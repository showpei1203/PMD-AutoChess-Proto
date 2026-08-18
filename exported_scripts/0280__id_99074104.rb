#==============================================================================
# 【PMD AutoChess 中文維護說明】
# 腳本：PMD AutoChess Balance Data v0.75
# 分類：近遠程平衡
#
# 【用途／機制】
# 處理 ENGAGED／SEPARATE／REARM、撤退速度與近戰短期追擊黏性。
#
# 【怎麼調整】
# 範例：想讓遠程更難脫離，可提高 release distance 或 rearm frames；不要直接砍所有遠程傷害。
#
# 【本腳本主要設定常數／資料表】
# - BALANCE_VERSION_V075 / RANGED_ENGAGE_RANGE_V075 / RANGED_RELEASE_RANGE_V075 / RANGED_REARM_FRAMES_V075
# - RANGED_RETREAT_SPEED_MULT_V075 / MELEE_PURSUIT_MULT_V075 / MELEE_PURSUIT_RANGE_V075 / RANGED_BALANCE_POLICIES_V075
# - BALANCE_MANIFEST_V075
#
# 【PMD_AC 對外／共用方法】
# - validate_balance_v075 / balance_checksum32_v075
#
# 【Runtime 主要方法（查流程時可直接搜尋）】
# - self
#
# 【維護規則】
# - RPG Maker VX / RGSS2 / Ruby 1.8 相容。
# - instance_uid 才是 Pokémon 個體身份；Actor ID 只是容器。
# - 新增行為優先沿用既有 helper／Data 表；避免破壞已 Freeze 的舊核心。
# - 本專案新腳本也必須保留同等級的中文說明與實際範例。
#==============================================================================
#==============================================================================
# PMD AutoChess Balance Data v0.75
# Battle Balance + Presentation Freeze
# RGSS2 / Ruby 1.8 compatible
#==============================================================================
module PMD_AC
  BALANCE_VERSION_V075 = '0.75'
  RANGED_ENGAGE_RANGE_V075 = 102.0
  RANGED_RELEASE_RANGE_V075 = 124.0
  RANGED_REARM_FRAMES_V075 = 30
  RANGED_RETREAT_SPEED_MULT_V075 = 0.82
  MELEE_PURSUIT_MULT_V075 = 1.08
  MELEE_PURSUIT_RANGE_V075 = 132.0
  RANGED_BALANCE_POLICIES_V075 = [:kiter,:artillery,:controller]

  BALANCE_MANIFEST_V075 = {
    :movement_core => 'v0.15_unchanged',
    :basic_target => 'v0.15_unchanged',
    :skill_target => 'v0.69_unchanged',
    :threat => 'v0.70_hysteresis',
    :intent => 'v0.71_24f',
    :prediction => 'v0.72',
    :weather_mechanics => 'v0.28_unchanged',
    :field => 'v0.35-v0.37_unchanged',
    :weather_visual => 'v0.74.3_Spriteset_Weather+v0.29_overlay',
    :ui => 'v0.74.1-v0.74.2_frozen',
    :damage_packet => 'v0.60.2_unchanged',
    :native_router => 'v0.62_unchanged',
    :range_damage => 'unchanged'
  }

  def self.validate_balance_v075
    e=[]
    e.push('engage_range') unless RANGED_ENGAGE_RANGE_V075 >= THREAT_PRESSURE_RANGE
    e.push('release_range') unless RANGED_RELEASE_RANGE_V075 > RANGED_ENGAGE_RANGE_V075
    e.push('rearm') unless RANGED_REARM_FRAMES_V075 > 0
    e.push('retreat_speed') unless RANGED_RETREAT_SPEED_MULT_V075 > 0.5 && RANGED_RETREAT_SPEED_MULT_V075 < 1.0
    e.push('pursuit') unless MELEE_PURSUIT_MULT_V075 > 1.0 && MELEE_PURSUIT_MULT_V075 <= 1.15
    e.push('weather_rain') unless const_defined?('WEATHER_CORE_RAIN_TYPE_V0743') && WEATHER_CORE_RAIN_TYPE_V0743==1
    e.push('weather_hail') unless const_defined?('WEATHER_CORE_HAIL_VISUAL_TYPE_V0743') && WEATHER_CORE_HAIL_VISUAL_TYPE_V0743==3
    e.push('foot_bar') unless const_defined?('FOOT_BAR_OFFSET_Y_V0742') && FOOT_BAR_OFFSET_Y_V0742==-4
    e
  end

  def self.balance_checksum32_v075
    s=[RANGED_ENGAGE_RANGE_V075,RANGED_RELEASE_RANGE_V075,RANGED_REARM_FRAMES_V075,
       RANGED_RETREAT_SPEED_MULT_V075,MELEE_PURSUIT_MULT_V075,MELEE_PURSUIT_RANGE_V075,
       BALANCE_MANIFEST_V075.keys.sort{|a,b|a.to_s<=>b.to_s}.map{|k|k.to_s+'='+BALANCE_MANIFEST_V075[k].to_s}.join('|')].join('|')
    n=0
    s.each_byte{|b| n=((n*131)+b)&0x7fffffff}
    n
  end
end
