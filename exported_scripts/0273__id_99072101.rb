#==============================================================================
# 【PMD AutoChess 中文維護說明】
# 腳本：PMD AutoChess Proto v0.72.1
# 分類：核心戰鬥 Runtime
#
# 【用途／機制】
# 承接前序 Data／Config，實際執行戰鬥 Scene、Unit、AI、技能與呈現。
#
# 【怎麼調整】
# 一般平衡與資料調整不要直接改 Runtime；若要追加功能，建議在較後腳本 alias 原方法後擴充。
#
# 【Runtime 主要方法（查流程時可直接搜尋）】
# - start / combat_ai_phase2_active_v069? / combat_ai_phase3_active_v070? / combat_ai_phase4_active_v071?
#
# 【維護規則】
# - RPG Maker VX / RGSS2 / Ruby 1.8 相容。
# - instance_uid 才是 Pokémon 個體身份；Actor ID 只是容器。
# - 新增行為優先沿用既有 helper／Data 表；避免破壞已 Freeze 的舊核心。
# - 本專案新腳本也必須保留同等級的中文說明與實際範例。
#==============================================================================
#==============================================================================
# PMD AutoChess Proto v0.72.1
# Combat AI V Verification Phase-Inheritance Fix
# RGSS2 / Ruby 1.8 compatible
#------------------------------------------------------------------------------
# v0.72 normal combat already runs all Combat AI phases because verification_mode
# is :normal.  The v0.72 dedicated verifier, however, introduced a new mode symbol
# that older phase gates did not recognize.  As a result, v0.70 reservation and
# v0.71 ordered-combo / intent-target layers were inactive only while testing v0.72.
#
# This patch changes verifier inheritance only.  Normal combat scoring, movement,
# targeting, weather/field runtime and damage packets are unchanged.
#==============================================================================

class Scene_PMD_AutoChess
  alias pmd_ac_v0721_start start unless method_defined?(:pmd_ac_v0721_start)
  alias pmd_ac_v0721_phase2_active_v069 combat_ai_phase2_active_v069? unless method_defined?(:pmd_ac_v0721_phase2_active_v069)
  alias pmd_ac_v0721_phase3_active_v070 combat_ai_phase3_active_v070? unless method_defined?(:pmd_ac_v0721_phase3_active_v070)
  alias pmd_ac_v0721_phase4_active_v071 combat_ai_phase4_active_v071? unless method_defined?(:pmd_ac_v0721_phase4_active_v071)

  def start
    pmd_ac_v0721_start
    begin
      if FileTest.exist?(PMD_AC::BATTLE_LOG_FILE)
        t=File.open(PMD_AC::BATTLE_LOG_FILE,'rb'){|f|f.read}
        t.sub!(/PMD AutoChess Proto v0\.72 Battle Verification Log/,
          'PMD AutoChess Proto v0.72.1 Battle Verification Log')
        File.open(PMD_AC::BATTLE_LOG_FILE,'wb'){|f|f.write(t)}
      end
    rescue
    end
    log_event(:presentation,
      'PATCH v0.72.1 verifier_phase_inheritance=v0.69+v0.70+v0.71+v0.72 '+
      'normal_combat_unchanged=1 combo_values_unchanged=1 weather_field_unchanged=1')
  end

  def combat_ai_phase2_active_v069?
    return true if verification_mode==:combat_ai_integration_v_v072
    pmd_ac_v0721_phase2_active_v069
  end

  def combat_ai_phase3_active_v070?
    return true if verification_mode==:combat_ai_integration_v_v072
    pmd_ac_v0721_phase3_active_v070
  end

  def combat_ai_phase4_active_v071?
    return true if verification_mode==:combat_ai_integration_v_v072
    pmd_ac_v0721_phase4_active_v071
  end
end
