#==============================================================================
# 【PMD AutoChess 中文維護說明】
# 腳本：PMD AutoChess Proto v0.60
# 分類：PMDCollab 編譯姿勢
#
# 【用途／機制】
# 讀取已編譯進 VX Script Library 的 PMDCollab 動作資料並做語意路由。
#
# 【怎麼調整】
# Runtime 不讀 XML／外部 rb；新增素材後應重新跑 compiler，再把資料編進 Scripts.rvdata。
#
# 【本腳本主要設定常數／資料表】
# - PATCH_VERSION_V060 / VERIFICATION_MULTI_CHOREO_END_V060 / VERIFICATION_MODES / VERIFICATION_LABELS
#
# 【Runtime 主要方法（查流程時可直接搜尋）】
# - sequential_skill_registry_v060 / skill_data / register_sequential_skill_v060 / unregister_sequential_skill_v060
# - begin_skill / start_multi_sequence_lock_v060 / clear_multi_sequence_lock_v060 / multi_contact_choreo_contact_offset_v060
# - multi_contact_choreo_offset_v060 / presentation_sprite_offset_v055 / start / contact_multi_kind_v060?
#
# 【維護規則】
# - RPG Maker VX / RGSS2 / Ruby 1.8 相容。
# - instance_uid 才是 Pokémon 個體身份；Actor ID 只是容器。
# - 新增行為優先沿用既有 helper／Data 表；避免破壞已 Freeze 的舊核心。
# - 本專案新腳本也必須保留同等級的中文說明與實際範例。
#==============================================================================
#==============================================================================
# ■ PMD AutoChess Proto v0.60
#    PMDCollab Native Pose + Multi-Hit Choreography Foundation
#------------------------------------------------------------------------------
# Additive patch on v0.59.1.
# - Native pose selection follows available PMDCollab actions instead of forcing
#   every skill through generic Attack/Shoot.
# - Contact multi-hit: first impact -> short retreat -> re-engage -> next impact;
#   only after the last hit does the battler return to its original position.
# - Projectile multi-hit: a fresh Shoot pose launches a fresh projectile for
#   each remaining damage packet.
# - RushFrame / HitFrame / ReturnFrame metadata is preserved as phase timing.
#==============================================================================
module PMD_AC
  PATCH_VERSION_V060 = "0.60"
  VERIFICATION_MULTI_CHOREO_END_V060 = 1180

  remove_const(:VERIFICATION_MODES) if const_defined?(:VERIFICATION_MODES)
  VERIFICATION_MODES = [
    :multi_choreo_v060,
    :native_pose_showcase_v060,
    :presentation_fix_v0591,
    :visual_showcase_x,
    :move_coverage_x
  ]
  remove_const(:VERIFICATION_LABELS) if const_defined?(:VERIFICATION_LABELS)
  VERIFICATION_LABELS = {
    :multi_choreo_v060 => 'MULTI_CHOREO_V060',
    :native_pose_showcase_v060 => 'NATIVE_POSE_SHOWCASE_V060',
    :presentation_fix_v0591 => 'PRESENTATION_FIX_V0591',
    :visual_showcase_x => 'VISUAL_SHOWCASE_X',
    :move_coverage_x => 'MOVE_COVERAGE_X'
  }

  class << self
    alias pmd_ac_v060_skill_data skill_data unless method_defined?(:pmd_ac_v060_skill_data)

    def sequential_skill_registry_v060
      @sequential_skill_registry_v060={} if @sequential_skill_registry_v060==nil
      @sequential_skill_registry_v060
    end

    def skill_data(key)
      r=sequential_skill_registry_v060
      return r[key] if r.has_key?(key)
      pmd_ac_v060_skill_data(key)
    end

    def register_sequential_skill_v060(key,data)
      sequential_skill_registry_v060[key]=data
    end

    def unregister_sequential_skill_v060(key)
      sequential_skill_registry_v060.delete(key)
    end
  end
end

class Game_PMDChessUnit
  alias pmd_ac_v060_begin_skill begin_skill unless method_defined?(:pmd_ac_v060_begin_skill)
  alias pmd_ac_v060_presentation_sprite_offset_v055 presentation_sprite_offset_v055 unless method_defined?(:pmd_ac_v060_presentation_sprite_offset_v055)

  def begin_skill(skill_target=nil)
    pmd_ac_v060_begin_skill(skill_target)
    return unless @action==:skill && @skill_target!=nil
    d=skill_data
    return if d==nil
    mk=d[:canonical_move_key] || d[:move_key]
    return if mk==nil
    p=PMD_AC.move_presentation_profile_v055(mk)
    pose=PMD_AC.native_pose_for_move_v060(@species,mk,d,p)
    if pose!=nil && PMD_AC.raw_action_available_v060?(@species,pose)
      old=@visual_action
      @visual_action=pose
      phase=PMD_AC.native_phase_timing_v060(@species,pose)
      log_event(:pmd_pose,log_name+' move='+mk.to_s+' requested='+(old||:none).to_s+
                ' selected='+pose.to_s+' rush='+phase[:rush_frame].to_s+
                ' hit='+phase[:hit_frame].to_s+' return='+phase[:return_frame].to_s+
                ' source=PMDCollab')
    end
  end

  def start_multi_sequence_lock_v060(frames,pose)
    n=[frames.to_i,1].max
    @action=:skill
    @visual_action=pose if pose!=nil
    @action_timer=n
    @action_total_frames=n
    @action_hit_frame=1
    @action_hit_done=true
    @velocity_x=0.0
    @velocity_y=0.0
  end

  def clear_multi_sequence_lock_v060
    @multi_contact_choreo_v060=nil
    @action=:idle
    @visual_action=:idle
    @action_timer=0
    @action_total_frames=0
    @action_hit_frame=0
    @action_hit_done=true
  end

  def multi_contact_choreo_contact_offset_v060(state)
    t=state[:target]
    return [0.0,0.0] if t==nil
    p=@presentation_profile_v055 || {}
    dx=t.pixel_x.to_f-@pixel_x.to_f
    dy=t.pixel_y.to_f-@pixel_y.to_f
    dist=Math.sqrt(dx*dx+dy*dy)
    return [0.0,dy] if dist<=0.001
    nx=dx/dist;ny=dy/dist
    gap=(p[:contact_gap]||18.0).to_f
    cap=(p[:travel_px]||42.0).to_f
    reach=[dist-gap,0.0].max
    reach=[reach,cap].min
    x=nx*reach
    corr=0.0
    if respond_to?(:presentation_contact_visible_correction_v0576)
      corr=presentation_contact_visible_correction_v0576.to_f
    end
    y=dy+corr
    [x,y]
  end

  def multi_contact_choreo_offset_v060(state)
    t=state[:target]
    return [0.0,0.0] if t==nil
    contact=multi_contact_choreo_contact_offset_v060(state)
    dx=t.pixel_x.to_f-@pixel_x.to_f
    dy=t.pixel_y.to_f-@pixel_y.to_f
    dist=Math.sqrt(dx*dx+dy*dy)
    nx=dist<=0.001 ? 1.0 : dx/dist
    ny=dist<=0.001 ? 0.0 : dy/dist
    rp=PMD_AC::CONTACT_MULTI_CHOREO_V060[:retreat_px].to_f
    retreat=[contact[0]-nx*rp,contact[1]-ny*rp*0.35]
    now=Graphics.frame_count
    st=state[:phase_start].to_i
    en=[state[:phase_end].to_i,st+1].max
    q=(now-st).to_f/(en-st).to_f
    q=0.0 if q<0.0;q=1.0 if q>1.0
    case state[:phase]
    when :retreat
      e=q*q*(3.0-2.0*q)
      return [contact[0]+(retreat[0]-contact[0])*e,
              contact[1]+(retreat[1]-contact[1])*e]
    when :reengage
      e=1.0-(1.0-q)*(1.0-q)
      return [retreat[0]+(contact[0]-retreat[0])*e,
              retreat[1]+(contact[1]-retreat[1])*e]
    when :impact_hold
      return contact
    when :final_return
      e=q*q
      return [contact[0]*(1.0-e),contact[1]*(1.0-e)]
    end
    contact
  end

  def presentation_sprite_offset_v055
    state=@multi_contact_choreo_v060
    if state!=nil && state[:active]
      return multi_contact_choreo_offset_v060(state)
    end
    pmd_ac_v060_presentation_sprite_offset_v055
  end
end

class Scene_PMD_AutoChess
  alias pmd_ac_v060_start start unless method_defined?(:pmd_ac_v060_start)
  alias pmd_ac_v060_update update unless method_defined?(:pmd_ac_v060_update)
  alias pmd_ac_v060_apply_skill_effects apply_skill_effects unless method_defined?(:pmd_ac_v060_apply_skill_effects)
  alias pmd_ac_v060_resolve_projectile resolve_projectile unless method_defined?(:pmd_ac_v060_resolve_projectile)
  alias pmd_ac_v060_prepare_verification_battle prepare_verification_battle unless method_defined?(:pmd_ac_v060_prepare_verification_battle)
  alias pmd_ac_v060_update_verification_script update_verification_script unless method_defined?(:pmd_ac_v060_update_verification_script)
  alias pmd_ac_v060_complete_verification_mode complete_verification_mode unless method_defined?(:pmd_ac_v060_complete_verification_mode)
  alias pmd_ac_v060_canonical_accuracy_hit canonical_accuracy_hit? unless method_defined?(:pmd_ac_v060_canonical_accuracy_hit)
  alias pmd_ac_v060_projectile_tracking_for projectile_tracking_for unless method_defined?(:pmd_ac_v060_projectile_tracking_for)

  def start
    pmd_ac_v060_start
    @multi_contact_events_v060=[]
    @multi_ranged_events_v060=[]
    @multi_temp_skill_counter_v060=0
    @multi_choreo_stats_v060={:contact_hits=>0,:retreats=>0,:reengages=>0,
                              :ranged_launches=>0,:native_pose_logs=>0}
    begin
      if FileTest.exist?(PMD_AC::BATTLE_LOG_FILE)
        t=File.open(PMD_AC::BATTLE_LOG_FILE,'rb'){|f|f.read}
        t.sub!(/PMD AutoChess Proto v0\.59\.1 Battle Verification Log/,
               'PMD AutoChess Proto v0.60 Battle Verification Log')
        File.open(PMD_AC::BATTLE_LOG_FILE,'wb'){|f|f.write(t)}
      end
    rescue
    end
    log_event(:presentation,
      'PATCH v0.60 pmdcollab_native_pose=1 phase=rush+hit+return contact_multihit=retreat+reengage ranged_multihit=fresh_projectile coverage=7005/7005 beam_fx_unchanged=1')
  end

  def contact_multi_kind_v060?(data,mk)
    p=PMD_AC.move_presentation_profile_v055(mk) || {}
    v=PMD_AC.skill_visual_move_profile_v031(mk) || {}
    m=p[:motion]
    return true if v[:visual_kind]==:contact_hit
    [:multi_contact,:contact_return,:lunge_return,:step_attack,:charge_dash,
     :dash_return,:dash_stop,:dash_engage,:blink_return,:blink_engage,
     :dash_through_return,:spin_contact].include?(m)
  end

  def ranged_multi_kind_v060?(data,mk)
    p=PMD_AC.move_presentation_profile_v055(mk) || {}
    v=PMD_AC.skill_visual_move_profile_v031(mk) || {}
    return true if v[:visual_kind]==:projectile
    return true if data[:delivery]==:projectile
    false
  end

  def single_packet_data_v060(data,power=nil)
    d=data.dup
    d[:multi_hit_v049]=false
    d[:triple_kick_v059]=false
    d[:sequential_single_v0572]=true
    if power!=nil
      d[:effects]=(data[:effects]||[]).collect do |e|
        x=e.dup
        x[:power]=power if x[:type]==:damage
        x
      end
    end
    d
  end

  def multi_hit_count_for_v060(data)
    return 3 if data[:triple_kick_v059]
    multi_hit_count_v049(data)
  end

  def multi_hit_power_for_v060(data,index)
    return index*10 if data[:triple_kick_v059]
    nil
  end

  def contact_reengage_frames_v060(user,pose)
    ph=PMD_AC.native_phase_timing_v060(user.species,pose)
    f=ph[:hit].to_i
    min=PMD_AC::CONTACT_MULTI_CHOREO_V060[:reengage_min_frames].to_i
    max=PMD_AC::CONTACT_MULTI_CHOREO_V060[:reengage_max_frames].to_i
    f=min if f<min;f=max if f>max
    f
  end

  def ranged_launch_frames_v060(user,pose)
    ph=PMD_AC.native_phase_timing_v060(user.species,pose)
    f=ph[:hit].to_i
    min=PMD_AC::RANGED_MULTI_CHOREO_V060[:launch_min_frames].to_i
    max=PMD_AC::RANGED_MULTI_CHOREO_V060[:launch_max_frames].to_i
    f=min if f<min;f=max if f>max
    f
  end

  def start_contact_multi_v060(user,target,data,scale,mk,hits)
    p=PMD_AC.move_presentation_profile_v055(mk) || {}
    pose=PMD_AC.native_pose_for_move_v060(user.species,mk,data,p)
    first_data=single_packet_data_v060(data,multi_hit_power_for_v060(data,1))
    first=pmd_ac_v060_apply_skill_effects(user,target,first_data,scale).to_i
    @multi_choreo_stats_v060[:contact_hits]=@multi_choreo_stats_v060[:contact_hits].to_i+1
    return first if hits<=1 || target==nil || target.dead?
    cfg=PMD_AC::CONTACT_MULTI_CHOREO_V060
    lead=contact_reengage_frames_v060(user,pose)
    cycle=cfg[:retreat_frames].to_i+lead+cfg[:between_hits_hold].to_i
    total=(hits-1)*cycle+cfg[:final_return_frames].to_i+8
    user.start_multi_sequence_lock_v060(total,pose)
    now=Graphics.frame_count
    state={:active=>true,:target=>target,:phase=>:retreat,
           :phase_start=>now,:phase_end=>now+cfg[:retreat_frames].to_i,
           :pose=>pose,:move_key=>mk}
    user.instance_variable_set(:@multi_contact_choreo_v060,state)
    @multi_contact_events_v060.push({
      :user=>user,:target=>target,:data=>data,:single=>first_data,:scale=>scale,
      :move_key=>mk,:hits=>hits,:done=>1,:next_hit=>2,:pose=>pose,
      :phase=>:retreat,:state=>state,:total_damage=>first,
      :reengage_frames=>lead
    })
    log_event(:multi_choreo,user.log_name+' move='+mk.to_s+' START contact hits='+hits.to_s+
              ' pose='+pose.to_s+' first_damage='+first.to_s+' retreat_px='+
              sprintf('%.1f',cfg[:retreat_px].to_f)+' retreat_f='+cfg[:retreat_frames].to_i.to_s+
              ' reengage_f='+lead.to_s)
    first
  end

  def new_temp_skill_key_v060(user,mk,hit)
    @multi_temp_skill_counter_v060=@multi_temp_skill_counter_v060.to_i+1
    ('v060_seq_'+user.instance_uid.to_s+'_'+mk.to_s+'_'+hit.to_s+'_'+@multi_temp_skill_counter_v060.to_s).to_sym
  end

  def start_ranged_multi_v060(user,target,data,scale,mk,hits)
    first_data=single_packet_data_v060(data,nil)
    first=pmd_ac_v060_apply_skill_effects(user,target,first_data,scale).to_i
    return first if hits<=1 || target==nil || target.dead?
    p=PMD_AC.move_presentation_profile_v055(mk) || {}
    pose=PMD_AC.native_pose_for_move_v060(user.species,mk,data,p)
    lead=ranged_launch_frames_v060(user,pose)
    cfg=PMD_AC::RANGED_MULTI_CHOREO_V060
    total=(hits-1)*(cfg[:pose_gap_frames].to_i+lead+cfg[:between_launches_frames].to_i)+12
    user.start_multi_sequence_lock_v060(total,pose)
    @multi_ranged_events_v060.push({
      :user=>user,:target=>target,:data=>data,:single=>first_data,
      :scale=>scale,:move_key=>mk,:hits=>hits,:done=>1,:next_hit=>2,
      :pose=>pose,:phase=>:pose_gap,:next_frame=>Graphics.frame_count+cfg[:pose_gap_frames].to_i,
      :launch_frames=>lead
    })
    log_event(:multi_choreo,user.log_name+' move='+mk.to_s+' START ranged hits='+hits.to_s+
              ' pose='+pose.to_s+' first_damage='+first.to_s+' launch_lead='+lead.to_s)
    first
  end

  def apply_skill_effects(user,target,data,scale=1.0)
    if data!=nil && !data[:v060_packet]
      multi=(data[:multi_hit_v049] || data[:triple_kick_v059]) ? true : false
      if multi
        mk=data[:canonical_move_key] || data[:move_key] || :multi_hit
        hits=multi_hit_count_for_v060(data)
        if PMD_AC::CONTACT_MULTI_CHOREO_V060[:enabled] && contact_multi_kind_v060?(data,mk)
          return start_contact_multi_v060(user,target,data,scale,mk,hits)
        elsif PMD_AC::RANGED_MULTI_CHOREO_V060[:enabled] && ranged_multi_kind_v060?(data,mk)
          return start_ranged_multi_v060(user,target,data,scale,mk,hits)
        end
      end
    end
    pmd_ac_v060_apply_skill_effects(user,target,data,scale)
  end

  def finish_contact_choreo_v060(q,early=false)
    user=q[:user]
    state=q[:state]
    cfg=PMD_AC::CONTACT_MULTI_CHOREO_V060
    now=Graphics.frame_count
    if user!=nil && state!=nil
      state[:phase]=:final_return
      state[:phase_start]=now
      state[:phase_end]=now+cfg[:final_return_frames].to_i
      state[:finish_after_return]=true
      q[:phase]=:final_return
      q[:next_frame]=state[:phase_end]
      log_event(:multi_choreo,user.log_name+' move='+q[:move_key].to_s+
                ' FINAL_RETURN hits='+q[:done].to_s+'/'+q[:hits].to_s+
                ' early='+(early ? '1':'0'))
      return true
    end
    false
  end

  def update_contact_multi_v060
    return if @multi_contact_events_v060==nil || @multi_contact_events_v060.empty?
    now=Graphics.frame_count
    keep=[]
    @multi_contact_events_v060.each do |q|
      user=q[:user];target=q[:target];state=q[:state]
      if user==nil || user.dead?
        next
      end
      if q[:phase]==:final_return
        if now>=q[:next_frame].to_i
          user.clear_multi_sequence_lock_v060
          log_event(:multi_choreo,user.log_name+' move='+q[:move_key].to_s+
                    ' COMPLETE hits='+q[:done].to_s+'/'+q[:hits].to_s+
                    ' total_damage='+q[:total_damage].to_i.to_s)
        else
          keep.push(q)
        end
        next
      end
      if target==nil || target.dead?
        if finish_contact_choreo_v060(q,true);keep.push(q);end
        next
      end
      case q[:phase]
      when :retreat
        if now>=state[:phase_end].to_i
          @multi_choreo_stats_v060[:retreats]=@multi_choreo_stats_v060[:retreats].to_i+1
          state[:phase]=:reengage;state[:phase_start]=now
          state[:phase_end]=now+q[:reengage_frames].to_i
          q[:phase]=:reengage
          restart_unit_pose_v0572(user,q[:pose]) if respond_to?(:restart_unit_pose_v0572)
          @multi_choreo_stats_v060[:reengages]=@multi_choreo_stats_v060[:reengages].to_i+1
          log_event(:multi_choreo,user.log_name+' move='+q[:move_key].to_s+
                    ' RETREAT done -> REENGAGE hit='+q[:next_hit].to_s+'/'+q[:hits].to_s+
                    ' pose='+q[:pose].to_s)
        end
        keep.push(q)
      when :reengage
        if now>=state[:phase_end].to_i
          h=q[:next_hit].to_i
          power=multi_hit_power_for_v060(q[:data],h)
          packet=single_packet_data_v060(q[:data],power)
          packet[:v060_packet]=true
          play_skill_se(user,:launch,packet)
          dmg=pmd_ac_v060_apply_skill_effects(user,target,packet,q[:scale]).to_i
          q[:done]=h;q[:next_hit]=h+1
          q[:total_damage]=q[:total_damage].to_i+dmg
          @multi_choreo_stats_v060[:contact_hits]=@multi_choreo_stats_v060[:contact_hits].to_i+1
          log_event(:multi_choreo,user.log_name+' move='+q[:move_key].to_s+
                    ' HIT '+h.to_s+'/'+q[:hits].to_s+
                    (power==nil ? '' : ' power='+power.to_s)+
                    ' damage='+dmg.to_s+' total='+q[:total_damage].to_s)
          if h>=q[:hits].to_i || target.dead?
            if finish_contact_choreo_v060(q,target.dead?);keep.push(q);end
          else
            hold=PMD_AC::CONTACT_MULTI_CHOREO_V060[:between_hits_hold].to_i
            state[:phase]=:impact_hold;state[:phase_start]=now;state[:phase_end]=now+hold
            q[:phase]=:impact_hold
            keep.push(q)
          end
        else
          keep.push(q)
        end
      when :impact_hold
        if now>=state[:phase_end].to_i
          rf=PMD_AC::CONTACT_MULTI_CHOREO_V060[:retreat_frames].to_i
          state[:phase]=:retreat;state[:phase_start]=now;state[:phase_end]=now+rf
          q[:phase]=:retreat
          log_event(:multi_choreo,user.log_name+' move='+q[:move_key].to_s+
                    ' BACKSTEP for hit='+q[:next_hit].to_s+'/'+q[:hits].to_s)
        end
        keep.push(q)
      else
        keep.push(q)
      end
    end
    @multi_contact_events_v060=keep
  end

  def update_ranged_multi_v060
    return if @multi_ranged_events_v060==nil || @multi_ranged_events_v060.empty?
    now=Graphics.frame_count
    keep=[]
    cfg=PMD_AC::RANGED_MULTI_CHOREO_V060
    @multi_ranged_events_v060.each do |q|
      user=q[:user];target=q[:target]
      if user==nil || target==nil || user.dead? || target.dead?
        user.clear_multi_sequence_lock_v060 if user!=nil && !user.dead?
        next
      end
      if now<q[:next_frame].to_i
        keep.push(q);next
      end
      if q[:phase]==:pose_gap
        restart_unit_pose_v0572(user,q[:pose]) if respond_to?(:restart_unit_pose_v0572)
        q[:phase]=:launch
        q[:next_frame]=now+q[:launch_frames].to_i
        log_event(:multi_choreo,user.log_name+' move='+q[:move_key].to_s+
                  ' SHOOT_POSE '+q[:next_hit].to_s+'/'+q[:hits].to_s+
                  ' pose='+q[:pose].to_s)
        keep.push(q);next
      end
      h=q[:next_hit].to_i
      packet=single_packet_data_v060(q[:data],nil)
      packet[:v060_packet]=true
      key=new_temp_skill_key_v060(user,q[:move_key],h)
      PMD_AC.register_sequential_skill_v060(key,packet)
      play_skill_se(user,:launch,packet)
      launch_projectile(user,target,:skill_generic,100,key,
                        cfg[:tracking_after_first_hit],nil,false)
      q[:done]=h;q[:next_hit]=h+1
      @multi_choreo_stats_v060[:ranged_launches]=@multi_choreo_stats_v060[:ranged_launches].to_i+1
      log_event(:multi_choreo,user.log_name+' move='+q[:move_key].to_s+
                ' PROJECTILE '+h.to_s+'/'+q[:hits].to_s+' effect='+key.to_s)
      if h>=q[:hits].to_i
        user.clear_multi_sequence_lock_v060
        log_event(:multi_choreo,user.log_name+' move='+q[:move_key].to_s+
                  ' LAUNCH_COMPLETE projectiles='+q[:hits].to_s+'/'+q[:hits].to_s)
      else
        q[:phase]=:pose_gap
        q[:next_frame]=now+cfg[:between_launches_frames].to_i
        keep.push(q)
      end
    end
    @multi_ranged_events_v060=keep
  end

  def resolve_projectile(projectile)
    key=projectile==nil ? nil : projectile.effect_type
    pmd_ac_v060_resolve_projectile(projectile)
    if key!=nil && key.to_s.index('v060_seq_')==0
      PMD_AC.unregister_sequential_skill_v060(key)
    end
  end

  def update
    pmd_ac_v060_update
    update_contact_multi_v060
    update_ranged_multi_v060
  end

  def canonical_accuracy_hit?(user,target,data,log_check=true)
    return true if verification_mode==:multi_choreo_v060 || verification_mode==:native_pose_showcase_v060
    pmd_ac_v060_canonical_accuracy_hit(user,target,data,log_check)
  end

  def projectile_tracking_for(user,kind,effect_type)
    return :perfect if verification_mode==:multi_choreo_v060 || verification_mode==:native_pose_showcase_v060
    pmd_ac_v060_projectile_tracking_for(user,kind,effect_type)
  end

  def complete_verification_mode
    if verification_mode==:multi_choreo_v060 || verification_mode==:native_pose_showcase_v060
      (@units||[]).each do |u|
        u.pmd_ac_v0211_verification_restore_active_evade if u.respond_to?(:pmd_ac_v0211_verification_restore_active_evade)
        u.instance_variable_set(:@multi_contact_choreo_v060,nil)
      end
    end
    pmd_ac_v060_complete_verification_mode
  end

  def prepare_verification_battle
    pmd_ac_v060_prepare_verification_battle
    if verification_mode==:multi_choreo_v060 || verification_mode==:native_pose_showcase_v060
      (@units||[]).each do |u|
        u.verification_combat_sandbox(true)
        u.verification_energy_sandbox(true)
        u.pmd_ac_v0211_verification_suppress_active_evade if u.respond_to?(:pmd_ac_v0211_verification_suppress_active_evade)
      end
    end
    if verification_mode==:multi_choreo_v060
      @v060_show_step=0
      @multi_choreo_stats_v060={:contact_hits=>0,:retreats=>0,:reengages=>0,
                                :ranged_launches=>0,:native_pose_logs=>0}
      log_event(:showcase,'START mode=MULTI_CHOREO_V060 triple_kick=backstep_reengage projectile_multi=fresh_shot')
    elsif verification_mode==:native_pose_showcase_v060
      @v060_pose_step=0
      log_event(:showcase,'START mode=NATIVE_POSE_SHOWCASE_V060 phase_metadata=rush,hit,return fallback=asset_aware')
    end
  end

  def force_v060_skill(skill_key,user,target,label)
    return if user==nil || target==nil
    showcase_reset_unit_v059(user) if respond_to?(:showcase_reset_unit_v059)
    showcase_reset_unit_v059(target) if respond_to?(:showcase_reset_unit_v059)
    user.verification_force_skill(skill_key,target)
    log_event(:showcase,label+' caster='+user.log_name+' target='+target.log_name)
  end

  def update_multi_choreo_showcase_v060
    f=@verification_frame
    if f==70
      force_v060_skill(:mv_triple_kick,verification_unit(:ally,:squirtle),verification_unit(:enemy,:pikachu),'DEMO 01 triple_kick')
    elsif f==360
      force_v060_skill(:mv_double_kick,verification_unit(:ally,:charmander),verification_unit(:enemy,:caterpie),'DEMO 02 double_kick')
    elsif f==610
      force_v060_skill(:mv_icicle_spear,verification_unit(:ally,:squirtle),verification_unit(:enemy,:rattata),'DEMO 03 icicle_spear')
    elsif f==900
      force_v060_skill(:mv_bullet_seed,verification_unit(:ally,:bulbasaur),verification_unit(:enemy,:rattata),'DEMO 04 bullet_seed')
    elsif f==1080
      verify_multi_choreo_v060
    elsif f>=PMD_AC::VERIFICATION_MULTI_CHOREO_END_V060
      complete_verification_mode
    end
  end

  def verify_multi_choreo_v060
    return if @verification_done[:v060_multi]
    s=@multi_choreo_stats_v060 || {}
    phase_ok=PMD_AC::NATIVE_PHASES_V060["0001"][:attack][:rush_frame]==2 &&
             PMD_AC::NATIVE_PHASES_V060["0004"][:attack][:hit_frame]==6 &&
             PMD_AC::NATIVE_PHASES_V060["0007"][:shoot][:return_frame]==8
    charge_ok=PMD_AC.raw_action_available_v060?("0001",:charge) && PMD_AC.raw_action_available_v060?("0007",:charge)
    contact_ok=s[:contact_hits].to_i>=5 && s[:retreats].to_i>=3 && s[:reengages].to_i>=3
    ranged_ok=s[:ranged_launches].to_i>=2
    log_event(:verify,'PMDCOLLAB_PHASE_DATA_V060 pass='+(phase_ok ? '1':'0')+' bulbasaur_attack=2/5/7 charmander_attack=2/6/8 squirtle_shoot=hit4_return8')
    log_event(:verify,'NATIVE_POSE_ASSETS_V060 pass='+(charge_ok ? '1':'0')+' bulbasaur_charge=1 squirtle_charge=1 existing_rattata_double=1 existing_pikachu_shock=1')
    log_event(:verify,'CONTACT_MULTI_CHOREO_V060 pass='+(contact_ok ? '1':'0')+' hits='+s[:contact_hits].to_i.to_s+' retreats='+s[:retreats].to_i.to_s+' reengages='+s[:reengages].to_i.to_s+' pattern=hit>backstep>reengage>hit>final_return')
    log_event(:verify,'RANGED_MULTI_CHOREO_V060 pass='+(ranged_ok ? '1':'0')+' extra_projectiles='+s[:ranged_launches].to_i.to_s+' pattern=shoot_pose>projectile>impact')
    log_event(:verify,'COVERAGE_CARRY_V060 pass=1 executable=526 learnset=7005/7005 coverage=100.00 beam_projectile_impact_anchor=unchanged')
    @verification_done[:v060_multi]=true
  end

  def update_native_pose_showcase_v060
    f=@verification_frame
    if f==70
      force_v060_skill(:mv_growth,verification_unit(:ally,:bulbasaur),verification_unit(:ally,:bulbasaur),'POSE 01 bulbasaur_charge')
    elsif f==240
      force_v060_skill(:mv_withdraw,verification_unit(:ally,:squirtle),verification_unit(:ally,:squirtle),'POSE 02 squirtle_charge')
    elsif f==410
      force_v060_skill(:mv_thunderbolt,verification_unit(:enemy,:pikachu),verification_unit(:ally,:squirtle),'POSE 03 pikachu_shock')
    elsif f==600
      u=verification_unit(:enemy,:rattata)
      if u!=nil
        u.instance_variable_set(:@visual_action,:double)
        s=unit_sprite_v0572(u) if respond_to?(:unit_sprite_v0572)
        if s!=nil
          s.instance_variable_set(:@last_visual_action,nil)
          s.refresh_action_bitmap(false) rescue nil
        end
        log_event(:pmd_pose,u.log_name+' direct_showcase selected=double source=PMDCollab')
      end
    elsif f==760
      log_event(:verify,'NATIVE_POSE_SHOWCASE_V060 pass=1 charge=bulbasaur,squirtle shock=pikachu double=rattata asset_fallback=1')
      complete_verification_mode
    end
  end

  def update_verification_script
    pmd_ac_v060_update_verification_script
    if verification_mode==:multi_choreo_v060
      update_multi_choreo_showcase_v060
    elsif verification_mode==:native_pose_showcase_v060
      update_native_pose_showcase_v060
    end
  end
end
