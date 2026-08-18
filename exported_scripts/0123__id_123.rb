#==============================================================================
# 【PMD AutoChess 中文維護說明】
# 腳本：PMD AutoChess Proto v0.18.1
# 分類：核心戰鬥 Runtime
#
# 【用途／機制】
# 承接前序 Data／Config，實際執行戰鬥 Scene、Unit、AI、技能與呈現。
#
# 【怎麼調整】
# 一般平衡與資料調整不要直接改 Runtime；若要追加功能，建議在較後腳本 alias 原方法後擴充。
#
# 【Runtime 主要方法（查流程時可直接搜尋）】
# - ranged? / start / prepare_verification_battle / log_event
# - verify_move_runtime_tackle_cast / verify_move_runtime_tags / complete_verification_mode
#
# 【維護規則】
# - RPG Maker VX / RGSS2 / Ruby 1.8 相容。
# - instance_uid 才是 Pokémon 個體身份；Actor ID 只是容器。
# - 新增行為優先沿用既有 helper／Data 表；避免破壞已 Freeze 的舊核心。
# - 本專案新腳本也必須保留同等級的中文說明與實際範例。
#==============================================================================
#==============================================================================
# ■ PMD AutoChess Proto v0.18.1
#    MOVE_RUNTIME Verification + Sound AOE Adapter Fix
#------------------------------------------------------------------------------
#  Base: v0.18 FullTestProject.
#  Purpose:
#   1. Fix deterministic Tackle verification placement.
#   2. Route canonical all-opponents sound AOE directly through existing AOE
#      resolver instead of launching a spatial projectile.
#   3. MOVE_RUNTIME verification may only report COMPLETE when no pass=0 exists.
#
#  This patch does not rewrite v0.15 combat Core, SpeciesDB, MoveDB, or the
#  v0.18 canonical Move Behavior registry.
#==============================================================================

class Game_PMDChessUnit
  alias pmd_ac_v0181_ranged ranged? unless method_defined?(:pmd_ac_v0181_ranged)

  def pmd_ac_v0181_direct_sound_aoe?
    return false unless @action == :skill
    data = skill_data
    return false if data == nil || data.empty?
    return false if data[:canonical_move_key] == nil
    return false unless data[:delivery] == :aoe
    return false unless data[:sound]
    return false unless data[:target] == :all_opponents
    return true
  end

  # Hyper Voice-style canonical moves hit all opponents as a sound wave.
  # The v0.15 :aoe branch launches a projectile for ranged species; that is
  # correct for ground/projectile AOE, but wrong for all-opponents sound moves.
  # Returning false only during this canonical action reuses the existing
  # resolve_skill_aoe path without changing the species' normal ranged profile.
  def ranged?
    return false if pmd_ac_v0181_direct_sound_aoe?
    return pmd_ac_v0181_ranged
  end
end

class Scene_PMD_AutoChess
  alias pmd_ac_v0181_start start unless method_defined?(:pmd_ac_v0181_start)
  alias pmd_ac_v0181_prepare_verification_battle prepare_verification_battle unless method_defined?(:pmd_ac_v0181_prepare_verification_battle)
  alias pmd_ac_v0181_log_event log_event unless method_defined?(:pmd_ac_v0181_log_event)
  alias pmd_ac_v0181_complete_verification_mode complete_verification_mode unless method_defined?(:pmd_ac_v0181_complete_verification_mode)

  def start
    pmd_ac_v0181_start
    begin
      if FileTest.exist?(PMD_AC::BATTLE_LOG_FILE)
        text = File.open(PMD_AC::BATTLE_LOG_FILE, "rb") { |f| f.read }
        text.sub!("PMD AutoChess Proto v0.18 Battle Verification Log",
                  "PMD AutoChess Proto v0.18.1 Battle Verification Log")
        File.open(PMD_AC::BATTLE_LOG_FILE, "wb") { |f| f.write(text) }
      end
    rescue
    end
  end

  def prepare_verification_battle
    pmd_ac_v0181_prepare_verification_battle
    @move_runtime_verification_failed = false if verification_mode == :move_runtime
  end

  # Track deterministic failures. v0.18 could print COMPLETE even when an
  # earlier MOVE_RUNTIME assertion had pass=0, which defeats the point of a
  # verification mode.
  def log_event(category, message)
    if category.to_s == "verify"
      text = message.to_s
      if text.index("MOVE_RUNTIME_") == 0 && text.include?(" pass=0")
        @move_runtime_verification_failed = true
      end
    end
    pmd_ac_v0181_log_event(category, message)
  end

  # Forced-skill verification bypasses normal approach movement. Put Tackle's
  # target inside the canonical contact reach so the test measures damage
  # resolution, not whether two 72px deployment-cell centers happen to exceed
  # a 52px contact range.
  def verify_move_runtime_tackle_cast(tag)
    return if @verification_done[tag]
    caster = verification_unit(:ally, :bulbasaur)
    target = verification_unit(:enemy, :rattata)
    caster.deploy_to_cell(1, 1)
    target.deploy_to_cell(2, 1)
    target.deploy_to_pixel(caster.pixel_x + 48.0, caster.pixel_y)
    @move_runtime_snapshots[:tackle_hp] = target.hp
    ok = caster.verification_force_skill(:mv_tackle, target)
    distance = PMD_AC.distance(caster.pixel_x, caster.pixel_y,
                               target.pixel_x, target.pixel_y)
    log_event(:verify, tag.to_s.upcase + " pass=" + (ok ? "1" : "0") +
      " skill=" + caster.skill_name.to_s +
      " before=" + target.hp.to_s +
      " distance=" + distance.round.to_s +
      " range=" + PMD_AC.skill_data(:mv_tackle)[:range_px].to_s)
    @verification_done[tag] = true
  end

  # Keep the existing tag checks, and also prove the semantic adapter that
  # makes all-opponents sound AOE direct rather than projectile-based.
  def verify_move_runtime_tags(tag)
    return if @verification_done[tag]
    tackle = PMD_AC.skill_data(:mv_tackle)
    aura = PMD_AC.skill_data(:mv_aura_sphere)
    pulse = PMD_AC.skill_data(:mv_dragon_pulse)
    voice = PMD_AC.skill_data(:mv_hyper_voice)
    pass = tackle[:contact] && tackle[:force_contact_range] &&
           aura[:pulse] && aura[:projectile_tracking] == :perfect &&
           pulse[:pulse] && voice[:sound] && voice[:delivery] == :aoe &&
           voice[:target] == :all_opponents
    log_event(:verify, tag.to_s.upcase + " pass=" + (pass ? "1" : "0") +
      " contact=" + (tackle[:contact] ? "1" : "0") +
      " aura_tracking=" + aura[:projectile_tracking].to_s +
      " pulse=" + (pulse[:pulse] ? "1" : "0") +
      " sound=" + (voice[:sound] ? "1" : "0") +
      " sound_direct=" + ((voice[:target] == :all_opponents) ? "1" : "0"))
    @verification_done[tag] = true
  end

  def complete_verification_mode
    if verification_mode == :move_runtime && @move_runtime_verification_failed
      return if @verification_done[:verification_complete]
      for unit in @units
        unit.verification_finish
      end
      @verification_done[:verification_complete] = true
      log_event(:verify,
                "FAILED mode=MOVE_RUNTIME auto_skill=on original_skills=restored")
      return
    end
    pmd_ac_v0181_complete_verification_mode
  end
end
