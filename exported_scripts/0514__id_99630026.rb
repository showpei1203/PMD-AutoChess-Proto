# encoding: UTF-8
#===============================================================================
# ■ PMD AutoChess - Representative Group Tuning I v1.05.29
#===============================================================================
# 【用途】
# 1. 承接 v1.05.28 Windows 實機 56 × 16 = 896 route QA PASS 結果，正式套用第一批
#   「有 Windows 證據」的 Representative Motion candidate tuning。
# 2. 本批只處理 v1.05.28 LOG 明確列出的 16 條 generic Attack candidate：
#    - quadruped:lunge 5 條
#    - avian:lunge 1 條
#    - small:dash/lunge 10 條
#    這些 route 的 :double 均已由 v1.05.28 Audit 證明同時通過 playable、strict45、
#    Anatomy Gate 與 Semantic Gate，因此只調整 presentation candidate priority。
# 3. 不把整個 body/family hotspot 一口氣改掉。像 quadruped:bite / heavy:bite 雖然
#    fallback 熱點高，但「fallback 高」本身不等於畫面錯；必須有更安全替代證據才動。
# 4. v1.05.29 在 v1.05.28 QA 完成後自動做 16-route after-tuning verification，並比較
#    Windows baseline generic Attack 294；預期本批降為 278。fallback 可能仍為 502，
#    因為 :double 在原始 Motion Family contract 中不是 dash/lunge semantic-native。
#    本版不為了讓統計變漂亮而修改 Frozen family classification。
# 5. 將 v1.05.28 調整後剩餘的下一批 candidate 樣本繼續寫入 LOG，供 v1.05.30 使用。
#
# 【主要設定】
# GROUP_TUNING_I_V10529
#   精確 species × family → preferred pose 對照，共 16 routes。
# GROUP_TUNING_BASELINE_GENERIC_ATTACK_V10529 = 294
#   v1.05.28 Windows 實機 baseline。
# GROUP_TUNING_EXPECTED_GENERIC_ATTACK_V10529 = 278
#   第一批 16 route 成功後的預期 generic Attack 數。
# GROUP_TUNING_THRESHOLD_MS_V10529 = 50
#   16-route after-tuning QA 單次性能門檻，沿用全專案 50ms，不放寬。
#
# 【機制規則】
# - 只 alias native_pose_candidates_v061，不改 motion_action_family_v102、Damage、AI、
#   Energy、Attack Wait、Priority、logical Spatial、action hit timing。
# - 只在「species + family 精確命中」且 v1.05.28 safety helper 仍確認 pose 安全時，
#   把 :double 提到 candidate list 第一順位。
# - 0001～0026 curated Motion 完全不在本批 mapping。
# - 若素材、geometry 或 Anatomy/Semantic Gate 日後失效，tuning 自動不套用並回 parent。
# - fallback flag 的原始定義保留。:double 對 dash/lunge 仍可被標示 fallback；這是來源
#   contract 的真實狀態，不在本版竄改。
#
# 【依賴／載入順序】
# - 必須載於 v1.05.28 後、Main 前。
# - 使用 v1.05.28 representative_tuning_pose_safe_v10528。
# - 使用 v1.04.3 MOTION_REPRESENTATIVE_FAMILY_CASES_V1043。
# - 使用 v1.05.28 896-route state 做 before/after 數字比較。
#
# 【事件／腳本呼叫方式】
# - NORMAL battle 自動生效，不需按鍵、不新增 S-menu verifier。
# - 查詢 tuning map：PMD_AC.group_tuning_i_map_v10529
# - 手動跑 16-route QA：PMD_AC.group_tuning_i_qa_v10529
# - 查詢最後 QA：PMD_AC.group_tuning_i_last_qa_v10529
#
# 【LOG】
# BATTLE_REPRESENTATIVE_GROUP_TUNING_I_V10529 START ...
# BATTLE_REPRESENTATIVE_GROUP_TUNING_I_ROUTE_V10529 ...（只列失敗／異常）
# BATTLE_REPRESENTATIVE_GROUP_TUNING_I_SUMMARY_V10529 ...
# BATTLE_REPRESENTATIVE_GROUP_TUNING_I_GROUP_V10529 ...
# BATTLE_REPRESENTATIVE_GROUP_TUNING_NEXT_V10529 ...
#
# 【實際範例】
# - 0029 quadruped:lunge：v1.05.28 為 generic Attack；若 Double 仍通過四項 Gate，
#   v1.05.29 candidate list 會變成 [:double, ...parent...]，Router 實際選 Double。
# - 0069 small:dash / small:lunge 同樣只改 presentation pose source，不改位移終點；
#   真正 dash/lunge displacement 仍由 Spatial Runtime 擁有。
#===============================================================================
$imported={} unless defined?($imported)
$imported['PMD_AutoChess_RepresentativeGroupTuningI_v10529']=true

module PMD_AC
  GROUP_TUNING_BASELINE_GENERIC_ATTACK_V10529=294
  GROUP_TUNING_BASELINE_FALLBACK_V10529=502
  GROUP_TUNING_BASELINE_SELECTED_NATIVE_V10529=394
  GROUP_TUNING_EXPECTED_GENERIC_ATTACK_V10529=278
  GROUP_TUNING_THRESHOLD_MS_V10529=50

  GROUP_TUNING_I_V10529={
    '0029'=>{:lunge=>:double},
    '0209'=>{:lunge=>:double},
    '0244'=>{:lunge=>:double},
    '0431'=>{:lunge=>:double},
    '0492'=>{:lunge=>:double},
    '0164'=>{:lunge=>:double},
    '0069'=>{:dash=>:double,:lunge=>:double},
    '0152'=>{:lunge=>:double},
    '0191'=>{:dash=>:double,:lunge=>:double},
    '0270'=>{:lunge=>:double},
    '0316'=>{:dash=>:double,:lunge=>:double},
    '0412'=>{:lunge=>:double},
    '0494'=>{:lunge=>:double}
  }

  GROUP_TUNING_EXPECTED_BODY_ATTACK_V10529={
    :small=>33,
    :medium=>44,
    :quadruped=>33,
    :heavy=>42,
    :hover=>44,
    :avian=>31,
    :serpentine=>51
  }

  class << self
    alias pmd_ac_v10529_group_tuning_native_pose_candidates_v061 native_pose_candidates_v061 unless method_defined?(:pmd_ac_v10529_group_tuning_native_pose_candidates_v061)

    def group_tuning_i_map_v10529
      GROUP_TUNING_I_V10529
    end

    def group_tuning_i_route_count_v10529
      n=0
      GROUP_TUNING_I_V10529.each_value{|h| n+=h.size}
      n
    rescue
      0
    end

    def group_tuning_i_preferred_pose_v10529(species,family)
      row=GROUP_TUNING_I_V10529[species.to_s]
      return nil if row==nil
      row[family]
    rescue
      nil
    end

    def group_tuning_i_safe_v10529(species,pose,family)
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
      base=pmd_ac_v10529_group_tuning_native_pose_candidates_v061(species,move_key,data,profile)
      family=motion_action_family_v102(move_key,data,profile)
      pose=group_tuning_i_preferred_pose_v10529(species,family)
      return base if pose==nil
      return base unless group_tuning_i_safe_v10529(species,pose,family)
      out=[pose]
      base.each{|p|out.push(p) if p!=nil && !out.include?(p)}
      @group_tuning_i_hits_v10529={} if @group_tuning_i_hits_v10529==nil
      @group_tuning_i_hits_v10529[species.to_s+':'+family.to_s]=pose
      out
    rescue
      pmd_ac_v10529_group_tuning_native_pose_candidates_v061(species,move_key,data,profile)
    end

    def group_tuning_i_family_case_v10529(family)
      return nil unless const_defined?(:MOTION_REPRESENTATIVE_FAMILY_CASES_V1043)
      MOTION_REPRESENTATIVE_FAMILY_CASES_V1043.each do |row|
        return row if row[0]==family
      end
      nil
    rescue
      nil
    end

    def group_tuning_i_last_qa_v10529
      @group_tuning_i_last_qa_v10529
    end

    def group_tuning_i_qa_v10529(route_state=nil)
      t0=Time.now
      total=0;selected=0;playable=0;strict=0;family_ok=0;safe=0;bad=[]
      GROUP_TUNING_I_V10529.each do |sid,fams|
        fams.each do |family,pose|
          total+=1
          row=group_tuning_i_family_case_v10529(family)
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
          ok_safe=group_tuning_i_safe_v10529(sid,pose,family)
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
      expected_attack=(attack_after==GROUP_TUNING_EXPECTED_GENERIC_ATTACK_V10529)
      groups_ok=true
      if rs!=nil && rs[:groups]!=nil
        GROUP_TUNING_EXPECTED_BODY_ATTACK_V10529.each do |body,expected|
          g=rs[:groups][body]
          groups_ok=false if g==nil || g[:attack].to_i!=expected
        end
      else
        groups_ok=false
      end
      pass=(total==16 && selected==16 && playable==16 && strict==16 && family_ok==16 && safe==16 &&
        route_pass && expected_attack && groups_ok && ms<=GROUP_TUNING_THRESHOLD_MS_V10529 && bad.empty?)
      @group_tuning_i_last_qa_v10529={
        :pass=>pass,:total=>total,:selected=>selected,:playable=>playable,:strict=>strict,
        :family=>family_ok,:safe=>safe,:ms=>ms,:bad=>bad,:route_pass=>route_pass,
        :attack_after=>attack_after,:fallback_after=>fallback_after,:native_after=>native_after,
        :groups_ok=>groups_ok,:attack_reduced=>(attack_after<0 ? 0 : GROUP_TUNING_BASELINE_GENERIC_ATTACK_V10529-attack_after)
      }
      @group_tuning_i_last_qa_v10529
    rescue
      @group_tuning_i_last_qa_v10529={:pass=>false,:total=>0,:selected=>0,:playable=>0,:strict=>0,
        :family=>0,:safe=>0,:ms=>0,:bad=>['exception'],:route_pass=>false,
        :attack_after=>-1,:fallback_after=>-1,:native_after=>-1,:groups_ok=>false,:attack_reduced=>0}
    end
  end
end

class Scene_PMD_AutoChess
  alias pmd_ac_v10529_start_battle start_battle unless method_defined?(:pmd_ac_v10529_start_battle)
  alias pmd_ac_v10529_update update unless method_defined?(:pmd_ac_v10529_update)
  alias pmd_ac_v10529_focus_summary focus_cast_log_summary_v1055 unless method_defined?(:pmd_ac_v10529_focus_summary)

  def start_battle
    r=pmd_ac_v10529_start_battle
    begin
      if respond_to?(:verification_mode) && verification_mode==:normal &&
         !(respond_to?(:production_external_battle_fast_v10613?) && production_external_battle_fast_v10613?)
        @group_tuning_i_reported_v10529=false
        log_event(:battle,'BATTLE_REPRESENTATIVE_GROUP_TUNING_I_V10529 START routes='+
          PMD_AC.group_tuning_i_route_count_v10529.to_i.to_s+
          ' source=v10528_windows_evidence generic_attack_before='+
          PMD_AC::GROUP_TUNING_BASELINE_GENERIC_ATTACK_V10529.to_i.to_s+
          ' expected_after='+PMD_AC::GROUP_TUNING_EXPECTED_GENERIC_ATTACK_V10529.to_i.to_s+
          ' fallback_before='+PMD_AC::GROUP_TUNING_BASELINE_FALLBACK_V10529.to_i.to_s+
          ' family_contract_unchanged=1 motion_core_unchanged=1 gameplay_change=0')
      end
    rescue
    end
    r
  end

  def update
    pmd_ac_v10529_update
    begin
      return unless respond_to?(:verification_mode) && verification_mode==:normal
      return if respond_to?(:production_external_battle_fast_v10613?) && production_external_battle_fast_v10613?
      return if @group_tuning_i_reported_v10529
      s=PMD_AC.representative_route_qa_state_v10528 rescue nil
      if s!=nil && s[:complete]
        q=PMD_AC.group_tuning_i_qa_v10529(s)
        group_tuning_i_log_v10529(q,s)
      end
    rescue
    end
  end

  def group_tuning_i_log_v10529(q=nil,s=nil)
    q ||= PMD_AC.group_tuning_i_last_qa_v10529
    s ||= (PMD_AC.representative_route_qa_state_v10528 rescue nil)
    return false if q==nil || s==nil
    log_event(:battle,'BATTLE_REPRESENTATIVE_GROUP_TUNING_I_SUMMARY_V10529 pass='+(q[:pass] ? '1':'0')+
      ' tuned='+q[:selected].to_i.to_s+'/16 playable='+q[:playable].to_i.to_s+'/16'+
      ' strict45='+q[:strict].to_i.to_s+'/16 family='+q[:family].to_i.to_s+'/16'+
      ' safety='+q[:safe].to_i.to_s+'/16 generic_attack_before='+
      PMD_AC::GROUP_TUNING_BASELINE_GENERIC_ATTACK_V10529.to_i.to_s+
      ' generic_attack_after='+q[:attack_after].to_i.to_s+
      ' reduced='+q[:attack_reduced].to_i.to_s+
      ' fallback_before='+PMD_AC::GROUP_TUNING_BASELINE_FALLBACK_V10529.to_i.to_s+
      ' fallback_after='+q[:fallback_after].to_i.to_s+
      ' selected_native_before='+PMD_AC::GROUP_TUNING_BASELINE_SELECTED_NATIVE_V10529.to_i.to_s+
      ' selected_native_after='+q[:native_after].to_i.to_s+
      ' groups_ok='+(q[:groups_ok] ? '1':'0')+' qa_ms='+q[:ms].to_i.to_s+
      ' threshold_ms='+PMD_AC::GROUP_TUNING_THRESHOLD_MS_V10529.to_i.to_s+
      ' bad=['+(q[:bad]||[]).join(',')+'] gameplay_change=0')
    PMD_AC::GROUP_TUNING_EXPECTED_BODY_ATTACK_V10529.each do |body,expected|
      g=s[:groups][body] || {}
      log_event(:battle,'BATTLE_REPRESENTATIVE_GROUP_TUNING_I_GROUP_V10529 body='+body.to_s+
        ' generic_attack='+g[:attack].to_i.to_s+' expected='+expected.to_i.to_s+
        ' fallback='+g[:fallback].to_i.to_s+' selected_native='+g[:native].to_i.to_s)
    end
    next_rows=s[:tuning] || []
    log_event(:battle,'BATTLE_REPRESENTATIVE_GROUP_TUNING_NEXT_V10529 count='+next_rows.size.to_i.to_s+
      ' candidates=['+next_rows.join(',')+'] source=v10528_after_tuning next_batch=audit_first')
    @group_tuning_i_reported_v10529=true
    true
  rescue
    false
  end

  def focus_cast_log_summary_v1055
    r=pmd_ac_v10529_focus_summary
    return r if respond_to?(:production_external_battle_fast_v10613?) && production_external_battle_fast_v10613?
    begin
      if !@group_tuning_i_reported_v10529
        s=PMD_AC.representative_route_qa_state_v10528 rescue nil
        if s!=nil && s[:complete]
          q=PMD_AC.group_tuning_i_last_qa_v10529
          q=PMD_AC.group_tuning_i_qa_v10529(s) if q==nil
          group_tuning_i_log_v10529(q,s)
        end
      end
    rescue
    end
    r
  end
end
