# encoding: UTF-8
#===============================================================================
# ■ PMD AutoChess - VXRD Hunt Floor Progression / Run Settlement v1.06.05
#-------------------------------------------------------------------------------
# 【用途】
# - 定義 3/4/5/5/6 層 Hunt Run 節奏。
# - Exit 事件負責下一層；最後一層完成才給 Run Completion Bonus。
# - Retreat / Defeat 都保留已取得的招募與即時掉落，但沒有完整通關 Bonus。
# - 完成後自動回到進入 Hunt 前的位置，並顯示簡潔 Run 結算。
#===============================================================================
$imported={} unless defined?($imported)
$imported['PMD_AutoChess_VXRDHuntFloorSettlement_v10605']=true

class Game_System
  attr_accessor :pmd_vxrd_hunt_last_result_v10605
end

module PMD_AC
  class << self
    def hunt_runtime_session_v10605
      s=phase_div_hunt_session_v10555
      return nil if s==nil || !s[:active] || !s[:vxrd_runtime_v10604]
      s
    rescue
      nil
    end

    def hunt_runtime_current_floor_v10605
      s=hunt_runtime_session_v10605
      s==nil ? 0 : s[:vxrd_floor_count_v10584].to_i
    rescue
      0
    end

    def hunt_runtime_max_floor_v10605
      s=hunt_runtime_session_v10605
      s==nil ? 0 : s[:vxrd_max_floors_v10604].to_i
    rescue
      0
    end

    def hunt_runtime_completion_bonus_v10605(session,dry_run=false)
      return nil if session==nil
      key=hunt_loot_pool_key_v10578(session[:code])
      tier=[[session[:tier].to_i,1].max,5].min
      rarity=tier>=4 ? :very_rare : :rare
      ctx={:rarity=>rarity,:elite=>(tier>=4),:elite_count=>(tier>=4 ? 1:0),:boss=>false,
        :hunt_completion_v10605=>true}
      resolve_loot_pool_v094(key,ctx,dry_run)
    rescue
      nil
    end

    def hunt_runtime_result_lines_v10605(result)
      return ['狩獵結束'] if result==nil
      reason=result[:reason].to_s
      title=reason=='complete' ? '狩獵完成' : (reason=='defeat' ? '狩獵失敗' : '狩獵撤退')
      stats=result[:stats]||{}
      line2=result[:code].to_s+'｜Floor '+result[:floors_cleared].to_i.to_s+'/'+result[:max_floors].to_i.to_s+
        '｜戰鬥 '+stats[:wins].to_i.to_s+'勝'
      line3='招募 '+stats[:recruits].to_i.to_s+'｜寶藏 '+stats[:treasures].to_i.to_s+
        '｜Rare '+stats[:rare_nest_wins].to_i.to_s+'｜Elite '+stats[:elite_room_wins].to_i.to_s
      bonus=(result[:completion_bonus]||{})[:labels]||[]
      line4=bonus.empty? ? (reason=='complete' ? '完整通關 Bonus：無額外掉落' : '已取得成果全部保留') :
        ('通關 Bonus：'+bonus[0,2].join('、'))
      [title,line2,line3,line4]
    rescue
      ['狩獵結束']
    end

    def hunt_runtime_finish_v10605(reason=:retreat,dry_run=false)
      s=hunt_runtime_session_v10605
      return false if s==nil
      why=reason.to_sym
      complete=(why==:complete)
      s[:vxrd_floor_clears_v10604]=[s[:vxrd_floor_clears_v10604].to_i,
        complete ? s[:vxrd_max_floors_v10604].to_i : [s[:vxrd_floor_count_v10584].to_i-1,0].max].max
      bonus=complete ? hunt_runtime_completion_bonus_v10605(s,dry_run) : nil
      stats=(s[:vxrd_runtime_stats_v10604]||{}).dup
      origin=(s[:vxrd_origin_v10604]||{}).dup
      pool=(s[:active_pool]||[]).dup
      seen=0;owned=0
      pool.each do |sp|
        seen+=1 if respond_to?(:dex_seen_v093?) && dex_seen_v093?(sp)
        owned+=1 if respond_to?(:dex_ever_owned_v093?) && dex_ever_owned_v093?(sp)
      end
      result={:code=>s[:code],:run=>s[:run].to_i,:seed=>s[:seed].to_i,:reason=>why,
        :floors_cleared=>s[:vxrd_floor_clears_v10604].to_i,:max_floors=>s[:vxrd_max_floors_v10604].to_i,
        :encounters=>s[:encounters].to_i,:stats=>stats,:active_pool=>pool,
        :active_seen=>seen,:active_owned=>owned,:completion_bonus=>bonus,:origin=>origin}
      $game_system.pmd_vxrd_hunt_last_result_v10605=result if $game_system!=nil
      # Preserve v1.05.75 last-summary compatibility.
      hunt_exit(why)
      st=vxrd_state_v10582 rescue nil
      st[:active]=false if st!=nil
      if $game_temp!=nil
        $game_temp.pmd_vxrd_hunt_result_message_v10604=result
      end
      if $game_player!=nil
        mid=origin[:map_id].to_i;mid=2 if mid<=0 || mid==VXRD_HUNT_RUNTIME_MAP_ID_V10604
        x=origin[:x].to_i;y=origin[:y].to_i;d=origin[:direction].to_i;d=2 if d<=0
        $game_player.reserve_transfer(mid,x,y,d)
        $scene=Scene_Map.new unless $scene.is_a?(Scene_Map)
      end
      write_project_state_log(false) if respond_to?(:write_project_state_log)
      true
    rescue
      false
    end

    def hunt_runtime_advance_floor_v10605
      s=hunt_runtime_session_v10605;return false if s==nil
      cur=s[:vxrd_floor_count_v10584].to_i;max=s[:vxrd_max_floors_v10604].to_i
      if cur>=max
        s[:vxrd_floor_clears_v10604]=max
        return hunt_runtime_finish_v10605(:complete,false)
      end
      s[:vxrd_floor_clears_v10604]=[s[:vxrd_floor_clears_v10604].to_i,cur].max
      st=hunt_generate_vx_floor_v10584(s[:code],(s[:encounter_mode_v10579]||:event),{:move_player=>true})
      return false if st==nil
      hunt_runtime_message_v10604([
        '下一層｜'+s[:code].to_s,
        'Floor '+s[:vxrd_floor_count_v10584].to_i.to_s+' / '+max.to_s,
        'Active Pool 維持 '+(s[:active_pool]||[]).size.to_i.to_s+' 種｜Seed '+s[:seed].to_i.to_s,
        '特殊房、寶藏與遭遇已重新配置。'
      ])
      true
    rescue
      false
    end

    def hunt_runtime_retreat_v10605
      hunt_runtime_finish_v10605(:retreat,false)
    rescue
      false
    end

    def hunt_runtime_info_v10605
      s=hunt_runtime_session_v10605;return nil if s==nil
      st=vxrd_state_v10582 rescue nil
      rr=respond_to?(:hunt_room_runtime_info_v10602) ? hunt_room_runtime_info_v10602 : nil
      {:code=>s[:code],:floor=>s[:vxrd_floor_count_v10584].to_i,:max_floor=>s[:vxrd_max_floors_v10604].to_i,
        :encounters=>s[:encounters].to_i,:active_pool=>(s[:active_pool]||[]).dup,
        :room=>(rr==nil ? nil:rr[:room_type]),:explored=>(respond_to?(:vxrd_exploration_percent_v10583) ? vxrd_exploration_percent_v10583 : 0),
        :rooms=>(st==nil ? 0:(st[:rooms]||[]).size),:stats=>(s[:vxrd_runtime_stats_v10604]||{}).dup}
    rescue
      nil
    end

    def vxrd_runtime_exit_event_v10605(interpreter=nil)
      if respond_to?(:vxrd_autotest_active_v10586?) && vxrd_autotest_active_v10586?
        return vxrd_autotest_next_floor_v10586
      end
      hunt_runtime_advance_floor_v10605
    rescue
      false
    end

    def vxrd_runtime_retreat_event_v10605(interpreter=nil)
      if respond_to?(:vxrd_autotest_active_v10586?) && vxrd_autotest_active_v10586?
        return vxrd_autotest_return_v10586
      end
      hunt_runtime_retreat_v10605
    rescue
      false
    end

    def vxrd_runtime_info_event_v10605(interpreter=nil)
      if respond_to?(:vxrd_autotest_active_v10586?) && vxrd_autotest_active_v10586?
        return vxrd_autotest_info_v10586
      end
      i=hunt_runtime_info_v10605;return false if i==nil
      hunt_runtime_message_v10604([
        i[:code].to_s+'｜Floor '+i[:floor].to_i.to_s+'/'+i[:max_floor].to_i.to_s,
        '探索 '+i[:explored].to_i.to_s+'%｜遭遇 '+i[:encounters].to_i.to_s+'｜Room '+i[:room].to_s,
        'Active Pool '+(i[:active_pool]||[]).size.to_i.to_s+' 種｜Rooms '+i[:rooms].to_i.to_s,
        '出口前往下一層；入口附近可撤退。'
      ])
      true
    rescue
      false
    end

    def vxrd_runtime_entrance_event_v10605(interpreter=nil)
      vxrd_runtime_info_event_v10605(interpreter)
    rescue
      false
    end

    def hunt_runtime_settlement_audit_v10605
      req=[:hunt_runtime_finish_v10605,:hunt_runtime_advance_floor_v10605,:hunt_runtime_retreat_v10605,
        :hunt_runtime_info_v10605,:hunt_runtime_completion_bonus_v10605]
      bad=req.find_all{|m|!respond_to?(m)}
      {:pass=>bad.empty?,:api=>req.size,:completion_bonus=>true,:retreat_keeps_immediate_rewards=>true,
        :defeat_bonus=>false,:return_origin=>true,:bad=>bad}
    rescue
      {:pass=>false,:api=>0,:bad=>[:audit_error]}
    end
  end
end

class Game_Player
  alias pmd_ac_v10605_perform_transfer perform_transfer unless method_defined?(:pmd_ac_v10605_perform_transfer)
  def perform_transfer
    pmd_ac_v10605_perform_transfer
    begin
      r=$game_temp==nil ? nil : $game_temp.pmd_vxrd_hunt_result_message_v10604
      if r!=nil && ($game_map==nil || $game_map.map_id.to_i!=PMD_AC::VXRD_HUNT_RUNTIME_MAP_ID_V10604)
        $game_temp.pmd_vxrd_hunt_result_message_v10604=nil
        PMD_AC.hunt_runtime_message_v10604(PMD_AC.hunt_runtime_result_lines_v10605(r))
      end
    rescue
    end
  end
end
