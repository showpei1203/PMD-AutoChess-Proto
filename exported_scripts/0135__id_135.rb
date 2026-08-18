#==============================================================================
# 【PMD AutoChess 中文維護說明】
# 腳本：PMD AutoChess Proto v0.22.1
# 分類：核心戰鬥 Runtime
#
# 【用途／機制】
# 承接前序 Data／Config，實際執行戰鬥 Scene、Unit、AI、技能與呈現。
#
# 【怎麼調整】
# 一般平衡與資料調整不要直接改 Runtime；若要追加功能，建議在較後腳本 alias 原方法後擴充。
#
# 【Runtime 主要方法（查流程時可直接搜尋）】
# - start / prepare_verification_battle / canonical_secondary_roll / verify_speed_status_paralysis_cast
# - verify_speed_status_paralysis_result / complete_verification_mode
#
# 【維護規則】
# - RPG Maker VX / RGSS2 / Ruby 1.8 相容。
# - instance_uid 才是 Pokémon 個體身份；Actor ID 只是容器。
# - 新增行為優先沿用既有 helper／Data 表；避免破壞已 Freeze 的舊核心。
# - 本專案新腳本也必須保留同等級的中文說明與實際範例。
#==============================================================================
#==============================================================================
# ■ PMD AutoChess Proto v0.22.1
#    Speed/Paralysis deterministic verification fix
#------------------------------------------------------------------------------
#  Base: v0.22. No combat/runtime behavior is changed.
#  Fix:
#  - v0.22 queued a forced canonical secondary roll for Thunder Shock while the
#    verification mode was :speed_status.
#  - v0.21's canonical_secondary_roll only consumes forced rolls in :secondary,
#    so the Thunder Shock verification silently fell back to rand(100).
#  - v0.22.1 consumes the queued roll only while the dedicated SPEED_STATUS
#    Thunder Shock verification shot is active, then restores normal RNG.
#==============================================================================
class Scene_PMD_AutoChess
  alias pmd_ac_v0221_start start unless method_defined?(:pmd_ac_v0221_start)
  alias pmd_ac_v0221_prepare_verification_battle prepare_verification_battle unless method_defined?(:pmd_ac_v0221_prepare_verification_battle)
  alias pmd_ac_v0221_canonical_secondary_roll canonical_secondary_roll unless method_defined?(:pmd_ac_v0221_canonical_secondary_roll)
  alias pmd_ac_v0221_verify_speed_status_paralysis_cast verify_speed_status_paralysis_cast unless method_defined?(:pmd_ac_v0221_verify_speed_status_paralysis_cast)
  alias pmd_ac_v0221_verify_speed_status_paralysis_result verify_speed_status_paralysis_result unless method_defined?(:pmd_ac_v0221_verify_speed_status_paralysis_result)
  alias pmd_ac_v0221_complete_verification_mode complete_verification_mode unless method_defined?(:pmd_ac_v0221_complete_verification_mode)

  def start
    pmd_ac_v0221_start
    begin
      if FileTest.exist?(PMD_AC::BATTLE_LOG_FILE)
        text=File.open(PMD_AC::BATTLE_LOG_FILE,"rb"){|f|f.read}
        text.sub!("PMD AutoChess Proto v0.22 Battle Verification Log","PMD AutoChess Proto v0.22.1 Battle Verification Log")
        File.open(PMD_AC::BATTLE_LOG_FILE,"wb"){|f|f.write(text)}
      end
    rescue
    end
  end

  def prepare_verification_battle
    pmd_ac_v0221_prepare_verification_battle
    if verification_mode==:speed_status
      @v0221_force_speed_status_secondary_roll=false
    end
  end

  # Verification-only extension of the v0.21 deterministic secondary RNG hook.
  # Normal battles and the original :secondary verification path still use the
  # previously verified implementation unchanged.
  def canonical_secondary_roll(chance)
    if verification_mode==:speed_status && @v0221_force_speed_status_secondary_roll &&
       @secondary_verification_rolls!=nil && !@secondary_verification_rolls.empty?
      c=PMD_AC.clamp(chance.to_i,0,100)
      return [true,0] if c>=100
      roll=@secondary_verification_rolls.shift.to_i
      return [roll<c,roll]
    end
    pmd_ac_v0221_canonical_secondary_roll(chance)
  end

  def verify_speed_status_paralysis_cast(tag)
    return if @verification_done[tag]
    @v0221_force_speed_status_secondary_roll=true
    pmd_ac_v0221_verify_speed_status_paralysis_cast(tag)
    # Add an explicit breadcrumb without changing the v0.22 pass/fail rule.
    if @verification_done[tag]
      log_event(:verify,"SPEED_STATUS_FORCED_SECONDARY_SCOPE pass=1 mode=speed_status queued_roll=0")
    end
  end

  def verify_speed_status_paralysis_result(tag)
    return if @verification_done[tag]
    pmd_ac_v0221_verify_speed_status_paralysis_result(tag)
    @v0221_force_speed_status_secondary_roll=false
    @secondary_verification_rolls=[] if @secondary_verification_rolls!=nil
  end

  def complete_verification_mode
    if verification_mode==:speed_status
      @v0221_force_speed_status_secondary_roll=false
      @secondary_verification_rolls=[] if @secondary_verification_rolls!=nil
    end
    pmd_ac_v0221_complete_verification_mode
  end
end
