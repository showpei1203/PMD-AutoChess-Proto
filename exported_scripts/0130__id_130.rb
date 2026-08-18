#==============================================================================
# 【PMD AutoChess 中文維護說明】
# 腳本：PMD AutoChess Proto v0.21.1
# 分類：核心戰鬥 Runtime
#
# 【用途／機制】
# 承接前序 Data／Config，實際執行戰鬥 Scene、Unit、AI、技能與呈現。
#
# 【怎麼調整】
# 一般平衡與資料調整不要直接改 Runtime；若要追加功能，建議在較後腳本 alias 原方法後擴充。
#
# 【Runtime 主要方法（查流程時可直接搜尋）】
# - start / verify_secondary_ember_cast / verify_secondary_ember_result / complete_verification_mode
#
# 【維護規則】
# - RPG Maker VX / RGSS2 / Ruby 1.8 相容。
# - instance_uid 才是 Pokémon 個體身份；Actor ID 只是容器。
# - 新增行為優先沿用既有 helper／Data 表；避免破壞已 Freeze 的舊核心。
# - 本專案新腳本也必須保留同等級的中文說明與實際範例。
#==============================================================================
#==============================================================================
# ■ PMD AutoChess Proto v0.21.1
#    SECONDARY Verification Determinism Fix
#------------------------------------------------------------------------------
#  Base: v0.21 FullTestProject.
#  Purpose:
#   - Fix SECONDARY Ember verification occasionally failing because the target's
#     normal active-evade system can dodge the projectile before the forced
#     secondary-proc roll is ever reached.
#   - Suppress active evade ONLY for that deterministic verification case and
#     restore the unit's original evade capability immediately afterward.
#   - No change to normal battle evade, projectile tracking, MoveDB, secondary
#     effect probabilities, status behavior, or combat geometry.
#==============================================================================

class Game_PMDChessUnit
  # Deterministic verification helper. This intentionally does not alter the
  # species profile or the normal active-evade rules used in real combat.
  def pmd_ac_v0211_verification_suppress_active_evade
    unless @pmd_ac_v0211_saved_active_evade_valid
      @pmd_ac_v0211_saved_active_evade = @active_evade_enabled ? true : false
      @pmd_ac_v0211_saved_active_evade_valid = true
    end
    @active_evade_enabled = false
    @verification_force_evade = false
  end

  def pmd_ac_v0211_verification_restore_active_evade
    return unless @pmd_ac_v0211_saved_active_evade_valid
    @active_evade_enabled = @pmd_ac_v0211_saved_active_evade ? true : false
    @pmd_ac_v0211_saved_active_evade_valid = false
  end
end

class Scene_PMD_AutoChess
  alias pmd_ac_v0211_start start unless method_defined?(:pmd_ac_v0211_start)
  alias pmd_ac_v0211_complete_verification_mode complete_verification_mode unless method_defined?(:pmd_ac_v0211_complete_verification_mode)

  def start
    pmd_ac_v0211_start
    begin
      if FileTest.exist?(PMD_AC::BATTLE_LOG_FILE)
        text = File.open(PMD_AC::BATTLE_LOG_FILE, "rb") { |f| f.read }
        text.sub!("PMD AutoChess Proto v0.21 Battle Verification Log",
                  "PMD AutoChess Proto v0.21.1 Battle Verification Log")
        File.open(PMD_AC::BATTLE_LOG_FILE, "wb") { |f| f.write(text) }
      end
    rescue
    end
  end

  # v0.21 correctly forced the secondary roll to 0, but the projectile could
  # still be actively evaded before the hit callback. The verification is meant
  # to prove Ember damage + 10% Burn proc wiring, not to test the separate evade
  # subsystem, so only this test target has active evade temporarily disabled.
  def verify_secondary_ember_cast(tag)
    return if @verification_done[tag]
    u = verification_unit(:ally, :charmander)
    t = verification_unit(:enemy, :rattata)
    t.verification_clear_status(:burn)
    u.deploy_to_cell(1, 1)
    t.deploy_to_cell(3, 1)
    t.pmd_ac_v0211_verification_suppress_active_evade
    set_secondary_verification_rolls([0])
    @secondary_snapshots[:ember] = t.hp
    ok = u.verification_force_skill(:mv_ember, t)
    log_event(:verify,
      tag.to_s.upcase + " pass=" + (ok ? "1" : "0") +
      " before=" + t.hp.to_s +
      " forced_roll=0 chance=10 evade_suppressed=1")
    @verification_done[tag] = true
  end

  def verify_secondary_ember_result(tag)
    return if @verification_done[tag]
    t = verification_unit(:enemy, :rattata)
    b = @secondary_snapshots[:ember].to_i
    pass = t.hp < b && t.status?(:burn)
    log_event(:verify,
      tag.to_s.upcase + " pass=" + (pass ? "1" : "0") +
      " damage=" + (b - t.hp).to_s +
      " burn=" + (t.status?(:burn) ? "1" : "0") +
      " evade_restored=1")
    t.pmd_ac_v0211_verification_restore_active_evade
    @verification_done[tag] = true
  end

  # Safety restore in case a future edit changes verification frame ordering.
  def complete_verification_mode
    if verification_mode == :secondary
      begin
        t = verification_unit(:enemy, :rattata)
        t.pmd_ac_v0211_verification_restore_active_evade if t != nil
      rescue
      end
    end
    pmd_ac_v0211_complete_verification_mode
  end
end
