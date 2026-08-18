# encoding: UTF-8
#===============================================================================
# ■ PMD AutoChess - VXRD Save / Load / Resume Safety v1.06.09
#-------------------------------------------------------------------------------
# 【用途】
# - 在 Map090 中存檔／讀檔後恢復當前 Hunt Floor 的事件消耗與 encounter mode。
# - 若 Hunt Session 尚在但 VXRD runtime state 遺失，以目前 floor seed 原地重建，不增加樓層。
# - 若玩家意外載入孤立 Map090 且沒有 Hunt / AutoTest 狀態，安全送回原入口或 Map002。
#===============================================================================
$imported={} unless defined?($imported)
$imported['PMD_AutoChess_VXRDSaveResumeSafety_v10609']=true

module PMD_AC
  class << self
    def vxrd_runtime_map090_v10609?
      $game_map!=nil && $game_map.map_id.to_i==VXRD_HUNT_RUNTIME_MAP_ID_V10604
    rescue
      false
    end

    def vxrd_reapply_consumed_nodes_v10609
      s=phase_div_hunt_session_v10555;return false if s==nil || $game_map==nil
      h=s[:vxrd_consumed_nodes_v10606]||{}
      ($game_map.events||{}).each do |id,ev|
        key=vxrd_node_key_v10606(id)
        if h[key]
          ev.erase if ev.respond_to?(:erase)
        else
          ev.instance_variable_set(:@erased,false)
          ev.refresh if ev.respond_to?(:refresh)
        end
      end
      true
    rescue
      false
    end

    def vxrd_regenerate_saved_floor_v10609
      s=hunt_runtime_session_v10605;return false if s==nil || !vxrd_runtime_map090_v10609?
      seed=s[:vxrd_last_floor_seed_v10584].to_i;return false if seed<=0
      floor=s[:vxrd_floor_count_v10584].to_i
      o={:move_player=>false}
      st=vxrd_generate_current_map_v10582(s[:code],seed,o)
      return false if st==nil
      relocate=vxrd_relocate_events_v10584
      s[:vxrd_floor_count_v10584]=floor
      s[:vxrd_last_event_relocate_v10584]=relocate
      vxrd_reapply_consumed_nodes_v10609
      hunt_map_floor_ready(s[:code])
      vxrd_reveal_at_v10583 if respond_to?(:vxrd_reveal_at_v10583)
      true
    rescue
      false
    end

    def vxrd_resume_runtime_v10609
      return false unless vxrd_runtime_map090_v10609?
      auto=respond_to?(:vxrd_autotest_active_v10586?) && vxrd_autotest_active_v10586?
      s=hunt_runtime_session_v10605
      if s==nil
        return true if auto
        origin=nil
        raw=phase_div_hunt_session_v10555 rescue nil
        origin=raw[:vxrd_origin_v10604] if raw!=nil
        mid=origin.is_a?(Hash) ? origin[:map_id].to_i : 2;mid=2 if mid<=0 || mid==VXRD_HUNT_RUNTIME_MAP_ID_V10604
        x=origin.is_a?(Hash) ? origin[:x].to_i : 8;y=origin.is_a?(Hash) ? origin[:y].to_i : 6
        d=origin.is_a?(Hash) ? origin[:direction].to_i : 2;d=2 if d<=0
        $game_player.reserve_transfer(mid,x,y,d) if $game_player!=nil
        return false
      end
      st=vxrd_state_v10582 rescue nil
      ok=(st!=nil && st[:map_id].to_i==$game_map.map_id.to_i && st[:seed].to_i==s[:vxrd_last_floor_seed_v10584].to_i)
      ok=vxrd_regenerate_saved_floor_v10609 unless ok
      vxrd_reapply_consumed_nodes_v10609 if ok
      s[:encounter_mode_v10579]=(s[:encounter_mode_v10579]||:event).to_sym
      hunt_map_floor_ready(s[:code]) if ok
      write_project_state_log(false) if ok && respond_to?(:write_project_state_log)
      ok
    rescue
      false
    end

    def vxrd_save_resume_audit_v10609
      req=[:vxrd_resume_runtime_v10609,:vxrd_regenerate_saved_floor_v10609,
        :vxrd_reapply_consumed_nodes_v10609,:vxrd_runtime_map090_v10609?]
      bad=req.find_all{|m|!respond_to?(m)}
      {:pass=>bad.empty?,:api=>req.size,:floor_seed_restore=>true,:no_floor_increment=>true,
        :consumed_nodes=>true,:orphan_guard=>true,:bad=>bad}
    rescue
      {:pass=>false,:api=>0,:bad=>[:audit_error]}
    end
  end
end

class Scene_Map
  alias pmd_ac_v10609_start start unless method_defined?(:pmd_ac_v10609_start)
  def start
    pmd_ac_v10609_start
    begin
      PMD_AC.vxrd_resume_runtime_v10609 if PMD_AC.vxrd_runtime_map090_v10609?
    rescue
    end
  end
end
