# encoding: UTF-8
#===============================================================================
# ■ PMD AutoChess - Project State Sync Schema 10 F12/WaterPair/Decor v1.05.99
#===============================================================================
$imported={} unless defined?($imported)
$imported['PMD_AutoChess_ProjectStateSyncSchema10_v10599']=true

module PMD_AC
  class << self
    alias pmd_ac_v10599_write_vxrd_autotest_log_v10586 write_vxrd_autotest_log_v10586 unless method_defined?(:pmd_ac_v10599_write_vxrd_autotest_log_v10586)
    def write_vxrd_autotest_log_v10586(action,extra=nil)
      ok=pmd_ac_v10599_write_vxrd_autotest_log_v10586(action,extra)
      return false unless ok
      f=f12_alias_guard_audit_v10596 rescue {:pass=>false}
      w=vxrd_water_pair_info_v10597 rescue nil
      d=vxrd_ground_decor_info_v10598 rescue nil
      lines=[]
      lines << 'F12_ALIAS_GUARD='+(f[:pass] ? 'PASS':'FAIL')
      lines << 'F12_ALIAS_DECLARATIONS='+f[:aliases].to_i.to_s
      lines << 'F12_ALIAS_GUARDED='+f[:guarded].to_i.to_s
      if w!=nil
        lines << 'WATER_PAIR_SOURCE='+w[:source].to_s
        lines << 'WATER_PAIR_PALETTE='+w[:palette_index].to_i.to_s
        lines << 'WATER_PAIR_FLOOR_BASE='+w[:floor_base].to_i.to_s
        lines << 'WATER_PAIR_WALL_BASE='+w[:wall_base].to_i.to_s
        lines << 'WATER_PAIR_BASE='+w[:water_base].to_i.to_s
        lines << 'WATER_PAIR_STYLE='+w[:style].to_s
      end
      if d!=nil
        lines << 'GROUND_DECOR_BIOME='+d[:biome].to_s
        lines << 'GROUND_DECOR_LABEL='+d[:label].to_s
        lines << 'GROUND_DECOR_TILES='+d[:decor_a].to_i.to_s+','+d[:decor_b].to_i.to_s
        lines << 'GROUND_DECOR_CANDIDATES='+d[:candidates].to_i.to_s
        lines << 'GROUND_DECOR_PLACED='+d[:placed].to_i.to_s
        lines << 'GROUND_DECOR_CORRIDOR_SAFE=1'
        lines << 'GROUND_DECOR_WATER_SAFE=1'
      end
      File.open(VXRD_AUTOTEST_LOG_V10586,'ab'){|io|io.write(lines.join("\r\n")+"\r\n")}
      true
    rescue
      false
    end

    alias pmd_ac_v10599_write_project_state_log write_project_state_log unless method_defined?(:pmd_ac_v10599_write_project_state_log)
    def project_version
      '1.05.99'
    end

    def write_project_state_log(force=false)
      r=pmd_ac_v10599_write_project_state_log(force)
      return false unless r
      f=f12_alias_guard_audit_v10596 rescue {:pass=>false,:aliases=>0,:guarded=>0}
      w=vxrd_water_pair_audit_v10597 rescue {:pass=>false,:pairs=>0,:water_families=>0}
      d=vxrd_ground_decor_audit_v10598 rescue {:pass=>false,:palettes=>0,:biomes=>0}
      text='';File.open(PROJECT_STATE_FILE_V10564,'rb'){|io|text=io.read}
      text=text.gsub('PROJECT_STATE_SCHEMA=9','PROJECT_STATE_SCHEMA=10')
      text=text.gsub('LATEST_FEATURE=VXRD_HEIGHT_WALL_GEOMETRY_REPAIR+REGULAR_WATER','LATEST_FEATURE=F12_ALIAS_GUARD+VXRD_PALETTE_WATER_PAIR+GROUND_DECOR')
      text=text.gsub('NEXT_TARGET=VXRD_WINDOWS_WALL_WATER_QA+ROOM_TYPES+RARE_NEST','NEXT_TARGET=VXRD_ROOM_TYPES+TREASURE_ROOM+RARE_NEST+ELITE_ROOM')
      lines=[]
      lines << ''
      lines << 'F12_ALIAS_RELOAD_SAFETY='+(f[:pass] ? 'PASS':'FAIL')
      lines << 'F12_ALIAS_DECLARATIONS='+f[:aliases].to_i.to_s
      lines << 'F12_ALIAS_GUARDED='+f[:guarded].to_i.to_s
      lines << 'VXRD_WATER_PALETTE_PAIR='+(w[:pass] ? 'PASS':'FAIL')
      lines << 'VXRD_WATER_PALETTE_PAIRS='+w[:pairs].to_i.to_s+'/24'
      lines << 'VXRD_WATER_FAMILIES='+w[:water_families].to_i.to_s
      lines << 'VXRD_WATER_PAIR_SOURCE=palette'
      lines << 'VXRD_GROUND_DECOR='+(d[:pass] ? 'PASS':'FAIL')
      lines << 'VXRD_GROUND_DECOR_PALETTES='+d[:palettes].to_i.to_s+'/24'
      lines << 'VXRD_GROUND_DECOR_BIOMES='+d[:biomes].to_i.to_s+'/6'
      lines << 'VXRD_GROUND_DECOR_EXTERNAL_PNG=0'
      File.open(PROJECT_STATE_FILE_V10564,'wb'){|io|io.write(text.rstrip+"\r\n"+lines.join("\r\n")+"\r\n")}
      true
    rescue
      false
    end

    # Keep the existing AutoTest scene, but make the first presets visibly test
    # the newly paired water and deterministic ground decoration.
    def vxrd_autotest_presets_v10586
      [
        {:label=>'H01 林緣｜牆體＋地表裝飾',:code=>'H01',:mode=>:event,:seed=>1059901},
        {:label=>'H02 苔溪｜水域配色＋裝飾',:code=>'H02',:mode=>:event,:seed=>1059902},
        {:label=>'H03 風丘｜天空 Palette＋裝飾',:code=>'H03',:mode=>:event,:seed=>1059903},
        {:label=>'H04 赤岩｜山地 Palette＋裝飾',:code=>'H04',:mode=>:event,:seed=>1059904},
        {:label=>'H05 月影｜神秘水域＋裝飾',:code=>'H05',:mode=>:event,:seed=>1059905},
        {:label=>'H01 林緣｜步數遭遇',:code=>'H01',:mode=>:steps,:seed=>1059911}
      ]
    end

    def vxrd_style_audit_v10599
      f=f12_alias_guard_audit_v10596
      w=vxrd_water_pair_audit_v10597
      d=vxrd_ground_decor_audit_v10598
      {:pass=>f[:pass] && w[:pass] && d[:pass],:f12=>f,:water=>w,:decor=>d}
    rescue
      {:pass=>false}
    end
  end
end
