# encoding: UTF-8
#===============================================================================
# ■ PMD AutoChess - VXRD Event Visual Identity I v1.06.47
#-------------------------------------------------------------------------------
# Replaces temporary Actor charset stand-ins on Random Hunt semantic events
# with runtime-drawn semantic markers. No external PNG is introduced.
#
# Visual authority (matches v1.06.43 minimap semantics):
# - normal encounter : red    / !
# - rare nest        : magenta/ R
# - elite            : orange / E
# - treasure         : blue   / T
# - recovery         : green  / +
# - exit             : white  / >
# - retreat          : gold   / <
# - info             : purple / i
# - entrance anchor  : hidden
#
# Scope is presentation only. Event trigger semantics, positions, room roles,
# battle/loot/recovery/retreat logic and progression remain unchanged.
#===============================================================================
$imported={} unless defined?($imported)
$imported['PMD_AutoChess_VXRDEventVisualIdentityI_v10647']=true

module PMD_AC
  VXRD_EVENT_VISUAL_PROFILE_V10647={
    :monster=>{:label=>'!',:rgb=>[255,72,72],  :shape=>:diamond},
    :rare_nest=>{:label=>'R',:rgb=>[255,96,224], :shape=>:diamond},
    :elite=>{:label=>'E',:rgb=>[255,144,48], :shape=>:diamond},
    :item=>{:label=>'T',:rgb=>[64,192,255],  :shape=>:square},
    :recovery=>{:label=>'+',:rgb=>[96,255,128], :shape=>:square},
    :stairs=>{:label=>'>',:rgb=>[255,255,255], :shape=>:square},
    :retreat=>{:label=>'<',:rgb=>[255,208,96], :shape=>:square},
    :npc=>{:label=>'i',:rgb=>[224,96,255], :shape=>:square}
  }

  class << self
    def vxrd_event_visual_active_v10647?
      return vxrd_minimap_active_v10643? if respond_to?(:vxrd_minimap_active_v10643?)
      return false if $game_map==nil
      s=vxrd_state_v10582 rescue nil
      s!=nil && s[:active] && s[:map_id].to_i==$game_map.map_id.to_i
    rescue
      false
    end

    def vxrd_event_visual_kind_v10647(ev)
      return nil if ev==nil
      tag=vxrd_game_event_tag_v10584(ev) rescue nil
      return nil if tag==nil || tag==:fixed || tag==:entrance
      if respond_to?(:vxrd_minimap_event_kind_v10643)
        k=vxrd_minimap_event_kind_v10643(ev) rescue nil
        return k unless k==:entrance || k==nil
      end
      if tag==:encounter
        rt=ev.instance_variable_get(:@pmd_vxrd_room_type_v10601) rescue nil
        return :rare_nest if rt==:rare_nest
        return :elite if rt==:elite
        return :monster
      end
      return :item if tag==:treasure
      return :stairs if tag==:exit
      return :recovery if tag==:recovery
      return :retreat if tag==:retreat
      return :npc if tag==:info
      nil
    rescue
      nil
    end

    def vxrd_event_visual_profile_v10647(kind)
      p=VXRD_EVENT_VISUAL_PROFILE_V10647[kind]
      p==nil ? nil : p.dup
    rescue
      nil
    end

    def vxrd_event_visual_suppress_placeholder_v10647(ev)
      return false if ev==nil
      kind=vxrd_event_visual_kind_v10647(ev)
      return false if kind==nil
      # These are semantic runtime events; the old Actor graphics were only
      # temporary stand-ins. Keep the Game_Event itself fully interactive.
      ev.instance_variable_set(:@tile_id,0)
      ev.instance_variable_set(:@character_name,'')
      ev.instance_variable_set(:@character_index,0)
      ev.instance_variable_set(:@pattern,1)
      ev.instance_variable_set(:@step_anime,false)
      ev.instance_variable_set(:@walk_anime,false)
      ev.instance_variable_set(:@direction_fix,true)
      ev.instance_variable_set(:@pmd_vxrd_event_visual_kind_v10647,kind)
      true
    rescue
      false
    end

    # v1.06.46 is the final semantic-placement author. Blank the temporary
    # charsets immediately after it assigns a semantic role.
    alias pmd_ac_v10647_event_set_semantic_visual_v10646 vxrd_event_set_semantic_visual_v10646 unless method_defined?(:pmd_ac_v10647_event_set_semantic_visual_v10646)
    def vxrd_event_set_semantic_visual_v10646(ev,tag,room_type=nil)
      r=pmd_ac_v10647_event_set_semantic_visual_v10646(ev,tag,room_type)
      vxrd_event_visual_suppress_placeholder_v10647(ev)
      r
    rescue
      r
    end

    def vxrd_event_visual_signature_v10647
      return [] if $game_map==nil || $game_map.events==nil
      out=[]
      $game_map.events.keys.sort.each do |id|
        ev=$game_map.events[id]
        kind=vxrd_event_visual_kind_v10647(ev)
        next if kind==nil
        out << [id.to_i,kind,ev.x.to_i,ev.y.to_i]
      end
      out
    rescue
      []
    end

    def vxrd_event_visual_audit_v10647
      req=[:vxrd_event_visual_active_v10647?,:vxrd_event_visual_kind_v10647,
        :vxrd_event_visual_profile_v10647,:vxrd_event_visual_suppress_placeholder_v10647]
      bad=req.find_all{|m|!respond_to?(m)}
      kinds=[:monster,:rare_nest,:elite,:item,:recovery,:stairs,:retreat,:npc]
      kinds.each{|k|bad << ('profile_'+k.to_s).to_sym unless VXRD_EVENT_VISUAL_PROFILE_V10647[k].is_a?(Hash)}
      {:pass=>bad.empty?,:api=>req.size,:profiles=>VXRD_EVENT_VISUAL_PROFILE_V10647.size,
       :external_png=>false,:placeholder_actor_charset=>false,:minimap_color_semantics_shared=>true,
       :gameplay_change=>false,:bad=>bad}
    rescue
      {:pass=>false,:api=>0,:profiles=>0,:bad=>[:audit_error]}
    end
  end
end

class Sprite_PMDVXRDEventMarkerV10647 < Sprite
  WIDTH=24
  HEIGHT=24

  def initialize(event_id,kind)
    super(nil)
    @event_id=event_id.to_i
    @kind=kind
    @profile=PMD_AC.vxrd_event_visual_profile_v10647(kind) || {}
    self.bitmap=Bitmap.new(WIDTH,HEIGHT)
    self.ox=WIDTH/2
    self.oy=HEIGHT
    @pulse_phase=(@event_id*17)%60
    redraw_v10647
    update
  end

  def dispose
    self.bitmap.dispose if self.bitmap!=nil && !self.bitmap.disposed?
    super
  end

  def event_v10647
    return nil if $game_map==nil || $game_map.events==nil
    $game_map.events[@event_id]
  rescue
    nil
  end

  def color_v10647(alpha=255)
    rgb=@profile[:rgb]||[224,224,224]
    Color.new(rgb[0].to_i,rgb[1].to_i,rgb[2].to_i,alpha.to_i)
  rescue
    Color.new(224,224,224,alpha.to_i)
  end

  def redraw_v10647
    b=self.bitmap
    return if b==nil || b.disposed?
    b.clear
    # Small dark backing keeps the marker readable over all RTP terrain while
    # leaving most of the tile visible.
    b.fill_rect(4,3,16,16,Color.new(0,0,0,168))
    c=color_v10647(248)
    if @profile[:shape]==:diamond
      b.fill_rect(10,1,4,2,c)
      b.fill_rect(7,3,10,2,c)
      b.fill_rect(5,5,14,8,c)
      b.fill_rect(7,13,10,2,c)
      b.fill_rect(10,15,4,2,c)
    else
      b.fill_rect(4,3,16,2,c)
      b.fill_rect(4,17,16,2,c)
      b.fill_rect(4,5,2,12,c)
      b.fill_rect(18,5,2,12,c)
    end
    b.font.size=15
    b.font.bold=true
    b.font.color=Color.new(255,255,255,255)
    b.font.shadow=true if b.font.respond_to?(:shadow=)
    b.draw_text(2,2,20,18,@profile[:label].to_s,1)
    b.font.bold=false
  rescue
  end

  def update
    super
    ev=event_v10647
    erased=(ev==nil ? true : ((ev.instance_variable_get(:@erased) rescue false) ? true:false))
    unless PMD_AC.vxrd_event_visual_active_v10647? && ev!=nil && !erased
      self.visible=false
      return
    end
    kind=PMD_AC.vxrd_event_visual_kind_v10647(ev)
    if kind!=@kind && kind!=nil
      @kind=kind
      @profile=PMD_AC.vxrd_event_visual_profile_v10647(kind) || {}
      redraw_v10647
    end
    PMD_AC.vxrd_event_visual_suppress_placeholder_v10647(ev)
    self.visible=(kind!=nil)
    return unless self.visible
    self.x=ev.screen_x.to_i
    self.y=ev.screen_y.to_i-30
    self.z=ev.screen_z.to_i+120
    # Rare/Elite receive a restrained pulse; ordinary nodes stay static so the
    # whole map does not blink like an airport departure board.
    if [:rare_nest,:elite].include?(@kind)
      f=(Graphics.frame_count.to_i+@pulse_phase)%48
      d=(f<24 ? f : 47-f)
      self.opacity=210+(d*45/23)
    else
      self.opacity=245
    end
  rescue
    self.visible=false
  end
end

class Spriteset_PMDVXRDEventMarkersV10647
  def initialize
    @sprites={}
    @signature=nil
    refresh_v10647
  end

  def dispose
    (@sprites||{}).each_value{|s|s.dispose if s!=nil && !s.disposed?}
    @sprites={}
  end

  def refresh_v10647
    sig=PMD_AC.vxrd_event_visual_signature_v10647
    return if sig==@signature
    @signature=sig
    dispose
    @signature=sig
    return unless PMD_AC.vxrd_event_visual_active_v10647?
    sig.each do |row|
      id=row[0].to_i;kind=row[1]
      @sprites[id]=Sprite_PMDVXRDEventMarkerV10647.new(id,kind)
    end
  rescue
    @sprites={}
  end

  def update
    unless PMD_AC.vxrd_event_visual_active_v10647?
      (@sprites||{}).each_value{|s|s.visible=false if s!=nil}
      return
    end
    refresh_v10647 if (Graphics.frame_count.to_i%15)==0
    (@sprites||{}).each_value{|s|s.update if s!=nil && !s.disposed?}
  rescue
  end
end

class Scene_Map
  alias pmd_ac_v10647_event_visual_start start unless method_defined?(:pmd_ac_v10647_event_visual_start)
  def start
    pmd_ac_v10647_event_visual_start
    begin
      @pmd_vxrd_event_markers_v10647.dispose if @pmd_vxrd_event_markers_v10647!=nil
    rescue
    end
    @pmd_vxrd_event_markers_v10647=Spriteset_PMDVXRDEventMarkersV10647.new
  end

  alias pmd_ac_v10647_event_visual_update update unless method_defined?(:pmd_ac_v10647_event_visual_update)
  def update
    pmd_ac_v10647_event_visual_update
    begin
      @pmd_vxrd_event_markers_v10647.update if @pmd_vxrd_event_markers_v10647!=nil
    rescue
    end
  end

  alias pmd_ac_v10647_event_visual_terminate terminate unless method_defined?(:pmd_ac_v10647_event_visual_terminate)
  def terminate
    begin
      @pmd_vxrd_event_markers_v10647.dispose if @pmd_vxrd_event_markers_v10647!=nil
      @pmd_vxrd_event_markers_v10647=nil
    rescue
    end
    pmd_ac_v10647_event_visual_terminate
  end
end

module PMD_AC
  class << self
    alias pmd_ac_v10647_write_project_state_log write_project_state_log unless method_defined?(:pmd_ac_v10647_write_project_state_log)
    def project_version
      '1.06.47'
    end
    def write_project_state_log(force=false)
      r=pmd_ac_v10647_write_project_state_log(force)
      return false unless r
      begin
        text='';File.open(PROJECT_STATE_FILE_V10564,'rb'){|io|text=io.read}
        text=text.gsub(/PROJECT_STATE_SCHEMA=\d+/,'PROJECT_STATE_SCHEMA=33')
        text=text.gsub(/CURRENT_VERSION=[^\r\n]+/,'CURRENT_VERSION=1.06.47')
        text=text.gsub(/LATEST_FEATURE=[^\r\n]+/,'LATEST_FEATURE=VXRD_EVENT_VISUAL_IDENTITY_I')
        text=text.gsub(/NEXT_TARGET=[^\r\n]+/,'NEXT_TARGET=LANDMARK_TEMPLATE_II_ATLAS_COORDS+EVENT_VISUAL_POLISH')
        text=text.gsub(/\r?\nVXRD_EVENT_VISUAL_V10647_BEGIN.*?VXRD_EVENT_VISUAL_V10647_END\r?\n/m,"\r\n")
        a=vxrd_event_visual_audit_v10647
        lines=[]
        lines << ''
        lines << 'VXRD_EVENT_VISUAL_V10647_BEGIN'
        lines << 'VXRD_EVENT_VISUAL_IDENTITY='+(a[:pass] ? 'PASS':'FAIL')
        lines << 'VXRD_EVENT_VISUAL_PROFILES='+a[:profiles].to_i.to_s+'/8'
        lines << 'VXRD_EVENT_VISUAL_RENDERER=RUNTIME_BITMAP_MARKERS'
        lines << 'VXRD_EVENT_VISUAL_EXTERNAL_PNG=0'
        lines << 'VXRD_EVENT_VISUAL_PLACEHOLDER_ACTOR_CHARSET=RETIRED'
        lines << 'VXRD_EVENT_VISUAL_MINIMAP_COLOR_SEMANTICS=SHARED'
        lines << 'VXRD_EVENT_VISUAL_GAMEPLAY_CHANGE=0'
        lines << 'VXRD_EVENT_VISUAL_V10647_END'
        File.open(PROJECT_STATE_FILE_V10564,'wb'){|io|io.write(text.rstrip+"\r\n"+lines.join("\r\n")+"\r\n")}
      rescue
      end
      true
    rescue
      false
    end
  end
end
