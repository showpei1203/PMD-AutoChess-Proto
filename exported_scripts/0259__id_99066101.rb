#==============================================================================
# 【PMD AutoChess 中文維護說明】
# 腳本：PMD AutoChess Proto v0.66.1 Verifier Fix
# 分類：核心戰鬥 Runtime
#
# 【用途／機制】
# 承接前序 Data／Config，實際執行戰鬥 Scene、Unit、AI、技能與呈現。
#
# 【怎麼調整】
# 一般平衡與資料調整不要直接改 Runtime；若要追加功能，建議在較後腳本 alias 原方法後擴充。
#
# 【Runtime 主要方法（查流程時可直接搜尋）】
# - start / verify_ability_infiltrator_v066
#
# 【維護規則】
# - RPG Maker VX / RGSS2 / Ruby 1.8 相容。
# - instance_uid 才是 Pokémon 個體身份；Actor ID 只是容器。
# - 新增行為優先沿用既有 helper／Data 表；避免破壞已 Freeze 的舊核心。
# - 本專案新腳本也必須保留同等級的中文說明與實際範例。
#==============================================================================
#==============================================================================
# PMD AutoChess Proto v0.66.1 - Infiltrator Mist Verifier Fix
# RGSS2 / Ruby 1.8 compatible
#
# Runtime mechanics are unchanged.
# v0.36 models Mist as a follow-source aura.  Its source-alive check requires
# the source unit to belong to Scene_PMD_AutoChess @units.  v0.66 verification
# units intentionally live outside @units, so the Mist half of the verifier
# tested an inactive aura and produced -1 -> -1.  This patch temporarily
# registers only the Mist test source while the synchronous assertion runs.
#==============================================================================
class Scene_PMD_AutoChess
  alias pmd_ac_v0661_start start unless method_defined?(:pmd_ac_v0661_start)
  def start
    pmd_ac_v0661_start
    begin
      if FileTest.exist?(PMD_AC::BATTLE_LOG_FILE)
        t=File.open(PMD_AC::BATTLE_LOG_FILE,'rb'){|f|f.read}
        t.sub!(/PMD AutoChess Proto v0\.66 Battle Verification Log/,'PMD AutoChess Proto v0.66.1 Battle Verification Log')
        File.open(PMD_AC::BATTLE_LOG_FILE,'wb'){|f|f.write(t)}
      end
    rescue
    end
    log_event(:presentation,'PATCH v0.66.1 infiltrator_mist_verifier_aura_source_registry_fix=1 verifier_only=1 mechanics_unchanged=1')
  end

  def verify_ability_infiltrator_v066
    return if @verification_done[:v066_infiltrator]
    a=ability_runtime_verification_unit_v066(:spiritomb,:hidden,:ally,1)
    plain=ability_runtime_verification_unit_v066(:rattata,:primary,:ally,2)
    t=ability_runtime_verification_unit_v066(:rattata,:primary,:enemy,3)
    a.deploy_to_cell(0,2);plain.deploy_to_cell(0,3);t.deploy_to_cell(4,2)

    set_canonical_field_effect_v035(:reflect,t,5)
    t.canonical_set_direct_damage_context({:user=>plain,:category=>:physical,:move_type=>:normal,:skill_data=>nil})
    before=t.hp;t.receive_damage(90,plain,false,true,false);reflect_plain=before-t.hp
    t.canonical_clear_direct_damage_context
    t.canonical_set_direct_damage_context({:user=>a,:category=>:physical,:move_type=>:normal,:skill_data=>nil})
    before=t.hp;t.receive_damage(90,a,false,true,false);reflect_infil=before-t.hp
    t.canonical_clear_direct_damage_context
    clear_canonical_field_effect_v035(:reflect,:enemy,:verify)

    set_canonical_field_effect_v035(:light_screen,t,5)
    t.canonical_set_direct_damage_context({:user=>plain,:category=>:special,:move_type=>:dark,:skill_data=>nil})
    before=t.hp;t.receive_damage(90,plain,false,true,false);screen_plain=before-t.hp
    t.canonical_clear_direct_damage_context
    t.canonical_set_direct_damage_context({:user=>a,:category=>:special,:move_type=>:dark,:skill_data=>nil})
    before=t.hp;t.receive_damage(90,a,false,true,false);screen_infil=before-t.hp
    t.canonical_clear_direct_damage_context
    clear_canonical_field_effect_v035(:light_screen,:enemy,:verify)

    set_canonical_field_effect_v035(:safeguard,t,5)
    s1=t.apply_status(:burn,{:duration=>60},plain);t.remove_status(:burn)
    s2=t.apply_status(:burn,{:duration=>60},a);t.remove_status(:burn)
    clear_canonical_field_effect_v035(:safeguard,:enemy,:verify)

    # Mist is a v0.36 follow-source aura.  Verification units are sandbox-only
    # and normally stay outside @units, but aura liveness deliberately checks
    # membership there.  Register the source only for this synchronous test.
    added=false
    if @units!=nil && !@units.include?(t)
      @units.push(t);added=true
    end
    begin
      set_canonical_field_effect_v035(:mist,t,5)
      t.reset_stat_stages;d1=t.change_stat_stage(:atk,-1,plain)
      t.reset_stat_stages;d2=t.change_stat_stage(:atk,-1,a)
      clear_canonical_field_effect_v035(:mist,:enemy,:verify)
    ensure
      @units.delete(t) if added && @units!=nil
    end

    ok=a.ability_key==:infiltrator && reflect_plain==60 && reflect_infil==90 &&
      screen_plain==60 && screen_infil==90 && !s1 && s2 && d1.to_i==0 && d2.to_i==-1
    log_event(:verify,'ABILITY_INFILTRATOR_V066 pass='+(ok ? '1':'0')+
      ' reflect='+reflect_plain.to_s+'->'+reflect_infil.to_s+
      ' light_screen='+screen_plain.to_s+'->'+screen_infil.to_s+
      ' safeguard='+(!s1 ? 'block':'fail')+'->'+(s2 ? 'bypass':'fail')+
      ' mist='+d1.to_i.to_s+'->'+d2.to_i.to_s+
      ' gen5_substitute_bypass=0 field_layer=v0.35 verifier_fix=v0.66.1')
    @verification_done[:v066_infiltrator]=true
  end
end
