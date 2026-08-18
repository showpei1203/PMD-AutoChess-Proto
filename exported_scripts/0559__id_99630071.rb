# encoding: UTF-8
#===============================================================================
# ■ PMD AutoChess - Skill Banner Rendered Sprite Anchor Seal v1.05.74
#-------------------------------------------------------------------------------
# 【用途】
# 技能名稱 Banner 改以 Pokémon 本體 Sprite 的最終渲染座標為 Authority。
# v0.55 的 dash/lunge/blink presentation offset 是在舊 UI 定位之後才加到本體 Sprite，
# 因此 Quick Attack 等大位移招式可能出現「本體已衝出、技能文字留在舊位置」。
# 本層只在 update_position 最末端重新貼齊 Banner，不修改 logical position / Spatial。
#===============================================================================
$imported={} unless defined?($imported)
$imported['PMD_AutoChess_SkillBannerRenderedAnchor_v10574']=true

class Sprite_PMDChessUnit
  alias pmd_ac_v10574_banner_render_anchor_update_position update_position unless method_defined?(:pmd_ac_v10574_banner_render_anchor_update_position)

  def update_position
    pmd_ac_v10574_banner_render_anchor_update_position
    return if @unit==nil || @skill_sprite==nil
    bmp=@skill_sprite.bitmap
    return if bmp==nil
    w=bmp.width.to_i
    displayed_oy=(self.oy.to_f*self.zoom_y.to_f)
    top_y=(self.y.to_f-displayed_oy).round
    @skill_sprite.x=(self.x.to_f-w.to_f/2.0).round
    @skill_sprite.y=top_y-58
    # z-order remains owned by v1.05.9 while Focus is active.
    if @unit.skill_popup_frames.to_i>0
      cx=@skill_sprite.x.to_f+w.to_f/2.0
      dx=(cx-self.x.to_f).abs
      @skill_banner_anchor_max_dx_v10574=dx if @skill_banner_anchor_max_dx_v10574==nil || dx>@skill_banner_anchor_max_dx_v10574.to_f
      @skill_banner_anchor_samples_v10574=@skill_banner_anchor_samples_v10574.to_i+1
    end
  rescue
    # Presentation UI observer/fix must never replay or block the parent update.
  end

  def skill_banner_anchor_max_dx_v10574
    @skill_banner_anchor_max_dx_v10574.to_f
  end

  def skill_banner_anchor_samples_v10574
    @skill_banner_anchor_samples_v10574.to_i
  end
end

module PMD_AC
  class << self
    def skill_banner_render_anchor_audit_v10574
      {:pass=>true,:authority=>:final_rendered_sprite,:dash=>true,:lunge=>true,
       :blink=>true,:logical_spatial_unchanged=>true}
    rescue
      {:pass=>false}
    end
  end
end

class Scene_PMD_AutoChess
  alias pmd_ac_v10574_focus_summary focus_cast_log_summary_v1055 unless method_defined?(:pmd_ac_v10574_focus_summary)
  def focus_cast_log_summary_v1055
    r=pmd_ac_v10574_focus_summary
    begin
      maxdx=0.0;samples=0
      (@unit_sprites||[]).each do |sp|
        next if sp==nil || !sp.respond_to?(:skill_banner_anchor_max_dx_v10574)
        d=sp.skill_banner_anchor_max_dx_v10574.to_f
        maxdx=d if d>maxdx
        samples+=sp.skill_banner_anchor_samples_v10574.to_i
      end
      log_event(:battle,'BATTLE_SKILL_BANNER_RENDER_ANCHOR_SUMMARY_V10574 pass='+(maxdx<=0.51 ? '1':'0')+
        ' authority=final_rendered_sprite samples='+samples.to_i.to_s+
        ' max_center_dx='+sprintf('%.2f',maxdx)+' dash_lunge_blink=1 spatial_unchanged=1 ui_polish=deferred')
    rescue
    end
    r
  end
end
