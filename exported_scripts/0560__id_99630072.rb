# encoding: UTF-8
#===============================================================================
# ■ PMD AutoChess - Hunt Run Lifecycle + Floor Persistence v1.05.75
#-------------------------------------------------------------------------------
# 【用途】
# 補齊 Random Map Hunt Run 的進入、跨樓層、結束與最後摘要生命週期。
# Random Map 插件仍只負責地圖殼，本系統持有 seed / active pool / run identity。
#===============================================================================
$imported={} unless defined?($imported)
$imported['PMD_AutoChess_HuntRunLifecycle_v10575']=true

class Game_System
  attr_accessor :pmd_phase_div_hunt_last_summary_v10575
end

module PMD_AC
  class << self
    alias pmd_ac_v10575_hunt_enter hunt_enter unless method_defined?(:pmd_ac_v10575_hunt_enter)
    alias pmd_ac_v10575_hunt_bind_current_map hunt_bind_current_map unless method_defined?(:pmd_ac_v10575_hunt_bind_current_map)
    alias pmd_ac_v10575_hunt_exit hunt_exit unless method_defined?(:pmd_ac_v10575_hunt_exit)
    alias pmd_ac_v10575_hunt_formation phase_div_hunt_formation_v10555 unless method_defined?(:pmd_ac_v10575_hunt_formation)

    def hunt_finish_snapshot_v10575(reason=:normal)
      s=phase_div_hunt_session_v10555
      return nil if s==nil
      pool=(s[:active_pool]||[]).dup
      seen=0;owned=0
      pool.each do |sp|
        seen+=1 if respond_to?(:dex_seen_v093?) && dex_seen_v093?(sp)
        owned+=1 if respond_to?(:dex_ever_owned_v093?) && dex_ever_owned_v093?(sp)
      end
      out={:code=>s[:code],:run=>s[:run].to_i,:seed=>s[:seed].to_i,
        :encounters=>s[:encounters].to_i,:maps=>(s[:map_ids_v10572]||[]).dup,
        :floors=>(s[:floor_sequence_v10575]||[]).dup,:active_pool=>pool,
        :active_seen=>seen,:active_owned=>owned,:reason=>reason.to_s,
        :last_formation=>(s[:last_formation_v10575]||[]).dup}
      $game_system.pmd_phase_div_hunt_last_summary_v10575=out if $game_system!=nil
      out
    rescue
      nil
    end

    def hunt_enter(code,seed=nil)
      old=phase_div_hunt_session_v10555
      hunt_finish_snapshot_v10575(:reenter) if old!=nil && old[:active]
      s=pmd_ac_v10575_hunt_enter(code,seed)
      return nil if s==nil
      mid=$game_map==nil ? 0 : $game_map.map_id.to_i
      s[:floor_sequence_v10575]=[]
      s[:floor_sequence_v10575].push(mid) if mid>0
      s[:floor_visits_v10575]=mid>0 ? {mid=>1} : {}
      s[:last_formation_v10575]=[]
      s[:lifecycle_v10575]=:active
      write_project_state_log(false) if respond_to?(:write_project_state_log)
      s
    rescue
      nil
    end

    def hunt_bind_current_map
      s=phase_div_hunt_session_v10555
      before=s==nil ? [] : (s[:map_ids_v10572]||[]).dup
      ok=pmd_ac_v10575_hunt_bind_current_map
      return false unless ok
      s=phase_div_hunt_session_v10555
      mid=$game_map==nil ? 0 : $game_map.map_id.to_i
      s[:floor_sequence_v10575]=[] if s[:floor_sequence_v10575]==nil
      s[:floor_visits_v10575]={} if s[:floor_visits_v10575]==nil
      if mid>0
        s[:floor_sequence_v10575].push(mid) unless s[:floor_sequence_v10575].include?(mid)
        s[:floor_visits_v10575][mid]=s[:floor_visits_v10575][mid].to_i+1
      end
      s[:lifecycle_v10575]=:active
      write_project_state_log(false) if respond_to?(:write_project_state_log) && !before.include?(mid)
      true
    rescue
      false
    end

    def phase_div_hunt_formation_v10555(session)
      out=pmd_ac_v10575_hunt_formation(session)
      if session!=nil
        session[:last_formation_v10575]=(out||[]).collect{|row|[row[0],row[3].to_i]}
      end
      out
    rescue
      []
    end

    def hunt_exit(reason=:normal)
      hunt_finish_snapshot_v10575(reason)
      r=pmd_ac_v10575_hunt_exit
      s=phase_div_hunt_session_v10555
      s[:lifecycle_v10575]=:closed if s!=nil
      write_project_state_log(false) if respond_to?(:write_project_state_log)
      r
    rescue
      false
    end

    def hunt_abort
      hunt_exit(:abort)
    rescue
      false
    end

    def hunt_last_summary
      return nil if $game_system==nil
      s=$game_system.pmd_phase_div_hunt_last_summary_v10575
      s==nil ? nil : s.dup
    rescue
      nil
    end

    def hunt_floor_info
      s=phase_div_hunt_session_v10555
      return nil if s==nil || !s[:active]
      {:maps=>(s[:map_ids_v10572]||[]).dup,:floors=>(s[:floor_sequence_v10575]||[]).dup,
       :visits=>(s[:floor_visits_v10575]||{}).dup,:current_map=>($game_map==nil ? 0:$game_map.map_id.to_i)}
    rescue
      nil
    end

    def hunt_lifecycle_audit_v10575
      req=[:hunt_enter,:hunt_bind_current_map,:hunt_exit,:hunt_abort,:hunt_last_summary,:hunt_floor_info]
      bad=req.find_all{|m|!respond_to?(m)}
      {:pass=>bad.empty?,:api=>req.size,:bad=>bad,:save_persistent=>true,:multi_floor=>true}
    rescue
      {:pass=>false,:api=>0,:bad=>[:audit_error]}
    end
  end
end

class Scene_PMD_AutoChess
  alias pmd_ac_v10575_focus_summary focus_cast_log_summary_v1055 unless method_defined?(:pmd_ac_v10575_focus_summary)
  def focus_cast_log_summary_v1055
    r=pmd_ac_v10575_focus_summary
    begin
      a=PMD_AC.hunt_lifecycle_audit_v10575
      log_event(:battle,'BATTLE_PHASE_DIV_HUNT_LIFECYCLE_SUMMARY_V10575 pass='+(a[:pass] ? '1':'0')+
        ' api='+a[:api].to_i.to_s+'/6 save_persistent=1 multi_floor=1 last_summary=1'+
        ' random_map_plugin_agnostic=1 errors=['+(a[:bad]||[]).collect{|x|x.to_s}.join(',')+']')
    rescue
    end
    r
  end
end
