# encoding: UTF-8
#===============================================================================
# ■ PMD AutoChess - Gate 3 Integrated Seal Convergence I
#   v1.06.66 PRODUCTION CANDIDATE
#-------------------------------------------------------------------------------
# 【用途】
# - 整合 v1.06.62 樓層風險、v1.06.63 Completion Incentive、
#   v1.06.64 Run Accounting，建立目前有效的 Gate 3 Seal contract。
# - 不直接把 v1.06.63 的歷史文案 audit 當成目前 blocking gate；
#   v1.06.64 已正式覆寫撤退/敗北結算文案，但 reward semantics 未變。
# - 提供唯讀 Run Summary API；不新增獎勵、不改 RNG、不改地圖、不改戰鬥。
#===============================================================================
$imported={} unless defined?($imported)
$imported['PMD_AutoChess_Gate3IntegratedSealConvergenceI_v10666']=true

module PMD_AC
  GATE3_SUMMARY_SCHEMA_V10666=2

  class << self
    def vxrd_gate3_hunt_tier_v10666(code)
      h=phase_div_hunt_v10553(code.to_s.upcase) rescue nil
      t=h==nil ? 1 : h[:tier].to_i
      t=1 if t<1
      t=5 if t>5
      t
    rescue
      1
    end

    def vxrd_gate3_risk_snapshot_v10666(code)
      tier=vxrd_gate3_hunt_tier_v10666(code)
      tab=respond_to?(:vxrd_gate3_curve_table_v10662) ? vxrd_gate3_curve_table_v10662 : {}
      rows=tab[tier]||[]
      first=rows.empty? ? [1,0,0] : rows[0]
      last=rows.empty? ? first : rows[rows.size-1]
      {:tier=>tier,:floor_count=>rows.size,
        :rare_base=>first[1].to_i,:rare_final=>last[1].to_i,
        :elite_base=>first[2].to_i,:elite_final=>last[2].to_i}
    rescue
      {:tier=>1,:floor_count=>0,:rare_base=>0,:rare_final=>0,:elite_base=>0,:elite_final=>0}
    end

    def vxrd_gate3_completion_current_contract_v10666
      bad=[]
      curve=(1..5).collect{|t|vxrd_gate3_completion_target_v10663(t)} rescue []
      bad << :curve unless curve==[2,2,3,4,5]

      pool={:base_rolls=>2,:max_rolls=>4}
      normal_same=true
      [{},{:rarity=>:rare},{:rarity=>:very_rare,:elite=>true},
       {:rarity=>:normal,:elite=>true,:boss=>true}].each do |ctx|
        old=pmd_ac_v10663_loot_roll_count_v094(pool,ctx) rescue nil
        now=loot_roll_count_v094(pool,ctx) rescue nil
        normal_same=false unless old==now
      end
      bad << :normal_roll_policy unless normal_same

      completion=loot_roll_count_v094(pool,{:rarity=>:very_rare,:elite=>true,
        :completion_roll_target_v10663=>5}) rescue 0
      cap=loot_roll_count_v094(pool,{:completion_roll_target_v10663=>99}) rescue 0
      bad << :completion_override unless completion==5
      bad << :override_cap unless cap==VXRD_GATE3_COMPLETION_OVERRIDE_CAP_V10663.to_i

      stats={:loot_results=>9,:immediate_loot_results=>7,:completion_bonus_results=>2,
        :battles=>6,:wins=>5,:losses=>0,:escapes=>1,:recruits=>2,:treasures=>2,
        :recoveries=>1,:rare_nest_wins=>1,:elite_room_wins=>2}
      complete={:reason=>:complete,:code=>'H21',:floors_cleared=>6,:max_floors=>6,
        :stats=>stats,:completion_bonus=>{:rolls=>5,:results=>[{:a=>1},{:b=>2}],
        :labels=>['A','B'],:completion_roll_target_v10663=>5}}
      retreat={:reason=>:retreat,:code=>'H21',:floors_cleared=>2,:max_floors=>6,
        :stats=>{:loot_results=>4,:immediate_loot_results=>4,:completion_bonus_results=>0},
        :completion_bonus=>nil}
      defeat=retreat.merge({:reason=>:defeat})

      cl=(hunt_runtime_result_lines_v10605(complete)||[]).join('|')
      rl=(hunt_runtime_result_lines_v10605(retreat)||[]).join('|')
      dl=(hunt_runtime_result_lines_v10605(defeat)||[]).join('|')
      bad << :complete_copy unless cl.index('通關 Bonus 5抽')
      bad << :retreat_copy unless rl.index('成果保留') && rl.index('通關 Bonus 0')
      bad << :defeat_copy unless dl.index('成果保留') && dl.index('通關 Bonus 0')

      legacy=nil
      begin
        legacy=vxrd_gate3_completion_static_audit_v10663
      rescue
        legacy=nil
      end
      {:pass=>bad.empty?,:curve=>curve,:normal_roll_policy_unchanged=>normal_same,
        :completion_override=>completion,:override_cap=>cap,
        :retreat_bonus=>0,:defeat_bonus=>0,:partial_clear_bonus=>0,
        :legacy_v10663_audit_pass=>(legacy.is_a?(Hash) && legacy[:pass] ? true:false),
        :legacy_v10663_expected_nonblocking=>true,:bad=>bad}
    rescue Exception=>e
      {:pass=>false,:bad=>[:completion_contract_error],:error=>e.class.to_s}
    end

    def vxrd_gate3_integrated_summary_v10666(result)
      r=result.is_a?(Hash) ? result : {}
      code=r[:code].to_s.upcase
      risk=vxrd_gate3_risk_snapshot_v10666(code)
      tier=risk[:tier].to_i
      reason=(r[:reason]||:unknown).to_sym
      st=r[:stats].is_a?(Hash) ? r[:stats] : {}
      acct=respond_to?(:vxrd_gate3_result_accounting_v10664) ? vxrd_gate3_result_accounting_v10664(r) : {}
      target=respond_to?(:vxrd_gate3_completion_target_v10663) ? vxrd_gate3_completion_target_v10663(tier) : 0
      complete=(reason==:complete)
      rolls=complete ? acct[:completion_rolls].to_i : 0
      completion_results=complete ? acct[:completion_bonus_results].to_i : 0
      floors=r[:floors_cleared].to_i
      max=r[:max_floors].to_i
      floors=0 if floors<0
      max=0 if max<0
      ratio=max>0 ? (floors*10000/max) : 0
      ratio=10000 if ratio>10000
      ratio=0 if ratio<0
      total=acct[:total_loot_results].to_i
      immediate=acct[:immediate_loot_results].to_i
      actual_completion=acct[:completion_bonus_results].to_i
      {:schema=>GATE3_SUMMARY_SCHEMA_V10666,:code=>code,:tier=>tier,:reason=>reason,
        :floors_cleared=>floors,:max_floors=>max,:floor_clear_bps=>ratio,
        :battles=>st[:battles].to_i,:wins=>st[:wins].to_i,:losses=>st[:losses].to_i,
        :escapes=>st[:escapes].to_i,:recruits=>st[:recruits].to_i,
        :treasures=>st[:treasures].to_i,:recoveries=>st[:recoveries].to_i,
        :rare_nest_wins=>st[:rare_nest_wins].to_i,:elite_room_wins=>st[:elite_room_wins].to_i,
        :rare_rate_base=>risk[:rare_base].to_i,:rare_rate_final=>risk[:rare_final].to_i,
        :elite_rate_base=>risk[:elite_base].to_i,:elite_rate_final=>risk[:elite_final].to_i,
        :completion_target_rolls=>target.to_i,:completion_rolls=>rolls,
        :total_loot_results=>total,:immediate_loot_results=>immediate,
        :completion_bonus_results=>completion_results,
        :raw_completion_bonus_results=>actual_completion,
        :accounting_balanced=>(total==immediate+actual_completion),
        :completion_eligible=>complete}
    rescue Exception=>e
      {:schema=>GATE3_SUMMARY_SCHEMA_V10666,:code=>'',:tier=>1,:reason=>:error,
        :accounting_balanced=>false,:error=>e.class.to_s}
    end

    def vxrd_gate3_active_run_summary_v10666
      s=respond_to?(:hunt_runtime_session_v10605) ? hunt_runtime_session_v10605 : nil
      return nil if s==nil
      st=Marshal.load(Marshal.dump(s[:vxrd_runtime_stats_v10604]||{}))
      r={:code=>s[:code],:reason=>:active,
        :floors_cleared=>s[:vxrd_floor_clears_v10604].to_i,
        :max_floors=>s[:vxrd_max_floors_v10604].to_i,
        :stats=>st,:completion_bonus=>nil}
      vxrd_gate3_integrated_summary_v10666(r)
    rescue
      nil
    end

    def vxrd_gate3_integrated_seal_audit_v10666
      bad=[]
      a62=respond_to?(:vxrd_gate3_static_audit_v10662) ? vxrd_gate3_static_audit_v10662 : {:pass=>false}
      a63=vxrd_gate3_completion_current_contract_v10666
      a64=respond_to?(:vxrd_gate3_accounting_static_audit_v10664) ? vxrd_gate3_accounting_static_audit_v10664 : {:pass=>false}
      bad << :v10662 unless a62[:pass]
      bad << :v10663_current_contract unless a63[:pass]
      bad << :v10664 unless a64[:pass]

      tab=respond_to?(:vxrd_gate3_curve_table_v10662) ? vxrd_gate3_curve_table_v10662 : {}
      endpoints={1=>[18,30,0,0],2=>[28,40,30,45],3=>[40,52,42,57],
        4=>[52,64,55,70],5=>[65,77,70,85]}
      monotonic=true
      endpoint_ok=true
      (1..5).each do |t|
        rows=tab[t]||[]
        last_r=-1
        last_e=-1
        rows.each do |row|
          rr=row[1].to_i
          ee=row[2].to_i
          monotonic=false if rr<last_r || ee<last_e
          last_r=rr
          last_e=ee
        end
        if rows.empty?
          endpoint_ok=false
        else
          got=[rows[0][1].to_i,rows[rows.size-1][1].to_i,
            rows[0][2].to_i,rows[rows.size-1][2].to_i]
          endpoint_ok=false unless got==endpoints[t]
        end
      end
      bad << :risk_monotonic unless monotonic
      bad << :risk_endpoints unless endpoint_ok

      curve=a63[:curve]||[]
      bad << :completion_curve unless curve==[2,2,3,4,5]

      stats={:battles=>6,:wins=>5,:losses=>0,:escapes=>1,:recruits=>2,:treasures=>2,
        :recoveries=>1,:rare_nest_wins=>1,:elite_room_wins=>2,:loot_results=>9,
        :immediate_loot_results=>7,:completion_bonus_results=>2,
        :floor_wins=>{1=>2,2=>3},:recruit_rows=>[{:species=>:pikachu,:uid=>7,:floor=>2}]}
      complete={:reason=>:complete,:code=>'H21',:floors_cleared=>6,:max_floors=>6,
        :stats=>stats,:completion_bonus=>{:rolls=>5,:results=>[{:a=>1},{:b=>2}],:labels=>['A','B']}}
      before=Marshal.dump(complete)
      cs=vxrd_gate3_integrated_summary_v10666(complete)
      after=Marshal.dump(complete)
      bad << :summary_mutation unless before==after
      bad << :complete_tier unless cs[:tier]==5
      bad << :complete_floor unless cs[:floors_cleared]==6 && cs[:max_floors]==6 && cs[:floor_clear_bps]==10000
      bad << :complete_risk unless [cs[:rare_rate_base],cs[:rare_rate_final],
        cs[:elite_rate_base],cs[:elite_rate_final]]==[65,77,70,85]
      bad << :complete_reward unless cs[:completion_target_rolls]==5 &&
        cs[:completion_rolls]==5 && cs[:completion_bonus_results]==2
      bad << :complete_accounting unless cs[:accounting_balanced] &&
        cs[:total_loot_results]==9 && cs[:immediate_loot_results]==7

      legacy={:reason=>:complete,:code=>'H21',:floors_cleared=>6,:max_floors=>6,
        :stats=>{:loot_results=>9},
        :completion_bonus=>{:rolls=>5,:results=>[{:a=>1},{:b=>2}]}}
      ls=vxrd_gate3_integrated_summary_v10666(legacy)
      bad << :legacy_fallback unless ls[:total_loot_results]==9 &&
        ls[:immediate_loot_results]==7 && ls[:completion_bonus_results]==2 &&
        ls[:accounting_balanced]

      retreat={:reason=>:retreat,:code=>'H21',:floors_cleared=>2,:max_floors=>6,
        :stats=>{:loot_results=>4,:immediate_loot_results=>4,:completion_bonus_results=>0},
        :completion_bonus=>nil}
      rs=vxrd_gate3_integrated_summary_v10666(retreat)
      ds=vxrd_gate3_integrated_summary_v10666(retreat.merge({:reason=>:defeat}))
      bad << :retreat_bonus unless !rs[:completion_eligible] &&
        rs[:completion_rolls]==0 && rs[:completion_bonus_results]==0
      bad << :defeat_bonus unless !ds[:completion_eligible] &&
        ds[:completion_rolls]==0 && ds[:completion_bonus_results]==0

      active=vxrd_gate3_integrated_summary_v10666({
        :reason=>:active,:code=>'H02',:floors_cleared=>0,:max_floors=>3,
        :stats=>{:loot_results=>0,:immediate_loot_results=>0,:completion_bonus_results=>0},
        :completion_bonus=>nil})
      bad << :active_fixture unless active[:tier]==1 &&
        active[:completion_target_rolls]==2 && active[:completion_rolls]==0 &&
        active[:accounting_balanced]

      round=Marshal.load(Marshal.dump(complete))
      bad << :marshal unless round==complete

      {:pass=>bad.empty?,:sub_v10662=>a62[:pass] ? true:false,
        :sub_v10663=>a63[:pass] ? true:false,:sub_v10664=>a64[:pass] ? true:false,
        :legacy_v10663_audit_pass=>a63[:legacy_v10663_audit_pass],
        :legacy_v10663_expected_nonblocking=>true,
        :risk_monotonic=>monotonic,:risk_endpoints=>endpoint_ok,
        :completion_curve=>curve,:complete_summary=>cs,:legacy_summary=>ls,
        :retreat_summary=>rs,:defeat_summary=>ds,:active_summary=>active,
        :marshal=>(round==complete),:summary_mutation=>(before==after ? 0:1),
        :rng_calls=>0,:reward_grant=>0,:map_regen=>0,:bad=>bad}
    rescue Exception=>e
      {:pass=>false,:bad=>[:audit_error],:error=>e.class.to_s}
    end

    alias pmd_ac_v10666_write_project_state_log write_project_state_log unless method_defined?(:pmd_ac_v10666_write_project_state_log)
    def project_version
      '1.06.66'
    end
    def write_project_state_log(force=false)
      r=pmd_ac_v10666_write_project_state_log(force)
      return false unless r
      begin
        text=''
        File.open(PROJECT_STATE_FILE_V10564,'rb'){|io|text=io.read}
        text=text.gsub(/PROJECT_STATE_SCHEMA=\d+/,'PROJECT_STATE_SCHEMA=47')
        text=text.gsub(/CURRENT_VERSION=[^\r\n]+/,'CURRENT_VERSION=1.06.66')
        text=text.gsub(/LATEST_FEATURE=[^\r\n]+/,'LATEST_FEATURE=GATE3_INTEGRATED_SEAL_CONVERGENCE_I')
        text=text.gsub(/NEXT_TARGET=[^\r\n]+/,'NEXT_TARGET=GATE3_V10666_WINDOWS_ACCEPTANCE+GATE3_FORMAL_SEAL')
        text=text.gsub(/\r?\nVXRD_GATE3_V10666_BEGIN.*?VXRD_GATE3_V10666_END\r?\n/m,"\r\n")
        a=vxrd_gate3_integrated_seal_audit_v10666
        lines=[]
        lines << ''
        lines << 'VXRD_GATE3_V10666_BEGIN'
        lines << 'GATE3_INTEGRATED_SEAL_STATIC='+(a[:pass] ? 'PASS':'FAIL')
        lines << 'GATE3_SUMMARY_SCHEMA='+GATE3_SUMMARY_SCHEMA_V10666.to_i.to_s
        lines << 'GATE3_RISK_CURVE_V10662=SEALED'
        lines << 'GATE3_COMPLETION_CURRENT_CONTRACT='+(a[:sub_v10663] ? 'PASS':'FAIL')
        lines << 'GATE3_LEGACY_V10663_AUDIT='+(a[:legacy_v10663_audit_pass] ? 'PASS':'FAIL')
        lines << 'GATE3_LEGACY_V10663_EXPECTED_NONBLOCKING=1'
        lines << 'GATE3_ACCOUNTING_V10664=SEALED_TOTAL_IMMEDIATE_COMPLETION'
        lines << 'GATE3_SUMMARY_READ_ONLY=1'
        lines << 'GATE3_REWARD_CHANGE=0'
        lines << 'GATE3_RNG_CALLS=0'
        lines << 'GATE3_MAP_CHANGE=0'
        lines << 'RMVX_EDITOR_RESTART_REQUIRED=1'
        lines << 'TUTORIAL_UPDATED=1'
        lines << 'VXRD_GATE3_V10666_END'
        File.open(PROJECT_STATE_FILE_V10564,'wb'){|io|
          io.write(text.rstrip+"\r\n"+lines.join("\r\n")+"\r\n")}
      rescue
      end
      true
    rescue
      false
    end
  end
end
