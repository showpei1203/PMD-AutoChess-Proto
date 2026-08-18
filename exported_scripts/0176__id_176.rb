#==============================================================================
# 【PMD AutoChess 中文維護說明】
# 腳本：PMD AutoChess Proto v0.39.1
# 分類：核心戰鬥 Runtime
#
# 【用途／機制】
# 承接前序 Data／Config，實際執行戰鬥 Scene、Unit、AI、技能與呈現。
#
# 【怎麼調整】
# 一般平衡與資料調整不要直接改 Runtime；若要追加功能，建議在較後腳本 alias 原方法後擴充。
#
# 【Runtime 主要方法（查流程時可直接搜尋）】
# - two_turn_pending_v039? / start
#
# 【維護規則】
# - RPG Maker VX / RGSS2 / Ruby 1.8 相容。
# - instance_uid 才是 Pokémon 個體身份；Actor ID 只是容器。
# - 新增行為優先沿用既有 helper／Data 表；避免破壞已 Freeze 的舊核心。
# - 本專案新腳本也必須保留同等級的中文說明與實際範例。
#==============================================================================
# PMD AutoChess v0.39.1 - Two-Turn Phase-2 Release Gate Fix
# Additive patch over verified v0.38 + v0.39.
#
# v0.39 defined pending as move != nil AND frames > 0.  On the exact frame
# the countdown reached zero, Scene#resolve_two_turn_release_v039 was called,
# but its first guard asked two_turn_pending_v039? again.  Since frames was
# already zero, the release returned immediately.  Result: no Phase 2 damage
# and the altitude pose remained underground/submerged/airborne.
#
# A pending two-turn move is a state machine ownership flag, not a timer test.
# It remains pending while @two_turn_move_v039 exists, including the zero-frame
# handoff frame.  clear_two_turn_charge_v039 is the only normal completion path.

class Game_PMDChessUnit
  def two_turn_pending_v039?
    @two_turn_move_v039 != nil
  end
end

class Scene_PMD_AutoChess
  alias pmd_ac_v0391_start start unless method_defined?(:pmd_ac_v0391_start)
  def start
    pmd_ac_v0391_start
    begin
      if FileTest.exist?(PMD_AC::BATTLE_LOG_FILE)
        text=File.open(PMD_AC::BATTLE_LOG_FILE,'rb'){|f|f.read}
        text.sub!(/PMD AutoChess Proto v0\.[0-9.]+ Battle Verification Log/,
                  'PMD AutoChess Proto v0.39.1 Battle Verification Log')
        File.open(PMD_AC::BATTLE_LOG_FILE,'wb'){|f|f.write(text)}
      end
    rescue
    end
    log_event(:two_turn,'PATCH v0.39.1 release_gate=move_owned pending_zero_frame=1 phase2_handoff=1 mechanics_unchanged=1')
  end
end
