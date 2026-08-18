# encoding: UTF-8
#===============================================================================
# ■ PMD AutoChess - Representative Group Tuning III + Legacy Verifier Seal v1.05.31
#===============================================================================
# 【用途】
# 1. 承接 v1.05.30 Windows 實機證據，套用第三批 Representative Motion tuning。
# 2. 本批只處理 v1.05.30 LOG 明確列出的 16 條 serpentine candidate：
#    - 0340 鯰魚王：strike / lunge / punch / kick -> Swing
#    - 0350 美納斯：strike / dash / lunge / punch / kick -> Swing
#    - 0367 獵斑魚：strike / dash / lunge / punch / kick -> Swing
#    - 0384 烈空坐：strike / lunge -> Swing
# 3. 這 16 條 Swing 均已由 v1.05.30 Audit 證明有 playable、strict45、Anatomy Gate、
#    Semantic Gate 的安全替代證據；本版只調整 Presentation candidate priority。
# 4. 修正 v1.05.29 / v1.05.30 歷史 verifier 的「exact snapshot expectation drift」。
#    後續 tuning 會繼續降低 generic Attack，因此早期 verifier 不應要求總數永遠剛好
#    等於當時的 278 / 262。v1.05.31 改為 cumulative-cap：
#      - v1.05.29：generic Attack <= 278，且各 body group <= 當時 cap。
#      - v1.05.30：generic Attack <= 262，且各 body group <= 當時 cap。
#    每一批自己那 16 條 route 的 selected/playable/strict45/family/safety 仍必須全 PASS。
# 5. 完整 896-route QA 仍由 v1.05.28 Runtime Router 真實掃描，50ms 門檻不放寬。
#
# 【主要設定】
# GROUP_TUNING_III_V10531
#   精確 species × family -> preferred pose，共 16 routes。
# GROUP_TUNING_BASELINE_GENERIC_ATTACK_V10531 = 262
#   v1.05.30 Windows 實機總 generic Attack。
# GROUP_TUNING_EXPECTED_GENERIC_ATTACK_V10531 = 246
#   本批 16 條成功改用 Swing 後的預期總 generic Attack。
# GROUP_TUNING_THRESHOLD_MS_V10531 = 50
#   本批 after-tuning QA 門檻，沿用正式 50ms。
#
# 【機制規則】
# - 只 alias native_pose_candidates_v061，不改 Frozen Motion Combat Core。
# - 不改 motion_action_family_v102，不把 Swing 偷改成 semantic-native 來美化統計。
# - 不改 Damage、HP、AI、Energy、Attack Wait、Priority、hit timing。
# - 不改 logical Spatial x/y、速度、dash/lunge endpoint、push/pull/through ownership。
# - HOME 仍是本次 logical/action anchor，不是出生點。
# - 只在 species + family 精確命中且 v1.05.28 safety helper 仍確認安全時，把 Swing
#   提到 candidate list 第一順位；任何素材／geometry／Anatomy／Semantic Gate 失效時
#   自動回 parent route。
# - 0001～0026 curated Motion 不在本批 mapping。
# - v1.05.29 / v1.05.30 舊腳本本體 byte-for-byte 保留；相容修正只用 trailing method
#   wrapper，不回頭修改已封裝版本。
#
# 【依賴／載入順序】
# - 必須載於 v1.05.30 後、Main 前。
# - 使用 v1.05.28 representative_tuning_pose_safe_v10528。
# - 使用 v1.04.3 MOTION_REPRESENTATIVE_FAMILY_CASES_V1043。
# - 使用 v1.05.28 896-route state 做 cumulative after-tuning 驗證。
#
# 【事件／腳本呼叫方式】
# - NORMAL battle 自動生效，不需按鍵，不新增 S-menu verifier。
# - 查詢本批 tuning：PMD_AC.group_tuning_iii_map_v10531
# - 手動跑本批 QA：PMD_AC.group_tuning_iii_qa_v10531
# - 查詢最後 QA：PMD_AC.group_tuning_iii_last_qa_v10531
#
# 【LOG】
# BATTLE_REPRESENTATIVE_GROUP_TUNING_III_V10531 START ...
# BATTLE_REPRESENTATIVE_LEGACY_TUNING_VERIFIER_SEAL_V10531 START ...
# BATTLE_REPRESENTATIVE_GROUP_TUNING_III_SUMMARY_V10531 ...
# BATTLE_REPRESENTATIVE_GROUP_TUNING_III_GROUP_V10531 ...
# BATTLE_REPRESENTATIVE_GROUP_TUNING_NEXT_V10531 ...
#
# 【實際範例】
# - 0384 烈空坐 lunge：原 route 會落到 generic Attack；若 Swing 仍通過四項 safety
#   gate，v1.05.31 candidate list 會成為 [:swing, ...parent...]，Router 選 Swing。
# - lunge 真正位移距離、方向與終點仍由既有 Spatial Runtime 決定；Swing 只負責身體
#   演技，不會因為換動畫把烈空坐甩去另一個戰術座標。
#===============================================================================
$imported={} unless defined?($imported)
$imported['PMD_AutoChess_RepresentativeGroupTuningIII_LegacyVerifierSeal_v10531']=true

module PMD_AC
  GROUP_TUNING_BASELINE_GENERIC_ATTACK_V10531=262
  GROUP_TUNING_EXPECTED_GENERIC_ATTACK_V10531=246
  GROUP_TUNING_THRESHOLD_MS_V10531=50

  GROUP_TUNING_III_V10531={
    '0340'=>{:strike=>:swing,:lunge=>:swing,:punch=>:swing,:kick=>:swing},
    '0350'=>{:strike=>:swing,:dash=>:swing,:lunge=>:swing,:punch=>:swing,:kick=>:swing},
    '0367'=>{:strike=>:swing,:dash=>:swing,:lunge=>:swing,:punch=>:swing,:kick=>:swing},
    '0384'=>{:strike=>:swing,:lunge=>:swing}
  }

  GROUP_TUNING_EXPECTED_BODY_ATTACK_V10531={
    :small=>33,
    :medium=>44,
    :quadruped=>33,
    :heavy=>42,
    :hover=>44,
    :avian=>31,
    :serpentine=>19
  }

  class << self
    alias pmd_ac_v10531_group_tuning_native_pose_candidates_v061 native_pose_candidates_v061 unless method_defined?(:pmd_ac_v10531_group_tuning_native_pose_candidates_v061)
    alias pmd_ac_v10531_legacy_group_tuning_i_qa_v10529 group_tuning_i_qa_v10529 unless method_defined?(:pmd_ac_v10531_legacy_group_tuning_i_qa_v10529)
    alias pmd_ac_v10531_legacy_group_tuning_ii_qa_v10530 group_tuning_ii_qa_v10530 unless method_defined?(:pmd_ac_v10531_legacy_group_tuning_ii_qa_v10530)

    def group_tuning_iii_map_v10531
      GROUP_TUNING_III_V10531
    end

    def group_tuning_iii_route_count_v10531
      n=0
      GROUP_TUNING_III_V10531.each_value{|h| n+=h.size}
      n
    rescue
      0
    end

    def group_tuning_iii_preferred_pose_v10531(species,family)
      row=GROUP_TUNING_III_V10531[species.to_s]
      return nil if row==nil
      row[family]
    rescue
      nil
    end

    def group_tuning_iii_safe_v10531(species,pose,family)
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
      base=pmd_ac_v10531_group_tuning_native_pose_candidates_v061(species,move_key,data,profile)
      family=motion_action_family_v102(move_key,data,profile)
      pose=group_tuning_iii_preferred_pose_v10531(species,family)
      return base if pose==nil
      return base unless group_tuning_iii_safe_v10531(species,pose,family)
      out=[pose]
      base.each{|p|out.push(p) if p!=nil && !out.include?(p)}
      @group_tuning_iii_hits_v10531={} if @group_tuning_iii_hits_v10531==nil
      @group_tuning_iii_hits_v10531[species.to_s+':'+family.to_s]=pose
      out
    rescue
      pmd_ac_v10531_group_tuning_native_pose_candidates_v061(species,move_key,data,profile)
    end

    def group_tuning_iii_family_case_v10531(family)
      return nil unless const_defined?(:MOTION_REPRESENTATIVE_FAMILY_CASES_V1043)
      MOTION_REPRESENTATIVE_FAMILY_CASES_V1043.each do |row|
        return row if row[0]==family
      end
      nil
    rescue
      nil
    end

    def legacy_tuning_groups_under_cap_v10531(route_state,expected_map)
      return false if route_state==nil || route_state[:groups]==nil
      expected_map.each do |body,cap|
        g=route_state[:groups][body]
        return false if g==nil || g[:attack].to_i>cap.to_i
      end
      true
    rescue
      false
    end

    # v1.05.29 歷史 verifier：自己的 16 條仍需全正確；總 generic Attack 與 body group
    # 改採 <= 當時 cap，允許後續 tuning 繼續改善。
    def group_tuning_i_qa_v10529(route_state=nil)
      q=pmd_ac_v10531_legacy_group_tuning_i_qa_v10529(route_state)
      return q if q==nil || route_state==nil || !route_state[:complete]
      groups_ok=legacy_tuning_groups_under_cap_v10531(route_state,GROUP_TUNING_EXPECTED_BODY_ATTACK_V10529)
      cap_ok=q[:attack_after].to_i<=GROUP_TUNING_EXPECTED_GENERIC_ATTACK_V10529.to_i
      q[:groups_ok]=groups_ok
      q[:attack_reduced]=GROUP_TUNING_BASELINE_GENERIC_ATTACK_V10529.to_i-q[:attack_after].to_i
      q[:pass]=(q[:total].to_i==16 && q[:selected].to_i==16 && q[:playable].to_i==16 &&
        q[:strict].to_i==16 && q[:family].to_i==16 && q[:safe].to_i==16 &&
        q[:route_pass] && cap_ok && groups_ok && q[:ms].to_i<=GROUP_TUNING_THRESHOLD_MS_V10529.to_i &&
        (q[:bad]||[]).empty?)
      q
    rescue
      pmd_ac_v10531_legacy_group_tuning_i_qa_v10529(route_state)
    end

    # v1.05.30 歷史 verifier 同理改採 cumulative-cap。
    def group_tuning_ii_qa_v10530(route_state=nil)
      q=pmd_ac_v10531_legacy_group_tuning_ii_qa_v10530(route_state)
      return q if q==nil || route_state==nil || !route_state[:complete]
      groups_ok=legacy_tuning_groups_under_cap_v10531(route_state,GROUP_TUNING_EXPECTED_BODY_ATTACK_V10530)
      cap_ok=q[:attack_after].to_i<=GROUP_TUNING_EXPECTED_GENERIC_ATTACK_V10530.to_i
      q[:groups_ok]=groups_ok
      q[:attack_reduced]=GROUP_TUNING_BASELINE_GENERIC_ATTACK_V10530.to_i-q[:attack_after].to_i
      q[:pass]=(q[:total].to_i==16 && q[:selected].to_i==16 && q[:playable].to_i==16 &&
        q[:strict].to_i==16 && q[:family].to_i==16 && q[:safe].to_i==16 &&
        q[:route_pass] && cap_ok && groups_ok && q[:ms].to_i<=GROUP_TUNING_THRESHOLD_MS_V10530.to_i &&
        (q[:bad]||[]).empty?)
      q
    rescue
      pmd_ac_v10531_legacy_group_tuning_ii_qa_v10530(route_state)
    end

    def group_tuning_iii_last_qa_v10531
      @group_tuning_iii_last_qa_v10531
    end

    def group_tuning_iii_qa_v10531(route_state=nil)
      t0=Time.now
      total=0;selected=0;playable=0;strict=0;family_ok=0;safe=0;bad=[]
      GROUP_TUNING_III_V10531.each do |sid,fams|
        fams.each do |family,pose|
          total+=1
          row=group_tuning_iii_family_case_v10531(family)
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
          ok_safe=group_tuning_iii_safe_v10531(sid,pose,family)
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
      expected_attack=(attack_after==GROUP_TUNING_EXPECTED_GENERIC_ATTACK_V10531)
      groups_ok=true
      if rs!=nil && rs[:groups]!=nil
        GROUP_TUNING_EXPECTED_BODY_ATTACK_V10531.each do |body,expected|
          g=rs[:groups][body]
          groups_ok=false if g==nil || g[:attack].to_i!=expected
        end
      else
        groups_ok=false
      end
      pass=(total==16 && selected==16 && playable==16 && strict==16 && family_ok==16 && safe==16 &&
        route_pass && expected_attack && groups_ok && ms<=GROUP_TUNING_THRESHOLD_MS_V10531 && bad.empty?)
      @group_tuning_iii_last_qa_v10531={
        :pass=>pass,:total=>total,:selected=>selected,:playable=>playable,:strict=>strict,
        :family=>family_ok,:safe=>safe,:ms=>ms,:bad=>bad,:route_pass=>route_pass,
        :attack_after=>attack_after,:fallback_after=>fallback_after,:native_after=>native_after,
        :groups_ok=>groups_ok,:attack_reduced=>(attack_after<0 ? 0 : GROUP_TUNING_BASELINE_GENERIC_ATTACK_V10531-attack_after)
      }
      @group_tuning_iii_last_qa_v10531
    rescue
      @group_tuning_iii_last_qa_v10531={:pass=>false,:total=>0,:selected=>0,:playable=>0,:strict=>0,
        :family=>0,:safe=>0,:ms=>0,:bad=>['exception'],:route_pass=>false,
        :attack_after=>-1,:fallback_after=>-1,:native_after=>-1,:groups_ok=>false,:attack_reduced=>0}
    end
  end
end

class Scene_PMD_AutoChess
  alias pmd_ac_v10531_start_battle start_battle unless method_defined?(:pmd_ac_v10531_start_battle)
  alias pmd_ac_v10531_update update unless method_defined?(:pmd_ac_v10531_update)
  alias pmd_ac_v10531_focus_summary focus_cast_log_summary_v1055 unless method_defined?(:pmd_ac_v10531_focus_summary)

  def start_battle
    r=pmd_ac_v10531_start_battle
    begin
      if respond_to?(:verification_mode) && verification_mode==:normal &&
         !(respond_to?(:production_external_battle_fast_v10613?) && production_external_battle_fast_v10613?)
        @group_tuning_iii_reported_v10531=false
        log_event(:battle,'BATTLE_REPRESENTATIVE_GROUP_TUNING_III_V10531 START routes='+
          PMD_AC.group_tuning_iii_route_count_v10531.to_i.to_s+
          ' source=v10530_windows_evidence generic_attack_before='+
          PMD_AC::GROUP_TUNING_BASELINE_GENERIC_ATTACK_V10531.to_i.to_s+
          ' expected_after='+PMD_AC::GROUP_TUNING_EXPECTED_GENERIC_ATTACK_V10531.to_i.to_s+
          ' species=0340,0350,0367,0384 pose=swing family_contract_unchanged=1'+
          ' motion_core_unchanged=1 gameplay_change=0')
        log_event(:battle,'BATTLE_REPRESENTATIVE_LEGACY_TUNING_VERIFIER_SEAL_V10531 START'+
          ' batch_i_cap=278 batch_ii_cap=262 cumulative_cap=1 own_routes_still_strict=1'+
          ' exact_snapshot_expectation_retired=1 behavior_change=verifier_only')
      end
    rescue
    end
    r
  end

  def update
    pmd_ac_v10531_update
    begin
      return unless respond_to?(:verification_mode) && verification_mode==:normal
      return if respond_to?(:production_external_battle_fast_v10613?) && production_external_battle_fast_v10613?
      return if @group_tuning_iii_reported_v10531
      s=PMD_AC.representative_route_qa_state_v10528 rescue nil
      if s!=nil && s[:complete]
        q=PMD_AC.group_tuning_iii_qa_v10531(s)
        group_tuning_iii_log_v10531(q,s)
      end
    rescue
    end
  end

  def group_tuning_iii_log_v10531(q=nil,s=nil)
    q ||= PMD_AC.group_tuning_iii_last_qa_v10531
    s ||= (PMD_AC.representative_route_qa_state_v10528 rescue nil)
    return false if q==nil || s==nil
    log_event(:battle,'BATTLE_REPRESENTATIVE_GROUP_TUNING_III_SUMMARY_V10531 pass='+(q[:pass] ? '1':'0')+
      ' tuned='+q[:selected].to_i.to_s+'/16 playable='+q[:playable].to_i.to_s+'/16'+
      ' strict45='+q[:strict].to_i.to_s+'/16 family='+q[:family].to_i.to_s+'/16'+
      ' safety='+q[:safe].to_i.to_s+'/16 generic_attack_before='+
      PMD_AC::GROUP_TUNING_BASELINE_GENERIC_ATTACK_V10531.to_i.to_s+
      ' generic_attack_after='+q[:attack_after].to_i.to_s+
      ' reduced='+q[:attack_reduced].to_i.to_s+
      ' fallback_after='+q[:fallback_after].to_i.to_s+
      ' selected_native_after='+q[:native_after].to_i.to_s+
      ' groups_ok='+(q[:groups_ok] ? '1':'0')+' qa_ms='+q[:ms].to_i.to_s+
      ' threshold_ms='+PMD_AC::GROUP_TUNING_THRESHOLD_MS_V10531.to_i.to_s+
      ' bad=['+(q[:bad]||[]).join(',')+'] gameplay_change=0')
    PMD_AC::GROUP_TUNING_EXPECTED_BODY_ATTACK_V10531.each do |body,expected|
      g=s[:groups][body] || {}
      log_event(:battle,'BATTLE_REPRESENTATIVE_GROUP_TUNING_III_GROUP_V10531 body='+body.to_s+
        ' generic_attack='+g[:attack].to_i.to_s+' expected='+expected.to_i.to_s+
        ' fallback='+g[:fallback].to_i.to_s+' selected_native='+g[:native].to_i.to_s)
    end
    next_rows=s[:tuning] || []
    log_event(:battle,'BATTLE_REPRESENTATIVE_GROUP_TUNING_NEXT_V10531 count='+next_rows.size.to_i.to_s+
      ' candidates=['+next_rows.join(',')+'] source=v10528_after_tuning_i_ii_iii next_batch=audit_first')
    log_event(:battle,'BATTLE_REPRESENTATIVE_LEGACY_TUNING_VERIFIER_SEAL_SUMMARY_V10531'+
      ' batch_i='+(begin q1=PMD_AC.group_tuning_i_last_qa_v10529;q1!=nil && q1[:pass] ? '1':'0' rescue '0' end)+
      ' batch_ii='+(begin q2=PMD_AC.group_tuning_ii_last_qa_v10530;q2!=nil && q2[:pass] ? '1':'0' rescue '0' end)+
      ' cumulative_generic_attack='+s[:attack].to_i.to_s+' verifier_only=1')
    @group_tuning_iii_reported_v10531=true
    true
  rescue
    false
  end

  def focus_cast_log_summary_v1055
    r=pmd_ac_v10531_focus_summary
    return r if respond_to?(:production_external_battle_fast_v10613?) && production_external_battle_fast_v10613?
    begin
      if !@group_tuning_iii_reported_v10531
        s=PMD_AC.representative_route_qa_state_v10528 rescue nil
        if s!=nil && s[:complete]
          q=PMD_AC.group_tuning_iii_last_qa_v10531
          q=PMD_AC.group_tuning_iii_qa_v10531(s) if q==nil
          group_tuning_iii_log_v10531(q,s)
        end
      end
    rescue
    end
    r
  end
end
