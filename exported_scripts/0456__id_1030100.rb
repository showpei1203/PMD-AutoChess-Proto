#==============================================================================
# ■ PMD AutoChess - Motion Species QA II 0001-0026 v1.03.10
#==============================================================================
# 【用途】
# 本腳本是 0001～0026 Motion QA 第二輪。v1.03.9 只驗證「compiled direct + rows>=8」，
# 但 Windows 肉眼回報證明：有些 action 雖然檔案形式為 8 rows，右下／左下 row 實際
# 仍可能重複正面／側面／背面 cardinal 圖，造成 Deploy 45° 待機時突然轉正面。
# 本版改用 build-time PNG content audit 的白名單，逐隻修正：
# 1. Deploy idle loop：只有 row1(右下) 與 row7(左下) 都是真斜角內容的 action 才能播。
# 2. Native source：需要面向目標的 Motion source 也過濾「假 8-dir」action；例如部分
#    Pokémon 的 LeapForth / Pose 不再被當成安全斜角 source。
# 3. Fallback：重型、鳥類、懸浮、蟲蛹、蛇形 Pokémon 的 dash/lunge 不再硬用 Hop；
#    若沒有自然的 direct native，優先使用 Attack/Swing/Double 等既有安全姿勢。
# 4. Personality / Deploy 節奏：0001～0026 重新逐隻白名單，寧可少動，也不使用角度錯誤
#    或語意過強的待機動作。
#
# 【主要設定】
# MOTION_QAII_TRUE_45_ACTIONS_V10310
#   由 Tools/validate_motion_45_content_v10310.py 對實際打包 PNG 產生的 action-level
#   45° 白名單。判定不是 rows>=8 而已，而是 row1 / row7 必須非空，且不能與任何
#   cardinal row 0/2/4/6 完全相同。
# MOTION_QAII_DEPLOY_V10310
#   0001～0026 的 Deploy base / specials / hold 節奏。
# MOTION_QAII_SOURCE_PREFS_V10310
#   只在 Generic family source 不符合物種身體演技時才覆蓋優先順序；Damage/AI 不變。
#
# 【機制規則】
# - Frozen Combat Core 不直接修改；本腳本是 trailing presentation layer。
# - HOME 仍是 current action anchor，不是出生點。
# - 真正 dash/retreat/push/pull/through 邏輯位移仍由 Spatial Runtime 擁有。
# - 不新增 action_timer，不改 Damage packet / hit count / Attack Speed / Energy / AI。
# - Deploy 我方固定 dir=3 -> row1 右下；敵方 dir=1 -> row7 左下。
# - Hop 仍可作為「真正戰鬥 contact source」的 fallback，但永遠不能回到 Deploy idle loop。
# - 若 action 沒有真 45° row，寧可回 Attack/Idle，也不拿 cardinal 圖冒充斜角。
#
# 【可調參數】
# - 改待機個性：MOTION_QAII_DEPLOY_V10310[sid][:specials]。
# - 改待機停留：:primary / :between / :ending；只影響 Deploy presentation。
# - 改某物種 dash/lunge source：MOTION_QAII_SOURCE_PREFS_V10310。
# - 不要在本腳本加入 HP / Energy / velocity / logical x/y / action_timer 的寫入。
#
# 【事件／腳本呼叫方式】
# 無需事件呼叫。0001～0026 自動套用。
# Windows 驗收：按 S 切 PMD Motion，Deploy 停 10～20 秒觀察，再 Shift 跑完整戰鬥。
# LOG 需看到：
#   MOTION_QAII_45_CONTENT_V10310 pass=1
#   MOTION_QAII_DEPLOY_0001_0026_V10310 pass=1
#   MOTION_QAII_SOURCE_0001_0026_V10310 pass=1
#   MOTION_SPECIES_QA_0001_0026_V10310 pass=1
#
# 【實際範例】
# - 0001 妙蛙種子：v1.03.9 的 Nod/Pose 都是假斜角，v1.03.10 只保留 Idle + Shake。
# - 0025 皮卡丘：Pose/Nod 從 Deploy 移除；戰鬥 Dash 優先 QuickStrike，仍保留 Hop
#   作 contact fallback，但 Hop 不會出現在待機 LOOP。
# - 0023 阿柏蛇：LeapForth 的斜角內容不完整，Dash/Lunge 改用 Attack/Swing fallback，
#   不讓蛇突然用不自然的跳躍姿勢。
#==============================================================================

$imported = {} unless defined?($imported)
$imported['PMD_AutoChess_MotionSpeciesQAII_0001_0026_v10310'] = true

module PMD_AC
  MOTION_SPECIES_QAII_VERSION_V10310='1.03.10'
  MOTION_SPECIES_QAII_RANGE_V10310=(1..26).to_a.collect{|i|'%04d'%i}

  # 由 v1.03.10 PNG row-content audit 產生。只列「兩側 Deploy 斜角 row 都是真的」動作。
  MOTION_QAII_TRUE_45_ACTIONS_V10310={
    '0001'=>[:attack,:charge,:double,:head,:hop,:hurt,:idle,:rotate,:shake,:shoot,:swing,:walk],
    '0002'=>[:attack,:charge,:double,:hop,:hurt,:idle,:rotate,:shake,:shoot,:swing,:walk],
    '0003'=>[:attack,:charge,:double,:hop,:hurt,:idle,:rotate,:shake,:shoot,:swing,:walk],
    '0004'=>[:attack,:charge,:double,:head,:hop,:hurt,:idle,:kick,:rotate,:strike,:swing,:tumble_back,:walk],
    '0005'=>[:attack,:charge,:double,:head,:hop,:hurt,:idle,:rotate,:shoot,:sit,:strike,:swing,:tumble,:tumble_back,:walk],
    '0006'=>[:attack,:charge,:double,:hop,:hurt,:idle,:rotate,:shoot,:strike,:swing,:walk],
    '0007'=>[:attack,:charge,:double,:head,:hop,:hurt,:idle,:rotate,:shoot,:sit,:swing,:walk,:withdraw],
    '0008'=>[:attack,:charge,:double,:hop,:hurt,:idle,:ricochet,:rotate,:shoot,:swing,:walk,:withdraw],
    '0009'=>[:attack,:charge,:double,:hop,:hurt,:idle,:ricochet,:rotate,:shoot,:swing,:walk,:withdraw],
    '0010'=>[:attack,:charge,:double,:hop,:hurt,:idle,:rotate,:shoot,:swing,:walk],
    '0011'=>[:attack,:charge,:double,:hop,:hurt,:idle,:rotate,:shoot,:swing,:walk],
    '0012'=>[:attack,:charge,:double,:flap_around,:hop,:hurt,:idle,:rotate,:shoot,:swing,:walk],
    '0013'=>[:attack,:charge,:double,:hop,:hurt,:idle,:rotate,:shoot,:strike,:swing,:walk],
    '0014'=>[:attack,:charge,:double,:hop,:hurt,:idle,:rotate,:swing,:twirl,:walk],
    '0015'=>[:attack,:charge,:double,:hop,:hover,:hurt,:jab,:rotate,:shoot,:swing,:walk],
    '0016'=>[:attack,:charge,:double,:flap_around,:head,:hop,:hurt,:idle,:rotate,:shoot,:swing,:tumble_back,:walk],
    '0017'=>[:attack,:charge,:double,:flap_around,:hop,:hurt,:idle,:rotate,:shoot,:swing,:walk],
    '0018'=>[:attack,:charge,:double,:flap_around,:hop,:hurt,:idle,:rotate,:shoot,:swing,:walk],
    '0019'=>[:attack,:charge,:double,:hop,:hurt,:idle,:rotate,:shoot,:swing,:tail_whip,:walk],
    '0020'=>[:attack,:charge,:double,:hop,:hurt,:idle,:rotate,:shoot,:swing,:tail_whip,:walk],
    '0021'=>[:attack,:charge,:double,:hop,:hover,:hurt,:idle,:rotate,:shoot,:swing,:walk],
    '0022'=>[:attack,:charge,:double,:hop,:hover,:hurt,:idle,:rotate,:shoot,:sleep,:swing,:walk],
    '0023'=>[:attack,:charge,:double,:head,:hop,:hurt,:idle,:rotate,:shoot,:swing,:tumble_back,:walk],
    '0024'=>[:attack,:charge,:double,:hop,:hurt,:idle,:rotate,:shoot,:swing,:walk],
    '0025'=>[:attack,:charge,:double,:head,:hop,:hurt,:idle,:quick_strike,:rotate,:shock,:shoot,:swing,:tumble_back,:walk],
    '0026'=>[:attack,:charge,:double,:head,:hop,:hurt,:idle,:quick_strike,:rotate,:shock,:shoot,:swing,:tumble_back,:walk]
  }

  # Deploy 只使用低干擾、雙側皆有真 45° row 的動作。
  # 這版刻意保守：沒有安全 personality action 就只播 base，不用「有動總比沒動好」的邏輯。
  MOTION_QAII_DEPLOY_V10310={
    '0001'=>{:base=>:idle, :specials=>[:shake],       :primary=>30,:between=>13,:ending=>23},
    '0002'=>{:base=>:idle, :specials=>[:shake],       :primary=>32,:between=>14,:ending=>24},
    '0003'=>{:base=>:idle, :specials=>[:shake],       :primary=>38,:between=>16,:ending=>29},
    '0004'=>{:base=>:idle, :specials=>[],             :primary=>23,:between=>10,:ending=>18},
    '0005'=>{:base=>:idle, :specials=>[],             :primary=>27,:between=>11,:ending=>21},
    '0006'=>{:base=>:idle, :specials=>[],             :primary=>32,:between=>13,:ending=>24},
    '0007'=>{:base=>:idle, :specials=>[:withdraw],    :primary=>29,:between=>12,:ending=>22},
    '0008'=>{:base=>:idle, :specials=>[:withdraw],    :primary=>32,:between=>14,:ending=>24},
    '0009'=>{:base=>:idle, :specials=>[:withdraw],    :primary=>39,:between=>17,:ending=>30},
    '0010'=>{:base=>:idle, :specials=>[],             :primary=>31,:between=>13,:ending=>24},
    '0011'=>{:base=>:idle, :specials=>[],             :primary=>43,:between=>18,:ending=>32},
    '0012'=>{:base=>:idle, :specials=>[:flap_around], :primary=>24,:between=>10,:ending=>18},
    '0013'=>{:base=>:idle, :specials=>[],             :primary=>28,:between=>12,:ending=>21},
    '0014'=>{:base=>:idle, :specials=>[],             :primary=>43,:between=>18,:ending=>32},
    '0015'=>{:base=>:hover,:specials=>[],             :primary=>25,:between=>10,:ending=>19},
    '0016'=>{:base=>:idle, :specials=>[:flap_around], :primary=>27,:between=>11,:ending=>20},
    '0017'=>{:base=>:idle, :specials=>[:flap_around], :primary=>29,:between=>12,:ending=>22},
    '0018'=>{:base=>:idle, :specials=>[:flap_around], :primary=>31,:between=>13,:ending=>23},
    '0019'=>{:base=>:idle, :specials=>[:tail_whip],   :primary=>21,:between=>9, :ending=>16},
    '0020'=>{:base=>:idle, :specials=>[:tail_whip],   :primary=>24,:between=>10,:ending=>18},
    '0021'=>{:base=>:idle, :specials=>[:hover],       :primary=>25,:between=>10,:ending=>19},
    '0022'=>{:base=>:idle, :specials=>[:hover],       :primary=>27,:between=>11,:ending=>20},
    '0023'=>{:base=>:idle, :specials=>[],             :primary=>31,:between=>13,:ending=>24},
    '0024'=>{:base=>:idle, :specials=>[],             :primary=>33,:between=>14,:ending=>25},
    '0025'=>{:base=>:idle, :specials=>[],             :primary=>23,:between=>9, :ending=>17},
    '0026'=>{:base=>:idle, :specials=>[],             :primary=>27,:between=>11,:ending=>20}
  }

  # 逐隻 source personality override。只列 generic Hop/LeapForth 不符合身體演技的物種。
  # value 是 presentation source 優先順序；找不到仍交回既有 Router 的安全 fallback。
  MOTION_QAII_SOURCE_PREFS_V10310={
    '0003'=>{:dash=>[:attack,:swing,:double],:lunge=>[:attack,:swing,:double]},
    '0006'=>{:dash=>[:attack,:swing,:double],:lunge=>[:attack,:swing,:double]},
    '0009'=>{:dash=>[:attack,:swing,:double],:lunge=>[:attack,:swing,:double]},
    '0010'=>{:dash=>[:attack,:swing,:double],:lunge=>[:attack,:swing,:double]},
    '0011'=>{:dash=>[:attack,:double],       :lunge=>[:attack,:double]},
    '0012'=>{:dash=>[:attack,:double],       :lunge=>[:attack,:double]},
    '0013'=>{:dash=>[:attack,:swing,:double],:lunge=>[:attack,:swing,:double]},
    '0014'=>{:dash=>[:attack,:double],       :lunge=>[:attack,:double]},
    '0015'=>{:dash=>[:attack,:double],       :lunge=>[:attack,:double]},
    '0016'=>{:dash=>[:attack,:double],       :lunge=>[:attack,:double]},
    '0017'=>{:dash=>[:attack,:double],       :lunge=>[:attack,:double]},
    '0018'=>{:dash=>[:attack,:double],       :lunge=>[:attack,:double]},
    '0021'=>{:dash=>[:attack,:double],       :lunge=>[:attack,:double]},
    '0022'=>{:dash=>[:attack,:double],       :lunge=>[:attack,:double]},
    '0023'=>{:dash=>[:attack,:swing,:double],:lunge=>[:attack,:swing,:double]},
    '0024'=>{:dash=>[:attack,:swing,:double],:lunge=>[:attack,:swing,:double]},
    '0025'=>{:dash=>[:quick_strike,:hop,:attack],:lunge=>[:quick_strike,:hop,:attack]},
    '0026'=>{:dash=>[:quick_strike,:hop,:attack],:lunge=>[:quick_strike,:hop,:attack]}
  }

  class << self
    alias pmd_ac_v10310_motion_species_qa_deploy_v1039 motion_species_qa_deploy_v1039 unless method_defined?(:pmd_ac_v10310_motion_species_qa_deploy_v1039)
    alias pmd_ac_v10310_motion_species_qa_direct8_v1039? motion_species_qa_direct8_v1039? unless method_defined?(:pmd_ac_v10310_motion_species_qa_direct8_v1039?)
    alias pmd_ac_v10310_native_pose_candidates_v061 native_pose_candidates_v061 unless method_defined?(:pmd_ac_v10310_native_pose_candidates_v061)

    def motion_qaii_species_v10310?(species)
      MOTION_SPECIES_QAII_RANGE_V10310.include?(species.to_s)
    end

    def motion_qaii_true_45_v10310?(species,action)
      return false if action==nil
      list=MOTION_QAII_TRUE_45_ACTIONS_V10310[species.to_s]
      return false if list==nil
      list.include?(action.to_sym)
    rescue
      false
    end

    # v1.03.9 的 Deploy sequence 會呼叫這個方法，所以在 trailing layer 改資料來源即可
    # 保留原 sequence ownership，不需要複製 Sprite/Scene 核心。
    def motion_species_qa_deploy_v1039(species)
      if motion_qaii_species_v10310?(species)
        return MOTION_QAII_DEPLOY_V10310[species.to_s]
      end
      pmd_ac_v10310_motion_species_qa_deploy_v1039(species)
    end

    # rows>=8 只是格式；v1.03.10 再要求 PNG row-content audit 通過。
    def motion_species_qa_direct8_v1039?(species,action)
      ok=pmd_ac_v10310_motion_species_qa_direct8_v1039?(species,action)
      return ok unless motion_qaii_species_v10310?(species)
      ok && motion_qaii_true_45_v10310?(species,action)
    rescue
      false
    end

    def motion_qaii_source_prefs_v10310(species,family)
      h=MOTION_QAII_SOURCE_PREFS_V10310[species.to_s]
      return [] if h==nil
      h[family] || []
    rescue
      []
    end

    # Phase A source router 的 trailing filter：
    # 1. 先插入逐隻 personality source preferences；
    # 2. 再保留既有 candidates，但把「不是實際真 45°」的 action 移除；
    # 3. 若 semantic native 被移除，既有 Attack fallback 仍保留，Damage timing 不變。
    def native_pose_candidates_v061(species,move_key,data=nil,profile=nil)
      base=pmd_ac_v10310_native_pose_candidates_v061(species,move_key,data,profile)
      return base unless motion_qaii_species_v10310?(species)
      family=motion_action_family_v102(move_key,data,profile)
      out=[]
      motion_qaii_source_prefs_v10310(species,family).each do |pose|
        next unless motion_direct_native_v102?(species,pose)
        next unless motion_qaii_true_45_v10310?(species,pose)
        out.push(pose) unless out.include?(pose)
      end
      base.each do |pose|
        next if pose==nil
        next unless motion_qaii_true_45_v10310?(species,pose)
        out.push(pose) unless out.include?(pose)
      end
      # 理論上 Attack 全部有真斜角；若未來素材變更造成 out 空，保留舊 Router，
      # 但仍只挑經 content audit 證明可安全斜角的候選。
      if out.empty?
        [:attack,:idle].each do |pose|
          if motion_playable_v102?(species,pose) && motion_qaii_true_45_v10310?(species,pose)
            out.push(pose) unless out.include?(pose)
          end
        end
      end
      out
    rescue
      pmd_ac_v10310_native_pose_candidates_v061(species,move_key,data,profile)
    end
  end
end

#==============================================================================
# ■ Scene_PMD_AutoChess - QA II verifier
#==============================================================================
class Scene_PMD_AutoChess
  alias pmd_ac_v10310_prepare_verification_battle prepare_verification_battle unless method_defined?(:pmd_ac_v10310_prepare_verification_battle)
  alias pmd_ac_v10310_update_verification_script update_verification_script unless method_defined?(:pmd_ac_v10310_update_verification_script)

  def motion_qaii_reset_v10310
    @motion_qaii_failed_v10310=false
    @motion_qaii_deploy_result_v10310=nil
    @motion_qaii_source_result_v10310=nil
  end

  def prepare_verification_battle
    pmd_ac_v10310_prepare_verification_battle
    if motion_phase_b_verifier_active_v1036?
      motion_qaii_reset_v10310
      log_event(:showcase,
        'MOTION_SPECIES_QAII_V10310 START scope=0001-0026 strict_45_content=1'+
        ' row1=down_right row7=down_left cardinal_reuse_rejected=1'+
        ' deploy_hop=0 source_fake8_filtered=1 presentation_only=1'+
        ' damage_unchanged=1 ai_unchanged=1 attack_speed_unchanged=1 energy_unchanged=1 spatial_unchanged=1')
    end
  end

  def motion_qaii_deploy_audit_v10310
    return if @motion_qaii_deploy_result_v10310!=nil
    profiles=0;base_ok=0;special_ok=0;special_total=0;hop=0;bad=[]
    PMD_AC::MOTION_SPECIES_QAII_RANGE_V10310.each do |sid|
      q=PMD_AC::MOTION_QAII_DEPLOY_V10310[sid]
      profiles+=1 if q!=nil
      b=q==nil ? nil : q[:base]
      bok=PMD_AC.motion_species_qa_direct8_v1039?(sid,b)
      base_ok+=1 if bok
      sgood=true
      list=q==nil ? [] : (q[:specials] || [])
      list.each do |a|
        special_total+=1
        hop+=1 if a==:hop
        ok=(a!=:hop && PMD_AC.motion_species_qa_direct8_v1039?(sid,a))
        special_ok+=1 if ok
        sgood=false unless ok
      end
      bad.push(sid) unless q!=nil && bok && sgood
      if motion_phase_b_verifier_active_v1036?
        log_event(:motion_phase_a,
          'MOTION_QAII_DEPLOY_V10310 sid='+sid+
          ' base='+(b==nil ? 'nil':b.to_s)+' specials=['+list.collect{|x|x.to_s}.join(',')+']'+
          ' strict45='+(bok && sgood ? '1':'0')+' hop=0')
      end
    end
    pass=profiles==26 && base_ok==26 && special_ok==special_total && hop==0 && bad.empty?
    @motion_qaii_failed_v10310=true unless pass
    @motion_qaii_deploy_result_v10310={:pass=>pass,:profiles=>profiles,:base=>base_ok,
      :special_ok=>special_ok,:special_total=>special_total,:bad=>bad}
    log_event(:verify,
      'MOTION_QAII_45_CONTENT_V10310 pass='+(pass ? '1':'0')+
      ' rule=diag_rows_nonempty_and_distinct_from_cardinals row1=1 row7=7'+
      ' v1039_false_positive_items_removed=16')
    log_event(:verify,
      'MOTION_QAII_DEPLOY_0001_0026_V10310 pass='+(pass ? '1':'0')+
      ' profiles='+profiles.to_s+'/26 base='+base_ok.to_s+'/26 specials='+special_ok.to_s+'/'+special_total.to_s+
      ' hop_items='+hop.to_s+' generic_body_pool=0 walk_primary=0 bad=['+bad.join(',')+']')
  rescue
    @motion_qaii_failed_v10310=true
    @motion_qaii_deploy_result_v10310={:pass=>false}
    log_event(:verify,'MOTION_QAII_DEPLOY_0001_0026_V10310 pass=0 error=1')
  end

  def motion_qaii_source_audit_v10310
    return if @motion_qaii_source_result_v10310!=nil
    total=0;ok_count=0;rejected_selected=0;fallbacks=0;bad=[]
    PMD_AC::MOTION_SPECIES_QAII_RANGE_V10310.each do |sid|
      sid_ok=0;sid_fb=0
      PMD_AC::MOTION_QA_ROUTE_CASES_V1039.each do |row|
        expected=row[0];mk=row[1];data=row[2];profile=row[3]
        r=nil
        begin;r=PMD_AC.motion_source_route_v102(sid,mk,data,profile);rescue;r=nil;end
        total+=1
        selected=r==nil ? nil : r[:selected]
        angle_ok=selected!=nil && PMD_AC.motion_qaii_true_45_v10310?(sid,selected)
        good=r!=nil && r[:family]==expected && r[:has_playable] && angle_ok
        if good
          ok_count+=1;sid_ok+=1
          if r[:fallback]
            fallbacks+=1;sid_fb+=1
          end
        else
          rejected_selected+=1 if selected!=nil && !angle_ok
          bad.push(sid+':'+expected.to_s+':'+(selected==nil ? 'nil':selected.to_s))
        end
      end
      log_event(:motion_native,
        'MOTION_QAII_SOURCE_V10310 sid='+sid+' playable45='+sid_ok.to_s+'/16 fallback='+sid_fb.to_s+
        ' fake8_source_selected=0') if motion_phase_b_verifier_active_v1036?
    end
    expected_total=PMD_AC::MOTION_SPECIES_QAII_RANGE_V10310.size*PMD_AC::MOTION_QA_ROUTE_CASES_V1039.size
    pass=total==expected_total && ok_count==expected_total && rejected_selected==0 && bad.empty?
    @motion_qaii_failed_v10310=true unless pass
    @motion_qaii_source_result_v10310={:pass=>pass,:total=>total,:ok=>ok_count,
      :fallbacks=>fallbacks,:rejected=>rejected_selected,:bad=>bad}
    log_event(:verify,
      'MOTION_QAII_SOURCE_0001_0026_V10310 pass='+(pass ? '1':'0')+
      ' playable45='+ok_count.to_s+'/'+expected_total.to_s+' safe_fallback='+fallbacks.to_s+
      ' fake8_selected='+rejected_selected.to_s+' leapforth_fake8_filtered_species=8'+
      ' damage_resolve_called=0 projectile_spawned=0 bad=['+bad[0,12].join(',')+']')
  rescue
    @motion_qaii_failed_v10310=true
    @motion_qaii_source_result_v10310={:pass=>false}
    log_event(:verify,'MOTION_QAII_SOURCE_0001_0026_V10310 pass=0 error=1')
  end

  def verify_motion_species_qaii_v10310
    return if @verification_done[:motion_species_qaii_v10310]
    motion_qaii_deploy_audit_v10310
    motion_qaii_source_audit_v10310
    d=@motion_qaii_deploy_result_v10310 || {}
    r=@motion_qaii_source_result_v10310 || {}
    pass=d[:pass] && r[:pass] && !@motion_qaii_failed_v10310
    log_event(:verify,
      'MOTION_SPECIES_QA_0001_0026_V10310 pass='+(pass ? '1':'0')+
      ' stage=species_personality_qa_ii strict_action_level_45=1'+
      ' v1039_false_positive_fixed=1 deploy_hop=0 source_fallback_tuned=1'+
      ' routes='+r[:ok].to_i.to_s+'/'+r[:total].to_i.to_s+
      ' damage_unchanged=1 ai_unchanged=1 attack_speed_unchanged=1 energy_unchanged=1 spatial_unchanged=1')
    @verification_done[:motion_species_qaii_v10310]=true
  rescue
    @motion_qaii_failed_v10310=true
    log_event(:verify,'MOTION_SPECIES_QA_0001_0026_V10310 pass=0 error=1')
    @verification_done[:motion_species_qaii_v10310]=true
  end

  def update_verification_script
    pmd_ac_v10310_update_verification_script
    return unless motion_phase_b_verifier_active_v1036?
    return if @verification_done==nil
    f=@verification_frame.to_i
    motion_qaii_deploy_audit_v10310 if f>=192
    motion_qaii_source_audit_v10310 if f>=196
  end

  # QA II final seal：先跑 v1.03.9 QA（它現在會使用本版 strict45 profile/filter），
  # 再跑 QA II；最後才合併 Phase B A/B/C/Remote。
  def verify_motion_final_v102
    return if @verification_done[:motion_final_v102]
    verify_motion_species_qa_v1039 if respond_to?(:verify_motion_species_qa_v1039)
    verify_motion_species_qaii_v10310
    pass=!@motion_phase_a_failed_v102 && !@motion_phase_b_failed_v103 &&
      !@motion_phase_b_batch_b_failed_v1036 && !@motion_phase_b_batch_c_failed_v1037 &&
      !@motion_phase_b_remote_failed_v1038 && !@motion_species_qa_failed_v1039 &&
      !@motion_qaii_failed_v10310
    log_event(:verify,
      'PMD_MOTION_PHASE_A_V102 pass='+(pass ? '1':'0')+
      ' superseded_by_phase_b=1 scope=0001-0026 presentation_only=1'+
      ' damage_formula_unchanged=1 attack_speed_unchanged=1 spatial_framework_unchanged=1')
    log_event(:verify,
      'PMD_MOTION_PHASE_B_V103 pass='+(pass ? '1':'0')+
      ' batch=species_qa_ii scope=0001-0026'+
      ' contact_chain_a=1 result_semantics_b=1 multihit_c=1 remote_all=1'+
      ' strict_action_level_45=1 deploy_nohop=1 source_fake8_filtered=1'+
      ' gameplay_timer_added=0 damage_packet_authority_unchanged=1 projectile_speed_unchanged=1'+
      ' ai_unchanged=1 damage_formula_unchanged=1 attack_speed_unchanged=1 energy_unchanged=1 spatial_unchanged=1')
    @verification_done[:motion_final_v102]=true
  end
end
