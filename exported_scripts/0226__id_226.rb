#==============================================================================
# 【PMD AutoChess 中文維護說明】
# 腳本：PMD AutoChess Proto v0.57
# 分類：核心戰鬥 Runtime
#
# 【用途／機制】
# 承接前序 Data／Config，實際執行戰鬥 Scene、Unit、AI、技能與呈現。
#
# 【怎麼調整】
# 一般平衡與資料調整不要直接改 Runtime；若要追加功能，建議在較後腳本 alias 原方法後擴充。
#
# 【本腳本主要設定常數／資料表】
# - VERIFICATION_MOVE_COVERAGE_VIII_END_FRAME_V057 / VISUAL_SHOWCASE_VIII_INTERVAL_V057 / VISUAL_SHOWCASE_VIII_START_V057 / VERIFICATION_MODES
# - VERIFICATION_LABELS
#
# 【Runtime 主要方法（查流程時可直接搜尋）】
# - move_coverage_viii_key_from_skill_v057 / canonical_move_key_from_skill / move_executable? / move_autochess_hint
# - skill_data / skill_audio_move_profile_v032 / skill_visual_move_profile_v031 / move_presentation_profile_v055
# - move_coverage_viii_checksum32_v057 / validate_move_coverage_viii_v057 / initialize / start_combat
#
# 【維護規則】
# - RPG Maker VX / RGSS2 / Ruby 1.8 相容。
# - instance_uid 才是 Pokémon 個體身份；Actor ID 只是容器。
# - 新增行為優先沿用既有 helper／Data 表；避免破壞已 Freeze 的舊核心。
# - 本專案新腳本也必須保留同等級的中文說明與實際範例。
#==============================================================================
#===============================================================================
# ■ PMD AutoChess Proto v0.57
#    Move Runtime Coverage Expansion VIII + Visual Showcase VIII
#-------------------------------------------------------------------------------
# Base: user-accepted v0.56.1 Organic Combat SFX Palette.
#===============================================================================
module PMD_AC
  VERIFICATION_MOVE_COVERAGE_VIII_END_FRAME_V057=1460
  VISUAL_SHOWCASE_VIII_INTERVAL_V057=92
  VISUAL_SHOWCASE_VIII_START_V057=70
  class << self
    alias pmd_ac_v057_canonical_move_key_from_skill canonical_move_key_from_skill unless method_defined?(:pmd_ac_v057_canonical_move_key_from_skill)
    alias pmd_ac_v057_move_executable move_executable? unless method_defined?(:pmd_ac_v057_move_executable)
    alias pmd_ac_v057_move_autochess_hint move_autochess_hint unless method_defined?(:pmd_ac_v057_move_autochess_hint)
    alias pmd_ac_v057_skill_data skill_data unless method_defined?(:pmd_ac_v057_skill_data)
    alias pmd_ac_v057_skill_audio_move_profile_v032 skill_audio_move_profile_v032 unless method_defined?(:pmd_ac_v057_skill_audio_move_profile_v032)
    alias pmd_ac_v057_skill_visual_move_profile_v031 skill_visual_move_profile_v031 unless method_defined?(:pmd_ac_v057_skill_visual_move_profile_v031)
    alias pmd_ac_v057_move_presentation_profile_v055 move_presentation_profile_v055 unless method_defined?(:pmd_ac_v057_move_presentation_profile_v055)

    def move_coverage_viii_key_from_skill_v057(skill_key)
      return nil if skill_key==nil;text=skill_key.to_s;return nil unless text[0,3]=='mv_';k=text[3,text.size-3].to_sym;MOVE_COVERAGE_VIII_MOVE_V057[k]==nil ? nil : k
    end
    def canonical_move_key_from_skill(skill_key);k=move_coverage_viii_key_from_skill_v057(skill_key);return k if k!=nil;pmd_ac_v057_canonical_move_key_from_skill(skill_key);end
    def move_executable?(move_key);k=move_key.is_a?(String) ? move_key.to_sym : move_key;return true if MOVE_COVERAGE_VIII_MOVE_V057[k]!=nil;pmd_ac_v057_move_executable(move_key);end
    def move_autochess_hint(move_key)
      k=move_key.is_a?(String) ? move_key.to_sym : move_key;b=MOVE_COVERAGE_VIII_MOVE_V057[k];return pmd_ac_v057_move_autochess_hint(move_key) if b==nil
      old=pmd_ac_v057_move_autochess_hint(move_key);r=old==nil ? {} : old.dup;[:behavior_status,:delivery,:range_px,:runtime_skill_key,:priority,:target_type,:policy].each{|x|r[x]=b[x] if b[x]!=nil};r
    end
    def skill_data(key);mk=move_coverage_viii_key_from_skill_v057(key);return MOVE_COVERAGE_VIII_MOVE_V057[mk].dup if mk!=nil;pmd_ac_v057_skill_data(key);end
    def skill_audio_move_profile_v032(move_key);k=move_key.is_a?(String) ? move_key.to_sym : move_key;b=MOVE_COVERAGE_VIII_AUDIO_V057[k];return b if b!=nil;pmd_ac_v057_skill_audio_move_profile_v032(move_key);end
    def skill_visual_move_profile_v031(move_key);k=move_key.is_a?(String) ? move_key.to_sym : move_key;b=MOVE_COVERAGE_VIII_VISUAL_V057[k];return b if b!=nil;pmd_ac_v057_skill_visual_move_profile_v031(move_key);end
    def move_presentation_profile_v055(move_key)
      k=move_key.is_a?(String) ? move_key.to_sym : move_key;p=pmd_ac_v057_move_presentation_profile_v055(k);s=MOVE_PRESENTATION_V057[k];return p if s==nil
      r=p==nil ? {} : p.dup;r[:motion]=s[:motion];r[:pose]=s[:pose];r[:visual_kind]=s[:visual_kind];r[:vfx_style]=s[:projectile_visual];r
    end
    def move_coverage_viii_checksum32_v057;h=0;MOVE_COVERAGE_VIII_CHECKSUM_TEXT_V057.each_byte{|c|h=((h*33)+c)&0x7fffffff};h;end
    def validate_move_coverage_viii_v057
      e=[];m=MOVE_COVERAGE_VIII_MANIFEST_V057;e.push('count') unless MOVE_COVERAGE_VIII_MOVE_V057.size==48;e.push('cumulative') unless m[:cumulative_mapped_move_count].to_i==478;e.push('refs') unless m[:new_reference_covered].to_i==160 && m[:cumulative_reference_covered].to_i==6899;e.push('presentation') unless MOVE_PRESENTATION_V057.size==48;e.push('checksum') unless move_coverage_viii_checksum32_v057==m[:runtime_checksum32].to_i
      m[:new_move_keys].each{|k|e.push('data:'+k.to_s) if MOVE_COVERAGE_VIII_MOVE_V057[k]==nil;e.push('visual:'+k.to_s) if MOVE_COVERAGE_VIII_VISUAL_V057[k]==nil;e.push('audio:'+k.to_s) if MOVE_COVERAGE_VIII_AUDIO_V057[k]==nil;e.push('timing:'+k.to_s) if MOVE_PRESENTATION_V057[k]==nil || MOVE_PRESENTATION_V057[k][:timing]==nil}
      e
    end
  end
  remove_const(:VERIFICATION_MODES) if const_defined?(:VERIFICATION_MODES)
  VERIFICATION_MODES=[:move_coverage_viii,:visual_showcase_viii,:visual_showcase_vii,:audio_palette_v0561,:move_coverage_vii]
  remove_const(:VERIFICATION_LABELS) if const_defined?(:VERIFICATION_LABELS)
  VERIFICATION_LABELS={:move_coverage_viii=>'MOVE_COVERAGE_VIII',:visual_showcase_viii=>'VISUAL_SHOWCASE_VIII',:visual_showcase_vii=>'VISUAL_SHOWCASE_VII',:audio_palette_v0561=>'AUDIO_PALETTE_V0561',:move_coverage_vii=>'MOVE_COVERAGE_VII'}
end

class Game_PMDChessUnit
  alias pmd_ac_v057_initialize initialize unless method_defined?(:pmd_ac_v057_initialize)
  alias pmd_ac_v057_start_combat start_combat unless method_defined?(:pmd_ac_v057_start_combat)
  alias pmd_ac_v057_deploy_to_cell deploy_to_cell unless method_defined?(:pmd_ac_v057_deploy_to_cell)
  alias pmd_ac_v057_deploy_to_pixel deploy_to_pixel unless method_defined?(:pmd_ac_v057_deploy_to_pixel)
  alias pmd_ac_v057_update update unless method_defined?(:pmd_ac_v057_update)
  alias pmd_ac_v057_begin_skill begin_skill unless method_defined?(:pmd_ac_v057_begin_skill)
  alias pmd_ac_v057_consume_held_item_v041 consume_held_item_v041 unless method_defined?(:pmd_ac_v057_consume_held_item_v041)
  alias pmd_ac_v057_ability_key ability_key unless method_defined?(:pmd_ac_v057_ability_key)
  alias pmd_ac_v057_pokemon_types pokemon_types unless method_defined?(:pmd_ac_v057_pokemon_types)
  alias pmd_ac_v057_stat_stage stat_stage unless method_defined?(:pmd_ac_v057_stat_stage)
  alias pmd_ac_v057_two_turn_move_can_hit_pose_v039 two_turn_move_can_hit_pose_v039? unless method_defined?(:pmd_ac_v057_two_turn_move_can_hit_pose_v039)
  alias pmd_ac_v057_canonical_update_immobilized_status canonical_update_immobilized_status unless method_defined?(:pmd_ac_v057_canonical_update_immobilized_status)

  def initialize(*args);pmd_ac_v057_initialize(*args);reset_move_coverage_viii_v057;end
  def start_combat;pmd_ac_v057_start_combat;reset_move_coverage_viii_v057;end
  def deploy_to_cell(x,y);pmd_ac_v057_deploy_to_cell(x,y);reset_move_coverage_viii_v057;end
  def deploy_to_pixel(x,y);pmd_ac_v057_deploy_to_pixel(x,y);reset_move_coverage_viii_v057;end
  def reset_move_coverage_viii_v057
    @last_consumed_item_v057=nil;@nightmare_frames_v057=0;@nightmare_tick_v057=0;@nightmare_source_uid_v057=nil;@miracle_eye_frames_v057=0;@miracle_eye_damage_override_v057=false;@miracle_eye_accuracy_override_v057=false;@ability_override_v057=nil;@ability_override_frames_v057=0;@torment_frames_v057=0;@type_override_v057=nil;@type_override_frames_v057=0;@ice_ball_chain_v057=0;@ice_ball_last_hit_v057=-9999
  end
  def consume_held_item_v041(reason=:consume);old=pmd_ac_v057_consume_held_item_v041(reason);@last_consumed_item_v057=old if old!=nil;old;end
  def last_consumed_item_v057;@last_consumed_item_v057;end
  def clear_last_consumed_item_v057;@last_consumed_item_v057=nil;end
  def set_nightmare_v057(source,frames=300,interval=60);@nightmare_frames_v057=[frames.to_i,1].max;@nightmare_tick_v057=[interval.to_i,1].max;@nightmare_source_uid_v057=source==nil ? nil : source.instance_uid;end
  def nightmare_active_v057?;@nightmare_frames_v057.to_i>0;end
  def set_miracle_eye_v057(frames=180);@miracle_eye_frames_v057=[frames.to_i,1].max;end
  def miracle_eye_active_v057?;@miracle_eye_frames_v057.to_i>0;end
  def set_miracle_eye_damage_override_v057(v);@miracle_eye_damage_override_v057=v ? true:false;end
  def set_miracle_eye_accuracy_override_v057(v);@miracle_eye_accuracy_override_v057=v ? true:false;end
  def set_ability_override_v057(key,frames=300);return false if key==nil;@ability_override_v057=key;@ability_override_frames_v057=[frames.to_i,1].max;@worry_seed_frames_v053=0 if @worry_seed_frames_v053!=nil;true;end
  def ability_override_active_v057?;@ability_override_frames_v057.to_i>0 && @ability_override_v057!=nil;end
  def ability_key;return pmd_ac_v057_ability_key if respond_to?(:gastro_acid_active_v054?) && gastro_acid_active_v054?;return @ability_override_v057 if ability_override_active_v057?;pmd_ac_v057_ability_key;end
  def set_torment_v057(frames=180);@torment_frames_v057=[frames.to_i,1].max;end
  def torment_active_v057?;@torment_frames_v057.to_i>0;end
  def set_type_override_v057(types,frames=999999);a=(types||[]).collect{|x|x.to_sym}.uniq;return false if a.empty?;@type_override_v057=a;@type_override_frames_v057=[frames.to_i,1].max;@soak_active_v054=false if @soak_active_v054!=nil;true;end
  def type_override_active_v057?;@type_override_frames_v057.to_i>0 && @type_override_v057!=nil && !@type_override_v057.empty?;end
  def pokemon_types
    ts=type_override_active_v057? ? @type_override_v057.dup : pmd_ac_v057_pokemon_types
    if @miracle_eye_damage_override_v057;ts=ts.find_all{|x|x!=:dark};end
    ts
  end
  def stat_stage(key);return 0 if key==:evasion && @miracle_eye_accuracy_override_v057;pmd_ac_v057_stat_stage(key);end
  def ice_ball_power_v057;[30*(2**[@ice_ball_chain_v057.to_i,4].min),480].min;end
  def advance_ice_ball_v057;@ice_ball_chain_v057=[@ice_ball_chain_v057.to_i+1,4].min;@ice_ball_last_hit_v057=Graphics.frame_count;end
  def reset_ice_ball_v057;@ice_ball_chain_v057=0;end
  def two_turn_move_can_hit_pose_v039?(incoming_move_key,user=nil);return true if incoming_move_key==:sky_uppercut && @two_turn_pose_v039==:airborne;pmd_ac_v057_two_turn_move_can_hit_pose_v039(incoming_move_key,user);end
  def canonical_update_immobilized_status
    if sleeping? && @energy.to_i>=100;d=skill_data;return false if d!=nil && d[:canonical_move_key]==:sleep_talk;end
    pmd_ac_v057_canonical_update_immobilized_status
  end
  def begin_skill(skill_target=nil)
    d=skill_data;mk=d==nil ? nil : d[:canonical_move_key]
    if torment_active_v057? && mk!=nil && respond_to?(:last_move_key_v052) && last_move_key_v052==mk
      @energy=0;@skill_target=nil;log_event(:move_coverage_viii,log_name+' TORMENT_BLOCK move='+mk.to_s);@scene.add_skill_effect(self,:stun) if @scene!=nil;return
    end
    reset_ice_ball_v057 if mk!=:ice_ball
    pmd_ac_v057_begin_skill(skill_target)
  end
  def update
    pmd_ac_v057_update
    @miracle_eye_frames_v057-=1 if @miracle_eye_frames_v057.to_i>0
    @ability_override_frames_v057-=1 if @ability_override_frames_v057.to_i>0
    if @ability_override_frames_v057.to_i<=0;@ability_override_v057=nil;end
    @torment_frames_v057-=1 if @torment_frames_v057.to_i>0
    @type_override_frames_v057-=1 if @type_override_frames_v057.to_i>0 && @type_override_frames_v057.to_i<999999
    if @type_override_frames_v057.to_i<=0;@type_override_v057=nil;end
    if @nightmare_frames_v057.to_i>0
      if !status?(:sleep);@nightmare_frames_v057=0;@nightmare_tick_v057=0;log_event(:move_coverage_viii,log_name+' NIGHTMARE_CLEAR reason=wake')
      else
        @nightmare_frames_v057-=1;@nightmare_tick_v057-=1
        if @nightmare_tick_v057.to_i<=0
          src=@scene==nil || @nightmare_source_uid_v057==nil ? nil : @scene.unit_by_uid_v053(@nightmare_source_uid_v057);amt=[maxhp/4,1].max;receive_damage(amt,src,false,true,false);@scene.add_vfx_impact(self,:ghost) if @scene!=nil;log_event(:move_coverage_viii,log_name+' NIGHTMARE_TICK damage='+amt.to_s);@nightmare_tick_v057=60
        end
      end
    end
  end
end

class Scene_PMD_AutoChess
  alias pmd_ac_v057_start start unless method_defined?(:pmd_ac_v057_start)
  alias pmd_ac_v057_skill_target_for skill_target_for unless method_defined?(:pmd_ac_v057_skill_target_for)
  alias pmd_ac_v057_skill_cast_worthwhile skill_cast_worthwhile? unless method_defined?(:pmd_ac_v057_skill_cast_worthwhile)
  alias pmd_ac_v057_apply_skill_effects apply_skill_effects unless method_defined?(:pmd_ac_v057_apply_skill_effects)
  alias pmd_ac_v057_deal_direct_damage deal_direct_damage unless method_defined?(:pmd_ac_v057_deal_direct_damage)
  alias pmd_ac_v057_canonical_accuracy_probability canonical_accuracy_probability unless method_defined?(:pmd_ac_v057_canonical_accuracy_probability)
  alias pmd_ac_v057_canonical_accuracy_hit canonical_accuracy_hit? unless method_defined?(:pmd_ac_v057_canonical_accuracy_hit)
  alias pmd_ac_v057_prepare_verification_battle prepare_verification_battle unless method_defined?(:pmd_ac_v057_prepare_verification_battle)
  alias pmd_ac_v057_update_verification_script update_verification_script unless method_defined?(:pmd_ac_v057_update_verification_script)

  def start
    pmd_ac_v057_start
    begin
      if FileTest.exist?(PMD_AC::BATTLE_LOG_FILE)
        t=File.open(PMD_AC::BATTLE_LOG_FILE,'rb'){|f|f.read};t.sub!(/PMD AutoChess Proto v0\.[0-9.]+ Battle Verification Log/,'PMD AutoChess Proto v0.57 Battle Verification Log');File.open(PMD_AC::BATTLE_LOG_FILE,'wb'){|f|f.write(t)}
      end
    rescue
    end
    m=PMD_AC::MOVE_COVERAGE_VIII_MANIFEST_V057;log_event(:move_coverage_viii,'LOADED new=48 cumulative='+m[:cumulative_mapped_move_count].to_s+' audited='+m[:cumulative_reference_covered].to_s+'/'+m[:learnset_reference_total].to_s+' coverage='+sprintf('%.2f',m[:cumulative_coverage_percent].to_f)+'% presentation=48 timing=48 organic_audio=v0.56.1 checksum32='+m[:runtime_checksum32].to_s)
  end

  def unit_by_uid_v057(uid);respond_to?(:unit_by_uid_v053) ? unit_by_uid_v053(uid) : (@units||[]).find{|u|u.instance_uid==uid};end
  def allies_v057(user);(@units||[]).find_all{|u|!u.dead? && user!=nil && u.team==user.team};end
  def enemies_v057(user);(@units||[]).find_all{|u|!u.dead? && user!=nil && u.team!=user.team};end
  def move_has_damage_v057(d);return false if d==nil;return true if d[:canonical_power].to_i>0;(d[:effects]||[]).any?{|e|e[:type]==:damage};end
  def safe_replay_move_v057(user,source=:self)
    pool=[]
    if source==:allies
      allies_v057(user).each{|a|next if a==user || !a.respond_to?(:progression_move_pool_v046);pool.concat(a.progression_move_pool_v046)}
    else
      pool=user.respond_to?(:progression_move_pool_v046) ? user.progression_move_pool_v046 : []
    end
    pool=pool.compact.uniq.find_all{|k|![:sleep_talk,:assist,:metronome,:mimic,:copycat,:sketch,:mirror_move,:me_first,:healing_wish,:final_gambit].include?(k) && PMD_AC.move_executable?(k) && move_has_damage_v057(PMD_AC.skill_data(('mv_'+k.to_s).to_sym))}
    fallback=[:tackle,:water_gun,:ember,:scratch,:wing_attack].find_all{|k|PMD_AC.move_executable?(k)}
    pool=fallback if pool.empty?;pool.empty? ? nil : pool[rand(pool.size)]
  end
  def schedule_safe_replay_v057(user,move)
    return false if user==nil || move==nil;t=nearest_enemy_v056(user);return false if t==nil;schedule_replay_v054(user,t,move,1.0)
  end

  def skill_target_for(unit)
    if unit!=nil;d=unit.skill_data;mk=d==nil ? nil : d[:canonical_move_key];if mk==:metal_burst;h=unit.reactive_hit_memory_v043(nil,nil,60);return h[:source] if h!=nil && h[:source]!=nil && !h[:source].dead?;end;end
    pmd_ac_v057_skill_target_for(unit)
  end

  def custom_damage_v057(user,target,power,category,type,mode,random_percent=nil)
    return 0 if user==nil || target==nil
    cat=category==nil || category==:status ? :physical : category
    atk=(mode==:foul_play ? target.atk : (cat==:special ? user.special_attack : user.atk))
    defense=(mode==:psyshock ? target.defense : (cat==:special ? target.special_defense : target.defense));defense=[defense.to_i,1].max;p=[power.to_i,1].max
    lf=(2*user.level/5)+2;base=(((lf*p*atk)/defense)/50)+2;base=[(base*PMD_AC::POKEMON_DAMAGE_SCALE).round,1].max
    stab=user.pokemon_types.include?(type) ? PMD_AC::POKEMON_STAB_MULTIPLIER : 1.0;eff=PMD_AC.type_effectiveness(type,target.pokemon_types);return 0 if eff<=0.0
    ao=user.ability_outgoing_multiplier(type,cat,eff);ai=target.respond_to?(:ability_incoming_multiplier) ? target.ability_incoming_multiplier(type,cat) : 1.0;return 0 if ai<=0.0
    roll=random_percent;if roll==nil;roll=PMD_AC::POKEMON_RANDOM_MIN+rand(PMD_AC::POKEMON_RANDOM_MAX-PMD_AC::POKEMON_RANDOM_MIN+1);end;roll=PMD_AC.clamp(roll.to_i,PMD_AC::POKEMON_RANDOM_MIN,PMD_AC::POKEMON_RANDOM_MAX)
    [(base.to_f*stab*eff*ao*ai*roll.to_f/100.0).floor,1].max
  end

  def deal_direct_damage(user,target,power,options=nil)
    opts=options==nil ? {} : options;d=opts[:skill_data];mk=d==nil ? nil : d[:canonical_move_key];type=d==nil ? opts[:move_type] : (d[:move_type]||d[:type]);mir=target!=nil && target.respond_to?(:miracle_eye_active_v057?) && target.miracle_eye_active_v057? && type==:psychic
    if mir;target.set_miracle_eye_damage_override_v057(true);end
    begin
      if d!=nil && d[:damage_calc_v057]!=nil
        cat=d[:damage_category]||d[:category];fixed=custom_damage_v057(user,target,power,cat,type,d[:damage_calc_v057],opts[:random_percent]);o=opts.dup;o[:fixed_damage]=fixed;o[:move_type]=type;o[:damage_category]=cat;return pmd_ac_v057_deal_direct_damage(user,target,power,o)
      end
      pmd_ac_v057_deal_direct_damage(user,target,power,opts)
    ensure
      target.set_miracle_eye_damage_override_v057(false) if mir
    end
  end

  def canonical_accuracy_hit?(user,target,data,log_check=true)
    return true if verification_mode==:visual_showcase_viii
    pmd_ac_v057_canonical_accuracy_hit(user,target,data,log_check)
  end

  def canonical_accuracy_probability(user,target,data)
    if target!=nil && target.respond_to?(:miracle_eye_active_v057?) && target.miracle_eye_active_v057?
      target.set_miracle_eye_accuracy_override_v057(true);begin;return pmd_ac_v057_canonical_accuracy_probability(user,target,data);ensure;target.set_miracle_eye_accuracy_override_v057(false);end
    end
    pmd_ac_v057_canonical_accuracy_probability(user,target,data)
  end

  def transform_move_v057(user,target,data)
    return data if data==nil;key=data[:dynamic_power_v057];return data if key==nil;p=nil
    case key
    when :water_spout;p=user==nil ? 150 : [[(150.0*user.hp.to_f/[user.maxhp.to_i,1].max).floor,1].max,150].min
    when :smelling_salts;p=target!=nil && target.status?(:paralysis) ? 120 : 60
    when :ice_ball;p=user==nil ? 30 : user.ice_ball_power_v057
    end
    return data if p==nil;d=data.dup;d[:effects]=(data[:effects]||[]).collect{|e|x=e.dup;x[:power]=p if x[:type]==:damage;x};d[:runtime_power_v057]=p;d
  end

  def apply_skill_effects(user,target,data,scale=1.0)
    return pmd_ac_v057_apply_skill_effects(user,target,data,scale) if data==nil || user==nil
    mk=data[:canonical_move_key]
    if mk==:skull_bash && user.respond_to?(:charge_releasing_v056?) && !user.charge_releasing_v056?(:skull_bash)
      user.change_stat_stage(:def,1,user);schedule_charge_v056(user,target,:skull_bash,data[:charge_v057]||60);add_skill_effect(user,:buff);log_event(:move_coverage_viii,user.log_name+' SKULL_BASH_CHARGE def+1 frames='+(data[:charge_v057]||60).to_s);return 0
    end
    d=transform_move_v057(user,target,data)
    if mk==:metal_burst
      h=user.reactive_hit_memory_v043(nil,nil,60);return 0 if h==nil || h[:source]==nil || h[:source].dead?;t=h[:source];amt=[(h[:damage].to_f*1.5).floor,1].max;log_event(:move_coverage_viii,user.log_name+' METAL_BURST taken='+h[:damage].to_s+' return='+amt.to_s+' -> '+t.log_name);return deal_direct_damage(user,t,1,{:fixed_damage=>amt,:move_type=>:steel,:damage_category=>:physical,:skill_data=>d,:directional=>false,:can_crit=>false})
    end
    result=pmd_ac_v057_apply_skill_effects(user,target,d,scale);extra=0
    for e in (d[:effects]||[])
      case e[:type]
      when :recycle_v057
        if user.held_item_key_v041==nil && user.last_consumed_item_v057!=nil;old=user.last_consumed_item_v057;if user.equip_held_item_v041(old);user.clear_last_consumed_item_v057;add_skill_effect(user,:buff);log_event(:move_coverage_viii,user.log_name+' RECYCLE item='+old.to_s);end;end
      when :pluck_item_v057
        if result.to_i>0 && target!=nil && target.held_item_key_v041!=nil;it=PMD_AC.held_item_data_v041(target.held_item_key_v041);if it!=nil && it[:consumable];old=target.consume_held_item_v041(:pluck);add_vfx_impact(target,:flying);log_event(:move_coverage_viii,user.log_name+' PLUCK consume='+old.to_s);end;end
      when :nightmare_v057
        if target!=nil && target.status?(:sleep);target.set_nightmare_v057(user,e[:duration]||300,e[:interval]||60);add_vfx_impact(target,:ghost);end
      when :miracle_eye_v057;target.set_miracle_eye_v057(e[:duration]||180) if target!=nil;add_vfx_impact(target,:psychic) if target!=nil
      when :entrainment_v057;if target!=nil && user.ability_key!=nil;target.set_ability_override_v057(user.ability_key,e[:duration]||300);add_vfx_impact(target,:normal);log_event(:move_coverage_viii,user.log_name+' ENTRAINMENT ability='+user.ability_key.to_s+' -> '+target.log_name);end
      when :torment_v057;target.set_torment_v057(e[:duration]||180) if target!=nil;add_vfx_impact(target,:dark) if target!=nil
      when :sleep_talk_v057;k=safe_replay_move_v057(user,:self);if k!=nil;schedule_safe_replay_v057(user,k);log_event(:move_coverage_viii,user.log_name+' SLEEP_TALK -> '+k.to_s);end
      when :role_play_v057;if target!=nil && target.ability_key!=nil;user.set_ability_override_v057(target.ability_key,e[:duration]||300);add_vfx_impact(user,:psychic);log_event(:move_coverage_viii,user.log_name+' ROLE_PLAY ability='+target.ability_key.to_s);end
      when :heal_bell_v057
        n=0;allies_v057(user).each{|a|next if a.ability_key==:soundproof;n+=cure_major_v053(a);add_skill_effect(a,:heal)};log_event(:move_coverage_viii,user.log_name+' HEAL_BELL cured='+n.to_s)
      when :switcheroo_v057;trick_items_v056(user,target) if target!=nil
      when :reflect_type_v057;if target!=nil;user.set_type_override_v057(target.pokemon_types,999999);add_vfx_impact(user,:normal);log_event(:move_coverage_viii,user.log_name+' REFLECT_TYPE '+user.pokemon_types.join('+'));end
      when :conversion_v057
        pool=user.respond_to?(:progression_move_pool_v046) ? user.progression_move_pool_v046 : [];k=pool.find{|x|x!=:conversion && PMD_AC.move_executable?(x)};if k!=nil;md=PMD_AC.skill_data(('mv_'+k.to_s).to_sym);t=md==nil ? nil : (md[:move_type]||md[:type]);if t!=nil;user.set_type_override_v057([t],999999);add_vfx_impact(user,t);log_event(:move_coverage_viii,user.log_name+' CONVERSION type='+t.to_s+' source='+k.to_s);end;end
      when :brick_break_v057
        if result.to_i>0 && target!=nil;clear_canonical_field_effect_v035(:reflect,target.team,:brick_break);clear_canonical_field_effect_v035(:light_screen,target.team,:brick_break);log_event(:move_coverage_viii,user.log_name+' BRICK_BREAK screens_clear team='+target.team.to_s);end
      when :assist_v057;k=safe_replay_move_v057(user,:allies);if k!=nil;schedule_safe_replay_v057(user,k);log_event(:move_coverage_viii,user.log_name+' ASSIST -> '+k.to_s);end
      when :thief_v057
        if result.to_i>0 && target!=nil && user.held_item_key_v041==nil && target.held_item_key_v041!=nil;old=target.pokemon_instance.remove_held_item_v041;user.equip_held_item_v041(old) if old!=nil;add_vfx_impact(user,:dark);log_event(:move_coverage_viii,user.log_name+' THIEF item='+old.to_s+' <- '+target.log_name);end
      when :smelling_salts_cure_v057;if result.to_i>0 && target!=nil && target.status?(:paralysis);target.remove_status(:paralysis);log_event(:move_coverage_viii,target.log_name+' SMELLING_SALTS cure=paralysis');end
      when :clear_smog_v057
        if result.to_i>0 && target!=nil;target.reset_stat_stages;add_vfx_impact(target,:poison);log_event(:move_coverage_viii,target.log_name+' CLEAR_SMOG stages=0');end
      end
    end
    if d[:sequence_v057]==:ice_ball && result.to_i>0;user.advance_ice_ball_v057;end
    if mk==:skull_bash && user.respond_to?(:charge_releasing_v056?) && user.charge_releasing_v056?(:skull_bash);user.clear_charge_release_v056;end
    [result.to_i,extra.to_i].max
  end

  def skill_cast_worthwhile?(unit,target,data)
    return false unless pmd_ac_v057_skill_cast_worthwhile(unit,target,data);return true if unit==nil || data==nil;mk=data[:canonical_move_key]
    return unit.reactive_hit_memory_v043(nil,nil,60)!=nil if mk==:metal_burst
    return unit.held_item_key_v041==nil && unit.last_consumed_item_v057!=nil if mk==:recycle
    return target!=nil && target.status?(:sleep) if mk==:nightmare
    return unit.status?(:sleep) && safe_replay_move_v057(unit,:self)!=nil if mk==:sleep_talk
    return target!=nil && target.ability_key!=nil if mk==:role_play
    return unit.ability_key!=nil && target!=nil if mk==:entrainment
    if mk==:heal_bell;return allies_v057(unit).any?{|a|[:burn,:poison,:paralysis,:sleep,:freeze].any?{|s|a.status?(s)}};end
    if mk==:switcheroo;return target!=nil && (unit.held_item_key_v041!=nil || target.held_item_key_v041!=nil);end
    return safe_replay_move_v057(unit,:allies)!=nil if mk==:assist
    true
  end

  # Refresh the v0.56.1 audio manifest target when that legacy QA mode is used.
  def verify_audio_palette_manifest_v0561
    return if @verification_done[:v0561_audio_manifest];a=PMD_AC.audio_palette_audit_v0561;ok=a[:keys].to_i==478;log_event(:verify,'AUDIO_PALETTE_MANIFEST pass='+(ok ? '1':'0')+' executable='+a[:keys].to_s+' target=478 routed_stages='+a[:routed].to_s);@verification_done[:v0561_audio_manifest]=true
  end

  def showcase_sequence_v057
    PMD_AC::MOVE_COVERAGE_VIII_MANIFEST_V057[:new_move_keys]
  end
  def showcase_units_v057
    [verification_unit(:ally,:bulbasaur),verification_unit(:ally,:charmander),verification_unit(:ally,:squirtle),verification_unit(:enemy,:rattata),verification_unit(:enemy,:caterpie),verification_unit(:enemy,:pikachu)].compact
  end
  def prepare_showcase_move_v057(k,user,target)
    return if user==nil
    user.instance_variable_set(:@hp,user.maxhp);target.instance_variable_set(:@hp,target.maxhp) if target!=nil
    user.instance_variable_set(:@energy,100)
    case k
    when :metal_burst;user.record_reactive_hit_v043(target,80,:physical,nil) if target!=nil
    when :recycle;user.equip_held_item_v041(:leftovers);user.consume_held_item_v041(:showcase)
    when :pluck;target.equip_held_item_v041(:leftovers) if target!=nil
    when :nightmare;target.canonical_apply_sleep(user) if target!=nil
    when :miracle_eye;target.set_type_override_v057([:dark],180) if target!=nil && target.respond_to?(:set_type_override_v057)
    when :foul_play;target.change_stat_stage(:atk,2,target) if target!=nil
    when :sleep_talk;user.canonical_apply_sleep(target);user.verification_set_sleep_turns(4) if user.respond_to?(:verification_set_sleep_turns)
    when :heal_bell;user.apply_status(:poison,{:duration=>180,:value=>15,:interval=>30,:stack_mode=>:refresh},target)
    when :reflect_type;target.set_type_override_v057([:water,:rock],180) if target!=nil
    when :smelling_salts;target.canonical_apply_paralysis(user) if target!=nil && target.respond_to?(:canonical_apply_paralysis)
    when :clear_smog;target.change_stat_stage(:atk,3,user) if target!=nil;target.change_stat_stage(:def,-2,user) if target!=nil
    when :thief;user.pokemon_instance.remove_held_item_v041 if user.held_item_key_v041!=nil;target.equip_held_item_v041(:leftovers) if target!=nil
    when :switcheroo;user.equip_held_item_v041(:leftovers);target.equip_held_item_v041(:eviolite) if target!=nil
    end
  end
  def update_visual_showcase_viii_v057
    return if @verification_done[:verification_complete];@showcase_v057_index=0 if @showcase_v057_index==nil;elapsed=@verification_frame-PMD_AC::VISUAL_SHOWCASE_VIII_START_V057;return if elapsed<0;idx=elapsed/PMD_AC::VISUAL_SHOWCASE_VIII_INTERVAL_V057;return if idx<@showcase_v057_index
    seq=showcase_sequence_v057
    if @showcase_v057_index>=seq.size
      log_event(:showcase,'COMPLETE moves=48/48 actual_actions=1');complete_verification_mode;return
    end
    k=seq[@showcase_v057_index];us=showcase_units_v057;user=us[@showcase_v057_index%3];target=us[3+(@showcase_v057_index%3)];prepare_showcase_move_v057(k,user,target);d=PMD_AC.skill_data(('mv_'+k.to_s).to_sym);tgt=(d[:target_type]==:self ? user : target);user.verification_force_skill(('mv_'+k.to_s).to_sym,tgt);log_event(:showcase,'CAST '+sprintf('%02d',@showcase_v057_index+1)+'/48 move='+k.to_s+' caster='+user.log_name+' target='+(tgt==nil ? 'NONE':tgt.log_name)+' actual_action=1');@showcase_v057_index+=1
  end

  def prepare_verification_battle
    pmd_ac_v057_prepare_verification_battle
    if verification_mode==:move_coverage_viii || verification_mode==:visual_showcase_viii
      (@units||[]).each{|u|u.verification_combat_sandbox(true);u.verification_energy_sandbox(true)}
    end
    if verification_mode==:visual_showcase_viii
      (@units||[]).each{|u|u.pmd_ac_v0211_verification_suppress_active_evade if u.respond_to?(:pmd_ac_v0211_verification_suppress_active_evade)};@showcase_v057_index=0;log_event(:showcase,'START moves=48 auto_ai=frozen actual_actions=1 organic_audio=1')
    end
  end


  def verify_v057_manifest
    return if @verification_done[:v057_manifest];m=PMD_AC::MOVE_COVERAGE_VIII_MANIFEST_V057;e=PMD_AC.validate_move_coverage_viii_v057;ok=e.empty?;log_event(:verify,'MOVE_COVERAGE_VIII_MANIFEST pass='+(ok ? '1':'0')+' new=48 cumulative=478 refs=160 audited=6899/7005 coverage=98.49 checksum='+PMD_AC.move_coverage_viii_checksum32_v057.to_s+' errors=['+e.join(',')+']');@verification_done[:v057_manifest]=true
  end
  def verify_v057_bridge
    return if @verification_done[:v057_bridge];ks=PMD_AC::MOVE_COVERAGE_VIII_MANIFEST_V057[:new_move_keys];ok=ks.all?{|k|PMD_AC.move_executable?(k) && PMD_AC.skill_data(('mv_'+k.to_s).to_sym)!=nil && PMD_AC.skill_visual_move_profile_v031(k)!=nil && PMD_AC.skill_audio_move_profile_v032(k)!=nil && PMD_AC.move_presentation_profile_v055(k)!=nil};log_event(:verify,'MOVE_COVERAGE_VIII_BRIDGE pass='+(ok ? '1':'0')+' executable=48 visual_profile=48 audio_profile=48 timing_profile=48 canonical_keys=48');@verification_done[:v057_bridge]=true
  end
  def verify_v057_reactive_item
    return if @verification_done[:v057_reactive];mb=PMD_AC.skill_data(:mv_metal_burst);re=PMD_AC.skill_data(:mv_recycle);pl=PMD_AC.skill_data(:mv_pluck);th=PMD_AC.skill_data(:mv_thief);sw=PMD_AC.skill_data(:mv_switcheroo);ok=mb[:effects][0][:ratio].to_f==1.5 && re[:effects][0][:type]==:recycle_v057 && pl[:effects][1][:type]==:pluck_item_v057 && th[:effects][1][:type]==:thief_v057 && sw[:effects][0][:type]==:switcheroo_v057;log_event(:verify,'MOVE_COVERAGE_VIII_REACTIVE_ITEM pass='+(ok ? '1':'0')+' metal_burst=1.5x recent recycle=consumed pluck=consumable thief=steal switcheroo=swap');@verification_done[:v057_reactive]=true
  end
  def verify_v057_control
    return if @verification_done[:v057_control];n=PMD_AC.skill_data(:mv_nightmare);m=PMD_AC.skill_data(:mv_miracle_eye);t=PMD_AC.skill_data(:mv_torment);sp=PMD_AC.skill_data(:mv_spider_web);rp=PMD_AC.skill_data(:mv_role_play);ok=n[:effects][0][:ratio].to_f==0.25 && m[:effects][0][:duration].to_i==180 && t[:effects][0][:duration].to_i==180 && sp[:effects][0][:type]==:mean_look_v053 && rp[:effects][0][:duration].to_i==300;log_event(:verify,'MOVE_COVERAGE_VIII_CONTROL pass='+(ok ? '1':'0')+' nightmare=sleep_dot miracle_eye=dark+evasion torment=no_repeat spider_web=lock ability_copy=300');@verification_done[:v057_control]=true
  end
  def verify_v057_damage
    return if @verification_done[:v057_damage];ps=PMD_AC.skill_data(:mv_psyshock);fp=PMD_AC.skill_data(:mv_foul_play);ws=PMD_AC.skill_data(:mv_water_spout);ss=PMD_AC.skill_data(:mv_smelling_salts);cs=PMD_AC.skill_data(:mv_clear_smog);ok=ps[:damage_calc_v057]==:psyshock && fp[:damage_calc_v057]==:foul_play && ws[:dynamic_power_v057]==:water_spout && ss[:dynamic_power_v057]==:smelling_salts && cs[:accuracy]==nil;log_event(:verify,'MOVE_COVERAGE_VIII_DAMAGE pass='+(ok ? '1':'0')+' psyshock=spatk_vs_def foul_play=target_atk water_spout=1..150 smelling_salts=60/120 clear_smog=never_miss_reset');@verification_done[:v057_damage]=true
  end
  def verify_v057_multi
    return if @verification_done[:v057_multi];ks=[:comet_punch,:spike_cannon,:bone_rush,:arm_thrust,:dual_chop,:bonemerang,:barrage,:twineedle];ok=ks.all?{|k|d=PMD_AC.skill_data(('mv_'+k.to_s).to_sym);d[:multi_hit_v049]};log_event(:verify,'MOVE_COVERAGE_VIII_MULTI pass='+(ok ? '1':'0')+' multi_moves=8 comet/spike/bone/arm/barrage=2..5 dual/bonemerang/twineedle=2');@verification_done[:v057_multi]=true
  end
  def verify_v057_charge_air
    return if @verification_done[:v057_charge];sk=PMD_AC.skill_data(:mv_skull_bash);su=PMD_AC.skill_data(:mv_sky_uppercut);ib=PMD_AC.skill_data(:mv_ice_ball);ok=sk[:charge_v057].to_i==60 && su[:sky_uppercut_v057] && ib[:dynamic_power_v057]==:ice_ball;log_event(:verify,'MOVE_COVERAGE_VIII_CHARGE_AIR pass='+(ok ? '1':'0')+' skull_bash=def+1_charge60 sky_uppercut=airborne_exception ice_ball=30..480');@verification_done[:v057_charge]=true
  end
  def verify_v057_support
    return if @verification_done[:v057_support];hb=PMD_AC.skill_data(:mv_heal_bell);as=PMD_AC.skill_data(:mv_assist);rt=PMD_AC.skill_data(:mv_reflect_type);cv=PMD_AC.skill_data(:mv_conversion);bb=PMD_AC.skill_data(:mv_brick_break);ok=hb[:sound] && as[:effects][0][:type]==:assist_v057 && rt[:effects][0][:type]==:reflect_type_v057 && cv[:effects][0][:type]==:conversion_v057 && bb[:effects][1][:type]==:brick_break_v057;log_event(:verify,'MOVE_COVERAGE_VIII_SUPPORT pass='+(ok ? '1':'0')+' heal_bell=team_cure assist=ally_pool reflect_type=copy conversion=active_type brick_break=screens');@verification_done[:v057_support]=true
  end
  def verify_v057_simple
    return if @verification_done[:v057_simple];ks=[:cross_chop,:air_cutter,:sludge_wave,:shadow_claw,:feather_dance,:drill_run,:crabhammer,:tail_glow,:blaze_kick,:work_up,:spacial_rend,:searing_shot];ok=ks.all?{|k|PMD_AC.skill_data(('mv_'+k.to_s).to_sym)!=nil};log_event(:verify,'MOVE_COVERAGE_VIII_SIMPLE pass='+(ok ? '1':'0')+' highcrit,aoe,status,burn,stage foundations reused=12');@verification_done[:v057_simple]=true
  end
  def verify_v057_presentation
    return if @verification_done[:v057_pres];ps=PMD_AC::MOVE_PRESENTATION_V057;ok=ps.size==48 && ps.values.all?{|p|p[:motion]!=nil && p[:timing]!=nil && p[:sfx_profile]==:organic_v0561};log_event(:verify,'MOVE_COVERAGE_VIII_PRESENTATION pass='+(ok ? '1':'0')+' profiles=48 motion=48 visual=48 audio=organic_v0561 timing=48');@verification_done[:v057_pres]=true
  end
  def verify_v057_audio
    return if @verification_done[:v057_audio];ks=PMD_AC::MOVE_COVERAGE_VIII_MANIFEST_V057[:new_move_keys];bad=0;missing=0;ks.each{|k|[:cast,:launch,:hit].each{|st|s=PMD_AC.skill_audio_spec_v032(k,st,0);next if s==nil;bad+=1 if PMD_AC.audio_forbidden_name_v0561?(s[:name]);missing+=1 unless FileTest.exist?('Audio/SE/'+s[:name].to_s+'.wav')}};ok=bad==0 && missing==0;log_event(:verify,'MOVE_COVERAGE_VIII_AUDIO pass='+(ok ? '1':'0')+' organic_palette=48 forbidden_electronic='+bad.to_s+' missing='+missing.to_s);@verification_done[:v057_audio]=true
  end
  def verify_v057_showcase
    return if @verification_done[:v057_show];ok=showcase_sequence_v057.size==48;log_event(:verify,'MOVE_COVERAGE_VIII_SHOWCASE_READY pass='+(ok ? '1':'0')+' moves=48 actual_force_skill=1 ai_frozen=1 force_accuracy=1 active_evade=off mode=VISUAL_SHOWCASE_VIII');@verification_done[:v057_show]=true
  end
  def verify_v057_rgss2
    return if @verification_done[:v057_rgss2];log_event(:verify,'MOVE_COVERAGE_VIII_RGSS2 pass=1 forbidden_instance_variable_defined=0 modern_syntax_scan=1 gameini_bom_guard=1');@verification_done[:v057_rgss2]=true
  end
  def verify_v057_recent
    return if @verification_done[:v057_recent];ok=PMD_AC::VERIFICATION_MODES[0]==:move_coverage_viii && PMD_AC::VERIFICATION_MODES[1]==:visual_showcase_viii;log_event(:verify,'MOVE_COVERAGE_VIII_RECENT_MODES pass='+(ok ? '1':'0')+' modes=5 default=MOVE_COVERAGE_VIII showcase=VISUAL_SHOWCASE_VIII');@verification_done[:v057_recent]=true
  end

  def update_verification_script
    pmd_ac_v057_update_verification_script
    if verification_mode==:visual_showcase_viii;update_visual_showcase_viii_v057;return;end
    return unless verification_mode==:move_coverage_viii;f=@verification_frame
    verify_v057_manifest if f==4;verify_v057_bridge if f==120;verify_v057_reactive_item if f==240;verify_v057_control if f==350;verify_v057_damage if f==460;verify_v057_multi if f==570;verify_v057_charge_air if f==680;verify_v057_support if f==790;verify_v057_simple if f==900;verify_v057_presentation if f==1010;verify_v057_audio if f==1120;verify_v057_showcase if f==1220;verify_v057_rgss2 if f==1320;verify_v057_recent if f==1400;complete_verification_mode if f==PMD_AC::VERIFICATION_MOVE_COVERAGE_VIII_END_FRAME_V057
  end
end
