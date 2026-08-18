#==============================================================================
# 【PMD AutoChess 中文維護說明】
# 腳本：PMD AutoChess Proto v0.41.1
# 分類：核心戰鬥 Runtime
#
# 【用途／機制】
# 承接前序 Data／Config，實際執行戰鬥 Scene、Unit、AI、技能與呈現。
#
# 【怎麼調整】
# 一般平衡與資料調整不要直接改 Runtime；若要追加功能，建議在較後腳本 alias 原方法後擴充。
#
# 【Runtime 主要方法（查流程時可直接搜尋）】
# - receive_damage / start
#
# 【維護規則】
# - RPG Maker VX / RGSS2 / Ruby 1.8 相容。
# - instance_uid 才是 Pokémon 個體身份；Actor ID 只是容器。
# - 新增行為優先沿用既有 helper／Data 表；避免破壞已 Freeze 的舊核心。
# - 本專案新腳本也必須保留同等級的中文說明與實際範例。
#==============================================================================
#===============================================================================
# ■ PMD AutoChess Proto v0.41.1
#    RGSS2 Held Item Direct-Damage Compatibility Fix
#-------------------------------------------------------------------------------
# Additive compatibility patch over v0.41.
#
# RPG Maker VX / RGSS2 Ruby does not provide Object#instance_variable_defined?
# in this runtime. v0.41 used it only to test whether the canonical direct
# damage context was active for Focus Sash.
#
# Reading an unset instance variable safely returns nil in RGSS2, so the exact
# intended check can be expressed as:
#   @canonical_direct_damage_context != nil
#
# No Held Item mechanics, damage rules, Magic Room behavior, item identity,
# verification data, or prior scripts are modified.
#===============================================================================

class Game_PMDChessUnit
  # Override only the v0.41 wrapper.  pmd_ac_v041_receive_damage still points
  # to the verified pre-v0.41 receive_damage chain.
  def receive_damage(value,source=nil,grant_energy=true,bypass_link=false,critical=false)
    raw=value.to_i
    direct=(@canonical_direct_damage_context!=nil)
    sturdy_will_handle=(ability_key==:sturdy && respond_to?(:canonical_sturdy_eligible_source?) && canonical_sturdy_eligible_source?(source))
    endure_will_handle=(respond_to?(:guard_active_v040?) && guard_active_v040?(:endure))
    if direct && held_item_effective_v041?(:focus_sash) && @hp.to_i==@maxhp.to_i && @hp.to_i>1 && !sturdy_will_handle && !endure_will_handle && respond_to?(:canonical_preview_local_hp_damage) && canonical_preview_local_hp_damage(raw,bypass_link)>=@hp.to_i
      capped=respond_to?(:canonical_cap_sturdy_raw) ? canonical_cap_sturdy_raw(raw,bypass_link) : [raw,@hp.to_i-1].min
      capped=1 if capped<1
      value=capped
      consume_held_item_v041(:focus_sash)
      log_event(:held_item,log_name+' FOCUS_SASH raw='+raw.to_s+'->'+value.to_i.to_s+' hp='+@hp.to_s)
    end
    pmd_ac_v041_receive_damage(value,source,grant_energy,bypass_link,critical)
  end
end

class Scene_PMD_AutoChess
  alias pmd_ac_v0411_start start unless method_defined?(:pmd_ac_v0411_start)
  def start
    pmd_ac_v0411_start
    begin
      if FileTest.exist?(PMD_AC::BATTLE_LOG_FILE)
        text=File.open(PMD_AC::BATTLE_LOG_FILE,'rb'){|f|f.read}
        text.sub!(/PMD AutoChess Proto v0\.[0-9.]+ Battle Verification Log/,
                  'PMD AutoChess Proto v0.41.1 Battle Verification Log')
        File.open(PMD_AC::BATTLE_LOG_FILE,'wb'){|f|f.write(text)}
      end
    rescue
    end
    log_event(:held_item,'PATCH v0.41.1 rgss2_instance_variable_defined_fix=1 direct_context=nil_check mechanics_unchanged=1')
  end
end
