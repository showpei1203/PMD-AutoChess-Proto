# encoding: UTF-8
#===============================================================================
# ■ PMD AutoChess - VXRD Production Hunt Run Entry v1.06.04
#-------------------------------------------------------------------------------
# 【用途】
# 1. 將既有 Hunt Selector 正式改接 Map090 VX-native Random Dungeon，而非單場測試戰。
# 2. 自動保存進入前 Map / X / Y / 方向；同一 Hunt Run 全程共用 Active Pool / Seed。
# 3. 轉移完成後自動建立第一層，不需要事件製作者手動串接 API。
# 4. AutoTest 仍保留，Production / AutoTest 共用同一張 runtime shell，不建立第二套 Game_Map。
#===============================================================================
$imported={} unless defined?($imported)
$imported['PMD_AutoChess_VXRDProductionHuntEntry_v10604']=true

class Game_Temp
  attr_accessor :pmd_vxrd_hunt_pending_v10604
  attr_accessor :pmd_vxrd_hunt_result_message_v10604
end

module PMD_AC
  VXRD_HUNT_RUNTIME_MAP_ID_V10604=90
  VXRD_HUNT_DEFAULT_MODE_V10604=:event
  VXRD_HUNT_FLOORS_BY_TIER_V10604={1=>3,2=>4,3=>5,4=>5,5=>6}

  class << self
    def hunt_runtime_floor_limit_v10604(code)
      h=phase_div_hunt_v10553(code.to_s.upcase) rescue nil
      tier=h==nil ? 1 : [[h[:tier].to_i,1].max,5].min
      VXRD_HUNT_FLOORS_BY_TIER_V10604[tier] || 3
    rescue
      3
    end

    def hunt_runtime_message_v10604(lines)
      return false if $game_message==nil || $game_message.busy
      ary=lines.is_a?(Array) ? lines : [lines]
      $game_message.face_name=''
      $game_message.face_index=0
      $game_message.background=0
      $game_message.position=2
      ary[0,4].each{|t|$game_message.texts.push(t.to_s)}
      true
    rescue
      false
    end

    def hunt_runtime_active_v10604?
      s=phase_div_hunt_session_v10555
      s!=nil && s[:active] && s[:vxrd_runtime_v10604] && $game_map!=nil &&
        $game_map.map_id.to_i==VXRD_HUNT_RUNTIME_MAP_ID_V10604
    rescue
      false
    end

    def hunt_runtime_origin_v10604
      s=phase_div_hunt_session_v10555
      return nil if s==nil
      o=s[:vxrd_origin_v10604]
      o.is_a?(Hash) ? o.dup : nil
    rescue
      nil
    end

    def start_hunt_dungeon_v10604(code,mode=VXRD_HUNT_DEFAULT_MODE_V10604,seed=nil)
      return false if $game_map==nil || $game_player==nil || $game_temp==nil
      c=code.to_s.upcase
      return false if phase_div_hunt_v10553(c)==nil
      m=(mode||VXRD_HUNT_DEFAULT_MODE_V10604).to_sym
      m=:event unless [:event,:steps].include?(m)
      # Production launch is intentionally separate from AutoTest state.
      if respond_to?(:vxrd_autotest_active_v10586?) && vxrd_autotest_active_v10586?
        vxrd_autotest_return_v10586 rescue nil
      end
      old=phase_div_hunt_session_v10555
      hunt_exit(:new_runtime_hunt) if old!=nil && old[:active]
      pending={:code=>c,:mode=>m,:seed=>seed,
        :origin_map_id=>$game_map.map_id.to_i,:origin_x=>$game_player.x.to_i,
        :origin_y=>$game_player.y.to_i,:origin_direction=>$game_player.direction.to_i,
        :started_frame=>(defined?(Graphics) ? Graphics.frame_count.to_i : 0)}
      $game_temp.pmd_vxrd_hunt_pending_v10604=pending
      $game_player.reserve_transfer(VXRD_HUNT_RUNTIME_MAP_ID_V10604,30,22,2)
      $scene=Scene_Map.new unless $scene.is_a?(Scene_Map)
      true
    rescue
      false
    end

    def hunt_runtime_generate_after_transfer_v10604
      return false if $game_map==nil || $game_map.map_id.to_i!=VXRD_HUNT_RUNTIME_MAP_ID_V10604
      p=$game_temp==nil ? nil : $game_temp.pmd_vxrd_hunt_pending_v10604
      return false if p==nil
      $game_temp.pmd_vxrd_hunt_pending_v10604=nil
      c=p[:code].to_s.upcase;m=(p[:mode]||:event).to_sym
      s=hunt_map_enter(c,m,p[:seed])
      return false if s==nil
      s[:vxrd_runtime_v10604]=true
      s[:vxrd_origin_v10604]={:map_id=>p[:origin_map_id].to_i,:x=>p[:origin_x].to_i,
        :y=>p[:origin_y].to_i,:direction=>p[:origin_direction].to_i}
      s[:vxrd_max_floors_v10604]=hunt_runtime_floor_limit_v10604(c)
      s[:vxrd_started_frame_v10604]=p[:started_frame].to_i
      s[:vxrd_floor_clears_v10604]=0
      s[:vxrd_runtime_stats_v10604]={:battles=>0,:wins=>0,:losses=>0,:escapes=>0,
        :recruits=>0,:treasures=>0,:recoveries=>0,:rare_nest_wins=>0,:elite_room_wins=>0,
        :loot_results=>0,:loot_labels=>[]}
      st=hunt_generate_vx_floor_v10584(c,m,{:move_player=>true})
      return false if st==nil
      hunt_runtime_message_v10604([
        c+' '+((phase_div_hunt_v10553(c)||{})[:name]||'').to_s,
        '狩獵開始｜Floor 1 / '+s[:vxrd_max_floors_v10604].to_i.to_s,
        '本次 Active Pool '+(s[:active_pool]||[]).size.to_i.to_s+' 種｜AI'+s[:ai_tier].to_i.to_s,
        '探索遭遇、特殊房與寶藏；出口前往下一層。'
      ])
      write_project_state_log(false) if respond_to?(:write_project_state_log)
      true
    rescue
      false
    end

    # Existing public Hunt selector API now enters the integrated random dungeon.
    def phase_div_start_hunt_scene_battle_v10560(code)
      start_hunt_dungeon_v10604(code,:event,nil)
    rescue
      false
    end

    def hunt_runtime_entry_audit_v10604
      req=[:start_hunt_dungeon_v10604,:hunt_runtime_generate_after_transfer_v10604,
        :hunt_runtime_active_v10604?,:hunt_runtime_origin_v10604,:hunt_runtime_floor_limit_v10604]
      bad=req.find_all{|m|!respond_to?(m)}
      floors=(1..5).collect{|t|VXRD_HUNT_FLOORS_BY_TIER_V10604[t].to_i}
      bad << :floor_curve unless floors==[3,4,5,5,6]
      {:pass=>bad.empty?,:api=>req.size,:map_id=>VXRD_HUNT_RUNTIME_MAP_ID_V10604,
        :floor_curve=>floors,:selector_integrated=>true,:bad=>bad}
    rescue
      {:pass=>false,:api=>0,:bad=>[:audit_error]}
    end
  end
end

class Game_Player
  alias pmd_ac_v10604_perform_transfer perform_transfer unless method_defined?(:pmd_ac_v10604_perform_transfer)
  def perform_transfer
    pmd_ac_v10604_perform_transfer
    begin
      if $game_map!=nil && $game_map.map_id.to_i==PMD_AC::VXRD_HUNT_RUNTIME_MAP_ID_V10604 &&
         $game_temp!=nil && $game_temp.pmd_vxrd_hunt_pending_v10604!=nil
        PMD_AC.hunt_runtime_generate_after_transfer_v10604
      end
    rescue
    end
  end
end
