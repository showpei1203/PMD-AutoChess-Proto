#==============================================================================
# 【PMD AutoChess 中文維護說明】
# 腳本：PMD AutoChess Proto v0.40.1
# 分類：核心戰鬥 Runtime
#
# 【用途／機制】
# 承接前序 Data／Config，實際執行戰鬥 Scene、Unit、AI、技能與呈現。
#
# 【怎麼調整】
# 一般平衡與資料調整不要直接改 Runtime；若要追加功能，建議在較後腳本 alias 原方法後擴充。
#
# 【Runtime 主要方法（查流程時可直接搜尋）】
# - start / verify_guard_personal_v040 / verify_guard_feint_v040
#
# 【維護規則】
# - RPG Maker VX / RGSS2 / Ruby 1.8 相容。
# - instance_uid 才是 Pokémon 個體身份；Actor ID 只是容器。
# - 新增行為優先沿用既有 helper／Data 表；避免破壞已 Freeze 的舊核心。
# - 本專案新腳本也必須保留同等級的中文說明與實際範例。
#==============================================================================
# PMD AutoChess v0.40.1 - Guard Verification Target-Team Fix
# Additive verification-only patch over v0.40.
#
# v0.40 runtime guard mechanics were working, but two verifier cases used
# invalid target/team setups:
# 1) Shadow Force bypass was tested against Rattata (Normal type), so Protect
#    was correctly broken but Ghost damage was then type-immune. The verifier
#    incorrectly required HP loss as proof of Protect bypass.
# 2) Feint tried to prove Wide Guard removal using an ALLY Wide Guard source
#    placed on top of an ENEMY target. Wide Guard only protects same-team
#    units, so that aura was never affecting the target and therefore could
#    not be found/cleared by break_guard_on_target_v040.
#
# Fixes only the verification setup. Guard runtime mechanics are unchanged.

class Scene_PMD_AutoChess
  alias pmd_ac_v0401_start start unless method_defined?(:pmd_ac_v0401_start)

  def start
    pmd_ac_v0401_start
    begin
      if FileTest.exist?(PMD_AC::BATTLE_LOG_FILE)
        text=File.open(PMD_AC::BATTLE_LOG_FILE,'rb'){|f|f.read}
        text.sub!(/PMD AutoChess Proto v0\.[0-9.]+ Battle Verification Log/,
                  'PMD AutoChess Proto v0.40.1 Battle Verification Log')
        File.open(PMD_AC::BATTLE_LOG_FILE,'wb'){|f|f.write(text)}
      end
    rescue
    end
    log_event(:guard,'PATCH v0.40.1 verifier_target_team_fix=1 shadow_force_non_normal_target=1 feint_same_team_aura=1 mechanics_unchanged=1')
  end

  def verify_guard_personal_v040
    return if @verification_done[:guard_personal]
    guard_reset_units_v040
    a,b,c,t=guard_verify_units_v040

    # Protect / normal attacks remain tested on Rattata.
    t.set_guard_v040(:protect,60)
    hp=t.hp
    basic=deal_direct_damage(a,t,50,{:fixed_damage=>50,:can_crit=>false,
      :directional=>false,:source_type=>:basic,:grant_energy=>false})
    tackle=apply_skill_effects(a,t,PMD_AC.skill_data(:mv_tackle),1.0)
    protect_basic=(basic==0 && t.hp==hp)
    protect_skill=(tackle.to_i==0 && t.hp==hp)

    # Shadow Force must be tested on a non-Normal target.  Caterpie is already
    # present in the verification battle and is not immune to Ghost damage.
    sf_target=verification_unit(:enemy,:caterpie)
    sf_ok=false
    sf_broke=false
    if sf_target!=nil
      sf_target.set_guard_v040(:protect,60)
      before=sf_target.hp
      sf=PMD_AC.skill_data(:mv_shadow_force)
      apply_skill_effects(a,sf_target,sf,1.0)
      sf_ok=sf_target.hp<before
      sf_broke=!sf_target.guard_active_v040?(:protect)
    end

    t.set_guard_v040(:detect,60)
    hp2=t.hp
    d2=deal_direct_damage(a,t,30,{:fixed_damage=>30,:can_crit=>false,
      :directional=>false,:source_type=>:basic,:grant_energy=>false})
    detect=(d2==0 && t.hp==hp2)

    pass=protect_basic && protect_skill && sf_ok && sf_broke && detect
    log_event(:verify,'GUARD_PERSONAL pass='+(pass ? '1':'0')+
      ' protect_basic='+(protect_basic ? '1':'0')+
      ' protect_skill='+(protect_skill ? '1':'0')+
      ' detect_basic='+(detect ? '1':'0')+
      ' shadow_force_damage='+(sf_ok ? '1':'0')+
      ' shadow_force_bypass='+(sf_broke ? '1':'0')+
      ' verifier_normal_immunity_fixed=1')
    @verification_done[:guard_personal]=true
  end

  def verify_guard_feint_v040
    return if @verification_done[:guard_feint]
    guard_reset_units_v040
    a,b,c,t=guard_verify_units_v040
    aura_source=verification_unit(:enemy,:caterpie)

    t.set_guard_v040(:protect,60)
    if aura_source!=nil
      aura_source.deploy_to_pixel(t.pixel_x,t.pixel_y)
      aura_source.set_guard_v040(:wide_guard,60)
      aura_source.set_guard_v040(:quick_guard,60)
    end

    f=PMD_AC.skill_data(:mv_feint)
    before=t.hp
    apply_skill_effects(a,t,f,1.0)
    damage=before-t.hp
    protect_removed=!t.guard_active_v040?(:protect)
    wide_removed=(aura_source!=nil && !aura_source.guard_active_v040?(:wide_guard))
    quick_removed=(aura_source!=nil && !aura_source.guard_active_v040?(:quick_guard))
    pass=damage>0 && protect_removed && wide_removed && quick_removed

    log_event(:verify,'GUARD_FEINT_BREAK pass='+(pass ? '1':'0')+
      ' damage='+damage.to_s+
      ' protect_removed='+(protect_removed ? '1':'0')+
      ' affecting_wide_guard_removed='+(wide_removed ? '1':'0')+
      ' affecting_quick_guard_removed='+(quick_removed ? '1':'0')+
      ' same_team_aura_source='+(aura_source!=nil ? '1':'0')+
      ' shadow_force_hook=integrated')
    @verification_done[:guard_feint]=true
  end
end
