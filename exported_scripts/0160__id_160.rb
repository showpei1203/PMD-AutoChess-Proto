#==============================================================================
# 【PMD AutoChess 中文維護說明】
# 腳本：PMD AutoChess Skill Special Data v0.33
# 分類：技能視覺
#
# 【用途／機制】
# 定義技能 Beam／Projectile／Impact 等映射與特效資產。
#
# 【怎麼調整】
# 新增視覺時先建立資料映射，再讓 Runtime 讀取；Projectile 與 Target FX 的 anchor 規則不要混用。
#
# 【本腳本主要設定常數／資料表】
# - SKILL_SPECIAL_VISUAL_V033 / SKILL_SPECIAL_RGS3_META_V033 / SKILL_SPECIAL_AUDIO_V033 / SKILL_SPECIAL_MANIFEST_V033
#
# 【維護規則】
# - RPG Maker VX / RGSS2 / Ruby 1.8 相容。
# - instance_uid 才是 Pokémon 個體身份；Actor ID 只是容器。
# - 新增行為優先沿用既有 helper／Data 表；避免破壞已 Freeze 的舊核心。
# - 本專案新腳本也必須保留同等級的中文說明與實際範例。
#==============================================================================
#==============================================================================
# ■ PMD AutoChess Skill Specialization Data v0.33
#==============================================================================
module PMD_AC
  SKILL_SPECIAL_VISUAL_V033 = {
    :blizzard => {:kind=>:blizzard_sweep,:primary=>"RGS3_ATK_147",:secondary=>"RGS3_ATK_221",:anchor=>:target,:label=>"BLIZZARD"},
    :dark_pulse => {:kind=>:pulse_ring,:primary=>"RGS3_ATK_215",:secondary=>nil,:anchor=>:user,:label=>"DARK PULSE"},
    :dragon_pulse => {:kind=>:pulse_ring,:primary=>"RGS3_ATK_177",:secondary=>nil,:anchor=>:target,:label=>"DRAGON PULSE"},
    :hyper_voice => {:kind=>:pulse_ring,:primary=>"RGS3_ATK_190",:secondary=>nil,:anchor=>:user,:label=>"HYPER VOICE"},
    :leaf_storm => {:kind=>:leaf_swirl,:primary=>"RGS3_ATK_199",:secondary=>"RGS3_ATK_063",:anchor=>:target,:label=>"LEAF STORM"},
    :recover => {:kind=>:recover_sparkle,:primary=>"RGS3_ATK_195",:secondary=>nil,:anchor=>:user,:label=>"RECOVER"},
    :rock_slide => {:kind=>:rock_fall,:primary=>"RGS3_ATK_149",:secondary=>"RGS3_ATK_240",:anchor=>:target,:label=>"ROCK SLIDE"},
    :swords_dance => {:kind=>:cross_slash,:primary=>"RGS3_ATK_238",:secondary=>"RGS3_ATK_239",:anchor=>:user,:label=>"SWORDS DANCE"},
    :thunder => {:kind=>:thunder_strike,:primary=>"RGS3_ATK_208",:secondary=>"RGS3_ATK_221",:anchor=>:target,:label=>"THUNDER"},
  }
  SKILL_SPECIAL_RGS3_META_V033 = {
    "RGS3_ATK_063" => {:width=>960,:height=>192,:cols=>5,:rows=>1,:cells_csv=>"0",:frames=>1,:magenta_removed=>0,:magenta_remaining=>0},
    "RGS3_ATK_147" => {:width=>960,:height=>192,:cols=>5,:rows=>1,:cells_csv=>"0,1,2,3",:frames=>4,:magenta_removed=>0,:magenta_remaining=>0},
    "RGS3_ATK_149" => {:width=>960,:height=>192,:cols=>5,:rows=>1,:cells_csv=>"0",:frames=>1,:magenta_removed=>0,:magenta_remaining=>0},
    "RGS3_ATK_177" => {:width=>960,:height=>576,:cols=>5,:rows=>3,:cells_csv=>"0,1,2,3,4,5,6,7,8,9,10,11",:frames=>12,:magenta_removed=>0,:magenta_remaining=>0},
    "RGS3_ATK_190" => {:width=>960,:height=>192,:cols=>5,:rows=>1,:cells_csv=>"0,1,2,3",:frames=>4,:magenta_removed=>0,:magenta_remaining=>0},
    "RGS3_ATK_195" => {:width=>960,:height=>192,:cols=>5,:rows=>1,:cells_csv=>"0,1,2",:frames=>3,:magenta_removed=>0,:magenta_remaining=>0},
    "RGS3_ATK_199" => {:width=>960,:height=>192,:cols=>5,:rows=>1,:cells_csv=>"0,1,2,3",:frames=>4,:magenta_removed=>0,:magenta_remaining=>0},
    "RGS3_ATK_208" => {:width=>960,:height=>192,:cols=>5,:rows=>1,:cells_csv=>"0,1,2",:frames=>3,:magenta_removed=>0,:magenta_remaining=>0},
    "RGS3_ATK_215" => {:width=>960,:height=>192,:cols=>5,:rows=>1,:cells_csv=>"0,1,2,3",:frames=>4,:magenta_removed=>0,:magenta_remaining=>0},
    "RGS3_ATK_221" => {:width=>960,:height=>192,:cols=>5,:rows=>1,:cells_csv=>"0,1,2,3",:frames=>4,:magenta_removed=>0,:magenta_remaining=>0},
    "RGS3_ATK_238" => {:width=>960,:height=>192,:cols=>5,:rows=>1,:cells_csv=>"0",:frames=>1,:magenta_removed=>0,:magenta_remaining=>0},
    "RGS3_ATK_239" => {:width=>960,:height=>192,:cols=>5,:rows=>1,:cells_csv=>"0",:frames=>1,:magenta_removed=>0,:magenta_remaining=>0},
    "RGS3_ATK_240" => {:width=>960,:height=>192,:cols=>5,:rows=>1,:cells_csv=>"0",:frames=>1,:magenta_removed=>0,:magenta_remaining=>0},
  }
  SKILL_SPECIAL_AUDIO_V033 = {
    :blizzard => {:cast_cat=>:magic_chime,:launch_cat=>:wind_hiss,:hit_cat=>:impact_sharp,:audio_style=>:ice},
    :dark_pulse => {:cast_cat=>:tone_low_hum,:launch_cat=>:magic_sustain,:hit_cat=>:impact_burst,:audio_style=>:dark},
    :dragon_pulse => {:cast_cat=>:energy_charge,:launch_cat=>:energy_beam,:hit_cat=>:impact_burst,:audio_style=>:dragon},
    :hyper_voice => {:cast_cat=>:tone_high_sustain,:launch_cat=>nil,:hit_cat=>:tone_high_sustain,:audio_style=>:sound},
    :leaf_storm => {:cast_cat=>:energy_rise,:launch_cat=>:wind_whoosh,:hit_cat=>:slash_swish,:audio_style=>:grass},
    :recover => {:cast_cat=>:magic_chime,:launch_cat=>nil,:hit_cat=>:tone_sustain,:audio_style=>:psychic},
    :rock_slide => {:cast_cat=>:low_rumble,:launch_cat=>nil,:hit_cat=>:rumble_impact,:audio_style=>:rock},
    :swords_dance => {:cast_cat=>:slash_swish,:launch_cat=>nil,:hit_cat=>:slash_swish,:audio_style=>:steel},
    :thunder => {:cast_cat=>:energy_charge,:launch_cat=>nil,:hit_cat=>:electric_crackle,:audio_style=>:electric},
  }
  SKILL_SPECIAL_MANIFEST_V033 = {
    :schema_version=>"1.0",
    :content_version=>"0.33.0",
    :base_version=>"0.32",
    :special_visual_count=>9,
    :special_audio_count=>9,
    :special_asset_count=>13,
    :rgs3_sheet_count=>256,
    :sfx_alias_count=>50,
    :sfx_alias_missing=>0,
    :opaque_magenta_remaining=>0,
    :magenta_removed_on_import=>0,
    :impact_first_frame_wait=>3,
    :impact_last_frame_hold=>6,
    :runtime_checksum32=>1740726031,
  }
end
