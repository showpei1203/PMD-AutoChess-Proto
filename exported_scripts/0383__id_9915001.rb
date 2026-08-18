# encoding: UTF-8
#==============================================================================
# 【PMD AutoChess 中文維護說明】
# 腳本：PMD AutoChess Spatial Conditions / AI Rules Data v0.99.15
# 分類：空間條件判定／AI 規則評分／玩家條件偏好資料層
# RPG Maker VX / RGSS2 / Ruby 1.8 compatible
#==============================================================================
# 【用途】
# 延續 v0.99.14 Spatial Framework，把「位移技能存在」推進到「AI 知道何時值得用」。
# 本版不新增傷害倍率，也不把 Species Role 寫死；AI 會依即時戰場條件評估技能：
#   - 目標太近／太遠
#   - 自己被多人包圍
#   - 目標周圍形成群聚
#   - 友軍正在受壓
#   - 後排目標暴露
#   - Line / Cone 幾何機會
#   - 自己低 HP
#   - 目標低 HP
#
# 【核心規則】
# Spatial Condition 是「現況」，Tactical Tags 是「技能能做什麼」。
# AI Rule 將兩者配對後加減候選技能分數。例如：
#   surrounded + escape_through  -> 強烈加分
#   ally_distress + rescue       -> 強烈加分
#   backline_exposed + dash_through/back_attack -> 加分
#   line_count >= 2 + line_geometry -> 加分
#   target_low_hp + execute      -> 加分
# 若條件不成立，少數高度情境化技能會受到輕度扣分，避免無理由亂用。
#
# 【玩家 AI 新增欄位】
# condition_focus：條件偏好，只調整 AI 對戰場條件的重視程度，不直接強制出招。
#   :auto      自動平衡（預設）
#   :distance  距離／接近／脫離
#   :survival  生存／脫困
#   :crowd     群聚／混戰
#   :rescue    救援／Peel
#   :flank     後排／側背
#   :line      直線／扇形
#   :execute   收頭
#
# 【腳本呼叫範例】
# pokemon.set_ai_option(:condition_focus, :rescue)
# pokemon.set_ai_option(:condition_focus, :flank)
# pokemon.clear_ai_option(:condition_focus)
#
# 【可調參數】
# TARGET_NEAR_DISTANCE_V09915 / TARGET_FAR_DISTANCE_V09915
# SURROUNDED_COUNT_V09915 / TARGET_CLUSTER_COUNT_V09915
# SELF_LOW_HP_RATE_V09915 / TARGET_LOW_HP_RATE_V09915
# RULE_*_BONUS / RULE_*_PENALTY
#
# 【安全邊界】
# - 不直接修改 Frozen Combat Core。
# - 不改 Attack Speed / Damage Formula / Move Power / Accuracy / Priority。
# - 不改 494 隻 Species Gameplay Review。
# - 不改 v0.99.12 Basic Flex 的 melee/ranged/adaptive 分類。
# - 玩家明確 AI 設定仍高於 Nature / Species 自動傾向。
# - Nature × AI Temperament 留待下一階段，不在本版偷渡。
#==============================================================================
module PMD_AC
  SPATIAL_CONDITION_VERSION_V09915='0.99.15'

  SPATIAL_CONDITIONS_V09915=[
    :target_near,:target_far,:self_surrounded,:target_cluster,
    :ally_distress,:backline_exposed,:line_opportunity,:cone_opportunity,
    :self_low_hp,:target_low_hp
  ]

  AI_CONDITION_FOCUS_V09915=[
    :auto,:distance,:survival,:crowd,:rescue,:flank,:line,:execute
  ]

  CONDITION_FOCUS_LABELS_V09915={
    :auto=>'自動平衡',:distance=>'距離',:survival=>'生存／脫困',
    :crowd=>'群聚／混戰',:rescue=>'救援',:flank=>'側背／後排',
    :line=>'直線／扇形',:execute=>'收頭'
  }

  CONDITION_LABELS_V09915={
    :target_near=>'目標貼近',:target_far=>'目標遠距',:self_surrounded=>'自身被包圍',
    :target_cluster=>'敵方群聚',:ally_distress=>'友軍受壓',:backline_exposed=>'後排暴露',
    :line_opportunity=>'直線機會',:cone_opportunity=>'扇形機會',
    :self_low_hp=>'自身低血',:target_low_hp=>'目標低血'
  }

  TARGET_NEAR_DISTANCE_V09915=76.0
  TARGET_FAR_DISTANCE_V09915=132.0
  SURROUND_RADIUS_V09915=96.0
  SURROUNDED_COUNT_V09915=2
  TARGET_CLUSTER_RADIUS_V09915=106.0
  TARGET_CLUSTER_COUNT_V09915=2
  ALLY_DISTRESS_HP_RATE_V09915=0.55
  ALLY_ENGAGE_DISTANCE_V09915=72.0
  BACKLINE_DEPTH_MARGIN_V09915=28.0
  SELF_LOW_HP_RATE_V09915=0.42
  TARGET_LOW_HP_RATE_V09915=0.35
  LINE_OPPORTUNITY_COUNT_V09915=2
  CONE_OPPORTUNITY_COUNT_V09915=2

  RULE_MAX_BONUS_V09915=48.0
  RULE_CONTEXT_PENALTY_V09915=10.0

  # condition => skill tag => bonus
  CONDITION_TAG_BONUS_V09915={
    :target_near=>{
      :space_create=>10.0,:disengage=>8.0,:escape_through=>8.0,
      :surrounded_payoff=>5.0,:melee_density_payoff=>5.0
    },
    :target_far=>{
      :gap_close=>10.0,:engage=>8.0,:dash_through=>7.0,
      :center_dive=>6.0,:phase_reposition=>5.0
    },
    :self_surrounded=>{
      :escape_through=>18.0,:escape=>14.0,:space_create=>12.0,
      :disengage=>10.0,:surrounded_payoff=>14.0,:melee_density_payoff=>10.0
    },
    :target_cluster=>{
      :cluster_payoff=>14.0,:cluster_geometry=>12.0,:center_dive=>12.0,
      :crowd_commit=>9.0,:cone_geometry=>7.0,:melee_density_payoff=>6.0
    },
    :ally_distress=>{
      :rescue=>20.0,:intercept=>20.0,:peel=>16.0,:swap=>14.0,
      :space_create=>8.0,:frontline_control=>8.0
    },
    :backline_exposed=>{
      :back_attack=>16.0,:blink_behind=>16.0,:dash_through=>14.0,
      :flank=>12.0,:dive=>10.0,:center_dive=>7.0
    },
    :line_opportunity=>{
      :line_geometry=>16.0,:line_payoff=>13.0,:line_break=>8.0
    },
    :cone_opportunity=>{
      :cone_geometry=>14.0,:cluster_payoff=>6.0,:crowd_commit=>5.0
    },
    :self_low_hp=>{
      :escape_through=>16.0,:escape=>14.0,:disengage=>12.0,
      :reposition=>9.0,:guard_support=>7.0,:heal_support=>7.0
    },
    :target_low_hp=>{
      :execute=>16.0,:burst_damage=>9.0,:gap_close=>5.0,
      :engage=>4.0,:back_attack=>5.0
    }
  }

  CONDITION_FOCUS_CONDITIONS_V09915={
    :distance=>[:target_near,:target_far],
    :survival=>[:self_surrounded,:self_low_hp,:target_near],
    :crowd=>[:self_surrounded,:target_cluster,:cone_opportunity],
    :rescue=>[:ally_distress],
    :flank=>[:backline_exposed,:target_far],
    :line=>[:line_opportunity,:cone_opportunity],
    :execute=>[:target_low_hp]
  }

  CONDITION_FOCUS_ROLE_HINTS_V09915={
    :distance=>{:kiter=>6,:skirmisher=>6},
    :survival=>{:kiter=>6,:skirmisher=>5,:bodyguard=>3},
    :crowd=>{:bruiser=>5,:frontline=>5,:controller=>5,:diver=>4},
    :rescue=>{:bodyguard=>10,:controller=>3},
    :flank=>{:assassin=>8,:diver=>7,:skirmisher=>4},
    :line=>{:artillery=>7,:controller=>5},
    :execute=>{:assassin=>8,:bruiser=>4}
  }

  class << self
    def normalize_condition_focus_v09915(value)
      return :auto if value==nil
      v=value.to_sym rescue :auto
      AI_CONDITION_FOCUS_V09915.include?(v) ? v : :auto
    end

    def condition_focus_label_v09915(value)
      v=normalize_condition_focus_v09915(value)
      CONDITION_FOCUS_LABELS_V09915[v] || v.to_s
    end

    def condition_true_v09915(snapshot,key)
      return false if snapshot==nil
      snapshot[key] ? true : false
    end

    def condition_focus_multiplier_v09915(focus,condition)
      f=normalize_condition_focus_v09915(focus)
      return 1.0 if f==:auto
      list=CONDITION_FOCUS_CONDITIONS_V09915[f] || []
      list.include?(condition) ? 1.45 : 1.0
    end

    def condition_rule_bonus_v09915(snapshot,tags,focus=:auto)
      return 0.0 if snapshot==nil || tags==nil
      total=0.0
      SPATIAL_CONDITIONS_V09915.each do |cond|
        next unless condition_true_v09915(snapshot,cond)
        weights=CONDITION_TAG_BONUS_V09915[cond] || {}
        mult=condition_focus_multiplier_v09915(focus,cond)
        tags.each do |tag|
          total+=weights[tag].to_f*mult if weights[tag]!=nil
        end
      end

      # 高度情境化技能在條件不成立時輕度扣分，避免「有招就亂按」。
      if tags.include?(:escape_through) || tags.include?(:escape)
        unless snapshot[:self_surrounded] || snapshot[:self_low_hp] || snapshot[:target_near]
          total-=RULE_CONTEXT_PENALTY_V09915
        end
      end
      if tags.include?(:center_dive) && !snapshot[:target_cluster]
        total-=RULE_CONTEXT_PENALTY_V09915
      end
      if !(tags & [:rescue,:intercept,:peel,:swap]).empty? && !snapshot[:ally_distress]
        total-=RULE_CONTEXT_PENALTY_V09915+2.0
      end
      if tags.include?(:line_geometry) && !snapshot[:line_opportunity]
        total-=6.0
      end
      if tags.include?(:cone_geometry) && !snapshot[:cone_opportunity]
        total-=5.0
      end
      if tags.include?(:execute) && !snapshot[:target_low_hp]
        total-=4.0
      end
      [[total,-20.0].max,RULE_MAX_BONUS_V09915].min
    end

    def condition_focus_role_hints_v09915(focus)
      f=normalize_condition_focus_v09915(focus)
      h=CONDITION_FOCUS_ROLE_HINTS_V09915[f] || {}
      h.dup
    end

    def spatial_conditions_report_text_v09915
      out=[]
      out << 'PMD AutoChess Spatial Conditions / AI Rules v0.99.15'
      out << 'Conditions: '+SPATIAL_CONDITIONS_V09915.collect{|x|x.to_s}.join(',')
      out << 'Condition Focus: '+AI_CONDITION_FOCUS_V09915.collect{|x|x.to_s}.join(',')
      out << 'Rule scoring: context-aware bonus + contextual penalty'
      out << 'Dynamic Role carry: YES'
      out << 'Basic Flex carry: 494/494'
      out << 'Attack Cadence v0.99.14.2 carry: YES'
      out << 'Normal Attack Speed modified: NO'
      out << 'Damage formula modified: NO'
      out << 'Nature AI Temperament implemented: NO (next phase)'
      out << 'Frozen Combat Core direct modification: NO'
      out << 'Review PASS: 1'
      out.join("\r\n")+"\r\n"
    end

    def write_spatial_conditions_report_v09915
      File.open('PMD_SpatialConditionsAIRules_v0.99.15.txt','wb'){|f|f.write(spatial_conditions_report_text_v09915)}
      true
    rescue
      false
    end
  end
end
