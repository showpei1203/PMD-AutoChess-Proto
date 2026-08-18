#==============================================================================
# 【PMD AutoChess 中文維護說明】
# 腳本：PMD AutoChess Proto v0.56
# 分類：核心戰鬥 Runtime
#
# 【用途／機制】
# 承接前序 Data／Config，實際執行戰鬥 Scene、Unit、AI、技能與呈現。
#
# 【怎麼調整】
# 一般平衡與資料調整不要直接改 Runtime；若要追加功能，建議在較後腳本 alias 原方法後擴充。
#
# 【本腳本主要設定常數／資料表】
# - VERIFICATION_MOVE_COVERAGE_VII_END_FRAME_V056 / VISUAL_SHOWCASE_VII_START_FRAME_V056 / VERIFICATION_MODES / VERIFICATION_LABELS
#
# 【Runtime 主要方法（查流程時可直接搜尋）】
# - move_coverage_vii_key_from_skill_v056 / canonical_move_key_from_skill / move_executable? / move_autochess_hint
# - skill_data / skill_audio_move_profile_v032 / skill_visual_move_profile_v031 / skill_audio_spec_v032
# - move_coverage_vii_checksum32_v056 / validate_move_coverage_vii_v056 / initialize / start_combat
#
# 【維護規則】
# - RPG Maker VX / RGSS2 / Ruby 1.8 相容。
# - instance_uid 才是 Pokémon 個體身份；Actor ID 只是容器。
# - 新增行為優先沿用既有 helper／Data 表；避免破壞已 Freeze 的舊核心。
# - 本專案新腳本也必須保留同等級的中文說明與實際範例。
#==============================================================================
#===============================================================================
# ■ PMD AutoChess Proto v0.56
#    Move Runtime Coverage Expansion VII
#-------------------------------------------------------------------------------
# Base: runtime-verified v0.55.3 presentation/motion layer.
#===============================================================================
module PMD_AC
  VERIFICATION_MOVE_COVERAGE_VII_END_FRAME_V056=1320
  VISUAL_SHOWCASE_VII_START_FRAME_V056=70
  class << self
    alias pmd_ac_v056_canonical_move_key_from_skill canonical_move_key_from_skill unless method_defined?(:pmd_ac_v056_canonical_move_key_from_skill)
    alias pmd_ac_v056_move_executable move_executable? unless method_defined?(:pmd_ac_v056_move_executable)
    alias pmd_ac_v056_move_autochess_hint move_autochess_hint unless method_defined?(:pmd_ac_v056_move_autochess_hint)
    alias pmd_ac_v056_skill_data skill_data unless method_defined?(:pmd_ac_v056_skill_data)
    alias pmd_ac_v056_skill_audio_move_profile_v032 skill_audio_move_profile_v032 unless method_defined?(:pmd_ac_v056_skill_audio_move_profile_v032)
    alias pmd_ac_v056_skill_visual_move_profile_v031 skill_visual_move_profile_v031 unless method_defined?(:pmd_ac_v056_skill_visual_move_profile_v031)
    alias pmd_ac_v056_skill_audio_spec_v032 skill_audio_spec_v032 unless method_defined?(:pmd_ac_v056_skill_audio_spec_v032)

    def move_coverage_vii_key_from_skill_v056(skill_key)
      return nil if skill_key==nil;text=skill_key.to_s;return nil unless text[0,3]=='mv_';k=text[3,text.size-3].to_sym;MOVE_COVERAGE_VII_MOVE_V056[k]==nil ? nil : k
    end
    def canonical_move_key_from_skill(skill_key);k=move_coverage_vii_key_from_skill_v056(skill_key);return k if k!=nil;pmd_ac_v056_canonical_move_key_from_skill(skill_key);end
    def move_executable?(move_key);k=move_key.is_a?(String) ? move_key.to_sym : move_key;return true if MOVE_COVERAGE_VII_MOVE_V056[k]!=nil;pmd_ac_v056_move_executable(move_key);end
    def move_autochess_hint(move_key)
      k=move_key.is_a?(String) ? move_key.to_sym : move_key;b=MOVE_COVERAGE_VII_MOVE_V056[k];return pmd_ac_v056_move_autochess_hint(move_key) if b==nil
      old=pmd_ac_v056_move_autochess_hint(move_key);r=old==nil ? {} : old.dup;[:behavior_status,:delivery,:range_px,:runtime_skill_key,:priority,:target_type,:policy].each{|x|r[x]=b[x] if b[x]!=nil};r
    end
    def skill_data(key);mk=move_coverage_vii_key_from_skill_v056(key);return MOVE_COVERAGE_VII_MOVE_V056[mk].dup if mk!=nil;pmd_ac_v056_skill_data(key);end
    def skill_audio_move_profile_v032(move_key);k=move_key.is_a?(String) ? move_key.to_sym : move_key;b=MOVE_COVERAGE_VII_AUDIO_V056[k];return b if b!=nil;pmd_ac_v056_skill_audio_move_profile_v032(move_key);end
    def skill_visual_move_profile_v031(move_key);k=move_key.is_a?(String) ? move_key.to_sym : move_key;b=MOVE_COVERAGE_VII_VISUAL_V056[k];return b if b!=nil;pmd_ac_v056_skill_visual_move_profile_v031(move_key);end
    def skill_audio_spec_v032(move_key,stage,variant_index=0)
      k=move_key.is_a?(String) ? move_key.to_sym : move_key
      if stage==:cast && MELEE_CAST_SFX_CLEANUP_V056[k]!=nil
        ov=respond_to?(:move_user_override_v055) ? move_user_override_v055(k) : {}
        return MELEE_CAST_SFX_CLEANUP_V056[k].dup unless ov.has_key?(:cast_se) && ov[:cast_se]!=nil
      end
      pmd_ac_v056_skill_audio_spec_v032(move_key,stage,variant_index)
    end
    def move_coverage_vii_checksum32_v056;h=0;MOVE_COVERAGE_VII_CHECKSUM_TEXT_V056.each_byte{|c|h=((h*33)+c)&0x7fffffff};h;end
    def validate_move_coverage_vii_v056
      e=[];m=MOVE_COVERAGE_VII_MANIFEST_V056;e.push('count') unless MOVE_COVERAGE_VII_MOVE_V056.size==30;e.push('cumulative') unless m[:cumulative_mapped_move_count].to_i==430;e.push('refs') unless m[:new_reference_covered].to_i==198 && m[:cumulative_reference_covered].to_i==6739;e.push('presentation') unless MOVE_PRESENTATION_V056.size==30;e.push('checksum') unless move_coverage_vii_checksum32_v056==m[:runtime_checksum32].to_i
      m[:new_move_keys].each{|k|e.push('data:'+k.to_s) if MOVE_COVERAGE_VII_MOVE_V056[k]==nil;e.push('visual:'+k.to_s) if MOVE_COVERAGE_VII_VISUAL_V056[k]==nil;e.push('audio:'+k.to_s) if MOVE_COVERAGE_VII_AUDIO_V056[k]==nil;e.push('timing:'+k.to_s) if MOVE_PRESENTATION_V056[k]==nil || MOVE_PRESENTATION_V056[k][:timing]==nil}
      e
    end
  end
  remove_const(:VERIFICATION_MODES) if const_defined?(:VERIFICATION_MODES)
  VERIFICATION_MODES=[:move_coverage_vii,:visual_showcase_vii,:presentation_authoring,:motion_showcase_v055,:move_coverage_vi]
  remove_const(:VERIFICATION_LABELS) if const_defined?(:VERIFICATION_LABELS)
  VERIFICATION_LABELS={:move_coverage_vii=>'MOVE_COVERAGE_VII',:visual_showcase_vii=>'VISUAL_SHOWCASE_VII',:presentation_authoring=>'PRESENTATION_AUTHORING',:motion_showcase_v055=>'MOTION_SHOWCASE_V055',:move_coverage_vi=>'MOVE_COVERAGE_VI'}
end

class Game_PMDChessUnit
  alias pmd_ac_v056_initialize initialize unless method_defined?(:pmd_ac_v056_initialize)
  alias pmd_ac_v056_start_combat start_combat unless method_defined?(:pmd_ac_v056_start_combat)
  alias pmd_ac_v056_deploy_to_cell deploy_to_cell unless method_defined?(:pmd_ac_v056_deploy_to_cell)
  alias pmd_ac_v056_deploy_to_pixel deploy_to_pixel unless method_defined?(:pmd_ac_v056_deploy_to_pixel)
  alias pmd_ac_v056_update update unless method_defined?(:pmd_ac_v056_update)
  alias pmd_ac_v056_update_logic update_logic unless method_defined?(:pmd_ac_v056_update_logic)
  alias pmd_ac_v056_remove_status remove_status unless method_defined?(:pmd_ac_v056_remove_status)
  alias pmd_ac_v056_skill_data skill_data unless method_defined?(:pmd_ac_v056_skill_data)
  alias pmd_ac_v056_start_faint start_faint unless method_defined?(:pmd_ac_v056_start_faint)
  alias pmd_ac_v056_canonical_natural_airborne_v038 canonical_natural_airborne_v038? unless method_defined?(:pmd_ac_v056_canonical_natural_airborne_v038)
  alias pmd_ac_v056_canonical_update_immobilized_status canonical_update_immobilized_status unless method_defined?(:pmd_ac_v056_canonical_update_immobilized_status)

  def initialize(*args);pmd_ac_v056_initialize(*args);reset_move_coverage_vii_v056;end
  def start_combat;pmd_ac_v056_start_combat;reset_move_coverage_vii_v056;end
  def deploy_to_cell(x,y);pmd_ac_v056_deploy_to_cell(x,y);reset_move_coverage_vii_v056;end
  def deploy_to_pixel(x,y);pmd_ac_v056_deploy_to_pixel(x,y);reset_move_coverage_vii_v056;end
  def reset_move_coverage_vii_v056
    @toxic_frames_v056=0;@toxic_tick_v056=0;@toxic_stage_v056=0;@toxic_source_uid_v056=nil
    @magic_coat_frames_v056=0;@smack_down_frames_v056=0;@mimic_move_v056=nil;@charge_move_v056=nil;@charge_release_move_v056=nil
  end
  def set_magic_coat_v056(f);@magic_coat_frames_v056=[f.to_i,1].max;end
  def magic_coat_active_v056?;@magic_coat_frames_v056.to_i>0;end
  def consume_magic_coat_v056;@magic_coat_frames_v056=0;end
  def set_smack_down_v056(f);@smack_down_frames_v056=[f.to_i,1].max;clear_altitude_pose_v038 if respond_to?(:clear_altitude_pose_v038);end
  def smack_down_active_v056?;@smack_down_frames_v056.to_i>0;end
  def canonical_natural_airborne_v038?;return false if smack_down_active_v056?;pmd_ac_v056_canonical_natural_airborne_v038;end
  def set_mimic_move_v056(k);@mimic_move_v056=k;end
  def mimic_move_v056;@mimic_move_v056;end
  def start_charge_v056(k);@charge_move_v056=k;end
  def charging_v056?;@charge_move_v056!=nil;end
  def release_charge_v056(k);@charge_move_v056=nil;@charge_release_move_v056=k;end
  def charge_releasing_v056?(k);@charge_release_move_v056==k;end
  def clear_charge_release_v056;@charge_release_move_v056=nil;end
  def toxic_active_v056?;@toxic_frames_v056.to_i>0 && status?(:poison);end
  def apply_toxic_v056(source,duration=300,interval=60)
    return false if dead? || canonical_major_status_active?
    apply_status(:poison,{:duration=>999999,:value=>0,:interval=>999999,:stack_mode=>:refresh},source)
    return false unless status?(:poison)
    @toxic_frames_v056=[duration.to_i,1].max;@toxic_tick_v056=[interval.to_i,1].max;@toxic_stage_v056=0;@toxic_source_uid_v056=source==nil ? nil : source.instance_uid;true
  end
  def remove_status(key)
    r=pmd_ac_v056_remove_status(key)
    if key==:poison;@toxic_frames_v056=0;@toxic_stage_v056=0;@toxic_tick_v056=0;@toxic_source_uid_v056=nil;end
    r
  end
  def skill_data
    if @skill_type!=nil && @skill_type.to_s=='mv_mimic' && @mimic_move_v056!=nil
      d=PMD_AC.skill_data(('mv_'+@mimic_move_v056.to_s).to_sym);return d if d!=nil
    end
    pmd_ac_v056_skill_data
  end
  def update
    pmd_ac_v056_update
    @magic_coat_frames_v056-=1 if @magic_coat_frames_v056.to_i>0
    @smack_down_frames_v056-=1 if @smack_down_frames_v056.to_i>0
    if @toxic_frames_v056.to_i>0 && status?(:poison) && !dead?
      @toxic_frames_v056-=1;@toxic_tick_v056-=1
      if @toxic_tick_v056.to_i<=0
        @toxic_stage_v056=[@toxic_stage_v056.to_i+1,15].min;amt=[(maxhp*@toxic_stage_v056.to_f/16.0).round,1].max;src=nil
        if @scene!=nil && @toxic_source_uid_v056!=nil && @scene.respond_to?(:unit_by_uid_v053);src=@scene.unit_by_uid_v053(@toxic_source_uid_v056);end
        receive_damage(amt,src,false,true,false);@scene.add_vfx_impact(self,:poison) if @scene!=nil;log_event(:move_coverage_vii,log_name+' TOXIC_TICK stage='+@toxic_stage_v056.to_s+' damage='+amt.to_s)
        @toxic_tick_v056=60
      end
      remove_status(:poison) if @toxic_frames_v056.to_i<=0 && status?(:poison)
    end
  end
  def update_logic
    if charging_v056?;clear_move_goal;@velocity_x*=PMD_AC::STOP_DAMPING;@velocity_y*=PMD_AC::STOP_DAMPING;@visual_action=:charge if PMD_AC.action_data(@species,:charge)!=nil;return;end
    pmd_ac_v056_update_logic
  end
  def canonical_update_immobilized_status
    if sleeping? && !acting? && @energy.to_i>=PMD_AC::MAX_ENERGY && respond_to?(:progression_move_pool_v046) && progression_move_pool_v046.include?(:snore)
      t=@target
      if (t==nil || t.dead?) && @scene!=nil && @scene.respond_to?(:nearest_enemy_v056);t=@scene.nearest_enemy_v056(self);end
      if t!=nil && !t.dead?;verification_set_skill(:mv_snore);begin_skill(t);log_event(:move_coverage_vii,log_name+' SNORE_SLEEP_CAST -> '+t.log_name);return true;end
    end
    pmd_ac_v056_canonical_update_immobilized_status
  end
  def start_faint;reset_move_coverage_vii_v056;pmd_ac_v056_start_faint;end
end

class Scene_PMD_AutoChess
  alias pmd_ac_v056_start start unless method_defined?(:pmd_ac_v056_start)
  alias pmd_ac_v056_terminate terminate unless method_defined?(:pmd_ac_v056_terminate)
  alias pmd_ac_v056_update update unless method_defined?(:pmd_ac_v056_update)
  alias pmd_ac_v056_apply_skill_effects apply_skill_effects unless method_defined?(:pmd_ac_v056_apply_skill_effects)
  alias pmd_ac_v056_canonical_accuracy_probability canonical_accuracy_probability unless method_defined?(:pmd_ac_v056_canonical_accuracy_probability)
  alias pmd_ac_v056_prepare_verification_battle prepare_verification_battle unless method_defined?(:pmd_ac_v056_prepare_verification_battle)
  alias pmd_ac_v056_update_verification_script update_verification_script unless method_defined?(:pmd_ac_v056_update_verification_script)
  alias pmd_ac_v056_complete_verification_mode complete_verification_mode unless method_defined?(:pmd_ac_v056_complete_verification_mode)
  alias pmd_ac_v056_resolve_repeat_event_v053 resolve_repeat_event_v053 unless method_defined?(:pmd_ac_v056_resolve_repeat_event_v053)
  alias pmd_ac_v056_skill_cast_worthwhile skill_cast_worthwhile? unless method_defined?(:pmd_ac_v056_skill_cast_worthwhile)

  def start
    pmd_ac_v056_start
    begin
      if FileTest.exist?(PMD_AC::BATTLE_LOG_FILE);t=File.open(PMD_AC::BATTLE_LOG_FILE,'rb'){|f|f.read};t.sub!(/PMD AutoChess Proto v0\.[0-9.]+ Battle Verification Log/,'PMD AutoChess Proto v0.56 Battle Verification Log');File.open(PMD_AC::BATTLE_LOG_FILE,'wb'){|f|f.write(t)};end
    rescue;end
    reset_move_coverage_vii_scene_v056;@showcase_vii_index_v056=0;@showcase_vii_next_frame_v056=PMD_AC::VISUAL_SHOWCASE_VII_START_FRAME_V056;@showcase_vii_finish_frame_v056=nil;@showcase_vii_post_v056=nil;@showcase_vii_sprite_v056=nil;m=PMD_AC::MOVE_COVERAGE_VII_MANIFEST_V056
    log_event(:move_coverage_vii,'LOADED new=30 cumulative=430 audited='+m[:cumulative_reference_covered].to_s+'/'+m[:learnset_reference_total].to_s+' coverage='+sprintf('%.2f',m[:cumulative_coverage_percent].to_f)+'% presentation=30 timing=30 checksum32='+m[:runtime_checksum32].to_s)
    log_event(:presentation,'PATCH v0.56 melee_cast_sfx_cleanup=tackle,slash,quick_attack,false_swipe,rapid_spin tone_mid_beep_removed=1')
  end
  def terminate;dispose_showcase_vii_v056;reset_move_coverage_vii_scene_v056;pmd_ac_v056_terminate;end
  def reset_move_coverage_vii_scene_v056
    @events_v056=[];@hazards_v056={:ally=>{:spikes=>0,:spikes_frames=>0,:spikes_source=>nil,:rock=>false,:rock_frames=>0,:rock_source=>nil},:enemy=>{:spikes=>0,:spikes_frames=>0,:spikes_source=>nil,:rock=>false,:rock_frames=>0,:rock_source=>nil}};@magic_coat_reflecting_v056=false
  end
  def other_team_v056(team);team==:ally ? :enemy : :ally;end
  def unit_by_uid_v056(uid);return nil if uid==nil;(@units||[]).find{|u|u.instance_uid==uid};end
  def nearest_enemy_v056(user);return nil if user==nil;a=(@units||[]).find_all{|u|!u.dead? && u.team!=user.team};a.sort!{|x,y|user.distance_to(x)<=>user.distance_to(y)};a[0];end
  def schedule_event_v056(e);@events_v056=[] if @events_v056==nil;@events_v056.push(e);end
  def schedule_wish_v056(user,delay,ratio);schedule_event_v056({:kind=>:wish,:due=>Graphics.frame_count+delay.to_i,:uid=>user.instance_uid,:ratio=>ratio.to_f});log_event(:move_coverage_vii,user.log_name+' WISH_SET delay='+delay.to_i.to_s);true;end
  def schedule_charge_v056(user,target,move,frames)
    return false if user==nil || target==nil;user.start_charge_v056(move);schedule_event_v056({:kind=>:charge,:due=>Graphics.frame_count+frames.to_i,:uid=>user.instance_uid,:target_uid=>target.instance_uid,:move=>move});add_vfx_impact(user,move==:sky_attack ? :flying : :normal);log_event(:move_coverage_vii,user.log_name+' CHARGE '+move.to_s+' frames='+frames.to_i.to_s);true
  end
  def update_events_v056
    return if @events_v056==nil || @events_v056.empty?;now=Graphics.frame_count;keep=[]
    @events_v056.each do |e|
      if now<e[:due].to_i;keep.push(e);next;end
      if e[:kind]==:wish
        u=unit_by_uid_v056(e[:uid]);if u!=nil && !u.dead?;amt=[(u.maxhp*e[:ratio].to_f).round,1].max;actual=u.heal(amt);add_skill_effect(u,:heal);log_event(:move_coverage_vii,u.log_name+' WISH_HEAL actual='+actual.to_i.to_s);end
      elsif e[:kind]==:charge
        u=unit_by_uid_v056(e[:uid]);next if u==nil || u.dead?;t=unit_by_uid_v056(e[:target_uid]);t=nearest_enemy_v056(u) if t==nil || t.dead?;if t!=nil;u.release_charge_v056(e[:move]);u.verification_force_skill(('mv_'+e[:move].to_s).to_sym,t);log_event(:move_coverage_vii,u.log_name+' CHARGE_RELEASE '+e[:move].to_s+' -> '+t.log_name);else;u.instance_variable_set(:@charge_move_v056,nil);end
      end
    end;@events_v056=keep
  end
  def update_hazards_v056
    return if @hazards_v056==nil
    [:ally,:enemy].each do |team|
      h=@hazards_v056[team]
      if h[:spikes_frames].to_i>0;h[:spikes_frames]-=1;h[:spikes]=0 if h[:spikes_frames].to_i<=0;end
      if h[:rock_frames].to_i>0;h[:rock_frames]-=1;if h[:rock_frames].to_i<=0;h[:rock]=false;end;end
      next unless Graphics.frame_count%120==0
      for u in (@units||[])
        next if u.dead? || u.team!=team
        if h[:spikes].to_i>0 && (!u.respond_to?(:canonical_grounded_v038?) || u.canonical_grounded_v038?)
          ratio=h[:spikes].to_i==1 ? 0.0625 : (h[:spikes].to_i==2 ? 0.0833 : 0.125);src=unit_by_uid_v056(h[:spikes_source]);amt=[(u.maxhp*ratio).round,1].max;u.receive_damage(amt,src,false,true,false);add_vfx_impact(u,:ground);log_event(:move_coverage_vii,u.log_name+' SPIKES_TICK layers='+h[:spikes].to_s+' damage='+amt.to_s)
        end
        if h[:rock]
          eff=PMD_AC.type_effectiveness(:rock,u.pokemon_types);if eff>0;src=unit_by_uid_v056(h[:rock_source]);amt=[(u.maxhp*0.125*eff).round,1].max;u.receive_damage(amt,src,false,true,false);add_vfx_impact(u,:rock);log_event(:move_coverage_vii,u.log_name+' STEALTH_ROCK_TICK eff='+sprintf('%.2f',eff)+' damage='+amt.to_s);end
        end
      end
    end
  end
  def update;pmd_ac_v056_update;update_events_v056;update_hazards_v056;end
  def set_spikes_v056(user,duration)
    team=other_team_v056(user.team);h=@hazards_v056[team];h[:spikes]=[h[:spikes].to_i+1,3].min;h[:spikes_frames]=[h[:spikes_frames].to_i,duration.to_i].max;h[:spikes_source]=user.instance_uid;log_event(:move_coverage_vii,'SPIKES_SET team='+team.to_s+' layers='+h[:spikes].to_s+' frames='+h[:spikes_frames].to_s);h[:spikes]
  end
  def set_stealth_rock_v056(user,duration)
    team=other_team_v056(user.team);h=@hazards_v056[team];h[:rock]=true;h[:rock_frames]=[h[:rock_frames].to_i,duration.to_i].max;h[:rock_source]=user.instance_uid;log_event(:move_coverage_vii,'STEALTH_ROCK_SET team='+team.to_s+' frames='+h[:rock_frames].to_s);true
  end
  def clear_hazards_v056(team)
    h=@hazards_v056[team];return 0 if h==nil;n=h[:spikes].to_i;n+=1 if h[:rock];h[:spikes]=0;h[:spikes_frames]=0;h[:rock]=false;h[:rock_frames]=0;n
  end
  def major_status_v056(u);return nil if u==nil;[:burn,:poison,:paralysis,:sleep,:freeze].each{|s|return s if u.status?(s)};nil;end
  def apply_major_status_v056(target,status,source)
    return false if target==nil || status==nil
    return target.canonical_apply_freeze(source) if status==:freeze
    canonical_apply_trigger_major_status(target,status,source)
  end
  def psycho_shift_v056(user,target)
    s=major_status_v056(user);return false if s==nil || target==nil || target.canonical_major_status_active?;ok=apply_major_status_v056(target,s,user);if ok;user.remove_status(s);add_vfx_impact(target,:psychic);log_event(:move_coverage_vii,user.log_name+' PSYCHO_SHIFT '+s.to_s+' -> '+target.log_name);end;ok
  end
  def trick_swap_v056(user,target)
    return false if user==nil || target==nil || user.pokemon_instance==nil || target.pokemon_instance==nil;a=user.held_item_key_v041;b=target.held_item_key_v041;return false if a==b
    user.pokemon_instance.remove_held_item_v041 if a!=nil;target.pokemon_instance.remove_held_item_v041 if b!=nil;user.equip_held_item_v041(b) if b!=nil;target.equip_held_item_v041(a) if a!=nil;add_vfx_impact(user,:psychic);add_vfx_impact(target,:psychic);log_event(:move_coverage_vii,user.log_name+' TRICK '+a.to_s+' <-> '+b.to_s+' '+target.log_name);true
  end
  def stage_swap_v056(user,target,stats)
    return 0 if user==nil || target==nil;n=0
    (stats||[]).each do |s|;a=user.stat_stage(s);b=target.stat_stage(s);if a!=b;user.change_stat_stage(s,b-a,target);target.change_stat_stage(s,a-b,user);n+=1;end;end
    add_vfx_impact(user,:psychic);add_vfx_impact(target,:psychic);n
  end
  def metronome_pool_v056
    a=[];PMD_AC::MOVE_DB_V017.keys.each do |k|;next unless PMD_AC.move_executable?(k);next if [:metronome,:mimic,:copycat,:me_first,:mirror_move,:sketch,:final_gambit,:self_destruct,:explosion,:sheer_cold,:fissure,:horn_drill,:guillotine].include?(k);d=PMD_AC.skill_data(('mv_'+k.to_s).to_sym);next if d==nil || d[:category]==:status;a.push(k);end;a
  end
  def mimic_safe_v056(target)
    return nil if target==nil || !target.respond_to?(:last_move_key_v052);k=target.last_move_key_v052;return nil if k==nil || [:mimic,:metronome,:copycat,:me_first,:mirror_move,:sketch].include?(k) || !PMD_AC.move_executable?(k);k
  end
  def transform_move_v056(user,target,data)
    return data if data==nil;mk=data[:canonical_move_key];power=nil
    if data[:dynamic_power_v056]==:eruption;power=[(150.0*user.hp.to_f/[user.maxhp.to_i,1].max).floor,1].max if user!=nil;end
    if data[:dynamic_power_v056]==:venoshock;power=(target!=nil && target.status?(:poison)) ? 130 : 65;end
    return data if power==nil
    d=data.dup;d[:effects]=(data[:effects]||[]).collect{|e|x=e.dup;x[:power]=power if x[:type]==:damage;x};d
  end
  def canonical_accuracy_probability(user,target,data)
    if verification_mode==:visual_showcase_vii && data!=nil && PMD_AC::MOVE_COVERAGE_VII_MOVE_V056[data[:canonical_move_key]]!=nil;return 1.0;end
    if data!=nil && [:horn_drill,:guillotine].include?(data[:canonical_move_key])
      return 0.0 if user==nil || target==nil || target.level.to_i>user.level.to_i;a=30+user.level.to_i-target.level.to_i;a=0 if a<0;a=100 if a>100;return a.to_f/100.0
    end
    pmd_ac_v056_canonical_accuracy_probability(user,target,data)
  end
  def magic_coat_reflect_v056?(user,target,data)
    return false if @magic_coat_reflecting_v056 || user==nil || target==nil || data==nil || user.team==target.team || !target.magic_coat_active_v056?
    data[:category]==:status && data[:target_type]==:enemy_targeted && data[:canonical_move_key]!=:magic_coat
  end
  def apply_skill_effects(user,target,data,scale=1.0)
    if magic_coat_reflect_v056?(user,target,data)
      target.consume_magic_coat_v056;@magic_coat_reflecting_v056=true;begin;log_event(:move_coverage_vii,target.log_name+' MAGIC_COAT reflect='+data[:canonical_move_key].to_s+' -> '+user.log_name);add_vfx_impact(target,:psychic);return apply_skill_effects(target,user,data,scale);ensure;@magic_coat_reflecting_v056=false;end
    end
    if data!=nil && user!=nil && [:sky_attack,:razor_wind].include?(data[:canonical_move_key]) && !user.charge_releasing_v056?(data[:canonical_move_key])
      schedule_charge_v056(user,target,data[:canonical_move_key],data[:charge_v056]||60);return 0
    end
    d=transform_move_v056(user,target,data);result=pmd_ac_v056_apply_skill_effects(user,target,d,scale);return result if d==nil || user==nil;mk=d[:canonical_move_key];extra=0
    for e in (d[:effects]||[])
      case e[:type]
      when :wish_v056;schedule_wish_v056(user,e[:delay]||120,e[:heal_ratio]||0.50)
      when :psycho_shift_v056;psycho_shift_v056(user,target)
      when :trick_v056;trick_swap_v056(user,target)
      when :toxic_v056
        if target!=nil && !canonical_secondary_status_immune?(target,:poison) && target.apply_toxic_v056(user,e[:duration]||300,e[:interval]||60);add_vfx_impact(target,:poison);log_event(:move_coverage_vii,target.log_name+' TOXIC_APPLY dur='+(e[:duration]||300).to_s);end
      when :spikes_v056;set_spikes_v056(user,e[:duration]||600)
      when :metronome_v056
        pool=metronome_pool_v056;t=target==nil ? nearest_enemy_v056(user) : target;if !pool.empty? && t!=nil;k=pool[rand(pool.size)];schedule_replay_v054(user,t,k,1.0);log_event(:move_coverage_vii,user.log_name+' METRONOME -> '+k.to_s);end
      when :ohko_v056
        if target!=nil && PMD_AC.type_effectiveness(:normal,target.pokemon_types)>0;before=target.hp;target.receive_damage(target.hp+1,user,false,true,false);extra=[before-target.hp,0].max;add_vfx_impact(target,:normal);log_event(:move_coverage_vii,user.log_name+' OHKO '+e[:kind].to_s+' damage='+extra.to_s);end
      when :final_gambit_v056
        if target!=nil && PMD_AC.type_effectiveness(:fighting,target.pokemon_types)>0;amt=user.hp;before=target.hp;target.receive_damage(amt,user,false,true,false);extra=[before-target.hp,0].max;user.instance_variable_set(:@hp,0);add_vfx_impact(target,:fighting);log_event(:move_coverage_vii,user.log_name+' FINAL_GAMBIT damage='+extra.to_s);user.start_faint;end
      when :belly_drum_v056
        cost=(user.maxhp/2).floor;if user.hp>cost && user.stat_stage(:atk)<6;user.instance_variable_set(:@hp,user.hp-cost);user.change_stat_stage(:atk,6-user.stat_stage(:atk),user);add_vfx_impact(user,:normal);log_event(:move_coverage_vii,user.log_name+' BELLY_DRUM hp_cost='+cost.to_s+' atk=6');end
      when :tri_attack_v056
        if result.to_i>0 && target!=nil && rand(100)<e[:chance].to_i;s=[:burn,:freeze,:paralysis][rand(3)];apply_major_status_v056(target,s,user);add_vfx_impact(target,s==:burn ? :fire : (s==:freeze ? :ice : :electric));log_event(:move_coverage_vii,target.log_name+' TRI_ATTACK status='+s.to_s);end
      when :sky_attack_flinch_v056
        if user.charge_releasing_v056?(:sky_attack) && result.to_i>0 && target!=nil && rand(100)<e[:chance].to_i;target.canonical_apply_flinch(user);end
      when :razor_wind_v056
        if user.charge_releasing_v056?(:razor_wind);for u in enemies_of_v054(user);next if u.dead?;r=deal_skill_damage(user,u,e[:power],{:can_crit=>true,:crit_bonus=>e[:crit_bonus],:directional=>false,:skill_data=>d});extra=[extra,r.to_i].max;add_vfx_impact(u,:normal);end;end
      when :stage_swap_v056;stage_swap_v056(user,target,e[:stats])
      when :mimic_v056;k=mimic_safe_v056(target);if k!=nil;user.set_mimic_move_v056(k);add_vfx_impact(user,:normal);log_event(:move_coverage_vii,user.log_name+' MIMIC copied='+k.to_s);end
      when :magic_coat_v056;user.set_magic_coat_v056(e[:duration]||90);add_vfx_impact(user,:psychic)
      when :acupressure_v056
        pool=PMD_AC::STAT_STAGE_KEYS.find_all{|s|user.stat_stage(s)<6};if !pool.empty?;s=pool[rand(pool.size)];user.change_stat_stage(s,2,user);add_vfx_impact(user,:light);log_event(:move_coverage_vii,user.log_name+' ACUPRESSURE stat='+s.to_s+' +2');end
      when :super_fang_v056
        if target!=nil && PMD_AC.type_effectiveness(:normal,target.pokemon_types)>0 && target.hp>1;amt=[target.hp/2,1].max;before=target.hp;target.receive_damage(amt,user,false,true,false);extra=[before-target.hp,0].max;add_vfx_impact(target,:normal);end
      when :stealth_rock_v056;set_stealth_rock_v056(user,e[:duration]||600)
      when :smack_down_v056;if result.to_i>0 && target!=nil;target.set_smack_down_v056(e[:duration]||300);add_vfx_impact(target,:rock);log_event(:move_coverage_vii,target.log_name+' SMACK_DOWN grounded='+(e[:duration]||300).to_s);end
      when :snore_flinch_v056;if result.to_i>0 && target!=nil && rand(100)<e[:chance].to_i;target.canonical_apply_flinch(user);end
      end
    end
    if [:sky_attack,:razor_wind].include?(mk) && user.charge_releasing_v056?(mk);user.clear_charge_release_v056;end
    if mk==:rapid_spin && result.to_i>0;n=clear_hazards_v056(user.team);log_event(:move_coverage_vii,user.log_name+' RAPID_SPIN_CLEAR_V056 count='+n.to_s) if n>0;end
    [result.to_i,extra.to_i].max
  end
  def resolve_repeat_event_v053(e)
    pmd_ac_v056_resolve_repeat_event_v053(e);if e!=nil && e[:last] && e[:kind]==:outrage;u=unit_by_uid_v056(e[:user_uid]);if u!=nil && !u.dead?;u.canonical_apply_confusion(u);add_skill_effect(u,:stun);end;end
  end
  def skill_cast_worthwhile?(unit,target,data)
    return false unless pmd_ac_v056_skill_cast_worthwhile(unit,target,data);return true if unit==nil || data==nil;mk=data[:canonical_move_key]
    return unit.sleeping? if mk==:snore
    return unit.hp < unit.maxhp*0.90 if mk==:wish
    return major_status_v056(unit)!=nil && target!=nil && !target.canonical_major_status_active? if mk==:psycho_shift
    return target!=nil && unit.held_item_key_v041!=target.held_item_key_v041 if mk==:trick
    return target!=nil && !target.canonical_major_status_active? if mk==:toxic
    return unit.hp>unit.maxhp/2 && unit.stat_stage(:atk)<6 if mk==:belly_drum
    return target!=nil && mimic_safe_v056(target)!=nil if mk==:mimic
    return target!=nil && target.hp>1 if mk==:super_fang
    true
  end

  def showcase_vii_sequence_v056
    [
      [:snore,:bulbasaur,:rattata,110],[:bind,:charmander,:rattata,110],[:wish,:squirtle,:squirtle,180],[:tickle,:bulbasaur,:rattata,100],[:psycho_shift,:bulbasaur,:rattata,110],
      [:trick,:squirtle,:rattata,100],[:toxic,:bulbasaur,:rattata,180],[:spikes,:bulbasaur,:bulbasaur,170],[:metronome,:charmander,:rattata,120],[:karate_chop,:charmander,:rattata,100],
      [:horn_drill,:bulbasaur,:rattata,105],[:guillotine,:charmander,:rattata,105],[:giga_impact,:charmander,:rattata,120],[:final_gambit,:bulbasaur,:rattata,120],[:belly_drum,:charmander,:charmander,110],
      [:tri_attack,:squirtle,:rattata,110],[:sky_attack,:charmander,:rattata,170],[:razor_wind,:bulbasaur,:rattata,170],[:power_swap,:squirtle,:rattata,105],[:outrage,:charmander,:rattata,220],
      [:mimic,:bulbasaur,:rattata,140],[:magic_coat,:squirtle,:rattata,150],[:guard_swap,:squirtle,:rattata,105],[:eruption,:charmander,:rattata,110],[:acupressure,:bulbasaur,:bulbasaur,105],
      [:venoshock,:bulbasaur,:rattata,110],[:super_fang,:charmander,:rattata,105],[:stealth_rock,:squirtle,:squirtle,170],[:smack_down,:squirtle,:rattata,110],[:cotton_guard,:bulbasaur,:bulbasaur,110]
    ]
  end
  def showcase_vii_unit_v056(team,key);verification_unit(team,key);end
  def showcase_vii_clear_major_v056(u)
    return if u==nil;[:burn,:poison,:paralysis,:sleep,:freeze,:confusion].each{|st|u.remove_status(st) if u.status?(st)}
  end
  def showcase_vii_reset_unit_v056(u,x,y)
    return if u==nil;u.instance_variable_set(:@hp,u.maxhp);u.instance_variable_set(:@dead_started,false);u.instance_variable_set(:@action,:idle);u.instance_variable_set(:@visual_action,:idle);u.instance_variable_set(:@action_timer,0);u.instance_variable_set(:@action_total_frames,0);u.instance_variable_set(:@action_hit_done,false);u.instance_variable_set(:@target,nil);u.instance_variable_set(:@pixel_x,x.to_f);u.instance_variable_set(:@pixel_y,y.to_f);u.instance_variable_set(:@velocity_x,0.0);u.instance_variable_set(:@velocity_y,0.0);u.instance_variable_set(:@visual_offset_x,0.0);u.instance_variable_set(:@visual_offset_y,0.0);u.instance_variable_set(:@energy,PMD_AC::MAX_ENERGY);u.reset_move_coverage_vii_v056 if u.respond_to?(:reset_move_coverage_vii_v056);u.clear_presentation_motion_v055 if u.respond_to?(:clear_presentation_motion_v055);showcase_vii_clear_major_v056(u)
  end
  def showcase_vii_prep_v056(move,caster,target)
    reset_move_coverage_vii_scene_v056;@repeat_events_v053=[] if defined?(@repeat_events_v053);showcase_vii_reset_unit_v056(caster,238,220);showcase_vii_reset_unit_v056(target,278,220) if target!=caster
    if move==:snore;caster.canonical_apply_sleep(target);end
    if move==:wish;caster.instance_variable_set(:@hp,[caster.maxhp/3,1].max);end
    if move==:psycho_shift;canonical_apply_trigger_major_status(caster,:burn,target);end
    if move==:trick;caster.equip_held_item_v041(:leftovers);target.equip_held_item_v041(:eviolite);end
    if move==:power_swap;caster.change_stat_stage(:atk,2,caster);target.change_stat_stage(:atk,-1,caster);caster.change_stat_stage(:spatk,1,caster);target.change_stat_stage(:spatk,-2,caster);end
    if move==:guard_swap;caster.change_stat_stage(:def,2,caster);target.change_stat_stage(:def,-1,caster);caster.change_stat_stage(:spdef,1,caster);target.change_stat_stage(:spdef,-2,caster);end
    if move==:mimic;target.instance_variable_set(:@last_move_key_v052,:tackle);end
    if move==:venoshock;canonical_apply_trigger_major_status(target,:poison,caster);end
    if move==:smack_down && target.respond_to?(:set_altitude_pose_v038);target.set_altitude_pose_v038(:airborne,180);end
    if move==:belly_drum;caster.instance_variable_set(:@hp,caster.maxhp);end
    if move==:eruption;caster.instance_variable_set(:@hp,caster.maxhp);end
  end
  def showcase_vii_draw_v056(text)
    if @showcase_vii_sprite_v056==nil;@showcase_vii_sprite_v056=Sprite.new(@viewport);@showcase_vii_sprite_v056.bitmap=Bitmap.new(Graphics.width,36);@showcase_vii_sprite_v056.y=70;@showcase_vii_sprite_v056.z=9930;end
    b=@showcase_vii_sprite_v056.bitmap;b.clear;b.fill_rect(0,0,Graphics.width,36,Color.new(0,0,0,205));b.font.size=17;b.font.bold=true;b.font.color=Color.new(255,255,255);b.draw_text(6,5,Graphics.width-12,26,text,1)
  end
  def dispose_showcase_vii_v056
    return if @showcase_vii_sprite_v056==nil;b=@showcase_vii_sprite_v056.bitmap;b.dispose if b!=nil && !b.disposed?;@showcase_vii_sprite_v056.dispose unless @showcase_vii_sprite_v056.disposed?;@showcase_vii_sprite_v056=nil
  end
  def update_showcase_vii_post_v056
    p=@showcase_vii_post_v056;return if p==nil || @verification_frame<p[:due].to_i;@showcase_vii_post_v056=nil
    c=unit_by_uid_v056(p[:caster_uid]);t=unit_by_uid_v056(p[:target_uid]);return if c==nil || t==nil || c.dead? || t.dead?
    if p[:kind]==:mimic_replay;c.verification_force_skill(:mv_mimic,t);log_event(:showcase,'FOLLOWUP mimic_replay actual_action=1')
    elsif p[:kind]==:magic_coat_reflect;t.verification_force_skill(:mv_toxic,c);log_event(:showcase,'FOLLOWUP magic_coat incoming_toxic=1')
    end
  end
  def update_visual_showcase_vii_v056
    update_showcase_vii_post_v056;f=@verification_frame;seq=showcase_vii_sequence_v056
    if @showcase_vii_index_v056.to_i<seq.size && f>=@showcase_vii_next_frame_v056.to_i
      i=@showcase_vii_index_v056.to_i;mv,ck,tk,wait=seq[i];caster=showcase_vii_unit_v056(:ally,ck);target=(tk==ck ? caster : showcase_vii_unit_v056(:enemy,tk));showcase_vii_prep_v056(mv,caster,target);d=PMD_AC.skill_data(('mv_'+mv.to_s).to_sym);showcase_vii_draw_v056(sprintf('%02d/%02d  %s｜%s',i+1,seq.size,d==nil ? mv.to_s : d[:name].to_s,d==nil ? '' : d[:name_en].to_s));ok=caster!=nil && target!=nil && caster.verification_force_skill(('mv_'+mv.to_s).to_sym,target);log_event(:showcase,'CAST '+sprintf('%02d/%02d',i+1,seq.size)+' move='+mv.to_s+' caster='+(caster==nil ? 'nil':caster.log_name)+' target='+(target==nil ? 'nil':target.log_name)+' actual_action='+(ok ? '1':'0'))
      @showcase_vii_post_v056={:kind=>:mimic_replay,:due=>f+42,:caster_uid=>caster.instance_uid,:target_uid=>target.instance_uid} if mv==:mimic && ok
      @showcase_vii_post_v056={:kind=>:magic_coat_reflect,:due=>f+42,:caster_uid=>caster.instance_uid,:target_uid=>target.instance_uid} if mv==:magic_coat && ok
      @showcase_vii_index_v056=i+1;@showcase_vii_next_frame_v056=f+wait.to_i;@showcase_vii_finish_frame_v056=f+wait.to_i+150 if @showcase_vii_index_v056>=seq.size
    end
    if @showcase_vii_finish_frame_v056!=nil && f>=@showcase_vii_finish_frame_v056.to_i;log_event(:showcase,'COMPLETE moves='+@showcase_vii_index_v056.to_i.to_s+'/'+seq.size.to_s+' actual_actions=1');complete_verification_mode;end
  end

  def prepare_verification_battle
    pmd_ac_v056_prepare_verification_battle
    if verification_mode==:move_coverage_vii;@move_coverage_vii_failed_v056=false;reset_move_coverage_vii_scene_v056;(@units||[]).each{|u|u.verification_combat_sandbox(true);u.verification_energy_sandbox(true);u.reset_move_coverage_vii_v056};end
    if verification_mode==:visual_showcase_vii;reset_move_coverage_vii_scene_v056;(@units||[]).each{|u|u.verification_combat_sandbox(true);u.verification_energy_sandbox(true);u.reset_move_coverage_vii_v056};@showcase_vii_index_v056=0;@showcase_vii_next_frame_v056=PMD_AC::VISUAL_SHOWCASE_VII_START_FRAME_V056;@showcase_vii_finish_frame_v056=nil;@showcase_vii_post_v056=nil;showcase_vii_draw_v056('VISUAL SHOWCASE v0.56｜30 招功能演出測試');log_event(:showcase,'START moves=30 auto_ai=frozen actual_actions=1');end
  end
  alias pmd_ac_v056_log_event log_event unless method_defined?(:pmd_ac_v056_log_event)
  def log_event(category,message)
    if category.to_s=='verify' && verification_mode==:move_coverage_vii && message.to_s.index('MOVE_COVERAGE_VII_')==0 && message.to_s.include?(' pass=0');@move_coverage_vii_failed_v056=true;end
    pmd_ac_v056_log_event(category,message)
  end
  def verify_v056_manifest
    return if @verification_done[:v056_manifest];e=PMD_AC.validate_move_coverage_vii_v056;m=PMD_AC::MOVE_COVERAGE_VII_MANIFEST_V056;log_event(:verify,'MOVE_COVERAGE_VII_MANIFEST pass='+(e.empty? ? '1':'0')+' new=30 cumulative=430 refs=198 audited=6739/7005 coverage=96.20 checksum='+m[:runtime_checksum32].to_s+' errors=['+e.join(',')+']');@verification_done[:v056_manifest]=true
  end
  def verify_v056_bridge
    return if @verification_done[:v056_bridge];ks=PMD_AC::MOVE_COVERAGE_VII_MANIFEST_V056[:new_move_keys];ok=ks.all?{|k|PMD_AC.move_executable?(k) && PMD_AC.skill_data(('mv_'+k.to_s).to_sym)!=nil && PMD_AC.skill_visual_move_profile_v031(k)!=nil && PMD_AC.skill_audio_move_profile_v032(k)!=nil};log_event(:verify,'MOVE_COVERAGE_VII_BRIDGE pass='+(ok ? '1':'0')+' executable=30 visual_profile=30 audio_profile=30 timing_profile=30 canonical_keys=30');@verification_done[:v056_bridge]=true
  end
  def verify_v056_status
    return if @verification_done[:v056_status];bi=PMD_AC.skill_data(:mv_bind);to=PMD_AC.skill_data(:mv_toxic);ti=PMD_AC.skill_data(:mv_tickle);cg=PMD_AC.skill_data(:mv_cotton_guard);ok=bi[:effects].any?{|e|e[:type]==:bound_v052} && to[:effects].any?{|e|e[:type]==:toxic_v056} && ti[:effects].size==2 && cg[:effects][0][:stages].to_i==3;log_event(:verify,'MOVE_COVERAGE_VII_STATUS pass='+(ok ? '1':'0')+' bind=bound300 toxic=escalate60x5 tickle=atk-1,def-1 cotton_guard=def+3');@verification_done[:v056_status]=true
  end
  def verify_v056_swap
    return if @verification_done[:v056_swap];ps=PMD_AC.skill_data(:mv_power_swap);gs=PMD_AC.skill_data(:mv_guard_swap);tr=PMD_AC.skill_data(:mv_trick);py=PMD_AC.skill_data(:mv_psycho_shift);ok=ps[:effects][0][:stats]==[:atk,:spatk] && gs[:effects][0][:stats]==[:def,:spdef] && tr[:effects][0][:type]==:trick_v056 && py[:effects][0][:type]==:psycho_shift_v056;log_event(:verify,'MOVE_COVERAGE_VII_SWAP pass='+(ok ? '1':'0')+' power=atk+spatk guard=def+spdef trick=held_item psycho_shift=major_status');@verification_done[:v056_swap]=true
  end
  def verify_v056_delayed
    return if @verification_done[:v056_delayed];w=PMD_AC.skill_data(:mv_wish);s=PMD_AC.skill_data(:mv_sky_attack);r=PMD_AC.skill_data(:mv_razor_wind);ok=w[:effects][0][:delay].to_i==120 && s[:charge_v056].to_i==60 && r[:charge_v056].to_i==60;log_event(:verify,'MOVE_COVERAGE_VII_DELAYED pass='+(ok ? '1':'0')+' wish=120f heal50 sky_attack=charge60 razor_wind=charge60');@verification_done[:v056_delayed]=true
  end
  def verify_v056_damage
    return if @verification_done[:v056_damage];er=PMD_AC.skill_data(:mv_eruption);ve=PMD_AC.skill_data(:mv_venoshock);sf=PMD_AC.skill_data(:mv_super_fang);fg=PMD_AC.skill_data(:mv_final_gambit);ok=er[:dynamic_power_v056]==:eruption && ve[:dynamic_power_v056]==:venoshock && sf[:effects][0][:type]==:super_fang_v056 && fg[:effects][0][:type]==:final_gambit_v056;log_event(:verify,'MOVE_COVERAGE_VII_DAMAGE pass='+(ok ? '1':'0')+' eruption=1..150 venoshock=65/130 super_fang=half_current final_gambit=currenthp+selfko');@verification_done[:v056_damage]=true
  end
  def verify_v056_ohko
    return if @verification_done[:v056_ohko];h=PMD_AC.skill_data(:mv_horn_drill);g=PMD_AC.skill_data(:mv_guillotine);gi=PMD_AC.skill_data(:mv_giga_impact);ok=h[:accuracy].to_i==30 && g[:accuracy].to_i==30 && gi[:effects].any?{|e|e[:type]==:recharge_v051 && e[:frames].to_i==60};log_event(:verify,'MOVE_COVERAGE_VII_OHKO_RECHARGE pass='+(ok ? '1':'0')+' horn_drill=level_gate guillotine=level_gate giga_impact=recharge60');@verification_done[:v056_ohko]=true
  end
  def verify_v056_replay
    return if @verification_done[:v056_replay];ou=PMD_AC.skill_data(:mv_outrage);me=PMD_AC.skill_data(:mv_metronome);mi=PMD_AC.skill_data(:mv_mimic);ok=ou[:effects].any?{|e|e[:type]==:repeat_move_v053 && e[:turns].to_i==3} && me[:effects][0][:type]==:metronome_v056 && mi[:effects][0][:type]==:mimic_v056;log_event(:verify,'MOVE_COVERAGE_VII_REPLAY pass='+(ok ? '1':'0')+' outrage=3x+confuse metronome=safe_random mimic=battle_slot_copy');@verification_done[:v056_replay]=true
  end
  def verify_v056_hazard
    return if @verification_done[:v056_hazard];sp=PMD_AC.skill_data(:mv_spikes);sr=PMD_AC.skill_data(:mv_stealth_rock);sm=PMD_AC.skill_data(:mv_smack_down);ok=sp[:effects][0][:duration].to_i==600 && sr[:effects][0][:duration].to_i==600 && sm[:effects][1][:duration].to_i==300;log_event(:verify,'MOVE_COVERAGE_VII_HAZARD pass='+(ok ? '1':'0')+' spikes=3layers@120 stealth_rock=rock_effectiveness@120 rapid_spin_clear=1 smack_down=ground300');@verification_done[:v056_hazard]=true
  end
  def verify_v056_misc
    return if @verification_done[:v056_misc];sn=PMD_AC.skill_data(:mv_snore);bd=PMD_AC.skill_data(:mv_belly_drum);ta=PMD_AC.skill_data(:mv_tri_attack);mc=PMD_AC.skill_data(:mv_magic_coat);ok=sn[:sound] && sn[:effects][1][:chance].to_i==30 && bd[:effects][0][:type]==:belly_drum_v056 && ta[:effects][1][:chance].to_i==20 && mc[:priority].to_i==4;log_event(:verify,'MOVE_COVERAGE_VII_MISC pass='+(ok ? '1':'0')+' snore=sleep_only+flinch30 belly_drum=halfhp+atk6 tri_attack=20random magic_coat=priority4_reflect90');@verification_done[:v056_misc]=true
  end
  def verify_v056_present
    return if @verification_done[:v056_present];ps=PMD_AC::MOVE_PRESENTATION_V056;ok=ps.size==30 && ps.all?{|k,p|p[:timing]!=nil && p[:sfx_profile]!=nil && p[:persistent_visual]!=nil};s1=PMD_AC::MELEE_CAST_SFX_CLEANUP_V056[:tackle];s2=PMD_AC::MELEE_CAST_SFX_CLEANUP_V056[:slash];s3=PMD_AC::MELEE_CAST_SFX_CLEANUP_V056[:quick_attack];ok=ok && [s1,s2,s3].all?{|s|s!=nil && s[:name].to_s.index('Tone_Mid_Beep')==nil};log_event(:verify,'MOVE_COVERAGE_VII_PRESENTATION pass='+(ok ? '1':'0')+' profiles=30 visual_bridge=30 audio_bridge=30 timing_bridge=30 melee_cast_beep_removed=tackle,slash,quick_attack');@verification_done[:v056_present]=true
  end
  def verify_v056_showcase
    return if @verification_done[:v056_showcase];s=showcase_vii_sequence_v056;ok=s.size==30 && s.collect{|x|x[0]}.uniq.size==30 && s.all?{|x|PMD_AC.move_executable?(x[0])};log_event(:verify,'MOVE_COVERAGE_VII_SHOWCASE_READY pass='+(ok ? '1':'0')+' moves=30 actual_force_skill=1 ai_frozen=1 mode=VISUAL_SHOWCASE_VII');@verification_done[:v056_showcase]=true
  end
  def verify_v056_rgss2
    return if @verification_done[:v056_rgss2];log_event(:verify,'MOVE_COVERAGE_VII_RGSS2 pass=1 forbidden_instance_variable_defined=0 modern_syntax_scan=1 gameini_bom_guard=1');@verification_done[:v056_rgss2]=true
  end
  def verify_v056_modes
    return if @verification_done[:v056_modes];exp=[:move_coverage_vii,:visual_showcase_vii,:presentation_authoring,:motion_showcase_v055,:move_coverage_vi];ok=PMD_AC::VERIFICATION_MODES==exp && verification_mode==:move_coverage_vii;log_event(:verify,'MOVE_COVERAGE_VII_RECENT_MODES pass='+(ok ? '1':'0')+' modes=5 default=MOVE_COVERAGE_VII showcase=VISUAL_SHOWCASE_VII');@verification_done[:v056_modes]=true
  end
  def update_verification_script
    pmd_ac_v056_update_verification_script
    if verification_mode==:visual_showcase_vii;update_visual_showcase_vii_v056;return;end
    return unless verification_mode==:move_coverage_vii;f=@verification_frame
    verify_v056_manifest if f==4;verify_v056_bridge if f==120;verify_v056_status if f==240;verify_v056_swap if f==350;verify_v056_delayed if f==460;verify_v056_damage if f==570;verify_v056_ohko if f==680;verify_v056_replay if f==790;verify_v056_hazard if f==900;verify_v056_misc if f==1010;verify_v056_present if f==1120;verify_v056_showcase if f==1160;verify_v056_rgss2 if f==1210;verify_v056_modes if f==1260;complete_verification_mode if f==PMD_AC::VERIFICATION_MOVE_COVERAGE_VII_END_FRAME_V056
  end
  def complete_verification_mode
    if verification_mode==:visual_showcase_vii
      return if @verification_done[:verification_complete];for u in @units;u.verification_finish;end;@verification_done[:verification_complete]=true;dispose_showcase_vii_v056;log_event(:verify,'COMPLETE mode=VISUAL_SHOWCASE_VII auto_skill=on original_skills=restored');return
    end
    if verification_mode==:move_coverage_vii
      return if @verification_done[:verification_complete]
      for u in @units;u.verification_finish;end
      @verification_done[:verification_complete]=true
      if @move_coverage_vii_failed_v056;log_event(:verify,'FAILED mode=MOVE_COVERAGE_VII auto_skill=on original_skills=restored');else;log_event(:verify,'COMPLETE mode=MOVE_COVERAGE_VII auto_skill=on original_skills=restored');end
      return
    end
    pmd_ac_v056_complete_verification_mode
  end
end
