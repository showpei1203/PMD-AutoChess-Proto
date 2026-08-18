#==============================================================================
# 【PMD AutoChess 中文維護說明】
# 腳本：PMD AutoChess Proto v0.30
# 分類：核心戰鬥 Runtime
#
# 【用途／機制】
# 承接前序 Data／Config，實際執行戰鬥 Scene、Unit、AI、技能與呈現。
#
# 【怎麼調整】
# 一般平衡與資料調整不要直接改 Runtime；若要追加功能，建議在較後腳本 alias 原方法後擴充。
#
# 【本腳本主要設定常數／資料表】
# - SKILL_FX_FOLDER_V030 / VERIFICATION_SKILL_VISUAL_END_FRAME / VERIFICATION_MODES / VERIFICATION_LABELS
#
# 【PMD_AC 對外／共用方法】
# - bitmap_for
#
# 【Runtime 主要方法（查流程時可直接搜尋）】
# - skill_visual_manifest_v030 / skill_visual_beam_profile_v030 / skill_visual_projectile_profile_v030 / skill_visual_impact_profile_v030
# - skill_visual_move_profile_v030 / skill_visual_load_bitmap_v030 / skill_data / skill_visual_scalar_v030
# - skill_visual_checksum32_v030 / validate_skill_visual_v030 / initialize / disposed?
#
# 【維護規則】
# - RPG Maker VX / RGSS2 / Ruby 1.8 相容。
# - instance_uid 才是 Pokémon 個體身份；Actor ID 只是容器。
# - 新增行為優先沿用既有 helper／Data 表；避免破壞已 Freeze 的舊核心。
# - 本專案新腳本也必須保留同等級的中文說明與實際範例。
#==============================================================================
#==============================================================================
# ■ PMD AutoChess Proto v0.30
#    Skill Visual Foundation
#------------------------------------------------------------------------------
#  Visual-only extension on verified v0.29. Combat calculations, projectile
#  collision, tracking, evade, and canonical move semantics remain unchanged.
#==============================================================================
module PMD_AC
  SKILL_FX_FOLDER_V030 = "Graphics/Pictures/PMD_SkillFX/"
  VERIFICATION_SKILL_VISUAL_END_FRAME = 390

  class << self
    alias pmd_ac_v030_skill_data skill_data unless method_defined?(:pmd_ac_v030_skill_data)

    def skill_visual_manifest_v030; SKILL_VISUAL_MANIFEST_V030; end
    def skill_visual_beam_profile_v030(style); SKILL_VISUAL_BEAM_V030[style]; end
    def skill_visual_projectile_profile_v030(style); SKILL_VISUAL_PROJECTILE_V030[style]; end
    def skill_visual_impact_profile_v030(style); SKILL_VISUAL_IMPACT_V030[style]; end
    def skill_visual_move_profile_v030(move_key); SKILL_VISUAL_MOVE_V030[move_key]; end

    def skill_visual_load_bitmap_v030(name)
      Cache.load_bitmap(SKILL_FX_FOLDER_V030, name)
    end

    def skill_data(key)
      data=pmd_ac_v030_skill_data(key)
      return data if data==nil || data.empty?
      mk=data[:canonical_move_key]
      return data if mk==nil
      visual=skill_visual_move_profile_v030(mk)
      return data if visual==nil
      r=data.dup
      r[:visual_kind]=visual[:visual_kind]
      r[:visual_style]=visual[:style]
      r
    end

    def skill_visual_scalar_v030(v)
      return "" if v==nil
      return v ? "true" : "false" if v==true || v==false
      v.to_s
    end

    def skill_visual_checksum32_v030
      h=0
      groups=[["B",SKILL_VISUAL_BEAM_V030],["P",SKILL_VISUAL_PROJECTILE_V030],["I",SKILL_VISUAL_IMPACT_V030],["M",SKILL_VISUAL_MOVE_V030]]
      for pair in groups
        prefix=pair[0];group=pair[1]
        for key in group.keys.sort{|a,b|a.to_s<=>b.to_s}
          r=group[key]
          fields=r.keys.sort{|a,b|a.to_s<=>b.to_s}.collect{|f|f.to_s+"="+skill_visual_scalar_v030(r[f])}
          text=([prefix,key.to_s]+fields).join("|")
          text.each_byte{|by|h=((h*33)+by)&0x7fffffff}
        end
      end
      h
    end

    def validate_skill_visual_v030
      e=[];m=SKILL_VISUAL_MANIFEST_V030
      e.push("beam_count") unless SKILL_VISUAL_BEAM_V030.size==4
      e.push("projectile_count") unless SKILL_VISUAL_PROJECTILE_V030.size==4
      e.push("impact_count") unless SKILL_VISUAL_IMPACT_V030.size==5
      e.push("move_count") unless SKILL_VISUAL_MOVE_V030.size==10
      e.push("water_head") unless SKILL_VISUAL_BEAM_V030[:water][:head]=="Ranger_109"
      e.push("water_body") unless SKILL_VISUAL_BEAM_V030[:water][:body]=="Ranger_105"
      e.push("electric_motion") unless SKILL_VISUAL_BEAM_V030[:electric][:motion]==:jitter
      e.push("fire_motion") unless SKILL_VISUAL_BEAM_V030[:fire][:motion]==:burn
      e.push("checksum") unless skill_visual_checksum32_v030==m[:runtime_checksum32].to_i
      e
    end
  end

  remove_const(:VERIFICATION_MODES) if const_defined?(:VERIFICATION_MODES)
  VERIFICATION_MODES=[:normal,:control,:beam,:zone,:hit,:energy,:direction,:object,:summon,:identity,
    :progression,:individual,:mega,:synergy,:species_db,:move_db,:move_runtime,:stat_stage,:sustain,
    :secondary,:speed_status,:action_status,:ability,:ability_trigger,:ability_passive,:accuracy_evasion,
    :weather,:weather_visual,:skill_visual]
  remove_const(:VERIFICATION_LABELS) if const_defined?(:VERIFICATION_LABELS)
  VERIFICATION_LABELS={:normal=>"NORMAL",:control=>"CONTROL",:beam=>"BEAM",:zone=>"ZONE",:hit=>"HIT",
    :energy=>"ENERGY",:direction=>"DIRECTION",:object=>"OBJECT",:summon=>"SUMMON",:identity=>"IDENTITY",
    :progression=>"PROGRESSION",:individual=>"INDIVIDUAL",:mega=>"MEGA",:synergy=>"SYNERGY",
    :species_db=>"SPECIES_DB",:move_db=>"MOVE_DB",:move_runtime=>"MOVE_RUNTIME",:stat_stage=>"STAT_STAGE",
    :sustain=>"SUSTAIN",:secondary=>"SECONDARY",:speed_status=>"SPEED_STATUS",:action_status=>"ACTION_STATUS",
    :ability=>"ABILITY",:ability_trigger=>"ABILITY_TRIGGER",:ability_passive=>"ABILITY_PASSIVE",
    :accuracy_evasion=>"ACCURACY_EVASION",:weather=>"WEATHER",:weather_visual=>"WEATHER_VISUAL",
    :skill_visual=>"SKILL_VISUAL"}
end

#==============================================================================
# ■ PMD_AC_SkillBeamVisualV030
#    Animated texture beam with optional fixed-size target head.
#==============================================================================
class PMD_AC_SkillBeamVisualV030
  attr_reader :finished
  def initialize(viewport,source,target,style,life=24,width=nil)
    @viewport=viewport;@source=source;@target=target;@style=style
    @profile=PMD_AC.skill_visual_beam_profile_v030(style)
    @life=[life.to_i,1].max;@max_life=@life;@finished=false;@frame=0;@frame_wait=0
    @body=nil;@head=nil
    create_sprites
    update_geometry
  end
  def disposed?;(@body==nil || @body.disposed?) && (@head==nil || @head.disposed?);end
  def source_alive?;@source.is_a?(Array) || (@source!=nil && @source.alive?);end
  def target_alive?;@target.is_a?(Array) || (@target!=nil && @target.alive?);end
  def point(obj)
    return [obj[0].to_f,obj[1].to_f] if obj.is_a?(Array)
    return [0.0,0.0] if obj==nil
    [obj.visual_center_x.to_f,obj.visual_center_y.to_f]
  end
  def create_sprites
    return if @profile==nil
    @body=Sprite.new(@viewport);@body.bitmap=PMD_AC.skill_visual_load_bitmap_v030(@profile[:body]);@body.z=9260
    @body.ox=0;@body.oy=@profile[:frame_h].to_i/2;@body.blend_type=(@profile[:blend]||0).to_i
    if @profile[:head]!=nil
      @head=Sprite.new(@viewport);@head.bitmap=PMD_AC.skill_visual_load_bitmap_v030(@profile[:head]);@head.z=9261
      hw=(@profile[:head_src_w]||@profile[:head_sheet_w]).to_i;hh=@profile[:head_frame_h].to_i
      @head.ox=hw;@head.oy=hh/2;@head.blend_type=(@profile[:blend]||0).to_i
    end
    update_src_rects
  end
  def update_src_rects
    return if @profile==nil
    bf=@frame % [@profile[:frames].to_i,1].max
    @body.src_rect.set((@profile[:body_src_x]||0).to_i,bf*@profile[:frame_h].to_i,@profile[:body_src_w].to_i,@profile[:frame_h].to_i)
    if @head!=nil
      hf=@frame % [@profile[:head_frames].to_i,1].max
      @head.src_rect.set((@profile[:head_src_x]||0).to_i,hf*@profile[:head_frame_h].to_i,@profile[:head_src_w].to_i,@profile[:head_frame_h].to_i)
    end
  end
  def update_geometry
    return if @profile==nil || @body==nil
    p1=point(@source);p2=point(@target);dx=p2[0]-p1[0];dy=p2[1]-p1[1];len=Math.sqrt(dx*dx+dy*dy)
    ang=-Math.atan2(dy,dx)*180.0/Math::PI
    jitter=0.0
    if @profile[:motion]==:jitter
      jitter=[-2.0,1.0,2.0,-1.0][Graphics.frame_count % 4]
    elsif @profile[:motion]==:burn
      jitter=[0.0,1.0,0.0,-1.0][Graphics.frame_count % 4]
    end
    nx=len>0.001 ? (-dy/len) : 0.0;ny=len>0.001 ? (dx/len) : 0.0
    sx=p1[0]+nx*jitter;sy=p1[1]+ny*jitter
    head_len=@head==nil ? 0.0 : (@profile[:head_display_w]||36).to_f
    body_len=[len-head_len,4.0].max
    @body.x=sx.to_i;@body.y=sy.to_i;@body.angle=ang
    @body.zoom_x=body_len/[(@profile[:body_src_w]||136).to_f,1.0].max
    @body.zoom_y=(@profile[:thickness]||0.55).to_f
    if @head!=nil
      @head.x=p2[0].to_i;@head.y=p2[1].to_i;@head.angle=ang
      @head.zoom_x=head_len/[(@profile[:head_src_w]||68).to_f,1.0].max
      @head.zoom_y=(@profile[:head_zoom_y]||@profile[:thickness]||0.6).to_f
    end
  end
  def update
    return if @finished
    unless source_alive? && target_alive?;finish;return;end
    @life-=1;@frame_wait-=1
    if @frame_wait<=0
      @frame+=1;@frame_wait=[(@profile[:frame_wait]||3).to_i,1].max;update_src_rects
    end
    update_geometry
    fade=[@life*22,255].min
    @body.opacity=fade if @body!=nil;@head.opacity=fade if @head!=nil
    finish if @life<=0
  end
  def finish;@finished=true;@body.visible=false if @body!=nil;@head.visible=false if @head!=nil;end
  def dispose
    @body.dispose if @body!=nil && !@body.disposed?
    @head.dispose if @head!=nil && !@head.disposed?
  end
end

#==============================================================================
# ■ Sprite_PMDSkillImpactV030
#==============================================================================
class Sprite_PMDSkillImpactV030 < Sprite
  attr_reader :finished
  def initialize(viewport,x,y,style,delay=0)
    super(viewport);@profile=PMD_AC.skill_visual_impact_profile_v030(style);@finished=false;@delay=[delay.to_i,0].max;@frame=0;@wait=0
    if @profile==nil;@finished=true;self.visible=false;return;end
    self.bitmap=PMD_AC.skill_visual_load_bitmap_v030(@profile[:sheet]);self.ox=@profile[:frame_w].to_i/2;self.oy=@profile[:frame_h].to_i/2
    self.x=x.to_i;self.y=y.to_i;self.z=9270;self.zoom_x=(@profile[:zoom]||1.0).to_f;self.zoom_y=self.zoom_x;self.blend_type=(@profile[:blend]||0).to_i
    self.visible=(@delay<=0);update_src
  end
  def update_src;self.src_rect.set(0,@frame*@profile[:frame_h].to_i,@profile[:frame_w].to_i,@profile[:frame_h].to_i);end
  def update
    super;return if @finished
    if @delay>0;@delay-=1;self.visible=true if @delay<=0;return;end
    @wait-=1
    if @wait<=0
      @frame+=1;@wait=[(@profile[:frame_wait]||3).to_i,1].max
      if @frame>=@profile[:frames].to_i;@finished=true;self.visible=false;return;end
      update_src
    end
  end
  def dispose;super;end
end

#==============================================================================
# ■ Sprite_PMDSkillTrailV030 - shared tiny bitmap, no per-frame allocation.
#==============================================================================
class Sprite_PMDSkillTrailV030 < Sprite
  attr_reader :finished
  @@bitmaps={}
  def self.bitmap_for(style)
    return @@bitmaps[style] if @@bitmaps[style]!=nil && !@@bitmaps[style].disposed?
    b=Bitmap.new(12,12)
    c=case style;when :fire;Color.new(255,120,35,190);when :water;Color.new(80,205,255,170);when :electric;Color.new(255,235,70,190);when :seed;Color.new(110,220,100,170);else;Color.new(220,235,255,160);end
    b.fill_rect(3,3,6,6,Color.new(c.red,c.green,c.blue,70));b.fill_rect(4,4,4,4,c);@@bitmaps[style]=b;b
  end
  def initialize(viewport,x,y,style)
    super(viewport);self.bitmap=Sprite_PMDSkillTrailV030.bitmap_for(style);self.ox=6;self.oy=6;self.x=x.to_i;self.y=y.to_i;self.z=9190;self.blend_type=1;@life=8;@finished=false
  end
  def update;super;return if @finished;@life-=1;self.opacity=[@life*28,210].min;self.zoom_x+=0.03;self.zoom_y+=0.03;if @life<=0;@finished=true;self.visible=false;end;end
  def dispose;super;end
end

#==============================================================================
# ■ Sprite_PMDSkillDemoProjectileV030 - visual verification only.
#==============================================================================
class Sprite_PMDSkillDemoProjectileV030 < Sprite
  attr_reader :finished
  def initialize(viewport,scene,x1,y1,x2,y2,style)
    super(viewport);@scene=scene;@x=x1.to_f;@y=y1.to_f;@x2=x2.to_f;@y2=y2.to_f;@style=style;@profile=PMD_AC.skill_visual_projectile_profile_v030(style);@finished=false;@frame=0;@wait=0;@trail_wait=0
    self.bitmap=Bitmap.new(48,48);self.ox=24;self.oy=24;self.z=9250;setup_heading;redraw
  end
  def setup_heading;dx=@x2-@x;dy=@y2-@y;l=Math.sqrt(dx*dx+dy*dy);@hx=l>0.001 ? dx/l : 1.0;@hy=l>0.001 ? dy/l : 0.0;self.angle=-Math.atan2(@hy,@hx)*180.0/Math::PI;end
  def redraw
    return if @profile==nil
    sheet=PMD_AC.skill_visual_load_bitmap_v030(@profile[:sheet]);self.bitmap.clear
    f=@frame % [@profile[:frames].to_i,1].max;src=Rect.new(0,f*@profile[:frame_h].to_i,@profile[:frame_w].to_i,@profile[:frame_h].to_i)
    dw=(@profile[:display_w]||34).to_i;dh=(@profile[:display_h]||34).to_i;dx=(48-dw)/2;dy=(48-dh)/2
    self.bitmap.stretch_blt(Rect.new(dx,dy,dw,dh),sheet,src)
    self.blend_type=(@profile[:blend]||0).to_i
  end
  def update
    super;return if @finished
    @x+=@hx*9.0;@y+=@hy*9.0;self.x=@x.to_i;self.y=@y.to_i
    @wait-=1;if @wait<=0;@frame+=1;@wait=[(@profile[:frame_wait]||3).to_i,1].max;redraw;end
    @trail_wait-=1;if @profile!=nil && @profile[:trail] && @trail_wait<=0;@scene.add_skill_trail_v030(@x,@y,@style);@trail_wait=3;end
    if PMD_AC.distance(@x,@y,@x2,@y2)<=11.0;@scene.add_vfx_impact_xy(@x2,@y2,@style);@finished=true;self.visible=false;end
  end
  def dispose;self.bitmap.dispose if self.bitmap!=nil && !self.bitmap.disposed?;super;end
end

#==============================================================================
# ■ Sprite_PMDProjectile visual skin patch
#==============================================================================
class Sprite_PMDProjectile
  attr_reader :pmd_skill_visual_profile_v030
  alias pmd_ac_v030_initialize initialize unless method_defined?(:pmd_ac_v030_initialize)
  alias pmd_ac_v030_update update unless method_defined?(:pmd_ac_v030_update)
  def initialize(*args)
    pmd_ac_v030_initialize(*args)
    @pmd_skill_visual_profile_v030=PMD_AC.skill_visual_projectile_profile_v030(@style)
    @pmd_v030_frame=0;@pmd_v030_wait=0;@pmd_v030_trail_wait=0
    setup_skill_visual_v030 if @pmd_skill_visual_profile_v030!=nil
  end
  def setup_skill_visual_v030
    self.bitmap.dispose if self.bitmap!=nil && !self.bitmap.disposed?
    self.bitmap=Bitmap.new(48,48);self.ox=24;self.oy=24;redraw_skill_visual_v030
  end
  def redraw_skill_visual_v030
    p=@pmd_skill_visual_profile_v030;return if p==nil
    sheet=PMD_AC.skill_visual_load_bitmap_v030(p[:sheet]);self.bitmap.clear
    f=@pmd_v030_frame % [p[:frames].to_i,1].max;src=Rect.new(0,f*p[:frame_h].to_i,p[:frame_w].to_i,p[:frame_h].to_i)
    dw=(p[:display_w]||34).to_i;dh=(p[:display_h]||34).to_i
    self.bitmap.stretch_blt(Rect.new((48-dw)/2,(48-dh)/2,dw,dh),sheet,src);self.blend_type=(p[:blend]||0).to_i
  end
  def update
    pmd_ac_v030_update
    return if @finished || @pmd_skill_visual_profile_v030==nil || !self.visible
    @pmd_v030_wait-=1
    if @pmd_v030_wait<=0;@pmd_v030_frame+=1;@pmd_v030_wait=[(@pmd_skill_visual_profile_v030[:frame_wait]||3).to_i,1].max;redraw_skill_visual_v030;end
    @pmd_v030_trail_wait-=1
    if @pmd_skill_visual_profile_v030[:trail] && @pmd_v030_trail_wait<=0 && @scene!=nil && @scene.respond_to?(:add_skill_trail_v030)
      @scene.add_skill_trail_v030(@x_f,@y_f,@style);@pmd_v030_trail_wait=3
    end
  end
end

class Scene_PMD_AutoChess
  alias pmd_ac_v030_start start unless method_defined?(:pmd_ac_v030_start)
  alias pmd_ac_v030_projectile_style projectile_style unless method_defined?(:pmd_ac_v030_projectile_style)
  alias pmd_ac_v030_launch_projectile launch_projectile unless method_defined?(:pmd_ac_v030_launch_projectile)
  alias pmd_ac_v030_add_beam_effect add_beam_effect unless method_defined?(:pmd_ac_v030_add_beam_effect)
  alias pmd_ac_v030_add_vfx_impact_xy add_vfx_impact_xy unless method_defined?(:pmd_ac_v030_add_vfx_impact_xy)
  alias pmd_ac_v030_apply_skill_effects apply_skill_effects unless method_defined?(:pmd_ac_v030_apply_skill_effects)
  alias pmd_ac_v030_prepare_verification_battle prepare_verification_battle unless method_defined?(:pmd_ac_v030_prepare_verification_battle)
  alias pmd_ac_v030_update_verification_script update_verification_script unless method_defined?(:pmd_ac_v030_update_verification_script)
  alias pmd_ac_v030_complete_verification_mode complete_verification_mode unless method_defined?(:pmd_ac_v030_complete_verification_mode)
  alias pmd_ac_v030_log_event log_event unless method_defined?(:pmd_ac_v030_log_event)

  def start
    pmd_ac_v030_start
    begin
      if FileTest.exist?(PMD_AC::BATTLE_LOG_FILE)
        text=File.open(PMD_AC::BATTLE_LOG_FILE,"rb"){|f|f.read}
        text.sub!(/PMD AutoChess Proto v0\.[0-9.]+ Battle Verification Log/,"PMD AutoChess Proto v0.30 Battle Verification Log")
        File.open(PMD_AC::BATTLE_LOG_FILE,"wb"){|f|f.write(text)}
      end
    rescue
    end
    m=PMD_AC.skill_visual_manifest_v030
    log_event(:skill_visual,"LOADED beams="+m[:beam_profile_count].to_s+" projectiles="+m[:projectile_profile_count].to_s+" impacts="+m[:impact_profile_count].to_s+" mapped_moves="+m[:mapped_move_visual_count].to_s+" assets="+m[:asset_count].to_s+" checksum32="+m[:runtime_checksum32].to_s)
  end

  def projectile_style(user,kind,effect_type)
    if effect_type!=nil
      data=PMD_AC.skill_data(effect_type)
      if data!=nil && data[:canonical_move_key]!=nil
        v=PMD_AC.skill_visual_move_profile_v030(data[:canonical_move_key])
        return v[:style] if v!=nil && v[:style]!=nil
      end
    end
    pmd_ac_v030_projectile_style(user,kind,effect_type)
  end

  def add_skill_trail_v030(x,y,style)
    @effect_sprites.push(Sprite_PMDSkillTrailV030.new(@viewport,x,y,style))
  end

  def add_skill_visual_beam_v030(source,target,style,life=24,width=nil)
    p=PMD_AC.skill_visual_beam_profile_v030(style);return false if p==nil
    @effect_sprites.push(PMD_AC_SkillBeamVisualV030.new(@viewport,source,target,style,life,width));true
  end

  def add_beam_effect(source,target,style=:light,life=nil,width=nil)
    if PMD_AC.skill_visual_beam_profile_v030(style)!=nil
      life=PMD_AC::BEAM_DEFAULT_LIFE if life==nil
      src=effect_anchor_xy(source,true);dst=effect_anchor_xy(target,false)
      sn=source.respond_to?(:log_name) ? source.log_name : "POINT";tn=target.respond_to?(:log_name) ? target.log_name : "POINT"
      log_event(:vfx_anchor,sn+" BEAM style="+style.to_s+" src=("+src[0].round.to_s+","+src[1].round.to_s+") dst=("+dst[0].round.to_s+","+dst[1].round.to_s+") target="+tn)
      add_vfx_muzzle(source,style) unless source.is_a?(Array)
      add_vfx_impact(target,style,[life.to_i-PMD_AC::PMD_VFX_BEAM_IMPACT_DELAY,0].max) unless target.is_a?(Array)
      add_skill_visual_beam_v030(source,target,style,life,width);return
    end
    pmd_ac_v030_add_beam_effect(source,target,style,life,width)
  end

  def add_vfx_impact_xy(x,y,style,delay=0)
    if PMD_AC.skill_visual_impact_profile_v030(style)!=nil
      @effect_sprites.push(Sprite_PMDSkillImpactV030.new(@viewport,x,y,style,delay));return
    end
    pmd_ac_v030_add_vfx_impact_xy(x,y,style,delay)
  end

  def launch_projectile(user,target,kind,power,effect_type,tracking_override=nil,attack_modifier=nil,allow_substitute=true)
    data=effect_type==nil ? nil : PMD_AC.skill_data(effect_type)
    visual=nil
    if data!=nil && data[:canonical_move_key]!=nil;visual=PMD_AC.skill_visual_move_profile_v030(data[:canonical_move_key]);end
    if visual!=nil && visual[:visual_kind]==:beam && target!=nil
      d=PMD_AC.distance(user.visual_center_x,user.visual_center_y,target.visual_center_x,target.visual_center_y)
      life=(d/[PMD_AC::PROJECTILE_SPEED,1.0].max).ceil+5;life=[[life,12].max,30].min
      add_skill_visual_beam_v030(user,target,visual[:style],life,nil)
      log_event(:skill_visual,user.log_name+" BEAM move="+data[:canonical_move_key].to_s+" style="+visual[:style].to_s+" logical_projectile=hidden")
    end
    before=@projectile_sprites.size
    pmd_ac_v030_launch_projectile(user,target,kind,power,effect_type,tracking_override,attack_modifier,allow_substitute)
    if visual!=nil && visual[:visual_kind]==:beam && @projectile_sprites.size>before
      p=@projectile_sprites[-1];p.visible=false;p.instance_variable_set(:@pmd_skill_visual_hidden_v030,true)
    end
  end

  def apply_skill_effects(user,target,data,multiplier=1.0)
    if data!=nil && target!=nil && data[:canonical_move_key]!=nil
      visual=PMD_AC.skill_visual_move_profile_v030(data[:canonical_move_key])
      if visual!=nil && visual[:visual_kind]==:target_hit
        add_vfx_impact(target,visual[:style]);log_event(:skill_visual,user.log_name+" TARGET_HIT move="+data[:canonical_move_key].to_s+" style="+visual[:style].to_s+" target="+target.log_name)
      end
    end
    pmd_ac_v030_apply_skill_effects(user,target,data,multiplier)
  end

  def prepare_verification_battle
    pmd_ac_v030_prepare_verification_battle
    if verification_mode==:skill_visual
      @skill_visual_failed_v030=false
      for u in @units;u.verification_combat_sandbox(true);end
    end
  end

  def log_event(category,message)
    if category.to_s=="verify" && verification_mode==:skill_visual && message.to_s.index("SKILL_VISUAL_")==0 && message.to_s.include?(" pass=0")
      @skill_visual_failed_v030=true
    end
    pmd_ac_v030_log_event(category,message)
  end

  def skill_visual_verify_manifest_v030
    return if @verification_done[:skill_visual_manifest]
    e=PMD_AC.validate_skill_visual_v030;m=PMD_AC.skill_visual_manifest_v030;pass=e.empty?
    log_event(:verify,"SKILL_VISUAL_MANIFEST pass="+(pass ? "1":"0")+" beams="+m[:beam_profile_count].to_s+" projectiles="+m[:projectile_profile_count].to_s+" impacts="+m[:impact_profile_count].to_s+" moves="+m[:mapped_move_visual_count].to_s+" assets="+m[:asset_count].to_s+" checksum="+PMD_AC.skill_visual_checksum32_v030.to_s+" errors=["+e.join(",")+"]")
    @verification_done[:skill_visual_manifest]=true
  end
  def skill_visual_demo_beam_v030(style,tag,y)
    return if @verification_done[tag]
    p=PMD_AC.skill_visual_beam_profile_v030(style);pass=p!=nil
    add_skill_visual_beam_v030([110,y],[430,y],style,38,nil) if pass
    extra=style==:water ? " body="+p[:body].to_s+" head="+p[:head].to_s : " body="+(p==nil ? "nil" : p[:body].to_s)+" motion="+(p==nil ? "nil" : p[:motion].to_s)
    log_event(:verify,tag.to_s.upcase+" pass="+(pass ? "1":"0")+extra);@verification_done[tag]=true
  end
  def skill_visual_demo_projectiles_v030
    return if @verification_done[:skill_visual_projectiles]
    styles=[:electric,:fire,:water,:seed];ok=true
    styles.each_with_index do |s,i|
      p=PMD_AC.skill_visual_projectile_profile_v030(s);ok=false if p==nil
      @effect_sprites.push(Sprite_PMDSkillDemoProjectileV030.new(@viewport,self,100,118+i*56,430,118+i*56,s)) if p!=nil
    end
    log_event(:verify,"SKILL_VISUAL_PROJECTILES pass="+(ok ? "1":"0")+" styles=electric,fire,water,seed animated=1 trail=1");@verification_done[:skill_visual_projectiles]=true
  end
  def skill_visual_demo_impacts_v030
    return if @verification_done[:skill_visual_impacts]
    styles=[:electric,:fire,:water,:ice,:sound];ok=true
    styles.each_with_index do |s,i|;p=PMD_AC.skill_visual_impact_profile_v030(s);ok=false if p==nil;add_vfx_impact_xy(110+i*82,210,s,0) if p!=nil;end
    log_event(:verify,"SKILL_VISUAL_IMPACTS pass="+(ok ? "1":"0")+" target_centered=1 styles=electric,fire,water,ice,sound");@verification_done[:skill_visual_impacts]=true
  end
  def skill_visual_verify_integration_v030
    return if @verification_done[:skill_visual_integration]
    a=@units.find{|u|u.team==:ally};b=@units.find{|u|u.team==:enemy};p=nil
    begin;p=Sprite_PMDProjectile.new(@viewport,self,930001,a,b,:visual_demo,1,:mv_ember,:perfect,nil);skin=p.pmd_skill_visual_profile_v030!=nil;p.dispose unless p.disposed?;rescue;skin=false;end
    fm=PMD_AC.skill_data(:mv_flamethrower);hm=PMD_AC.skill_data(:mv_hydro_pump);im=PMD_AC.skill_data(:mv_ice_beam);sm=PMD_AC.skill_data(:mv_screech)
    beam=fm[:visual_kind]==:beam && hm[:visual_kind]==:beam && im[:visual_kind]==:beam;target=sm[:visual_kind]==:target_hit
    pass=skin&&beam&&target
    log_event(:verify,"SKILL_VISUAL_INTEGRATION pass="+(pass ? "1":"0")+" projectile_skin="+(skin ? "1":"0")+" beam_moves="+(beam ? "1":"0")+" target_hit="+(target ? "1":"0"));@verification_done[:skill_visual_integration]=true
  end

  def update_verification_script
    pmd_ac_v030_update_verification_script
    return unless verification_mode==:skill_visual
    f=@verification_frame
    skill_visual_verify_manifest_v030 if f==4
    skill_visual_demo_beam_v030(:electric,:skill_visual_beam_electric,130) if f==35
    skill_visual_demo_beam_v030(:fire,:skill_visual_beam_fire,175) if f==85
    skill_visual_demo_beam_v030(:water,:skill_visual_beam_water,220) if f==135
    skill_visual_demo_beam_v030(:ice,:skill_visual_beam_ice,265) if f==185
    skill_visual_demo_projectiles_v030 if f==235
    skill_visual_demo_impacts_v030 if f==305
    skill_visual_verify_integration_v030 if f==345
    complete_verification_mode if f==PMD_AC::VERIFICATION_SKILL_VISUAL_END_FRAME
  end

  def complete_verification_mode
    if verification_mode==:skill_visual
      if @skill_visual_failed_v030
        for u in @units;u.verification_finish;end
        @verification_done[:complete]=true
        log_event(:verify,"FAILED mode=SKILL_VISUAL auto_skill=on original_skills=restored");return
      end
    end
    pmd_ac_v030_complete_verification_mode
  end
end
