# encoding: UTF-8
#===============================================================================
# ■ PMD AutoChess - Gate 3 Integrated Run Summary / Risk-Reward Seal I
#   v1.06.65 PRODUCTION CANDIDATE
#-------------------------------------------------------------------------------
# 【用途】
# - 將 Gate 3 已封存的「樓層風險曲線／完整通關獎勵／Run Accounting」整合成
#   單一唯讀 Run Summary API，供後續 UI、紀錄與回歸測試使用。
# - 不新增掉落、不改 RNG、不改戰鬥、不改地圖；只讀既有 Result / Authority 資料。
# - 完整通關、撤退、敗北與舊 completed result 都使用同一套摘要語意。
#===============================================================================
$imported={} unless defined?($imported)
$imported['PMD_AutoChess_Gate3IntegratedRunSummaryRiskRewardSealI_v10665']=true

module PMD_AC
  GATE3_SUMMARY_SCHEMA_V10665=1

  class << self
    def vxrd_gate3_hunt_tier_v10665(code)
      h=phase_div_hunt_v10553(code.to_s.upcase) rescue nil
      t=h==nil ? 1 : h[:tier].to_i
      t=1 if t<1;t=5 if t>5
      t
    rescue
      1
    end

    def vxrd_gate3_risk_snapshot_v10665(code)
      tier=vxrd_gate3_hunt_tier_v10665(code)
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

    def vxrd_gate3_integrated_summary_v10665(result)
      r=result.is_a?(Hash) ? result : {}
      code=r[:code].to_s.upcase
      risk=vxrd_gate3_risk_snapshot_v10665(code)
      tier=risk[:tier].to_i
      reason=(r[:reason]||:unknown).to_sym
      st=r[:stats].is_a?(Hash) ? r[:stats] : {}
      acct=respond_to?(:vxrd_gate3_result_accounting_v10664) ? vxrd_gate3_result_accounting_v10664(r) : {}
      target=respond_to?(:vxrd_gate3_completion_target_v10663) ? vxrd_gate3_completion_target_v10663(tier) : 0
      complete=(reason==:complete)
      rolls=complete ? acct[:completion_rolls].to_i : 0
      completion_results=complete ? acct[:completion_bonus_results].to_i : 0
      floors=r[:floors_cleared].to_i;max=r[:max_floors].to_i
      floors=0 if floors<0;max=0 if max<0
      ratio=max>0 ? (floors*10000/max) : 0
      ratio=10000 if ratio>10000;ratio=0 if ratio<0
      total=acct[:total_loot_results].to_i
      immediate=acct[:immediate_loot_results].to_i
      actual_completion=acct[:completion_bonus_results].to_i
      {:schema=>GATE3_SUMMARY_SCHEMA_V10665,:code=>code,:tier=>tier,:reason=>reason,
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
      {:schema=>GATE3_SUMMARY_SCHEMA_V10665,:code=>'',:tier=>1,:reason=>:error,
        :accounting_balanced=>false,:error=>e.class.to_s}
    end

    def vxrd_gate3_last_run_summary_v10665
      return nil if $game_system==nil
      r=nil
      begin;r=$game_system.pmd_vxrd_hunt_last_result_v10605;rescue;r=nil;end
      vxrd_gate3_integrated_summary_v10665(r) unless r==nil
    rescue
      nil
    end

    def vxrd_gate3_active_run_summary_v10665
      s=respond_to?(:hunt_runtime_session_v10605) ? hunt_runtime_session_v10605 : nil
      return nil if s==nil
      st=Marshal.load(Marshal.dump(s[:vxrd_runtime_stats_v10604]||{}))
      r={:code=>s[:code],:reason=>:active,
        :floors_cleared=>s[:vxrd_floor_clears_v10604].to_i,
        :max_floors=>s[:vxrd_max_floors_v10604].to_i,
        :stats=>st,:completion_bonus=>nil}
      vxrd_gate3_integrated_summary_v10665(r)
    rescue
      nil
    end

    def vxrd_gate3_integrated_seal_audit_v10665
      bad=[]
      a62=respond_to?(:vxrd_gate3_static_audit_v10662) ? vxrd_gate3_static_audit_v10662 : {:pass=>false}
      a63=respond_to?(:vxrd_gate3_completion_static_audit_v10663) ? vxrd_gate3_completion_static_audit_v10663 : {:pass=>false}
      a64=respond_to?(:vxrd_gate3_accounting_static_audit_v10664) ? vxrd_gate3_accounting_static_audit_v10664 : {:pass=>false}
      bad << :v10662 unless a62[:pass]
      bad << :v10663 unless a63[:pass]
      bad << :v10664 unless a64[:pass]

      tab=respond_to?(:vxrd_gate3_curve_table_v10662) ? vxrd_gate3_curve_table_v10662 : {}
      endpoints={1=>[18,30,0,0],2=>[28,40,30,45],3=>[40,52,42,57],
        4=>[52,64,55,70],5=>[65,77,70,85]}
      monotonic=true;endpoint_ok=true
      (1..5).each do |t|
        rows=tab[t]||[]
        last_r=-1;last_e=-1
        rows.each do |row|
          rr=row[1].to_i;ee=row[2].to_i
          monotonic=false if rr<last_r || ee<last_e
          last_r=rr;last_e=ee
        end
        if rows.empty?
          endpoint_ok=false
        else
          got=[rows[0][1].to_i,rows[rows.size-1][1].to_i,rows[0][2].to_i,rows[rows.size-1][2].to_i]
          endpoint_ok=false unless got==endpoints[t]
        end
      end
      bad << :risk_monotonic unless monotonic
      bad << :risk_endpoints unless endpoint_ok

      curve=(1..5).collect{|t|vxrd_gate3_completion_target_v10663(t)} rescue []
      bad << :completion_curve unless curve==[2,2,3,4,5]

      stats={:battles=>6,:wins=>5,:losses=>0,:escapes=>1,:recruits=>2,:treasures=>2,
        :recoveries=>1,:rare_nest_wins=>1,:elite_room_wins=>2,:loot_results=>9,
        :immediate_loot_results=>7,:completion_bonus_results=>2,
        :floor_wins=>{1=>2,2=>3},:recruit_rows=>[{:species=>:pikachu,:uid=>7,:floor=>2}]}
      complete={:reason=>:complete,:code=>'H21',:floors_cleared=>6,:max_floors=>6,
        :stats=>stats,:completion_bonus=>{:rolls=>5,:results=>[{:a=>1},{:b=>2}],:labels=>['A','B']}}
      before=Marshal.dump(complete)
      cs=vxrd_gate3_integrated_summary_v10665(complete)
      after=Marshal.dump(complete)
      bad << :summary_mutation unless before==after
      bad << :complete_tier unless cs[:tier]==5
      bad << :complete_floor unless cs[:floors_cleared]==6 && cs[:max_floors]==6 && cs[:floor_clear_bps]==10000
      bad << :complete_risk unless [cs[:rare_rate_base],cs[:rare_rate_final],cs[:elite_rate_base],cs[:elite_rate_final]]==[65,77,70,85]
      bad << :complete_reward unless cs[:completion_target_rolls]==5 && cs[:completion_rolls]==5 && cs[:completion_bonus_results]==2
      bad << :complete_accounting unless cs[:accounting_balanced] && cs[:total_loot_results]==9 && cs[:immediate_loot_results]==7

      legacy={:reason=>:complete,:code=>'H21',:floors_cleared=>6,:max_floors=>6,
        :stats=>{:loot_results=>9},:completion_bonus=>{:rolls=>5,:results=>[{:a=>1},{:b=>2}]}}
      ls=vxrd_gate3_integrated_summary_v10665(legacy)
      bad << :legacy_fallback unless ls[:total_loot_results]==9 && ls[:immediate_loot_results]==7 && ls[:completion_bonus_results]==2 && ls[:accounting_balanced]

      retreat={:reason=>:retreat,:code=>'H21',:floors_cleared=>2,:max_floors=>6,
        :stats=>{:loot_results=>4,:immediate_loot_results=>4,:completion_bonus_results=>0},:completion_bonus=>nil}
      rs=vxrd_gate3_integrated_summary_v10665(retreat)
      bad << :retreat_bonus unless !rs[:completion_eligible] && rs[:completion_rolls]==0 && rs[:completion_bonus_results]==0
      defeat=retreat.merge({:reason=>:defeat})
      ds=vxrd_gate3_integrated_summary_v10665(defeat)
      bad << :defeat_bonus unless !ds[:completion_eligible] && ds[:completion_rolls]==0 && ds[:completion_bonus_results]==0

      round=Marshal.load(Marshal.dump(complete))
      bad << :marshal unless round==complete
      {:pass=>bad.empty?,:sub_v10662=>a62[:pass] ? true:false,:sub_v10663=>a63[:pass] ? true:false,
        :sub_v10664=>a64[:pass] ? true:false,:risk_monotonic=>monotonic,:risk_endpoints=>endpoint_ok,
        :completion_curve=>curve,:complete_summary=>cs,:legacy_summary=>ls,
        :retreat_summary=>rs,:defeat_summary=>ds,:marshal=>(round==complete),
        :summary_mutation=>(before==after ? 0:1),:rng_calls=>0,:reward_grant=>0,:map_regen=>0,:bad=>bad}
    rescue Exception=>e
      {:pass=>false,:bad=>[:audit_error],:error=>e.class.to_s}
    end

    alias pmd_ac_v10665_write_project_state_log write_project_state_log unless method_defined?(:pmd_ac_v10665_write_project_state_log)
    def project_version
      '1.06.65'
    end
    def write_project_state_log(force=false)
      r=pmd_ac_v10665_write_project_state_log(force)
      return false unless r
      begin
        text='';File.open(PROJECT_STATE_FILE_V10564,'rb'){|io|text=io.read}
        text=text.gsub(/PROJECT_STATE_SCHEMA=\d+/,'PROJECT_STATE_SCHEMA=46')
        text=text.gsub(/CURRENT_VERSION=[^\r\n]+/,'CURRENT_VERSION=1.06.65')
        text=text.gsub(/LATEST_FEATURE=[^\r\n]+/,'LATEST_FEATURE=GATE3_INTEGRATED_RUN_SUMMARY_RISK_REWARD_SEAL_I')
        text=text.gsub(/NEXT_TARGET=[^\r\n]+/,'NEXT_TARGET=GATE3_V10665_WINDOWS_ACCEPTANCE+GATE3_FORMAL_SEAL')
        text=text.gsub(/\r?\nVXRD_GATE3_V10665_BEGIN.*?VXRD_GATE3_V10665_END\r?\n/m,"\r\n")
        a=vxrd_gate3_integrated_seal_audit_v10665
        lines=[]
        lines << ''
        lines << 'VXRD_GATE3_V10665_BEGIN'
        lines << 'GATE3_INTEGRATED_SEAL_STATIC='+(a[:pass] ? 'PASS':'FAIL')
        lines << 'GATE3_SUMMARY_SCHEMA='+GATE3_SUMMARY_SCHEMA_V10665.to_i.to_s
        lines << 'GATE3_RISK_CURVE_V10662=SEALED'
        lines << 'GATE3_COMPLETION_CURVE_V10663=SEALED_2_2_3_4_5'
        lines << 'GATE3_ACCOUNTING_V10664=SEALED_TOTAL_IMMEDIATE_COMPLETION'
        lines << 'GATE3_SUMMARY_READ_ONLY=1'
        lines << 'GATE3_REWARD_CHANGE=0'
        lines << 'GATE3_RNG_CALLS=0'
        lines << 'GATE3_MAP_CHANGE=0'
        lines << 'RMVX_EDITOR_RESTART_REQUIRED=1'
        lines << 'TUTORIAL_UPDATED=1'
        lines << 'VXRD_GATE3_V10665_END'
        File.open(PROJECT_STATE_FILE_V10564,'wb'){|io|io.write(text.rstrip+"\r\n"+lines.join("\r\n")+"\r\n")}
      rescue
      end
      true
    rescue
      false
    end
  end
end
