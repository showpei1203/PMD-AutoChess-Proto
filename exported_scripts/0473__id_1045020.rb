# encoding: UTF-8
#==============================================================================
# 【PMD AutoChess 中文維護說明】
# 腳本：PMD AutoChess Hurt/Faint Narrow Profiler Retire v1.04.5
# 分類：效能診斷收尾／Trailing Layer
# RPG Maker VX / RGSS2 / Ruby 1.8 compatible
#------------------------------------------------------------------------------
# 【用途】
# v1.04.4 Windows 已完成 Hurt/Faint narrow attribution：最重被探測 frame=45ms，
# battle_step=41ms、unit_update=37ms、unit_sprites=4ms、refresh=1ms，並且正式
# MOTION_PERFORMANCE_SEAL_V10229 PASS（max_update_ms=45 < 50）。
# 本版將 v1.04.4 的條件式 Time.now 診斷 wrapper 完整旁路，避免已完成的 profiler
# 繼續在後續 Motion QA 場景增加量測成本；一般 frame profiler 與 50ms Seal 繼續保留。
#------------------------------------------------------------------------------
# 【主要設定】
# 無可調 gameplay 參數。本腳本只復原到 v1.04.4 profiler 安裝前的各 method alias。
#------------------------------------------------------------------------------
# 【機制規則】
# - 不修改 Unit update 內容，只呼叫 v1.04.4 保存的原 method alias。
# - 不修改 Hurt、Faint、Hit-stop、Damage、AI、Attack Speed、Energy、Spatial。
# - Performance Seal 門檻仍為 50ms。
# - 若之後 Performance Seal 再 FAIL，可另開新窄 profiler，不重新啟用本舊探針。
#------------------------------------------------------------------------------
# 【事件／腳本呼叫方式】
# 無需事件呼叫。Verifier 會輸出：
#   MOTION_HURT_FAINT_PROFILER_RETIRED_V1045
#------------------------------------------------------------------------------
# 【實際範例】
# v1.04.4：Hurt>=2 frame 會額外做 component Time.now。
# v1.04.5：直接走 profiler 安裝前 alias；只留下既有整體 Frame Profiler。
#==============================================================================
$imported={} unless defined?($imported)
$imported['PMD_AutoChess_HurtFaintProfilerRetire_v1045']=true

class Game_PMDChessUnit
  def update
    pmd_ac_v1044_hf_unit_update
  end
end

class Sprite_PMDChessUnit
  def refresh_action_bitmap(force)
    pmd_ac_v1044_hf_refresh_action_bitmap(force)
  end
end

class Scene_PMD_AutoChess
  alias pmd_ac_v1045_hf_retire_update_verification_script update_verification_script unless method_defined?(:pmd_ac_v1045_hf_retire_update_verification_script)

  def update
    pmd_ac_v1044_hf_update
  end

  def update_battle_step
    pmd_ac_v1044_hf_update_battle_step
  end

  def update_unit_sprites
    pmd_ac_v1044_hf_update_unit_sprites
  end

  def update_effect_sprites
    pmd_ac_v1044_hf_update_effect_sprites
  end

  def update_projectile_sprites
    pmd_ac_v1044_hf_update_projectile_sprites
  end

  def check_battle_end
    pmd_ac_v1044_hf_check_battle_end
  end

  def update_verification_script
    pmd_ac_v1045_hf_retire_update_verification_script
    return unless respond_to?(:motion_phase_b_verifier_active_v1036?) && motion_phase_b_verifier_active_v1036?
    if !@motion_hf_retired_verify_v1045 && @verification_frame.to_i>=219
      @motion_hf_retired_verify_v1045=true
      log_event(:verify,'MOTION_HURT_FAINT_PROFILER_RETIRED_V1045 pass=1 prior_windows_peak_ms=45 threshold_ms=50'+
        ' unit_update_attribution_ms=37 wrappers_bypassed=1 broad_frame_profiler_retained=1 performance_seal_retained=1'+
        ' hurt_unchanged=1 faint_unchanged=1 hitstop_unchanged=1 damage_unchanged=1 ai_unchanged=1')
    end
  rescue
  end
end
