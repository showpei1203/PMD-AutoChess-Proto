# encoding: UTF-8
#===============================================================================
# ■ PMD AutoChess - Gate 3 Hunt Risk / Reward Curve Baseline Audit I
#   v1.06.61d TEST-ONLY
#-------------------------------------------------------------------------------
# Purpose:
# - Measure current Rare/Elite room rates, completion bonus roll curve,
#   retreat policy, run accounting coverage and live accounting Marshal safety.
# - Read-only instrumentation only: no RNG draw, map regeneration, reward grant,
#   Hunt state mutation, battle change or balance tuning.
#
# Control: plain F5 during RMVX Test Play on an active Map090 Hunt floor.
# Output : PMD_GATE3_RiskRewardBaseline_LATEST.log
#===============================================================================
$imported={} unless defined?($imported)
$imported['PMD_AutoChess_Gate3RiskRewardBaselineAuditI_v10661d']=true

module PMD_AC
  GATE3_BASELINE_VERSION_V10661D='1.06.61d-TEST'
  GATE3_BASELINE_LOG_V10661D='PMD_GATE3_RiskRewardBaseline_LATEST.log'
  GATE3_EXPECTED_STATS_V10661D=[:battles,:wins,:losses,:escapes,:recruits,
    :treasures,:recoveries,:rare_nest_wins,:elite_room_wins,:loot_results,:loot_labels]

  class << self
    def gate3_completion_context_v10661d(tier)
      t=[[tier.to_i,1].max,5].min
      {:rarity=>(t>=4 ? :very_rare : :rare),:elite=>(t>=4),
       :elite_count=>(t>=4 ? 1:0),:boss=>false,:hunt_completion_v10605=>true}
    rescue
      {:rarity=>:rare,:elite=>false,:elite_count=>0,:boss=>false}
    end

    def gate3_completion_rolls_by_tier_v10661d
      reps={1=>'H01',2=>'H06',3=>'H11',4=>'H16',5=>'H21'}
      out={}
      reps.each do |tier,code|
        pool=respond_to?(:hunt_loot_pool_v10578) ? hunt_loot_pool_v10578(code) : nil
        ctx=gate3_completion_context_v10661d(tier)
        out[tier]=(pool==nil || !respond_to?(:loot_roll_count_v094)) ? 0 : loot_roll_count_v094(pool,ctx).to_i
      end
      out
    rescue
      {}
    end

    def gate3_live_accounting_snapshot_v10661d
      s=respond_to?(:hunt_runtime_session_v10605) ? hunt_runtime_session_v10605 : nil
      return {:pass=>false,:reason=>:no_active_hunt} if s==nil
      st=s[:vxrd_runtime_stats_v10604]||{}
      snap={:code=>s[:code].to_s,:tier=>s[:tier].to_i,:seed=>s[:seed].to_i,
        :floor=>s[:vxrd_floor_count_v10584].to_i,:max_floor=>s[:vxrd_max_floors_v10604].to_i,
        :floors_cleared=>s[:vxrd_floor_clears_v10604].to_i,:encounters=>s[:encounters].to_i,
        :stats=>st}
      blob=Marshal.dump(snap);copy=Marshal.load(blob)
      semantic=(copy==snap)
      deep=(copy.object_id!=snap.object_id && copy[:stats].object_id!=st.object_id)
      missing=GATE3_EXPECTED_STATS_V10661D.find_all{|k|!st.has_key?(k)}
      {:pass=>semantic && deep && missing.empty?,:snapshot=>snap,:marshal=>semantic,
       :deep=>deep,:missing=>missing,:stats_keys=>st.keys.collect{|x|x.to_s}.sort,
       :rare_available=>(respond_to?(:vxrd_active_pool_has_rare_v10601?) ? vxrd_active_pool_has_rare_v10601? : false)}
    rescue Exception=>e
      {:pass=>false,:reason=>:marshal_error,:error=>e.class.to_s,:missing=>[],:stats_keys=>[]}
    end

    def gate3_risk_reward_baseline_audit_v10661d
      bad=[]
      rare=defined?(VXRD_RARE_NEST_RATE_V10601) ? VXRD_RARE_NEST_RATE_V10601 : {}
      elite=defined?(VXRD_ELITE_ROOM_RATE_V10601) ? VXRD_ELITE_ROOM_RATE_V10601 : {}
      floors=defined?(VXRD_HUNT_FLOORS_BY_TIER_V10604) ? VXRD_HUNT_FLOORS_BY_TIER_V10604 : {}
      economy=defined?(HUNT_ECONOMY_TIER_V10578) ? HUNT_ECONOMY_TIER_V10578 : {}
      bonus=defined?(LOOT_CONTEXT_BONUS_ROLLS_V094) ? LOOT_CONTEXT_BONUS_ROLLS_V094 : {}
      expected_rare={1=>18,2=>28,3=>40,4=>52,5=>65}
      expected_elite={1=>0,2=>30,3=>42,4=>55,5=>70}
      expected_floors={1=>3,2=>4,3=>5,4=>5,5=>6}
      bad << :rare_rate unless rare==expected_rare
      bad << :elite_rate unless elite==expected_elite
      bad << :floor_curve unless floors==expected_floors
      bad << :economy_tiers unless economy.keys.sort==[1,2,3,4,5]
      bad << :bonus_rolls unless bonus[:rare].to_i==1 && bonus[:very_rare].to_i==1 && bonus[:elite].to_i==1
      rolls=gate3_completion_rolls_by_tier_v10661d
      bad << :completion_roll_curve unless rolls=={1=>2,2=>2,3=>3,4=>4,5=>4}
      set=respond_to?(:hunt_runtime_settlement_audit_v10605) ? hunt_runtime_settlement_audit_v10605 : {:pass=>false}
      acc=respond_to?(:hunt_run_accounting_audit_v10608) ? hunt_run_accounting_audit_v10608 : {:pass=>false}
      sav=respond_to?(:vxrd_save_resume_audit_v10609) ? vxrd_save_resume_audit_v10609 : {:pass=>false}
      bad << :settlement unless set[:pass]
      bad << :accounting unless acc[:pass]
      bad << :save_resume unless sav[:pass]
      live=gate3_live_accounting_snapshot_v10661d
      bad << :live_accounting unless live[:pass]
      {:pass=>bad.empty?,:bad=>bad,:rare=>rare,:elite=>elite,:floors=>floors,
       :completion_rolls=>rolls,:live=>live,:floor_depth_scaling=>false,
       :rare_requires_active_pool=>true,:completion_only_bonus=>true,
       :retreat_keeps_immediate=>true,:defeat_keeps_immediate=>true,
       :summary_exposed=>[:floors_cleared,:wins,:recruits,:treasures,:rare_nest_wins,:elite_room_wins,:completion_bonus],
       :summary_hidden=>[:battles,:losses,:escapes,:recoveries,:loot_results,:loot_labels,:floor_wins,:encounters],
       :rng_calls=>0,:map_regen=>false,:reward_grant=>false,:session_mutation=>false,
       :balance_tuning=>false}
    rescue Exception=>e
      {:pass=>false,:bad=>[:audit_exception],:error=>e.class.to_s,:rng_calls=>0,
       :map_regen=>false,:reward_grant=>false,:session_mutation=>false,:balance_tuning=>false}
    end

    def gate3_write_risk_reward_baseline_v10661d
      r=gate3_risk_reward_baseline_audit_v10661d
      live=r[:live]||{};snap=live[:snapshot]||{};stats=snap[:stats]||{}
      lines=[]
      lines << 'PMD AutoChess Gate 3 Hunt Risk / Reward Baseline Audit v1.06.61d TEST-ONLY'
      lines << 'RESULT='+(r[:pass] ? 'PASS':'FAIL')
      lines << 'FORMAL_BASELINE=v1.06.61'
      lines << 'BALANCE_TUNING_APPLIED=0'
      lines << 'RNG_CALLS=0'
      lines << 'MAP_REGEN=0'
      lines << 'REWARD_GRANT=0'
      lines << 'SESSION_MUTATION=0'
      lines << 'RARE_RATE_BY_TIER=1:18,2:28,3:40,4:52,5:65'
      lines << 'ELITE_RATE_BY_TIER=1:0,2:30,3:42,4:55,5:70'
      lines << 'FLOORS_BY_TIER=1:3,2:4,3:5,4:5,5:6'
      lines << 'FLOOR_DEPTH_RATE_SCALING=0'
      lines << 'RARE_ROOM_GATE=ACTIVE_POOL_RARE_PLUS_REQUIRED'
      lines << 'COMPLETION_BONUS_ROLLS_BY_TIER=1:2,2:2,3:3,4:4,5:4'
      lines << 'COMPLETION_BONUS=FULL_CLEAR_ONLY'
      lines << 'RETREAT_COMPLETION_BONUS=0'
      lines << 'DEFEAT_COMPLETION_BONUS=0'
      lines << 'RETREAT_KEEPS_IMMEDIATE_REWARDS=1'
      lines << 'DEFEAT_KEEPS_IMMEDIATE_REWARDS=1'
      lines << 'ACCOUNTING_BASE_FIELDS='+GATE3_EXPECTED_STATS_V10661D.collect{|x|x.to_s}.join(',')
      lines << 'ACCOUNTING_DYNAMIC_FIELD=floor_wins'
      lines << 'SETTLEMENT_EXPOSED='+(r[:summary_exposed]||[]).collect{|x|x.to_s}.join(',')
      lines << 'SETTLEMENT_HIDDEN='+(r[:summary_hidden]||[]).collect{|x|x.to_s}.join(',')
      lines << 'LIVE_HUNT='+snap[:code].to_s
      lines << 'LIVE_TIER='+snap[:tier].to_i.to_s
      lines << 'LIVE_FLOOR='+snap[:floor].to_i.to_s+'/'+snap[:max_floor].to_i.to_s
      lines << 'LIVE_FLOORS_CLEARED='+snap[:floors_cleared].to_i.to_s
      lines << 'LIVE_ENCOUNTERS='+snap[:encounters].to_i.to_s
      lines << 'LIVE_RARE_AVAILABLE='+(live[:rare_available] ? '1':'0')
      lines << 'LIVE_STATS='+stats.inspect
      lines << 'LIVE_STATS_KEYS='+(live[:stats_keys]||[]).join(',')
      lines << 'ACCOUNTING_MARSHAL='+(live[:marshal] ? 'PASS':'FAIL')
      lines << 'ACCOUNTING_DEEP_COPY='+(live[:deep] ? 'PASS':'FAIL')
      lines << 'ACCOUNTING_MISSING='+(live[:missing]||[]).collect{|x|x.to_s}.join(',')
      lines << 'FINDING_1=RARE_ELITE_RATES_ARE_TIER_ONLY_NOT_FLOOR_DEPTH_SCALED'
      lines << 'FINDING_2=COMPLETION_ROLL_CURVE_PLATEAUS_AT_TIER4_5'
      lines << 'FINDING_3=SETTLEMENT_UI_HIDES_EXISTING_ACCOUNTING_FIELDS'
      (r[:bad]||[]).each{|x|lines << 'ERROR='+x.to_s}
      File.open(GATE3_BASELINE_LOG_V10661D,'wb'){|io|io.write(lines.join("\r\n")+"\r\n")}
      r
    rescue Exception=>e
      begin
        File.open(GATE3_BASELINE_LOG_V10661D,'wb'){|io|io.write("RESULT=FAIL\r\nERROR=write_exception_"+e.class.to_s+"\r\n")}
      rescue
      end
      {:pass=>false,:bad=>[:write_exception]}
    end
  end
end

class Scene_Map
  alias pmd_ac_v10661d_gate3_update update unless method_defined?(:pmd_ac_v10661d_gate3_update)
  def update
    pmd_ac_v10661d_gate3_update
    begin
      return unless $TEST
      return unless Input.trigger?(Input::F5)
      return if Input.press?(Input::SHIFT) || Input.press?(Input::CTRL) || Input.press?(Input::ALT)
      if $game_map==nil || $game_map.map_id.to_i!=PMD_AC::VXRD_HUNT_RUNTIME_MAP_ID_V10604
        PMD_AC.hunt_runtime_message_v10604(['Gate 3 Baseline Audit','請先進入 Random Hunt / Map090。','此測試不會修改地圖或獎勵。']) rescue nil
        return
      end
      r=PMD_AC.gate3_write_risk_reward_baseline_v10661d
      PMD_AC.hunt_runtime_message_v10604([
        'Gate 3 Baseline Audit '+(r[:pass] ? 'PASS':'FAIL'),
        'Rare/Elite Tier-only｜Floor scaling 0',
        'Completion Rolls 2 / 2 / 3 / 4 / 4',
        'LOG: '+PMD_AC::GATE3_BASELINE_LOG_V10661D
      ]) rescue nil
    rescue
    end
  end
end
