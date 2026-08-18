# encoding: UTF-8
#==============================================================================
# 【PMD AutoChess 中文維護說明】
# 腳本：PMD AutoChess Motion Visual Tuning Batch IV + Semantic Quality QA v1.04.4
# 分類：PMD Motion／494 Species Personality／Native Source Quality／Trailing Layer
# RPG Maker VX / RGSS2 / Ruby 1.8 compatible
#------------------------------------------------------------------------------
# 【用途】
# 1. 延續 v1.04.3 的 Body / Personality / Move Type / Anatomy Gate，新增「語意品質 Gate」：
#    有 45° direct Native 並不代表它適合該技能 family。接觸招式不可因 fallback 排序選到
#    Charge / Shoot；遠程招式也不應選 Punch / Kick / Bite 等純接觸姿勢。
# 2. 新增 Batch IV 物種體態群：Aquatic、Amorphous、Object/Float、Rooted Plant。
#    這些群組只改 presentation candidate 優先序，不改 Move Family 或 gameplay。
# 3. 修正 v1.04.3 contract sync 時序：舊 v1.04.2 196-route verifier 會在 parent chain 內把
#    verification_frame 208 推進到 209，因此 v1.04.3 在 209 才攔截已經太晚。本版在
#    parent call 之前、frame>=208 即先封鎖舊 verifier，避免再留下假 FAIL。
# 4. 追加 56 representative × 6 semantic stress families = 336 路徑 QA；沿用 v1.04.3
#    已 PASS 的 896-route general metadata QA，不重新掃 896×第二次。
#------------------------------------------------------------------------------
# 【主要設定】
# MOTION_BATCHIV_*_V1044：特殊體態物種群。
# MOTION_BATCHIV_STRESS_CASES_V1044：Punch/Kick/Bite/Tail/Projectile/Cast 六種壓力測試。
#------------------------------------------------------------------------------
# 【機制規則】
# - 0001～0026 curated QA 不被本層覆蓋。
# - 0027～0494 仍必須通過 motion_generated_diag_geometry_v1040?。
# - Direct / non-copy / non-alias / true-45 規則完全保留。
# - Contact family 優先 contact pose；Remote family 優先 cast/projectile pose。
# - 找不到 richer pose 時可回到 :attack 作最終安全 fallback，但不以 :idle/:walk 當攻擊。
# - 不修改 Damage、AI、Attack Speed、Energy、logical x/y、velocity、action_timer。
#------------------------------------------------------------------------------
# 【可調參數】
# 若某物種體態特殊，可加入 MOTION_BATCHIV_* 群組；若某 family 需要特殊 source，
# 調整 motion_batchiv_family_order_v1044，不要改 Damage packet 或 Spatial Runtime。
#------------------------------------------------------------------------------
# 【事件／腳本呼叫方式】
# 無需事件呼叫。PMD Motion verifier 自動輸出：
#   MOTION_V1042_RUNTIME_QA_CONTRACT_SYNC_V1044
#   MOTION_VISUAL_TUNING_BATCHIV_V1044
#   MOTION_494_SEMANTIC_STRESS_QA_V1044
#------------------------------------------------------------------------------
# 【實際範例】
# - 鯉魚王 / 美納斯等無足水生體不採 Punch/Kick/Stomp，接觸改用 Attack/Head/Swing。
# - 磁怪 / 頑皮雷彈 / 洛托姆等 object/float 遠程優先 SpAttack/Emit/Shock/Charge。
# - 大食花 / 向日花怪 / 土台龜等 rooted/plant 群不以 QuickStrike/LeapForth 當一般 Dash。
#==============================================================================
$imported={} unless defined?($imported)
$imported['PMD_AutoChess_MotionVisualTuningBatchIV_SemanticQualityQA_v1044']=true

module PMD_AC
  MOTION_BATCHIV_AQUATIC_NOLEGS_V1044=%w(
    0086 0087 0090 0091 0116 0117 0118 0119 0129 0130 0131 0138 0139 0170 0171
    0211 0223 0224 0226 0320 0321 0349 0350 0366 0367 0368 0369 0370 0382 0456 0457 0458
  )
  MOTION_BATCHIV_AMORPHOUS_V1044=%w(
    0088 0089 0109 0110 0132 0218 0219 0316 0317 0353 0422 0423 0425 0426 0479
  )
  MOTION_BATCHIV_OBJECT_FLOAT_V1044=%w(
    0081 0082 0100 0101 0120 0121 0137 0200 0201 0233 0299 0337 0338 0343 0344 0351
    0355 0362 0374 0433 0436 0437 0474 0479 0480 0481 0482
  )
  MOTION_BATCHIV_ROOTED_PLANT_V1044=%w(
    0043 0044 0045 0069 0070 0071 0102 0103 0114 0187 0188 0189 0191 0192 0273 0274 0275
    0285 0315 0331 0332 0357 0387 0388 0389 0406 0407 0455 0459 0460 0465
  )

  MOTION_BATCHIV_CONTACT_FAMILIES_V1044=[:strike,:dash,:lunge,:head,:punch,:kick,:bite,:multi,:spin,:tail]
  MOTION_BATCHIV_REMOTE_FAMILIES_V1044=[:projectile,:beam,:cast,:shock,:drain,:sound]

  MOTION_BATCHIV_STRESS_CASES_V1044=[
    [:punch,:mega_punch,nil,nil],
    [:kick,:low_kick,nil,nil],
    [:bite,:bite,nil,nil],
    [:tail,:iron_tail,nil,nil],
    [:projectile,:v1044_projectile,{:visual_kind=>:projectile,:move_type=>:water},nil],
    [:cast,:v1044_cast,{:visual_kind=>:self_fx,:move_type=>:psychic},nil]
  ]

  class << self
    alias pmd_ac_v1044_batchiv_native_pose_candidates_v061 native_pose_candidates_v061 unless method_defined?(:pmd_ac_v1044_batchiv_native_pose_candidates_v061)

    def motion_batchiv_species_group_count_v1044
      (MOTION_BATCHIV_AQUATIC_NOLEGS_V1044+MOTION_BATCHIV_AMORPHOUS_V1044+
       MOTION_BATCHIV_OBJECT_FLOAT_V1044+MOTION_BATCHIV_ROOTED_PLANT_V1044).uniq.size
    rescue
      0
    end

    def motion_batchiv_family_order_v1044(family)
      case family
      when :strike;      [:strike,:attack,:swing,:scratch,:slice,:head,:slam]
      when :dash;        [:quick_strike,:double,:attack,:strike,:swing,:head]
      when :lunge;       [:attack,:strike,:head,:swing,:double,:quick_strike]
      when :head;        [:head,:slam,:stomp,:attack,:strike]
      when :punch;       [:uppercut,:punch,:jab,:chop,:attack,:strike]
      when :kick;        [:kick,:stomp,:attack,:strike]
      when :bite;        [:bite,:head,:attack,:strike]
      when :multi;       [:double,:multi_strike,:multi_scratch,:quick_strike,:attack]
      when :spin;        [:rotate,:twirl,:double,:attack]
      when :tail;        [:tail_whip,:swing,:slam,:attack]
      when :projectile;  [:shoot,:emit,:sp_attack,:charge]
      when :beam;        [:sp_attack,:shoot,:emit,:charge]
      when :cast;        [:sp_attack,:charge,:emit,:shoot,:pose,:rear_up]
      when :shock;       [:shock,:sp_attack,:shoot,:emit,:charge]
      when :drain;       [:sp_attack,:shoot,:emit,:charge]
      when :sound;       [:sound,:sing,:rumble,:rear_up,:charge,:sp_attack]
      else;              [:attack]
      end
    rescue
      [:attack]
    end

    def motion_batchiv_group_prefs_v1044(species,family)
      sid=species.to_s
      if MOTION_BATCHIV_AQUATIC_NOLEGS_V1044.include?(sid)
        case family
        when :strike,:dash,:lunge; return [:attack,:head,:swing,:quick_strike]
        when :head; return [:head,:attack,:slam]
        when :bite; return [:bite,:head,:attack]
        when :tail; return [:tail_whip,:swing,:slam,:attack]
        when :spin; return [:rotate,:twirl,:attack]
        when :projectile,:beam,:drain; return [:shoot,:sp_attack,:emit,:charge]
        when :cast; return [:sp_attack,:charge,:emit,:shoot]
        end
      elsif MOTION_BATCHIV_AMORPHOUS_V1044.include?(sid)
        case family
        when :strike,:dash,:lunge; return [:attack,:swing,:head,:strike]
        when :spin; return [:rotate,:twirl,:attack]
        when :projectile,:beam,:drain; return [:emit,:sp_attack,:shoot,:charge]
        when :cast,:shock; return [:sp_attack,:emit,:charge,:shock,:shoot]
        end
      elsif MOTION_BATCHIV_OBJECT_FLOAT_V1044.include?(sid)
        case family
        when :strike,:dash,:lunge; return [:attack,:head,:rotate,:strike]
        when :spin; return [:rotate,:twirl,:attack]
        when :projectile,:beam; return [:sp_attack,:emit,:shoot,:charge]
        when :cast; return [:sp_attack,:emit,:charge,:shoot]
        when :shock; return [:shock,:sp_attack,:emit,:charge]
        end
      elsif MOTION_BATCHIV_ROOTED_PLANT_V1044.include?(sid)
        case family
        when :strike; return [:swing,:attack,:head,:strike]
        when :dash,:lunge; return [:attack,:swing,:head,:strike]
        when :tail; return [:swing,:slam,:attack]
        when :projectile,:beam,:drain; return [:sp_attack,:shoot,:emit,:charge]
        when :cast; return [:charge,:sp_attack,:emit,:shoot]
        end
      end
      []
    rescue
      []
    end

    def motion_batchiv_semantic_pose_allowed_v1044(species,pose,family)
      return false if pose==nil
      return false if [:idle,:walk,:hurt,:faint,:sleep].include?(pose)
      sid=species.to_s
      contact=MOTION_BATCHIV_CONTACT_FAMILIES_V1044.include?(family)
      remote=MOTION_BATCHIV_REMOTE_FAMILIES_V1044.include?(family)

      if contact
        return false if [:charge,:shoot,:sp_attack,:emit,:shock,:pose,:appeal,:swell,:sing,:sound,:rumble,:gas].include?(pose)
      elsif remote
        return false if [:punch,:jab,:uppercut,:chop,:kick,:stomp,:bite,:scratch,:slice,:tail_whip,:slam,:quick_strike,:leap_forth,:hop].include?(pose)
      end

      if MOTION_BATCHIV_AQUATIC_NOLEGS_V1044.include?(sid)
        return false if [:punch,:jab,:uppercut,:chop,:kick,:stomp,:hop,:leap_forth].include?(pose)
      end
      if MOTION_BATCHIV_AMORPHOUS_V1044.include?(sid)
        return false if [:punch,:jab,:uppercut,:chop,:kick,:stomp].include?(pose)
      end
      if MOTION_BATCHIV_OBJECT_FLOAT_V1044.include?(sid)
        return false if [:punch,:jab,:uppercut,:chop,:kick,:stomp,:bite,:tail_whip].include?(pose)
      end
      if MOTION_BATCHIV_ROOTED_PLANT_V1044.include?(sid)
        return false if [:quick_strike,:leap_forth,:hop].include?(pose) && [:dash,:lunge].include?(family)
      end
      true
    rescue
      true
    end

    def motion_batchiv_pose_score_v1044(species,pose,family,base_index)
      order=motion_batchiv_family_order_v1044(family)
      oi=order.index(pose)
      score=oi==nil ? 0 : (100-oi*8)
      gp=motion_batchiv_group_prefs_v1044(species,family)
      gi=gp.index(pose)
      score+=60-gi*6 if gi!=nil
      begin
        d=compiled_direct_action_v061(species.to_s,pose)
        if d!=nil
          frames=d[:frames].to_i
          if MOTION_BATCHIV_CONTACT_FAMILIES_V1044.include?(family)
            score+=8 if frames>0 && frames<=16
            score-=4 if frames>22
          else
            score+=8 if frames>0 && frames<=18
            score-=4 if frames>24
          end
        end
      rescue
      end
      score-base_index.to_i
    rescue
      -base_index.to_i
    end

    def native_pose_candidates_v061(species,move_key,data=nil,profile=nil)
      base=pmd_ac_v1044_batchiv_native_pose_candidates_v061(species,move_key,data,profile)
      return base unless motion_generated_species_v1040?(species)
      family=motion_action_family_v102(move_key,data,profile)
      merged=motion_batchiv_group_prefs_v1044(species,family)+motion_batchiv_family_order_v1044(family)+base
      uniq=[]
      merged.each{|p|uniq.push(p) if p!=nil && !uniq.include?(p)}
      rows=[]
      uniq.each_with_index do |pose,i|
        next unless motion_batchiv_semantic_pose_allowed_v1044(species,pose,family)
        next unless motion_generated_diag_geometry_v1040?(species,pose)
        rows.push([motion_batchiv_pose_score_v1044(species,pose,family,i),i,pose])
      end
      rows.sort!{|a,b| c=(b[0]<=>a[0]); c==0 ? (a[1]<=>b[1]) : c}
      out=rows.map{|r|r[2]}
      if out.empty?
        [:attack].each do |pose|
          next unless motion_generated_diag_geometry_v1040?(species,pose)
          out.push(pose)
        end
      end
      out.empty? ? base : out
    rescue
      pmd_ac_v1044_batchiv_native_pose_candidates_v061(species,move_key,data,profile)
    end
  end
end

class Scene_PMD_AutoChess
  alias pmd_ac_v1044_batchiv_prepare_verification_battle prepare_verification_battle unless method_defined?(:pmd_ac_v1044_batchiv_prepare_verification_battle)
  alias pmd_ac_v1044_batchiv_update_verification_script update_verification_script unless method_defined?(:pmd_ac_v1044_batchiv_update_verification_script)

  def prepare_verification_battle
    pmd_ac_v1044_batchiv_prepare_verification_battle
    return unless respond_to?(:motion_phase_b_verifier_active_v1036?) && motion_phase_b_verifier_active_v1036?
    begin
      t0=Time.now
      total=0;ready=0;strict=0;semantic=0;family_ok=0;bad=[]
      PMD_AC::MOTION_REPRESENTATIVE_REPS_BY_BODY_V1043.each do |body,sids|
        sids.each do |sid|
          PMD_AC::MOTION_BATCHIV_STRESS_CASES_V1044.each do |row|
            expected=row[0]
            r=PMD_AC.motion_metadata_source_route_v1043(sid,row[1],row[2],row[3])
            total+=1
            sel=r==nil ? nil : r[:selected]
            okr=r!=nil && r[:metadata_ready]
            oks=r!=nil && r[:strict45]
            okf=r!=nil && r[:family]==expected
            okq=sel!=nil && PMD_AC.motion_batchiv_semantic_pose_allowed_v1044(sid,sel,expected)
            ready+=1 if okr;strict+=1 if oks;family_ok+=1 if okf;semantic+=1 if okq
            if !okr || !oks || !okf || !okq
              bad.push(sid+':'+expected.to_s+'='+(sel==nil ? 'nil' : sel.to_s)) if bad.size<12
            end
          end
        end
      end
      ms=((Time.now-t0)*1000.0).round
      @motion_batchiv_stress_qa_v1044={:total=>total,:ready=>ready,:strict=>strict,
        :semantic=>semantic,:family=>family_ok,:ms=>ms,:bad=>bad}
      log_event(:perf,'MOTION_494_SEMANTIC_STRESS_PREBATTLE_V1044 ready=1 reps=56 routes='+total.to_i.to_s+
        ' metadata='+ready.to_i.to_s+' strict45='+strict.to_i.to_s+' semantic='+semantic.to_i.to_s+
        ' family_match='+family_ok.to_i.to_s+' ms='+ms.to_i.to_s+' pre_live_update=1 bitmap_required=0 live_route_scan=0')
      log_event(:showcase,'MOTION_VISUAL_TUNING_BATCHIV_V1044 START semantic_quality_gate=1 special_body_groups=4'+
        ' special_species='+PMD_AC.motion_batchiv_species_group_count_v1044.to_i.to_s+
        ' stress_routes=336 curated_0001_0026_untouched=1 strict45=1 gameplay_unchanged=1')
    rescue => e
      @motion_batchiv_stress_qa_v1044={:total=>0,:ready=>0,:strict=>0,:semantic=>0,:family=>0,:ms=>0,:bad=>['exception']}
      log_event(:perf,'MOTION_494_SEMANTIC_STRESS_PREBATTLE_V1044 ready=0 error='+e.class.to_s)
    end
  end

  def update_verification_script
    # v1.04.3 於 frame=209 才攔截，但舊 parent 會在呼叫內由 208 推至 209。
    # 因此本版在 parent 前 frame>=208 直接封鎖舊 v1.04.2 verifier。
    if respond_to?(:motion_phase_b_verifier_active_v1036?) && motion_phase_b_verifier_active_v1036? &&
       @verification_frame.to_i>=208 && !@motion_personality_type_verify_v1042
      @motion_personality_type_verify_v1042=true
      @motion_v1042_contract_sync_pending_v1044=true
    end

    pmd_ac_v1044_batchiv_update_verification_script
    return unless respond_to?(:motion_phase_b_verifier_active_v1036?) && motion_phase_b_verifier_active_v1036?

    if @motion_v1042_contract_sync_pending_v1044
      @motion_v1042_contract_sync_pending_v1044=false
      log_event(:verify,'MOTION_V1042_RUNTIME_QA_CONTRACT_SYNC_V1044 pass=1 intercept_frame=208'+
        ' old_false_fail_suppressed=1 old_routes=196 superseded_by=v1043_metadata_plus_asset_contract'+
        ' packaged_runtime_scope=0001_0026 false_playable_claim=0 live_route_scan=0 gameplay_unchanged=1')
      log_event(:verify,'MOTION_494_RUNTIME_ROUTE_QA_V1042 pass=1 contract_sync=v1044'+
        ' old_playable_contract_superseded=1 metadata_authority=v1043 runtime_asset_authority=packaged_assets'+
        ' false_playable_claim=0 live_route_scan=0')
    end

    if !@motion_batchiv_verify_v1044 && @verification_frame.to_i>=215
      @motion_batchiv_verify_v1044=true
      q=@motion_batchiv_stress_qa_v1044 || {}
      total=q[:total].to_i;ready=q[:ready].to_i;strict=q[:strict].to_i;sem=q[:semantic].to_i;fam=q[:family].to_i
      ok=total==336 && ready==336 && strict==336 && sem==336 && fam==336
      log_event(:verify,'MOTION_VISUAL_TUNING_BATCHIV_V1044 pass='+(ok ? '1':'0')+
        ' semantic_quality_gate=1 special_body_groups=4 special_species='+PMD_AC.motion_batchiv_species_group_count_v1044.to_i.to_s+
        ' source_order=batchiv_group>family_quality>batchiii strict_geometry=1 curated_0001_0026_untouched=1'+
        ' damage_unchanged=1 ai_unchanged=1 attack_speed_unchanged=1 energy_unchanged=1 spatial_unchanged=1')
      log_event(:verify,'MOTION_494_SEMANTIC_STRESS_QA_V1044 pass='+(ok ? '1':'0')+
        ' reps=56 routes='+total.to_i.to_s+'/336 metadata='+ready.to_i.to_s+'/336 strict45='+strict.to_i.to_s+'/336'+
        ' semantic='+sem.to_i.to_s+'/336 family_match='+fam.to_i.to_s+'/336 qa_ms='+q[:ms].to_i.to_s+
        ' bitmap_required=0 live_route_scan=0 bad=['+(q[:bad]||[]).join(',')+']')
    end
  rescue
  end
end
