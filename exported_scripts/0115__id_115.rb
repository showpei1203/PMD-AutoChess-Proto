#==============================================================================
# 【PMD AutoChess 中文維護說明】
# 腳本：PMD AutoChess Proto v0.15
# 分類：核心戰鬥 Runtime
#
# 【用途／機制】
# 承接前序 Data／Config，實際執行戰鬥 Scene、Unit、AI、技能與呈現。
#
# 【怎麼調整】
# 一般平衡與資料調整不要直接改 Runtime；若要追加功能，建議在較後腳本 alias 原方法後擴充。
#
# 【本腳本主要設定常數／資料表】
# - VERSION / CORE_BASELINE / GRID_COLS / GRID_ROWS
# - CELL_W / CELL_H / GRID_X / GRID_Y
# - LOGIC_TICK / MAX_ENERGY / ENERGY_ON_BASIC_HIT / ENERGY_ON_DAMAGE_TAKEN
# - ENERGY_LOG_PASSIVE_FLOW / PMD_ROOT / ACCELERATION / STOP_DAMPING
# - ARRIVAL_RADIUS / DIRECTION_HOLD_FRAMES / MELEE_HIT_GRACE / ATTACK_SLOT_GAP
# - AOE_RADIUS / PROJECTILE_SPEED / PROJECTILE_RADIUS / PROJECTILE_LIFE
# - BASIC_LUNGE_DISTANCE / SKILL_LUNGE_DISTANCE / RECOIL_DAMPING / RECOIL_LIMIT
# - KNOCKBACK_DAMPING / CAMERA_SHAKE_MAX / UNIT_SPRITE_SCALE / EFFECT_SPRITE_SCALE
# - PROJECTILE_SPRITE_SCALE / LINK_EFFECT_THICKNESS_SCALE / BEAM_DEFAULT_LIFE / BEAM_DEFAULT_WIDTH
# - BEAM_SUSTAIN_TICK / SLOW_CAP / SLOW_RESIST_MAX / SHOW_THREAT_DEBUG
# - THREAT_SCAN_RANGE / THREAT_PRESSURE_RANGE / THREAT_EMERGENCY_RANGE / THREAT_MEMORY_FRAMES
# - THREAT_RETARGET_COOLDOWN / THREAT_RELEASE_FRAMES / THREAT_PRESSURE_STEP / THREAT_EMERGENCY_STEP
# - SHOW_AI_DEBUG / AI_TARGET_REEVALUATE_FRAMES / AI_TARGET_REEVALUATE_JITTER / AI_SWITCH_THRESHOLD_MIN
# - AI_SWITCH_THRESHOLD_MAX / AI_BODYGUARD_LEASH / AI_BODYGUARD_OFFSET / AI_ASSASSIN_FLANK_OFFSET
# - AI_ARTILLERY_RANGE_BONUS / AI_BERSERKER_HP_RATE / AI_BERSERKER_SPEED_BONUS / AI_EDGE_MARGIN
# - AI_ESCAPE_MIN_MOVE / AI_ESCAPE_MIN_GAIN / ESCAPE_FAIL_LOG_INTERVAL / VERIFICATION_MODES
# - VERIFICATION_LABELS / VERIFICATION_HP_MULTIPLIER / VERIFICATION_CONTROL_END_FRAME / VERIFICATION_BEAM_END_FRAME
# - VERIFICATION_ZONE_END_FRAME / VERIFICATION_HIT_END_FRAME / VERIFICATION_ENERGY_END_FRAME / VERIFICATION_DIRECTION_END_FRAME
# - VERIFICATION_OBJECT_END_FRAME / VERIFICATION_SUMMON_END_FRAME / VERIFICATION_IDENTITY_END_FRAME / TEMP_INSTANCE_UID_START
# - SUMMON_MAX_PER_TEAM / SUMMON_DEFAULT_DURATION / SUMMON_DEFEAT_FAINT_FRAMES / SUBSTITUTE_DEFAULT_HP_RATIO
# - SUBSTITUTE_INTERCEPT_RADIUS / BATTLE_OBJECT_MAX / BATTLE_OBJECT_ID_BASE / BATTLE_OBJECT_DEFAULT_RADIUS
# - BATTLE_OBJECT_DEFAULT_DURATION / BATTLE_OBJECT_HP_BAR_WIDTH / BATTLE_OBJECT_HP_BAR_HEIGHT / DIRECTION_FRONT_DOT
# - DIRECTION_FRONT_MULTIPLIER / DIRECTION_SIDE_MULTIPLIER / DIRECTION_BACK_MULTIPLIER / BASE_CRIT_RATE
# - BASE_CRIT_MULTIPLIER / ACTIVE_EVADE_DISTANCE / ACTIVE_EVADE_COOLDOWN / ACTIVE_EVADE_TRIGGER_DISTANCE
# - ACTIVE_EVADE_VISUAL_FRAMES / PROJECTILE_TRACKING_TURN_RATE / PROJECTILE_ORBIT_BREAK_RADIUS / PROJECTILE_OVERSHOOT_TOLERANCE
# - PROJECTILE_OVERSHOOT_FRAMES / PROJECTILE_MAX_REACQUIRE_ANGLE / SE_ENABLED / SE_DEFAULT_VOLUME
# - SE_DEFAULT_PITCH / DEFAULT_SKILL_LAUNCH_SE / DEFAULT_SKILL_HIT_SE / DEFAULT_CRIT_SE
# - DEFAULT_EVADE_SE / SKILL_HIT_SE_DEDUP_FRAMES / UNIT_BAR_INNER_WIDTH / UNIT_BAR_WIDTH
# - UNIT_BAR_HEIGHT / UNIT_BAR_THICKNESS / VICTORY_BOUNCE_HEIGHT / VICTORY_BOUNCE_PERIOD
# - VICTORY_BOUNCE_STAGGER / SHOW_STATUS_DEBUG / SKILL_REEVALUATE_FRAMES / SKILL_FORCE_CAST_AFTER
# - STATUS_DEFAULT_INTERVAL / STATUS_MAX_STACKS / TAUNT_DEFAULT_DURATION / CC_RESIST_MAX
# - CC_DR_RESET_FRAMES / CC_DR_STEPS / FEAR_ESCAPE_DISTANCE / ZONE_DEFAULT_DURATION
# - ZONE_DEFAULT_INTERVAL / ZONE_AVOID_STRENGTH / AURA_REFRESH_INTERVAL / LINK_DEFAULT_RATIO
# - PROJECTILE_INTERCEPT_RADIUS / PMD_VFX_FOLDER / PMD_VFX_CELL_SIZE / PMD_VFX_DEFAULT_FPS
# - PMD_VFX_DEFAULT_ZOOM / PMD_VFX_GLOBAL_SCALE / PMD_VFX_BEAM_IMPACT_DELAY / PMD_VFX_IMPACT_LAYERS
# - PMD_VFX_PROFILES / PMD_VFX_EVENT_DEDUP_FRAMES / PMD_VFX_EVENT_LAYERS / BATTLE_LOG_ENABLED
# - BATTLE_LOG_FILE / BATTLE_LOG_DAMAGE / BATTLE_LOG_TARGET / BATTLE_LOG_THREAT
# - STATUS_DEFS / SKILL_DATA / BOARD_LEFT / BOARD_RIGHT
# - BOARD_TOP / BOARD_BOTTOM / ALLY_DEPLOY_MIN_X / ALLY_DEPLOY_MAX_X
# - DIRECTION_ROWS / DEFAULT_DIRECTION / ACTION_FALLBACKS / BATTLE_OBJECT_DATA
# - EVOLUTION_LINE_DATA / POKEMON_SPECIES_DATA / UNIT_DATA / ALLY_SETUP
# - ENEMY_SETUP / ATTACK_SLOT_VECTORS / VERIFICATION_PROGRESSION_END_FRAME / POKEMON_MAX_LEVEL
# - POKEMON_DEFAULT_LEVEL / POKEMON_PLACEHOLDER_IV / POKEMON_PLACEHOLDER_EV / POKEMON_COMBAT_HP_SCALE
# - POKEMON_DAMAGE_SCALE / POKEMON_STAB_MULTIPLIER / POKEMON_RANDOM_MIN / POKEMON_RANDOM_MAX
# - TYPE_CHART / SPECIES_V012 / SKILL_V012 / VERIFICATION_INDIVIDUAL_END_FRAME
# - NATURE_DATA / ABILITY_DATA / SPECIES_ABILITY_SLOTS / AI_TARGET_POLICIES
# - AI_MOVEMENT_POLICIES / AI_THREAT_POLICIES / AI_SKILL_POLICIES / AI_PRESETS
# - VERIFICATION_MEGA_END_FRAME / MEGA_PER_TEAM / MEGA_SE_NAME / MEGA_SE_VOLUME
# - MEGA_SE_PITCH / MEGA_FORM_DATA / VERIFICATION_SYNERGY_END_FRAME / SYNERGY_DATA
#
# 【PMD_AC 對外／共用方法】
# - vfx_event_key / vfx_event_layers / vfx_profile / vfx_impact_layers
# - skill_data / play_se / status_def / action_database
# - action_data / action_timing / direction_from_delta / direction_row
# - bitmap_exists? / cell_pixel_x / cell_pixel_y / pixel_to_cell_x
# - pixel_to_cell_y / clamp / distance / allocate_temporary_instance_uid
# - species_identity_data / evolution_line_data / identity_synergy_tags / identity_role_tags
# - validate_identity_registry
#
# 【Runtime 主要方法（查流程時可直接搜尋）】
# - self / initialize / bind_actor_ids / set_form_key
# - species? / evolution_line? / synergy_tag? / role_tag?
# - same_species? / same_evolution_line? / clone_identity / log_signature
#
# 【維護規則】
# - RPG Maker VX / RGSS2 / Ruby 1.8 相容。
# - instance_uid 才是 Pokémon 個體身份；Actor ID 只是容器。
# - 新增行為優先沿用既有 helper／Data 表；避免破壞已 Freeze 的舊核心。
# - 本專案新腳本也必須保留同等級的中文說明與實際範例。
#==============================================================================
#==============================================================================
# ■ PMD AutoChess Proto v0.15
#------------------------------------------------------------------------------
# RPG Maker VX / RGSS2
# 獨立 3v3 自走棋原型，不使用 Scene_Battle，也不依賴 Tankentai SBS。
# 腳本名稱建議：PMD AutoChess Proto v0.15（40 字元內）
#------------------------------------------------------------------------------
# 【安裝】
# 1. 放在「▼ Materials」以下、「Main」以上。
# 2. PMD_AUTOCHESS_DATA 資料腳本放在本腳本上方。
# 3. 事件腳本呼叫：
#      $scene = Scene_PMD_AutoChess.new
#
# 【操作】
# 布陣：方向鍵移動游標；C 選取／放置；Shift 開戰；B 取消／離開。
# 戰鬥：A 鍵切換 1 倍／2 倍速度；B 離開。
# 結果：C 回到布陣；B 離開。
#
# 【v0.11.5 Pokémon Identity Layer】
# - v0.11.1.1 Summon Cleanup 驗證通過，召喚物到期確實從 Scene 移除。
# - 新增 PMD_PokemonIdentity，將「戰鬥 Unit」與「Pokémon 身份」分離。
# - Identity 欄位：
#     instance_uid
#     runtime_actor_id
#     template_actor_id
#     evolution_line_key
#     species_key
#     form_key
#     evolution_stage
#     synergy_tags
#     role_tags
#     pmd_species_id
# - instance_uid 與 Unit ID 分離；目前原型使用 Temporary UID，
#   v0.12 PokémonInstance 會改由持久資料提供 UID。
# - Actor ID 不代表 Pokémon 身份：
#     runtime_actor_id / template_actor_id 只是 Adapter Binding。
#     Clone Actor 未來可以換 Runtime Actor ID，但 species_key / line / UID 不受影響。
# - 新增 Evolution Line Registry 與 Species Identity Registry。
#   先登錄目前六條進化線及後續進化成員，但本版不執行升級／進化。
# - Synergy 目前只建立 Tags 與查詢介面，不計算羈絆效果。
# - role_tags 與 species/line 身份分離，後續可由 AI Build / Ability 調整。
# - Summoned Unit 也取得獨立 instance_uid；
#   可與原生同 species_key，但不會被誤認成同一隻個體。
# - 新增 IDENTITY Verification Mode：
#     Registry / UID uniqueness / Species-Line matching /
#     Kanto Starter Tags / Form identity / Actor Adapter / Summon Identity。
#
# 【v0.11.1.1 Summon Cleanup / No Permanent Corpse】
# - 修正 Summoned Unit Duration 到期後永久留下 Faint Sprite。
# - Summon 結束分成兩種語意：
#     * duration / owner_dead / manual：
#         SUMMON_EXPIRE -> 直接排入 Remove Queue，不記錄 DEATH，不留屍體。
#     * 真正 HP 被打到 0：
#         正常播放短暫 Faint，24f 後自動移除 Sprite / Unit。
# - 新增 Summon Removal Queue，避免在 @units.each 更新途中直接 delete 導致跳過下一隻。
# - 真正移除時會：
#     * 從 @units 刪除
#     * Dispose 對應 Sprite_PMDChessUnit
#     * 清除其他單位對該召喚物的 Target / Threat / SkillTarget 等引用
#     * Release Attack Slot
# - 新增 [SUMMON_REMOVE] LOG。
# - SUMMON Verification 增加 REMOVED_FROM_SCENE 驗證，不只看 alive_summons=0。
#
# 【v0.11.1 Summon Unit / Substitute Extension】
# - v0.11 OBJECT Verification 已完整通過：Decoy / Trap / Bomb / Totem / Delayed。
# - Battle Object 與 Summoned Unit 正式分層：
#     * Battle Object：不具完整 Battler AI，例如替身、陷阱、炸彈、圖騰。
#     * Summoned Unit：真正 Game_PMDChessUnit，可移動、鎖定、普攻、吃狀態與方向傷害。
# - 新增 Summoned Unit：
#     * 可由任意既有 UNIT_DATA species 生成。
#     * 可設定 duration / hp_scale / stat_scale / allow_skill / expire_with_owner。
#     * 會加入 Pixel Movement / Collision / Target / Threat / Damage / VFX 全套戰鬥核心。
#     * 預設不計入勝負條件。
# - 新增 Pokémon 式 Substitute：
#     * 以 Battle Object 實作。
#     * 可設定 HP Cost Ratio；預設 25% Max HP。
#     * Basic / Projectile / Instant Direct Skill / Direct Beam 可先打替身。
#     * AOE / Zone / Chain / Bounce / Pierce 不被替身整片吸走。
# - 新增 Healing Totem Template。
# - 新增 :summon_unit Effect 與 SUMMON Verification Mode。
#
# 【v0.11 Battle Object Framework】
# - v0.10.2.1 DIRECTION 驗證正式通過，v0.10 戰鬥核心收束。
# - 新增通用 Battle Object：
#     * Decoy：可被普通攻擊鎖定／摧毀，能提高 Target Utility。
#     * Trap：Arm 後偵測敵人進入 Trigger Radius，一次觸發。
#     * Bomb：倒數後範圍爆炸；可設定被摧毀時提前爆炸。
#     * Totem：持續存在、定時對範圍單位施加 Effect。
#     * Delayed Skill Marker：不可選取的延遲落點，倒數後結算。
# - Battle Object 不算存活戰鬥單位，不影響勝負條件。
# - Skill Effect 新增 :battle_object，可直接由技能資料生成物件。
# - Skill AI 預設仍只對真正 Battler 施放技能；Decoy 主要干擾普通 Target，
#   避免 Poison / Pull / Fear 等技能對一顆炸彈做出哲學反應。
# - Targetable Object 可被 Basic Attack / Projectile / Crit 正常打壞。
# - Object SE 預留 spawn_se / trigger_se / destroy_se；未填即靜音。
# - Object VFX 使用簡潔 Pixel Sprite，角色仍保持畫面主體。
# - 新增 OBJECT Verification Mode，固定驗證：
#     Decoy Targeting / Destruction
#     Trap Proximity Trigger
#     Bomb Countdown
#     Totem Periodic Tick
#     Delayed Skill
# - DIRECTION / OBJECT Verification 期間會停用既有 DEF Aura Refresh，
#   讓 Sandbox 真正 deterministic。
#
# 【v0.10.2.1 Deterministic DIRECTION / True Blink Behind】
# - 修正 DIRECTION Verification 被正常 AI 普攻／位移污染：
#     DIRECTION 模式啟用 Combat Sandbox，一般 Target / Movement / Basic Attack
#     全部暫停，但固定 Verify Damage 仍照常執行。
# - Shield Trigger 固定驗證重新保證：
#     Shield 70 -> 40 -> 0
#     Energy 0 -> 5 -> 25
#     第二擊 60 時 HP Loss = 20。
# - 修正 blink_behind：
#     舊版只依 Ally / Enemy 左右側決定 X Offset，不是真正的「背後」。
#     新版依目標 Facing Vector 計算 Back Vector，並在場地邊界嘗試
#     後方、後左、後右候選點，選擇最符合背面 Arc 的合法位置。
# - BLINK Log 現在會附 arc=back/side/front。
# - 新增 DIRECTION 固定 BLINK_BACK 測試：
#     小拉達從傑尼龜正面起始，執行 blink_behind 後再打固定 100，
#     預期 arc=back、100 -> 115。
# - Verification 結束後 Sandbox 必定解除，正常戰鬥 AI 不受影響。
#
# 【v0.10.2 Directional Defense / Back Attack / Shield Trigger】
# - 新增 Direct Hit 方位判定，依被攻擊者目前 Facing 與攻擊來源的位置分類：
#     FRONT / SIDE / BACK。
# - 預設 Direct Hit 倍率：
#     FRONT 0.85x、SIDE 1.00x、BACK 1.15x。
# - FRONT 是 Directional Defense；BACK 會另外記錄 BACK_ATTACK。
# - 單位資料可個別覆寫 front / side / back damage multiplier，
#   後續坦克、刺客、Ability、MEGA 都能沿用，不必重寫傷害公式。
# - DoT / Zone / Sustained Beam / Sweeping Beam / Ground AOE / Chain / Bounce
#   預設不吃方向倍率；Basic / 單體 Direct Hit / Projectile / Pierce 可吃方向。
# - 新增 Shield Trigger：
#     * on_absorb：護盾實際吸收傷害時觸發。
#     * on_break：護盾被打破時觸發。
#     * 可指定 target=:self / :attacker。
#     * 可設定 absorb_cooldown，避免 DoT / 多段技能每幀觸發。
# - Shield Trigger 使用既有 Effect Framework，所以 Heal / Energy / Status /
#   Damage / Next Attack 等後續效果可共用同一條管線。
# - 新增 DIRECTION Verification Mode，固定驗證 FRONT / SIDE / BACK 與
#   Shield Absorb / Break Trigger。
# - 修正 Pierce：實際命中線重新使用 unit.pixel_x/y；
#   PMD Sprite 幾何中心只用於視覺 Beam，不再改變戰鬥碰撞線。
#
# 【v0.10.1 Energy System / Projectile Orbit Fix / 2px Bars】
# - 每個技能 SE 仍可獨立設定 cast_se / launch_se / hit_se / crit_se；
#   未設定才使用專案預設 Launch / Hit / Crit。
# - 弱／強 Tracking 是正式戰鬥機制，不只存在 HIT 測試。
# - 修正 Weak / Strong Projectile 射過目標後反覆繞圈：
#     * 進入近目標區域後記錄最近距離。
#     * 一旦明顯 Overshoot 且需大角度回頭，直接 PROJECTILE_LOST reason=overshoot。
#     * 追蹤仍可修正飛行弧線，但不再做 180 度回頭繞圈。
# - HP / Energy Bar 厚度 3px → 2px，兩條維持相同粗細；長度維持 29px。
# - 新增 Energy System：
#     * Gain：增加能量，受 Max Energy 與 Energy Lock 限制。
#     * Drain：扣除目標能量，不轉移給施術者。
#     * Steal：扣除目標能量，依實際扣除量轉移給施術者。
#     * Aura：跟隨施術者移動的能量 Aura，定時給範圍內單位能量。
#     * Lock：Debuff，期間禁止所有正向 Energy Gain；Drain 仍可生效。
# - 舊有能量規則正式常數化：
#     * 普攻命中 +28
#     * 承受實際 HP 傷害 +16
#     * 技能滿 100 自動施放並歸零
# - 新增 ENERGY Verification Mode，固定驗證 Gain / Drain / Steal / Lock / Aura。
#
# 【v0.10.0.1 Skill SE / Compact Unit Bars / HIT Verify Polish】
# - 技能 SE 從「只有接口」提升為實際可聽：
#     * 技能真正 Resolve／發出時播放 launch_se。
#     * 技能真正造成 Direct Hit 或支援效果落地時播放 hit_se。
#     * 同一技能短時間多目標命中會去重，避免 Chain / AOE 變成音效機關槍。
# - 若技能未指定 SE，技能 Launch / Hit 使用本專案自製的預設 PMD_MoveLaunch / PMD_MoveHit。
# - Crit / Evade 也提供預設 PMD_Crit / PMD_Evade；仍可逐技能／逐單位覆寫。
# - Cast SE 保留接口但沒有預設音，避免「開始蓄力」與「真正發出」混為一談。
# - HP Bar 與 Energy Bar 內長由 58px 改成 29px，精確縮短 50%。
# - HP Bar 厚度由 6px 改成 3px，與 Energy Bar 完全相同。
# - Shield Overlay 配合新細 HP Bar 改為 1px。
# - HIT 驗證：
#     * NEXT_CRIT 的下一擊加入 perfect tracking，避免必暴驗證彈丸自己飛丟。
#     * verification_force_evade_ready 會清除目標當前 Action，讓 Strong/Perfect Tracking
#       對 Active Evade 的驗證不會因「剛好正在攻擊」而被跳過。
#
# 【v0.10 Hit System / SE Hook Foundation】
# - v0.9.2.2 保留為 CORE_BASELINE，不改舊核心語意。
# - 新增 Direct Hit Crit：預設 5%，1.50x；DoT / Zone / Sustained Beam Tick 預設不可暴擊。
# - 新增 Active Evade：不是全域隨機閃避率，而是具有冷卻、可觀察位移的主動側閃。
# - 新增 Projectile Tracking：none / weak / strong / perfect 四級。
# - 新增 Projectile Lost：非必中投射物可因目標移動／Evade 真正射失。
# - 新增 Next Attack Modifier：下一次普通攻擊可掛 force_crit / power_multiplier / effects。
# - 新增 HIT Verification Mode，固定驗證 Crit、Next Attack、Evade Success/Fail、Tracking。
# - 新增 SE Hook 基礎：技能可設定 cast_se / launch_se / hit_se / crit_se / evade_se；
#   普攻亦可設定 basic_cast_se / basic_launch_se / basic_hit_se / crit_se / evade_se。
#   本版不附實際 SE 檔，不填資料就完全靜音；後續只需填 Audio/SE 檔名。
#
# 【v0.9.2.2 Victory Facing Down / v0.9 Core Freeze】
# - 勝利慶祝時，所有存活勝方寶可夢強制面向下方（PMD / VX numpad direction = 2）。
# - 同步重設 pending_dir，避免上一個戰鬥朝向在 MOVE 動作第一幀短暫殘留。
# - MOVE + 6px 上下跳慶祝保留，角色本體比例仍為 100%。
# - 新增 CORE_BASELINE = "0.9.2.2"，作為 v0.9 戰鬥核心封板基準。
# - CONTROL / BEAM / ZONE 驗證模式完整保留，後續 v0.10+ 可用來做 regression test。
# - 本版不新增 Crit / Evade / Tracking 等新規則；下一版 v0.10 才開始 Hit System。
#
# 【v0.9.2.1 Verification Resume / Victory Celebration】
# - 修正 CONTROL／BEAM／ZONE 驗證模式在排定測試完成後，auto_skill 一直維持 off，
#   導致後半場只剩普通攻擊。
# - 驗證項目完成後，自動恢復每隻寶可夢原本技能與正常自動技能 AI；
#   能量歸零後重新從普攻累積，因此後半場會回到正常技能循環。
# - CONTROL 於 frame 150、BEAM 於 frame 260、ZONE 於 frame 250 結束驗證鎖定。
# - 新增 [VERIFY] COMPLETE ... auto_skill=on。
# - 戰鬥勝負確定後，存活的勝方寶可夢：
#     1. 停止戰鬥 AI／位移
#     2. 切回 PMD MOVE（程式內 :walk）循環動作
#     3. 以 6 px 高度持續上下跳躍，並稍微錯開起跳時間
#   敗方與死亡單位保持原狀。
# - 新增 [VICTORY] ... MOVE_BOUNCE LOG。
#
# 【v0.9.2 Final Core Verification Pack】
# - 新增戰前驗證模式：S 鍵循環 NORMAL／CONTROL／BEAM／ZONE，Shift 開戰。
# - CONTROL：強制驗證 Channel Interrupt、Silence、Knockback、Dash。
# - BEAM：強制驗證 Bounce、Sustained Beam、Action Slow、Sweeping Beam。
# - ZONE：強制驗證 Healing Zone 與 Zone Avoidance AI。
# - 驗證模式會暫時把六隻單位 HP 放大 3 倍，停用自動技能，只保留普攻與排定的驗證技能，
#   避免測試還沒發生就先被正常戰鬥打死。
# - 新增 VERIFY / ACTION_TIMING / ZONE_AVOID LOG。
# - ESCAPE_FAIL 加入 24 frame 節流，避免牆角時每 4 frame 洗滿 LOG。
# - 新增「彈跳種子」Bounce 模板，正式讓 Bounce Delivery 有可測案例。
# - 本版不加入 Crit／隨機 Dodge；那是 v0.10 的下一層規則，先把現有核心逐項打靶。
#
# 【v0.9.1.5 Unified PMD Skill VFX】
# - 修正 v0.9.1.4 仍有大量技能命中效果走舊 Sprite_PMDChessEffect 的問題。
# - 舊 Sprite_PMDChessEffect 原本會每幀 zoom +0.035，造成 64x64 測試特效越放越大；
#   本版所有技能／狀態／支援效果改走 PMD Animations sprite sheet，舊類只保留 MISS。
# - Cast 特效改走 PMD muzzle，不再顯示旋轉放大的方框。
# - AOE 中心、Pierce 每個命中者、Chain 每個命中者、Instant 近戰技能皆補上屬性 PMD Impact。
# - 傑尼龜 Column 移除舊自繪 36x72 光柱，只保留縮小後的 PMD Column。
# - Heal / Shield / Cleanse / Dispel / Poison / Burn / Slow / Fear / Root / Taunt
#   等狀態效果改用小型 PMD 動畫，並加 45f 同類型去重，避免多效果同時疊成煙火大會。
# - 全部 PMD Burst 仍受 PMD_VFX_GLOBAL_SCALE = 0.50 控制；Unit Sprite 永遠 100%。
#
# 【v0.9.1.4 Anti-Pin Ranged AI / Refined PMD Impact VFX】
# - 修正 Artillery / Kiter 在緊急威脅狀態下「只逃跑、永遠不能普攻」的死角。
# - set_threat_escape_goal 現在會回報是否真的找到有效逃生位移，並加入純側移與朝場中央脫離候選。
# - 遠程被逼到牆邊／角落、且目標仍在射程內時，普攻冷卻完成會短暫停步反擊，
#   攻擊後再繼續嘗試拉距離；不再因 clamp 到邊界而一路挨打到死。
# - 新增 PIN_BREAK / ESCAPE_FAIL LOG，專門驗證角落脫困與被迫反擊。
# - PMD VFX Burst 全域縮放再乘 0.50；角色本體仍維持 100%，Beam 主體尺寸不變。
# - 命中後特效改用 Animations.zip 中更精緻、屬性更明確的 PMD 動畫：
#   Fire=M0223+M0253、Water=M0155+M0242、Electric=M0152+M0242、
#   Web=M0104+M0242、Seed=M0245_V001+M0242、Generic=M0224+M0242。
# - Projectile 命中時不再疊加舊版簡易 impact 色塊，避免「新 PMD Burst + 舊特效」雙重放大。
#
# 【v0.9.1.3 RGSS2 Rotation Sign / Chain Center Fix】
# - 修正 RGSS2 Sprite#angle 與數學 atan2 的旋轉正負方向相反問題。
# - Beam：目標在上方時不再錯誤斜向下方。
# - Projectile：飛行路徑原本正確，但 Sprite 朝向也同步修正。
# - Link / Chain：連鎖電擊等短命連線同步修正角度符號。
# - 連鎖技能視覺端點改用雙方 PMD Sprite 幾何中心，不再使用腳底 pixel_y。
# - Damage Link 視覺連線也改用 Sprite 中心。
# - 新增 VFX_LINK_ANCHOR LOG，方便驗證皮卡丘 Chain 每一跳的實際起訖座標。
#
# 【v0.9.1.2 Layered Beam / Visual Center / Projectile Polish】
# - Beam 主體改為五層像素漸層：低透明外暈→外色→主色→亮芯→白色中心。
# - Beam、Muzzle、Impact、Projectile 的起點／終點統一使用 PMD Sprite 當前 frame 的幾何中心，
#   不再依 collision_radius 推估，因此皮卡丘等角色不會從 Sprite 下半部射出。
# - Projectile 追蹤目標時也瞄準 Sprite 中心。
# - Electric 普攻投射物重畫為三層閃電：金色外暈→亮黃主體→近白色亮芯。
# - Water / Fire / Seed / Web / Neutral projectile 同步改為分層像素材質。
# - 新增 VFX_ANCHOR LOG，記錄 Beam／Projectile 的實際視覺起點，方便實機驗證。
#
# 【v0.9.1.1 RGSS2 Cache 相容修正】
# - 修正 PMD VFX Adapter 在 RPG Maker VX / RGSS2 的 Bitmap Cache 呼叫。
# - VX / RGSS2 使用 Cache.load_bitmap，不使用 RPG 命名空間下的 Cache。
# - 本版只修相容性，不改 VFX Profile、角色 100% 比例與戰鬥邏輯。
#
# 【v0.9.1 PMD VFX Adapter / Verification Prep】
# - 導入 PMD VFX Adapter：可讀取 Graphics/Animations/PMD_VFX/ 下的 PMD sprite sheet，
#   以 192x192 frame 播放 Muzzle／Impact／Column 類型特效。
# - 目前先接入火束／水束／電擊／蟲絲／泛用 Impact 五種樣式，實作為「端點動畫 + 細 Beam 主體」；
#   不改動既有命中判定與寶可夢本體 100% 顯示比例。
# - Beam／Column／Projectile 會自動呼叫對應端點特效；缺少素材時會安全退回舊版繪製。
# - 新增 PMD_VFX_PROFILES 常數，後續只需換 sheet 名稱與 frames，即可快速替換風格。
# - 本版先完成動畫接線與素材掛載，供後續 v0.9.1 測試 LOG 驗證使用。
#
# 【v0.9.0 Control / Space / Protection Core】
# - 寶可夢本體固定 100%，此規則延續且不得由 VFX 影響。
# - 新增完整控制層：Stun／Root／Silence／Fear；Slow 沿用 v0.8.4 三分法。
# - 新增 CC Resist 與 Boss 控制遞減（Diminishing Return）。
# - 新增 Pull／Dash／Blink 位移效果；強制位移可中斷可中斷型 Channeling。
# - 新增 Channeling／Interrupt：技能可設定施法時間、是否可中斷、被中斷時能量返還。
# - 新增 Zone：傷害／治療／Slow 等地面區域，並加入簡易危險區域避讓 AI。
# - 新增 Aura：可在一定半徑內持續刷新 Buff／Debuff。
# - 新增 Link：可將被保護者部分實際 HP 傷害轉移給守護者。
# - 新增 Projectile Intercept：Bodyguard 可攔截原本飛向附近隊友的投射物。
# - 新增 LOG：CONTROL／CC_DR／INTERRUPT／PULL／DASH／BLINK／ZONE／AURA／LINK／INTERCEPT。
# - v0.9.0 先建立共用核心；既有六隻技能只做必要擴充，避免同時改掉所有已驗證玩法。
#
# 【v0.8.4 100% Unit／Pixel Beam／Slow Framework】
# - 寶可夢本體顯示比例正式鎖定 100%，後續版本不得再由技能 VFX 調整角色縮放。
# - 技能特效維持獨立縮放；新增窄幅 Pixel Beam、持續 Beam、掃射 Beam、水柱效果。
# - Beam 使用亮芯＋外緣＋像素節點的低遮蔽繪製，不以巨大光球覆蓋角色。
# - 新增 Move Slow／Attack Slow／Action Slow，舊 :slow 保留為 Move Slow 相容別名。
# - Slow 套用時先計算 slow_resist，再受 SLOW_CAP 限制；LOG 記錄 raw／resist／effective。
# - Attack Slow 影響普攻動畫與攻擊間隔；Action Slow 影響技能前搖／後搖；Move Slow 影響 Pixel Movement。
# - 綠毛蟲「貫穿蟲絲」改為 Move Slow + Attack Slow，作為實戰驗證樣本。
# - 小火龍「火焰擴散」增加細窄火束視覺；傑尼龜「守護水幕」增加水柱視覺；
#   綠毛蟲貫穿技能增加蛛絲 Beam 視覺。命中規則與原技能不變。
# - 新增通用 :beam／:sustained_beam／:sweeping_beam delivery，先建立底層供後續技能直接配置。
#
# 【v0.8.3 角色／特效縮放分離 + 技能鎖定修正】
# - 修正 v0.8.1 對「動畫縮小」的誤解：PMD 角色本體於 v0.8.3 暫恢復為 82%；v0.8.4 起正式固定 100%。
# - 戰鬥特效、投射物改為獨立 50% 顯示縮放，不影響角色本體與命中判定。
# - Chain／Bounce 連線厚度同步縮小，但連線長度與命中邏輯完全不變。
# - enemy_targeted 單體技能在開始施放後鎖定原目標；原目標於前搖期間死亡時，
#   預設取消該次技能，不再於 Resolve 瞬間自動轉火新目標。
# - 可由技能資料 :retarget_on_resolve => true 明確允許重鎖。
# - LOG Header 同時記錄 Unit Scale 與 Effect Scale。
#
# 【v0.8.2 LOG／Debug 顯示修正】
# - AI Debug 標籤預設關閉，避免 41% PMD Sprite 被 16px 黑底字母完全遮住。
# - Status Debug 改放到 HP Bar 上方，不再蓋住角色本體。
# - 修正死亡單位仍繼續更新 DoT／HoT 狀態 Tick。
# - 死亡時清理自身 Status／Shield／Taunt，避免殘留 Debug 與無效計時。
# - Skill LOG 改記錄「實際技能資料使用的 policy」，不再誤顯示 Unit 預設 policy。
# - Heal LOG 即使實際回復 0 也會記錄 attempted／actual，方便確認治療效果有執行。
#
# 【v0.8.1 Test Logger／顯示縮放】
# - v0.8.1 曾將角色誤縮為 41%；v0.8.3 已恢復角色 82%，改縮戰鬥特效。
# - 新增自動戰鬥驗證 LOG：目標切換、技能、傷害、治療、護盾、狀態、嘲諷、
#   Chain／Bounce／Pierce、MISS、死亡與勝負均會記錄。
# - 每次進入 Scene 會重建 PMD_AutoChess_Battle.log；同一 Scene 內重打會保留多場紀錄。
# - 戰鬥結束自動寫入事件統計摘要，方便直接上傳 LOG 檢查機制。
#
# 【v0.8 Skill AI／支援與狀態／Taunt／Chain／Pierce】
# - Skill Policy 正式接入；技能目標與一般攻擊目標分離。
# - 新增 Heal／Shield／HoT／Buff／Debuff／DoT／Cleanse／Dispel 通用效果框架。
# - 新增 Status Tags 與 stacking mode（refresh／stack／replace_stronger）。
# - 新增 Taunt / Forced Target：有持續時間，可強制一般攻擊與 enemy_targeted 技能。
# - Ground／Ally／Self 技能不受一般 Taunt 改向；技能可設 ignore_taunt。
# - 新增 Chain／Bounce／Pierce 通用傳遞模式。
# - 新增 Skill Cast / Hold 條件：補血不浪費、範圍技可等待群聚後再放。
# - 原型六隻重新配置技能，用來實測吸血＋中毒、燃燒 AOE、護盾＋補血＋範圍嘲諷、
#   貫穿＋緩速、收割＋破防、連鎖電擊。
# - 狀態與護盾加入簡易 Debug 顯示；正式版可關閉。
#
# 【v0.7 通用 AI Framework】
# - 將 AI 拆分為 Target／Movement／Threat／Skill 四個可組合策略軸。
# - 新增 Target Commitment 與換目標遲滯，避免角色頻繁左右抽搐。
# - 目標選擇不再只靠單一 target_rule，改用通用 utility score。
# - Movement Policy 實作：Frontline／Bruiser／Assassin／Kiter／Artillery／
#   Controller／Bodyguard／Berserker 八種行動模式。
# - Target Policy 實作：最近、殘血、最低防、最高攻、後排、遠程優先、
#   近戰優先、群聚、最近攻擊者、後排脆皮、護衛威脅等。
# - AI 目標重新評估採降頻處理；移動仍沿用 4 frame 邏輯 tick。
# - Debug 顯示可直接看到每隻單位目前 Movement／Target Policy。
#
# 【v0.6 遠程威脅反應／Pixel Movement AI】
# - PMD 角色本體維持 82%；v0.8.3 起戰鬥特效改用獨立縮放。
# - 遠程單位正式分離「攻擊目標」與「威脅來源」。
# - 記錄最近攻擊者；威脅來源依距離、近戰、正在攻擊自己、最近攻擊者加權。
# - 遠程分成安全／受壓／緊急三段反應。
# - 受壓時維持原攻擊目標並重新走位，攻擊冷卻完成時可停步反擊。
# - 緊急貼身時優先撤離，必要時暫時把近身威脅改成攻擊目標。
# - 脫離緊急狀態後會恢復原本的戰術索敵，不會永久記仇。
# - 逃跑加入左右側移與邊界評分，降低貼牆原地倒車。
# - 原型階段顯示「!／!!」威脅標記，方便實機確認 AI 是否觸發。
#
# 【v0.5.1 RGSS2 Viewport 相容修正】
# - 修正 RGSS2 的 Viewport 沒有 disposed? 方法而造成 Scene 一開即報錯。
# - update_camera_shake 不再呼叫 Viewport#disposed?。
# - terminate 以旗標安全釋放 Viewport，避免離場時再次觸發相同錯誤。
#
# 【v0.5 戰鬥表現與戰術 AI】
# - 保留 v0.4 的戰前棋格、戰中 Pixel Movement、軟碰撞與攻擊槽。
# - 近戰攻擊與技能加入「只影響表演、不改變碰撞座標」的前衝動作。
# - 受擊者加入視覺後仰、白色閃光與小幅畫面震動。
# - 投射物依水、火、蟲絲、電、種子等風格呈現，不再全部使用同一光點。
# - 技能發動前加入蓄力提示；連鎖電擊加入目標間的連線效果。
# - 傑尼龜控制技能與火焰範圍技能加入實際位移，可自然造成攻擊落空。
# - 單位新增前衛、鬥士、控場、刺客、術士定位與目標評分。
# - 統計實際落空次數；沒有隨機 MISS，只有 HitFrame 時真的離開有效距離才落空。
#
# 【定位原則】
# 動畫只負責表演；命中由戰鬥資料、HitFrame、距離與投射物決定。
# PMD Offsets 仍不在遊戲執行時逐格參與碰撞。
#==============================================================================

$imported = {} if $imported == nil
$imported["PMD_AutoChess_Proto"] = "0.15"

module PMD_AC
  VERSION = "0.15"
  CORE_BASELINE = "0.9.2.2"

  GRID_COLS = 6
  GRID_ROWS = 5
  CELL_W = 72
  CELL_H = 58
  GRID_X = 56
  GRID_Y = 72

  LOGIC_TICK = 4
  MAX_ENERGY = 100
  ENERGY_ON_BASIC_HIT = 28
  ENERGY_ON_DAMAGE_TAKEN = 16
  ENERGY_LOG_PASSIVE_FLOW = false
  PMD_ROOT = "Graphics/PMD/"

  # 像素移動參數
  ACCELERATION = 0.22
  STOP_DAMPING = 0.64
  ARRIVAL_RADIUS = 4.0
  DIRECTION_HOLD_FRAMES = 3
  MELEE_HIT_GRACE = 10.0
  ATTACK_SLOT_GAP = 5.0
  AOE_RADIUS = 76.0
  PROJECTILE_SPEED = 7.0
  PROJECTILE_RADIUS = 5.0
  PROJECTILE_LIFE = 180
  BASIC_LUNGE_DISTANCE = 9.0
  SKILL_LUNGE_DISTANCE = 14.0
  RECOIL_DAMPING = 0.72
  RECOIL_LIMIT = 9.0
  KNOCKBACK_DAMPING = 0.82
  CAMERA_SHAKE_MAX = 5

  # v0.6 顯示與遠程威脅 AI
  UNIT_SPRITE_SCALE = 1.00
  EFFECT_SPRITE_SCALE = 0.50
  PROJECTILE_SPRITE_SCALE = 0.50
  LINK_EFFECT_THICKNESS_SCALE = 0.50
  BEAM_DEFAULT_LIFE = 16
  BEAM_DEFAULT_WIDTH = 7.0
  BEAM_SUSTAIN_TICK = 12
  SLOW_CAP = 0.70
  SLOW_RESIST_MAX = 0.80
  SHOW_THREAT_DEBUG = true
  THREAT_SCAN_RANGE = 138.0
  THREAT_PRESSURE_RANGE = 102.0
  THREAT_EMERGENCY_RANGE = 58.0
  THREAT_MEMORY_FRAMES = 150
  THREAT_RETARGET_COOLDOWN = 42
  THREAT_RELEASE_FRAMES = 48
  THREAT_PRESSURE_STEP = 54.0
  THREAT_EMERGENCY_STEP = 78.0

  # v0.7 通用 AI Framework
  SHOW_AI_DEBUG = false
  AI_TARGET_REEVALUATE_FRAMES = 12
  AI_TARGET_REEVALUATE_JITTER = 8
  AI_SWITCH_THRESHOLD_MIN = 1.10
  AI_SWITCH_THRESHOLD_MAX = 1.34
  AI_BODYGUARD_LEASH = 92.0
  AI_BODYGUARD_OFFSET = 56.0
  AI_ASSASSIN_FLANK_OFFSET = 54.0
  AI_ARTILLERY_RANGE_BONUS = 24.0
  AI_BERSERKER_HP_RATE = 0.35
  AI_BERSERKER_SPEED_BONUS = 1.18
  AI_EDGE_MARGIN = 20.0
  AI_ESCAPE_MIN_MOVE = 8.0
  AI_ESCAPE_MIN_GAIN = 3.0
  ESCAPE_FAIL_LOG_INTERVAL = 24

  VERIFICATION_MODES = [:normal, :control, :beam, :zone, :hit, :energy,
                        :direction, :object, :summon, :identity]
  VERIFICATION_LABELS = {
    :normal => "NORMAL",
    :control => "CONTROL",
    :beam => "BEAM",
    :zone => "ZONE",
    :hit => "HIT",
    :energy => "ENERGY",
    :direction => "DIRECTION",
    :object => "OBJECT",
    :summon => "SUMMON",
    :identity => "IDENTITY"
  }
  VERIFICATION_HP_MULTIPLIER = 3.0
  VERIFICATION_CONTROL_END_FRAME = 150
  VERIFICATION_BEAM_END_FRAME = 260
  VERIFICATION_ZONE_END_FRAME = 250
  VERIFICATION_HIT_END_FRAME = 330
  VERIFICATION_ENERGY_END_FRAME = 320
  VERIFICATION_DIRECTION_END_FRAME = 280
  VERIFICATION_OBJECT_END_FRAME = 350
  VERIFICATION_SUMMON_END_FRAME = 360
  VERIFICATION_IDENTITY_END_FRAME = 170

  # v0.11.5 Pokémon Identity
  TEMP_INSTANCE_UID_START = 100000

  # v0.11.1 Summon / Substitute
  SUMMON_MAX_PER_TEAM = 4
  SUMMON_DEFAULT_DURATION = 180
  SUMMON_DEFEAT_FAINT_FRAMES = 24
  SUBSTITUTE_DEFAULT_HP_RATIO = 0.25
  SUBSTITUTE_INTERCEPT_RADIUS = 46.0

  # v0.11 Battle Object
  BATTLE_OBJECT_MAX = 16
  BATTLE_OBJECT_ID_BASE = 1000
  BATTLE_OBJECT_DEFAULT_RADIUS = 14.0
  BATTLE_OBJECT_DEFAULT_DURATION = 180
  BATTLE_OBJECT_HP_BAR_WIDTH = 22
  BATTLE_OBJECT_HP_BAR_HEIGHT = 2

  # v0.10.2 Directional Hit
  DIRECTION_FRONT_DOT = 0.50
  DIRECTION_FRONT_MULTIPLIER = 0.85
  DIRECTION_SIDE_MULTIPLIER = 1.00
  DIRECTION_BACK_MULTIPLIER = 1.15

  # v0.10 Hit System
  BASE_CRIT_RATE = 0.05
  BASE_CRIT_MULTIPLIER = 1.50

  ACTIVE_EVADE_DISTANCE = 48.0
  ACTIVE_EVADE_COOLDOWN = 210
  ACTIVE_EVADE_TRIGGER_DISTANCE = 58.0
  ACTIVE_EVADE_VISUAL_FRAMES = 12

  PROJECTILE_TRACKING_TURN_RATE = {
    :none => 0.0,
    :weak => 4.0,
    :strong => 10.0,
    :perfect => 180.0
  }

  # Weak / Strong Homing 只允許修正飛行弧線，不允許射過頭後繞回來。
  PROJECTILE_ORBIT_BREAK_RADIUS = 54.0
  PROJECTILE_OVERSHOOT_TOLERANCE = 5.0
  PROJECTILE_OVERSHOOT_FRAMES = 3
  PROJECTILE_MAX_REACQUIRE_ANGLE = 105.0

  # SE Hook。name 空白／nil 時不播放。
  SE_ENABLED = true
  SE_DEFAULT_VOLUME = 80
  SE_DEFAULT_PITCH = 100

  # 未指定技能 SE 時的專案預設音。
  DEFAULT_SKILL_LAUNCH_SE = {
    :name => "PMD_MoveLaunch", :volume => 76, :pitch => 100
  }
  DEFAULT_SKILL_HIT_SE = {
    :name => "PMD_MoveHit", :volume => 82, :pitch => 100
  }
  DEFAULT_CRIT_SE = {
    :name => "PMD_Crit", :volume => 88, :pitch => 104
  }
  DEFAULT_EVADE_SE = {
    :name => "PMD_Evade", :volume => 74, :pitch => 105
  }
  SKILL_HIT_SE_DEDUP_FRAMES = 8

  # v0.10.0.1：角色頭頂 HP / Energy 條
  # 舊內長 58px → 新內長 29px，精確 50%。
  UNIT_BAR_INNER_WIDTH = 29
  UNIT_BAR_WIDTH = 33
  UNIT_BAR_HEIGHT = 9
  UNIT_BAR_THICKNESS = 2

  VICTORY_BOUNCE_HEIGHT = 6.0
  VICTORY_BOUNCE_PERIOD = 28
  VICTORY_BOUNCE_STAGGER = 3


  # v0.8 Skill AI / Status / Taunt
  SHOW_STATUS_DEBUG = true
  SKILL_REEVALUATE_FRAMES = 8
  SKILL_FORCE_CAST_AFTER = 90
  STATUS_DEFAULT_INTERVAL = 30
  STATUS_MAX_STACKS = 5
  TAUNT_DEFAULT_DURATION = 120

  # v0.9 Control / Space / Protection
  CC_RESIST_MAX = 0.80
  CC_DR_RESET_FRAMES = 300
  CC_DR_STEPS = [1.00, 0.65, 0.40, 0.20]
  FEAR_ESCAPE_DISTANCE = 110.0
  ZONE_DEFAULT_DURATION = 180
  ZONE_DEFAULT_INTERVAL = 30
  ZONE_AVOID_STRENGTH = 1.65
  AURA_REFRESH_INTERVAL = 12
  LINK_DEFAULT_RATIO = 0.25
  PROJECTILE_INTERCEPT_RADIUS = 52.0


  # v0.9.1 PMD VFX Adapter
  PMD_VFX_FOLDER = "Graphics/Animations/PMD_VFX/"
  PMD_VFX_CELL_SIZE = 192
  PMD_VFX_DEFAULT_FPS = 3
  PMD_VFX_DEFAULT_ZOOM = 0.22
  # 使用者要求：Animations 素材目前放大效果再縮小一半。
  # 只作用於 PMD sheet Burst，不影響 Unit 100%、Beam 長條與 Projectile 本體。
  PMD_VFX_GLOBAL_SCALE = 0.50
  PMD_VFX_BEAM_IMPACT_DELAY = 6

  # v0.9.1.4：命中 Burst 改為多層 PMD 動畫。
  # :delay 是相對於 Impact 觸發時間的額外延遲。
  PMD_VFX_IMPACT_LAYERS = {
    :light => [
      {:sheet => "PMD_EOS_M0224_V000", :frames => (0..11).to_a,
       :zoom => 0.24, :oy => 96, :fps => 2, :delay => 0},
      {:sheet => "PMD_EOS_M0242_V000", :frames => (0..9).to_a,
       :zoom => 0.18, :oy => 96, :fps => 2, :delay => 2}
    ],
    :impact => [
      {:sheet => "PMD_EOS_M0224_V000", :frames => (0..11).to_a,
       :zoom => 0.22, :oy => 96, :fps => 2, :delay => 0},
      {:sheet => "PMD_EOS_M0242_V000", :frames => (0..9).to_a,
       :zoom => 0.16, :oy => 96, :fps => 2, :delay => 1}
    ],
    :fire => [
      {:sheet => "PMD_EOS_M0223_V000", :frames => (0..14).to_a,
       :zoom => 0.24, :oy => 96, :fps => 2, :delay => 0},
      {:sheet => "PMD_EOS_M0253_V000", :frames => (0..5).to_a,
       :zoom => 0.18, :oy => 96, :fps => 2, :delay => 1}
    ],
    :water => [
      {:sheet => "PMD_EOS_M0155_V000", :frames => (0..9).to_a,
       :zoom => 0.24, :oy => 96, :fps => 2, :delay => 0},
      {:sheet => "PMD_EOS_M0242_V000", :frames => (0..9).to_a,
       :zoom => 0.14, :oy => 96, :fps => 2, :delay => 2}
    ],
    :electric => [
      {:sheet => "PMD_EOS_M0152_V000", :frames => (0..9).to_a,
       :zoom => 0.24, :oy => 96, :fps => 2, :delay => 0},
      {:sheet => "PMD_EOS_M0242_V000", :frames => (0..9).to_a,
       :zoom => 0.17, :oy => 96, :fps => 2, :delay => 1}
    ],
    :web => [
      {:sheet => "PMD_EOS_M0104_V000", :frames => (0..9).to_a,
       :zoom => 0.22, :oy => 96, :fps => 2, :delay => 0},
      {:sheet => "PMD_EOS_M0242_V000", :frames => (0..9).to_a,
       :zoom => 0.12, :oy => 96, :fps => 2, :delay => 2}
    ],
    :seed => [
      {:sheet => "PMD_EOS_M0245_V001", :frames => (0..12).to_a,
       :zoom => 0.23, :oy => 96, :fps => 2, :delay => 0},
      {:sheet => "PMD_EOS_M0242_V000", :frames => (0..9).to_a,
       :zoom => 0.12, :oy => 96, :fps => 2, :delay => 2}
    ]
  }
  PMD_VFX_PROFILES = {
    :light => {
      :muzzle => {:sheet => "PMD_EOS_M0111_V000", :frames => (0..9).to_a, :zoom => 0.18, :oy => 120, :fps => 3},
      :impact => {:sheet => "PMD_EOS_M0010_V000", :frames => (5..18).to_a, :zoom => 0.20, :oy => 96, :fps => 3},
      :column => {:sheet => "PMD_EOS_M0111_V000", :frames => (0..9).to_a, :zoom => 0.24, :oy => 112, :fps => 3}
    },
    :fire => {
      :muzzle => {:sheet => "PMD_EOS_M0121_V000", :frames => (0..14).to_a, :zoom => 0.18, :oy => 112, :fps => 3},
      :impact => {:sheet => "PMD_EOS_M0010_V000", :frames => (5..18).to_a, :zoom => 0.20, :oy => 96, :fps => 3},
      :column => {:sheet => "PMD_EOS_M0121_V000", :frames => (0..14).to_a, :zoom => 0.22, :oy => 112, :fps => 3}
    },
    :water => {
      :muzzle => {:sheet => "skill_anim", :frames => (0..4).to_a, :zoom => 0.20, :oy => 112, :fps => 3},
      :impact => {:sheet => "PMD_EOS_M0013_V000", :frames => (0..4).to_a, :zoom => 0.22, :oy => 104, :fps => 3},
      :column => {:sheet => "skill_anim", :frames => (0..4).to_a, :zoom => 0.28, :oy => 108, :fps => 3}
    },
    :electric => {
      :muzzle => {:sheet => "PMD_EOS_M0111_V000", :frames => (0..9).to_a, :zoom => 0.18, :oy => 118, :fps => 3},
      :impact => {:sheet => "PMD_EOS_M0010_V000", :frames => (0..18).to_a, :zoom => 0.22, :oy => 96, :fps => 3},
      :column => {:sheet => "PMD_EOS_M0111_V000", :frames => (0..9).to_a, :zoom => 0.24, :oy => 112, :fps => 3}
    },
    :web => {
      :muzzle => {:sheet => "PMD_EOS_M0122_V000", :frames => (0..11).to_a, :zoom => 0.18, :oy => 112, :fps => 3},
      :impact => {:sheet => "PMD_EOS_M0122_V000", :frames => (0..11).to_a, :zoom => 0.18, :oy => 104, :fps => 3},
      :column => {:sheet => "PMD_EOS_M0122_V000", :frames => (0..11).to_a, :zoom => 0.22, :oy => 112, :fps => 3}
    },
    :seed => {
      :muzzle => {:sheet => "PMD_EOS_M0010_V000", :frames => (0..10).to_a, :zoom => 0.16, :oy => 112, :fps => 3},
      :impact => {:sheet => "PMD_EOS_M0010_V000", :frames => (5..18).to_a, :zoom => 0.18, :oy => 96, :fps => 3},
      :column => {:sheet => "PMD_EOS_M0010_V000", :frames => (5..18).to_a, :zoom => 0.20, :oy => 104, :fps => 3}
    },
    :impact => {
      :impact => {:sheet => "PMD_EOS_M0010_V000", :frames => (5..18).to_a, :zoom => 0.20, :oy => 96, :fps => 3}
    }

  }

  # v0.9.1.5：非傷害型／狀態型 VFX。
  # 這些 zoom 仍會再乘 PMD_VFX_GLOBAL_SCALE，因此實際顯示非常小。
  PMD_VFX_EVENT_DEDUP_FRAMES = 45
  PMD_VFX_EVENT_LAYERS = {
    :heal => [
      {:sheet => "PMD_EOS_M0247_V000", :frames => (0..10).to_a,
       :zoom => 0.16, :oy => 96, :fps => 2, :delay => 0},
      {:sheet => "PMD_EOS_M0256_V000", :frames => (0..8).to_a,
       :zoom => 0.10, :oy => 96, :fps => 2, :delay => 2}
    ],
    :shield => [
      {:sheet => "PMD_EOS_M0239_V000", :frames => (0..12).to_a,
       :zoom => 0.17, :oy => 96, :fps => 2, :delay => 0}
    ],
    :cleanse => [
      {:sheet => "PMD_EOS_M0256_V000", :frames => (0..8).to_a,
       :zoom => 0.14, :oy => 96, :fps => 2, :delay => 0}
    ],
    :dispel => [
      {:sheet => "PMD_EOS_M0234_V000", :frames => (0..12).to_a,
       :zoom => 0.13, :oy => 96, :fps => 2, :delay => 0}
    ],
    :drain => [
      {:sheet => "PMD_EOS_M0245_V001", :frames => (0..12).to_a,
       :zoom => 0.15, :oy => 96, :fps => 2, :delay => 0}
    ],
    :poison => [
      {:sheet => "PMD_EOS_M0196_V000", :frames => (0..10).to_a,
       :zoom => 0.12, :oy => 96, :fps => 2, :delay => 0}
    ],
    :burn => [
      {:sheet => "PMD_EOS_M0225_V000", :frames => (0..9).to_a,
       :zoom => 0.13, :oy => 96, :fps => 2, :delay => 0}
    ],
    :debuff => [
      {:sheet => "PMD_EOS_M0234_V000", :frames => (0..12).to_a,
       :zoom => 0.11, :oy => 96, :fps => 2, :delay => 0}
    ],
    :buff => [
      {:sheet => "PMD_EOS_M0247_V000", :frames => (0..10).to_a,
       :zoom => 0.11, :oy => 96, :fps => 2, :delay => 0}
    ],
    :control => [
      {:sheet => "PMD_EOS_M0219_V000", :frames => (0..10).to_a,
       :zoom => 0.11, :oy => 96, :fps => 2, :delay => 0}
    ],
    :stun => [
      {:sheet => "PMD_EOS_M0152_V000", :frames => (0..9).to_a,
       :zoom => 0.13, :oy => 96, :fps => 2, :delay => 0}
    ],
    :root => [
      {:sheet => "PMD_EOS_M0122_V000", :frames => (0..11).to_a,
       :zoom => 0.12, :oy => 96, :fps => 2, :delay => 0}
    ],
    :taunt => [
      {:sheet => "PMD_EOS_M0204_V000", :frames => (0..10).to_a,
       :zoom => 0.11, :oy => 96, :fps => 2, :delay => 0}
    ]
  }

  def self.vfx_event_key(type)
    case type
    when :heal, :regen
      return :heal
    when :shield
      return :shield
    when :cleanse
      return :cleanse
    when :dispel
      return :dispel
    when :drain, :seed, :energy_drain, :energy_steal
      return :drain
    when :poison
      return :poison
    when :burn, :fire
      return :burn
    when :def_up, :atk_up, :def_aura, :energy_gain, :energy_aura
      return :buff
    when :slow, :move_slow, :attack_slow, :atk_down, :def_down, :fear,
         :energy_lock
      return :debuff
    when :stun, :electric, :chain
      return :stun
    when :root, :web
      return :root
    when :taunt
      return :taunt
    when :impact, :slash
      return :impact
    else
      return :control
    end
  end

  def self.vfx_event_layers(type)
    key = vfx_event_key(type)
    return PMD_VFX_IMPACT_LAYERS[:impact] if key == :impact
    return PMD_VFX_EVENT_LAYERS[key] || PMD_VFX_EVENT_LAYERS[:control]
  end

  def self.vfx_profile(style)
    return PMD_VFX_PROFILES[style] || PMD_VFX_PROFILES[:light]
  end

  def self.vfx_impact_layers(style)
    layers = PMD_VFX_IMPACT_LAYERS[style]
    layers = PMD_VFX_IMPACT_LAYERS[:light] if layers == nil
    return layers
  end

  # v0.8.1 自動驗證 LOG
  BATTLE_LOG_ENABLED = true
  BATTLE_LOG_FILE = "PMD_AutoChess_Battle.log"
  BATTLE_LOG_DAMAGE = true
  BATTLE_LOG_TARGET = true
  BATTLE_LOG_THREAT = true

  STATUS_DEFS = {
    :poison => {
      :tags => [:debuff, :poison, :dot],
      :tick_type => :damage, :interval => 30, :stack_mode => :refresh
    },
    :burn => {
      :tags => [:debuff, :burn, :dot],
      :tick_type => :damage, :interval => 30, :stack_mode => :refresh
    },
    :regen => {
      :tags => [:buff, :hot],
      :tick_type => :heal, :interval => 30, :stack_mode => :refresh
    },
    # :slow 為舊資料相容別名，行為等同 Move Slow。
    :slow => {
      :tags => [:debuff, :slow, :move_slow],
      :stat => :move_speed, :stack_mode => :replace_stronger
    },
    :move_slow => {
      :tags => [:debuff, :slow, :move_slow],
      :stat => :move_speed, :stack_mode => :replace_stronger
    },
    :attack_slow => {
      :tags => [:debuff, :slow, :attack_slow],
      :stat => :attack_speed, :stack_mode => :replace_stronger
    },
    :action_slow => {
      :tags => [:debuff, :slow, :action_slow],
      :stat => :action_speed, :stack_mode => :replace_stronger
    },
    :root => {
      :tags => [:debuff, :control, :root],
      :stack_mode => :refresh
    },
    :silence => {
      :tags => [:debuff, :control, :silence],
      :stack_mode => :refresh
    },
    :fear => {
      :tags => [:debuff, :control, :fear],
      :stack_mode => :refresh
    },
    :atk_down => {
      :tags => [:debuff, :atk_down],
      :stat => :atk, :stack_mode => :replace_stronger
    },
    :def_down => {
      :tags => [:debuff, :def_down],
      :stat => :def, :stack_mode => :replace_stronger
    },
    :atk_up => {
      :tags => [:buff, :atk_up],
      :stat => :atk, :stack_mode => :replace_stronger
    },
    :def_up => {
      :tags => [:buff, :def_up],
      :stat => :def, :stack_mode => :replace_stronger
    },
    :def_aura => {
      :tags => [:buff, :aura, :def_up],
      :stat => :def, :stack_mode => :replace_stronger
    },
    :energy_lock => {
      :tags => [:debuff, :energy, :energy_lock],
      :stack_mode => :refresh
    }
  }

  SKILL_DATA = {
    :vine_drain => {
      :name => "寄生吸取",
      :target_type => :enemy_targeted,
      :policy => :current_target,
      :delivery => :projectile,
      :projectile_tracking => :weak,
      # 可選 SE Hook：
      # :cast_se=>..., :launch_se=>..., :hit_se=>..., :crit_se=>...
      :effects => [
        {:type => :damage, :power => 135},
        {:type => :drain, :ratio => 0.50},
        {:type => :pull, :distance => 22.0},
        {:type => :control, :control => :root, :duration => 36},
        {:type => :status, :status => :poison, :duration => 180,
         :value => 18, :interval => 30, :stack_mode => :refresh}
      ]
    },
    :flame_burst => {
      :name => "火焰擴散",
      :target_type => :ground_enemy,
      :policy => :best_cluster,
      :delivery => :aoe,
      :radius => 78.0,
      :minimum_cluster => 2,
      :beam_visual => :fire,
      :beam_width => 8.0,
      :zone => {
        :style => :fire, :radius => 66.0, :duration => 120,
        :interval => 30, :scope => :enemies, :harmful => true,
        :effects => [
          {:type => :damage, :power => 24},
          {:type => :status, :status => :burn, :duration => 45,
           :value => 8, :interval => 30, :stack_mode => :refresh}
        ]
      },
      :effects => [
        {:type => :damage, :power => 118},
        {:type => :status, :status => :burn, :duration => 150,
         :value => 16, :interval => 30, :stack_mode => :refresh}
      ]
    },
    :guardian_tide => {
      :name => "守護水幕",
      :target_type => :ally,
      :policy => :protect_ally,
      :delivery => :instant,
      :ally_hp_below => 0.92,
      :cast_if_threatened => true,
      :column_visual => :water,
      :effects => [
        {:type => :heal, :flat => 80},
        {:type => :hot, :duration => 120, :value => 14,
         :interval => 30, :stack_mode => :refresh},
        {:type => :shield, :flat => 150, :duration => 180},
        {:type => :status, :status => :def_up, :duration => 150,
         :value => 0.12, :stack_mode => :replace_stronger},
        {:type => :cleanse, :tags => [:debuff]},
        {:type => :link, :ratio => 0.25, :duration => 180},
        {:type => :taunt_area, :radius => 108.0, :duration => 120, :center => :target}
      ]
    },
    :web_pierce => {
      :name => "貫穿蟲絲",
      :target_type => :enemy_targeted,
      :policy => :best_cluster,
      :delivery => :pierce,
      :pierce_length => 245.0,
      :pierce_width => 18.0,
      :max_hits => 3,
      :damage_decay => 0.82,
      :beam_visual => :web,
      :beam_width => 5.0,
      :effects => [
        {:type => :damage, :power => 108},
        {:type => :status, :status => :move_slow, :duration => 150,
         :value => 0.30, :stack_mode => :replace_stronger},
        {:type => :status, :status => :attack_slow, :duration => 120,
         :value => 0.15, :stack_mode => :replace_stronger}
      ]
    },
    :rending_assault => {
      :name => "裂傷突襲",
      :target_type => :enemy_targeted,
      :policy => :execute,
      :delivery => :instant,
      :global_range => true,
      :pre_move => :blink,
      :blink_offset => 34.0,
      :interruptible => true,
      :effects => [
        {:type => :dispel, :tags => [:buff]},
        {:type => :damage, :power => 205},
        {:type => :control, :control => :fear, :duration => 42},
        {:type => :status, :status => :def_down, :duration => 150,
         :value => 0.18, :stack_mode => :replace_stronger}
      ]
    },
    :chain_lightning => {
      :name => "連鎖電擊",
      :target_type => :enemy_targeted,
      :policy => :best_cluster,
      :delivery => :chain,
      :channeling => true,
      :interruptible => true,
      :cast_frames => 42,
      :hit_frame => 10,
      :interrupt_refund => 30,
      :max_hits => 3,
      :bounce_radius => 150.0,
      :damage_decay => 0.76,
      :effects => [
        {:type => :damage, :power => 138},
        {:type => :control, :control => :stun, :duration => 24},
        {:type => :status, :status => :atk_down, :duration => 120,
         :value => 0.12, :stack_mode => :replace_stronger}
      ]
    },

    # v0.8.4 通用 Beam 範例。尚未配置給六隻測試單位，
    # 後續只要把 UNIT_DATA 的 :skill 指向這些資料即可直接驗證。
    :frost_beam => {
      :name => "凍結光束",
      :target_type => :enemy_targeted,
      :policy => :current_target,
      :delivery => :sustained_beam,
      :beam_style => :light,
      :beam_width => 7.0,
      :duration => 72,
      :tick_interval => 12,
      :tick_effects => [
        {:type => :damage, :power => 32},
        {:type => :status, :status => :move_slow, :duration => 90,
         :value => 0.18, :stack_mode => :stack},
        {:type => :status, :status => :action_slow, :duration => 90,
         :value => 0.10, :stack_mode => :replace_stronger}
      ]
    },
    :water_lance => {
      :name => "高壓水柱",
      :target_type => :enemy_targeted,
      :policy => :current_target,
      :delivery => :beam,
      :beam_style => :water,
      :beam_width => 9.0,
      :effects => [
        {:type => :damage, :power => 155},
        {:type => :status, :status => :move_slow, :duration => 120,
         :value => 0.25, :stack_mode => :replace_stronger}
      ]
    },
    :fire_sweep => {
      :name => "扇形火束",
      :target_type => :ground_enemy,
      :policy => :best_cluster,
      :delivery => :sweeping_beam,
      :beam_style => :fire,
      :beam_width => 10.0,
      :beam_length => 240.0,
      :sweep_angle => 70.0,
      :duration => 48,
      :effects => [
        {:type => :damage, :power => 92},
        {:type => :status, :status => :burn, :duration => 120,
         :value => 12, :interval => 30, :stack_mode => :refresh}
      ]
    },

    # v0.9 控制／空間效果模板。核心已完成，未全部配置給六隻原型。
    :tidal_push => {
      :name => "潮汐衝擊",
      :target_type => :enemy_targeted,
      :policy => :current_target,
      :delivery => :beam,
      :beam_style => :water,
      :effects => [
        {:type => :damage, :power => 125},
        {:type => :knockback, :distance => 42.0},
        {:type => :control, :control => :silence, :duration => 48}
      ]
    },
    :dash_strike => {
      :name => "疾影突襲",
      :target_type => :enemy_targeted,
      :policy => :execute,
      :delivery => :instant,
      :global_range => true,
      :pre_move => :dash,
      :dash_distance => 110.0,
      :interruptible => true,
      :effects => [
        {:type => :damage, :power => 170}
      ]
    },
    :healing_field => {
      :name => "生命領域",
      :target_type => :ally,
      :policy => :lowest_ally,
      :delivery => :instant,
      :zone => {
        :style => :heal, :radius => 76.0, :duration => 180,
        :interval => 30, :scope => :allies, :harmful => false,
        :effects => [
          {:type => :heal, :flat => 22},
          {:type => :hot, :duration => 45, :value => 8,
           :interval => 30, :stack_mode => :refresh}
        ]
      },
      :effects => [
        {:type => :heal, :flat => 60}
      ]
    },
    :ricochet_seed => {
      :name => "彈跳種子",
      :target_type => :enemy_targeted,
      :policy => :current_target,
      :delivery => :bounce,
      :max_hits => 3,
      :bounce_radius => 170.0,
      :damage_decay => 0.78,
      :effects => [
        {:type => :damage, :power => 105}
      ]
    },

    # v0.10.1 Energy System Templates
    # 尚未正式配置給六隻原型，先由 ENERGY Verification 驗證核心。
    :energy_charge => {
      :name => "能量充能",
      :target_type => :ally,
      :policy => :lowest_ally,
      :delivery => :instant,
      :effects => [
        {:type => :energy_gain, :flat => 30}
      ]
    },
    :energy_siphon => {
      :name => "能量虹吸",
      :target_type => :enemy_targeted,
      :policy => :current_target,
      :delivery => :instant,
      :effects => [
        {:type => :energy_steal, :flat => 30},
        {:type => :energy_lock, :duration => 90}
      ]
    },
    :energy_field => {
      :name => "共鳴充能場",
      :target_type => :self,
      :policy => :current_target,
      :delivery => :instant,
      :effects => [
        {:type => :energy_aura, :flat => 6, :radius => 96.0,
         :duration => 150, :interval => 30, :scope => :allies}
      ]
    },

    # v0.10.2 Shield Trigger Template
    # 尚未正式配置給六隻原型，只先提供通用資料格式。
    :reactive_shell => {
      :name => "反應護盾",
      :target_type => :ally,
      :policy => :protect_ally,
      :delivery => :instant,
      :effects => [
        {:type => :shield, :flat => 100, :duration => 180,
         :trigger => {
           :absorb_cooldown => 30,
           :on_absorb => [
             {:type => :energy_gain, :flat => 5, :target => :self}
           ],
           :on_break => [
             {:type => :energy_gain, :flat => 15, :target => :self}
           ]
         }}
      ]
    },

    # v0.11 Battle Object Skill Templates
    :deploy_decoy => {
      :name => "誘餌投放",
      :target_type => :self,
      :policy => :current_target,
      :delivery => :instant,
      :effects => [
        {:type => :battle_object, :object => :decoy,
         :placement => :self, :offset_x => 34}
      ]
    },
    :lay_trap => {
      :name => "佈設陷阱",
      :target_type => :enemy_targeted,
      :policy => :current_target,
      :delivery => :instant,
      :effects => [
        {:type => :battle_object, :object => :trap,
         :placement => :target}
      ]
    },
    :timed_bomb => {
      :name => "定時爆彈",
      :target_type => :enemy_targeted,
      :policy => :current_target,
      :delivery => :instant,
      :effects => [
        {:type => :battle_object, :object => :bomb,
         :placement => :target}
      ]
    },
    :energy_totem => {
      :name => "充能圖騰",
      :target_type => :self,
      :policy => :current_target,
      :delivery => :instant,
      :effects => [
        {:type => :battle_object, :object => :totem,
         :placement => :self, :offset_y => -34}
      ]
    },
    :delayed_blast => {
      :name => "延遲爆破",
      :target_type => :enemy_targeted,
      :policy => :current_target,
      :delivery => :instant,
      :effects => [
        {:type => :battle_object, :object => :delayed_marker,
         :placement => :target}
      ]
    },

    :substitute_skill => {
      :name => "替身",
      :target_type => :self,
      :policy => :current_target,
      :delivery => :instant,
      :effects => [
        {:type => :battle_object, :object => :substitute,
         :placement => :self,
         :hp_cost_ratio => 0.25,
         :offset_x => 18}
      ]
    },

    :summon_helper => {
      :name => "召喚援手",
      :target_type => :self,
      :policy => :current_target,
      :delivery => :instant,
      :effects => [
        {:type => :summon_unit,
         :unit => :caterpie,
         :placement => :self,
         :offset_x => 34,
         :duration => 150,
         :hp_scale => 0.55,
         :stat_scale => 0.70,
         :allow_skill => false,
         :expire_with_owner => true}
      ]
    }
  }

  def self.skill_data(key)
    return SKILL_DATA[key] || {}
  end

  #--------------------------------------------------------------------------
  # ● v0.10 SE Hook
  #--------------------------------------------------------------------------
  # 支援：
  #   "Skill1"
  #   {:name=>"Skill1", :volume=>80, :pitch=>100}
  #
  # 資料沒填就靜音；故意 rescue，避免測試專案缺音效檔時中止戰鬥。
  def self.play_se(spec)
    return unless SE_ENABLED
    return if spec == nil
    if spec.is_a?(String)
      name = spec
      volume = SE_DEFAULT_VOLUME
      pitch = SE_DEFAULT_PITCH
    else
      name = spec[:name]
      volume = (spec[:volume] || SE_DEFAULT_VOLUME).to_i
      pitch = (spec[:pitch] || SE_DEFAULT_PITCH).to_i
    end
    return if name == nil || name.to_s.empty?
    RPG::SE.new(name.to_s, volume, pitch).play
  rescue
    # SE 是表現層，不應讓缺檔破壞戰鬥核心。
  end

  def self.status_def(key)
    return STATUS_DEFS[key] || {}
  end

  BOARD_LEFT   = GRID_X + 14
  BOARD_RIGHT  = GRID_X + GRID_COLS * CELL_W - 14
  BOARD_TOP    = GRID_Y + 18
  BOARD_BOTTOM = GRID_Y + GRID_ROWS * CELL_H - 10

  # 友方只能在左側三欄進行戰前布陣。
  ALLY_DEPLOY_MIN_X = 0
  ALLY_DEPLOY_MAX_X = 2

  # PMD 多方向 sheet 的列順序：
  # 下、右下、右、右上、上、左上、左、左下。
  DIRECTION_ROWS = {
    2 => 0, 3 => 1, 6 => 2, 9 => 3,
    8 => 4, 7 => 5, 4 => 6, 1 => 7
  }
  DEFAULT_DIRECTION = 2

  ACTION_FALLBACKS = {
    :idle   => [:idle, :walk],
    :walk   => [:walk, :idle],
    :attack => [:attack, :strike, :double, :swing, :idle],
    :strike => [:strike, :attack, :double, :swing, :idle],
    :shoot  => [:shoot, :charge, :attack, :idle],
    :charge => [:charge, :shoot, :shake, :attack, :idle],
    :double => [:double, :strike, :attack, :idle],
    :shock  => [:shock, :charge, :shoot, :attack, :idle],
    :shake  => [:shake, :charge, :idle],
    :swing  => [:swing, :attack, :strike, :idle],
    :hurt   => [:hurt, :idle],
    :faint  => [:faint, :sleep, :hurt, :idle]
  }

  # 六隻原型單位。數值只用來驗證移動與交戰節奏，不是正式平衡。
  # :move_speed       每幀最高移動像素
  # :collision_radius 圓形單位碰撞半徑
  # :melee_reach      近戰中心距離判定
  # :min_range / :preferred_range / :max_range 為遠程保持距離參數
  #--------------------------------------------------------------------------
  # ● v0.11 Battle Object Templates
  #--------------------------------------------------------------------------
  BATTLE_OBJECT_DATA = {
    :decoy => {
      :name => "誘餌",
      :kind => :decoy,
      :style => :decoy,
      :targetable => true,
      :hp => 120,
      :duration => 180,
      :collision_radius => 13.0,
      :target_priority => 10500.0
    },

    :trap => {
      :name => "陷阱",
      :kind => :trap,
      :style => :trap,
      :targetable => false,
      :duration => 180,
      :arm_delay => 12,
      :trigger_radius => 34.0,
      :effect_radius => 52.0,
      :scope => :enemies,
      :effects => [
        {:type => :damage, :flat => 40},
        {:type => :status, :status => :move_slow,
         :value => 0.20, :duration => 75,
         :stack_mode => :replace_stronger}
      ]
    },

    :bomb => {
      :name => "炸彈",
      :kind => :bomb,
      :style => :bomb,
      :targetable => true,
      :hp => 90,
      :duration => 120,
      :trigger_delay => 36,
      :effect_radius => 68.0,
      :scope => :enemies,
      :detonate_on_destroy => true,
      :target_priority => 1400.0,
      :effects => [
        {:type => :damage, :flat => 60}
      ]
    },

    :totem => {
      :name => "圖騰",
      :kind => :totem,
      :style => :totem,
      :targetable => true,
      :hp => 100,
      :duration => 150,
      :tick_interval => 30,
      :effect_radius => 92.0,
      :scope => :allies,
      :target_priority => 2200.0,
      :effects => [
        {:type => :energy_gain, :flat => 6,
         :reason => :battle_object_totem}
      ]
    },

    :substitute => {
      :name => "替身",
      :kind => :substitute,
      :style => :decoy,
      :targetable => true,
      :hp => 100,
      :duration => 240,
      :collision_radius => 13.0,
      :target_priority => 1800.0,
      :intercept_owner => true,
      :intercept_radius => 46.0
    },

    :healing_totem => {
      :name => "治癒圖騰",
      :kind => :totem,
      :style => :totem,
      :targetable => true,
      :hp => 100,
      :duration => 150,
      :tick_interval => 30,
      :effect_radius => 92.0,
      :scope => :allies,
      :target_priority => 2200.0,
      :effects => [
        {:type => :heal, :flat => 18}
      ]
    },

    :delayed_marker => {
      :name => "延遲落點",
      :kind => :delayed,
      :style => :marker,
      :targetable => false,
      :duration => 80,
      :trigger_delay => 36,
      :effect_radius => 56.0,
      :scope => :enemies,
      :effects => [
        {:type => :damage, :flat => 35},
        {:type => :status, :status => :root,
         :value => 0, :duration => 30,
         :stack_mode => :refresh}
      ]
    }
  }

  #--------------------------------------------------------------------------
  # ● v0.11.5 Pokémon Identity Registry
  #--------------------------------------------------------------------------
  # evolution_line_key 是跨進化不變的家族身份。
  # species_key 是目前實際物種，進化後會改。
  # form_key 不放在這裡，屬於每個 Instance 的當前形態。
  EVOLUTION_LINE_DATA = {
    :bulbasaur_line => {
      :members => [:bulbasaur, :ivysaur, :venusaur],
      :synergy_tags => [:kanto_starter, :starter]
    },
    :charmander_line => {
      :members => [:charmander, :charmeleon, :charizard],
      :synergy_tags => [:kanto_starter, :starter]
    },
    :squirtle_line => {
      :members => [:squirtle, :wartortle, :blastoise],
      :synergy_tags => [:kanto_starter, :starter]
    },
    :caterpie_line => {
      :members => [:caterpie, :metapod, :butterfree],
      :synergy_tags => [:early_bug]
    },
    :rattata_line => {
      :members => [:rattata, :raticate],
      :synergy_tags => [:route_rodent]
    },
    :pikachu_line => {
      :members => [:pikachu, :raichu],
      :synergy_tags => [:electric_mascot]
    }
  }

  POKEMON_SPECIES_DATA = {
    :bulbasaur => {
      :name => "妙蛙種子", :pmd_species => "0001",
      :line => :bulbasaur_line, :stage => 1,
      :synergy_tags => [:grass, :poison],
      :role_tags => [:frontline, :sustain, :drain]
    },
    :ivysaur => {
      :name => "妙蛙草", :pmd_species => "0002",
      :line => :bulbasaur_line, :stage => 2,
      :synergy_tags => [:grass, :poison],
      :role_tags => [:frontline, :sustain]
    },
    :venusaur => {
      :name => "妙蛙花", :pmd_species => "0003",
      :line => :bulbasaur_line, :stage => 3,
      :synergy_tags => [:grass, :poison],
      :role_tags => [:frontline, :sustain, :controller]
    },

    :charmander => {
      :name => "小火龍", :pmd_species => "0004",
      :line => :charmander_line, :stage => 1,
      :synergy_tags => [:fire],
      :role_tags => [:bruiser, :melee, :area_damage]
    },
    :charmeleon => {
      :name => "火恐龍", :pmd_species => "0005",
      :line => :charmander_line, :stage => 2,
      :synergy_tags => [:fire],
      :role_tags => [:bruiser, :melee]
    },
    :charizard => {
      :name => "噴火龍", :pmd_species => "0006",
      :line => :charmander_line, :stage => 3,
      :synergy_tags => [:fire, :flying],
      :role_tags => [:bruiser, :area_damage]
    },

    :squirtle => {
      :name => "傑尼龜", :pmd_species => "0007",
      :line => :squirtle_line, :stage => 1,
      :synergy_tags => [:water],
      :role_tags => [:bodyguard, :support, :controller, :ranged]
    },
    :wartortle => {
      :name => "卡咪龜", :pmd_species => "0008",
      :line => :squirtle_line, :stage => 2,
      :synergy_tags => [:water],
      :role_tags => [:bodyguard, :support]
    },
    :blastoise => {
      :name => "水箭龜", :pmd_species => "0009",
      :line => :squirtle_line, :stage => 3,
      :synergy_tags => [:water],
      :role_tags => [:bodyguard, :artillery, :support]
    },

    :caterpie => {
      :name => "綠毛蟲", :pmd_species => "0010",
      :line => :caterpie_line, :stage => 1,
      :synergy_tags => [:bug],
      :role_tags => [:controller, :ranged, :pierce]
    },
    :metapod => {
      :name => "鐵甲蛹", :pmd_species => "0011",
      :line => :caterpie_line, :stage => 2,
      :synergy_tags => [:bug],
      :role_tags => [:tank]
    },
    :butterfree => {
      :name => "巴大蝶", :pmd_species => "0012",
      :line => :caterpie_line, :stage => 3,
      :synergy_tags => [:bug, :flying],
      :role_tags => [:controller, :ranged]
    },

    :rattata => {
      :name => "小拉達", :pmd_species => "0019",
      :line => :rattata_line, :stage => 1,
      :synergy_tags => [:normal],
      :role_tags => [:assassin, :melee, :execute]
    },
    :raticate => {
      :name => "拉達", :pmd_species => "0020",
      :line => :rattata_line, :stage => 2,
      :synergy_tags => [:normal],
      :role_tags => [:assassin, :melee]
    },

    :pikachu => {
      :name => "皮卡丘", :pmd_species => "0025",
      :line => :pikachu_line, :stage => 1,
      :synergy_tags => [:electric],
      :role_tags => [:artillery, :caster, :ranged, :chain]
    },
    :raichu => {
      :name => "雷丘", :pmd_species => "0026",
      :line => :pikachu_line, :stage => 2,
      :synergy_tags => [:electric],
      :role_tags => [:artillery, :caster, :ranged]
    }
  }

  UNIT_DATA = {
    :bulbasaur => {
      :name => "妙蛙種子", :mark => "B", :species => "0001",
      :maxhp => 520, :atk => 58, :def => 48,
      :range => 1, :attack_wait => 54,
      :move_speed => 1.85, :collision_radius => 15.0,
      :melee_reach => 43.0,
      :role => :frontline, :target_rule => :nearest,
      :target_policy => :nearest, :movement_policy => :frontline,
      :threat_policy => :hold_ground, :skill_policy => :current_target,
      :target_commitment => 72,
      :slow_resist => 0.10, :cc_resist => 0.10,
      :crit_rate => 0.05, :crit_multiplier => 1.50,
      :projectile_tracking => :weak,
      :projectile_style => :seed,
      :basic_action => :attack, :skill_action => :shoot,
      :skill_name => "寄生吸取", :skill => :vine_drain, :skill_power => 135
    },
    :charmander => {
      :name => "小火龍", :mark => "C", :species => "0004",
      :maxhp => 430, :atk => 72, :def => 34,
      :range => 1, :attack_wait => 46,
      :move_speed => 2.15, :collision_radius => 13.0,
      :melee_reach => 39.0,
      :role => :bruiser, :target_rule => :cluster,
      :target_policy => :execute, :movement_policy => :bruiser,
      :threat_policy => :normal, :skill_policy => :current_target,
      :target_commitment => 62,
      :slow_resist => 0.05, :cc_resist => 0.05,
      :crit_rate => 0.05, :crit_multiplier => 1.50,
      :projectile_style => :fire,
      :basic_action => :attack, :skill_action => :charge,
      :skill_name => "火焰擴散", :skill => :flame_burst, :skill_power => 118
    },
    :squirtle => {
      :name => "傑尼龜", :mark => "S", :species => "0007",
      :maxhp => 560, :atk => 52, :def => 55,
      :range => 3, :attack_wait => 62,
      :move_speed => 1.80, :collision_radius => 14.0,
      :min_range => 86.0, :preferred_range => 142.0, :max_range => 184.0,
      :role => :controller, :target_rule => :nearest,
      :target_policy => :protect_ally, :movement_policy => :bodyguard,
      :threat_policy => :protective, :skill_policy => :current_target,
      :target_commitment => 58,
      :slow_resist => 0.15, :cc_resist => 0.15,
      :crit_rate => 0.05, :crit_multiplier => 1.50,
      :projectile_tracking => :weak,
      :projectile_intercept => true,
      :projectile_intercept_radius => 58.0,
      :aura => {
        :target => :allies, :radius => 86.0,
        :status => :def_aura, :value => 0.08
      },
      :projectile_style => :water,
      :basic_action => :attack, :skill_action => :shoot,
      :skill_name => "守護水幕", :skill => :guardian_tide, :skill_power => 0
    },
    :caterpie => {
      :name => "綠毛蟲", :mark => "G", :species => "0010",
      :maxhp => 460, :atk => 49, :def => 42,
      :range => 3, :attack_wait => 58,
      :move_speed => 1.65, :collision_radius => 12.0,
      :min_range => 82.0, :preferred_range => 138.0, :max_range => 178.0,
      :role => :controller, :target_rule => :cluster,
      :target_policy => :cluster, :movement_policy => :controller,
      :threat_policy => :responsive, :skill_policy => :best_cluster,
      :target_commitment => 52,
      :slow_resist => 0.00, :cc_resist => 0.00,
      :crit_rate => 0.05, :crit_multiplier => 1.50,
      :projectile_tracking => :none,
      :projectile_style => :web,
      :basic_action => :attack, :skill_action => :shoot,
      :skill_name => "貫穿蟲絲", :skill => :web_pierce, :skill_power => 108
    },
    :rattata => {
      :name => "小拉達", :mark => "R", :species => "0019",
      :maxhp => 390, :atk => 79, :def => 29,
      :range => 1, :attack_wait => 39,
      :move_speed => 2.75, :collision_radius => 11.0,
      :melee_reach => 36.0,
      :role => :assassin, :target_rule => :fragile,
      :target_policy => :backline_low_def, :movement_policy => :assassin,
      :threat_policy => :ignore_minor, :skill_policy => :execute,
      :target_commitment => 86,
      :slow_resist => 0.00, :cc_resist => 0.00,
      :crit_rate => 0.08, :crit_multiplier => 1.50,
      :active_evade => true,
      :evade_cooldown => 210,
      :evade_distance => 48.0,
      :projectile_style => :slash,
      :basic_action => :attack, :skill_action => :double,
      :skill_name => "裂傷突襲", :skill => :rending_assault, :skill_power => 215
    },
    :pikachu => {
      :name => "皮卡丘", :mark => "P", :species => "0025",
      :maxhp => 410, :atk => 69, :def => 31,
      :range => 3, :attack_wait => 44,
      :move_speed => 2.35, :collision_radius => 12.0,
      :min_range => 92.0, :preferred_range => 150.0, :max_range => 192.0,
      :role => :caster, :target_rule => :cluster,
      :target_policy => :cluster, :movement_policy => :artillery,
      :threat_policy => :responsive, :skill_policy => :best_cluster,
      :target_commitment => 48,
      :slow_resist => 0.05, :cc_resist => 0.08,
      :crit_rate => 0.06, :crit_multiplier => 1.50,
      :projectile_tracking => :strong,
      :boss => true,
      :projectile_style => :electric,
      :basic_action => :attack, :skill_action => :shock,
      :skill_name => "連鎖電擊", :skill => :chain_lightning, :skill_power => 145
    }
  }

  ALLY_SETUP = [
    [:bulbasaur, 0, 2],
    [:charmander, 1, 1],
    [:squirtle,  0, 3]
  ]

  ENEMY_SETUP = [
    [:rattata,  5, 2],
    [:caterpie, 4, 1],
    [:pikachu,  5, 3]
  ]

  ATTACK_SLOT_VECTORS = [
    [ 1.000,  0.000],
    [ 0.707,  0.707],
    [ 0.000,  1.000],
    [-0.707,  0.707],
    [-1.000,  0.000],
    [-0.707, -0.707],
    [ 0.000, -1.000],
    [ 0.707, -0.707]
  ]

  def self.action_database
    return PMD_AUTOCHESS_DATA if defined?(PMD_AUTOCHESS_DATA)
    return {}
  end

  def self.action_data(species, requested_action)
    species_data = action_database[species]
    return nil if species_data == nil
    fallbacks = ACTION_FALLBACKS[requested_action]
    fallbacks = [requested_action] if fallbacks == nil
    for key in fallbacks
      data = species_data[key]
      return data if data != nil
    end
    return nil
  end

  def self.action_timing(species, requested_action, default_total, default_hit)
    data = action_data(species, requested_action)
    return [default_total, default_hit] if data == nil
    durations = data[:durations]
    return [default_total, default_hit] if durations == nil || durations.empty?
    total = 0
    for value in durations
      total += [value.to_i, 1].max
    end
    total = clamp(total, 12, 72)
    hit_index = data[:hit_frame]
    if hit_index == nil
      hit_countdown = total * 45 / 100
    else
      index = clamp(hit_index.to_i, 0, durations.size - 1)
      elapsed = 0
      for i in 0..index
        elapsed += [durations[i].to_i, 1].max
      end
      hit_countdown = total - elapsed
    end
    hit_countdown = clamp(hit_countdown, 1, total - 1)
    return [total, hit_countdown]
  end

  # 使用角度區間，而不是只看 dx/dy 正負，讓 Pixel Movement 的方向較自然。
  def self.direction_from_delta(dx, dy, fallback = DEFAULT_DIRECTION)
    return fallback if dx.abs < 0.001 && dy.abs < 0.001
    degree = Math.atan2(dy, dx) * 180.0 / Math::PI
    degree += 360.0 if degree < 0.0
    sector = ((degree + 22.5) / 45.0).floor % 8
    directions = [6, 3, 2, 1, 4, 7, 8, 9]
    return directions[sector]
  end

  def self.direction_row(data, direction)
    rows = data == nil ? 1 : data[:rows].to_i
    return 0 if rows <= 1
    if rows >= 8
      row = DIRECTION_ROWS[direction]
      row = DIRECTION_ROWS[DEFAULT_DIRECTION] if row == nil
      return clamp(row, 0, rows - 1)
    end
    cardinal = {
      2 => 0, 1 => 0, 3 => 0,
      6 => 1, 9 => 1,
      8 => 2, 7 => 2,
      4 => 3
    }
    return clamp(cardinal[direction] || 0, 0, rows - 1)
  end

  def self.bitmap_exists?(folder, filename)
    path = folder + filename + ".png"
    return FileTest.exist?(path)
  rescue
    return false
  end

  def self.cell_pixel_x(cell_x)
    return GRID_X + cell_x * CELL_W + CELL_W / 2
  end

  def self.cell_pixel_y(cell_y)
    return GRID_Y + cell_y * CELL_H + CELL_H - 6
  end

  def self.pixel_to_cell_x(pixel_x)
    value = ((pixel_x - GRID_X) / CELL_W.to_f).floor
    return clamp(value, 0, GRID_COLS - 1)
  end

  def self.pixel_to_cell_y(pixel_y)
    value = ((pixel_y - GRID_Y) / CELL_H.to_f).floor
    return clamp(value, 0, GRID_ROWS - 1)
  end

  def self.clamp(value, min_value, max_value)
    return min_value if value < min_value
    return max_value if value > max_value
    return value
  end

  def self.distance(x1, y1, x2, y2)
    dx = x2 - x1
    dy = y2 - y1
    return Math.sqrt(dx * dx + dy * dy)
  end

  #--------------------------------------------------------------------------
  # ● v0.11.5 Identity Helpers
  #--------------------------------------------------------------------------
  @temporary_instance_uid = TEMP_INSTANCE_UID_START

  def self.allocate_temporary_instance_uid
    @temporary_instance_uid = TEMP_INSTANCE_UID_START if
      @temporary_instance_uid == nil
    @temporary_instance_uid += 1
    return @temporary_instance_uid
  end

  def self.species_identity_data(species_key)
    return POKEMON_SPECIES_DATA[species_key]
  end

  def self.evolution_line_data(line_key)
    return EVOLUTION_LINE_DATA[line_key]
  end

  def self.identity_synergy_tags(species_key)
    species = species_identity_data(species_key)
    return [] if species == nil
    result = []
    line = evolution_line_data(species[:line])
    if line != nil && line[:synergy_tags] != nil
      result.concat(line[:synergy_tags])
    end
    result.concat(species[:synergy_tags] || [])
    return result.uniq
  end

  def self.identity_role_tags(species_key)
    species = species_identity_data(species_key)
    return [] if species == nil
    return (species[:role_tags] || []).dup
  end

  def self.validate_identity_registry
    errors = []

    for line_key in EVOLUTION_LINE_DATA.keys
      line = EVOLUTION_LINE_DATA[line_key]
      members = line[:members] || []
      if members.empty?
        errors.push("line_empty:" + line_key.to_s)
      end
      for species_key in members
        species = POKEMON_SPECIES_DATA[species_key]
        if species == nil
          errors.push("missing_species:" + species_key.to_s)
        elsif species[:line] != line_key
          errors.push("line_mismatch:" + species_key.to_s)
        end
      end
    end

    for unit_key in UNIT_DATA.keys
      data = UNIT_DATA[unit_key]
      species = POKEMON_SPECIES_DATA[unit_key]
      if species == nil
        errors.push("unit_identity_missing:" + unit_key.to_s)
        next
      end
      if data[:species].to_s != species[:pmd_species].to_s
        errors.push("pmd_mismatch:" + unit_key.to_s)
      end
    end

    return errors
  end
end


#==============================================================================
# ■ PMD_PokemonIdentity
#------------------------------------------------------------------------------
#  身份資料本身不處理戰鬥數值、Level 或 Evolution Transaction。
#  v0.12 PokémonInstance 將持有此資料，Battle Unit 只引用／鏡射它。
#==============================================================================
class PMD_PokemonIdentity
  attr_reader :instance_uid
  attr_reader :runtime_actor_id
  attr_reader :template_actor_id
  attr_reader :evolution_line_key
  attr_reader :species_key
  attr_reader :form_key
  attr_reader :evolution_stage
  attr_reader :synergy_tags
  attr_reader :role_tags
  attr_reader :pmd_species_id

  def initialize(species_key, options = nil)
    options = {} if options == nil
    data = PMD_AC.species_identity_data(species_key)
    raise "Unknown Pokemon identity: " + species_key.to_s if data == nil

    @instance_uid = options[:instance_uid] ||
                    PMD_AC.allocate_temporary_instance_uid
    @runtime_actor_id = options[:runtime_actor_id]
    @template_actor_id = options[:template_actor_id]
    @species_key = species_key
    @evolution_line_key = data[:line]
    @evolution_stage = data[:stage].to_i
    @form_key = options[:form_key] || :normal
    @pmd_species_id = data[:pmd_species].to_s

    @synergy_tags = PMD_AC.identity_synergy_tags(species_key)
    if options[:synergy_tags] != nil
      @synergy_tags.concat(options[:synergy_tags])
    end
    @synergy_tags = @synergy_tags.uniq

    @role_tags = PMD_AC.identity_role_tags(species_key)
    if options[:role_tags] != nil
      @role_tags.concat(options[:role_tags])
    end
    @role_tags = @role_tags.uniq
  end

  def bind_actor_ids(runtime_actor_id, template_actor_id = nil)
    @runtime_actor_id = runtime_actor_id
    @template_actor_id = template_actor_id
    return self
  end

  def set_form_key(form_key)
    @form_key = form_key || :normal
    return self
  end

  def species?(key)
    return @species_key == key
  end

  def evolution_line?(key)
    return @evolution_line_key == key
  end

  def synergy_tag?(tag)
    return @synergy_tags.include?(tag)
  end

  def role_tag?(tag)
    return @role_tags.include?(tag)
  end

  def same_species?(other)
    return false if other == nil
    return @species_key == other.species_key
  end

  def same_evolution_line?(other)
    return false if other == nil
    return @evolution_line_key == other.evolution_line_key
  end

  def clone_identity(options = nil)
    options = {} if options == nil
    clone = PMD_PokemonIdentity.new(
      @species_key,
      {
        :instance_uid => options.has_key?(:instance_uid) ?
                         options[:instance_uid] : @instance_uid,
        :runtime_actor_id => options.has_key?(:runtime_actor_id) ?
                             options[:runtime_actor_id] : @runtime_actor_id,
        :template_actor_id => options.has_key?(:template_actor_id) ?
                              options[:template_actor_id] : @template_actor_id,
        :form_key => options.has_key?(:form_key) ?
                     options[:form_key] : @form_key,
        :synergy_tags => @synergy_tags,
        :role_tags => @role_tags
      })
    return clone
  end

  def log_signature
    runtime = @runtime_actor_id == nil ? "nil" : @runtime_actor_id.to_s
    template = @template_actor_id == nil ? "nil" : @template_actor_id.to_s
    return "uid=" + @instance_uid.to_s +
           " species=" + @species_key.to_s +
           " line=" + @evolution_line_key.to_s +
           " stage=" + @evolution_stage.to_s +
           " form=" + @form_key.to_s +
           " runtime_actor=" + runtime +
           " template_actor=" + template
  end
end


#==============================================================================
# ■ Game_PMDChessUnit
#==============================================================================
class Game_PMDChessUnit
  attr_reader   :id
  attr_reader   :key
  attr_reader   :name
  attr_reader   :species
  attr_reader   :identity
  attr_reader   :team
  attr_reader   :cell_x
  attr_reader   :cell_y
  attr_reader   :pixel_x
  attr_reader   :pixel_y
  attr_reader   :velocity_x
  attr_reader   :velocity_y
  attr_reader   :maxhp
  attr_reader   :hp
  attr_reader   :energy
  attr_reader   :action
  attr_reader   :visual_action
  attr_reader   :facing_dir
  attr_reader   :skill_name
  attr_reader   :skill_popup_frames
  attr_reader   :target
  attr_reader   :stun_frames
  attr_reader   :last_damage
  attr_reader   :damage_popup_frames
  attr_reader   :collision_radius
  attr_reader   :move_goal_x
  attr_reader   :move_goal_y
  attr_reader   :visual_offset_x
  attr_reader   :visual_offset_y
  attr_reader   :role
  attr_reader   :target_rule
  attr_reader   :projectile_style
  attr_reader   :miss_count
  attr_reader   :threat_source
  attr_reader   :threat_level
  attr_reader   :last_attacker
  attr_reader   :target_policy
  attr_reader   :movement_policy
  attr_reader   :slow_resist
  attr_reader   :threat_policy
  attr_reader   :skill_policy
  attr_reader   :target_commitment
  attr_reader   :skill_target
  attr_reader   :shield
  attr_reader   :forced_target
  attr_reader   :forced_target_frames
  attr_reader   :cc_resist
  attr_reader   :boss
  attr_reader   :projectile_intercept_radius
  attr_reader   :damage_link_source
  attr_reader   :damage_link_frames
  attr_reader   :victory_celebrating
  attr_reader   :last_damage_critical
  attr_reader   :projectile_tracking
  attr_reader   :summon_owner
  attr_reader   :summon_remaining
  attr_accessor :scene

  def initialize(id, key, team, cell_x, cell_y)
    data = PMD_AC::UNIT_DATA[key]
    @id = id
    @key = key
    @name = data[:name]
    @species = data[:species]
    @mark = data[:mark]
    @team = team
    @cell_x = cell_x
    @cell_y = cell_y
    @pixel_x = PMD_AC.cell_pixel_x(cell_x).to_f
    @pixel_y = PMD_AC.cell_pixel_y(cell_y).to_f
    @velocity_x = 0.0
    @velocity_y = 0.0
    @move_goal_x = nil
    @move_goal_y = nil
    @move_speed = (data[:move_speed] || 2.0).to_f
    @collision_radius = (data[:collision_radius] || 13.0).to_f
    @melee_reach = (data[:melee_reach] || 40.0).to_f
    @min_range = (data[:min_range] || 0.0).to_f
    @preferred_range = (data[:preferred_range] || 0.0).to_f
    @max_range = (data[:max_range] || @melee_reach).to_f
    @maxhp = data[:maxhp]
    @hp = @maxhp
    @atk = data[:atk]
    @def = data[:def]

    # v0.10.2 Directional Defense / Back Attack
    @front_damage_multiplier =
      (data[:front_damage_multiplier] ||
       PMD_AC::DIRECTION_FRONT_MULTIPLIER).to_f
    @side_damage_multiplier =
      (data[:side_damage_multiplier] ||
       PMD_AC::DIRECTION_SIDE_MULTIPLIER).to_f
    @back_damage_multiplier =
      (data[:back_damage_multiplier] ||
       PMD_AC::DIRECTION_BACK_MULTIPLIER).to_f
    @range = data[:range]
    @attack_wait_max = data[:attack_wait]
    @skill_type = data[:skill]
    @skill_power = data[:skill_power]
    @basic_action = data[:basic_action] || :attack
    @skill_action = data[:skill_action] || :shoot
    skill_def = PMD_AC.skill_data(@skill_type)
    @skill_name = skill_def[:name] || data[:skill_name] || "技能"
    @role = data[:role] || :fighter

    # v0.11.5：Unit Key 目前等同 species_key，但兩者概念正式分離。
    # 未來 Clone Actor / PokémonInstance 可以傳不同 Actor ID，
    # species identity 仍由 PMD_PokemonIdentity 管理。
    @identity = PMD_PokemonIdentity.new(
      key,
      {:role_tags => [@role]})

    @target_rule = data[:target_rule] || :nearest
    @target_policy = data[:target_policy] || @target_rule || :nearest
    @movement_policy = data[:movement_policy] ||
                       (data[:range].to_i > 1 ? :kiter : :frontline)
    @threat_policy = data[:threat_policy] ||
                     (data[:range].to_i > 1 ? :responsive : :normal)
    @skill_policy = data[:skill_policy] || :current_target
    @target_commitment = PMD_AC.clamp((data[:target_commitment] || 60).to_i,
                                      0, 100)
    @slow_resist = PMD_AC.clamp((data[:slow_resist] || 0.0).to_f,
                                0.0, PMD_AC::SLOW_RESIST_MAX)
    @cc_resist = PMD_AC.clamp((data[:cc_resist] || 0.0).to_f,
                              0.0, PMD_AC::CC_RESIST_MAX)
    @boss = data[:boss] ? true : false
    @cc_dr_counts = {}
    @cc_dr_timers = {}
    @fear_source = nil
    @projectile_intercept = data[:projectile_intercept] ? true : false
    @projectile_intercept_radius =
      (data[:projectile_intercept_radius] ||
       PMD_AC::PROJECTILE_INTERCEPT_RADIUS).to_f
    @aura_data = data[:aura]
    @damage_link_source = nil
    @damage_link_ratio = 0.0
    @damage_link_frames = 0
    @channeling = false
    @verification_no_auto_skill = false
    @verification_combat_sandbox = false
    @verification_original_skill_type = nil
    @verification_original_skill_name = nil
    @last_escape_fail_log_frame = -9999
    @victory_celebrating = false
    @victory_started_frame = 0
    @target_recheck_frames = 0
    @protected_ally = nil
    @projectile_style = data[:projectile_style] || :neutral

    # v0.10 Hit System
    @crit_rate = PMD_AC.clamp((data[:crit_rate] || PMD_AC::BASE_CRIT_RATE).to_f,
                              0.0, 1.0)
    @crit_multiplier = [(data[:crit_multiplier] ||
                         PMD_AC::BASE_CRIT_MULTIPLIER).to_f, 1.0].max
    @projectile_tracking = data[:projectile_tracking] || :perfect
    @active_evade_enabled = data[:active_evade] ? true : false
    @evade_cooldown_max = (data[:evade_cooldown] ||
                           PMD_AC::ACTIVE_EVADE_COOLDOWN).to_i
    @evade_distance = (data[:evade_distance] ||
                       PMD_AC::ACTIVE_EVADE_DISTANCE).to_f
    @evade_cooldown = 0
    @evade_visual_frames = 0
    @verification_force_evade = false
    @next_attack_modifier = nil
    @last_damage_critical = false

    @energy = 0
    @skill_target = nil
    @skill_recheck_frames = 0
    @skill_hold_frames = 0
    @shield = 0
    @shield_frames = 0
    @shield_trigger = nil
    @shield_trigger_source = nil
    @shield_trigger_absorb_cooldown = 0
    @statuses = {}
    @forced_target = nil
    @forced_target_frames = 0
    @action = :idle
    @visual_action = :idle
    @facing_dir = team == :ally ? 6 : 4
    @pending_dir = @facing_dir
    @pending_dir_frames = 0
    @skill_popup_frames = 0
    @target = nil
    @attack_wait = rand(18)
    @action_timer = 0
    @action_total_frames = 0
    @action_hit_frame = 0
    @action_hit_done = false
    @action_dir_x = 0.0
    @action_dir_y = 0.0
    @action_lunge = 0.0
    @visual_offset_x = 0.0
    @visual_offset_y = 0.0
    @recoil_x = 0.0
    @recoil_y = 0.0
    @knockback_x = 0.0
    @knockback_y = 0.0
    @knockback_frames = 0
    @miss_count = 0
    @threat_source = nil
    @threat_level = :safe
    @last_attacker = nil
    @last_attacker_memory = 0
    @retarget_cooldown = 0
    @emergency_target = nil
    @threat_release_frames = 0
    @stun_frames = 0
    @hurt_frames = 0
    @dead_started = false
    @last_damage = 0
    @damage_popup_frames = 0
    @battle_active = false

    # v0.11.1 Summoned Unit
    @summoned = false
    @summon_owner = nil
    @summon_remaining = 0
    @summon_allow_skill = false
    @summon_expire_with_owner = true
    @summon_expiring = false
    @summon_remove_scheduled = false
  end

  def mark
    return @mark
  end

  def atk
    value = @atk.to_f
    value *= status_stat_multiplier(:atk)
    return [value.round, 1].max
  end

  def defense
    value = @def.to_f
    value *= status_stat_multiplier(:def)
    return [value.round, 0].max
  end

  def attack_range
    return @range
  end

  def range_label
    return ranged? ? "遠程" : "近戰"
  end

  def skill_type
    return @skill_type
  end

  def skill_power
    return @skill_power
  end


  def skill_data
    return PMD_AC.skill_data(@skill_type)
  end

  #--------------------------------------------------------------------------
  # ● v0.10 Hit System
  #--------------------------------------------------------------------------
  def crit_rate
    return @crit_rate
  end

  def crit_multiplier
    return @crit_multiplier
  end

  def queue_next_attack_modifier(data)
    return if data == nil
    @next_attack_modifier = data.dup
    name = @next_attack_modifier[:name] || "modifier"
    log_event(:next_attack,
              log_name + " QUEUE " + name.to_s +
              " force_crit=" + (@next_attack_modifier[:force_crit] ? "1" : "0") +
              " power_mul=" +
              sprintf("%.2f", (@next_attack_modifier[:power_multiplier] || 1.0).to_f) +
              " tracking=" +
              (@next_attack_modifier[:projectile_tracking] || :default).to_s)
  end

  def consume_next_attack_modifier
    data = @next_attack_modifier
    @next_attack_modifier = nil
    if data != nil
      log_event(:next_attack,
                log_name + " CONSUME " +
                (data[:name] || "modifier").to_s)
    end
    return data
  end

  def verification_force_evade_ready
    @verification_force_evade = true
    @evade_cooldown = 0

    # 驗證模式需要「一定有資格嘗試 Evade」。
    # 正常戰鬥規則仍然禁止 acting? 時 Evade，只有這個 verification helper 清 Action。
    if acting?
      @action = :idle
      @visual_action = :idle
      @action_timer = 0
      @action_total_frames = 0
      @action_hit_done = false
      @action_lunge = 0.0
      @channeling = false
      @skill_target = nil
    end
  end

  def active_evade_available?
    return false if dead?
    return false unless @active_evade_enabled || @verification_force_evade
    return false if @evade_cooldown > 0
    return false if @stun_frames > 0 || rooted? || feared?
    return false if acting?
    return true
  end

  def try_active_evade(source, attack_kind = :direct)
    return false if source == nil
    return false unless active_evade_available?

    dx = @pixel_x - source.pixel_x
    dy = @pixel_y - source.pixel_y
    len = Math.sqrt(dx * dx + dy * dy)
    if len <= 0.001
      dx = @team == :ally ? -1.0 : 1.0
      dy = 0.0
      len = 1.0
    end

    # 只做可觀察的實際側閃，不骰「閃避率」。
    sx = -dy / len
    sy = dx / len
    candidates = [[sx, sy], [-sx, -sy]]
    best = nil
    best_score = nil

    for vec in candidates
      nx = PMD_AC.clamp(@pixel_x + vec[0] * @evade_distance,
                        PMD_AC::BOARD_LEFT.to_f, PMD_AC::BOARD_RIGHT.to_f)
      ny = PMD_AC.clamp(@pixel_y + vec[1] * @evade_distance,
                        PMD_AC::BOARD_TOP.to_f, PMD_AC::BOARD_BOTTOM.to_f)
      moved = PMD_AC.distance(@pixel_x, @pixel_y, nx, ny)
      away = PMD_AC.distance(source.pixel_x, source.pixel_y, nx, ny)
      edge = [nx - PMD_AC::BOARD_LEFT.to_f,
              PMD_AC::BOARD_RIGHT.to_f - nx,
              ny - PMD_AC::BOARD_TOP.to_f,
              PMD_AC::BOARD_BOTTOM.to_f - ny].min
      score = moved * 1.5 + away * 0.25 + [edge, 28.0].min * 0.30
      if best_score == nil || score > best_score
        best_score = score
        best = [nx, ny]
      end
    end

    return false if best == nil
    ox = @pixel_x
    oy = @pixel_y
    @pixel_x = best[0]
    @pixel_y = best[1]
    sync_cell_from_pixel
    @velocity_x = 0.0
    @velocity_y = 0.0
    clear_move_goal
    @scene.release_attack_slot(self) if @scene != nil
    face_delta(@pixel_x - ox, @pixel_y - oy, true)
    @evade_cooldown = @evade_cooldown_max
    @evade_visual_frames = PMD_AC::ACTIVE_EVADE_VISUAL_FRAMES
    @verification_force_evade = false

    log_event(:evade_start,
              log_name + " kind=" + attack_kind.to_s +
              " from=" + source.log_name +
              " move=" + PMD_AC.distance(ox, oy, @pixel_x, @pixel_y).round.to_s)
    @scene.play_evade_se(self) if @scene != nil
    return true
  end

  def update_hit_system
    @evade_cooldown -= 1 if @evade_cooldown > 0
    @evade_visual_frames -= 1 if @evade_visual_frames > 0
  end

  def verification_prepare(active, hp_multiplier = 1.0)
    @verification_no_auto_skill = active ? true : false
    @verification_combat_sandbox = false
    @verification_original_skill_type = @skill_type
    @verification_original_skill_name = @skill_name
    return unless active
    mult = hp_multiplier.to_f
    mult = 1.0 if mult < 1.0
    @maxhp = (@maxhp.to_f * mult).round
    @hp = @maxhp
    @energy = 0
    @verification_energy_sandbox = false
    @attack_wait = 0
  end

  def verification_finish
    return unless @verification_no_auto_skill
    @verification_no_auto_skill = false
    @verification_energy_sandbox = false
    @verification_combat_sandbox = false
    if @verification_original_skill_type != nil
      @skill_type = @verification_original_skill_type
      @skill_name = @verification_original_skill_name
    end
    # 強制驗證技能不應讓正常 AI 免費接一發滿能技能。
    @energy = 0
    @skill_target = nil
    @skill_hold_frames = 0
    @skill_recheck_frames = 0
  end

  def verification_set_skill(skill_type)
    data = PMD_AC.skill_data(skill_type)
    return false if data == nil || data.empty?
    @skill_type = skill_type
    @skill_name = data[:name] || skill_type.to_s
    return true
  end

  def verification_force_skill(skill_type, target)
    return false if dead? || target == nil || target.dead?
    return false unless verification_set_skill(skill_type)
    if acting?
      @action = :idle
      @visual_action = :idle
      @action_timer = 0
      @action_total_frames = 0
      @action_hit_done = false
      @action_lunge = 0.0
      @channeling = false
    end
    @energy = PMD_AC::MAX_ENERGY
    begin_skill(target)
    return true
  end

  def verification_force_basic_attack(target, modifier = nil)
    return false if dead? || target == nil || target.dead?
    if acting?
      @action = :idle
      @visual_action = :idle
      @action_timer = 0
      @action_total_frames = 0
      @action_hit_done = false
      @action_lunge = 0.0
      @channeling = false
    end
    @target = target
    @attack_wait = 0
    queue_next_attack_modifier(modifier) if modifier != nil
    begin_attack
    return true
  end

  def verification_damage(amount, source = nil)
    return if dead?
    receive_damage(amount.to_i, source, false)
  end

  def log_event(category, message)
    return if @scene == nil
    @scene.log_event(category, message)
  end

  def log_name
    side = @team == :ally ? "ALLY" : "ENEMY"
    if summoned?
      return "SUMMON:" + side + ":" + @name.to_s + "#" + @id.to_s
    end
    return side + ":" + @name.to_s
  end

  #--------------------------------------------------------------------------
  # ● v0.11.5 Pokémon Identity Delegates
  #--------------------------------------------------------------------------
  def instance_uid
    return @identity.instance_uid
  end

  def species_key
    return @identity.species_key
  end

  def evolution_line_key
    return @identity.evolution_line_key
  end

  def form_key
    return @identity.form_key
  end

  def evolution_stage
    return @identity.evolution_stage
  end

  def synergy_tags
    return @identity.synergy_tags
  end

  def role_tags
    return @identity.role_tags
  end

  def runtime_actor_id
    return @identity.runtime_actor_id
  end

  def template_actor_id
    return @identity.template_actor_id
  end

  def bind_actor_identity(runtime_actor_id, template_actor_id = nil)
    @identity.bind_actor_ids(runtime_actor_id, template_actor_id)
  end

  def identity_species?(key)
    return @identity.species?(key)
  end

  def identity_line?(key)
    return @identity.evolution_line?(key)
  end

  def identity_synergy_tag?(tag)
    return @identity.synergy_tag?(tag)
  end

  def identity_role_tag?(tag)
    return @identity.role_tag?(tag)
  end

  #--------------------------------------------------------------------------
  # ● v0.11.1 Summoned Unit
  #--------------------------------------------------------------------------
  def summoned?
    return @summoned ? true : false
  end

  def counts_for_victory?
    return !summoned?
  end

  def summon_allow_skill?
    return @summon_allow_skill ? true : false
  end

  def configure_as_summon(owner, options = nil)
    options = {} if options == nil
    @summoned = true
    @summon_owner = owner
    @summon_remaining =
      (options[:duration] || PMD_AC::SUMMON_DEFAULT_DURATION).to_i
    @summon_allow_skill = options[:allow_skill] ? true : false
    @summon_expire_with_owner =
      options.has_key?(:expire_with_owner) ?
      (options[:expire_with_owner] ? true : false) : true
    @summon_expiring = false
    @summon_remove_scheduled = false

    hp_scale = (options[:hp_scale] || 1.0).to_f
    stat_scale = (options[:stat_scale] || 1.0).to_f
    @maxhp = [(@maxhp * hp_scale).round, 1].max
    @hp = @maxhp
    @atk = [(@atk * stat_scale).round, 1].max
    @def = [(@def * stat_scale).round, 0].max

    if options[:move_speed_scale] != nil
      @move_speed *= options[:move_speed_scale].to_f
    end
    if options[:name_prefix] != false
      prefix = options[:name_prefix] || "召喚"
      @name = prefix.to_s + @name.to_s
    end

    @energy = 0
    return self
  end

  def deploy_to_pixel(x, y)
    @pixel_x = x.to_f
    @pixel_y = y.to_f
    clamp_to_board
    sync_cell_from_pixel
    @velocity_x = 0.0
    @velocity_y = 0.0
    clear_move_goal
    @target = nil
    @threat_source = nil
    @threat_level = :safe
    @action = :idle
    @visual_action = :idle
  end

  def update_summon_lifetime
    return unless summoned?
    return if dead? || @summon_expiring || summon_remove_scheduled?

    if @summon_expire_with_owner &&
       @summon_owner != nil && @summon_owner.dead?
      @scene.expire_summoned_unit(self, :owner_dead) if @scene != nil
      return
    end

    @summon_remaining -= 1 if @summon_remaining > 0
    if @summon_remaining <= 0
      @scene.expire_summoned_unit(self, :duration) if @scene != nil
    end
  end

  def mark_summon_expiring
    @summon_expiring = true
  end

  def summon_remove_scheduled?
    return @summon_remove_scheduled ? true : false
  end

  def mark_summon_remove_scheduled
    @summon_remove_scheduled = true
    @summon_expiring = true
    @battle_active = false
    @velocity_x = 0.0
    @velocity_y = 0.0
    clear_move_goal
  end

  def clear_reference_to(other)
    return if other == nil
    @target = nil if @target == other
    @skill_target = nil if @skill_target == other
    @threat_source = nil if @threat_source == other
    @emergency_target = nil if @emergency_target == other
    @last_attacker = nil if @last_attacker == other
    @protected_ally = nil if @protected_ally == other
    if @taunt_source == other
      clear_taunt
    end
  end

  def pay_hp_cost(value)
    return false if dead?
    cost = [value.to_i, 0].max
    return true if cost <= 0
    return false if @hp <= cost

    before = @hp
    @hp -= cost
    @last_damage = cost
    @last_damage_critical = false
    @damage_popup_frames = 30
    log_event(:hp_cost,
              log_name + " COST -" + cost.to_s +
              " hp=" + before.to_s + "->" + @hp.to_s)
    return true
  end

  # v0.9.1.2
  # 戰鬥邏輯的 pixel_y 是腳底基準；VFX 不應拿腳底或 collision radius 當出射點。
  # 直接依目前 PMD action 的 frame 高度推算 Sprite 幾何中心。
  def visual_frame_height
    data = PMD_AC.action_data(@species, @visual_action)
    if data != nil
      h = data[:frame_h].to_i
      return h if h > 0
    end
    return 52
  end

  def visual_center_x
    return @pixel_x.to_f + @visual_offset_x.to_f
  end

  def visual_center_y
    h = visual_frame_height.to_f * PMD_AC::UNIT_SPRITE_SCALE
    return @pixel_y.to_f + @visual_offset_y.to_f - h * 0.50
  end

  def visual_center
    return [visual_center_x, visual_center_y]
  end

  def boss?
    return @boss
  end

  def aura_data
    return @aura_data
  end

  def projectile_intercept?
    return @projectile_intercept && !dead?
  end

  def rooted?
    return status?(:root)
  end

  def silenced?
    return status?(:silence)
  end

  def feared?
    return status?(:fear)
  end

  def channeling?
    return @channeling && @action == :skill
  end

  def status?(key)
    return @statuses.has_key?(key)
  end

  def energy_locked?
    return status?(:energy_lock)
  end

  def verification_energy_sandbox(enabled)
    @verification_energy_sandbox = enabled ? true : false
  end

  def verification_combat_sandbox(enabled)
    @verification_combat_sandbox = enabled ? true : false
    if @verification_combat_sandbox
      clear_move_goal
      @velocity_x = 0.0
      @velocity_y = 0.0
      @target = nil
      @threat_source = nil
      @emergency_target = nil
      @attack_wait = 9999
    end
  end

  def verification_set_energy(value)
    value = PMD_AC.clamp(value.to_i, 0, PMD_AC::MAX_ENERGY)
    @energy = value
    log_event(:energy,
              log_name + " VERIFY_SET energy=" +
              @energy.to_s + "/" + PMD_AC::MAX_ENERGY.to_s)
    return @energy
  end

  def status_tags(key)
    data = PMD_AC.status_def(key)
    return data[:tags] || []
  end

  def slow_value_for(stat)
    total = 0.0
    for key in @statuses.keys
      data = @statuses[key]
      next if data == nil
      base = PMD_AC.status_def(key)
      tags = base[:tags] || []
      next unless tags.include?(:slow)
      next unless base[:stat] == stat
      stacks = [data[:stacks].to_i, 1].max
      value = data[:value].to_f
      if (base[:stack_mode] || :refresh) == :stack
        value *= stacks
      end
      total += value
    end
    return PMD_AC.clamp(total, 0.0, PMD_AC::SLOW_CAP)
  end

  def status_stat_multiplier(stat)
    mult = 1.0
    for key in @statuses.keys
      data = @statuses[key]
      next if data == nil
      value = data[:value].to_f
      case key
      when :atk_down
        mult *= (1.0 - value) if stat == :atk
      when :def_down
        mult *= (1.0 - value) if stat == :def
      when :atk_up
        mult *= (1.0 + value) if stat == :atk
      when :def_up, :def_aura
        mult *= (1.0 + value) if stat == :def
      end
    end
    if [:move_speed, :attack_speed, :action_speed].include?(stat)
      mult *= (1.0 - slow_value_for(stat))
    end
    return [mult, 0.10].max
  end

  def attack_speed_multiplier
    return status_stat_multiplier(:attack_speed)
  end

  def action_speed_multiplier
    return status_stat_multiplier(:action_speed)
  end

  def scaled_action_timing(timing, speed_multiplier)
    speed = [speed_multiplier.to_f, 0.10].max
    total = (timing[0].to_f / speed).round
    hit = (timing[1].to_f / speed).round
    total = PMD_AC.clamp(total, 8, 180)
    hit = PMD_AC.clamp(hit, 1, total - 1)
    return [total, hit]
  end

  def effective_attack_wait
    speed = [attack_speed_multiplier, 0.10].max
    return [(@attack_wait_max.to_f / speed).round, 1].max
  end

  def status_debug_label
    parts = []
    parts.push("Sh" + @shield.to_i.to_s) if @shield.to_i > 0
    parts.push("TNT") if taunted?
    parts.push("Stn") if @stun_frames.to_i > 0
    parts.push("Chn") if channeling?
    parts.push("Lnk") if @damage_link_frames.to_i > 0
    map = {
      :poison => "Psn", :burn => "Brn", :regen => "HoT",
      :slow => "Mv-", :move_slow => "Mv-", :attack_slow => "AS-",
      :action_slow => "Ac-", :root => "Rt", :silence => "Sil",
      :fear => "Fear", :atk_down => "A-", :def_down => "D-",
      :atk_up => "A+", :def_up => "D+", :def_aura => "Au",
      :energy_lock => "ELk"
    }
    for key in @statuses.keys
      label = map[key]
      parts.push(label) if label != nil
    end
    return parts.join(" ")
  end

  def adjusted_control_duration(control, base_duration)
    duration = base_duration.to_f
    duration *= (1.0 - @cc_resist)
    if boss?
      count = @cc_dr_counts[control] || 0
      index = [count, PMD_AC::CC_DR_STEPS.size - 1].min
      dr = PMD_AC::CC_DR_STEPS[index]
      duration *= dr
      @cc_dr_counts[control] = count + 1
      @cc_dr_timers[control] = PMD_AC::CC_DR_RESET_FRAMES
      log_event(:cc_dr, log_name + " " + control.to_s +
                " stack=" + @cc_dr_counts[control].to_s +
                " mult=" + sprintf("%.2f", dr))
    end
    duration = duration.round
    duration = 1 if duration < 1
    return duration
  end

  def apply_control(control, duration, source = nil)
    return if dead?
    effective = adjusted_control_duration(control, duration)
    src = source == nil ? "SYSTEM" : source.log_name
    case control
    when :stun
      interrupt_action(:stun, source)
      if @action != :idle
        @action = :idle
        @visual_action = :idle
        @action_timer = 0
        @action_total_frames = 0
        @action_hit_done = false
        @action_lunge = 0.0
      end
      @stun_frames = [@stun_frames, effective].max
    when :root, :silence
      interrupt_action(control, source) if control == :silence
      apply_status(control, {:duration => effective, :value => 0,
                             :stack_mode => :refresh}, source)
    when :fear
      interrupt_action(:fear, source)
      if @action != :idle
        @action = :idle
        @visual_action = :idle
        @action_timer = 0
        @action_total_frames = 0
        @action_hit_done = false
        @action_lunge = 0.0
      end
      @fear_source = source
      apply_status(:fear, {:duration => effective, :value => 0,
                           :stack_mode => :refresh}, source)
    else
      return
    end
    log_event(:control, log_name + " " + control.to_s +
              " dur=" + effective.to_s + " src=" + src)
  end

  def interrupt_action(reason, source = nil)
    return false unless @action == :skill
    data = skill_data
    return false unless data[:channeling] || data[:interruptible]
    src = source == nil ? "SYSTEM" : source.log_name
    log_event(:interrupt, log_name + " " + @skill_name.to_s +
              " reason=" + reason.to_s + " src=" + src)
    refund = (data[:interrupt_refund] || 0).to_i
    gain_energy(refund, source, :interrupt_refund) if refund > 0
    @action = :idle
    @visual_action = :idle
    @action_timer = 0
    @action_total_frames = 0
    @action_hit_done = false
    @action_lunge = 0.0
    @channeling = false
    @skill_target = nil
    return true
  end

  def update_cc_dr_timers
    for key in @cc_dr_timers.keys.dup
      @cc_dr_timers[key] -= 1
      if @cc_dr_timers[key] <= 0
        @cc_dr_timers.delete(key)
        @cc_dr_counts.delete(key)
        log_event(:cc_dr, log_name + " " + key.to_s + " RESET") if boss?
      end
    end
  end

  def set_damage_link(protector, ratio, duration)
    return if dead? || protector == nil || protector.dead? || protector == self
    @damage_link_source = protector
    @damage_link_ratio = PMD_AC.clamp(ratio.to_f, 0.0, 0.80)
    @damage_link_frames = [duration.to_i, 1].max
    log_event(:link, log_name + " LINK <- " + protector.log_name +
              " ratio=" + sprintf("%.2f", @damage_link_ratio) +
              " dur=" + @damage_link_frames.to_s)
  end

  def update_damage_link_timer
    return if @damage_link_frames <= 0
    @damage_link_frames -= 1
    if @damage_link_source == nil || @damage_link_source.dead? ||
       @damage_link_frames <= 0
      old = @damage_link_source
      @damage_link_source = nil
      @damage_link_ratio = 0.0
      @damage_link_frames = 0
      log_event(:link, log_name + " LINK END" +
                (old == nil ? "" : " from " + old.log_name))
    end
  end

  def apply_pull(source, distance)
    return if dead? || source == nil
    interrupt_action(:pull, source)
    dx = source.pixel_x - @pixel_x
    dy = source.pixel_y - @pixel_y
    length = Math.sqrt(dx * dx + dy * dy)
    return if length <= 0.001
    frames = 9
    speed = distance.to_f / frames.to_f
    @knockback_x = dx / length * speed
    @knockback_y = dy / length * speed
    @knockback_frames = frames
    @velocity_x = 0.0
    @velocity_y = 0.0
    @scene.release_attack_slot(self) if @scene != nil
    log_event(:pull, log_name + " <- " + source.log_name +
              " dist=" + distance.to_f.round.to_s)
  end

  def dash_toward(other, distance)
    return if dead? || other == nil || other.dead?
    dx = other.pixel_x - @pixel_x
    dy = other.pixel_y - @pixel_y
    length = Math.sqrt(dx * dx + dy * dy)
    return if length <= 0.001
    travel = [distance.to_f, [length - @melee_reach * 0.75, 0.0].max].min
    @pixel_x += dx / length * travel
    @pixel_y += dy / length * travel
    clamp_to_board
    sync_cell_from_pixel
    @velocity_x = 0.0
    @velocity_y = 0.0
    log_event(:dash, log_name + " -> " + other.log_name +
              " dist=" + travel.round.to_s)
  end

  def blink_behind(other, offset = 36.0)
    return if dead? || other == nil || other.dead?

    # v0.10.2.1：真正依「目標面向」找背面，而不是依隊伍左右側。
    forward = other.facing_vector
    back_x = -forward[0]
    back_y = -forward[1]
    side_x = -forward[1]
    side_y = forward[0]
    dist = offset.to_f

    # 後方優先；若貼近邊界，再嘗試後左／後右。
    raw_vectors = [
      [back_x, back_y],
      [back_x * 0.86 + side_x * 0.52,
       back_y * 0.86 + side_y * 0.52],
      [back_x * 0.86 - side_x * 0.52,
       back_y * 0.86 - side_y * 0.52]
    ]

    best_x = other.pixel_x
    best_y = other.pixel_y
    best_dot = 999.0
    best_len = 0.0

    for vec in raw_vectors
      vx = vec[0].to_f
      vy = vec[1].to_f
      vlen = Math.sqrt(vx * vx + vy * vy)
      next if vlen <= 0.001
      vx /= vlen
      vy /= vlen

      cx = PMD_AC.clamp(other.pixel_x + vx * dist,
                        PMD_AC::BOARD_LEFT.to_f,
                        PMD_AC::BOARD_RIGHT.to_f)
      cy = PMD_AC.clamp(other.pixel_y + vy * dist,
                        PMD_AC::BOARD_TOP.to_f,
                        PMD_AC::BOARD_BOTTOM.to_f)

      dx = cx - other.pixel_x
      dy = cy - other.pixel_y
      clen = Math.sqrt(dx * dx + dy * dy)
      next if clen <= 6.0

      nx = dx / clen
      ny = dy / clen
      dot = forward[0] * nx + forward[1] * ny

      # dot 越小越接近真正背面；同樣方位時選較遠的位置。
      if dot < best_dot - 0.001 ||
         ((dot - best_dot).abs <= 0.001 && clen > best_len)
        best_dot = dot
        best_len = clen
        best_x = cx
        best_y = cy
      end
    end

    @pixel_x = best_x
    @pixel_y = best_y
    clamp_to_board
    sync_cell_from_pixel
    @velocity_x = 0.0
    @velocity_y = 0.0
    clear_move_goal
    @scene.release_attack_slot(self) if @scene != nil
    face_toward(other, true)

    arc = other.incoming_arc_from(self)
    log_event(:blink, log_name + " BEHIND " + other.log_name +
              " arc=" + arc.to_s +
              " offset=" + best_len.round.to_s)
  end

  def update_fear_logic
    source = @fear_source
    source = @last_attacker if source == nil || source.dead?
    if source == nil || source.dead?
      clear_move_goal
      return
    end
    dx = @pixel_x - source.pixel_x
    dy = @pixel_y - source.pixel_y
    length = Math.sqrt(dx * dx + dy * dy)
    if length <= 0.001
      dx = @team == :ally ? -1.0 : 1.0
      dy = 0.0
      length = 1.0
    end
    gx = @pixel_x + dx / length * PMD_AC::FEAR_ESCAPE_DISTANCE
    gy = @pixel_y + dy / length * PMD_AC::FEAR_ESCAPE_DISTANCE
    set_move_goal(gx, gy)
  end

  def apply_status(key, options = {}, source = nil)
    return if dead?
    base = PMD_AC.status_def(key)
    return if base.empty?
    duration = (options[:duration] || 120).to_i
    value = options.has_key?(:value) ? options[:value] : 0
    tags = base[:tags] || []
    if tags.include?(:slow)
      raw_slow = value.to_f
      effective_slow = raw_slow * (1.0 - @slow_resist)
      effective_slow = PMD_AC.clamp(effective_slow, 0.0, PMD_AC::SLOW_CAP)
      stat_name = (base[:stat] || :move_speed).to_s
      log_event(:slow, log_name + " " + key.to_s +
                " stat=" + stat_name +
                " raw=" + sprintf("%.3f", raw_slow) +
                " resist=" + sprintf("%.3f", @slow_resist) +
                " effective=" + sprintf("%.3f", effective_slow))
      value = effective_slow
    end
    interval = (options[:interval] || base[:interval] ||
                PMD_AC::STATUS_DEFAULT_INTERVAL).to_i
    stack_mode = options[:stack_mode] || base[:stack_mode] || :refresh
    current = @statuses[key]

    if current != nil && options[:silent_refresh]
      current[:duration] = [current[:duration].to_i, duration].max
      current[:value] = value if value.to_f > current[:value].to_f
      current[:source] = source if source != nil
      return
    end

    if current != nil
      case stack_mode
      when :stack
        current[:stacks] = [current[:stacks].to_i + 1,
                            PMD_AC::STATUS_MAX_STACKS].min
        current[:duration] = [current[:duration].to_i, duration].max
        current[:value] = value if value.to_f > current[:value].to_f
        current[:source] = source if source != nil
        src = source == nil ? "SYSTEM" : source.log_name
        log_event(:status, log_name + " STACK " + key.to_s +
                  " x" + current[:stacks].to_s +
                  " dur=" + current[:duration].to_s +
                  " src=" + src)
        return
      when :replace_stronger
        return if current[:value].to_f > value.to_f &&
                  current[:duration].to_i >= duration
      end
    end

    @statuses[key] = {
      :duration => duration,
      :value => value,
      :interval => [interval, 1].max,
      :tick => [interval, 1].max,
      :stacks => 1,
      :source => source
    }
    src = source == nil ? "SYSTEM" : source.log_name
    log_event(:status, log_name + " APPLY " + key.to_s +
              " value=" + value.to_s + " dur=" + duration.to_s +
              " mode=" + stack_mode.to_s + " src=" + src)
  end

  def remove_status(key)
    existed = @statuses.has_key?(key)
    @statuses.delete(key)
    @fear_source = nil if key == :fear
    log_event(:status, log_name + " REMOVE " + key.to_s) if existed
  end

  def cleanse(tags = [:debuff])
    removed = false
    removed_keys = []
    for key in @statuses.keys.dup
      stags = status_tags(key)
      match = false
      for tag in tags
        match = true if stags.include?(tag)
      end
      if match
        @statuses.delete(key)
        @fear_source = nil if key == :fear
        removed_keys.push(key)
        removed = true
      end
    end
    if (tags.include?(:debuff) || tags.include?(:control)) &&
       @stun_frames.to_i > 0
      @stun_frames = 0
      removed_keys.push(:stun)
      removed = true
    end
    if tags.include?(:debuff) && taunted?
      clear_taunt
      removed_keys.push(:taunt)
      removed = true
    end
    if removed
      log_event(:cleanse, log_name + " CLEANSE [" +
                removed_keys.collect { |k| k.to_s }.join(",") + "]")
    end
    return removed
  end

  def dispel(tags = [:buff])
    removed = false
    removed_keys = []
    for key in @statuses.keys.dup
      stags = status_tags(key)
      match = false
      for tag in tags
        match = true if stags.include?(tag)
      end
      if match
        @statuses.delete(key)
        removed_keys.push(key)
        removed = true
      end
    end
    if removed
      log_event(:dispel, log_name + " DISPEL [" +
                removed_keys.collect { |k| k.to_s }.join(",") + "]")
    end
    return removed
  end

  def add_shield(value, duration = 0, trigger = nil, source = nil)
    return if dead?
    gained = value.to_i
    @shield += gained
    @shield = 0 if @shield < 0
    if duration.to_i > 0
      @shield_frames = [@shield_frames, duration.to_i].max
    end

    if trigger != nil
      @shield_trigger = trigger.dup
      @shield_trigger_source = source
      @shield_trigger_absorb_cooldown = 0
      log_event(:shield_trigger,
                log_name + " ARM absorb=" +
                ((@shield_trigger[:on_absorb] || []).size rescue 1).to_s +
                " break=" +
                ((@shield_trigger[:on_break] || []).size rescue 1).to_s)
    end

    log_event(:shield, log_name + " +" + gained.to_s +
              " shield=" + @shield.to_s +
              " dur=" + @shield_frames.to_s)
  end

  def clear_shield_trigger
    @shield_trigger = nil
    @shield_trigger_source = nil
    @shield_trigger_absorb_cooldown = 0
  end

  def shield_trigger_source
    return @shield_trigger_source
  end

  def shield_trigger_effects(event)
    return [] if @shield_trigger == nil

    if event == :absorb
      return [] if @shield_trigger_absorb_cooldown > 0
      cooldown = (@shield_trigger[:absorb_cooldown] || 0).to_i
      @shield_trigger_absorb_cooldown = cooldown if cooldown > 0
      raw = @shield_trigger[:on_absorb]
    elsif event == :break
      raw = @shield_trigger[:on_break]
    else
      raw = nil
    end

    return [] if raw == nil
    return raw if raw.is_a?(Array)
    return [raw]
  end

  def apply_taunt(source, duration = PMD_AC::TAUNT_DEFAULT_DURATION)
    return if dead? || source == nil || source.dead?
    return unless enemy_of?(source)
    effective = adjusted_control_duration(:taunt, duration)
    @forced_target = source
    @forced_target_frames = [effective.to_i, 1].max
    log_event(:taunt, log_name + " TAUNTED by " + source.log_name +
              " dur=" + @forced_target_frames.to_s)
    set_target(source)
  end

  def clear_taunt
    old = @forced_target
    if old != nil
      log_event(:taunt, log_name + " TAUNT END from " + old.log_name)
    end
    @forced_target = nil
    @forced_target_frames = 0
    if @target == old
      @scene.release_attack_slot(self) if @scene != nil
      @target = nil
    end
  end

  def taunted?
    return @forced_target != nil && @forced_target_frames > 0 &&
           @forced_target.alive?
  end

  def defer_skill
    if @skill_hold_frames <= 0
      log_event(:skill_hold, log_name + " HOLD " + @skill_name.to_s)
    end
    @skill_hold_frames += PMD_AC::LOGIC_TICK
  end

  def reset_skill_hold
    @skill_hold_frames = 0
  end

  def skill_hold_frames
    return @skill_hold_frames
  end

  def role_label
    labels = {
      :frontline => "前衛", :bruiser => "鬥士",
      :controller => "控場", :assassin => "刺客",
      :caster => "術士", :fighter => "戰士"
    }
    return labels[@role] || "戰士"
  end

  def movement_policy_label
    labels = {
      :frontline => "前衛", :bruiser => "鬥士", :assassin => "刺客",
      :kiter => "風箏", :artillery => "砲台", :controller => "控場",
      :bodyguard => "護衛", :berserker => "狂戰"
    }
    return labels[@movement_policy] || @movement_policy.to_s
  end

  def target_policy_label
    labels = {
      :nearest => "最近", :lowest_hp => "殘血", :lowest_hp_percent => "低血%",
      :lowest_def => "低防", :highest_atk => "高攻", :farthest => "最遠",
      :backline => "後排", :ranged_first => "遠程", :melee_first => "近戰",
      :cluster => "群聚", :current_attacker => "攻擊者",
      :backline_low_def => "後排脆皮", :execute => "收割",
      :protect_ally => "護衛威脅"
    }
    return labels[@target_policy] || @target_policy.to_s
  end

  def ai_debug_label
    codes = {
      :frontline => "FR", :bruiser => "BR", :assassin => "AS",
      :kiter => "KT", :artillery => "AR", :controller => "CT",
      :bodyguard => "BG", :berserker => "BZ"
    }
    return codes[@movement_policy] || "AI"
  end

  def dead?
    return @hp <= 0
  end

  def alive?
    return !dead?
  end

  def ranged?
    return @range > 1
  end

  def melee?
    return !ranged?
  end

  def moving?
    return @velocity_x.abs > 0.18 || @velocity_y.abs > 0.18
  end

  def acting?
    return @action_timer > 0
  end

  def battle_active?
    return @battle_active
  end

  def distance_to(other)
    return 999999 if other == nil
    return PMD_AC.distance(@pixel_x, @pixel_y, other.pixel_x, other.pixel_y).to_i
  end

  def distance_to_xy(x, y)
    return PMD_AC.distance(@pixel_x, @pixel_y, x, y)
  end

  def enemy_of?(other)
    return @team != other.team
  end

  def start_combat
    @battle_active = true
    @victory_celebrating = false
    @victory_started_frame = 0
    @velocity_x = 0.0
    @velocity_y = 0.0
    clear_move_goal
    @target = nil
    @action = :idle
    @visual_action = :idle
    @action_timer = 0
    @action_total_frames = 0
    @action_hit_done = false
    @action_lunge = 0.0
    @visual_offset_x = 0.0
    @visual_offset_y = 0.0
    @recoil_x = 0.0
    @recoil_y = 0.0
    @knockback_frames = 0
    @threat_source = nil
    @threat_level = :safe
    @last_attacker = nil
    @last_attacker_memory = 0
    @retarget_cooldown = 0
    @emergency_target = nil
    @threat_release_frames = 0
    @target_recheck_frames = 0
    @protected_ally = nil
    @skill_target = nil
    @skill_recheck_frames = 0
    @skill_hold_frames = 0
    @shield = 0
    @shield_frames = 0
    @shield_trigger = nil
    @shield_trigger_source = nil
    @shield_trigger_absorb_cooldown = 0
    @statuses = {}
    @forced_target = nil
    @forced_target_frames = 0
    @cc_dr_counts = {}
    @cc_dr_timers = {}
    @fear_source = nil
    @damage_link_source = nil
    @damage_link_ratio = 0.0
    @damage_link_frames = 0
    @channeling = false
    @last_escape_fail_log_frame = -9999
    @evade_cooldown = 0
    @evade_visual_frames = 0
    @verification_force_evade = false
    @next_attack_modifier = nil
    @last_damage_critical = false
  end

  def stop_combat
    @battle_active = false
    @victory_celebrating = false
    @velocity_x = 0.0
    @velocity_y = 0.0
    clear_move_goal
  end

  #--------------------------------------------------------------------------
  # ● v0.9.2.1 勝利慶祝
  #--------------------------------------------------------------------------
  def start_victory_celebration
    return if dead?
    @battle_active = false
    @victory_celebrating = true
    @victory_started_frame = Graphics.frame_count
    @velocity_x = 0.0
    @velocity_y = 0.0
    clear_move_goal
    @target = nil
    @skill_target = nil
    @action_timer = 0
    @action_total_frames = 0
    @action_hit_done = false
    @action_lunge = 0.0
    @recoil_x = 0.0
    @recoil_y = 0.0
    @visual_offset_x = 0.0
    @visual_offset_y = 0.0
    @action = :idle
    # v0.9.2.2：勝利慶祝統一面向畫面下方。
    # RPG Maker VX / PMD Runtime 的 numpad 方向：2 = Down。
    @facing_dir = 2
    @pending_dir = 2
    @pending_dir_frames = 0
    # PMD Compiler 的 MOVE 動作在 Runtime 對應 :walk。
    @visual_action = :walk
  end

  def victory_bounce_offset
    return 0.0 unless @victory_celebrating
    elapsed = Graphics.frame_count - @victory_started_frame
    delay = @id.to_i * PMD_AC::VICTORY_BOUNCE_STAGGER
    return 0.0 if elapsed < delay
    period = PMD_AC::VICTORY_BOUNCE_PERIOD
    local = (elapsed - delay) % period
    phase = local.to_f / period.to_f
    # 0 → 向上 → 回地面；不往腳底以下沉。
    return -Math.sin(phase * Math::PI) * PMD_AC::VICTORY_BOUNCE_HEIGHT
  end

  def update
    update_popup
    return unless @battle_active
    update_summon_lifetime
    return if dead?
    update_stun
    update_hurt
    update_hit_system
    update_statuses
    update_shield_timer
    update_forced_target_timer
    update_cc_dr_timers
    update_damage_link_timer
    update_threat_timers
    update_action_timer
    update_movement
    update_visual_motion
    refresh_motion_visual
  end

  def update_logic
    return if dead?
    return if !@battle_active
    if @verification_combat_sandbox
      clear_move_goal
      @velocity_x *= PMD_AC::STOP_DAMPING
      @velocity_y *= PMD_AC::STOP_DAMPING
      return
    end
    return if @stun_frames > 0
    if feared?
      update_fear_logic
      return
    end
    return if acting?

    if @attack_wait > 0
      # Attack Slow 直接降低冷卻倒數速度，因此狀態在既有冷卻途中套用也會立即生效。
      @attack_wait -= PMD_AC::LOGIC_TICK * attack_speed_multiplier
      @attack_wait = 0 if @attack_wait < 0
    end

    validate_target
    update_threat_state
    update_target_selection
    emergency_retarget_if_needed

    if @target == nil
      clear_move_goal
      return
    end

    can_cast = !silenced?
    can_cast = false if @verification_no_auto_skill
    can_cast = false if summoned? && !summon_allow_skill?
    if @threat_level == :emergency &&
       [:kiter, :artillery, :controller].include?(@movement_policy)
      can_cast = false
    end
    if can_cast && @energy >= PMD_AC::MAX_ENERGY && @scene != nil
      skill_target = @scene.skill_target_for(self)
      if skill_target != nil && skill_in_range?(skill_target)
        clear_move_goal
        reset_skill_hold
        begin_skill(skill_target)
        return
      elsif skill_target == nil
        defer_skill
      end
    end

    update_movement_policy_logic
  end

  def update_popup
    @damage_popup_frames -= 1 if @damage_popup_frames > 0
    @skill_popup_frames -= 1 if @skill_popup_frames > 0
  end

  def update_stun
    return if @stun_frames <= 0
    @stun_frames -= 1
    clear_move_goal
    @velocity_x *= PMD_AC::STOP_DAMPING
    @velocity_y *= PMD_AC::STOP_DAMPING
    if @stun_frames == 0 && !dead?
      @action = :idle
      @visual_action = :idle
      log_event(:control, log_name + " stun EXPIRE")
    end
  end

  def update_hurt
    @hurt_frames -= 1 if @hurt_frames > 0
  end


  def update_shield_timer
    if @shield_trigger_absorb_cooldown > 0
      @shield_trigger_absorb_cooldown -= 1
    end

    return if @shield_frames <= 0
    @shield_frames -= 1
    if @shield_frames <= 0
      @shield_frames = 0
      if @shield > 0
        log_event(:shield, log_name + " SHIELD EXPIRE remain=" + @shield.to_s)
      end
      @shield = 0
      clear_shield_trigger
    end
  end

  def update_forced_target_timer
    return if @forced_target_frames <= 0
    @forced_target_frames -= 1
    if @forced_target == nil || @forced_target.dead? ||
       @forced_target_frames <= 0
      clear_taunt
    end
  end

  def update_statuses
    return if dead?
    return if @statuses.empty?
    expired = []
    for key in @statuses.keys
      data = @statuses[key]
      next if data == nil
      data[:duration] -= 1
      base = PMD_AC.status_def(key)
      tick_type = base[:tick_type]
      if tick_type != nil
        data[:tick] -= 1
        if data[:tick] <= 0
          amount = data[:value].to_i * [data[:stacks].to_i, 1].max
          src = data[:source] == nil ? "SYSTEM" : data[:source].log_name
          log_event(:status_tick, log_name + " " + key.to_s.upcase +
                    " tick=" + amount.to_s + " src=" + src)
          if tick_type == :damage
            receive_damage(amount, data[:source], false)
          elsif tick_type == :heal
            heal(amount)
          end
          data[:tick] = [data[:interval].to_i, 1].max
        end
      end
      expired.push(key) if data[:duration] <= 0
    end
    for key in expired
      @statuses.delete(key)
      @fear_source = nil if key == :fear
      log_event(:status, log_name + " EXPIRE " + key.to_s)
    end
  end

  def update_threat_timers
    if @last_attacker_memory > 0
      @last_attacker_memory -= 1
      if @last_attacker_memory <= 0
        @last_attacker_memory = 0
        @last_attacker = nil
      end
    end
    @retarget_cooldown -= 1 if @retarget_cooldown > 0
  end

  def update_action_timer
    return if @action_timer <= 0
    @action_timer -= 1
    if !@action_hit_done && @action_timer <= @action_hit_frame
      @action_hit_done = true
      if @action == :attack
        resolve_basic_attack
      elsif @action == :skill
        @scene.resolve_skill(self) if @scene != nil
      end
    end
    if @action_timer <= 0
      @action_timer = 0
      @action = dead? ? :faint : :idle
      @visual_action = dead? ? :faint : :idle
      @action_lunge = 0.0
      @action_total_frames = 0
      @channeling = false
      @target = nil if @target != nil && @target.dead?
      @skill_target = nil if @action == :idle || @action == :faint
    end
  end

  def update_visual_motion
    @recoil_x *= PMD_AC::RECOIL_DAMPING
    @recoil_y *= PMD_AC::RECOIL_DAMPING
    @recoil_x = 0.0 if @recoil_x.abs < 0.08
    @recoil_y = 0.0 if @recoil_y.abs < 0.08

    lunge = current_lunge_amount
    @visual_offset_x = @action_dir_x * lunge + @recoil_x
    @visual_offset_y = @action_dir_y * lunge + @recoil_y
  end

  def current_lunge_amount
    return 0.0 if @action_timer <= 0 || @action_total_frames <= 0
    return 0.0 if @action_lunge <= 0.0
    hit_elapsed = @action_total_frames - @action_hit_frame
    hit_elapsed = 1 if hit_elapsed <= 0
    elapsed = @action_total_frames - @action_timer
    if elapsed <= hit_elapsed
      ratio = elapsed.to_f / hit_elapsed.to_f
    else
      ratio = @action_timer.to_f / [@action_hit_frame, 1].max.to_f
    end
    ratio = PMD_AC.clamp(ratio, 0.0, 1.0)
    return Math.sin(ratio * Math::PI / 2.0) * @action_lunge
  end

  def set_action_vector_to(other)
    return if other == nil
    dx = other.pixel_x - @pixel_x
    dy = other.pixel_y - @pixel_y
    length = Math.sqrt(dx * dx + dy * dy)
    if length <= 0.001
      @action_dir_x = @team == :ally ? 1.0 : -1.0
      @action_dir_y = 0.0
    else
      @action_dir_x = dx / length
      @action_dir_y = dy / length
    end
  end

  def set_action_vector_to_target
    set_action_vector_to(@target)
  end

  def update_movement
    if @knockback_frames > 0 && !dead?
      @pixel_x += @knockback_x
      @pixel_y += @knockback_y
      @knockback_x *= PMD_AC::KNOCKBACK_DAMPING
      @knockback_y *= PMD_AC::KNOCKBACK_DAMPING
      @knockback_frames -= 1
      clamp_to_board
      sync_cell_from_pixel
      face_delta(-@knockback_x, -@knockback_y, false)
      return
    end
    if dead? || @stun_frames > 0 || acting? || rooted?
      desired_x = 0.0
      desired_y = 0.0
    else
      desired_x, desired_y = desired_velocity
      if @scene != nil
        separation = @scene.separation_vector(self)
        desired_x += separation[0]
        desired_y += separation[1]
        zone_force = @scene.zone_avoidance_vector(self)
        desired_x += zone_force[0]
        desired_y += zone_force[1]
      end
      length = Math.sqrt(desired_x * desired_x + desired_y * desired_y)
      current_speed = effective_move_speed
      if length > current_speed && length > 0.0
        desired_x = desired_x / length * current_speed
        desired_y = desired_y / length * current_speed
      end
    end

    if desired_x.abs < 0.01 && desired_y.abs < 0.01
      @velocity_x *= PMD_AC::STOP_DAMPING
      @velocity_y *= PMD_AC::STOP_DAMPING
      @velocity_x = 0.0 if @velocity_x.abs < 0.04
      @velocity_y = 0.0 if @velocity_y.abs < 0.04
    else
      @velocity_x += (desired_x - @velocity_x) * PMD_AC::ACCELERATION
      @velocity_y += (desired_y - @velocity_y) * PMD_AC::ACCELERATION
    end

    speed = Math.sqrt(@velocity_x * @velocity_x + @velocity_y * @velocity_y)
    current_speed = effective_move_speed
    if speed > current_speed && speed > 0.0
      @velocity_x = @velocity_x / speed * current_speed
      @velocity_y = @velocity_y / speed * current_speed
    end

    @pixel_x += @velocity_x
    @pixel_y += @velocity_y
    clamp_to_board
    sync_cell_from_pixel
    face_delta(@velocity_x, @velocity_y, false) if moving? && !acting?
  end

  def desired_velocity
    return [0.0, 0.0] if @move_goal_x == nil || @move_goal_y == nil
    dx = @move_goal_x - @pixel_x
    dy = @move_goal_y - @pixel_y
    distance = Math.sqrt(dx * dx + dy * dy)
    if distance <= PMD_AC::ARRIVAL_RADIUS
      return [0.0, 0.0]
    end
    speed_scale = [distance / 26.0, 1.0].min
    speed_scale = 0.28 if speed_scale < 0.28
    speed = effective_move_speed * speed_scale
    return [dx / distance * speed, dy / distance * speed]
  end

  def clamp_to_board
    @pixel_x = PMD_AC.clamp(@pixel_x, PMD_AC::BOARD_LEFT.to_f,
                            PMD_AC::BOARD_RIGHT.to_f)
    @pixel_y = PMD_AC.clamp(@pixel_y, PMD_AC::BOARD_TOP.to_f,
                            PMD_AC::BOARD_BOTTOM.to_f)
  end

  def sync_cell_from_pixel
    @cell_x = PMD_AC.pixel_to_cell_x(@pixel_x)
    @cell_y = PMD_AC.pixel_to_cell_y(@pixel_y)
  end

  def refresh_motion_visual
    return if dead?
    return if acting?
    if @stun_frames > 0
      @action = :idle
      @visual_action = :idle
    elsif @evade_visual_frames > 0
      @action = :walk
      @visual_action = :walk
    elsif @hurt_frames > 0
      @action = :hurt
      @visual_action = :hurt
    elsif moving?
      @action = :walk
      @visual_action = :walk
    else
      @action = :idle
      @visual_action = :idle
    end
  end

  def reset_target_recheck
    jitter = PMD_AC::AI_TARGET_REEVALUATE_JITTER
    extra = jitter > 0 ? ((@id * 7 + Graphics.frame_count) % (jitter + 1)) : 0
    @target_recheck_frames = PMD_AC::AI_TARGET_REEVALUATE_FRAMES + extra
  end

  def update_target_selection
    if taunted?
      set_target(@forced_target) if @target != @forced_target
      return
    end
    if @target == nil
      acquire_target
      reset_target_recheck
      return
    end

    # 緊急轉火期間不讓一般評分搶回目標。
    if @emergency_target != nil && @target == @emergency_target
      return
    end

    @target_recheck_frames -= PMD_AC::LOGIC_TICK
    return if @target_recheck_frames > 0
    reset_target_recheck
    reevaluate_target
  end

  def target_switch_ratio
    t = @target_commitment.to_f / 100.0
    return PMD_AC::AI_SWITCH_THRESHOLD_MIN +
           (PMD_AC::AI_SWITCH_THRESHOLD_MAX -
            PMD_AC::AI_SWITCH_THRESHOLD_MIN) * t
  end

  def reevaluate_target
    candidate, candidate_score = best_target_candidate
    return if candidate == nil
    if @target == nil
      set_target(candidate)
      return
    end
    return if candidate == @target

    current_score = target_utility(@target)
    current_score = 1.0 if current_score <= 0.0
    if candidate_score > current_score * target_switch_ratio
      set_target(candidate)
    end
  end

  def set_target(new_target)
    return if new_target == @target
    old_target = @target
    @scene.release_attack_slot(self) if @scene != nil
    @target = new_target
    if PMD_AC::BATTLE_LOG_TARGET
      old_name = old_target == nil ? "NONE" : old_target.log_name
      new_name = @target == nil ? "NONE" : @target.log_name
      log_event(:target, log_name + " " + old_name + " -> " + new_name +
                " policy=" + @target_policy.to_s)
    end
    face_toward(@target, true) if @target != nil
  end

  def best_target_candidate
    enemies = @scene == nil ? [] : @scene.attack_targets_of(self)
    best = nil
    best_score = nil
    for enemy in enemies
      score = target_utility(enemy)
      if best == nil || score > best_score
        best = enemy
        best_score = score
      end
    end
    return [best, best_score || 0.0]
  end

  def protected_ally
    if @protected_ally != nil &&
       @protected_ally.alive? &&
       @protected_ally.team == @team
      return @protected_ally
    end
    @protected_ally = nil
    return nil if @scene == nil
    candidates = @scene.allies_of(self)
    candidates = candidates.find_all { |u| u != self && u.alive? }
    return nil if candidates.empty?

    # 護衛優先保後排／施法者，其次保目前血量比例最低的隊友。
    best = nil
    best_score = nil
    for ally in candidates
      hp_rate = ally.hp.to_f / [ally.maxhp, 1].max.to_f
      score = (1.0 - hp_rate) * 800.0
      score += 1200.0 if ally.ranged?
      score += 500.0 if ally.role == :caster || ally.role == :controller
      score -= distance_to(ally).to_f * 0.8
      if best == nil || score > best_score
        best = ally
        best_score = score
      end
    end
    @protected_ally = best
    return best
  end

  def enemy_backline_depth(enemy)
    # 紅方後排在右側；藍方後排在左側。
    if enemy.team == :enemy
      return enemy.pixel_x - PMD_AC::BOARD_LEFT
    else
      return PMD_AC::BOARD_RIGHT - enemy.pixel_x
    end
  end

  def target_utility(enemy)
    return -999999.0 if enemy == nil || enemy.dead?
    distance = distance_to(enemy).to_f

    # Battle Object 只進入「普通 Target」評分。
    # Decoy 用高 priority 吸引普攻；Bomb / Totem 可被打，但優先度較低。
    if enemy.respond_to?(:battle_object?) && enemy.battle_object?
      base = 12000.0
      return base + enemy.target_priority - distance * 7.0
    end

    hp_rate = enemy.hp.to_f / [enemy.maxhp, 1].max.to_f
    depth = enemy_backline_depth(enemy).to_f
    cluster = @scene == nil ? 1 :
              @scene.enemy_cluster_size(self, enemy, PMD_AC::AOE_RADIUS)
    base = 12000.0

    case @target_policy
    when :lowest_hp
      return base - enemy.hp.to_f * 12.0 - distance * 1.5
    when :lowest_hp_percent
      return base + (1.0 - hp_rate) * 7000.0 - distance * 1.5
    when :lowest_def
      return base - enemy.defense.to_f * 75.0 - distance * 1.5
    when :highest_atk
      return base + enemy.atk.to_f * 70.0 - distance * 2.0
    when :farthest
      return base + distance * 18.0
    when :backline
      return base + depth * 18.0 - distance * 2.0
    when :ranged_first
      return base + (enemy.ranged? ? 5000.0 : 0.0) -
             distance * 8.0
    when :melee_first
      return base + (enemy.melee? ? 5000.0 : 0.0) -
             distance * 8.0
    when :cluster
      return base + cluster * 3600.0 +
             (1.0 - hp_rate) * 900.0 - distance * 5.0
    when :current_attacker
      bonus = (enemy == @last_attacker && @last_attacker_memory > 0) ?
              7000.0 : 0.0
      return base + bonus - distance * 10.0
    when :backline_low_def
      return base + depth * 15.0 +
             (enemy.ranged? ? 3600.0 : 0.0) -
             enemy.defense.to_f * 45.0 +
             (1.0 - hp_rate) * 1800.0 - distance * 3.0
    when :execute
      return base + (1.0 - hp_rate) * 6200.0 -
             distance * 7.0 - enemy.defense.to_f * 8.0
    when :protect_ally
      ally = protected_ally
      if ally != nil
        danger_distance = enemy.distance_to(ally).to_f
        attacking_bonus = enemy.target == ally ? 5200.0 : 0.0
        return base + attacking_bonus -
               danger_distance * 16.0 - distance * 2.0
      end
      return base - distance * 12.0
    else # :nearest
      return base - distance * 18.0 +
             (1.0 - hp_rate) * 300.0
    end
  end

  def validate_target
    if @forced_target != nil &&
       (@forced_target.dead? || !enemy_of?(@forced_target))
      clear_taunt
    end
    if @target != nil && (@target.dead? || !enemy_of?(@target))
      @scene.release_attack_slot(self) if @scene != nil
      @target = nil
    end
    if @emergency_target != nil &&
       (@emergency_target.dead? || !enemy_of?(@emergency_target))
      @emergency_target = nil
      @threat_release_frames = 0
    end
    if @threat_source != nil &&
       (@threat_source.dead? || !enemy_of?(@threat_source))
      @threat_source = nil
      @threat_level = :safe
    end
  end

  def update_threat_state
    old_threat_level = @threat_level
    old_threat_source = @threat_source
    unless [:responsive, :protective].include?(@threat_policy)
      @threat_source = nil
      @threat_level = :safe
      return
    end
    enemies = @scene == nil ? [] : @scene.enemies_of(self)
    best = nil
    best_score = nil

    for enemy in enemies
      distance = distance_to(enemy).to_f
      next if distance > PMD_AC::THREAT_SCAN_RANGE &&
              enemy != @last_attacker

      score = distance
      # 先確保「已經貼近」的敵人一定比遠處舊仇恨更優先，
      # 再用近戰／正在攻擊自己／最近攻擊者做細部排序。
      score -= 1000.0 if distance <= PMD_AC::THREAT_EMERGENCY_RANGE
      score -= 500.0 if distance > PMD_AC::THREAT_EMERGENCY_RANGE &&
                        distance <= PMD_AC::THREAT_PRESSURE_RANGE
      score -= 34.0 if enemy.melee?
      score -= 30.0 if enemy.target == self
      if @threat_policy == :protective
        ally = protected_ally
        if ally != nil
          guard_distance = enemy.distance_to(ally).to_f
          score -= 90.0 if guard_distance <= PMD_AC::AI_BODYGUARD_LEASH
          score -= 80.0 if enemy.target == ally
        end
      end
      if enemy == @last_attacker && @last_attacker_memory > 0
        memory_ratio = @last_attacker_memory.to_f /
                       PMD_AC::THREAT_MEMORY_FRAMES.to_f
        score -= 48.0 * memory_ratio
      end

      if best == nil || score < best_score
        best = enemy
        best_score = score
      end
    end

    @threat_source = best
    @threat_level = :safe
    if best != nil
      distance = distance_to(best).to_f
      if distance <= PMD_AC::THREAT_EMERGENCY_RANGE
        @threat_level = :emergency
      elsif distance <= PMD_AC::THREAT_PRESSURE_RANGE
        @threat_level = :pressured
      end
    end

    if PMD_AC::BATTLE_LOG_THREAT &&
       (old_threat_level != @threat_level ||
        old_threat_source != @threat_source)
      src = @threat_source == nil ? "NONE" : @threat_source.log_name
      log_event(:threat, log_name + " level=" + @threat_level.to_s +
                " source=" + src)
    end

    if @threat_level == :emergency
      @threat_release_frames = 0
    elsif @emergency_target != nil
      @threat_release_frames += PMD_AC::LOGIC_TICK
      if @threat_release_frames >= PMD_AC::THREAT_RELEASE_FRAMES
        if @target == @emergency_target
          @scene.release_attack_slot(self) if @scene != nil
          @target = nil
        end
        @emergency_target = nil
        @threat_release_frames = 0
      end
    else
      @threat_release_frames = 0
    end
  end

  def emergency_retarget_if_needed
    return if taunted?
    return unless [:responsive, :protective].include?(@threat_policy)
    return if @threat_level != :emergency
    return if @threat_source == nil || @threat_source.dead?
    return if @target == @threat_source
    return if @retarget_cooldown > 0

    urgent = @threat_source.melee?
    urgent = true if @threat_source == @last_attacker &&
                     @last_attacker_memory > 0
    return unless urgent

    @scene.release_attack_slot(self) if @scene != nil
    old_target = @target
    @target = @threat_source
    @emergency_target = @threat_source
    if PMD_AC::BATTLE_LOG_TARGET
      old_name = old_target == nil ? "NONE" : old_target.log_name
      log_event(:target, log_name + " EMERGENCY " + old_name +
                " -> " + @target.log_name)
    end
    @retarget_cooldown = PMD_AC::THREAT_RETARGET_COOLDOWN
    @threat_release_frames = 0
    face_toward(@target, true)
  end

  def threat_debug_label
    return "" unless [:responsive, :protective].include?(@threat_policy)
    return "!!" if @threat_level == :emergency
    return "!" if @threat_level == :pressured
    return ""
  end

  def board_edge_distance
    left = @pixel_x - PMD_AC::BOARD_LEFT.to_f
    right = PMD_AC::BOARD_RIGHT.to_f - @pixel_x
    top = @pixel_y - PMD_AC::BOARD_TOP.to_f
    bottom = PMD_AC::BOARD_BOTTOM.to_f - @pixel_y
    return [left, right, top, bottom].min
  end

  def near_board_edge?
    return board_edge_distance <= PMD_AC::AI_EDGE_MARGIN
  end

  # 回傳 true = 找到有意義的逃生位置；false = clamp / 幾何上幾乎無法拉開。
  def set_threat_escape_goal(threat, emergency = false)
    return false if threat == nil
    dx = @pixel_x - threat.pixel_x
    dy = @pixel_y - threat.pixel_y
    length = Math.sqrt(dx * dx + dy * dy)
    if length <= 0.001
      dx = @team == :ally ? -1.0 : 1.0
      dy = ((@id % 3) - 1).to_f * 0.4
      length = Math.sqrt(dx * dx + dy * dy)
    end

    away_x = dx / length
    away_y = dy / length
    side_x = -away_y
    side_y = away_x
    side_sign = ((@id + threat.id) % 2 == 0) ? 1.0 : -1.0
    step = emergency ? PMD_AC::THREAT_EMERGENCY_STEP :
                       PMD_AC::THREAT_PRESSURE_STEP

    candidates = []
    # 原本的斜退兩側 + 正退
    candidates.push([away_x * 0.90 + side_x * 0.58 * side_sign,
                     away_y * 0.90 + side_y * 0.58 * side_sign])
    candidates.push([away_x * 0.90 - side_x * 0.58 * side_sign,
                     away_y * 0.90 - side_y * 0.58 * side_sign])
    candidates.push([away_x, away_y])

    # v0.9.1.4：純側移。被逼在牆上時，「遠離」向量可能整個指向牆外，
    # 這兩個候選讓砲台可以沿牆滑走。
    candidates.push([side_x, side_y])
    candidates.push([-side_x, -side_y])

    # 靠近邊界時再加入朝場中央的脫困向量，避免角落只有 outward 解。
    if near_board_edge?
      center_x = (PMD_AC::BOARD_LEFT + PMD_AC::BOARD_RIGHT) * 0.5
      center_y = (PMD_AC::BOARD_TOP + PMD_AC::BOARD_BOTTOM) * 0.5
      cx = center_x - @pixel_x
      cy = center_y - @pixel_y
      clen = Math.sqrt(cx * cx + cy * cy)
      if clen > 0.001
        candidates.push([cx / clen, cy / clen])
        candidates.push([cx / clen + side_x * 0.45,
                         cy / clen + side_y * 0.45])
        candidates.push([cx / clen - side_x * 0.45,
                         cy / clen - side_y * 0.45])
      end
    end

    current_threat_distance = distance_to(threat).to_f
    best_x = @pixel_x
    best_y = @pixel_y
    best_score = nil
    best_move = 0.0
    best_gain = 0.0

    for vector in candidates
      vx = vector[0]
      vy = vector[1]
      vlen = Math.sqrt(vx * vx + vy * vy)
      next if vlen <= 0.001
      vx /= vlen
      vy /= vlen

      raw_x = @pixel_x + vx * step
      raw_y = @pixel_y + vy * step
      goal_x = PMD_AC.clamp(raw_x, PMD_AC::BOARD_LEFT.to_f,
                            PMD_AC::BOARD_RIGHT.to_f)
      goal_y = PMD_AC.clamp(raw_y, PMD_AC::BOARD_TOP.to_f,
                            PMD_AC::BOARD_BOTTOM.to_f)

      threat_distance = PMD_AC.distance(goal_x, goal_y,
                                        threat.pixel_x, threat.pixel_y)
      actual_move = PMD_AC.distance(@pixel_x, @pixel_y, goal_x, goal_y)
      gain = threat_distance - current_threat_distance

      # 多給「真的有位移」和「離牆更遠」一些分數。
      edge_left = goal_x - PMD_AC::BOARD_LEFT.to_f
      edge_right = PMD_AC::BOARD_RIGHT.to_f - goal_x
      edge_top = goal_y - PMD_AC::BOARD_TOP.to_f
      edge_bottom = PMD_AC::BOARD_BOTTOM.to_f - goal_y
      edge_clearance = [edge_left, edge_right, edge_top, edge_bottom].min

      score = threat_distance * 2.2 + actual_move * 0.7 +
              [edge_clearance, 34.0].min * 0.16

      if @target != nil && @target.alive?
        target_distance = PMD_AC.distance(goal_x, goal_y,
                                          @target.pixel_x, @target.pixel_y)
        if target_distance > @max_range
          score -= (target_distance - @max_range) * 1.15
        elsif target_distance < @min_range
          score -= (@min_range - target_distance) * 0.30
        end
      end

      if best_score == nil || score > best_score
        best_score = score
        best_x = goal_x
        best_y = goal_y
        best_move = actual_move
        best_gain = gain
      end
    end

    meaningful = best_move >= PMD_AC::AI_ESCAPE_MIN_MOVE &&
                 best_gain >= PMD_AC::AI_ESCAPE_MIN_GAIN

    unless meaningful
      clear_move_goal
      now = Graphics.frame_count
      if now - @last_escape_fail_log_frame >= PMD_AC::ESCAPE_FAIL_LOG_INTERVAL
        @last_escape_fail_log_frame = now
        log_event(:escape_fail,
                  log_name + " threat=" + threat.log_name +
                  " move=" + best_move.round.to_s +
                  " gain=" + best_gain.round.to_s +
                  " edge=" + board_edge_distance.round.to_s)
      end
      return false
    end

    set_move_goal(best_x, best_y)
    return true
  end

  def emergency_return_fire?(escape_ok)
    return false if @target == nil || @target.dead?
    return false if @attack_wait > 0
    return false if distance_to(@target).to_f > @max_range
    return true unless escape_ok
    # 即使沿牆還能滑一點，只要已經被逼在邊界，就不能無限放棄輸出。
    return true if near_board_edge?
    return false
  end


  def acquire_target
    best, score = best_target_candidate
    set_target(best)
  end

  # v0.6 相容入口：舊腳本／Debug 若呼叫 target_score，改回傳「越低越好」。
  def target_score(enemy)
    return -target_utility(enemy)
  end

  #--------------------------------------------------------------------------
  # ● v0.10.2 Directional Defense / Back Attack
  #--------------------------------------------------------------------------
  def facing_vector
    diag = 0.70710678
    case @facing_dir
    when 2
      return [0.0, 1.0]
    when 3
      return [diag, diag]
    when 6
      return [1.0, 0.0]
    when 9
      return [diag, -diag]
    when 8
      return [0.0, -1.0]
    when 7
      return [-diag, -diag]
    when 4
      return [-1.0, 0.0]
    when 1
      return [-diag, diag]
    end
    return [0.0, 1.0]
  end

  def incoming_arc_from(source)
    return :side if source == nil
    dx = source.pixel_x - @pixel_x
    dy = source.pixel_y - @pixel_y
    len = Math.sqrt(dx * dx + dy * dy)
    return :side if len <= 0.001

    nx = dx / len
    ny = dy / len
    forward = facing_vector
    dot = forward[0] * nx + forward[1] * ny

    return :front if dot >= PMD_AC::DIRECTION_FRONT_DOT
    return :back if dot <= -PMD_AC::DIRECTION_FRONT_DOT
    return :side
  end

  def directional_damage_multiplier(arc)
    case arc
    when :front
      return @front_damage_multiplier
    when :back
      return @back_damage_multiplier
    else
      return @side_damage_multiplier
    end
  end

  def verification_set_facing(direction)
    return unless PMD_AC::DIRECTION_ROWS.has_key?(direction)
    @facing_dir = direction
    @pending_dir = direction
    @pending_dir_frames = 0
  end

  def face_toward(other, immediate = true)
    return if other == nil
    face_delta(other.pixel_x - @pixel_x,
               other.pixel_y - @pixel_y, immediate)
  end

  def face_delta(dx, dy, immediate = false)
    new_dir = PMD_AC.direction_from_delta(dx, dy, @facing_dir)
    if immediate
      @facing_dir = new_dir
      @pending_dir = new_dir
      @pending_dir_frames = 0
      return
    end
    if new_dir == @facing_dir
      @pending_dir = new_dir
      @pending_dir_frames = 0
    elsif new_dir == @pending_dir
      @pending_dir_frames += 1
      if @pending_dir_frames >= PMD_AC::DIRECTION_HOLD_FRAMES
        @facing_dir = new_dir
        @pending_dir_frames = 0
      end
    else
      @pending_dir = new_dir
      @pending_dir_frames = 1
    end
  end

  def set_move_goal(x, y)
    @move_goal_x = PMD_AC.clamp(x.to_f, PMD_AC::BOARD_LEFT.to_f,
                                PMD_AC::BOARD_RIGHT.to_f)
    @move_goal_y = PMD_AC.clamp(y.to_f, PMD_AC::BOARD_TOP.to_f,
                                PMD_AC::BOARD_BOTTOM.to_f)
  end

  def clear_move_goal
    @move_goal_x = nil
    @move_goal_y = nil
  end

  def update_movement_policy_logic
    case @movement_policy
    when :frontline
      update_frontline_logic
    when :bruiser
      update_bruiser_logic
    when :assassin
      update_assassin_logic
    when :kiter
      update_kiter_logic
    when :artillery
      update_artillery_logic
    when :controller
      update_controller_logic
    when :bodyguard
      update_bodyguard_logic
    when :berserker
      update_berserker_logic
    else
      ranged? ? update_kiter_logic : update_frontline_logic
    end
  end

  def update_frontline_logic
    # 前衛重點是接敵與卡線，不主動繞後。
    update_melee_logic
  end

  def update_bruiser_logic
    # 鬥士仍以近戰攻擊為主；target_policy 通常搭配 execute，
    # 因此會在「值得換線」時追殘血，但受 Commitment 抑制頻繁轉頭。
    update_melee_logic
  end

  def update_assassin_logic
    return if @target == nil
    distance = distance_to(@target).to_f
    if distance <= @melee_reach
      clear_move_goal
      face_toward(@target, true)
      begin_attack if @attack_wait <= 0
      return
    end

    # 先嘗試繞到敵方後側，再貼近；形成與普通前衛不同的進場路徑。
    sign = @target.team == :enemy ? 1.0 : -1.0
    side = ((@id % 2) == 0 ? 1.0 : -1.0)
    flank_x = @target.pixel_x + sign * PMD_AC::AI_ASSASSIN_FLANK_OFFSET
    flank_y = @target.pixel_y + side * PMD_AC::AI_ASSASSIN_FLANK_OFFSET * 0.55
    if distance_to_xy(flank_x, flank_y) > 26.0 &&
       distance > @melee_reach + 28.0
      set_move_goal(flank_x, flank_y)
    else
      slot = @scene.attack_slot_position(self, @target)
      slot == nil ? set_move_goal(@target.pixel_x, @target.pixel_y) :
                    set_move_goal(slot[0], slot[1])
    end
  end

  def update_kiter_logic
    update_ranged_logic
  end

  def update_artillery_logic
    return if @target == nil
    @scene.release_attack_slot(self) if @scene != nil

    target_distance = distance_to(@target).to_f

    if @threat_level == :emergency && @threat_source != nil
      escape_ok = set_threat_escape_goal(@threat_source, true)
      if emergency_return_fire?(escape_ok)
        clear_move_goal
        face_toward(@target, true)
        log_event(:pin_break,
                  log_name + " EMERGENCY RETURN_FIRE -> " +
                  @target.log_name + " edge=" +
                  board_edge_distance.round.to_s)
        begin_attack
      end
      return
    elsif @threat_level == :pressured && @threat_source != nil
      # 砲台受壓時不再完全禁火：冷卻好了先打一發，再繼續移位。
      if target_distance <= @max_range && @attack_wait <= 0
        clear_move_goal
        face_toward(@target, true)
        begin_attack
      else
        set_threat_escape_goal(@threat_source, false)
      end
      return
    end

    desired = [@preferred_range + PMD_AC::AI_ARTILLERY_RANGE_BONUS,
               @max_range - 8.0].min
    desired = @preferred_range if desired < @preferred_range

    if target_distance > @max_range
      move_toward_distance(@target, desired)
    elsif target_distance < desired - 18.0
      move_away_from(@target, desired)
    else
      clear_move_goal
      face_toward(@target, true)
      begin_attack if @attack_wait <= 0
    end
  end

  def update_controller_logic
    # 控場型的「找群聚」由 Target Policy 負責；
    # 移動則採較保守的 Kiter 邏輯，避免為了群聚目標一路走進前線。
    update_ranged_logic
  end

  def update_bodyguard_logic
    return if @target == nil
    ally = protected_ally
    if ally == nil
      update_ranged_logic
      return
    end

    # 護衛站在被保護者與威脅之間，並限制自己離隊友太遠。
    dx = @target.pixel_x - ally.pixel_x
    dy = @target.pixel_y - ally.pixel_y
    length = Math.sqrt(dx * dx + dy * dy)
    if length <= 0.001
      dx = @team == :ally ? 1.0 : -1.0
      dy = 0.0
      length = 1.0
    end
    guard_x = ally.pixel_x + dx / length * PMD_AC::AI_BODYGUARD_OFFSET
    guard_y = ally.pixel_y + dy / length * PMD_AC::AI_BODYGUARD_OFFSET

    target_distance = distance_to(@target).to_f
    ally_distance = distance_to(ally).to_f

    if target_distance <= @max_range &&
       ally_distance <= PMD_AC::AI_BODYGUARD_LEASH
      clear_move_goal
      face_toward(@target, true)
      begin_attack if @attack_wait <= 0
    else
      set_move_goal(guard_x, guard_y)
    end
  end

  def update_berserker_logic
    update_melee_logic
  end

  def effective_move_speed
    speed = @move_speed
    if @movement_policy == :berserker
      hp_rate = @hp.to_f / [@maxhp, 1].max.to_f
      speed *= PMD_AC::AI_BERSERKER_SPEED_BONUS if hp_rate <= PMD_AC::AI_BERSERKER_HP_RATE
    elsif @movement_policy == :assassin
      speed *= 1.06
    end
    speed *= status_stat_multiplier(:move_speed)
    return speed
  end

  def update_melee_logic
    return if @target == nil
    distance = distance_to(@target).to_f
    if distance <= @melee_reach
      clear_move_goal
      face_toward(@target, true)
      begin_attack if @attack_wait <= 0
    else
      slot = @scene.attack_slot_position(self, @target)
      if slot != nil
        set_move_goal(slot[0], slot[1])
      else
        set_move_goal(@target.pixel_x, @target.pixel_y)
      end
    end
  end

  def update_ranged_logic
    return if @target == nil
    @scene.release_attack_slot(self) if @scene != nil

    if @threat_level == :emergency && @threat_source != nil
      escape_ok = set_threat_escape_goal(@threat_source, true)
      if emergency_return_fire?(escape_ok)
        clear_move_goal
        face_toward(@target, true)
        log_event(:pin_break,
                  log_name + " EMERGENCY RETURN_FIRE -> " +
                  @target.log_name + " edge=" +
                  board_edge_distance.round.to_s)
        begin_attack
      end
      return
    end

    target_distance = distance_to(@target).to_f

    if @threat_level == :pressured && @threat_source != nil
      # 受壓時仍保留原攻擊目標；冷卻完成可短暫停步反擊，
      # 其餘時間重新站位，讓遠程不是只會對著原目標倒車。
      if target_distance <= @max_range && @attack_wait <= 0
        clear_move_goal
        face_toward(@target, true)
        begin_attack
      else
        set_threat_escape_goal(@threat_source, false)
      end
      return
    end

    if target_distance > @max_range
      move_toward_distance(@target, @preferred_range)
    elsif target_distance < @min_range
      move_away_from(@target, @preferred_range)
    else
      clear_move_goal
      face_toward(@target, true)
      begin_attack if @attack_wait <= 0
    end
  end

  def move_toward_distance(other, desired_distance)
    dx = @pixel_x - other.pixel_x
    dy = @pixel_y - other.pixel_y
    distance = Math.sqrt(dx * dx + dy * dy)
    if distance <= 0.001
      dx = @team == :ally ? -1.0 : 1.0
      dy = 0.0
      distance = 1.0
    end
    goal_x = other.pixel_x + dx / distance * desired_distance
    goal_y = other.pixel_y + dy / distance * desired_distance
    set_move_goal(goal_x, goal_y)
  end

  def move_away_from(other, desired_distance)
    dx = @pixel_x - other.pixel_x
    dy = @pixel_y - other.pixel_y
    distance = Math.sqrt(dx * dx + dy * dy)
    if distance <= 0.001
      dx = @team == :ally ? -1.0 : 1.0
      dy = ((@id % 3) - 1).to_f * 0.35
      distance = Math.sqrt(dx * dx + dy * dy)
    end
    goal_x = other.pixel_x + dx / distance * desired_distance
    goal_y = other.pixel_y + dy / distance * desired_distance
    set_move_goal(goal_x, goal_y)
  end

  def skill_in_range?(other)
    return false if other == nil || other.dead?
    return true if skill_data[:global_range]
    distance = distance_to(other).to_f
    if ranged?
      return distance <= @max_range + 12.0
    end
    return distance <= @melee_reach + PMD_AC::MELEE_HIT_GRACE
  end

  def begin_attack
    return if @target == nil || @target.dead?
    face_toward(@target, true)
    clear_move_goal
    @velocity_x *= 0.45
    @velocity_y *= 0.45
    @action = :attack
    @visual_action = @basic_action
    timing = PMD_AC.action_timing(@species, @visual_action, 18, 8)
    timing = scaled_action_timing(timing, attack_speed_multiplier)
    @action_timer = timing[0]
    @action_total_frames = timing[0]
    @action_hit_frame = timing[1]
    @action_hit_done = false
    set_action_vector_to_target
    @action_lunge = melee? ? PMD_AC::BASIC_LUNGE_DISTANCE : 2.5
    @attack_wait = @attack_wait_max.to_f
    @scene.play_basic_se(self, :cast) if @scene != nil
  end

  def begin_skill(skill_target = nil)
    @skill_target = skill_target || @target
    return if @skill_target == nil || @skill_target.dead?
    face_toward(@skill_target, true)
    clear_move_goal
    @velocity_x *= 0.35
    @velocity_y *= 0.35
    @action = :skill
    @visual_action = @skill_action
    timing = PMD_AC.action_timing(@species, @visual_action, 28, 12)
    if skill_data[:cast_frames]
      total = skill_data[:cast_frames].to_i
      hit = (skill_data[:hit_frame] || [total / 3, 1].max).to_i
      timing = [total, hit]
    end
    raw_total = timing[0]
    raw_hit = timing[1]
    action_mult = action_speed_multiplier
    timing = scaled_action_timing(timing, action_mult)
    if action_mult < 0.999
      log_event(:action_timing,
                log_name + " " + @skill_name.to_s +
                " action_mult=" + sprintf("%.3f", action_mult) +
                " raw=(" + raw_total.to_s + "," + raw_hit.to_s + ")" +
                " scaled=(" + timing[0].to_s + "," + timing[1].to_s + ")")
    end
    @channeling = skill_data[:channeling] ? true : false
    if @channeling
      log_event(:channel, log_name + " CHANNEL " + @skill_name.to_s +
                " frames=" + timing[0].to_s)
    end
    @action_timer = timing[0]
    @action_total_frames = timing[0]
    @action_hit_frame = timing[1]
    @action_hit_done = false
    set_action_vector_to(@skill_target)
    @action_lunge = melee? ? PMD_AC::SKILL_LUNGE_DISTANCE : 4.0
    @energy = 0
    @skill_popup_frames = 42
    effective_policy = skill_data[:policy] || @skill_policy
    log_event(:skill, log_name + " CAST " + @skill_name.to_s +
              " -> " + @skill_target.log_name +
              " policy=" + effective_policy.to_s)
    @scene.add_cast_effect(self) if @scene != nil
    @scene.play_skill_se(self, :cast) if @scene != nil
  end

  def resolve_basic_attack
    return if @target == nil || @target.dead?
    intended_target = @target
    hit_target = @scene == nil ? intended_target :
                 @scene.substitute_target_for(self, intended_target, :basic)
    face_toward(intended_target, true)
    modifier = consume_next_attack_modifier

    if ranged?
      tracking_override = nil
      if modifier != nil
        tracking_override = modifier[:projectile_tracking]
      end
      @scene.launch_projectile(self, hit_target, :basic, 100, :single,
                               tracking_override, modifier, false)
      @scene.play_basic_se(self, :launch) if @scene != nil
      return
    end

    evaded = hit_target.try_active_evade(self, :melee)
    in_range = distance_to(hit_target).to_f <=
               @melee_reach + PMD_AC::MELEE_HIT_GRACE

    if in_range
      if evaded
        log_event(:evade_fail,
                  hit_target.log_name + " melee still_hit by " + log_name)
      end
      @scene.deal_direct_damage(self, hit_target, 100,
                                {:modifier => modifier,
                                 :source_type => :basic})
      gain_energy(PMD_AC::ENERGY_ON_BASIC_HIT, hit_target, :basic_hit)
      @scene.add_vfx_impact(hit_target, :impact) if @scene != nil
      @scene.play_basic_se(self, :hit) if @scene != nil
    else
      if evaded
        log_event(:evade_success,
                  hit_target.log_name + " melee avoided " + log_name)
      end
      register_miss(hit_target)
    end
  end

  def register_miss(target_unit)
    @miss_count += 1
    if @scene != nil
      @scene.register_miss(self, target_unit)
    end
  end

  def apply_knockback(source, distance)
    return if dead? || source == nil
    interrupt_action(:knockback, source)
    dx = @pixel_x - source.pixel_x
    dy = @pixel_y - source.pixel_y
    length = Math.sqrt(dx * dx + dy * dy)
    if length <= 0.001
      dx = @team == :ally ? -1.0 : 1.0
      dy = 0.0
      length = 1.0
    end
    frames = 9
    speed = distance.to_f / frames.to_f
    @knockback_x = dx / length * speed
    @knockback_y = dy / length * speed
    @knockback_frames = frames
    @velocity_x = 0.0
    @velocity_y = 0.0
    @scene.release_attack_slot(self) if @scene != nil
  end

  def calculate_damage(target_unit, power)
    base = atk * power / 100 - target_unit.defense / 2
    base = 1 if base < 1
    variance = [base / 8, 1].max
    return [base + rand(variance * 2 + 1) - variance, 1].max
  end

  def receive_damage(value, source = nil, grant_energy = true, bypass_link = false, critical = false)
    return if dead?
    raw_value = value.to_i
    value = raw_value
    value = 1 if value < 1

    absorbed = 0
    shield_broken = false
    if @shield > 0
      absorbed = [@shield, value].min
      @shield -= absorbed
      shield_broken = absorbed > 0 && @shield <= 0
      @shield_frames = 0 if @shield <= 0
      value -= absorbed

      if absorbed > 0 && @scene != nil
        @scene.resolve_shield_trigger(self, source, :absorb, absorbed)
        if shield_broken
          @scene.resolve_shield_trigger(self, source, :break, absorbed)
          clear_shield_trigger
        end
      end
    end

    redirected = 0
    if value > 0 && !bypass_link && @damage_link_frames > 0 &&
       @damage_link_source != nil && @damage_link_source.alive?
      redirected = (value * @damage_link_ratio).round
      redirected = value if redirected > value
      if redirected > 0
        value -= redirected
        log_event(:link, log_name + " REDIRECT " + redirected.to_s +
                  " -> " + @damage_link_source.log_name)
        @damage_link_source.receive_damage(redirected, source, false, true)
      end
    end

    if value > 0
      @hp -= value
      @hp = 0 if @hp < 0
      @last_damage = value
      @last_damage_critical = critical ? true : false
      @damage_popup_frames = 36
      if source != nil
        @last_attacker = source
        @last_attacker_memory = PMD_AC::THREAT_MEMORY_FRAMES
        dx = @pixel_x - source.pixel_x
        dy = @pixel_y - source.pixel_y
        length = Math.sqrt(dx * dx + dy * dy)
        if length > 0.001
          recoil = PMD_AC.clamp(value / 20.0 + 2.0, 2.5, PMD_AC::RECOIL_LIMIT)
          @recoil_x += dx / length * recoil
          @recoil_y += dy / length * recoil
        end
      end
      @scene.register_impact(value) if @scene != nil
      gain_energy(PMD_AC::ENERGY_ON_DAMAGE_TAKEN, source,
                  :damage_taken) if grant_energy && !dead?
    else
      @last_damage = 0
      @last_damage_critical = false
      @damage_popup_frames = 20 if absorbed > 0
    end

    if PMD_AC::BATTLE_LOG_DAMAGE
      src = source == nil ? "SYSTEM" : source.log_name
      log_event(:damage, log_name + " <- " + src +
                " raw=" + raw_value.to_s +
                " shield_absorb=" + absorbed.to_s +
                " redirected=" + redirected.to_s +
                " hp_damage=" + value.to_s +
                " critical=" + (critical ? "1" : "0") +
                " hp=" + @hp.to_s + "/" + @maxhp.to_s +
                " shield=" + @shield.to_s)
    end

    if dead?
      start_faint
    elsif value > 0
      @hurt_frames = [@hurt_frames, 10].max
    end
  end

  def heal(value)
    return if dead?
    attempted = value.to_i
    before = @hp
    @hp += attempted
    @hp = @maxhp if @hp > @maxhp
    actual = @hp - before
    log_event(:heal, log_name + " attempted=" + attempted.to_s +
              " actual=" + actual.to_s +
              " hp=" + @hp.to_s + "/" + @maxhp.to_s)
  end

  def gain_energy(value, source = nil, reason = :generic)
    return 0 if dead?
    amount = value.to_i
    return 0 if amount <= 0

    # ENERGY Verification 要排除普攻／受傷自動充能，避免干擾固定數值測試。
    if @verification_energy_sandbox &&
       [:basic_hit, :damage_taken].include?(reason)
      return 0
    end

    if energy_locked?
      src = source == nil ? "SYSTEM" : source.log_name
      log_event(:energy_block,
                log_name + " BLOCK +" + amount.to_s +
                " reason=" + reason.to_s + " src=" + src +
                " energy=" + @energy.to_s + "/" +
                PMD_AC::MAX_ENERGY.to_s)
      return 0
    end

    before = @energy
    @energy += amount
    @energy = PMD_AC::MAX_ENERGY if @energy > PMD_AC::MAX_ENERGY
    actual = @energy - before

    passive = [:basic_hit, :damage_taken].include?(reason)
    if actual > 0 && (!passive || PMD_AC::ENERGY_LOG_PASSIVE_FLOW)
      src = source == nil ? "SYSTEM" : source.log_name
      log_event(:energy,
                log_name + " GAIN +" + actual.to_s +
                " reason=" + reason.to_s + " src=" + src +
                " energy=" + @energy.to_s + "/" +
                PMD_AC::MAX_ENERGY.to_s)
    end
    return actual
  end

  def lose_energy(value, source = nil, reason = :drain)
    return 0 if dead?
    amount = value.to_i
    return 0 if amount <= 0
    before = @energy
    @energy -= amount
    @energy = 0 if @energy < 0
    actual = before - @energy
    if actual > 0
      src = source == nil ? "SYSTEM" : source.log_name
      log_event(:energy,
                log_name + " DRAIN -" + actual.to_s +
                " reason=" + reason.to_s + " src=" + src +
                " energy=" + @energy.to_s + "/" +
                PMD_AC::MAX_ENERGY.to_s)
    end
    return actual
  end

  def apply_stun(frames, source = nil)
    apply_control(:stun, frames, source)
  end

  def start_faint
    return if @dead_started
    @dead_started = true
    @victory_celebrating = false
    @hp = 0
    killer = @last_attacker == nil ? "UNKNOWN" : @last_attacker.log_name
    log_event(:death, log_name + " FAINT killer=" + killer)
    if summoned?
      log_event(:summon_end,
                log_name + " reason=defeated killer=" + killer)
      if @scene != nil && !summon_remove_scheduled?
        @scene.schedule_summon_removal(
          self, :defeated, PMD_AC::SUMMON_DEFEAT_FAINT_FRAMES)
      end
    end
    unless @statuses.empty?
      log_event(:status, log_name + " CLEAR_ON_FAINT [" +
                @statuses.keys.collect { |k| k.to_s }.join(",") + "]")
    end
    @statuses.clear
    @fear_source = nil
    @shield = 0
    @shield_frames = 0
    clear_shield_trigger
    @damage_link_source = nil
    @damage_link_ratio = 0.0
    @damage_link_frames = 0
    @channeling = false
    clear_taunt if taunted?
    @energy = 0
    @action_timer = 0
    @action_total_frames = 0
    @action_hit_done = false
    @action_lunge = 0.0
    @action = :faint
    @visual_action = :faint
    @target = nil
    @threat_source = nil
    @threat_level = :safe
    @last_attacker = nil
    @last_attacker_memory = 0
    @emergency_target = nil
    @protected_ally = nil
    @target_recheck_frames = 0
    @velocity_x = 0.0
    @velocity_y = 0.0
    @visual_offset_x = 0.0
    @visual_offset_y = 0.0
    @recoil_x = 0.0
    @recoil_y = 0.0
    @knockback_frames = 0
    clear_move_goal
    @scene.release_attack_slot(self) if @scene != nil
  end

  # 戰前布陣使用：立即改變棋格與畫面位置，不播放移動動畫。
  def deploy_to_cell(x, y)
    @victory_celebrating = false
    @cell_x = x.to_i
    @cell_y = y.to_i
    @pixel_x = PMD_AC.cell_pixel_x(@cell_x).to_f
    @pixel_y = PMD_AC.cell_pixel_y(@cell_y).to_f
    @velocity_x = 0.0
    @velocity_y = 0.0
    clear_move_goal
    @target = nil
    @action_timer = 0
    @action_total_frames = 0
    @action_hit_done = false
    @action_lunge = 0.0
    @visual_offset_x = 0.0
    @visual_offset_y = 0.0
    @recoil_x = 0.0
    @recoil_y = 0.0
    @knockback_frames = 0
    @threat_source = nil
    @threat_level = :safe
    @last_attacker = nil
    @last_attacker_memory = 0
    @retarget_cooldown = 0
    @emergency_target = nil
    @threat_release_frames = 0
    @target_recheck_frames = 0
    @protected_ally = nil
    @action = :idle
    @visual_action = :idle
  end
end

#==============================================================================
# ■ Game_PMDBattleObject
#------------------------------------------------------------------------------
#  v0.11 通用戰場物件。不是 Battler，不計入勝負，但可選擇性成為普通攻擊目標。
#==============================================================================
class Game_PMDBattleObject
  attr_accessor :scene
  attr_reader   :id
  attr_reader   :owner
  attr_reader   :team
  attr_reader   :key
  attr_reader   :kind
  attr_reader   :name
  attr_reader   :style
  attr_reader   :pixel_x
  attr_reader   :pixel_y
  attr_reader   :collision_radius
  attr_reader   :hp
  attr_reader   :maxhp
  attr_reader   :duration
  attr_reader   :age
  attr_reader   :trigger_radius
  attr_reader   :effect_radius
  attr_reader   :scope
  attr_reader   :effects
  attr_reader   :triggered
  attr_reader   :target_priority
  attr_reader   :expire_reason
  attr_reader   :config

  def initialize(scene, id, owner, key, x, y, data)
    @scene = scene
    @id = id
    @owner = owner
    @team = owner == nil ? :ally : owner.team
    @key = key
    @kind = data[:kind] || key
    @name = data[:name] || key.to_s
    @style = data[:style] || @kind
    @pixel_x = x.to_f
    @pixel_y = y.to_f
    @collision_radius =
      (data[:collision_radius] ||
       PMD_AC::BATTLE_OBJECT_DEFAULT_RADIUS).to_f
    @targetable = data[:targetable] ? true : false
    hp_value = data[:hp] || 1
    @maxhp = [hp_value.to_i, 1].max
    @hp = @maxhp
    @duration =
      (data[:duration] || PMD_AC::BATTLE_OBJECT_DEFAULT_DURATION).to_i
    @age = 0
    @arm_delay = (data[:arm_delay] || 0).to_i
    @trigger_delay = data[:trigger_delay]
    @trigger_delay = @trigger_delay.to_i if @trigger_delay != nil
    @tick_interval = (data[:tick_interval] || 0).to_i
    @next_tick = @tick_interval
    @trigger_radius = (data[:trigger_radius] || 0.0).to_f
    @effect_radius = (data[:effect_radius] || 0.0).to_f
    @scope = data[:scope] || :enemies
    @effects = data[:effects] || []
    @target_priority = (data[:target_priority] || 0.0).to_f
    @detonate_on_destroy = data[:detonate_on_destroy] ? true : false
    @triggered = false
    @expired = false
    @expire_reason = nil
    @config = data
  end

  def battle_object?
    return true
  end

  def alive?
    return false if @expired
    return false if @targetable && @hp <= 0
    return true
  end

  def dead?
    return !alive?
  end

  def expired?
    return @expired
  end

  def targetable?
    return @targetable && alive?
  end

  def acting?
    return false
  end

  def ranged?
    return false
  end

  def melee?
    return false
  end

  def role
    return :battle_object
  end

  def defense
    return 0
  end

  def atk
    return @owner == nil ? 0 : @owner.atk
  end

  def target
    return nil
  end

  def shield
    return 0
  end

  def log_name
    return "OBJECT:" + @name + "#" + @id.to_s
  end

  def visual_center_x
    return @pixel_x
  end

  def visual_center_y
    return @pixel_y - 8.0
  end

  def distance_to(other)
    return 9999.0 if other == nil
    return PMD_AC.distance(@pixel_x, @pixel_y,
                           other.pixel_x, other.pixel_y)
  end

  def incoming_arc_from(source)
    return :side
  end

  def directional_damage_multiplier(arc)
    return 1.0
  end

  def try_active_evade(source, attack_kind = :direct)
    return false
  end

  def receive_damage(value, source = nil, grant_energy = true,
                     bypass_link = false, critical = false)
    return if dead? || !@targetable
    damage = [value.to_i, 0].max
    return if damage <= 0
    before = @hp
    @hp -= damage
    @hp = 0 if @hp < 0
    src = source == nil ? "SYSTEM" : source.log_name
    @scene.log_event(:object_damage,
      log_name + " <- " + src +
      " damage=" + damage.to_s +
      " critical=" + (critical ? "1" : "0") +
      " hp=" + @hp.to_s + "/" + @maxhp.to_s)
    if before > 0 && @hp <= 0
      @scene.destroy_battle_object(self, source)
    end
  end

  # Skill Framework 誤碰到 Object 時保持安全；預設不接受狀態系統。
  def apply_status(key, options = {}, source = nil)
    return false
  end

  def heal(value)
    return 0
  end

  def add_shield(value, duration = 0, trigger = nil, source = nil)
    return 0
  end

  def gain_energy(value, source = nil, reason = :generic)
    return 0
  end

  def lose_energy(value, source = nil, reason = :drain)
    return 0
  end

  def mark_triggered
    @triggered = true
  end

  def detonate_on_destroy?
    return @detonate_on_destroy
  end

  def intercept_owner?
    return @config[:intercept_owner] ? true : false
  end

  def intercept_radius
    return (@config[:intercept_radius] ||
            PMD_AC::SUBSTITUTE_INTERCEPT_RADIUS).to_f
  end

  def armed?
    return @age >= @arm_delay
  end

  def trigger_due?
    return false if @trigger_delay == nil
    return @age >= @trigger_delay
  end

  def tick_due?
    return false if @tick_interval <= 0
    return @next_tick <= 0
  end

  def reset_tick
    @next_tick = @tick_interval
  end

  def expire(reason)
    return if @expired
    @expired = true
    @expire_reason = reason
  end

  def update
    return if @expired
    @age += 1
    @duration -= 1 if @duration > 0
    @next_tick -= 1 if @tick_interval > 0
    @scene.update_battle_object_logic(self) if @scene != nil && !@expired
    if @duration <= 0 && !@expired
      @scene.expire_battle_object(self, :duration)
    end
  end
end


#==============================================================================
# ■ Sprite_PMDBattleObject
#------------------------------------------------------------------------------
#  小型 Pixel Object。避免搶過 PMD Pokémon 的視覺主體。
#==============================================================================
class Sprite_PMDBattleObject < Sprite
  def initialize(viewport, object)
    super(viewport)
    @object = object
    @hp_sprite = Sprite.new(viewport)
    @hp_sprite.bitmap = Bitmap.new(PMD_AC::BATTLE_OBJECT_HP_BAR_WIDTH, 4)
    self.bitmap = Bitmap.new(30, 30)
    self.ox = 15
    self.oy = 15
    self.z = object.pixel_y.to_i + 2
    draw_object
    update
  end

  def object
    return @object
  end

  def dispose
    if @hp_sprite != nil
      if @hp_sprite.bitmap != nil && !@hp_sprite.bitmap.disposed?
        @hp_sprite.bitmap.dispose
      end
      @hp_sprite.dispose unless @hp_sprite.disposed?
    end
    self.bitmap.dispose if self.bitmap != nil && !self.bitmap.disposed?
    super
  end

  def update
    super
    self.x = @object.pixel_x.to_i
    self.y = @object.pixel_y.to_i
    self.z = @object.pixel_y.to_i + 2

    # Trap / Marker 尚未觸發時保持低存在感。
    if @object.kind == :trap || @object.kind == :delayed
      pulse = 110 + (Graphics.frame_count % 24)
      self.opacity = [pulse, 145].min
    else
      self.opacity = 255
    end
    update_hp_bar
  end

  def update_hp_bar
    @hp_sprite.visible = @object.targetable? && !@object.expired?
    return unless @hp_sprite.visible
    bmp = @hp_sprite.bitmap
    bmp.clear
    width = PMD_AC::BATTLE_OBJECT_HP_BAR_WIDTH
    bmp.fill_rect(0, 0, width, 4, Color.new(0, 0, 0, 190))
    inner = width - 2
    hp_w = inner * @object.hp / [@object.maxhp, 1].max
    bmp.fill_rect(1, 1, hp_w, PMD_AC::BATTLE_OBJECT_HP_BAR_HEIGHT,
                  Color.new(235, 220, 95, 235))
    @hp_sprite.x = self.x - width / 2
    @hp_sprite.y = self.y - 25
    @hp_sprite.z = self.z + 5
  end

  def draw_object
    bmp = self.bitmap
    bmp.clear
    case @object.style
    when :decoy
      bmp.fill_rect(11, 5, 8, 18, Color.new(235, 235, 225, 230))
      bmp.fill_rect(7, 10, 16, 8, Color.new(115, 205, 135, 245))
      bmp.fill_rect(12, 7, 6, 4, Color.new(250, 255, 245, 255))
      bmp.fill_rect(13, 23, 4, 4, Color.new(120, 85, 55, 240))
    when :trap
      bmp.fill_rect(5, 13, 20, 3, Color.new(230, 230, 220, 190))
      bmp.fill_rect(13, 5, 3, 20, Color.new(230, 230, 220, 190))
      bmp.fill_rect(8, 8, 4, 4, Color.new(165, 210, 115, 210))
      bmp.fill_rect(18, 18, 4, 4, Color.new(165, 210, 115, 210))
    when :bomb
      bmp.fill_rect(8, 9, 14, 14, Color.new(125, 55, 45, 230))
      bmp.fill_rect(10, 7, 10, 18, Color.new(225, 80, 45, 245))
      bmp.fill_rect(7, 11, 16, 10, Color.new(245, 125, 45, 235))
      bmp.fill_rect(13, 5, 5, 5, Color.new(255, 225, 105, 255))
    when :totem
      bmp.fill_rect(11, 5, 8, 21, Color.new(70, 125, 185, 240))
      bmp.fill_rect(7, 8, 16, 7, Color.new(115, 210, 235, 245))
      bmp.fill_rect(10, 10, 10, 3, Color.new(235, 255, 255, 255))
      bmp.fill_rect(8, 24, 14, 3, Color.new(80, 70, 55, 230))
    else # marker
      c1 = Color.new(250, 185, 80, 190)
      c2 = Color.new(255, 235, 150, 220)
      bmp.fill_rect(5, 5, 20, 2, c1)
      bmp.fill_rect(5, 23, 20, 2, c1)
      bmp.fill_rect(5, 5, 2, 20, c1)
      bmp.fill_rect(23, 5, 2, 20, c1)
      bmp.fill_rect(12, 12, 6, 6, c2)
    end
  end
end


#==============================================================================
# ■ Sprite_PMDChessUnit
#==============================================================================
class Sprite_PMDChessUnit < Sprite
  def initialize(viewport, unit)
    super(viewport)
    @unit = unit
    @last_action = nil
    @last_visual_action = nil
    @last_facing_dir = nil
    @frame_index = 0
    @frame_wait = 0
    @owns_bitmap = false
    @placeholder = false
    @bar_sprite = Sprite.new(viewport)
    @bar_sprite.bitmap = Bitmap.new(PMD_AC::UNIT_BAR_WIDTH,
                                    PMD_AC::UNIT_BAR_HEIGHT)
    @popup_sprite = Sprite.new(viewport)
    @popup_sprite.bitmap = Bitmap.new(80, 28)
    @skill_sprite = Sprite.new(viewport)
    @skill_sprite.bitmap = Bitmap.new(120, 28)
    @threat_sprite = Sprite.new(viewport)
    @threat_sprite.bitmap = Bitmap.new(36, 20)
    @last_threat_label = nil
    @ai_sprite = Sprite.new(viewport)
    @ai_sprite.bitmap = Bitmap.new(34, 16)
    @last_ai_label = nil
    @status_sprite = Sprite.new(viewport)
    @status_sprite.bitmap = Bitmap.new(104, 16)
    @last_status_label = nil
    self.zoom_x = PMD_AC::UNIT_SPRITE_SCALE
    self.zoom_y = PMD_AC::UNIT_SPRITE_SCALE
    @last_hp = -1
    @last_energy = -1
    @last_shield = -1
    @last_popup_frames = -1
    @last_skill_frames = -1
    @selected = false
    refresh_action_bitmap(true)
    update
  end

  def unit
    return @unit
  end

  def dispose
    dispose_owned_bitmap
    if @bar_sprite != nil
      @bar_sprite.bitmap.dispose if @bar_sprite.bitmap != nil && !@bar_sprite.bitmap.disposed?
      @bar_sprite.dispose unless @bar_sprite.disposed?
    end
    if @popup_sprite != nil
      @popup_sprite.bitmap.dispose if @popup_sprite.bitmap != nil && !@popup_sprite.bitmap.disposed?
      @popup_sprite.dispose unless @popup_sprite.disposed?
    end
    if @skill_sprite != nil
      @skill_sprite.bitmap.dispose if @skill_sprite.bitmap != nil && !@skill_sprite.bitmap.disposed?
      @skill_sprite.dispose unless @skill_sprite.disposed?
    end
    if @threat_sprite != nil
      @threat_sprite.bitmap.dispose if @threat_sprite.bitmap != nil && !@threat_sprite.bitmap.disposed?
      @threat_sprite.dispose unless @threat_sprite.disposed?
    end
    if @ai_sprite != nil
      @ai_sprite.bitmap.dispose if @ai_sprite.bitmap != nil && !@ai_sprite.bitmap.disposed?
      @ai_sprite.dispose unless @ai_sprite.disposed?
    end
    if @status_sprite != nil
      @status_sprite.bitmap.dispose if @status_sprite.bitmap != nil && !@status_sprite.bitmap.disposed?
      @status_sprite.dispose unless @status_sprite.disposed?
    end
    super
  end

  def update
    super
    if @last_action != @unit.action ||
       @last_visual_action != @unit.visual_action
      refresh_action_bitmap(false)
    end
    if @last_facing_dir != @unit.facing_dir
      @last_facing_dir = @unit.facing_dir
      setup_source_rect unless @placeholder || @action_data == nil
    end
    update_animation
    update_position
    update_bar
    update_popup
    update_skill_popup
    update_threat_debug
    update_ai_debug
    update_status_debug
    update_dead_opacity
    update_selection_color
  end

  def selected=(value)
    @selected = value ? true : false
  end

  def update_selection_color
    if @selected && !@unit.dead?
      pulse = 65 + (Graphics.frame_count % 24 - 12).abs * 5
      self.color.set(255, 230, 80, pulse)
    else
      self.color.set(0, 0, 0, 0)
    end
  end

  def dispose_owned_bitmap
    if @owns_bitmap && self.bitmap != nil && !self.bitmap.disposed?
      self.bitmap.dispose
    end
    @owns_bitmap = false
  end

  def refresh_action_bitmap(force)
    action = @unit.action
    visual_action = @unit.visual_action
    return if !force && @last_action == action &&
              @last_visual_action == visual_action
    @last_action = action
    @last_visual_action = visual_action
    @last_facing_dir = @unit.facing_dir
    @frame_index = 0
    @frame_wait = 0
    dispose_owned_bitmap

    data = PMD_AC.action_data(@unit.species, visual_action)
    if data != nil
      filename = data[:file]
      folder = PMD_AC::PMD_ROOT + @unit.species + "/"
      if filename != nil && PMD_AC.bitmap_exists?(folder, filename)
        begin
          self.bitmap = Cache.load_bitmap(folder, filename)
          @action_data = data
          @placeholder = false
          setup_source_rect
          return
        rescue
        end
      end
    end
    create_placeholder_bitmap
  end

  def create_placeholder_bitmap
    @placeholder = true
    @action_data = nil
    self.bitmap = Bitmap.new(52, 52)
    @owns_bitmap = true
    color = @unit.team == :ally ? Color.new(70, 160, 235) : Color.new(230, 95, 95)
    self.bitmap.fill_rect(4, 4, 44, 44, Color.new(20, 20, 20, 210))
    self.bitmap.fill_rect(7, 7, 38, 38, color)
    self.bitmap.font.size = 18
    self.bitmap.font.bold = true
    self.bitmap.font.color = Color.new(255, 255, 255)
    self.bitmap.draw_text(0, 11, 52, 24, @unit.mark, 1)
    self.src_rect.set(0, 0, 52, 52)
    self.ox = 26
    self.oy = 48
  end

  def setup_source_rect
    frame_w = @action_data[:frame_w].to_i
    frame_h = @action_data[:frame_h].to_i
    frame_w = self.bitmap.width if frame_w <= 0
    frame_h = self.bitmap.height if frame_h <= 0
    self.ox = frame_w / 2
    self.oy = frame_h
    row = PMD_AC.direction_row(@action_data, @unit.facing_dir)
    self.src_rect.set(@frame_index * frame_w, row * frame_h,
                      frame_w, frame_h)
  end

  def update_animation
    return if @placeholder
    return if @action_data == nil
    durations = @action_data[:durations]
    frames = @action_data[:frames].to_i
    frames = durations.size if frames <= 0 && durations != nil
    frame_w = @action_data[:frame_w].to_i
    frame_h = @action_data[:frame_h].to_i
    return if frames <= 0 || frame_w <= 0 || frame_h <= 0

    if @frame_wait > 0
      @frame_wait -= 1
      return
    end

    duration = 8
    if durations != nil && !durations.empty?
      duration = durations[@frame_index % durations.size].to_i
      duration = 1 if duration <= 0
    end
    # 移動速度越快，Walk 動畫越快；不改變攻擊與技能原始節奏。
    if @unit.visual_action == :walk
      speed = Math.sqrt(@unit.velocity_x * @unit.velocity_x +
                        @unit.velocity_y * @unit.velocity_y)
      duration = (duration * 1.75 / [speed, 0.75].max).round
      duration = PMD_AC.clamp(duration, 2, 10)
    end
    @frame_wait = duration
    @frame_index += 1
    if @frame_index >= frames
      if @action_data[:loop] == false
        @frame_index = frames - 1
      else
        @frame_index = 0
      end
    end
    row = PMD_AC.direction_row(@action_data, @unit.facing_dir)
    self.src_rect.set(@frame_index * frame_w, row * frame_h, frame_w, frame_h)
  end

  def update_position
    self.x = (@unit.pixel_x + @unit.visual_offset_x).to_i
    bounce = @unit.victory_bounce_offset
    self.y = (@unit.pixel_y + @unit.visual_offset_y + bounce).to_i
    # z 使用地面基準，不讓跳躍時圖層排序跟著來回變動。
    self.z = (@unit.pixel_y + @unit.visual_offset_y).to_i
    self.mirror = false
    if @unit.stun_frames > 0
      self.tone.set(40, 40, 40, 0)
    else
      self.tone.set(0, 0, 0, 0)
    end

    displayed_oy = self.oy * self.zoom_y
    @bar_sprite.x = self.x - PMD_AC::UNIT_BAR_WIDTH / 2
    @bar_sprite.y = (self.y - displayed_oy - 18).to_i
    @bar_sprite.z = self.z + 10
    @popup_sprite.x = self.x - 40
    @popup_sprite.y = (self.y - displayed_oy - 42).to_i
    @popup_sprite.z = self.z + 20
    @skill_sprite.x = self.x - 60
    @skill_sprite.y = (self.y - displayed_oy - 68).to_i
    @skill_sprite.z = self.z + 25
    @threat_sprite.x = self.x - 18
    @threat_sprite.y = (self.y - displayed_oy - 88).to_i
    @threat_sprite.z = self.z + 28
    # v0.8.2：Debug 標籤不得壓住 PMD 角色圖。
    # AI 若手動開啟，放在 HP Bar 上方；Status 再往上一層。
    @ai_sprite.x = self.x - 17
    @ai_sprite.y = @bar_sprite.y - 16
    @ai_sprite.z = self.z + 11
    @status_sprite.x = self.x - 52
    @status_sprite.y = @bar_sprite.y - 32
    @status_sprite.z = self.z + 12
  end

  def update_bar
    return if @last_hp == @unit.hp && @last_energy == @unit.energy &&
              @last_shield == @unit.shield
    @last_hp = @unit.hp
    @last_energy = @unit.energy
    @last_shield = @unit.shield
    bmp = @bar_sprite.bitmap
    bmp.clear
    bmp.fill_rect(0, 0,
                  PMD_AC::UNIT_BAR_WIDTH,
                  PMD_AC::UNIT_BAR_HEIGHT,
                  Color.new(0, 0, 0, 210))

    inner = PMD_AC::UNIT_BAR_INNER_WIDTH
    thick = PMD_AC::UNIT_BAR_THICKNESS
    hp_w = inner * @unit.hp / @unit.maxhp
    en_w = inner * @unit.energy / PMD_AC::MAX_ENERGY
    shield_w = inner * [@unit.shield, @unit.maxhp].min / @unit.maxhp

    # HP 與 Energy 都是 2px。
    bmp.fill_rect(2, 2, hp_w, thick, Color.new(80, 220, 90))
    # Shield 只佔 HP 上緣 1px，避免細條被整片藍色蓋掉。
    bmp.fill_rect(2, 2, shield_w, 1,
                  Color.new(110, 205, 255)) if shield_w > 0
    bmp.fill_rect(2, 6, en_w, thick, Color.new(80, 170, 255))
  end

  def update_popup
    frames = @unit.damage_popup_frames
    return if @last_popup_frames == frames
    old_frames = @last_popup_frames
    @last_popup_frames = frames
    if frames > 0 && (old_frames <= 0 || frames > old_frames)
      self.flash(Color.new(255, 255, 255, 185), 6)
    end
    bmp = @popup_sprite.bitmap
    bmp.clear
    return if frames <= 0
    bmp.font.size = 20
    bmp.font.bold = true
    if @unit.last_damage_critical
      bmp.font.size = 16
      bmp.font.color = Color.new(255, 220, 90)
      bmp.draw_text(0, 0, 80, 24,
                    "CRIT -" + @unit.last_damage.to_s, 1)
    else
      bmp.font.color = Color.new(255, 245, 210)
      bmp.draw_text(0, 0, 80, 24, "-" + @unit.last_damage.to_s, 1)
    end
    @popup_sprite.opacity = PMD_AC.clamp(frames * 10, 0, 255)
  end

  def update_skill_popup
    frames = @unit.skill_popup_frames
    return if @last_skill_frames == frames
    @last_skill_frames = frames
    bmp = @skill_sprite.bitmap
    bmp.clear
    return if frames <= 0
    bmp.fill_rect(4, 3, 112, 22, Color.new(0, 0, 0, 170))
    bmp.font.size = 16
    bmp.font.bold = true
    bmp.font.color = Color.new(255, 235, 120)
    bmp.draw_text(0, 1, 120, 24, @unit.skill_name, 1)
    @skill_sprite.opacity = PMD_AC.clamp(frames * 12, 0, 255)
  end

  def update_threat_debug
    return if @threat_sprite == nil
    unless PMD_AC::SHOW_THREAT_DEBUG
      @threat_sprite.visible = false
      return
    end
    label = @unit.threat_debug_label
    if label != @last_threat_label
      @last_threat_label = label
      bmp = @threat_sprite.bitmap
      bmp.clear
      if label != ""
        bmp.font.size = 18
        bmp.font.bold = true
        bmp.font.color = label == "!!" ? Color.new(255, 110, 80) :
                                         Color.new(255, 225, 90)
        bmp.draw_text(0, 0, 36, 20, label, 1)
      end
    end
    @threat_sprite.visible = (label != "" && !@unit.dead?)
  end

  def update_ai_debug
    return if @ai_sprite == nil
    unless PMD_AC::SHOW_AI_DEBUG
      @ai_sprite.visible = false
      return
    end
    label = @unit.ai_debug_label
    if label != @last_ai_label
      @last_ai_label = label
      bmp = @ai_sprite.bitmap
      bmp.clear
      bmp.fill_rect(2, 1, 30, 14, Color.new(0, 0, 0, 150))
      bmp.font.size = 12
      bmp.font.bold = true
      bmp.font.color = Color.new(190, 225, 255)
      bmp.draw_text(0, 0, 34, 15, label, 1)
    end
    @ai_sprite.visible = !@unit.dead?
  end

  def update_status_debug
    return if @status_sprite == nil
    unless PMD_AC::SHOW_STATUS_DEBUG
      @status_sprite.visible = false
      return
    end
    label = @unit.status_debug_label
    if label != @last_status_label
      @last_status_label = label
      bmp = @status_sprite.bitmap
      bmp.clear
      if label != ""
        bmp.fill_rect(1, 1, 102, 14, Color.new(0, 0, 0, 145))
        bmp.font.size = 11
        bmp.font.bold = true
        bmp.font.color = Color.new(220, 245, 255)
        bmp.draw_text(0, 0, 104, 15, label, 1)
      end
    end
    @status_sprite.visible = (label != "" && !@unit.dead?)
  end

  def update_dead_opacity
    if @unit.dead?
      self.opacity -= 4 if self.opacity > 70
      @bar_sprite.opacity = self.opacity
      @skill_sprite.opacity = self.opacity if @unit.skill_popup_frames <= 0
      @ai_sprite.opacity = self.opacity if @ai_sprite != nil
      @status_sprite.opacity = self.opacity if @status_sprite != nil
    end
  end
end

#==============================================================================
# ■ Sprite_PMDDeployCursor
#==============================================================================
class Sprite_PMDDeployCursor < Sprite
  attr_reader :cell_x
  attr_reader :cell_y

  def initialize(viewport)
    super(viewport)
    self.bitmap = Bitmap.new(PMD_AC::CELL_W, PMD_AC::CELL_H)
    @cell_x = 0
    @cell_y = 2
    @selected_mode = false
    self.z = 8500
    redraw
    refresh_position
  end

  def dispose
    self.bitmap.dispose if self.bitmap != nil && !self.bitmap.disposed?
    super
  end

  def move_to(x, y)
    @cell_x = PMD_AC.clamp(x.to_i, PMD_AC::ALLY_DEPLOY_MIN_X,
                           PMD_AC::ALLY_DEPLOY_MAX_X)
    @cell_y = PMD_AC.clamp(y.to_i, 0, PMD_AC::GRID_ROWS - 1)
    refresh_position
  end

  def selected_mode=(value)
    value = value ? true : false
    return if @selected_mode == value
    @selected_mode = value
    redraw
  end

  def update
    super
    self.opacity = 170 + (Graphics.frame_count % 30 - 15).abs * 5
  end

  def refresh_position
    self.x = PMD_AC::GRID_X + @cell_x * PMD_AC::CELL_W
    self.y = PMD_AC::GRID_Y + @cell_y * PMD_AC::CELL_H
  end

  def redraw
    bmp = self.bitmap
    bmp.clear
    color = @selected_mode ? Color.new(255, 225, 70, 255) :
                             Color.new(90, 220, 255, 255)
    bmp.fill_rect(0, 0, PMD_AC::CELL_W, 3, color)
    bmp.fill_rect(0, PMD_AC::CELL_H - 3, PMD_AC::CELL_W, 3, color)
    bmp.fill_rect(0, 0, 3, PMD_AC::CELL_H, color)
    bmp.fill_rect(PMD_AC::CELL_W - 3, 0, 3, PMD_AC::CELL_H, color)
  end
end

#==============================================================================
# ■ Sprite_PMDChessEffect
#==============================================================================
class Sprite_PMDChessEffect < Sprite
  attr_reader :finished

  def initialize(viewport, x, y, type, delay = 0)
    super(viewport)
    @type = type
    @delay = delay
    @life = type == :miss ? 22 : (cast_effect? ? 32 : 28)
    @finished = false
    self.bitmap = Bitmap.new(64, 64)
    self.ox = 32
    self.oy = 32
    self.x = x.to_i
    self.y = y.to_i - 24
    self.z = 9000
    self.zoom_x = PMD_AC::EFFECT_SPRITE_SCALE
    self.zoom_y = PMD_AC::EFFECT_SPRITE_SCALE
    draw_effect
    self.visible = (@delay <= 0)
  end

  def cast_effect?
    return [:cast_seed, :cast_fire, :cast_water, :cast_web,
            :cast_electric, :cast_slash].include?(@type)
  end

  def draw_effect
    bmp = self.bitmap
    bmp.clear
    case @type
    when :drain, :seed
      c = Color.new(90, 255, 130, 220)
      bmp.fill_rect(8, 8, 48, 3, c)
      bmp.fill_rect(8, 53, 48, 3, c)
      bmp.fill_rect(8, 8, 3, 48, c)
      bmp.fill_rect(53, 8, 3, 48, c)
      bmp.fill_rect(27, 23, 10, 18, Color.new(195, 255, 145, 235))
    when :aoe, :fire
      c = Color.new(255, 125, 55, 225)
      bmp.fill_rect(7, 27, 50, 10, c)
      bmp.fill_rect(27, 7, 10, 50, c)
      bmp.fill_rect(16, 16, 32, 32, Color.new(255, 190, 70, 120))
    when :stun, :chain, :electric
      c = Color.new(255, 235, 70, 235)
      bmp.fill_rect(29, 3, 6, 20, c)
      bmp.fill_rect(20, 20, 16, 6, c)
      bmp.fill_rect(29, 23, 6, 18, c)
      bmp.fill_rect(29, 38, 17, 6, c)
      bmp.fill_rect(41, 41, 6, 20, c)
    when :water
      bmp.fill_rect(9, 27, 46, 10, Color.new(75, 180, 255, 210))
      bmp.fill_rect(18, 20, 30, 24, Color.new(115, 220, 255, 140))
      bmp.fill_rect(25, 24, 14, 16, Color.new(235, 255, 255, 230))
    when :web
      c = Color.new(235, 245, 220, 220)
      bmp.fill_rect(30, 5, 3, 54, c)
      bmp.fill_rect(5, 30, 54, 3, c)
      bmp.fill_rect(13, 13, 38, 2, c)
      bmp.fill_rect(13, 49, 38, 2, c)
      bmp.fill_rect(13, 13, 2, 38, c)
      bmp.fill_rect(49, 13, 2, 38, c)
    when :slash
      c = Color.new(250, 250, 255, 235)
      for i in 0...5
        bmp.fill_rect(10 + i * 8, 47 - i * 8, 18, 3, c)
      end
    when :heal, :regen, :cleanse
      c = Color.new(100, 255, 150, 230)
      bmp.fill_rect(28, 10, 8, 44, c)
      bmp.fill_rect(10, 28, 44, 8, c)
    when :shield
      c = Color.new(110, 205, 255, 225)
      bmp.fill_rect(10, 8, 44, 3, c)
      bmp.fill_rect(8, 10, 3, 36, c)
      bmp.fill_rect(53, 10, 3, 36, c)
      bmp.fill_rect(14, 49, 36, 3, c)
    when :poison
      c = Color.new(155, 90, 220, 225)
      bmp.fill_rect(17, 17, 30, 30, c)
      bmp.fill_rect(24, 10, 16, 44, Color.new(110, 60, 180, 150))
    when :burn
      c = Color.new(255, 110, 45, 230)
      bmp.fill_rect(20, 17, 24, 34, c)
      bmp.fill_rect(26, 9, 12, 42, Color.new(255, 200, 75, 170))
    when :slow, :atk_down, :def_down, :dispel
      c = Color.new(180, 190, 245, 225)
      bmp.fill_rect(8, 29, 48, 5, c)
      bmp.fill_rect(29, 8, 5, 48, c)
    when :taunt
      c = Color.new(255, 90, 90, 235)
      bmp.fill_rect(10, 10, 44, 4, c)
      bmp.fill_rect(10, 50, 44, 4, c)
      bmp.fill_rect(10, 10, 4, 44, c)
      bmp.fill_rect(50, 10, 4, 44, c)
    when :impact
      c = Color.new(255, 245, 215, 235)
      bmp.fill_rect(6, 29, 52, 6, c)
      bmp.fill_rect(29, 6, 6, 52, c)
      bmp.fill_rect(15, 15, 34, 34, Color.new(255, 190, 90, 105))
    when :cast_seed, :cast_fire, :cast_water, :cast_web, :cast_electric, :cast_slash
      c = cast_color
      bmp.fill_rect(6, 6, 52, 3, c)
      bmp.fill_rect(6, 55, 52, 3, c)
      bmp.fill_rect(6, 6, 3, 52, c)
      bmp.fill_rect(55, 6, 3, 52, c)
      bmp.fill_rect(15, 15, 34, 2, Color.new(c.red, c.green, c.blue, 145))
      bmp.fill_rect(15, 47, 34, 2, Color.new(c.red, c.green, c.blue, 145))
    when :miss
      bmp.font.size = 16
      bmp.font.bold = true
      bmp.font.color = Color.new(220, 230, 240)
      bmp.draw_text(0, 18, 64, 24, "MISS", 1)
    else
      c = Color.new(245, 245, 255, 230)
      bmp.fill_rect(8, 28, 48, 7, c)
      bmp.fill_rect(28, 8, 7, 48, c)
    end
  end

  def cast_color
    case @type
    when :cast_seed then return Color.new(95, 245, 120, 220)
    when :cast_fire then return Color.new(255, 120, 50, 220)
    when :cast_water then return Color.new(70, 185, 255, 220)
    when :cast_web then return Color.new(235, 245, 220, 220)
    when :cast_electric then return Color.new(255, 230, 65, 225)
    else return Color.new(245, 245, 255, 220)
    end
  end

  def update
    super
    return if @finished
    if @delay > 0
      @delay -= 1
      self.visible = true if @delay <= 0
      return
    end
    @life -= 1
    if @type == :miss
      self.y -= 1
    end
    # v0.9.1.5：舊 Effect 僅作 MISS / fallback。
    # 禁止任何自動 zoom，避免舊 64x64 測試圖重新膨脹。
    self.opacity = PMD_AC.clamp(@life * 12, 0, 255)
    if @life <= 0
      @finished = true
      self.visible = false
    end
  end

  def dispose
    self.bitmap.dispose if self.bitmap != nil && !self.bitmap.disposed?
    super
  end
end

#==============================================================================
# ■ Sprite_PMDProjectile
#------------------------------------------------------------------------------
# 原型用邏輯投射物。正式 VFX 之後可替換圖片，但命中骨架可保留。
#==============================================================================
class Sprite_PMDProjectile < Sprite
  attr_reader :finished
  attr_reader :user
  attr_reader :target
  attr_reader :kind
  attr_reader :power
  attr_reader :impact_x
  attr_reader :impact_y
  attr_reader :effect_type
  attr_reader :style
  attr_reader :radius
  attr_reader :tracking_level
  attr_reader :attack_modifier

  def initialize(viewport, scene, id, user, target, kind, power, effect_type,
                 tracking_level = nil, attack_modifier = nil)
    super(viewport)
    @scene = scene
    @id = id
    @user = user
    @target = target
    @kind = kind
    @power = power
    @effect_type = effect_type
    @style = @scene.projectile_style(user, kind, effect_type)
    @tracking_level = tracking_level || :perfect
    @attack_modifier = attack_modifier
    @evade_triggered = false
    @evade_target = nil
    source_anchor = @scene.effect_anchor_xy(user, true)
    target_anchor = @scene.effect_anchor_xy(target, false)
    @x_f = source_anchor[0].to_f
    @y_f = source_anchor[1].to_f
    @target_x = target_anchor[0].to_f
    @target_y = target_anchor[1].to_f
    hdx = @target_x - @x_f
    hdy = @target_y - @y_f
    hlen = Math.sqrt(hdx * hdx + hdy * hdy)
    if hlen <= 0.001
      @heading_x = user.team == :ally ? 1.0 : -1.0
      @heading_y = 0.0
    else
      @heading_x = hdx / hlen
      @heading_y = hdy / hlen
    end
    @scene.log_event(:projectile_track,
      user.log_name + " -> " + target.log_name +
      " level=" + @tracking_level.to_s)
    @scene.log_event(:vfx_anchor,
      user.log_name + " PROJECTILE style=" + @style.to_s +
      " src=(" + @x_f.round.to_s + "," + @y_f.round.to_s + ")" +
      " dst=(" + @target_x.round.to_s + "," + @target_y.round.to_s + ")")
    @impact_x = @target_x
    @impact_y = @target_y
    @speed = PMD_AC::PROJECTILE_SPEED
    @radius = PMD_AC::PROJECTILE_RADIUS
    @life = PMD_AC::PROJECTILE_LIFE

    # v0.10.1：避免 Turn-limited Homing 射過目標後無限繞圈。
    @closest_target_distance = hlen
    @entered_orbit_break_radius = false
    @overshoot_frames = 0
    @finished = false
    self.bitmap = Bitmap.new(28, 28)
    self.ox = 14
    self.oy = 14
    self.z = 9200
    self.zoom_x = PMD_AC::PROJECTILE_SPRITE_SCALE
    self.zoom_y = PMD_AC::PROJECTILE_SPRITE_SCALE
    draw_projectile
    update_screen_position
  end

  def effect_type
    return @effect_type
  end

  def draw_projectile
    bmp = self.bitmap
    bmp.clear
    case @style
    when :electric
      # 外暈：深金色、低 Alpha
      glow = Color.new(205, 155, 0, 75)
      bmp.fill_rect(2, 7, 10, 8, glow)
      bmp.fill_rect(8, 10, 10, 8, glow)
      bmp.fill_rect(15, 13, 11, 8, glow)

      # 主體：亮黃閃電
      main = Color.new(255, 210, 25, 245)
      bmp.fill_rect(3, 9, 8, 4, main)
      bmp.fill_rect(9, 12, 8, 4, main)
      bmp.fill_rect(16, 15, 9, 4, main)

      # 亮芯：近白黃色
      core = Color.new(255, 255, 210, 255)
      bmp.fill_rect(5, 10, 5, 2, core)
      bmp.fill_rect(11, 13, 5, 2, core)
      bmp.fill_rect(18, 16, 5, 2, core)

      # 少量像素火花，維持 pixel-art 感
      bmp.fill_rect(3, 5, 2, 2, Color.new(255, 235, 70, 180))
      bmp.fill_rect(21, 9, 2, 2, Color.new(255, 255, 210, 170))

    when :water
      # 深藍外暈 → 青藍主體 → 白色高光
      bmp.fill_rect(2, 9, 23, 11, Color.new(25, 95, 205, 75))
      bmp.fill_rect(6, 10, 19, 9, Color.new(45, 175, 245, 230))
      bmp.fill_rect(12, 11, 12, 6, Color.new(105, 225, 255, 250))
      bmp.fill_rect(18, 12, 6, 3, Color.new(235, 255, 255, 255))

    when :fire
      # 暗紅外暈 → 橘紅 → 黃白芯
      bmp.fill_rect(2, 8, 23, 13, Color.new(175, 40, 15, 75))
      bmp.fill_rect(6, 9, 19, 11, Color.new(255, 85, 25, 230))
      bmp.fill_rect(12, 10, 12, 8, Color.new(255, 155, 35, 250))
      bmp.fill_rect(18, 12, 6, 4, Color.new(255, 245, 150, 255))

    when :seed
      bmp.fill_rect(3, 9, 22, 11, Color.new(30, 105, 45, 70))
      bmp.fill_rect(6, 10, 18, 9, Color.new(65, 180, 75, 230))
      bmp.fill_rect(12, 11, 12, 7, Color.new(130, 235, 100, 250))
      bmp.fill_rect(18, 13, 5, 3, Color.new(235, 255, 185, 255))

    when :web
      # 半透明灰白外層 + 白色絲芯
      glow = Color.new(185, 200, 180, 80)
      core = Color.new(248, 252, 240, 245)
      bmp.fill_rect(4, 12, 21, 4, glow)
      bmp.fill_rect(12, 4, 4, 21, glow)
      bmp.fill_rect(6, 13, 19, 2, core)
      bmp.fill_rect(13, 6, 2, 19, core)
      bmp.fill_rect(8, 8, 2, 13, Color.new(225, 238, 215, 220))
      bmp.fill_rect(19, 8, 2, 13, Color.new(225, 238, 215, 220))

    else
      bmp.fill_rect(2, 9, 23, 11, Color.new(55, 115, 190, 70))
      bmp.fill_rect(6, 10, 19, 9, Color.new(110, 195, 245, 225))
      bmp.fill_rect(12, 11, 12, 6, Color.new(190, 235, 255, 245))
      bmp.fill_rect(18, 12, 6, 3, Color.new(255, 255, 255, 255))
    end
  end

  def update
    super
    return if @finished
    @life -= 1
    if @life <= 0
      finish_without_hit
      return
    end

    if @target != nil && @target.alive?
      # 進入近距離時，具有 Active Evade 的目標會嘗試側閃一次。
      if !@evade_triggered
        current_distance = PMD_AC.distance(@x_f, @y_f,
                                           @target.pixel_x, @target.pixel_y)
        if current_distance <= PMD_AC::ACTIVE_EVADE_TRIGGER_DISTANCE
          if @target.try_active_evade(@user, :projectile)
            @evade_triggered = true
            @evade_target = @target
          end
        end
      end

      if @tracking_level != :none
        anchor = @scene.effect_anchor_xy(@target, false)
        @target_x = anchor[0].to_f
        @target_y = anchor[1].to_f
      end
    end

    old_x = @x_f
    old_y = @y_f

    desired_x = @target_x - @x_f
    desired_y = @target_y - @y_f
    desired_len = Math.sqrt(desired_x * desired_x + desired_y * desired_y)

    # Weak / Strong Tracking 只做「飛行途中修正」，不做 Boomerang。
    if [:weak, :strong].include?(@tracking_level) && desired_len > 0.001
      @entered_orbit_break_radius = true if
        desired_len <= PMD_AC::PROJECTILE_ORBIT_BREAK_RADIUS

      if desired_len < @closest_target_distance
        @closest_target_distance = desired_len
        @overshoot_frames = 0
      elsif @entered_orbit_break_radius &&
            desired_len > @closest_target_distance +
                          PMD_AC::PROJECTILE_OVERSHOOT_TOLERANCE
        @overshoot_frames += 1
      end

      desired_nx = desired_x / desired_len
      desired_ny = desired_y / desired_len
      dot = @heading_x * desired_nx + @heading_y * desired_ny
      dot = PMD_AC.clamp(dot, -1.0, 1.0)
      reacquire_angle = Math.acos(dot) * 180.0 / Math::PI

      if @entered_orbit_break_radius &&
         (@overshoot_frames >= PMD_AC::PROJECTILE_OVERSHOOT_FRAMES ||
          reacquire_angle >= PMD_AC::PROJECTILE_MAX_REACQUIRE_ANGLE)
        finish_without_hit(:overshoot)
        return
      end
    end

    if @tracking_level == :perfect
      if desired_len > 0.001
        @heading_x = desired_x / desired_len
        @heading_y = desired_y / desired_len
      end
    elsif @tracking_level != :none && desired_len > 0.001
      desired_angle = Math.atan2(desired_y, desired_x)
      current_angle = Math.atan2(@heading_y, @heading_x)
      diff = desired_angle - current_angle
      while diff > Math::PI
        diff -= Math::PI * 2.0
      end
      while diff < -Math::PI
        diff += Math::PI * 2.0
      end
      max_deg = PMD_AC::PROJECTILE_TRACKING_TURN_RATE[@tracking_level] || 0.0
      max_turn = max_deg * Math::PI / 180.0
      diff = PMD_AC.clamp(diff, -max_turn, max_turn)
      current_angle += diff
      @heading_x = Math.cos(current_angle)
      @heading_y = Math.sin(current_angle)
    end

    @x_f += @heading_x * @speed
    @y_f += @heading_y * @speed
    update_screen_position
    self.angle = -Math.atan2(@heading_y, @heading_x) * 180.0 / Math::PI

    if @target != nil && @target.alive?
      interceptor = @scene.projectile_interceptor_for(
        self, old_x, old_y, @x_f, @y_f)
      if interceptor != nil
        @scene.log_event(:intercept, interceptor.log_name +
                         " INTERCEPT projectile from " + @user.log_name +
                         " originally->" + @target.log_name)
        @target = interceptor
        hit(interceptor.pixel_x, interceptor.pixel_y)
        return
      end

      radius = @target.collision_radius + @radius
      if @scene.segment_circle_hit?(old_x, old_y, @x_f, @y_f,
                                    @target.pixel_x, @target.pixel_y, radius)
        hit(@target.pixel_x, @target.pixel_y)
        return
      end
    elsif PMD_AC.distance(@x_f, @y_f, @target_x, @target_y) <= @speed
      hit(@target_x, @target_y)
      return
    end
  end

  def update_screen_position
    self.x = @x_f.to_i
    self.y = @y_f.to_i
  end

  def hit(x, y)
    return if @finished
    @impact_x = x.to_f
    @impact_y = y.to_f
    @finished = true
    self.visible = false
    if @evade_triggered && @evade_target == @target
      @scene.log_event(:evade_fail,
                       @target.log_name + " projectile caught by " +
                       @user.log_name + " tracking=" +
                       @tracking_level.to_s)
    end
    @scene.add_vfx_impact_xy(@impact_x, @impact_y, @style) if @scene != nil
    @scene.resolve_projectile(self)
  end

  def finish_without_hit(reason = :life)
    return if @finished
    @finished = true
    self.visible = false
    if @scene != nil && @target != nil && @target.alive?
      @scene.log_event(:projectile_lost,
                       @user.log_name + " -> " + @target.log_name +
                       " tracking=" + @tracking_level.to_s +
                       " reason=" + reason.to_s)
      if @evade_triggered && @evade_target == @target
        @scene.log_event(:evade_success,
                         @target.log_name + " projectile avoided " +
                         @user.log_name + " tracking=" +
                         @tracking_level.to_s)
      end
      @user.register_miss(@target)
    end
  end

  def dispose
    self.bitmap.dispose if self.bitmap != nil && !self.bitmap.disposed?
    super
  end
end

#==============================================================================
# ■ Sprite_PMDLinkEffect
#------------------------------------------------------------------------------
# 連鎖／光束使用的短命連線。只負責顯示，不參與命中判定。
#==============================================================================
class Sprite_PMDLinkEffect < Sprite
  attr_reader :finished

  def initialize(viewport, x1, y1, x2, y2, type = :electric, delay = 0)
    super(viewport)
    @delay = delay
    @life = 18
    @finished = false
    self.bitmap = Bitmap.new(32, 8)
    self.ox = 0
    self.oy = 4
    self.x = x1.to_i
    self.y = y1.to_i
    self.z = 9250
    draw_link(type)
    dx = x2 - x1
    dy = y2 - y1
    length = Math.sqrt(dx * dx + dy * dy)
    self.zoom_x = [length / 32.0, 0.1].max
    self.zoom_y = PMD_AC::LINK_EFFECT_THICKNESS_SCALE
    self.angle = -Math.atan2(dy, dx) * 180.0 / Math::PI
    self.visible = (@delay <= 0)
  end

  def draw_link(type)
    color = case type
            when :electric then Color.new(255, 230, 65, 235)
            when :web then Color.new(235, 245, 220, 230)
            when :seed then Color.new(105, 235, 115, 230)
            when :fire then Color.new(255, 125, 55, 230)
            else Color.new(150, 220, 255, 225)
            end
    self.bitmap.fill_rect(0, 2, 32, 4, Color.new(color.red, color.green, color.blue, 90))
    self.bitmap.fill_rect(0, 3, 32, 2, color)
  end

  def update
    super
    return if @finished
    if @delay > 0
      @delay -= 1
      self.visible = true if @delay <= 0
      return
    end
    @life -= 1
    self.opacity = PMD_AC.clamp(@life * 15, 0, 255)
    self.zoom_y = PMD_AC::LINK_EFFECT_THICKNESS_SCALE *
                  (1.0 + (Graphics.frame_count % 4) * 0.08)
    if @life <= 0
      @finished = true
      self.visible = false
    end
  end

  def dispose
    self.bitmap.dispose if self.bitmap != nil && !self.bitmap.disposed?
    super
  end
end

#==============================================================================
# ■ Sprite_PMDArenaBeam
#------------------------------------------------------------------------------
# v0.8.4：窄幅像素 Beam。只負責視覺，不拿 Sprite 邊界做命中判定。
#==============================================================================
class Sprite_PMDArenaBeam < Sprite
  attr_reader :finished

  def initialize(viewport, source, target, style = :light,
                 life = PMD_AC::BEAM_DEFAULT_LIFE,
                 width = PMD_AC::BEAM_DEFAULT_WIDTH)
    super(viewport)
    @source = source
    @target = target
    @style = style
    @life = [life.to_i, 1].max
    @max_life = @life
    @beam_width = [width.to_f, 2.0].max
    @finished = false
    self.bitmap = Bitmap.new(32, 12)
    self.ox = 0
    self.oy = 6
    self.z = 9240
    draw_beam
    update_geometry
  end

  def beam_point(obj, source_side)
    if obj.is_a?(Array)
      return [obj[0].to_f, obj[1].to_f]
    end
    return [0.0, 0.0] if obj == nil
    return [obj.visual_center_x.to_f, obj.visual_center_y.to_f]
  end

  def source_alive?
    return true if @source.is_a?(Array)
    return @source != nil && @source.alive?
  end

  def target_alive?
    return true if @target.is_a?(Array)
    return @target != nil && @target.alive?
  end

  def set_fixed_target(x, y)
    @target = [x.to_f, y.to_f]
  end

  def current_points
    p1 = beam_point(@source, true)
    p2 = beam_point(@target, false)
    return [p1[0], p1[1], p2[0], p2[1]]
  end

  def draw_beam
    bmp = self.bitmap
    bmp.clear
    halo, edge, body, core, hot = beam_colors

    # 參考 pixel laser 的層次：低透明外暈 → 外色 → 主體 → 亮芯 → 最亮中心。
    # 使用離散像素階梯，不做 anti-alias，維持 VX / PMD 的 pixel-art 質感。
    bmp.fill_rect(0, 0, 32, 12, halo)
    bmp.fill_rect(0, 1, 32, 10, edge)
    bmp.fill_rect(0, 3, 32, 6, body)
    bmp.fill_rect(0, 4, 32, 4, core)
    bmp.fill_rect(0, 5, 32, 2, hot)

    # 細小高亮節點，不改變整體 Beam 寬度。
    for x in [4, 12, 20, 28]
      bmp.fill_rect(x, 4, 2, 1, Color.new(hot.red, hot.green, hot.blue, 210))
      bmp.fill_rect(x + 1, 7, 2, 1, Color.new(core.red, core.green, core.blue, 150))
    end
  end

  def beam_colors
    case @style
    when :fire
      return [Color.new(120, 20, 5, 35),
              Color.new(185, 45, 15, 90),
              Color.new(255, 90, 25, 225),
              Color.new(255, 175, 55, 250),
              Color.new(255, 250, 185, 255)]
    when :water
      return [Color.new(20, 65, 170, 35),
              Color.new(25, 105, 220, 90),
              Color.new(55, 180, 255, 225),
              Color.new(135, 230, 255, 250),
              Color.new(245, 255, 255, 255)]
    when :electric
      return [Color.new(135, 95, 0, 30),
              Color.new(205, 155, 0, 85),
              Color.new(255, 215, 30, 230),
              Color.new(255, 245, 95, 250),
              Color.new(255, 255, 225, 255)]
    when :web
      return [Color.new(105, 120, 100, 25),
              Color.new(160, 175, 150, 70),
              Color.new(220, 235, 210, 210),
              Color.new(242, 248, 235, 245),
              Color.new(255, 255, 250, 255)]
    else
      return [Color.new(45, 80, 165, 30),
              Color.new(90, 135, 225, 80),
              Color.new(145, 205, 255, 220),
              Color.new(210, 240, 255, 248),
              Color.new(255, 255, 255, 255)]
    end
  end

  def update_geometry
    points = current_points
    x1, y1, x2, y2 = points
    dx = x2 - x1
    dy = y2 - y1
    length = Math.sqrt(dx * dx + dy * dy)
    self.x = x1.to_i
    self.y = y1.to_i
    self.zoom_x = [length / 32.0, 0.01].max
    self.zoom_y = @beam_width / 12.0
    self.angle = -Math.atan2(dy, dx) * 180.0 / Math::PI
  end

  def update
    super
    return if @finished
    unless source_alive? && target_alive?
      @finished = true
      self.visible = false
      return
    end
    @life -= 1
    update_geometry
    # 小幅亮度脈衝，不改 Beam 實際寬度與命中資料。
    pulse = Graphics.frame_count % 4
    self.opacity = pulse == 0 ? 220 : 255
    if @life <= 0
      @finished = true
      self.visible = false
    end
  end

  def dispose
    self.bitmap.dispose if self.bitmap != nil && !self.bitmap.disposed?
    super
  end
end

#==============================================================================
# ■ Sprite_PMDArenaColumn
#------------------------------------------------------------------------------
# 水柱／光柱等垂直型效果。低寬度、短生命，避免遮住整隻角色。
#==============================================================================
class Sprite_PMDArenaColumn < Sprite
  attr_reader :finished

  def initialize(viewport, target, style = :water, life = 26)
    super(viewport)
    @target = target
    @style = style
    @life = [life.to_i, 1].max
    @max_life = @life
    @finished = false
    self.bitmap = Bitmap.new(36, 72)
    self.ox = 18
    self.oy = 64
    self.z = 9230
    draw_column
    update_position
  end

  def draw_column
    bmp = self.bitmap
    bmp.clear
    if @style == :fire
      outer = Color.new(220, 65, 25, 90)
      mid = Color.new(255, 125, 35, 215)
      core = Color.new(255, 235, 120, 245)
    elsif @style == :light
      outer = Color.new(120, 170, 255, 80)
      mid = Color.new(185, 220, 255, 210)
      core = Color.new(255, 255, 255, 250)
    else
      outer = Color.new(40, 120, 225, 80)
      mid = Color.new(65, 190, 255, 210)
      core = Color.new(225, 250, 255, 250)
    end
    bmp.fill_rect(10, 4, 16, 62, outer)
    bmp.fill_rect(13, 2, 10, 66, mid)
    bmp.fill_rect(16, 0, 4, 68, core)
    for y in [8, 20, 34, 48, 60]
      bmp.fill_rect(7, y, 5, 3, Color.new(mid.red, mid.green, mid.blue, 155))
      bmp.fill_rect(24, y + 4, 5, 3, Color.new(core.red, core.green, core.blue, 130))
    end
  end

  def update_position
    return if @target == nil
    self.x = @target.pixel_x.to_i
    self.y = @target.pixel_y.to_i + 4
  end

  def update
    super
    return if @finished
    if @target == nil || @target.dead?
      @finished = true
      self.visible = false
      return
    end
    @life -= 1
    update_position
    self.opacity = PMD_AC.clamp(@life * 14, 0, 255)
    if @life <= 0
      @finished = true
      self.visible = false
    end
  end

  def dispose
    self.bitmap.dispose if self.bitmap != nil && !self.bitmap.disposed?
    super
  end
end

#==============================================================================
# ■ Sprite_PMDSustainedBeam
#==============================================================================
class Sprite_PMDSustainedBeam < Sprite_PMDArenaBeam
  def initialize(viewport, scene, user, target, data)
    @scene = scene
    @user = user
    @data = data
    @tick_interval = [(data[:tick_interval] || PMD_AC::BEAM_SUSTAIN_TICK).to_i, 1].max
    @tick = 1
    style = data[:beam_style] || user.projectile_style
    life = data[:duration] || 60
    width = data[:beam_width] || PMD_AC::BEAM_DEFAULT_WIDTH
    super(viewport, user, target, style, life, width)
  end

  def update
    super
    return if @finished
    @tick -= 1
    if @tick <= 0
      @scene.resolve_sustained_beam_tick(@user, @target, @data)
      @tick = @tick_interval
    end
  end
end

#==============================================================================
# ■ Sprite_PMDSweepingBeam
#==============================================================================
class Sprite_PMDSweepingBeam < Sprite_PMDArenaBeam
  def initialize(viewport, scene, user, target, data)
    @scene = scene
    @user = user
    @data = data
    @duration = [(data[:duration] || 48).to_i, 1].max
    @elapsed = 0
    @length = (data[:beam_length] || 220.0).to_f
    @sweep_angle = (data[:sweep_angle] || 60.0).to_f
    dx = target.pixel_x - user.pixel_x
    dy = target.pixel_y - user.pixel_y
    @base_angle = Math.atan2(dy, dx)
    @hit_ids = {}
    style = data[:beam_style] || user.projectile_style
    width = data[:beam_width] || PMD_AC::BEAM_DEFAULT_WIDTH
    endpoint = sweep_endpoint(0)
    super(viewport, user, endpoint, style, @duration, width)
  end

  def sweep_endpoint(frame)
    ratio = frame.to_f / [@duration - 1, 1].max.to_f
    degree = -@sweep_angle / 2.0 + @sweep_angle * ratio
    rad = @base_angle + degree * Math::PI / 180.0
    x = @user.pixel_x + Math.cos(rad) * @length
    y = @user.pixel_y + Math.sin(rad) * @length
    return [x, y]
  end

  def update
    return if @finished
    set_fixed_target(*sweep_endpoint(@elapsed))
    super
    return if @finished
    points = current_points
    @scene.resolve_sweeping_beam_tick(@user, points[0], points[1],
                                      points[2], points[3], @data, @hit_ids)
    @elapsed += 1
  end
end

#==============================================================================
# ■ Sprite_PMDArenaZone
#------------------------------------------------------------------------------
# 低遮蔽像素地面區域。視覺不參與命中，Zone 邏輯由 Scene 管理。
#==============================================================================
class Sprite_PMDArenaZone < Sprite
  attr_reader :finished

  def initialize(viewport, x, y, radius, style, duration)
    super(viewport)
    @life = [duration.to_i, 1].max
    @max_life = @life
    @finished = false
    @style = style || :neutral
    self.bitmap = Bitmap.new(128, 128)
    self.ox = 64
    self.oy = 64
    self.x = x.to_i
    self.y = y.to_i
    self.z = 120
    scale = [radius.to_f / 60.0, 0.20].max
    self.zoom_x = scale
    self.zoom_y = scale
    draw_zone
  end

  def zone_color(alpha)
    case @style
    when :fire
      return Color.new(255, 105, 35, alpha)
    when :water
      return Color.new(65, 175, 255, alpha)
    when :web
      return Color.new(225, 240, 220, alpha)
    when :poison
      return Color.new(170, 85, 205, alpha)
    when :heal
      return Color.new(100, 235, 135, alpha)
    when :energy
      return Color.new(255, 215, 90, alpha)
    when :ice
      return Color.new(130, 225, 255, alpha)
    else
      return Color.new(210, 220, 235, alpha)
    end
  end

  def move_to(x, y)
    self.x = x.to_i
    self.y = y.to_i
  end

  def draw_zone
    bmp = self.bitmap
    bmp.clear
    # 像素環＋稀疏內點，避免半透明大圓蓋過 PMD 角色。
    [58, 48, 35].each_with_index do |radius, index|
      step = index == 0 ? 10 : 18
      alpha = index == 0 ? 150 : 70
      degree = 0
      while degree < 360
        rad = degree * Math::PI / 180.0
        x = 64 + Math.cos(rad) * radius
        y = 64 + Math.sin(rad) * radius
        bmp.fill_rect(x.to_i - 1, y.to_i - 1, 3, 3, zone_color(alpha))
        degree += step
      end
    end
    for i in 0...24
      angle = (i * 47) % 360
      distance = 12 + (i * 13) % 40
      rad = angle * Math::PI / 180.0
      x = 64 + Math.cos(rad) * distance
      y = 64 + Math.sin(rad) * distance
      bmp.fill_rect(x.to_i, y.to_i, 2, 2, zone_color(55))
    end
  end

  def update
    super
    return if @finished
    @life -= 1
    pulse = 150 + (Graphics.frame_count % 24) * 3
    self.opacity = PMD_AC.clamp(pulse, 120, 210)
    if @life <= 0
      @finished = true
      self.visible = false
    end
  end

  def dispose
    self.bitmap.dispose if self.bitmap != nil && !self.bitmap.disposed?
    super
  end
end

#==============================================================================
# ■ Sprite_PMDVFXBurst
#------------------------------------------------------------------------------
# 以 PMD 192x192 sprite sheet 播放短命 Burst。用於 Beam 的 muzzle / impact，
# 以及水柱／光柱類技能的端點強化。缺少素材時會自動結束，不中斷戰鬥。
#==============================================================================
class Sprite_PMDVFXBurst < Sprite
  attr_reader :finished

  def initialize(viewport, x, y, profile, delay = 0)
    super(viewport)
    @profile = profile || {}
    @delay = [delay.to_i, 0].max
    @finished = false
    @frame_wait = [(@profile[:fps] || PMD_AC::PMD_VFX_DEFAULT_FPS).to_i, 1].max
    @frame_wait_count = @frame_wait
    @cell = PMD_AC::PMD_VFX_CELL_SIZE
    @sheet_name = @profile[:sheet]
    @frame_order = @profile[:frames]
    if @sheet_name == nil || !FileTest.exist?(PMD_AC::PMD_VFX_FOLDER + @sheet_name + ".png")
      self.bitmap = Bitmap.new(1, 1)
      self.visible = false
      @finished = true
      return
    end
    self.bitmap = Cache.load_bitmap(PMD_AC::PMD_VFX_FOLDER, @sheet_name)
    @cols = [self.bitmap.width / @cell, 1].max
    total = [@cols * [self.bitmap.height / @cell, 1].max, 1].max
    if @frame_order == nil || @frame_order.empty?
      @frame_order = []
      for i in 0...total
        @frame_order.push(i)
      end
    end
    @frame_order = @frame_order.find_all { |i| i >= 0 && i < total }
    if @frame_order.empty?
      @frame_order = [0]
    end
    @frame_index = 0
    self.src_rect = Rect.new(0, 0, @cell, @cell)
    self.ox = (@profile[:ox] || (@cell / 2)).to_i
    self.oy = (@profile[:oy] || (@cell / 2)).to_i
    self.x = x.to_i
    self.y = y.to_i
    self.z = (@profile[:z] || 9238).to_i
    zoom = (@profile[:zoom] || PMD_AC::PMD_VFX_DEFAULT_ZOOM).to_f
    zoom *= PMD_AC::PMD_VFX_GLOBAL_SCALE
    self.zoom_x = zoom
    self.zoom_y = zoom
    self.blend_type = (@profile[:blend] || 1).to_i
    self.opacity = (@profile[:opacity] || 255).to_i
    self.visible = (@delay <= 0)
    update_frame_rect
  end

  def update_frame_rect
    index = @frame_order[[@frame_index, @frame_order.size - 1].min]
    col = index % @cols
    row = index / @cols
    self.src_rect.set(col * @cell, row * @cell, @cell, @cell)
  end

  def update
    super
    return if @finished
    if @delay > 0
      @delay -= 1
      self.visible = true if @delay <= 0
      return
    end
    @frame_wait_count -= 1
    if @frame_wait_count <= 0
      @frame_wait_count = @frame_wait
      @frame_index += 1
      if @frame_index >= @frame_order.size
        @finished = true
        self.visible = false
        return
      end
      update_frame_rect
    end
    self.opacity = 255 - (@frame_index * 8)
  end

  def dispose
    super
  end
end

#==============================================================================
# ■ Scene_PMD_AutoChess
#==============================================================================
class Scene_PMD_AutoChess < Scene_Base
  def init_battle_log
    @battle_log_enabled = false
    @battle_log_battle_id = 0
    @battle_log_counts = {}
    @battle_started_frame = nil
    return unless PMD_AC::BATTLE_LOG_ENABLED
    begin
      File.open(PMD_AC::BATTLE_LOG_FILE, "wb") do |file|
        file.write("PMD AutoChess Proto v0.15 Battle Verification Log\r\n")
        file.write("Session: " + Time.now.strftime("%Y-%m-%d %H:%M:%S") + "\r\n")
        file.write("Unit Sprite Scale: " + PMD_AC::UNIT_SPRITE_SCALE.to_s + "\r\n")
        file.write("Effect Sprite Scale: " + PMD_AC::EFFECT_SPRITE_SCALE.to_s + "\r\n")
        file.write("Projectile Sprite Scale: " + PMD_AC::PROJECTILE_SPRITE_SCALE.to_s + "\r\n")
        file.write("============================================================\r\n")
      end
      @battle_log_enabled = true
    rescue
      @battle_log_enabled = false
    end
  end

  def log_event(category, message)
    return unless @battle_log_enabled
    begin
      key = category.to_s
      unless key == "battle" || key == "summary"
        @battle_log_counts[key] = 0 if @battle_log_counts[key] == nil
        @battle_log_counts[key] += 1
      end
      frame = @battle_started_frame == nil ? 0 :
              Graphics.frame_count - @battle_started_frame
      line = sprintf("[%06d][%s] %s\r\n", frame, key.upcase, message.to_s)
      File.open(PMD_AC::BATTLE_LOG_FILE, "ab") { |file| file.write(line) }
    rescue
      @battle_log_enabled = false
    end
  end

  def log_battle_summary
    return unless @battle_log_enabled
    items = []
    keys = @battle_log_counts.keys
    keys.sort! { |a, b| a.to_s <=> b.to_s }
    for key in keys
      items.push(key.to_s.upcase + "=" + @battle_log_counts[key].to_s)
    end
    log_event(:summary, "EVENT COUNTS: " + items.join(" | "))
    for unit in @units
      log_event(:summary, unit.log_name +
                " HP=" + unit.hp.to_s + "/" + unit.maxhp.to_s +
                " AI=" + unit.movement_policy.to_s +
                " TARGET=" + unit.target_policy.to_s)
    end
  end

  def start
    super
    @phase = :deploy
    @battle_speed = 1
    @selected_unit = nil
    @logic_count = 0
    @battle_end = false
    @result_text = ""
    @attack_slots = {}
    @next_projectile_id = 0
    @miss_count = 0
    @shake_frames = 0
    @shake_power = 0
    @viewport_disposed = false
    @verification_mode_index = 0
    @verification_frame = 0
    @verification_done = {}
    @zone_avoid_log_frames = {}
    init_battle_log
    log_event(:battle, "SCENE START")

    identity_errors = PMD_AC.validate_identity_registry
    if identity_errors.empty?
      log_event(:identity,
                "REGISTRY PASS lines=" +
                PMD_AC::EVOLUTION_LINE_DATA.size.to_s +
                " species=" +
                PMD_AC::POKEMON_SPECIES_DATA.size.to_s +
                " unit_profiles=" +
                PMD_AC::UNIT_DATA.size.to_s)
    else
      log_event(:identity,
                "REGISTRY FAIL " + identity_errors.join(","))
    end

    create_viewport
    create_background
    create_board
    create_header
    create_footer
    create_units
    create_unit_sprites
    create_deploy_cursor
    @effect_sprites = []
    @projectile_sprites = []
    @battle_objects = []
    @battle_object_sprites = []
    @next_battle_object_id = 0
    @summon_removal_queue = []
    @zones = []
    @aura_counter = 0
    refresh_header
    refresh_footer
    refresh_selected_sprites
  end

  def terminate
    log_event(:battle, "SCENE TERMINATE")
    super
    dispose_unit_sprites
    dispose_effect_sprites
    dispose_projectile_sprites
    dispose_battle_object_sprites
    dispose_sprite(@deploy_cursor)
    dispose_sprite(@result_sprite)
    dispose_sprite(@footer_sprite)
    dispose_sprite(@header_sprite)
    dispose_sprite(@board_sprite)
    dispose_sprite(@background_sprite)
    dispose_viewport
  end

  def update
    super
    case @phase
    when :deploy
      update_deploy_phase
      update_unit_sprites
      @deploy_cursor.update if @deploy_cursor != nil
    when :battle
      update_battle_input
      return if $scene != self
      steps = @battle_speed
      for i in 0...steps
        update_battle_step
        update_unit_sprites
        update_effect_sprites
        update_projectile_sprites
        break if @phase != :battle
      end
    when :result
      update_result_phase
      update_unit_sprites
      update_effect_sprites
      update_projectile_sprites
      update_battle_object_sprites
    end
    update_camera_shake if $scene == self
  end

  #--------------------------------------------------------------------------
  # ● 戰前布陣
  #--------------------------------------------------------------------------
  def update_deploy_phase
    moved = false
    if Input.repeat?(Input::LEFT)
      moved = move_deploy_cursor(-1, 0)
    elsif Input.repeat?(Input::RIGHT)
      moved = move_deploy_cursor(1, 0)
    elsif Input.repeat?(Input::UP)
      moved = move_deploy_cursor(0, -1)
    elsif Input.repeat?(Input::DOWN)
      moved = move_deploy_cursor(0, 1)
    end
    if moved
      Sound.play_cursor
      refresh_footer
    end

    if Input.trigger?(Input::C)
      handle_deploy_confirm
    elsif Input.trigger?(Input::Y)
      cycle_verification_mode
    elsif Input.trigger?(Input::A)
      start_battle
    elsif Input.trigger?(Input::B)
      if @selected_unit != nil
        Sound.play_cancel
        @selected_unit = nil
        refresh_selected_sprites
        refresh_footer
      else
        Sound.play_cancel
        $scene = Scene_Map.new
      end
    end
  end

  def move_deploy_cursor(dx, dy)
    old_x = @deploy_cursor.cell_x
    old_y = @deploy_cursor.cell_y
    @deploy_cursor.move_to(old_x + dx, old_y + dy)
    return old_x != @deploy_cursor.cell_x || old_y != @deploy_cursor.cell_y
  end

  def handle_deploy_confirm
    cursor_unit = unit_at(@deploy_cursor.cell_x, @deploy_cursor.cell_y)
    if @selected_unit == nil
      if cursor_unit != nil && cursor_unit.team == :ally
        Sound.play_decision
        @selected_unit = cursor_unit
        refresh_selected_sprites
        refresh_footer
      else
        Sound.play_buzzer
      end
      return
    end

    if cursor_unit == @selected_unit
      Sound.play_cancel
      @selected_unit = nil
      refresh_selected_sprites
      refresh_footer
      return
    end

    old_x = @selected_unit.cell_x
    old_y = @selected_unit.cell_y
    if cursor_unit != nil
      if cursor_unit.team != :ally
        Sound.play_buzzer
        return
      end
      cursor_unit.deploy_to_cell(old_x, old_y)
    end
    @selected_unit.deploy_to_cell(@deploy_cursor.cell_x, @deploy_cursor.cell_y)
    Sound.play_equip
    @selected_unit = nil
    refresh_selected_sprites
    refresh_footer
  end

  def verification_mode
    return PMD_AC::VERIFICATION_MODES[@verification_mode_index] || :normal
  end

  def verification_mode_label
    return PMD_AC::VERIFICATION_LABELS[verification_mode] || "NORMAL"
  end

  def cycle_verification_mode
    @verification_mode_index += 1
    @verification_mode_index %= PMD_AC::VERIFICATION_MODES.size
    Sound.play_cursor
    log_event(:verify, "MODE -> " + verification_mode_label)
    refresh_header
    refresh_footer
  end

  def verification_unit(team, key)
    return @units.find { |u| u.team == team && u.key == key }
  end

  def prepare_verification_battle
    @verification_frame = 0
    @verification_done = {}
    @zone_avoid_log_frames = {}
    mode = verification_mode
    active = mode != :normal

    for unit in @units
      unit.verification_prepare(active, PMD_AC::VERIFICATION_HP_MULTIPLIER)
      unit.verification_energy_sandbox(
        [:energy, :direction, :object, :summon, :identity].include?(mode))
      unit.verification_combat_sandbox(
        [:direction, :object, :summon, :identity].include?(mode))
    end

    return unless active

    positions = {
      [:ally, :bulbasaur]  => [1, 1],
      [:ally, :charmander] => [1, 2],
      [:ally, :squirtle]   => [1, 3],
      [:enemy, :rattata]   => [4, 1],
      [:enemy, :caterpie]  => [4, 2],
      [:enemy, :pikachu]   => [4, 3]
    }
    for pair in positions
      unit = verification_unit(pair[0][0], pair[0][1])
      unit.deploy_to_cell(pair[1][0], pair[1][1]) if unit != nil
    end

    log_event(:verify,
              "START mode=" + verification_mode_label +
              " hp_x" + PMD_AC::VERIFICATION_HP_MULTIPLIER.to_s +
              " auto_skill=off")
  end

  def verify_force_skill(tag, caster_team, caster_key, skill_type,
                         target_team, target_key)
    return if @verification_done[tag]
    caster = verification_unit(caster_team, caster_key)
    target = verification_unit(target_team, target_key)
    if caster == nil || target == nil || caster.dead? || target.dead?
      log_event(:verify, tag.to_s.upcase + " SKIP missing/dead")
      @verification_done[tag] = true
      return
    end
    ok = caster.verification_force_skill(skill_type, target)
    if ok
      log_event(:verify,
                tag.to_s.upcase + " FORCE " + caster.log_name +
                " skill=" + caster.skill_name.to_s +
                " target=" + target.log_name)
      @verification_done[tag] = true
    end
  end

  def verify_force_basic(tag, caster_team, caster_key,
                         target_team, target_key, modifier = nil)
    return if @verification_done[tag]
    caster = verification_unit(caster_team, caster_key)
    target = verification_unit(target_team, target_key)
    if caster == nil || target == nil || caster.dead? || target.dead?
      log_event(:verify, tag.to_s.upcase + " SKIP missing/dead")
      @verification_done[tag] = true
      return
    end
    ok = caster.verification_force_basic_attack(target, modifier)
    if ok
      log_event(:verify,
                tag.to_s.upcase + " FORCE_BASIC " +
                caster.log_name + " -> " + target.log_name)
      @verification_done[tag] = true
    end
  end

  def verify_force_tracking_projectile(tag, caster_team, caster_key,
                                       target_team, target_key, tracking)
    return if @verification_done[tag]
    caster = verification_unit(caster_team, caster_key)
    target = verification_unit(target_team, target_key)
    if caster == nil || target == nil || caster.dead? || target.dead?
      log_event(:verify, tag.to_s.upcase + " SKIP missing/dead")
      @verification_done[tag] = true
      return
    end
    target.verification_force_evade_ready
    launch_projectile(caster, target, :basic, 100, :single,
                      tracking, nil)
    log_event(:verify,
              tag.to_s.upcase + " PROJECTILE tracking=" +
              tracking.to_s + " " + caster.log_name +
              " -> " + target.log_name)
    @verification_done[tag] = true
  end

  def verify_set_energy(tag, team, key, value)
    return if @verification_done[tag]
    unit = verification_unit(team, key)
    if unit == nil || unit.dead?
      log_event(:verify, tag.to_s.upcase + " SKIP missing/dead")
      @verification_done[tag] = true
      return
    end
    unit.verification_set_energy(value)
    log_event(:verify,
              tag.to_s.upcase + " " + unit.log_name +
              " energy=" + unit.energy.to_s)
    @verification_done[tag] = true
  end

  def verify_energy_effect(tag, source_team, source_key,
                           target_team, target_key, effect)
    return if @verification_done[tag]
    source = verification_unit(source_team, source_key)
    target = verification_unit(target_team, target_key)
    if source == nil || target == nil || source.dead? || target.dead?
      log_event(:verify, tag.to_s.upcase + " SKIP missing/dead")
      @verification_done[tag] = true
      return
    end
    apply_skill_effects(source, target,
                        {:effects => [effect], :can_crit => false}, 1.0)
    log_event(:verify,
              tag.to_s.upcase + " " + source.log_name +
              " -> " + target.log_name +
              " src_energy=" + source.energy.to_s +
              " dst_energy=" + target.energy.to_s)
    @verification_done[tag] = true
  end

  def verify_directional_hit(tag, arc,
                             source_team, source_key,
                             target_team, target_key)
    return if @verification_done[tag]
    source = verification_unit(source_team, source_key)
    target = verification_unit(target_team, target_key)
    if source == nil || target == nil || source.dead? || target.dead?
      log_event(:verify, tag.to_s.upcase + " SKIP missing/dead")
      @verification_done[tag] = true
      return
    end

    # Target 固定面向右(6)。
    target.deploy_to_cell(2, 2)
    target.verification_set_facing(6)

    case arc
    when :front
      source.deploy_to_cell(3, 2)
    when :back
      source.deploy_to_cell(1, 2)
    else
      source.deploy_to_cell(2, 1)
    end
    source.face_toward(target, true)

    before = target.hp
    dealt = deal_direct_damage(
      source, target, 100,
      {:fixed_damage => 100,
       :can_crit => false,
       :directional => true,
       :grant_energy => false,
       :source_type => :verification})
    actual = before - target.hp

    expected_mult = target.directional_damage_multiplier(arc)
    expected = (100.0 * expected_mult).round
    log_event(:verify,
              tag.to_s.upcase +
              " arc=" + arc.to_s +
              " expected=" + expected.to_s +
              " dealt=" + dealt.to_s +
              " hp_damage=" + actual.to_s)
    @verification_done[tag] = true
  end

  def verify_blink_back_attack(tag,
                               source_team, source_key,
                               target_team, target_key)
    return if @verification_done[tag]
    source = verification_unit(source_team, source_key)
    target = verification_unit(target_team, target_key)
    if source == nil || target == nil || source.dead? || target.dead?
      log_event(:verify, tag.to_s.upcase + " SKIP missing/dead")
      @verification_done[tag] = true
      return
    end

    # Target 固定面向右；Source 先站正面，再執行真正的 blink_behind。
    target.deploy_to_cell(2, 2)
    target.verification_set_facing(6)
    source.deploy_to_cell(3, 2)
    source.face_toward(target, true)

    source.blink_behind(target, 34.0)
    arc = target.incoming_arc_from(source)

    before_hp = target.hp
    dealt = deal_direct_damage(
      source, target, 100,
      {:fixed_damage => 100,
       :can_crit => false,
       :directional => true,
       :grant_energy => false,
       :source_type => :verification})
    actual = before_hp - target.hp

    expected = arc == :back ? 115 : (arc == :front ? 85 : 100)
    log_event(:verify,
              tag.to_s.upcase +
              " arc=" + arc.to_s +
              " expected=115" +
              " actual_expected=" + expected.to_s +
              " dealt=" + dealt.to_s +
              " hp_damage=" + actual.to_s)
    @verification_done[tag] = true
  end

  def verify_shield_trigger_setup(tag, team, key)
    return if @verification_done[tag]
    unit = verification_unit(team, key)
    if unit == nil || unit.dead?
      log_event(:verify, tag.to_s.upcase + " SKIP missing/dead")
      @verification_done[tag] = true
      return
    end

    unit.verification_set_energy(0)
    unit.clear_shield_trigger
    trigger = {
      :absorb_cooldown => 0,
      :on_absorb => [
        {:type => :energy_gain, :flat => 5, :target => :self}
      ],
      :on_break => [
        {:type => :energy_gain, :flat => 15, :target => :self}
      ]
    }
    unit.add_shield(70, 120, trigger, unit)
    log_event(:verify,
              tag.to_s.upcase + " " + unit.log_name +
              " shield=" + unit.shield.to_s +
              " energy=" + unit.energy.to_s)
    @verification_done[tag] = true
  end

  def verify_shield_hit(tag, source_team, source_key,
                        target_team, target_key, fixed_damage)
    return if @verification_done[tag]
    source = verification_unit(source_team, source_key)
    target = verification_unit(target_team, target_key)
    if source == nil || target == nil || source.dead? || target.dead?
      log_event(:verify, tag.to_s.upcase + " SKIP missing/dead")
      @verification_done[tag] = true
      return
    end

    before_hp = target.hp
    before_shield = target.shield
    before_energy = target.energy
    deal_direct_damage(
      source, target, 100,
      {:fixed_damage => fixed_damage,
       :can_crit => false,
       :directional => false,
       :grant_energy => false,
       :source_type => :verification})

    log_event(:verify,
              tag.to_s.upcase +
              " damage=" + fixed_damage.to_i.to_s +
              " shield=" + before_shield.to_s +
              "->" + target.shield.to_s +
              " hp_loss=" + (before_hp - target.hp).to_s +
              " energy=" + before_energy.to_s +
              "->" + target.energy.to_s)
    @verification_done[tag] = true
  end

  def verify_object_spawn(tag, owner_team, owner_key,
                          object_key, target_team, target_key,
                          overrides = nil)
    return nil if @verification_done[tag]
    owner = verification_unit(owner_team, owner_key)
    target = verification_unit(target_team, target_key)
    if owner == nil || target == nil || owner.dead? || target.dead?
      log_event(:verify, tag.to_s.upcase + " SKIP missing/dead")
      @verification_done[tag] = true
      return nil
    end

    obj = create_battle_object(owner, object_key,
                               target.pixel_x, target.pixel_y,
                               overrides || {})
    if obj != nil
      log_event(:verify,
                tag.to_s.upcase + " SPAWN " + obj.log_name)
    end
    @verification_done[tag] = true
    return obj
  end

  def verify_decoy_target(tag, source_team, source_key)
    return if @verification_done[tag]
    source = verification_unit(source_team, source_key)
    if source == nil || source.dead?
      log_event(:verify, tag.to_s.upcase + " SKIP missing/dead")
      @verification_done[tag] = true
      return
    end

    candidate, score = source.best_target_candidate
    object = candidate != nil &&
             candidate.respond_to?(:battle_object?) &&
             candidate.battle_object?
    log_event(:object_target,
              source.log_name +
              " candidate=" + (candidate == nil ? "NONE" :
                               candidate.log_name) +
              " object=" + (object ? "1" : "0") +
              " score=" + score.round.to_s)
    log_event(:verify,
              tag.to_s.upcase +
              " object_target=" + (object ? "PASS" : "FAIL"))
    @verification_done[tag] = true
  end

  def verify_damage_first_object(tag, source_team, source_key,
                                 object_kind, amount)
    return if @verification_done[tag]
    source = verification_unit(source_team, source_key)
    obj = nil
    for candidate in battle_objects
      if candidate.kind == object_kind && candidate.alive?
        obj = candidate
        break
      end
    end

    if source == nil || obj == nil
      log_event(:verify, tag.to_s.upcase + " SKIP missing")
      @verification_done[tag] = true
      return
    end

    before = obj.hp
    deal_direct_damage(
      source, obj, 100,
      {:fixed_damage => amount,
       :can_crit => false,
       :directional => false,
       :grant_energy => false,
       :source_type => :verification})
    after = obj.hp
    log_event(:verify,
              tag.to_s.upcase +
              " " + obj.log_name +
              " hp=" + before.to_s + "->" + after.to_s)
    @verification_done[tag] = true
  end

  def verify_prepare_object_positions(tag)
    return if @verification_done[tag]
    ally_b = verification_unit(:ally, :bulbasaur)
    ally_c = verification_unit(:ally, :charmander)
    ally_s = verification_unit(:ally, :squirtle)
    enemy_r = verification_unit(:enemy, :rattata)
    enemy_c = verification_unit(:enemy, :caterpie)
    enemy_p = verification_unit(:enemy, :pikachu)

    ally_b.deploy_to_cell(1, 1) if ally_b != nil
    ally_c.deploy_to_cell(1, 2) if ally_c != nil
    ally_s.deploy_to_cell(1, 3) if ally_s != nil
    enemy_r.deploy_to_cell(4, 1) if enemy_r != nil
    enemy_c.deploy_to_cell(4, 2) if enemy_c != nil
    enemy_p.deploy_to_cell(4, 3) if enemy_p != nil

    ally_b.verification_set_energy(0) if ally_b != nil
    ally_c.verification_set_energy(0) if ally_c != nil
    ally_s.verification_set_energy(0) if ally_s != nil

    log_event(:verify, tag.to_s.upcase + " POSITIONS READY")
    @verification_done[tag] = true
  end

  def verify_spawn_decoy(tag)
    return if @verification_done[tag]
    owner = verification_unit(:ally, :squirtle)
    enemy = verification_unit(:enemy, :rattata)
    if owner == nil || enemy == nil
      @verification_done[tag] = true
      return
    end
    # 放在小拉達附近，確保 Decoy Utility 明顯勝過普通目標。
    x = enemy.pixel_x - 32.0
    y = enemy.pixel_y
    obj = create_battle_object(owner, :decoy, x, y,
                               {:duration => 90, :hp => 100})
    log_event(:verify,
              tag.to_s.upcase + " " +
              (obj == nil ? "FAIL" : obj.log_name))
    @verification_done[tag] = true
  end

  def verify_spawn_trap(tag)
    return if @verification_done[tag]
    owner = verification_unit(:ally, :bulbasaur)
    enemy = verification_unit(:enemy, :caterpie)
    if owner != nil && enemy != nil
      before = enemy.hp
      obj = create_battle_object(
        owner, :trap, enemy.pixel_x, enemy.pixel_y,
        {:arm_delay => 8,
         :duration => 60,
         :effects => [{:type => :damage, :flat => 40}]})
      log_event(:verify,
                tag.to_s.upcase +
                " target_hp=" + before.to_s +
                " object=" + (obj == nil ? "NONE" : obj.log_name))
    end
    @verification_done[tag] = true
  end

  def verify_spawn_bomb(tag)
    return if @verification_done[tag]
    owner = verification_unit(:ally, :charmander)
    enemy = verification_unit(:enemy, :pikachu)
    if owner != nil && enemy != nil
      obj = create_battle_object(
        owner, :bomb, enemy.pixel_x, enemy.pixel_y,
        {:trigger_delay => 24,
         :duration => 60,
         :targetable => false,
         :effect_radius => 38.0,
         :effects => [{:type => :damage, :flat => 60}]})
      log_event(:verify,
                tag.to_s.upcase +
                " object=" + (obj == nil ? "NONE" : obj.log_name) +
                " target_hp=" + enemy.hp.to_s)
    end
    @verification_done[tag] = true
  end

  def verify_spawn_totem(tag)
    return if @verification_done[tag]
    owner = verification_unit(:ally, :squirtle)
    if owner != nil
      for unit in living_units(:ally)
        unit.verification_set_energy(0)
      end
      obj = create_battle_object(
        owner, :totem, owner.pixel_x, owner.pixel_y,
        {:duration => 76,
         :tick_interval => 20,
         :effect_radius => 999.0,
         :targetable => false,
         :effects => [
           {:type => :energy_gain, :flat => 7,
            :reason => :object_verify_totem}
         ]})
      log_event(:verify,
                tag.to_s.upcase +
                " object=" + (obj == nil ? "NONE" : obj.log_name))
    end
    @verification_done[tag] = true
  end

  def verify_spawn_delayed(tag)
    return if @verification_done[tag]
    owner = verification_unit(:ally, :bulbasaur)
    enemy = verification_unit(:enemy, :rattata)
    if owner != nil && enemy != nil
      obj = create_battle_object(
        owner, :delayed_marker, enemy.pixel_x, enemy.pixel_y,
        {:trigger_delay => 24,
         :duration => 60,
         :effect_radius => 38.0,
         :effects => [
           {:type => :damage, :flat => 35},
           {:type => :status, :status => :root,
            :value => 0, :duration => 30,
            :stack_mode => :refresh}
         ]})
      log_event(:verify,
                tag.to_s.upcase +
                " object=" + (obj == nil ? "NONE" : obj.log_name) +
                " target_hp=" + enemy.hp.to_s)
    end
    @verification_done[tag] = true
  end

  def verify_substitute_setup(tag)
    return if @verification_done[tag]
    owner = verification_unit(:ally, :charmander)
    if owner == nil || owner.dead?
      @verification_done[tag] = true
      return
    end

    before = owner.hp
    effect = {
      :object => :substitute,
      :placement => :self,
      :hp_cost_ratio => PMD_AC::SUBSTITUTE_DEFAULT_HP_RATIO,
      :offset_x => 18,
      :object_data => {:hp => 80, :duration => 120}
    }
    obj = create_battle_object_from_effect(owner, owner, effect)
    cost = before - owner.hp

    log_event(:verify,
              tag.to_s.upcase +
              " owner_hp=" + before.to_s + "->" + owner.hp.to_s +
              " cost=" + cost.to_s +
              " object=" + (obj == nil ? "NONE" : obj.log_name))
    @verification_done[tag] = true
  end

  def verify_substitute_redirect(tag, fixed_damage)
    return if @verification_done[tag]
    source = verification_unit(:enemy, :pikachu)
    owner = verification_unit(:ally, :charmander)
    if source == nil || owner == nil
      @verification_done[tag] = true
      return
    end

    sub = substitute_for(owner)
    before_owner = owner.hp
    before_sub = sub == nil ? -1 : sub.hp
    target = substitute_target_for(source, owner, :verification)
    deal_direct_damage(
      source, target, 100,
      {:fixed_damage => fixed_damage,
       :can_crit => false,
       :directional => false,
       :grant_energy => false,
       :source_type => :verification})

    after_sub = sub == nil ? -1 : sub.hp
    log_event(:verify,
              tag.to_s.upcase +
              " redirected=" + ((target != owner) ? "1" : "0") +
              " owner_hp=" + before_owner.to_s + "->" + owner.hp.to_s +
              " sub_hp=" + before_sub.to_s + "->" + after_sub.to_s)
    @verification_done[tag] = true
  end

  def verify_owner_hit_after_substitute(tag, fixed_damage)
    return if @verification_done[tag]
    source = verification_unit(:enemy, :pikachu)
    owner = verification_unit(:ally, :charmander)
    if source == nil || owner == nil
      @verification_done[tag] = true
      return
    end

    before = owner.hp
    target = substitute_target_for(source, owner, :verification_after_break)
    deal_direct_damage(
      source, target, 100,
      {:fixed_damage => fixed_damage,
       :can_crit => false,
       :directional => false,
       :grant_energy => false,
       :source_type => :verification})
    log_event(:verify,
              tag.to_s.upcase +
              " target_owner=" + ((target == owner) ? "1" : "0") +
              " owner_hp=" + before.to_s + "->" + owner.hp.to_s)
    @verification_done[tag] = true
  end

  def verify_summon_spawn(tag)
    return if @verification_done[tag]
    owner = verification_unit(:ally, :squirtle)
    enemy = verification_unit(:enemy, :caterpie)
    if owner == nil || enemy == nil
      @verification_done[tag] = true
      return
    end

    x = enemy.pixel_x - 46.0
    y = enemy.pixel_y
    unit = summon_unit(
      owner, :rattata, x, y,
      {:duration => 82,
       :hp_scale => 0.50,
       :stat_scale => 0.65,
       :allow_skill => false,
       :expire_with_owner => true,
       :name_prefix => "援手"})

    if unit != nil
      log_event(:verify,
                tag.to_s.upcase +
                " " + unit.log_name +
                " summoned=" + (unit.summoned? ? "1" : "0") +
                " victory=" + (unit.counts_for_victory? ? "1" : "0") +
                " hp=" + unit.hp.to_s +
                " dur=" + unit.summon_remaining.to_s)
    end
    @verification_done[tag] = true
  end

  def verify_summon_basic(tag)
    return if @verification_done[tag]
    unit = summoned_units(:ally)[0]
    target = verification_unit(:enemy, :caterpie)
    if unit == nil || target == nil || unit.dead? || target.dead?
      log_event(:verify, tag.to_s.upcase + " SKIP missing/dead")
      @verification_done[tag] = true
      return
    end

    before = target.hp
    unit.verification_force_basic_attack(target, nil)
    unit.resolve_basic_attack
    log_event(:verify,
              tag.to_s.upcase +
              " target_hp=" + before.to_s + "->" + target.hp.to_s +
              " summon_alive=" + (unit.alive? ? "1" : "0"))
    @verification_done[tag] = true
  end

  def verify_summon_state(tag)
    return if @verification_done[tag]
    alive = summoned_units(:ally)
    any_summon_in_scene = false
    for unit in @units
      if unit.summoned?
        any_summon_in_scene = true
        break
      end
    end
    log_event(:verify,
              tag.to_s.upcase +
              " alive_summons=" + alive.size.to_s +
              " in_scene=" + (any_summon_in_scene ? "1" : "0") +
              " removed=" + (!any_summon_in_scene ? "PASS" : "FAIL"))
    @verification_done[tag] = true
  end

  def verify_identity_registry(tag)
    return if @verification_done[tag]
    errors = PMD_AC.validate_identity_registry
    pass = errors.empty?
    log_event(:verify,
              tag.to_s.upcase +
              " pass=" + (pass ? "1" : "0") +
              " errors=[" + errors.join(",") + "]")
    @verification_done[tag] = true
  end

  def verify_identity_units(tag)
    return if @verification_done[tag]
    uids = []
    valid = true

    for unit in @units
      next if unit.summoned?
      uids.push(unit.instance_uid)
      identity = unit.identity
      valid = false if identity == nil
      valid = false if unit.species_key != unit.key
      valid = false if identity.pmd_species_id != unit.species.to_s

      log_event(:identity,
                unit.log_name + " " + identity.log_signature +
                " synergy=[" +
                unit.synergy_tags.collect { |x| x.to_s }.join(",") + "]" +
                " roles=[" +
                unit.role_tags.collect { |x| x.to_s }.join(",") + "]")
    end

    unique = (uids.uniq.size == uids.size)
    log_event(:verify,
              tag.to_s.upcase +
              " units=" + uids.size.to_s +
              " unique_uid=" + (unique ? "PASS" : "FAIL") +
              " mapping=" + (valid ? "PASS" : "FAIL"))
    @verification_done[tag] = true
  end

  def verify_identity_starters(tag)
    return if @verification_done[tag]
    keys = [:bulbasaur, :charmander, :squirtle]
    pass = true
    lines = []

    for key in keys
      unit = verification_unit(:ally, key)
      if unit == nil
        pass = false
        next
      end
      pass = false unless unit.identity_synergy_tag?(:kanto_starter)
      pass = false unless unit.identity_synergy_tag?(:starter)
      lines.push(unit.evolution_line_key)
    end

    pass = false unless lines.uniq.size == 3
    log_event(:verify,
              tag.to_s.upcase +
              " pass=" + (pass ? "1" : "0") +
              " lines=[" + lines.collect { |x| x.to_s }.join(",") + "]")
    @verification_done[tag] = true
  end

  def verify_identity_matching(tag)
    return if @verification_done[tag]
    unit = verification_unit(:ally, :bulbasaur)
    if unit == nil
      @verification_done[tag] = true
      return
    end

    species_ok = unit.identity_species?(:bulbasaur)
    line_ok = unit.identity_line?(:bulbasaur_line)
    wrong_line = unit.identity_line?(:charmander_line)

    log_event(:verify,
              tag.to_s.upcase +
              " species=" + (species_ok ? "PASS" : "FAIL") +
              " line=" + (line_ok ? "PASS" : "FAIL") +
              " wrong_line=" + (!wrong_line ? "PASS" : "FAIL"))
    @verification_done[tag] = true
  end

  def verify_identity_form(tag)
    return if @verification_done[tag]
    unit = verification_unit(:ally, :bulbasaur)
    if unit == nil
      @verification_done[tag] = true
      return
    end

    preview = unit.identity.clone_identity
    before_uid = preview.instance_uid
    before_species = preview.species_key
    preview.set_form_key(:mega_preview)

    pass = preview.instance_uid == before_uid &&
           preview.species_key == before_species &&
           preview.form_key == :mega_preview

    log_event(:verify,
              tag.to_s.upcase +
              " pass=" + (pass ? "1" : "0") +
              " uid_same=" +
              (preview.instance_uid == before_uid ? "1" : "0") +
              " species_same=" +
              (preview.species_key == before_species ? "1" : "0") +
              " form=" + preview.form_key.to_s)
    @verification_done[tag] = true
  end

  def verify_identity_actor_adapter(tag)
    return if @verification_done[tag]
    unit = verification_unit(:ally, :squirtle)
    if unit == nil
      @verification_done[tag] = true
      return
    end

    preview = unit.identity.clone_identity
    before_uid = preview.instance_uid
    before_species = preview.species_key
    preview.bind_actor_ids(501, 7)

    pass = preview.instance_uid == before_uid &&
           preview.species_key == before_species &&
           preview.runtime_actor_id == 501 &&
           preview.template_actor_id == 7

    log_event(:verify,
              tag.to_s.upcase +
              " pass=" + (pass ? "1" : "0") +
              " uid=" + preview.instance_uid.to_s +
              " species=" + preview.species_key.to_s +
              " runtime_actor=" + preview.runtime_actor_id.to_s +
              " template_actor=" + preview.template_actor_id.to_s)
    @verification_done[tag] = true
  end

  def verify_identity_summon(tag)
    return if @verification_done[tag]
    owner = verification_unit(:ally, :squirtle)
    natural = verification_unit(:enemy, :rattata)
    if owner == nil || natural == nil
      @verification_done[tag] = true
      return
    end

    summon = summon_unit(
      owner, :rattata,
      owner.pixel_x + 40.0, owner.pixel_y,
      {:duration => 30,
       :hp_scale => 0.50,
       :stat_scale => 0.60,
       :allow_skill => false,
       :expire_with_owner => true,
       :name_prefix => "身份測試"})

    if summon == nil
      log_event(:verify, tag.to_s.upcase + " spawn=FAIL")
      @verification_done[tag] = true
      return
    end

    same_species = summon.species_key == natural.species_key
    same_line = summon.evolution_line_key == natural.evolution_line_key
    different_uid = summon.instance_uid != natural.instance_uid

    log_event(:verify,
              tag.to_s.upcase +
              " same_species=" + (same_species ? "PASS" : "FAIL") +
              " same_line=" + (same_line ? "PASS" : "FAIL") +
              " different_uid=" + (different_uid ? "PASS" : "FAIL") +
              " summon_uid=" + summon.instance_uid.to_s +
              " natural_uid=" + natural.instance_uid.to_s)
    @verification_done[tag] = true
  end

  def verify_identity_summon_removed(tag)
    return if @verification_done[tag]
    count = summoned_units(:ally).size
    log_event(:verify,
              tag.to_s.upcase +
              " alive_summons=" + count.to_s +
              " removed=" + (count == 0 ? "PASS" : "FAIL"))
    @verification_done[tag] = true
  end

  def verify_apply_control(tag, source_team, source_key,
                           target_team, target_key, control, duration)
    return if @verification_done[tag]
    source = verification_unit(source_team, source_key)
    target = verification_unit(target_team, target_key)
    if source == nil || target == nil || target.dead?
      log_event(:verify, tag.to_s.upcase + " SKIP missing/dead")
      @verification_done[tag] = true
      return
    end
    target.apply_control(control, duration, source)
    log_event(:verify,
              tag.to_s.upcase + " APPLY " + control.to_s +
              " " + source.log_name + " -> " + target.log_name)
    @verification_done[tag] = true
  end

  def verify_damage_allies
    return if @verification_done[:zone_damage]
    source = verification_unit(:enemy, :caterpie)
    for key in [:bulbasaur, :charmander, :squirtle]
      unit = verification_unit(:ally, key)
      unit.verification_damage(140, source) if unit != nil && unit.alive?
    end
    log_event(:verify, "ZONE PRE-DAMAGE allies=140")
    @verification_done[:zone_damage] = true
  end

  def verify_create_harmful_zone
    return if @verification_done[:harmful_zone]
    owner = verification_unit(:enemy, :caterpie)
    target = verification_unit(:ally, :charmander)
    if owner == nil || target == nil || owner.dead? || target.dead?
      log_event(:verify, "HARMFUL_ZONE SKIP missing/dead")
      @verification_done[:harmful_zone] = true
      return
    end
    add_zone(owner, {
      :x => target.pixel_x,
      :y => target.pixel_y,
      :style => :poison,
      :radius => 88.0,
      :duration => 150,
      :interval => 30,
      :scope => :enemies,
      :harmful => true,
      :effects => [
        {:type => :damage, :power => 4}
      ]
    })
    log_event(:verify, "HARMFUL_ZONE center=" + target.log_name)
    @verification_done[:harmful_zone] = true
  end

  def complete_verification_mode
    return if @verification_done[:verification_complete]
    for unit in @units
      unit.verification_finish
    end
    @verification_done[:verification_complete] = true
    log_event(:verify,
              "COMPLETE mode=" + verification_mode_label +
              " auto_skill=on original_skills=restored")
  end

  def update_verification_script
    return if verification_mode == :normal
    @verification_frame += 1

    case verification_mode
    when :control
      verify_force_skill(:channel_start, :enemy, :pikachu, :chain_lightning,
                         :ally, :bulbasaur) if @verification_frame >= 8
      verify_apply_control(:interrupt_silence, :ally, :squirtle,
                           :enemy, :pikachu, :silence, 48) if @verification_frame >= 18
      verify_force_skill(:tidal_push, :ally, :squirtle, :tidal_push,
                         :enemy, :rattata) if @verification_frame >= 52
      verify_force_skill(:dash, :ally, :charmander, :dash_strike,
                         :enemy, :caterpie) if @verification_frame >= 96
      complete_verification_mode if @verification_frame >=
                                    PMD_AC::VERIFICATION_CONTROL_END_FRAME

    when :beam
      verify_force_skill(:bounce, :ally, :bulbasaur, :ricochet_seed,
                         :enemy, :caterpie) if @verification_frame >= 8
      verify_force_skill(:sustain, :ally, :squirtle, :frost_beam,
                         :enemy, :pikachu) if @verification_frame >= 56
      verify_force_skill(:slow_timing, :enemy, :pikachu, :chain_lightning,
                         :ally, :bulbasaur) if @verification_frame >= 132
      verify_force_skill(:sweep, :ally, :charmander, :fire_sweep,
                         :enemy, :caterpie) if @verification_frame >= 190
      complete_verification_mode if @verification_frame >=
                                    PMD_AC::VERIFICATION_BEAM_END_FRAME

    when :zone
      verify_damage_allies if @verification_frame >= 4
      verify_force_skill(:healing_zone, :ally, :squirtle, :healing_field,
                         :ally, :charmander) if @verification_frame >= 12
      verify_create_harmful_zone if @verification_frame >= 78
      complete_verification_mode if @verification_frame >=
                                    PMD_AC::VERIFICATION_ZONE_END_FRAME

    when :hit
      # 1. Next Attack Modifier + Force Crit
      modifier = {
        :name => "驗證必暴擊",
        :force_crit => true,
        :power_multiplier => 1.20,
        :projectile_tracking => :perfect
      }
      verify_force_basic(:next_crit, :ally, :squirtle,
                         :enemy, :caterpie, modifier) if @verification_frame >= 8

      # 2. 無追蹤投射物：小拉達主動側閃，預期 projectile lost / evade success。
      verify_force_tracking_projectile(:evade_none,
        :ally, :squirtle, :enemy, :rattata, :none) if @verification_frame >= 78

      # 3. 強追蹤投射物：小拉達再次側閃，但彈道會修正，預期 evade fail。
      verify_force_tracking_projectile(:evade_strong,
        :ally, :squirtle, :enemy, :rattata, :strong) if @verification_frame >= 178

      # 4. Perfect tracking 對照組。
      verify_force_tracking_projectile(:tracking_perfect,
        :ally, :squirtle, :enemy, :rattata, :perfect) if @verification_frame >= 268

      complete_verification_mode if @verification_frame >=
                                    PMD_AC::VERIFICATION_HIT_END_FRAME

    when :energy
      # 初始值固定，並關閉普攻命中／受傷的自動能量，確保數值可驗證。
      verify_set_energy(:energy_src_init, :ally, :squirtle, 20) if
        @verification_frame >= 4
      verify_set_energy(:energy_ally_init, :ally, :charmander, 10) if
        @verification_frame >= 4
      verify_set_energy(:energy_enemy_init, :enemy, :caterpie, 80) if
        @verification_frame >= 4

      # Gain：小火龍 10 -> 40
      verify_energy_effect(:energy_gain, :ally, :squirtle,
        :ally, :charmander,
        {:type => :energy_gain, :flat => 30}) if @verification_frame >= 12

      # Drain：綠毛蟲 80 -> 55
      verify_energy_effect(:energy_drain, :ally, :squirtle,
        :enemy, :caterpie,
        {:type => :energy_drain, :flat => 25}) if @verification_frame >= 44

      # Steal：綠毛蟲 55 -> 35；傑尼龜 20 -> 40
      verify_energy_effect(:energy_steal, :ally, :squirtle,
        :enemy, :caterpie,
        {:type => :energy_steal, :flat => 20}) if @verification_frame >= 76

      # Lock：小火龍被鎖後，下一次 +30 必須被 BLOCK。
      verify_energy_effect(:energy_lock, :enemy, :caterpie,
        :ally, :charmander,
        {:type => :energy_lock, :duration => 72}) if @verification_frame >= 108
      verify_energy_effect(:energy_blocked_gain, :ally, :squirtle,
        :ally, :charmander,
        {:type => :energy_gain, :flat => 30}) if @verification_frame >= 116

      # Lock 到期後 Gain 恢復：40 -> 70
      verify_energy_effect(:energy_post_lock_gain, :ally, :squirtle,
        :ally, :charmander,
        {:type => :energy_gain, :flat => 30}) if @verification_frame >= 188

      # Aura：跟隨傑尼龜；驗證模式用大半徑確保三名友軍都能收到 Tick。
      verify_energy_effect(:energy_aura, :ally, :squirtle,
        :ally, :squirtle,
        {:type => :energy_aura, :flat => 7, :radius => 999.0,
         :duration => 100, :interval => 30, :scope => :allies}) if
        @verification_frame >= 212

      complete_verification_mode if @verification_frame >=
                                    PMD_AC::VERIFICATION_ENERGY_END_FRAME

    when :direction
      # 固定 100 傷害，不暴擊、不給被打能量，直接驗證三個方位倍率。
      verify_directional_hit(:direction_front, :front,
        :enemy, :rattata, :ally, :squirtle) if @verification_frame >= 8

      verify_directional_hit(:direction_side, :side,
        :enemy, :rattata, :ally, :squirtle) if @verification_frame >= 48

      verify_directional_hit(:direction_back, :back,
        :enemy, :rattata, :ally, :squirtle) if @verification_frame >= 88

      # Shield = 70。
      # 第一次 30：吸收 30，remain 40，on_absorb +5 Energy。
      verify_shield_trigger_setup(:shield_trigger_setup,
        :ally, :squirtle) if @verification_frame >= 128

      verify_shield_hit(:shield_absorb,
        :enemy, :rattata, :ally, :squirtle, 30) if
        @verification_frame >= 144

      # 第二次 60：吸收剩餘 40，HP -20。
      # on_absorb +5，on_break +15，所以 Energy 5 -> 25。
      verify_shield_hit(:shield_break,
        :enemy, :rattata, :ally, :squirtle, 60) if
        @verification_frame >= 184

      # Blink 必須真的依目標 Facing 落在背面，並吃 1.15 倍。
      verify_blink_back_attack(:blink_back,
        :enemy, :rattata, :ally, :charmander) if
        @verification_frame >= 224

      complete_verification_mode if @verification_frame >=
                                    PMD_AC::VERIFICATION_DIRECTION_END_FRAME

    when :object
      verify_prepare_object_positions(:object_positions) if
        @verification_frame >= 4

      # Decoy：Target Utility + 可摧毀。
      verify_spawn_decoy(:object_decoy_spawn) if @verification_frame >= 12
      verify_decoy_target(:object_decoy_target,
        :enemy, :rattata) if @verification_frame >= 16
      verify_damage_first_object(:object_decoy_hit1,
        :enemy, :rattata, :decoy, 45) if @verification_frame >= 24
      verify_damage_first_object(:object_decoy_hit2,
        :enemy, :rattata, :decoy, 55) if @verification_frame >= 36

      # Trap：8f Arm 後，綠毛蟲已在 Trigger Radius，應自動觸發 40。
      verify_spawn_trap(:object_trap_spawn) if @verification_frame >= 72

      # Bomb：24f Countdown，皮卡丘固定吃 60。
      verify_spawn_bomb(:object_bomb_spawn) if @verification_frame >= 126

      # Totem：20f Tick，三名藍方每次 +7，持續 76f。
      verify_spawn_totem(:object_totem_spawn) if @verification_frame >= 190

      # Delayed Skill：24f 後，小拉達吃 35 + Root。
      verify_spawn_delayed(:object_delayed_spawn) if @verification_frame >= 282

      complete_verification_mode if @verification_frame >=
                                    PMD_AC::VERIFICATION_OBJECT_END_FRAME

    when :summon
      verify_substitute_setup(:substitute_setup) if @verification_frame >= 8
      verify_substitute_redirect(:substitute_hit1, 35) if
        @verification_frame >= 28
      verify_substitute_redirect(:substitute_hit2, 50) if
        @verification_frame >= 58
      verify_owner_hit_after_substitute(:substitute_owner_hit, 40) if
        @verification_frame >= 88

      verify_summon_spawn(:summon_spawn) if @verification_frame >= 132
      verify_summon_basic(:summon_basic) if @verification_frame >= 150
      verify_summon_state(:summon_after_expire) if @verification_frame >= 230

      complete_verification_mode if @verification_frame >=
                                    PMD_AC::VERIFICATION_SUMMON_END_FRAME

    when :identity
      verify_identity_registry(:identity_registry) if
        @verification_frame >= 4

      verify_identity_units(:identity_units) if
        @verification_frame >= 12

      verify_identity_starters(:identity_starters) if
        @verification_frame >= 34

      verify_identity_matching(:identity_matching) if
        @verification_frame >= 54

      verify_identity_form(:identity_form) if
        @verification_frame >= 74

      verify_identity_actor_adapter(:identity_actor_adapter) if
        @verification_frame >= 94

      verify_identity_summon(:identity_summon) if
        @verification_frame >= 114

      verify_identity_summon_removed(:identity_summon_removed) if
        @verification_frame >= 154

      complete_verification_mode if @verification_frame >=
                                    PMD_AC::VERIFICATION_IDENTITY_END_FRAME
    end
  end

  def start_battle
    return if living_units(:ally).empty? || living_units(:enemy).empty?
    Sound.play_decision
    @selected_unit = nil
    @phase = :battle
    @logic_count = 0
    clear_battle_objects(:battle_start)
    @zones = []
    @aura_counter = 0
    @attack_slots.clear
    @deploy_cursor.visible = false if @deploy_cursor != nil
    @board_sprite.opacity = 145 if @board_sprite != nil
    @battle_log_battle_id += 1
    @battle_log_counts = {}
    @battle_started_frame = Graphics.frame_count
    log_event(:battle, "START #" + @battle_log_battle_id.to_s +
              " speed=x" + @battle_speed.to_s)
    for unit in @units
      log_event(:deploy, unit.log_name +
                " uid=" + unit.instance_uid.to_s +
                " species_key=" + unit.species_key.to_s +
                " line=" + unit.evolution_line_key.to_s +
                " form=" + unit.form_key.to_s +
                " cell=(" + unit.cell_x.to_s + "," + unit.cell_y.to_s + ")" +
                " move=" + unit.movement_policy.to_s +
                " target=" + unit.target_policy.to_s +
                " threat=" + unit.threat_policy.to_s +
                " skill=" + unit.skill_name.to_s +
                " skill_policy=" +
                (unit.skill_data[:policy] || unit.skill_policy).to_s)
      unit.start_combat
    end
    prepare_verification_battle
    refresh_selected_sprites
    refresh_header
    refresh_footer
  end

  #--------------------------------------------------------------------------
  # ● 戰鬥
  #--------------------------------------------------------------------------
  def update_battle_input
    if Input.trigger?(Input::B)
      Sound.play_cancel
      $scene = Scene_Map.new
      return
    end
    if Input.trigger?(Input::X)
      Sound.play_cursor
      @battle_speed = @battle_speed == 1 ? 2 : 1
      refresh_header
      refresh_footer
    end
  end

  def update_battle_step
    return if @phase != :battle
    @logic_count += 1
    update_verification_script
    for unit in @units
      unit.update
    end
    update_summon_removal_queue
    update_battle_objects
    update_battle_object_sprites
    update_zones
    if @logic_count >= PMD_AC::LOGIC_TICK
      @logic_count = 0
      cleanup_attack_slots
      @aura_counter += PMD_AC::LOGIC_TICK
      if @aura_counter >= PMD_AC::AURA_REFRESH_INTERVAL
        @aura_counter = 0
        unless [:direction, :object, :summon, :identity].include?(verification_mode)
          update_auras
        end
      end
      for unit in @units
        unit.update_logic
      end
    end
    check_battle_end
  end

  #--------------------------------------------------------------------------
  # ● 結果
  #--------------------------------------------------------------------------
  def update_result_phase
    if Input.trigger?(Input::B)
      Sound.play_cancel
      $scene = Scene_Map.new
    elsif Input.trigger?(Input::C)
      Sound.play_decision
      restart_to_deploy
    end
  end

  def create_viewport
    @viewport = Viewport.new(0, 0, Graphics.width, Graphics.height)
    @viewport.z = 0
  end

  def create_background
    @background_sprite = Sprite.new(@viewport)
    @background_sprite.bitmap = Bitmap.new(Graphics.width, Graphics.height)
    bmp = @background_sprite.bitmap
    bmp.fill_rect(0, 0, Graphics.width, Graphics.height, Color.new(18, 26, 36))
    bmp.fill_rect(0, 0, Graphics.width / 2, Graphics.height,
                  Color.new(25, 47, 68, 120))
    bmp.fill_rect(Graphics.width / 2, 0, Graphics.width / 2, Graphics.height,
                  Color.new(68, 31, 31, 120))
  end

  def create_board
    @board_sprite = Sprite.new(@viewport)
    @board_sprite.bitmap = Bitmap.new(Graphics.width, Graphics.height)
    bmp = @board_sprite.bitmap
    board_w = PMD_AC::GRID_COLS * PMD_AC::CELL_W
    board_h = PMD_AC::GRID_ROWS * PMD_AC::CELL_H
    bmp.fill_rect(PMD_AC::GRID_X, PMD_AC::GRID_Y, board_w, board_h,
                  Color.new(0, 0, 0, 80))
    for y in 0...PMD_AC::GRID_ROWS
      for x in 0...PMD_AC::GRID_COLS
        rx = PMD_AC::GRID_X + x * PMD_AC::CELL_W
        ry = PMD_AC::GRID_Y + y * PMD_AC::CELL_H
        shade = (x + y) % 2 == 0 ? 34 : 24
        bmp.fill_rect(rx + 1, ry + 1, PMD_AC::CELL_W - 2,
                      PMD_AC::CELL_H - 2,
                      Color.new(shade, shade + 10, shade + 15, 180))
        zone_color = x <= PMD_AC::ALLY_DEPLOY_MAX_X ?
                     Color.new(55, 125, 190, 26) :
                     Color.new(180, 65, 65, 24)
        bmp.fill_rect(rx + 2, ry + 2, PMD_AC::CELL_W - 4,
                      PMD_AC::CELL_H - 4, zone_color)
        bmp.fill_rect(rx, ry, PMD_AC::CELL_W, 1,
                      Color.new(135, 150, 165, 120))
        bmp.fill_rect(rx, ry, 1, PMD_AC::CELL_H,
                      Color.new(135, 150, 165, 120))
      end
    end
    divider_x = PMD_AC::GRID_X + 3 * PMD_AC::CELL_W
    bmp.fill_rect(divider_x - 2, PMD_AC::GRID_Y, 4, board_h,
                  Color.new(230, 230, 230, 100))
  end

  def create_header
    @header_sprite = Sprite.new(@viewport)
    @header_sprite.bitmap = Bitmap.new(Graphics.width, 68)
  end

  def refresh_header
    return if @header_sprite == nil
    bmp = @header_sprite.bitmap
    bmp.clear
    bmp.fill_rect(0, 0, Graphics.width, 68, Color.new(0, 0, 0, 180))
    bmp.font.size = 22
    bmp.font.bold = true
    bmp.font.color = Color.new(255, 255, 255)
    bmp.draw_text(16, 4, Graphics.width - 32, 26,
                  "PMD 自走棋原型 v0.15", 1)
    bmp.font.size = 16
    bmp.font.bold = false
    bmp.font.color = Color.new(210, 220, 230)
    text = ""
    if @phase == :deploy
      text = "戰前布陣｜S 驗證模式：" + verification_mode_label +
             "｜Shift 開戰"
    elsif @phase == :battle
      text = "AI Framework／Pixel Movement｜速度 x" + @battle_speed.to_s +
             "｜A 鍵切換｜B 離開"
    else
      text = "戰鬥結束｜C 回到布陣｜B 離開"
    end
    bmp.draw_text(16, 32, Graphics.width - 32, 24, text, 1)
  end

  def create_footer
    @footer_sprite = Sprite.new(@viewport)
    @footer_sprite.bitmap = Bitmap.new(Graphics.width, 52)
    @footer_sprite.y = Graphics.height - 52
    @footer_sprite.z = 8800
  end

  def refresh_footer
    return if @footer_sprite == nil
    bmp = @footer_sprite.bitmap
    bmp.clear
    bmp.fill_rect(0, 0, Graphics.width, 52, Color.new(0, 0, 0, 205))
    bmp.font.size = 15
    bmp.font.bold = false
    bmp.font.color = Color.new(235, 240, 245)

    if @phase == :deploy
      unit = @selected_unit
      unit = unit_at(@deploy_cursor.cell_x, @deploy_cursor.cell_y) if unit == nil
      line1 = "空白棋格"
      if unit != nil
        line1 = unit.name + "  HP " + unit.maxhp.to_s +
                "  ATK " + unit.atk.to_s +
                "  DEF " + unit.defense.to_s +
                "  " + unit.role_label + "／" + unit.range_label +
                "  AI：" + unit.movement_policy_label + "／" +
                unit.target_policy_label
      end
      if @selected_unit != nil
        line2 = "已選取 " + @selected_unit.name +
                "｜C 放置／交換｜S " + verification_mode_label +
                "｜B 取消｜Shift 開戰"
      else
        line2 = "方向鍵移動｜C 選取｜S 驗證：" +
                verification_mode_label + "｜Shift 開戰｜B 離開"
      end
      bmp.draw_text(10, 2, Graphics.width - 20, 22, line1, 0)
      bmp.font.color = Color.new(170, 220, 255)
      bmp.draw_text(10, 25, Graphics.width - 20, 22, line2, 0)
    elsif @phase == :battle
      allies = living_units(:ally).size
      enemies = living_units(:enemy).size
      bmp.draw_text(10, 2, Graphics.width - 20, 22,
                    "藍方存活 " + allies.to_s +
                    "｜紅方存活 " + enemies.to_s, 0)
      bmp.font.color = Color.new(170, 220, 255)
      bmp.draw_text(10, 25, Graphics.width - 20, 22,
                    "AI策略／威脅反應｜落空 " + @miss_count.to_s +
                    " 次｜A x1／x2｜" + verification_mode_label, 0)
    else
      bmp.draw_text(10, 8, Graphics.width - 20, 30,
                    @result_text + "｜C 回到布陣｜B 離開", 1)
    end
  end

  def create_units
    @units = []
    id = 0
    for entry in PMD_AC::ALLY_SETUP
      unit = Game_PMDChessUnit.new(id, entry[0], :ally, entry[1], entry[2])
      unit.scene = self
      @units.push(unit)
      id += 1
    end
    for entry in PMD_AC::ENEMY_SETUP
      unit = Game_PMDChessUnit.new(id, entry[0], :enemy, entry[1], entry[2])
      unit.scene = self
      @units.push(unit)
      id += 1
    end
    @next_unit_id = id
  end

  def create_unit_sprites
    @unit_sprites = []
    for unit in @units
      @unit_sprites.push(Sprite_PMDChessUnit.new(@viewport, unit))
    end
  end

  def create_deploy_cursor
    @deploy_cursor = Sprite_PMDDeployCursor.new(@viewport)
    first = living_units(:ally)[0]
    @deploy_cursor.move_to(first.cell_x, first.cell_y) if first != nil
  end

  def refresh_selected_sprites
    return if @unit_sprites == nil
    for sprite in @unit_sprites
      sprite.selected = (sprite.unit == @selected_unit)
    end
    @deploy_cursor.selected_mode = (@selected_unit != nil) if @deploy_cursor != nil
  end

  def update_unit_sprites
    for sprite in @unit_sprites
      sprite.update
    end
  end

  def dispose_unit_sprites
    return if @unit_sprites == nil
    for sprite in @unit_sprites
      sprite.dispose unless sprite.disposed?
    end
    @unit_sprites.clear
  end

  def update_effect_sprites
    return if @effect_sprites == nil
    alive = []
    for sprite in @effect_sprites
      sprite.update
      if sprite.finished
        sprite.dispose unless sprite.disposed?
      else
        alive.push(sprite)
      end
    end
    @effect_sprites = alive
  end

  def dispose_effect_sprites
    return if @effect_sprites == nil
    for sprite in @effect_sprites
      sprite.dispose unless sprite.disposed?
    end
    @effect_sprites.clear
  end

  def update_projectile_sprites
    return if @projectile_sprites == nil
    alive = []
    for sprite in @projectile_sprites
      sprite.update
      if sprite.finished
        sprite.dispose unless sprite.disposed?
      else
        alive.push(sprite)
      end
    end
    @projectile_sprites = alive
  end

  def dispose_projectile_sprites
    return if @projectile_sprites == nil
    for sprite in @projectile_sprites
      sprite.dispose unless sprite.disposed?
    end
    @projectile_sprites.clear
  end

  #--------------------------------------------------------------------------
  # ● v0.11.1 Summoned Unit
  #--------------------------------------------------------------------------
  def summoned_units(team = nil)
    result = []
    for unit in @units
      next unless unit.summoned?
      next unless unit.alive?
      next if team != nil && unit.team != team
      result.push(unit)
    end
    return result
  end

  def core_living_units(team)
    result = []
    for unit in @units
      next unless unit.team == team && unit.alive?
      next unless unit.counts_for_victory?
      result.push(unit)
    end
    return result
  end

  def summon_unit(owner, key, x, y, options = nil)
    return nil if owner == nil || owner.dead?
    return nil if PMD_AC::UNIT_DATA[key] == nil
    options = {} if options == nil

    if summoned_units(owner.team).size >= PMD_AC::SUMMON_MAX_PER_TEAM
      log_event(:summon,
                owner.log_name + " SUMMON_REJECT key=" + key.to_s +
                " reason=team_limit")
      return nil
    end

    @next_unit_id = @units.size if @next_unit_id == nil
    unit = Game_PMDChessUnit.new(
      @next_unit_id, key, owner.team,
      PMD_AC.pixel_to_cell_x(x), PMD_AC.pixel_to_cell_y(y))
    @next_unit_id += 1
    unit.scene = self
    unit.configure_as_summon(owner, options)
    unit.deploy_to_pixel(x, y)
    unit.start_combat

    @units.push(unit)
    @unit_sprites.push(Sprite_PMDChessUnit.new(@viewport, unit))

    log_event(:summon,
              owner.log_name + " SPAWN " + unit.log_name +
              " uid=" + unit.instance_uid.to_s +
              " species_key=" + unit.species_key.to_s +
              " pmd=" + unit.species.to_s +
              " hp=" + unit.hp.to_s + "/" + unit.maxhp.to_s +
              " dur=" + unit.summon_remaining.to_s +
              " skill=" + (unit.summon_allow_skill? ? "on" : "off") +
              " victory=0")
    return unit
  end

  def expire_summoned_unit(unit, reason = :duration)
    return if unit == nil || unit.dead? || !unit.summoned?
    return if unit.summon_remove_scheduled?

    # Duration / Owner Dead 是「召喚解除」，不是 HP=0 的死亡。
    unit.mark_summon_expiring
    log_event(:summon_expire,
              unit.log_name + " reason=" + reason.to_s)

    # 小型消散效果，不留下 Faint Corpse。
    add_vfx_impact_xy(unit.pixel_x, unit.pixel_y, :impact)
    schedule_summon_removal(unit, reason, 0)
  end

  def schedule_summon_removal(unit, reason, delay = 0)
    return if unit == nil || !unit.summoned?
    return if unit.summon_remove_scheduled?

    @summon_removal_queue = [] if @summon_removal_queue == nil
    unit.mark_summon_remove_scheduled
    @summon_removal_queue.push({
      :unit => unit,
      :reason => reason,
      :frames => [delay.to_i, 0].max
    })
  end

  def update_summon_removal_queue
    return if @summon_removal_queue == nil ||
              @summon_removal_queue.empty?

    pending = []
    for entry in @summon_removal_queue
      unit = entry[:unit]
      next if unit == nil

      frames = entry[:frames].to_i
      if frames > 0
        entry[:frames] = frames - 1
        pending.push(entry)
      else
        remove_summoned_unit(unit, entry[:reason])
      end
    end
    @summon_removal_queue = pending
  end

  def remove_summoned_unit(unit, reason = :removed)
    return if unit == nil

    # 先把所有指向這隻召喚物的戰鬥引用清掉。
    for other in @units
      next if other == unit
      other.clear_reference_to(unit)
    end

    release_attack_slot(unit)

    # Dispose 對應 Unit Sprite，包含 HP / Energy / Status / Popup 等附屬 Sprite。
    if @unit_sprites != nil
      survivors = []
      for sprite in @unit_sprites
        if sprite.unit == unit
          sprite.dispose unless sprite.disposed?
        else
          survivors.push(sprite)
        end
      end
      @unit_sprites = survivors
    end

    @units.delete(unit)

    log_event(:summon_remove,
              unit.log_name +
              " reason=" + reason.to_s +
              " units_left=" + @units.size.to_s)
  end

  def summon_in_scene?(unit)
    return false if unit == nil
    return @units.include?(unit)
  end

  def summon_from_effect(user, target, effect)
    key = effect[:unit]
    return nil if key == nil

    placement = effect[:placement] || :self
    x = user.pixel_x
    y = user.pixel_y
    if placement == :target && target != nil
      x = target.pixel_x
      y = target.pixel_y
    elsif placement == :midpoint && target != nil
      x = (user.pixel_x + target.pixel_x) / 2.0
      y = (user.pixel_y + target.pixel_y) / 2.0
    end

    x += (effect[:offset_x] || 0).to_f
    y += (effect[:offset_y] || 0).to_f

    options = {
      :duration => effect[:duration],
      :hp_scale => effect[:hp_scale],
      :stat_scale => effect[:stat_scale],
      :move_speed_scale => effect[:move_speed_scale],
      :allow_skill => effect[:allow_skill],
      :expire_with_owner => effect.has_key?(:expire_with_owner) ?
                            effect[:expire_with_owner] : true,
      :name_prefix => effect.has_key?(:name_prefix) ?
                      effect[:name_prefix] : "召喚"
    }
    return summon_unit(user, key, x, y, options)
  end

  #--------------------------------------------------------------------------
  # ● v0.11.1 Substitute
  #--------------------------------------------------------------------------
  def substitute_for(owner)
    return nil if owner == nil
    for obj in battle_objects
      next unless obj.alive? && obj.targetable?
      next unless obj.intercept_owner?
      next unless obj.owner == owner
      dist = PMD_AC.distance(owner.pixel_x, owner.pixel_y,
                             obj.pixel_x, obj.pixel_y)
      next if dist > obj.intercept_radius
      return obj
    end
    return nil
  end

  def substitute_target_for(attacker, intended_target, source_type = :direct)
    return intended_target if attacker == nil || intended_target == nil
    if intended_target.respond_to?(:battle_object?) &&
       intended_target.battle_object?
      return intended_target
    end
    return intended_target unless intended_target.is_a?(Game_PMDChessUnit)

    obj = substitute_for(intended_target)
    return intended_target if obj == nil

    log_event(:substitute,
              intended_target.log_name + " PROTECTED_BY " + obj.log_name +
              " from=" + attacker.log_name +
              " type=" + source_type.to_s)
    return obj
  end

  def pay_hp_cost(unit, ratio)
    return false if unit == nil || unit.dead?
    ratio = ratio.to_f
    return true if ratio <= 0.0
    cost = [(unit.maxhp * ratio).floor, 1].max
    return unit.pay_hp_cost(cost)
  end

  #--------------------------------------------------------------------------
  # ● v0.11 Battle Object
  #--------------------------------------------------------------------------
  def battle_objects
    return @battle_objects || []
  end

  def attack_targets_of(unit)
    result = enemies_of(unit)
    for obj in battle_objects
      next unless obj.targetable?
      next if obj.team == unit.team
      result.push(obj)
    end
    return result
  end

  def create_battle_object(owner, key, x, y, overrides = nil)
    @battle_objects = [] if @battle_objects == nil
    @battle_object_sprites = [] if @battle_object_sprites == nil
    @next_battle_object_id = 0 if @next_battle_object_id == nil

    if @battle_objects.size >= PMD_AC::BATTLE_OBJECT_MAX
      log_event(:object_spawn,
                "REJECT key=" + key.to_s + " reason=max_objects")
      return nil
    end

    base = PMD_AC::BATTLE_OBJECT_DATA[key]
    if base == nil
      log_event(:object_spawn,
                "REJECT key=" + key.to_s + " reason=unknown_template")
      return nil
    end

    data = base.merge(overrides || {})
    x = PMD_AC.clamp(x.to_f,
                     PMD_AC::BOARD_LEFT.to_f,
                     PMD_AC::BOARD_RIGHT.to_f)
    y = PMD_AC.clamp(y.to_f,
                     PMD_AC::BOARD_TOP.to_f,
                     PMD_AC::BOARD_BOTTOM.to_f)

    id = PMD_AC::BATTLE_OBJECT_ID_BASE + @next_battle_object_id
    @next_battle_object_id += 1
    obj = Game_PMDBattleObject.new(self, id, owner, key, x, y, data)
    @battle_objects.push(obj)
    @battle_object_sprites.push(
      Sprite_PMDBattleObject.new(@viewport, obj))

    owner_name = owner == nil ? "SYSTEM" : owner.log_name
    log_event(:object_spawn,
              obj.log_name +
              " kind=" + obj.kind.to_s +
              " team=" + obj.team.to_s +
              " pos=(" + x.round.to_s + "," + y.round.to_s + ")" +
              " owner=" + owner_name +
              " targetable=" + (obj.targetable? ? "1" : "0"))

    PMD_AC.play_se(data[:spawn_se])
    return obj
  end

  def create_battle_object_from_effect(user, target, effect)
    key = effect[:object]
    return nil if key == nil

    if effect[:hp_cost_ratio] != nil
      unless pay_hp_cost(user, effect[:hp_cost_ratio])
        log_event(:object_spawn,
                  user.log_name + " REJECT key=" + key.to_s +
                  " reason=hp_cost")
        return nil
      end
    end

    placement = effect[:placement] || :target
    x = user.pixel_x
    y = user.pixel_y

    case placement
    when :self
      x = user.pixel_x
      y = user.pixel_y
    when :target
      if target != nil
        x = target.pixel_x
        y = target.pixel_y
      end
    when :midpoint
      if target != nil
        x = (user.pixel_x + target.pixel_x) / 2.0
        y = (user.pixel_y + target.pixel_y) / 2.0
      end
    end

    x += (effect[:offset_x] || 0).to_f
    y += (effect[:offset_y] || 0).to_f

    overrides = effect[:object_data] || {}
    return create_battle_object(user, key, x, y, overrides)
  end

  def update_battle_objects
    return if @battle_objects == nil
    alive = []
    for obj in @battle_objects
      obj.update
      alive.push(obj) unless obj.expired?
    end
    @battle_objects = alive
  end

  def update_battle_object_sprites
    return if @battle_object_sprites == nil
    alive = []
    for sprite in @battle_object_sprites
      if sprite.object.expired?
        sprite.dispose unless sprite.disposed?
      else
        sprite.update
        alive.push(sprite)
      end
    end
    @battle_object_sprites = alive
  end

  def dispose_battle_object_sprites
    return if @battle_object_sprites == nil
    for sprite in @battle_object_sprites
      sprite.dispose unless sprite.disposed?
    end
    @battle_object_sprites.clear
  end

  def clear_battle_objects(reason = :clear)
    return if @battle_objects == nil
    for obj in @battle_objects
      obj.expire(reason) unless obj.expired?
    end
    @battle_objects.clear
  end

  def expire_battle_object(obj, reason)
    return if obj == nil || obj.expired?
    obj.expire(reason)
    log_event(:object_expire,
              obj.log_name + " reason=" + reason.to_s)
  end

  def destroy_battle_object(obj, source = nil)
    return if obj == nil || obj.expired?
    src = source == nil ? "SYSTEM" : source.log_name
    log_event(:object_destroy,
              obj.log_name + " by=" + src)

    if obj.detonate_on_destroy? && !obj.triggered
      trigger_battle_object(obj, :destroy)
    end

    PMD_AC.play_se(obj.config[:destroy_se])
    expire_battle_object(obj, :destroyed) unless obj.expired?
  end

  def update_battle_object_logic(obj)
    return if obj == nil || obj.expired?

    case obj.kind
    when :trap
      if obj.armed? && !obj.triggered
        target = nearest_object_trigger_target(obj)
        if target != nil
          log_event(:object_trigger,
                    obj.log_name + " PROXIMITY target=" +
                    target.log_name)
          trigger_battle_object(obj, :proximity)
        end
      end

    when :bomb, :delayed
      if !obj.triggered && obj.trigger_due?
        trigger_battle_object(obj, :countdown)
      end

    when :totem
      if obj.tick_due?
        obj.reset_tick
        tick_battle_object(obj)
      end
    end
  end

  def nearest_object_trigger_target(obj)
    candidates = object_scope_units(obj)
    best = nil
    best_dist = nil
    for unit in candidates
      dist = PMD_AC.distance(obj.pixel_x, obj.pixel_y,
                             unit.pixel_x, unit.pixel_y)
      next if dist > obj.trigger_radius + unit.collision_radius
      if best == nil || dist < best_dist
        best = unit
        best_dist = dist
      end
    end
    return best
  end

  def object_scope_units(obj)
    case obj.scope
    when :allies
      return living_units(obj.team)
    when :both
      return @units.find_all { |u| u.alive? }
    else # :enemies
      return living_units(obj.team == :ally ? :enemy : :ally)
    end
  end

  def object_effect_targets(obj)
    result = []
    for unit in object_scope_units(obj)
      dist = PMD_AC.distance(obj.pixel_x, obj.pixel_y,
                             unit.pixel_x, unit.pixel_y)
      if dist <= obj.effect_radius + unit.collision_radius
        result.push(unit)
      end
    end
    return result
  end

  def trigger_battle_object(obj, reason = :trigger)
    return if obj == nil || obj.expired? || obj.triggered
    obj.mark_triggered

    targets = object_effect_targets(obj)
    names = targets.collect { |u| u.log_name }.join(",")
    log_event(:object_trigger,
              obj.log_name +
              " reason=" + reason.to_s +
              " radius=" + obj.effect_radius.round.to_s +
              " hits=[" + names + "]")

    PMD_AC.play_se(obj.config[:trigger_se])
    add_vfx_impact_xy(obj.pixel_x, obj.pixel_y,
                      object_vfx_style(obj))

    for target in targets
      source = obj.owner
      next if source == nil
      data = {
        :effects => obj.effects,
        :can_crit => false,
        :directional => false
      }
      apply_skill_effects(source, target, data, 1.0)
    end

    if [:trap, :bomb, :delayed].include?(obj.kind)
      expire_battle_object(obj, :triggered)
    end
  end

  def tick_battle_object(obj)
    return if obj == nil || obj.expired?
    targets = object_effect_targets(obj)
    names = targets.collect { |u| u.log_name }.join(",")
    log_event(:object_tick,
              obj.log_name +
              " hits=[" + names + "]")

    for target in targets
      source = obj.owner
      next if source == nil
      data = {
        :effects => obj.effects,
        :can_crit => false,
        :directional => false
      }
      apply_skill_effects(source, target, data, 1.0)
    end
  end

  def object_vfx_style(obj)
    case obj.style
    when :bomb
      return :fire
    when :trap
      return :web
    when :totem
      return :electric
    when :decoy
      return :seed
    else
      return :impact
    end
  end

  def add_skill_effect(target, type, delay = 0)
    return if target == nil

    # MISS 保留文字提示；其他技能視覺統一走 PMD Animations。
    if type == :miss
      x, y = effect_anchor_xy(target, false)
      @effect_sprites.push(Sprite_PMDChessEffect.new(
        @viewport, x, y + 24, :miss, delay))
      return
    end

    key = PMD_AC.vfx_event_key(type)
    @vfx_event_recent = {} if @vfx_event_recent == nil
    target_id = target.respond_to?(:id) ? target.id : target.object_id
    cache_key = [target_id, key]
    now = Graphics.frame_count
    last = @vfx_event_recent[cache_key]
    if last != nil && now - last < PMD_AC::PMD_VFX_EVENT_DEDUP_FRAMES
      return
    end
    @vfx_event_recent[cache_key] = now

    x, y = effect_anchor_xy(target, false)
    add_vfx_event_xy(x, y, type, delay)
  end

  def add_effect_xy(x, y, type, delay = 0)
    if type == :miss
      @effect_sprites.push(Sprite_PMDChessEffect.new(
        @viewport, x, y + 24, :miss, delay))
    else
      add_vfx_event_xy(x, y, type, delay)
    end
  end

  def add_vfx_event_xy(x, y, type, delay = 0)
    layers = PMD_AC.vfx_event_layers(type)
    return if layers == nil || layers.empty?
    for layer in layers
      extra_delay = (layer[:delay] || 0).to_i
      add_vfx_burst_xy(x, y, layer, delay.to_i + extra_delay)
    end
  end

  def add_cast_effect(unit)
    return if unit == nil
    # 施法動畫直接使用該單位屬性的 PMD muzzle，不再使用旋轉放大框。
    add_vfx_muzzle(unit, unit.projectile_style)
  end

  def add_link_effect(x1, y1, x2, y2, type = :electric, delay = 0)
    @effect_sprites.push(Sprite_PMDLinkEffect.new(
      @viewport, x1, y1, x2, y2, type, delay))
  end

  # v0.9.1.3
  # Chain / Link 類視覺直接連接 PMD Sprite 幾何中心。
  def add_unit_link_effect(source, target, type = :electric, delay = 0)
    return if source == nil || target == nil
    x1, y1 = effect_anchor_xy(source, true)
    x2, y2 = effect_anchor_xy(target, false)
    log_event(:vfx_link_anchor,
      source.log_name + " LINK style=" + type.to_s +
      " src=(" + x1.round.to_s + "," + y1.round.to_s + ")" +
      " dst=(" + x2.round.to_s + "," + y2.round.to_s + ")" +
      " target=" + target.log_name)
    add_link_effect(x1, y1, x2, y2, type, delay)
  end

  def effect_anchor_xy(obj, source_side = false)
    if obj.is_a?(Array)
      return [obj[0].to_f, obj[1].to_f]
    end
    return [0.0, 0.0] if obj == nil
    return [obj.visual_center_x.to_f, obj.visual_center_y.to_f]
  end

  def add_vfx_burst_xy(x, y, profile, delay = 0)
    return if profile == nil
    @effect_sprites.push(Sprite_PMDVFXBurst.new(@viewport, x, y, profile, delay))
  end

  def add_vfx_muzzle(obj, style)
    profile = PMD_AC.vfx_profile(style)
    return if profile == nil || profile[:muzzle] == nil
    x, y = effect_anchor_xy(obj, true)
    add_vfx_burst_xy(x, y, profile[:muzzle], 0)
  end

  def add_vfx_impact(obj, style, delay = 0)
    return if obj == nil
    x, y = effect_anchor_xy(obj, false)
    add_vfx_impact_xy(x, y, style, delay)
  end

  def add_vfx_impact_xy(x, y, style, delay = 0)
    layers = PMD_AC.vfx_impact_layers(style)
    return if layers == nil || layers.empty?
    for layer in layers
      extra_delay = (layer[:delay] || 0).to_i
      add_vfx_burst_xy(x, y, layer, delay.to_i + extra_delay)
    end
  end

  def add_vfx_column(obj, style, delay = 0)
    profile = PMD_AC.vfx_profile(style)
    return if profile == nil || profile[:column] == nil
    x, y = effect_anchor_xy(obj, false)
    add_vfx_burst_xy(x, y, profile[:column], delay)
  end

  def add_beam_effect(source, target, style = :light, life = nil, width = nil)
    life = PMD_AC::BEAM_DEFAULT_LIFE if life == nil
    width = PMD_AC::BEAM_DEFAULT_WIDTH if width == nil
    src_anchor = effect_anchor_xy(source, true)
    dst_anchor = effect_anchor_xy(target, false)
    src_name = source.respond_to?(:log_name) ? source.log_name : "POINT"
    dst_name = target.respond_to?(:log_name) ? target.log_name : "POINT"
    log_event(:vfx_anchor,
      src_name + " BEAM style=" + style.to_s +
      " src=(" + src_anchor[0].round.to_s + "," + src_anchor[1].round.to_s + ")" +
      " dst=(" + dst_anchor[0].round.to_s + "," + dst_anchor[1].round.to_s + ")" +
      " target=" + dst_name)
    add_vfx_muzzle(source, style)
    add_vfx_impact(target, style, [life.to_i - PMD_AC::PMD_VFX_BEAM_IMPACT_DELAY, 0].max)
    @effect_sprites.push(Sprite_PMDArenaBeam.new(
      @viewport, source, target, style, life, width))
  end

  def add_column_effect(target, style = :water, life = 26)
    return if target == nil
    # v0.9.1.5：只保留 PMD sheet Column。
    # 舊 Sprite_PMDArenaColumn 36x72 自繪光柱不再疊加。
    add_vfx_column(target, style)
  end

  def add_sustained_beam(user, target, data)
    style = data[:beam_style] || user.projectile_style
    add_vfx_muzzle(user, style)
    add_vfx_impact(target, style, 6)
    @effect_sprites.push(Sprite_PMDSustainedBeam.new(
      @viewport, self, user, target, data))
  end

  def add_sweeping_beam(user, target, data)
    style = data[:beam_style] || user.projectile_style
    add_vfx_muzzle(user, style)
    @effect_sprites.push(Sprite_PMDSweepingBeam.new(
      @viewport, self, user, target, data))
  end

  #--------------------------------------------------------------------------
  # ● v0.9 Zone / Aura
  #--------------------------------------------------------------------------
  def add_zone(owner, data)
    return if owner == nil || data == nil
    x = (data[:x] || owner.pixel_x).to_f
    y = (data[:y] || owner.pixel_y).to_f
    radius = (data[:radius] || 70.0).to_f
    duration = (data[:duration] || PMD_AC::ZONE_DEFAULT_DURATION).to_i
    interval = (data[:interval] || PMD_AC::ZONE_DEFAULT_INTERVAL).to_i
    sprite = Sprite_PMDArenaZone.new(
      @viewport, x, y, radius, data[:style] || :neutral, duration)
    zone = {
      :owner => owner,
      :x => x, :y => y,
      :radius => radius,
      :remaining => duration,
      :interval => [interval, 1].max,
      :tick => 1,
      :scope => data[:scope] || :enemies,
      :harmful => data[:harmful] ? true : false,
      :follow_owner => data[:follow_owner] ? true : false,
      :style => data[:style] || :neutral,
      :effects => data[:effects] || [],
      :sprite => sprite
    }
    @zones.push(zone)
    @effect_sprites.push(sprite)
    log_event(:zone, owner.log_name + " CREATE style=" +
              zone[:style].to_s + " radius=" + radius.round.to_s +
              " dur=" + duration.to_s)
  end

  def zone_units(zone)
    owner = zone[:owner]
    return [] if owner == nil
    case zone[:scope]
    when :allies
      return living_units(owner.team)
    when :all
      return @units.find_all { |u| u.alive? }
    else
      return enemies_of(owner)
    end
  end

  def update_zones
    return if @zones == nil || @zones.empty?
    alive = []
    for zone in @zones
      owner = zone[:owner]
      if zone[:follow_owner]
        if owner == nil || owner.dead?
          zone[:remaining] = 0
        else
          zone[:x] = owner.pixel_x.to_f
          zone[:y] = owner.pixel_y.to_f
          sprite = zone[:sprite]
          sprite.move_to(zone[:x], zone[:y]) if
            sprite != nil && !sprite.disposed?
        end
      end

      zone[:remaining] -= 1
      zone[:tick] -= 1
      if zone[:tick] <= 0
        hit_names = []
        temp = {:effects => zone[:effects], :can_crit => false, :directional => false}
        for unit in zone_units(zone)
          distance = PMD_AC.distance(zone[:x], zone[:y],
                                     unit.pixel_x, unit.pixel_y)
          next if distance > zone[:radius] + unit.collision_radius
          apply_skill_effects(zone[:owner], unit, temp, 1.0)
          hit_names.push(unit.log_name)
        end
        unless hit_names.empty?
          log_event(:zone_tick, zone[:owner].log_name + " " +
                    zone[:style].to_s + " hits=[" +
                    hit_names.join(",") + "]")
        end
        zone[:tick] = zone[:interval]
      end
      alive.push(zone) if zone[:remaining] > 0
      if zone[:remaining] <= 0
        log_event(:zone, zone[:owner].log_name + " END style=" +
                  zone[:style].to_s)
      end
    end
    @zones = alive
  end

  def zone_avoidance_vector(unit)
    return [0.0, 0.0] if @zones == nil || @zones.empty?
    return [0.0, 0.0] if unit == nil || unit.dead?
    return [0.0, 0.0] if unit.movement_policy == :berserker
    fx = 0.0
    fy = 0.0
    for zone in @zones
      next unless zone[:harmful]
      owner = zone[:owner]
      next if owner == nil || owner.team == unit.team
      dx = unit.pixel_x - zone[:x]
      dy = unit.pixel_y - zone[:y]
      distance = Math.sqrt(dx * dx + dy * dy)
      danger = zone[:radius] + unit.collision_radius + 18.0
      next if distance >= danger
      if distance <= 0.001
        dx = unit.team == :ally ? -1.0 : 1.0
        dy = 0.0
        distance = 1.0
      end
      ratio = (danger - distance) / danger
      fx += dx / distance * ratio * PMD_AC::ZONE_AVOID_STRENGTH
      fy += dy / distance * ratio * PMD_AC::ZONE_AVOID_STRENGTH
    end
    if fx.abs > 0.05 || fy.abs > 0.05
      @zone_avoid_log_frames = {} if @zone_avoid_log_frames == nil
      last = @zone_avoid_log_frames[unit.id] || -9999
      now = Graphics.frame_count
      if now - last >= 30
        @zone_avoid_log_frames[unit.id] = now
        log_event(:zone_avoid,
                  unit.log_name +
                  " vec=(" + sprintf("%.2f", fx) + "," +
                  sprintf("%.2f", fy) + ")")
      end
    end
    return [fx, fy]
  end

  def update_auras
    for source in @units
      next if source.dead?
      raw = source.aura_data
      next if raw == nil
      auras = raw.is_a?(Array) ? raw : [raw]
      for aura in auras
        radius = (aura[:radius] || 80.0).to_f
        status = aura[:status]
        next if status == nil
        targets = aura[:target] == :enemies ?
                  enemies_of(source) : living_units(source.team)
        for target in targets
          distance = source.distance_to(target)
          next if distance > radius + target.collision_radius
          was = target.status?(status)
          target.apply_status(status, {
            :duration => PMD_AC::AURA_REFRESH_INTERVAL * 3,
            :value => aura[:value] || 0,
            :stack_mode => aura[:stack_mode] || :replace_stronger,
            :silent_refresh => true
          }, source)
          unless was
            log_event(:aura, source.log_name + " -> " + target.log_name +
                      " " + status.to_s)
          end
        end
      end
    end
  end

  def register_miss(user, target)
    @miss_count += 1
    user_name = user == nil ? "UNKNOWN" : user.log_name
    target_name = target == nil ? "UNKNOWN" : target.log_name
    log_event(:miss, user_name + " MISS -> " + target_name)
    if target != nil
      add_skill_effect(target, :miss)
    elsif user != nil
      add_skill_effect(user, :miss)
    end
    refresh_footer
  end

  def register_impact(value)
    power = value.to_i >= 120 ? 4 : (value.to_i >= 70 ? 3 : 2)
    @shake_power = [@shake_power, power].max
    @shake_frames = [@shake_frames, power + 2].max
  end

  def update_camera_shake
    return unless viewport_available?
    if @shake_frames > 0
      @shake_frames -= 1
      power = [@shake_power, PMD_AC::CAMERA_SHAKE_MAX].min
      phase = Graphics.frame_count % 4
      @viewport.ox = phase == 0 ? -power : (phase == 2 ? power : 0)
      @viewport.oy = phase == 1 ? -1 : (phase == 3 ? 1 : 0)
    else
      @viewport.ox = 0
      @viewport.oy = 0
      @shake_power = 0
    end
  end

  # RGSS2 的 Viewport 沒有 Sprite/Bitmap 那種 disposed? 查詢方法。
  # 因此由 Scene 自己記錄是否已釋放，避免使用 RGSS3 式 API。
  def viewport_available?
    return false if @viewport == nil
    return false if @viewport_disposed
    return true
  end

  def dispose_viewport
    return if @viewport == nil
    return if @viewport_disposed
    begin
      @viewport.ox = 0
      @viewport.oy = 0
    rescue
    end
    @viewport.dispose
    @viewport_disposed = true
  end

  def dispose_sprite(sprite)
    return if sprite == nil
    if sprite.bitmap != nil && !sprite.bitmap.disposed?
      sprite.bitmap.dispose
    end
    sprite.dispose unless sprite.disposed?
  end

  def living_units(team)
    result = []
    for unit in @units
      result.push(unit) if unit.team == team && unit.alive?
    end
    return result
  end

  def unit_at(x, y)
    for unit in @units
      return unit if unit.alive? && unit.cell_x == x && unit.cell_y == y
    end
    return nil
  end

  def enemies_of(unit)
    return living_units(unit.team == :ally ? :enemy : :ally)
  end

  def allies_of(unit)
    return living_units(unit.team)
  end

  def enemy_cluster_size(user, center, radius)
    count = 0
    for enemy in enemies_of(user)
      distance = PMD_AC.distance(center.pixel_x, center.pixel_y,
                                 enemy.pixel_x, enemy.pixel_y)
      count += 1 if distance <= radius + enemy.collision_radius
    end
    return count
  end

  def projectile_style(user, kind, effect_type)
    return :neutral if user == nil
    return user.projectile_style
  end

  def impact_effect_for(projectile)
    case projectile.style
    when :water then return :water
    when :web then return :web
    when :electric then return :electric
    when :fire then return :fire
    when :seed then return :seed
    else return :impact
    end
  end

  #--------------------------------------------------------------------------
  # ● v0.9 Bodyguard Projectile Intercept
  #--------------------------------------------------------------------------
  def projectile_interceptor_for(projectile, x1, y1, x2, y2)
    return nil if projectile == nil || projectile.target == nil
    original = projectile.target
    user = projectile.user
    return nil if user == nil
    candidates = []
    for unit in living_units(original.team)
      next if unit == original
      next unless unit.projectile_intercept?
      next if PMD_AC.distance(unit.pixel_x, unit.pixel_y,
                              original.pixel_x, original.pixel_y) >
              unit.projectile_intercept_radius
      dist, t = point_segment_distance(unit.pixel_x, unit.pixel_y,
                                       x1, y1, x2, y2)
      radius = unit.collision_radius + projectile.radius.to_f
      next if dist > radius || t < 0.0 || t > 1.0
      candidates.push([t, unit])
    end
    return nil if candidates.empty?
    candidates.sort! { |a, b| a[0] <=> b[0] }
    return candidates[0][1]
  end

  #--------------------------------------------------------------------------
  # ● Pixel Movement：軟碰撞
  #--------------------------------------------------------------------------
  def separation_vector(unit)
    return [0.0, 0.0] if unit.dead? || unit.acting?
    force_x = 0.0
    force_y = 0.0
    for other in @units
      next if other == unit || other.dead?
      dx = unit.pixel_x - other.pixel_x
      dy = unit.pixel_y - other.pixel_y
      distance_sq = dx * dx + dy * dy
      minimum = unit.collision_radius + other.collision_radius + 2.0
      next if distance_sq >= minimum * minimum
      if distance_sq <= 0.001
        angle_index = (unit.id * 3 + other.id * 5) % 8
        vector = PMD_AC::ATTACK_SLOT_VECTORS[angle_index]
        dx = vector[0]
        dy = vector[1]
        distance = 1.0
      else
        distance = Math.sqrt(distance_sq)
      end
      overlap = (minimum - distance) / minimum
      strength = unit.team == other.team ? 1.15 : 1.75
      # 攻擊中的對手視為較穩定，不讓周圍單位把它像冰壺一樣推走。
      strength *= 0.65 if other.acting?
      force_x += dx / distance * overlap * strength
      force_y += dy / distance * overlap * strength
    end
    return [force_x, force_y]
  end

  #--------------------------------------------------------------------------
  # ● Pixel Movement：近戰攻擊槽
  #--------------------------------------------------------------------------
  def attack_slot_position(attacker, target)
    return nil if attacker == nil || target == nil || target.dead?
    stored = @attack_slots[attacker.id]
    if stored != nil && stored[0] == target.id
      return calculate_attack_slot_xy(attacker, target, stored[1])
    end

    used = {}
    for owner_id in @attack_slots.keys
      data = @attack_slots[owner_id]
      next if data == nil || data[0] != target.id
      used[data[1]] = true
    end

    choices = []
    for slot_index in 0...PMD_AC::ATTACK_SLOT_VECTORS.size
      next if used[slot_index]
      pos = calculate_attack_slot_xy(attacker, target, slot_index, false)
      next if pos == nil
      dx = attacker.pixel_x - pos[0]
      dy = attacker.pixel_y - pos[1]
      score = dx * dx + dy * dy
      choices.push([score, slot_index])
    end
    if choices.empty?
      for slot_index in 0...PMD_AC::ATTACK_SLOT_VECTORS.size
        pos = calculate_attack_slot_xy(attacker, target, slot_index, true)
        dx = attacker.pixel_x - pos[0]
        dy = attacker.pixel_y - pos[1]
        choices.push([dx * dx + dy * dy, slot_index])
      end
    end
    choices.sort! { |a, b| a[0] <=> b[0] }
    slot_index = choices[0][1]
    @attack_slots[attacker.id] = [target.id, slot_index]
    return calculate_attack_slot_xy(attacker, target, slot_index, true)
  end

  def calculate_attack_slot_xy(attacker, target, slot_index, clamp = true)
    vector = PMD_AC::ATTACK_SLOT_VECTORS[slot_index]
    radius = target.collision_radius + attacker.collision_radius +
             PMD_AC::ATTACK_SLOT_GAP
    x = target.pixel_x + vector[0] * radius
    y = target.pixel_y + vector[1] * radius
    if !clamp
      return nil if x < PMD_AC::BOARD_LEFT || x > PMD_AC::BOARD_RIGHT
      return nil if y < PMD_AC::BOARD_TOP || y > PMD_AC::BOARD_BOTTOM
    end
    x = PMD_AC.clamp(x, PMD_AC::BOARD_LEFT.to_f, PMD_AC::BOARD_RIGHT.to_f)
    y = PMD_AC.clamp(y, PMD_AC::BOARD_TOP.to_f, PMD_AC::BOARD_BOTTOM.to_f)
    return [x, y]
  end

  def release_attack_slot(unit)
    return if unit == nil
    @attack_slots.delete(unit.id)
  end

  def cleanup_attack_slots
    valid_ids = {}
    for unit in @units
      valid_ids[unit.id] = true if unit.alive? && unit.melee?
    end
    for owner_id in @attack_slots.keys
      data = @attack_slots[owner_id]
      target = find_unit_by_id(data[0])
      if !valid_ids[owner_id] || target == nil || target.dead?
        @attack_slots.delete(owner_id)
      end
    end
  end

  #--------------------------------------------------------------------------
  # ● v0.10 SE routing
  #--------------------------------------------------------------------------
  def play_skill_se(unit, stage, data = nil)
    return if unit == nil
    data = unit.skill_data if data == nil
    key = (stage.to_s + "_se").to_sym
    spec = data[key]
    if spec == nil
      unit_data = PMD_AC::UNIT_DATA[unit.key] || {}
      spec = unit_data[key]
    end

    # Launch / Hit 在未指定時有專案預設。
    # Cast 保持 opt-in，避免蓄力一開始就誤聽成技能已發出。
    if spec == nil
      spec = PMD_AC::DEFAULT_SKILL_LAUNCH_SE if stage == :launch
      spec = PMD_AC::DEFAULT_SKILL_HIT_SE if stage == :hit
    end

    # Chain / Pierce / AOE 同 frame 多目標只播一次 Hit。
    if stage == :hit && spec != nil
      @skill_hit_se_frames = {} if @skill_hit_se_frames == nil
      hit_key = [unit.id, unit.skill_type]
      now = Graphics.frame_count
      last = @skill_hit_se_frames[hit_key] || -9999
      return if now - last < PMD_AC::SKILL_HIT_SE_DEDUP_FRAMES
      @skill_hit_se_frames[hit_key] = now
    end

    PMD_AC.play_se(spec)
  end

  def play_basic_se(unit, stage)
    return if unit == nil
    data = PMD_AC::UNIT_DATA[unit.key] || {}
    key = ("basic_" + stage.to_s + "_se").to_sym
    PMD_AC.play_se(data[key])
  end

  def play_crit_se(unit, skill_data = nil)
    return if unit == nil
    spec = skill_data == nil ? nil : skill_data[:crit_se]
    if spec == nil
      data = PMD_AC::UNIT_DATA[unit.key] || {}
      spec = data[:crit_se]
    end
    spec = PMD_AC::DEFAULT_CRIT_SE if spec == nil
    PMD_AC.play_se(spec)
  end

  def play_evade_se(unit)
    return if unit == nil
    data = PMD_AC::UNIT_DATA[unit.key] || {}
    spec = data[:evade_se]
    spec = PMD_AC::DEFAULT_EVADE_SE if spec == nil
    PMD_AC.play_se(spec)
  end

  #--------------------------------------------------------------------------
  # ● v0.10.2 Shield Trigger routing
  #--------------------------------------------------------------------------
  def resolve_shield_trigger(unit, attacker, event, absorbed)
    return if unit == nil || unit.dead?
    effects = unit.shield_trigger_effects(event)
    return if effects == nil || effects.empty?

    log_event(:shield_trigger,
              unit.log_name + " " + event.to_s.upcase +
              " absorbed=" + absorbed.to_i.to_s +
              " remain=" + unit.shield.to_s +
              " effects=" + effects.size.to_s)

    for original in effects
      next if original == nil
      effect = original.dup
      target_rule = effect.delete(:target)
      target = unit
      target = attacker if target_rule == :attacker
      target = unit if target_rule == :self || target_rule == nil
      next if target == nil || target.dead?

      temp = {
        :effects => [effect],
        :can_crit => false,
        :directional => false
      }
      apply_skill_effects(unit, target, temp, 1.0)
    end
  end

  def find_unit_by_id(id)
    for unit in @units
      return unit if unit.id == id
    end
    if @battle_objects != nil
      for obj in @battle_objects
        return obj if obj.id == id && !obj.expired?
      end
    end
    return nil
  end

  #--------------------------------------------------------------------------
  # ● 投射物與連續命中判定
  #--------------------------------------------------------------------------
  def projectile_tracking_for(user, kind, effect_type)
    if effect_type != nil
      data = PMD_AC.skill_data(effect_type)
      level = data[:projectile_tracking]
      return level if level != nil
    end
    return user.projectile_tracking || :perfect
  end

  def launch_projectile(user, target, kind, power, effect_type,
                        tracking_override = nil, attack_modifier = nil,
                        allow_substitute = true)
    return if user == nil || target == nil || target.dead?

    if allow_substitute && [:basic, :skill_generic].include?(kind)
      target = substitute_target_for(user, target, kind)
    end

    return if target == nil || target.dead?
    tracking = tracking_override ||
               projectile_tracking_for(user, kind, effect_type)
    projectile = Sprite_PMDProjectile.new(
      @viewport, self, @next_projectile_id,
      user, target, kind, power, effect_type, tracking, attack_modifier)
    @next_projectile_id += 1
    @projectile_sprites.push(projectile)
  end

  def segment_circle_hit?(x1, y1, x2, y2, cx, cy, radius)
    vx = x2 - x1
    vy = y2 - y1
    wx = cx - x1
    wy = cy - y1
    length_sq = vx * vx + vy * vy
    if length_sq <= 0.0001
      closest_x = x1
      closest_y = y1
    else
      t = (wx * vx + wy * vy) / length_sq
      t = PMD_AC.clamp(t, 0.0, 1.0)
      closest_x = x1 + vx * t
      closest_y = y1 + vy * t
    end
    dx = cx - closest_x
    dy = cy - closest_y
    return dx * dx + dy * dy <= radius * radius
  end

  def resolve_projectile(projectile)
    user = projectile.user
    target = projectile.target
    return if user == nil
    case projectile.kind
    when :basic
      if target != nil && target.alive?
        deal_direct_damage(
          user, target, projectile.power,
          {:modifier => projectile.attack_modifier,
           :source_type => :basic})
        user.gain_energy(PMD_AC::ENERGY_ON_BASIC_HIT, target, :basic_hit)
        play_basic_se(user, :hit)
      end
    when :stun
      if target != nil && target.alive?
        deal_skill_damage(user, target, projectile.power)
        target.apply_knockback(user, 30.0) unless target.dead?
        target.apply_stun(58, user) unless target.dead?
      end
    when :aoe
      resolve_aoe_at(user, projectile.impact_x,
                     projectile.impact_y, projectile.power,
                     impact_effect_for(projectile))
    when :drain
      if target != nil && target.alive?
        add_skill_effect(target, :drain)
        damage = deal_skill_damage(user, target, projectile.power)
        user.heal(damage / 2)
        add_skill_effect(user, :drain, 5)
      end
    when :skill_generic
      if target != nil && target.alive?
        data = PMD_AC.skill_data(projectile.effect_type)
        before_hp = target.hp
        apply_skill_effects(user, target, data, 1.0)
        # 純支援／純狀態 Projectile 沒有 Direct Damage 時仍需要 Hit SE。
        if target.hp == before_hp
          play_skill_se(user, :hit, data)
        end
      end
    when :skill_aoe
      data = PMD_AC.skill_data(projectile.effect_type)
      resolve_skill_aoe(user, projectile.impact_x,
                        projectile.impact_y, data)
    else
      if target != nil && target.alive?
        add_skill_effect(target, projectile.effect_type)
        deal_skill_damage(user, target, projectile.power)
      end
    end
    refresh_footer
  end

  #--------------------------------------------------------------------------
  # ● v0.8 Skill AI / 通用技能效果
  #--------------------------------------------------------------------------
  def skill_target_for(unit)
    data = unit.skill_data
    return nil if data == nil || data.empty?
    target_type = data[:target_type] || :enemy_targeted
    policy = data[:policy] || unit.skill_policy || :current_target

    # 嘲諷只強制 enemy_targeted 類技能；Ground / Ally / Self 不受影響。
    if target_type == :enemy_targeted &&
       unit.taunted? && !data[:ignore_taunt]
      target = unit.forced_target
      return skill_cast_worthwhile?(unit, target, data) ? target : nil
    end

    target = nil
    case target_type
    when :self
      target = unit
    when :ally
      target = skill_ally_target(unit, policy)
    else
      target = skill_enemy_target(unit, policy)
    end
    return nil if target == nil || target.dead?
    return nil unless skill_cast_worthwhile?(unit, target, data)
    return target
  end

  def skill_enemy_target(unit, policy)
    enemies = enemies_of(unit)
    return nil if enemies.empty?
    case policy
    when :current_target
      if unit.target != nil && unit.target.alive? &&
         !(unit.target.respond_to?(:battle_object?) &&
           unit.target.battle_object?)
        return unit.target
      end
      return nearest_enemy(unit)
    when :best_cluster
      best = nil
      best_score = nil
      for enemy in enemies
        count = enemy_cluster_size(unit, enemy, PMD_AC::AOE_RADIUS)
        hp_rate = enemy.hp.to_f / [enemy.maxhp, 1].max.to_f
        score = count * 1000.0 + (1.0 - hp_rate) * 120.0
        if best == nil || score > best_score
          best = enemy
          best_score = score
        end
      end
      return best
    when :execute
      return enemies.sort_by { |e| e.hp.to_f / [e.maxhp, 1].max.to_f }[0]
    when :lowest_def
      return enemies.sort_by { |e| e.defense }[0]
    when :highest_atk
      return enemies.sort_by { |e| -e.atk }[0]
    else
      if unit.target != nil && unit.target.alive? &&
         !(unit.target.respond_to?(:battle_object?) &&
           unit.target.battle_object?)
        return unit.target
      end
      return nearest_enemy(unit)
    end
  end

  def skill_ally_target(unit, policy)
    allies = allies_of(unit)
    return nil if allies.empty?
    case policy
    when :protect_ally
      ally = unit.protected_ally
      return ally if ally != nil && ally.alive?
      return unit
    when :heal_critical, :lowest_ally
      return allies.sort_by { |a| a.hp.to_f / [a.maxhp, 1].max.to_f }[0]
    else
      return unit
    end
  end

  def skill_cast_worthwhile?(unit, target, data)
    return false if target == nil || target.dead?

    if data[:ally_hp_below] != nil
      hp_rate = target.hp.to_f / [target.maxhp, 1].max.to_f
      threatened = false
      if data[:cast_if_threatened]
        for enemy in enemies_of(unit)
          if enemy.target == target ||
             enemy.distance_to(target) <= PMD_AC::THREAT_PRESSURE_RANGE
            threatened = true
            break
          end
        end
      end
      return false if hp_rate > data[:ally_hp_below].to_f && !threatened
    end

    if data[:minimum_cluster] != nil
      count = enemy_cluster_size(unit, target, data[:radius] || PMD_AC::AOE_RADIUS)
      if count < data[:minimum_cluster].to_i &&
         unit.skill_hold_frames < PMD_AC::SKILL_FORCE_CAST_AFTER
        return false
      end
    end
    return true
  end

  def resolve_skill(unit)
    return if unit.dead?
    data = unit.skill_data
    return if data == nil || data.empty?
    target = unit.skill_target
    target_type = data[:target_type] || :enemy_targeted

    # v0.8.3：單體鎖定技能開始施放後不應在 Resolve 瞬間偷偷換人。
    # 原目標死亡時，預設取消本次技能；只有技能資料明確允許才重鎖。
    if target == nil || target.dead?
      if data[:retarget_on_resolve]
        target = skill_target_for(unit)
        if target != nil
          log_event(:skill_retarget, unit.log_name + " RETARGET " +
                    unit.skill_name.to_s + " -> " + target.log_name)
        end
      else
        old_name = target == nil ? "NONE" : target.log_name
        log_event(:skill_cancel, unit.log_name + " CANCEL " +
                  unit.skill_name.to_s + " target=" + old_name +
                  " reason=target_dead")
        return
      end
    end
    return if target == nil

    delivery = data[:delivery] || :instant

    # v0.10.0.1：目標仍有效、技能真正進入 Resolve，才算「招式發出」。
    play_skill_se(unit, :launch, data)

    # v0.8.4：視覺 Delivery 與命中邏輯分離。既有技能可加細 Beam／Column，
    # 不需要改變原本 AOE／Pierce／Support 的結算方式。
    if data[:beam_visual] != nil
      add_beam_effect(unit, target, data[:beam_visual],
                      PMD_AC::BEAM_DEFAULT_LIFE,
                      data[:beam_width] || PMD_AC::BEAM_DEFAULT_WIDTH)
      log_event(:vfx, unit.log_name + " VISUAL_BEAM style=" +
                data[:beam_visual].to_s + " -> " + target.log_name)
    end
    if data[:column_visual] != nil
      add_column_effect(target, data[:column_visual])
      log_event(:vfx, unit.log_name + " COLUMN style=" +
                data[:column_visual].to_s + " at " + target.log_name)
    end

    log_event(:skill_resolve, unit.log_name + " RESOLVE " +
              unit.skill_name.to_s + " target=" + target.log_name +
              " delivery=" + delivery.to_s +
              " target_type=" + target_type.to_s)

    # v0.9：技能前置位移。Blink／Dash 在近戰距離檢查前執行。
    case data[:pre_move]
    when :blink
      unit.blink_behind(target, data[:blink_offset] || 36.0)
      add_skill_effect(unit, :impact)
    when :dash
      unit.dash_toward(target, data[:dash_distance] || 90.0)
      add_skill_effect(unit, :impact)
    end

    if target_type == :enemy_targeted &&
       unit.melee? && delivery == :instant &&
       !unit.skill_in_range?(target)
      unit.register_miss(target)
      return
    end

    # Substitute 只攔截單體直接命中。
    # AOE / Zone / Chain / Bounce / Pierce / Ground Effect 不重導。
    if target_type == :enemy_targeted &&
       [:instant, :beam].include?(delivery)
      target = substitute_target_for(unit, target, :skill_direct)
    end

    case delivery
    when :beam
      add_beam_effect(unit, target, data[:beam_style] || unit.projectile_style,
                      data[:beam_life] || PMD_AC::BEAM_DEFAULT_LIFE,
                      data[:beam_width] || PMD_AC::BEAM_DEFAULT_WIDTH)
      apply_skill_effects(unit, target, data, 1.0)
      log_event(:beam, unit.log_name + " BEAM " + unit.skill_name.to_s +
                " -> " + target.log_name)
    when :sustained_beam
      add_sustained_beam(unit, target, data)
      log_event(:beam, unit.log_name + " SUSTAINED_BEAM " +
                unit.skill_name.to_s + " -> " + target.log_name)
    when :sweeping_beam
      add_sweeping_beam(unit, target, data)
      log_event(:beam, unit.log_name + " SWEEPING_BEAM " +
                unit.skill_name.to_s + " toward " + target.log_name)
    when :projectile
      launch_projectile(unit, target, :skill_generic, 100, unit.skill_type)
    when :aoe
      if unit.ranged?
        launch_projectile(unit, target, :skill_aoe, 100, unit.skill_type)
      else
        resolve_skill_aoe(unit, target.pixel_x, target.pixel_y, data)
      end
    when :chain
      resolve_skill_chain(unit, target, data, false)
    when :bounce
      resolve_skill_chain(unit, target, data, true)
    when :pierce
      resolve_skill_pierce(unit, target, data)
    else
      damaging = false
      for effect in (data[:effects] || [])
        if effect[:type] == :damage
          damaging = true
          break
        end
      end
      if damaging && target_type == :enemy_targeted
        add_vfx_impact(target, unit.projectile_style)
      end
      before_hp = target.hp
      apply_skill_effects(unit, target, data, 1.0)
      # 無 Direct Damage 的治療／護盾／狀態技能，效果真正落地時播 Hit。
      if !damaging || target.hp == before_hp
        play_skill_se(unit, :hit, data)
      end
    end

    if data[:zone] != nil
      zone_data = data[:zone].dup
      zone_data[:x] = target.pixel_x
      zone_data[:y] = target.pixel_y
      add_zone(unit, zone_data)
    end

    refresh_footer
  end

  def resolve_sustained_beam_tick(user, target, data)
    return if user == nil || target == nil
    return if user.dead? || target.dead?
    tick_effects = data[:tick_effects] || data[:effects] || []
    temp = {:effects => tick_effects, :can_crit => false, :directional => false}
    log_event(:beam_tick, user.log_name + " -> " + target.log_name +
              " skill=" + (data[:name] || "beam").to_s)
    apply_skill_effects(user, target, temp, 1.0)
  end

  def resolve_sweeping_beam_tick(user, x1, y1, x2, y2, data, hit_ids)
    return if user == nil || user.dead?
    width = (data[:beam_width] || PMD_AC::BEAM_DEFAULT_WIDTH).to_f
    for enemy in enemies_of(user)
      next if hit_ids[enemy.id]
      radius = enemy.collision_radius + width * 0.5
      if segment_circle_hit?(x1, y1, x2, y2,
                             enemy.pixel_x, enemy.pixel_y, radius)
        hit_ids[enemy.id] = true
        log_event(:beam_hit, user.log_name + " SWEEP HIT " + enemy.log_name)
        temp = data.dup
        temp[:directional] = false
        apply_skill_effects(user, enemy, temp, 1.0)
      end
    end
  end

  def apply_skill_effects(user, target, data, scale = 1.0)
    return if user == nil || target == nil || target.dead?
    last_damage = 0
    effects = data[:effects] || []
    data_can_crit = data.has_key?(:can_crit) ? data[:can_crit] : true
    data_directional = data.has_key?(:directional) ? data[:directional] : true
    for effect in effects
      case effect[:type]
      when :damage
        can_crit = effect.has_key?(:can_crit) ? effect[:can_crit] : data_can_crit
        directional = effect.has_key?(:directional) ?
                      effect[:directional] : data_directional

        if effect[:flat] != nil
          last_damage = deal_direct_damage(
            user, target, 100,
            {:fixed_damage => (effect[:flat].to_f * scale).round,
             :can_crit => can_crit,
             :crit_bonus => effect[:crit_bonus],
             :crit_multiplier => effect[:crit_multiplier],
             :directional => directional,
             :skill_data => data})
        else
          power = (effect[:power].to_f * scale).round
          last_damage = deal_skill_damage(
            user, target, power,
            {:can_crit => can_crit,
             :crit_bonus => effect[:crit_bonus],
             :crit_multiplier => effect[:crit_multiplier],
             :directional => directional,
             :skill_data => data})
        end
      when :drain
        ratio = effect[:ratio] || 0.5
        user.heal((last_damage * ratio.to_f).round)
        add_skill_effect(user, :heal, 3)

      when :energy_gain
        amount = effect[:flat].to_i
        amount += (user.atk * effect[:power].to_i / 100) if effect[:power]
        gained = target.gain_energy(amount, user,
                                    effect[:reason] || :skill_gain)
        add_skill_effect(target, :energy_gain) if gained > 0

      when :energy_drain
        amount = effect[:flat].to_i
        amount += (user.atk * effect[:power].to_i / 100) if effect[:power]
        drained = target.lose_energy(amount, user,
                                     effect[:reason] || :skill_drain)
        add_skill_effect(target, :energy_drain) if drained > 0

      when :energy_steal
        amount = effect[:flat].to_i
        amount += (user.atk * effect[:power].to_i / 100) if effect[:power]
        drained = target.lose_energy(amount, user, :skill_steal)
        ratio = effect[:ratio] == nil ? 1.0 : effect[:ratio].to_f
        transfer = (drained * ratio).round
        gained = user.gain_energy(transfer, target, :skill_steal)
        log_event(:energy_steal,
                  user.log_name + " <- " + target.log_name +
                  " drained=" + drained.to_s +
                  " gained=" + gained.to_s)
        add_skill_effect(target, :energy_drain) if drained > 0
        add_skill_effect(user, :energy_gain, 3) if gained > 0

      when :energy_lock
        duration = (effect[:duration] || 90).to_i
        target.apply_status(:energy_lock, {
          :duration => duration,
          :value => 0,
          :stack_mode => :refresh
        }, user)
        log_event(:energy_lock,
                  target.log_name + " LOCK dur=" + duration.to_s +
                  " src=" + user.log_name)
        add_skill_effect(target, :energy_lock)

      when :energy_aura
        amount = effect[:flat].to_i
        radius = (effect[:radius] || 96.0).to_f
        duration = (effect[:duration] || 150).to_i
        interval = (effect[:interval] || 30).to_i
        scope = effect[:scope] || :allies
        add_zone(user, {
          :style => :energy,
          :radius => radius,
          :duration => duration,
          :interval => interval,
          :scope => scope,
          :harmful => false,
          :follow_owner => true,
          :effects => [
            {:type => :energy_gain, :flat => amount, :reason => :energy_aura}
          ]
        })
        log_event(:energy_aura,
                  user.log_name + " CREATE radius=" + radius.round.to_s +
                  " gain=" + amount.to_s +
                  " interval=" + interval.to_s +
                  " dur=" + duration.to_s)
        add_skill_effect(user, :energy_aura)

      when :battle_object
        create_battle_object_from_effect(user, target, effect)

      when :summon_unit
        summon_from_effect(user, target, effect)

      when :heal
        amount = effect[:flat].to_i
        amount += (user.atk * effect[:power].to_i / 100) if effect[:power]
        target.heal(amount)
        add_skill_effect(target, :heal)
      when :shield
        amount = effect[:flat].to_i
        amount += (user.atk * effect[:power].to_i / 100) if effect[:power]
        target.add_shield(amount, effect[:duration] || 0,
                          effect[:trigger], user)
        add_skill_effect(target, :shield)
      when :status
        options = {
          :duration => effect[:duration],
          :value => effect[:value],
          :interval => effect[:interval],
          :stack_mode => effect[:stack_mode]
        }
        target.apply_status(effect[:status], options, user)
        add_skill_effect(target, effect[:status])
      when :hot
        options = {
          :duration => effect[:duration],
          :value => effect[:value],
          :interval => effect[:interval],
          :stack_mode => effect[:stack_mode] || :refresh
        }
        target.apply_status(:regen, options, user)
        add_skill_effect(target, :heal)
      when :cleanse
        target.cleanse(effect[:tags] || [:debuff])
        add_skill_effect(target, :cleanse)
      when :dispel
        target.dispel(effect[:tags] || [:buff])
        add_skill_effect(target, :dispel)
      when :control
        target.apply_control(effect[:control],
                             effect[:duration] || 60, user)
        add_skill_effect(target, effect[:control] || :control)
      when :knockback
        target.apply_knockback(user, effect[:distance] || 30.0)
        log_event(:knockback, target.log_name + " <- " + user.log_name +
                  " dist=" + (effect[:distance] || 30.0).to_s)
      when :pull
        target.apply_pull(user, effect[:distance] || 30.0)
      when :dash_user
        user.dash_toward(target, effect[:distance] || 80.0)
      when :blink_user
        user.blink_behind(target, effect[:offset] || 36.0)
      when :link
        target.set_damage_link(user,
                               effect[:ratio] || PMD_AC::LINK_DEFAULT_RATIO,
                               effect[:duration] || 180)
        add_unit_link_effect(user, target, :water, 0)
      when :taunt
        target.apply_taunt(user, effect[:duration] || PMD_AC::TAUNT_DEFAULT_DURATION)
        add_skill_effect(target, :taunt)
      when :taunt_area
        center = effect[:center] == :target ? target : user
        apply_area_taunt(user, center, effect[:radius] || 100.0,
                         effect[:duration] || PMD_AC::TAUNT_DEFAULT_DURATION)
      end
    end
    return last_damage
  end

  def apply_area_taunt(user, center, radius, duration)
    return if user == nil || center == nil
    affected = []
    for enemy in enemies_of(user)
      distance = PMD_AC.distance(center.pixel_x, center.pixel_y,
                                 enemy.pixel_x, enemy.pixel_y)
      next if distance > radius.to_f + enemy.collision_radius
      enemy.apply_taunt(user, duration)
      affected.push(enemy.log_name)
      add_skill_effect(enemy, :taunt)
    end
    log_event(:taunt, user.log_name + " AREA TAUNT radius=" +
              radius.to_s + " affected=[" + affected.join(",") + "]")
  end

  def resolve_skill_aoe(unit, x, y, data)
    radius = data[:radius] || PMD_AC::AOE_RADIUS
    if data[:beam_visual] == nil && data[:column_visual] == nil
      add_vfx_impact_xy(x, y, unit.projectile_style)
    end
    index = 0
    damaged = false
    for enemy in enemies_of(unit)
      distance = PMD_AC.distance(x, y, enemy.pixel_x, enemy.pixel_y)
      next if distance > radius.to_f + enemy.collision_radius
      before_hp = enemy.hp
      aoe_data = data.dup
      aoe_data[:directional] = false
      apply_skill_effects(unit, enemy, aoe_data, 1.0)
      damaged = true if enemy.hp < before_hp
      index += 1
    end
    if index > 0 && !damaged
      play_skill_se(unit, :hit, data)
    end
    return index
  end

  def resolve_skill_chain(unit, first_target, data, bounce = false)
    available = enemies_of(unit)
    return if available.empty?
    max_hits = (data[:max_hits] || 3).to_i
    radius = (data[:bounce_radius] || 150.0).to_f
    decay = (data[:damage_decay] || 0.80).to_f
    chain = []
    current = first_target
    current = nearest_enemy(unit) if current == nil || current.dead?

    while current != nil && chain.size < max_hits
      chain.push(current)
      candidates = available.find_all { |enemy| !chain.include?(enemy) }
      break if candidates.empty?
      candidates = candidates.find_all { |enemy| current.distance_to(enemy) <= radius }
      break if candidates.empty?
      candidates.sort! { |a, b| current.distance_to(a) <=> current.distance_to(b) }
      current = candidates[0]
    end

    mode_name = bounce ? "BOUNCE" : "CHAIN"
    log_event(bounce ? :bounce : :chain,
              unit.log_name + " " + mode_name + " [" +
              chain.collect { |u| u.log_name }.join(" -> ") + "]")
    last_unit = unit
    scale = 1.0
    for i in 0...chain.size
      visual = bounce ? unit.projectile_style : :electric
      add_unit_link_effect(last_unit, chain[i], visual, i * 5)
      add_vfx_impact(chain[i], visual, i * 5)
      chain_data = data.dup
      chain_data[:directional] = false
      apply_skill_effects(unit, chain[i], chain_data, scale)
      last_unit = chain[i]
      scale *= decay
    end
  end

  def point_segment_distance(px, py, x1, y1, x2, y2)
    vx = x2 - x1
    vy = y2 - y1
    wx = px - x1
    wy = py - y1
    len_sq = vx * vx + vy * vy
    return [PMD_AC.distance(px, py, x1, y1), 0.0] if len_sq <= 0.0001
    t = (wx * vx + wy * vy) / len_sq
    t = PMD_AC.clamp(t, 0.0, 1.0)
    cx = x1 + vx * t
    cy = y1 + vy * t
    return [PMD_AC.distance(px, py, cx, cy), t]
  end

  def resolve_skill_pierce(unit, target, data)
    dx = target.pixel_x - unit.pixel_x
    dy = target.pixel_y - unit.pixel_y
    length = Math.sqrt(dx * dx + dy * dy)
    return if length <= 0.001
    ux = dx / length
    uy = dy / length
    line_length = (data[:pierce_length] || 240.0).to_f

    # 戰鬥判定永遠使用腳底／碰撞座標。
    logic_x1 = unit.pixel_x
    logic_y1 = unit.pixel_y
    logic_x2 = logic_x1 + ux * line_length
    logic_y2 = logic_y1 + uy * line_length

    # VFX 才使用 PMD Sprite 幾何中心。
    source_anchor = effect_anchor_xy(unit, true)
    visual_x1 = source_anchor[0]
    visual_y1 = source_anchor[1]
    visual_x2 = visual_x1 + ux * line_length
    visual_y2 = visual_y1 + uy * line_length
    add_link_effect(visual_x1, visual_y1, visual_x2, visual_y2,
                    unit.projectile_style, 0)

    width = (data[:pierce_width] || 16.0).to_f
    candidates = []
    for enemy in enemies_of(unit)
      dist, t = point_segment_distance(enemy.pixel_x, enemy.pixel_y,
                                       logic_x1, logic_y1,
                                       logic_x2, logic_y2)
      if dist <= width + enemy.collision_radius && t >= 0.0 && t <= 1.0
        candidates.push([t, enemy])
      end
    end
    candidates.sort! { |a, b| a[0] <=> b[0] }
    max_hits = (data[:max_hits] || candidates.size).to_i
    hit_items = candidates[0, max_hits] || []
    log_event(:pierce, unit.log_name + " PIERCE hits=[" +
              hit_items.collect { |item| item[1].log_name }.join(",") + "]")
    decay = (data[:damage_decay] || 1.0).to_f
    scale = 1.0
    hit_index = 0
    for item in hit_items
      add_vfx_impact(item[1], unit.projectile_style, hit_index * 2)
      apply_skill_effects(unit, item[1], data, scale)
      scale *= decay
      hit_index += 1
    end
  end

  def nearest_enemy(unit)
    enemies = enemies_of(unit)
    result = nil
    best = nil
    for enemy in enemies
      distance = unit.distance_to(enemy)
      if result == nil || distance < best
        result = enemy
        best = distance
      end
    end
    return result
  end

  def deal_direct_damage(user, target, power, options = nil)
    return 0 if user == nil || target == nil || target.dead?
    options = {} if options == nil
    modifier = options[:modifier]

    final_power = power.to_f
    if modifier != nil
      final_power *= (modifier[:power_multiplier] || 1.0).to_f
    end
    final_power = final_power.round

    if options.has_key?(:fixed_damage)
      damage = [options[:fixed_damage].to_i, 1].max
    else
      damage = user.calculate_damage(target, final_power)
    end

    # Directional multiplier 只處理 Direct Hit。
    directional = options.has_key?(:directional) ? options[:directional] : true
    if directional
      arc = target.incoming_arc_from(user)
      mult = target.directional_damage_multiplier(arc)
      before_direction = damage
      damage = [(damage.to_f * mult).round, 1].max

      log_event(:direction,
                user.log_name + " -> " + target.log_name +
                " arc=" + arc.to_s +
                " mult=" + sprintf("%.2f", mult.to_f) +
                " damage=" + before_direction.to_s +
                "->" + damage.to_s)

      if arc == :front
        log_event(:front_guard,
                  target.log_name + " FRONT_GUARD vs " + user.log_name +
                  " mult=" + sprintf("%.2f", mult.to_f))
      elsif arc == :back
        log_event(:back_attack,
                  user.log_name + " BACK_ATTACK -> " + target.log_name +
                  " mult=" + sprintf("%.2f", mult.to_f))
      end
    end

    can_crit = options.has_key?(:can_crit) ? options[:can_crit] : true
    critical = false

    if can_crit
      if modifier != nil && modifier[:force_crit]
        critical = true
      else
        bonus = options[:crit_bonus] || 0.0
        rate = PMD_AC.clamp(user.crit_rate + bonus.to_f, 0.0, 1.0)
        critical = rand < rate
      end
    end

    if critical
      mult = options[:crit_multiplier] || user.crit_multiplier
      damage = [(damage * mult.to_f).round, 1].max
      log_event(:crit,
                user.log_name + " -> " + target.log_name +
                " damage=" + damage.to_s +
                " mult=" + sprintf("%.2f", mult.to_f))
      play_crit_se(user, options[:skill_data])
    end

    grant_energy = options.has_key?(:grant_energy) ?
                   options[:grant_energy] : true
    target.receive_damage(damage, user, grant_energy, false, critical)

    # 有 skill_data 代表這是技能 Direct Hit，而不是普攻／Zone Tick。
    if options[:skill_data] != nil
      play_skill_se(user, :hit, options[:skill_data])
    end

    if modifier != nil && modifier[:effects] != nil &&
       target.alive?
      temp = {:effects => modifier[:effects], :can_crit => false}
      apply_skill_effects(user, target, temp, 1.0)
    end

    return damage
  end

  def deal_skill_damage(user, target, power, options = nil)
    return deal_direct_damage(user, target, power, options)
  end

  def check_battle_end
    allies = core_living_units(:ally)
    enemies = core_living_units(:enemy)
    refresh_footer if @logic_count == 0
    return if !allies.empty? && !enemies.empty?
    @battle_end = true
    @phase = :result
    winner_team = enemies.empty? ? :ally : :enemy
    @result_text = winner_team == :ally ? "藍方勝利" : "紅方勝利"
    @result_text += "｜實際落空 " + @miss_count.to_s + " 次"
    log_event(:battle, "END #" + @battle_log_battle_id.to_s +
              " result=" + @result_text)
    log_battle_summary
    for unit in @units
      unit.stop_combat
    end
    # 存活勝方切回 PMD MOVE 並跳躍慶祝。
    winners = core_living_units(winner_team)
    for unit in winners
      unit.start_victory_celebration
      log_event(:victory,
                unit.log_name + " MOVE_BOUNCE facing=down(2) height=" +
                PMD_AC::VICTORY_BOUNCE_HEIGHT.to_i.to_s)
    end
    # 勝負成立後清除尚未命中的投射物與 Battle Object，
    # 避免結果畫面再追加傷害／倒數。
    dispose_projectile_sprites
    @summon_removal_queue = []
    clear_battle_objects(:battle_end)
    dispose_battle_object_sprites
    show_result
    refresh_header
    refresh_footer
  end

  def show_result
    dispose_sprite(@result_sprite)
    @result_sprite = Sprite.new(@viewport)
    @result_sprite.bitmap = Bitmap.new(360, 96)
    @result_sprite.x = (Graphics.width - 360) / 2
    @result_sprite.y = (Graphics.height - 96) / 2 - 12
    @result_sprite.z = 9999
    bmp = @result_sprite.bitmap
    bmp.fill_rect(0, 0, 360, 96, Color.new(0, 0, 0, 220))
    bmp.font.size = 28
    bmp.font.bold = true
    bmp.font.color = Color.new(255, 255, 255)
    bmp.draw_text(0, 12, 360, 34, @result_text, 1)
    bmp.font.size = 18
    bmp.font.bold = false
    bmp.font.color = Color.new(210, 220, 230)
    bmp.draw_text(0, 53, 360, 26, "LOG 已寫入專案根目錄｜C 回布陣／B 離開", 1)
  end

  def restart_to_deploy
    log_event(:battle, "RETURN TO DEPLOY")
    dispose_unit_sprites
    dispose_effect_sprites
    dispose_projectile_sprites
    dispose_battle_object_sprites
    dispose_sprite(@result_sprite)
    @result_sprite = nil
    create_units
    create_unit_sprites
    @effect_sprites = []
    @projectile_sprites = []
    @battle_objects = []
    @battle_object_sprites = []
    @next_battle_object_id = 0
    @summon_removal_queue = []
    @zones = []
    @aura_counter = 0
    @attack_slots = {}
    @next_projectile_id = 0
    @miss_count = 0
    @shake_frames = 0
    @shake_power = 0
    @selected_unit = nil
    @phase = :deploy
    @battle_speed = 1
    @logic_count = 0
    @battle_end = false
    @result_text = ""
    @verification_frame = 0
    @verification_done = {}
    @zone_avoid_log_frames = {}
    @board_sprite.opacity = 255 if @board_sprite != nil
    @deploy_cursor.visible = true
    first = living_units(:ally)[0]
    @deploy_cursor.move_to(first.cell_x, first.cell_y) if first != nil
    refresh_selected_sprites
    refresh_header
    refresh_footer
  end
end


#==============================================================================
# ■ PMD AutoChess v0.12.0.1 Extension
#    Startup Regression Fix
#------------------------------------------------------------------------------
#  修正 v0.12 最後追加擴充段誤用 Scene_PMDChessPrototype。
#  正確場景類別為 Scene_PMD_AutoChess。
#  因此 prepare_verification_battle / update_auras /
#  update_verification_script 的 alias 現在會綁定既有方法。
#
#    Pokémon Progression / Base Stats / Pokémon Damage Formula
#==============================================================================
module PMD_AC
  # Verification mode extension
  remove_const(:VERIFICATION_MODES) if const_defined?(:VERIFICATION_MODES)
  VERIFICATION_MODES = [:normal, :control, :beam, :zone, :hit, :energy,
                        :direction, :object, :summon, :identity, :progression]

  remove_const(:VERIFICATION_LABELS) if const_defined?(:VERIFICATION_LABELS)
  VERIFICATION_LABELS = {
    :normal=>"NORMAL", :control=>"CONTROL", :beam=>"BEAM", :zone=>"ZONE",
    :hit=>"HIT", :energy=>"ENERGY", :direction=>"DIRECTION",
    :object=>"OBJECT", :summon=>"SUMMON", :identity=>"IDENTITY",
    :progression=>"PROGRESSION"
  }

  VERIFICATION_PROGRESSION_END_FRAME = 220 unless
    const_defined?(:VERIFICATION_PROGRESSION_END_FRAME)

  POKEMON_MAX_LEVEL = 100 unless const_defined?(:POKEMON_MAX_LEVEL)
  POKEMON_DEFAULT_LEVEL = 15 unless const_defined?(:POKEMON_DEFAULT_LEVEL)
  POKEMON_PLACEHOLDER_IV = 15 unless const_defined?(:POKEMON_PLACEHOLDER_IV)
  POKEMON_PLACEHOLDER_EV = 0 unless const_defined?(:POKEMON_PLACEHOLDER_EV)
  POKEMON_COMBAT_HP_SCALE = 10.0 unless const_defined?(:POKEMON_COMBAT_HP_SCALE)
  POKEMON_DAMAGE_SCALE = 1.65 unless const_defined?(:POKEMON_DAMAGE_SCALE)
  POKEMON_STAB_MULTIPLIER = 1.50 unless
    const_defined?(:POKEMON_STAB_MULTIPLIER)
  POKEMON_RANDOM_MIN = 85 unless const_defined?(:POKEMON_RANDOM_MIN)
  POKEMON_RANDOM_MAX = 100 unless const_defined?(:POKEMON_RANDOM_MAX)

  # Full 18-type chart. Missing pair = 1.0.
  TYPE_CHART = {
    :normal=>{:rock=>0.5,:ghost=>0.0,:steel=>0.5},
    :fire=>{:fire=>0.5,:water=>0.5,:grass=>2.0,:ice=>2.0,:bug=>2.0,
            :rock=>0.5,:dragon=>0.5,:steel=>2.0},
    :water=>{:fire=>2.0,:water=>0.5,:grass=>0.5,:ground=>2.0,
             :rock=>2.0,:dragon=>0.5},
    :electric=>{:water=>2.0,:electric=>0.5,:grass=>0.5,:ground=>0.0,
                :flying=>2.0,:dragon=>0.5},
    :grass=>{:fire=>0.5,:water=>2.0,:grass=>0.5,:poison=>0.5,
             :ground=>2.0,:flying=>0.5,:bug=>0.5,:rock=>2.0,
             :dragon=>0.5,:steel=>0.5},
    :ice=>{:fire=>0.5,:water=>0.5,:grass=>2.0,:ice=>0.5,:ground=>2.0,
           :flying=>2.0,:dragon=>2.0,:steel=>0.5},
    :fighting=>{:normal=>2.0,:ice=>2.0,:poison=>0.5,:flying=>0.5,
                :psychic=>0.5,:bug=>0.5,:rock=>2.0,:ghost=>0.0,
                :dark=>2.0,:steel=>2.0,:fairy=>0.5},
    :poison=>{:grass=>2.0,:poison=>0.5,:ground=>0.5,:rock=>0.5,
              :ghost=>0.5,:steel=>0.0,:fairy=>2.0},
    :ground=>{:fire=>2.0,:electric=>2.0,:grass=>0.5,:poison=>2.0,
              :flying=>0.0,:bug=>0.5,:rock=>2.0,:steel=>2.0},
    :flying=>{:electric=>0.5,:grass=>2.0,:fighting=>2.0,:bug=>2.0,
              :rock=>0.5,:steel=>0.5},
    :psychic=>{:fighting=>2.0,:poison=>2.0,:psychic=>0.5,
               :dark=>0.0,:steel=>0.5},
    :bug=>{:fire=>0.5,:grass=>2.0,:fighting=>0.5,:poison=>0.5,
           :flying=>0.5,:psychic=>2.0,:ghost=>0.5,:dark=>2.0,
           :steel=>0.5,:fairy=>0.5},
    :rock=>{:fire=>2.0,:ice=>2.0,:fighting=>0.5,:ground=>0.5,
            :flying=>2.0,:bug=>2.0,:steel=>0.5},
    :ghost=>{:normal=>0.0,:psychic=>2.0,:ghost=>2.0,:dark=>0.5},
    :dragon=>{:dragon=>2.0,:steel=>0.5,:fairy=>0.0},
    :dark=>{:fighting=>0.5,:psychic=>2.0,:ghost=>2.0,:dark=>0.5,
            :fairy=>0.5},
    :steel=>{:fire=>0.5,:water=>0.5,:electric=>0.5,:ice=>2.0,
             :rock=>2.0,:steel=>0.5,:fairy=>2.0},
    :fairy=>{:fire=>0.5,:fighting=>2.0,:poison=>0.5,:dragon=>2.0,
             :dark=>2.0,:steel=>0.5}
  } unless const_defined?(:TYPE_CHART)

  # Canonical base-stat layer + progression metadata.
  SPECIES_V012 = {
    :bulbasaur=>{:types=>[:grass,:poison],:base_stats=>[45,49,49,65,65,45],
      :base_exp=>64,:growth_group=>:medium_slow,:evolves_to=>:ivysaur,
      :evolution=>{:type=>:level,:level=>16},
      :learnset=>{1=>:vine_drain,16=>:ricochet_seed}},
    :ivysaur=>{:types=>[:grass,:poison],:base_stats=>[60,62,63,80,80,60],
      :base_exp=>142,:growth_group=>:medium_slow,:evolves_to=>:venusaur,
      :evolution=>{:type=>:level,:level=>32},:learnset=>{}},
    :venusaur=>{:types=>[:grass,:poison],:base_stats=>[80,82,83,100,100,80],
      :base_exp=>236,:growth_group=>:medium_slow,:evolves_to=>nil,
      :evolution=>nil,:learnset=>{}},
    :charmander=>{:types=>[:fire],:base_stats=>[39,52,43,60,50,65],
      :base_exp=>62,:growth_group=>:medium_slow,:evolves_to=>:charmeleon,
      :evolution=>{:type=>:level,:level=>16},
      :learnset=>{1=>:flame_burst,16=>:fire_sweep}},
    :charmeleon=>{:types=>[:fire],:base_stats=>[58,64,58,80,65,80],
      :base_exp=>142,:growth_group=>:medium_slow,:evolves_to=>:charizard,
      :evolution=>{:type=>:level,:level=>36},:learnset=>{}},
    :charizard=>{:types=>[:fire,:flying],:base_stats=>[78,84,78,109,85,100],
      :base_exp=>240,:growth_group=>:medium_slow,:evolves_to=>nil,
      :evolution=>nil,:learnset=>{}},
    :squirtle=>{:types=>[:water],:base_stats=>[44,48,65,50,64,43],
      :base_exp=>63,:growth_group=>:medium_slow,:evolves_to=>:wartortle,
      :evolution=>{:type=>:level,:level=>16},
      :learnset=>{1=>:guardian_tide,16=>:water_lance}},
    :wartortle=>{:types=>[:water],:base_stats=>[59,63,80,65,80,58],
      :base_exp=>142,:growth_group=>:medium_slow,:evolves_to=>:blastoise,
      :evolution=>{:type=>:level,:level=>36},:learnset=>{}},
    :blastoise=>{:types=>[:water],:base_stats=>[79,83,100,85,105,78],
      :base_exp=>239,:growth_group=>:medium_slow,:evolves_to=>nil,
      :evolution=>nil,:learnset=>{}},
    :caterpie=>{:types=>[:bug],:base_stats=>[45,30,35,20,20,45],
      :base_exp=>39,:growth_group=>:medium_fast,:evolves_to=>:metapod,
      :evolution=>{:type=>:level,:level=>7},:learnset=>{1=>:web_pierce}},
    :metapod=>{:types=>[:bug],:base_stats=>[50,20,55,25,25,30],
      :base_exp=>72,:growth_group=>:medium_fast,:evolves_to=>:butterfree,
      :evolution=>{:type=>:level,:level=>10},:learnset=>{}},
    :butterfree=>{:types=>[:bug,:flying],:base_stats=>[60,45,50,90,80,70],
      :base_exp=>178,:growth_group=>:medium_fast,:evolves_to=>nil,
      :evolution=>nil,:learnset=>{}},
    :rattata=>{:types=>[:normal],:base_stats=>[30,56,35,25,35,72],
      :base_exp=>51,:growth_group=>:medium_fast,:evolves_to=>:raticate,
      :evolution=>{:type=>:level,:level=>20},
      :learnset=>{1=>:rending_assault,20=>:dash_strike}},
    :raticate=>{:types=>[:normal],:base_stats=>[55,81,60,50,70,97],
      :base_exp=>145,:growth_group=>:medium_fast,:evolves_to=>nil,
      :evolution=>nil,:learnset=>{}},
    :pikachu=>{:types=>[:electric],:base_stats=>[35,55,40,50,50,90],
      :base_exp=>112,:growth_group=>:medium_fast,:evolves_to=>:raichu,
      :evolution=>{:type=>:item,:item=>:thunder_stone},
      :learnset=>{1=>:chain_lightning}},
    :raichu=>{:types=>[:electric],:base_stats=>[60,90,55,90,80,110],
      :base_exp=>243,:growth_group=>:medium_fast,:evolves_to=>nil,
      :evolution=>nil,:learnset=>{}}
  } unless const_defined?(:SPECIES_V012)

  for key in SPECIES_V012.keys
    POKEMON_SPECIES_DATA[key].merge!(SPECIES_V012[key])
  end

  SKILL_V012 = {
    :vine_drain=>[:grass,:special],
    :flame_burst=>[:fire,:special],
    :guardian_tide=>[:water,:status],
    :web_pierce=>[:bug,:special],
    :rending_assault=>[:normal,:physical],
    :chain_lightning=>[:electric,:special],
    :frost_beam=>[:ice,:special],
    :water_lance=>[:water,:special],
    :fire_sweep=>[:fire,:special],
    :tidal_push=>[:water,:special],
    :dash_strike=>[:normal,:physical],
    :healing_field=>[:grass,:status],
    :ricochet_seed=>[:grass,:physical]
  } unless const_defined?(:SKILL_V012)

  for key in SKILL_V012.keys
    next if SKILL_DATA[key] == nil
    SKILL_DATA[key][:move_type] = SKILL_V012[key][0]
    SKILL_DATA[key][:damage_category] = SKILL_V012[key][1]
  end
  # Ground fire tick still belongs to Fire/Special.
  if SKILL_DATA[:flame_burst] && SKILL_DATA[:flame_burst][:zone]
    zone_damage = SKILL_DATA[:flame_burst][:zone][:effects][0]
    zone_damage[:move_type] = :fire
    zone_damage[:damage_category] = :special
  end

  class << self
    def unit_profile(species_key)
      direct = UNIT_DATA[species_key]
      return direct if direct != nil
      species = species_identity_data(species_key)
      return nil if species == nil
      line = evolution_line_data(species[:line])
      return nil if line == nil
      source_key = nil
      for member in line[:members]
        if UNIT_DATA[member] != nil
          source_key = member
          break
        end
      end
      return nil if source_key == nil
      data = UNIT_DATA[source_key].dup
      data[:name] = species[:name]
      data[:species] = species[:pmd_species]
      data[:profile_source] = source_key
      return data
    end

    def pmd_visual_species(species_key, profile = nil)
      species = species_identity_data(species_key)
      return profile[:species].to_s if species == nil && profile != nil
      actual = species[:pmd_species].to_s
      return actual if FileTest.exist?(PMD_ROOT + actual + "/Idle-Anim.png")
      if profile != nil && profile[:profile_source] != nil
        fallback = species_identity_data(profile[:profile_source])
        if fallback != nil
          fid = fallback[:pmd_species].to_s
          return fid if FileTest.exist?(PMD_ROOT + fid + "/Idle-Anim.png")
        end
      end
      return profile[:species].to_s if profile != nil
      return actual
    end

    def base_stats(species_key)
      data = species_identity_data(species_key)
      return data == nil ? nil : data[:base_stats]
    end

    def pokemon_stat(base, level, hp = false, iv = nil, ev = nil,
                     nature = 1.0)
      iv = POKEMON_PLACEHOLDER_IV if iv == nil
      ev = POKEMON_PLACEHOLDER_EV if ev == nil
      level = clamp(level.to_i, 1, POKEMON_MAX_LEVEL)
      iv = clamp(iv.to_i, 0, 31)
      ev = [ev.to_i, 0].max
      core = ((2 * base.to_i + iv + ev / 4) * level / 100)
      return core + level + 10 if hp
      return [((core + 5) * nature.to_f).floor, 1].max
    end

    def pokemon_stats(species_key, level, ivs = nil, evs = nil,
                      natures = nil)
      bases = base_stats(species_key)
      return nil if bases == nil
      ivs = [POKEMON_PLACEHOLDER_IV] * 6 if ivs == nil
      evs = [POKEMON_PLACEHOLDER_EV] * 6 if evs == nil
      natures = [1.0] * 6 if natures == nil
      return {
        :hp=>pokemon_stat(bases[0],level,true,ivs[0],evs[0],1.0),
        :atk=>pokemon_stat(bases[1],level,false,ivs[1],evs[1],natures[1]),
        :def=>pokemon_stat(bases[2],level,false,ivs[2],evs[2],natures[2]),
        :spatk=>pokemon_stat(bases[3],level,false,ivs[3],evs[3],natures[3]),
        :spdef=>pokemon_stat(bases[4],level,false,ivs[4],evs[4],natures[4]),
        :speed=>pokemon_stat(bases[5],level,false,ivs[5],evs[5],natures[5])
      }
    end

    def combat_stats(species_key, level, ivs = nil, evs = nil, natures = nil)
      raw = pokemon_stats(species_key, level, ivs, evs, natures)
      return nil if raw == nil
      return {
        :hp=>[(raw[:hp] * POKEMON_COMBAT_HP_SCALE).round,1].max,
        :pokemon_hp=>raw[:hp],
        :atk=>raw[:atk], :def=>raw[:def],
        :spatk=>raw[:spatk], :spdef=>raw[:spdef], :speed=>raw[:speed]
      }
    end

    def exp_for_level(level, growth_group)
      l = clamp(level.to_i, 1, POKEMON_MAX_LEVEL)
      value = case growth_group
      when :medium_slow
        (6*l*l*l/5) - (15*l*l) + (100*l) - 140
      else
        l*l*l
      end
      return [value,0].max
    end

    def type_effectiveness(move_type, defender_types)
      chart = TYPE_CHART[move_type] || {}
      mult = 1.0
      for type in defender_types
        mult *= chart.has_key?(type) ? chart[type].to_f : 1.0
      end
      return mult
    end

    def exp_reward_for(species_key, level, participants = 1)
      data = species_identity_data(species_key)
      return 0 if data == nil
      participants = [participants.to_i,1].max
      value = ((data[:base_exp] || 50).to_i * level.to_i / 7) / participants
      return [value,1].max
    end

    alias pmd_ac_v012_validate_identity_registry validate_identity_registry unless method_defined?(:pmd_ac_v012_validate_identity_registry)
    def validate_identity_registry
      errors = pmd_ac_v012_validate_identity_registry
      for key in POKEMON_SPECIES_DATA.keys
        data = POKEMON_SPECIES_DATA[key]
        bases = data[:base_stats]
        errors.push("base_stats_missing:"+key.to_s) if
          bases == nil || bases.size != 6
        errors.push("types_missing:"+key.to_s) if
          data[:types] == nil || data[:types].empty?
      end
      return errors
    end
  end
end

#==============================================================================
# ■ PMD_PokemonIdentity v0.12
#==============================================================================
class PMD_PokemonIdentity
  def change_species_key(new_species_key)
    data = PMD_AC.species_identity_data(new_species_key)
    return false if data == nil
    return false if data[:line] != @evolution_line_key
    @species_key = new_species_key
    @evolution_stage = data[:stage].to_i
    @pmd_species_id = data[:pmd_species].to_s
    @form_key = :normal
    @synergy_tags = PMD_AC.identity_synergy_tags(new_species_key)
    @role_tags = PMD_AC.identity_role_tags(new_species_key)
    return true
  end
end

#==============================================================================
# ■ PMD_PokemonInstance
#==============================================================================
class PMD_PokemonInstance
  attr_reader :identity
  attr_reader :level
  attr_reader :exp
  attr_reader :learned_moves
  attr_reader :progression_history

  def initialize(species_key, level = nil, options = nil)
    options = {} if options == nil
    @level = PMD_AC.clamp(
      (level || PMD_AC::POKEMON_DEFAULT_LEVEL).to_i,
      1, PMD_AC::POKEMON_MAX_LEVEL)
    @identity = PMD_PokemonIdentity.new(
      species_key,
      {:instance_uid=>options[:instance_uid],
       :runtime_actor_id=>options[:runtime_actor_id],
       :template_actor_id=>options[:template_actor_id],
       :form_key=>options[:form_key] || :normal})
    @exp = options.has_key?(:exp) ? options[:exp].to_i :
           PMD_AC.exp_for_level(@level, growth_group)
    @learned_moves = []
    @progression_history = []
    learn_moves_through_level(@level, false)
  end

  def instance_uid; @identity.instance_uid; end
  def species_key; @identity.species_key; end
  def evolution_line_key; @identity.evolution_line_key; end
  def evolution_stage; @identity.evolution_stage; end
  def form_key; @identity.form_key; end
  def runtime_actor_id; @identity.runtime_actor_id; end
  def template_actor_id; @identity.template_actor_id; end

  def bind_actor_ids(runtime_id, template_id = nil)
    @identity.bind_actor_ids(runtime_id, template_id)
  end

  def species_data
    PMD_AC.species_identity_data(species_key)
  end

  def growth_group
    data = species_data
    return data == nil ? :medium_fast : (data[:growth_group] || :medium_fast)
  end

  def next_level_exp
    return @exp if @level >= PMD_AC::POKEMON_MAX_LEVEL
    return PMD_AC.exp_for_level(@level + 1, growth_group)
  end

  def exp_to_next_level
    return [next_level_exp - @exp,0].max
  end

  def pokemon_stats
    return PMD_AC.pokemon_stats(species_key,@level)
  end

  def combat_stats
    return PMD_AC.combat_stats(species_key,@level)
  end

  def types
    data = species_data
    return data == nil ? [] : (data[:types] || []).dup
  end

  def learnset
    data = species_data
    return data == nil ? {} : (data[:learnset] || {})
  end

  def learn_moves_through_level(level, record = true)
    learned = []
    pairs = learnset.to_a
    pairs.sort! { |a,b| a[0].to_i <=> b[0].to_i }
    for pair in pairs
      next if pair[0].to_i > level.to_i
      move = pair[1]
      next if @learned_moves.include?(move)
      @learned_moves.push(move)
      learned.push(move)
      @progression_history.push(
        {:type=>:move_learn,:level=>@level,:move=>move}) if record
    end
    return learned
  end

  def gain_exp(amount, allow_evolution = true)
    amount = [amount.to_i,0].max
    result = {:gained=>amount,:levels=>[],:moves=>[],:evolutions=>[]}
    return result if amount <= 0 || @level >= PMD_AC::POKEMON_MAX_LEVEL
    @exp += amount
    @progression_history.push({:type=>:exp,:amount=>amount,:exp=>@exp})
    while @level < PMD_AC::POKEMON_MAX_LEVEL &&
          @exp >= PMD_AC.exp_for_level(@level + 1, growth_group)
      @level += 1
      result[:levels].push(@level)
      @progression_history.push({:type=>:level_up,:level=>@level})
      result[:moves].concat(learn_moves_through_level(@level,true))
      if allow_evolution
        evo = evolve_if_ready
        if evo != nil
          result[:evolutions].push(evo)
          result[:moves].concat(learn_moves_through_level(@level,true))
        end
      end
    end
    return result
  end

  def evolution_ready?
    data = species_data
    return false if data == nil
    cond = data[:evolution]
    return false if data[:evolves_to] == nil || cond == nil
    return @level >= cond[:level].to_i if cond[:type] == :level
    return false
  end

  def evolve_if_ready
    return nil unless evolution_ready?
    old_species = species_key
    target = species_data[:evolves_to]
    return nil unless @identity.change_species_key(target)
    event = {:from=>old_species,:to=>target,:level=>@level,:uid=>instance_uid}
    @progression_history.push({:type=>:evolution}.merge(event))
    return event
  end

  def evolve_with_item(item_key)
    data = species_data
    return nil if data == nil
    cond = data[:evolution]
    return nil if data[:evolves_to] == nil || cond == nil
    return nil unless cond[:type] == :item && cond[:item] == item_key
    old_species = species_key
    target = data[:evolves_to]
    return nil unless @identity.change_species_key(target)
    event = {:from=>old_species,:to=>target,:level=>@level,
             :uid=>instance_uid,:item=>item_key}
    @progression_history.push({:type=>:evolution}.merge(event))
    return event
  end
end

#==============================================================================
# ■ Persistent Ally Roster
#==============================================================================
class Game_System
  attr_accessor :pmd_autochess_roster
  unless method_defined?(:pmd_ac_v012_initialize)
    alias pmd_ac_v012_initialize initialize unless method_defined?(:pmd_ac_v012_initialize)
    def initialize
      pmd_ac_v012_initialize
      @pmd_autochess_roster = {}
    end
  end
end

module PMD_AC
  @fallback_roster = {}
  class << self
    def roster_storage
      if defined?($game_system) && $game_system != nil
        $game_system.pmd_autochess_roster = {} if
          $game_system.pmd_autochess_roster == nil
        return $game_system.pmd_autochess_roster
      end
      @fallback_roster = {} if @fallback_roster == nil
      return @fallback_roster
    end

    def ally_roster_instance(slot, initial_species, initial_level = nil)
      storage = roster_storage
      key = slot.to_i
      instance = storage[key]
      if instance == nil
        instance = PMD_PokemonInstance.new(
          initial_species,initial_level || POKEMON_DEFAULT_LEVEL)
        storage[key] = instance
      end
      return instance
    end
  end
end

#==============================================================================
# ■ Game_PMDChessUnit v0.12 Progression Adapter
#==============================================================================
class Game_PMDChessUnit
  attr_reader :pokemon_instance
  attr_reader :speed_stat

  alias pmd_ac_v012_initialize initialize unless method_defined?(:pmd_ac_v012_initialize)
  def initialize(id, key, team, cell_x, cell_y, pokemon_instance = nil)
    profile = PMD_AC.unit_profile(key) || {}
    instance = pokemon_instance || PMD_PokemonInstance.new(
      key, profile[:start_level] || PMD_AC::POKEMON_DEFAULT_LEVEL)

    actual_key = instance.species_key
    actual_profile = PMD_AC.unit_profile(actual_key)
    raise "Missing unit profile: " + actual_key.to_s if actual_profile == nil
    runtime_key = actual_profile[:profile_source] || actual_key

    pmd_ac_v012_initialize(id,runtime_key,team,cell_x,cell_y)

    @pokemon_instance = instance
    @identity = instance.identity
    @key = actual_key
    @name = actual_profile[:name]
    @species = PMD_AC.pmd_visual_species(actual_key,actual_profile)

    stats = instance.combat_stats
    @maxhp = stats[:hp]
    @hp = @maxhp
    @atk = stats[:atk]
    @def = stats[:def]
    @spatk = stats[:spatk]
    @spdef = stats[:spdef]
    @speed_stat = stats[:speed]
  end

  def level
    return @pokemon_instance == nil ? PMD_AC::POKEMON_DEFAULT_LEVEL :
                                     @pokemon_instance.level
  end

  def pokemon_types
    return @pokemon_instance == nil ? [] : @pokemon_instance.types
  end

  def special_attack
    value = @spatk.to_f
    value *= status_stat_multiplier(:spatk)
    return [value.round,1].max
  end

  def special_defense
    value = @spdef.to_f
    value *= status_stat_multiplier(:spdef)
    return [value.round,1].max
  end

  def basic_move_type
    data = PMD_AC.unit_profile(@key) || {}
    return data[:basic_move_type] || :normal
  end

  def sync_from_pokemon_instance
    return false if @pokemon_instance == nil
    old_key = @key
    @identity = @pokemon_instance.identity
    @key = @pokemon_instance.species_key
    data = PMD_AC.unit_profile(@key)
    return false if data == nil
    @name = data[:name]
    actual_pmd = @identity.pmd_species_id
    @species = PMD_AC.pmd_visual_species(@key,data)

    stats = @pokemon_instance.combat_stats
    hp_rate = @maxhp.to_i <= 0 ? 1.0 : @hp.to_f / @maxhp.to_f
    @maxhp = stats[:hp]
    @atk = stats[:atk]
    @def = stats[:def]
    @spatk = stats[:spatk]
    @spdef = stats[:spdef]
    @speed_stat = stats[:speed]
    @hp = [(@maxhp * hp_rate).round,1].max unless dead?
    @hp = @maxhp if @hp > @maxhp

    if @scene != nil && actual_pmd != @species
      @scene.log_event(:progression,
        log_name+" VISUAL_FALLBACK actual_pmd="+actual_pmd.to_s+
        " using="+@species.to_s)
    end
    if @scene != nil && old_key != @key
      @scene.log_event(:evolution,
        log_name+" UNIT_SYNC "+old_key.to_s+"->"+@key.to_s+
        " Lv="+level.to_s)
    end
    return true
  end

  def gain_progression_exp(amount)
    result = @pokemon_instance.gain_exp(amount,true)
    if @scene != nil && result[:gained] > 0
      @scene.log_event(:exp,
        log_name+" +"+result[:gained].to_s+
        " EXP="+@pokemon_instance.exp.to_s+" Lv="+level.to_s)
    end
    for lv in result[:levels]
      @scene.log_event(:level_up,log_name+" LEVEL_UP -> "+lv.to_s) if @scene
    end
    for move in result[:moves]
      @scene.log_event(:move_learn,log_name+" LEARN "+move.to_s) if @scene
    end
    for evo in result[:evolutions]
      @scene.log_event(:evolution,
        log_name+" EVOLVE "+evo[:from].to_s+"->"+evo[:to].to_s+
        " uid="+evo[:uid].to_s) if @scene
    end
    sync_from_pokemon_instance if
      !result[:levels].empty? || !result[:evolutions].empty?
    return result
  end

  alias pmd_ac_v012_configure_as_summon configure_as_summon unless method_defined?(:pmd_ac_v012_configure_as_summon)
  def configure_as_summon(owner, options = nil)
    options = {} if options == nil
    stat_scale = (options[:stat_scale] || 1.0).to_f
    pmd_ac_v012_configure_as_summon(owner,options)
    @spatk = [(@spatk * stat_scale).round,1].max
    @spdef = [(@spdef * stat_scale).round,1].max
    return self
  end

  def calculate_damage(target_unit, power, category = :physical,
                       move_type = :normal, random_percent = nil)
    category = :physical if category == nil || category == :status
    attack_stat = category == :special ? special_attack : atk
    defense_stat = category == :special ?
                   target_unit.special_defense : target_unit.defense
    defense_stat = [defense_stat.to_i,1].max
    power = [power.to_i,1].max

    level_factor = (2 * level / 5) + 2
    base = (((level_factor * power * attack_stat) / defense_stat) / 50) + 2
    base = [(base * PMD_AC::POKEMON_DAMAGE_SCALE).round,1].max

    stab = pokemon_types.include?(move_type) ?
           PMD_AC::POKEMON_STAB_MULTIPLIER : 1.0
    effectiveness = PMD_AC.type_effectiveness(
      move_type,
      target_unit.respond_to?(:pokemon_types) ? target_unit.pokemon_types : [])

    if effectiveness <= 0.0
      @scene.log_event(:type,
        log_name+" -> "+target_unit.log_name+
        " type="+move_type.to_s+" IMMUNE") if @scene != nil
      return 0
    end

    roll = random_percent
    if roll == nil
      roll = PMD_AC::POKEMON_RANDOM_MIN +
             rand(PMD_AC::POKEMON_RANDOM_MAX-PMD_AC::POKEMON_RANDOM_MIN+1)
    end
    roll = PMD_AC.clamp(
      roll.to_i,PMD_AC::POKEMON_RANDOM_MIN,PMD_AC::POKEMON_RANDOM_MAX)
    damage = (base.to_f * stab * effectiveness * roll.to_f / 100.0).floor
    damage = [damage,1].max

    if @scene != nil && (stab != 1.0 || effectiveness != 1.0)
      @scene.log_event(:type,
        log_name+" -> "+target_unit.log_name+
        " move_type="+move_type.to_s+
        " category="+category.to_s+
        " STAB="+sprintf("%.2f",stab)+
        " effectiveness="+sprintf("%.2f",effectiveness))
    end
    return damage
  end
end

# Battle Object compatibility with Pokémon damage formula.
class Game_PMDBattleObject
  def special_defense
    return 1
  end

  def pokemon_types
    return []
  end

  def level
    return 1
  end
end

#==============================================================================
# ■ Scene_PMDChessPrototype v0.12
#==============================================================================
class Scene_PMD_AutoChess
  # Persistent ally roster, fresh enemies.
  def create_units
    @units = []
    id = 0
    slot = 0
    for entry in PMD_AC::ALLY_SETUP
      profile = PMD_AC.unit_profile(entry[0]) || {}
      instance = PMD_AC.ally_roster_instance(
        slot,entry[0],profile[:start_level] || PMD_AC::POKEMON_DEFAULT_LEVEL)
      unit = Game_PMDChessUnit.new(
        id,instance.species_key,:ally,entry[1],entry[2],instance)
      unit.scene = self
      @units.push(unit)
      id += 1
      slot += 1
    end

    for entry in PMD_AC::ENEMY_SETUP
      profile = PMD_AC.unit_profile(entry[0]) || {}
      instance = PMD_PokemonInstance.new(
        entry[0],profile[:start_level] || PMD_AC::POKEMON_DEFAULT_LEVEL)
      unit = Game_PMDChessUnit.new(
        id,entry[0],:enemy,entry[1],entry[2],instance)
      unit.scene = self
      @units.push(unit)
      id += 1
    end
    @next_unit_id = id
  end

  # Pokémon category/type aware direct damage, preserving v0.10 mechanics.
  def deal_direct_damage(user, target, power, options = nil)
    return 0 if user == nil || target == nil || target.dead?
    options = {} if options == nil
    modifier = options[:modifier]

    final_power = power.to_f
    final_power *= (modifier[:power_multiplier] || 1.0).to_f if modifier
    final_power = final_power.round

    if options.has_key?(:fixed_damage)
      damage = [options[:fixed_damage].to_i,1].max
    else
      skill_data = options[:skill_data]
      category = options[:damage_category]
      move_type = options[:move_type]
      category = skill_data[:damage_category] if
        category == nil && skill_data != nil
      move_type = skill_data[:move_type] if
        move_type == nil && skill_data != nil
      category = :physical if category == nil
      move_type = user.respond_to?(:basic_move_type) ?
                  user.basic_move_type : :normal if move_type == nil
      damage = user.calculate_damage(
        target,final_power,category,move_type,options[:random_percent])
    end

    return 0 if damage <= 0

    directional = options.has_key?(:directional) ? options[:directional] : true
    if directional
      arc = target.incoming_arc_from(user)
      mult = target.directional_damage_multiplier(arc)
      before_direction = damage
      damage = [(damage.to_f * mult).round,1].max
      log_event(:direction,
        user.log_name+" -> "+target.log_name+
        " arc="+arc.to_s+
        " mult="+sprintf("%.2f",mult.to_f)+
        " damage="+before_direction.to_s+"->"+damage.to_s)
      if arc == :front
        log_event(:front_guard,
          target.log_name+" FRONT_GUARD vs "+user.log_name+
          " mult="+sprintf("%.2f",mult.to_f))
      elsif arc == :back
        log_event(:back_attack,
          user.log_name+" BACK_ATTACK -> "+target.log_name+
          " mult="+sprintf("%.2f",mult.to_f))
      end
    end

    can_crit = options.has_key?(:can_crit) ? options[:can_crit] : true
    critical = false
    if can_crit
      if modifier != nil && modifier[:force_crit]
        critical = true
      else
        bonus = options[:crit_bonus] || 0.0
        rate = PMD_AC.clamp(user.crit_rate + bonus.to_f,0.0,1.0)
        critical = rand < rate
      end
    end

    if critical
      mult = options[:crit_multiplier] || user.crit_multiplier
      damage = [(damage * mult.to_f).round,1].max
      log_event(:crit,
        user.log_name+" -> "+target.log_name+
        " damage="+damage.to_s+" mult="+sprintf("%.2f",mult.to_f))
      play_crit_se(user,options[:skill_data])
    end

    grant_energy = options.has_key?(:grant_energy) ?
                   options[:grant_energy] : true
    target.receive_damage(damage,user,grant_energy,false,critical)

    play_skill_se(user,:hit,options[:skill_data]) if options[:skill_data]

    if modifier != nil && modifier[:effects] != nil && target.alive?
      temp = {:effects=>modifier[:effects],:can_crit=>false}
      apply_skill_effects(user,target,temp,1.0)
    end
    return damage
  end

  def award_battle_exp(winner_team)
    return unless winner_team == :ally
    return unless verification_mode == :normal
    winners = core_living_units(:ally)
    return if winners.empty?
    defeated = []
    for unit in @units
      next unless unit.team == :enemy
      next unless unit.counts_for_victory?
      defeated.push(unit) if unit.dead?
    end
    return if defeated.empty?

    reward = 0
    for enemy in defeated
      reward += PMD_AC.exp_reward_for(
        enemy.species_key,enemy.level,winners.size)
    end
    reward = [reward,1].max
    log_event(:exp,
      "BATTLE_REWARD exp_each="+reward.to_s+
      " defeated="+defeated.size.to_s)
    for unit in winners
      unit.gain_progression_exp(reward)
    end
  end

  # Replaces original only to insert battle EXP.
  def check_battle_end
    allies = core_living_units(:ally)
    enemies = core_living_units(:enemy)
    refresh_footer if @logic_count == 0
    return if !allies.empty? && !enemies.empty?

    @battle_end = true
    @phase = :result
    winner_team = enemies.empty? ? :ally : :enemy
    @result_text = winner_team == :ally ? "藍方勝利" : "紅方勝利"
    @result_text += "｜實際落空 " + @miss_count.to_s + " 次"
    log_event(:battle,
      "END #"+@battle_log_battle_id.to_s+" result="+@result_text)

    award_battle_exp(winner_team)
    log_battle_summary

    for unit in @units
      unit.stop_combat
    end
    winners = core_living_units(winner_team)
    for unit in winners
      unit.start_victory_celebration
      log_event(:victory,
        unit.log_name+" MOVE_BOUNCE facing=down(2) height="+
        PMD_AC::VICTORY_BOUNCE_HEIGHT.to_i.to_s)
    end

    dispose_projectile_sprites
    @summon_removal_queue = []
    clear_battle_objects(:battle_end)
    dispose_battle_object_sprites
    show_result
    refresh_header
    refresh_footer
  end

  # Progression mode needs the same deterministic sandbox as Identity.
  alias pmd_ac_v012_prepare_verification_battle prepare_verification_battle unless method_defined?(:pmd_ac_v012_prepare_verification_battle)
  def prepare_verification_battle
    pmd_ac_v012_prepare_verification_battle
    if verification_mode == :progression
      for unit in @units
        unit.verification_energy_sandbox(true)
        unit.verification_combat_sandbox(true)
      end
    end
  end

  alias pmd_ac_v012_update_auras update_auras unless method_defined?(:pmd_ac_v012_update_auras)
  def update_auras
    return if verification_mode == :progression
    pmd_ac_v012_update_auras
  end

  #--------------------------------------------------------------------------
  # ● PROGRESSION Verification Helpers
  #--------------------------------------------------------------------------
  def verify_progression_base_stats(tag)
    return if @verification_done[tag]
    expected = {
      :bulbasaur=>[45,49,49,65,65,45],
      :charmander=>[39,52,43,60,50,65],
      :squirtle=>[44,48,65,50,64,43],
      :caterpie=>[45,30,35,20,20,45],
      :rattata=>[30,56,35,25,35,72],
      :pikachu=>[35,55,40,50,50,90]
    }
    pass = true
    for key in expected.keys
      pass = false unless PMD_AC.base_stats(key) == expected[key]
    end
    log_event(:verify,tag.to_s.upcase+" pass="+(pass ? "1" : "0"))
    @verification_done[tag] = true
  end

  def verify_progression_stat_formula(tag)
    return if @verification_done[tag]
    stats = PMD_AC.pokemon_stats(:bulbasaur,15)
    combat = PMD_AC.combat_stats(:bulbasaur,15)
    pass = stats != nil &&
           combat[:hp] == (stats[:hp]*PMD_AC::POKEMON_COMBAT_HP_SCALE).round
    log_event(:verify,
      tag.to_s.upcase+" pass="+(pass ? "1" : "0")+
      " raw=HP"+stats[:hp].to_s+
      "/A"+stats[:atk].to_s+
      "/D"+stats[:def].to_s+
      "/SA"+stats[:spatk].to_s+
      "/SD"+stats[:spdef].to_s+
      "/S"+stats[:speed].to_s+
      " combat_hp="+combat[:hp].to_s)
    @verification_done[tag] = true
  end

  def verify_progression_level_evolution(tag)
    return if @verification_done[tag]
    instance = PMD_PokemonInstance.new(
      :bulbasaur,15,
      {:instance_uid=>777001,:runtime_actor_id=>501,:template_actor_id=>7})
    uid = instance.instance_uid
    line = instance.evolution_line_key
    before = instance.combat_stats
    result = instance.gain_exp(instance.exp_to_next_level,true)
    after = instance.combat_stats
    pass = instance.level == 16 &&
           instance.species_key == :ivysaur &&
           instance.evolution_stage == 2 &&
           instance.instance_uid == uid &&
           instance.evolution_line_key == line &&
           instance.runtime_actor_id == 501 &&
           instance.template_actor_id == 7 &&
           result[:moves].include?(:ricochet_seed) &&
           after[:hp] > before[:hp] &&
           after[:spatk] > before[:spatk]
    log_event(:verify,
      tag.to_s.upcase+" pass="+(pass ? "1" : "0")+
      " Lv=15->"+instance.level.to_s+
      " species=bulbasaur->"+instance.species_key.to_s+
      " uid_same="+(instance.instance_uid==uid ? "1" : "0")+
      " line_same="+(instance.evolution_line_key==line ? "1" : "0")+
      " learned=["+result[:moves].collect{|x|x.to_s}.join(",")+"]"+
      " hp="+before[:hp].to_s+"->"+after[:hp].to_s)
    @verification_done[tag] = true
  end

  def verify_progression_item_evolution(tag)
    return if @verification_done[tag]
    instance = PMD_PokemonInstance.new(:pikachu,25,{:instance_uid=>777025})
    wrong = instance.evolve_with_item(:water_stone)
    good = instance.evolve_with_item(:thunder_stone)
    pass = wrong == nil && good != nil &&
           instance.species_key == :raichu &&
           instance.instance_uid == 777025
    log_event(:verify,
      tag.to_s.upcase+" pass="+(pass ? "1" : "0")+
      " species="+instance.species_key.to_s+
      " uid="+instance.instance_uid.to_s)
    @verification_done[tag] = true
  end

  def verify_progression_damage_formula(tag)
    return if @verification_done[tag]
    charmander = verification_unit(:ally,:charmander)
    caterpie = verification_unit(:enemy,:caterpie)
    pikachu = verification_unit(:enemy,:pikachu)
    squirtle = verification_unit(:ally,:squirtle)
    if charmander == nil || caterpie == nil || pikachu == nil || squirtle == nil
      @verification_done[tag] = true
      return
    end
    fire = charmander.calculate_damage(caterpie,100,:special,:fire,100)
    normal = charmander.calculate_damage(caterpie,100,:special,:normal,100)
    electric = pikachu.calculate_damage(squirtle,100,:special,:electric,100)
    pass = fire > normal && electric > normal
    log_event(:verify,
      tag.to_s.upcase+" pass="+(pass ? "1" : "0")+
      " fire_STAB_super="+fire.to_s+
      " normal="+normal.to_s+
      " electric_STAB_super="+electric.to_s)
    @verification_done[tag] = true
  end

  def verify_progression_roster(tag)
    return if @verification_done[tag]
    a = PMD_AC.ally_roster_instance(0,:bulbasaur,15)
    b = PMD_AC.ally_roster_instance(0,:bulbasaur,15)
    pass = a.equal?(b) && a.instance_uid == b.instance_uid
    log_event(:verify,
      tag.to_s.upcase+" pass="+(pass ? "1" : "0")+
      " uid_a="+a.instance_uid.to_s+
      " uid_b="+b.instance_uid.to_s+
      " same_object="+(a.equal?(b) ? "1" : "0"))
    @verification_done[tag] = true
  end

  def verify_progression_profile_fallback(tag)
    return if @verification_done[tag]
    profile = PMD_AC.unit_profile(:ivysaur)
    visual = PMD_AC.pmd_visual_species(:ivysaur,profile)
    pass = profile != nil && profile[:name] == "妙蛙草" &&
           PMD_AC.species_identity_data(:ivysaur)[:pmd_species] == "0002"
    log_event(:verify,
      tag.to_s.upcase+" pass="+(pass ? "1" : "0")+
      " source="+(profile[:profile_source] || :direct).to_s+
      " actual_pmd=0002 visual_pmd="+visual.to_s)
    @verification_done[tag] = true
  end

  alias pmd_ac_v012_update_verification_script update_verification_script unless method_defined?(:pmd_ac_v012_update_verification_script)
  def update_verification_script
    if verification_mode != :progression
      pmd_ac_v012_update_verification_script
      return
    end

    @verification_frame += 1
    verify_progression_base_stats(:progression_base_stats) if
      @verification_frame >= 4
    verify_progression_stat_formula(:progression_stat_formula) if
      @verification_frame >= 24
    verify_progression_level_evolution(:progression_level_evolution) if
      @verification_frame >= 52
    verify_progression_item_evolution(:progression_item_evolution) if
      @verification_frame >= 82
    verify_progression_damage_formula(:progression_damage_formula) if
      @verification_frame >= 112
    verify_progression_roster(:progression_roster) if
      @verification_frame >= 144
    verify_progression_profile_fallback(:progression_profile_fallback) if
      @verification_frame >= 174
    complete_verification_mode if @verification_frame >=
      PMD_AC::VERIFICATION_PROGRESSION_END_FRAME
  end
end



#==============================================================================
# ■ PMD AutoChess v0.13 Extension
#    Individual System / IV / Nature / Ability / Persistent AI
#==============================================================================
module PMD_AC
  remove_const(:VERIFICATION_MODES) if const_defined?(:VERIFICATION_MODES)
  VERIFICATION_MODES = [:normal, :control, :beam, :zone, :hit, :energy,
                        :direction, :object, :summon, :identity,
                        :progression, :individual]

  remove_const(:VERIFICATION_LABELS) if const_defined?(:VERIFICATION_LABELS)
  VERIFICATION_LABELS = {
    :normal=>"NORMAL", :control=>"CONTROL", :beam=>"BEAM", :zone=>"ZONE",
    :hit=>"HIT", :energy=>"ENERGY", :direction=>"DIRECTION",
    :object=>"OBJECT", :summon=>"SUMMON", :identity=>"IDENTITY",
    :progression=>"PROGRESSION", :individual=>"INDIVIDUAL"
  }

  VERIFICATION_INDIVIDUAL_END_FRAME = 260 unless
    const_defined?(:VERIFICATION_INDIVIDUAL_END_FRAME)

  #--------------------------------------------------------------------------
  # ● Nature
  #--------------------------------------------------------------------------
  # HP 不受 Nature 影響。
  # :up / :down 使用 Pokémon 六圍鍵。
  NATURE_DATA = {
    :hardy   =>{:up=>:atk,   :down=>:atk},
    :lonely  =>{:up=>:atk,   :down=>:def},
    :brave   =>{:up=>:atk,   :down=>:speed},
    :adamant =>{:up=>:atk,   :down=>:spatk},
    :naughty =>{:up=>:atk,   :down=>:spdef},

    :bold    =>{:up=>:def,   :down=>:atk},
    :docile  =>{:up=>:def,   :down=>:def},
    :relaxed =>{:up=>:def,   :down=>:speed},
    :impish  =>{:up=>:def,   :down=>:spatk},
    :lax     =>{:up=>:def,   :down=>:spdef},

    :timid   =>{:up=>:speed, :down=>:atk},
    :hasty   =>{:up=>:speed, :down=>:def},
    :serious =>{:up=>:speed, :down=>:speed},
    :jolly   =>{:up=>:speed, :down=>:spatk},
    :naive   =>{:up=>:speed, :down=>:spdef},

    :modest  =>{:up=>:spatk, :down=>:atk},
    :mild    =>{:up=>:spatk, :down=>:def},
    :quiet   =>{:up=>:spatk, :down=>:speed},
    :bashful =>{:up=>:spatk, :down=>:spatk},
    :rash    =>{:up=>:spatk, :down=>:spdef},

    :calm    =>{:up=>:spdef, :down=>:atk},
    :gentle  =>{:up=>:spdef, :down=>:def},
    :sassy   =>{:up=>:spdef, :down=>:speed},
    :careful =>{:up=>:spdef, :down=>:spatk},
    :quirky  =>{:up=>:spdef, :down=>:spdef}
  } unless const_defined?(:NATURE_DATA)

  #--------------------------------------------------------------------------
  # ● Ability Registry
  #--------------------------------------------------------------------------
  ABILITY_DATA = {
    :overgrow      =>{:name=>"茂盛",       :hook=>:low_hp_type,
                      :type=>:grass, :threshold=>1.0/3.0, :mult=>1.5},
    :blaze         =>{:name=>"猛火",       :hook=>:low_hp_type,
                      :type=>:fire, :threshold=>1.0/3.0, :mult=>1.5},
    :torrent       =>{:name=>"激流",       :hook=>:low_hp_type,
                      :type=>:water, :threshold=>1.0/3.0, :mult=>1.5},
    :guts          =>{:name=>"毅力",       :hook=>:status_physical,
                      :mult=>1.5},
    :tinted_lens   =>{:name=>"有色眼鏡",   :hook=>:resist_break,
                      :mult=>2.0},
    :lightning_rod =>{:name=>"避雷針",     :hook=>:type_immunity,
                      :type=>:electric},

    # 已建立身份／槽位，但需要後續 Weather / Accuracy /
    # Secondary-Effect 模組才完整發揮。
    :chlorophyll   =>{:name=>"葉綠素",     :hook=>:weather_speed},
    :solar_power   =>{:name=>"太陽之力",   :hook=>:weather_spatk},
    :rain_dish     =>{:name=>"雨盤",       :hook=>:weather_heal},
    :shield_dust   =>{:name=>"鱗粉",       :hook=>:secondary_block},
    :run_away      =>{:name=>"逃跑",       :hook=>:escape},
    :shed_skin     =>{:name=>"蛻皮",       :hook=>:periodic_cleanse},
    :compound_eyes =>{:name=>"複眼",       :hook=>:accuracy},
    :static        =>{:name=>"靜電",       :hook=>:contact_status},
    :hustle        =>{:name=>"活力",       :hook=>:physical_power_accuracy}
  } unless const_defined?(:ABILITY_DATA)

  # 能力保存「槽位」而不是死存 Ability Key。
  # 進化後以同一槽位重新解析 Species Ability。
  SPECIES_ABILITY_SLOTS = {
    :bulbasaur =>{:primary=>:overgrow,      :hidden=>:chlorophyll},
    :ivysaur   =>{:primary=>:overgrow,      :hidden=>:chlorophyll},
    :venusaur  =>{:primary=>:overgrow,      :hidden=>:chlorophyll},

    :charmander=>{:primary=>:blaze,         :hidden=>:solar_power},
    :charmeleon=>{:primary=>:blaze,         :hidden=>:solar_power},
    :charizard =>{:primary=>:blaze,         :hidden=>:solar_power},

    :squirtle  =>{:primary=>:torrent,       :hidden=>:rain_dish},
    :wartortle =>{:primary=>:torrent,       :hidden=>:rain_dish},
    :blastoise =>{:primary=>:torrent,       :hidden=>:rain_dish},

    :caterpie  =>{:primary=>:shield_dust,   :hidden=>:run_away},
    :metapod   =>{:primary=>:shed_skin},
    :butterfree=>{:primary=>:compound_eyes, :hidden=>:tinted_lens},

    :rattata   =>{:primary=>:run_away, :secondary=>:guts, :hidden=>:hustle},
    :raticate  =>{:primary=>:run_away, :secondary=>:guts, :hidden=>:hustle},

    :pikachu   =>{:primary=>:static, :hidden=>:lightning_rod},
    :raichu    =>{:primary=>:static, :hidden=>:lightning_rod}
  } unless const_defined?(:SPECIES_ABILITY_SLOTS)

  #--------------------------------------------------------------------------
  # ● Persistent AI Setup
  #--------------------------------------------------------------------------
  AI_TARGET_POLICIES = [
    :nearest, :lowest_hp, :lowest_hp_percent, :lowest_def, :highest_atk,
    :farthest, :backline, :ranged_first, :melee_first, :cluster,
    :current_attacker, :backline_low_def, :execute, :protect_ally
  ] unless const_defined?(:AI_TARGET_POLICIES)

  AI_MOVEMENT_POLICIES = [
    :frontline, :bruiser, :assassin, :kiter,
    :artillery, :controller, :bodyguard, :berserker
  ] unless const_defined?(:AI_MOVEMENT_POLICIES)

  AI_THREAT_POLICIES = [
    :hold_ground, :normal, :ignore_minor, :responsive, :protective
  ] unless const_defined?(:AI_THREAT_POLICIES)

  AI_SKILL_POLICIES = [
    :current_target, :best_cluster, :execute, :lowest_def, :highest_atk,
    :protect_ally, :heal_critical, :lowest_ally
  ] unless const_defined?(:AI_SKILL_POLICIES)

  AI_PRESETS = {
    :aggressive=>{
      :target_policy=>:execute, :movement_policy=>:bruiser,
      :threat_policy=>:ignore_minor, :skill_policy=>:execute,
      :target_commitment=>75
    },
    :assassin=>{
      :target_policy=>:backline_low_def, :movement_policy=>:assassin,
      :threat_policy=>:ignore_minor, :skill_policy=>:execute,
      :target_commitment=>82
    },
    :defender=>{
      :target_policy=>:protect_ally, :movement_policy=>:bodyguard,
      :threat_policy=>:protective, :skill_policy=>:protect_ally,
      :target_commitment=>88
    },
    :controller=>{
      :target_policy=>:cluster, :movement_policy=>:controller,
      :threat_policy=>:responsive, :skill_policy=>:best_cluster,
      :target_commitment=>58
    },
    :kiter=>{
      :target_policy=>:nearest, :movement_policy=>:kiter,
      :threat_policy=>:responsive, :skill_policy=>:current_target,
      :target_commitment=>52
    }
  } unless const_defined?(:AI_PRESETS)

  class << self
    def normalize_ivs(ivs)
      source = ivs || []
      result = []
      6.times do |i|
        value = source[i]
        value = rand(32) if value == nil
        result.push(clamp(value.to_i,0,31))
      end
      return result
    end

    def random_nature
      keys = NATURE_DATA.keys
      return keys[rand(keys.size)]
    end

    def nature_valid?(key)
      return NATURE_DATA.has_key?(key)
    end

    def nature_multipliers(nature_key)
      data = NATURE_DATA[nature_key] || NATURE_DATA[:hardy]
      result = {
        :hp=>1.0, :atk=>1.0, :def=>1.0,
        :spatk=>1.0, :spdef=>1.0, :speed=>1.0
      }
      if data[:up] != data[:down]
        result[data[:up]] = 1.10
        result[data[:down]] = 0.90
      end
      return [1.0, result[:atk], result[:def],
              result[:spatk], result[:spdef], result[:speed]]
    end

    def ability_slots(species_key)
      return SPECIES_ABILITY_SLOTS[species_key] || {}
    end

    def normal_ability_slots(species_key)
      slots = ability_slots(species_key)
      result = []
      result.push(:primary) if slots[:primary] != nil
      result.push(:secondary) if slots[:secondary] != nil
      return result
    end

    def default_ability_slot(species_key)
      slots = normal_ability_slots(species_key)
      return :primary if slots.empty?
      return slots[rand(slots.size)]
    end

    def resolve_ability(species_key, slot)
      slots = ability_slots(species_key)
      result = slots[slot]
      result = slots[:primary] if result == nil
      return result
    end

    def ability_data(key)
      return ABILITY_DATA[key] || {}
    end

    def valid_ai_option?(key, value)
      case key
      when :target_policy
        return AI_TARGET_POLICIES.include?(value)
      when :movement_policy
        return AI_MOVEMENT_POLICIES.include?(value)
      when :threat_policy
        return AI_THREAT_POLICIES.include?(value)
      when :skill_policy
        return AI_SKILL_POLICIES.include?(value)
      when :target_commitment
        return value.to_i >= 0 && value.to_i <= 100
      end
      return false
    end
  end
end


#==============================================================================
# ■ PMD_PokemonInstance v0.13
#==============================================================================
class PMD_PokemonInstance
  attr_reader :ivs
  attr_reader :nature_key
  attr_reader :ability_slot
  attr_reader :ai_setup

  alias pmd_ac_v013_initialize initialize unless method_defined?(:pmd_ac_v013_initialize)
  def initialize(species_key, level = nil, options = nil)
    options = {} if options == nil
    pmd_ac_v013_initialize(species_key,level,options)

    @ivs = PMD_AC.normalize_ivs(options[:ivs])

    nature = options[:nature]
    nature = PMD_AC.random_nature unless PMD_AC.nature_valid?(nature)
    @nature_key = nature

    slot = options[:ability_slot]
    valid_slots = PMD_AC.ability_slots(species_key)
    if slot == nil || valid_slots[slot] == nil
      slot = PMD_AC.default_ability_slot(species_key)
    end
    @ability_slot = slot

    @ai_setup = {}
    apply_ai_setup_hash(options[:ai_setup]) if options[:ai_setup] != nil
  end

  # 舊存檔／v0.12 instance 進入 v0.13 時補資料。
  def ensure_individual_data
    @ivs = PMD_AC.normalize_ivs(nil) if @ivs == nil
    @nature_key = PMD_AC.random_nature unless
      PMD_AC.nature_valid?(@nature_key)
    if @ability_slot == nil ||
       PMD_AC.ability_slots(species_key)[@ability_slot] == nil
      @ability_slot = PMD_AC.default_ability_slot(species_key)
    end
    @ai_setup = {} if @ai_setup == nil
  end

  def ivs
    ensure_individual_data
    return @ivs.dup
  end

  def nature_key
    ensure_individual_data
    return @nature_key
  end

  def ability_slot
    ensure_individual_data
    return @ability_slot
  end

  def ability_key
    ensure_individual_data
    return PMD_AC.resolve_ability(species_key,@ability_slot)
  end

  def ability_data
    return PMD_AC.ability_data(ability_key)
  end

  def nature_multipliers
    ensure_individual_data
    return PMD_AC.nature_multipliers(@nature_key)
  end

  def pokemon_stats
    ensure_individual_data
    return PMD_AC.pokemon_stats(
      species_key,@level,@ivs,
      [PMD_AC::POKEMON_PLACEHOLDER_EV] * 6,
      nature_multipliers)
  end

  def combat_stats
    ensure_individual_data
    return PMD_AC.combat_stats(
      species_key,@level,@ivs,
      [PMD_AC::POKEMON_PLACEHOLDER_EV] * 6,
      nature_multipliers)
  end

  def set_ivs(values)
    @ivs = PMD_AC.normalize_ivs(values)
    return @ivs.dup
  end

  def set_nature(key)
    return false unless PMD_AC.nature_valid?(key)
    @nature_key = key
    return true
  end

  def set_ability_slot(slot)
    return false if PMD_AC.ability_slots(species_key)[slot] == nil
    @ability_slot = slot
    return true
  end

  def ai_setup
    ensure_individual_data
    return @ai_setup.dup
  end

  def set_ai_option(key, value)
    ensure_individual_data
    return false unless PMD_AC.valid_ai_option?(key,value)
    @ai_setup[key] = (key == :target_commitment ? value.to_i : value)
    return true
  end

  def clear_ai_option(key)
    ensure_individual_data
    @ai_setup.delete(key)
  end

  def clear_ai_setup
    @ai_setup = {}
  end

  def apply_ai_setup_hash(hash)
    return if hash == nil
    for key in hash.keys
      set_ai_option(key,hash[key])
    end
  end

  def apply_ai_preset(key)
    preset = PMD_AC::AI_PRESETS[key]
    return false if preset == nil
    @ai_setup = {}
    apply_ai_setup_hash(preset)
    return true
  end

  def individual_signature
    ensure_individual_data
    return "uid="+instance_uid.to_s+
           " IV=["+@ivs.join(",")+"]"+
           " nature="+@nature_key.to_s+
           " ability_slot="+@ability_slot.to_s+
           " ability="+ability_key.to_s+
           " ai={"+@ai_setup.collect{|k,v| k.to_s+"="+v.to_s}.join(",")+"}"
  end
end


#==============================================================================
# ■ Game_PMDChessUnit v0.13
#==============================================================================
class Game_PMDChessUnit
  alias pmd_ac_v013_initialize initialize unless method_defined?(:pmd_ac_v013_initialize)
  def initialize(id, key, team, cell_x, cell_y, pokemon_instance = nil)
    pmd_ac_v013_initialize(id,key,team,cell_x,cell_y,pokemon_instance)
    apply_persistent_ai_setup
  end

  def nature_key
    return @pokemon_instance == nil ? :hardy : @pokemon_instance.nature_key
  end

  def ability_key
    return @pokemon_instance == nil ? nil : @pokemon_instance.ability_key
  end

  def ability_slot
    return @pokemon_instance == nil ? :primary :
                                     @pokemon_instance.ability_slot
  end

  def ability_data
    return PMD_AC.ability_data(ability_key)
  end

  def ivs
    return @pokemon_instance == nil ?
           [PMD_AC::POKEMON_PLACEHOLDER_IV] * 6 :
           @pokemon_instance.ivs
  end

  def apply_persistent_ai_setup
    return if @pokemon_instance == nil
    setup = @pokemon_instance.ai_setup
    return if setup == nil || setup.empty?

    if setup[:target_policy] != nil
      @target_policy = setup[:target_policy]
      @target_rule = @target_policy
    end
    @movement_policy = setup[:movement_policy] if
      setup[:movement_policy] != nil
    @threat_policy = setup[:threat_policy] if
      setup[:threat_policy] != nil
    @skill_policy = setup[:skill_policy] if
      setup[:skill_policy] != nil
    if setup[:target_commitment] != nil
      @target_commitment = PMD_AC.clamp(
        setup[:target_commitment].to_i,0,100)
    end
  end

  def major_status_for_guts?
    return status?(:poison) || status?(:burn)
  end

  def ability_outgoing_multiplier(move_type, category, effectiveness = 1.0)
    data = ability_data
    return 1.0 if data == nil || data.empty?

    case data[:hook]
    when :low_hp_type
      hp_rate = @hp.to_f / [@maxhp,1].max.to_f
      if move_type == data[:type] &&
         hp_rate <= data[:threshold].to_f
        return data[:mult].to_f
      end

    when :status_physical
      if category == :physical && major_status_for_guts?
        return data[:mult].to_f
      end

    when :resist_break
      if effectiveness > 0.0 && effectiveness < 1.0
        return data[:mult].to_f
      end

    when :physical_power_accuracy
      return 1.5 if category == :physical
    end
    return 1.0
  end

  def ability_incoming_multiplier(move_type, category)
    data = ability_data
    return 1.0 if data == nil || data.empty?
    if data[:hook] == :type_immunity && move_type == data[:type]
      return 0.0
    end
    return 1.0
  end

  def verification_set_hp_percent(rate)
    rate = PMD_AC.clamp(rate.to_f,0.01,1.0)
    @hp = [(@maxhp * rate).floor,1].max
  end

  # Pokémon damage + Ability Hooks.
  def calculate_damage(target_unit, power, category = :physical,
                       move_type = :normal, random_percent = nil)
    category = :physical if category == nil || category == :status
    attack_stat = category == :special ? special_attack : atk
    defense_stat = category == :special ?
                   target_unit.special_defense : target_unit.defense
    defense_stat = [defense_stat.to_i,1].max
    power = [power.to_i,1].max

    level_factor = (2 * level / 5) + 2
    base = (((level_factor * power * attack_stat) / defense_stat) / 50) + 2
    base = [(base * PMD_AC::POKEMON_DAMAGE_SCALE).round,1].max

    stab = pokemon_types.include?(move_type) ?
           PMD_AC::POKEMON_STAB_MULTIPLIER : 1.0
    effectiveness = PMD_AC.type_effectiveness(
      move_type,
      target_unit.respond_to?(:pokemon_types) ?
      target_unit.pokemon_types : [])

    if effectiveness <= 0.0
      @scene.log_event(:type,
        log_name+" -> "+target_unit.log_name+
        " type="+move_type.to_s+" TYPE_IMMUNE") if @scene != nil
      return 0
    end

    ability_out = ability_outgoing_multiplier(
      move_type,category,effectiveness)

    ability_in = target_unit.respond_to?(:ability_incoming_multiplier) ?
                 target_unit.ability_incoming_multiplier(
                   move_type,category) : 1.0

    if ability_in <= 0.0
      if @scene != nil
        @scene.log_event(:ability,
          target_unit.log_name+" "+target_unit.ability_key.to_s+
          " IMMUNE move_type="+move_type.to_s+
          " from="+log_name)
      end
      return 0
    end

    roll = random_percent
    if roll == nil
      roll = PMD_AC::POKEMON_RANDOM_MIN +
             rand(PMD_AC::POKEMON_RANDOM_MAX -
                  PMD_AC::POKEMON_RANDOM_MIN + 1)
    end
    roll = PMD_AC.clamp(
      roll.to_i,PMD_AC::POKEMON_RANDOM_MIN,PMD_AC::POKEMON_RANDOM_MAX)

    damage = base.to_f * stab * effectiveness *
             ability_out * ability_in * roll.to_f / 100.0
    damage = [damage.floor,1].max

    if @scene != nil &&
       (stab != 1.0 || effectiveness != 1.0 ||
        ability_out != 1.0 || ability_in != 1.0)
      @scene.log_event(:type,
        log_name+" -> "+target_unit.log_name+
        " move_type="+move_type.to_s+
        " category="+category.to_s+
        " STAB="+sprintf("%.2f",stab)+
        " effectiveness="+sprintf("%.2f",effectiveness)+
        " ability_out="+sprintf("%.2f",ability_out)+
        " ability_in="+sprintf("%.2f",ability_in))
    end

    if @scene != nil && ability_out != 1.0
      @scene.log_event(:ability,
        log_name+" "+ability_key.to_s+
        " OUT_MULT="+sprintf("%.2f",ability_out))
    end
    return damage
  end
end


#==============================================================================
# ■ Scene_PMD_AutoChess v0.13
#==============================================================================
class Scene_PMD_AutoChess
  alias pmd_ac_v013_prepare_verification_battle prepare_verification_battle unless method_defined?(:pmd_ac_v013_prepare_verification_battle)
  def prepare_verification_battle
    pmd_ac_v013_prepare_verification_battle
    if verification_mode == :individual
      for unit in @units
        unit.verification_energy_sandbox(true)
        unit.verification_combat_sandbox(true)
      end
    end
  end

  alias pmd_ac_v013_update_auras update_auras unless method_defined?(:pmd_ac_v013_update_auras)
  def update_auras
    return if verification_mode == :individual
    pmd_ac_v013_update_auras
  end

  #--------------------------------------------------------------------------
  # ● INDIVIDUAL Verification
  #--------------------------------------------------------------------------
  def verify_individual_generated(tag)
    return if @verification_done[tag]
    pass = true
    details = []
    for unit in @units
      next if unit.summoned?
      ivs = unit.ivs
      valid_iv = ivs.size == 6 &&
                 ivs.all? { |x| x.to_i >= 0 && x.to_i <= 31 }
      valid_nature = PMD_AC.nature_valid?(unit.nature_key)
      valid_ability = unit.ability_key != nil
      pass = false unless valid_iv && valid_nature && valid_ability
      details.push(
        unit.species_key.to_s+"#"+unit.instance_uid.to_s+
        " IV="+ivs.join("/")+
        " N="+unit.nature_key.to_s+
        " A="+unit.ability_key.to_s)
    end
    log_event(:verify,
      tag.to_s.upcase+" pass="+(pass ? "1" : "0")+
      " ["+details.join(" | ")+"]")
    @verification_done[tag] = true
  end

  def verify_individual_iv_formula(tag)
    return if @verification_done[tag]
    zero = PMD_PokemonInstance.new(
      :bulbasaur,50,
      {:ivs=>[0,0,0,0,0,0],:nature=>:hardy,:ability_slot=>:primary})
    max = PMD_PokemonInstance.new(
      :bulbasaur,50,
      {:ivs=>[31,31,31,31,31,31],:nature=>:hardy,:ability_slot=>:primary})
    a = zero.pokemon_stats
    b = max.pokemon_stats
    pass = b[:hp] > a[:hp] &&
           b[:atk] > a[:atk] &&
           b[:def] > a[:def] &&
           b[:spatk] > a[:spatk] &&
           b[:spdef] > a[:spdef] &&
           b[:speed] > a[:speed]
    log_event(:verify,
      tag.to_s.upcase+" pass="+(pass ? "1" : "0")+
      " IV0=HP"+a[:hp].to_s+"/A"+a[:atk].to_s+
      "/D"+a[:def].to_s+"/SA"+a[:spatk].to_s+
      "/SD"+a[:spdef].to_s+"/S"+a[:speed].to_s+
      " IV31=HP"+b[:hp].to_s+"/A"+b[:atk].to_s+
      "/D"+b[:def].to_s+"/SA"+b[:spatk].to_s+
      "/SD"+b[:spdef].to_s+"/S"+b[:speed].to_s)
    @verification_done[tag] = true
  end

  def verify_individual_nature(tag)
    return if @verification_done[tag]
    ivs = [15,15,15,15,15,15]
    adamant = PMD_PokemonInstance.new(
      :bulbasaur,50,
      {:ivs=>ivs,:nature=>:adamant,:ability_slot=>:primary})
    modest = PMD_PokemonInstance.new(
      :bulbasaur,50,
      {:ivs=>ivs,:nature=>:modest,:ability_slot=>:primary})
    a = adamant.pokemon_stats
    m = modest.pokemon_stats
    pass = a[:atk] > m[:atk] && m[:spatk] > a[:spatk] &&
           a[:hp] == m[:hp]
    log_event(:verify,
      tag.to_s.upcase+" pass="+(pass ? "1" : "0")+
      " adamant=A"+a[:atk].to_s+"/SA"+a[:spatk].to_s+
      " modest=A"+m[:atk].to_s+"/SA"+m[:spatk].to_s+
      " HP_same="+(a[:hp]==m[:hp] ? "1" : "0"))
    @verification_done[tag] = true
  end

  def verify_individual_ability_evolution(tag)
    return if @verification_done[tag]
    instance = PMD_PokemonInstance.new(
      :caterpie,6,
      {:instance_uid=>880010,
       :ivs=>[15,15,15,15,15,15],
       :nature=>:hardy,
       :ability_slot=>:primary})
    before = instance.ability_key
    result = instance.gain_exp(instance.exp_to_next_level,true)
    after = instance.ability_key
    pass = before == :shield_dust &&
           instance.species_key == :metapod &&
           after == :shed_skin &&
           instance.instance_uid == 880010
    log_event(:verify,
      tag.to_s.upcase+" pass="+(pass ? "1" : "0")+
      " species=caterpie->"+instance.species_key.to_s+
      " ability="+before.to_s+"->"+after.to_s+
      " slot="+instance.ability_slot.to_s+
      " uid="+instance.instance_uid.to_s)
    @verification_done[tag] = true
  end

  def verify_individual_ability_power(tag)
    return if @verification_done[tag]
    ivs = [15,15,15,15,15,15]

    over_i = PMD_PokemonInstance.new(
      :bulbasaur,30,
      {:ivs=>ivs,:nature=>:modest,:ability_slot=>:primary})
    over_u = Game_PMDChessUnit.new(980,:bulbasaur,:ally,0,0,over_i)

    target_i = PMD_PokemonInstance.new(
      :squirtle,30,
      {:ivs=>ivs,:nature=>:hardy,:ability_slot=>:primary})
    target_u = Game_PMDChessUnit.new(981,:squirtle,:enemy,5,0,target_i)

    over_u.verification_set_hp_percent(1.0)
    normal = over_u.calculate_damage(target_u,80,:special,:grass,100)
    over_u.verification_set_hp_percent(0.30)
    boosted = over_u.calculate_damage(target_u,80,:special,:grass,100)

    guts_i = PMD_PokemonInstance.new(
      :rattata,30,
      {:ivs=>ivs,:nature=>:adamant,:ability_slot=>:secondary})
    guts_u = Game_PMDChessUnit.new(982,:rattata,:ally,0,0,guts_i)
    normal_guts = guts_u.calculate_damage(target_u,80,:physical,:normal,100)
    guts_u.apply_status(:poison,{:duration=>120,:value=>4},nil)
    boosted_guts = guts_u.calculate_damage(
      target_u,80,:physical,:normal,100)

    rod_i = PMD_PokemonInstance.new(
      :pikachu,30,
      {:ivs=>ivs,:nature=>:hardy,:ability_slot=>:hidden})
    rod_u = Game_PMDChessUnit.new(983,:pikachu,:enemy,5,0,rod_i)
    electric = target_u.calculate_damage(
      rod_u,80,:special,:electric,100)

    pass = boosted > normal &&
           boosted_guts > normal_guts &&
           electric == 0

    log_event(:verify,
      tag.to_s.upcase+" pass="+(pass ? "1" : "0")+
      " overgrow="+normal.to_s+"->"+boosted.to_s+
      " guts="+normal_guts.to_s+"->"+boosted_guts.to_s+
      " lightning_rod_damage="+electric.to_s)
    @verification_done[tag] = true
  end

  def verify_individual_ai_setup(tag)
    return if @verification_done[tag]
    instance = PMD_PokemonInstance.new(
      :squirtle,20,
      {:ivs=>[15,15,15,15,15,15],
       :nature=>:bold,:ability_slot=>:primary})

    preset_ok = instance.apply_ai_preset(:defender)
    invalid = instance.set_ai_option(:movement_policy,:teleport_everywhere)

    unit1 = Game_PMDChessUnit.new(984,:squirtle,:ally,0,0,instance)
    unit2 = Game_PMDChessUnit.new(985,:squirtle,:ally,0,0,instance)

    pass = preset_ok && !invalid &&
           unit1.target_policy == :protect_ally &&
           unit1.movement_policy == :bodyguard &&
           unit1.threat_policy == :protective &&
           unit1.skill_policy == :protect_ally &&
           unit1.target_commitment == 88 &&
           unit2.movement_policy == :bodyguard

    log_event(:verify,
      tag.to_s.upcase+" pass="+(pass ? "1" : "0")+
      " target="+unit1.target_policy.to_s+
      " move="+unit1.movement_policy.to_s+
      " threat="+unit1.threat_policy.to_s+
      " skill="+unit1.skill_policy.to_s+
      " commitment="+unit1.target_commitment.to_s+
      " invalid_rejected="+(!invalid ? "1" : "0"))
    @verification_done[tag] = true
  end

  def verify_individual_roster_persistence(tag)
    return if @verification_done[tag]
    storage = PMD_AC.roster_storage
    storage.delete(99)

    first = PMD_AC.ally_roster_instance(99,:rattata,20)
    first.set_ivs([31,30,29,28,27,26])
    first.set_nature(:jolly)
    first.set_ability_slot(:secondary)
    first.apply_ai_preset(:assassin)

    second = PMD_AC.ally_roster_instance(99,:rattata,20)

    pass = first.equal?(second) &&
           second.ivs == [31,30,29,28,27,26] &&
           second.nature_key == :jolly &&
           second.ability_key == :guts &&
           second.ai_setup[:movement_policy] == :assassin

    log_event(:verify,
      tag.to_s.upcase+" pass="+(pass ? "1" : "0")+
      " uid="+second.instance_uid.to_s+
      " IV=["+second.ivs.join(",")+"]"+
      " nature="+second.nature_key.to_s+
      " ability="+second.ability_key.to_s+
      " ai_move="+second.ai_setup[:movement_policy].to_s)

    # 測試槽不影響正式 0~2 Ally Roster。
    storage.delete(99)
    @verification_done[tag] = true
  end

  alias pmd_ac_v013_update_verification_script update_verification_script unless method_defined?(:pmd_ac_v013_update_verification_script)
  def update_verification_script
    if verification_mode != :individual
      pmd_ac_v013_update_verification_script
      return
    end

    @verification_frame += 1

    verify_individual_generated(:individual_generated) if
      @verification_frame >= 4

    verify_individual_iv_formula(:individual_iv_formula) if
      @verification_frame >= 34

    verify_individual_nature(:individual_nature) if
      @verification_frame >= 68

    verify_individual_ability_evolution(:individual_ability_evolution) if
      @verification_frame >= 104

    verify_individual_ability_power(:individual_ability_power) if
      @verification_frame >= 142

    verify_individual_ai_setup(:individual_ai_setup) if
      @verification_frame >= 184

    verify_individual_roster_persistence(:individual_roster_persistence) if
      @verification_frame >= 220

    complete_verification_mode if @verification_frame >=
      PMD_AC::VERIFICATION_INDIVIDUAL_END_FRAME
  end
end


#==============================================================================
# ■ PMD AutoChess v0.14 Extension
#    MEGA Evolution / Form Change
#==============================================================================
module PMD_AC
  remove_const(:VERIFICATION_MODES) if const_defined?(:VERIFICATION_MODES)
  VERIFICATION_MODES = [:normal, :control, :beam, :zone, :hit, :energy,
                        :direction, :object, :summon, :identity,
                        :progression, :individual, :mega]

  remove_const(:VERIFICATION_LABELS) if const_defined?(:VERIFICATION_LABELS)
  VERIFICATION_LABELS = {
    :normal=>"NORMAL", :control=>"CONTROL", :beam=>"BEAM", :zone=>"ZONE",
    :hit=>"HIT", :energy=>"ENERGY", :direction=>"DIRECTION",
    :object=>"OBJECT", :summon=>"SUMMON", :identity=>"IDENTITY",
    :progression=>"PROGRESSION", :individual=>"INDIVIDUAL",
    :mega=>"MEGA"
  }

  VERIFICATION_MEGA_END_FRAME = 320
  MEGA_PER_TEAM = 1

  MEGA_SE_NAME = ""
  MEGA_SE_VOLUME = 90
  MEGA_SE_PITCH = 100

  ACTION_FALLBACKS[:mega] = [:mega, :charge, :shake, :idle]

  MEGA_FORM_DATA = {
    :venusaur=>{
      :mega=>{
        :base_stats=>[80,100,123,122,120,80],
        :types=>[:grass,:poison],
        :ability=>:thick_fat,
        :visual_candidates=>["0003_Mega","0003-Mega","0003_mega"]
      }
    },
    :charizard=>{
      :mega_x=>{
        :base_stats=>[78,130,111,130,85,100],
        :types=>[:fire,:dragon],
        :ability=>:tough_claws,
        :visual_candidates=>["0006_MegaX","0006-MegaX","0006_mega_x"]
      },
      :mega_y=>{
        :base_stats=>[78,104,78,159,115,100],
        :types=>[:fire,:flying],
        :ability=>:drought,
        :visual_candidates=>["0006_MegaY","0006-MegaY","0006_mega_y"]
      }
    },
    :blastoise=>{
      :mega=>{
        :base_stats=>[79,103,120,135,115,78],
        :types=>[:water],
        :ability=>:mega_launcher,
        :visual_candidates=>["0009_Mega","0009-Mega","0009_mega"]
      }
    }
  }

  ABILITY_DATA[:thick_fat] = {
    :name=>"厚脂肪", :hook=>:incoming_type_reduction,
    :types=>[:fire,:ice], :mult=>0.5
  }
  ABILITY_DATA[:tough_claws] = {
    :name=>"硬爪", :hook=>:contact_power, :mult=>1.30
  }
  ABILITY_DATA[:drought] = {
    :name=>"日照", :hook=>:weather_sun
  }
  ABILITY_DATA[:mega_launcher] = {
    :name=>"超級發射器", :hook=>:pulse_power, :mult=>1.50
  }

  class << self
    def mega_forms_for(species_key)
      MEGA_FORM_DATA[species_key] || {}
    end

    def mega_form_data(species_key, form_key)
      mega_forms_for(species_key)[form_key]
    end

    def mega_available?(species_key)
      !mega_forms_for(species_key).empty?
    end

    def default_mega_form(species_key)
      keys = mega_forms_for(species_key).keys
      return keys[0] if keys.size == 1
      nil
    end

    def form_base_stats(species_key, form_key)
      if form_key && form_key != :normal
        data = mega_form_data(species_key, form_key)
        return data[:base_stats] if data && data[:base_stats]
      end
      base_stats(species_key)
    end

    def form_types(species_key, form_key)
      if form_key && form_key != :normal
        data = mega_form_data(species_key, form_key)
        return (data[:types] || []).dup if data
      end
      data = species_identity_data(species_key)
      data ? (data[:types] || []).dup : []
    end

    def form_ability(species_key, form_key)
      return nil if form_key == nil || form_key == :normal
      data = mega_form_data(species_key, form_key)
      data ? data[:ability] : nil
    end

    def pokemon_stats_from_bases(bases, level, ivs, evs, natures)
      return nil if bases == nil
      {
        :hp=>pokemon_stat(bases[0],level,true,ivs[0],evs[0],1.0),
        :atk=>pokemon_stat(bases[1],level,false,ivs[1],evs[1],natures[1]),
        :def=>pokemon_stat(bases[2],level,false,ivs[2],evs[2],natures[2]),
        :spatk=>pokemon_stat(bases[3],level,false,ivs[3],evs[3],natures[3]),
        :spdef=>pokemon_stat(bases[4],level,false,ivs[4],evs[4],natures[4]),
        :speed=>pokemon_stat(bases[5],level,false,ivs[5],evs[5],natures[5])
      }
    end

    def combat_stats_for_form(species_key, form_key, level, ivs, evs, natures)
      raw = pokemon_stats_from_bases(
        form_base_stats(species_key,form_key), level, ivs, evs, natures)
      return nil if raw == nil
      {
        :hp=>[(raw[:hp]*POKEMON_COMBAT_HP_SCALE).round,1].max,
        :pokemon_hp=>raw[:hp],
        :atk=>raw[:atk], :def=>raw[:def],
        :spatk=>raw[:spatk], :spdef=>raw[:spdef], :speed=>raw[:speed]
      }
    end

    def compiled_visual_species?(key)
      return false if key == nil
      return false if action_database[key] == nil
      FileTest.exist?(PMD_ROOT + key + "/")
    end

    def form_visual_species(instance)
      species_key = instance.species_key
      if instance.form_key != :normal
        data = mega_form_data(species_key, instance.form_key)
        if data
          for key in (data[:visual_candidates] || [])
            return key if compiled_visual_species?(key)
          end
        end
      end
      pmd_visual_species(species_key, unit_profile(species_key))
    end

    def validate_mega_registry
      errors = []
      for species_key in MEGA_FORM_DATA.keys
        errors.push("species:"+species_key.to_s) if
          species_identity_data(species_key) == nil
        for form_key in mega_forms_for(species_key).keys
          data = mega_form_data(species_key,form_key)
          errors.push("stats:"+species_key.to_s+":"+form_key.to_s) if
            data[:base_stats] == nil || data[:base_stats].size != 6
          errors.push("types:"+species_key.to_s+":"+form_key.to_s) if
            data[:types] == nil || data[:types].empty?
          errors.push("ability:"+species_key.to_s+":"+form_key.to_s) if
            ABILITY_DATA[data[:ability]] == nil
        end
      end
      errors
    end
  end
end


class PMD_PokemonInstance
  def mega?
    form_key != :normal
  end

  def mega_available?
    PMD_AC.mega_available?(species_key)
  end

  def mega_forms
    PMD_AC.mega_forms_for(species_key).keys
  end

  def mega_evolve!(requested_form = nil)
    return false if mega?
    form = requested_form || PMD_AC.default_mega_form(species_key)
    return false if form == nil
    return false if PMD_AC.mega_form_data(species_key,form) == nil
    @identity.set_form_key(form)
    @progression_history.push(
      {:type=>:mega,:form=>form,:species=>species_key,:uid=>instance_uid})
    true
  end

  def mega_revert!
    return false unless mega?
    old = form_key
    @identity.set_form_key(:normal)
    @progression_history.push(
      {:type=>:mega_revert,:form=>old,:species=>species_key,:uid=>instance_uid})
    true
  end

  def pokemon_stats
    ensure_individual_data
    PMD_AC.pokemon_stats_from_bases(
      PMD_AC.form_base_stats(species_key,form_key),
      @level,@ivs,[PMD_AC::POKEMON_PLACEHOLDER_EV]*6,nature_multipliers)
  end

  def combat_stats
    ensure_individual_data
    PMD_AC.combat_stats_for_form(
      species_key,form_key,@level,@ivs,
      [PMD_AC::POKEMON_PLACEHOLDER_EV]*6,nature_multipliers)
  end

  def types
    PMD_AC.form_types(species_key,form_key)
  end

  def ability_key
    ensure_individual_data
    mega_ability = PMD_AC.form_ability(species_key,form_key)
    return mega_ability if mega_ability
    PMD_AC.resolve_ability(species_key,@ability_slot)
  end
end


class Game_PMDChessUnit
  def mega?
    @pokemon_instance && @pokemon_instance.mega?
  end

  def mega_available?
    @pokemon_instance && @pokemon_instance.mega_available?
  end

  def mega_forms
    @pokemon_instance ? @pokemon_instance.mega_forms : []
  end

  def apply_mega_form(form = nil)
    return false if dead? || summoned? || @pokemon_instance == nil
    return false unless @pokemon_instance.mega_evolve!(form)
    sync_from_pokemon_instance
    true
  end

  def revert_mega_form
    return false if @pokemon_instance == nil
    return false unless @pokemon_instance.mega_revert!
    sync_from_pokemon_instance
    true
  end

  def sync_from_pokemon_instance
    return false if @pokemon_instance == nil
    old_key = @key
    old_form = @runtime_form_key || :normal

    @identity = @pokemon_instance.identity
    @key = @pokemon_instance.species_key
    data = PMD_AC.unit_profile(@key)
    return false if data == nil
    @name = data[:name]
    @species = PMD_AC.form_visual_species(@pokemon_instance)

    stats = @pokemon_instance.combat_stats
    hp_rate = @maxhp.to_i <= 0 ? 1.0 : @hp.to_f / @maxhp.to_f
    @maxhp = stats[:hp]
    @atk = stats[:atk]
    @def = stats[:def]
    @spatk = stats[:spatk]
    @spdef = stats[:spdef]
    @speed_stat = stats[:speed]
    unless dead?
      @hp = [(@maxhp*hp_rate).round,1].max
      @hp = @maxhp if @hp > @maxhp
    end

    @runtime_form_key = @pokemon_instance.form_key

    if @scene
      @scene.log_event(:evolution,
        log_name+" UNIT_SYNC "+old_key.to_s+"->"+@key.to_s) if old_key != @key
      if old_form != @runtime_form_key
        @scene.log_event(:form,
          log_name+" "+old_form.to_s+"->"+@runtime_form_key.to_s+
          " ability="+ability_key.to_s+" visual="+@species.to_s)
      end
      if @runtime_form_key != :normal
        fd = PMD_AC.mega_form_data(@key,@runtime_form_key)
        candidates = fd ? (fd[:visual_candidates] || []) : []
        unless candidates.include?(@species)
          @scene.log_event(:mega,
            log_name+" VISUAL_FALLBACK form="+@runtime_form_key.to_s+
            " using="+@species.to_s)
        end
      end
      @scene.refresh_unit_sprite(self) if
        @scene.respond_to?(:refresh_unit_sprite)
    end
    true
  end

  def ability_incoming_multiplier(move_type, category)
    data = ability_data
    return 1.0 if data == nil || data.empty?
    return 0.0 if data[:hook] == :type_immunity && move_type == data[:type]
    if data[:hook] == :incoming_type_reduction
      return data[:mult].to_f if (data[:types] || []).include?(move_type)
    end
    1.0
  end
end


class Sprite_PMDChessUnit
  alias pmd_ac_v014_update update unless method_defined?(:pmd_ac_v014_update)
  def update
    key = @unit ? @unit.species : nil
    if @pmd_v014_last_species != key
      @pmd_v014_last_species = key
      refresh_action_bitmap(true) if @unit
    end
    pmd_ac_v014_update
  end
end


class Scene_PMD_AutoChess
  def reset_mega_usage
    @mega_used_by_team = {:ally=>0,:enemy=>0}
  end

  def mega_used_count(team)
    reset_mega_usage if @mega_used_by_team == nil
    (@mega_used_by_team[team] || 0).to_i
  end

  def refresh_unit_sprite(unit)
    return if @unit_sprites == nil
    for sprite in @unit_sprites
      if sprite.unit == unit
        sprite.refresh_action_bitmap(true)
        break
      end
    end
  end

  def request_mega(unit, form = nil)
    return mega_reject(nil,"unit=nil") if unit == nil
    return mega_reject(unit,"dead") if unit.dead?
    return mega_reject(unit,"summoned") if unit.summoned?
    return mega_reject(unit,"team_limit") if
      mega_used_count(unit.team) >= PMD_AC::MEGA_PER_TEAM
    return mega_reject(unit,"species_not_eligible") unless unit.mega_available?

    form ||= PMD_AC.default_mega_form(unit.species_key)
    return mega_reject(unit,"form_required") if form == nil

    uid = unit.instance_uid
    species = unit.species_key
    line = unit.evolution_line_key
    before = unit.pokemon_instance.combat_stats

    return mega_reject(unit,"invalid_form") unless unit.apply_mega_form(form)

    @mega_used_by_team[unit.team] = mega_used_count(unit.team) + 1
    after = unit.pokemon_instance.combat_stats
    add_vfx_impact_xy(unit.visual_center_x,unit.visual_center_y,:light)

    name = PMD_AC::MEGA_SE_NAME.to_s
    unless name.empty?
      begin
        Audio.se_play("Audio/SE/"+name,
          PMD_AC::MEGA_SE_VOLUME,PMD_AC::MEGA_SE_PITCH)
      rescue
      end
    end

    log_event(:mega,
      unit.log_name+" ACTIVATE form="+unit.form_key.to_s+
      " uid_same="+(unit.instance_uid==uid ? "1":"0")+
      " species_same="+(unit.species_key==species ? "1":"0")+
      " line_same="+(unit.evolution_line_key==line ? "1":"0")+
      " ability="+unit.ability_key.to_s+
      " A="+before[:atk].to_s+"->"+after[:atk].to_s+
      " D="+before[:def].to_s+"->"+after[:def].to_s+
      " SA="+before[:spatk].to_s+"->"+after[:spatk].to_s+
      " SD="+before[:spdef].to_s+"->"+after[:spdef].to_s+
      " visual="+unit.species.to_s+
      " team_used="+mega_used_count(unit.team).to_s)
    true
  end

  def mega_reject(unit, reason)
    label = unit ? unit.log_name : "NONE"
    log_event(:mega_reject,label+" reason="+reason.to_s)
    false
  end

  def revert_all_mega_forms
    return if @units == nil
    for unit in @units
      next unless unit.respond_to?(:mega?) && unit.mega?
      old = unit.form_key
      if unit.revert_mega_form
        log_event(:mega_revert,
          unit.log_name+" "+old.to_s+"->normal uid="+unit.instance_uid.to_s)
      end
    end
  end

  alias pmd_ac_v014_start_battle start_battle unless method_defined?(:pmd_ac_v014_start_battle)
  def start_battle
    reset_mega_usage
    pmd_ac_v014_start_battle
  end

  alias pmd_ac_v014_restart_to_deploy restart_to_deploy unless method_defined?(:pmd_ac_v014_restart_to_deploy)
  def restart_to_deploy
    revert_all_mega_forms
    reset_mega_usage
    pmd_ac_v014_restart_to_deploy
  end

  alias pmd_ac_v014_terminate terminate unless method_defined?(:pmd_ac_v014_terminate)
  def terminate
    revert_all_mega_forms
    pmd_ac_v014_terminate
  end

  alias pmd_ac_v014_prepare_verification_battle prepare_verification_battle unless method_defined?(:pmd_ac_v014_prepare_verification_battle)
  def prepare_verification_battle
    pmd_ac_v014_prepare_verification_battle
    if verification_mode == :mega
      reset_mega_usage
      for unit in @units
        unit.verification_energy_sandbox(true)
        unit.verification_combat_sandbox(true)
      end
    end
  end

  alias pmd_ac_v014_update_auras update_auras unless method_defined?(:pmd_ac_v014_update_auras)
  def update_auras
    return if verification_mode == :mega
    pmd_ac_v014_update_auras
  end

  def mega_test_instance(species, extra = nil)
    opts = {:ivs=>[15,15,15,15,15,15],
            :nature=>:hardy,:ability_slot=>:primary}
    if extra
      for k in extra.keys
        opts[k] = extra[k]
      end
    end
    PMD_PokemonInstance.new(species,50,opts)
  end

  def mega_test_unit(id,species,team,extra=nil)
    unit = Game_PMDChessUnit.new(
      id,species,team,0,0,mega_test_instance(species,extra))
    unit.scene = self
    unit
  end

  def verify_mega_registry(tag)
    return if @verification_done[tag]
    errors = PMD_AC.validate_mega_registry
    forms = PMD_AC::MEGA_FORM_DATA.values.inject(0){|s,h|s+h.size}
    log_event(:verify,tag.to_s.upcase+
      " pass="+(errors.empty? ? "1":"0")+
      " species="+PMD_AC::MEGA_FORM_DATA.size.to_s+
      " forms="+forms.to_s+" errors=["+errors.join(",")+"]")
    @verification_done[tag] = true
  end

  def verify_mega_identity(tag)
    return if @verification_done[tag]
    i = mega_test_instance(:venusaur,
      {:instance_uid=>990003,:runtime_actor_id=>501,:template_actor_id=>7})
    uid=i.instance_uid; sp=i.species_key; line=i.evolution_line_key
    actors=[i.runtime_actor_id,i.template_actor_id]
    ok=i.mega_evolve!(:mega)
    pass = ok && i.form_key==:mega && i.instance_uid==uid &&
      i.species_key==sp && i.evolution_line_key==line &&
      [i.runtime_actor_id,i.template_actor_id]==actors
    log_event(:verify,tag.to_s.upcase+
      " pass="+(pass ? "1":"0")+
      " uid_same="+(i.instance_uid==uid ? "1":"0")+
      " species_same="+(i.species_key==sp ? "1":"0")+
      " line_same="+(i.evolution_line_key==line ? "1":"0")+
      " form="+i.form_key.to_s+
      " actor_same="+([i.runtime_actor_id,i.template_actor_id]==actors ? "1":"0"))
    @verification_done[tag]=true
  end

  def verify_mega_stats(tag)
    return if @verification_done[tag]
    i=mega_test_instance(:venusaur)
    a=i.combat_stats
    i.mega_evolve!(:mega)
    b=i.combat_stats
    pass=b[:hp]==a[:hp] && b[:atk]>a[:atk] && b[:def]>a[:def] &&
         b[:spatk]>a[:spatk] && b[:spdef]>a[:spdef]
    log_event(:verify,tag.to_s.upcase+
      " pass="+(pass ? "1":"0")+
      " HP="+a[:hp].to_s+"->"+b[:hp].to_s+
      " A="+a[:atk].to_s+"->"+b[:atk].to_s+
      " D="+a[:def].to_s+"->"+b[:def].to_s+
      " SA="+a[:spatk].to_s+"->"+b[:spatk].to_s+
      " SD="+a[:spdef].to_s+"->"+b[:spdef].to_s)
    @verification_done[tag]=true
  end

  def verify_mega_charizard_forms(tag)
    return if @verification_done[tag]
    x=mega_test_instance(:charizard)
    y=mega_test_instance(:charizard)
    xok=x.mega_evolve!(:mega_x)
    yok=y.mega_evolve!(:mega_y)
    pass=xok && yok && x.species_key==:charizard && y.species_key==:charizard &&
      x.types==[:fire,:dragon] && y.types==[:fire,:flying] &&
      x.ability_key==:tough_claws && y.ability_key==:drought
    log_event(:verify,tag.to_s.upcase+
      " pass="+(pass ? "1":"0")+
      " X=["+x.types.collect{|v|v.to_s}.join(",")+"]/"+x.ability_key.to_s+
      " Y=["+y.types.collect{|v|v.to_s}.join(",")+"]/"+y.ability_key.to_s)
    @verification_done[tag]=true
  end

  def verify_mega_ability(tag)
    return if @verification_done[tag]
    normal=mega_test_unit(991,:venusaur,:ally)
    mega=mega_test_unit(992,:venusaur,:ally)
    mega.apply_mega_form(:mega)
    n=normal.ability_incoming_multiplier(:fire,:special)
    f=mega.ability_incoming_multiplier(:fire,:special)
    ice=mega.ability_incoming_multiplier(:ice,:special)
    water=mega.ability_incoming_multiplier(:water,:special)
    pass=normal.ability_key==:overgrow && mega.ability_key==:thick_fat &&
         n==1.0 && f==0.5 && ice==0.5 && water==1.0
    log_event(:verify,tag.to_s.upcase+
      " pass="+(pass ? "1":"0")+
      " ability="+normal.ability_key.to_s+"->"+mega.ability_key.to_s+
      " fire="+n.to_s+"->"+f.to_s+" ice="+ice.to_s+" water="+water.to_s)
    @verification_done[tag]=true
  end

  def verify_mega_team_limit(tag)
    return if @verification_done[tag]
    reset_mega_usage
    a=mega_test_unit(993,:venusaur,:ally)
    b=mega_test_unit(994,:blastoise,:ally)
    e=mega_test_unit(995,:charizard,:enemy)
    first=request_mega(a,:mega)
    second=request_mega(b,:mega)
    enemy=request_mega(e,:mega_x)
    pass=first && !second && enemy &&
         mega_used_count(:ally)==1 && mega_used_count(:enemy)==1
    log_event(:verify,tag.to_s.upcase+
      " pass="+(pass ? "1":"0")+
      " ally_first="+(first ? "1":"0")+
      " ally_second_rejected="+(!second ? "1":"0")+
      " enemy_allowed="+(enemy ? "1":"0")+
      " ally_used="+mega_used_count(:ally).to_s+
      " enemy_used="+mega_used_count(:enemy).to_s)
    a.revert_mega_form if a.mega?
    b.revert_mega_form if b.mega?
    e.revert_mega_form if e.mega?
    reset_mega_usage
    @verification_done[tag]=true
  end

  def verify_mega_revert(tag)
    return if @verification_done[tag]
    i=mega_test_instance(:blastoise,
      {:instance_uid=>990009,:ability_slot=>:primary})
    uid=i.instance_uid; sp=i.species_key; slot=i.ability_slot
    stats=i.combat_stats; normal_ability=i.ability_key
    on=i.mega_evolve!(:mega)
    mega_ability=i.ability_key
    off=i.mega_revert!
    pass=on && off && i.form_key==:normal && i.instance_uid==uid &&
      i.species_key==sp && i.ability_slot==slot &&
      i.ability_key==normal_ability && i.combat_stats==stats &&
      mega_ability==:mega_launcher
    log_event(:verify,tag.to_s.upcase+
      " pass="+(pass ? "1":"0")+
      " form="+i.form_key.to_s+
      " uid_same="+(i.instance_uid==uid ? "1":"0")+
      " species_same="+(i.species_key==sp ? "1":"0")+
      " slot_same="+(i.ability_slot==slot ? "1":"0")+
      " ability="+mega_ability.to_s+"->"+i.ability_key.to_s)
    @verification_done[tag]=true
  end

  def verify_mega_visual_fallback(tag)
    return if @verification_done[tag]
    i=mega_test_instance(:venusaur)
    i.mega_evolve!(:mega)
    resolved=PMD_AC.form_visual_species(i)
    candidates=PMD_AC.mega_form_data(:venusaur,:mega)[:visual_candidates]
    pass=resolved!=nil && resolved.to_s!=""
    log_event(:verify,tag.to_s.upcase+
      " pass="+(pass ? "1":"0")+
      " resolved="+resolved.to_s+
      " mega_compiled="+(candidates.include?(resolved) ? "1":"0"))
    @verification_done[tag]=true
  end

  def verify_mega_roster_revert(tag)
    return if @verification_done[tag]
    storage=PMD_AC.roster_storage
    storage.delete(98)
    i=PMD_PokemonInstance.new(:venusaur,50,
      {:instance_uid=>990098,:ivs=>[20,20,20,20,20,20],
       :nature=>:modest,:ability_slot=>:primary})
    storage[98]=i
    a=PMD_AC.ally_roster_instance(98,:venusaur,50)
    a.mega_evolve!(:mega)
    during=a.form_key; uid=a.instance_uid
    a.mega_revert!
    b=PMD_AC.ally_roster_instance(98,:venusaur,50)
    pass=during==:mega && b.form_key==:normal && b.instance_uid==uid &&
         b.species_key==:venusaur && b.nature_key==:modest
    log_event(:verify,tag.to_s.upcase+
      " pass="+(pass ? "1":"0")+
      " during="+during.to_s+" after="+b.form_key.to_s+
      " uid_same="+(b.instance_uid==uid ? "1":"0")+
      " species="+b.species_key.to_s+" nature="+b.nature_key.to_s)
    storage.delete(98)
    @verification_done[tag]=true
  end

  alias pmd_ac_v014_update_verification_script update_verification_script unless method_defined?(:pmd_ac_v014_update_verification_script)
  def update_verification_script
    if verification_mode != :mega
      pmd_ac_v014_update_verification_script
      return
    end
    @verification_frame += 1
    verify_mega_registry(:mega_registry) if @verification_frame >= 4
    verify_mega_identity(:mega_identity) if @verification_frame >= 34
    verify_mega_stats(:mega_stats) if @verification_frame >= 70
    verify_mega_charizard_forms(:mega_charizard_forms) if @verification_frame >= 106
    verify_mega_ability(:mega_ability) if @verification_frame >= 144
    verify_mega_team_limit(:mega_team_limit) if @verification_frame >= 184
    verify_mega_revert(:mega_revert) if @verification_frame >= 224
    verify_mega_visual_fallback(:mega_visual_fallback) if @verification_frame >= 258
    verify_mega_roster_revert(:mega_roster_revert) if @verification_frame >= 288
    complete_verification_mode if
      @verification_frame >= PMD_AC::VERIFICATION_MEGA_END_FRAME
  end
end


#==============================================================================
# ■ PMD AutoChess v0.15 Extension
#    Synergy System
#==============================================================================
module PMD_AC
  remove_const(:VERIFICATION_MODES) if const_defined?(:VERIFICATION_MODES)
  VERIFICATION_MODES = [:normal, :control, :beam, :zone, :hit, :energy,
                        :direction, :object, :summon, :identity,
                        :progression, :individual, :mega, :synergy]

  remove_const(:VERIFICATION_LABELS) if const_defined?(:VERIFICATION_LABELS)
  VERIFICATION_LABELS = {
    :normal=>"NORMAL", :control=>"CONTROL", :beam=>"BEAM", :zone=>"ZONE",
    :hit=>"HIT", :energy=>"ENERGY", :direction=>"DIRECTION",
    :object=>"OBJECT", :summon=>"SUMMON", :identity=>"IDENTITY",
    :progression=>"PROGRESSION", :individual=>"INDIVIDUAL",
    :mega=>"MEGA", :synergy=>"SYNERGY"
  }

  VERIFICATION_SYNERGY_END_FRAME = 340

  #--------------------------------------------------------------------------
  # ● v0.15 Synergy Registry
  #--------------------------------------------------------------------------
  # Condition vocabulary:
  #
  # :required_species => [:pikachu, :raichu]
  # :required_lines   => [:bulbasaur_line, ...]
  # :required_tags    => {:water=>2, :starter=>3}
  # :required_roles   => {:ranged=>2, :controller=>1}
  # :required_forms   => [
  #   {:species=>:venusaur, :form=>:mega, :count=>1}
  # ]
  #
  # Summoned Units do NOT count by default.
  #
  # Exact species / line requirements use unique identity keys:
  # three Bulbasaur cannot fake Bulbasaur+Charmander+Squirtle.
  #
  SYNERGY_DATA = {
    :kanto_starter_trio=>{
      :name=>"初代御三家",
      :description=>"三條初代御三家進化線同隊時，戰鬥開始獲得少量初始能量。",
      :condition=>{
        :required_lines=>[
          :bulbasaur_line,
          :charmander_line,
          :squirtle_line
        ]
      },
      :effects=>[
        {:type=>:gain_energy, :amount=>12, :scope=>:team, :once=>true}
      ]
    }
  }

  class << self
    def synergy_data(key)
      SYNERGY_DATA[key]
    end

    def synergy_eligible_units(units)
      result = []
      for unit in (units || [])
        next if unit == nil
        next if unit.respond_to?(:summoned?) && unit.summoned?
        result.push(unit)
      end
      result
    end

    def synergy_species_set(units)
      synergy_eligible_units(units).collect { |u| u.species_key }.uniq
    end

    def synergy_line_set(units)
      synergy_eligible_units(units).collect {
        |u| u.evolution_line_key
      }.uniq
    end

    def synergy_tag_count(units, tag)
      count = 0
      for unit in synergy_eligible_units(units)
        count += 1 if unit.synergy_tags.include?(tag)
      end
      count
    end

    def synergy_role_count(units, role)
      count = 0
      for unit in synergy_eligible_units(units)
        count += 1 if unit.role_tags.include?(role)
      end
      count
    end

    def synergy_form_match?(unit, requirement)
      return false if unit == nil
      return false if requirement[:species] != nil &&
                      unit.species_key != requirement[:species]
      return false if requirement[:line] != nil &&
                      unit.evolution_line_key != requirement[:line]
      return false if requirement[:form] != nil &&
                      unit.form_key != requirement[:form]
      return true
    end

    def synergy_condition_met?(units, condition)
      units = synergy_eligible_units(units)
      condition = {} if condition == nil

      required_species = condition[:required_species] || []
      species_set = synergy_species_set(units)
      for key in required_species
        return false unless species_set.include?(key)
      end

      required_lines = condition[:required_lines] || []
      line_set = synergy_line_set(units)
      for key in required_lines
        return false unless line_set.include?(key)
      end

      required_tags = condition[:required_tags] || {}
      for tag in required_tags.keys
        return false if synergy_tag_count(units,tag) <
                        required_tags[tag].to_i
      end

      required_roles = condition[:required_roles] || {}
      for role in required_roles.keys
        return false if synergy_role_count(units,role) <
                        required_roles[role].to_i
      end

      required_forms = condition[:required_forms] || []
      for requirement in required_forms
        needed = (requirement[:count] || 1).to_i
        matched = 0
        for unit in units
          matched += 1 if synergy_form_match?(unit,requirement)
        end
        return false if matched < needed
      end

      if condition[:min_unique_species] != nil
        return false if species_set.size <
                        condition[:min_unique_species].to_i
      end

      return true
    end

    def active_synergy_keys_for(units)
      result = []
      for key in SYNERGY_DATA.keys
        data = SYNERGY_DATA[key]
        if synergy_condition_met?(units,data[:condition])
          result.push(key)
        end
      end
      result
    end

    def active_synergy_names_for(units)
      active_synergy_keys_for(units).collect {
        |key| (SYNERGY_DATA[key][:name] || key.to_s)
      }
    end

    def validate_synergy_registry
      errors = []
      for key in SYNERGY_DATA.keys
        data = SYNERGY_DATA[key]
        if data[:condition] == nil
          errors.push("condition:"+key.to_s)
        end
        if data[:effects] == nil
          errors.push("effects:"+key.to_s)
        else
          for effect in data[:effects]
            unless [:gain_energy].include?(effect[:type])
              errors.push("effect_type:"+key.to_s+":"+effect[:type].to_s)
            end
          end
        end
      end
      errors
    end
  end
end


#==============================================================================
# ■ Scene_PMD_AutoChess v0.15
#==============================================================================
class Scene_PMD_AutoChess
  def reset_synergy_state
    @active_synergies_by_team = {:ally=>[], :enemy=>[]}
    @synergy_effect_applied = {:ally=>{}, :enemy=>{}}
  end

  def synergy_team_units(team)
    result = []
    for unit in (@units || [])
      next unless unit.team == team
      next if unit.summoned?
      next unless unit.counts_for_victory?
      result.push(unit)
    end
    result
  end

  def active_synergy_keys(team)
    reset_synergy_state if @active_synergies_by_team == nil
    return (@active_synergies_by_team[team] || []).dup
  end

  def active_synergy_names(team)
    active_synergy_keys(team).collect {
      |key| PMD_AC::SYNERGY_DATA[key][:name] || key.to_s
    }
  end

  def synergy_effect_targets(team, effect)
    units = synergy_team_units(team)
    scope = effect[:scope] || :team

    if scope == :team
      return units
    end

    if scope.is_a?(Hash)
      if scope[:tag] != nil
        return units.select {
          |u| u.synergy_tags.include?(scope[:tag])
        }
      end
      if scope[:role] != nil
        return units.select {
          |u| u.role_tags.include?(scope[:role])
        }
      end
      if scope[:line] != nil
        return units.select {
          |u| u.evolution_line_key == scope[:line]
        }
      end
      if scope[:species] != nil
        return units.select {
          |u| u.species_key == scope[:species]
        }
      end
    end

    return units
  end

  def apply_synergy_effects(team, key)
    reset_synergy_state if @synergy_effect_applied == nil
    data = PMD_AC::SYNERGY_DATA[key]
    return if data == nil

    @synergy_effect_applied[team] = {} if
      @synergy_effect_applied[team] == nil

    for index in 0...(data[:effects] || []).size
      effect = data[:effects][index]
      effect_id = key.to_s + ":" + index.to_s

      if effect[:once] &&
         @synergy_effect_applied[team][effect_id]
        next
      end

      case effect[:type]
      when :gain_energy
        amount = (effect[:amount] || 0).to_i
        for unit in synergy_effect_targets(team,effect)
          actual = unit.gain_energy(amount,nil,:synergy)
          log_event(
            :synergy_effect,
            team.to_s.upcase+" "+key.to_s+
            " ENERGY "+unit.log_name+
            " +"+actual.to_s+
            " now="+unit.energy.to_s+"/"+PMD_AC::MAX_ENERGY.to_s)
        end
      end

      @synergy_effect_applied[team][effect_id] = true if effect[:once]
    end
  end

  def refresh_team_synergies(team, reason = :refresh, apply_effects = true)
    reset_synergy_state if @active_synergies_by_team == nil

    units = synergy_team_units(team)
    old_keys = @active_synergies_by_team[team] || []
    new_keys = PMD_AC.active_synergy_keys_for(units)

    activated = new_keys - old_keys
    deactivated = old_keys - new_keys

    for key in activated
      data = PMD_AC::SYNERGY_DATA[key]
      log_event(
        :synergy,
        team.to_s.upcase+" ACTIVATE "+key.to_s+
        " name="+(data[:name] || key.to_s)+
        " reason="+reason.to_s+
        " units=["+
        units.collect{|u|u.species_key.to_s+"#"+u.instance_uid.to_s}.join(",")+
        "]")
      apply_synergy_effects(team,key) if apply_effects
    end

    for key in deactivated
      data = PMD_AC::SYNERGY_DATA[key]
      log_event(
        :synergy,
        team.to_s.upcase+" DEACTIVATE "+key.to_s+
        " name="+(data[:name] || key.to_s)+
        " reason="+reason.to_s)
    end

    @active_synergies_by_team[team] = new_keys
    return new_keys
  end

  def refresh_all_synergies(reason = :refresh, apply_effects = true)
    refresh_team_synergies(:ally,reason,apply_effects)
    refresh_team_synergies(:enemy,reason,apply_effects)
  end

  alias pmd_ac_v015_start_battle start_battle unless method_defined?(:pmd_ac_v015_start_battle)
  def start_battle
    reset_synergy_state
    pmd_ac_v015_start_battle

    # Old deterministic verification modes must remain isolated.
    if @phase == :battle &&
       [:normal,:synergy].include?(verification_mode)
      refresh_all_synergies(:battle_start,true)
      refresh_footer
    end
  end

  alias pmd_ac_v015_request_mega request_mega unless method_defined?(:pmd_ac_v015_request_mega)
  def request_mega(unit, form = nil)
    result = pmd_ac_v015_request_mega(unit,form)
    if result && unit != nil
      refresh_team_synergies(unit.team,:mega_form,true)
      refresh_footer
    end
    result
  end

  alias pmd_ac_v015_revert_all_mega_forms revert_all_mega_forms unless method_defined?(:pmd_ac_v015_revert_all_mega_forms)
  def revert_all_mega_forms
    pmd_ac_v015_revert_all_mega_forms
    if @active_synergies_by_team != nil
      refresh_all_synergies(:mega_revert,false)
    end
  end

  alias pmd_ac_v015_prepare_verification_battle prepare_verification_battle unless method_defined?(:pmd_ac_v015_prepare_verification_battle)
  def prepare_verification_battle
    pmd_ac_v015_prepare_verification_battle
    if verification_mode == :synergy
      for unit in @units
        unit.verification_energy_sandbox(true)
        unit.verification_combat_sandbox(true)
      end
    end
  end

  alias pmd_ac_v015_update_auras update_auras unless method_defined?(:pmd_ac_v015_update_auras)
  def update_auras
    return if verification_mode == :synergy
    pmd_ac_v015_update_auras
  end

  #--------------------------------------------------------------------------
  # ● Synthetic helpers
  #--------------------------------------------------------------------------
  def synergy_test_instance(species, extra = nil)
    opts = {
      :ivs=>[15,15,15,15,15,15],
      :nature=>:hardy,
      :ability_slot=>:primary
    }
    if extra != nil
      for key in extra.keys
        opts[key] = extra[key]
      end
    end
    PMD_PokemonInstance.new(species,50,opts)
  end

  def synergy_test_unit(id, species, team = :ally, extra = nil)
    unit = Game_PMDChessUnit.new(
      id,species,team,0,0,synergy_test_instance(species,extra))
    unit.scene = self
    unit
  end

  #--------------------------------------------------------------------------
  # ● SYNERGY Verification
  #--------------------------------------------------------------------------
  def verify_synergy_registry(tag)
    return if @verification_done[tag]
    errors = PMD_AC.validate_synergy_registry
    pass = errors.empty?
    log_event(
      :verify,
      tag.to_s.upcase+
      " pass="+(pass ? "1":"0")+
      " entries="+PMD_AC::SYNERGY_DATA.size.to_s+
      " errors=["+errors.join(",")+"]")
    @verification_done[tag] = true
  end

  def verify_synergy_kanto_base(tag)
    return if @verification_done[tag]
    units = [
      synergy_test_unit(1501,:bulbasaur),
      synergy_test_unit(1502,:charmander),
      synergy_test_unit(1503,:squirtle)
    ]
    keys = PMD_AC.active_synergy_keys_for(units)
    pass = keys.include?(:kanto_starter_trio)
    log_event(
      :verify,
      tag.to_s.upcase+
      " pass="+(pass ? "1":"0")+
      " active=["+keys.collect{|x|x.to_s}.join(",")+"]")
    @verification_done[tag] = true
  end

  def verify_synergy_evolution_line(tag)
    return if @verification_done[tag]
    units = [
      synergy_test_unit(1511,:venusaur),
      synergy_test_unit(1512,:charmeleon),
      synergy_test_unit(1513,:blastoise)
    ]
    keys = PMD_AC.active_synergy_keys_for(units)
    pass = keys.include?(:kanto_starter_trio)
    lines = units.collect{|u|u.evolution_line_key}
    log_event(
      :verify,
      tag.to_s.upcase+
      " pass="+(pass ? "1":"0")+
      " lines=["+lines.collect{|x|x.to_s}.join(",")+"]")
    @verification_done[tag] = true
  end

  def verify_synergy_duplicate_line(tag)
    return if @verification_done[tag]
    units = [
      synergy_test_unit(1521,:bulbasaur),
      synergy_test_unit(1522,:bulbasaur),
      synergy_test_unit(1523,:bulbasaur)
    ]
    active = PMD_AC.active_synergy_keys_for(units)
    pass = !active.include?(:kanto_starter_trio)
    log_event(
      :verify,
      tag.to_s.upcase+
      " pass="+(pass ? "1":"0")+
      " unique_lines="+PMD_AC.synergy_line_set(units).size.to_s+
      " active=["+active.collect{|x|x.to_s}.join(",")+"]")
    @verification_done[tag] = true
  end

  def verify_synergy_species_rule(tag)
    return if @verification_done[tag]
    condition = {:required_species=>[:pikachu,:raichu]}

    good = [
      synergy_test_unit(1531,:pikachu),
      synergy_test_unit(1532,:raichu)
    ]
    bad = [
      synergy_test_unit(1533,:pikachu),
      synergy_test_unit(1534,:pikachu)
    ]

    good_ok = PMD_AC.synergy_condition_met?(good,condition)
    bad_ok = PMD_AC.synergy_condition_met?(bad,condition)
    pass = good_ok && !bad_ok

    log_event(
      :verify,
      tag.to_s.upcase+
      " pass="+(pass ? "1":"0")+
      " exact_pair="+(good_ok ? "1":"0")+
      " duplicate_rejected="+(!bad_ok ? "1":"0"))
    @verification_done[tag] = true
  end

  def verify_synergy_tag_role_rule(tag)
    return if @verification_done[tag]

    tag_condition = {
      :required_tags=>{:grass=>1,:fire=>1,:water=>1}
    }
    tag_units = [
      synergy_test_unit(1541,:ivysaur),
      synergy_test_unit(1542,:charizard),
      synergy_test_unit(1543,:wartortle)
    ]

    role_condition = {
      :required_roles=>{:ranged=>2,:controller=>1}
    }
    role_units = [
      synergy_test_unit(1544,:squirtle),
      synergy_test_unit(1545,:caterpie)
    ]

    tags_ok = PMD_AC.synergy_condition_met?(tag_units,tag_condition)
    roles_ok = PMD_AC.synergy_condition_met?(role_units,role_condition)
    pass = tags_ok && roles_ok

    log_event(
      :verify,
      tag.to_s.upcase+
      " pass="+(pass ? "1":"0")+
      " tags="+(tags_ok ? "1":"0")+
      " roles="+(roles_ok ? "1":"0")+
      " ranged="+PMD_AC.synergy_role_count(role_units,:ranged).to_s+
      " controller="+
      PMD_AC.synergy_role_count(role_units,:controller).to_s)
    @verification_done[tag] = true
  end

  def verify_synergy_form_rule(tag)
    return if @verification_done[tag]

    condition = {
      :required_forms=>[
        {:species=>:venusaur,:form=>:mega,:count=>1}
      ]
    }

    unit = synergy_test_unit(1551,:venusaur)
    normal = PMD_AC.synergy_condition_met?([unit],condition)
    unit.pokemon_instance.mega_evolve!(:mega)
    unit.sync_from_pokemon_instance
    mega = PMD_AC.synergy_condition_met?([unit],condition)
    unit.revert_mega_form
    reverted = PMD_AC.synergy_condition_met?([unit],condition)

    pass = !normal && mega && !reverted

    log_event(
      :verify,
      tag.to_s.upcase+
      " pass="+(pass ? "1":"0")+
      " normal="+(normal ? "1":"0")+
      " mega="+(mega ? "1":"0")+
      " reverted="+(reverted ? "1":"0"))
    @verification_done[tag] = true
  end

  def verify_synergy_actor_independence(tag)
    return if @verification_done[tag]

    units = [
      synergy_test_unit(
        1561,:bulbasaur,:ally,
        {:runtime_actor_id=>501,:template_actor_id=>7}),
      synergy_test_unit(
        1562,:charmeleon,:ally,
        {:runtime_actor_id=>777,:template_actor_id=>18}),
      synergy_test_unit(
        1563,:blastoise,:ally,
        {:runtime_actor_id=>999,:template_actor_id=>42})
    ]

    active = PMD_AC.active_synergy_keys_for(units)
    pass = active.include?(:kanto_starter_trio)

    actors = units.collect{
      |u| u.runtime_actor_id.to_s+"/"+u.template_actor_id.to_s
    }

    log_event(
      :verify,
      tag.to_s.upcase+
      " pass="+(pass ? "1":"0")+
      " actors=["+actors.join(",")+"]"+
      " active=["+active.collect{|x|x.to_s}.join(",")+"]")
    @verification_done[tag] = true
  end

  def verify_synergy_summon_excluded(tag)
    return if @verification_done[tag]

    bulba = synergy_test_unit(1571,:bulbasaur)
    char = synergy_test_unit(1572,:charmander)
    turtle = synergy_test_unit(1573,:squirtle)

    turtle.configure_as_summon(
      bulba,
      {:duration=>120,:stat_scale=>1.0,:hp_scale=>1.0})

    active = PMD_AC.active_synergy_keys_for([bulba,char,turtle])
    pass = !active.include?(:kanto_starter_trio)

    log_event(
      :verify,
      tag.to_s.upcase+
      " pass="+(pass ? "1":"0")+
      " eligible="+
      PMD_AC.synergy_eligible_units([bulba,char,turtle]).size.to_s+
      " summon_excluded="+(turtle.summoned? ? "1":"0"))
    @verification_done[tag] = true
  end

  def verify_synergy_battle_effect(tag)
    return if @verification_done[tag]

    allies = synergy_team_units(:ally)
    active = active_synergy_keys(:ally)

    energy_ok = true
    values = []
    for unit in allies
      values.push(unit.species_key.to_s+"="+unit.energy.to_s)
      energy_ok = false unless unit.energy == 12
    end

    pass = active.include?(:kanto_starter_trio) && energy_ok

    log_event(
      :verify,
      tag.to_s.upcase+
      " pass="+(pass ? "1":"0")+
      " active=["+active.collect{|x|x.to_s}.join(",")+"]"+
      " energy=["+values.join(",")+"]")
    @verification_done[tag] = true
  end

  def verify_synergy_once_effect(tag)
    return if @verification_done[tag]

    before = synergy_team_units(:ally).collect{|u|u.energy}
    refresh_team_synergies(:ally,:verify_refresh,true)
    after = synergy_team_units(:ally).collect{|u|u.energy}

    pass = before == after

    log_event(
      :verify,
      tag.to_s.upcase+
      " pass="+(pass ? "1":"0")+
      " before=["+before.join(",")+"]"+
      " after=["+after.join(",")+"]")
    @verification_done[tag] = true
  end

  alias pmd_ac_v015_update_verification_script update_verification_script unless method_defined?(:pmd_ac_v015_update_verification_script)
  def update_verification_script
    if verification_mode != :synergy
      pmd_ac_v015_update_verification_script
      return
    end

    @verification_frame += 1

    verify_synergy_registry(:synergy_registry) if
      @verification_frame >= 4

    verify_synergy_kanto_base(:synergy_kanto_base) if
      @verification_frame >= 34

    verify_synergy_evolution_line(:synergy_evolution_line) if
      @verification_frame >= 68

    verify_synergy_duplicate_line(:synergy_duplicate_line) if
      @verification_frame >= 102

    verify_synergy_species_rule(:synergy_species_rule) if
      @verification_frame >= 136

    verify_synergy_tag_role_rule(:synergy_tag_role_rule) if
      @verification_frame >= 172

    verify_synergy_form_rule(:synergy_form_rule) if
      @verification_frame >= 208

    verify_synergy_actor_independence(:synergy_actor_independence) if
      @verification_frame >= 242

    verify_synergy_summon_excluded(:synergy_summon_excluded) if
      @verification_frame >= 274

    verify_synergy_battle_effect(:synergy_battle_effect) if
      @verification_frame >= 302

    verify_synergy_once_effect(:synergy_once_effect) if
      @verification_frame >= 320

    complete_verification_mode if
      @verification_frame >= PMD_AC::VERIFICATION_SYNERGY_END_FRAME
  end
end
