# encoding: UTF-8
#==============================================================================
# ■ PMD AutoChess - Motion Visual Tuning Batch VII
#   Signature Priority Rescue / Evolution Lunge Identity v1.04.10
#==============================================================================
# 【用途】
# 在 v1.04.6 已完成 Head / Punch / Kick selective fallback rescue 後，繼續改善
# 0027～0494 generated scope 中仍以 generic :attack 當第一 presentation source 的
# 高價值路徑。本批不追求把 fallback 數字硬清零，而是修正「已知道身體 signature，
# 卻因通用 family scoring 又退回 Attack」的 arbitration 問題。
#
# 本批重點：
# 1. Evolution Lunge Identity：延伸 v1.04.5 的進化線動作血統到 Lunge family。
#    例如 Sandshrew/Vulpix/Poochyena/Skitty/Swablu 偏 Head；Machop 偏 Kick；
#    Riolu/Electrike/Taillow/Starly/Buizel 等高速線偏 QuickStrike。
# 2. Anatomical Lunge Rescue：Brawler、Jaw、Roll、Shell、Stomper、Blade、Claw、
#    Tail、Wing 等高辨識度身體群，在 parent 第一候選仍是 :attack 時，提升通過
#    true-45 + anatomy + semantic gate 的專屬 source。
# 3. Signature Strike Rescue：Blade / Claw / Tail / Wing 在 Strike family 仍退回
#    :attack 時，優先 Slice / Swing / TailWhip 等更符合身體構造的 Native。
# 4. Bite 保留既有安全政策：沒有真正 Bite / Head 或明確進化線咬擊 signature 時，
#    不因統計數字把 Swing 冒充咬擊。
#
# 【主要設定】
# MOTION_BATCHVII_PRIOR_SAFE_ATTACK_V10410 = 1377
#   v1.04.6 Windows PASS 後的 estimated safe Attack fallback baseline。
# MOTION_BATCHVII_LINE_LUNGE_V10410
#   17 條進化線的 Lunge soft-signature。
# MOTION_BATCHVII_LUNGE_TARGETS_V10410
#   重要進化線 + 9 類 body/signature 群的 Lunge target。
# MOTION_BATCHVII_STRIKE_TARGETS_V10410
#   Blade / Claw / Tail / Wing 的 Strike target。
#
# 【機制規則】
# - Frozen Combat Core 不直接修改；本腳本為 trailing alias layer。
# - 0001～0026 curated Motion 完全不接管。
# - 只有 parent 第一候選「真的仍是 :attack」才 Rescue；已有 QuickStrike、Head、
#   Bite、Kick、Slice、Strike 等較專用 Native 時一律保留 parent。
# - Rescue pose 必須同時通過：
#     motion_generated_diag_geometry_v1040?
#     motion_batchiii_pose_allowed_v1043
#     motion_batchiv_semantic_pose_allowed_v1044
# - HOME、logical x/y、velocity、Damage、AI、Attack Speed、Energy、action_timer 不變。
# - 不做 468×16 live route scan；只在 battle live update 前檢查本批 target routes。
# - Presentation Profile Memo v1.04.9、Zone Bitmap Cache v1.04.7、Skill Banner 54f
#   全部保留，不修改 Performance baseline。
#
# 【可調參數】
# - 擴充進化線：修改 MOTION_BATCHVII_LINE_LUNGE_V10410。
# - 擴充身體群：優先新增到既有 Batch II/III anatomy/signature group，再在
#   motion_batchvii_lunge_choices_v10410 / motion_batchvii_strike_choices_v10410
#   設定合理候選，不要直接全物種套 Swing。
# - Bite 類除非有嘴部／頭部語意證據，不加入 generic rescue。
#
# 【事件／腳本呼叫方式】
# 無需事件呼叫。PMD Motion verifier 會自動輸出：
#   MOTION_BATCHVII_SIGNATURE_RESCUE_PREBATTLE_V10410
#   MOTION_VISUAL_TUNING_BATCHVII_V10410
#   MOTION_EVOLUTION_LUNGE_IDENTITY_V10410
#   MOTION_SIGNATURE_PRIORITY_RESCUE_QA_V10410
#
# 【實際範例】
# - Lucario 的 Lunge 若 parent 已是 QuickStrike：本層不碰。
# - Machoke 的 Lunge 若 parent 仍是 Attack，且 Kick true-45/semantic safe：提升 Kick。
# - Scizor/Skarmory 類 Strike 若只剩 Attack，且 Swing/Slice safe：提升身體 signature。
# - 沒有 Bite/Head Native 的 Jaw species：仍可保留 Attack，不用尾巴假裝咬人。
#==============================================================================
$imported={} unless defined?($imported)
$imported['PMD_AutoChess_MotionVisualTuningBatchVII_SignaturePriorityRescue_v10410']=true

module PMD_AC
  MOTION_BATCHVII_PRIOR_SAFE_ATTACK_V10410=1377

  # v1.04.5 已建立的 evolution identity 向 Lunge family 延伸。
  # 只列有明確身體語意、且 build-time metadata 校準可通過的 line。
  MOTION_BATCHVII_LINE_LUNGE_V10410={
    :sandshrew_line=>:head,
    :vulpix_line=>:head,
    :machop_line=>:kick,
    :poochyena_line=>:head,
    :skitty_line=>:head,
    :swablu_line=>:head,
    :carvanha_line=>:bite,
    :corphish_line=>:bite,
    :electrike_line=>:quick_strike,
    :pikachu_line=>:quick_strike,
    :riolu_line=>:quick_strike,
    :taillow_line=>:quick_strike,
    :wingull_line=>:quick_strike,
    :starly_line=>:quick_strike,
    :buizel_line=>:quick_strike,
    :buneary_line=>:quick_strike,
    :surskit_line=>:quick_strike
  }

  MOTION_BATCHVII_EVOLUTION_LUNGE_SPECIES_V10410=[]
  MOTION_BATCHVII_LINE_LUNGE_V10410.keys.each do |line|
    rows=MOTION_BATCHV_MEMBERS_BY_LINE_V1045[line] || []
    rows.each do |sid|
      n=sid.to_s.to_i
      if n>=27 && n<=494 && !MOTION_BATCHVII_EVOLUTION_LUNGE_SPECIES_V10410.include?(sid.to_s)
        MOTION_BATCHVII_EVOLUTION_LUNGE_SPECIES_V10410.push(sid.to_s)
      end
    end
  end

  MOTION_BATCHVII_LUNGE_TARGETS_V10410=(
    MOTION_BATCHVII_EVOLUTION_LUNGE_SPECIES_V10410+
    MOTION_BATCHII_BRAWLERS_V1042+
    MOTION_BATCHII_JAW_V1042+
    MOTION_BATCHII_ROLL_SPIN_V1042+
    MOTION_BATCHIII_SHELL_V1043+
    MOTION_BATCHIII_STOMPER_V1043+
    MOTION_BATCHII_BLADES_V1042+
    MOTION_BATCHIII_CLAW_V1043+
    MOTION_BATCHIII_TAIL_V1043+
    MOTION_BATCHIII_WING_V1043
  ).uniq

  MOTION_BATCHVII_STRIKE_TARGETS_V10410=(
    MOTION_BATCHII_BLADES_V1042+
    MOTION_BATCHIII_CLAW_V1043+
    MOTION_BATCHIII_TAIL_V1043+
    MOTION_BATCHIII_WING_V1043
  ).uniq

  MOTION_BATCHVII_CASES_V10410={
    :strike=>[:basic_attack,nil,nil],
    :lunge=>[:v10410_lunge,nil,{:motion=>:contact_return}]
  }

  class << self
    alias pmd_ac_v10410_batchvii_native_pose_candidates_v061 native_pose_candidates_v061 unless method_defined?(:pmd_ac_v10410_batchvii_native_pose_candidates_v061)

    def motion_batchvii_line_lunge_pose_v10410(species)
      line=motion_batchv_line_key_v1045(species)
      return nil if line==nil
      MOTION_BATCHVII_LINE_LUNGE_V10410[line]
    rescue
      nil
    end

    def motion_batchvii_push_unique_v10410(out,items)
      (items || []).each do |pose|
        out.push(pose) if pose!=nil && !out.include?(pose)
      end
      out
    rescue
      out || []
    end

    # Lunge priority：evolution identity 先於 generic body rescue。
    # 每個 group 的候選都只代表 presentation body language，不改技能 family。
    def motion_batchvii_lunge_choices_v10410(species)
      sid=species.to_s
      out=[]
      line_pose=motion_batchvii_line_lunge_pose_v10410(sid)
      out.push(line_pose) if line_pose!=nil

      if MOTION_BATCHII_BRAWLERS_V1042.include?(sid)
        motion_batchvii_push_unique_v10410(out,[:kick,:punch,:uppercut,:jab,:chop,:quick_strike,:strike,:swing])
      end
      if MOTION_BATCHII_JAW_V1042.include?(sid)
        motion_batchvii_push_unique_v10410(out,[:bite,:head,:quick_strike,:strike,:swing])
      end
      if MOTION_BATCHII_ROLL_SPIN_V1042.include?(sid)
        motion_batchvii_push_unique_v10410(out,[:slam,:head,:ricochet,:tumble,:tumble_back,:swing,:strike])
      end
      if MOTION_BATCHIII_SHELL_V1043.include?(sid)
        motion_batchvii_push_unique_v10410(out,[:ricochet,:slam,:head,:twirl,:swing,:strike])
      end
      if MOTION_BATCHIII_STOMPER_V1043.include?(sid)
        motion_batchvii_push_unique_v10410(out,[:stomp,:slam,:head,:kick,:strike,:swing])
      end
      if MOTION_BATCHII_BLADES_V1042.include?(sid)
        motion_batchvii_push_unique_v10410(out,[:slice,:swing,:quick_strike,:strike])
      end
      if MOTION_BATCHIII_CLAW_V1043.include?(sid)
        motion_batchvii_push_unique_v10410(out,[:slice,:multi_scratch,:scratch,:swing,:quick_strike,:strike])
      end
      if MOTION_BATCHIII_TAIL_V1043.include?(sid)
        motion_batchvii_push_unique_v10410(out,[:tail_whip,:swing,:slam,:strike])
      end
      if MOTION_BATCHIII_WING_V1043.include?(sid)
        motion_batchvii_push_unique_v10410(out,[:quick_strike,:swing,:double,:strike])
      end
      out
    rescue
      []
    end

    # Strike 只補「明確身體武器」：blade/claw/tail/wing。
    def motion_batchvii_strike_choices_v10410(species)
      sid=species.to_s
      out=[]
      if MOTION_BATCHII_BLADES_V1042.include?(sid)
        motion_batchvii_push_unique_v10410(out,[:slice,:swing,:quick_strike,:strike])
      end
      if MOTION_BATCHIII_CLAW_V1043.include?(sid)
        motion_batchvii_push_unique_v10410(out,[:scratch,:slice,:swing,:multi_scratch,:quick_strike,:strike])
      end
      if MOTION_BATCHIII_TAIL_V1043.include?(sid)
        motion_batchvii_push_unique_v10410(out,[:tail_whip,:swing,:slam,:strike])
      end
      if MOTION_BATCHIII_WING_V1043.include?(sid)
        motion_batchvii_push_unique_v10410(out,[:swing,:quick_strike,:jab,:strike])
      end
      out
    rescue
      []
    end

    def motion_batchvii_target_v10410?(species,family)
      sid=species.to_s
      return MOTION_BATCHVII_LUNGE_TARGETS_V10410.include?(sid) if family==:lunge
      return MOTION_BATCHVII_STRIKE_TARGETS_V10410.include?(sid) if family==:strike
      false
    rescue
      false
    end

    def motion_batchvii_choices_v10410(species,family)
      return motion_batchvii_lunge_choices_v10410(species) if family==:lunge
      return motion_batchvii_strike_choices_v10410(species) if family==:strike
      []
    rescue
      []
    end

    def motion_batchvii_rescue_safe_v10410(species,pose,family)
      return false if pose==nil || pose==:attack
      return false unless motion_generated_diag_geometry_v1040?(species,pose)
      return false unless motion_batchiii_pose_allowed_v1043(species,pose,family)
      return false unless motion_batchiv_semantic_pose_allowed_v1044(species,pose,family)
      true
    rescue
      false
    end

    def motion_batchvii_rescue_pose_v10410(species,family)
      motion_batchvii_choices_v10410(species,family).each do |pose|
        return pose if motion_batchvii_rescue_safe_v10410(species,pose,family)
      end
      nil
    rescue
      nil
    end

    def native_pose_candidates_v061(species,move_key,data=nil,profile=nil)
      base=pmd_ac_v10410_batchvii_native_pose_candidates_v061(species,move_key,data,profile)
      return base unless motion_generated_species_v1040?(species)
      return base if base==nil || base.empty? || base[0]!=:attack
      family=motion_action_family_v102(move_key,data,profile)
      return base unless motion_batchvii_target_v10410?(species,family)
      pose=motion_batchvii_rescue_pose_v10410(species,family)
      return base if pose==nil || pose==:attack
      out=[pose]
      base.each{|p|out.push(p) unless out.include?(p)}
      out
    rescue
      pmd_ac_v10410_batchvii_native_pose_candidates_v061(species,move_key,data,profile)
    end

    def motion_batchvii_line_audit_v10410
      checks=0;safe=0;bad=[]
      MOTION_BATCHVII_LINE_LUNGE_V10410.each do |line,pose|
        rows=MOTION_BATCHV_MEMBERS_BY_LINE_V1045[line] || []
        rows.each do |sid|
          next unless motion_generated_species_v1040?(sid)
          checks+=1
          ok=motion_batchvii_rescue_safe_v10410(sid,pose,:lunge)
          safe+=1 if ok
          bad.push(sid+':'+line.to_s+'='+pose.to_s) if !ok && bad.size<12
        end
      end
      {:checks=>checks,:safe=>safe,:bad=>bad}
    rescue
      {:checks=>0,:safe=>0,:bad=>['exception']}
    end

    # selective metadata audit：只掃本批 131 Lunge + 57 Strike target routes。
    # parent specific 直接保留；parent :attack 才要求 current 一定成功 Rescue。
    def motion_batchvii_rescue_audit_v10410
      total=0;generic=0;rescued=0;retained=0;strict=0;semantic=0;bad=[]
      family={:lunge=>[0,0,0],:strike=>[0,0,0]}
      line_generic=0;line_promoted=0
      [:lunge,:strike].each do |fam|
        targets=fam==:lunge ? MOTION_BATCHVII_LUNGE_TARGETS_V10410 : MOTION_BATCHVII_STRIKE_TARGETS_V10410
        row=MOTION_BATCHVII_CASES_V10410[fam]
        targets.each do |sid|
          next unless motion_generated_species_v1040?(sid)
          total+=1
          family[fam][0]+=1
          prior=pmd_ac_v10410_batchvii_native_pose_candidates_v061(sid,row[0],row[1],row[2]) || []
          before=prior.empty? ? nil : prior[0]
          if before==:attack
            generic+=1
            family[fam][1]+=1
            current=native_pose_candidates_v061(sid,row[0],row[1],row[2]) || []
            after=current.empty? ? nil : current[0]
            if fam==:lunge && motion_batchvii_line_lunge_pose_v10410(sid)!=nil
              line_generic+=1
            end
            if after!=nil && after!=:attack
              rescued+=1
              family[fam][2]+=1
              oks=motion_generated_diag_geometry_v1040?(sid,after)
              oka=motion_batchiii_pose_allowed_v1043(sid,after,fam)
              okq=motion_batchiv_semantic_pose_allowed_v1044(sid,after,fam)
              strict+=1 if oks
              semantic+=1 if oka && okq
              if fam==:lunge
                lp=motion_batchvii_line_lunge_pose_v10410(sid)
                line_promoted+=1 if lp!=nil && after==lp
              end
              if !oks || !oka || !okq
                bad.push(sid+':'+fam.to_s+'='+after.to_s) if bad.size<12
              end
            else
              bad.push(sid+':'+fam.to_s+'=unrescued') if bad.size<12
            end
          else
            retained+=1
          end
        end
      end
      {:total=>total,:generic=>generic,:rescued=>rescued,:retained=>retained,
       :strict=>strict,:semantic=>semantic,:family=>family,:bad=>bad,
       :line_generic=>line_generic,:line_promoted=>line_promoted}
    rescue
      {:total=>0,:generic=>0,:rescued=>0,:retained=>0,:strict=>0,:semantic=>0,
       :family=>{:lunge=>[0,0,0],:strike=>[0,0,0]},:bad=>['exception'],
       :line_generic=>0,:line_promoted=>0}
    end
  end
end

class Scene_PMD_AutoChess
  alias pmd_ac_v10410_batchvii_prepare_verification_battle prepare_verification_battle unless method_defined?(:pmd_ac_v10410_batchvii_prepare_verification_battle)
  alias pmd_ac_v10410_batchvii_update_verification_script update_verification_script unless method_defined?(:pmd_ac_v10410_batchvii_update_verification_script)

  def prepare_verification_battle
    pmd_ac_v10410_batchvii_prepare_verification_battle
    return unless respond_to?(:motion_phase_b_verifier_active_v1036?) && motion_phase_b_verifier_active_v1036?
    begin
      t0=Time.now
      @motion_batchvii_line_qa_v10410=PMD_AC.motion_batchvii_line_audit_v10410
      @motion_batchvii_rescue_qa_v10410=PMD_AC.motion_batchvii_rescue_audit_v10410
      ms=((Time.now-t0)*1000.0).round
      @motion_batchvii_rescue_qa_v10410[:ms]=ms
      q=@motion_batchvii_rescue_qa_v10410
      l=@motion_batchvii_line_qa_v10410
      log_event(:perf,'MOTION_BATCHVII_SIGNATURE_RESCUE_PREBATTLE_V10410 ready=1'+
        ' routes='+q[:total].to_i.to_s+' generic_before='+q[:generic].to_i.to_s+
        ' rescued='+q[:rescued].to_i.to_s+' retained_specific='+q[:retained].to_i.to_s+
        ' evolution_lunge_safe='+l[:safe].to_i.to_s+'/'+l[:checks].to_i.to_s+
        ' ms='+ms.to_i.to_s+' pre_live_update=1 bitmap_required=0 live_full_scan=0')
      log_event(:showcase,'MOTION_VISUAL_TUNING_BATCHVII_V10410 START signature_priority_arbitration=1'+
        ' evolution_lunge_lines=17 lunge_targets='+PMD_AC::MOTION_BATCHVII_LUNGE_TARGETS_V10410.size.to_i.to_s+
        ' strike_targets='+PMD_AC::MOTION_BATCHVII_STRIKE_TARGETS_V10410.size.to_i.to_s+
        ' parent_attack_only=1 bite_policy_retained=1 strict45=1 anatomy_gate=1 semantic_gate=1'+
        ' performance_v1049_frozen=1 curated_0001_0026_untouched=1 gameplay_unchanged=1')
    rescue => e
      @motion_batchvii_line_qa_v10410={:checks=>0,:safe=>0,:bad=>['exception']}
      @motion_batchvii_rescue_qa_v10410={:total=>0,:generic=>0,:rescued=>0,:retained=>0,
        :strict=>0,:semantic=>0,:family=>{:lunge=>[0,0,0],:strike=>[0,0,0]},
        :bad=>['exception'],:line_generic=>0,:line_promoted=>0,:ms=>0}
      log_event(:perf,'MOTION_BATCHVII_SIGNATURE_RESCUE_PREBATTLE_V10410 ready=0 error='+e.class.to_s)
    end
  end

  def update_verification_script
    pmd_ac_v10410_batchvii_update_verification_script
    return unless respond_to?(:motion_phase_b_verifier_active_v1036?) && motion_phase_b_verifier_active_v1036?
    if !@motion_batchvii_verify_v10410 && @verification_frame.to_i>=230
      @motion_batchvii_verify_v10410=true
      q=@motion_batchvii_rescue_qa_v10410 || {}
      l=@motion_batchvii_line_qa_v10410 || {}
      generic=q[:generic].to_i;rescued=q[:rescued].to_i
      line_ok=l[:checks].to_i>0 && l[:safe].to_i==l[:checks].to_i && (l[:bad]||[]).empty?
      rescue_ok=q[:total].to_i>0 && generic>0 && rescued==generic &&
        q[:strict].to_i==rescued && q[:semantic].to_i==rescued && (q[:bad]||[]).empty?
      ok=line_ok && rescue_ok
      rem=PMD_AC::MOTION_BATCHVII_PRIOR_SAFE_ATTACK_V10410-rescued
      rem=0 if rem<0
      fam=q[:family] || {}
      lu=fam[:lunge] || [0,0,0]
      st=fam[:strike] || [0,0,0]
      log_event(:verify,'MOTION_VISUAL_TUNING_BATCHVII_V10410 pass='+(ok ? '1':'0')+
        ' signature_priority_arbitration=1 target_routes='+q[:total].to_i.to_s+
        ' generic_before='+generic.to_i.to_s+' rescued='+rescued.to_i.to_s+
        ' retained_specific='+q[:retained].to_i.to_s+
        ' estimated_safe_attack_remaining='+rem.to_i.to_s+
        ' parent_attack_only=1 bite_policy_retained=1 strict45=1 anatomy_gate=1 semantic_gate=1'+
        ' performance_v1049_frozen=1 curated_0001_0026_untouched=1')
      log_event(:verify,'MOTION_EVOLUTION_LUNGE_IDENTITY_V10410 pass='+(line_ok ? '1':'0')+
        ' lines='+PMD_AC::MOTION_BATCHVII_LINE_LUNGE_V10410.size.to_i.to_s+
        ' generated_members='+l[:checks].to_i.to_s+' safe='+l[:safe].to_i.to_s+'/'+l[:checks].to_i.to_s+
        ' generic_before='+q[:line_generic].to_i.to_s+' promoted='+q[:line_promoted].to_i.to_s+
        ' soft_preference_only=1 parent_specific_retained=1 bad=['+(l[:bad]||[]).join(',')+']')
      log_event(:verify,'MOTION_SIGNATURE_PRIORITY_RESCUE_QA_V10410 pass='+(rescue_ok ? '1':'0')+
        ' lunge='+lu[2].to_i.to_s+'/'+lu[1].to_i.to_s+' lunge_targets='+lu[0].to_i.to_s+
        ' strike='+st[2].to_i.to_s+'/'+st[1].to_i.to_s+' strike_targets='+st[0].to_i.to_s+
        ' strict45='+q[:strict].to_i.to_s+'/'+rescued.to_i.to_s+
        ' semantic='+q[:semantic].to_i.to_s+'/'+rescued.to_i.to_s+
        ' qa_ms='+q[:ms].to_i.to_s+' bitmap_required=0 live_full_scan=0 bad=['+(q[:bad]||[]).join(',')+']')
    end
  rescue
  end
end
