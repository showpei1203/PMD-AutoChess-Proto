#==============================================================================
# 【PMD AutoChess 中文維護說明】
# 腳本：PMD AutoChess Proto v0.26.1
# 分類：核心戰鬥 Runtime
#
# 【用途／機制】
# 承接前序 Data／Config，實際執行戰鬥 Scene、Unit、AI、技能與呈現。
#
# 【怎麼調整】
# 一般平衡與資料調整不要直接改 Runtime；若要追加功能，建議在較後腳本 alias 原方法後擴充。
#
# 【Runtime 主要方法（查流程時可直接搜尋）】
# - start / verify_ability_passive_offense
#
# 【維護規則】
# - RPG Maker VX / RGSS2 / Ruby 1.8 相容。
# - instance_uid 才是 Pokémon 個體身份；Actor ID 只是容器。
# - 新增行為優先沿用既有 helper／Data 表；避免破壞已 Freeze 的舊核心。
# - 本專案新腳本也必須保留同等級的中文說明與實際範例。
#==============================================================================
#==============================================================================
# PMD AutoChess Proto v0.26.1
# Ability Passive deterministic verification correction only.
#------------------------------------------------------------------------------
# v0.26's Flare Boost verification used a Ghost-type special attack against
# Rattata.  Normal is immune to Ghost, so both pre-burn and post-burn damage
# were correctly 0 and the verification could not observe Flare Boost.
#
# v0.26.1 changes only that deterministic test input to a neutral Psychic-type
# special attack.  Flare Boost runtime behavior, battle type rules, abilities,
# RNG, and every pre-existing script are unchanged.
#==============================================================================

class Scene_PMD_AutoChess
  alias pmd_ac_v0261_start start unless method_defined?(:pmd_ac_v0261_start)

  def start
    pmd_ac_v0261_start
    begin
      if FileTest.exist?(PMD_AC::BATTLE_LOG_FILE)
        text = File.open(PMD_AC::BATTLE_LOG_FILE, "rb") { |f| f.read }
        text.sub!("PMD AutoChess Proto v0.26 Battle Verification Log",
                  "PMD AutoChess Proto v0.26.1 Battle Verification Log")
        File.open(PMD_AC::BATTLE_LOG_FILE, "wb") { |f| f.write(text) }
      end
    rescue
    end
  end

  # Same v0.26 verification, except Flare Boost is measured with a neutral,
  # non-immune special move so the assertion tests the ability rather than the
  # Normal-vs-Ghost type chart.
  def verify_ability_passive_offense(tag)
    return if @verification_done[tag]
    data=PMD_AC.skill_data(:mv_crunch)
    sf=ability_passive_verification_unit(:nidoking,:hidden,:ally,20);plain=ability_passive_verification_unit(:nidoking,:primary,:ally,21)
    t1=ability_passive_verification_unit(:rattata,:primary,:enemy,22);t2=ability_passive_verification_unit(:rattata,:primary,:enemy,23)
    d_sf=deal_direct_damage(sf,t1,80,{:skill_data=>data,:random_percent=>100,:directional=>false,:can_crit=>false})
    apply_canonical_secondary_group(sf,t1,data,data[:secondary_effects],d_sf)
    d_pl=deal_direct_damage(plain,t2,80,{:skill_data=>data,:random_percent=>100,:directional=>false,:can_crit=>false})
    sheer=d_sf>d_pl && t1.stat_stage(:def)==0

    sn=ability_passive_verification_unit(:kingdra,:secondary,:ally,24);sn0=ability_passive_verification_unit(:kingdra,:primary,:ally,25)
    st1=ability_passive_verification_unit(:rattata,:primary,:enemy,26);st2=ability_passive_verification_unit(:rattata,:primary,:enemy,27)
    crit1=deal_direct_damage(sn,st1,60,{:move_type=>:water,:damage_category=>:special,:random_percent=>100,:directional=>false,:modifier=>{:force_crit=>true}})
    crit0=deal_direct_damage(sn0,st2,60,{:move_type=>:water,:damage_category=>:special,:random_percent=>100,:directional=>false,:modifier=>{:force_crit=>true}})

    tox=ability_passive_verification_unit(:zangoose,:hidden,:ally,28);tt1=ability_passive_verification_unit(:rattata,:primary,:enemy,29);tt2=ability_passive_verification_unit(:rattata,:primary,:enemy,30)
    pre=deal_direct_damage(tox,tt1,50,{:move_type=>:normal,:damage_category=>:physical,:random_percent=>100,:directional=>false,:can_crit=>false});tox.apply_status(:poison,{:duration=>180,:value=>10,:interval=>30,:stack_mode=>:refresh},nil);post=deal_direct_damage(tox,tt2,50,{:move_type=>:normal,:damage_category=>:physical,:random_percent=>100,:directional=>false,:can_crit=>false})

    fl=ability_passive_verification_unit(:drifblim,:hidden,:ally,31);ft1=ability_passive_verification_unit(:rattata,:primary,:enemy,32);ft2=ability_passive_verification_unit(:rattata,:primary,:enemy,33)
    # Neutral special hit.  Rattata is immune to Ghost, which made v0.26's
    # original test read 0->0 even though Flare Boost itself was correct.
    fpre=deal_direct_damage(fl,ft1,50,{:move_type=>:psychic,:damage_category=>:special,:random_percent=>100,:directional=>false,:can_crit=>false});fl.apply_status(:burn,{:duration=>180,:value=>10,:interval=>30,:stack_mode=>:refresh},nil);fpost=deal_direct_damage(fl,ft2,50,{:move_type=>:psychic,:damage_category=>:special,:random_percent=>100,:directional=>false,:can_crit=>false})

    pass=sheer && crit1>crit0 && post>pre && fpost>fpre
    log_event(:verify,tag.to_s.upcase+" pass="+(pass ? "1":"0")+" sheer_force="+d_pl.to_s+"->"+d_sf.to_s+" suppressed="+(t1.stat_stage(:def)==0 ? "1":"0")+" sniper="+crit0.to_s+"->"+crit1.to_s+" toxic="+pre.to_s+"->"+post.to_s+" flare="+fpre.to_s+"->"+fpost.to_s+" flare_type=psychic")
    @verification_done[tag]=true
  end
end
