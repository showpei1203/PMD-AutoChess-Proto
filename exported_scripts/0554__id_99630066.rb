# encoding: UTF-8
#===============================================================================
# ■ PMD AutoChess - Weather Maintenance Decision Audit v1.05.69
#-------------------------------------------------------------------------------
# 【用途】
# 釐清天氣技能的 AI 選擇時點。v0.69 已有「相同天氣仍有效時降權」正式規則；
# 本版不再疊加另一套分數，而是記錄選擇天氣技當下：目前天氣、剩餘 frames、
# 是否同天氣仍有效、以及該單位四招 loadout。只增加診斷，不改正式 AI。
#===============================================================================
$imported={} unless defined?($imported)
$imported['PMD_AutoChess_WeatherMaintenanceDecisionAudit_v10569']=true

module PMD_AC
  class << self
    def weather_from_skill_data_v10569(data)
      return nil if data==nil
      for e in (data[:effects]||[])
        t=e[:type];t=t.to_sym if t.is_a?(String)
        if t==:set_weather
          w=e[:weather];w=w.to_sym if w.is_a?(String)
          return w
        end
      end
      nil
    rescue
      nil
    end

    def weather_maintenance_audit_v10569
      factor=nil
      begin
        factor=COMBAT_AI_TUNING_V069[:active_weather_score_factor].to_f
      rescue
        factor=nil
      end
      frames=defined?(WEATHER_TURN_FRAMES) ? WEATHER_TURN_FRAMES.to_i : 0
      ok=factor!=nil && factor>0.0 && factor<0.5 && frames>0
      {:pass=>ok,:existing_factor=>factor,:turn_frames=>frames,:observer_only=>true}
    rescue
      {:pass=>false,:existing_factor=>nil,:turn_frames=>0,:observer_only=>true}
    end
  end
end

class Scene_PMD_AutoChess
  alias pmd_ac_v10569_select_best_move progression_select_best_move_v046 unless method_defined?(:pmd_ac_v10569_select_best_move)
  alias pmd_ac_v10569_focus_summary focus_cast_log_summary_v1055 unless method_defined?(:pmd_ac_v10569_focus_summary)

  def progression_select_best_move_v046(unit)
    r=pmd_ac_v10569_select_best_move(unit)
    begin
      if r!=nil && r[0]!=nil && unit!=nil && unit.respond_to?(:skill_data)
        data=unit.skill_data
        weather=PMD_AC.weather_from_skill_data_v10569(data)
        if weather!=nil
          effective=respond_to?(:canonical_weather_effective?) && canonical_weather_effective?(weather)
          current=respond_to?(:canonical_weather) ? canonical_weather : nil
          frames=respond_to?(:canonical_weather_frames) ? canonical_weather_frames.to_i : 0
          permanent=respond_to?(:canonical_weather_permanent?) && canonical_weather_permanent?
          pool=unit.respond_to?(:progression_move_pool_v046) ? unit.progression_move_pool_v046 : []
          key=[unit.object_id,r[0],current,frames/30,effective ? 1:0]
          old=unit.instance_variable_get(:@weather_decision_log_key_v10569)
          if old!=key
            unit.instance_variable_set(:@weather_decision_log_key_v10569,key)
            log_event(:combat_ai,'WEATHER_DECISION_V10569 '+unit.log_name+
              ' move='+r[0].to_s+' requested='+weather.to_s+' current='+(current==nil ? 'none':current.to_s)+
              ' same_effective='+(effective ? '1':'0')+' frames='+frames.to_s+
              ' permanent='+(permanent ? '1':'0')+' score='+sprintf('%.2f',r[2].to_f)+
              ' active=['+pool.collect{|x|x.to_s}.join(',')+'] observer_only=1')
          end
        end
      end
    rescue
    end
    r
  end

  def focus_cast_log_summary_v1055
    r=pmd_ac_v10569_focus_summary
    begin
      a=PMD_AC.weather_maintenance_audit_v10569
      f=a[:existing_factor]
      log_event(:battle,'BATTLE_WEATHER_MAINTENANCE_DECISION_AUDIT_SUMMARY_V10569 pass='+(a[:pass] ? '1':'0')+
        ' existing_same_weather_factor='+(f==nil ? 'NA':sprintf('%.2f',f.to_f))+
        ' weather_turn_frames='+a[:turn_frames].to_i.to_s+
        ' observer_only=1 ai_behavior_change=0')
    rescue
    end
    r
  end
end
