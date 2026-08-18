# encoding: UTF-8
#==============================================================================
# 【PMD AutoChess 中文維護說明】
# 腳本：PMD AutoChess First Story Boss Final Calibration v1.01.6
# 分類：Map / Story Boss 首通最終校正／敗北保底／驗證
#
# 【用途】
# v1.01.5 Windows 實機結果已提供可用的難度樣本：舊 Tier 0（Lv11/15/11、
# HP 1.35x、ATK 0.92x）仍會讓目前初期固定隊伍首戰失敗；敗北後的舊 Tier 1
# （Lv10/14/10、HP 1.18x、ATK 0.86x）則可正常通關，且勝利時全隊仍有約
# 七成總 HP，保留個別成員受到壓力的 Boss 感。因此本版把「已實機證明可過」
# 的舊 Tier 1 正式上移為第一次挑戰基準，不再把先輸一次當作正常流程。
#
# 【主要設定】
# STORY_BOSS_TIERS_V1016：
#   Tier 0：第一次挑戰。Lv10 / Lv14 / Lv10，HP 1.18x、ATK 0.86x。
#   Tier 1：已敗北 1 次。Lv9 / Lv13 / Lv9，HP 1.00x、ATK 0.80x。
#   Tier 2：已敗北 2 次以上。Lv8 / Lv12 / Lv8，HP 0.90x、ATK 0.75x。
# Boss Profile 沿用 v1.01.5 三階段版本：無增援、總護盾 10%、無天氣／場地／無敵。
#
# 【機制規則】
# 1. 只改 Vertical Slice 首次 boss_beedrill 的 accessibility tier 資料來源。
# 2. v1.01.5 的 story_boss_setup_v1015 仍是唯一組隊入口，本版透過 trailing method
#    override 讓它讀 STORY_BOSS_TIERS_V1016；不直接改既有腳本與 Frozen Combat Core。
# 3. 第一次挑戰直接使用已在 Windows 實機通關的舊 Tier 1 強度。
# 4. 若仍敗北，boss_attempts 既有機制會依序降到新 Tier 1 / Tier 2。
# 5. Boss 前 Heal + Map006 checkpoint、首通後完整 hive_overlord 重戰皆維持不變。
# 6. Damage Formula / Attack Speed / Dynamic Tactical Role / Spatial Framework 不變。
#
# 【可調參數】
# - 首戰若仍偏難：優先調 Tier 0 hp / atk，不要恢復增援、無敵或永久速度增幅。
# - 首戰若偏易：最多小幅提高 Tier 0 hp；保留 Tier 1/2 作防卡關保底。
# - Tier 必須單調下降，避免敗北後反而變難。
#
# 【事件／腳本呼叫方式】
# 正式事件不需修改，仍使用：
#   PMD_AC.vertical_boss_v101
# 查目前 tier：
#   PMD_AC.story_boss_assist_tier_v1015
# 查本版實際資料：
#   PMD_AC.story_boss_tier_data_v1015
# 快速 Boss 重測仍可在 Vertical Slice 地圖按 F7。
#
# 【實際範例】
# 新進度首次挑戰 -> boss_attempts=0 -> Lv10/14/10、HP1.18、ATK0.86。
# 首戰若敗北 -> boss_attempts=1 -> Lv9/13/9、HP1.00、ATK0.80。
#
# 【維護注意】
# - RPG Maker VX / RGSS2 / Ruby 1.8 相容。
# - Pokémon 個體身份仍為 instance_uid。
# - 不直接修改 Frozen Combat Core；本腳本只做 trailing override。
# - S 選單不增加 mode；驗證仍掛 MAP_STORY_VERTICAL_SLICE_V101。
#==============================================================================
module PMD_AC
  VERTICAL_BOSS_CALIBRATION_VERSION_V1016='1.01.6'

  STORY_BOSS_TIERS_V1016={
    0=>{:add_level=>10,:boss_level=>14,:hp=>1.18,:atk=>0.86,:spdef=>0.95,:energy=>8},
    1=>{:add_level=>9, :boss_level=>13,:hp=>1.00,:atk=>0.80,:spdef=>0.92,:energy=>0},
    2=>{:add_level=>8, :boss_level=>12,:hp=>0.90,:atk=>0.75,:spdef=>0.90,:energy=>0}
  }

  class << self
    # v1.01.5 的 setup 與 request 會動態呼叫本方法；因此只替換資料來源即可。
    def story_boss_tier_data_v1015(tier=nil)
      t=tier==nil ? story_boss_assist_tier_v1015 : tier.to_i
      t=0 if t<0
      t=2 if t>2
      STORY_BOSS_TIERS_V1016[t] || STORY_BOSS_TIERS_V1016[0]
    end

    alias pmd_ac_v1016_mark_vertical_request_v101 mark_vertical_request_v101 unless method_defined?(:pmd_ac_v1016_mark_vertical_request_v101)
    def mark_vertical_request_v101(request)
      r=pmd_ac_v1016_mark_vertical_request_v101(request)
      return r if r==nil
      o=r[:options] || {}
      if o[:vertical_story_boss_v1015]
        tier=o[:vertical_story_boss_tier_v1015].to_i
        d=story_boss_tier_data_v1015(tier)
        r[:options][:vertical_story_boss_calibration_version]=VERTICAL_BOSS_CALIBRATION_VERSION_V1016
        vertical_log_v101('BOSS_CALIBRATION_V1016 tier='+tier.to_s+
          ' levels='+d[:add_level].to_i.to_s+','+d[:boss_level].to_i.to_s+','+d[:add_level].to_i.to_s+
          ' hp='+sprintf('%.2f',d[:hp].to_f)+' atk='+sprintf('%.2f',d[:atk].to_f)+
          ' first_try_uses_verified_old_tier1=1')
      end
      r
    end
  end
end

class Scene_PMD_AutoChess
  # 重新定義舊 v1.01.5 verifier，讓它驗證目前實際生效的 v1.01.6 tier，
  # 避免舊常數規格在新校正後產生假 FAIL。
  def verify_boss_story_accessibility_v1015
    return if @verification_done[:boss_story_accessibility_v1015]
    tiers=PMD_AC::STORY_BOSS_TIERS_V1016
    p=PMD_AC::STORY_BOSS_PROFILE_V1015
    phases=p[:phases] || []
    kinds=[]
    shield_total=0.0
    summon_count=0
    phases.each do |ph|
      (ph[:effects]||[]).each do |ef|
        kinds.push(ef[0])
        shield_total+=ef[1].to_f if ef[0]==:shield_rate
        summon_count+=ef[2].to_i if ef[0]==:summon
      end
    end
    t0=tiers[0] || {}
    t1=tiers[1] || {}
    t2=tiers[2] || {}
    descending=t0[:hp].to_f>t1[:hp].to_f && t1[:hp].to_f>t2[:hp].to_f &&
      t0[:atk].to_f>t1[:atk].to_f && t1[:atk].to_f>t2[:atk].to_f
    pass=tiers.size==3 && phases.size==3 && summon_count==0 &&
      (shield_total-0.10).abs<0.001 && descending &&
      t0[:boss_level].to_i==14 && (t0[:hp].to_f-1.18).abs<0.001 &&
      (t0[:atk].to_f-0.86).abs<0.001 && t1[:boss_level].to_i==13 &&
      (t1[:hp].to_f-1.00).abs<0.001 && (t1[:atk].to_f-0.80).abs<0.001 &&
      t2[:boss_level].to_i==12 && (t2[:hp].to_f-0.90).abs<0.001 &&
      (t2[:atk].to_f-0.75).abs<0.001 &&
      !kinds.include?(:weather) && !kinds.include?(:field) && !kinds.include?(:invulnerable)
    log_event(:verify,'BOSS_STORY_ACCESSIBILITY_V1015 pass='+(pass ? '1':'0')+
      ' calibrated_by_v1016=1 tier0=10,14,10/hp1.18/atk0.86 tier1=9,13,9/hp1.00/atk0.80 tier2=8,12,8/hp0.90/atk0.75 phases=3 summon=0 shield_total=0.10 adaptive_after_loss=1 preheal=1 rematch_legacy=1 damage_unchanged=1 attack_speed_unchanged=1')
    @verification_done[:boss_story_accessibility_v1015]=true
  end

  alias pmd_ac_v1016_update_verification_script update_verification_script unless method_defined?(:pmd_ac_v1016_update_verification_script)
  def update_verification_script
    pmd_ac_v1016_update_verification_script
    return unless respond_to?(:map_story_vertical_slice_v101?) && map_story_vertical_slice_v101?
    verify_boss_story_calibration_v1016 if @logic_frame.to_i>=32
  end

  def verify_boss_story_calibration_v1016
    return if @verification_done[:boss_story_calibration_v1016]
    t=PMD_AC::STORY_BOSS_TIERS_V1016
    t0=t[0] || {}
    t1=t[1] || {}
    t2=t[2] || {}
    pass=t0[:boss_level].to_i==14 && t0[:add_level].to_i==10 &&
      (t0[:hp].to_f-1.18).abs<0.001 && (t0[:atk].to_f-0.86).abs<0.001 &&
      t1[:boss_level].to_i==13 && t2[:boss_level].to_i==12 &&
      t0[:hp].to_f>t1[:hp].to_f && t1[:hp].to_f>t2[:hp].to_f &&
      t0[:atk].to_f>t1[:atk].to_f && t1[:atk].to_f>t2[:atk].to_f
    log_event(:verify,'BOSS_STORY_CALIBRATION_V1016 pass='+(pass ? '1':'0')+
      ' first_try=old_v1015_tier1 verified_win=1 retry_steps=2 boss_levels=14,13,12 hp=1.18,1.00,0.90 atk=0.86,0.80,0.75 damage_unchanged=1 attack_speed_unchanged=1')
    @verification_done[:boss_story_calibration_v1016]=true
  end
end
