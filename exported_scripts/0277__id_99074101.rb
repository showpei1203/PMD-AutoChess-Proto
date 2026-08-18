#==============================================================================
# 【PMD AutoChess 中文維護說明】
# 腳本：PMD AutoChess Proto v0.74.1
# 分類：核心戰鬥 Runtime
#
# 【用途／機制】
# 承接前序 Data／Config，實際執行戰鬥 Scene、Unit、AI、技能與呈現。
#
# 【怎麼調整】
# 一般平衡與資料調整不要直接改 Runtime；若要追加功能，建議在較後腳本 alias 原方法後擴充。
#
# 【本腳本主要設定常數／資料表】
# - UI_PATCH_VERSION_V0741 / UI_PANEL_FONT_V0741 / HEADER_TITLE_FONT_V0741 / HEADER_SUB_FONT_V0741
# - FOOTER_FONT_V0741 / FOOTER_LV_FONT_V0741 / RESULT_TITLE_FONT_V0741 / RESULT_SUB_FONT_V0741
#
# 【PMD_AC 對外／共用方法】
# - numf_v0741 / numi_v0741 / false_to_i_message_v0741?
#
# 【Runtime 主要方法（查流程時可直接搜尋）】
# - self / change_kind / reset_position / update_position
# - draw_effect / start / apply_skill_effects / refresh_header
# - refresh_footer / show_result
#
# 【維護規則】
# - RPG Maker VX / RGSS2 / Ruby 1.8 相容。
# - instance_uid 才是 Pokémon 個體身份；Actor ID 只是容器。
# - 新增行為優先沿用既有 helper／Data 表；避免破壞已 Freeze 的舊核心。
# - 本專案新腳本也必須保留同等級的中文說明與實際範例。
#==============================================================================
#==============================================================================
# PMD AutoChess Proto v0.74.1
# UI font scope correction + safe numeric guards + rain direction fix
# RGSS2 / Ruby 1.8 compatible
#------------------------------------------------------------------------------
# Fixes:
# - Keep battlefield font behavior (do not force Microsoft JhengHei on popups
#   and floating battle labels).
# - Enlarge UI panel fonts slightly.
# - Guard v0.52 apply_skill_effects false.to_i crash.
# - Guard foot-bar anchor math against false/nil visual offsets.
# - Flip rain streak direction to the intended down-right slant.
#==============================================================================
module PMD_AC
  UI_PATCH_VERSION_V0741 = "0.74.1"
  UI_PANEL_FONT_V0741 = ["Microsoft JhengHei", "微軟正黑體", "Arial"]
  HEADER_TITLE_FONT_V0741 = 20
  HEADER_SUB_FONT_V0741   = 14
  FOOTER_FONT_V0741       = 13
  FOOTER_LV_FONT_V0741    = 12
  RESULT_TITLE_FONT_V0741 = 26
  RESULT_SUB_FONT_V0741   = 15

  def self.numf_v0741(v)
    return 0.0 if v == nil || v == false
    v.to_f
  rescue
    0.0
  end

  def self.numi_v0741(v)
    return 0 if v == nil || v == false
    v.to_i
  rescue
    0
  end

  def self.false_to_i_message_v0741?(ex)
    return false if ex == nil
    msg = ex.message.to_s
    msg.index("to_i") != nil && msg.index("FalseClass") != nil
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
      self.angle = -24
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
      @vx = 5 + rand(3)
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
  # v0.74 made this helper apply a battlefield-wide font override.
  # Keep the battle font behavior from before v0.74 by turning it into a no-op.
  def pmd_ac_v074_set_font(bitmap)
    bitmap
  end

  def update_position
    pmd_ac_v074_update_position
    return if @unit == nil
    gx = PMD_AC.numf_v0741(@unit.pixel_x) +
         PMD_AC.numf_v0741(@unit.visual_offset_x)
    gy = PMD_AC.numf_v0741(@unit.pixel_y) +
         PMD_AC.numf_v0741(@unit.visual_offset_y) +
         PMD_AC.numf_v0741(@unit.victory_bounce_offset)
    gx = gx.to_i
    gy = gy.to_i
    if @bar_sprite != nil
      @bar_sprite.x = gx - PMD_AC::UNIT_BAR_WIDTH / 2
      @bar_sprite.y = gy + PMD_AC::FOOT_BAR_OFFSET_Y_V074
      @bar_sprite.z = self.z + 10
    end
    if @popup_sprite != nil
      @popup_sprite.x = gx - PMD_AC::DAMAGE_POPUP_W_V074 / 2
      @popup_sprite.y += 5
    end
  end
end

class Sprite_PMDChessEffect
  def draw_effect
    pmd_ac_v074_draw_effect
    return unless @type == :miss
    bmp = self.bitmap
    return if bmp == nil
    bmp.clear
    bmp.font.size = PMD_AC::MISS_FONT_V074
    bmp.font.bold = true
    bmp.font.color = Color.new(220,230,240)
    bmp.draw_text(0,20,64,20,"MISS",1)
  end
end

class Scene_PMD_AutoChess
  alias pmd_ac_v0741_apply_skill_effects_guard apply_skill_effects unless method_defined?(:pmd_ac_v0741_apply_skill_effects_guard)

  def pmd_ac_v074_font(bitmap)
    bitmap.font.name = PMD_AC::UI_PANEL_FONT_V0741 if bitmap != nil
  end

  def start
    idx = PMD_AC::VERIFICATION_MODES.index(:normal)
    @verification_mode_index = idx unless idx == nil
    pmd_ac_v074_start
    begin
      if FileTest.exist?(PMD_AC::BATTLE_LOG_FILE)
        t = File.open(PMD_AC::BATTLE_LOG_FILE,'rb'){|f| f.read}
        t.sub!(/PMD AutoChess Proto v0\.[0-9.]+ Battle Verification Log/,
               'PMD AutoChess Proto v0.74.1 Battle Verification Log')
        File.open(PMD_AC::BATTLE_LOG_FILE,'wb'){|f| f.write(t)}
      end
    rescue
    end
    log_event(:presentation,
      'PATCH v0.74.1 keep_battlefield_font=1 ui_font_panel=jhenghei '+
      'ui_font_sizes=larger false_to_i_guard=1 rain_direction=down_right')
    refresh_header
    refresh_footer
  end

  def apply_skill_effects(user,target,data,scale=1.0)
    pmd_ac_v0741_apply_skill_effects_guard(user,target,data,scale)
  rescue NoMethodError => ex
    raise unless PMD_AC.false_to_i_message_v0741?(ex)
    begin
      mk = (data == nil ? nil : data[:canonical_move_key])
      log_event(:presentation,
        'PATCH v0.74.1 FALSE_TO_I_GUARD move=' + (mk == nil ? 'nil' : mk.to_s) +
        ' user=' + (user == nil ? 'nil' : user.log_name) +
        ' target=' + (target == nil ? 'nil' : target.log_name))
    rescue
    end
    0
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
    bmp.draw_text(16,4,Graphics.width-32,24,"PMD 自走棋原型 v0.74.1",1)
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

  def refresh_footer
    return if @footer_sprite == nil
    bmp = @footer_sprite.bitmap
    bmp.clear
    bmp.fill_rect(0,0,Graphics.width,52,Color.new(0,0,0,205))
    pmd_ac_v074_font(bmp)
    bmp.font.size = PMD_AC::FOOTER_FONT_V0741
    bmp.font.bold = false
    bmp.font.color = Color.new(235,240,245)

    if @phase == :deploy
      unit = @selected_unit
      unit = unit_at(@deploy_cursor.cell_x,@deploy_cursor.cell_y) if unit == nil
      line1 = "空白棋格"
      if unit != nil
        line1 = unit.name + "  HP " + unit.maxhp.to_s +
                "  ATK " + unit.atk.to_s +
                "  DEF " + unit.defense.to_s +
                "  " + unit.role_label + "／" + unit.range_label +
                "  AI：" + unit.movement_policy_label + "／" + unit.target_policy_label
      end
      if @selected_unit != nil
        line2 = "已選取 " + @selected_unit.name +
                "｜C 放置／交換｜S " + verification_mode_label +
                "｜B 取消｜Shift 開戰"
      else
        line2 = "方向鍵移動｜C 選取｜S 驗證：" +
                verification_mode_label + "｜Shift 開戰｜B 離開"
      end
      bmp.draw_text(10,2,Graphics.width-20,20,line1,0)
      if unit != nil && unit.team == :ally && unit.pokemon_instance != nil
        bmp.font.size = PMD_AC::FOOTER_LV_FONT_V0741
        bmp.font.color = Color.new(255,220,130)
        bmp.draw_text(Graphics.width-130,2,120,18,
                      "Lv" + unit.level.to_s + "｜D 成長",2)
        bmp.font.size = PMD_AC::FOOTER_FONT_V0741
      end
      bmp.font.color = Color.new(170,220,255)
      bmp.draw_text(10,26,Graphics.width-20,20,line2,0)
    elsif @phase == :battle
      allies = living_units(:ally).size
      enemies = living_units(:enemy).size
      bmp.draw_text(10,2,Graphics.width-20,20,
                    "藍方存活 " + allies.to_s + "｜紅方存活 " + enemies.to_s,0)
      bmp.font.color = Color.new(170,220,255)
      bmp.draw_text(10,26,Graphics.width-20,20,
                    "AI策略／威脅反應｜落空 " + @miss_count.to_s +
                    " 次｜A x1／x2｜" + verification_mode_label,0)
    else
      bmp.draw_text(10,9,Graphics.width-20,26,
                    @result_text + "｜C 回到布陣｜B 離開",1)
    end
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
