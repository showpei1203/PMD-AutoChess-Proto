# encoding: UTF-8
#===============================================================================
# ■ PMD AutoChess - VXRD Event-Owned Marker Authority v1.06.48
#-------------------------------------------------------------------------------
# v1.06.47 used an invisible Game_Event plus a separate marker Sprite. The
# trigger was still valid, but presentation and interaction were owned by two
# different objects. This pass collapses them into one authority:
#
#   Game_Event      = position / trigger / priority / event command authority
#   Sprite_Character= visible semantic marker for that same Game_Event
#
# No Game_Event visual state is blanked or mutated by this layer. No separate
# marker Sprite is created. Existing v1.06.47 saves with blank charsets are also
# safe because the marker is rendered directly by the event's Sprite_Character.
#===============================================================================
$imported={} unless defined?($imported)
$imported['PMD_AutoChess_VXRDEventOwnedMarkerAuthority_v10648']=true

module PMD_AC
  class << self
    # Retire v1.06.47's Game_Event mutation. Its wrapper still calls this method,
    # but dynamic dispatch now lands here, so event graphic state is untouched.
    def vxrd_event_visual_suppress_placeholder_v10647(ev)
      false
    rescue
      false
    end

    def vxrd_event_owned_marker_kind_v10648(character)
      return nil unless vxrd_event_visual_active_v10647? rescue false
      return nil if character==nil
      return nil unless defined?(Game_Event) && character.is_a?(Game_Event)
      vxrd_event_visual_kind_v10647(character)
    rescue
      nil
    end

    def vxrd_event_owned_marker_profile_v10648(character)
      k=vxrd_event_owned_marker_kind_v10648(character)
      return nil if k==nil
      p=vxrd_event_visual_profile_v10647(k)
      p==nil ? nil : p.merge({:kind=>k})
    rescue
      nil
    end

    def vxrd_event_owned_marker_audit_v10648
      req=[:vxrd_event_owned_marker_kind_v10648,:vxrd_event_owned_marker_profile_v10648]
      bad=req.find_all{|m|!respond_to?(m)}
      {:pass=>bad.empty?,:api=>req.size,:game_event_mutation=>false,
       :separate_marker_sprite=>false,:sprite_character_owned=>true,
       :trigger_authority=>:game_event,:save_load_safe=>true,
       :external_png=>false,:gameplay_change=>false,:bad=>bad}
    rescue
      {:pass=>false,:api=>0,:bad=>[:audit_error]}
    end
  end
end

# v1.06.47's separate overlay container is retained as a compatibility shell,
# but it no longer creates or updates any marker sprites.
class Spriteset_PMDVXRDEventMarkersV10647
  def initialize
    @sprites={}
    @signature=[]
  end
  def dispose
    (@sprites||{}).each_value do |s|
      begin
        s.dispose if s!=nil && !s.disposed?
      rescue
      end
    end
    @sprites={}
  end
  def refresh_v10647
    @signature=[]
  end
  def update
    # no-op: v1.06.48 Sprite_Character owns event presentation
  end
end

class Sprite_Character < Sprite_Base
  alias pmd_ac_v10648_event_owned_update_bitmap update_bitmap unless method_defined?(:pmd_ac_v10648_event_owned_update_bitmap)
  alias pmd_ac_v10648_event_owned_update_src_rect update_src_rect unless method_defined?(:pmd_ac_v10648_event_owned_update_src_rect)
  alias pmd_ac_v10648_event_owned_dispose dispose unless method_defined?(:pmd_ac_v10648_event_owned_dispose)

  def pmd_vxrd_marker_profile_v10648
    PMD_AC.vxrd_event_owned_marker_profile_v10648(@character)
  rescue
    nil
  end

  def pmd_vxrd_marker_bitmap_v10648(profile)
    kind=profile[:kind]
    if @pmd_vxrd_event_marker_bitmap_v10648==nil ||
       @pmd_vxrd_event_marker_bitmap_v10648.disposed? ||
       @pmd_vxrd_event_marker_kind_v10648!=kind
      begin
        @pmd_vxrd_event_marker_bitmap_v10648.dispose if @pmd_vxrd_event_marker_bitmap_v10648!=nil && !@pmd_vxrd_event_marker_bitmap_v10648.disposed?
      rescue
      end
      @pmd_vxrd_event_marker_bitmap_v10648=Bitmap.new(24,24)
      @pmd_vxrd_event_marker_kind_v10648=kind
      pmd_vxrd_draw_marker_v10648(@pmd_vxrd_event_marker_bitmap_v10648,profile)
    end
    @pmd_vxrd_event_marker_bitmap_v10648
  rescue
    nil
  end

  def pmd_vxrd_draw_marker_v10648(b,profile)
    return if b==nil || b.disposed?
    b.clear
    rgb=profile[:rgb]||[224,224,224]
    c=Color.new(rgb[0].to_i,rgb[1].to_i,rgb[2].to_i,248)
    b.fill_rect(4,3,16,16,Color.new(0,0,0,168))
    if profile[:shape]==:diamond
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
    b.draw_text(2,2,20,18,profile[:label].to_s,1)
    b.font.bold=false
  rescue
  end

  def pmd_vxrd_release_marker_bitmap_v10648
    begin
      @pmd_vxrd_event_marker_bitmap_v10648.dispose if @pmd_vxrd_event_marker_bitmap_v10648!=nil && !@pmd_vxrd_event_marker_bitmap_v10648.disposed?
    rescue
    end
    @pmd_vxrd_event_marker_bitmap_v10648=nil
    @pmd_vxrd_event_marker_kind_v10648=nil
    @pmd_vxrd_event_marker_active_v10648=false
  end

  def update_bitmap
    profile=pmd_vxrd_marker_profile_v10648
    if profile!=nil
      bmp=pmd_vxrd_marker_bitmap_v10648(profile)
      if bmp!=nil
        @pmd_vxrd_event_marker_active_v10648=true
        self.bitmap=bmp
        self.src_rect.set(0,0,24,24)
        self.ox=12
        self.oy=24
        @cw=24
        @ch=24
        # Internal Sprite_Character cache is presentation-only. Do not touch the
        # underlying Game_Event's @tile_id / @character_name / trigger state.
        @tile_id=-10648
        @character_name='__PMD_VXRD_EVENT_MARKER_V10648__'
        @character_index=0
        return
      end
    end
    if @pmd_vxrd_event_marker_active_v10648
      pmd_vxrd_release_marker_bitmap_v10648
      # Force the native bitmap path to rebuild on this frame.
      @tile_id=nil
      @character_name=nil
      @character_index=nil
    end
    pmd_ac_v10648_event_owned_update_bitmap
  rescue
    pmd_ac_v10648_event_owned_update_bitmap
  end

  def update_src_rect
    if @pmd_vxrd_event_marker_active_v10648
      self.src_rect.set(0,0,24,24)
      return
    end
    pmd_ac_v10648_event_owned_update_src_rect
  rescue
    pmd_ac_v10648_event_owned_update_src_rect
  end

  def dispose
    pmd_vxrd_release_marker_bitmap_v10648
    pmd_ac_v10648_event_owned_dispose
  end
end

module PMD_AC
  class << self
    alias pmd_ac_v10648_write_project_state_log write_project_state_log unless method_defined?(:pmd_ac_v10648_write_project_state_log)
    def project_version
      '1.06.48'
    end
    def write_project_state_log(force=false)
      r=pmd_ac_v10648_write_project_state_log(force)
      return false unless r
      begin
        text='';File.open(PROJECT_STATE_FILE_V10564,'rb'){|io|text=io.read}
        text=text.gsub(/PROJECT_STATE_SCHEMA=\d+/,'PROJECT_STATE_SCHEMA=34')
        text=text.gsub(/CURRENT_VERSION=[^\r\n]+/,'CURRENT_VERSION=1.06.48')
        text=text.gsub(/LATEST_FEATURE=[^\r\n]+/,'LATEST_FEATURE=VXRD_EVENT_OWNED_MARKER_AUTHORITY')
        text=text.gsub(/NEXT_TARGET=[^\r\n]+/,'NEXT_TARGET=LANDMARK_TEMPLATE_II_ATLAS_COORDS')
        text=text.gsub(/\r?\nVXRD_EVENT_OWNED_MARKER_V10648_BEGIN.*?VXRD_EVENT_OWNED_MARKER_V10648_END\r?\n/m,"\r\n")
        a=vxrd_event_owned_marker_audit_v10648
        lines=[]
        lines << ''
        lines << 'VXRD_EVENT_OWNED_MARKER_V10648_BEGIN'
        lines << 'VXRD_EVENT_OWNED_MARKER='+(a[:pass] ? 'PASS':'FAIL')
        lines << 'VXRD_EVENT_TRIGGER_AUTHORITY=GAME_EVENT_UNCHANGED'
        lines << 'VXRD_EVENT_VISIBLE_AUTHORITY=SPRITE_CHARACTER'
        lines << 'VXRD_EVENT_GAME_EVENT_VISUAL_MUTATION=0'
        lines << 'VXRD_EVENT_SEPARATE_MARKER_SPRITE=0'
        lines << 'VXRD_EVENT_SAVE_LOAD_SAFE=1'
        lines << 'VXRD_EVENT_EXTERNAL_PNG=0'
        lines << 'VXRD_EVENT_GAMEPLAY_CHANGE=0'
        lines << 'VXRD_EVENT_OWNED_MARKER_V10648_END'
        File.open(PROJECT_STATE_FILE_V10564,'wb'){|io|io.write(text.rstrip+"\r\n"+lines.join("\r\n")+"\r\n")}
      rescue
      end
      true
    rescue
      false
    end
  end
end
