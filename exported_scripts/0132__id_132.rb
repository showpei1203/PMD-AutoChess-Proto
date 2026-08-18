#==============================================================================
# 【PMD AutoChess 中文維護說明】
# 腳本：PMD AutoChess Proto v0.21.3
# 分類：核心戰鬥 Runtime
#
# 【用途／機制】
# 承接前序 Data／Config，實際執行戰鬥 Scene、Unit、AI、技能與呈現。
#
# 【怎麼調整】
# 一般平衡與資料調整不要直接改 Runtime；若要追加功能，建議在較後腳本 alias 原方法後擴充。
#
# 【Runtime 主要方法（查流程時可直接搜尋）】
# - start / projectile_tracking_for / verify_secondary_leaf_cast / verify_secondary_leaf_result
# - complete_verification_mode
#
# 【維護規則】
# - RPG Maker VX / RGSS2 / Ruby 1.8 相容。
# - instance_uid 才是 Pokémon 個體身份；Actor ID 只是容器。
# - 新增行為優先沿用既有 helper／Data 表；避免破壞已 Freeze 的舊核心。
# - 本專案新腳本也必須保留同等級的中文說明與實際範例。
#==============================================================================
#==============================================================================
# ■ PMD AutoChess Proto v0.21.3
#    SECONDARY Verification Determinism Fix 3
#------------------------------------------------------------------------------
#  Base: v0.21.2 FullTestProject.
#  Purpose:
#   - v0.21.2 suppresses Active Evade for deterministic Leaf Storm verification,
#     but the independent strong-tracking projectile can still legitimately
#     overshoot before the guaranteed 100% self Sp.Atk-drop callback resolves.
#   - Force :perfect tracking ONLY for the Leaf Storm deterministic verification
#     projectile, while retaining the v0.21.2 verification-only evade suppression.
#   - Restore the override immediately after the result check and at verification
#     completion as a safety path.
#   - No normal battle projectile tracking, Active Evade, Leaf Storm data,
#     secondary probabilities, combat geometry, or existing Core is changed.
#==============================================================================

class Scene_PMD_AutoChess
  alias pmd_ac_v0213_start start unless method_defined?(:pmd_ac_v0213_start)
  alias pmd_ac_v0213_projectile_tracking_for projectile_tracking_for unless method_defined?(:pmd_ac_v0213_projectile_tracking_for)
  alias pmd_ac_v0213_complete_verification_mode complete_verification_mode unless method_defined?(:pmd_ac_v0213_complete_verification_mode)

  def start
    pmd_ac_v0213_start
    begin
      if FileTest.exist?(PMD_AC::BATTLE_LOG_FILE)
        text = File.open(PMD_AC::BATTLE_LOG_FILE, "rb") { |f| f.read }
        text.sub!("PMD AutoChess Proto v0.21.2 Battle Verification Log",
                  "PMD AutoChess Proto v0.21.3 Battle Verification Log")
        File.open(PMD_AC::BATTLE_LOG_FILE, "wb") { |f| f.write(text) }
      end
    rescue
    end
  end

  # Strong tracking is intentionally allowed to overshoot in normal combat.
  # This one verification case is testing Leaf Storm's guaranteed post-hit
  # self Sp.Atk -2, not the already verified projectile miss model. Therefore
  # only this forced verification projectile is upgraded to :perfect tracking.
  def projectile_tracking_for(user, kind, effect_type)
    if verification_mode == :secondary &&
       @pmd_ac_v0213_leaf_tracking_override &&
       effect_type == :mv_leaf_storm
      return :perfect
    end
    pmd_ac_v0213_projectile_tracking_for(user, kind, effect_type)
  end

  def verify_secondary_leaf_cast(tag)
    return if @verification_done[tag]
    u = verification_unit(:ally, :bulbasaur)
    t = verification_unit(:enemy, :rattata)
    u.reset_stat_stages
    u.deploy_to_cell(1, 2)
    t.deploy_to_cell(3, 2)
    t.pmd_ac_v0211_verification_suppress_active_evade
    @pmd_ac_v0213_leaf_tracking_override = true
    @secondary_snapshots[:leaf] = u.special_attack
    ok = u.verification_force_skill(:mv_leaf_storm, t)
    log_event(:verify,
      tag.to_s.upcase + " pass=" + (ok ? "1" : "0") +
      " spatk_before=" + u.special_attack.to_s +
      " chance=100 evade_suppressed=1 tracking_forced=perfect")
    @verification_done[tag] = true
  end

  def verify_secondary_leaf_result(tag)
    return if @verification_done[tag]
    u = verification_unit(:ally, :bulbasaur)
    t = verification_unit(:enemy, :rattata)
    b = @secondary_snapshots[:leaf].to_i
    pass = u.stat_stage(:spatk) == -2 && u.special_attack < b
    @pmd_ac_v0213_leaf_tracking_override = false
    t.pmd_ac_v0211_verification_restore_active_evade
    log_event(:verify,
      tag.to_s.upcase + " pass=" + (pass ? "1" : "0") +
      " stage=" + u.stat_stage(:spatk).to_s +
      " spatk=" + b.to_s + "->" + u.special_attack.to_s +
      " evade_restored=1 tracking_restored=strong")
    @verification_done[tag] = true
  end

  def complete_verification_mode
    if verification_mode == :secondary
      @pmd_ac_v0213_leaf_tracking_override = false
      begin
        t = verification_unit(:enemy, :rattata)
        t.pmd_ac_v0211_verification_restore_active_evade if t != nil
      rescue
      end
    end
    pmd_ac_v0213_complete_verification_mode
  end
end
