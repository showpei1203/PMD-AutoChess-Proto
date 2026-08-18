#==============================================================================
# 【PMD AutoChess 中文維護說明】
# 腳本：PMD AutoChess Skill Special Data v0.34
# 分類：技能視覺
#
# 【用途／機制】
# 定義技能 Beam／Projectile／Impact 等映射與特效資產。
#
# 【怎麼調整】
# 新增視覺時先建立資料映射，再讓 Runtime 讀取；Projectile 與 Target FX 的 anchor 規則不要混用。
#
# 【本腳本主要設定常數／資料表】
# - SKILL_SPECIAL_II_VISUAL_V034 / SKILL_SPECIAL_II_RGS3_META_V034 / SKILL_SPECIAL_II_AUDIO_V034 / SKILL_SPECIAL_II_MANIFEST_V034
#
# 【維護規則】
# - RPG Maker VX / RGSS2 / Ruby 1.8 相容。
# - instance_uid 才是 Pokémon 個體身份；Actor ID 只是容器。
# - 新增行為優先沿用既有 helper／Data 表；避免破壞已 Freeze 的舊核心。
# - 本專案新腳本也必須保留同等級的中文說明與實際範例。
#==============================================================================
#==============================================================================
# ■ PMD AutoChess Skill Specialization Data v0.34
#==============================================================================
module PMD_AC
  SKILL_SPECIAL_II_VISUAL_V034 = {
    :air_slash => {:kind=>:wind_slashes,:primary=>"RGS3_ATK_130",:secondary=>"RGS3_ATK_147",:anchor=>:target,:label=>"AIR SLASH"},
    :aura_sphere => {:kind=>:aura_burst,:primary=>"RGS3_ATK_192",:secondary=>"RGS3_ATK_221",:anchor=>:target,:label=>"AURA SPHERE"},
    :bulk_up => {:kind=>:power_aura,:primary=>"RGS3_ATK_237",:secondary=>"RGS3_ATK_239",:anchor=>:user,:label=>"BULK UP"},
    :calm_mind => {:kind=>:mind_aura,:primary=>"RGS3_ATK_215",:secondary=>"RGS3_ATK_195",:anchor=>:user,:label=>"CALM MIND"},
    :close_combat => {:kind=>:combat_combo,:primary=>"RGS3_ATK_236",:secondary=>"RGS3_ATK_239",:anchor=>:target,:label=>"CLOSE COMBAT"},
    :dragon_dance => {:kind=>:dragon_dance,:primary=>"RGS3_ATK_177",:secondary=>"RGS3_ATK_202",:anchor=>:user,:label=>"DRAGON DANCE"},
    :fire_blast => {:kind=>:fire_burst,:primary=>"RGS3_ATK_174",:secondary=>"RGS3_ATK_222",:anchor=>:target,:label=>"FIRE BLAST"},
    :nasty_plot => {:kind=>:dark_focus,:primary=>"RGS3_ATK_206",:secondary=>"RGS3_ATK_197",:anchor=>:user,:label=>"NASTY PLOT"},
    :psychic => {:kind=>:psychic_focus,:primary=>"RGS3_ATK_215",:secondary=>"RGS3_ATK_172",:anchor=>:target,:label=>"PSYCHIC"},
    :shadow_ball => {:kind=>:shadow_burst,:primary=>"RGS3_ATK_170",:secondary=>"RGS3_ATK_186",:anchor=>:target,:label=>"SHADOW BALL"},
    :sludge_bomb => {:kind=>:sludge_burst,:primary=>"RGS3_ATK_158",:secondary=>"RGS3_ATK_197",:anchor=>:target,:label=>"SLUDGE BOMB"},
    :x_scissor => {:kind=>:x_slash,:primary=>"RGS3_ATK_238",:secondary=>"RGS3_ATK_239",:anchor=>:target,:label=>"X-SCISSOR"},
  }
  SKILL_SPECIAL_II_RGS3_META_V034 = {
    "RGS3_ATK_130" => {:width=>960,:height=>192,:cols=>5,:rows=>1,:cells_csv=>"0,1",:frames=>2,:magenta_remaining=>0},
    "RGS3_ATK_147" => {:width=>960,:height=>192,:cols=>5,:rows=>1,:cells_csv=>"0,1,2,3",:frames=>4,:magenta_remaining=>0},
    "RGS3_ATK_158" => {:width=>960,:height=>192,:cols=>5,:rows=>1,:cells_csv=>"0,1,2,3",:frames=>4,:magenta_remaining=>0},
    "RGS3_ATK_170" => {:width=>960,:height=>192,:cols=>5,:rows=>1,:cells_csv=>"0",:frames=>1,:magenta_remaining=>0},
    "RGS3_ATK_172" => {:width=>960,:height=>192,:cols=>5,:rows=>1,:cells_csv=>"0,1,2",:frames=>3,:magenta_remaining=>0},
    "RGS3_ATK_174" => {:width=>960,:height=>192,:cols=>5,:rows=>1,:cells_csv=>"0,1,2,3",:frames=>4,:magenta_remaining=>0},
    "RGS3_ATK_177" => {:width=>960,:height=>576,:cols=>5,:rows=>3,:cells_csv=>"0,1,2,3,4,5,6,7,8,9,10,11",:frames=>12,:magenta_remaining=>0},
    "RGS3_ATK_186" => {:width=>960,:height=>192,:cols=>5,:rows=>1,:cells_csv=>"0,1,2,3",:frames=>4,:magenta_remaining=>0},
    "RGS3_ATK_192" => {:width=>960,:height=>192,:cols=>5,:rows=>1,:cells_csv=>"0",:frames=>1,:magenta_remaining=>0},
    "RGS3_ATK_195" => {:width=>960,:height=>192,:cols=>5,:rows=>1,:cells_csv=>"0,1,2",:frames=>3,:magenta_remaining=>0},
    "RGS3_ATK_197" => {:width=>960,:height=>192,:cols=>5,:rows=>1,:cells_csv=>"0,1,2,3",:frames=>4,:magenta_remaining=>0},
    "RGS3_ATK_202" => {:width=>960,:height=>192,:cols=>5,:rows=>1,:cells_csv=>"0,1,2,3",:frames=>4,:magenta_remaining=>0},
    "RGS3_ATK_206" => {:width=>960,:height=>192,:cols=>5,:rows=>1,:cells_csv=>"0",:frames=>1,:magenta_remaining=>0},
    "RGS3_ATK_215" => {:width=>960,:height=>192,:cols=>5,:rows=>1,:cells_csv=>"0,1,2,3",:frames=>4,:magenta_remaining=>0},
    "RGS3_ATK_221" => {:width=>960,:height=>192,:cols=>5,:rows=>1,:cells_csv=>"0,1,2,3",:frames=>4,:magenta_remaining=>0},
    "RGS3_ATK_222" => {:width=>960,:height=>192,:cols=>5,:rows=>1,:cells_csv=>"0,1,2,3",:frames=>4,:magenta_remaining=>0},
    "RGS3_ATK_236" => {:width=>960,:height=>192,:cols=>5,:rows=>1,:cells_csv=>"0",:frames=>1,:magenta_remaining=>0},
    "RGS3_ATK_237" => {:width=>960,:height=>192,:cols=>5,:rows=>1,:cells_csv=>"0",:frames=>1,:magenta_remaining=>0},
    "RGS3_ATK_238" => {:width=>960,:height=>192,:cols=>5,:rows=>1,:cells_csv=>"0",:frames=>1,:magenta_remaining=>0},
    "RGS3_ATK_239" => {:width=>960,:height=>192,:cols=>5,:rows=>1,:cells_csv=>"0",:frames=>1,:magenta_remaining=>0},
  }
  SKILL_SPECIAL_II_AUDIO_V034 = {
    :air_slash => {:cast_cat=>:wind_whoosh,:launch_cat=>:wind_hiss,:hit_cat=>:slash_swish,:audio_style=>:flying},
    :aura_sphere => {:cast_cat=>:energy_charge,:launch_cat=>:energy_beam,:hit_cat=>:impact_burst,:audio_style=>:fighting},
    :bulk_up => {:cast_cat=>:energy_rise,:launch_cat=>nil,:hit_cat=>:low_thump,:audio_style=>:fighting},
    :calm_mind => {:cast_cat=>:magic_chime,:launch_cat=>nil,:hit_cat=>:tone_sustain,:audio_style=>:psychic},
    :close_combat => {:cast_cat=>:low_thump,:launch_cat=>nil,:hit_cat=>:impact_heavy,:audio_style=>:fighting},
    :dragon_dance => {:cast_cat=>:energy_rise,:launch_cat=>nil,:hit_cat=>:magic_sustain,:audio_style=>:dragon},
    :fire_blast => {:cast_cat=>:crackle_burst,:launch_cat=>:long_burst,:hit_cat=>:explosion_burst,:audio_style=>:fire},
    :nasty_plot => {:cast_cat=>:tone_low_hum,:launch_cat=>nil,:hit_cat=>:magic_sustain,:audio_style=>:dark},
    :psychic => {:cast_cat=>:magic_chime,:launch_cat=>:magic_sustain,:hit_cat=>:impact_burst,:audio_style=>:psychic},
    :shadow_ball => {:cast_cat=>:tone_low_hum,:launch_cat=>:magic_sustain,:hit_cat=>:impact_burst,:audio_style=>:ghost},
    :sludge_bomb => {:cast_cat=>:low_thump,:launch_cat=>:noise_hiss,:hit_cat=>:impact_mid,:audio_style=>:poison},
    :x_scissor => {:cast_cat=>:slash_swish,:launch_cat=>nil,:hit_cat=>:slash_swish,:audio_style=>:bug},
  }
  SKILL_SPECIAL_II_MANIFEST_V034 = {
    :schema_version=>"1.0",
    :content_version=>"0.34.0",
    :base_version=>"0.33.1",
    :global_rgs3_scale=>0.60,
    :new_special_count=>12,
    :cumulative_special_count=>21,
    :new_asset_meta_count=>20,
    :rgs3_sheet_count=>256,
    :opaque_magenta_remaining=>0,
    :runtime_move_total=>222,
    :runtime_specialized_cumulative=>21,
    :runtime_checksum32=>226969796,
  }
end
