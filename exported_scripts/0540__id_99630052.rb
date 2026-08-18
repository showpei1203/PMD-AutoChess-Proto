# encoding: UTF-8
#===============================================================================
# ■ PMD AutoChess - Phase D-IV Hunt Run / Random Map Bridge v1.05.55
#===============================================================================
# 【用途】
# 把 v1.05.53 的 Hunt Authority 接到正式 Scene_Map 遇敵流程，但不綁死任何
# Random Map 產生器。隨機地圖腳本只要在地圖建立/轉移完成後呼叫：
#   PMD_AC.phase_div_begin_hunt_run_v10555('H01', $game_map.map_id)
# 即可取得該 Hunt 的 persistent run seed、active species pool 與野外 Encounter。
#
# 【設計】
# - 21 張 Hunt Authority 與地圖殼分離；RTP/Random Map 可日後任意更換。
# - 每次進 Hunt 只從完整區域 Catalog 抽一組 8~12 species active pool。
# - 同一次 run 的 active pool 固定，離開再進才重抽，提供可理解的 hunting ecology。
# - Encounter 使用既有 v0.81/v0.84/v0.92 Request，不另造戰鬥核心。
# - AI tier 只套到敵方 Game_PMDChessUnit runtime，不寫回 Pokemon instance，避免
#   招募後把「野怪低難度 AI」永久帶回玩家 BOX。
#===============================================================================
$imported={} unless defined?($imported)
$imported['PMD_AutoChess_PhaseDIVHuntRunBridge_v10555']=true

module PMD_AC
  PHASE_DIV_HUNT_BRIDGE_V10555={
    :version=>'1.05.55',:authority=>'v1.05.53',:map_shell=>:external_random_map,
    :rtp_compatible=>true,:active_pool_min=>8,:active_pool_max=>12,
    :team_size=>3,:same_run_pool_persistent=>true,:ui_polish=>:deferred
  }
  PHASE_DIV_RARITY_WEIGHT_V10555={
    'common'=>60,'uncommon'=>30,'rare'=>12,'very_rare'=>4,'legendary'=>1
  }

  class << self
    def phase_div_seed_step_v10555(seed)
      ((seed.to_i * 1103515245 + 12345) & 0x7fffffff)
    end

    def phase_div_seed_value_v10555(seed,salt=0)
      x=(seed.to_i ^ ((salt.to_i+1)*2654435761)) & 0x7fffffff
      phase_div_seed_step_v10555(x)
    end

    def phase_div_challenge_unlock_for_species_v10555(row)
      return true if row==nil || row[:first_track].to_s=='hunt'
      return false unless respond_to?(:phase_div_challenge_cleared_v10556?)
      if row[:first_track].to_s=='challenge_reward'
        # v1.05.53 already records the owning Challenge in first_location.
        # Use that direct authority instead of reverse-scanning reward_key/species.
        return phase_div_challenge_cleared_v10556?(row[:first_location].to_s)
      elsif row[:first_track].to_s=='challenge_boss'
        return phase_div_challenge_cleared_v10556?(row[:first_location].to_s)
      end
      false
    rescue
      false
    end

    def phase_div_hunt_catalog_v10555(code)
      c=code.to_s.upcase
      return [] if phase_div_hunt_v10553(c)==nil
      out=[]
      PHASE_DIV_SPECIES_APPEARANCE_V10553.each do |k,row|
        next unless row[:natural_hunt].to_s.upcase==c
        next unless phase_div_challenge_unlock_for_species_v10555(row)
        out.push(k)
      end
      out.sort{|a,b|PHASE_DIV_SPECIES_APPEARANCE_V10553[a][:appearance_order].to_i <=> PHASE_DIV_SPECIES_APPEARANCE_V10553[b][:appearance_order].to_i}
    rescue
      []
    end

    def phase_div_spawn_weight_v10555(species)
      row=phase_div_species_v10553(species)
      return 1 if row==nil
      if respond_to?(:phase_div_spawn_weight_v10557)
        return [phase_div_spawn_weight_v10557(row).to_i,1].max
      end
      [PHASE_DIV_RARITY_WEIGHT_V10555[row[:spawn_rarity].to_s].to_i,1].max
    rescue
      1
    end

    def phase_div_weighted_species_pick_v10555(pool,seed,salt=0)
      a=(pool||[]).compact
      return nil if a.empty?
      total=0
      a.each{|sp|total += phase_div_spawn_weight_v10555(sp)}
      return a[0] if total<=0
      roll=phase_div_seed_value_v10555(seed,salt)%total
      acc=0
      a.each do |sp|
        acc += phase_div_spawn_weight_v10555(sp)
        return sp if roll<acc
      end
      a[-1]
    rescue
      (pool||[])[0]
    end

    def phase_div_active_pool_target_v10555(code,catalog_size)
      h=phase_div_hunt_v10553(code)
      tier=h==nil ? 1 : h[:tier].to_i
      n=tier<=2 ? 10 : 12
      n=8 if n<8
      [n,catalog_size.to_i].min
    end

    def phase_div_build_active_pool_v10555(code,seed)
      catalog=phase_div_hunt_catalog_v10555(code)
      target=phase_div_active_pool_target_v10555(code,catalog.size)
      remain=catalog.dup;out=[];salt=0
      while !remain.empty? && out.size<target
        sp=phase_div_weighted_species_pick_v10555(remain,seed,salt)
        break if sp==nil
        out.push(sp);remain.delete(sp);salt+=1
      end
      out
    rescue
      []
    end

    def phase_div_hunt_session_v10555
      return nil if $game_system==nil
      $game_system.pmd_phase_div_hunt_session_v10555
    end

    def phase_div_current_hunt_session_v10555(map_id=nil)
      s=phase_div_hunt_session_v10555
      return nil if s==nil || !s[:active]
      mid=map_id==nil ? ($game_map==nil ? 0 : $game_map.map_id.to_i) : map_id.to_i
      return nil if s[:map_id].to_i>0 && mid>0 && s[:map_id].to_i!=mid
      s
    rescue
      nil
    end

    def phase_div_begin_hunt_run_v10555(code,map_id=nil,seed=nil,options=nil)
      return nil if $game_system==nil
      c=code.to_s.upcase;h=phase_div_hunt_v10553(c)
      return nil if h==nil
      mid=map_id==nil ? ($game_map==nil ? 0 : $game_map.map_id.to_i) : map_id.to_i
      $game_system.pmd_phase_div_hunt_run_counter_v10555=$game_system.pmd_phase_div_hunt_run_counter_v10555.to_i+1
      counter=$game_system.pmd_phase_div_hunt_run_counter_v10555.to_i
      if seed==nil
        frame=(defined?(Graphics) && Graphics.respond_to?(:frame_count)) ? Graphics.frame_count.to_i : 0
        seed=((counter*1000003)+(mid*9176)+frame+10555) & 0x7fffffff
      end
      pool=phase_div_build_active_pool_v10555(c,seed)
      return nil if pool.empty?
      o=options.is_a?(Hash) ? options.dup : {}
      s={:active=>true,:code=>c,:map_id=>mid,:seed=>seed.to_i,:run=>counter,
        :encounters=>0,:active_pool=>pool,:tier=>h[:tier].to_i,:ai_tier=>h[:ai_tier].to_i,
        :level_min=>h[:level_min].to_i,:level_max=>h[:level_max].to_i,
        :options=>o,:started_frame=>((defined?(Graphics) && Graphics.respond_to?(:frame_count)) ? Graphics.frame_count.to_i : 0)}
      $game_system.pmd_phase_div_hunt_session_v10555=s
      steps=respond_to?(:phase_div_hunt_steps_v10557) ? phase_div_hunt_steps_v10557(h[:tier]) : [9,15]
      if $game_player!=nil && $game_player.respond_to?(:make_pmd_encounter_count_v081)
        $game_player.make_pmd_encounter_count_v081(steps[0],steps[1])
      end
      s
    rescue
      nil
    end

    def phase_div_bind_hunt_to_current_map_v10555(map_id=nil)
      s=phase_div_hunt_session_v10555;return false if s==nil
      mid=map_id==nil ? ($game_map==nil ? 0 : $game_map.map_id.to_i) : map_id.to_i
      return false if mid<=0
      s[:map_id]=mid;true
    rescue
      false
    end

    def phase_div_end_hunt_run_v10555
      s=phase_div_hunt_session_v10555
      s[:active]=false if s!=nil
      true
    rescue
      false
    end

    def phase_div_hunt_formation_v10555(session)
      return [] if session==nil
      pool=(session[:active_pool]||[]).dup
      return [] if pool.empty?
      out=[];salt=session[:encounters].to_i*17+3
      3.times do |i|
        source=pool.empty? ? (session[:active_pool]||[]) : pool
        sp=phase_div_weighted_species_pick_v10555(source,session[:seed],salt+i)
        next if sp==nil
        pool.delete(sp)
        row=phase_div_species_v10553(sp)||{}
        mn=[session[:level_min].to_i,row[:level_min].to_i].max
        mx=[session[:level_max].to_i,row[:level_max].to_i].min
        mn=session[:level_min].to_i if mn<=0
        mx=session[:level_max].to_i if mx<mn
        span=[mx-mn+1,1].max
        lv=mn+(phase_div_seed_value_v10555(session[:seed],salt+40+i)%span)
        pos=[[4,1],[5,2],[4,3]][i]
        out.push([sp,pos[0],pos[1],lv,{:phase_div_hunt_v10555=>true}])
      end
      out
    rescue
      []
    end

    def phase_div_hunt_request_v10555(session)
      return nil if session==nil
      h=phase_div_hunt_v10553(session[:code]);return nil if h==nil
      setup=phase_div_hunt_formation_v10555(session);return nil if setup.empty?
      opts={:kind=>:wild,:source=>:phase_div_hunt,:deploy=>false,:recruitable=>true,
        :can_escape=>true,:hp_policy=>:carry,:defeat_policy=>:return_heal}
      if respond_to?(:phase_div_hunt_runtime_options_v10557)
        extra=phase_div_hunt_runtime_options_v10557(session[:code])||{}
        extra.each{|k,v|opts[k]=v}
      end
      r=event_custom_request_v092(h[:name],setup,opts,false)
      return nil if r==nil
      r[:key]=('phase_div_'+session[:code].to_s.downcase).to_sym
      r[:source]=:phase_div_hunt
      r[:phase_div_hunt_code_v10555]=session[:code]
      r[:phase_div_hunt_seed_v10555]=session[:seed]
      r[:phase_div_hunt_run_v10555]=session[:run]
      r[:phase_div_ai_tier_v10555]=session[:ai_tier]
      r
    rescue
      nil
    end

    def phase_div_launch_hunt_encounter_v10555
      s=phase_div_current_hunt_session_v10555
      return false if s==nil
      r=phase_div_hunt_request_v10555(s);return false if r==nil
      s[:encounters]=s[:encounters].to_i+1
      launch_battle_request_v081(r)
    rescue
      false
    end

    def phase_div_apply_enemy_ai_tier_v10555(unit,tier)
      return false if unit==nil || unit.team!=:enemy
      t=tier.to_i
      # AI0/AI1 are intentionally readable. Higher tiers retain existing Dynamic Role AI.
      if t<=0
        unit.instance_variable_set(:@target_policy,:nearest)
        unit.instance_variable_set(:@target_rule,:nearest)
        unit.instance_variable_set(:@threat_policy,:hold_ground)
        unit.instance_variable_set(:@skill_policy,:current_target)
        unit.instance_variable_set(:@target_commitment,25)
      elsif t==1
        unit.instance_variable_set(:@target_policy,:nearest)
        unit.instance_variable_set(:@target_rule,:nearest)
        unit.instance_variable_set(:@threat_policy,:normal)
        unit.instance_variable_set(:@skill_policy,:current_target)
        unit.instance_variable_set(:@target_commitment,45)
      end
      unit.instance_variable_set(:@phase_div_ai_tier_v10555,t)
      true
    rescue
      false
    end

    def phase_div_hunt_bridge_audit_v10555
      bad=[]
      PHASE_DIV_HUNT_ORDER_V10553.each do |code|
        cat=phase_div_hunt_catalog_v10555(code)
        # H21 may be empty until legendary challenge clears; all others need content.
        bad.push('catalog:'+code) if code!='H21' && cat.empty?
      end
      a=phase_div_build_active_pool_v10555('H01',10555)
      b=phase_div_build_active_pool_v10555('H01',10555)
      bad.push('seed_parity') unless a==b
      bad.push('active_pool') if a.empty? || a.size>12
      {:pass=>bad.empty?,:hunt_maps=>PHASE_DIV_HUNT_ORDER_V10553.size,:sample_pool=>a,:bad=>bad}
    rescue
      {:pass=>false,:hunt_maps=>0,:sample_pool=>[],:bad=>['audit_error']}
    end
  end
end

class Game_System
  attr_accessor :pmd_phase_div_hunt_session_v10555
  attr_accessor :pmd_phase_div_hunt_run_counter_v10555
end

class Scene_Map
  alias pmd_ac_v10555_update_encounter update_encounter unless method_defined?(:pmd_ac_v10555_update_encounter)
  def update_encounter
    s=PMD_AC.phase_div_current_hunt_session_v10555($game_map==nil ? 0 : $game_map.map_id)
    if s==nil
      pmd_ac_v10555_update_encounter
      return
    end
    return if $game_player==nil || $game_player.encounter_count>0
    return if $game_map!=nil && $game_map.interpreter.running?
    return if $game_system!=nil && $game_system.encounter_disabled
    h=PMD_AC.phase_div_hunt_v10553(s[:code])
    steps=PMD_AC.respond_to?(:phase_div_hunt_steps_v10557) ? PMD_AC.phase_div_hunt_steps_v10557(h[:tier]) : [9,15]
    $game_player.make_pmd_encounter_count_v081(steps[0],steps[1])
    PMD_AC.phase_div_launch_hunt_encounter_v10555
  end
end

class Scene_PMD_AutoChess
  alias pmd_ac_v10555_create_units create_units unless method_defined?(:pmd_ac_v10555_create_units)
  alias pmd_ac_v10555_start_battle start_battle unless method_defined?(:pmd_ac_v10555_start_battle)
  alias pmd_ac_v10555_focus_summary focus_cast_log_summary_v1055 unless method_defined?(:pmd_ac_v10555_focus_summary)

  def create_units
    pmd_ac_v10555_create_units
    req=rpg_request_v081 rescue nil
    if req!=nil && req[:phase_div_hunt_code_v10555]!=nil
      tier=req[:phase_div_ai_tier_v10555].to_i
      (@units||[]).each{|u|PMD_AC.phase_div_apply_enemy_ai_tier_v10555(u,tier) if u.team==:enemy}
    end
  end

  def start_battle
    r=pmd_ac_v10555_start_battle
    begin
      req=rpg_request_v081
      if req!=nil && req[:phase_div_hunt_code_v10555]!=nil
        s=PMD_AC.phase_div_hunt_session_v10555
        log_event(:collection,'PHASE_DIV_HUNT_RUN_V10555 code='+req[:phase_div_hunt_code_v10555].to_s+
          ' run='+(s==nil ? '0':s[:run].to_i.to_s)+' seed='+(s==nil ? '0':s[:seed].to_i.to_s)+
          ' active_pool='+(s==nil ? '0':(s[:active_pool]||[]).size.to_s)+
          ' encounter='+(s==nil ? '0':s[:encounters].to_i.to_s)+' ai='+req[:phase_div_ai_tier_v10555].to_i.to_s+
          ' random_map_shell=external rtp_compatible=1')
      end
    rescue
    end
    r
  end

  def focus_cast_log_summary_v1055
    r=pmd_ac_v10555_focus_summary
    begin
      a=PMD_AC.phase_div_hunt_bridge_audit_v10555
      log_event(:battle,'BATTLE_PHASE_DIV_HUNT_BRIDGE_SUMMARY_V10555 pass='+(a[:pass] ? '1':'0')+
        ' hunt_maps='+a[:hunt_maps].to_i.to_s+'/21 deterministic_pool=1 random_map_shell=external'+
        ' ui_polish=deferred errors=['+(a[:bad]||[]).join(',')+'] blocking_gate=0')
    rescue
    end
    r
  end
end
