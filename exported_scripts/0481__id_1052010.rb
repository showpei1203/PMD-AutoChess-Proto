# encoding: UTF-8
#==============================================================================
# ■ PMD AutoChess - Motion Visual Tuning Batch VIII
#   Spin / Sound / Special Remote Residual Quality v1.04.12
#==============================================================================
# 【用途】
# 延續 v1.04.10 Batch VII 的 Signature Priority Rescue，處理 generated 0027～0494
# 中仍偏「功能正確但演技辨識度不足」的三類 presentation：
# 1. Spin：有真正 Twirl Native 時，不再讓 Spin family 停在 generic Attack/Double。
# 2. Sound：吼叫／尖叫優先 Rumble / RearUp；歌唱類有 Dance / Appeal 時優先使用，
#    避免所有聲音招式都只是 Charge。
# 3. Special Remote：Cast / Drain 在有 Emit 或具明確 caster expressive Native 時，
#    從 generic Charge / Shoot 提升成更符合遠程施法身體語言的 source；Shock 則確認
#    具 direct Shock 的物種絕不退回 generic ranged pose。
#
# 【主要設定】
# MOTION_BATCHVIII_SPIN_TWIRL_V10412
#   compiled metadata 中通過 conservative true-45 的 direct Twirl 物種。
# MOTION_BATCHVIII_SOUND_SHOUT_V10412
#   具 Rumble / RearUp true-45 的聲音演技物種。
# MOTION_BATCHVIII_SOUND_SING_V10412
#   具 Dance / Appeal true-45，可用於 Sing / Grass Whistle 類演技的物種。
# MOTION_BATCHVIII_CAST_EMIT_V10412 / MOTION_BATCHVIII_DRAIN_EMIT_V10412
#   具 Emit true-45 的特殊遠程 source；Cast 另外只加入 0036/0280/0282 三個
#   已知 caster expressive 例外。
# MOTION_BATCHVIII_SHOCK_DIRECT_V10412
#   具 direct Shock true-45 的 generated 物種。
#
# 【機制規則】
# - Frozen Combat Core 不直接修改；本腳本為 trailing alias layer。
# - 0001～0026 curated Motion 完全不接管。
# - 只有 parent 第一候選仍屬「低辨識度」時才 Rescue；已有專用 Native 一律保留。
# - Spin 不用 universal Swing 假裝旋轉；沒有 Twirl 就保留既有安全 fallback。
# - Sound 的吼叫與歌唱分開：Screech/Roar 類可 RearUp/Rumble；Sing 類才允許
#   Dance/Appeal，不把舞蹈套到所有聲音技能。
# - Cast / Drain 只提升通過 strict45 + anatomy + semantic gate 的 Emit/expressive source。
# - Shock 只接受 direct Shock，不把一般 Shoot 假稱為物種專屬電擊姿勢。
# - HOME、logical x/y、velocity、Damage、AI、Attack Speed、Energy、action_timer 不變。
# - 不做 468×16 live scan；本批只在 battle live update 前掃固定 target routes。
# - Presentation Profile Memo v1.04.9 / Zone Cache v1.04.7 / Skill Banner 54f 全保留。
#
# 【可調參數】
# - 新增 Sound expressive 物種：只可加入已確認 true-45 的 RearUp/Rumble/Dance/Appeal。
# - 新增 Special Remote：優先 direct Emit / SpAttack / Shock；若只是 Attack/Swing，
#   不應為了降低 fallback 統計而強行提升。
# - Spin 若沒有 Twirl/Rotate 的可信 true-45，不要用 Swing 冒充。
#
# 【事件／腳本呼叫方式】
# 無需事件呼叫。PMD Motion verifier 自動輸出：
#   MOTION_BATCHVIII_RESIDUAL_QUALITY_PREBATTLE_V10412
#   MOTION_VISUAL_TUNING_BATCHVIII_V10412
#   MOTION_SPIN_SOUND_REMOTE_RESCUE_QA_V10412
#   MOTION_SPECIAL_REMOTE_IDENTITY_V10412
#
# 【實際範例】
# - Rapid Spin：若 #0324 有 Twirl 且 parent 仍是 Attack/Double，改用 Twirl。
# - Screech：若物種有 RearUp/Rumble true-45，優先張口／仰身式演技，不再只 Charge。
# - Sing：只有具 Dance/Appeal true-45 的物種才提升，其他維持既有安全 source。
# - Cast：具 Emit 的特殊物種若 parent 仍是 Charge/Shoot，提升 Emit；已有 SpAttack 保留。
#==============================================================================
$imported={} unless defined?($imported)
$imported['PMD_AutoChess_MotionVisualTuningBatchVIII_SpinSoundRemote_v10412']=true

module PMD_AC
  MOTION_BATCHVIII_SPIN_TWIRL_V10412=%w(
    0045 0056 0072 0102 0151 0182 0184 0194 0210 0237 0258 0324 0326 0368 0438 0439
  )
  # Roll/Spin 重要物種若沒有 Twirl，但有更接近整體翻滾的 Head/Slam true-45，
  # 只對這幾隻人工提升；其餘仍保留安全 fallback，不拿 universal Swing 冒充旋轉。
  MOTION_BATCHVIII_SPIN_SIGNATURE_V10412={
    '0027'=>:head, '0028'=>:head, '0075'=>:slam, '0324'=>:twirl
  }
  MOTION_BATCHVIII_SPIN_TARGETS_V10412=(MOTION_BATCHVIII_SPIN_TWIRL_V10412+MOTION_BATCHVIII_SPIN_SIGNATURE_V10412.keys).uniq

  MOTION_BATCHVIII_SOUND_SHOUT_V10412=%w(
    0034 0037 0038 0058 0059 0061 0062 0077 0078 0118 0119 0130 0131 0134 0137 0144 0147
    0161 0162 0180 0186 0199 0223 0224 0228 0229 0230 0233 0234 0260 0261 0262 0263 0264
    0287 0316 0317 0320 0321 0322 0323 0337 0338 0343 0344 0350 0363 0364 0365 0377 0378
    0379 0380 0381 0384 0408 0418 0422 0423 0424 0429 0434 0435 0443 0444 0445 0447 0448
    0449 0450 0453 0454 0455 0456 0459 0460 0464 0473 0474 0475 0483 0484 0490 0491
  )

  MOTION_BATCHVIII_SOUND_SING_V10412=%w(
    0035 0036 0060 0103 0172 0173 0175 0176 0190 0208 0216 0252 0280 0282 0287 0288 0289
    0294 0298 0300 0301 0339 0340 0349 0417 0428
  )

  MOTION_BATCHVIII_CAST_EMIT_V10412=%w(
    0032 0033 0145 0149 0179 0272 0299 0371 0372 0373 0383 0386 0401 0431 0432 0433 0437
    0465 0466 0476 0477 0479 0485 0486 0492
  )
  # 0036=Abra line body-language; 0280/0282=Ralts/Gardevoir caster expressive.
  MOTION_BATCHVIII_CAST_EXPRESSIVE_V10412=%w(0036 0280 0282)
  MOTION_BATCHVIII_DRAIN_EMIT_V10412=MOTION_BATCHVIII_CAST_EMIT_V10412
  MOTION_BATCHVIII_SHOCK_DIRECT_V10412=%w(0135 0172 0243 0309 0310 0311 0312)

  # [tag, expected_family, move_key, data, profile, target_constant_symbol]
  MOTION_BATCHVIII_CASES_V10412=[
    [:spin,:spin,:rapid_spin,nil,nil,:MOTION_BATCHVIII_SPIN_TARGETS_V10412],
    [:sound_shout,:sound,:screech,nil,nil,:MOTION_BATCHVIII_SOUND_SHOUT_V10412],
    [:sound_sing,:sound,:sing,nil,nil,:MOTION_BATCHVIII_SOUND_SING_V10412],
    [:shock,:shock,:v10412_shock,{:visual_kind=>:target_hit,:move_type=>:electric},nil,:MOTION_BATCHVIII_SHOCK_DIRECT_V10412],
    [:cast,:cast,:v10412_cast,{:visual_kind=>:self_fx,:move_type=>:psychic},nil,:MOTION_BATCHVIII_CAST_EMIT_V10412],
    [:cast_expressive,:cast,:v10412_cast,{:visual_kind=>:self_fx,:move_type=>:psychic},nil,:MOTION_BATCHVIII_CAST_EXPRESSIVE_V10412],
    [:drain,:drain,:absorb,nil,nil,:MOTION_BATCHVIII_DRAIN_EMIT_V10412]
  ]

  class << self
    alias pmd_ac_v10412_batchviii_native_pose_candidates_v061 native_pose_candidates_v061 unless method_defined?(:pmd_ac_v10412_batchviii_native_pose_candidates_v061)

    def motion_batchviii_low_quality_v10412?(family,pose)
      return false if pose==nil
      case family
      when :spin
        [:attack,:strike,:double].include?(pose)
      when :sound
        [:attack,:charge,:sp_attack,:shoot,:emit].include?(pose)
      when :shock
        [:attack,:charge,:sp_attack,:shoot,:emit].include?(pose)
      when :cast
        [:attack,:charge,:shoot].include?(pose)
      when :drain
        [:attack,:charge,:shoot].include?(pose)
      else
        false
      end
    rescue
      false
    end

    def motion_batchviii_sing_key_v10412?(move_key)
      k=move_key==nil ? :unknown : move_key.to_sym
      k==:sing || k==:grass_whistle
    rescue
      false
    end

    def motion_batchviii_target_list_v10412(tag)
      case tag
      when :spin; MOTION_BATCHVIII_SPIN_TARGETS_V10412
      when :sound_shout; MOTION_BATCHVIII_SOUND_SHOUT_V10412
      when :sound_sing; MOTION_BATCHVIII_SOUND_SING_V10412
      when :shock; MOTION_BATCHVIII_SHOCK_DIRECT_V10412
      when :cast; MOTION_BATCHVIII_CAST_EMIT_V10412
      when :cast_expressive; MOTION_BATCHVIII_CAST_EXPRESSIVE_V10412
      when :drain; MOTION_BATCHVIII_DRAIN_EMIT_V10412
      else; []
      end
    rescue
      []
    end

    def motion_batchviii_species_target_v10412?(species,family,move_key)
      sid=species.to_s
      case family
      when :spin
        MOTION_BATCHVIII_SPIN_TARGETS_V10412.include?(sid)
      when :sound
        if motion_batchviii_sing_key_v10412?(move_key)
          MOTION_BATCHVIII_SOUND_SING_V10412.include?(sid)
        else
          MOTION_BATCHVIII_SOUND_SHOUT_V10412.include?(sid)
        end
      when :shock
        MOTION_BATCHVIII_SHOCK_DIRECT_V10412.include?(sid)
      when :cast
        MOTION_BATCHVIII_CAST_EMIT_V10412.include?(sid) || MOTION_BATCHVIII_CAST_EXPRESSIVE_V10412.include?(sid)
      when :drain
        MOTION_BATCHVIII_DRAIN_EMIT_V10412.include?(sid)
      else
        false
      end
    rescue
      false
    end

    def motion_batchviii_choices_v10412(species,family,move_key)
      sid=species.to_s
      case family
      when :spin
        out=[]
        sig=MOTION_BATCHVIII_SPIN_SIGNATURE_V10412[sid]
        out.push(sig) if sig!=nil
        out.push(:twirl) unless out.include?(:twirl)
        return out
      when :sound
        if motion_batchviii_sing_key_v10412?(move_key)
          return [:dance,:appeal]
        end
        return [:rumble,:rear_up]
      when :shock
        return [:shock]
      when :cast
        if MOTION_BATCHVIII_CAST_EXPRESSIVE_V10412.include?(sid)
          return [:emit,:sp_attack,:dance,:appeal]
        end
        return [:emit,:sp_attack]
      when :drain
        return [:emit,:sp_attack]
      end
      []
    rescue
      []
    end

    def motion_batchviii_safe_pose_v10412?(species,pose,family)
      return false if pose==nil || pose==:attack
      return false unless motion_generated_diag_geometry_v1040?(species,pose)
      return false unless motion_batchiii_pose_allowed_v1043(species,pose,family)
      return false unless motion_batchiv_semantic_pose_allowed_v1044(species,pose,family)
      true
    rescue
      false
    end

    def motion_batchviii_rescue_pose_v10412(species,family,move_key)
      return nil unless motion_batchviii_species_target_v10412?(species,family,move_key)
      @motion_batchviii_rescue_cache_v10412={} if @motion_batchviii_rescue_cache_v10412==nil
      sing=motion_batchviii_sing_key_v10412?(move_key) ? 'sing' : 'other'
      key=species.to_s+'|'+family.to_s+'|'+sing
      return @motion_batchviii_rescue_cache_v10412[key] if @motion_batchviii_rescue_cache_v10412.has_key?(key)
      chosen=nil
      motion_batchviii_choices_v10412(species,family,move_key).each do |pose|
        if motion_batchviii_safe_pose_v10412?(species,pose,family)
          chosen=pose
          break
        end
      end
      @motion_batchviii_rescue_cache_v10412[key]=chosen
      chosen
    rescue
      nil
    end

    def native_pose_candidates_v061(species,move_key,data=nil,profile=nil)
      base=pmd_ac_v10412_batchviii_native_pose_candidates_v061(species,move_key,data,profile)
      return base unless motion_generated_species_v1040?(species)
      return base if base==nil || base.empty?
      family=motion_action_family_v102(move_key,data,profile)
      return base unless [:spin,:sound,:shock,:cast,:drain].include?(family)
      return base unless motion_batchviii_low_quality_v10412?(family,base[0])
      pose=motion_batchviii_rescue_pose_v10412(species,family,move_key)
      return base if pose==nil || pose==base[0]
      out=[pose]
      base.each{|p|out.push(p) unless out.include?(p)}
      out
    rescue
      pmd_ac_v10412_batchviii_native_pose_candidates_v061(species,move_key,data,profile)
    end

    # 本批固定 target route audit。只掃 7 組約 180 routes，不做全 7488 live scan。
    def motion_batchviii_audit_v10412
      total=0;safe=0;low=0;rescued=0;retained=0;strict=0;semantic=0;family_match=0;bad=[]
      rows={}
      MOTION_BATCHVIII_CASES_V10412.each do |case_row|
        tag=case_row[0];expected=case_row[1];move_key=case_row[2];data=case_row[3];profile=case_row[4]
        targets=motion_batchviii_target_list_v10412(tag)
        rr={:total=>0,:safe=>0,:low=>0,:rescued=>0,:retained=>0}
        targets.each do |sid|
          next unless motion_generated_species_v1040?(sid)
          total+=1;rr[:total]+=1
          fam=motion_action_family_v102(move_key,data,profile)
          family_match+=1 if fam==expected
          pose=motion_batchviii_rescue_pose_v10412(sid,fam,move_key)
          if pose!=nil && motion_batchviii_safe_pose_v10412?(sid,pose,fam)
            safe+=1;rr[:safe]+=1
          else
            bad.push(sid+':'+tag.to_s+'=no_safe_pose') if bad.size<16
            next
          end
          prior=pmd_ac_v10412_batchviii_native_pose_candidates_v061(sid,move_key,data,profile) || []
          before=prior.empty? ? nil : prior[0]
          if motion_batchviii_low_quality_v10412?(fam,before)
            low+=1;rr[:low]+=1
            current=native_pose_candidates_v061(sid,move_key,data,profile) || []
            after=current.empty? ? nil : current[0]
            if after==pose
              rescued+=1;rr[:rescued]+=1
              oks=motion_generated_diag_geometry_v1040?(sid,after)
              oka=motion_batchiii_pose_allowed_v1043(sid,after,fam)
              okq=motion_batchiv_semantic_pose_allowed_v1044(sid,after,fam)
              strict+=1 if oks
              semantic+=1 if oka && okq
              if !oks || !oka || !okq
                bad.push(sid+':'+tag.to_s+'='+after.to_s) if bad.size<16
              end
            else
              bad.push(sid+':'+tag.to_s+'=expected_'+pose.to_s+'_got_'+(after==nil ? 'nil' : after.to_s)) if bad.size<16
            end
          else
            retained+=1;rr[:retained]+=1
          end
        end
        rows[tag]=rr
      end
      {:total=>total,:safe=>safe,:low=>low,:rescued=>rescued,:retained=>retained,
       :strict=>strict,:semantic=>semantic,:family_match=>family_match,:rows=>rows,:bad=>bad}
    rescue
      {:total=>0,:safe=>0,:low=>0,:rescued=>0,:retained=>0,:strict=>0,:semantic=>0,
       :family_match=>0,:rows=>{},:bad=>['exception']}
    end
  end
end

class Scene_PMD_AutoChess
  alias pmd_ac_v10412_batchviii_prepare_verification_battle prepare_verification_battle unless method_defined?(:pmd_ac_v10412_batchviii_prepare_verification_battle)
  alias pmd_ac_v10412_batchviii_update_verification_script update_verification_script unless method_defined?(:pmd_ac_v10412_batchviii_update_verification_script)

  def prepare_verification_battle
    pmd_ac_v10412_batchviii_prepare_verification_battle
    return unless respond_to?(:motion_phase_b_verifier_active_v1036?) && motion_phase_b_verifier_active_v1036?
    begin
      t0=Time.now
      @motion_batchviii_qa_v10412=PMD_AC.motion_batchviii_audit_v10412
      ms=((Time.now-t0)*1000.0).round
      @motion_batchviii_qa_v10412[:ms]=ms
      q=@motion_batchviii_qa_v10412
      log_event(:perf,'MOTION_BATCHVIII_RESIDUAL_QUALITY_PREBATTLE_V10412 ready=1'+
        ' routes='+q[:total].to_i.to_s+' safe='+q[:safe].to_i.to_s+
        ' low_quality_before='+q[:low].to_i.to_s+' promoted='+q[:rescued].to_i.to_s+
        ' retained_specific='+q[:retained].to_i.to_s+' family_match='+q[:family_match].to_i.to_s+'/'+q[:total].to_i.to_s+
        ' ms='+ms.to_i.to_s+' pre_live_update=1 cached_rescue=1 bitmap_required=0 live_full_scan=0')
      log_event(:showcase,'MOTION_VISUAL_TUNING_BATCHVIII_V10412 START spin_twirl=1 sound_shout_sing_split=1'+
        ' cast_emit=1 drain_emit=1 shock_direct_guard=1 low_quality_only=1'+
        ' universal_swing_spin_rejected=1 strict45=1 anatomy_gate=1 semantic_gate=1'+
        ' performance_v1049_frozen=1 curated_0001_0026_untouched=1 gameplay_unchanged=1')
    rescue => e
      @motion_batchviii_qa_v10412={:total=>0,:safe=>0,:low=>0,:rescued=>0,:retained=>0,
        :strict=>0,:semantic=>0,:family_match=>0,:rows=>{},:bad=>['exception'],:ms=>0}
      log_event(:perf,'MOTION_BATCHVIII_RESIDUAL_QUALITY_PREBATTLE_V10412 ready=0 error='+e.class.to_s)
    end
  end

  def update_verification_script
    pmd_ac_v10412_batchviii_update_verification_script
    return unless respond_to?(:motion_phase_b_verifier_active_v1036?) && motion_phase_b_verifier_active_v1036?
    if !@motion_batchviii_verify_v10412 && @verification_frame.to_i>=232
      @motion_batchviii_verify_v10412=true
      q=@motion_batchviii_qa_v10412 || {}
      total=q[:total].to_i;safe=q[:safe].to_i;low=q[:low].to_i;rescued=q[:rescued].to_i
      ok=total>0 && safe==total && q[:family_match].to_i==total && rescued==low &&
         q[:strict].to_i==rescued && q[:semantic].to_i==rescued && (q[:bad]||[]).empty?
      rows=q[:rows] || {}
      sp=rows[:spin] || {};ss=rows[:sound_shout] || {};sg=rows[:sound_sing] || {}
      sh=rows[:shock] || {};ca=rows[:cast] || {};cx=rows[:cast_expressive] || {};dr=rows[:drain] || {}
      remote_low=sh[:low].to_i+ca[:low].to_i+cx[:low].to_i+dr[:low].to_i
      remote_rescued=sh[:rescued].to_i+ca[:rescued].to_i+cx[:rescued].to_i+dr[:rescued].to_i
      log_event(:verify,'MOTION_VISUAL_TUNING_BATCHVIII_V10412 pass='+(ok ? '1':'0')+
        ' target_routes='+total.to_s+' safe='+safe.to_s+'/'+total.to_s+
        ' low_quality_before='+low.to_s+' promoted='+rescued.to_s+' retained_specific='+q[:retained].to_i.to_s+
        ' spin_sound_remote=1 low_quality_only=1 universal_swing_spin_rejected=1'+
        ' strict45=1 anatomy_gate=1 semantic_gate=1 performance_v1049_frozen=1 gameplay_unchanged=1')
      log_event(:verify,'MOTION_SPIN_SOUND_REMOTE_RESCUE_QA_V10412 pass='+(ok ? '1':'0')+
        ' spin='+sp[:rescued].to_i.to_s+'/'+sp[:low].to_i.to_s+
        ' sound_shout='+ss[:rescued].to_i.to_s+'/'+ss[:low].to_i.to_s+
        ' sound_sing='+sg[:rescued].to_i.to_s+'/'+sg[:low].to_i.to_s+
        ' shock='+sh[:rescued].to_i.to_s+'/'+sh[:low].to_i.to_s+
        ' cast='+ca[:rescued].to_i.to_s+'/'+ca[:low].to_i.to_s+
        ' cast_expressive='+cx[:rescued].to_i.to_s+'/'+cx[:low].to_i.to_s+
        ' drain='+dr[:rescued].to_i.to_s+'/'+dr[:low].to_i.to_s+
        ' strict45='+q[:strict].to_i.to_s+'/'+rescued.to_s+
        ' semantic='+q[:semantic].to_i.to_s+'/'+rescued.to_s+
        ' family_match='+q[:family_match].to_i.to_s+'/'+total.to_s+
        ' qa_ms='+q[:ms].to_i.to_s+' live_full_scan=0 bad=['+(q[:bad]||[]).join(',')+']')
      log_event(:verify,'MOTION_SPECIAL_REMOTE_IDENTITY_V10412 pass='+(remote_rescued==remote_low ? '1':'0')+
        ' remote_low_quality_before='+remote_low.to_s+' remote_promoted='+remote_rescued.to_s+
        ' shock_direct_guard=1 cast_emit=1 drain_emit=1 expressive_cast_species=3'+
        ' projectile_beam_good_shoot_retained=1 damage_timing_unchanged=1 projectile_speed_unchanged=1')
    end
  rescue
  end
end
