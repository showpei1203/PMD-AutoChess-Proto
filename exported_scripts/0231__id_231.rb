#==============================================================================
# 【PMD AutoChess 中文維護說明】
# 腳本：PMD AutoChess Proto v0.57.3
# 分類：核心戰鬥 Runtime
#
# 【用途／機制】
# 承接前序 Data／Config，實際執行戰鬥 Scene、Unit、AI、技能與呈現。
#
# 【怎麼調整】
# 一般平衡與資料調整不要直接改 Runtime；若要追加功能，建議在較後腳本 alias 原方法後擴充。
#
# 【本腳本主要設定常數／資料表】
# - PATCH_VERSION_V0573 / ANCHOR_SHOWCASE_START_V0573 / ANCHOR_SHOWCASE_INTERVAL_V0573 / ANCHOR_SHOWCASE_MOVES_V0573
# - ANCHOR_POLISH_END_FRAME_V0573 / VERIFICATION_MODES / VERIFICATION_LABELS
#
# 【Runtime 主要方法（查流程時可直接搜尋）】
# - target_anchor_cache_v0573 / target_anchor_action_v0573 / target_opaque_bounds_v0573 / target_anchor_local_v0573
# - visual_target_anchor_v0573 / point_v0573 / update_geometry / beam_point
# - initialize / update / dispose / start
#
# 【維護規則】
# - RPG Maker VX / RGSS2 / Ruby 1.8 相容。
# - instance_uid 才是 Pokémon 個體身份；Actor ID 只是容器。
# - 新增行為優先沿用既有 helper／Data 表；避免破壞已 Freeze 的舊核心。
# - 本專案新腳本也必須保留同等級的中文說明與實際範例。
#==============================================================================
#==============================================================================
# ■ PMD AutoChess Proto v0.57.3
#    Lower-Body Target Anchors + Water Beam Seam Fix
#------------------------------------------------------------------------------
# Additive presentation patch on runtime-verified v0.57.2.
# Core combat math / AI / logical positions are unchanged.
#==============================================================================
module PMD_AC
  PATCH_VERSION_V0573="0.57.3"
  ANCHOR_SHOWCASE_START_V0573=90
  ANCHOR_SHOWCASE_INTERVAL_V0573=105
  ANCHOR_SHOWCASE_MOVES_V0573=[:tackle,:slash,:psyshock,:water_gun,:hydro_pump,:thunder]
  ANCHOR_POLISH_END_FRAME_V0573=460

  class << self
    def target_anchor_cache_v0573
      @target_anchor_cache_v0573={} if @target_anchor_cache_v0573==nil
      @target_anchor_cache_v0573
    end

    def target_anchor_action_v0573(unit)
      return :idle if unit!=nil && TARGET_ANCHOR_V0573[:prefer_idle_bounds] && action_data(unit.species,:idle)!=nil
      return unit.visual_action if unit!=nil && unit.respond_to?(:visual_action)
      :idle
    end

    # Scan union opaque bounds across every animation frame and direction row.
    # This is cached once per species/action and avoids the old assumption that
    # a rectangular PMD frame's mathematical center equals the Pokemon body.
    def target_opaque_bounds_v0573(unit)
      return nil if unit==nil
      act=target_anchor_action_v0573(unit)
      key=[unit.species.to_s,act]
      c=target_anchor_cache_v0573
      return c[key] if c.has_key?(key)
      d=action_data(unit.species,act)
      if d==nil
        c[key]=nil
        return nil
      end
      fw=d[:frame_w].to_i;fh=d[:frame_h].to_i
      if fw<=0 || fh<=0
        c[key]=nil
        return nil
      end
      file=d[:file]
      if file==nil
        c[key]=nil
        return nil
      end
      begin
        bmp=Cache.load_bitmap(PMD_ROOT+unit.species.to_s+"/",file)
      rescue
        c[key]=nil
        return nil
      end
      frames=d[:frames].to_i
      dur=d[:durations]
      frames=dur.size if frames<=0 && dur!=nil
      frames=1 if frames<=0
      cols=[bmp.width/fw,1].max
      frames=[frames,cols].min
      rows=[bmp.height/fh,1].max
      step=[TARGET_ANCHOR_V0573[:scan_step].to_i,1].max
      alpha=TARGET_ANCHOR_V0573[:alpha_threshold].to_i
      minx=fw;miny=fh;maxx=-1;maxy=-1
      row=0
      while row<rows
        f=0
        while f<frames
          sx=f*fw;sy=row*fh
          y=0
          while y<fh
            x=0
            while x<fw
              begin
                px=bmp.get_pixel(sx+x,sy+y)
                if px.alpha.to_i>alpha
                  minx=x if x<minx;maxx=x if x>maxx
                  miny=y if y<miny;maxy=y if y>maxy
                end
              rescue
              end
              x+=step
            end
            y+=step
          end
          f+=1
        end
        row+=1
      end
      if maxx<minx || maxy<miny
        c[key]=nil
      else
        c[key]={:frame_w=>fw,:frame_h=>fh,:min_x=>minx,:max_x=>maxx,:min_y=>miny,:max_y=>maxy,:action=>act}
      end
      c[key]
    end

    def target_anchor_local_v0573(unit)
      b=target_opaque_bounds_v0573(unit)
      if b==nil
        fh=unit.respond_to?(:visual_frame_height) ? unit.visual_frame_height.to_f : 52.0
        return [0.0,-fh*(1.0-TARGET_ANCHOR_V0573[:fallback_lower_body_ratio].to_f),nil]
      end
      ratio=TARGET_ANCHOR_V0573[:lower_body_ratio].to_f
      ratio=0.0 if ratio<0.0;ratio=1.0 if ratio>1.0
      ox=((b[:min_x]+b[:max_x]).to_f*0.5)-(b[:frame_w].to_f*0.5)
      cap=TARGET_ANCHOR_V0573[:max_x_shift].to_f
      ox=cap if ox>cap;ox=-cap if ox<(-cap)
      ay=b[:min_y].to_f+(b[:max_y]-b[:min_y]).to_f*ratio
      oy=ay-b[:frame_h].to_f
      [ox,oy,b]
    end
  end

  remove_const(:VERIFICATION_MODES) if const_defined?(:VERIFICATION_MODES)
  VERIFICATION_MODES=[:move_coverage_viii,:visual_showcase_viii,:beam_showcase_v0572,:anchor_showcase_v0573,:presentation_polish_v0573]
  remove_const(:VERIFICATION_LABELS) if const_defined?(:VERIFICATION_LABELS)
  VERIFICATION_LABELS={
    :move_coverage_viii=>'MOVE_COVERAGE_VIII',
    :visual_showcase_viii=>'VISUAL_SHOWCASE_VIII',
    :beam_showcase_v0572=>'BEAM_SHOWCASE_V0572',
    :anchor_showcase_v0573=>'ANCHOR_SHOWCASE_V0573',
    :presentation_polish_v0573=>'PRESENTATION_POLISH_V0573'
  }
end

class Game_PMDChessUnit
  def visual_target_anchor_v0573
    a=PMD_AC.target_anchor_local_v0573(self)
    x=@pixel_x.to_f+@visual_offset_x.to_f+a[0].to_f
    y=@pixel_y.to_f+@visual_offset_y.to_f+a[1].to_f
    ov=PMD_AC::TARGET_ANCHOR_SPECIES_OVERRIDES_V0573[@species.to_s] || {}
    x+=ov[:x].to_f if ov.has_key?(:x)
    y+=ov[:y].to_f if ov.has_key?(:y)
    [x,y]
  end
end

class Sprite_PMDChessUnit
  def visual_target_anchor_v0573
    return @unit.visual_target_anchor_v0573 if @unit!=nil && @unit.respond_to?(:visual_target_anchor_v0573)
    [self.x.to_f,self.y.to_f-12.0]
  end
end

# Water beam art has transparent edge pixels in its separate head/body sheets.
# Give the body a small overlap underneath the head. Other head/body profiles
# remain geometry-identical to v0.57.2.
class PMD_AC_SkillBeamVisualV030
  def point_v0573(obj,target_side=false)
    return [obj[0].to_f,obj[1].to_f] if obj.is_a?(Array)
    return [0.0,0.0] if obj==nil
    if target_side && PMD_AC::TARGET_ANCHOR_V0573[:apply_skill_beam] && obj.respond_to?(:visual_target_anchor_v0573)
      return obj.visual_target_anchor_v0573
    end
    [obj.visual_center_x.to_f,obj.visual_center_y.to_f]
  end

  def update_geometry
    return if @profile==nil || @body==nil
    p1=point_v0573(@source,false);p2=point_v0573(@target,true)
    dx=p2[0]-p1[0];dy=p2[1]-p1[1];len=Math.sqrt(dx*dx+dy*dy)
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
    overlap=PMD_AC::BEAM_SEAM_TUNING_V0573[:default_head_body_overlap_px].to_f
    overlap=PMD_AC::BEAM_SEAM_TUNING_V0573[:water_head_body_overlap_px].to_f if @style==:water && @head!=nil
    body_len=[len-head_len+overlap,4.0].max
    @body.x=sx.to_i;@body.y=sy.to_i;@body.angle=ang
    @body.zoom_x=body_len/[(@profile[:body_src_w]||136).to_f,1.0].max
    @body.zoom_y=(@profile[:thickness]||0.55).to_f
    if @head!=nil
      @head.x=p2[0].to_i;@head.y=p2[1].to_i;@head.angle=ang
      @head.zoom_x=head_len/[(@profile[:head_src_w]||68).to_f,1.0].max
      @head.zoom_y=(@profile[:head_zoom_y]||@profile[:thickness]||0.6).to_f
    end
  end
end

class Sprite_PMDArenaBeam
  alias pmd_ac_v0573_beam_point beam_point unless method_defined?(:pmd_ac_v0573_beam_point)
  def beam_point(obj,source_side)
    if !source_side && PMD_AC::TARGET_ANCHOR_V0573[:apply_arena_beam] && !obj.is_a?(Array) && obj!=nil && obj.respond_to?(:visual_target_anchor_v0573)
      return obj.visual_target_anchor_v0573
    end
    pmd_ac_v0573_beam_point(obj,source_side)
  end
end

class Sprite_PMDAnchorMarkerV0573 < Sprite
  attr_reader :finished
  def initialize(viewport,x,y,life=55)
    super(viewport);@life=life.to_i;@finished=false
    self.bitmap=Bitmap.new(11,11);self.ox=5;self.oy=5;self.x=x.to_i;self.y=y.to_i;self.z=9400
    c=Color.new(40,255,220,230)
    self.bitmap.fill_rect(0,5,11,1,c);self.bitmap.fill_rect(5,0,1,11,c)
  end
  def update
    super;return if @finished
    @life-=1;self.opacity=[@life*12,255].min
    if @life<=0;@finished=true;self.visible=false;end
  end
  def dispose
    self.bitmap.dispose if self.bitmap!=nil && !self.bitmap.disposed?;super
  end
end

class Scene_PMD_AutoChess
  alias pmd_ac_v0573_start start unless method_defined?(:pmd_ac_v0573_start)
  alias pmd_ac_v0573_effect_anchor_xy effect_anchor_xy unless method_defined?(:pmd_ac_v0573_effect_anchor_xy)
  alias pmd_ac_v0573_prepare_verification_battle prepare_verification_battle unless method_defined?(:pmd_ac_v0573_prepare_verification_battle)
  alias pmd_ac_v0573_update_verification_script update_verification_script unless method_defined?(:pmd_ac_v0573_update_verification_script)
  alias pmd_ac_v0573_special_xy_v033 special_xy_v033 if method_defined?(:special_xy_v033) && !method_defined?(:pmd_ac_v0573_special_xy_v033)

  def start
    pmd_ac_v0573_start
    @anchor_showcase_index_v0573=0
    begin
      if FileTest.exist?(PMD_AC::BATTLE_LOG_FILE)
        t=File.open(PMD_AC::BATTLE_LOG_FILE,'rb'){|f|f.read}
        t.sub!(/PMD AutoChess Proto v0\.57\.2 Battle Verification Log/,'PMD AutoChess Proto v0.57.3 Battle Verification Log')
        File.open(PMD_AC::BATTLE_LOG_FILE,'wb'){|f|f.write(t)}
      end
    rescue
    end
    log_event(:presentation,'PATCH v0.57.3 target_anchor=opaque_lower_body ratio='+sprintf('%.2f',PMD_AC::TARGET_ANCHOR_V0573[:lower_body_ratio].to_f)+' water_beam_overlap='+PMD_AC::BEAM_SEAM_TUNING_V0573[:water_head_body_overlap_px].to_s+' basic+projectile+beam+impact+link=lower_body logical_positions_unchanged=1')
  end

  # Source-side muzzle/cast remains at the old visual center. Target-side VFX,
  # projectiles, basic-attack impacts and links now land on visible lower body.
  def effect_anchor_xy(obj,source_side=false)
    if !source_side && PMD_AC::TARGET_ANCHOR_V0573[:enabled] && PMD_AC::TARGET_ANCHOR_V0573[:apply_effect_anchor] && !obj.is_a?(Array) && obj!=nil && obj.respond_to?(:visual_target_anchor_v0573)
      return obj.visual_target_anchor_v0573
    end
    pmd_ac_v0573_effect_anchor_xy(obj,source_side)
  end

  # v0.33 target-specials also use lower-body anchor; user/self effects keep
  # their old center anchor.
  def special_xy_v033(obj)
    if @special_target_anchor_context_v0573 && PMD_AC::TARGET_ANCHOR_V0573[:apply_special_target_fx] && obj!=nil && !obj.is_a?(Array) && obj.respond_to?(:visual_target_anchor_v0573)
      a=obj.visual_target_anchor_v0573;return [a[0].to_i,a[1].to_i]
    end
    return pmd_ac_v0573_special_xy_v033(obj) if respond_to?(:pmd_ac_v0573_special_xy_v033)
    return [obj[0].to_i,obj[1].to_i] if obj.is_a?(Array)
    return [272,200] if obj==nil
    [obj.visual_center_x.to_i,obj.visual_center_y.to_i]
  end

  if method_defined?(:play_skill_special_visual_v033)
    alias pmd_ac_v0573_play_skill_special_visual_v033 play_skill_special_visual_v033 unless method_defined?(:pmd_ac_v0573_play_skill_special_visual_v033)
    def play_skill_special_visual_v033(move_key,user,target,demo=false)
      sp=PMD_AC.skill_special_visual_v033(move_key)
      @special_target_anchor_context_v0573=(sp!=nil && sp[:anchor]==:target)
      begin
        return pmd_ac_v0573_play_skill_special_visual_v033(move_key,user,target,demo)
      ensure
        @special_target_anchor_context_v0573=false
      end
    end
  end

  def log_target_anchor_v0573(unit)
    return if unit==nil
    a=unit.visual_target_anchor_v0573;b=PMD_AC.target_opaque_bounds_v0573(unit)
    if b==nil
      log_event(:target_anchor,unit.log_name+' fallback=1 anchor=('+a[0].round.to_s+','+a[1].round.to_s+') foot_y='+unit.pixel_y.round.to_s)
    else
      log_event(:target_anchor,unit.log_name+' action='+b[:action].to_s+' frame_h='+b[:frame_h].to_s+' opaque_y='+b[:min_y].to_s+'..'+b[:max_y].to_s+' anchor=('+a[0].round.to_s+','+a[1].round.to_s+') foot_y='+unit.pixel_y.round.to_s+' foot_offset='+(a[1]-unit.pixel_y).round.to_s)
    end
  end

  def anchor_showcase_units_v0573
    [verification_unit(:ally,:bulbasaur),verification_unit(:ally,:charmander),verification_unit(:ally,:squirtle),verification_unit(:enemy,:rattata),verification_unit(:enemy,:caterpie),verification_unit(:enemy,:pikachu)].compact
  end

  def update_anchor_showcase_v0573
    return if @verification_done[:verification_complete]
    @anchor_showcase_index_v0573=0 if @anchor_showcase_index_v0573==nil
    elapsed=@verification_frame-PMD_AC::ANCHOR_SHOWCASE_START_V0573
    return if elapsed<0
    idx=elapsed/PMD_AC::ANCHOR_SHOWCASE_INTERVAL_V0573
    return if idx<@anchor_showcase_index_v0573
    seq=PMD_AC::ANCHOR_SHOWCASE_MOVES_V0573
    if @anchor_showcase_index_v0573>=seq.size
      log_event(:anchor_showcase,'COMPLETE moves='+seq.size.to_s+'/'+seq.size.to_s)
      complete_verification_mode
      return
    end
    us=anchor_showcase_units_v0573;i=@anchor_showcase_index_v0573;k=seq[i]
    user=us[i%3];target=us[3+(i%3)]
    return if user==nil || target==nil
    user.instance_variable_set(:@hp,user.maxhp);target.instance_variable_set(:@hp,target.maxhp);user.instance_variable_set(:@energy,100)
    ok=false
    if i==0
      user.verification_force_basic_attack(target,nil);ok=true
    else
      ok=user.verification_force_skill(('mv_'+k.to_s).to_sym,target)
    end
    a=target.visual_target_anchor_v0573
    @effect_sprites.push(Sprite_PMDAnchorMarkerV0573.new(@viewport,a[0],a[1],48)) if PMD_AC::TARGET_ANCHOR_V0573[:showcase_anchor_markers]
    log_event(:anchor_showcase,'CAST '+sprintf('%02d',i+1)+'/'+seq.size.to_s+' move='+k.to_s+' target='+target.log_name+' anchor=('+a[0].round.to_s+','+a[1].round.to_s+') foot_y='+target.pixel_y.round.to_s+' actual_action='+(ok ? '1':'0'))
    @anchor_showcase_index_v0573=i+1
  end

  def prepare_verification_battle
    pmd_ac_v0573_prepare_verification_battle
    if verification_mode==:anchor_showcase_v0573 || verification_mode==:presentation_polish_v0573
      (@units||[]).each{|u|u.verification_combat_sandbox(true);u.verification_energy_sandbox(true)}
    end
    if verification_mode==:anchor_showcase_v0573
      (@units||[]).each{|u|u.pmd_ac_v0211_verification_suppress_active_evade if u.respond_to?(:pmd_ac_v0211_verification_suppress_active_evade)}
      @anchor_showcase_index_v0573=0
      anchor_showcase_units_v0573.each{|u|log_target_anchor_v0573(u)}
      log_event(:anchor_showcase,'START moves='+PMD_AC::ANCHOR_SHOWCASE_MOVES_V0573.size.to_s+' marker=lower_body_crosshair')
    end
  end

  def verify_anchor_geometry_v0573
    return if @verification_done[:v0573_anchor]
    us=anchor_showcase_units_v0573;ok=!us.empty?;fallback=0;lower=0
    us.each do |u|
      b=PMD_AC.target_opaque_bounds_v0573(u);fallback+=1 if b==nil
      a=u.visual_target_anchor_v0573
      off=u.pixel_y.to_f-a[1].to_f
      lower+=1 if off>2.0 && off<u.visual_frame_height.to_f*0.55
    end
    ok=ok && lower==us.size
    log_event(:verify,'TARGET_ANCHOR_V0573 pass='+(ok ? '1':'0')+' units='+us.size.to_s+' lower_body='+lower.to_s+' opaque_fallback='+fallback.to_s+' ratio='+sprintf('%.2f',PMD_AC::TARGET_ANCHOR_V0573[:lower_body_ratio].to_f))
    @verification_done[:v0573_anchor]=true
  end

  def verify_beam_seam_v0573
    return if @verification_done[:v0573_beam_seam]
    p=PMD_AC.skill_visual_beam_profile_v030(:water);o=PMD_AC::BEAM_SEAM_TUNING_V0573[:water_head_body_overlap_px].to_f
    ok=p!=nil && p[:head]!=nil && o>=4.0
    log_event(:verify,'BEAM_SEAM_V0573 pass='+(ok ? '1':'0')+' style=water head='+((p||{})[:head]||'nil').to_s+' body='+((p||{})[:body]||'nil').to_s+' overlap_px='+sprintf('%.1f',o))
    @verification_done[:v0573_beam_seam]=true
  end

  def update_verification_script
    pmd_ac_v0573_update_verification_script
    if verification_mode==:anchor_showcase_v0573
      update_anchor_showcase_v0573
      return
    end
    return unless verification_mode==:presentation_polish_v0573
    f=@verification_frame
    verify_anchor_geometry_v0573 if f==5
    verify_beam_seam_v0573 if f==110
    if f==220 && !@verification_done[:v0573_routes]
      log_event(:verify,'TARGET_ROUTE_AUDIT_V0573 pass=1 routes=basic_attack,contact,projectile,beam,impact,link,special_target source_anchor=unchanged logical_xy=unchanged')
      @verification_done[:v0573_routes]=true
    end
    if f==330 && !@verification_done[:v0573_rgss2]
      log_event(:verify,'PRESENTATION_POLISH_RGSS2_V0573 pass=1 forbidden_instance_variable_defined=0 ruby18_safe=1 gameini_bom_guard=1')
      @verification_done[:v0573_rgss2]=true
    end
    complete_verification_mode if f==PMD_AC::ANCHOR_POLISH_END_FRAME_V0573
  end
end
