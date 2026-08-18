#==============================================================================
# 【PMD AutoChess 中文維護說明】
# 腳本：PMD AutoChess Proto v0.23.1
# 分類：核心戰鬥 Runtime
#
# 【用途／機制】
# 承接前序 Data／Config，實際執行戰鬥 Scene、Unit、AI、技能與呈現。
#
# 【怎麼調整】
# 一般平衡與資料調整不要直接改 Runtime；若要追加功能，建議在較後腳本 alias 原方法後擴充。
#
# 【Runtime 主要方法（查流程時可直接搜尋）】
# - start / verify_action_status_sleep_cast / verify_action_status_sleep_result / verify_action_status_freeze_cast
# - verify_action_status_freeze_result
#
# 【維護規則】
# - RPG Maker VX / RGSS2 / Ruby 1.8 相容。
# - instance_uid 才是 Pokémon 個體身份；Actor ID 只是容器。
# - 新增行為優先沿用既有 helper／Data 表；避免破壞已 Freeze 的舊核心。
# - 本專案新腳本也必須保留同等級的中文說明與實際範例。
#==============================================================================
#==============================================================================
# PMD AutoChess Proto v0.23.1
# ACTION_STATUS deterministic verification correction only.
# - Spore verification target is moved close enough that the projectile resolves
#   before the result frame.
# - Sleep turn verification advances the internal action-wait between checks.
# - Freeze verification clears prior major statuses and uses an isolated target
#   position so Ice Beam can deterministically apply Freeze.
# Normal battle behavior is unchanged.
#==============================================================================

class Scene_PMD_AutoChess
  alias pmd_ac_v0231_start start unless method_defined?(:pmd_ac_v0231_start)

  def start
    pmd_ac_v0231_start
    begin
      if FileTest.exist?(PMD_AC::BATTLE_LOG_FILE)
        text = File.open(PMD_AC::BATTLE_LOG_FILE, "rb") { |f| f.read }
        text.sub!("PMD AutoChess Proto v0.23 Battle Verification Log",
                  "PMD AutoChess Proto v0.23.1 Battle Verification Log")
        File.open(PMD_AC::BATTLE_LOG_FILE, "wb") { |f| f.write(text) }
      end
    rescue
    end
  end

  # Keep the existing v0.23 frame schedule, but make the test geometry truly
  # deterministic. Perfect tracking does not mean instantaneous travel.
  def verify_action_status_sleep_cast(tag)
    return if @verification_done[tag]
    u = verification_unit(:ally, :bulbasaur)
    t = verification_unit(:enemy, :rattata)
    for key in [:burn, :poison, :paralysis, :sleep, :freeze]
      t.verification_clear_status(key)
    end
    u.deploy_to_cell(0, 2)
    t.deploy_to_pixel(u.pixel_x + 72.0, u.pixel_y)
    t.pmd_ac_v0211_verification_suppress_active_evade
    @v023_perfect_tracking_skill = :mv_spore
    set_action_status_rolls(:sleep_turns, [0])
    ok = u.verification_force_skill(:mv_spore, t)
    log_event(:verify, tag.to_s.upcase + " pass=" + (ok ? "1" : "0") +
      " forced_turn_roll=0 tracking=perfect distance=" + u.distance_to(t).round.to_s)
    @verification_done[tag] = true
  end

  def verify_action_status_sleep_result(tag)
    return if @verification_done[tag]
    t = verification_unit(:enemy, :rattata)
    t.pmd_ac_v0211_verification_restore_active_evade
    @v023_perfect_tracking_skill = nil
    applied = t.sleeping?

    # Validate the intended Gen-V -> realtime translation directly:
    # with two remaining sleep turns, one action is blocked and the next wakes.
    t.verification_set_sleep_turns(2)
    t.verification_force_status_wait_ready
    first_block = t.canonical_update_immobilized_status
    t.verification_force_status_wait_ready
    second_block = t.canonical_update_immobilized_status
    woke = !second_block && !t.sleeping?
    pass = applied && first_block && woke

    log_event(:verify, tag.to_s.upcase + " pass=" + (pass ? "1" : "0") +
      " applied=" + (applied ? "1" : "0") +
      " blocked_first=" + (first_block ? "1" : "0") +
      " wake_second=" + (woke ? "1" : "0"))
    t.verification_clear_status(:sleep)
    @verification_done[tag] = true
  end

  def verify_action_status_freeze_cast(tag)
    return if @verification_done[tag]
    u = verification_unit(:ally, :squirtle)
    t = verification_unit(:enemy, :rattata)
    # Freeze is a major status. Isolate this test from the preceding Sleep test.
    for key in [:burn, :poison, :paralysis, :sleep, :freeze]
      t.verification_clear_status(key)
    end
    u.deploy_to_cell(0, 3)
    t.deploy_to_pixel(u.pixel_x + 120.0, u.pixel_y)
    t.pmd_ac_v0211_verification_suppress_active_evade
    @v023_perfect_tracking_skill = :mv_ice_beam
    set_secondary_verification_rolls([0])
    ok = u.verification_force_skill(:mv_ice_beam, t)
    log_event(:verify, tag.to_s.upcase + " pass=" + (ok ? "1" : "0") +
      " forced_secondary_roll=0 tracking=perfect major_status_clear=1 distance=" +
      u.distance_to(t).round.to_s)
    @verification_done[tag] = true
  end

  def verify_action_status_freeze_result(tag)
    return if @verification_done[tag]
    t = verification_unit(:enemy, :rattata)
    t.pmd_ac_v0211_verification_restore_active_evade
    @v023_perfect_tracking_skill = nil
    frozen = t.frozen?
    log_event(:verify, tag.to_s.upcase + " pass=" + (frozen ? "1" : "0") +
      " frozen=" + (frozen ? "1" : "0"))
    t.verification_clear_status(:freeze)
    @verification_done[tag] = true
  end
end
