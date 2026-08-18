# encoding: UTF-8
#===============================================================================
# ■ PMD AutoChess - VXRD Unified Integrated Acceptance Harness v1.06.11
#-------------------------------------------------------------------------------
# 【用途】
# - 提供 Random Dungeon / Hunt Integration 最終 Windows 實機一次驗收入口。
# - 沿用 Map090 dry-run AutoTest，不大量自動跑 Seed；玩家可看實際 VX Tilemap 外觀。
# - 另外輸出 PMD_VXRD_IntegratedTest_LATEST.log，集中牆／水／房間／事件／Pool／Run 狀態。
#===============================================================================
$imported={} unless defined?($imported)
$imported['PMD_AutoChess_VXRDIntegratedAcceptance_v10611']=true

module PMD_AC
  VXRD_INTEGRATED_LOG_V10611='PMD_VXRD_IntegratedTest_LATEST.log'

  class << self
    def vxrd_integrated_presets_v10611
      [
        {:label=>'H01 前期森林｜牆＋裝飾＋Room',:code=>'H01',:mode=>:event,:seed=>1061101},
        {:label=>'H02 前期濕地｜水＋乾岸＋Room',:code=>'H02',:mode=>:event,:seed=>1061102},
        {:label=>'H09 中期洞窟｜Elite＋Recovery',:code=>'H09',:mode=>:event,:seed=>1061109},
        {:label=>'H12 中期水境｜水＋特殊房',:code=>'H12',:mode=>:event,:seed=>1061112},
        {:label=>'H17 後期冰灣｜後期水域',:code=>'H17',:mode=>:event,:seed=>1061117},
        {:label=>'H21 終盤聖域｜Legend Pool＋Room',:code=>'H21',:mode=>:event,:seed=>1061121},
        {:label=>'H01 步數遭遇模式',:code=>'H01',:mode=>:steps,:seed=>1061191}
      ]
    end

    def vxrd_autotest_presets_v10586
      vxrd_integrated_presets_v10611
    end

    def run_vxrd_integrated_test_v10611(code='H01',mode=:event,seed=nil)
      c=code.to_s.upcase
      p=vxrd_integrated_presets_v10611.find{|x|x[:code]==c && x[:mode].to_sym==mode.to_sym}
      sd=seed==nil ? (p==nil ? 1061101:p[:seed].to_i) : seed.to_i
      ok=run_vxrd_auto_test_v10586(c,mode,sd)
      write_vxrd_integrated_log_v10611(:launch,{:requested=>c,:mode=>mode,:seed=>sd}) if ok
      ok
    rescue
      false
    end

    def vxrd_integrated_consumed_count_v10611
      s=phase_div_hunt_session_v10555;st=vxrd_state_v10582
      return 0 if s==nil || st==nil
      prefix=st[:seed].to_i.to_s+':'
      (s[:vxrd_consumed_nodes_v10606]||{}).keys.find_all{|k|k.to_s.index(prefix)==0}.size
    rescue
      0
    end

    def write_vxrd_integrated_log_v10611(action,extra=nil)
      st=vxrd_state_v10582 rescue nil
      hs=phase_div_hunt_session_v10555 rescue nil
      f=respond_to?(:hunt_vx_floor_info_v10584) ? hunt_vx_floor_info_v10584 : nil
      wa=respond_to?(:vxrd_wall_geometry_audit_v10592) ? vxrd_wall_geometry_audit_v10592 : {}
      wat=respond_to?(:vxrd_regular_water_audit_v10593) ? vxrd_regular_water_audit_v10593 : {}
      dec=respond_to?(:vxrd_ground_decor_audit_v10598) ? vxrd_ground_decor_audit_v10598 : {}
      rt=respond_to?(:vxrd_room_type_info_v10601) ? vxrd_room_type_info_v10601 : nil
      rv=respond_to?(:vxrd_room_visual_audit_v10607) ? vxrd_room_visual_audit_v10607 : {}
      seal=respond_to?(:vxrd_random_hunt_system_audit_v10610) ? vxrd_random_hunt_system_audit_v10610 : {}
      lines=[]
      lines << 'PMD VXRD Integrated Acceptance'
      lines << 'VERSION='+project_version.to_s
      lines << 'ACTION='+action.to_s
      lines << 'STRUCTURAL_SEAL='+(seal[:pass] ? 'PASS':'FAIL')
      lines << 'MAP_ID='+(f==nil ? '0':f[:map_id].to_i.to_s)
      lines << 'CODE='+(hs==nil ? '':hs[:code].to_s)
      lines << 'MODE='+(hs==nil ? '':(hs[:encounter_mode_v10579]||:event).to_s)
      lines << 'RUN='+(hs==nil ? '0':hs[:run].to_i.to_s)
      lines << 'FLOOR='+(hs==nil ? '0':hs[:vxrd_floor_count_v10584].to_i.to_s)
      lines << 'MAX_FLOOR='+(hs==nil ? '0':hs[:vxrd_max_floors_v10604].to_i.to_s)
      lines << 'RUN_SEED='+(hs==nil ? '0':hs[:seed].to_i.to_s)
      lines << 'FLOOR_SEED='+(st==nil ? '0':st[:seed].to_i.to_s)
      lines << 'ACTIVE_POOL='+(hs==nil ? '':(hs[:active_pool]||[]).collect{|x|x.to_s}.join(','))
      if f!=nil
        lines << 'PALETTE='+((f[:palette]||{})[:index]||-1).to_i.to_s
        lines << 'ROOMS='+f[:rooms].to_i.to_s
        lines << 'EDGES='+f[:edges].to_i.to_s
        lines << 'WALKABLE='+f[:walkable].to_i.to_s
        lines << 'EXPLORED='+f[:explored].to_i.to_s
        er=f[:event_relocate]||{}
        lines << 'EVENT_RELOCATE='+(er[:pass] ? 'PASS':'FAIL')
        lines << 'EVENT_COUNTS='+(er[:counts]||{}).inspect
      end
      lines << 'WALL_GEOMETRY='+(wa[:pass] ? 'PASS':'FAIL')
      lines << 'WALL_VERTICAL_PINCHES='+wa[:vertical_pinches].to_i.to_s
      lines << 'WALL_UNSUPPORTED_NORTH='+wa[:unsupported_north].to_i.to_s
      lines << 'WALL_UNSUPPORTED_SOUTH='+wa[:unsupported_south].to_i.to_s
      lines << 'WALL_ORPHAN_FACE='+wa[:orphan_face].to_i.to_s
      vi=st==nil ? nil : st[:visual_style_v10600]
      wp=st==nil ? nil : st[:water_pair_v10597]
      lines << 'WATER_EXPECTED='+(vi!=nil && vi[:water_expected] ? '1':'0')
      lines << 'WATER_BASE='+(wp==nil ? '0':wp[:water_base].to_i.to_s)
      lines << 'WATER_RULE=ONE_TYPE_RECTANGLE_NO_RIVER_NO_BRIDGE'
      lines << 'WATER_AUDIT='+(wat[:pass] ? 'PASS':'FAIL')
      lines << 'GROUND_DECOR='+(dec[:pass] ? 'PASS':'FAIL')
      if rt!=nil
        lines << 'ROOM_TYPES='+(rt[:counts]||{}).inspect
        lines << 'ROOM_EVENTS='+(rt[:events]||{}).inspect
      end
      lines << 'ROOM_VISUAL='+(rv[:pass] ? 'PASS':'FAIL')
      lines << 'CONSUMED_NODES='+vxrd_integrated_consumed_count_v10611.to_i.to_s
      stats=hs==nil ? {}:(hs[:vxrd_runtime_stats_v10604]||{})
      lines << 'RUN_STATS='+stats.inspect
      lines << 'EXTRA='+extra.inspect if extra!=nil
      File.open(VXRD_INTEGRATED_LOG_V10611,'wb'){|io|io.write(lines.join("\r\n")+"\r\n")}
      true
    rescue
      false
    end

    alias pmd_ac_v10611_write_vxrd_autotest_log_v10586 write_vxrd_autotest_log_v10586 unless method_defined?(:pmd_ac_v10611_write_vxrd_autotest_log_v10586)
    def write_vxrd_autotest_log_v10586(action,extra=nil)
      r=pmd_ac_v10611_write_vxrd_autotest_log_v10586(action,extra)
      write_vxrd_integrated_log_v10611(action,extra)
      r
    rescue
      false
    end

    def vxrd_integrated_acceptance_audit_v10611
      req=[:run_vxrd_integrated_test_v10611,:write_vxrd_integrated_log_v10611,
        :vxrd_integrated_presets_v10611,:vxrd_integrated_consumed_count_v10611]
      bad=req.find_all{|m|!respond_to?(m)}
      p=vxrd_integrated_presets_v10611
      codes=p.collect{|x|x[:code]}
      bad << :presets unless p.size==7 && ['H01','H02','H09','H12','H17','H21'].all?{|c|codes.include?(c)}
      {:pass=>bad.empty?,:api=>req.size,:presets=>p.size,:log=>VXRD_INTEGRATED_LOG_V10611,
        :windows_manual_visual=>true,:mass_seed_runtime=>false,:bad=>bad}
    rescue
      {:pass=>false,:api=>0,:presets=>0,:bad=>[:audit_error]}
    end
  end
end
