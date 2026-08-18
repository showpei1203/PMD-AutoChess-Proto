#==============================================================================
# 【PMD AutoChess 中文維護說明】
# 腳本：PMD AutoChess Proto v0.77.1
# 分類：核心戰鬥 Runtime
#
# 【用途／機制】
# 承接前序 Data／Config，實際執行戰鬥 Scene、Unit、AI、技能與呈現。
#
# 【怎麼調整】
# 一般平衡與資料調整不要直接改 Runtime；若要追加功能，建議在較後腳本 alias 原方法後擴充。
#
# 【本腳本主要設定常數／資料表】
# - PROGRESSION_FLOW_PATCH_VERSION_V0771
#
# 【PMD_AC 對外／共用方法】
# - multi_branch_species_v0771?
#
# 【Runtime 主要方法（查流程時可直接搜尋）】
# - self / evolve_if_ready / start
#
# 【維護規則】
# - RPG Maker VX / RGSS2 / Ruby 1.8 相容。
# - instance_uid 才是 Pokémon 個體身份；Actor ID 只是容器。
# - 新增行為優先沿用既有 helper／Data 表；避免破壞已 Freeze 的舊核心。
# - 本專案新腳本也必須保留同等級的中文說明與實際範例。
#==============================================================================
#==============================================================================
# PMD AutoChess Proto v0.77.1
# Branch Evolution Auto-Selection Intercept
# RGSS2 / Ruby 1.8 compatible
#------------------------------------------------------------------------------
# v0.16.1 historically resolved multi-branch level evolution by stable
# instance_uid random selection. v0.77 changes the player-facing policy to
# explicit choice, so multi-branch species must not pass through the old
# evolve_if_ready path during EXP level-up.
#
# Simple / single-route evolution remains byte-for-byte behavior underneath.
#==============================================================================
module PMD_AC
  PROGRESSION_FLOW_PATCH_VERSION_V0771 = "0.77.1"

  def self.multi_branch_species_v0771?(species_key)
    rows = evolution_rules_v077(species_key)
    rows != nil && rows.size >= 2
  end
end

class PMD_PokemonInstance
  alias pmd_ac_v0771_evolve_if_ready evolve_if_ready unless method_defined?(:pmd_ac_v0771_evolve_if_ready)

  def evolve_if_ready
    # Multi-branch evolution is now a player decision handled by v0.77's
    # pending_evolution_choices_v077 / resolve_evolution_choice_v077 flow.
    return nil if PMD_AC.multi_branch_species_v0771?(species_key)
    pmd_ac_v0771_evolve_if_ready
  end
end

class Scene_PMD_AutoChess
  alias pmd_ac_v0771_start start unless method_defined?(:pmd_ac_v0771_start)

  def start
    pmd_ac_v0771_start
    begin
      if FileTest.exist?(PMD_AC::BATTLE_LOG_FILE)
        text = File.open(PMD_AC::BATTLE_LOG_FILE,'rb'){|f|f.read}
        text.sub!(/PMD AutoChess Proto v0\.[0-9.]+ Battle Verification Log/,
                  'PMD AutoChess Proto v0.77.1 Battle Verification Log')
        File.open(PMD_AC::BATTLE_LOG_FILE,'wb'){|f|f.write(text)}
      end
    rescue
    end
    log_event(:progression,
      'PATCH v0.77.1 branch_auto_intercept=1 multi_rule_threshold=2 '+
      'simple_auto=unchanged player_choice=v0.77 uid_random_selector=data_only')
  end
end
