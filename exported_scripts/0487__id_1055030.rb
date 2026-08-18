# encoding: UTF-8
#==============================================================================
# ■ PMD AutoChess - Original Pace Restore + Clarity Observation Probe v1.05.3
#==============================================================================
# 【用途】
# 1. 正式回退 v1.05.0～v1.05.2 的 Battle Readability 節奏／HP／傷害／Energy／
#    額外戰場因果 UI，重新以 v1.04.17 Windows PASS 為正式戰鬥基底。
# 2. 保留 v1.04.17 以前所有 PMD Motion、AI、Spatial、Damage、Energy、Field、
#    Ability、Reward、Collection、Performance 等既有功能與數值。
# 3. 為後續「玩家看得懂聰明 AI 的技能使用、目標與效果順序」建立純診斷 Probe。
#    Probe 只記錄原始戰鬥中技能解算／傷害／效果事件的時間聚集程度，不新增任何
#    戰場 UI、不延遲事件、不改數值、不改行動順序。
#
# 【主要設定】
# CLARITY_CAST_CLUSTER_WINDOW_V1053 = 18
#   兩次 skill resolve 相距 <=18 frame 時，視為玩家可能需要同時理解的施放群。
# CLARITY_IMPACT_CLUSTER_WINDOW_V1053 = 6
#   兩個 damage/effect packet 相距 <=6 frame 時，視為可能重疊的結果群。
# CLARITY_TRACE_SAMPLE_LIMIT_V1053 = 8
#   LOG summary 最多保留 8 個代表性密集事件，避免 LOG 無限增肥。
#
# 【機制規則】
# - Frozen Combat Core 不直接修改；本腳本為 trailing alias/hook layer。
# - 正式戰鬥數值完全沿用 v1.04.17：HP、Damage Formula、Attack Wait、Action Timing、
#   Native Motion hold、Energy gain、logical movement 全部不乘任何新倍率。
# - v1.05.0 A/B、v1.05.1 IMPACT-I、v1.05.2 Causality UI 不存在於本 build 的
#   Scripts.rvdata，因此不需要以「反向倍率」抵消，避免殘留副作用。
# - Probe 只讀取 Graphics.frame_count、unit.action、HP 前後差與 skill_data。
# - 不新增 presentation stagger、不新增 tether、不新增事件 feed、不新增 sequence badge。
# - PMD Motion verifier 仍可使用；Probe 只在 NORMAL battle 記錄。
#
# 【可調參數】
# - 若下一版需要判斷玩家一次能否追蹤多個事件，可調整 18f / 6f cluster window。
# - 此版禁止利用 Probe 統計直接修改 Damage、HP、Attack Speed 或 Energy。
#
# 【事件／腳本呼叫方式】
# 無需事件呼叫。NORMAL 戰鬥自動輸出：
#   BATTLE_ORIGINAL_PACE_RESTORE_V1053
#   BATTLE_CLARITY_OBSERVATION_PROBE_V1053 START
#   BATTLE_CLARITY_OBSERVATION_SUMMARY_V1053
#
# 【實際範例】
# - 兩隻寶可夢在 12 frame 內各自解算技能：cast_cluster 會 +1，但實際技能不排隊。
# - 三個 Damage/Status packet 在 5 frame 內完成：impact_cluster 會記錄代表 sample，
#   供下一版決定是否需要更輕量的視覺焦點，而不是先把整場戰鬥降速。
#==============================================================================
$imported={} unless defined?($imported)
$imported['PMD_AutoChess_OriginalPaceRestore_ClarityProbe_v1053']=true

module PMD_AC
  CLARITY_CAST_CLUSTER_WINDOW_V1053 = 18
  CLARITY_IMPACT_CLUSTER_WINDOW_V1053 = 6
  CLARITY_TRACE_SAMPLE_LIMIT_V1053 = 8
end

class Scene_PMD_AutoChess
  alias pmd_ac_v1053_restore_start_battle start_battle unless method_defined?(:pmd_ac_v1053_restore_start_battle)
  alias pmd_ac_v1053_restore_resolve_skill resolve_skill unless method_defined?(:pmd_ac_v1053_restore_resolve_skill)
  alias pmd_ac_v1053_restore_deal_direct_damage deal_direct_damage unless method_defined?(:pmd_ac_v1053_restore_deal_direct_damage)
  alias pmd_ac_v1053_restore_apply_skill_effects apply_skill_effects unless method_defined?(:pmd_ac_v1053_restore_apply_skill_effects)
  alias pmd_ac_v1053_restore_check_battle_end check_battle_end unless method_defined?(:pmd_ac_v1053_restore_check_battle_end)

  def clarity_probe_normal_v1053?
    return false unless @phase==:battle
    if respond_to?(:motion_phase_b_verifier_active_v1036?)
      return false if motion_phase_b_verifier_active_v1036?
    end
    true
  rescue
    false
  end

  def clarity_probe_reset_v1053
    @clarity_probe_start_frame_v1053=Graphics.frame_count
    @clarity_cast_events_v1053=[]
    @clarity_impact_events_v1053=[]
    @clarity_effect_events_v1053=[]
    @clarity_cast_cluster_v1053=0
    @clarity_impact_cluster_v1053=0
    @clarity_cross_source_impact_cluster_v1053=0
    @clarity_probe_samples_v1053=[]
    @clarity_probe_summary_logged_v1053=false
    true
  rescue
    false
  end

  def clarity_probe_frame_v1053
    base=@clarity_probe_start_frame_v1053
    base=Graphics.frame_count if base==nil
    Graphics.frame_count-base.to_i
  rescue
    0
  end

  def clarity_probe_unit_name_v1053(unit)
    return '-' if unit==nil
    return unit.log_name.to_s if unit.respond_to?(:log_name)
    unit.to_s
  rescue
    '?'
  end

  def clarity_probe_move_key_v1053(unit)
    return :unknown if unit==nil
    data=unit.skill_data rescue nil
    return :unknown if data==nil
    (data[:canonical_move_key] || data[:move_key] || data[:name] || :unknown)
  rescue
    :unknown
  end

  def clarity_probe_target_v1053(unit)
    return nil if unit==nil
    unit.instance_variable_get(:@skill_target)
  rescue
    nil
  end

  def clarity_probe_sample_v1053(text)
    @clarity_probe_samples_v1053=[] if @clarity_probe_samples_v1053==nil
    return false if @clarity_probe_samples_v1053.size>=PMD_AC::CLARITY_TRACE_SAMPLE_LIMIT_V1053
    @clarity_probe_samples_v1053.push(text.to_s)
    true
  rescue
    false
  end

  def clarity_probe_register_cast_v1053(unit)
    return false unless clarity_probe_normal_v1053?
    @clarity_cast_events_v1053=[] if @clarity_cast_events_v1053==nil
    frame=clarity_probe_frame_v1053
    source=clarity_probe_unit_name_v1053(unit)
    target=clarity_probe_unit_name_v1053(clarity_probe_target_v1053(unit))
    move=clarity_probe_move_key_v1053(unit).to_s
    last=@clarity_cast_events_v1053[-1]
    if last!=nil && frame-last[0].to_i<=PMD_AC::CLARITY_CAST_CLUSTER_WINDOW_V1053
      @clarity_cast_cluster_v1053=@clarity_cast_cluster_v1053.to_i+1
      clarity_probe_sample_v1053('cast@'+frame.to_s+':'+source+'>'+target+':'+move+' after='+
        (frame-last[0].to_i).to_s+'f')
    end
    @clarity_cast_events_v1053.push([frame,source,target,move])
    true
  rescue
    false
  end

  def clarity_probe_register_impact_v1053(user,target,kind,amount=0)
    return false unless clarity_probe_normal_v1053?
    @clarity_impact_events_v1053=[] if @clarity_impact_events_v1053==nil
    frame=clarity_probe_frame_v1053
    source=clarity_probe_unit_name_v1053(user)
    tname=clarity_probe_unit_name_v1053(target)
    last=@clarity_impact_events_v1053[-1]
    if last!=nil && frame-last[0].to_i<=PMD_AC::CLARITY_IMPACT_CLUSTER_WINDOW_V1053
      @clarity_impact_cluster_v1053=@clarity_impact_cluster_v1053.to_i+1
      if last[1].to_s!=source.to_s
        @clarity_cross_source_impact_cluster_v1053=@clarity_cross_source_impact_cluster_v1053.to_i+1
      end
      clarity_probe_sample_v1053('impact@'+frame.to_s+':'+source+'>'+tname+':'+kind.to_s+
        ' amount='+amount.to_i.to_s+' after='+(frame-last[0].to_i).to_s+'f')
    end
    @clarity_impact_events_v1053.push([frame,source,tname,kind,amount.to_i])
    true
  rescue
    false
  end

  def start_battle
    r=pmd_ac_v1053_restore_start_battle
    if clarity_probe_normal_v1053?
      clarity_probe_reset_v1053
      log_event(:battle,'BATTLE_ORIGINAL_PACE_RESTORE_V1053 pass=1 source=v1.04.17'+
        ' hp=original damage=original attack_wait=original action_timing=original visual_timing=original'+
        ' energy=original movement=original v1050_removed=1 v1051_removed=1 v1052_removed=1')
      log_event(:battle,'BATTLE_CLARITY_OBSERVATION_PROBE_V1053 START cast_window=18f impact_window=6f'+
        ' visible_ui_added=0 gameplay_delay=0 damage_order_unchanged=1 ai_unchanged=1 spatial_unchanged=1')
    end
    r
  end

  def resolve_skill(*args)
    unit=(args[0] rescue nil)
    clarity_probe_register_cast_v1053(unit)
    pmd_ac_v1053_restore_resolve_skill(*args)
  end

  def deal_direct_damage(*args)
    user=(args[0] rescue nil)
    target=(args[1] rescue nil)
    before=(target==nil ? 0 : (target.hp.to_i rescue 0))
    r=pmd_ac_v1053_restore_deal_direct_damage(*args)
    after=(target==nil ? before : (target.hp.to_i rescue before))
    amount=[before-after,0].max
    kind=(user!=nil && (user.action rescue nil)==:skill) ? :skill_damage : :damage
    clarity_probe_register_impact_v1053(user,target,kind,amount)
    r
  end

  def apply_skill_effects(*args)
    user=(args[0] rescue nil)
    target=(args[1] rescue nil)
    r=pmd_ac_v1053_restore_apply_skill_effects(*args)
    if clarity_probe_normal_v1053?
      @clarity_effect_events_v1053=[] if @clarity_effect_events_v1053==nil
      @clarity_effect_events_v1053.push([clarity_probe_frame_v1053,
        clarity_probe_unit_name_v1053(user),clarity_probe_unit_name_v1053(target)])
      clarity_probe_register_impact_v1053(user,target,:effect,0)
    end
    r
  end

  def clarity_probe_log_summary_v1053
    return false if @clarity_probe_summary_logged_v1053
    @clarity_probe_summary_logged_v1053=true
    casts=(@clarity_cast_events_v1053 || []).size
    impacts=(@clarity_impact_events_v1053 || []).size
    effects=(@clarity_effect_events_v1053 || []).size
    samples=(@clarity_probe_samples_v1053 || []).join('|')
    log_event(:battle,'BATTLE_CLARITY_OBSERVATION_SUMMARY_V1053 casts='+casts.to_i.to_s+
      ' cast_clusters_18f='+@clarity_cast_cluster_v1053.to_i.to_s+
      ' impacts='+impacts.to_i.to_s+' effects='+effects.to_i.to_s+
      ' impact_clusters_6f='+@clarity_impact_cluster_v1053.to_i.to_s+
      ' cross_source_clusters_6f='+@clarity_cross_source_impact_cluster_v1053.to_i.to_s+
      ' visible_ui_added=0 gameplay_delay=0 original_pace_retained=1 samples=['+samples+']')
    true
  rescue
    false
  end

  def check_battle_end
    before=@phase
    r=pmd_ac_v1053_restore_check_battle_end
    clarity_probe_log_summary_v1053 if before==:battle && @phase!=:battle
    r
  end
end
