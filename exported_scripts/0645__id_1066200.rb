# encoding: UTF-8
#===============================================================================
# ■ PMD AutoChess - Gate 3 Floor-Depth Risk Curve + Settlement Visibility I
#   v1.06.62 PRODUCTION CANDIDATE
#-------------------------------------------------------------------------------
# 【用途】
# - 在既有 Tier Room Type 機率上加入「樓層越深，Rare/Elite 越高」的保守曲線。
# - 保留 v1.06.01 原本 RNG 流程；額外深度提升使用 seed hash，不額外呼叫 RNG。
# - 擴充 Hunt 結算文字，顯示 Runtime 已存在的戰鬥／逃跑／休息／掉落統計。
# - 本版不修改 Completion Bonus 次數、撤退／敗北保留規則、Battle/Reward 公式。
#===============================================================================
$imported={} unless defined?($imported)
$imported['PMD_AutoChess_Gate3FloorDepthRiskSettlementI_v10662']=true

module PMD_AC
  VXRD_GATE3_RARE_FINAL_BONUS_V10662=12
  VXRD_GATE3_ELITE_FINAL_BONUS_V10662=15
  VXRD_GATE3_SPECIAL_RATE_CAP_V10662=85
  VXRD_GATE3_COMPLETION_POLICY_V10662=:UNCHANGED_V10605

  class << self
    def vxrd_gate3_floor_context_v10662(state=nil,tier=nil)
      s=respond_to?(:phase_div_hunt_session_v10555) ? (phase_div_hunt_session_v10555 rescue nil) : nil
      t=tier.to_i
      if t<=0
        h=respond_to?(:phase_div_hunt_v10553) && state!=nil ? (phase_div_hunt_v10553(state[:code].to_s) rescue nil) : nil
        t=h==nil ? 1 : h[:tier].to_i
      end
      t=1 if t<1;t=5 if t>5
      max=0
      max=s[:vxrd_max_floors_v10604].to_i if s.is_a?(Hash)
      if max<=0 && defined?(VXRD_HUNT_FLOORS_BY_TIER_V10604)
        max=VXRD_HUNT_FLOORS_BY_TIER_V10604[t].to_i
      end
      max=1 if max<=0
      floor=1
      if s.is_a?(Hash)
        current=s[:vxrd_floor_count_v10584].to_i
        floor=current+1
        # If called after floor commit rather than during generation, do not exceed max.
        floor=current if current>=max
      elsif state.is_a?(Hash) && state[:floor_v10662].to_i>0
        floor=state[:floor_v10662].to_i
      end
      floor=1 if floor<1;floor=max if floor>max
      {:tier=>t,:floor=>floor,:max_floor=>max}
    rescue
      {:tier=>1,:floor=>1,:max_floor=>1}
    end

    def vxrd_gate3_depth_bonus_v10662(floor,max_floor,final_bonus)
      f=floor.to_i;m=max_floor.to_i;b=final_bonus.to_i
      return 0 if b<=0 || m<=1 || f<=1
      f=m if f>m
      # round-to-nearest integer percentage point
      num=(f-1)*b
      den=(m-1)
      (num*2+den)/(den*2)
    rescue
      0
    end

    def vxrd_gate3_effective_rate_v10662(base,floor,max_floor,kind=:rare)
      b=base.to_i
      bonus=(kind.to_sym==:elite ? VXRD_GATE3_ELITE_FINAL_BONUS_V10662 : VXRD_GATE3_RARE_FINAL_BONUS_V10662)
      r=b+vxrd_gate3_depth_bonus_v10662(floor,max_floor,bonus)
      cap=VXRD_GATE3_SPECIAL_RATE_CAP_V10662
      r=cap if r>cap;r=0 if r<0
      r
    rescue
      base.to_i
    end

    def vxrd_gate3_hash_v10662(seed,floor,salt)
      x=(seed.to_i ^ (floor.to_i*1103515245) ^ salt.to_i) & 0x7fffffff
      x=(x*1664525+1013904223) & 0x7fffffff
      x^=(x>>11)
      x&0x7fffffff
    rescue
      0
    end

    def vxrd_gate3_promotion_bps_v10662(base,target)
      b=base.to_i;t=target.to_i
      return 0 if t<=b || b>=100
      q=((t-b)*10000)/(100-b)
      q=10000 if q>10000;q=0 if q<0
      q
    rescue
      0
    end

    def vxrd_gate3_promote_special_v10662(state,type,base,target,salt)
      return false if state==nil || target.to_i<=base.to_i
      types=state[:room_types_v10601]||{}
      return false if types.values.include?(type.to_sym)
      normals=types.keys.find_all{|id|types[id]==:normal}.sort
      return false if normals.empty?
      ctx=vxrd_gate3_floor_context_v10662(state,nil)
      seed=state[:seed].to_i
      threshold=vxrd_gate3_promotion_bps_v10662(base,target)
      roll=vxrd_gate3_hash_v10662(seed,ctx[:floor],salt)%10000
      return false unless roll<threshold
      pick=vxrd_gate3_hash_v10662(seed,ctx[:floor],salt^0x5A17)%normals.size
      rid=normals[pick]
      types[rid]=type.to_sym
      true
    rescue
      false
    end

    alias pmd_ac_v10662_assign_room_types_v10601 vxrd_assign_room_types_v10601 unless method_defined?(:pmd_ac_v10662_assign_room_types_v10601)
    def vxrd_assign_room_types_v10601(state)
      st=pmd_ac_v10662_assign_room_types_v10601(state)
      return st if st==nil
      meta=st[:room_type_meta_v10601]||={}
      tier=meta[:tier].to_i;tier=1 if tier<1;tier=5 if tier>5
      ctx=vxrd_gate3_floor_context_v10662(st,tier)
      base_r=defined?(VXRD_RARE_NEST_RATE_V10601) ? VXRD_RARE_NEST_RATE_V10601[tier].to_i : meta[:rare_rate].to_i
      base_e=defined?(VXRD_ELITE_ROOM_RATE_V10601) ? VXRD_ELITE_ROOM_RATE_V10601[tier].to_i : meta[:elite_rate].to_i
      target_r=vxrd_gate3_effective_rate_v10662(base_r,ctx[:floor],ctx[:max_floor],:rare)
      target_e=(tier>=2 ? vxrd_gate3_effective_rate_v10662(base_e,ctx[:floor],ctx[:max_floor],:elite) : 0)
      rare_ok=meta[:rare_available] ? true:false
      promoted_r=false;promoted_e=false
      promoted_r=vxrd_gate3_promote_special_v10662(st,:rare_nest,base_r,target_r,0x621A) if rare_ok
      promoted_e=vxrd_gate3_promote_special_v10662(st,:elite,base_e,target_e,0x621E) if tier>=2
      counts={}
      (st[:room_types_v10601]||{}).values.each{|t|counts[t]=counts[t].to_i+1}
      st[:room_type_counts_v10601]=counts
      meta[:rare_rate_base_v10662]=base_r
      meta[:elite_rate_base_v10662]=base_e
      meta[:rare_rate]=target_r
      meta[:elite_rate]=target_e
      meta[:floor_v10662]=ctx[:floor]
      meta[:max_floor_v10662]=ctx[:max_floor]
      meta[:rare_depth_bonus_v10662]=target_r-base_r
      meta[:elite_depth_bonus_v10662]=target_e-base_e
      meta[:rare_promoted_v10662]=promoted_r
      meta[:elite_promoted_v10662]=promoted_e
      meta[:extra_rng_calls_v10662]=0
      st[:room_type_meta_v10601]=meta
      st
    rescue
      st
    end

    alias pmd_ac_v10662_hunt_runtime_result_lines_v10605 hunt_runtime_result_lines_v10605 unless method_defined?(:pmd_ac_v10662_hunt_runtime_result_lines_v10605)
    def hunt_runtime_result_lines_v10605(result)
      return pmd_ac_v10662_hunt_runtime_result_lines_v10605(result) if result==nil
      reason=result[:reason].to_s
      title=reason=='complete' ? '狩獵完成' : (reason=='defeat' ? '狩獵失敗' : '狩獵撤退')
      st=result[:stats]||{}
      line2=result[:code].to_s+'｜Floor '+result[:floors_cleared].to_i.to_s+'/'+result[:max_floors].to_i.to_s+
        '｜戰 '+st[:battles].to_i.to_s+'（'+st[:wins].to_i.to_s+'勝/'+st[:losses].to_i.to_s+'敗/'+st[:escapes].to_i.to_s+'逃）'
      line3='招募 '+st[:recruits].to_i.to_s+'｜寶藏 '+st[:treasures].to_i.to_s+'｜休息 '+st[:recoveries].to_i.to_s+
        '｜R '+st[:rare_nest_wins].to_i.to_s+'｜E '+st[:elite_room_wins].to_i.to_s
      bonus=(result[:completion_bonus]||{})[:labels]||[]
      base='掉落 '+st[:loot_results].to_i.to_s+'｜'
      line4=base+(bonus.empty? ? (reason=='complete' ? '通關 Bonus：無額外掉落' : '已取得成果保留') :
        ('通關 Bonus：'+bonus[0,2].join('、')))
      [title,line2,line3,line4]
    rescue
      pmd_ac_v10662_hunt_runtime_result_lines_v10605(result)
    end

    def vxrd_gate3_curve_table_v10662
      out={}
      (1..5).each do |tier|
        max=defined?(VXRD_HUNT_FLOORS_BY_TIER_V10604) ? VXRD_HUNT_FLOORS_BY_TIER_V10604[tier].to_i : 1
        max=1 if max<=0
        br=VXRD_RARE_NEST_RATE_V10601[tier].to_i
        be=VXRD_ELITE_ROOM_RATE_V10601[tier].to_i
        out[tier]=(1..max).collect do |f|
          [f,vxrd_gate3_effective_rate_v10662(br,f,max,:rare),
           tier>=2 ? vxrd_gate3_effective_rate_v10662(be,f,max,:elite) : 0]
        end
      end
      out
    rescue
      {}
    end

    def vxrd_gate3_static_audit_v10662
      bad=[]
      tab=vxrd_gate3_curve_table_v10662
      expected={
        1=>[[1,18,0],[2,24,0],[3,30,0]],
        2=>[[1,28,30],[2,32,35],[3,36,40],[4,40,45]],
        3=>[[1,40,42],[2,43,46],[3,46,50],[4,49,53],[5,52,57]],
        4=>[[1,52,55],[2,55,59],[3,58,63],[4,61,66],[5,64,70]],
        5=>[[1,65,70],[2,67,73],[3,70,76],[4,72,79],[5,75,82],[6,77,85]]
      }
      bad << :curve unless tab==expected
      bad << :completion_policy unless VXRD_GATE3_COMPLETION_POLICY_V10662==:UNCHANGED_V10605
      # Hash repeatability without touching global or VXRD RNG.
      a=vxrd_gate3_hash_v10662(12345,4,0x621A)
      b=vxrd_gate3_hash_v10662(12345,4,0x621A)
      bad << :determinism unless a==b
      fixture={:reason=>:retreat,:code=>'H03',:floors_cleared=>2,:max_floors=>5,
        :stats=>{:battles=>5,:wins=>3,:losses=>1,:escapes=>1,:recruits=>2,:treasures=>1,
          :recoveries=>1,:rare_nest_wins=>1,:elite_room_wins=>0,:loot_results=>4},
        :completion_bonus=>nil}
      lines=hunt_runtime_result_lines_v10605(fixture)
      text=(lines||[]).join('|')
      bad << :settlement unless lines.is_a?(Array) && lines.size==4 &&
        text.index('5') && text.index('3勝/1敗/1逃') && text.index('休息 1') && text.index('掉落 4')
      {:pass=>bad.empty?,:curve=>tab,:completion_unchanged=>true,:extra_rng_calls=>0,
        :settlement_fields=>[:battles,:wins,:losses,:escapes,:recruits,:treasures,:recoveries,
          :rare_nest_wins,:elite_room_wins,:loot_results],:bad=>bad}
    rescue Exception=>e
      {:pass=>false,:bad=>[:audit_error],:error=>e.class.to_s}
    end

    alias pmd_ac_v10662_write_project_state_log write_project_state_log unless method_defined?(:pmd_ac_v10662_write_project_state_log)
    def project_version
      '1.06.62'
    end
    def write_project_state_log(force=false)
      r=pmd_ac_v10662_write_project_state_log(force)
      return false unless r
      begin
        text='';File.open(PROJECT_STATE_FILE_V10564,'rb'){|io|text=io.read}
        text=text.gsub(/PROJECT_STATE_SCHEMA=\d+/,'PROJECT_STATE_SCHEMA=43')
        text=text.gsub(/CURRENT_VERSION=[^\r\n]+/,'CURRENT_VERSION=1.06.62')
        text=text.gsub(/LATEST_FEATURE=[^\r\n]+/,'LATEST_FEATURE=GATE3_FLOOR_DEPTH_RISK_CURVE_SETTLEMENT_VISIBILITY_I')
        text=text.gsub(/NEXT_TARGET=[^\r\n]+/,'NEXT_TARGET=GATE3_V10662_WINDOWS_ACCEPTANCE+COMPLETION_ECONOMY_PHASE_III')
        text=text.gsub(/\r?\nVXRD_GATE3_V10662_BEGIN.*?VXRD_GATE3_V10662_END\r?\n/m,"\r\n")
        a=vxrd_gate3_static_audit_v10662
        lines=[]
        lines << ''
        lines << 'VXRD_GATE3_V10662_BEGIN'
        lines << 'GATE3_FLOOR_DEPTH_STATIC='+(a[:pass] ? 'PASS':'FAIL')
        lines << 'GATE3_RARE_FINAL_BONUS=12'
        lines << 'GATE3_ELITE_FINAL_BONUS=15'
        lines << 'GATE3_SPECIAL_RATE_CAP=85'
        lines << 'GATE3_EXTRA_RNG_CALLS=0'
        lines << 'GATE3_COMPLETION_BONUS_POLICY=UNCHANGED_V10605'
        lines << 'GATE3_SETTLEMENT_VISIBILITY=EXPANDED_EXISTING_FIELDS_ONLY'
        lines << 'GATE3_REWARD_GRANT_CHANGE=0'
        lines << 'GATE3_MAP_TOPOLOGY_CHANGE=0'
        lines << 'RMVX_EDITOR_RESTART_REQUIRED=1'
        lines << 'TUTORIAL_UPDATED=1'
        lines << 'VXRD_GATE3_V10662_END'
        File.open(PROJECT_STATE_FILE_V10564,'wb'){|io|io.write(text.rstrip+"\r\n"+lines.join("\r\n")+"\r\n")}
      rescue
      end
      true
    rescue
      false
    end
  end
end
