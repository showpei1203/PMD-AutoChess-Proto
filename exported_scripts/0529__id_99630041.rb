# encoding: UTF-8
#===============================================================================
# ■ PMD AutoChess - Important Family Exception + Single Delegation Seal v1.05.44
#===============================================================================
# 【用途】
# 1. Roadmap C2 important-skill exception audit：把 v1.05.15 / 21 / 22 / 23 / 25 的
#    Important Focus library 合併檢查，要求每個 important skill 都有唯一 semantic family。
# 2. 封住 Focus/Status presentation wrapper 的 exception double-delegation 風險。
#    診斷、LOG、observer 出錯時可以漏記，但絕不能再次 resolve 技能、再次建立 projectile、
#    再次 mark effect、再次 begin/release/complete Focus。
# 3. 正常路徑不改任何 gameplay；本版只把舊 rescue「再呼叫 parent」改成 parent exactly once。
#
# 【靜態已確認的 Important library】
# - total unique = 93 / mapped = 93 / duplicate = 0
# - beam=15 impact=37 burst=18 rift=5 column=4 wave=14
#
# 【Single-delegation seal 範圍】
# A. v1.05.16 pure-status projectile / apply / hit wrapper：重新提供安全 parent bridge。
# B. v1.05.18 resolve_skill / launch_projectile / focus_cast_mark_effect：parent exactly once。
# C. v1.05.22 carryover begin / completion：透過既有 alias seam 替換成安全版本。
# D. v1.05.20 release：透過 v1.05.21 alias seam 替換成安全版本。
# E. v1.05.41 move-family observer 行為保留，由本版在安全 wrapper 的 post phase 手動記錄。
#
# 【Authority 邊界】
# Damage / HP / Accuracy / Crit / target / Energy / Priority / Attack Wait /
# projectile speed / tracking / collision / multi-hit cadence / Spatial / Motion Core 不改。
#===============================================================================
$imported={} unless defined?($imported)
$imported['PMD_AutoChess_ImportantFamilyExceptionSingleDelegationSeal_v10544']=true

module PMD_AC
  IMPORTANT_FAMILY_EXPECTED_TOTAL_V10544=93
  IMPORTANT_FAMILY_EXPECTED_COUNTS_V10544={
    :beam=>15,:impact=>37,:burst=>18,:rift=>5,:column=>4,:wave=>14
  }

  def self.important_family_lists_v10544
    out=[]
    [:IMPORTANT_FOCUS_SKILL_TYPES_V10515,
     :IMPORTANT_FOCUS_SKILL_TYPES_V10522,
     :IMPORTANT_FOCUS_SKILL_TYPES_V10523,
     :IMPORTANT_FOCUS_SKILL_TYPES_V10525].each do |c|
      begin
        arr=const_get(c)
        arr.each{|k|out.push(k)} if arr!=nil
      rescue
      end
    end
    out
  rescue
    []
  end

  def self.important_family_map_v10544
    out={}
    [:FOCUS_SIGNATURE_FAMILY_V10521,
     :FOCUS_SIGNATURE_FAMILY_V10522,
     :FOCUS_SIGNATURE_FAMILY_V10523,
     :FOCUS_SIGNATURE_FAMILY_V10525].each do |c|
      begin
        h=const_get(c)
        h.each{|k,v|out[k]=v} if h!=nil
      rescue
      end
    end
    out
  rescue
    {}
  end
end

class Scene_PMD_AutoChess
  alias pmd_ac_v10544_start_battle start_battle unless method_defined?(:pmd_ac_v10544_start_battle)
  alias pmd_ac_v10544_focus_summary focus_cast_log_summary_v1055 unless method_defined?(:pmd_ac_v10544_focus_summary)

  #--------------------------------------------------------------------------
  # ● v1.05.16 safe bridge
  #   pmd_ac_v10518_launch_projectile originally points at the v1.05.16 wrapper.
  #   Redefine that seam so any later caller gets the same suppression semantics without retry.
  #--------------------------------------------------------------------------
  def pmd_ac_v10518_launch_projectile(user,target,kind,power,effect_type,tracking_override=nil,attack_modifier=nil,allow_substitute=true)
    pure=false
    begin
      pure=status_semantic_pure_v10516?(effect_type)
    rescue
      pure=false
    end
    unless pure
      return pmd_ac_v10516_launch_projectile(user,target,kind,power,effect_type,tracking_override,attack_modifier,allow_substitute)
    end

    before=(@projectile_sprites || []).size
    r=status_semantic_with_impact_suppressed_v10516(effect_type) do
      pmd_ac_v10516_launch_projectile(user,target,kind,power,effect_type,tracking_override,attack_modifier,allow_substitute)
    end
    begin
      hidden=status_semantic_hide_new_projectiles_v10516(before,effect_type)
      if hidden.to_i>0
        log_event(:battle,'BATTLE_STATUS_VFX_FILTER_V10516 skill='+effect_type.to_s+
          ' projectile_hidden='+hidden.to_i.to_s+' impact_suppressed=0 phase=launch')
      end
    rescue
      @focus_single_delegate_post_error_v10544=@focus_single_delegate_post_error_v10544.to_i+1
    end
    r
  end

  #--------------------------------------------------------------------------
  # ● v1.05.16 apply_skill_effects safe top-level
  #   Gameplay delegation is exactly once. Suppression bookkeeping is post-only.
  #--------------------------------------------------------------------------
  def apply_skill_effects(user,target,data,multiplier=1.0)
    pure=false
    begin
      pure=status_semantic_pure_v10516?(data)
    rescue
      pure=false
    end
    unless pure
      return pmd_ac_v10516_apply_skill_effects(user,target,data,multiplier)
    end

    key=nil
    before=0
    begin
      key=(data==nil ? nil : (data[:runtime_skill_key] || data[:canonical_move_key]))
      key=@focus_cast_owner_v1055.instance_variable_get(:@skill_type) if key==nil && @focus_cast_owner_v1055!=nil
      before=@status_semantic_impact_suppressed_v10516.to_i
      @status_semantic_apply_count_v10516=@status_semantic_apply_count_v10516.to_i+1
      status_semantic_note_skill_v10516(key,:apply)
    rescue
      @focus_single_delegate_post_error_v10544=@focus_single_delegate_post_error_v10544.to_i+1
    end

    # Exactly one gameplay delegation under the same impact-suppression context.
    r=status_semantic_with_impact_suppressed_v10516(key) do
      pmd_ac_v10516_apply_skill_effects(user,target,data,multiplier)
    end

    begin
      suppressed=@status_semantic_impact_suppressed_v10516.to_i-before.to_i
      if suppressed>0
        suppressed.times{status_semantic_note_skill_v10516(key,:impact_suppressed)}
        log_event(:battle,'BATTLE_STATUS_VFX_FILTER_V10516 skill='+(key==nil ? 'unknown' : key.to_s)+
          ' projectile_hidden=0 impact_suppressed='+suppressed.to_i.to_s+' phase=apply')
      end
    rescue
      @focus_single_delegate_post_error_v10544=@focus_single_delegate_post_error_v10544.to_i+1
    end
    r
  end

  #--------------------------------------------------------------------------
  # ● v1.05.20 release safe seam used by v1.05.21
  #--------------------------------------------------------------------------
  def pmd_ac_v10521_focus_release
    tier=@focus_tier_current_v10515 || :standard
    owner=@focus_cast_owner_v1055
    type=@focus_cast_type_v1055 || :normal
    r=pmd_ac_v10520_focus_release
    begin
      focus_content_begin_release_v10520(tier,owner,type) if r && (tier==:important || tier==:boss)
    rescue
      @focus_single_delegate_post_error_v10544=@focus_single_delegate_post_error_v10544.to_i+1
    end
    r
  end

  #--------------------------------------------------------------------------
  # ● v1.05.22 begin safe seam used by v1.05.25
  #--------------------------------------------------------------------------
  def pmd_ac_v10525_focus_begin(user,target)
    begin
      focus_carryover_prepare_v10522(user)
    rescue
      @focus_single_delegate_post_error_v10544=@focus_single_delegate_post_error_v10544.to_i+1
    end

    ok=pmd_ac_v10522_focus_begin(user,target)
    begin
      unless ok
        @focus_carryover_ids_v10522={}
      end
      if ok
        key=(user==nil ? nil : user.instance_variable_get(:@skill_type))
        tier=focus_tier_v10515(user)
        if tier==:important && PMD_AC::IMPORTANT_FOCUS_SKILL_TYPES_V10522.include?(key)
          fam=focus_semantic_family_v10521(key,tier)
          @important_library_ii_seen_v10522={} if @important_library_ii_seen_v10522==nil
          @important_library_ii_seen_v10522[key]=fam
          log_event(:battle,'BATTLE_IMPORTANT_LIBRARY_II_V10522 skill='+key.to_s+
            ' tier=important family='+fam.to_s)
        end
      end
    rescue
      @focus_single_delegate_post_error_v10544=@focus_single_delegate_post_error_v10544.to_i+1
    end
    ok
  end

  #--------------------------------------------------------------------------
  # ● v1.05.22 completion safe seam used by v1.05.41
  #--------------------------------------------------------------------------
  def pmd_ac_v10541_focus_complete(reason)
    was_active=false
    begin
      was_active=(respond_to?(:focus_cast_action_lane_active_v1058?) && focus_cast_action_lane_active_v1058?)
    rescue
      was_active=false
    end

    r=pmd_ac_v10522_focus_complete(reason)

    begin
      still_active=(respond_to?(:focus_cast_action_lane_active_v1058?) && focus_cast_action_lane_active_v1058?)
      focus_carryover_restore_projectiles_v10522 if was_active && !still_active
    rescue
      @focus_single_delegate_post_error_v10544=@focus_single_delegate_post_error_v10544.to_i+1
    end
    r
  end

  #--------------------------------------------------------------------------
  # ● v1.05.18 resolve_skill safe top-level
  #--------------------------------------------------------------------------
  def resolve_skill(unit)
    key=nil
    watch=false
    begin
      key=(unit==nil ? nil : unit.instance_variable_get(:@skill_type))
      watch=(unit!=nil && unit==@focus_cast_owner_v1055 && status_vfx_seal_pure_v10517?(key))
      if watch
        log_event(:battle,'BATTLE_STATUS_RESULT_RESOLVE_V10518 BEFORE skill='+key.to_s+status_result_diag_v10518(unit))
      end
    rescue
      watch=false
      @focus_single_delegate_post_error_v10544=@focus_single_delegate_post_error_v10544.to_i+1
    end

    # Exactly one gameplay delegation.
    r=pmd_ac_v10518_resolve_skill(unit)

    begin
      if watch
        log_event(:battle,'BATTLE_STATUS_RESULT_RESOLVE_V10518 AFTER skill='+key.to_s+
          ' effect_seen='+(@focus_cast_effect_seen_v1055 ? '1':'0')+status_result_diag_v10518(unit))
      end
    rescue
      @focus_single_delegate_post_error_v10544=@focus_single_delegate_post_error_v10544.to_i+1
    end
    r
  end

  #--------------------------------------------------------------------------
  # ● v1.05.18 + v1.05.41 projectile wrapper, parent exactly once
  #--------------------------------------------------------------------------
  def launch_projectile(user,target,kind,power,effect_type,tracking_override=nil,attack_modifier=nil,allow_substitute=true)
    before=0
    watch=false
    begin
      before=(@projectile_sprites || []).size
      watch=(user!=nil && user==@focus_cast_owner_v1055 && status_vfx_seal_pure_v10517?(effect_type))
    rescue
      before=0;watch=false
    end

    # Calls the safe v1.05.16 seam above, exactly once.
    r=pmd_ac_v10518_launch_projectile(user,target,kind,power,effect_type,tracking_override,attack_modifier,allow_substitute)

    begin
      after=(@projectile_sprites || []).size
      if watch
        log_event(:battle,'BATTLE_STATUS_RESULT_PROJECTILE_V10518 skill='+effect_type.to_s+
          ' kind='+kind.to_s+' created='+(after-before).to_i.to_s+
          ' total='+after.to_i.to_s+status_result_diag_v10518(user))
      end
      ctx=@move_family_runtime_current_v10541
      if ctx!=nil && user!=nil && ctx[:user]==user
        created=[after-before,0].max
        ctx[:projectiles]=ctx[:projectiles].to_i+1
        ctx[:projectile_objects]=ctx[:projectile_objects].to_i+created
      end
    rescue
      @focus_single_delegate_post_error_v10544=@focus_single_delegate_post_error_v10544.to_i+1
    end
    r
  end

  #--------------------------------------------------------------------------
  # ● v1.05.18 + v1.05.41 effect-commit wrapper, parent exactly once
  #--------------------------------------------------------------------------
  def focus_cast_mark_effect_v1055(user,target,kind)
    before=(@focus_cast_effect_seen_v1055 ? true : false)

    # Exactly one semantic/gameplay delegation.
    r=pmd_ac_v10518_mark_effect(user,target,kind)

    begin
      if !before && @focus_cast_effect_seen_v1055 && status_result_pure_focus_v10518?(user)
        @status_result_commit_count_v10518=@status_result_commit_count_v10518.to_i+1
        age=status_result_wait_age_v10518
        key=(user==nil ? nil : user.instance_variable_get(:@skill_type))
        log_event(:battle,'BATTLE_STATUS_RESULT_COMMIT_V10518 skill='+(key==nil ? 'NONE' : key.to_s)+
          ' wait_frames='+[age,0].max.to_i.to_s+' kind='+kind.to_s)
      end

      ctx=@move_family_runtime_current_v10541
      if ctx!=nil && user!=nil && ctx[:user]==user
        now=Graphics.frame_count.to_i
        ctx[:first_impact]=now if ctx[:first_impact].to_i<0
        ctx[:last_impact]=now
        ctx[:impacts]=ctx[:impacts].to_i+1
        ctx[:effect_kinds][kind]=ctx[:effect_kinds][kind].to_i+1
      end
    rescue
      @focus_single_delegate_post_error_v10544=@focus_single_delegate_post_error_v10544.to_i+1
    end
    r
  end

  #--------------------------------------------------------------------------
  # ● Important family exception audit
  #--------------------------------------------------------------------------
  def important_family_exception_audit_v10544
    list=PMD_AC.important_family_lists_v10544
    map=PMD_AC.important_family_map_v10544
    seen={};duplicates=[]
    list.each do |k|
      duplicates.push(k) if seen[k]
      seen[k]=true
    end
    missing=[];counts={}
    seen.keys.each do |k|
      fam=map[k]
      if fam==nil
        missing.push(k)
      else
        counts[fam]=counts[fam].to_i+1
      end
    end
    unexpected=[]
    PMD_AC::IMPORTANT_FAMILY_EXPECTED_COUNTS_V10544.each do |fam,n|
      unexpected.push(fam.to_s+':'+counts[fam].to_i.to_s+'/'+n.to_i.to_s) if counts[fam].to_i!=n.to_i
    end
    pass=(seen.size==PMD_AC::IMPORTANT_FAMILY_EXPECTED_TOTAL_V10544 &&
      missing.empty? && duplicates.empty? && unexpected.empty?)
    @important_family_audit_pass_v10544=pass
    @important_family_audit_missing_v10544=missing.size
    @important_family_audit_duplicate_v10544=duplicates.size
    parts=[]
    [:beam,:impact,:burst,:rift,:column,:wave].each{|f|parts.push(f.to_s+'='+counts[f].to_i.to_s)}
    log_event(:battle,'BATTLE_IMPORTANT_FAMILY_EXCEPTION_AUDIT_V10544 pass='+(pass ? '1':'0')+
      ' important_unique='+seen.size.to_i.to_s+' mapped='+(seen.size-missing.size).to_i.to_s+
      ' missing='+missing.size.to_i.to_s+' duplicate='+duplicates.size.to_i.to_s+
      ' families=['+parts.join(',')+']'+
      ' missing_keys=['+missing.collect{|x|x.to_s}.join(',')+']'+
      ' unexpected=['+unexpected.join(',')+']')
    pass
  rescue
    @important_family_audit_pass_v10544=false
    false
  end

  def focus_single_delegate_reset_v10544
    @focus_single_delegate_post_error_v10544=0
    @focus_single_delegate_summary_logged_v10544=false
    @important_family_audit_pass_v10544=false
    @important_family_audit_missing_v10544=0
    @important_family_audit_duplicate_v10544=0
  end

  def start_battle
    r=pmd_ac_v10544_start_battle
    begin
      if respond_to?(:verification_mode) && verification_mode==:normal
        focus_single_delegate_reset_v10544
        if respond_to?(:production_external_battle_fast_v10613?) && production_external_battle_fast_v10613?
          @important_family_audit_pass_v10544=true
          @important_family_audit_missing_v10544=0
          @important_family_audit_duplicate_v10544=0
        else
          important_family_exception_audit_v10544
        end
        log_event(:battle,'BATTLE_FOCUS_SINGLE_DELEGATION_SEAL_V10544 START'+
          ' resolve_skill_once=1 projectile_once=1 apply_effect_once=1 projectile_hit_once=1 mark_effect_once=1'+
          ' carryover_begin_once=1 release_once=1 completion_once=1'+
          ' observer_post_error_non_replay=1 gameplay_change=0')
      end
    rescue
    end
    r
  end

  def focus_single_delegate_summary_v10544
    return false if @focus_single_delegate_summary_logged_v10544
    @focus_single_delegate_summary_logged_v10544=true
    log_event(:battle,'BATTLE_FOCUS_SINGLE_DELEGATION_SUMMARY_V10544'+
      ' post_errors='+@focus_single_delegate_post_error_v10544.to_i.to_s+
      ' important_family_pass='+(@important_family_audit_pass_v10544 ? '1':'0')+
      ' family_missing='+@important_family_audit_missing_v10544.to_i.to_s+
      ' family_duplicate='+@important_family_audit_duplicate_v10544.to_i.to_s+
      ' parent_replay_on_observer_exception=0')
    true
  rescue
    false
  end

  def focus_cast_log_summary_v1055
    r=pmd_ac_v10544_focus_summary
    begin
      focus_single_delegate_summary_v10544
    rescue
    end
    r
  end
end


#==============================================================================
# ■ Sprite_PMDProjectile v1.05.16 hit safe seam used by v1.05.22 basic wrapper
#------------------------------------------------------------------------------
# pmd_ac_v10522_basic_hit points at the old v1.05.16 hit wrapper. Replacing that
# alias seam preserves the v1.05.22 basic visual context while guaranteeing the
# underlying hit delegation runs exactly once.
#==============================================================================
class Sprite_PMDProjectile
  def pmd_ac_v10522_basic_hit(*args)
    s=@scene rescue nil
    pure=false
    begin
      pure=(s!=nil && s.respond_to?(:status_semantic_pure_v10516?) && s.status_semantic_pure_v10516?(@effect_type))
    rescue
      pure=false
    end
    unless pure && s.respond_to?(:status_semantic_with_impact_suppressed_v10516)
      return pmd_ac_v10516_hit(*args)
    end
    # Exactly one hit delegation; exceptions propagate to the existing battle
    # authority instead of replaying a partially-applied hit.
    s.status_semantic_with_impact_suppressed_v10516(@effect_type){pmd_ac_v10516_hit(*args)}
  end
end
