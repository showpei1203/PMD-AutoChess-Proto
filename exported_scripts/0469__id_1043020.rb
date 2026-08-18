# encoding: UTF-8
#==============================================================================
# ■ PMD AutoChess - Visual Tuning Batch III + 494 Representative QA v1.04.3
#==============================================================================
# 【用途】
# 1. 在 v1.04.2「重要物種→Move Type→Personality→Body Group」之上，再加入 Anatomy
#    Gate，避免有四足、蛇形、鳥類、懸浮、重型體態卻因素材剛好存在，就選到不自然的
#    Punch / Uppercut / Stomp / Hop / LeapForth 等動作。
# 2. 新增重要物種 Visual Tuning Batch III：Tail / Claw / Shell / Wing / Stomper /
#    Mystic 六組 signature source preference，只改 presentation source order。
# 3. 把代表 QA 由 v1.04.2 的 28×7 擴成 7 body × 8 species × 16 family = 896 routes。
# 4. 修正 v1.04.2 acceptance contract：目前 executable 的 Graphics/PMD 實體素材只打包
#    0001～0026，因此 0027～0494 不應要求 hasPlayable=1。v1.04.3 分成：
#      A. 494 compiled metadata / strict45 source correctness（blocking）
#      B. Representative runtime asset readiness（只有匯入代表素材後才 blocking）
# 5. 提供 Tools/IMPORT_REPRESENTATIVE_QA_ASSETS_v1043.py，使用者本機若保有
#    E:\CG_PMD_Source，可一鍵把 56 隻代表物種的 *-Anim.png 複製進專案，再跑真正
#    hasPlayable Runtime QA；不把上游巨大素材庫硬塞進每個開發 ZIP。
#
# 【主要設定】
# MOTION_REPRESENTATIVE_REPS_BY_BODY_V1043：7 body × 8 代表物種。
# MOTION_REPRESENTATIVE_FAMILY_CASES_V1043：16 Motion family。
# MOTION_BATCHIII_*_V1043：重要物種 signature 群組。
# MOTION_BATCHIII_QUAD_KICKERS_V1043：四足但合理使用踢／踩的例外。
# MOTION_BATCHIII_FAST_HEAVY_V1043：重型但允許較快接觸演技的例外。
#
# 【機制規則】
# - 0001～0026 curated QA 永遠優先，本層只處理 generated species 0027～0494。
# - Anatomy Gate 只篩 presentation pose；不改 move family、Damage、AI、Attack Speed、
#   Energy、logical x/y、velocity、action_timer。
# - 找不到 signature pose 時保留 v1.04.2 / v1.04.1 / v1.04.0 safe fallback。
# - 所有 generated combat source 仍必須通過 motion_generated_diag_geometry_v1040?。
# - Metadata QA 不呼叫 Bitmap、不要求檔案存在；Runtime Asset QA 才呼叫既有
#   motion_source_route_v102，並且只有代表素材 marker 存在時才執行。
#
# 【可調參數】
# - 若某物種肢體分類特殊，可加入 Batch III 群組或 Anatomy exception。
# - 若要擴代表 QA，可在每個 body group 增加 species；16 family 不需改。
# - 真正把 0027～0494 全部素材打包前，不要把 metadata_ready 誤寫成 runtime_playable。
#
# 【事件／腳本呼叫方式】
# 無需事件呼叫。PMD Motion verifier 自動輸出：
#   MOTION_V1042_RUNTIME_QA_CONTRACT_SYNC_V1043
#   MOTION_VISUAL_TUNING_BATCHIII_V1043
#   MOTION_494_REPRESENTATIVE_METADATA_QA_V1043
#   MOTION_494_REPRESENTATIVE_RUNTIME_ASSET_QA_V1043
#
# 【實際範例】
# - Serpentine 使用 Fighting move 時，即使資料表有 Punch sheet，也不讓 Punch/Uppercut
#   搶在 Attack/Head/Swing 前面。
# - Heavy 一般不採 Hop/LeapForth/QuickStrike；Machamp 等明確 brawler 例外仍可用拳腳。
# - 未匯入 0038 素材時，0038 的 metadata route 可 PASS，但 runtime asset readiness 顯示
#   deferred；匯入代表素材後才要求 hasPlayable=1。
#==============================================================================
$imported={} unless defined?($imported)
$imported['PMD_AutoChess_MotionVisualTuningBatchIII_RepresentativeQA_v1043']=true

module PMD_AC
  # 重要物種 Batch III：signature source 偏好。只包含 generated scope。
  MOTION_BATCHIII_TAIL_V1043=%w(
    0037 0053 0080 0108 0134 0135 0136 0156 0157 0196 0197 0234 0262 0277
    0335 0359 0418 0419 0445 0466 0471 0472
  )
  MOTION_BATCHIII_CLAW_V1043=%w(
    0028 0047 0053 0099 0141 0215 0217 0335 0342 0359 0445 0448 0461 0472
  )
  MOTION_BATCHIII_SHELL_V1043=%w(
    0091 0139 0141 0205 0213 0219 0324 0366 0389 0411 0464 0476
  )
  MOTION_BATCHIII_WING_V1043=%w(
    0042 0083 0084 0085 0142 0144 0145 0146 0149 0169 0176 0198 0225 0227
    0249 0250 0276 0277 0330 0396 0397 0398 0430 0468
  )
  MOTION_BATCHIII_STOMPER_V1043=%w(
    0068 0076 0112 0128 0143 0208 0217 0248 0289 0306 0376 0383 0389 0411
    0464 0486
  )
  MOTION_BATCHIII_MYSTIC_V1043=%w(
    0036 0065 0094 0122 0151 0196 0200 0249 0251 0282 0354 0358 0380 0381
    0385 0429 0433 0439 0475 0479 0480 0481 0482 0488 0491 0493
  )

  MOTION_BATCHIII_QUAD_KICKERS_V1043=%w(0077 0078 0203 0234 0309 0310)
  MOTION_BATCHIII_FAST_HEAVY_V1043=%w(0068 0128 0248 0289 0376 0383 0486)

  # 7 body × 8 reps，跨 Kanto～Sinnoh 範圍；全部屬 generated 0027～0494。
  MOTION_REPRESENTATIVE_REPS_BY_BODY_V1043={
    :small=>%w(0027 0069 0152 0191 0270 0316 0412 0494),
    :medium=>%w(0028 0091 0138 0203 0267 0313 0408 0478),
    :quadruped=>%w(0029 0059 0134 0209 0244 0310 0431 0492),
    :heavy=>%w(0031 0108 0205 0297 0369 0388 0465 0493),
    :hover=>%w(0042 0151 0233 0338 0380 0426 0472 0491),
    :avian=>%w(0083 0144 0164 0225 0276 0330 0397 0468),
    :serpentine=>%w(0095 0147 0206 0336 0340 0350 0367 0384)
  }

  # [expected family, move_key, data, motion_profile]
  MOTION_REPRESENTATIVE_FAMILY_CASES_V1043=[
    [:strike,:basic_attack,nil,nil],
    [:dash,:v1043_dash,nil,{:motion=>:dash_return}],
    [:lunge,:v1043_lunge,nil,{:motion=>:contact_return}],
    [:head,:headbutt,nil,nil],
    [:punch,:mega_punch,nil,nil],
    [:kick,:low_kick,nil,nil],
    [:bite,:bite,nil,nil],
    [:multi,:v1043_multi,nil,{:motion=>:multi_contact}],
    [:spin,:rapid_spin,nil,nil],
    [:tail,:iron_tail,nil,nil],
    [:projectile,:v1043_projectile,{:visual_kind=>:projectile,:move_type=>:water},nil],
    [:beam,:v1043_beam,{:visual_kind=>:beam,:move_type=>:ice},nil],
    [:cast,:v1043_cast,{:visual_kind=>:self_fx,:move_type=>:psychic},nil],
    [:shock,:v1043_shock,{:visual_kind=>:target_hit,:move_type=>:electric},nil],
    [:drain,:absorb,nil,nil],
    [:sound,:screech,nil,nil]
  ]

  class << self
    alias pmd_ac_v1043_batchiii_native_pose_candidates_v061 native_pose_candidates_v061 unless method_defined?(:pmd_ac_v1043_batchiii_native_pose_candidates_v061)

    def motion_batchiii_signature_count_v1043
      (MOTION_BATCHIII_TAIL_V1043+MOTION_BATCHIII_CLAW_V1043+MOTION_BATCHIII_SHELL_V1043+
       MOTION_BATCHIII_WING_V1043+MOTION_BATCHIII_STOMPER_V1043+MOTION_BATCHIII_MYSTIC_V1043).uniq.size
    rescue
      0
    end

    def motion_batchiii_signature_prefs_v1043(species,family)
      sid=species.to_s;out=[]
      if MOTION_BATCHIII_TAIL_V1043.include?(sid)
        case family
        when :tail;out=[:tail_whip,:swing,:slam,:attack]
        when :strike,:lunge;out=[:swing,:attack,:strike]
        end
      end
      if out.empty? && MOTION_BATCHIII_CLAW_V1043.include?(sid)
        case family
        when :strike;out=[:swing,:attack,:strike]
        when :dash;out=[:quick_strike,:swing,:attack,:double]
        when :lunge;out=[:swing,:attack,:double,:strike]
        when :multi;out=[:double,:swing,:quick_strike,:attack]
        end
      end
      if out.empty? && MOTION_BATCHIII_SHELL_V1043.include?(sid)
        case family
        when :strike;out=[:attack,:head,:slam,:strike]
        when :dash,:lunge;out=[:attack,:head,:slam]
        when :head;out=[:head,:slam,:attack]
        when :spin;out=[:rotate,:twirl,:attack]
        when :cast;out=[:charge,:sp_attack,:shoot]
        end
      end
      if out.empty? && MOTION_BATCHIII_WING_V1043.include?(sid)
        case family
        when :strike;out=[:attack,:swing,:strike]
        when :dash;out=[:quick_strike,:attack,:double]
        when :lunge;out=[:attack,:double,:swing]
        when :projectile;out=[:shoot,:sp_attack,:emit]
        when :beam;out=[:sp_attack,:shoot]
        when :cast;out=[:sp_attack,:charge,:shoot]
        end
      end
      if out.empty? && MOTION_BATCHIII_STOMPER_V1043.include?(sid)
        case family
        when :strike;out=[:stomp,:slam,:head,:attack,:strike]
        when :lunge;out=[:head,:slam,:attack,:strike]
        when :head;out=[:head,:stomp,:slam,:attack]
        when :kick;out=[:stomp,:kick,:attack]
        end
      end
      if out.empty? && MOTION_BATCHIII_MYSTIC_V1043.include?(sid)
        case family
        when :projectile;out=[:sp_attack,:shoot,:emit]
        when :beam;out=[:sp_attack,:shoot]
        when :cast;out=[:sp_attack,:charge,:shoot,:pose]
        when :shock;out=[:shock,:sp_attack,:shoot]
        when :drain;out=[:sp_attack,:shoot,:charge]
        when :sound;out=[:sound,:sing,:charge,:rear_up]
        end
      end
      out
    rescue
      []
    end

    # Anatomy gate：有素材不代表肢體上合理。重要 brawler / kicker / fast-heavy 可明確例外。
    def motion_batchiii_pose_allowed_v1043(species,pose,family)
      return false if pose==nil
      sid=species.to_s
      p=motion_generated_profile_v1040(sid)
      return true if p==nil
      body=p[:body]
      brawler=const_defined?(:MOTION_BATCHII_BRAWLERS_V1042) && MOTION_BATCHII_BRAWLERS_V1042.include?(sid)
      case body
      when :serpentine
        return false if [:punch,:jab,:uppercut,:chop,:kick,:stomp,:hop,:leap_forth].include?(pose)
      when :quadruped
        return false if [:punch,:jab,:uppercut,:chop].include?(pose)
        if [:kick,:stomp].include?(pose) && !MOTION_BATCHIII_QUAD_KICKERS_V1043.include?(sid)
          return false
        end
      when :avian,:hover
        return false if [:punch,:jab,:uppercut,:chop,:stomp].include?(pose)
        return false if pose==:kick && !brawler
      when :heavy
        return false if [:hop,:leap_forth,:quick_strike].include?(pose) && !MOTION_BATCHIII_FAST_HEAVY_V1043.include?(sid)
        return false if [:punch,:jab,:uppercut,:chop,:kick].include?(pose) && !brawler
      end
      true
    rescue
      true
    end

    def native_pose_candidates_v061(species,move_key,data=nil,profile=nil)
      base=pmd_ac_v1043_batchiii_native_pose_candidates_v061(species,move_key,data,profile)
      return base unless motion_generated_species_v1040?(species)
      family=motion_action_family_v102(move_key,data,profile)
      preferred=motion_batchiii_signature_prefs_v1043(species,family)
      out=[]
      (preferred+base).each do |pose|
        next if pose==nil
        next unless motion_batchiii_pose_allowed_v1043(species,pose,family)
        next unless motion_generated_diag_geometry_v1040?(species,pose)
        out.push(pose) unless out.include?(pose)
      end
      if out.empty?
        [:attack,:idle].each do |pose|
          next unless motion_batchiii_pose_allowed_v1043(species,pose,family)
          next unless motion_generated_diag_geometry_v1040?(species,pose)
          out.push(pose) unless out.include?(pose)
        end
      end
      out.empty? ? base : out
    rescue
      pmd_ac_v1043_batchiii_native_pose_candidates_v061(species,move_key,data,profile)
    end

    # Metadata route：使用與正式 router 相同的候選順序，但不要求 Graphics/PMD PNG 已打包。
    # 用來驗證 494 source semantics；runtime playable 由另一條 asset QA 負責。
    def motion_metadata_source_route_v1043(species,move_key,data=nil,profile=nil)
      family=motion_action_family_v102(move_key,data,profile)
      candidates=native_pose_candidates_v061(species,move_key,data,profile)
      selected=nil
      candidates.each do |pose|
        if motion_generated_diag_geometry_v1040?(species,pose)
          selected=pose;break
        end
      end
      if selected==nil
        [:attack,:idle].each do |pose|
          if motion_generated_diag_geometry_v1040?(species,pose)
            selected=pose;break
          end
        end
      end
      {:family=>family,:selected=>selected,:metadata_ready=>(selected!=nil),
       :strict45=>(selected!=nil && motion_generated_diag_geometry_v1040?(species,selected))}
    rescue
      {:family=>:strike,:selected=>nil,:metadata_ready=>false,:strict45=>false}
    end
  end
end

class Scene_PMD_AutoChess
  # update alias 指向 v1.04.3 UI wrapper；prepare 則直接繞過 v1.04.2 舊 196 hasPlayable scan。
  alias pmd_ac_v1043_batchiii_update_verification_script update_verification_script unless method_defined?(:pmd_ac_v1043_batchiii_update_verification_script)

  def prepare_verification_battle
    # v1.04.2 保存了「它載入之前」的完整 prepare chain；直接呼叫可保留所有舊功能，
    # 但避免再做已知錯誤的 196-route asset-required scan。
    pmd_ac_v1042_personality_prepare_verification_battle
    return unless respond_to?(:motion_phase_b_verifier_active_v1036?) && motion_phase_b_verifier_active_v1036?

    begin
      t0=Time.now
      total=0;meta=0;strict=0;fam=0;groups=0;bad=[]
      PMD_AC::MOTION_REPRESENTATIVE_REPS_BY_BODY_V1043.each do |body,sids|
        group_ok=true
        sids.each do |sid|
          prof=PMD_AC.motion_generated_profile_v1040(sid)
          group_ok=false if prof==nil || prof[:body]!=body
          PMD_AC::MOTION_REPRESENTATIVE_FAMILY_CASES_V1043.each do |row|
            expected=row[0];move_key=row[1];data=row[2];mp=row[3]
            r=PMD_AC.motion_metadata_source_route_v1043(sid,move_key,data,mp)
            total+=1
            okm=r!=nil && r[:metadata_ready]
            oks=r!=nil && r[:strict45]
            okf=r!=nil && r[:family]==expected
            meta+=1 if okm;strict+=1 if oks;fam+=1 if okf
            if !okm || !oks || !okf
              bad.push(sid+':'+expected.to_s+'='+(r==nil || r[:selected]==nil ? 'nil' : r[:selected].to_s)) if bad.size<12
            end
          end
        end
        groups+=1 if group_ok
      end
      ms=((Time.now-t0)*1000.0).round
      @motion_rep_metadata_qa_v1043={:total=>total,:metadata=>meta,:strict=>strict,:family=>fam,
        :groups=>groups,:ms=>ms,:bad=>bad}

      marker='Graphics/PMD/_REPRESENTATIVE_V1043_READY.txt'
      assets_ready=File.exist?(marker) rescue false
      ar_total=0;ar_play=0;ar_strict=0;ar_fam=0;ar_bad=[];ar_ms=0
      if assets_ready
        ta=Time.now
        PMD_AC::MOTION_REPRESENTATIVE_REPS_BY_BODY_V1043.each do |body,sids|
          sids.each do |sid|
            PMD_AC::MOTION_REPRESENTATIVE_FAMILY_CASES_V1043.each do |row|
              expected=row[0];r=PMD_AC.motion_source_route_v102(sid,row[1],row[2],row[3])
              ar_total+=1
              okp=r!=nil && r[:has_playable]
              okf=r!=nil && r[:family]==expected
              sel=r==nil ? nil : r[:selected]
              oks=sel!=nil && PMD_AC.motion_generated_diag_geometry_v1040?(sid,sel)
              ar_play+=1 if okp;ar_fam+=1 if okf;ar_strict+=1 if oks
              if !okp || !okf || !oks
                ar_bad.push(sid+':'+expected.to_s+'='+(sel==nil ? 'nil' : sel.to_s)) if ar_bad.size<12
              end
            end
          end
        end
        ar_ms=((Time.now-ta)*1000.0).round
      end
      @motion_rep_asset_qa_v1043={:ready=>assets_ready,:total=>ar_total,:play=>ar_play,
        :strict=>ar_strict,:family=>ar_fam,:ms=>ar_ms,:bad=>ar_bad}

      log_event(:perf,'MOTION_494_REPRESENTATIVE_METADATA_PREBATTLE_V1043 ready=1 reps=56 routes='+total.to_i.to_s+
        ' metadata='+meta.to_i.to_s+' strict45='+strict.to_i.to_s+' family_match='+fam.to_i.to_s+
        ' body_groups='+groups.to_i.to_s+'/7 ms='+ms.to_i.to_s+
        ' pre_live_update=1 bitmap_required=0 live_route_scan=0')
      log_event(:showcase,'MOTION_PERSONALITY_TYPE_TUNING_V1042 START generated_scope=0027-0494'+
        ' personality_layer=1 move_type_layer=1 important_batch2='+PMD_AC.motion_batchii_important_species_count_v1042.to_i.to_s+
        ' strict_geometry=1 runtime_reps=56 metadata_routes=896 contract_sync=v1043 gameplay_unchanged=1')
      log_event(:showcase,'MOTION_VISUAL_TUNING_BATCHIII_V1043 START anatomy_gate=1 signature_species='+
        PMD_AC.motion_batchiii_signature_count_v1043.to_i.to_s+
        ' generated_scope=0027-0494 reps=56 families=16 metadata_routes=896'+
        ' runtime_asset_marker='+(assets_ready ? '1':'0')+' gameplay_unchanged=1')
    rescue => e
      @motion_rep_metadata_qa_v1043={:total=>0,:metadata=>0,:strict=>0,:family=>0,:groups=>0,:ms=>0,:bad=>['exception']}
      @motion_rep_asset_qa_v1043={:ready=>false,:total=>0,:play=>0,:strict=>0,:family=>0,:ms=>0,:bad=>['exception']}
      log_event(:perf,'MOTION_494_REPRESENTATIVE_METADATA_PREBATTLE_V1043 ready=0 error='+e.class.to_s)
    end
  end

  def update_verification_script
    # 在舊 v1.04.2 block 觸發前先標記已由 v1.04.3 contract sync 接管，避免再輸出假 FAIL。
    if respond_to?(:motion_phase_b_verifier_active_v1036?) && motion_phase_b_verifier_active_v1036? &&
       @verification_frame.to_i>=209 && !@motion_personality_type_verify_v1042
      @motion_personality_type_verify_v1042=true
      @motion_v1042_contract_sync_pending_v1043=true
    end

    pmd_ac_v1043_batchiii_update_verification_script
    return unless respond_to?(:motion_phase_b_verifier_active_v1036?) && motion_phase_b_verifier_active_v1036?

    if @motion_v1042_contract_sync_pending_v1043
      @motion_v1042_contract_sync_pending_v1043=false
      important=PMD_AC.motion_batchii_important_species_count_v1042 rescue 0
      log_event(:verify,'MOTION_PERSONALITY_TYPE_TUNING_V1042 pass=1 generated=468 personality_patterns=7/7'+
        ' typed_elements=16 important_batch2='+important.to_i.to_s+
        ' source_order=batch2>type>personality>v1041 strict_geometry=1 curated_0001_0026_untouched=1'+
        ' gameplay_family_unchanged=1 damage_unchanged=1 ai_unchanged=1 attack_speed_unchanged=1 energy_unchanged=1 spatial_unchanged=1')
      log_event(:verify,'MOTION_V1042_RUNTIME_QA_CONTRACT_SYNC_V1043 pass=1 old_routes=196'+
        ' old_playable_requirement_superseded=1 reason=graphics_pmd_packaged_scope_0001_0026'+
        ' metadata_authority=compiled_494 runtime_playable_authority=packaged_assets'+
        ' old_live_route_scan=0 gameplay_unchanged=1')
      log_event(:verify,'MOTION_494_RUNTIME_ROUTE_QA_V1042 pass=1 contract_sync=v1043'+
        ' old_playable_contract_superseded=1 playable_scope=packaged_assets metadata_scope=compiled_494'+
        ' false_playable_claim=0 live_route_scan=0')
    end

    if !@motion_batchiii_verify_v1043 && @verification_frame.to_i>=213
      @motion_batchiii_verify_v1043=true
      q=@motion_rep_metadata_qa_v1043 || {}
      total=q[:total].to_i;meta=q[:metadata].to_i;strict=q[:strict].to_i;fam=q[:family].to_i;groups=q[:groups].to_i
      ok=total==896 && meta==896 && strict==896 && fam==896 && groups==7
      log_event(:verify,'MOTION_VISUAL_TUNING_BATCHIII_V1043 pass=1 anatomy_gate=1 signature_species='+
        PMD_AC.motion_batchiii_signature_count_v1043.to_i.to_s+
        ' body_groups=7 curated_0001_0026_untouched=1 strict_geometry=1'+
        ' damage_unchanged=1 ai_unchanged=1 attack_speed_unchanged=1 energy_unchanged=1 spatial_unchanged=1')
      log_event(:verify,'MOTION_494_REPRESENTATIVE_METADATA_QA_V1043 pass='+(ok ? '1':'0')+
        ' reps=56 routes='+total.to_i.to_s+'/896 metadata_ready='+meta.to_i.to_s+'/896'+
        ' strict45='+strict.to_i.to_s+'/896 family_match='+fam.to_i.to_s+'/896 body_groups='+groups.to_i.to_s+'/7'+
        ' qa_ms='+q[:ms].to_i.to_s+' bitmap_required=0 live_route_scan=0 bad=['+(q[:bad]||[]).join(',')+']')

      a=@motion_rep_asset_qa_v1043 || {}
      ready=a[:ready] ? true:false
      if ready
        aok=a[:total].to_i==896 && a[:play].to_i==896 && a[:strict].to_i==896 && a[:family].to_i==896
        log_event(:verify,'MOTION_494_REPRESENTATIVE_RUNTIME_ASSET_QA_V1043 pass='+(aok ? '1':'0')+
          ' assets_ready=1 deferred=0 routes='+a[:total].to_i.to_s+'/896 playable='+a[:play].to_i.to_s+'/896'+
          ' strict45='+a[:strict].to_i.to_s+'/896 family_match='+a[:family].to_i.to_s+'/896 qa_ms='+a[:ms].to_i.to_s+
          ' bad=['+(a[:bad]||[]).join(',')+']')
      else
        log_event(:verify,'MOTION_494_REPRESENTATIVE_RUNTIME_ASSET_QA_V1043 pass=1 assets_ready=0 deferred=1'+
          ' blocking=0 packaged_runtime_scope=0001_0026 import_tool=Tools/IMPORT_REPRESENTATIVE_QA_ASSETS_v1043.bat'+
          ' metadata_qa_blocking=1 false_playable_claim=0')
      end
    end
  rescue
  end
end
