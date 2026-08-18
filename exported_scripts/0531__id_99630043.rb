# encoding: UTF-8
#===============================================================================
# ■ PMD AutoChess - Phase D Progression Authority Audit I v1.05.46
#===============================================================================
# 【目的】
# Motion / Presentation C2 封口後，正式進入 Phase D。
# 本版不重做既有 Progression，而是建立「現在版本」的 Authority Manifest 與
# 全 494 Species / Evolution / Movepool / Mastery / Gameplay Review 一致性稽核。
#
# 舊 v0.46～v0.48 manifest 是當時的歷史快照（262 moves / 4333 of 7005 refs）。
# 現在 Level-up Runtime 已於 v0.59 完成 7005/7005，v0.99.7 又完成完整取得來源。
# 本版保留舊 manifest，不覆寫歷史資料，另建立 CURRENT authority。
#
# 【只讀 / 不改 gameplay】
# - 不改 EXP 曲線、Level Cap、進化結果、Branch Roll、Learnset、4 Active Slots。
# - 不改 Mastery 數值、技能 Damage / Energy / Priority / AI。
# - 不改 Movepool unlock、Tutor、TM/HM、Egg、Special Learning。
# - 不改 494 Gameplay Review profile。
#===============================================================================
$imported={} unless defined?($imported)
$imported['PMD_AutoChess_PhaseDProgressionAuthorityAuditI_v10546']=true

module PMD_AC
  PHASE_D_CURRENT_MANIFEST_V10546={
    :version=>'1.05.46',
    :authority=>:current_progression_integrity,
    :identity=>:instance_uid,
    :species=>494,
    :evolution_lines=>248,
    :level_up_refs=>7005,
    :level_up_unique_moves=>512,
    :move_db=>559,
    :bw_nonlevel_unique=>434,
    :global_nonlevel_unique=>441,
    :canonical_acquisition_union=>538,
    :active_move_slots=>4,
    :mastery_level_max=>5,
    :mastery_thresholds=>[0,10,30,70,150],
    :gameplay_reviewed=>494,
    :historical_v046_v048_manifest_is_snapshot=>true,
    :gameplay_change=>false
  }
  PHASE_D_REVIEW_REQUIRED_FIELDS_V10546=[:role,:movement_policy,:target_policy,
    :threat_policy,:skill_policy,:range,:basic_damage_category,:basic_move_type,
    :target_commitment]
  PHASE_D_MASTERY_CATEGORIES_V10546=[:guard,:tactical,:field,:weather,:two_turn,
    :reactive,:drain,:damage_status,:damage,:heal,:shield,:status,:utility]

  class << self
    def phase_d_extract_acquisition_move_v10546(kind,row)
      return row[1] if kind==:machine && row.is_a?(Array)
      return row[:move] if row.is_a?(Hash)
      row
    rescue
      nil
    end

    def phase_d_progression_integrity_audit_v10546(force=false)
      return @phase_d_progression_integrity_cache_v10546 if !force && @phase_d_progression_integrity_cache_v10546!=nil
      errors=[];warn=[]
      sdb=SPECIES_DB_V016; mdb=MOVE_DB_V017
      ids={};lines={};learn_moves={};learn_refs=0
      evo_edges=0;branch_species=0;additional=[]

      sdb.each do |sk,d|
        id=d[:national_dex].to_i
        ids[id]=[] if ids[id]==nil;ids[id].push(sk)
        lines[d[:line]]=true
        learn=(d[:learnset]||[])
        learn.each do |e|
          learn_refs+=1;mv=e[:move];learn_moves[mv]=true
          errors.push('learn_missing_move:'+sk.to_s+':'+mv.to_s) if mdb[mv]==nil
          lv=e[:level].to_i
          errors.push('learn_level:'+sk.to_s+':'+lv.to_s) if lv<1 || lv>100
          errors.push('learn_method:'+sk.to_s) unless e[:method]==:level_up
        end

        rules=d[:evolution_rules]||[]
        main=rules.find_all{|r|!r[:additional_spawn]}
        branch_species+=1 if main.size>1
        if main.size>1
          levels=main.collect{|r|r[:min_level].to_i}.uniq
          errors.push('branch_level:'+sk.to_s) unless levels.size==1
          errors.push('branch_evolves_to:'+sk.to_s) unless d[:evolves_to]==nil
        elsif main.size==1
          errors.push('evolves_to:'+sk.to_s) unless d[:evolves_to]==main[0][:target_species]
        else
          errors.push('terminal_evolves_to:'+sk.to_s) unless d[:evolves_to]==nil
        end
        rules.each do |r|
          t=r[:target_species];td=sdb[t]
          errors.push('evo_target:'+sk.to_s+':'+t.to_s) if td==nil
          errors.push('evo_trigger:'+sk.to_s+':'+t.to_s) unless r[:trigger]==:level
          lv=r[:min_level].to_i
          errors.push('evo_level:'+sk.to_s+':'+t.to_s) if lv<1 || lv>100
          if td!=nil
            errors.push('evo_line:'+sk.to_s+':'+t.to_s) unless d[:line]==td[:line]
            errors.push('evo_stage:'+sk.to_s+':'+t.to_s) unless td[:stage].to_i>d[:stage].to_i
          end
          if r[:additional_spawn]
            additional.push([sk,t,lv])
          else
            evo_edges+=1
          end
        end
      end

      errors.push('species_count') unless sdb.size==494
      (1..494).each{|id|errors.push('dex:'+id.to_s) if ids[id]==nil || ids[id].size!=1}
      errors.push('line_count') unless lines.size==248
      errors.push('move_db_count') unless mdb.size==559
      errors.push('evolution_edges') unless evo_edges==245
      errors.push('branch_species') unless branch_species==10
      errors.push('learn_refs') unless learn_refs==7005
      errors.push('learn_unique') unless learn_moves.size==512
      errors.push('additional_spawn') unless additional==[[:nincada,:shedinja,20]]

      # Canonical acquisition union: BW TM/HM + Tutor + Egg + Special, then global B2W2 Tutor.
      nonlevel={};source_refs={:machine=>0,:tutor=>0,:egg=>0,:special=>0}
      MOVEPOOL_ACQUISITION_SPECIES_V0995.each do |sk,h|
        [:machine,:tutor,:egg,:special].each do |kind|
          (h[kind]||[]).each do |row|
            mv=phase_d_extract_acquisition_move_v10546(kind,row)
            source_refs[kind]=source_refs[kind].to_i+1
            nonlevel[mv]=true if mv!=nil
            errors.push('acq_move:'+sk.to_s+':'+kind.to_s+':'+mv.to_s) if mv==nil || mdb[mv]==nil
          end
        end
      end
      bw_nonlevel=nonlevel.size
      tutor_refs=0;tutor_moves={}
      GLOBAL_TUTOR_B2W2_V0997.each do |sk,a|
        a.each do |mv|
          tutor_refs+=1;tutor_moves[mv]=true;nonlevel[mv]=true
          errors.push('global_tutor_move:'+sk.to_s+':'+mv.to_s) if mdb[mv]==nil
        end
      end
      missing_tutor=sdb.keys.find_all{|sk|GLOBAL_TUTOR_B2W2_V0997[sk]==nil}.sort_by{|x|x.to_s}
      expected_missing=[:ditto,:unown,:wobbuffet,:smeargle,:wynaut].sort_by{|x|x.to_s}
      errors.push('acquisition_species') unless MOVEPOOL_ACQUISITION_SPECIES_V0995.size==494
      errors.push('machine_refs') unless source_refs[:machine]==15678
      errors.push('tutor_refs_bw') unless source_refs[:tutor]==68
      errors.push('egg_refs') unless source_refs[:egg]==2251
      errors.push('special_refs') unless source_refs[:special]==2
      errors.push('bw_nonlevel_unique') unless bw_nonlevel==434
      errors.push('global_tutor_species') unless GLOBAL_TUTOR_B2W2_V0997.size==489
      errors.push('global_tutor_refs') unless tutor_refs==5361
      errors.push('global_tutor_moves') unless tutor_moves.size==67
      errors.push('global_tutor_missing') unless missing_tutor==expected_missing
      errors.push('global_nonlevel_unique') unless nonlevel.size==441

      union={};learn_moves.each_key{|mv|union[mv]=true};nonlevel.each_key{|mv|union[mv]=true}
      errors.push('acquisition_union') unless union.size==538

      # Runtime truth: every move that can enter a Pokémon's learned library must execute,
      # produce skill data, and enter a meaningful Mastery policy category.
      runtime_blocked=[];skill_missing=[];mastery_unknown=[]
      union.keys.each do |mv|
        begin
          runtime_blocked.push(mv) unless move_executable?(mv)
        rescue
          runtime_blocked.push(mv)
        end
        begin
          key=canonical_runtime_skill_key(mv)
          data=skill_data(key)
          skill_missing.push(mv) if data==nil || data.empty?
          if data!=nil && !data.empty? && respond_to?(:mastery_move_category_v048)
            cat=mastery_move_category_v048(data)
            mastery_unknown.push([mv,cat]) unless PHASE_D_MASTERY_CATEGORIES_V10546.include?(cat)
          end
        rescue
          skill_missing.push(mv) unless skill_missing.include?(mv)
        end
      end
      errors.push('runtime_blocked:'+runtime_blocked.collect{|x|x.to_s}.sort.join(',')) unless runtime_blocked.empty?
      errors.push('skill_missing:'+skill_missing.collect{|x|x.to_s}.sort.join(',')) unless skill_missing.empty?
      errors.push('mastery_unknown:'+mastery_unknown.collect{|x|x[0].to_s+'='+x[1].to_s}.sort.join(',')) unless mastery_unknown.empty?

      # Identity / active slots / mastery policy safety contract.
      errors.push('active_slots') unless const_defined?(:ACTIVE_MOVE_SLOTS_V045) && ACTIVE_MOVE_SLOTS_V045.to_i==4
      errors.push('mastery_max') unless const_defined?(:MOVE_LEVEL_MAX_V045) && MOVE_LEVEL_MAX_V045.to_i==5
      th=const_defined?(:MOVE_MASTERY_THRESHOLDS_V045) ? MOVE_MASTERY_THRESHOLDS_V045 : []
      errors.push('mastery_thresholds') unless th==[0,10,30,70,150]
      if const_defined?(:MASTERY_POLICY_SAFETY_V048)
        safe=MASTERY_POLICY_SAFETY_V048
        [:stat_stage_amplification,:hard_control_duration_scaling,:priority_tier_scaling,
         :two_turn_phase_reduction,:helping_hand_multiplier_scaling,:reactive_return_ratio_scaling].each do |k|
          errors.push('mastery_safety:'+k.to_s) unless safe[k]==false
        end
      else
        errors.push('mastery_safety_missing')
      end

      # 494 Gameplay Review union and required tactical fields.
      regions=[KANTO_PROFILE_OVERRIDES_V0998,JOHTO_PROFILE_OVERRIDES_V0999,
        HOENN_PROFILE_OVERRIDES_V09910,FINAL_PROFILE_OVERRIDES_V09911]
      reviewed={};duplicate=[];review_field_bad=[]
      regions.each do |h|
        h.each do |sk,p|
          duplicate.push(sk) if reviewed[sk]
          reviewed[sk]=true
          missing=PHASE_D_REVIEW_REQUIRED_FIELDS_V10546.find_all{|f|!p.has_key?(f)}
          review_field_bad.push([sk,missing]) unless missing.empty?
        end
      end
      errors.push('review_count') unless reviewed.size==494
      errors.push('review_missing') unless sdb.keys.find_all{|sk|!reviewed[sk]}.empty?
      errors.push('review_duplicate') unless duplicate.empty?
      errors.push('review_fields') unless review_field_bad.empty?

      # Old manifests stay untouched by design; explicitly classify them as historical snapshots.
      historical_stale=false
      begin
        historical_stale=(PROGRESSION_RUNTIME_MANIFEST_V046[:learnset_reference_covered].to_i<7005 ||
          MASTERY_POLICY_MANIFEST_V048[:learnset_reference_covered].to_i<7005)
      rescue
        historical_stale=true
      end
      warn.push(:historical_v046_v048_manifest_snapshot) if historical_stale

      r={:pass=>errors.empty?,:errors=>errors,:warnings=>warn,
        :species=>sdb.size,:lines=>lines.size,:learn_refs=>learn_refs,:learn_unique=>learn_moves.size,
        :evolution_edges=>evo_edges,:branch_species=>branch_species,:additional_spawn=>additional.size,
        :bw_nonlevel=>bw_nonlevel,:global_nonlevel=>nonlevel.size,:acquisition_union=>union.size,
        :runtime_ready=>union.size-runtime_blocked.size,:skill_ready=>union.size-skill_missing.size,
        :mastery_ready=>union.size-mastery_unknown.size,:reviewed=>reviewed.size,
        :tutor_species=>GLOBAL_TUTOR_B2W2_V0997.size,:tutor_refs=>tutor_refs,:tutor_moves=>tutor_moves.size,
        :historical_manifest_snapshot=>historical_stale}
      @phase_d_progression_integrity_cache_v10546=r
      r
    rescue => e
      @phase_d_progression_integrity_cache_v10546={:pass=>false,:errors=>['audit_exception:'+e.class.to_s+':'+e.message.to_s],
        :warnings=>[],:species=>0,:lines=>0,:learn_refs=>0,:learn_unique=>0,:acquisition_union=>0,
        :runtime_ready=>0,:skill_ready=>0,:mastery_ready=>0,:reviewed=>0,:historical_manifest_snapshot=>true}
    end

    def phase_d_progression_integrity_summary_v10546(r=nil)
      a=r || phase_d_progression_integrity_audit_v10546
      'pass='+(a[:pass] ? '1':'0')+
      ' species='+a[:species].to_i.to_s+'/494 lines='+a[:lines].to_i.to_s+'/248'+
      ' levelup='+a[:learn_refs].to_i.to_s+'/7005 unique='+a[:learn_unique].to_i.to_s+'/512'+
      ' acquisition_union='+a[:acquisition_union].to_i.to_s+'/538'+
      ' runtime='+a[:runtime_ready].to_i.to_s+'/538 skill_data='+a[:skill_ready].to_i.to_s+'/538'+
      ' mastery='+a[:mastery_ready].to_i.to_s+'/538 review='+a[:reviewed].to_i.to_s+'/494'+
      ' historical_manifest_snapshot='+(a[:historical_manifest_snapshot] ? '1':'0')+
      ' errors=['+(a[:errors]||[]).join('|')+'] warnings=['+(a[:warnings]||[]).collect{|x|x.to_s}.join('|')+']'
    rescue
      'pass=0 errors=[summary_exception]'
    end
  end
end

class Scene_PMD_AutoChess
  alias pmd_ac_v10546_start_battle start_battle unless method_defined?(:pmd_ac_v10546_start_battle)
  alias pmd_ac_v10546_focus_summary focus_cast_log_summary_v1055 unless method_defined?(:pmd_ac_v10546_focus_summary)

  def start_battle
    r=pmd_ac_v10546_start_battle
    begin
      if respond_to?(:verification_mode) && verification_mode==:normal && !@phase_d_progression_audit_logged_v10546 &&
         !(respond_to?(:production_external_battle_fast_v10613?) && production_external_battle_fast_v10613?)
        @phase_d_progression_audit_logged_v10546=true
        a=PMD_AC.phase_d_progression_integrity_audit_v10546
        log_event(:battle,'BATTLE_PHASE_D_PROGRESSION_AUTHORITY_V10546 '+PMD_AC.phase_d_progression_integrity_summary_v10546(a)+
          ' gameplay_change=0 identity=instance_uid active_slots=4 mastery_lv=5')
      end
    rescue
      @phase_d_progression_audit_error_v10546=@phase_d_progression_audit_error_v10546.to_i+1
    end
    r
  end

  def focus_cast_log_summary_v1055
    r=pmd_ac_v10546_focus_summary
    return r if respond_to?(:production_external_battle_fast_v10613?) && production_external_battle_fast_v10613?
    begin
      a=PMD_AC.phase_d_progression_integrity_audit_v10546
      log_event(:battle,'BATTLE_PHASE_D_PROGRESSION_AUTHORITY_SUMMARY_V10546 '+PMD_AC.phase_d_progression_integrity_summary_v10546(a)+
        ' blocking_gate=0 issue_driven_adjustment=1')
    rescue
    end
    r
  end
end
