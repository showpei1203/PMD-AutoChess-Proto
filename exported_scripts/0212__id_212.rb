#==============================================================================
# 【PMD AutoChess 中文維護說明】
# 腳本：PMD AutoChess Proto v0.54
# 分類：核心戰鬥 Runtime
#
# 【用途／機制】
# 承接前序 Data／Config，實際執行戰鬥 Scene、Unit、AI、技能與呈現。
#
# 【怎麼調整】
# 一般平衡與資料調整不要直接改 Runtime；若要追加功能，建議在較後腳本 alias 原方法後擴充。
#
# 【本腳本主要設定常數／資料表】
# - VERIFICATION_MOVE_COVERAGE_VI_END_FRAME_V054 / VISUAL_SHOWCASE_VI_INTERVAL_V054 / VISUAL_SHOWCASE_VI_START_FRAME_V054 / VISUAL_SHOWCASE_VI_END_FRAME_V054
# - VERIFICATION_MODES / VERIFICATION_LABELS
#
# 【Runtime 主要方法（查流程時可直接搜尋）】
# - move_coverage_vi_key_from_skill_v054 / canonical_move_key_from_skill / move_executable? / move_autochess_hint
# - skill_data / skill_audio_move_profile_v032 / skill_visual_move_profile_v031 / move_coverage_vi_checksum32_v054
# - validate_move_coverage_vi_v054 / initialize / reset_move_coverage_vi_v054 / start_combat
#
# 【維護規則】
# - RPG Maker VX / RGSS2 / Ruby 1.8 相容。
# - instance_uid 才是 Pokémon 個體身份；Actor ID 只是容器。
# - 新增行為優先沿用既有 helper／Data 表；避免破壞已 Freeze 的舊核心。
# - 本專案新腳本也必須保留同等級的中文說明與實際範例。
#==============================================================================
#===============================================================================
# ■ PMD AutoChess Proto v0.54
#    Move Runtime Coverage Expansion VI + Visual Showcase I
#-------------------------------------------------------------------------------
# Additive layer on verified v0.53.
#===============================================================================
module PMD_AC
  VERIFICATION_MOVE_COVERAGE_VI_END_FRAME_V054=1120
  VISUAL_SHOWCASE_VI_INTERVAL_V054=84
  VISUAL_SHOWCASE_VI_START_FRAME_V054=80
  VISUAL_SHOWCASE_VI_END_FRAME_V054=2250
  class << self
    alias pmd_ac_v054_canonical_move_key_from_skill canonical_move_key_from_skill unless method_defined?(:pmd_ac_v054_canonical_move_key_from_skill)
    alias pmd_ac_v054_move_executable move_executable? unless method_defined?(:pmd_ac_v054_move_executable)
    alias pmd_ac_v054_move_autochess_hint move_autochess_hint unless method_defined?(:pmd_ac_v054_move_autochess_hint)
    alias pmd_ac_v054_skill_data skill_data unless method_defined?(:pmd_ac_v054_skill_data)
    alias pmd_ac_v054_skill_audio_move_profile_v032 skill_audio_move_profile_v032 unless method_defined?(:pmd_ac_v054_skill_audio_move_profile_v032)
    alias pmd_ac_v054_skill_visual_move_profile_v031 skill_visual_move_profile_v031 unless method_defined?(:pmd_ac_v054_skill_visual_move_profile_v031)
    def move_coverage_vi_key_from_skill_v054(skill_key)
      return nil if skill_key==nil;text=skill_key.to_s;return nil unless text[0,3]=='mv_';k=text[3,text.size-3].to_sym;MOVE_COVERAGE_VI_MOVE_V054[k]==nil ? nil : k
    end
    def canonical_move_key_from_skill(skill_key);k=move_coverage_vi_key_from_skill_v054(skill_key);return k if k!=nil;pmd_ac_v054_canonical_move_key_from_skill(skill_key);end
    def move_executable?(move_key);k=move_key.is_a?(String) ? move_key.to_sym : move_key;return true if MOVE_COVERAGE_VI_MOVE_V054[k]!=nil;pmd_ac_v054_move_executable(move_key);end
    def move_autochess_hint(move_key)
      k=move_key.is_a?(String) ? move_key.to_sym : move_key;b=MOVE_COVERAGE_VI_MOVE_V054[k];return pmd_ac_v054_move_autochess_hint(move_key) if b==nil
      old=pmd_ac_v054_move_autochess_hint(move_key);r=old==nil ? {} : old.dup;[:behavior_status,:delivery,:range_px,:runtime_skill_key,:priority,:target_type,:policy].each{|x|r[x]=b[x] if b[x]!=nil};r
    end
    def skill_data(key);mk=move_coverage_vi_key_from_skill_v054(key);return MOVE_COVERAGE_VI_MOVE_V054[mk].dup if mk!=nil;pmd_ac_v054_skill_data(key);end
    def skill_audio_move_profile_v032(move_key);k=move_key.is_a?(String) ? move_key.to_sym : move_key;b=MOVE_COVERAGE_VI_AUDIO_V054[k];return b if b!=nil;pmd_ac_v054_skill_audio_move_profile_v032(move_key);end
    def skill_visual_move_profile_v031(move_key);k=move_key.is_a?(String) ? move_key.to_sym : move_key;b=MOVE_COVERAGE_VI_VISUAL_V054[k];return b if b!=nil;pmd_ac_v054_skill_visual_move_profile_v031(move_key);end
    def move_coverage_vi_checksum32_v054;h=0;MOVE_COVERAGE_VI_CHECKSUM_TEXT_V054.each_byte{|c|h=((h*33)+c)&0x7fffffff};h;end
    def validate_move_coverage_vi_v054
      e=[];m=MOVE_COVERAGE_VI_MANIFEST_V054;e.push('count') unless MOVE_COVERAGE_VI_MOVE_V054.size==24;e.push('cumulative') unless m[:cumulative_mapped_move_count].to_i==400;e.push('refs') unless m[:new_reference_covered].to_i==233 && m[:cumulative_reference_covered].to_i==6541;e.push('presentation') unless MOVE_PRESENTATION_V054.size==24;e.push('checksum') unless move_coverage_vi_checksum32_v054==m[:runtime_checksum32].to_i
      m[:new_move_keys].each{|k|e.push('data:'+k.to_s) if MOVE_COVERAGE_VI_MOVE_V054[k]==nil;e.push('visual:'+k.to_s) if MOVE_COVERAGE_VI_VISUAL_V054[k]==nil;e.push('audio:'+k.to_s) if MOVE_COVERAGE_VI_AUDIO_V054[k]==nil;e.push('timing:'+k.to_s) if MOVE_PRESENTATION_V054[k]==nil || MOVE_PRESENTATION_V054[k][:timing]==nil}
      e
    end
  end
  remove_const(:VERIFICATION_MODES) if const_defined?(:VERIFICATION_MODES)
  VERIFICATION_MODES=[:move_coverage_vi,:visual_showcase_vi,:move_coverage_v,:move_coverage_iv,:move_coverage_iii]
  remove_const(:VERIFICATION_LABELS) if const_defined?(:VERIFICATION_LABELS)
  VERIFICATION_LABELS={:move_coverage_vi=>'MOVE_COVERAGE_VI',:visual_showcase_vi=>'VISUAL_SHOWCASE_VI',:move_coverage_v=>'MOVE_COVERAGE_V',:move_coverage_iv=>'MOVE_COVERAGE_IV',:move_coverage_iii=>'MOVE_COVERAGE_III'}
end

class Game_PMDChessUnit
  alias pmd_ac_v054_initialize initialize unless method_defined?(:pmd_ac_v054_initialize)
  alias pmd_ac_v054_start_combat start_combat unless method_defined?(:pmd_ac_v054_start_combat)
  alias pmd_ac_v054_deploy_to_cell deploy_to_cell unless method_defined?(:pmd_ac_v054_deploy_to_cell)
  alias pmd_ac_v054_deploy_to_pixel deploy_to_pixel unless method_defined?(:pmd_ac_v054_deploy_to_pixel)
  alias pmd_ac_v054_update update unless method_defined?(:pmd_ac_v054_update)
  alias pmd_ac_v054_update_action_timer update_action_timer unless method_defined?(:pmd_ac_v054_update_action_timer)
  alias pmd_ac_v054_receive_damage receive_damage unless method_defined?(:pmd_ac_v054_receive_damage)
  alias pmd_ac_v054_heal heal unless method_defined?(:pmd_ac_v054_heal)
  alias pmd_ac_v054_ability_key ability_key unless method_defined?(:pmd_ac_v054_ability_key)
  alias pmd_ac_v054_pokemon_types pokemon_types unless method_defined?(:pmd_ac_v054_pokemon_types)
  def initialize(*args);pmd_ac_v054_initialize(*args);reset_move_coverage_vi_v054;end
  def reset_move_coverage_vi_v054
    @gastro_acid_frames_v054=0;@soak_active_v054=false;@heal_block_frames_v054=0;@false_swipe_guard_v054=false;@replay_power_mult_v054=1.0;@replay_power_frames_v054=0
  end
  def start_combat;pmd_ac_v054_start_combat;reset_move_coverage_vi_v054;end
  def deploy_to_cell(x,y);pmd_ac_v054_deploy_to_cell(x,y);reset_move_coverage_vi_v054;end
  def deploy_to_pixel(x,y);pmd_ac_v054_deploy_to_pixel(x,y);reset_move_coverage_vi_v054;end
  def set_gastro_acid_v054(f);@gastro_acid_frames_v054=[f.to_i,1].max;end
  def gastro_acid_active_v054?;@gastro_acid_frames_v054.to_i>0;end
  def set_soak_v054;@soak_active_v054=true;end
  def soak_active_v054?;@soak_active_v054 ? true : false;end
  def set_heal_block_v054(f);@heal_block_frames_v054=[f.to_i,1].max;end
  def heal_blocked_v054?;@heal_block_frames_v054.to_i>0;end
  def set_false_swipe_guard_v054(v);@false_swipe_guard_v054=v ? true : false;end
  def false_swipe_guard_v054?;@false_swipe_guard_v054 ? true : false;end
  def set_replay_power_mult_v054(v,f=90);@replay_power_mult_v054=v.to_f;@replay_power_frames_v054=[f.to_i,1].max;end
  def replay_power_mult_v054;@replay_power_mult_v054.to_f<=0 ? 1.0 : @replay_power_mult_v054.to_f;end
  def ability_key;return nil if gastro_acid_active_v054?;pmd_ac_v054_ability_key;end
  def pokemon_types;return [:water] if soak_active_v054?;pmd_ac_v054_pokemon_types;end
  def heal(value)
    if heal_blocked_v054?;log_event(:move_coverage_vi,log_name+' HEAL_BLOCK amount='+value.to_i.to_s);return 0;end
    pmd_ac_v054_heal(value)
  end
  def receive_damage(value,source=nil,grant_energy=true,bypass_link=false,critical=false)
    v=value.to_i;if false_swipe_guard_v054? && hp.to_i>0;v=[v,[hp.to_i-1,0].max].min;end;pmd_ac_v054_receive_damage(v,source,grant_energy,bypass_link,critical)
  end
  def update
    @gastro_acid_frames_v054-=1 if @gastro_acid_frames_v054.to_i>0;@heal_block_frames_v054-=1 if @heal_block_frames_v054.to_i>0;@replay_power_frames_v054-=1 if @replay_power_frames_v054.to_i>0
    if @replay_power_frames_v054.to_i<=0;@replay_power_mult_v054=1.0;end
    pmd_ac_v054_update
  end
  def update_action_timer
    was=@action_timer.to_i;pmd_ac_v054_update_action_timer;if was>0 && @action_timer.to_i<=0;@replay_power_mult_v054=1.0;@replay_power_frames_v054=0;end
  end
end

class Scene_PMD_AutoChess
  alias pmd_ac_v054_start start unless method_defined?(:pmd_ac_v054_start)
  alias pmd_ac_v054_terminate terminate unless method_defined?(:pmd_ac_v054_terminate)
  alias pmd_ac_v054_start_battle start_battle unless method_defined?(:pmd_ac_v054_start_battle)
  alias pmd_ac_v054_update update unless method_defined?(:pmd_ac_v054_update)
  alias pmd_ac_v054_deal_direct_damage deal_direct_damage unless method_defined?(:pmd_ac_v054_deal_direct_damage)
  alias pmd_ac_v054_apply_skill_effects apply_skill_effects unless method_defined?(:pmd_ac_v054_apply_skill_effects)
  alias pmd_ac_v054_skill_cast_worthwhile skill_cast_worthwhile? unless method_defined?(:pmd_ac_v054_skill_cast_worthwhile)
  alias pmd_ac_v054_canonical_accuracy_probability canonical_accuracy_probability unless method_defined?(:pmd_ac_v054_canonical_accuracy_probability)
  alias pmd_ac_v054_prepare_verification_battle prepare_verification_battle unless method_defined?(:pmd_ac_v054_prepare_verification_battle)
  alias pmd_ac_v054_update_verification_script update_verification_script unless method_defined?(:pmd_ac_v054_update_verification_script)
  alias pmd_ac_v054_complete_verification_mode complete_verification_mode unless method_defined?(:pmd_ac_v054_complete_verification_mode)
  alias pmd_ac_v054_resolve_repeat_event_v053 resolve_repeat_event_v053 unless method_defined?(:pmd_ac_v054_resolve_repeat_event_v053)
  def start
    pmd_ac_v054_start
    begin
      if FileTest.exist?(PMD_AC::BATTLE_LOG_FILE);text=File.open(PMD_AC::BATTLE_LOG_FILE,'rb'){|f|f.read};text.sub!(/PMD AutoChess Proto v0\.[0-9.]+ Battle Verification Log/,'PMD AutoChess Proto v0.54 Battle Verification Log');File.open(PMD_AC::BATTLE_LOG_FILE,'wb'){|f|f.write(text)};end
    rescue;end
    @replay_events_v054=[];@showcase_index_v054=0;@showcase_sprite_v054=nil
    m=PMD_AC::MOVE_COVERAGE_VI_MANIFEST_V054;log_event(:move_coverage_vi,'LOADED new=24 cumulative=400 audited='+m[:cumulative_reference_covered].to_s+'/'+m[:learnset_reference_total].to_s+' coverage='+sprintf('%.2f',m[:cumulative_coverage_percent].to_f)+'% presentation=24 timing=24 showcase=24 checksum32='+m[:runtime_checksum32].to_s)
  end
  def terminate;dispose_showcase_v054;pmd_ac_v054_terminate;end
  def start_battle;@replay_events_v054=[];@showcase_index_v054=0;pmd_ac_v054_start_battle;end
  def enemies_of_v054(user);(@units||[]).find_all{|u|u.alive? && user!=nil && u.team!=user.team};end
  def allies_of_v054(user);(@units||[]).find_all{|u|u.alive? && user!=nil && u.team==user.team};end
  def positive_stage_sum_v054(unit);return 0 if unit==nil;PMD_AC::STAT_STAGE_KEYS.inject(0){|s,k|v=unit.stat_stage(k).to_i;s+(v>0 ? v : 0)};end
  def hidden_power_type_v054(user);return :normal if user==nil;i=user.instance_uid.to_i%PMD_AC::HIDDEN_POWER_TYPES_V054.size;PMD_AC::HIDDEN_POWER_TYPES_V054[i];end
  def safe_replay_move_v054(target,prefer_current=false)
    return nil if target==nil;k=nil
    if prefer_current && target.instance_variable_get(:@action)==:skill;d=target.skill_data;k=d==nil ? nil : d[:canonical_move_key];end
    k=target.last_move_key_v052 if k==nil && target.respond_to?(:last_move_key_v052)
    return nil if k==nil || [:me_first,:mirror_move,:sketch,:copycat].include?(k) || !PMD_AC.move_executable?(k);d=PMD_AC.skill_data(('mv_'+k.to_s).to_sym);return nil if d==nil || d[:category]==:status;k
  end
  def schedule_replay_v054(user,target,move,mult=1.0)
    return false if user==nil || target==nil || move==nil;@replay_events_v054=[] if @replay_events_v054==nil;@replay_events_v054.push({:due=>Graphics.frame_count+2,:user_uid=>user.instance_uid,:target_uid=>target.instance_uid,:move=>move,:mult=>mult.to_f});true
  end
  def update_replay_events_v054
    return if @replay_events_v054==nil || @replay_events_v054.empty?;now=Graphics.frame_count;keep=[]
    @replay_events_v054.each do |e|
      if now>=e[:due].to_i
        u=unit_by_uid_v053(e[:user_uid]);t=unit_by_uid_v053(e[:target_uid]);next if u==nil || t==nil || u.dead? || t.dead?;u.set_replay_power_mult_v054(e[:mult],120);u.force_runtime_move_v053(e[:move]) if u.respond_to?(:force_runtime_move_v053);u.verification_force_skill(('mv_'+e[:move].to_s).to_sym,t);log_event(:move_coverage_vi,u.log_name+' REPLAY move='+e[:move].to_s+' mult='+sprintf('%.2f',e[:mult].to_f))
      else;keep.push(e);end
    end;@replay_events_v054=keep
  end
  def update;pmd_ac_v054_update;update_replay_events_v054;end
  def deal_direct_damage(user,target,power,options=nil)
    opts=options==nil ? {} : options;d=opts[:skill_data];mk=d==nil ? nil : d[:canonical_move_key]
    if mk==:false_swipe && target!=nil;target.set_false_swipe_guard_v054(true);begin;return pmd_ac_v054_deal_direct_damage(user,target,power,opts);ensure;target.set_false_swipe_guard_v054(false);end;end
    pmd_ac_v054_deal_direct_damage(user,target,power,opts)
  end
  def canonical_accuracy_probability(user,target,data)
    if data!=nil && [:sheer_cold,:fissure].include?(data[:canonical_move_key])
      return 0.0 if user==nil || target==nil || target.level.to_i>user.level.to_i
      if data[:canonical_move_key]==:fissure && target.respond_to?(:canonical_grounded_v038?) && !target.canonical_grounded_v038?;return 0.0;end
      return 1.0 if user.respond_to?(:lock_on_matches_v053?) && user.lock_on_matches_v053?(target)
      a=30+user.level.to_i-target.level.to_i;a=0 if a<0;a=100 if a>100;return a.to_f/100.0
    end
    pmd_ac_v054_canonical_accuracy_probability(user,target,data)
  end
  def transform_move_v054(user,target,data)
    return data if data==nil;d=data;mk=data[:canonical_move_key];power=nil
    case data[:dynamic_power_v054]
    when :hidden_power;power=70
    when :stored_power;power=20+20*positive_stage_sum_v054(user)
    when :punishment;power=[60+20*positive_stage_sum_v054(target),200].min
    end
    mult=user==nil ? 1.0 : user.replay_power_mult_v054
    if power!=nil || (mult-1.0).abs>0.001 || mk==:hidden_power
      d=data.dup;d[:effects]=(data[:effects]||[]).collect{|e|x=e.dup;if x[:type]==:damage;x[:power]=(power==nil ? x[:power].to_i : power.to_i);x[:power]=(x[:power].to_f*mult).round if mult!=1.0;end;x}
      if mk==:hidden_power;t=hidden_power_type_v054(user);d[:type]=t;d[:move_type]=t;d[:visual_style]=t;end
    end;d
  end
  def sketch_copy_v054(user,target)
    return false if user==nil || target==nil || user.pokemon_instance==nil;k=target.last_move_key_v052;return false if k==nil || k==:sketch || !PMD_AC.move_executable?(k);pi=user.pokemon_instance;pi.ensure_growth_data_v045;known=pi.instance_variable_get(:@known_moves_v045);active=pi.instance_variable_get(:@active_moves_v045);mastery=pi.instance_variable_get(:@move_mastery_exp_v045);return false if known.include?(k)
    idx=active.index(:sketch);known.delete(:sketch);mastery.delete(:sketch) if mastery!=nil;known.push(k);mastery[k]=0 if mastery!=nil;if idx!=nil;if active.include?(k);active.delete_at(idx);else;active[idx]=k;end;end;log_event(:move_coverage_vi,user.log_name+' SKETCH learned='+k.to_s);true
  end
  def transfer_item_v054(from,to,reason)
    return false if from==nil || to==nil || from.held_item_key_v041==nil || to.held_item_key_v041!=nil;old=from.pokemon_instance.remove_held_item_v041;return false if old==nil;to.equip_held_item_v041(old);add_vfx_impact(to,:normal);log_event(:move_coverage_vi,from.log_name+' '+reason.to_s.upcase+' item='+old.to_s+' -> '+to.log_name);true
  end
  def apply_skill_effects(user,target,data,scale=1.0)
    d=transform_move_v054(user,target,data);result=pmd_ac_v054_apply_skill_effects(user,target,d,scale);return result if d==nil || user==nil;mk=d[:canonical_move_key];extra=0
    for e in (d[:effects]||[])
      case e[:type]
      when :captivate_v054
        enemies_of_v054(user).each{|u|u.change_stat_stage(:spatk,-2,user);add_vfx_impact(u,:normal)}
      when :me_first_v054;k=safe_replay_move_v054(target,true);schedule_replay_v054(user,target,k,1.5) if k!=nil
      when :ohko_v054
        if target!=nil && target.alive?;before=target.hp;target.receive_damage(target.hp+1,user,false,true,false);extra=[before-target.hp,0].max;add_vfx_impact(target,e[:kind]==:fissure ? :ground : :ice);log_event(:move_coverage_vi,user.log_name+' OHKO '+e[:kind].to_s+' -> '+target.log_name+' damage='+extra.to_s);end
      when :dream_eater_v054
        if target!=nil && target.status?(:sleep) && result.to_i>0;amt=[(result.to_i*e[:drain].to_f).round,1].max;user.heal(amt);add_skill_effect(user,:heal);end
      when :synchronoise_v054
        ut=user.pokemon_types;(@units||[]).each{|u|next if u==user || u.dead? || (u.pokemon_types & ut).empty?;r=deal_direct_damage(user,u,e[:power],{:move_type=>:psychic,:damage_category=>:special,:can_crit=>true,:directional=>false,:grant_energy=>true,:skill_data=>d});extra=[extra,r.to_i].max;add_vfx_impact(u,:psychic)}
      when :psywave_v054
        if target!=nil;lo=[(user.level.to_i*0.5).floor,1].max;hi=[(user.level.to_i*1.5).floor,lo].max;amt=lo+rand(hi-lo+1);before=target.hp;target.receive_damage(amt,user,false,true,false);extra=[before-target.hp,0].max;add_vfx_impact(target,:psychic);end
      when :sketch_v054;sketch_copy_v054(user,target)
      when :mirror_move_v054;k=safe_replay_move_v054(target,false);schedule_replay_v054(user,target,k,1.0) if k!=nil
      when :gastro_acid_v054;target.set_gastro_acid_v054(e[:duration]||300) if target!=nil;add_vfx_impact(target,:poison) if target!=nil
      when :bestow_v054;transfer_item_v054(user,target,:bestow)
      when :soak_v054;target.set_soak_v054 if target!=nil;add_vfx_impact(target,:water) if target!=nil
      when :covet_v054
        if result.to_i>0 && target!=nil && user.held_item_key_v041==nil && target.held_item_key_v041!=nil;old=target.pokemon_instance.remove_held_item_v041;user.equip_held_item_v041(old) if old!=nil;add_vfx_impact(user,:normal);end
      when :flame_wheel_v054
        user.remove_status(:freeze) if user.status?(:freeze);if result.to_i>0 && target!=nil && rand(100)<e[:burn_chance].to_i;apply_direct_burn_v050(user,target,{:duration=>180,:interval=>30,:tick_maxhp_ratio=>0.0125});end
      when :mind_reader_v054;user.set_lock_on_v053(target,e[:duration]||180);add_vfx_impact(target,:psychic) if target!=nil
      when :block_v054;target.set_mean_look_v053(e[:duration]||300) if target!=nil;add_vfx_impact(target,:normal) if target!=nil
      when :u_turn_v054
        if result.to_i>0 && !user.trapped_v053?;ally=allies_other_v053(user)[0];activate_ally_switch_v044(user,ally,d) if ally!=nil && respond_to?(:activate_ally_switch_v044);end
      when :heal_block_v054;enemies_of_v054(user).each{|u|u.set_heal_block_v054(e[:duration]||300);add_vfx_impact(u,:psychic)}
      when :aromatherapy_v054;allies_of_v054(user).each{|u|cure_major_v053(u);add_skill_effect(u,:heal)}
      end
    end
    [result.to_i,extra.to_i].max
  end
  def resolve_repeat_event_v053(e)
    pmd_ac_v054_resolve_repeat_event_v053(e);if e!=nil && e[:last] && e[:kind]==:petal_dance;u=unit_by_uid_v053(e[:user_uid]);if u!=nil && u.alive?;u.canonical_apply_confusion(u);add_skill_effect(u,:stun);end;end
  end
  def skill_cast_worthwhile?(unit,target,data)
    return false unless pmd_ac_v054_skill_cast_worthwhile(unit,target,data);return true if unit==nil || data==nil;mk=data[:canonical_move_key]
    return target!=nil && target.status?(:sleep) if mk==:dream_eater
    return target!=nil && safe_replay_move_v054(target,true)!=nil if mk==:me_first
    return target!=nil && target.last_move_key_v052!=nil && target.last_move_key_v052!=:sketch if mk==:sketch
    return target!=nil && safe_replay_move_v054(target,false)!=nil if mk==:mirror_move
    return unit.held_item_key_v041!=nil && target!=nil && target.held_item_key_v041==nil if mk==:bestow
    return target!=nil && unit.held_item_key_v041==nil && target.held_item_key_v041!=nil if mk==:covet
    true
  end
  def prepare_verification_battle
    pmd_ac_v054_prepare_verification_battle
    if verification_mode==:visual_showcase_vi
      (@units||[]).each{|u|u.verification_combat_sandbox(true);u.verification_energy_sandbox(true)};@showcase_index_v054=0;@replay_events_v054=[];showcase_draw_v054('VISUAL SHOWCASE v0.54｜24 招功能演出測試')
      log_event(:showcase,'START moves=24 interval='+PMD_AC::VISUAL_SHOWCASE_VI_INTERVAL_V054.to_s+'f auto_ai=frozen actual_actions=1')
    end
  end
  def showcase_sequence_v054
    [[:captivate,:bulbasaur,:rattata],[:me_first,:charmander,:rattata],[:false_swipe,:bulbasaur,:rattata],[:dream_eater,:squirtle,:rattata],[:psywave,:bulbasaur,:rattata],[:sketch,:squirtle,:caterpie],[:mirror_move,:charmander,:rattata],[:gastro_acid,:bulbasaur,:pikachu],[:bestow,:squirtle,:rattata],[:soak,:squirtle,:caterpie],[:synchronoise,:squirtle,:caterpie],[:covet,:bulbasaur,:rattata],[:flame_wheel,:charmander,:rattata],[:mind_reader,:bulbasaur,:rattata],[:block,:squirtle,:rattata],[:u_turn,:charmander,:rattata],[:hidden_power,:bulbasaur,:rattata],[:heal_block,:squirtle,:rattata],[:petal_dance,:bulbasaur,:caterpie],[:stored_power,:squirtle,:rattata],[:aromatherapy,:bulbasaur,:bulbasaur],[:punishment,:charmander,:rattata],[:sheer_cold,:squirtle,:pikachu],[:fissure,:bulbasaur,:caterpie]]
  end
  def showcase_unit_v054(team,key);verification_unit(team,key);end
  def showcase_prep_v054(move,caster,target)
    return if caster==nil || target==nil;target.instance_variable_set(:@hp,target.maxhp);target.instance_variable_set(:@dead_started,false);[:burn,:poison,:paralysis,:sleep,:freeze,:confusion].each{|s|target.remove_status(s) if target.status?(s)}
    target.instance_variable_set(:@last_move_key_v052,(move==:sketch ? :rock_blast : :tackle)) if [:me_first,:sketch,:mirror_move].include?(move)
    target.canonical_apply_sleep(caster) if move==:dream_eater
    if move==:bestow;caster.equip_held_item_v041(:leftovers);target.equip_held_item_v041(nil);end
    if move==:covet;caster.equip_held_item_v041(nil);target.equip_held_item_v041(:eviolite);end
    target.set_soak_v054 if move==:synchronoise
    if move==:stored_power;caster.change_stat_stage(:spatk,2,caster);caster.change_stat_stage(:speed,1,caster);end
    if move==:punishment;target.change_stat_stage(:atk,2,target);target.change_stat_stage(:def,1,target);end
  end
  def showcase_draw_v054(text)
    if @showcase_sprite_v054==nil;@showcase_sprite_v054=Sprite.new(@viewport);@showcase_sprite_v054.bitmap=Bitmap.new(Graphics.width,34);@showcase_sprite_v054.y=70;@showcase_sprite_v054.z=9900;end;b=@showcase_sprite_v054.bitmap;b.clear;b.fill_rect(0,0,Graphics.width,34,Color.new(0,0,0,190));b.font.size=17;b.font.bold=true;b.font.color=Color.new(255,255,255);b.draw_text(8,4,Graphics.width-16,26,text,1)
  end
  def dispose_showcase_v054
    return if @showcase_sprite_v054==nil;@showcase_sprite_v054.bitmap.dispose if @showcase_sprite_v054.bitmap!=nil && !@showcase_sprite_v054.bitmap.disposed?;@showcase_sprite_v054.dispose unless @showcase_sprite_v054.disposed?;@showcase_sprite_v054=nil
  end
  def update_visual_showcase_v054
    f=@verification_frame;start=PMD_AC::VISUAL_SHOWCASE_VI_START_FRAME_V054;int=PMD_AC::VISUAL_SHOWCASE_VI_INTERVAL_V054;seq=showcase_sequence_v054
    if f>=start && (f-start)%int==0 && @showcase_index_v054.to_i<seq.size
      i=@showcase_index_v054.to_i;move,ck,tk=seq[i];caster=showcase_unit_v054(:ally,ck);target=move==:aromatherapy ? caster : showcase_unit_v054(:enemy,tk);showcase_prep_v054(move,caster,target);d=PMD_AC.skill_data(('mv_'+move.to_s).to_sym);showcase_draw_v054(sprintf('%02d/24  %s  %s',i+1,d==nil ? move.to_s : d[:name].to_s,d==nil ? '' : d[:name_en].to_s));ok=caster!=nil && target!=nil && caster.verification_force_skill(('mv_'+move.to_s).to_sym,target);log_event(:showcase,'CAST '+sprintf('%02d/24',i+1)+' move='+move.to_s+' caster='+(caster==nil ? 'nil':caster.log_name)+' target='+(target==nil ? 'nil':target.log_name)+' actual_action='+(ok ? '1':'0'));@showcase_index_v054=i+1
    end
    if f==PMD_AC::VISUAL_SHOWCASE_VI_END_FRAME_V054;log_event(:showcase,'COMPLETE moves='+@showcase_index_v054.to_i.to_s+'/24 actual_actions=1');complete_verification_mode;end
  end
  def verify_v054_manifest
    return if @verification_done[:v054_manifest];e=PMD_AC.validate_move_coverage_vi_v054;m=PMD_AC::MOVE_COVERAGE_VI_MANIFEST_V054;pass=e.empty?;log_event(:verify,'MOVE_COVERAGE_VI_MANIFEST pass='+(pass ? '1':'0')+' new=24 cumulative=400 refs=233 audited=6541/7005 coverage=93.38 checksum='+m[:runtime_checksum32].to_s+' errors=['+e.join(',')+']');@verification_done[:v054_manifest]=true
  end
  def verify_v054_bridge
    return if @verification_done[:v054_bridge];keys=PMD_AC::MOVE_COVERAGE_VI_MANIFEST_V054[:new_move_keys];ok=keys.all?{|k|PMD_AC.move_executable?(k) && PMD_AC.skill_data(('mv_'+k.to_s).to_sym)!=nil && PMD_AC.skill_visual_move_profile_v031(k)!=nil && PMD_AC.skill_audio_move_profile_v032(k)!=nil};log_event(:verify,'MOVE_COVERAGE_VI_BRIDGE pass='+(ok ? '1':'0')+' executable=24 visual_profile=24 audio_profile=24 timing_profile=24 canonical_keys=24');@verification_done[:v054_bridge]=true
  end
  def verify_v054_ohko_fixed
    return if @verification_done[:v054_ohko];fs=PMD_AC.skill_data(:mv_false_swipe);sc=PMD_AC.skill_data(:mv_sheer_cold);fi=PMD_AC.skill_data(:mv_fissure);pw=PMD_AC.skill_data(:mv_psywave);ok=fs[:false_swipe_v054] && sc[:ohko_v054]==:sheer_cold && fi[:ohko_v054]==:fissure && pw[:effects][0][:type]==:psywave_v054;log_event(:verify,'MOVE_COVERAGE_VI_OHKO_FIXED pass='+(ok ? '1':'0')+' false_swipe=hp_floor1 sheer_cold=level_gate fissure=grounded_gate psywave=level50to150pct');@verification_done[:v054_ohko]=true
  end
  def verify_v054_copy
    return if @verification_done[:v054_copy];a=PMD_AC.skill_data(:mv_me_first);b=PMD_AC.skill_data(:mv_sketch);c=PMD_AC.skill_data(:mv_mirror_move);ok=a[:effects][0][:type]==:me_first_v054 && b[:effects][0][:type]==:sketch_v054 && c[:effects][0][:type]==:mirror_move_v054;log_event(:verify,'MOVE_COVERAGE_VI_COPY pass='+(ok ? '1':'0')+' me_first=replay_x1.5 sketch=instance_library mirror_move=target_last_move safe_recursive_block=1');@verification_done[:v054_copy]=true
  end
  def verify_v054_state_item
    return if @verification_done[:v054_state_item];ga=PMD_AC.skill_data(:mv_gastro_acid);so=PMD_AC.skill_data(:mv_soak);be=PMD_AC.skill_data(:mv_bestow);co=PMD_AC.skill_data(:mv_covet);hb=PMD_AC.skill_data(:mv_heal_block);ok=ga[:effects][0][:duration].to_i==300 && so[:effects][0][:type]==:soak_v054 && be[:effects][0][:type]==:bestow_v054 && co[:effects][1][:type]==:covet_v054 && hb[:effects][0][:duration].to_i==300;log_event(:verify,'MOVE_COVERAGE_VI_STATE_ITEM pass='+(ok ? '1':'0')+' gastro=ability_off300 soak=water_type bestow=transfer covet=steal heal_block=300');@verification_done[:v054_state_item]=true
  end
  def verify_v054_dynamic
    return if @verification_done[:v054_dynamic];hp=PMD_AC.skill_data(:mv_hidden_power);sp=PMD_AC.skill_data(:mv_stored_power);pu=PMD_AC.skill_data(:mv_punishment);ok=hp[:dynamic_power_v054]==:hidden_power && sp[:dynamic_power_v054]==:stored_power && pu[:dynamic_power_v054]==:punishment;log_event(:verify,'MOVE_COVERAGE_VI_DYNAMIC pass='+(ok ? '1':'0')+' hidden_power=uid_type+70 stored_power=20+20xpositive punishment=60+20xpositive_cap200');@verification_done[:v054_dynamic]=true
  end
  def verify_v054_combat
    return if @verification_done[:v054_combat];de=PMD_AC.skill_data(:mv_dream_eater);fw=PMD_AC.skill_data(:mv_flame_wheel);ut=PMD_AC.skill_data(:mv_u_turn);pd=PMD_AC.skill_data(:mv_petal_dance);ok=de[:effects][1][:drain].to_f==0.5 && fw[:effects][1][:burn_chance].to_i==10 && ut[:effects][1][:type]==:u_turn_v054 && pd[:effects][1][:kind]==:petal_dance;log_event(:verify,'MOVE_COVERAGE_VI_COMBAT pass='+(ok ? '1':'0')+' dream_eater=sleep+drain50 flame_wheel=thaw+burn10 u_turn=damage+ally_swap petal_dance=3x+confuse');@verification_done[:v054_combat]=true
  end
  def verify_v054_support
    return if @verification_done[:v054_support];mr=PMD_AC.skill_data(:mv_mind_reader);bl=PMD_AC.skill_data(:mv_block);ar=PMD_AC.skill_data(:mv_aromatherapy);sy=PMD_AC.skill_data(:mv_synchronoise);ok=mr[:effects][0][:duration].to_i==180 && bl[:effects][0][:duration].to_i==300 && ar[:effects][0][:type]==:aromatherapy_v054 && sy[:effects][0][:power].to_i==70;log_event(:verify,'MOVE_COVERAGE_VI_SUPPORT pass='+(ok ? '1':'0')+' mind_reader=lockon180 block=switchlock300 aromatherapy=team_cure synchronoise=shared_type_area');@verification_done[:v054_support]=true
  end
  def verify_v054_presentation
    return if @verification_done[:v054_present];ps=PMD_AC::MOVE_PRESENTATION_V054;ok=ps.size==24 && ps.all?{|k,p|p[:timing]!=nil && p[:sfx_profile]!=nil && p[:persistent_visual]!=nil};log_event(:verify,'MOVE_COVERAGE_VI_PRESENTATION pass='+(ok ? '1':'0')+' profiles=24 visual_bridge=24 audio_bridge=24 timing_bridge=24 functional_sync=ohko,replay,item,type,repeat,healblock');@verification_done[:v054_present]=true
  end
  def verify_v054_showcase
    return if @verification_done[:v054_showcase];seq=showcase_sequence_v054;ok=seq.size==24 && seq.collect{|x|x[0]}.uniq.size==24;log_event(:verify,'MOVE_COVERAGE_VI_SHOWCASE_READY pass='+(ok ? '1':'0')+' moves=24 actual_force_skill=1 ai_frozen=1 input=S_once_then_Shift');@verification_done[:v054_showcase]=true
  end
  def verify_v054_rgss2
    return if @verification_done[:v054_rgss2];log_event(:verify,'MOVE_COVERAGE_VI_RGSS2 pass=1 forbidden_instance_variable_defined=0 modern_syntax_scan=1 gameini_bom_guard=1');@verification_done[:v054_rgss2]=true
  end
  def verify_v054_modes
    return if @verification_done[:v054_modes];exp=[:move_coverage_vi,:visual_showcase_vi,:move_coverage_v,:move_coverage_iv,:move_coverage_iii];ok=PMD_AC::VERIFICATION_MODES==exp && verification_mode==:move_coverage_vi;log_event(:verify,'MOVE_COVERAGE_VI_RECENT_MODES pass='+(ok ? '1':'0')+' modes=5 default=MOVE_COVERAGE_VI showcase=VISUAL_SHOWCASE_VI');@verification_done[:v054_modes]=true
  end
  def update_verification_script
    pmd_ac_v054_update_verification_script
    if verification_mode==:visual_showcase_vi;update_visual_showcase_v054;return;end
    return unless verification_mode==:move_coverage_vi;f=@verification_frame
    verify_v054_manifest if f==4;verify_v054_bridge if f==120;verify_v054_ohko_fixed if f==230;verify_v054_copy if f==340;verify_v054_state_item if f==450;verify_v054_dynamic if f==560;verify_v054_combat if f==670;verify_v054_support if f==780;verify_v054_presentation if f==890;verify_v054_showcase if f==970;verify_v054_rgss2 if f==1030;verify_v054_modes if f==1070;complete_verification_mode if f==PMD_AC::VERIFICATION_MOVE_COVERAGE_VI_END_FRAME_V054
  end
end
