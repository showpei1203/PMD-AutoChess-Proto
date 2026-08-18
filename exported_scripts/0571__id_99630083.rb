# encoding: UTF-8
#===============================================================================
# ■ PMD AutoChess - VXRD Dedicated AutoTest Harness v1.05.86
#-------------------------------------------------------------------------------
# Dedicated hidden Map090 test harness for VX-native random dungeon generation.
# Can be launched from any VX event with one line or from the built-in menu.
#===============================================================================
$imported={} unless defined?($imported)
$imported['PMD_AutoChess_VXRDAutoTestHarness_v10586']=true

class Game_System
  attr_accessor :pmd_vxrd_autotest_state_v10586
  attr_accessor :pmd_vxrd_autotest_last_v10586
end

class Game_Temp
  attr_accessor :pmd_vxrd_autotest_pending_v10586
end

module PMD_AC
  VXRD_AUTOTEST_MAP_ID_V10586=90
  VXRD_AUTOTEST_LOG_V10586='PMD_VXRD_AutoTest_LATEST.log'
  VXRD_AUTOTEST_DEFAULT_SEED_V10586=1058601

  class << self
    def vxrd_autotest_presets_v10586
      [
        {:label=>'H01 林緣｜事件遭遇',:code=>'H01',:mode=>:event,:seed=>1058601},
        {:label=>'H02 苔溪｜水域 Palette',:code=>'H02',:mode=>:event,:seed=>1058602},
        {:label=>'H03 風丘｜天空 Palette',:code=>'H03',:mode=>:event,:seed=>1058603},
        {:label=>'H04 赤岩｜山地 Palette',:code=>'H04',:mode=>:event,:seed=>1058604},
        {:label=>'H05 月影｜神秘 Palette',:code=>'H05',:mode=>:event,:seed=>1058605},
        {:label=>'H01 林緣｜步數遭遇',:code=>'H01',:mode=>:steps,:seed=>1058611}
      ]
    end

    def vxrd_autotest_state_v10586
      return nil if $game_system==nil
      $game_system.pmd_vxrd_autotest_state_v10586
    rescue
      nil
    end

    def vxrd_autotest_active_v10586?
      s=vxrd_autotest_state_v10586
      s!=nil && s[:active] && $game_map!=nil && $game_map.map_id.to_i==VXRD_AUTOTEST_MAP_ID_V10586
    rescue
      false
    end

    def vxrd_autotest_message_v10586(lines)
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

    def write_vxrd_autotest_log_v10586(action,extra=nil)
      s=vxrd_autotest_state_v10586 || {}
      f=respond_to?(:hunt_vx_floor_info_v10584) ? hunt_vx_floor_info_v10584 : nil
      lines=[]
      lines << 'PMD VXRD AutoTest'
      lines << 'VERSION='+project_version.to_s
      lines << 'ACTION='+action.to_s
      lines << 'ACTIVE='+(s[:active] ? '1':'0')
      lines << 'TEST_MAP_ID='+VXRD_AUTOTEST_MAP_ID_V10586.to_s
      lines << 'CODE='+s[:code].to_s
      lines << 'MODE='+s[:mode].to_s
      lines << 'SEED='+s[:seed].to_i.to_s
      lines << 'FLOORS='+s[:floors].to_i.to_s
      lines << 'ENCOUNTER_NODES='+s[:encounter_nodes].to_i.to_s
      lines << 'TREASURE_NODES='+s[:treasure_nodes].to_i.to_s
      lines << 'RETURN_MAP='+s[:return_map_id].to_i.to_s
      if f!=nil
        lines << 'MAP_ID='+f[:map_id].to_i.to_s
        lines << 'FLOOR='+f[:floor].to_i.to_s
        lines << 'FLOOR_SEED='+f[:seed].to_i.to_s
        lines << 'PALETTE='+((f[:palette]||{})[:index]||-1).to_i.to_s
        lines << 'ROOMS='+f[:rooms].to_i.to_s
        lines << 'EDGES='+f[:edges].to_i.to_s
        lines << 'WALKABLE='+f[:walkable].to_i.to_s
        lines << 'EXPLORED='+f[:explored].to_i.to_s
        er=f[:event_relocate]||{}
        lines << 'EVENT_RELOCATE_PASS='+(er[:pass] ? '1':'0')
        lines << 'EVENT_RELOCATED='+er[:moved].to_i.to_s
        lines << 'EVENT_COUNTS='+(er[:counts]||{}).inspect
      end
      lines << 'EXTRA='+extra.inspect if extra!=nil
      File.open(VXRD_AUTOTEST_LOG_V10586,'wb'){|io|io.write(lines.join("\r\n")+"\r\n")}
      true
    rescue
      false
    end

    def run_vxrd_auto_test_v10586(code='H01',mode=:event,seed=VXRD_AUTOTEST_DEFAULT_SEED_V10586)
      return false if $game_map==nil || $game_player==nil || $game_system==nil || $game_temp==nil
      c=code.to_s.upcase
      m=mode==nil ? :event : mode.to_sym
      m=:event unless [:event,:steps].include?(m)
      # Preserve the real play position. Re-launching while already in Map090 does not overwrite it.
      old=vxrd_autotest_state_v10586
      if old!=nil && old[:active] && $game_map.map_id.to_i==VXRD_AUTOTEST_MAP_ID_V10586
        return vxrd_autotest_restart_v10586(c,m,seed)
      end
      state={:active=>true,:code=>c,:mode=>m,:seed=>seed.to_i,
        :floors=>0,:encounter_nodes=>0,:treasure_nodes=>0,
        :return_map_id=>$game_map.map_id.to_i,:return_x=>$game_player.x.to_i,
        :return_y=>$game_player.y.to_i,:return_direction=>$game_player.direction.to_i,
        :started_frame=>Graphics.frame_count.to_i}
      $game_system.pmd_vxrd_autotest_state_v10586=state
      $game_temp.pmd_vxrd_autotest_pending_v10586={:code=>c,:mode=>m,:seed=>seed.to_i}
      $game_player.reserve_transfer(VXRD_AUTOTEST_MAP_ID_V10586,30,22,2)
      $scene=Scene_Map.new unless $scene.is_a?(Scene_Map)
      write_vxrd_autotest_log_v10586(:launch)
      true
    rescue
      false
    end

    def vxrd_autotest_restart_v10586(code='H01',mode=:event,seed=VXRD_AUTOTEST_DEFAULT_SEED_V10586)
      s=vxrd_autotest_state_v10586;return false if s==nil
      c=code.to_s.upcase;m=mode.to_sym;m=:event unless [:event,:steps].include?(m)
      hunt_map_leave(:autotest_restart) if respond_to?(:hunt_map_active?) && hunt_map_active?
      s[:code]=c;s[:mode]=m;s[:seed]=seed.to_i;s[:floors]=0;s[:encounter_nodes]=0;s[:treasure_nodes]=0
      $game_temp.pmd_vxrd_autotest_pending_v10586={:code=>c,:mode=>m,:seed=>seed.to_i}
      vxrd_autotest_generate_after_transfer_v10586
      true
    rescue
      false
    end

    def vxrd_autotest_generate_after_transfer_v10586
      return false if $game_map==nil || $game_map.map_id.to_i!=VXRD_AUTOTEST_MAP_ID_V10586
      p=$game_temp==nil ? nil : $game_temp.pmd_vxrd_autotest_pending_v10586
      s=vxrd_autotest_state_v10586
      return false if p==nil || s==nil
      $game_temp.pmd_vxrd_autotest_pending_v10586=nil
      hunt_map_leave(:autotest_rebuild) if respond_to?(:hunt_map_active?) && hunt_map_active?
      hunt_map_enter(p[:code],p[:mode],p[:seed])
      st=hunt_generate_vx_floor_v10584(p[:code],p[:mode],{:move_player=>true})
      return false if st==nil
      s[:floors]=1
      s[:code]=p[:code];s[:mode]=p[:mode];s[:seed]=p[:seed].to_i
      s[:active]=true
      write_vxrd_autotest_log_v10586(:generated)
      info=hunt_vx_floor_info_v10584
      vxrd_autotest_message_v10586([
        'VX 隨機地圖測試已建立',
        p[:code].to_s+' / '+p[:mode].to_s+' / Seed '+p[:seed].to_i.to_s,
        '房間 '+info[:rooms].to_i.to_s+'｜通路 '+info[:edges].to_i.to_s+'｜Palette '+((info[:palette]||{})[:index]||-1).to_i.to_s,
        '找地圖角色測 Encounter / Treasure / Next Floor'
      ]) if info!=nil
      true
    rescue
      false
    end

    def vxrd_autotest_next_floor_v10586
      return false unless vxrd_autotest_active_v10586?
      s=vxrd_autotest_state_v10586
      st=hunt_generate_vx_floor_v10584(s[:code],s[:mode],{:move_player=>true})
      return false if st==nil
      s[:floors]=s[:floors].to_i+1
      write_vxrd_autotest_log_v10586(:next_floor)
      info=hunt_vx_floor_info_v10584
      vxrd_autotest_message_v10586(['下一層生成完成','Floor '+s[:floors].to_i.to_s+' / Seed '+(info==nil ? '0' : info[:seed].to_i.to_s),
        'Rooms '+(info==nil ? '0' : info[:rooms].to_i.to_s)+' / Walkable '+(info==nil ? '0' : info[:walkable].to_i.to_s)])
      true
    rescue
      false
    end

    def vxrd_autotest_encounter_v10586
      return false unless vxrd_autotest_active_v10586?
      s=vxrd_autotest_state_v10586
      s[:encounter_nodes]=s[:encounter_nodes].to_i+1
      write_vxrd_autotest_log_v10586(:encounter_node)
      if respond_to?(:hunt_map_active?) && hunt_map_active?
        return hunt_map_encounter
      end
      vxrd_autotest_message_v10586(['目前 Hunt Session 不可用','此節點只測地圖配置。'])
      false
    rescue
      false
    end

    def vxrd_autotest_treasure_v10586
      return false unless vxrd_autotest_active_v10586?
      s=vxrd_autotest_state_v10586
      s[:treasure_nodes]=s[:treasure_nodes].to_i+1
      eco=respond_to?(:hunt_economy_info) ? hunt_economy_info(s[:code]) : nil
      write_vxrd_autotest_log_v10586(:treasure_node,eco)
      if eco!=nil
        vxrd_autotest_message_v10586(['Treasure Node #'+s[:treasure_nodes].to_i.to_s,
          '區域 '+s[:code].to_s+'｜Tier '+eco[:tier].to_i.to_s+'｜'+eco[:biome].to_s,
          '基本 Roll '+eco[:base_rolls].to_i.to_s+'｜Gold '+eco[:gold].inspect,
          '測試節點不實際發獎，避免污染存檔。'])
      else
        vxrd_autotest_message_v10586(['Treasure Node #'+s[:treasure_nodes].to_i.to_s,'Economy data unavailable'])
      end
      true
    rescue
      false
    end

    def vxrd_autotest_info_v10586
      return false unless vxrd_autotest_active_v10586?
      s=vxrd_autotest_state_v10586;f=hunt_vx_floor_info_v10584
      write_vxrd_autotest_log_v10586(:info)
      vxrd_autotest_message_v10586([
        'VXRD AutoTest｜'+s[:code].to_s+' '+s[:mode].to_s,
        'Floor '+s[:floors].to_i.to_s+'｜Seed '+(f==nil ? s[:seed].to_i.to_s : f[:seed].to_i.to_s),
        'Rooms '+(f==nil ? '0' : f[:rooms].to_i.to_s)+'｜Edges '+(f==nil ? '0' : f[:edges].to_i.to_s)+'｜Explore '+(f==nil ? '0' : f[:explored].to_i.to_s)+'%',
        'Encounter '+s[:encounter_nodes].to_i.to_s+'｜Treasure '+s[:treasure_nodes].to_i.to_s
      ])
      true
    rescue
      false
    end

    def vxrd_autotest_return_v10586
      s=vxrd_autotest_state_v10586;return false if s==nil || $game_player==nil
      write_vxrd_autotest_log_v10586(:return)
      hunt_map_leave(:autotest_return) if respond_to?(:hunt_map_active?) && hunt_map_active?
      st=vxrd_state_v10582 if respond_to?(:vxrd_state_v10582)
      st[:active]=false if st!=nil
      $game_system.pmd_vxrd_autotest_last_v10586=s.dup if $game_system!=nil
      mid=s[:return_map_id].to_i;mid=2 if mid<=0 || mid==VXRD_AUTOTEST_MAP_ID_V10586
      x=s[:return_x].to_i;y=s[:return_y].to_i;d=s[:return_direction].to_i;d=2 if d<=0
      s[:active]=false
      $game_player.reserve_transfer(mid,x,y,d)
      true
    rescue
      false
    end

    def vxrd_autotest_audit_v10586
      req=[:run_vxrd_auto_test_v10586,:vxrd_autotest_next_floor_v10586,
        :vxrd_autotest_encounter_v10586,:vxrd_autotest_treasure_v10586,
        :vxrd_autotest_info_v10586,:vxrd_autotest_return_v10586,
        :vxrd_autotest_presets_v10586,:write_vxrd_autotest_log_v10586]
      bad=req.find_all{|m|!respond_to?(m)}
      map_ok=FileTest.exist?(sprintf('Data/Map%03d.rvdata',VXRD_AUTOTEST_MAP_ID_V10586)) rescue false
      {:pass=>bad.empty? && map_ok,:api=>req.size,:presets=>vxrd_autotest_presets_v10586.size,
       :map_id=>VXRD_AUTOTEST_MAP_ID_V10586,:map_file=>map_ok,:bad=>bad}
    rescue
      {:pass=>false,:api=>0,:presets=>0,:map_id=>VXRD_AUTOTEST_MAP_ID_V10586,:map_file=>false,:bad=>[:audit_error]}
    end
  end
end

class Game_Player
  alias pmd_ac_v10586_perform_transfer perform_transfer unless method_defined?(:pmd_ac_v10586_perform_transfer)
  def perform_transfer
    pmd_ac_v10586_perform_transfer
    begin
      if $game_map!=nil && $game_map.map_id.to_i==PMD_AC::VXRD_AUTOTEST_MAP_ID_V10586 &&
         $game_temp!=nil && $game_temp.pmd_vxrd_autotest_pending_v10586!=nil
        PMD_AC.vxrd_autotest_generate_after_transfer_v10586
      end
    rescue
    end
  end
end
