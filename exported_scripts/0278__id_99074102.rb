#==============================================================================
# 【PMD AutoChess 中文維護說明】
# 腳本：PMD AutoChess Proto v0.74.2
# 分類：核心戰鬥 Runtime
#
# 【用途／機制】
# 承接前序 Data／Config，實際執行戰鬥 Scene、Unit、AI、技能與呈現。
#
# 【怎麼調整】
# 一般平衡與資料調整不要直接改 Runtime；若要追加功能，建議在較後腳本 alias 原方法後擴充。
#
# 【本腳本主要設定常數／資料表】
# - UI_PATCH_VERSION_V0742 / FOOT_BAR_OFFSET_Y_V0742 / STATUS_HEAD_OFFSET_Y_V0742 / THREAT_HEAD_OFFSET_Y_V0742
# - AI_HEAD_OFFSET_Y_V0742 / STATUS_MAX_PARTS_V0742
#
# 【PMD_AC 對外／共用方法】
# - player_status_parts_v0742 / player_status_label_v0742
#
# 【Runtime 主要方法（查流程時可直接搜尋）】
# - self / player_status_label_v0742 / change_kind / reset_position
# - update_position / update_status_debug / start / refresh_header
# - show_result
#
# 【維護規則】
# - RPG Maker VX / RGSS2 / Ruby 1.8 相容。
# - instance_uid 才是 Pokémon 個體身份；Actor ID 只是容器。
# - 新增行為優先沿用既有 helper／Data 表；避免破壞已 Freeze 的舊核心。
# - 本專案新腳本也必須保留同等級的中文說明與實際範例。
#==============================================================================
#==============================================================================
# PMD AutoChess Proto v0.74.2
# Battle UI placement / player-facing status cleanup / rain direction correction
# RGSS2 / Ruby 1.8 compatible
#------------------------------------------------------------------------------
# Visual-only patch on top of v0.74.1:
# - Pull HP / Energy bars closer to the sprite foot baseline.
# - Re-anchor status / threat labels closer to the sprite head.
# - Replace raw internal status abbreviations with short player-facing labels.
# - Keep rain streak art and movement drifting in the same down-left direction.
# Combat logic, AI logic, weather mechanics, field effects and damage packets
# remain unchanged.
#==============================================================================
module PMD_AC
  UI_PATCH_VERSION_V0742 = "0.74.2"
  FOOT_BAR_OFFSET_Y_V0742 = -4
  STATUS_HEAD_OFFSET_Y_V0742 = -18
  THREAT_HEAD_OFFSET_Y_V0742 = -32
  AI_HEAD_OFFSET_Y_V0742 = -46
  STATUS_MAX_PARTS_V0742 = 2

  def self.player_status_parts_v0742(unit)
    return [] if unit == nil
    parts = []
    shield = 0
    begin
      shield = unit.instance_variable_get(:@shield).to_i
    rescue
      shield = 0
    end
    parts << ("盾" + shield.to_s) if shield > 0
    parts << "挑釁" if unit.respond_to?(:taunted?) && unit.taunted?
    stun_frames = 0
    begin
      stun_frames = unit.instance_variable_get(:@stun_frames).to_i
    rescue
      stun_frames = 0
    end
    parts << "暈" if stun_frames > 0
    parts << "眠" if unit.respond_to?(:sleeping?) && unit.sleeping?
    parts << "冰" if unit.respond_to?(:frozen?) && unit.frozen?
    parts << "麻" if unit.respond_to?(:paralyzed?) && unit.paralyzed?
    parts << "亂" if unit.respond_to?(:confused?) && unit.confused?
    parts << "畏縮" if unit.respond_to?(:canonical_flinch_pending?) && unit.canonical_flinch_pending?

    status_map = {
      :poison => "毒", :burn => "燒", :regen => "回",
      :slow => "緩", :move_slow => "緩", :attack_slow => "緩", :action_slow => "緩",
      :root => "定", :silence => "封", :fear => "懼",
      :atk_down => "攻↓", :def_down => "防↓",
      :atk_up => "攻↑", :def_up => "防↑"
    }
    begin
      statuses = unit.instance_variable_get(:@statuses)
      if statuses != nil
        for key in statuses.keys
          text = status_map[key]
          parts << text if text != nil && !parts.include?(text)
        end
      end
    rescue
    end

    if unit.respond_to?(:channeling?) && unit.channeling?
      parts << "蓄力" unless parts.include?("蓄力")
    end
    damage_link_frames = 0
    begin
      damage_link_frames = unit.instance_variable_get(:@damage_link_frames).to_i
    rescue
      damage_link_frames = 0
    end
    parts << "連結" if damage_link_frames > 0 && !parts.include?("連結")
    energy_lock = 0
    begin
      energy_lock = unit.instance_variable_get(:@energy_lock).to_i
    rescue
      energy_lock = 0
    end
    parts << "封氣" if energy_lock > 0 && !parts.include?("封氣")
    return parts[0, STATUS_MAX_PARTS_V0742]
  end

  def self.player_status_label_v0742(unit)
    parts = player_status_parts_v0742(unit)
    return "" if parts == nil || parts.empty?
    parts.join(" ")
  end
end

class Game_PMDChessUnit
  def player_status_label_v0742
    PMD_AC.player_status_label_v0742(self)
  end
end

class Sprite_PMDWeatherParticle
  def change_kind(kind)
    return if @kind == kind && self.bitmap != nil
    @kind = kind
    if self.bitmap != nil && !self.bitmap.disposed?
      self.bitmap.dispose
    end
    case @kind
    when :rain
      self.bitmap = Bitmap.new(8, 24)
      6.times do |i|
        self.bitmap.fill_rect(3, i * 3, 2, 3,
          Color.new(185, 225, 255, 210 - i * 20))
      end
      self.angle = 24
      self.blend_type = 0
    when :hail
      self.bitmap = Bitmap.new(8, 8)
      self.bitmap.fill_rect(2, 1, 4, 6, Color.new(240, 248, 255, 220))
      self.bitmap.fill_rect(1, 2, 6, 4, Color.new(210, 230, 255, 190))
      self.angle = 0
      self.blend_type = 0
    else
      self.bitmap = Bitmap.new(4, 4)
      self.bitmap.fill_rect(0, 0, 4, 4, Color.new(255, 255, 255, 255))
      self.angle = 0
      self.blend_type = 0
    end
  end

  def reset_position(initial)
    bx = @bounds[:x]
    by = @bounds[:y]
    bw = @bounds[:w]
    bh = @bounds[:h]
    if @kind == :rain
      self.x = bx + rand(bw + 48) - 24
      self.y = initial ? (by + rand(bh)) : (by - rand(40) - 24)
      @vx = -5 - rand(3)
      @vy = 10 + rand(5)
      zf = 0.85 + rand(35) / 100.0
      self.zoom_x = zf
      self.zoom_y = zf
    elsif @kind == :hail
      self.x = bx + rand(bw + 24) - 12
      self.y = initial ? (by + rand(bh)) : (by - rand(24) - 10)
      @vx = -1 + rand(3)
      @vy = 6 + rand(4)
      zf = 0.8 + rand(45) / 100.0
      self.zoom_x = zf
      self.zoom_y = zf
    else
      self.x = bx + rand(bw)
      self.y = by + rand(bh)
      @vx = 0
      @vy = 0
    end
  end
end

class Sprite_PMDChessUnit
  alias pmd_ac_v0742_update_position update_position unless method_defined?(:pmd_ac_v0742_update_position)

  def update_position
    pmd_ac_v0742_update_position
    return if @unit == nil

    gx = self.x.to_i
    gy = self.y.to_i
    displayed_oy = (self.oy.to_f * self.zoom_y.to_f)
    top_y = (self.y - displayed_oy).to_i

    if @bar_sprite != nil
      @bar_sprite.x = gx - PMD_AC::UNIT_BAR_WIDTH / 2
      @bar_sprite.y = gy + PMD_AC::FOOT_BAR_OFFSET_Y_V0742
      @bar_sprite.z = self.z + 10
    end
    if @popup_sprite != nil
      @popup_sprite.x = gx - PMD_AC::DAMAGE_POPUP_W_V074 / 2
      @popup_sprite.z = self.z + 20
    end
    if @threat_sprite != nil
      @threat_sprite.x = gx - 18
      @threat_sprite.y = top_y + PMD_AC::THREAT_HEAD_OFFSET_Y_V0742
      @threat_sprite.z = self.z + 28
    end
    if @ai_sprite != nil
      @ai_sprite.x = gx - 17
      @ai_sprite.y = top_y + PMD_AC::AI_HEAD_OFFSET_Y_V0742
      @ai_sprite.z = self.z + 11
    end
    if @status_sprite != nil
      @status_sprite.x = gx - 52
      @status_sprite.y = top_y + PMD_AC::STATUS_HEAD_OFFSET_Y_V0742
      @status_sprite.z = self.z + 12
    end
  end

  def update_status_debug
    return if @status_sprite == nil
    unless PMD_AC::SHOW_STATUS_DEBUG
      @status_sprite.visible = false
      return
    end
    label = ""
    begin
      if @unit != nil && @unit.respond_to?(:player_status_label_v0742)
        label = @unit.player_status_label_v0742.to_s
      end
    rescue
      label = ""
    end
    if label != @last_status_label
      @last_status_label = label
      bmp = @status_sprite.bitmap
      bmp.clear
      if label != ""
        w = [[label.size * 14 + 10, 54].max, 102].min
        x = ((104 - w) / 2).to_i
        bmp.fill_rect(x, 1, w, 14, Color.new(0,0,0,145))
        bmp.font.size = PMD_AC::STATUS_FONT_V074
        bmp.font.bold = true
        bmp.font.color = Color.new(220,245,255)
        bmp.draw_text(0,0,104,15,label,1)
      end
    end
    @status_sprite.visible = (label != "" && !@unit.dead?)
  end
end

class Scene_PMD_AutoChess
  alias pmd_ac_v0742_start start unless method_defined?(:pmd_ac_v0742_start)

  def start
    pmd_ac_v0742_start
    begin
      if FileTest.exist?(PMD_AC::BATTLE_LOG_FILE)
        t = File.open(PMD_AC::BATTLE_LOG_FILE,'rb'){|f| f.read}
        t.sub!(/PMD AutoChess Proto v0\.[0-9.]+ Battle Verification Log/,
               'PMD AutoChess Proto v0.74.2 Battle Verification Log')
        File.open(PMD_AC::BATTLE_LOG_FILE,'wb'){|f| f.write(t)}
      end
    rescue
    end
    log_event(:presentation,
      'PATCH v0.74.2 foot_bar_offset=-4 player_status_filter=1 '+
      'status_anchor=head_close threat_anchor=head_close rain_direction=down_left')
    refresh_header
    refresh_footer
  end

  def refresh_header
    return if @header_sprite == nil
    bmp = @header_sprite.bitmap
    bmp.clear
    bmp.fill_rect(0,0,Graphics.width,68,Color.new(0,0,0,180))
    pmd_ac_v074_font(bmp)
    bmp.font.size = PMD_AC::HEADER_TITLE_FONT_V0741
    bmp.font.bold = true
    bmp.font.color = Color.new(255,255,255)
    bmp.draw_text(16,4,Graphics.width-32,24,"PMD 自走棋原型 v0.74.2",1)
    bmp.font.size = PMD_AC::HEADER_SUB_FONT_V0741
    bmp.font.bold = false
    bmp.font.color = Color.new(210,220,230)
    text = ""
    if @phase == :deploy
      text = "戰前布陣｜D 成長/技能｜S 驗證：" + verification_mode_label + "｜Shift 開戰"
    elsif @phase == :battle
      text = "AI Framework／Pixel Movement｜速度 x" + @battle_speed.to_s + "｜A 鍵切換｜B 離開"
    else
      text = "戰鬥結束｜C 回到布陣｜B 離開"
    end
    bmp.draw_text(16,33,Graphics.width-32,21,text,1)
  end

  def show_result
    dispose_sprite(@result_sprite)
    @result_sprite = Sprite.new(@viewport)
    @result_sprite.bitmap = Bitmap.new(360,96)
    @result_sprite.x = (Graphics.width-360)/2
    @result_sprite.y = (Graphics.height-96)/2-12
    @result_sprite.z = 9999
    bmp = @result_sprite.bitmap
    bmp.fill_rect(0,0,360,96,Color.new(0,0,0,220))
    pmd_ac_v074_font(bmp)
    bmp.font.size = PMD_AC::RESULT_TITLE_FONT_V0741
    bmp.font.bold = true
    bmp.font.color = Color.new(255,255,255)
    bmp.draw_text(0,13,360,32,@result_text,1)
    bmp.font.size = PMD_AC::RESULT_SUB_FONT_V0741
    bmp.font.bold = false
    bmp.font.color = Color.new(210,220,230)
    bmp.draw_text(0,55,360,22,"LOG 已寫入專案根目錄｜C 回布陣／B 離開",1)
  end
end
