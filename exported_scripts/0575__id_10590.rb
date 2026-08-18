# encoding: UTF-8
#===============================================================================
# ■ PMD AutoChess - VXRD Height Wall AutoTest Diagnostics v1.05.90
#===============================================================================
$imported={} unless defined?($imported)
$imported['PMD_AutoChess_VXRDHeightWallDiagnostics_v10590']=true

module PMD_AC
  class << self
    alias pmd_ac_v10590_hunt_vx_floor_info_v10584 hunt_vx_floor_info_v10584 unless method_defined?(:pmd_ac_v10590_hunt_vx_floor_info_v10584)
    def hunt_vx_floor_info_v10584
      h=pmd_ac_v10590_hunt_vx_floor_info_v10584
      return h if h==nil
      h[:wall_topology]=vxrd_wall_topology_info_v10589 if respond_to?(:vxrd_wall_topology_info_v10589)
      h
    rescue
      nil
    end

    alias pmd_ac_v10590_write_vxrd_autotest_log_v10586 write_vxrd_autotest_log_v10586 unless method_defined?(:pmd_ac_v10590_write_vxrd_autotest_log_v10586)
    def write_vxrd_autotest_log_v10586(action,extra=nil)
      r=pmd_ac_v10590_write_vxrd_autotest_log_v10586(action,extra)
      return false unless r
      info=respond_to?(:vxrd_wall_topology_info_v10589) ? vxrd_wall_topology_info_v10589 : nil
      audit=respond_to?(:vxrd_wall_topology_audit_v10589) ? vxrd_wall_topology_audit_v10589 : {:pass=>false}
      lines=[]
      lines << 'WALL_TOPOLOGY_PASS='+(audit[:pass] ? '1':'0')
      lines << 'WALL_RENDERER='+audit[:renderer].to_s
      lines << 'WALL_EXTERNAL_PNG='+(audit[:external_png] ? '1':'0')
      lines << 'WALL_BITMAP_RENDERER='+(audit[:bitmap_renderer] ? '1':'0')
      if info!=nil
        c=info[:counts]||{}
        lines << 'WALL_TOP_BASE='+info[:wall_top_base].to_i.to_s
        lines << 'WALL_FACE_BASE='+info[:wall_face_base].to_i.to_s
        lines << 'WALL_OPEN='+c[:open].to_i.to_s
        lines << 'WALL_NORTH_FACE='+c[:north_face].to_i.to_s
        lines << 'WALL_TOP='+c[:wall_top].to_i.to_s
        lines << 'WALL_SOUTH_FACE='+c[:south_face].to_i.to_s
        lines << 'WALL_OUTER='+c[:outer].to_i.to_s
      end
      File.open(VXRD_AUTOTEST_LOG_V10586,'ab'){|f|f.write(lines.join("\r\n")+"\r\n")}
      true
    rescue
      false
    end

    def run_vxrd_wall_test_v10590(code='H01')
      run_vxrd_auto_test_v10586(code.to_s.upcase,:event,1059001)
    rescue
      false
    end

    def vxrd_wall_test_info_v10590
      a=vxrd_wall_topology_audit_v10589
      i=vxrd_wall_topology_info_v10589
      {:pass=>a[:pass],:audit=>a,:current=>i,:autotest_log=>VXRD_AUTOTEST_LOG_V10586}
    rescue
      {:pass=>false,:audit=>nil,:current=>nil,:autotest_log=>VXRD_AUTOTEST_LOG_V10586}
    end
  end
end
