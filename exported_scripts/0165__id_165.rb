#==============================================================================
# 【PMD AutoChess 中文維護說明】
# 腳本：PMD AutoChess Field Effect Data v0.35
# 分類：場地／空間效果
#
# 【用途／機制】
# 定義 Field/Terrain 的效果、範圍、視覺圓盤與 AI 位置評分。
#
# 【怎麼調整】
# 新增場地時同時確認 Effect、Spatial 與 AI 三層；只加數值不加空間資料會讓 AI 不知道場地在哪。
#
# 【本腳本主要設定常數／資料表】
# - FIELD_EFFECT_MOVE_V035 / FIELD_EFFECT_VISUAL_V035 / FIELD_EFFECT_AUDIO_V035 / FIELD_EFFECT_MANIFEST_V035
#
# 【維護規則】
# - RPG Maker VX / RGSS2 / Ruby 1.8 相容。
# - instance_uid 才是 Pokémon 個體身份；Actor ID 只是容器。
# - 新增行為優先沿用既有 helper／Data 表；避免破壞已 Freeze 的舊核心。
# - 本專案新腳本也必須保留同等級的中文說明與實際範例。
#==============================================================================
#==============================================================================
# ■ PMD AutoChess Field Effect Data v0.35
#==============================================================================
module PMD_AC
  FIELD_EFFECT_MOVE_V035 = {
    :gravity => {:schema_version=>"1.0",:content_version=>"0.35.0",:canon_snapshot=>"2026-08-08",:ruleset=>"black_white",:move_key=>:gravity,:runtime_skill_key=>:mv_gravity,:name=>"重力",:name_en=>"Gravity",:type=>:psychic,:category=>:status,:target=>"entire_field",:target_type=>:self_targeted,:delivery=>:instant,:range_px=>0.00,:policy=>:self,:behavior_status=>:implemented_field_v035,:priority=>0,:accuracy=>nil,:effects=>[{"type"=>:field_effect,"key"=>:gravity,"scope"=>:global,"turns"=>5}],:field_key=>:gravity,:field_scope=>:global,:field_turns=>5,:visual_kind=>:field_disc,:visual_style=>:gravity},
    :light_screen => {:schema_version=>"1.0",:content_version=>"0.35.0",:canon_snapshot=>"2026-08-08",:ruleset=>"black_white",:move_key=>:light_screen,:runtime_skill_key=>:mv_light_screen,:name=>"光牆",:name_en=>"Light Screen",:type=>:psychic,:category=>:status,:target=>"users_field",:target_type=>:self_targeted,:delivery=>:instant,:range_px=>0.00,:policy=>:self,:behavior_status=>:implemented_field_v035,:priority=>0,:accuracy=>nil,:effects=>[{"type"=>:field_effect,"key"=>:light_screen,"scope"=>:user_side,"turns"=>5}],:field_key=>:light_screen,:field_scope=>:user_side,:field_turns=>5,:visual_kind=>:field_disc,:visual_style=>:light_screen},
    :lucky_chant => {:schema_version=>"1.0",:content_version=>"0.35.0",:canon_snapshot=>"2026-08-08",:ruleset=>"black_white",:move_key=>:lucky_chant,:runtime_skill_key=>:mv_lucky_chant,:name=>"幸運咒語",:name_en=>"Lucky Chant",:type=>:normal,:category=>:status,:target=>"users_field",:target_type=>:self_targeted,:delivery=>:instant,:range_px=>0.00,:policy=>:self,:behavior_status=>:implemented_field_v035,:priority=>0,:accuracy=>nil,:effects=>[{"type"=>:field_effect,"key"=>:lucky_chant,"scope"=>:user_side,"turns"=>5}],:field_key=>:lucky_chant,:field_scope=>:user_side,:field_turns=>5,:visual_kind=>:field_disc,:visual_style=>:lucky_chant},
    :magic_room => {:schema_version=>"1.0",:content_version=>"0.35.0",:canon_snapshot=>"2026-08-08",:ruleset=>"black_white",:move_key=>:magic_room,:runtime_skill_key=>:mv_magic_room,:name=>"魔法空間",:name_en=>"Magic Room",:type=>:psychic,:category=>:status,:target=>"entire_field",:target_type=>:self_targeted,:delivery=>:instant,:range_px=>0.00,:policy=>:self,:behavior_status=>:implemented_field_v035,:priority=>-7,:accuracy=>nil,:effects=>[{"type"=>:field_effect,"key"=>:magic_room,"scope"=>:global,"turns"=>5}],:field_key=>:magic_room,:field_scope=>:global,:field_turns=>5,:visual_kind=>:field_disc,:visual_style=>:magic_room},
    :mist => {:schema_version=>"1.0",:content_version=>"0.35.0",:canon_snapshot=>"2026-08-08",:ruleset=>"black_white",:move_key=>:mist,:runtime_skill_key=>:mv_mist,:name=>"白霧",:name_en=>"Mist",:type=>:ice,:category=>:status,:target=>"users_field",:target_type=>:self_targeted,:delivery=>:instant,:range_px=>0.00,:policy=>:self,:behavior_status=>:implemented_field_v035,:priority=>0,:accuracy=>nil,:effects=>[{"type"=>:field_effect,"key"=>:mist,"scope"=>:user_side,"turns"=>5}],:field_key=>:mist,:field_scope=>:user_side,:field_turns=>5,:visual_kind=>:field_disc,:visual_style=>:mist},
    :reflect => {:schema_version=>"1.0",:content_version=>"0.35.0",:canon_snapshot=>"2026-08-08",:ruleset=>"black_white",:move_key=>:reflect,:runtime_skill_key=>:mv_reflect,:name=>"反射壁",:name_en=>"Reflect",:type=>:psychic,:category=>:status,:target=>"users_field",:target_type=>:self_targeted,:delivery=>:instant,:range_px=>0.00,:policy=>:self,:behavior_status=>:implemented_field_v035,:priority=>0,:accuracy=>nil,:effects=>[{"type"=>:field_effect,"key"=>:reflect,"scope"=>:user_side,"turns"=>5}],:field_key=>:reflect,:field_scope=>:user_side,:field_turns=>5,:visual_kind=>:field_disc,:visual_style=>:reflect},
    :safeguard => {:schema_version=>"1.0",:content_version=>"0.35.0",:canon_snapshot=>"2026-08-08",:ruleset=>"black_white",:move_key=>:safeguard,:runtime_skill_key=>:mv_safeguard,:name=>"神秘守護",:name_en=>"Safeguard",:type=>:normal,:category=>:status,:target=>"users_field",:target_type=>:self_targeted,:delivery=>:instant,:range_px=>0.00,:policy=>:self,:behavior_status=>:implemented_field_v035,:priority=>0,:accuracy=>nil,:effects=>[{"type"=>:field_effect,"key"=>:safeguard,"scope"=>:user_side,"turns"=>5}],:field_key=>:safeguard,:field_scope=>:user_side,:field_turns=>5,:visual_kind=>:field_disc,:visual_style=>:safeguard},
    :tailwind => {:schema_version=>"1.0",:content_version=>"0.35.0",:canon_snapshot=>"2026-08-08",:ruleset=>"black_white",:move_key=>:tailwind,:runtime_skill_key=>:mv_tailwind,:name=>"順風",:name_en=>"Tailwind",:type=>:flying,:category=>:status,:target=>"users_field",:target_type=>:self_targeted,:delivery=>:instant,:range_px=>0.00,:policy=>:self,:behavior_status=>:implemented_field_v035,:priority=>0,:accuracy=>nil,:effects=>[{"type"=>:field_effect,"key"=>:tailwind,"scope"=>:user_side,"turns"=>4}],:field_key=>:tailwind,:field_scope=>:user_side,:field_turns=>4,:visual_kind=>:field_disc,:visual_style=>:tailwind},
    :trick_room => {:schema_version=>"1.0",:content_version=>"0.35.0",:canon_snapshot=>"2026-08-08",:ruleset=>"black_white",:move_key=>:trick_room,:runtime_skill_key=>:mv_trick_room,:name=>"戲法空間",:name_en=>"Trick Room",:type=>:psychic,:category=>:status,:target=>"entire_field",:target_type=>:self_targeted,:delivery=>:instant,:range_px=>0.00,:policy=>:self,:behavior_status=>:implemented_field_v035,:priority=>-7,:accuracy=>nil,:effects=>[{"type"=>:field_effect,"key"=>:trick_room,"scope"=>:global,"turns"=>5}],:field_key=>:trick_room,:field_scope=>:global,:field_turns=>5,:visual_kind=>:field_disc,:visual_style=>:trick_room},
    :wonder_room => {:schema_version=>"1.0",:content_version=>"0.35.0",:canon_snapshot=>"2026-08-08",:ruleset=>"black_white",:move_key=>:wonder_room,:runtime_skill_key=>:mv_wonder_room,:name=>"奇妙空間",:name_en=>"Wonder Room",:type=>:psychic,:category=>:status,:target=>"entire_field",:target_type=>:self_targeted,:delivery=>:instant,:range_px=>0.00,:policy=>:self,:behavior_status=>:implemented_field_v035,:priority=>-7,:accuracy=>nil,:effects=>[{"type"=>:field_effect,"key"=>:wonder_room,"scope"=>:global,"turns"=>5}],:field_key=>:wonder_room,:field_scope=>:global,:field_turns=>5,:visual_kind=>:field_disc,:visual_style=>:wonder_room},
  }
  FIELD_EFFECT_VISUAL_V035 = {
    :gravity => {:color=>[165,90,220,58],:scope=>:global,:label=>"GRAVITY",:opacity=>58,:y_offset=>0},
    :light_screen => {:color=>[100,145,255,62],:scope=>:user_side,:label=>"LIGHT SCREEN",:opacity=>62,:y_offset=>0},
    :lucky_chant => {:color=>[255,220,95,58],:scope=>:user_side,:label=>"LUCKY CHANT",:opacity=>58,:y_offset=>0},
    :magic_room => {:color=>[245,145,185,58],:scope=>:global,:label=>"MAGIC ROOM",:opacity=>58,:y_offset=>0},
    :mist => {:color=>[190,225,245,62],:scope=>:user_side,:label=>"MIST",:opacity=>62,:y_offset=>0},
    :reflect => {:color=>[80,220,245,62],:scope=>:user_side,:label=>"REFLECT",:opacity=>62,:y_offset=>0},
    :safeguard => {:color=>[100,235,175,62],:scope=>:user_side,:label=>"SAFEGUARD",:opacity=>62,:y_offset=>0},
    :tailwind => {:color=>[120,205,255,58],:scope=>:user_side,:label=>"TAILWIND",:opacity=>58,:y_offset=>0},
    :trick_room => {:color=>[235,80,205,58],:scope=>:global,:label=>"TRICK ROOM",:opacity=>58,:y_offset=>0},
    :wonder_room => {:color=>[110,100,230,58],:scope=>:global,:label=>"WONDER ROOM",:opacity=>58,:y_offset=>0},
  }
  FIELD_EFFECT_AUDIO_V035 = {
    :gravity => {:cast_cat=>:tone_low_hum,:launch_cat=>nil,:hit_cat=>:low_rumble,:audio_style=>:psychic},
    :light_screen => {:cast_cat=>:magic_chime,:launch_cat=>nil,:hit_cat=>:tone_sustain,:audio_style=>:psychic},
    :lucky_chant => {:cast_cat=>:magic_chime,:launch_cat=>nil,:hit_cat=>:tone_sustain,:audio_style=>:normal},
    :magic_room => {:cast_cat=>:magic_chime,:launch_cat=>nil,:hit_cat=>:magic_sustain,:audio_style=>:psychic},
    :mist => {:cast_cat=>:magic_chime,:launch_cat=>nil,:hit_cat=>:wind_hiss,:audio_style=>:ice},
    :reflect => {:cast_cat=>:magic_chime,:launch_cat=>nil,:hit_cat=>:tone_sustain,:audio_style=>:psychic},
    :safeguard => {:cast_cat=>:magic_chime,:launch_cat=>nil,:hit_cat=>:tone_sustain,:audio_style=>:normal},
    :tailwind => {:cast_cat=>:wind_whoosh,:launch_cat=>nil,:hit_cat=>:wind_hiss,:audio_style=>:flying},
    :trick_room => {:cast_cat=>:magic_chime,:launch_cat=>nil,:hit_cat=>:magic_sustain,:audio_style=>:psychic},
    :wonder_room => {:cast_cat=>:magic_chime,:launch_cat=>nil,:hit_cat=>:magic_sustain,:audio_style=>:psychic},
  }
  FIELD_EFFECT_MANIFEST_V035 = {
    :schema_version=>"1.0",
    :content_version=>"0.35.0",
    :base_version=>"0.34",
    :new_mapped_move_count=>10,
    :cumulative_mapped_move_count=>232,
    :learnset_reference_total=>7005,
    :new_reference_covered=>131,
    :cumulative_reference_covered=>3885,
    :cumulative_coverage_percent=>55.46,
    :field_visual_count=>10,
    :side_field_count=>6,
    :global_field_count=>4,
    :stack_y_spacing=>7,
    :field_visual_z=>62,
    :turn_frames=>60,
    :runtime_checksum32=>1886573291,
    :reference_counts=>{:gravity=>6,:light_screen=>22,:lucky_chant=>14,:magic_room=>1,:mist=>23,:reflect=>14,:safeguard=>38,:tailwind=>9,:trick_room=>1,:wonder_room=>3},
  }
end
