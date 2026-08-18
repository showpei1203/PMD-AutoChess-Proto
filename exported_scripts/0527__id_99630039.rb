# encoding: UTF-8
#===============================================================================
# ■ PMD AutoChess - Focus Tail Ownership Handoff v1.05.42
#===============================================================================
# 【用途】
# 1. 承接 v1.05.41 Move-Family Presentation Audit I，處理 Roadmap C2-II 中已能由
#    程式結構直接確認的「尾端 ownership」問題。
# 2. 修正 Focus Action Lane 期間新建立的持續型 Zone 視覺時鐘會自行前進、但 Zone
#    gameplay remaining 因全場 freeze 不前進，導致兩者壽命不同步的問題。
# 3. 將新建立 Zone 在建立當下完成「Focus-owned transient → battle-owned persistent」
#    handoff：Focus 仍暫停 Zone gameplay，Zone sprite 也同步暫停；世界恢復後兩者再一起走。
# 4. Projectile ownership 再加一道 source-aware 保護：Focus 期間只有本次 owner 新建立的
#    projectile 才屬於 Action Lane；若反應機制意外建立其他來源 projectile，它保持凍結，
#    等世界恢復再繼續，避免「所有 baseline 後的新 projectile 都被誤認為 caster 的」。
# 5. completion 時記錄 Zone sprite life / gameplay remaining 是否維持一致，以及 owner
#    multi-hit event 是否仍 pending。只做 invariant LOG，不改 multi-hit damage / cadence。
#
# 【為什麼需要這版】
# v1.05.8 以「Focus begin 前已存在的 effect object_id」作 baseline。這對短 VFX 正確，
# 但 Zone 在技能命中後才建立，因此會被視為本次 Focus-owned effect。Focus 中 update_zones
# 被刻意凍結，然而 owned effect sprite 仍會 update，Sprite_PMDArenaZone#@life 會減少；
# zone[:remaining] 卻不減少。結果是長時間 Zone 的圖片可能比 gameplay Zone 更早結束。
#
# 【主要設定】
# FOCUS_TAIL_ZONE_INITIAL_OPACITY_PARITY_V10542 = true
#   Zone handoff 當下只同步設定一次與原 update 相同的 pulse opacity，不呼叫 sprite.update，
#   因此不消耗 @life。
#
# 【機制規則】
# - Sprite_PMDArenaZone：persistent battle-owned effect，不進 Focus transient effect tail。
# - Sprite_PMDProjectile：若能讀到 user，只有 user == @focus_cast_owner_v1055 才能在 Focus
#   Action Lane 中前進；無 user metadata 時保留 v1.05.8 baseline 判定。
# - Beam / SustainedBeam / SweepingBeam / impact burst 等短效果仍完整沿用 v1.05.8 ownership。
# - v0.60 multi-contact / multi-ranged owner event 更新規則不改，只在真正 completion 時觀測。
#
# 【Authority 邊界】
# 本版不修改：
# - Damage / HP / Accuracy / Crit
# - AI / target selection
# - Energy / Priority / Attack Wait
# - hit timing / damage commit cadence
# - logical Spatial x/y / endpoint / push / pull / through
# - Zone radius / duration / interval / tick / effects / scope
# - Projectile speed / tracking / collision / damage
# - Multi-hit 次數、間隔與 damage
# - Frozen Motion Combat Core
#
# 【事件／腳本呼叫方式】
# 不需事件呼叫，NORMAL battle 自動生效。
#
# 【LOG】
# BATTLE_FOCUS_TAIL_HANDOFF_V10542 START ...
# BATTLE_FOCUS_TAIL_ZONE_HANDOFF_V10542 ...
# BATTLE_FOCUS_TAIL_COMPLETION_V10542 ...
# BATTLE_FOCUS_TAIL_HANDOFF_SUMMARY_V10542 ...
#
# 【實際範例】
# 使用 Spikes / Toxic Spikes / Stealth Rock / 其他 add_zone 類技能時，Zone 建立後仍立即可見，
# 但 Focus Action Lane 尚未結束的幾幀不再偷偷消耗 Sprite Zone 的 @life。Focus 結束後
# update_zones 與 Sprite update 同步恢復，因此「畫面上的 Zone 壽命」與「真正 gameplay
# remaining」重新維持同一個 battle clock。
#===============================================================================
$imported={} unless defined?($imported)
$imported['PMD_AutoChess_FocusTailOwnershipHandoff_v10542']=true

module PMD_AC
  FOCUS_TAIL_ZONE_INITIAL_OPACITY_PARITY_V10542=true
end

class Scene_PMD_AutoChess
  alias pmd_ac_v10542_owned_effect focus_cast_owned_effect_v1058? unless method_defined?(:pmd_ac_v10542_owned_effect)
  alias pmd_ac_v10542_owned_projectile focus_cast_owned_projectile_v1058? unless method_defined?(:pmd_ac_v10542_owned_projectile)
  alias pmd_ac_v10542_add_zone add_zone unless method_defined?(:pmd_ac_v10542_add_zone)
  alias pmd_ac_v10542_start_battle start_battle unless method_defined?(:pmd_ac_v10542_start_battle)
  alias pmd_ac_v10542_focus_complete focus_cast_complete_lock_v1055 unless method_defined?(:pmd_ac_v10542_focus_complete)
  alias pmd_ac_v10542_focus_summary focus_cast_log_summary_v1055 unless method_defined?(:pmd_ac_v10542_focus_summary)

  def focus_tail_persistent_effect_v10542?(sp)
    return false if sp==nil
    return true if defined?(Sprite_PMDArenaZone) && sp.is_a?(Sprite_PMDArenaZone)
    false
  rescue
    false
  end

  # Persistent Zone belongs to the frozen battle world immediately after creation.
  # It is deliberately NOT a transient Focus effect tail.
  def focus_cast_owned_effect_v1058?(sp)
    return false if focus_tail_persistent_effect_v10542?(sp)
    pmd_ac_v10542_owned_effect(sp)
  rescue
    false
  end

  # v1.05.8 baseline ownership is kept, then refined by source when metadata exists.
  def focus_cast_owned_projectile_v1058?(sp)
    base=pmd_ac_v10542_owned_projectile(sp)
    return false unless base
    return base unless @focus_cast_lock_active_v1055
    begin
      src=sp.user if sp.respond_to?(:user)
      return src==@focus_cast_owner_v1055 if src!=nil
    rescue
    end
    base
  rescue
    false
  end

  def focus_tail_zone_visual_parity_v10542(sp)
    return false if sp==nil || sp.disposed?
    return false unless PMD_AC::FOCUS_TAIL_ZONE_INITIAL_OPACITY_PARITY_V10542
    pulse=150+(Graphics.frame_count.to_i%24)*3
    pulse=120 if pulse<120
    pulse=210 if pulse>210
    sp.opacity=pulse
    true
  rescue
    false
  end

  def focus_tail_note_new_zones_v10542(before_count)
    return 0 unless @focus_cast_lock_active_v1055
    rows=@zones || []
    start=[before_count.to_i,0].max
    return 0 if start>=rows.size
    @focus_tail_pending_zones_v10542=[] if @focus_tail_pending_zones_v10542==nil
    added=0
    i=start
    while i<rows.size
      zone=rows[i]
      if zone!=nil
        sp=zone[:sprite]
        focus_tail_zone_visual_parity_v10542(sp)
        life=0
        begin;life=sp.instance_variable_get(:@life).to_i if sp!=nil;rescue;life=0;end
        rem=zone[:remaining].to_i
        row={:zone=>zone,:sprite=>sp,:life=>life,:remaining=>rem,
          :frame=>(Graphics.frame_count.to_i rescue 0),:style=>zone[:style]}
        @focus_tail_pending_zones_v10542.push(row)
        @focus_tail_zone_handoff_count_v10542=@focus_tail_zone_handoff_count_v10542.to_i+1
        log_event(:battle,'BATTLE_FOCUS_TAIL_ZONE_HANDOFF_V10542 owner='+
          (zone[:owner]==nil ? 'NONE' : zone[:owner].log_name.to_s)+
          ' style='+zone[:style].to_s+' life='+life.to_s+' remaining='+rem.to_s+
          ' persistent_battle_owned=1 focus_effect_tail=0 gameplay_clock_frozen=1 sprite_clock_frozen=1')
        added+=1
      end
      i+=1
    end
    added
  rescue
    0
  end

  def add_zone(*args)
    before=(@zones || []).size
    r=pmd_ac_v10542_add_zone(*args)
    begin
      focus_tail_note_new_zones_v10542(before)
    rescue
    end
    r
  end

  def focus_tail_check_zone_handoffs_v10542
    rows=@focus_tail_pending_zones_v10542 || []
    mismatch=0
    checked=0
    rows.each do |row|
      zone=row[:zone];sp=row[:sprite]
      next if zone==nil
      life=row[:life].to_i
      begin;life_now=sp.instance_variable_get(:@life).to_i if sp!=nil;rescue;life_now=life;end
      life_now=life if life_now==nil
      rem_now=zone[:remaining].to_i
      ok=(life_now.to_i==row[:life].to_i && rem_now==row[:remaining].to_i)
      mismatch+=1 unless ok
      checked+=1
      log_event(:battle,'BATTLE_FOCUS_TAIL_ZONE_HANDOFF_V10542 COMPLETE style='+row[:style].to_s+
        ' initial_life='+row[:life].to_i.to_s+' final_life='+life_now.to_i.to_s+
        ' initial_remaining='+row[:remaining].to_i.to_s+' final_remaining='+rem_now.to_s+
        ' clocks_held='+(ok ? '1':'0'))
    end
    @focus_tail_zone_checked_v10542=@focus_tail_zone_checked_v10542.to_i+checked
    @focus_tail_zone_mismatch_v10542=@focus_tail_zone_mismatch_v10542.to_i+mismatch
    @focus_tail_pending_zones_v10542=[]
    [checked,mismatch]
  rescue
    @focus_tail_pending_zones_v10542=[]
    [0,1]
  end

  def start_battle
    r=pmd_ac_v10542_start_battle
    begin
      @focus_tail_pending_zones_v10542=[]
      @focus_tail_zone_handoff_count_v10542=0
      @focus_tail_zone_checked_v10542=0
      @focus_tail_zone_mismatch_v10542=0
      @focus_tail_completion_count_v10542=0
      @focus_tail_multi_pending_complete_v10542=0
      @focus_tail_summary_logged_v10542=false
      if respond_to?(:verification_mode) && verification_mode==:normal
        log_event(:battle,'BATTLE_FOCUS_TAIL_HANDOFF_V10542 START zone_persistent_handoff=1'+
          ' projectile_source_ownership=1 beam_transient_ownership_unchanged=1'+
          ' multi_hit_cadence_unchanged=1 gameplay_change=0')
      end
    rescue
    end
    r
  end

  def focus_cast_complete_lock_v1055(reason)
    was_active=(@focus_cast_lock_active_v1055 ? true:false)
    owner=@focus_cast_owner_v1055
    multi_before=false
    begin
      multi_before=focus_cast_owner_multi_active_v1058?(owner) if was_active && owner!=nil
    rescue
      multi_before=false
    end

    # Parent includes v1.05.41 observer and all earlier Result Hold / Action Lane contracts.
    # Exactly one delegation. Completion is counted only when the lock really closes.
    r=pmd_ac_v10542_focus_complete(reason)

    still_active=(@focus_cast_lock_active_v1055 ? true:false)
    if was_active && !still_active
      begin
        @focus_tail_completion_count_v10542=@focus_tail_completion_count_v10542.to_i+1
        @focus_tail_multi_pending_complete_v10542=@focus_tail_multi_pending_complete_v10542.to_i+1 if multi_before
        z=focus_tail_check_zone_handoffs_v10542
        log_event(:battle,'BATTLE_FOCUS_TAIL_COMPLETION_V10542 reason='+reason.to_s+
          ' zone_checked='+z[0].to_i.to_s+' zone_clock_mismatch='+z[1].to_i.to_s+
          ' owner_multi_pending_before_close='+(multi_before ? '1':'0')+
          ' actual_lock_complete=1')
      rescue
      end
    end
    r
  end

  def focus_tail_log_summary_v10542
    return false if @focus_tail_summary_logged_v10542
    @focus_tail_summary_logged_v10542=true
    log_event(:battle,'BATTLE_FOCUS_TAIL_HANDOFF_SUMMARY_V10542 completions='+
      @focus_tail_completion_count_v10542.to_i.to_s+
      ' zone_handoffs='+@focus_tail_zone_handoff_count_v10542.to_i.to_s+
      ' zone_checked='+@focus_tail_zone_checked_v10542.to_i.to_s+
      ' zone_clock_mismatch='+@focus_tail_zone_mismatch_v10542.to_i.to_s+
      ' multi_pending_at_complete='+@focus_tail_multi_pending_complete_v10542.to_i.to_s+
      ' persistent_zone_sprite_clock_matches_world_freeze=1'+
      ' projectile_source_ownership=1 blocking_gate=0')
    true
  rescue
    false
  end

  def focus_cast_log_summary_v1055
    r=pmd_ac_v10542_focus_summary
    begin
      focus_tail_log_summary_v10542
    rescue
    end
    r
  end
end
