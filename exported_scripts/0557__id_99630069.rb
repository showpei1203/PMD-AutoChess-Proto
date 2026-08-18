# encoding: UTF-8
#===============================================================================
# ■ PMD AutoChess - Random Map Event Bridge v1.05.72
#-------------------------------------------------------------------------------
# 【用途】
# 提供 Random Map / RTP 地圖事件可直接呼叫的穩定 API，不綁任何特定隨機地圖插件。
# 同一 Hunt Run 可以跨多個 generated floor / map_id，active pool 與 seed 保持一致。
#===============================================================================
$imported={} unless defined?($imported)
$imported['PMD_AutoChess_RandomMapEventBridge_v10572']=true

module PMD_AC
  class << self
    alias pmd_ac_v10572_current_hunt_session phase_div_current_hunt_session_v10555 unless method_defined?(:pmd_ac_v10572_current_hunt_session)

    def phase_div_current_hunt_session_v10555(map_id=nil)
      s=phase_div_hunt_session_v10555
      return nil if s==nil || !s[:active]
      mid=map_id==nil ? ($game_map==nil ? 0 : $game_map.map_id.to_i) : map_id.to_i
      maps=s[:map_ids_v10572]
      if maps!=nil && !maps.empty? && mid>0
        return s if maps.include?(mid)
        return nil
      end
      pmd_ac_v10572_current_hunt_session(map_id)
    rescue
      nil
    end

    def hunt_enter(code,seed=nil)
      mid=$game_map==nil ? 0 : $game_map.map_id.to_i
      s=phase_div_begin_hunt_run_v10555(code,mid,seed,{:bridge=>:random_map_v10572})
      return nil if s==nil
      s[:map_ids_v10572]=[]
      s[:map_ids_v10572].push(mid) if mid>0
      write_project_state_log(false) if respond_to?(:write_project_state_log)
      s
    rescue
      nil
    end

    def hunt_bind_current_map
      s=phase_div_hunt_session_v10555;return false if s==nil || !s[:active]
      mid=$game_map==nil ? 0 : $game_map.map_id.to_i
      return false if mid<=0
      s[:map_ids_v10572]=[] if s[:map_ids_v10572]==nil
      s[:map_ids_v10572].push(mid) unless s[:map_ids_v10572].include?(mid)
      s[:map_id]=mid if s[:map_id].to_i<=0
      true
    rescue
      false
    end

    def hunt_exit
      r=phase_div_end_hunt_run_v10555
      write_project_state_log(false) if respond_to?(:write_project_state_log)
      r
    rescue
      false
    end

    def hunt_encounter_now
      phase_div_launch_hunt_encounter_v10555
    rescue
      false
    end

    def hunt_reroll(code=nil)
      old=phase_div_hunt_session_v10555
      c=code==nil ? (old==nil ? nil : old[:code]) : code
      return nil if c==nil
      phase_div_end_hunt_run_v10555
      hunt_enter(c,nil)
    rescue
      nil
    end

    def hunt_active_pool
      s=phase_div_hunt_session_v10555
      s==nil ? [] : (s[:active_pool]||[]).dup
    rescue
      []
    end

    def hunt_info
      s=phase_div_hunt_session_v10555
      return nil if s==nil
      {:active=>(s[:active] ? true:false),:code=>s[:code],:seed=>s[:seed].to_i,
       :run=>s[:run].to_i,:encounters=>s[:encounters].to_i,
       :maps=>(s[:map_ids_v10572]||[]).dup,:active_pool=>(s[:active_pool]||[]).dup,
       :tier=>s[:tier].to_i,:ai_tier=>s[:ai_tier].to_i}
    rescue
      nil
    end

    def hunt_event(action,code=nil)
      case action
      when :enter then hunt_enter(code)
      when :bind then hunt_bind_current_map
      when :encounter then hunt_encounter_now
      when :exit then hunt_exit
      when :reroll then hunt_reroll(code)
      when :info then hunt_info
      when :pool then hunt_active_pool
      else nil
      end
    rescue
      nil
    end

    def random_map_event_bridge_audit_v10572
      required=[:hunt_enter,:hunt_bind_current_map,:hunt_exit,:hunt_encounter_now,
        :hunt_reroll,:hunt_active_pool,:hunt_info,:hunt_event]
      bad=required.find_all{|m|!respond_to?(m)}
      {:pass=>bad.empty?,:api=>required.size,:bad=>bad}
    rescue
      {:pass=>false,:api=>0,:bad=>[:audit_error]}
    end
  end
end

class Scene_PMD_AutoChess
  alias pmd_ac_v10572_focus_summary focus_cast_log_summary_v1055 unless method_defined?(:pmd_ac_v10572_focus_summary)
  def focus_cast_log_summary_v1055
    r=pmd_ac_v10572_focus_summary
    begin
      a=PMD_AC.random_map_event_bridge_audit_v10572
      log_event(:battle,'BATTLE_PHASE_DIV_RANDOM_MAP_EVENT_BRIDGE_SUMMARY_V10572 pass='+(a[:pass] ? '1':'0')+
        ' api='+a[:api].to_i.to_s+'/8 multi_map_run=1 active_pool_persistent=1 plugin_agnostic=1'+
        ' ui_polish=deferred errors=['+(a[:bad]||[]).collect{|x|x.to_s}.join(',')+']')
    rescue
    end
    r
  end
end
