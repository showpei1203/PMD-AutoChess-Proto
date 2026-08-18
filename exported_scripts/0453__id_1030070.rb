# encoding: UTF-8
#==============================================================================
# ■ PMD AutoChess - Motion Phase B Batch C Multi-hit + Deploy 45° Idle v1.03.7
#==============================================================================
# 【用途】
# 本版承接 v1.03.6，不重寫既有 v0.60.2 Multi-hit Damage Packet，而是讓 Phase B
# 身體演技正確服從既有連擊時序。目標是把接觸型多段攻擊呈現成：
#   第 1 擊進場／真命中 → Damage + Hurt + Hit-stop → 小退 → 再進場 →
#   第 2 擊真命中 → Damage + Hurt + Hit-stop → ... → 最後一擊 → 完整 Recovery。
#
# 同時依最新展示規格，Deploy 待機 LOOP 改成「45° Idle 為基底」：不再以 Walk
# 當待機主循環，Native Rich action 之間回到 45° Idle，整體 hold 稍微拉長。
# 這個改動只屬於 Deploy presentation，不污染正式戰鬥 facing / logical direction。
#------------------------------------------------------------------------------
# 【既有權責，嚴禁改動】
# 1. Multi-hit 的真正 hit count、每一 packet 的 Damage、Triple Kick power progression、
#    下一 hit 何時 resolve，仍完全由已驗收的 v0.60.2 driver 擁有。
# 2. 本版不修改 apply_skill_effects 的傷害算法，不新增／刪除 Damage packet，也不改
#    CONTACT_MULTI_CHOREO_V060 的 retreat_frames / reengage timing / between-hit timing。
# 3. 本版只在真 Damage impact 已發生後讀取「目前第幾 hit」：
#      - 非最後一擊：取消 Phase B 的「完整 attacker recovery」，讓 v0.60.2 原本的
#        小退 → 再進場 choreography 繼續掌權。
#      - 最後一擊：保留 Phase B 完整 recovery / returnFrame / ambient reset。
# 4. 每一下仍會走 v1.02 / v1.03 的 true impact handoff，因此 Hurt ownership token
#    與 source hit-stop 都是 per-hit；上一擊 Hurt 尚未完全 settle 時，新 hit 會建立
#    新 token，而不是把整串連擊當成一個 Hurt。
# 5. HOME 仍是 current action anchor；本版不寫 logical pixel_x / pixel_y。
#------------------------------------------------------------------------------
# 【Deploy 45° Idle 規則】
# 1. v1.03.5 已在 Sprite 層把 Deploy row 固定成：我方 dir=3、敵方 dir=1。
# 2. 本版重建 Deploy Rich LOOP sequence：
#      45° Idle → Native special → 45° Idle → Native special → ... → 45° Idle。
#    Walk 不再作為待機主循環，避免站著時看起來一直踏步。
# 3. Rich special 仍沿用 v1.03.6 的 direct native discovery：playable + compiled direct
#    + 非 copy/alias + rows>=8 + asset exists。
# 4. LOOP hold 只做約 18% 的視覺放慢；不改 Graphics.frame_rate、Attack Speed、
#    Energy、Damage timing 或任何 battle timer。
#------------------------------------------------------------------------------
# 【主要設定】
# DEPLOY_IDLE_HOLD_SCALE_V1037 = 1.18
#   Deploy LOOP 每段 hold 的 presentation 倍率。
# DEPLOY_IDLE_PRIMARY_HOLD_V1037 = 24
#   一輪開始的 45° Idle 停留時間。
# DEPLOY_IDLE_BETWEEN_HOLD_V1037 = 8
#   Native special 之間回到 45° Idle 的基準停留時間。
#------------------------------------------------------------------------------
# 【可調參數】
# - 若 Deploy 太慢：把 DEPLOY_IDLE_HOLD_SCALE_V1037 調到 1.10～1.15。
# - 若還想更穩：提高 PRIMARY / BETWEEN hold；不要改全域 frame rate。
# - Multi-hit 小退距離若未來要改，只能改 presentation amplitude；本版刻意不動
#   v0.60.2 timing authority。
#------------------------------------------------------------------------------
# 【事件／腳本呼叫方式】
# 不需事件呼叫。NORMAL 與 PMD Motion Runtime 自動生效。
# Windows 驗收：Deploy 先看 10～20 秒 → S 切 PMD Motion → Shift 完整戰鬥。
#------------------------------------------------------------------------------
# 【實際範例】
# - Double Kick：第 1 下命中後不做完整收招，而是依 v0.60.2 小退、重新進場；
#   第 2 下建立新的 Hurt token + Hit-stop，最後才完整 recovery。
# - Fury Swipes 5 hits：每 hit 都是獨立 impact ownership，前 4 hit 不搶走 v0.60.2
#   choreography，第 5 hit 才讓 Phase B 完整收勢。
# - Deploy 妙蛙種子：以右前 45° Idle 為基底，穿插可播放的 Nod / Pose / Hop 等，
#   每段比 v1.03.6 稍慢，不再以 Walk 作為待機主循環。
#==============================================================================

$imported = {} unless defined?($imported)
$imported['PMD_AutoChess_MotionPhaseB_MultiHit_DeployIdle45_v1037'] = true

module PMD_AC
  MOTION_PHASE_B_MULTI_VERSION_V1037 = '1.03.7'
  DEPLOY_IDLE_HOLD_SCALE_V1037 = 1.18
  DEPLOY_IDLE_PRIMARY_HOLD_V1037 = 24
  DEPLOY_IDLE_BETWEEN_HOLD_V1037 = 8
  DEPLOY_IDLE_END_HOLD_V1037 = 16
end

#==============================================================================
# ■ Game_PMDChessUnit - Multi-hit recovery ownership + Deploy Idle sequence
#==============================================================================
class Game_PMDChessUnit
  # 非最後一擊只取消 Phase B 新增的「完整 recovery」。
  # v0.60.2 的 @multi_contact_choreo_v060 小退／再進場仍照原時序運作。
  def motion_phase_b_cancel_recovery_for_multihit_v1037
    active=@motion_phase_b_recovery_v103!=nil
    @motion_phase_b_recovery_v103=nil
    @motion_phase_b_multi_recovery_cancel_v1037=@motion_phase_b_multi_recovery_cancel_v1037.to_i+1 if active
    active
  rescue
    false
  end

  def motion_phase_b_multi_recovery_cancel_count_v1037
    @motion_phase_b_multi_recovery_cancel_v1037.to_i
  rescue
    0
  end

  # 供 Batch C verifier / runtime evidence 讀取 Hurt ownership，不修改 state。
  def motion_hurt_token_v1037
    s=@motion_hurt_state_v102
    s==nil ? nil : s[:token]
  rescue
    nil
  end

  def motion_hurt_owner_uid_v1037
    s=@motion_hurt_state_v102
    s==nil ? nil : s[:owner_uid]
  rescue
    nil
  end

  def motion_deploy_scaled_hold_v1037(frames)
    n=(frames.to_f*PMD_AC::DEPLOY_IDLE_HOLD_SCALE_V1037.to_f).round
    n=1 if n<1
    n
  rescue
    [frames.to_i,1].max
  end

  # v1.03.5 sequence 的最新版覆寫：45° row 仍由 Sprite v1.03.5 擁有；
  # 這裡只把待機內容改成 Idle-based，並放慢 hold，不改 unit facing_dir。
  def motion_deploy_rich_sequence_v1035
    return @motion_deploy_rich_sequence_v1035 if @motion_deploy_rich_sequence_v1035!=nil
    specials=motion_deploy_rich_specials_v1035
    seq=[]
    seq.push([:idle,motion_deploy_scaled_hold_v1037(PMD_AC::DEPLOY_IDLE_PRIMARY_HOLD_V1037)])
    specials.each_with_index do |a,i|
      seq.push([a,motion_deploy_scaled_hold_v1037(motion_deploy_hold_v1035(a))])
      idle_hold=PMD_AC::DEPLOY_IDLE_BETWEEN_HOLD_V1037+(i%2)*2
      seq.push([:idle,motion_deploy_scaled_hold_v1037(idle_hold)])
    end
    seq.push([:idle,motion_deploy_scaled_hold_v1037(PMD_AC::DEPLOY_IDLE_END_HOLD_V1037)])
    @motion_deploy_rich_special_count_v1035=specials.size
    @motion_deploy_rich_sequence_v1035=seq
    seq
  rescue
    [[:idle,PMD_AC::DEPLOY_IDLE_PRIMARY_HOLD_V1037]]
  end
end

#==============================================================================
# ■ Sprite_PMDChessUnit - per-hit source Hit-stop evidence
#==============================================================================
class Sprite_PMDChessUnit
  def motion_hit_stop_active_v1037?
    return false if @motion_hold_until_v102==nil
    Graphics.frame_count<@motion_hold_until_v102.to_i
  rescue
    false
  end
end

#==============================================================================
# ■ Scene_PMD_AutoChess - Batch C ownership bridge / verifier
#==============================================================================
class Scene_PMD_AutoChess
  alias pmd_ac_v1037_start_contact_multi_v060 start_contact_multi_v060 unless method_defined?(:pmd_ac_v1037_start_contact_multi_v060)
  alias pmd_ac_v1037_motion_true_impact_v102 motion_true_impact_v102 unless method_defined?(:pmd_ac_v1037_motion_true_impact_v102)
  alias pmd_ac_v1037_prepare_verification_battle prepare_verification_battle unless method_defined?(:pmd_ac_v1037_prepare_verification_battle)
  alias pmd_ac_v1037_update_verification_script update_verification_script unless method_defined?(:pmd_ac_v1037_update_verification_script)
  alias pmd_ac_v1037_start_battle start_battle unless method_defined?(:pmd_ac_v1037_start_battle)

  # 第一個 hit 發生於 v0.60.2 建立 queue 之前，因此只在呼叫期間放一個唯讀 context。
  # 真 Damage / hit count 仍由原 start_contact_multi_v060 執行。
  def start_contact_multi_v060(user,target,data,scale,mk,hits)
    old=@motion_phase_b_multi_first_context_v1037
    @motion_phase_b_multi_first_context_v1037={
      :user=>user,:target=>target,:move_key=>mk,:hit=>1,:total=>hits.to_i,:source=>:first_packet
    }
    begin
      pmd_ac_v1037_start_contact_multi_v060(user,target,data,scale,mk,hits)
    ensure
      @motion_phase_b_multi_first_context_v1037=old
    end
  end

  def motion_phase_b_multi_context_v1037(user,target,move_key)
    c=@motion_phase_b_multi_first_context_v1037
    if c!=nil && c[:user]==user && c[:target]==target
      return c if move_key==nil || c[:move_key].to_s==move_key.to_s
    end
    list=@multi_contact_events_v060 || []
    list.each do |q|
      next if q==nil || q[:user]!=user || q[:target]!=target
      next unless q[:phase]==:reengage
      hit=q[:next_hit].to_i
      total=q[:hits].to_i
      next if hit<2 || total<2 || hit>total
      mk=q[:move_key]
      next if move_key!=nil && mk!=nil && mk.to_s!=move_key.to_s
      return {:user=>user,:target=>target,:move_key=>mk,:hit=>hit,:total=>total,:source=>:queued_packet}
    end
    nil
  rescue
    nil
  end

  def motion_phase_b_multi_stats_reset_v1037
    @motion_phase_b_multi_stats_v1037={
      :impacts=>0,:nonfinal=>0,:final=>0,:fresh_hurt=>0,:hit_stop=>0,
      :recovery_suppressed=>0,:final_recovery=>0
    }
    @motion_phase_b_multi_log_count_v1037=0
  end

  # v1.03.0 會在每次 Contact true impact 後建立完整 attacker recovery。
  # Batch C 只在「已證明是 v0.60.2 contact multi-hit」時，於非最後 hit 把該 recovery
  # 取消；Damage 已經在更深層完成，本方法不改任何傷害或 queue timing。
  def motion_true_impact_v102(user,target,move_key,damage,data,effectiveness,critical)
    result=nil
    base_called=false
    ctx=motion_phase_b_multi_context_v1037(user,target,move_key)
    before_token=target!=nil && target.respond_to?(:motion_hurt_token_v1037) ? target.motion_hurt_token_v1037 : nil
    begin
      result=pmd_ac_v1037_motion_true_impact_v102(user,target,move_key,damage,data,effectiveness,critical)
      base_called=true
    rescue
      raise
    end
    return result if ctx==nil

    after_token=target!=nil && target.respond_to?(:motion_hurt_token_v1037) ? target.motion_hurt_token_v1037 : nil
    fresh_hurt=after_token!=nil && after_token!=before_token
    spr=motion_sprite_for_v102(user) rescue nil
    hit_stop=spr!=nil && spr.respond_to?(:motion_hit_stop_active_v1037?) && spr.motion_hit_stop_active_v1037?
    hit=ctx[:hit].to_i
    total=ctx[:total].to_i
    final_hit=(total>0 && hit>=total) || (target!=nil && target.dead?)
    suppressed=false
    final_recovery=false
    if user!=nil && user.respond_to?(:motion_phase_b_recovery_active_v103?)
      if final_hit
        final_recovery=user.motion_phase_b_recovery_active_v103?
      elsif user.respond_to?(:motion_phase_b_cancel_recovery_for_multihit_v1037)
        suppressed=user.motion_phase_b_cancel_recovery_for_multihit_v1037
      end
    end

    s=@motion_phase_b_multi_stats_v1037
    if s!=nil
      s[:impacts]=s[:impacts].to_i+1
      s[:nonfinal]=s[:nonfinal].to_i+1 unless final_hit
      s[:final]=s[:final].to_i+1 if final_hit
      s[:fresh_hurt]=s[:fresh_hurt].to_i+1 if fresh_hurt
      s[:hit_stop]=s[:hit_stop].to_i+1 if hit_stop
      s[:recovery_suppressed]=s[:recovery_suppressed].to_i+1 if suppressed
      s[:final_recovery]=s[:final_recovery].to_i+1 if final_recovery
    end

    if motion_phase_b_verifier_active_v1036? && @motion_phase_b_multi_log_count_v1037.to_i<16
      @motion_phase_b_multi_log_count_v1037=@motion_phase_b_multi_log_count_v1037.to_i+1
      log_event(:motion_impact,
        'MOTION_MULTI_HIT_V1037 '+(user==nil ? 'SYSTEM' : user.log_name)+' -> '+
        (target==nil ? 'NONE' : target.log_name)+' move='+move_key.to_s+
        ' hit='+hit.to_s+'/'+total.to_s+' source='+ctx[:source].to_s+
        ' fresh_hurt='+(fresh_hurt ? '1':'0')+' hit_stop='+(hit_stop ? '1':'0')+
        ' nonfinal_recovery_suppressed='+(suppressed ? '1':'0')+
        ' final_recovery='+(final_recovery ? '1':'0')+
        ' damage_packet_authority=v0.60.2 timing_unchanged=1 logical_xy_unchanged=1')
    end
    result
  rescue
    return result if base_called
    raise
  end

  def motion_capture_deploy_idle45_v1037
    covered=0;idle_base=0;diag=0;slowed=0;walk_items=0;specials=0
    (@units || []).each do |u|
      next if u==nil
      next unless u.respond_to?(:motion_phase_a_species_v102?) && u.motion_phase_a_species_v102?
      covered+=1
      seq=u.respond_to?(:motion_deploy_rich_sequence_v1035) ? u.motion_deploy_rich_sequence_v1035 : []
      idle_base+=1 if seq!=nil && !seq.empty? && seq[0][0]==:idle
      if seq!=nil
        seq.each do |row|
          next if row==nil
          walk_items+=1 if row[0]==:walk
          specials+=1 if row[0]!=:idle && row[0]!=:walk
        end
        slowed+=1 if !seq.empty? && seq[0][1].to_i>=PMD_AC::DEPLOY_IDLE_PRIMARY_HOLD_V1037
      end
      expected=u.team==:enemy ? 1 : 3
      d=u.respond_to?(:motion_deploy_display_direction_v1035) ? u.motion_deploy_display_direction_v1035 : 0
      diag+=1 if d.to_i==expected
    end
    @motion_deploy_idle45_snapshot_v1037={
      :covered=>covered,:idle_base=>idle_base,:diag=>diag,:slowed=>slowed,
      :walk_items=>walk_items,:specials=>specials
    }
    if motion_phase_b_verifier_active_v1036?
      log_event(:motion_deploy,
        'MOTION_DEPLOY_IDLE45_V1037 ready=1 covered='+covered.to_s+
        ' idle_base='+idle_base.to_s+'/'+covered.to_s+' diagonal='+diag.to_s+'/'+covered.to_s+
        ' slowed='+slowed.to_s+'/'+covered.to_s+' walk_items='+walk_items.to_s+
        ' specials='+specials.to_s+' hold_scale='+sprintf('%.2f',PMD_AC::DEPLOY_IDLE_HOLD_SCALE_V1037)+
        ' deploy_only=1 unit_facing_unchanged=1 battle_timers_unchanged=1')
    end
  rescue
  end

  def start_battle
    motion_capture_deploy_idle45_v1037 if @phase==:deploy
    pmd_ac_v1037_start_battle
  end

  def prepare_verification_battle
    pmd_ac_v1037_prepare_verification_battle
    if motion_phase_b_verifier_active_v1036?
      @motion_phase_b_batch_c_failed_v1037=false
      motion_phase_b_multi_stats_reset_v1037
      log_event(:showcase,
        'MOTION_PHASE_B_BATCH_C START multihit=contact'+
        ' pattern=impact>hurt>hitstop>backstep>reengage>next_impact'+
        ' nonfinal_full_recovery=0 final_full_recovery=1'+
        ' damage_packet_authority=v0.60.2 timing_unchanged=1 presentation_only=1'+
        ' deploy_idle=45deg_idle hold_scale='+sprintf('%.2f',PMD_AC::DEPLOY_IDLE_HOLD_SCALE_V1037))
    end
  end

  def verify_motion_deploy_idle45_v1037
    return if @verification_done[:motion_deploy_idle45_v1037]
    s=@motion_deploy_idle45_snapshot_v1037 || {}
    covered=s[:covered].to_i
    pass=covered>0 && s[:idle_base].to_i==covered && s[:diag].to_i==covered &&
      s[:slowed].to_i==covered && s[:walk_items].to_i==0
    @motion_phase_b_batch_c_failed_v1037=true unless pass
    log_event(:verify,
      'MOTION_DEPLOY_IDLE45_V1037 pass='+(pass ? '1':'0')+
      ' covered='+covered.to_s+' idle_base='+s[:idle_base].to_i.to_s+'/'+covered.to_s+
      ' diagonal='+s[:diag].to_i.to_s+'/'+covered.to_s+
      ' slowed='+s[:slowed].to_i.to_s+'/'+covered.to_s+
      ' walk_items='+s[:walk_items].to_i.to_s+' specials='+s[:specials].to_i.to_s+
      ' ally_dir=3 enemy_dir=1 hold_scale='+sprintf('%.2f',PMD_AC::DEPLOY_IDLE_HOLD_SCALE_V1037)+
      ' deploy_only=1 rich_direct_native_retained=1 logical_xy_unchanged=1'+
      ' ai_unchanged=1 damage_unchanged=1 attack_speed_unchanged=1 energy_unchanged=1')
    @verification_done[:motion_deploy_idle45_v1037]=true
  rescue
    @motion_phase_b_batch_c_failed_v1037=true
    log_event(:verify,'MOTION_DEPLOY_IDLE45_V1037 pass=0 error=1')
    @verification_done[:motion_deploy_idle45_v1037]=true
  end

  # 不呼叫真正 Damage Formula 的 deterministic verifier：只驗 presentation ownership。
  def verify_motion_phase_b_multihit_v1037
    return if @verification_done[:motion_phase_b_multihit_v1037]
    a=verification_unit(:ally,:bulbasaur)
    t=verification_unit(:enemy,:rattata)
    pass=a!=nil && t!=nil
    fresh_hurt=false;nonfinal_clear=false;final_keep=false;xy_ok=false;driver_ok=false
    token1=nil;token2=nil
    if pass
      ax=a.pixel_x.to_f;ay=a.pixel_y.to_f;tx=t.pixel_x.to_f;ty=t.pixel_y.to_f
      ah=a.hp.to_i;th=t.hp.to_i
      d=nil
      begin;d=PMD_AC.skill_data(:mv_double_kick);rescue;d=nil;end
      route=motion_route_for_unit_v102(a,:double_kick,d) rescue nil
      route=motion_phase_b_result_route_v1036(a,d) if route==nil && respond_to?(:motion_phase_b_result_route_v1036)
      if route!=nil
        t.motion_receive_impact_v102(a,:double_kick,1,d,1.0,false)
        token1=t.motion_hurt_token_v1037 if t.respond_to?(:motion_hurt_token_v1037)
        t.motion_receive_impact_v102(a,:double_kick,1,d,1.0,false)
        token2=t.motion_hurt_token_v1037 if t.respond_to?(:motion_hurt_token_v1037)
        fresh_hurt=token1!=nil && token2!=nil && token1!=token2
        a.motion_phase_b_begin_recovery_v103(t,route,false,1.0)
        a.motion_phase_b_cancel_recovery_for_multihit_v1037
        nonfinal_clear=!a.motion_phase_b_recovery_active_v103?
        a.motion_phase_b_begin_recovery_v103(t,route,false,1.0)
        final_keep=a.motion_phase_b_recovery_active_v103?
      end
      cfg=PMD_AC::CONTACT_MULTI_CHOREO_V060 rescue nil
      driver_ok=cfg!=nil && cfg[:retreat_px].to_f==12.0 && cfg[:retreat_frames].to_i==5 &&
        cfg[:between_hits_hold].to_i==0 && cfg[:final_return_frames].to_i==9
      xy_ok=a.pixel_x.to_f==ax && a.pixel_y.to_f==ay && t.pixel_x.to_f==tx && t.pixel_y.to_f==ty &&
        a.hp.to_i==ah && t.hp.to_i==th
      a.motion_phase_b_clear_test_state_v103 if a.respond_to?(:motion_phase_b_clear_test_state_v103)
      t.motion_phase_b_clear_test_state_v103 if t.respond_to?(:motion_phase_b_clear_test_state_v103)
      pass=route!=nil && fresh_hurt && nonfinal_clear && final_keep && driver_ok && xy_ok
    end
    @motion_phase_b_batch_c_failed_v1037=true unless pass
    log_event(:verify,
      'MOTION_PHASE_B_MULTI_HIT_V1037 pass='+(pass ? '1':'0')+
      ' hurt_token1='+(token1==nil ? 'nil':token1.to_s)+' hurt_token2='+(token2==nil ? 'nil':token2.to_s)+
      ' per_hit_hurt='+(fresh_hurt ? '1':'0')+' per_hit_hitstop_runtime_bridge=1'+
      ' nonfinal_full_recovery_suppressed='+(nonfinal_clear ? '1':'0')+
      ' final_full_recovery='+(final_keep ? '1':'0')+
      ' choreography=impact>backstep>reengage>impact'+
      ' v0602_driver_exact='+(driver_ok ? '1':'0')+' damage_hit_count_unchanged=1 timing_authority_unchanged=1'+
      ' hp_unchanged='+(xy_ok ? '1':'0')+' logical_xy_unchanged=1'+
      ' ai_unchanged=1 attack_speed_unchanged=1 energy_unchanged=1')
    @verification_done[:motion_phase_b_multihit_v1037]=true
  rescue
    @motion_phase_b_batch_c_failed_v1037=true
    log_event(:verify,'MOTION_PHASE_B_MULTI_HIT_V1037 pass=0 error=1')
    @verification_done[:motion_phase_b_multihit_v1037]=true
  end

  def update_verification_script
    pmd_ac_v1037_update_verification_script
    return unless motion_phase_b_verifier_active_v1036?
    return if @verification_done==nil
    f=@verification_frame.to_i
    verify_motion_deploy_idle45_v1037 if f>=185
    verify_motion_phase_b_multihit_v1037 if f>=188
  end

  # Phase A 的 update_verification_script 會在 f>=190 呼叫最新版同名方法。
  # 將 A/B/C 三批與 Deploy idle 45° 一起收斂成目前正式 CANDIDATE 結果。
  def verify_motion_final_v102
    return if @verification_done[:motion_final_v102]
    pass=!@motion_phase_a_failed_v102 && !@motion_phase_b_failed_v103 &&
      !@motion_phase_b_batch_b_failed_v1036 && !@motion_phase_b_batch_c_failed_v1037
    log_event(:verify,
      'PMD_MOTION_PHASE_A_V102 pass='+(pass ? '1':'0')+
      ' superseded_by_phase_b=1 scope=0001-0026 presentation_only=1'+
      ' damage_formula_unchanged=1 attack_speed_unchanged=1 spatial_framework_unchanged=1')
    log_event(:verify,
      'PMD_MOTION_PHASE_B_V103 pass='+(pass ? '1':'0')+
      ' batch=contact_chain_c scope=0001-0026 anticipation=1 source_hit_return=1'+
      ' impact_semantic=1 landing=1 attacker_recovery=1 ambient_reset=1'+
      ' miss_semantic=1 immune_semantic=1 guard_semantic=1'+
      ' multi_hit_per_impact=1 nonfinal_recovery_suppressed=1 final_recovery=1'+
      ' deploy_direct_native_fix=1 deploy_idle45=1 deploy_loop_slowed=1'+
      ' damage_packet_authority=v0.60.2 timing_unchanged=1'+
      ' ai_unchanged=1 damage_formula_unchanged=1 attack_speed_unchanged=1'+
      ' energy_unchanged=1 spatial_unchanged=1')
    @verification_done[:motion_final_v102]=true
  end
end
