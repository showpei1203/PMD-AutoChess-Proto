#==============================================================================
# 【PMD AutoChess 中文維護說明】
# 腳本：PMD AutoChess Held Item Data v0.41
# 分類：持有道具
#
# 【用途／機制】
# 定義 Pokémon Instance 上的持有道具與 Magic Room 等互動。
#
# 【怎麼調整】
# 資料修改請看 Held Item Data；Runtime 以 instance_uid 對應個體，不要把道具存在 Actor ID
# 。
#
# 【本腳本主要設定常數／資料表】
# - HELD_ITEM_MANIFEST_V041 / HELD_ITEM_DATA_V041
#
# 【維護規則】
# - RPG Maker VX / RGSS2 / Ruby 1.8 相容。
# - instance_uid 才是 Pokémon 個體身份；Actor ID 只是容器。
# - 新增行為優先沿用既有 helper／Data 表；避免破壞已 Freeze 的舊核心。
# - 本專案新腳本也必須保留同等級的中文說明與實際範例。
#==============================================================================
# PMD AutoChess v0.41 Held Item / Magic Room Foundation Data
module PMD_AC
  HELD_ITEM_MANIFEST_V041 = {
    :schema_version=>"1.0",
    :content_version=>"0.41.0",
    :base_version=>"0.40.1",
    :feature=>"held_item_magic_room_foundation_i",
    :item_count=>8,
    :identity_storage=>:pokemon_instance,
    :identity_key=>:instance_uid,
    :magic_room_integration=>true,
    :gravity_air_balloon_grounded=>true,
    :magic_guard_life_orb_recoil_block=>true,
    :sheer_force_life_orb_recoil_block=>true,
    :focus_sash_direct_only=>true,
    :focus_sash_sturdy_precedence=>true,
    :focus_sash_endure_precedence=>true,
    :leftovers_turn_fraction=>"1/16",
    :life_orb_damage=>"13/10",
    :life_orb_recoil=>"1/10",
    :eviolite_defenses=>"3/2",
    :muscle_band=>"11/10 physical",
    :wise_glasses=>"11/10 special",
    :expert_belt=>"6/5 super_effective",
    :magic_room_pending_hook_closed=>true,
    :runtime_checksum32=>471077816,
  }
  HELD_ITEM_DATA_V041 = {
    :leftovers=>{:name=>"吃剩的東西",:name_en=>"Leftovers",:kind=>:turn_heal,:fraction_num=>1,:fraction_den=>16,:consumable=>false},
    :life_orb=>{:name=>"生命寶珠",:name_en=>"Life Orb",:kind=>:damage_boost_recoil,:damage_num=>13,:damage_den=>10,:recoil_num=>1,:recoil_den=>10,:consumable=>false},
    :focus_sash=>{:name=>"氣勢披帶",:name_en=>"Focus Sash",:kind=>:full_hp_survive,:min_hp=>1,:consumable=>true},
    :air_balloon=>{:name=>"氣球",:name_en=>"Air Balloon",:kind=>:ground_immunity_until_hit,:consumable=>true},
    :eviolite=>{:name=>"進化奇石",:name_en=>"Eviolite",:kind=>:evolution_defenses,:def_num=>3,:def_den=>2,:spdef_num=>3,:spdef_den=>2,:consumable=>false},
    :muscle_band=>{:name=>"力量頭帶",:name_en=>"Muscle Band",:kind=>:category_damage_boost,:category=>:physical,:damage_num=>11,:damage_den=>10,:consumable=>false},
    :wise_glasses=>{:name=>"博識眼鏡",:name_en=>"Wise Glasses",:kind=>:category_damage_boost,:category=>:special,:damage_num=>11,:damage_den=>10,:consumable=>false},
    :expert_belt=>{:name=>"達人帶",:name_en=>"Expert Belt",:kind=>:super_effective_boost,:damage_num=>6,:damage_den=>5,:consumable=>false},
  }
end
