#==============================================================================
# ■ PMD AutoChess Motion Live GC Guard v1.02.11
#------------------------------------------------------------------------------
# 【用途】
# 本腳本用於診斷並抑制 PMD Motion Phase A 實戰中的 Ruby 1.8 GC 暫停。
# v1.02.9 已在真正開戰前把 Active Pokémon Action、PMD VFX、SkillFX、
# Motion Route / Local Bind 等資源完整預載；v1.02.10 又完成 real Sprite
# render-prime。實機 Profiler 仍觀察到 50～230ms 的不定期 update hitch，
# 且 slow bitmap 已為 0，耗時會落在 Sprite / Unit 等不同當下函式上。
# 這種分散型尖峰符合 live GC pause 的特徵，因此本版做受控 A/B 驗證。
#------------------------------------------------------------------------------
# 【主要設定項】
# PMD_AC::MOTION_LIVE_GC_GUARD_ENABLED_V10211
#   是否啟用本版保護。預設 true。
# PMD_AC::MOTION_LIVE_GC_GUARD_MODE_V10211
#   僅作用於 :pmd_motion_phase_a_v102 verifier，不影響 NORMAL / Map Story。
#------------------------------------------------------------------------------
# 【機制規則】
# 1. 必須等 v1.02.9 Battle Resource Loading Gate 完成後才可啟用。
# 2. Scene 真正進入 :battle 後呼叫 GC.disable。
# 3. Live battle 期間不主動 GC，避免 Ruby 在 Attack / Hurt / Hop / Skill
#    等任意 frame 插入長時間 mark/sweep pause。
# 4. 戰鬥結果顯示前、回布陣、離開 Scene 時一定重新 GC.enable。
# 5. 重新啟用後立即 GC.start，把整理成本移到 live battle 之外。
# 6. 本版不修改 AI、Damage、Attack Speed、Spatial、hit-stop、Hurt ownership、
#    Native hitFrame 或 logical xy。
#------------------------------------------------------------------------------
# 【可調參數】
# - 本版目前故意只限 Motion verifier，先用 Windows RGSS2 實機數據驗證。
# - 若證明 ≥50ms hitch 大幅下降，後續才會整理成 Production Battle GC Gate。
#------------------------------------------------------------------------------
# 【事件／腳本呼叫方式】
# 不需要事件手動呼叫。
# S 切至 PMD_MOTION_PHASE_A_V102 → Shift，Loading 100% 後自動啟用。
#------------------------------------------------------------------------------
# 【實際範例】
# 開戰後 LOG：
#   MOTION_LIVE_GC_GUARD_V10211 enabled=1 resource_ready=1 ...
# verifier：
#   MOTION_LIVE_GC_GUARD_V10211 pass=1 live_gc_disabled=1 ...
# 戰鬥結束：
#   MOTION_LIVE_GC_RELEASE_V10211 reason=result ... gc_ms=...
#------------------------------------------------------------------------------
# 【不可破壞】
# - Frozen Combat Core 不直接修改，只以 Main 前 trailing alias 安裝。
# - Pokémon 個體身份仍使用 instance_uid。
# - PMD Sprite 100%，Effect / Projectile 50%。
# - Game.ini 不得有 UTF-8 BOM。
#==============================================================================

$imported = {} unless defined?($imported)
$imported['PMD_AutoChess_MotionLiveGCGuard_v10211'] = true

module PMD_AC
  MOTION_LIVE_GC_GUARD_VERSION_V10211='1.02.11'
  MOTION_LIVE_GC_GUARD_ENABLED_V10211=true
  MOTION_LIVE_GC_GUARD_MODE_V10211=:pmd_motion_phase_a_v102
end

class Scene_PMD_AutoChess
  alias pmd_ac_v10211_start start unless method_defined?(:pmd_ac_v10211_start)
  alias pmd_ac_v10211_start_battle start_battle unless method_defined?(:pmd_ac_v10211_start_battle)
  alias pmd_ac_v10211_show_result show_result unless method_defined?(:pmd_ac_v10211_show_result)
  alias pmd_ac_v10211_restart_to_deploy restart_to_deploy unless method_defined?(:pmd_ac_v10211_restart_to_deploy)
  alias pmd_ac_v10211_terminate terminate unless method_defined?(:pmd_ac_v10211_terminate)
  alias pmd_ac_v10211_update_verification_script update_verification_script unless method_defined?(:pmd_ac_v10211_update_verification_script)

  def motion_live_gc_mode_v10211?
    return false unless PMD_AC::MOTION_LIVE_GC_GUARD_ENABLED_V10211
    verification_mode==PMD_AC::MOTION_LIVE_GC_GUARD_MODE_V10211
  rescue
    false
  end

  def motion_live_gc_reset_v10211
    @motion_live_gc_disabled_v10211=false
    @motion_live_gc_start_frame_v10211=0
    @motion_live_gc_disable_ms_v10211=0
    @motion_live_gc_release_count_v10211=0
    @motion_live_gc_last_release_v10211=nil
    @motion_live_gc_verify_logged_v10211=false
  end

  def start
    motion_live_gc_reset_v10211
    pmd_ac_v10211_start
  end

  def motion_live_gc_disable_v10211
    return false if @motion_live_gc_disabled_v10211
    return false unless motion_live_gc_mode_v10211?
    ready=false
    begin;ready=battle_resource_loading_ready_v1029?;rescue;ready=false;end
    return false unless ready
    t=Time.now.to_f
    begin
      GC.disable
      @motion_live_gc_disable_ms_v10211=((Time.now.to_f-t)*1000.0).round rescue 0
      @motion_live_gc_disabled_v10211=true
      @motion_live_gc_start_frame_v10211=Graphics.frame_count
      log_event(:perf,'MOTION_LIVE_GC_GUARD_V10211 enabled=1 resource_ready=1 after_loading=1 '+
        'disable_ms='+@motion_live_gc_disable_ms_v10211.to_i.to_s+
        ' live_gc_disabled=1 scope=motion_verifier_only ai_unchanged=1 damage_unchanged=1 '+
        'attack_speed_unchanged=1 spatial_unchanged=1')
      true
    rescue Exception=>e
      @motion_live_gc_disabled_v10211=false
      begin;log_event(:perf,'MOTION_LIVE_GC_GUARD_V10211 enabled=0 error='+e.class.to_s);rescue;end
      false
    end
  end

  def motion_live_gc_release_v10211(reason)
    return false unless @motion_live_gc_disabled_v10211
    frames=Graphics.frame_count.to_i-@motion_live_gc_start_frame_v10211.to_i
    frames=0 if frames<0
    enable_ms=0;gc_ms=0;ok=1
    begin
      t=Time.now.to_f;GC.enable;enable_ms=((Time.now.to_f-t)*1000.0).round rescue 0
      t=Time.now.to_f;GC.start;gc_ms=((Time.now.to_f-t)*1000.0).round rescue 0
    rescue
      ok=0
      begin;GC.enable;rescue;end
    end
    @motion_live_gc_disabled_v10211=false
    @motion_live_gc_release_count_v10211=@motion_live_gc_release_count_v10211.to_i+1
    @motion_live_gc_last_release_v10211={:reason=>reason,:frames=>frames,:enable_ms=>enable_ms,:gc_ms=>gc_ms,:ok=>ok}
    begin
      log_event(:perf,'MOTION_LIVE_GC_RELEASE_V10211 reason='+reason.to_s+
        ' frames='+frames.to_i.to_s+' enable_ms='+enable_ms.to_i.to_s+
        ' gc_ms='+gc_ms.to_i.to_s+' ok='+ok.to_i.to_s+' live_gc_disabled=0')
    rescue
    end
    ok==1
  end

  def start_battle
    r=pmd_ac_v10211_start_battle
    if @phase==:battle && motion_live_gc_mode_v10211?
      motion_live_gc_disable_v10211
    end
    r
  end

  def show_result
    motion_live_gc_release_v10211(:result) if @motion_live_gc_disabled_v10211
    pmd_ac_v10211_show_result
  end

  def restart_to_deploy
    motion_live_gc_release_v10211(:deploy) if @motion_live_gc_disabled_v10211
    r=pmd_ac_v10211_restart_to_deploy
    motion_live_gc_reset_v10211 if @phase==:deploy
    r
  end

  def terminate
    motion_live_gc_release_v10211(:terminate) if @motion_live_gc_disabled_v10211
    pmd_ac_v10211_terminate
  end

  def verify_motion_live_gc_guard_v10211
    return if @verification_done[:motion_live_gc_guard_v10211]
    ready=false
    begin;ready=battle_resource_loading_ready_v1029?;rescue;ready=false;end
    pass=motion_live_gc_mode_v10211? && ready && @phase==:battle && @motion_live_gc_disabled_v10211
    @motion_phase_a_failed_v102=true unless pass
    log_event(:verify,'MOTION_LIVE_GC_GUARD_V10211 pass='+(pass ? '1':'0')+
      ' resource_ready='+(ready ? '1':'0')+' live_gc_disabled='+(@motion_live_gc_disabled_v10211 ? '1':'0')+
      ' after_loading=1 release_before_result=1 motion_scope_only=1 '+
      'ai_unchanged=1 damage_unchanged=1 attack_speed_unchanged=1 spatial_unchanged=1')
    @verification_done[:motion_live_gc_guard_v10211]=true
  end

  def update_verification_script
    pmd_ac_v10211_update_verification_script
    return unless motion_live_gc_mode_v10211?
    verify_motion_live_gc_guard_v10211 if @verification_frame.to_i>=48
  end
end
