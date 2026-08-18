# encoding: UTF-8
#===============================================================================
# ■ PMD AutoChess - VXRD Upper Tile ID Coordinate Authority Reset v1.06.45
#-------------------------------------------------------------------------------
# Root-cause correction after H02 visual QA.
#
# IMPORTANT:
# RPG Maker VX upper-layer B/C/D/E tile IDs do NOT map to the source PNG in
# naive 16-column row-major order. Each 256-tile sheet is addressed as two
# 8-column banks of 128 IDs:
#   runtime local 0..127   -> source columns 0..7
#   runtime local 128..255 -> source columns 8..15
#
# The previous Landmark I data used PNG atlas indices as if they were runtime
# tile IDs. Example: runtime B161 actually renders source TileB atlas #73.
# That is exactly the large-map fragment seen in H02.
#
# v1.06.45 therefore:
# - revokes v1.06.44 Landmark Template I visual stamping;
# - establishes explicit atlas-index <-> runtime-tile conversion APIs;
# - fixes TileB left/right-half detection;
# - adds a final post-v1.06.44 upper-layer purge so no legacy B/C/D/E write can
#   survive generation;
# - keeps terrain/minimap/event gameplay untouched.
#
# Future Landmark Template II MUST store source PNG atlas indices, never raw
# runtime IDs, and convert through the v1.06.45 API at stamp time.
#===============================================================================
$imported={} unless defined?($imported)
$imported['PMD_AutoChess_VXRDUpperTileIDCoordinateAuthorityReset_v10645']=true

module PMD_AC
  VXRD_UPPER_SHEET_BASE_V10645={:tile_b=>0,:tile_c=>256,:tile_d=>512,:tile_e=>768}

  class << self
    # runtime local ID (0..255) -> source PNG row-major atlas index (0..255)
    def vxrd_upper_runtime_local_to_atlas_v10645(local_id)
      r=local_id.to_i
      return -1 if r<0 || r>255
      bank=r/128
      within=r%128
      x=bank*8+(within%8)
      y=within/8
      y*16+x
    rescue
      -1
    end

    # source PNG row-major atlas index (0..255) -> runtime local ID (0..255)
    def vxrd_upper_atlas_to_runtime_local_v10645(atlas_index)
      a=atlas_index.to_i
      return -1 if a<0 || a>255
      x=a%16
      y=a/16
      y*8+(x%8)+(x>=8 ? 128:0)
    rescue
      -1
    end

    def vxrd_upper_runtime_tile_to_atlas_v10645(tile_id,sheet)
      base=VXRD_UPPER_SHEET_BASE_V10645[sheet.to_sym]
      return -1 if base==nil
      local=tile_id.to_i-base.to_i
      vxrd_upper_runtime_local_to_atlas_v10645(local)
    rescue
      -1
    end

    def vxrd_upper_atlas_to_runtime_tile_v10645(sheet,atlas_index)
      base=VXRD_UPPER_SHEET_BASE_V10645[sheet.to_sym]
      return -1 if base==nil
      local=vxrd_upper_atlas_to_runtime_local_v10645(atlas_index)
      return -1 if local<0
      base.to_i+local
    rescue
      -1
    end

    # Correct the earlier bad right-half test. For TileB, runtime IDs 0..127
    # map to PNG columns 0..7; IDs 128..255 map to PNG columns 8..15.
    def vxrd_tileb_right_half_v10638?(tile)
      t=tile.to_i
      return true if t<0 || t>255
      t>=128
    rescue
      true
    end

    def vxrd_tileb_left_half_v10645?(tile)
      t=tile.to_i
      t>=0 && t<128
    rescue
      false
    end

    # v1.06.44 is revoked. Do not write any upper-layer landmarks until each
    # footprint is rebuilt from source PNG atlas coordinates.
    def vxrd_apply_landmarks_v10644(state)
      return nil if state==nil
      state[:landmark_reserved_v10644]={}
      info={:code=>state[:code].to_s.upcase,:enabled=>false,:placed=>0,
        :templates=>[],:placements=>[],:reserved_cells=>0,
        :revoked_v10645=>true,:reason=>:upper_tile_id_coordinate_mismatch,
        :single_scatter=>false,:tileb=>false,:tilec=>false,:tiled=>false,
        :gameplay_change=>false}
      state[:landmarks_v10644]=info
      info
    rescue
      nil
    end

    # Ensure even a stale alias or old save-time generation hook cannot leave
    # upper B/C/D/E tiles after v1.06.44. Events are sprites and unaffected.
    alias pmd_ac_v10645_generate_current_map_v10582 vxrd_generate_current_map_v10582 unless method_defined?(:pmd_ac_v10645_generate_current_map_v10582)
    def vxrd_generate_current_map_v10582(code=nil,seed=nil,options=nil)
      st=pmd_ac_v10645_generate_current_map_v10582(code,seed,options)
      return st if st==nil || $game_map==nil
      map=$game_map.instance_variable_get(:@map)
      return st if map==nil || map.data==nil
      removed=[];ids={}
      for y in 0...$game_map.height.to_i
        for x in 0...$game_map.width.to_i
          [1,2].each do |z|
            t=map.data[x,y,z].to_i
            next if t<=0
            if t<1536
              map.data[x,y,z]=0
              removed << [x,y,z,t]
              ids[t]=true
            end
          end
        end
      end
      st[:landmark_reserved_v10644]={}
      st[:upper_tile_coordinate_v10645]={
        :landmark_i_revoked=>true,
        :post_purge_removed=>removed.size,
        :post_purge_tile_ids=>ids.keys.sort,
        :b_runtime_left_range=>'0..127',
        :b_runtime_right_range=>'128..255',
        :future_landmark_storage=>:source_atlas_index,
        :gameplay_change=>false
      }
      $game_map.need_refresh=true if $game_map.respond_to?(:need_refresh=)
      st
    rescue
      st
    end

    def vxrd_upper_tile_coordinate_audit_v10645
      bad=[]
      evidence={
        161=>73,162=>74,180=>108,197=>141,
        160=>72,176=>104,178=>106,179=>107
      }
      evidence.each do |runtime,atlas|
        got=vxrd_upper_runtime_local_to_atlas_v10645(runtime)
        bad << 'B'+runtime.to_s+'->'+got.to_s unless got==atlas
        inv=vxrd_upper_atlas_to_runtime_local_v10645(atlas)
        bad << 'B_atlas'+atlas.to_s+'->'+inv.to_s unless inv==runtime
      end
      # Desired source PNG plant examples now convert into the first bank.
      desired=[160,161,162,176,178,179,180,181,182,197]
      desired.each do |atlas|
        r=vxrd_upper_atlas_to_runtime_local_v10645(atlas)
        bad << 'atlas_inverse_'+atlas.to_s if r<0 || r>=128
      end
      {:pass=>bad.empty?,:evidence=>evidence,:desired_source_examples=>desired,
        :tileb_left_runtime=>'0..127',:tileb_right_runtime=>'128..255',
        :landmark_i_revoked=>true,:future_storage=>:source_atlas_index,:bad=>bad}
    rescue
      {:pass=>false,:bad=>[:audit_error]}
    end

    alias pmd_ac_v10645_write_project_state_log write_project_state_log unless method_defined?(:pmd_ac_v10645_write_project_state_log)
    def project_version
      '1.06.45'
    end
    def write_project_state_log(force=false)
      r=pmd_ac_v10645_write_project_state_log(force)
      return false unless r
      begin
        text='';File.open(PROJECT_STATE_FILE_V10564,'rb'){|io|text=io.read}
        text=text.gsub(/PROJECT_STATE_SCHEMA=\d+/,'PROJECT_STATE_SCHEMA=31')
        text=text.gsub(/CURRENT_VERSION=[^\r\n]+/,'CURRENT_VERSION=1.06.45')
        text=text.gsub(/LATEST_FEATURE=[^\r\n]+/,'LATEST_FEATURE=VXRD_UPPER_TILE_ID_COORDINATE_AUTHORITY_RESET')
        text=text.gsub(/NEXT_TARGET=[^\r\n]+/,'NEXT_TARGET=EVENT_SEMANTIC_PLACEMENT+LANDMARK_TEMPLATE_REBUILD_FROM_ATLAS_COORDS')
        text=text.gsub(/\r?\nVXRD_UPPER_TILE_COORDINATE_V10645_BEGIN.*?VXRD_UPPER_TILE_COORDINATE_V10645_END\r?\n/m,"\r\n")
        a=vxrd_upper_tile_coordinate_audit_v10645
        lines=[]
        lines << ''
        lines << 'VXRD_UPPER_TILE_COORDINATE_V10645_BEGIN'
        lines << 'VXRD_UPPER_TILE_COORDINATE_AUTHORITY='+(a[:pass] ? 'PASS':'FAIL')
        lines << 'TILEB_RUNTIME_LEFT_HALF=0..127'
        lines << 'TILEB_RUNTIME_RIGHT_HALF=128..255'
        lines << 'TILEB_EVIDENCE_RUNTIME_161_ATLAS=73'
        lines << 'TILEB_EVIDENCE_RUNTIME_162_ATLAS=74'
        lines << 'TILEB_EVIDENCE_RUNTIME_180_ATLAS=108'
        lines << 'TILEB_EVIDENCE_RUNTIME_197_ATLAS=141'
        lines << 'VXRD_LANDMARK_TEMPLATE_I=REVOKED'
        lines << 'VXRD_LANDMARK_AUTOWRITE_BCD=DISABLED'
        lines << 'VXRD_FUTURE_LANDMARK_STORAGE=SOURCE_PNG_ATLAS_INDEX'
        lines << 'VXRD_UPPER_TILE_COORDINATE_V10645_END'
        File.open(PROJECT_STATE_FILE_V10564,'wb'){|io|io.write(text.rstrip+"\r\n"+lines.join("\r\n")+"\r\n")}
      rescue
      end
      true
    rescue
      false
    end
  end
end
