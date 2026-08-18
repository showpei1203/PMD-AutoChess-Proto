# encoding: UTF-8
#===============================================================================
# ■ PMD AutoChess - VXRD Landmark PNG Authority Foundation I v1.06.53
#-------------------------------------------------------------------------------
# Research-first correction for Random Hunt landmarks.
#
# Authority:
# - Native A1/A2/A4/A5 terrain remains owned by the VX tilemap path.
# - B/C/D/E map-table stamping remains forbidden by v1.06.45.
# - Landmark visuals are now explicit PNG composites under
#     Graphics/VXRD_Landmarks/
#   and are rendered by map-coordinate sprites.
# - Source objects were cropped directly from the approved TileB/TileD source
#   images. No runtime upper-tile ID is involved in landmark rendering.
# - Runtime event placement reserves every landmark footprint before Map091
#   event relocation, preserving the existing route/event safety rules.
# - Phase I is VISUAL ONLY: landmark collision is intentionally deferred until
#   the visual set passes acceptance. No battle/reward/progression changes.
#===============================================================================
$imported={} unless defined?($imported)
$imported['PMD_AutoChess_VXRDLandmarkPNGAuthorityFoundationI_v10653']=true

module PMD_AC
  VXRD_LANDMARK_PNG_DIR_V10653='Graphics/VXRD_Landmarks/'
  VXRD_LANDMARK_PNG_AUDIT_LOG_V10653='PMD_VXRD_LandmarkPNG_Audit_LATEST.log'

  VXRD_LANDMARK_PNG_TEMPLATES_V10653={
    :forest_green_a=>{
      :file=>'forest_green_a',:label=>'森林低植被群',:w=>2,:h=>2,
      :source_sheet=>'TileB',:source_atlas=>[[160,161],[162,163]],:blocking=>false
    },
    :forest_flower_a=>{
      :file=>'forest_flower_a',:label=>'森林花草群',:w=>2,:h=>2,
      :source_sheet=>'TileB',:source_atlas=>[[176,177],[178,179]],:blocking=>false
    },
    :dry_rock_a=>{
      :file=>'dry_rock_a',:label=>'乾燥岩石群',:w=>2,:h=>2,
      :source_sheet=>'TileD',:source_atlas=>[[48,49],[144,148]],:blocking=>false
    },
    :cave_crystal_a=>{
      :file=>'cave_crystal_a',:label=>'洞窟晶岩群',:w=>2,:h=>2,
      :source_sheet=>'TileD',:source_atlas=>[[49,53],[65,69]],:blocking=>false
    },
    :mine_ore_a=>{
      :file=>'mine_ore_a',:label=>'礦坑礦石群',:w=>2,:h=>2,
      :source_sheet=>'TileD',:source_atlas=>[[32,33],[34,37]],:blocking=>false
    },
    :volcanic_ore_a=>{
      :file=>'volcanic_ore_a',:label=>'火山礦晶群',:w=>2,:h=>2,
      :source_sheet=>'TileD',:source_atlas=>[[50,54],[66,70]],:blocking=>false
    }
  }

  # First visual-acceptance set only. Do not spray all 21 Hunts at once.
  VXRD_LANDMARK_PNG_HUNT_PROFILE_V10653={
    'H01'=>{:templates=>[:forest_green_a,:forest_flower_a],:max=>2,:chance=>82},
    'H04'=>{:templates=>[:dry_rock_a],:max=>2,:chance=>78},
    'H09'=>{:templates=>[:cave_crystal_a],:max=>2,:chance=>76},
    'H14'=>{:templates=>[:mine_ore_a],:max=>2,:chance=>82},
    'H19'=>{:templates=>[:volcanic_ore_a],:max=>2,:chance=>82}
  }

  class << self
    def vxrd_landmark_png_profile_v10653(code)
      VXRD_LANDMARK_PNG_HUNT_PROFILE_V10653[code.to_s.upcase]
    rescue
      nil
    end

    def vxrd_landmark_png_room_type_v10653(state,room)
      return vxrd_landmark_room_type_v10644(state,room) if respond_to?(:vxrd_landmark_room_type_v10644)
      return :normal if state==nil || room==nil
      (state[:room_types_v10601]||{})[room[:id].to_i] || :normal
    rescue
      :normal
    end

    def vxrd_landmark_png_footprint_clear_v10653?(state,room,t,ax,ay)
      if respond_to?(:vxrd_landmark_footprint_clear_v10644?)
        return vxrd_landmark_footprint_clear_v10644?(state,room,t,ax,ay)
      end
      false
    rescue
      false
    end

    def vxrd_landmark_png_corner_anchors_v10653(room,t)
      if respond_to?(:vxrd_landmark_corner_anchors_v10644)
        return vxrd_landmark_corner_anchors_v10644(room,t)
      end
      []
    rescue
      []
    end

    def vxrd_landmark_png_reserve_v10653(state,t,ax,ay)
      state[:landmark_reserved_v10653]={} unless state[:landmark_reserved_v10653].is_a?(Hash)
      h=state[:landmark_reserved_v10653]
      for dy in 0...t[:h].to_i
        for dx in 0...t[:w].to_i
          h[[ax.to_i+dx,ay.to_i+dy]]=true
        end
      end
      # v1.06.46 / v1.06.49 event placement already respects this legacy key.
      state[:landmark_reserved_v10644]=h
      h.size
    rescue
      0
    end

    def vxrd_landmark_png_make_placement_v10653(state,room,key,ax,ay)
      t=VXRD_LANDMARK_PNG_TEMPLATES_V10653[key.to_sym]
      return nil if t==nil
      return nil unless vxrd_landmark_png_footprint_clear_v10653?(state,room,t,ax,ay)
      vxrd_landmark_png_reserve_v10653(state,t,ax,ay)
      {:template=>key.to_sym,:file=>t[:file].to_s,:label=>t[:label].to_s,
       :anchor=>[ax.to_i,ay.to_i],:w=>t[:w].to_i,:h=>t[:h].to_i,
       :room_id=>room[:id].to_i,:blocking=>false,
       :source_sheet=>t[:source_sheet].to_s,:source_atlas=>t[:source_atlas],
       :renderer=>:png_sprite,:native_upper_tile_id=>false}
    rescue
      nil
    end

    def vxrd_apply_landmark_pngs_v10653(state)
      return nil if state==nil
      code=state[:code].to_s.upcase
      prof=vxrd_landmark_png_profile_v10653(code)
      state[:landmark_reserved_v10653]={}
      state[:landmark_reserved_v10644]=state[:landmark_reserved_v10653]
      if prof==nil
        info={:code=>code,:enabled=>false,:placed=>0,:placements=>[],
          :renderer=>:png_sprite,:native_upper_tile_id=>false,
          :collision=>:deferred_visual_acceptance,:gameplay_change=>false}
        state[:landmarks_v10653]=info
        return info
      end
      rng=VXRD_RNG_V10582.new((state[:seed].to_i ^ 0x10653A71) & 0x7fffffff)
      rooms=(state[:rooms]||[]).find_all{|r|vxrd_landmark_png_room_type_v10653(state,r)==:normal}
      pool=rooms.dup;order=[]
      until pool.empty?
        order << pool.delete_at(rng.rand(pool.size))
      end
      placed=[]
      max=prof[:max].to_i
      order.each do |room|
        break if placed.size>=max
        next unless rng.rand(100)<prof[:chance].to_i
        keys=prof[:templates]||[]
        next if keys.empty?
        key=keys[rng.rand(keys.size)]
        t=VXRD_LANDMARK_PNG_TEMPLATES_V10653[key]
        next if t==nil
        anchors=vxrd_landmark_png_corner_anchors_v10653(room,t)
        unless anchors.empty?
          off=rng.rand(anchors.size)
          anchors=anchors[off..-1]+anchors[0...off]
        end
        hit=nil
        anchors.each do |a|
          hit=vxrd_landmark_png_make_placement_v10653(state,room,key,a[0],a[1])
          break unless hit==nil
        end
        placed << hit unless hit==nil
      end
      info={:code=>code,:enabled=>true,:placed=>placed.size,:max=>max,
        :placements=>placed,:reserved_cells=>state[:landmark_reserved_v10653].size,
        :renderer=>:png_sprite,:native_upper_tile_id=>false,
        :tileb_map_stamp=>false,:tilec_map_stamp=>false,:tiled_map_stamp=>false,
        :normal_rooms_only=>true,:corner_only=>true,:center_cross_safe=>true,
        :collision=>:deferred_visual_acceptance,:gameplay_change=>false}
      state[:landmarks_v10653]=info
      info
    rescue
      nil
    end

    # This wrapper runs OUTSIDE v1.06.45. The old map pipeline and its final
    # B/C/D/E purge finish first; then only PNG descriptors are created.
    alias pmd_ac_v10653_generate_current_map_v10582 vxrd_generate_current_map_v10582 unless method_defined?(:pmd_ac_v10653_generate_current_map_v10582)
    def vxrd_generate_current_map_v10582(code=nil,seed=nil,options=nil)
      st=pmd_ac_v10653_generate_current_map_v10582(code,seed,options)
      vxrd_apply_landmark_pngs_v10653(st) unless st==nil
      st
    rescue
      st
    end

    def vxrd_landmark_png_audit_v10653
      bad=[]
      VXRD_LANDMARK_PNG_TEMPLATES_V10653.each do |key,t|
        bad << (key.to_s+':size') unless t[:w].to_i==2 && t[:h].to_i==2
        path=VXRD_LANDMARK_PNG_DIR_V10653+t[:file].to_s+'.png'
        bad << (key.to_s+':file') unless FileTest.exist?(path)
        a=t[:source_atlas]
        bad << (key.to_s+':source') unless a.is_a?(Array) && a.size==2 && a.all?{|r|r.is_a?(Array) && r.size==2}
      end
      VXRD_LANDMARK_PNG_HUNT_PROFILE_V10653.each do |code,p|
        bad << (code+':templates') if (p[:templates]||[]).empty?
        (p[:templates]||[]).each{|k|bad << (code+':'+k.to_s) unless VXRD_LANDMARK_PNG_TEMPLATES_V10653.has_key?(k)}
      end
      {:pass=>bad.empty?,:templates=>VXRD_LANDMARK_PNG_TEMPLATES_V10653.size,
       :hunt_profiles=>VXRD_LANDMARK_PNG_HUNT_PROFILE_V10653.size,
       :renderer=>:png_sprite,:native_upper_tile_id=>false,
       :tilemap_stamp=>false,:collision=>:deferred_visual_acceptance,
       :source_assets=>'TileB/TileD curated crops',:bad=>bad}
    rescue Exception=>e
      {:pass=>false,:templates=>0,:hunt_profiles=>0,:bad=>[:audit_error],:error=>e.class.to_s}
    end

    def vxrd_write_landmark_png_audit_v10653
      a=vxrd_landmark_png_audit_v10653
      lines=[]
      lines << 'PMD AutoChess VXRD Landmark PNG Audit v1.06.53'
      lines << 'RESULT='+(a[:pass] ? 'PASS':'FAIL')
      lines << 'RENDERER=PNG_SPRITE'
      lines << 'NATIVE_UPPER_TILE_ID_USED=0'
      lines << 'MAP_TABLE_BCDE_STAMPING=0'
      lines << 'TEMPLATES='+a[:templates].to_i.to_s+'/6'
      lines << 'HUNT_PROFILES='+a[:hunt_profiles].to_i.to_s+'/5'
      lines << 'PROFILE_CODES='+VXRD_LANDMARK_PNG_HUNT_PROFILE_V10653.keys.sort.join(',')
      lines << 'COLLISION=DEFERRED_VISUAL_ACCEPTANCE'
      lines << 'EVENT_FOOTPRINT_RESERVATION=1'
      lines << 'BATTLE_MECHANICS_CHANGED=0'
      lines << 'REWARD_MECHANICS_CHANGED=0'
      lines << 'PROGRESSION_CHANGED=0'
      (a[:bad]||[]).each{|x|lines << 'ERROR='+x.to_s}
      File.open(VXRD_LANDMARK_PNG_AUDIT_LOG_V10653,'wb'){|io|io.write(lines.join("\r\n")+"\r\n")}
      a
    rescue
      {:pass=>false,:bad=>[:write_error]}
    end

    alias pmd_ac_v10653_write_project_state_log write_project_state_log unless method_defined?(:pmd_ac_v10653_write_project_state_log)
    def project_version
      '1.06.53'
    end
    def write_project_state_log(force=false)
      r=pmd_ac_v10653_write_project_state_log(force)
      return false unless r
      begin
        text='';File.open(PROJECT_STATE_FILE_V10564,'rb'){|io|text=io.read}
        text=text.gsub(/PROJECT_STATE_SCHEMA=\d+/,'PROJECT_STATE_SCHEMA=38')
        text=text.gsub(/CURRENT_VERSION=[^\r\n]+/,'CURRENT_VERSION=1.06.53')
        text=text.gsub(/LATEST_FEATURE=[^\r\n]+/,'LATEST_FEATURE=LANDMARK_PNG_AUTHORITY_FOUNDATION_I')
        text=text.gsub(/NEXT_TARGET=[^\r\n]+/,'NEXT_TARGET=LANDMARK_PNG_VISUAL_ACCEPTANCE+EVENT_VISUAL_ART_PASS')
        text=text.gsub(/\r?\nVXRD_LANDMARK_PNG_V10653_BEGIN.*?VXRD_LANDMARK_PNG_V10653_END\r?\n/m,"\r\n")
        a=vxrd_landmark_png_audit_v10653
        lines=[]
        lines << ''
        lines << 'VXRD_LANDMARK_PNG_V10653_BEGIN'
        lines << 'LANDMARK_PNG_AUTHORITY='+(a[:pass] ? 'PASS':'FAIL')
        lines << 'LANDMARK_RENDERER=PNG_SPRITE'
        lines << 'LANDMARK_NATIVE_UPPER_TILE_ID=0'
        lines << 'LANDMARK_MAP_TABLE_BCDE_STAMP=0'
        lines << 'LANDMARK_TEMPLATES='+a[:templates].to_i.to_s+'/6'
        lines << 'LANDMARK_HUNT_PROFILES='+a[:hunt_profiles].to_i.to_s+'/5'
        lines << 'LANDMARK_PROFILE_CODES='+VXRD_LANDMARK_PNG_HUNT_PROFILE_V10653.keys.sort.join(',')
        lines << 'LANDMARK_EVENT_RESERVATION=1'
        lines << 'LANDMARK_COLLISION=DEFERRED_VISUAL_ACCEPTANCE'
        lines << 'RMVX_EDITOR_RESTART_REQUIRED=1'
        lines << 'TUTORIAL_UPDATED=1'
        lines << 'VXRD_LANDMARK_PNG_V10653_END'
        File.open(PROJECT_STATE_FILE_V10564,'wb'){|io|io.write(text.rstrip+"\r\n"+lines.join("\r\n")+"\r\n")}
      rescue
      end
      true
    rescue
      false
    end
  end
end

module Cache
  def self.vxrd_landmark_v10653(filename)
    load_bitmap(PMD_AC::VXRD_LANDMARK_PNG_DIR_V10653,filename.to_s+'.png')
  end
end

class Spriteset_Map
  alias pmd_ac_v10653_initialize initialize unless method_defined?(:pmd_ac_v10653_initialize)
  def initialize
    @pmd_vxrd_landmark_sprites_v10653=[]
    @pmd_vxrd_landmark_token_v10653=nil
    pmd_ac_v10653_initialize
    pmd_vxrd_refresh_landmark_sprites_v10653
  end

  alias pmd_ac_v10653_update update unless method_defined?(:pmd_ac_v10653_update)
  def update
    pmd_ac_v10653_update
    pmd_vxrd_refresh_landmark_sprites_v10653
    pmd_vxrd_update_landmark_sprites_v10653
  end

  alias pmd_ac_v10653_dispose dispose unless method_defined?(:pmd_ac_v10653_dispose)
  def dispose
    pmd_vxrd_dispose_landmark_sprites_v10653
    pmd_ac_v10653_dispose
  end

  def pmd_vxrd_landmark_state_v10653
    return nil unless defined?(PMD_AC)
    PMD_AC.vxrd_state_v10582 rescue nil
  end

  def pmd_vxrd_landmark_token_for_state_v10653(st)
    return nil if st==nil
    info=st[:landmarks_v10653]
    return nil unless info.is_a?(Hash)
    [st.object_id,st[:seed].to_i,st[:generated_frame].to_i,info[:placed].to_i]
  rescue
    nil
  end

  def pmd_vxrd_dispose_landmark_sprites_v10653
    (@pmd_vxrd_landmark_sprites_v10653||[]).each do |entry|
      s=entry[:sprite] rescue nil
      s.dispose if s!=nil && !s.disposed?
    end
    @pmd_vxrd_landmark_sprites_v10653=[]
    @pmd_vxrd_landmark_token_v10653=nil
  rescue
  end

  def pmd_vxrd_refresh_landmark_sprites_v10653
    st=pmd_vxrd_landmark_state_v10653
    token=pmd_vxrd_landmark_token_for_state_v10653(st)
    return if token==@pmd_vxrd_landmark_token_v10653
    pmd_vxrd_dispose_landmark_sprites_v10653
    @pmd_vxrd_landmark_token_v10653=token
    return if st==nil || token==nil
    info=st[:landmarks_v10653]
    (info[:placements]||[]).each do |p|
      begin
        s=Sprite.new(@viewport1)
        s.bitmap=Cache.vxrd_landmark_v10653(p[:file])
        s.ox=0;s.oy=0;s.z=80
        @pmd_vxrd_landmark_sprites_v10653 << {:sprite=>s,:placement=>p}
      rescue
      end
    end
  rescue
  end

  def pmd_vxrd_update_landmark_sprites_v10653
    ox=$game_map==nil ? 0:$game_map.display_x.to_i/8
    oy=$game_map==nil ? 0:$game_map.display_y.to_i/8
    (@pmd_vxrd_landmark_sprites_v10653||[]).each do |entry|
      s=entry[:sprite];p=entry[:placement]
      next if s==nil || s.disposed? || p==nil
      a=p[:anchor]||[0,0]
      s.x=a[0].to_i*32-ox
      s.y=a[1].to_i*32-oy
      s.visible=true
      s.z=80
    end
  rescue
  end
end

begin
  PMD_AC.vxrd_write_landmark_png_audit_v10653
rescue
end
