# encoding: UTF-8
#==============================================================================
# 【PMD AutoChess 中文維護說明】
# 腳本：PMD AutoChess Hoenn Gameplay Review Data v0.99.10
# 分類：Pokémon Gameplay / AI / Balance Review #0252-0386
#
# 【用途】
# - 正式完成 National Dex #0252-0386 共 135 隻 Pokémon 第一輪逐隻 Gameplay Review。
# - 每隻人工指定 Role、Movement / Target / Threat / Skill Policy、普通攻擊距離、
#   屬性與 Physical/Special 類別；Kanto / Johto 已審內容完整保留。
# - 特別審核 Slaking、Nincada/Ninjask/Shedinja、Castform、Deoxys 等特殊身份。
# - Base Stats、Learnset、TM、Tutor、Egg、Ability、Evolution、Team Bond 仍引用既有
#   Production Data；不為平衡竄改 canonical Base Stats。
#
# 【主要設定項】
# HOENN_PROFILE_OVERRIDES_V09910：#0252-0386 共 135 隻人工戰術 Profile。
# HOENN_SPECIAL_BALANCE_RISKS_V09910：特殊平衡風險。
# HOENN_IDENTITY_NOTES_V09910：特殊 Species 身份與不可任意抹平的規則。
# HOENN_ABILITY_SYNERGY_EXTRA_V09910：Hoenn 常見 Ability 戰術標籤。
# HOENN_FORM_REVIEW_PROFILES_V09910：Castform / Deoxys 的 disabled Form 預備 Profile。
#
# 【普通攻擊規則】
# - range=1 為近戰；range=3 為遠程。
# - basic_damage_category 只影響 source_type=:basic 普通攻擊。
# - Skill 自己的 Physical/Special category 完全不改。
# - basic_move_type 必須屬於目前正常型 Species Type。
#
# 【Form 規則】
# - 本版 Hoenn ruleset-enabled 非 Normal Form = 0。
# - Castform Sunny/Rainy/Snowy 與 Deoxys Attack/Defense/Speed 仍先建立 Review Profile，
#   但 forms ruleset_disabled 時只寫入報告，不套 Runtime，不會偷偷啟用 Mega/Primal/Form。
#
# 【AI 規則】
# - Species Profile 是預設 AI；玩家永久 ai_setup 永遠最後套用。
# - 進化後重新套 Species Profile，再恢復玩家 ai_setup。
#
# 【事件／腳本呼叫方式】
# row = PMD_AC.gameplay_review_row_v09910(:slaking)
# profile = PMD_AC.review_profile_for_v09910(:milotic, :normal)
# PMD_AC.write_hoenn_gameplay_review_v09910
#
# 【實際範例】
# Slaking：Normal Physical Berserker/Bruiser，Truant 是 power budget。
# Shedinja：Ghost Physical Assassin，1 HP + Wonder Guard 不以一般坦度公式修平。
# Milotic：Water Special ranged Bodyguard。
# Deoxys Defense：有 Review Profile，但因 form disabled 暫不套 Runtime。
#
# 【維護限制】
# - RPG Maker VX / RGSS2 / Ruby 1.8。
# - 不使用禁止的舊式 instance variable 反射檢查。
# - Actor ID 不是 Pokémon identity；永久個體識別仍為 instance_uid。
# - Frozen Combat Core 不直接修改；本版只追加 Data / Runtime Content Hook。
#==============================================================================
module PMD_AC
  GAMEPLAY_REVIEW_VERSION_V09910='0.99.10'
  HOENN_REVIEW_DEX_RANGE_V09910=(252..386)
  HOENN_REVIEW_STATUS_V09910=:reviewed_manual
  HOENN_PROFILE_OVERRIDES_V09910={
    :treecko=>{:role=>:kiter,:movement_policy=>:kiter,:target_policy=>:nearest,:threat_policy=>:responsive,:skill_policy=>:current_target,:range=>3,:basic_damage_category=>:special,:basic_move_type=>:grass,:target_commitment=>56},
    :grovyle=>{:role=>:kiter,:movement_policy=>:kiter,:target_policy=>:execute,:threat_policy=>:responsive,:skill_policy=>:execute,:range=>3,:basic_damage_category=>:special,:basic_move_type=>:grass,:target_commitment=>62},
    :sceptile=>{:role=>:kiter,:movement_policy=>:kiter,:target_policy=>:execute,:threat_policy=>:responsive,:skill_policy=>:execute,:range=>3,:basic_damage_category=>:special,:basic_move_type=>:grass,:target_commitment=>68},
    :torchic=>{:role=>:kiter,:movement_policy=>:kiter,:target_policy=>:nearest,:threat_policy=>:responsive,:skill_policy=>:current_target,:range=>3,:basic_damage_category=>:special,:basic_move_type=>:fire,:target_commitment=>52},
    :combusken=>{:role=>:bruiser,:movement_policy=>:bruiser,:target_policy=>:execute,:threat_policy=>:normal,:skill_policy=>:execute,:range=>1,:basic_damage_category=>:physical,:basic_move_type=>:fighting,:target_commitment=>72},
    :blaziken=>{:role=>:bruiser,:movement_policy=>:berserker,:target_policy=>:execute,:threat_policy=>:ignore_minor,:skill_policy=>:execute,:range=>1,:basic_damage_category=>:physical,:basic_move_type=>:fighting,:target_commitment=>88},
    :mudkip=>{:role=>:frontline,:movement_policy=>:frontline,:target_policy=>:melee_first,:threat_policy=>:hold_ground,:skill_policy=>:current_target,:range=>1,:basic_damage_category=>:physical,:basic_move_type=>:water,:target_commitment=>76},
    :marshtomp=>{:role=>:frontline,:movement_policy=>:frontline,:target_policy=>:melee_first,:threat_policy=>:hold_ground,:skill_policy=>:current_target,:range=>1,:basic_damage_category=>:physical,:basic_move_type=>:ground,:target_commitment=>84},
    :swampert=>{:role=>:bodyguard,:movement_policy=>:bodyguard,:target_policy=>:protect_ally,:threat_policy=>:protective,:skill_policy=>:protect_ally,:range=>1,:basic_damage_category=>:physical,:basic_move_type=>:ground,:target_commitment=>94},
    :poochyena=>{:role=>:assassin,:movement_policy=>:assassin,:target_policy=>:backline_low_def,:threat_policy=>:ignore_minor,:skill_policy=>:execute,:range=>1,:basic_damage_category=>:physical,:basic_move_type=>:dark,:target_commitment=>68},
    :mightyena=>{:role=>:bruiser,:movement_policy=>:bruiser,:target_policy=>:execute,:threat_policy=>:normal,:skill_policy=>:execute,:range=>1,:basic_damage_category=>:physical,:basic_move_type=>:dark,:target_commitment=>80},
    :zigzagoon=>{:role=>:controller,:movement_policy=>:controller,:target_policy=>:cluster,:threat_policy=>:responsive,:skill_policy=>:best_cluster,:range=>1,:basic_damage_category=>:physical,:basic_move_type=>:normal,:target_commitment=>50},
    :linoone=>{:role=>:assassin,:movement_policy=>:assassin,:target_policy=>:backline_low_def,:threat_policy=>:ignore_minor,:skill_policy=>:execute,:range=>1,:basic_damage_category=>:physical,:basic_move_type=>:normal,:target_commitment=>82},
    :wurmple=>{:role=>:controller,:movement_policy=>:controller,:target_policy=>:highest_atk,:threat_policy=>:responsive,:skill_policy=>:highest_atk,:range=>3,:basic_damage_category=>:physical,:basic_move_type=>:bug,:target_commitment=>46},
    :silcoon=>{:role=>:frontline,:movement_policy=>:frontline,:target_policy=>:nearest,:threat_policy=>:hold_ground,:skill_policy=>:current_target,:range=>1,:basic_damage_category=>:physical,:basic_move_type=>:bug,:target_commitment=>90},
    :beautifly=>{:role=>:artillery,:movement_policy=>:artillery,:target_policy=>:lowest_def,:threat_policy=>:responsive,:skill_policy=>:lowest_def,:range=>3,:basic_damage_category=>:special,:basic_move_type=>:bug,:target_commitment=>66},
    :cascoon=>{:role=>:frontline,:movement_policy=>:frontline,:target_policy=>:nearest,:threat_policy=>:hold_ground,:skill_policy=>:current_target,:range=>1,:basic_damage_category=>:physical,:basic_move_type=>:bug,:target_commitment=>90},
    :dustox=>{:role=>:controller,:movement_policy=>:controller,:target_policy=>:cluster,:threat_policy=>:responsive,:skill_policy=>:best_cluster,:range=>3,:basic_damage_category=>:special,:basic_move_type=>:poison,:target_commitment=>78},
    :lotad=>{:role=>:controller,:movement_policy=>:controller,:target_policy=>:cluster,:threat_policy=>:responsive,:skill_policy=>:best_cluster,:range=>3,:basic_damage_category=>:special,:basic_move_type=>:water,:target_commitment=>54},
    :lombre=>{:role=>:controller,:movement_policy=>:controller,:target_policy=>:cluster,:threat_policy=>:responsive,:skill_policy=>:best_cluster,:range=>3,:basic_damage_category=>:special,:basic_move_type=>:water,:target_commitment=>62},
    :ludicolo=>{:role=>:bodyguard,:movement_policy=>:bodyguard,:target_policy=>:protect_ally,:threat_policy=>:protective,:skill_policy=>:heal_critical,:range=>3,:basic_damage_category=>:special,:basic_move_type=>:water,:target_commitment=>88},
    :seedot=>{:role=>:frontline,:movement_policy=>:frontline,:target_policy=>:melee_first,:threat_policy=>:hold_ground,:skill_policy=>:current_target,:range=>1,:basic_damage_category=>:physical,:basic_move_type=>:grass,:target_commitment=>72},
    :nuzleaf=>{:role=>:bruiser,:movement_policy=>:bruiser,:target_policy=>:execute,:threat_policy=>:normal,:skill_policy=>:execute,:range=>1,:basic_damage_category=>:physical,:basic_move_type=>:dark,:target_commitment=>76},
    :shiftry=>{:role=>:assassin,:movement_policy=>:assassin,:target_policy=>:backline_low_def,:threat_policy=>:ignore_minor,:skill_policy=>:execute,:range=>1,:basic_damage_category=>:physical,:basic_move_type=>:dark,:target_commitment=>86},
    :taillow=>{:role=>:assassin,:movement_policy=>:assassin,:target_policy=>:backline_low_def,:threat_policy=>:ignore_minor,:skill_policy=>:execute,:range=>1,:basic_damage_category=>:physical,:basic_move_type=>:flying,:target_commitment=>80},
    :swellow=>{:role=>:assassin,:movement_policy=>:assassin,:target_policy=>:backline_low_def,:threat_policy=>:ignore_minor,:skill_policy=>:execute,:range=>1,:basic_damage_category=>:physical,:basic_move_type=>:flying,:target_commitment=>92},
    :wingull=>{:role=>:kiter,:movement_policy=>:kiter,:target_policy=>:nearest,:threat_policy=>:responsive,:skill_policy=>:current_target,:range=>3,:basic_damage_category=>:special,:basic_move_type=>:water,:target_commitment=>54},
    :pelipper=>{:role=>:bodyguard,:movement_policy=>:bodyguard,:target_policy=>:protect_ally,:threat_policy=>:protective,:skill_policy=>:protect_ally,:range=>3,:basic_damage_category=>:special,:basic_move_type=>:water,:target_commitment=>90},
    :ralts=>{:role=>:controller,:movement_policy=>:controller,:target_policy=>:highest_atk,:threat_policy=>:responsive,:skill_policy=>:highest_atk,:range=>3,:basic_damage_category=>:special,:basic_move_type=>:psychic,:target_commitment=>48},
    :kirlia=>{:role=>:controller,:movement_policy=>:controller,:target_policy=>:highest_atk,:threat_policy=>:responsive,:skill_policy=>:highest_atk,:range=>3,:basic_damage_category=>:special,:basic_move_type=>:psychic,:target_commitment=>58},
    :gardevoir=>{:role=>:artillery,:movement_policy=>:artillery,:target_policy=>:lowest_def,:threat_policy=>:responsive,:skill_policy=>:lowest_def,:range=>3,:basic_damage_category=>:special,:basic_move_type=>:psychic,:target_commitment=>76},
    :surskit=>{:role=>:controller,:movement_policy=>:controller,:target_policy=>:cluster,:threat_policy=>:responsive,:skill_policy=>:best_cluster,:range=>3,:basic_damage_category=>:special,:basic_move_type=>:water,:target_commitment=>54},
    :masquerain=>{:role=>:controller,:movement_policy=>:controller,:target_policy=>:cluster,:threat_policy=>:responsive,:skill_policy=>:best_cluster,:range=>3,:basic_damage_category=>:special,:basic_move_type=>:bug,:target_commitment=>70},
    :shroomish=>{:role=>:controller,:movement_policy=>:controller,:target_policy=>:highest_atk,:threat_policy=>:responsive,:skill_policy=>:highest_atk,:range=>3,:basic_damage_category=>:special,:basic_move_type=>:grass,:target_commitment=>64},
    :breloom=>{:role=>:bruiser,:movement_policy=>:berserker,:target_policy=>:execute,:threat_policy=>:ignore_minor,:skill_policy=>:execute,:range=>1,:basic_damage_category=>:physical,:basic_move_type=>:fighting,:target_commitment=>86},
    :slakoth=>{:role=>:frontline,:movement_policy=>:frontline,:target_policy=>:nearest,:threat_policy=>:hold_ground,:skill_policy=>:current_target,:range=>1,:basic_damage_category=>:physical,:basic_move_type=>:normal,:target_commitment=>88},
    :vigoroth=>{:role=>:assassin,:movement_policy=>:assassin,:target_policy=>:backline_low_def,:threat_policy=>:ignore_minor,:skill_policy=>:execute,:range=>1,:basic_damage_category=>:physical,:basic_move_type=>:normal,:target_commitment=>84},
    :slaking=>{:role=>:bruiser,:movement_policy=>:berserker,:target_policy=>:execute,:threat_policy=>:ignore_minor,:skill_policy=>:execute,:range=>1,:basic_damage_category=>:physical,:basic_move_type=>:normal,:target_commitment=>98},
    :nincada=>{:role=>:frontline,:movement_policy=>:frontline,:target_policy=>:melee_first,:threat_policy=>:hold_ground,:skill_policy=>:current_target,:range=>1,:basic_damage_category=>:physical,:basic_move_type=>:ground,:target_commitment=>84},
    :ninjask=>{:role=>:assassin,:movement_policy=>:assassin,:target_policy=>:backline_low_def,:threat_policy=>:ignore_minor,:skill_policy=>:execute,:range=>1,:basic_damage_category=>:physical,:basic_move_type=>:bug,:target_commitment=>94},
    :shedinja=>{:role=>:assassin,:movement_policy=>:assassin,:target_policy=>:backline_low_def,:threat_policy=>:ignore_minor,:skill_policy=>:execute,:range=>1,:basic_damage_category=>:physical,:basic_move_type=>:ghost,:target_commitment=>74},
    :whismur=>{:role=>:artillery,:movement_policy=>:artillery,:target_policy=>:cluster,:threat_policy=>:responsive,:skill_policy=>:best_cluster,:range=>3,:basic_damage_category=>:special,:basic_move_type=>:normal,:target_commitment=>54},
    :loudred=>{:role=>:artillery,:movement_policy=>:artillery,:target_policy=>:cluster,:threat_policy=>:responsive,:skill_policy=>:best_cluster,:range=>3,:basic_damage_category=>:special,:basic_move_type=>:normal,:target_commitment=>64},
    :exploud=>{:role=>:artillery,:movement_policy=>:artillery,:target_policy=>:cluster,:threat_policy=>:hold_ground,:skill_policy=>:best_cluster,:range=>3,:basic_damage_category=>:special,:basic_move_type=>:normal,:target_commitment=>78},
    :makuhita=>{:role=>:frontline,:movement_policy=>:frontline,:target_policy=>:melee_first,:threat_policy=>:hold_ground,:skill_policy=>:current_target,:range=>1,:basic_damage_category=>:physical,:basic_move_type=>:fighting,:target_commitment=>86},
    :hariyama=>{:role=>:bodyguard,:movement_policy=>:bodyguard,:target_policy=>:protect_ally,:threat_policy=>:protective,:skill_policy=>:protect_ally,:range=>1,:basic_damage_category=>:physical,:basic_move_type=>:fighting,:target_commitment=>94},
    :azurill=>{:role=>:bodyguard,:movement_policy=>:bodyguard,:target_policy=>:protect_ally,:threat_policy=>:protective,:skill_policy=>:heal_critical,:range=>1,:basic_damage_category=>:physical,:basic_move_type=>:fairy,:target_commitment=>70},
    :nosepass=>{:role=>:bodyguard,:movement_policy=>:bodyguard,:target_policy=>:protect_ally,:threat_policy=>:protective,:skill_policy=>:protect_ally,:range=>1,:basic_damage_category=>:physical,:basic_move_type=>:rock,:target_commitment=>98},
    :skitty=>{:role=>:controller,:movement_policy=>:controller,:target_policy=>:highest_atk,:threat_policy=>:responsive,:skill_policy=>:highest_atk,:range=>1,:basic_damage_category=>:physical,:basic_move_type=>:normal,:target_commitment=>58},
    :delcatty=>{:role=>:controller,:movement_policy=>:controller,:target_policy=>:cluster,:threat_policy=>:responsive,:skill_policy=>:best_cluster,:range=>1,:basic_damage_category=>:physical,:basic_move_type=>:normal,:target_commitment=>68},
    :sableye=>{:role=>:controller,:movement_policy=>:controller,:target_policy=>:highest_atk,:threat_policy=>:responsive,:skill_policy=>:highest_atk,:range=>1,:basic_damage_category=>:physical,:basic_move_type=>:dark,:target_commitment=>82},
    :mawile=>{:role=>:bodyguard,:movement_policy=>:bodyguard,:target_policy=>:protect_ally,:threat_policy=>:protective,:skill_policy=>:protect_ally,:range=>1,:basic_damage_category=>:physical,:basic_move_type=>:steel,:target_commitment=>90},
    :aron=>{:role=>:frontline,:movement_policy=>:frontline,:target_policy=>:melee_first,:threat_policy=>:hold_ground,:skill_policy=>:current_target,:range=>1,:basic_damage_category=>:physical,:basic_move_type=>:steel,:target_commitment=>82},
    :lairon=>{:role=>:frontline,:movement_policy=>:frontline,:target_policy=>:melee_first,:threat_policy=>:hold_ground,:skill_policy=>:current_target,:range=>1,:basic_damage_category=>:physical,:basic_move_type=>:steel,:target_commitment=>90},
    :aggron=>{:role=>:bodyguard,:movement_policy=>:bodyguard,:target_policy=>:protect_ally,:threat_policy=>:protective,:skill_policy=>:protect_ally,:range=>1,:basic_damage_category=>:physical,:basic_move_type=>:steel,:target_commitment=>98},
    :meditite=>{:role=>:bruiser,:movement_policy=>:bruiser,:target_policy=>:execute,:threat_policy=>:normal,:skill_policy=>:execute,:range=>1,:basic_damage_category=>:physical,:basic_move_type=>:fighting,:target_commitment=>74},
    :medicham=>{:role=>:assassin,:movement_policy=>:assassin,:target_policy=>:backline_low_def,:threat_policy=>:ignore_minor,:skill_policy=>:execute,:range=>1,:basic_damage_category=>:physical,:basic_move_type=>:fighting,:target_commitment=>86},
    :electrike=>{:role=>:kiter,:movement_policy=>:kiter,:target_policy=>:nearest,:threat_policy=>:responsive,:skill_policy=>:current_target,:range=>3,:basic_damage_category=>:special,:basic_move_type=>:electric,:target_commitment=>56},
    :manectric=>{:role=>:kiter,:movement_policy=>:kiter,:target_policy=>:execute,:threat_policy=>:responsive,:skill_policy=>:execute,:range=>3,:basic_damage_category=>:special,:basic_move_type=>:electric,:target_commitment=>68},
    :plusle=>{:role=>:controller,:movement_policy=>:controller,:target_policy=>:cluster,:threat_policy=>:responsive,:skill_policy=>:best_cluster,:range=>3,:basic_damage_category=>:special,:basic_move_type=>:electric,:target_commitment=>68},
    :minun=>{:role=>:bodyguard,:movement_policy=>:bodyguard,:target_policy=>:protect_ally,:threat_policy=>:protective,:skill_policy=>:heal_critical,:range=>3,:basic_damage_category=>:special,:basic_move_type=>:electric,:target_commitment=>84},
    :volbeat=>{:role=>:controller,:movement_policy=>:controller,:target_policy=>:highest_atk,:threat_policy=>:responsive,:skill_policy=>:highest_atk,:range=>1,:basic_damage_category=>:physical,:basic_move_type=>:bug,:target_commitment=>72},
    :illumise=>{:role=>:controller,:movement_policy=>:controller,:target_policy=>:cluster,:threat_policy=>:responsive,:skill_policy=>:best_cluster,:range=>3,:basic_damage_category=>:special,:basic_move_type=>:bug,:target_commitment=>72},
    :roselia=>{:role=>:controller,:movement_policy=>:controller,:target_policy=>:cluster,:threat_policy=>:responsive,:skill_policy=>:best_cluster,:range=>3,:basic_damage_category=>:special,:basic_move_type=>:grass,:target_commitment=>72},
    :gulpin=>{:role=>:controller,:movement_policy=>:controller,:target_policy=>:highest_atk,:threat_policy=>:responsive,:skill_policy=>:highest_atk,:range=>3,:basic_damage_category=>:special,:basic_move_type=>:poison,:target_commitment=>72},
    :swalot=>{:role=>:bodyguard,:movement_policy=>:bodyguard,:target_policy=>:protect_ally,:threat_policy=>:protective,:skill_policy=>:protect_ally,:range=>3,:basic_damage_category=>:special,:basic_move_type=>:poison,:target_commitment=>90},
    :carvanha=>{:role=>:assassin,:movement_policy=>:assassin,:target_policy=>:backline_low_def,:threat_policy=>:ignore_minor,:skill_policy=>:execute,:range=>1,:basic_damage_category=>:physical,:basic_move_type=>:dark,:target_commitment=>84},
    :sharpedo=>{:role=>:assassin,:movement_policy=>:assassin,:target_policy=>:backline_low_def,:threat_policy=>:ignore_minor,:skill_policy=>:execute,:range=>1,:basic_damage_category=>:physical,:basic_move_type=>:dark,:target_commitment=>90},
    :wailmer=>{:role=>:artillery,:movement_policy=>:artillery,:target_policy=>:cluster,:threat_policy=>:hold_ground,:skill_policy=>:best_cluster,:range=>3,:basic_damage_category=>:special,:basic_move_type=>:water,:target_commitment=>76},
    :wailord=>{:role=>:bodyguard,:movement_policy=>:bodyguard,:target_policy=>:protect_ally,:threat_policy=>:protective,:skill_policy=>:protect_ally,:range=>3,:basic_damage_category=>:special,:basic_move_type=>:water,:target_commitment=>94},
    :numel=>{:role=>:artillery,:movement_policy=>:artillery,:target_policy=>:lowest_def,:threat_policy=>:hold_ground,:skill_policy=>:lowest_def,:range=>3,:basic_damage_category=>:special,:basic_move_type=>:fire,:target_commitment=>68},
    :camerupt=>{:role=>:artillery,:movement_policy=>:artillery,:target_policy=>:cluster,:threat_policy=>:hold_ground,:skill_policy=>:best_cluster,:range=>3,:basic_damage_category=>:special,:basic_move_type=>:fire,:target_commitment=>82},
    :torkoal=>{:role=>:bodyguard,:movement_policy=>:bodyguard,:target_policy=>:protect_ally,:threat_policy=>:protective,:skill_policy=>:protect_ally,:range=>3,:basic_damage_category=>:special,:basic_move_type=>:fire,:target_commitment=>98},
    :spoink=>{:role=>:controller,:movement_policy=>:controller,:target_policy=>:highest_atk,:threat_policy=>:responsive,:skill_policy=>:highest_atk,:range=>3,:basic_damage_category=>:special,:basic_move_type=>:psychic,:target_commitment=>62},
    :grumpig=>{:role=>:bodyguard,:movement_policy=>:bodyguard,:target_policy=>:protect_ally,:threat_policy=>:protective,:skill_policy=>:heal_critical,:range=>3,:basic_damage_category=>:special,:basic_move_type=>:psychic,:target_commitment=>90},
    :spinda=>{:role=>:controller,:movement_policy=>:controller,:target_policy=>:cluster,:threat_policy=>:responsive,:skill_policy=>:best_cluster,:range=>1,:basic_damage_category=>:physical,:basic_move_type=>:normal,:target_commitment=>66},
    :trapinch=>{:role=>:frontline,:movement_policy=>:frontline,:target_policy=>:highest_atk,:threat_policy=>:hold_ground,:skill_policy=>:highest_atk,:range=>1,:basic_damage_category=>:physical,:basic_move_type=>:ground,:target_commitment=>88},
    :vibrava=>{:role=>:kiter,:movement_policy=>:kiter,:target_policy=>:execute,:threat_policy=>:responsive,:skill_policy=>:execute,:range=>3,:basic_damage_category=>:physical,:basic_move_type=>:ground,:target_commitment=>64},
    :flygon=>{:role=>:assassin,:movement_policy=>:assassin,:target_policy=>:backline_low_def,:threat_policy=>:ignore_minor,:skill_policy=>:execute,:range=>1,:basic_damage_category=>:physical,:basic_move_type=>:dragon,:target_commitment=>86},
    :cacnea=>{:role=>:artillery,:movement_policy=>:artillery,:target_policy=>:lowest_def,:threat_policy=>:responsive,:skill_policy=>:lowest_def,:range=>3,:basic_damage_category=>:special,:basic_move_type=>:grass,:target_commitment=>68},
    :cacturne=>{:role=>:artillery,:movement_policy=>:artillery,:target_policy=>:backline_low_def,:threat_policy=>:responsive,:skill_policy=>:execute,:range=>3,:basic_damage_category=>:special,:basic_move_type=>:dark,:target_commitment=>80},
    :swablu=>{:role=>:bodyguard,:movement_policy=>:bodyguard,:target_policy=>:protect_ally,:threat_policy=>:protective,:skill_policy=>:heal_critical,:range=>3,:basic_damage_category=>:special,:basic_move_type=>:flying,:target_commitment=>82},
    :altaria=>{:role=>:bodyguard,:movement_policy=>:bodyguard,:target_policy=>:protect_ally,:threat_policy=>:protective,:skill_policy=>:heal_critical,:range=>3,:basic_damage_category=>:special,:basic_move_type=>:dragon,:target_commitment=>94},
    :zangoose=>{:role=>:assassin,:movement_policy=>:assassin,:target_policy=>:backline_low_def,:threat_policy=>:ignore_minor,:skill_policy=>:execute,:range=>1,:basic_damage_category=>:physical,:basic_move_type=>:normal,:target_commitment=>88},
    :seviper=>{:role=>:controller,:movement_policy=>:controller,:target_policy=>:highest_atk,:threat_policy=>:responsive,:skill_policy=>:highest_atk,:range=>3,:basic_damage_category=>:special,:basic_move_type=>:poison,:target_commitment=>78},
    :lunatone=>{:role=>:artillery,:movement_policy=>:artillery,:target_policy=>:lowest_def,:threat_policy=>:responsive,:skill_policy=>:lowest_def,:range=>3,:basic_damage_category=>:special,:basic_move_type=>:psychic,:target_commitment=>80},
    :solrock=>{:role=>:bruiser,:movement_policy=>:bruiser,:target_policy=>:execute,:threat_policy=>:normal,:skill_policy=>:execute,:range=>1,:basic_damage_category=>:physical,:basic_move_type=>:rock,:target_commitment=>82},
    :barboach=>{:role=>:controller,:movement_policy=>:controller,:target_policy=>:cluster,:threat_policy=>:responsive,:skill_policy=>:best_cluster,:range=>3,:basic_damage_category=>:special,:basic_move_type=>:water,:target_commitment=>64},
    :whiscash=>{:role=>:bodyguard,:movement_policy=>:bodyguard,:target_policy=>:protect_ally,:threat_policy=>:protective,:skill_policy=>:protect_ally,:range=>1,:basic_damage_category=>:physical,:basic_move_type=>:ground,:target_commitment=>94},
    :corphish=>{:role=>:bruiser,:movement_policy=>:bruiser,:target_policy=>:execute,:threat_policy=>:normal,:skill_policy=>:execute,:range=>1,:basic_damage_category=>:physical,:basic_move_type=>:water,:target_commitment=>76},
    :crawdaunt=>{:role=>:bruiser,:movement_policy=>:berserker,:target_policy=>:execute,:threat_policy=>:ignore_minor,:skill_policy=>:execute,:range=>1,:basic_damage_category=>:physical,:basic_move_type=>:dark,:target_commitment=>88},
    :baltoy=>{:role=>:controller,:movement_policy=>:controller,:target_policy=>:highest_atk,:threat_policy=>:responsive,:skill_policy=>:highest_atk,:range=>3,:basic_damage_category=>:special,:basic_move_type=>:psychic,:target_commitment=>72},
    :claydol=>{:role=>:bodyguard,:movement_policy=>:bodyguard,:target_policy=>:protect_ally,:threat_policy=>:protective,:skill_policy=>:protect_ally,:range=>3,:basic_damage_category=>:special,:basic_move_type=>:psychic,:target_commitment=>96},
    :lileep=>{:role=>:bodyguard,:movement_policy=>:bodyguard,:target_policy=>:protect_ally,:threat_policy=>:protective,:skill_policy=>:heal_critical,:range=>3,:basic_damage_category=>:special,:basic_move_type=>:grass,:target_commitment=>94},
    :cradily=>{:role=>:bodyguard,:movement_policy=>:bodyguard,:target_policy=>:protect_ally,:threat_policy=>:protective,:skill_policy=>:heal_critical,:range=>3,:basic_damage_category=>:special,:basic_move_type=>:grass,:target_commitment=>98},
    :anorith=>{:role=>:assassin,:movement_policy=>:assassin,:target_policy=>:backline_low_def,:threat_policy=>:ignore_minor,:skill_policy=>:execute,:range=>1,:basic_damage_category=>:physical,:basic_move_type=>:bug,:target_commitment=>80},
    :armaldo=>{:role=>:bruiser,:movement_policy=>:bruiser,:target_policy=>:execute,:threat_policy=>:normal,:skill_policy=>:execute,:range=>1,:basic_damage_category=>:physical,:basic_move_type=>:rock,:target_commitment=>90},
    :feebas=>{:role=>:kiter,:movement_policy=>:kiter,:target_policy=>:nearest,:threat_policy=>:responsive,:skill_policy=>:current_target,:range=>3,:basic_damage_category=>:special,:basic_move_type=>:water,:target_commitment=>42},
    :milotic=>{:role=>:bodyguard,:movement_policy=>:bodyguard,:target_policy=>:protect_ally,:threat_policy=>:protective,:skill_policy=>:heal_critical,:range=>3,:basic_damage_category=>:special,:basic_move_type=>:water,:target_commitment=>98},
    :castform=>{:role=>:controller,:movement_policy=>:controller,:target_policy=>:cluster,:threat_policy=>:responsive,:skill_policy=>:best_cluster,:range=>3,:basic_damage_category=>:special,:basic_move_type=>:normal,:target_commitment=>72},
    :kecleon=>{:role=>:controller,:movement_policy=>:frontline,:target_policy=>:highest_atk,:threat_policy=>:hold_ground,:skill_policy=>:highest_atk,:range=>1,:basic_damage_category=>:physical,:basic_move_type=>:normal,:target_commitment=>86},
    :shuppet=>{:role=>:assassin,:movement_policy=>:assassin,:target_policy=>:backline_low_def,:threat_policy=>:ignore_minor,:skill_policy=>:execute,:range=>1,:basic_damage_category=>:physical,:basic_move_type=>:ghost,:target_commitment=>76},
    :banette=>{:role=>:assassin,:movement_policy=>:assassin,:target_policy=>:backline_low_def,:threat_policy=>:ignore_minor,:skill_policy=>:execute,:range=>1,:basic_damage_category=>:physical,:basic_move_type=>:ghost,:target_commitment=>88},
    :duskull=>{:role=>:bodyguard,:movement_policy=>:bodyguard,:target_policy=>:protect_ally,:threat_policy=>:protective,:skill_policy=>:protect_ally,:range=>1,:basic_damage_category=>:physical,:basic_move_type=>:ghost,:target_commitment=>94},
    :dusclops=>{:role=>:bodyguard,:movement_policy=>:bodyguard,:target_policy=>:protect_ally,:threat_policy=>:protective,:skill_policy=>:protect_ally,:range=>1,:basic_damage_category=>:physical,:basic_move_type=>:ghost,:target_commitment=>100},
    :tropius=>{:role=>:bodyguard,:movement_policy=>:bodyguard,:target_policy=>:protect_ally,:threat_policy=>:protective,:skill_policy=>:heal_critical,:range=>3,:basic_damage_category=>:special,:basic_move_type=>:grass,:target_commitment=>92},
    :chimecho=>{:role=>:bodyguard,:movement_policy=>:bodyguard,:target_policy=>:protect_ally,:threat_policy=>:protective,:skill_policy=>:heal_critical,:range=>3,:basic_damage_category=>:special,:basic_move_type=>:psychic,:target_commitment=>92},
    :absol=>{:role=>:assassin,:movement_policy=>:assassin,:target_policy=>:backline_low_def,:threat_policy=>:ignore_minor,:skill_policy=>:execute,:range=>1,:basic_damage_category=>:physical,:basic_move_type=>:dark,:target_commitment=>90},
    :wynaut=>{:role=>:bodyguard,:movement_policy=>:bodyguard,:target_policy=>:protect_ally,:threat_policy=>:protective,:skill_policy=>:protect_ally,:range=>1,:basic_damage_category=>:physical,:basic_move_type=>:psychic,:target_commitment=>98},
    :snorunt=>{:role=>:controller,:movement_policy=>:controller,:target_policy=>:cluster,:threat_policy=>:responsive,:skill_policy=>:best_cluster,:range=>3,:basic_damage_category=>:special,:basic_move_type=>:ice,:target_commitment=>60},
    :glalie=>{:role=>:controller,:movement_policy=>:controller,:target_policy=>:cluster,:threat_policy=>:responsive,:skill_policy=>:best_cluster,:range=>3,:basic_damage_category=>:special,:basic_move_type=>:ice,:target_commitment=>78},
    :spheal=>{:role=>:bodyguard,:movement_policy=>:bodyguard,:target_policy=>:protect_ally,:threat_policy=>:protective,:skill_policy=>:heal_critical,:range=>3,:basic_damage_category=>:special,:basic_move_type=>:water,:target_commitment=>86},
    :sealeo=>{:role=>:bodyguard,:movement_policy=>:bodyguard,:target_policy=>:protect_ally,:threat_policy=>:protective,:skill_policy=>:heal_critical,:range=>3,:basic_damage_category=>:special,:basic_move_type=>:water,:target_commitment=>92},
    :walrein=>{:role=>:bodyguard,:movement_policy=>:bodyguard,:target_policy=>:protect_ally,:threat_policy=>:protective,:skill_policy=>:protect_ally,:range=>3,:basic_damage_category=>:special,:basic_move_type=>:ice,:target_commitment=>98},
    :clamperl=>{:role=>:artillery,:movement_policy=>:artillery,:target_policy=>:lowest_def,:threat_policy=>:hold_ground,:skill_policy=>:lowest_def,:range=>3,:basic_damage_category=>:special,:basic_move_type=>:water,:target_commitment=>84},
    :huntail=>{:role=>:bruiser,:movement_policy=>:bruiser,:target_policy=>:execute,:threat_policy=>:normal,:skill_policy=>:execute,:range=>1,:basic_damage_category=>:physical,:basic_move_type=>:water,:target_commitment=>84},
    :gorebyss=>{:role=>:artillery,:movement_policy=>:artillery,:target_policy=>:lowest_def,:threat_policy=>:responsive,:skill_policy=>:lowest_def,:range=>3,:basic_damage_category=>:special,:basic_move_type=>:water,:target_commitment=>84},
    :relicanth=>{:role=>:frontline,:movement_policy=>:frontline,:target_policy=>:melee_first,:threat_policy=>:hold_ground,:skill_policy=>:current_target,:range=>1,:basic_damage_category=>:physical,:basic_move_type=>:rock,:target_commitment=>96},
    :luvdisc=>{:role=>:kiter,:movement_policy=>:kiter,:target_policy=>:lowest_hp_percent,:threat_policy=>:responsive,:skill_policy=>:current_target,:range=>3,:basic_damage_category=>:special,:basic_move_type=>:water,:target_commitment=>56},
    :bagon=>{:role=>:bruiser,:movement_policy=>:bruiser,:target_policy=>:execute,:threat_policy=>:normal,:skill_policy=>:execute,:range=>1,:basic_damage_category=>:physical,:basic_move_type=>:dragon,:target_commitment=>70},
    :shelgon=>{:role=>:frontline,:movement_policy=>:frontline,:target_policy=>:melee_first,:threat_policy=>:hold_ground,:skill_policy=>:current_target,:range=>1,:basic_damage_category=>:physical,:basic_move_type=>:dragon,:target_commitment=>90},
    :salamence=>{:role=>:assassin,:movement_policy=>:assassin,:target_policy=>:backline_low_def,:threat_policy=>:ignore_minor,:skill_policy=>:execute,:range=>1,:basic_damage_category=>:physical,:basic_move_type=>:dragon,:target_commitment=>92},
    :beldum=>{:role=>:frontline,:movement_policy=>:frontline,:target_policy=>:nearest,:threat_policy=>:hold_ground,:skill_policy=>:current_target,:range=>1,:basic_damage_category=>:physical,:basic_move_type=>:steel,:target_commitment=>92},
    :metang=>{:role=>:frontline,:movement_policy=>:frontline,:target_policy=>:melee_first,:threat_policy=>:hold_ground,:skill_policy=>:current_target,:range=>1,:basic_damage_category=>:physical,:basic_move_type=>:steel,:target_commitment=>94},
    :metagross=>{:role=>:bodyguard,:movement_policy=>:bodyguard,:target_policy=>:protect_ally,:threat_policy=>:protective,:skill_policy=>:protect_ally,:range=>1,:basic_damage_category=>:physical,:basic_move_type=>:steel,:target_commitment=>98},
    :regirock=>{:role=>:frontline,:movement_policy=>:frontline,:target_policy=>:highest_atk,:threat_policy=>:hold_ground,:skill_policy=>:highest_atk,:range=>1,:basic_damage_category=>:physical,:basic_move_type=>:rock,:target_commitment=>100},
    :regice=>{:role=>:bodyguard,:movement_policy=>:bodyguard,:target_policy=>:protect_ally,:threat_policy=>:protective,:skill_policy=>:protect_ally,:range=>3,:basic_damage_category=>:special,:basic_move_type=>:ice,:target_commitment=>100},
    :registeel=>{:role=>:bodyguard,:movement_policy=>:bodyguard,:target_policy=>:protect_ally,:threat_policy=>:protective,:skill_policy=>:protect_ally,:range=>1,:basic_damage_category=>:physical,:basic_move_type=>:steel,:target_commitment=>100},
    :latias=>{:role=>:bodyguard,:movement_policy=>:bodyguard,:target_policy=>:protect_ally,:threat_policy=>:protective,:skill_policy=>:heal_critical,:range=>3,:basic_damage_category=>:special,:basic_move_type=>:psychic,:target_commitment=>98},
    :latios=>{:role=>:artillery,:movement_policy=>:artillery,:target_policy=>:lowest_def,:threat_policy=>:responsive,:skill_policy=>:lowest_def,:range=>3,:basic_damage_category=>:special,:basic_move_type=>:dragon,:target_commitment=>88},
    :kyogre=>{:role=>:artillery,:movement_policy=>:artillery,:target_policy=>:cluster,:threat_policy=>:hold_ground,:skill_policy=>:best_cluster,:range=>3,:basic_damage_category=>:special,:basic_move_type=>:water,:target_commitment=>100},
    :groudon=>{:role=>:frontline,:movement_policy=>:berserker,:target_policy=>:highest_atk,:threat_policy=>:hold_ground,:skill_policy=>:highest_atk,:range=>1,:basic_damage_category=>:physical,:basic_move_type=>:ground,:target_commitment=>100},
    :rayquaza=>{:role=>:bruiser,:movement_policy=>:berserker,:target_policy=>:execute,:threat_policy=>:ignore_minor,:skill_policy=>:execute,:range=>1,:basic_damage_category=>:physical,:basic_move_type=>:dragon,:target_commitment=>100},
    :jirachi=>{:role=>:controller,:movement_policy=>:controller,:target_policy=>:cluster,:threat_policy=>:responsive,:skill_policy=>:best_cluster,:range=>3,:basic_damage_category=>:special,:basic_move_type=>:psychic,:target_commitment=>96},
    :deoxys=>{:role=>:artillery,:movement_policy=>:artillery,:target_policy=>:lowest_def,:threat_policy=>:responsive,:skill_policy=>:lowest_def,:range=>3,:basic_damage_category=>:special,:basic_move_type=>:psychic,:target_commitment=>82},
  }
  HOENN_SPECIAL_BALANCE_RISKS_V09910={
    :sceptile=>[:high_speed_special_pressure],
    :blaziken=>[:speed_boost_physical_snowball],
    :swampert=>[:high_bulk_low_weakness_bodyguard],
    :swellow=>[:high_speed_guts_pressure],
    :pelipper=>[:rain_weather_centralization],
    :gardevoir=>[:high_special_burst_support_flex],
    :breloom=>[:spore_plus_physical_burst],
    :slaking=>[:truant_extreme_power_budget],
    :ninjask=>[:extreme_speed_snowball],
    :shedinja=>[:one_hp_wonder_guard_binary_matchup],
    :exploud=>[:sound_aoe_pressure],
    :hariyama=>[:high_hp_physical_pressure],
    :nosepass=>[:extreme_physical_wall],
    :sableye=>[:prankster_disruption_ceiling],
    :mawile=>[:intimidate_control_bulk],
    :aggron=>[:extreme_physical_wall],
    :medicham=>[:pure_power_physical_ceiling],
    :manectric=>[:high_speed_special_pressure],
    :plusle=>[:pair_synergy_dependency],
    :minun=>[:pair_synergy_support_dependency],
    :sharpedo=>[:glass_cannon_assassin],
    :wailord=>[:extreme_hp_low_defense],
    :camerupt=>[:slow_mixed_nuke],
    :torkoal=>[:drought_physical_wall],
    :flygon=>[:high_speed_ground_dragon_pressure],
    :altaria=>[:special_wall_support],
    :zangoose=>[:high_physical_pressure],
    :crawdaunt=>[:high_attack_low_speed_tradeoff],
    :claydol=>[:dual_wall_utility],
    :cradily=>[:sustain_wall_stall],
    :feebas=>[:identity_weak_growth_stage],
    :milotic=>[:marvel_scale_special_wall],
    :castform=>[:weather_form_dependency],
    :kecleon=>[:reactive_type_shift_complexity],
    :dusclops=>[:extreme_dual_wall_low_damage],
    :absol=>[:critical_physical_burst],
    :walrein=>[:dual_bulk_sustain],
    :clamperl=>[:branch_and_item_dependency],
    :salamence=>[:pseudo_legendary_power_budget],
    :beldum=>[:sparse_levelup_identity],
    :metagross=>[:pseudo_legendary_physical_wall],
    :regirock=>[:legendary_extreme_physical_wall],
    :regice=>[:legendary_extreme_special_wall],
    :registeel=>[:legendary_dual_wall],
    :latias=>[:legendary_special_wall_speed],
    :latios=>[:legendary_special_burst_speed],
    :kyogre=>[:legendary_weather_special_ceiling],
    :groudon=>[:legendary_weather_physical_ceiling],
    :rayquaza=>[:legendary_mixed_power_ceiling],
    :jirachi=>[:serene_grace_control_chain],
    :deoxys=>[:form_role_divergence_extreme_stats],
  }
  HOENN_IDENTITY_NOTES_V09910={
    :wurmple=>'Wurmple 的分支進化是身份核心；維持既有隨機分支，不讓玩家用一般四招模板預測成 Beautifly 或 Dustox。',
    :slakoth=>'Truant 從幼體就屬於進化線 power budget 的一部分；不因低階體感而移除。',
    :slaking=>'160 Attack / 150 HP 的極端數值必須由 Truant 約束；既有 Truant Runtime 保留，本輪不繞過停滯回合。',
    :nincada=>'進化時除 Ninjask 外可額外生成 Shedinja；既有 additional_spawn Runtime 保留，個體仍以 instance_uid 分離。',
    :ninjask=>'Speed Boost 與 160 Base Speed 定義其 Assassin 身份；成長強度來自時間而非硬塞額外傷害倍率。',
    :shedinja=>'1 HP + Wonder Guard 是不可拆的身份組合；不以一般坦度公式補 HP，也不削掉 Wonder Guard 來換取報表平滑。',
    :feebas=>'刻意保留極弱幼體與稀疏 Level-up 體驗，價值來自進化成 Milotic；不提前抹平成普通 Water attacker。',
    :castform=>'Forecast / Weather Form 是核心；Sunny/Rainy/Snowy 已建立 Review Profile，但目前 forms ruleset_disabled，因此本版不偷啟用。',
    :kecleon=>'Color Change 是反應式屬性身份；Review 以近戰 Controller 為基底，不把每次變色硬編成固定 Form。',
    :wynaut=>'與 Wobbuffet 共用 Counter / Mirror Coat 身份；基本攻擊抑制與反擊專屬 AI 留給 Special Species Runtime。',
    :clamperl=>'Huntail / Gorebyss 分支必須導向 Physical Bruiser 與 Special Artillery 兩種終局，不用同一 Profile 蓋掉分支價值。',
    :beldum=>'Level-up 身份刻意稀疏，核心從 Take Down 起步，再靠進化與 Tutor 擴張；不為湊四招新增虛構招式。',
    :deoxys=>'Normal 是高速 Special Artillery 基底；Attack / Defense / Speed 三型已做 Review Profile，但 forms ruleset_disabled，暫不套 Runtime。',
  }
  HOENN_ABILITY_SYNERGY_EXTRA_V09910={
    :speed_boost=>:speed_snowball,
    :truant=>:turn_skip_power_budget,
    :wonder_guard=>:selective_damage_immunity,
    :pure_power=>:physical_multiplier,
    :rough_skin=>:contact_punish,
    :white_smoke=>:stat_drop_resist,
    :own_tempo=>:confusion_immunity,
    :levitate=>:ground_immunity_positioning,
    :sand_veil=>:sand_evasion,
    :color_change=>:reactive_type_shift,
    :forecast=>:weather_form_identity,
    :air_lock=>:weather_suppression,
    :normalize=>:type_normalization,
    :hyper_cutter=>:attack_drop_resist,
    :drizzle=>:rain_weather_core,
    :drought=>:sun_weather_core,
    :plus=>:pair_synergy,
    :minus=>:pair_synergy,
    :prankster=>:support_priority,
    :huge_power=>:physical_multiplier,
  }
  HOENN_FORM_REVIEW_PROFILES_V09910={
    [:castform,:sunny]=>{:role=>:artillery,:movement_policy=>:artillery,:target_policy=>:cluster,:threat_policy=>:responsive,:skill_policy=>:best_cluster,:range=>3,:basic_damage_category=>:special,:basic_move_type=>:fire,:target_commitment=>76},
    [:castform,:rainy]=>{:role=>:artillery,:movement_policy=>:artillery,:target_policy=>:cluster,:threat_policy=>:responsive,:skill_policy=>:best_cluster,:range=>3,:basic_damage_category=>:special,:basic_move_type=>:water,:target_commitment=>76},
    [:castform,:snowy]=>{:role=>:controller,:movement_policy=>:controller,:target_policy=>:cluster,:threat_policy=>:responsive,:skill_policy=>:best_cluster,:range=>3,:basic_damage_category=>:special,:basic_move_type=>:ice,:target_commitment=>76},
    [:deoxys,:attack]=>{:role=>:artillery,:movement_policy=>:artillery,:target_policy=>:lowest_def,:threat_policy=>:ignore_minor,:skill_policy=>:lowest_def,:range=>3,:basic_damage_category=>:special,:basic_move_type=>:psychic,:target_commitment=>92},
    [:deoxys,:defense]=>{:role=>:bodyguard,:movement_policy=>:bodyguard,:target_policy=>:protect_ally,:threat_policy=>:protective,:skill_policy=>:protect_ally,:range=>3,:basic_damage_category=>:special,:basic_move_type=>:psychic,:target_commitment=>100},
    [:deoxys,:speed]=>{:role=>:kiter,:movement_policy=>:kiter,:target_policy=>:execute,:threat_policy=>:responsive,:skill_policy=>:execute,:range=>3,:basic_damage_category=>:special,:basic_move_type=>:psychic,:target_commitment=>84},
  }
  HOENN_REVIEW_MANIFEST_V09910={
    :dex_start=>252,:dex_end=>386,:species=>135,:fields=>18,
    :physical=>70,:special=>65,:melee=>68,:ranged=>67,
    :enabled_non_normal_forms=>0,:review_only_form_profiles=>6,
    :combat_core_direct_modification=>false,:previous_reviewed=>251,:reviewed_total=>386,:pending=>108
  }
end
