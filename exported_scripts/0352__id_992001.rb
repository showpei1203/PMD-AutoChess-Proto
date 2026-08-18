# encoding: UTF-8
#==============================================================================
# 【PMD AutoChess 中文維護說明】
# 腳本：PMD AutoChess Team Bond Data v0.99.2
# 分類：隊伍羈絆／正式資料庫／RPG 長期隊伍構築
#
# 【用途】
# 這支腳本是「隊伍羈絆」的唯一正式資料來源。羈絆名稱、組成條件、中文說明、
# 類別、優先度與效果全部集中在 TEAM_BOND_DATA_V0992，避免資料散落在 Runtime。
#
# 【正式設計規則】
# 1. 羈絆是 RPG 長期收集／培養／編隊內容，不是每一輪重抽的肉鴿 Buff。
# 2. 每隊最多同時生效 1 個「關係羈絆」(:relationship)＋1 個「戰術羈絆」(:tactical)。
# 3. 同類條件同時成立時，只取 priority 最高者；priority 相同時依 key 字串排序。
# 4. Summon 不參與羈絆；Actor ID 不作為羈絆身份，永遠依 species_key / line / tags。
# 5. 戰鬥開始鎖定正式出戰三隻；中途倒下不會讓羈絆消失。
# 6. Form / Mega 變更可重新判定，但一次性效果不會因重判重複領取。
# 7. 舊 v0.15「初代御三家」+12 Energy 保留並由舊 Runtime 執行，本版不重複加成。
#
# 【Composition DSL】
# 關係羈絆使用 :composition，每個 requirement 必須由不同正式出戰單位填入：
# {:type=>:species, :key=>:mew}
# {:type=>:line, :key=>:bulbasaur_line}
# {:type=>:species_pool, :keys=>[:vaporeon,:jolteon,...], :count=>3, :unique=>true}
# {:type=>:form, :species=>:shaymin, :form=>:sky}
#
# 【Tactical Condition DSL】
# 戰術羈絆使用 :condition，角色標籤可重疊計數：
# :required_roles=>{:ranged=>2,:controller=>1}
# :required_role_pools=>[{:roles=>[:frontline,:tank],:count=>1}]
#
# 【Effect DSL】
# :initial_energy         開場 Energy（加法）
# :damage_out_mult        全傷害輸出倍率
# :damage_in_mult         承受傷害倍率
# :energy_gain_mult       正向 Energy 取得倍率
# :healing_mult           治療／吸血／HoT 回復倍率
# :move_speed_mult        戰場移動速度倍率
# :status_duration_mult   Debuff／Control 持續時間倍率
# :type_damage_mult       指定屬性傷害倍率；:move_type=>:own 表示使用者本系
# :physical_damage_mult   物理傷害倍率
# :special_damage_mult    特殊傷害倍率
# :contact_damage_mult    近戰 Role 傷害倍率
# :ranged_damage_mult     遠程 Role 傷害倍率
# :start_shield           開場護盾；:ratio 依 MaxHP
# :indirect_damage_mult   DoT／Zone 等不產生受擊 Energy 的間接傷害倍率
#
# 【Scope】
# :scope=>:team                                  全隊
# :scope=>{:species=>:gardevoir}                 指定 species
# :scope=>{:line=>:ralts_line}                   指定進化線
# :scope=>{:role=>:ranged}                       指定 role tag
# :scope=>{:tag=>:water}                         指定 synergy tag
# :scope=>{:species_pool=>[:a,:b,:c]}            指定 species 群組
#
# 【平衡上限】
# TEAM_BOND_LIMITS_V0992 是「關係＋戰術」合計後的硬上限。若日後調高單條羈絆，
# 仍不會突破上限。不要在 Runtime 另外乘一份數字。
#
# 【事件／腳本查詢】
# $scene.active_team_bond_names_v0992(:ally)
# $scene.active_team_bond_keys_v0992(:enemy)
# PMD_AC.team_bond_data_v0992(:kanto_starter_trio)
#
# 【實際範例】
# 妙蛙花＋火恐龍＋水箭龜：成立「初代御三家」。
# 太陽伊布＋月亮伊布＋水伊布：同時符合「日月共鳴」與「七色進化」，
# 但關係羈絆只取 priority 較高的「七色進化」。
#
# 【維護注意】
# - RPG Maker VX / RGSS2 / Ruby 1.8 相容。
# - 新增羈絆時必須填 name / category / priority / description / effects。
# - Relationship 的 composition 在三人隊伍中必須可成立；不可放無法觸發的幽靈條件。
# - 不在這裡修改 Ability、Move、AI、Loot、Held Item 或 RPG Map 規則。
#==============================================================================
module PMD_AC
  TEAM_BOND_VERSION_V0992='0.99.2'
  TEAM_BOND_CATEGORY_LIMIT_V0992={:relationship=>1,:tactical=>1}
  TEAM_BOND_EFFECT_TYPES_V0992=[
    :initial_energy,:damage_out_mult,:damage_in_mult,:energy_gain_mult,
    :healing_mult,:move_speed_mult,:status_duration_mult,:type_damage_mult,
    :physical_damage_mult,:special_damage_mult,:contact_damage_mult,
    :ranged_damage_mult,:start_shield,:indirect_damage_mult
  ]
  TEAM_BOND_LIMITS_V0992={
    :initial_energy=>{:min=>0,:max=>12},
    :damage_out_mult=>{:min=>1.00,:max=>1.10},
    :damage_in_mult=>{:min=>0.90,:max=>1.05},
    :energy_gain_mult=>{:min=>1.00,:max=>1.12},
    :healing_mult=>{:min=>1.00,:max=>1.15},
    :move_speed_mult=>{:min=>1.00,:max=>1.10},
    :status_duration_mult=>{:min=>0.75,:max=>1.00},
    :type_damage_mult=>{:min=>1.00,:max=>1.10},
    :physical_damage_mult=>{:min=>1.00,:max=>1.10},
    :special_damage_mult=>{:min=>1.00,:max=>1.10},
    :contact_damage_mult=>{:min=>1.00,:max=>1.10},
    :ranged_damage_mult=>{:min=>1.00,:max=>1.10},
    :start_shield=>{:min=>0.00,:max=>0.08},
    :indirect_damage_mult=>{:min=>1.00,:max=>1.10}
  }

  TEAM_BOND_DATA_V0992={
    #------------------------------------------------------------------------
    # 關係羈絆：四世代御三家
    #------------------------------------------------------------------------
    :kanto_starter_trio=>{
      :name=>'初代御三家',:category=>:relationship,:priority=>200,
      :description=>'關都三條御三家進化線共同出戰。戰鬥開始時，全隊獲得 12 Energy。',
      :composition=>[
        {:type=>:line,:key=>:bulbasaur_line},{:type=>:line,:key=>:charmander_line},
        {:type=>:line,:key=>:squirtle_line}],
      :effects=>[{:type=>:initial_energy,:amount=>12,:scope=>:team,:once=>true,:legacy_v015=>true}]
    },
    :johto_starter_trio=>{
      :name=>'城都御三家',:category=>:relationship,:priority=>200,
      :description=>'城都三條御三家進化線共同出戰。隊伍更耐久，也更容易維持續戰。',
      :composition=>[
        {:type=>:line,:key=>:chikorita_line},{:type=>:line,:key=>:cyndaquil_line},
        {:type=>:line,:key=>:totodile_line}],
      :effects=>[
        {:type=>:damage_in_mult,:mult=>0.95,:scope=>:team},
        {:type=>:healing_mult,:mult=>1.05,:scope=>:team}]
    },
    :hoenn_starter_trio=>{
      :name=>'豐緣御三家',:category=>:relationship,:priority=>200,
      :description=>'豐緣三條御三家進化線共同出戰。全隊提高輸出與戰場機動力。',
      :composition=>[
        {:type=>:line,:key=>:treecko_line},{:type=>:line,:key=>:torchic_line},
        {:type=>:line,:key=>:mudkip_line}],
      :effects=>[
        {:type=>:damage_out_mult,:mult=>1.04,:scope=>:team},
        {:type=>:move_speed_mult,:mult=>1.05,:scope=>:team}]
    },
    :sinnoh_starter_trio=>{
      :name=>'神奧御三家',:category=>:relationship,:priority=>200,
      :description=>'神奧三條御三家進化線共同出戰。全隊更快累積 Energy，並縮短負面狀態時間。',
      :composition=>[
        {:type=>:line,:key=>:turtwig_line},{:type=>:line,:key=>:chimchar_line},
        {:type=>:line,:key=>:piplup_line}],
      :effects=>[
        {:type=>:energy_gain_mult,:mult=>1.08,:scope=>:team},
        {:type=>:status_duration_mult,:mult=>0.90,:scope=>:team}]
    },

    #------------------------------------------------------------------------
    # 關係羈絆：傳說／幻之組合
    #------------------------------------------------------------------------
    :legendary_birds=>{
      :name=>'傳說三鳥',:category=>:relationship,:priority=>205,
      :description=>'急凍鳥、閃電鳥、火焰鳥共同出戰。全隊提高機動並獲得少量開場 Energy。',
      :composition=>[
        {:type=>:species,:key=>:articuno},{:type=>:species,:key=>:zapdos},{:type=>:species,:key=>:moltres}],
      :effects=>[
        {:type=>:move_speed_mult,:mult=>1.05,:scope=>:team},
        {:type=>:initial_energy,:amount=>6,:scope=>:team,:once=>true}]
    },
    :legendary_beasts=>{
      :name=>'三聖獸',:category=>:relationship,:priority=>205,
      :description=>'雷公、炎帝、水君共同出戰。全隊移動與 Energy 循環同步加快。',
      :composition=>[
        {:type=>:species,:key=>:raikou},{:type=>:species,:key=>:entei},{:type=>:species,:key=>:suicune}],
      :effects=>[
        {:type=>:move_speed_mult,:mult=>1.05,:scope=>:team},
        {:type=>:energy_gain_mult,:mult=>1.05,:scope=>:team}]
    },
    :regi_trio=>{
      :name=>'三神柱',:category=>:relationship,:priority=>205,
      :description=>'雷吉洛克、雷吉艾斯、雷吉斯奇魯共同出戰。全隊承傷下降並縮短負面狀態。',
      :composition=>[
        {:type=>:species,:key=>:regirock},{:type=>:species,:key=>:regice},{:type=>:species,:key=>:registeel}],
      :effects=>[
        {:type=>:damage_in_mult,:mult=>0.94,:scope=>:team},
        {:type=>:status_duration_mult,:mult=>0.85,:scope=>:team}]
    },
    :lake_guardians=>{
      :name=>'湖之三神',:category=>:relationship,:priority=>205,
      :description=>'由克希、艾姆利多、亞克諾姆共同出戰。全隊 Energy 循環更快並提高狀態韌性。',
      :composition=>[
        {:type=>:species,:key=>:uxie},{:type=>:species,:key=>:mesprit},{:type=>:species,:key=>:azelf}],
      :effects=>[
        {:type=>:energy_gain_mult,:mult=>1.08,:scope=>:team},
        {:type=>:status_duration_mult,:mult=>0.90,:scope=>:team}]
    },
    :creation_trio=>{
      :name=>'創世三龍',:category=>:relationship,:priority=>215,
      :description=>'帝牙盧卡、帕路奇亞、騎拉帝納共同出戰。全隊同時提高攻守效率。',
      :composition=>[
        {:type=>:species,:key=>:dialga},{:type=>:species,:key=>:palkia},{:type=>:species,:key=>:giratina}],
      :effects=>[
        {:type=>:damage_out_mult,:mult=>1.04,:scope=>:team},
        {:type=>:damage_in_mult,:mult=>0.96,:scope=>:team}]
    },
    :weather_trio=>{
      :name=>'豐緣三神',:category=>:relationship,:priority=>215,
      :description=>'固拉多、蓋歐卡、烈空坐共同出戰。全隊取得開場 Energy 並提高狀態韌性。',
      :composition=>[
        {:type=>:species,:key=>:groudon},{:type=>:species,:key=>:kyogre},{:type=>:species,:key=>:rayquaza}],
      :effects=>[
        {:type=>:initial_energy,:amount=>8,:scope=>:team,:once=>true},
        {:type=>:status_duration_mult,:mult=>0.90,:scope=>:team}]
    },
    :tower_duo=>{
      :name=>'海空雙塔',:category=>:relationship,:priority=>130,
      :description=>'洛奇亞與鳳王共同出戰。隊伍治療效率提升，並略微降低承受傷害。',
      :composition=>[{:type=>:species,:key=>:lugia},{:type=>:species,:key=>:ho_oh}],
      :effects=>[
        {:type=>:healing_mult,:mult=>1.08,:scope=>:team},
        {:type=>:damage_in_mult,:mult=>0.97,:scope=>:team}]
    },
    :eon_duo=>{
      :name=>'水都雙子',:category=>:relationship,:priority=>130,
      :description=>'拉帝亞斯與拉帝歐斯共同出戰。全隊提高移動速度與特殊傷害。',
      :composition=>[{:type=>:species,:key=>:latias},{:type=>:species,:key=>:latios}],
      :effects=>[
        {:type=>:move_speed_mult,:mult=>1.05,:scope=>:team},
        {:type=>:special_damage_mult,:mult=>1.04,:scope=>:team}]
    },
    :lunar_nightmare=>{
      :name=>'夢與惡夢',:category=>:relationship,:priority=>135,
      :description=>'克雷色利亞與達克萊伊共同出戰。全隊縮短負面狀態時間並提高特殊傷害。',
      :composition=>[{:type=>:species,:key=>:cresselia},{:type=>:species,:key=>:darkrai}],
      :effects=>[
        {:type=>:status_duration_mult,:mult=>0.88,:scope=>:team},
        {:type=>:special_damage_mult,:mult=>1.04,:scope=>:team}]
    },
    :origin_clone=>{
      :name=>'始源與人造',:category=>:relationship,:priority=>140,
      :description=>'夢幻與超夢共同出戰。全隊開場 Energy 與後續 Energy 循環同步提升。',
      :composition=>[{:type=>:species,:key=>:mew},{:type=>:species,:key=>:mewtwo}],
      :effects=>[
        {:type=>:initial_energy,:amount=>5,:scope=>:team,:once=>true},
        {:type=>:energy_gain_mult,:mult=>1.06,:scope=>:team}]
    },
    :sea_royalty=>{
      :name=>'海之王族',:category=>:relationship,:priority=>125,
      :description=>'瑪納霏與霏歐納共同出戰。全隊治療效果提高。',
      :composition=>[{:type=>:species,:key=>:manaphy},{:type=>:species,:key=>:phione}],
      :effects=>[{:type=>:healing_mult,:mult=>1.10,:scope=>:team}]
    },
    :regigigas_seals=>{
      :name=>'巨人與封印',:category=>:relationship,:priority=>220,
      :description=>'雷吉奇卡斯與三神柱中的任兩隻共同出戰。全隊開場獲得護盾並大幅提高狀態韌性。',
      :composition=>[
        {:type=>:species,:key=>:regigigas},
        {:type=>:species_pool,:keys=>[:regirock,:regice,:registeel],:count=>2,:unique=>true}],
      :effects=>[
        {:type=>:start_shield,:ratio=>0.06,:scope=>:team,:once=>true},
        {:type=>:status_duration_mult,:mult=>0.85,:scope=>:team}]
    },

    #------------------------------------------------------------------------
    # 關係羈絆：進化分支、搭檔、宿敵與化石群
    #------------------------------------------------------------------------
    :tyrogue_trio=>{
      :name=>'格鬥三傑',:category=>:relationship,:priority=>205,
      :description=>'飛腿郎、快拳郎、戰舞郎共同出戰。近戰傷害與機動力同步提高。',
      :composition=>[
        {:type=>:species,:key=>:hitmonlee},{:type=>:species,:key=>:hitmonchan},{:type=>:species,:key=>:hitmontop}],
      :effects=>[
        {:type=>:contact_damage_mult,:mult=>1.06,:scope=>:team},
        {:type=>:move_speed_mult,:mult=>1.04,:scope=>:team}]
    },
    :eevee_prismatic=>{
      :name=>'七色進化',:category=>:relationship,:priority=>210,
      :description=>'七種伊布進化型中任選三種不同成員共同出戰。各自本系傷害與 Energy 循環提高。',
      :composition=>[
        {:type=>:species_pool,
         :keys=>[:vaporeon,:jolteon,:flareon,:espeon,:umbreon,:leafeon,:glaceon],
         :count=>3,:unique=>true}],
      :effects=>[
        {:type=>:type_damage_mult,:move_type=>:own,:mult=>1.06,:scope=>:team},
        {:type=>:energy_gain_mult,:mult=>1.04,:scope=>:team}]
    },
    :sun_moon_resonance=>{
      :name=>'日月共鳴',:category=>:relationship,:priority=>120,
      :description=>'太陽伊布與月亮伊布共同出戰。全隊 Energy 循環提高並縮短負面狀態時間。',
      :composition=>[{:type=>:species,:key=>:espeon},{:type=>:species,:key=>:umbreon}],
      :effects=>[
        {:type=>:energy_gain_mult,:mult=>1.05,:scope=>:team},
        {:type=>:status_duration_mult,:mult=>0.90,:scope=>:team}]
    },
    :plus_minus_pair=>{
      :name=>'正負電極',:category=>:relationship,:priority=>120,
      :description=>'正電拍拍與負電拍拍共同出戰。全隊獲得開場 Energy 並提高 Energy 取得效率。',
      :composition=>[{:type=>:species,:key=>:plusle},{:type=>:species,:key=>:minun}],
      :effects=>[
        {:type=>:initial_energy,:amount=>6,:scope=>:team,:once=>true},
        {:type=>:energy_gain_mult,:mult=>1.06,:scope=>:team}]
    },
    :sun_moon_stones=>{
      :name=>'日月石',:category=>:relationship,:priority=>120,
      :description=>'太陽岩與月石共同出戰。全隊特殊傷害提高並縮短負面狀態時間。',
      :composition=>[{:type=>:species,:key=>:solrock},{:type=>:species,:key=>:lunatone}],
      :effects=>[
        {:type=>:special_damage_mult,:mult=>1.05,:scope=>:team},
        {:type=>:status_duration_mult,:mult=>0.90,:scope=>:team}]
    },
    :poison_royalty=>{
      :name=>'王與后',:category=>:relationship,:priority=>125,
      :description=>'尼多王系與尼多后系共同出戰。全隊毒屬性與持續傷害提高。',
      :composition=>[
        {:type=>:line,:key=>:nidoran_m_line},{:type=>:line,:key=>:nidoran_f_line}],
      :effects=>[
        {:type=>:type_damage_mult,:move_type=>:poison,:mult=>1.06,:scope=>:team},
        {:type=>:indirect_damage_mult,:mult=>1.08,:scope=>:team}]
    },
    :blade_and_guardian=>{
      :name=>'劍與盾之心',:category=>:relationship,:priority=>125,
      :description=>'沙奈朵與艾路雷朵共同出戰。沙奈朵提高特殊傷害，艾路雷朵提高物理傷害。',
      :composition=>[{:type=>:species,:key=>:gardevoir},{:type=>:species,:key=>:gallade}],
      :effects=>[
        {:type=>:special_damage_mult,:mult=>1.06,:scope=>{:species=>:gardevoir}},
        {:type=>:physical_damage_mult,:mult=>1.06,:scope=>{:species=>:gallade}}]
    },
    :ice_duality=>{
      :name=>'冰之雙貌',:category=>:relationship,:priority=>120,
      :description=>'冰鬼護與雪妖女共同出戰。全隊冰屬性傷害提高並略微縮短負面狀態。',
      :composition=>[{:type=>:species,:key=>:glalie},{:type=>:species,:key=>:froslass}],
      :effects=>[
        {:type=>:type_damage_mult,:move_type=>:ice,:mult=>1.06,:scope=>:team},
        {:type=>:status_duration_mult,:mult=>0.92,:scope=>:team}]
    },
    :deepsea_branch=>{
      :name=>'深海分歧',:category=>:relationship,:priority=>120,
      :description=>'獵斑魚與櫻花魚共同出戰。全隊水屬性傷害與移動速度提高。',
      :composition=>[{:type=>:species,:key=>:huntail},{:type=>:species,:key=>:gorebyss}],
      :effects=>[
        {:type=>:type_damage_mult,:move_type=>:water,:mult=>1.06,:scope=>:team},
        {:type=>:move_speed_mult,:mult=>1.04,:scope=>:team}]
    },
    :one_shell_twins=>{
      :name=>'一殼雙生',:category=>:relationship,:priority=>120,
      :description=>'鐵面忍者與脫殼忍者共同出戰。全隊取得開場 Energy 並提高機動力。',
      :composition=>[{:type=>:species,:key=>:ninjask},{:type=>:species,:key=>:shedinja}],
      :effects=>[
        {:type=>:initial_energy,:amount=>8,:scope=>:team,:once=>true},
        {:type=>:move_speed_mult,:mult=>1.04,:scope=>:team}]
    },
    :firefly_pair=>{
      :name=>'螢火雙星',:category=>:relationship,:priority=>115,
      :description=>'電螢蟲與甜甜螢共同出戰。全隊提高機動與治療效率。',
      :composition=>[{:type=>:species,:key=>:volbeat},{:type=>:species,:key=>:illumise}],
      :effects=>[
        {:type=>:move_speed_mult,:mult=>1.05,:scope=>:team},
        {:type=>:healing_mult,:mult=>1.05,:scope=>:team}]
    },
    :rivals_united=>{
      :name=>'宿敵共鬥',:category=>:relationship,:priority=>125,
      :description=>'貓鼬斬與飯匙蛇暫時並肩作戰。全隊輸出顯著提高，但承受傷害也略微增加。',
      :composition=>[{:type=>:species,:key=>:zangoose},{:type=>:species,:key=>:seviper}],
      :effects=>[
        {:type=>:damage_out_mult,:mult=>1.08,:scope=>:team},
        {:type=>:damage_in_mult,:mult=>1.03,:scope=>:team}]
    },
    :kanto_fossils=>{
      :name=>'關都化石群',:category=>:relationship,:priority=>195,
      :description=>'菊石獸系、化石盔系、化石翼龍系共同出戰。全隊承傷下降並提高狀態韌性。',
      :composition=>[
        {:type=>:line,:key=>:omanyte_line},{:type=>:line,:key=>:kabuto_line},{:type=>:line,:key=>:aerodactyl_line}],
      :effects=>[
        {:type=>:damage_in_mult,:mult=>0.95,:scope=>:team},
        {:type=>:status_duration_mult,:mult=>0.90,:scope=>:team}]
    },
    :hoenn_fossils=>{
      :name=>'豐緣化石',:category=>:relationship,:priority=>115,
      :description=>'觸手百合系與太古羽蟲系共同出戰。全隊承傷下降並提高物理傷害。',
      :composition=>[{:type=>:line,:key=>:lileep_line},{:type=>:line,:key=>:anorith_line}],
      :effects=>[
        {:type=>:damage_in_mult,:mult=>0.96,:scope=>:team},
        {:type=>:physical_damage_mult,:mult=>1.03,:scope=>:team}]
    },
    :sinnoh_fossils=>{
      :name=>'神奧化石',:category=>:relationship,:priority=>115,
      :description=>'頭蓋龍系與盾甲龍系共同出戰。全隊提高物理傷害並降低承受傷害。',
      :composition=>[{:type=>:line,:key=>:cranidos_line},{:type=>:line,:key=>:shieldon_line}],
      :effects=>[
        {:type=>:physical_damage_mult,:mult=>1.04,:scope=>:team},
        {:type=>:damage_in_mult,:mult=>0.96,:scope=>:team}]
    },
    :deepsea_key=>{
      :name=>'深海密鑰',:category=>:relationship,:priority=>120,
      :description=>'吼鯨王與古空棘魚共同出戰。全隊承傷下降並提高狀態韌性。',
      :composition=>[{:type=>:species,:key=>:wailord},{:type=>:species,:key=>:relicanth}],
      :effects=>[
        {:type=>:damage_in_mult,:mult=>0.96,:scope=>:team},
        {:type=>:status_duration_mult,:mult=>0.90,:scope=>:team}]
    },
    :swim_partners=>{
      :name=>'共游夥伴',:category=>:relationship,:priority=>115,
      :description=>'巨翅飛魚系與鐵炮魚系共同出戰。全隊遠程傷害與治療效率提高。',
      :composition=>[{:type=>:line,:key=>:mantyke_line},{:type=>:line,:key=>:remoraid_line}],
      :effects=>[
        {:type=>:ranged_damage_mult,:mult=>1.04,:scope=>:team},
        {:type=>:healing_mult,:mult=>1.06,:scope=>:team}]
    },
    :electric_fire_duo=>{
      :name=>'電火雙核',:category=>:relationship,:priority=>125,
      :description=>'電擊魔獸與鴨嘴炎獸共同出戰。各自強化擅長輸出，全隊 Energy 循環也略微提高。',
      :composition=>[{:type=>:species,:key=>:electivire},{:type=>:species,:key=>:magmortar}],
      :effects=>[
        {:type=>:physical_damage_mult,:mult=>1.04,:scope=>{:species=>:electivire}},
        {:type=>:special_damage_mult,:mult=>1.04,:scope=>{:species=>:magmortar}},
        {:type=>:energy_gain_mult,:mult=>1.04,:scope=>:team}]
    },

    #------------------------------------------------------------------------
    # 戰術羈絆：依三隻正式出戰 Pokémon 的 role_tags 判定
    #------------------------------------------------------------------------
    :tactical_fortress_battery=>{
      :name=>'堡壘砲台',:category=>:tactical,:priority=>170,
      :description=>'隊伍同時具備 Bodyguard、Artillery 與 Frontline/Tank。前線穩固，遠程輸出提高。',
      :condition=>{
        :required_roles=>{:bodyguard=>1,:artillery=>1},
        :required_role_pools=>[{:roles=>[:frontline,:tank],:count=>1}]},
      :effects=>[
        {:type=>:damage_in_mult,:mult=>0.97,:scope=>:team},
        {:type=>:ranged_damage_mult,:mult=>1.05,:scope=>:team}]
    },
    :tactical_hunt_chain=>{
      :name=>'獵殺鏈',:category=>:tactical,:priority=>155,
      :description=>'隊伍同時具備 Assassin、Controller、Bruiser。控制與追擊形成連續獵殺節奏。',
      :condition=>{:required_roles=>{:assassin=>1,:controller=>1,:bruiser=>1}},
      :effects=>[
        {:type=>:damage_out_mult,:mult=>1.04,:scope=>:team},
        {:type=>:energy_gain_mult,:mult=>1.05,:scope=>:team}]
    },
    :tactical_mobile_pincer=>{
      :name=>'機動包夾',:category=>:tactical,:priority=>150,
      :description=>'隊伍同時具備 Kiter、Assassin、Controller。機動包抄讓全隊更快移動與循環技能。',
      :condition=>{:required_roles=>{:kiter=>1,:assassin=>1,:controller=>1}},
      :effects=>[
        {:type=>:move_speed_mult,:mult=>1.05,:scope=>:team},
        {:type=>:energy_gain_mult,:mult=>1.04,:scope=>:team}]
    },
    :tactical_ranged_net=>{
      :name=>'遠程火網',:category=>:tactical,:priority=>140,
      :description=>'隊伍至少有兩名 Ranged，並具備 Controller。遠程火力得到更好的控制掩護。',
      :condition=>{:required_roles=>{:ranged=>2,:controller=>1}},
      :effects=>[{:type=>:ranged_damage_mult,:mult=>1.05,:scope=>:team}]
    },
    :tactical_melee_charge=>{
      :name=>'近衛衝陣',:category=>:tactical,:priority=>140,
      :description=>'隊伍至少有兩名 Melee，並具備 Frontline。近戰接觸傷害與推進速度提高。',
      :condition=>{:required_roles=>{:melee=>2,:frontline=>1}},
      :effects=>[
        {:type=>:contact_damage_mult,:mult=>1.05,:scope=>:team},
        {:type=>:move_speed_mult,:mult=>1.03,:scope=>:team}]
    },
    :tactical_long_campaign=>{
      :name=>'長線作戰',:category=>:tactical,:priority=>130,
      :description=>'隊伍具備 Tank、Ranged，並至少有 Sustain/Support/Controller。適合長時間消耗戰。',
      :condition=>{
        :required_roles=>{:tank=>1,:ranged=>1},
        :required_role_pools=>[{:roles=>[:sustain,:support,:controller],:count=>1}]},
      :effects=>[
        {:type=>:healing_mult,:mult=>1.08,:scope=>:team},
        {:type=>:status_duration_mult,:mult=>0.92,:scope=>:team}]
    },
    :tactical_watch_line=>{
      :name=>'守望陣線',:category=>:tactical,:priority=>125,
      :description=>'隊伍具備 Bodyguard、Frontline/Tank 與 Sustain/Support/Controller。全隊更能承受長時間壓力。',
      :condition=>{
        :required_roles=>{:bodyguard=>1},
        :required_role_pools=>[
          {:roles=>[:frontline,:tank],:count=>1},
          {:roles=>[:sustain,:support,:controller],:count=>1}]},
      :effects=>[
        {:type=>:damage_in_mult,:mult=>0.96,:scope=>:team},
        {:type=>:healing_mult,:mult=>1.06,:scope=>:team}]
    },
    :tactical_triangle=>{
      :name=>'三角陣型',:category=>:tactical,:priority=>110,
      :description=>'隊伍同時具備 Frontline、Ranged、Assassin。三種站位互補，獲得少量開場 Energy 與防護。',
      :condition=>{:required_roles=>{:frontline=>1,:ranged=>1,:assassin=>1}},
      :effects=>[
        {:type=>:initial_energy,:amount=>5,:scope=>:team,:once=>true},
        {:type=>:damage_in_mult,:mult=>0.98,:scope=>:team}]
    }
  }

  TEAM_BOND_MANIFEST_V0992={
    :version=>'0.99.2',:relationship_count=>34,:tactical_count=>8,:total_count=>42,
    :party_size=>3,:relationship_limit=>1,:tactical_limit=>1,
    :summon_counts=>false,:actor_id_identity=>false,:faint_persists=>true,
    :form_refresh=>true,:legacy_v015_kanto_carried=>true,
    :rpg_persistent_design=>true,:roguelike_run_bonus=>false
  }

  class << self
    def team_bond_data_v0992(key)
      TEAM_BOND_DATA_V0992[key]
    end
    def team_bond_name_v0992(key)
      data=TEAM_BOND_DATA_V0992[key]
      data==nil ? key.to_s : (data[:name] || key.to_s)
    end
  end
end
