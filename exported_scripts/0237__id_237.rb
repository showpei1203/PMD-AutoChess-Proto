#==============================================================================
# 【PMD AutoChess 中文維護說明】
# 腳本：PMD AutoChess Proto v0.57.6
# 分類：核心戰鬥 Runtime
#
# 【用途／機制】
# 承接前序 Data／Config，實際執行戰鬥 Scene、Unit、AI、技能與呈現。
#
# 【怎麼調整】
# 一般平衡與資料調整不要直接改 Runtime；若要追加功能，建議在較後腳本 alias 原方法後擴充。
#
# 【本腳本主要設定常數／資料表】
# - PRESENTATION_PATCH_VERSION_V0576
#
# 【Runtime 主要方法（查流程時可直接搜尋）】
# - contact_bottom_cache_v0576 / visible_bottom_rel_for_action_v0576 / contact_visible_baseline_correction_v0576 / presentation_contact_visible_correction_v0576
# - presentation_sprite_offset_v055 / start / verify_contact_visible_baseline_v0576 / update_verification_script
#
# 【維護規則】
# - RPG Maker VX / RGSS2 / Ruby 1.8 相容。
# - instance_uid 才是 Pokémon 個體身份；Actor ID 只是容器。
# - 新增行為優先沿用既有 helper／Data 表；避免破壞已 Freeze 的舊核心。
# - 本專案新腳本也必須保留同等級的中文說明與實際範例。
#==============================================================================
#==============================================================================
# ■ PMD AutoChess Proto v0.57.6
#    Contact Visible-Foot Baseline Fix
#------------------------------------------------------------------------------
# Additive patch on v0.57.5.
# - v0.57.5 aligned Sprite Y numerically to target.pixel_y.
# - v0.57.6 additionally compensates per-action transparent bottom padding so
#   the two Pokemon's VISIBLE ground/foot line is actually horizontal.
# - Beam / projectile / impact / target-FX anchors remain v0.57.4 unchanged.
#==============================================================================
module PMD_AC
  PRESENTATION_PATCH_VERSION_V0576 = "0.57.6"
  class << self
    def contact_bottom_cache_v0576
      @contact_bottom_cache_v0576={} if @contact_bottom_cache_v0576==nil
      @contact_bottom_cache_v0576
    end

    def visible_bottom_rel_for_action_v0576(unit,action)
      return 0.0 if unit==nil
      act=action==nil ? :idle : action
      key=[unit.species.to_s,act]
      c=contact_bottom_cache_v0576
      return c[key] if c.has_key?(key)
      d=action_data(unit.species,act)
      if d==nil
        c[key]=0.0
        return 0.0
      end
      fw=d[:frame_w].to_i;fh=d[:frame_h].to_i
      if fw<=0 || fh<=0 || d[:file]==nil
        c[key]=0.0
        return 0.0
      end
      begin
        bmp=Cache.load_bitmap(PMD_ROOT+unit.species.to_s+"/",d[:file])
      rescue
        c[key]=0.0
        return 0.0
      end
      frames=d[:frames].to_i
      dur=d[:durations]
      frames=dur.size if frames<=0 && dur!=nil
      frames=1 if frames<=0
      cols=[bmp.width/fw,1].max
      frames=[frames,cols].min
      rows=[bmp.height/fh,1].max
      step=[CONTACT_VISIBLE_BASELINE_V0576[:scan_step].to_i,1].max
      alpha=CONTACT_VISIBLE_BASELINE_V0576[:alpha_threshold].to_i
      maxy=-1
      y=fh-1
      while y>=0 && maxy<0
        row=0
        while row<rows && maxy<0
          f=0
          while f<frames && maxy<0
            sx=f*fw;sy=row*fh
            x=0
            while x<fw
              begin
                px=bmp.get_pixel(sx+x,sy+y)
                if px.alpha.to_i>alpha
                  maxy=y
                  break
                end
              rescue
              end
              x+=step
            end
            f+=1
          end
          row+=1
        end
        y-=1 if maxy<0
      end
      rel=maxy<0 ? 0.0 : (maxy.to_f+1.0-fh.to_f)*UNIT_SPRITE_SCALE.to_f
      c[key]=rel
      rel
    end

    def contact_visible_baseline_correction_v0576(attacker,target)
      return 0.0 if attacker==nil || target==nil
      aa=attacker.respond_to?(:visual_action) ? attacker.visual_action : :attack
      ta=CONTACT_VISIBLE_BASELINE_V0576[:target_reference_action]
      ar=visible_bottom_rel_for_action_v0576(attacker,aa)
      tr=visible_bottom_rel_for_action_v0576(target,ta)
      corr=tr-ar
      cap=CONTACT_VISIBLE_BASELINE_V0576[:max_correction_px].to_f
      corr=cap if corr>cap
      corr=-cap if corr<(-cap)
      corr
    end
  end
end

class Game_PMDChessUnit
  alias pmd_ac_v0576_presentation_sprite_offset_v055 presentation_sprite_offset_v055 unless method_defined?(:pmd_ac_v0576_presentation_sprite_offset_v055)

  def presentation_contact_visible_correction_v0576
    return 0.0 unless PMD_AC::CONTACT_VISIBLE_BASELINE_V0576[:enabled]
    return 0.0 unless presentation_motion_active_v055?
    p=@presentation_profile_v055
    return 0.0 if p==nil || !PMD_AC.contact_ground_y_motion_v0575?(p[:motion])
    t=@skill_target
    return 0.0 if t==nil || t.dead?
    PMD_AC.contact_visible_baseline_correction_v0576(self,t)
  end

  def presentation_sprite_offset_v055
    base=pmd_ac_v0576_presentation_sprite_offset_v055
    return base unless PMD_AC::CONTACT_VISIBLE_BASELINE_V0576[:enabled]
    return base unless presentation_motion_active_v055?
    p=@presentation_profile_v055
    return base if p==nil || !PMD_AC.contact_ground_y_motion_v0575?(p[:motion])
    corr=presentation_contact_visible_correction_v0576
    return base if corr.abs<0.001
    factor=presentation_contact_y_factor_v0575(p)
    [base[0].to_f,base[1].to_f+corr*factor]
  end
end

class Scene_PMD_AutoChess
  alias pmd_ac_v0576_start start unless method_defined?(:pmd_ac_v0576_start)
  alias pmd_ac_v0576_update_verification_script update_verification_script unless method_defined?(:pmd_ac_v0576_update_verification_script)

  def start
    pmd_ac_v0576_start
    begin
      if FileTest.exist?(PMD_AC::BATTLE_LOG_FILE)
        t=File.open(PMD_AC::BATTLE_LOG_FILE,'rb'){|f|f.read}
        t.sub!(/PMD AutoChess Proto v0\.57\.5 Battle Verification Log/,'PMD AutoChess Proto v0.57.6 Battle Verification Log')
        File.open(PMD_AC::BATTLE_LOG_FILE,'wb'){|f|f.write(t)}
      end
    rescue
    end
    log_event(:presentation,'PATCH v0.57.6 contact_visible_baseline=opaque_foot action_padding_compensation=1 target_pixel_y_rule_preserved=1 beam_projectile_impact_targetfx_unchanged=1')
  end

  def verify_contact_visible_baseline_v0576
    return if @verification_done[:v0576_contact_visible]
    u=verification_unit(:ally,:charmander)
    t=verification_unit(:enemy,:caterpie)
    ok=u!=nil && t!=nil
    ar=0.0;tr=0.0;corr=0.0;rendered=0.0;targetfoot=0.0
    if ok
      ar=PMD_AC.visible_bottom_rel_for_action_v0576(u,:attack)
      tr=PMD_AC.visible_bottom_rel_for_action_v0576(t,:idle)
      corr=tr-ar
      rendered=t.pixel_y.to_f+corr+ar
      targetfoot=t.pixel_y.to_f+tr
      ok=(rendered-targetfoot).abs<0.01
    end
    log_event(:verify,'CONTACT_VISIBLE_BASELINE_V0576 pass='+(ok ? '1':'0')+' attacker_action_rel='+sprintf('%.1f',ar)+' target_idle_rel='+sprintf('%.1f',tr)+' correction='+sprintf('%.1f',corr)+' rendered_foot_y='+sprintf('%.1f',rendered)+' target_foot_y='+sprintf('%.1f',targetfoot)+' same_line='+(ok ? '1':'0')+' beam_fx_unchanged=1')
    @verification_done[:v0576_contact_visible]=true
  end

  def update_verification_script
    pmd_ac_v0576_update_verification_script
    return unless verification_mode==:presentation_polish_v0573
    verify_contact_visible_baseline_v0576 if @verification_frame==455
  end
end
