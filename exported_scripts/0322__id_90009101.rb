# encoding: UTF-8
#==============================================================================
# 【PMD AutoChess 中文維護說明】
# 腳本：PMD AutoChess Boss Framework Data v0.91
# 分類：Boss Profile／Phase Data
#
# 【用途】
# v0.81 已有 Boss 倍率與單純 HP Phase；v0.91 把 Boss 戰提升成可重用的資料框架。
# 本腳本只放資料與純判定 Helper，不直接改戰鬥流程。
#
# 【核心規則】
# - Boss Encounter 先由 BOSS_ENCOUNTER_PROFILE_V091 對應 Boss Profile。
# - 每個 Profile 可放任意數量 phases，Phase 可用 HP 比例、戰鬥時間或兩者觸發。
# - Phase effects 採資料化序列，由 Runtime v0.91 執行。
# - Boss 一律不可招募；v0.81 的既有規則仍保留作為第一層保護。
# - 同一 Boss 每次戰鬥只執行一次同 key Phase。
# - Phase 預設有短暫 lock，避免一次大傷害跨多段時所有 Phase 同幀爆出。
#
# 【支援的 Phase Effect】
#   [:shield_rate, 0.20]                 # 依 Boss MaxHP 加盾
#   [:shield_flat, 200]                  # 固定護盾
#   [:heal_rate, 0.10]                   # 回復 MaxHP 10%
#   [:energy, 30]                        # 補 Energy
#   [:stat_mult, :atk, 1.15]             # 永久乘算 Boss Runtime stat
#   [:weather, :sun, 99, true]           # Weather；turns / permanent
#   [:field, :tailwind, 4]               # v0.35 Field Effect
#   [:summon, :weedle, 2, {...}]         # 召喚增援；不計入勝利條件
#   [:invulnerable, 45]                  # 45 logic frames 傷害無效
#   [:mechanic, :hive_alarm, {...}]       # 呼叫自訂 Phase Hook
#
# 【Phase Trigger】
#   {:hp_below=>0.70}                    # HP <= 70%
#   {:time_frames=>360}                  # 戰鬥 logic frame >= 360
#   同時存在時預設 :trigger_mode=>:all；也可指定 :any。
#
# 【Boss 首通獎勵】
# Profile 的 :first_clear_bonus / :repeat_bonus 使用 v0.83 Reward Row 格式。
# 這是「額外獎勵」，既有 Encounter Reward Table 仍會照常發放。
# 例如 boss_beedrill 原本固定 300G；本版首通再 +200G，首通合計 500G。
#
# 【新增 Boss 範例】
# 1. 在 RPG_ENCOUNTER_DB_V081 建 Encounter（或用自訂 Boss API）。
# 2. 在 BOSS_ENCOUNTER_PROFILE_V091 加：
#      :my_boss_encounter=>:my_boss_profile
# 3. 在 BOSS_PROFILES_V091 增加 :my_boss_profile。
# 4. 事件仍可直接：PMD_AC.start_battle_v081(:my_boss_encounter)
#
# 【注意事項】
# - RGSS2 / Ruby 1.8 相容。
# - 不使用專案禁用的舊式 instance variable probe。
# - Boss 增援使用 Pokémon Instance，但 configure_as_summon 後不計勝敗、不進招募。
# - 本腳本插在 Main 前，不修改 v0.90 舊 Script entries。
#==============================================================================
module PMD_AC
  BOSS_FRAMEWORK_VERSION_V091 = '0.91'

  BOSS_ENCOUNTER_PROFILE_V091 = {
    :boss_beedrill=>:hive_overlord
  }

  BOSS_ADD_OFFSETS_V091 = [
    [-54,-24],[-54,24],[-78,0],[48,-32],[48,32],[72,0]
  ]

  BOSS_EFFECT_TYPES_V091 = [
    :shield_rate,:shield_flat,:heal_rate,:energy,:stat_mult,
    :weather,:field,:summon,:invulnerable,:mechanic
  ]

  BOSS_PROFILES_V091 = {
    :hive_overlord=>{
      :name=>'蜂巢霸主・大針蜂',
      :encounter=>:boss_beedrill,
      :phase_lock_frames=>12,
      :never_recruit=>true,
      :phases=>[
        {
          :key=>:hive_alarm,
          :time_frames=>360,
          :text=>'蜂群支援',
          :effects=>[
            [:summon,:weedle,2,{
              :duration=>420,:allow_skill=>false,:expire_with_owner=>true,
              :level_offset=>-3,:hp_scale=>0.75,:stat_scale=>0.80
            }],
            [:mechanic,:hive_alarm,{}]
          ]
        },
        {
          :key=>:guard_swarm,
          :hp_below=>0.70,
          :text=>'蜂巢護衛',
          :effects=>[
            [:shield_rate,0.15],
            [:field,:tailwind,4],
            [:energy,20]
          ]
        },
        {
          :key=>:sun_frenzy,
          :hp_below=>0.45,
          :text=>'烈日狂舞',
          :effects=>[
            [:weather,:sun,99,true],
            [:stat_mult,:atk,1.15],
            [:stat_mult,:speed,1.12],
            [:energy,30]
          ]
        },
        {
          :key=>:last_sting,
          :hp_below=>0.20,
          :text=>'最後毒針',
          :effects=>[
            [:invulnerable,45],
            [:shield_rate,0.20],
            [:energy,45],
            [:mechanic,:last_sting,{}]
          ]
        }
      ],
      # v0.83 boss_beedrill 固定 300G；首通額外 +200G。
      :first_clear_bonus=>[
        {:type=>:gold,:amount=>200,:chance=>100}
      ],
      :repeat_bonus=>[]
    }
  }

  BOSS_FRAMEWORK_VERIFY_END_V091 = 30
  BOSS_FRAMEWORK_MANIFEST_V091 = {
    :schema_version=>'1.0',
    :content_version=>'0.91.0',
    :profiles=>BOSS_PROFILES_V091.size,
    :encounter_links=>BOSS_ENCOUNTER_PROFILE_V091.size,
    :trigger_types=>[:hp,:timer],
    :effect_types=>BOSS_EFFECT_TYPES_V091,
    :adds=>true,
    :weather=>true,
    :field=>true,
    :shield=>true,
    :invulnerable=>true,
    :phase_notice=>true,
    :mechanic_hook=>true,
    :first_clear_bonus=>true,
    :boss_recruitable=>false,
    :legacy_boss=>'v0.81',
    :runtime_checksum32=>910910517
  }

  class << self
    def boss_profile_v091(key)
      BOSS_PROFILES_V091[key]
    end

    def boss_profile_key_for_encounter_v091(encounter_key)
      BOSS_ENCOUNTER_PROFILE_V091[encounter_key]
    end

    def boss_profile_key_for_request_v091(request)
      return nil if request==nil
      return request[:boss_profile_v091] if request[:boss_profile_v091]!=nil
      boss_profile_key_for_encounter_v091(request[:key])
    end

    def boss_profile_for_request_v091(request)
      boss_profile_v091(boss_profile_key_for_request_v091(request))
    end

    def boss_effect_supported_v091?(kind)
      BOSS_EFFECT_TYPES_V091.include?(kind.to_sym)
    end

    def boss_phase_hp_rate_v091(hp,maxhp)
      return 0.0 if maxhp.to_i<=0
      hp.to_f/maxhp.to_f
    end

    def boss_phase_trigger_met_v091(rule,hp_rate,age_frames)
      return false if rule==nil
      tests=[]
      tests.push(hp_rate.to_f <= rule[:hp_below].to_f) if rule[:hp_below]!=nil
      tests.push(age_frames.to_i >= rule[:time_frames].to_i) if rule[:time_frames]!=nil
      return false if tests.empty?
      mode=rule[:trigger_mode] || :all
      if mode==:any
        tests.each{|x|return true if x}
        return false
      end
      tests.each{|x|return false unless x}
      true
    end

    def boss_phase_trigger_label_v091(rule)
      return 'none' if rule==nil
      a=[]
      a.push('hp<='+sprintf('%.0f',rule[:hp_below].to_f*100.0)+'%') if rule[:hp_below]!=nil
      a.push('time>='+rule[:time_frames].to_i.to_s+'f') if rule[:time_frames]!=nil
      a.join(rule[:trigger_mode]==:any ? ' OR ' : ' + ')
    end

    def boss_reward_rows_v091(profile_key,first_clear)
      p=boss_profile_v091(profile_key)
      return [] if p==nil
      rows=first_clear ? p[:first_clear_bonus] : p[:repeat_bonus]
      rows || []
    end

    def boss_profile_errors_v091
      errors=[]
      BOSS_ENCOUNTER_PROFILE_V091.each do |enc,key|
        errors.push('link_'+enc.to_s) if boss_profile_v091(key)==nil
      end
      BOSS_PROFILES_V091.each do |key,p|
        errors.push('name_'+key.to_s) if p[:name].to_s==''
        phases=p[:phases] || []
        errors.push('phase_empty_'+key.to_s) if phases.empty?
        seen={}
        phases.each do |ph|
          pk=ph[:key]
          errors.push('phase_key_'+key.to_s) if pk==nil || seen[pk]
          seen[pk]=true if pk!=nil
          if ph[:hp_below]==nil && ph[:time_frames]==nil
            errors.push('phase_trigger_'+key.to_s+'_'+pk.to_s)
          end
          if ph[:hp_below]!=nil
            rate=ph[:hp_below].to_f
            errors.push('phase_hp_'+key.to_s+'_'+pk.to_s) if rate<=0.0 || rate>=1.0
          end
          if ph[:time_frames]!=nil
            errors.push('phase_time_'+key.to_s+'_'+pk.to_s) if ph[:time_frames].to_i<=0
          end
          (ph[:effects]||[]).each do |ef|
            kind=ef.is_a?(Array) ? ef[0] : nil
            errors.push('effect_'+key.to_s+'_'+pk.to_s+'_'+kind.to_s) if kind==nil || !boss_effect_supported_v091?(kind)
          end
        end
        errors.push('recruit_'+key.to_s) unless p[:never_recruit]
      end
      errors
    end
  end
end
