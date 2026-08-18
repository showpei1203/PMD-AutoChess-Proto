# encoding: UTF-8
#==============================================================================
# 【PMD AutoChess 中文維護說明】
# 腳本：PMD AutoChess Kanto Gameplay Review Data v0.99.8
# 分類：Pokémon Gameplay / AI / Balance Review #0001-0151
#
# 【用途】
# - 正式完成 National Dex #0001-0151 的第一輪逐隻 Gameplay Review。
# - 每隻 Pokémon 都人工指定 Role、Movement/Target/Threat/Skill Policy、
#   普通攻擊距離、屬性與 Physical/Special 類別，不再沿用 percentile 自動結論。
# - canonical Base Stats / Level-up Learnset / TM / Egg / Tutor / Ability 資料不重寫，
#   Review row 會引用既有 Production Data 並計算完整養成來源。
# - 對 ruleset-enabled 的 Mega Venusaur / Charizard X / Charizard Y / Mega Blastoise
#   額外建立 Form Tactical Profile，使型態差異不只停在 Stats / Type / Ability。
#
# 【主要設定項】
# KANTO_PROFILE_OVERRIDES_V0998
#   151 隻普通型的人工戰術 Profile。
# KANTO_FORM_PROFILE_OVERRIDES_V0998
#   目前 Kanto 中 ruleset-enabled 的 4 個非 Normal Form 戰術 Profile。
# KANTO_SPECIAL_BALANCE_RISKS_V0998
#   Ditto、Magikarp、Abra、Chansey 等需特別追蹤的平衡風險。
#
# 【普通攻擊規則】
# - :range=1 為近戰；:range=3 為遠程。
# - :basic_damage_category 可為 :physical 或 :special。
# - :basic_move_type 必須屬於該 Pokémon 當前形態 Type，Form override 可改變。
# - 本版 Runtime 只在 source_type=:basic 時注入類別，不改 Skill damage category。
#
# 【AI 規則】
# - 物種 Profile 是預設值。
# - 玩家在 PokémonInstance 儲存的 ai_setup 永遠擁有更高優先權。
# - 進化／Mega Form 改變後會重新套物種／形態預設，再重新套玩家 ai_setup。
#
# 【事件／腳本呼叫方式】
# row = PMD_AC.gameplay_review_row_v0998(:bulbasaur)
# profile = PMD_AC.review_profile_for_v0998(:charizard, :mega_x)
# PMD_AC.write_kanto_gameplay_review_v0998
#
# 【實際範例】
# Bulbasaur：Controller / ranged Grass Special / cluster control。
# Raichu：由舊自動近戰 Assassin 改為 ranged Electric Special Kiter。
# Diglett：由舊自動 ranged Controller 改為 melee Ground Assassin。
# Charizard：Normal=Fire Special Artillery；Mega X=Dragon Physical Bruiser；
#            Mega Y=Fire Special Artillery。
#
# 【維護限制】
# - RPG Maker VX / RGSS2 / Ruby 1.8。
# - 不使用禁止的舊式 instance variable 反射檢查。
# - Actor ID 不是 Pokémon identity；仍使用 instance_uid。
# - Frozen Combat Core 不直接修改，本版以 Main 前追加 Data/Runtime Hook 實作。
#==============================================================================
module PMD_AC
  GAMEPLAY_REVIEW_VERSION_V0998='0.99.8'
  KANTO_REVIEW_DEX_RANGE_V0998=(1..151)
  KANTO_REVIEW_STATUS_V0998=:reviewed_manual

  KANTO_PROFILE_OVERRIDES_V0998={
    :bulbasaur=>{:role=>:controller,:movement_policy=>:controller,:target_policy=>:cluster,:threat_policy=>:responsive,:skill_policy=>:best_cluster,:range=>3,:basic_damage_category=>:special,:basic_move_type=>:grass,:target_commitment=>60},
    :ivysaur=>{:role=>:controller,:movement_policy=>:controller,:target_policy=>:cluster,:threat_policy=>:responsive,:skill_policy=>:best_cluster,:range=>3,:basic_damage_category=>:special,:basic_move_type=>:grass,:target_commitment=>66},
    :venusaur=>{:role=>:controller,:movement_policy=>:controller,:target_policy=>:cluster,:threat_policy=>:hold_ground,:skill_policy=>:best_cluster,:range=>3,:basic_damage_category=>:special,:basic_move_type=>:grass,:target_commitment=>72},
    :charmander=>{:role=>:kiter,:movement_policy=>:kiter,:target_policy=>:nearest,:threat_policy=>:responsive,:skill_policy=>:current_target,:range=>3,:basic_damage_category=>:special,:basic_move_type=>:fire,:target_commitment=>54},
    :charmeleon=>{:role=>:kiter,:movement_policy=>:kiter,:target_policy=>:execute,:threat_policy=>:responsive,:skill_policy=>:execute,:range=>3,:basic_damage_category=>:special,:basic_move_type=>:fire,:target_commitment=>60},
    :charizard=>{:role=>:artillery,:movement_policy=>:artillery,:target_policy=>:cluster,:threat_policy=>:responsive,:skill_policy=>:best_cluster,:range=>3,:basic_damage_category=>:special,:basic_move_type=>:fire,:target_commitment=>66},
    :squirtle=>{:role=>:bodyguard,:movement_policy=>:bodyguard,:target_policy=>:protect_ally,:threat_policy=>:protective,:skill_policy=>:protect_ally,:range=>3,:basic_damage_category=>:special,:basic_move_type=>:water,:target_commitment=>78},
    :wartortle=>{:role=>:bodyguard,:movement_policy=>:bodyguard,:target_policy=>:protect_ally,:threat_policy=>:protective,:skill_policy=>:protect_ally,:range=>3,:basic_damage_category=>:special,:basic_move_type=>:water,:target_commitment=>84},
    :blastoise=>{:role=>:bodyguard,:movement_policy=>:bodyguard,:target_policy=>:protect_ally,:threat_policy=>:protective,:skill_policy=>:protect_ally,:range=>3,:basic_damage_category=>:special,:basic_move_type=>:water,:target_commitment=>88},
    :caterpie=>{:role=>:controller,:movement_policy=>:controller,:target_policy=>:cluster,:threat_policy=>:responsive,:skill_policy=>:best_cluster,:range=>3,:basic_damage_category=>:special,:basic_move_type=>:bug,:target_commitment=>46},
    :metapod=>{:role=>:frontline,:movement_policy=>:frontline,:target_policy=>:nearest,:threat_policy=>:hold_ground,:skill_policy=>:current_target,:range=>1,:basic_damage_category=>:physical,:basic_move_type=>:bug,:target_commitment=>90},
    :butterfree=>{:role=>:controller,:movement_policy=>:controller,:target_policy=>:cluster,:threat_policy=>:responsive,:skill_policy=>:best_cluster,:range=>3,:basic_damage_category=>:special,:basic_move_type=>:bug,:target_commitment=>58},
    :weedle=>{:role=>:controller,:movement_policy=>:controller,:target_policy=>:cluster,:threat_policy=>:responsive,:skill_policy=>:current_target,:range=>3,:basic_damage_category=>:physical,:basic_move_type=>:poison,:target_commitment=>48},
    :kakuna=>{:role=>:frontline,:movement_policy=>:frontline,:target_policy=>:nearest,:threat_policy=>:hold_ground,:skill_policy=>:current_target,:range=>1,:basic_damage_category=>:physical,:basic_move_type=>:poison,:target_commitment=>90},
    :beedrill=>{:role=>:assassin,:movement_policy=>:assassin,:target_policy=>:backline_low_def,:threat_policy=>:ignore_minor,:skill_policy=>:execute,:range=>1,:basic_damage_category=>:physical,:basic_move_type=>:bug,:target_commitment=>84},
    :pidgey=>{:role=>:bruiser,:movement_policy=>:bruiser,:target_policy=>:execute,:threat_policy=>:normal,:skill_policy=>:execute,:range=>1,:basic_damage_category=>:physical,:basic_move_type=>:flying,:target_commitment=>58},
    :pidgeotto=>{:role=>:bruiser,:movement_policy=>:bruiser,:target_policy=>:execute,:threat_policy=>:normal,:skill_policy=>:execute,:range=>1,:basic_damage_category=>:physical,:basic_move_type=>:flying,:target_commitment=>64},
    :pidgeot=>{:role=>:assassin,:movement_policy=>:assassin,:target_policy=>:backline_low_def,:threat_policy=>:ignore_minor,:skill_policy=>:execute,:range=>1,:basic_damage_category=>:physical,:basic_move_type=>:flying,:target_commitment=>78},
    :rattata=>{:role=>:assassin,:movement_policy=>:assassin,:target_policy=>:backline_low_def,:threat_policy=>:ignore_minor,:skill_policy=>:execute,:range=>1,:basic_damage_category=>:physical,:basic_move_type=>:normal,:target_commitment=>76},
    :raticate=>{:role=>:bruiser,:movement_policy=>:berserker,:target_policy=>:execute,:threat_policy=>:ignore_minor,:skill_policy=>:execute,:range=>1,:basic_damage_category=>:physical,:basic_move_type=>:normal,:target_commitment=>80},
    :spearow=>{:role=>:bruiser,:movement_policy=>:bruiser,:target_policy=>:execute,:threat_policy=>:normal,:skill_policy=>:execute,:range=>1,:basic_damage_category=>:physical,:basic_move_type=>:flying,:target_commitment=>64},
    :fearow=>{:role=>:assassin,:movement_policy=>:assassin,:target_policy=>:backline_low_def,:threat_policy=>:ignore_minor,:skill_policy=>:execute,:range=>1,:basic_damage_category=>:physical,:basic_move_type=>:flying,:target_commitment=>82},
    :ekans=>{:role=>:controller,:movement_policy=>:bruiser,:target_policy=>:highest_atk,:threat_policy=>:responsive,:skill_policy=>:highest_atk,:range=>1,:basic_damage_category=>:physical,:basic_move_type=>:poison,:target_commitment=>62},
    :arbok=>{:role=>:controller,:movement_policy=>:bruiser,:target_policy=>:highest_atk,:threat_policy=>:responsive,:skill_policy=>:highest_atk,:range=>1,:basic_damage_category=>:physical,:basic_move_type=>:poison,:target_commitment=>70},
    :pikachu=>{:role=>:controller,:movement_policy=>:kiter,:target_policy=>:lowest_hp_percent,:threat_policy=>:responsive,:skill_policy=>:current_target,:range=>3,:basic_damage_category=>:special,:basic_move_type=>:electric,:target_commitment=>52},
    :raichu=>{:role=>:kiter,:movement_policy=>:kiter,:target_policy=>:execute,:threat_policy=>:responsive,:skill_policy=>:execute,:range=>3,:basic_damage_category=>:special,:basic_move_type=>:electric,:target_commitment=>62},
    :sandshrew=>{:role=>:frontline,:movement_policy=>:frontline,:target_policy=>:melee_first,:threat_policy=>:hold_ground,:skill_policy=>:current_target,:range=>1,:basic_damage_category=>:physical,:basic_move_type=>:ground,:target_commitment=>76},
    :sandslash=>{:role=>:bruiser,:movement_policy=>:bruiser,:target_policy=>:execute,:threat_policy=>:normal,:skill_policy=>:execute,:range=>1,:basic_damage_category=>:physical,:basic_move_type=>:ground,:target_commitment=>74},
    :nidoran_f=>{:role=>:frontline,:movement_policy=>:frontline,:target_policy=>:nearest,:threat_policy=>:hold_ground,:skill_policy=>:current_target,:range=>1,:basic_damage_category=>:physical,:basic_move_type=>:poison,:target_commitment=>70},
    :nidorina=>{:role=>:bodyguard,:movement_policy=>:bodyguard,:target_policy=>:protect_ally,:threat_policy=>:protective,:skill_policy=>:protect_ally,:range=>1,:basic_damage_category=>:physical,:basic_move_type=>:poison,:target_commitment=>82},
    :nidoqueen=>{:role=>:bodyguard,:movement_policy=>:bodyguard,:target_policy=>:protect_ally,:threat_policy=>:protective,:skill_policy=>:protect_ally,:range=>1,:basic_damage_category=>:physical,:basic_move_type=>:ground,:target_commitment=>88},
    :nidoran_m=>{:role=>:bruiser,:movement_policy=>:bruiser,:target_policy=>:execute,:threat_policy=>:normal,:skill_policy=>:execute,:range=>1,:basic_damage_category=>:physical,:basic_move_type=>:poison,:target_commitment=>62},
    :nidorino=>{:role=>:bruiser,:movement_policy=>:bruiser,:target_policy=>:execute,:threat_policy=>:normal,:skill_policy=>:execute,:range=>1,:basic_damage_category=>:physical,:basic_move_type=>:poison,:target_commitment=>70},
    :nidoking=>{:role=>:bruiser,:movement_policy=>:bruiser,:target_policy=>:lowest_def,:threat_policy=>:ignore_minor,:skill_policy=>:lowest_def,:range=>1,:basic_damage_category=>:physical,:basic_move_type=>:ground,:target_commitment=>76},
    :clefairy=>{:role=>:bodyguard,:movement_policy=>:bodyguard,:target_policy=>:protect_ally,:threat_policy=>:protective,:skill_policy=>:heal_critical,:range=>3,:basic_damage_category=>:special,:basic_move_type=>:fairy,:target_commitment=>84},
    :clefable=>{:role=>:bodyguard,:movement_policy=>:bodyguard,:target_policy=>:protect_ally,:threat_policy=>:protective,:skill_policy=>:heal_critical,:range=>3,:basic_damage_category=>:special,:basic_move_type=>:fairy,:target_commitment=>90},
    :vulpix=>{:role=>:controller,:movement_policy=>:controller,:target_policy=>:cluster,:threat_policy=>:responsive,:skill_policy=>:best_cluster,:range=>3,:basic_damage_category=>:special,:basic_move_type=>:fire,:target_commitment=>54},
    :ninetales=>{:role=>:controller,:movement_policy=>:controller,:target_policy=>:cluster,:threat_policy=>:responsive,:skill_policy=>:best_cluster,:range=>3,:basic_damage_category=>:special,:basic_move_type=>:fire,:target_commitment=>62},
    :jigglypuff=>{:role=>:controller,:movement_policy=>:controller,:target_policy=>:highest_atk,:threat_policy=>:responsive,:skill_policy=>:highest_atk,:range=>3,:basic_damage_category=>:special,:basic_move_type=>:fairy,:target_commitment=>66},
    :wigglytuff=>{:role=>:bodyguard,:movement_policy=>:bodyguard,:target_policy=>:protect_ally,:threat_policy=>:protective,:skill_policy=>:heal_critical,:range=>3,:basic_damage_category=>:special,:basic_move_type=>:fairy,:target_commitment=>86},
    :zubat=>{:role=>:assassin,:movement_policy=>:assassin,:target_policy=>:backline_low_def,:threat_policy=>:ignore_minor,:skill_policy=>:execute,:range=>1,:basic_damage_category=>:physical,:basic_move_type=>:flying,:target_commitment=>70},
    :golbat=>{:role=>:assassin,:movement_policy=>:assassin,:target_policy=>:backline_low_def,:threat_policy=>:responsive,:skill_policy=>:execute,:range=>1,:basic_damage_category=>:physical,:basic_move_type=>:flying,:target_commitment=>76},
    :oddish=>{:role=>:controller,:movement_policy=>:controller,:target_policy=>:cluster,:threat_policy=>:responsive,:skill_policy=>:best_cluster,:range=>3,:basic_damage_category=>:special,:basic_move_type=>:grass,:target_commitment=>58},
    :gloom=>{:role=>:controller,:movement_policy=>:controller,:target_policy=>:cluster,:threat_policy=>:responsive,:skill_policy=>:best_cluster,:range=>3,:basic_damage_category=>:special,:basic_move_type=>:grass,:target_commitment=>66},
    :vileplume=>{:role=>:artillery,:movement_policy=>:artillery,:target_policy=>:cluster,:threat_policy=>:responsive,:skill_policy=>:best_cluster,:range=>3,:basic_damage_category=>:special,:basic_move_type=>:grass,:target_commitment=>72},
    :paras=>{:role=>:frontline,:movement_policy=>:frontline,:target_policy=>:highest_atk,:threat_policy=>:hold_ground,:skill_policy=>:highest_atk,:range=>1,:basic_damage_category=>:physical,:basic_move_type=>:bug,:target_commitment=>74},
    :parasect=>{:role=>:frontline,:movement_policy=>:frontline,:target_policy=>:highest_atk,:threat_policy=>:hold_ground,:skill_policy=>:highest_atk,:range=>1,:basic_damage_category=>:physical,:basic_move_type=>:bug,:target_commitment=>82},
    :venonat=>{:role=>:controller,:movement_policy=>:controller,:target_policy=>:cluster,:threat_policy=>:responsive,:skill_policy=>:best_cluster,:range=>3,:basic_damage_category=>:special,:basic_move_type=>:poison,:target_commitment=>56},
    :venomoth=>{:role=>:controller,:movement_policy=>:controller,:target_policy=>:cluster,:threat_policy=>:responsive,:skill_policy=>:best_cluster,:range=>3,:basic_damage_category=>:special,:basic_move_type=>:bug,:target_commitment=>62},
    :diglett=>{:role=>:assassin,:movement_policy=>:assassin,:target_policy=>:backline_low_def,:threat_policy=>:ignore_minor,:skill_policy=>:execute,:range=>1,:basic_damage_category=>:physical,:basic_move_type=>:ground,:target_commitment=>88},
    :dugtrio=>{:role=>:assassin,:movement_policy=>:assassin,:target_policy=>:backline_low_def,:threat_policy=>:ignore_minor,:skill_policy=>:execute,:range=>1,:basic_damage_category=>:physical,:basic_move_type=>:ground,:target_commitment=>92},
    :meowth=>{:role=>:assassin,:movement_policy=>:assassin,:target_policy=>:backline_low_def,:threat_policy=>:ignore_minor,:skill_policy=>:execute,:range=>1,:basic_damage_category=>:physical,:basic_move_type=>:normal,:target_commitment=>76},
    :persian=>{:role=>:assassin,:movement_policy=>:assassin,:target_policy=>:backline_low_def,:threat_policy=>:ignore_minor,:skill_policy=>:execute,:range=>1,:basic_damage_category=>:physical,:basic_move_type=>:normal,:target_commitment=>82},
    :psyduck=>{:role=>:controller,:movement_policy=>:controller,:target_policy=>:highest_atk,:threat_policy=>:responsive,:skill_policy=>:highest_atk,:range=>3,:basic_damage_category=>:special,:basic_move_type=>:water,:target_commitment=>56},
    :golduck=>{:role=>:kiter,:movement_policy=>:kiter,:target_policy=>:execute,:threat_policy=>:responsive,:skill_policy=>:execute,:range=>3,:basic_damage_category=>:special,:basic_move_type=>:water,:target_commitment=>62},
    :mankey=>{:role=>:bruiser,:movement_policy=>:berserker,:target_policy=>:execute,:threat_policy=>:ignore_minor,:skill_policy=>:execute,:range=>1,:basic_damage_category=>:physical,:basic_move_type=>:fighting,:target_commitment=>76},
    :primeape=>{:role=>:bruiser,:movement_policy=>:berserker,:target_policy=>:execute,:threat_policy=>:ignore_minor,:skill_policy=>:execute,:range=>1,:basic_damage_category=>:physical,:basic_move_type=>:fighting,:target_commitment=>84},
    :growlithe=>{:role=>:bruiser,:movement_policy=>:bruiser,:target_policy=>:execute,:threat_policy=>:normal,:skill_policy=>:execute,:range=>1,:basic_damage_category=>:physical,:basic_move_type=>:fire,:target_commitment=>68},
    :arcanine=>{:role=>:bodyguard,:movement_policy=>:bodyguard,:target_policy=>:protect_ally,:threat_policy=>:protective,:skill_policy=>:protect_ally,:range=>1,:basic_damage_category=>:physical,:basic_move_type=>:fire,:target_commitment=>82},
    :poliwag=>{:role=>:controller,:movement_policy=>:controller,:target_policy=>:highest_atk,:threat_policy=>:responsive,:skill_policy=>:highest_atk,:range=>3,:basic_damage_category=>:special,:basic_move_type=>:water,:target_commitment=>54},
    :poliwhirl=>{:role=>:controller,:movement_policy=>:controller,:target_policy=>:highest_atk,:threat_policy=>:responsive,:skill_policy=>:highest_atk,:range=>3,:basic_damage_category=>:special,:basic_move_type=>:water,:target_commitment=>62},
    :poliwrath=>{:role=>:frontline,:movement_policy=>:frontline,:target_policy=>:melee_first,:threat_policy=>:hold_ground,:skill_policy=>:current_target,:range=>1,:basic_damage_category=>:physical,:basic_move_type=>:fighting,:target_commitment=>82},
    :abra=>{:role=>:artillery,:movement_policy=>:artillery,:target_policy=>:lowest_def,:threat_policy=>:responsive,:skill_policy=>:lowest_def,:range=>3,:basic_damage_category=>:special,:basic_move_type=>:psychic,:target_commitment=>38},
    :kadabra=>{:role=>:artillery,:movement_policy=>:artillery,:target_policy=>:lowest_def,:threat_policy=>:responsive,:skill_policy=>:lowest_def,:range=>3,:basic_damage_category=>:special,:basic_move_type=>:psychic,:target_commitment=>50},
    :alakazam=>{:role=>:artillery,:movement_policy=>:artillery,:target_policy=>:lowest_def,:threat_policy=>:responsive,:skill_policy=>:lowest_def,:range=>3,:basic_damage_category=>:special,:basic_move_type=>:psychic,:target_commitment=>58},
    :machop=>{:role=>:bruiser,:movement_policy=>:bruiser,:target_policy=>:execute,:threat_policy=>:normal,:skill_policy=>:execute,:range=>1,:basic_damage_category=>:physical,:basic_move_type=>:fighting,:target_commitment=>72},
    :machoke=>{:role=>:frontline,:movement_policy=>:frontline,:target_policy=>:melee_first,:threat_policy=>:hold_ground,:skill_policy=>:current_target,:range=>1,:basic_damage_category=>:physical,:basic_move_type=>:fighting,:target_commitment=>80},
    :machamp=>{:role=>:frontline,:movement_policy=>:frontline,:target_policy=>:highest_atk,:threat_policy=>:hold_ground,:skill_policy=>:highest_atk,:range=>1,:basic_damage_category=>:physical,:basic_move_type=>:fighting,:target_commitment=>86},
    :bellsprout=>{:role=>:controller,:movement_policy=>:controller,:target_policy=>:cluster,:threat_policy=>:responsive,:skill_policy=>:best_cluster,:range=>3,:basic_damage_category=>:special,:basic_move_type=>:grass,:target_commitment=>56},
    :weepinbell=>{:role=>:controller,:movement_policy=>:controller,:target_policy=>:cluster,:threat_policy=>:responsive,:skill_policy=>:best_cluster,:range=>3,:basic_damage_category=>:special,:basic_move_type=>:grass,:target_commitment=>62},
    :victreebel=>{:role=>:bruiser,:movement_policy=>:bruiser,:target_policy=>:execute,:threat_policy=>:normal,:skill_policy=>:execute,:range=>1,:basic_damage_category=>:physical,:basic_move_type=>:grass,:target_commitment=>72},
    :tentacool=>{:role=>:controller,:movement_policy=>:controller,:target_policy=>:cluster,:threat_policy=>:responsive,:skill_policy=>:best_cluster,:range=>3,:basic_damage_category=>:special,:basic_move_type=>:poison,:target_commitment=>58},
    :tentacruel=>{:role=>:controller,:movement_policy=>:controller,:target_policy=>:cluster,:threat_policy=>:responsive,:skill_policy=>:best_cluster,:range=>3,:basic_damage_category=>:special,:basic_move_type=>:poison,:target_commitment=>66},
    :geodude=>{:role=>:frontline,:movement_policy=>:frontline,:target_policy=>:melee_first,:threat_policy=>:hold_ground,:skill_policy=>:current_target,:range=>1,:basic_damage_category=>:physical,:basic_move_type=>:rock,:target_commitment=>82},
    :graveler=>{:role=>:frontline,:movement_policy=>:frontline,:target_policy=>:melee_first,:threat_policy=>:hold_ground,:skill_policy=>:current_target,:range=>1,:basic_damage_category=>:physical,:basic_move_type=>:rock,:target_commitment=>86},
    :golem=>{:role=>:bodyguard,:movement_policy=>:bodyguard,:target_policy=>:protect_ally,:threat_policy=>:protective,:skill_policy=>:protect_ally,:range=>1,:basic_damage_category=>:physical,:basic_move_type=>:rock,:target_commitment=>90},
    :ponyta=>{:role=>:bruiser,:movement_policy=>:bruiser,:target_policy=>:execute,:threat_policy=>:normal,:skill_policy=>:execute,:range=>1,:basic_damage_category=>:physical,:basic_move_type=>:fire,:target_commitment=>72},
    :rapidash=>{:role=>:assassin,:movement_policy=>:assassin,:target_policy=>:backline_low_def,:threat_policy=>:ignore_minor,:skill_policy=>:execute,:range=>1,:basic_damage_category=>:physical,:basic_move_type=>:fire,:target_commitment=>82},
    :slowpoke=>{:role=>:bodyguard,:movement_policy=>:bodyguard,:target_policy=>:protect_ally,:threat_policy=>:protective,:skill_policy=>:protect_ally,:range=>3,:basic_damage_category=>:special,:basic_move_type=>:psychic,:target_commitment=>88},
    :slowbro=>{:role=>:bodyguard,:movement_policy=>:bodyguard,:target_policy=>:protect_ally,:threat_policy=>:protective,:skill_policy=>:protect_ally,:range=>3,:basic_damage_category=>:special,:basic_move_type=>:psychic,:target_commitment=>92},
    :magnemite=>{:role=>:artillery,:movement_policy=>:artillery,:target_policy=>:lowest_def,:threat_policy=>:responsive,:skill_policy=>:lowest_def,:range=>3,:basic_damage_category=>:special,:basic_move_type=>:electric,:target_commitment=>58},
    :magneton=>{:role=>:artillery,:movement_policy=>:artillery,:target_policy=>:lowest_def,:threat_policy=>:responsive,:skill_policy=>:lowest_def,:range=>3,:basic_damage_category=>:special,:basic_move_type=>:electric,:target_commitment=>66},
    :farfetchd=>{:role=>:bruiser,:movement_policy=>:bruiser,:target_policy=>:execute,:threat_policy=>:normal,:skill_policy=>:execute,:range=>1,:basic_damage_category=>:physical,:basic_move_type=>:flying,:target_commitment=>72},
    :doduo=>{:role=>:assassin,:movement_policy=>:assassin,:target_policy=>:backline_low_def,:threat_policy=>:ignore_minor,:skill_policy=>:execute,:range=>1,:basic_damage_category=>:physical,:basic_move_type=>:flying,:target_commitment=>76},
    :dodrio=>{:role=>:assassin,:movement_policy=>:assassin,:target_policy=>:backline_low_def,:threat_policy=>:ignore_minor,:skill_policy=>:execute,:range=>1,:basic_damage_category=>:physical,:basic_move_type=>:flying,:target_commitment=>84},
    :seel=>{:role=>:bodyguard,:movement_policy=>:bodyguard,:target_policy=>:protect_ally,:threat_policy=>:protective,:skill_policy=>:protect_ally,:range=>3,:basic_damage_category=>:special,:basic_move_type=>:water,:target_commitment=>80},
    :dewgong=>{:role=>:bodyguard,:movement_policy=>:bodyguard,:target_policy=>:protect_ally,:threat_policy=>:protective,:skill_policy=>:protect_ally,:range=>3,:basic_damage_category=>:special,:basic_move_type=>:ice,:target_commitment=>86},
    :grimer=>{:role=>:frontline,:movement_policy=>:frontline,:target_policy=>:melee_first,:threat_policy=>:hold_ground,:skill_policy=>:current_target,:range=>1,:basic_damage_category=>:physical,:basic_move_type=>:poison,:target_commitment=>82},
    :muk=>{:role=>:bodyguard,:movement_policy=>:bodyguard,:target_policy=>:protect_ally,:threat_policy=>:protective,:skill_policy=>:protect_ally,:range=>1,:basic_damage_category=>:physical,:basic_move_type=>:poison,:target_commitment=>90},
    :shellder=>{:role=>:artillery,:movement_policy=>:artillery,:target_policy=>:lowest_def,:threat_policy=>:responsive,:skill_policy=>:execute,:range=>3,:basic_damage_category=>:physical,:basic_move_type=>:water,:target_commitment=>58},
    :cloyster=>{:role=>:artillery,:movement_policy=>:artillery,:target_policy=>:lowest_def,:threat_policy=>:responsive,:skill_policy=>:execute,:range=>3,:basic_damage_category=>:physical,:basic_move_type=>:ice,:target_commitment=>66},
    :gastly=>{:role=>:artillery,:movement_policy=>:artillery,:target_policy=>:backline_low_def,:threat_policy=>:responsive,:skill_policy=>:execute,:range=>3,:basic_damage_category=>:special,:basic_move_type=>:ghost,:target_commitment=>48},
    :haunter=>{:role=>:artillery,:movement_policy=>:artillery,:target_policy=>:backline_low_def,:threat_policy=>:responsive,:skill_policy=>:execute,:range=>3,:basic_damage_category=>:special,:basic_move_type=>:ghost,:target_commitment=>56},
    :gengar=>{:role=>:assassin,:movement_policy=>:kiter,:target_policy=>:backline_low_def,:threat_policy=>:ignore_minor,:skill_policy=>:execute,:range=>3,:basic_damage_category=>:special,:basic_move_type=>:ghost,:target_commitment=>70},
    :onix=>{:role=>:frontline,:movement_policy=>:frontline,:target_policy=>:melee_first,:threat_policy=>:hold_ground,:skill_policy=>:current_target,:range=>1,:basic_damage_category=>:physical,:basic_move_type=>:rock,:target_commitment=>92},
    :drowzee=>{:role=>:controller,:movement_policy=>:controller,:target_policy=>:highest_atk,:threat_policy=>:responsive,:skill_policy=>:highest_atk,:range=>3,:basic_damage_category=>:special,:basic_move_type=>:psychic,:target_commitment=>66},
    :hypno=>{:role=>:controller,:movement_policy=>:controller,:target_policy=>:highest_atk,:threat_policy=>:responsive,:skill_policy=>:highest_atk,:range=>3,:basic_damage_category=>:special,:basic_move_type=>:psychic,:target_commitment=>76},
    :krabby=>{:role=>:bruiser,:movement_policy=>:bruiser,:target_policy=>:lowest_def,:threat_policy=>:normal,:skill_policy=>:lowest_def,:range=>1,:basic_damage_category=>:physical,:basic_move_type=>:water,:target_commitment=>72},
    :kingler=>{:role=>:bruiser,:movement_policy=>:berserker,:target_policy=>:lowest_def,:threat_policy=>:ignore_minor,:skill_policy=>:execute,:range=>1,:basic_damage_category=>:physical,:basic_move_type=>:water,:target_commitment=>80},
    :voltorb=>{:role=>:controller,:movement_policy=>:controller,:target_policy=>:cluster,:threat_policy=>:responsive,:skill_policy=>:best_cluster,:range=>3,:basic_damage_category=>:special,:basic_move_type=>:electric,:target_commitment=>48},
    :electrode=>{:role=>:kiter,:movement_policy=>:kiter,:target_policy=>:execute,:threat_policy=>:responsive,:skill_policy=>:execute,:range=>3,:basic_damage_category=>:special,:basic_move_type=>:electric,:target_commitment=>54},
    :exeggcute=>{:role=>:controller,:movement_policy=>:controller,:target_policy=>:cluster,:threat_policy=>:responsive,:skill_policy=>:best_cluster,:range=>3,:basic_damage_category=>:special,:basic_move_type=>:psychic,:target_commitment=>62},
    :exeggutor=>{:role=>:artillery,:movement_policy=>:artillery,:target_policy=>:cluster,:threat_policy=>:responsive,:skill_policy=>:best_cluster,:range=>3,:basic_damage_category=>:special,:basic_move_type=>:psychic,:target_commitment=>70},
    :cubone=>{:role=>:frontline,:movement_policy=>:frontline,:target_policy=>:melee_first,:threat_policy=>:hold_ground,:skill_policy=>:current_target,:range=>1,:basic_damage_category=>:physical,:basic_move_type=>:ground,:target_commitment=>80},
    :marowak=>{:role=>:bruiser,:movement_policy=>:bruiser,:target_policy=>:execute,:threat_policy=>:normal,:skill_policy=>:execute,:range=>1,:basic_damage_category=>:physical,:basic_move_type=>:ground,:target_commitment=>84},
    :hitmonlee=>{:role=>:assassin,:movement_policy=>:assassin,:target_policy=>:backline_low_def,:threat_policy=>:ignore_minor,:skill_policy=>:execute,:range=>1,:basic_damage_category=>:physical,:basic_move_type=>:fighting,:target_commitment=>82},
    :hitmonchan=>{:role=>:bruiser,:movement_policy=>:bruiser,:target_policy=>:highest_atk,:threat_policy=>:normal,:skill_policy=>:highest_atk,:range=>1,:basic_damage_category=>:physical,:basic_move_type=>:fighting,:target_commitment=>78},
    :lickitung=>{:role=>:bodyguard,:movement_policy=>:bodyguard,:target_policy=>:protect_ally,:threat_policy=>:protective,:skill_policy=>:protect_ally,:range=>1,:basic_damage_category=>:physical,:basic_move_type=>:normal,:target_commitment=>88},
    :koffing=>{:role=>:controller,:movement_policy=>:controller,:target_policy=>:cluster,:threat_policy=>:responsive,:skill_policy=>:best_cluster,:range=>3,:basic_damage_category=>:special,:basic_move_type=>:poison,:target_commitment=>66},
    :weezing=>{:role=>:controller,:movement_policy=>:controller,:target_policy=>:cluster,:threat_policy=>:responsive,:skill_policy=>:best_cluster,:range=>3,:basic_damage_category=>:special,:basic_move_type=>:poison,:target_commitment=>76},
    :rhyhorn=>{:role=>:frontline,:movement_policy=>:frontline,:target_policy=>:melee_first,:threat_policy=>:hold_ground,:skill_policy=>:current_target,:range=>1,:basic_damage_category=>:physical,:basic_move_type=>:ground,:target_commitment=>90},
    :rhydon=>{:role=>:frontline,:movement_policy=>:frontline,:target_policy=>:highest_atk,:threat_policy=>:hold_ground,:skill_policy=>:highest_atk,:range=>1,:basic_damage_category=>:physical,:basic_move_type=>:ground,:target_commitment=>92},
    :chansey=>{:role=>:bodyguard,:movement_policy=>:bodyguard,:target_policy=>:protect_ally,:threat_policy=>:protective,:skill_policy=>:heal_critical,:range=>3,:basic_damage_category=>:special,:basic_move_type=>:normal,:target_commitment=>94},
    :tangela=>{:role=>:controller,:movement_policy=>:controller,:target_policy=>:cluster,:threat_policy=>:responsive,:skill_policy=>:best_cluster,:range=>3,:basic_damage_category=>:special,:basic_move_type=>:grass,:target_commitment=>72},
    :kangaskhan=>{:role=>:bruiser,:movement_policy=>:bruiser,:target_policy=>:execute,:threat_policy=>:normal,:skill_policy=>:execute,:range=>1,:basic_damage_category=>:physical,:basic_move_type=>:normal,:target_commitment=>82},
    :horsea=>{:role=>:artillery,:movement_policy=>:artillery,:target_policy=>:lowest_def,:threat_policy=>:responsive,:skill_policy=>:lowest_def,:range=>3,:basic_damage_category=>:special,:basic_move_type=>:water,:target_commitment=>54},
    :seadra=>{:role=>:artillery,:movement_policy=>:artillery,:target_policy=>:lowest_def,:threat_policy=>:responsive,:skill_policy=>:lowest_def,:range=>3,:basic_damage_category=>:special,:basic_move_type=>:water,:target_commitment=>62},
    :goldeen=>{:role=>:bruiser,:movement_policy=>:bruiser,:target_policy=>:execute,:threat_policy=>:normal,:skill_policy=>:execute,:range=>1,:basic_damage_category=>:physical,:basic_move_type=>:water,:target_commitment=>68},
    :seaking=>{:role=>:bruiser,:movement_policy=>:bruiser,:target_policy=>:execute,:threat_policy=>:normal,:skill_policy=>:execute,:range=>1,:basic_damage_category=>:physical,:basic_move_type=>:water,:target_commitment=>76},
    :staryu=>{:role=>:kiter,:movement_policy=>:kiter,:target_policy=>:lowest_hp_percent,:threat_policy=>:responsive,:skill_policy=>:current_target,:range=>3,:basic_damage_category=>:special,:basic_move_type=>:water,:target_commitment=>54},
    :starmie=>{:role=>:artillery,:movement_policy=>:artillery,:target_policy=>:lowest_def,:threat_policy=>:responsive,:skill_policy=>:lowest_def,:range=>3,:basic_damage_category=>:special,:basic_move_type=>:psychic,:target_commitment=>60},
    :mr_mime=>{:role=>:bodyguard,:movement_policy=>:bodyguard,:target_policy=>:protect_ally,:threat_policy=>:protective,:skill_policy=>:protect_ally,:range=>3,:basic_damage_category=>:special,:basic_move_type=>:psychic,:target_commitment=>88},
    :scyther=>{:role=>:assassin,:movement_policy=>:assassin,:target_policy=>:backline_low_def,:threat_policy=>:ignore_minor,:skill_policy=>:execute,:range=>1,:basic_damage_category=>:physical,:basic_move_type=>:bug,:target_commitment=>84},
    :jynx=>{:role=>:controller,:movement_policy=>:controller,:target_policy=>:highest_atk,:threat_policy=>:responsive,:skill_policy=>:highest_atk,:range=>3,:basic_damage_category=>:special,:basic_move_type=>:ice,:target_commitment=>64},
    :electabuzz=>{:role=>:kiter,:movement_policy=>:kiter,:target_policy=>:execute,:threat_policy=>:responsive,:skill_policy=>:execute,:range=>3,:basic_damage_category=>:special,:basic_move_type=>:electric,:target_commitment=>64},
    :magmar=>{:role=>:kiter,:movement_policy=>:kiter,:target_policy=>:execute,:threat_policy=>:responsive,:skill_policy=>:execute,:range=>3,:basic_damage_category=>:special,:basic_move_type=>:fire,:target_commitment=>64},
    :pinsir=>{:role=>:assassin,:movement_policy=>:assassin,:target_policy=>:lowest_def,:threat_policy=>:ignore_minor,:skill_policy=>:execute,:range=>1,:basic_damage_category=>:physical,:basic_move_type=>:bug,:target_commitment=>82},
    :tauros=>{:role=>:assassin,:movement_policy=>:assassin,:target_policy=>:backline_low_def,:threat_policy=>:ignore_minor,:skill_policy=>:execute,:range=>1,:basic_damage_category=>:physical,:basic_move_type=>:normal,:target_commitment=>86},
    :magikarp=>{:role=>:frontline,:movement_policy=>:frontline,:target_policy=>:nearest,:threat_policy=>:hold_ground,:skill_policy=>:current_target,:range=>1,:basic_damage_category=>:physical,:basic_move_type=>:water,:target_commitment=>96},
    :gyarados=>{:role=>:bruiser,:movement_policy=>:berserker,:target_policy=>:execute,:threat_policy=>:ignore_minor,:skill_policy=>:execute,:range=>1,:basic_damage_category=>:physical,:basic_move_type=>:water,:target_commitment=>84},
    :lapras=>{:role=>:bodyguard,:movement_policy=>:bodyguard,:target_policy=>:protect_ally,:threat_policy=>:protective,:skill_policy=>:protect_ally,:range=>3,:basic_damage_category=>:special,:basic_move_type=>:ice,:target_commitment=>90},
    :ditto=>{:role=>:frontline,:movement_policy=>:frontline,:target_policy=>:nearest,:threat_policy=>:normal,:skill_policy=>:current_target,:range=>1,:basic_damage_category=>:physical,:basic_move_type=>:normal,:target_commitment=>60},
    :eevee=>{:role=>:bruiser,:movement_policy=>:bruiser,:target_policy=>:execute,:threat_policy=>:normal,:skill_policy=>:current_target,:range=>1,:basic_damage_category=>:physical,:basic_move_type=>:normal,:target_commitment=>64},
    :vaporeon=>{:role=>:artillery,:movement_policy=>:artillery,:target_policy=>:lowest_def,:threat_policy=>:responsive,:skill_policy=>:lowest_def,:range=>3,:basic_damage_category=>:special,:basic_move_type=>:water,:target_commitment=>64},
    :jolteon=>{:role=>:kiter,:movement_policy=>:kiter,:target_policy=>:execute,:threat_policy=>:responsive,:skill_policy=>:execute,:range=>3,:basic_damage_category=>:special,:basic_move_type=>:electric,:target_commitment=>58},
    :flareon=>{:role=>:bruiser,:movement_policy=>:bruiser,:target_policy=>:execute,:threat_policy=>:normal,:skill_policy=>:execute,:range=>1,:basic_damage_category=>:physical,:basic_move_type=>:fire,:target_commitment=>72},
    :porygon=>{:role=>:controller,:movement_policy=>:controller,:target_policy=>:highest_atk,:threat_policy=>:responsive,:skill_policy=>:protect_ally,:range=>3,:basic_damage_category=>:special,:basic_move_type=>:normal,:target_commitment=>74},
    :omanyte=>{:role=>:artillery,:movement_policy=>:artillery,:target_policy=>:lowest_def,:threat_policy=>:responsive,:skill_policy=>:lowest_def,:range=>3,:basic_damage_category=>:special,:basic_move_type=>:water,:target_commitment=>66},
    :omastar=>{:role=>:artillery,:movement_policy=>:artillery,:target_policy=>:cluster,:threat_policy=>:responsive,:skill_policy=>:best_cluster,:range=>3,:basic_damage_category=>:special,:basic_move_type=>:rock,:target_commitment=>74},
    :kabuto=>{:role=>:bruiser,:movement_policy=>:bruiser,:target_policy=>:execute,:threat_policy=>:normal,:skill_policy=>:execute,:range=>1,:basic_damage_category=>:physical,:basic_move_type=>:water,:target_commitment=>72},
    :kabutops=>{:role=>:assassin,:movement_policy=>:assassin,:target_policy=>:backline_low_def,:threat_policy=>:ignore_minor,:skill_policy=>:execute,:range=>1,:basic_damage_category=>:physical,:basic_move_type=>:rock,:target_commitment=>82},
    :aerodactyl=>{:role=>:assassin,:movement_policy=>:assassin,:target_policy=>:backline_low_def,:threat_policy=>:ignore_minor,:skill_policy=>:execute,:range=>1,:basic_damage_category=>:physical,:basic_move_type=>:flying,:target_commitment=>86},
    :snorlax=>{:role=>:frontline,:movement_policy=>:frontline,:target_policy=>:melee_first,:threat_policy=>:hold_ground,:skill_policy=>:current_target,:range=>1,:basic_damage_category=>:physical,:basic_move_type=>:normal,:target_commitment=>96},
    :articuno=>{:role=>:controller,:movement_policy=>:controller,:target_policy=>:cluster,:threat_policy=>:responsive,:skill_policy=>:best_cluster,:range=>3,:basic_damage_category=>:special,:basic_move_type=>:ice,:target_commitment=>78},
    :zapdos=>{:role=>:artillery,:movement_policy=>:artillery,:target_policy=>:lowest_def,:threat_policy=>:responsive,:skill_policy=>:lowest_def,:range=>3,:basic_damage_category=>:special,:basic_move_type=>:electric,:target_commitment=>72},
    :moltres=>{:role=>:artillery,:movement_policy=>:artillery,:target_policy=>:cluster,:threat_policy=>:responsive,:skill_policy=>:best_cluster,:range=>3,:basic_damage_category=>:special,:basic_move_type=>:fire,:target_commitment=>72},
    :dratini=>{:role=>:bruiser,:movement_policy=>:bruiser,:target_policy=>:execute,:threat_policy=>:normal,:skill_policy=>:current_target,:range=>1,:basic_damage_category=>:physical,:basic_move_type=>:dragon,:target_commitment=>66},
    :dragonair=>{:role=>:bruiser,:movement_policy=>:bruiser,:target_policy=>:execute,:threat_policy=>:responsive,:skill_policy=>:current_target,:range=>1,:basic_damage_category=>:physical,:basic_move_type=>:dragon,:target_commitment=>72},
    :dragonite=>{:role=>:bodyguard,:movement_policy=>:bodyguard,:target_policy=>:protect_ally,:threat_policy=>:protective,:skill_policy=>:protect_ally,:range=>1,:basic_damage_category=>:physical,:basic_move_type=>:dragon,:target_commitment=>88},
    :mewtwo=>{:role=>:artillery,:movement_policy=>:artillery,:target_policy=>:backline_low_def,:threat_policy=>:responsive,:skill_policy=>:lowest_def,:range=>3,:basic_damage_category=>:special,:basic_move_type=>:psychic,:target_commitment=>68},
    :mew=>{:role=>:controller,:movement_policy=>:controller,:target_policy=>:cluster,:threat_policy=>:responsive,:skill_policy=>:best_cluster,:range=>3,:basic_damage_category=>:special,:basic_move_type=>:psychic,:target_commitment=>70},
  }

  KANTO_FORM_PROFILE_OVERRIDES_V0998={
    [:venusaur,:mega]=>{:role=>:bodyguard,:movement_policy=>:bodyguard,:target_policy=>:protect_ally,:threat_policy=>:protective,:skill_policy=>:protect_ally,:range=>3,:basic_damage_category=>:special,:basic_move_type=>:grass,:target_commitment=>90},
    [:charizard,:mega_x]=>{:role=>:bruiser,:movement_policy=>:bruiser,:target_policy=>:execute,:threat_policy=>:normal,:skill_policy=>:execute,:range=>1,:basic_damage_category=>:physical,:basic_move_type=>:dragon,:target_commitment=>80},
    [:charizard,:mega_y]=>{:role=>:artillery,:movement_policy=>:artillery,:target_policy=>:cluster,:threat_policy=>:responsive,:skill_policy=>:best_cluster,:range=>3,:basic_damage_category=>:special,:basic_move_type=>:fire,:target_commitment=>70},
    [:blastoise,:mega]=>{:role=>:artillery,:movement_policy=>:artillery,:target_policy=>:lowest_def,:threat_policy=>:responsive,:skill_policy=>:lowest_def,:range=>3,:basic_damage_category=>:special,:basic_move_type=>:water,:target_commitment=>78},
  }

  KANTO_SPECIAL_BALANCE_RISKS_V0998={
    :metapod=>[:low_agency_until_evolution,:tutor_dependency],
    :kakuna=>[:low_agency_until_evolution,:tutor_dependency],
    :abra=>[:teleport_only_early,:extreme_glass_cannon],
    :magikarp=>[:identity_weak_stage,:tutor_bounce_only],
    :ditto=>[:transform_copy_scaling,:single_move_identity],
    :chansey=>[:extreme_hp_special_wall,:very_low_physical_defense],
    :cloyster=>[:extreme_physical_defense,:skill_link_multihit_spike],
    :onix=>[:extreme_physical_defense,:low_damage_without_growth],
    :diglett=>[:extreme_low_hp,:arena_trap_focus_risk],
    :dugtrio=>[:high_speed_assassin,:arena_trap_focus_risk],
    :alakazam=>[:high_speed_special_burst,:low_physical_bulk],
    :gengar=>[:high_speed_special_burst,:control_chain_risk],
    :snorlax=>[:stall_sustain_risk,:slow_frontline_bodyblock],
    :mewtwo=>[:legendary_power_budget,:high_speed_special_burst],
    :mew=>[:movepool_breadth_extreme,:role_flexibility_ceiling],
    :gyarados=>[:intimidate_moxie_snowball,:physical_burst],
    :dragonite=>[:multiscale_bodyguard_stall,:coverage_breadth],
    :lapras=>[:high_hp_bodyguard_stall,:coverage_breadth],
    :clefairy=>[:friend_guard_support_stall],
    :clefable=>[:magic_guard_unaware_support_stall],
    :vileplume=>[:powder_control_chain,:effect_spore_contact_punish],
    :butterfree=>[:compound_eyes_sleep_control],
    :ninetales=>[:drought_team_amplification],
    :charizard=>[:mega_form_role_divergence],
    :venusaur=>[:mega_form_bulk_spike],
    :blastoise=>[:mega_form_special_spike],
  }

  KANTO_IDENTITY_NOTES_V0998={
    :ditto=>"Transform 是核心玩法；不以四招數量評價。普通攻擊只是變身前最低限度自衛。",
    :magikarp=>"弱勢成長期是刻意設計；靠進化成暴鯉龍形成巨大回報，不補免費強招。",
    :metapod=>"定位為高物防過渡前排；攻擊能力主要靠進化前繼承與已解鎖 Tutor。",
    :kakuna=>"定位為高物防過渡前排；不為了湊四招破壞蛹期特色。",
    :abra=>"Lv1 僅 Teleport 是原作身份；早期戰鬥價值由 TM/Egg/Tutor 養成取得，而非免費補招。",
  }

  KANTO_ROLE_NOTES_V0998={
    :frontline=>"貼線承傷與穩定輸出",
    :bruiser=>"近戰壓迫與收頭",
    :assassin=>"繞後追擊脆弱後排",
    :kiter=>"維持射程並持續輸出",
    :artillery=>"遠距高價值技能與爆發",
    :controller=>"以狀態／群聚控制塑造戰場",
    :bodyguard=>"貼近隊友攔截威脅與保護核心",
  }

  KANTO_REVIEW_MANIFEST_V0998={
    :dex_range=>[1,151],:reviewed_species=>151,:pending_species=>343,
    :fields=>18,:profile_generation=>:manual_kanto_v0998,
    :enabled_form_profiles=>4,:combat_core_direct_modification=>false
  }
end
