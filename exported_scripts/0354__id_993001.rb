# encoding: UTF-8
#==============================================================================
# 【PMD AutoChess 中文維護說明】
# 腳本：PMD AutoChess Team Bond Content Expansion v0.99.3
# 分類：隊伍羈絆／正式內容擴張／RPG 發現資料
#
# 【用途】
# 1. 延續 v0.99.2 已驗證通過的 Team Bond Runtime，不修改 Damage / Energy /
#    Heal / Move Speed / Status 等效果入口。
# 2. 將正式羈絆由 42 組擴張為 81 組：73 Relationship + 8 Tactical。
# 3. 每條羈絆的名稱、組成、效果、設計依據、發現等級、提示與隱藏規則都寫在腳本。
# 4. 提供未來 RPG「羈絆圖鑑／隊伍編成／劇情 Boss」共用的唯一資料來源。
#
# 【正式內容上限】
# - Relationship：73
# - Tactical：8
# - Total：81
# 此 81 組視為正式內容上限。日後只有劇情或世界觀真的產生值得加入的新組合時才破例增加，
# 不為了數量製造「同屬性三隻」之類泛用 Tag Bonus。
#
# 【Basis：羈絆設計依據】
# :canonical_group     原作明確集團／神話關係
# :evolution_relation  分歧進化／親緣關係
# :counterpart         明確的對照、搭檔或宿敵
# :shared_mechanic     共同進化方式／特殊機制
# :ecology_theme       合理生態／棲地／主題組合
# :collection_theme    收集型特殊組合
# :legendary_myth      傳說／幻之寶可夢世界觀組合
# :tactical_role       戰術 Role 組合（8 個 Tactical 專用）
#
# 【Discovery Rank】
# :normal  一開始即可顯示名稱／組成／效果。
# :rare    未發現前可顯示名稱與 hint，但組成與效果可隱藏。
# :secret  未發現前名稱可顯示為「???」，只留下模糊 hint。
# :tactical Tactical Bond 固定公開，不參與神秘發現稀有度。
# Rank 只代表「發現難度」，絕對不代表戰鬥強度。
#
# 【新增 39 Relationship】
# 35 花開兩路 ～ 73 巔峰血脈。舊 34 Relationship 與 8 Tactical 完整保留。
# v0.99.2 TEAM_BOND_DATA_V0992 會在載入本腳本時加入新資料與 discovery metadata，
# 讓舊 Runtime 不需要重寫即可直接使用 81 組羈絆。
#
# 【調整方式】
# - 改名稱／組成／效果：修改 TEAM_BOND_EXPANSION_DATA_V0993。
# - 改舊羈絆的 basis／rank／hint：修改 TEAM_BOND_LEGACY_METADATA_V0993。
# - 改 Tactical 公開提示：修改 TEAM_BOND_TACTICAL_METADATA_V0993。
# - 不要在 Runtime 複製第二份數值。
#
# 【事件／腳本查詢範例】
# PMD_AC.team_bond_data_v0993(:mimic_trinity)
# PMD_AC.team_bond_hint_v0993(:creation_myth)
# PMD_AC.team_bond_discovery_rank_v0993(:fossil_museum)
#
# 【維護注意】
# - RPG Maker VX / RGSS2 / Ruby 1.8 相容。
# - 不使用 Actor ID 作為寶可夢身份。
# - Summon 仍由 v0.99.2 Runtime 排除。
# - 不新增 Effect Type；全部沿用 v0.99.2 已驗證效果。
# - 不修改 Ability 1193/1193、Move 526/526、AI、Loot、Held Item、Movement。
#==============================================================================
module PMD_AC
  TEAM_BOND_CONTENT_VERSION_V0993='0.99.3'
  TEAM_BOND_BASIS_TYPES_V0993=[
    :canonical_group,:evolution_relation,:counterpart,:shared_mechanic,
    :ecology_theme,:collection_theme,:legendary_myth,:tactical_role
  ]
  TEAM_BOND_DISCOVERY_RANKS_V0993=[:normal,:rare,:secret,:tactical]

  #--------------------------------------------------------------------------
  # v0.99.2 既有 34 Relationship 的 RPG 發現資料
  # 配額：Normal 20 / Rare 10 / Secret 4
  #--------------------------------------------------------------------------
  TEAM_BOND_LEGACY_METADATA_V0993={
    :kanto_starter_trio=>{:basis=>:canonical_group,:discovery_rank=>:normal,:hidden_until_discovered=>false,:hint=>'來自關都的三位最初夥伴。'},
    :johto_starter_trio=>{:basis=>:canonical_group,:discovery_rank=>:normal,:hidden_until_discovered=>false,:hint=>'城都旅程開始時的三條道路。'},
    :hoenn_starter_trio=>{:basis=>:canonical_group,:discovery_rank=>:normal,:hidden_until_discovered=>false,:hint=>'豐緣冒險最初的草、火與水。'},
    :sinnoh_starter_trio=>{:basis=>:canonical_group,:discovery_rank=>:normal,:hidden_until_discovered=>false,:hint=>'神奧地區並肩成長的三位最初夥伴。'},
    :legendary_birds=>{:basis=>:canonical_group,:discovery_rank=>:rare,:hidden_until_discovered=>false,:hint=>'冰、雷與火的三道天空之翼。'},
    :legendary_beasts=>{:basis=>:legendary_myth,:discovery_rank=>:rare,:hidden_until_discovered=>false,:hint=>'從燒毀之塔傳說中奔出的三道身影。'},
    :regi_trio=>{:basis=>:legendary_myth,:discovery_rank=>:rare,:hidden_until_discovered=>false,:hint=>'岩、冰與鋼封存著古老巨人的力量。'},
    :lake_guardians=>{:basis=>:legendary_myth,:discovery_rank=>:rare,:hidden_until_discovered=>false,:hint=>'知識、情感與意志守望著神奧三湖。'},
    :creation_trio=>{:basis=>:legendary_myth,:discovery_rank=>:secret,:hidden_until_discovered=>true,:hint=>'時間、空間與反轉世界的力量若同時甦醒……'},
    :weather_trio=>{:basis=>:legendary_myth,:discovery_rank=>:secret,:hidden_until_discovered=>true,:hint=>'大地、海洋與天空曾決定豐緣世界的命運。'},
    :tower_duo=>{:basis=>:legendary_myth,:discovery_rank=>:rare,:hidden_until_discovered=>false,:hint=>'海之守護者與虹色之翼遙望不同的高塔。'},
    :eon_duo=>{:basis=>:canonical_group,:discovery_rank=>:normal,:hidden_until_discovered=>false,:hint=>'紅與藍的水都雙子。'},
    :lunar_nightmare=>{:basis=>:legendary_myth,:discovery_rank=>:rare,:hidden_until_discovered=>false,:hint=>'美夢與惡夢在同一片夜色中交會。'},
    :origin_clone=>{:basis=>:legendary_myth,:discovery_rank=>:secret,:hidden_until_discovered=>true,:hint=>'最初的基因，與由它誕生的人造生命。'},
    :sea_royalty=>{:basis=>:legendary_myth,:discovery_rank=>:normal,:hidden_until_discovered=>false,:hint=>'深海中的王族血脈彼此呼應。'},
    :regigigas_seals=>{:basis=>:legendary_myth,:discovery_rank=>:secret,:hidden_until_discovered=>true,:hint=>'沉睡的巨人似乎仍在等待古老封印回到身旁。'},
    :tyrogue_trio=>{:basis=>:evolution_relation,:discovery_rank=>:normal,:hidden_until_discovered=>false,:hint=>'同一位幼小格鬥家走向三條不同道路。'},
    :eevee_prismatic=>{:basis=>:evolution_relation,:discovery_rank=>:rare,:hidden_until_discovered=>false,:hint=>'七種不同進化，任三種色彩也能彼此共鳴。'},
    :sun_moon_resonance=>{:basis=>:evolution_relation,:discovery_rank=>:normal,:hidden_until_discovered=>false,:hint=>'白晝與黑夜孕育出的兩種伊布進化。'},
    :plus_minus_pair=>{:basis=>:counterpart,:discovery_rank=>:normal,:hidden_until_discovered=>false,:hint=>'正與負本來就適合成對。'},
    :sun_moon_stones=>{:basis=>:counterpart,:discovery_rank=>:normal,:hidden_until_discovered=>false,:hint=>'白晝的太陽與夜晚的月亮彼此映照。'},
    :poison_royalty=>{:basis=>:counterpart,:discovery_rank=>:normal,:hidden_until_discovered=>false,:hint=>'毒之王與毒之后共同守住前線。'},
    :blade_and_guardian=>{:basis=>:evolution_relation,:discovery_rank=>:normal,:hidden_until_discovered=>false,:hint=>'同一條血脈分成守護與劍刃。'},
    :ice_duality=>{:basis=>:evolution_relation,:discovery_rank=>:normal,:hidden_until_discovered=>false,:hint=>'冰冷面孔可以走向兩種截然不同的終點。'},
    :deepsea_branch=>{:basis=>:evolution_relation,:discovery_rank=>:normal,:hidden_until_discovered=>false,:hint=>'深海之牙與深海之美源自同一條進化支流。'},
    :one_shell_twins=>{:basis=>:evolution_relation,:discovery_rank=>:rare,:hidden_until_discovered=>false,:hint=>'一次進化，留下速度與空殼兩道生命。'},
    :firefly_pair=>{:basis=>:counterpart,:discovery_rank=>:normal,:hidden_until_discovered=>false,:hint=>'夜色中的兩點螢光彼此呼應。'},
    :rivals_united=>{:basis=>:counterpart,:discovery_rank=>:normal,:hidden_until_discovered=>false,:hint=>'天生宿敵若暫時停戰，攻勢反而更加兇猛。'},
    :kanto_fossils=>{:basis=>:collection_theme,:discovery_rank=>:rare,:hidden_until_discovered=>false,:hint=>'關都復甦的三種古代生命。'},
    :hoenn_fossils=>{:basis=>:evolution_relation,:discovery_rank=>:normal,:hidden_until_discovered=>false,:hint=>'豐緣兩枚化石各自復甦的生命。'},
    :sinnoh_fossils=>{:basis=>:evolution_relation,:discovery_rank=>:normal,:hidden_until_discovered=>false,:hint=>'神奧兩種古代生命，一攻一守。'},
    :deepsea_key=>{:basis=>:ecology_theme,:discovery_rank=>:rare,:hidden_until_discovered=>false,:hint=>'古老傳說曾要求兩種深海生命同時出現。'},
    :swim_partners=>{:basis=>:ecology_theme,:discovery_rank=>:normal,:hidden_until_discovered=>false,:hint=>'巨大的海翼經常與小型魚群一同游動。'},
    :electric_fire_duo=>{:basis=>:counterpart,:discovery_rank=>:normal,:hidden_until_discovered=>false,:hint=>'電流與烈焰的兩位力量型進化者。'}
  }

  #--------------------------------------------------------------------------
  # 8 Tactical：全部公開，不使用 Rare / Secret 發現隱藏
  #--------------------------------------------------------------------------
  TEAM_BOND_TACTICAL_METADATA_V0993={
    :tactical_fortress_battery=>{:basis=>:tactical_role,:discovery_rank=>:tactical,:hidden_until_discovered=>false,:hint=>'穩固前線保護遠程砲台。'},
    :tactical_hunt_chain=>{:basis=>:tactical_role,:discovery_rank=>:tactical,:hidden_until_discovered=>false,:hint=>'控制、追擊與收割形成連續獵殺。'},
    :tactical_mobile_pincer=>{:basis=>:tactical_role,:discovery_rank=>:tactical,:hidden_until_discovered=>false,:hint=>'用高機動從不同角度夾擊敵人。'},
    :tactical_ranged_net=>{:basis=>:tactical_role,:discovery_rank=>:tactical,:hidden_until_discovered=>false,:hint=>'控制手為多名遠程輸出製造安全火網。'},
    :tactical_melee_charge=>{:basis=>:tactical_role,:discovery_rank=>:tactical,:hidden_until_discovered=>false,:hint=>'前線帶領近戰單位共同壓進。'},
    :tactical_long_campaign=>{:basis=>:tactical_role,:discovery_rank=>:tactical,:hidden_until_discovered=>false,:hint=>'防守、遠程與續航共同支撐長時間作戰。'},
    :tactical_watch_line=>{:basis=>:tactical_role,:discovery_rank=>:tactical,:hidden_until_discovered=>false,:hint=>'護衛與前線共同照看隊伍的續戰核心。'},
    :tactical_triangle=>{:basis=>:tactical_role,:discovery_rank=>:tactical,:hidden_until_discovered=>false,:hint=>'前線、遠程與刺客形成互補的三角結構。'}
  }

  #--------------------------------------------------------------------------
  # 新增 39 Relationship：35～73
  # 配額：Normal 13 / Rare 18 / Secret 8
  #--------------------------------------------------------------------------
  TEAM_BOND_EXPANSION_DATA_V0993={
    :flower_split=>{
      :name=>'花開兩路',:category=>:relationship,:priority=>130,
      :basis=>:evolution_relation,:discovery_rank=>:normal,:hidden_until_discovered=>false,
      :hint=>'同一朵臭臭花，能朝截然不同的花朵盛開。',
      :description=>'霸王花與美麗花共同出戰。分歧進化的共鳴提高全隊治療效率。',
      :composition=>[{:type=>:species,:key=>:vileplume},{:type=>:species,:key=>:bellossom}],
      :effects=>[{:type=>:healing_mult,:mult=>1.06,:scope=>:team}]
    },
    :royal_branch=>{
      :name=>'雙王之路',:category=>:relationship,:priority=>130,
      :basis=>:evolution_relation,:discovery_rank=>:normal,:hidden_until_discovered=>false,
      :hint=>'同一條水中血脈，能走向拳腳或王冠。',
      :description=>'蚊香泳士與牛蛙君共同出戰。物理壓力與治療循環同時提高。',
      :composition=>[{:type=>:species,:key=>:poliwrath},{:type=>:species,:key=>:politoed}],
      :effects=>[{:type=>:physical_damage_mult,:mult=>1.04,:scope=>:team},{:type=>:healing_mult,:mult=>1.04,:scope=>:team}]
    },
    :crown_branch=>{
      :name=>'王冠分流',:category=>:relationship,:priority=>130,
      :basis=>:evolution_relation,:discovery_rank=>:normal,:hidden_until_discovered=>false,
      :hint=>'被大舌貝咬住的位置不同，通往的終點也不同。',
      :description=>'呆殼獸與呆呆王共同出戰。全隊降低承傷並提高特殊傷害。',
      :composition=>[{:type=>:species,:key=>:slowbro},{:type=>:species,:key=>:slowking}],
      :effects=>[{:type=>:damage_in_mult,:mult=>0.96,:scope=>:team},{:type=>:special_damage_mult,:mult=>1.04,:scope=>:team}]
    },
    :moth_branch=>{
      :name=>'蝶蛾分岔',:category=>:relationship,:priority=>125,
      :basis=>:evolution_relation,:discovery_rank=>:normal,:hidden_until_discovered=>false,
      :hint=>'同一種幼蟲能走向華麗蝶翼，也能披上夜色毒粉。',
      :description=>'狩獵鳳蝶與毒粉蛾共同出戰。全隊提高移速並縮短負面狀態時間。',
      :composition=>[{:type=>:species,:key=>:beautifly},{:type=>:species,:key=>:dustox}],
      :effects=>[{:type=>:move_speed_mult,:mult=>1.04,:scope=>:team},{:type=>:status_duration_mult,:mult=>0.94,:scope=>:team}]
    },
    :burmy_branch=>{
      :name=>'蟲衣兩相',:category=>:relationship,:priority=>125,
      :basis=>:evolution_relation,:discovery_rank=>:rare,:hidden_until_discovered=>false,
      :hint=>'相同的結草兒，性別讓成年形態走向完全不同的方向。',
      :description=>'結草貴婦與紳士蛾共同出戰。全隊降低承傷並提高遠程傷害。',
      :composition=>[{:type=>:species,:key=>:wormadam},{:type=>:species,:key=>:mothim}],
      :effects=>[{:type=>:damage_in_mult,:mult=>0.96,:scope=>:team},{:type=>:ranged_damage_mult,:mult=>1.04,:scope=>:team}]
    },
    :metal_evolution=>{
      :name=>'金屬蛻變',:category=>:relationship,:priority=>135,
      :basis=>:shared_mechanic,:discovery_rank=>:rare,:hidden_until_discovered=>false,
      :hint=>'金屬膜能讓兩條古老血脈披上真正的鋼鐵。',
      :description=>'巨鉗螳螂與大鋼蛇共同出戰。全隊提高接觸傷害並降低承傷。',
      :composition=>[{:type=>:species,:key=>:scizor},{:type=>:species,:key=>:steelix}],
      :effects=>[{:type=>:contact_damage_mult,:mult=>1.04,:scope=>:team},{:type=>:damage_in_mult,:mult=>0.96,:scope=>:team}]
    },
    :ancient_power_awakening=>{
      :name=>'原始力量覺醒',:category=>:relationship,:priority=>210,
      :basis=>:shared_mechanic,:discovery_rank=>:secret,:hidden_until_discovered=>true,
      :hint=>'某些沉睡的進化，只有重新記起遠古力量才會甦醒。',
      :description=>'象牙豬、遠古巨蜓與巨蔓藤共同出戰。全隊取得開場 Energy 並提高狀態韌性。',
      :composition=>[{:type=>:species,:key=>:mamoswine},{:type=>:species,:key=>:yanmega},{:type=>:species,:key=>:tangrowth}],
      :effects=>[{:type=>:initial_energy,:amount=>6,:scope=>:team,:once=>true},{:type=>:status_duration_mult,:mult=>0.92,:scope=>:team}]
    },
    :kings_rock_royalty=>{
      :name=>'王者之證',:category=>:relationship,:priority=>135,
      :basis=>:shared_mechanic,:discovery_rank=>:rare,:hidden_until_discovered=>false,
      :hint=>'兩條完全不同的進化線，都曾需要同一頂王冠。',
      :description=>'牛蛙君與呆呆王共同出戰。全隊提高治療與 Energy 取得效率。',
      :composition=>[{:type=>:species,:key=>:politoed},{:type=>:species,:key=>:slowking}],
      :effects=>[{:type=>:healing_mult,:mult=>1.06,:scope=>:team},{:type=>:energy_gain_mult,:mult=>1.05,:scope=>:team}]
    },
    :sea_god_birds=>{
      :name=>'海神與三鳥',:category=>:relationship,:priority=>220,
      :basis=>:legendary_myth,:discovery_rank=>:rare,:hidden_until_discovered=>false,
      :hint=>'統御三道天空之翼的海之守護者……',
      :description=>'洛奇亞與傳說三鳥任兩隻共同出戰。全隊降低承傷並大幅縮短負面狀態時間。',
      :composition=>[{:type=>:species,:key=>:lugia},{:type=>:species_pool,:keys=>[:articuno,:zapdos,:moltres],:count=>2,:unique=>true}],
      :effects=>[{:type=>:damage_in_mult,:mult=>0.95,:scope=>:team},{:type=>:status_duration_mult,:mult=>0.90,:scope=>:team}]
    },
    :rainbow_tower_pact=>{
      :name=>'虹塔盟約',:category=>:relationship,:priority=>220,
      :basis=>:legendary_myth,:discovery_rank=>:rare,:hidden_until_discovered=>false,
      :hint=>'虹色之翼曾讓三道逝去的生命重新奔跑。',
      :description=>'鳳王與三聖獸任兩隻共同出戰。全隊提高治療與 Energy 循環。',
      :composition=>[{:type=>:species,:key=>:ho_oh},{:type=>:species_pool,:keys=>[:raikou,:entei,:suicune],:count=>2,:unique=>true}],
      :effects=>[{:type=>:healing_mult,:mult=>1.08,:scope=>:team},{:type=>:energy_gain_mult,:mult=>1.05,:scope=>:team}]
    },
    :creation_myth=>{
      :name=>'創世神話',:category=>:relationship,:priority=>230,
      :basis=>:legendary_myth,:discovery_rank=>:secret,:hidden_until_discovered=>true,
      :hint=>'創造世界的存在，與時間、空間及反轉世界彼此相連。',
      :description=>'阿爾宙斯與創世三龍任兩隻共同出戰。全隊同時提高攻守效率。',
      :composition=>[{:type=>:species,:key=>:arceus},{:type=>:species_pool,:keys=>[:dialga,:palkia,:giratina],:count=>2,:unique=>true}],
      :effects=>[{:type=>:damage_out_mult,:mult=>1.05,:scope=>:team},{:type=>:damage_in_mult,:mult=>0.95,:scope=>:team}]
    },
    :mythical_constellation=>{
      :name=>'幻之星群',:category=>:relationship,:priority=>180,
      :basis=>:legendary_myth,:discovery_rank=>:secret,:hidden_until_discovered=>true,
      :hint=>'稀少到幾乎只存在傳說中的生命，若有三顆星同時聚集……',
      :description=>'夢幻、時拉比、基拉祈、瑪納霏、謝米、比克提尼任三隻共同出戰。全隊提高 Energy 循環與狀態韌性。',
      :composition=>[{:type=>:species_pool,:keys=>[:mew,:celebi,:jirachi,:manaphy,:shaymin,:victini],:count=>3,:unique=>true}],
      :effects=>[{:type=>:energy_gain_mult,:mult=>1.08,:scope=>:team},{:type=>:status_duration_mult,:mult=>0.92,:scope=>:team}]
    },
    :champion_aces=>{
      :name=>'冠軍王牌',:category=>:relationship,:priority=>215,
      :basis=>:collection_theme,:discovery_rank=>:rare,:hidden_until_discovered=>false,
      :hint=>'不同地區的冠軍，曾把這三種強大血脈帶上最高舞台。',
      :description=>'快龍、巨金怪與烈咬陸鯊共同出戰。全隊提高傷害並大幅縮短負面狀態時間。',
      :composition=>[{:type=>:species,:key=>:dragonite},{:type=>:species,:key=>:metagross},{:type=>:species,:key=>:garchomp}],
      :effects=>[{:type=>:damage_out_mult,:mult=>1.05,:scope=>:team},{:type=>:status_duration_mult,:mult=>0.90,:scope=>:team}]
    },
    :weather_extremes=>{
      :name=>'氣象極端',:category=>:relationship,:priority=>220,
      :basis=>:ecology_theme,:discovery_rank=>:secret,:hidden_until_discovered=>true,
      :hint=>'有一種寶可夢會隨天氣改變，而有些傳說本身就足以改變天空。',
      :description=>'飄浮泡泡與固拉多、蓋歐卡、烈空坐任兩隻共同出戰。全隊提高 Energy 循環與狀態韌性。',
      :composition=>[{:type=>:species,:key=>:castform},{:type=>:species_pool,:keys=>[:groudon,:kyogre,:rayquaza],:count=>2,:unique=>true}],
      :effects=>[{:type=>:energy_gain_mult,:mult=>1.06,:scope=>:team},{:type=>:status_duration_mult,:mult=>0.92,:scope=>:team}]
    },
    :winged_bug_rivals=>{
      :name=>'雙翼蟲群',:category=>:relationship,:priority=>120,
      :basis=>:counterpart,:discovery_rank=>:normal,:hidden_until_discovered=>false,
      :hint=>'關都最早被人熟悉的兩條蟲系進化道路。',
      :description=>'巴大蝶與大針蜂共同出戰。全隊提高機動並略微縮短負面狀態。',
      :composition=>[{:type=>:species,:key=>:butterfree},{:type=>:species,:key=>:beedrill}],
      :effects=>[{:type=>:move_speed_mult,:mult=>1.05,:scope=>:team},{:type=>:status_duration_mult,:mult=>0.95,:scope=>:team}]
    },
    :fire_fox_hound=>{
      :name=>'炎狐與烈犬',:category=>:relationship,:priority=>120,
      :basis=>:counterpart,:discovery_rank=>:normal,:hidden_until_discovered=>false,
      :hint=>'兩條需要火之石才能抵達頂點的關都火焰血脈。',
      :description=>'九尾與風速狗共同出戰。九尾提高特殊傷害，風速狗提高物理傷害。',
      :composition=>[{:type=>:species,:key=>:ninetales},{:type=>:species,:key=>:arcanine}],
      :effects=>[{:type=>:special_damage_mult,:mult=>1.05,:scope=>{:species=>:ninetales}},{:type=>:physical_damage_mult,:mult=>1.05,:scope=>{:species=>:arcanine}}]
    },
    :blade_horn_rivals=>{
      :name=>'鐮角競鋒',:category=>:relationship,:priority=>120,
      :basis=>:counterpart,:discovery_rank=>:normal,:hidden_until_discovered=>false,
      :hint=>'鐮刀般的前肢與巨大的雙角都為近身搏鬥而生。',
      :description=>'飛天螳螂與凱羅斯共同出戰。全隊提高接觸傷害與機動力。',
      :composition=>[{:type=>:species,:key=>:scyther},{:type=>:species,:key=>:pinsir}],
      :effects=>[{:type=>:contact_damage_mult,:mult=>1.06,:scope=>:team},{:type=>:move_speed_mult,:mult=>1.03,:scope=>:team}]
    },
    :rainforest_kings=>{
      :name=>'雨林雙王',:category=>:relationship,:priority=>120,
      :basis=>:counterpart,:discovery_rank=>:normal,:hidden_until_discovered=>false,
      :hint=>'一邊等待陽光，一邊期待雨水，卻同樣統治著森林節奏。',
      :description=>'狡猾天狗與樂天河童共同出戰。全隊提高 Energy 循環與治療效率。',
      :composition=>[{:type=>:species,:key=>:shiftry},{:type=>:species,:key=>:ludicolo}],
      :effects=>[{:type=>:energy_gain_mult,:mult=>1.05,:scope=>:team},{:type=>:healing_mult,:mult=>1.05,:scope=>:team}]
    },
    :gem_shadow_pair=>{
      :name=>'寶石暗影',:category=>:relationship,:priority=>120,
      :basis=>:counterpart,:discovery_rank=>:rare,:hidden_until_discovered=>false,
      :hint=>'一個躲進寶石陰影，一個用巨大的顎面對世界。',
      :description=>'勾魂眼與大嘴娃共同出戰。全隊降低承傷並提高狀態韌性。',
      :composition=>[{:type=>:species,:key=>:sableye},{:type=>:species,:key=>:mawile}],
      :effects=>[{:type=>:damage_in_mult,:mult=>0.96,:scope=>:team},{:type=>:status_duration_mult,:mult=>0.92,:scope=>:team}]
    },
    :night_duo=>{
      :name=>'黑夜雙星',:category=>:relationship,:priority=>120,
      :basis=>:counterpart,:discovery_rank=>:rare,:hidden_until_discovered=>false,
      :hint=>'一位號令黑夜群鳥，一位讓夜色化成詭異魔法。',
      :description=>'烏鴉頭頭與夢妖魔共同出戰。全隊提高遠程傷害與 Energy 循環。',
      :composition=>[{:type=>:species,:key=>:honchkrow},{:type=>:species,:key=>:mismagius}],
      :effects=>[{:type=>:ranged_damage_mult,:mult=>1.05,:scope=>:team},{:type=>:energy_gain_mult,:mult=>1.05,:scope=>:team}]
    },
    :poison_claw_pair=>{
      :name=>'毒煙與利爪',:category=>:relationship,:priority=>115,
      :basis=>:counterpart,:discovery_rank=>:normal,:hidden_until_discovered=>false,
      :hint=>'神奧兩條性格強烈的普通野外血脈，一邊靠毒，一邊靠爪。',
      :description=>'坦克臭鼬與東施喵共同出戰。全隊提高接觸傷害與機動力。',
      :composition=>[{:type=>:species,:key=>:skuntank},{:type=>:species,:key=>:purugly}],
      :effects=>[{:type=>:contact_damage_mult,:mult=>1.05,:scope=>:team},{:type=>:move_speed_mult,:mult=>1.03,:scope=>:team}]
    },
    :steel_sea_wings=>{
      :name=>'鋼羽與海翼',:category=>:relationship,:priority=>110,
      :basis=>:counterpart,:discovery_rank=>:rare,:hidden_until_discovered=>false,
      :hint=>'一片鋼鐵天空，一片深海天空，都是巨大雙翼。',
      :description=>'盔甲鳥與巨翅飛魚共同出戰。全隊降低承傷並提高遠程傷害。',
      :composition=>[{:type=>:species,:key=>:skarmory},{:type=>:species,:key=>:mantine}],
      :effects=>[{:type=>:damage_in_mult,:mult=>0.96,:scope=>:team},{:type=>:ranged_damage_mult,:mult=>1.04,:scope=>:team}]
    },
    :trade_pioneers=>{
      :name=>'交換進化先驅',:category=>:relationship,:priority=>180,
      :basis=>:shared_mechanic,:discovery_rank=>:rare,:hidden_until_discovered=>false,
      :hint=>'最早讓訓練家理解「交換」也能促成進化的四條血脈。',
      :description=>'胡地、怪力、隆隆岩、耿鬼任三隻共同出戰。全隊提高 Energy 循環與狀態韌性。',
      :composition=>[{:type=>:species_pool,:keys=>[:alakazam,:machamp,:golem,:gengar],:count=>3,:unique=>true}],
      :effects=>[{:type=>:energy_gain_mult,:mult=>1.05,:scope=>:team},{:type=>:status_duration_mult,:mult=>0.95,:scope=>:team}]
    },
    :held_trade_evolution=>{
      :name=>'攜物交換',:category=>:relationship,:priority=>175,
      :basis=>:shared_mechanic,:discovery_rank=>:rare,:hidden_until_discovered=>false,
      :hint=>'有些交換還需要手中握著正確的物品。',
      :description=>'牛蛙君、呆呆王、大鋼蛇、巨鉗螳螂、刺龍王任三隻共同出戰。全隊降低承傷並提高 Energy 循環。',
      :composition=>[{:type=>:species_pool,:keys=>[:politoed,:slowking,:steelix,:scizor,:kingdra],:count=>3,:unique=>true}],
      :effects=>[{:type=>:damage_in_mult,:mult=>0.96,:scope=>:team},{:type=>:energy_gain_mult,:mult=>1.04,:scope=>:team}]
    },
    :sinnoh_evolvers=>{
      :name=>'神奧進化器',:category=>:relationship,:priority=>180,
      :basis=>:shared_mechanic,:discovery_rank=>:rare,:hidden_until_discovered=>false,
      :hint=>'神奧讓許多舊世代血脈再次找到新的終點。',
      :description=>'超甲狂犀、電擊魔獸、鴨嘴炎獸、多邊獸乙型、黑夜魔靈任三隻共同出戰。全隊提高傷害與 Energy 循環。',
      :composition=>[{:type=>:species_pool,:keys=>[:rhyperior,:electivire,:magmortar,:porygon_z,:dusknoir],:count=>3,:unique=>true}],
      :effects=>[{:type=>:damage_out_mult,:mult=>1.04,:scope=>:team},{:type=>:energy_gain_mult,:mult=>1.04,:scope=>:team}]
    },
    :cradle_stars=>{
      :name=>'搖籃三星',:category=>:relationship,:priority=>190,
      :basis=>:shared_mechanic,:discovery_rank=>:normal,:hidden_until_discovered=>false,
      :hint=>'三位最早登場的幼年寶可夢，從搖籃就彼此相映。',
      :description=>'皮丘、皮寶寶、寶寶丁共同出戰。全隊提高治療效率並縮短負面狀態。',
      :composition=>[{:type=>:species,:key=>:pichu},{:type=>:species,:key=>:cleffa},{:type=>:species,:key=>:igglybuff}],
      :effects=>[{:type=>:healing_mult,:mult=>1.06,:scope=>:team},{:type=>:status_duration_mult,:mult=>0.90,:scope=>:team}]
    },
    :baby_generation=>{
      :name=>'幼體世代',:category=>:relationship,:priority=>175,
      :basis=>:shared_mechanic,:discovery_rank=>:normal,:hidden_until_discovered=>false,
      :hint=>'幼小外表下藏著未來完全不同的戰鬥道路。',
      :description=>'迷唇娃、電擊怪、鴨嘴寶寶、無畏小子任三隻共同出戰。全隊取得開場 Energy 並提高機動力。',
      :composition=>[{:type=>:species_pool,:keys=>[:smoochum,:elekid,:magby,:tyrogue],:count=>3,:unique=>true}],
      :effects=>[{:type=>:initial_energy,:amount=>5,:scope=>:team,:once=>true},{:type=>:move_speed_mult,:mult=>1.04,:scope=>:team}]
    },
    :new_babies=>{
      :name=>'新世代幼體',:category=>:relationship,:priority=>175,
      :basis=>:shared_mechanic,:discovery_rank=>:rare,:hidden_until_discovered=>false,
      :hint=>'神奧補上了許多早已熟悉血脈的幼年篇章。',
      :description=>'含羞苞、鈴鐺響、盆才怪、魔尼尼、小福蛋、小卡比獸、小球飛魚任三隻共同出戰。全隊提高治療並略微降低承傷。',
      :composition=>[{:type=>:species_pool,:keys=>[:budew,:chingling,:bonsly,:mime_jr,:happiny,:munchlax,:mantyke],:count=>3,:unique=>true}],
      :effects=>[{:type=>:healing_mult,:mult=>1.07,:scope=>:team},{:type=>:damage_in_mult,:mult=>0.97,:scope=>:team}]
    },
    :moon_stone_classics=>{
      :name=>'月之石古典',:category=>:relationship,:priority=>175,
      :basis=>:shared_mechanic,:discovery_rank=>:rare,:hidden_until_discovered=>false,
      :hint=>'月光曾讓關都多條古老血脈完成最終進化。',
      :description=>'皮可西、胖可丁、尼多后、尼多王任三隻共同出戰。全隊提高狀態韌性與 Energy 循環。',
      :composition=>[{:type=>:species_pool,:keys=>[:clefable,:wigglytuff,:nidoqueen,:nidoking],:count=>3,:unique=>true}],
      :effects=>[{:type=>:status_duration_mult,:mult=>0.90,:scope=>:team},{:type=>:energy_gain_mult,:mult=>1.04,:scope=>:team}]
    },
    :fossil_museum=>{
      :name=>'古生物博覽',:category=>:relationship,:priority=>185,
      :basis=>:collection_theme,:discovery_rank=>:secret,:hidden_until_discovered=>true,
      :hint=>'來自不同年代的化石若在同一隊伍復甦，就像一座活著的博物館。',
      :description=>'多刺菊石獸、鐮刀盔、化石翼龍、搖籃百合、太古盔甲、戰槌龍、護城龍任三隻共同出戰。全隊降低承傷並提高狀態韌性。',
      :composition=>[{:type=>:species_pool,:keys=>[:omastar,:kabutops,:aerodactyl,:cradily,:armaldo,:rampardos,:bastiodon],:count=>3,:unique=>true}],
      :effects=>[{:type=>:damage_in_mult,:mult=>0.95,:scope=>:team},{:type=>:status_duration_mult,:mult=>0.90,:scope=>:team}]
    },
    :electric_mouse_union=>{
      :name=>'電氣鼠聯盟',:category=>:relationship,:priority=>180,
      :basis=>:collection_theme,:discovery_rank=>:rare,:hidden_until_discovered=>false,
      :hint=>'不同地區總有小小身影把電流藏進臉頰。',
      :description=>'皮卡丘、正電拍拍、負電拍拍、帕奇利茲任三隻共同出戰。全隊提高 Energy 循環與機動力。',
      :composition=>[{:type=>:species_pool,:keys=>[:pikachu,:plusle,:minun,:pachirisu],:count=>3,:unique=>true}],
      :effects=>[{:type=>:energy_gain_mult,:mult=>1.06,:scope=>:team},{:type=>:move_speed_mult,:mult=>1.04,:scope=>:team}]
    },
    :artificial_life=>{
      :name=>'人造生命',:category=>:relationship,:priority=>205,
      :basis=>:collection_theme,:discovery_rank=>:secret,:hidden_until_discovered=>true,
      :hint=>'並非所有生命都只由自然塑造。',
      :description=>'超夢、多邊獸乙型與飄浮泡泡共同出戰。全隊提高特殊傷害並大幅縮短負面狀態。',
      :composition=>[{:type=>:species,:key=>:mewtwo},{:type=>:species,:key=>:porygon_z},{:type=>:species,:key=>:castform}],
      :effects=>[{:type=>:special_damage_mult,:mult=>1.05,:scope=>:team},{:type=>:status_duration_mult,:mult=>0.90,:scope=>:team}]
    },
    :mimic_trinity=>{
      :name=>'模仿者',:category=>:relationship,:priority=>210,
      :basis=>:collection_theme,:discovery_rank=>:secret,:hidden_until_discovered=>true,
      :hint=>'有些 Pokémon 並不只靠自己的模樣與招式戰鬥。',
      :description=>'百變怪、夢幻與圖圖犬共同出戰。全隊提高 Energy 循環與機動力。',
      :composition=>[{:type=>:species,:key=>:ditto},{:type=>:species,:key=>:mew},{:type=>:species,:key=>:smeargle}],
      :effects=>[{:type=>:energy_gain_mult,:mult=>1.06,:scope=>:team},{:type=>:move_speed_mult,:mult=>1.04,:scope=>:team}]
    },
    :sound_trio=>{
      :name=>'音律三重奏',:category=>:relationship,:priority=>190,
      :basis=>:ecology_theme,:discovery_rank=>:normal,:hidden_until_discovered=>false,
      :hint=>'吼聲、蟲鳴與歌聲都能成為戰鬥的一部分。',
      :description=>'爆音怪、音箱蟀與聒噪鳥共同出戰。全隊提高 Energy 循環與機動力。',
      :composition=>[{:type=>:species,:key=>:exploud},{:type=>:species,:key=>:kricketune},{:type=>:species,:key=>:chatot}],
      :effects=>[{:type=>:energy_gain_mult,:mult=>1.05,:scope=>:team},{:type=>:move_speed_mult,:mult=>1.04,:scope=>:team}]
    },
    :magnetic_resonance=>{
      :name=>'磁場共振',:category=>:relationship,:priority=>195,
      :basis=>:ecology_theme,:discovery_rank=>:rare,:hidden_until_discovered=>false,
      :hint=>'強烈磁場能改變進化，也會吸引奇異的電磁生命。',
      :description=>'自爆磁怪、大朝北鼻與洛托姆共同出戰。全隊提高特殊傷害並略微降低承傷。',
      :composition=>[{:type=>:species,:key=>:magnezone},{:type=>:species,:key=>:probopass},{:type=>:species,:key=>:rotom}],
      :effects=>[{:type=>:special_damage_mult,:mult=>1.05,:scope=>:team},{:type=>:damage_in_mult,:mult=>0.97,:scope=>:team}]
    },
    :ancient_celestial=>{
      :name=>'古代天象',:category=>:relationship,:priority=>190,
      :basis=>:ecology_theme,:discovery_rank=>:rare,:hidden_until_discovered=>false,
      :hint=>'古代文明留下的土偶，與日月形體的生命共同凝視天空。',
      :description=>'念力土偶、太陽岩與月石共同出戰。全隊提高特殊傷害與狀態韌性。',
      :composition=>[{:type=>:species,:key=>:claydol},{:type=>:species,:key=>:solrock},{:type=>:species,:key=>:lunatone}],
      :effects=>[{:type=>:special_damage_mult,:mult=>1.05,:scope=>:team},{:type=>:status_duration_mult,:mult=>0.92,:scope=>:team}]
    },
    :fragrant_garden=>{
      :name=>'芳香花園',:category=>:relationship,:priority=>190,
      :basis=>:ecology_theme,:discovery_rank=>:normal,:hidden_until_discovered=>false,
      :hint=>'不同季節與地區的花朵，也能在同一座花園盛開。',
      :description=>'美麗花、羅絲雷朵與櫻花兒共同出戰。全隊大幅提高治療效率。',
      :composition=>[{:type=>:species,:key=>:bellossom},{:type=>:species,:key=>:roserade},{:type=>:species,:key=>:cherrim}],
      :effects=>[{:type=>:healing_mult,:mult=>1.08,:scope=>:team}]
    },
    :night_ghost_stories=>{
      :name=>'夜幕怪談',:category=>:relationship,:priority=>200,
      :basis=>:ecology_theme,:discovery_rank=>:secret,:hidden_until_discovered=>true,
      :hint=>'被封印的怨念、被遺棄的玩偶，以及載走靈魂的氣球。',
      :description=>'花岩怪、詛咒娃娃與隨風球共同出戰。全隊提高間接傷害與 Energy 循環。',
      :composition=>[{:type=>:species,:key=>:spiritomb},{:type=>:species,:key=>:banette},{:type=>:species,:key=>:drifblim}],
      :effects=>[{:type=>:indirect_damage_mult,:mult=>1.08,:scope=>:team},{:type=>:energy_gain_mult,:mult=>1.04,:scope=>:team}]
    },
    :apex_bloodline=>{
      :name=>'巔峰血脈',:category=>:relationship,:priority=>180,
      :basis=>:collection_theme,:discovery_rank=>:rare,:hidden_until_discovered=>false,
      :hint=>'不同世代都有少數血脈，以漫長成長換取頂尖力量。',
      :description=>'快龍、班基拉斯、暴飛龍、巨金怪、烈咬陸鯊任三隻共同出戰。全隊提高傷害並略微降低承傷。',
      :composition=>[{:type=>:species_pool,:keys=>[:dragonite,:tyranitar,:salamence,:metagross,:garchomp],:count=>3,:unique=>true}],
      :effects=>[{:type=>:damage_out_mult,:mult=>1.04,:scope=>:team},{:type=>:damage_in_mult,:mult=>0.97,:scope=>:team}]
    }
  }

  #--------------------------------------------------------------------------
  # 將 v0.99.3 內容加入 v0.99.2 Frozen Runtime 的資料表。
  # 只改資料 Hash，不覆寫任何戰鬥 Effect Runtime 方法。
  #--------------------------------------------------------------------------
  TEAM_BOND_EXPANSION_DATA_V0993.each{|k,v|TEAM_BOND_DATA_V0992[k]=v}
  TEAM_BOND_LEGACY_METADATA_V0993.each do |k,meta|
    d=TEAM_BOND_DATA_V0992[k]
    meta.each{|mk,mv|d[mk]=mv} if d!=nil
  end
  TEAM_BOND_TACTICAL_METADATA_V0993.each do |k,meta|
    d=TEAM_BOND_DATA_V0992[k]
    meta.each{|mk,mv|d[mk]=mv} if d!=nil
  end

  # v0.99.2 Registry Validator 會讀這個 manifest；只更新內容數，不改 Runtime 規則。
  TEAM_BOND_MANIFEST_V0992[:relationship_count]=73
  TEAM_BOND_MANIFEST_V0992[:tactical_count]=8
  TEAM_BOND_MANIFEST_V0992[:total_count]=81

  TEAM_BOND_MANIFEST_V0993={
    :version=>'0.99.3',:relationship_count=>73,:tactical_count=>8,:total_count=>81,
    :relationship_rank_counts=>{:normal=>33,:rare=>28,:secret=>12},
    :tactical_public=>true,:content_cap=>81,:runtime_source=>'v0.99.2',
    :effect_types_unchanged=>true,:category_limit=>{:relationship=>1,:tactical=>1},
    :seen_formed_save=>true,:roguelike_run_bonus=>false
  }

  class << self
    def team_bond_data_v0993(key);TEAM_BOND_DATA_V0992[key];end
    def team_bond_hint_v0993(key)
      d=TEAM_BOND_DATA_V0992[key];d==nil ? '' : (d[:hint] || '')
    end
    def team_bond_discovery_rank_v0993(key)
      d=TEAM_BOND_DATA_V0992[key];d==nil ? nil : d[:discovery_rank]
    end
    def team_bond_hidden_v0993?(key)
      d=TEAM_BOND_DATA_V0992[key];d!=nil && d[:hidden_until_discovered] ? true:false
    end
  end
end
