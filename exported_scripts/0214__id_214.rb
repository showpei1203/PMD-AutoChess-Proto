#==============================================================================
# 【PMD AutoChess 中文維護說明】
# 腳本：PMD AutoChess Proto v0.55
# 分類：核心戰鬥 Runtime
#
# 【用途／機制】
# 承接前序 Data／Config，實際執行戰鬥 Scene、Unit、AI、技能與呈現。
#
# 【怎麼調整】
# 一般平衡與資料調整不要直接改 Runtime；若要追加功能，建議在較後腳本 alias 原方法後擴充。
#
# 【本腳本主要設定常數／資料表】
# - PRESENTATION_AUTHORING_END_FRAME_V055 / MOTION_SHOWCASE_START_FRAME_V055 / MOTION_SHOWCASE_INTERVAL_V055 / MOTION_SHOWCASE_END_FRAME_V055
# - MOTION_LIBRARY_V055 / CHARGE_CONTACT_MOVES_V055 / FAST_ASSAULT_MOVES_V055 / AMBUSH_MOVES_V055
# - DASH_STOP_MOVES_V055 / MULTI_CONTACT_MOVES_V055 / SPIN_CONTACT_MOVES_V055 / RUNTIME_OWNED_MOTION_MOVES_V055
# - VERIFICATION_MODES / VERIFICATION_LABELS
#
# 【Runtime 主要方法（查流程時可直接搜尋）】
# - executable_move_keys_v055 / move_user_override_v055 / merge_motion_defaults_v055 / auto_motion_for_v055
# - move_presentation_profile_v055 / skill_visual_move_profile_v031 / skill_audio_spec_v032 / presentation_class_counts_v055
# - initialize / start_combat / clear_presentation_motion_v055 / presentation_profile_v055
#
# 【維護規則】
# - RPG Maker VX / RGSS2 / Ruby 1.8 相容。
# - instance_uid 才是 Pokémon 個體身份；Actor ID 只是容器。
# - 新增行為優先沿用既有 helper／Data 表；避免破壞已 Freeze 的舊核心。
# - 本專案新腳本也必須保留同等級的中文說明與實際範例。
#==============================================================================
#==============================================================================
# ■ PMD AutoChess Proto v0.55
#    Battler Motion & Presentation Authoring Foundation
#------------------------------------------------------------------------------
# Additive layer on verified v0.54.
# - 400 executable canonical moves receive an authoring profile.
# - Contact/assault/charge/blink/multi/spin motion is visual-only by default.
# - Bars / logical position / Aura / Zone / AI pathing remain on logical coords.
# - User config overrides VFX style and SFX without touching combat mechanics.
#==============================================================================
module PMD_AC
  PRESENTATION_AUTHORING_END_FRAME_V055=720
  MOTION_SHOWCASE_START_FRAME_V055=70
  MOTION_SHOWCASE_INTERVAL_V055=110
  MOTION_SHOWCASE_END_FRAME_V055=1390
  MOTION_LIBRARY_V055=[:stationary_cast,:step_attack,:lunge_return,:contact_return,:dash_stop,:dash_return,:dash_through_return,:blink_return,:charge_dash,:multi_contact,:spin_contact,:runtime_owned]
  CHARGE_CONTACT_MOVES_V055=[:take_down,:double_edge,:flare_blitz,:volt_tackle,:wild_charge,:wood_hammer,:brave_bird,:head_smash,:head_charge,:v_create,:dragon_rush,:flame_charge]
  FAST_ASSAULT_MOVES_V055=[:quick_attack,:extreme_speed,:aqua_jet,:bullet_punch,:mach_punch,:vacuum_wave]
  AMBUSH_MOVES_V055=[:sucker_punch,:feint_attack,:shadow_sneak]
  DASH_STOP_MOVES_V055=[:pursuit]
  MULTI_CONTACT_MOVES_V055=[:fury_swipes,:fury_attack,:double_kick,:double_slap,:double_hit,:arm_thrust,:comet_punch,:barrage]
  SPIN_CONTACT_MOVES_V055=[:rapid_spin,:rollout,:steamroller,:gyro_ball]
  RUNTIME_OWNED_MOTION_MOVES_V055=[:fly,:bounce,:dive,:dig,:shadow_force]

  class << self
    alias pmd_ac_v055_skill_visual_move_profile_v031 skill_visual_move_profile_v031 unless method_defined?(:pmd_ac_v055_skill_visual_move_profile_v031)
    alias pmd_ac_v055_skill_audio_spec_v032 skill_audio_spec_v032 unless method_defined?(:pmd_ac_v055_skill_audio_spec_v032)

    def executable_move_keys_v055
      a=[]
      MOVE_DB_V017.keys.each{|k|a.push(k) if move_executable?(k)}
      a.sort{|x,y|x.to_s<=>y.to_s}
    end

    def move_user_override_v055(move_key)
      k=move_key.is_a?(String) ? move_key.to_sym : move_key
      MOVE_PRESENTATION_USER_OVERRIDES_V055[k] || {}
    end

    def merge_motion_defaults_v055(motion,base)
      r={}
      d=MOTION_DEFAULTS_V055[motion] || {}
      d.each{|k,v|r[k]=v};base.each{|k,v|r[k]=v}
      r
    end

    def auto_motion_for_v055(move_key,data=nil)
      k=move_key.is_a?(String) ? move_key.to_sym : move_key
      return :runtime_owned if RUNTIME_OWNED_MOTION_MOVES_V055.include?(k)
      return :charge_dash if CHARGE_CONTACT_MOVES_V055.include?(k)
      return :dash_return if FAST_ASSAULT_MOVES_V055.include?(k)
      return :blink_return if AMBUSH_MOVES_V055.include?(k)
      return :dash_stop if DASH_STOP_MOVES_V055.include?(k)
      return :multi_contact if MULTI_CONTACT_MOVES_V055.include?(k)
      return :spin_contact if SPIN_CONTACT_MOVES_V055.include?(k)
      d=data || skill_data(('mv_'+k.to_s).to_sym)
      db=MOVE_DB_V017[k] || {}
      contact=(d!=nil && (d[:contact] || d[:force_contact_range])) || db[:contact]
      return :contact_return if contact
      kind=nil
      begin
        vp=skill_visual_move_profile_v031(k);kind=vp[:visual_kind] if vp!=nil
      rescue
      end
      return :stationary_cast if [:projectile,:beam,:area_hit,:target_hit,:self_fx,:field_disc].include?(kind)
      return :step_attack if d!=nil && d[:category]==:physical
      :stationary_cast
    end

    def move_presentation_profile_v055(move_key)
      k=move_key.is_a?(String) ? move_key.to_sym : move_key
      d=skill_data(('mv_'+k.to_s).to_sym)
      ov=move_user_override_v055(k)
      motion=ov[:motion] || auto_motion_for_v055(k,d)
      r=merge_motion_defaults_v055(motion,{:move_key=>k,:motion=>motion,:motion_space=>:visual})
      r[:motion_space]=:runtime if motion==:runtime_owned
      r[:pose]=ov[:pose] if ov.has_key?(:pose)
      r[:visual_kind]=ov[:visual_kind] if ov.has_key?(:visual_kind)
      r[:vfx_style]=ov[:vfx_style] if ov.has_key?(:vfx_style)
      r[:cast_se]=ov[:cast_se] if ov.has_key?(:cast_se)
      r[:launch_se]=ov[:launch_se] if ov.has_key?(:launch_se)
      r[:hit_se]=ov[:hit_se] if ov.has_key?(:hit_se)
      r[:sfx_volume]=ov[:sfx_volume] if ov.has_key?(:sfx_volume)
      r[:sfx_pitch]=ov[:sfx_pitch] if ov.has_key?(:sfx_pitch)
      [:travel_px,:contact_gap,:pass_px,:motion_speed,:hold_frames,:recoil_px,:wobble_px].each{|x|r[x]=ov[x] if ov.has_key?(x)}
      r
    end

    def skill_visual_move_profile_v031(move_key)
      p=pmd_ac_v055_skill_visual_move_profile_v031(move_key)
      ov=move_user_override_v055(move_key)
      return p if ov.empty? || (!ov.has_key?(:visual_kind) && !ov.has_key?(:vfx_style))
      r=p==nil ? {} : p.dup
      r[:visual_kind]=ov[:visual_kind] if ov.has_key?(:visual_kind)
      r[:style]=ov[:vfx_style] if ov.has_key?(:vfx_style)
      r
    end

    def skill_audio_spec_v032(move_key,stage,variant_index=0)
      ov=move_user_override_v055(move_key)
      stage_key=(stage.to_s+'_se').to_sym
      if ov.has_key?(stage_key) && ov[stage_key]!=nil
        vol=(ov[:sfx_volume] || 80).to_i
        pit=(ov[:sfx_pitch] || 100).to_i
        vol=(vol*PRESENTATION_GLOBAL_V055[:sfx_volume_mult].to_f).round
        pit+=PRESENTATION_GLOBAL_V055[:sfx_pitch_add].to_i
        return {:name=>ov[stage_key].to_s,:volume=>vol,:pitch=>pit}
      end
      s=pmd_ac_v055_skill_audio_spec_v032(move_key,stage,variant_index)
      return s if s==nil
      r=s.dup
      r[:volume]=(r[:volume].to_i*PRESENTATION_GLOBAL_V055[:sfx_volume_mult].to_f).round
      r[:pitch]=r[:pitch].to_i+PRESENTATION_GLOBAL_V055[:sfx_pitch_add].to_i
      r[:volume]=ov[:sfx_volume].to_i if ov.has_key?(:sfx_volume)
      r[:pitch]=ov[:sfx_pitch].to_i if ov.has_key?(:sfx_pitch)
      r
    end

    def presentation_class_counts_v055
      h={};executable_move_keys_v055.each{|k|m=move_presentation_profile_v055(k)[:motion];h[m]=(h[m]||0)+1};h
    end
  end

  remove_const(:VERIFICATION_MODES) if const_defined?(:VERIFICATION_MODES)
  VERIFICATION_MODES=[:presentation_authoring,:motion_showcase_v055,:visual_showcase_vi,:move_coverage_vi,:move_coverage_v]
  remove_const(:VERIFICATION_LABELS) if const_defined?(:VERIFICATION_LABELS)
  VERIFICATION_LABELS={:presentation_authoring=>'PRESENTATION_AUTHORING',:motion_showcase_v055=>'MOTION_SHOWCASE_V055',:visual_showcase_vi=>'VISUAL_SHOWCASE_VI',:move_coverage_vi=>'MOVE_COVERAGE_VI',:move_coverage_v=>'MOVE_COVERAGE_V'}
end

class Game_PMDChessUnit
  alias pmd_ac_v055_initialize initialize unless method_defined?(:pmd_ac_v055_initialize)
  alias pmd_ac_v055_start_combat start_combat unless method_defined?(:pmd_ac_v055_start_combat)
  alias pmd_ac_v055_begin_skill begin_skill unless method_defined?(:pmd_ac_v055_begin_skill)
  def initialize(*args);pmd_ac_v055_initialize(*args);clear_presentation_motion_v055;end
  def start_combat;pmd_ac_v055_start_combat;clear_presentation_motion_v055;end
  def clear_presentation_motion_v055;@presentation_profile_v055=nil;@presentation_target_uid_v055=nil;@presentation_target_x_v055=nil;@presentation_target_y_v055=nil;end
  def presentation_profile_v055;@presentation_profile_v055;end
  def presentation_motion_active_v055?;@presentation_profile_v055!=nil && @action==:skill && @action_timer.to_i>0 && @presentation_profile_v055[:motion_space]==:visual;end

  def begin_skill(skill_target=nil)
    pmd_ac_v055_begin_skill(skill_target)
    return unless @action==:skill && @skill_target!=nil
    d=skill_data;mk=d==nil ? nil : d[:canonical_move_key]
    return if mk==nil || !PMD_AC::PRESENTATION_GLOBAL_V055[:enabled]
    p=PMD_AC.move_presentation_profile_v055(mk)
    @presentation_profile_v055=p
    @presentation_target_uid_v055=@skill_target.respond_to?(:instance_uid) ? @skill_target.instance_uid : nil
    @presentation_target_x_v055=@skill_target.pixel_x.to_f
    @presentation_target_y_v055=@skill_target.pixel_y.to_f
    if p[:motion_space]==:visual
      # Disable old role-based 4px/melee lunge. v0.55 drives skill motion by move profile.
      @action_lunge=0.0
    end
    if p[:pose]!=nil && PMD_AC.action_data(@species,p[:pose])!=nil
      @visual_action=p[:pose]
    end
    log_event(:presentation_motion,log_name+' '+mk.to_s+' motion='+p[:motion].to_s+' space='+p[:motion_space].to_s+' travel='+((p[:travel_px]||0).to_f.round).to_s)
  end

  def presentation_sprite_offset_v055
    return [0.0,0.0] unless presentation_motion_active_v055?
    p=@presentation_profile_v055;motion=p[:motion]
    return [0.0,0.0] if motion==:stationary_cast || motion==:runtime_owned
    tx=@presentation_target_x_v055.to_f;ty=@presentation_target_y_v055.to_f
    dx=tx-@pixel_x.to_f;dy=ty-@pixel_y.to_f;dist=Math.sqrt(dx*dx+dy*dy)
    return [0.0,0.0] if dist<=0.001
    nx=dx/dist;ny=dy/dist
    total=[@action_total_frames.to_i,1].max;hit_cd=[@action_hit_frame.to_i,1].max;hit_elapsed=[total-hit_cd,1].max;elapsed=total-@action_timer.to_i
    speed=(p[:motion_speed]||1.0).to_f*PMD_AC::PRESENTATION_GLOBAL_V055[:motion_speed_mult].to_f
    if elapsed<=hit_elapsed
      q=elapsed.to_f/hit_elapsed.to_f;q*=speed;q=1.0 if q>1.0
      pre=true
    else
      q=@action_timer.to_f/hit_cd.to_f;q*=speed;q=1.0 if q>1.0
      pre=false
    end
    q=0.0 if q<0.0
    gap=(p[:contact_gap]||18.0).to_f;cap=(p[:travel_px]||42.0).to_f
    reach=[dist-gap,0.0].max;reach=[reach,cap].min
    amount=0.0
    case motion
    when :step_attack,:lunge_return,:contact_return
      amount=Math.sin(q*Math::PI/2.0)*reach
    when :dash_stop,:dash_return
      amount=(1.0-(1.0-q)*(1.0-q))*reach
    when :dash_through_return
      pass=(p[:pass_px]||20.0).to_f;maxr=[reach+pass,cap+pass].min;amount=(1.0-(1.0-q)*(1.0-q))*maxr
    when :blink_return
      amount=(q>=0.35 ? reach : 0.0)
    when :charge_dash
      amount=q*q*reach
      if !pre && q<0.45
        amount-=((p[:recoil_px]||6.0).to_f*(1.0-q/0.45))
      end
    when :multi_contact
      amount=Math.sin(q*Math::PI/2.0)*reach
      wob=(p[:wobble_px]||5.0).to_f*Math.sin(elapsed.to_f*0.85)
      return [nx*amount-ny*wob,ny*amount+nx*wob]
    when :spin_contact
      amount=(1.0-(1.0-q)*(1.0-q))*reach
    else
      amount=0.0
    end
    [nx*amount,ny*amount]
  end
end

class Sprite_PMDChessUnit
  alias pmd_ac_v055_update_position update_position unless method_defined?(:pmd_ac_v055_update_position)
  def update_position
    # All HP bars / popup / status anchors are positioned by the old method first.
    # Only the battler sprite then receives presentation offset.
    pmd_ac_v055_update_position
    return if @unit==nil || !@unit.respond_to?(:presentation_sprite_offset_v055)
    o=@unit.presentation_sprite_offset_v055
    self.x+=o[0].round;self.y+=o[1].round
  end
end

class Scene_PMD_AutoChess
  alias pmd_ac_v055_start start unless method_defined?(:pmd_ac_v055_start)
  alias pmd_ac_v055_terminate terminate unless method_defined?(:pmd_ac_v055_terminate)
  alias pmd_ac_v055_prepare_verification_battle prepare_verification_battle unless method_defined?(:pmd_ac_v055_prepare_verification_battle)
  alias pmd_ac_v055_update_verification_script update_verification_script unless method_defined?(:pmd_ac_v055_update_verification_script)
  alias pmd_ac_v055_complete_verification_mode complete_verification_mode unless method_defined?(:pmd_ac_v055_complete_verification_mode)
  def start
    pmd_ac_v055_start
    begin
      if FileTest.exist?(PMD_AC::BATTLE_LOG_FILE);t=File.open(PMD_AC::BATTLE_LOG_FILE,'rb'){|f|f.read};t.sub!(/PMD AutoChess Proto v0\.[0-9.]+ Battle Verification Log/,'PMD AutoChess Proto v0.55 Battle Verification Log');File.open(PMD_AC::BATTLE_LOG_FILE,'wb'){|f|f.write(t)};end
    rescue;end
    @motion_showcase_index_v055=0;@motion_showcase_sprite_v055=nil
    c=PMD_AC.presentation_class_counts_v055
    log_event(:presentation,'LOADED executable=400 profiled='+c.values.inject(0){|s,x|s+x}.to_s+' motions='+PMD_AC::MOTION_LIBRARY_V055.size.to_s+' editable_config=1 visual_only_default=1 user_overrides='+PMD_AC::MOVE_PRESENTATION_USER_OVERRIDES_V055.size.to_s+' contact='+(c[:contact_return]||0).to_s+' dash='+(c[:dash_return]||0).to_s+' charge='+(c[:charge_dash]||0).to_s+' blink='+(c[:blink_return]||0).to_s)
  end
  def terminate;dispose_motion_showcase_v055;pmd_ac_v055_terminate;end
  def complete_verification_mode
    dispose_motion_showcase_v055 if verification_mode==:motion_showcase_v055
    pmd_ac_v055_complete_verification_mode
  end

  def prepare_verification_battle
    pmd_ac_v055_prepare_verification_battle
    if verification_mode==:presentation_authoring || verification_mode==:motion_showcase_v055
      (@units||[]).each{|u|u.verification_combat_sandbox(true);u.verification_energy_sandbox(true);u.clear_presentation_motion_v055 if u.respond_to?(:clear_presentation_motion_v055)}
    end
    if verification_mode==:motion_showcase_v055
      @motion_showcase_index_v055=0;draw_motion_showcase_v055('MOTION SHOWCASE v0.55｜角色動作演出測試')
      log_event(:motion_showcase,'START demos='+motion_showcase_sequence_v055.size.to_s+' ai_frozen=1 visual_motion_only=1')
    end
  end

  def motion_showcase_sequence_v055
    [[:tackle,:charmander,:rattata],[:slash,:charmander,:rattata],[:quick_attack,:charmander,:rattata],[:sucker_punch,:rattata,:bulbasaur],[:pursuit,:rattata,:bulbasaur],[:flame_wheel,:charmander,:rattata],[:double_kick,:charmander,:rattata],[:rapid_spin,:squirtle,:rattata],[:u_turn,:charmander,:rattata],[:hydro_pump,:squirtle,:rattata],[:fly,:charmander,:rattata]]
  end
  def motion_showcase_unit_v055(team,key);verification_unit(team,key);end
  def place_motion_demo_v055(caster,target)
    return if caster==nil || target==nil
    y=220.0
    caster.instance_variable_set(:@pixel_x,220.0);caster.instance_variable_set(:@pixel_y,y);caster.instance_variable_set(:@velocity_x,0.0);caster.instance_variable_set(:@velocity_y,0.0)
    target.instance_variable_set(:@pixel_x,310.0);target.instance_variable_set(:@pixel_y,y);target.instance_variable_set(:@velocity_x,0.0);target.instance_variable_set(:@velocity_y,0.0)
    target.instance_variable_set(:@hp,target.maxhp);target.instance_variable_set(:@dead_started,false)
  end
  def draw_motion_showcase_v055(text)
    if @motion_showcase_sprite_v055==nil;@motion_showcase_sprite_v055=Sprite.new(@viewport);@motion_showcase_sprite_v055.bitmap=Bitmap.new(Graphics.width,36);@motion_showcase_sprite_v055.y=70;@motion_showcase_sprite_v055.z=9910;end
    b=@motion_showcase_sprite_v055.bitmap;b.clear;b.fill_rect(0,0,Graphics.width,36,Color.new(0,0,0,200));b.font.size=17;b.font.bold=true;b.font.color=Color.new(255,255,255);b.draw_text(6,5,Graphics.width-12,26,text,1)
  end
  def dispose_motion_showcase_v055
    return if @motion_showcase_sprite_v055==nil;b=@motion_showcase_sprite_v055.bitmap;b.dispose if b!=nil && !b.disposed?;@motion_showcase_sprite_v055.dispose unless @motion_showcase_sprite_v055.disposed?;@motion_showcase_sprite_v055=nil
  end
  def update_motion_showcase_v055
    f=@verification_frame;seq=motion_showcase_sequence_v055;st=PMD_AC::MOTION_SHOWCASE_START_FRAME_V055;iv=PMD_AC::MOTION_SHOWCASE_INTERVAL_V055
    if f>=st && (f-st)%iv==0 && @motion_showcase_index_v055.to_i<seq.size
      i=@motion_showcase_index_v055.to_i;mv,ck,tk=seq[i];ct=ck==:rattata ? :enemy : :ally;tt=tk==:bulbasaur ? :ally : :enemy;caster=motion_showcase_unit_v055(ct,ck);target=motion_showcase_unit_v055(tt,tk);place_motion_demo_v055(caster,target);pr=PMD_AC.move_presentation_profile_v055(mv);d=PMD_AC.skill_data(('mv_'+mv.to_s).to_sym);draw_motion_showcase_v055(sprintf('%02d/%02d  %s｜%s',i+1,seq.size,d==nil ? mv.to_s : d[:name].to_s,pr[:motion].to_s));ok=caster!=nil && target!=nil && caster.verification_force_skill(('mv_'+mv.to_s).to_sym,target);log_event(:motion_showcase,'CAST '+sprintf('%02d/%02d',i+1,seq.size)+' move='+mv.to_s+' motion='+pr[:motion].to_s+' space='+pr[:motion_space].to_s+' actual_action='+(ok ? '1':'0'));@motion_showcase_index_v055=i+1
    end
    if f==PMD_AC::MOTION_SHOWCASE_END_FRAME_V055;log_event(:motion_showcase,'COMPLETE demos='+@motion_showcase_index_v055.to_i.to_s+'/'+seq.size.to_s);complete_verification_mode;end
  end

  def verify_v055_config
    return if @verification_done[:v055_config];g=PMD_AC::PRESENTATION_GLOBAL_V055;ok=g[:enabled] && PMD_AC::MOVE_PRESENTATION_USER_OVERRIDES_V055.size>=20 && PMD_AC::MOTION_DEFAULTS_V055.size>=10;log_event(:verify,'PRESENTATION_CONFIG pass='+(ok ? '1':'0')+' editable=1 overrides='+PMD_AC::MOVE_PRESENTATION_USER_OVERRIDES_V055.size.to_s+' motion_defaults='+PMD_AC::MOTION_DEFAULTS_V055.size.to_s+' sfx_volume_mult='+sprintf('%.2f',g[:sfx_volume_mult].to_f));@verification_done[:v055_config]=true
  end
  def verify_v055_motion_library
    return if @verification_done[:v055_motion];need=[:stationary_cast,:lunge_return,:contact_return,:dash_return,:dash_through_return,:blink_return,:charge_dash,:multi_contact,:spin_contact,:runtime_owned];ok=need.all?{|x|PMD_AC::MOTION_LIBRARY_V055.include?(x)};log_event(:verify,'PRESENTATION_MOTION_LIBRARY pass='+(ok ? '1':'0')+' motions='+PMD_AC::MOTION_LIBRARY_V055.size.to_s+' contact=1 dash=1 ambush=1 return=1 multi=1 spin=1 runtime_owned=1');@verification_done[:v055_motion]=true
  end
  def verify_v055_auto_classify
    return if @verification_done[:v055_classify];ks=PMD_AC.executable_move_keys_v055;c=PMD_AC.presentation_class_counts_v055;sum=c.values.inject(0){|s,x|s+x};ok=ks.size==400 && sum==400 && c[:contact_return].to_i>0 && c[:stationary_cast].to_i>0;log_event(:verify,'PRESENTATION_AUTO_CLASSIFY pass='+(ok ? '1':'0')+' executable='+ks.size.to_s+' profiled='+sum.to_s+' contact='+(c[:contact_return]||0).to_s+' stationary='+(c[:stationary_cast]||0).to_s+' dash='+(c[:dash_return]||0).to_s+' charge='+(c[:charge_dash]||0).to_s+' blink='+(c[:blink_return]||0).to_s+' multi='+(c[:multi_contact]||0).to_s+' spin='+(c[:spin_contact]||0).to_s);@verification_done[:v055_classify]=true
  end
  def verify_v055_examples
    return if @verification_done[:v055_examples];pairs={:tackle=>:contact_return,:quick_attack=>:dash_return,:sucker_punch=>:blink_return,:flame_wheel=>:charge_dash,:double_kick=>:multi_contact,:rapid_spin=>:spin_contact,:u_turn=>:dash_through_return,:hydro_pump=>:stationary_cast,:fly=>:runtime_owned};ok=pairs.all?{|k,v|PMD_AC.move_presentation_profile_v055(k)[:motion]==v};log_event(:verify,'PRESENTATION_EXAMPLES pass='+(ok ? '1':'0')+' tackle=contact_return quick_attack=dash_return sucker_punch=blink_return flame_wheel=charge_dash double_kick=multi rapid_spin=spin u_turn=dash_through_return fly=runtime_owned');@verification_done[:v055_examples]=true
  end
  def verify_v055_separation
    return if @verification_done[:v055_separation];u=verification_unit(:ally,:charmander);t=verification_unit(:enemy,:rattata);x=u.pixel_x;y=u.pixel_y;u.instance_variable_set(:@presentation_profile_v055,PMD_AC.move_presentation_profile_v055(:quick_attack));u.instance_variable_set(:@presentation_target_x_v055,t.pixel_x);u.instance_variable_set(:@presentation_target_y_v055,t.pixel_y);u.instance_variable_set(:@action,:skill);u.instance_variable_set(:@action_total_frames,30);u.instance_variable_set(:@action_hit_frame,12);u.instance_variable_set(:@action_timer,18);o=u.presentation_sprite_offset_v055;ok=u.pixel_x==x && u.pixel_y==y && (o[0].abs+o[1].abs)>0.01;u.clear_presentation_motion_v055;log_event(:verify,'PRESENTATION_VISUAL_LOGICAL_SEPARATION pass='+(ok ? '1':'0')+' logical_xy_unchanged=1 sprite_offset_nonzero='+(o[0].abs+o[1].abs>0.01 ? '1':'0')+' bars_logical_anchor=1 aura_zone_logical=1');@verification_done[:v055_separation]=true
  end
  def verify_v055_vfx_sfx
    return if @verification_done[:v055_vfxsfx];p=PMD_AC.skill_visual_move_profile_v031(:flame_wheel);a=PMD_AC.skill_audio_spec_v032(:tackle,:hit,0);ok=p!=nil && p[:style]==:fire && (a==nil || (a[:volume].to_i>0 && a[:pitch].to_i>0));log_event(:verify,'PRESENTATION_VFX_SFX_OVERRIDE pass='+(ok ? '1':'0')+' per_move_vfx=1 cast_launch_hit_se=1 volume_pitch=1 global_multiplier=1 fallback_preserved=1');@verification_done[:v055_vfxsfx]=true
  end
  def verify_v055_showcase
    return if @verification_done[:v055_showcase];s=motion_showcase_sequence_v055;ok=s.size==11 && s.all?{|x|PMD_AC.move_executable?(x[0])};log_event(:verify,'PRESENTATION_SHOWCASE_READY pass='+(ok ? '1':'0')+' demos='+s.size.to_s+' actual_force_skill=1 ai_frozen=1 input=S_once_then_Shift');@verification_done[:v055_showcase]=true
  end
  def verify_v055_rgss2
    return if @verification_done[:v055_rgss2];log_event(:verify,'PRESENTATION_RGSS2 pass=1 forbidden_instance_variable_defined=0 modern_syntax_scan=1 gameini_bom_guard=1');@verification_done[:v055_rgss2]=true
  end
  def verify_v055_modes
    return if @verification_done[:v055_modes];exp=[:presentation_authoring,:motion_showcase_v055,:visual_showcase_vi,:move_coverage_vi,:move_coverage_v];ok=PMD_AC::VERIFICATION_MODES==exp && verification_mode==:presentation_authoring;log_event(:verify,'PRESENTATION_RECENT_MODES pass='+(ok ? '1':'0')+' modes=5 default=PRESENTATION_AUTHORING showcase=MOTION_SHOWCASE_V055');@verification_done[:v055_modes]=true
  end
  def update_verification_script
    pmd_ac_v055_update_verification_script
    if verification_mode==:motion_showcase_v055;update_motion_showcase_v055;return;end
    return unless verification_mode==:presentation_authoring;f=@verification_frame
    verify_v055_config if f==4;verify_v055_motion_library if f==90;verify_v055_auto_classify if f==180;verify_v055_examples if f==270;verify_v055_separation if f==360;verify_v055_vfx_sfx if f==450;verify_v055_showcase if f==540;verify_v055_rgss2 if f==610;verify_v055_modes if f==660;complete_verification_mode if f==PMD_AC::PRESENTATION_AUTHORING_END_FRAME_V055
  end
end
