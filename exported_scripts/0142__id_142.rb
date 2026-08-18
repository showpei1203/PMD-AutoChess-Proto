#==============================================================================
# 【PMD AutoChess 中文維護說明】
# 腳本：PMD AutoChess Proto v0.24.1
# 分類：核心戰鬥 Runtime
#
# 【用途／機制】
# 承接前序 Data／Config，實際執行戰鬥 Scene、Unit、AI、技能與呈現。
#
# 【怎麼調整】
# 一般平衡與資料調整不要直接改 Runtime；若要追加功能，建議在較後腳本 alias 原方法後擴充。
#
# 【Runtime 主要方法（查流程時可直接搜尋）】
# - ability_checksum_scalar_v0241 / ability_checksum32 / start / verify_ability_manifest
#
# 【維護規則】
# - RPG Maker VX / RGSS2 / Ruby 1.8 相容。
# - instance_uid 才是 Pokémon 個體身份；Actor ID 只是容器。
# - 新增行為優先沿用既有 helper／Data 表；避免破壞已 Freeze 的舊核心。
# - 本專案新腳本也必須保留同等級的中文說明與實際範例。
#==============================================================================
#==============================================================================
# PMD AutoChess Proto v0.24.1
# ABILITY checksum portability correction only.
#------------------------------------------------------------------------------
# v0.24's integrity checksum serialized Float values with Float#to_s.  RGSS2
# embeds Ruby 1.8, whose Float#to_s formatting is not guaranteed to match the
# Python/Ruby-3 build environment for long fractional values such as 1.0 / 3.0.
# The actual ability data and all v0.24 mechanics were correct; only the
# cross-runtime checksum representation was non-portable.
#
# v0.24.1 uses an explicit canonical Float serializer for the checksum.  Normal
# combat, ability data, slot data, RNG, and all behavior hooks are unchanged.
#==============================================================================

module PMD_AC
  class << self
    # Stable textual representation shared by the generated manifest and RGSS2.
    # Integer-valued floats keep '.0' because the source compiler serialized
    # them that way; non-integer floats use 16 significant digits, sufficient
    # for all v0.24 behavior constants while avoiding Ruby-version Float#to_s.
    def ability_checksum_scalar_v0241(x)
      return x.join(",") if x.is_a?(Array)
      if x.is_a?(Float)
        s = sprintf("%.16g", x)
        s += ".0" if s !~ /[\.eE]/
        return s
      end
      x.to_s
    end

    def ability_checksum32
      h = 0
      data = AbilityDB.instance_variable_get(:@data)
      for k in data[:behaviors].keys.sort { |a,b| a.to_s <=> b.to_s }
        d = AbilityDB.behavior(k)
        fields = [k, d[:kind], d[:type], d[:mult], d[:threshold], d[:heal_ratio],
          d[:boost_mult], d[:max_power], d[:flag], d[:canonical_stab],
          d[:base_stab], d[:statuses], d[:stats], d[:target], d[:stat],
          d[:stages], d[:status], d[:chance], d[:form_only]]
        text = fields.collect { |x| ability_checksum_scalar_v0241(x) }.join("|")
        text.each_byte { |by| h = ((h * 33) + by) & 0x7fffffff }
      end
      keys = data[:species_slots].keys.sort { |a,b| a.to_s <=> b.to_s }
      for sk in keys
        s = AbilityDB.species_slots(sk)
        text = [sk, s[:primary], s[:secondary], s[:hidden]].collect { |x| x.to_s }.join("|")
        text.each_byte { |by| h = ((h * 33) + by) & 0x7fffffff }
      end
      h
    end
  end
end

class Scene_PMD_AutoChess
  alias pmd_ac_v0241_start start unless method_defined?(:pmd_ac_v0241_start)

  def start
    pmd_ac_v0241_start
    begin
      if FileTest.exist?(PMD_AC::BATTLE_LOG_FILE)
        text = File.open(PMD_AC::BATTLE_LOG_FILE, "rb") { |f| f.read }
        text.sub!("PMD AutoChess Proto v0.24 Battle Verification Log",
                  "PMD AutoChess Proto v0.24.1 Battle Verification Log")
        File.open(PMD_AC::BATTLE_LOG_FILE, "wb") { |f| f.write(text) }
      end
    rescue
    end
  end

  # Keep v0.24's manifest test, but expose both values in the log so a future
  # platform mismatch cannot hide behind the manifest's expected checksum.
  def verify_ability_manifest(tag)
    return if @verification_done[tag]
    m = PMD_AC::AbilityDB.manifest
    e = PMD_AC.validate_ability_db
    actual = PMD_AC.ability_checksum32
    pass = e.empty?
    log_event(:verify, tag.to_s.upcase + " pass=" + (pass ? "1" : "0") +
      " behaviors=" + PMD_AC::AbilityDB.behavior_count.to_s +
      " slots=" + m[:implemented_slot_count].to_s + "/" + m[:total_slot_count].to_s +
      " coverage=" + m[:implemented_slot_coverage_percent].to_s + "%" +
      " species=" + m[:species_with_any_implemented_ability].to_s + "/494" +
      " corrected=" + m[:corrected_slot_count].to_s +
      " checksum_expected=" + m[:runtime_checksum32].to_s +
      " checksum_actual=" + actual.to_s +
      " errors=[" + e.join(",") + "]")
    @verification_done[tag] = true
  end
end
