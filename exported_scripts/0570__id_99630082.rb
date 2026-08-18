# encoding: UTF-8
#===============================================================================
# ■ PMD AutoChess - Project State Sync Schema 6 + VXRD Audit v1.05.85
#-------------------------------------------------------------------------------
# 同步 VX Native Random Dungeon Core / Placement Exploration / Hunt integration。
#===============================================================================
$imported={} unless defined?($imported)
$imported['PMD_AutoChess_ProjectStateSyncSchema6_v10585']=true

module PMD_AC
  class << self
    alias pmd_ac_v10585_write_project_state_log write_project_state_log unless method_defined?(:pmd_ac_v10585_write_project_state_log)

    def project_version
      '1.05.85'
    end

    def write_project_state_log(force=false)
      r=pmd_ac_v10585_write_project_state_log(force)
      return false unless r
      core=respond_to?(:vxrd_core_audit_v10582) ? vxrd_core_audit_v10582 : {:pass=>false,:palettes=>0,:biomes=>0}
      exp=respond_to?(:vxrd_placement_exploration_audit_v10583) ? vxrd_placement_exploration_audit_v10583 : {:pass=>false,:api=>0}
      hunt=respond_to?(:hunt_vx_random_floor_audit_v10584) ? hunt_vx_random_floor_audit_v10584 : {:pass=>false,:api=>0}
      info=respond_to?(:hunt_vx_floor_info_v10584) ? hunt_vx_floor_info_v10584 : nil
      text=''
      File.open(PROJECT_STATE_FILE_V10564,'rb'){|f|text=f.read}
      text=text.gsub('PROJECT_STATE_SCHEMA=5','PROJECT_STATE_SCHEMA=6')
      text=text.gsub('LATEST_FEATURE=HUNT_REGION_ECONOMY+RANDOM_MAP_EVENT_TEMPLATE+UI_DATA_CONTRACT',
        'LATEST_FEATURE=VX_NATIVE_RANDOM_DUNGEON+HUNT_RANDOM_FLOOR')
      text=text.gsub('NEXT_TARGET=HUNT_REWARD_CURVE+RANDOM_MAP_INTEGRATION_FIXTURE+UI_PHASE_PREP',
        'NEXT_TARGET=VXRD_WINDOWS_VISUAL_QA+HUNT_NODE_CONTENT+UI_PHASE_PREP')
      lines=[]
      lines << ''
      lines << 'VX_NATIVE_RANDOM_DUNGEON='+(core[:pass] ? 'PASS':'FAIL')
      lines << 'VXRD_RTP_PALETTES='+core[:palettes].to_i.to_s+'/24'
      lines << 'VXRD_BIOMES='+core[:biomes].to_i.to_s+'/6'
      lines << 'VXRD_EXTERNAL_PNG=0'
      lines << 'VXRD_PARALLAX_GENERATION=0'
      lines << 'VXRD_SECOND_GAME_MAP=0'
      lines << 'VXRD_PLACEMENT_EXPLORATION='+(exp[:pass] ? exp[:api].to_i.to_s+'/5':'FAIL')
      lines << 'HUNT_VX_RANDOM_FLOOR='+(hunt[:pass] ? hunt[:api].to_i.to_s+'/4':'FAIL')
      if info!=nil
        lines << 'VXRD_ACTIVE_FLOOR='+info[:code].to_s+':'+info[:floor].to_i.to_s
        lines << 'VXRD_ACTIVE_MAP_ID='+info[:map_id].to_i.to_s
        lines << 'VXRD_ACTIVE_SEED='+info[:seed].to_i.to_s
        lines << 'VXRD_ACTIVE_ROOMS='+info[:rooms].to_i.to_s
        lines << 'VXRD_ACTIVE_EDGES='+info[:edges].to_i.to_s
        lines << 'VXRD_ACTIVE_WALKABLE='+info[:walkable].to_i.to_s
        lines << 'VXRD_EXPLORED_PERCENT='+info[:explored].to_i.to_s
      else
        lines << 'VXRD_ACTIVE_FLOOR=NONE'
      end
      File.open(PROJECT_STATE_FILE_V10564,'wb'){|f|f.write(text.rstrip+"\r\n"+lines.join("\r\n")+"\r\n")}
      true
    rescue
      false
    end
  end
end

class Scene_PMD_AutoChess
  alias pmd_ac_v10585_focus_summary focus_cast_log_summary_v1055 unless method_defined?(:pmd_ac_v10585_focus_summary)
  def focus_cast_log_summary_v1055
    r=pmd_ac_v10585_focus_summary
    begin
      a=PMD_AC.vxrd_core_audit_v10582
      b=PMD_AC.vxrd_placement_exploration_audit_v10583
      c=PMD_AC.hunt_vx_random_floor_audit_v10584
      log_event(:battle,'BATTLE_VX_NATIVE_RANDOM_DUNGEON_SUMMARY_V10582 pass='+(a[:pass] ? '1':'0')+
        ' palettes='+a[:palettes].to_i.to_s+'/24 biomes='+a[:biomes].to_i.to_s+'/6'+
        ' external_png=0 parallax_generation=0 second_game_map=0')
      log_event(:battle,'BATTLE_VXRD_PLACEMENT_EXPLORATION_SUMMARY_V10583 pass='+(b[:pass] ? '1':'0')+
        ' api='+b[:api].to_i.to_s+'/5 visual_fog=deferred visual_minimap=deferred')
      log_event(:battle,'BATTLE_HUNT_VX_RANDOM_FLOOR_SUMMARY_V10584 pass='+(c[:pass] ? '1':'0')+
        ' api='+c[:api].to_i.to_s+'/4 scene_map_native=1 rtp_tileset_native=1 external_png=0')
    rescue
    end
    r
  end
end
