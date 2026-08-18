# encoding: UTF-8
#==============================================================================
# 【PMD AutoChess 中文維護說明】
# 腳本：PMD AutoChess Final 494 Gameplay Review Data v0.99.11
# 分類：Pokémon Gameplay / AI / Balance Review #0387-0494
#
# 【用途】
# - 完成 National Dex #0387-0494 共 108 隻第一輪逐隻 Gameplay Review。
# - 與 Kanto/Johto/Hoenn 合併後，正式達成 #0001-0494 全 494 隻 REVIEWED。
# - 每隻指定 Role、Movement/Target/Threat/Skill Policy、普通攻擊距離、屬性與物特類別。
# - 特別處理 Regigigas、Rotom、Giratina、Shaymin、Arceus 等特殊身份。
#
# 【主要設定項】
# FINAL_PROFILE_OVERRIDES_V09911：#0387-0494 共 108 隻人工 Profile。
# FINAL_SPECIAL_BALANCE_RISKS_V09911：特殊平衡風險。
# FINAL_IDENTITY_NOTES_V09911：不可被一般模板抹平的身份規則。
# FINAL_ABILITY_SYNERGY_EXTRA_V09911：本批 Ability 戰術標籤。
# FINAL_FORM_REVIEW_PROFILES_V09911：Rotom/Giratina/Shaymin disabled Form 預備 Profile。
#
# 【普通攻擊規則】
# - range=1 近戰；range=3 遠程。
# - basic_damage_category 僅 source_type=:basic 使用。
# - Skill category 完全依 Move Runtime，不由 Species Profile 覆蓋。
#
# 【Form 規則】
# - disabled Form 只做 Review Profile，不偷啟用 Runtime。
# - Rotom 家電、Giratina Origin、Shaymin Sky 先準備差異定位。
# - Arceus Multitype 以單一 instance + type/form state 管理，不複製成多隻。
#
# 【事件／腳本呼叫方式】
# row = PMD_AC.gameplay_review_row_v09911(:arceus)
# profile = PMD_AC.review_profile_for_v09911(:garchomp, :normal)
# PMD_AC.write_final_gameplay_review_v09911
#
# 【實際範例】
# Regigigas：Physical Bruiser，Slow Start 是極端數值的 power budget。
# Giratina：Altered=耐久 Bodyguard；Origin=review-only 壓迫型。
# Arceus：Normal 只是預設，Multitype 是未來切換身份核心。
#
# 【維護限制】
# - RPG Maker VX / RGSS2 / Ruby 1.8。
# - Actor ID 不是 Pokémon identity；使用 instance_uid。
# - Frozen Combat Core 不直接修改，只追加 Content Hook。
#==============================================================================
module PMD_AC
  GAMEPLAY_REVIEW_VERSION_V09911='0.99.11'
  FINAL_REVIEW_DEX_RANGE_V09911=(387..494)
  FINAL_REVIEW_STATUS_V09911=:reviewed_manual
  FINAL_PROFILE_OVERRIDES_V09911={
    :turtwig=>{:role=>:frontline,:movement_policy=>:frontline,:target_policy=>:melee_first,:threat_policy=>:hold_ground,:skill_policy=>:current_target,:range=>1,:basic_damage_category=>:physical,:basic_move_type=>:grass,:target_commitment=>86},
    :grotle=>{:role=>:frontline,:movement_policy=>:frontline,:target_policy=>:melee_first,:threat_policy=>:hold_ground,:skill_policy=>:current_target,:range=>1,:basic_damage_category=>:physical,:basic_move_type=>:grass,:target_commitment=>86},
    :torterra=>{:role=>:bodyguard,:movement_policy=>:bodyguard,:target_policy=>:protect_ally,:threat_policy=>:protective,:skill_policy=>:protect_ally,:range=>1,:basic_damage_category=>:physical,:basic_move_type=>:ground,:target_commitment=>92},
    :chimchar=>{:role=>:kiter,:movement_policy=>:kiter,:target_policy=>:nearest,:threat_policy=>:responsive,:skill_policy=>:current_target,:range=>3,:basic_damage_category=>:special,:basic_move_type=>:fire,:target_commitment=>62},
    :monferno=>{:role=>:bruiser,:movement_policy=>:bruiser,:target_policy=>:execute,:threat_policy=>:normal,:skill_policy=>:execute,:range=>3,:basic_damage_category=>:special,:basic_move_type=>:fighting,:target_commitment=>82},
    :infernape=>{:role=>:bruiser,:movement_policy=>:bruiser,:target_policy=>:execute,:threat_policy=>:normal,:skill_policy=>:execute,:range=>3,:basic_damage_category=>:special,:basic_move_type=>:fighting,:target_commitment=>82},
    :piplup=>{:role=>:controller,:movement_policy=>:controller,:target_policy=>:cluster,:threat_policy=>:responsive,:skill_policy=>:best_cluster,:range=>3,:basic_damage_category=>:special,:basic_move_type=>:water,:target_commitment=>66},
    :prinplup=>{:role=>:controller,:movement_policy=>:controller,:target_policy=>:cluster,:threat_policy=>:responsive,:skill_policy=>:best_cluster,:range=>3,:basic_damage_category=>:special,:basic_move_type=>:water,:target_commitment=>66},
    :empoleon=>{:role=>:bodyguard,:movement_policy=>:bodyguard,:target_policy=>:protect_ally,:threat_policy=>:protective,:skill_policy=>:protect_ally,:range=>3,:basic_damage_category=>:special,:basic_move_type=>:steel,:target_commitment=>92},
    :starly=>{:role=>:assassin,:movement_policy=>:assassin,:target_policy=>:backline_low_def,:threat_policy=>:ignore_minor,:skill_policy=>:execute,:range=>1,:basic_damage_category=>:physical,:basic_move_type=>:normal,:target_commitment=>82},
    :staravia=>{:role=>:assassin,:movement_policy=>:assassin,:target_policy=>:backline_low_def,:threat_policy=>:ignore_minor,:skill_policy=>:execute,:range=>1,:basic_damage_category=>:physical,:basic_move_type=>:normal,:target_commitment=>82},
    :staraptor=>{:role=>:assassin,:movement_policy=>:assassin,:target_policy=>:backline_low_def,:threat_policy=>:ignore_minor,:skill_policy=>:execute,:range=>1,:basic_damage_category=>:physical,:basic_move_type=>:flying,:target_commitment=>82},
    :bidoof=>{:role=>:controller,:movement_policy=>:controller,:target_policy=>:cluster,:threat_policy=>:responsive,:skill_policy=>:best_cluster,:range=>1,:basic_damage_category=>:physical,:basic_move_type=>:normal,:target_commitment=>66},
    :bibarel=>{:role=>:bruiser,:movement_policy=>:bruiser,:target_policy=>:execute,:threat_policy=>:normal,:skill_policy=>:execute,:range=>1,:basic_damage_category=>:physical,:basic_move_type=>:water,:target_commitment=>82},
    :kricketot=>{:role=>:controller,:movement_policy=>:controller,:target_policy=>:cluster,:threat_policy=>:responsive,:skill_policy=>:best_cluster,:range=>3,:basic_damage_category=>:physical,:basic_move_type=>:bug,:target_commitment=>66},
    :kricketune=>{:role=>:bruiser,:movement_policy=>:bruiser,:target_policy=>:execute,:threat_policy=>:normal,:skill_policy=>:execute,:range=>1,:basic_damage_category=>:physical,:basic_move_type=>:bug,:target_commitment=>82},
    :shinx=>{:role=>:assassin,:movement_policy=>:assassin,:target_policy=>:backline_low_def,:threat_policy=>:ignore_minor,:skill_policy=>:execute,:range=>1,:basic_damage_category=>:physical,:basic_move_type=>:electric,:target_commitment=>82},
    :luxio=>{:role=>:bruiser,:movement_policy=>:bruiser,:target_policy=>:execute,:threat_policy=>:normal,:skill_policy=>:execute,:range=>1,:basic_damage_category=>:physical,:basic_move_type=>:electric,:target_commitment=>82},
    :luxray=>{:role=>:bruiser,:movement_policy=>:bruiser,:target_policy=>:execute,:threat_policy=>:normal,:skill_policy=>:execute,:range=>1,:basic_damage_category=>:physical,:basic_move_type=>:electric,:target_commitment=>82},
    :budew=>{:role=>:controller,:movement_policy=>:controller,:target_policy=>:cluster,:threat_policy=>:responsive,:skill_policy=>:best_cluster,:range=>3,:basic_damage_category=>:special,:basic_move_type=>:grass,:target_commitment=>66},
    :roserade=>{:role=>:artillery,:movement_policy=>:artillery,:target_policy=>:lowest_def,:threat_policy=>:responsive,:skill_policy=>:lowest_def,:range=>3,:basic_damage_category=>:special,:basic_move_type=>:poison,:target_commitment=>70},
    :cranidos=>{:role=>:bruiser,:movement_policy=>:bruiser,:target_policy=>:execute,:threat_policy=>:normal,:skill_policy=>:execute,:range=>1,:basic_damage_category=>:physical,:basic_move_type=>:rock,:target_commitment=>82},
    :rampardos=>{:role=>:bruiser,:movement_policy=>:berserker,:target_policy=>:execute,:threat_policy=>:ignore_minor,:skill_policy=>:execute,:range=>1,:basic_damage_category=>:physical,:basic_move_type=>:rock,:target_commitment=>82},
    :shieldon=>{:role=>:frontline,:movement_policy=>:frontline,:target_policy=>:melee_first,:threat_policy=>:hold_ground,:skill_policy=>:current_target,:range=>1,:basic_damage_category=>:physical,:basic_move_type=>:rock,:target_commitment=>86},
    :bastiodon=>{:role=>:bodyguard,:movement_policy=>:bodyguard,:target_policy=>:protect_ally,:threat_policy=>:protective,:skill_policy=>:protect_ally,:range=>1,:basic_damage_category=>:physical,:basic_move_type=>:steel,:target_commitment=>92},
    :burmy=>{:role=>:frontline,:movement_policy=>:frontline,:target_policy=>:melee_first,:threat_policy=>:hold_ground,:skill_policy=>:current_target,:range=>1,:basic_damage_category=>:physical,:basic_move_type=>:bug,:target_commitment=>86},
    :wormadam=>{:role=>:bodyguard,:movement_policy=>:bodyguard,:target_policy=>:protect_ally,:threat_policy=>:protective,:skill_policy=>:protect_ally,:range=>3,:basic_damage_category=>:special,:basic_move_type=>:bug,:target_commitment=>92},
    :mothim=>{:role=>:artillery,:movement_policy=>:artillery,:target_policy=>:lowest_def,:threat_policy=>:responsive,:skill_policy=>:lowest_def,:range=>3,:basic_damage_category=>:special,:basic_move_type=>:bug,:target_commitment=>70},
    :combee=>{:role=>:controller,:movement_policy=>:controller,:target_policy=>:cluster,:threat_policy=>:responsive,:skill_policy=>:best_cluster,:range=>3,:basic_damage_category=>:physical,:basic_move_type=>:bug,:target_commitment=>66},
    :vespiquen=>{:role=>:bodyguard,:movement_policy=>:bodyguard,:target_policy=>:protect_ally,:threat_policy=>:protective,:skill_policy=>:protect_ally,:range=>1,:basic_damage_category=>:physical,:basic_move_type=>:bug,:target_commitment=>92},
    :pachirisu=>{:role=>:controller,:movement_policy=>:controller,:target_policy=>:cluster,:threat_policy=>:responsive,:skill_policy=>:best_cluster,:range=>3,:basic_damage_category=>:physical,:basic_move_type=>:electric,:target_commitment=>66},
    :buizel=>{:role=>:kiter,:movement_policy=>:kiter,:target_policy=>:nearest,:threat_policy=>:responsive,:skill_policy=>:current_target,:range=>1,:basic_damage_category=>:physical,:basic_move_type=>:water,:target_commitment=>62},
    :floatzel=>{:role=>:assassin,:movement_policy=>:assassin,:target_policy=>:backline_low_def,:threat_policy=>:ignore_minor,:skill_policy=>:execute,:range=>1,:basic_damage_category=>:physical,:basic_move_type=>:water,:target_commitment=>82},
    :cherubi=>{:role=>:controller,:movement_policy=>:controller,:target_policy=>:cluster,:threat_policy=>:responsive,:skill_policy=>:best_cluster,:range=>3,:basic_damage_category=>:special,:basic_move_type=>:grass,:target_commitment=>66},
    :cherrim=>{:role=>:controller,:movement_policy=>:controller,:target_policy=>:cluster,:threat_policy=>:responsive,:skill_policy=>:best_cluster,:range=>3,:basic_damage_category=>:special,:basic_move_type=>:grass,:target_commitment=>66},
    :shellos=>{:role=>:controller,:movement_policy=>:controller,:target_policy=>:cluster,:threat_policy=>:responsive,:skill_policy=>:best_cluster,:range=>3,:basic_damage_category=>:special,:basic_move_type=>:water,:target_commitment=>66},
    :gastrodon=>{:role=>:bodyguard,:movement_policy=>:bodyguard,:target_policy=>:protect_ally,:threat_policy=>:protective,:skill_policy=>:protect_ally,:range=>3,:basic_damage_category=>:special,:basic_move_type=>:water,:target_commitment=>92},
    :ambipom=>{:role=>:assassin,:movement_policy=>:assassin,:target_policy=>:backline_low_def,:threat_policy=>:ignore_minor,:skill_policy=>:execute,:range=>1,:basic_damage_category=>:physical,:basic_move_type=>:normal,:target_commitment=>82},
    :drifloon=>{:role=>:controller,:movement_policy=>:controller,:target_policy=>:cluster,:threat_policy=>:responsive,:skill_policy=>:best_cluster,:range=>3,:basic_damage_category=>:special,:basic_move_type=>:ghost,:target_commitment=>66},
    :drifblim=>{:role=>:controller,:movement_policy=>:controller,:target_policy=>:cluster,:threat_policy=>:responsive,:skill_policy=>:best_cluster,:range=>3,:basic_damage_category=>:special,:basic_move_type=>:ghost,:target_commitment=>66},
    :buneary=>{:role=>:assassin,:movement_policy=>:assassin,:target_policy=>:backline_low_def,:threat_policy=>:ignore_minor,:skill_policy=>:execute,:range=>1,:basic_damage_category=>:physical,:basic_move_type=>:normal,:target_commitment=>82},
    :lopunny=>{:role=>:assassin,:movement_policy=>:assassin,:target_policy=>:backline_low_def,:threat_policy=>:ignore_minor,:skill_policy=>:execute,:range=>1,:basic_damage_category=>:physical,:basic_move_type=>:normal,:target_commitment=>82},
    :mismagius=>{:role=>:artillery,:movement_policy=>:artillery,:target_policy=>:lowest_def,:threat_policy=>:responsive,:skill_policy=>:lowest_def,:range=>3,:basic_damage_category=>:special,:basic_move_type=>:ghost,:target_commitment=>70},
    :honchkrow=>{:role=>:artillery,:movement_policy=>:artillery,:target_policy=>:lowest_def,:threat_policy=>:responsive,:skill_policy=>:lowest_def,:range=>1,:basic_damage_category=>:physical,:basic_move_type=>:dark,:target_commitment=>70},
    :glameow=>{:role=>:assassin,:movement_policy=>:assassin,:target_policy=>:backline_low_def,:threat_policy=>:ignore_minor,:skill_policy=>:execute,:range=>1,:basic_damage_category=>:physical,:basic_move_type=>:normal,:target_commitment=>82},
    :purugly=>{:role=>:assassin,:movement_policy=>:assassin,:target_policy=>:backline_low_def,:threat_policy=>:ignore_minor,:skill_policy=>:execute,:range=>1,:basic_damage_category=>:physical,:basic_move_type=>:normal,:target_commitment=>82},
    :chingling=>{:role=>:controller,:movement_policy=>:controller,:target_policy=>:cluster,:threat_policy=>:responsive,:skill_policy=>:best_cluster,:range=>3,:basic_damage_category=>:special,:basic_move_type=>:psychic,:target_commitment=>66},
    :stunky=>{:role=>:bruiser,:movement_policy=>:bruiser,:target_policy=>:execute,:threat_policy=>:normal,:skill_policy=>:execute,:range=>1,:basic_damage_category=>:physical,:basic_move_type=>:poison,:target_commitment=>82},
    :skuntank=>{:role=>:bruiser,:movement_policy=>:bruiser,:target_policy=>:execute,:threat_policy=>:normal,:skill_policy=>:execute,:range=>1,:basic_damage_category=>:physical,:basic_move_type=>:dark,:target_commitment=>82},
    :bronzor=>{:role=>:bodyguard,:movement_policy=>:bodyguard,:target_policy=>:protect_ally,:threat_policy=>:protective,:skill_policy=>:protect_ally,:range=>3,:basic_damage_category=>:special,:basic_move_type=>:steel,:target_commitment=>92},
    :bronzong=>{:role=>:bodyguard,:movement_policy=>:bodyguard,:target_policy=>:protect_ally,:threat_policy=>:protective,:skill_policy=>:protect_ally,:range=>3,:basic_damage_category=>:special,:basic_move_type=>:steel,:target_commitment=>92},
    :bonsly=>{:role=>:frontline,:movement_policy=>:frontline,:target_policy=>:melee_first,:threat_policy=>:hold_ground,:skill_policy=>:current_target,:range=>1,:basic_damage_category=>:physical,:basic_move_type=>:rock,:target_commitment=>86},
    :mime_jr=>{:role=>:controller,:movement_policy=>:controller,:target_policy=>:cluster,:threat_policy=>:responsive,:skill_policy=>:best_cluster,:range=>3,:basic_damage_category=>:special,:basic_move_type=>:psychic,:target_commitment=>66},
    :happiny=>{:role=>:bodyguard,:movement_policy=>:bodyguard,:target_policy=>:protect_ally,:threat_policy=>:protective,:skill_policy=>:protect_ally,:range=>3,:basic_damage_category=>:special,:basic_move_type=>:normal,:target_commitment=>92},
    :chatot=>{:role=>:artillery,:movement_policy=>:artillery,:target_policy=>:lowest_def,:threat_policy=>:responsive,:skill_policy=>:lowest_def,:range=>3,:basic_damage_category=>:special,:basic_move_type=>:normal,:target_commitment=>70},
    :spiritomb=>{:role=>:controller,:movement_policy=>:controller,:target_policy=>:highest_atk,:threat_policy=>:responsive,:skill_policy=>:highest_atk,:range=>3,:basic_damage_category=>:special,:basic_move_type=>:ghost,:target_commitment=>88},
    :gible=>{:role=>:bruiser,:movement_policy=>:bruiser,:target_policy=>:execute,:threat_policy=>:normal,:skill_policy=>:execute,:range=>1,:basic_damage_category=>:physical,:basic_move_type=>:dragon,:target_commitment=>82},
    :gabite=>{:role=>:bruiser,:movement_policy=>:bruiser,:target_policy=>:execute,:threat_policy=>:normal,:skill_policy=>:execute,:range=>1,:basic_damage_category=>:physical,:basic_move_type=>:dragon,:target_commitment=>82},
    :garchomp=>{:role=>:assassin,:movement_policy=>:assassin,:target_policy=>:backline_low_def,:threat_policy=>:ignore_minor,:skill_policy=>:execute,:range=>1,:basic_damage_category=>:physical,:basic_move_type=>:ground,:target_commitment=>82},
    :munchlax=>{:role=>:frontline,:movement_policy=>:frontline,:target_policy=>:melee_first,:threat_policy=>:hold_ground,:skill_policy=>:current_target,:range=>1,:basic_damage_category=>:physical,:basic_move_type=>:normal,:target_commitment=>86},
    :riolu=>{:role=>:assassin,:movement_policy=>:assassin,:target_policy=>:backline_low_def,:threat_policy=>:ignore_minor,:skill_policy=>:execute,:range=>1,:basic_damage_category=>:physical,:basic_move_type=>:fighting,:target_commitment=>82},
    :lucario=>{:role=>:bruiser,:movement_policy=>:bruiser,:target_policy=>:execute,:threat_policy=>:normal,:skill_policy=>:execute,:range=>1,:basic_damage_category=>:physical,:basic_move_type=>:fighting,:target_commitment=>82},
    :hippopotas=>{:role=>:frontline,:movement_policy=>:frontline,:target_policy=>:melee_first,:threat_policy=>:hold_ground,:skill_policy=>:current_target,:range=>1,:basic_damage_category=>:physical,:basic_move_type=>:ground,:target_commitment=>86},
    :hippowdon=>{:role=>:bodyguard,:movement_policy=>:bodyguard,:target_policy=>:protect_ally,:threat_policy=>:protective,:skill_policy=>:protect_ally,:range=>1,:basic_damage_category=>:physical,:basic_move_type=>:ground,:target_commitment=>92},
    :skorupi=>{:role=>:controller,:movement_policy=>:controller,:target_policy=>:cluster,:threat_policy=>:responsive,:skill_policy=>:best_cluster,:range=>3,:basic_damage_category=>:physical,:basic_move_type=>:poison,:target_commitment=>66},
    :drapion=>{:role=>:bruiser,:movement_policy=>:bruiser,:target_policy=>:execute,:threat_policy=>:normal,:skill_policy=>:execute,:range=>1,:basic_damage_category=>:physical,:basic_move_type=>:poison,:target_commitment=>82},
    :croagunk=>{:role=>:bruiser,:movement_policy=>:bruiser,:target_policy=>:execute,:threat_policy=>:normal,:skill_policy=>:execute,:range=>1,:basic_damage_category=>:physical,:basic_move_type=>:poison,:target_commitment=>82},
    :toxicroak=>{:role=>:bruiser,:movement_policy=>:bruiser,:target_policy=>:execute,:threat_policy=>:normal,:skill_policy=>:execute,:range=>1,:basic_damage_category=>:physical,:basic_move_type=>:fighting,:target_commitment=>82},
    :carnivine=>{:role=>:controller,:movement_policy=>:controller,:target_policy=>:cluster,:threat_policy=>:responsive,:skill_policy=>:best_cluster,:range=>1,:basic_damage_category=>:physical,:basic_move_type=>:grass,:target_commitment=>66},
    :finneon=>{:role=>:kiter,:movement_policy=>:kiter,:target_policy=>:nearest,:threat_policy=>:responsive,:skill_policy=>:current_target,:range=>3,:basic_damage_category=>:special,:basic_move_type=>:water,:target_commitment=>62},
    :lumineon=>{:role=>:controller,:movement_policy=>:controller,:target_policy=>:cluster,:threat_policy=>:responsive,:skill_policy=>:best_cluster,:range=>3,:basic_damage_category=>:special,:basic_move_type=>:water,:target_commitment=>66},
    :mantyke=>{:role=>:bodyguard,:movement_policy=>:bodyguard,:target_policy=>:protect_ally,:threat_policy=>:protective,:skill_policy=>:protect_ally,:range=>3,:basic_damage_category=>:special,:basic_move_type=>:water,:target_commitment=>92},
    :snover=>{:role=>:controller,:movement_policy=>:controller,:target_policy=>:cluster,:threat_policy=>:responsive,:skill_policy=>:best_cluster,:range=>3,:basic_damage_category=>:special,:basic_move_type=>:grass,:target_commitment=>66},
    :abomasnow=>{:role=>:bodyguard,:movement_policy=>:bodyguard,:target_policy=>:protect_ally,:threat_policy=>:protective,:skill_policy=>:protect_ally,:range=>3,:basic_damage_category=>:special,:basic_move_type=>:ice,:target_commitment=>92},
    :weavile=>{:role=>:assassin,:movement_policy=>:assassin,:target_policy=>:backline_low_def,:threat_policy=>:ignore_minor,:skill_policy=>:execute,:range=>1,:basic_damage_category=>:physical,:basic_move_type=>:dark,:target_commitment=>82},
    :magnezone=>{:role=>:artillery,:movement_policy=>:artillery,:target_policy=>:lowest_def,:threat_policy=>:responsive,:skill_policy=>:lowest_def,:range=>3,:basic_damage_category=>:special,:basic_move_type=>:electric,:target_commitment=>70},
    :lickilicky=>{:role=>:bodyguard,:movement_policy=>:bodyguard,:target_policy=>:protect_ally,:threat_policy=>:protective,:skill_policy=>:protect_ally,:range=>1,:basic_damage_category=>:physical,:basic_move_type=>:normal,:target_commitment=>92},
    :rhyperior=>{:role=>:bodyguard,:movement_policy=>:bodyguard,:target_policy=>:protect_ally,:threat_policy=>:protective,:skill_policy=>:protect_ally,:range=>1,:basic_damage_category=>:physical,:basic_move_type=>:ground,:target_commitment=>92},
    :tangrowth=>{:role=>:bodyguard,:movement_policy=>:bodyguard,:target_policy=>:protect_ally,:threat_policy=>:protective,:skill_policy=>:protect_ally,:range=>3,:basic_damage_category=>:special,:basic_move_type=>:grass,:target_commitment=>92},
    :electivire=>{:role=>:bruiser,:movement_policy=>:bruiser,:target_policy=>:execute,:threat_policy=>:normal,:skill_policy=>:execute,:range=>1,:basic_damage_category=>:physical,:basic_move_type=>:electric,:target_commitment=>82},
    :magmortar=>{:role=>:artillery,:movement_policy=>:artillery,:target_policy=>:lowest_def,:threat_policy=>:responsive,:skill_policy=>:lowest_def,:range=>3,:basic_damage_category=>:special,:basic_move_type=>:fire,:target_commitment=>70},
    :togekiss=>{:role=>:bodyguard,:movement_policy=>:bodyguard,:target_policy=>:protect_ally,:threat_policy=>:protective,:skill_policy=>:protect_ally,:range=>3,:basic_damage_category=>:special,:basic_move_type=>:fairy,:target_commitment=>92},
    :yanmega=>{:role=>:artillery,:movement_policy=>:artillery,:target_policy=>:lowest_def,:threat_policy=>:responsive,:skill_policy=>:lowest_def,:range=>3,:basic_damage_category=>:special,:basic_move_type=>:bug,:target_commitment=>70},
    :leafeon=>{:role=>:assassin,:movement_policy=>:assassin,:target_policy=>:backline_low_def,:threat_policy=>:ignore_minor,:skill_policy=>:execute,:range=>1,:basic_damage_category=>:physical,:basic_move_type=>:grass,:target_commitment=>82},
    :glaceon=>{:role=>:artillery,:movement_policy=>:artillery,:target_policy=>:lowest_def,:threat_policy=>:responsive,:skill_policy=>:lowest_def,:range=>3,:basic_damage_category=>:special,:basic_move_type=>:ice,:target_commitment=>70},
    :gliscor=>{:role=>:bodyguard,:movement_policy=>:bodyguard,:target_policy=>:protect_ally,:threat_policy=>:protective,:skill_policy=>:protect_ally,:range=>1,:basic_damage_category=>:physical,:basic_move_type=>:ground,:target_commitment=>92},
    :mamoswine=>{:role=>:bruiser,:movement_policy=>:bruiser,:target_policy=>:execute,:threat_policy=>:normal,:skill_policy=>:execute,:range=>1,:basic_damage_category=>:physical,:basic_move_type=>:ground,:target_commitment=>82},
    :porygon_z=>{:role=>:artillery,:movement_policy=>:artillery,:target_policy=>:lowest_def,:threat_policy=>:responsive,:skill_policy=>:lowest_def,:range=>3,:basic_damage_category=>:special,:basic_move_type=>:normal,:target_commitment=>70},
    :gallade=>{:role=>:bruiser,:movement_policy=>:bruiser,:target_policy=>:execute,:threat_policy=>:normal,:skill_policy=>:execute,:range=>1,:basic_damage_category=>:physical,:basic_move_type=>:fighting,:target_commitment=>82},
    :probopass=>{:role=>:bodyguard,:movement_policy=>:bodyguard,:target_policy=>:protect_ally,:threat_policy=>:protective,:skill_policy=>:protect_ally,:range=>3,:basic_damage_category=>:special,:basic_move_type=>:steel,:target_commitment=>92},
    :dusknoir=>{:role=>:bodyguard,:movement_policy=>:bodyguard,:target_policy=>:protect_ally,:threat_policy=>:protective,:skill_policy=>:protect_ally,:range=>1,:basic_damage_category=>:physical,:basic_move_type=>:ghost,:target_commitment=>92},
    :froslass=>{:role=>:kiter,:movement_policy=>:kiter,:target_policy=>:nearest,:threat_policy=>:responsive,:skill_policy=>:current_target,:range=>3,:basic_damage_category=>:special,:basic_move_type=>:ice,:target_commitment=>62},
    :rotom=>{:role=>:controller,:movement_policy=>:controller,:target_policy=>:cluster,:threat_policy=>:responsive,:skill_policy=>:best_cluster,:range=>3,:basic_damage_category=>:special,:basic_move_type=>:electric,:target_commitment=>66},
    :uxie=>{:role=>:bodyguard,:movement_policy=>:bodyguard,:target_policy=>:protect_ally,:threat_policy=>:protective,:skill_policy=>:protect_ally,:range=>3,:basic_damage_category=>:special,:basic_move_type=>:psychic,:target_commitment=>92},
    :mesprit=>{:role=>:controller,:movement_policy=>:controller,:target_policy=>:cluster,:threat_policy=>:responsive,:skill_policy=>:best_cluster,:range=>3,:basic_damage_category=>:special,:basic_move_type=>:psychic,:target_commitment=>66},
    :azelf=>{:role=>:artillery,:movement_policy=>:artillery,:target_policy=>:lowest_def,:threat_policy=>:responsive,:skill_policy=>:lowest_def,:range=>3,:basic_damage_category=>:special,:basic_move_type=>:psychic,:target_commitment=>70},
    :dialga=>{:role=>:artillery,:movement_policy=>:artillery,:target_policy=>:lowest_def,:threat_policy=>:responsive,:skill_policy=>:lowest_def,:range=>3,:basic_damage_category=>:special,:basic_move_type=>:dragon,:target_commitment=>70},
    :palkia=>{:role=>:artillery,:movement_policy=>:artillery,:target_policy=>:lowest_def,:threat_policy=>:responsive,:skill_policy=>:lowest_def,:range=>3,:basic_damage_category=>:special,:basic_move_type=>:dragon,:target_commitment=>70},
    :heatran=>{:role=>:artillery,:movement_policy=>:artillery,:target_policy=>:lowest_def,:threat_policy=>:responsive,:skill_policy=>:lowest_def,:range=>3,:basic_damage_category=>:special,:basic_move_type=>:fire,:target_commitment=>70},
    :regigigas=>{:role=>:bruiser,:movement_policy=>:berserker,:target_policy=>:execute,:threat_policy=>:ignore_minor,:skill_policy=>:execute,:range=>1,:basic_damage_category=>:physical,:basic_move_type=>:normal,:target_commitment=>82},
    :giratina=>{:role=>:bodyguard,:movement_policy=>:bodyguard,:target_policy=>:protect_ally,:threat_policy=>:protective,:skill_policy=>:protect_ally,:range=>3,:basic_damage_category=>:special,:basic_move_type=>:ghost,:target_commitment=>92},
    :cresselia=>{:role=>:bodyguard,:movement_policy=>:bodyguard,:target_policy=>:protect_ally,:threat_policy=>:protective,:skill_policy=>:protect_ally,:range=>3,:basic_damage_category=>:special,:basic_move_type=>:psychic,:target_commitment=>92},
    :phione=>{:role=>:bodyguard,:movement_policy=>:bodyguard,:target_policy=>:protect_ally,:threat_policy=>:protective,:skill_policy=>:protect_ally,:range=>3,:basic_damage_category=>:special,:basic_move_type=>:water,:target_commitment=>92},
    :manaphy=>{:role=>:controller,:movement_policy=>:controller,:target_policy=>:cluster,:threat_policy=>:responsive,:skill_policy=>:best_cluster,:range=>3,:basic_damage_category=>:special,:basic_move_type=>:water,:target_commitment=>66},
    :darkrai=>{:role=>:kiter,:movement_policy=>:kiter,:target_policy=>:nearest,:threat_policy=>:responsive,:skill_policy=>:current_target,:range=>3,:basic_damage_category=>:special,:basic_move_type=>:dark,:target_commitment=>62},
    :shaymin=>{:role=>:controller,:movement_policy=>:controller,:target_policy=>:cluster,:threat_policy=>:responsive,:skill_policy=>:best_cluster,:range=>3,:basic_damage_category=>:special,:basic_move_type=>:grass,:target_commitment=>66},
    :arceus=>{:role=>:bodyguard,:movement_policy=>:bodyguard,:target_policy=>:protect_ally,:threat_policy=>:protective,:skill_policy=>:best_cluster,:range=>3,:basic_damage_category=>:special,:basic_move_type=>:normal,:target_commitment=>100},
    :victini=>{:role=>:artillery,:movement_policy=>:artillery,:target_policy=>:lowest_def,:threat_policy=>:responsive,:skill_policy=>:lowest_def,:range=>3,:basic_damage_category=>:special,:basic_move_type=>:psychic,:target_commitment=>70},
  }
  FINAL_SPECIAL_BALANCE_RISKS_V09911={
    :rampardos=>[:extreme_attack_glass_cannon],
    :bastiodon=>[:extreme_dual_wall_low_offense],
    :spiritomb=>[:no_weakness_legacy_control_bulk],
    :garchomp=>[:pseudo_legendary_speed_physical_ceiling],
    :lucario=>[:mixed_movepool_role_flex],
    :hippowdon=>[:sand_weather_physical_wall],
    :weavile=>[:extreme_speed_physical_assassin],
    :magnezone=>[:high_special_defense_pressure],
    :rhyperior=>[:extreme_physical_bulk_attack],
    :togekiss=>[:serene_grace_support_control],
    :gliscor=>[:poison_heal_wall_ceiling],
    :porygon_z=>[:adaptability_special_nuke],
    :gallade=>[:physical_burst_special_bulk],
    :probopass=>[:extreme_dual_defense_low_speed],
    :dusknoir=>[:extreme_dual_wall_low_hp],
    :froslass=>[:high_speed_control],
    :rotom=>[:form_role_divergence],
    :uxie=>[:legendary_support_wall],
    :azelf=>[:legendary_speed_mixed_burst],
    :dialga=>[:legendary_special_bulk_ceiling],
    :palkia=>[:legendary_special_speed_ceiling],
    :heatran=>[:legendary_resistance_special_pressure],
    :regigigas=>[:slow_start_extreme_power_budget],
    :giratina=>[:legendary_extreme_bulk_form_identity],
    :cresselia=>[:legendary_sustain_wall],
    :darkrai=>[:high_speed_sleep_special_ceiling],
    :shaymin=>[:form_role_divergence],
    :arceus=>[:multitype_universal_role_ceiling],
    :victini=>[:victory_star_team_accuracy_burst],
  }
  FINAL_IDENTITY_NOTES_V09911={
    :bastiodon=>'高雙防與低輸出是身份核心；不以一般 DPS 目標補攻擊，定位為拖延與保護。',
    :rampardos=>'165 Base Attack 必須以低速、低雙防與貼身風險換取；不額外補生存。',
    :spiritomb=>'無一般弱點的舊世代身份以 Controller/耐久表現；不靠純輸出與高速搶位。',
    :garchomp=>'Pseudo-Legendary 高速物理壓力；不得同時再給免費坦度倍率或無成本突進。',
    :lucario=>'物特雙向 movepool 很寬，但普通攻擊固定 Physical Fighting；技能仍依各招式自己的 category。',
    :rotom=>'Normal Rotom 為 Electric Special Controller 基底；家電 Form 先作 Review 資料，ruleset disabled 時不啟用 Runtime。',
    :regigigas=>'160 Attack / 110 HP / 100 Speed 的數值由 Slow Start 約束；不可移除 Slow Start 再照原數值運作。',
    :giratina=>'Altered 以耐久 Bodyguard 為基底；Origin Form 應偏壓迫與機動，但 ruleset disabled 前不套 Runtime。',
    :darkrai=>'Bad Dreams + sleep payoff 是核心；高速度與 135 SpA 已足夠，不再疊免費控制命中。',
    :shaymin=>'Land Form 為均衡 Controller；Sky Form 應轉高速 Special Kiter/Artillery，但 disabled 時只 Review。',
    :arceus=>'Multitype 才是身份核心。Normal 只是預設；未來 Plate/Type 變化必須同步 basic type、AI 與技能評分，不能複製 18 套獨立個體。',
    :victini=>'100 全能力 + Victory Star 偏團隊命中/爆發支援；不因 Mythical 身份直接給隱性傷害倍率。',
  }
  FINAL_ABILITY_SYNERGY_EXTRA_V09911={
    :slow_start=>:delayed_power_budget,
    :multitype=>:type_form_identity,
    :bad_dreams=>:sleep_payoff,
    :serene_grace=>:secondary_effect_build,
    :poison_heal=>:status_sustain,
    :adaptability=>:stab_multiplier,
    :sand_stream=>:sand_weather_core,
    :victory_star=>:team_accuracy_support,
    :pressure=>:resource_pressure,
    :levitate=>:ground_immunity_positioning,
    :download=>:adaptive_offense,
    :trace=>:adaptive_offense,
    :technician=>:low_power_move_build,
  }
  FINAL_FORM_REVIEW_PROFILES_V09911={
    [:rotom,:heat]=>{:role=>:artillery,:movement_policy=>:artillery,:target_policy=>:lowest_def,:threat_policy=>:responsive,:skill_policy=>:lowest_def,:range=>3,:basic_damage_category=>:special,:basic_move_type=>:fire,:target_commitment=>78},
    [:rotom,:wash]=>{:role=>:bodyguard,:movement_policy=>:bodyguard,:target_policy=>:protect_ally,:threat_policy=>:protective,:skill_policy=>:protect_ally,:range=>3,:basic_damage_category=>:special,:basic_move_type=>:water,:target_commitment=>82},
    [:rotom,:frost]=>{:role=>:controller,:movement_policy=>:controller,:target_policy=>:cluster,:threat_policy=>:responsive,:skill_policy=>:best_cluster,:range=>3,:basic_damage_category=>:special,:basic_move_type=>:ice,:target_commitment=>76},
    [:rotom,:fan]=>{:role=>:kiter,:movement_policy=>:kiter,:target_policy=>:nearest,:threat_policy=>:responsive,:skill_policy=>:current_target,:range=>3,:basic_damage_category=>:special,:basic_move_type=>:flying,:target_commitment=>72},
    [:rotom,:mow]=>{:role=>:controller,:movement_policy=>:controller,:target_policy=>:cluster,:threat_policy=>:responsive,:skill_policy=>:best_cluster,:range=>3,:basic_damage_category=>:special,:basic_move_type=>:grass,:target_commitment=>76},
    [:giratina,:origin]=>{:role=>:bruiser,:movement_policy=>:bruiser,:target_policy=>:execute,:threat_policy=>:normal,:skill_policy=>:execute,:range=>3,:basic_damage_category=>:special,:basic_move_type=>:ghost,:target_commitment=>92},
    [:shaymin,:sky]=>{:role=>:kiter,:movement_policy=>:kiter,:target_policy=>:execute,:threat_policy=>:responsive,:skill_policy=>:execute,:range=>3,:basic_damage_category=>:special,:basic_move_type=>:grass,:target_commitment=>82},
  }
  FINAL_REVIEW_MANIFEST_V09911={:dex_start=>387,:dex_end=>494,:species=>108,:fields=>18,:physical=>55,:special=>53,:melee=>51,:ranged=>57,:previous_reviewed=>386,:reviewed_total=>494,:pending=>0,:review_only_form_profiles=>7,:combat_core_direct_modification=>false}
end
