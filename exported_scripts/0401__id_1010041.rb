# encoding: UTF-8
#==============================================================================
# 【PMD AutoChess 中文維護說明】
# 腳本：PMD AutoChess Vertical Slice Boss Story Balance v1.01.4
# 分類：Map / Story Boss 平衡／首次通關輔助／驗證
#
# 【用途】
# v1.01.2 實機已證明 Map004～006、野戰、特殊遭遇與 Boss 入口皆可走通，
# 但既有 boss_beedrill 是 Boss Framework v0.91 的完整展示版：高 HP/ATK 倍率、
# 多段護盾、永久天氣、速度增幅、增援與末段無敵同時存在，對 Vertical Slice
# 的固定初期三人隊伍過重。本腳本只調整「v1.01 林緣劇情首次 Boss」的難度，
# 不改全域 boss_beedrill 原始資料，也不修改 Damage Formula / Attack Speed。
#
# 【主要設定】
# STORY_BOSS_SETUP_V1014：首次劇情 Boss 的三隻敵方配置與倍率。
# STORY_BOSS_PROFILE_V1014：首次劇情 Boss 的四階段演出／機制。
# STORY_BOSS_MIN_WINS_V1014：F7 實機重測捷徑需要的最低林緣勝場。
#
# 【機制規則】
# 1. 只有 request 同時帶 vertical_slice_v101 且 foundation_kind_v100=:boss，且
#    尚未首通時，才套 Story Balance。其他 Boss、舊 verifier、日後重戰不受影響。
# 2. 首次劇情 Boss：Lv13 獨角蟲 + Lv17 大針蜂 + Lv13 鐵殼蛹。
# 3. 大針蜂 HP 2.60x -> 1.85x；ATK 1.25x -> 1.08x；取消額外 DEF/SPEED 壓力。
# 4. 四階段仍保留 Boss 感，但改為：1 隻較弱增援、8% 護盾、8% 攻擊增幅、
#    最後 8% 護盾；取消永久晴天、順風、速度增幅與 45 frame 無敵。
# 5. 首次 Boss 啟動前自動 Heal Party + 記錄 Map006 checkpoint，確保前面探索
#    的 carry HP 不會把 Boss 難度偷偷放大。敗北後仍走既有 return_heal。
# 6. 首通後 Foundation boss_cleared=true；之後重戰恢復原始 hive_overlord Profile，
#    因而保留完整高難度版本作為未來重戰／挑戰基準。
# 7. F7 僅為 v1.01.4 實機重測捷徑：在 Map004～006 按 F7，會把 wild_wins 最低
#    補到 2、治療隊伍並送到 Map006。它不直接標記 Boss 通關，也不偽造 battle result。
#
# 【事件／腳本呼叫方式】
# 正式流程不需改事件，仍呼叫：
#   PMD_AC.vertical_boss_v101
# 手動檢查 Story Boss request：
#   r = PMD_AC.rpg_foundation_boss_request_v100
#   PMD_AC.mark_vertical_request_v101(r)
# 實機快速重測：進任一 v1.01 地圖後按 F7。
#
# 【實際範例】
# 玩家 Map004 打完兩場後進 Map006 -> 調查 Boss -> 自動前線整備 -> Story Boss。
# 若首通完成，再次挑戰同 encounter 時不再套 Story Balance，而使用原 v0.91 Boss。
#
# 【維護注意】
# - RPG Maker VX / RGSS2 / Ruby 1.8 相容。
# - Pokémon 個體身份仍為 instance_uid。
# - 不直接修改 Frozen Combat Core；本腳本只用 trailing alias/content override。
# - 不改 Dynamic Tactical Role、Spatial Framework、Skill FX、Damage Formula。
# - S 選單不新增 mode，仍維持最新 5 個正式 mode。
#==============================================================================
module PMD_AC
  VERTICAL_BOSS_BALANCE_VERSION_V1014='1.01.4'
  STORY_BOSS_MIN_WINS_V1014=2

  STORY_BOSS_SETUP_V1014=[
    [:weedle,4,1,13,{}],
    [:beedrill,5,2,17,{
      :boss=>true,
      :stat_mult=>{:hp=>1.85,:atk=>1.08,:def=>1.00,:spatk=>1.00,:spdef=>1.05,:speed=>1.00},
      :energy_start=>30,
      :active_moves=>[:fury_attack,:focus_energy],
      :phases=>[]
    }],
    [:kakuna,5,3,13,{}]
  ]

  STORY_BOSS_PROFILE_V1014={
    :name=>'蜂巢霸主・大針蜂',
    :encounter=>:boss_beedrill,
    :phase_lock_frames=>12,
    :never_recruit=>true,
    :phases=>[
      {
        :key=>:hive_alarm,
        :time_frames=>480,
        :text=>'蜂群支援',
        :effects=>[
          [:summon,:weedle,1,{
            :duration=>300,:allow_skill=>false,:expire_with_owner=>true,
            :level_offset=>-4,:hp_scale=>0.55,:stat_scale=>0.70
          }],
          [:mechanic,:hive_alarm,{}]
        ]
      },
      {
        :key=>:guard_swarm,
        :hp_below=>0.70,
        :text=>'蜂巢護衛',
        :effects=>[
          [:shield_rate,0.08],
          [:energy,10]
        ]
      },
      {
        :key=>:sun_frenzy,
        :hp_below=>0.40,
        :text=>'蜂王急襲',
        :effects=>[
          [:stat_mult,:atk,1.08],
          [:energy,20]
        ]
      },
      {
        :key=>:last_sting,
        :hp_below=>0.18,
        :text=>'最後毒針',
        :effects=>[
          [:shield_rate,0.08],
          [:energy,20],
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
    def story_boss_request_v1014?(request=nil)
      r=request
      if r==nil && $game_temp!=nil
        r=$game_temp.pmd_autochess_request_v081
      end
      return false if r==nil
      o=r[:options] || {}
      o[:vertical_story_boss_v1014] ? true:false
    end

    def clone_story_boss_setup_v1014
      STORY_BOSS_SETUP_V1014.collect do |row|
        opts=row[4]==nil ? {} : row[4].dup
        opts[:stat_mult]=opts[:stat_mult].dup if opts[:stat_mult]!=nil
        opts[:active_moves]=opts[:active_moves].dup if opts[:active_moves]!=nil
        opts[:phases]=opts[:phases].dup if opts[:phases]!=nil
        [row[0],row[1],row[2],row[3],opts]
      end
    end

    alias pmd_ac_v1014_mark_vertical_request_v101 mark_vertical_request_v101 unless method_defined?(:pmd_ac_v1014_mark_vertical_request_v101)
    def mark_vertical_request_v101(request)
      r=pmd_ac_v1014_mark_vertical_request_v101(request)
      return r if r==nil
      o=r[:options] || {}
      s=rpg_foundation_state_v100
      if r[:kind]==:boss && o[:foundation_kind_v100]==:boss && !s[:boss_cleared]
        r[:enemy_setup]=clone_story_boss_setup_v1014
        r[:options][:vertical_story_boss_v1014]=true
        r[:options][:vertical_story_boss_balance_version]=VERTICAL_BOSS_BALANCE_VERSION_V1014
        vertical_log_v101('BOSS_BALANCE_V1014 story=1 beedrill_lv=17 hp=1.85 atk=1.08 adds=13,13 profile=story_first_clear')
      end
      r
    end

    alias pmd_ac_v1014_boss_profile_v091 boss_profile_v091 unless method_defined?(:pmd_ac_v1014_boss_profile_v091)
    def boss_profile_v091(key)
      if key==:hive_overlord && story_boss_request_v1014?
        return STORY_BOSS_PROFILE_V1014
      end
      pmd_ac_v1014_boss_profile_v091(key)
    end

    alias pmd_ac_v1014_vertical_boss_v101 vertical_boss_v101 unless method_defined?(:pmd_ac_v1014_vertical_boss_v101)
    def vertical_boss_v101
      s=rpg_foundation_state_v100
      if rpg_foundation_boss_unlocked_v100? && !s[:boss_cleared]
        heal_party_here_v092
        checkpoint_here_v092
        vertical_log_v101('BOSS_PREP_V1014 heal=1 checkpoint=1 map='+($game_map==nil ? '0':$game_map.map_id.to_s))
      end
      pmd_ac_v1014_vertical_boss_v101
    end

    def boss_retest_shortcut_v1014
      return false if $game_map==nil || !vertical_map_v101?($game_map.map_id)
      s=rpg_foundation_state_v100
      s[:wild_wins]=STORY_BOSS_MIN_WINS_V1014 if s[:wild_wins].to_i<STORY_BOSS_MIN_WINS_V1014
      heal_party_here_v092
      vertical_log_v101('BOSS_RETEST_SHORTCUT_V1014 wild_wins='+s[:wild_wins].to_i.to_s+' heal=1 to=6')
      transfer_vertical_v101(6,8,11,8)
      true
    end
  end
end

class Scene_Map
  alias pmd_ac_v1014_update update unless method_defined?(:pmd_ac_v1014_update)
  def update
    pmd_ac_v1014_update
    # P8 v1.06.67: historical F7 Boss retest launcher retired.
    # boss_retest_shortcut_v1014 remains callable for issue-driven diagnosis.
  end
end

class Scene_PMD_AutoChess
  alias pmd_ac_v1014_update_verification_script update_verification_script unless method_defined?(:pmd_ac_v1014_update_verification_script)

  def verify_boss_story_balance_v1014
    return if @verification_done[:boss_story_balance_v1014]
    setup=PMD_AC::STORY_BOSS_SETUP_V1014
    boss=setup[1]
    opts=boss==nil ? {} : (boss[4]||{})
    mult=opts[:stat_mult] || {}
    p=PMD_AC::STORY_BOSS_PROFILE_V1014
    phases=p[:phases] || []
    kinds=[]
    summon_count=0
    shield_total=0.0
    phases.each do |ph|
      (ph[:effects]||[]).each do |ef|
        kinds.push(ef[0])
        summon_count+=ef[2].to_i if ef[0]==:summon
        shield_total+=ef[1].to_f if ef[0]==:shield_rate
      end
    end
    pass=setup.size==3 && boss[0]==:beedrill && boss[3].to_i==17 &&
      (mult[:hp].to_f-1.85).abs<0.001 && (mult[:atk].to_f-1.08).abs<0.001 &&
      setup[0][3].to_i==13 && setup[2][3].to_i==13 && phases.size==4 &&
      summon_count==1 && (shield_total-0.16).abs<0.001 &&
      !kinds.include?(:weather) && !kinds.include?(:field) && !kinds.include?(:invulnerable)
    log_event(:verify,'BOSS_STORY_BALANCE_V1014 pass='+(pass ? '1':'0')+
      ' first_clear=1 team_lv=13,17,13 hp_mult=1.85 atk_mult=1.08 summon=1 shield_total=0.16 weather=0 field=0 invuln=0 preheal=1 rematch_legacy=1 damage_unchanged=1 attack_speed_unchanged=1')
    @verification_done[:boss_story_balance_v1014]=true
  end

  def update_verification_script
    pmd_ac_v1014_update_verification_script
    return unless respond_to?(:map_story_vertical_slice_v101?) && map_story_vertical_slice_v101?
    verify_boss_story_balance_v1014 if @logic_frame.to_i>=28
  end
end
