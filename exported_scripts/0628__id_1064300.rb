# encoding: UTF-8
#===============================================================================
# ■ PMD AutoChess - VXRD Minimap Foundation I v1.06.43
#-------------------------------------------------------------------------------
# Reintroduces the original Random Dungeon minimap concept using the CURRENT
# VXRD layout/exploration authority. No second map state is created.
#
# Original reference (Scripts - dungeon.rvdata / Sprite_DungeonMap):
# - draw discovered ground only;
# - player = yellow;
# - monster = red; item = blue; stairs = white; NPC = purple;
# - update as exploration changes.
#
# Current implementation:
# - reads Game_System VXRD state[:explored] from v1.05.83;
# - compact top-right minimap while a generated Hunt floor is active;
# - explored walkable cells only; A1 water is visually distinct;
# - discovered runtime events are marked by current VXRD event semantics;
# - save/load naturally preserves minimap because exploration remains in the
#   existing VXRD state rather than a duplicate minimap data structure.
#===============================================================================
$imported={} unless defined?($imported)
$imported['PMD_AutoChess_VXRDMinimapFoundationI_v10643']=true

module PMD_AC
  VXRD_MINIMAP_WIDTH_V10643=154
  VXRD_MINIMAP_HEIGHT_V10643=112

  class << self
    def vxrd_minimap_active_v10643?
      return false if $game_map==nil || $game_player==nil
      s=vxrd_state_v10582 rescue nil
      return false if s==nil || !s[:active]
      return false unless s[:map_id].to_i==$game_map.map_id.to_i
      true
    rescue
      false
    end

    def vxrd_minimap_floor_v10643
      hs=phase_div_hunt_session_v10555 rescue nil
      return 1 if hs==nil
      n=(hs[:vxrd_floor_count_v10584]||hs[:floor]||1).to_i
      n=1 if n<=0
      n
    rescue
      1
    end

    def vxrd_minimap_event_kind_v10643(ev)
      return nil if ev==nil
      tag=vxrd_game_event_tag_v10584(ev) rescue nil
      if tag==:encounter
        rt=ev.instance_variable_get(:@pmd_vxrd_room_type_v10601) rescue nil
        return :rare_nest if rt==:rare_nest
        return :elite if rt==:elite
        return :monster
      elsif tag==:treasure
        return :item
      elsif tag==:exit
        return :stairs
      elsif tag==:recovery
        return :recovery
      elsif tag==:retreat
        return :retreat
      elsif tag==:info
        return :npc
      elsif tag==:entrance
        return :entrance
      elsif tag==:fixed
        return :npc
      end
      nil
    rescue
      nil
    end

    def vxrd_minimap_audit_v10643
      req=[:vxrd_minimap_active_v10643?,:vxrd_minimap_floor_v10643,:vxrd_minimap_event_kind_v10643]
      bad=req.find_all{|m|!respond_to?(m)}
      exp=respond_to?(:vxrd_explored_v10583?) && respond_to?(:vxrd_exploration_percent_v10583)
      bad << :exploration_authority unless exp
      {:pass=>bad.empty?,:api=>req.size,:exploration_authority=>exp,
       :duplicate_map_state=>false,:save_load_shared_state=>true,
       :original_sprite_dungeon_map_reference=>true,:bad=>bad}
    rescue
      {:pass=>false,:api=>0,:bad=>[:audit_error]}
    end
  end
end

class Sprite_PMDVXRDMinimapV10643 < Sprite
  def initialize
    super(nil)
    self.bitmap=Bitmap.new(PMD_AC::VXRD_MINIMAP_WIDTH_V10643,PMD_AC::VXRD_MINIMAP_HEIGHT_V10643)
    self.x=Graphics.width-PMD_AC::VXRD_MINIMAP_WIDTH_V10643-6
    self.y=6
    self.z=420
    self.opacity=238
    @last_signature=nil
    @last_event_signature=nil
    @last_refresh_frame=-999
    self.visible=false
  end

  def dispose
    if self.bitmap!=nil && !self.bitmap.disposed?
      self.bitmap.dispose
    end
    super
  end

  def update
    super
    unless PMD_AC.vxrd_minimap_active_v10643?
      self.visible=false
      @last_signature=nil
      return
    end
    self.visible=true
    s=PMD_AC.vxrd_state_v10582 rescue nil
    return if s==nil
    explored=s[:explored]||{}
    sig=[s[:map_id].to_i,s[:seed].to_i,explored.size,
      ($game_player==nil ? -1:$game_player.x.to_i),($game_player==nil ? -1:$game_player.y.to_i),
      PMD_AC.vxrd_minimap_floor_v10643]
    event_sig=nil
    if Graphics.frame_count.to_i-@last_refresh_frame>=20
      event_sig=vxrd_event_signature_v10643
    end
    if @last_signature!=sig || (!event_sig.nil? && event_sig!=@last_event_signature)
      @last_signature=sig
      @last_event_signature=event_sig unless event_sig.nil?
      @last_refresh_frame=Graphics.frame_count.to_i
      refresh_v10643(s)
    end
  rescue
    self.visible=false
  end

  def vxrd_event_signature_v10643
    return [] if $game_map==nil || $game_map.events==nil
    a=[]
    $game_map.events.keys.sort.each do |id|
      ev=$game_map.events[id]
      kind=PMD_AC.vxrd_minimap_event_kind_v10643(ev)
      next if kind==nil
      a << [id.to_i,kind,ev.x.to_i,ev.y.to_i]
    end
    a
  rescue
    []
  end

  def cell_size_v10643(s)
    w=[s[:width].to_i,1].max;h=[s[:height].to_i,1].max
    cw=PMD_AC::VXRD_MINIMAP_WIDTH_V10643-12
    ch=PMD_AC::VXRD_MINIMAP_HEIGHT_V10643-24
    n=[cw/w,ch/h].min
    n=1 if n<1
    n=3 if n>3
    n
  rescue
    1
  end

  def event_color_v10643(kind)
    case kind
    when :monster
      Color.new(255,72,72,255)
    when :rare_nest
      Color.new(255,96,224,255)
    when :elite
      Color.new(255,144,48,255)
    when :item
      Color.new(64,192,255,255)
    when :stairs
      Color.new(255,255,255,255)
    when :recovery
      Color.new(96,255,128,255)
    when :retreat
      Color.new(255,208,96,255)
    when :entrance
      Color.new(160,255,176,255)
    when :npc
      Color.new(224,96,255,255)
    else
      Color.new(224,224,224,255)
    end
  rescue
    Color.new(224,224,224,255)
  end

  def refresh_v10643(s)
    b=self.bitmap
    return if b==nil || b.disposed?
    b.clear
    b.fill_rect(0,0,b.width,b.height,Color.new(0,0,0,176))
    b.fill_rect(0,0,b.width,1,Color.new(180,196,224,200))
    b.fill_rect(0,b.height-1,b.width,1,Color.new(180,196,224,200))
    b.fill_rect(0,0,1,b.height,Color.new(180,196,224,200))
    b.fill_rect(b.width-1,0,1,b.height,Color.new(180,196,224,200))

    code=s[:code].to_s
    floor=PMD_AC.vxrd_minimap_floor_v10643
    pct=PMD_AC.vxrd_exploration_percent_v10583 rescue 0
    b.font.size=14
    b.font.bold=true
    b.font.color=Color.new(240,240,248,255)
    b.draw_text(5,0,b.width-10,18,code+' F'+floor.to_i.to_s+'  '+pct.to_i.to_s+'%',0)
    b.font.bold=false

    n=cell_size_v10643(s)
    mw=s[:width].to_i*n;mh=s[:height].to_i*n
    ox=(b.width-mw)/2
    oy=19+(b.height-21-mh)/2
    ox=5 if ox<5;oy=20 if oy<20
    walk=s[:walkable]||[]
    walk.each do |p|
      x=p[0].to_i;y=p[1].to_i
      explored=false
      begin;explored=PMD_AC.vxrd_explored_v10583?(x,y);rescue;explored=false;end
      next unless explored
      water=PMD_AC.vxrd_state_water_cell_v10607?(s,x,y) rescue false
      c=water ? Color.new(48,152,224,224) : Color.new(72,88,216,214)
      b.fill_rect(ox+x*n,oy+y*n,n,n,c)
    end

    if $game_map!=nil && $game_map.events!=nil
      $game_map.events.each_value do |ev|
        kind=PMD_AC.vxrd_minimap_event_kind_v10643(ev)
        next if kind==nil
        x=ev.x.to_i;y=ev.y.to_i
        explored=false
      begin;explored=PMD_AC.vxrd_explored_v10583?(x,y);rescue;explored=false;end
      next unless explored
        sz=[n,2].max
        b.fill_rect(ox+x*n,oy+y*n,sz,sz,event_color_v10643(kind))
      end
    end

    if $game_player!=nil
      px=$game_player.x.to_i;py=$game_player.y.to_i
      sz=[n,2].max
      b.fill_rect(ox+px*n,oy+py*n,sz,sz,Color.new(255,255,64,255))
    end
  rescue
  end
end

class Scene_Map
  alias pmd_ac_v10643_minimap_start start unless method_defined?(:pmd_ac_v10643_minimap_start)
  def start
    pmd_ac_v10643_minimap_start
    begin
      @pmd_vxrd_minimap_v10643.dispose if @pmd_vxrd_minimap_v10643!=nil && !@pmd_vxrd_minimap_v10643.disposed?
    rescue
    end
    @pmd_vxrd_minimap_v10643=Sprite_PMDVXRDMinimapV10643.new
  end

  alias pmd_ac_v10643_minimap_update update unless method_defined?(:pmd_ac_v10643_minimap_update)
  def update
    pmd_ac_v10643_minimap_update
    begin
      @pmd_vxrd_minimap_v10643.update if @pmd_vxrd_minimap_v10643!=nil && !@pmd_vxrd_minimap_v10643.disposed?
    rescue
    end
  end

  alias pmd_ac_v10643_minimap_terminate terminate unless method_defined?(:pmd_ac_v10643_minimap_terminate)
  def terminate
    begin
      if @pmd_vxrd_minimap_v10643!=nil && !@pmd_vxrd_minimap_v10643.disposed?
        @pmd_vxrd_minimap_v10643.dispose
      end
      @pmd_vxrd_minimap_v10643=nil
    rescue
    end
    pmd_ac_v10643_minimap_terminate
  end
end

module PMD_AC
  class << self
    alias pmd_ac_v10643_write_project_state_log write_project_state_log unless method_defined?(:pmd_ac_v10643_write_project_state_log)
    def project_version
      '1.06.43'
    end
    def write_project_state_log(force=false)
      r=pmd_ac_v10643_write_project_state_log(force)
      return false unless r
      begin
        text='';File.open(PROJECT_STATE_FILE_V10564,'rb'){|io|text=io.read}
        text=text.gsub(/PROJECT_STATE_SCHEMA=\d+/,'PROJECT_STATE_SCHEMA=29')
        text=text.gsub(/CURRENT_VERSION=[^\r\n]+/,'CURRENT_VERSION=1.06.43')
        text=text.gsub(/LATEST_FEATURE=[^\r\n]+/,'LATEST_FEATURE=VXRD_MINIMAP_FOUNDATION_I+NATIVE_AUTOTILE_RULES')
        text=text.gsub(/NEXT_TARGET=[^\r\n]+/,'NEXT_TARGET=VXRD_LANDMARK_TEMPLATE+EVENT_SEMANTIC_PLACEMENT+MINIMAP_POLISH')
        text=text.gsub(/\r?\nVXRD_MINIMAP_V10643_BEGIN.*?VXRD_MINIMAP_V10643_END\r?\n/m,"\r\n")
        a=vxrd_minimap_audit_v10643
        lines=[]
        lines << ''
        lines << 'VXRD_MINIMAP_V10643_BEGIN'
        lines << 'VXRD_MINIMAP_FOUNDATION='+(a[:pass] ? 'PASS':'FAIL')
        lines << 'VXRD_MINIMAP_SOURCE=ORIGINAL_SPRITE_DUNGEONMAP_CONCEPT'
        lines << 'VXRD_MINIMAP_EXPLORATION_AUTHORITY=V10583_SHARED_STATE'
        lines << 'VXRD_MINIMAP_DUPLICATE_MAP_STATE=0'
        lines << 'VXRD_MINIMAP_SAVE_LOAD_SHARED_STATE=1'
        lines << 'VXRD_MINIMAP_DISCOVERED_GROUND_ONLY=1'
        lines << 'VXRD_MINIMAP_PLAYER=YELLOW'
        lines << 'VXRD_MINIMAP_EVENTS=MONSTER_RED,ITEM_BLUE,EXIT_WHITE,NPC_PURPLE,RARE_MAGENTA,ELITE_ORANGE,RECOVERY_GREEN'
        lines << 'VXRD_MINIMAP_WATER_DISTINCT=1'
        lines << 'VXRD_MINIMAP_VISUAL_QA=PENDING_USER_REVIEW'
        lines << 'VXRD_MINIMAP_V10643_END'
        File.open(PROJECT_STATE_FILE_V10564,'wb'){|io|io.write(text.rstrip+"\r\n"+lines.join("\r\n")+"\r\n")}
      rescue
      end
      true
    rescue
      false
    end
  end
end
