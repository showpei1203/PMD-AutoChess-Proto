#==============================================================================
# 【PMD AutoChess 中文維護說明】
# 腳本：PMD AutoChess Proto v0.36.1
# 分類：核心戰鬥 Runtime
#
# 【用途／機制】
# 承接前序 Data／Config，實際執行戰鬥 Scene、Unit、AI、技能與呈現。
#
# 【怎麼調整】
# 一般平衡與資料調整不要直接改 Runtime；若要追加功能，建議在較後腳本 alias 原方法後擴充。
#
# 【本腳本主要設定常數／資料表】
# - FIELD_SPATIAL_STACK_FIX_V0361
#
# 【Runtime 主要方法（查流程時可直接搜尋）】
# - start / spatial_visual_group_v036
#
# 【維護規則】
# - RPG Maker VX / RGSS2 / Ruby 1.8 相容。
# - instance_uid 才是 Pokémon 個體身份；Actor ID 只是容器。
# - 新增行為優先沿用既有 helper／Data 表；避免破壞已 Freeze 的舊核心。
# - 本專案新腳本也必須保留同等級的中文說明與實際範例。
#==============================================================================
#==============================================================================
# ■ PMD AutoChess Proto v0.36.1
#    Spatial Field Visual Stack Fix
#------------------------------------------------------------------------------
#  Fixes v0.36 visual stacking only.
#  Local Aura/Zone fields that share the same battlefield center now belong to
#  the same visual stack group regardless of spatial type, so the existing
#  STACK_Y offset actually separates overlapping discs.
#  Combat field membership/mechanics are untouched.
#==============================================================================
module PMD_AC
  FIELD_SPATIAL_STACK_FIX_V0361 = true
end

class Scene_PMD_AutoChess
  alias pmd_ac_v0361_start start unless method_defined?(:pmd_ac_v0361_start)
  def start
    pmd_ac_v0361_start
    begin
      if FileTest.exist?(PMD_AC::BATTLE_LOG_FILE)
        text=File.open(PMD_AC::BATTLE_LOG_FILE,'rb'){|f|f.read}
        text.sub!(/PMD AutoChess Proto v0\.36 Battle Verification Log/,'PMD AutoChess Proto v0.36.1 Battle Verification Log')
        File.open(PMD_AC::BATTLE_LOG_FILE,'wb'){|f|f.write(text)}
      end
    rescue
    end
    log_event(:field_spatial,'PATCH v0.36.1 visual_stack_group=shared_center cross_type=1 stack_y=7 mechanics_unchanged=1')
  end

  # v0.36 grouped Aura by source UID and Zone by fixed coordinate. That meant
  # an Aura and a Zone centered on the same unit were visually overlapping but
  # never shared the Y-stack. Group local fields by center instead.
  def spatial_visual_group_v036(e)
    return 'global' if e[:spatial_type]==:global
    cx=((e[:center_x].to_f/12.0).round*12).to_i
    cy=((e[:center_y].to_f/12.0).round*12).to_i
    'local:'+cx.to_s+':'+cy.to_s
  end
end
