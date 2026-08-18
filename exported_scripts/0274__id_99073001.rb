#==============================================================================
# 【PMD AutoChess 中文維護說明】
# 腳本：PMD AutoChess Full Battle Soak Data v0.73
# 分類：測試／Soak
#
# 【用途／機制】
# 提供整體戰鬥驗證、長時間 Soak 與 Carry 檢查。
#
# 【怎麼調整】
# 驗證模式結束必須看到 VERIFY_FINISHED_BATTLE_RESUME pass=1，並恢復 Pokémon AI／Mov
# ement。
#
# 【本腳本主要設定常數／資料表】
# - PATCH_VERSION_V073 / SOAK_ROUNDS_V073 / SOAK_MAX_FRAMES_V073 / SOAK_AUDIT_INTERVAL_V073
# - SOAK_INITIAL_HP_RATE_V073 / SOAK_INITIAL_ENERGY_V073 / SOAK_BATTLE_SPEED_V073 / SOAK_RESULT_WAIT_V073
# - SOAK_SCENARIOS_V073 / SOAK_MANIFEST_V073 / VERIFICATION_MODES / VERIFICATION_LABELS
#
# 【Runtime 主要方法（查流程時可直接搜尋）】
# - soak_scalar_v073 / soak_checksum32_v073 / validate_soak_v073
#
# 【維護規則】
# - RPG Maker VX / RGSS2 / Ruby 1.8 相容。
# - instance_uid 才是 Pokémon 個體身份；Actor ID 只是容器。
# - 新增行為優先沿用既有 helper／Data 表；避免破壞已 Freeze 的舊核心。
# - 本專案新腳本也必須保留同等級的中文說明與實際範例。
#==============================================================================
#==============================================================================
# PMD AutoChess Full Battle Soak Data v0.73
# RGSS2 / Ruby 1.8 compatible
#==============================================================================
module PMD_AC
  PATCH_VERSION_V073='0.73'
  SOAK_ROUNDS_V073=3
  SOAK_MAX_FRAMES_V073=3000
  SOAK_AUDIT_INTERVAL_V073=180
  SOAK_INITIAL_HP_RATE_V073=0.55
  SOAK_INITIAL_ENERGY_V073=100
  SOAK_BATTLE_SPEED_V073=2
  SOAK_RESULT_WAIT_V073=24

  SOAK_SCENARIOS_V073=[
    {
      :key=>:control_sustain,
      :name=>'CONTROL_SUSTAIN',
      :moves=>{
        :bulbasaur=>[:sleep_powder,:leech_seed,:vine_whip,:protect],
        :charmander=>[:flamethrower,:slash,:smokescreen,:protect],
        :squirtle=>[:water_gun,:aqua_ring,:protect,:tail_whip],
        :rattata=>[:quick_attack,:super_fang,:tail_whip,:focus_energy],
        :caterpie=>[:bug_bite,:string_shot,:electroweb,:tackle],
        :pikachu=>[:thunderbolt,:slam,:quick_attack,:tail_whip]
      },
      :perturb=>[[:field,240,:safeguard,:enemy,4]]
    },
    {
      :key=>:weather_field,
      :name=>'WEATHER_FIELD',
      :moves=>{
        :bulbasaur=>[:sunny_day,:growth,:solar_beam,:protect],
        :charmander=>[:flamethrower,:will_o_wisp,:slash,:sunny_day],
        :squirtle=>[:rain_dance,:muddy_water,:light_screen,:aqua_ring],
        :rattata=>[:protect,:quick_attack,:super_fang,:double_team],
        :caterpie=>[:safeguard,:string_shot,:bug_bite,:electroweb],
        :pikachu=>[:rain_dance,:thunder,:light_screen,:electro_ball]
      },
      :perturb=>[
        [:weather,180,:rain,:ally,5],
        [:field,420,:reflect,:ally,5],
        [:weather,720,:sun,:enemy,4]
      ]
    },
    {
      :key=>:multihit_guard,
      :name=>'MULTIHIT_GUARD',
      :moves=>{
        :bulbasaur=>[:bullet_seed,:take_down,:leech_seed,:protect],
        :charmander=>[:double_kick,:slash,:fire_fang,:protect],
        :squirtle=>[:rapid_spin,:water_pulse,:aqua_ring,:protect],
        :rattata=>[:hyper_fang,:quick_attack,:focus_energy,:protect],
        :caterpie=>[:double_slap,:fury_swipes,:string_shot,:protect],
        :pikachu=>[:slam,:quick_attack,:thunderbolt,:protect]
      },
      :perturb=>[
        [:field,240,:gravity,:ally,4],
        [:field,540,:light_screen,:enemy,4]
      ]
    }
  ]

  SOAK_MANIFEST_V073={
    :schema_version=>'1.0',
    :content_version=>'0.73.0',
    :phase=>'FULL_BATTLE_SOAK',
    :rounds=>SOAK_ROUNDS_V073,
    :max_frames=>SOAK_MAX_FRAMES_V073,
    :audit_interval=>SOAK_AUDIT_INTERVAL_V073,
    :initial_hp_rate=>SOAK_INITIAL_HP_RATE_V073,
    :initial_energy=>SOAK_INITIAL_ENERGY_V073,
    :battle_speed=>SOAK_BATTLE_SPEED_V073,
    :scenarios=>SOAK_SCENARIOS_V073.collect{|x|x[:key]},
    :move_runtime=>526,
    :learnset_coverage=>'7005/7005',
    :ability_slots=>'1028/1193',
    :ability_species=>'483/494',
    :movement_core=>'v0.15_unchanged',
    :basic_target=>'v0.15_unchanged',
    :skill_target=>'v0.69_overlay',
    :threat_core=>'v0.70_hysteresis',
    :intent_core=>'v0.71_24f',
    :prediction_core=>'v0.72_side_effect_free',
    :weather_core=>'v0.28_unchanged',
    :field_core=>'v0.35-v0.37_unchanged',
    :damage_packet=>'v0.60.2',
    :native_router=>'v0.62'
  }

  class << self
    def soak_scalar_v073(x)
      return '' if x==nil
      return x.collect{|v|soak_scalar_v073(v)}.join(',') if x.is_a?(Array)
      if x.is_a?(Hash)
        return x.keys.sort{|a,b|a.to_s<=>b.to_s}.collect{|k|k.to_s+'='+soak_scalar_v073(x[k])}.join(',')
      end
      x.to_s
    end

    def soak_checksum32_v073
      h=0
      m=SOAK_MANIFEST_V073
      m.keys.sort{|a,b|a.to_s<=>b.to_s}.each do |k|
        (k.to_s+'='+soak_scalar_v073(m[k])).each_byte{|b|h=((h*33)+b)&0x7fffffff}
      end
      SOAK_SCENARIOS_V073.each do |s|
        soak_scalar_v073(s).each_byte{|b|h=((h*33)+b)&0x7fffffff}
      end
      h
    end

    def validate_soak_v073
      e=[]
      e.push('rounds') unless SOAK_ROUNDS_V073==3 && SOAK_SCENARIOS_V073.size==3
      e.push('frames') unless SOAK_MAX_FRAMES_V073>=1800
      e.push('speed') unless SOAK_BATTLE_SPEED_V073==2
      e.push('moves') unless SOAK_MANIFEST_V073[:move_runtime].to_i==526
      e.push('abilities') unless SOAK_MANIFEST_V073[:ability_slots]=='1028/1193'
      SOAK_SCENARIOS_V073.each do |s|
        e.push('scenario_'+s[:key].to_s) unless s[:moves].size==6
      end
      e
    end
  end

  remove_const(:VERIFICATION_MODES) if const_defined?(:VERIFICATION_MODES)
  VERIFICATION_MODES=[
    :full_battle_soak_v073,
    :normal,
    :combat_ai_integration_v_v072,
    :combat_ai_integration_iv_v071,
    :combat_ai_integration_iii_v070,
    :combat_ai_integration_ii_v069,
    :combat_ai_integration_v068,
    :ability_runtime_coverage_iv_v067,
    :ability_runtime_coverage_iii_v066,
    :ability_runtime_coverage_ii_v065,
    :ability_runtime_coverage_v064,
    :native_semantic_audit_v063,
    :native_semantic_v062,
    :native_combo_preview_v062,
    :compiled_pose_runtime_v061,
    :multi_choreo_v060,
    :native_pose_showcase_v060
  ]

  remove_const(:VERIFICATION_LABELS) if const_defined?(:VERIFICATION_LABELS)
  VERIFICATION_LABELS={
    :full_battle_soak_v073=>'FULL_BATTLE_SOAK_V073',
    :normal=>'NORMAL',
    :combat_ai_integration_v_v072=>'COMBAT_AI_INTEGRATION_V_V072',
    :combat_ai_integration_iv_v071=>'COMBAT_AI_INTEGRATION_IV_V071',
    :combat_ai_integration_iii_v070=>'COMBAT_AI_INTEGRATION_III_V070',
    :combat_ai_integration_ii_v069=>'COMBAT_AI_INTEGRATION_II_V069',
    :combat_ai_integration_v068=>'COMBAT_AI_INTEGRATION_V068',
    :ability_runtime_coverage_iv_v067=>'ABILITY_RUNTIME_COVERAGE_IV_V067',
    :ability_runtime_coverage_iii_v066=>'ABILITY_RUNTIME_COVERAGE_III_V066',
    :ability_runtime_coverage_ii_v065=>'ABILITY_RUNTIME_COVERAGE_II_V065',
    :ability_runtime_coverage_v064=>'ABILITY_RUNTIME_COVERAGE_V064',
    :native_semantic_audit_v063=>'NATIVE_SEMANTIC_AUDIT_V063',
    :native_semantic_v062=>'NATIVE_SEMANTIC_V062',
    :native_combo_preview_v062=>'NATIVE_COMBO_PREVIEW_V062',
    :compiled_pose_runtime_v061=>'COMPILED_POSE_RUNTIME_V061',
    :multi_choreo_v060=>'MULTI_CHOREO_V060',
    :native_pose_showcase_v060=>'NATIVE_POSE_SHOWCASE_V060'
  }
end
