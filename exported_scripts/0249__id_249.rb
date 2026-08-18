#==============================================================================
# 【PMD AutoChess 中文維護說明】
# 腳本：PMD AutoChess Proto v0.61.2
# 分類：PMDCollab 編譯姿勢
#
# 【用途／機制】
# 讀取已編譯進 VX Script Library 的 PMDCollab 動作資料並做語意路由。
#
# 【怎麼調整】
# Runtime 不讀 XML／外部 rb；新增素材後應重新跑 compiler，再把資料編進 Scripts.rvdata。
#
# 【本腳本主要設定常數／資料表】
# - PATCH_VERSION_V0612
#
# 【Runtime 主要方法（查流程時可直接搜尋）】
# - start / update_compiled_pose_runtime_v061 / complete_verification_mode
#
# 【維護規則】
# - RPG Maker VX / RGSS2 / Ruby 1.8 相容。
# - instance_uid 才是 Pokémon 個體身份；Actor ID 只是容器。
# - 新增行為優先沿用既有 helper／Data 表；避免破壞已 Freeze 的舊核心。
# - 本專案新腳本也必須保留同等級的中文說明與實際範例。
#==============================================================================
#==============================================================================
# ■ PMD AutoChess Proto v0.61.2
#    Verification Clock Fix / Visible Resume Convention
#------------------------------------------------------------------------------
# Additive patch on v0.61.1.
#
# Fix:
# - v0.61.1's COMPILED_POSE_RUNTIME_V061 branch bypassed the older verifier
#   update chain, so @verification_frame never advanced.  The battle scene's
#   global frame counter moved, but the verification clock stayed at 0.
#
# Test UX convention:
# - Finish metadata-only verification immediately after the last required check.
# - Call the common verification_finish path so normal AI / movement resumes.
# - Emit one standard VERIFY_FINISHED_BATTLE_RESUME marker for every mode.
#   When the Pokemon start moving again, the required verification has ended.
#==============================================================================
module PMD_AC
  PATCH_VERSION_V0612 = "0.61.2"
end

class Scene_PMD_AutoChess
  alias pmd_ac_v0612_start start unless method_defined?(:pmd_ac_v0612_start)
  alias pmd_ac_v0612_complete_verification_mode complete_verification_mode unless method_defined?(:pmd_ac_v0612_complete_verification_mode)

  def start
    pmd_ac_v0612_start
    begin
      if FileTest.exist?(PMD_AC::BATTLE_LOG_FILE)
        t = File.open(PMD_AC::BATTLE_LOG_FILE, 'rb') { |f| f.read }
        t.sub!(/PMD AutoChess Proto v0\.61\.1 Battle Verification Log/,
               'PMD AutoChess Proto v0.61.2 Battle Verification Log')
        File.open(PMD_AC::BATTLE_LOG_FILE, 'wb') { |f| f.write(t) }
      end
    rescue
    end
    log_event(:presentation,
      'PATCH v0.61.2 verification_clock=explicit_increment compiled_pose_end=18 '+
      'verify_complete_visual=pokemon_resume common_resume_marker=1 mechanics_unchanged=1')
  end

  # v0.61.1 returned before the inherited verifier could advance this counter.
  # Advance it here exactly once per Scene update while this mode is active.
  def update_compiled_pose_runtime_v061
    return if @verification_done[:verification_complete]
    @verification_frame += 1
    f = @verification_frame

    verify_compiled_loader_v061 if f >= 2
    verify_compiled_core_actions_v061 if f >= 4
    verify_compiled_semantic_actions_v061 if f >= 6
    verify_compiled_phase_v061 if f >= 8
    verify_compiled_pose_router_v061 if f >= 10
    verify_compiled_anchor_metadata_v061 if f >= 12
    verify_compiled_pipeline_boundary_v061 if f >= 14

    # Two frames after the final required assertion are enough for the log to
    # flush and for the player to perceive the state transition.  Do not leave
    # the board frozen for an arbitrary 90-frame tail.
    complete_verification_mode if f >= 18
  end

  # Global visual completion convention.  The inherited implementation calls
  # Game_PMDUnit#verification_finish for every unit, which restores normal AI.
  # Therefore Pokemon movement itself becomes the human-visible "tests done"
  # signal, while this log marker gives the machine-readable equivalent.
  def complete_verification_mode
    already_done = @verification_done[:verification_complete] ? true : false
    pmd_ac_v0612_complete_verification_mode
    if !already_done && @verification_done[:verification_complete]
      log_event(:verify,
        'VERIFY_FINISHED_BATTLE_RESUME pass=1 mode='+verification_mode_label+
        ' pokemon_ai=on pokemon_movement=resume visible_signal=movement')
    end
  end
end
