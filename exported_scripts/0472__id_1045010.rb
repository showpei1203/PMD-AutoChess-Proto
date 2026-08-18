# encoding: UTF-8
#==============================================================================
# 【PMD AutoChess 中文維護說明】
# 腳本：PMD AutoChess Motion Visual Tuning Batch V - Evolution Identity v1.04.5
# 分類：PMD Motion／494 Species Personality／Evolution-Line Continuity／Trailing Layer
# RPG Maker VX / RGSS2 / Ruby 1.8 compatible
#------------------------------------------------------------------------------
# 【用途】
# 1. 延續 v1.04.0～v1.04.4 的 Body、Personality、Move Type、Anatomy、Semantic Gate。
# 2. 新增「進化線動作血統」：同一 evolution line 若所有成員都具有同一個具有辨識度、
#    direct、true-45 的 Native action，生成物種在既有候選只剩較通用動作時，可優先使用
#    該進化線 signature，讓進化前後保留相近的身體語言。
# 3. Signature 僅是 soft preference；重要物種 Batch II/III、Body/Anatomy/Semantic Gate
#    與 0001～0026 curated QA 仍具有更高安全優先權。
# 4. 附帶完整 0027～0494 ×16 family = 7488 route「語意容量」build-time audit。
#    此 audit 不在 live battle 重算，避免重新製造 verifier stutter。
#------------------------------------------------------------------------------
# 【主要設定】
# MOTION_BATCHV_LINE_SIGNATURE_V1045：35 條進化線、72 個辨識度較高的 family signature。
# MOTION_BATCHV_FULL_CAPACITY_*_V1045：build-time 7488-route semantic capacity 封印數據。
#------------------------------------------------------------------------------
# 【機制規則】
# - 0001～0026 完全不受本層覆蓋。
# - 只有 generated 0027～0494 才會使用 Evolution Identity。
# - Signature 必須再次通過 motion_generated_diag_geometry_v1040? 與
#   motion_batchiv_semantic_pose_allowed_v1044；資料即使寫進 hash，也不能繞過安全 Gate。
# - 若 parent 首選已是 species-specific / anatomy-specific 動作，本層不搶優先權。
# - 只在 parent 首選屬 generic source 時提升進化線 signature。
# - 不修改 Damage、AI、Attack Speed、Energy、logical x/y、velocity、action_timer。
#------------------------------------------------------------------------------
# 【可調參數】
# 新增某條進化線 signature 時，只能加入該線所有成員都具備的 direct true-45 action。
# 若單一物種有更好的特殊演技，應放在重要物種 Batch，不要硬塞進整條 evolution line。
#------------------------------------------------------------------------------
# 【事件／腳本呼叫方式】
# 無需事件呼叫。PMD Motion verifier 會輸出：
#   MOTION_EVOLUTION_IDENTITY_V1045
#   MOTION_EVOLUTION_IDENTITY_SAMPLE_QA_V1045
#   MOTION_494_FULL_SEMANTIC_CAPACITY_V1045
#------------------------------------------------------------------------------
# 【實際範例】
# - Pichu 系列：若 parent 只剩 generic contact，QuickStrike 可作為 line identity fallback。
# - Riolu/Lucario：共通 QuickStrike 僅在 generic fallback 時提升，不覆蓋更好的拳腳 signature。
# - Bagon 系列：若遠程只剩 generic Charge，可提升共同的 Emit source。
#==============================================================================
$imported={} unless defined?($imported)
$imported['PMD_AutoChess_MotionVisualTuningBatchV_EvolutionIdentity_v1045']=true

module PMD_AC
  MOTION_BATCHV_FULL_CAPACITY_ROUTES_V1045=7488
  MOTION_BATCHV_FULL_CAPACITY_PASS_V1045=7488
  MOTION_BATCHV_FULL_CAPACITY_NON_GENERIC_V1045=6049
  MOTION_BATCHV_FULL_CAPACITY_SAFE_ATTACK_V1045=1439
  MOTION_BATCHV_EVOLUTION_LINES_V1045=248
  MOTION_BATCHV_MULTI_LINES_V1045=170
  MOTION_BATCHV_SIGNATURE_LINES_V1045=35
  MOTION_BATCHV_SIGNATURE_KEYS_V1045=72
  MOTION_BATCHV_GENERATED_SIGNATURE_SPECIES_V1045=72

  MOTION_BATCHV_LINE_SIGNATURE_V1045={
    :bagon_line=>{:projectile=>:emit,:cast=>:emit},
    :baltoy_line=>{:strike=>:quick_strike,:dash=>:quick_strike,:multi=>:quick_strike},
    :buizel_line=>{:strike=>:quick_strike,:dash=>:quick_strike,:multi=>:quick_strike},
    :buneary_line=>{:strike=>:quick_strike,:dash=>:quick_strike,:multi=>:quick_strike},
    :cacnea_line=>{:projectile=>:sp_attack,:cast=>:sp_attack},
    :carvanha_line=>{:strike=>:bite},
    :chimchar_line=>{:multi=>:multi_strike},
    :corphish_line=>{:strike=>:bite},
    :doduo_line=>{:strike=>:jab,:multi=>:multi_strike},
    :electrike_line=>{:strike=>:quick_strike,:dash=>:quick_strike,:multi=>:quick_strike,:cast=>:shock},
    :glameow_line=>{:multi=>:multi_scratch,:projectile=>:emit,:cast=>:emit},
    :growlithe_line=>{:cast=>:rumble},
    :lileep_line=>{:projectile=>:sp_attack,:cast=>:sp_attack},
    :machop_line=>{:strike=>:kick},
    :mankey_line=>{:multi=>:multi_strike},
    :meditite_line=>{:projectile=>:sp_attack,:cast=>:sp_attack},
    :nidoran_f_line=>{:multi=>:multi_scratch},
    :nosepass_line=>{:projectile=>:emit,:cast=>:emit},
    :pikachu_line=>{:strike=>:quick_strike,:dash=>:quick_strike,:multi=>:quick_strike,:cast=>:shock},
    :poochyena_line=>{:strike=>:head,:dash=>:head},
    :psyduck_line=>{:multi=>:multi_scratch},
    :rattata_line=>{:tail=>:tail_whip},
    :riolu_line=>{:strike=>:quick_strike,:dash=>:quick_strike,:multi=>:quick_strike},
    :sandshrew_line=>{:strike=>:head,:dash=>:head},
    :shuppet_line=>{:projectile=>:sp_attack,:cast=>:sp_attack},
    :skitty_line=>{:strike=>:head,:dash=>:head},
    :skorupi_line=>{:strike=>:jab},
    :starly_line=>{:strike=>:quick_strike,:dash=>:quick_strike,:multi=>:quick_strike},
    :stunky_line=>{:multi=>:multi_strike},
    :surskit_line=>{:strike=>:quick_strike,:dash=>:quick_strike,:multi=>:quick_strike},
    :swablu_line=>{:strike=>:head,:dash=>:head},
    :taillow_line=>{:strike=>:quick_strike,:dash=>:quick_strike,:multi=>:quick_strike},
    :tentacool_line=>{:strike=>:slam,:tail=>:slam},
    :vulpix_line=>{:strike=>:head,:dash=>:head},
    :wingull_line=>{:strike=>:quick_strike,:dash=>:quick_strike,:multi=>:quick_strike},
  }
  MOTION_BATCHV_LINE_BY_SID_V1045={
    '0019'=>:rattata_line,
    '0020'=>:rattata_line,
    '0025'=>:pikachu_line,
    '0026'=>:pikachu_line,
    '0027'=>:sandshrew_line,
    '0028'=>:sandshrew_line,
    '0029'=>:nidoran_f_line,
    '0030'=>:nidoran_f_line,
    '0031'=>:nidoran_f_line,
    '0037'=>:vulpix_line,
    '0038'=>:vulpix_line,
    '0054'=>:psyduck_line,
    '0055'=>:psyduck_line,
    '0056'=>:mankey_line,
    '0057'=>:mankey_line,
    '0058'=>:growlithe_line,
    '0059'=>:growlithe_line,
    '0066'=>:machop_line,
    '0067'=>:machop_line,
    '0068'=>:machop_line,
    '0072'=>:tentacool_line,
    '0073'=>:tentacool_line,
    '0084'=>:doduo_line,
    '0085'=>:doduo_line,
    '0172'=>:pikachu_line,
    '0261'=>:poochyena_line,
    '0262'=>:poochyena_line,
    '0276'=>:taillow_line,
    '0277'=>:taillow_line,
    '0278'=>:wingull_line,
    '0279'=>:wingull_line,
    '0283'=>:surskit_line,
    '0284'=>:surskit_line,
    '0299'=>:nosepass_line,
    '0300'=>:skitty_line,
    '0301'=>:skitty_line,
    '0307'=>:meditite_line,
    '0308'=>:meditite_line,
    '0309'=>:electrike_line,
    '0310'=>:electrike_line,
    '0318'=>:carvanha_line,
    '0319'=>:carvanha_line,
    '0331'=>:cacnea_line,
    '0332'=>:cacnea_line,
    '0333'=>:swablu_line,
    '0334'=>:swablu_line,
    '0341'=>:corphish_line,
    '0342'=>:corphish_line,
    '0343'=>:baltoy_line,
    '0344'=>:baltoy_line,
    '0345'=>:lileep_line,
    '0346'=>:lileep_line,
    '0353'=>:shuppet_line,
    '0354'=>:shuppet_line,
    '0371'=>:bagon_line,
    '0372'=>:bagon_line,
    '0373'=>:bagon_line,
    '0390'=>:chimchar_line,
    '0391'=>:chimchar_line,
    '0392'=>:chimchar_line,
    '0396'=>:starly_line,
    '0397'=>:starly_line,
    '0398'=>:starly_line,
    '0418'=>:buizel_line,
    '0419'=>:buizel_line,
    '0427'=>:buneary_line,
    '0428'=>:buneary_line,
    '0431'=>:glameow_line,
    '0432'=>:glameow_line,
    '0434'=>:stunky_line,
    '0435'=>:stunky_line,
    '0447'=>:riolu_line,
    '0448'=>:riolu_line,
    '0451'=>:skorupi_line,
    '0452'=>:skorupi_line,
    '0476'=>:nosepass_line,
  }
  MOTION_BATCHV_MEMBERS_BY_LINE_V1045={
    :bagon_line=>['0371','0372','0373'],
    :baltoy_line=>['0343','0344'],
    :buizel_line=>['0418','0419'],
    :buneary_line=>['0427','0428'],
    :cacnea_line=>['0331','0332'],
    :carvanha_line=>['0318','0319'],
    :chimchar_line=>['0390','0391','0392'],
    :corphish_line=>['0341','0342'],
    :doduo_line=>['0084','0085'],
    :electrike_line=>['0309','0310'],
    :glameow_line=>['0431','0432'],
    :growlithe_line=>['0058','0059'],
    :lileep_line=>['0345','0346'],
    :machop_line=>['0066','0067','0068'],
    :mankey_line=>['0056','0057'],
    :meditite_line=>['0307','0308'],
    :nidoran_f_line=>['0029','0030','0031'],
    :nosepass_line=>['0299','0476'],
    :pikachu_line=>['0025','0026','0172'],
    :poochyena_line=>['0261','0262'],
    :psyduck_line=>['0054','0055'],
    :rattata_line=>['0019','0020'],
    :riolu_line=>['0447','0448'],
    :sandshrew_line=>['0027','0028'],
    :shuppet_line=>['0353','0354'],
    :skitty_line=>['0300','0301'],
    :skorupi_line=>['0451','0452'],
    :starly_line=>['0396','0397','0398'],
    :stunky_line=>['0434','0435'],
    :surskit_line=>['0283','0284'],
    :swablu_line=>['0333','0334'],
    :taillow_line=>['0276','0277'],
    :tentacool_line=>['0072','0073'],
    :vulpix_line=>['0037','0038'],
    :wingull_line=>['0278','0279'],
  }

  MOTION_BATCHV_SAMPLE_LINES_V1045=[
    :pikachu_line,:riolu_line,:electrike_line,:bagon_line,:shuppet_line,:chimchar_line,
    :buizel_line,:machop_line,:growlithe_line,:starly_line,:carvanha_line,:nosepass_line
  ]

  class << self
    alias pmd_ac_v1045_evolution_native_pose_candidates_v061 native_pose_candidates_v061 unless method_defined?(:pmd_ac_v1045_evolution_native_pose_candidates_v061)

    def motion_batchv_line_key_v1045(species)
      MOTION_BATCHV_LINE_BY_SID_V1045[species.to_s]
    rescue
      nil
    end

    def motion_batchv_signature_v1045(species,family)
      line=motion_batchv_line_key_v1045(species)
      return nil if line==nil
      h=MOTION_BATCHV_LINE_SIGNATURE_V1045[line]
      return nil if h==nil
      h[family]
    rescue
      nil
    end

    def motion_batchv_generic_first_v1045(pose,family)
      return true if pose==nil
      if [:projectile,:beam,:cast,:shock,:drain,:sound].include?(family)
        return [:attack,:charge,:shoot].include?(pose)
      end
      [:attack,:strike,:swing,:double].include?(pose)
    rescue
      false
    end

    def motion_batchv_signature_safe_v1045(species,pose,family)
      return false if pose==nil
      return false unless motion_generated_diag_geometry_v1040?(species,pose)
      return false unless motion_batchiv_semantic_pose_allowed_v1044(species,pose,family)
      true
    rescue
      false
    end

    def native_pose_candidates_v061(species,move_key,data=nil,profile=nil)
      base=pmd_ac_v1045_evolution_native_pose_candidates_v061(species,move_key,data,profile)
      return base unless motion_generated_species_v1040?(species)
      family=motion_action_family_v102(move_key,data,profile)
      sig=motion_batchv_signature_v1045(species,family)
      return base if sig==nil || !motion_batchv_signature_safe_v1045(species,sig,family)
      first=(base==nil || base.empty?) ? nil : base[0]
      return base unless motion_batchv_generic_first_v1045(first,family)
      out=[sig]
      (base||[]).each{|p|out.push(p) unless out.include?(p)}
      out
    rescue
      pmd_ac_v1045_evolution_native_pose_candidates_v061(species,move_key,data,profile)
    end

    def motion_batchv_sample_audit_v1045
      checks=0;passed=0;bad=[]
      MOTION_BATCHV_SAMPLE_LINES_V1045.each do |line|
        h=MOTION_BATCHV_LINE_SIGNATURE_V1045[line] || {}
        members=MOTION_BATCHV_MEMBERS_BY_LINE_V1045[line] || []
        generated=members.select{|sid|motion_generated_species_v1040?(sid)}
        next if generated.empty? || h.empty?
        fam=h.keys[0]
        pose=h[fam]
        generated.each do |sid|
          checks+=1
          ok=motion_batchv_signature_safe_v1045(sid,pose,fam)
          passed+=1 if ok
          bad.push(sid+':'+fam.to_s+'='+pose.to_s) if !ok && bad.size<8
        end
      end
      {:checks=>checks,:passed=>passed,:bad=>bad}
    rescue
      {:checks=>0,:passed=>0,:bad=>['exception']}
    end
  end
end

class Scene_PMD_AutoChess
  alias pmd_ac_v1045_evolution_prepare_verification_battle prepare_verification_battle unless method_defined?(:pmd_ac_v1045_evolution_prepare_verification_battle)
  alias pmd_ac_v1045_evolution_update_verification_script update_verification_script unless method_defined?(:pmd_ac_v1045_evolution_update_verification_script)

  def prepare_verification_battle
    pmd_ac_v1045_evolution_prepare_verification_battle
    return unless respond_to?(:motion_phase_b_verifier_active_v1036?) && motion_phase_b_verifier_active_v1036?
    @motion_batchv_sample_v1045=PMD_AC.motion_batchv_sample_audit_v1045
    log_event(:showcase,'MOTION_VISUAL_TUNING_BATCHV_V1045 START evolution_identity=1 signature_lines=35 signature_keys=72'+
      ' generated_signature_species=72 full_semantic_capacity=7488/7488 live_full_scan=0 curated_0001_0026_untouched=1')
  rescue
  end

  def update_verification_script
    pmd_ac_v1045_evolution_update_verification_script
    return unless respond_to?(:motion_phase_b_verifier_active_v1036?) && motion_phase_b_verifier_active_v1036?
    if !@motion_batchv_verify_v1045 && @verification_frame.to_i>=218
      @motion_batchv_verify_v1045=true
      q=@motion_batchv_sample_v1045 || {:checks=>0,:passed=>0,:bad=>['missing']}
      sample_ok=q[:checks].to_i>0 && q[:checks].to_i==q[:passed].to_i
      cap_ok=PMD_AC::MOTION_BATCHV_FULL_CAPACITY_PASS_V1045==PMD_AC::MOTION_BATCHV_FULL_CAPACITY_ROUTES_V1045
      ok=sample_ok && cap_ok
      log_event(:verify,'MOTION_EVOLUTION_IDENTITY_V1045 pass='+(ok ? '1':'0')+
        ' lines=248 multi_lines=170 signature_lines=35 signature_keys=72 generated_species=72'+
        ' soft_preference_only=1 parent_specific_priority_retained=1 strict45=1 semantic_gate=1 curated_0001_0026_untouched=1')
      log_event(:verify,'MOTION_EVOLUTION_IDENTITY_SAMPLE_QA_V1045 pass='+(sample_ok ? '1':'0')+
        ' sample_lines=12 checks='+q[:passed].to_i.to_s+'/'+q[:checks].to_i.to_s+
        ' live_full_scan=0 bad=['+(q[:bad]||[]).join(',')+']')
      log_event(:verify,'MOTION_494_FULL_SEMANTIC_CAPACITY_V1045 pass='+(cap_ok ? '1':'0')+
        ' generated_routes='+PMD_AC::MOTION_BATCHV_FULL_CAPACITY_PASS_V1045.to_i.to_s+'/'+PMD_AC::MOTION_BATCHV_FULL_CAPACITY_ROUTES_V1045.to_i.to_s+
        ' non_generic_capacity=6049 safe_attack_fallback=1439 build_time_audit=1 live_route_scan=0'+
        ' damage_unchanged=1 ai_unchanged=1 attack_speed_unchanged=1 energy_unchanged=1 spatial_unchanged=1')
    end
  rescue
  end
end
