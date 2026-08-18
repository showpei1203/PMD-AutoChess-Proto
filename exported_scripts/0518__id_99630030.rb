# encoding: UTF-8
#===============================================================================
# ■ PMD AutoChess - Representative Group Tuning V + Candidate Exhaustion Gate v1.05.33
#===============================================================================
# 【用途】
# 1. 承接 v1.05.32 Windows 實機證據，套用第五批 Representative Motion tuning。
# 2. 本批只處理 v1.05.32 LOG 明確列出的 8 條安全 candidate：
#    - 0091 medium：dash -> Double。
#    - 0138 medium：dash / lunge -> Double。
#    - 0203 / 0267 / 0313 / 0408 / 0478 medium：lunge -> Double。
# 3. 這 8 條都由 v1.05.32 Windows Runtime Audit 列為 attack>double candidate；
#    本版只調整 Presentation candidate priority，不修改任何戰鬥邏輯 Authority。
# 4. 預期 generic Attack 由 230 降到 222，medium 由 44 降到 36；其他 body group 不變。
# 5. 修正 v1.05.32 Group Tuning IV verifier 的 exact snapshot drift：後續 tuning 只會讓
#    generic Attack 更低，因此 Batch IV 改採 cumulative-cap；但它自己的 16 條 route
#    仍必須 selected/playable/strict45/family/safety 全 PASS。
# 6. 新增 Candidate Exhaustion Gate：若本批完成後 v1.05.28 Runtime Audit 的下一批
#    safe candidate 為 0，LOG 明確標記 next_gate=representative_visual_fixture；這只代表
#    「現有自動安全規則已無低風險替代」，不宣稱所有 fallback 都已人工最佳化。
# 7. 完整 56×16=896-route QA 仍由 v1.05.28 Runtime Router 真實掃描，50ms 門檻不放寬。
#
# 【主要設定】
# GROUP_TUNING_V_V10533
#   精確 species × family -> preferred pose，共 8 routes。
# GROUP_TUNING_BASELINE_GENERIC_ATTACK_V10533 = 230
#   v1.05.32 Windows 實機總 generic Attack。
# GROUP_TUNING_EXPECTED_GENERIC_ATTACK_V10533 = 222
#   本批 8 條全部成功改用 Double 後的預期總 generic Attack。
# GROUP_TUNING_THRESHOLD_MS_V10533 = 50
#   after-tuning QA 性能門檻，沿用全專案正式值。
#
# 【機制規則】
# - 只 alias native_pose_candidates_v061，不改 Frozen Motion Combat Core。
# - 不改 motion_action_family_v102，不把 Double 偷改成 semantic-native 來美化統計。
# - 只在 species + family 精確命中，且 v1.05.28 safety helper 仍確認 Double 通過
#   playable / strict45 / Anatomy Gate / Semantic Gate 時，將 Double 提到 candidate 第一順位。
# - 若素材、geometry 或 safety gate 日後失效，自動退回 parent candidate list。
# - Damage、HP、AI、Energy、Attack Wait、Priority、hit timing 全不變。
# - logical Spatial x/y、速度、dash/lunge endpoint、push/pull/through Authority 全不變。
# - HOME 仍是本次 logical/action anchor，不是出生點。
# - 0001～0026 curated Motion 不在本批 mapping。
# - Candidate Exhaustion Gate 只讀取 v1.05.28 的 tuning candidate list，不改 Router 行為。
#
# 【依賴／載入順序】
# - 必須載於 v1.05.32 後、Main 前。
# - 使用 v1.05.28 representative_tuning_pose_safe_v10528。
# - 使用 v1.04.3 MOTION_REPRESENTATIVE_FAMILY_CASES_V1043。
# - 使用 v1.05.28 896-route state 驗證本批與 cumulative legacy verifier。
#
# 【事件／腳本呼叫方式】
# - NORMAL battle 自動生效，不需按鍵，不新增 S-menu verifier。
# - 查詢本批 tuning：PMD_AC.group_tuning_v_map_v10533
# - 手動跑本批 QA：PMD_AC.group_tuning_v_qa_v10533
# - 查詢最後 QA：PMD_AC.group_tuning_v_last_qa_v10533
#
# 【LOG】
# BATTLE_REPRESENTATIVE_GROUP_TUNING_V_V10533 START ...
# BATTLE_REPRESENTATIVE_LEGACY_TUNING_VERIFIER_SEAL_V10533 START ...
# BATTLE_REPRESENTATIVE_GROUP_TUNING_V_SUMMARY_V10533 ...
# BATTLE_REPRESENTATIVE_GROUP_TUNING_V_GROUP_V10533 ...
# BATTLE_REPRESENTATIVE_GROUP_TUNING_NEXT_V10533 ...
# BATTLE_REPRESENTATIVE_CANDIDATE_EXHAUSTION_GATE_V10533 ...
# BATTLE_REPRESENTATIVE_LEGACY_TUNING_VERIFIER_SEAL_SUMMARY_V10533 ...
#
# 【實際範例】
# - 0138 medium:dash / lunge 原 route 在 v1.05.32 Audit 為 generic Attack，但 Double
#   已通過 safety gate。v1.05.33 會讓 candidate list 成為 [:double, ...parent...]。
# - 真正 dash / lunge 的位移方向、距離與終點仍由 Spatial Runtime 決定；Double 只負責身體演技。
# - 若 8 條完成後 next candidate count=0，Gate 只會要求下一階段轉入 56 隻實際視覺
#   Fixture / 人工 QA，不會自動把剩餘 fallback 強制改成別的姿勢。
#===============================================================================
$imported={} unless defined?($imported)
$imported['PMD_AutoChess_RepresentativeGroupTuningV_CandidateExhaustionGate_v10533']=true

module PMD_AC
  GROUP_TUNING_BASELINE_GENERIC_ATTACK_V10533=230
  GROUP_TUNING_EXPECTED_GENERIC_ATTACK_V10533=222
  GROUP_TUNING_THRESHOLD_MS_V10533=50

  GROUP_TUNING_V_V10533={
    '0091'=>{:dash=>:double},
    '0138'=>{:dash=>:double,:lunge=>:double},
    '0203'=>{:lunge=>:double},
    '0267'=>{:lunge=>:double},
    '0313'=>{:lunge=>:double},
    '0408'=>{:lunge=>:double},
    '0478'=>{:lunge=>:double}
  }

  GROUP_TUNING_EXPECTED_BODY_ATTACK_V10533={
    :small=>33,
    :medium=>36,
    :quadruped=>33,
    :heavy=>37,
    :hover=>35,
    :avian=>31,
    :serpentine=>17
  }

  class << self
    alias pmd_ac_v10533_group_tuning_native_pose_candidates_v061 native_pose_candidates_v061 unless method_defined?(:pmd_ac_v10533_group_tuning_native_pose_candidates_v061)
    alias pmd_ac_v10533_legacy_group_tuning_iv_qa_v10532 group_tuning_iv_qa_v10532 unless method_defined?(:pmd_ac_v10533_legacy_group_tuning_iv_qa_v10532)

    def group_tuning_v_map_v10533
      GROUP_TUNING_V_V10533
    end

    def group_tuning_v_route_count_v10533
      n=0
      GROUP_TUNING_V_V10533.each_value{|h| n+=h.size}
      n
    rescue
      0
    end

    def group_tuning_v_preferred_pose_v10533(species,family)
      row=GROUP_TUNING_V_V10533[species.to_s]
      return nil if row==nil
      row[family]
    rescue
      nil
    end

    def group_tuning_v_safe_v10533(species,pose,family)
      return false if pose==nil
      if respond_to?(:representative_tuning_pose_safe_v10528)
        return representative_tuning_pose_safe_v10528(species.to_s,pose,family)
      end
      return false unless motion_playable_v102?(species.to_s,pose)
      if respond_to?(:motion_generated_diag_geometry_v1040?)
        return false unless motion_generated_diag_geometry_v1040?(species.to_s,pose)
      end
      true
    rescue
      false
    end

    def native_pose_candidates_v061(species,move_key,data=nil,profile=nil)
      base=pmd_ac_v10533_group_tuning_native_pose_candidates_v061(species,move_key,data,profile)
      family=motion_action_family_v102(move_key,data,profile)
      pose=group_tuning_v_preferred_pose_v10533(species,family)
      return base if pose==nil
      return base unless group_tuning_v_safe_v10533(species,pose,family)
      out=[pose]
      base.each{|p|out.push(p) if p!=nil && !out.include?(p)}
      @group_tuning_v_hits_v10533={} if @group_tuning_v_hits_v10533==nil
      @group_tuning_v_hits_v10533[species.to_s+':'+family.to_s]=pose
      out
    rescue
      pmd_ac_v10533_group_tuning_native_pose_candidates_v061(species,move_key,data,profile)
    end

    def group_tuning_v_family_case_v10533(family)
      return nil unless const_defined?(:MOTION_REPRESENTATIVE_FAMILY_CASES_V1043)
      MOTION_REPRESENTATIVE_FAMILY_CASES_V1043.each do |row|
        return row if row[0]==family
      end
      nil
    rescue
      nil
    end

    def legacy_tuning_groups_under_cap_v10533(route_state,expected_map)
      return false if route_state==nil || route_state[:groups]==nil
      expected_map.each do |body,cap|
        g=route_state[:groups][body]
        return false if g==nil || g[:attack].to_i>cap.to_i
      end
      true
    rescue
      false
    end

    # v1.05.32 歷史 verifier 改採 cumulative cap。自己的 16 routes 仍必須全 PASS。
    def group_tuning_iv_qa_v10532(route_state=nil)
      q=pmd_ac_v10533_legacy_group_tuning_iv_qa_v10532(route_state)
      return q if q==nil || route_state==nil || !route_state[:complete]
      groups_ok=legacy_tuning_groups_under_cap_v10533(route_state,GROUP_TUNING_EXPECTED_BODY_ATTACK_V10532)
      cap_ok=q[:attack_after].to_i<=GROUP_TUNING_EXPECTED_GENERIC_ATTACK_V10532.to_i
      q[:groups_ok]=groups_ok
      q[:attack_reduced]=GROUP_TUNING_BASELINE_GENERIC_ATTACK_V10532.to_i-q[:attack_after].to_i
      q[:pass]=(q[:total].to_i==16 && q[:selected].to_i==16 && q[:playable].to_i==16 &&
        q[:strict].to_i==16 && q[:family].to_i==16 && q[:safe].to_i==16 &&
        q[:route_pass] && cap_ok && groups_ok && q[:ms].to_i<=GROUP_TUNING_THRESHOLD_MS_V10532.to_i &&
        (q[:bad]||[]).empty?)
      q
    rescue
      pmd_ac_v10533_legacy_group_tuning_iv_qa_v10532(route_state)
    end

    def group_tuning_v_last_qa_v10533
      @group_tuning_v_last_qa_v10533
    end

    def group_tuning_v_qa_v10533(route_state=nil)
      t0=Time.now
      total=0;selected=0;playable=0;strict=0;family_ok=0;safe=0;bad=[]
      GROUP_TUNING_V_V10533.each do |sid,fams|
        fams.each do |family,pose|
          total+=1
          row=group_tuning_v_family_case_v10533(family)
          if row==nil
            bad.push(sid+':'+family.to_s+'=case_nil') if bad.size<16
            next
          end
          r=motion_source_route_v102(sid,row[1],row[2],row[3])
          sel=r==nil ? nil : r[:selected]
          ok_sel=(sel==pose)
          ok_play=(r!=nil && r[:has_playable])
          ok_fam=(r!=nil && r[:family]==family)
          ok_strict=false
          begin
            ok_strict=sel!=nil && motion_generated_diag_geometry_v1040?(sid,sel)
          rescue
            ok_strict=false
          end
          ok_safe=group_tuning_v_safe_v10533(sid,pose,family)
          selected+=1 if ok_sel
          playable+=1 if ok_play
          family_ok+=1 if ok_fam
          strict+=1 if ok_strict
          safe+=1 if ok_safe
          if !ok_sel || !ok_play || !ok_fam || !ok_strict || !ok_safe
            bad.push(sid+':'+family.to_s+'='+(sel==nil ? 'nil' : sel.to_s)+
              ':sel'+(ok_sel ? '1':'0')+'p'+(ok_play ? '1':'0')+'s'+(ok_strict ? '1':'0')+
              'f'+(ok_fam ? '1':'0')+'q'+(ok_safe ? '1':'0')) if bad.size<16
          end
        end
      end
      ms=((Time.now-t0)*1000.0).round
      rs=route_state
      attack_after=rs==nil ? -1 : rs[:attack].to_i
      fallback_after=rs==nil ? -1 : rs[:fallback].to_i
      native_after=rs==nil ? -1 : rs[:native].to_i
      route_pass=rs!=nil && rs[:complete] && rs[:pass]
      expected_attack=(attack_after==GROUP_TUNING_EXPECTED_GENERIC_ATTACK_V10533)
      groups_ok=true
      if rs!=nil && rs[:groups]!=nil
        GROUP_TUNING_EXPECTED_BODY_ATTACK_V10533.each do |body,expected|
          g=rs[:groups][body]
          groups_ok=false if g==nil || g[:attack].to_i!=expected
        end
      else
        groups_ok=false
      end
      expected_total=group_tuning_v_route_count_v10533
      pass=(total==expected_total && selected==expected_total && playable==expected_total &&
        strict==expected_total && family_ok==expected_total && safe==expected_total &&
        route_pass && expected_attack && groups_ok && ms<=GROUP_TUNING_THRESHOLD_MS_V10533 && bad.empty?)
      next_rows=rs==nil ? [] : (rs[:tuning] || [])
      @group_tuning_v_last_qa_v10533={
        :pass=>pass,:total=>total,:selected=>selected,:playable=>playable,:strict=>strict,
        :family=>family_ok,:safe=>safe,:ms=>ms,:bad=>bad,:route_pass=>route_pass,
        :attack_after=>attack_after,:fallback_after=>fallback_after,:native_after=>native_after,
        :groups_ok=>groups_ok,:next_count=>next_rows.size,
        :attack_reduced=>(attack_after<0 ? 0 : GROUP_TUNING_BASELINE_GENERIC_ATTACK_V10533-attack_after)
      }
      @group_tuning_v_last_qa_v10533
    rescue
      @group_tuning_v_last_qa_v10533={:pass=>false,:total=>0,:selected=>0,:playable=>0,:strict=>0,
        :family=>0,:safe=>0,:ms=>0,:bad=>['exception'],:route_pass=>false,
        :attack_after=>-1,:fallback_after=>-1,:native_after=>-1,:groups_ok=>false,
        :next_count=>-1,:attack_reduced=>0}
    end
  end
end

class Scene_PMD_AutoChess
  alias pmd_ac_v10533_start_battle start_battle unless method_defined?(:pmd_ac_v10533_start_battle)
  alias pmd_ac_v10533_update update unless method_defined?(:pmd_ac_v10533_update)
  alias pmd_ac_v10533_focus_summary focus_cast_log_summary_v1055 unless method_defined?(:pmd_ac_v10533_focus_summary)

  def start_battle
    r=pmd_ac_v10533_start_battle
    begin
      if respond_to?(:verification_mode) && verification_mode==:normal &&
         !(respond_to?(:production_external_battle_fast_v10613?) && production_external_battle_fast_v10613?)
        @group_tuning_v_reported_v10533=false
        log_event(:battle,'BATTLE_REPRESENTATIVE_GROUP_TUNING_V_V10533 START routes='+
          PMD_AC.group_tuning_v_route_count_v10533.to_i.to_s+
          ' source=v10532_windows_evidence generic_attack_before='+
          PMD_AC::GROUP_TUNING_BASELINE_GENERIC_ATTACK_V10533.to_i.to_s+
          ' expected_after='+PMD_AC::GROUP_TUNING_EXPECTED_GENERIC_ATTACK_V10533.to_i.to_s+
          ' body=medium pose=double family_contract_unchanged=1 motion_core_unchanged=1 gameplay_change=0')
        log_event(:battle,'BATTLE_REPRESENTATIVE_LEGACY_TUNING_VERIFIER_SEAL_V10533 START'+
          ' batch_i_cap=278 batch_ii_cap=262 batch_iii_cap=246 batch_iv_cap=230 cumulative_cap=1'+
          ' own_routes_still_strict=1 behavior_change=verifier_only')
      end
    rescue
    end
    r
  end

  def update
    pmd_ac_v10533_update
    begin
      return unless respond_to?(:verification_mode) && verification_mode==:normal
      return if respond_to?(:production_external_battle_fast_v10613?) && production_external_battle_fast_v10613?
      return if @group_tuning_v_reported_v10533
      s=PMD_AC.representative_route_qa_state_v10528 rescue nil
      if s!=nil && s[:complete]
        q=PMD_AC.group_tuning_v_qa_v10533(s)
        group_tuning_v_log_v10533(q,s)
      end
    rescue
    end
  end

  def group_tuning_v_log_v10533(q=nil,s=nil)
    q ||= PMD_AC.group_tuning_v_last_qa_v10533
    s ||= (PMD_AC.representative_route_qa_state_v10528 rescue nil)
    return false if q==nil || s==nil
    expected=PMD_AC.group_tuning_v_route_count_v10533.to_i
    log_event(:battle,'BATTLE_REPRESENTATIVE_GROUP_TUNING_V_SUMMARY_V10533 pass='+(q[:pass] ? '1':'0')+
      ' tuned='+q[:selected].to_i.to_s+'/'+expected.to_s+
      ' playable='+q[:playable].to_i.to_s+'/'+expected.to_s+
      ' strict45='+q[:strict].to_i.to_s+'/'+expected.to_s+
      ' family='+q[:family].to_i.to_s+'/'+expected.to_s+
      ' safety='+q[:safe].to_i.to_s+'/'+expected.to_s+
      ' generic_attack_before='+PMD_AC::GROUP_TUNING_BASELINE_GENERIC_ATTACK_V10533.to_i.to_s+
      ' generic_attack_after='+q[:attack_after].to_i.to_s+
      ' reduced='+q[:attack_reduced].to_i.to_s+
      ' fallback_after='+q[:fallback_after].to_i.to_s+
      ' selected_native_after='+q[:native_after].to_i.to_s+
      ' groups_ok='+(q[:groups_ok] ? '1':'0')+' qa_ms='+q[:ms].to_i.to_s+
      ' threshold_ms='+PMD_AC::GROUP_TUNING_THRESHOLD_MS_V10533.to_i.to_s+
      ' bad=['+(q[:bad]||[]).join(',')+'] gameplay_change=0')
    PMD_AC::GROUP_TUNING_EXPECTED_BODY_ATTACK_V10533.each do |body,expected_body|
      g=s[:groups][body] || {}
      log_event(:battle,'BATTLE_REPRESENTATIVE_GROUP_TUNING_V_GROUP_V10533 body='+body.to_s+
        ' generic_attack='+g[:attack].to_i.to_s+' expected='+expected_body.to_i.to_s+
        ' fallback='+g[:fallback].to_i.to_s+' selected_native='+g[:native].to_i.to_s)
    end
    next_rows=s[:tuning] || []
    log_event(:battle,'BATTLE_REPRESENTATIVE_GROUP_TUNING_NEXT_V10533 count='+next_rows.size.to_i.to_s+
      ' candidates=['+next_rows.join(',')+'] source=v10528_after_tuning_i_ii_iii_iv_v next_batch='+
      (next_rows.empty? ? 'representative_visual_fixture':'audit_first'))
    log_event(:battle,'BATTLE_REPRESENTATIVE_CANDIDATE_EXHAUSTION_GATE_V10533'+
      ' safe_candidates_remaining='+next_rows.size.to_i.to_s+
      ' exhausted='+(next_rows.empty? ? '1':'0')+
      ' next_gate='+(next_rows.empty? ? 'representative_visual_fixture':'group_tuning_next')+
      ' forced_generic_replacement=0 family_contract_unchanged=1 behavior_change=observer_only')
    log_event(:battle,'BATTLE_REPRESENTATIVE_LEGACY_TUNING_VERIFIER_SEAL_SUMMARY_V10533'+
      ' batch_i='+(begin q1=PMD_AC.group_tuning_i_last_qa_v10529;q1!=nil && q1[:pass] ? '1':'0' rescue '0' end)+
      ' batch_ii='+(begin q2=PMD_AC.group_tuning_ii_last_qa_v10530;q2!=nil && q2[:pass] ? '1':'0' rescue '0' end)+
      ' batch_iii='+(begin q3=PMD_AC.group_tuning_iii_last_qa_v10531;q3!=nil && q3[:pass] ? '1':'0' rescue '0' end)+
      ' batch_iv='+(begin q4=PMD_AC.group_tuning_iv_last_qa_v10532;q4!=nil && q4[:pass] ? '1':'0' rescue '0' end)+
      ' cumulative_generic_attack='+s[:attack].to_i.to_s+' verifier_only=1')
    @group_tuning_v_reported_v10533=true
    true
  rescue
    false
  end

  def focus_cast_log_summary_v1055
    r=pmd_ac_v10533_focus_summary
    return r if respond_to?(:production_external_battle_fast_v10613?) && production_external_battle_fast_v10613?
    begin
      if !@group_tuning_v_reported_v10533
        s=PMD_AC.representative_route_qa_state_v10528 rescue nil
        if s!=nil && s[:complete]
          q=PMD_AC.group_tuning_v_last_qa_v10533
          q=PMD_AC.group_tuning_v_qa_v10533(s) if q==nil
          group_tuning_v_log_v10533(q,s)
        end
      end
    rescue
    end
    r
  end
end
