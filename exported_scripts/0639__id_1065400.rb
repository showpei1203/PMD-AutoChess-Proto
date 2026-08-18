# encoding: UTF-8
#===============================================================================
# ■ PMD AutoChess - VXRD Landmark Single-Prop Semantic / Presence / Collision I
#   v1.06.54
#-------------------------------------------------------------------------------
# Real-machine visual acceptance repair after v1.06.53 FAIL.
#
# Fixes:
# - The six 64x64 Landmark PNG files are treated as 2x2 atlases of four
#   independent 32x32 props. Only one atlas cell is rendered per placement.
# - H01/H04/H09/H14/H19 each receive at least one placement attempt with a
#   deterministic fallback across safe non-entrance/non-exit rooms.
# - Logical footprint is 1x1 instead of the invalid 2x2 collage footprint.
# - H01 foliage/flowers are soft/passable decoration.
# - H04/H09/H14/H19 rock/crystal/ore props are hard/impassable.
# - Full route/collision audit remains deferred. This phase only aligns local
#   collision with obvious visual semantics.
#
# Invariants:
# - No B/C/D/E map table stamping.
# - v1.06.44 runtime upper-tile IDs remain revoked.
# - No battle/reward/progression changes.
#===============================================================================
$imported={} unless defined?($imported)
$imported['PMD_AutoChess_VXRDLandmarkSinglePropSemanticPresenceCollisionI_v10654']=true

module PMD_AC
  VXRD_LANDMARK_CELL_V10654=32
  VXRD_LANDMARK_AUDIT_LOG_V10654='PMD_VXRD_LandmarkSemantic_Audit_LATEST.log'

  # Existing 64x64 source PNGs are 2x2 atlases, not coherent 64x64 objects.
  # Variant index mapping: 0=TL, 1=TR, 2=BL, 3=BR.
  VXRD_LANDMARK_TEMPLATE_SEMANTICS_V10654={
    :forest_green_a=>{
      :file=>'forest_green_a',:label=>'森林低植被',:blocking=>false,
      :variants=>[0,1,2,3]
    },
    :forest_flower_a=>{
      :file=>'forest_flower_a',:label=>'森林花草',:blocking=>false,
      :variants=>[0,1,2,3]
    },
    :dry_rock_a=>{
      :file=>'dry_rock_a',:label=>'乾燥岩石',:blocking=>true,
      :variants=>[0,1,2,3]
    },
    :cave_crystal_a=>{
      :file=>'cave_crystal_a',:label=>'洞窟晶岩',:blocking=>true,
      :variants=>[0,1,2,3]
    },
    :mine_ore_a=>{
      :file=>'mine_ore_a',:label=>'礦坑礦石',:blocking=>true,
      :variants=>[0,1,2,3]
    },
    :volcanic_ore_a=>{
      :file=>'volcanic_ore_a',:label=>'火山礦晶',:blocking=>true,
      :variants=>[0,2,3]
    }
  }

  # Conservative visual density. Hard props are never allowed to form a 2x2
  # pile; a second hard prop is optional and must be far away.
  VXRD_LANDMARK_HUNT_PROFILE_V10654={
    'H01'=>{:templates=>[:forest_green_a,:forest_flower_a],:min=>2,:max=>3,
      :extra_chance=>55,:spacing=>3,:blocking=>false},
    'H04'=>{:templates=>[:dry_rock_a],:min=>1,:max=>2,
      :extra_chance=>30,:spacing=>5,:blocking=>true},
    'H09'=>{:templates=>[:cave_crystal_a],:min=>1,:max=>2,
      :extra_chance=>30,:spacing=>5,:blocking=>true},
    'H14'=>{:templates=>[:mine_ore_a],:min=>1,:max=>2,
      :extra_chance=>30,:spacing=>5,:blocking=>true},
    'H19'=>{:templates=>[:volcanic_ore_a],:min=>1,:max=>2,
      :extra_chance=>25,:spacing=>5,:blocking=>true}
  }

  class << self
    # Disable the failed v1.06.53 placement renderer at generation time. Its
    # Spriteset hook remains loaded but receives an empty placement list.
    def vxrd_apply_landmark_pngs_v10653(state)
      return nil if state==nil
      state[:landmark_reserved_v10653]={}
      state[:landmark_reserved_v10644]=state[:landmark_reserved_v10653]
      info={:code=>state[:code].to_s.upcase,:enabled=>false,:placed=>0,
        :placements=>[],:renderer=>:disabled_by_v10654,
        :native_upper_tile_id=>false,:collision=>:superseded_by_v10654,
        :battle_gameplay_change=>false}
      state[:landmarks_v10653]=info
      info
    rescue
      nil
    end

    def vxrd_landmark_profile_v10654(code)
      VXRD_LANDMARK_HUNT_PROFILE_V10654[code.to_s.upcase]
    rescue
      nil
    end

    def vxrd_landmark_room_type_v10654(state,room)
      return :normal if state==nil || room==nil
      types=state[:room_types_v10601]||{}
      types[room[:id].to_i] || :normal
    rescue
      :normal
    end

    def vxrd_landmark_room_candidates_v10654(state,rng)
      rooms=(state[:rooms]||[]).find_all do |r|
        t=vxrd_landmark_room_type_v10654(state,r)
        t!=:entrance && t!=:exit
      end
      preferred=[];fallback=[]
      rooms.each do |r|
        t=vxrd_landmark_room_type_v10654(state,r)
        if t==:normal
          preferred << r
        else
          fallback << r
        end
      end
      # Deterministic shuffle, Ruby 1.9/RGSS2 safe.
      out=[]
      [preferred,fallback].each do |ary|
        pool=ary.dup
        until pool.empty?
          out << pool.delete_at(rng.rand(pool.size))
        end
      end
      out
    rescue
      []
    end

    def vxrd_landmark_edge_anchors_v10654(room)
      return [] if room==nil
      x0=room[:x].to_i+1;y0=room[:y].to_i+1
      x1=room[:x].to_i+room[:w].to_i-2
      y1=room[:y].to_i+room[:h].to_i-2
      return [] if x1<x0 || y1<y0
      pts=[]
      # Corners first.
      pts << [x0,y0] << [x1,y0] << [x0,y1] << [x1,y1]
      # Then perimeter cells. This avoids the v1.06.53 failure mode where a
      # 2x2 footprint plus only four corners yielded zero valid positions.
      for x in x0..x1
        pts << [x,y0] << [x,y1]
      end
      for y in y0..y1
        pts << [x0,y] << [x1,y]
      end
      uniq=[];seen={}
      pts.each do |p|
        k=[p[0].to_i,p[1].to_i]
        next if seen[k]
        seen[k]=true;uniq << k
      end
      uniq
    rescue
      []
    end

    def vxrd_landmark_spacing_clear_v10654?(state,x,y,gap)
      h=state[:landmark_reserved_v10654]
      return true unless h.is_a?(Hash)
      g=[gap.to_i,1].max
      h.keys.each do |p|
        next unless p.is_a?(Array) && p.size>=2
        dx=(p[0].to_i-x.to_i).abs;dy=(p[1].to_i-y.to_i).abs
        return false if [dx,dy].max<g
      end
      true
    rescue
      false
    end

    def vxrd_landmark_cell_clear_v10654?(state,room,x,y,gap)
      shape={:w=>1,:h=>1}
      clear=false
      if respond_to?(:vxrd_landmark_footprint_clear_v10644?)
        clear=vxrd_landmark_footprint_clear_v10644?(state,room,shape,x,y)
      end
      return false unless clear
      vxrd_landmark_spacing_clear_v10654?(state,x,y,gap)
    rescue
      false
    end

    def vxrd_landmark_reserve_v10654(state,x,y,blocking)
      state[:landmark_reserved_v10654]={} unless state[:landmark_reserved_v10654].is_a?(Hash)
      state[:landmark_blocked_v10654]={} unless state[:landmark_blocked_v10654].is_a?(Hash)
      key=[x.to_i,y.to_i]
      state[:landmark_reserved_v10654][key]=true
      state[:landmark_blocked_v10654][key]=true if blocking
      # Existing Map091 relocation/event safety respects the legacy reservation
      # key. Reserve both soft and hard props against event overlap.
      state[:landmark_reserved_v10644]=state[:landmark_reserved_v10654]
      true
    rescue
      false
    end

    def vxrd_landmark_make_v10654(state,room,key,x,y,rng,gap)
      t=VXRD_LANDMARK_TEMPLATE_SEMANTICS_V10654[key.to_sym]
      return nil if t==nil
      return nil unless vxrd_landmark_cell_clear_v10654?(state,room,x,y,gap)
      variants=t[:variants]||[0]
      return nil if variants.empty?
      variant=variants[rng.rand(variants.size)].to_i
      blocking=t[:blocking] ? true:false
      return nil unless vxrd_landmark_reserve_v10654(state,x,y,blocking)
      sx=(variant%2)*VXRD_LANDMARK_CELL_V10654
      sy=(variant/2)*VXRD_LANDMARK_CELL_V10654
      {:template=>key.to_sym,:file=>t[:file].to_s,:label=>t[:label].to_s,
       :anchor=>[x.to_i,y.to_i],:w=>1,:h=>1,:room_id=>room[:id].to_i,
       :variant=>variant,:src_rect=>[sx,sy,VXRD_LANDMARK_CELL_V10654,VXRD_LANDMARK_CELL_V10654],
       :blocking=>blocking,:renderer=>:png_atlas_cell,
       :native_upper_tile_id=>false}
    rescue
      nil
    end

    def vxrd_landmark_try_room_v10654(state,room,prof,rng)
      keys=prof[:templates]||[];return nil if keys.empty?
      key=keys[rng.rand(keys.size)]
      anchors=vxrd_landmark_edge_anchors_v10654(room)
      unless anchors.empty?
        off=rng.rand(anchors.size)
        anchors=anchors[off..-1]+anchors[0...off]
      end
      anchors.each do |a|
        hit=vxrd_landmark_make_v10654(state,room,key,a[0],a[1],rng,prof[:spacing])
        return hit unless hit==nil
      end
      nil
    rescue
      nil
    end

    def vxrd_apply_landmarks_v10654(state)
      return nil if state==nil
      code=state[:code].to_s.upcase
      prof=vxrd_landmark_profile_v10654(code)
      state[:landmark_reserved_v10654]={}
      state[:landmark_blocked_v10654]={}
      state[:landmark_reserved_v10644]=state[:landmark_reserved_v10654]
      if prof==nil
        info={:code=>code,:enabled=>false,:placed=>0,:placements=>[],
          :renderer=>:png_atlas_cell,:native_upper_tile_id=>false,
          :map_table_bcde_stamp=>false,:battle_gameplay_change=>false}
        state[:landmarks_v10654]=info
        return info
      end

      rng=VXRD_RNG_V10582.new((state[:seed].to_i ^ 0x10654A91) & 0x7fffffff)
      rooms=vxrd_landmark_room_candidates_v10654(state,rng)
      placed=[]
      min=[prof[:min].to_i,1].max
      max=[prof[:max].to_i,min].max
      target=min
      while target<max && rng.rand(100)<prof[:extra_chance].to_i
        target+=1
      end

      # Multiple passes are intentional: after one room fails a particular
      # template/anchor choice, another deterministic pass may select a
      # different template and still satisfy the minimum presence gate.
      attempts=0
      while placed.size<target && attempts<3
        rooms.each do |room|
          break if placed.size>=target
          hit=vxrd_landmark_try_room_v10654(state,room,prof,rng)
          placed << hit unless hit==nil
        end
        attempts+=1
      end

      info={:code=>code,:enabled=>true,:placed=>placed.size,:target=>target,
        :minimum=>min,:maximum=>max,:placements=>placed,
        :reserved_cells=>state[:landmark_reserved_v10654].size,
        :blocked_cells=>state[:landmark_blocked_v10654].size,
        :presence_ok=>(placed.size>=min),:renderer=>:png_atlas_cell,
        :cell_size=>VXRD_LANDMARK_CELL_V10654,:native_upper_tile_id=>false,
        :tileb_map_stamp=>false,:tilec_map_stamp=>false,:tiled_map_stamp=>false,
        :entrance_exit_rooms_excluded=>true,:edge_preferred=>true,
        :local_semantic_collision=>true,:full_route_audit=>false,
        :landmark_passability_change=>true,:battle_gameplay_change=>false}
      state[:landmarks_v10654]=info
      info
    rescue
      nil
    end

    # Wrap the v1.06.53 generation chain. The old v1.06.53 apply call has been
    # neutralized above; this becomes the sole Landmark placement authority.
    alias pmd_ac_v10654_generate_current_map_v10582 vxrd_generate_current_map_v10582 unless method_defined?(:pmd_ac_v10654_generate_current_map_v10582)
    def vxrd_generate_current_map_v10582(code=nil,seed=nil,options=nil)
      st=pmd_ac_v10654_generate_current_map_v10582(code,seed,options)
      vxrd_apply_landmarks_v10654(st) unless st==nil
      st
    rescue
      st
    end

    def vxrd_landmark_blocked_v10654?(x,y)
      return false if $game_map==nil || $game_map.map_id.to_i!=90
      st=vxrd_state_v10582 rescue nil
      return false if st==nil
      h=st[:landmark_blocked_v10654]
      h.is_a?(Hash) && h[[x.to_i,y.to_i]] ? true:false
    rescue
      false
    end

    def vxrd_landmark_audit_v10654
      bad=[]
      VXRD_LANDMARK_TEMPLATE_SEMANTICS_V10654.each do |key,t|
        path=VXRD_LANDMARK_PNG_DIR_V10653+t[:file].to_s+'.png'
        bad << (key.to_s+':file') unless FileTest.exist?(path)
        v=t[:variants]
        bad << (key.to_s+':variants') unless v.is_a?(Array) && !v.empty? && v.all?{|n|n.to_i>=0 && n.to_i<=3}
      end
      VXRD_LANDMARK_HUNT_PROFILE_V10654.each do |code,p|
        bad << (code+':min') if p[:min].to_i<1
        bad << (code+':max') if p[:max].to_i<p[:min].to_i
        (p[:templates]||[]).each do |k|
          bad << (code+':'+k.to_s) unless VXRD_LANDMARK_TEMPLATE_SEMANTICS_V10654.has_key?(k)
        end
      end
      soft=VXRD_LANDMARK_TEMPLATE_SEMANTICS_V10654.find_all{|k,t|!t[:blocking]}.collect{|x|x[0]}
      hard=VXRD_LANDMARK_TEMPLATE_SEMANTICS_V10654.find_all{|k,t|t[:blocking]}.collect{|x|x[0]}
      {:pass=>bad.empty?,:templates=>VXRD_LANDMARK_TEMPLATE_SEMANTICS_V10654.size,
       :hunt_profiles=>VXRD_LANDMARK_HUNT_PROFILE_V10654.size,
       :soft=>soft,:hard=>hard,:renderer=>:png_atlas_cell,
       :map_table_stamp=>false,:native_upper_tile_id=>false,:bad=>bad}
    rescue Exception=>e
      {:pass=>false,:templates=>0,:hunt_profiles=>0,:bad=>[:audit_error],:error=>e.class.to_s}
    end

    def vxrd_write_landmark_audit_v10654
      a=vxrd_landmark_audit_v10654
      lines=[]
      lines << 'PMD AutoChess VXRD Landmark Semantic Audit v1.06.54'
      lines << 'RESULT='+(a[:pass] ? 'PASS':'FAIL')
      lines << 'RENDERER=PNG_ATLAS_CELL_32X32'
      lines << 'FULL_64X64_COLLAGE_RENDERED=0'
      lines << 'NATIVE_UPPER_TILE_ID_USED=0'
      lines << 'MAP_TABLE_BCDE_STAMPING=0'
      lines << 'TEMPLATES='+a[:templates].to_i.to_s+'/6'
      lines << 'HUNT_PROFILES='+a[:hunt_profiles].to_i.to_s+'/5'
      lines << 'PROFILE_CODES='+VXRD_LANDMARK_HUNT_PROFILE_V10654.keys.sort.join(',')
      lines << 'MINIMUM_VISIBLE_PRESENCE=1'
      lines << 'LOGICAL_FOOTPRINT=1X1'
      lines << 'SOFT_PASSABLE='+((a[:soft]||[]).collect{|x|x.to_s}.sort.join(','))
      lines << 'HARD_BLOCKING='+((a[:hard]||[]).collect{|x|x.to_s}.sort.join(','))
      lines << 'LOCAL_SEMANTIC_COLLISION=1'
      lines << 'FULL_ROUTE_AUDIT=0'
      lines << 'BATTLE_MECHANICS_CHANGED=0'
      lines << 'REWARD_MECHANICS_CHANGED=0'
      lines << 'PROGRESSION_CHANGED=0'
      (a[:bad]||[]).each{|x|lines << 'ERROR='+x.to_s}
      File.open(VXRD_LANDMARK_AUDIT_LOG_V10654,'wb'){|io|io.write(lines.join("\r\n")+"\r\n")}
      a
    rescue
      {:pass=>false,:bad=>[:write_error]}
    end

    alias pmd_ac_v10654_write_project_state_log write_project_state_log unless method_defined?(:pmd_ac_v10654_write_project_state_log)
    def project_version
      '1.06.54'
    end
    def write_project_state_log(force=false)
      r=pmd_ac_v10654_write_project_state_log(force)
      return false unless r
      begin
        text='';File.open(PROJECT_STATE_FILE_V10564,'rb'){|io|text=io.read}
        text=text.gsub(/PROJECT_STATE_SCHEMA=\d+/,'PROJECT_STATE_SCHEMA=39')
        text=text.gsub(/CURRENT_VERSION=[^\r\n]+/,'CURRENT_VERSION=1.06.54')
        text=text.gsub(/LATEST_FEATURE=[^\r\n]+/,'LATEST_FEATURE=LANDMARK_SINGLE_PROP_SEMANTIC_PRESENCE_COLLISION_I')
        text=text.gsub(/NEXT_TARGET=[^\r\n]+/,'NEXT_TARGET=H01_H04_H09_H14_H19_VISUAL_INTERACTION_ACCEPTANCE')
        text=text.gsub(/\r?\nVXRD_LANDMARK_V10654_BEGIN.*?VXRD_LANDMARK_V10654_END\r?\n/m,"\r\n")
        a=vxrd_landmark_audit_v10654
        lines=[]
        lines << ''
        lines << 'VXRD_LANDMARK_V10654_BEGIN'
        lines << 'LANDMARK_SEMANTIC_AUTHORITY='+(a[:pass] ? 'PASS':'FAIL')
        lines << 'LANDMARK_RENDERER=PNG_ATLAS_CELL_32X32'
        lines << 'LANDMARK_FULL_COLLAGE_RENDER=0'
        lines << 'LANDMARK_NATIVE_UPPER_TILE_ID=0'
        lines << 'LANDMARK_MAP_TABLE_BCDE_STAMP=0'
        lines << 'LANDMARK_HUNT_PROFILES='+a[:hunt_profiles].to_i.to_s+'/5'
        lines << 'LANDMARK_MINIMUM_PRESENCE=1'
        lines << 'LANDMARK_LOCAL_SEMANTIC_COLLISION=1'
        lines << 'LANDMARK_FULL_ROUTE_AUDIT=0'
        lines << 'RMVX_EDITOR_RESTART_REQUIRED=1'
        lines << 'TUTORIAL_UPDATED=1'
        lines << 'VXRD_LANDMARK_V10654_END'
        File.open(PROJECT_STATE_FILE_V10564,'wb'){|io|io.write(text.rstrip+"\r\n"+lines.join("\r\n")+"\r\n")}
      rescue
      end
      true
    rescue
      false
    end
  end
end

# Hard physical Landmark cells participate in ordinary walking passability.
# This is intentionally local semantic collision only; no route audit is run.
class Game_Map
  alias pmd_ac_v10654_passable passable? unless method_defined?(:pmd_ac_v10654_passable)
  def passable?(x,y,flag=0x01)
    if flag.to_i==0x01 && defined?(PMD_AC) && PMD_AC.vxrd_landmark_blocked_v10654?(x,y)
      return false
    end
    pmd_ac_v10654_passable(x,y,flag)
  rescue
    pmd_ac_v10654_passable(x,y,flag)
  end
end

class Spriteset_Map
  alias pmd_ac_v10654_initialize initialize unless method_defined?(:pmd_ac_v10654_initialize)
  def initialize
    @pmd_vxrd_landmark_sprites_v10654=[]
    @pmd_vxrd_landmark_token_v10654=nil
    pmd_ac_v10654_initialize
    pmd_vxrd_refresh_landmark_sprites_v10654
  end

  alias pmd_ac_v10654_update update unless method_defined?(:pmd_ac_v10654_update)
  def update
    pmd_ac_v10654_update
    pmd_vxrd_refresh_landmark_sprites_v10654
    pmd_vxrd_update_landmark_sprites_v10654
  end

  alias pmd_ac_v10654_dispose dispose unless method_defined?(:pmd_ac_v10654_dispose)
  def dispose
    pmd_vxrd_dispose_landmark_sprites_v10654
    pmd_ac_v10654_dispose
  end

  def pmd_vxrd_landmark_state_v10654
    return nil unless defined?(PMD_AC)
    PMD_AC.vxrd_state_v10582 rescue nil
  end

  def pmd_vxrd_landmark_token_for_state_v10654(st)
    return nil if st==nil
    info=st[:landmarks_v10654]
    return nil unless info.is_a?(Hash)
    sig=(info[:placements]||[]).collect do |p|
      a=p[:anchor]||[0,0]
      [p[:template].to_s,p[:variant].to_i,a[0].to_i,a[1].to_i,p[:blocking] ? 1:0]
    end
    [st.object_id,st[:seed].to_i,st[:generated_frame].to_i,info[:placed].to_i,sig]
  rescue
    nil
  end

  def pmd_vxrd_dispose_landmark_sprites_v10654
    (@pmd_vxrd_landmark_sprites_v10654||[]).each do |entry|
      s=entry[:sprite] rescue nil
      s.dispose if s!=nil && !s.disposed?
    end
    @pmd_vxrd_landmark_sprites_v10654=[]
    @pmd_vxrd_landmark_token_v10654=nil
  rescue
  end

  def pmd_vxrd_refresh_landmark_sprites_v10654
    st=pmd_vxrd_landmark_state_v10654
    token=pmd_vxrd_landmark_token_for_state_v10654(st)
    return if token==@pmd_vxrd_landmark_token_v10654
    pmd_vxrd_dispose_landmark_sprites_v10654
    @pmd_vxrd_landmark_token_v10654=token
    return if st==nil || token==nil
    info=st[:landmarks_v10654]
    (info[:placements]||[]).each do |p|
      begin
        s=Sprite.new(@viewport1)
        s.bitmap=Cache.vxrd_landmark_v10653(p[:file])
        r=p[:src_rect]||[0,0,32,32]
        s.src_rect.set(r[0].to_i,r[1].to_i,r[2].to_i,r[3].to_i)
        s.ox=0;s.oy=0;s.z=80
        @pmd_vxrd_landmark_sprites_v10654 << {:sprite=>s,:placement=>p}
      rescue
      end
    end
  rescue
  end

  def pmd_vxrd_update_landmark_sprites_v10654
    ox=$game_map==nil ? 0:$game_map.display_x.to_i/8
    oy=$game_map==nil ? 0:$game_map.display_y.to_i/8
    (@pmd_vxrd_landmark_sprites_v10654||[]).each do |entry|
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
  PMD_AC.vxrd_write_landmark_audit_v10654
rescue
end
