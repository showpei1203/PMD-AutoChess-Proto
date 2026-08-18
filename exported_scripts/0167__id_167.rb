#==============================================================================
# 【PMD AutoChess 中文維護說明】
# 腳本：PMD AutoChess Field Spatial Data v0.36
# 分類：場地／空間效果
#
# 【用途／機制】
# 定義 Field/Terrain 的效果、範圍、視覺圓盤與 AI 位置評分。
#
# 【怎麼調整】
# 新增場地時同時確認 Effect、Spatial 與 AI 三層；只加數值不加空間資料會讓 AI 不知道場地在哪。
#
# 【本腳本主要設定常數／資料表】
# - FIELD_SPATIAL_PROFILE_V036 / FIELD_SPATIAL_MANIFEST_V036
#
# 【維護規則】
# - RPG Maker VX / RGSS2 / Ruby 1.8 相容。
# - instance_uid 才是 Pokémon 個體身份；Actor ID 只是容器。
# - 新增行為優先沿用既有 helper／Data 表；避免破壞已 Freeze 的舊核心。
# - 本專案新腳本也必須保留同等級的中文說明與實際範例。
#==============================================================================
#==============================================================================
# ■ PMD AutoChess Field Spatial Data v0.36
#==============================================================================
module PMD_AC
  FIELD_SPATIAL_PROFILE_V036 = {
    :gravity => {:spatial_type=>:global,:affect_team=>:both,:follow_source=>false,:radius_x=>0,:radius_y=>0,:visual_width=>410,:visual_height=>94,:ai_value=>0.00},
    :light_screen => {:spatial_type=>:zone,:affect_team=>:owner,:follow_source=>false,:radius_x=>122,:radius_y=>86,:visual_width=>244,:visual_height=>96,:ai_value=>0.20},
    :lucky_chant => {:spatial_type=>:aura,:affect_team=>:owner,:follow_source=>true,:radius_x=>120,:radius_y=>86,:visual_width=>240,:visual_height=>92,:ai_value=>0.12},
    :magic_room => {:spatial_type=>:global,:affect_team=>:both,:follow_source=>false,:radius_x=>0,:radius_y=>0,:visual_width=>410,:visual_height=>94,:ai_value=>0.00},
    :mist => {:spatial_type=>:aura,:affect_team=>:owner,:follow_source=>true,:radius_x=>120,:radius_y=>86,:visual_width=>240,:visual_height=>92,:ai_value=>0.14},
    :reflect => {:spatial_type=>:zone,:affect_team=>:owner,:follow_source=>false,:radius_x=>122,:radius_y=>86,:visual_width=>244,:visual_height=>96,:ai_value=>0.22},
    :safeguard => {:spatial_type=>:zone,:affect_team=>:owner,:follow_source=>false,:radius_x=>122,:radius_y=>86,:visual_width=>244,:visual_height=>96,:ai_value=>0.20},
    :tailwind => {:spatial_type=>:aura,:affect_team=>:owner,:follow_source=>true,:radius_x=>120,:radius_y=>86,:visual_width=>240,:visual_height=>92,:ai_value=>0.22},
    :trick_room => {:spatial_type=>:global,:affect_team=>:both,:follow_source=>false,:radius_x=>0,:radius_y=>0,:visual_width=>410,:visual_height=>94,:ai_value=>0.00},
    :wonder_room => {:spatial_type=>:global,:affect_team=>:both,:follow_source=>false,:radius_x=>0,:radius_y=>0,:visual_width=>410,:visual_height=>94,:ai_value=>0.00},
  }
  FIELD_SPATIAL_MANIFEST_V036 = {
    :schema_version=>"1.0",
    :content_version=>"0.36.0",
    :base_version=>"0.35",
    :cumulative_mapped_move_count=>232,
    :learnset_reference_total=>7005,
    :cumulative_reference_covered=>3885,
    :cumulative_coverage_percent=>55.46,
    :spatial_field_count=>10,
    :zone_count=>3,
    :aura_count=>3,
    :global_count=>4,
    :stack_y_spacing=>7,
    :field_visual_z=>62,
    :turn_frames=>60,
    :zone_keys=>[:reflect,:light_screen,:safeguard],
    :aura_keys=>[:mist,:tailwind,:lucky_chant],
    :global_keys=>[:gravity,:trick_room,:wonder_room,:magic_room],
    :runtime_checksum32=>659873155,
  }
end
