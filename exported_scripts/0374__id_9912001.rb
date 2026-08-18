# encoding: UTF-8
#==============================================================================
# 【PMD AutoChess 中文維護說明】
# 腳本：PMD AutoChess Basic Attack / Spatial Flex Data v0.99.12
# 分類：普攻模式解耦／玩家戰術 AI／空間技能統一資料層
# RPG Maker VX / RGSS2 / Ruby 1.8 compatible
#==============================================================================
# 【用途】
# 本腳本是「玩家可透過技能配置＋AI 改變 Pokémon 戰場定位」的第一階段底座。
# 它不把 Species Profile 原本的 Role 刪掉，而是把先前綁在一起的概念正式拆開：
#
#   A. Basic Attack Delivery：普攻是 melee / ranged / adaptive。
#   B. Basic Max Range：普攻最大射程，只代表「多遠仍可攻擊」。
#   C. Preferred Spacing：AI 想站多遠，不再決定能不能攻擊。
#   D. Movement Policy：Kiter / Bodyguard / Bruiser 等仍是行動傾向。
#   E. Spatial Intent：玩家可告訴 AI 比較偏好 engage / disengage / peel / dive。
#
# 重要規則：
# - ranged 普攻的「射程」是 0～Max Range，而不是 Min Range～Max Range。
# - 敵人貼身時，真正遠程仍可在 Point Blank 射擊。
# - adaptive 遠距使用 ranged basic，敵人貼近後改用 close basic。
# - adaptive 使用不同的進入／離開距離（Hysteresis），避免 1px 抖動切模式。
# - Pokémon 體質仍來自 Species Base Stats／IV／Nature，不因遠程標籤強制扣防。
# - Species Review 是先天天性；玩家 4 招、AI、Ability、Held Item 才決定實戰定位。
#
#==============================================================================
# 【目前 v0.99.12 範圍】
# 1. 為 494 隻已完成 Gameplay Review 的 Pokémon 產生 Basic Flex Profile。
# 2. 原本 range=1 的物種保持 :melee。
# 3. 原本 ranged 依 Role／種族值初步分成 :ranged 或 :adaptive；此為 Foundation，
#    後續可逐物種人工覆寫，不把本版自動分類當永遠定案。
# 4. Kanto Starter／Abra line／Pikachu 等提供人工示範 Override。
# 5. 建立 Unified Spatial Tactical Tags，把 v0.91.4 的 19 個 Spatial Move 和
#    Ally Switch／Two-turn reposition 等納入同一套 AI 標籤語彙。
# 6. 新增 Aerial Ace / Feint Attack 的 :dash_through AutoChess 位移示範，
#    讓技能能穿過目標並停在另一側，作為 Diver / Skirmisher 的基礎。
#
#==============================================================================
# 【主要設定項】
# BASIC_FLEX_OVERRIDES_V09912
#   逐物種人工覆寫。可設定：
#   :mode             :melee / :ranged / :adaptive
#   :spacing_policy   :kite / :hold / :flexible / :bodyguard / :artillery
#   :basic_max_range  普攻最大 Pixel 射程
#   :preferred_min    AI 開始覺得太近的距離（不是攻擊下限）
#   :preferred_max    AI 覺得舒適區的遠端
#   :close_enter      adaptive 進入 close basic 的距離
#   :ranged_resume    adaptive 切回 ranged basic 的距離
#   :close_type       close basic 屬性
#   :close_category   close basic Physical / Special
#
# AI_SPACING_POLICIES_V09912
#   玩家可寫入 PMD_PokemonInstance#ai_setup：
#     :species_default  使用 Species Flex Profile
#     :kite             攻擊後積極維持距離
#     :hold             射程內不主動後退
#     :flexible         Adaptive 近身後接受混戰，不為了射程不停逃
#     :bodyguard        以保護友軍站位優先
#     :artillery        優先維持較長安全距離
#     :close            主動接近，適合把 ranged-capable Pokémon 改造成近戰玩法
#
# AI_SPATIAL_INTENTS_V09912
#     :balanced / :engage / :disengage / :peel / :dive / :control
#   這會影響已有 Spatial Move 的 AI 候選分數，不直接改招式傷害。
#
#==============================================================================
# 【腳本呼叫範例】
# 查某物種 Foundation Profile：
#   p PMD_AC.basic_flex_profile_v09912(:charmander, :normal)
#
# 玩家把某隻 Pokémon 改成不主動風箏：
#   pokemon.set_ai_option(:spacing_policy, :hold)
#
# 玩家希望位移技能偏向切入：
#   pokemon.set_ai_option(:spatial_intent, :dive)
#
# 玩家恢復物種預設站位：
#   pokemon.clear_ai_option(:spacing_policy)
#
# 查技能戰術標籤：
#   p PMD_AC.skill_tactical_tags_v09912(:u_turn)
#     # => [:disengage, :skirmish, :space_create]
#
#==============================================================================
# 【實際例子】
# Charmander：
#   遠距 Fire/Special，最大普攻射程縮短為中距離；貼身後切 Normal/Physical。
#   因 spacing=:flexible，被黏住時會反擊，不再把「逃到理想距離」當攻擊前提。
#
# Abra / Kadabra / Alakazam：
#   真正遠程玻璃砲，mode=:ranged。敵人貼身仍能 Psychic/Special Point Blank，
#   但低 HP/DEF 就是被切入後的實際代價。
#
# Squirtle line：
#   Adaptive + Bodyguard。遠距 Water/Special，貼身 Water/Physical；主要站位由
#   Bodyguard 保護需求決定，而不是看到敵人靠近就一直後退。
#
#==============================================================================
# 【安全邊界】
# - 不直接修改 Frozen Combat Core 舊腳本。
# - 不改 Base Stats、IV、Nature、Damage Formula、Skill Category。
# - 不把 Skill Range 綁到 Basic Max Range；兩者從本版開始正式分離。
# - 不強制玩家採用 Dynamic Role；本版只建立 AI 可用資料與 Runtime hook。
# - v0.99.11 的 494 Gameplay Review 結果全部保留。
#==============================================================================
module PMD_AC
  BASIC_SPATIAL_FLEX_VERSION_V09912='0.99.12'
  BASIC_ATTACK_MODES_V09912=[:melee,:ranged,:adaptive]
  AI_SPACING_POLICIES_V09912=[:species_default,:kite,:hold,:flexible,:bodyguard,:artillery,:close]
  AI_SPATIAL_INTENTS_V09912=[:balanced,:engage,:disengage,:peel,:dive,:control]

  ADAPTIVE_DEFAULT_BASIC_MAX_V09912=158.0
  RANGED_DEFAULT_BASIC_MAX_V09912=192.0
  RANGED_HOLD_BASIC_MAX_V09912=172.0
  ADAPTIVE_CLOSE_ENTER_V09912=66.0
  ADAPTIVE_RANGED_RESUME_V09912=92.0
  ADAPTIVE_CLOSE_STAGGER_MOVE_MULT_V09912=0.80

  # 人工示範覆寫。未列入者由 Review Profile + Base Stats 產生 Foundation 預設。
  BASIC_FLEX_OVERRIDES_V09912={
    :bulbasaur=>{:mode=>:adaptive,:spacing_policy=>:flexible,:basic_max_range=>158.0,
      :preferred_min=>88.0,:preferred_max=>126.0,:close_enter=>66.0,:ranged_resume=>92.0,
      :close_type=>:grass,:close_category=>:physical},
    :ivysaur=>{:mode=>:adaptive,:spacing_policy=>:flexible,:basic_max_range=>162.0,
      :preferred_min=>90.0,:preferred_max=>130.0,:close_enter=>68.0,:ranged_resume=>94.0,
      :close_type=>:grass,:close_category=>:physical},
    :venusaur=>{:mode=>:adaptive,:spacing_policy=>:flexible,:basic_max_range=>168.0,
      :preferred_min=>92.0,:preferred_max=>134.0,:close_enter=>70.0,:ranged_resume=>96.0,
      :close_type=>:grass,:close_category=>:physical},

    :charmander=>{:mode=>:adaptive,:spacing_policy=>:flexible,:basic_max_range=>158.0,
      :preferred_min=>92.0,:preferred_max=>132.0,:close_enter=>64.0,:ranged_resume=>92.0,
      :close_type=>:normal,:close_category=>:physical},
    :charmeleon=>{:mode=>:adaptive,:spacing_policy=>:flexible,:basic_max_range=>164.0,
      :preferred_min=>94.0,:preferred_max=>136.0,:close_enter=>66.0,:ranged_resume=>94.0,
      :close_type=>:normal,:close_category=>:physical},
    :charizard=>{:mode=>:adaptive,:spacing_policy=>:flexible,:basic_max_range=>174.0,
      :preferred_min=>98.0,:preferred_max=>144.0,:close_enter=>70.0,:ranged_resume=>98.0,
      :close_type=>:fire,:close_category=>:physical},

    :squirtle=>{:mode=>:adaptive,:spacing_policy=>:bodyguard,:basic_max_range=>154.0,
      :preferred_min=>78.0,:preferred_max=>116.0,:close_enter=>64.0,:ranged_resume=>90.0,
      :close_type=>:water,:close_category=>:physical},
    :wartortle=>{:mode=>:adaptive,:spacing_policy=>:bodyguard,:basic_max_range=>158.0,
      :preferred_min=>80.0,:preferred_max=>120.0,:close_enter=>66.0,:ranged_resume=>92.0,
      :close_type=>:water,:close_category=>:physical},
    :blastoise=>{:mode=>:adaptive,:spacing_policy=>:bodyguard,:basic_max_range=>164.0,
      :preferred_min=>82.0,:preferred_max=>124.0,:close_enter=>68.0,:ranged_resume=>94.0,
      :close_type=>:water,:close_category=>:physical},

    :abra=>{:mode=>:ranged,:spacing_policy=>:kite,:basic_max_range=>192.0,
      :preferred_min=>118.0,:preferred_max=>158.0},
    :kadabra=>{:mode=>:ranged,:spacing_policy=>:kite,:basic_max_range=>192.0,
      :preferred_min=>120.0,:preferred_max=>160.0},
    :alakazam=>{:mode=>:ranged,:spacing_policy=>:artillery,:basic_max_range=>192.0,
      :preferred_min=>126.0,:preferred_max=>166.0},
    :pikachu=>{:mode=>:ranged,:spacing_policy=>:kite,:basic_max_range=>184.0,
      :preferred_min=>112.0,:preferred_max=>152.0},
    :raichu=>{:mode=>:ranged,:spacing_policy=>:kite,:basic_max_range=>188.0,
      :preferred_min=>114.0,:preferred_max=>154.0},
    :magnemite=>{:mode=>:ranged,:spacing_policy=>:hold,:basic_max_range=>168.0,
      :preferred_min=>0.0,:preferred_max=>148.0},
    :magneton=>{:mode=>:ranged,:spacing_policy=>:hold,:basic_max_range=>176.0,
      :preferred_min=>0.0,:preferred_max=>154.0}
  }

  # v0.91.4 既有 Spatial Move 的統一語彙，再加上少量 native / 新示範。
  SPATIAL_TACTICAL_TAGS_V09912={
    :quick_attack=>[:engage,:gap_close,:execute],
    :mach_punch=>[:engage,:gap_close,:execute],
    :extreme_speed=>[:engage,:gap_close,:execute],
    :aqua_jet=>[:engage,:gap_close,:execute],
    :flame_charge=>[:engage,:gap_close,:snowball],
    :volt_tackle=>[:engage,:gap_close,:commit],
    :wild_charge=>[:engage,:gap_close,:commit],
    :water_gun=>[:disengage,:peel,:space_create],
    :hydro_pump=>[:disengage,:peel,:space_create],
    :gust=>[:disengage,:peel,:space_create],
    :hurricane=>[:disengage,:peel,:space_create,:cluster_control],
    :dragon_tail=>[:peel,:space_create,:frontline_control],
    :circle_throw=>[:peel,:space_create,:frontline_control],
    :roar=>[:peel,:space_create,:frontline_control],
    :whirlwind=>[:peel,:space_create,:frontline_control],
    :vine_whip=>[:engage,:pull,:isolate],
    :power_whip=>[:engage,:pull,:isolate],
    :u_turn=>[:disengage,:skirmish,:space_create],
    :volt_switch=>[:disengage,:skirmish,:space_create],
    :ally_switch=>[:rescue,:swap,:reposition,:peel],
    :fly=>[:dive,:phase_reposition,:escape],
    :bounce=>[:dive,:phase_reposition,:escape],
    :dig=>[:dive,:phase_reposition,:escape],
    :dive=>[:dive,:phase_reposition,:escape],
    :shadow_force=>[:dive,:blink_behind,:back_attack,:phase_reposition],
    :aerial_ace=>[:dive,:dash_through,:back_attack],
    :feint_attack=>[:dive,:dash_through,:back_attack]
  }

  SPATIAL_MOVE_EXTENSIONS_V09912={
    :aerial_ace=>{:kind=>:dash_through,:distance_past=>34.0,:frames=>7},
    :feint_attack=>{:kind=>:dash_through,:distance_past=>30.0,:frames=>7}
  }

  MELEE_DENSITY_MOVES_V09912=[
    :earthquake,:discharge,:lava_plume,:sludge_wave,:surf,
    :heat_wave,:rock_slide,:bulldoze,:magnitude,:explosion,:self_destruct
  ]

  class << self
    def basic_flex_spacing_from_review_v09912(review)
      role=review==nil ? nil : review[:role]
      move=review==nil ? nil : review[:movement_policy]
      return :bodyguard if role==:bodyguard || move==:bodyguard
      return :artillery if role==:artillery || move==:artillery
      return :kite if move==:kiter
      return :flexible if move==:controller
      :hold
    end

    def basic_flex_true_ranged_v09912(species_key,review)
      return false if review==nil || review[:range].to_i<=1
      d=SPECIES_DB_V016[species_key] || {}
      s=d[:base_stats] || []
      return false unless s.size==6
      hp=s[0].to_i;atk=s[1].to_i;df=s[2].to_i;spa=s[3].to_i;spd=s[4].to_i
      offense=[atk,spa].max;bulk=hp+df+spd
      role=review[:role]
      # Foundation 規則只找出「高輸出而偏脆」的典型真遠程；其餘先 Adaptive。
      return true if role==:artillery && offense>=100 && bulk<=230
      return true if role==:kiter && offense>=95 && bulk<=210
      false
    end

    def basic_flex_profile_v09912(species_key,form_key=nil)
      sk=species_key.to_sym
      review=review_profile_for_v09911(sk,form_key || :normal)
      return nil if review==nil
      base={
        :species_key=>sk,
        :review_source=>:gameplay_review_494,
        :ranged_type=>review[:basic_move_type],
        :ranged_category=>review[:basic_damage_category],
        :close_type=>review[:basic_move_type],
        :close_category=>review[:basic_damage_category],
        :close_enter=>ADAPTIVE_CLOSE_ENTER_V09912,
        :ranged_resume=>ADAPTIVE_RANGED_RESUME_V09912,
        :preferred_min=>88.0,
        :preferred_max=>136.0,
        :spacing_policy=>basic_flex_spacing_from_review_v09912(review),
        :source=>:derived_v09912
      }
      if review[:range].to_i<=1
        base[:mode]=:melee
        base[:basic_max_range]=0.0
        base[:preferred_min]=0.0;base[:preferred_max]=0.0
      elsif basic_flex_true_ranged_v09912(sk,review)
        base[:mode]=:ranged
        base[:basic_max_range]=RANGED_DEFAULT_BASIC_MAX_V09912
        base[:preferred_min]=116.0;base[:preferred_max]=158.0
      else
        base[:mode]=:adaptive
        base[:basic_max_range]=ADAPTIVE_DEFAULT_BASIC_MAX_V09912
      end
      if base[:spacing_policy]==:bodyguard
        base[:preferred_min]=76.0;base[:preferred_max]=118.0
        base[:basic_max_range]=[base[:basic_max_range].to_f,RANGED_HOLD_BASIC_MAX_V09912].min if review[:range].to_i>1
      elsif base[:spacing_policy]==:artillery
        base[:preferred_min]=122.0;base[:preferred_max]=162.0
      elsif base[:spacing_policy]==:hold
        base[:preferred_min]=0.0;base[:preferred_max]=138.0
      end
      ov=BASIC_FLEX_OVERRIDES_V09912[sk]
      if ov!=nil
        ov.each{|k,v|base[k]=v}
        base[:source]=:manual_override_v09912
      end
      base
    end

    def spatial_extension_v09912(move_key)
      return nil if move_key==nil
      k=move_key.to_s.downcase.gsub(/[^a-z0-9]+/,'_').to_sym
      p=SPATIAL_MOVE_EXTENSIONS_V09912[k]
      p==nil ? nil : p.dup
    end

    def skill_tactical_tags_v09912(move_key,data=nil)
      return [] if move_key==nil
      k=move_key.to_s.downcase.gsub(/^mv_/,'').gsub(/[^a-z0-9]+/,'_').to_sym
      out=(SPATIAL_TACTICAL_TAGS_V09912[k] || []).dup
      out.push(:melee_density_payoff) if MELEE_DENSITY_MOVES_V09912.include?(k)
      if data!=nil
        delivery=data[:delivery] || data['delivery']
        radius=data[:radius] || data['radius']
        out.push(:cluster_payoff) if [:aoe,:zone,:chain].include?(delivery)
        out.push(:cluster_payoff) if radius!=nil && radius.to_f>=48.0
        out.push(:line_payoff) if delivery==:pierce
      end
      out.uniq
    end

    def spatial_intent_bonus_v09912(intent,tags)
      i=(intent || :balanced).to_sym
      return 0.0 if i==:balanced
      t=tags || []
      case i
      when :engage
        return 14.0 if !(t & [:engage,:gap_close,:pull]).empty?
      when :disengage
        return 14.0 if !(t & [:disengage,:space_create,:escape]).empty?
      when :peel
        return 16.0 if !(t & [:peel,:rescue,:swap,:frontline_control]).empty?
      when :dive
        return 16.0 if !(t & [:dive,:dash_through,:blink_behind,:back_attack]).empty?
      when :control
        return 12.0 if !(t & [:cluster_control,:pull,:isolate,:space_create,:cluster_payoff]).empty?
      end
      0.0
    end
  end
end
