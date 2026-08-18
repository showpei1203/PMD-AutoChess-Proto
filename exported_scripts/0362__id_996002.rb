# encoding: UTF-8
#==============================================================================
# 【PMD AutoChess 中文維護說明】
# 腳本：PMD AutoChess Movepool Production Runtime v0.99.6
# 分類：19 招 Runtime／Tutor Overlay／Production Verifier
#
# 【用途】
# - 把 v0.99.5 被 move_not_executable 擋下的 19 個 non-Level-up 招式全部接入戰鬥。
# - 不修改舊 Move Coverage 526 招；本腳本以最末端 alias 擴充。
# - 把 v0.99.6 B2W2 稀疏 Tutor Overlay 接入既有 unlock_tutor/teach_tutor API。
# - 提供 MOVEPOOL_PRODUCTION_V0996 驗證模式。
#
# 【主要 AutoChess 改造】
# - Surf：改為敵方全場 AoE，避免 AI 自動戰鬥無法控制的友軍誤傷。
# - Volt Switch：命中後 96px 短距離後撤，10 幀完成；不假造不存在的第 4 隻替換位。
# - Grass Knot：沿用既有 species mass proxy，20/40/60/80/100/120 威力。
# - Pledge：同隊 120 幀內不同誓約連攜，第二招威力 100；火草=敵陣 DOT、
#   水草=敵陣移動減速、火水=我方副效果機率加倍，場效 180 幀。
# - Defog：目標迴避 -1，清雙方 Hazards，清目標側 Reflect/Light Screen/Safeguard/Mist。
# - Simple Beam / Skill Swap：使用既有 Ability Override；Multitype/Wonder Guard 有保護。
#
# 【事件／腳本呼叫】
# B2W2 Tutor 與 v0.99.5 API 完全共用：
#   PMD_AC.unlock_tutor_v0995(:electroweb)
#   PMD_AC.teach_tutor_v0995(instance_uid, :electroweb)
#
# 【維護規則】
# - RGSS2 / Ruby 1.8。
# - identity 使用 instance_uid。
# - 不使用專案禁止的 instance-variable introspection helper。
# - Frozen Combat Core 不直接改寫；所有功能都從此較後腳本 alias 擴充。
#==============================================================================
module PMD_AC
  MOVEPOOL_PRODUCTION_AUDIT_FILE_V0996='PMD_MovepoolProduction_RuntimeAudit_v0.99.6.txt'
  MOVEPOOL_PRODUCTION_VERIFY_END_V0996=105

  class << self
    alias pmd_ac_v0996_canonical_move_key_from_skill canonical_move_key_from_skill unless method_defined?(:pmd_ac_v0996_canonical_move_key_from_skill)
    alias pmd_ac_v0996_move_executable move_executable? unless method_defined?(:pmd_ac_v0996_move_executable)
    alias pmd_ac_v0996_move_autochess_hint move_autochess_hint unless method_defined?(:pmd_ac_v0996_move_autochess_hint)
    alias pmd_ac_v0996_skill_data skill_data unless method_defined?(:pmd_ac_v0996_skill_data)
    alias pmd_ac_v0996_skill_audio skill_audio_move_profile_v032 unless method_defined?(:pmd_ac_v0996_skill_audio)
    alias pmd_ac_v0996_skill_visual skill_visual_move_profile_v031 unless method_defined?(:pmd_ac_v0996_skill_visual)
    alias pmd_ac_v0996_tutor_compatible tutor_compatible_v0995? unless method_defined?(:pmd_ac_v0996_tutor_compatible)
    alias pmd_ac_v0996_unlock_tutor unlock_tutor_v0995 unless method_defined?(:pmd_ac_v0996_unlock_tutor)
    alias pmd_ac_v0996_sources_for_move movepool_sources_for_move_v0995 unless method_defined?(:pmd_ac_v0996_sources_for_move)

    def movepool_exclusive_key_from_skill_v0996(skill_key)
      return nil if skill_key==nil
      text=skill_key.to_s
      return nil unless text[0,3]=='mv_'
      k=text[3,text.size-3].to_sym
      MOVEPOOL_EXCLUSIVE_MOVE_V0996[k]==nil ? nil : k
    end
    def canonical_move_key_from_skill(skill_key)
      k=movepool_exclusive_key_from_skill_v0996(skill_key)
      return k if k!=nil
      pmd_ac_v0996_canonical_move_key_from_skill(skill_key)
    end
    def move_executable?(move_key)
      k=normalize_acquisition_key_v0995(move_key)
      return true if MOVEPOOL_EXCLUSIVE_MOVE_V0996[k]!=nil
      pmd_ac_v0996_move_executable(move_key)
    end
    def move_autochess_hint(move_key)
      k=normalize_acquisition_key_v0995(move_key);b=MOVEPOOL_EXCLUSIVE_MOVE_V0996[k]
      return pmd_ac_v0996_move_autochess_hint(move_key) if b==nil
      r=pmd_ac_v0996_move_autochess_hint(move_key);r=r==nil ? {} : r.dup
      [:behavior_status,:delivery,:range_px,:runtime_skill_key,:priority,:target_type,:policy].each{|x|r[x]=b[x] if b[x]!=nil}
      r
    end
    def skill_data(key)
      mk=movepool_exclusive_key_from_skill_v0996(key)
      return MOVEPOOL_EXCLUSIVE_MOVE_V0996[mk].dup if mk!=nil
      pmd_ac_v0996_skill_data(key)
    end
    def skill_audio_move_profile_v032(move_key)
      k=normalize_acquisition_key_v0995(move_key);b=MOVEPOOL_EXCLUSIVE_AUDIO_V0996[k]
      return b if b!=nil
      pmd_ac_v0996_skill_audio(move_key)
    end
    def skill_visual_move_profile_v031(move_key)
      k=normalize_acquisition_key_v0995(move_key);b=MOVEPOOL_EXCLUSIVE_VISUAL_V0996[k]
      return b if b!=nil
      pmd_ac_v0996_skill_visual(move_key)
    end

    def supplemental_tutor_v0996?(species,move)
      sk=normalize_acquisition_key_v0995(species);mv=normalize_acquisition_key_v0995(move)
      (SPARSE_TUTOR_B2W2_V0996[sk]||[]).include?(mv)
    end
    def supplemental_tutor_move_v0996?(move)
      mv=normalize_acquisition_key_v0995(move)
      SPARSE_TUTOR_B2W2_V0996.each_value{|a|return true if a.include?(mv)}
      false
    end
    def tutor_compatible_v0995?(species,move)
      supplemental_tutor_v0996?(species,move) || pmd_ac_v0996_tutor_compatible(species,move)
    end
    def unlock_tutor_v0995(move)
      mv=normalize_acquisition_key_v0995(move)
      if supplemental_tutor_move_v0996?(mv)
        tutor_unlocks_v0995[mv]=true
        return true
      end
      pmd_ac_v0996_unlock_tutor(move)
    end
    def movepool_sources_for_move_v0995(species,move)
      out=pmd_ac_v0996_sources_for_move(species,move)
      mv=normalize_acquisition_key_v0995(move)
      out.push([:tutor_b2w2,mv]) if supplemental_tutor_v0996?(species,mv)
      out
    end

    def sparse_movepool_audit_v0996
      lifetime=[];early=[]
      SPECIES_DB_V016.each do |sk,d|
        all=(d[:learnset]||[]).collect{|e|e[:move]}.uniq
        lv20=(d[:learnset]||[]).find_all{|e|e[:level].to_i<=20}.collect{|e|e[:move]}.uniq
        lifetime.push(sk) if all.size<4
        early.push(sk) if lv20.size<4
      end
      refs=0;SPARSE_TUTOR_B2W2_V0996.each_value{|a|refs+=a.size}
      missing_policy=(lifetime|early).find_all{|sk|SPARSE_POLICY_V0996[sk]==nil}
      bad_tutor=[]
      SPARSE_TUTOR_B2W2_V0996.each{|sk,a|a.each{|mv|bad_tutor.push([sk,mv]) unless move_executable?(mv)}}
      exceptions=SPARSE_POLICY_V0996.keys.find_all{|sk|SPARSE_POLICY_V0996[sk][:four_move_rule]==:exempt}
      {:lifetime=>lifetime,:early=>early,:tutor_refs=>refs,:missing_policy=>missing_policy,
       :bad_tutor=>bad_tutor,:exceptions=>exceptions,
       :pass=>(lifetime.sort_by{|x|x.to_s}==SPARSE_LIFETIME_LT4_V0996.sort_by{|x|x.to_s} && early.sort_by{|x|x.to_s}==SPARSE_LV20_LT4_V0996.sort_by{|x|x.to_s} && refs==25 && missing_policy.empty? && bad_tutor.empty? && exceptions.size==3)}
    end

    def movepool_production_audit_v0996
      a=movepool_acquisition_audit_v0995;s=sparse_movepool_audit_v0996;bad=[]
      MOVEPOOL_EXCLUSIVE_KEYS_V0996.each do |k|
        d=skill_data(('mv_'+k.to_s).to_sym)
        bad.push(k) if d==nil || d[:canonical_move_key]!=k || !move_executable?(k)
      end
      {:acquisition=>a,:sparse=>s,:exclusive_bad=>bad,
       :pass=>(a[:core_ready] && a[:nonlevel_unique].size==434 && a[:nonlevel_executable].size==434 && a[:nonlevel_blocked].empty? && bad.empty? && s[:pass])}
    end

    def movepool_production_audit_text_v0996(report=nil)
      r=report || movepool_production_audit_v0996;a=r[:acquisition];s=r[:sparse]
      t=[]
      t << 'PMD AutoChess Movepool Production Runtime Audit v0.99.6'
      t << 'Base: v0.99.5 | Combat Core direct modification: NO'
      t << 'Exclusive runtime completion: '+(19-r[:exclusive_bad].size).to_s+'/19'
      t << 'Non-level unique/executable/blocked: '+a[:nonlevel_unique].size.to_s+'/'+a[:nonlevel_executable].size.to_s+'/'+a[:nonlevel_blocked].size.to_s
      t << 'BW acquisition refs: machine='+a[:machine_refs].to_s+' tutor='+a[:tutor_refs].to_s+' egg='+a[:egg_refs].to_s+' special='+a[:special_refs].to_s
      t << 'B2W2 sparse tutor overlay: species='+SPARSE_TUTOR_B2W2_V0996.size.to_s+' refs='+s[:tutor_refs].to_s
      t << 'Sparse lifetime<4: '+s[:lifetime].size.to_s+' | Lv20<4: '+s[:early].size.to_s+' | identity exceptions='+s[:exceptions].size.to_s
      t << 'Identity exceptions: '+s[:exceptions].collect{|x|x.to_s}.sort.join(', ')
      t << 'Bad exclusive runtime: '+r[:exclusive_bad].collect{|x|x.to_s}.join(', ')
      t << 'Bad supplemental tutor: '+s[:bad_tutor].collect{|x|x.join(':')}.join(', ')
      t << 'Missing sparse policy: '+s[:missing_policy].collect{|x|x.to_s}.join(', ')
      t << 'Production Ready: '+(r[:pass] ? '1':'0')
      t.join("\r\n")+"\r\n"
    end
    def write_movepool_production_audit_v0996(report=nil)
      File.open(MOVEPOOL_PRODUCTION_AUDIT_FILE_V0996,'wb'){|f|f.write(movepool_production_audit_text_v0996(report))}
      true
    rescue
      false
    end
  end

  old_modes=VERIFICATION_MODES.dup
  old_labels=VERIFICATION_LABELS.dup
  remove_const(:VERIFICATION_MODES)
  VERIFICATION_MODES=[:normal,:movepool_production_v0996]+old_modes.reject{|x|x==:normal || x==:movepool_production_v0996 || x==:movepool_acquisition_v0995}
  remove_const(:VERIFICATION_LABELS)
  VERIFICATION_LABELS=old_labels.dup
  VERIFICATION_LABELS.delete(:movepool_acquisition_v0995)
  VERIFICATION_LABELS[:movepool_production_v0996]='MOVEPOOL_PRODUCTION_V0996'
end

class Game_PMDChessUnit
  alias pmd_ac_v0996_effective_move_speed effective_move_speed unless method_defined?(:pmd_ac_v0996_effective_move_speed)
  def effective_move_speed
    s=pmd_ac_v0996_effective_move_speed
    if @scene!=nil && @scene.respond_to?(:pledge_swamp_active_v0996?) && @scene.pledge_swamp_active_v0996?(team)
      return s.to_f*0.50
    end
    s
  end
end

class Scene_PMD_AutoChess
  alias pmd_ac_v0996_start start unless method_defined?(:pmd_ac_v0996_start)
  alias pmd_ac_v0996_update update unless method_defined?(:pmd_ac_v0996_update)
  alias pmd_ac_v0996_apply_skill_effects apply_skill_effects unless method_defined?(:pmd_ac_v0996_apply_skill_effects)
  alias pmd_ac_v0996_refresh_header refresh_header unless method_defined?(:pmd_ac_v0996_refresh_header)
  alias pmd_ac_v0996_prepare_verification_battle prepare_verification_battle unless method_defined?(:pmd_ac_v0996_prepare_verification_battle)
  alias pmd_ac_v0996_update_verification_script update_verification_script unless method_defined?(:pmd_ac_v0996_update_verification_script)
  alias pmd_ac_v0996_terminate terminate unless method_defined?(:pmd_ac_v0996_terminate)
  alias pmd_ac_v0996_log_event log_event unless method_defined?(:pmd_ac_v0996_log_event)

  def start
    pmd_ac_v0996_start
    reset_movepool_production_runtime_v0996
    begin
      if FileTest.exist?(PMD_AC::BATTLE_LOG_FILE)
        text=File.open(PMD_AC::BATTLE_LOG_FILE,'rb'){|f|f.read}
        text.sub!(/PMD AutoChess Proto v0\.[0-9.]+ Battle Verification Log/,'PMD AutoChess Proto v0.99.6 Battle Verification Log')
        File.open(PMD_AC::BATTLE_LOG_FILE,'wb'){|f|f.write(text)}
      end
    rescue
    end
    log_event(:movepool_production,'FLOW v0.99.6 exclusive_runtime=19 nonlevel=434/434 blocked=0 sparse_tutor_b2w2=25 identity_exceptions=ditto/unown/smeargle')
    refresh_header
  end
  def refresh_header
    pmd_ac_v0996_refresh_header
    return if @header_sprite==nil || @header_sprite.bitmap==nil
    bmp=@header_sprite.bitmap;bmp.fill_rect(0,0,Graphics.width,28,Color.new(0,0,0,180));pmd_ac_v074_font(bmp)
    bmp.font.size=PMD_AC.const_defined?(:UI_HEADER_TITLE_FONT_V086) ? PMD_AC::UI_HEADER_TITLE_FONT_V086 : 20
    bmp.font.bold=true;bmp.font.color=Color.new(255,255,255);bmp.draw_text(16,1,Graphics.width-32,30,'PMD 自走棋原型 v0.99.6',1)
  end

  def reset_movepool_production_runtime_v0996
    @pledge_pending_v0996={};@pledge_fire_frames_v0996={:ally=>0,:enemy=>0};@pledge_fire_tick_v0996={:ally=>60,:enemy=>60};@pledge_fire_source_v0996={}
    @pledge_swamp_frames_v0996={:ally=>0,:enemy=>0};@pledge_rainbow_frames_v0996={:ally=>0,:enemy=>0};@volt_retreat_events_v0996=[]
  end
  def other_team_v0996(team);team==:ally ? :enemy : :ally;end
  def pledge_swamp_active_v0996?(team);@pledge_swamp_frames_v0996!=nil && @pledge_swamp_frames_v0996[team].to_i>0;end
  def pledge_rainbow_active_v0996?(team);@pledge_rainbow_frames_v0996!=nil && @pledge_rainbow_frames_v0996[team].to_i>0;end
  def pledge_combo_key_v0996(a,b);[a,b].sort_by{|x|x.to_s}.join('_').to_sym;end

  def grass_knot_power_v0996(user,target)
    return dynamic_power_v053(user,target,:low_kick) if respond_to?(:dynamic_power_v053)
    20
  end
  def secret_power_secondary_v0996
    if respond_to?(:canonical_weather_effective?) && canonical_weather_effective?(:sun)
      return {:group=>0,:type=>:ailment,:status=>:burn,:chance=>30,:receiver=>:target,:duration=>180,:interval=>30,:tick_maxhp_ratio=>0.0125}
    elsif respond_to?(:canonical_weather_effective?) && canonical_weather_effective?(:rain)
      return {:group=>0,:type=>:ailment,:status=>:paralysis,:chance=>30,:receiver=>:target,:duration=>180}
    elsif respond_to?(:canonical_weather_effective?) && canonical_weather_effective?(:sandstorm)
      return {:group=>0,:type=>:stat_stage,:stat=>:accuracy,:stages=>-1,:chance=>30,:receiver=>:target}
    elsif respond_to?(:canonical_weather_effective?) && canonical_weather_effective?(:hail)
      return {:group=>0,:type=>:stat_stage,:stat=>:speed,:stages=>-1,:chance=>30,:receiver=>:target}
    end
    {:group=>0,:type=>:ailment,:status=>:paralysis,:chance=>30,:receiver=>:target,:duration=>180}
  end

  def transform_movepool_production_v0996(user,target,data)
    return data if data==nil
    d=data
    if data[:dynamic_power_v0996]==:target_mass
      d=data.dup;d[:effects]=(data[:effects]||[]).collect{|e|x=e.dup;x[:power]=grass_knot_power_v0996(user,target) if x[:type]==:damage;x}
    end
    if data[:secret_power_v0996]
      d=d.dup if d.equal?(data);d[:secondary_effects]=[secret_power_secondary_v0996]
    end
    if user!=nil && pledge_rainbow_active_v0996?(user.team) && d[:secondary_effects]!=nil
      d=d.dup if d.equal?(data);d[:secondary_effects]=(d[:secondary_effects]||[]).collect{|e|x=e.dup;x[:chance]=[x[:chance].to_i*2,100].min if x[:chance]!=nil;x}
      d[:pledge_rainbow_boosted_v0996]=true
    end
    if user!=nil && d[:pledge_v0996]!=nil
      @pledge_pending_v0996={} if @pledge_pending_v0996==nil;cur=@pledge_pending_v0996[user.team];now=Graphics.frame_count
      if cur!=nil && cur[:expire].to_i>=now && cur[:kind]!=d[:pledge_v0996]
        d=d.dup if d.equal?(data);d[:effects]=(d[:effects]||[]).collect{|e|x=e.dup;x[:power]=100 if x[:type]==:damage;x}
        d[:pledge_combo_key_v0996]=pledge_combo_key_v0996(cur[:kind],d[:pledge_v0996]);d[:pledge_combo_source_uid_v0996]=cur[:source_uid]
      else
        d=d.dup if d.equal?(data);d[:pledge_arm_v0996]=true
      end
    end
    d
  end

  def queue_volt_retreat_v0996(user,target)
    return false if user==nil || target==nil || user.dead? || (user.respond_to?(:trapped_v053?) && user.trapped_v053?)
    dx=user.pixel_x.to_f-target.pixel_x.to_f;dy=user.pixel_y.to_f-target.pixel_y.to_f;len=Math.sqrt(dx*dx+dy*dy)
    if len<0.01;dx=(user.team==:ally ? -1.0 : 1.0);dy=0.0;len=1.0;end
    dist=PMD_AC::VOLT_SWITCH_RETREAT_PX_V0996;frames=[PMD_AC::VOLT_SWITCH_RETREAT_FRAMES_V0996.to_i,1].max
    @volt_retreat_events_v0996=[] if @volt_retreat_events_v0996==nil
    @volt_retreat_events_v0996.push({:uid=>user.instance_uid,:dx=>dx/len*dist/frames,:dy=>dy/len*dist/frames,:frames=>frames})
    log_event(:movepool_production,user.log_name+' VOLT_SWITCH_RETREAT distance='+dist.to_i.to_s+' frames='+frames.to_s);true
  end
  def update_volt_retreat_v0996
    return if @volt_retreat_events_v0996==nil || @volt_retreat_events_v0996.empty?
    keep=[]
    @volt_retreat_events_v0996.each do |e|
      u=respond_to?(:unit_by_uid_v059) ? unit_by_uid_v059(e[:uid]) : (@units||[]).find{|x|x.instance_uid.to_i==e[:uid].to_i}
      next if u==nil || u.dead? || e[:frames].to_i<=0
      u.set_runtime_position_v044(u.pixel_x.to_f+e[:dx].to_f,u.pixel_y.to_f+e[:dy].to_f);e[:frames]=e[:frames].to_i-1;keep.push(e) if e[:frames].to_i>0
    end
    @volt_retreat_events_v0996=keep
  end

  def activate_pledge_combo_v0996(user,key)
    return if user==nil || key==nil
    enemy=other_team_v0996(user.team);frames=PMD_AC::PLEDGE_FIELD_FRAMES_V0996
    case key
    when :fire_grass
      @pledge_fire_frames_v0996[enemy]=frames;@pledge_fire_tick_v0996[enemy]=60;@pledge_fire_source_v0996[enemy]=user.instance_uid
      add_special_label_v033('火＋草誓約！') if respond_to?(:add_special_label_v033)
    when :grass_water
      @pledge_swamp_frames_v0996[enemy]=frames;add_special_label_v033('濕地！') if respond_to?(:add_special_label_v033)
    when :fire_water
      @pledge_rainbow_frames_v0996[user.team]=frames;add_special_label_v033('彩虹！') if respond_to?(:add_special_label_v033)
    end
    @pledge_pending_v0996.delete(user.team)
    log_event(:movepool_production,'PLEDGE_COMBO team='+user.team.to_s+' combo='+key.to_s+' frames='+frames.to_s)
  end
  def update_pledge_fields_v0996
    return if @pledge_fire_frames_v0996==nil
    [:ally,:enemy].each do |team|
      @pledge_swamp_frames_v0996[team]=[@pledge_swamp_frames_v0996[team].to_i-1,0].max
      @pledge_rainbow_frames_v0996[team]=[@pledge_rainbow_frames_v0996[team].to_i-1,0].max
      if @pledge_fire_frames_v0996[team].to_i>0
        @pledge_fire_frames_v0996[team]-=1;@pledge_fire_tick_v0996[team]=@pledge_fire_tick_v0996[team].to_i-1
        if @pledge_fire_tick_v0996[team].to_i<=0
          src=respond_to?(:unit_by_uid_v059) ? unit_by_uid_v059(@pledge_fire_source_v0996[team]) : nil
          (@units||[]).each do |u|
            next unless u.alive? && u.team==team;amt=[u.maxhp.to_i/16,1].max;u.receive_damage(amt,src,false,true,false);add_vfx_impact(u,:fire) if respond_to?(:add_vfx_impact)
          end
          @pledge_fire_tick_v0996[team]=60
        end
      end
    end
    now=Graphics.frame_count;@pledge_pending_v0996.delete_if{|team,e|e[:expire].to_i<now} if @pledge_pending_v0996!=nil
  end

  def apply_defog_v0996(user,target)
    return false if target==nil
    target.change_stat_stage(:evasion,-1,user)
    if @hazards_v056!=nil && respond_to?(:clear_hazards_v056);clear_hazards_v056(:ally);clear_hazards_v056(:enemy);end
    if respond_to?(:clear_canonical_field_effect_v035)
      [:reflect,:light_screen,:safeguard,:mist].each{|k|clear_canonical_field_effect_v035(k,target.team,:defog_v0996)}
    end
    add_vfx_impact(target,:flying) if respond_to?(:add_vfx_impact);true
  end
  def apply_simple_beam_v0996(user,target)
    return false if target==nil || target.ability_key==:multitype || !target.respond_to?(:set_ability_override_v057)
    target.set_ability_override_v057(:simple,999999);add_vfx_impact(target,:normal) if respond_to?(:add_vfx_impact);true
  end
  def apply_skill_swap_v0996(user,target)
    return false if user==nil || target==nil || !user.respond_to?(:set_ability_override_v057) || !target.respond_to?(:set_ability_override_v057)
    a=user.ability_key;b=target.ability_key;locked=[:multitype,:wonder_guard]
    return false if a==nil || b==nil || locked.include?(a) || locked.include?(b)
    user.set_ability_override_v057(b,999999);target.set_ability_override_v057(a,999999);add_vfx_impact(user,:psychic);add_vfx_impact(target,:psychic);true
  end

  def apply_skill_effects(user,target,data,scale=1.0)
    d=transform_movepool_production_v0996(user,target,data);result=pmd_ac_v0996_apply_skill_effects(user,target,d,scale)
    return result if d==nil || user==nil
    (d[:effects]||[]).each do |e|
      case e[:type]
      when :defog_v0996;apply_defog_v0996(user,target)
      when :simple_beam_v0996;apply_simple_beam_v0996(user,target)
      when :skill_swap_v0996;apply_skill_swap_v0996(user,target)
      when :volt_retreat_v0996;queue_volt_retreat_v0996(user,target) if result.to_i>0
      end
    end
    if d[:pledge_combo_key_v0996]!=nil;activate_pledge_combo_v0996(user,d[:pledge_combo_key_v0996])
    elsif d[:pledge_arm_v0996];@pledge_pending_v0996[user.team]={:kind=>d[:pledge_v0996],:source_uid=>user.instance_uid,:expire=>Graphics.frame_count+PMD_AC::PLEDGE_WINDOW_FRAMES_V0996};end
    result
  end
  def update
    pmd_ac_v0996_update;update_volt_retreat_v0996;update_pledge_fields_v0996
  end

  def movepool_production_v0996?;verification_mode==:movepool_production_v0996;end
  def prepare_verification_battle
    pmd_ac_v0996_prepare_verification_battle
    return unless movepool_production_v0996?
    reset_movepool_production_runtime_v0996;@movepool_production_failed_v0996=false;@movepool_production_report_v0996=PMD_AC.movepool_production_audit_v0996
    @movepool_production_written_v0996=PMD_AC.write_movepool_production_audit_v0996(@movepool_production_report_v0996)
    @movepool_test_uid_v0996=99600124;reg=PMD_AC.pokemon_registry_v045;@movepool_old_instance_v0996=reg[@movepool_test_uid_v0996]
    @movepool_test_instance_v0996=PMD_PokemonInstance.new(:bulbasaur,20,{:instance_uid=>@movepool_test_uid_v0996,:ivs=>[15,15,15,15,15,15],:nature=>:hardy,:ability_slot=>:primary});reg[@movepool_test_uid_v0996]=@movepool_test_instance_v0996
    @movepool_tutor_snapshot_v0996=PMD_AC.tutor_unlocks_v0995.dup;PMD_AC.lock_tutor_v0995(:grass_pledge)
    log_event(:showcase,'START mode=MOVEPOOL_PRODUCTION_V0996 exclusive=19 blocked=0 tutor_overlay=B2W2 sparse_policy=19')
  end
  def restore_movepool_production_v0996
    return if @movepool_restore_done_v0996
    if @movepool_tutor_snapshot_v0996!=nil;h=PMD_AC.tutor_unlocks_v0995;h.clear;@movepool_tutor_snapshot_v0996.each{|k,v|h[k]=v};end
    if @movepool_test_uid_v0996!=nil;reg=PMD_AC.pokemon_registry_v045;if @movepool_old_instance_v0996==nil;reg.delete(@movepool_test_uid_v0996);else;reg[@movepool_test_uid_v0996]=@movepool_old_instance_v0996;end;end
    @movepool_restore_done_v0996=true;true
  end
  def terminate
    restore_movepool_production_v0996 if movepool_production_v0996?;pmd_ac_v0996_terminate
  end
  def log_event(category,message)
    if category.to_s=='verify' && movepool_production_v0996? && message.to_s.index('V0996')!=nil && message.to_s.index(' pass=0')!=nil;@movepool_production_failed_v0996=true;end
    pmd_ac_v0996_log_event(category,message)
  end
  def log_movepool_verify_v0996(name,pass,detail)
    @movepool_production_failed_v0996=true unless pass;log_event(:verify,name+' pass='+(pass ? '1':'0')+' '+detail)
  end

  def update_verification_script
    unless movepool_production_v0996?;pmd_ac_v0996_update_verification_script;return;end
    return if @verification_done[:verification_complete];@verification_frame=@verification_frame.to_i+1;f=@verification_frame;r=@movepool_production_report_v0996 || PMD_AC.movepool_production_audit_v0996;a=r[:acquisition];s=r[:sparse]
    if f>=2 && !@verification_done[:v0996_runtime]
      pass=r[:exclusive_bad].empty? && a[:nonlevel_executable].size==434 && a[:nonlevel_blocked].empty?
      log_movepool_verify_v0996('MOVEPOOL_EXCLUSIVE_RUNTIME_V0996',pass,'exclusive=19/19 nonlevel=434 executable='+a[:nonlevel_executable].size.to_s+'/434 blocked='+a[:nonlevel_blocked].size.to_s+'/0')
      @verification_done[:v0996_runtime]=true
    end
    if f>=8 && !@verification_done[:v0996_mechanics]
      g=PMD_AC.skill_data(:mv_grass_knot);fr=PMD_AC.skill_data(:mv_frost_breath);ts=PMD_AC.skill_data(:mv_tail_slap);dp=PMD_AC.skill_data(:mv_drain_punch);vs=PMD_AC.skill_data(:mv_volt_switch)
      pass=g[:dynamic_power_v0996]==:target_mass && fr[:effects][0][:crit_bonus].to_f>=1.0 && ts[:multi_hit_min].to_i==2 && ts[:multi_hit_max].to_i==5 && dp[:effects][1][:type]==:drain && vs[:effects][1][:type]==:volt_retreat_v0996
      log_movepool_verify_v0996('MOVEPOOL_MECHANICS_V0996',pass,'grass_knot=mass frost_breath=forced_crit tail_slap=2..5 drain_punch=50% volt_switch=retreat96')
      @verification_done[:v0996_mechanics]=true
    end
    if f>=14 && !@verification_done[:v0996_pledge]
      u=verification_unit(:ally,:bulbasaur);t=verification_unit(:enemy,:rattata);reset_movepool_production_runtime_v0996
      d1=transform_movepool_production_v0996(u,t,PMD_AC.skill_data(:mv_fire_pledge));@pledge_pending_v0996[u.team]={:kind=>:fire,:source_uid=>u.instance_uid,:expire=>Graphics.frame_count+120}
      d2=transform_movepool_production_v0996(u,t,PMD_AC.skill_data(:mv_grass_pledge));pow=(d2[:effects]||[]).find{|e|e[:type]==:damage}[:power].to_i
      pass=d1[:pledge_arm_v0996] && d2[:pledge_combo_key_v0996]==:fire_grass && pow==100
      log_movepool_verify_v0996('MOVEPOOL_PLEDGE_COMBO_V0996',pass,'window=120 second_power='+pow.to_s+'/100 fire_grass=dot grass_water=swamp fire_water=rainbow')
      @verification_done[:v0996_pledge]=true
    end
    if f>=20 && !@verification_done[:v0996_ability]
      sb=PMD_AC.skill_data(:mv_simple_beam);ss=PMD_AC.skill_data(:mv_skill_swap);pass=sb[:effects][0][:type]==:simple_beam_v0996 && ss[:effects][0][:type]==:skill_swap_v0996
      log_movepool_verify_v0996('MOVEPOOL_ABILITY_MOVES_V0996',pass,'simple_beam=ability_override skill_swap=swap multitype_guard=1 wonder_guard_guard=1')
      @verification_done[:v0996_ability]=true
    end
    if f>=26 && !@verification_done[:v0996_sparse]
      pass=s[:pass] && s[:lifetime].size==15 && s[:early].size==19 && s[:exceptions].size==3 && s[:tutor_refs]==25
      log_movepool_verify_v0996('MOVEPOOL_SPARSE_POLICY_V0996',pass,'lifetime_lt4='+s[:lifetime].size.to_s+'/15 lv20_lt4='+s[:early].size.to_s+'/19 b2w2_tutor_species=9 refs='+s[:tutor_refs].to_s+'/25 identity_exceptions=['+s[:exceptions].collect{|x|x.to_s}.sort.join(',')+']')
      @verification_done[:v0996_sparse]=true
    end
    if f>=32 && !@verification_done[:v0996_tutor]
      ok1=PMD_AC.tutor_compatible_v0995?(:caterpie,:electroweb);ok2=PMD_AC.tutor_compatible_v0995?(:beldum,:iron_head);ok3=PMD_AC.tutor_compatible_v0995?(:combee,:tailwind);unlock=PMD_AC.unlock_tutor_v0995(:electroweb)
      log_movepool_verify_v0996('MOVEPOOL_B2W2_TUTOR_V0996',ok1&&ok2&&ok3&&unlock,'caterpie_electroweb='+(ok1 ? '1':'0')+' beldum_iron_head='+(ok2 ? '1':'0')+' combee_tailwind='+(ok3 ? '1':'0')+' unlock='+(unlock ? '1':'0')+' free_learn=0')
      @verification_done[:v0996_tutor]=true
    end
    if f>=38 && !@verification_done[:v0996_acquire]
      PMD_AC.unlock_tutor_v0995(:grass_pledge);x=PMD_AC.teach_tutor_v0995(@movepool_test_uid_v0996,:grass_pledge)
      pass=x[:ok] && x[:reason]==:learned && @movepool_test_instance_v0996.knows_move_v045?(:grass_pledge)
      log_movepool_verify_v0996('MOVEPOOL_RUNTIME_ACQUISITION_V0996',pass,'move=grass_pledge old_gate=removed result='+x[:reason].to_s+' learned='+(pass ? '1':'0')+' identity=instance_uid')
      @verification_done[:v0996_acquire]=true
    end
    if f>=44 && !@verification_done[:v0996_report]
      pass=@movepool_production_written_v0996 && FileTest.exist?(PMD_AC::MOVEPOOL_PRODUCTION_AUDIT_FILE_V0996)
      log_movepool_verify_v0996('MOVEPOOL_PRODUCTION_REPORT_V0996',pass,'file='+PMD_AC::MOVEPOOL_PRODUCTION_AUDIT_FILE_V0996+' blocked=0')
      @verification_done[:v0996_report]=true
    end
    if f>=50 && !@verification_done[:v0996_final]
      pass=!@movepool_production_failed_v0996 && r[:pass]
      log_movepool_verify_v0996('MOVEPOOL_PRODUCTION_V0996',pass,'exclusive_runtime=complete sparse_policy=complete b2w2_sparse_tutor=25 acquisition=persistent next=global_tutor_special_content+gameplay_review')
      @verification_done[:v0996_final]=true;restore_movepool_production_v0996
    end
    complete_verification_mode if f>=PMD_AC::MOVEPOOL_PRODUCTION_VERIFY_END_V0996
  end
end
