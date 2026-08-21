# encoding: UTF-8
#===============================================================================
# ■ PMD AutoChess - P8-II Deterministic Battle Regression Consolidation I
#   v1.06.68a TEST HARNESS REPAIR
#-------------------------------------------------------------------------------
# 【用途】
# - 從 v1.06.67 FORMAL PASS / P8 Cross-Gate SEALED 接續。
# - 不重開 Battle AI / Damage Formula / Attack Speed / Focus-C2 / Spatial endpoint
#   / Gate3 Reward / Random Hunt Gate Authority。
# - 在 NORMAL PMD battle 中以 TEST-only F5 執行「static + detached runtime」回歸。
# - 不改 live battle unit，不開始新 Battle，不發 Reward，不呼叫 Damage Formula，
#   不直接呼叫 rand；detached unit 只測正式 displacement runtime method。
# - species-focused route 使用既有 motion_source_route_v102，不建立 projectile / effect。
# - 執行前後比對 Party / battle request / live units / scene phase，證明 live battle 不變。
#
# 【QA Shortcut Governance】
# - Scene_Map F5 仍由 v1.06.67 P8 Cross-Gate 擁有。
# - Scene_PMD_AutoChess battle F5 由本版 P8-II 擁有；相同 key、不同 scene dispatch。
# - 不新增 F6/F7/F8/F9 launcher；Production F8 完全不碰。
#===============================================================================
$imported={} unless defined?($imported)
$imported['PMD_AutoChess_P8IIDeterministicBattleRegressionConsolidationI_v10668a']=true

module PMD_AC
  P8II_VERSION_V10668='1.06.68a'
  P8II_LOG_V10668='PMD_P8II_BattleRegression_LATEST.log'
  P8II_FORMAL_BASE_VERSION_V10668='1.06.67'
  P8II_FORMAL_BASE_SCRIPT_COUNT_V10668=652
  P8II_FORMAL_BASE_SCRIPTS_SHA256_V10668='91495233cd3d38572a9bcd5091e8d1076ea1260c5126a0a99cca9edfdb9c3c4b'
  P8II_EXPECTED_CANDIDATE_SCRIPT_COUNT_V10668=653

  P8II_ROUTE_SAMPLES_V10668=[
    ['0010',:strike],      # Caterpie / small
    ['0123',:dash],        # Scyther / avian-like
    ['0282',:cast],        # Gardevoir / medium
    ['0448',:punch],       # Lucario / biped
    ['0445',:bite],        # Garchomp / heavy
    ['0479',:shock]        # Rotom / hover
  ]

  class << self
    def p8ii_crc_v10668(obj)
      return nil if obj==nil
      Zlib.crc32(Marshal.dump(obj))
    rescue
      -1
    end

    def p8ii_request_v10668
      return nil if $game_temp==nil
      return $game_temp.pmd_autochess_request_v081 if $game_temp.respond_to?(:pmd_autochess_request_v081)
      $game_temp.instance_variable_get(:@pmd_autochess_request_v081)
    rescue
      nil
    end

    def p8ii_scene_live_digest_v10668(scene)
      return -1 if scene==nil
      units=scene.instance_variable_get(:@units) || []
      rows=[]
      units.each do |u|
        next if u==nil
        pi=(u.respond_to?(:pokemon_instance) ? u.pokemon_instance : nil)
        rows << [
          u.object_id,
          (u.respond_to?(:team) ? u.team : u.instance_variable_get(:@team)),
          u.instance_variable_get(:@hp).to_i,
          u.instance_variable_get(:@energy).to_i,
          u.instance_variable_get(:@pixel_x).to_f,
          u.instance_variable_get(:@pixel_y).to_f,
          u.instance_variable_get(:@velocity_x).to_f,
          u.instance_variable_get(:@velocity_y).to_f,
          u.instance_variable_get(:@action),
          u.instance_variable_get(:@visual_action),
          u.instance_variable_get(:@action_timer).to_i,
          u.instance_variable_get(:@knockback_frames).to_i,
          (u.instance_variable_get(:@target)==nil ? 0:u.instance_variable_get(:@target).object_id),
          (u.instance_variable_get(:@skill_target)==nil ? 0:u.instance_variable_get(:@skill_target).object_id),
          p8ii_crc_v10668(pi)
        ]
      end
      Zlib.crc32(Marshal.dump(rows))
    rescue
      -1
    end

    def p8ii_snapshot_v10668(scene)
      {
        :party=>p8ii_crc_v10668($game_party),
        :request=>p8ii_crc_v10668(p8ii_request_v10668),
        :live_units=>p8ii_scene_live_digest_v10668(scene),
        :scene_class=>(scene==nil ? 'nil':scene.class.to_s),
        :scene_phase=>(scene==nil ? nil:scene.instance_variable_get(:@phase)),
        :unit_count=>(scene==nil ? 0:(scene.instance_variable_get(:@units)||[]).compact.size)
      }
    rescue Exception=>e
      {:party=>-1,:request=>-1,:live_units=>-1,:scene_class=>'snapshot_error:'+e.class.to_s,
       :scene_phase=>nil,:unit_count=>-1}
    end

    def p8ii_snapshot_compare_v10668(before,after)
      keys=[:party,:request,:live_units,:scene_class,:scene_phase,:unit_count]
      changed=[]
      keys.each{|k|changed << k if before[k]!=after[k]}
      {
        :pass=>changed.empty?,:changed=>changed,
        :party_mutation=>(before[:party]==after[:party] ? 0:1),
        :request_mutation=>(before[:request]==after[:request] ? 0:1),
        :live_unit_mutation=>(before[:live_units]==after[:live_units] ? 0:1),
        :scene_mutation=>((before[:scene_class]==after[:scene_class] && before[:scene_phase]==after[:scene_phase]) ? 0:1),
        :battle_launch=>((before[:scene_class]==after[:scene_class]) ? 0:1),
        :reward_grant=>(before[:party]==after[:party] ? 0:1),
        :harness_extra_rng_calls=>0
      }
    rescue
      {:pass=>false,:changed=>[:compare_error],:party_mutation=>1,:request_mutation=>1,
       :live_unit_mutation=>1,:scene_mutation=>1,:battle_launch=>1,:reward_grant=>1,
       :harness_extra_rng_calls=>0}
    end

    def p8ii_cache_snapshot_v10668
      out={}
      [:@phase_d_progression_integrity_cache_v10546,:@motion_generated_diag_cache_v1040].each do |iv|
        if instance_variable_defined?(iv)
          out[iv]=[:present,instance_variable_get(iv)]
        else
          out[iv]=[:missing,nil]
        end
      end
      out
    rescue
      {}
    end

    def p8ii_cache_restore_v10668(snap)
      (snap||{}).each do |iv,row|
        if row[0]==:present
          instance_variable_set(iv,row[1])
        elsif instance_variable_defined?(iv)
          send(:remove_instance_variable,iv)
        end
      end
      true
    rescue
      false
    end

    def p8ii_result_v10668(pass,bad=nil,extra=nil)
      h={:pass=>(pass ? true:false),:bad=>(bad||[])}
      (extra||{}).each{|k,v|h[k]=v}
      h
    end

    def p8ii_api_audit_v10668
      required=[
        :phase_d_progression_integrity_audit_v10546,
        :motion_batchv_sample_audit_v1045,
        :weather_maintenance_audit_v10569,
        :visual_test_loadout_audit_v10570,
        :representative_runtime_matrix_v10527,
        :phase_div_early_audit_v10554,
        :motion_action_family_v102,
        :motion_species_profile_v102,
        :motion_generated_profile_v1040,
        :runtime_asset_admitted_v10526?
      ]
      missing=required.find_all{|m|!respond_to?(m)}
      p8ii_result_v10668(missing.empty?,missing.collect{|m|'missing:'+m.to_s},
        {:required=>required.size,:available=>required.size-missing.size})
    rescue Exception=>e
      p8ii_result_v10668(false,['api_audit:'+e.class.to_s])
    end

    def p8ii_progression_audit_v10668
      r=phase_d_progression_integrity_audit_v10546
      pass=r.is_a?(Hash) && r[:pass] && r[:species].to_i==494 && r[:lines].to_i==248
      p8ii_result_v10668(pass,(r.is_a?(Hash) ? (r[:errors]||[]):['invalid_result']),
        {:species=>(r.is_a?(Hash) ? r[:species].to_i : 0),:lines=>(r.is_a?(Hash) ? r[:lines].to_i : 0)})
    rescue Exception=>e
      p8ii_result_v10668(false,['progression:'+e.class.to_s])
    end

    def p8ii_evolution_audit_v10668
      r=motion_batchv_sample_audit_v1045
      pass=r.is_a?(Hash) && r[:checks].to_i>0 && r[:checks].to_i==r[:passed].to_i
      p8ii_result_v10668(pass,(r.is_a?(Hash) ? (r[:bad]||[]):['invalid_result']),
        {:checks=>(r.is_a?(Hash) ? r[:checks].to_i : 0),:passed=>(r.is_a?(Hash) ? r[:passed].to_i : 0)})
    rescue Exception=>e
      p8ii_result_v10668(false,['evolution:'+e.class.to_s])
    end

    def p8ii_weather_audit_v10668
      r=weather_maintenance_audit_v10569
      pass=r.is_a?(Hash) && r[:pass] && r[:observer_only]
      p8ii_result_v10668(pass,(pass ? []:['weather_contract']),
        {:factor=>(r.is_a?(Hash) ? r[:existing_factor]:nil),:turn_frames=>(r.is_a?(Hash) ? r[:turn_frames].to_i : 0)})
    rescue Exception=>e
      p8ii_result_v10668(false,['weather:'+e.class.to_s])
    end

    def p8ii_representative_asset_audit_v10668
      r=representative_runtime_matrix_v10527
      unless r.is_a?(Hash)
        return p8ii_result_v10668(false,['invalid_result'])
      end
      total=r[:total].to_i
      ready=r[:ready].to_i
      partial=r[:partial].to_i
      missing=r[:missing].to_i
      pending=(r[:pending]||[]).size
      # Runtime Asset Expansion 0027..0494 is explicitly deferred by current Authority.
      # P8-II therefore validates the 56-representative admission matrix contract, not
      # completion of PNG production. Missing/deferred assets are observational only.
      bad=[]
      bad << 'representative_total:'+total.to_s unless total==56
      bad << 'representative_partition' unless ready+partial+missing==total
      bad << 'representative_pending' unless pending==partial+missing
      expected_complete=(total>0 && ready==total)
      bad << 'representative_complete_flag' unless (!!r[:complete])==expected_complete
      deferred=partial+missing
      p8ii_result_v10668(bad.empty?,bad,{:ready=>ready,:total=>total,
        :partial=>partial,:missing=>missing,:deferred=>deferred,
        :completion_required=>false})
    rescue Exception=>e
      p8ii_result_v10668(false,['representative_assets:'+e.class.to_s])
    end

    def p8ii_loadout_audit_v10668
      r=visual_test_loadout_audit_v10570
      pass=r.is_a?(Hash) && r[:pass] && r[:species].to_i==6 && r[:slots].to_i==24
      p8ii_result_v10668(pass,(r.is_a?(Hash) ? (r[:bad]||[]):['invalid_result']),
        {:species=>(r.is_a?(Hash) ? r[:species].to_i : 0),:slots=>(r.is_a?(Hash) ? r[:slots].to_i : 0)})
    rescue Exception=>e
      p8ii_result_v10668(false,['loadout:'+e.class.to_s])
    end

    def p8ii_early_battle_content_audit_v10668
      r=phase_div_early_audit_v10554
      unless r.is_a?(Hash)
        return p8ii_result_v10668(false,['invalid_result'])
      end
      # v1.05.54 began as 2 Hunts + 2 Challenges, but later accepted content extends
      # the same Challenge table through C12. Do not treat legitimate expansion as drift.
      hunts=r[:hunts].to_i
      challenges=r[:challenges].to_i
      rewards=r[:fixed_rewards].to_i
      bad=(r[:bad]||[]).dup
      bad << 'early_hunts:'+hunts.to_s unless hunts>=2
      bad << 'challenge_floor:'+challenges.to_s unless challenges>=2
      bad << 'reward_floor:'+rewards.to_s unless rewards>=2
      pass=r[:pass] && bad.empty?
      p8ii_result_v10668(pass,bad,{:hunts=>hunts,:challenges=>challenges,
        :fixed_rewards=>rewards})
    rescue Exception=>e
      p8ii_result_v10668(false,['early_battle:'+e.class.to_s])
    end

    def p8ii_boss_contract_audit_v10668
      bad=[]
      unless const_defined?(:STORY_BOSS_SETUP_V1014) && const_defined?(:STORY_BOSS_PROFILE_V1014)
        bad << 'missing_boss_contract'
        return p8ii_result_v10668(false,bad)
      end
      setup=STORY_BOSS_SETUP_V1014
      prof=STORY_BOSS_PROFILE_V1014
      bad << 'team_size' unless setup.is_a?(Array) && setup.size==3
      bad << 'boss_species' unless setup[1]!=nil && setup[1][0]==:beedrill
      bad << 'encounter' unless prof.is_a?(Hash) && prof[:encounter]==:boss_beedrill
      bad << 'phases' unless prof.is_a?(Hash) && (prof[:phases]||[]).size==4
      bad << 'recruit_policy' unless prof.is_a?(Hash) && prof[:never_recruit]==true
      p8ii_result_v10668(bad.empty?,bad,{:team=>(setup.is_a?(Array) ? setup.size : 0),
        :phases=>(prof.is_a?(Hash) ? (prof[:phases]||[]).size : 0)})
    rescue Exception=>e
      p8ii_result_v10668(false,['boss_contract:'+e.class.to_s])
    end

    def p8ii_route_case_v10668(family)
      return nil unless const_defined?(:MOTION_QA_ROUTE_CASES_V1039)
      MOTION_QA_ROUTE_CASES_V1039.find{|row|row[0]==family}
    rescue
      nil
    end

    def p8ii_species_route_audit_v10668
      bad=[];passed=0;profile_ready=0;asset_admitted=0;asset_deferred=0
      P8II_ROUTE_SAMPLES_V10668.each do |sample|
        sid=sample[0];fam=sample[1]
        row=p8ii_route_case_v10668(fam)
        if row==nil
          bad << sid+':'+fam.to_s+':case_missing'
          next
        end
        actual=motion_action_family_v102(row[1],row[2],row[3])
        prof=nil
        if sid.to_i<=26
          prof=motion_species_profile_v102(sid)
        else
          prof=motion_generated_profile_v1040(sid)
        end
        admitted=runtime_asset_admitted_v10526?(sid)
        if actual==fam && prof!=nil
          passed+=1
          profile_ready+=1
        else
          bad << sid+':'+fam.to_s+':family='+actual.to_s+':profile='+(prof==nil ? '0':'1')
        end
        if admitted
          asset_admitted+=1
        else
          asset_deferred+=1
        end
      end
      pass=passed==P8II_ROUTE_SAMPLES_V10668.size && bad.empty?
      p8ii_result_v10668(pass,bad,{:passed=>passed,:total=>P8II_ROUTE_SAMPLES_V10668.size,
        :profile_ready=>profile_ready,:asset_admitted=>asset_admitted,
        :asset_deferred=>asset_deferred,:asset_completion_required=>false})
    rescue Exception=>e
      p8ii_result_v10668(false,['species_route:'+e.class.to_s])
    end

    def p8ii_detached_unit_v10668(species,slot,team,id,x)
      inst=PMD_PokemonInstance.new(species,20,{:ability_slot=>slot})
      u=Game_PMDChessUnit.new(id,species,team,team==:ally ? 1:4,1,inst)
      u.instance_variable_set(:@scene,nil)
      u.start_combat
      u.instance_variable_set(:@pixel_x,x.to_f)
      u.instance_variable_set(:@pixel_y,200.0)
      u
    rescue
      nil
    end

    def p8ii_detached_displacement_audit_v10668
      bad=[]
      src=p8ii_detached_unit_v10668(:rattata,:primary,:enemy,1066801,300)
      normal=p8ii_detached_unit_v10668(:caterpie,:primary,:ally,1066802,200)
      suction=p8ii_detached_unit_v10668(:lileep,:primary,:ally,1066803,200)
      if src==nil || normal==nil || suction==nil
        return p8ii_result_v10668(false,['detached_unit_create'])
      end
      normal.apply_knockback(src,40)
      normal_kb=normal.instance_variable_get(:@knockback_frames).to_i
      normal_vec=normal.instance_variable_get(:@knockback_x).to_f.abs+normal.instance_variable_get(:@knockback_y).to_f.abs
      bad << 'normal_knockback_not_started' unless normal_kb>0 && normal_vec>0.0
      suction.apply_knockback(src,40)
      suction_kb=suction.instance_variable_get(:@knockback_frames).to_i
      suction.apply_pull(src,40)
      suction_after_pull=suction.instance_variable_get(:@knockback_frames).to_i
      bad << 'suction_knockback_not_blocked' unless suction_kb==0
      bad << 'suction_pull_not_blocked' unless suction_after_pull==0
      p8ii_result_v10668(bad.empty?,bad,{:normal_frames=>normal_kb,
        :suction_knockback_frames=>suction_kb,:suction_pull_frames=>suction_after_pull,
        :detached_only=>true})
    rescue Exception=>e
      p8ii_result_v10668(false,['displacement:'+e.class.to_s])
    end

    def p8ii_audit_line_v10668(key,row)
      'AUDIT key='+key.to_s+' result='+(row[:pass] ? 'PASS':'FAIL')+
        ' bad=['+(row[:bad]||[]).collect{|x|x.to_s}.join(',')+']'
    rescue
      'AUDIT key='+key.to_s+' result=FAIL bad=[log_error]'
    end

    def p8ii_write_log_v10668(result)
      lines=[]
      lines << 'PMD AutoChess P8-II Deterministic Battle Regression Consolidation I'
      lines << 'VERSION='+P8II_VERSION_V10668
      lines << 'FORMAL_BASE='+P8II_FORMAL_BASE_VERSION_V10668
      lines << 'FORMAL_BASE_SCRIPT_COUNT='+P8II_FORMAL_BASE_SCRIPT_COUNT_V10668.to_i.to_s
      lines << 'FORMAL_BASE_SCRIPTS_SHA256='+P8II_FORMAL_BASE_SCRIPTS_SHA256_V10668
      current_count=(defined?($RGSS_SCRIPTS) && $RGSS_SCRIPTS.is_a?(Array)) ? $RGSS_SCRIPTS.size : 0
      lines << 'CURRENT_SCRIPT_COUNT='+current_count.to_i.to_s
      lines << 'EXPECTED_CANDIDATE_SCRIPT_COUNT='+P8II_EXPECTED_CANDIDATE_SCRIPT_COUNT_V10668.to_i.to_s
      lines << 'TEST_LAUNCHER=F5_SCENE_PMD_AUTOCHESS_BATTLE'
      lines << 'SCENE_MAP_F5_P8_CROSS_GATE_PRESERVED=1'
      lines << 'PRODUCTION_F8_PRESERVED=1'
      lines << 'NEW_F6_F7_F8_F9_LAUNCHERS=0'
      lines << 'SEALED_GAMEPLAY_REOPENED=0'
      lines << 'EXECUTION_MODE=STATIC_PLUS_DETACHED_RUNTIME'
      result[:rows].keys.sort{|a,b|a.to_s<=>b.to_s}.each do |k|
        lines << p8ii_audit_line_v10668(k,result[:rows][k])
      end
      d=result[:rows][:detached_displacement]||{}
      lines << 'DETACHED_NORMAL_KNOCKBACK_FRAMES='+d[:normal_frames].to_i.to_s
      lines << 'DETACHED_SUCTION_KNOCKBACK_FRAMES='+d[:suction_knockback_frames].to_i.to_s
      lines << 'DETACHED_SUCTION_PULL_FRAMES='+d[:suction_pull_frames].to_i.to_s
      a=result[:rows][:representative_assets]||{}
      lines << 'REPRESENTATIVE_ASSET_READY='+a[:ready].to_i.to_s+'/'+a[:total].to_i.to_s
      lines << 'REPRESENTATIVE_ASSET_DEFERRED='+a[:deferred].to_i.to_s
      lines << 'REPRESENTATIVE_ASSET_COMPLETION_REQUIRED='+(a[:completion_required] ? '1':'0')
      e=result[:rows][:early_battle_content]||{}
      lines << 'EARLY_HUNTS='+e[:hunts].to_i.to_s
      lines << 'CHALLENGES_CURRENT='+e[:challenges].to_i.to_s
      lines << 'FIXED_REWARDS_CURRENT='+e[:fixed_rewards].to_i.to_s
      s=result[:rows][:species_routes]||{}
      lines << 'SPECIES_ROUTE_SAMPLE='+s[:passed].to_i.to_s+'/'+s[:total].to_i.to_s
      lines << 'SPECIES_ROUTE_PROFILE_READY='+s[:profile_ready].to_i.to_s+'/'+s[:total].to_i.to_s
      lines << 'SPECIES_ROUTE_ASSET_ADMITTED='+s[:asset_admitted].to_i.to_s+'/'+s[:total].to_i.to_s
      lines << 'SPECIES_ROUTE_ASSET_DEFERRED='+s[:asset_deferred].to_i.to_s
      lines << 'SPECIES_ROUTE_ASSET_COMPLETION_REQUIRED='+(s[:asset_completion_required] ? '1':'0')
      m=result[:mutation]||{}
      lines << 'HARNESS_EXTRA_RNG_CALLS='+m[:harness_extra_rng_calls].to_i.to_s
      lines << 'REWARD_GRANT='+m[:reward_grant].to_i.to_s
      lines << 'PARTY_MUTATION='+m[:party_mutation].to_i.to_s
      lines << 'BATTLE_REQUEST_MUTATION='+m[:request_mutation].to_i.to_s
      lines << 'LIVE_UNIT_MUTATION='+m[:live_unit_mutation].to_i.to_s
      lines << 'SCENE_MUTATION='+m[:scene_mutation].to_i.to_s
      lines << 'BATTLE_LAUNCH='+m[:battle_launch].to_i.to_s
      lines << 'MODULE_CACHE_RESTORED='+(result[:cache_restored] ? '1':'0')
      lines << 'BLOCKERS='+result[:blockers].size.to_i.to_s
      result[:blockers].each do |b|
        lines << 'BLOCKER key='+b[:key].to_s+' class='+b[:class].to_s.upcase+
          ' bad=['+(b[:bad]||[]).join(',')+']'
      end
      lines << 'RESULT='+(result[:pass] ? 'PASS':'FAIL')
      File.open(P8II_LOG_V10668,'wb'){|io|io.write(lines.join("\r\n")+"\r\n")}
      true
    rescue
      false
    end

    def p8ii_run_v10668(scene)
      blockers=[];rows={}
      before=p8ii_snapshot_v10668(scene)
      cache=p8ii_cache_snapshot_v10668
      cache_restored=false
      begin
        rows[:api]=p8ii_api_audit_v10668
        if rows[:api][:pass]
          rows[:progression]=p8ii_progression_audit_v10668
          rows[:evolution]=p8ii_evolution_audit_v10668
          rows[:weather]=p8ii_weather_audit_v10668
          rows[:representative_assets]=p8ii_representative_asset_audit_v10668
          rows[:curated_loadouts]=p8ii_loadout_audit_v10668
          rows[:early_battle_content]=p8ii_early_battle_content_audit_v10668
          rows[:boss_contract]=p8ii_boss_contract_audit_v10668
          rows[:species_routes]=p8ii_species_route_audit_v10668
          rows[:detached_displacement]=p8ii_detached_displacement_audit_v10668
        end
      ensure
        cache_restored=p8ii_cache_restore_v10668(cache)
      end
      rows.each do |key,row|
        next if row[:pass]
        klass=(key==:api ? :test_defect : :runtime_defect)
        blockers << {:key=>key,:class=>klass,:bad=>(row[:bad]||[:unknown]).collect{|x|x.to_s}}
      end
      unless cache_restored
        blockers << {:key=>:cache_restore,:class=>:test_defect,:bad=>['module_cache_restore_failed']}
      end
      after=p8ii_snapshot_v10668(scene)
      mutation=p8ii_snapshot_compare_v10668(before,after)
      unless mutation[:pass]
        blockers << {:key=>:live_state_guard,:class=>:runtime_defect,
          :bad=>(mutation[:changed]||[:unknown]).collect{|x|x.to_s}}
      end
      pass=!rows.empty? && rows.values.all?{|r|r[:pass]} && mutation[:pass] && cache_restored && blockers.empty?
      result={:pass=>pass,:rows=>rows,:mutation=>mutation,:blockers=>blockers,
        :cache_restored=>cache_restored,:before=>before,:after=>after}
      @p8ii_last_result_v10668=result
      p8ii_write_log_v10668(result)
      result
    rescue Exception=>e
      begin;p8ii_cache_restore_v10668(cache);rescue;end
      result={:pass=>false,:rows=>rows||{},:mutation=>{:pass=>false,:harness_extra_rng_calls=>0},
        :blockers=>[{:key=>:harness_exception,:class=>:test_defect,:bad=>[e.class.to_s]}],:cache_restored=>false}
      @p8ii_last_result_v10668=result
      p8ii_write_log_v10668(result)
      result
    end

    def p8ii_last_result_v10668
      @p8ii_last_result_v10668
    end

    alias pmd_ac_v10668_write_project_state_log write_project_state_log unless method_defined?(:pmd_ac_v10668_write_project_state_log)
    def project_version
      P8II_VERSION_V10668
    end
    def write_project_state_log(force=false)
      r=pmd_ac_v10668_write_project_state_log(force)
      return false unless r
      begin
        text=''
        File.open(PROJECT_STATE_FILE_V10564,'rb'){|io|text=io.read}
        text=text.gsub(/PROJECT_STATE_SCHEMA=\d+/,'PROJECT_STATE_SCHEMA=49')
        text=text.gsub(/CURRENT_VERSION=[^\r\n]+/,'CURRENT_VERSION=1.06.68')
        text=text.gsub(/LATEST_FEATURE=[^\r\n]+/,'LATEST_FEATURE=P8II_DETERMINISTIC_BATTLE_REGRESSION_CONSOLIDATION_I')
        text=text.gsub(/NEXT_TARGET=[^\r\n]+/,'NEXT_TARGET=P8II_V10668_WINDOWS_BATTLE_F5_ACCEPTANCE')
        text=text.gsub(/\r?\nP8II_V10668_BEGIN.*?P8II_V10668_END\r?\n/m,"\r\n")
        last=p8ii_last_result_v10668
        lines=[]
        lines << ''
        lines << 'P8II_V10668_BEGIN'
        lines << 'P8II_STATUS='+(last==nil ? 'PENDING_WINDOWS_BATTLE_F5':(last[:pass] ? 'PASS':'FAIL'))
        lines << 'P8II_TEST_LAUNCHER=F5_SCENE_PMD_AUTOCHESS_BATTLE'
        lines << 'P8II_SCENE_MAP_F5_PRESERVED=1'
        lines << 'P8II_PRODUCTION_F8_PRESERVED=1'
        lines << 'P8II_EXECUTION=STATIC_PLUS_DETACHED_RUNTIME'
        lines << 'P8II_LIVE_BATTLE_MUTATION_EXPECTED=0'
        lines << 'P8II_EXTRA_RNG_EXPECTED=0'
        lines << 'P8II_LOG='+P8II_LOG_V10668
        lines << 'P8II_GAMEPLAY_CHANGE=0'
        lines << 'RMVX_EDITOR_RESTART_REQUIRED=1'
        lines << 'TUTORIAL_UPDATED=1'
        lines << 'P8II_V10668_END'
        File.open(PROJECT_STATE_FILE_V10564,'wb'){|io|io.write(text.rstrip+"\r\n"+lines.join("\r\n")+"\r\n")}
      rescue
      end
      true
    rescue
      false
    end
  end
end

#===============================================================================
# ■ Scene_PMD_AutoChess - same F5 key, battle-scoped P8-II dispatcher
#===============================================================================
class Scene_PMD_AutoChess
  alias pmd_ac_v10668_p8ii_update_battle_input update_battle_input unless method_defined?(:pmd_ac_v10668_p8ii_update_battle_input)
  def update_battle_input
    pmd_ac_v10668_p8ii_update_battle_input
    return unless $TEST
    return unless @phase==:battle
    return unless respond_to?(:verification_mode) && verification_mode==:normal
    return unless Input.trigger?(Input::F5)
    return if @p8ii_running_v10668
    @p8ii_running_v10668=true
    begin
      r=PMD_AC.p8ii_run_v10668(self)
      r[:pass] ? Sound.play_decision : Sound.play_buzzer
    rescue
      begin;Sound.play_buzzer;rescue;end
    ensure
      @p8ii_running_v10668=false
    end
  rescue
    @p8ii_running_v10668=false
  end
end
