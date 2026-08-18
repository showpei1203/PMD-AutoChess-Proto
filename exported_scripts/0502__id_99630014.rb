# encoding: UTF-8
#===============================================================================
# ■ PMD AutoChess - Status Result Completion Authority v1.05.18
#===============================================================================
# 【用途】
# 1. 修正 v1.05.17 封掉純 Status 的錯誤 cast muzzle / generic burst 後，Focus Action Lane
#    可能在真正狀態／能力結果套用前就開始 Result Hold 並完成的時序回歸。
# 2. 將「純 Status 技能是否可以結束 Focus」從裝飾性 VFX 是否仍存在，改為依正式
#    apply_skill_effects / focus_cast_mark_effect 的 semantic commit 判斷。
# 3. 保留 v1.05.17 Status VFX Ownership Seal：叫聲、吐絲等不恢復 elemental muzzle、
#    generic burst 或 generic focus impact。
#
# 【Windows 實機依據】
# v1.05.17 LOG 中 Growl：
# - Focus frame 306 開始、353 release。
# - frame 358 已開始 Result Hold，376 Focus COMPLETE，且 effect_seen=0。
# - 真正 -攻擊與藍色能力下降光圈到 frame 383 才套用。
# 因此舊 Completion 實際依賴了一部分被 v1.05.17 正確移除的 Presentation VFX，
# 裝飾物消失後反而讓 Action Lane 太早判定可結束。
#
# 【主要機制】
# - 只作用於 NORMAL battle、Focus Action Lane、且技能被 v1.05.16 判為 pure status。
# - intro release 後，只要 @focus_cast_effect_seen_v1055 仍為 false，就把 owner action
#   視為 semantic busy，讓既有 v1.05.8 owner-only action clock 繼續推進。
# - 一旦 focus_cast_mark_effect_v1055 確認真正效果 commit，立即解除 semantic wait，
#   後續照原本 effect tail → settle → v1.05.13 Result Hold 18f → world resume。
# - 若 miss / immune / 特殊路徑沒有 semantic commit，最多等待 48f 後 safety release，
#   防止永久 Focus lock。此 timeout 只解除 Presentation wait，不改技能命中／效果結果。
#
# 【設定／可調參數】
# STATUS_RESULT_COMMIT_WAIT_MAX_V10518 = 48
#   release 後等待 pure-status semantic effect commit 的最大 frame 數。
#
# 【不修改】
# - Damage / HP / AI / Energy / Attack Wait / Priority / hit timing
# - logical Spatial x/y/velocity/endpoints
# - v1.05.17 Status VFX Ownership
# - v1.05.13 KO / Result Hold 18f
# - v1.05.14 紅藍多光圈
# - v1.05.15 Important / Boss Focus tier
#
# 【事件／腳本呼叫方式】
# 無需事件呼叫，NORMAL battle 自動生效。
#
# 【實際範例】
# - Growl：release 後會繼續 owner-only clock，等真正 -攻擊套用；之後才開始 Result Hold。
# - String Shot：等 -速度 commit 後才進 Result Hold。
# - Water Gun：damage move，不進本 semantic wait，維持既有流程。
# - Status miss：最長等待 48f，之後 safety release，避免戰鬥卡死。
#
# 【LOG】
# BATTLE_STATUS_RESULT_COMPLETION_AUTHORITY_V10518 START ...
# BATTLE_STATUS_RESULT_WAIT_V10518 START skill=... wait_max=48 action/timer/hit/projectile diagnostics
# BATTLE_STATUS_RESULT_RESOLVE_V10518 BEFORE/AFTER ...
# BATTLE_STATUS_RESULT_PROJECTILE_V10518 ...
# BATTLE_STATUS_RESULT_COMMIT_V10518 skill=... wait_frames=...
# BATTLE_STATUS_RESULT_WAIT_TIMEOUT_V10518 skill=... waited=48
# BATTLE_STATUS_RESULT_COMPLETION_SUMMARY_V10518 waits=... commits=... timeouts=...
#===============================================================================
$imported={} unless defined?($imported)
$imported['PMD_AutoChess_StatusResultCompletionAuthority_v10518']=true

module PMD_AC
  STATUS_RESULT_COMMIT_WAIT_MAX_V10518 = 48
end

class Scene_PMD_AutoChess
  alias pmd_ac_v10518_owner_busy focus_cast_owner_action_busy_v1058? unless method_defined?(:pmd_ac_v10518_owner_busy)
  alias pmd_ac_v10518_mark_effect focus_cast_mark_effect_v1055 unless method_defined?(:pmd_ac_v10518_mark_effect)
  alias pmd_ac_v10518_start_battle start_battle unless method_defined?(:pmd_ac_v10518_start_battle)
  alias pmd_ac_v10518_focus_summary focus_cast_log_summary_v1055 unless method_defined?(:pmd_ac_v10518_focus_summary)
  alias pmd_ac_v10518_resolve_skill resolve_skill unless method_defined?(:pmd_ac_v10518_resolve_skill)
  alias pmd_ac_v10518_launch_projectile launch_projectile unless method_defined?(:pmd_ac_v10518_launch_projectile)

  def status_result_pure_focus_v10518?(u=nil)
    return false unless respond_to?(:focus_cast_action_lane_active_v1058?) && focus_cast_action_lane_active_v1058?
    return false if @focus_cast_intro_active_v1055
    user=(u==nil ? @focus_cast_owner_v1055 : u)
    return false if user==nil || user!=@focus_cast_owner_v1055
    key=user.instance_variable_get(:@skill_type)
    if respond_to?(:status_vfx_seal_pure_v10517?)
      return status_vfx_seal_pure_v10517?(key)
    end
    if respond_to?(:status_semantic_pure_v10516?)
      return status_semantic_pure_v10516?(key)
    end
    false
  rescue
    false
  end

  def status_result_wait_age_v10518
    release=@focus_cast_release_frame_v1058.to_i
    return -1 if release<0
    Graphics.frame_count.to_i-release
  rescue
    -1
  end

  def status_result_diag_v10518(u)
    return 'owner=NONE' if u==nil
    data=(u.respond_to?(:skill_data) ? u.skill_data : nil)
    delivery=(data==nil ? :none : (data[:delivery] || :instant))
    ranged=(u.respond_to?(:ranged?) && u.ranged?) ? 1 : 0
    owned=0
    begin
      (@projectile_sprites || []).each do |sp|
        next unless respond_to?(:focus_cast_owned_projectile_v1058?) && focus_cast_owned_projectile_v1058?(sp)
        owned+=1 unless sp.respond_to?(:finished) && sp.finished
      end
    rescue
    end
    ' action='+u.action.to_s+
      ' timer='+u.action_timer.to_i.to_s+
      ' hit_frame='+u.instance_variable_get(:@action_hit_frame).to_i.to_s+
      ' hit_done='+(u.instance_variable_get(:@action_hit_done) ? '1':'0')+
      ' delivery='+delivery.to_s+' ranged='+ranged.to_s+
      ' projectiles='+(@projectile_sprites || []).size.to_i.to_s+
      ' owned_projectiles='+owned.to_i.to_s
  rescue
    ' diag_error=1'
  end

  def resolve_skill(unit)
    key=(unit==nil ? nil : unit.instance_variable_get(:@skill_type))
    watch=unit!=nil && unit==@focus_cast_owner_v1055 && status_vfx_seal_pure_v10517?(key) rescue false
    if watch
      log_event(:battle,'BATTLE_STATUS_RESULT_RESOLVE_V10518 BEFORE skill='+key.to_s+status_result_diag_v10518(unit))
    end
    r=pmd_ac_v10518_resolve_skill(unit)
    if watch
      log_event(:battle,'BATTLE_STATUS_RESULT_RESOLVE_V10518 AFTER skill='+key.to_s+
        ' effect_seen='+(@focus_cast_effect_seen_v1055 ? '1':'0')+status_result_diag_v10518(unit))
    end
    r
  rescue
    pmd_ac_v10518_resolve_skill(unit)
  end

  def launch_projectile(user,target,kind,power,effect_type,tracking_override=nil,attack_modifier=nil,allow_substitute=true)
    watch=user!=nil && user==@focus_cast_owner_v1055 && status_vfx_seal_pure_v10517?(effect_type) rescue false
    before=(@projectile_sprites || []).size
    r=pmd_ac_v10518_launch_projectile(user,target,kind,power,effect_type,tracking_override,attack_modifier,allow_substitute)
    if watch
      after=(@projectile_sprites || []).size
      log_event(:battle,'BATTLE_STATUS_RESULT_PROJECTILE_V10518 skill='+effect_type.to_s+
        ' kind='+kind.to_s+' created='+(after-before).to_i.to_s+
        ' total='+after.to_i.to_s+status_result_diag_v10518(user))
    end
    r
  rescue
    pmd_ac_v10518_launch_projectile(user,target,kind,power,effect_type,tracking_override,attack_modifier,allow_substitute)
  end

  def status_result_wait_note_start_v10518(u)
    return if @status_result_wait_logged_v10518
    @status_result_wait_logged_v10518=true
    @status_result_wait_count_v10518=@status_result_wait_count_v10518.to_i+1
    key=(u==nil ? nil : u.instance_variable_get(:@skill_type))
    log_event(:battle,'BATTLE_STATUS_RESULT_WAIT_V10518 START skill='+(key==nil ? 'NONE' : key.to_s)+
      ' wait_max='+PMD_AC::STATUS_RESULT_COMMIT_WAIT_MAX_V10518.to_s+status_result_diag_v10518(u))
  rescue
  end

  def focus_cast_owner_action_busy_v1058?(u)
    base=pmd_ac_v10518_owner_busy(u)
    return true if base
    return false unless status_result_pure_focus_v10518?(u)
    return false if @focus_cast_effect_seen_v1055
    age=status_result_wait_age_v10518
    return false if age<0
    status_result_wait_note_start_v10518(u)
    if age<PMD_AC::STATUS_RESULT_COMMIT_WAIT_MAX_V10518
      return true
    end
    unless @status_result_wait_timeout_logged_v10518
      @status_result_wait_timeout_logged_v10518=true
      @status_result_wait_timeout_count_v10518=@status_result_wait_timeout_count_v10518.to_i+1
      key=u.instance_variable_get(:@skill_type) rescue nil
      log_event(:battle,'BATTLE_STATUS_RESULT_WAIT_TIMEOUT_V10518 skill='+(key==nil ? 'NONE' : key.to_s)+
        ' waited='+age.to_i.to_s+status_result_diag_v10518(u))
    end
    false
  rescue
    pmd_ac_v10518_owner_busy(u)
  end

  def focus_cast_mark_effect_v1055(user,target,kind)
    before=@focus_cast_effect_seen_v1055 ? true : false
    r=pmd_ac_v10518_mark_effect(user,target,kind)
    if !before && @focus_cast_effect_seen_v1055 && status_result_pure_focus_v10518?(user)
      @status_result_commit_count_v10518=@status_result_commit_count_v10518.to_i+1
      age=status_result_wait_age_v10518
      key=(user==nil ? nil : user.instance_variable_get(:@skill_type))
      log_event(:battle,'BATTLE_STATUS_RESULT_COMMIT_V10518 skill='+(key==nil ? 'NONE' : key.to_s)+
        ' wait_frames='+[age,0].max.to_i.to_s+' kind='+kind.to_s)
    end
    r
  rescue
    pmd_ac_v10518_mark_effect(user,target,kind)
  end

  def status_result_completion_reset_v10518
    @status_result_wait_count_v10518=0
    @status_result_commit_count_v10518=0
    @status_result_wait_timeout_count_v10518=0
    @status_result_wait_logged_v10518=false
    @status_result_wait_timeout_logged_v10518=false
    @status_result_completion_summary_logged_v10518=false
  end

  # 每次 Focus 開始會由 v1.05.15 經既有 focus_cast_begin_v1055 進入；
  # 在這裡不重 alias begin，改在 release frame 轉換時由 busy gate 自動建立 wait。
  # 為避免上一個 pure-status wait 的一次性旗標污染下一招，利用 owner/skill 變化懶重置。
  def status_result_wait_prepare_for_current_v10518(u)
    key=(u==nil ? nil : u.instance_variable_get(:@skill_type))
    token=[u==nil ? 0 : u.object_id,key,@focus_cast_start_frame_v1055.to_i]
    if @status_result_wait_token_v10518!=token
      @status_result_wait_token_v10518=token
      @status_result_wait_logged_v10518=false
      @status_result_wait_timeout_logged_v10518=false
    end
    true
  rescue
    false
  end

  alias pmd_ac_v10518_owner_busy_with_prepare focus_cast_owner_action_busy_v1058? unless method_defined?(:pmd_ac_v10518_owner_busy_with_prepare)
  def focus_cast_owner_action_busy_v1058?(u)
    status_result_wait_prepare_for_current_v10518(u)
    pmd_ac_v10518_owner_busy_with_prepare(u)
  rescue
    pmd_ac_v10518_owner_busy_with_prepare(u)
  end

  def start_battle
    r=pmd_ac_v10518_start_battle
    if respond_to?(:verification_mode) && verification_mode==:normal
      status_result_completion_reset_v10518
      log_event(:battle,'BATTLE_STATUS_RESULT_COMPLETION_AUTHORITY_V10518 START'+
        ' pure_status_requires_effect_commit=1 wait_max='+PMD_AC::STATUS_RESULT_COMMIT_WAIT_MAX_V10518.to_s+
        ' result_hold_after_commit=1 status_vfx_v10517_retained=1'+
        ' damage_formula_unchanged=1 hp_unchanged=1 ai_unchanged=1 energy_unchanged=1'+
        ' attack_wait_unchanged=1 spatial_endpoint_unchanged=1 hit_timing_unchanged=1')
    end
    r
  end

  def status_result_completion_summary_v10518
    return false if @status_result_completion_summary_logged_v10518
    @status_result_completion_summary_logged_v10518=true
    log_event(:battle,'BATTLE_STATUS_RESULT_COMPLETION_SUMMARY_V10518'+
      ' waits='+@status_result_wait_count_v10518.to_i.to_s+
      ' commits='+@status_result_commit_count_v10518.to_i.to_s+
      ' timeouts='+@status_result_wait_timeout_count_v10518.to_i.to_s+
      ' result_hold_after_commit=1')
    true
  rescue
    false
  end

  def focus_cast_log_summary_v1055
    r=pmd_ac_v10518_focus_summary
    status_result_completion_summary_v10518
    r
  rescue
    false
  end
end
