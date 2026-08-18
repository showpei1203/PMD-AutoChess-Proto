# encoding: UTF-8
#==============================================================================
# PMD AutoChess Skill Type Banner Compact + Max Spike Forensic v1.03.15
# RPG Maker VX / RGSS2 / Ruby 1.8 compatible
#------------------------------------------------------------------------------
# 【用途】
# 1. 將 v1.03.14 戰鬥技能名稱屬性色底板縮至約原視覺占用的 2/3。
# 2. 移除左側屬性文字徽章，只保留「屬性色底板 + 技能名稱」。
# 3. 延續既有 18 屬性色、白字、半透明背景與淡入淡出時序。
# 4. 延續效能追查：不新增每幀計時，只接收 v1.02.3 已計算完成的
#    gap_ms / update_ms，在 severe spike 時另存最大尖峰，避免舊 24 筆紀錄上限
#    將真正最大 update frame 擠掉。
#------------------------------------------------------------------------------
# 【主要設定】
# SKILL_BANNER_WIDTH_V10315  = 100   實際底板寬度，約原 150 的 2/3。
# SKILL_BANNER_HEIGHT_V10315 = 20    實際底板高度，縮小但保留中文字可讀性。
# SKILL_BANNER_FONT_V10315   = 13    技能名稱字體。
# SKILL_BANNER_X_V10315      = 25    在既有 150x32 Bitmap 內水平置中。
# SKILL_BANNER_Y_V10315      = 6     在既有 150x32 Bitmap 內垂直置中。
#------------------------------------------------------------------------------
# 【機制規則】
# - Bitmap / Sprite 容器仍沿用既有 150x32，不改 Sprite position / fade / frames。
# - 只縮小實際繪製區域，因此不影響頭頂定位、skill_popup_frames 或戰鬥流程。
# - 屬性來源與 18 色 palette 直接沿用 v1.03.14。
# - 不顯示「火／水／草／電……」等額外屬性文字。
# - Max Spike forensic 不新增 Time.now，不改 50ms Performance Seal 門檻。
#------------------------------------------------------------------------------
# 【可調參數】
# 可直接調整上列 WIDTH / HEIGHT / FONT / X / Y。
# 若日後想再更細，只需改底板尺寸，不需更動 combat UI authority。
#------------------------------------------------------------------------------
# 【事件／腳本呼叫方式】
# 不需事件呼叫。技能 popup 自動套用。
# Motion verifier 完整跑一場後，LOG 會額外出現：
#   MOTION_MAX_SPIKE_FORENSIC_V10315 ...
#------------------------------------------------------------------------------
# 【實際範例】
# Water Gun：小型藍色半透明底板，只顯示「水槍」。
# Ember：小型橘紅半透明底板，只顯示「火花」。
# Thunderbolt：小型黃色半透明底板，只顯示「十萬伏特」。
#------------------------------------------------------------------------------
# 【不可破壞】
# - 不修改 Damage / Accuracy / Type Effectiveness。
# - 不修改 AI / Attack Speed / Energy。
# - 不修改 logical pixel_x / pixel_y / velocity / Spatial Runtime。
# - 不修改 action_timer、skill_popup_frames、Projectile / Beam gameplay timing。
# - 不修改 Performance Seal 50ms 門檻。
#==============================================================================
module PMD_AC
  SKILL_BANNER_WIDTH_V10315  = 100
  SKILL_BANNER_HEIGHT_V10315 = 20
  SKILL_BANNER_FONT_V10315   = 13
  SKILL_BANNER_X_V10315      = 25
  SKILL_BANNER_Y_V10315      = 6
  MOTION_FORENSIC_SEVERE_MS_V10315 = 45
end

class Sprite_PMDChessUnit
  # v1.03.14 已解析技能屬性；本層只縮小底板並移除屬性文字徽章。
  def update_skill_popup
    frames=@unit.skill_popup_frames
    return if @last_skill_frames==frames
    @last_skill_frames=frames
    bmp=@skill_sprite.bitmap
    bmp.clear
    return if frames<=0

    pmd_ac_v074_set_font(bmp) if respond_to?(:pmd_ac_v074_set_font)
    type=PMD_AC.skill_type_banner_type_v10314(@unit)
    bg=PMD_AC.skill_type_banner_color_v10314(type,PMD_AC::SKILL_TYPE_BANNER_BG_ALPHA_V10314)
    edge=PMD_AC.skill_type_banner_dark_color_v10314(type,220)
    accent=PMD_AC.skill_type_banner_light_color_v10314(type,PMD_AC::SKILL_TYPE_BANNER_ACCENT_ALPHA_V10314)

    x=PMD_AC::SKILL_BANNER_X_V10315
    y=PMD_AC::SKILL_BANNER_Y_V10315
    w=PMD_AC::SKILL_BANNER_WIDTH_V10315
    h=PMD_AC::SKILL_BANNER_HEIGHT_V10315

    # 小型 Pokémon type-icon 語言：深框、屬性色內底、上緣高光。
    # 不再畫任何屬性文字／徽章，整條只服務技能名稱。
    bmp.fill_rect(x,y,w,h,Color.new(0,0,0,150))
    bmp.fill_rect(x+1,y+1,w-2,h-2,edge)
    bmp.fill_rect(x+3,y+3,w-6,h-6,bg)
    bmp.fill_rect(x+4,y+3,w-8,2,accent)

    text=@unit.skill_name.to_s
    bmp.font.size=PMD_AC::SKILL_BANNER_FONT_V10315
    bmp.font.bold=true
    bmp.font.color=Color.new(0,0,0,205)
    bmp.draw_text(x+4,y+1,w-8,h,text,1)
    bmp.font.color=Color.new(255,255,255,255)
    bmp.draw_text(x+3,y,w-8,h,text,1)

    @skill_sprite.opacity=PMD_AC.clamp(frames*12,0,255)
  end
end

class Scene_PMD_AutoChess
  # 不新增 frame timer；使用 v1.02.3 已算好的 gap/update 數值。
  alias pmd_ac_v10315_motion_perf_record_spike_v1023 motion_perf_record_spike_v1023 unless method_defined?(:pmd_ac_v10315_motion_perf_record_spike_v1023)
  def motion_perf_record_spike_v1023(gap_ms,update_ms)
    result=pmd_ac_v10315_motion_perf_record_spike_v1023(gap_ms,update_ms)
    g=gap_ms.to_i
    u=update_ms.to_i
    if g>=PMD_AC::MOTION_FORENSIC_SEVERE_MS_V10315 || u>=PMD_AC::MOTION_FORENSIC_SEVERE_MS_V10315
      old=@motion_max_spike_forensic_v10315
      old_u=old==nil ? -1 : old[:update].to_i
      old_g=old==nil ? -1 : old[:gap].to_i
      if old==nil || u>old_u || (u==old_u && g>old_g)
        @motion_max_spike_forensic_v10315={
          :frame=>motion_perf_relative_frame_v1023,
          :graphics_frame=>(Graphics.frame_count rescue 0),
          :verify=>(@verification_frame.to_i rescue 0),
          :gap=>g,
          :update=>u,
          :phase=>(@phase.to_s rescue 'unknown'),
          :context=>motion_perf_action_context_v1023
        }
      end
    end
    result
  rescue
    result
  end

  alias pmd_ac_v10315_motion_perf_log_summary_v1023 motion_perf_log_summary_v1023 unless method_defined?(:pmd_ac_v10315_motion_perf_log_summary_v1023)
  def motion_perf_log_summary_v1023
    already=@motion_perf_summary_logged_v1023
    result=pmd_ac_v10315_motion_perf_log_summary_v1023
    if !already && @motion_perf_summary_logged_v1023
      r=@motion_max_spike_forensic_v10315
      if r!=nil
        log_event(:perf,'MOTION_MAX_SPIKE_FORENSIC_V10315 frame='+r[:frame].to_i.to_s+
          ' graphics_frame='+r[:graphics_frame].to_i.to_s+
          ' verify_frame='+r[:verify].to_i.to_s+
          ' gap_ms='+r[:gap].to_i.to_s+' update_ms='+r[:update].to_i.to_s+
          ' phase='+r[:phase].to_s+' record_limit_bypass=1 extra_frame_timer=0'+
          ' actions=['+r[:context].to_s+']')
      else
        log_event(:perf,'MOTION_MAX_SPIKE_FORENSIC_V10315 frame=-1 gap_ms=0 update_ms=0'+
          ' severe_seen=0 record_limit_bypass=1 extra_frame_timer=0')
      end
    end
    result
  rescue
    result
  end

  alias pmd_ac_v10315_skill_banner_compact_start start unless method_defined?(:pmd_ac_v10315_skill_banner_compact_start)
  def start
    pmd_ac_v10315_skill_banner_compact_start
    begin
      log_event(:ui,'SKILL_TYPE_BANNER_V10315 ready=1 visual_scale=0.667 banner=100x20'+
        ' type_text=0 badge=0 skill_text_only=1 palette=v10314 font=13'+
        ' popup_bitmap_unchanged=150x32 popup_frames_unchanged=1 action_timer_unchanged=1'+
        ' damage_unchanged=1 ai_unchanged=1 attack_speed_unchanged=1 energy_unchanged=1 spatial_unchanged=1')
    rescue
    end
  end
end
