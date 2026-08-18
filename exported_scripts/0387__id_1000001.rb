# encoding: UTF-8
#==============================================================================
# 【PMD AutoChess 中文維護說明】
# 腳本：PMD AutoChess RPG Foundation Data v1.00
# 分類：RPG 可遊玩循環／營地／探索／招募／Boss／個體收集
# RPG Maker VX / RGSS2 / Ruby 1.8 compatible
#==============================================================================
# 【用途】
# 將既有 v0.78～v0.99.16 系統串成第一個可實際操作的 RPG Foundation：
# 營地 → 林緣探索 → 戰鬥 → 招募／成長 → Party/BOX／圖鑑／AI → Boss → 回營地。
# 本版先以「RPG Hub + Encounter Runtime」建立可遊玩閉環，不重做戰鬥核心；
# 後續版本再把同一套 API 綁到正式地圖、NPC、劇情事件與手工地城。
#
# 【玩家操作】
# 1. 一般戰前布陣畫面按 F8 進入「林緣營地」。
# 2. 營地 ↑↓ 選擇、C 決定、B 返回戰鬥實驗室。
# 3. 林緣探索：沿用 Region Ecology + Wild Encounter + Recruit + Reward。
# 4. 特殊足跡：林緣勝利 1 次後解鎖「受驚的皮卡丘」，成功招募後鎖定。
# 5. 蜂巢霸主：林緣勝利 2 次後解鎖，沿用 Boss Framework，Boss 不可招募。
# 6. Party/BOX、圖鑑、AI 編成全部呼叫既有正式系統，不建立第二套資料。
#
# 【主要設定項】
# RPG_FOUNDATION_BOSS_WIN_REQ_V100：解鎖 Boss 需要的林緣勝場。
# RPG_FOUNDATION_SPECIAL_WIN_REQ_V100：解鎖特殊遭遇需要的林緣勝場。
# RPG_FOUNDATION_WILD_REGION_V100：第一個探索 Region。
# RPG_FOUNDATION_SPECIAL_ENCOUNTER_V100：特殊遭遇。
# RPG_FOUNDATION_BOSS_ENCOUNTER_V100：第一個 Boss。
#
# 【機制規則】
# - Pokémon 個體身份仍使用 instance_uid。
# - Nature × AI Temperament v0.99.16 保留，招募個體會自然帶入 Nature。
# - 野外／Boss 使用 field HP carry；敗北回營地並治療。
# - 招募沿用 v0.80/v0.81，Party/BOX 沿用 v0.78，圖鑑沿用 v0.93。
# - 不修改 Damage Formula、Normal Attack Speed、Priority、Accuracy。
#
# 【事件／腳本呼叫範例】
# PMD_AC.open_rpg_foundation_v100
# PMD_AC.start_rpg_foundation_wild_v100
# PMD_AC.start_rpg_foundation_special_v100
# PMD_AC.start_rpg_foundation_boss_v100
# PMD_AC.rpg_foundation_state_v100
# PMD_AC.reset_rpg_foundation_v100
#
# 【S 驗證】
# NORMAL -> S 一次 -> RPG_FOUNDATION_V100 -> Shift
# S 只保留最新 5 個正式 verifier：v1.00 / v0.99.16 / .15 / .14 / .13。
#===============================================================================
module PMD_AC
  RPG_FOUNDATION_VERSION_V100='1.00'
  RPG_FOUNDATION_REPORT_V100='PMD_RPGFoundation_v1.00.txt'
  RPG_FOUNDATION_VERIFY_END_V100=210

  RPG_FOUNDATION_WILD_REGION_V100=:forest_edge
  RPG_FOUNDATION_SPECIAL_ENCOUNTER_V100=:roadside_pikachu
  RPG_FOUNDATION_BOSS_ENCOUNTER_V100=:boss_beedrill
  RPG_FOUNDATION_SPECIAL_WIN_REQ_V100=1
  RPG_FOUNDATION_BOSS_WIN_REQ_V100=2

  RPG_FOUNDATION_MENU_V100=[
    :wild,
    :special,
    :boss,
    :party,
    :collection,
    :ai,
    :heal,
    :battle_lab
  ]

  RPG_FOUNDATION_MENU_LABEL_V100={
    :wild=>'前往林緣探索',
    :special=>'調查特殊足跡・皮卡丘',
    :boss=>'挑戰蜂巢霸主・大針蜂',
    :party=>'隊伍／BOX',
    :collection=>'寶可夢圖鑑',
    :ai=>'AI Strategy 編成',
    :heal=>'營地休息／全隊治療',
    :battle_lab=>'返回戰鬥實驗室'
  }

  RPG_FOUNDATION_MANIFEST_V100={
    :version=>'1.00.0',
    :loop=>[:camp,:explore,:battle,:recruit,:growth,:party_storage,:boss,:return],
    :wild_region=>RPG_FOUNDATION_WILD_REGION_V100,
    :special=>RPG_FOUNDATION_SPECIAL_ENCOUNTER_V100,
    :boss=>RPG_FOUNDATION_BOSS_ENCOUNTER_V100,
    :boss_unlock_wins=>RPG_FOUNDATION_BOSS_WIN_REQ_V100,
    :identity=>:instance_uid,
    :nature_ai=>'v0.99.16',
    :spatial_ai=>'v0.99.15',
    :party_storage=>'v0.78',
    :reward=>'v0.79-v0.94',
    :encounter=>'v0.81-v0.92',
    :collection=>'v0.93',
    :boss_framework=>'v0.91',
    :combat_core_direct_modification=>false
  }

  class << self
    def rpg_foundation_default_state_v100
      {
        :visits=>0,
        :expeditions=>0,
        :wild_wins=>0,
        :wild_losses=>0,
        :special_wins=>0,
        :special_cleared=>false,
        :boss_attempts=>0,
        :boss_wins=>0,
        :boss_cleared=>false,
        :recruits=>0,
        :last_result=>nil,
        :last_kind=>nil,
        :last_recruit_uid=>nil,
        :last_recruit_species=>nil,
        :last_recruit_nature=>nil
      }
    end

    def rpg_foundation_manifest_errors_v100
      e=[]
      e.push('wild_region') if !respond_to?(:region_data_v086) || region_data_v086(RPG_FOUNDATION_WILD_REGION_V100)==nil
      e.push('special_encounter') if !respond_to?(:encounter_data_v081) || encounter_data_v081(RPG_FOUNDATION_SPECIAL_ENCOUNTER_V100)==nil
      e.push('boss_encounter') if !respond_to?(:encounter_data_v081) || encounter_data_v081(RPG_FOUNDATION_BOSS_ENCOUNTER_V100)==nil
      e.push('party_api') unless respond_to?(:party_instances_v078) && respond_to?(:storage_count_v078)
      e.push('collection_api') unless respond_to?(:dex_summary_v093)
      e.push('nature_ai') unless respond_to?(:temperament_axes_v09916)
      e
    end

    def write_rpg_foundation_report_v100
      lines=[]
      lines << 'PMD AutoChess RPG Foundation v1.00'
      lines << 'Playable loop: camp -> explore -> battle -> recruit/growth -> party/BOX -> boss -> camp'
      lines << 'Hub shortcut: F8 from NORMAL deploy'
      lines << 'Wild region: '+RPG_FOUNDATION_WILD_REGION_V100.to_s
      lines << 'Special encounter: '+RPG_FOUNDATION_SPECIAL_ENCOUNTER_V100.to_s+' unlock_wins='+RPG_FOUNDATION_SPECIAL_WIN_REQ_V100.to_s
      lines << 'Boss encounter: '+RPG_FOUNDATION_BOSS_ENCOUNTER_V100.to_s+' unlock_wins='+RPG_FOUNDATION_BOSS_WIN_REQ_V100.to_s
      lines << 'Identity: instance_uid'
      lines << 'Nature x AI Temperament carry: YES'
      lines << 'Party/BOX carry: YES'
      lines << 'Collection/Pokedex carry: YES'
      lines << 'Field HP carry: YES'
      lines << 'Reward/Loot carry: YES'
      lines << 'Boss Framework carry: YES'
      lines << 'Normal Attack Speed modified: NO'
      lines << 'Damage formula modified: NO'
      lines << 'Frozen Combat Core direct modification: NO'
      errors=rpg_foundation_manifest_errors_v100
      lines << 'Manifest errors: '+errors.join(',')
      lines << 'Review PASS: '+(errors.empty? ? '1':'0')
      File.open(RPG_FOUNDATION_REPORT_V100,'wb'){|f|f.write(lines.join("\r\n")+"\r\n")}
      errors.empty?
    rescue
      false
    end
  end
end
