#==============================================================================
# PMD AutoChess 中文設定總索引 v0.86
#==============================================================================
# 這支腳本沒有執行程式碼，只是放在 Script Editor 裡當「中文設定目錄」。
# 從 v0.83 起，所有 PMD AutoChess 相關腳本開頭都必須附中文用途、設定、機制與範例；
# 往後新增腳本也沿用這個規格。
#
# 【最常修改的區域】
# 1. 寶可夢／種族／技能資料
#    - PMD AutoChess Species Data v0.16.1
#    - PMD AutoChess Move Data v0.17
#    - 各 Move Runtime Coverage Data v0.49～v0.59
#
# 2. 戰鬥定位／AI
#    - PMD AutoChess Combat AI Data v0.68～v0.72
#    - PMD AutoChess Balance Data v0.75
#
# 3. 畫面／動畫／音效
#    - PMD AutoChess Presentation User Config v0.55
#    - v0.55.1～v0.57.6 各 Presentation Tuning
#    - PMD AutoChess Organic Combat SFX Palette v0.56.1
#    - PMD AutoChess PMDCollab Native Pose Config v0.60
#
# 4. 天氣／場地／高度
#    - Weather Data v0.28
#    - Field Effect / Spatial / AI Data v0.35～v0.37
#    - Altitude Data v0.38
#
# 5. 成長／技能／進化
#    - Identity Growth Data v0.45
#    - RPG Progression Data v0.46
#    - RPG Progression UI Data v0.47
#    - Progression Flow Data v0.77
#
# 6. 隊伍／BOX
#    - Party Storage Data v0.78
#
# 7. 關卡／野外／Boss／事件戰
#    - Stage Data v0.80：關卡編成、解鎖、關卡招募池
#    - RPG Encounter Data v0.81：Wild／Boss／Scripted Battle 定義與事件入口
#    - RPG Field Data v0.82：HP 延續、治療、檢查點、戰敗政策、臨時戰鬥
#
# 8. RPG 戰利品
#    - Reward / Loot Data v0.83：Gold／Item／Weapon／Armor／Variable／Switch／Common Event
#
# 9. 敵方等級縮放／精英怪／區域難度（v0.84 新增）
#    - PMD AutoChess Encounter Config Data v0.84
#      最常改的三張表：
#        ENEMY_SCALING_PROFILES_V084  敵人等級縮放
#        ELITE_PROFILES_V084          精英倍率
#        ENCOUNTER_PROFILES_V084      區域整合設定
#    - PMD AutoChess Proto v0.84
#      Runtime 執行層；一般調數值時不要直接改這支。
#
# 【v0.84 常用事件指令】
# 區域設定直接開戰：
#   PMD_AC.start_profile_battle_v084(:forest_adaptive)
#
# 地圖開啟動態野怪：
#   PMD_AC.wild_profile_on_v084(:forest_adaptive,10,18,[1])
#
# 關閉野怪：
#   PMD_AC.wild_off_v081
#
# 舊事件戰臨時套縮放：
#   PMD_AC.start_battle_v081(:roadside_pikachu,{
#     :encounter_profile=>:roadside_adaptive
#   })
#
# 10. 戰鬥背景／BGM（v0.85 新增）
#    - PMD AutoChess Battle Presentation Data v0.85
#      最常改的兩張表：
#        BATTLE_PRESENTATION_PROFILES_V085  背景／BGM Profile
#        MAP_BATTLE_PRESENTATION_V085       Map ID 的預設戰鬥演出
#    - Stage／Boss／Encounter 可直接加 :presentation=>:profile_name
#    - 單場事件戰可在 options 直接寫 :battleback / :bgm / :bgm_volume / :bgm_pitch
#
# 【v0.85 常用事件指令】
# 指定某場使用 Boss 演出：
#   PMD_AC.start_battle_v081(:roadside_pikachu,{:presentation=>:boss_demo})
#
# 單場直接指定圖片與 BGM：
#   PMD_AC.start_battle_v081(:roadside_pikachu,{
#     :battleback=>'bg_002.jpg', :bgm=>'Battle',
#     :bgm_volume=>90, :bgm_pitch=>100
#   })
#
# 11. 區域生態／稀有 Encounter／精英額外獎勵（v0.86 新增）
#    - PMD AutoChess Region Ecology Data v0.86
#      最常改的兩張表：
#        ENCOUNTER_FORMATIONS_V086     一場完整敵方編成
#        REGION_ECOLOGY_PROFILES_V086  地區權重／難度／稀有與精英獎勵
#      Map ID 預設可用 MAP_REGION_DEFAULTS_V086。
#
# 【v0.86 常用事件指令】
# 區域生態直接開戰：
#   PMD_AC.start_region_battle_v086(:forest_edge)
#
# 強制某一稀有編成：
#   PMD_AC.start_region_battle_v086(:forest_edge,{:formation=>:forest_pikachu_rare})
#
# 地圖開啟區域生態野怪：
#   PMD_AC.wild_region_on_v086(:forest_edge,10,18,[1,2])
#
# 12. UI 字體／可讀性（v0.86 統一整理）
#    - PMD AutoChess UI Readability v0.86
#      字級集中在腳本最上方的 UI_*_FONT_V086 常數。
#      可調 Header、Footer、戰場浮字、BOX、成長面板、結果／Loot。
#      此腳本只改 UI，不改戰鬥機制。
#
# 【修改原則】
# - 優先修改名稱含 Data / Config / Tuning / Policy 的腳本。
# - 名稱為 Proto 的腳本多半是 Runtime 執行層，除非要擴充機制，否則少直接改。
# - 要追加行為，建議新增一支更後面的腳本用 alias 包裝，而不是回頭改十幾層舊 alias。
# - instance_uid 是寶可夢真正身份，不要用 Actor ID 當個體身份。
# - 新增 RGSS2 程式請維持 Ruby 1.8 相容，避免使用 instance_variable_defined?。
# - Game.ini 永遠不得有 UTF-8 BOM。
#==============================================================================
