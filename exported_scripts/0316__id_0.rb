# encoding: UTF-8
#==============================================================================
# 【PMD AutoChess 中文維護說明】
# 腳本：PMD AutoChess True Foot Bars v0.88.4
# 分類：戰鬥 UI／PMD Sprite 可見腳底定位
# RPG Maker VX / RGSS2 / Ruby 1.8 compatible
#==============================================================================
# 【用途】
# 修正 HP／Energy Bar 雖然舊版稱為 foot bar，實際只使用 Sprite 數值基準 Y
# 定位，遇到不同 PMDCollab 動作圖的透明底部 padding 時，肉眼會看到 Bar
# 浮在角色上方或與角色腳部重疊的問題。
#
# v0.88.4 會依「目前顯示中的 PMD 動作幀」掃描不透明像素最下緣，將
# HP + Energy 共用 Bar 的頂緣放到真正可見腳底下方，再保留少量間距。
# 因為使用最終 Sprite self.y，所以也會自然承接 v0.88.2 近身攻擊 Sprite +5px，
# 不再發生角色本體下移但 Bar 留在舊位置的分離感。
#
#==============================================================================
# 【主要設定項】
# TRUE_FOOT_BAR_GAP_Y_V0884 = 2
#   Bar 頂緣距離可見腳底 2px。
# TRUE_FOOT_ALPHA_THRESHOLD_V0884 = 8
#   Alpha 大於 8 才視為角色實體像素，避免極淡邊緣把腳底誤判太低。
# TRUE_FOOT_SCAN_STEP_X_V0884 = 1
#   水平逐像素掃描。結果會依目前 Sprite Frame 快取，不會每幀重掃同一張圖。
#
#==============================================================================
# 【定位規則】
# 1. 先執行所有舊版 update_position。
# 2. 取得目前 Sprite src_rect（目前動作幀＋方向列）。
# 3. 從該 Frame 最底列向上找第一個可見不透明像素。
# 4. 將其換算為畫面上的 visible_foot_y。
# 5. Bar.y = visible_foot_y + 2px。
#
# Placeholder／讀圖失敗時安全 fallback 到 Sprite 的 self.y + 2px。
#
#==============================================================================
# 【事件／腳本呼叫】
# Runtime 自動套用，不需要事件頁呼叫。
#
# 查詢目前某隻戰鬥 Sprite 的可見腳底：
#   sprite.visible_foot_screen_y_v0884
#
# 清除快取（一般不需要）：
#   PMD_AC.true_foot_cache_v0884.clear
#
#==============================================================================
# 【注意事項】
# - 只改 HP／Energy Bar 畫面位置，不改 Logical pixel_y、命中、AI、Range、VFX Anchor。
# - 不改 Damage Popup、技能名、狀態文字的位置。
# - 不改 Bar 尺寸與數值：仍沿用 33x9 / HP 2px / Energy 2px 的既有設定。
# - 新 RGSS2 程式避免使用不相容的 instance 反射判斷。
#==============================================================================
module PMD_AC
  PATCH_VERSION_V0884 = '0.88.4'
  TRUE_FOOT_BAR_GAP_Y_V0884 = 2
  TRUE_FOOT_ALPHA_THRESHOLD_V0884 = 8
  TRUE_FOOT_SCAN_STEP_X_V0884 = 1

  def self.true_foot_cache_v0884
    @true_foot_cache_v0884={} if @true_foot_cache_v0884==nil
    @true_foot_cache_v0884
  end
end

class Sprite_PMDChessUnit
  alias pmd_ac_v0884_update_position update_position unless method_defined?(:pmd_ac_v0884_update_position)

  def visible_foot_frame_offset_v0884
    return 0.0 if self.bitmap==nil || self.bitmap.disposed?
    return 0.0 if @placeholder
    r=self.src_rect
    return 0.0 if r==nil || r.width.to_i<=0 || r.height.to_i<=0
    key=[@unit==nil ? '' : @unit.species.to_s,
         @unit==nil ? '' : @unit.visual_action.to_s,
         r.x.to_i,r.y.to_i,r.width.to_i,r.height.to_i,
         self.oy.to_i]
    cache=PMD_AC.true_foot_cache_v0884
    return cache[key] if cache.has_key?(key)

    found=-1
    begin
      y=r.height.to_i-1
      step=[PMD_AC::TRUE_FOOT_SCAN_STEP_X_V0884.to_i,1].max
      alpha=PMD_AC::TRUE_FOOT_ALPHA_THRESHOLD_V0884.to_i
      while y>=0 && found<0
        x=0
        while x<r.width.to_i
          px=self.bitmap.get_pixel(r.x.to_i+x,r.y.to_i+y)
          if px.alpha.to_i>alpha
            found=y
            break
          end
          x+=step
        end
        y-=1 if found<0
      end
    rescue
      found=-1
    end

    # self.y 對應 oy。found+1 是可見像素下緣。
    rel=found<0 ? 0.0 : (found.to_f+1.0-self.oy.to_f)*self.zoom_y.to_f
    cache[key]=rel
    rel
  end

  def visible_foot_screen_y_v0884
    self.y.to_f+visible_foot_frame_offset_v0884
  end

  def update_position
    pmd_ac_v0884_update_position
    return if @unit==nil || @bar_sprite==nil
    foot_y=visible_foot_screen_y_v0884
    @bar_sprite.x=self.x.to_i-PMD_AC::UNIT_BAR_WIDTH/2
    @bar_sprite.y=(foot_y+PMD_AC::TRUE_FOOT_BAR_GAP_Y_V0884).round
    @bar_sprite.z=self.z+10
  end
end

class Scene_PMD_AutoChess
  alias pmd_ac_v0884_start start unless method_defined?(:pmd_ac_v0884_start)

  def start
    pmd_ac_v0884_start
    log_event(:presentation,
      'PATCH v0.88.4 hp_energy_bar=true_visible_foot current_frame_alpha_scan=1 gap_y='+
      PMD_AC::TRUE_FOOT_BAR_GAP_Y_V0884.to_s+
      ' melee_sprite_y=v0.88.2_followed logical_y_unchanged=1 mechanics_unchanged=1')
  end
end
