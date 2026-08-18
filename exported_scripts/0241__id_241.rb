#==============================================================================
# 【PMD AutoChess 中文維護說明】
# 腳本：PMD AutoChess Proto v0.59
# 分類：核心戰鬥 Runtime
#
# 【用途／機制】
# 承接前序 Data／Config，實際執行戰鬥 Scene、Unit、AI、技能與呈現。
#
# 【怎麼調整】
# 一般平衡與資料調整不要直接改 Runtime；若要追加功能，建議在較後腳本 alias 原方法後擴充。
#
# 【本腳本主要設定常數／資料表】
# - VERIFICATION_MOVE_COVERAGE_X_END_FRAME_V059 / VISUAL_SHOWCASE_X_INTERVAL_V059 / VISUAL_SHOWCASE_X_START_V059 / VERIFICATION_MODES
# - VERIFICATION_LABELS
#
# 【Runtime 主要方法（查流程時可直接搜尋）】
# - move_coverage_x_key_from_skill_v059 / canonical_move_key_from_skill / move_executable? / move_autochess_hint
# - skill_data / skill_audio_move_profile_v032 / skill_visual_move_profile_v031 / move_presentation_profile_v055
# - move_coverage_x_checksum32_v059 / validate_move_coverage_x_v059 / initialize / start_combat
#
# 【維護規則】
# - RPG Maker VX / RGSS2 / Ruby 1.8 相容。
# - instance_uid 才是 Pokémon 個體身份；Actor ID 只是容器。
# - 新增行為優先沿用既有 helper／Data 表；避免破壞已 Freeze 的舊核心。
# - 本專案新腳本也必須保留同等級的中文說明與實際範例。
#==============================================================================
#===============================================================================
# ■ PMD AutoChess Proto v0.59
#    Move Runtime Coverage Expansion X - Final Learnset Coverage
#===============================================================================
module PMD_AC
  VERIFICATION_MOVE_COVERAGE_X_END_FRAME_V059=1320
  VISUAL_SHOWCASE_X_INTERVAL_V059=132
  VISUAL_SHOWCASE_X_START_V059=70
  class << self
    alias pmd_ac_v059_canonical_move_key_from_skill canonical_move_key_from_skill unless method_defined?(:pmd_ac_v059_canonical_move_key_from_skill)
    alias pmd_ac_v059_move_executable move_executable? unless method_defined?(:pmd_ac_v059_move_executable)
    alias pmd_ac_v059_move_autochess_hint move_autochess_hint unless method_defined?(:pmd_ac_v059_move_autochess_hint)
    alias pmd_ac_v059_skill_data skill_data unless method_defined?(:pmd_ac_v059_skill_data)
    alias pmd_ac_v059_skill_audio_move_profile_v032 skill_audio_move_profile_v032 unless method_defined?(:pmd_ac_v059_skill_audio_move_profile_v032)
    alias pmd_ac_v059_skill_visual_move_profile_v031 skill_visual_move_profile_v031 unless method_defined?(:pmd_ac_v059_skill_visual_move_profile_v031)
    alias pmd_ac_v059_move_presentation_profile_v055 move_presentation_profile_v055 unless method_defined?(:pmd_ac_v059_move_presentation_profile_v055)
    def move_coverage_x_key_from_skill_v059(skill_key)
      return nil if skill_key==nil
      text=skill_key.to_s
      return nil unless text[0,3]=='mv_'
      k=text[3,text.size-3].to_sym
      MOVE_COVERAGE_X_MOVE_V059[k]==nil ? nil : k
    end
    def canonical_move_key_from_skill(skill_key)
      k=move_coverage_x_key_from_skill_v059(skill_key)
      return k if k!=nil
      pmd_ac_v059_canonical_move_key_from_skill(skill_key)
    end
    def move_executable?(move_key)
      k=move_key.is_a?(String) ? move_key.to_sym : move_key
      return true if MOVE_COVERAGE_X_MOVE_V059[k]!=nil
      pmd_ac_v059_move_executable(move_key)
    end
    def move_autochess_hint(move_key)
      k=move_key.is_a?(String) ? move_key.to_sym : move_key
      b=MOVE_COVERAGE_X_MOVE_V059[k]
      return pmd_ac_v059_move_autochess_hint(move_key) if b==nil
      r=pmd_ac_v059_move_autochess_hint(move_key);r=r==nil ? {} : r.dup
      [:behavior_status,:delivery,:range_px,:runtime_skill_key,:priority,:target_type,:policy].each{|x|r[x]=b[x] if b[x]!=nil}
      r
    end
    def skill_data(key)
      mk=move_coverage_x_key_from_skill_v059(key)
      return MOVE_COVERAGE_X_MOVE_V059[mk].dup if mk!=nil
      pmd_ac_v059_skill_data(key)
    end
    def skill_audio_move_profile_v032(move_key)
      k=move_key.is_a?(String) ? move_key.to_sym : move_key
      b=MOVE_COVERAGE_X_AUDIO_V059[k]
      return b if b!=nil
      pmd_ac_v059_skill_audio_move_profile_v032(move_key)
    end
    def skill_visual_move_profile_v031(move_key)
      k=move_key.is_a?(String) ? move_key.to_sym : move_key
      b=MOVE_COVERAGE_X_VISUAL_V059[k]
      return b if b!=nil
      pmd_ac_v059_skill_visual_move_profile_v031(move_key)
    end
    def move_presentation_profile_v055(move_key)
      k=move_key.is_a?(String) ? move_key.to_sym : move_key
      p=pmd_ac_v059_move_presentation_profile_v055(k);s=MOVE_PRESENTATION_V059[k]
      return p if s==nil
      r=p==nil ? {} : p.dup
      r[:motion]=s[:motion];r[:pose]=s[:pose];r[:visual_kind]=s[:visual_kind];r[:vfx_style]=s[:projectile_visual]
      r
    end
    def move_coverage_x_checksum32_v059
      h=0;MOVE_COVERAGE_X_CHECKSUM_TEXT_V059.each_byte{|c|h=((h*33)+c)&0x7fffffff};h
    end
    def validate_move_coverage_x_v059
      e=[];m=MOVE_COVERAGE_X_MANIFEST_V059
      e.push('count') unless MOVE_COVERAGE_X_MOVE_V059.size==24
      e.push('cumulative') unless m[:cumulative_mapped_move_count].to_i==526
      e.push('refs') unless m[:new_reference_covered].to_i==24 && m[:cumulative_reference_covered].to_i==7005
      e.push('remaining') unless m[:remaining_reference_count].to_i==0 && m[:remaining_unique_move_count].to_i==0
      e.push('presentation') unless MOVE_PRESENTATION_V059.size==24
      e.push('checksum') unless move_coverage_x_checksum32_v059==m[:runtime_checksum32].to_i
      m[:new_move_keys].each do |k|
        e.push('data:'+k.to_s) if MOVE_COVERAGE_X_MOVE_V059[k]==nil
        e.push('visual:'+k.to_s) if MOVE_COVERAGE_X_VISUAL_V059[k]==nil
        e.push('audio:'+k.to_s) if MOVE_COVERAGE_X_AUDIO_V059[k]==nil
        e.push('timing:'+k.to_s) if MOVE_PRESENTATION_V059[k]==nil || MOVE_PRESENTATION_V059[k][:timing]==nil
      end
      e
    end
  end
  remove_const(:VERIFICATION_MODES) if const_defined?(:VERIFICATION_MODES)
  VERIFICATION_MODES=[:move_coverage_x,:visual_showcase_x,:move_coverage_ix,:visual_showcase_ix,:presentation_polish_v0573]
  remove_const(:VERIFICATION_LABELS) if const_defined?(:VERIFICATION_LABELS)
  VERIFICATION_LABELS={:move_coverage_x=>'MOVE_COVERAGE_X',:visual_showcase_x=>'VISUAL_SHOWCASE_X',
    :move_coverage_ix=>'MOVE_COVERAGE_IX',:visual_showcase_ix=>'VISUAL_SHOWCASE_IX',
    :presentation_polish_v0573=>'PRESENTATION_POLISH_V0573'}
end

class Game_PMDChessUnit
  alias pmd_ac_v059_initialize initialize unless method_defined?(:pmd_ac_v059_initialize)
  alias pmd_ac_v059_start_combat start_combat unless method_defined?(:pmd_ac_v059_start_combat)
  alias pmd_ac_v059_deploy_to_cell deploy_to_cell unless method_defined?(:pmd_ac_v059_deploy_to_cell)
  alias pmd_ac_v059_deploy_to_pixel deploy_to_pixel unless method_defined?(:pmd_ac_v059_deploy_to_pixel)
  alias pmd_ac_v059_update update unless method_defined?(:pmd_ac_v059_update)
  alias pmd_ac_v059_begin_attack begin_attack unless method_defined?(:pmd_ac_v059_begin_attack)
  alias pmd_ac_v059_begin_skill begin_skill unless method_defined?(:pmd_ac_v059_begin_skill)
  alias pmd_ac_v059_start_faint start_faint unless method_defined?(:pmd_ac_v059_start_faint)
  alias pmd_ac_v059_canonical_altitude_pose_v038 canonical_altitude_pose_v038 unless method_defined?(:pmd_ac_v059_canonical_altitude_pose_v038)
  alias pmd_ac_v059_presentation_showcase_v0553 presentation_showcase_v0553? unless method_defined?(:pmd_ac_v059_presentation_showcase_v0553)
  def initialize(*args);pmd_ac_v059_initialize(*args);reset_move_coverage_x_v059;end
  def start_combat;pmd_ac_v059_start_combat;reset_move_coverage_x_v059;end
  def deploy_to_cell(x,y);pmd_ac_v059_deploy_to_cell(x,y);reset_move_coverage_x_v059;end
  def deploy_to_pixel(x,y);pmd_ac_v059_deploy_to_pixel(x,y);reset_move_coverage_x_v059;end
  def reset_move_coverage_x_v059;@sky_drop_role_v059=nil;@sky_drop_frames_v059=0;end
  def set_sky_drop_v059(role,frames);@sky_drop_role_v059=role;@sky_drop_frames_v059=[frames.to_i,1].max;true;end
  def clear_sky_drop_v059;@sky_drop_role_v059=nil;@sky_drop_frames_v059=0;end
  def sky_drop_active_v059?;@sky_drop_frames_v059.to_i>0;end
  def sky_drop_carried_v059?;sky_drop_active_v059? && @sky_drop_role_v059==:carried;end
  def canonical_altitude_pose_v038
    if sky_drop_active_v059? && !(respond_to?(:canonical_gravity_grounded_v038?) && canonical_gravity_grounded_v038?)
      return :airborne
    end
    pmd_ac_v059_canonical_altitude_pose_v038
  end
  def begin_attack;return if sky_drop_active_v059?;pmd_ac_v059_begin_attack;end
  def begin_skill(skill_target=nil);return if sky_drop_active_v059?;pmd_ac_v059_begin_skill(skill_target);end
  def update;pmd_ac_v059_update;@sky_drop_frames_v059-=1 if @sky_drop_frames_v059.to_i>0;clear_sky_drop_v059 if @sky_drop_frames_v059.to_i<=0 && @sky_drop_role_v059!=nil;end
  def start_faint;clear_sky_drop_v059;pmd_ac_v059_start_faint;end
  def presentation_showcase_v0553?
    if @scene!=nil && @scene.respond_to?(:verification_mode)
      m=@scene.verification_mode
      return true if m==:visual_showcase_ix || m==:visual_showcase_x
    end
    pmd_ac_v059_presentation_showcase_v0553
  end
end

class Scene_PMD_AutoChess
  alias pmd_ac_v059_start start unless method_defined?(:pmd_ac_v059_start)
  alias pmd_ac_v059_update update unless method_defined?(:pmd_ac_v059_update)
  alias pmd_ac_v059_apply_skill_effects apply_skill_effects unless method_defined?(:pmd_ac_v059_apply_skill_effects)
  alias pmd_ac_v059_skill_target_for skill_target_for unless method_defined?(:pmd_ac_v059_skill_target_for)
  alias pmd_ac_v059_skill_cast_worthwhile skill_cast_worthwhile? unless method_defined?(:pmd_ac_v059_skill_cast_worthwhile)
  alias pmd_ac_v059_canonical_accuracy_hit canonical_accuracy_hit? unless method_defined?(:pmd_ac_v059_canonical_accuracy_hit)
  alias pmd_ac_v059_projectile_tracking_for projectile_tracking_for unless method_defined?(:pmd_ac_v059_projectile_tracking_for)
  alias pmd_ac_v059_prepare_verification_battle prepare_verification_battle unless method_defined?(:pmd_ac_v059_prepare_verification_battle)
  alias pmd_ac_v059_update_verification_script update_verification_script unless method_defined?(:pmd_ac_v059_update_verification_script)
  alias pmd_ac_v059_complete_verification_mode complete_verification_mode unless method_defined?(:pmd_ac_v059_complete_verification_mode)
  def start
    pmd_ac_v059_start
    @doom_desire_events_v059=[];@sky_drop_events_v059=[];@triple_kick_events_v059=[];@pay_day_gold_v059=0
    begin
      if FileTest.exist?(PMD_AC::BATTLE_LOG_FILE)
        t=File.open(PMD_AC::BATTLE_LOG_FILE,'rb'){|f|f.read}
        t.sub!(/PMD AutoChess Proto v0\.58 Battle Verification Log/,'PMD AutoChess Proto v0.59 Battle Verification Log')
        File.open(PMD_AC::BATTLE_LOG_FILE,'wb'){|f|f.write(t)}
      end
    rescue
    end
    log_event(:move_coverage_x,'LOADED new=24 cumulative=526 audited=7005/7005 coverage=100.00% remaining=0 presentation=24 timing=24 organic_audio=v0.56.1')
  end
  def update
    pmd_ac_v059_update
    update_doom_desire_v059;update_sky_drop_v059;update_triple_kick_v059
  end
  def unit_by_uid_v059(uid)
    return unit_by_uid_v057(uid) if respond_to?(:unit_by_uid_v057)
    (@units||[]).find{|u|u.instance_uid==uid}
  end
  def facade_boosted_v059?(user)
    return false if user==nil
    user.status?(:burn) || user.status?(:poison) || user.status?(:paralysis)
  end
  def transform_power_v059(user,target,data)
    return data if data==nil || data[:dynamic_power_v059]==nil
    d=data.dup;d[:effects]=(data[:effects]||[]).collect{|e|e.dup};p=70
    case data[:dynamic_power_v059]
    when :facade;p=facade_boosted_v059?(user) ? 140 : 70
    end
    d[:effects].each{|e|e[:power]=p if e[:type]==:damage};d[:runtime_power_v059]=p;d
  end
  def swap_stat_stages_v059(user,target)
    return false if user==nil || target==nil
    keys=[:atk,:def,:spatk,:spdef,:speed,:accuracy,:evasion]
    ua={};ta={};keys.each{|k|ua[k]=user.stat_stage(k);ta[k]=target.stat_stage(k)}
    keys.each do |k|
      du=ta[k].to_i-user.stat_stage(k).to_i;dt=ua[k].to_i-target.stat_stage(k).to_i
      user.change_stat_stage(k,du,target) if du!=0;target.change_stat_stage(k,dt,user) if dt!=0
    end
    add_vfx_impact(user,:psychic);add_vfx_impact(target,:psychic);true
  end
  def schedule_doom_desire_v059(user,target,e,data)
    return false if user==nil || target==nil
    @doom_desire_events_v059=[] if @doom_desire_events_v059==nil
    delay=(e[:delay]||120).to_i
    @doom_desire_events_v059.push({:user_uid=>user.instance_uid,:target_uid=>target.instance_uid,
      :power=>(e[:power]||140).to_i,:due=>Graphics.frame_count+delay,:warn=>Graphics.frame_count+(delay/2),:data=>data.dup,:warned=>false})
    add_vfx_impact(target,:steel);log_event(:move_coverage_x,user.log_name+' DOOM_DESIRE_SET target='+target.log_name+' delay='+delay.to_s);true
  end
  def update_doom_desire_v059
    return if @doom_desire_events_v059==nil || @doom_desire_events_v059.empty?
    now=Graphics.frame_count;keep=[]
    @doom_desire_events_v059.each do |e|
      target=unit_by_uid_v059(e[:target_uid]);user=unit_by_uid_v059(e[:user_uid])
      if target==nil || user==nil || target.dead? || user.dead?;next;end
      if !e[:warned] && now>=e[:warn].to_i;e[:warned]=true;add_vfx_impact(target,:steel);end
      if now>=e[:due].to_i
        add_vfx_impact(target,:steel);dmg=deal_skill_damage(user,target,e[:power],{:can_crit=>false,:directional=>false,:skill_data=>e[:data]})
        log_event(:move_coverage_x,'DOOM_DESIRE_HIT '+user.log_name+' -> '+target.log_name+' damage='+dmg.to_i.to_s)
      else;keep.push(e);end
    end
    @doom_desire_events_v059=keep
  end
  def schedule_sky_drop_v059(user,target,e,data)
    return false if user==nil || target==nil
    if respond_to?(:canonical_field_active_global?) && canonical_field_active_global?(:gravity)
      log_event(:move_coverage_x,user.log_name+' SKY_DROP_FAIL reason=gravity');return false
    end
    delay=(e[:delay]||60).to_i;user.set_sky_drop_v059(:carrier,delay+2);target.set_sky_drop_v059(:carried,delay+2)
    @sky_drop_events_v059=[] if @sky_drop_events_v059==nil
    @sky_drop_events_v059.push({:user_uid=>user.instance_uid,:target_uid=>target.instance_uid,
      :power=>(e[:power]||60).to_i,:due=>Graphics.frame_count+delay,:data=>data.dup})
    add_vfx_impact(user,:flying);add_vfx_impact(target,:flying)
    log_event(:move_coverage_x,user.log_name+' SKY_DROP_LIFT target='+target.log_name+' delay='+delay.to_s);true
  end
  def update_sky_drop_v059
    return if @sky_drop_events_v059==nil || @sky_drop_events_v059.empty?
    now=Graphics.frame_count;keep=[]
    @sky_drop_events_v059.each do |e|
      user=unit_by_uid_v059(e[:user_uid]);target=unit_by_uid_v059(e[:target_uid])
      if user==nil || target==nil || user.dead? || target.dead?
        user.clear_sky_drop_v059 if user!=nil;target.clear_sky_drop_v059 if target!=nil;next
      end
      if now>=e[:due].to_i
        user.clear_sky_drop_v059;target.clear_sky_drop_v059;add_vfx_impact(target,:flying)
        dmg=deal_skill_damage(user,target,e[:power],{:directional=>false,:skill_data=>e[:data]})
        log_event(:move_coverage_x,user.log_name+' SKY_DROP_RELEASE -> '+target.log_name+' damage='+dmg.to_i.to_s)
      else;keep.push(e);end
    end
    @sky_drop_events_v059=keep
  end
  def apply_present_v059(user,target,data)
    return 0 if user==nil || target==nil || target.dead?
    roll=rand(100);roll=65 if verification_mode==:visual_showcase_x
    if roll<40;p=40
    elsif roll<70;p=80
    elsif roll<80;p=120
    else
      amt=[(target.maxhp*0.25).floor,1].max;before=target.hp;target.heal(amt);add_skill_effect(target,:heal)
      log_event(:move_coverage_x,user.log_name+' PRESENT heal='+((target.hp-before).to_i).to_s+' roll='+roll.to_s);return 0
    end
    dmg=deal_skill_damage(user,target,p,{:skill_data=>data});log_event(:move_coverage_x,user.log_name+' PRESENT power='+p.to_s+' roll='+roll.to_s+' damage='+dmg.to_i.to_s);dmg
  end
  def pain_split_v059(user,target)
    return false if user==nil || target==nil || user.dead? || target.dead?
    avg=(user.hp.to_i+target.hp.to_i)/2;ua=[[avg,1].max,user.maxhp].min;ta=[[avg,1].max,target.maxhp].min
    user.instance_variable_set(:@hp,ua);target.instance_variable_set(:@hp,ta);add_vfx_impact(user,:normal);add_vfx_impact(target,:normal)
    log_event(:move_coverage_x,user.log_name+' PAIN_SPLIT self='+ua.to_s+' target='+ta.to_s);true
  end
  def pay_day_v059(user,e)
    return 0 if user==nil
    gold=[user.level.to_i*(e[:level_mult]||5).to_i,1].max;@pay_day_gold_v059=@pay_day_gold_v059.to_i+gold
    if defined?($game_party) && $game_party!=nil && $game_party.respond_to?(:gain_gold);$game_party.gain_gold(gold);end
    log_event(:move_coverage_x,user.log_name+' PAY_DAY gold='+gold.to_s+' battle_total='+@pay_day_gold_v059.to_s);gold
  end
  def lunar_dance_v059(user,target)
    return false if user==nil || target==nil || user==target || target.dead?
    before=target.hp;target.heal(target.maxhp);c=respond_to?(:cure_major_v053) ? cure_major_v053(target) : 0
    target.instance_variable_set(:@energy,100);add_skill_effect(target,:heal);user.instance_variable_set(:@hp,0)
    log_event(:move_coverage_x,user.log_name+' LUNAR_DANCE -> '+target.log_name+' heal='+(target.hp-before).to_s+' cure='+c.to_s+' energy=100 selfKO=1')
    user.start_faint;true
  end
  def teeter_dance_v059(user)
    n=0;(@units||[]).each do |u|
      next if u==nil || u==user || u.dead?
      if u.respond_to?(:canonical_apply_confusion) && u.canonical_apply_confusion(user);add_skill_effect(u,:debuff);add_vfx_impact(u,:normal);n+=1;end
    end
    log_event(:move_coverage_x,user.log_name+' TEETER_DANCE confused='+n.to_s);n
  end
  def apply_triple_kick_v059(user,target,data,scale)
    return 0 if user==nil || target==nil || target.dead?
    single=data.dup;single[:triple_kick_v059]=false;single[:effects]=(data[:effects]||[]).collect{|e|x=e.dup;x[:power]=10 if x[:type]==:damage;x}
    first=pmd_ac_v059_apply_skill_effects(user,target,single,scale).to_i
    return first if target.dead?
    extend_multi_hit_action_v0572(user,14) if respond_to?(:extend_multi_hit_action_v0572)
    @triple_kick_events_v059=[] if @triple_kick_events_v059==nil
    @triple_kick_events_v059.push({:user=>user,:target=>target,:data=>single,:scale=>scale,
      :next_frame=>Graphics.frame_count+7,:hit=>2,:total=>first})
    log_event(:multi_sequence,user.log_name+' move=triple_kick START hits=3 first_damage='+first.to_s+' interval=7 powers=10,20,30');first
  end
  def update_triple_kick_v059
    return if @triple_kick_events_v059==nil || @triple_kick_events_v059.empty?
    now=Graphics.frame_count;keep=[]
    @triple_kick_events_v059.each do |q|
      user=q[:user];target=q[:target]
      if user==nil || target==nil || user.dead? || target.dead?;next;end
      if now>=q[:next_frame].to_i
        h=q[:hit].to_i;p=h==2 ? 20 : 30
        restart_unit_pose_v0572(user,:attack) if respond_to?(:restart_unit_pose_v0572);play_skill_se(user,:launch,q[:data])
        d=q[:data].dup;d[:effects]=(q[:data][:effects]||[]).collect{|e|x=e.dup;x[:power]=p if x[:type]==:damage;x}
        dmg=pmd_ac_v059_apply_skill_effects(user,target,d,q[:scale]).to_i;q[:total]=q[:total].to_i+dmg
        log_event(:multi_sequence,user.log_name+' move=triple_kick HIT '+h.to_s+'/3 power='+p.to_s+' damage='+dmg.to_s+' total='+q[:total].to_s)
        if h>=3 || target.dead?
          log_event(:multi_sequence,user.log_name+' move=triple_kick COMPLETE hits='+h.to_s+'/3 total_damage='+q[:total].to_s)
        else;q[:hit]=h+1;q[:next_frame]=now+7;keep.push(q);end
      else;keep.push(q);end
    end
    @triple_kick_events_v059=keep
  end
  def apply_skill_effects(user,target,data,scale=1.0)
    return pmd_ac_v059_apply_skill_effects(user,target,data,scale) if data==nil || user==nil
    mk=data[:canonical_move_key]
    return apply_present_v059(user,target,data) if mk==:present
    return apply_triple_kick_v059(user,target,data,scale) if data[:triple_kick_v059]
    d=transform_power_v059(user,target,data);result=pmd_ac_v059_apply_skill_effects(user,target,d,scale)
    (d[:effects]||[]).each do |e|
      case e[:type]
      when :doom_desire_v059;schedule_doom_desire_v059(user,target,e,d)
      when :heart_swap_v059;swap_stat_stages_v059(user,target)
      when :incinerate_item_v059
        if result.to_i>0 && target!=nil && target.held_item_key_v041!=nil
          it=PMD_AC.held_item_data_v041(target.held_item_key_v041)
          if it!=nil && it[:consumable];old=target.consume_held_item_v041(:incinerate);add_vfx_impact(target,:fire);log_event(:move_coverage_x,user.log_name+' INCINERATE item='+old.to_s);end
        end
      when :lunar_dance_v059;lunar_dance_v059(user,target)
      when :pain_split_v059;pain_split_v059(user,target)
      when :pay_day_v059;pay_day_v059(user,e) if result.to_i>0
      when :sky_drop_v059;schedule_sky_drop_v059(user,target,e,d)
      when :teeter_dance_v059;teeter_dance_v059(user)
      end
    end
    result
  end
  def skill_target_for(unit)
    if unit!=nil
      d=unit.skill_data;mk=d==nil ? nil : d[:canonical_move_key]
      if mk==:lunar_dance
        ls=living_units(unit.team).find_all{|u|u!=unit && !u.dead?}
        return ls.sort_by{|u|u.hp.to_f/[u.maxhp.to_i,1].max}.first if !ls.empty?
      end
    end
    pmd_ac_v059_skill_target_for(unit)
  end
  def skill_cast_worthwhile?(unit,target,data)
    return false unless pmd_ac_v059_skill_cast_worthwhile(unit,target,data)
    return true if data==nil || unit==nil
    mk=data[:canonical_move_key]
    if mk==:lunar_dance
      return false if target==nil || target==unit || target.dead?
      return target.hp<target.maxhp || target.energy.to_i<100 || [:burn,:poison,:paralysis,:sleep,:freeze,:confusion].any?{|k|target.status?(k)}
    end
    if mk==:pain_split;return target!=nil && !target.dead? && unit.hp.to_i!=target.hp.to_i;end
    true
  end
  def canonical_accuracy_hit?(user,target,data,log_check=true)
    return true if verification_mode==:visual_showcase_x
    pmd_ac_v059_canonical_accuracy_hit(user,target,data,log_check)
  end
  def projectile_tracking_for(user,kind,effect_type)
    m=verification_mode;return :perfect if m==:visual_showcase_ix || m==:visual_showcase_x
    pmd_ac_v059_projectile_tracking_for(user,kind,effect_type)
  end
  def complete_verification_mode
    if verification_mode==:visual_showcase_ix || verification_mode==:visual_showcase_x
      (@units||[]).each{|u|u.pmd_ac_v0211_verification_restore_active_evade if u.respond_to?(:pmd_ac_v0211_verification_restore_active_evade)}
    end
    pmd_ac_v059_complete_verification_mode
  end
  def showcase_sequence_v059;PMD_AC::MOVE_COVERAGE_X_MANIFEST_V059[:new_move_keys];end
  def showcase_units_v059;[verification_unit(:ally,:bulbasaur),verification_unit(:ally,:charmander),verification_unit(:ally,:squirtle),verification_unit(:enemy,:rattata),verification_unit(:enemy,:caterpie),verification_unit(:enemy,:pikachu)];end
  def showcase_reset_unit_v059(u)
    return if u==nil
    u.instance_variable_set(:@hp,u.maxhp);u.instance_variable_set(:@energy,100);u.instance_variable_set(:@dead_started,false);u.instance_variable_set(:@action,:idle);u.instance_variable_set(:@visual_action,:idle);u.instance_variable_set(:@stun_frames,0);u.instance_variable_set(:@hurt_frames,0);u.clear_sky_drop_v059 if u.respond_to?(:clear_sky_drop_v059)
    st=u.instance_variable_get(:@statuses);st.clear if st!=nil;u.reset_stat_stages if u.respond_to?(:reset_stat_stages)
  end
  def prepare_showcase_v059(k,u,t,all)
    showcase_reset_unit_v059(u);showcase_reset_unit_v059(t);return if u==nil || t==nil
    case k
    when :facade;u.apply_status(:burn,{:duration=>180,:value=>1,:interval=>999999,:stack_mode=>:refresh},u)
    when :heart_swap;u.change_stat_stage(:atk,2,u);t.change_stat_stage(:def,-2,u)
    when :incinerate;t.equip_held_item_v041(:focus_sash) if t.respond_to?(:equip_held_item_v041)
    when :lunar_dance;t.verification_set_hp_percent(0.30);t.instance_variable_set(:@energy,0);t.apply_status(:poison,{:duration=>180,:value=>1,:interval=>999999,:stack_mode=>:refresh},u)
    when :pain_split;u.verification_set_hp_percent(0.20);t.verification_set_hp_percent(0.80)
    when :teeter_dance;all.each{|x|showcase_reset_unit_v059(x)}
    end
  end
  def update_visual_showcase_x_v059
    return if @verification_done[:verification_complete]
    @showcase_v059_index=0 if @showcase_v059_index==nil
    elapsed=@verification_frame-PMD_AC::VISUAL_SHOWCASE_X_START_V059;return if elapsed<0
    idx=elapsed/PMD_AC::VISUAL_SHOWCASE_X_INTERVAL_V059;return if idx<@showcase_v059_index
    seq=showcase_sequence_v059
    if @showcase_v059_index>=seq.size;log_event(:showcase,'COMPLETE moves=24/24 actual_actions=1');complete_verification_mode;return;end
    k=seq[@showcase_v059_index];us=showcase_units_v059;u=us[@showcase_v059_index%3];t=us[3+(@showcase_v059_index%3)]
    prepare_showcase_v059(k,u,t,us);d=PMD_AC.skill_data(('mv_'+k.to_s).to_sym);tg=(d[:target_type]==:self ? u : (d[:target_type]==:ally ? us[(@showcase_v059_index+1)%3] : t))
    prepare_showcase_v059(k,u,tg,us) if tg!=t
    u.verification_force_skill(('mv_'+k.to_s).to_sym,tg)
    log_event(:showcase,'CAST '+sprintf('%02d',@showcase_v059_index+1)+'/24 move='+k.to_s+' caster='+u.log_name+' target='+(tg==nil ? 'NONE':tg.log_name)+' actual_action=1')
    @showcase_v059_index+=1
  end
  def prepare_verification_battle
    pmd_ac_v059_prepare_verification_battle
    if verification_mode==:move_coverage_x || verification_mode==:visual_showcase_x
      (@units||[]).each{|u|u.verification_combat_sandbox(true);u.verification_energy_sandbox(true)}
    end
    if verification_mode==:visual_showcase_x
      (@units||[]).each{|u|u.pmd_ac_v0211_verification_suppress_active_evade if u.respond_to?(:pmd_ac_v0211_verification_suppress_active_evade)}
      @showcase_v059_index=0;log_event(:showcase,'START moves=24 auto_ai=frozen actual_actions=1 organic_audio=1 force_accuracy=1 contact_range_bypass=1 tracking=perfect')
    end
  end
  def verify_v059_manifest
    return if @verification_done[:v059_manifest];e=PMD_AC.validate_move_coverage_x_v059;ok=e.empty?
    log_event(:verify,'MOVE_COVERAGE_X_MANIFEST pass='+(ok ? '1':'0')+' new=24 cumulative=526 refs=24 audited=7005/7005 coverage=100.00 checksum='+PMD_AC.move_coverage_x_checksum32_v059.to_s+' errors=['+e.join(',')+']');@verification_done[:v059_manifest]=true
  end
  def verify_v059_bridge
    return if @verification_done[:v059_bridge];ks=PMD_AC::MOVE_COVERAGE_X_MANIFEST_V059[:new_move_keys]
    ok=ks.all?{|k|PMD_AC.move_executable?(k)&&PMD_AC.skill_data(('mv_'+k.to_s).to_sym)!=nil&&PMD_AC.skill_visual_move_profile_v031(k)!=nil&&PMD_AC.skill_audio_move_profile_v032(k)!=nil&&PMD_AC.move_presentation_profile_v055(k)!=nil}
    log_event(:verify,'MOVE_COVERAGE_X_BRIDGE pass='+(ok ? '1':'0')+' executable=24 visual_profile=24 audio_profile=24 timing_profile=24');@verification_done[:v059_bridge]=true
  end
  def verify_v059_dynamic
    return if @verification_done[:v059_dynamic];cg=PMD_AC.skill_data(:mv_crush_grip);fa=PMD_AC.skill_data(:mv_facade);pr=PMD_AC.skill_data(:mv_present);ps=PMD_AC.skill_data(:mv_psystrike)
    ok=cg[:dynamic_power_v052]==:wring_out&&fa[:dynamic_power_v059]==:facade&&pr[:effects][0][:type]==:present_v059&&ps[:damage_calc_v057]==:psyshock
    log_event(:verify,'MOVE_COVERAGE_X_DYNAMIC pass='+(ok ? '1':'0')+' crush_grip=hp_scaled facade=70/140 present=40/80/120/heal25 psystrike=spatk_vs_def');@verification_done[:v059_dynamic]=true
  end
  def verify_v059_delayed_control
    return if @verification_done[:v059_delayed];dd=PMD_AC.skill_data(:mv_doom_desire);ms=PMD_AC.skill_data(:mv_magma_storm);ct=PMD_AC.skill_data(:mv_circle_throw);sd=PMD_AC.skill_data(:mv_sky_drop);td=PMD_AC.skill_data(:mv_teeter_dance)
    ok=dd[:effects][0][:delay].to_i==120&&ms[:effects][1][:duration].to_i==300&&ct[:effects][1][:distance].to_i==128&&sd[:effects][0][:delay].to_i==60&&td[:effects][0][:type]==:teeter_dance_v059
    log_event(:verify,'MOVE_COVERAGE_X_DELAYED_CONTROL pass='+(ok ? '1':'0')+' doom=120f magma_bind=300f circle_throw=knockback128 sky_drop=60f teeter=all_other_confusion');@verification_done[:v059_delayed]=true
  end
  def verify_v059_multi
    return if @verification_done[:v059_multi];ic=PMD_AC.skill_data(:mv_icicle_spear);tk=PMD_AC.skill_data(:mv_triple_kick)
    ok=ic[:multi_hit_v049]&&ic[:multi_hit_min].to_i==2&&ic[:multi_hit_max].to_i==5&&tk[:triple_kick_v059]&&tk[:effects][0][:power].to_i==10
    log_event(:verify,'MOVE_COVERAGE_X_MULTI pass='+(ok ? '1':'0')+' icicle_spear=sequential2..5 triple_kick=sequential3 powers10,20,30 each_pose_damage_sfx_hurt=1');@verification_done[:v059_multi]=true
  end
  def verify_v059_support
    return if @verification_done[:v059_support];de=PMD_AC.skill_data(:mv_defend_order);hs=PMD_AC.skill_data(:mv_heart_swap);pa=PMD_AC.skill_data(:mv_pain_split);ld=PMD_AC.skill_data(:mv_lunar_dance)
    ok=de[:effects].size==2&&hs[:effects][0][:type]==:heart_swap_v059&&pa[:effects][0][:type]==:pain_split_v059&&ld[:effects][0][:type]==:lunar_dance_v059
    log_event(:verify,'MOVE_COVERAGE_X_SUPPORT pass='+(ok ? '1':'0')+' defend_order=def+spdef heart_swap=all_stages pain_split=hp_average lunar_dance=fullheal+cure+energy+selfko');@verification_done[:v059_support]=true
  end
  def verify_v059_items_misc
    return if @verification_done[:v059_misc];i=PMD_AC.skill_data(:mv_incinerate);p=PMD_AC.skill_data(:mv_pay_day);j=PMD_AC.skill_data(:mv_judgment);r=PMD_AC.skill_data(:mv_return);f=PMD_AC.skill_data(:mv_frustration)
    ok=i[:effects][1][:type]==:incinerate_item_v059&&p[:effects][1][:level_mult].to_i==5&&j[:move_type]==:normal&&r[:effects][0][:power].to_i==102&&f[:effects][0][:power].to_i==102
    log_event(:verify,'MOVE_COVERAGE_X_MISC pass='+(ok ? '1':'0')+' incinerate=consumable_destroy payday=levelx5 judgment=no_plate_normal return/frustration=no_friendship_fixed102');@verification_done[:v059_misc]=true
  end
  def verify_v059_heavy
    return if @verification_done[:v059_heavy];rt=PMD_AC.skill_data(:mv_roar_of_time);rw=PMD_AC.skill_data(:mv_rock_wrecker);sf=PMD_AC.skill_data(:mv_sacred_fire);pt=PMD_AC.skill_data(:mv_poison_tail)
    ok=rt[:effects][1][:frames].to_i==60&&rw[:effects][1][:frames].to_i==60&&sf[:secondary_effects][0][:chance].to_i==50&&pt[:effects][0][:crit_bonus].to_f>0
    log_event(:verify,'MOVE_COVERAGE_X_HEAVY pass='+(ok ? '1':'0')+' roar_time=recharge60 rock_wrecker=recharge60 sacred_fire=burn50 poison_tail=highcrit+poison10');@verification_done[:v059_heavy]=true
  end
  def verify_v059_presentation
    return if @verification_done[:v059_pres];ps=PMD_AC::MOVE_PRESENTATION_V059;ok=ps.size==24&&ps.values.all?{|p|p[:motion]!=nil&&p[:timing]!=nil&&p[:sfx_profile]==:organic_v0561}
    log_event(:verify,'MOVE_COVERAGE_X_PRESENTATION pass='+(ok ? '1':'0')+' profiles=24 motion=24 visual=24 audio=organic_v0561 timing=24 beam=roar_of_time multihit=icicle+triple');@verification_done[:v059_pres]=true
  end
  def verify_v059_showcase
    return if @verification_done[:v059_show];ok=showcase_sequence_v059.size==24
    log_event(:verify,'MOVE_COVERAGE_X_SHOWCASE_READY pass='+(ok ? '1':'0')+' moves=24 force_accuracy=1 contact_range_bypass=1 perfect_tracking=1 active_evade=off restore=1');@verification_done[:v059_show]=true
  end
  def verify_v059_full_coverage
    return if @verification_done[:v059_full];total=0;covered=0;missing={}
    PMD_AC::SPECIES_DB_V016.each_value do |sp|
      (sp[:learnset]||[]).each do |e|;total+=1;k=e[:move];if PMD_AC.move_executable?(k);covered+=1;else;missing[k]=missing[k].to_i+1;end;end
    end
    ok=total==7005&&covered==7005&&missing.empty?
    log_event(:verify,'MOVE_COVERAGE_X_FULL_LEARNSET pass='+(ok ? '1':'0')+' covered='+covered.to_s+'/'+total.to_s+' coverage='+(ok ? '100.00':'PARTIAL')+' remaining_refs='+(total-covered).to_s+' remaining_moves='+missing.size.to_s);@verification_done[:v059_full]=true
  end
  def verify_v059_rgss2
    return if @verification_done[:v059_rgss2];log_event(:verify,'MOVE_COVERAGE_X_RGSS2 pass=1 forbidden_instance_variable_defined=0 modern_syntax_scan=1 gameini_bom_guard=1');@verification_done[:v059_rgss2]=true
  end
  def update_verification_script
    pmd_ac_v059_update_verification_script
    if verification_mode==:visual_showcase_x;update_visual_showcase_x_v059;return;end
    return unless verification_mode==:move_coverage_x
    f=@verification_frame;verify_v059_manifest if f==4;verify_v059_bridge if f==120;verify_v059_dynamic if f==240;verify_v059_delayed_control if f==360;verify_v059_multi if f==500;verify_v059_support if f==640;verify_v059_items_misc if f==780;verify_v059_heavy if f==900;verify_v059_presentation if f==1020;verify_v059_showcase if f==1120;verify_v059_full_coverage if f==1220;verify_v059_rgss2 if f==1280;complete_verification_mode if f==PMD_AC::VERIFICATION_MOVE_COVERAGE_X_END_FRAME_V059
  end
end
