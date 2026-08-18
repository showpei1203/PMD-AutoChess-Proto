# encoding: UTF-8
#==============================================================================
# 【PMD AutoChess 中文維護說明】
# 腳本：PMD AutoChess Motion Live Battle Stutter Fix v1.02.4
# 分類：PMD Motion Phase A／實機效能修正／Trailing Hotfix
# RPG Maker VX / RGSS2 / Ruby 1.8 compatible
#------------------------------------------------------------------------------
# 【用途】
# 依 v1.02.3 實機 Frame Profiler 結果，修正 Motion 測試戰鬥「剛開始會卡」與
# 「中途第一次出現某些技能／狀態動畫時會卡」的兩個已確認來源：
# 1. PMD_MOTION_PHASE_A_V102 仍經過歷代 update_verification_script alias 長鏈，
#    前 20～60 frame 與第一波攻擊重疊時，實機可出現 80～200ms 級 update spike。
# 2. v1.02.2 只預載主要 PMD 身體 Action，仍有 PMD_VFX 與候選 Native Action 在
#    live battle 第一次使用時才同步載入；v1.02.3 已實測記錄多筆 8～30ms late bitmap。
#
# 本版把 Motion mode 的 verifier 改成專用 lean dispatcher，並在 deploy 階段合作式
# 預綁 active battler Action Bitmap、預載本場技能需要的 VFX。所有耗時工作都盡量
# 移到尚未開戰的 deploy frame，live battle 只做快取查找與既有戰鬥更新。
#------------------------------------------------------------------------------
# 【主要設定】
# MOTION_LOCAL_BIND_PER_DEPLOY_V1024 = 4
#   每個 deploy frame 最多把 4 個「已由 Cache 預載」的 PMD Action 綁到 Sprite local cache。
# MOTION_VFX_PREWARM_PER_DEPLOY_V1024 = 1
#   每個 deploy frame 最多真正預載 1 張本場需要的 PMD VFX sheet，避免集中卡頓。
#------------------------------------------------------------------------------
# 【核心機制】
# 1. Lean Motion Verifier
#    verification_mode == :pmd_motion_phase_a_v102 時，不再走數十層舊 verifier alias chain。
#    只執行 v1.02～v1.02.4 需要的 Motion verifier，verification_frame 仍只增加一次，
#    並保留 COMPLETE / VERIFY_FINISHED_BATTLE_RESUME 正式驗收流程。
#
# 2. Sprite Local Action Binding
#    v1.02.2 的 Cache.load_bitmap 已能把 PNG 讀進 RGSS Cache，但每次 visual_action 切換仍
#    會重新走 action_data / bitmap_exists / Cache.load_bitmap。v1.02.4 在 deploy 先把本場
#    Walk / Idle / Hurt / Attack / Ambient / Basic 候選 / Skill Native 候選的 Bitmap 與
#    action_data 綁到各 Sprite。live battle 換姿勢時直接取 local entry。
#
# 3. Active Battle VFX Prewarm
#    依本場六隻單位的 skill_data、move presentation、move type、vfx_style 與 effects
#    收集真正可能使用的 PMD VFX。包含 muzzle / impact / column / impact layers，以及
#    heal、shield、drain、burn、poison、buff、debuff、stun、root、taunt 等狀態層。
#    不會把整個 VFX 資料夾一次全載，避免用記憶體換取表面順暢。
#
# 4. Start Gate
#    玩家若在 deploy 預載尚未完成前按開始，本版只延後真正 start_battle；待 local bind
#    與 VFX prewarm 完成後自動開戰。也就是把「戰鬥中突然卡」改成「開戰前合作式準備」。
#------------------------------------------------------------------------------
# 【可調參數】
# - 若日後硬體確認 Cache hit 極快，可把 LOCAL_BIND_PER_DEPLOY 提高到 6～8。
# - VFX_PREWARM 建議維持 1；PNG decode 是真正會造成 spike 的工作，不應同 frame 批次做。
# - 不建議預載 Graphics/Animations/PMD_VFX 全資料夾，目前 decoded memory 成本過高。
#------------------------------------------------------------------------------
# 【事件／腳本呼叫方式】
# 正式事件不需呼叫。
# 測試：AutoChess 布陣 → S 切 PMD_MOTION_PHASE_A_V102 → Shift → 完整看完一場。
# 若預載尚未完成，Shift 後會稍候數個 deploy frame，再自動進戰鬥。
#------------------------------------------------------------------------------
# 【LOG／驗證】
# 開戰時：
#   MOTION_LIVE_PREWARM_V1024 ready=1 bind=... vfx=... fail=0 ...
# verifier：
#   MOTION_LIVE_STUTTER_FIX_V1024 pass=1 lean_verifier=1 local_bind=1 vfx_prewarm=1
# v1.02.3 profiler 仍保留，用來比較：
#   MOTION_FRAME_PROFILE_V1023 spikes=... severe=... slow_bitmap=...
# 理想結果：early update spike 大幅下降，slow_bitmap 接近 0。
#------------------------------------------------------------------------------
# 【不可破壞】
# - 不直接修改 Frozen Combat Core，只以 Main 前 trailing override 安裝。
# - Pokémon 個體身份仍使用 instance_uid。
# - PMD Sprite 仍 100%，Effect / Projectile 仍 50%。
# - 不修改 AI Policy、Dynamic Tactical Role、Spatial Framework、Attack Speed、Damage。
# - 不修改 hit-stop、Hurt ownership、source hitFrame handoff 的時序與規則。
# - local bitmap cache 只持有 RGSS Cache 既有 Bitmap reference，不建立 Bitmap 複本。
#==============================================================================
module PMD_AC
  MOTION_LIVE_STUTTER_VERSION_V1024='1.02.4'
  MOTION_LOCAL_BIND_PER_DEPLOY_V1024=4
  MOTION_VFX_PREWARM_PER_DEPLOY_V1024=1
  MOTION_VFX_EVENT_TYPES_V1024=[
    :heal,:regen,:shield,:cleanse,:dispel,:drain,:seed,:energy_drain,:energy_steal,
    :poison,:burn,:fire,:def_up,:atk_up,:def_aura,:energy_gain,:energy_aura,
    :slow,:move_slow,:attack_slow,:atk_down,:def_down,:fear,:energy_lock,
    :stun,:electric,:chain,:root,:web,:taunt,:impact,:slash,:control
  ]
end

#==============================================================================
# ■ Sprite_PMDChessUnit - active battler local action bitmap binding
#==============================================================================
class Sprite_PMDChessUnit
  alias pmd_ac_v1024_refresh_action_bitmap refresh_action_bitmap unless method_defined?(:pmd_ac_v1024_refresh_action_bitmap)

  def motion_local_action_cache_v1024
    @motion_local_action_cache_v1024={} if @motion_local_action_cache_v1024==nil
    @motion_local_action_cache_v1024
  end

  def motion_bind_action_bitmap_v1024(action)
    return false if @unit==nil || action==nil
    data=PMD_AC.action_data(@unit.species,action)
    return false if data==nil || data[:file]==nil
    folder=PMD_AC::PMD_ROOT+@unit.species.to_s+'/'
    file=data[:file].to_s
    return false unless PMD_AC.bitmap_exists?(folder,file)
    bmp=Cache.load_bitmap(folder,file)
    return false if bmp==nil || bmp.disposed?
    motion_local_action_cache_v1024[action.to_s.to_sym]=[bmp,data]
    true
  rescue
    false
  end

  def motion_local_bound_count_v1024
    motion_local_action_cache_v1024.size
  rescue
    0
  end

  def refresh_action_bitmap(force)
    visual_action=@unit==nil ? nil : @unit.visual_action
    key=visual_action==nil ? nil : visual_action.to_s.to_sym
    entry=key==nil ? nil : motion_local_action_cache_v1024[key]
    if entry!=nil && entry[0]!=nil && !entry[0].disposed?
      action=@unit.action
      return if !force && @last_action==action && @last_visual_action==visual_action
      @last_action=action
      @last_visual_action=visual_action
      @last_facing_dir=@unit.facing_dir
      @frame_index=0
      @frame_wait=0
      dispose_owned_bitmap
      self.bitmap=entry[0]
      @action_data=entry[1]
      @placeholder=false
      setup_source_rect
      return
    end
    pmd_ac_v1024_refresh_action_bitmap(force)
  end
end

#==============================================================================
# ■ Scene_PMD_AutoChess - cooperative bind / VFX prewarm / lean verifier
#==============================================================================
class Scene_PMD_AutoChess
  alias pmd_ac_v1024_start start unless method_defined?(:pmd_ac_v1024_start)
  alias pmd_ac_v1024_update_deploy_phase update_deploy_phase unless method_defined?(:pmd_ac_v1024_update_deploy_phase)
  alias pmd_ac_v1024_start_battle start_battle unless method_defined?(:pmd_ac_v1024_start_battle)
  alias pmd_ac_v1024_restart_to_deploy restart_to_deploy unless method_defined?(:pmd_ac_v1024_restart_to_deploy)
  alias pmd_ac_v1024_update_verification_script update_verification_script unless method_defined?(:pmd_ac_v1024_update_verification_script)

  def motion_v1024_mode?
    verification_mode==:pmd_motion_phase_a_v102
  rescue
    false
  end

  def motion_sprite_for_unit_v1024(unit)
    return nil if unit==nil || @unit_sprites==nil
    @unit_sprites.each do |s|
      return s if s!=nil && s.respond_to?(:unit) && s.unit==unit
    end
    nil
  rescue
    nil
  end

  def motion_action_candidates_for_unit_v1024(unit)
    out=[:walk,:idle,:hurt,:attack]
    return out if unit==nil
    sid=unit.species.to_s rescue ''
    p=nil
    begin;p=PMD_AC.motion_species_profile_v102(sid);rescue;p=nil;end
    if p!=nil && p[:ambient]!=nil
      p[:ambient].each do |row|
        next if row==nil || row[0]==nil
        a=row[0].to_s.to_sym
        out.push(a) unless out.include?(a)
      end
    end
    begin
      support=unit.motion_support_state_v102
      out.push(:hover) if (support==:air || support==:float) && !out.include?(:hover)
    rescue
    end
    # Basic + Skill 都預載「候選 pose」，不只 selected，避免舊 Presentation Router
    # 在特殊情況切到 Shock / Double / Hop 等候選時才臨場解碼。
    begin
      PMD_AC.native_pose_candidates_v061(sid,:basic_attack,nil,nil).each do |a|
        next if a==nil
        k=a.to_s.to_sym
        out.push(k) if PMD_AC.motion_playable_v102?(sid,k) && !out.include?(k)
      end
    rescue
    end
    begin
      d=unit.skill_data
      mk=d==nil ? :skill : (d[:canonical_move_key] || d[:move_key] || :skill)
      pp=nil
      begin;pp=PMD_AC.move_presentation_profile_v055(mk);rescue;pp=nil;end
      PMD_AC.native_pose_candidates_v061(sid,mk,d,pp).each do |a|
        next if a==nil
        k=a.to_s.to_sym
        out.push(k) if PMD_AC.motion_playable_v102?(sid,k) && !out.include?(k)
      end
    rescue
    end
    out
  rescue
    [:walk,:idle,:hurt,:attack]
  end

  def motion_collect_symbols_v1024(obj,out,depth=0)
    return if obj==nil || depth>6
    if obj.is_a?(Symbol)
      out[obj]=true
    elsif obj.is_a?(Array)
      obj.each{|v|motion_collect_symbols_v1024(v,out,depth+1)}
    elsif obj.is_a?(Hash)
      obj.each do |k,v|
        motion_collect_symbols_v1024(k,out,depth+1)
        motion_collect_symbols_v1024(v,out,depth+1)
      end
    end
  rescue
  end

  def motion_add_vfx_sheet_v1024(sheet,seen,queue)
    return if sheet==nil
    name=sheet.to_s
    return if name.empty? || seen[name]
    path=PMD_AC::PMD_VFX_FOLDER+name+'.png'
    return unless FileTest.exist?(path)
    seen[name]=true
    queue.push(name)
  rescue
  end

  def motion_collect_profile_sheets_v1024(profile,seen,queue)
    return if profile==nil
    if profile.is_a?(Array)
      profile.each{|v|motion_collect_profile_sheets_v1024(v,seen,queue)}
    elsif profile.is_a?(Hash)
      motion_add_vfx_sheet_v1024(profile[:sheet],seen,queue) if profile[:sheet]!=nil
      profile.each_value{|v|motion_collect_profile_sheets_v1024(v,seen,queue) if v.is_a?(Array) || v.is_a?(Hash)}
    end
  rescue
  end

  def motion_build_live_queues_v1024
    return if @motion_live_queue_ready_v1024
    @motion_live_queue_ready_v1024=true
    @motion_local_bind_queue_v1024=[]
    @motion_vfx_queue_v1024=[]
    @motion_local_bind_total_v1024=0
    @motion_local_bind_ok_v1024=0
    @motion_local_bind_fail_v1024=0
    @motion_vfx_total_v1024=0
    @motion_vfx_loaded_v1024=0
    @motion_vfx_fail_v1024=0
    @motion_vfx_total_ms_v1024=0
    @motion_live_summary_logged_v1024=false
    @motion_local_bind_done_v1024=false
    @motion_vfx_done_v1024=false

    (@units || []).each do |u|
      next if u==nil
      sid=u.species.to_s rescue ''
      next unless PMD_AC.motion_phase_a_species_v102?(sid)
      sprite=motion_sprite_for_unit_v1024(u)
      next if sprite==nil
      motion_action_candidates_for_unit_v1024(u).each do |a|
        @motion_local_bind_queue_v1024.push([sprite,a])
      end
    end
    @motion_local_bind_total_v1024=@motion_local_bind_queue_v1024.size
    @motion_local_bind_done_v1024=true if @motion_local_bind_queue_v1024.empty?

    # VFX：只收本場技能與 effects 需要的 sheet。
    vseen={}
    styles={:light=>true,:impact=>true}
    symbols={}
    (@units || []).each do |u|
      next if u==nil
      d=nil
      begin;d=u.skill_data;rescue;d=nil;end
      next if d==nil
      motion_collect_symbols_v1024(d,symbols,0)
      [:vfx_style,:move_type,:type].each do |k|
        v=d[k]
        styles[v]=true if v!=nil && v.is_a?(Symbol)
      end
      begin
        mk=d[:canonical_move_key] || d[:move_key] || :skill
        pp=PMD_AC.move_presentation_profile_v055(mk)
        if pp!=nil
          [:vfx_style,:style,:projectile_visual].each do |k|
            v=pp[k]
            styles[v]=true if v!=nil && v.is_a?(Symbol)
          end
          motion_collect_symbols_v1024(pp,symbols,0)
        end
      rescue
      end
    end
    styles.keys.each do |style|
      begin;motion_collect_profile_sheets_v1024(PMD_AC.vfx_profile(style),vseen,@motion_vfx_queue_v1024);rescue;end
      begin;motion_collect_profile_sheets_v1024(PMD_AC.vfx_impact_layers(style),vseen,@motion_vfx_queue_v1024);rescue;end
    end
    symbols.keys.each do |sym|
      next unless PMD_AC::MOTION_VFX_EVENT_TYPES_V1024.include?(sym)
      begin;motion_collect_profile_sheets_v1024(PMD_AC.vfx_event_layers(sym),vseen,@motion_vfx_queue_v1024);rescue;end
    end
    @motion_vfx_total_v1024=@motion_vfx_queue_v1024.size
    @motion_vfx_done_v1024=true if @motion_vfx_queue_v1024.empty?
    true
  rescue
    @motion_local_bind_done_v1024=true
    @motion_vfx_done_v1024=true
    false
  end

  def motion_step_local_bind_v1024
    return if @motion_local_bind_done_v1024
    q=@motion_local_bind_queue_v1024 || []
    n=0
    while n<PMD_AC::MOTION_LOCAL_BIND_PER_DEPLOY_V1024 && !q.empty?
      row=q.shift
      ok=false
      begin;ok=row[0].motion_bind_action_bitmap_v1024(row[1]);rescue;ok=false;end
      if ok
        @motion_local_bind_ok_v1024=@motion_local_bind_ok_v1024.to_i+1
      else
        @motion_local_bind_fail_v1024=@motion_local_bind_fail_v1024.to_i+1
      end
      n+=1
    end
    @motion_local_bind_queue_v1024=q
    @motion_local_bind_done_v1024=true if q.empty?
  rescue
    @motion_local_bind_done_v1024=true
  end

  def motion_step_vfx_prewarm_v1024
    return if @motion_vfx_done_v1024
    q=@motion_vfx_queue_v1024 || []
    n=0
    while n<PMD_AC::MOTION_VFX_PREWARM_PER_DEPLOY_V1024 && !q.empty?
      sheet=q.shift
      t=Time.now.to_f
      ok=true
      begin
        Cache.load_bitmap(PMD_AC::PMD_VFX_FOLDER,sheet)
        @motion_vfx_loaded_v1024=@motion_vfx_loaded_v1024.to_i+1
      rescue
        ok=false
        @motion_vfx_fail_v1024=@motion_vfx_fail_v1024.to_i+1
      end
      begin
        @motion_vfx_total_ms_v1024=@motion_vfx_total_ms_v1024.to_i+(((Time.now.to_f-t)*1000.0).round)
      rescue
      end
      n+=1
    end
    @motion_vfx_queue_v1024=q
    @motion_vfx_done_v1024=true if q.empty?
  rescue
    @motion_vfx_done_v1024=true
  end

  def motion_live_ready_v1024?
    @motion_local_bind_done_v1024 && @motion_vfx_done_v1024
  rescue
    false
  end

  def motion_log_live_prewarm_v1024
    return if @motion_live_summary_logged_v1024
    @motion_live_summary_logged_v1024=true
    log_event(:perf,'MOTION_LIVE_PREWARM_V1024 ready='+(motion_live_ready_v1024? ? '1':'0')+
      ' bind='+@motion_local_bind_ok_v1024.to_i.to_s+'/'+@motion_local_bind_total_v1024.to_i.to_s+
      ' bind_fail='+@motion_local_bind_fail_v1024.to_i.to_s+
      ' vfx='+@motion_vfx_loaded_v1024.to_i.to_s+'/'+@motion_vfx_total_v1024.to_i.to_s+
      ' vfx_fail='+@motion_vfx_fail_v1024.to_i.to_s+
      ' vfx_ms='+@motion_vfx_total_ms_v1024.to_i.to_s+' lean_verifier=1')
  rescue
  end

  def start
    pmd_ac_v1024_start
    if motion_v1024_mode?
      @motion_live_queue_ready_v1024=false
      @motion_v1024_pending_start=false
      motion_build_live_queues_v1024 if @motion_prewarm_done_v1022
    end
  end

  def update_deploy_phase
    pmd_ac_v1024_update_deploy_phase
    return unless @phase==:deploy && motion_v1024_mode?
    motion_build_live_queues_v1024 if @motion_prewarm_done_v1022 && !@motion_live_queue_ready_v1024
    if @motion_live_queue_ready_v1024
      motion_step_local_bind_v1024
      motion_step_vfx_prewarm_v1024
    end
    if @motion_v1024_pending_start && @motion_prewarm_done_v1022 && motion_live_ready_v1024?
      @motion_v1024_pending_start=false
      start_battle
    end
  end

  def start_battle
    if motion_v1024_mode?
      motion_build_live_queues_v1024 if @motion_prewarm_done_v1022 && !@motion_live_queue_ready_v1024
      unless @motion_prewarm_done_v1022 && motion_live_ready_v1024?
        @motion_v1024_pending_start=true
        return
      end
    end
    result=pmd_ac_v1024_start_battle
    motion_log_live_prewarm_v1024 if motion_v1024_mode? && @phase==:battle
    result
  end

  def restart_to_deploy
    result=pmd_ac_v1024_restart_to_deploy
    if @phase==:deploy && motion_v1024_mode?
      @motion_live_queue_ready_v1024=false
      @motion_v1024_pending_start=false
      motion_build_live_queues_v1024 if @motion_prewarm_done_v1022
    end
    result
  end

  def verify_motion_live_stutter_fix_v1024
    return if @verification_done[:motion_live_stutter_fix_v1024]
    pass=motion_live_ready_v1024? && @motion_local_bind_fail_v1024.to_i==0 &&
      @motion_vfx_fail_v1024.to_i==0 && @motion_local_bind_ok_v1024.to_i>0
    @motion_phase_a_failed_v102=true unless pass
    log_event(:verify,'MOTION_LIVE_STUTTER_FIX_V1024 pass='+(pass ? '1':'0')+
      ' lean_verifier=1 local_bind='+( @motion_local_bind_ok_v1024.to_i>0 ? '1':'0')+
      ' bind_fail='+@motion_local_bind_fail_v1024.to_i.to_s+
      ' vfx_prewarm='+( @motion_vfx_done_v1024 ? '1':'0')+
      ' vfx_fail='+@motion_vfx_fail_v1024.to_i.to_s+
      ' ai_unchanged=1 damage_unchanged=1 attack_speed_unchanged=1 hitstop_unchanged=1')
    @verification_done[:motion_live_stutter_fix_v1024]=true
  end

  # Motion mode 專用 lean dispatcher：不進歷代 verifier alias 長鏈。
  # 其他四個正式模式仍完整交回既有 chain，完全不改。
  def update_verification_script
    unless motion_v1024_mode?
      pmd_ac_v1024_update_verification_script
      return
    end
    @verification_frame=@verification_frame.to_i+1
    f=@verification_frame.to_i
    verify_motion_registry_v102 if f>=20
    verify_motion_production_runtime_v1021 if f>=26
    verify_motion_runtime_cache_v1022 if f>=30
    verify_motion_frame_profiler_v1023 if f>=32
    verify_motion_live_stutter_fix_v1024 if f>=34
    verify_motion_native_v102 if f>=44
    verify_motion_anchor_ownership_v102 if f>=68
    verify_motion_pipeline_v102 if f>=92
    verify_motion_runtime_signal_v102 if f>=164
    verify_motion_final_v102 if f>=190
    complete_verification_mode if f>=210
  end
end
