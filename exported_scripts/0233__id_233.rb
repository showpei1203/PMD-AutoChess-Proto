#==============================================================================
# 【PMD AutoChess 中文維護說明】
# 腳本：PMD AutoChess Proto v0.57.4
# 分類：核心戰鬥 Runtime
#
# 【用途／機制】
# 承接前序 Data／Config，實際執行戰鬥 Scene、Unit、AI、技能與呈現。
#
# 【怎麼調整】
# 一般平衡與資料調整不要直接改 Runtime；若要追加功能，建議在較後腳本 alias 原方法後擴充。
#
# 【本腳本主要設定常數／資料表】
# - PATCH_VERSION_V0574 / TARGET_FX_POLISH_END_FRAME_V0574
#
# 【Runtime 主要方法（查流程時可直接搜尋）】
# - visual_target_fx_anchor_v0574 / update_geometry / start / target_fx_anchor_v0574
# - add_vfx_impact / add_vfx_column / add_skill_effect / special_xy_v033
# - verify_target_fx_split_v0574 / verify_water_beam_body_only_v0574 / update_verification_script / hit
#
# 【維護規則】
# - RPG Maker VX / RGSS2 / Ruby 1.8 相容。
# - instance_uid 才是 Pokémon 個體身份；Actor ID 只是容器。
# - 新增行為優先沿用既有 helper／Data 表；避免破壞已 Freeze 的舊核心。
# - 本專案新腳本也必須保留同等級的中文說明與實際範例。
#==============================================================================
#==============================================================================
# ■ PMD AutoChess Proto v0.57.4
#    Water Beam Body-Only + Split Aim / Target-FX Anchors
#------------------------------------------------------------------------------
# Additive presentation patch on runtime-verified v0.57.3.
# Core combat math / AI / logical positions are unchanged.
#==============================================================================
module PMD_AC
  PATCH_VERSION_V0574="0.57.4"
  TARGET_FX_POLISH_END_FRAME_V0574=500
end

class Game_PMDChessUnit
  # v0.57.3 lower-body anchor remains the AIM / TRAVEL anchor.
  # Target-bound animation sprites use this legacy center anchor instead.
  def visual_target_fx_anchor_v0574
    [visual_center_x.to_f,visual_center_y.to_f]
  end
end

class Sprite_PMDChessUnit
  def visual_target_fx_anchor_v0574
    return @unit.visual_target_fx_anchor_v0574 if @unit!=nil && @unit.respond_to?(:visual_target_fx_anchor_v0574)
    [self.x.to_f,self.y.to_f]
  end
end

# Water Beam: Ranger_105 already contains a coherent stream + terminal shape.
# Default body-only mode stretches that one continuous strip across the whole
# source-target distance, avoiding the visibly thicker Ranger_109 head.
class PMD_AC_SkillBeamVisualV030
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
    nx=len>0.001 ? (-dy/len) : 0.0
    ny=len>0.001 ? (dx/len) : 0.0
    sx=p1[0]+nx*jitter;sy=p1[1]+ny*jitter

    water_body_only=(@style==:water && PMD_AC::WATER_BEAM_RENDER_V0574[:head_mode]==:none)
    if water_body_only
      @head.visible=false if @head!=nil
      body_len=[len,4.0].max
      @body.x=sx.to_i;@body.y=sy.to_i;@body.angle=ang
      @body.zoom_x=body_len/[(@profile[:body_src_w]||136).to_f,1.0].max
      @body.zoom_y=PMD_AC::WATER_BEAM_RENDER_V0574[:body_thickness].to_f
      return
    end

    @head.visible=true if @head!=nil
    head_len=@head==nil ? 0.0 : (@profile[:head_display_w]||36).to_f
    overlap=PMD_AC::BEAM_SEAM_TUNING_V0573[:default_head_body_overlap_px].to_f
    if @style==:water && @head!=nil
      overlap=PMD_AC::WATER_BEAM_RENDER_V0574[:composite_overlap_px].to_f
    end
    body_len=[len-head_len+overlap,4.0].max
    @body.x=sx.to_i;@body.y=sy.to_i;@body.angle=ang
    if @style==:water
      @body.zoom_y=PMD_AC::WATER_BEAM_RENDER_V0574[:composite_body_thickness].to_f
    else
      @body.zoom_y=(@profile[:thickness]||0.55).to_f
    end
    @body.zoom_x=body_len/[(@profile[:body_src_w]||136).to_f,1.0].max
    if @head!=nil
      @head.x=p2[0].to_i;@head.y=p2[1].to_i;@head.angle=ang
      @head.zoom_x=head_len/[(@profile[:head_src_w]||68).to_f,1.0].max
      if @style==:water
        @head.zoom_y=PMD_AC::WATER_BEAM_RENDER_V0574[:composite_head_zoom_y].to_f
      else
        @head.zoom_y=(@profile[:head_zoom_y]||@profile[:thickness]||0.6).to_f
      end
    end
  end
end

class Scene_PMD_AutoChess
  alias pmd_ac_v0574_start start unless method_defined?(:pmd_ac_v0574_start)
  alias pmd_ac_v0574_add_skill_effect add_skill_effect unless method_defined?(:pmd_ac_v0574_add_skill_effect)
  alias pmd_ac_v0574_add_vfx_impact add_vfx_impact unless method_defined?(:pmd_ac_v0574_add_vfx_impact)
  alias pmd_ac_v0574_add_vfx_column add_vfx_column unless method_defined?(:pmd_ac_v0574_add_vfx_column)
  alias pmd_ac_v0574_special_xy_v033 special_xy_v033 if method_defined?(:special_xy_v033) && !method_defined?(:pmd_ac_v0574_special_xy_v033)
  alias pmd_ac_v0574_update_verification_script update_verification_script unless method_defined?(:pmd_ac_v0574_update_verification_script)

  def start
    pmd_ac_v0574_start
    begin
      if FileTest.exist?(PMD_AC::BATTLE_LOG_FILE)
        t=File.open(PMD_AC::BATTLE_LOG_FILE,'rb'){|f|f.read}
        t.sub!(/PMD AutoChess Proto v0\.57\.3 Battle Verification Log/,'PMD AutoChess Proto v0.57.4 Battle Verification Log')
        File.open(PMD_AC::BATTLE_LOG_FILE,'wb'){|f|f.write(t)}
      end
    rescue
    end
    log_event(:presentation,'PATCH v0.57.4 water_beam_head=none body_only=Ranger_105 aim_anchor=lower_body target_fx_anchor=legacy_center logical_positions_unchanged=1')
  end

  def target_fx_anchor_v0574(obj)
    return [obj[0].to_f,obj[1].to_f] if obj.is_a?(Array)
    return [0.0,0.0] if obj==nil
    if obj.respond_to?(:visual_target_fx_anchor_v0574)
      return obj.visual_target_fx_anchor_v0574
    end
    [obj.visual_center_x.to_f,obj.visual_center_y.to_f]
  end

  # Impact animation sprites return to the v0.57.2 visual-center height.
  # effect_anchor_xy itself intentionally remains v0.57.3 lower-body so aim,
  # projectile travel, beam endpoints, links and contact placement stay low.
  def add_vfx_impact(obj,style,delay=0)
    return if obj==nil
    if PMD_AC::TARGET_FX_ANCHOR_V0574[:apply_impact]
      x,y=target_fx_anchor_v0574(obj)
      add_vfx_impact_xy(x,y,style,delay)
      return
    end
    pmd_ac_v0574_add_vfx_impact(obj,style,delay)
  end

  def add_vfx_column(obj,style,delay=0)
    if obj!=nil && PMD_AC::TARGET_FX_ANCHOR_V0574[:apply_column]
      profile=PMD_AC.vfx_profile(style)
      return if profile==nil || profile[:column]==nil
      x,y=target_fx_anchor_v0574(obj)
      add_vfx_burst_xy(x,y,profile[:column],delay)
      return
    end
    pmd_ac_v0574_add_vfx_column(obj,style,delay)
  end

  # Status / event animations on a battler also return to center. MISS text is
  # left on the lower aim anchor because it is not an on-body animation sprite.
  def add_skill_effect(target,type,delay=0)
    return if target==nil
    if !PMD_AC::TARGET_FX_ANCHOR_V0574[:apply_status_event]
      return pmd_ac_v0574_add_skill_effect(target,type,delay)
    end
    if type==:miss
      x,y=effect_anchor_xy(target,false)
      @effect_sprites.push(Sprite_PMDChessEffect.new(@viewport,x,y+24,:miss,delay))
      return
    end
    key=PMD_AC.vfx_event_key(type)
    @vfx_event_recent={} if @vfx_event_recent==nil
    target_id=target.respond_to?(:id) ? target.id : target.object_id
    cache_key=[target_id,key]
    now=Graphics.frame_count
    last=@vfx_event_recent[cache_key]
    return if last!=nil && now-last<PMD_AC::PMD_VFX_EVENT_DEDUP_FRAMES
    @vfx_event_recent[cache_key]=now
    x,y=target_fx_anchor_v0574(target)
    add_vfx_event_xy(x,y,type,delay)
  end

  # v0.33 target-anchored special animations return to the exact pre-v0.57.3
  # visual center. User/self specials were already centered, so this is safe for
  # both contexts and preserves their previous height.
  def special_xy_v033(obj)
    return [obj[0].to_i,obj[1].to_i] if obj.is_a?(Array)
    return [272,200] if obj==nil
    a=target_fx_anchor_v0574(obj)
    [a[0].to_i,a[1].to_i]
  end

  def verify_target_fx_split_v0574
    return if @verification_done[:v0574_fx_split]
    us=anchor_showcase_units_v0573
    ok=!us.empty?;center_ok=0;different=0
    us.each do |u|
      aim=u.visual_target_anchor_v0573
      fx=u.visual_target_fx_anchor_v0574
      center_ok+=1 if (fx[0]-u.visual_center_x.to_f).abs<0.01 && (fx[1]-u.visual_center_y.to_f).abs<0.01
      different+=1 if (fx[1]-aim[1]).abs>=1.0
    end
    ok=ok && center_ok==us.size
    log_event(:verify,'TARGET_FX_SPLIT_V0574 pass='+(ok ? '1':'0')+' units='+us.size.to_s+' aim=opaque_lower_body fx=legacy_visual_center center_ok='+center_ok.to_s+' geometry_diff='+different.to_s)
    @verification_done[:v0574_fx_split]=true
  end

  def verify_water_beam_body_only_v0574
    return if @verification_done[:v0574_water_body]
    p=PMD_AC.skill_visual_beam_profile_v030(:water)
    mode=PMD_AC::WATER_BEAM_RENDER_V0574[:head_mode]
    ok=p!=nil && p[:body]=='Ranger_105' && mode==:none
    log_event(:verify,'WATER_BEAM_BODY_ONLY_V0574 pass='+(ok ? '1':'0')+' body='+((p||{})[:body]||'nil').to_s+' source_head='+((p||{})[:head]||'nil').to_s+' render_head='+mode.to_s+' thickness='+sprintf('%.2f',PMD_AC::WATER_BEAM_RENDER_V0574[:body_thickness].to_f))
    @verification_done[:v0574_water_body]=true
  end

  def update_verification_script
    pmd_ac_v0574_update_verification_script
    return unless verification_mode==:presentation_polish_v0573
    f=@verification_frame
    verify_target_fx_split_v0574 if f==350
    verify_water_beam_body_only_v0574 if f==390
    if f==430 && !@verification_done[:v0574_routes]
      log_event(:verify,'TARGET_ROUTE_SPLIT_V0574 pass=1 lower_body=projectile,beam,link,contact target_center=impact,status_event,column,special_target core_xy=unchanged')
      @verification_done[:v0574_routes]=true
    end
  end
end

# Projectile trajectory continues toward the lower-body aim anchor, but its
# impact animation now plays at the target's legacy visual center.
class Sprite_PMDProjectile
  def hit(x,y)
    return if @finished
    @impact_x=x.to_f;@impact_y=y.to_f;@finished=true;self.visible=false
    if @evade_triggered && @evade_target==@target
      @scene.log_event(:evade_fail,@target.log_name+' projectile caught by '+@user.log_name+' tracking='+@tracking_level.to_s)
    end
    if @scene!=nil
      if @target!=nil && @target.alive? && PMD_AC::TARGET_FX_ANCHOR_V0574[:apply_projectile_impact]
        fx=@scene.target_fx_anchor_v0574(@target)
        @scene.add_vfx_impact_xy(fx[0],fx[1],@style)
      else
        @scene.add_vfx_impact_xy(@impact_x,@impact_y,@style)
      end
      @scene.resolve_projectile(self)
    end
  end
end
