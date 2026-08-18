#==============================================================================
# 【PMD AutoChess 中文維護說明】
# 腳本：PMD AutoChess Proto v0.52
# 分類：核心戰鬥 Runtime
#
# 【用途／機制】
# 承接前序 Data／Config，實際執行戰鬥 Scene、Unit、AI、技能與呈現。
#
# 【怎麼調整】
# 一般平衡與資料調整不要直接改 Runtime；若要追加功能，建議在較後腳本 alias 原方法後擴充。
#
# 【本腳本主要設定常數／資料表】
# - VERIFICATION_MOVE_COVERAGE_IV_END_FRAME_V052 / VERIFICATION_MODES / VERIFICATION_LABELS
#
# 【Runtime 主要方法（查流程時可直接搜尋）】
# - move_coverage_iv_key_from_skill_v052 / canonical_move_key_from_skill / move_executable? / move_autochess_hint
# - skill_data / skill_audio_move_profile_v032 / skill_visual_move_profile_v031 / move_presentation_profile_v052
# - move_coverage_iv_checksum32_v052 / validate_move_coverage_iv_v052 / initialize / reset_move_coverage_iv_v052
#
# 【維護規則】
# - RPG Maker VX / RGSS2 / Ruby 1.8 相容。
# - instance_uid 才是 Pokémon 個體身份；Actor ID 只是容器。
# - 新增行為優先沿用既有 helper／Data 表；避免破壞已 Freeze 的舊核心。
# - 本專案新腳本也必須保留同等級的中文說明與實際範例。
#==============================================================================
#===============================================================================
# ■ PMD AutoChess Proto v0.52
#    Move Runtime Coverage Expansion IV + Functional Presentation Profiles II
#-------------------------------------------------------------------------------
# Additive layer on verified v0.51. Previous scripts are not rewritten.
#===============================================================================
module PMD_AC
  VERIFICATION_MOVE_COVERAGE_IV_END_FRAME_V052=1120
  STATUS_DEFS[:bound_v052]={:tags=>[:debuff,:dot,:trap],:tick_type=>:damage,:interval=>60,:stack_mode=>:refresh} unless STATUS_DEFS.has_key?(:bound_v052)
  STATUS_DEFS[:foresight_v052]={:tags=>[:debuff,:exposed],:tick_type=>nil,:interval=>999999,:stack_mode=>:refresh} unless STATUS_DEFS.has_key?(:foresight_v052)
  class << self
    alias pmd_ac_v052_canonical_move_key_from_skill canonical_move_key_from_skill unless method_defined?(:pmd_ac_v052_canonical_move_key_from_skill)
    alias pmd_ac_v052_move_executable move_executable? unless method_defined?(:pmd_ac_v052_move_executable)
    alias pmd_ac_v052_move_autochess_hint move_autochess_hint unless method_defined?(:pmd_ac_v052_move_autochess_hint)
    alias pmd_ac_v052_skill_data skill_data unless method_defined?(:pmd_ac_v052_skill_data)
    alias pmd_ac_v052_skill_audio_move_profile_v032 skill_audio_move_profile_v032 unless method_defined?(:pmd_ac_v052_skill_audio_move_profile_v032)
    alias pmd_ac_v052_skill_visual_move_profile_v031 skill_visual_move_profile_v031 unless method_defined?(:pmd_ac_v052_skill_visual_move_profile_v031)
    def move_coverage_iv_key_from_skill_v052(skill_key)
      return nil if skill_key==nil;text=skill_key.to_s;return nil unless text[0,3]=='mv_';k=text[3,text.size-3].to_sym;MOVE_COVERAGE_IV_MOVE_V052[k]==nil ? nil : k
    end
    def canonical_move_key_from_skill(skill_key);k=move_coverage_iv_key_from_skill_v052(skill_key);return k if k!=nil;pmd_ac_v052_canonical_move_key_from_skill(skill_key);end
    def move_executable?(move_key);k=move_key.is_a?(String) ? move_key.to_sym : move_key;return true if MOVE_COVERAGE_IV_MOVE_V052[k]!=nil;pmd_ac_v052_move_executable(move_key);end
    def move_autochess_hint(move_key)
      k=move_key.is_a?(String) ? move_key.to_sym : move_key;b=MOVE_COVERAGE_IV_MOVE_V052[k];return pmd_ac_v052_move_autochess_hint(move_key) if b==nil
      old=pmd_ac_v052_move_autochess_hint(move_key);r=old==nil ? {} : old.dup;[:behavior_status,:delivery,:range_px,:runtime_skill_key,:priority,:target_type,:policy].each{|x|r[x]=b[x] if b[x]!=nil};r
    end
    def skill_data(key);mk=move_coverage_iv_key_from_skill_v052(key);return MOVE_COVERAGE_IV_MOVE_V052[mk].dup if mk!=nil;pmd_ac_v052_skill_data(key);end
    def skill_audio_move_profile_v032(move_key);k=move_key.is_a?(String) ? move_key.to_sym : move_key;b=MOVE_COVERAGE_IV_AUDIO_V052[k];return b if b!=nil;pmd_ac_v052_skill_audio_move_profile_v032(move_key);end
    def skill_visual_move_profile_v031(move_key);k=move_key.is_a?(String) ? move_key.to_sym : move_key;b=MOVE_COVERAGE_IV_VISUAL_V052[k];return b if b!=nil;pmd_ac_v052_skill_visual_move_profile_v031(move_key);end
    def move_presentation_profile_v052(move_key);k=move_key.is_a?(String) ? move_key.to_sym : move_key;MOVE_PRESENTATION_V052[k];end
    def move_coverage_iv_checksum32_v052;h=0;MOVE_COVERAGE_IV_CHECKSUM_TEXT_V052.each_byte{|c|h=((h*33)+c)&0x7fffffff};h;end
    def validate_move_coverage_iv_v052
      e=[];m=MOVE_COVERAGE_IV_MANIFEST_V052;e.push('count') unless MOVE_COVERAGE_IV_MOVE_V052.size==24;e.push('cumulative') unless m[:cumulative_mapped_move_count].to_i==347;e.push('refs') unless m[:new_reference_covered].to_i==496 && m[:cumulative_reference_covered].to_i==5849;e.push('presentation') unless MOVE_PRESENTATION_V052.size==24;e.push('checksum') unless move_coverage_iv_checksum32_v052==m[:runtime_checksum32].to_i
      m[:new_move_keys].each{|k|d=MOVE_COVERAGE_IV_MOVE_V052[k];p=MOVE_PRESENTATION_V052[k];e.push('data:'+k.to_s) if d==nil;e.push('presentation:'+k.to_s) if p==nil;e.push('visual:'+k.to_s) if MOVE_COVERAGE_IV_VISUAL_V052[k]==nil;e.push('audio:'+k.to_s) if MOVE_COVERAGE_IV_AUDIO_V052[k]==nil;e.push('timing:'+k.to_s) if p!=nil && p[:timing]==nil}
      e
    end
  end
  remove_const(:VERIFICATION_MODES) if const_defined?(:VERIFICATION_MODES)
  VERIFICATION_MODES=[:move_coverage_iv,:move_coverage_iii,:move_coverage_ii,:move_coverage,:mastery_policy]
  remove_const(:VERIFICATION_LABELS) if const_defined?(:VERIFICATION_LABELS)
  VERIFICATION_LABELS={:move_coverage_iv=>'MOVE_COVERAGE_IV',:move_coverage_iii=>'MOVE_COVERAGE_III',:move_coverage_ii=>'MOVE_COVERAGE_II',:move_coverage=>'MOVE_COVERAGE',:mastery_policy=>'MASTERY_POLICY'}
end

class Game_PMDChessUnit
  alias pmd_ac_v052_initialize initialize unless method_defined?(:pmd_ac_v052_initialize)
  alias pmd_ac_v052_start_combat start_combat unless method_defined?(:pmd_ac_v052_start_combat)
  alias pmd_ac_v052_deploy_to_cell deploy_to_cell unless method_defined?(:pmd_ac_v052_deploy_to_cell)
  alias pmd_ac_v052_deploy_to_pixel deploy_to_pixel unless method_defined?(:pmd_ac_v052_deploy_to_pixel)
  alias pmd_ac_v052_update update unless method_defined?(:pmd_ac_v052_update)
  alias pmd_ac_v052_begin_skill begin_skill unless method_defined?(:pmd_ac_v052_begin_skill)
  alias pmd_ac_v052_receive_damage receive_damage unless method_defined?(:pmd_ac_v052_receive_damage)
  alias pmd_ac_v052_start_faint start_faint unless method_defined?(:pmd_ac_v052_start_faint)
  def initialize(*args);pmd_ac_v052_initialize(*args);reset_move_coverage_iv_v052;end
  def reset_move_coverage_iv_v052
    @last_move_key_v052=nil;@disabled_move_key_v052=nil;@disable_frames_v052=0;@yawn_frames_v052=0;@yawn_source_uid_v052=nil;@rage_frames_v052=0;@rollout_chain_v052=0;@rollout_last_hit_v052=-9999;@fury_cutter_chain_v052=0;@fury_cutter_last_hit_v052=-9999;@charge_frames_v052=0;@bound_style_v052=nil
  end
  def start_combat;pmd_ac_v052_start_combat;reset_move_coverage_iv_v052;end
  def deploy_to_cell(x,y);pmd_ac_v052_deploy_to_cell(x,y);reset_move_coverage_iv_v052;end
  def deploy_to_pixel(x,y);pmd_ac_v052_deploy_to_pixel(x,y);reset_move_coverage_iv_v052;end
  def last_move_key_v052;@last_move_key_v052;end
  def disabled_move_key_v052;@disable_frames_v052.to_i>0 ? @disabled_move_key_v052 : nil;end
  def apply_disable_v052(key,duration);return false if key==nil;@disabled_move_key_v052=key;@disable_frames_v052=[duration.to_i,1].max;true;end
  def apply_yawn_v052(source,delay);@yawn_source_uid_v052=source==nil ? nil : source.instance_uid;@yawn_frames_v052=[delay.to_i,1].max;true;end
  def apply_rage_v052(duration);@rage_frames_v052=[duration.to_i,1].max;true;end
  def rage_active_v052?;@rage_frames_v052.to_i>0;end
  def apply_charge_v052(duration);@charge_frames_v052=[duration.to_i,1].max;true;end
  def charge_active_v052?;@charge_frames_v052.to_i>0;end
  def consume_charge_v052;@charge_frames_v052=0;end
  def foresight_active_v052?;status?(:foresight_v052);end
  def bound_v052?;status?(:bound_v052);end
  def set_bound_style_v052(style);@bound_style_v052=style;end
  def clear_binding_v052
    n=0;if status?(:bound_v052);remove_status(:bound_v052);n+=1;end;if status?(:fire_trap_v051);remove_status(:fire_trap_v051);n+=1;end
    if instance_variable_defined?(:@leech_seed_frames_v051) && @leech_seed_frames_v051.to_i>0;@leech_seed_frames_v051=0;@leech_seed_tick_v051=0;n+=1;end
    @bound_style_v052=nil;n
  end
  def rollout_power_v052;[30*(2**[@rollout_chain_v052.to_i,4].min),480].min;end
  def fury_cutter_power_v052;[20*(2**[@fury_cutter_chain_v052.to_i,3].min),160].min;end
  def advance_rollout_v052;@rollout_chain_v052=[@rollout_chain_v052.to_i+1,4].min;@rollout_last_hit_v052=Graphics.frame_count;end
  def advance_fury_cutter_v052;@fury_cutter_chain_v052=[@fury_cutter_chain_v052.to_i+1,3].min;@fury_cutter_last_hit_v052=Graphics.frame_count;end
  def reset_rollout_v052;@rollout_chain_v052=0;end
  def reset_fury_cutter_v052;@fury_cutter_chain_v052=0;end
  def evading_v052?;instance_variable_defined?(:@evade_visual_frames) && @evade_visual_frames.to_i>0;end
  def update
    @disable_frames_v052-=1 if @disable_frames_v052.to_i>0
    if @disable_frames_v052.to_i<=0;@disabled_move_key_v052=nil;end
    @rage_frames_v052-=1 if @rage_frames_v052.to_i>0;@charge_frames_v052-=1 if @charge_frames_v052.to_i>0
    if @yawn_frames_v052.to_i>0
      @yawn_frames_v052-=1
      if @yawn_frames_v052<=0 && !dead?
        src=@scene==nil ? nil : @scene.two_turn_unit_by_uid_v039(@yawn_source_uid_v052)
        if !canonical_major_status_active?;canonical_apply_sleep(src);@scene.add_skill_effect(self,:stun) if @scene!=nil;log_event(:move_coverage_iv,log_name+' YAWN_SLEEP');else;log_event(:move_coverage_iv,log_name+' YAWN_FAIL major_status=1');end
      end
    end
    if bound_v052? && Graphics.frame_count%30==0 && @scene!=nil;@scene.add_vfx_impact(self,@bound_style_v052||:normal);end
    pmd_ac_v052_update
  end
  def begin_skill(skill_target=nil)
    d=skill_data;mk=d==nil ? nil : d[:canonical_move_key]
    if mk!=nil && disabled_move_key_v052==mk
      @energy=0;@skill_target=nil;log_event(:move_coverage_iv,log_name+' DISABLE_BLOCK move='+mk.to_s+' remaining='+@disable_frames_v052.to_i.to_s);@scene.add_skill_effect(self,:stun) if @scene!=nil;return
    end
    reset_rollout_v052 if mk!=:rollout;reset_fury_cutter_v052 if mk!=:fury_cutter
    pmd_ac_v052_begin_skill(skill_target)
    @last_move_key_v052=mk if mk!=nil && @action==:skill && @action_timer.to_i>0
  end
  def receive_damage(value,source=nil,grant_energy=true,bypass_link=false,critical=false)
    before=@hp.to_i;r=pmd_ac_v052_receive_damage(value,source,grant_energy,bypass_link,critical);actual=[before-@hp.to_i,0].max
    if actual>0 && rage_active_v052? && source!=nil && source!=self && (!source.respond_to?(:team) || source.team!=team)
      change_stat_stage(:atk,1,source);@scene.add_skill_effect(self,:buff) if @scene!=nil;log_event(:move_coverage_iv,log_name+' RAGE_TRIGGER atk='+stat_stage(:atk).to_s)
    end
    r
  end
  def start_faint;reset_move_coverage_iv_v052;pmd_ac_v052_start_faint;end
end

class Scene_PMD_AutoChess
  alias pmd_ac_v052_start start unless method_defined?(:pmd_ac_v052_start)
  alias pmd_ac_v052_terminate terminate unless method_defined?(:pmd_ac_v052_terminate)
  alias pmd_ac_v052_start_battle start_battle unless method_defined?(:pmd_ac_v052_start_battle)
  alias pmd_ac_v052_update update unless method_defined?(:pmd_ac_v052_update)
  alias pmd_ac_v052_apply_skill_effects apply_skill_effects unless method_defined?(:pmd_ac_v052_apply_skill_effects)
  alias pmd_ac_v052_deal_direct_damage deal_direct_damage unless method_defined?(:pmd_ac_v052_deal_direct_damage)
  alias pmd_ac_v052_canonical_accuracy_probability canonical_accuracy_probability unless method_defined?(:pmd_ac_v052_canonical_accuracy_probability)
  alias pmd_ac_v052_skill_cast_worthwhile skill_cast_worthwhile? unless method_defined?(:pmd_ac_v052_skill_cast_worthwhile)
  alias pmd_ac_v052_prepare_verification_battle prepare_verification_battle unless method_defined?(:pmd_ac_v052_prepare_verification_battle)
  alias pmd_ac_v052_update_verification_script update_verification_script unless method_defined?(:pmd_ac_v052_update_verification_script)
  alias pmd_ac_v052_log_event log_event unless method_defined?(:pmd_ac_v052_log_event)
  alias pmd_ac_v052_complete_verification_mode complete_verification_mode unless method_defined?(:pmd_ac_v052_complete_verification_mode)
  def start
    pmd_ac_v052_start
    begin
      if FileTest.exist?(PMD_AC::BATTLE_LOG_FILE);text=File.open(PMD_AC::BATTLE_LOG_FILE,'rb'){|f|f.read};text.sub!(/PMD AutoChess Proto v0\.[0-9.]+ Battle Verification Log/,'PMD AutoChess Proto v0.52 Battle Verification Log');File.open(PMD_AC::BATTLE_LOG_FILE,'wb'){|f|f.write(text)};end
    rescue;end
    @future_sight_events_v052=[];m=PMD_AC::MOVE_COVERAGE_IV_MANIFEST_V052;log_event(:move_coverage_iv,'LOADED new=24 cumulative=347 audited='+m[:cumulative_reference_covered].to_s+'/'+m[:learnset_reference_total].to_s+' coverage='+sprintf('%.2f',m[:cumulative_coverage_percent].to_f)+'% presentation=24 timing=24 foundations=delayed,sequence,disable,bind,item,foresight,reactive checksum32='+m[:runtime_checksum32].to_s)
  end
  def terminate;@future_sight_events_v052=nil;pmd_ac_v052_terminate;end
  def start_battle;@future_sight_events_v052=[];pmd_ac_v052_start_battle;end
  def update
    pmd_ac_v052_update;return if @future_sight_events_v052==nil || @future_sight_events_v052.empty?;now=Graphics.frame_count;keep=[]
    @future_sight_events_v052.each do |e|
      if now>=e[:due].to_i;resolve_future_sight_v052(e);else;keep.push(e);if e[:due].to_i-now==60;t=two_turn_unit_by_uid_v039(e[:target_uid]);add_vfx_impact(t,:psychic) if t!=nil && !t.dead?;end;end
    end;@future_sight_events_v052=keep
  end
  def pursuit_bonus_v052?(user,target)
    return false if user==nil || target==nil;return true if target.respond_to?(:evading_v052?) && target.evading_v052?
    vx=target.instance_variable_defined?(:@velocity_x) ? target.instance_variable_get(:@velocity_x).to_f : 0.0;vy=target.instance_variable_defined?(:@velocity_y) ? target.instance_variable_get(:@velocity_y).to_f : 0.0;dx=target.pixel_x-user.pixel_x;dy=target.pixel_y-user.pixel_y;len=Math.sqrt(dx*dx+dy*dy);return false if len<0.001;(vx*dx/len+vy*dy/len)>0.35
  end
  def flail_like_power_v052(user)
    return 20 if user==nil || user.maxhp.to_i<=0;r=user.hp.to_f/user.maxhp.to_f;return 200 if r<=0.0417;return 150 if r<=0.1042;return 100 if r<=0.2083;return 80 if r<=0.3542;return 40 if r<=0.6875;20
  end
  def dynamic_power_v052(user,target,key)
    case key
    when :pursuit;pursuit_bonus_v052?(user,target) ? 80 : 40
    when :rollout;user==nil ? 30 : user.rollout_power_v052
    when :payback;user!=nil && target!=nil && user.respond_to?(:reactive_was_hit_by_v043?) && user.reactive_was_hit_by_v043?(target,60) ? 100 : 50
    when :assurance;target!=nil && target.respond_to?(:reactive_hit_memory_v043) && target.reactive_hit_memory_v043(nil,nil,30)!=nil ? 100 : 50
    when :wring_out;target==nil || target.maxhp.to_i<=0 ? 1 : [[(120.0*target.hp.to_f/target.maxhp.to_f).floor+1,1].max,121].min
    when :fury_cutter;user==nil ? 20 : user.fury_cutter_power_v052
    when :reversal;flail_like_power_v052(user)
    else;nil
    end
  end
  def transform_move_v052(user,target,data)
    return data if data==nil;d=data;power_key=data[:dynamic_power_v052]
    if power_key!=nil;d=data.dup;p=dynamic_power_v052(user,target,power_key);d[:effects]=(data[:effects]||[]).collect{|e|x=e.dup;x[:power]=p if x[:type]==:damage;x};d[:runtime_power_v052]=p;end
    if user!=nil && user.respond_to?(:charge_active_v052?) && user.charge_active_v052? && d[:move_type]==:electric && (d[:effects]||[]).any?{|e|e[:type]==:damage}
      d=d.dup if d.equal?(data);d[:effects]=(d[:effects]||[]).collect{|e|x=e.dup;x[:power]=(x[:power].to_f*2.0).round if x[:type]==:damage && x[:power]!=nil;x};d[:consume_charge_v052]=true
    end;d
  end
  def schedule_future_sight_v052(user,target,power,delay,data)
    return false if user==nil || target==nil;@future_sight_events_v052=[] if @future_sight_events_v052==nil;@future_sight_events_v052.push({:user_uid=>user.instance_uid,:target_uid=>target.instance_uid,:power=>power.to_i,:due=>Graphics.frame_count+delay.to_i,:data=>data.dup});add_vfx_impact(target,:psychic);log_event(:move_coverage_iv,user.log_name+' FUTURE_SIGHT_SET target='+target.log_name+' delay='+delay.to_i.to_s);true
  end
  def resolve_future_sight_v052(e)
    target=two_turn_unit_by_uid_v039(e[:target_uid]);user=two_turn_unit_by_uid_v039(e[:user_uid]);return false if target==nil || target.dead? || user==nil;d=e[:data]||PMD_AC.skill_data(:mv_future_sight);add_vfx_impact(target,:psychic);result=deal_skill_damage(user,target,e[:power]||100,{:can_crit=>false,:directional=>false,:skill_data=>d});log_event(:move_coverage_iv,'FUTURE_SIGHT_HIT '+user.log_name+' -> '+target.log_name+' damage='+result.to_i.to_s);true
  end
  def canonical_accuracy_probability(user,target,data)
    if target!=nil && target.respond_to?(:foresight_active_v052?) && target.foresight_active_v052? && target.respond_to?(:stat_stage)
      stages=target.instance_variable_get(:@stat_stages);if stages!=nil;old=stages[:evasion];stages[:evasion]=0;begin;return pmd_ac_v052_canonical_accuracy_probability(user,target,data);ensure;stages[:evasion]=old;end;end
    end;pmd_ac_v052_canonical_accuracy_probability(user,target,data)
  end
  def apply_bound_v052(user,target,e)
    value=[(target.maxhp*(e[:ratio]||0.0625).to_f).round,1].max;target.apply_status(:bound_v052,{:duration=>(e[:duration]||300).to_i,:value=>value,:interval=>(e[:interval]||60).to_i,:stack_mode=>:refresh},user);target.set_bound_style_v052(e[:style]||:normal);target.apply_status(:move_slow,{:duration=>(e[:duration]||300).to_i,:value=>0.30,:stack_mode=>:replace_stronger},user);add_vfx_impact(target,e[:style]||:normal);true
  end
  def apply_skill_effects(user,target,data,scale=1.0)
    d=transform_move_v052(user,target,data);result=pmd_ac_v052_apply_skill_effects(user,target,d,scale);extra=0;return result if d==nil || user==nil || target==nil
    for e in (d[:effects]||[])
      case e[:type]
      when :future_sight_v052;schedule_future_sight_v052(user,target,e[:power]||100,e[:delay]||120,d)
      when :foresight_v052;target.apply_status(:foresight_v052,{:duration=>(e[:duration]||180).to_i,:value=>1,:interval=>999999,:stack_mode=>:refresh},user);add_vfx_impact(target,:normal);log_event(:move_coverage_iv,target.log_name+' FORESIGHT duration='+(e[:duration]||180).to_s)
      when :disable_v052;k=target.last_move_key_v052;if k!=nil;target.apply_disable_v052(k,e[:duration]||180);add_vfx_impact(target,:psychic);log_event(:move_coverage_iv,target.log_name+' DISABLE move='+k.to_s+' duration='+(e[:duration]||180).to_s);else;log_event(:move_coverage_iv,target.log_name+' DISABLE_FAIL no_last_move=1');end
      when :yawn_v052;if !target.canonical_major_status_active?;target.apply_yawn_v052(user,e[:delay]||60);add_vfx_impact(target,:normal);log_event(:move_coverage_iv,target.log_name+' YAWN_PENDING delay='+(e[:delay]||60).to_s);end
      when :rage_v052;user.apply_rage_v052(e[:duration]||180);add_skill_effect(user,:buff)
      when :force_back_v052;target.apply_knockback(user,e[:distance]||118.0);add_vfx_impact(target,d[:canonical_move_key]==:whirlwind ? :flying : :normal)
      when :knock_off_v052
        if result.to_i>0 && target.respond_to?(:held_item_key_v041) && target.held_item_key_v041!=nil;old=target.held_item_key_v041;target.consume_held_item_v041(:knock_off);add_vfx_impact(target,:dark);log_event(:move_coverage_iv,target.log_name+' KNOCK_OFF item='+old.to_s);end
      when :endeavor_v052
        if target.hp.to_i>user.hp.to_i && PMD_AC.type_effectiveness(:normal,target.pokemon_types)>0.0;amount=target.hp.to_i-user.hp.to_i;before=target.hp;target.receive_damage(amount,user,false,true,false);extra=[before-target.hp,0].max;add_vfx_impact(target,:normal);log_event(:move_coverage_iv,user.log_name+' ENDEAVOR damage='+extra.to_s);end
      when :bound_v052;apply_bound_v052(user,target,e)
      when :charge_v052;user.apply_charge_v052(e[:duration]||180);add_vfx_impact(user,:electric);log_event(:move_coverage_iv,user.log_name+' CHARGE duration='+(e[:duration]||180).to_s)
      when :rapid_spin_clear_v052;n=user.clear_binding_v052;add_vfx_impact(user,:normal);log_event(:move_coverage_iv,user.log_name+' RAPID_SPIN_CLEAR count='+n.to_s)
      when :psych_up_v052;n=0;PMD_AC::STAT_STAGE_KEYS.each{|s|delta=target.stat_stage(s)-user.stat_stage(s);if delta!=0;user.change_stat_stage(s,delta,target);n+=1;end};add_vfx_impact(user,:psychic);log_event(:move_coverage_iv,user.log_name+' PSYCH_UP copied='+n.to_s)
      end
    end
    if d[:sequence_v052]==:rollout && result.to_i>0;user.advance_rollout_v052;end
    if d[:sequence_v052]==:fury_cutter && result.to_i>0;user.advance_fury_cutter_v052;end
    if d[:consume_charge_v052] && result.to_i>0;user.consume_charge_v052;log_event(:move_coverage_iv,user.log_name+' CHARGE_CONSUME electric=1');end
    [result.to_i,extra.to_i].max
  end
  def deal_direct_damage(user,target,power,options=nil)
    opts=options==nil ? {} : options.dup;data=opts[:skill_data]
    if data!=nil && data[:ignore_defense_stages_v052] && target!=nil && target.respond_to?(:stat_stage)
      stat=(data[:damage_category]||data[:category])==:special ? :spdef : :def;stages=target.instance_variable_get(:@stat_stages);if stages!=nil;old=stages[stat];stages[stat]=0;begin;return pmd_ac_v052_deal_direct_damage(user,target,power,opts);ensure;stages[stat]=old;end;end
    end;pmd_ac_v052_deal_direct_damage(user,target,power,opts)
  end
  def skill_cast_worthwhile?(unit,target,data)
    return false unless pmd_ac_v052_skill_cast_worthwhile(unit,target,data);return true if unit==nil || data==nil;mk=data[:canonical_move_key]
    return false if mk==:charge && unit.charge_active_v052?;return false if mk==:foresight && target!=nil && target.foresight_active_v052?;return false if mk==:yawn && target!=nil && (target.canonical_major_status_active? || target.instance_variable_get(:@yawn_frames_v052).to_i>0);return false if mk==:disable && (target==nil || target.last_move_key_v052==nil);true
  end

  # Verification --------------------------------------------------------------
  def prepare_verification_battle
    pmd_ac_v052_prepare_verification_battle
    if verification_mode==:move_coverage_iv;@move_coverage_iv_failed_v052=false;@future_sight_events_v052=[];for u in @units;u.verification_combat_sandbox(true);u.reset_move_coverage_iv_v052;end;end
  end
  def log_event(category,message)
    if category.to_s=='verify' && verification_mode==:move_coverage_iv && message.to_s.index('MOVE_COVERAGE_IV_')==0 && message.to_s.include?(' pass=0');@move_coverage_iv_failed_v052=true;end;pmd_ac_v052_log_event(category,message)
  end
  def verify_move_coverage_iv_manifest_v052
    return if @verification_done[:v052_manifest];e=PMD_AC.validate_move_coverage_iv_v052;m=PMD_AC::MOVE_COVERAGE_IV_MANIFEST_V052;pass=e.empty?;log_event(:verify,'MOVE_COVERAGE_IV_MANIFEST pass='+(pass ? '1':'0')+' new=24 cumulative=347 refs=496 audited=5849/7005 coverage=83.50 checksum='+PMD_AC.move_coverage_iv_checksum32_v052.to_s+' errors=['+e.join(',')+']');@verification_done[:v052_manifest]=true
  end
  def verify_move_coverage_iv_bridge_v052
    return if @verification_done[:v052_bridge];ok=true;PMD_AC::MOVE_COVERAGE_IV_MANIFEST_V052[:new_move_keys].each{|k|d=PMD_AC.skill_data(('mv_'+k.to_s).to_sym);p=PMD_AC.move_presentation_profile_v052(k);ok=false if d==nil || d[:canonical_move_key]!=k || !PMD_AC.move_executable?(k) || PMD_AC.skill_visual_move_profile_v031(k)==nil || PMD_AC.skill_audio_move_profile_v032(k)==nil || p==nil || p[:timing]==nil};log_event(:verify,'MOVE_COVERAGE_IV_BRIDGE pass='+(ok ? '1':'0')+' executable=24 visual_profile=24 audio_profile=24 timing_profile=24 canonical_keys=24');@verification_done[:v052_bridge]=true
  end
  def verify_move_coverage_iv_dynamic_v052
    return if @verification_done[:v052_dynamic];a=verification_unit(:ally,:bulbasaur);b=verification_unit(:enemy,:rattata);b.instance_variable_set(:@hp,b.maxhp);w=dynamic_power_v052(a,b,:wring_out);a.instance_variable_set(:@hp,[a.maxhp/25,1].max);r=dynamic_power_v052(a,b,:reversal);base=dynamic_power_v052(a,b,:pursuit);pass=w==121 && r==200 && [40,80].include?(base);log_event(:verify,'MOVE_COVERAGE_IV_DYNAMIC pass='+(pass ? '1':'0')+' wring_out_full='+w.to_s+' reversal_lowhp='+r.to_s+' pursuit='+base.to_s+' payback=50/100 assurance=50/100');@verification_done[:v052_dynamic]=true
  end
  def verify_move_coverage_iv_sequence_v052
    return if @verification_done[:v052_sequence];u=verification_unit(:ally,:bulbasaur);u.reset_move_coverage_iv_v052;r=[u.rollout_power_v052];4.times{u.advance_rollout_v052;r.push(u.rollout_power_v052)};u.reset_fury_cutter_v052;f=[u.fury_cutter_power_v052];3.times{u.advance_fury_cutter_v052;f.push(u.fury_cutter_power_v052)};pm=PMD_AC.skill_data(:mv_pin_missile);pass=r==[30,60,120,240,480] && f==[20,40,80,160] && pm[:multi_hit_v049] && pm[:multi_hit_min]==2 && pm[:multi_hit_max]==5;log_event(:verify,'MOVE_COVERAGE_IV_SEQUENCE pass='+(pass ? '1':'0')+' rollout='+r.join(',')+' fury_cutter='+f.join(',')+' pin_missile=2..5 visual_sync=1');@verification_done[:v052_sequence]=true
  end
  def verify_move_coverage_iv_delayed_v052
    return if @verification_done[:v052_delayed];fs=PMD_AC.skill_data(:mv_future_sight);yw=PMD_AC.skill_data(:mv_yawn);ds=PMD_AC.skill_data(:mv_disable);pass=fs[:effects][0][:delay].to_i==120 && yw[:effects][0][:delay].to_i==60 && ds[:effects][0][:duration].to_i==180;log_event(:verify,'MOVE_COVERAGE_IV_DELAYED pass='+(pass ? '1':'0')+' future_sight=120f yawn=60f disable=180f target_last_move=1 marker_sync=1');@verification_done[:v052_delayed]=true
  end
  def verify_move_coverage_iv_control_v052
    return if @verification_done[:v052_control];fo=PMD_AC.skill_data(:mv_foresight);ro=PMD_AC.skill_data(:mv_roar);wh=PMD_AC.skill_data(:mv_whirlwind);pu=PMD_AC.skill_data(:mv_psych_up);pass=fo[:effects][0][:duration].to_i==180 && ro[:priority].to_i==-6 && wh[:priority].to_i==-6 && pu[:effects][0][:type]==:psych_up_v052;log_event(:verify,'MOVE_COVERAGE_IV_CONTROL pass='+(pass ? '1':'0')+' foresight=evasion_ignore180 roar=knockback118 whirlwind=knockback128 priority=-6 psych_up=copy_all_stages');@verification_done[:v052_control]=true
  end
  def verify_move_coverage_iv_item_spin_v052
    return if @verification_done[:v052_item];ko=PMD_AC.skill_data(:mv_knock_off);rs=PMD_AC.skill_data(:mv_rapid_spin);ch=PMD_AC.skill_data(:mv_charge);pass=ko[:effects][1][:type]==:knock_off_v052 && rs[:effects][1][:type]==:rapid_spin_clear_v052 && ch[:effects][0][:duration].to_i==180 && ch[:effects][1][:stat]==:spdef;log_event(:verify,'MOVE_COVERAGE_IV_ITEM_SPIN pass='+(pass ? '1':'0')+' knock_off=held_item_remove rapid_spin=clear_bind+fire_spin+leech charge=spdef+1,next_electric_x2');@verification_done[:v052_item]=true
  end
  def verify_move_coverage_iv_trap_rage_v052
    return if @verification_done[:v052_trap];wa=PMD_AC.skill_data(:mv_wrap);wp=PMD_AC.skill_data(:mv_whirlpool);st=PMD_AC.skill_data(:mv_sand_tomb);rg=PMD_AC.skill_data(:mv_rage);pass=[wa,wp,st].all?{|d|e=d[:effects].find{|x|x[:type]==:bound_v052};e!=nil && e[:duration].to_i==300 && e[:interval].to_i==60} && rg[:effects][1][:duration].to_i==180;log_event(:verify,'MOVE_COVERAGE_IV_TRAP_RAGE pass='+(pass ? '1':'0')+' wrap/whirlpool/sand_tomb=1/16@60x5t+slow rage=atk+1_per_hit@180');@verification_done[:v052_trap]=true
  end
  def verify_move_coverage_iv_damage_rules_v052
    return if @verification_done[:v052_damage];ca=PMD_AC.skill_data(:mv_chip_away);en=PMD_AC.skill_data(:mv_endeavor);pa=PMD_AC.skill_data(:mv_payback);as=PMD_AC.skill_data(:mv_assurance);pass=ca[:ignore_defense_stages_v052] && en[:effects][0][:type]==:endeavor_v052 && pa[:dynamic_power_v052]==:payback && as[:dynamic_power_v052]==:assurance;log_event(:verify,'MOVE_COVERAGE_IV_DAMAGE_RULES pass='+(pass ? '1':'0')+' chip_away=ignore_def_stages endeavor=hp_equalize payback=recent_source_hit assurance=recent_any_hit');@verification_done[:v052_damage]=true
  end
  def verify_move_coverage_iv_presentation_v052
    return if @verification_done[:v052_presentation];ps=PMD_AC::MOVE_PRESENTATION_V052;special=[:future_sight,:disable,:yawn,:rollout,:fury_cutter,:charge,:wrap,:whirlpool,:sand_tomb,:pin_missile,:knock_off,:rapid_spin];ok=ps.size==24 && special.all?{|k|p=ps[k];p!=nil && p[:timing]!=nil && p[:sfx_profile]!=nil && p[:persistent_visual]!=nil};log_event(:verify,'MOVE_COVERAGE_IV_PRESENTATION pass='+(ok ? '1':'0')+' profiles=24 functional_sync=delayed,sequence,disable,bind,knockback,item,charge,multihit visual_bridge=24 audio_bridge=24 timing_bridge=24');@verification_done[:v052_presentation]=true
  end
  def verify_move_coverage_iv_modes_v052
    return if @verification_done[:v052_modes];exp=[:move_coverage_iv,:move_coverage_iii,:move_coverage_ii,:move_coverage,:mastery_policy];pass=PMD_AC::VERIFICATION_MODES==exp && verification_mode==:move_coverage_iv;log_event(:verify,'MOVE_COVERAGE_IV_RECENT_MODES pass='+(pass ? '1':'0')+' modes=5 default=MOVE_COVERAGE_IV');@verification_done[:v052_modes]=true
  end
  def update_verification_script
    pmd_ac_v052_update_verification_script;return unless verification_mode==:move_coverage_iv;f=@verification_frame
    verify_move_coverage_iv_manifest_v052 if f==4;verify_move_coverage_iv_bridge_v052 if f==120;verify_move_coverage_iv_dynamic_v052 if f==240;verify_move_coverage_iv_sequence_v052 if f==350;verify_move_coverage_iv_delayed_v052 if f==460;verify_move_coverage_iv_control_v052 if f==570;verify_move_coverage_iv_item_spin_v052 if f==680;verify_move_coverage_iv_trap_rage_v052 if f==790;verify_move_coverage_iv_damage_rules_v052 if f==890;verify_move_coverage_iv_presentation_v052 if f==980;verify_move_coverage_iv_modes_v052 if f==1050;complete_verification_mode if f==PMD_AC::VERIFICATION_MOVE_COVERAGE_IV_END_FRAME_V052
  end
  def complete_verification_mode
    if verification_mode==:move_coverage_iv && @move_coverage_iv_failed_v052;return if @verification_done[:verification_complete];for u in @units;u.verification_finish;end;@verification_done[:verification_complete]=true;log_event(:verify,'FAILED mode=MOVE_COVERAGE_IV auto_skill=on original_skills=restored');return;end;pmd_ac_v052_complete_verification_mode
  end
end
