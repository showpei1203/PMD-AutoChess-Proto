#==============================================================================
# 【PMD AutoChess 中文維護說明】
# 腳本：PMD AutoChess Collection / Pokédex Data v0.93
# 分類：蒐集紀錄／全國圖鑑資料層
#
# 【用途】
# 將既有 494 種 Species Data、instance_uid Registry、Stage／Region Encounter
# 整理成可永久保存的「Species Dex」。圖鑑只記錄種族層級資訊，Party／BOX 的
# 真正個體仍完全由 v0.45/v0.78 instance_uid 系統管理。
#
# 【主要機制】
# - seen：真正進入戰鬥後曾看過該種族。
# - owned：曾經擁有過該種族；目前是否仍持有則即時計算 Party／BOX。
# - encounter_count：以「戰鬥」為單位，同種族一場只加一次。
# - elite_seen：曾遇到 Elite；highest_rarity 記錄最高稀有遭遇階級。
# - owning implies seen；舊存檔會從目前 Registry 與已通關 Stage 做一次安全回填。
# - Evolution Line 直接讀 v0.16.1 EVOLUTION_LINES_V016，不另維護第二份進化表。
#
# 【可調參數】
# - DEX_PAGE_SIZE_V093：圖鑑每頁筆數。
# - RARITY_RANK_V093／RARITY_LABEL_V093：稀有度排序與顯示。
# - TYPE_LABEL_V093：屬性中文名稱。
#
# 【腳本呼叫範例】
#   PMD_AC.dex_seen_v093?(:pikachu)
#   PMD_AC.dex_ever_owned_v093?(:pikachu)
#   PMD_AC.dex_current_owned_count_v093(:pikachu)
#   PMD_AC.dex_entry_v093(:pikachu)
#   PMD_AC.dex_summary_v093
#   PMD_AC.open_collection_v093        # 地圖事件可直接開圖鑑
#
# 【維護規則／注意】
# - 未遭遇種族不得在 UI 洩漏名稱、屬性、進化資訊。
# - 曾遭遇但未擁有，只顯示基本生態／戰鬥資訊；擁有後才揭露完整進化線。
# - Verifier 使用 snapshot/restore，不可污染玩家正式蒐集紀錄。
# - RPG Maker VX / RGSS2 / Ruby 1.8 相容。
#==============================================================================
module PMD_AC
  DEX_PAGE_SIZE_V093 = 14
  COLLECTION_VERIFY_END_V093 = 30

  RARITY_RANK_V093 = {
    :normal=>0, :common=>0, :uncommon=>1, :rare=>2, :very_rare=>3, :legendary=>4
  }
  RARITY_LABEL_V093 = {
    :normal=>'一般', :common=>'一般', :uncommon=>'少見', :rare=>'稀有',
    :very_rare=>'極稀有', :legendary=>'傳說'
  }
  TYPE_LABEL_V093 = {
    :normal=>'一般', :fire=>'火', :water=>'水', :electric=>'電', :grass=>'草',
    :ice=>'冰', :fighting=>'格鬥', :poison=>'毒', :ground=>'地面', :flying=>'飛行',
    :psychic=>'超能力', :bug=>'蟲', :rock=>'岩石', :ghost=>'幽靈', :dragon=>'龍',
    :dark=>'惡', :steel=>'鋼', :fairy=>'妖精'
  }

  COLLECTION_MANIFEST_V093 = {
    :schema_version=>'1.0', :content_version=>'0.93.0',
    :feature=>'species_collection_pokedex', :species=>494,
    :identity=>'instance_uid_registry_v0.45', :storage=>'party3_box24x30_v0.78',
    :seen_on_real_battle=>true, :ever_owned=>true, :current_owned_dynamic=>true,
    :elite_history=>true, :rarity_history=>true, :evolution_line=>'v0.16.1',
    :migration=>'registry+cleared_stage_backfill', :ui=>'battle_overlay+map_scene',
    :runtime_checksum32=>930930517
  }
end

class Game_System
  attr_accessor :pmd_autochess_dex_entries_v093
  attr_accessor :pmd_autochess_dex_order_v093
  attr_accessor :pmd_autochess_dex_migrated_v093
end
