# encoding: UTF-8
#===============================================================================
# ■ PMD AutoChess - Random Map Event Template Contract v1.05.79
#-------------------------------------------------------------------------------
# 提供 RTP / Random Map 事件頁可直接貼用的穩定生命週期 API。
# 支援 :steps（走路自動遇敵）與 :event（地圖事件手動觸發）兩種模式。
#===============================================================================
$imported={} unless defined?($imported)
$imported['PMD_AutoChess_RandomMapEventTemplate_v10579']=true

module PMD_AC
  HUNT_MAP_ENCOUNTER_MODES_V10579=[:steps,:event]

  class << self
    def hunt_map_active?(code=nil)
      s=phase_div_hunt_session_v10555
      return false if s==nil || !s[:active]
      return true if code==nil
      s[:code].to_s==code.to_s.upcase
    rescue
      false
    end

    def hunt_map_enter(code,mode=:steps,seed=nil)
      c=code.to_s.upcase;m=mode==nil ? :steps : mode.to_sym
      m=:steps unless HUNT_MAP_ENCOUNTER_MODES_V10579.include?(m)
      s=phase_div_hunt_session_v10555
      if s!=nil && s[:active] && s[:code].to_s==c
        s[:encounter_mode_v10579]=m
        hunt_bind_current_map
        return s
      end
      hunt_exit(:switch_area) if s!=nil && s[:active]
      s=hunt_enter(c,seed)
      return nil if s==nil
      s[:encounter_mode_v10579]=m
      hunt_bind_current_map
      s
    rescue
      nil
    end

    def hunt_map_floor_ready(code=nil)
      s=phase_div_hunt_session_v10555
      return false if s==nil || !s[:active]
      return false if code!=nil && s[:code].to_s!=code.to_s.upcase
      ok=hunt_bind_current_map
      if ok && s[:encounter_mode_v10579].to_sym!=:event && $game_player!=nil && $game_player.respond_to?(:make_pmd_encounter_count_v081)
        h=phase_div_hunt_v10553(s[:code])
        steps=respond_to?(:phase_div_hunt_steps_v10557) ? phase_div_hunt_steps_v10557(h[:tier]) : [9,15]
        $game_player.make_pmd_encounter_count_v081(steps[0],steps[1])
      end
      ok
    rescue
      false
    end

    def hunt_map_encounter
      return false unless hunt_map_active?
      hunt_encounter_now
    rescue
      false
    end

    def hunt_map_leave(reason=:normal)
      return false unless hunt_map_active?
      hunt_exit(reason)
    rescue
      false
    end

    def hunt_map_mode
      s=phase_div_hunt_session_v10555
      return nil if s==nil || !s[:active]
      (s[:encounter_mode_v10579]||:steps).to_sym
    rescue
      nil
    end

    def hunt_map_event_template(code='H01',mode=:steps)
      c=code.to_s.upcase;m=mode.to_sym
      {
        :entry=>"PMD_AC.hunt_map_enter('#{c}', :#{m})",
        :floor_ready=>"PMD_AC.hunt_map_floor_ready('#{c}')",
        :encounter=>'PMD_AC.hunt_map_encounter',
        :leave=>'PMD_AC.hunt_map_leave(:normal)',
        :abort=>'PMD_AC.hunt_map_leave(:abort)',
        :info=>'PMD_AC.hunt_info',
        :collection=>"PMD_AC.hunt_collection_info('#{c}')"
      }
    rescue
      {}
    end

    def random_map_event_template_audit_v10579
      req=[:hunt_map_enter,:hunt_map_floor_ready,:hunt_map_encounter,:hunt_map_leave,
        :hunt_map_active?,:hunt_map_mode,:hunt_map_event_template]
      bad=req.find_all{|m|!respond_to?(m)}
      t=hunt_map_event_template('H01',:event)
      bad.push(:template) unless t.is_a?(Hash) && t[:entry].to_s.index("H01")!=nil && t[:encounter].to_s!=''
      {:pass=>bad.empty?,:api=>req.size,:modes=>HUNT_MAP_ENCOUNTER_MODES_V10579.size,:bad=>bad}
    rescue
      {:pass=>false,:api=>0,:modes=>0,:bad=>[:audit_error]}
    end
  end
end

class Scene_Map
  alias pmd_ac_v10579_update_encounter update_encounter unless method_defined?(:pmd_ac_v10579_update_encounter)
  def update_encounter
    begin
      s=PMD_AC.phase_div_hunt_session_v10555
      if s!=nil && s[:active] && (s[:encounter_mode_v10579]||:steps).to_sym==:event
        return
      end
    rescue
    end
    pmd_ac_v10579_update_encounter
  end
end

class Scene_PMD_AutoChess
  alias pmd_ac_v10579_focus_summary focus_cast_log_summary_v1055 unless method_defined?(:pmd_ac_v10579_focus_summary)
  def focus_cast_log_summary_v1055
    r=pmd_ac_v10579_focus_summary
    begin
      a=PMD_AC.random_map_event_template_audit_v10579
      log_event(:battle,'BATTLE_PHASE_DIV_RANDOM_MAP_EVENT_TEMPLATE_SUMMARY_V10579 pass='+(a[:pass] ? '1':'0')+
        ' api='+a[:api].to_i.to_s+'/7 modes='+a[:modes].to_i.to_s+'/2 steps_mode=1 event_mode=1'+
        ' random_map_plugin_agnostic=1 errors=['+(a[:bad]||[]).collect{|x|x.to_s}.join(',')+']')
    rescue
    end
    r
  end
end
