#==============================================================================
# 【PMD AutoChess 中文維護說明】
# 腳本：PMD AutoChess Proto v0.21.2
# 分類：核心戰鬥 Runtime
#
# 【用途／機制】
# 承接前序 Data／Config，實際執行戰鬥 Scene、Unit、AI、技能與呈現。
#
# 【怎麼調整】
# 一般平衡與資料調整不要直接改 Runtime；若要追加功能，建議在較後腳本 alias 原方法後擴充。
#
# 【Runtime 主要方法（查流程時可直接搜尋）】
# - start / verify_secondary_leaf_cast / verify_secondary_leaf_result / complete_verification_mode
#
# 【維護規則】
# - RPG Maker VX / RGSS2 / Ruby 1.8 相容。
# - instance_uid 才是 Pokémon 個體身份；Actor ID 只是容器。
# - 新增行為優先沿用既有 helper／Data 表；避免破壞已 Freeze 的舊核心。
# - 本專案新腳本也必須保留同等級的中文說明與實際範例。
#==============================================================================
#==============================================================================
# ■ PMD AutoChess Proto v0.21.2
#    SECONDARY Verification Determinism Fix 2
#------------------------------------------------------------------------------
#  Base: v0.21.1 FullTestProject.
#  Purpose:
#   - v0.21.1 fixed Ember's deterministic verification by suppressing the
#     target's normal active-evade subsystem during that specific projectile.
#   - The same independent evade subsystem can also invalidate Leaf Storm's
#     deterministic 100% self Sp.Atk-drop verification before its hit callback.
#   - Apply the same narrow, verification-only suppression to Leaf Storm and
#     restore the target immediately after the result check.
#   - No normal battle behavior, evade rules, projectile tracking, secondary
#     probabilities, MoveDB data, combat geometry, or existing Core is changed.
#==============================================================================

class Scene_PMD_AutoChess
  alias pmd_ac_v0212_start start unless method_defined?(:pmd_ac_v0212_start)
  alias pmd_ac_v0212_complete_verification_mode complete_verification_mode unless method_defined?(:pmd_ac_v0212_complete_verification_mode)

  def start
    pmd_ac_v0212_start
    begin
      if FileTest.exist?(PMD_AC::BATTLE_LOG_FILE)
        text = File.open(PMD_AC::BATTLE_LOG_FILE, "rb") { |f| f.read }
        text.sub!("PMD AutoChess Proto v0.21.1 Battle Verification Log",
                  "PMD AutoChess Proto v0.21.2 Battle Verification Log")
        File.open(PMD_AC::BATTLE_LOG_FILE, "wb") { |f| f.write(text) }
      end
    rescue
    end
  end

  # Leaf Storm's secondary effect is guaranteed once the move actually hits.
  # The purpose of this deterministic case is to verify the 100% self-stage
  # change wiring, not to re-test the already independent active-evade system.
  def verify_secondary_leaf_cast(tag)
    return if @verification_done[tag]
    u = verification_unit(:ally, :bulbasaur)
    t = verification_unit(:enemy, :rattata)
    u.reset_stat_stages
    u.deploy_to_cell(1, 2)
    t.deploy_to_cell(3, 2)
    t.pmd_ac_v0211_verification_suppress_active_evade
    @secondary_snapshots[:leaf] = u.special_attack
    ok = u.verification_force_skill(:mv_leaf_storm, t)
    log_event(:verify,
      tag.to_s.upcase + " pass=" + (ok ? "1" : "0") +
      " spatk_before=" + u.special_attack.to_s +
      " chance=100 evade_suppressed=1")
    @verification_done[tag] = true
  end

  def verify_secondary_leaf_result(tag)
    return if @verification_done[tag]
    u = verification_unit(:ally, :bulbasaur)
    t = verification_unit(:enemy, :rattata)
    b = @secondary_snapshots[:leaf].to_i
    pass = u.stat_stage(:spatk) == -2 && u.special_attack < b
    t.pmd_ac_v0211_verification_restore_active_evade
    log_event(:verify,
      tag.to_s.upcase + " pass=" + (pass ? "1" : "0") +
      " stage=" + u.stat_stage(:spatk).to_s +
      " spatk=" + b.to_s + "->" + u.special_attack.to_s +
      " evade_restored=1")
    @verification_done[tag] = true
  end

  # Final safety restore if frame ordering is changed later.
  def complete_verification_mode
    if verification_mode == :secondary
      begin
        t = verification_unit(:enemy, :rattata)
        t.pmd_ac_v0211_verification_restore_active_evade if t != nil
      rescue
      end
    end
    pmd_ac_v0212_complete_verification_mode
  end
end
