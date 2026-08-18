#==============================================================================
# 【PMD AutoChess 中文維護說明】
# 腳本：PMD AutoChess Field AI Data v0.37
# 分類：場地／空間效果
#
# 【用途／機制】
# 定義 Field/Terrain 的效果、範圍、視覺圓盤與 AI 位置評分。
#
# 【怎麼調整】
# 新增場地時同時確認 Effect、Spatial 與 AI 三層；只加數值不加空間資料會讓 AI 不知道場地在哪。
#
# 【本腳本主要設定常數／資料表】
# - FIELD_AI_MANIFEST_V037 / FIELD_AI_POLICY_WEIGHT_V037
#
# 【維護規則】
# - RPG Maker VX / RGSS2 / Ruby 1.8 相容。
# - instance_uid 才是 Pokémon 個體身份；Actor ID 只是容器。
# - 新增行為優先沿用既有 helper／Data 表；避免破壞已 Freeze 的舊核心。
# - 本專案新腳本也必須保留同等級的中文說明與實際範例。
#==============================================================================
# PMD AutoChess v0.37 Field AI Data
module PMD_AC
  FIELD_AI_MANIFEST_V037 = {
    :schema_version=>"1.0",
    :content_version=>"0.37.0",
    :base_version=>"0.36.1",
    :feature=>"spatial_field_ai_movement_scoring_i",
    :cumulative_mapped_move_count=>232,
    :learnset_reference_total=>7005,
    :cumulative_reference_covered=>3885,
    :cumulative_coverage_percent=>55.46,
    :local_field_count=>6,
    :zone_count=>3,
    :aura_count=>3,
    :global_count=>4,
    :attract_range_px=>190.00,
    :max_steer=>0.72,
    :min_steer=>0.03,
    :pressured_weight=>0.35,
    :emergency_weight=>0.00,
    :field_value_hook=>:field_value_at,
    :movement_hook=>:desired_velocity,
    :policy_weights=>{:frontline=>0.90,:bruiser=>0.80,:assassin=>0.35,:kiter=>1.00,:artillery=>1.10,:controller=>1.15,:bodyguard=>0.75,:berserker=>0.00},
    :runtime_checksum32=>386560758,
  }
  FIELD_AI_POLICY_WEIGHT_V037 = {
    :frontline=>0.90,
    :bruiser=>0.80,
    :assassin=>0.35,
    :kiter=>1.00,
    :artillery=>1.10,
    :controller=>1.15,
    :bodyguard=>0.75,
    :berserker=>0.00,
  }
end
