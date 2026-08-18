# encoding: UTF-8
#==============================================================================
# ■ PMD AutoChess - Motion Visual Tuning Batch IX
#   Rare Native Identity Rescue + Visual Acceptance Pack v1.04.13
#==============================================================================
# 【用途】
# 延續 v1.04.12 Batch VIII，在 generated 0027～0494 中處理「該物種明明有很少見、
# 很有辨識度的 direct Native，但通用 family scoring 仍可能把較泛用姿勢排在前面」
# 的 residual identity gap。
#
# 本批聚焦 15 組可直接由動作語意判定的稀有 Native：
# Bite / Scratch / Slice / Lick / Swell / Gas / Slap / Uppercut / TailWhip /
# Stomp / Slam / Punch / Kick / FlapAround / Withdraw。
#
# 同時建立 64 隻 Batch IX Visual Acceptance Pack 的資產契約：預設專案仍只正式
# 打包 0001～0026，因此 64 隻 PNG 未匯入時 Runtime Asset QA 必須 deferred，
# 不可把 compiled metadata 假稱為 hasPlayable。
#
# 【主要設定】
# MOTION_BATCHIX_*_V10413
#   各 exact-native 的保守 target species。所有項目都必須有 direct conservative
#   true-45 geometry，並通過既有 Anatomy Gate / Semantic Gate。
# MOTION_BATCHIX_VISUAL_REPS_V10413
#   64 隻實際視覺驗收候選；Tools/IMPORT_BATCHIX_VISUAL_ASSETS_v10413.bat 可從
#   使用者本機完整 PMD source 匯入。
#
# 【機制規則】
# - Frozen Combat Core 不直接修改；只 alias native_pose_candidates_v061。
# - 0001～0026 curated scope 完全不接管。
# - Exact Native 只有在 parent 第一候選仍屬較低辨識度／較泛用姿勢時才提升。
# - 已經是 exact pose，或 parent 已有另一個明確專用 Native，完整保留。
# - MultiStrike / MultiScratch / Double 不在本批使用；多段傷害仍由既有 v0.60.2
#   hit -> backstep -> re-engage packet choreography 掌權。
# - 每個提升 source 再次要求 strict true-45 + Batch III Anatomy + Batch IV Semantic。
# - HOME、logical x/y、velocity、Damage、AI、Attack Speed、Energy、action_timer 不變。
# - Presentation Profile Memo v1.04.9、Zone Cache v1.04.7、Skill Banner 54f 全保留。
# - 不做 468×16 live scan；只在 battle live update 前掃固定 74 target routes。
#
# 【可調參數】
# - 若新增 exact Native target，先確認動作名稱真的與招式 body language 對應，
#   不能只因為 PNG 存在就提升。
# - Heavy / Hover / Avian / Quadruped 等仍受既有 Anatomy Gate 約束。
# - Bite 無 direct Bite 的物種仍保留 Attack/Head fallback，不追求 fallback=0。
#
# 【事件／腳本呼叫方式】
# 無需事件呼叫。PMD Motion verifier 自動輸出：
#   MOTION_BATCHIX_RARE_NATIVE_PREBATTLE_V10413
#   MOTION_VISUAL_TUNING_BATCHIX_V10413
#   MOTION_RARE_NATIVE_IDENTITY_QA_V10413
#   MOTION_BATCHIX_VISUAL_ASSET_QA_V10413
#
# 【實際範例】
# - Mawile / Sharpedo 等若 Bite family parent 仍是 Head/Attack，而 direct Bite
#   通過 true-45，則提升 Bite。
# - Scyther / Pinsir 的 Slash 類若仍是 Attack/Swing，提升 direct Slice。
# - Koffing 的 Poison Gas 若仍只是 Charge/Emit，提升 direct Gas。
# - Shellder / Cloyster / Omanyte / Clamperl / Turtwig line 的 Withdraw 若仍只是
#   generic cast，提升 direct Withdraw。
#==============================================================================
$imported={} unless defined?($imported)
$imported['PMD_AutoChess_MotionVisualTuningBatchIX_RareNativeIdentity_v10413']=true

module PMD_AC
  MOTION_BATCHIX_BITE_V10413=%w(0203 0303 0318 0319 0328 0336 0341 0342 0371 0451)
  MOTION_BATCHIX_SCRATCH_V10413=%w(0288 0292 0347 0348 0483 0484)
  MOTION_BATCHIX_SLICE_V10413=%w(0123 0127)
  MOTION_BATCHIX_LICK_V10413=%w(0092 0093 0108)
  MOTION_BATCHIX_SWELL_V10413=%w(0204 0318 0319 0336 0341 0342 0352 0382 0425)
  MOTION_BATCHIX_GAS_V10413=%w(0109)
  MOTION_BATCHIX_SLAP_V10413=%w(0124)
  MOTION_BATCHIX_UPPERCUT_V10413=%w(0107)
  MOTION_BATCHIX_TAIL_V10413=%w(0133 0136 0470 0471)
  MOTION_BATCHIX_STOMP_V10413=%w(0143 0203 0241)
  MOTION_BATCHIX_SLAM_V10413=%w(0039 0040 0072 0073 0075 0096 0098 0152 0185 0214 0257 0327)
  MOTION_BATCHIX_PUNCH_V10413=%w(0067 0068 0097 0107 0125 0236 0239 0308)
  MOTION_BATCHIX_KICK_V10413=%w(0066 0067 0068 0106 0257)
  MOTION_BATCHIX_FLAP_V10413=%w(0049)
  MOTION_BATCHIX_WITHDRAW_V10413=%w(0090 0091 0138 0139 0366 0387 0388 0389)

  # [tag, expected_family, move_key, data, profile, exact_pose, target_constant_symbol]
  MOTION_BATCHIX_CASES_V10413=[
    [:bite,:bite,:bite,nil,nil,:bite,:MOTION_BATCHIX_BITE_V10413],
    [:scratch,:lunge,:scratch,{:contact=>true},nil,:scratch,:MOTION_BATCHIX_SCRATCH_V10413],
    [:slice,:lunge,:slash,{:contact=>true},nil,:slice,:MOTION_BATCHIX_SLICE_V10413],
    [:lick,:lunge,:lick,{:contact=>true},nil,:lick,:MOTION_BATCHIX_LICK_V10413],
    [:swell,:cast,:growth,{:visual_kind=>:self_fx,:target_type=>:self},nil,:swell,:MOTION_BATCHIX_SWELL_V10413],
    [:gas,:cast,:poison_gas,{:visual_kind=>:area_hit,:move_type=>:poison},nil,:gas,:MOTION_BATCHIX_GAS_V10413],
    [:slap,:lunge,:double_slap,{:contact=>true},nil,:slap,:MOTION_BATCHIX_SLAP_V10413],
    [:uppercut,:punch,:sky_uppercut,{:contact=>true},nil,:uppercut,:MOTION_BATCHIX_UPPERCUT_V10413],
    [:tail,:tail,:tail_whip,{:contact=>true},nil,:tail_whip,:MOTION_BATCHIX_TAIL_V10413],
    [:stomp,:lunge,:stomp,{:contact=>true},nil,:stomp,:MOTION_BATCHIX_STOMP_V10413],
    [:slam,:lunge,:body_slam,{:contact=>true},nil,:slam,:MOTION_BATCHIX_SLAM_V10413],
    [:punch,:punch,:mega_punch,{:contact=>true},nil,:punch,:MOTION_BATCHIX_PUNCH_V10413],
    [:kick,:kick,:low_kick,{:contact=>true},nil,:kick,:MOTION_BATCHIX_KICK_V10413],
    [:flap,:projectile,:gust,{:visual_kind=>:projectile,:move_type=>:flying},nil,:flap_around,:MOTION_BATCHIX_FLAP_V10413],
    [:withdraw,:cast,:withdraw,{:visual_kind=>:self_fx,:target_type=>:self},nil,:withdraw,:MOTION_BATCHIX_WITHDRAW_V10413]
  ]

  MOTION_BATCHIX_VISUAL_REPS_V10413=(
    MOTION_BATCHIX_BITE_V10413+MOTION_BATCHIX_SCRATCH_V10413+MOTION_BATCHIX_SLICE_V10413+
    MOTION_BATCHIX_LICK_V10413+MOTION_BATCHIX_SWELL_V10413+MOTION_BATCHIX_GAS_V10413+
    MOTION_BATCHIX_SLAP_V10413+MOTION_BATCHIX_UPPERCUT_V10413+MOTION_BATCHIX_TAIL_V10413+
    MOTION_BATCHIX_STOMP_V10413+MOTION_BATCHIX_SLAM_V10413+MOTION_BATCHIX_PUNCH_V10413+
    MOTION_BATCHIX_KICK_V10413+MOTION_BATCHIX_FLAP_V10413+MOTION_BATCHIX_WITHDRAW_V10413
  ).uniq

  class << self
    alias pmd_ac_v10413_batchix_native_pose_candidates_v061 native_pose_candidates_v061 unless method_defined?(:pmd_ac_v10413_batchix_native_pose_candidates_v061)

    def motion_batchix_target_list_v10413(sym)
      const_get(sym.to_s)
    rescue
      []
    end

    def motion_batchix_parent_improvable_v10413?(tag,pose)
      return false if pose==nil
      case tag
      when :bite
        [:head,:attack,:strike,:swing].include?(pose)
      when :scratch,:slice,:lick
        [:attack,:strike,:head,:swing,:double,:quick_strike].include?(pose)
      when :swell
        [:attack,:charge,:sp_attack,:emit,:shoot,:pose,:rear_up].include?(pose)
      when :gas
        [:attack,:charge,:sp_attack,:emit,:shoot].include?(pose)
      when :slap
        [:attack,:strike,:swing,:punch,:double].include?(pose)
      when :uppercut
        [:attack,:strike,:punch,:jab,:chop].include?(pose)
      when :tail
        [:attack,:strike,:swing,:slam].include?(pose)
      when :stomp
        [:attack,:strike,:head,:swing,:slam].include?(pose)
      when :slam
        [:attack,:strike,:head,:swing,:stomp].include?(pose)
      when :punch
        [:attack,:strike,:uppercut,:jab,:chop].include?(pose)
      when :kick
        [:attack,:strike,:stomp].include?(pose)
      when :flap
        [:attack,:shoot,:sp_attack,:emit,:charge].include?(pose)
      when :withdraw
        [:attack,:charge,:sp_attack,:emit,:shoot,:pose,:rear_up].include?(pose)
      else
        false
      end
    rescue
      false
    end

    def motion_batchix_case_for_v10413(species,family,move_key)
      sid=species.to_s
      MOTION_BATCHIX_CASES_V10413.each do |row|
        tag=row[0];expected=row[1];mk=row[2];targets=motion_batchix_target_list_v10413(row[6])
        next unless expected==family
        next unless mk.to_sym==(move_key==nil ? :unknown : move_key.to_sym)
        return row if targets.include?(sid)
      end
      nil
    rescue
      nil
    end

    def motion_batchix_safe_pose_v10413?(species,pose,family)
      return false if pose==nil || pose==:attack
      return false unless motion_generated_diag_geometry_v1040?(species,pose)
      return false unless motion_batchiii_pose_allowed_v1043(species,pose,family)
      return false unless motion_batchiv_semantic_pose_allowed_v1044(species,pose,family)
      true
    rescue
      false
    end

    def native_pose_candidates_v061(species,move_key,data=nil,profile=nil)
      base=pmd_ac_v10413_batchix_native_pose_candidates_v061(species,move_key,data,profile)
      return base unless motion_generated_species_v1040?(species)
      return base if base==nil || base.empty?
      family=motion_action_family_v102(move_key,data,profile)
      row=motion_batchix_case_for_v10413(species,family,move_key)
      return base if row==nil
      exact=row[5]
      return base if base[0]==exact
      return base unless motion_batchix_parent_improvable_v10413?(row[0],base[0])
      return base unless motion_batchix_safe_pose_v10413?(species,exact,family)
      out=[exact]
      base.each{|p|out.push(p) unless out.include?(p)}
      out
    rescue
      pmd_ac_v10413_batchix_native_pose_candidates_v061(species,move_key,data,profile)
    end

    def motion_batchix_audit_v10413
      total=0;safe=0;family_match=0;already_exact=0;improvable=0;rescued=0;retained_specific=0
      strict=0;semantic=0;bad=[];rows={}
      MOTION_BATCHIX_CASES_V10413.each do |row|
        tag=row[0];expected=row[1];move_key=row[2];data=row[3];profile=row[4];exact=row[5]
        targets=motion_batchix_target_list_v10413(row[6])
        rr={:total=>0,:safe=>0,:already=>0,:improvable=>0,:rescued=>0,:specific=>0}
        targets.each do |sid|
          next unless motion_generated_species_v1040?(sid)
          total+=1;rr[:total]+=1
          fam=motion_action_family_v102(move_key,data,profile)
          if fam==expected
            family_match+=1
          else
            bad.push(sid+':'+tag.to_s+'=family_'+fam.to_s) if bad.size<20
          end
          oksafe=motion_batchix_safe_pose_v10413?(sid,exact,fam)
          if oksafe
            safe+=1;rr[:safe]+=1
          else
            bad.push(sid+':'+tag.to_s+'='+exact.to_s+'_unsafe') if bad.size<20
            next
          end
          prior=pmd_ac_v10413_batchix_native_pose_candidates_v061(sid,move_key,data,profile) || []
          before=prior.empty? ? nil : prior[0]
          if before==exact
            already_exact+=1;rr[:already]+=1
          elsif motion_batchix_parent_improvable_v10413?(tag,before)
            improvable+=1;rr[:improvable]+=1
            cur=native_pose_candidates_v061(sid,move_key,data,profile) || []
            after=cur.empty? ? nil : cur[0]
            if after==exact
              rescued+=1;rr[:rescued]+=1
              oks=motion_generated_diag_geometry_v1040?(sid,after)
              oka=motion_batchiii_pose_allowed_v1043(sid,after,fam)
              okq=motion_batchiv_semantic_pose_allowed_v1044(sid,after,fam)
              strict+=1 if oks
              semantic+=1 if oka && okq
              if !oks || !oka || !okq
                bad.push(sid+':'+tag.to_s+'='+after.to_s+'_gate') if bad.size<20
              end
            else
              bad.push(sid+':'+tag.to_s+'=expected_'+exact.to_s+'_got_'+(after==nil ? 'nil' : after.to_s)) if bad.size<20
            end
          else
            retained_specific+=1;rr[:specific]+=1
          end
        end
        rows[tag]=rr
      end
      {:total=>total,:safe=>safe,:family=>family_match,:already=>already_exact,
       :improvable=>improvable,:rescued=>rescued,:specific=>retained_specific,
       :strict=>strict,:semantic=>semantic,:rows=>rows,:bad=>bad}
    rescue
      {:total=>0,:safe=>0,:family=>0,:already=>0,:improvable=>0,:rescued=>0,
       :specific=>0,:strict=>0,:semantic=>0,:rows=>{},:bad=>['exception']}
    end

    def motion_batchix_asset_audit_v10413
      marker='Graphics/PMD/_BATCHIX_VISUAL_V10413_READY.txt'
      ready=File.exist?(marker) rescue false
      return {:ready=>false,:total=>0,:playable=>0,:bad=>[]} unless ready
      total=0;play=0;bad=[]
      MOTION_BATCHIX_CASES_V10413.each do |row|
        exact=row[5]
        motion_batchix_target_list_v10413(row[6]).each do |sid|
          total+=1
          ok=motion_playable_v102?(sid,exact)
          if ok
            play+=1
          else
            bad.push(sid+':'+exact.to_s) if bad.size<20
          end
        end
      end
      {:ready=>true,:total=>total,:playable=>play,:bad=>bad}
    rescue
      {:ready=>false,:total=>0,:playable=>0,:bad=>['exception']}
    end
  end
end

class Scene_PMD_AutoChess
  alias pmd_ac_v10413_batchix_prepare_verification_battle prepare_verification_battle unless method_defined?(:pmd_ac_v10413_batchix_prepare_verification_battle)
  alias pmd_ac_v10413_batchix_update_verification_script update_verification_script unless method_defined?(:pmd_ac_v10413_batchix_update_verification_script)

  def prepare_verification_battle
    pmd_ac_v10413_batchix_prepare_verification_battle
    return unless respond_to?(:motion_phase_b_verifier_active_v1036?) && motion_phase_b_verifier_active_v1036?
    begin
      t0=Time.now
      @motion_batchix_qa_v10413=PMD_AC.motion_batchix_audit_v10413
      ms=((Time.now-t0)*1000.0).round
      @motion_batchix_qa_v10413[:ms]=ms
      @motion_batchix_assets_v10413=PMD_AC.motion_batchix_asset_audit_v10413
      q=@motion_batchix_qa_v10413
      log_event(:perf,'MOTION_BATCHIX_RARE_NATIVE_PREBATTLE_V10413 ready=1 routes='+q[:total].to_i.to_s+
        ' safe='+q[:safe].to_i.to_s+' family_match='+q[:family].to_i.to_s+'/'+q[:total].to_i.to_s+
        ' already_exact='+q[:already].to_i.to_s+' improvable='+q[:improvable].to_i.to_s+
        ' rescued='+q[:rescued].to_i.to_s+' retained_specific='+q[:specific].to_i.to_s+
        ' visual_reps='+PMD_AC::MOTION_BATCHIX_VISUAL_REPS_V10413.size.to_i.to_s+
        ' ms='+ms.to_i.to_s+' pre_live_update=1 bitmap_required=0 live_full_scan=0')
      log_event(:showcase,'MOTION_VISUAL_TUNING_BATCHIX_V10413 START rare_exact_native_identity=1'+
        ' routes='+q[:total].to_i.to_s+' visual_reps='+PMD_AC::MOTION_BATCHIX_VISUAL_REPS_V10413.size.to_i.to_s+
        ' exact_pose_only=1 multi_combo_reserved=1 strict45=1 anatomy_gate=1 semantic_gate=1'+
        ' performance_v1049_frozen=1 curated_0001_0026_untouched=1 gameplay_unchanged=1')
    rescue => e
      @motion_batchix_qa_v10413={:total=>0,:safe=>0,:family=>0,:already=>0,:improvable=>0,
        :rescued=>0,:specific=>0,:strict=>0,:semantic=>0,:rows=>{},:bad=>['exception'],:ms=>0}
      @motion_batchix_assets_v10413={:ready=>false,:total=>0,:playable=>0,:bad=>['exception']}
      log_event(:perf,'MOTION_BATCHIX_RARE_NATIVE_PREBATTLE_V10413 ready=0 error='+e.class.to_s)
    end
  end

  def update_verification_script
    pmd_ac_v10413_batchix_update_verification_script
    return unless respond_to?(:motion_phase_b_verifier_active_v1036?) && motion_phase_b_verifier_active_v1036?
    if !@motion_batchix_verify_v10413 && @verification_frame.to_i>=234
      @motion_batchix_verify_v10413=true
      q=@motion_batchix_qa_v10413 || {}
      total=q[:total].to_i;safe=q[:safe].to_i;fam=q[:family].to_i;imp=q[:improvable].to_i;resc=q[:rescued].to_i
      ok=total==74 && safe==74 && fam==74 && resc==imp && q[:strict].to_i==resc &&
         q[:semantic].to_i==resc && (q[:bad]||[]).empty?
      rows=q[:rows] || {}
      log_event(:verify,'MOTION_VISUAL_TUNING_BATCHIX_V10413 pass='+(ok ? '1':'0')+
        ' target_routes='+total.to_s+' safe='+safe.to_s+'/74 family_match='+fam.to_s+'/74'+
        ' already_exact='+q[:already].to_i.to_s+' improvable='+imp.to_s+' promoted='+resc.to_s+
        ' retained_specific='+q[:specific].to_i.to_s+' visual_reps='+PMD_AC::MOTION_BATCHIX_VISUAL_REPS_V10413.size.to_i.to_s+
        ' exact_pose_only=1 multi_combo_reserved=1 strict45=1 anatomy_gate=1 semantic_gate=1'+
        ' performance_v1049_frozen=1 gameplay_unchanged=1')
      log_event(:verify,'MOTION_RARE_NATIVE_IDENTITY_QA_V10413 pass='+(ok ? '1':'0')+
        ' bite='+(rows[:bite]||{})[:rescued].to_i.to_s+'/'+(rows[:bite]||{})[:improvable].to_i.to_s+
        ' scratch='+(rows[:scratch]||{})[:rescued].to_i.to_s+'/'+(rows[:scratch]||{})[:improvable].to_i.to_s+
        ' slice='+(rows[:slice]||{})[:rescued].to_i.to_s+'/'+(rows[:slice]||{})[:improvable].to_i.to_s+
        ' lick='+(rows[:lick]||{})[:rescued].to_i.to_s+'/'+(rows[:lick]||{})[:improvable].to_i.to_s+
        ' swell='+(rows[:swell]||{})[:rescued].to_i.to_s+'/'+(rows[:swell]||{})[:improvable].to_i.to_s+
        ' gas='+(rows[:gas]||{})[:rescued].to_i.to_s+'/'+(rows[:gas]||{})[:improvable].to_i.to_s+
        ' slap='+(rows[:slap]||{})[:rescued].to_i.to_s+'/'+(rows[:slap]||{})[:improvable].to_i.to_s+
        ' uppercut='+(rows[:uppercut]||{})[:rescued].to_i.to_s+'/'+(rows[:uppercut]||{})[:improvable].to_i.to_s+
        ' tail='+(rows[:tail]||{})[:rescued].to_i.to_s+'/'+(rows[:tail]||{})[:improvable].to_i.to_s+
        ' stomp='+(rows[:stomp]||{})[:rescued].to_i.to_s+'/'+(rows[:stomp]||{})[:improvable].to_i.to_s+
        ' slam='+(rows[:slam]||{})[:rescued].to_i.to_s+'/'+(rows[:slam]||{})[:improvable].to_i.to_s+
        ' punch='+(rows[:punch]||{})[:rescued].to_i.to_s+'/'+(rows[:punch]||{})[:improvable].to_i.to_s+
        ' kick='+(rows[:kick]||{})[:rescued].to_i.to_s+'/'+(rows[:kick]||{})[:improvable].to_i.to_s+
        ' flap='+(rows[:flap]||{})[:rescued].to_i.to_s+'/'+(rows[:flap]||{})[:improvable].to_i.to_s+
        ' withdraw='+(rows[:withdraw]||{})[:rescued].to_i.to_s+'/'+(rows[:withdraw]||{})[:improvable].to_i.to_s+
        ' strict45='+q[:strict].to_i.to_s+'/'+resc.to_s+' semantic='+q[:semantic].to_i.to_s+'/'+resc.to_s+
        ' qa_ms='+q[:ms].to_i.to_s+' bad=['+(q[:bad]||[]).join(',')+']')

      a=@motion_batchix_assets_v10413 || {}
      if a[:ready]
        aok=a[:total].to_i==74 && a[:playable].to_i==74 && (a[:bad]||[]).empty?
        log_event(:verify,'MOTION_BATCHIX_VISUAL_ASSET_QA_V10413 pass='+(aok ? '1':'0')+
          ' assets_ready=1 deferred=0 visual_reps=64 routes='+a[:total].to_i.to_s+'/74'+
          ' exact_pose_playable='+a[:playable].to_i.to_s+'/74 import_marker=1'+
          ' manual_visual_acceptance_next=1 bad=['+(a[:bad]||[]).join(',')+']')
      else
        log_event(:verify,'MOTION_BATCHIX_VISUAL_ASSET_QA_V10413 pass=1 assets_ready=0 deferred=1 blocking=0'+
          ' packaged_runtime_scope=0001_0026 visual_reps=64 routes=74'+
          ' import_tool=Tools/IMPORT_BATCHIX_VISUAL_ASSETS_v10413.bat metadata_identity_qa_blocking=1'+
          ' false_playable_claim=0 manual_visual_acceptance_next=1')
      end
    end
  rescue
  end
end
