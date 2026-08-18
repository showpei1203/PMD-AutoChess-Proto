# encoding: UTF-8
#===============================================================================
# ■ PMD AutoChess - Important Skill / Boss Focus Overrides I v1.05.15
#===============================================================================
# 【用途】
# 1. 進入 Battle Readability Roadmap Phase B1，讓少量「重要／招牌技能」與 Boss 技能
#    在既有 v1.05.8 Focus Action Lane 上擁有更有份量的 Presentation Profile。
# 2. 一般技能完全維持既有 48f precharge / 232 mask / orbit charge；重要技能與 Boss
#    只改 Focus 視覺時序與 charge style，不改 Damage、AI、Energy、Attack Wait、Priority、
#    hit timing、logical Spatial endpoint 或技能資料。
# 3. v1.05.13 的 18f Result Hold、KO；v1.05.14 的紅／藍多光圈能力變化全部保留。
#
# 【重要技能初始清單】
# 只收錄辨識度高、理應讓玩家停下來看的招牌／究極招式；不是單純依威力門檻判定。
# Hyper Beam / Solar Beam / Giga Impact / Frenzy Plant / Blast Burn / Hydro Cannon /
# Draco Meteor / Roar of Time / Spacial Rend / Shadow Force / Judgment / Aeroblast /
# Sacred Fire / Doom Desire / Psycho Boost / Volt Tackle。
# 若日後需要擴充，只調 IMPORTANT_FOCUS_SKILL_TYPES_V10515。
#
# 【Presentation Profile】
# standard：沿用 v1.05.8，完全不改。
# important：precharge 60f、fade in 12f、mask 242、signature charge。
# boss：precharge 72f、fade in 14f、mask 248、boss charge。
# Result Hold 仍是 v1.05.13 的 18f，避免本版同時改兩種閱讀停頓。
#
# 【Charge Style】
# signature：雙層收束環繞，粒子逐步向施放者聚攏，亮度較標準 orbit 高。
# boss：更寬的雙向旋轉環，最後收束，保留既有 8 粒子上限，不新增大量 sprite。
#
# 【Boss 判定】
# 優先沿用 Game_PMDChessUnit#boss；不存在或 false 就不假裝是 Boss。
#
# 【設定／可調參數】
# IMPORTANT_FOCUS_PRECHARGE_V10515 = 60
# BOSS_FOCUS_PRECHARGE_V10515 = 72
# IMPORTANT_FOCUS_MASK_V10515 = 242
# BOSS_FOCUS_MASK_V10515 = 248
# IMPORTANT_FOCUS_SKILL_TYPES_V10515 = [...]  # :mv_xxx runtime skill keys
#
# 【事件／腳本呼叫】
# 無需事件呼叫；NORMAL battle 自動判定。
# 可由後續腳本把 runtime skill key 加入 IMPORTANT_FOCUS_SKILL_TYPES_V10515 的同等維護表。
# 本版不直接修改 Frozen Combat Core。
#
# 【範例】
# - 一般水槍：仍使用 standard Focus，不變。
# - Hyper Beam：60f precharge + signature charge + mask 242。
# - Boss 大針蜂的任何 Focus 技能：72f precharge + boss charge + mask 248。
#
# 【LOG】
# BATTLE_IMPORTANT_BOSS_FOCUS_V10515 START ...
# BATTLE_FOCUS_TIER_V10515 user=... skill=... skill_type=... tier=... precharge=...
# BATTLE_IMPORTANT_BOSS_FOCUS_SUMMARY_V10515 standard=... important=... boss=...
#===============================================================================
$imported={} unless defined?($imported)
$imported['PMD_AutoChess_ImportantBossFocusOverridesI_v10515']=true

module PMD_AC
  IMPORTANT_FOCUS_PRECHARGE_V10515 = 60
  IMPORTANT_FOCUS_FADE_IN_V10515 = 12
  IMPORTANT_FOCUS_FADE_OUT_V10515 = 22
  IMPORTANT_FOCUS_MASK_V10515 = 242

  BOSS_FOCUS_PRECHARGE_V10515 = 72
  BOSS_FOCUS_FADE_IN_V10515 = 14
  BOSS_FOCUS_FADE_OUT_V10515 = 24
  BOSS_FOCUS_MASK_V10515 = 248

  IMPORTANT_FOCUS_SKILL_TYPES_V10515 = [
    :mv_hyper_beam,:mv_solar_beam,:mv_giga_impact,
    :mv_frenzy_plant,:mv_blast_burn,:mv_hydro_cannon,
    :mv_draco_meteor,:mv_roar_of_time,:mv_spacial_rend,:mv_shadow_force,
    :mv_judgment,:mv_aeroblast,:mv_sacred_fire,:mv_doom_desire,
    :mv_psycho_boost,:mv_volt_tackle
  ]
end

class Scene_PMD_AutoChess
  alias pmd_ac_v10515_focus_profile focus_cast_profile_v1055 unless method_defined?(:pmd_ac_v10515_focus_profile)
  alias pmd_ac_v10515_focus_begin focus_cast_begin_v1055 unless method_defined?(:pmd_ac_v10515_focus_begin)
  alias pmd_ac_v10515_start_battle start_battle unless method_defined?(:pmd_ac_v10515_start_battle)
  alias pmd_ac_v10515_focus_summary focus_cast_log_summary_v1055 unless method_defined?(:pmd_ac_v10515_focus_summary)

  def focus_skill_type_v10515(user)
    return nil if user==nil
    user.instance_variable_get(:@skill_type)
  rescue
    nil
  end

  def focus_tier_v10515(user)
    return :standard if user==nil
    begin
      return :boss if user.respond_to?(:boss) && user.boss
    rescue
    end
    key=focus_skill_type_v10515(user)
    return :important if PMD_AC::IMPORTANT_FOCUS_SKILL_TYPES_V10515.include?(key)
    :standard
  rescue
    :standard
  end

  def focus_cast_profile_v1055(user)
    p=pmd_ac_v10515_focus_profile(user)
    p={} if p==nil
    tier=focus_tier_v10515(user)
    if tier==:important
      p[:intro_frames]=PMD_AC::IMPORTANT_FOCUS_PRECHARGE_V10515
      p[:fade_in_frames]=PMD_AC::IMPORTANT_FOCUS_FADE_IN_V10515
      p[:fade_out_frames]=PMD_AC::IMPORTANT_FOCUS_FADE_OUT_V10515
      p[:mask_opacity]=PMD_AC::IMPORTANT_FOCUS_MASK_V10515
      p[:charge_style]=:signature
    elsif tier==:boss
      p[:intro_frames]=PMD_AC::BOSS_FOCUS_PRECHARGE_V10515
      p[:fade_in_frames]=PMD_AC::BOSS_FOCUS_FADE_IN_V10515
      p[:fade_out_frames]=PMD_AC::BOSS_FOCUS_FADE_OUT_V10515
      p[:mask_opacity]=PMD_AC::BOSS_FOCUS_MASK_V10515
      p[:charge_style]=:boss
    end
    p
  rescue
    pmd_ac_v10515_focus_profile(user)
  end

  # v1.05.5 的動態 dispatch 會尋找 focus_cast_charge_<style>_v1055。
  def focus_cast_charge_signature_v1055(age,intro)
    return if @focus_cast_owner_v1055==nil
    a=focus_cast_anchor_v1055(@focus_cast_owner_v1055)
    ratio=intro<=1 ? 1.0 : age.to_f/intro.to_f
    ratio=0.0 if ratio<0.0;ratio=1.0 if ratio>1.0
    count=PMD_AC::FOCUS_CAST_PARTICLE_COUNT_V1055
    (@focus_cast_particles_v1055 || []).each_with_index do |sp,i|
      next if sp==nil
      band=(i%2==0 ? 1.0 : 0.72)
      radius=(46.0-(34.0*ratio))*band
      ang=(Math::PI*2.0*i.to_f/count.to_f)+(age.to_f*(i%2==0 ? 0.20 : -0.16))
      sp.x=(a[0]+Math.cos(ang)*radius).to_i
      sp.y=(a[1]-6+Math.sin(ang)*radius*0.48).to_i
      sp.z=20025+i
      pulse=185+(Math.sin(age.to_f*0.62+i)*55).to_i
      pulse=110 if pulse<110;pulse=255 if pulse>255
      sp.opacity=pulse
      sp.zoom_x=0.90+ratio*0.55
      sp.zoom_y=sp.zoom_x
      sp.visible=true
    end
  rescue
  end

  def focus_cast_charge_boss_v1055(age,intro)
    return if @focus_cast_owner_v1055==nil
    a=focus_cast_anchor_v1055(@focus_cast_owner_v1055)
    ratio=intro<=1 ? 1.0 : age.to_f/intro.to_f
    ratio=0.0 if ratio<0.0;ratio=1.0 if ratio>1.0
    count=PMD_AC::FOCUS_CAST_PARTICLE_COUNT_V1055
    (@focus_cast_particles_v1055 || []).each_with_index do |sp,i|
      next if sp==nil
      outer=(i<4)
      radius=(outer ? 58.0 : 38.0) - (outer ? 40.0 : 26.0)*ratio
      direction=(outer ? 1.0 : -1.0)
      ang=(Math::PI*2.0*i.to_f/count.to_f)+(age.to_f*0.18*direction)
      sp.x=(a[0]+Math.cos(ang)*radius).to_i
      sp.y=(a[1]-7+Math.sin(ang)*radius*0.52).to_i
      sp.z=20026+i
      pulse=205+(Math.sin(age.to_f*0.48+i)*45).to_i
      pulse=130 if pulse<130;pulse=255 if pulse>255
      sp.opacity=pulse
      sp.zoom_x=1.00+ratio*0.62
      sp.zoom_y=sp.zoom_x
      sp.visible=true
    end
  rescue
  end

  def focus_cast_begin_v1055(user,target)
    tier=focus_tier_v10515(user)
    ok=pmd_ac_v10515_focus_begin(user,target)
    if ok
      p=@focus_cast_profile_v1055 || focus_cast_profile_v1055(user)
      @focus_tier_current_v10515=tier
      @focus_tier_standard_count_v10515=@focus_tier_standard_count_v10515.to_i+1 if tier==:standard
      @focus_tier_important_count_v10515=@focus_tier_important_count_v10515.to_i+1 if tier==:important
      @focus_tier_boss_count_v10515=@focus_tier_boss_count_v10515.to_i+1 if tier==:boss
      log_event(:battle,'BATTLE_FOCUS_TIER_V10515 user='+(user==nil ? 'NONE' : user.log_name.to_s)+
        ' skill='+(user==nil ? 'NONE' : user.skill_name.to_s)+
        ' skill_type='+(focus_skill_type_v10515(user)==nil ? 'NONE' : focus_skill_type_v10515(user).to_s)+
        ' tier='+tier.to_s+
        ' precharge='+p[:intro_frames].to_i.to_s+
        ' fade_in='+p[:fade_in_frames].to_i.to_s+
        ' fade_out='+p[:fade_out_frames].to_i.to_s+
        ' mask='+p[:mask_opacity].to_i.to_s+
        ' charge='+(p[:charge_style]||:orbit).to_s)
    end
    ok
  rescue
    false
  end

  def start_battle
    r=pmd_ac_v10515_start_battle
    if respond_to?(:verification_mode) && verification_mode==:normal
      @focus_tier_standard_count_v10515=0
      @focus_tier_important_count_v10515=0
      @focus_tier_boss_count_v10515=0
      log_event(:battle,'BATTLE_IMPORTANT_BOSS_FOCUS_V10515 START'+
        ' standard_precharge=48 important_precharge='+PMD_AC::IMPORTANT_FOCUS_PRECHARGE_V10515.to_s+
        ' boss_precharge='+PMD_AC::BOSS_FOCUS_PRECHARGE_V10515.to_s+
        ' important_mask='+PMD_AC::IMPORTANT_FOCUS_MASK_V10515.to_s+
        ' boss_mask='+PMD_AC::BOSS_FOCUS_MASK_V10515.to_s+
        ' important_charge=signature boss_charge=boss'+
        ' important_skill_count='+PMD_AC::IMPORTANT_FOCUS_SKILL_TYPES_V10515.size.to_s+
        ' damage_formula_unchanged=1 hp_unchanged=1 ai_choice_unchanged=1 energy_amount_unchanged=1'+
        ' attack_wait_unchanged=1 spatial_endpoint_unchanged=1 hit_timing_unchanged=1')
    end
    r
  end

  def important_boss_focus_summary_v10515
    log_event(:battle,'BATTLE_IMPORTANT_BOSS_FOCUS_SUMMARY_V10515'+
      ' standard='+@focus_tier_standard_count_v10515.to_i.to_s+
      ' important='+@focus_tier_important_count_v10515.to_i.to_s+
      ' boss='+@focus_tier_boss_count_v10515.to_i.to_s+
      ' result_hold_v10513_retained=1 orbit_stat_fx_v10514_retained=1')
    true
  rescue
    false
  end

  def focus_cast_log_summary_v1055
    r=pmd_ac_v10515_focus_summary
    important_boss_focus_summary_v10515
    r
  rescue
    false
  end
end
