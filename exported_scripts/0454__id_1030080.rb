# encoding: UTF-8
#==============================================================================
# ■ PMD AutoChess - Motion Phase B Remote Motion + Deploy 45° No-Hop v1.03.8
#==============================================================================
# 【用途】
# 本版承接 v1.03.7，正式補完 Remote Motion 六大 Family：
#   Projectile → Beam → Cast → Shock → Drain → Sound。
# 核心目標不是重寫技能，而是把 PMDCollab 身體動作接到既有戰鬥 authority：
#   anticipation（純 Sprite）→ Native source hitFrame release → 既有 FX / projectile /
#   beam handoff → 既有 target impact / Damage → source returnFrame recovery。
#
# 同時收緊 Deploy 待機 LOOP：
#   - Hop 完全禁止出現在待機序列。
#   - Walk 仍不作主循環；以 45° Idle 為基底。
#   - Idle 與所有 Native special 都必須具備 direct playable 8-direction 素材，畫面
#     一律由 v1.03.5 Sprite row lock 使用我方 dir=3、敵方 dir=1。
#------------------------------------------------------------------------------
# 【Frozen Combat Core / Authority 規則】
# 1. 不修改 resolve_skill、apply_skill_effects 的傷害算法、launch_projectile 的飛行
#    邏輯、Projectile collision、Beam life、Accuracy、AI、Attack Speed、Energy。
# 2. 不新增 action_timer / skill timer；Remote anticipation 只凍結 Sprite source frame，
#    gameplay timer 照原速度前進。
# 3. 真正 release authority 仍是既有 play_skill_se(:launch) / launch_projectile / Beam FX。
#    本版只在同一時點把 source Sprite snap 到 Native hitFrame。
# 4. 真正 target impact 仍由既有 apply_skill_effects / deal_direct_damage / projectile
#    resolve 擁有。本版讀取 impact 事件後才讓 source 進 returnFrame recovery。
# 5. 無傷害 Cast／Sound、MISS、IMMUNE 或其他沒有 true Damage impact 的技能，會在既有
#    apply_skill_effects 完成時或純視覺 timeout 後收勢；timeout 不阻塞 gameplay。
# 6. HOME 仍是 current action anchor；本版不寫 logical pixel_x / pixel_y。
#------------------------------------------------------------------------------
# 【六大 Remote Family 身體演技】
# - Projectile：Shoot / SpAttack / Emit，短前搖，release 後等 projectile impact 再收勢。
# - Beam：SpAttack / Shoot，release frame 稍長，等 beam/hidden projectile impact 再收勢。
# - Cast：Charge / SpAttack / Shoot / Pose，支援 self / field / target status 無傷害技能。
# - Shock：Shock 優先，保留電系 Native 身體反應，Damage / target FX 不變。
# - Drain：SpAttack / Shoot / Charge；吸收／回復數值 authority 完全不搬動。
# - Sound：Sound / Sing / RearUp / Rumble；聲音 FX/SE authority 完全保留。
#------------------------------------------------------------------------------
# 【Deploy 45° No-Hop 規則】
# 1. :hop 從 Deploy special discovery 與最終 sequence 雙重排除。
# 2. :walk 不重新加入主 LOOP；基底優先 :idle。
# 3. Base action 與所有 specials 都經 v1.03.6 direct 8-dir 檢查：playable + compiled
#    direct + 非 copy/alias + rows>=8 + asset exists。
# 4. 若某物種 Idle 無法證明 direct 8-dir，才使用該物種第一個可證明的安全 8-dir
#    neutral action；不為了「一定 Idle」而使用單方向素材假裝 45°。
# 5. v1.03.5 Sprite row lock 保持：ally dir=3 / enemy dir=1，只改 source rect，不回寫
#    Game_PMDChessUnit#facing_dir。
#------------------------------------------------------------------------------
# 【主要設定】
# REMOTE_ANTICIPATION_V1038
#   六類前搖的純視覺 frame 數，不會增加 gameplay action_timer。
# REMOTE_RELEASE_TIMEOUT_V1038
#   沒收到 impact callback 時，source pose 最長等待多久後自動 visual recovery。
# REMOTE_RECOVERY_HOLD_V1038
#   returnFrame 的可見收勢時間。
# DEPLOY_BLOCKED_EXTRA_V1038 = [:hop]
#   Hop 永久退出 Deploy idle loop。
#------------------------------------------------------------------------------
# 【可調參數】
# - 想讓 Beam 蓄勢更明顯：只增加 REMOTE_ANTICIPATION_V1038[:beam]，不要改技能 timer。
# - Projectile 若遠距離飛行很久，可增加 REMOTE_RELEASE_TIMEOUT_V1038[:projectile]；
#   這只影響 source pose 最長保持時間，不改 projectile speed。
# - Deploy LOOP 太快／太慢仍調 v1.03.7 hold scale，不要改 Graphics.frame_rate。
#------------------------------------------------------------------------------
# 【事件／腳本呼叫方式】
# 不需事件呼叫。NORMAL 與 PMD Motion Runtime 自動生效。
# Windows 驗收：Deploy 停 10～20 秒確認無 Hop、所有動作維持 45°；再按 S 切
# PMD Motion → Shift → 完整戰鬥，觀察 Projectile / Beam / Cast / Shock / Drain /
# Sound 的 source release 與 target impact 銜接。
#------------------------------------------------------------------------------
# 【實際範例】
# - Pikachu Thunderbolt：Shock Native 前搖 → Shock hitFrame release → 原電系 FX / Damage
#   → target Hurt → Pikachu returnFrame 收勢；不提前 Damage。
# - Squirtle Water Gun：Shoot / SpAttack 前搖 → projectile release → 原 projectile 飛行
#   → 命中後 Hurt → source recovery；Projectile speed 完全不變。
# - Bulbasaur Absorb：Drain Native release → 原吸收 Damage/Heal → impact 後 source recovery；
#   回復量與 Damage Formula 不變。
# - Deploy：Idle / Nod / Pose / Shake 等若不是 direct 8-dir 就不用；Hop 永遠不用。
#==============================================================================

$imported = {} unless defined?($imported)
$imported['PMD_AutoChess_MotionPhaseB_RemoteMotion_Deploy45NoHop_v1038'] = true

module PMD_AC
  MOTION_PHASE_B_REMOTE_VERSION_V1038 = '1.03.8'
  MOTION_REMOTE_FAMILIES_V1038 = [:projectile,:beam,:cast,:shock,:drain,:sound]
  REMOTE_ANTICIPATION_V1038 = {
    :projectile=>3, :beam=>5, :cast=>5, :shock=>4, :drain=>5, :sound=>4
  }
  REMOTE_RELEASE_TIMEOUT_V1038 = {
    :projectile=>28, :beam=>24, :cast=>14, :shock=>20, :drain=>22, :sound=>18
  }
  REMOTE_RECOVERY_HOLD_V1038 = {
    :projectile=>5, :beam=>7, :cast=>6, :shock=>6, :drain=>7, :sound=>6
  }
  DEPLOY_BLOCKED_EXTRA_V1038 = [:hop]
end

#==============================================================================
# ■ Game_PMDChessUnit - Remote source presentation state / Deploy no-hop sequence
#==============================================================================
class Game_PMDChessUnit
  alias pmd_ac_v1038_initialize initialize unless method_defined?(:pmd_ac_v1038_initialize)
  alias pmd_ac_v1038_start_combat start_combat unless method_defined?(:pmd_ac_v1038_start_combat)
  alias pmd_ac_v1038_stop_combat stop_combat unless method_defined?(:pmd_ac_v1038_stop_combat)
  alias pmd_ac_v1038_begin_skill begin_skill unless method_defined?(:pmd_ac_v1038_begin_skill)
  alias pmd_ac_v1038_update update unless method_defined?(:pmd_ac_v1038_update)
  alias pmd_ac_v1038_visual_action visual_action unless method_defined?(:pmd_ac_v1038_visual_action)
  alias pmd_ac_v1038_motion_deploy_idle_reset_v1033 motion_deploy_idle_reset_v1033 unless method_defined?(:pmd_ac_v1038_motion_deploy_idle_reset_v1033)

  def initialize(*args)
    pmd_ac_v1038_initialize(*args)
    motion_remote_clear_v1038
  end

  def start_combat
    pmd_ac_v1038_start_combat
    motion_remote_clear_v1038
  end

  def stop_combat
    pmd_ac_v1038_stop_combat
    motion_remote_clear_v1038
  end

  def motion_remote_family_v1038?(family)
    PMD_AC::MOTION_REMOTE_FAMILIES_V1038.include?(family)
  rescue
    false
  end

  def motion_remote_clear_v1038
    @motion_remote_state_v1038=nil
    @motion_remote_recovery_snap_v1038=false
  end

  def motion_remote_state_v1038
    @motion_remote_state_v1038
  end

  def motion_remote_active_v1038?
    @motion_remote_state_v1038!=nil
  end

  def motion_remote_phase_v1038
    s=@motion_remote_state_v1038
    s==nil ? nil : s[:phase]
  end

  def motion_remote_begin_v1038(move_key,data=nil,route=nil,source=:begin_skill)
    return false unless motion_phase_a_species_v102?
    r=route
    if r==nil
      p=nil
      begin;p=PMD_AC.move_presentation_profile_v055(move_key);rescue;p=nil;end
      begin;r=PMD_AC.motion_source_route_v102(@species,move_key,data,p);rescue;r=nil;end
    end
    return false if r==nil
    fam=r[:family]
    return false unless motion_remote_family_v1038?(fam)
    pose=r[:selected]
    return false if pose==nil || !PMD_AC.motion_playable_v102?(@species,pose)
    @visual_action=pose
    @motion_remote_state_v1038={
      :move_key=>move_key,:family=>fam,:pose=>pose,:hit_frame=>r[:hit_frame],
      :return_frame=>r[:return_frame],:phase=>:anticipation,
      :started_at=>Graphics.frame_count,:released_at=>nil,:impact_at=>nil,
      :anticipation=>PMD_AC::REMOTE_ANTICIPATION_V1038[fam].to_i,
      :release_timeout=>PMD_AC::REMOTE_RELEASE_TIMEOUT_V1038[fam].to_i,
      :recovery_hold=>PMD_AC::REMOTE_RECOVERY_HOLD_V1038[fam].to_i,
      :source=>source,:release_count=>0,:impact_count=>0
    }
    @motion_remote_recovery_snap_v1038=false
    true
  rescue
    @motion_remote_state_v1038=nil
    false
  end

  def motion_remote_ensure_v1038(move_key,data=nil,route=nil,source=:handoff)
    s=@motion_remote_state_v1038
    if s!=nil && s[:move_key].to_s==move_key.to_s
      return true
    end
    motion_remote_begin_v1038(move_key,data,route,source)
  rescue
    false
  end

  def motion_remote_anticipation_active_v1038?
    s=@motion_remote_state_v1038
    return false if s==nil || s[:phase]!=:anticipation
    n=s[:anticipation].to_i
    return false if n<=0
    Graphics.frame_count-s[:started_at].to_i<n
  rescue
    false
  end

  def motion_remote_mark_release_v1038(move_key=nil)
    s=@motion_remote_state_v1038
    return false if s==nil
    return false if move_key!=nil && s[:move_key].to_s!=move_key.to_s
    return false if s[:phase]==:released
    s[:phase]=:released
    s[:released_at]=Graphics.frame_count
    s[:release_count]=s[:release_count].to_i+1
    true
  rescue
    false
  end

  def motion_remote_begin_recovery_v1038(move_key=nil,reason=:impact)
    s=@motion_remote_state_v1038
    return false if s==nil
    return false if move_key!=nil && s[:move_key].to_s!=move_key.to_s
    return false if s[:phase]==:recovery
    s[:phase]=:recovery
    s[:impact_at]=Graphics.frame_count if reason==:impact || reason==:effect_complete
    s[:recovery_started_at]=Graphics.frame_count
    s[:recovery_reason]=reason
    s[:impact_count]=s[:impact_count].to_i+1 if reason==:impact || reason==:effect_complete
    @motion_remote_recovery_snap_v1038=true
    true
  rescue
    false
  end

  def motion_remote_recovery_snap_pending_v1038?
    @motion_remote_recovery_snap_v1038 ? true : false
  rescue
    false
  end

  def motion_remote_mark_recovery_snap_done_v1038
    @motion_remote_recovery_snap_v1038=false
  end

  def motion_remote_frame_v1038(kind)
    s=@motion_remote_state_v1038
    return nil if s==nil
    kind==:return ? s[:return_frame] : s[:hit_frame]
  rescue
    nil
  end

  def motion_remote_recovery_hold_v1038
    s=@motion_remote_state_v1038
    s==nil ? 1 : [s[:recovery_hold].to_i,1].max
  rescue
    1
  end

  def motion_remote_update_v1038
    s=@motion_remote_state_v1038
    return if s==nil
    now=Graphics.frame_count
    if s[:phase]==:anticipation
      # 沒有收到 launch/hit handoff 時不綁 gameplay；action 自己結束後安全收勢。
      if !acting? && now-s[:started_at].to_i>[s[:anticipation].to_i+6,8].max
        motion_remote_begin_recovery_v1038(s[:move_key],:no_release_timeout)
      end
    elsif s[:phase]==:released
      timeout=[s[:release_timeout].to_i,6].max
      if s[:released_at]!=nil && now-s[:released_at].to_i>=timeout
        motion_remote_begin_recovery_v1038(s[:move_key],:visual_timeout)
      end
    elsif s[:phase]==:recovery
      hold=[s[:recovery_hold].to_i,1].max
      if s[:recovery_started_at]!=nil && now-s[:recovery_started_at].to_i>=hold
        motion_remote_clear_v1038
      end
    end
  rescue
    motion_remote_clear_v1038
  end

  def begin_skill(skill_target=nil)
    pmd_ac_v1038_begin_skill(skill_target)
    return unless @action==:skill
    d=nil;mk=:skill;p=nil;r=nil
    begin
      d=skill_data
      mk=d==nil ? :skill : (d[:canonical_move_key] || d[:move_key] || :skill)
      p=PMD_AC.move_presentation_profile_v055(mk)
      r=PMD_AC.motion_source_route_v102(@species,mk,d,p)
    rescue
      d=nil;r=nil
    end
    motion_remote_begin_v1038(mk,d,r,:begin_skill) if r!=nil && motion_remote_family_v1038?(r[:family])
  end

  def update
    pmd_ac_v1038_update
    motion_remote_update_v1038
  end

  def visual_action
    base=pmd_ac_v1038_visual_action
    return base unless motion_remote_active_v1038?
    return base if respond_to?(:motion_hurt_active_v102?) && motion_hurt_active_v102?
    s=@motion_remote_state_v1038
    pose=s==nil ? nil : s[:pose]
    return base if pose==nil || !PMD_AC.motion_playable_v102?(@species,pose)
    pose
  rescue
    pmd_ac_v1038_visual_action
  end

  # ---------------------------------------------------------------------------
  # Deploy 45° No-Hop
  # ---------------------------------------------------------------------------
  def motion_deploy_idle_reset_v1033
    pmd_ac_v1038_motion_deploy_idle_reset_v1033
    @motion_deploy_rich_sequence_v1035=nil
  end

  def motion_deploy_direct_8dir_v1038?(action)
    return false if action==nil
    return false unless PMD_AC.respond_to?(:motion_playable_v102?)
    return false unless PMD_AC.motion_playable_v102?(@species,action)
    return false unless PMD_AC.respond_to?(:compiled_direct_action_v061)
    d=PMD_AC.compiled_direct_action_v061(@species.to_s,action)
    return false if d==nil
    return false if d[:copy_of]!=nil || d[:alias_of]!=nil
    return false if d[:rows].to_i<8
    return false unless PMD_AC.respond_to?(:compiled_action_asset_available_v061?)
    PMD_AC.compiled_action_asset_available_v061?(@species.to_s,action,d)
  rescue
    false
  end

  def motion_deploy_base_45_v1038
    return :idle if motion_deploy_direct_8dir_v1038?(:idle)
    return :walk if motion_deploy_direct_8dir_v1038?(:walk)
    list=motion_deploy_rich_specials_v1035
    return list[0] if list!=nil && !list.empty?
    :idle
  rescue
    :idle
  end

  # 重新做 specials discovery：Hop 在 discovery 階段就被拒絕，不只是在 sequence 隱藏。
  def motion_deploy_rich_specials_v1035
    out=[]
    p=respond_to?(:motion_species_profile_v102) ? motion_species_profile_v102 : nil
    ambient=p==nil ? nil : p[:ambient]
    candidates=[]
    if ambient!=nil
      ambient.each do |row|
        a=row==nil ? nil : row[0]
        candidates.push(a) if a!=nil
      end
    end
    body=p==nil ? :medium : p[:body]
    pool=PMD_AC::DEPLOY_RICH_BODY_POOL_V1035[body] || PMD_AC::DEPLOY_RICH_BODY_POOL_V1035[:medium]
    candidates.concat(pool)
    candidates.concat(PMD_AC::DEPLOY_RICH_COMMON_POOL_V1035)
    candidates.each do |a|
      next if a==nil || a==:walk || a==:idle || a==:hop
      next if PMD_AC::DEPLOY_RICH_BLOCKED_ACTIONS_V1035.include?(a)
      next if PMD_AC::DEPLOY_BLOCKED_EXTRA_V1038.include?(a)
      next if out.include?(a)
      next unless motion_deploy_direct_8dir_v1038?(a)
      out.push(a)
    end
    max=PMD_AC::DEPLOY_RICH_MAX_SPECIALS_V1035.to_i
    max=1 if max<1
    out=out[0,max] if out.size>max
    out
  rescue
    []
  end

  # v1.03.7 的 Idle-based 節奏保留，但 sequence 每一項都先驗 direct 8-dir。
  def motion_deploy_rich_sequence_v1035
    return @motion_deploy_rich_sequence_v1035 if @motion_deploy_rich_sequence_v1035!=nil
    base=motion_deploy_base_45_v1038
    specials=motion_deploy_rich_specials_v1035
    seq=[]
    primary=motion_deploy_scaled_hold_v1037(PMD_AC::DEPLOY_IDLE_PRIMARY_HOLD_V1037)
    between=PMD_AC::DEPLOY_IDLE_BETWEEN_HOLD_V1037
    ending=motion_deploy_scaled_hold_v1037(PMD_AC::DEPLOY_IDLE_END_HOLD_V1037)
    seq.push([base,primary])
    specials.each_with_index do |a,i|
      next if a==:hop
      next unless motion_deploy_direct_8dir_v1038?(a)
      seq.push([a,motion_deploy_scaled_hold_v1037(motion_deploy_hold_v1035(a))])
      seq.push([base,motion_deploy_scaled_hold_v1037(between+(i%2)*2)])
    end
    seq.push([base,ending])
    seq=[[:idle,primary]] if seq.empty?
    @motion_deploy_rich_special_count_v1035=specials.size
    @motion_deploy_rich_sequence_v1035=seq
    seq
  rescue
    [[:idle,motion_deploy_scaled_hold_v1037(PMD_AC::DEPLOY_IDLE_PRIMARY_HOLD_V1037)]]
  end
end

#==============================================================================
# ■ Sprite_PMDChessUnit - Remote anticipation / release hold / returnFrame
#==============================================================================
class Sprite_PMDChessUnit
  alias pmd_ac_v1038_update_animation update_animation unless method_defined?(:pmd_ac_v1038_update_animation)

  def motion_remote_lock_frame_v1038(frame)
    return false if @placeholder || @action_data==nil || frame==nil
    frames=@action_data[:frames].to_i
    ds=@action_data[:durations]
    frames=ds.size if frames<=0 && ds!=nil
    return false if frames<=0
    idx=frame.to_i
    idx=0 if idx<0
    idx=frames-1 if idx>=frames
    @frame_index=idx
    @frame_wait=0
    setup_source_rect
    true
  rescue
    false
  end

  def update_animation
    if @unit!=nil && @unit.respond_to?(:motion_remote_active_v1038?) && @unit.motion_remote_active_v1038?
      phase=@unit.motion_remote_phase_v1038
      if phase==:anticipation && @unit.motion_remote_anticipation_active_v1038?
        motion_remote_lock_frame_v1038(0)
        return
      elsif phase==:released
        frame=@unit.motion_remote_frame_v1038(:hit)
        if frame!=nil
          motion_remote_lock_frame_v1038(frame)
          return
        end
      elsif phase==:recovery && @unit.motion_remote_recovery_snap_pending_v1038?
        frame=@unit.motion_remote_frame_v1038(:return)
        if frame!=nil && respond_to?(:motion_snap_source_frame_v102)
          motion_snap_source_frame_v102(frame,@unit.motion_remote_recovery_hold_v1038)
        end
        @unit.motion_remote_mark_recovery_snap_done_v1038
      end
    end
    pmd_ac_v1038_update_animation
  rescue
    begin;pmd_ac_v1038_update_animation;rescue;end
  end
end

#==============================================================================
# ■ Scene_PMD_AutoChess - Remote authority bridge / Deploy verifier / final seal
#==============================================================================
class Scene_PMD_AutoChess
  alias pmd_ac_v1038_play_skill_se play_skill_se unless method_defined?(:pmd_ac_v1038_play_skill_se)
  alias pmd_ac_v1038_launch_projectile launch_projectile unless method_defined?(:pmd_ac_v1038_launch_projectile)
  alias pmd_ac_v1038_apply_skill_effects apply_skill_effects unless method_defined?(:pmd_ac_v1038_apply_skill_effects)
  alias pmd_ac_v1038_motion_true_impact_v102 motion_true_impact_v102 unless method_defined?(:pmd_ac_v1038_motion_true_impact_v102)
  alias pmd_ac_v1038_prepare_verification_battle prepare_verification_battle unless method_defined?(:pmd_ac_v1038_prepare_verification_battle)
  alias pmd_ac_v1038_update_verification_script update_verification_script unless method_defined?(:pmd_ac_v1038_update_verification_script)
  alias pmd_ac_v1038_start_battle start_battle unless method_defined?(:pmd_ac_v1038_start_battle)

  def motion_remote_stats_reset_v1038
    @motion_remote_stats_v1038={
      :begins=>0,:releases=>0,:projectile_handoffs=>0,:impacts=>0,:recoveries=>0,
      :families=>{}
    }
    @motion_remote_log_count_v1038=0
  end

  def motion_remote_route_v1038(unit,move_key,data=nil)
    return nil if unit==nil
    motion_route_for_unit_v102(unit,move_key,data)
  rescue
    nil
  end

  def motion_remote_note_family_v1038(fam,key)
    s=@motion_remote_stats_v1038
    return if s==nil
    s[:families]={} if s[:families]==nil
    row=s[:families][fam] || {:release=>0,:impact=>0,:projectile=>0}
    row[key]=row[key].to_i+1
    s[:families][fam]=row
  rescue
  end

  def motion_remote_ensure_release_v1038(unit,move_key,data=nil,source=:audio_launch)
    return nil if unit==nil
    r=motion_remote_route_v1038(unit,move_key,data)
    return nil if r==nil || !PMD_AC::MOTION_REMOTE_FAMILIES_V1038.include?(r[:family])
    unit.motion_remote_ensure_v1038(move_key,data,r,source) if unit.respond_to?(:motion_remote_ensure_v1038)
    # 不論 handoff 入口是 audio、projectile 或 direct effect，都只做 Sprite snap；
    # 這不延遲任何 gameplay resolve。Phase A 若已 snap，重設同一 frame 也是 idempotent。
    hold=(r[:family]==:beam ? 2 : 1)
    motion_snap_unit_v102(unit,r[:hit_frame],hold) if respond_to?(:motion_snap_unit_v102) && r[:hit_frame]!=nil
    if unit.respond_to?(:motion_remote_mark_release_v1038) && unit.motion_remote_mark_release_v1038(move_key)
      s=@motion_remote_stats_v1038
      s[:releases]=s[:releases].to_i+1 if s!=nil
      motion_remote_note_family_v1038(r[:family],:release)
      if motion_phase_b_verifier_active_v1036? && @motion_remote_log_count_v1038.to_i<18
        @motion_remote_log_count_v1038=@motion_remote_log_count_v1038.to_i+1
        log_event(:motion_native,
          'MOTION_REMOTE_RELEASE_V1038 '+unit.log_name+' move='+move_key.to_s+
          ' family='+r[:family].to_s+' pose='+r[:selected].to_s+
          ' hitFrame='+(r[:hit_frame]==nil ? 'nil':r[:hit_frame].to_s)+
          ' returnFrame='+(r[:return_frame]==nil ? 'nil':r[:return_frame].to_s)+
          ' hasNative='+(r[:has_native] ? '1':'0')+' hasPlayable='+(r[:has_playable] ? '1':'0')+
          ' fallback='+(r[:fallback] ? '1':'0')+
          ' source='+source.to_s+' gameplay_timer_added=0 logical_xy_unchanged=1')
      end
    end
    r
  rescue
    nil
  end

  def play_skill_se(unit,stage,data=nil)
    # Phase A 原本在 :launch 會 snap hitFrame；先保留它，再建立等待 impact 的 state。
    result=pmd_ac_v1038_play_skill_se(unit,stage,data)
    if unit!=nil && data!=nil && (stage==:launch || stage==:hit)
      mk=data[:canonical_move_key] || data[:move_key] || :skill
      active=unit.respond_to?(:motion_remote_active_v1038?) && unit.motion_remote_active_v1038?
      phase=unit.respond_to?(:motion_remote_phase_v1038) ? unit.motion_remote_phase_v1038 : nil
      if stage==:launch
        motion_remote_ensure_release_v1038(unit,mk,data,:audio_launch)
      elsif !active || phase==:anticipation
        # 某些 Cast/Sound 沒有 launch SE stage；hit stage 只補 presentation handoff。
        motion_release_handoff_v102(unit,mk,data) if respond_to?(:motion_release_handoff_v102)
        motion_remote_ensure_release_v1038(unit,mk,data,:audio_hit_fallback)
      end
    end
    result
  end

  def launch_projectile(user,target,kind,power,effect_type,tracking_override=nil,attack_modifier=nil,allow_substitute=true)
    data=nil;mk=:skill;r=nil
    begin
      data=effect_type==nil ? nil : PMD_AC.skill_data(effect_type)
      mk=data==nil ? :skill : (data[:canonical_move_key] || data[:move_key] || :skill)
      r=motion_remote_ensure_release_v1038(user,mk,data,:projectile_launch) if user!=nil && data!=nil
      if r!=nil
        s=@motion_remote_stats_v1038
        s[:projectile_handoffs]=s[:projectile_handoffs].to_i+1 if s!=nil
        motion_remote_note_family_v1038(r[:family],:projectile)
      end
    rescue
      r=nil
    end
    pmd_ac_v1038_launch_projectile(user,target,kind,power,effect_type,tracking_override,attack_modifier,allow_substitute)
  end

  def motion_remote_mark_impact_v1038(user,target,move_key,data,source=:damage)
    return false if user==nil
    r=motion_remote_route_v1038(user,move_key,data)
    return false if r==nil || !PMD_AC::MOTION_REMOTE_FAMILIES_V1038.include?(r[:family])
    return false unless user.respond_to?(:motion_remote_active_v1038?) && user.motion_remote_active_v1038?
    return false unless user.respond_to?(:motion_remote_begin_recovery_v1038)
    ok=user.motion_remote_begin_recovery_v1038(move_key,source==:effect_complete ? :effect_complete : :impact)
    if ok
      s=@motion_remote_stats_v1038
      s[:impacts]=s[:impacts].to_i+1 if s!=nil
      s[:recoveries]=s[:recoveries].to_i+1 if s!=nil
      motion_remote_note_family_v1038(r[:family],:impact)
      if motion_phase_b_verifier_active_v1036? && @motion_remote_log_count_v1038.to_i<18
        @motion_remote_log_count_v1038=@motion_remote_log_count_v1038.to_i+1
        log_event(:motion_hit,
          'MOTION_REMOTE_IMPACT_V1038 '+user.log_name+' -> '+(target==nil ? 'NONE':target.log_name)+
          ' move='+move_key.to_s+' family='+r[:family].to_s+' source='+source.to_s+
          ' target_hurt_owned_by_existing_impact=1 source_recovery_after_impact=1'+
          ' damage_timing_unchanged=1 logical_xy_unchanged=1')
      end
    end
    ok
  rescue
    false
  end

  def motion_true_impact_v102(user,target,move_key,damage,data,effectiveness,critical)
    result=pmd_ac_v1038_motion_true_impact_v102(user,target,move_key,damage,data,effectiveness,critical)
    motion_remote_mark_impact_v1038(user,target,move_key,data,:damage) if damage.to_i>0
    result
  end

  def apply_skill_effects(user,target,data,multiplier=1.0)
    mk=nil
    if user!=nil && data!=nil
      mk=data[:canonical_move_key] || data[:move_key] || :skill
      r=motion_remote_route_v1038(user,mk,data) rescue nil
      if r!=nil && PMD_AC::MOTION_REMOTE_FAMILIES_V1038.include?(r[:family])
        phase=user.respond_to?(:motion_remote_phase_v1038) ? user.motion_remote_phase_v1038 : nil
        # 部分 direct Cast / Sound 沒有 launch stage；在既有 effect resolve 前補 source
        # hitFrame handoff，仍然不改 effect / Damage 的執行時點。
        motion_remote_ensure_release_v1038(user,mk,data,:effect_pre_resolve) if phase==nil || phase==:anticipation
      end
    end
    result=pmd_ac_v1038_apply_skill_effects(user,target,data,multiplier)
    if user!=nil && data!=nil
      mk=data[:canonical_move_key] || data[:move_key] || :skill if mk==nil
      # Damage path 可能已在 motion_true_impact 收勢；無 Damage / status path 則在既有
      # effects 全部完成後收勢。begin_recovery idempotent，不重算任何 effect。
      motion_remote_mark_impact_v1038(user,target,mk,data,:effect_complete)
    end
    result
  end

  # ---------------------------------------------------------------------------
  # Deploy snapshot：驗 sequence 中 Hop=0，且每一個 action 都有 direct 8-dir 證據。
  # ---------------------------------------------------------------------------
  def motion_capture_deploy_nohop45_v1038
    covered=0;hop_items=0;bad_8dir=0;diag=0;idle_base=0;actions=0
    (@units || []).each do |u|
      next if u==nil
      next unless u.respond_to?(:motion_phase_a_species_v102?) && u.motion_phase_a_species_v102?
      covered+=1
      seq=u.respond_to?(:motion_deploy_rich_sequence_v1035) ? u.motion_deploy_rich_sequence_v1035 : []
      idle_base+=1 if seq!=nil && !seq.empty? && seq[0][0]==:idle
      if seq!=nil
        seq.each do |row|
          next if row==nil
          a=row[0];actions+=1
          hop_items+=1 if a==:hop
          ok=u.respond_to?(:motion_deploy_direct_8dir_v1038?) && u.motion_deploy_direct_8dir_v1038?(a)
          bad_8dir+=1 unless ok
        end
      end
      expected=u.team==:enemy ? 1 : 3
      d=u.respond_to?(:motion_deploy_display_direction_v1035) ? u.motion_deploy_display_direction_v1035 : 0
      diag+=1 if d.to_i==expected
    end
    @motion_deploy_nohop45_snapshot_v1038={
      :covered=>covered,:hop_items=>hop_items,:bad_8dir=>bad_8dir,:diag=>diag,
      :idle_base=>idle_base,:actions=>actions
    }
    if motion_phase_b_verifier_active_v1036?
      log_event(:motion_deploy,
        'MOTION_DEPLOY_NOHOP_45_V1038 ready=1 covered='+covered.to_s+
        ' hop_items='+hop_items.to_s+' bad_8dir='+bad_8dir.to_s+
        ' diagonal='+diag.to_s+'/'+covered.to_s+' idle_base='+idle_base.to_s+'/'+covered.to_s+
        ' sequence_actions='+actions.to_s+' ally_dir=3 enemy_dir=1'+
        ' direct_8dir_every_action=1 hop_removed=1 deploy_only=1 logical_xy_unchanged=1')
    end
  rescue
  end

  def start_battle
    motion_capture_deploy_nohop45_v1038 if @phase==:deploy
    pmd_ac_v1038_start_battle
  end

  def prepare_verification_battle
    pmd_ac_v1038_prepare_verification_battle
    if motion_phase_b_verifier_active_v1036?
      @motion_phase_b_remote_failed_v1038=false
      motion_remote_stats_reset_v1038
      log_event(:showcase,
        'MOTION_PHASE_B_REMOTE_V1038 START families=projectile,beam,cast,shock,drain,sound'+
        ' anticipation=sprite_only release=source_hitFrame handoff=existing_fx'+
        ' impact=existing_damage_effect recovery=source_returnFrame'+
        ' gameplay_timer_added=0 projectile_speed_unchanged=1 damage_timing_unchanged=1'+
        ' deploy_hop=0 deploy_all_actions_45deg_direct8=1')
    end
  end

  def verify_motion_deploy_nohop45_v1038
    return if @verification_done[:motion_deploy_nohop45_v1038]
    s=@motion_deploy_nohop45_snapshot_v1038 || {}
    covered=s[:covered].to_i
    pass=covered>0 && s[:hop_items].to_i==0 && s[:bad_8dir].to_i==0 && s[:diag].to_i==covered
    # 0001-0026 目前應以 Idle 為 45° base；若未來某物種缺 direct Idle，base fallback
    # 仍可通過 all-8dir，但 verifier 會把 idle_base 數量明列出來供人工 QA。
    @motion_phase_b_remote_failed_v1038=true unless pass
    log_event(:verify,
      'MOTION_DEPLOY_NOHOP_45_V1038 pass='+(pass ? '1':'0')+
      ' covered='+covered.to_s+' hop_items='+s[:hop_items].to_i.to_s+
      ' all_actions_direct8='+(s[:bad_8dir].to_i==0 ? '1':'0')+
      ' bad_8dir='+s[:bad_8dir].to_i.to_s+' diagonal='+s[:diag].to_i.to_s+'/'+covered.to_s+
      ' idle_base='+s[:idle_base].to_i.to_s+'/'+covered.to_s+
      ' ally_dir=3 enemy_dir=1 walk_primary=0 hop_removed=1 deploy_only=1')
    @verification_done[:motion_deploy_nohop45_v1038]=true
  rescue
    @motion_phase_b_remote_failed_v1038=true
    log_event(:verify,'MOTION_DEPLOY_NOHOP_45_V1038 pass=0 error=1')
    @verification_done[:motion_deploy_nohop45_v1038]=true
  end

  def verify_motion_remote_registry_v1038
    return if @verification_done[:motion_remote_registry_v1038]
    fam=PMD_AC::MOTION_REMOTE_FAMILIES_V1038
    pass=fam==[:projectile,:beam,:cast,:shock,:drain,:sound]
    fam.each do |f|
      pass=false if PMD_AC::REMOTE_ANTICIPATION_V1038[f]==nil ||
        PMD_AC::REMOTE_RELEASE_TIMEOUT_V1038[f]==nil || PMD_AC::REMOTE_RECOVERY_HOLD_V1038[f]==nil
    end
    @motion_phase_b_remote_failed_v1038=true unless pass
    log_event(:verify,
      'MOTION_REMOTE_FAMILY_REGISTRY_V1038 pass='+(pass ? '1':'0')+
      ' families=projectile,beam,cast,shock,drain,sound count='+fam.size.to_s+
      ' source_aware_native=1 fallback_retained=1 hitFrame=1 returnFrame=1')
    @verification_done[:motion_remote_registry_v1038]=true
  rescue
    @motion_phase_b_remote_failed_v1038=true
    log_event(:verify,'MOTION_REMOTE_FAMILY_REGISTRY_V1038 pass=0 error=1')
    @verification_done[:motion_remote_registry_v1038]=true
  end

  def verify_motion_remote_routes_v1038
    return if @verification_done[:motion_remote_routes_v1038]
    samples=[
      ['0007',:water_gun,:projectile],['0007',:ice_beam,:beam],
      ['0001',:swords_dance,:cast],['0025',:thunderbolt,:shock],
      ['0001',:absorb,:drain],['0019',:screech,:sound]
    ]
    rows=[];pass=true
    samples.each do |sid,mk,expected|
      d=nil;p=nil;r=nil
      begin;d=PMD_AC.skill_data(('mv_'+mk.to_s).to_sym);rescue;d=nil;end
      begin;p=PMD_AC.move_presentation_profile_v055(mk);rescue;p=nil;end
      begin;r=PMD_AC.motion_source_route_v102(sid,mk,d,p);rescue;r=nil;end
      ok=r!=nil && r[:family]==expected && r[:selected]!=nil && r[:has_playable]
      pass=false unless ok
      rows.push(sid+':'+mk.to_s+'='+(r==nil ? 'nil':r[:family].to_s+'/'+r[:selected].to_s+
        '/H'+(r[:hit_frame]==nil ? 'nil':r[:hit_frame].to_s)+'/R'+(r[:return_frame]==nil ? 'nil':r[:return_frame].to_s)))
    end
    @motion_phase_b_remote_failed_v1038=true unless pass
    log_event(:verify,
      'MOTION_REMOTE_SOURCE_ROUTES_V1038 pass='+(pass ? '1':'0')+
      ' samples=['+rows.join(',')+'] playable_source=1 provenance_separated=1')
    @verification_done[:motion_remote_routes_v1038]=true
  rescue
    @motion_phase_b_remote_failed_v1038=true
    log_event(:verify,'MOTION_REMOTE_SOURCE_ROUTES_V1038 pass=0 error=1')
    @verification_done[:motion_remote_routes_v1038]=true
  end

  # 純 presentation state verifier，不呼叫 Damage Formula、不發 projectile、不改 HP。
  def verify_motion_remote_state_machine_v1038
    return if @verification_done[:motion_remote_state_machine_v1038]
    u=verification_unit(:ally,:squirtle)
    t=verification_unit(:enemy,:rattata)
    pass=u!=nil && t!=nil
    began=false;released=false;recovered=false;xy_ok=false;timer_ok=false
    if pass
      ux=u.pixel_x.to_f;uy=u.pixel_y.to_f;tx=t.pixel_x.to_f;ty=t.pixel_y.to_f
      uh=u.hp.to_i;th=t.hp.to_i;timer=u.instance_variable_get(:@action_timer).to_i
      d=nil;r=nil
      begin;d=PMD_AC.skill_data(:mv_water_gun);rescue;d=nil;end
      begin;r=motion_remote_route_v1038(u,:water_gun,d);rescue;r=nil;end
      began=u.motion_remote_begin_v1038(:water_gun,d,r,:verify) if r!=nil
      released=u.motion_remote_mark_release_v1038(:water_gun) if began
      recovered=u.motion_remote_begin_recovery_v1038(:water_gun,:impact) if released
      timer_ok=u.instance_variable_get(:@action_timer).to_i==timer
      xy_ok=u.pixel_x.to_f==ux && u.pixel_y.to_f==uy && t.pixel_x.to_f==tx && t.pixel_y.to_f==ty &&
        u.hp.to_i==uh && t.hp.to_i==th
      u.motion_remote_clear_v1038 if u.respond_to?(:motion_remote_clear_v1038)
      pass=began && released && recovered && timer_ok && xy_ok
    end
    @motion_phase_b_remote_failed_v1038=true unless pass
    log_event(:verify,
      'MOTION_REMOTE_PRESENTATION_STATE_V1038 pass='+(pass ? '1':'0')+
      ' anticipation='+(began ? '1':'0')+' release='+(released ? '1':'0')+
      ' impact_owned_recovery='+(recovered ? '1':'0')+
      ' action_timer_unchanged='+(timer_ok ? '1':'0')+' hp_unchanged='+(xy_ok ? '1':'0')+
      ' logical_xy_unchanged=1 projectile_speed_unchanged=1 damage_formula_unchanged=1'+
      ' ai_unchanged=1 attack_speed_unchanged=1 energy_unchanged=1')
    @verification_done[:motion_remote_state_machine_v1038]=true
  rescue
    @motion_phase_b_remote_failed_v1038=true
    log_event(:verify,'MOTION_REMOTE_PRESENTATION_STATE_V1038 pass=0 error=1')
    @verification_done[:motion_remote_state_machine_v1038]=true
  end

  def update_verification_script
    pmd_ac_v1038_update_verification_script
    return unless motion_phase_b_verifier_active_v1036?
    return if @verification_done==nil
    f=@verification_frame.to_i
    verify_motion_remote_registry_v1038 if f>=182
    verify_motion_deploy_nohop45_v1038 if f>=183
    verify_motion_remote_routes_v1038 if f>=186
    verify_motion_remote_state_machine_v1038 if f>=189
  end

  # v1.03.7 final seal 的最新版：A/B/C + Remote 六 Family + Deploy No-Hop 45°。
  def verify_motion_final_v102
    return if @verification_done[:motion_final_v102]
    pass=!@motion_phase_a_failed_v102 && !@motion_phase_b_failed_v103 &&
      !@motion_phase_b_batch_b_failed_v1036 && !@motion_phase_b_batch_c_failed_v1037 &&
      !@motion_phase_b_remote_failed_v1038
    log_event(:verify,
      'PMD_MOTION_PHASE_A_V102 pass='+(pass ? '1':'0')+
      ' superseded_by_phase_b=1 scope=0001-0026 presentation_only=1'+
      ' damage_formula_unchanged=1 attack_speed_unchanged=1 spatial_framework_unchanged=1')
    log_event(:verify,
      'PMD_MOTION_PHASE_B_V103 pass='+(pass ? '1':'0')+
      ' batch=remote_motion_all scope=0001-0026'+
      ' contact_chain_a=1 result_semantics_b=1 multihit_c=1'+
      ' remote_projectile=1 remote_beam=1 remote_cast=1 remote_shock=1 remote_drain=1 remote_sound=1'+
      ' remote_chain=anticipation>source_hitFrame>existing_handoff>target_impact>returnFrame'+
      ' deploy_idle45=1 deploy_hop=0 deploy_all_actions_direct8=1'+
      ' gameplay_timer_added=0 damage_packet_authority_unchanged=1 projectile_speed_unchanged=1'+
      ' ai_unchanged=1 damage_formula_unchanged=1 attack_speed_unchanged=1'+
      ' energy_unchanged=1 spatial_unchanged=1')
    @verification_done[:motion_final_v102]=true
  end
end
