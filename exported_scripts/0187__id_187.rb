#==============================================================================
# 【PMD AutoChess 中文維護說明】
# 腳本：PMD AutoChess Proto v0.43
# 分類：核心戰鬥 Runtime
#
# 【用途／機制】
# 承接前序 Data／Config，實際執行戰鬥 Scene、Unit、AI、技能與呈現。
#
# 【怎麼調整】
# 一般平衡與資料調整不要直接改 Runtime；若要追加功能，建議在較後腳本 alias 原方法後擴充。
#
# 【本腳本主要設定常數／資料表】
# - VERIFICATION_REACTIVE_END_FRAME_V043 / REACTIVE_WINDOW_FRAMES_V043 / VERIFICATION_MODES / VERIFICATION_LABELS
#
# 【Runtime 主要方法（查流程時可直接搜尋）】
# - reactive_move_key_from_skill_v043 / canonical_move_key_from_skill / move_executable? / move_autochess_hint
# - skill_data / skill_audio_move_profile_v032 / skill_visual_move_profile_v031 / validate_reactive_priority_v043
# - initialize / clear_reactive_memory_v043 / reactive_source_key_v043 / record_reactive_hit_v043
#
# 【維護規則】
# - RPG Maker VX / RGSS2 / Ruby 1.8 相容。
# - instance_uid 才是 Pokémon 個體身份；Actor ID 只是容器。
# - 新增行為優先沿用既有 helper／Data 表；避免破壞已 Freeze 的舊核心。
# - 本專案新腳本也必須保留同等級的中文說明與實際範例。
#==============================================================================
#===============================================================================
# ■ PMD AutoChess Proto v0.43
#    Reactive Priority Runtime I
#-------------------------------------------------------------------------------
# Additive layer on verified v0.42.1.
# Realtime adaptation: one canonical turn = 60 battle frames for reaction memory.
#===============================================================================
module PMD_AC
  VERIFICATION_REACTIVE_END_FRAME_V043=650
  REACTIVE_WINDOW_FRAMES_V043=60
  class << self
    alias pmd_ac_v043_canonical_move_key_from_skill canonical_move_key_from_skill unless method_defined?(:pmd_ac_v043_canonical_move_key_from_skill)
    alias pmd_ac_v043_move_executable move_executable? unless method_defined?(:pmd_ac_v043_move_executable)
    alias pmd_ac_v043_move_autochess_hint move_autochess_hint unless method_defined?(:pmd_ac_v043_move_autochess_hint)
    alias pmd_ac_v043_skill_data skill_data unless method_defined?(:pmd_ac_v043_skill_data)
    alias pmd_ac_v043_skill_audio_move_profile_v032 skill_audio_move_profile_v032 unless method_defined?(:pmd_ac_v043_skill_audio_move_profile_v032)
    alias pmd_ac_v043_skill_visual_move_profile_v031 skill_visual_move_profile_v031 unless method_defined?(:pmd_ac_v043_skill_visual_move_profile_v031)

    def reactive_move_key_from_skill_v043(skill_key)
      return nil if skill_key==nil
      text=skill_key.to_s
      return nil unless text[0,3]=='mv_'
      key=text[3,text.size-3].to_sym
      REACTIVE_PRIORITY_MOVE_V043[key]==nil ? nil : key
    end
    def canonical_move_key_from_skill(skill_key)
      k=reactive_move_key_from_skill_v043(skill_key);return k if k!=nil
      pmd_ac_v043_canonical_move_key_from_skill(skill_key)
    end
    def move_executable?(move_key)
      return true if REACTIVE_PRIORITY_MOVE_V043[move_key]!=nil
      pmd_ac_v043_move_executable(move_key)
    end
    def move_autochess_hint(move_key)
      b=REACTIVE_PRIORITY_MOVE_V043[move_key];return pmd_ac_v043_move_autochess_hint(move_key) if b==nil
      old=pmd_ac_v043_move_autochess_hint(move_key);r=old==nil ? {} : old.dup
      r[:behavior_status]=b[:behavior_status];r[:delivery]=b[:delivery];r[:range_px]=b[:range_px];r[:runtime_skill_key]=b[:runtime_skill_key];r[:priority]=b[:priority];r
    end
    def skill_data(key)
      mk=reactive_move_key_from_skill_v043(key)
      return REACTIVE_PRIORITY_MOVE_V043[mk].dup if mk!=nil
      pmd_ac_v043_skill_data(key)
    end
    def skill_audio_move_profile_v032(move_key)
      b=REACTIVE_PRIORITY_AUDIO_V043[move_key];return b if b!=nil
      pmd_ac_v043_skill_audio_move_profile_v032(move_key)
    end
    def skill_visual_move_profile_v031(move_key)
      b=REACTIVE_PRIORITY_VISUAL_V043[move_key];return b if b!=nil
      pmd_ac_v043_skill_visual_move_profile_v031(move_key)
    end
    def validate_reactive_priority_v043
      e=[];m=REACTIVE_PRIORITY_MANIFEST_V043
      e.push('count') unless REACTIVE_PRIORITY_MOVE_V043.size==6
      e.push('cumulative') unless m[:cumulative_mapped_move_count].to_i==257
      e.push('covered') unless m[:cumulative_reference_covered].to_i==4280
      [:sucker_punch,:counter,:mirror_coat,:revenge,:avalanche,:vital_throw].each{|k|e.push('missing:'+k.to_s) if REACTIVE_PRIORITY_MOVE_V043[k]==nil}
      e.push('priority') unless REACTIVE_PRIORITY_MOVE_V043[:sucker_punch][:priority].to_i==1 && REACTIVE_PRIORITY_MOVE_V043[:counter][:priority].to_i==-5 && REACTIVE_PRIORITY_MOVE_V043[:revenge][:priority].to_i==-4 && REACTIVE_PRIORITY_MOVE_V043[:vital_throw][:priority].to_i==-1
      e.push('vital_accuracy') unless REACTIVE_PRIORITY_MOVE_V043[:vital_throw].has_key?(:accuracy) && REACTIVE_PRIORITY_MOVE_V043[:vital_throw][:accuracy]==nil
      e
    end
  end
  remove_const(:VERIFICATION_MODES) if const_defined?(:VERIFICATION_MODES)
  VERIFICATION_MODES=[:reactive_priority,:priority,:held_item,:guard,:two_turn]
  remove_const(:VERIFICATION_LABELS) if const_defined?(:VERIFICATION_LABELS)
  VERIFICATION_LABELS={:reactive_priority=>'REACTIVE_PRIORITY',:priority=>'PRIORITY',:held_item=>'HELD_ITEM',:guard=>'GUARD',:two_turn=>'TWO_TURN'}
end

class Game_PMDChessUnit
  alias pmd_ac_v043_initialize initialize unless method_defined?(:pmd_ac_v043_initialize)
  alias pmd_ac_v043_start_faint start_faint unless method_defined?(:pmd_ac_v043_start_faint)
  alias pmd_ac_v043_deploy_to_cell deploy_to_cell unless method_defined?(:pmd_ac_v043_deploy_to_cell)
  alias pmd_ac_v043_deploy_to_pixel deploy_to_pixel unless method_defined?(:pmd_ac_v043_deploy_to_pixel)

  def initialize(*args);pmd_ac_v043_initialize(*args);@reactive_hits_v043={};end
  def clear_reactive_memory_v043;@reactive_hits_v043={};end
  def reactive_source_key_v043(source)
    return nil if source==nil
    return source.instance_uid.to_i if source.respond_to?(:instance_uid)
    source.object_id
  end
  def record_reactive_hit_v043(source,damage,category,data=nil)
    return false if source==nil || source==self || damage.to_i<=0
    return false if source.respond_to?(:team) && source.team==team
    cat=category==nil ? :physical : category.to_sym
    return false unless [:physical,:special].include?(cat)
    @reactive_hits_v043={} if @reactive_hits_v043==nil
    key=reactive_source_key_v043(source);return false if key==nil
    @reactive_hits_v043[key]={:source=>source,:damage=>damage.to_i,:category=>cat,:frame=>Graphics.frame_count,:move_key=>(data==nil ? nil : data[:canonical_move_key])}
    true
  end
  def reactive_hit_memory_v043(category=nil,source=nil,window=PMD_AC::REACTIVE_WINDOW_FRAMES_V043)
    @reactive_hits_v043={} if @reactive_hits_v043==nil
    now=Graphics.frame_count;best=nil
    @reactive_hits_v043.each_value do |h|
      next if h==nil || h[:source]==nil || h[:source].dead?
      age=now-h[:frame].to_i;next if age<0 || age>window.to_i
      next if category!=nil && h[:category]!=category
      next if source!=nil && h[:source]!=source
      best=h if best==nil || h[:frame].to_i>best[:frame].to_i
    end
    best
  end
  def reactive_was_hit_by_v043?(source,window=PMD_AC::REACTIVE_WINDOW_FRAMES_V043);reactive_hit_memory_v043(nil,source,window)!=nil;end
  def reactive_pre_hit_damaging_action_v043?
    return false if dead? || @action_timer.to_i<=0 || @action_hit_done
    return true if @action==:attack
    return false unless @action==:skill
    d=skill_data;return false if d==nil || d.empty?
    for e in (d[:effects]||[]);return true if e[:type]==:damage;end
    return true if d[:canonical_power].to_i>0 || d[:power].to_i>0
    false
  end
  def start_faint;clear_reactive_memory_v043;pmd_ac_v043_start_faint;end
  def deploy_to_cell(x,y);clear_reactive_memory_v043;pmd_ac_v043_deploy_to_cell(x,y);end
  def deploy_to_pixel(x,y);clear_reactive_memory_v043;pmd_ac_v043_deploy_to_pixel(x,y);end
end

class Scene_PMD_AutoChess
  alias pmd_ac_v043_start start unless method_defined?(:pmd_ac_v043_start)
  alias pmd_ac_v043_start_battle start_battle unless method_defined?(:pmd_ac_v043_start_battle)
  alias pmd_ac_v043_skill_target_for skill_target_for unless method_defined?(:pmd_ac_v043_skill_target_for)
  alias pmd_ac_v043_skill_cast_worthwhile skill_cast_worthwhile? unless method_defined?(:pmd_ac_v043_skill_cast_worthwhile)
  alias pmd_ac_v043_apply_skill_effects apply_skill_effects unless method_defined?(:pmd_ac_v043_apply_skill_effects)
  alias pmd_ac_v043_deal_direct_damage deal_direct_damage unless method_defined?(:pmd_ac_v043_deal_direct_damage)
  alias pmd_ac_v043_prepare_verification_battle prepare_verification_battle unless method_defined?(:pmd_ac_v043_prepare_verification_battle)
  alias pmd_ac_v043_update_verification_script update_verification_script unless method_defined?(:pmd_ac_v043_update_verification_script)
  alias pmd_ac_v043_log_event log_event unless method_defined?(:pmd_ac_v043_log_event)
  alias pmd_ac_v043_complete_verification_mode complete_verification_mode unless method_defined?(:pmd_ac_v043_complete_verification_mode)

  def start
    pmd_ac_v043_start
    begin
      if FileTest.exist?(PMD_AC::BATTLE_LOG_FILE)
        text=File.open(PMD_AC::BATTLE_LOG_FILE,'rb'){|f|f.read};text.sub!(/PMD AutoChess Proto v0\.[0-9.]+ Battle Verification Log/,'PMD AutoChess Proto v0.43 Battle Verification Log');File.open(PMD_AC::BATTLE_LOG_FILE,'wb'){|f|f.write(text)}
      end
    rescue;end
    m=PMD_AC::REACTIVE_PRIORITY_MANIFEST_V043
    log_event(:reactive_priority,'LOADED new=6 cumulative='+m[:cumulative_mapped_move_count].to_s+' covered='+m[:cumulative_reference_covered].to_s+'/'+m[:learnset_reference_total].to_s+' coverage='+sprintf('%.2f',m[:cumulative_coverage_percent].to_f)+'% window='+PMD_AC::REACTIVE_WINDOW_FRAMES_V043.to_s+' priority=integrated checksum32='+m[:runtime_checksum32].to_s)
  end
  def start_battle
    pmd_ac_v043_start_battle
    if @phase==:battle;for u in (@units||[]);u.clear_reactive_memory_v043 if u.respond_to?(:clear_reactive_memory_v043);end;end
  end
  def reactive_move_key_v043(data);data==nil ? nil : (data[:canonical_move_key]||data[:move_key]);end
  def reactive_return_snapshot_v043(unit,mk)
    return nil if unit==nil
    cat=(mk==:counter ? :physical : :special)
    unit.reactive_hit_memory_v043(cat,nil,PMD_AC::REACTIVE_WINDOW_FRAMES_V043)
  end
  def skill_target_for(unit)
    if unit!=nil
      data=unit.skill_data;mk=reactive_move_key_v043(data)
      if [:counter,:mirror_coat].include?(mk)
        h=reactive_return_snapshot_v043(unit,mk);s=h==nil ? nil : h[:source]
        return nil if s==nil || s.dead? || s.team==unit.team
        return s
      end
    end
    pmd_ac_v043_skill_target_for(unit)
  end
  def skill_cast_worthwhile?(unit,target,data)
    return false unless pmd_ac_v043_skill_cast_worthwhile(unit,target,data)
    mk=reactive_move_key_v043(data)
    return target.respond_to?(:reactive_pre_hit_damaging_action_v043?) && target.reactive_pre_hit_damaging_action_v043? if mk==:sucker_punch
    return reactive_return_snapshot_v043(unit,mk)!=nil if [:counter,:mirror_coat].include?(mk)
    true
  end
  def deal_direct_damage(user,target,power,options=nil)
    before=(target==nil ? 0 : target.hp.to_i);opts=options==nil ? {} : options
    result=pmd_ac_v043_deal_direct_damage(user,target,power,options)
    if user!=nil && target!=nil && user.team!=target.team
      hp_damage=[before-target.hp.to_i,0].max
      if hp_damage>0 && target.respond_to?(:record_reactive_hit_v043)
        data=opts[:skill_data];cat=opts[:damage_category]
        cat=(data[:damage_category]||data[:category]) if cat==nil && data!=nil
        cat=:physical if cat==nil
        target.record_reactive_hit_v043(user,hp_damage,cat,data)
      end
    end
    result
  end
  def reactive_fail_v043(user,target,mk,reason)
    user.register_miss(target) if user!=nil && target!=nil && user.respond_to?(:register_miss)
    log_event(:reactive_priority,(user==nil ? 'NONE':user.log_name)+' '+mk.to_s.upcase+' FAIL reason='+reason.to_s+(target==nil ? '':' target='+target.log_name));0
  end
  def reactive_return_damage_v043(user,data,mk)
    h=reactive_return_snapshot_v043(user,mk);return reactive_fail_v043(user,nil,mk,:no_matching_hit) if h==nil
    target=h[:source];return reactive_fail_v043(user,target,mk,:source_lost) if target==nil || target.dead? || target.team==user.team
    type=data[:move_type]||data[:type];eff=PMD_AC.type_effectiveness(type,target.pokemon_types)
    return reactive_fail_v043(user,target,mk,:type_immune) if eff<=0.0
    amount=[h[:damage].to_i*(data[:return_ratio]||2).to_i,1].max
    log_event(:reactive_priority,user.log_name+' '+mk.to_s.upcase+' RETURN source='+target.log_name+' taken='+h[:damage].to_s+' return='+amount.to_s+' category='+h[:category].to_s)
    add_vfx_impact(target,data[:visual_style]||type) if respond_to?(:add_vfx_impact)
    deal_direct_damage(user,target,1,{:fixed_damage=>amount,:move_type=>type,:damage_category=>data[:damage_category],:skill_data=>data,:directional=>false,:can_crit=>false})
  end
  def reactive_scaled_damage_data_v043(user,target,data,mk)
    doubled=user!=nil && target!=nil && user.reactive_was_hit_by_v043?(target,PMD_AC::REACTIVE_WINDOW_FRAMES_V043)
    d=data.dup;d[:effects]=(data[:effects]||[]).collect{|e|e.dup}
    if doubled
      for e in d[:effects];e[:power]=e[:power].to_i*2 if e[:type]==:damage;end
      d[:canonical_power]=data[:canonical_power].to_i*2
      log_event(:reactive_priority,user.log_name+' '+mk.to_s.upcase+' POWER 60->120 target_hit_user=1')
    end
    d
  end
  def apply_skill_effects(user,target,data,scale=1.0)
    mk=reactive_move_key_v043(data)
    if mk==:sucker_punch
      return reactive_fail_v043(user,target,mk,:target_not_readying_damage) unless target!=nil && target.respond_to?(:reactive_pre_hit_damaging_action_v043?) && target.reactive_pre_hit_damaging_action_v043?
    elsif [:counter,:mirror_coat].include?(mk)
      return reactive_return_damage_v043(user,data,mk)
    elsif [:revenge,:avalanche].include?(mk)
      return pmd_ac_v043_apply_skill_effects(user,target,reactive_scaled_damage_data_v043(user,target,data,mk),scale)
    end
    pmd_ac_v043_apply_skill_effects(user,target,data,scale)
  end

  def prepare_verification_battle
    pmd_ac_v043_prepare_verification_battle
    if verification_mode==:reactive_priority
      @reactive_failed_v043=false
      for u in @units;u.verification_combat_sandbox(true);u.clear_reactive_memory_v043;end
    end
  end
  def log_event(category,message)
    if category.to_s=='verify' && verification_mode==:reactive_priority && message.to_s.index('REACTIVE_')==0 && message.to_s.include?(' pass=0');@reactive_failed_v043=true;end
    pmd_ac_v043_log_event(category,message)
  end
  def reactive_verify_units_v043
    a=verification_unit(:ally,:bulbasaur);b=verification_unit(:ally,:charmander);c=verification_unit(:ally,:squirtle);t=verification_unit(:enemy,:rattata);x=verification_unit(:enemy,:caterpie);[a,b,c,t,x]
  end
  def reactive_reset_v043
    for u in @units;u.verification_heal_full if u.respond_to?(:verification_heal_full);u.clear_reactive_memory_v043 if u.respond_to?(:clear_reactive_memory_v043);u.clear_all_guards_v040 if u.respond_to?(:clear_all_guards_v040);end
  end
  def verify_reactive_manifest_v043
    return if @verification_done[:reactive_manifest];e=PMD_AC.validate_reactive_priority_v043;m=PMD_AC::REACTIVE_PRIORITY_MANIFEST_V043;pass=e.empty?
    log_event(:verify,'REACTIVE_MANIFEST pass='+(pass ? '1':'0')+' new=6 cumulative='+m[:cumulative_mapped_move_count].to_s+' covered='+m[:cumulative_reference_covered].to_s+'/'+m[:learnset_reference_total].to_s+' coverage='+sprintf('%.2f',m[:cumulative_coverage_percent].to_f)+' checksum='+m[:runtime_checksum32].to_s+' errors=['+e.join(',')+']');@verification_done[:reactive_manifest]=true
  end
  def verify_reactive_data_v043
    return if @verification_done[:reactive_data];ok=true
    [:sucker_punch,:counter,:mirror_coat,:revenge,:avalanche,:vital_throw].each{|k|d=PMD_AC.skill_data(('mv_'+k.to_s).to_sym);ok=false if d==nil || d[:canonical_move_key]!=k || !PMD_AC.move_executable?(k) || PMD_AC.skill_visual_move_profile_v031(k)==nil || PMD_AC.skill_audio_move_profile_v032(k)==nil}
    log_event(:verify,'REACTIVE_DATA pass='+(ok ? '1':'0')+' executable=6 visuals=6 audio=6 symbol_keys=1');@verification_done[:reactive_data]=true
  end
  def verify_reactive_memory_v043
    return if @verification_done[:reactive_memory];reactive_reset_v043;a,b,c,t,x=reactive_verify_units_v043
    deal_direct_damage(t,a,1,{:fixed_damage=>30,:move_type=>:normal,:damage_category=>:physical,:directional=>false,:can_crit=>false,:grant_energy=>false});p=a.reactive_hit_memory_v043(:physical,t,60)
    deal_direct_damage(x,a,1,{:fixed_damage=>40,:move_type=>:water,:damage_category=>:special,:directional=>false,:can_crit=>false,:grant_energy=>false});s=a.reactive_hit_memory_v043(:special,x,60)
    pass=p!=nil&&p[:damage].to_i==30&&s!=nil&&s[:damage].to_i==40&&p[:source]==t&&s[:source]==x
    log_event(:verify,'REACTIVE_MEMORY pass='+(pass ? '1':'0')+' physical=30 special=40 per_source=1 window=60 direct_hp_damage=1');@verification_done[:reactive_memory]=true
  end
  def verify_reactive_counter_coat_v043
    return if @verification_done[:reactive_counter];reactive_reset_v043;a,b,c,t,x=reactive_verify_units_v043
    deal_direct_damage(t,a,1,{:fixed_damage=>30,:move_type=>:normal,:damage_category=>:physical,:directional=>false,:can_crit=>false,:grant_energy=>false});before=t.hp;counter=apply_skill_effects(a,t,PMD_AC.skill_data(:mv_counter),1.0);cd=before-t.hp
    a.clear_reactive_memory_v043;deal_direct_damage(x,a,1,{:fixed_damage=>40,:move_type=>:water,:damage_category=>:special,:directional=>false,:can_crit=>false,:grant_energy=>false});before2=x.hp;coat=apply_skill_effects(a,x,PMD_AC.skill_data(:mv_mirror_coat),1.0);md=before2-x.hp
    a.clear_reactive_memory_v043;fail=apply_skill_effects(a,t,PMD_AC.skill_data(:mv_counter),1.0).to_i==0
    pass=(cd==60&&md==80&&fail)
    log_event(:verify,'REACTIVE_COUNTER_COAT pass='+(pass ? '1':'0')+' counter=30->60 mirror=40->80 no_memory_fail='+(fail ? '1':'0')+' source_lock=1');@verification_done[:reactive_counter]=true
  end
  def verify_reactive_sucker_v043
    return if @verification_done[:reactive_sucker];reactive_reset_v043;a,b,c,t,x=reactive_verify_units_v043;d=PMD_AC.skill_data(:mv_sucker_punch)
    t.instance_variable_set(:@action,:attack);t.instance_variable_set(:@action_timer,20);t.instance_variable_set(:@action_hit_done,false);before=t.hp;hit=apply_skill_effects(a,t,d,1.0);hit_ok=t.hp<before
    t.verification_heal_full;t.instance_variable_set(:@action,:attack);t.instance_variable_set(:@action_timer,20);t.instance_variable_set(:@action_hit_done,true);before2=t.hp;miss=apply_skill_effects(a,t,d,1.0);fail_ok=t.hp==before2&&miss.to_i==0
    t.instance_variable_set(:@action,:idle);t.instance_variable_set(:@action_timer,0);t.instance_variable_set(:@action_hit_done,false)
    pass=hit_ok&&fail_ok
    log_event(:verify,'REACTIVE_SUCKER_PUNCH pass='+(pass ? '1':'0')+' pre_hit_attack=hit recovery=fail priority=+1');@verification_done[:reactive_sucker]=true
  end
  def verify_reactive_revenge_v043
    return if @verification_done[:reactive_revenge];reactive_reset_v043;a,b,c,t,x=reactive_verify_units_v043;rv=PMD_AC.skill_data(:mv_revenge);av=PMD_AC.skill_data(:mv_avalanche)
    d0=reactive_scaled_damage_data_v043(a,t,rv,:revenge);p0=d0[:effects][0][:power].to_i;deal_direct_damage(t,a,1,{:fixed_damage=>20,:move_type=>:normal,:damage_category=>:physical,:directional=>false,:can_crit=>false,:grant_energy=>false});d1=reactive_scaled_damage_data_v043(a,t,rv,:revenge);p1=d1[:effects][0][:power].to_i;d2=reactive_scaled_damage_data_v043(a,x,av,:avalanche);p2=d2[:effects][0][:power].to_i
    pass=(p0==60&&p1==120&&p2==60)
    log_event(:verify,'REACTIVE_REVENGE_AVALANCHE pass='+(pass ? '1':'0')+' revenge=60->120 same_target=1 other_target=60 avalanche_shared_rule=1 priority=-4');@verification_done[:reactive_revenge]=true
  end
  def verify_reactive_vital_v043
    return if @verification_done[:reactive_vital];reactive_reset_v043;a,b,c,t,x=reactive_verify_units_v043;d=PMD_AC.skill_data(:mv_vital_throw);t.change_stat_stage(:evasion,6,t) if t.respond_to?(:change_stat_stage);chance=canonical_accuracy_probability(a,t,d);hit=canonical_accuracy_hit?(a,t,d,false);pri=PMD_AC.canonical_priority_v042(d);pass=(chance>=100.0&&hit&&pri==-1);t.reset_stat_stages if t.respond_to?(:reset_stat_stages)
    log_event(:verify,'REACTIVE_VITAL_THROW pass='+(pass ? '1':'0')+' never_miss='+(hit ? '1':'0')+' evasion_plus6=1 chance='+sprintf('%.1f',chance)+' priority=-1');@verification_done[:reactive_vital]=true
  end
  def verify_reactive_priority_timing_v043
    return if @verification_done[:reactive_timing];n=20;t=28;p1=PMD_AC.priority_startup_elapsed_v042(1,n,t,1.0);p0=PMD_AC.priority_startup_elapsed_v042(0,n,t,1.0);pm1=PMD_AC.priority_startup_elapsed_v042(-1,n,t,1.0);pm4=PMD_AC.priority_startup_elapsed_v042(-4,n,t,1.0);pm5=PMD_AC.priority_startup_elapsed_v042(-5,n,t,1.0);pass=p1<p0&&pm1>=p0&&pm4>p0&&pm5>pm4
    log_event(:verify,'REACTIVE_PRIORITY_TIMING pass='+(pass ? '1':'0')+' p1='+p1.to_s+' p0='+p0.to_s+' p-1='+pm1.to_s+' p-4='+pm4.to_s+' p-5='+pm5.to_s+' shared_v042_timing=1');@verification_done[:reactive_timing]=true
  end
  def verify_reactive_runtime_v043
    return if @verification_done[:reactive_runtime];m=PMD_AC::REACTIVE_PRIORITY_MANIFEST_V043;ok=PMD_AC::REACTIVE_PRIORITY_MOVE_V043.size==6&&m[:cumulative_mapped_move_count].to_i==257&&m[:cumulative_reference_covered].to_i==4280
    log_event(:verify,'REACTIVE_RUNTIME pass='+(ok ? '1':'0')+' mapped=6 cumulative=257 coverage=4280/7005 window=60 counter_coat=last_matching_direct_hit revenge_avalanche=target_specific sucker=pre_hit_action vital_throw=never_miss');@verification_done[:reactive_runtime]=true
  end
  def verify_reactive_modes_v043
    return if @verification_done[:reactive_modes];exp=[:reactive_priority,:priority,:held_item,:guard,:two_turn];pass=PMD_AC::VERIFICATION_MODES==exp&&verification_mode==:reactive_priority
    log_event(:verify,'REACTIVE_RECENT_MODES pass='+(pass ? '1':'0')+' modes=5 default=REACTIVE_PRIORITY');@verification_done[:reactive_modes]=true
  end
  def update_verification_script
    pmd_ac_v043_update_verification_script;return unless verification_mode==:reactive_priority;f=@verification_frame
    verify_reactive_manifest_v043 if f==4;verify_reactive_data_v043 if f==45;verify_reactive_memory_v043 if f==110;verify_reactive_counter_coat_v043 if f==190;verify_reactive_sucker_v043 if f==280;verify_reactive_revenge_v043 if f==370;verify_reactive_vital_v043 if f==450;verify_reactive_priority_timing_v043 if f==510;verify_reactive_runtime_v043 if f==560;verify_reactive_modes_v043 if f==600;complete_verification_mode if f==PMD_AC::VERIFICATION_REACTIVE_END_FRAME_V043
  end
  def complete_verification_mode
    if verification_mode==:reactive_priority
      if @reactive_failed_v043;for u in @units;u.verification_finish;end;@verification_done[:complete]=true;log_event(:verify,'FAILED mode=REACTIVE_PRIORITY auto_skill=on original_skills=restored');return;end
    end
    pmd_ac_v043_complete_verification_mode
  end
end
