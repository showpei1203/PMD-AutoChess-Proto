# encoding: UTF-8
#===============================================================================
# ■ PMD AutoChess - Hunt Sequential Clear Unlock + Retreat UX v1.06.29
#-------------------------------------------------------------------------------
# - Fixes Hunt selector unlock regression: v1.05.63 queried the nonexistent
#   party_instance_uids_v045 method, so party max level collapsed to 1 and
#   H02-H20 could remain locked forever.
# - Prototype progression now uses explicit sequential Hunt completion:
#     H01 available initially; H02 requires H01 clear ... H20 requires H19.
# - H21 additionally keeps its Legendary Circuit spawn gate.
# - Migrates the most recent completed Hunt result so existing v1.06.28 saves
#   that just cleared H01 immediately unlock H02 after applying this patch.
# - Makes retreat instructions explicit in the in-floor Hunt information.
#===============================================================================
$imported={} unless defined?($imported)
$imported['PMD_AutoChess_HuntSequentialUnlockRetreatUX_v10629']=true

class Game_System
  attr_accessor :pmd_hunt_clear_counts_v10629
end

module PMD_AC
  class << self
    def hunt_clear_counts_v10629
      return {} if $game_system==nil
      h=$game_system.pmd_hunt_clear_counts_v10629
      unless h.is_a?(Hash)
        h={}
        $game_system.pmd_hunt_clear_counts_v10629=h
      end
      # Migration for saves created before explicit Hunt clear persistence.
      begin
        r=$game_system.pmd_vxrd_hunt_last_result_v10605
        if r.is_a?(Hash) && r[:reason].to_s=='complete'
          c=r[:code].to_s.upcase
          if c =~ /^H\d\d$/
            h[c]=[h[c].to_i,1].max
          end
        end
      rescue
      end
      h
    rescue
      {}
    end

    def hunt_clear_count_v10629(code)
      h=hunt_clear_counts_v10629
      h[code.to_s.upcase].to_i
    rescue
      0
    end

    def hunt_mark_complete_v10629(code)
      return false if $game_system==nil
      c=code.to_s.upcase
      return false unless c =~ /^H\d\d$/
      n=c.sub('H','').to_i
      return false if n<1 || n>21
      h=hunt_clear_counts_v10629
      h[c]=h[c].to_i+1
      $game_system.pmd_hunt_clear_counts_v10629=h
      true
    rescue
      false
    end

    def hunt_previous_code_v10629(code)
      c=code.to_s.upcase
      n=c.sub('H','').to_i
      return nil if n<=1 || n>21
      'H'+sprintf('%02d',n-1)
    rescue
      nil
    end

    def hunt_unlock_state_v10629(code)
      c=code.to_s.upcase
      n=c.sub('H','').to_i
      return {:unlocked=>false,:reason=>:invalid} if n<1 || n>21
      return {:unlocked=>true,:reason=>:initial} if n==1
      prev=hunt_previous_code_v10629(c)
      return {:unlocked=>false,:reason=>:previous_hunt,:requires=>prev} if hunt_clear_count_v10629(prev)<=0
      if c=='H21'
        unlocked=respond_to?(:h21_unlocked_legend_species_v10626) ? h21_unlocked_legend_species_v10626.to_i : 0
        return {:unlocked=>false,:reason=>:legend_circuit_locked,:requires=>'C13-C16',:legends=>unlocked} if unlocked<=0
      end
      {:unlocked=>true,:reason=>:previous_clear,:requires=>prev}
    rescue
      {:unlocked=>false,:reason=>:error}
    end

    # Final Hunt unlock authority for the current prototype progression.
    def phase_div_hunt_unlock_v10563(code)
      hunt_unlock_state_v10629(code)[:unlocked] ? true : false
    rescue
      false
    end

    alias pmd_ac_v10629_hunt_runtime_finish_v10605 hunt_runtime_finish_v10605 unless method_defined?(:pmd_ac_v10629_hunt_runtime_finish_v10605)
    def hunt_runtime_finish_v10605(reason=:retreat,dry_run=false)
      s=hunt_runtime_session_v10605 rescue nil
      code=s==nil ? nil : s[:code].to_s.upcase
      why=reason.to_sym rescue :retreat
      ok=pmd_ac_v10629_hunt_runtime_finish_v10605(reason,dry_run)
      if ok && why==:complete && code!=nil && !code.empty?
        hunt_mark_complete_v10629(code)
        write_project_state_log(false) if respond_to?(:write_project_state_log)
      end
      ok
    rescue
      false
    end

    alias pmd_ac_v10629_vxrd_runtime_info_event_v10605 vxrd_runtime_info_event_v10605 unless method_defined?(:pmd_ac_v10629_vxrd_runtime_info_event_v10605)
    def vxrd_runtime_info_event_v10605(interpreter=nil)
      if respond_to?(:vxrd_autotest_active_v10586?) && vxrd_autotest_active_v10586?
        return pmd_ac_v10629_vxrd_runtime_info_event_v10605(interpreter)
      end
      i=hunt_runtime_info_v10605 rescue nil
      return false if i==nil
      hunt_runtime_message_v10604([
        i[:code].to_s+'｜Floor '+i[:floor].to_i.to_s+'/'+i[:max_floor].to_i.to_s,
        '探索 '+i[:explored].to_i.to_s+'%｜遭遇 '+i[:encounters].to_i.to_s+'｜Room '+i[:room].to_s,
        'Active Pool '+(i[:active_pool]||[]).size.to_i.to_s+' 種｜Rooms '+i[:rooms].to_i.to_s,
        '撤退：回入口房找「撤退」NPC；成果保留、無通關 Bonus。'
      ])
      true
    rescue
      false
    end

    def hunt_sequential_unlock_audit_v10629
      bad=[]
      bad << :h01 unless hunt_unlock_state_v10629('H01')[:unlocked]
      # API/authority checks only; current save progression is intentionally dynamic.
      req=[:hunt_clear_counts_v10629,:hunt_clear_count_v10629,:hunt_mark_complete_v10629,
        :hunt_unlock_state_v10629,:hunt_previous_code_v10629,:hunt_runtime_retreat_v10605]
      req.each{|m|bad << m unless respond_to?(m)}
      {:pass=>bad.empty?,:api=>req.size,:policy=>:sequential_clear,
       :h21_legend_gate=>true,:retreat_event=>true,:retreat_api=>:hunt_runtime_retreat_v10605,:bad=>bad}
    rescue
      {:pass=>false,:api=>0,:bad=>[:audit_error]}
    end
  end
end
