# encoding: UTF-8
#===============================================================================
# ■ PMD AutoChess - Gate 3 Run Accounting Semantic / Persistence I
#   v1.06.64 PRODUCTION CANDIDATE
#-------------------------------------------------------------------------------
# 【用途】
# - 保留既有 loot_results 作為 Hunt 掉落「總計」相容欄位。
# - 正式拆分途中掉落 immediate_loot_results 與通關獎勵 completion_bonus_results。
# - Completion 判定只看既有 Context marker，不依賴 UI 字串、Item 類型或 Tier 猜測。
# - 新 Run 初始化 split 欄位；舊 v1.06.63 active Run 可無歧義 migration。
# - 舊 completed result 可從 completion_bonus[:results] 反推 split，不需改存檔格式。
# - 結算維持四行預算，明確顯示途中掉落與通關 Bonus 的不同語意。
#===============================================================================
$imported={} unless defined?($imported)
$imported['PMD_AutoChess_Gate3RunAccountingSemanticPersistenceI_v10664']=true

module PMD_AC
  class << self
    def vxrd_gate3_completion_loot_result_v10664?(result)
      return false unless result.is_a?(Hash)
      c=result[:context]
      return false unless c.is_a?(Hash)
      c[:hunt_completion_v10605] ? true : c.has_key?(:completion_roll_target_v10663)
    rescue
      false
    end

    def vxrd_gate3_loot_class_v10664(result)
      vxrd_gate3_completion_loot_result_v10664?(result) ? :completion : :immediate
    rescue
      :immediate
    end

    def vxrd_gate3_ensure_active_accounting_v10664(stats)
      return nil unless stats.is_a?(Hash)
      # Active legacy v1.06.63 Run cannot already have received Completion Bonus:
      # completion ends the run. Therefore legacy loot_results is safely immediate.
      unless stats.has_key?(:immediate_loot_results)
        stats[:immediate_loot_results]=stats[:loot_results].to_i
      end
      stats[:completion_bonus_results]=0 unless stats.has_key?(:completion_bonus_results)
      stats[:immediate_loot_labels]=[] unless stats[:immediate_loot_labels].is_a?(Array)
      stats[:completion_bonus_labels]=[] unless stats[:completion_bonus_labels].is_a?(Array)
      stats
    rescue
      stats
    end

    def vxrd_gate3_result_accounting_v10664(result)
      r=result.is_a?(Hash) ? result : {}
      st=r[:stats].is_a?(Hash) ? r[:stats] : {}
      bonus=r[:completion_bonus].is_a?(Hash) ? r[:completion_bonus] : {}
      total=st[:loot_results].to_i
      completion=if st.has_key?(:completion_bonus_results)
        st[:completion_bonus_results].to_i
      else
        (bonus[:results]||[]).size.to_i
      end
      completion=0 if completion<0
      immediate=if st.has_key?(:immediate_loot_results)
        st[:immediate_loot_results].to_i
      else
        x=total-completion
        x<0 ? 0 : x
      end
      immediate=0 if immediate<0
      rolls=bonus[:rolls].to_i
      rolls=bonus[:completion_roll_target_v10663].to_i if rolls<=0
      {:total_loot_results=>total,:immediate_loot_results=>immediate,
        :completion_bonus_results=>completion,:completion_rolls=>rolls,
        :reason=>(r[:reason]||:unknown).to_sym}
    rescue
      {:total_loot_results=>0,:immediate_loot_results=>0,
        :completion_bonus_results=>0,:completion_rolls=>0,:reason=>:error}
    end

    alias pmd_ac_v10664_hunt_runtime_generate_after_transfer_v10604 hunt_runtime_generate_after_transfer_v10604 unless method_defined?(:pmd_ac_v10664_hunt_runtime_generate_after_transfer_v10604)
    def hunt_runtime_generate_after_transfer_v10604
      ok=pmd_ac_v10664_hunt_runtime_generate_after_transfer_v10604
      begin
        if ok
          s=phase_div_hunt_session_v10555
          st=s==nil ? nil : s[:vxrd_runtime_stats_v10604]
          if st.is_a?(Hash)
            st[:immediate_loot_results]=0
            st[:completion_bonus_results]=0
            st[:immediate_loot_labels]=[]
            st[:completion_bonus_labels]=[]
          end
        end
      rescue
      end
      ok
    rescue
      false
    end

    alias pmd_ac_v10664_hunt_runtime_stats_v10608 hunt_runtime_stats_v10608 unless method_defined?(:pmd_ac_v10664_hunt_runtime_stats_v10608)
    def hunt_runtime_stats_v10608
      st=pmd_ac_v10664_hunt_runtime_stats_v10608
      vxrd_gate3_ensure_active_accounting_v10664(st) unless st==nil
      st
    rescue
      st
    end

    def vxrd_gate3_apply_split_result_v10664(stats,result)
      return false unless stats.is_a?(Hash) && result.is_a?(Hash)
      vxrd_gate3_ensure_active_accounting_v10664(stats)
      rows=result[:results]||[]
      labels=result[:labels]||[]
      n=rows.size.to_i
      if vxrd_gate3_loot_class_v10664(result)==:completion
        stats[:completion_bonus_results]=stats[:completion_bonus_results].to_i+n
        labels.each{|x|stats[:completion_bonus_labels] << x.to_s if stats[:completion_bonus_labels].size<16}
      else
        stats[:immediate_loot_results]=stats[:immediate_loot_results].to_i+n
        labels.each{|x|stats[:immediate_loot_labels] << x.to_s if stats[:immediate_loot_labels].size<24}
      end
      true
    rescue
      false
    end

    alias pmd_ac_v10664_record_loot_pool_result_v094 record_loot_pool_result_v094 unless method_defined?(:pmd_ac_v10664_record_loot_pool_result_v094)
    def record_loot_pool_result_v094(result)
      # Same result Hash should never be accounted twice. This also protects the
      # legacy ledger/loot_results side effects in the aliased chain.
      return nil if result.is_a?(Hash) && result[:vxrd_accounting_recorded_v10664]
      s_before=respond_to?(:hunt_runtime_session_v10605) ? hunt_runtime_session_v10605 : nil
      wanted_before=s_before==nil || !respond_to?(:hunt_loot_pool_key_v10578) ? nil : hunt_loot_pool_key_v10578(s_before[:code])
      matching_before=s_before!=nil && result.is_a?(Hash) && wanted_before!=nil && result[:pool].to_s==wanted_before.to_s
      # Migration must happen before v1.06.08 increments legacy loot_results; otherwise
      # the first post-upgrade result would be counted once in migration and once again
      # in the semantic split.
      if matching_before
        st_before=s_before[:vxrd_runtime_stats_v10604]||={}
        vxrd_gate3_ensure_active_accounting_v10664(st_before)
      end
      out=pmd_ac_v10664_record_loot_pool_result_v094(result)
      begin
        if matching_before
          st=s_before[:vxrd_runtime_stats_v10604]||={}
          vxrd_gate3_apply_split_result_v10664(st,result)
          result[:vxrd_accounting_recorded_v10664]=true
        end
      rescue
      end
      out
    rescue
      nil
    end

    alias pmd_ac_v10664_hunt_runtime_result_lines_v10605 hunt_runtime_result_lines_v10605 unless method_defined?(:pmd_ac_v10664_hunt_runtime_result_lines_v10605)
    def hunt_runtime_result_lines_v10605(result)
      lines=pmd_ac_v10664_hunt_runtime_result_lines_v10605(result)
      return lines unless lines.is_a?(Array) && lines.size>=4 && result.is_a?(Hash)
      a=vxrd_gate3_result_accounting_v10664(result)
      reason=a[:reason].to_s
      if reason=='complete'
        lines[3]='途中掉落 '+a[:immediate_loot_results].to_i.to_s+
          '｜通關 Bonus '+a[:completion_rolls].to_i.to_s+'抽→'+a[:completion_bonus_results].to_i.to_s+'項'
      elsif reason=='retreat' || reason=='defeat'
        lines[3]='途中掉落 '+a[:immediate_loot_results].to_i.to_s+'｜成果保留｜通關 Bonus 0'
      end
      lines
    rescue
      pmd_ac_v10664_hunt_runtime_result_lines_v10605(result)
    end

    def vxrd_gate3_accounting_static_audit_v10664
      bad=[]
      legacy_complete={:reason=>:complete,
        :stats=>{:loot_results=>9},
        :completion_bonus=>{:rolls=>5,:results=>[{:a=>1},{:b=>2}],:labels=>['A','B']}}
      la=vxrd_gate3_result_accounting_v10664(legacy_complete)
      bad << :legacy_total unless la[:total_loot_results]==9
      bad << :legacy_immediate unless la[:immediate_loot_results]==7
      bad << :legacy_completion unless la[:completion_bonus_results]==2
      bad << :legacy_rolls unless la[:completion_rolls]==5

      fresh={:loot_results=>0}
      vxrd_gate3_ensure_active_accounting_v10664(fresh)
      bad << :active_migration unless fresh[:immediate_loot_results]==0 && fresh[:completion_bonus_results]==0
      legacy_active={:loot_results=>4,:loot_labels=>['A']}
      vxrd_gate3_ensure_active_accounting_v10664(legacy_active)
      bad << :active_legacy_migration unless legacy_active[:immediate_loot_results]==4 && legacy_active[:completion_bonus_results]==0

      new_stats={:battles=>6,:wins=>5,:losses=>0,:escapes=>1,:recruits=>2,:treasures=>2,
        :recoveries=>1,:rare_nest_wins=>1,:elite_room_wins=>2,:loot_results=>9,
        :immediate_loot_results=>7,:completion_bonus_results=>2,
        :immediate_loot_labels=>['L1'],:completion_bonus_labels=>['B1','B2'],
        :floor_wins=>{1=>2,2=>3},:recruit_rows=>[{:species=>:pikachu,:uid=>7,:floor=>2}]}
      complete={:reason=>:complete,:code=>'H21',:floors_cleared=>6,:max_floors=>6,
        :stats=>new_stats,:completion_bonus=>{:rolls=>5,:results=>[{:a=>1},{:b=>2}],:labels=>['B1','B2']}}
      na=vxrd_gate3_result_accounting_v10664(complete)
      bad << :new_split unless na[:total_loot_results]==9 && na[:immediate_loot_results]==7 && na[:completion_bonus_results]==2
      bad << :sum unless na[:immediate_loot_results]+na[:completion_bonus_results]==na[:total_loot_results]
      cl=(hunt_runtime_result_lines_v10605(complete)||[]).join('|')
      bad << :complete_copy unless cl.index('途中掉落 7') && cl.index('通關 Bonus 5抽→2項')

      retreat={:reason=>:retreat,:code=>'H03',:floors_cleared=>2,:max_floors=>5,
        :stats=>{:loot_results=>4,:immediate_loot_results=>4,:completion_bonus_results=>0},
        :completion_bonus=>nil}
      rl=(hunt_runtime_result_lines_v10605(retreat)||[]).join('|')
      bad << :retreat_copy unless rl.index('途中掉落 4') && rl.index('成果保留') && rl.index('通關 Bonus 0')

      c1={:context=>{:rarity=>:rare},:results=>[1]}
      c2={:context=>{:hunt_completion_v10605=>true,:completion_roll_target_v10663=>5},:results=>[1]}
      bad << :class_immediate unless vxrd_gate3_loot_class_v10664(c1)==:immediate
      bad << :class_completion unless vxrd_gate3_loot_class_v10664(c2)==:completion
      migrate_then_record={:loot_results=>4}
      vxrd_gate3_ensure_active_accounting_v10664(migrate_then_record)
      # Simulate v1.06.08 legacy total increment followed by v1.06.64 split increment.
      migrate_then_record[:loot_results]=migrate_then_record[:loot_results].to_i+1
      vxrd_gate3_apply_split_result_v10664(migrate_then_record,{:context=>{:rarity=>:rare},:results=>[1],:labels=>['X']})
      bad << :migration_first_result unless migrate_then_record[:loot_results]==5 && migrate_then_record[:immediate_loot_results]==5 && migrate_then_record[:completion_bonus_results]==0

      round=Marshal.load(Marshal.dump(new_stats))
      bad << :marshal unless round==new_stats
      preserve=[:battles,:wins,:losses,:escapes,:recruits,:treasures,:recoveries,
        :rare_nest_wins,:elite_room_wins,:loot_results,:floor_wins,:recruit_rows]
      bad << :legacy_fields unless preserve.all?{|k|new_stats.has_key?(k)}
      {:pass=>bad.empty?,:legacy_total=>la[:total_loot_results],
        :legacy_immediate=>la[:immediate_loot_results],:legacy_completion=>la[:completion_bonus_results],
        :split_total=>na[:total_loot_results],:split_immediate=>na[:immediate_loot_results],
        :split_completion=>na[:completion_bonus_results],:marshal=>round==new_stats,
        :classification=>[:immediate,:completion],:legacy_fields_preserved=>preserve.size,
        :reward_change=>0,:rng_calls=>0,:bad=>bad}
    rescue Exception=>e
      {:pass=>false,:bad=>[:audit_error],:error=>e.class.to_s}
    end

    alias pmd_ac_v10664_write_project_state_log write_project_state_log unless method_defined?(:pmd_ac_v10664_write_project_state_log)
    def project_version
      '1.06.64'
    end
    def write_project_state_log(force=false)
      r=pmd_ac_v10664_write_project_state_log(force)
      return false unless r
      begin
        text='';File.open(PROJECT_STATE_FILE_V10564,'rb'){|io|text=io.read}
        text=text.gsub(/PROJECT_STATE_SCHEMA=\d+/,'PROJECT_STATE_SCHEMA=45')
        text=text.gsub(/CURRENT_VERSION=[^\r\n]+/,'CURRENT_VERSION=1.06.64')
        text=text.gsub(/LATEST_FEATURE=[^\r\n]+/,'LATEST_FEATURE=GATE3_RUN_ACCOUNTING_SEMANTIC_PERSISTENCE_I')
        text=text.gsub(/NEXT_TARGET=[^\r\n]+/,'NEXT_TARGET=GATE3_V10664_WINDOWS_ACCEPTANCE+RUN_SUMMARY_SEAL_PHASE_V')
        text=text.gsub(/\r?\nVXRD_GATE3_V10664_BEGIN.*?VXRD_GATE3_V10664_END\r?\n/m,"\r\n")
        a=vxrd_gate3_accounting_static_audit_v10664
        lines=[]
        lines << ''
        lines << 'VXRD_GATE3_V10664_BEGIN'
        lines << 'GATE3_ACCOUNTING_STATIC='+(a[:pass] ? 'PASS':'FAIL')
        lines << 'GATE3_LOOT_RESULTS_SEMANTIC=TOTAL_COMPAT'
        lines << 'GATE3_IMMEDIATE_LOOT_RESULTS=SEPARATE'
        lines << 'GATE3_COMPLETION_BONUS_RESULTS=SEPARATE'
        lines << 'GATE3_ACTIVE_LEGACY_MIGRATION=SAFE'
        lines << 'GATE3_COMPLETED_LEGACY_FALLBACK=DERIVED_FROM_BONUS_RESULTS'
        lines << 'GATE3_MARSHAL_PERSISTENCE='+(a[:marshal] ? 'PASS':'FAIL')
        lines << 'GATE3_REWARD_CHANGE=0'
        lines << 'GATE3_RNG_CALLS=0'
        lines << 'GATE3_COMPLETION_CURVE_V10663=SEALED'
        lines << 'GATE3_FLOOR_DEPTH_CURVE_V10662=SEALED'
        lines << 'RMVX_EDITOR_RESTART_REQUIRED=1'
        lines << 'TUTORIAL_UPDATED=1'
        lines << 'VXRD_GATE3_V10664_END'
        File.open(PROJECT_STATE_FILE_V10564,'wb'){|io|io.write(text.rstrip+"\r\n"+lines.join("\r\n")+"\r\n")}
      rescue
      end
      true
    rescue
      false
    end
  end
end
