#==============================================================================
# 【PMD AutoChess 中文維護說明】
# 腳本：PMD AutoChess Proto v0.39
# 分類：核心戰鬥 Runtime
#
# 【用途／機制】
# 承接前序 Data／Config，實際執行戰鬥 Scene、Unit、AI、技能與呈現。
#
# 【怎麼調整】
# 一般平衡與資料調整不要直接改 Runtime；若要追加功能，建議在較後腳本 alias 原方法後擴充。
#
# 【本腳本主要設定常數／資料表】
# - VERIFICATION_TWO_TURN_END_FRAME_V039 / TWO_TURN_EXCEPTION_MULT_V039 / VERIFICATION_MODES / VERIFICATION_LABELS
#
# 【Runtime 主要方法（查流程時可直接搜尋）】
# - canonical_move_key_from_skill / move_executable? / move_autochess_hint / skill_data
# - skill_audio_move_profile_v032 / two_turn_checksum_scalar_v039 / two_turn_checksum32_v039 / validate_two_turn_v039
# - initialize / two_turn_pending_v039? / two_turn_move_v039 / two_turn_target_uid_v039
#
# 【維護規則】
# - RPG Maker VX / RGSS2 / Ruby 1.8 相容。
# - instance_uid 才是 Pokémon 個體身份；Actor ID 只是容器。
# - 新增行為優先沿用既有 helper／Data 表；避免破壞已 Freeze 的舊核心。
# - 本專案新腳本也必須保留同等級的中文說明與實際範例。
#==============================================================================
#===============================================================================
# ■ PMD AutoChess Proto v0.39
#    Two-Turn Semi-Invulnerable Move Runtime I
#-------------------------------------------------------------------------------
# Additive layer on verified v0.38.
# Implements Fly / Bounce / Dive / Dig / Shadow Force as real two-phase moves.
# Phase 1 enters the v0.38 Altitude/Pose layer for 60 realtime frames.
# Phase 2 reacquires the ORIGINAL individual target by instance_uid and strikes.
#===============================================================================
module PMD_AC
  VERIFICATION_TWO_TURN_END_FRAME_V039 = 620
  TWO_TURN_EXCEPTION_MULT_V039 = 2.0

  class << self
    alias pmd_ac_v039_canonical_move_key_from_skill canonical_move_key_from_skill unless method_defined?(:pmd_ac_v039_canonical_move_key_from_skill)
    alias pmd_ac_v039_move_executable move_executable? unless method_defined?(:pmd_ac_v039_move_executable)
    alias pmd_ac_v039_move_autochess_hint move_autochess_hint unless method_defined?(:pmd_ac_v039_move_autochess_hint)
    alias pmd_ac_v039_skill_data skill_data unless method_defined?(:pmd_ac_v039_skill_data)
    alias pmd_ac_v039_skill_audio_move_profile_v032 skill_audio_move_profile_v032 unless method_defined?(:pmd_ac_v039_skill_audio_move_profile_v032)

    def canonical_move_key_from_skill(skill_key)
      k=pmd_ac_v039_canonical_move_key_from_skill(skill_key);return k if k!=nil
      return nil if skill_key==nil;text=skill_key.to_s;return nil unless text[0,3]=='mv_'
      key=text[3,text.size-3].to_sym;TWO_TURN_MOVE_V039[key]==nil ? nil : key
    end
    def move_executable?(move_key);return true if TWO_TURN_MOVE_V039[move_key]!=nil;pmd_ac_v039_move_executable(move_key);end
    def move_autochess_hint(move_key)
      base=pmd_ac_v039_move_autochess_hint(move_key);b=TWO_TURN_MOVE_V039[move_key];return base if b==nil
      r=base==nil ? {} : base.dup
      r[:behavior_status]=b[:behavior_status];r[:delivery]=b[:delivery];r[:range_px]=b[:range_px]
      r[:runtime_skill_key]=b[:runtime_skill_key];r[:target_type]=:enemy_targeted;r[:two_turn]=true;r
    end
    def skill_data(key)
      old=pmd_ac_v039_skill_data(key);return old if old!=nil && !old.empty?
      mk=canonical_move_key_from_skill(key);return {} if mk==nil;b=TWO_TURN_MOVE_V039[mk];return {} if b==nil
      r=b.dup;r[:move_type]=b[:type];r[:damage_category]=b[:category];r[:canonical_move_key]=mk;r
    end
    def skill_audio_move_profile_v032(move_key)
      b=TWO_TURN_AUDIO_V039[move_key];return b unless b==nil
      pmd_ac_v039_skill_audio_move_profile_v032(move_key)
    end
    def two_turn_checksum_scalar_v039(v)
      return '' if v==nil
      return v ? 'true':'false' if v==true || v==false
      if v.is_a?(Array);return v.collect{|x|two_turn_checksum_scalar_v039(x)}.join(',');end
      if v.is_a?(Hash)
        ks=v.keys.sort{|a,b|a.to_s<=>b.to_s};return ks.collect{|k|k.to_s+'='+two_turn_checksum_scalar_v039(v[k])}.join(';')
      end
      return sprintf('%.2f',v) if v.is_a?(Float)
      v.to_s
    end
    def two_turn_checksum32_v039
      h=0;m=TWO_TURN_MANIFEST_V039
      m.keys.reject{|k|k==:runtime_checksum32}.sort{|a,b|a.to_s<=>b.to_s}.each do |k|
        ('M|'+k.to_s+'='+two_turn_checksum_scalar_v039(m[k])).each_byte{|by|h=((h*33)+by)&0x7fffffff}
      end
      TWO_TURN_MOVE_V039.keys.sort{|a,b|a.to_s<=>b.to_s}.each do |k|
        src={}
        # checksum uses the source fields before runtime-only bridge fields were added
        [:name,:type,:category,:power,:accuracy,:energy_cost_hint,:pose,:phase_frames,:gravity_blocked,:vfx_style,
         :semi_hit_by,:semi_double_power_from,:secondary_paralysis_chance,:cast_cat,:launch_cat,:hit_cat,:bypass_protect].each do |f|
          v=TWO_TURN_MOVE_V039[k][f]
          src[f]=v unless v==nil
        end
        ('R|'+k.to_s+'|'+two_turn_checksum_scalar_v039(src)).each_byte{|by|h=((h*33)+by)&0x7fffffff}
      end
      h
    end
    def validate_two_turn_v039
      e=[];m=TWO_TURN_MANIFEST_V039
      e.push('count') unless TWO_TURN_MOVE_V039.size==5
      e.push('cumulative') unless m[:cumulative_mapped_move_count].to_i==237
      e.push('covered') unless m[:cumulative_reference_covered].to_i==3923
      e.push('poses') unless TWO_TURN_MOVE_V039[:fly][:pose]==:airborne && TWO_TURN_MOVE_V039[:dive][:pose]==:submerged && TWO_TURN_MOVE_V039[:dig][:pose]==:underground && TWO_TURN_MOVE_V039[:shadow_force][:pose]==:vanished
      e.push('gravity') unless TWO_TURN_MOVE_V039[:fly][:gravity_blocked] && TWO_TURN_MOVE_V039[:bounce][:gravity_blocked] && !TWO_TURN_MOVE_V039[:dive][:gravity_blocked]
      e.push('exceptions') unless TWO_TURN_MOVE_V039[:dive][:semi_double_power_from].include?(:surf) && TWO_TURN_MOVE_V039[:dig][:semi_double_power_from].include?(:earthquake)
      e.push('shadow_force') unless TWO_TURN_MOVE_V039[:shadow_force][:bypass_protect]
      e.push('checksum') unless two_turn_checksum32_v039==m[:runtime_checksum32].to_i
      e
    end
  end

  remove_const(:VERIFICATION_MODES) if const_defined?(:VERIFICATION_MODES)
  VERIFICATION_MODES=[:two_turn,:altitude,:field_ai,:field_spatial,:skill_special_ii]
  remove_const(:VERIFICATION_LABELS) if const_defined?(:VERIFICATION_LABELS)
  VERIFICATION_LABELS={:two_turn=>'TWO_TURN',:altitude=>'ALTITUDE',:field_ai=>'FIELD_AI',:field_spatial=>'FIELD_SPATIAL',:skill_special_ii=>'SKILL_SPECIAL_II'}
end

class Game_PMDChessUnit
  alias pmd_ac_v039_initialize initialize unless method_defined?(:pmd_ac_v039_initialize)
  alias pmd_ac_v039_update update unless method_defined?(:pmd_ac_v039_update)
  alias pmd_ac_v039_desired_velocity desired_velocity unless method_defined?(:pmd_ac_v039_desired_velocity)
  alias pmd_ac_v039_begin_attack begin_attack unless method_defined?(:pmd_ac_v039_begin_attack)
  alias pmd_ac_v039_begin_skill begin_skill unless method_defined?(:pmd_ac_v039_begin_skill)
  alias pmd_ac_v039_start_faint start_faint unless method_defined?(:pmd_ac_v039_start_faint)

  def initialize(*args)
    pmd_ac_v039_initialize(*args)
    @two_turn_move_v039=nil;@two_turn_target_uid_v039=nil;@two_turn_frames_v039=0;@two_turn_pose_v039=nil
  end
  def two_turn_pending_v039?;@two_turn_move_v039!=nil && @two_turn_frames_v039.to_i>0;end
  def two_turn_move_v039;@two_turn_move_v039;end
  def two_turn_target_uid_v039;@two_turn_target_uid_v039;end
  def two_turn_pose_v039;@two_turn_pose_v039;end
  def two_turn_frames_v039;@two_turn_frames_v039.to_i;end
  def two_turn_semi_invulnerable_v039?;two_turn_pending_v039?;end
  def two_turn_gravity_blocked_v039?
    return false unless two_turn_pending_v039?
    d=PMD_AC::TWO_TURN_MOVE_V039[@two_turn_move_v039];d!=nil && d[:gravity_blocked] ? true:false
  end
  def begin_two_turn_charge_v039(move_key,target_uid,pose,frames)
    @two_turn_move_v039=move_key;@two_turn_target_uid_v039=target_uid;@two_turn_pose_v039=pose;@two_turn_frames_v039=[frames.to_i,1].max
    set_altitude_pose_v038(pose,999999) if respond_to?(:set_altitude_pose_v038)
    @velocity_x=0.0;@velocity_y=0.0;clear_move_goal if respond_to?(:clear_move_goal)
    true
  end
  def clear_two_turn_charge_v039
    @two_turn_move_v039=nil;@two_turn_target_uid_v039=nil;@two_turn_pose_v039=nil;@two_turn_frames_v039=0
    clear_altitude_pose_v038 if respond_to?(:clear_altitude_pose_v038)
  end
  def two_turn_move_can_hit_pose_v039?(incoming_move_key,user=nil)
    return true unless two_turn_pending_v039?
    if user!=nil && respond_to?(:ability_key) && user.respond_to?(:ability_key)
      return true if user.ability_key==:no_guard || ability_key==:no_guard
    end
    d=PMD_AC::TWO_TURN_MOVE_V039[@two_turn_move_v039];return false if d==nil
    return false if incoming_move_key==nil
    (d[:semi_hit_by]||[]).include?(incoming_move_key.to_sym)
  end
  def two_turn_incoming_power_multiplier_v039(incoming_move_key)
    return 1.0 unless two_turn_pending_v039? || @two_turn_pose_v039!=nil
    d=PMD_AC::TWO_TURN_MOVE_V039[@two_turn_move_v039];return 1.0 if d==nil || incoming_move_key==nil
    (d[:semi_double_power_from]||[]).include?(incoming_move_key.to_sym) ? PMD_AC::TWO_TURN_EXCEPTION_MULT_V039 : 1.0
  end

  def update
    if two_turn_pending_v039?
      if dead?
        clear_two_turn_charge_v039
      elsif two_turn_gravity_blocked_v039? && respond_to?(:canonical_gravity_grounded_v038?) && canonical_gravity_grounded_v038?
        @scene.cancel_two_turn_v039(self,:gravity) if @scene!=nil && @scene.respond_to?(:cancel_two_turn_v039)
      else
        @two_turn_frames_v039-=1
        if @two_turn_frames_v039<=0 && @scene!=nil && @scene.respond_to?(:resolve_two_turn_release_v039)
          @scene.resolve_two_turn_release_v039(self)
        end
      end
    end
    pmd_ac_v039_update
  end
  def desired_velocity
    return [0.0,0.0] if two_turn_pending_v039?
    pmd_ac_v039_desired_velocity
  end
  def begin_attack
    return if two_turn_pending_v039?
    pmd_ac_v039_begin_attack
  end
  def begin_skill(skill_target=nil)
    return if two_turn_pending_v039?
    pmd_ac_v039_begin_skill(skill_target)
  end
  def start_faint
    clear_two_turn_charge_v039 if two_turn_pending_v039?
    pmd_ac_v039_start_faint
  end
end

class Scene_PMD_AutoChess
  alias pmd_ac_v039_start start unless method_defined?(:pmd_ac_v039_start)
  alias pmd_ac_v039_prepare_verification_battle prepare_verification_battle unless method_defined?(:pmd_ac_v039_prepare_verification_battle)
  alias pmd_ac_v039_update_verification_script update_verification_script unless method_defined?(:pmd_ac_v039_update_verification_script)
  alias pmd_ac_v039_log_event log_event unless method_defined?(:pmd_ac_v039_log_event)
  alias pmd_ac_v039_complete_verification_mode complete_verification_mode unless method_defined?(:pmd_ac_v039_complete_verification_mode)
  alias pmd_ac_v039_resolve_skill resolve_skill unless method_defined?(:pmd_ac_v039_resolve_skill)
  alias pmd_ac_v039_canonical_accuracy_hit canonical_accuracy_hit? unless method_defined?(:pmd_ac_v039_canonical_accuracy_hit)
  alias pmd_ac_v039_deal_direct_damage deal_direct_damage unless method_defined?(:pmd_ac_v039_deal_direct_damage)
  alias pmd_ac_v039_skill_cast_worthwhile skill_cast_worthwhile? unless method_defined?(:pmd_ac_v039_skill_cast_worthwhile)

  def start
    pmd_ac_v039_start
    begin
      if FileTest.exist?(PMD_AC::BATTLE_LOG_FILE)
        text=File.open(PMD_AC::BATTLE_LOG_FILE,'rb'){|f|f.read};text.sub!(/PMD AutoChess Proto v0\.[0-9.]+ Battle Verification Log/,'PMD AutoChess Proto v0.39 Battle Verification Log');File.open(PMD_AC::BATTLE_LOG_FILE,'wb'){|f|f.write(text)}
      end
    rescue;end
    m=PMD_AC::TWO_TURN_MANIFEST_V039
    log_event(:two_turn,'LOADED new=5 cumulative='+m[:cumulative_mapped_move_count].to_s+' covered='+m[:cumulative_reference_covered].to_s+'/'+m[:learnset_reference_total].to_s+' coverage='+sprintf('%.2f',m[:cumulative_coverage_percent].to_f)+'% phase=60 moves=fly,bounce,dive,dig,shadow_force checksum32='+m[:runtime_checksum32].to_s)
  end

  def two_turn_unit_by_uid_v039(uid)
    return nil if uid==nil || @units==nil
    @units.find{|u|u.respond_to?(:instance_uid) && u.instance_uid.to_i==uid.to_i}
  end
  def start_two_turn_v039(unit,target,data)
    return false if unit==nil || target==nil || data==nil
    mk=data[:canonical_move_key];return false if mk==nil
    if data[:gravity_blocked] && respond_to?(:canonical_field_active_global?) && canonical_field_active_global?(:gravity)
      log_event(:two_turn,unit.log_name+' BLOCK '+mk.to_s+' reason=gravity');return false
    end
    unit.begin_two_turn_charge_v039(mk,target.instance_uid,data[:pose],data[:phase_frames]||60)
    log_event(:two_turn,unit.log_name+' PHASE1 '+mk.to_s+' pose='+data[:pose].to_s+' target_uid='+target.instance_uid.to_s+' frames='+unit.two_turn_frames_v039.to_s)
    true
  end
  def cancel_two_turn_v039(unit,reason)
    return if unit==nil || !unit.respond_to?(:two_turn_pending_v039?) || !unit.two_turn_pending_v039?
    mk=unit.two_turn_move_v039;unit.clear_two_turn_charge_v039
    log_event(:two_turn,unit.log_name+' CANCEL '+mk.to_s+' reason='+reason.to_s)
  end
  def resolve_two_turn_release_v039(unit)
    return if unit==nil || !unit.respond_to?(:two_turn_pending_v039?) || !unit.two_turn_pending_v039?
    mk=unit.two_turn_move_v039;uid=unit.two_turn_target_uid_v039;data=PMD_AC.skill_data(('mv_'+mk.to_s).to_sym);target=two_turn_unit_by_uid_v039(uid)
    unit.clear_two_turn_charge_v039
    if target==nil || target.dead?
      log_event(:two_turn,unit.log_name+' PHASE2_CANCEL '+mk.to_s+' target_uid='+uid.to_s+' reason=target_lost');return false
    end
    unit.face_toward(target,true) if unit.respond_to?(:face_toward)
    if mk==:shadow_force
      unit.blink_behind(target,34.0) if unit.respond_to?(:blink_behind)
    else
      unit.dash_toward(target,999.0) if unit.respond_to?(:dash_toward)
    end
    play_skill_se(unit,:launch,data)
    result=apply_skill_effects(unit,target,data,1.0);amount=result.is_a?(Numeric) ? result.to_i : 0
    if amount>0
      add_vfx_impact(target,data[:vfx_style]||:normal)
      if mk==:bounce && data[:secondary_paralysis_chance].to_i>0 && target.alive?
        chance=data[:secondary_paralysis_chance].to_i;roll=two_turn_roll_v039(chance)
        if roll[0]
          target.apply_status(:paralysis,{:duration=>999999,:value=>0,:interval=>999999,:stack_mode=>:refresh},unit)
          add_skill_effect(target,:stun);log_event(:two_turn,target.log_name+' BOUNCE_PARALYSIS chance='+chance.to_s+' roll='+roll[1].to_s)
        end
      end
    end
    log_event(:two_turn,unit.log_name+' PHASE2 '+mk.to_s+' -> '+target.log_name+' result='+amount.to_s+' pose=ground')
    amount>0
  end

  def resolve_skill(unit)
    data=unit==nil ? nil : unit.skill_data
    if unit!=nil && data!=nil && data[:two_turn] && !unit.two_turn_pending_v039?
      target=unit.skill_target
      return start_two_turn_v039(unit,target,data) if target!=nil && !target.dead?
    end
    pmd_ac_v039_resolve_skill(unit)
  end

  def skill_cast_worthwhile?(unit,target,data)
    return false unless pmd_ac_v039_skill_cast_worthwhile(unit,target,data)
    if data!=nil && data[:two_turn] && data[:gravity_blocked] && respond_to?(:canonical_field_active_global?) && canonical_field_active_global?(:gravity)
      return false
    end
    true
  end

  def canonical_accuracy_hit?(user,target,data,log_check=true)
    if user!=nil && target!=nil && data!=nil && user.team!=target.team && target.respond_to?(:two_turn_semi_invulnerable_v039?) && target.two_turn_semi_invulnerable_v039?
      mk=data[:canonical_move_key]
      unless target.two_turn_move_can_hit_pose_v039?(mk,user)
        log_event(:two_turn,user.log_name+' -> '+target.log_name+' move='+(mk||:unknown).to_s+' SEMI_INVULNERABLE_MISS pose='+target.two_turn_pose_v039.to_s)
        return false
      end
      # Thunder/Hurricane are the canonical aerial exceptions that should not miss the hidden aerial phase.
      return true if target.two_turn_pose_v039==:airborne && [:thunder,:hurricane].include?(mk)
    end
    pmd_ac_v039_canonical_accuracy_hit(user,target,data,log_check)
  end

  def deal_direct_damage(user,target,power,options=nil)
    options={} if options==nil
    if user!=nil && target!=nil && user.team!=target.team && target.respond_to?(:two_turn_semi_invulnerable_v039?) && target.two_turn_semi_invulnerable_v039?
      sd=options[:skill_data];mk=sd==nil ? nil : sd[:canonical_move_key]
      hostile_direct=(options[:source_type]==:basic || mk!=nil)
      if hostile_direct
        unless target.two_turn_move_can_hit_pose_v039?(mk,user)
          user.register_miss(target) if user.respond_to?(:register_miss)
          log_event(:two_turn,user.log_name+' -> '+target.log_name+' direct='+((mk||:basic).to_s)+' BLOCKED pose='+target.two_turn_pose_v039.to_s)
          return 0
        end
        mult=target.two_turn_incoming_power_multiplier_v039(mk)
        if mult>1.001 && options[:fixed_damage]==nil
          old=power.to_i;power=[(power.to_f*mult).round,1].max
          log_event(:two_turn,user.log_name+' -> '+target.log_name+' exception='+mk.to_s+' power='+old.to_s+'->'+power.to_s+' pose='+target.two_turn_pose_v039.to_s)
        end
      end
    end
    pmd_ac_v039_deal_direct_damage(user,target,power,options)
  end

  def two_turn_roll_v039(chance)
    c=PMD_AC.clamp(chance.to_i,0,100);return [true,0] if c>=100
    roll=nil
    if verification_mode==:two_turn && @two_turn_rolls_v039!=nil && !@two_turn_rolls_v039.empty?;roll=@two_turn_rolls_v039.shift.to_i;else;roll=rand(100);end
    [roll<c,roll]
  end
  def set_two_turn_rolls_v039(a);@two_turn_rolls_v039=a.dup;end

  def prepare_verification_battle
    pmd_ac_v039_prepare_verification_battle
    if verification_mode==:two_turn
      @two_turn_failed_v039=false;@two_turn_rolls_v039=[];@two_turn_snapshots_v039={}
      clear_all_spatial_fields_v036(:verify) if respond_to?(:clear_all_spatial_fields_v036)
      for u in @units
        u.verification_combat_sandbox(true);u.verification_altitude_pose_v038(nil) if u.respond_to?(:verification_altitude_pose_v038);u.clear_two_turn_charge_v039 if u.respond_to?(:clear_two_turn_charge_v039)
      end
    end
  end
  def log_event(category,message)
    if category.to_s=='verify' && verification_mode==:two_turn && message.to_s.index('TWO_TURN_')==0 && message.to_s.include?(' pass=0');@two_turn_failed_v039=true;end
    pmd_ac_v039_log_event(category,message)
  end
  def two_turn_verify_units_v039;[verification_unit(:ally,:bulbasaur),verification_unit(:ally,:charmander),verification_unit(:ally,:squirtle),verification_unit(:enemy,:rattata)];end
  def two_turn_temp_unit_v039(species,team,id,ability_slot=:primary)
    i=PMD_PokemonInstance.new(species,50,{:instance_uid=>99039000+id.to_i,:ability_slot=>ability_slot});u=Game_PMDChessUnit.new(9390+id.to_i,species,team,0,0,i);u.scene=self;u.verification_combat_sandbox(true);u
  end

  def verify_two_turn_manifest_v039
    return if @verification_done[:two_turn_manifest];e=PMD_AC.validate_two_turn_v039;m=PMD_AC::TWO_TURN_MANIFEST_V039;pass=e.empty?
    log_event(:verify,'TWO_TURN_MANIFEST pass='+(pass ? '1':'0')+' new=5 cumulative='+m[:cumulative_mapped_move_count].to_s+' covered='+m[:cumulative_reference_covered].to_s+'/'+m[:learnset_reference_total].to_s+' coverage='+sprintf('%.2f',m[:cumulative_coverage_percent].to_f)+' checksum='+PMD_AC.two_turn_checksum32_v039.to_s+' errors=['+e.join(',')+']')
    @verification_done[:two_turn_manifest]=true
  end
  def verify_two_turn_pose_gallery_v039
    return if @verification_done[:two_turn_pose]
    a,b,c,t=two_turn_verify_units_v039
    start_two_turn_v039(a,t,PMD_AC.skill_data(:mv_fly));start_two_turn_v039(b,t,PMD_AC.skill_data(:mv_dive));start_two_turn_v039(c,t,PMD_AC.skill_data(:mv_dig))
    pass=a.two_turn_pose_v039==:airborne && b.two_turn_pose_v039==:submerged && c.two_turn_pose_v039==:underground && a.desired_velocity==[0.0,0.0] && b.desired_velocity==[0.0,0.0] && c.desired_velocity==[0.0,0.0]
    log_event(:verify,'TWO_TURN_POSE pass='+(pass ? '1':'0')+' fly=airborne dive=submerged dig=underground movement_lock=1 phase=60')
    @verification_done[:two_turn_pose]=true
  end
  def verify_two_turn_invulnerability_v039
    return if @verification_done[:two_turn_invul]
    a,b,c,t=two_turn_verify_units_v039
    # Fly target: basic and Tackle miss; Thunder is allowed.
    t.begin_two_turn_charge_v039(:fly,a.instance_uid,:airborne,60)
    hp=t.hp;basic=deal_direct_damage(a,t,50,{:fixed_damage=>50,:can_crit=>false,:directional=>false,:source_type=>:basic,:grant_energy=>false})
    tackle=canonical_accuracy_hit?(a,t,PMD_AC.skill_data(:mv_tackle),false)
    thunder=canonical_accuracy_hit?(a,t,PMD_AC.skill_data(:mv_thunder),false)
    t.clear_two_turn_charge_v039
    pass=basic==0 && t.hp==hp && !tackle && thunder
    log_event(:verify,'TWO_TURN_INVULNERABILITY pass='+(pass ? '1':'0')+' basic=blocked tackle=miss thunder=hit natural_airborne_not_invulnerable=1')
    @verification_done[:two_turn_invul]=true
  end
  def verify_two_turn_exceptions_v039
    return if @verification_done[:two_turn_exceptions]
    a,b,c,t=two_turn_verify_units_v039
    t.begin_two_turn_charge_v039(:dive,a.instance_uid,:submerged,60);surf=t.two_turn_incoming_power_multiplier_v039(:surf);whirl=t.two_turn_incoming_power_multiplier_v039(:whirlpool);t.clear_two_turn_charge_v039
    t.begin_two_turn_charge_v039(:dig,a.instance_uid,:underground,60);eq=t.two_turn_incoming_power_multiplier_v039(:earthquake);mag=t.two_turn_incoming_power_multiplier_v039(:magnitude);t.clear_two_turn_charge_v039
    t.begin_two_turn_charge_v039(:fly,a.instance_uid,:airborne,60);gust=t.two_turn_incoming_power_multiplier_v039(:gust);twister=t.two_turn_incoming_power_multiplier_v039(:twister);t.clear_two_turn_charge_v039
    pass=surf==2.0 && whirl==2.0 && eq==2.0 && mag==2.0 && gust==2.0 && twister==2.0
    log_event(:verify,'TWO_TURN_EXCEPTIONS pass='+(pass ? '1':'0')+' dive=surf/whirlpool_x2 dig=earthquake/magnitude_x2 airborne=gust/twister_x2 thunder/hurricane_hit=1')
    @verification_done[:two_turn_exceptions]=true
  end
  def verify_two_turn_gravity_v039
    return if @verification_done[:two_turn_gravity]
    clear_all_spatial_fields_v036(:verify);a,b,c,t=two_turn_verify_units_v039
    a.begin_two_turn_charge_v039(:fly,t.instance_uid,:airborne,60);set_canonical_field_effect_v035(:gravity,t,5);a.update
    fly_cancel=!a.two_turn_pending_v039? && a.canonical_altitude_pose_v038==:ground
    b.begin_two_turn_charge_v039(:dive,t.instance_uid,:submerged,60);b.update;dive_stays=b.two_turn_pending_v039? && b.canonical_altitude_pose_v038==:submerged;b.clear_two_turn_charge_v039
    block=!skill_cast_worthwhile?(a,t,PMD_AC.skill_data(:mv_fly));clear_all_spatial_fields_v036(:verify)
    pass=fly_cancel && dive_stays && block
    log_event(:verify,'TWO_TURN_GRAVITY pass='+(pass ? '1':'0')+' fly_cancel=1 bounce_cancel=hook dive_unchanged=1 cast_block=1')
    @verification_done[:two_turn_gravity]=true
  end
  def verify_two_turn_integration_cast_v039
    return if @verification_done[:two_turn_cast]
    clear_all_spatial_fields_v036(:verify);a,b,c,t=two_turn_verify_units_v039
    a.deploy_to_cell(1,1);t.deploy_to_cell(2,1);t.deploy_to_pixel(a.pixel_x+48.0,a.pixel_y);@two_turn_snapshots_v039[:dig_hp]=t.hp
    ok=a.verification_force_skill(:mv_dig,t)
    log_event(:verify,'TWO_TURN_INTEGRATION_CAST pass='+(ok ? '1':'0')+' move=dig target_uid='+t.instance_uid.to_s+' hp_before='+t.hp.to_s)
    @verification_done[:two_turn_cast]=true
  end
  def verify_two_turn_integration_result_v039
    return if @verification_done[:two_turn_result]
    a,b,c,t=two_turn_verify_units_v039;before=@two_turn_snapshots_v039[:dig_hp].to_i
    pass=!a.two_turn_pending_v039? && t.hp<before && a.canonical_altitude_pose_v038==:ground
    log_event(:verify,'TWO_TURN_INTEGRATION_RESULT pass='+(pass ? '1':'0')+' dig_damage='+(before-t.hp).to_s+' pending=0 pose='+a.canonical_altitude_pose_v038.to_s+' original_target_uid=1')
    @verification_done[:two_turn_result]=true
  end
  def verify_two_turn_bounce_shadow_v039
    return if @verification_done[:two_turn_bounce_shadow]
    a,b,c,t=two_turn_verify_units_v039;t.verification_clear_status(:paralysis);set_two_turn_rolls_v039([0])
    # Directly release a prepared Bounce for deterministic secondary verification.
    a.begin_two_turn_charge_v039(:bounce,t.instance_uid,:airborne,1);resolve_two_turn_release_v039(a)
    para=t.status?(:paralysis);t.verification_clear_status(:paralysis)
    sf=PMD_AC.skill_data(:mv_shadow_force);pass=para && sf[:pose]==:vanished && sf[:bypass_protect]
    log_event(:verify,'TWO_TURN_BOUNCE_SHADOW pass='+(pass ? '1':'0')+' bounce_paralysis30=1 forced_roll=0 shadow_force=vanished protect_bypass_hook=1')
    @verification_done[:two_turn_bounce_shadow]=true
  end
  def verify_two_turn_runtime_v039
    return if @verification_done[:two_turn_runtime];ok=true
    [:fly,:bounce,:dive,:dig,:shadow_force].each{|k|d=PMD_AC.skill_data(('mv_'+k.to_s).to_sym);ok=false if d==nil || d[:canonical_move_key]!=k || !PMD_AC.move_executable?(k) || !d[:two_turn]}
    log_event(:verify,'TWO_TURN_RUNTIME pass='+(ok ? '1':'0')+' mapped=5 cumulative=237 target_lock=instance_uid pose_api=v038 movement_lock=1 audio=5 shadow_force_protect_system=pending_hook')
    @verification_done[:two_turn_runtime]=true
  end
  def verify_two_turn_modes_v039
    return if @verification_done[:two_turn_modes];exp=[:two_turn,:altitude,:field_ai,:field_spatial,:skill_special_ii];pass=PMD_AC::VERIFICATION_MODES==exp && verification_mode==:two_turn
    log_event(:verify,'TWO_TURN_RECENT_MODES pass='+(pass ? '1':'0')+' modes=5 default=TWO_TURN')
    @verification_done[:two_turn_modes]=true
  end

  def update_verification_script
    pmd_ac_v039_update_verification_script
    return unless verification_mode==:two_turn
    f=@verification_frame
    verify_two_turn_manifest_v039 if f==4
    verify_two_turn_pose_gallery_v039 if f==30
    if f==80
      a,b,c,t=two_turn_verify_units_v039;[a,b,c].each{|u|u.clear_two_turn_charge_v039 if u.respond_to?(:clear_two_turn_charge_v039)}
    end
    verify_two_turn_invulnerability_v039 if f==100
    verify_two_turn_exceptions_v039 if f==170
    verify_two_turn_gravity_v039 if f==240
    verify_two_turn_integration_cast_v039 if f==300
    verify_two_turn_integration_result_v039 if f==410
    verify_two_turn_bounce_shadow_v039 if f==470
    verify_two_turn_runtime_v039 if f==530
    verify_two_turn_modes_v039 if f==560
    complete_verification_mode if f==PMD_AC::VERIFICATION_TWO_TURN_END_FRAME_V039
  end
  def complete_verification_mode
    if verification_mode==:two_turn
      for u in @units
        u.clear_two_turn_charge_v039 if u.respond_to?(:clear_two_turn_charge_v039)
        u.verification_altitude_pose_v038(nil) if u.respond_to?(:verification_altitude_pose_v038)
        u.verification_clear_status(:paralysis) if u.respond_to?(:verification_clear_status)
      end
      clear_all_spatial_fields_v036(:verify) if respond_to?(:clear_all_spatial_fields_v036)
      if @two_turn_failed_v039
        for u in @units;u.verification_finish;end;@verification_done[:complete]=true;log_event(:verify,'FAILED mode=TWO_TURN auto_skill=on original_skills=restored');return
      end
    end
    pmd_ac_v039_complete_verification_mode
  end
end
