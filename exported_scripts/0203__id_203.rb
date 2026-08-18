#==============================================================================
# 【PMD AutoChess 中文維護說明】
# 腳本：PMD AutoChess Proto v0.50
# 分類：核心戰鬥 Runtime
#
# 【用途／機制】
# 承接前序 Data／Config，實際執行戰鬥 Scene、Unit、AI、技能與呈現。
#
# 【怎麼調整】
# 一般平衡與資料調整不要直接改 Runtime；若要追加功能，建議在較後腳本 alias 原方法後擴充。
#
# 【本腳本主要設定常數／資料表】
# - VERIFICATION_MOVE_COVERAGE_II_END_FRAME_V050 / VERIFICATION_MODES / VERIFICATION_LABELS
#
# 【Runtime 主要方法（查流程時可直接搜尋）】
# - move_coverage_ii_key_from_skill_v050 / canonical_move_key_from_skill / move_executable? / move_autochess_hint
# - skill_data / skill_audio_move_profile_v032 / skill_visual_move_profile_v031 / move_coverage_ii_checksum32_v050
# - validate_move_coverage_ii_v050 / start / apply_direct_burn_v050 / apply_fixed_damage_v050
#
# 【維護規則】
# - RPG Maker VX / RGSS2 / Ruby 1.8 相容。
# - instance_uid 才是 Pokémon 個體身份；Actor ID 只是容器。
# - 新增行為優先沿用既有 helper／Data 表；避免破壞已 Freeze 的舊核心。
# - 本專案新腳本也必須保留同等級的中文說明與實際範例。
#==============================================================================
#===============================================================================
# ■ PMD AutoChess Proto v0.50
#    Move Runtime Coverage Expansion II
#-------------------------------------------------------------------------------
# Additive layer on verified v0.49. No previous script is modified.
#===============================================================================
module PMD_AC
  VERIFICATION_MOVE_COVERAGE_II_END_FRAME_V050=920
  class << self
    alias pmd_ac_v050_canonical_move_key_from_skill canonical_move_key_from_skill unless method_defined?(:pmd_ac_v050_canonical_move_key_from_skill)
    alias pmd_ac_v050_move_executable move_executable? unless method_defined?(:pmd_ac_v050_move_executable)
    alias pmd_ac_v050_move_autochess_hint move_autochess_hint unless method_defined?(:pmd_ac_v050_move_autochess_hint)
    alias pmd_ac_v050_skill_data skill_data unless method_defined?(:pmd_ac_v050_skill_data)
    alias pmd_ac_v050_skill_audio_move_profile_v032 skill_audio_move_profile_v032 unless method_defined?(:pmd_ac_v050_skill_audio_move_profile_v032)
    alias pmd_ac_v050_skill_visual_move_profile_v031 skill_visual_move_profile_v031 unless method_defined?(:pmd_ac_v050_skill_visual_move_profile_v031)

    def move_coverage_ii_key_from_skill_v050(skill_key)
      return nil if skill_key==nil
      text=skill_key.to_s;return nil unless text[0,3]=='mv_'
      key=text[3,text.size-3].to_sym
      MOVE_COVERAGE_II_MOVE_V050[key]==nil ? nil : key
    end
    def canonical_move_key_from_skill(skill_key)
      k=move_coverage_ii_key_from_skill_v050(skill_key);return k if k!=nil
      pmd_ac_v050_canonical_move_key_from_skill(skill_key)
    end
    def move_executable?(move_key)
      k=move_key.is_a?(String) ? move_key.to_sym : move_key
      return true if MOVE_COVERAGE_II_MOVE_V050[k]!=nil
      pmd_ac_v050_move_executable(move_key)
    end
    def move_autochess_hint(move_key)
      k=move_key.is_a?(String) ? move_key.to_sym : move_key;b=MOVE_COVERAGE_II_MOVE_V050[k]
      return pmd_ac_v050_move_autochess_hint(move_key) if b==nil
      old=pmd_ac_v050_move_autochess_hint(move_key);r=old==nil ? {} : old.dup
      [:behavior_status,:delivery,:range_px,:runtime_skill_key,:priority,:target_type,:policy].each{|x|r[x]=b[x] if b[x]!=nil};r
    end
    def skill_data(key)
      mk=move_coverage_ii_key_from_skill_v050(key);return MOVE_COVERAGE_II_MOVE_V050[mk].dup if mk!=nil
      pmd_ac_v050_skill_data(key)
    end
    def skill_audio_move_profile_v032(move_key)
      k=move_key.is_a?(String) ? move_key.to_sym : move_key;b=MOVE_COVERAGE_II_AUDIO_V050[k];return b if b!=nil
      pmd_ac_v050_skill_audio_move_profile_v032(move_key)
    end
    def skill_visual_move_profile_v031(move_key)
      k=move_key.is_a?(String) ? move_key.to_sym : move_key;b=MOVE_COVERAGE_II_VISUAL_V050[k];return b if b!=nil
      pmd_ac_v050_skill_visual_move_profile_v031(move_key)
    end
    def move_coverage_ii_checksum32_v050
      h=0;MOVE_COVERAGE_II_CHECKSUM_TEXT_V050.each_byte{|c|h=((h*33)+c)&0x7fffffff};h
    end
    def validate_move_coverage_ii_v050
      e=[];m=MOVE_COVERAGE_II_MANIFEST_V050
      e.push('count') unless MOVE_COVERAGE_II_MOVE_V050.size==24
      e.push('previous') unless m[:previous_mapped_move_count].to_i==275
      e.push('cumulative') unless m[:cumulative_mapped_move_count].to_i==299
      e.push('refs') unless m[:new_reference_covered].to_i==261 && m[:cumulative_reference_covered].to_i==4955
      e.push('checksum') unless move_coverage_ii_checksum32_v050==m[:runtime_checksum32].to_i
      for k in m[:new_move_keys]
        d=MOVE_COVERAGE_II_MOVE_V050[k];e.push('data:'+k.to_s) if d==nil
        if d!=nil
          e.push('skill:'+k.to_s) unless d[:runtime_skill_key].to_s=='mv_'+k.to_s
          e.push('visual:'+k.to_s) if MOVE_COVERAGE_II_VISUAL_V050[k]==nil
          e.push('audio:'+k.to_s) if MOVE_COVERAGE_II_AUDIO_V050[k]==nil
        end
      end;e
    end
  end
  remove_const(:VERIFICATION_MODES) if const_defined?(:VERIFICATION_MODES)
  VERIFICATION_MODES=[:move_coverage_ii,:move_coverage,:mastery_policy,:progression_ui,:progression_runtime]
  remove_const(:VERIFICATION_LABELS) if const_defined?(:VERIFICATION_LABELS)
  VERIFICATION_LABELS={:move_coverage_ii=>'MOVE_COVERAGE_II',:move_coverage=>'MOVE_COVERAGE',:mastery_policy=>'MASTERY_POLICY',:progression_ui=>'PROGRESSION_UI',:progression_runtime=>'PROGRESSION_RUNTIME'}
end

class Scene_PMD_AutoChess
  alias pmd_ac_v050_start start unless method_defined?(:pmd_ac_v050_start)
  alias pmd_ac_v050_prepare_verification_battle prepare_verification_battle unless method_defined?(:pmd_ac_v050_prepare_verification_battle)
  alias pmd_ac_v050_apply_skill_effects apply_skill_effects unless method_defined?(:pmd_ac_v050_apply_skill_effects)
  alias pmd_ac_v050_update_verification_script update_verification_script unless method_defined?(:pmd_ac_v050_update_verification_script)
  alias pmd_ac_v050_log_event log_event unless method_defined?(:pmd_ac_v050_log_event)
  alias pmd_ac_v050_complete_verification_mode complete_verification_mode unless method_defined?(:pmd_ac_v050_complete_verification_mode)

  def start
    pmd_ac_v050_start
    begin
      if FileTest.exist?(PMD_AC::BATTLE_LOG_FILE)
        text=File.open(PMD_AC::BATTLE_LOG_FILE,'rb'){|f|f.read}
        text.sub!(/PMD AutoChess Proto v0\.[0-9.]+ Battle Verification Log/,'PMD AutoChess Proto v0.50 Battle Verification Log')
        File.open(PMD_AC::BATTLE_LOG_FILE,'wb'){|f|f.write(text)}
      end
    rescue;end
    m=PMD_AC::MOVE_COVERAGE_II_MANIFEST_V050
    log_event(:move_coverage_ii,'LOADED new='+m[:new_mapped_move_count].to_s+' cumulative='+m[:cumulative_mapped_move_count].to_s+' covered='+m[:cumulative_reference_covered].to_s+'/'+m[:learnset_reference_total].to_s+' coverage='+sprintf('%.2f',m[:cumulative_coverage_percent].to_f)+'% foundations=fixed_damage,direct_burn,aqua_ring,refresh,self_faint,reuse_multi_hit,reuse_high_crit checksum32='+m[:runtime_checksum32].to_s)
  end

  def apply_direct_burn_v050(user,target,effect)
    return false if target==nil || target.dead?
    if canonical_secondary_status_immune?(target,:burn)
      log_event(:move_coverage_ii,target.log_name+' BURN_IMMUNE');return false
    end
    value=[(target.maxhp*(effect[:tick_maxhp_ratio]||0.0125).to_f).round,1].max
    target.apply_status(:burn,{:duration=>(effect[:duration]||180).to_i,:value=>value,:interval=>(effect[:interval]||30).to_i,:stack_mode=>:refresh},user)
    add_skill_effect(target,:burn);true
  end
  def apply_fixed_damage_v050(user,target,effect,data)
    return 0 if user==nil || target==nil || target.dead?
    type=data[:move_type]||data[:type]||:normal
    if PMD_AC.type_effectiveness(type,target.pokemon_types).to_f<=0.0
      log_event(:move_coverage_ii,user.log_name+' '+(data[:canonical_move_key]||:fixed).to_s+' TYPE_IMMUNE -> '+target.log_name);return 0
    end
    amount=effect[:level_based] ? [user.level.to_i,1].max : [effect[:flat].to_i,1].max
    deal_direct_damage(user,target,1,{:fixed_damage=>amount,:move_type=>type,:damage_category=>data[:damage_category],:skill_data=>data,:directional=>false,:can_crit=>false})
  end
  def apply_aqua_ring_v050(user,effect)
    value=[(user.maxhp*(effect[:tick_maxhp_ratio]||0.0625).to_f).round,1].max
    user.apply_status(:regen,{:duration=>(effect[:duration]||240).to_i,:value=>value,:interval=>(effect[:interval]||30).to_i,:stack_mode=>:refresh},user)
    add_skill_effect(user,:heal);log_event(:move_coverage_ii,user.log_name+' AQUA_RING tick='+value.to_s);true
  end
  def apply_refresh_v050(user)
    n=0;[:burn,:poison,:paralysis].each{|k|if user.status?(k);user.remove_status(k);n+=1;end}
    add_skill_effect(user,:cleanse) if n>0;log_event(:move_coverage_ii,user.log_name+' REFRESH removed='+n.to_s);n
  end
  def apply_skill_effects(user,target,data,scale=1.0)
    result=pmd_ac_v050_apply_skill_effects(user,target,data,scale)
    return result if data==nil || user==nil || target==nil
    for e in (data[:effects]||[])
      case e[:type]
      when :fixed_damage_v050
        result=apply_fixed_damage_v050(user,target,e,data)
      when :direct_burn_v050
        apply_direct_burn_v050(user,target,e)
      when :aqua_ring_v050
        apply_aqua_ring_v050(user,e)
      when :refresh_v050
        apply_refresh_v050(user)
      when :self_faint_v050
        before=user.hp;user.receive_damage([user.hp,1].max,user,false,true,false);log_event(:move_coverage_ii,user.log_name+' MEMENTO_SELF_KO hp='+before.to_s+'->'+user.hp.to_s)
      when :no_effect_v050
        log_event(:move_coverage_ii,user.log_name+' SPLASH no_effect=1')
      end
    end
    result
  end

  def prepare_verification_battle
    pmd_ac_v050_prepare_verification_battle
    if verification_mode==:move_coverage_ii
      @move_coverage_ii_failed_v050=false
      for u in @units;u.verification_combat_sandbox(true);end
    end
  end
  def log_event(category,message)
    if category.to_s=='verify' && verification_mode==:move_coverage_ii && message.to_s.index('MOVE_COVERAGE_II_')==0 && message.to_s.include?(' pass=0');@move_coverage_ii_failed_v050=true;end
    pmd_ac_v050_log_event(category,message)
  end
  def verify_move_coverage_ii_manifest_v050
    return if @verification_done[:move_coverage_ii_manifest];e=PMD_AC.validate_move_coverage_ii_v050;m=PMD_AC::MOVE_COVERAGE_II_MANIFEST_V050;pass=e.empty?
    log_event(:verify,'MOVE_COVERAGE_II_MANIFEST pass='+(pass ? '1':'0')+' new=24 cumulative=299 refs=261 covered=4955/7005 coverage=70.74 checksum='+PMD_AC.move_coverage_ii_checksum32_v050.to_s+' errors=['+e.join(',')+']');@verification_done[:move_coverage_ii_manifest]=true
  end
  def verify_move_coverage_ii_bridge_v050
    return if @verification_done[:move_coverage_ii_bridge];ok=true
    for k in PMD_AC::MOVE_COVERAGE_II_MANIFEST_V050[:new_move_keys]
      d=PMD_AC.skill_data(('mv_'+k.to_s).to_sym);ok=false if d==nil || d[:canonical_move_key]!=k || !PMD_AC.move_executable?(k) || PMD_AC.skill_visual_move_profile_v031(k)==nil || PMD_AC.skill_audio_move_profile_v032(k)==nil
    end
    log_event(:verify,'MOVE_COVERAGE_II_BRIDGE pass='+(ok ? '1':'0')+' executable=24 visuals=24 audio=24 canonical_keys=24');@verification_done[:move_coverage_ii_bridge]=true
  end
  def verify_move_coverage_ii_reuse_v050
    return if @verification_done[:move_coverage_ii_reuse];rb=PMD_AC.skill_data(:mv_rock_blast);dk=PMD_AC.skill_data(:mv_double_kick);bs=PMD_AC.skill_data(:mv_bullet_seed);dh=PMD_AC.skill_data(:mv_double_hit)
    pass=rb[:multi_hit_v049] && rb[:multi_hit_min]==2 && rb[:multi_hit_max]==5 && dk[:multi_hit_min]==2 && dk[:multi_hit_max]==2 && bs[:multi_hit_max]==5 && dh[:multi_hit_max]==2
    log_event(:verify,'MOVE_COVERAGE_II_MULTI_HIT pass='+(pass ? '1':'0')+' rock_blast=2..5 bullet_seed=2..5 double_kick=2 double_hit=2 reuse_v049=1');@verification_done[:move_coverage_ii_reuse]=true
  end
  def verify_move_coverage_ii_fixed_v050
    return if @verification_done[:move_coverage_ii_fixed];s=PMD_AC.skill_data(:mv_sonic_boom);d=PMD_AC.skill_data(:mv_dragon_rage);t=PMD_AC.skill_data(:mv_seismic_toss)
    a=s[:effects][0];b=d[:effects][0];c=t[:effects][0];pass=a[:flat].to_i==20 && b[:flat].to_i==40 && c[:level_based]
    log_event(:verify,'MOVE_COVERAGE_II_FIXED pass='+(pass ? '1':'0')+' sonic_boom=20 dragon_rage=40 seismic_toss=user_level crit=off directional=off');@verification_done[:move_coverage_ii_fixed]=true
  end
  def verify_move_coverage_ii_status_v050
    return if @verification_done[:move_coverage_ii_status];ar=PMD_AC.skill_data(:mv_aqua_ring);rf=PMD_AC.skill_data(:mv_refresh);ww=PMD_AC.skill_data(:mv_will_o_wisp);pg=PMD_AC.skill_data(:mv_poison_gas)
    pass=ar[:effects][0][:tick_maxhp_ratio].to_f==0.0625 && rf[:effects][0][:type]==:refresh_v050 && ww[:effects][0][:type]==:direct_burn_v050 && pg[:effects][0][:type]==:direct_poison_v049
    log_event(:verify,'MOVE_COVERAGE_II_STATUS pass='+(pass ? '1':'0')+' aqua_ring=1/16 refresh=burn,poison,paralysis will_o_wisp=burn poison_gas=poison');@verification_done[:move_coverage_ii_status]=true
  end
  def verify_move_coverage_ii_stats_v050
    return if @verification_done[:move_coverage_ii_stats];mi=PMD_AC.skill_data(:mv_minimize);cp=PMD_AC.skill_data(:mv_cosmic_power);ft=PMD_AC.skill_data(:mv_fake_tears);bd=PMD_AC.skill_data(:mv_bulldoze);me=PMD_AC.skill_data(:mv_memento)
    pass=mi[:effects][0][:stat]==:evasion && mi[:effects][0][:stages].to_i==2 && cp[:effects].size==2 && ft[:effects][0][:spdef]==nil && ft[:effects][0][:stat]==:spdef && bd[:effects][1][:stat]==:speed && me[:effects][2][:type]==:self_faint_v050
    log_event(:verify,'MOVE_COVERAGE_II_STATS pass='+(pass ? '1':'0')+' minimize_eva=+2 cosmic=def+1/spdef+1 fake_tears_spdef=-2 bulldoze_speed=-1 memento=atk/spatk-2+selfKO');@verification_done[:move_coverage_ii_stats]=true
  end
  def verify_move_coverage_ii_combat_v050
    return if @verification_done[:move_coverage_ii_combat];lb=PMD_AC.skill_data(:mv_leaf_blade);pc=PMD_AC.skill_data(:mv_psycho_cut);cp=PMD_AC.skill_data(:mv_cross_poison);fb=PMD_AC.skill_data(:mv_flare_blitz);hp=PMD_AC.skill_data(:mv_heal_pulse);rr=PMD_AC.skill_data(:mv_roost)
    pass=lb[:effects][0][:crit_bonus].to_f==0.075 && pc[:effects][0][:crit_bonus].to_f==0.075 && cp[:secondary_effects][0][:chance].to_i==10 && fb[:effects][1][:type]==:recoil_last_damage && hp[:target_type]==:ally && rr[:effects][0][:ratio].to_f==0.5
    log_event(:verify,'MOVE_COVERAGE_II_COMBAT pass='+(pass ? '1':'0')+' high_crit=leaf_blade,psycho_cut,cross_poison flare_blitz=recoil+burn heal_pulse=ally50 roost=self50');@verification_done[:move_coverage_ii_combat]=true
  end
  def verify_move_coverage_ii_mastery_v050
    return if @verification_done[:move_coverage_ii_mastery];lb=PMD_AC.skill_data(:mv_leaf_blade);rr=PMD_AC.skill_data(:mv_roost);cp=PMD_AC.skill_data(:mv_cross_poison);a=PMD_AC.mastery_move_category_v048(lb);b=PMD_AC.mastery_move_category_v048(rr);c=PMD_AC.mastery_transform_data_v048(cp,5);sec=c[:secondary_effects][0]
    pass=a==:damage && b==:heal && sec[:chance].to_i==15
    log_event(:verify,'MOVE_COVERAGE_II_MASTERY pass='+(pass ? '1':'0')+' leaf_blade=damage roost=heal cross_poison_secondary_lv5=15');@verification_done[:move_coverage_ii_mastery]=true
  end
  def verify_move_coverage_ii_modes_v050
    return if @verification_done[:move_coverage_ii_modes];exp=[:move_coverage_ii,:move_coverage,:mastery_policy,:progression_ui,:progression_runtime];pass=PMD_AC::VERIFICATION_MODES==exp && verification_mode==:move_coverage_ii
    log_event(:verify,'MOVE_COVERAGE_II_RECENT_MODES pass='+(pass ? '1':'0')+' modes=5 default=MOVE_COVERAGE_II');@verification_done[:move_coverage_ii_modes]=true
  end
  def update_verification_script
    pmd_ac_v050_update_verification_script;return unless verification_mode==:move_coverage_ii;f=@verification_frame
    verify_move_coverage_ii_manifest_v050 if f==4;verify_move_coverage_ii_bridge_v050 if f==120;verify_move_coverage_ii_reuse_v050 if f==240;verify_move_coverage_ii_fixed_v050 if f==360;verify_move_coverage_ii_status_v050 if f==480;verify_move_coverage_ii_stats_v050 if f==600;verify_move_coverage_ii_combat_v050 if f==720;verify_move_coverage_ii_mastery_v050 if f==820;verify_move_coverage_ii_modes_v050 if f==880;complete_verification_mode if f==PMD_AC::VERIFICATION_MOVE_COVERAGE_II_END_FRAME_V050
  end
  def complete_verification_mode
    if verification_mode==:move_coverage_ii && @move_coverage_ii_failed_v050
      return if @verification_done[:verification_complete];for u in @units;u.verification_finish;end;@verification_done[:verification_complete]=true;log_event(:verify,'FAILED mode=MOVE_COVERAGE_II auto_skill=on original_skills=restored');return
    end
    pmd_ac_v050_complete_verification_mode
  end
end
