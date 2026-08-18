#==============================================================================
# 【PMD AutoChess 中文維護說明】
# 腳本：PMD AutoChess Organic Combat SFX Palette v0.56.1
# 分類：音效
#
# 【用途／機制】
# 定義技能音效、Organic Combat SFX 與普攻命中聲。
#
# 【怎麼調整】
# 物理接觸起手通常保持安靜，聲音主要放在飛行／命中；避免 Tone/UI/Energy/Magic 類電子音。
#
# 【本腳本主要設定常數／資料表】
# - ORGANIC_SFX_FORBIDDEN_TOKENS_V0561 / ORGANIC_SFX_VOLUME_V0561 / ORGANIC_SFX_PITCH_V0561 / ORGANIC_SFX_TYPE_V0561
# - ORGANIC_SFX_SILENT_CONTACT_CAST_V0561 / ORGANIC_SFX_SLASH_MOVES_V0561 / ORGANIC_SFX_HEAVY_MOVES_V0561 / ORGANIC_SFX_BITE_MOVES_V0561
# - ORGANIC_SFX_SPIN_MOVES_V0561 / ORGANIC_SFX_MOVE_CATEGORIES_V0561 / MOVE_AUDIO_USER_OVERRIDES_V0561
#
# 【維護規則】
# - RPG Maker VX / RGSS2 / Ruby 1.8 相容。
# - instance_uid 才是 Pokémon 個體身份；Actor ID 只是容器。
# - 新增行為優先沿用既有 helper／Data 表；避免破壞已 Freeze 的舊核心。
# - 本專案新腳本也必須保留同等級的中文說明與實際範例。
#==============================================================================
#===============================================================================
# ■ PMD AutoChess Organic Combat SFX Palette v0.56.1
#-------------------------------------------------------------------------------
# User-facing audio authoring layer.
# Goal: remove generic electronic beeps/tones from ordinary Pokemon combat.
# The default palette prefers impacts, wind, water, rumble, crackle and hiss.
# Electric sounds remain electrical because, regrettably, electricity sounds
# like electricity.
#
# You may override one move without touching battle logic:
# MOVE_AUDIO_USER_OVERRIDES_V0561[:tackle] = {
#   :cast => :none,
#   :launch => :wind_whoosh,
#   :hit => :impact_heavy,
#   :volume => 90,
#   :pitch => 100
# }
#
# A stage may also be a full Audio/SE path string without extension.
# Example:
#   :hit => "PMD_SFX_Library/Pokemon_Ranger/Impact_Heavy/RGR_Impact_Heavy_001"
#===============================================================================
module PMD_AC
  ORGANIC_SFX_FORBIDDEN_TOKENS_V0561 = ["/Tone_", "/UI_", "/Energy_", "/Magic_"]

  ORGANIC_SFX_VOLUME_V0561 = {
    :cast=>54,
    :launch=>68,
    :hit=>88
  }

  # Keep pitch variation narrow.  Extreme pitch shifting was one of the main
  # reasons otherwise-usable DS effects began sounding synthetic.
  ORGANIC_SFX_PITCH_V0561 = {
    :normal=>100,:fire=>98,:water=>100,:electric=>102,:grass=>101,:ice=>103,
    :fighting=>97,:poison=>98,:ground=>95,:flying=>103,:psychic=>99,
    :bug=>101,:rock=>96,:ghost=>97,:dragon=>97,:dark=>96,:steel=>100,
    :fairy=>103,:sound=>98
  }

  # Default type palette.  These category names already exist in the packaged
  # DS sound library.  No new external asset is required.
  ORGANIC_SFX_TYPE_V0561 = {
    :normal   => {:cast=>:wind_hiss,     :launch=>:wind_whoosh,   :hit=>:impact_mid},
    :fire     => {:cast=>:crackle_burst, :launch=>:long_burst,    :hit=>:explosion_burst},
    :water    => {:cast=>:ambient_stream,:launch=>:splash_noise,  :hit=>:water_splash},
    :electric => {:cast=>:electric_crackle,:launch=>:electric_sweep,:hit=>:electric_zap},
    :grass    => {:cast=>:wind_hiss,     :launch=>:wind_whoosh,   :hit=>:impact_mid},
    :ice      => {:cast=>:wind_hiss,     :launch=>:wind_hiss,     :hit=>:impact_sharp},
    :fighting => {:cast=>:low_thump,     :launch=>:slash_swish,   :hit=>:impact_heavy},
    :poison   => {:cast=>:noise_hiss,    :launch=>:noise_hiss,    :hit=>:impact_mid},
    :ground   => {:cast=>:low_rumble,    :launch=>:rumble_impact, :hit=>:low_impact},
    :flying   => {:cast=>:wind_whoosh,   :launch=>:wind_hiss,     :hit=>:slash_swish},
    :psychic  => {:cast=>:wind_hiss,     :launch=>:noise_hiss,    :hit=>:impact_burst},
    :bug      => {:cast=>:noise_hiss,    :launch=>:slash_swish,   :hit=>:impact_sharp},
    :rock     => {:cast=>:low_rumble,    :launch=>:rumble_impact, :hit=>:impact_heavy},
    :ghost    => {:cast=>:wind_hiss,     :launch=>:noise_hiss,    :hit=>:impact_burst},
    :dragon   => {:cast=>:low_rumble,    :launch=>:wind_whoosh,   :hit=>:impact_burst},
    :dark     => {:cast=>:noise_hiss,    :launch=>:wind_whoosh,   :hit=>:impact_heavy},
    :steel    => {:cast=>:low_thump,     :launch=>:slash_swish,   :hit=>:impact_sharp},
    :fairy    => {:cast=>:wind_hiss,     :launch=>:wind_whoosh,   :hit=>:impact_sharp},
    :sound    => {:cast=>:low_rumble,    :launch=>:wind_hiss,     :hit=>:impact_burst}
  }

  # Ordinary contact attacks do not need a separate pre-cast beep.  Their
  # approach/weapon swish and impact carry the readable audio information.
  ORGANIC_SFX_SILENT_CONTACT_CAST_V0561 = true

  ORGANIC_SFX_SLASH_MOVES_V0561 = [
    :slash,:night_slash,:leaf_blade,:psycho_cut,:fury_cutter,:x_scissor,
    :false_swipe,:karate_chop,:guillotine,:cut,:sacred_sword,:aerial_ace
  ]
  ORGANIC_SFX_HEAVY_MOVES_V0561 = [
    :giga_impact,:take_down,:double_edge,:body_slam,:headbutt,:head_smash,
    :wood_hammer,:flare_blitz,:brave_bird,:volt_tackle,:wild_charge,
    :superpower,:close_combat,:dragon_rush,:head_charge,:v_create
  ]
  ORGANIC_SFX_BITE_MOVES_V0561 = [
    :bite,:crunch,:super_fang,:poison_fang,:fire_fang,:ice_fang,
    :thunder_fang,:bug_bite
  ]
  ORGANIC_SFX_SPIN_MOVES_V0561 = [:rapid_spin,:rollout,:steamroller,:gyro_ball]

  # Curated exceptions for moves where type-only routing sounds obviously wrong.
  ORGANIC_SFX_MOVE_CATEGORIES_V0561 = {
    :snore       => {:cast=>:low_rumble,:launch=>:wind_hiss,:hit=>:impact_burst},
    :wish        => {:cast=>:wind_hiss,:launch=>nil,:hit=>nil},
    :tickle      => {:cast=>:wind_whoosh,:launch=>nil,:hit=>:wind_hiss},
    :psycho_shift=> {:cast=>:wind_hiss,:launch=>:noise_hiss,:hit=>:impact_burst},
    :trick       => {:cast=>:wind_whoosh,:launch=>nil,:hit=>:impact_sharp},
    :toxic       => {:cast=>:noise_hiss,:launch=>:noise_hiss,:hit=>:impact_mid},
    :spikes      => {:cast=>:low_rumble,:launch=>nil,:hit=>:low_impact},
    :metronome   => {:cast=>:wind_whoosh,:launch=>nil,:hit=>:impact_sharp},
    :horn_drill  => {:cast=>:low_rumble,:launch=>:wind_whoosh,:hit=>:impact_heavy},
    :giga_impact => {:cast=>:low_rumble,:launch=>:wind_whoosh,:hit=>:impact_burst},
    :final_gambit=> {:cast=>:low_rumble,:launch=>:wind_whoosh,:hit=>:impact_burst},
    :belly_drum  => {:cast=>:low_thump,:launch=>nil,:hit=>:low_thump},
    :tri_attack  => {:cast=>:wind_hiss,:launch=>:wind_whoosh,:hit=>:impact_burst},
    :sky_attack  => {:cast=>:wind_whoosh,:launch=>:wind_hiss,:hit=>:impact_burst},
    :razor_wind  => {:cast=>:wind_whoosh,:launch=>:wind_hiss,:hit=>:slash_swish},
    :power_swap  => {:cast=>:wind_hiss,:launch=>nil,:hit=>:impact_sharp},
    :outrage     => {:cast=>:low_rumble,:launch=>:wind_whoosh,:hit=>:impact_heavy},
    :mimic       => {:cast=>:wind_hiss,:launch=>nil,:hit=>:impact_sharp},
    :magic_coat  => {:cast=>:wind_hiss,:launch=>nil,:hit=>:impact_sharp},
    :guard_swap  => {:cast=>:wind_hiss,:launch=>nil,:hit=>:impact_sharp},
    :eruption    => {:cast=>:low_rumble,:launch=>:long_burst,:hit=>:explosion_burst},
    :acupressure => {:cast=>:wind_hiss,:launch=>nil,:hit=>:impact_sharp},
    :venoshock   => {:cast=>:noise_hiss,:launch=>:noise_hiss,:hit=>:impact_burst},
    :super_fang  => {:cast=>nil,:launch=>:wind_whoosh,:hit=>:impact_sharp},
    :stealth_rock=> {:cast=>:low_rumble,:launch=>:rumble_impact,:hit=>:impact_heavy},
    :smack_down  => {:cast=>:low_rumble,:launch=>:wind_whoosh,:hit=>:rumble_impact},
    :cotton_guard=> {:cast=>:wind_hiss,:launch=>nil,:hit=>nil}
  }

  # User edits belong here.  Values may be category symbols, :none, nil, or a
  # direct Audio/SE path string (without extension).  This hash intentionally
  # starts empty so later updates never overwrite the user's choices.
  MOVE_AUDIO_USER_OVERRIDES_V0561 = {
  }
end
