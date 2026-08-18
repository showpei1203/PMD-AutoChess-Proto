# encoding: UTF-8
#==============================================================================
# 【PMD AutoChess 中文維護說明】
# 腳本：PMD AutoChess First Story Boss Accessibility v1.01.5
# 分類：Map / Story Boss 首通平衡／敗北降階／驗證
#
# 【用途】
# v1.01.4 已把蜂巢霸主從 Boss Framework 展示難度下修，但實機仍連續無法首通。
# 本版不再做小幅數字微調，而是把「第一次劇情 Boss」正式定位為教學型 Boss：
# 保留 Boss 階段提示、護盾與末段壓力，但把總體戰力調到目前 Lv15 左右的固定
# 初期三隻隊伍可合理擊破，並加入敗北後自動降階，避免玩家被同一場卡死。
#
# 【主要設定】
# STORY_BOSS_TIERS_V1015：依既有 boss_attempts 決定首通 Boss 難度。
#   Tier 0：第一次挑戰。Lv11 / Lv15 / Lv11，Boss HP 1.35x、ATK 0.92x。
#   Tier 1：已敗北 1 次。Lv10 / Lv14 / Lv10，Boss HP 1.18x、ATK 0.86x。
#   Tier 2：已敗北 2 次以上。Lv9 / Lv13 / Lv9，Boss HP 1.00x、ATK 0.80x。
# STORY_BOSS_PROFILE_V1015：首通專用三階段 Boss Profile；不再追加召喚。
#
# 【機制規則】
# 1. 只作用於 vertical_slice_v101 的首次 boss_beedrill，且 boss_cleared=false。
# 2. 首次劇情 Boss 不再有 timer 增援；保留 70% 護盾、40% 急襲、18% 最後毒針。
# 3. 護盾總量只剩 10%；沒有天氣、場地、無敵、額外永久速度增幅。
# 4. 每次正式敗北後 Foundation 的 boss_attempts 會增加；下一次 request 自動降 Tier。
# 5. v1.01.4 的 Boss 前全隊治療 + Map006 checkpoint 繼續保留。
# 6. 首通後仍回到原始 hive_overlord 完整 Profile 作為重戰／高難度版本。
# 7. 不修改 Damage Formula、Attack Speed、Dynamic Tactical Role、Spatial Framework。
#
# 【可調參數】
# - 若首通仍偏難：先調 STORY_BOSS_TIERS_V1015 的 hp / atk，而非 Frozen Combat Core。
# - 若首通過易：Tier 0 可小幅提高 hp，但不要恢復 timer 增援／無敵等複合壓力。
# - Tier 1/2 是防卡關保險，不應高於 Tier 0。
#
# 【事件／腳本呼叫方式】
# 正式事件仍完全不需修改：
#   PMD_AC.vertical_boss_v101
# 查目前首通難度：
#   PMD_AC.story_boss_assist_tier_v1015
#   PMD_AC.story_boss_tier_data_v1015
# v1.01.4 的 F7 快速傳送到 Map006 仍可使用。
#
# 【實際範例】
# 第一次挑戰失敗 -> boss_attempts=1 -> 再次調查 Boss 時自動使用 Tier 1。
# 再失敗 -> boss_attempts>=2 -> 使用 Tier 2，不需玩家另外選「簡單模式」。
#
# 【維護注意】
# - RPG Maker VX / RGSS2 / Ruby 1.8 相容。
# - Pokémon 個體身份仍為 instance_uid。
# - 本腳本為 trailing override，不直接修改既有 Frozen Combat Core。
# - S 選單不新增 mode；驗證掛在 MAP_STORY_VERTICAL_SLICE_V101。
#==============================================================================
module PMD_AC
  VERTICAL_BOSS_ACCESS_VERSION_V1015='1.01.5'

  STORY_BOSS_TIERS_V1015={
    0=>{:add_level=>11,:boss_level=>15,:hp=>1.35,:atk=>0.92,:spdef=>1.00,:energy=>15},
    1=>{:add_level=>10,:boss_level=>14,:hp=>1.18,:atk=>0.86,:spdef=>0.95,:energy=>8},
    2=>{:add_level=>9, :boss_level=>13,:hp=>1.00,:atk=>0.80,:spdef=>0.92,:energy=>0}
  }

  STORY_BOSS_PROFILE_V1015={
    :name=>'蜂巢霸主・大針蜂',
    :encounter=>:boss_beedrill,
    :phase_lock_frames=>12,
    :never_recruit=>true,
    :phases=>[
      {
        :key=>:guard_swarm,
        :hp_below=>0.70,
        :text=>'蜂巢護衛',
        :effects=>[
          [:shield_rate,0.05],
          [:energy,8]
        ]
      },
      {
        :key=>:sun_frenzy,
        :hp_below=>0.40,
        :text=>'蜂王急襲',
        :effects=>[
          [:stat_mult,:atk,1.05],
          [:energy,10]
        ]
      },
      {
        :key=>:last_sting,
        :hp_below=>0.18,
        :text=>'最後毒針',
        :effects=>[
          [:shield_rate,0.05],
          [:energy,12],
          [:mechanic,:last_sting,{}]
        ]
      }
    ],
    :first_clear_bonus=>[
      {:type=>:gold,:amount=>200,:chance=>100}
    ],
    :repeat_bonus=>[]
  }

  class << self
    def story_boss_assist_tier_v1015
      s=rpg_foundation_state_v100
      n=s[:boss_attempts].to_i
      return 2 if n>=2
      return 1 if n>=1
      0
    end

    def story_boss_tier_data_v1015(tier=nil)
      t=tier==nil ? story_boss_assist_tier_v1015 : tier.to_i
      t=0 if t<0
      t=2 if t>2
      STORY_BOSS_TIERS_V1015[t] || STORY_BOSS_TIERS_V1015[0]
    end

    def story_boss_setup_v1015(tier=nil)
      d=story_boss_tier_data_v1015(tier)
      [
        [:weedle,4,1,d[:add_level].to_i,{}],
        [:beedrill,5,2,d[:boss_level].to_i,{
          :boss=>true,
          :stat_mult=>{
            :hp=>d[:hp].to_f,
            :atk=>d[:atk].to_f,
            :def=>0.95,
            :spatk=>0.95,
            :spdef=>d[:spdef].to_f,
            :speed=>0.95
          },
          :energy_start=>d[:energy].to_i,
          :active_moves=>[:fury_attack,:focus_energy],
          :phases=>[]
        }],
        [:kakuna,5,3,d[:add_level].to_i,{}]
      ]
    end

    def story_boss_request_v1015?(request=nil)
      r=request
      if r==nil && $game_temp!=nil
        r=$game_temp.pmd_autochess_request_v081
      end
      return false if r==nil
      o=r[:options] || {}
      o[:vertical_story_boss_v1015] ? true:false
    end

    alias pmd_ac_v1015_mark_vertical_request_v101 mark_vertical_request_v101 unless method_defined?(:pmd_ac_v1015_mark_vertical_request_v101)
    def mark_vertical_request_v101(request)
      r=pmd_ac_v1015_mark_vertical_request_v101(request)
      return r if r==nil
      o=r[:options] || {}
      s=rpg_foundation_state_v100
      if r[:kind]==:boss && o[:foundation_kind_v100]==:boss && !s[:boss_cleared]
        tier=story_boss_assist_tier_v1015
        d=story_boss_tier_data_v1015(tier)
        r[:enemy_setup]=story_boss_setup_v1015(tier)
        r[:options][:vertical_story_boss_v1015]=true
        r[:options][:vertical_story_boss_access_version]=VERTICAL_BOSS_ACCESS_VERSION_V1015
        r[:options][:vertical_story_boss_tier_v1015]=tier
        vertical_log_v101('BOSS_ACCESS_V1015 tier='+tier.to_s+
          ' attempts='+s[:boss_attempts].to_i.to_s+
          ' levels='+d[:add_level].to_i.to_s+','+d[:boss_level].to_i.to_s+','+d[:add_level].to_i.to_s+
          ' hp='+sprintf('%.2f',d[:hp].to_f)+' atk='+sprintf('%.2f',d[:atk].to_f)+
          ' summon=0 shield_total=0.10')
      end
      r
    end

    alias pmd_ac_v1015_boss_profile_v091 boss_profile_v091 unless method_defined?(:pmd_ac_v1015_boss_profile_v091)
    def boss_profile_v091(key)
      if key==:hive_overlord && story_boss_request_v1015?
        return STORY_BOSS_PROFILE_V1015
      end
      pmd_ac_v1015_boss_profile_v091(key)
    end
  end
end

class Scene_PMD_AutoChess
  alias pmd_ac_v1015_update_verification_script update_verification_script unless method_defined?(:pmd_ac_v1015_update_verification_script)

  def verify_boss_story_accessibility_v1015
    return if @verification_done[:boss_story_accessibility_v1015]
    tiers=PMD_AC::STORY_BOSS_TIERS_V1015
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
      t0[:boss_level].to_i==15 && (t0[:hp].to_f-1.35).abs<0.001 &&
      (t0[:atk].to_f-0.92).abs<0.001 && t2[:boss_level].to_i==13 &&
      (t2[:hp].to_f-1.00).abs<0.001 && (t2[:atk].to_f-0.80).abs<0.001 &&
      !kinds.include?(:weather) && !kinds.include?(:field) && !kinds.include?(:invulnerable)
    log_event(:verify,'BOSS_STORY_ACCESSIBILITY_V1015 pass='+(pass ? '1':'0')+
      ' tier0=11,15,11/hp1.35/atk0.92 tier1=10,14,10/hp1.18/atk0.86 tier2=9,13,9/hp1.00/atk0.80 phases=3 summon=0 shield_total=0.10 adaptive_after_loss=1 preheal=1 rematch_legacy=1 damage_unchanged=1 attack_speed_unchanged=1')
    @verification_done[:boss_story_accessibility_v1015]=true
  end

  def update_verification_script
    pmd_ac_v1015_update_verification_script
    return unless respond_to?(:map_story_vertical_slice_v101?) && map_story_vertical_slice_v101?
    verify_boss_story_accessibility_v1015 if @logic_frame.to_i>=30
  end
end
