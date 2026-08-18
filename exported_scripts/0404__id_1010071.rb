# encoding: UTF-8
#==============================================================================
# 【PMD AutoChess 中文維護說明】
# 腳本：PMD AutoChess Story Progression / Recruit Separation v1.01.7
# 分類：Map / NPC / Story Vertical Slice 劇情進度修正／特殊遭遇與招募解耦
# RPG Maker VX / RGSS2 / Ruby 1.8 compatible
#------------------------------------------------------------------------------
# 【用途】
# 修正 v1.01～v1.01.6 的林緣劇情把「皮卡丘故事調查完成」錯綁成
# 「特殊皮卡丘成功招募」的問題。Windows 實機已出現 special_wins>0、甚至 Boss CLEAR，
# 但 HUD 仍顯示「皮卡丘 未完成」；這代表 RNG 招募結果反過來控制劇情主線。
# 本版把故事進度與收集結果正式分離：打贏特殊遭遇一次即完成調查，是否招募則另外顯示。
#------------------------------------------------------------------------------
# 【主要設定項】
# VERTICAL_STORY_PROGRESS_VERSION_V1017：本修正版本。
# SPECIAL_STORY_WIN_REQ_V1017：完成皮卡丘調查所需特殊遭遇勝場，預設 1。
# BOSS_STORY_WILD_WIN_REQ_V1017：開放蜂巢 Boss 所需林緣野戰勝場，沿用 2。
#------------------------------------------------------------------------------
# 【機制規則】
# 1. 皮卡丘故事完成 = special_wins >= 1；不再要求 special_cleared=true。
# 2. special_cleared 保留原意：特殊遭遇成功招募／收集完成，不改 Foundation Recruit 邏輯。
# 3. Boss 主線開放 = wild_wins >= 2 且皮卡丘故事調查已完成。
# 4. 已打贏皮卡丘但尚未招募時，仍可再次調查特殊足跡，作為可選招募重戰。
# 5. HUD 分三種狀態：未調查／調查完成／已招募，不再混成單一完成旗標。
# 6. F7 Boss 重測捷徑只補「測試用 special_wins=1」，不設定 special_cleared，
#    因此不會假造皮卡丘已加入隊伍或圖鑑 owned。
# 7. Dynamic Tactical Role、Spatial Framework、Skill FX、Damage Formula、Attack Speed 不變。
#------------------------------------------------------------------------------
# 【可調參數】
# - SPECIAL_STORY_WIN_REQ_V1017：若未來劇情要求多次調查，可提高此值。
# - BOSS_STORY_WILD_WIN_REQ_V1017：若林緣流程拉長，可提高野戰勝場門檻。
#------------------------------------------------------------------------------
# 【事件／腳本呼叫方式】
# 正式事件不需改：
#   PMD_AC.vertical_special_v101
#   PMD_AC.vertical_boss_gate_v101
#   PMD_AC.vertical_boss_v101
# 查故事調查是否完成：
#   PMD_AC.vertical_special_story_done_v1017?
# 查蜂巢主線是否開放：
#   PMD_AC.vertical_story_boss_unlocked_v1017?
#------------------------------------------------------------------------------
# 【實際範例】
# special_wins=1, special_cleared=false
# -> HUD「皮卡丘 調查完成」；Boss 可在 wild_wins>=2 時解鎖；仍可重戰嘗試招募。
# special_wins=1, special_cleared=true
# -> HUD「皮卡丘 已招募」。
#------------------------------------------------------------------------------
# 【維護注意】
# - 不直接修改 v1.00 Foundation state schema；以既有 special_wins / special_cleared 解讀。
# - Pokémon 個體身份仍為 instance_uid。
# - 不直接修改 Frozen Combat Core；本腳本只做 trailing alias / presentation hook。
# - S 選單不增加 mode；驗證仍掛 MAP_STORY_VERTICAL_SLICE_V101。
#==============================================================================
module PMD_AC
  VERTICAL_STORY_PROGRESS_VERSION_V1017='1.01.7'
  SPECIAL_STORY_WIN_REQ_V1017=1
  BOSS_STORY_WILD_WIN_REQ_V1017=2

  class << self
    def vertical_special_story_done_v1017?
      s=rpg_foundation_state_v100
      s[:special_wins].to_i>=SPECIAL_STORY_WIN_REQ_V1017
    end

    def vertical_story_boss_unlocked_v1017?
      s=rpg_foundation_state_v100
      s[:wild_wins].to_i>=BOSS_STORY_WILD_WIN_REQ_V1017 && vertical_special_story_done_v1017?
    end

    # 劇情目標改以「特殊遭遇勝利」而非招募成功推進。
    def vertical_objective_v101
      s=rpg_foundation_state_v100
      return '蜂巢霸主已討伐。返回營地整理隊伍與收集成果。' if s[:boss_cleared]
      return '先在林緣取得 1 場勝利，確認野生寶可夢異常。' if s[:wild_wins].to_i<1
      unless vertical_special_story_done_v1017?
        return '特殊足跡已出現；林緣深處可調查皮卡丘。'
      end
      return '再取得 1 場林緣勝利，追查蜂群來源。' if s[:wild_wins].to_i<BOSS_STORY_WILD_WIN_REQ_V1017
      '皮卡丘的異常已確認。通往蜂巢林地的道路已開放。'
    end

    # 招募狀態與故事調查狀態分開顯示。
    def vertical_status_text_v101
      s=rpg_foundation_state_v100
      pstate=if s[:special_cleared]
        '已招募'
      elsif vertical_special_story_done_v1017?
        '調查完成'
      else
        '未調查'
      end
      '林緣勝利 '+s[:wild_wins].to_i.to_s+'｜皮卡丘 '+pstate+
        '｜Boss '+(s[:boss_cleared] ? 'CLEAR':'未討伐')
    end

    # 已完成故事但未招募時，特殊點仍可作可選招募重戰。
    alias pmd_ac_v1017_vertical_special_v101 vertical_special_v101 unless method_defined?(:pmd_ac_v1017_vertical_special_v101)
    def vertical_special_v101
      s=rpg_foundation_state_v100
      if vertical_special_story_done_v1017? && !s[:special_cleared]
        vertical_log_v101('SPECIAL_RECRUIT_REMATCH_V1017 story_done=1 recruited=0 special_wins='+s[:special_wins].to_i.to_s)
      end
      pmd_ac_v1017_vertical_special_v101
    end

    # Vertical Slice 主線 Boss Gate 額外要求特殊皮卡丘調查完成。
    alias pmd_ac_v1017_vertical_boss_gate_v101 vertical_boss_gate_v101 unless method_defined?(:pmd_ac_v1017_vertical_boss_gate_v101)
    def vertical_boss_gate_v101
      unless vertical_story_boss_unlocked_v1017?
        s=rpg_foundation_state_v100
        if s[:wild_wins].to_i<BOSS_STORY_WILD_WIN_REQ_V1017
          vertical_message_v101(['前方蜂群太密，現在還不能通過。',
            '林緣勝利需要 '+BOSS_STORY_WILD_WIN_REQ_V1017.to_s+' 次，目前 '+s[:wild_wins].to_i.to_s+' 次。'])
        else
          vertical_message_v101(['蜂群的來源還無法確定。','先完成林緣深處的皮卡丘特殊足跡調查。'])
        end
        vertical_log_v101('BOSS_GATE_STORY_V1017 locked=1 wild_wins='+s[:wild_wins].to_i.to_s+
          ' special_wins='+s[:special_wins].to_i.to_s)
        return false
      end
      pmd_ac_v1017_vertical_boss_gate_v101
    end

    # 防止直接碰 Boss 事件繞過 Gate。
    alias pmd_ac_v1017_vertical_boss_v101 vertical_boss_v101 unless method_defined?(:pmd_ac_v1017_vertical_boss_v101)
    def vertical_boss_v101
      unless vertical_story_boss_unlocked_v1017?
        s=rpg_foundation_state_v100
        vertical_message_v101(['現在還不能挑戰蜂巢霸主。',vertical_objective_v101])
        vertical_log_v101('BOSS_STORY_V1017 locked=1 wild_wins='+s[:wild_wins].to_i.to_s+
          ' special_wins='+s[:special_wins].to_i.to_s)
        return false
      end
      pmd_ac_v1017_vertical_boss_v101
    end

    # 開發用 F7 直接 Boss 重測時，補齊故事前置，但不假造招募成功。
    alias pmd_ac_v1017_boss_retest_shortcut_v1014 boss_retest_shortcut_v1014 unless method_defined?(:pmd_ac_v1017_boss_retest_shortcut_v1014)
    def boss_retest_shortcut_v1014
      s=rpg_foundation_state_v100
      injected=false
      if s[:special_wins].to_i<SPECIAL_STORY_WIN_REQ_V1017
        s[:special_wins]=SPECIAL_STORY_WIN_REQ_V1017
        injected=true
      end
      ok=pmd_ac_v1017_boss_retest_shortcut_v1014
      if ok
        vertical_log_v101('BOSS_RETEST_STORY_PREREQ_V1017 special_wins='+s[:special_wins].to_i.to_s+
          ' recruited='+(s[:special_cleared] ? '1':'0')+' injected='+(injected ? '1':'0'))
      end
      ok
    end
  end
end

class Scene_PMD_AutoChess
  alias pmd_ac_v1017_update_verification_script update_verification_script unless method_defined?(:pmd_ac_v1017_update_verification_script)
  def update_verification_script
    pmd_ac_v1017_update_verification_script
    return unless respond_to?(:map_story_vertical_slice_v101?) && map_story_vertical_slice_v101?
    verify_story_progress_separation_v1017 if @logic_frame.to_i>=34
  end

  def verify_story_progress_separation_v1017
    return if @verification_done[:story_progress_separation_v1017]
    s=PMD_AC.rpg_foundation_state_v100
    old={
      :wild_wins=>s[:wild_wins],:special_wins=>s[:special_wins],
      :special_cleared=>s[:special_cleared],:boss_cleared=>s[:boss_cleared]
    }
    pass=false
    begin
      s[:wild_wins]=2
      s[:special_wins]=1
      s[:special_cleared]=false
      s[:boss_cleared]=false
      story_done=PMD_AC.vertical_special_story_done_v1017?
      boss_open=PMD_AC.vertical_story_boss_unlocked_v1017?
      status_story=PMD_AC.vertical_status_text_v101
      objective_story=PMD_AC.vertical_objective_v101
      s[:special_cleared]=true
      status_recruit=PMD_AC.vertical_status_text_v101
      s[:special_cleared]=false
      s[:special_wins]=0
      boss_locked=!PMD_AC.vertical_story_boss_unlocked_v1017?
      pass=story_done && boss_open && boss_locked &&
        status_story.include?('調查完成') && !status_story.include?('已招募') &&
        status_recruit.include?('已招募') && objective_story.include?('蜂巢林地')
    ensure
      s[:wild_wins]=old[:wild_wins]
      s[:special_wins]=old[:special_wins]
      s[:special_cleared]=old[:special_cleared]
      s[:boss_cleared]=old[:boss_cleared]
    end
    log_event(:verify,'STORY_PROGRESS_SEPARATION_V1017 pass='+(pass ? '1':'0')+
      ' story_by_special_win=1 recruit_separate=1 boss_requires_special_win=1 optional_recruit_rematch=1 f7_prereq_only=1 damage_unchanged=1 attack_speed_unchanged=1')
    @verification_done[:story_progress_separation_v1017]=true
  end
end
