# encoding: UTF-8
#==============================================================================
# 【PMD AutoChess 中文維護說明】
# 腳本：PMD AutoChess Dynamic Tactical Role Data v0.99.13
# 分類：動態戰場定位／AI Strategy 資料層
# RPG Maker VX / RGSS2 / Ruby 1.8 compatible
#==============================================================================
# 【用途】
# 本腳本把「Species 天性」與「玩家實際配裝後的戰場定位」拆成兩層。
#
# Species Gameplay Review 仍保留原本的 role / movement / target / threat / skill，
# 但不再把它視為寶可夢一輩子唯一能做的工作。Runtime Tactical Role 會同時看：
#   1. Species Review 原始定位。
#   2. Base Stats：耐久、攻擊面、速度。
#   3. Basic Flex：melee / ranged / adaptive 與射程。
#   4. 目前 4 個 Active Moves 的戰術標籤。
#   5. Ability / Held Item 的少量定位傾向。
#   6. 玩家 AI：movement / target / threat / skill / spacing / spatial intent。
#   7. 玩家可選的 role_bias（偏好定位）。
#
# 【核心目標】
# 同一隻 Pokémon 可以因技能＋AI 成為不同角色：
#   - Diver：突進、穿越戰線、背擊、切後排。
#   - Skirmisher：進出混戰、U-turn / Volt Switch 類拉打。
#   - Bodyguard：Peel、Push、Swap、保護隊友。
#   - Controller：Pull、群聚、狀態、場地控制。
#   - Artillery：遠距與群聚／直線輸出。
#   - Assassin：高速、收頭、後排優先。
#   - Bruiser / Frontline / Kiter 依舊存在。
#
# Dynamic Role 是「分數」，不是硬職業。最高分只作為目前主要戰場定位。
# 玩家仍可直接調 movement / target / spacing 等 AI，這些設定永遠優先於
# 系統擅自替玩家改配置。
#
#==============================================================================
# 【主要設定項】
# TACTICAL_ROLES_V09913
#   動態角色清單。
#
# AI_ROLE_BIASES_V09913
#   :auto 表示由 Species＋技能＋AI 推導。
#   其餘值會給指定角色很高的加權，但不修改種族值與招式傷害。
#
# ROLE_TO_SPACING_V09913
#   玩家沒有明確指定 spacing_policy 時，若 role_bias 非 :auto，
#   可由角色偏好推導站位，例如 Diver -> close、Skirmisher -> flexible。
#
# ROLE_MOVE_TAG_WEIGHTS_V09913
#   各角色偏好的技能 Tactical Tags。
#
#==============================================================================
# 【AI Strategy 面板】
# 戰前布陣時游標停在我方 Pokémon：
#   A 鍵（Input::X）開啟 AI Strategy。
#
# 可調：
#   角色偏好 role_bias
#   移動 movement_policy
#   目標 target_policy
#   威脅 threat_policy
#   技能 skill_policy
#   站位 spacing_policy
#   位移意圖 spatial_intent
#   目標黏著 target_commitment
#
# 左右：調整
# C：恢復該欄預設
# B / A：關閉
#
#==============================================================================
# 【腳本呼叫範例】
# pokemon.set_ai_option(:role_bias, :diver)
# pokemon.set_ai_option(:spacing_policy, :close)
# pokemon.set_ai_option(:spatial_intent, :dive)
# pokemon.set_ai_option(:target_policy, :backline_low_def)
#
# 查目前動態定位：
# scores = PMD_AC.dynamic_role_scores_v09913(pokemon)
# role   = PMD_AC.dynamic_role_v09913(pokemon)
#
#==============================================================================
# 【安全邊界】
# - 不直接修改 Frozen Combat Core。
# - 不改 Base Stats / IV / Nature / Damage Formula。
# - 不改技能原始 Power / Category / Accuracy。
# - Dynamic Role 主要影響 AI 技能評分、玩家選擇的站位 fallback 與 UI 顯示。
# - 明確的玩家 AI 設定優先，不會被 Species Role 偷偷覆寫。
# - 494/494 Gameplay Review 與 v0.99.12 Basic Flex 全部保留。
#==============================================================================
module PMD_AC
  DYNAMIC_TACTICAL_ROLE_VERSION_V09913='0.99.13'

  TACTICAL_ROLES_V09913=[
    :frontline,:bruiser,:bodyguard,:controller,:artillery,
    :assassin,:kiter,:diver,:skirmisher
  ]

  AI_ROLE_BIASES_V09913=[:auto]+TACTICAL_ROLES_V09913

  ROLE_TO_SPACING_V09913={
    :frontline=>:hold,
    :bruiser=>:hold,
    :bodyguard=>:bodyguard,
    :controller=>:flexible,
    :artillery=>:artillery,
    :assassin=>:close,
    :kiter=>:kite,
    :diver=>:close,
    :skirmisher=>:flexible
  }

  ROLE_LABELS_V09913={
    :frontline=>'前排',
    :bruiser=>'鬥士',
    :bodyguard=>'護衛',
    :controller=>'控制',
    :artillery=>'砲台',
    :assassin=>'刺客',
    :kiter=>'拉打',
    :diver=>'切入',
    :skirmisher=>'游擊'
  }

  SPACING_LABELS_V09913={
    :species_default=>'物種預設',:kite=>'拉打',:hold=>'站樁',
    :flexible=>'彈性',:bodyguard=>'護衛',:artillery=>'遠距砲台',:close=>'貼身'
  }

  SPATIAL_LABELS_V09913={
    :balanced=>'平衡',:engage=>'接戰',:disengage=>'脫離',
    :peel=>'保護',:dive=>'切後排',:control=>'控制'
  }

  MOVEMENT_LABELS_V09913={
    :frontline=>'前排',:bruiser=>'鬥士',:assassin=>'刺客',:kiter=>'拉打',
    :artillery=>'砲台',:controller=>'控制',:bodyguard=>'護衛',:berserker=>'狂戰'
  }

  TARGET_LABELS_V09913={
    :nearest=>'最近',:lowest_hp=>'最低HP',:lowest_hp_percent=>'最低HP%',
    :lowest_def=>'最低防禦',:highest_atk=>'最高攻擊',:farthest=>'最遠',
    :backline=>'後排',:ranged_first=>'遠程優先',:melee_first=>'近戰優先',
    :cluster=>'群聚',:current_attacker=>'攻擊者',:backline_low_def=>'脆弱後排',
    :execute=>'收頭',:protect_ally=>'威脅友軍者'
  }

  THREAT_LABELS_V09913={
    :hold_ground=>'不退',:normal=>'一般',:ignore_minor=>'忽略小威脅',
    :responsive=>'反應式',:protective=>'保護式'
  }

  SKILL_LABELS_V09913={
    :current_target=>'目前目標',:best_cluster=>'最佳群聚',:execute=>'收頭',
    :lowest_def=>'最低防禦',:highest_atk=>'最高攻擊',
    :protect_ally=>'保護友軍',:heal_critical=>'危急治療',:lowest_ally=>'最低友軍'
  }

  ROLE_MOVE_TAG_WEIGHTS_V09913={
    :frontline=>{
      :melee_density_payoff=>8,:frontline_control=>10,:space_create=>5
    },
    :bruiser=>{
      :engage=>8,:gap_close=>8,:melee_density_payoff=>7,:back_attack=>4
    },
    :bodyguard=>{
      :peel=>14,:rescue=>16,:swap=>14,:frontline_control=>12,:space_create=>8
    },
    :controller=>{
      :pull=>10,:isolate=>10,:cluster_payoff=>9,:line_payoff=>5,
      :space_create=>7,:frontline_control=>8
    },
    :artillery=>{
      :cluster_payoff=>10,:line_payoff=>10,:space_create=>3
    },
    :assassin=>{
      :back_attack=>12,:blink_behind=>14,:dash_through=>9,:gap_close=>7
    },
    :kiter=>{
      :disengage=>12,:escape=>12,:space_create=>8,:skirmish=>8
    },
    :diver=>{
      :dive=>16,:dash_through=>16,:blink_behind=>16,:engage=>10,
      :gap_close=>12,:back_attack=>10,:phase_reposition=>8
    },
    :skirmisher=>{
      :skirmish=>16,:disengage=>14,:space_create=>10,:reposition=>8,
      :dash_through=>7,:engage=>5
    }
  }

  ABILITY_ROLE_HINTS_V09913={
    :friend_guard=>{:bodyguard=>14},
    :prankster=>{:controller=>12},
    :speed_boost=>{:kiter=>8,:assassin=>6,:skirmisher=>8},
    :sturdy=>{:frontline=>10,:bodyguard=>6},
    :solid_rock=>{:frontline=>10,:bodyguard=>6},
    :filter=>{:frontline=>10,:bodyguard=>6},
    :regenerator=>{:skirmisher=>10,:bodyguard=>5},
    :intimidate=>{:frontline=>6,:bodyguard=>7,:controller=>5},
    :technician=>{:assassin=>5,:skirmisher=>5},
    :adaptability=>{:bruiser=>5,:artillery=>5},
    :serene_grace=>{:controller=>8},
    :poison_heal=>{:frontline=>6,:bruiser=>5}
  }

  HELD_ITEM_ROLE_HINTS_V09913={
    :focus_sash=>{:assassin=>5,:artillery=>5},
    :life_orb=>{:assassin=>5,:bruiser=>5,:artillery=>5},
    :leftovers=>{:frontline=>6,:bodyguard=>6},
    :air_balloon=>{:kiter=>4,:skirmisher=>4}
  }

  ROLE_BIAS_BONUS_V09913=42.0

  class << self
    def normalize_role_key_v09913(key)
      return :auto if key==nil
      k=key.to_sym rescue :auto
      AI_ROLE_BIASES_V09913.include?(k) ? k : :auto
    end

    def role_label_v09913(role)
      ROLE_LABELS_V09913[role] || role.to_s
    end

    def add_role_score_v09913(scores,role,value)
      return if scores==nil || !TACTICAL_ROLES_V09913.include?(role)
      scores[role]=scores[role].to_f+value.to_f
    end

    def review_profile_any_v09913(species_key,form_key=nil)
      return nil unless respond_to?(:review_profile_for_v09911)
      review_profile_for_v09911(species_key,form_key || :normal)
    end

    def move_runtime_data_v09913(move_key)
      return nil if move_key==nil
      k=move_key.to_s.downcase.gsub(/^mv_/,'').gsub(/[^a-z0-9]+/,'_').to_sym
      if respond_to?(:skill_data)
        d=skill_data(('mv_'+k.to_s).to_sym)
        return d if d!=nil
      end
      nil
    rescue
      nil
    end

    def move_tactical_tags_v09913(move_key,data=nil)
      return [] if move_key==nil
      k=move_key.to_s.downcase.gsub(/^mv_/,'').gsub(/[^a-z0-9]+/,'_').to_sym
      d=data || move_runtime_data_v09913(k)
      out=respond_to?(:skill_tactical_tags_v09912) ? skill_tactical_tags_v09912(k,d) : []
      out=out.dup

      if d!=nil
        delivery=d[:delivery] || d['delivery']
        category=d[:damage_category] || d[:category] || d['damage_category'] || d['category']
        target_type=d[:target_type] || d['target_type']
        power=(d[:power] || d['power'] || 0).to_i

        out.push(:status_utility) if category==:status
        out.push(:burst_damage) if power>=100
        out.push(:ranged_pressure) if [:projectile,:beam,:pierce,:chain].include?(delivery)
        out.push(:melee_pressure) if [:contact,:melee,:dash,:blink].include?(delivery)
        out.push(:ally_support) if [:ally,:ally_targeted,:ally_or_self,:team].include?(target_type)
      end

      # Move-key semantic tags for important support / positioning families.
      if [:protect,:detect,:wide_guard,:quick_guard,:endure].include?(k)
        out.push(:guard_support)
      end
      if [:recover,:roost,:soft_boiled,:slack_off,:milk_drink,:heal_pulse,
          :wish,:morning_sun,:synthesis,:moonlight].include?(k)
        out.push(:heal_support)
      end
      if [:tailwind,:reflect,:light_screen,:safeguard,:mist].include?(k)
        out.push(:team_support)
      end
      if [:toxic,:will_o_wisp,:thunder_wave,:sleep_powder,:spore,:hypnosis,
          :stun_spore,:glare,:confuse_ray].include?(k)
        out.push(:hard_control)
      end

      out.uniq
    end

    def add_move_role_scores_v09913(scores,move_key)
      tags=move_tactical_tags_v09913(move_key)
      TACTICAL_ROLES_V09913.each do |role|
        weights=ROLE_MOVE_TAG_WEIGHTS_V09913[role] || {}
        tags.each do |tag|
          w=weights[tag]
          add_role_score_v09913(scores,role,w) if w!=nil
        end
      end

      if tags.include?(:status_utility) || tags.include?(:hard_control)
        add_role_score_v09913(scores,:controller,8)
      end
      if tags.include?(:guard_support) || tags.include?(:ally_support) ||
         tags.include?(:heal_support) || tags.include?(:team_support)
        add_role_score_v09913(scores,:bodyguard,9)
        add_role_score_v09913(scores,:controller,4)
      end
      if tags.include?(:burst_damage)
        add_role_score_v09913(scores,:assassin,4)
        add_role_score_v09913(scores,:artillery,4)
        add_role_score_v09913(scores,:bruiser,3)
      end
      if tags.include?(:ranged_pressure)
        add_role_score_v09913(scores,:artillery,4)
        add_role_score_v09913(scores,:kiter,3)
      end
      if tags.include?(:melee_pressure)
        add_role_score_v09913(scores,:bruiser,4)
        add_role_score_v09913(scores,:diver,3)
      end
      tags
    end

    def add_species_role_scores_v09913(scores,species_key,form_key=nil)
      review=review_profile_any_v09913(species_key,form_key)
      if review!=nil
        r=review[:role]
        add_role_score_v09913(scores,r,30) if TACTICAL_ROLES_V09913.include?(r)
        move=review[:movement_policy]
        add_role_score_v09913(scores,move,13) if TACTICAL_ROLES_V09913.include?(move)
        add_role_score_v09913(scores,:bruiser,10) if move==:berserker
      end

      d=SPECIES_DB_V016[species_key] rescue nil
      stats=d==nil ? nil : d[:base_stats]
      if stats!=nil && stats.size==6
        hp=stats[0].to_i;atk=stats[1].to_i;df=stats[2].to_i
        spa=stats[3].to_i;spd=stats[4].to_i;spe=stats[5].to_i
        bulk=hp+df+spd
        offense=[atk,spa].max

        if bulk>=280
          add_role_score_v09913(scores,:frontline,16)
          add_role_score_v09913(scores,:bodyguard,12)
        elsif bulk>=240
          add_role_score_v09913(scores,:frontline,9)
          add_role_score_v09913(scores,:bodyguard,6)
        end

        if offense>=120
          if spa>=atk
            add_role_score_v09913(scores,:artillery,10)
          else
            add_role_score_v09913(scores,:bruiser,8)
            add_role_score_v09913(scores,:assassin,5)
          end
        elsif offense>=100
          add_role_score_v09913(scores,spa>=atk ? :artillery : :bruiser,5)
        end

        if spe>=110
          add_role_score_v09913(scores,:assassin,10)
          add_role_score_v09913(scores,:kiter,8)
          add_role_score_v09913(scores,:diver,6)
          add_role_score_v09913(scores,:skirmisher,8)
        elsif spe>=90
          add_role_score_v09913(scores,:assassin,5)
          add_role_score_v09913(scores,:skirmisher,5)
        end
      end

      flex=basic_flex_profile_v09912(species_key,form_key || :normal) rescue nil
      if flex!=nil
        case flex[:mode]
        when :ranged
          add_role_score_v09913(scores,:artillery,8)
          add_role_score_v09913(scores,:kiter,7)
        when :adaptive
          add_role_score_v09913(scores,:skirmisher,9)
          add_role_score_v09913(scores,:controller,3)
        when :melee
          add_role_score_v09913(scores,:bruiser,4)
          add_role_score_v09913(scores,:assassin,3)
        end
      end
      review
    end

    def add_ai_role_scores_v09913(scores,ai)
      ai={} if ai==nil
      move=ai[:movement_policy]
      add_role_score_v09913(scores,move,18) if TACTICAL_ROLES_V09913.include?(move)
      add_role_score_v09913(scores,:bruiser,14) if move==:berserker

      case ai[:target_policy]
      when :backline_low_def,:backline
        add_role_score_v09913(scores,:assassin,12);add_role_score_v09913(scores,:diver,7)
      when :execute,:lowest_hp,:lowest_hp_percent
        add_role_score_v09913(scores,:assassin,7);add_role_score_v09913(scores,:bruiser,5)
      when :cluster
        add_role_score_v09913(scores,:controller,8);add_role_score_v09913(scores,:artillery,6)
      when :protect_ally
        add_role_score_v09913(scores,:bodyguard,14)
      end

      case ai[:threat_policy]
      when :protective
        add_role_score_v09913(scores,:bodyguard,12)
      when :hold_ground
        add_role_score_v09913(scores,:frontline,8);add_role_score_v09913(scores,:bruiser,5)
      when :ignore_minor
        add_role_score_v09913(scores,:assassin,7);add_role_score_v09913(scores,:diver,5)
      when :responsive
        add_role_score_v09913(scores,:controller,4);add_role_score_v09913(scores,:skirmisher,5)
      end

      case ai[:skill_policy]
      when :best_cluster
        add_role_score_v09913(scores,:controller,8);add_role_score_v09913(scores,:artillery,8)
      when :protect_ally,:heal_critical,:lowest_ally
        add_role_score_v09913(scores,:bodyguard,12)
      when :execute
        add_role_score_v09913(scores,:assassin,7);add_role_score_v09913(scores,:bruiser,4)
      end

      case ai[:spacing_policy]
      when :kite
        add_role_score_v09913(scores,:kiter,18)
      when :artillery
        add_role_score_v09913(scores,:artillery,20)
      when :bodyguard
        add_role_score_v09913(scores,:bodyguard,20)
      when :close
        add_role_score_v09913(scores,:bruiser,10);add_role_score_v09913(scores,:diver,10)
      when :flexible
        add_role_score_v09913(scores,:skirmisher,15)
      when :hold
        add_role_score_v09913(scores,:frontline,6);add_role_score_v09913(scores,:bruiser,5)
      end

      case ai[:spatial_intent]
      when :engage
        add_role_score_v09913(scores,:bruiser,9);add_role_score_v09913(scores,:diver,12)
      when :disengage
        add_role_score_v09913(scores,:kiter,10);add_role_score_v09913(scores,:skirmisher,15)
      when :peel
        add_role_score_v09913(scores,:bodyguard,18);add_role_score_v09913(scores,:controller,7)
      when :dive
        add_role_score_v09913(scores,:diver,22);add_role_score_v09913(scores,:assassin,8)
      when :control
        add_role_score_v09913(scores,:controller,18)
      end

      bias=normalize_role_key_v09913(ai[:role_bias])
      add_role_score_v09913(scores,bias,ROLE_BIAS_BONUS_V09913) if bias!=:auto
      scores
    end

    def dynamic_role_scores_for_v09913(species_key,active_moves=nil,ai=nil,ability=nil,item=nil,form_key=nil)
      scores={}
      TACTICAL_ROLES_V09913.each{|r|scores[r]=0.0}
      add_species_role_scores_v09913(scores,species_key,form_key)
      (active_moves || []).each{|mv|add_move_role_scores_v09913(scores,mv)}
      add_ai_role_scores_v09913(scores,ai || {})

      hints=ABILITY_ROLE_HINTS_V09913[ability] || {}
      hints.each{|r,v|add_role_score_v09913(scores,r,v)}
      ih=HELD_ITEM_ROLE_HINTS_V09913[item] || {}
      ih.each{|r,v|add_role_score_v09913(scores,r,v)}
      scores
    end

    def dynamic_role_scores_v09913(instance)
      return {} if instance==nil
      sk=instance.species_key
      fk=instance.respond_to?(:form_key) ? instance.form_key : :normal
      moves=instance.respond_to?(:active_moves_v045) ? instance.active_moves_v045 : []
      ai=instance.respond_to?(:ai_setup) ? instance.ai_setup : {}
      ab=instance.respond_to?(:ability_key) ? instance.ability_key : nil
      it=instance.respond_to?(:held_item_key_v041) ? instance.held_item_key_v041 : nil
      dynamic_role_scores_for_v09913(sk,moves,ai,ab,it,fk)
    end

    def dynamic_role_v09913(instance)
      scores=dynamic_role_scores_v09913(instance)
      return :frontline if scores.empty?
      best=TACTICAL_ROLES_V09913[0]
      TACTICAL_ROLES_V09913.each do |r|
        best=r if scores[r].to_f>scores[best].to_f
      end
      best
    end

    def sorted_role_scores_v09913(scores)
      TACTICAL_ROLES_V09913.sort do |a,b|
        c=scores[b].to_f<=>scores[a].to_f
        c==0 ? a.to_s<=>b.to_s : c
      end
    end

    def role_move_bonus_v09913(role,tags)
      weights=ROLE_MOVE_TAG_WEIGHTS_V09913[role] || {}
      total=0.0
      (tags || []).each{|t|total+=weights[t].to_f if weights[t]!=nil}
      [total,18.0].min
    end

    def role_default_spacing_v09913(role)
      ROLE_TO_SPACING_V09913[role] || :species_default
    end
  end
end
