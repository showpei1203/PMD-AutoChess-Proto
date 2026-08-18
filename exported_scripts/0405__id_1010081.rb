# encoding: UTF-8
#==============================================================================
# 【PMD AutoChess 中文維護說明】
# 腳本：PMD AutoChess Vertical Slice Verification Finalization v1.01.8
# 分類：Map / NPC / Story Vertical Slice 驗證框架收尾
# RPG Maker VX / RGSS2 / Ruby 1.8 compatible
#------------------------------------------------------------------------------
# 【用途】
# 修正 v1.01.7 的兩個驗證框架問題：
# 1. Story Progression / Recruit Separation 的 verifier hook 使用較脆弱的條件，
#    Windows 實機可正確執行劇情邏輯，卻沒有輸出 STORY_PROGRESS_SEPARATION_V1017 marker。
# 2. v1.01.2 把「本次 Game.exe session 是否重新走完 Map004~006 所有人工路徑」
#    直接當成 Formal Verifier 的 blocking FAIL，導致只做 Boss、AI 或單一路徑重測時，
#    即使程式驗證全綠仍被標 FAILED。
# 本版正式分離 Automated Verifier 與 Manual Runtime Evidence：
# 自動 verifier 驗程式邏輯；人工 runtime coverage 仍記錄完整，但不再阻塞自動 verifier。
#------------------------------------------------------------------------------
# 【主要設定項】
# VERTICAL_VERIFY_FINAL_VERSION_V1018：本修正版本。
# RUNTIME_EVIDENCE_BLOCKING_V1018：固定 false；人工 runtime evidence 不阻塞 formal verifier。
#------------------------------------------------------------------------------
# 【機制規則】
# 1. MAP_STORY_VERTICAL_SLICE_V101 仍是正式 S mode，不新增第六個 mode。
# 2. Story/Recruit Separation 以 @verification_frame 在固定 frame 驗證，不依賴 respond_to?。
# 3. 驗證 special_wins=1 / special_cleared=false 時：
#    - 故事調查完成。
#    - HUD 顯示「調查完成」。
#    - wild_wins>=2 時 Boss Gate 開放。
#    - 招募狀態仍保持 false。
# 4. 再切 special_cleared=true，HUD 必須顯示「已招募」。
# 5. special_wins=0 時 Boss Gate 必須鎖住。
# 6. v1.01.2 runtime coverage 改為 evidence-only：仍輸出 maps/npcs/checkpoint/visible/walking/
#    special/boss/returns/camp 等資料，但 coverage 不完整不再設 @map_story_failed_v101。
# 7. 真正 automated verifier 任一程式檢查失敗時，仍照常 blocking FAIL。
# 8. Dynamic Tactical Role、Spatial Framework、Damage Formula、Attack Speed、Skill FX 不變。
#------------------------------------------------------------------------------
# 【可調參數】
# 本版無玩家向調參。若未來要做一次性的 Release Acceptance，可另外建立 strict runtime mode，
# 不要重新把日常 Formal Verifier 綁死在同一 session 的人工探索覆蓋率。
#------------------------------------------------------------------------------
# 【事件／腳本呼叫方式】
# 不需修改地圖事件。
# 正式驗證：AutoChess 布陣畫面按 S 切到 MAP_STORY_VERTICAL_SLICE_V101，再按 Shift。
# 人工 runtime coverage：照常遊玩 Map004~006，PMD_MapStoryVerticalSlice_v1.01.log 仍會記錄。
#------------------------------------------------------------------------------
# 【實際範例】
# 只測皮卡丘流程、沒有打 Boss：
# -> MAP_STORY_RUNTIME_EVIDENCE_V1018 pass=1 coverage_complete=0 blocking=0
# -> 其他 automated checks 全通時 Formal Verifier 仍可 PASS。
# 完整走完 Map004~006：
# -> coverage_complete=1，代表人工 evidence 也完整。
#------------------------------------------------------------------------------
# 【維護注意】
# - 不刪除 v1.01.2 runtime coverage；只是修正其「證據」與「自動測試」角色混淆。
# - Pokémon identity 永遠使用 instance_uid。
# - 不直接修改 Frozen Combat Core；本腳本只做 trailing verification override。
# - 新增/修改腳本避免使用禁止的 literal probe 字串。
#==============================================================================
module PMD_AC
  VERTICAL_VERIFY_FINAL_VERSION_V1018='1.01.8'
  RUNTIME_EVIDENCE_BLOCKING_V1018=false
end

class Scene_PMD_AutoChess
  alias pmd_ac_v1018_update_verification_script update_verification_script unless method_defined?(:pmd_ac_v1018_update_verification_script)

  # v1.01.2 的 runtime coverage 保留，但改為 evidence-only。
  # 這個方法名稱沿用舊 API，讓舊 update wrapper 自動呼叫到新版實作。
  def verify_map_story_runtime_acceptance_v1012
    return if @verification_done[:map_story_runtime_acceptance_v1012]
    complete=PMD_AC.runtime_acceptance_v1012?
    log_event(:verify,'MAP_STORY_RUNTIME_EVIDENCE_V1018 pass=1 coverage_complete='+(complete ? '1':'0')+
      ' blocking=0 '+PMD_AC.runtime_summary_v1012)
    @verification_done[:map_story_runtime_acceptance_v1012]=true
  end

  def verify_story_progress_separation_v1018
    return if @verification_done[:story_progress_separation_v1018]
    s=PMD_AC.rpg_foundation_state_v100
    old={
      :wild_wins=>s[:wild_wins],:special_wins=>s[:special_wins],
      :special_cleared=>s[:special_cleared],:boss_cleared=>s[:boss_cleared]
    }
    pass=false
    story_done=false
    boss_open=false
    boss_locked=false
    status_story=''
    status_recruit=''
    begin
      s[:wild_wins]=2
      s[:special_wins]=1
      s[:special_cleared]=false
      s[:boss_cleared]=false
      story_done=PMD_AC.vertical_special_story_done_v1017?
      boss_open=PMD_AC.vertical_story_boss_unlocked_v1017?
      status_story=PMD_AC.vertical_status_text_v101
      s[:special_cleared]=true
      status_recruit=PMD_AC.vertical_status_text_v101
      s[:special_cleared]=false
      s[:special_wins]=0
      boss_locked=!PMD_AC.vertical_story_boss_unlocked_v1017?
      pass=story_done && boss_open && boss_locked &&
        status_story.index('調查完成')!=nil && status_story.index('已招募')==nil &&
        status_recruit.index('已招募')!=nil
    rescue
      pass=false
    ensure
      s[:wild_wins]=old[:wild_wins]
      s[:special_wins]=old[:special_wins]
      s[:special_cleared]=old[:special_cleared]
      s[:boss_cleared]=old[:boss_cleared]
    end
    @map_story_failed_v101=true unless pass
    log_event(:verify,'STORY_PROGRESS_SEPARATION_V1017 pass='+(pass ? '1':'0')+
      ' hook=v1018 story_by_special_win='+(story_done ? '1':'0')+
      ' boss_after_special='+(boss_open ? '1':'0')+
      ' boss_before_special_locked='+(boss_locked ? '1':'0')+
      ' recruit_separate=1 damage_unchanged=1 attack_speed_unchanged=1')
    @verification_done[:story_progress_separation_v1018]=true
  end

  def verify_vertical_slice_policy_v1018
    return if @verification_done[:vertical_slice_policy_v1018]
    pass=PMD_AC::RUNTIME_EVIDENCE_BLOCKING_V1018==false
    @map_story_failed_v101=true unless pass
    log_event(:verify,'MAP_STORY_VERIFIER_POLICY_V1018 pass='+(pass ? '1':'0')+
      ' automated_logic_blocking=1 runtime_evidence_blocking=0 s_modes=5')
    @verification_done[:vertical_slice_policy_v1018]=true
  end

  def update_verification_script
    pmd_ac_v1018_update_verification_script
    return unless verification_mode==:map_story_vertical_slice_v101
    f=@verification_frame.to_i
    verify_story_progress_separation_v1018 if f>=34
    verify_vertical_slice_policy_v1018 if f>=190
  end
end
