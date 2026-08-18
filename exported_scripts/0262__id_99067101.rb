#==============================================================================
# 【PMD AutoChess 中文維護說明】
# 腳本：PMD AutoChess Proto v0.67.1
# 分類：核心戰鬥 Runtime
#
# 【用途／機制】
# 承接前序 Data／Config，實際執行戰鬥 Scene、Unit、AI、技能與呈現。
#
# 【怎麼調整】
# 一般平衡與資料調整不要直接改 Runtime；若要追加功能，建議在較後腳本 alias 原方法後擴充。
#
# 【本腳本主要設定常數／資料表】
# - PATCH_VERSION_V0671
#
# 【Runtime 主要方法（查流程時可直接搜尋）】
# - start / canonical_indirect_ability_damage
#
# 【維護規則】
# - RPG Maker VX / RGSS2 / Ruby 1.8 相容。
# - instance_uid 才是 Pokémon 個體身份；Actor ID 只是容器。
# - 新增行為優先沿用既有 helper／Data 表；避免破壞已 Freeze 的舊核心。
# - 本專案新腳本也必須保留同等級的中文說明與實際範例。
#==============================================================================
#==============================================================================
# PMD AutoChess Proto v0.67.1
# Magic Guard Symbol Label RGSS2 Compatibility Fix
#------------------------------------------------------------------------------
# Fixes the v0.25 canonical_indirect_ability_damage logger when callers pass a
# Symbol label (for example :verify, :rough_skin, :aftermath, :bad_dreams).
# The original v0.25 script remains byte-identical.  Mechanics are unchanged;
# only the label passed into the legacy method is normalized to String.
#==============================================================================
module PMD_AC
  PATCH_VERSION_V0671='0.67.1'
end

class Scene_PMD_AutoChess
  alias pmd_ac_v0671_start start unless method_defined?(:pmd_ac_v0671_start)
  alias pmd_ac_v0671_canonical_indirect_ability_damage canonical_indirect_ability_damage unless method_defined?(:pmd_ac_v0671_canonical_indirect_ability_damage)

  def start
    pmd_ac_v0671_start
    begin
      if FileTest.exist?(PMD_AC::BATTLE_LOG_FILE)
        t=File.open(PMD_AC::BATTLE_LOG_FILE,'rb'){|f|f.read}
        t.sub!(/PMD AutoChess Proto v0\.67 Battle Verification Log/,
          'PMD AutoChess Proto v0.67.1 Battle Verification Log')
        File.open(PMD_AC::BATTLE_LOG_FILE,'wb'){|f|f.write(t)}
      end
    rescue
    end
    log_event(:presentation,
      'PATCH v0.67.1 magic_guard_indirect_label_symbol_to_string=1 '+
      'legacy_v0.25_script_unchanged=1 mechanics_unchanged=1')
  end

  def canonical_indirect_ability_damage(target,source,amount,label)
    safe_label=label==nil ? '' : label.to_s
    pmd_ac_v0671_canonical_indirect_ability_damage(target,source,amount,safe_label)
  end
end
