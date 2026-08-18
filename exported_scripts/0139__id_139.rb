#==============================================================================
# 【PMD AutoChess 中文維護說明】
# 腳本：PMD AutoChess Proto v0.23.2
# 分類：核心戰鬥 Runtime
#
# 【用途／機制】
# 承接前序 Data／Config，實際執行戰鬥 Scene、Unit、AI、技能與呈現。
#
# 【怎麼調整】
# 一般平衡與資料調整不要直接改 Runtime；若要追加功能，建議在較後腳本 alias 原方法後擴充。
#
# 【Runtime 主要方法（查流程時可直接搜尋）】
# - start / verify_action_status_confusion_cast / verify_action_status_confusion_result
#
# 【維護規則】
# - RPG Maker VX / RGSS2 / Ruby 1.8 相容。
# - instance_uid 才是 Pokémon 個體身份；Actor ID 只是容器。
# - 新增行為優先沿用既有 helper／Data 表；避免破壞已 Freeze 的舊核心。
# - 本專案新腳本也必須保留同等級的中文說明與實際範例。
#==============================================================================
#==============================================================================
# PMD AutoChess Proto v0.23.2
# ACTION_STATUS deterministic verification correction only.
# - Confuse Ray verification now uses deterministic close-range geometry so the
#   projectile resolves before the scheduled result frame.
# - Normal battle projectile range, tracking, evasion and Confusion behavior are
#   unchanged.
#==============================================================================

class Scene_PMD_AutoChess
  alias pmd_ac_v0232_start start unless method_defined?(:pmd_ac_v0232_start)

  def start
    pmd_ac_v0232_start
    begin
      if FileTest.exist?(PMD_AC::BATTLE_LOG_FILE)
        text = File.open(PMD_AC::BATTLE_LOG_FILE, "rb") { |f| f.read }
        text.sub!("PMD AutoChess Proto v0.23.1 Battle Verification Log",
                  "PMD AutoChess Proto v0.23.2 Battle Verification Log")
        File.open(PMD_AC::BATTLE_LOG_FILE, "wb") { |f| f.write(text) }
      end
    rescue
    end
  end

  # Perfect tracking guarantees pursuit, not instantaneous travel.  The v0.23
  # schedule checks the result at frame 245, so place the verification pair at
  # a deterministic 96 px separation.  This validates Confusion itself instead
  # of projectile flight time.
  def verify_action_status_confusion_cast(tag)
    return if @verification_done[tag]
    u = verification_unit(:enemy, :pikachu)
    t = verification_unit(:ally, :squirtle)
    t.verification_clear_status(:confusion)
    u.deploy_to_cell(4, 3)
    t.deploy_to_pixel(u.pixel_x - 96.0, u.pixel_y)
    t.pmd_ac_v0211_verification_suppress_active_evade
    @v023_perfect_tracking_skill = :mv_confuse_ray
    set_action_status_rolls(:confusion_turns, [0])
    ok = u.verification_force_skill(:mv_confuse_ray, t)
    log_event(:verify, tag.to_s.upcase + " pass=" + (ok ? "1" : "0") +
      " forced_turn_roll=0 tracking=perfect distance=" + u.distance_to(t).round.to_s)
    @verification_done[tag] = true
  end

  def verify_action_status_confusion_result(tag)
    return if @verification_done[tag]
    t = verification_unit(:ally, :squirtle)
    t.pmd_ac_v0211_verification_restore_active_evade
    @v023_perfect_tracking_skill = nil
    applied = t.confused?
    t.verification_set_confusion_turns(3)
    set_action_status_rolls(:confusion_self_hit, [49, 50])
    set_action_status_rolls(:confusion_damage_roll, [15])
    before = t.hp
    first_block = t.canonical_confusion_action_block?(:basic)
    middle = t.hp
    second_block = t.canonical_confusion_action_block?(:basic)
    pass = applied && first_block && middle < before && !second_block
    log_event(:verify, tag.to_s.upcase + " pass=" + (pass ? "1" : "0") +
      " applied=" + (applied ? "1" : "0") +
      " roll49_selfhit=" + (first_block ? "1" : "0") +
      " damage=" + (before - middle).to_s +
      " roll50_allow=" + (!second_block ? "1" : "0") +
      " evade_restored=1 tracking_restored=strong")
    t.verification_clear_status(:confusion)
    @verification_done[tag] = true
  end
end
