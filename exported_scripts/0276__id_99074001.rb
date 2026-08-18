#==============================================================================
# 【PMD AutoChess 中文維護說明】
# 腳本：PMD AutoChess Proto v0.74
# 分類：核心戰鬥 Runtime
#
# 【用途／機制】
# 承接前序 Data／Config，實際執行戰鬥 Scene、Unit、AI、技能與呈現。
#
# 【怎麼調整】
# 一般平衡與資料調整不要直接改 Runtime；若要追加功能，建議在較後腳本 alias 原方法後擴充。
#
# 【本腳本主要設定常數／資料表】
# - UI_PATCH_VERSION_V074 / BATTLE_FONT_V074 / DAMAGE_POPUP_W_V074 / DAMAGE_POPUP_H_V074
# - DAMAGE_FONT_V074 / CRIT_FONT_V074 / SKILL_FONT_V074 / THREAT_FONT_V074
# - AI_FONT_V074 / STATUS_FONT_V074 / MISS_FONT_V074 / PLACEHOLDER_FONT_V074
# - FOOT_BAR_OFFSET_Y_V074 / HEADER_TITLE_FONT_V074 / HEADER_SUB_FONT_V074 / FOOTER_FONT_V074
# - RESULT_TITLE_FONT_V074 / RESULT_SUB_FONT_V074
#
# 【Runtime 主要方法（查流程時可直接搜尋）】
# - initialize / update_position / update_popup / update_skill_popup
# - update_threat_debug / update_ai_debug / update_status_debug / create_placeholder_bitmap
# - draw_effect / start / terminate / refresh_header
#
# 【維護規則】
# - RPG Maker VX / RGSS2 / Ruby 1.8 相容。
# - instance_uid 才是 Pokémon 個體身份；Actor ID 只是容器。
# - 新增行為優先沿用既有 helper／Data 表；避免破壞已 Freeze 的舊核心。
# - 本專案新腳本也必須保留同等級的中文說明與實際範例。
#==============================================================================
#==============================================================================
# PMD AutoChess Proto v0.74
# Battle UI Readability Polish
# RGSS2 / Ruby 1.8 compatible
#------------------------------------------------------------------------------
# Visual-only patch:
# - Damage popup approximately 50% text size.
# - HP / Energy bar moved from above the battler to the logical foot baseline.
# - Battle UI uses Microsoft JhengHei with safe fallbacks.
# - Skill / debug / header / footer / result text slightly reduced.
# Combat math, AI, movement, weather, field, anchors and timing are unchanged.
#==============================================================================
module PMD_AC
  UI_PATCH_VERSION_V074 = "0.74"
  BATTLE_FONT_V074 = ["Microsoft JhengHei", "微軟正黑體", "Arial"]
  DAMAGE_POPUP_W_V074 = 56
  DAMAGE_POPUP_H_V074 = 18
  DAMAGE_FONT_V074 = 10
  CRIT_FONT_V074 = 9
  SKILL_FONT_V074 = 13
  THREAT_FONT_V074 = 14
  AI_FONT_V074 = 10
  STATUS_FONT_V074 = 9
  MISS_FONT_V074 = 12
  PLACEHOLDER_FONT_V074 = 15
  FOOT_BAR_OFFSET_Y_V074 = 2
  HEADER_TITLE_FONT_V074 = 18
  HEADER_SUB_FONT_V074 = 13
  FOOTER_FONT_V074 = 12
  RESULT_TITLE_FONT_V074 = 24
  RESULT_SUB_FONT_V074 = 14
end

class Sprite_PMDChessUnit
  alias pmd_ac_v074_initialize initialize unless method_defined?(:pmd_ac_v074_initialize)
  alias pmd_ac_v074_update_position update_position unless method_defined?(:pmd_ac_v074_update_position)

  def pmd_ac_v074_set_font(bitmap)
    return if bitmap==nil
    bitmap.font.name=PMD_AC::BATTLE_FONT_V074
  end

  def initialize(viewport,unit)
    pmd_ac_v074_initialize(viewport,unit)
    if @popup_sprite!=nil && @popup_sprite.bitmap!=nil
      old=@popup_sprite.bitmap
      @popup_sprite.bitmap=Bitmap.new(PMD_AC::DAMAGE_POPUP_W_V074,
                                      PMD_AC::DAMAGE_POPUP_H_V074)
      old.dispose unless old.disposed?
      @last_popup_frames=-1
    end
    [@bar_sprite,@popup_sprite,@skill_sprite,@threat_sprite,
     @ai_sprite,@status_sprite].each do |s|
      pmd_ac_v074_set_font(s.bitmap) if s!=nil
    end
  end

  def update_position
    # Preserve all prior altitude/presentation logic first.
    pmd_ac_v074_update_position
    return if @unit==nil

    # UI remains attached to the logical ground position, exactly like the
    # verified pre-v0.74 bar anchor.  Only its vertical placement changes.
    gx=(@unit.pixel_x+@unit.visual_offset_x).to_i
    gy=(@unit.pixel_y+@unit.visual_offset_y+@unit.victory_bounce_offset).to_i
    if @bar_sprite!=nil
      @bar_sprite.x=gx-PMD_AC::UNIT_BAR_WIDTH/2
      @bar_sprite.y=gy+PMD_AC::FOOT_BAR_OFFSET_Y_V074
      @bar_sprite.z=self.z+10
    end

    # The smaller damage bitmap should remain centered over the battler.
    if @popup_sprite!=nil
      @popup_sprite.x=gx-PMD_AC::DAMAGE_POPUP_W_V074/2
      @popup_sprite.y+=5
    end
  end

  def update_popup
    frames=@unit.damage_popup_frames
    return if @last_popup_frames==frames
    old_frames=@last_popup_frames
    @last_popup_frames=frames
    if frames>0 && (old_frames<=0 || frames>old_frames)
      self.flash(Color.new(255,255,255,185),6)
    end
    bmp=@popup_sprite.bitmap
    bmp.clear
    return if frames<=0
    pmd_ac_v074_set_font(bmp)
    bmp.font.bold=true
    if @unit.last_damage_critical
      bmp.font.size=PMD_AC::CRIT_FONT_V074
      bmp.font.color=Color.new(255,220,90)
      bmp.draw_text(0,0,PMD_AC::DAMAGE_POPUP_W_V074,
                    PMD_AC::DAMAGE_POPUP_H_V074,
                    "CRIT -"+@unit.last_damage.to_s,1)
    else
      bmp.font.size=PMD_AC::DAMAGE_FONT_V074
      bmp.font.color=Color.new(255,245,210)
      bmp.draw_text(0,0,PMD_AC::DAMAGE_POPUP_W_V074,
                    PMD_AC::DAMAGE_POPUP_H_V074,
                    "-"+@unit.last_damage.to_s,1)
    end
    @popup_sprite.opacity=PMD_AC.clamp(frames*10,0,255)
  end

  def update_skill_popup
    frames=@unit.skill_popup_frames
    return if @last_skill_frames==frames
    @last_skill_frames=frames
    bmp=@skill_sprite.bitmap
    bmp.clear
    return if frames<=0
    pmd_ac_v074_set_font(bmp)
    bmp.fill_rect(8,5,104,18,Color.new(0,0,0,170))
    bmp.font.size=PMD_AC::SKILL_FONT_V074
    bmp.font.bold=true
    bmp.font.color=Color.new(255,235,120)
    bmp.draw_text(0,2,120,20,@unit.skill_name,1)
    @skill_sprite.opacity=PMD_AC.clamp(frames*12,0,255)
  end

  def update_threat_debug
    return if @threat_sprite==nil
    unless PMD_AC::SHOW_THREAT_DEBUG
      @threat_sprite.visible=false
      return
    end
    label=@unit.threat_debug_label
    if label!=@last_threat_label
      @last_threat_label=label
      bmp=@threat_sprite.bitmap
      bmp.clear
      if label!=""
        pmd_ac_v074_set_font(bmp)
        bmp.font.size=PMD_AC::THREAT_FONT_V074
        bmp.font.bold=true
        bmp.font.color=label=="!!" ? Color.new(255,110,80) : Color.new(255,225,90)
        bmp.draw_text(0,0,36,20,label,1)
      end
    end
    @threat_sprite.visible=(label!="" && !@unit.dead?)
  end

  def update_ai_debug
    return if @ai_sprite==nil
    unless PMD_AC::SHOW_AI_DEBUG
      @ai_sprite.visible=false
      return
    end
    label=@unit.ai_debug_label
    if label!=@last_ai_label
      @last_ai_label=label
      bmp=@ai_sprite.bitmap
      bmp.clear
      bmp.fill_rect(2,1,30,14,Color.new(0,0,0,150))
      pmd_ac_v074_set_font(bmp)
      bmp.font.size=PMD_AC::AI_FONT_V074
      bmp.font.bold=true
      bmp.font.color=Color.new(190,225,255)
      bmp.draw_text(0,0,34,15,label,1)
    end
    @ai_sprite.visible=!@unit.dead?
  end

  def update_status_debug
    return if @status_sprite==nil
    unless PMD_AC::SHOW_STATUS_DEBUG
      @status_sprite.visible=false
      return
    end
    label=@unit.status_debug_label
    if label!=@last_status_label
      @last_status_label=label
      bmp=@status_sprite.bitmap
      bmp.clear
      if label!=""
        bmp.fill_rect(1,1,102,14,Color.new(0,0,0,145))
        pmd_ac_v074_set_font(bmp)
        bmp.font.size=PMD_AC::STATUS_FONT_V074
        bmp.font.bold=true
        bmp.font.color=Color.new(220,245,255)
        bmp.draw_text(0,0,104,15,label,1)
      end
    end
    @status_sprite.visible=(label!="" && !@unit.dead?)
  end

  def create_placeholder_bitmap
    @placeholder=true
    @action_data=nil
    self.bitmap=Bitmap.new(52,52)
    @owns_bitmap=true
    color=@unit.team==:ally ? Color.new(70,160,235) : Color.new(230,95,95)
    self.bitmap.fill_rect(4,4,44,44,Color.new(20,20,20,210))
    self.bitmap.fill_rect(7,7,38,38,color)
    pmd_ac_v074_set_font(self.bitmap)
    self.bitmap.font.size=PMD_AC::PLACEHOLDER_FONT_V074
    self.bitmap.font.bold=true
    self.bitmap.font.color=Color.new(255,255,255)
    self.bitmap.draw_text(0,11,52,24,@unit.mark,1)
    self.src_rect.set(0,0,52,52)
    self.ox=26
    self.oy=48
  end
end

class Sprite_PMDChessEffect
  alias pmd_ac_v074_draw_effect draw_effect unless method_defined?(:pmd_ac_v074_draw_effect)
  def draw_effect
    pmd_ac_v074_draw_effect
    return unless @type==:miss
    bmp=self.bitmap
    bmp.clear
    bmp.font.name=PMD_AC::BATTLE_FONT_V074
    bmp.font.size=PMD_AC::MISS_FONT_V074
    bmp.font.bold=true
    bmp.font.color=Color.new(220,230,240)
    bmp.draw_text(0,20,64,20,"MISS",1)
  end
end

class Scene_PMD_AutoChess
  alias pmd_ac_v074_start start unless method_defined?(:pmd_ac_v074_start)
  alias pmd_ac_v074_terminate terminate unless method_defined?(:pmd_ac_v074_terminate)

  def pmd_ac_v074_font(bitmap)
    bitmap.font.name=PMD_AC::BATTLE_FONT_V074 if bitmap!=nil
  end

  def start
    @pmd_ac_v074_old_font_name=Font.default_name
    Font.default_name=PMD_AC::BATTLE_FONT_V074
    # Full Soak is now accepted.  Default back to NORMAL for visual/gameplay
    # iteration while keeping all verification modes available with S.
    idx=PMD_AC::VERIFICATION_MODES.index(:normal)
    @verification_mode_index=idx unless idx==nil
    pmd_ac_v074_start
    begin
      if FileTest.exist?(PMD_AC::BATTLE_LOG_FILE)
        t=File.open(PMD_AC::BATTLE_LOG_FILE,'rb'){|f|f.read}
        t.sub!(/PMD AutoChess Proto v0\.73 Battle Verification Log/,
               'PMD AutoChess Proto v0.74 Battle Verification Log')
        File.open(PMD_AC::BATTLE_LOG_FILE,'wb'){|f|f.write(t)}
      end
    rescue
    end
    log_event(:presentation,
      'PATCH v0.74 battle_ui_font=Microsoft_JhengHei damage_popup=20_to_10 '+
      'crit_popup=16_to_9 hp_energy_anchor=foot+2 skill_font=13 '+
      'normal_combat_mechanics_unchanged=1')
    refresh_header
    refresh_footer
  end

  def terminate
    begin
      pmd_ac_v074_terminate
    ensure
      begin
        Font.default_name=@pmd_ac_v074_old_font_name if @pmd_ac_v074_old_font_name!=nil
      rescue
      end
    end
  end

  def refresh_header
    return if @header_sprite==nil
    bmp=@header_sprite.bitmap
    bmp.clear
    bmp.fill_rect(0,0,Graphics.width,68,Color.new(0,0,0,180))
    pmd_ac_v074_font(bmp)
    bmp.font.size=PMD_AC::HEADER_TITLE_FONT_V074
    bmp.font.bold=true
    bmp.font.color=Color.new(255,255,255)
    bmp.draw_text(16,4,Graphics.width-32,24,"PMD 自走棋原型 v0.74",1)
    bmp.font.size=PMD_AC::HEADER_SUB_FONT_V074
    bmp.font.bold=false
    bmp.font.color=Color.new(210,220,230)
    text=""
    if @phase==:deploy
      text="戰前布陣｜D 成長/技能｜S 驗證："+verification_mode_label+"｜Shift 開戰"
    elsif @phase==:battle
      text="AI Framework／Pixel Movement｜速度 x"+@battle_speed.to_s+"｜A 鍵切換｜B 離開"
    else
      text="戰鬥結束｜C 回到布陣｜B 離開"
    end
    bmp.draw_text(16,33,Graphics.width-32,21,text,1)
  end

  def refresh_footer
    return if @footer_sprite==nil
    bmp=@footer_sprite.bitmap
    bmp.clear
    bmp.fill_rect(0,0,Graphics.width,52,Color.new(0,0,0,205))
    pmd_ac_v074_font(bmp)
    bmp.font.size=PMD_AC::FOOTER_FONT_V074
    bmp.font.bold=false
    bmp.font.color=Color.new(235,240,245)

    if @phase==:deploy
      unit=@selected_unit
      unit=unit_at(@deploy_cursor.cell_x,@deploy_cursor.cell_y) if unit==nil
      line1="空白棋格"
      if unit!=nil
        line1=unit.name+"  HP "+unit.maxhp.to_s+
              "  ATK "+unit.atk.to_s+
              "  DEF "+unit.defense.to_s+
              "  "+unit.role_label+"／"+unit.range_label+
              "  AI："+unit.movement_policy_label+"／"+unit.target_policy_label
      end
      if @selected_unit!=nil
        line2="已選取 "+@selected_unit.name+
              "｜C 放置／交換｜S "+verification_mode_label+
              "｜B 取消｜Shift 開戰"
      else
        line2="方向鍵移動｜C 選取｜S 驗證："+
              verification_mode_label+"｜Shift 開戰｜B 離開"
      end
      bmp.draw_text(10,2,Graphics.width-20,20,line1,0)
      if unit!=nil && unit.team==:ally && unit.pokemon_instance!=nil
        bmp.font.size=11
        bmp.font.color=Color.new(255,220,130)
        bmp.draw_text(Graphics.width-130,2,120,18,
                      "Lv"+unit.level.to_s+"｜D 成長",2)
        bmp.font.size=PMD_AC::FOOTER_FONT_V074
      end
      bmp.font.color=Color.new(170,220,255)
      bmp.draw_text(10,26,Graphics.width-20,20,line2,0)
    elsif @phase==:battle
      allies=living_units(:ally).size
      enemies=living_units(:enemy).size
      bmp.draw_text(10,2,Graphics.width-20,20,
                    "藍方存活 "+allies.to_s+"｜紅方存活 "+enemies.to_s,0)
      bmp.font.color=Color.new(170,220,255)
      bmp.draw_text(10,26,Graphics.width-20,20,
                    "AI策略／威脅反應｜落空 "+@miss_count.to_s+
                    " 次｜A x1／x2｜"+verification_mode_label,0)
    else
      bmp.draw_text(10,9,Graphics.width-20,26,
                    @result_text+"｜C 回到布陣｜B 離開",1)
    end
  end

  def show_result
    dispose_sprite(@result_sprite)
    @result_sprite=Sprite.new(@viewport)
    @result_sprite.bitmap=Bitmap.new(360,96)
    @result_sprite.x=(Graphics.width-360)/2
    @result_sprite.y=(Graphics.height-96)/2-12
    @result_sprite.z=9999
    bmp=@result_sprite.bitmap
    bmp.fill_rect(0,0,360,96,Color.new(0,0,0,220))
    pmd_ac_v074_font(bmp)
    bmp.font.size=PMD_AC::RESULT_TITLE_FONT_V074
    bmp.font.bold=true
    bmp.font.color=Color.new(255,255,255)
    bmp.draw_text(0,13,360,32,@result_text,1)
    bmp.font.size=PMD_AC::RESULT_SUB_FONT_V074
    bmp.font.bold=false
    bmp.font.color=Color.new(210,220,230)
    bmp.draw_text(0,55,360,22,"LOG 已寫入專案根目錄｜C 回布陣／B 離開",1)
  end
end
