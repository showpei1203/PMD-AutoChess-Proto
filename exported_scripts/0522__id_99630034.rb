# encoding: UTF-8
#===============================================================================
# ■ PMD AutoChess - Representative Transition Continuity Fixture I v1.05.37
#===============================================================================
# 【用途】
# 1. 承接 v1.05.36 Windows 實機 PASS：#0027 穿山鼠 / #0028 穿山王的 standalone
#    Head component 已被 presentation guard 排除，32/32 targeted QA PASS，F9 focused
#    visual review marks=0；因此下一階段從「單張動作是否完整」進入「動作切換是否連續」。
# 2. 新增 56-species Transition Continuity Fixture，專門觀察：
#      Neutral → Action(single-shot) → End Hold → Neutral Recovery
#    是否出現尺寸跳變、腳底 anchor 瞬移、方向翻面、裁切、最後一格跳回待機太突兀，或
#    routed fallback 雖合法但銜接很怪。
# 3. 每頁沿用 v1.05.34 的 4 species / 2×2 panel、左右 45°同時顯示；每頁依序檢查
#    Attack、Hurt、Route A、Route B、Hotspot 共 5 條 transition sequence。
# 4. Action 不再循環。各 species 依自己的 PMD Durations 播放一次；同頁以最長 action
#    duration 作同步窗口，較短者停在最後一格等待，再一起切回 Neutral，讓 recovery 切點
#    可以肉眼直接比較。
# 5. Fixture 中 F8 可標記/取消目前「page + sequence」疑點；LOG 會保存 4 隻 species、
#    selected pose、action duration，下一輪可直接建立 focused transition review。
#
# 【主要設定】
# REPRESENTATIVE_TRANSITION_INPUT_V10537 = SHIFT + F7
#   避免占用既有 F7 靜態 Visual Fixture、F8 finding、F9 Sandshrew focused review。
# REPRESENTATIVE_TRANSITION_SEQUENCES_V10537
#   [:attack,:hurt,:route_a,:route_b,:hotspot]
# REPRESENTATIVE_TRANSITION_PRE_FRAMES_V10537 = 24
#   Action 前先看 24f Neutral。
# REPRESENTATIVE_TRANSITION_END_HOLD_V10537 = 6
#   所有 action 播完後，最後一格共同停 6f。
# REPRESENTATIVE_TRANSITION_POST_FRAMES_V10537 = 30
#   再切回 Neutral 30f，專門觀察 recovery / foot anchor / scale parity。
# REPRESENTATIVE_TRANSITION_ACTION_MIN_V10537 = 18
# REPRESENTATIVE_TRANSITION_ACTION_MAX_V10537 = 120
#   同頁 action window 依實際最長 PMD duration 決定，僅對 QA 預覽做上下限保護。
# REPRESENTATIVE_TRANSITION_PREWARM_PER_FRAME_V10537 = 3
#   每 frame 暖載 3 個 preview asset，避免啟動當幀集中 I/O。
# REPRESENTATIVE_TRANSITION_THRESHOLD_MS_V10537 = 50
#   只用於 targeted structural audit；正式 50ms Performance threshold 完全不放寬。
#
# 【機制規則】
# - Frozen Motion Combat Core 不直接修改；本版是 trailing QA / Presentation layer。
# - Preview 使用獨立 Sprite，不替換任何正式 Combat unit bitmap / zoom / logical position。
# - Stable scale 繼續沿用 v1.05.35 neutral-reference authority，同一 species 所有 action
#   共用同一比例，不能再靠 per-action fit 掩蓋大小跳變。
# - ox/oy 仍用當前 action frame 的 bottom-center，故 action sheet 本身尺寸 / anchor 差異
#   會如實顯示，這正是本 Fixture 要抓的問題。
# - Action 播放一次後停最後 frame，不 loop；Neutral 才 loop。
# - Fixture active 時 battle step 與正式 performance capture 暫停；完成後重新建立時間邊界。
# - 不修改 Damage Formula、HP、AI、Energy、Attack Wait、Priority、hit timing。
# - 不修改 logical Spatial x/y、velocity、dash/lunge endpoint、push/pull/through。
# - HOME 仍是 logical/action anchor；Fixture 不模擬或改寫真實 Spatial displacement。
# - v1.05.36 Sandshrew Head-only guard 保留；0027/0028 route 不得重新選回 standalone Head。
# - F8 finding 是人工疑點，不自動改 gameplay，也不為了 marks 數量自行重排 Motion。
#
# 【操作方式】
# - NORMAL battle → 按住 SHIFT 再按 F7：啟動 Transition Continuity Fixture。
# - 若 896-route QA 尚未完成，會記住 request，安全邊界到達後自動啟動。
# - Fixture 中：
#   F8      標記/取消目前 page + sequence 疑點
#   C       下一 sequence
#   ← / →   上一頁 / 下一頁
#   ↑ / ↓   上一個 / 下一個 body group
#   B / Esc 提早離開
# - 普通 F7 不變，仍是 v1.05.34 / v1.05.35 的 56-species 靜態 Visual Fixture。
# - F9 不變，仍是 v1.05.36 Sandshrew focused review。
#
# 【LOG】
# BATTLE_REPRESENTATIVE_TRANSITION_V10537 READY / REQUEST / START ...
# BATTLE_REPRESENTATIVE_TRANSITION_PREWARM_V10537 ...
# BATTLE_REPRESENTATIVE_TRANSITION_SEQUENCE_V10537 ...
# BATTLE_REPRESENTATIVE_TRANSITION_FINDING_V10537 ...
# BATTLE_REPRESENTATIVE_TRANSITION_COMPLETE_V10537 ...
# BATTLE_REPRESENTATIVE_TRANSITION_SUMMARY_V10537 ...
#
# 【實際範例】
# - Page 1 / small / route_a：0027 目前是 Double。畫面會先 Walk，Double 只播一次，
#   停最後一格 6f，再回 Walk。若回 Walk 時整隻突然跳高或縮放異常，直接按 F8。
# - Page 13 / serpentine / route_a：0095 等物種目前 routed Swing。若 Swing 本身完整但
#   最後一格回 Walk 時 anchor 明顯跳動，也按 F8；下一版才會針對該 species/sequence
#   做 focused transition correction，不會全域改 serpentine。
#===============================================================================
$imported={} unless defined?($imported)
$imported['PMD_AutoChess_RepresentativeTransitionContinuityFixtureI_v10537']=true

module PMD_AC
  REPRESENTATIVE_TRANSITION_SEQUENCES_V10537=[:attack,:hurt,:route_a,:route_b,:hotspot]
  REPRESENTATIVE_TRANSITION_PRE_FRAMES_V10537=24
  REPRESENTATIVE_TRANSITION_END_HOLD_V10537=6
  REPRESENTATIVE_TRANSITION_POST_FRAMES_V10537=30
  REPRESENTATIVE_TRANSITION_ACTION_MIN_V10537=18
  REPRESENTATIVE_TRANSITION_ACTION_MAX_V10537=120
  REPRESENTATIVE_TRANSITION_PREWARM_PER_FRAME_V10537=3
  REPRESENTATIVE_TRANSITION_THRESHOLD_MS_V10537=50

  class << self
    def representative_transition_action_info_v10537(sid,body,sequence)
      representative_visual_phase_info_v10534(sid,body,sequence)
    rescue
      {:phase=>sequence,:family=>sequence,:pose=>nil,:fallback=>false,:native=>false,:playable=>false,:label=>sequence.to_s.upcase}
    end

    def representative_transition_pose_duration_v10537(sid,pose)
      return REPRESENTATIVE_TRANSITION_ACTION_MIN_V10537 if pose==nil
      d=action_data(sid.to_s,pose)
      return REPRESENTATIVE_TRANSITION_ACTION_MIN_V10537 if d==nil
      ds=d[:durations]
      total=0
      if ds!=nil && !ds.empty?
        ds.each do |v|
          n=v.to_i;n=1 if n<=0;total+=n
        end
      else
        frames=d[:frames].to_i;frames=1 if frames<=0
        total=frames*6
      end
      total=REPRESENTATIVE_TRANSITION_ACTION_MIN_V10537 if total<REPRESENTATIVE_TRANSITION_ACTION_MIN_V10537
      total=REPRESENTATIVE_TRANSITION_ACTION_MAX_V10537 if total>REPRESENTATIVE_TRANSITION_ACTION_MAX_V10537
      total
    rescue
      REPRESENTATIVE_TRANSITION_ACTION_MIN_V10537
    end

    def representative_transition_sequence_rows_v10537(body,sids,sequence)
      out=[]
      (sids || []).each do |sid|
        info=representative_transition_action_info_v10537(sid,body,sequence)
        pose=info[:pose]
        out.push({:sid=>sid.to_s,:info=>info,:pose=>pose,
          :duration=>representative_transition_pose_duration_v10537(sid,pose)})
      end
      out
    rescue
      []
    end

    def representative_transition_structural_audit_v10537
      t0=Time.now
      pages=representative_visual_pages_v10534
      views=0;species=0;playable=0;head_guard=0;bad=[]
      seen={}
      pages.each do |row|
        body=row[0];sids=row[1]
        sids.each{|sid|seen[sid.to_s]=true}
        REPRESENTATIVE_TRANSITION_SEQUENCES_V10537.each do |seq|
          views+=1
          representative_transition_sequence_rows_v10537(body,sids,seq).each do |q|
            p=(q[:info]!=nil && q[:info][:playable])
            playable+=1 if p
            if !p
              bad.push(q[:sid]+':'+seq.to_s+'=unplayable') if bad.size<16
            end
            if ['0027','0028'].include?(q[:sid]) && q[:pose]==:head
              head_guard+=1
              bad.push(q[:sid]+':'+seq.to_s+'=head') if bad.size<16
            end
          end
        end
      end
      species=seen.size
      expected_slots=56*REPRESENTATIVE_TRANSITION_SEQUENCES_V10537.size
      ms=((Time.now-t0)*1000.0).round
      pass=(pages.size==14 && views==70 && species==56 && playable==expected_slots && head_guard==0 && bad.empty? && ms<=REPRESENTATIVE_TRANSITION_THRESHOLD_MS_V10537)
      {:pass=>pass,:pages=>pages.size,:views=>views,:species=>species,:playable=>playable,
       :expected_slots=>expected_slots,:head_guard=>head_guard,:bad=>bad,:ms=>ms}
    rescue
      {:pass=>false,:pages=>0,:views=>0,:species=>0,:playable=>0,:expected_slots=>280,
       :head_guard=>-1,:bad=>['exception'],:ms=>0}
    end
  end
end

#===============================================================================
# ■ Sprite_PMDRepresentativeTransitionPanelV10537
#   沿用 v1.05.35 stable scale，但 action 改成 single-shot。
#===============================================================================
class Sprite_PMDRepresentativeTransitionPanelV10537 < Sprite_PMDRepresentativeVisualPanelV10534
  def initialize(viewport,x,y,w,h,sid,body,index,total)
    @transition_mode_v10537=:neutral
    @transition_action_finished_v10537=false
    super(viewport,x,y,w,h,sid,body,index,total)
    set_neutral_v10537
  end

  def set_neutral_v10537
    @transition_mode_v10537=:neutral
    @transition_action_finished_v10537=false
    set_phase_v10534(:neutral)
  rescue
  end

  def set_action_v10537(info)
    @transition_mode_v10537=:action
    @transition_action_finished_v10537=false
    phase=(info==nil || info[:phase]==nil) ? :attack : info[:phase]
    set_custom_info_v10536(phase,info)
    @frame_index=0
    @frame_wait=transition_frame_duration_v10537(0)-1
    @frame_wait=0 if @frame_wait<0
    update_source_rect_v10534
  rescue
  end

  def transition_frame_duration_v10537(index)
    return 6 if @data==nil
    ds=@data[:durations]
    return 6 if ds==nil || ds.empty?
    n=ds[index.to_i % ds.size].to_i
    n=1 if n<=0
    n
  rescue
    6
  end

  def transition_action_finished_v10537?
    @transition_action_finished_v10537==true
  end

  def update
    if @transition_mode_v10537!=:action
      super
      return
    end
    return if @data==nil || @bitmap==nil || @transition_action_finished_v10537
    if @frame_wait>0
      @frame_wait-=1
      return
    end
    ds=@data[:durations]
    frames=@data[:frames].to_i
    frames=ds.size if frames<=0 && ds!=nil
    frames=1 if frames<=0
    if @frame_index>=frames-1
      @frame_index=frames-1
      @transition_action_finished_v10537=true
      update_source_rect_v10534
      return
    end
    @frame_index+=1
    @frame_index=frames-1 if @frame_index>=frames
    @frame_wait=transition_frame_duration_v10537(@frame_index)-1
    @frame_wait=0 if @frame_wait<0
    update_source_rect_v10534
  rescue
  end
end

#===============================================================================
# ■ Scene_PMD_AutoChess - SHIFT+F7 Transition Continuity Fixture
#===============================================================================
class Scene_PMD_AutoChess
  alias pmd_ac_v10537_transition_start_battle start_battle unless method_defined?(:pmd_ac_v10537_transition_start_battle)
  alias pmd_ac_v10537_transition_update_battle_input update_battle_input unless method_defined?(:pmd_ac_v10537_transition_update_battle_input)
  alias pmd_ac_v10537_transition_update_battle_step update_battle_step unless method_defined?(:pmd_ac_v10537_transition_update_battle_step)
  alias pmd_ac_v10537_transition_motion_perf_capture_active_v1023 motion_perf_capture_active_v1023? unless method_defined?(:pmd_ac_v10537_transition_motion_perf_capture_active_v1023)
  alias pmd_ac_v10537_transition_restart_to_deploy restart_to_deploy unless method_defined?(:pmd_ac_v10537_transition_restart_to_deploy)
  alias pmd_ac_v10537_transition_terminate terminate unless method_defined?(:pmd_ac_v10537_transition_terminate)
  alias pmd_ac_v10537_transition_focus_summary focus_cast_log_summary_v1055 unless method_defined?(:pmd_ac_v10537_transition_focus_summary)

  def start_battle
    @rep_transition_active_v10537=false
    @rep_transition_loading_v10537=false
    @rep_transition_request_v10537=false
    @rep_transition_ready_logged_v10537=false
    @rep_transition_runs_v10537=0
    @rep_transition_completes_v10537=0
    @rep_transition_marks_v10537={}
    @rep_transition_panels_v10537=[]
    pmd_ac_v10537_transition_start_battle
    begin
      if respond_to?(:verification_mode) && verification_mode==:normal
        q=PMD_AC.representative_transition_structural_audit_v10537
        @rep_transition_audit_v10537=q
        log_event(:battle,'BATTLE_REPRESENTATIVE_TRANSITION_AUDIT_V10537 pass='+(q[:pass] ? '1':'0')+
          ' pages='+q[:pages].to_i.to_s+'/14 views='+q[:views].to_i.to_s+'/70 species='+q[:species].to_i.to_s+'/56'+
          ' playable='+q[:playable].to_i.to_s+'/'+q[:expected_slots].to_i.to_s+
          ' sandshrew_head_selected='+q[:head_guard].to_i.to_s+' qa_ms='+q[:ms].to_i.to_s+
          ' threshold_ms='+PMD_AC::REPRESENTATIVE_TRANSITION_THRESHOLD_MS_V10537.to_s+
          ' bad=['+(q[:bad] || []).join(',')+'] gameplay_change=0')
      end
    rescue
    end
  end

  def representative_transition_active_v10537?
    @rep_transition_active_v10537==true
  end

  def representative_transition_ready_v10537?
    return false unless @phase==:battle
    return false unless respond_to?(:verification_mode) && verification_mode==:normal
    return false if representative_transition_active_v10537?
    if respond_to?(:representative_visual_fixture_active_v10534?) && representative_visual_fixture_active_v10534?
      return false
    end
    if respond_to?(:sandshrew_focus_active_v10536?) && sandshrew_focus_active_v10536?
      return false
    end
    if respond_to?(:focus_cast_action_lane_active_v1058?) && focus_cast_action_lane_active_v1058?
      return false
    end
    if respond_to?(:result_feedback_hold_active_v10513?) && result_feedback_hold_active_v10513?
      return false
    end
    rs=PMD_AC.representative_route_qa_state_v10528
    return false if rs==nil || !rs[:complete] || !rs[:pass] || !(rs[:tuning] || []).empty?
    sq=PMD_AC.sandshrew_head_guard_last_qa_v10536
    return false if sq==nil || !sq[:pass] || sq[:head_selected].to_i!=0
    q=@rep_transition_audit_v10537
    q=PMD_AC.representative_transition_structural_audit_v10537 if q==nil
    return false unless q[:pass]
    true
  rescue
    false
  end

  def motion_perf_capture_active_v1023?
    return false if representative_transition_active_v10537?
    pmd_ac_v10537_transition_motion_perf_capture_active_v1023
  rescue
    pmd_ac_v10537_transition_motion_perf_capture_active_v1023
  end

  def representative_transition_create_overlay_v10537
    return if @rep_transition_overlay_v10537!=nil
    @rep_transition_overlay_v10537=Sprite.new(@viewport)
    @rep_transition_overlay_v10537.bitmap=Bitmap.new(Graphics.width,Graphics.height)
    @rep_transition_overlay_v10537.z=16000
  end

  def representative_transition_current_stage_v10537
    f=@rep_transition_frame_v10537.to_i
    pre=PMD_AC::REPRESENTATIVE_TRANSITION_PRE_FRAMES_V10537
    aw=@rep_transition_action_window_v10537.to_i
    hold=PMD_AC::REPRESENTATIVE_TRANSITION_END_HOLD_V10537
    return :pre_neutral if f<pre
    return :action if f<pre+aw
    return :end_hold if f<pre+aw+hold
    :post_neutral
  rescue
    :pre_neutral
  end

  def representative_transition_draw_header_v10537
    representative_transition_create_overlay_v10537
    b=@rep_transition_overlay_v10537.bitmap;b.clear
    b.fill_rect(0,0,Graphics.width,Graphics.height,Color.new(3,6,10,248))
    font=PMD_AC.const_defined?(:UI_PANEL_FONT_V0741) ? PMD_AC::UI_PANEL_FONT_V0741 : ['Microsoft JhengHei']
    b.font.name=font;b.font.size=20;b.font.bold=true;b.font.color=Color.new(255,255,255)
    b.draw_text(8,3,Graphics.width-16,26,'Representative Transition Continuity QA I  |  56 Species',1)
    pages=PMD_AC.representative_visual_pages_v10534
    pi=@rep_transition_page_v10537.to_i
    seq=PMD_AC::REPRESENTATIVE_TRANSITION_SEQUENCES_V10537[@rep_transition_sequence_v10537.to_i] || :attack
    row=(pages!=nil && pi>=0 && pi<pages.size) ? pages[pi] : nil
    body=row==nil ? :none : row[0];sids=row==nil ? [] : row[1]
    stage=representative_transition_current_stage_v10537
    b.font.size=13;b.font.bold=false;b.font.color=Color.new(195,215,235)
    b.draw_text(8,28,Graphics.width-16,19,
      'Page '+(pi+1).to_s+'/14  '+body.to_s.upcase+'  ['+sids.join(',')+']  '+seq.to_s.upcase+
      '  stage='+stage.to_s.upcase+'  action_window='+@rep_transition_action_window_v10537.to_i.to_s+'f',1)
    marks=(@rep_transition_marks_v10537 || {}).size
    b.font.size=12;b.font.bold=true;b.font.color=Color.new(255,220,125)
    b.draw_text(8,Graphics.height-21,Graphics.width-16,18,
      'F8 標記/取消疑點 ['+marks.to_s+']   C 下一序列   ←/→ 換頁   ↑/↓ 換體型   B/Esc 離開   SHIFT+F7 啟動',1)
  rescue
  end

  def representative_transition_dispose_panels_v10537
    (@rep_transition_panels_v10537 || []).each{|p|p.dispose if p!=nil}
    @rep_transition_panels_v10537=[]
  rescue
  end

  def representative_transition_dispose_all_v10537
    representative_transition_dispose_panels_v10537
    s=@rep_transition_overlay_v10537
    if s!=nil
      begin;s.bitmap.dispose if s.bitmap!=nil && !s.bitmap.disposed?;rescue;end
      begin;s.dispose unless s.disposed?;rescue;end
    end
    @rep_transition_overlay_v10537=nil
    @rep_transition_active_v10537=false
    @rep_transition_loading_v10537=false
  rescue
  end

  def representative_transition_start_v10537
    return false unless representative_transition_ready_v10537?
    @rep_transition_active_v10537=true
    @rep_transition_loading_v10537=true
    @rep_transition_load_index_v10537=0
    @rep_transition_assets_v10537=PMD_AC.representative_visual_asset_rows_v10534
    @rep_transition_page_v10537=0
    @rep_transition_sequence_v10537=0
    @rep_transition_frame_v10537=0
    @rep_transition_action_window_v10537=PMD_AC::REPRESENTATIVE_TRANSITION_ACTION_MIN_V10537
    @rep_transition_stage_v10537=:pre_neutral
    @rep_transition_panels_v10537=[]
    @rep_transition_marks_v10537={}
    @rep_transition_pages_seen_v10537={}
    @rep_transition_species_seen_v10537={}
    @rep_transition_sequences_seen_v10537={}
    @rep_transition_runs_v10537=@rep_transition_runs_v10537.to_i+1
    @rep_transition_request_v10537=false
    representative_transition_create_overlay_v10537
    log_event(:battle,'BATTLE_REPRESENTATIVE_TRANSITION_V10537 START input=SHIFT+F7 reps=56 pages=14'+
      ' sequences=5 single_shot_action=1 end_hold='+PMD_AC::REPRESENTATIVE_TRANSITION_END_HOLD_V10537.to_s+
      ' stable_species_scale=1 two_diagonals=1 combat_step_paused=1 preview_sprite_isolated=1'+
      ' performance_capture_paused=1 manual_visual_judgement_required=1')
    representative_transition_draw_header_v10537
    true
  rescue
    @rep_transition_active_v10537=false
    representative_transition_dispose_all_v10537
    false
  end

  def representative_transition_prewarm_v10537
    rows=@rep_transition_assets_v10537 || []
    n=PMD_AC::REPRESENTATIVE_TRANSITION_PREWARM_PER_FRAME_V10537
    n=1 if n<=0
    n.times do
      break if @rep_transition_load_index_v10537.to_i>=rows.size
      row=rows[@rep_transition_load_index_v10537.to_i]
      PMD_AC.representative_visual_bitmap_v10534(row[0],row[1])
      @rep_transition_load_index_v10537=@rep_transition_load_index_v10537.to_i+1
    end
    done=@rep_transition_load_index_v10537.to_i
    if done>=rows.size
      @rep_transition_loading_v10537=false
      log_event(:battle,'BATTLE_REPRESENTATIVE_TRANSITION_PREWARM_V10537 ready=1 assets='+rows.size.to_s+'/'+rows.size.to_s+
        ' per_frame='+n.to_s+' formal_perf_capture_paused=1')
      representative_transition_build_page_v10537
    else
      representative_transition_draw_header_v10537
    end
  rescue
    representative_transition_finish_v10537(false,'prewarm_exception')
  end

  def representative_transition_build_page_v10537
    representative_transition_dispose_panels_v10537
    pages=PMD_AC.representative_visual_pages_v10534
    pi=@rep_transition_page_v10537.to_i
    return representative_transition_finish_v10537(true,'complete') if pi>=pages.size
    row=pages[pi];body=row[0];sids=row[1]
    top=50;bottom=25;gap=4;cols=2;rows=2
    pw=(Graphics.width-gap*(cols+1))/cols
    ph=(Graphics.height-top-bottom-gap*(rows+1))/rows
    sids.each_with_index do |sid,i|
      c=i%cols;r=i/cols;x=gap+c*(pw+gap);y=top+gap+r*(ph+gap)
      p=Sprite_PMDRepresentativeTransitionPanelV10537.new(@viewport,x,y,pw,ph,sid,body,pi*4+i+1,56)
      @rep_transition_panels_v10537.push(p)
      @rep_transition_species_seen_v10537[sid.to_s]=true
    end
    @rep_transition_pages_seen_v10537[pi]=true
    representative_transition_apply_sequence_v10537
  rescue
    representative_transition_finish_v10537(false,'page_exception')
  end

  def representative_transition_apply_sequence_v10537
    pages=PMD_AC.representative_visual_pages_v10534
    pi=@rep_transition_page_v10537.to_i
    return if pi<0 || pi>=pages.size
    body=pages[pi][0];sids=pages[pi][1]
    seq=PMD_AC::REPRESENTATIVE_TRANSITION_SEQUENCES_V10537[@rep_transition_sequence_v10537.to_i] || :attack
    rows=PMD_AC.representative_transition_sequence_rows_v10537(body,sids,seq)
    maxdur=PMD_AC::REPRESENTATIVE_TRANSITION_ACTION_MIN_V10537
    rows.each{|q|maxdur=q[:duration].to_i if q[:duration].to_i>maxdur}
    maxdur=PMD_AC::REPRESENTATIVE_TRANSITION_ACTION_MAX_V10537 if maxdur>PMD_AC::REPRESENTATIVE_TRANSITION_ACTION_MAX_V10537
    @rep_transition_action_window_v10537=maxdur
    @rep_transition_frame_v10537=0
    @rep_transition_stage_v10537=:pre_neutral
    (@rep_transition_panels_v10537 || []).each{|p|p.set_neutral_v10537 if p!=nil}
    key=pi.to_s+':'+seq.to_s
    @rep_transition_sequences_seen_v10537[key]=true
    poses=[]
    rows.each do |q|
      flags=':fb'+(q[:info][:fallback] ? '1':'0')+':nat'+(q[:info][:native] ? '1':'0')
      poses.push(q[:sid]+':' +(q[:pose]==nil ? 'nil' : q[:pose].to_s)+':'+q[:duration].to_i.to_s+'f'+flags)
    end
    log_event(:battle,'BATTLE_REPRESENTATIVE_TRANSITION_SEQUENCE_V10537 page='+(pi+1).to_s+'/14 body='+body.to_s+
      ' sequence='+seq.to_s+' species=['+sids.join(',')+'] action_window='+maxdur.to_s+
      ' poses=['+poses.join(',')+'] flow=neutral>single_shot>end_hold>neutral')
    representative_transition_draw_header_v10537
  rescue
    representative_transition_finish_v10537(false,'sequence_exception')
  end

  def representative_transition_begin_action_v10537
    pages=PMD_AC.representative_visual_pages_v10534
    pi=@rep_transition_page_v10537.to_i
    return if pi<0 || pi>=pages.size
    body=pages[pi][0];sids=pages[pi][1]
    seq=PMD_AC::REPRESENTATIVE_TRANSITION_SEQUENCES_V10537[@rep_transition_sequence_v10537.to_i] || :attack
    rows=PMD_AC.representative_transition_sequence_rows_v10537(body,sids,seq)
    (@rep_transition_panels_v10537 || []).each_with_index do |p,i|
      p.set_action_v10537(rows[i][:info]) if p!=nil && rows[i]!=nil
    end
    @rep_transition_stage_v10537=:action
    representative_transition_draw_header_v10537
  rescue
  end

  def representative_transition_begin_post_v10537
    (@rep_transition_panels_v10537 || []).each{|p|p.set_neutral_v10537 if p!=nil}
    @rep_transition_stage_v10537=:post_neutral
    representative_transition_draw_header_v10537
  rescue
  end

  def representative_transition_next_sequence_v10537
    @rep_transition_sequence_v10537=@rep_transition_sequence_v10537.to_i+1
    if @rep_transition_sequence_v10537>=PMD_AC::REPRESENTATIVE_TRANSITION_SEQUENCES_V10537.size
      @rep_transition_sequence_v10537=0
      @rep_transition_page_v10537=@rep_transition_page_v10537.to_i+1
      pages=PMD_AC.representative_visual_pages_v10534
      if @rep_transition_page_v10537>=pages.size
        representative_transition_finish_v10537(true,'complete')
        return
      end
      representative_transition_build_page_v10537
    else
      representative_transition_apply_sequence_v10537
    end
  rescue
    representative_transition_finish_v10537(false,'next_sequence_exception')
  end

  def representative_transition_change_page_v10537(delta)
    pages=PMD_AC.representative_visual_pages_v10534
    return if pages.empty?
    @rep_transition_page_v10537=(@rep_transition_page_v10537.to_i+delta.to_i)%pages.size
    @rep_transition_sequence_v10537=0
    representative_transition_build_page_v10537
  rescue
  end

  def representative_transition_change_group_v10537(delta)
    pages=PMD_AC.representative_visual_pages_v10534
    return if pages.empty?
    group=@rep_transition_page_v10537.to_i/2
    group=(group+delta.to_i)%PMD_AC::REPRESENTATIVE_VISUAL_BODY_ORDER_V10534.size
    @rep_transition_page_v10537=group*2
    @rep_transition_sequence_v10537=0
    representative_transition_build_page_v10537
  rescue
  end

  def representative_transition_current_finding_v10537
    pages=PMD_AC.representative_visual_pages_v10534
    pi=@rep_transition_page_v10537.to_i
    return nil if pages==nil || pi<0 || pi>=pages.size
    row=pages[pi];body=row[0];sids=row[1]
    seq=PMD_AC::REPRESENTATIVE_TRANSITION_SEQUENCES_V10537[@rep_transition_sequence_v10537.to_i] || :attack
    rows=PMD_AC.representative_transition_sequence_rows_v10537(body,sids,seq)
    poses=[]
    rows.each{|q|poses.push(q[:sid]+':' +(q[:pose]==nil ? 'nil' : q[:pose].to_s)+':'+q[:duration].to_i.to_s+'f')}
    {:key=>pi.to_s+':'+seq.to_s,:page=>pi,:body=>body,:sequence=>seq,:species=>sids,:poses=>poses}
  rescue
    nil
  end

  def representative_transition_toggle_mark_v10537
    row=representative_transition_current_finding_v10537
    return if row==nil
    @rep_transition_marks_v10537={} if @rep_transition_marks_v10537==nil
    if @rep_transition_marks_v10537[row[:key]]
      @rep_transition_marks_v10537.delete(row[:key]);action='unmark'
      begin;Sound.play_cancel;rescue;end
    else
      @rep_transition_marks_v10537[row[:key]]=row;action='mark'
      begin;Sound.play_decision;rescue;end
    end
    log_event(:battle,'BATTLE_REPRESENTATIVE_TRANSITION_FINDING_V10537 action='+action+
      ' page='+(row[:page].to_i+1).to_s+'/14 body='+row[:body].to_s+' sequence='+row[:sequence].to_s+
      ' species=['+row[:species].join(',')+'] poses=['+row[:poses].join(',')+']'+
      ' marks_now='+@rep_transition_marks_v10537.size.to_s)
    representative_transition_draw_header_v10537
  rescue
  end

  def representative_transition_findings_text_v10537
    rows=(@rep_transition_marks_v10537 || {}).values
    out=[]
    rows.sort_by{|r|[r[:page].to_i,r[:sequence].to_s]}.each do |r|
      out.push('p'+(r[:page].to_i+1).to_s+':'+r[:body].to_s+':'+r[:sequence].to_s+'=['+r[:species].join(',')+']')
    end
    out
  rescue
    []
  end

  def representative_transition_finish_v10537(ok,reason)
    return false unless representative_transition_active_v10537?
    marks=representative_transition_findings_text_v10537
    representative_transition_dispose_panels_v10537
    s=@rep_transition_overlay_v10537
    if s!=nil
      begin;s.bitmap.dispose if s.bitmap!=nil && !s.bitmap.disposed?;rescue;end
      begin;s.dispose unless s.disposed?;rescue;end
    end
    @rep_transition_overlay_v10537=nil
    @rep_transition_active_v10537=false
    @rep_transition_loading_v10537=false
    pages_seen=(@rep_transition_pages_seen_v10537 || {}).size
    species_seen=(@rep_transition_species_seen_v10537 || {}).size
    sequences_seen=(@rep_transition_sequences_seen_v10537 || {}).size
    structural=(pages_seen==14 && species_seen==56 && sequences_seen==70)
    fixture_pass=ok && structural
    visual_pass=fixture_pass && marks.empty?
    @rep_transition_completes_v10537=@rep_transition_completes_v10537.to_i+1 if fixture_pass
    begin
      @motion_perf_prev_update_time_v1023=Time.now.to_f
      @motion_perf_capture_last_time_v1023=Time.now if @motion_perf_capture_last_time_v1023!=nil
    rescue
    end
    log_event(:battle,'BATTLE_REPRESENTATIVE_TRANSITION_COMPLETE_V10537 fixture_pass='+(fixture_pass ? '1':'0')+
      ' visual_pass='+(visual_pass ? '1':'0')+' reason='+reason.to_s+
      ' pages_seen='+pages_seen.to_s+'/14 species_seen='+species_seen.to_s+'/56 sequence_views='+sequences_seen.to_s+'/70'+
      ' marks='+marks.size.to_s+' findings=['+marks.join('|')+'] single_shot=1 stable_species_scale=1'+
      ' sandshrew_head_guard_retained=1 combat_step_resumed=1 performance_capture_resumed=1'+
      ' next_gate='+(visual_pass ? 'important_species_manual_qa':'focused_transition_review')+
      ' gameplay_change=0')
    visual_pass
  rescue
    false
  end

  def representative_transition_update_v10537
    return unless representative_transition_active_v10537?
    if @rep_transition_loading_v10537
      representative_transition_prewarm_v10537
      return
    end
    (@rep_transition_panels_v10537 || []).each{|p|p.update if p!=nil}
    @rep_transition_frame_v10537=@rep_transition_frame_v10537.to_i+1
    pre=PMD_AC::REPRESENTATIVE_TRANSITION_PRE_FRAMES_V10537
    aw=@rep_transition_action_window_v10537.to_i
    hold=PMD_AC::REPRESENTATIVE_TRANSITION_END_HOLD_V10537
    post=PMD_AC::REPRESENTATIVE_TRANSITION_POST_FRAMES_V10537
    f=@rep_transition_frame_v10537.to_i
    if f==pre
      representative_transition_begin_action_v10537
    elsif f==pre+aw
      @rep_transition_stage_v10537=:end_hold
      representative_transition_draw_header_v10537
    elsif f==pre+aw+hold
      representative_transition_begin_post_v10537
    elsif f>=pre+aw+hold+post
      representative_transition_next_sequence_v10537
    end
  rescue
    representative_transition_finish_v10537(false,'update_exception')
  end

  def representative_transition_input_v10537
    if Input.trigger?(Input::B)
      begin;Sound.play_cancel;rescue;end
      representative_transition_finish_v10537(false,'manual_exit')
    elsif Input.trigger?(Input::F8)
      representative_transition_toggle_mark_v10537
    elsif Input.trigger?(Input::RIGHT)
      begin;Sound.play_cursor;rescue;end
      representative_transition_change_page_v10537(1)
    elsif Input.trigger?(Input::LEFT)
      begin;Sound.play_cursor;rescue;end
      representative_transition_change_page_v10537(-1)
    elsif Input.trigger?(Input::DOWN)
      begin;Sound.play_cursor;rescue;end
      representative_transition_change_group_v10537(1)
    elsif Input.trigger?(Input::UP)
      begin;Sound.play_cursor;rescue;end
      representative_transition_change_group_v10537(-1)
    elsif Input.trigger?(Input::C)
      begin;Sound.play_decision;rescue;end
      representative_transition_next_sequence_v10537
    end
  rescue
  end

  def update_battle_input
    if representative_transition_active_v10537?
      representative_transition_input_v10537
      return
    end
    if @phase==:battle && respond_to?(:verification_mode) && verification_mode==:normal &&
       Input.press?(Input::SHIFT) && Input.trigger?(Input::F7)
      @rep_transition_request_v10537=true
      if representative_transition_ready_v10537?
        begin;Sound.play_decision;rescue;end
        representative_transition_start_v10537
      else
        begin;Sound.play_cursor;rescue;end
        rs=PMD_AC.representative_route_qa_state_v10528
        log_event(:battle,'BATTLE_REPRESENTATIVE_TRANSITION_V10537 REQUEST input=SHIFT+F7 pending_safe_boundary=1'+
          ' route_qa_complete='+(rs!=nil && rs[:complete] ? '1':'0')+
          ' sandshrew_guard='+(PMD_AC.sandshrew_head_guard_last_qa_v10536!=nil && PMD_AC.sandshrew_head_guard_last_qa_v10536[:pass] ? '1':'0'))
      end
      return
    end
    pmd_ac_v10537_transition_update_battle_input
  rescue
    pmd_ac_v10537_transition_update_battle_input
  end

  def update_battle_step
    if representative_transition_active_v10537?
      representative_transition_update_v10537
      return
    end
    r=pmd_ac_v10537_transition_update_battle_step
    if !@rep_transition_ready_logged_v10537 && representative_transition_ready_v10537?
      @rep_transition_ready_logged_v10537=true
      log_event(:battle,'BATTLE_REPRESENTATIVE_TRANSITION_V10537 READY input=SHIFT+F7 reps=56 pages=14 sequences=5'+
        ' transition_views=70 single_shot=1 stable_species_scale=1 F8_mark=1'+
        ' sandshrew_head_guard=1 s_menu_added=0 top_event_feed_added=0')
    end
    if @rep_transition_request_v10537 && representative_transition_ready_v10537?
      representative_transition_start_v10537
    end
    r
  rescue
    pmd_ac_v10537_transition_update_battle_step
  end

  def restart_to_deploy
    representative_transition_finish_v10537(false,'return_deploy') if representative_transition_active_v10537?
    representative_transition_dispose_all_v10537
    pmd_ac_v10537_transition_restart_to_deploy
  end

  def terminate
    representative_transition_dispose_all_v10537
    pmd_ac_v10537_transition_terminate
  end

  def focus_cast_log_summary_v1055
    r=pmd_ac_v10537_transition_focus_summary
    return r if respond_to?(:production_external_battle_fast_v10613?) && production_external_battle_fast_v10613?
    begin
      marks=representative_transition_findings_text_v10537
      q=@rep_transition_audit_v10537 || {}
      log_event(:battle,'BATTLE_REPRESENTATIVE_TRANSITION_SUMMARY_V10537 audit_pass='+(q[:pass] ? '1':'0')+
        ' runs='+@rep_transition_runs_v10537.to_i.to_s+' completes='+@rep_transition_completes_v10537.to_i.to_s+
        ' marks='+marks.size.to_s+' findings=['+marks.join('|')+'] input=SHIFT+F7'+
        ' next_gate='+((@rep_transition_completes_v10537.to_i>0 && marks.empty?) ? 'important_species_manual_qa':'run_transition_fixture')+
        ' sandshrew_head_guard_retained=1 gameplay_change=0')
    rescue
    end
    r
  end
end
