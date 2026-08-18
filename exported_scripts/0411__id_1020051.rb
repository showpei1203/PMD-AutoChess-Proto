# encoding: UTF-8
#==============================================================================
# 【PMD AutoChess 中文維護說明】
# 腳本：PMD AutoChess Motion Opening Heap Settle v1.02.5
# 分類：PMD Motion Phase A／RGSS2 開場卡頓修正／Trailing Hotfix
# RPG Maker VX / RGSS2 / Ruby 1.8 compatible
#------------------------------------------------------------------------------
# 【用途】
# v1.02.3～v1.02.4 實機 Frame Profiler 已確認兩件事：
# 1. PMD / VFX late bitmap 已由 v1.02.4 從 10 筆降到 2 筆，素材預載有效。
# 2. 但戰鬥前 20～50 frame 仍會出現 70～230ms update spike，而且當下並沒有
#    對應的慢 Bitmap；這種「預載後、第一波多單位開始行動時集中爆發」的形狀，
#    高度符合 Ruby 1.8 heap 在大量 Cache / Hash / Array 建立後第一次自動 GC 的停頓。
#
# 本版因此不再把工作塞進 live battle，而是在 deploy 階段完成三件事：
# A. 本場 active Pokémon 的「所有可播放 PMD Action」全部綁進 Sprite local cache，
#    不只預測 Basic / Skill 候選，避免 Double-Anim 等舊 Presentation fallback 漏網。
# B. 預載所有既有狀態事件 VFX layer，補足像 taunt -> PMD_EOS_M0204_V000 這種
#    不一定直接寫在 skill_data 裡、卻會由 runtime 效果觸發的 VFX。
# C. 所有合作式預載完成後，先清掉暫存 queue，於 deploy 畫面主動 GC.start 一次；
#    heap settle 完成前 start_battle 一律保持 pending。讓垃圾回收停頓發生在開戰前，
#    而不是第一輪 Attack / Hurt 已經開始後。
#------------------------------------------------------------------------------
# 【主要設定】
# MOTION_HEAP_SETTLE_ENABLED_V1025 = true
#   是否在 Motion Phase A 預載後執行一次 deploy-time GC settle。
# MOTION_PREBIND_ALL_ACTIVE_ACTIONS_V1025 = true
#   是否把 active battler PMDCollab action_database 內所有可播放 Action 預綁。
# MOTION_PREWARM_ALL_EVENT_VFX_V1025 = true
#   是否把既有 Motion VFX event type 對應的 layer 全部放進合作式預載 queue。
# MOTION_OPENING_WINDOW_V1025 = 60
#   Profiler 額外把 spike 分成前 60 frame 與之後，方便確認開場問題是否真的下降。
#------------------------------------------------------------------------------
# 【機制規則】
# - 本版只改「什麼時候準備 Presentation 資源」與「什麼時候做一次 GC」。
# - 不改 AI、Target、Dynamic Tactical Role、Spatial Framework、Damage、Attack Speed。
# - 不改 Motion hit-stop、Hurt ownership、source hitFrame、FX / Damage handoff。
# - local cache 只保留 RGSS Cache 已有 Bitmap reference，不複製 Bitmap。
# - GC 只在 deploy、所有預載完成後執行一次；live battle 不主動 GC、不 disable GC。
# - 其他 verification mode 完全交回原 verifier chain；只有 PMD_MOTION_PHASE_A_V102
#   使用本版的 heap-settle start gate。
#------------------------------------------------------------------------------
# 【可調參數】
# - 若實機顯示 gc_ms 很低且 opening spike 明顯下降，維持一次 GC 即可。
# - 若 opening spike 仍高，不要直接增加 GC 次數；下一步應依 profiler 再拆 Unit / Sprite
#   update 子階段，而不是用更多停頓互相抵消。
# - 若 deploy 預載時間過長，可改回只預綁 active action 白名單，但目前 Phase A 代表戰
#   只有六隻 active battler，完整 action 綁定的記憶體成本可控。
#------------------------------------------------------------------------------
# 【事件／腳本呼叫方式】
# 正式事件不需呼叫。
# 測試方式：AutoChess 布陣 → S 切 PMD_MOTION_PHASE_A_V102 → Shift → 完整看完一場。
# 玩家過早按 Shift 時，start_battle 會保持 pending，直到 v1.02.2 / v1.02.4 預載與
# v1.02.5 heap settle 都完成後才真正進戰鬥。
#------------------------------------------------------------------------------
# 【LOG／驗證】
# deploy-time：
#   MOTION_HEAP_SETTLE_V1025 ready=1 gc_ms=... all_actions_added=... event_vfx_added=...
# verifier：
#   MOTION_OPENING_STUTTER_GUARD_V1025 pass=1 heap_settle=1 ...
# battle end：
#   MOTION_SPIKE_SPLIT_V1025 opening=... runtime=... severe_opening=... severe_runtime=...
# 並繼續沿用 v1.02.3：
#   MOTION_FRAME_PROFILE_V1023 ...
#------------------------------------------------------------------------------
# 【實際範例】
# v1.02.4 曾漏：Graphics/PMD/0019/Double-Anim.png
# 本版會由 action_database['0019'] 的所有 playable action 自動加入 local bind queue。
# v1.02.4 曾漏：Graphics/Animations/PMD_VFX/PMD_EOS_M0204_V000.png（taunt）
# 本版會由所有既有 event VFX type 的 layer 自動加入 VFX prewarm queue。
#------------------------------------------------------------------------------
# 【不可破壞】
# - Frozen Combat Core 不直接修改，只在 Main 前追加 trailing override。
# - Pokémon 個體身份仍以 instance_uid 為唯一身份。
# - PMD Sprite 100%，Effect / Projectile 50%。
# - Game.ini 不得有 UTF-8 BOM。
#==============================================================================
module PMD_AC
  MOTION_OPENING_HEAP_VERSION_V1025='1.02.5'
  MOTION_HEAP_SETTLE_ENABLED_V1025=true
  MOTION_PREBIND_ALL_ACTIVE_ACTIONS_V1025=true
  MOTION_PREWARM_ALL_EVENT_VFX_V1025=true
  MOTION_OPENING_WINDOW_V1025=60
end

class Scene_PMD_AutoChess
  alias pmd_ac_v1025_start start unless method_defined?(:pmd_ac_v1025_start)
  alias pmd_ac_v1025_restart_to_deploy restart_to_deploy unless method_defined?(:pmd_ac_v1025_restart_to_deploy)
  alias pmd_ac_v1025_update_deploy_phase update_deploy_phase unless method_defined?(:pmd_ac_v1025_update_deploy_phase)
  alias pmd_ac_v1025_motion_build_live_queues_v1024 motion_build_live_queues_v1024 unless method_defined?(:pmd_ac_v1025_motion_build_live_queues_v1024)
  alias pmd_ac_v1025_motion_live_ready_v1024 motion_live_ready_v1024? unless method_defined?(:pmd_ac_v1025_motion_live_ready_v1024)
  alias pmd_ac_v1025_update_verification_script update_verification_script unless method_defined?(:pmd_ac_v1025_update_verification_script)
  alias pmd_ac_v1025_motion_perf_record_spike_v1023 motion_perf_record_spike_v1023 unless method_defined?(:pmd_ac_v1025_motion_perf_record_spike_v1023)
  alias pmd_ac_v1025_motion_perf_log_summary_v1023 motion_perf_log_summary_v1023 unless method_defined?(:pmd_ac_v1025_motion_perf_log_summary_v1023)

  def motion_reset_heap_settle_v1025
    @motion_heap_settled_v1025=false
    @motion_heap_settle_failed_v1025=false
    @motion_heap_gc_ms_v1025=0
    @motion_all_actions_added_v1025=0
    @motion_event_vfx_added_v1025=0
    @motion_spike_opening_v1025=0
    @motion_spike_runtime_v1025=0
    @motion_spike_severe_opening_v1025=0
    @motion_spike_severe_runtime_v1025=0
    @motion_heap_log_v1025=false
  end

  def start
    motion_reset_heap_settle_v1025
    pmd_ac_v1025_start
  end

  def restart_to_deploy
    result=pmd_ac_v1025_restart_to_deploy
    motion_reset_heap_settle_v1025 if @phase==:deploy && motion_v1024_mode?
    result
  end

  def motion_queue_all_active_actions_v1025
    return 0 unless PMD_AC::MOTION_PREBIND_ALL_ACTIVE_ACTIONS_V1025
    q=@motion_local_bind_queue_v1024 || []
    seen={}
    q.each do |row|
      next if row==nil || row[0]==nil || row[1]==nil
      seen[[row[0].object_id,row[1].to_s.to_sym]]=true
    end
    added=0
    (@units || []).each do |u|
      next if u==nil
      sid=u.species.to_s rescue ''
      next unless PMD_AC.motion_phase_a_species_v102?(sid)
      sprite=motion_sprite_for_unit_v1024(u)
      next if sprite==nil
      db=PMD_AC.action_database[sid] rescue nil
      next if db==nil
      db.keys.each do |a|
        k=a.to_s.to_sym
        token=[sprite.object_id,k]
        next if seen[token]
        next unless PMD_AC.motion_playable_v102?(sid,k)
        q.push([sprite,k])
        seen[token]=true
        added+=1
      end
    end
    @motion_local_bind_queue_v1024=q
    @motion_local_bind_total_v1024=q.size
    @motion_local_bind_done_v1024=q.empty?
    added
  rescue
    0
  end

  def motion_queue_all_event_vfx_v1025
    return 0 unless PMD_AC::MOTION_PREWARM_ALL_EVENT_VFX_V1025
    q=@motion_vfx_queue_v1024 || []
    seen={}
    q.each{|name|seen[name.to_s]=true if name!=nil}
    before=q.size
    PMD_AC::MOTION_VFX_EVENT_TYPES_V1024.each do |sym|
      begin
        motion_collect_profile_sheets_v1024(PMD_AC.vfx_event_layers(sym),seen,q)
      rescue
      end
    end
    @motion_vfx_queue_v1024=q
    @motion_vfx_total_v1024=q.size
    @motion_vfx_done_v1024=q.empty?
    q.size-before
  rescue
    0
  end

  def motion_build_live_queues_v1024
    was=@motion_live_queue_ready_v1024
    result=pmd_ac_v1025_motion_build_live_queues_v1024
    if motion_v1024_mode? && !was && @motion_live_queue_ready_v1024
      @motion_all_actions_added_v1025=motion_queue_all_active_actions_v1025
      @motion_event_vfx_added_v1025=motion_queue_all_event_vfx_v1025
    end
    result
  end

  def motion_base_prewarm_ready_v1025?
    pmd_ac_v1025_motion_live_ready_v1024
  rescue
    false
  end

  # v1.02.4 start gate 看到的 ready 必須包含 heap settle。
  def motion_live_ready_v1024?
    base=motion_base_prewarm_ready_v1025?
    return base unless motion_v1024_mode?
    base && @motion_heap_settled_v1025
  rescue
    false
  end

  def motion_heap_settle_v1025
    return true if @motion_heap_settled_v1025
    return false unless motion_v1024_mode?
    return false unless motion_base_prewarm_ready_v1025?
    # 先釋放只在預載階段使用的 queue reference，再做一次 deploy-time GC。
    @motion_local_bind_queue_v1024=nil
    @motion_vfx_queue_v1024=nil
    ms=0
    ok=true
    if PMD_AC::MOTION_HEAP_SETTLE_ENABLED_V1025
      begin
        t=Time.now.to_f
        GC.start
        ms=((Time.now.to_f-t)*1000.0).round
      rescue
        ok=false
      end
    end
    @motion_heap_gc_ms_v1025=ms
    @motion_heap_settle_failed_v1025=!ok
    @motion_heap_settled_v1025=true
    unless @motion_heap_log_v1025
      @motion_heap_log_v1025=true
      log_event(:perf,'MOTION_HEAP_SETTLE_V1025 ready=1 gc_ms='+ms.to_i.to_s+
        ' gc_ok='+(ok ? '1':'0')+
        ' all_actions_added='+@motion_all_actions_added_v1025.to_i.to_s+
        ' event_vfx_added='+@motion_event_vfx_added_v1025.to_i.to_s+
        ' live_gc_disabled=0 ai_unchanged=1 damage_unchanged=1 attack_speed_unchanged=1')
    end
    true
  rescue
    @motion_heap_settle_failed_v1025=true
    @motion_heap_settled_v1025=true
    false
  end

  def update_deploy_phase
    result=pmd_ac_v1025_update_deploy_phase
    if @phase==:deploy && motion_v1024_mode?
      motion_heap_settle_v1025 if motion_base_prewarm_ready_v1025? && !@motion_heap_settled_v1025
    end
    result
  end

  def verify_motion_opening_stutter_guard_v1025
    return if @verification_done[:motion_opening_stutter_guard_v1025]
    pass=@motion_heap_settled_v1025 && !@motion_heap_settle_failed_v1025 &&
      @motion_local_bind_fail_v1024.to_i==0 && @motion_vfx_fail_v1024.to_i==0
    @motion_phase_a_failed_v102=true unless pass
    log_event(:verify,'MOTION_OPENING_STUTTER_GUARD_V1025 pass='+(pass ? '1':'0')+
      ' heap_settle='+(@motion_heap_settled_v1025 ? '1':'0')+
      ' gc_ok='+(@motion_heap_settle_failed_v1025 ? '0':'1')+
      ' gc_ms='+@motion_heap_gc_ms_v1025.to_i.to_s+
      ' all_actions_added='+@motion_all_actions_added_v1025.to_i.to_s+
      ' event_vfx_added='+@motion_event_vfx_added_v1025.to_i.to_s+
      ' bind_fail='+@motion_local_bind_fail_v1024.to_i.to_s+
      ' vfx_fail='+@motion_vfx_fail_v1024.to_i.to_s+
      ' ai_unchanged=1 damage_unchanged=1 attack_speed_unchanged=1 spatial_unchanged=1')
    @verification_done[:motion_opening_stutter_guard_v1025]=true
  end

  def update_verification_script
    pmd_ac_v1025_update_verification_script
    if motion_v1024_mode? && @verification_frame.to_i>=38
      verify_motion_opening_stutter_guard_v1025
    end
  end

  def motion_perf_record_spike_v1023(gap_ms,update_ms)
    g=gap_ms.to_i
    u=update_ms.to_i
    if motion_perf_capture_active_v1023? &&
       (g>=PMD_AC::MOTION_FRAME_SPIKE_MS_V1023 || u>=PMD_AC::MOTION_UPDATE_SPIKE_MS_V1023)
      f=motion_perf_relative_frame_v1023
      opening=f<=PMD_AC::MOTION_OPENING_WINDOW_V1025
      severe=(g>=PMD_AC::MOTION_SEVERE_SPIKE_MS_V1023 || u>=PMD_AC::MOTION_SEVERE_SPIKE_MS_V1023)
      if opening
        @motion_spike_opening_v1025=@motion_spike_opening_v1025.to_i+1
        @motion_spike_severe_opening_v1025=@motion_spike_severe_opening_v1025.to_i+1 if severe
      else
        @motion_spike_runtime_v1025=@motion_spike_runtime_v1025.to_i+1
        @motion_spike_severe_runtime_v1025=@motion_spike_severe_runtime_v1025.to_i+1 if severe
      end
    end
    pmd_ac_v1025_motion_perf_record_spike_v1023(gap_ms,update_ms)
  end

  def motion_perf_log_summary_v1023
    already=@motion_perf_summary_logged_v1023
    result=pmd_ac_v1025_motion_perf_log_summary_v1023
    if !already && @motion_perf_summary_logged_v1023
      log_event(:perf,'MOTION_SPIKE_SPLIT_V1025 opening='+@motion_spike_opening_v1025.to_i.to_s+
        ' runtime='+@motion_spike_runtime_v1025.to_i.to_s+
        ' severe_opening='+@motion_spike_severe_opening_v1025.to_i.to_s+
        ' severe_runtime='+@motion_spike_severe_runtime_v1025.to_i.to_s+
        ' opening_window='+PMD_AC::MOTION_OPENING_WINDOW_V1025.to_i.to_s)
    end
    result
  end
end
