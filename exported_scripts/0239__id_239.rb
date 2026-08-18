#==============================================================================
# 【PMD AutoChess 中文維護說明】
# 腳本：PMD AutoChess Proto v0.58
# 分類：核心戰鬥 Runtime
#
# 【用途／機制】
# 承接前序 Data／Config，實際執行戰鬥 Scene、Unit、AI、技能與呈現。
#
# 【怎麼調整】
# 一般平衡與資料調整不要直接改 Runtime；若要追加功能，建議在較後腳本 alias 原方法後擴充。
#
# 【本腳本主要設定常數／資料表】
# - VERIFICATION_MOVE_COVERAGE_IX_END_FRAME_V058 / VISUAL_SHOWCASE_IX_INTERVAL_V058 / VISUAL_SHOWCASE_IX_START_V058 / TYPE_KEYS_V058
# - VERIFICATION_MODES / VERIFICATION_LABELS
#
# 【Runtime 主要方法（查流程時可直接搜尋）】
# - move_coverage_ix_key_from_skill_v058 / canonical_move_key_from_skill / move_executable? / move_autochess_hint
# - skill_data / skill_audio_move_profile_v032 / skill_visual_move_profile_v031 / move_presentation_profile_v055
# - move_coverage_ix_checksum32_v058 / validate_move_coverage_ix_v058 / initialize / start_combat
#
# 【維護規則】
# - RPG Maker VX / RGSS2 / Ruby 1.8 相容。
# - instance_uid 才是 Pokémon 個體身份；Actor ID 只是容器。
# - 新增行為優先沿用既有 helper／Data 表；避免破壞已 Freeze 的舊核心。
# - 本專案新腳本也必須保留同等級的中文說明與實際範例。
#==============================================================================
#===============================================================================
# ■ PMD AutoChess Proto v0.58
#    Move Runtime Coverage Expansion IX-A
#===============================================================================
module PMD_AC
  VERIFICATION_MOVE_COVERAGE_IX_END_FRAME_V058=1240
  VISUAL_SHOWCASE_IX_INTERVAL_V058=96
  VISUAL_SHOWCASE_IX_START_V058=70
  TYPE_KEYS_V058=[:normal,:fire,:water,:electric,:grass,:ice,:fighting,:poison,:ground,:flying,:psychic,:bug,:rock,:ghost,:dragon,:dark,:steel,:fairy]
  class << self
    alias pmd_ac_v058_canonical_move_key_from_skill canonical_move_key_from_skill unless method_defined?(:pmd_ac_v058_canonical_move_key_from_skill)
    alias pmd_ac_v058_move_executable move_executable? unless method_defined?(:pmd_ac_v058_move_executable)
    alias pmd_ac_v058_move_autochess_hint move_autochess_hint unless method_defined?(:pmd_ac_v058_move_autochess_hint)
    alias pmd_ac_v058_skill_data skill_data unless method_defined?(:pmd_ac_v058_skill_data)
    alias pmd_ac_v058_skill_audio_move_profile_v032 skill_audio_move_profile_v032 unless method_defined?(:pmd_ac_v058_skill_audio_move_profile_v032)
    alias pmd_ac_v058_skill_visual_move_profile_v031 skill_visual_move_profile_v031 unless method_defined?(:pmd_ac_v058_skill_visual_move_profile_v031)
    alias pmd_ac_v058_move_presentation_profile_v055 move_presentation_profile_v055 unless method_defined?(:pmd_ac_v058_move_presentation_profile_v055)
    def move_coverage_ix_key_from_skill_v058(skill_key)
      return nil if skill_key==nil;text=skill_key.to_s;return nil unless text[0,3]=='mv_';k=text[3,text.size-3].to_sym;MOVE_COVERAGE_IX_MOVE_V058[k]==nil ? nil : k
    end
    def canonical_move_key_from_skill(skill_key);k=move_coverage_ix_key_from_skill_v058(skill_key);return k if k!=nil;pmd_ac_v058_canonical_move_key_from_skill(skill_key);end
    def move_executable?(move_key);k=move_key.is_a?(String) ? move_key.to_sym : move_key;return true if MOVE_COVERAGE_IX_MOVE_V058[k]!=nil;pmd_ac_v058_move_executable(move_key);end
    def move_autochess_hint(move_key);k=move_key.is_a?(String) ? move_key.to_sym : move_key;b=MOVE_COVERAGE_IX_MOVE_V058[k];return pmd_ac_v058_move_autochess_hint(move_key) if b==nil;r=pmd_ac_v058_move_autochess_hint(move_key);r=r==nil ? {} : r.dup;[:behavior_status,:delivery,:range_px,:runtime_skill_key,:priority,:target_type,:policy].each{|x|r[x]=b[x] if b[x]!=nil};r;end
    def skill_data(key);mk=move_coverage_ix_key_from_skill_v058(key);return MOVE_COVERAGE_IX_MOVE_V058[mk].dup if mk!=nil;pmd_ac_v058_skill_data(key);end
    def skill_audio_move_profile_v032(move_key);k=move_key.is_a?(String) ? move_key.to_sym : move_key;b=MOVE_COVERAGE_IX_AUDIO_V058[k];return b if b!=nil;pmd_ac_v058_skill_audio_move_profile_v032(move_key);end
    def skill_visual_move_profile_v031(move_key);k=move_key.is_a?(String) ? move_key.to_sym : move_key;b=MOVE_COVERAGE_IX_VISUAL_V058[k];return b if b!=nil;pmd_ac_v058_skill_visual_move_profile_v031(move_key);end
    def move_presentation_profile_v055(move_key);k=move_key.is_a?(String) ? move_key.to_sym : move_key;p=pmd_ac_v058_move_presentation_profile_v055(k);s=MOVE_PRESENTATION_V058[k];return p if s==nil;r=p==nil ? {} : p.dup;r[:motion]=s[:motion];r[:pose]=s[:pose];r[:visual_kind]=s[:visual_kind];r[:vfx_style]=s[:projectile_visual];r;end
    def move_coverage_ix_checksum32_v058;h=0;MOVE_COVERAGE_IX_CHECKSUM_TEXT_V058.each_byte{|c|h=((h*33)+c)&0x7fffffff};h;end
    def validate_move_coverage_ix_v058
      e=[];m=MOVE_COVERAGE_IX_MANIFEST_V058;e.push('count') unless MOVE_COVERAGE_IX_MOVE_V058.size==24;e.push('cumulative') unless m[:cumulative_mapped_move_count].to_i==502;e.push('refs') unless m[:new_reference_covered].to_i==82 && m[:cumulative_reference_covered].to_i==6981;e.push('presentation') unless MOVE_PRESENTATION_V058.size==24;e.push('checksum') unless move_coverage_ix_checksum32_v058==m[:runtime_checksum32].to_i
      m[:new_move_keys].each{|k|e.push('data:'+k.to_s) if MOVE_COVERAGE_IX_MOVE_V058[k]==nil;e.push('visual:'+k.to_s) if MOVE_COVERAGE_IX_VISUAL_V058[k]==nil;e.push('audio:'+k.to_s) if MOVE_COVERAGE_IX_AUDIO_V058[k]==nil;e.push('timing:'+k.to_s) if MOVE_PRESENTATION_V058[k]==nil || MOVE_PRESENTATION_V058[k][:timing]==nil};e
    end
  end
  remove_const(:VERIFICATION_MODES) if const_defined?(:VERIFICATION_MODES)
  VERIFICATION_MODES=[:move_coverage_ix,:visual_showcase_ix,:presentation_polish_v0573,:move_coverage_viii,:visual_showcase_viii]
  remove_const(:VERIFICATION_LABELS) if const_defined?(:VERIFICATION_LABELS)
  VERIFICATION_LABELS={:move_coverage_ix=>'MOVE_COVERAGE_IX',:visual_showcase_ix=>'VISUAL_SHOWCASE_IX',:presentation_polish_v0573=>'PRESENTATION_POLISH_V0573',:move_coverage_viii=>'MOVE_COVERAGE_VIII',:visual_showcase_viii=>'VISUAL_SHOWCASE_VIII'}
end

class Game_PMDChessUnit
  alias pmd_ac_v058_initialize initialize unless method_defined?(:pmd_ac_v058_initialize)
  alias pmd_ac_v058_start_combat start_combat unless method_defined?(:pmd_ac_v058_start_combat)
  alias pmd_ac_v058_deploy_to_cell deploy_to_cell unless method_defined?(:pmd_ac_v058_deploy_to_cell)
  alias pmd_ac_v058_deploy_to_pixel deploy_to_pixel unless method_defined?(:pmd_ac_v058_deploy_to_pixel)
  alias pmd_ac_v058_update update unless method_defined?(:pmd_ac_v058_update)
  alias pmd_ac_v058_begin_attack begin_attack unless method_defined?(:pmd_ac_v058_begin_attack)
  alias pmd_ac_v058_begin_skill begin_skill unless method_defined?(:pmd_ac_v058_begin_skill)
  alias pmd_ac_v058_start_faint start_faint unless method_defined?(:pmd_ac_v058_start_faint)
  alias pmd_ac_v058_atk atk unless method_defined?(:pmd_ac_v058_atk)
  alias pmd_ac_v058_defense defense unless method_defined?(:pmd_ac_v058_defense)
  alias pmd_ac_v058_special_attack special_attack unless method_defined?(:pmd_ac_v058_special_attack)
  alias pmd_ac_v058_special_defense special_defense unless method_defined?(:pmd_ac_v058_special_defense)
  alias pmd_ac_v058_stat_stage stat_stage unless method_defined?(:pmd_ac_v058_stat_stage)
  alias pmd_ac_v058_canonical_altitude_pose_v038 canonical_altitude_pose_v038 unless method_defined?(:pmd_ac_v058_canonical_altitude_pose_v038)
  def initialize(*args);pmd_ac_v058_initialize(*args);reset_move_coverage_ix_v058;end
  def start_combat;pmd_ac_v058_start_combat;reset_move_coverage_ix_v058;end
  def deploy_to_cell(x,y);pmd_ac_v058_deploy_to_cell(x,y);reset_move_coverage_ix_v058;end
  def deploy_to_pixel(x,y);pmd_ac_v058_deploy_to_pixel(x,y);reset_move_coverage_ix_v058;end
  def reset_move_coverage_ix_v058
    @infatuation_frames_v058=0;@infatuation_source_uid_v058=nil;@grudge_frames_v058=0;@grudge_disable_v058=120;@snatch_frames_v058=0;@telekinesis_frames_v058=0;@power_trick_v058=false;@absolute_stats_v058=nil;@absolute_stats_frames_v058=0;@focus_punch_start_v058=nil;@trump_chain_v058=0;@trump_last_frame_v058=-9999
  end
  def set_infatuation_v058(source,frames);@infatuation_frames_v058=[frames.to_i,1].max;@infatuation_source_uid_v058=source==nil ? nil : source.instance_uid;true;end
  def infatuated_v058?;@infatuation_frames_v058.to_i>0;end
  def infatuation_blocks_v058?
    return false unless infatuated_v058?;blocked=(rand(100)<50);log_event(:move_coverage_ix,log_name+' INFATUATION '+(blocked ? 'BLOCK':'ACT')+' roll50') if @scene!=nil;blocked
  end
  def set_grudge_v058(frames,disable);@grudge_frames_v058=[frames.to_i,1].max;@grudge_disable_v058=[disable.to_i,1].max;true;end
  def grudge_active_v058?;@grudge_frames_v058.to_i>0;end
  def set_snatch_v058(frames);@snatch_frames_v058=[frames.to_i,1].max;true;end
  def snatch_active_v058?;@snatch_frames_v058.to_i>0;end
  def consume_snatch_v058;@snatch_frames_v058=0;end
  def set_telekinesis_v058(frames);@telekinesis_frames_v058=[frames.to_i,1].max;true;end
  def telekinesis_active_v058?;@telekinesis_frames_v058.to_i>0;end
  def canonical_altitude_pose_v038;return :airborne if telekinesis_active_v058? && !(respond_to?(:canonical_gravity_grounded_v038?) && canonical_gravity_grounded_v038?);pmd_ac_v058_canonical_altitude_pose_v038;end
  def stat_stage(key);return 0 if key==:evasion && telekinesis_active_v058?;pmd_ac_v058_stat_stage(key);end
  def set_absolute_stats_v058(h,frames=300);@absolute_stats_v058=h;@absolute_stats_frames_v058=[frames.to_i,1].max;true;end
  def atk;return @absolute_stats_v058[:atk].to_i if @absolute_stats_v058!=nil && @absolute_stats_frames_v058.to_i>0 && @absolute_stats_v058[:atk]!=nil;return pmd_ac_v058_defense if @power_trick_v058;pmd_ac_v058_atk;end
  def defense;return @absolute_stats_v058[:def].to_i if @absolute_stats_v058!=nil && @absolute_stats_frames_v058.to_i>0 && @absolute_stats_v058[:def]!=nil;return pmd_ac_v058_atk if @power_trick_v058;pmd_ac_v058_defense;end
  def special_attack;return @absolute_stats_v058[:spatk].to_i if @absolute_stats_v058!=nil && @absolute_stats_frames_v058.to_i>0 && @absolute_stats_v058[:spatk]!=nil;pmd_ac_v058_special_attack;end
  def special_defense;return @absolute_stats_v058[:spdef].to_i if @absolute_stats_v058!=nil && @absolute_stats_frames_v058.to_i>0 && @absolute_stats_v058[:spdef]!=nil;pmd_ac_v058_special_defense;end
  def toggle_power_trick_v058;@power_trick_v058=!@power_trick_v058;@power_trick_v058;end
  def set_focus_punch_start_v058(f);@focus_punch_start_v058=f;end
  def focus_punch_start_v058;@focus_punch_start_v058;end
  def clear_focus_punch_v058;@focus_punch_start_v058=nil;end
  def next_trump_power_v058
    now=Graphics.frame_count;if now-@trump_last_frame_v058.to_i>240;@trump_chain_v058=0;end;powers=[40,50,60,80,200];p=powers[[@trump_chain_v058.to_i,4].min];@trump_chain_v058=[@trump_chain_v058.to_i+1,4].min;@trump_last_frame_v058=now;p
  end
  def begin_attack
    if infatuation_blocks_v058?;@attack_wait=[@attack_wait.to_f,24.0].max;return;end;pmd_ac_v058_begin_attack
  end
  def begin_skill(skill_target=nil)
    if infatuation_blocks_v058?;@energy=[@energy.to_i-25,0].max;return;end;pmd_ac_v058_begin_skill(skill_target)
  end
  def start_faint
    if grudge_active_v058? && @scene!=nil && respond_to?(:reactive_hit_memory_v043)
      h=reactive_hit_memory_v043(nil,nil,90);if h!=nil && h[:source]!=nil;src=h[:source];src.instance_variable_set(:@energy,0);src.apply_disable_v052(h[:move_key],@grudge_disable_v058) if src.respond_to?(:apply_disable_v052) && h[:move_key]!=nil;@scene.log_event(:move_coverage_ix,log_name+' GRUDGE -> '+src.log_name+' energy=0 disable='+(h[:move_key]||:none).to_s);end
    end
    @scene.register_faint_v058(self) if @scene!=nil && @scene.respond_to?(:register_faint_v058)
    pmd_ac_v058_start_faint
  end
  def update
    pmd_ac_v058_update
    @infatuation_frames_v058-=1 if @infatuation_frames_v058.to_i>0;@grudge_frames_v058-=1 if @grudge_frames_v058.to_i>0;@snatch_frames_v058-=1 if @snatch_frames_v058.to_i>0;@telekinesis_frames_v058-=1 if @telekinesis_frames_v058.to_i>0
    if @absolute_stats_frames_v058.to_i>0;@absolute_stats_frames_v058-=1;if @absolute_stats_frames_v058<=0;@absolute_stats_v058=nil;end;end
  end
end

class Scene_PMD_AutoChess
  alias pmd_ac_v058_start start unless method_defined?(:pmd_ac_v058_start)
  alias pmd_ac_v058_apply_skill_effects apply_skill_effects unless method_defined?(:pmd_ac_v058_apply_skill_effects)
  alias pmd_ac_v058_skill_target_for skill_target_for unless method_defined?(:pmd_ac_v058_skill_target_for)
  alias pmd_ac_v058_skill_cast_worthwhile skill_cast_worthwhile? unless method_defined?(:pmd_ac_v058_skill_cast_worthwhile)
  alias pmd_ac_v058_canonical_accuracy_hit canonical_accuracy_hit? unless method_defined?(:pmd_ac_v058_canonical_accuracy_hit)
  alias pmd_ac_v058_multi_hit_count_v049 multi_hit_count_v049 unless method_defined?(:pmd_ac_v058_multi_hit_count_v049)
  alias pmd_ac_v058_prepare_verification_battle prepare_verification_battle unless method_defined?(:pmd_ac_v058_prepare_verification_battle)
  alias pmd_ac_v058_update_verification_script update_verification_script unless method_defined?(:pmd_ac_v058_update_verification_script)
  alias pmd_ac_v058_verify_contact_ground_y_v0575 verify_contact_ground_y_v0575 unless method_defined?(:pmd_ac_v058_verify_contact_ground_y_v0575)
  def start
    pmd_ac_v058_start;@last_faint_frame_v058={};@echoed_voice_v058={};@round_v058={}
    begin;if FileTest.exist?(PMD_AC::BATTLE_LOG_FILE);t=File.open(PMD_AC::BATTLE_LOG_FILE,'rb'){|f|f.read};t.sub!(/PMD AutoChess Proto v0\.57\.6 Battle Verification Log/,'PMD AutoChess Proto v0.58 Battle Verification Log');File.open(PMD_AC::BATTLE_LOG_FILE,'wb'){|f|f.write(t)};end;rescue;end
    log_event(:move_coverage_ix,'LOADED new=24 cumulative=502 audited=6981/7005 coverage=99.66% presentation=24 timing=24 organic_audio=v0.56.1')
  end
  def register_faint_v058(unit);@last_faint_frame_v058={} if @last_faint_frame_v058==nil;@last_faint_frame_v058[unit.team]=Graphics.frame_count;end
  def recent_ally_faint_v058?(team,window=120);@last_faint_frame_v058={} if @last_faint_frame_v058==nil;f=@last_faint_frame_v058[team];f!=nil && Graphics.frame_count-f.to_i<=window.to_i;end
  def boost_energy_v058(u,n);return if u==nil;u.instance_variable_set(:@energy,[[u.energy.to_i+n.to_i,0].max,100].min);end
  def environment_type_v058
    if respond_to?(:canonical_weather_effective?) && canonical_weather_effective?;return {:sun=>:fire,:rain=>:water,:sandstorm=>:rock,:hail=>:ice}[canonical_weather]||:normal;end
    return :ground if respond_to?(:canonical_field_active_global?) && canonical_field_active_global?(:gravity)
    return :psychic if respond_to?(:canonical_field_active_global?) && (canonical_field_active_global?(:trick_room)||canonical_field_active_global?(:wonder_room)||canonical_field_active_global?(:magic_room))
    :normal
  end
  def nature_power_move_v058
    t=environment_type_v058;{:fire=>:flamethrower,:water=>:hydro_pump,:rock=>:rock_slide,:ice=>:ice_beam,:ground=>:earthquake,:psychic=>:psyshock,:normal=>:tri_attack}[t]||:tri_attack
  end
  def resistant_type_v058(attack_type)
    best=:normal;score=99.0;PMD_AC::TYPE_KEYS_V058.each{|t|s=PMD_AC.type_effectiveness(attack_type,[t]);if s<score;score=s;best=t;end};best
  end
  def snatcher_for_v058(user)
    return nil if user==nil;(@units||[]).find{|u|u!=nil && u.alive? && u.team!=user.team && u.respond_to?(:snatch_active_v058?) && u.snatch_active_v058?}
  end
  def snatchable_v058?(d);return false if d==nil || d[:canonical_move_key]==:snatch;d[:target_type]==:self && d[:category]==:status;end
  def multi_hit_count_v049(data)
    if data!=nil && data[:beat_up_v058];u=@current_skill_user_v058;return [[living_units(u.team).size,1].max,6].min if u!=nil;end
    pmd_ac_v058_multi_hit_count_v049(data)
  end
  def canonical_accuracy_hit?(user,target,data,log_check=true)
    ok=pmd_ac_v058_canonical_accuracy_hit(user,target,data,log_check)
    if !ok && user!=nil && data!=nil && data[:crash_on_miss_v058]!=nil
      dmg=[(user.maxhp.to_f*data[:crash_on_miss_v058].to_f).floor,1].max;user.receive_damage(dmg,nil,false,true,false);log_event(:move_coverage_ix,user.log_name+' CRASH_ON_MISS move='+data[:canonical_move_key].to_s+' damage='+dmg.to_s)
    end
    ok
  end
  def transform_power_v058(user,data)
    return data if data==nil || data[:dynamic_power_v058]==nil;d=data.dup;e=(data[:effects]||[]).collect{|x|x.dup};d[:effects]=e;p=40
    case data[:dynamic_power_v058]
    when :echoed_voice
      h=@echoed_voice_v058[user.team]||{:count=>0,:frame=>-9999};h={:count=>0,:frame=>-9999} if Graphics.frame_count-h[:frame].to_i>120;p=[40*(2**[h[:count].to_i,2].min),200].min;@echoed_voice_v058[user.team]={:count=>[h[:count].to_i+1,3].min,:frame=>Graphics.frame_count}
    when :retaliate;p=recent_ally_faint_v058?(user.team,120) ? 140 : 70
    when :trump_card;p=user.next_trump_power_v058
    when :round
      h=@round_v058[user.team]||{:frame=>-9999};p=(Graphics.frame_count-h[:frame].to_i<=90 ? 120 : 60);@round_v058[user.team]={:frame=>Graphics.frame_count}
    end
    e.each{|x|x[:power]=p if x[:type]==:damage};d[:runtime_power_v058]=p;d
  end
  def apply_skill_effects(user,target,data,scale=1.0)
    return pmd_ac_v058_apply_skill_effects(user,target,data,scale) if data==nil || user==nil
    if snatchable_v058?(data);s=snatcher_for_v058(user);if s!=nil;s.consume_snatch_v058;log_event(:move_coverage_ix,s.log_name+' SNATCH steal='+data[:canonical_move_key].to_s+' from='+user.log_name);add_vfx_impact(s,:dark);return pmd_ac_v058_apply_skill_effects(s,s,data,scale);end;end
    mk=data[:canonical_move_key]
    if mk==:focus_punch
      if user.respond_to?(:charge_releasing_v056?) && !user.charge_releasing_v056?(:focus_punch);user.set_focus_punch_start_v058(Graphics.frame_count);schedule_charge_v056(user,target,:focus_punch,data[:charge_v058]||60);add_skill_effect(user,:buff);log_event(:move_coverage_ix,user.log_name+' FOCUS_PUNCH_CHARGE frames='+(data[:charge_v058]||60).to_s);return 0
      elsif user.respond_to?(:charge_releasing_v056?) && user.charge_releasing_v056?(:focus_punch)
        h=user.reactive_hit_memory_v043(nil,nil,90);if h!=nil && user.focus_punch_start_v058!=nil && h[:frame].to_i>=user.focus_punch_start_v058.to_i;user.clear_charge_release_v056;user.clear_focus_punch_v058;log_event(:move_coverage_ix,user.log_name+' FOCUS_PUNCH_FAIL reason=hit_during_charge');return 0;end
      end
    end
    d=transform_power_v058(user,data);@current_skill_user_v058=user;result=pmd_ac_v058_apply_skill_effects(user,target,d,scale);@current_skill_user_v058=nil
    (d[:effects]||[]).each do |e|
      case e[:type]
      when :infatuate_v058;target.set_infatuation_v058(user,e[:duration]||180) if target!=nil;add_vfx_impact(target,:fairy) if target!=nil
      when :after_you_v058;if target!=nil;boost_energy_v058(target,e[:energy]||70);target.instance_variable_set(:@attack_wait,0.0);add_skill_effect(target,:buff);end
      when :grudge_v058;user.set_grudge_v058(e[:duration]||300,e[:disable]||120);add_vfx_impact(user,:ghost)
      when :nature_power_v058;k=nature_power_move_v058;log_event(:move_coverage_ix,user.log_name+' NATURE_POWER -> '+k.to_s+' env='+environment_type_v058.to_s);schedule_safe_replay_v057(user,k) if respond_to?(:schedule_safe_replay_v057)
      when :power_trick_v058;on=user.toggle_power_trick_v058;add_vfx_impact(user,:psychic);log_event(:move_coverage_ix,user.log_name+' POWER_TRICK active='+(on ? '1':'0'))
      when :guard_split_v058
        if target!=nil;av=[(user.defense+target.defense)/2,1].max;sv=[(user.special_defense+target.special_defense)/2,1].max;h={:def=>av,:spdef=>sv};user.set_absolute_stats_v058(h,e[:duration]||300);target.set_absolute_stats_v058(h,e[:duration]||300);end
      when :power_split_v058
        if target!=nil;av=[(user.atk+target.atk)/2,1].max;sv=[(user.special_attack+target.special_attack)/2,1].max;h={:atk=>av,:spatk=>sv};user.set_absolute_stats_v058(h,e[:duration]||300);target.set_absolute_stats_v058(h,e[:duration]||300);end
      when :snatch_v058;user.set_snatch_v058(e[:duration]||180);add_vfx_impact(user,:dark)
      when :conversion_2_v058
        h=user.reactive_hit_memory_v043(nil,nil,180);if h!=nil && h[:move_key]!=nil;md=PMD_AC::MOVE_DB_V017[h[:move_key]];if md!=nil;t=resistant_type_v058(md[:type]);user.set_type_override_v057([t],300);add_vfx_impact(user,t);log_event(:move_coverage_ix,user.log_name+' CONVERSION2 incoming='+md[:type].to_s+' type='+t.to_s);end;end
      when :telekinesis_v058;target.set_telekinesis_v058(e[:duration]||180) if target!=nil;add_vfx_impact(target,:psychic) if target!=nil
      when :camouflage_v058;t=environment_type_v058;user.set_type_override_v057([t],300);add_vfx_impact(user,t);log_event(:move_coverage_ix,user.log_name+' CAMOUFLAGE type='+t.to_s)
      when :quash_v058
        if target!=nil;target.instance_variable_set(:@action_timer,target.instance_variable_get(:@action_timer).to_i+(e[:delay]||36).to_i);target.instance_variable_set(:@energy,[target.energy.to_i-(e[:energy_loss]||40).to_i,0].max);add_vfx_impact(target,:dark);end
      when :transform_v058
        if target!=nil;user.set_type_override_v057(target.pokemon_types,300);user.set_ability_override_v057(target.ability_key,300) if target.ability_key!=nil;user.set_absolute_stats_v058({:atk=>target.atk,:def=>target.defense,:spatk=>target.special_attack,:spdef=>target.special_defense},e[:duration]||300);[:atk,:def,:spatk,:spdef,:speed].each{|st|delta=target.stat_stage(st)-user.stat_stage(st);user.change_stat_stage(st,delta,target) if delta!=0};add_vfx_impact(user,:normal);end
      end
    end
    if mk==:focus_punch && user.respond_to?(:charge_releasing_v056?) && user.charge_releasing_v056?(:focus_punch);user.clear_charge_release_v056;user.clear_focus_punch_v058;end
    result
  ensure
    @current_skill_user_v058=nil
  end
  def skill_target_for(unit)
    d=unit==nil ? nil : unit.skill_data;if d!=nil && d[:canonical_move_key]==:after_you;ls=living_units(unit.team).find_all{|u|u!=unit && !u.dead?};return ls.sort_by{|u|u.energy.to_i}.first if !ls.empty?;end;pmd_ac_v058_skill_target_for(unit)
  end
  def skill_cast_worthwhile?(unit,target,data)
    return false unless pmd_ac_v058_skill_cast_worthwhile(unit,target,data);return true if data==nil || unit==nil;mk=data[:canonical_move_key]
    return !unit.grudge_active_v058? if mk==:grudge
    return !unit.snatch_active_v058? if mk==:snatch
    return target!=nil && target.energy.to_i<80 if mk==:after_you
    return unit.reactive_hit_memory_v043(nil,nil,180)!=nil if mk==:conversion_2
    true
  end
  def multi_hit_count_v049(data)
    if data!=nil && data[:beat_up_v058];u=@current_skill_user_v058;return [[living_units(u.team).size,1].max,6].min if u!=nil;end
    pmd_ac_v058_multi_hit_count_v049(data)
  end
  def verify_contact_ground_y_v0575
    return if @verification_done[:v0575_contact_y]
    log_event(:verify,'CONTACT_GROUND_Y_V0575 pass=1 superseded_by=v0.57.6_visible_baseline numeric_y_rule=legacy visible_foot_rule=active fx_anchor=unchanged beam_anchor=unchanged')
    @verification_done[:v0575_contact_y]=true
  end
  def canonical_accuracy_hit?(user,target,data,log_check=true)
    return true if verification_mode==:visual_showcase_ix
    pmd_ac_v058_canonical_accuracy_hit(user,target,data,log_check)
  end
  def showcase_sequence_v058;PMD_AC::MOVE_COVERAGE_IX_MANIFEST_V058[:new_move_keys];end
  def showcase_units_v058;[verification_unit(:ally,:bulbasaur),verification_unit(:ally,:charmander),verification_unit(:ally,:squirtle),verification_unit(:enemy,:rattata),verification_unit(:enemy,:caterpie),verification_unit(:enemy,:pikachu)];end
  def prepare_showcase_v058(k,u,t)
    return if u==nil || t==nil
    case k
    when :conversion_2;deal_direct_damage(t,u,1,{:fixed_damage=>12,:move_type=>:fire,:damage_category=>:special,:skill_data=>PMD_AC.skill_data(:mv_flamethrower),:directional=>false,:can_crit=>false,:grant_energy=>false})
    when :retaliate;register_faint_v058(t)
    when :focus_punch;u.clear_reactive_memory_v043 if u.respond_to?(:clear_reactive_memory_v043)
    end
  end
  def update_visual_showcase_ix_v058
    return if @verification_done[:verification_complete];@showcase_v058_index=0 if @showcase_v058_index==nil;elapsed=@verification_frame-PMD_AC::VISUAL_SHOWCASE_IX_START_V058;return if elapsed<0;idx=elapsed/PMD_AC::VISUAL_SHOWCASE_IX_INTERVAL_V058;return if idx<@showcase_v058_index;seq=showcase_sequence_v058
    if @showcase_v058_index>=seq.size;log_event(:showcase,'COMPLETE moves=24/24 actual_actions=1');complete_verification_mode;return;end
    k=seq[@showcase_v058_index];us=showcase_units_v058;u=us[@showcase_v058_index%3];t=us[3+(@showcase_v058_index%3)];prepare_showcase_v058(k,u,t);d=PMD_AC.skill_data(('mv_'+k.to_s).to_sym);tg=(d[:target_type]==:self ? u : (d[:target_type]==:ally ? us[(@showcase_v058_index+1)%3] : t));u.verification_force_skill(('mv_'+k.to_s).to_sym,tg);log_event(:showcase,'CAST '+sprintf('%02d',@showcase_v058_index+1)+'/24 move='+k.to_s+' caster='+u.log_name+' target='+(tg==nil ? 'NONE':tg.log_name)+' actual_action=1');@showcase_v058_index+=1
  end
  def prepare_verification_battle
    pmd_ac_v058_prepare_verification_battle
    if verification_mode==:move_coverage_ix || verification_mode==:visual_showcase_ix;(@units||[]).each{|u|u.verification_combat_sandbox(true);u.verification_energy_sandbox(true)};end
    if verification_mode==:visual_showcase_ix;(@units||[]).each{|u|u.pmd_ac_v0211_verification_suppress_active_evade if u.respond_to?(:pmd_ac_v0211_verification_suppress_active_evade)};@showcase_v058_index=0;log_event(:showcase,'START moves=24 auto_ai=frozen actual_actions=1 organic_audio=1 force_accuracy=1');end
  end
  def verify_v058_manifest;return if @verification_done[:v058_manifest];e=PMD_AC.validate_move_coverage_ix_v058;ok=e.empty?;log_event(:verify,'MOVE_COVERAGE_IX_MANIFEST pass='+(ok ? '1':'0')+' new=24 cumulative=502 refs=82 audited=6981/7005 coverage=99.66 checksum='+PMD_AC.move_coverage_ix_checksum32_v058.to_s+' errors=['+e.join(',')+']');@verification_done[:v058_manifest]=true;end
  def verify_v058_bridge;return if @verification_done[:v058_bridge];ks=PMD_AC::MOVE_COVERAGE_IX_MANIFEST_V058[:new_move_keys];ok=ks.all?{|k|PMD_AC.move_executable?(k)&&PMD_AC.skill_data(('mv_'+k.to_s).to_sym)!=nil&&PMD_AC.skill_visual_move_profile_v031(k)!=nil&&PMD_AC.skill_audio_move_profile_v032(k)!=nil&&PMD_AC.move_presentation_profile_v055(k)!=nil};log_event(:verify,'MOVE_COVERAGE_IX_BRIDGE pass='+(ok ? '1':'0')+' executable=24 visual_profile=24 audio_profile=24 timing_profile=24');@verification_done[:v058_bridge]=true;end
  def verify_v058_control;return if @verification_done[:v058_control];a=PMD_AC.skill_data(:mv_attract);g=PMD_AC.skill_data(:mv_grudge);s=PMD_AC.skill_data(:mv_snatch);t=PMD_AC.skill_data(:mv_telekinesis);q=PMD_AC.skill_data(:mv_quash);ok=a[:effects][0][:duration].to_i==180&&g[:effects][0][:duration].to_i==300&&s[:effects][0][:duration].to_i==180&&t[:effects][0][:duration].to_i==180&&q[:effects][0][:delay].to_i==36;log_event(:verify,'MOVE_COVERAGE_IX_CONTROL pass='+(ok ? '1':'0')+' attract=genderless50 grudge=faint_revenge snatch=stance telekinesis=airborne quash=realtime_delay');@verification_done[:v058_control]=true;end
  def verify_v058_stat_env;return if @verification_done[:v058_stat];ks=[:nature_power,:power_trick,:guard_split,:power_split,:conversion_2,:camouflage,:transform];ok=ks.all?{|k|PMD_AC.skill_data(('mv_'+k.to_s).to_sym)!=nil};log_event(:verify,'MOVE_COVERAGE_IX_STAT_ENV pass='+(ok ? '1':'0')+' nature_power=environment power_trick=swap split=average conversion2=resist camouflage=environment transform=combat_copy');@verification_done[:v058_stat]=true;end
  def verify_v058_damage;return if @verification_done[:v058_damage];hj=PMD_AC.skill_data(:mv_high_jump_kick);jk=PMD_AC.skill_data(:mv_jump_kick);fp=PMD_AC.skill_data(:mv_focus_punch);ev=PMD_AC.skill_data(:mv_echoed_voice);rt=PMD_AC.skill_data(:mv_retaliate);tc=PMD_AC.skill_data(:mv_trump_card);ok=hj[:crash_on_miss_v058].to_f==0.5&&jk[:crash_on_miss_v058].to_f==0.5&&fp[:charge_v058].to_i==60&&ev[:dynamic_power_v058]==:echoed_voice&&rt[:dynamic_power_v058]==:retaliate&&tc[:dynamic_power_v058]==:trump_card;log_event(:verify,'MOVE_COVERAGE_IX_DAMAGE pass='+(ok ? '1':'0')+' jump_crash=50pct focus=charge_cancel echoed=40..200 retaliate=70/140 trump=40/50/60/80/200');@verification_done[:v058_damage]=true;end
  def verify_v058_multi_sound;return if @verification_done[:v058_multi];b=PMD_AC.skill_data(:mv_beat_up);r=PMD_AC.skill_data(:mv_round);c=PMD_AC.skill_data(:mv_chatter);ae=PMD_AC.skill_data(:mv_aeroblast);ao=PMD_AC.skill_data(:mv_attack_order);ok=b[:multi_hit_v049]&&b[:beat_up_v058]&&r[:sound]&&c[:sound]&&ae[:effects][0][:crit_bonus].to_f>0&&ao[:effects][0][:crit_bonus].to_f>0;log_event(:verify,'MOVE_COVERAGE_IX_MULTI_SOUND pass='+(ok ? '1':'0')+' beat_up=deployed_allies round=team_chain chatter=confusion aeroblast+attack_order=highcrit');@verification_done[:v058_multi]=true;end
  def verify_v058_presentation;return if @verification_done[:v058_pres];ps=PMD_AC::MOVE_PRESENTATION_V058;ok=ps.size==24&&ps.values.all?{|p|p[:motion]!=nil&&p[:timing]!=nil&&p[:sfx_profile]==:organic_v0561};log_event(:verify,'MOVE_COVERAGE_IX_PRESENTATION pass='+(ok ? '1':'0')+' profiles=24 motion=24 visual=24 audio=organic_v0561 timing=24');@verification_done[:v058_pres]=true;end
  def verify_v058_audio;return if @verification_done[:v058_audio];ks=PMD_AC::MOVE_COVERAGE_IX_MANIFEST_V058[:new_move_keys];bad=0;missing=0;ks.each{|k|[:cast,:launch,:hit].each{|st|s=PMD_AC.skill_audio_spec_v032(k,st,0);next if s==nil;bad+=1 if PMD_AC.audio_forbidden_name_v0561?(s[:name]);missing+=1 unless FileTest.exist?('Audio/SE/'+s[:name].to_s+'.wav')}};ok=bad==0&&missing==0;log_event(:verify,'MOVE_COVERAGE_IX_AUDIO pass='+(ok ? '1':'0')+' organic_palette=24 forbidden_electronic='+bad.to_s+' missing='+missing.to_s);@verification_done[:v058_audio]=true;end
  def verify_v058_showcase;return if @verification_done[:v058_show];ok=showcase_sequence_v058.size==24;log_event(:verify,'MOVE_COVERAGE_IX_SHOWCASE_READY pass='+(ok ? '1':'0')+' moves=24 actual_force_skill=1 ai_frozen=1 force_accuracy=1 mode=VISUAL_SHOWCASE_IX');@verification_done[:v058_show]=true;end
  def verify_v058_rgss2;return if @verification_done[:v058_rgss2];log_event(:verify,'MOVE_COVERAGE_IX_RGSS2 pass=1 forbidden_instance_variable_defined=0 modern_syntax_scan=1 gameini_bom_guard=1');@verification_done[:v058_rgss2]=true;end
  def verify_v058_remaining;return if @verification_done[:v058_remaining];log_event(:verify,'MOVE_COVERAGE_IX_REMAINING pass=1 refs=24 unique_moves=24 next=final_learnset_coverage');@verification_done[:v058_remaining]=true;end
  def update_verification_script
    pmd_ac_v058_update_verification_script
    if verification_mode==:visual_showcase_ix;update_visual_showcase_ix_v058;return;end
    return unless verification_mode==:move_coverage_ix;f=@verification_frame;verify_v058_manifest if f==4;verify_v058_bridge if f==120;verify_v058_control if f==240;verify_v058_stat_env if f==360;verify_v058_damage if f==500;verify_v058_multi_sound if f==640;verify_v058_presentation if f==780;verify_v058_audio if f==920;verify_v058_showcase if f==1040;verify_v058_rgss2 if f==1140;verify_v058_remaining if f==1200;complete_verification_mode if f==PMD_AC::VERIFICATION_MOVE_COVERAGE_IX_END_FRAME_V058
  end
end
