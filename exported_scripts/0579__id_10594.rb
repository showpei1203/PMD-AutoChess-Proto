# encoding: UTF-8
#===============================================================================
# ■ PMD AutoChess - VXRD Wall/Water Windows Diagnostics v1.05.94
#===============================================================================
$imported={} unless defined?($imported)
$imported['PMD_AutoChess_VXRDWallWaterDiagnostics_v10594']=true

module PMD_AC
  class << self
    alias pmd_ac_v10594_write_vxrd_autotest_log_v10586 write_vxrd_autotest_log_v10586 unless method_defined?(:pmd_ac_v10594_write_vxrd_autotest_log_v10586)
    def write_vxrd_autotest_log_v10586(action,extra=nil)
      ok=pmd_ac_v10594_write_vxrd_autotest_log_v10586(action,extra)
      return false unless ok
      st=respond_to?(:vxrd_state_v10582) ? vxrd_state_v10582 : nil
      g=st==nil ? nil : st[:wall_geometry_v10592]
      w=st==nil ? nil : st[:water_v10593]
      lines=[]
      lines << 'WALL_GEOMETRY_SCHEMA=2'
      if g!=nil
        lines << 'WALL_CLEARANCE_REPAIRS='+g[:clearance_repairs].to_i.to_s
        lines << 'WALL_VERTICAL_PINCHES='+g[:vertical_pinches].to_i.to_s
        lines << 'WALL_UNSUPPORTED_NORTH='+g[:unsupported_north].to_i.to_s
        lines << 'WALL_UNSUPPORTED_SOUTH='+g[:unsupported_south].to_i.to_s
        lines << 'WALL_ORPHAN_FACE='+g[:orphan_face].to_i.to_s
        pass=g[:vertical_pinches].to_i==0 && g[:unsupported_north].to_i==0 && g[:unsupported_south].to_i==0 && g[:orphan_face].to_i==0
        lines << 'WALL_GEOMETRY_PASS='+(pass ? '1':'0')
      end
      lines << 'WATER_RULE=ONE_TYPE_RECTANGLE_NO_BRIDGE'
      if w!=nil
        lines << 'WATER_BIOME='+w[:biome].to_s
        lines << 'WATER_BASE='+w[:base].to_i.to_s
        lines << 'WATER_SHAPE='+w[:shape].to_s
        lines << 'WATER_BRIDGE='+(w[:bridge] ? '1':'0')
        lines << 'WATER_RECTS='+(w[:rects]||[]).size.to_s
        lines << 'WATER_CELLS='+w[:cells].to_i.to_s
        lines << 'WATER_TYPES_ON_FLOOR='+w[:types_on_floor].to_i.to_s
      end
      File.open(VXRD_AUTOTEST_LOG_V10586,'ab'){|io|io.write(lines.join("\r\n")+"\r\n")}
      true
    rescue
      false
    end

    def run_vxrd_wall_water_test_v10594(code='H02',seed=1059402)
      run_vxrd_auto_test_v10586(code.to_s.upcase,:event,seed.to_i)
    rescue
      false
    end

    # Existing menu automatically calls this method dynamically, so relabel the
    # water preset without adding another command to the VX main menu.
    def vxrd_autotest_presets_v10586
      [
        {:label=>'H01 林緣｜牆體測試',:code=>'H01',:mode=>:event,:seed=>1058601},
        {:label=>'H02 苔溪｜規則水域',:code=>'H02',:mode=>:event,:seed=>1059402},
        {:label=>'H03 風丘｜天空 Palette',:code=>'H03',:mode=>:event,:seed=>1058603},
        {:label=>'H04 赤岩｜山地 Palette',:code=>'H04',:mode=>:event,:seed=>1058604},
        {:label=>'H05 月影｜神秘＋水域',:code=>'H05',:mode=>:event,:seed=>1058605},
        {:label=>'H01 林緣｜步數遭遇',:code=>'H01',:mode=>:steps,:seed=>1058611}
      ]
    end

    def vxrd_wall_water_audit_v10594
      a=respond_to?(:vxrd_wall_geometry_audit_v10592) ? vxrd_wall_geometry_audit_v10592 : {:pass=>false}
      b=respond_to?(:vxrd_regular_water_audit_v10593) ? vxrd_regular_water_audit_v10593 : {:pass=>false}
      {:pass=>a[:pass] && b[:pass],:wall=>a,:water=>b,:autotest_api=>1}
    rescue
      {:pass=>false,:autotest_api=>0}
    end
  end
end
