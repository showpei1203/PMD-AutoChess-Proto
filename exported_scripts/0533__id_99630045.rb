# encoding: UTF-8
#===============================================================================
# ■ PMD AutoChess - C2 Windows Evidence Reconciliation v1.05.48
#===============================================================================
# 【用途】
# 依據 2026-08-15 Windows NORMAL battle 實機 LOG，修正 v1.05.41 / v1.05.45
# 的 QA 量測語意，使 C2 報表只對真正的 Presentation / Ownership 問題報警。
# 本版不修改 Damage、HP、Energy、AI、Accuracy、Priority、Attack Wait、Spatial
# endpoint、Projectile speed / collision / tracking、Motion Core 或任何技能數值。
#
# 【實機證據與修正】
# 1. v1.05.41 Structural Audit：504/504 route 全可播放，但 56 個 projectile case
#    全被 router 選成 route_beam，因此舊版 family_match=448/504。
#    - PMD body motion 的 :beam / :projectile 都屬合法 remote-release 身體語言。
#    - 本版允許「expected=:projectile、route_family=:beam」作 semantic-compatible。
#    - 不改 router 選擇，不強迫替換任何 Native pose。
#
# 2. v1.05.45 presentation_home_residual：舊版直接讀 presentation_sprite_offset_v055，
#    其中包含 v0.55.3 的 hit-recoil。Windows LOG 因此把正常 recoil 誤算成 HOME drift。
#    - 本版優先讀 v0.55.3 recoil 之前的 base motion offset。
#    - Hit recoil / Hurt feedback 可繼續播放，不再被誤判為技能 travel 殘留。
#
# 3. v1.05.45 orphan_at_close：v1.05.8 completion 會先清 ownership baseline，
#    舊版再於 lock 關閉後重新數 sprite，會把已 handoff 回 battle world 的 sprite
#    誤認為本技能 orphan。
#    - 真正 pre-close orphan 仍由 v1.05.41 snapshot / v1.05.42 / v1.05.43 gate 檢查。
#    - lock 已關閉後 ownership 定義為 0，不再對 world-owned sprite 報假警報。
#
# 4. v1.05.18 status_result_diag_v10518：舊診斷直接呼叫不存在的 action_timer accessor，
#    Windows LOG 每次 pure-status 都顯示 diag_error=1。
#    - 本版改讀既有 @action_timer / @action_hit_frame / @action_hit_done。
#    - 僅修 LOG 診斷，不碰 action clock。
#
# 5. v1.05.41 Runtime Observer：semantic family=:projectile 不代表 Runtime delivery
#    必然建立 logical projectile；visual_kind 也可能讓技能被歸為 projectile family。
#    - 本版記錄實際 user.skill_data[:delivery]。
#    - 只有 delivery=:projectile 且真的沒有 launch 時才列 logical projectile warning。
#    - deal_direct_damage 增加 observer-only commit fallback；若既有 mark hook 已記錄，
#      不重複計數，更不呼叫 gameplay parent 第二次。
#
# 【依賴與載入順序】
# 必須放在以下腳本之後、Main 之前：
# - PMD AutoChess Move Family Presentation Audit I v1.05.41
# - PMD AutoChess Focus Tail Ownership Handoff v1.05.42
# - PMD AutoChess Important Family Exception + Single Delegation Seal v1.05.44
# - PMD AutoChess C2 Completion Boundary Seal v1.05.45
#
# 【事件／腳本呼叫】
# 不需要事件呼叫。NORMAL battle 自動啟用。
#
# 【實際範例】
# - Water Gun / Ember 類 remote skill 若 PMD router 選 :beam 身體動作，仍屬合法。
# - Quick Attack 結束時若角色正承受 recoil，recoil 不再被當成技能沒有回 HOME。
# - Focus lock 關閉後留在世界中的 basic hit particle 不再被當成本技能 orphan。
#===============================================================================
$imported={} unless defined?($imported)
$imported['PMD_AutoChess_C2WindowsEvidenceReconciliation_v10548']=true

module PMD_AC
  class << self
    alias pmd_ac_v10548_move_family_semantic_match_v10541 move_family_semantic_match_v10541 unless method_defined?(:pmd_ac_v10548_move_family_semantic_match_v10541)

    # Remote release 的身體動作可共用 beam / projectile pose family。
    # 這只影響 QA semantic match，不修改 router 或 Runtime delivery。
    def move_family_semantic_match_v10541(expected,route_family)
      return true if expected==:projectile && [:projectile,:beam].include?(route_family)
      pmd_ac_v10548_move_family_semantic_match_v10541(expected,route_family)
    rescue
      false
    end
  end
end

class Scene_PMD_AutoChess
  alias pmd_ac_v10548_start_battle start_battle unless method_defined?(:pmd_ac_v10548_start_battle)
  alias pmd_ac_v10548_focus_summary focus_cast_log_summary_v1055 unless method_defined?(:pmd_ac_v10548_focus_summary)
  alias pmd_ac_v10548_owned_active_counts move_family_owned_active_counts_v10541 unless method_defined?(:pmd_ac_v10548_owned_active_counts)
  alias pmd_ac_v10548_c2_snapshot c2_completion_snapshot_v10545 unless method_defined?(:pmd_ac_v10548_c2_snapshot)
  alias pmd_ac_v10548_deal_direct_damage deal_direct_damage unless method_defined?(:pmd_ac_v10548_deal_direct_damage)
  alias pmd_ac_v10548_move_family_context move_family_context_v10541 unless method_defined?(:pmd_ac_v10548_move_family_context)

  #--------------------------------------------------------------------------
  # ● Runtime context 補上實際 delivery，讓 visual semantic 與 logical delivery 分離。
  #--------------------------------------------------------------------------
  def move_family_context_v10541(user,target)
    ctx=pmd_ac_v10548_move_family_context(user,target)
    begin
      d=(user!=nil && user.respond_to?(:skill_data)) ? (user.skill_data || {}) : {}
      ctx[:delivery]=d[:delivery] || :instant
      ctx[:visual_kind]=d[:visual_kind]
    rescue
      ctx[:delivery]=:unknown if ctx!=nil
    end
    ctx
  end

  #--------------------------------------------------------------------------
  # ● Ownership 只在 active Focus lock 內成立。
  #   pre-close snapshot 仍會走 parent；post-close world handoff 回傳 0/0。
  #--------------------------------------------------------------------------
  def move_family_owned_active_counts_v10541
    return [0,0] unless @focus_cast_lock_active_v1055
    pmd_ac_v10548_owned_active_counts
  rescue
    [0,0]
  end

  #--------------------------------------------------------------------------
  # ● C2 HOME 只看 skill motion offset，不把 hit recoil 當成 travel residual。
  #--------------------------------------------------------------------------
  def c2_completion_snapshot_v10545(ctx,owner)
    s=pmd_ac_v10548_c2_snapshot(ctx,owner)
    begin
      po=nil
      if owner!=nil && owner.respond_to?(:pmd_ac_v0553_presentation_sprite_offset_v055)
        po=owner.pmd_ac_v0553_presentation_sprite_offset_v055
      elsif owner!=nil && owner.respond_to?(:presentation_motion_active_v055?) &&
            !owner.presentation_motion_active_v055?
        po=[0.0,0.0]
      end
      if po!=nil
        px=po[0].to_f;py=po[1].to_f
        s[:presentation]=Math.sqrt(px*px+py*py)
      end
    rescue
      # 保留 parent snapshot；observer 失敗不可影響 gameplay。
    end
    s
  rescue
    # v1.05.44 single-delegation 原則：parent snapshot 不可因 observer 例外重跑。
    {:active=>[0,0],:total=>0,:project_wait=>0,:effect_tail=>0,:slide_wait=>0,
     :release_to_impact=>-1,:impact_to_complete=>-1,:drift=>0,:presentation=>0.0}
  end

  #--------------------------------------------------------------------------
  # ● v1.05.18 診斷 accessor 修正。
  #--------------------------------------------------------------------------
  def status_result_diag_v10518(u)
    return ' owner=NONE' if u==nil
    data=(u.respond_to?(:skill_data) ? u.skill_data : nil)
    delivery=(data==nil ? :none : (data[:delivery] || :instant))
    ranged=(u.respond_to?(:ranged?) && u.ranged?) ? 1 : 0
    owned=0
    begin
      (@projectile_sprites || []).each do |sp|
        next unless respond_to?(:focus_cast_owned_projectile_v1058?) && focus_cast_owned_projectile_v1058?(sp)
        done=(sp.respond_to?(:finished) && sp.finished) rescue false
        owned+=1 unless done
      end
    rescue
    end
    action=(u.respond_to?(:action) ? u.action : u.instance_variable_get(:@action))
    timer=u.instance_variable_get(:@action_timer).to_i
    hit_frame=u.instance_variable_get(:@action_hit_frame).to_i
    hit_done=u.instance_variable_get(:@action_hit_done) ? 1 : 0
    ' action='+action.to_s+
      ' timer='+timer.to_s+
      ' hit_frame='+hit_frame.to_s+
      ' hit_done='+hit_done.to_s+
      ' delivery='+delivery.to_s+' ranged='+ranged.to_s+
      ' projectiles='+(@projectile_sprites || []).size.to_i.to_s+
      ' owned_projectiles='+owned.to_i.to_s
  rescue
    @v10548_status_diag_error=@v10548_status_diag_error.to_i+1
    ' diag_error=1'
  end

  #--------------------------------------------------------------------------
  # ● Damage commit observer fallback。
  #   parent exactly once；只有既有 observer 沒記到時才補一筆 audit impact。
  #--------------------------------------------------------------------------
  def deal_direct_damage(*args)
    user=(args[0] rescue nil)
    ctx=@move_family_runtime_current_v10541
    before=(ctx==nil ? -1 : ctx[:impacts].to_i)

    r=pmd_ac_v10548_deal_direct_damage(*args)

    begin
      if ctx!=nil && user!=nil && ctx[:user]==user && @focus_cast_lock_active_v1055 &&
         ctx[:impacts].to_i==before
        now=Graphics.frame_count.to_i
        ctx[:first_impact]=now if ctx[:first_impact].to_i<0
        ctx[:last_impact]=now
        ctx[:impacts]=ctx[:impacts].to_i+1
        ctx[:effect_kinds][:damage_runtime]=ctx[:effect_kinds][:damage_runtime].to_i+1
        @v10548_damage_commit_fallback=@v10548_damage_commit_fallback.to_i+1
      end
    rescue
      @v10548_observer_error=@v10548_observer_error.to_i+1
    end
    r
  end

  #--------------------------------------------------------------------------
  # ● v1.05.41 finalize：保留所有原 accounting，只把 warning 改成 delivery-aware。
  #--------------------------------------------------------------------------
  def move_family_runtime_finalize_v10541(ctx,reason,snap)
    active=snap[:active] || [0,0]
    hard=(reason==:v1058_timeout || active[0].to_i>0)
    warns=[]
    if ctx[:damaging] && ctx[:impacts].to_i<=0
      warns.push('no_damage_commit_observed')
    end
    if ctx[:delivery]==:projectile && ctx[:projectiles].to_i<=0
      warns.push('logical_projectile_no_launch')
    end
    if ctx[:family]==:multi_hit && ctx[:impacts].to_i<2
      warns.push('multi_hit_commit_lt2')
    end
    warns.push('effect_active_at_complete') if active[1].to_i>0

    c=@move_family_runtime_counts_v10541[ctx[:family]] || {}
    c[:complete]=c[:complete].to_i+1
    c[:projectiles]=c[:projectiles].to_i+ctx[:projectile_objects].to_i
    c[:impacts]=c[:impacts].to_i+ctx[:impacts].to_i
    c[:max_total]=snap[:total].to_i if snap[:total].to_i>c[:max_total].to_i
    c[:max_project_wait]=snap[:project_wait].to_i if snap[:project_wait].to_i>c[:max_project_wait].to_i
    c[:max_effect_tail]=snap[:effect_tail].to_i if snap[:effect_tail].to_i>c[:max_effect_tail].to_i
    if hard
      c[:hard_fail]=c[:hard_fail].to_i+1
      @move_family_runtime_hard_fail_v10541=@move_family_runtime_hard_fail_v10541.to_i+1
    end
    @move_family_runtime_counts_v10541[ctx[:family]]=c
    warns.each{|w|move_family_runtime_note_warn_v10541(ctx,w)}

    log_event(:battle,'BATTLE_MOVE_FAMILY_PRESENTATION_CAST_V10541 COMPLETE family='+ctx[:family].to_s+
      ' move='+ctx[:move].to_s+' delivery='+(ctx[:delivery]||:unknown).to_s+
      ' reason='+reason.to_s+' total_frames='+snap[:total].to_i.to_s+
      ' impacts='+ctx[:impacts].to_s+' projectile_calls='+ctx[:projectiles].to_s+
      ' projectile_created='+ctx[:projectile_objects].to_s+' release_to_first_impact='+snap[:release_to_impact].to_i.to_s+
      ' last_impact_to_complete='+snap[:impact_to_complete].to_i.to_s+' projectile_wait='+snap[:project_wait].to_i.to_s+
      ' effect_tail='+snap[:effect_tail].to_i.to_s+' slide_wait='+snap[:slide_wait].to_i.to_s+
      ' orphan_projectile='+active[0].to_i.to_s+' active_effect_at_complete='+active[1].to_i.to_s+
      ' logical_drift_observed='+snap[:drift].to_i.to_s+' hard_fail='+(hard ? '1':'0')+
      ' warn=['+warns.join(',')+'] observer_only=1 actual_lock_complete=1 v10548=1')
    true
  rescue
    false
  end

  def start_battle
    r=pmd_ac_v10548_start_battle
    begin
      @v10548_status_diag_error=0
      @v10548_damage_commit_fallback=0
      @v10548_observer_error=0
      @v10548_summary_logged=false
      if respond_to?(:verification_mode) && verification_mode==:normal
        log_event(:battle,'BATTLE_C2_WINDOWS_EVIDENCE_RECONCILIATION_V10548 START'+
          ' projectile_beam_motion_compatible=1 recoil_excluded_from_home=1'+
          ' post_lock_world_handoff=1 status_diag_accessor_fix=1'+
          ' runtime_delivery_aware=1 damage_commit_observer_fallback=1'+
          ' gameplay_change=0 motion_core_unchanged=1')
      end
    rescue
    end
    r
  end

  def c2_windows_evidence_summary_v10548
    return false if @v10548_summary_logged
    @v10548_summary_logged=true
    sq=move_family_structural_result_v10541 rescue {}
    log_event(:battle,'BATTLE_C2_WINDOWS_EVIDENCE_RECONCILIATION_SUMMARY_V10548'+
      ' structural_pass='+(sq[:pass] ? '1':'0')+
      ' family_match='+sq[:family_match].to_i.to_s+'/'+sq[:expected].to_i.to_s+
      ' status_diag_error='+@v10548_status_diag_error.to_i.to_s+
      ' damage_commit_fallback='+@v10548_damage_commit_fallback.to_i.to_s+
      ' observer_error='+@v10548_observer_error.to_i.to_s+
      ' recoil_excluded_from_home=1 post_lock_world_handoff=1'+
      ' gameplay_change=0 blocking_gate=0')
    true
  rescue
    false
  end

  def focus_cast_log_summary_v1055
    r=pmd_ac_v10548_focus_summary
    begin
      c2_windows_evidence_summary_v10548
    rescue
    end
    r
  end
end
