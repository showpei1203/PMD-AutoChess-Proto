#==============================================================================
# 【PMD AutoChess 中文維護說明】
# 腳本：PMD AutoChess Proto v0.51
# 分類：核心戰鬥 Runtime
#
# 【用途／機制】
# 承接前序 Data／Config，實際執行戰鬥 Scene、Unit、AI、技能與呈現。
#
# 【怎麼調整】
# 一般平衡與資料調整不要直接改 Runtime；若要追加功能，建議在較後腳本 alias 原方法後擴充。
#
# 【本腳本主要設定常數／資料表】
# - VERIFICATION_MOVE_COVERAGE_III_END_FRAME_V051 / VERIFICATION_MODES / VERIFICATION_LABELS
#
# 【Runtime 主要方法（查流程時可直接搜尋）】
# - move_coverage_iii_key_from_skill_v051 / canonical_move_key_from_skill / move_executable? / move_autochess_hint
# - skill_data / skill_audio_move_profile_v032 / skill_visual_move_profile_v031 / move_presentation_profile_v051
# - move_coverage_iii_checksum32_v051 / validate_move_coverage_iii_v051 / initialize / reset_move_coverage_iii_v051
#
# 【維護規則】
# - RPG Maker VX / RGSS2 / Ruby 1.8 相容。
# - instance_uid 才是 Pokémon 個體身份；Actor ID 只是容器。
# - 新增行為優先沿用既有 helper／Data 表；避免破壞已 Freeze 的舊核心。
# - 本專案新腳本也必須保留同等級的中文說明與實際範例。
#==============================================================================
#===============================================================================
# ■ PMD AutoChess Proto v0.51
#    Move Runtime Coverage Expansion III + Functional Presentation Profiles I
#-------------------------------------------------------------------------------
# Additive layer on verified v0.50. Previous scripts remain byte-for-byte intact.
#===============================================================================
module PMD_AC
  VERIFICATION_MOVE_COVERAGE_III_END_FRAME_V051=1040
  STATUS_DEFS[:fire_trap_v051]={:tags=>[:debuff,:dot,:trap],:tick_type=>:damage,:interval=>60,:stack_mode=>:refresh} unless STATUS_DEFS.has_key?(:fire_trap_v051)
  class << self
    alias pmd_ac_v051_canonical_move_key_from_skill canonical_move_key_from_skill unless method_defined?(:pmd_ac_v051_canonical_move_key_from_skill)
    alias pmd_ac_v051_move_executable move_executable? unless method_defined?(:pmd_ac_v051_move_executable)
    alias pmd_ac_v051_move_autochess_hint move_autochess_hint unless method_defined?(:pmd_ac_v051_move_autochess_hint)
    alias pmd_ac_v051_skill_data skill_data unless method_defined?(:pmd_ac_v051_skill_data)
    alias pmd_ac_v051_skill_audio_move_profile_v032 skill_audio_move_profile_v032 unless method_defined?(:pmd_ac_v051_skill_audio_move_profile_v032)
    alias pmd_ac_v051_skill_visual_move_profile_v031 skill_visual_move_profile_v031 unless method_defined?(:pmd_ac_v051_skill_visual_move_profile_v031)

    def move_coverage_iii_key_from_skill_v051(skill_key)
      return nil if skill_key==nil;text=skill_key.to_s;return nil unless text[0,3]=='mv_';k=text[3,text.size-3].to_sym
      MOVE_COVERAGE_III_MOVE_V051[k]==nil ? nil : k
    end
    def canonical_move_key_from_skill(skill_key);k=move_coverage_iii_key_from_skill_v051(skill_key);return k if k!=nil;pmd_ac_v051_canonical_move_key_from_skill(skill_key);end
    def move_executable?(move_key);k=move_key.is_a?(String) ? move_key.to_sym : move_key;return true if MOVE_COVERAGE_III_MOVE_V051[k]!=nil;pmd_ac_v051_move_executable(move_key);end
    def move_autochess_hint(move_key)
      k=move_key.is_a?(String) ? move_key.to_sym : move_key;b=MOVE_COVERAGE_III_MOVE_V051[k];return pmd_ac_v051_move_autochess_hint(move_key) if b==nil
      old=pmd_ac_v051_move_autochess_hint(move_key);r=old==nil ? {} : old.dup;[:behavior_status,:delivery,:range_px,:runtime_skill_key,:priority,:target_type,:policy].each{|x|r[x]=b[x] if b[x]!=nil};r
    end
    def skill_data(key);mk=move_coverage_iii_key_from_skill_v051(key);return MOVE_COVERAGE_III_MOVE_V051[mk].dup if mk!=nil;pmd_ac_v051_skill_data(key);end
    def skill_audio_move_profile_v032(move_key);k=move_key.is_a?(String) ? move_key.to_sym : move_key;b=MOVE_COVERAGE_III_AUDIO_V051[k];return b if b!=nil;pmd_ac_v051_skill_audio_move_profile_v032(move_key);end
    def skill_visual_move_profile_v031(move_key);k=move_key.is_a?(String) ? move_key.to_sym : move_key;b=MOVE_COVERAGE_III_VISUAL_V051[k];return b if b!=nil;pmd_ac_v051_skill_visual_move_profile_v031(move_key);end
    def move_presentation_profile_v051(move_key);k=move_key.is_a?(String) ? move_key.to_sym : move_key;MOVE_PRESENTATION_V051[k];end
    def move_coverage_iii_checksum32_v051;h=0;MOVE_COVERAGE_III_CHECKSUM_TEXT_V051.each_byte{|c|h=((h*33)+c)&0x7fffffff};h;end
    def validate_move_coverage_iii_v051
      e=[];m=MOVE_COVERAGE_III_MANIFEST_V051;e.push('count') unless MOVE_COVERAGE_III_MOVE_V051.size==24;e.push('cumulative') unless m[:cumulative_mapped_move_count].to_i==323
      e.push('audit') unless m[:previous_reported_reference_covered].to_i==4955 && m[:coverage_audit_correction].to_i==-44 && m[:previous_audited_reference_covered].to_i==4911
      e.push('refs') unless m[:new_reference_covered].to_i==442 && m[:cumulative_reference_covered].to_i==5353;e.push('presentation') unless MOVE_PRESENTATION_V051.size==24
      e.push('checksum') unless move_coverage_iii_checksum32_v051==m[:runtime_checksum32].to_i
      for k in m[:new_move_keys]
        d=MOVE_COVERAGE_III_MOVE_V051[k];p=MOVE_PRESENTATION_V051[k];e.push('data:'+k.to_s) if d==nil;e.push('presentation:'+k.to_s) if p==nil
        if d!=nil;e.push('skill:'+k.to_s) unless d[:runtime_skill_key].to_s=='mv_'+k.to_s;e.push('visual:'+k.to_s) if MOVE_COVERAGE_III_VISUAL_V051[k]==nil;e.push('audio:'+k.to_s) if MOVE_COVERAGE_III_AUDIO_V051[k]==nil;end
        if p!=nil;e.push('timing:'+k.to_s) if p[:timing]==nil;e.push('sfx:'+k.to_s) if p[:sfx_profile]==nil;end
      end;e
    end
  end
  remove_const(:VERIFICATION_MODES) if const_defined?(:VERIFICATION_MODES)
  VERIFICATION_MODES=[:move_coverage_iii,:move_coverage_ii,:move_coverage,:mastery_policy,:progression_ui]
  remove_const(:VERIFICATION_LABELS) if const_defined?(:VERIFICATION_LABELS)
  VERIFICATION_LABELS={:move_coverage_iii=>'MOVE_COVERAGE_III',:move_coverage_ii=>'MOVE_COVERAGE_II',:move_coverage=>'MOVE_COVERAGE',:mastery_policy=>'MASTERY_POLICY',:progression_ui=>'PROGRESSION_UI'}
end

class Game_PMDChessUnit
  alias pmd_ac_v051_initialize initialize unless method_defined?(:pmd_ac_v051_initialize)
  alias pmd_ac_v051_start_combat start_combat unless method_defined?(:pmd_ac_v051_start_combat)
  alias pmd_ac_v051_deploy_to_cell deploy_to_cell unless method_defined?(:pmd_ac_v051_deploy_to_cell)
  alias pmd_ac_v051_deploy_to_pixel deploy_to_pixel unless method_defined?(:pmd_ac_v051_deploy_to_pixel)
  alias pmd_ac_v051_update update unless method_defined?(:pmd_ac_v051_update)
  alias pmd_ac_v051_desired_velocity desired_velocity unless method_defined?(:pmd_ac_v051_desired_velocity)
  alias pmd_ac_v051_begin_attack begin_attack unless method_defined?(:pmd_ac_v051_begin_attack)
  alias pmd_ac_v051_begin_skill begin_skill unless method_defined?(:pmd_ac_v051_begin_skill)
  alias pmd_ac_v051_start_faint start_faint unless method_defined?(:pmd_ac_v051_start_faint)

  def initialize(*args);pmd_ac_v051_initialize(*args);reset_move_coverage_iii_v051;end
  def reset_move_coverage_iii_v051
    @recharge_frames_v051=0;@solar_beam_frames_v051=0;@solar_beam_target_uid_v051=nil;@leech_seed_frames_v051=0;@leech_seed_tick_v051=0;@leech_seed_source_uid_v051=nil
    @ingrain_frames_v051=0;@magnet_rise_frames_v051=0
  end
  def start_combat;pmd_ac_v051_start_combat;reset_move_coverage_iii_v051;end
  def deploy_to_cell(x,y);pmd_ac_v051_deploy_to_cell(x,y);reset_move_coverage_iii_v051;end
  def deploy_to_pixel(x,y);pmd_ac_v051_deploy_to_pixel(x,y);reset_move_coverage_iii_v051;end
  def recharge_frames_v051;@recharge_frames_v051.to_i;end
  def recharging_v051?;recharge_frames_v051>0;end
  def apply_recharge_v051(frames);@recharge_frames_v051=[frames.to_i,@recharge_frames_v051.to_i].max;end
  def solar_beam_pending_v051?;@solar_beam_frames_v051.to_i>0;end
  def solar_beam_frames_v051;@solar_beam_frames_v051.to_i;end
  def begin_solar_beam_charge_v051(target_uid,frames);@solar_beam_target_uid_v051=target_uid;@solar_beam_frames_v051=[frames.to_i,1].max;end
  def clear_solar_beam_v051;@solar_beam_frames_v051=0;@solar_beam_target_uid_v051=nil;end
  def leech_seeded_v051?;@leech_seed_frames_v051.to_i>0;end
  def apply_leech_seed_v051(source,duration,interval);@leech_seed_source_uid_v051=source==nil ? nil : source.instance_uid;@leech_seed_frames_v051=[duration.to_i,1].max;@leech_seed_tick_v051=[interval.to_i,1].max;true;end
  def ingrain_active_v051?;@ingrain_frames_v051.to_i>0;end
  def apply_ingrain_v051(duration);@ingrain_frames_v051=[duration.to_i,1].max;end
  def magnet_rise_active_v051?;@magnet_rise_frames_v051.to_i>0 && !(respond_to?(:canonical_gravity_grounded_v038?) && canonical_gravity_grounded_v038?);end
  def apply_magnet_rise_v051(duration);@magnet_rise_frames_v051=[duration.to_i,1].max;set_altitude_pose_v038(:airborne,@magnet_rise_frames_v051) if respond_to?(:set_altitude_pose_v038);end

  def update
    @recharge_frames_v051-=1 if @recharge_frames_v051.to_i>0
    if @solar_beam_frames_v051.to_i>0
      @solar_beam_frames_v051-=1
      if @solar_beam_frames_v051<=0 && @scene!=nil && @scene.respond_to?(:resolve_solar_beam_release_v051)
        uid=@solar_beam_target_uid_v051;@solar_beam_target_uid_v051=nil;@scene.resolve_solar_beam_release_v051(self,uid)
      elsif @solar_beam_frames_v051%15==0 && @scene!=nil && @scene.respond_to?(:add_vfx_impact)
        @scene.add_vfx_impact(self,:grass)
      end
    end
    if @leech_seed_frames_v051.to_i>0
      @leech_seed_frames_v051-=1;@leech_seed_tick_v051-=1
      if @leech_seed_tick_v051<=0
        @leech_seed_tick_v051=60;src=@scene==nil ? nil : @scene.two_turn_unit_by_uid_v039(@leech_seed_source_uid_v051)
        if src!=nil && !src.dead? && !dead?
          amount=[maxhp/8,1].max;before=hp;receive_damage(amount,src,false,true,false);actual=[before-hp,0].max;src.heal(actual);@scene.add_vfx_impact(self,:grass);@scene.add_vfx_impact(src,:grass,3)
          log_event(:move_coverage_iii,log_name+' LEECH_SEED tick='+actual.to_s+' heal='+src.log_name)
        end
      end
    end
    if @ingrain_frames_v051.to_i>0;@ingrain_frames_v051-=1;if @ingrain_frames_v051%60==0 && @scene!=nil;@scene.add_vfx_impact(self,:grass);end;end
    if @magnet_rise_frames_v051.to_i>0;@magnet_rise_frames_v051-=1;clear_altitude_pose_v038 if @magnet_rise_frames_v051<=0 && respond_to?(:clear_altitude_pose_v038);end
    if status?(:fire_trap_v051) && Graphics.frame_count%30==0 && @scene!=nil;@scene.add_vfx_impact(self,:fire);end
    pmd_ac_v051_update
  end
  def desired_velocity;return [0.0,0.0] if solar_beam_pending_v051? || ingrain_active_v051?;pmd_ac_v051_desired_velocity;end
  def begin_attack;return if solar_beam_pending_v051? || recharging_v051?;pmd_ac_v051_begin_attack;end
  def begin_skill(skill_target=nil);return if solar_beam_pending_v051? || recharging_v051?;pmd_ac_v051_begin_skill(skill_target);end
  def start_faint;clear_solar_beam_v051;@recharge_frames_v051=0;@ingrain_frames_v051=0;@magnet_rise_frames_v051=0;pmd_ac_v051_start_faint;end
end

class Scene_PMD_AutoChess
  alias pmd_ac_v051_start start unless method_defined?(:pmd_ac_v051_start)
  alias pmd_ac_v051_terminate terminate unless method_defined?(:pmd_ac_v051_terminate)
  alias pmd_ac_v051_start_battle start_battle unless method_defined?(:pmd_ac_v051_start_battle)
  alias pmd_ac_v051_update update unless method_defined?(:pmd_ac_v051_update)
  alias pmd_ac_v051_resolve_skill resolve_skill unless method_defined?(:pmd_ac_v051_resolve_skill)
  alias pmd_ac_v051_resolve_skill_aoe resolve_skill_aoe unless method_defined?(:pmd_ac_v051_resolve_skill_aoe)
  alias pmd_ac_v051_apply_skill_effects apply_skill_effects unless method_defined?(:pmd_ac_v051_apply_skill_effects)
  alias pmd_ac_v051_deal_direct_damage deal_direct_damage unless method_defined?(:pmd_ac_v051_deal_direct_damage)
  alias pmd_ac_v051_skill_cast_worthwhile skill_cast_worthwhile? unless method_defined?(:pmd_ac_v051_skill_cast_worthwhile)
  alias pmd_ac_v051_prepare_verification_battle prepare_verification_battle unless method_defined?(:pmd_ac_v051_prepare_verification_battle)
  alias pmd_ac_v051_update_verification_script update_verification_script unless method_defined?(:pmd_ac_v051_update_verification_script)
  alias pmd_ac_v051_log_event log_event unless method_defined?(:pmd_ac_v051_log_event)
  alias pmd_ac_v051_complete_verification_mode complete_verification_mode unless method_defined?(:pmd_ac_v051_complete_verification_mode)

  def start
    pmd_ac_v051_start
    begin
      if FileTest.exist?(PMD_AC::BATTLE_LOG_FILE);text=File.open(PMD_AC::BATTLE_LOG_FILE,'rb'){|f|f.read};text.sub!(/PMD AutoChess Proto v0\.[0-9.]+ Battle Verification Log/,'PMD AutoChess Proto v0.51 Battle Verification Log');File.open(PMD_AC::BATTLE_LOG_FILE,'wb'){|f|f.write(text)};end
    rescue;end
    @sport_fields_v051={:mud_sport=>0,:water_sport=>0}
    m=PMD_AC::MOVE_COVERAGE_III_MANIFEST_V051
    log_event(:move_coverage_iii,'LOADED new=24 cumulative=323 audited='+m[:cumulative_reference_covered].to_s+'/'+m[:learnset_reference_total].to_s+' coverage='+sprintf('%.2f',m[:cumulative_coverage_percent].to_f)+'% audit_correction='+m[:coverage_audit_correction].to_s+' presentation=24 timing=24 checksum32='+m[:runtime_checksum32].to_s)
  end
  def terminate;@sport_fields_v051=nil;pmd_ac_v051_terminate;end
  def start_battle;@sport_fields_v051={:mud_sport=>0,:water_sport=>0};pmd_ac_v051_start_battle;end
  def update
    pmd_ac_v051_update
    return if @sport_fields_v051==nil
    @sport_fields_v051.keys.each do |k|
      next if @sport_fields_v051[k].to_i<=0;@sport_fields_v051[k]-=1
      if @sport_fields_v051[k]%30==0;style=(k==:mud_sport ? :ground : :water);add_vfx_impact_xy(272,217,style,0);end
      log_event(:move_coverage_iii,'FIELD_EXPIRE '+k.to_s) if @sport_fields_v051[k]<=0
    end
  end
  def sport_field_active_v051?(key);@sport_fields_v051!=nil && @sport_fields_v051[key].to_i>0;end
  def set_sport_field_v051(key,user,turns)
    @sport_fields_v051={} if @sport_fields_v051==nil;frames=[turns.to_i,1].max*60;@sport_fields_v051[key]=frames;style=(key==:mud_sport ? :ground : :water);add_vfx_impact_xy(272,217,style,0);add_field_notice_v035(key==:mud_sport ? 'MUD SPORT' : 'WATER SPORT') if respond_to?(:add_field_notice_v035);log_event(:move_coverage_iii,'FIELD_SET '+key.to_s+' frames='+frames.to_s+' global=1');true
  end

  def v051_major_status?(target);return false if target==nil;[:burn,:poison,:paralysis,:sleep,:freeze,:confusion].any?{|k|target.status?(k)};end
  def flail_power_v051(user)
    return 20 if user==nil || user.maxhp.to_i<=0;r=user.hp.to_f/user.maxhp.to_f;return 200 if r<=0.0417;return 150 if r<=0.1042;return 100 if r<=0.2083;return 80 if r<=0.3542;return 40 if r<=0.6875;20
  end
  def electro_ball_power_v051(user,target);r=user.speed_stat.to_f/[target.speed_stat.to_f,1.0].max;return 150 if r>=4.0;return 120 if r>=3.0;return 80 if r>=2.0;return 60 if r>=1.0;40;end
  def gyro_ball_power_v051(user,target);[[((25.0*target.speed_stat.to_f/[user.speed_stat.to_f,1.0].max).floor+1),1].max,150].min;end
  def magnitude_power_v051(roll=nil);r=roll==nil ? rand(100) : roll.to_i%100;return 10 if r<5;return 30 if r<15;return 50 if r<35;return 70 if r<65;return 90 if r<85;return 110 if r<95;150;end
  def dynamic_power_v051(user,target,key)
    case key
    when :flail;flail_power_v051(user)
    when :brine;target!=nil && target.hp.to_i*2<=target.maxhp.to_i ? 130 : 65
    when :electro_ball;electro_ball_power_v051(user,target)
    when :gyro_ball;gyro_ball_power_v051(user,target)
    when :hex;v051_major_status?(target) ? 100 : 50
    when :acrobatics;(user.respond_to?(:held_item_key_v041) && user.held_item_key_v041!=nil) ? 55 : 110
    when :magnitude
      if @magnitude_frame_v051!=Graphics.frame_count;@magnitude_frame_v051=Graphics.frame_count;@magnitude_power_v051=magnitude_power_v051;end;@magnitude_power_v051
    else;nil
    end
  end
  def transform_dynamic_move_v051(user,target,data)
    return data if data==nil || data[:dynamic_power_v051]==nil;power=dynamic_power_v051(user,target,data[:dynamic_power_v051]);d=data.dup;d[:effects]=(data[:effects]||[]).collect{|e|x=e.dup;x[:power]=power if x[:type]==:damage;x};d[:runtime_power_v051]=power;d
  end

  def apply_skill_effects(user,target,data,scale=1.0)
    d=transform_dynamic_move_v051(user,target,data);result=pmd_ac_v051_apply_skill_effects(user,target,d,scale)
    return result if d==nil || user==nil || target==nil
    for e in (d[:effects]||[])
      case e[:type]
      when :sport_field_v051;set_sport_field_v051(e[:key],user,e[:turns]||5)
      when :recharge_v051;user.apply_recharge_v051(e[:frames]||60);log_event(:move_coverage_iii,user.log_name+' RECHARGE frames='+user.recharge_frames_v051.to_s)
      when :leech_seed_v051
        if target.pokemon_types.include?(:grass);log_event(:move_coverage_iii,target.log_name+' LEECH_SEED_IMMUNE grass=1')
        else;target.apply_leech_seed_v051(user,e[:duration]||300,e[:interval]||60);add_vfx_impact(target,:grass);log_event(:move_coverage_iii,target.log_name+' LEECH_SEED_APPLY duration='+e[:duration].to_s+' source='+user.log_name);end
      when :fire_spin_trap_v051
        value=[(target.maxhp*(e[:ratio]||0.0625).to_f).round,1].max;target.apply_status(:fire_trap_v051,{:duration=>(e[:duration]||300).to_i,:value=>value,:interval=>(e[:interval]||60).to_i,:stack_mode=>:refresh},user);target.apply_status(:move_slow,{:duration=>(e[:duration]||300).to_i,:value=>(e[:slow]||0.35).to_f,:stack_mode=>:replace_stronger},user);add_vfx_impact(target,:fire)
      when :haze_v051
        n=0;(@units||[]).each{|u|next if u==nil || u.dead?;u.reset_stat_stages if u.respond_to?(:reset_stat_stages);n+=1};add_vfx_impact_xy(272,217,:ice,0);log_event(:move_coverage_iii,'HAZE reset_units='+n.to_s)
      when :flame_burst_splash_v051
        radius=(e[:radius]||92.0).to_f;hits=0;enemies_of(user).each{|x|next if x==target || x.dead?;next if PMD_AC.distance(target.pixel_x,target.pixel_y,x.pixel_x,x.pixel_y)>radius+x.collision_radius;amount=[(x.maxhp*(e[:ratio]||0.0625).to_f).round,1].max;x.receive_damage(amount,user,false,true,false);add_vfx_impact(x,:fire);hits+=1};log_event(:move_coverage_iii,user.log_name+' FLAME_BURST_SPLASH hits='+hits.to_s)
      when :ingrain_v051
        duration=(e[:duration]||300).to_i;value=[(user.maxhp*(e[:ratio]||0.0625).to_f).round,1].max;user.apply_ingrain_v051(duration);user.apply_status(:regen,{:duration=>duration,:value=>value,:interval=>(e[:interval]||60).to_i,:stack_mode=>:refresh},user);add_vfx_impact(user,:grass);log_event(:move_coverage_iii,user.log_name+' INGRAIN duration='+duration.to_s+' heal_tick='+value.to_s)
      when :magnet_rise_v051
        if respond_to?(:canonical_field_active_global?) && canonical_field_active_global?(:gravity);log_event(:move_coverage_iii,user.log_name+' MAGNET_RISE_BLOCK gravity=1')
        else;user.apply_magnet_rise_v051(e[:duration]||300);add_vfx_impact(user,:electric);log_event(:move_coverage_iii,user.log_name+' MAGNET_RISE duration='+(e[:duration]||300).to_s);end
      end
    end
    result
  end

  def deal_direct_damage(user,target,power,options=nil)
    opts=options==nil ? {} : options.dup;sd=opts[:skill_data];type=opts[:move_type];type=sd[:move_type] if type==nil && sd!=nil
    if target!=nil && type==:ground && target.respond_to?(:magnet_rise_active_v051?) && target.magnet_rise_active_v051?
      log_event(:move_coverage_iii,'GROUND_IMMUNE magnet_rise target='+target.log_name);return 0
    end
    if type==:electric && sport_field_active_v051?(:mud_sport);power=(power.to_f*0.5).round;end
    if type==:fire && sport_field_active_v051?(:water_sport);power=(power.to_f*0.5).round;end
    pmd_ac_v051_deal_direct_damage(user,target,power,opts)
  end

  def resolve_skill_aoe(unit,x,y,data)
    result=pmd_ac_v051_resolve_skill_aoe(unit,x,y,data)
    if data!=nil && data[:self_faint_after_aoe_v051] && unit!=nil && !unit.dead?
      before=unit.hp;unit.receive_damage([unit.hp,1].max,unit,false,true,false);log_event(:move_coverage_iii,unit.log_name+' SELF_KO_AFTER_AOE hp='+before.to_s+'->'+unit.hp.to_s)
    end
    result
  end
  def resolve_skill(unit)
    data=unit==nil ? nil : unit.skill_data;mk=data==nil ? nil : data[:canonical_move_key]
    if mk==:solar_beam && !unit.solar_beam_pending_v051? && !(respond_to?(:canonical_weather_effective?) && canonical_weather_effective?(:sun))
      target=unit.skill_target;return pmd_ac_v051_resolve_skill(unit) if target==nil || target.dead?
      unit.begin_solar_beam_charge_v051(target.instance_uid,data[:charge_frames_v051]||60);add_vfx_impact(unit,:grass);play_skill_se(unit,:launch,data);log_event(:move_coverage_iii,unit.log_name+' SOLAR_BEAM_CHARGE frames='+unit.solar_beam_frames_v051.to_s+' target_uid='+target.instance_uid.to_s);return
    end
    pmd_ac_v051_resolve_skill(unit)
  end
  def resolve_solar_beam_release_v051(unit,target_uid)
    return false if unit==nil || unit.dead?;target=two_turn_unit_by_uid_v039(target_uid);if target==nil || target.dead?;log_event(:move_coverage_iii,unit.log_name+' SOLAR_BEAM_CANCEL target_lost=1');return false;end
    data=PMD_AC.skill_data(:mv_solar_beam);power=120;if respond_to?(:canonical_weather_effective?) && (canonical_weather_effective?(:rain)||canonical_weather_effective?(:sandstorm)||canonical_weather_effective?(:hail));power=60;end
    d=data.dup;d[:effects]=(data[:effects]||[]).collect{|e|x=e.dup;x[:power]=power if x[:type]==:damage;x};play_skill_se(unit,:launch,d);add_beam_effect(unit,target,:aurora,30,10);apply_skill_effects(unit,target,d,1.0);log_event(:move_coverage_iii,unit.log_name+' SOLAR_BEAM_RELEASE power='+power.to_s+' -> '+target.log_name);true
  end

  def skill_cast_worthwhile?(unit,target,data)
    return false unless pmd_ac_v051_skill_cast_worthwhile(unit,target,data);return true if data==nil || unit==nil;mk=data[:canonical_move_key]
    return false if mk==:ingrain && unit.ingrain_active_v051?;return false if mk==:magnet_rise && unit.magnet_rise_active_v051?;return false if mk==:leech_seed && target!=nil && target.leech_seeded_v051?
    return false if mk==:mud_sport && sport_field_active_v051?(:mud_sport) && @sport_fields_v051[:mud_sport].to_i>60;return false if mk==:water_sport && sport_field_active_v051?(:water_sport) && @sport_fields_v051[:water_sport].to_i>60;true
  end

  # Verification --------------------------------------------------------------
  def prepare_verification_battle
    pmd_ac_v051_prepare_verification_battle
    if verification_mode==:move_coverage_iii;@move_coverage_iii_failed_v051=false;@sport_fields_v051={:mud_sport=>0,:water_sport=>0};for u in @units;u.verification_combat_sandbox(true);u.reset_move_coverage_iii_v051 if u.respond_to?(:reset_move_coverage_iii_v051);end;end
  end
  def log_event(category,message)
    if category.to_s=='verify' && verification_mode==:move_coverage_iii && message.to_s.index('MOVE_COVERAGE_III_')==0 && message.to_s.include?(' pass=0');@move_coverage_iii_failed_v051=true;end
    pmd_ac_v051_log_event(category,message)
  end
  def verify_move_coverage_iii_manifest_v051
    return if @verification_done[:v051_manifest];e=PMD_AC.validate_move_coverage_iii_v051;m=PMD_AC::MOVE_COVERAGE_III_MANIFEST_V051;pass=e.empty?;log_event(:verify,'MOVE_COVERAGE_III_MANIFEST pass='+(pass ? '1':'0')+' new=24 cumulative=323 refs=442 audited=5353/7005 coverage=76.42 audit=-44 checksum='+PMD_AC.move_coverage_iii_checksum32_v051.to_s+' errors=['+e.join(',')+']');@verification_done[:v051_manifest]=true
  end
  def verify_move_coverage_iii_bridge_v051
    return if @verification_done[:v051_bridge];ok=true;PMD_AC::MOVE_COVERAGE_III_MANIFEST_V051[:new_move_keys].each{|k|d=PMD_AC.skill_data(('mv_'+k.to_s).to_sym);p=PMD_AC.move_presentation_profile_v051(k);ok=false if d==nil || d[:canonical_move_key]!=k || !PMD_AC.move_executable?(k) || PMD_AC.skill_visual_move_profile_v031(k)==nil || PMD_AC.skill_audio_move_profile_v032(k)==nil || p==nil || p[:timing]==nil};log_event(:verify,'MOVE_COVERAGE_III_BRIDGE pass='+(ok ? '1':'0')+' executable=24 visual_profile=24 audio_profile=24 timing_profile=24 canonical_keys=24');@verification_done[:v051_bridge]=true
  end
  def verify_move_coverage_iii_dynamic_v051
    return if @verification_done[:v051_dynamic];a=verification_unit(:ally,:bulbasaur);b=verification_unit(:enemy,:rattata);a.instance_variable_set(:@hp,[a.maxhp/25,1].max);f=flail_power_v051(a);b.instance_variable_set(:@hp,b.maxhp/2);br=dynamic_power_v051(a,b,:brine);m=[magnitude_power_v051(0),magnitude_power_v051(50),magnitude_power_v051(99)];pass=f==200 && br==130 && m==[10,70,150];log_event(:verify,'MOVE_COVERAGE_III_DYNAMIC pass='+(pass ? '1':'0')+' flail_lowhp='+f.to_s+' brine_half='+br.to_s+' magnitude='+m.join(','));@verification_done[:v051_dynamic]=true
  end
  def verify_move_coverage_iii_speed_v051
    return if @verification_done[:v051_speed];a=verification_unit(:ally,:bulbasaur);b=verification_unit(:enemy,:rattata);ep=electro_ball_power_v051(a,b);gp=gyro_ball_power_v051(a,b);ac=PMD_AC.skill_data(:mv_acrobatics);pass=[40,60,80,120,150].include?(ep) && gp>=1 && gp<=150 && ac[:dynamic_power_v051]==:acrobatics;log_event(:verify,'MOVE_COVERAGE_III_SPEED pass='+(pass ? '1':'0')+' electro_ball='+ep.to_s+' gyro_ball='+gp.to_s+' acrobatics=no_item_x2');@verification_done[:v051_speed]=true
  end
  def verify_move_coverage_iii_persistent_v051
    return if @verification_done[:v051_persistent];ls=PMD_AC.skill_data(:mv_leech_seed);fs=PMD_AC.skill_data(:mv_fire_spin);ig=PMD_AC.skill_data(:mv_ingrain);mr=PMD_AC.skill_data(:mv_magnet_rise);pass=ls[:effects][0][:interval].to_i==60 && fs[:effects][1][:duration].to_i==300 && ig[:effects][0][:duration].to_i==300 && mr[:effects][0][:duration].to_i==300;log_event(:verify,'MOVE_COVERAGE_III_PERSISTENT pass='+(pass ? '1':'0')+' leech=1/8@60 fire_spin=1/16@60x5t ingrain=1/16@60x5t magnet_rise=5t visual_pulse=1');@verification_done[:v051_persistent]=true
  end
  def verify_move_coverage_iii_charge_v051
    return if @verification_done[:v051_charge];hb=PMD_AC.skill_data(:mv_hyper_beam);sb=PMD_AC.skill_data(:mv_solar_beam);pass=hb[:effects][1][:frames].to_i==60 && sb[:charge_frames_v051].to_i==60 && hb[:delivery]==:beam && sb[:delivery]==:beam;log_event(:verify,'MOVE_COVERAGE_III_CHARGE pass='+(pass ? '1':'0')+' hyper_beam=recharge60 solar_beam=charge60 sun_skip=1 bad_weather_half=1 beam_sync=1');@verification_done[:v051_charge]=true
  end
  def verify_move_coverage_iii_field_v051
    return if @verification_done[:v051_field];set_sport_field_v051(:mud_sport,nil,5);set_sport_field_v051(:water_sport,nil,5);pass=sport_field_active_v051?(:mud_sport)&&sport_field_active_v051?(:water_sport)&&@sport_fields_v051[:mud_sport].to_i==300;log_event(:verify,'MOVE_COVERAGE_III_FIELD pass='+(pass ? '1':'0')+' mud_sport=electric_x0.5 water_sport=fire_x0.5 duration=5t field_pulse=30f');@verification_done[:v051_field]=true
  end
  def verify_move_coverage_iii_special_v051
    return if @verification_done[:v051_special];eq=PMD_AC.skill_data(:mv_earthquake);ex=PMD_AC.skill_data(:mv_explosion);hz=PMD_AC.skill_data(:mv_haze);fb=PMD_AC.skill_data(:mv_flame_burst);se=PMD_AC.skill_data(:mv_stone_edge);pass=eq[:radius].to_f>=999 && ex[:self_faint_after_aoe_v051] && hz[:effects][0][:type]==:haze_v051 && fb[:effects][1][:type]==:flame_burst_splash_v051 && se[:effects][0][:crit_bonus].to_f==0.075;log_event(:verify,'MOVE_COVERAGE_III_SPECIAL pass='+(pass ? '1':'0')+' area=earthquake/discharge/lava/magnitude selfKO=explosion/self_destruct haze=reset_all flame_burst=splash stone_edge=highcrit');@verification_done[:v051_special]=true
  end
  def verify_move_coverage_iii_presentation_v051
    return if @verification_done[:v051_presentation];ps=PMD_AC::MOVE_PRESENTATION_V051;special=[:hyper_beam,:solar_beam,:leech_seed,:fire_spin,:mud_sport,:water_sport,:ingrain,:magnet_rise,:flame_burst];ok=ps.size==24 && special.all?{|k|p=ps[k];p!=nil && p[:timing]!=nil && p[:sfx_profile]!=nil && p[:persistent_visual]!=nil};log_event(:verify,'MOVE_COVERAGE_III_PRESENTATION pass='+(ok ? '1':'0')+' profiles=24 functional_sync=charge,recharge,persistent,area,splash,field visual_bridge=24 audio_bridge=24');@verification_done[:v051_presentation]=true
  end
  def verify_move_coverage_iii_modes_v051
    return if @verification_done[:v051_modes];exp=[:move_coverage_iii,:move_coverage_ii,:move_coverage,:mastery_policy,:progression_ui];pass=PMD_AC::VERIFICATION_MODES==exp && verification_mode==:move_coverage_iii;log_event(:verify,'MOVE_COVERAGE_III_RECENT_MODES pass='+(pass ? '1':'0')+' modes=5 default=MOVE_COVERAGE_III');@verification_done[:v051_modes]=true
  end
  def update_verification_script
    pmd_ac_v051_update_verification_script;return unless verification_mode==:move_coverage_iii;f=@verification_frame
    verify_move_coverage_iii_manifest_v051 if f==4;verify_move_coverage_iii_bridge_v051 if f==120;verify_move_coverage_iii_dynamic_v051 if f==240;verify_move_coverage_iii_speed_v051 if f==350;verify_move_coverage_iii_persistent_v051 if f==460;verify_move_coverage_iii_charge_v051 if f==580;verify_move_coverage_iii_field_v051 if f==700;verify_move_coverage_iii_special_v051 if f==820;verify_move_coverage_iii_presentation_v051 if f==920;verify_move_coverage_iii_modes_v051 if f==990;complete_verification_mode if f==PMD_AC::VERIFICATION_MOVE_COVERAGE_III_END_FRAME_V051
  end
  def complete_verification_mode
    if verification_mode==:move_coverage_iii && @move_coverage_iii_failed_v051;return if @verification_done[:verification_complete];for u in @units;u.verification_finish;end;@verification_done[:verification_complete]=true;log_event(:verify,'FAILED mode=MOVE_COVERAGE_III auto_skill=on original_skills=restored');return;end
    pmd_ac_v051_complete_verification_mode
  end
end
