# encoding: UTF-8
#==============================================================================
# PMD AutoChess Skill Type Banner UI v1.03.14
# 戰鬥技能名稱屬性色底板／屬性徽章
# RPG Maker VX / RGSS2 / Ruby 1.8 compatible
#------------------------------------------------------------------------------
# 【用途】
# 戰鬥中 Pokémon 使用技能時，既有 skill popup 會在單位頭上顯示技能名稱，
# 過去底板固定為黑色半透明。本腳本只修改這塊 presentation UI：
#   1. 依招式 Pokémon 屬性使用不同半透明主色。
#   2. 左側加入小型「屬性徽章」，外觀參考 Pokémon 屬性 icon 的色塊語言。
#   3. 使用深色外框＋屬性色內框＋上緣亮線，提升 45° PMD 戰場上的辨識度。
#   4. 技能名稱改為白字＋深色陰影，避免深色／亮色屬性底板吃字。
#
# 【顏色規則】
# TYPE_COLOR_V10314 使用 Pokémon Diamond / Pearl 時期常見的 17 屬性色，
# 並補入 Fairy。色值只影響 UI，不參與屬性相剋、傷害、AI 或技能資料。
#
# 【屬性來源優先序】
# 1. unit.skill_data[:move_type]
# 2. unit.skill_data[:type]
# 3. canonical_move_key -> PMD_AC.move_data
# 4. 舊版自訂技能 LEGACY_SKILL_TYPE_V10314
# 5. 找不到時回退 :normal
#
# 【可調參數】
# SKILL_TYPE_BANNER_BG_ALPHA_V10314    主底板透明度
# SKILL_TYPE_BANNER_ACCENT_ALPHA_V10314 上緣亮線透明度
# SKILL_TYPE_BANNER_BADGE_ALPHA_V10314  左側徽章透明度
# TYPE_COLOR_V10314                    18 屬性 RGB
# TYPE_GLYPH_V10314                    徽章單字標記
#
# 【事件／腳本呼叫方式】
# 不需事件呼叫。只要既有 Game_PMDChessUnit 觸發 skill_popup_frames，
# Sprite_PMDChessUnit#update_skill_popup 就會自動使用屬性色底板。
#
# 【實際範例】
# Ember / 火花        -> Fire 橘紅底 +「火」徽章
# Water Gun / 水槍    -> Water 藍底   +「水」徽章
# Thunderbolt / 十萬伏特 -> Electric 黃底 +「電」徽章
# Vine Whip / 藤鞭    -> Grass 綠底   +「草」徽章
# 無法解析屬性的舊技能 -> Normal 灰橄欖底 +「普」徽章
#
# 【機制邊界】
# - 不修改 Damage / Accuracy / Type Effectiveness。
# - 不修改 AI / Attack Speed / Energy。
# - 不修改 unit logical x/y、velocity、Spatial Runtime。
# - 不修改 skill_popup_frames、action_timer 或技能施放時序。
# - 不新增 Bitmap/PNG live alpha scan；每次 popup 只畫既有 150x32 Bitmap。
#==============================================================================
module PMD_AC
  SKILL_TYPE_BANNER_BG_ALPHA_V10314     = 184
  SKILL_TYPE_BANNER_ACCENT_ALPHA_V10314 = 220
  SKILL_TYPE_BANNER_BADGE_ALPHA_V10314  = 235

  TYPE_COLOR_V10314 = {
    :normal   => [168,168,120],
    :fire     => [240,128,48],
    :water    => [104,144,240],
    :electric => [248,208,48],
    :grass    => [120,200,80],
    :ice      => [152,216,216],
    :fighting => [192,48,40],
    :poison   => [160,64,160],
    :ground   => [224,192,104],
    :flying   => [168,144,240],
    :psychic  => [248,88,136],
    :bug      => [168,184,32],
    :rock     => [184,160,56],
    :ghost    => [112,88,152],
    :dragon   => [112,56,248],
    :dark     => [112,88,72],
    :steel    => [184,184,208],
    :fairy    => [238,153,172]
  }

  TYPE_GLYPH_V10314 = {
    :normal=>'普', :fire=>'火', :water=>'水', :electric=>'電',
    :grass=>'草', :ice=>'冰', :fighting=>'格', :poison=>'毒',
    :ground=>'地', :flying=>'飛', :psychic=>'超', :bug=>'蟲',
    :rock=>'岩', :ghost=>'幽', :dragon=>'龍', :dark=>'惡',
    :steel=>'鋼', :fairy=>'妖'
  }

  LEGACY_SKILL_TYPE_V10314 = {
    :vine_drain=>:grass,
    :flame_burst=>:fire,
    :guardian_tide=>:water,
    :web_pierce=>:bug,
    :rending_assault=>:dark,
    :chain_lightning=>:electric,
    :frost_beam=>:ice,
    :water_lance=>:water,
    :fire_sweep=>:fire,
    :tidal_push=>:water,
    :dash_strike=>:normal,
    :healing_field=>:grass,
    :ricochet_seed=>:grass
  }

  class << self
    def skill_type_banner_valid_type_v10314(type)
      t=type
      t=t.to_sym if t.respond_to?(:to_sym)
      return :normal unless TYPE_COLOR_V10314.has_key?(t)
      t
    rescue
      :normal
    end

    def skill_type_banner_type_v10314(unit)
      return :normal if unit==nil
      data=nil
      begin
        data=unit.skill_data if unit.respond_to?(:skill_data)
      rescue
        data=nil
      end
      if data!=nil
        t=data[:move_type] || data[:type]
        return skill_type_banner_valid_type_v10314(t) if t!=nil
        ck=data[:canonical_move_key]
        if ck!=nil && respond_to?(:move_data)
          begin
            md=move_data(ck.is_a?(String) ? ck.to_sym : ck)
            if md!=nil
              t=md[:move_type] || md[:type]
              return skill_type_banner_valid_type_v10314(t) if t!=nil
            end
          rescue
          end
        end
      end
      key=nil
      begin
        key=unit.skill_type if unit.respond_to?(:skill_type)
      rescue
        key=nil
      end
      key=key.to_sym if key.respond_to?(:to_sym)
      t=LEGACY_SKILL_TYPE_V10314[key]
      return skill_type_banner_valid_type_v10314(t) if t!=nil
      :normal
    rescue
      :normal
    end

    def skill_type_banner_color_v10314(type,alpha=255)
      t=skill_type_banner_valid_type_v10314(type)
      rgb=TYPE_COLOR_V10314[t] || TYPE_COLOR_V10314[:normal]
      Color.new(rgb[0],rgb[1],rgb[2],alpha)
    end

    def skill_type_banner_light_color_v10314(type,alpha=255)
      t=skill_type_banner_valid_type_v10314(type)
      rgb=TYPE_COLOR_V10314[t] || TYPE_COLOR_V10314[:normal]
      r=[rgb[0]+46,255].min
      g=[rgb[1]+46,255].min
      b=[rgb[2]+46,255].min
      Color.new(r,g,b,alpha)
    end

    def skill_type_banner_dark_color_v10314(type,alpha=255)
      t=skill_type_banner_valid_type_v10314(type)
      rgb=TYPE_COLOR_V10314[t] || TYPE_COLOR_V10314[:normal]
      r=(rgb[0]*0.42).to_i
      g=(rgb[1]*0.42).to_i
      b=(rgb[2]*0.42).to_i
      Color.new(r,g,b,alpha)
    end
  end
end

class Sprite_PMDChessUnit
  # v0.86 是目前技能名稱 UI authority；本版只覆寫其繪圖內容，
  # frames / fade / Sprite position 完全沿用既有邏輯。
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
    badge=PMD_AC.skill_type_banner_color_v10314(type,PMD_AC::SKILL_TYPE_BANNER_BADGE_ALPHA_V10314)

    # 150x32 既有 popup 內建立「深框／屬性色／高光」三層底板。
    bmp.fill_rect(4,4,bmp.width-8,24,Color.new(0,0,0,150))
    bmp.fill_rect(5,5,bmp.width-10,22,edge)
    bmp.fill_rect(7,7,bmp.width-14,18,bg)
    bmp.fill_rect(8,7,bmp.width-16,2,accent)

    # 左側小型屬性徽章，結構參考 Pokémon type icon 的獨立色塊。
    bmp.fill_rect(7,6,24,20,Color.new(0,0,0,205))
    bmp.fill_rect(9,8,20,16,badge)
    bmp.fill_rect(10,8,18,2,accent)
    glyph=PMD_AC::TYPE_GLYPH_V10314[type] || '普'
    bmp.font.size=11
    bmp.font.bold=true
    bmp.font.color=Color.new(20,20,20,180)
    bmp.draw_text(10,8,18,16,glyph,1)
    bmp.font.color=Color.new(255,255,255,255)
    bmp.draw_text(9,7,18,16,glyph,1)

    # 技能名稱：深影 + 白字。亮底（Electric / Ice / Steel）與深底都保持可讀。
    bmp.font.size=PMD_AC::UI_SKILL_FONT_V086
    bmp.font.bold=true
    text=@unit.skill_name.to_s
    bmp.font.color=Color.new(0,0,0,205)
    bmp.draw_text(31,4,bmp.width-35,23,text,1)
    bmp.font.color=Color.new(255,255,255,255)
    bmp.draw_text(30,3,bmp.width-35,23,text,1)

    @skill_sprite.opacity=PMD_AC.clamp(frames*12,0,255)
  end
end

class Scene_PMD_AutoChess
  alias pmd_ac_v10314_skill_type_banner_start start unless method_defined?(:pmd_ac_v10314_skill_type_banner_start)
  def start
    pmd_ac_v10314_skill_type_banner_start
    begin
      log_event(:ui,
        'SKILL_TYPE_BANNER_V10314 ready=1 types=18 source=move_type,type,canonical,legacy' +
        ' palette=dp_reference badge=1 translucent=1 white_text=1' +
        ' popup_frames_unchanged=1 action_timer_unchanged=1 damage_unchanged=1' +
        ' ai_unchanged=1 attack_speed_unchanged=1 energy_unchanged=1 spatial_unchanged=1')
    rescue
    end
  end
end
