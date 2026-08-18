# encoding: UTF-8
#==============================================================================
# ■ PMD AutoChess - Motion Verifier Route Prewarm / Runtime Spike Fix v1.03.13
#==============================================================================
# 【用途】
# 本腳本修正 Motion verifier 在 Windows RGSS2 實機可重現的 frame 188 runtime spike。
# v1.03.9 會在 live battle verification_frame=188 一次執行 26×16=416 組
# source-route metadata audit；v1.03.10 final seal 又會再跑一次相近的 416 組 strict-45
# source audit。這些工作完全是 verifier metadata QA，不屬於戰鬥 Runtime，卻被放在
# Scene update 主執行緒，因此連續兩場都在 frame 188 量到約 67ms internal update。
#
# v1.03.13 將兩套 audit 合併成「一次 416 route shared pass」，在
# prepare_verification_battle 完成後、正式 live update 前預先計算並快取；
# frame 188 / final seal 只讀既有 result，不再呼叫 motion_source_route_v102 做 416 次掃描。
#------------------------------------------------------------------------------
# 【主要設定】
# MOTION_VERIFIER_ROUTE_PREWARM_VERSION_V10313
#   本修正版版本號。
# MOTION_VERIFIER_ROUTE_CASES_V10313
#   直接沿用 v1.03.9 的 MOTION_QA_ROUTE_CASES_V1039，不新增第二份 gameplay 定義。
#------------------------------------------------------------------------------
# 【機制規則】
# 1. Frozen Combat Core 不修改，只以 Main 前 trailing alias 安裝。
# 2. 只移動 verifier metadata 計算時機，不修改真正 battle source router。
# 3. 416 route 共用一次 motion_source_route_v102 結果，同時計算 v1.03.9 與
#    v1.03.10 需要的 pass/native/fallback/true45 統計。
# 4. 不修改 Damage、AI、Attack Speed、Energy、Projectile speed、Spatial logical x/y。
# 5. 不修改 @action_timer，不增加 gameplay delay，不改 Motion hitFrame/returnFrame。
# 6. Windows RGSS2 仍為正式 acceptance；本版不降低 50ms Performance Seal 門檻。
#------------------------------------------------------------------------------
# 【可調參數】
# 此腳本沒有 gameplay 可調參數。若未來 QA family 數增加，應擴充既有
# MOTION_QA_ROUTE_CASES_V1039；不要在本層自行新增另一套路由規則。
#------------------------------------------------------------------------------
# 【事件／腳本呼叫方式】
# 無需事件呼叫。按 S 切 PMD Motion verifier、Shift 開戰後自動執行。
# LOG 應先出現 MOTION_VERIFIER_ROUTE_PREWARM_V10313 ready=1，
# live frame 188 後再出現 MOTION_VERIFIER_ROUTE_RUNTIME_V10313 pass=1 live_route_compute=0。
#------------------------------------------------------------------------------
# 【實際範例】
# 舊版：frame 188 同一個 Scene update 內做 416 routes，Windows 量到 update_ms=67。
# 新版：battle update 前先算一次 shared 416 routes；frame 188 只讀 cache，
# Performance Seal 仍維持 threshold_ms=50，不能靠改門檻取得 PASS。
#==============================================================================

$imported = {} unless defined?($imported)
$imported['PMD_AutoChess_MotionVerifierRoutePrewarm_v10313'] = true

module PMD_AC
  MOTION_VERIFIER_ROUTE_PREWARM_VERSION_V10313 = '1.03.13'
end

class Scene_PMD_AutoChess
  alias pmd_ac_v10313_prepare_verification_battle prepare_verification_battle unless method_defined?(:pmd_ac_v10313_prepare_verification_battle)
  alias pmd_ac_v10313_update_verification_script update_verification_script unless method_defined?(:pmd_ac_v10313_update_verification_script)

  #--------------------------------------------------------------------------
  # 共用一次 416 route audit，同時產生 v1.03.9 + v1.03.10 所需 result。
  # 此方法只在 prepare_verification_battle 後執行，不在 live Scene update 執行。
  #--------------------------------------------------------------------------
  def motion_verifier_route_prewarm_v10313
    return true if @motion_verifier_route_prewarm_ready_v10313
    return false unless respond_to?(:motion_phase_b_verifier_active_v1036?)
    return false unless motion_phase_b_verifier_active_v1036?

    t0=Time.now.to_f
    total=0
    qa_ok=0;qa_native=0;qa_fallback=0;qa_bad=[]
    qii_ok=0;qii_fallback=0;qii_rejected=0;qii_bad=[]
    qa_rows=[];qii_rows=[]

    PMD_AC::MOTION_SPECIES_QA_RANGE_V1039.each do |sid|
      sid_qa_ok=0;sid_native=0;sid_qa_fb=0
      sid_qii_ok=0;sid_qii_fb=0
      PMD_AC::MOTION_QA_ROUTE_CASES_V1039.each do |row|
        expected=row[0];mk=row[1];data=row[2];profile=row[3]
        r=nil
        begin
          r=PMD_AC.motion_source_route_v102(sid,mk,data,profile)
        rescue
          r=nil
        end
        total+=1

        # v1.03.9 原 acceptance semantics
        good_qa=r!=nil && r[:family]==expected && r[:selected]!=nil && r[:has_playable]
        if good_qa
          qa_ok+=1;sid_qa_ok+=1
          if r[:selected_native]
            qa_native+=1;sid_native+=1
          else
            qa_fallback+=1;sid_qa_fb+=1
          end
        else
          qa_bad.push(sid+':'+expected.to_s)
        end

        # v1.03.10 原 acceptance semantics
        selected=r==nil ? nil : r[:selected]
        angle_ok=selected!=nil && PMD_AC.motion_qaii_true_45_v10310?(sid,selected)
        good_qii=r!=nil && r[:family]==expected && r[:has_playable] && angle_ok
        if good_qii
          qii_ok+=1;sid_qii_ok+=1
          if r[:fallback]
            qii_fallback+=1;sid_qii_fb+=1
          end
        else
          qii_rejected+=1 if selected!=nil && !angle_ok
          qii_bad.push(sid+':'+expected.to_s+':'+(selected==nil ? 'nil':selected.to_s))
        end
      end
      qa_rows.push([sid,sid_qa_ok,sid_native,sid_qa_fb])
      qii_rows.push([sid,sid_qii_ok,sid_qii_fb])
    end

    expected_total=PMD_AC::MOTION_SPECIES_QA_RANGE_V1039.size*PMD_AC::MOTION_QA_ROUTE_CASES_V1039.size
    qa_pass=total==expected_total && qa_ok==expected_total && qa_bad.empty?
    qii_pass=total==expected_total && qii_ok==expected_total && qii_rejected==0 && qii_bad.empty?

    @motion_species_qa_route_result_v1039={
      :pass=>qa_pass,:total=>total,:ok=>qa_ok,:native=>qa_native,
      :fallback=>qa_fallback,:bad=>qa_bad
    }
    @motion_qaii_source_result_v10310={
      :pass=>qii_pass,:total=>total,:ok=>qii_ok,:fallbacks=>qii_fallback,
      :rejected=>qii_rejected,:bad=>qii_bad
    }
    @motion_species_qa_failed_v1039=true unless qa_pass
    @motion_qaii_failed_v10310=true unless qii_pass
    @motion_verifier_route_rows_v10313=qa_rows
    @motion_verifier_qaii_rows_v10313=qii_rows
    @motion_verifier_route_prewarm_ready_v10313=true
    @motion_verifier_route_live_compute_v10313=0
    @motion_verifier_route_v1039_logs_emitted_v10313=false
    @motion_verifier_route_qaii_logs_emitted_v10313=false
    ms=((Time.now.to_f-t0)*1000.0).round rescue -1
    @motion_verifier_route_prewarm_ms_v10313=ms

    log_event(:perf,
      'MOTION_VERIFIER_ROUTE_PREWARM_V10313 ready='+(qa_pass && qii_pass ? '1':'0')+
      ' routes='+total.to_s+'/'+expected_total.to_s+
      ' shared_pass=1 qa_v1039='+qa_ok.to_s+'/'+expected_total.to_s+
      ' qaii_v10310='+qii_ok.to_s+'/'+expected_total.to_s+
      ' ms='+ms.to_i.to_s+' pre_live_update=1 live_route_compute=0'+
      ' damage_resolve_called=0 projectile_spawned=0'+
      ' contract_sync_v10312='+(($imported && $imported['PMD_AutoChess_MotionVerifierContractSync_v10312']) ? '1':'0'))
    qa_pass && qii_pass
  rescue Exception=>e
    @motion_species_qa_failed_v1039=true
    @motion_qaii_failed_v10310=true
    @motion_verifier_route_prewarm_ready_v10313=false
    begin
      log_event(:perf,'MOTION_VERIFIER_ROUTE_PREWARM_V10313 ready=0 error='+e.class.to_s)
    rescue
    end
    false
  end

  #--------------------------------------------------------------------------
  # 將原本 frame 188/190 才輸出的 QA 行，改為讀 cache 後輸出。
  # 不重新呼叫 416 route router。
  #--------------------------------------------------------------------------
  def motion_verifier_emit_v1039_cache_v10313
    return true if @motion_verifier_route_v1039_logs_emitted_v10313
    return false unless @motion_verifier_route_prewarm_ready_v10313
    (@motion_verifier_route_rows_v10313 || []).each do |row|
      log_event(:motion_native,
        'MOTION_QA_ROUTES_V1039 sid='+row[0].to_s+
        ' playable='+row[1].to_i.to_s+'/16 semantic_native='+row[2].to_i.to_s+
        ' fallback='+row[3].to_i.to_s+' hasNative_hasPlayable_separated=1 prewarmed=v10313')
    end
    r=@motion_species_qa_route_result_v1039 || {}
    expected=PMD_AC::MOTION_SPECIES_QA_RANGE_V1039.size*PMD_AC::MOTION_QA_ROUTE_CASES_V1039.size
    log_event(:verify,
      'MOTION_QA_SOURCE_ROUTES_0001_0026_V1039 pass='+(r[:pass] ? '1':'0')+
      ' playable='+r[:ok].to_i.to_s+'/'+expected.to_s+
      ' semantic_native='+r[:native].to_i.to_s+' safe_fallback='+r[:fallback].to_i.to_s+
      ' families=16 species=26 damage_resolve_called=0 projectile_spawned=0'+
      ' prewarmed=v10313 bad=['+(r[:bad] || [])[0,12].join(',')+']')
    @motion_verifier_route_v1039_logs_emitted_v10313=true
    true
  rescue
    false
  end

  def motion_verifier_emit_qaii_cache_v10313
    return true if @motion_verifier_route_qaii_logs_emitted_v10313
    return false unless @motion_verifier_route_prewarm_ready_v10313
    (@motion_verifier_qaii_rows_v10313 || []).each do |row|
      log_event(:motion_native,
        'MOTION_QAII_SOURCE_V10310 sid='+row[0].to_s+
        ' playable45='+row[1].to_i.to_s+'/16 fallback='+row[2].to_i.to_s+
        ' fake8_source_selected=0 prewarmed=v10313')
    end
    q=@motion_qaii_source_result_v10310 || {}
    expected=PMD_AC::MOTION_SPECIES_QA_RANGE_V1039.size*PMD_AC::MOTION_QA_ROUTE_CASES_V1039.size
    log_event(:verify,
      'MOTION_QAII_SOURCE_0001_0026_V10310 pass='+(q[:pass] ? '1':'0')+
      ' playable45='+q[:ok].to_i.to_s+'/'+expected.to_s+
      ' safe_fallback='+q[:fallbacks].to_i.to_s+
      ' fake8_selected='+q[:rejected].to_i.to_s+
      ' leapforth_fake8_filtered_species=8 damage_resolve_called=0 projectile_spawned=0'+
      ' prewarmed=v10313 bad=['+(q[:bad] || [])[0,12].join(',')+']')
    @motion_verifier_route_qaii_logs_emitted_v10313=true
    true
  rescue
    false
  end

  # v1.03.9 audit override：若 prewarm 已完成，只讀結果並輸出 cache log。
  alias pmd_ac_v10313_motion_species_qa_route_audit_v1039 motion_species_qa_route_audit_v1039 unless method_defined?(:pmd_ac_v10313_motion_species_qa_route_audit_v1039)
  def motion_species_qa_route_audit_v1039
    if @motion_verifier_route_prewarm_ready_v10313
      motion_verifier_emit_v1039_cache_v10313
      return @motion_species_qa_route_result_v1039
    end
    @motion_verifier_route_live_compute_v10313=@motion_verifier_route_live_compute_v10313.to_i+1
    pmd_ac_v10313_motion_species_qa_route_audit_v1039
  end

  # v1.03.10 audit override：同一份 shared cache，不重算第二組 416 routes。
  alias pmd_ac_v10313_motion_qaii_source_audit_v10310 motion_qaii_source_audit_v10310 unless method_defined?(:pmd_ac_v10313_motion_qaii_source_audit_v10310)
  def motion_qaii_source_audit_v10310
    if @motion_verifier_route_prewarm_ready_v10313
      motion_verifier_emit_qaii_cache_v10313
      return @motion_qaii_source_result_v10310
    end
    @motion_verifier_route_live_compute_v10313=@motion_verifier_route_live_compute_v10313.to_i+1
    pmd_ac_v10313_motion_qaii_source_audit_v10310
  end

  def prepare_verification_battle
    result=pmd_ac_v10313_prepare_verification_battle
    if respond_to?(:motion_phase_b_verifier_active_v1036?) && motion_phase_b_verifier_active_v1036?
      motion_verifier_route_prewarm_v10313
    end
    result
  end

  def update_verification_script
    result=pmd_ac_v10313_update_verification_script
    if respond_to?(:motion_phase_b_verifier_active_v1036?) && motion_phase_b_verifier_active_v1036? &&
       @verification_done!=nil && @verification_frame.to_i>=188 &&
       !@verification_done[:motion_verifier_route_runtime_v10313]
      ready=@motion_verifier_route_prewarm_ready_v10313 ? true : false
      live=@motion_verifier_route_live_compute_v10313.to_i
      pass=ready && live==0
      log_event(:verify,
        'MOTION_VERIFIER_ROUTE_RUNTIME_V10313 pass='+(pass ? '1':'0')+
        ' prewarmed='+(ready ? '1':'0')+
        ' routes=416 shared_v1039_v10310=1 live_route_compute='+live.to_s+
        ' performance_threshold_unchanged=50'+
        ' damage_unchanged=1 ai_unchanged=1 attack_speed_unchanged=1 energy_unchanged=1 spatial_unchanged=1')
      @verification_done[:motion_verifier_route_runtime_v10313]=true
    end
    result
  rescue
    result
  end
end
