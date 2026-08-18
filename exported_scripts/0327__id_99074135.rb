# encoding: UTF-8
#==============================================================================
# 【PMD AutoChess 中文維護說明】
# 腳本：PMD AutoChess Tactical Passive / Spatial Data v0.91.4
# 分類：AutoChess 戰術被動／空間技能／資料層
#
# 【用途】
# 建立與 Energy 蓄力條分離的「Tactical Passive Counter」資料層，並集中管理
# 既有寶可夢招式的自走棋空間位移擴充。這一層的目標是讓普攻、承傷與站位本身
# 也能推進戰術節奏，而不是所有有趣的事情都只能等 Energy 滿格。
#
# 【主要設定項】
# 1. TACTICAL_PASSIVES_V0914
#    指定各寶可夢（或進化線）目前採用的自走棋被動。
#    支援：
#      :pursuit_stride  累積普攻命中後，向目前目標追步。
#      :evasive_step    累積普攻命中後，敵人貼近時做側後滑步。
#      :shell_guard     累積直接承傷後，短時間獲得 Damage Reduction。
#
# 2. SPATIAL_MOVE_EXTENSIONS_V0914
#    對既有招式增加空間效果，不另造一套技能資料庫：
#      :advance  使用者向目標推進。
#      :retreat  使用者遠離目標。
#      :push     把目標推出去。
#      :pull     把目標拉近。
#
# 3. TACTICAL_*_ABILITY_AFFINITY_V0914
#    「特性 × 自走棋被動」的輕量接口。只有語意相符的特性才提供額外加成；
#    不會修改原本 Pokémon Ability 的正規效果，也不會把 Static 等特性硬改成位移。
#
# 【機制規則】
# - Tactical Passive 不使用 Energy、不重置 Energy、也不取代 Pokémon Ability。
# - 被動 Counter 只計「成功的基本攻擊命中」或「真正造成 HP Damage 的直接承傷」。
# - 被動位移具有自己的短 CD，不能因高速普攻每幀連續觸發。
# - 空間招式擴充會先檢查原技能是否已經有 Pull/Knockback/Dash；有就不重複疊加。
# - 舊 Verifier 不套用新空間效果，避免污染 v0.60.2～v0.91.3 已 Freeze 的驗證。
#
# 【可調參數】
# 每個 Profile 都可調：
#   :trigger       需要幾次事件才觸發。
#   :distance      位移距離（px）。
#   :frames        位移動畫幀數。
#   :cooldown      觸發後內建 CD（frame）。
#   :threat_range  evasive_step 只在敵人夠近時才觸發。
#   :reduction     shell_guard 的減傷比例。
#   :duration      shell_guard 的持續時間。
#
# 【事件／腳本呼叫方式】
# Runtime 會自動運作，一般事件不需設定。
# 開發時可查詢：
#   unit.tactical_passive_profile_v0914
#   unit.tactical_passive_key_v0914
#   PMD_AC.spatial_move_extension_v0914(:quick_attack)
#
# 【實際範例】
# 妙蛙種子：成功普攻 3 次後，如果仍有存活目標，向目標追步最多 34px。
# 皮卡丘：成功普攻 4 次後，如果 125px 內仍有敵人，側後滑步 34px（只有部分位移直接增加距離）。
# 傑尼龜：受到 3 次直接 HP 傷害後，短時間取得 20% Damage Reduction。
# 電光一閃：原技能正常消耗 Energy；命中時額外保留約 38px 的向前位移。
# 水槍／起風：命中後增加小幅 Push；藤鞭增加小幅 Pull。
#
# 【注意事項】
# - 目前先覆蓋測試專案常見的六條進化線，框架可再擴到 494 種。
# - 不修改 v0.60.2 Multi-hit Damage Packet、v0.88.3 Ranged Stagger、
#   v0.89 Stalemate、v0.91 Boss、v0.91.2 Aggro、v0.91.3 Peel。
# - RGSS2 / Ruby 1.8 相容；禁止使用 instance_variable_defined?。
#==============================================================================
module PMD_AC
  PATCH_VERSION_V0914 = '0.91.4'

  TACTICAL_PASSIVES_V0914 = {
    :bulbasaur  => {:key=>:pursuit_stride,:name=>'藤根追步',:trigger=>3,:distance=>34.0,:frames=>7,:cooldown=>60},
    :ivysaur    => {:key=>:pursuit_stride,:name=>'藤根追步',:trigger=>3,:distance=>36.0,:frames=>7,:cooldown=>58},
    :venusaur   => {:key=>:pursuit_stride,:name=>'藤根追步',:trigger=>3,:distance=>38.0,:frames=>7,:cooldown=>56},

    :charmander => {:key=>:pursuit_stride,:name=>'猛攻追步',:trigger=>4,:distance=>30.0,:frames=>6,:cooldown=>62},
    :charmeleon => {:key=>:pursuit_stride,:name=>'猛攻追步',:trigger=>4,:distance=>33.0,:frames=>6,:cooldown=>60},
    :charizard  => {:key=>:pursuit_stride,:name=>'猛攻追步',:trigger=>4,:distance=>36.0,:frames=>6,:cooldown=>58},

    :squirtle   => {:key=>:shell_guard,:name=>'龜甲架勢',:trigger=>3,:reduction=>0.20,:duration=>60,:cooldown=>120},
    :wartortle  => {:key=>:shell_guard,:name=>'龜甲架勢',:trigger=>3,:reduction=>0.22,:duration=>66,:cooldown=>116},
    :blastoise  => {:key=>:shell_guard,:name=>'重甲架勢',:trigger=>3,:reduction=>0.24,:duration=>72,:cooldown=>112},

    :caterpie   => {:key=>:evasive_step,:name=>'蟲絲滑步',:trigger=>4,:distance=>28.0,:frames=>7,:cooldown=>66,:threat_range=>116.0},
    :butterfree => {:key=>:evasive_step,:name=>'蝶舞滑步',:trigger=>4,:distance=>32.0,:frames=>7,:cooldown=>62,:threat_range=>124.0},
    :metapod    => {:key=>:shell_guard,:name=>'硬殼架勢',:trigger=>2,:reduction=>0.30,:duration=>72,:cooldown=>120},

    :rattata    => {:key=>:pursuit_stride,:name=>'獵食追步',:trigger=>3,:distance=>24.0,:frames=>5,:cooldown=>54},
    :raticate   => {:key=>:pursuit_stride,:name=>'獵食追步',:trigger=>3,:distance=>28.0,:frames=>5,:cooldown=>50},

    :pikachu    => {:key=>:evasive_step,:name=>'電光滑步',:trigger=>4,:distance=>34.0,:frames=>7,:cooldown=>62,:threat_range=>125.0},
    :raichu     => {:key=>:evasive_step,:name=>'雷光滑步',:trigger=>4,:distance=>38.0,:frames=>7,:cooldown=>58,:threat_range=>132.0}
  }

  # 只有語意相符的正規特性才影響戰術被動。這是增幅，不是覆寫 Ability 本體。
  TACTICAL_MOVEMENT_ABILITY_AFFINITY_V0914 = [
    :run_away,:quick_feet,:speed_boost,:motor_drive,:unburden
  ]
  TACTICAL_DEFENSE_ABILITY_AFFINITY_V0914 = [
    :sturdy,:battle_armor,:shell_armor,:filter,:solid_rock,:thick_fat
  ]
  TACTICAL_MOVEMENT_TRIGGER_REDUCTION_V0914 = 1
  TACTICAL_DEFENSE_REDUCTION_BONUS_V0914 = 0.05
  TACTICAL_DEFENSE_REDUCTION_CAP_V0914 = 0.40

  # 既有招式的 AutoChess 空間延伸。若原 Runtime 已有同類位移，Runtime 會跳過。
  SPATIAL_MOVE_EXTENSIONS_V0914 = {
    :quick_attack => {:kind=>:advance,:distance=>38.0,:frames=>6},
    :mach_punch   => {:kind=>:advance,:distance=>32.0,:frames=>5},
    :extreme_speed=> {:kind=>:advance,:distance=>50.0,:frames=>6},
    :aqua_jet     => {:kind=>:advance,:distance=>42.0,:frames=>6},
    :flame_charge => {:kind=>:advance,:distance=>44.0,:frames=>6},
    :volt_tackle  => {:kind=>:advance,:distance=>48.0,:frames=>6},
    :wild_charge  => {:kind=>:advance,:distance=>44.0,:frames=>6},

    :water_gun    => {:kind=>:push,:distance=>18.0},
    :hydro_pump   => {:kind=>:push,:distance=>34.0},
    :gust         => {:kind=>:push,:distance=>20.0},
    :hurricane    => {:kind=>:push,:distance=>32.0},
    :dragon_tail  => {:kind=>:push,:distance=>42.0},
    :circle_throw => {:kind=>:push,:distance=>44.0},
    :roar         => {:kind=>:push,:distance=>50.0},
    :whirlwind    => {:kind=>:push,:distance=>50.0},

    :vine_whip    => {:kind=>:pull,:distance=>18.0},
    :power_whip   => {:kind=>:pull,:distance=>24.0},

    # 原作換人招式在單機 3v3 自走棋中改成「打完主動拉開」，保留 hit-and-run 語意。
    :u_turn       => {:kind=>:retreat,:distance=>42.0,:frames=>7},
    :volt_switch  => {:kind=>:retreat,:distance=>42.0,:frames=>7}
  }

  TACTICAL_SPATIAL_VERIFY_END_V0914 = 30
  DUEL_PACE_WATCH_FRAMES_V0914 = 600
  DUEL_PACE_LONG_FRAMES_V0914 = 1200

  def self.tactical_passive_profile_v0914(species_key)
    p=TACTICAL_PASSIVES_V0914[species_key]
    p==nil ? nil : p.dup
  end

  def self.spatial_move_extension_v0914(move_key)
    return nil if move_key==nil
    k=move_key.to_s.downcase.gsub(/[^a-z0-9]+/,'_').to_sym
    p=SPATIAL_MOVE_EXTENSIONS_V0914[k]
    p==nil ? nil : p.dup
  end
end
