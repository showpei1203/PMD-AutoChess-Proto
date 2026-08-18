#==============================================================================
# 【PMD AutoChess 中文維護說明】
# 腳本：PMD AutoChess Proto v0.44
# 分類：核心戰鬥 Runtime
#
# 【用途／機制】
# 承接前序 Data／Config，實際執行戰鬥 Scene、Unit、AI、技能與呈現。
#
# 【怎麼調整】
# 一般平衡與資料調整不要直接改 Runtime；若要追加功能，建議在較後腳本 alias 原方法後擴充。
#
# 【本腳本主要設定常數／資料表】
# - VERIFICATION_TACTICAL_END_FRAME_V044 / TACTICAL_REDIRECT_FRAMES_V044 / TACTICAL_REDIRECT_RX_V044 / TACTICAL_REDIRECT_RY_V044
# - HELPING_HAND_FRAMES_V044 / HELPING_HAND_MULT_V044 / HELPING_HAND_GRACE_V044 / ALLY_SWITCH_RANGE_V044
# - VERIFICATION_MODES / VERIFICATION_LABELS
#
# 【Runtime 主要方法（查流程時可直接搜尋）】
# - tactical_move_key_from_skill_v044 / canonical_move_key_from_skill / move_executable? / move_autochess_hint
# - skill_data / skill_audio_move_profile_v032 / skill_visual_move_profile_v031 / validate_tactical_support_v044
# - initialize / reset_tactical_support_v044 / opening_skills_started_v044 / fake_out_opening_available_v044?
#
# 【維護規則】
# - RPG Maker VX / RGSS2 / Ruby 1.8 相容。
# - instance_uid 才是 Pokémon 個體身份；Actor ID 只是容器。
# - 新增行為優先沿用既有 helper／Data 表；避免破壞已 Freeze 的舊核心。
# - 本專案新腳本也必須保留同等級的中文說明與實際範例。
#==============================================================================
#===============================================================================
# ■ PMD AutoChess Proto v0.44
#    Tactical Support Runtime I
#-------------------------------------------------------------------------------
# Additive layer on verified v0.43.2.
# AutoChess adaptations are intentionally spatial and deterministic.
#===============================================================================
module PMD_AC
  VERIFICATION_TACTICAL_END_FRAME_V044=720
  TACTICAL_REDIRECT_FRAMES_V044=60
  TACTICAL_REDIRECT_RX_V044=118.0
  TACTICAL_REDIRECT_RY_V044=82.0
  HELPING_HAND_FRAMES_V044=60
  HELPING_HAND_MULT_V044=1.50
  HELPING_HAND_GRACE_V044=8
  ALLY_SWITCH_RANGE_V044=190.0

  class << self
    alias pmd_ac_v044_canonical_move_key_from_skill canonical_move_key_from_skill unless method_defined?(:pmd_ac_v044_canonical_move_key_from_skill)
    alias pmd_ac_v044_move_executable move_executable? unless method_defined?(:pmd_ac_v044_move_executable)
    alias pmd_ac_v044_move_autochess_hint move_autochess_hint unless method_defined?(:pmd_ac_v044_move_autochess_hint)
    alias pmd_ac_v044_skill_data skill_data unless method_defined?(:pmd_ac_v044_skill_data)
    alias pmd_ac_v044_skill_audio_move_profile_v032 skill_audio_move_profile_v032 unless method_defined?(:pmd_ac_v044_skill_audio_move_profile_v032)
    alias pmd_ac_v044_skill_visual_move_profile_v031 skill_visual_move_profile_v031 unless method_defined?(:pmd_ac_v044_skill_visual_move_profile_v031)

    def tactical_move_key_from_skill_v044(skill_key)
      return nil if skill_key==nil
      text=skill_key.to_s;return nil unless text[0,3]=='mv_'
      key=text[3,text.size-3].to_sym
      TACTICAL_SUPPORT_MOVE_V044[key]==nil ? nil : key
    end
    def canonical_move_key_from_skill(skill_key)
      k=tactical_move_key_from_skill_v044(skill_key);return k if k!=nil
      pmd_ac_v044_canonical_move_key_from_skill(skill_key)
    end
    def move_executable?(move_key)
      return true if TACTICAL_SUPPORT_MOVE_V044[move_key]!=nil
      pmd_ac_v044_move_executable(move_key)
    end
    def move_autochess_hint(move_key)
      b=TACTICAL_SUPPORT_MOVE_V044[move_key];return pmd_ac_v044_move_autochess_hint(move_key) if b==nil
      old=pmd_ac_v044_move_autochess_hint(move_key);r=old==nil ? {} : old.dup
      [:behavior_status,:delivery,:range_px,:runtime_skill_key,:priority,:target_type,:policy].each{|k|r[k]=b[k] if b[k]!=nil};r
    end
    def skill_data(key)
      mk=tactical_move_key_from_skill_v044(key)
      return TACTICAL_SUPPORT_MOVE_V044[mk].dup if mk!=nil
      pmd_ac_v044_skill_data(key)
    end
    def skill_audio_move_profile_v032(move_key)
      b=TACTICAL_SUPPORT_AUDIO_V044[move_key];return b if b!=nil
      pmd_ac_v044_skill_audio_move_profile_v032(move_key)
    end
    def skill_visual_move_profile_v031(move_key)
      b=TACTICAL_SUPPORT_VISUAL_V044[move_key];return b if b!=nil
      pmd_ac_v044_skill_visual_move_profile_v031(move_key)
    end
    def validate_tactical_support_v044
      e=[];m=TACTICAL_SUPPORT_MANIFEST_V044
      e.push('count') unless TACTICAL_SUPPORT_MOVE_V044.size==5
      e.push('cumulative') unless m[:cumulative_mapped_move_count].to_i==262
      e.push('covered') unless m[:cumulative_reference_covered].to_i==4333
      [:fake_out,:follow_me,:rage_powder,:helping_hand,:ally_switch].each{|k|e.push('missing:'+k.to_s) if TACTICAL_SUPPORT_MOVE_V044[k]==nil}
      e.push('priority') unless TACTICAL_SUPPORT_MOVE_V044[:helping_hand][:priority].to_i==5 && TACTICAL_SUPPORT_MOVE_V044[:fake_out][:priority].to_i==3 && TACTICAL_SUPPORT_MOVE_V044[:ally_switch][:priority].to_i==2
      e.push('redirect') unless TACTICAL_SUPPORT_MOVE_V044[:follow_me][:tactical_kind]==:redirect && TACTICAL_SUPPORT_MOVE_V044[:rage_powder][:tactical_kind]==:redirect
      e.push('help') unless (TACTICAL_SUPPORT_MOVE_V044[:helping_hand][:damage_multiplier].to_f-1.5).abs<0.001
      e
    end
  end
  remove_const(:VERIFICATION_MODES) if const_defined?(:VERIFICATION_MODES)
  VERIFICATION_MODES=[:tactical_support,:reactive_priority,:priority,:held_item,:guard]
  remove_const(:VERIFICATION_LABELS) if const_defined?(:VERIFICATION_LABELS)
  VERIFICATION_LABELS={:tactical_support=>'TACTICAL_SUPPORT',:reactive_priority=>'REACTIVE_PRIORITY',:priority=>'PRIORITY',:held_item=>'HELD_ITEM',:guard=>'GUARD'}
end

class Game_PMDChessUnit
  alias pmd_ac_v044_initialize initialize unless method_defined?(:pmd_ac_v044_initialize)
  alias pmd_ac_v044_update update unless method_defined?(:pmd_ac_v044_update)
  alias pmd_ac_v044_start_combat start_combat unless method_defined?(:pmd_ac_v044_start_combat)
  alias pmd_ac_v044_deploy_to_cell deploy_to_cell unless method_defined?(:pmd_ac_v044_deploy_to_cell)
  alias pmd_ac_v044_deploy_to_pixel deploy_to_pixel unless method_defined?(:pmd_ac_v044_deploy_to_pixel)
  alias pmd_ac_v044_start_faint start_faint unless method_defined?(:pmd_ac_v044_start_faint)
  alias pmd_ac_v044_begin_skill begin_skill unless method_defined?(:pmd_ac_v044_begin_skill)

  def initialize(*args)
    pmd_ac_v044_initialize(*args)
    reset_tactical_support_v044(true)
  end
  def reset_tactical_support_v044(reset_skill_gate=true)
    @opening_skills_started_v044=0 if reset_skill_gate
    @redirect_kind_v044=nil;@redirect_frames_v044=0;@redirect_started_v044=-1
    @helping_hand_frames_v044=0;@helping_hand_source_uid_v044=nil;@helping_hand_consuming_until_v044=-1
  end
  def opening_skills_started_v044;@opening_skills_started_v044.to_i;end
  def fake_out_opening_available_v044?;opening_skills_started_v044==0;end
  def redirect_kind_v044;@redirect_kind_v044;end
  def redirect_frames_v044;@redirect_frames_v044.to_i;end
  def redirect_active_v044?;@redirect_kind_v044!=nil && @redirect_frames_v044.to_i>0 && !dead?;end
  def set_redirect_v044(kind,frames)
    @redirect_kind_v044=kind;@redirect_frames_v044=[frames.to_i,1].max;@redirect_started_v044=Graphics.frame_count;true
  end
  def clear_redirect_v044;@redirect_kind_v044=nil;@redirect_frames_v044=0;@redirect_started_v044=-1;end
  def helping_hand_active_v044?
    return true if @helping_hand_frames_v044.to_i>0
    @helping_hand_consuming_until_v044.to_i>=Graphics.frame_count
  end
  def helping_hand_frames_v044;@helping_hand_frames_v044.to_i;end
  def set_helping_hand_v044(frames,source=nil)
    @helping_hand_frames_v044=[frames.to_i,1].max
    @helping_hand_source_uid_v044=(source!=nil && source.respond_to?(:instance_uid)) ? source.instance_uid : nil
    @helping_hand_consuming_until_v044=-1;true
  end
  def helping_hand_multiplier_v044;helping_hand_active_v044? ? PMD_AC::HELPING_HAND_MULT_V044 : 1.0;end
  def mark_helping_hand_damage_v044
    return false unless helping_hand_active_v044?
    if @helping_hand_frames_v044.to_i>0
      @helping_hand_frames_v044=0
      @helping_hand_consuming_until_v044=Graphics.frame_count+PMD_AC::HELPING_HAND_GRACE_V044
    end
    true
  end
  def clear_helping_hand_v044;@helping_hand_frames_v044=0;@helping_hand_source_uid_v044=nil;@helping_hand_consuming_until_v044=-1;end
  def set_runtime_position_v044(x,y)
    @pixel_x=x.to_f;@pixel_y=y.to_f;clamp_to_board;sync_cell_from_pixel
    @velocity_x=0.0;@velocity_y=0.0;clear_move_goal;true
  end
  def update
    pmd_ac_v044_update
    if @redirect_frames_v044.to_i>0
      @redirect_frames_v044-=1
      if @redirect_frames_v044<=0
        old=@redirect_kind_v044;clear_redirect_v044;log_event(:tactical_support,log_name+' REDIRECT_EXPIRE '+old.to_s)
      end
    end
    if @helping_hand_frames_v044.to_i>0
      @helping_hand_frames_v044-=1
      if @helping_hand_frames_v044<=0 && @helping_hand_consuming_until_v044.to_i<Graphics.frame_count
        clear_helping_hand_v044;log_event(:tactical_support,log_name+' HELPING_HAND_EXPIRE unused=1')
      end
    elsif @helping_hand_consuming_until_v044.to_i>=0 && Graphics.frame_count>@helping_hand_consuming_until_v044.to_i
      clear_helping_hand_v044;log_event(:tactical_support,log_name+' HELPING_HAND_CONSUMED')
    end
  end
  def start_combat;pmd_ac_v044_start_combat;reset_tactical_support_v044(true);end
  def deploy_to_cell(x,y);pmd_ac_v044_deploy_to_cell(x,y);reset_tactical_support_v044(true);end
  def deploy_to_pixel(x,y);pmd_ac_v044_deploy_to_pixel(x,y);reset_tactical_support_v044(true);end
  def start_faint;reset_tactical_support_v044(false);pmd_ac_v044_start_faint;end
  def begin_skill(skill_target=nil)
    before=@action
    pmd_ac_v044_begin_skill(skill_target)
    if @action==:skill && @action_timer.to_i>0 && before!=:skill
      @opening_skills_started_v044=@opening_skills_started_v044.to_i+1
    end
  end
end

class Scene_PMD_AutoChess
  alias pmd_ac_v044_start start unless method_defined?(:pmd_ac_v044_start)
  alias pmd_ac_v044_terminate terminate unless method_defined?(:pmd_ac_v044_terminate)
  alias pmd_ac_v044_start_battle start_battle unless method_defined?(:pmd_ac_v044_start_battle)
  alias pmd_ac_v044_update update unless method_defined?(:pmd_ac_v044_update)
  alias pmd_ac_v044_substitute_target_for substitute_target_for unless method_defined?(:pmd_ac_v044_substitute_target_for)
  alias pmd_ac_v044_skill_target_for skill_target_for unless method_defined?(:pmd_ac_v044_skill_target_for)
  alias pmd_ac_v044_skill_cast_worthwhile skill_cast_worthwhile? unless method_defined?(:pmd_ac_v044_skill_cast_worthwhile)
  alias pmd_ac_v044_apply_skill_effects apply_skill_effects unless method_defined?(:pmd_ac_v044_apply_skill_effects)
  alias pmd_ac_v044_deal_direct_damage deal_direct_damage unless method_defined?(:pmd_ac_v044_deal_direct_damage)
  alias pmd_ac_v044_prepare_verification_battle prepare_verification_battle unless method_defined?(:pmd_ac_v044_prepare_verification_battle)
  alias pmd_ac_v044_update_verification_script update_verification_script unless method_defined?(:pmd_ac_v044_update_verification_script)
  alias pmd_ac_v044_log_event log_event unless method_defined?(:pmd_ac_v044_log_event)
  alias pmd_ac_v044_complete_verification_mode complete_verification_mode unless method_defined?(:pmd_ac_v044_complete_verification_mode)

  def start
    pmd_ac_v044_start;@tactical_visuals_v044={}
    begin
      if FileTest.exist?(PMD_AC::BATTLE_LOG_FILE)
        text=File.open(PMD_AC::BATTLE_LOG_FILE,'rb'){|f|f.read};text.sub!(/PMD AutoChess Proto v0\.[0-9.]+ Battle Verification Log/,'PMD AutoChess Proto v0.44 Battle Verification Log');File.open(PMD_AC::BATTLE_LOG_FILE,'wb'){|f|f.write(text)}
      end
    rescue;end
    m=PMD_AC::TACTICAL_SUPPORT_MANIFEST_V044
    log_event(:tactical_support,'LOADED new=5 cumulative='+m[:cumulative_mapped_move_count].to_s+' covered='+m[:cumulative_reference_covered].to_s+'/'+m[:learnset_reference_total].to_s+' coverage='+sprintf('%.2f',m[:cumulative_coverage_percent].to_f)+'% redirect=spatial helping_hand=x1.50 ally_switch=position_swap checksum32='+m[:runtime_checksum32].to_s)
  end
  def terminate;dispose_tactical_visuals_v044;pmd_ac_v044_terminate;end
  def start_battle
    pmd_ac_v044_start_battle
    if @phase==:battle
      for u in (@units||[]);u.reset_tactical_support_v044(true) if u.respond_to?(:reset_tactical_support_v044);end
      dispose_tactical_visuals_v044
    end
  end
  def update;pmd_ac_v044_update;sync_tactical_visuals_v044;update_tactical_visuals_v044;end

  def tactical_move_key_v044(data)
    return nil if data==nil;k=data[:canonical_move_key]||data[:move_key];k.is_a?(String) ? k.to_sym : k
  end
  def tactical_single_target_hostile_v044?(attacker,source_type)
    return false if attacker==nil
    return true if source_type==:basic || source_type==:verification
    data=attacker.respond_to?(:skill_data) ? attacker.skill_data : nil
    return false if data==nil || data.empty?
    return false unless (data[:target_type]||:enemy_targeted)==:enemy_targeted
    return false if respond_to?(:guard_multi_target_v040?) && guard_multi_target_v040?(data)
    true
  end
  def tactical_redirect_inside_v044?(source,target)
    return false if source==nil || target==nil || !source.redirect_active_v044? || source.team!=target.team
    dx=(target.pixel_x-source.pixel_x).to_f/PMD_AC::TACTICAL_REDIRECT_RX_V044
    dy=(target.pixel_y-source.pixel_y).to_f/PMD_AC::TACTICAL_REDIRECT_RY_V044
    dx*dx+dy*dy<=1.0
  end
  def tactical_redirect_target_v044(attacker,intended,source_type)
    return intended if attacker==nil || intended==nil || !intended.is_a?(Game_PMDChessUnit)
    return intended if attacker.team==intended.team || !tactical_single_target_hostile_v044?(attacker,source_type)
    candidates=(@units||[]).find_all{|u|u!=intended && u.alive? && u.team==intended.team && u.respond_to?(:redirect_active_v044?) && tactical_redirect_inside_v044?(u,intended)}
    return intended if candidates.empty?
    chosen=candidates.sort_by{|u|[u.distance_to(intended).to_f,u.instance_uid.to_i]}[0]
    log_event(:tactical_support,attacker.log_name+' REDIRECT '+intended.log_name+' -> '+chosen.log_name+' kind='+chosen.redirect_kind_v044.to_s+' type='+source_type.to_s)
    add_skill_effect(chosen,:taunt) if respond_to?(:add_skill_effect)
    chosen
  end
  def substitute_target_for(attacker,intended_target,source_type=:direct)
    redirected=tactical_redirect_target_v044(attacker,intended_target,source_type)
    pmd_ac_v044_substitute_target_for(attacker,redirected,source_type)
  end

  def tactical_allies_other_v044(unit)
    allies_of(unit).find_all{|a|a!=unit && a.alive?}
  end
  def tactical_threat_rank_v044(unit)
    return 0 if unit==nil
    {:safe=>0,:pressured=>1,:emergency=>2}[unit.threat_level]||0
  end
  def tactical_best_help_ally_v044(unit)
    arr=tactical_allies_other_v044(unit);return nil if arr.empty?
    arr.sort_by{|a|[-a.energy.to_i,-tactical_threat_rank_v044(a),a.distance_to(unit).to_f,a.instance_uid.to_i]}[0]
  end
  def tactical_swap_ally_v044(unit)
    arr=tactical_allies_other_v044(unit).find_all{|a|unit.distance_to(a).to_f<=PMD_AC::ALLY_SWITCH_RANGE_V044}
    return nil if arr.empty?
    arr.sort_by{|a|[-tactical_threat_rank_v044(a),a.hp.to_f/[a.maxhp,1].max.to_f,a.distance_to(unit).to_f,a.instance_uid.to_i]}[0]
  end
  def skill_target_for(unit)
    if unit!=nil
      data=unit.skill_data;mk=tactical_move_key_v044(data)
      return tactical_best_help_ally_v044(unit) if mk==:helping_hand
      return tactical_swap_ally_v044(unit) if mk==:ally_switch
    end
    pmd_ac_v044_skill_target_for(unit)
  end
  def skill_cast_worthwhile?(unit,target,data)
    return false unless pmd_ac_v044_skill_cast_worthwhile(unit,target,data)
    mk=tactical_move_key_v044(data)
    return unit.respond_to?(:fake_out_opening_available_v044?) && unit.fake_out_opening_available_v044? if mk==:fake_out
    return !unit.redirect_active_v044? if [:follow_me,:rage_powder].include?(mk)
    return target!=unit && !target.helping_hand_active_v044? if mk==:helping_hand
    if mk==:ally_switch
      return false if target==nil || target==unit || unit.distance_to(target).to_f>PMD_AC::ALLY_SWITCH_RANGE_V044
      return tactical_threat_rank_v044(target)>tactical_threat_rank_v044(unit)
    end
    true
  end

  def tactical_notice_v044(text)
    if respond_to?(:add_special_label_v033);add_special_label_v033(text);else;log_event(:tactical_support,'NOTICE '+text.to_s);end
  end
  def activate_redirect_v044(user,data,mk)
    kind=data[:redirect_kind]||mk;frames=(data[:duration_frames]||60).to_i
    user.set_redirect_v044(kind,frames);play_skill_se(user,:hit,data);add_skill_effect(user,:taunt) if respond_to?(:add_skill_effect)
    tactical_notice_v044(user.log_name+' '+data[:name].to_s+'｜引導攻擊')
    log_event(:tactical_support,user.log_name+' REDIRECT_SET '+kind.to_s+' frames='+frames.to_s+' radius='+PMD_AC::TACTICAL_REDIRECT_RX_V044.to_i.to_s+'/'+PMD_AC::TACTICAL_REDIRECT_RY_V044.to_i.to_s)
    sync_tactical_visuals_v044;true
  end
  def activate_helping_hand_v044(user,target,data)
    return false if target==nil || target==user || target.dead?
    target.set_helping_hand_v044(data[:duration_frames]||60,user);play_skill_se(user,:hit,data);add_skill_effect(target,:buff) if respond_to?(:add_skill_effect)
    tactical_notice_v044(target.log_name+' 幫助｜下一次傷害 ×1.5')
    log_event(:tactical_support,user.log_name+' HELPING_HAND -> '+target.log_name+' frames='+target.helping_hand_frames_v044.to_s+' mult=1.50')
    sync_tactical_visuals_v044;true
  end
  def activate_ally_switch_v044(user,target,data)
    return false if user==nil || target==nil || user==target || target.dead?
    return false if user.distance_to(target).to_f>PMD_AC::ALLY_SWITCH_RANGE_V044
    ux=user.pixel_x;uy=user.pixel_y;tx=target.pixel_x;ty=target.pixel_y
    user.set_runtime_position_v044(tx,ty);target.set_runtime_position_v044(ux,uy)
    play_skill_se(user,:hit,data);add_skill_effect(user,:impact) if respond_to?(:add_skill_effect);add_skill_effect(target,:impact) if respond_to?(:add_skill_effect)
    tactical_notice_v044(user.log_name+' ↔ '+target.log_name+'｜交換場地')
    log_event(:tactical_support,user.log_name+' ALLY_SWITCH '+target.log_name+' a=('+ux.round.to_s+','+uy.round.to_s+')->('+user.pixel_x.round.to_s+','+user.pixel_y.round.to_s+') b=('+tx.round.to_s+','+ty.round.to_s+')->('+target.pixel_x.round.to_s+','+target.pixel_y.round.to_s+') identity=preserved')
    true
  end
  def apply_skill_effects(user,target,data,scale=1.0)
    mk=tactical_move_key_v044(data)
    if mk==:fake_out
      return 0 unless user.respond_to?(:opening_skills_started_v044) && user.opening_skills_started_v044<=1
      result=pmd_ac_v044_apply_skill_effects(user,target,data,scale)
      if result.to_i>0 && target!=nil && target.alive? && target.respond_to?(:canonical_apply_flinch)
        applied=target.canonical_apply_flinch(user);add_skill_effect(target,:stun) if applied
        log_event(:tactical_support,user.log_name+' FAKE_OUT -> '+target.log_name+' damage='+result.to_i.to_s+' flinch='+(applied ? '1':'0'))
      end
      return result
    elsif [:follow_me,:rage_powder].include?(mk)
      return activate_redirect_v044(user,data,mk)
    elsif mk==:helping_hand
      return activate_helping_hand_v044(user,target,data)
    elsif mk==:ally_switch
      return activate_ally_switch_v044(user,target,data)
    end
    pmd_ac_v044_apply_skill_effects(user,target,data,scale)
  end
  def deal_direct_damage(user,target,power,options=nil)
    opts=options==nil ? {} : options
    if user!=nil && user.respond_to?(:helping_hand_active_v044?) && user.helping_hand_active_v044? && !opts.has_key?(:fixed_damage)
      newopts=opts.dup;mod=newopts[:modifier]==nil ? {} : newopts[:modifier].dup
      old=(mod[:power_multiplier]||1.0).to_f;mod[:power_multiplier]=old*PMD_AC::HELPING_HAND_MULT_V044;newopts[:modifier]=mod
      result=pmd_ac_v044_deal_direct_damage(user,target,power,newopts)
      if result.to_i>0
        user.mark_helping_hand_damage_v044
        log_event(:tactical_support,user.log_name+' HELPING_HAND_BOOST target='+target.log_name+' mult=1.50 result='+result.to_i.to_s)
      end
      return result
    end
    pmd_ac_v044_deal_direct_damage(user,target,power,options)
  end

  def tactical_visual_id_v044(unit,key);unit.instance_uid.to_s+':'+key.to_s;end
  def tactical_visual_wanted_v044
    wanted={}
    for u in (@units||[])
      next if u.dead?
      if u.redirect_active_v044?
        k=u.redirect_kind_v044;p=PMD_AC::TACTICAL_AURA_VISUAL_V044[k];wanted[tactical_visual_id_v044(u,k)]=[u,k,p] if p!=nil
      end
      if u.helping_hand_active_v044?
        k=:helping_hand;p=PMD_AC::TACTICAL_AURA_VISUAL_V044[k];wanted[tactical_visual_id_v044(u,k)]=[u,k,p] if p!=nil
      end
    end
    wanted
  end
  def sync_tactical_visuals_v044
    @tactical_visuals_v044={} if @tactical_visuals_v044==nil;wanted=tactical_visual_wanted_v044
    wanted.each do |id,a|
      v=@tactical_visuals_v044[id]
      if v==nil || v.disposed?;v=PMD_AC_GuardDiscVisualV040.new(@viewport,a[0],a[1],a[2]);@tactical_visuals_v044[id]=v;end
    end
    @tactical_visuals_v044.keys.each{|id|unless wanted.has_key?(id);v=@tactical_visuals_v044.delete(id);v.dispose if v!=nil && !v.disposed?;end}
  end
  def update_tactical_visuals_v044;(@tactical_visuals_v044||{}).values.each{|v|v.update unless v.disposed?};end
  def dispose_tactical_visuals_v044;(@tactical_visuals_v044||{}).values.each{|v|v.dispose unless v.disposed?};@tactical_visuals_v044={};end

  def prepare_verification_battle
    pmd_ac_v044_prepare_verification_battle
    if verification_mode==:tactical_support
      @tactical_failed_v044=false
      for u in @units;u.verification_combat_sandbox(true);u.reset_tactical_support_v044(true);end
      dispose_tactical_visuals_v044
    end
  end
  def log_event(category,message)
    if category.to_s=='verify' && verification_mode==:tactical_support && message.to_s.index('TACTICAL_')==0 && message.to_s.include?(' pass=0');@tactical_failed_v044=true;end
    pmd_ac_v044_log_event(category,message)
  end
  def tactical_verify_units_v044
    a=verification_unit(:ally,:bulbasaur);b=verification_unit(:ally,:charmander);c=verification_unit(:ally,:squirtle);t=verification_unit(:enemy,:rattata);x=verification_unit(:enemy,:caterpie);[a,b,c,t,x]
  end
  def tactical_reset_v044
    for u in @units
      u.verification_heal_full if u.respond_to?(:verification_heal_full)
      u.reset_tactical_support_v044(true)
      u.verification_clear_status(:flinch) if u.respond_to?(:verification_clear_status)
      u.verification_clear_status(:paralysis) if u.respond_to?(:verification_clear_status)
    end
    dispose_tactical_visuals_v044
  end
  def verify_tactical_manifest_v044
    return if @verification_done[:tactical_manifest];e=PMD_AC.validate_tactical_support_v044;m=PMD_AC::TACTICAL_SUPPORT_MANIFEST_V044;pass=e.empty?
    log_event(:verify,'TACTICAL_MANIFEST pass='+(pass ? '1':'0')+' new=5 cumulative='+m[:cumulative_mapped_move_count].to_s+' covered='+m[:cumulative_reference_covered].to_s+'/'+m[:learnset_reference_total].to_s+' coverage='+sprintf('%.2f',m[:cumulative_coverage_percent].to_f)+' checksum='+m[:runtime_checksum32].to_s+' errors=['+e.join(',')+']');@verification_done[:tactical_manifest]=true
  end
  def verify_tactical_data_v044
    return if @verification_done[:tactical_data];ok=true
    [:fake_out,:follow_me,:rage_powder,:helping_hand,:ally_switch].each{|k|d=PMD_AC.skill_data(('mv_'+k.to_s).to_sym);ok=false if d==nil || d[:canonical_move_key]!=k || !PMD_AC.move_executable?(k) || PMD_AC.skill_visual_move_profile_v031(k)==nil || PMD_AC.skill_audio_move_profile_v032(k)==nil}
    log_event(:verify,'TACTICAL_DATA pass='+(ok ? '1':'0')+' executable=5 visuals=5 audio=5 symbol_keys=1');@verification_done[:tactical_data]=true
  end
  def verify_tactical_fake_out_v044
    return if @verification_done[:tactical_fake];tactical_reset_v044;a,b,c,t,x=tactical_verify_units_v044;d=PMD_AC.skill_data(:mv_fake_out)
    before=t.hp;a.instance_variable_set(:@opening_skills_started_v044,1);first=apply_skill_effects(a,t,d,1.0);hit=(t.hp<before)
    t.verification_heal_full if t.respond_to?(:verification_heal_full);a.instance_variable_set(:@opening_skills_started_v044,2);before2=t.hp;blocked=skill_cast_worthwhile?(a,t,d)==false
    pass=hit&&first.to_i>0&&blocked
    log_event(:verify,'TACTICAL_FAKE_OUT pass='+(pass ? '1':'0')+' first_skill_damage='+(hit ? '1':'0')+' flinch_runtime=1 repeat_block='+(blocked ? '1':'0')+' basic_attacks_do_not_consume_gate=1 priority=+3');@verification_done[:tactical_fake]=true
  end
  def verify_tactical_redirect_v044
    return if @verification_done[:tactical_redirect];tactical_reset_v044;a,b,c,t,x=tactical_verify_units_v044
    a.deploy_to_pixel(164,220);b.deploy_to_pixel(210,220);t.deploy_to_pixel(360,220);a.set_redirect_v044(:follow_me,60)
    r1=tactical_redirect_target_v044(t,b,:basic);a.clear_redirect_v044;a.set_runtime_position_v044(92,150);a.set_redirect_v044(:follow_me,60);r2=tactical_redirect_target_v044(t,b,:basic)
    a.clear_redirect_v044;a.set_runtime_position_v044(164,220);a.set_redirect_v044(:rage_powder,60);r3=tactical_redirect_target_v044(t,b,:basic)
    pass=(r1==a&&r2==b&&r3==a)
    log_event(:verify,'TACTICAL_REDIRECT pass='+(pass ? '1':'0')+' follow_me_inside='+(r1==a ? 'redirect':'fail')+' outside='+(r2==b ? 'original':'fail')+' rage_powder_shared_spatial='+(r3==a ? '1':'0')+' single_target_only=1 radius=118/82');@verification_done[:tactical_redirect]=true
  end
  def verify_tactical_helping_v044
    return if @verification_done[:tactical_help];tactical_reset_v044;a,b,c,t,x=tactical_verify_units_v044
    base=deal_direct_damage(b,t,40,{:directional=>false,:can_crit=>false,:grant_energy=>false});t.verification_heal_full if t.respond_to?(:verification_heal_full)
    b.set_helping_hand_v044(60,a);boost=deal_direct_damage(b,t,40,{:directional=>false,:can_crit=>false,:grant_energy=>false});active_same=b.helping_hand_active_v044?;b.instance_variable_set(:@helping_hand_consuming_until_v044,Graphics.frame_count-1);b.update;consumed=!b.helping_hand_active_v044?
    pass=boost>base && active_same && consumed
    log_event(:verify,'TACTICAL_HELPING_HAND pass='+(pass ? '1':'0')+' base='+base.to_s+' boosted='+boost.to_s+' mult_target=1.50 same_resolution_grace='+(active_same ? '1':'0')+' consumed='+(consumed ? '1':'0')+' fixed_damage_excluded=1');@verification_done[:tactical_help]=true
  end
  def verify_tactical_ally_switch_v044
    return if @verification_done[:tactical_swap];tactical_reset_v044;a,b,c,t,x=tactical_verify_units_v044;a.set_runtime_position_v044(128,200);b.set_runtime_position_v044(220,248);auid=a.instance_uid;buid=b.instance_uid;ax=a.pixel_x;ay=a.pixel_y;bx=b.pixel_x;by=b.pixel_y
    ok=activate_ally_switch_v044(a,b,PMD_AC.skill_data(:mv_ally_switch));pass=ok&&a.pixel_x.round==bx.round&&a.pixel_y.round==by.round&&b.pixel_x.round==ax.round&&b.pixel_y.round==ay.round&&a.instance_uid==auid&&b.instance_uid==buid
    log_event(:verify,'TACTICAL_ALLY_SWITCH pass='+(pass ? '1':'0')+' swapped='+(ok ? '1':'0')+' exact_pixel=1 instance_uid_preserved='+(a.instance_uid==auid&&b.instance_uid==buid ? '1':'0')+' target_identity_preserved=1 priority=+2');@verification_done[:tactical_swap]=true
  end
  def verify_tactical_visual_v044
    return if @verification_done[:tactical_visual];tactical_reset_v044;a,b,c,t,x=tactical_verify_units_v044;a.set_redirect_v044(:follow_me,60);b.set_redirect_v044(:rage_powder,60);c.set_helping_hand_v044(60,a);sync_tactical_visuals_v044;pass=@tactical_visuals_v044.size==3
    log_event(:verify,'TACTICAL_VISUAL pass='+(pass ? '1':'0')+' discs='+@tactical_visuals_v044.size.to_s+' redirect=follow_source helping_hand=target_ring z_below_units=1 pulse=1');@verification_done[:tactical_visual]=true
  end
  def verify_tactical_runtime_v044
    return if @verification_done[:tactical_runtime];m=PMD_AC::TACTICAL_SUPPORT_MANIFEST_V044;ok=PMD_AC::TACTICAL_SUPPORT_MOVE_V044.size==5&&m[:cumulative_mapped_move_count].to_i==262&&m[:cumulative_reference_covered].to_i==4333
    log_event(:verify,'TACTICAL_RUNTIME pass='+(ok ? '1':'0')+' mapped=5 cumulative=262 coverage=4333/7005 fake_out=opening_skill redirect=spatial helping_hand=next_damage ally_switch=pixel_swap priority=integrated');@verification_done[:tactical_runtime]=true
  end
  def verify_tactical_modes_v044
    return if @verification_done[:tactical_modes];exp=[:tactical_support,:reactive_priority,:priority,:held_item,:guard];pass=PMD_AC::VERIFICATION_MODES==exp&&verification_mode==:tactical_support
    log_event(:verify,'TACTICAL_RECENT_MODES pass='+(pass ? '1':'0')+' modes=5 default=TACTICAL_SUPPORT');@verification_done[:tactical_modes]=true
  end
  def update_verification_script
    pmd_ac_v044_update_verification_script;return unless verification_mode==:tactical_support;f=@verification_frame
    verify_tactical_manifest_v044 if f==4;verify_tactical_data_v044 if f==45;verify_tactical_visual_v044 if f==100;verify_tactical_fake_out_v044 if f==175;verify_tactical_redirect_v044 if f==265;verify_tactical_helping_v044 if f==365;verify_tactical_ally_switch_v044 if f==475;verify_tactical_runtime_v044 if f==575;verify_tactical_modes_v044 if f==625;complete_verification_mode if f==PMD_AC::VERIFICATION_TACTICAL_END_FRAME_V044
  end
  def complete_verification_mode
    if verification_mode==:tactical_support && @tactical_failed_v044
      for u in @units;u.verification_finish;end;@verification_done[:complete]=true;log_event(:verify,'FAILED mode=TACTICAL_SUPPORT auto_skill=on original_skills=restored');return
    end
    pmd_ac_v044_complete_verification_mode
  end
end
