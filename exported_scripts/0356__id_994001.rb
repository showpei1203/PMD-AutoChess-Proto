# encoding: UTF-8
#==============================================================================
# 【PMD AutoChess 中文維護說明】
# 腳本：PMD AutoChess Species Production Audit Data v0.99.4
# 分類：#0001～#0494 寶可夢逐隻畢業審查／RPG Production Audit
#
# 【用途】
# 1. 對 494 隻 Pokémon 的身份、屬性、六維種族值、成長組、進化、技能池、
#    Ability Slot、Form、AI/Tactical Profile 做逐隻一致性審查。
# 2. 明確區分「Core Error」與「Design Warning」：資料壞掉才算 Error；
#    極端種族值、特殊機制、技能池偏窄等只列為後續 RPG 平衡審查項目。
# 3. 產生完整文字報告 PMD_SpeciesProductionAudit_v0.99.4.txt，未來每次改 Species
#    Data 都可以重跑，不必靠人工記憶檢查 494 隻。
#
# 【主要檢查】
# Core：
# - species=494 / dex=1..494 唯一 / evolution_lines=248 / forms=702
# - base_stats 6/6 且 BST 加總一致
# - types 1～2 / growth_group 合法
# - 7005 Learnset 引用全部存在 MoveDB 且可執行
# - 每隻 Lv1 至少具有 1 個 executable move，避免新取得個體完全不能戰鬥
# - Ability slots 使用最終 ability_slots()，每個非空槽都必須能由 ability_data() 找到 Runtime
# - 進化目標與 Evolution Line 成員合法
# - Tactical Profile 必要欄位完整
# - 每隻至少有 normal Form，所有 Form 的 stats/types 結構合法
#
# Design Warning：
# - lifetime level-up executable movepool < 4
# - 極端低／高 BST、特殊 Runtime Pokémon
# - Species Tactical Profile 目前 494/494 都由 v0.16 percentile generator 產生，
#   僅少數舊測試種有 explicit AI override；這不是 Error，但代表正式 RPG 仍需實戰平衡。
# - 現行 7005 Learnset 全部是 level_up；TM／Tutor／Egg Move 尚未形成 RPG Acquisition Pool。
#
# 【可調參數】
# SPECIES_AUDIT_LEVEL_CHECKPOINTS_V0994：檢查招式可用數的等級節點。
# SPECIES_AUDIT_SPARSE_MOVE_LIMIT_V0994：低於此數量列技能池偏窄 Warning。
# SPECIES_AUDIT_BST_LOW/HIGH_V0994：只做平衡提示，不修改種族值。
# SPECIES_SPECIAL_REVIEW_V0994：特殊機制逐隻人工提醒清單。
#
# 【事件／腳本呼叫方式】
# report = PMD_AC.species_production_audit_v0994
# PMD_AC.write_species_production_audit_v0994(report)
# row = PMD_AC.species_production_row_v0994(:bulbasaur)
#
# 【實際範例】
# Metapod 的 level-up movepool 只有 Harden：
# - Core PASS（招式引用與 Runtime 都合法）
# - Design Warning：sparse_levelup_movepool
# 這樣不會為了報表全綠就偷偷替鐵甲蛹發明四招，也不會漏掉實際 RPG 可玩性問題。
#
# 【維護注意】
# - RPG Maker VX / RGSS2 / Ruby 1.8 相容。
# - 本版只讀資料，不修改 Stats、Learnset、Ability、AI、Form 或戰鬥規則。
# - v0.99.3 Team Bond 81/81 與所有 Freeze 系統保持不變。
#==============================================================================
module PMD_AC
  SPECIES_PRODUCTION_AUDIT_VERSION_V0994='0.99.4'
  SPECIES_PRODUCTION_AUDIT_REPORT_FILE_V0994='PMD_SpeciesProductionAudit_v0.99.4.txt'
  SPECIES_AUDIT_LEVEL_CHECKPOINTS_V0994=[1,5,10,20,30,50,100]
  SPECIES_AUDIT_SPARSE_MOVE_LIMIT_V0994=4
  SPECIES_AUDIT_BST_LOW_V0994=250
  SPECIES_AUDIT_BST_HIGH_V0994=670
  SPECIES_AUDIT_GROWTH_GROUPS_V0994=[:slow,:medium_slow,:medium_fast,:fast,:erratic,:fluctuating]
  SPECIES_AUDIT_PROFILE_FIELDS_V0994=[
    :role_primary,:role_tags,:target_policy,:movement_policy,:threat_policy,
    :skill_policy,:target_commitment,:range,:preferred_range,:collision_radius,
    :melee_reach,:move_speed,:attack_wait,:profile_generation
  ]

  # 特殊個體不是 Error，而是正式 RPG 平衡測試時必須人工確認的高風險樣本。
  SPECIES_SPECIAL_REVIEW_V0994={
    :ditto=>'Transform/Imposter 依賴型；自身固定技能池極窄。',
    :smeargle=>'Sketch 依賴型；正式 RPG 是否允許永久複製招式需另定取得規則。',
    :unown=>'Hidden Power 單招型；需確認 AutoChess 中角色定位仍有存在感。',
    :wobbuffet=>'Counter/Mirror Coat 反應型；AI 必須能正確等待與反制。',
    :wynaut=>'Wobbuffet 前置反應型；低等級戰鬥節奏需特別測。',
    :shedinja=>'HP=1 原作特例在本專案 HP×10 公式下需獨立平衡確認，並依賴 Wonder Guard。',
    :slaking=>'極高 BST + Truant；AutoChess 即時制節奏需特別測。',
    :regigigas=>'極高 BST + Slow Start；長戰與短戰差異需特別測。',
    :castform=>'Forecast/天氣 Form 依賴型；Map Weather 與 Battle Weather 都要驗證。',
    :deoxys=>'多 Form 極端種族值；不同 Form 的 AI Role 不應只沿用同一泛用 Profile。',
    :rotom=>'多 Form／屬性變化型；正式取得 Form 時需要 RPG 事件規則。',
    :giratina=>'Origin/Altered Form；Form 取得條件與 Held Item 規則需 RPG 化。',
    :shaymin=>'Land/Sky Form；Form 切換條件需 RPG 化。',
    :arceus=>'Multitype 特例；本專案不做原作 Plate 全套時需鎖定正式 RPG 規則。',
    :eevee=>'多分支進化；v0.77 已支援玩家選擇，但 RPG 取得條件需最終內容化。',
    :wurmple=>'分支進化；目前採專案分支規則，正式劇情/生態需確認。',
    :nincada=>'進化額外生成 Shedinja；Party/BOX 容量與取得提示需 RPG 測試。'
  }
end
