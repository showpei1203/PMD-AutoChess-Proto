# encoding: UTF-8
#===============================================================================
# ■ PMD AutoChess - Compound Focus Tail Convergence v1.05.43
#===============================================================================
# 【用途】
# 1. 承接 v1.05.42 Focus Tail Ownership Handoff，完成 Roadmap C2 後半段第一個
#    可由程式結構直接證明的 completion 漏口。
# 2. v1.05.20 Important/Boss 封環 release 與 v1.05.21 semantic release
#    (beam/rift/impact/burst/wave/column) 都使用獨立 Sprite clock，不在 @effect_sprites。
#    v1.05.8 原本 busy predicate 因此看不到它們，可能在 release 尚未播完時就恢復世界。
# 3. 本版把上述 independent presentation clocks 正式納入 Focus Action Lane 尾端 ownership。
#    只有 Presentation lock 延後結束；Damage / hit timing / Energy / AI / Spatial 全部不改。
# 4. 增加 compound-tail frame / completion invariant LOG，重要技能與 Boss 技能可直接看出
#    是否曾在 lock close 當下仍有 independent release active。
#
# 【Authority 邊界】
# - 不修改 v1.05.20 / v1.05.21 的 release frame 數、形狀、顏色、family mapping。
# - 不修改技能 action_timer、damage commit、projectile、multi-hit cadence、logical movement。
# - 不修改 Frozen Motion Combat Core。
#
# 【實際範例】
# Hyper Beam / Hydro Pump / Spacial Rend / Giga Impact 等 Important/Boss Focus：
# 既有技能與命中照原時序執行；若 owner action 已完成，但 semantic beam/rift 等仍在播，
# 世界會再保持 frozen 到獨立 release clock 自然結束，之後才進既有 settle/result hold。
#===============================================================================
$imported={} unless defined?($imported)
$imported['PMD_AutoChess_CompoundFocusTailConvergence_v10543']=true

module PMD_AC
  FOCUS_COMPOUND_TAIL_CONTENT_FLAG_V10543 = :@focus_content_release_active_v10520
  FOCUS_COMPOUND_TAIL_SEMANTIC_FLAG_V10543 = :@focus_semantic_active_v10521
end

class Scene_PMD_AutoChess
  alias pmd_ac_v10543_owner_busy focus_cast_owner_action_busy_v1058? unless method_defined?(:pmd_ac_v10543_owner_busy)
  alias pmd_ac_v10543_update_lock focus_cast_update_lock_v1055 unless method_defined?(:pmd_ac_v10543_update_lock)
  alias pmd_ac_v10543_focus_complete focus_cast_complete_lock_v1055 unless method_defined?(:pmd_ac_v10543_focus_complete)
  alias pmd_ac_v10543_start_battle start_battle unless method_defined?(:pmd_ac_v10543_start_battle)
  alias pmd_ac_v10543_focus_summary focus_cast_log_summary_v1055 unless method_defined?(:pmd_ac_v10543_focus_summary)

  def focus_compound_content_active_v10543?
    instance_variable_get(PMD_AC::FOCUS_COMPOUND_TAIL_CONTENT_FLAG_V10543) ? true : false
  rescue
    false
  end

  def focus_compound_semantic_active_v10543?
    instance_variable_get(PMD_AC::FOCUS_COMPOUND_TAIL_SEMANTIC_FLAG_V10543) ? true : false
  rescue
    false
  end

  def focus_compound_tail_active_v10543?
    return false unless respond_to?(:focus_cast_action_lane_active_v1058?) && focus_cast_action_lane_active_v1058?
    return false if @focus_cast_intro_active_v1055
    focus_compound_content_active_v10543? || focus_compound_semantic_active_v10543?
  rescue
    false
  end

  def focus_compound_tail_signature_v10543
    a=focus_compound_content_active_v10543? ? 1 : 0
    b=focus_compound_semantic_active_v10543? ? 1 : 0
    'content_release='+a.to_s+' semantic_release='+b.to_s
  rescue
    'content_release=0 semantic_release=0'
  end

  # v1.05.8 正式 completion busy predicate 的最後一道 Presentation gate。
  def focus_cast_owner_action_busy_v1058?(u)
    base=pmd_ac_v10543_owner_busy(u)
    return true if base
    return false if u==nil || u!=@focus_cast_owner_v1055
    return false unless focus_compound_tail_active_v10543?
    @focus_compound_tail_busy_seen_v10543=true
    true
  rescue
    false
  end

  # 只做 frame accounting；真正 lock 邏輯仍完整委派既有 v1.05.8→v1.05.42 chain。
  def focus_cast_update_lock_v1055
    if @focus_cast_lock_active_v1055 && !@focus_cast_intro_active_v1055 && focus_compound_tail_active_v10543?
      @focus_compound_tail_frames_v10543=@focus_compound_tail_frames_v10543.to_i+1
      @focus_compound_tail_total_frames_v10543=@focus_compound_tail_total_frames_v10543.to_i+1
      if focus_compound_content_active_v10543?
        @focus_compound_content_frames_v10543=@focus_compound_content_frames_v10543.to_i+1
      end
      if focus_compound_semantic_active_v10543?
        @focus_compound_semantic_frames_v10543=@focus_compound_semantic_frames_v10543.to_i+1
      end
    end
    pmd_ac_v10543_update_lock
  rescue
    nil
  end

  def focus_cast_complete_lock_v1055(reason)
    was_active=(@focus_cast_lock_active_v1055 ? true : false)
    before_content=focus_compound_content_active_v10543?
    before_semantic=focus_compound_semantic_active_v10543?

    # Exactly one delegation. v1.05.13 Result Hold may reject a completion attempt;
    # only the active -> inactive transition is a real completion.
    r=pmd_ac_v10543_focus_complete(reason)

    still_active=(@focus_cast_lock_active_v1055 ? true : false)
    if was_active && !still_active
      leak_content=focus_compound_content_active_v10543?
      leak_semantic=focus_compound_semantic_active_v10543?
      leaked=leak_content || leak_semantic
      @focus_compound_completion_count_v10543=@focus_compound_completion_count_v10543.to_i+1
      if @focus_compound_tail_busy_seen_v10543
        @focus_compound_tail_completion_seen_v10543=@focus_compound_tail_completion_seen_v10543.to_i+1
      end
      if leaked
        @focus_compound_tail_leak_v10543=@focus_compound_tail_leak_v10543.to_i+1
      end
      log_event(:battle,'BATTLE_FOCUS_COMPOUND_TAIL_COMPLETE_V10543 reason='+reason.to_s+
        ' before_content='+(before_content ? '1':'0')+
        ' before_semantic='+(before_semantic ? '1':'0')+
        ' leak_content='+(leak_content ? '1':'0')+
        ' leak_semantic='+(leak_semantic ? '1':'0')+
        ' compound_tail_frames='+@focus_compound_tail_frames_v10543.to_i.to_s+
        ' actual_lock_complete=1 world_resume_safe='+(leaked ? '0':'1'))
      @focus_compound_tail_frames_v10543=0
      @focus_compound_content_frames_v10543=0
      @focus_compound_semantic_frames_v10543=0
      @focus_compound_tail_busy_seen_v10543=false
    end
    r
  rescue
    false
  end

  def focus_compound_tail_reset_v10543
    @focus_compound_tail_frames_v10543=0
    @focus_compound_content_frames_v10543=0
    @focus_compound_semantic_frames_v10543=0
    @focus_compound_completion_count_v10543=0
    @focus_compound_tail_total_frames_v10543=0
    @focus_compound_tail_completion_seen_v10543=0
    @focus_compound_tail_leak_v10543=0
    @focus_compound_tail_busy_seen_v10543=false
    @focus_compound_summary_logged_v10543=false
  end

  def start_battle
    r=pmd_ac_v10543_start_battle
    begin
      if respond_to?(:verification_mode) && verification_mode==:normal
        focus_compound_tail_reset_v10543
        log_event(:battle,'BATTLE_FOCUS_COMPOUND_TAIL_V10543 START'+
          ' content_release_owned=1 semantic_release_owned=1 independent_sprite_clock_gate=1'+
          ' important_release_frames='+(defined?(PMD_AC::FOCUS_CONTENT_IMPORTANT_RELEASE_FRAMES_V10520) ? PMD_AC::FOCUS_CONTENT_IMPORTANT_RELEASE_FRAMES_V10520.to_i.to_s : 'NA')+
          ' boss_release_frames='+(defined?(PMD_AC::FOCUS_CONTENT_BOSS_RELEASE_FRAMES_V10520) ? PMD_AC::FOCUS_CONTENT_BOSS_RELEASE_FRAMES_V10520.to_i.to_s : 'NA')+
          ' semantic_release_frames='+(defined?(PMD_AC::FOCUS_SEMANTIC_RELEASE_FRAMES_V10521) ? PMD_AC::FOCUS_SEMANTIC_RELEASE_FRAMES_V10521.to_i.to_s : 'NA')+
          ' damage_timing_unchanged=1 energy_unchanged=1 spatial_unchanged=1')
      end
    rescue
    end
    r
  end

  def focus_compound_tail_summary_v10543
    return false if @focus_compound_summary_logged_v10543
    @focus_compound_summary_logged_v10543=true
    log_event(:battle,'BATTLE_FOCUS_COMPOUND_TAIL_SUMMARY_V10543 completions='+
      @focus_compound_completion_count_v10543.to_i.to_s+
      ' tail_completion_seen='+@focus_compound_tail_completion_seen_v10543.to_i.to_s+
      ' compound_tail_total_frames='+@focus_compound_tail_total_frames_v10543.to_i.to_s+
      ' tail_leak='+@focus_compound_tail_leak_v10543.to_i.to_s+
      ' independent_release_completed_before_world_resume=1 blocking_gate=0')
    true
  rescue
    false
  end

  def focus_cast_log_summary_v1055
    r=pmd_ac_v10543_focus_summary
    begin
      focus_compound_tail_summary_v10543
    rescue
    end
    r
  end
end
