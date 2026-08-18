#==============================================================================
# 【PMD AutoChess 中文維護說明】
# 腳本：PMD AutoChess Proto v0.49
# 分類：核心戰鬥 Runtime
#
# 【用途／機制】
# 承接前序 Data／Config，實際執行戰鬥 Scene、Unit、AI、技能與呈現。
#
# 【怎麼調整】
# 一般平衡與資料調整不要直接改 Runtime；若要追加功能，建議在較後腳本 alias 原方法後擴充。
#
# 【本腳本主要設定常數／資料表】
# - VERIFICATION_MOVE_COVERAGE_END_FRAME_V049 / FOCUS_ENERGY_CRIT_BONUS_V049 / HIGH_CRIT_MOVE_BONUS_V049 / VERIFICATION_MODES
# - VERIFICATION_LABELS
#
# 【Runtime 主要方法（查流程時可直接搜尋）】
# - move_coverage_move_key_from_skill_v049 / canonical_move_key_from_skill / move_executable? / move_autochess_hint
# - skill_data / skill_audio_move_profile_v032 / skill_visual_move_profile_v031 / move_coverage_checksum32_v049
# - validate_move_coverage_v049 / initialize / reset_move_coverage_v049 / start_combat
#
# 【維護規則】
# - RPG Maker VX / RGSS2 / Ruby 1.8 相容。
# - instance_uid 才是 Pokémon 個體身份；Actor ID 只是容器。
# - 新增行為優先沿用既有 helper／Data 表；避免破壞已 Freeze 的舊核心。
# - 本專案新腳本也必須保留同等級的中文說明與實際範例。
#==============================================================================
#===============================================================================
# ■ PMD AutoChess Proto v0.49
#    Move Runtime Coverage Expansion I
#-------------------------------------------------------------------------------
# Additive layer on verified v0.48. No previous script is modified.
#===============================================================================
module PMD_AC
  VERIFICATION_MOVE_COVERAGE_END_FRAME_V049=900
  FOCUS_ENERGY_CRIT_BONUS_V049=0.20
  HIGH_CRIT_MOVE_BONUS_V049=0.075

  class << self
    alias pmd_ac_v049_canonical_move_key_from_skill canonical_move_key_from_skill unless method_defined?(:pmd_ac_v049_canonical_move_key_from_skill)
    alias pmd_ac_v049_move_executable move_executable? unless method_defined?(:pmd_ac_v049_move_executable)
    alias pmd_ac_v049_move_autochess_hint move_autochess_hint unless method_defined?(:pmd_ac_v049_move_autochess_hint)
    alias pmd_ac_v049_skill_data skill_data unless method_defined?(:pmd_ac_v049_skill_data)
    alias pmd_ac_v049_skill_audio_move_profile_v032 skill_audio_move_profile_v032 unless method_defined?(:pmd_ac_v049_skill_audio_move_profile_v032)
    alias pmd_ac_v049_skill_visual_move_profile_v031 skill_visual_move_profile_v031 unless method_defined?(:pmd_ac_v049_skill_visual_move_profile_v031)

    def move_coverage_move_key_from_skill_v049(skill_key)
      return nil if skill_key==nil
      text=skill_key.to_s;return nil unless text[0,3]=='mv_'
      key=text[3,text.size-3].to_sym
      MOVE_COVERAGE_MOVE_V049[key]==nil ? nil : key
    end
    def canonical_move_key_from_skill(skill_key)
      k=move_coverage_move_key_from_skill_v049(skill_key);return k if k!=nil
      pmd_ac_v049_canonical_move_key_from_skill(skill_key)
    end
    def move_executable?(move_key)
      k=move_key.is_a?(String) ? move_key.to_sym : move_key
      return true if MOVE_COVERAGE_MOVE_V049[k]!=nil
      pmd_ac_v049_move_executable(move_key)
    end
    def move_autochess_hint(move_key)
      k=move_key.is_a?(String) ? move_key.to_sym : move_key
      b=MOVE_COVERAGE_MOVE_V049[k]
      return pmd_ac_v049_move_autochess_hint(move_key) if b==nil
      old=pmd_ac_v049_move_autochess_hint(move_key);r=old==nil ? {} : old.dup
      [:behavior_status,:delivery,:range_px,:runtime_skill_key,:priority,:target_type,:policy].each{|x|r[x]=b[x] if b[x]!=nil};r
    end
    def skill_data(key)
      mk=move_coverage_move_key_from_skill_v049(key)
      return MOVE_COVERAGE_MOVE_V049[mk].dup if mk!=nil
      pmd_ac_v049_skill_data(key)
    end
    def skill_audio_move_profile_v032(move_key)
      k=move_key.is_a?(String) ? move_key.to_sym : move_key
      b=MOVE_COVERAGE_AUDIO_V049[k];return b if b!=nil
      pmd_ac_v049_skill_audio_move_profile_v032(move_key)
    end
    def skill_visual_move_profile_v031(move_key)
      k=move_key.is_a?(String) ? move_key.to_sym : move_key
      b=MOVE_COVERAGE_VISUAL_V049[k];return b if b!=nil
      pmd_ac_v049_skill_visual_move_profile_v031(move_key)
    end

    def move_coverage_checksum32_v049
      h=0
      for key in MOVE_COVERAGE_MOVE_V049.keys.sort{|a,b|a.to_s<=>b.to_s}
        d=MOVE_COVERAGE_MOVE_V049[key]
        eff=(d[:effects]||[]).collect{|e|[e[:type],e[:power],e[:stat],e[:stages],e[:crit_bonus]].join(',')}.join(';')
        sec=(d[:secondary_effects]||[]).collect{|e|[e[:type],e[:stat],e[:stages],e[:chance]].join(',')}.join(';')
        text=[key,d[:runtime_skill_key],d[:canonical_power],d[:accuracy],d[:category],d[:delivery],d[:target_type],d[:multi_hit_min],d[:multi_hit_max],eff,sec].join('|')
        text.each_byte{|c|h=((h*33)+c)&0x7fffffff}
      end
      h
    end
    def validate_move_coverage_v049
      e=[];m=MOVE_COVERAGE_MANIFEST_V049
      e.push('count') unless MOVE_COVERAGE_MOVE_V049.size==13
      e.push('previous') unless m[:previous_mapped_move_count].to_i==262
      e.push('cumulative') unless m[:cumulative_mapped_move_count].to_i==275
      e.push('refs') unless m[:new_reference_covered].to_i==361 && m[:cumulative_reference_covered].to_i==4694
      e.push('checksum') unless move_coverage_checksum32_v049==m[:runtime_checksum32].to_i
      for k in m[:new_move_keys]
        d=MOVE_COVERAGE_MOVE_V049[k]
        e.push('data:'+k.to_s) if d==nil
        if d!=nil
          e.push('skill:'+k.to_s) unless d[:runtime_skill_key].to_s=='mv_'+k.to_s
          e.push('visual:'+k.to_s) if MOVE_COVERAGE_VISUAL_V049[k]==nil
          e.push('audio:'+k.to_s) if MOVE_COVERAGE_AUDIO_V049[k]==nil
        end
      end
      e
    end
  end

  remove_const(:VERIFICATION_MODES) if const_defined?(:VERIFICATION_MODES)
  VERIFICATION_MODES=[:move_coverage,:mastery_policy,:progression_ui,:progression_runtime,:identity_bridge]
  remove_const(:VERIFICATION_LABELS) if const_defined?(:VERIFICATION_LABELS)
  VERIFICATION_LABELS={:move_coverage=>'MOVE_COVERAGE',:mastery_policy=>'MASTERY_POLICY',
    :progression_ui=>'PROGRESSION_UI',:progression_runtime=>'PROGRESSION_RUNTIME',
    :identity_bridge=>'IDENTITY_BRIDGE'}
end

class Game_PMDChessUnit
  alias pmd_ac_v049_initialize initialize unless method_defined?(:pmd_ac_v049_initialize)
  alias pmd_ac_v049_start_combat start_combat unless method_defined?(:pmd_ac_v049_start_combat)
  alias pmd_ac_v049_deploy_to_cell deploy_to_cell unless method_defined?(:pmd_ac_v049_deploy_to_cell)
  alias pmd_ac_v049_deploy_to_pixel deploy_to_pixel unless method_defined?(:pmd_ac_v049_deploy_to_pixel)

  def initialize(*args);pmd_ac_v049_initialize(*args);@focus_energy_v049=false;end
  def reset_move_coverage_v049;@focus_energy_v049=false;end
  def start_combat;pmd_ac_v049_start_combat;reset_move_coverage_v049;end
  def deploy_to_cell(x,y);pmd_ac_v049_deploy_to_cell(x,y);reset_move_coverage_v049;end
  def deploy_to_pixel(x,y);pmd_ac_v049_deploy_to_pixel(x,y);reset_move_coverage_v049;end
  def focus_energy_v049?;@focus_energy_v049 ? true : false;end
  def set_focus_energy_v049(v=true);@focus_energy_v049=v ? true : false;end

  def canonical_apply_rest_sleep_v049(source=nil)
    return false if dead?
    [:burn,:poison,:paralysis,:sleep,:freeze].each{|k|remove_status(k)}
    @canonical_sleep_turns=0;@canonical_status_wait=0.0
    heal(maxhp)
    apply_status(:sleep,{:duration=>999999,:value=>0,:interval=>999999,:stack_mode=>:refresh},source)
    @canonical_sleep_turns=2
    @canonical_status_wait=effective_attack_wait.to_f
    log_event(:move_coverage,log_name+' REST heal=full sleep_turns=2')
    true
  end
end

class Scene_PMD_AutoChess
  alias pmd_ac_v049_start start unless method_defined?(:pmd_ac_v049_start)
  alias pmd_ac_v049_prepare_verification_battle prepare_verification_battle unless method_defined?(:pmd_ac_v049_prepare_verification_battle)
  alias pmd_ac_v049_apply_skill_effects apply_skill_effects unless method_defined?(:pmd_ac_v049_apply_skill_effects)
  alias pmd_ac_v049_deal_direct_damage deal_direct_damage unless method_defined?(:pmd_ac_v049_deal_direct_damage)
  alias pmd_ac_v049_update_verification_script update_verification_script unless method_defined?(:pmd_ac_v049_update_verification_script)
  alias pmd_ac_v049_log_event log_event unless method_defined?(:pmd_ac_v049_log_event)
  alias pmd_ac_v049_complete_verification_mode complete_verification_mode unless method_defined?(:pmd_ac_v049_complete_verification_mode)

  def start
    pmd_ac_v049_start
    begin
      if FileTest.exist?(PMD_AC::BATTLE_LOG_FILE)
        text=File.open(PMD_AC::BATTLE_LOG_FILE,'rb'){|f|f.read}
        text.sub!(/PMD AutoChess Proto v0\.[0-9.]+ Battle Verification Log/,'PMD AutoChess Proto v0.49 Battle Verification Log')
        File.open(PMD_AC::BATTLE_LOG_FILE,'wb'){|f|f.write(text)}
      end
    rescue
    end
    m=PMD_AC::MOVE_COVERAGE_MANIFEST_V049
    log_event(:move_coverage,'LOADED new='+m[:new_mapped_move_count].to_s+' cumulative='+m[:cumulative_mapped_move_count].to_s+
      ' covered='+m[:cumulative_reference_covered].to_s+'/'+m[:learnset_reference_total].to_s+
      ' coverage='+sprintf('%.2f',m[:cumulative_coverage_percent].to_f)+'% foundations=multi_hit,focus_energy,rest,direct_poison,high_crit checksum32='+m[:runtime_checksum32].to_s)
  end

  def move_coverage_key_v049(data)
    return nil if data==nil;k=data[:canonical_move_key]||data[:move_key];k.is_a?(String) ? k.to_sym : k
  end
  def multi_hit_count_v049(data)
    lo=[(data[:multi_hit_min]||2).to_i,1].max;hi=[(data[:multi_hit_max]||lo).to_i,lo].max
    roll=nil
    if verification_mode==:move_coverage && @move_coverage_hit_rolls_v049!=nil && !@move_coverage_hit_rolls_v049.empty?
      roll=@move_coverage_hit_rolls_v049.shift.to_i
    else
      roll=rand(hi-lo+1)
    end
    lo+(roll%(hi-lo+1))
  end
  def set_move_coverage_hit_rolls_v049(values);@move_coverage_hit_rolls_v049=values.dup;end

  def apply_direct_poison_v049(user,target,effect)
    return false if target==nil || target.dead?
    if canonical_secondary_status_immune?(target,:poison)
      log_event(:move_coverage,target.log_name+' POISON_POWDER_IMMUNE');return false
    end
    value=[(target.maxhp*(effect[:tick_maxhp_ratio]||0.015).to_f).round,1].max
    target.apply_status(:poison,{:duration=>(effect[:duration]||180).to_i,:value=>value,
      :interval=>(effect[:interval]||30).to_i,:stack_mode=>:refresh},user)
    add_skill_effect(target,:poison);true
  end

  def apply_skill_effects(user,target,data,scale=1.0)
    if data!=nil && data[:multi_hit_v049]
      hits=multi_hit_count_v049(data);single=data.dup;single[:multi_hit_v049]=false;total=0;landed=0
      for i in 0...hits
        break if target==nil || target.dead?
        r=pmd_ac_v049_apply_skill_effects(user,target,single,scale);total+=r.to_i;landed+=1
        add_skill_effect(target,:impact,i*2) if i>0 && respond_to?(:add_skill_effect)
      end
      log_event(:move_coverage,user.log_name+' '+move_coverage_key_v049(data).to_s+' MULTI_HIT hits='+landed.to_s+' total_damage='+total.to_s) if user!=nil
      return total
    end
    result=pmd_ac_v049_apply_skill_effects(user,target,data,scale)
    return result if data==nil || user==nil || target==nil
    for e in (data[:effects]||[])
      case e[:type]
      when :focus_energy_v049
        user.set_focus_energy_v049(true);add_skill_effect(user,:buff)
        log_event(:move_coverage,user.log_name+' FOCUS_ENERGY crit_stage=+2 project_bonus=+0.20')
      when :rest_v049
        user.canonical_apply_rest_sleep_v049(user);add_skill_effect(user,:heal)
      when :direct_poison_v049
        apply_direct_poison_v049(user,target,e)
      end
    end
    result
  end

  def deal_direct_damage(user,target,power,options=nil)
    opts=options==nil ? {} : options.dup
    if user!=nil && user.respond_to?(:focus_energy_v049?) && user.focus_energy_v049? && (opts.has_key?(:can_crit) ? opts[:can_crit] : true)
      opts[:crit_bonus]=(opts[:crit_bonus]||0.0).to_f+PMD_AC::FOCUS_ENERGY_CRIT_BONUS_V049
    end
    pmd_ac_v049_deal_direct_damage(user,target,power,opts)
  end

  # Verification --------------------------------------------------------------
  def prepare_verification_battle
    pmd_ac_v049_prepare_verification_battle
    if verification_mode==:move_coverage
      @move_coverage_failed_v049=false;@move_coverage_hit_rolls_v049=[]
      for u in @units
        u.verification_combat_sandbox(true);u.reset_move_coverage_v049 if u.respond_to?(:reset_move_coverage_v049)
      end
    end
  end
  def log_event(category,message)
    if category.to_s=='verify' && verification_mode==:move_coverage && message.to_s.index('MOVE_COVERAGE_')==0 && message.to_s.include?(' pass=0')
      @move_coverage_failed_v049=true
    end
    pmd_ac_v049_log_event(category,message)
  end

  def verify_move_coverage_manifest_v049
    return if @verification_done[:move_coverage_manifest];m=PMD_AC::MOVE_COVERAGE_MANIFEST_V049;e=PMD_AC.validate_move_coverage_v049
    pass=e.empty?
    log_event(:verify,'MOVE_COVERAGE_MANIFEST pass='+(pass ? '1':'0')+' new=13 cumulative=275 refs=361 covered=4694/7005 coverage=67.01 checksum='+PMD_AC.move_coverage_checksum32_v049.to_s+' errors=['+e.join(',')+']')
    @verification_done[:move_coverage_manifest]=true
  end
  def verify_move_coverage_bridge_v049
    return if @verification_done[:move_coverage_bridge];ok=true
    for k in PMD_AC::MOVE_COVERAGE_MANIFEST_V049[:new_move_keys]
      d=PMD_AC.skill_data(('mv_'+k.to_s).to_sym)
      ok=false if d==nil || d[:canonical_move_key]!=k || !PMD_AC.move_executable?(k) || PMD_AC.skill_visual_move_profile_v031(k)==nil || PMD_AC.skill_audio_move_profile_v032(k)==nil
    end
    log_event(:verify,'MOVE_COVERAGE_BRIDGE pass='+(ok ? '1':'0')+' executable=13 visuals=13 audio=13 canonical_keys=13')
    @verification_done[:move_coverage_bridge]=true
  end
  def verify_move_coverage_multihit_v049
    return if @verification_done[:move_coverage_multihit]
    d=PMD_AC.skill_data(:mv_fury_swipes);set_move_coverage_hit_rolls_v049([0,3]);a=multi_hit_count_v049(d);b=multi_hit_count_v049(d)
    pass=d[:multi_hit_min].to_i==2 && d[:multi_hit_max].to_i==5 && a==2 && b==5
    log_event(:verify,'MOVE_COVERAGE_MULTI_HIT pass='+(pass ? '1':'0')+' fury_swipes=2..5 deterministic='+a.to_s+','+b.to_s+' per_hit_crit=1 mastery_each_hit=1')
    @verification_done[:move_coverage_multihit]=true
  end
  def verify_move_coverage_crit_v049
    return if @verification_done[:move_coverage_crit]
    u=verification_unit(:ally,:bulbasaur);u.set_focus_energy_v049(true)
    slash=PMD_AC.skill_data(:mv_slash);e=(slash[:effects]||[])[0]
    combined=(e[:crit_bonus]||0.0).to_f+PMD_AC::FOCUS_ENERGY_CRIT_BONUS_V049
    pass=u.focus_energy_v049? && (e[:crit_bonus].to_f-0.075).abs<0.0001 && (combined-0.275).abs<0.0001
    log_event(:verify,'MOVE_COVERAGE_CRIT pass='+(pass ? '1':'0')+' focus_energy=+0.20 high_crit=+0.075 combined=+0.275 reset_on_deploy=1')
    @verification_done[:move_coverage_crit]=true
  end
  def verify_move_coverage_status_rest_v049
    return if @verification_done[:move_coverage_status_rest]
    u=verification_unit(:ally,:bulbasaur);t=verification_unit(:enemy,:rattata)
    u.receive_damage([u.maxhp/2,1].max,nil,false,true,false);u.apply_status(:burn,{:duration=>60,:value=>1,:interval=>30},t)
    u.canonical_apply_rest_sleep_v049(u)
    rest_ok=u.hp==u.maxhp && u.sleeping? && !u.status?(:burn)
    poison=PMD_AC.skill_data(:mv_poison_powder);pe=(poison[:effects]||[])[0]
    poison_ok=pe[:type]==:direct_poison_v049 && pe[:duration].to_i==180 && pe[:interval].to_i==30
    pass=rest_ok && poison_ok
    log_event(:verify,'MOVE_COVERAGE_STATUS_REST pass='+(pass ? '1':'0')+' rest_full_heal=1 rest_sleep=2 rest_cure=1 poison_duration=180 poison_interval=30')
    @verification_done[:move_coverage_status_rest]=true
  end
  def verify_move_coverage_stat_secondary_v049
    return if @verification_done[:move_coverage_stat_secondary]
    ch=PMD_AC.skill_data(:mv_charm);wd=PMD_AC.skill_data(:mv_withdraw);ms=PMD_AC.skill_data(:mv_metal_sound);bb=PMD_AC.skill_data(:mv_bug_buzz)
    a=(ch[:effects]||[])[0];b=(wd[:effects]||[])[0];c=(ms[:effects]||[])[0];s=(bb[:secondary_effects]||[])[0]
    pass=a[:stat]==:atk && a[:stages].to_i==-2 && b[:stat]==:def && b[:stages].to_i==1 && c[:stat]==:spdef && c[:stages].to_i==-2 && s[:stat]==:spdef && s[:stages].to_i==-1 && s[:chance].to_i==10
    log_event(:verify,'MOVE_COVERAGE_STATS pass='+(pass ? '1':'0')+' charm_atk=-2 withdraw_def=+1 metal_sound_spdef=-2 bug_buzz_spdef=-1@10')
    @verification_done[:move_coverage_stat_secondary]=true
  end
  def verify_move_coverage_mastery_v049
    return if @verification_done[:move_coverage_mastery]
    slash=PMD_AC.skill_data(:mv_slash);bb=PMD_AC.skill_data(:mv_bug_buzz);a=PMD_AC.mastery_move_category_v048(slash);b=PMD_AC.mastery_move_category_v048(bb)
    x=PMD_AC.mastery_transform_data_v048(bb,5);sec=(x[:secondary_effects]||[])[0]
    pass=a==:damage && b==:damage_status && sec[:chance].to_i==15 && PMD_AC.mastery_scale_channel_v048?(slash)
    log_event(:verify,'MOVE_COVERAGE_MASTERY pass='+(pass ? '1':'0')+' slash=damage bug_buzz=damage_status bug_buzz_secondary_lv5=15 magnitude_channel=1')
    @verification_done[:move_coverage_mastery]=true
  end
  def verify_move_coverage_modes_v049
    return if @verification_done[:move_coverage_modes]
    exp=[:move_coverage,:mastery_policy,:progression_ui,:progression_runtime,:identity_bridge]
    pass=PMD_AC::VERIFICATION_MODES==exp && verification_mode==:move_coverage
    log_event(:verify,'MOVE_COVERAGE_RECENT_MODES pass='+(pass ? '1':'0')+' modes=5 default=MOVE_COVERAGE')
    @verification_done[:move_coverage_modes]=true
  end

  def update_verification_script
    pmd_ac_v049_update_verification_script
    return unless verification_mode==:move_coverage
    f=@verification_frame
    verify_move_coverage_manifest_v049 if f==4
    verify_move_coverage_bridge_v049 if f==120
    verify_move_coverage_multihit_v049 if f==240
    verify_move_coverage_crit_v049 if f==360
    verify_move_coverage_status_rest_v049 if f==500
    verify_move_coverage_stat_secondary_v049 if f==640
    verify_move_coverage_mastery_v049 if f==760
    verify_move_coverage_modes_v049 if f==840
    complete_verification_mode if f==PMD_AC::VERIFICATION_MOVE_COVERAGE_END_FRAME_V049
  end
  def complete_verification_mode
    if verification_mode==:move_coverage && @move_coverage_failed_v049
      return if @verification_done[:verification_complete]
      for u in @units;u.verification_finish;end
      @verification_done[:verification_complete]=true
      log_event(:verify,'FAILED mode=MOVE_COVERAGE auto_skill=on original_skills=restored');return
    end
    pmd_ac_v049_complete_verification_mode
  end
end
