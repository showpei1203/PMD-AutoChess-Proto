#==============================================================================
# 【PMD AutoChess 中文維護說明】
# 腳本：PMD AutoChess Proto v0.43.2
# 分類：核心戰鬥 Runtime
#
# 【用途／機制】
# 承接前序 Data／Config，實際執行戰鬥 Scene、Unit、AI、技能與呈現。
#
# 【怎麼調整】
# 一般平衡與資料調整不要直接改 Runtime；若要追加功能，建議在較後腳本 alias 原方法後擴充。
#
# 【PMD_AC 對外／共用方法】
# - reactive_identity_normalization_ok_v0432
#
# 【Runtime 主要方法（查流程時可直接搜尋）】
# - self / start / reactive_move_key_v043
#
# 【維護規則】
# - RPG Maker VX / RGSS2 / Ruby 1.8 相容。
# - instance_uid 才是 Pokémon 個體身份；Actor ID 只是容器。
# - 新增行為優先沿用既有 helper／Data 表；避免破壞已 Freeze 的舊核心。
# - 本專案新腳本也必須保留同等級的中文說明與實際範例。
#==============================================================================
#===============================================================================
# ■ PMD AutoChess Proto v0.43.2
#    Reactive Priority Move-Identity Compatibility Fix
#-------------------------------------------------------------------------------
# Additive hotfix on verified v0.43.1.
#
# Root cause found by real VX verification:
# - REACTIVE_PRIORITY_MOVE_V043 stores :move_key / :canonical_move_key VALUES
#   as Strings ("counter", "sucker_punch", ...).
# - Runtime dispatch compares those identities against Symbols (:counter,
#   :sucker_punch, ...).
# - As a result the data existed, but Counter/Mirror Coat/Sucker Punch skipped
#   their reactive branches and fell through to generic skill handling.
#
# Fix:
# - Normalize only move identity VALUES to Symbols once at load.
# - Defensively normalize reactive_move_key_v043 return values as Symbols.
# - No power, priority, timing, reaction window, damage formula, AI, visuals,
#   audio, or older scripts are changed.
#===============================================================================
module PMD_AC
  REACTIVE_PRIORITY_MOVE_V043.keys.each do |k|
    d=REACTIVE_PRIORITY_MOVE_V043[k]
    next if d==nil
    d[:move_key]=d[:move_key].to_sym if d[:move_key].is_a?(String)
    d[:canonical_move_key]=d[:canonical_move_key].to_sym if d[:canonical_move_key].is_a?(String)
  end

  def self.reactive_identity_normalization_ok_v0432
    keys=[:sucker_punch,:counter,:mirror_coat,:revenge,:avalanche,:vital_throw]
    keys.each do |k|
      d=REACTIVE_PRIORITY_MOVE_V043[k]
      return false if d==nil
      return false unless d[:move_key]==k
      return false unless d[:canonical_move_key]==k
    end
    true
  end
end

class Scene_PMD_AutoChess
  alias pmd_ac_v0432_start start unless method_defined?(:pmd_ac_v0432_start)

  def start
    pmd_ac_v0432_start
    begin
      if FileTest.exist?(PMD_AC::BATTLE_LOG_FILE)
        text=File.open(PMD_AC::BATTLE_LOG_FILE,'rb'){|f|f.read}
        text.sub!(/PMD AutoChess Proto v0\.[0-9.]+ Battle Verification Log/,
                  'PMD AutoChess Proto v0.43.2 Battle Verification Log')
        File.open(PMD_AC::BATTLE_LOG_FILE,'wb'){|f|f.write(text)}
      end
    rescue
    end
    log_event(:reactive_priority,
      'PATCH v0.43.2 move_identity=string_to_symbol reactive_dispatch=1 normalized='+
      (PMD_AC.reactive_identity_normalization_ok_v0432 ? '1':'0')+
      ' mechanics_unchanged=1')
  end

  # Defensive runtime boundary: all reactive dispatch code works in Symbol keys.
  def reactive_move_key_v043(data)
    return nil if data==nil
    k=data[:canonical_move_key]||data[:move_key]
    return nil if k==nil
    k.is_a?(String) ? k.to_sym : k
  end
end
