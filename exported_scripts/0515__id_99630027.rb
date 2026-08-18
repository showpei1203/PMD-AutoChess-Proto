# encoding: UTF-8
#===============================================================================
# ■ PMD AutoChess - Representative Group Tuning II v1.05.30
#===============================================================================
# 【用途】
# 1. 承接 v1.05.29 Windows 實機 Group Tuning I PASS 結果，套用第二批 16 條
#    「有 Windows Runtime QA 證據」的 Representative Motion tuning。
# 2. 本批只處理 v1.05.29 LOG 明確列出的 serpentine candidate：
#    - 0095 大岩蛇：strike / lunge / punch / kick → Swing
#    - 0147 哈克龍：strike / lunge / punch / kick → Swing
#    - 0206 土龍弟弟：strike / lunge / punch / kick → Swing
#    - 0336 飯匙蛇：strike / lunge / punch / kick → Swing
# 3. 四隻物種的 Swing 均已由 Windows v1.05.29 Audit 列為安全替代，且目前素材中
#    Swing-Anim.png 為 direct native action；本版只調整 presentation candidate priority。
# 4. v1.05.30 仍重新跑完整 56 × 16 = 896 route QA。預期 generic Attack 由
#    278 降為 262；serpentine 由 51 降為 35。fallback 預期仍可維持 502，因為
#    本版不修改 Frozen Motion Family contract，也不把 Swing 偷改成 semantic-native。
# 5. 調整完成後，繼續輸出 v1.05.28 Audit 在「目前所有 tuning 已套用後」找到的
#    下一批安全 candidate，供 v1.05.31 Group Tuning III 使用。
#
# 【主要設定】
# GROUP_TUNING_II_V10530
#   精確 species × family → preferred pose，共 16 routes。
# GROUP_TUNING_BASELINE_GENERIC_ATTACK_V10530 = 278
#   v1.05.29 Windows 實機 baseline。
# GROUP_TUNING_EXPECTED_GENERIC_ATTACK_V10530 = 262
#   第二批 16 route 成功後的預期 generic Attack 數。
# GROUP_TUNING_THRESHOLD_MS_V10530 = 50
#   QA 性能門檻，沿用全專案 50ms，不放寬。
#
# 【機制規則】
# - 只 alias native_pose_candidates_v061，不修改 Frozen Motion Core。
# - 只在 species + family 精確命中，且 v1.05.28 safety helper 仍確認 Swing 通過
#   playable / strict45 / Anatomy Gate / Semantic Gate 時，把 :swing 放到 candidate 首位。
# - 不改 Damage、HP、AI、Energy、Attack Wait、Priority、logical Spatial、hit timing。
# - 真正 dash/lunge 位移仍由既有 Spatial Runtime 決定，Swing 只提供身體演技。
# - 0001～0026 curated Motion 不在本批 mapping。
# - 若素材或 safety gate 日後不再成立，自動退回 parent candidate list。
#
# 【依賴／載入順序】
# - 必須載於 v1.05.29 後、Main 前。
# - 使用 v1.05.28 representative_tuning_pose_safe_v10528。
# - 使用 v1.04.3 MOTION_REPRESENTATIVE_FAMILY_CASES_V1043。
# - 使用 v1.05.28 896-route Runtime QA state 做 before/after 驗證。
#
# 【事件／腳本呼叫方式】
# - NORMAL battle 自動生效，不需按鍵，不新增 S-menu verifier。
# - 查詢 tuning map：PMD_AC.group_tuning_ii_map_v10530
# - 手動跑 16-route QA：PMD_AC.group_tuning_ii_qa_v10530
# - 查詢最後 QA：PMD_AC.group_tuning_ii_last_qa_v10530
#
# 【LOG】
# BATTLE_REPRESENTATIVE_GROUP_TUNING_II_V10530 START ...
# BATTLE_REPRESENTATIVE_GROUP_TUNING_II_SUMMARY_V10530 ...
# BATTLE_REPRESENTATIVE_GROUP_TUNING_II_GROUP_V10530 ...
# BATTLE_REPRESENTATIVE_GROUP_TUNING_NEXT_V10530 ...
#
# 【實際範例】
# - 0095 serpentine:lunge 在 v1.05.29 為 generic Attack；v1.05.30 若 Swing 仍通過
#   四項 safety gate，candidate list 會變成 [:swing, ...parent...]，Router 選 Swing。
# - 這不會改變大岩蛇真正的追擊距離或終點，只把 generic Attack 身體動作換成較符合
#   蛇型身體的甩身／擺動演技。
#===============================================================================
$imported={} unless defined?($imported)
$imported['PMD_AutoChess_RepresentativeGroupTuningII_v10530']=true

module PMD_AC
  GROUP_TUNING_BASELINE_GENERIC_ATTACK_V10530=278
  GROUP_TUNING_BASELINE_FALLBACK_V10530=502
  GROUP_TUNING_BASELINE_SELECTED_NATIVE_V10530=394
  GROUP_TUNING_EXPECTED_GENERIC_ATTACK_V10530=262
  GROUP_TUNING_THRESHOLD_MS_V10530=50

  GROUP_TUNING_II_V10530={
    '0095'=>{:strike=>:swing,:lunge=>:swing,:punch=>:swing,:kick=>:swing},
    '0147'=>{:strike=>:swing,:lunge=>:swing,:punch=>:swing,:kick=>:swing},
    '0206'=>{:strike=>:swing,:lunge=>:swing,:punch=>:swing,:kick=>:swing},
    '0336'=>{:strike=>:swing,:lunge=>:swing,:punch=>:swing,:kick=>:swing}
  }

  GROUP_TUNING_EXPECTED_BODY_ATTACK_V10530={
    :small=>33,
    :medium=>44,
    :quadruped=>33,
    :heavy=>42,
    :hover=>44,
    :avian=>31,
    :serpentine=>35
  }

  class << self
    alias pmd_ac_v10530_group_tuning_native_pose_candidates_v061 native_pose_candidates_v061 unless method_defined?(:pmd_ac_v10530_group_tuning_native_pose_candidates_v061)

    def group_tuning_ii_map_v10530
      GROUP_TUNING_II_V10530
    end

    def group_tuning_ii_route_count_v10530
      n=0
      GROUP_TUNING_II_V10530.each_value{|h| n+=h.size}
      n
    rescue
      0
    end

    def group_tuning_ii_preferred_pose_v10530(species,family)
      row=GROUP_TUNING_II_V10530[species.to_s]
      return nil if row==nil
      row[family]
    rescue
      nil
    end

    def group_tuning_ii_safe_v10530(species,pose,family)
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
      base=pmd_ac_v10530_group_tuning_native_pose_candidates_v061(species,move_key,data,profile)
      family=motion_action_family_v102(move_key,data,profile)
      pose=group_tuning_ii_preferred_pose_v10530(species,family)
      return base if pose==nil
      return base unless group_tuning_ii_safe_v10530(species,pose,family)
      out=[pose]
      base.each{|p|out.push(p) if p!=nil && !out.include?(p)}
      @group_tuning_ii_hits_v10530={} if @group_tuning_ii_hits_v10530==nil
      @group_tuning_ii_hits_v10530[species.to_s+':'+family.to_s]=pose
      out
    rescue
      pmd_ac_v10530_group_tuning_native_pose_candidates_v061(species,move_key,data,profile)
    end

    def group_tuning_ii_family_case_v10530(family)
      return nil unless const_defined?(:MOTION_REPRESENTATIVE_FAMILY_CASES_V1043)
      MOTION_REPRESENTATIVE_FAMILY_CASES_V1043.each do |row|
        return row if row[0]==family
      end
      nil
    rescue
      nil
    end

    def group_tuning_ii_last_qa_v10530
      @group_tuning_ii_last_qa_v10530
    end

    def group_tuning_ii_qa_v10530(route_state=nil)
      t0=Time.now
      total=0;selected=0;playable=0;strict=0;family_ok=0;safe=0;bad=[]
      GROUP_TUNING_II_V10530.each do |sid,fams|
        fams.each do |family,pose|
          total+=1
          row=group_tuning_ii_family_case_v10530(family)
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
          ok_safe=group_tuning_ii_safe_v10530(sid,pose,family)
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
      expected_attack=(attack_after==GROUP_TUNING_EXPECTED_GENERIC_ATTACK_V10530)
      groups_ok=true
      if rs!=nil && rs[:groups]!=nil
        GROUP_TUNING_EXPECTED_BODY_ATTACK_V10530.each do |body,expected|
          g=rs[:groups][body]
          groups_ok=false if g==nil || g[:attack].to_i!=expected
        end
      else
        groups_ok=false
      end
      pass=(total==16 && selected==16 && playable==16 && strict==16 && family_ok==16 && safe==16 &&
        route_pass && expected_attack && groups_ok && ms<=GROUP_TUNING_THRESHOLD_MS_V10530 && bad.empty?)
      @group_tuning_ii_last_qa_v10530={
        :pass=>pass,:total=>total,:selected=>selected,:playable=>playable,:strict=>strict,
        :family=>family_ok,:safe=>safe,:ms=>ms,:bad=>bad,:route_pass=>route_pass,
        :attack_after=>attack_after,:fallback_after=>fallback_after,:native_after=>native_after,
        :groups_ok=>groups_ok,:attack_reduced=>(attack_after<0 ? 0 : GROUP_TUNING_BASELINE_GENERIC_ATTACK_V10530-attack_after)
      }
      @group_tuning_ii_last_qa_v10530
    rescue
      @group_tuning_ii_last_qa_v10530={:pass=>false,:total=>0,:selected=>0,:playable=>0,:strict=>0,
        :family=>0,:safe=>0,:ms=>0,:bad=>['exception'],:route_pass=>false,
        :attack_after=>-1,:fallback_after=>-1,:native_after=>-1,:groups_ok=>false,:attack_reduced=>0}
    end
  end
end

class Scene_PMD_AutoChess
  alias pmd_ac_v10530_start_battle start_battle unless method_defined?(:pmd_ac_v10530_start_battle)
  alias pmd_ac_v10530_update update unless method_defined?(:pmd_ac_v10530_update)
  alias pmd_ac_v10530_focus_summary focus_cast_log_summary_v1055 unless method_defined?(:pmd_ac_v10530_focus_summary)

  def start_battle
    r=pmd_ac_v10530_start_battle
    begin
      if respond_to?(:verification_mode) && verification_mode==:normal &&
         !(respond_to?(:production_external_battle_fast_v10613?) && production_external_battle_fast_v10613?)
        @group_tuning_ii_reported_v10530=false
        log_event(:battle,'BATTLE_REPRESENTATIVE_GROUP_TUNING_II_V10530 START routes='+
          PMD_AC.group_tuning_ii_route_count_v10530.to_i.to_s+
          ' source=v10529_windows_evidence generic_attack_before='+
          PMD_AC::GROUP_TUNING_BASELINE_GENERIC_ATTACK_V10530.to_i.to_s+
          ' expected_after='+PMD_AC::GROUP_TUNING_EXPECTED_GENERIC_ATTACK_V10530.to_i.to_s+
          ' fallback_before='+PMD_AC::GROUP_TUNING_BASELINE_FALLBACK_V10530.to_i.to_s+
          ' species=0095,0147,0206,0336 pose=swing family_contract_unchanged=1 motion_core_unchanged=1 gameplay_change=0')
      end
    rescue
    end
    r
  end

  def update
    pmd_ac_v10530_update
    begin
      return unless respond_to?(:verification_mode) && verification_mode==:normal
      return if respond_to?(:production_external_battle_fast_v10613?) && production_external_battle_fast_v10613?
      return if @group_tuning_ii_reported_v10530
      s=PMD_AC.representative_route_qa_state_v10528 rescue nil
      if s!=nil && s[:complete]
        q=PMD_AC.group_tuning_ii_qa_v10530(s)
        group_tuning_ii_log_v10530(q,s)
      end
    rescue
    end
  end

  def group_tuning_ii_log_v10530(q=nil,s=nil)
    q ||= PMD_AC.group_tuning_ii_last_qa_v10530
    s ||= (PMD_AC.representative_route_qa_state_v10528 rescue nil)
    return false if q==nil || s==nil
    log_event(:battle,'BATTLE_REPRESENTATIVE_GROUP_TUNING_II_SUMMARY_V10530 pass='+(q[:pass] ? '1':'0')+
      ' tuned='+q[:selected].to_i.to_s+'/16 playable='+q[:playable].to_i.to_s+'/16'+
      ' strict45='+q[:strict].to_i.to_s+'/16 family='+q[:family].to_i.to_s+'/16'+
      ' safety='+q[:safe].to_i.to_s+'/16 generic_attack_before='+
      PMD_AC::GROUP_TUNING_BASELINE_GENERIC_ATTACK_V10530.to_i.to_s+
      ' generic_attack_after='+q[:attack_after].to_i.to_s+
      ' reduced='+q[:attack_reduced].to_i.to_s+
      ' fallback_before='+PMD_AC::GROUP_TUNING_BASELINE_FALLBACK_V10530.to_i.to_s+
      ' fallback_after='+q[:fallback_after].to_i.to_s+
      ' selected_native_before='+PMD_AC::GROUP_TUNING_BASELINE_SELECTED_NATIVE_V10530.to_i.to_s+
      ' selected_native_after='+q[:native_after].to_i.to_s+
      ' groups_ok='+(q[:groups_ok] ? '1':'0')+' qa_ms='+q[:ms].to_i.to_s+
      ' threshold_ms='+PMD_AC::GROUP_TUNING_THRESHOLD_MS_V10530.to_i.to_s+
      ' bad=['+(q[:bad]||[]).join(',')+'] gameplay_change=0')
    PMD_AC::GROUP_TUNING_EXPECTED_BODY_ATTACK_V10530.each do |body,expected|
      g=s[:groups][body] || {}
      log_event(:battle,'BATTLE_REPRESENTATIVE_GROUP_TUNING_II_GROUP_V10530 body='+body.to_s+
        ' generic_attack='+g[:attack].to_i.to_s+' expected='+expected.to_i.to_s+
        ' fallback='+g[:fallback].to_i.to_s+' selected_native='+g[:native].to_i.to_s)
    end
    next_rows=s[:tuning] || []
    log_event(:battle,'BATTLE_REPRESENTATIVE_GROUP_TUNING_NEXT_V10530 count='+next_rows.size.to_i.to_s+
      ' candidates=['+next_rows.join(',')+'] source=v10528_after_tuning_i_ii next_batch=audit_first')
    @group_tuning_ii_reported_v10530=true
    true
  rescue
    false
  end

  def focus_cast_log_summary_v1055
    r=pmd_ac_v10530_focus_summary
    return r if respond_to?(:production_external_battle_fast_v10613?) && production_external_battle_fast_v10613?
    begin
      if !@group_tuning_ii_reported_v10530
        s=PMD_AC.representative_route_qa_state_v10528 rescue nil
        if s!=nil && s[:complete]
          q=PMD_AC.group_tuning_ii_last_qa_v10530
          q=PMD_AC.group_tuning_ii_qa_v10530(s) if q==nil
          group_tuning_ii_log_v10530(q,s)
        end
      end
    rescue
    end
    r
  end
end
