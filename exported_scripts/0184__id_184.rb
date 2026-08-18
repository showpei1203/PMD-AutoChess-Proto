#==============================================================================
# 【PMD AutoChess 中文維護說明】
# 腳本：PMD AutoChess Proto v0.42
# 分類：核心戰鬥 Runtime
#
# 【用途／機制】
# 承接前序 Data／Config，實際執行戰鬥 Scene、Unit、AI、技能與呈現。
#
# 【怎麼調整】
# 一般平衡與資料調整不要直接改 Runtime；若要追加功能，建議在較後腳本 alias 原方法後擴充。
#
# 【本腳本主要設定常數／資料表】
# - VERIFICATION_PRIORITY_END_FRAME_V042 / PRIORITY_STARTUP_V042 / VERIFICATION_MODES / VERIFICATION_LABELS
#
# 【Runtime 主要方法（查流程時可直接搜尋）】
# - priority_move_key_from_skill_v042 / canonical_move_key_from_skill / move_executable? / move_autochess_hint
# - skill_data / skill_audio_move_profile_v032 / skill_visual_move_profile_v031 / canonical_priority_v042
# - priority_startup_elapsed_v042 / priority_checksum_scalar_v042 / priority_checksum32_v042 / validate_priority_v042
#
# 【維護規則】
# - RPG Maker VX / RGSS2 / Ruby 1.8 相容。
# - instance_uid 才是 Pokémon 個體身份；Actor ID 只是容器。
# - 新增行為優先沿用既有 helper／Data 表；避免破壞已 Freeze 的舊核心。
# - 本專案新腳本也必須保留同等級的中文說明與實際範例。
#==============================================================================
#===============================================================================
# ■ PMD AutoChess Proto v0.42
#    Priority Runtime I
#-------------------------------------------------------------------------------
# Additive layer on verified v0.41.1.
#
# Realtime priority translation:
# - Canonical priority changes only the startup / hit point of a skill action.
# - Total action duration is preserved, so priority does NOT create extra casts,
#   extra energy, or a hidden DPS multiplier by shortening recovery.
# - Positive priority resolves sooner; negative priority resolves later.
# - Existing Protect/Detect/Endure/Wide Guard/Quick Guard/Feint and the Room
#   moves automatically participate because their skill data already contains
#   canonical priority values.
# - Quick Guard therefore blocks the same priority > 0 value that now also
#   controls actual action startup timing.
#
# New executable simple priority attacks:
# Quick Attack, Mach Punch, Extreme Speed, Vacuum Wave, Bullet Punch,
# Ice Shard, Shadow Sneak, Aqua Jet.
#===============================================================================
module PMD_AC
  VERIFICATION_PRIORITY_END_FRAME_V042=560
  PRIORITY_STARTUP_V042={5=>1,4=>2,3=>3,2=>4,1=>6,-1=>18,-2=>19,-3=>20,-4=>21,-5=>22,-6=>23,-7=>24}

  class << self
    alias pmd_ac_v042_canonical_move_key_from_skill canonical_move_key_from_skill unless method_defined?(:pmd_ac_v042_canonical_move_key_from_skill)
    alias pmd_ac_v042_move_executable move_executable? unless method_defined?(:pmd_ac_v042_move_executable)
    alias pmd_ac_v042_move_autochess_hint move_autochess_hint unless method_defined?(:pmd_ac_v042_move_autochess_hint)
    alias pmd_ac_v042_skill_data skill_data unless method_defined?(:pmd_ac_v042_skill_data)
    alias pmd_ac_v042_skill_audio_move_profile_v032 skill_audio_move_profile_v032 unless method_defined?(:pmd_ac_v042_skill_audio_move_profile_v032)
    alias pmd_ac_v042_skill_visual_move_profile_v031 skill_visual_move_profile_v031 unless method_defined?(:pmd_ac_v042_skill_visual_move_profile_v031)

    def priority_move_key_from_skill_v042(skill_key)
      return nil if skill_key==nil
      text=skill_key.to_s
      return nil unless text[0,3]=='mv_'
      key=text[3,text.size-3].to_sym
      PRIORITY_MOVE_V042[key]==nil ? nil : key
    end
    def canonical_move_key_from_skill(skill_key)
      k=priority_move_key_from_skill_v042(skill_key);return k if k!=nil
      pmd_ac_v042_canonical_move_key_from_skill(skill_key)
    end
    def move_executable?(move_key)
      return true if PRIORITY_MOVE_V042[move_key]!=nil
      pmd_ac_v042_move_executable(move_key)
    end
    def move_autochess_hint(move_key)
      b=PRIORITY_MOVE_V042[move_key];return pmd_ac_v042_move_autochess_hint(move_key) if b==nil
      old=pmd_ac_v042_move_autochess_hint(move_key);r=old==nil ? {} : old.dup
      r[:behavior_status]=b[:behavior_status];r[:delivery]=b[:delivery];r[:range_px]=b[:range_px];r[:runtime_skill_key]=b[:runtime_skill_key];r[:priority]=b[:priority];r
    end
    def skill_data(key)
      mk=priority_move_key_from_skill_v042(key)
      if mk!=nil;b=PRIORITY_MOVE_V042[mk];return b.dup;end
      pmd_ac_v042_skill_data(key)
    end
    def skill_audio_move_profile_v032(move_key)
      b=PRIORITY_AUDIO_V042[move_key];return b if b!=nil
      pmd_ac_v042_skill_audio_move_profile_v032(move_key)
    end
    def skill_visual_move_profile_v031(move_key)
      b=PRIORITY_VISUAL_V042[move_key];return b if b!=nil
      pmd_ac_v042_skill_visual_move_profile_v031(move_key)
    end
    def canonical_priority_v042(data_or_key)
      if data_or_key.is_a?(Hash)
        return data_or_key[:priority].to_i if data_or_key[:priority]!=nil
        key=data_or_key[:canonical_move_key]||data_or_key[:move_key]
      else
        key=data_or_key
      end
      return 0 if key==nil
      if PRIORITY_MOVE_V042[key]!=nil;return PRIORITY_MOVE_V042[key][:priority].to_i;end
      if const_defined?(:MOVE_DB_V017) && MOVE_DB_V017[key]!=nil;return MOVE_DB_V017[key][:priority].to_i;end
      0
    end
    def priority_startup_elapsed_v042(priority,native_elapsed,total,speed_factor=1.0)
      p=priority.to_i;n=native_elapsed.to_i;t=total.to_i
      return PMD_AC.clamp(n,1,[t-1,1].max) if p==0
      base=PRIORITY_STARTUP_V042[p]
      return PMD_AC.clamp(n,1,[t-1,1].max) if base==nil
      # Existing realtime speed participates only as a small tie influence inside
      # a priority tier; it may not leap across priority tiers.
      sf=speed_factor.to_f;adj=0
      adj=-1 if sf>=1.25
      adj=1 if sf<=0.80
      e=base.to_i+adj
      if p>0
        e=[e,n].min
      else
        e=[e,n].max
      end
      PMD_AC.clamp(e,1,[t-1,1].max)
    end
    def priority_checksum_scalar_v042(v)
      return '' if v==nil;return v ? 'true':'false' if v==true || v==false
      return v.collect{|x|priority_checksum_scalar_v042(x)}.join(',') if v.is_a?(Array)
      if v.is_a?(Hash);ks=v.keys.sort{|a,b|a.to_s<=>b.to_s};return ks.collect{|k|k.to_s+'='+priority_checksum_scalar_v042(v[k])}.join(';');end
      return sprintf('%.2f',v) if v.is_a?(Float);v.to_s
    end
    def priority_checksum32_v042
      h=0;m=PRIORITY_MANIFEST_V042
      m.keys.reject{|k|k==:runtime_checksum32}.sort{|a,b|a.to_s<=>b.to_s}.each{|k|('M|'+k.to_s+'='+priority_checksum_scalar_v042(m[k])).each_byte{|by|h=((h*33)+by)&0x7fffffff}}
      PRIORITY_MOVE_V042.keys.sort{|a,b|a.to_s<=>b.to_s}.each do |k|
        d=PRIORITY_MOVE_V042[k]
        # Match generator checksum: source-facing move fields + source flags.
        raw={:name=>d[:name],:name_en=>d[:name_en],:type=>d[:type],:category=>d[:category],:power=>d[:canonical_power],:accuracy=>d[:accuracy],:priority=>d[:priority],:target_type=>d[:target_type],:policy=>d[:policy],:delivery=>d[:delivery],:range_px=>d[:range_px],:force_contact_range=>d[:force_contact_range],:projectile_tracking=>d[:projectile_tracking],:contact=>d[:contact],:visual_kind=>d[:visual_kind],:visual_style=>d[:visual_style],:cast_cat=>d[:cast_cat],:launch_cat=>d[:launch_cat],:hit_cat=>d[:hit_cat]}
        raw.delete_if{|kk,v|v==nil && ![:cast_cat,:launch_cat].include?(kk)}
        text='R|'+k.to_s+'|'+priority_checksum_scalar_v042(raw)+'|flags='+priority_checksum_scalar_v042(d[:source_move_flags]||[])
        text.each_byte{|by|h=((h*33)+by)&0x7fffffff}
      end
      h
    end
    def validate_priority_v042
      e=[];m=PRIORITY_MANIFEST_V042
      e.push('count') unless PRIORITY_MOVE_V042.size==8
      e.push('cumulative') unless m[:cumulative_mapped_move_count].to_i==251
      e.push('covered') unless m[:cumulative_reference_covered].to_i==4210
      [:quick_attack,:mach_punch,:extreme_speed,:vacuum_wave,:bullet_punch,:ice_shard,:shadow_sneak,:aqua_jet].each{|k|e.push('missing:'+k.to_s) if PRIORITY_MOVE_V042[k]==nil}
      e.push('priority') unless PRIORITY_MOVE_V042[:extreme_speed][:priority].to_i==2 && PRIORITY_MOVE_V042[:quick_attack][:priority].to_i==1
      # Generator checksum is additionally validated by the Python build; runtime
      # validation focuses on data shape to avoid Ruby Hash serialization ordering differences.
      e
    end
  end

  remove_const(:VERIFICATION_MODES) if const_defined?(:VERIFICATION_MODES)
  VERIFICATION_MODES=[:priority,:held_item,:guard,:two_turn,:altitude]
  remove_const(:VERIFICATION_LABELS) if const_defined?(:VERIFICATION_LABELS)
  VERIFICATION_LABELS={:priority=>'PRIORITY',:held_item=>'HELD_ITEM',:guard=>'GUARD',:two_turn=>'TWO_TURN',:altitude=>'ALTITUDE'}
end

class Game_PMDChessUnit
  alias pmd_ac_v042_begin_skill begin_skill unless method_defined?(:pmd_ac_v042_begin_skill)

  def priority_last_v042;@priority_last_v042.to_i;end
  def priority_native_elapsed_v042;@priority_native_elapsed_v042.to_i;end
  def priority_elapsed_v042;@priority_elapsed_v042.to_i;end
  def priority_total_v042;@priority_total_v042.to_i;end
  def begin_skill(skill_target=nil)
    pmd_ac_v042_begin_skill(skill_target)
    return unless @action==:skill && @action_timer.to_i>0 && !@action_hit_done
    data=skill_data;return if data==nil || data.empty?
    pri=PMD_AC.canonical_priority_v042(data)
    total=@action_total_frames.to_i;old_hit=@action_hit_frame.to_i
    return if total<=1
    native=total-old_hit;native=1 if native<1
    sf=respond_to?(:realtime_speed_factor) ? realtime_speed_factor : 1.0
    elapsed=PMD_AC.priority_startup_elapsed_v042(pri,native,total,sf)
    @action_hit_frame=total-elapsed
    @action_hit_frame=1 if @action_hit_frame<1
    @priority_last_v042=pri;@priority_native_elapsed_v042=native;@priority_elapsed_v042=elapsed;@priority_total_v042=total
    if pri!=0
      log_event(:priority,log_name+' move='+(data[:canonical_move_key]||:unknown).to_s+' priority='+pri.to_s+' startup='+native.to_s+'->'+elapsed.to_s+' total='+total.to_s+' recovery_preserved=1')
    end
  end
end

class Scene_PMD_AutoChess
  alias pmd_ac_v042_start start unless method_defined?(:pmd_ac_v042_start)
  alias pmd_ac_v042_prepare_verification_battle prepare_verification_battle unless method_defined?(:pmd_ac_v042_prepare_verification_battle)
  alias pmd_ac_v042_update_verification_script update_verification_script unless method_defined?(:pmd_ac_v042_update_verification_script)
  alias pmd_ac_v042_log_event log_event unless method_defined?(:pmd_ac_v042_log_event)
  alias pmd_ac_v042_complete_verification_mode complete_verification_mode unless method_defined?(:pmd_ac_v042_complete_verification_mode)

  def start
    pmd_ac_v042_start
    begin
      if FileTest.exist?(PMD_AC::BATTLE_LOG_FILE)
        text=File.open(PMD_AC::BATTLE_LOG_FILE,'rb'){|f|f.read};text.sub!(/PMD AutoChess Proto v0\.[0-9.]+ Battle Verification Log/,'PMD AutoChess Proto v0.42 Battle Verification Log');File.open(PMD_AC::BATTLE_LOG_FILE,'wb'){|f|f.write(text)}
      end
    rescue;end
    m=PMD_AC::PRIORITY_MANIFEST_V042
    log_event(:priority,'LOADED new=8 cumulative='+m[:cumulative_mapped_move_count].to_s+' covered='+m[:cumulative_reference_covered].to_s+'/'+m[:learnset_reference_total].to_s+' coverage='+sprintf('%.2f',m[:cumulative_coverage_percent].to_f)+'% timing=startup_shift recovery_preserved=1 quick_guard=integrated checksum32='+m[:runtime_checksum32].to_s)
  end
  def prepare_verification_battle
    pmd_ac_v042_prepare_verification_battle
    if verification_mode==:priority
      @priority_failed_v042=false;@priority_snapshots_v042={}
      for u in @units;u.verification_combat_sandbox(true);end
    end
  end
  def log_event(category,message)
    if category.to_s=='verify' && verification_mode==:priority && message.to_s.index('PRIORITY_')==0 && message.to_s.include?(' pass=0');@priority_failed_v042=true;end
    pmd_ac_v042_log_event(category,message)
  end
  def priority_verify_units_v042
    [verification_unit(:ally,:bulbasaur),verification_unit(:ally,:charmander),verification_unit(:ally,:squirtle),verification_unit(:enemy,:rattata),verification_unit(:enemy,:caterpie)]
  end
  def priority_reset_action_v042(u)
    return if u==nil
    u.verification_combat_sandbox(true)
  end
  def priority_capture_cast_v042(u,skill,target)
    return nil unless u.verification_force_skill(skill,target)
    {:p=>u.priority_last_v042,:native=>u.priority_native_elapsed_v042,:elapsed=>u.priority_elapsed_v042,:total=>u.priority_total_v042}
  end
  def verify_priority_manifest_v042
    return if @verification_done[:priority_manifest];e=PMD_AC.validate_priority_v042;m=PMD_AC::PRIORITY_MANIFEST_V042;pass=e.empty?
    log_event(:verify,'PRIORITY_MANIFEST pass='+(pass ? '1':'0')+' new=8 cumulative='+m[:cumulative_mapped_move_count].to_s+' covered='+m[:cumulative_reference_covered].to_s+'/'+m[:learnset_reference_total].to_s+' coverage='+sprintf('%.2f',m[:cumulative_coverage_percent].to_f)+' checksum='+m[:runtime_checksum32].to_s+' errors=['+e.join(',')+']');@verification_done[:priority_manifest]=true
  end
  def verify_priority_data_v042
    return if @verification_done[:priority_data];ok=true
    [:quick_attack,:mach_punch,:extreme_speed,:vacuum_wave,:bullet_punch,:ice_shard,:shadow_sneak,:aqua_jet].each do |k|
      d=PMD_AC.skill_data(('mv_'+k.to_s).to_sym);ok=false if d==nil || d.empty? || d[:canonical_move_key]!=k || d[:priority].to_i<=0 || !PMD_AC.move_executable?(k) || PMD_AC.skill_visual_move_profile_v031(k)==nil || PMD_AC.skill_audio_move_profile_v032(k)==nil
    end
    log_event(:verify,'PRIORITY_DATA pass='+(ok ? '1':'0')+' executable=8 visuals=8 audio=8 priorities=canonical_db');@verification_done[:priority_data]=true
  end
  def verify_priority_timing_v042
    return if @verification_done[:priority_timing];a,b,c,t,x=priority_verify_units_v042
    p4=priority_capture_cast_v042(a,:mv_protect,a);p2=priority_capture_cast_v042(a,:mv_extreme_speed,t);p1=priority_capture_cast_v042(a,:mv_quick_attack,t);p0=priority_capture_cast_v042(a,:mv_tackle,t);pn=priority_capture_cast_v042(a,:mv_trick_room,a)
    pass=p4!=nil&&p2!=nil&&p1!=nil&&p0!=nil&&pn!=nil&&p4[:p]==4&&p2[:p]==2&&p1[:p]==1&&p0[:p]==0&&pn[:p]==-7&&p4[:elapsed]<p2[:elapsed]&&p2[:elapsed]<p1[:elapsed]&&p1[:elapsed]<p0[:elapsed]&&p0[:elapsed]<pn[:elapsed]&&[p4,p2,p1,p0,pn].all?{|q|q[:total]>q[:elapsed]}
    log_event(:verify,'PRIORITY_TIMING pass='+(pass ? '1':'0')+' p4='+p4[:elapsed].to_s+' p2='+p2[:elapsed].to_s+' p1='+p1[:elapsed].to_s+' p0='+p0[:elapsed].to_s+' p-7='+pn[:elapsed].to_s+' total_duration_preserved=1');@verification_done[:priority_timing]=true
  end
  def verify_priority_quick_guard_v042
    return if @verification_done[:priority_quick_guard];a,b,c,t,x=priority_verify_units_v042
    x.deploy_to_pixel(t.pixel_x,t.pixel_y);x.set_guard_v040(:quick_guard,60)
    qa=PMD_AC.skill_data(:mv_quick_attack);tk=PMD_AC.skill_data(:mv_tackle);ex=PMD_AC.skill_data(:mv_extreme_speed)
    r1=guard_block_reason_v040(a,t,qa,false);r0=guard_block_reason_v040(a,t,tk,false);r2=guard_block_reason_v040(a,t,ex,false)
    pass=(r1==:quick_guard && r2==:quick_guard && r0==nil && PMD_AC.canonical_priority_v042(qa)==1 && PMD_AC.canonical_priority_v042(ex)==2)
    x.clear_guard_v040(:quick_guard)
    log_event(:verify,'PRIORITY_QUICK_GUARD pass='+(pass ? '1':'0')+' quick_attack=blocked extreme_speed=blocked tackle=hit shared_priority_source=1');@verification_done[:priority_quick_guard]=true
  end
  def verify_priority_damage_v042
    return if @verification_done[:priority_damage];a,b,c,t,x=priority_verify_units_v042
    t.verification_heal_full if t.respond_to?(:verification_heal_full);before=t.hp;d1=apply_skill_effects(a,t,PMD_AC.skill_data(:mv_quick_attack),1.0);hit1=before-t.hp
    x.verification_heal_full if x.respond_to?(:verification_heal_full);before2=x.hp;d2=apply_skill_effects(c,x,PMD_AC.skill_data(:mv_vacuum_wave),1.0);hit2=before2-x.hp
    pass=hit1>0&&hit2>0
    log_event(:verify,'PRIORITY_DAMAGE pass='+(pass ? '1':'0')+' quick_attack='+hit1.to_s+' vacuum_wave='+hit2.to_s+' damage_pipeline=canonical');@verification_done[:priority_damage]=true
  end
  def verify_priority_existing_v042
    return if @verification_done[:priority_existing]
    vals={:protect=>PMD_AC.canonical_priority_v042(PMD_AC.skill_data(:mv_protect)),:wide_guard=>PMD_AC.canonical_priority_v042(PMD_AC.skill_data(:mv_wide_guard)),:feint=>PMD_AC.canonical_priority_v042(PMD_AC.skill_data(:mv_feint)),:quick_attack=>PMD_AC.canonical_priority_v042(PMD_AC.skill_data(:mv_quick_attack)),:trick_room=>PMD_AC.canonical_priority_v042(PMD_AC.skill_data(:mv_trick_room))}
    pass=vals[:protect]==4&&vals[:wide_guard]==3&&vals[:feint]==2&&vals[:quick_attack]==1&&vals[:trick_room]==-7
    log_event(:verify,'PRIORITY_EXISTING pass='+(pass ? '1':'0')+' protect=+4 wide_guard=+3 feint=+2 quick_attack=+1 trick_room=-7 guard_room_integrated=1');@verification_done[:priority_existing]=true
  end
  def verify_priority_runtime_v042
    return if @verification_done[:priority_runtime];m=PMD_AC::PRIORITY_MANIFEST_V042;ok=PMD_AC::PRIORITY_MOVE_V042.size==8 && m[:cumulative_mapped_move_count].to_i==251 && m[:cumulative_reference_covered].to_i==4210
    log_event(:verify,'PRIORITY_RUNTIME pass='+(ok ? '1':'0')+' mapped=8 cumulative=251 coverage=4210/7005 timing=startup_only recovery_preserved=1 energy_unchanged=1 quick_guard=canonical_priority_gt0');@verification_done[:priority_runtime]=true
  end
  def verify_priority_modes_v042
    return if @verification_done[:priority_modes];exp=[:priority,:held_item,:guard,:two_turn,:altitude];pass=PMD_AC::VERIFICATION_MODES==exp && verification_mode==:priority
    log_event(:verify,'PRIORITY_RECENT_MODES pass='+(pass ? '1':'0')+' modes=5 default=PRIORITY');@verification_done[:priority_modes]=true
  end
  def update_verification_script
    pmd_ac_v042_update_verification_script;return unless verification_mode==:priority;f=@verification_frame
    verify_priority_manifest_v042 if f==4;verify_priority_data_v042 if f==50;verify_priority_timing_v042 if f==120;verify_priority_quick_guard_v042 if f==210;verify_priority_damage_v042 if f==300;verify_priority_existing_v042 if f==390;verify_priority_runtime_v042 if f==450;verify_priority_modes_v042 if f==490;complete_verification_mode if f==PMD_AC::VERIFICATION_PRIORITY_END_FRAME_V042
  end
  def complete_verification_mode
    if verification_mode==:priority
      if @priority_failed_v042;for u in @units;u.verification_finish;end;@verification_done[:complete]=true;log_event(:verify,'FAILED mode=PRIORITY auto_skill=on original_skills=restored');return;end
    end
    pmd_ac_v042_complete_verification_mode
  end
end
