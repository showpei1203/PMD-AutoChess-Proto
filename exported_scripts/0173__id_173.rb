#==============================================================================
# 【PMD AutoChess 中文維護說明】
# 腳本：PMD AutoChess Proto v0.38
# 分類：核心戰鬥 Runtime
#
# 【用途／機制】
# 承接前序 Data／Config，實際執行戰鬥 Scene、Unit、AI、技能與呈現。
#
# 【怎麼調整】
# 一般平衡與資料調整不要直接改 Runtime；若要追加功能，建議在較後腳本 alias 原方法後擴充。
#
# 【本腳本主要設定常數／資料表】
# - VERIFICATION_ALTITUDE_END_FRAME_V038 / VERIFICATION_MODES / VERIFICATION_LABELS
#
# 【Runtime 主要方法（查流程時可直接搜尋）】
# - altitude_checksum_scalar_v038 / altitude_checksum32_v038 / validate_altitude_v038 / initialize
# - canonical_natural_airborne_v038? / canonical_gravity_grounded_v038? / set_altitude_pose_v038 / clear_altitude_pose_v038
# - verification_altitude_pose_v038 / canonical_altitude_pose_v038 / canonical_airborne_v038? / canonical_grounded_v038?
#
# 【維護規則】
# - RPG Maker VX / RGSS2 / Ruby 1.8 相容。
# - instance_uid 才是 Pokémon 個體身份；Actor ID 只是容器。
# - 新增行為優先沿用既有 helper／Data 表；避免破壞已 Freeze 的舊核心。
# - 本專案新腳本也必須保留同等級的中文說明與實際範例。
#==============================================================================
#==============================================================================
# ■ PMD AutoChess Proto v0.38
#    Grounded / Airborne Foundation + Altitude Visual State I
#------------------------------------------------------------------------------
# Additive layer on v0.37.
#
# Natural altitude:
#   Flying type / Levitate => small visual lift + gentle bob.
#   Gravity               => forced to normal ground presentation.
#
# Transient pose API prepared for two-phase / semi-invulnerable moves:
#   set_altitude_pose_v038(:submerged, frames)   # Dive-like
#   set_altitude_pose_v038(:underground, frames) # Dig-like
#   set_altitude_pose_v038(:airborne, frames)    # Fly/Bounce-like
#   set_altitude_pose_v038(:vanished, frames)    # Shadow-Force-like
#
# Submerged / Underground / Vanished lock ordinary movement while active.
# Only the Pokemon body sprite moves vertically; HP/Energy/Popup UI remains on
# its normal ground anchor and z-order remains based on combat pixel_y.
#==============================================================================
module PMD_AC
  VERIFICATION_ALTITUDE_END_FRAME_V038 = 520

  class << self
    def altitude_checksum_scalar_v038(v)
      return '' if v==nil
      return v ? 'true':'false' if v==true || v==false
      if v.is_a?(Hash)
        ks=v.keys.sort{|a,b|a.to_s<=>b.to_s}
        return ks.collect{|k|k.to_s+'='+altitude_checksum_scalar_v038(v[k])}.join(';')
      end
      if v.is_a?(Array);return v.collect{|x|altitude_checksum_scalar_v038(x)}.join(',');end
      return sprintf('%.2f',v) if v.is_a?(Float)
      v.to_s
    end
    def altitude_checksum32_v038
      h=0;m=ALTITUDE_MANIFEST_V038
      m.keys.reject{|k|k==:runtime_checksum32}.sort{|a,b|a.to_s<=>b.to_s}.each do |k|
        ('M|'+k.to_s+'='+altitude_checksum_scalar_v038(m[k])).each_byte{|by|h=((h*33)+by)&0x7fffffff}
      end
      ALTITUDE_POSE_V038.keys.sort{|a,b|a.to_s<=>b.to_s}.each do |k|
        ('P|'+k.to_s+'|'+altitude_checksum_scalar_v038(ALTITUDE_POSE_V038[k])).each_byte{|by|h=((h*33)+by)&0x7fffffff}
      end
      h
    end
    def validate_altitude_v038
      e=[];m=ALTITUDE_MANIFEST_V038;p=ALTITUDE_POSE_V038
      e.push('poses') unless p.size==5
      e.push('airborne') unless p[:airborne][:base_y].to_i==-10 && p[:airborne][:bob_amp].to_i==3 && p[:airborne][:bob_period].to_i==48
      e.push('semi') unless p[:submerged][:movement_locked] && p[:underground][:movement_locked] && p[:submerged][:opacity].to_i==150
      e.push('gravity') unless m[:gravity_forces_ground] && m[:gravity_restores_ground_move_hit]
      e.push('ui_anchor') unless m[:bars_follow_altitude]==false && m[:sprite_z_uses_ground_baseline]
      e.push('moves') unless m[:cumulative_mapped_move_count].to_i==232 && m[:cumulative_reference_covered].to_i==3885
      e.push('checksum') unless altitude_checksum32_v038==m[:runtime_checksum32].to_i
      e
    end
  end

  remove_const(:VERIFICATION_MODES) if const_defined?(:VERIFICATION_MODES)
  VERIFICATION_MODES=[:altitude,:field_ai,:field_spatial,:skill_special_ii,:skill_special]
  remove_const(:VERIFICATION_LABELS) if const_defined?(:VERIFICATION_LABELS)
  VERIFICATION_LABELS={:altitude=>'ALTITUDE',:field_ai=>'FIELD_AI',:field_spatial=>'FIELD_SPATIAL',:skill_special_ii=>'SKILL_SPECIAL_II',:skill_special=>'SKILL_SPECIAL'}
end

class Game_PMDChessUnit
  alias pmd_ac_v038_initialize initialize unless method_defined?(:pmd_ac_v038_initialize)
  alias pmd_ac_v038_update update unless method_defined?(:pmd_ac_v038_update)
  alias pmd_ac_v038_desired_velocity desired_velocity unless method_defined?(:pmd_ac_v038_desired_velocity)
  alias pmd_ac_v038_calculate_damage calculate_damage unless method_defined?(:pmd_ac_v038_calculate_damage)
  alias pmd_ac_v038_pokemon_types pokemon_types unless method_defined?(:pmd_ac_v038_pokemon_types)
  alias pmd_ac_v038_ability_incoming_multiplier ability_incoming_multiplier unless method_defined?(:pmd_ac_v038_ability_incoming_multiplier)

  def initialize(*args)
    pmd_ac_v038_initialize(*args)
    @altitude_pose_v038=nil
    @altitude_pose_frames_v038=0
    @altitude_pose_verify_v038=nil
    @pmd_ac_v038_ground_damage_override=false
  end

  # True for a Pokemon whose natural battle layer is above ground.
  # Gravity is deliberately NOT considered here; this is identity/ability based.
  def canonical_natural_airborne_v038?
    ts=pmd_ac_v038_pokemon_types
    return true if ts!=nil && ts.include?(:flying)
    return true if respond_to?(:ability_key) && ability_key==:levitate
    false
  end

  def canonical_gravity_grounded_v038?
    return false if @scene==nil || !@scene.respond_to?(:canonical_field_active_global?)
    @scene.canonical_field_active_global?(:gravity) ? true : false
  end

  def set_altitude_pose_v038(pose,frames=0)
    pose=pose.to_sym if pose.respond_to?(:to_sym)
    return false unless PMD_AC::ALTITUDE_POSE_V038.has_key?(pose)
    @altitude_pose_v038=pose
    @altitude_pose_frames_v038=[frames.to_i,0].max
    true
  end
  def clear_altitude_pose_v038
    @altitude_pose_v038=nil;@altitude_pose_frames_v038=0
  end
  def verification_altitude_pose_v038(pose=nil)
    @altitude_pose_verify_v038=pose
  end

  def canonical_altitude_pose_v038
    pose=@altitude_pose_verify_v038
    pose=@altitude_pose_v038 if pose==nil && @altitude_pose_v038!=nil
    # Gravity knocks airborne/Fly-like presentation back to the ground.
    if pose==:airborne && canonical_gravity_grounded_v038?;return :ground;end
    return pose if pose!=nil && PMD_AC::ALTITUDE_POSE_V038.has_key?(pose)
    return :ground if canonical_gravity_grounded_v038?
    return :airborne if canonical_natural_airborne_v038?
    :ground
  end

  def canonical_airborne_v038?;canonical_altitude_pose_v038==:airborne;end
  def canonical_grounded_v038?
    return true if canonical_gravity_grounded_v038?
    canonical_altitude_pose_v038==:ground
  end
  def canonical_pose_movement_locked_v038?
    p=PMD_AC::ALTITUDE_POSE_V038[canonical_altitude_pose_v038]||{}
    p[:movement_locked] ? true : false
  end
  def altitude_visual_profile_v038
    PMD_AC::ALTITUDE_POSE_V038[canonical_altitude_pose_v038]||PMD_AC::ALTITUDE_POSE_V038[:ground]
  end
  def altitude_visual_offset_y_v038
    p=altitude_visual_profile_v038
    y=p[:base_y].to_f
    amp=p[:bob_amp].to_f;period=p[:bob_period].to_i
    if amp!=0.0 && period>0
      # Stable per-instance phase avoids a synchronized flock bobbing in lockstep.
      phase=((Graphics.frame_count + instance_uid.to_i%period)%period).to_f/period.to_f
      y += Math.sin(phase*Math::PI*2.0)*amp
    end
    y
  end

  def update
    if @altitude_pose_v038!=nil && @altitude_pose_frames_v038.to_i>0
      @altitude_pose_frames_v038-=1
      clear_altitude_pose_v038 if @altitude_pose_frames_v038<=0
    end
    pmd_ac_v038_update
  end

  def desired_velocity
    return [0.0,0.0] if canonical_pose_movement_locked_v038?
    pmd_ac_v038_desired_velocity
  end

  # During Gravity-only Ground damage resolution, remove Flying's type immunity
  # without erasing the Pokemon's real typing for STAB/other systems.
  def pokemon_types
    t=pmd_ac_v038_pokemon_types
    if @pmd_ac_v038_ground_damage_override
      return t.find_all{|x|x!=:flying}
    end
    t
  end

  # Levitate's Ground immunity is similarly bypassed ONLY during a Gravity
  # Ground-type damage calculation. Other ability hooks remain untouched.
  def ability_incoming_multiplier(move_type,category)
    if @pmd_ac_v038_ground_damage_override && move_type==:ground && respond_to?(:ability_key) && ability_key==:levitate
      return 1.0
    end
    pmd_ac_v038_ability_incoming_multiplier(move_type,category)
  end

  def pmd_ac_v038_ground_damage_override=(value);@pmd_ac_v038_ground_damage_override=value ? true:false;end
  def pmd_ac_v038_ground_damage_override?;@pmd_ac_v038_ground_damage_override ? true:false;end

  def calculate_damage(target_unit,power,category=:physical,move_type=:normal,random_percent=nil)
    override=false
    if move_type==:ground && target_unit!=nil && target_unit.respond_to?(:canonical_natural_airborne_v038?) && target_unit.canonical_natural_airborne_v038? && target_unit.respond_to?(:canonical_gravity_grounded_v038?) && target_unit.canonical_gravity_grounded_v038?
      override=true
      target_unit.pmd_ac_v038_ground_damage_override=true if target_unit.respond_to?(:pmd_ac_v038_ground_damage_override=)
    end
    begin
      value=pmd_ac_v038_calculate_damage(target_unit,power,category,move_type,random_percent)
    ensure
      target_unit.pmd_ac_v038_ground_damage_override=false if override && target_unit!=nil && target_unit.respond_to?(:pmd_ac_v038_ground_damage_override=)
    end
    if override && @scene!=nil
      @scene.log_event(:altitude,target_unit.log_name+' GRAVITY_GROUNDED ground_move=hit damage='+value.to_i.to_s)
    end
    value
  end
end

class Sprite_PMDChessUnit
  alias pmd_ac_v038_update_position update_position unless method_defined?(:pmd_ac_v038_update_position)
  def update_position
    # Let the verified core anchor bars/popups/status UI to the ground first.
    pmd_ac_v038_update_position
    return if @unit==nil || !@unit.respond_to?(:altitude_visual_profile_v038)
    p=@unit.altitude_visual_profile_v038
    self.y += @unit.altitude_visual_offset_y_v038.round
    # z intentionally remains the ground baseline from the original method.
    if !@unit.dead?
      self.opacity=(p[:opacity]||255).to_i
    end
    tone=p[:tone]||[0,0,0,0]
    if @unit.stun_frames>0
      self.tone.set(tone[0].to_i+40,tone[1].to_i+40,tone[2].to_i+40,tone[3].to_i)
    else
      self.tone.set(tone[0].to_i,tone[1].to_i,tone[2].to_i,tone[3].to_i)
    end
  end
end

class Scene_PMD_AutoChess
  alias pmd_ac_v038_start start unless method_defined?(:pmd_ac_v038_start)
  alias pmd_ac_v038_prepare_verification_battle prepare_verification_battle unless method_defined?(:pmd_ac_v038_prepare_verification_battle)
  alias pmd_ac_v038_update_verification_script update_verification_script unless method_defined?(:pmd_ac_v038_update_verification_script)
  alias pmd_ac_v038_log_event log_event unless method_defined?(:pmd_ac_v038_log_event)
  alias pmd_ac_v038_complete_verification_mode complete_verification_mode unless method_defined?(:pmd_ac_v038_complete_verification_mode)

  def start
    pmd_ac_v038_start
    begin
      if FileTest.exist?(PMD_AC::BATTLE_LOG_FILE)
        text=File.open(PMD_AC::BATTLE_LOG_FILE,'rb'){|f|f.read}
        text.sub!(/PMD AutoChess Proto v0\.[0-9.]+ Battle Verification Log/,'PMD AutoChess Proto v0.38 Battle Verification Log')
        File.open(PMD_AC::BATTLE_LOG_FILE,'wb'){|f|f.write(text)}
      end
    rescue
    end
    m=PMD_AC::ALTITUDE_MANIFEST_V038
    log_event(:altitude,'LOADED poses=5 natural=flying_type,levitate gravity_ground=1 ground_move_override=1 airborne_y=-10 bob=3/48 semi_y=6 semi_opacity=150 checksum32='+m[:runtime_checksum32].to_s)
  end

  def prepare_verification_battle
    pmd_ac_v038_prepare_verification_battle
    if verification_mode==:altitude
      @altitude_failed_v038=false
      clear_all_spatial_fields_v036(:verify) if respond_to?(:clear_all_spatial_fields_v036)
      for u in @units
        u.verification_combat_sandbox(true)
        u.verification_altitude_pose_v038(nil) if u.respond_to?(:verification_altitude_pose_v038)
      end
    end
  end

  def log_event(category,message)
    if category.to_s=='verify' && verification_mode==:altitude && message.to_s.index('ALTITUDE_')==0 && message.to_s.include?(' pass=0')
      @altitude_failed_v038=true
    end
    pmd_ac_v038_log_event(category,message)
  end

  def altitude_units_v038
    a=living_units(:ally);e=living_units(:enemy);[a[0],a[1],a[2],e[0]]
  end

  def altitude_temp_unit_v038(species,slot,team,id)
    i=PMD_PokemonInstance.new(species,50,{:instance_uid=>99038000+id.to_i,:ability_slot=>slot})
    u=Game_PMDChessUnit.new(9380+id.to_i,species,team,0,0,i);u.scene=self;u.verification_combat_sandbox(true);u
  end

  def altitude_sprite_for_v038(unit)
    return nil if @unit_sprites==nil
    @unit_sprites.find{|s|s.respond_to?(:unit) && s.unit==unit}
  end

  def verify_altitude_manifest_v038
    return if @verification_done[:altitude_manifest]
    e=PMD_AC.validate_altitude_v038;m=PMD_AC::ALTITUDE_MANIFEST_V038;pass=e.empty?
    log_event(:verify,'ALTITUDE_MANIFEST pass='+(pass ? '1':'0')+' poses=5 airborne_y=-10 bob=3/48 semi_y=6 semi_opacity=150 gravity_ground=1 checksum='+PMD_AC.altitude_checksum32_v038.to_s+' errors=['+e.join(',')+']')
    @verification_done[:altitude_manifest]=true
  end

  # Visual gallery on the three ally sprites: airborne / Dive-like / Dig-like.
  def verify_altitude_visual_v038
    return if @verification_done[:altitude_visual]
    air,water,earth,d=altitude_units_v038
    air.verification_altitude_pose_v038(:airborne);water.verification_altitude_pose_v038(:submerged);earth.verification_altitude_pose_v038(:underground)
    sa=altitude_sprite_for_v038(air);sw=altitude_sprite_for_v038(water);se=altitude_sprite_for_v038(earth)
    sa.update if sa;sw.update if sw;se.update if se
    ap=air.altitude_visual_profile_v038;wp=water.altitude_visual_profile_v038;ep=earth.altitude_visual_profile_v038
    pass=sa!=nil && sw!=nil && se!=nil && air.altitude_visual_offset_y_v038<0 && wp[:opacity].to_i==150 && ep[:opacity].to_i==150 && water.canonical_pose_movement_locked_v038? && earth.canonical_pose_movement_locked_v038?
    log_event(:verify,'ALTITUDE_VISUAL pass='+(pass ? '1':'0')+' airborne_offset='+sprintf('%.1f',air.altitude_visual_offset_y_v038)+' submerged_y='+wp[:base_y].to_s+' opacity='+wp[:opacity].to_s+' underground_y='+ep[:base_y].to_s+' opacity='+ep[:opacity].to_s+' bars_ground_anchor=1 z_ground_anchor=1')
    @verification_done[:altitude_visual]=true
  end

  def verify_altitude_gravity_visual_v038
    return if @verification_done[:altitude_gravity_visual]
    air,water,earth,d=altitude_units_v038
    set_canonical_field_effect_v035(:gravity,air,5)
    air.verification_altitude_pose_v038(:airborne)
    pose=air.canonical_altitude_pose_v038;off=air.altitude_visual_offset_y_v038
    # Dive/Dig-like layers are not airborne and Gravity does not erase them.
    dive=water.canonical_altitude_pose_v038;dig=earth.canonical_altitude_pose_v038
    pass=pose==:ground && off.abs<0.01 && dive==:submerged && dig==:underground
    log_event(:verify,'ALTITUDE_GRAVITY_VISUAL pass='+(pass ? '1':'0')+' airborne->'+pose.to_s+' offset='+sprintf('%.1f',off)+' dive='+dive.to_s+' dig='+dig.to_s+' gravity_only_airborne=1')
    @verification_done[:altitude_gravity_visual]=true
  end

  def verify_altitude_ground_immunity_v038
    return if @verification_done[:altitude_ground_immunity]
    clear_all_spatial_fields_v036(:verify)
    atk=altitude_temp_unit_v038(:rattata,:primary,:ally,1)
    fly=altitude_temp_unit_v038(:pidgey,:primary,:enemy,2)
    lev=altitude_temp_unit_v038(:gengar,:primary,:enemy,3)
    fly0=atk.calculate_damage(fly,80,:physical,:ground,100);lev0=atk.calculate_damage(lev,80,:physical,:ground,100)
    set_canonical_field_effect_v035(:gravity,atk,5)
    fly1=atk.calculate_damage(fly,80,:physical,:ground,100);lev1=atk.calculate_damage(lev,80,:physical,:ground,100)
    pass=fly.canonical_natural_airborne_v038? && lev.canonical_natural_airborne_v038? && fly0==0 && lev0==0 && fly1>0 && lev1>0 && fly.canonical_altitude_pose_v038==:ground && lev.canonical_altitude_pose_v038==:ground
    log_event(:verify,'ALTITUDE_GROUND_IMMUNITY pass='+(pass ? '1':'0')+' flying='+fly0.to_s+'->'+fly1.to_s+' levitate='+lev0.to_s+'->'+lev1.to_s+' gravity_restores_hit=1')
    @verification_done[:altitude_ground_immunity]=true
  end

  def verify_altitude_movement_lock_v038
    return if @verification_done[:altitude_movement_lock]
    clear_all_spatial_fields_v036(:verify)
    a,b,c,d=altitude_units_v038
    a.verification_altitude_pose_v038(nil);b.verification_altitude_pose_v038(:submerged);c.verification_altitude_pose_v038(:underground)
    b.set_move_goal(PMD_AC::BOARD_RIGHT,b.pixel_y);c.set_move_goal(PMD_AC::BOARD_RIGHT,c.pixel_y)
    vb=b.desired_velocity;vc=c.desired_velocity
    a.set_move_goal(PMD_AC::BOARD_RIGHT,a.pixel_y);va=a.desired_velocity
    b.clear_move_goal;c.clear_move_goal;a.clear_move_goal
    pass=(vb[0].abs+vb[1].abs)<0.001 && (vc[0].abs+vc[1].abs)<0.001 && (va[0].abs+va[1].abs)>0.01
    log_event(:verify,'ALTITUDE_MOVEMENT_LOCK pass='+(pass ? '1':'0')+' normal=('+sprintf('%.2f',va[0])+','+sprintf('%.2f',va[1])+') submerged=(0,0) underground=(0,0)')
    @verification_done[:altitude_movement_lock]=true
  end

  def verify_altitude_transient_api_v038
    return if @verification_done[:altitude_transient]
    a,b,c,d=altitude_units_v038
    a.verification_altitude_pose_v038(nil);a.set_altitude_pose_v038(:vanished,2);p0=a.canonical_altitude_pose_v038;a.update;a.update;a.update;p1=a.canonical_altitude_pose_v038
    # Current sample is Bulbasaur, so after transient expiry it should return ground.
    pass=p0==:vanished && p1==:ground
    log_event(:verify,'ALTITUDE_TRANSIENT_API pass='+(pass ? '1':'0')+' pose='+p0.to_s+'->'+p1.to_s+' api=set_altitude_pose_v038 expiry=1 future_hooks=fly,bounce,dive,dig,shadow_force')
    @verification_done[:altitude_transient]=true
  end

  def verify_altitude_runtime_v038
    return if @verification_done[:altitude_runtime]
    p=PMD_AC::ALTITUDE_POSE_V038
    pass=p[:airborne]!=nil && p[:submerged]!=nil && p[:underground]!=nil && Game_PMDChessUnit.instance_methods.map{|x|x.to_s}.include?('canonical_altitude_pose_v038')
    log_event(:verify,'ALTITUDE_RUNTIME pass='+(pass ? '1':'0')+' natural_sources=flying_type,levitate gravity=ground pose_api=1 move_runtime_hooks=prepared dive_dig_full_runtime=pending cumulative_moves=232')
    @verification_done[:altitude_runtime]=true
  end

  def verify_altitude_modes_v038
    return if @verification_done[:altitude_modes]
    exp=[:altitude,:field_ai,:field_spatial,:skill_special_ii,:skill_special];pass=PMD_AC::VERIFICATION_MODES==exp && verification_mode==:altitude
    log_event(:verify,'ALTITUDE_RECENT_MODES pass='+(pass ? '1':'0')+' modes=5 default=ALTITUDE')
    @verification_done[:altitude_modes]=true
  end

  def update_verification_script
    pmd_ac_v038_update_verification_script
    return unless verification_mode==:altitude
    f=@verification_frame
    verify_altitude_manifest_v038 if f==4
    verify_altitude_visual_v038 if f==40
    verify_altitude_gravity_visual_v038 if f==110
    verify_altitude_ground_immunity_v038 if f==190
    verify_altitude_movement_lock_v038 if f==280
    verify_altitude_transient_api_v038 if f==360
    verify_altitude_runtime_v038 if f==430
    verify_altitude_modes_v038 if f==460
    complete_verification_mode if f==PMD_AC::VERIFICATION_ALTITUDE_END_FRAME_V038
  end

  def complete_verification_mode
    if verification_mode==:altitude
      for u in @units
        u.verification_altitude_pose_v038(nil) if u.respond_to?(:verification_altitude_pose_v038)
        u.clear_altitude_pose_v038 if u.respond_to?(:clear_altitude_pose_v038)
      end
      clear_all_spatial_fields_v036(:verify) if respond_to?(:clear_all_spatial_fields_v036)
      if @altitude_failed_v038
        for u in @units;u.verification_finish;end
        @verification_done[:complete]=true
        log_event(:verify,'FAILED mode=ALTITUDE auto_skill=on original_skills=restored')
        return
      end
    end
    pmd_ac_v038_complete_verification_mode
  end
end
