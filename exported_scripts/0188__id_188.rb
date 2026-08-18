#==============================================================================
# 【PMD AutoChess 中文維護說明】
# 腳本：PMD AutoChess Proto v0.43.1
# 分類：核心戰鬥 Runtime
#
# 【用途／機制】
# 承接前序 Data／Config，實際執行戰鬥 Scene、Unit、AI、技能與呈現。
#
# 【怎麼調整】
# 一般平衡與資料調整不要直接改 Runtime；若要追加功能，建議在較後腳本 alias 原方法後擴充。
#
# 【Runtime 主要方法（查流程時可直接搜尋）】
# - start / reactive_verification_heal_full_v0431 / verify_reactive_sucker_v043
#
# 【維護規則】
# - RPG Maker VX / RGSS2 / Ruby 1.8 相容。
# - instance_uid 才是 Pokémon 個體身份；Actor ID 只是容器。
# - 新增行為優先沿用既有 helper／Data 表；避免破壞已 Freeze 的舊核心。
# - 本專案新腳本也必須保留同等級的中文說明與實際範例。
#==============================================================================
#===============================================================================
# ■ PMD AutoChess Proto v0.43.1
#    Reactive Priority Verification Heal Compatibility Fix
#-------------------------------------------------------------------------------
# Additive patch on v0.43. The reactive runtime mechanics are unchanged.
# Fixes a verifier-only call to an optional helper that is not defined by the
# current Game_PMDChessUnit implementation.
#===============================================================================
class Scene_PMD_AutoChess
  alias pmd_ac_v0431_start start unless method_defined?(:pmd_ac_v0431_start)

  def start
    pmd_ac_v0431_start
    begin
      if FileTest.exist?(PMD_AC::BATTLE_LOG_FILE)
        text=File.open(PMD_AC::BATTLE_LOG_FILE,'rb'){|f|f.read}
        text.sub!(/PMD AutoChess Proto v0\.43 Battle Verification Log/,
                  'PMD AutoChess Proto v0.43.1 Battle Verification Log')
        File.open(PMD_AC::BATTLE_LOG_FILE,'wb'){|f|f.write(text)}
      end
    rescue
    end
    log_event(:reactive_priority,
      'PATCH v0.43.1 verifier_heal_guard=1 fallback_hp_restore=1 mechanics_unchanged=1')
  end

  # Verification-only full HP restore. Some older verification layers probe an
  # optional verification_heal_full helper, but Game_PMDChessUnit does not
  # define it in this project. Keep the verifier robust without touching combat.
  def reactive_verification_heal_full_v0431(unit)
    return false if unit==nil
    if unit.respond_to?(:verification_heal_full)
      unit.verification_heal_full
      return true
    end
    if unit.respond_to?(:maxhp)
      unit.instance_variable_set(:@hp,unit.maxhp.to_i)
      unit.instance_variable_set(:@dead_started,false)
      return true
    end
    false
  end

  # Override verifier only. Runtime Sucker Punch mechanics remain v0.43.
  def verify_reactive_sucker_v043
    return if @verification_done[:reactive_sucker]
    reactive_reset_v043
    a,b,c,t,x=reactive_verify_units_v043
    d=PMD_AC.skill_data(:mv_sucker_punch)

    t.instance_variable_set(:@action,:attack)
    t.instance_variable_set(:@action_timer,20)
    t.instance_variable_set(:@action_hit_done,false)
    before=t.hp
    hit=apply_skill_effects(a,t,d,1.0)
    hit_ok=t.hp<before

    healed=reactive_verification_heal_full_v0431(t)
    t.instance_variable_set(:@action,:attack)
    t.instance_variable_set(:@action_timer,20)
    t.instance_variable_set(:@action_hit_done,true)
    before2=t.hp
    miss=apply_skill_effects(a,t,d,1.0)
    fail_ok=t.hp==before2 && miss.to_i==0

    t.instance_variable_set(:@action,:idle)
    t.instance_variable_set(:@action_timer,0)
    t.instance_variable_set(:@action_hit_done,false)

    pass=hit_ok && fail_ok && healed
    log_event(:verify,
      'REACTIVE_SUCKER_PUNCH pass='+(pass ? '1':'0')+
      ' pre_hit_attack=hit recovery=fail priority=+1 verifier_heal_safe='+
      (healed ? '1':'0'))
    @verification_done[:reactive_sucker]=true
  end
end
