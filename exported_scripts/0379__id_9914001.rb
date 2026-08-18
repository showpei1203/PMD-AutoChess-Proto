# encoding: UTF-8
#==============================================================================
# 【PMD AutoChess 中文維護說明】
# 腳本：PMD AutoChess Spatial Framework Expansion Data v0.99.14
# 分類：空間技能統一框架／戰場幾何／AI 位移意圖資料層
# RPG Maker VX / RGSS2 / Ruby 1.8 compatible
#==============================================================================
# 【用途】
# 延續 v0.91.4 Spatial Move、v0.99.12 Basic Flex、v0.99.13 Dynamic Role，
# 將「拉近／後撤／穿越／逃離包圍／突入混戰／救援」統一成可供技能與 AI
# 共用的 Spatial Vocabulary。Species 只提供天生傾向；玩家可用 Active Moves
# 與 AI Strategy 決定是否切後排、打混戰、保護友軍或游擊撤退。
#
# 【主要設定項】
# SPATIAL_KINDS_V09914：正式空間行為語彙。
# SPATIAL_MOVE_EXTENSIONS_V09914：本版新增的技能空間延伸。
# AI_SPATIAL_INTENTS_V09914：玩家可選的位移意圖。
# GEOMETRY_*：Line / Cone / Surround 的 AI 幾何判定參數。
#
# 【本版新增 Spatial Intent】
# :escape  優先脫離包圍／穿過混戰離場。
# :rescue  優先換位、Peel、Intercept、保護危急友軍。
# :crowd   願意主動進入多人混戰，重視近身密度收益。
# :flank   重視穿越戰線、背擊與側擊。
#
# 【本版示範技能】
# Rapid Spin / Teleport：escape_through，可無視單位碰撞穿越混戰脫離。
# Acrobatics：dash_through，穿過目標形成背後站位。
# Brave Bird / Flare Blitz：center_dive，在命中後往目標附近敵群重心壓進。
# 既有 Quick Attack / U-turn / Water Gun / Vine Whip / Ally Switch 等仍保留。
#
# 【戰場幾何】
# :line_geometry       評估使用者→目標方向上的穿透價值。
# :cone_geometry       評估前方扇形內敵人數。
# :surrounded_payoff   評估使用者近身敵人密度。
# :cluster_geometry    延續群聚技能的目標價值。
#
# 這些首先影響 AI 選技／位移價值，不在本版額外修改 Move Power。
#
# 【事件／腳本呼叫範例】
# pokemon.set_ai_option(:spatial_intent, :escape)
# pokemon.set_ai_option(:spatial_intent, :crowd)
# PMD_AC.spatial_extension_unified_v09914(:rapid_spin)
# PMD_AC.move_tactical_tags_v09914(:earthquake)
#
# 【可調參數】
# SURROUND_RADIUS_V09914 / LINE_WIDTH_V09914 / CONE_RANGE_V09914
# 只影響 AI 幾何評估，不直接更改傷害。
#
# 【安全邊界】
# - 不直接修改 Frozen Combat Core。
# - 不改 Base Stats / IV / Nature / Damage Formula / Move Power / Accuracy。
# - 不把 Ranged 自動改脆；體質仍由 Pokémon 種族值主導。
# - 既有 494/494 Gameplay Review、Basic Flex、Dynamic Role 全部保留。
#==============================================================================
module PMD_AC
  SPATIAL_FRAMEWORK_VERSION_V09914='0.99.14'

  SPATIAL_KINDS_V09914=[
    :advance,:retreat,:push,:pull,:dash_through,:escape_through,
    :center_dive,:intercept,:swap,:knock_aside,:phase_reposition,:blink_behind
  ]

  AI_SPATIAL_INTENTS_V09914=[
    :balanced,:engage,:disengage,:peel,:dive,:control,
    :escape,:rescue,:crowd,:flank
  ]

  # 讓既有 valid_ai_option? / AI Strategy UI 自動吃到新版選項。
  remove_const(:AI_SPATIAL_INTENTS_V09912) if const_defined?(:AI_SPATIAL_INTENTS_V09912)
  AI_SPATIAL_INTENTS_V09912=AI_SPATIAL_INTENTS_V09914

  SPATIAL_INTENT_LABELS_V09914={
    :escape=>'脫困',:rescue=>'救援',:crowd=>'混戰',:flank=>'繞側／背擊'
  }

  SPATIAL_MOVE_EXTENSIONS_V09914={
    :rapid_spin=>{:kind=>:escape_through,:distance=>58.0,:frames=>7},
    :teleport=>{:kind=>:escape_through,:distance=>72.0,:frames=>8},
    :acrobatics=>{:kind=>:dash_through,:distance_past=>34.0,:frames=>7},
    :brave_bird=>{:kind=>:center_dive,:distance=>54.0,:frames=>7,:cluster_radius=>110.0},
    :flare_blitz=>{:kind=>:center_dive,:distance=>48.0,:frames=>7,:cluster_radius=>104.0}
  }

  MOVE_TAG_ADDITIONS_V09914={
    :rapid_spin=>[:escape,:escape_through,:space_create,:surrounded_payoff],
    :teleport=>[:escape,:escape_through,:reposition],
    :acrobatics=>[:dive,:dash_through,:flank,:back_attack],
    :brave_bird=>[:dive,:center_dive,:crowd_commit,:melee_density_payoff],
    :flare_blitz=>[:dive,:center_dive,:crowd_commit,:melee_density_payoff],
    :ally_switch=>[:rescue,:swap,:intercept,:peel],
    :follow_me=>[:rescue,:intercept,:peel,:frontline_control],
    :rage_powder=>[:rescue,:intercept,:peel,:frontline_control],
    :dragon_tail=>[:line_break,:knock_aside,:peel],
    :circle_throw=>[:line_break,:knock_aside,:peel],
    :roar=>[:line_break,:peel],
    :whirlwind=>[:line_break,:peel]
  }

  CONE_GEOMETRY_MOVES_V09914=[
    :heat_wave,:icy_wind,:snarl,:hyper_voice,:hurricane,:gust
  ]
  SURROUND_PAYOFF_MOVES_V09914=[
    :earthquake,:discharge,:lava_plume,:sludge_wave,:surf,
    :bulldoze,:magnitude,:explosion,:self_destruct,:rapid_spin
  ]

  SURROUND_RADIUS_V09914=92.0
  LINE_WIDTH_V09914=30.0
  LINE_RANGE_V09914=190.0
  CONE_RANGE_V09914=170.0
  CONE_HALF_ANGLE_DEG_V09914=32.0

  ROLE_SPATIAL_BONUS_V09914={
    :bodyguard=>{:intercept=>12,:rescue=>14,:swap=>10,:peel=>8},
    :controller=>{:line_break=>8,:knock_aside=>8,:cluster_geometry=>6},
    :assassin=>{:flank=>12,:dash_through=>10,:back_attack=>8},
    :diver=>{:center_dive=>14,:crowd_commit=>10,:dash_through=>10,:flank=>8},
    :skirmisher=>{:escape_through=>12,:reposition=>8,:space_create=>6},
    :kiter=>{:escape_through=>12,:space_create=>8},
    :frontline=>{:surrounded_payoff=>10,:crowd_commit=>8},
    :bruiser=>{:surrounded_payoff=>10,:crowd_commit=>8}
  }

  class << self
    def canonical_spatial_key_v09914(move_key)
      return nil if move_key==nil
      move_key.to_s.downcase.gsub(/^mv_/,'').gsub(/[^a-z0-9]+/,'_').to_sym
    end

    def spatial_extension_v09914(move_key)
      k=canonical_spatial_key_v09914(move_key)
      p=k==nil ? nil : SPATIAL_MOVE_EXTENSIONS_V09914[k]
      p==nil ? nil : p.dup
    end

    def spatial_extension_unified_v09914(move_key)
      p=spatial_extension_v09914(move_key)
      return p if p!=nil
      if respond_to?(:spatial_extension_v09912)
        p=spatial_extension_v09912(move_key)
        return p if p!=nil
      end
      if respond_to?(:spatial_move_extension_v0914)
        p=spatial_move_extension_v0914(move_key)
        return p if p!=nil
      end
      nil
    end

    def move_tactical_tags_v09914(move_key,data=nil)
      k=canonical_spatial_key_v09914(move_key)
      out=[]
      if respond_to?(:move_tactical_tags_v09913)
        out=move_tactical_tags_v09913(k,data).dup
      elsif respond_to?(:skill_tactical_tags_v09912)
        out=skill_tactical_tags_v09912(k,data).dup
      end
      add=MOVE_TAG_ADDITIONS_V09914[k] || []
      add.each{|t|out.push(t)}
      out.push(:cone_geometry) if CONE_GEOMETRY_MOVES_V09914.include?(k)
      out.push(:surrounded_payoff) if SURROUND_PAYOFF_MOVES_V09914.include?(k)
      out.push(:line_geometry) if out.include?(:line_payoff)
      out.push(:cluster_geometry) if out.include?(:cluster_payoff)
      out.uniq
    end

    def spatial_intent_bonus_extra_v09914(intent,tags)
      i=(intent || :balanced).to_sym
      t=tags || []
      case i
      when :escape
        return 18.0 if !(t & [:escape_through,:escape,:disengage,:phase_reposition]).empty?
      when :rescue
        return 18.0 if !(t & [:rescue,:intercept,:swap,:peel]).empty?
      when :crowd
        return 16.0 if !(t & [:center_dive,:crowd_commit,:surrounded_payoff,:melee_density_payoff]).empty?
      when :flank
        return 16.0 if !(t & [:flank,:dash_through,:blink_behind,:back_attack]).empty?
      end
      0.0
    end

    def role_spatial_bonus_v09914(role,tags)
      w=ROLE_SPATIAL_BONUS_V09914[role] || {}
      total=0.0
      (tags || []).each{|tag|total+=w[tag].to_f if w[tag]!=nil}
      total
    end
  end
end
