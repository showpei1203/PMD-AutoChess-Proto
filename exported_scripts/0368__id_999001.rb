# encoding: UTF-8
#==============================================================================
# 【PMD AutoChess 中文維護說明】
# 腳本：PMD AutoChess Johto Gameplay Review Data v0.99.9
# 分類：Pokémon Gameplay / AI / Balance Review #0152-0251
#
# 【用途】
# - 正式完成 National Dex #0152-0251 共 100 隻 Pokémon 第一輪逐隻 Gameplay Review。
# - 每隻人工指定 Role、Movement / Target / Threat / Skill Policy、普通攻擊距離、
#   屬性與 Physical/Special 類別；不以 percentile 自動 Profile 冒充人工審核。
# - Kanto v0.99.8 的 151 隻 Profile 完整保留，本版只追加 Johto 內容。
# - Base Stats、Learnset、TM、Tutor、Egg、Ability、Evolution、Team Bond 仍引用既有
#   Production Data；不因平衡審核竄改 canonical Base Stats。
#
# 【主要設定項】
# JOHTO_PROFILE_OVERRIDES_V0999：#0152-0251 共 100 隻人工戰術 Profile。
# JOHTO_SPECIAL_BALANCE_RISKS_V0999：需要後續平衡追蹤的特殊風險。
# JOHTO_IDENTITY_NOTES_V0999：Unown / Wobbuffet / Delibird / Smeargle / Tyrogue 等
#   無法用一般四招模板合理描述的身份規則。
# JOHTO_ABILITY_SYNERGY_EXTRA_V0999：補足 Johto 常見 Ability 與戰術標籤關係。
#
# 【普通攻擊規則】
# - range=1：近戰；range=3：遠程。
# - basic_damage_category 僅影響 source_type=:basic 的普通攻擊。
# - Skill 自己的 Physical/Special category 完全不改。
# - basic_move_type 必須屬於目前 Species 正常型 Type。
#
# 【AI 規則】
# - Species Profile 是預設 AI。
# - 玩家已儲存在 PokémonInstance 的 ai_setup 永遠最後套用，優先於本表。
# - 進化後會重新套 Species Profile，再恢復玩家 ai_setup。
#
# 【特殊種規則】
# - Wobbuffet 本輪只完成 Gameplay Review 與風險標記，不在這裡直接改寫普攻核心。
# - Smeargle / Unown 不為湊四招新增虛構技能。
# - Tyrogue 保留分支進化身份。
#
# 【事件／腳本呼叫方式】
# row = PMD_AC.gameplay_review_row_v0999(:umbreon)
# profile = PMD_AC.review_profile_for_v0999(:crobat, :normal)
# PMD_AC.write_johto_gameplay_review_v0999
#
# 【實際範例】
# Lanturn：ranged Electric Special Bodyguard。
# Umbreon：melee Dark Physical Bodyguard，強調貼身保護與耐久。
# Crobat：高速 melee Poison Physical Assassin。
# Shuckle：極端防禦 Bodyguard，不把低攻擊錯判為後排砲台。
#
# 【維護限制】
# - RPG Maker VX / RGSS2 / Ruby 1.8。
# - 不使用禁止的舊式 instance variable 反射檢查。
# - Actor ID 不是 Pokémon identity；永久個體識別仍為 instance_uid。
# - Frozen Combat Core 不直接修改；本版只在 Main 前追加 Data / Runtime Hook。
#==============================================================================
module PMD_AC
  GAMEPLAY_REVIEW_VERSION_V0999='0.99.9'
  JOHTO_REVIEW_DEX_RANGE_V0999=(152..251)
  JOHTO_REVIEW_STATUS_V0999=:reviewed_manual
  JOHTO_PROFILE_OVERRIDES_V0999={
    :chikorita=>{:role=>:controller,:movement_policy=>:controller,:target_policy=>:cluster,:threat_policy=>:responsive,:skill_policy=>:best_cluster,:range=>3,:basic_damage_category=>:special,:basic_move_type=>:grass,:target_commitment=>62},
    :bayleef=>{:role=>:bodyguard,:movement_policy=>:bodyguard,:target_policy=>:protect_ally,:threat_policy=>:protective,:skill_policy=>:protect_ally,:range=>3,:basic_damage_category=>:special,:basic_move_type=>:grass,:target_commitment=>80},
    :meganium=>{:role=>:bodyguard,:movement_policy=>:bodyguard,:target_policy=>:protect_ally,:threat_policy=>:protective,:skill_policy=>:protect_ally,:range=>3,:basic_damage_category=>:special,:basic_move_type=>:grass,:target_commitment=>90},
    :cyndaquil=>{:role=>:kiter,:movement_policy=>:kiter,:target_policy=>:nearest,:threat_policy=>:responsive,:skill_policy=>:current_target,:range=>3,:basic_damage_category=>:special,:basic_move_type=>:fire,:target_commitment=>54},
    :quilava=>{:role=>:kiter,:movement_policy=>:kiter,:target_policy=>:execute,:threat_policy=>:responsive,:skill_policy=>:execute,:range=>3,:basic_damage_category=>:special,:basic_move_type=>:fire,:target_commitment=>60},
    :typhlosion=>{:role=>:artillery,:movement_policy=>:artillery,:target_policy=>:cluster,:threat_policy=>:responsive,:skill_policy=>:best_cluster,:range=>3,:basic_damage_category=>:special,:basic_move_type=>:fire,:target_commitment=>66},
    :totodile=>{:role=>:bruiser,:movement_policy=>:bruiser,:target_policy=>:execute,:threat_policy=>:normal,:skill_policy=>:execute,:range=>1,:basic_damage_category=>:physical,:basic_move_type=>:water,:target_commitment=>68},
    :croconaw=>{:role=>:frontline,:movement_policy=>:frontline,:target_policy=>:melee_first,:threat_policy=>:hold_ground,:skill_policy=>:current_target,:range=>1,:basic_damage_category=>:physical,:basic_move_type=>:water,:target_commitment=>80},
    :feraligatr=>{:role=>:bruiser,:movement_policy=>:berserker,:target_policy=>:execute,:threat_policy=>:ignore_minor,:skill_policy=>:execute,:range=>1,:basic_damage_category=>:physical,:basic_move_type=>:water,:target_commitment=>84},
    :sentret=>{:role=>:controller,:movement_policy=>:controller,:target_policy=>:cluster,:threat_policy=>:responsive,:skill_policy=>:best_cluster,:range=>1,:basic_damage_category=>:physical,:basic_move_type=>:normal,:target_commitment=>48},
    :furret=>{:role=>:assassin,:movement_policy=>:assassin,:target_policy=>:backline_low_def,:threat_policy=>:ignore_minor,:skill_policy=>:execute,:range=>1,:basic_damage_category=>:physical,:basic_move_type=>:normal,:target_commitment=>76},
    :hoothoot=>{:role=>:controller,:movement_policy=>:controller,:target_policy=>:highest_atk,:threat_policy=>:responsive,:skill_policy=>:highest_atk,:range=>3,:basic_damage_category=>:special,:basic_move_type=>:flying,:target_commitment=>60},
    :noctowl=>{:role=>:controller,:movement_policy=>:controller,:target_policy=>:highest_atk,:threat_policy=>:responsive,:skill_policy=>:highest_atk,:range=>3,:basic_damage_category=>:special,:basic_move_type=>:flying,:target_commitment=>72},
    :ledyba=>{:role=>:bodyguard,:movement_policy=>:bodyguard,:target_policy=>:protect_ally,:threat_policy=>:protective,:skill_policy=>:protect_ally,:range=>3,:basic_damage_category=>:special,:basic_move_type=>:bug,:target_commitment=>76},
    :ledian=>{:role=>:controller,:movement_policy=>:controller,:target_policy=>:cluster,:threat_policy=>:responsive,:skill_policy=>:best_cluster,:range=>3,:basic_damage_category=>:special,:basic_move_type=>:flying,:target_commitment=>68},
    :spinarak=>{:role=>:controller,:movement_policy=>:controller,:target_policy=>:highest_atk,:threat_policy=>:responsive,:skill_policy=>:highest_atk,:range=>3,:basic_damage_category=>:physical,:basic_move_type=>:poison,:target_commitment=>58},
    :ariados=>{:role=>:controller,:movement_policy=>:bruiser,:target_policy=>:highest_atk,:threat_policy=>:responsive,:skill_policy=>:highest_atk,:range=>1,:basic_damage_category=>:physical,:basic_move_type=>:poison,:target_commitment=>72},
    :crobat=>{:role=>:assassin,:movement_policy=>:assassin,:target_policy=>:backline_low_def,:threat_policy=>:ignore_minor,:skill_policy=>:execute,:range=>1,:basic_damage_category=>:physical,:basic_move_type=>:poison,:target_commitment=>88},
    :chinchou=>{:role=>:controller,:movement_policy=>:controller,:target_policy=>:cluster,:threat_policy=>:responsive,:skill_policy=>:best_cluster,:range=>3,:basic_damage_category=>:special,:basic_move_type=>:electric,:target_commitment=>60},
    :lanturn=>{:role=>:bodyguard,:movement_policy=>:bodyguard,:target_policy=>:protect_ally,:threat_policy=>:protective,:skill_policy=>:protect_ally,:range=>3,:basic_damage_category=>:special,:basic_move_type=>:electric,:target_commitment=>88},
    :pichu=>{:role=>:kiter,:movement_policy=>:kiter,:target_policy=>:lowest_hp_percent,:threat_policy=>:responsive,:skill_policy=>:current_target,:range=>3,:basic_damage_category=>:special,:basic_move_type=>:electric,:target_commitment=>42},
    :cleffa=>{:role=>:bodyguard,:movement_policy=>:bodyguard,:target_policy=>:protect_ally,:threat_policy=>:protective,:skill_policy=>:heal_critical,:range=>3,:basic_damage_category=>:special,:basic_move_type=>:fairy,:target_commitment=>86},
    :igglybuff=>{:role=>:bodyguard,:movement_policy=>:bodyguard,:target_policy=>:protect_ally,:threat_policy=>:protective,:skill_policy=>:heal_critical,:range=>3,:basic_damage_category=>:special,:basic_move_type=>:fairy,:target_commitment=>84},
    :togepi=>{:role=>:bodyguard,:movement_policy=>:bodyguard,:target_policy=>:protect_ally,:threat_policy=>:protective,:skill_policy=>:heal_critical,:range=>3,:basic_damage_category=>:special,:basic_move_type=>:fairy,:target_commitment=>88},
    :togetic=>{:role=>:bodyguard,:movement_policy=>:bodyguard,:target_policy=>:protect_ally,:threat_policy=>:protective,:skill_policy=>:heal_critical,:range=>3,:basic_damage_category=>:special,:basic_move_type=>:fairy,:target_commitment=>92},
    :natu=>{:role=>:controller,:movement_policy=>:controller,:target_policy=>:highest_atk,:threat_policy=>:responsive,:skill_policy=>:highest_atk,:range=>3,:basic_damage_category=>:special,:basic_move_type=>:psychic,:target_commitment=>58},
    :xatu=>{:role=>:artillery,:movement_policy=>:artillery,:target_policy=>:cluster,:threat_policy=>:responsive,:skill_policy=>:best_cluster,:range=>3,:basic_damage_category=>:special,:basic_move_type=>:psychic,:target_commitment=>66},
    :mareep=>{:role=>:artillery,:movement_policy=>:artillery,:target_policy=>:lowest_def,:threat_policy=>:responsive,:skill_policy=>:lowest_def,:range=>3,:basic_damage_category=>:special,:basic_move_type=>:electric,:target_commitment=>62},
    :flaaffy=>{:role=>:artillery,:movement_policy=>:artillery,:target_policy=>:lowest_def,:threat_policy=>:responsive,:skill_policy=>:lowest_def,:range=>3,:basic_damage_category=>:special,:basic_move_type=>:electric,:target_commitment=>68},
    :ampharos=>{:role=>:artillery,:movement_policy=>:artillery,:target_policy=>:lowest_def,:threat_policy=>:hold_ground,:skill_policy=>:lowest_def,:range=>3,:basic_damage_category=>:special,:basic_move_type=>:electric,:target_commitment=>76},
    :bellossom=>{:role=>:bodyguard,:movement_policy=>:bodyguard,:target_policy=>:protect_ally,:threat_policy=>:protective,:skill_policy=>:heal_critical,:range=>3,:basic_damage_category=>:special,:basic_move_type=>:grass,:target_commitment=>90},
    :marill=>{:role=>:frontline,:movement_policy=>:frontline,:target_policy=>:melee_first,:threat_policy=>:hold_ground,:skill_policy=>:current_target,:range=>1,:basic_damage_category=>:physical,:basic_move_type=>:water,:target_commitment=>78},
    :azumarill=>{:role=>:bruiser,:movement_policy=>:bruiser,:target_policy=>:execute,:threat_policy=>:normal,:skill_policy=>:execute,:range=>1,:basic_damage_category=>:physical,:basic_move_type=>:fairy,:target_commitment=>82},
    :sudowoodo=>{:role=>:frontline,:movement_policy=>:frontline,:target_policy=>:melee_first,:threat_policy=>:hold_ground,:skill_policy=>:current_target,:range=>1,:basic_damage_category=>:physical,:basic_move_type=>:rock,:target_commitment=>90},
    :politoed=>{:role=>:controller,:movement_policy=>:controller,:target_policy=>:cluster,:threat_policy=>:responsive,:skill_policy=>:best_cluster,:range=>3,:basic_damage_category=>:special,:basic_move_type=>:water,:target_commitment=>72},
    :hoppip=>{:role=>:controller,:movement_policy=>:controller,:target_policy=>:cluster,:threat_policy=>:responsive,:skill_policy=>:best_cluster,:range=>3,:basic_damage_category=>:special,:basic_move_type=>:grass,:target_commitment=>50},
    :skiploom=>{:role=>:controller,:movement_policy=>:controller,:target_policy=>:cluster,:threat_policy=>:responsive,:skill_policy=>:best_cluster,:range=>3,:basic_damage_category=>:special,:basic_move_type=>:grass,:target_commitment=>58},
    :jumpluff=>{:role=>:controller,:movement_policy=>:kiter,:target_policy=>:cluster,:threat_policy=>:responsive,:skill_policy=>:best_cluster,:range=>3,:basic_damage_category=>:special,:basic_move_type=>:grass,:target_commitment=>62},
    :aipom=>{:role=>:assassin,:movement_policy=>:assassin,:target_policy=>:backline_low_def,:threat_policy=>:ignore_minor,:skill_policy=>:execute,:range=>1,:basic_damage_category=>:physical,:basic_move_type=>:normal,:target_commitment=>78},
    :sunkern=>{:role=>:artillery,:movement_policy=>:artillery,:target_policy=>:lowest_def,:threat_policy=>:responsive,:skill_policy=>:lowest_def,:range=>3,:basic_damage_category=>:special,:basic_move_type=>:grass,:target_commitment=>44},
    :sunflora=>{:role=>:artillery,:movement_policy=>:artillery,:target_policy=>:lowest_def,:threat_policy=>:hold_ground,:skill_policy=>:lowest_def,:range=>3,:basic_damage_category=>:special,:basic_move_type=>:grass,:target_commitment=>72},
    :yanma=>{:role=>:kiter,:movement_policy=>:kiter,:target_policy=>:backline_low_def,:threat_policy=>:responsive,:skill_policy=>:execute,:range=>3,:basic_damage_category=>:special,:basic_move_type=>:bug,:target_commitment=>66},
    :wooper=>{:role=>:frontline,:movement_policy=>:frontline,:target_policy=>:melee_first,:threat_policy=>:hold_ground,:skill_policy=>:current_target,:range=>1,:basic_damage_category=>:physical,:basic_move_type=>:ground,:target_commitment=>86},
    :quagsire=>{:role=>:bodyguard,:movement_policy=>:bodyguard,:target_policy=>:protect_ally,:threat_policy=>:protective,:skill_policy=>:protect_ally,:range=>1,:basic_damage_category=>:physical,:basic_move_type=>:ground,:target_commitment=>92},
    :espeon=>{:role=>:artillery,:movement_policy=>:artillery,:target_policy=>:lowest_def,:threat_policy=>:responsive,:skill_policy=>:lowest_def,:range=>3,:basic_damage_category=>:special,:basic_move_type=>:psychic,:target_commitment=>62},
    :umbreon=>{:role=>:bodyguard,:movement_policy=>:bodyguard,:target_policy=>:protect_ally,:threat_policy=>:protective,:skill_policy=>:protect_ally,:range=>1,:basic_damage_category=>:physical,:basic_move_type=>:dark,:target_commitment=>94},
    :murkrow=>{:role=>:controller,:movement_policy=>:controller,:target_policy=>:highest_atk,:threat_policy=>:responsive,:skill_policy=>:highest_atk,:range=>3,:basic_damage_category=>:special,:basic_move_type=>:dark,:target_commitment=>60},
    :slowking=>{:role=>:bodyguard,:movement_policy=>:bodyguard,:target_policy=>:protect_ally,:threat_policy=>:protective,:skill_policy=>:heal_critical,:range=>3,:basic_damage_category=>:special,:basic_move_type=>:psychic,:target_commitment=>94},
    :misdreavus=>{:role=>:controller,:movement_policy=>:controller,:target_policy=>:highest_atk,:threat_policy=>:responsive,:skill_policy=>:highest_atk,:range=>3,:basic_damage_category=>:special,:basic_move_type=>:ghost,:target_commitment=>66},
    :unown=>{:role=>:artillery,:movement_policy=>:artillery,:target_policy=>:lowest_def,:threat_policy=>:responsive,:skill_policy=>:lowest_def,:range=>3,:basic_damage_category=>:special,:basic_move_type=>:psychic,:target_commitment=>50},
    :wobbuffet=>{:role=>:bodyguard,:movement_policy=>:bodyguard,:target_policy=>:protect_ally,:threat_policy=>:protective,:skill_policy=>:protect_ally,:range=>1,:basic_damage_category=>:physical,:basic_move_type=>:psychic,:target_commitment=>98},
    :girafarig=>{:role=>:artillery,:movement_policy=>:artillery,:target_policy=>:lowest_def,:threat_policy=>:responsive,:skill_policy=>:lowest_def,:range=>3,:basic_damage_category=>:special,:basic_move_type=>:psychic,:target_commitment=>66},
    :pineco=>{:role=>:frontline,:movement_policy=>:frontline,:target_policy=>:melee_first,:threat_policy=>:hold_ground,:skill_policy=>:current_target,:range=>1,:basic_damage_category=>:physical,:basic_move_type=>:bug,:target_commitment=>92},
    :forretress=>{:role=>:bodyguard,:movement_policy=>:bodyguard,:target_policy=>:protect_ally,:threat_policy=>:protective,:skill_policy=>:protect_ally,:range=>1,:basic_damage_category=>:physical,:basic_move_type=>:steel,:target_commitment=>98},
    :dunsparce=>{:role=>:controller,:movement_policy=>:frontline,:target_policy=>:highest_atk,:threat_policy=>:hold_ground,:skill_policy=>:highest_atk,:range=>1,:basic_damage_category=>:physical,:basic_move_type=>:normal,:target_commitment=>82},
    :gligar=>{:role=>:assassin,:movement_policy=>:assassin,:target_policy=>:backline_low_def,:threat_policy=>:ignore_minor,:skill_policy=>:execute,:range=>1,:basic_damage_category=>:physical,:basic_move_type=>:ground,:target_commitment=>82},
    :steelix=>{:role=>:bodyguard,:movement_policy=>:bodyguard,:target_policy=>:protect_ally,:threat_policy=>:protective,:skill_policy=>:protect_ally,:range=>1,:basic_damage_category=>:physical,:basic_move_type=>:steel,:target_commitment=>98},
    :snubbull=>{:role=>:bruiser,:movement_policy=>:bruiser,:target_policy=>:execute,:threat_policy=>:normal,:skill_policy=>:execute,:range=>1,:basic_damage_category=>:physical,:basic_move_type=>:fairy,:target_commitment=>72},
    :granbull=>{:role=>:bruiser,:movement_policy=>:berserker,:target_policy=>:execute,:threat_policy=>:ignore_minor,:skill_policy=>:execute,:range=>1,:basic_damage_category=>:physical,:basic_move_type=>:fairy,:target_commitment=>84},
    :qwilfish=>{:role=>:controller,:movement_policy=>:bruiser,:target_policy=>:highest_atk,:threat_policy=>:responsive,:skill_policy=>:highest_atk,:range=>1,:basic_damage_category=>:physical,:basic_move_type=>:poison,:target_commitment=>74},
    :scizor=>{:role=>:assassin,:movement_policy=>:assassin,:target_policy=>:backline_low_def,:threat_policy=>:ignore_minor,:skill_policy=>:execute,:range=>1,:basic_damage_category=>:physical,:basic_move_type=>:steel,:target_commitment=>88},
    :shuckle=>{:role=>:bodyguard,:movement_policy=>:bodyguard,:target_policy=>:protect_ally,:threat_policy=>:protective,:skill_policy=>:protect_ally,:range=>1,:basic_damage_category=>:physical,:basic_move_type=>:rock,:target_commitment=>100},
    :heracross=>{:role=>:bruiser,:movement_policy=>:berserker,:target_policy=>:execute,:threat_policy=>:ignore_minor,:skill_policy=>:execute,:range=>1,:basic_damage_category=>:physical,:basic_move_type=>:fighting,:target_commitment=>86},
    :sneasel=>{:role=>:assassin,:movement_policy=>:assassin,:target_policy=>:backline_low_def,:threat_policy=>:ignore_minor,:skill_policy=>:execute,:range=>1,:basic_damage_category=>:physical,:basic_move_type=>:dark,:target_commitment=>88},
    :teddiursa=>{:role=>:bruiser,:movement_policy=>:bruiser,:target_policy=>:execute,:threat_policy=>:normal,:skill_policy=>:execute,:range=>1,:basic_damage_category=>:physical,:basic_move_type=>:normal,:target_commitment=>68},
    :ursaring=>{:role=>:bruiser,:movement_policy=>:berserker,:target_policy=>:execute,:threat_policy=>:ignore_minor,:skill_policy=>:execute,:range=>1,:basic_damage_category=>:physical,:basic_move_type=>:normal,:target_commitment=>90},
    :slugma=>{:role=>:controller,:movement_policy=>:controller,:target_policy=>:cluster,:threat_policy=>:responsive,:skill_policy=>:best_cluster,:range=>3,:basic_damage_category=>:special,:basic_move_type=>:fire,:target_commitment=>58},
    :magcargo=>{:role=>:frontline,:movement_policy=>:frontline,:target_policy=>:melee_first,:threat_policy=>:hold_ground,:skill_policy=>:current_target,:range=>3,:basic_damage_category=>:special,:basic_move_type=>:fire,:target_commitment=>92},
    :swinub=>{:role=>:bruiser,:movement_policy=>:bruiser,:target_policy=>:execute,:threat_policy=>:normal,:skill_policy=>:execute,:range=>1,:basic_damage_category=>:physical,:basic_move_type=>:ground,:target_commitment=>68},
    :piloswine=>{:role=>:frontline,:movement_policy=>:frontline,:target_policy=>:melee_first,:threat_policy=>:hold_ground,:skill_policy=>:current_target,:range=>1,:basic_damage_category=>:physical,:basic_move_type=>:ground,:target_commitment=>88},
    :corsola=>{:role=>:bodyguard,:movement_policy=>:bodyguard,:target_policy=>:protect_ally,:threat_policy=>:protective,:skill_policy=>:heal_critical,:range=>3,:basic_damage_category=>:special,:basic_move_type=>:water,:target_commitment=>94},
    :remoraid=>{:role=>:artillery,:movement_policy=>:artillery,:target_policy=>:lowest_def,:threat_policy=>:responsive,:skill_policy=>:lowest_def,:range=>3,:basic_damage_category=>:special,:basic_move_type=>:water,:target_commitment=>58},
    :octillery=>{:role=>:artillery,:movement_policy=>:artillery,:target_policy=>:lowest_def,:threat_policy=>:hold_ground,:skill_policy=>:lowest_def,:range=>3,:basic_damage_category=>:special,:basic_move_type=>:water,:target_commitment=>76},
    :delibird=>{:role=>:kiter,:movement_policy=>:kiter,:target_policy=>:nearest,:threat_policy=>:responsive,:skill_policy=>:current_target,:range=>3,:basic_damage_category=>:special,:basic_move_type=>:ice,:target_commitment=>56},
    :mantine=>{:role=>:bodyguard,:movement_policy=>:bodyguard,:target_policy=>:protect_ally,:threat_policy=>:protective,:skill_policy=>:protect_ally,:range=>3,:basic_damage_category=>:special,:basic_move_type=>:water,:target_commitment=>94},
    :skarmory=>{:role=>:bodyguard,:movement_policy=>:bodyguard,:target_policy=>:protect_ally,:threat_policy=>:protective,:skill_policy=>:protect_ally,:range=>1,:basic_damage_category=>:physical,:basic_move_type=>:steel,:target_commitment=>96},
    :houndour=>{:role=>:artillery,:movement_policy=>:artillery,:target_policy=>:lowest_def,:threat_policy=>:responsive,:skill_policy=>:lowest_def,:range=>3,:basic_damage_category=>:special,:basic_move_type=>:fire,:target_commitment=>58},
    :houndoom=>{:role=>:artillery,:movement_policy=>:artillery,:target_policy=>:backline_low_def,:threat_policy=>:responsive,:skill_policy=>:execute,:range=>3,:basic_damage_category=>:special,:basic_move_type=>:dark,:target_commitment=>70},
    :kingdra=>{:role=>:artillery,:movement_policy=>:artillery,:target_policy=>:lowest_def,:threat_policy=>:responsive,:skill_policy=>:lowest_def,:range=>3,:basic_damage_category=>:special,:basic_move_type=>:dragon,:target_commitment=>76},
    :phanpy=>{:role=>:frontline,:movement_policy=>:frontline,:target_policy=>:melee_first,:threat_policy=>:hold_ground,:skill_policy=>:current_target,:range=>1,:basic_damage_category=>:physical,:basic_move_type=>:ground,:target_commitment=>82},
    :donphan=>{:role=>:frontline,:movement_policy=>:frontline,:target_policy=>:highest_atk,:threat_policy=>:hold_ground,:skill_policy=>:highest_atk,:range=>1,:basic_damage_category=>:physical,:basic_move_type=>:ground,:target_commitment=>94},
    :porygon2=>{:role=>:controller,:movement_policy=>:controller,:target_policy=>:highest_atk,:threat_policy=>:hold_ground,:skill_policy=>:highest_atk,:range=>3,:basic_damage_category=>:special,:basic_move_type=>:normal,:target_commitment=>88},
    :stantler=>{:role=>:controller,:movement_policy=>:bruiser,:target_policy=>:highest_atk,:threat_policy=>:responsive,:skill_policy=>:highest_atk,:range=>1,:basic_damage_category=>:physical,:basic_move_type=>:normal,:target_commitment=>72},
    :smeargle=>{:role=>:controller,:movement_policy=>:controller,:target_policy=>:cluster,:threat_policy=>:responsive,:skill_policy=>:best_cluster,:range=>3,:basic_damage_category=>:special,:basic_move_type=>:normal,:target_commitment=>50},
    :tyrogue=>{:role=>:bruiser,:movement_policy=>:bruiser,:target_policy=>:execute,:threat_policy=>:normal,:skill_policy=>:execute,:range=>1,:basic_damage_category=>:physical,:basic_move_type=>:fighting,:target_commitment=>62},
    :hitmontop=>{:role=>:bodyguard,:movement_policy=>:bodyguard,:target_policy=>:protect_ally,:threat_policy=>:protective,:skill_policy=>:protect_ally,:range=>1,:basic_damage_category=>:physical,:basic_move_type=>:fighting,:target_commitment=>90},
    :smoochum=>{:role=>:artillery,:movement_policy=>:artillery,:target_policy=>:lowest_def,:threat_policy=>:responsive,:skill_policy=>:lowest_def,:range=>3,:basic_damage_category=>:special,:basic_move_type=>:ice,:target_commitment=>54},
    :elekid=>{:role=>:kiter,:movement_policy=>:kiter,:target_policy=>:execute,:threat_policy=>:responsive,:skill_policy=>:execute,:range=>3,:basic_damage_category=>:special,:basic_move_type=>:electric,:target_commitment=>58},
    :magby=>{:role=>:bruiser,:movement_policy=>:bruiser,:target_policy=>:execute,:threat_policy=>:normal,:skill_policy=>:execute,:range=>1,:basic_damage_category=>:physical,:basic_move_type=>:fire,:target_commitment=>66},
    :miltank=>{:role=>:bodyguard,:movement_policy=>:bodyguard,:target_policy=>:protect_ally,:threat_policy=>:protective,:skill_policy=>:heal_critical,:range=>1,:basic_damage_category=>:physical,:basic_move_type=>:normal,:target_commitment=>94},
    :blissey=>{:role=>:bodyguard,:movement_policy=>:bodyguard,:target_policy=>:protect_ally,:threat_policy=>:protective,:skill_policy=>:heal_critical,:range=>3,:basic_damage_category=>:special,:basic_move_type=>:normal,:target_commitment=>98},
    :raikou=>{:role=>:kiter,:movement_policy=>:kiter,:target_policy=>:execute,:threat_policy=>:responsive,:skill_policy=>:execute,:range=>3,:basic_damage_category=>:special,:basic_move_type=>:electric,:target_commitment=>72},
    :entei=>{:role=>:bruiser,:movement_policy=>:bruiser,:target_policy=>:execute,:threat_policy=>:normal,:skill_policy=>:execute,:range=>1,:basic_damage_category=>:physical,:basic_move_type=>:fire,:target_commitment=>84},
    :suicune=>{:role=>:bodyguard,:movement_policy=>:bodyguard,:target_policy=>:protect_ally,:threat_policy=>:protective,:skill_policy=>:protect_ally,:range=>3,:basic_damage_category=>:special,:basic_move_type=>:water,:target_commitment=>96},
    :larvitar=>{:role=>:bruiser,:movement_policy=>:bruiser,:target_policy=>:execute,:threat_policy=>:normal,:skill_policy=>:execute,:range=>1,:basic_damage_category=>:physical,:basic_move_type=>:rock,:target_commitment=>68},
    :pupitar=>{:role=>:frontline,:movement_policy=>:frontline,:target_policy=>:melee_first,:threat_policy=>:hold_ground,:skill_policy=>:current_target,:range=>1,:basic_damage_category=>:physical,:basic_move_type=>:rock,:target_commitment=>88},
    :tyranitar=>{:role=>:frontline,:movement_policy=>:berserker,:target_policy=>:highest_atk,:threat_policy=>:hold_ground,:skill_policy=>:highest_atk,:range=>1,:basic_damage_category=>:physical,:basic_move_type=>:dark,:target_commitment=>94},
    :lugia=>{:role=>:bodyguard,:movement_policy=>:bodyguard,:target_policy=>:protect_ally,:threat_policy=>:protective,:skill_policy=>:protect_ally,:range=>3,:basic_damage_category=>:special,:basic_move_type=>:psychic,:target_commitment=>100},
    :ho_oh=>{:role=>:artillery,:movement_policy=>:artillery,:target_policy=>:cluster,:threat_policy=>:hold_ground,:skill_policy=>:best_cluster,:range=>3,:basic_damage_category=>:special,:basic_move_type=>:fire,:target_commitment=>94},
    :celebi=>{:role=>:controller,:movement_policy=>:controller,:target_policy=>:cluster,:threat_policy=>:responsive,:skill_policy=>:best_cluster,:range=>3,:basic_damage_category=>:special,:basic_move_type=>:psychic,:target_commitment=>84},
  }
  JOHTO_SPECIAL_BALANCE_RISKS_V0999={
    :meganium=>[:support_stall_ceiling],
    :typhlosion=>[:high_speed_special_burst],
    :feraligatr=>[:sheer_force_physical_burst],
    :lanturn=>[:high_hp_immunity_sustain],
    :pichu=>[:extreme_fragility],
    :togetic=>[:serene_grace_control_chain],
    :xatu=>[:magic_bounce_denial],
    :ampharos=>[:slow_artillery_bodyblock],
    :azumarill=>[:huge_power_physical_spike],
    :politoed=>[:drizzle_weather_centralization],
    :jumpluff=>[:high_speed_control_chain],
    :sunkern=>[:identity_weak_growth_stage],
    :sunflora=>[:slow_special_artillery],
    :yanma=>[:speed_boost_snowball],
    :quagsire=>[:unaware_wall],
    :espeon=>[:high_speed_special_burst],
    :umbreon=>[:extreme_special_wall_stall],
    :murkrow=>[:prankster_control_priority],
    :slowking=>[:regenerator_special_wall],
    :unown=>[:single_move_identity],
    :wobbuffet=>[:counter_mirror_coat_identity,:extreme_hp_reactive_wall],
    :forretress=>[:hazard_wall_stall],
    :dunsparce=>[:serene_grace_rng_chain],
    :steelix=>[:extreme_physical_wall],
    :scizor=>[:technician_priority_pressure],
    :shuckle=>[:extreme_dual_wall,:ultra_low_direct_offense],
    :heracross=>[:guts_moxie_snowball],
    :sneasel=>[:high_speed_assassin,:low_physical_bulk],
    :ursaring=>[:guts_physical_ceiling],
    :corsola=>[:regenerator_sustain_stall],
    :octillery=>[:slow_mixed_artillery],
    :delibird=>[:levelup_movepool_sparse,:present_variance_identity],
    :mantine=>[:extreme_special_wall],
    :skarmory=>[:physical_wall_bodyguard],
    :houndoom=>[:high_speed_special_burst],
    :kingdra=>[:rain_speed_sniper_flex],
    :porygon2=>[:adaptive_wall_download_trace],
    :smeargle=>[:sketch_copy_ceiling,:single_move_identity],
    :hitmontop=>[:intimidate_technician_support],
    :miltank=>[:fast_physical_wall_sustain],
    :blissey=>[:extreme_hp_special_wall,:very_low_physical_defense],
    :raikou=>[:legendary_power_budget,:high_speed_special_burst],
    :entei=>[:legendary_power_budget,:physical_pressure],
    :suicune=>[:legendary_power_budget,:dual_wall_stall],
    :tyranitar=>[:pseudo_legendary_power_budget,:sand_stream_team_warp],
    :lugia=>[:legendary_power_budget,:extreme_dual_bulk],
    :ho_oh=>[:legendary_power_budget,:regenerator_power_ceiling],
    :celebi=>[:mythical_flexible_role_ceiling],
  }
  JOHTO_IDENTITY_NOTES_V0999={
    :unown=>'Hidden Power 是唯一核心招式；不為湊四招新增非原作技能，後續以 Hidden Power 屬性與隊伍定位建立深度。',
    :wobbuffet=>'Counter / Mirror Coat / Safeguard / Destiny Bond 才是核心身份；本輪保留低傷害基本攻擊相容性，專屬反擊 AI／普攻抑制留給 Special Species Runtime，不直接改 Frozen Combat Core。',
    :delibird=>'Level-up 僅 Present 屬刻意稀疏身份；實際養成靠 TM / Tutor / Egg 擴充，不把 Present 的隨機性當作唯一戰力。',
    :smeargle=>'Sketch 才是永久養成核心；未來複製招式必須寫入 instance_uid 對應個體，不提供通用免費 Movepool。',
    :tyrogue=>'分支進化本身就是養成身份；Hitmonlee / Hitmonchan / Hitmontop 的終局 Role 必須保持明顯分歧，不用一套 Fighting Profile 蓋過去。',
    :pichu=>'Volt Tackle 已由 Special Learning source 管理；幼體維持高風險低耐久，不提前抹平與 Pikachu 的成長差。',
    :sunkern=>'刻意保留極弱幼體成長曲線，價值主要來自進化成 Sunflora，不用 Base Stat 補償把成長感消掉。',
  }
  JOHTO_ABILITY_SYNERGY_EXTRA_V0999={
    :leaf_guard=>:sun_status_resist,
    :early_bird=>:sleep_recovery,
    :rattled=>:reactive_speed,
    :iron_fist=>:punch_build,
    :magic_bounce=>:status_hazard_reflect,
    :plus=>:pair_synergy,
    :huge_power=>:physical_multiplier,
    :sap_sipper=>:grass_immunity_pressure,
    :drizzle=>:rain_weather_core,
    :prankster=>:support_priority,
    :shadow_tag=>:target_lock,
    :overcoat=>:weather_powder_resist,
    :hyper_cutter=>:attack_drop_resist,
    :immunity=>:poison_immunity,
    :swift_swim=>:rain_team,
    :contrary=>:stat_inversion_build,
    :pickpocket=>:held_item_disruption,
    :magma_armor=>:freeze_immunity,
    :weak_armor=>:hit_speed_tradeoff,
    :snow_cloak=>:hail_evasion,
    :moody=>:volatile_stat_snowball,
    :suction_cups=>:forced_move_resist,
    :water_veil=>:burn_immunity,
    :own_tempo=>:confusion_immunity,
    :steadfast=>:flinch_speed_payoff,
    :vital_spirit=>:sleep_immunity,
    :sand_stream=>:sand_weather_core,
    :multiscale=>:durability_spike,
    :pressure=>:legendary_endurance,
    :regenerator=>:sustain_rotation,
    :natural_cure=>:status_reset_sustain,
    :scrappy=>:coverage_ignore_ghost,
    :frisk=>:item_scout,
  }
  JOHTO_REVIEW_MANIFEST_V0999={
    :dex_start=>152,:dex_end=>251,:species=>100,:fields=>18,
    :physical=>44,:special=>56,:melee=>43,:ranged=>57,
    :enabled_non_normal_forms=>0,:combat_core_direct_modification=>false,
    :previous_reviewed=>151,:reviewed_total=>251,:pending=>243
  }
end
