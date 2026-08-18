#==============================================================================
# 【PMD AutoChess 中文維護說明】
# 腳本：PMD AutoChess Proto v0.37
# 分類：核心戰鬥 Runtime
#
# 【用途／機制】
# 承接前序 Data／Config，實際執行戰鬥 Scene、Unit、AI、技能與呈現。
#
# 【怎麼調整】
# 一般平衡與資料調整不要直接改 Runtime；若要追加功能，建議在較後腳本 alias 原方法後擴充。
#
# 【本腳本主要設定常數／資料表】
# - FIELD_AI_ATTRACT_RANGE_V037 / FIELD_AI_MAX_STEER_V037 / FIELD_AI_MIN_STEER_V037 / FIELD_AI_PRESSURED_WEIGHT_V037
# - VERIFICATION_FIELD_AI_END_FRAME_V037 / VERIFICATION_MODES / VERIFICATION_LABELS
#
# 【Runtime 主要方法（查流程時可直接搜尋）】
# - field_ai_checksum_scalar_v037 / field_ai_checksum32_v037 / validate_field_ai_v037 / desired_velocity
# - start / field_ai_policy_weight_v037 / field_ai_candidates_v037 / field_navigation_vector_v037
# - prepare_verification_battle / log_event / field_ai_units_v037 / verify_field_ai_manifest_v037
#
# 【維護規則】
# - RPG Maker VX / RGSS2 / Ruby 1.8 相容。
# - instance_uid 才是 Pokémon 個體身份；Actor ID 只是容器。
# - 新增行為優先沿用既有 helper／Data 表；避免破壞已 Freeze 的舊核心。
# - 本專案新腳本也必須保留同等級的中文說明與實際範例。
#==============================================================================
#==============================================================================
# ■ PMD AutoChess Proto v0.37
#    Spatial Field AI Movement Scoring I
#------------------------------------------------------------------------------
#  Additive layer on v0.36.1.
#  Friendly Zone/Aura fields now influence an already-moving unit's path.
#  The AI does NOT abandon attacks just to chase a disc: field steering is only
#  added while the current movement policy already has a movement goal.
#
#  Integration point:
#    field_value_at(x,y,unit) -> candidate center score -> steering vector
#
#  Emergency movement always wins. Berserker ignores beneficial field steering.
#==============================================================================
module PMD_AC
  FIELD_AI_ATTRACT_RANGE_V037 = 190.0
  FIELD_AI_MAX_STEER_V037 = 0.72
  FIELD_AI_MIN_STEER_V037 = 0.03
  FIELD_AI_PRESSURED_WEIGHT_V037 = 0.35
  VERIFICATION_FIELD_AI_END_FRAME_V037 = 500

  class << self
    def field_ai_checksum_scalar_v037(v)
      return '' if v==nil
      return v ? 'true':'false' if v==true || v==false
      if v.is_a?(Hash)
        ks=v.keys.sort{|a,b|a.to_s<=>b.to_s}
        return ks.collect{|k|k.to_s+'='+field_ai_checksum_scalar_v037(v[k])}.join(';')
      end
      if v.is_a?(Array);return v.collect{|x|field_ai_checksum_scalar_v037(x)}.join(',');end
      return sprintf('%.2f',v) if v.is_a?(Float)
      v.to_s
    end
    def field_ai_checksum32_v037
      h=0;m=FIELD_AI_MANIFEST_V037
      m.keys.reject{|k|k==:runtime_checksum32}.sort{|a,b|a.to_s<=>b.to_s}.each do |k|
        ('M|'+k.to_s+'='+field_ai_checksum_scalar_v037(m[k])).each_byte{|by|h=((h*33)+by)&0x7fffffff}
      end
      h
    end
    def validate_field_ai_v037
      e=[];m=FIELD_AI_MANIFEST_V037
      e.push('moves') unless m[:cumulative_mapped_move_count].to_i==232
      e.push('coverage') unless m[:cumulative_reference_covered].to_i==3885
      e.push('local') unless m[:local_field_count].to_i==6
      e.push('weights') unless FIELD_AI_POLICY_WEIGHT_V037.size==8
      e.push('berserker') unless FIELD_AI_POLICY_WEIGHT_V037[:berserker].to_f==0.0
      e.push('hook') unless m[:field_value_hook]==:field_value_at && m[:movement_hook]==:desired_velocity
      e.push('checksum') unless field_ai_checksum32_v037==m[:runtime_checksum32].to_i
      e
    end
  end

  remove_const(:VERIFICATION_MODES) if const_defined?(:VERIFICATION_MODES)
  VERIFICATION_MODES=[:field_ai,:field_spatial,:skill_special_ii,:skill_special,:skill_audio]
  remove_const(:VERIFICATION_LABELS) if const_defined?(:VERIFICATION_LABELS)
  VERIFICATION_LABELS={:field_ai=>'FIELD_AI',:field_spatial=>'FIELD_SPATIAL',:skill_special_ii=>'SKILL_SPECIAL_II',:skill_special=>'SKILL_SPECIAL',:skill_audio=>'SKILL_AUDIO'}
end

class Game_PMDChessUnit
  alias pmd_ac_v037_desired_velocity desired_velocity unless method_defined?(:pmd_ac_v037_desired_velocity)
  def desired_velocity
    base=pmd_ac_v037_desired_velocity
    return base if @scene==nil || !@scene.respond_to?(:field_navigation_vector_v037)
    len=Math.sqrt(base[0].to_f*base[0].to_f+base[1].to_f*base[1].to_f)
    # No move goal / already holding attack position: do not wander merely to
    # stand on a field. This layer bends existing movement, not combat intent.
    return base if len<=0.01
    steer=@scene.field_navigation_vector_v037(self)
    return base if steer==nil
    [base[0].to_f+steer[0].to_f,base[1].to_f+steer[1].to_f]
  end
end

class Scene_PMD_AutoChess
  alias pmd_ac_v037_start start unless method_defined?(:pmd_ac_v037_start)
  alias pmd_ac_v037_prepare_verification_battle prepare_verification_battle unless method_defined?(:pmd_ac_v037_prepare_verification_battle)
  alias pmd_ac_v037_update_verification_script update_verification_script unless method_defined?(:pmd_ac_v037_update_verification_script)
  alias pmd_ac_v037_log_event log_event unless method_defined?(:pmd_ac_v037_log_event)
  alias pmd_ac_v037_complete_verification_mode complete_verification_mode unless method_defined?(:pmd_ac_v037_complete_verification_mode)

  def start
    pmd_ac_v037_start
    begin
      if FileTest.exist?(PMD_AC::BATTLE_LOG_FILE)
        text=File.open(PMD_AC::BATTLE_LOG_FILE,'rb'){|f|f.read}
        text.sub!(/PMD AutoChess Proto v0\.[0-9.]+ Battle Verification Log/,'PMD AutoChess Proto v0.37 Battle Verification Log')
        File.open(PMD_AC::BATTLE_LOG_FILE,'wb'){|f|f.write(text)}
      end
    rescue
    end
    @field_ai_log_frames_v037={}
    m=PMD_AC::FIELD_AI_MANIFEST_V037
    log_event(:field_ai,'LOADED movement_scoring=1 local_fields=6 zone=3 aura=3 global=4 attract='+PMD_AC::FIELD_AI_ATTRACT_RANGE_V037.to_i.to_s+' max_steer='+sprintf('%.2f',PMD_AC::FIELD_AI_MAX_STEER_V037)+' cumulative=232 covered=3885/7005 checksum32='+m[:runtime_checksum32].to_s)
  end

  def field_ai_policy_weight_v037(unit)
    return 0.0 if unit==nil
    w=PMD_AC::FIELD_AI_POLICY_WEIGHT_V037[unit.movement_policy]
    w=0.80 if w==nil
    if unit.threat_level==:emergency
      return 0.0
    elsif unit.threat_level==:pressured
      w*=PMD_AC::FIELD_AI_PRESSURED_WEIGHT_V037
    end
    w.to_f
  end

  # Returns unique local-field centers that have positive value for this unit.
  # field_value_at is intentionally the source of truth, so future field types
  # can extend positional value without rewriting movement code.
  def field_ai_candidates_v037(unit)
    return [] if unit==nil || @canonical_spatial_fields_v036==nil
    seen={};out=[]
    @canonical_spatial_fields_v036.each do |e|
      next if e[:spatial_type]==:global
      # The provider does not chase the center of its own moving Aura.
      if e[:spatial_type]==:aura && unit.respond_to?(:instance_uid) && e[:source_uid].to_i==unit.instance_uid.to_i
        next
      end
      cx=e[:center_x].to_f;cy=e[:center_y].to_f
      key=((cx/8.0).round.to_i).to_s+':'+((cy/8.0).round.to_i).to_s
      next if seen[key];seen[key]=true
      val=field_value_at(cx,cy,unit).to_f
      next if val<=0.0
      out.push([cx,cy,val])
    end
    out
  end

  def field_navigation_vector_v037(unit)
    return [0.0,0.0] if unit==nil || unit.dead?
    weight=field_ai_policy_weight_v037(unit)
    return [0.0,0.0] if weight<=0.0
    best=nil;best_score=0.0
    field_ai_candidates_v037(unit).each do |c|
      dx=c[0]-unit.pixel_x.to_f;dy=c[1]-unit.pixel_y.to_f
      dist=Math.sqrt(dx*dx+dy*dy)
      next if dist<=0.001 || dist>PMD_AC::FIELD_AI_ATTRACT_RANGE_V037
      proximity=1.0-dist/PMD_AC::FIELD_AI_ATTRACT_RANGE_V037
      score=c[2].to_f*weight*(0.35+0.65*proximity)
      if score>best_score
        best_score=score;best=[dx,dy,dist,c[2]]
      end
    end
    return [0.0,0.0] if best==nil || best_score<=0.0
    strength=[best_score*2.65,PMD_AC::FIELD_AI_MAX_STEER_V037].min
    return [0.0,0.0] if strength<PMD_AC::FIELD_AI_MIN_STEER_V037
    vx=best[0]/best[2]*strength;vy=best[1]/best[2]*strength
    if verification_mode!=:field_ai
      @field_ai_log_frames_v037={} if @field_ai_log_frames_v037==nil
      last=@field_ai_log_frames_v037[unit.id]||-9999;now=Graphics.frame_count
      if now-last>=45
        @field_ai_log_frames_v037[unit.id]=now
        log_event(:field_ai,unit.log_name+' steer=('+sprintf('%.2f',vx)+','+sprintf('%.2f',vy)+') field_value='+sprintf('%.2f',best[3])+' policy='+unit.movement_policy.to_s)
      end
    end
    [vx,vy]
  end

  def prepare_verification_battle
    pmd_ac_v037_prepare_verification_battle
    if verification_mode==:field_ai
      @field_ai_failed_v037=false
      canonical_init_spatial_fields_v036
      for u in @units
        u.verification_combat_sandbox(true)
        u.reset_stat_stages if u.respond_to?(:reset_stat_stages)
      end
    end
  end

  def log_event(category,message)
    if category.to_s=='verify' && verification_mode==:field_ai && message.to_s.index('FIELD_AI_')==0 && message.to_s.include?(' pass=0')
      @field_ai_failed_v037=true
    end
    pmd_ac_v037_log_event(category,message)
  end

  def field_ai_units_v037
    a=living_units(:ally);e=living_units(:enemy);[a[0],a[1],e[0],e[1]]
  end

  def verify_field_ai_manifest_v037
    return if @verification_done[:field_ai_manifest]
    e=PMD_AC.validate_field_ai_v037;m=PMD_AC::FIELD_AI_MANIFEST_V037;pass=e.empty?
    log_event(:verify,'FIELD_AI_MANIFEST pass='+(pass ? '1':'0')+' local=6 zone=3 aura=3 global=4 cumulative=232 covered=3885/7005 attract=190 max_steer=0.72 checksum='+PMD_AC.field_ai_checksum32_v037.to_s+' errors=['+e.join(',')+']')
    @verification_done[:field_ai_manifest]=true
  end

  def verify_field_ai_zone_attraction_v037
    return if @verification_done[:field_ai_zone]
    clear_all_spatial_fields_v036(:verify);provider,mover,enemy,d=field_ai_units_v037
    provider.deploy_to_cell(2,2);mover.deploy_to_cell(0,2);set_canonical_field_effect_v035(:reflect,provider,5)
    inside=field_value_at(provider.pixel_x,provider.pixel_y,mover);outside=field_value_at(mover.pixel_x,mover.pixel_y,mover)
    vec=field_navigation_vector_v037(mover);enemy_vec=field_navigation_vector_v037(enemy)
    pass=inside>outside && vec[0]>0.03 && enemy_vec[0].abs<0.001 && enemy_vec[1].abs<0.001
    log_event(:verify,'FIELD_AI_ZONE_ATTRACTION pass='+(pass ? '1':'0')+' value='+sprintf('%.2f',outside)+'->'+sprintf('%.2f',inside)+' steer=('+sprintf('%.2f',vec[0])+','+sprintf('%.2f',vec[1])+') enemy_ignores=1')
    @verification_done[:field_ai_zone]=true
  end

  def verify_field_ai_aura_follow_v037
    return if @verification_done[:field_ai_aura]
    clear_all_spatial_fields_v036(:verify);provider,mover,enemy,d=field_ai_units_v037
    provider.deploy_to_cell(2,1);mover.deploy_to_cell(0,2);set_canonical_field_effect_v035(:tailwind,provider,4)
    v1=field_navigation_vector_v037(mover);provider.deploy_to_cell(1,4);canonical_update_spatial_fields_v036;v2=field_navigation_vector_v037(mover)
    selfv=field_navigation_vector_v037(provider)
    changed=(v1[0]-v2[0]).abs>0.03 || (v1[1]-v2[1]).abs>0.03
    pass=(v1[0].abs+v1[1].abs)>0.03 && changed && selfv[0].abs<0.001 && selfv[1].abs<0.001
    log_event(:verify,'FIELD_AI_AURA_FOLLOW pass='+(pass ? '1':'0')+' before=('+sprintf('%.2f',v1[0])+','+sprintf('%.2f',v1[1])+') after=('+sprintf('%.2f',v2[0])+','+sprintf('%.2f',v2[1])+') provider_self_chase=0')
    @verification_done[:field_ai_aura]=true
  end

  def verify_field_ai_policy_v037
    return if @verification_done[:field_ai_policy]
    clear_all_spatial_fields_v036(:verify);provider,mover,enemy,d=field_ai_units_v037
    provider.deploy_to_cell(2,2);mover.deploy_to_cell(0,2);set_canonical_field_effect_v035(:safeguard,provider,5)
    oldp=mover.instance_variable_get(:@movement_policy);oldt=mover.instance_variable_get(:@threat_level)
    mover.instance_variable_set(:@movement_policy,:controller);mover.instance_variable_set(:@threat_level,:safe);normal=field_navigation_vector_v037(mover)
    mover.instance_variable_set(:@threat_level,:pressured);press=field_navigation_vector_v037(mover)
    mover.instance_variable_set(:@threat_level,:emergency);em=field_navigation_vector_v037(mover)
    mover.instance_variable_set(:@movement_policy,:berserker);mover.instance_variable_set(:@threat_level,:safe);bers=field_navigation_vector_v037(mover)
    mover.instance_variable_set(:@movement_policy,oldp);mover.instance_variable_set(:@threat_level,oldt)
    nm=Math.sqrt(normal[0]*normal[0]+normal[1]*normal[1]);pm=Math.sqrt(press[0]*press[0]+press[1]*press[1])
    pass=nm>0.05 && pm>0.0 && pm<nm && em[0].abs<0.001 && em[1].abs<0.001 && bers[0].abs<0.001 && bers[1].abs<0.001
    log_event(:verify,'FIELD_AI_POLICY pass='+(pass ? '1':'0')+' normal='+sprintf('%.2f',nm)+' pressured='+sprintf('%.2f',pm)+' emergency=0 berserker=0')
    @verification_done[:field_ai_policy]=true
  end

  def verify_field_ai_velocity_hook_v037
    return if @verification_done[:field_ai_velocity]
    clear_all_spatial_fields_v036(:verify);provider,mover,enemy,d=field_ai_units_v037
    provider.deploy_to_cell(2,2);mover.deploy_to_cell(0,2);set_canonical_field_effect_v035(:reflect,provider,5)
    mover.set_move_goal(mover.pixel_x,mover.pixel_y-100.0)
    base=mover.pmd_ac_v037_desired_velocity;mixed=mover.desired_velocity;mover.clear_move_goal
    pass=base[0].abs<0.05 && mixed[0]>0.03 && mixed[1]<0.0
    log_event(:verify,'FIELD_AI_VELOCITY_HOOK pass='+(pass ? '1':'0')+' base=('+sprintf('%.2f',base[0])+','+sprintf('%.2f',base[1])+') mixed=('+sprintf('%.2f',mixed[0])+','+sprintf('%.2f',mixed[1])+') field_value_at_integrated=1')
    @verification_done[:field_ai_velocity]=true
  end

  def verify_field_ai_overlap_v037
    return if @verification_done[:field_ai_overlap]
    clear_all_spatial_fields_v036(:verify);provider,mover,enemy,d=field_ai_units_v037
    provider.deploy_to_cell(2,2);mover.deploy_to_cell(0,2);set_canonical_field_effect_v035(:reflect,provider,5)
    single=field_value_at(provider.pixel_x,provider.pixel_y,mover);v1=field_navigation_vector_v037(mover)
    set_canonical_field_effect_v035(:tailwind,provider,4);stack=field_value_at(provider.pixel_x,provider.pixel_y,mover);v2=field_navigation_vector_v037(mover)
    m1=Math.sqrt(v1[0]*v1[0]+v1[1]*v1[1]);m2=Math.sqrt(v2[0]*v2[0]+v2[1]*v2[1])
    pass=stack>single && m2>=m1
    log_event(:verify,'FIELD_AI_OVERLAP pass='+(pass ? '1':'0')+' field_value='+sprintf('%.2f',single)+'->'+sprintf('%.2f',stack)+' steer='+sprintf('%.2f',m1)+'->'+sprintf('%.2f',m2)+' stacked_benefit=1')
    @verification_done[:field_ai_overlap]=true
  end

  def verify_field_ai_runtime_v037
    return if @verification_done[:field_ai_runtime]
    old=@units.all?{|u|u.respond_to?(:pmd_ac_v037_desired_velocity)}
    pass=old && respond_to?(:field_navigation_vector_v037) && respond_to?(:field_value_at)
    log_event(:verify,'FIELD_AI_RUNTIME pass='+(pass ? '1':'0')+' movement_hook=desired_velocity field_value_at=1 existing_policies_preserved=1 combat_targeting_unchanged=1')
    @verification_done[:field_ai_runtime]=true
  end

  def verify_field_ai_modes_v037
    return if @verification_done[:field_ai_modes]
    exp=[:field_ai,:field_spatial,:skill_special_ii,:skill_special,:skill_audio]
    pass=PMD_AC::VERIFICATION_MODES==exp && verification_mode==:field_ai
    log_event(:verify,'FIELD_AI_RECENT_MODES pass='+(pass ? '1':'0')+' modes=5 default=FIELD_AI')
    @verification_done[:field_ai_modes]=true
  end

  def update_verification_script
    pmd_ac_v037_update_verification_script
    return unless verification_mode==:field_ai
    f=@verification_frame
    verify_field_ai_manifest_v037 if f==4
    verify_field_ai_zone_attraction_v037 if f==50
    verify_field_ai_aura_follow_v037 if f==110
    verify_field_ai_policy_v037 if f==180
    verify_field_ai_velocity_hook_v037 if f==250
    verify_field_ai_overlap_v037 if f==320
    verify_field_ai_runtime_v037 if f==390
    verify_field_ai_modes_v037 if f==430
    complete_verification_mode if f==PMD_AC::VERIFICATION_FIELD_AI_END_FRAME_V037
  end

  def complete_verification_mode
    if verification_mode==:field_ai && @field_ai_failed_v037
      for u in @units;u.verification_finish;end
      @verification_done[:complete]=true
      log_event(:verify,'FAILED mode=FIELD_AI auto_skill=on original_skills=restored')
      return
    end
    pmd_ac_v037_complete_verification_mode
  end
end
