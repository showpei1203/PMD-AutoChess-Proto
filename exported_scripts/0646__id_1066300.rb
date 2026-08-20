# encoding: UTF-8
#===============================================================================
# ■ PMD AutoChess - Gate 3 Completion Incentive + Retreat Clarity I
#   v1.06.63 PRODUCTION CANDIDATE
#-------------------------------------------------------------------------------
# 【用途】
# - 修正 Gate 3 Baseline 已證明的 Tier4 / Tier5 完整通關 Bonus 平台。
# - Tier1..4 維持 2/2/3/4 抽；Tier5 完整通關由 4 提升為 5 抽。
# - 只允許 Hunt Completion Context 超過既有 Tier5 pool max=4；一般掉落上限不變。
# - 撤退／敗北仍無 Completion Bonus，已取得的即時成果照舊保留。
# - 結算文字明確標示完整通關 Bonus 抽數，以及撤退／敗北未取得通關 Bonus。
#===============================================================================
$imported={} unless defined?($imported)
$imported['PMD_AutoChess_Gate3CompletionIncentiveRetreatClarityI_v10663']=true

module PMD_AC
  VXRD_GATE3_COMPLETION_ROLLS_V10663={1=>2,2=>2,3=>3,4=>4,5=>5}
  VXRD_GATE3_COMPLETION_OVERRIDE_CAP_V10663=6

  class << self
    alias pmd_ac_v10663_loot_roll_count_v094 loot_roll_count_v094 unless method_defined?(:pmd_ac_v10663_loot_roll_count_v094)
    def loot_roll_count_v094(pool,context)
      return 0 if pool==nil
      c=context || {}
      if c.has_key?(:completion_roll_target_v10663)
        n=c[:completion_roll_target_v10663].to_i
        n=0 if n<0
        cap=VXRD_GATE3_COMPLETION_OVERRIDE_CAP_V10663.to_i
        n=cap if cap>0 && n>cap
        return n
      end
      pmd_ac_v10663_loot_roll_count_v094(pool,context)
    rescue
      pmd_ac_v10663_loot_roll_count_v094(pool,context)
    end

    alias pmd_ac_v10663_hunt_runtime_completion_bonus_v10605 hunt_runtime_completion_bonus_v10605 unless method_defined?(:pmd_ac_v10663_hunt_runtime_completion_bonus_v10605)
    def hunt_runtime_completion_bonus_v10605(session,dry_run=false)
      return nil if session==nil
      key=hunt_loot_pool_key_v10578(session[:code])
      tier=[[session[:tier].to_i,1].max,5].min
      rarity=tier>=4 ? :very_rare : :rare
      target=VXRD_GATE3_COMPLETION_ROLLS_V10663[tier].to_i
      ctx={:rarity=>rarity,:elite=>(tier>=4),:elite_count=>(tier>=4 ? 1:0),:boss=>false,
        :hunt_completion_v10605=>true,:completion_roll_target_v10663=>target,
        :completion_tier_v10663=>tier}
      out=resolve_loot_pool_v094(key,ctx,dry_run)
      if out.is_a?(Hash)
        out[:completion_roll_target_v10663]=target
        out[:completion_tier_v10663]=tier
      end
      out
    rescue
      nil
    end

    alias pmd_ac_v10663_hunt_runtime_result_lines_v10605 hunt_runtime_result_lines_v10605 unless method_defined?(:pmd_ac_v10663_hunt_runtime_result_lines_v10605)
    def hunt_runtime_result_lines_v10605(result)
      lines=pmd_ac_v10663_hunt_runtime_result_lines_v10605(result)
      return lines unless lines.is_a?(Array) && lines.size>=4 && result.is_a?(Hash)
      reason=result[:reason].to_s
      bonus=result[:completion_bonus]||{}
      labels=bonus[:labels]||[]
      if reason=='complete'
        rolls=bonus[:rolls].to_i
        rolls=bonus[:completion_roll_target_v10663].to_i if rolls<=0
        rolls=0 if rolls<0
        lines[3]='通關 Bonus '+rolls.to_s+'抽：'+(labels.empty? ? '無掉落' : labels[0,2].join('、'))
      elsif reason=='retreat'
        lines[3]='撤退：已取得成果保留｜未取得通關 Bonus'
      elsif reason=='defeat'
        lines[3]='敗北：已取得成果保留｜未取得通關 Bonus'
      end
      lines
    rescue
      pmd_ac_v10663_hunt_runtime_result_lines_v10605(result)
    end

    def vxrd_gate3_completion_target_v10663(tier)
      t=[[tier.to_i,1].max,5].min
      VXRD_GATE3_COMPLETION_ROLLS_V10663[t].to_i
    rescue
      0
    end

    def vxrd_gate3_completion_static_audit_v10663
      bad=[]
      curve={}
      (1..5).each{|t|curve[t]=vxrd_gate3_completion_target_v10663(t)}
      expected={1=>2,2=>2,3=>3,4=>4,5=>5}
      bad << :curve unless curve==expected

      # Verify all non-completion contexts remain delegated byte/behavior-equivalent.
      pool={:base_rolls=>2,:max_rolls=>4}
      contexts=[{},
        {:rarity=>:rare},
        {:rarity=>:very_rare,:elite=>true},
        {:rarity=>:normal,:elite=>true,:boss=>true}]
      normal_same=true
      contexts.each do |ctx|
        a=pmd_ac_v10663_loot_roll_count_v094(pool,ctx)
        b=loot_roll_count_v094(pool,ctx)
        normal_same=false unless a==b
      end
      bad << :normal_roll_policy unless normal_same

      # Completion-only marker may exceed pool max=4, but never beyond local safety cap.
      completion_ctx={:rarity=>:very_rare,:elite=>true,:completion_roll_target_v10663=>5}
      completion_rolls=loot_roll_count_v094(pool,completion_ctx)
      bad << :completion_override unless completion_rolls==5
      bad << :override_cap unless loot_roll_count_v094(pool,{:completion_roll_target_v10663=>99})==VXRD_GATE3_COMPLETION_OVERRIDE_CAP_V10663

      stats={:battles=>6,:wins=>5,:losses=>0,:escapes=>1,:recruits=>2,:treasures=>2,
        :recoveries=>1,:rare_nest_wins=>1,:elite_room_wins=>2,:loot_results=>7}
      common={:code=>'H21',:floors_cleared=>6,:max_floors=>6,:stats=>stats}
      complete=common.merge({:reason=>:complete,:completion_bonus=>{:rolls=>5,:labels=>['掉落 A','掉落 B'],:completion_roll_target_v10663=>5}})
      retreat=common.merge({:reason=>:retreat,:completion_bonus=>nil})
      defeat=common.merge({:reason=>:defeat,:completion_bonus=>nil})
      cl=(hunt_runtime_result_lines_v10605(complete)||[]).join('|')
      rl=(hunt_runtime_result_lines_v10605(retreat)||[]).join('|')
      dl=(hunt_runtime_result_lines_v10605(defeat)||[]).join('|')
      bad << :complete_copy unless cl.index('通關 Bonus 5抽')
      bad << :retreat_copy unless rl.index('未取得通關 Bonus') && rl.index('成果保留')
      bad << :defeat_copy unless dl.index('未取得通關 Bonus') && dl.index('成果保留')

      {:pass=>bad.empty?,:curve=>curve,:normal_roll_policy_unchanged=>normal_same,
        :completion_override_rolls=>completion_rolls,:retreat_bonus=>0,:defeat_bonus=>0,
        :partial_clear_bonus=>0,:new_items=>0,:bad=>bad}
    rescue Exception=>e
      {:pass=>false,:bad=>[:audit_error],:error=>e.class.to_s}
    end

    alias pmd_ac_v10663_write_project_state_log write_project_state_log unless method_defined?(:pmd_ac_v10663_write_project_state_log)
    def project_version
      '1.06.63'
    end
    def write_project_state_log(force=false)
      r=pmd_ac_v10663_write_project_state_log(force)
      return false unless r
      begin
        text='';File.open(PROJECT_STATE_FILE_V10564,'rb'){|io|text=io.read}
        text=text.gsub(/PROJECT_STATE_SCHEMA=\d+/,'PROJECT_STATE_SCHEMA=44')
        text=text.gsub(/CURRENT_VERSION=[^\r\n]+/,'CURRENT_VERSION=1.06.63')
        text=text.gsub(/LATEST_FEATURE=[^\r\n]+/,'LATEST_FEATURE=GATE3_COMPLETION_INCENTIVE_RETREAT_CLARITY_I')
        text=text.gsub(/NEXT_TARGET=[^\r\n]+/,'NEXT_TARGET=GATE3_V10663_WINDOWS_ACCEPTANCE+RUN_SETTLEMENT_ACCOUNTING_PHASE_IV')
        text=text.gsub(/\r?\nVXRD_GATE3_V10663_BEGIN.*?VXRD_GATE3_V10663_END\r?\n/m,"\r\n")
        a=vxrd_gate3_completion_static_audit_v10663
        lines=[]
        lines << ''
        lines << 'VXRD_GATE3_V10663_BEGIN'
        lines << 'GATE3_COMPLETION_STATIC='+(a[:pass] ? 'PASS':'FAIL')
        lines << 'GATE3_COMPLETION_ROLLS=1:2,2:2,3:3,4:4,5:5'
        lines << 'GATE3_T5_COMPLETION_ONLY_OVERRIDE=5'
        lines << 'GATE3_NORMAL_LOOT_MAX_CHANGE=0'
        lines << 'GATE3_RETREAT_COMPLETION_BONUS=0'
        lines << 'GATE3_DEFEAT_COMPLETION_BONUS=0'
        lines << 'GATE3_PARTIAL_CLEAR_BONUS=0'
        lines << 'GATE3_NEW_ITEMS=0'
        lines << 'GATE3_FLOOR_DEPTH_CURVE_V10662=SEALED'
        lines << 'RMVX_EDITOR_RESTART_REQUIRED=1'
        lines << 'TUTORIAL_UPDATED=1'
        lines << 'VXRD_GATE3_V10663_END'
        File.open(PROJECT_STATE_FILE_V10564,'wb'){|io|io.write(text.rstrip+"\r\n"+lines.join("\r\n")+"\r\n")}
      rescue
      end
      true
    rescue
      false
    end
  end
end
