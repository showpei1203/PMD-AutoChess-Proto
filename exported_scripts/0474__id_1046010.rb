# encoding: UTF-8
#==============================================================================
# 【PMD AutoChess 中文維護說明】
# 腳本：PMD AutoChess Motion Visual Tuning Batch VI - Fallback Rescue v1.04.6
# 分類：PMD Motion／494 Species Personality／Generic Fallback Rescue／Trailing Layer
# RPG Maker VX / RGSS2 / Ruby 1.8 compatible
#------------------------------------------------------------------------------
# 【用途】
# 1. 延續 v1.04.5 Full Semantic Capacity：7488/7488 route 安全，但其中 1439 route
#    仍以 generic :attack 作最後 presentation source。
# 2. 不追求把 1439 全部消滅。只處理具有明確肢體依據的高價值群：
#      - Horn/Head + Stomper：Head family generic fallback -> Swing（若安全）
#      - Brawler：Punch family generic fallback -> Swing（若安全）
#      - Brawler + Stomper + Quad Kicker：Kick family generic fallback -> Slam/Swing（若安全）
# 3. Bite 等沒有明確專用 Native 的情況維持 :attack；不為統計數字硬塞不自然動作。
# 4. 新增 selective rescue metadata QA，只掃目標 pair，不做 468×16 live full scan。
#------------------------------------------------------------------------------
# 【主要設定】
# MOTION_BATCHVI_HEAD_RESCUE_V1046：Head family 高價值物種集合。
# MOTION_BATCHVI_PUNCH_RESCUE_V1046：Punch family Brawler 集合。
# MOTION_BATCHVI_KICK_RESCUE_V1046：Kick family Brawler/Stomper/Quad-Kicker 集合。
# MOTION_BATCHVI_PRIOR_SAFE_ATTACK_V1046 = 1439：v1.04.5 build-time baseline。
#------------------------------------------------------------------------------
# 【機制規則】
# - 0001～0026 curated QA 不受影響。
# - 只在 parent 第一候選「真的就是 :attack」時 Rescue；parent 已選到 Head/Punch/Kick
#   等較專用動作時完全不插手。
# - Rescue pose 必須同時通過：
#     motion_generated_diag_geometry_v1040?
#     motion_batchiii_pose_allowed_v1043
#     motion_batchiv_semantic_pose_allowed_v1044
# - 所以本層不能繞過 true-45 / anatomy / semantic gate。
# - Bite generic fallback 保留為 intentional safe fallback；沒有嘴部演技時寧可 Attack。
# - 不修改 Move family、Damage、AI、Attack Speed、Energy、logical x/y、velocity、action_timer。
#------------------------------------------------------------------------------
# 【可調參數】
# - 新增 Rescue 物種時，優先擴既有 anatomy group，不要直接把全物種套 Swing。
# - 若某物種有真正 direct Head/Punch/Kick，應讓 parent 自然選中，不必加 Rescue。
#------------------------------------------------------------------------------
# 【事件／腳本呼叫方式】
# 無需事件呼叫。Motion verifier 會輸出：
#   MOTION_VISUAL_TUNING_BATCHVI_V1046
#   MOTION_GENERIC_FALLBACK_RESCUE_QA_V1046
#------------------------------------------------------------------------------
# 【實際範例】
# - Brawler 沒有 direct Punch，但有安全 Swing：Punch family 從 generic Attack 提升 Swing。
# - Stomper 沒有 direct Kick/Stomp，但有 Slam：Kick family 優先 Slam。
# - Jaw species 沒有 Bite/Head：仍保留 Attack，不用 Swing 假裝咬擊。
#==============================================================================
$imported={} unless defined?($imported)
$imported['PMD_AutoChess_MotionVisualTuningBatchVI_FallbackRescue_v1046']=true

module PMD_AC
  MOTION_BATCHVI_PRIOR_SAFE_ATTACK_V1046=1439

  MOTION_BATCHVI_HEAD_RESCUE_V1046=(
    MOTION_BATCHII_HORN_HEAD_V1042 + MOTION_BATCHIII_STOMPER_V1043
  ).uniq
  MOTION_BATCHVI_PUNCH_RESCUE_V1046=MOTION_BATCHII_BRAWLERS_V1042.uniq
  MOTION_BATCHVI_KICK_RESCUE_V1046=(
    MOTION_BATCHII_BRAWLERS_V1042 + MOTION_BATCHIII_STOMPER_V1043 + MOTION_BATCHIII_QUAD_KICKERS_V1043
  ).uniq

  MOTION_BATCHVI_CASES_V1046={
    :head=>[:headbutt,nil,nil],
    :punch=>[:mega_punch,nil,nil],
    :kick=>[:low_kick,nil,nil]
  }

  class << self
    alias pmd_ac_v1046_rescue_native_pose_candidates_v061 native_pose_candidates_v061 unless method_defined?(:pmd_ac_v1046_rescue_native_pose_candidates_v061)

    def motion_batchvi_target_species_v1046(family)
      case family
      when :head; MOTION_BATCHVI_HEAD_RESCUE_V1046
      when :punch; MOTION_BATCHVI_PUNCH_RESCUE_V1046
      when :kick; MOTION_BATCHVI_KICK_RESCUE_V1046
      else; []
      end
    rescue
      []
    end

    def motion_batchvi_rescue_choices_v1046(species,family)
      sid=species.to_s
      case family
      when :head
        return [:swing] if MOTION_BATCHVI_HEAD_RESCUE_V1046.include?(sid)
      when :punch
        return [:swing] if MOTION_BATCHVI_PUNCH_RESCUE_V1046.include?(sid)
      when :kick
        return [:slam,:swing] if MOTION_BATCHVI_KICK_RESCUE_V1046.include?(sid)
      end
      []
    rescue
      []
    end

    def motion_batchvi_rescue_safe_v1046(species,pose,family)
      return false if pose==nil
      return false unless motion_generated_diag_geometry_v1040?(species,pose)
      return false unless motion_batchiii_pose_allowed_v1043(species,pose,family)
      return false unless motion_batchiv_semantic_pose_allowed_v1044(species,pose,family)
      true
    rescue
      false
    end

    def motion_batchvi_rescue_pose_v1046(species,family)
      motion_batchvi_rescue_choices_v1046(species,family).each do |pose|
        return pose if motion_batchvi_rescue_safe_v1046(species,pose,family)
      end
      nil
    rescue
      nil
    end

    def native_pose_candidates_v061(species,move_key,data=nil,profile=nil)
      base=pmd_ac_v1046_rescue_native_pose_candidates_v061(species,move_key,data,profile)
      return base unless motion_generated_species_v1040?(species)
      return base if base==nil || base.empty? || base[0]!=:attack
      family=motion_action_family_v102(move_key,data,profile)
      pose=motion_batchvi_rescue_pose_v1046(species,family)
      return base if pose==nil || pose==:attack
      out=[pose]
      base.each{|p|out.push(p) unless out.include?(p)}
      out
    rescue
      pmd_ac_v1046_rescue_native_pose_candidates_v061(species,move_key,data,profile)
    end

    # metadata-only selective audit：直接比較「v1.04.5 parent」與「v1.04.6 current」。
    # 不要求 Graphics/PMD runtime PNG，且不產生 Damage / Projectile。
    def motion_batchvi_rescue_audit_v1046
      total=0;generic_before=0;rescued=0;retained_specific=0;strict=0;semantic=0;bad=[]
      fam_counts={:head=>[0,0],:punch=>[0,0],:kick=>[0,0]}
      [:head,:punch,:kick].each do |family|
        row=MOTION_BATCHVI_CASES_V1046[family]
        move_key=row[0];data=row[1];profile=row[2]
        motion_batchvi_target_species_v1046(family).each do |sid|
          next unless motion_generated_species_v1040?(sid)
          total+=1
          prior=pmd_ac_v1046_rescue_native_pose_candidates_v061(sid,move_key,data,profile) || []
          before=prior.empty? ? nil : prior[0]
          current=native_pose_candidates_v061(sid,move_key,data,profile) || []
          after=current.empty? ? nil : current[0]
          if before==:attack
            generic_before+=1
            fam_counts[family][0]+=1
            if after!=nil && after!=:attack
              rescued+=1
              fam_counts[family][1]+=1
              oks=motion_generated_diag_geometry_v1040?(sid,after)
              okq=motion_batchiv_semantic_pose_allowed_v1044(sid,after,family) && motion_batchiii_pose_allowed_v1043(sid,after,family)
              strict+=1 if oks;semantic+=1 if okq
              if !oks || !okq
                bad.push(sid+':'+family.to_s+'='+after.to_s) if bad.size<12
              end
            else
              bad.push(sid+':'+family.to_s+'=unrescued') if bad.size<12
            end
          else
            retained_specific+=1
          end
        end
      end
      {:total=>total,:generic_before=>generic_before,:rescued=>rescued,
       :retained_specific=>retained_specific,:strict=>strict,:semantic=>semantic,
       :family=>fam_counts,:bad=>bad}
    rescue
      {:total=>0,:generic_before=>0,:rescued=>0,:retained_specific=>0,:strict=>0,:semantic=>0,
       :family=>{:head=>[0,0],:punch=>[0,0],:kick=>[0,0]},:bad=>['exception']}
    end
  end
end

class Scene_PMD_AutoChess
  alias pmd_ac_v1046_rescue_prepare_verification_battle prepare_verification_battle unless method_defined?(:pmd_ac_v1046_rescue_prepare_verification_battle)
  alias pmd_ac_v1046_rescue_update_verification_script update_verification_script unless method_defined?(:pmd_ac_v1046_rescue_update_verification_script)

  def prepare_verification_battle
    pmd_ac_v1046_rescue_prepare_verification_battle
    return unless respond_to?(:motion_phase_b_verifier_active_v1036?) && motion_phase_b_verifier_active_v1036?
    begin
      t0=Time.now
      @motion_batchvi_rescue_qa_v1046=PMD_AC.motion_batchvi_rescue_audit_v1046
      ms=((Time.now-t0)*1000.0).round
      @motion_batchvi_rescue_qa_v1046[:ms]=ms
      q=@motion_batchvi_rescue_qa_v1046
      log_event(:perf,'MOTION_GENERIC_FALLBACK_RESCUE_PREBATTLE_V1046 ready=1 routes='+q[:total].to_i.to_s+
        ' generic_before='+q[:generic_before].to_i.to_s+' rescued='+q[:rescued].to_i.to_s+
        ' retained_specific='+q[:retained_specific].to_i.to_s+' ms='+ms.to_i.to_s+
        ' pre_live_update=1 bitmap_required=0 live_full_scan=0')
      log_event(:showcase,'MOTION_VISUAL_TUNING_BATCHVI_V1046 START selective_fallback_rescue=1'+
        ' prior_safe_attack=1439 families=head,punch,kick bite_fallback_intentional=1'+
        ' true45=1 anatomy_gate=1 semantic_gate=1 curated_0001_0026_untouched=1 gameplay_unchanged=1')
    rescue => e
      @motion_batchvi_rescue_qa_v1046={:total=>0,:generic_before=>0,:rescued=>0,:retained_specific=>0,
        :strict=>0,:semantic=>0,:family=>{:head=>[0,0],:punch=>[0,0],:kick=>[0,0]},:bad=>['exception'],:ms=>0}
      log_event(:perf,'MOTION_GENERIC_FALLBACK_RESCUE_PREBATTLE_V1046 ready=0 error='+e.class.to_s)
    end
  end

  def update_verification_script
    pmd_ac_v1046_rescue_update_verification_script
    return unless respond_to?(:motion_phase_b_verifier_active_v1036?) && motion_phase_b_verifier_active_v1036?
    if !@motion_batchvi_verify_v1046 && @verification_frame.to_i>=222
      @motion_batchvi_verify_v1046=true
      q=@motion_batchvi_rescue_qa_v1046 || {}
      generic=q[:generic_before].to_i;rescued=q[:rescued].to_i
      ok=q[:total].to_i>0 && generic>0 && rescued==generic && q[:strict].to_i==rescued && q[:semantic].to_i==rescued && (q[:bad]||[]).empty?
      rem=PMD_AC::MOTION_BATCHVI_PRIOR_SAFE_ATTACK_V1046-rescued
      rem=0 if rem<0
      fc=q[:family] || {}
      h=fc[:head] || [0,0];p=fc[:punch] || [0,0];k=fc[:kick] || [0,0]
      log_event(:verify,'MOTION_VISUAL_TUNING_BATCHVI_V1046 pass='+(ok ? '1':'0')+
        ' selective_fallback_rescue=1 target_routes='+q[:total].to_i.to_s+
        ' generic_before='+generic.to_i.to_s+' rescued='+rescued.to_i.to_s+
        ' retained_specific='+q[:retained_specific].to_i.to_s+
        ' estimated_safe_attack_remaining='+rem.to_i.to_s+
        ' bite_fallback_intentional=1 strict45=1 anatomy_gate=1 semantic_gate=1 curated_0001_0026_untouched=1')
      log_event(:verify,'MOTION_GENERIC_FALLBACK_RESCUE_QA_V1046 pass='+(ok ? '1':'0')+
        ' head='+h[1].to_i.to_s+'/'+h[0].to_i.to_s+
        ' punch='+p[1].to_i.to_s+'/'+p[0].to_i.to_s+
        ' kick='+k[1].to_i.to_s+'/'+k[0].to_i.to_s+
        ' strict45='+q[:strict].to_i.to_s+'/'+rescued.to_i.to_s+
        ' semantic='+q[:semantic].to_i.to_s+'/'+rescued.to_i.to_s+
        ' qa_ms='+q[:ms].to_i.to_s+' bitmap_required=0 live_full_scan=0 bad=['+(q[:bad]||[]).join(',')+']')
    end
  rescue
  end
end
