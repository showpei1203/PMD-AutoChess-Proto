# encoding: UTF-8
#==============================================================================
# PMD AutoChess Encounter Unlock Data v0.87
# 區域解鎖／遭遇條件／稀有怪開關設定層
# RPG Maker VX / RGSS2 / Ruby 1.8 compatible
#==============================================================================
# 【這支腳本是做什麼的】
# v0.86 已經能設定「區域生態、完整編成、稀有 Encounter、精英獎勵」，
# 但如果要做真正 RPG 地圖，還需要「這個區域什麼時候能去、這隻稀有怪什麼
# 時候才會出現」的解鎖層。v0.87 就是補這一塊。
#
# 你可以用：
#   - Switch 開關
#   - Variable 變數
#   - Stage 通關次數
# 來控制：
#   1. 某個 Region 是否可用
#   2. 某個 Formation 是否可抽到
#   3. 某張地圖的預設野外 Encounter 是否開放
#
#----------------------------------------------------------------------------- 
# 【A. 最常改的表】
#
# 1. CONDITION_PRESETS_V087
#    把常用條件先取名字，之後 Region/Formation 直接引用 Symbol。
#
# 2. REGION_UNLOCK_RULES_V087
#    控制某個 Region 什麼時候開放。
#
# 3. FORMATION_UNLOCK_RULES_V087
#    控制某個 Formation 什麼時候可抽到。
#
# 4. MAP_REGION_UNLOCK_RULES_V087
#    控制某張地圖的預設 Region 遇敵是否啟用。
#
#----------------------------------------------------------------------------- 
# 【B. 條件格式】
# 條件可用 Symbol（引用預設）、Hash、或 Array（多個條件一起用）。
#
# Hash 支援欄位：
#   :switch_on     => 81 或 [81,82]
#   :switch_off    => 83 或 [83,84]
#   :variable_min  => {21=>3, 22=>10}
#   :variable_max  => {23=>5}
#   :stage_clear_min => {1=>1, 2=>3}
#
# 上述欄位同時存在時，必須全部成立。
#
# 例如：
#   {:switch_on=>81}
#   {:variable_min=>{31=>2}}
#   {:switch_on=>81,:stage_clear_min=>{1=>1}}
#
# Array 代表全部都要成立，例如：
#   [:thunder_key, {:variable_min=>{40=>1}}]
#
#----------------------------------------------------------------------------- 
# 【C. 設定範例】
# 1. 只有打通 Stage 1 才能進深林：
#   REGION_UNLOCK_RULES_V087[:deep_forest] = :forest_clear
#
# 2. 傳聞開關打開後，林緣才有稀有皮卡丘編成：
#   FORMATION_UNLOCK_RULES_V087[:forest_pikachu_rare] = :pikachu_rumor
#
# 3. 雷羽坡地圖只有拿到劇情鑰匙才開放：
#   REGION_UNLOCK_RULES_V087[:thunder_slope] = :thunder_key
#   MAP_REGION_UNLOCK_RULES_V087[18] = :thunder_key
#
#----------------------------------------------------------------------------- 
# 【D. 事件常用指令】
# 先開啟某條件：
#   $game_switches[81] = true
#   $game_variables[81] = 2
#
# 然後正常呼叫 v0.86 / v0.87 Region 戰鬥都會吃到條件：
#   PMD_AC.start_region_battle_v086(:forest_edge)
#   PMD_AC.start_region_battle_v087(:forest_edge)
#
# 地圖野怪（可附條件）：
#   PMD_AC.wild_region_on_v087(:forest_edge,10,18,[1],12,:forest_clear)
#
#----------------------------------------------------------------------------- 
# 【E. 設計原則】
# - 條件只影響「可否出現／可否開戰」，不改 HP、AI、移動、傷害公式。
# - 無法出現的 Formation 會直接從權重池排除，不會假裝抽到了又取消。
# - 若 Region 被鎖住，Wild Encounter 也不會觸發。
# - 使用者之後正式做劇情時，大多只要改本 Data 腳本，不必碰 Runtime。
# - 新腳本維持完整中文說明。腳本會寫，說明也要會寫；不然未來的你會想揍現在的你。
#==============================================================================
module PMD_AC
  CONDITION_PRESETS_V087 = {
    :pikachu_rumor=>{:switch_on=>81},
    :forest_clear=>{:stage_clear_min=>{1=>1}},
    :thunder_key=>{:switch_on=>82},
    :poison_report=>{:variable_min=>{81=>2}}
  }

  REGION_UNLOCK_RULES_V087 = {
    :deep_forest=>:forest_clear,
    :thunder_slope=>:thunder_key
  }

  FORMATION_UNLOCK_RULES_V087 = {
    :forest_pikachu_rare=>:pikachu_rumor,
    :poison_grove_beedrill=>:poison_report,
    :thunder_slope_pikachu=>[:thunder_key,:forest_clear]
  }

  MAP_REGION_UNLOCK_RULES_V087 = {
  }

  ENCOUNTER_UNLOCK_VERIFY_END_V087 = 26
  ENCOUNTER_UNLOCK_MANIFEST_V087 = {
    :schema_version=>'1.0',
    :content_version=>'0.87.0',
    :condition_presets=>CONDITION_PRESETS_V087.size,
    :region_rules=>REGION_UNLOCK_RULES_V087.size,
    :formation_rules=>FORMATION_UNLOCK_RULES_V087.size,
    :map_rules=>MAP_REGION_UNLOCK_RULES_V087.size,
    :supported_keys=>[:switch_on,:switch_off,:variable_min,:variable_max,:stage_clear_min],
    :ui_patch=>'small_text_up_title_same',
    :runtime_checksum32=>870870417
  }

  class << self
    def unlock_rule_errors_v087
      e=[]
      REGION_UNLOCK_RULES_V087.each_key do |key|
        e.push('region:'+key.to_s) if respond_to?(:region_data_v086) && region_data_v086(key)==nil
      end
      FORMATION_UNLOCK_RULES_V087.each_key do |key|
        e.push('formation:'+key.to_s) if respond_to?(:formation_data_v086) && formation_data_v086(key)==nil
      end
      MAP_REGION_UNLOCK_RULES_V087.each_key do |key|
        e.push('map:'+key.to_s) if key.to_i<=0
      end
      e
    end
  end
end
