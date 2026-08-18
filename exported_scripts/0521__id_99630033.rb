# encoding: UTF-8
#===============================================================================
# ■ PMD AutoChess - Sandshrew Head-Only Guard + Focused Visual Review v1.05.36
#===============================================================================
# 【用途】
# 1. 修正 v1.05.35 Windows 人工 Visual QA 首次抓到的真實 presentation bug：
#    #0027 穿山鼠與 #0028 穿山王在部分 route 被選到 :head 時，畫面只剩一顆頭。
# 2. 實際素材確認兩者 Head-Anim.png 是 PMD component-style Head sheet，不是可獨立代表
#    全身的 combat body action；因此本版把 0027 / 0028 的 standalone :head 視為
#    presentation-unsafe component pose。
# 3. 只在 native_pose_candidates_v061 最終候選中「第一個真正 playable pose 是 :head」時
#    才介入。若原 route 本來選的不是 :head，本版完全不改候選順序。
# 4. 介入後移除 :head，並依 family 從既有 full-body pose 中挑選通過 playable、strict45、
#    Anatomy Gate、Semantic Gate 的安全替代；若沒有更佳替代，保留 parent 其餘候選，最後
#    仍可回退完整 Attack，不會為了統計數字重新使用 Head component。
# 5. 新增 NORMAL battle F9 focused fixture，只展示穿山鼠 / 穿山王，快速重驗
#    neutral / Attack / Hurt / Strike / Dash / Lunge / Spin，不必重新觀看完整 56-species F7。
# 6. F9 中可用 F8 標記目前 phase 仍有肉眼問題；完整跑完且 marks=0 才代表本次人工
#    focused review 沒再看到 head-only 症狀。人工標記不是 gameplay fail。
#
# 【主要設定】
# SANDSHREW_HEAD_COMPONENT_SPECIES_V10536 = ['0027','0028']
#   目前經 Windows F8 + 素材檢查確認 Head sheet 不可 standalone 的 species。
# SANDSHREW_FULL_BODY_PREFS_V10536
#   只在原本會選到 :head 時使用。Dash/Lunge 優先 Double，Spin 優先 Rotate/Double，
#   Strike 優先 Strike/Swing，Head/Bite 優先 Strike/Swing，再回完整 Attack。
# SANDSHREW_FOCUSED_PHASES_V10536
#   F9 展示 neutral、attack、hurt、strike、dash、lunge、spin。
# SANDSHREW_FOCUSED_PHASE_FRAMES_V10536 = 54
#   每 phase 自動停留 54 frame，亦可按 C 提前切換。
# SANDSHREW_FOCUSED_THRESHOLD_MS_V10536 = 50
#   targeted 32-route QA 沿用正式 50ms 門檻，不放寬。
#
# 【機制規則】
# - Frozen Motion Combat Core 不直接修改，只用 trailing alias 包裝 native_pose_candidates_v061。
# - 不把 :head 全域封鎖；只處理 0027、0028，避免誤傷其他 species 真正可 standalone 的 Head。
# - 只在原 route 第一個 playable pose 為 :head 時才替換，避免趁修 bug 改掉無關動作。
# - safety 判定沿用 motion_playable_v102?、motion_generated_diag_geometry_v1040?、
#   motion_batchiii_pose_allowed_v1043、motion_batchiv_semantic_pose_allowed_v1044。
# - 不修改 Damage Formula、HP、AI、Energy、Attack Wait、Priority、hit timing。
# - 不修改 logical Spatial x/y、velocity、dash/lunge endpoint、push/pull/through。
# - HOME 仍是 logical/action anchor；F9 只建立 isolated preview Sprite。
# - F9 active 時 combat step 與正式 performance capture 暫停，退出後恢復；50ms 正式門檻不變。
# - v1.05.33 candidate exhaustion policy 保留；本修正是人工 QA 發現的 component-source bug，
#   不是重新開啟「為了降低 generic Attack」的自動 tuning 流水線。
#
# 【事件／腳本呼叫方式】
# - NORMAL battle：routing guard 自動生效。
# - F9：啟動 0027 / 0028 focused visual review。
# - F9 Fixture 中：
#   C      下一 phase
#   F8     標記/取消目前 phase 疑點
#   B/Esc  提早離開
# - 查詢 targeted QA：PMD_AC.sandshrew_head_guard_qa_v10536
# - 查詢最後 QA：PMD_AC.sandshrew_head_guard_last_qa_v10536
#
# 【LOG】
# BATTLE_SANDSHREW_HEAD_COMPONENT_GUARD_V10536 START ...
# BATTLE_SANDSHREW_HEAD_COMPONENT_ROUTE_V10536 ...
# BATTLE_SANDSHREW_HEAD_COMPONENT_GUARD_SUMMARY_V10536 ...
# BATTLE_SANDSHREW_FOCUSED_VISUAL_V10536 READY / START / PHASE / FINDING / COMPLETE ...
# BATTLE_SANDSHREW_FOCUSED_VISUAL_SUMMARY_V10536 ...
#
# 【實際範例】
# - v1.05.35：0027 small:dash = head，畫面只剩頭。
#   v1.05.36：若 Double 通過既有四項 safety gate，候選會改為 Double 優先，Head 被移除。
# - v1.05.35：0028 medium:dash = head，同樣只剩頭。
#   v1.05.36：同理改用 full-body candidate；真正 Dash 位移終點仍由 Spatial Runtime 決定。
#===============================================================================
$imported={} unless defined?($imported)
$imported['PMD_AutoChess_SandshrewHeadOnlyGuard_FocusedVisualReview_v10536']=true

module PMD_AC
  SANDSHREW_HEAD_COMPONENT_SPECIES_V10536=['0027','0028']
  SANDSHREW_FOCUSED_PHASES_V10536=[:neutral,:attack,:hurt,:strike,:dash,:lunge,:spin]
  SANDSHREW_FOCUSED_PHASE_FRAMES_V10536=54
  SANDSHREW_FOCUSED_THRESHOLD_MS_V10536=50
  SANDSHREW_FULL_BODY_PREFS_V10536={
    :strike=>[:strike,:swing,:double,:attack],
    :dash=>[:double,:strike,:swing,:attack],
    :lunge=>[:double,:strike,:swing,:attack],
    :head=>[:strike,:swing,:double,:attack],
    :bite=>[:strike,:swing,:double,:attack],
    :multi=>[:double,:strike,:swing,:attack],
    :spin=>[:rotate,:double,:swing,:attack],
    :tail=>[:swing,:strike,:double,:attack],
    :punch=>[:strike,:swing,:double,:attack],
    :kick=>[:strike,:swing,:double,:attack]
  }

  class << self
    alias pmd_ac_v10536_sandshrew_native_pose_candidates_v061 native_pose_candidates_v061 unless method_defined?(:pmd_ac_v10536_sandshrew_native_pose_candidates_v061)

    def sandshrew_component_species_v10536?(species)
      SANDSHREW_HEAD_COMPONENT_SPECIES_V10536.include?(species.to_s)
    rescue
      false
    end

    def sandshrew_first_playable_candidate_v10536(species,list)
      (list || []).each do |pose|
        next if pose==nil
        return pose if motion_playable_v102?(species.to_s,pose)
      end
      nil
    rescue
      nil
    end

    def sandshrew_full_body_pose_safe_v10536(species,pose,family)
      return false if pose==nil || pose==:head
      sid=species.to_s
      return false unless motion_playable_v102?(sid,pose)
      if respond_to?(:motion_generated_diag_geometry_v1040?)
        return false unless motion_generated_diag_geometry_v1040?(sid,pose)
      end
      if respond_to?(:motion_batchiii_pose_allowed_v1043)
        return false unless motion_batchiii_pose_allowed_v1043(sid,pose,family)
      end
      if respond_to?(:motion_batchiv_semantic_pose_allowed_v1044)
        return false unless motion_batchiv_semantic_pose_allowed_v1044(sid,pose,family)
      end
      true
    rescue
      false
    end

    def sandshrew_full_body_replacement_v10536(species,family,base)
      prefs=SANDSHREW_FULL_BODY_PREFS_V10536[family] || []
      prefs.each do |pose|
        return pose if sandshrew_full_body_pose_safe_v10536(species,pose,family)
      end
      (base || []).each do |pose|
        next if pose==:head
        return pose if sandshrew_full_body_pose_safe_v10536(species,pose,family)
      end
      return :attack if motion_playable_v102?(species.to_s,:attack)
      nil
    rescue
      nil
    end

    def native_pose_candidates_v061(species,move_key,data=nil,profile=nil)
      base=pmd_ac_v10536_sandshrew_native_pose_candidates_v061(species,move_key,data,profile)
      return base unless sandshrew_component_species_v10536?(species)
      selected=sandshrew_first_playable_candidate_v10536(species,base)
      return base unless selected==:head
      family=motion_action_family_v102(move_key,data,profile)
      filtered=[]
      (base || []).each do |pose|
        next if pose==nil || pose==:head
        filtered.push(pose) unless filtered.include?(pose)
      end
      replacement=sandshrew_full_body_replacement_v10536(species,family,filtered)
      out=[]
      out.push(replacement) if replacement!=nil
      filtered.each{|pose|out.push(pose) unless out.include?(pose)}
      out.push(:attack) if out.empty? && motion_playable_v102?(species.to_s,:attack)
      @sandshrew_head_guard_hits_v10536={} if @sandshrew_head_guard_hits_v10536==nil
      @sandshrew_head_guard_hits_v10536[species.to_s+':'+family.to_s]={:from=>:head,:to=>replacement}
      out.empty? ? filtered : out
    rescue
      pmd_ac_v10536_sandshrew_native_pose_candidates_v061(species,move_key,data,profile)
    end

    def sandshrew_head_guard_hits_v10536
      @sandshrew_head_guard_hits_v10536 || {}
    rescue
      {}
    end

    def sandshrew_head_guard_last_qa_v10536
      @sandshrew_head_guard_last_qa_v10536
    end

    def sandshrew_head_guard_qa_v10536
      t0=Time.now
      total=0;playable=0;strict=0;family_ok=0;head_selected=0;bad=[];critical=[]
      cases=const_defined?(:MOTION_REPRESENTATIVE_FAMILY_CASES_V1043) ? MOTION_REPRESENTATIVE_FAMILY_CASES_V1043 : []
      SANDSHREW_HEAD_COMPONENT_SPECIES_V10536.each do |sid|
        cases.each do |row|
          total+=1
          fam=row[0]
          r=motion_source_route_v102(sid,row[1],row[2],row[3])
          sel=r==nil ? nil : r[:selected]
          p=(r!=nil && r[:has_playable])
          f=(r!=nil && r[:family]==fam)
          s=false
          begin;s=(sel!=nil && motion_generated_diag_geometry_v1040?(sid,sel));rescue;s=false;end
          h=(sel==:head)
          playable+=1 if p;family_ok+=1 if f;strict+=1 if s;head_selected+=1 if h
          if !p || !f || !s || h
            bad.push(sid+':'+fam.to_s+'='+(sel==nil ? 'nil' : sel.to_s)+
              ':p'+(p ? '1':'0')+'s'+(s ? '1':'0')+'f'+(f ? '1':'0')+'head'+(h ? '1':'0')) if bad.size<16
          end
          if (sid=='0027' && [:dash,:lunge,:spin].include?(fam)) ||
             (sid=='0028' && [:dash,:lunge].include?(fam))
            critical.push(sid+':'+fam.to_s+'='+(sel==nil ? 'nil' : sel.to_s))
          end
        end
      end
      ms=((Time.now-t0)*1000.0).round
      pass=(total==32 && playable==32 && strict==32 && family_ok==32 && head_selected==0 &&
        bad.empty? && ms<=SANDSHREW_FOCUSED_THRESHOLD_MS_V10536)
      @sandshrew_head_guard_last_qa_v10536={:pass=>pass,:total=>total,:playable=>playable,
        :strict=>strict,:family=>family_ok,:head_selected=>head_selected,:bad=>bad,:critical=>critical,:ms=>ms}
    rescue
      @sandshrew_head_guard_last_qa_v10536={:pass=>false,:total=>0,:playable=>0,:strict=>0,
        :family=>0,:head_selected=>-1,:bad=>['exception'],:critical=>[],:ms=>0}
    end

    def sandshrew_focused_info_v10536(sid,body,phase)
      if phase==:neutral || phase==:attack || phase==:hurt
        return representative_visual_phase_info_v10534(sid,body,phase)
      end
      r=representative_visual_route_info_v10534(sid,phase)
      r[:phase]=phase;r[:label]=phase.to_s.upcase
      r
    rescue
      {:phase=>phase,:family=>phase,:pose=>nil,:fallback=>false,:native=>false,:playable=>false,:label=>phase.to_s.upcase}
    end
  end
end

#===============================================================================
# ■ Preview Panel helper：允許 F9 直接餵 family route info。
#===============================================================================
class Sprite_PMDRepresentativeVisualPanelV10534
  def set_custom_info_v10536(phase,info)
    @phase=phase;@info=info
    pose=@info==nil ? nil : @info[:pose]
    @data=pose==nil ? nil : PMD_AC.action_data(@sid,pose)
    @bitmap=pose==nil ? nil : PMD_AC.representative_visual_bitmap_v10534(@sid,pose)
    @right.bitmap=@bitmap;@left.bitmap=@bitmap
    @right.visible=(@bitmap!=nil && @data!=nil);@left.visible=@right.visible
    @frame_index=0;@frame_wait=0
    configure_geometry_v10534
    redraw_panel_v10534
    update_source_rect_v10534
  rescue
    @right.visible=false if @right!=nil
    @left.visible=false if @left!=nil
  end
end

#===============================================================================
# ■ Scene_PMD_AutoChess - F9 Sandshrew Focused Visual Review
#===============================================================================
class Scene_PMD_AutoChess
  alias pmd_ac_v10536_sand_start_battle start_battle unless method_defined?(:pmd_ac_v10536_sand_start_battle)
  alias pmd_ac_v10536_sand_update_battle_input update_battle_input unless method_defined?(:pmd_ac_v10536_sand_update_battle_input)
  alias pmd_ac_v10536_sand_update_battle_step update_battle_step unless method_defined?(:pmd_ac_v10536_sand_update_battle_step)
  alias pmd_ac_v10536_sand_motion_perf_capture_active_v1023 motion_perf_capture_active_v1023? unless method_defined?(:pmd_ac_v10536_sand_motion_perf_capture_active_v1023)
  alias pmd_ac_v10536_sand_restart_to_deploy restart_to_deploy unless method_defined?(:pmd_ac_v10536_sand_restart_to_deploy)
  alias pmd_ac_v10536_sand_terminate terminate unless method_defined?(:pmd_ac_v10536_sand_terminate)
  alias pmd_ac_v10536_sand_focus_summary focus_cast_log_summary_v1055 unless method_defined?(:pmd_ac_v10536_sand_focus_summary)

  def start_battle
    @sand_focus_active_v10536=false
    @sand_focus_phase_v10536=0
    @sand_focus_frame_v10536=0
    @sand_focus_marks_v10536={}
    @sand_focus_runs_v10536=0
    @sand_focus_completes_v10536=0
    @sand_focus_request_v10536=false
    r=pmd_ac_v10536_sand_start_battle
    begin
      if respond_to?(:verification_mode) && verification_mode==:normal &&
         !(respond_to?(:production_external_battle_fast_v10613?) && production_external_battle_fast_v10613?)
        q=PMD_AC.sandshrew_head_guard_qa_v10536
        log_event(:battle,'BATTLE_SANDSHREW_HEAD_COMPONENT_GUARD_V10536 START species=0027,0028 blocked_pose=head'+
          ' source=v10535_windows_f8 asset_type=component_only intervention=only_if_first_playable_head'+
          ' motion_core_unchanged=1 gameplay_change=0')
        log_event(:battle,'BATTLE_SANDSHREW_HEAD_COMPONENT_GUARD_SUMMARY_V10536 pass='+(q[:pass] ? '1':'0')+
          ' routes='+q[:total].to_i.to_s+'/32 playable='+q[:playable].to_i.to_s+'/32 strict45='+q[:strict].to_i.to_s+
          '/32 family='+q[:family].to_i.to_s+'/32 head_selected='+q[:head_selected].to_i.to_s+
          ' critical=['+(q[:critical] || []).join(',')+'] qa_ms='+q[:ms].to_i.to_s+
          ' threshold_ms='+PMD_AC::SANDSHREW_FOCUSED_THRESHOLD_MS_V10536.to_s+' bad=['+(q[:bad] || []).join(',')+']')
        log_event(:battle,'BATTLE_SANDSHREW_FOCUSED_VISUAL_V10536 READY input=F9 species=0027,0028'+
          ' phases='+PMD_AC::SANDSHREW_FOCUSED_PHASES_V10536.size.to_s+' F8_mark=1 combat_step_paused=1'+
          ' preview_only=1 manual_visual_judgement_required=1')
      end
    rescue
    end
    r
  end

  def sandshrew_focus_active_v10536?
    @sand_focus_active_v10536==true
  end

  def sandshrew_focus_ready_v10536?
    return false unless @phase==:battle
    return false unless respond_to?(:verification_mode) && verification_mode==:normal
    return false if respond_to?(:representative_visual_fixture_active_v10534?) && representative_visual_fixture_active_v10534?
    return false if respond_to?(:focus_cast_action_lane_active_v1058?) && focus_cast_action_lane_active_v1058?
    return false if respond_to?(:result_feedback_hold_active_v10513?) && result_feedback_hold_active_v10513?
    q=PMD_AC.sandshrew_head_guard_last_qa_v10536
    return false if q==nil || !q[:pass]
    true
  rescue
    false
  end

  def sandshrew_focus_dispose_v10536
    (@sand_focus_panels_v10536 || []).each{|p|p.dispose if p!=nil}
    @sand_focus_panels_v10536=[]
    s=@sand_focus_overlay_v10536
    if s!=nil
      begin;s.bitmap.dispose if s.bitmap!=nil && !s.bitmap.disposed?;rescue;end
      begin;s.dispose unless s.disposed?;rescue;end
    end
    @sand_focus_overlay_v10536=nil
  rescue
  end

  def sandshrew_focus_draw_v10536
    if @sand_focus_overlay_v10536==nil
      @sand_focus_overlay_v10536=Sprite.new(@viewport)
      @sand_focus_overlay_v10536.bitmap=Bitmap.new(Graphics.width,Graphics.height)
      @sand_focus_overlay_v10536.z=15000
    end
    b=@sand_focus_overlay_v10536.bitmap;b.clear
    b.fill_rect(0,0,Graphics.width,Graphics.height,Color.new(3,6,10,248))
    font=PMD_AC.const_defined?(:UI_PANEL_FONT_V0741) ? PMD_AC::UI_PANEL_FONT_V0741 : ['Microsoft JhengHei']
    b.font.name=font;b.font.size=20;b.font.bold=true;b.font.color=Color.new(255,255,255)
    b.draw_text(8,3,Graphics.width-16,26,'Focused Visual Review  |  Sandshrew Head-Only Guard',1)
    phase=PMD_AC::SANDSHREW_FOCUSED_PHASES_V10536[@sand_focus_phase_v10536.to_i] || :neutral
    b.font.size=13;b.font.bold=false;b.font.color=Color.new(195,215,235)
    b.draw_text(8,29,Graphics.width-16,19,'#0027 穿山鼠 + #0028 穿山王   phase '+phase.to_s.upcase+
      '   Head component must never appear standalone',1)
    marks=(@sand_focus_marks_v10536 || {}).size
    b.font.size=12;b.font.bold=true;b.font.color=Color.new(255,220,125)
    b.draw_text(8,Graphics.height-21,Graphics.width-16,18,
      'F8 標記/取消疑點 ['+marks.to_s+']   C 下一動作   B/Esc 離開   F9 啟動',1)
  rescue
  end

  def sandshrew_focus_apply_phase_v10536
    phase=PMD_AC::SANDSHREW_FOCUSED_PHASES_V10536[@sand_focus_phase_v10536.to_i] || :neutral
    rows=[['0027',:small],['0028',:medium]]
    (@sand_focus_panels_v10536 || []).each_with_index do |p,i|
      sid=rows[i][0];body=rows[i][1]
      info=PMD_AC.sandshrew_focused_info_v10536(sid,body,phase)
      p.set_custom_info_v10536(phase,info)
    end
    @sand_focus_frame_v10536=0
    sandshrew_focus_draw_v10536
    poses=[]
    rows.each do |row|
      info=PMD_AC.sandshrew_focused_info_v10536(row[0],row[1],phase)
      poses.push(row[0]+':' +(info[:pose]==nil ? 'nil' : info[:pose].to_s))
    end
    log_event(:battle,'BATTLE_SANDSHREW_FOCUSED_VISUAL_PHASE_V10536 phase='+phase.to_s+
      ' poses=['+poses.join(',')+'] head_selected='+(poses.any?{|x|x.index(':head')!=nil} ? '1':'0'))
  rescue
  end

  def sandshrew_focus_start_v10536
    return false unless sandshrew_focus_ready_v10536?
    return false if sandshrew_focus_active_v10536?
    @sand_focus_active_v10536=true
    @sand_focus_phase_v10536=0;@sand_focus_frame_v10536=0;@sand_focus_marks_v10536={}
    @sand_focus_runs_v10536=@sand_focus_runs_v10536.to_i+1
    @sand_focus_request_v10536=false
    @sand_focus_panels_v10536=[]
    gap=6;top=52;bottom=27
    pw=(Graphics.width-gap*3)/2;ph=Graphics.height-top-bottom-gap*2
    p1=Sprite_PMDRepresentativeVisualPanelV10534.new(@viewport,gap,top+gap,pw,ph,'0027',:small,1,2)
    p2=Sprite_PMDRepresentativeVisualPanelV10534.new(@viewport,gap*2+pw,top+gap,pw,ph,'0028',:medium,2,2)
    @sand_focus_panels_v10536=[p1,p2]
    sandshrew_focus_draw_v10536
    sandshrew_focus_apply_phase_v10536
    log_event(:battle,'BATTLE_SANDSHREW_FOCUSED_VISUAL_V10536 START input=F9 species=0027,0028'+
      ' phases='+PMD_AC::SANDSHREW_FOCUSED_PHASES_V10536.size.to_s+' stable_species_scale=1'+
      ' combat_step_paused=1 performance_capture_paused=1 preview_sprite_isolated=1')
    true
  rescue
    @sand_focus_active_v10536=false
    sandshrew_focus_dispose_v10536
    false
  end

  def sandshrew_focus_toggle_mark_v10536
    phase=PMD_AC::SANDSHREW_FOCUSED_PHASES_V10536[@sand_focus_phase_v10536.to_i] || :neutral
    @sand_focus_marks_v10536={} if @sand_focus_marks_v10536==nil
    if @sand_focus_marks_v10536[phase]
      @sand_focus_marks_v10536.delete(phase);action='unmark'
      begin;Sound.play_cancel;rescue;end
    else
      @sand_focus_marks_v10536[phase]=true;action='mark'
      begin;Sound.play_decision;rescue;end
    end
    log_event(:battle,'BATTLE_SANDSHREW_FOCUSED_VISUAL_FINDING_V10536 action='+action+
      ' phase='+phase.to_s+' marks_now='+@sand_focus_marks_v10536.size.to_s)
    sandshrew_focus_draw_v10536
  rescue
  end

  def sandshrew_focus_finish_v10536(ok,reason)
    return unless sandshrew_focus_active_v10536?
    marks=(@sand_focus_marks_v10536 || {}).keys.collect{|x|x.to_s}.sort
    @sand_focus_active_v10536=false
    sandshrew_focus_dispose_v10536
    @sand_focus_completes_v10536=@sand_focus_completes_v10536.to_i+1 if ok
    visual_pass=ok && marks.empty?
    log_event(:battle,'BATTLE_SANDSHREW_FOCUSED_VISUAL_COMPLETE_V10536 fixture_complete='+(ok ? '1':'0')+
      ' visual_pass='+(visual_pass ? '1':'0')+' reason='+reason.to_s+' marks='+marks.size.to_s+
      ' findings=['+marks.join(',')+'] head_component_guard_retained=1 combat_step_resumed=1'+
      ' performance_capture_resumed=1 manual_visual_judgement_required=1')
    begin
      @motion_perf_capture_last_time_v1023=Time.now if defined?(@motion_perf_capture_last_time_v1023)
    rescue
    end
    visual_pass
  rescue
    false
  end

  def sandshrew_focus_next_v10536
    @sand_focus_phase_v10536=@sand_focus_phase_v10536.to_i+1
    if @sand_focus_phase_v10536>=PMD_AC::SANDSHREW_FOCUSED_PHASES_V10536.size
      sandshrew_focus_finish_v10536(true,'complete')
    else
      sandshrew_focus_apply_phase_v10536
    end
  rescue
    sandshrew_focus_finish_v10536(false,'phase_exception')
  end

  def update_battle_input
    if sandshrew_focus_active_v10536?
      if Input.trigger?(Input::B)
        begin;Sound.play_cancel;rescue;end
        sandshrew_focus_finish_v10536(false,'manual_exit')
      elsif Input.trigger?(Input::F8)
        sandshrew_focus_toggle_mark_v10536
      elsif Input.trigger?(Input::C)
        begin;Sound.play_decision;rescue;end
        sandshrew_focus_next_v10536
      end
      return
    end
    if Input.trigger?(Input::F9)
      @sand_focus_request_v10536=true
      if sandshrew_focus_ready_v10536?
        begin;Sound.play_decision;rescue;end
        sandshrew_focus_start_v10536
      else
        log_event(:battle,'BATTLE_SANDSHREW_FOCUSED_VISUAL_V10536 REQUEST input=F9 pending_safe_boundary=1')
      end
      return
    end
    if @sand_focus_request_v10536 && sandshrew_focus_ready_v10536?
      begin;Sound.play_decision;rescue;end
      sandshrew_focus_start_v10536
      return
    end
    pmd_ac_v10536_sand_update_battle_input
  rescue
    pmd_ac_v10536_sand_update_battle_input
  end

  def update_battle_step
    if sandshrew_focus_active_v10536?
      (@sand_focus_panels_v10536 || []).each{|p|p.update if p!=nil}
      @sand_focus_frame_v10536=@sand_focus_frame_v10536.to_i+1
      if @sand_focus_frame_v10536>=PMD_AC::SANDSHREW_FOCUSED_PHASE_FRAMES_V10536
        sandshrew_focus_next_v10536
      end
      return
    end
    pmd_ac_v10536_sand_update_battle_step
  rescue
    pmd_ac_v10536_sand_update_battle_step
  end

  def motion_perf_capture_active_v1023?
    return false if sandshrew_focus_active_v10536?
    pmd_ac_v10536_sand_motion_perf_capture_active_v1023
  rescue
    pmd_ac_v10536_sand_motion_perf_capture_active_v1023
  end

  def restart_to_deploy
    sandshrew_focus_finish_v10536(false,'return_deploy') if sandshrew_focus_active_v10536?
    pmd_ac_v10536_sand_restart_to_deploy
  end

  def terminate
    sandshrew_focus_dispose_v10536
    pmd_ac_v10536_sand_terminate
  end

  def focus_cast_log_summary_v1055
    r=pmd_ac_v10536_sand_focus_summary
    return r if respond_to?(:production_external_battle_fast_v10613?) && production_external_battle_fast_v10613?
    begin
      q=PMD_AC.sandshrew_head_guard_last_qa_v10536 || {}
      marks=(@sand_focus_marks_v10536 || {}).keys.collect{|x|x.to_s}.sort
      log_event(:battle,'BATTLE_SANDSHREW_FOCUSED_VISUAL_SUMMARY_V10536 guard_pass='+(q[:pass] ? '1':'0')+
        ' head_selected='+q[:head_selected].to_i.to_s+' runs='+@sand_focus_runs_v10536.to_i.to_s+
        ' completes='+@sand_focus_completes_v10536.to_i.to_s+' marks='+marks.size.to_s+
        ' findings=['+marks.join(',')+'] input=F9 next_gate='+
        ((@sand_focus_completes_v10536.to_i>0 && marks.empty?) ? 'transition_continuity_fixture' : 'run_F9_focused_review'))
    rescue
    end
    r
  end
end
