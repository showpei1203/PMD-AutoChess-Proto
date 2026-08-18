# encoding: UTF-8
#==============================================================================
# PMD AutoChess Battle Flow + Combat Readability Data v0.88
# 戰鬥防無限追逐／被動蓄力／戰場提示資料
# RPG Maker VX / RGSS2 / Ruby 1.8 compatible
#==============================================================================
# 【這支腳本是做什麼的】
# v0.87.1 已經把「正常走位造成的近戰空揮」壓低，但實戰第二場仍出現另一種
# 無限循環：Artillery / Kiter 被近戰壓在 v0.75 ENGAGED 狀態後，舊平衡層會
# 持續禁止遠程攻擊，若雙方速度接近，就可能永遠無法拉到 RELEASE 124px。
#
# 本版不重寫 v0.15 移動核心，而加兩道保險：
# 1. 所有存活寶可夢在正常實戰中會「隨時間緩慢蓄力」。
# 2. 遠程若被近戰連續貼住太久，允許一次「受壓反擊」，之後仍回到原本的
#    ENGAGED / RELEASE / REARM 規則，保留放風箏的戰術特色。
#
# 同時依使用者要求整理戰場文字：
# - 寶可夢頭上只保留「招式名」與「+狀態 / -狀態」的短暫提示。
# - Threat / AI / 常駐 Status Debug 不再顯示。
# - 天氣／場地開始時改成畫面正中央提示，停留後淡出。
# - 傷害數字採用專案內 Tankentai SBS「Sprite_Damage#move_damage」的
#   上拋 → 下落 → 小幅回彈節奏，不再只是固定黏在角色頭上。
#------------------------------------------------------------------------------
# 【最常調整的參數】
# PASSIVE_ENERGY_INTERVAL_V088 = 30
#   每 30 畫面幀進行一次時間蓄力判定，約 0.5 秒（60fps）。
# PASSIVE_ENERGY_GAIN_V088 = 2
#   每次 +2 Energy，約每秒 +4。從 0 到 100 約 25 秒。
#
# RANGED_STALL_BREAK_FRAMES_V088 = 180
#   遠程連續被近戰壓住約 3 秒後，允許一次基本攻擊反擊。
#   這不是永久取消 v0.75 的遠程撤退規則。
#
# STATUS_NOTICE_FRAMES_V088 = 36
#   +狀態 / -狀態 每筆顯示約 0.6 秒。
#
# CENTER_NOTICE_FRAMES_V088 = 90
# CENTER_NOTICE_FADE_FRAMES_V088 = 30
#   天氣／場地中央提示總長約 1.5 秒，最後 0.5 秒淡出。
#------------------------------------------------------------------------------
# 【調整範例】
# 想讓技能更常出現：
#   PASSIVE_ENERGY_GAIN_V088 = 3
# 想讓遠程更久才反擊：
#   RANGED_STALL_BREAK_FRAMES_V088 = 240
# 想讓中央天氣文字快一點消失：
#   CENTER_NOTICE_FRAMES_V088 = 72
#------------------------------------------------------------------------------
# 【不修改的系統】
# - v0.15 移動與基本 AI 核心
# - v0.75 Engage 102 / Release 124 / Rearm 30 / 撤退速度
# - v0.87.1 Accuracy / Active Evade / Projectile Tracking
# - v0.60.2 多段傷害封包
# - v0.62 Native Semantic Router
# - 傷害、暴擊、屬性、方向傷害公式
#==============================================================================
module PMD_AC
  PASSIVE_ENERGY_INTERVAL_V088 = 30
  PASSIVE_ENERGY_GAIN_V088 = 2
  RANGED_STALL_BREAK_FRAMES_V088 = 180

  STATUS_NOTICE_FRAMES_V088 = 36
  STATUS_NOTICE_QUEUE_MAX_V088 = 4
  STATUS_NOTICE_W_V088 = 150
  STATUS_NOTICE_H_V088 = 24
  STATUS_NOTICE_FONT_V088 = 14

  CENTER_NOTICE_FRAMES_V088 = 90
  CENTER_NOTICE_FADE_FRAMES_V088 = 30
  CENTER_NOTICE_W_V088 = 360
  CENTER_NOTICE_H_V088 = 44
  CENTER_NOTICE_FONT_V088 = 22

  SBS_DAMAGE_POPUP_W_V088 = 104
  SBS_DAMAGE_POPUP_H_V088 = 40
  SBS_DAMAGE_FONT_V088 = 16
  SBS_DAMAGE_CRIT_FONT_V088 = 13

  # def_aura 是每 36f 重複刷新的內部 Aura，若照一般狀態顯示會一直洗版。
  STATUS_NOTICE_IGNORE_V088 = [:def_aura]

  STATUS_NOTICE_LABELS_V088 = {
    :poison=>'中毒', :burn=>'灼傷', :regen=>'再生',
    :slow=>'移速下降', :move_slow=>'移速下降',
    :attack_slow=>'攻速下降', :action_slow=>'行動變慢',
    :root=>'定身', :silence=>'沉默', :fear=>'恐懼',
    :atk_down=>'攻擊下降', :def_down=>'防禦下降',
    :atk_up=>'攻擊提升', :def_up=>'防禦提升',
    :energy_lock=>'封鎖蓄力',
    :sleep=>'睡眠', :freeze=>'冰凍', :confusion=>'混亂',
    :paralysis=>'麻痺', :bound_v052=>'束縛', :curse_v053=>'詛咒',
    :fire_trap_v051=>'火焰束縛', :foresight_v052=>'識破',
    :stun=>'暈眩', :taunt=>'挑釁'
  }

  STAT_NOTICE_LABELS_V088 = {
    :atk=>'攻擊', :def=>'防禦', :spatk=>'特攻', :spdef=>'特防',
    :speed=>'速度', :accuracy=>'命中', :evasion=>'閃避'
  }

  WEATHER_NOTICE_LABELS_V088 = {
    :rain=>'下雨', :sun=>'大晴天', :sandstorm=>'沙暴', :hail=>'冰雹'
  }

  BATTLE_FLOW_MANIFEST_V088 = {
    :version=>'0.88',
    :passive_energy_interval=>PASSIVE_ENERGY_INTERVAL_V088,
    :passive_energy_gain=>PASSIVE_ENERGY_GAIN_V088,
    :ranged_stall_break=>RANGED_STALL_BREAK_FRAMES_V088,
    :head_text=>[:skill,:status_delta],
    :center_notice=>[:weather,:field],
    :damage_motion=>:tankentai_sbs_move_damage_reference,
    :movement_core=>'v0.15_unchanged',
    :ranged_balance=>'v0.75_preserved_with_stall_counterfire',
    :accuracy=>'v0.87.1_unchanged',
    :damage=>'unchanged'
  }

  def self.status_notice_label_v088(key)
    label=STATUS_NOTICE_LABELS_V088[key]
    return label unless label==nil
    key.to_s.gsub('_',' ')
  end

  def self.stat_notice_label_v088(key)
    STAT_NOTICE_LABELS_V088[key] || key.to_s
  end

  def self.weather_notice_label_v088(key)
    WEATHER_NOTICE_LABELS_V088[key] || key.to_s
  end

  def self.field_notice_label_v088(text)
    s=text.to_s
    return nil if s=='' || s.index(' END')!=nil
    return nil if s.index('REFRESH ')==0
    FIELD_EFFECT_VISUAL_V035.each do |key,data|
      label=(data[:label] || '').to_s
      if label==s
        move=FIELD_EFFECT_MOVE_V035[key]
        return move==nil ? s : (move[:name] || s).to_s
      end
    end
    s
  end
end
