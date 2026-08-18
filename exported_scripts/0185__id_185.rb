#==============================================================================
# 【PMD AutoChess 中文維護說明】
# 腳本：PMD AutoChess Proto v0.42.1
# 分類：核心戰鬥 Runtime
#
# 【用途／機制】
# 承接前序 Data／Config，實際執行戰鬥 Scene、Unit、AI、技能與呈現。
#
# 【怎麼調整】
# 一般平衡與資料調整不要直接改 Runtime；若要追加功能，建議在較後腳本 alias 原方法後擴充。
#
# 【PMD_AC 對外／共用方法】
# - priority_deep_symbolize_keys_v0421 / priority_key_normalization_ok_v0421
#
# 【Runtime 主要方法（查流程時可直接搜尋）】
# - self / start
#
# 【維護規則】
# - RPG Maker VX / RGSS2 / Ruby 1.8 相容。
# - instance_uid 才是 Pokémon 個體身份；Actor ID 只是容器。
# - 新增行為優先沿用既有 helper／Data 表；避免破壞已 Freeze 的舊核心。
# - 本專案新腳本也必須保留同等級的中文說明與實際範例。
#==============================================================================
#===============================================================================
# ■ PMD AutoChess Proto v0.42.1
#    Priority Runtime RGSS2 Data-Key Compatibility Fix
#-------------------------------------------------------------------------------
# Additive hotfix on v0.42.
#
# Root cause found by the v0.42 real VX verification log:
# - Generated PRIORITY_MOVE_V042 / VISUAL / AUDIO profile payloads used String
#   keys ("priority", "canonical_move_key", ...).
# - The RGSS2 runtime consistently reads Symbol keys (:priority,
#   :canonical_move_key, ...).
# - Therefore the eight new moves loaded, but behaved as empty/default skill
#   records: priority became 0, canonical damage was 0, and visual/audio/data
#   verification failed.
#
# Fix:
# - Deep-normalize only Hash KEYS in the three v0.42 generated priority tables
#   from String to Symbol once when this patch is loaded.
# - String VALUES are preserved except move identity values that are runtime
#   Symbol contracts (:move_key / :canonical_move_key).
# - No timing formula, damage formula, Quick Guard rule, energy rule, or older
#   script is changed.
#===============================================================================
module PMD_AC
  def self.priority_deep_symbolize_keys_v0421(obj)
    if obj.is_a?(Hash)
      h={}
      obj.each do |k,v|
        nk=k.is_a?(String) ? k.to_sym : k
        h[nk]=priority_deep_symbolize_keys_v0421(v)
      end
      return h
    elsif obj.is_a?(Array)
      return obj.collect{|v|priority_deep_symbolize_keys_v0421(v)}
    end
    obj
  end

  PRIORITY_MOVE_V042.keys.each do |k|
    d=priority_deep_symbolize_keys_v0421(PRIORITY_MOVE_V042[k])
    # v0.42 generator also emitted the move identity VALUES as Strings.
    # Runtime contracts use Symbols for canonical/move keys.
    d[:move_key]=d[:move_key].to_sym if d[:move_key].is_a?(String)
    d[:canonical_move_key]=d[:canonical_move_key].to_sym if d[:canonical_move_key].is_a?(String)
    PRIORITY_MOVE_V042[k]=d
  end
  PRIORITY_VISUAL_V042.keys.each do |k|
    PRIORITY_VISUAL_V042[k]=priority_deep_symbolize_keys_v0421(PRIORITY_VISUAL_V042[k])
  end
  PRIORITY_AUDIO_V042.keys.each do |k|
    PRIORITY_AUDIO_V042[k]=priority_deep_symbolize_keys_v0421(PRIORITY_AUDIO_V042[k])
  end

  def self.priority_key_normalization_ok_v0421
    d=PRIORITY_MOVE_V042[:quick_attack]
    e=PRIORITY_MOVE_V042[:extreme_speed]
    v=PRIORITY_VISUAL_V042[:quick_attack]
    a=PRIORITY_AUDIO_V042[:quick_attack]
    return false if d==nil || e==nil || v==nil || a==nil
    return false unless d[:priority].to_i==1
    return false unless e[:priority].to_i==2
    return false unless d[:canonical_move_key]==:quick_attack
    return false unless d[:move_key]==:quick_attack
    return false unless d[:effects].is_a?(Array) && d[:effects][0].is_a?(Hash)
    return false unless d[:effects][0][:type]==:damage && d[:effects][0][:power].to_i==40
    return false unless v[:visual_kind]==:contact_hit
    return false unless a[:hit_cat]==:impact_mid
    true
  end
end

class Scene_PMD_AutoChess
  alias pmd_ac_v0421_start start unless method_defined?(:pmd_ac_v0421_start)
  def start
    pmd_ac_v0421_start
    begin
      if FileTest.exist?(PMD_AC::BATTLE_LOG_FILE)
        text=File.open(PMD_AC::BATTLE_LOG_FILE,'rb'){|f|f.read}
        text.sub!(/PMD AutoChess Proto v0\.[0-9.]+ Battle Verification Log/,'PMD AutoChess Proto v0.42.1 Battle Verification Log')
        File.open(PMD_AC::BATTLE_LOG_FILE,'wb'){|f|f.write(text)}
      end
    rescue
    end
    log_event(:priority,'PATCH v0.42.1 data_key_normalize=string_to_symbol deep_hash=1 move_visual_audio=1 normalized='+(PMD_AC.priority_key_normalization_ok_v0421 ? '1':'0')+' mechanics_unchanged=1')
  end
end
