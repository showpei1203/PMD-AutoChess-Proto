# encoding: UTF-8
#===============================================================================
# ■ PMD AutoChess - Transition Audit Incremental Seal + Important Species
#   Manual QA I v1.05.38
#===============================================================================
# 【用途】
# 1. 承接 v1.05.37 Windows 實機結果：Representative Transition Continuity Fixture
#    已完整跑完 14/14 pages、56/56 species、70/70 sequence views，F8 marks=0，
#    visual_pass=1；因此「代表物種 Neutral → Action → Recovery」人工視覺 Gate PASS。
# 2. 修正 v1.05.37 structural audit 的冷啟動效能問題：第一場在 cache 尚未暖起來時，
#    同一 frame 同步掃 280 slots 花 112ms，超過正式 50ms threshold；第二場 cache 熱後
#    同一 audit 僅 10ms。這是 QA/verifier scheduling 問題，不是 Motion regression。
# 3. v1.05.38 不再在 start_battle 同步掃 280 slots，而是在 896-route QA 完成後，以
#    8 slots / frame 分幀驗證。正式 PASS 依「單幀 max_tick_ms <= 50」判定，總耗時不拿來
#    偷換門檻。
# 4. Representative Transition PASS 後，新增 Important Species Manual QA I：從目前已實際
#    匯入的 56 representative assets 中，挑出 generated profile 原本標記 important=true 的
#    16 隻高辨識度物種，做 10 個 identity-stress family 的單次動作人工 QA。
# 5. Important fixture 仍採 stable neutral scale、左右 45°、single-shot action、end hold、
#    Neutral recovery，並支援 F8 標記 page+family 疑點。
#
# 【v1.05.37 Windows 證據】
# - 第一場 structural audit：pages=14/14, views=70/70, species=56/56,
#   playable=280/280, sandshrew_head_selected=0，但 qa_ms=112，故 pass=0。
# - 第二場 structural audit：同樣 280/280，qa_ms=10，pass=1。
# - Transition Fixture：fixture_pass=1, visual_pass=1, pages_seen=14/14,
#   species_seen=56/56, sequence_views=70/70, marks=0。
# - Representative Route QA 仍為 896/896 PASS，max_tick_ms=9。
# 因此本版只修 audit scheduling，不改任何已 PASS Motion routing。
#
# 【主要設定】
# TRANSITION_AUDIT_PER_TICK_V10538 = 8
#   v1.05.37 的 280-slot structural audit 每 frame 最多處理 8 slots。
# TRANSITION_AUDIT_THRESHOLD_MS_V10538 = 50
#   單一 audit tick 仍必須 <= 50ms；不可放寬。
# IMPORTANT_MANUAL_SPECIES_V10538
#   16 隻「目前 56 representative 中 generated profile important=true」的物種：
#   0031 尼多后、0059 風速狗、0095 大岩蛇、0144 急凍鳥、0151 夢幻、0244 炎帝、
#   0330 沙漠蜻蜓、0350 美納斯、0380 拉帝亞斯、0384 烈空坐、0426 隨風球、
#   0468 波克基斯、0491 達克萊伊、0492 謝米、0493 阿爾宙斯、0494 比克提尼。
# IMPORTANT_MANUAL_FAMILIES_V10538
#   [:strike,:dash,:lunge,:head,:bite,:spin,:tail,:cast,:shock,:sound]
# IMPORTANT_AUDIT_PER_TICK_V10538 = 8
#   Important 16×10=160 route slots 同樣分幀 audit。
# IMPORTANT_PRE_FRAMES_V10538 = 18
# IMPORTANT_END_HOLD_V10538 = 6
# IMPORTANT_POST_FRAMES_V10538 = 24
# IMPORTANT_PREWARM_PER_FRAME_V10538 = 3
#
# 【機制規則】
# - Frozen Motion Combat Core 不直接修改；本版只做 trailing QA / scheduling / preview。
# - v1.05.36 Sandshrew Head component guard 完整保留，0027/0028 不得回到 standalone Head。
# - v1.05.28～33 Group Tuning I～V 完整保留，不重排已 Windows PASS 的 candidate priority。
# - v1.05.37 Transition Fixture 本身保留；只把 structural audit 從「battle start 同步掃」
#   改為「route QA 完成後分幀掃」。
# - Important fixture 使用正式 motion_source_route_v102 的結果，不建立展示專用假 pose。
# - Preview 為獨立 Sprite；不修改正式 Combat unit bitmap / zoom / logical x/y。
# - Stable scale 沿用 v1.05.35 neutral-reference authority，同一 species 所有 action 共用比例。
# - Action 單次播放，不 loop；較短 action 會停最後 frame，等同頁最長 action 完成後一起 recovery。
# - Fixture active 時 battle step 與正式 Performance capture 暫停，離開後重建 wall-time boundary。
# - 不修改 Damage Formula、HP authority、AI、Energy、Attack Wait、Priority、hit timing。
# - 不修改 logical Spatial x/y、velocity、dash/lunge endpoint、push/pull/through。
# - HOME 仍為 current logical/action anchor。
# - Important Manual QA I 只是目前「已匯入 56 隻」中的 16 隻 important subset；
#   它不是 0027～0494 全部 important species 的最終驗收。若 PASS，下一 gate 是擴張
#   generated runtime assets，再做更完整的重要物種 / evolution line 人工 QA。
#
# 【操作方式】
# - NORMAL battle：
#   SHIFT + F7：v1.05.37 Transition Continuity Fixture（保留）。
#   F9：v1.05.36 Sandshrew focused review（保留）。
#   SHIFT + F9：啟動 Important Species Manual QA I。
# - 若 route QA / incremental audit 尚未完成，SHIFT+F9 會記住 request，安全邊界後自動啟動。
# - Important fixture 中：
#   F8      標記 / 取消目前 page + family 疑點
#   C       下一 family
#   ← / →   上一頁 / 下一頁
#   B / Esc 提早離開
#
# 【LOG】
# BATTLE_REPRESENTATIVE_TRANSITION_AUDIT_INCREMENTAL_V10538 START / COMPLETE
# BATTLE_REPRESENTATIVE_TRANSITION_AUDIT_V10537 ...  （compatibility final line）
# BATTLE_IMPORTANT_SPECIES_AUDIT_V10538 START / COMPLETE
# BATTLE_IMPORTANT_SPECIES_MANUAL_QA_V10538 READY / REQUEST / START
# BATTLE_IMPORTANT_SPECIES_SEQUENCE_V10538 ...
# BATTLE_IMPORTANT_SPECIES_FINDING_V10538 ...
# BATTLE_IMPORTANT_SPECIES_COMPLETE_V10538 ...
# BATTLE_IMPORTANT_SPECIES_SUMMARY_V10538 ...
#
# 【實際範例】
# - SHIFT+F9 後 Page 1 會同時顯示 #0031 尼多后、#0059 風速狗、#0095 大岩蛇、
#   #0144 急凍鳥。每個 family 都會先 Neutral，再播一次 routed action，最後回 Neutral。
# - 若大岩蛇的 HEAD family 看起來只是頭部零件、或急凍鳥從 LUNGE 回 Neutral 時身體
#   突然跳高，直接按 F8；LOG 會保存該頁四隻物種、family、selected pose 與 duration。
#===============================================================================
$imported={} unless defined?($imported)
$imported['PMD_AutoChess_TransitionAuditIncremental_ImportantSpeciesManualQAI_v10538']=true

module PMD_AC
  TRANSITION_AUDIT_PER_TICK_V10538=8
  TRANSITION_AUDIT_THRESHOLD_MS_V10538=50

  IMPORTANT_MANUAL_SPECIES_V10538=%w(0031 0059 0095 0144 0151 0244 0330 0350 0380 0384 0426 0468 0491 0492 0493 0494)
  IMPORTANT_MANUAL_NAMES_V10538={
    '0031'=>'尼多后','0059'=>'風速狗','0095'=>'大岩蛇','0144'=>'急凍鳥',
    '0151'=>'夢幻','0244'=>'炎帝','0330'=>'沙漠蜻蜓','0350'=>'美納斯',
    '0380'=>'拉帝亞斯','0384'=>'烈空坐','0426'=>'隨風球','0468'=>'波克基斯',
    '0491'=>'達克萊伊','0492'=>'謝米','0493'=>'阿爾宙斯','0494'=>'比克提尼'
  }
  IMPORTANT_MANUAL_FAMILIES_V10538=[:strike,:dash,:lunge,:head,:bite,:spin,:tail,:cast,:shock,:sound]
  IMPORTANT_AUDIT_PER_TICK_V10538=8
  IMPORTANT_AUDIT_THRESHOLD_MS_V10538=50
  IMPORTANT_PRE_FRAMES_V10538=18
  IMPORTANT_END_HOLD_V10538=6
  IMPORTANT_POST_FRAMES_V10538=24
  IMPORTANT_PREWARM_PER_FRAME_V10538=3

  class << self
    def important_manual_name_v10538(sid)
      IMPORTANT_MANUAL_NAMES_V10538[sid.to_s] || sid.to_s
    rescue
      sid.to_s
    end

    def important_manual_body_v10538(sid)
      p=motion_generated_profile_v1040(sid.to_s)
      return p[:body] if p!=nil && p[:body]!=nil
      REPRESENTATIVE_VISUAL_BODY_ORDER_V10534.each do |body|
        rows=representative_reps_by_body_v10527[body] || []
        return body if rows.include?(sid.to_s)
      end
      :medium
    rescue
      :medium
    end

    def important_manual_pages_v10538
      a=IMPORTANT_MANUAL_SPECIES_V10538
      [[a[0],a[1],a[2],a[3]],[a[4],a[5],a[6],a[7]],
       [a[8],a[9],a[10],a[11]],[a[12],a[13],a[14],a[15]]]
    rescue
      []
    end

    def important_manual_route_info_v10538(sid,family)
      representative_visual_route_info_v10534(sid.to_s,family)
    rescue
      {:family=>family,:pose=>nil,:fallback=>false,:native=>false,:playable=>false}
    end

    def important_manual_action_info_v10538(sid,family)
      q=important_manual_route_info_v10538(sid,family)
      q=q.clone
      q[:phase]=family
      q[:label]=family.to_s.upcase
      q
    rescue
      {:phase=>family,:family=>family,:pose=>nil,:fallback=>false,:native=>false,:playable=>false,:label=>family.to_s.upcase}
    end

    def important_manual_action_duration_v10538(sid,pose)
      representative_transition_pose_duration_v10537(sid.to_s,pose)
    rescue
      REPRESENTATIVE_TRANSITION_ACTION_MIN_V10537
    end

    def important_manual_asset_rows_v10538
      out=[];seen={}
      IMPORTANT_MANUAL_SPECIES_V10538.each do |sid|
        body=important_manual_body_v10538(sid)
        neutral=representative_visual_neutral_pose_v10534(sid,body)
        poses=[neutral]
        IMPORTANT_MANUAL_FAMILIES_V10538.each do |fam|
          q=important_manual_route_info_v10538(sid,fam)
          poses.push(q[:pose]) if q!=nil
        end
        poses.each do |pose|
          next if pose==nil
          key=sid+':'+pose.to_s
          next if seen[key]
          seen[key]=true
          out.push([sid,pose])
        end
      end
      out
    rescue
      []
    end
  end
end

#===============================================================================
# ■ Important Species Preview Panel
#===============================================================================
class Sprite_PMDImportantSpeciesPanelV10538 < Sprite_PMDRepresentativeTransitionPanelV10537
  def initialize(viewport,x,y,w,h,sid,index,total)
    @important_name_v10538=PMD_AC.important_manual_name_v10538(sid)
    body=PMD_AC.important_manual_body_v10538(sid)
    super(viewport,x,y,w,h,sid,body,index,total)
  end

  def redraw_panel_v10534
    b=@panel.bitmap;b.clear
    b.fill_rect(0,0,@w,@h,Color.new(8,12,18,235))
    b.fill_rect(1,1,@w-2,@h-2,Color.new(34,43,55,225))
    font=PMD_AC.const_defined?(:UI_PANEL_FONT_V0741) ? PMD_AC::UI_PANEL_FONT_V0741 : ['Microsoft JhengHei']
    b.font.name=font;b.font.size=15;b.font.bold=true;b.font.color=Color.new(255,255,255)
    b.draw_text(6,2,@w-12,22,'#'+@sid+' '+@important_name_v10538+'  '+@body.to_s.upcase,0)
    pose=@info==nil || @info[:pose]==nil ? 'nil' : @info[:pose].to_s
    label=@info==nil ? @phase.to_s.upcase : @info[:label].to_s
    flags=''
    if @info!=nil && @info[:family]!=:neutral
      flags='  '+(@info[:fallback] ? 'FALLBACK' : 'DIRECT')+' / '+(@info[:native] ? 'NATIVE' : 'ROUTED')
    end
    b.font.size=13;b.font.bold=false;b.font.color=Color.new(210,225,240)
    b.draw_text(6,24,@w-12,20,label+' -> '+pose+flags,0)
    if @bitmap==nil || @data==nil
      b.font.size=18;b.font.bold=true;b.font.color=Color.new(255,150,150)
      b.draw_text(4,62,@w-8,28,'NO PLAYABLE PREVIEW',1)
    end
    b.font.size=12;b.font.bold=false;b.font.color=Color.new(165,205,255)
    b.draw_text(4,@h-20,@w/2-6,18,'RIGHT 45',1)
    b.draw_text(@w/2+2,@h-20,@w/2-6,18,'LEFT 45',1)
  rescue
  end
end

#===============================================================================
# ■ Scene_PMD_AutoChess
#   A. 取代 v1.05.37 battle-start 同步 280-slot audit，改成 incremental。
#   B. SHIFT+F9 Important Species Manual QA I。
#===============================================================================
class Scene_PMD_AutoChess
  alias pmd_ac_v10538_update_battle_input update_battle_input unless method_defined?(:pmd_ac_v10538_update_battle_input)
  alias pmd_ac_v10538_update_battle_step update_battle_step unless method_defined?(:pmd_ac_v10538_update_battle_step)
  alias pmd_ac_v10538_motion_perf_capture_active_v1023 motion_perf_capture_active_v1023? unless method_defined?(:pmd_ac_v10538_motion_perf_capture_active_v1023)
  alias pmd_ac_v10538_restart_to_deploy restart_to_deploy unless method_defined?(:pmd_ac_v10538_restart_to_deploy)
  alias pmd_ac_v10538_terminate terminate unless method_defined?(:pmd_ac_v10538_terminate)
  alias pmd_ac_v10538_focus_summary focus_cast_log_summary_v1055 unless method_defined?(:pmd_ac_v10538_focus_summary)

  #--------------------------------------------------------------------------
  # start_battle：直接呼叫 v1.05.37 保存的「前一版 start_battle」alias，
  # 避免執行 v1.05.37 自己那段同步 structural audit。
  #--------------------------------------------------------------------------
  def start_battle
    # 先完整執行 v1.05.36 以前的 start_battle chain；刻意繞過 v1.05.37
    # 自己那段同步 280-slot audit。後續 QA 狀態再由本版初始化。
    pmd_ac_v10537_transition_start_battle

    @rep_transition_active_v10537=false
    @rep_transition_loading_v10537=false
    @rep_transition_request_v10537=false
    @rep_transition_ready_logged_v10537=false
    @rep_transition_runs_v10537=0
    @rep_transition_completes_v10537=0
    @rep_transition_marks_v10537={}
    @rep_transition_panels_v10537=[]

    @rep_transition_audit_v10537={:pass=>false,:pages=>14,:views=>70,:species=>56,
      :playable=>0,:expected_slots=>280,:head_guard=>0,:bad=>[],:ms=>0,:pending=>true}
    @rep_transition_audit_state_v10538=nil

    @important_active_v10538=false
    @important_loading_v10538=false
    @important_request_v10538=false
    @important_ready_logged_v10538=false
    @important_runs_v10538=0
    @important_completes_v10538=0
    @important_marks_v10538={}
    @important_panels_v10538=[]
    @important_audit_state_v10538=nil
    @important_audit_result_v10538=nil

    if respond_to?(:production_external_battle_fast_v10613?) && production_external_battle_fast_v10613?
      @rep_transition_audit_v10537={:pass=>true,:pages=>14,:views=>70,:species=>56,
        :playable=>280,:expected_slots=>280,:head_guard=>0,:bad=>[],:ms=>0,:pending=>false,
        :source=>:sealed_production_fast_v10613}
      @important_audit_result_v10538={:pass=>true,:species=>16,:families=>10,:slots=>160,
        :playable=>160,:fallback=>104,:native=>56,:attack=>33,:bad=>[],:ms=>0,
        :source=>:sealed_production_fast_v10613}
      @rep_transition_audit_state_v10538=nil
      @important_audit_state_v10538=nil
      return true
    end

    representative_transition_audit_prepare_v10538
    important_species_audit_prepare_v10538
  rescue
    # 不重複呼叫 start_battle chain；若 QA 初始化失敗，只讓 QA gate 留在 pending。
    @rep_transition_audit_v10537={:pass=>false,:pages=>0,:views=>0,:species=>0,
      :playable=>0,:expected_slots=>280,:head_guard=>-1,:bad=>['v10538_start_exception'],:ms=>0,:pending=>true}
  end

  #--------------------------------------------------------------------------
  # Transition structural audit incremental seal
  #--------------------------------------------------------------------------
  def representative_transition_audit_prepare_v10538
    queue=[]
    pages=PMD_AC.representative_visual_pages_v10534
    pages.each do |row|
      body=row[0]
      row[1].each do |sid|
        PMD_AC::REPRESENTATIVE_TRANSITION_SEQUENCES_V10537.each do |seq|
          queue.push([body,sid.to_s,seq])
        end
      end
    end
    @rep_transition_audit_state_v10538={:queue=>queue,:index=>0,:playable=>0,
      :head=>0,:bad=>[],:seen=>{},:ticks=>0,:max_tick=>0,:total_ms=>0,
      :started=>false,:complete=>false,:over=>0}
  rescue
    @rep_transition_audit_state_v10538={:queue=>[],:index=>0,:playable=>0,
      :head=>0,:bad=>['prepare_exception'],:seen=>{},:ticks=>0,:max_tick=>0,:total_ms=>0,
      :started=>false,:complete=>true,:over=>0}
  end

  def representative_transition_audit_tick_v10538
    st=@rep_transition_audit_state_v10538
    return if st==nil || st[:complete]
    rs=PMD_AC.representative_route_qa_state_v10528
    return if rs==nil || !rs[:complete] || !rs[:pass] || !(rs[:tuning] || []).empty?
    sq=PMD_AC.sandshrew_head_guard_last_qa_v10536
    return if sq==nil || !sq[:pass] || sq[:head_selected].to_i!=0
    unless st[:started]
      st[:started]=true
      log_event(:battle,'BATTLE_REPRESENTATIVE_TRANSITION_AUDIT_INCREMENTAL_V10538 START slots='+st[:queue].size.to_s+
        ' per_tick='+PMD_AC::TRANSITION_AUDIT_PER_TICK_V10538.to_s+
        ' threshold_ms='+PMD_AC::TRANSITION_AUDIT_THRESHOLD_MS_V10538.to_s+
        ' after_route_qa=1 cold_start_sync_scan_retired=1')
    end
    t0=Time.now
    n=PMD_AC::TRANSITION_AUDIT_PER_TICK_V10538
    n.times do
      break if st[:index]>=st[:queue].size
      row=st[:queue][st[:index]];body=row[0];sid=row[1];seq=row[2]
      info=PMD_AC.representative_transition_action_info_v10537(sid,body,seq)
      st[:seen][sid]=true
      if info!=nil && info[:playable]
        st[:playable]+=1
      elsif st[:bad].size<16
        st[:bad].push(sid+':'+seq.to_s+'=unplayable')
      end
      if ['0027','0028'].include?(sid) && info!=nil && info[:pose]==:head
        st[:head]+=1
        st[:bad].push(sid+':'+seq.to_s+'=head') if st[:bad].size<16
      end
      st[:index]+=1
    end
    ms=((Time.now-t0)*1000.0).round
    st[:ticks]+=1;st[:total_ms]+=ms
    st[:max_tick]=ms if ms>st[:max_tick]
    st[:over]+=1 if ms>PMD_AC::TRANSITION_AUDIT_THRESHOLD_MS_V10538
    return if st[:index]<st[:queue].size

    st[:complete]=true
    pages=PMD_AC.representative_visual_pages_v10534.size
    views=pages*PMD_AC::REPRESENTATIVE_TRANSITION_SEQUENCES_V10537.size
    species=st[:seen].size
    expected=56*PMD_AC::REPRESENTATIVE_TRANSITION_SEQUENCES_V10537.size
    pass=(pages==14 && views==70 && species==56 && st[:playable]==expected &&
      st[:head]==0 && st[:bad].empty? && st[:over]==0 &&
      st[:max_tick]<=PMD_AC::TRANSITION_AUDIT_THRESHOLD_MS_V10538)
    q={:pass=>pass,:pages=>pages,:views=>views,:species=>species,:playable=>st[:playable],
      :expected_slots=>expected,:head_guard=>st[:head],:bad=>st[:bad],:ms=>st[:max_tick],
      :pending=>false,:ticks=>st[:ticks],:total_ms=>st[:total_ms],:over=>st[:over]}
    @rep_transition_audit_v10537=q
    begin;@rep_transition_audit_finished_frame_v10538=Graphics.frame_count;rescue;@rep_transition_audit_finished_frame_v10538=-1;end
    log_event(:battle,'BATTLE_REPRESENTATIVE_TRANSITION_AUDIT_INCREMENTAL_V10538 COMPLETE pass='+(pass ? '1':'0')+
      ' slots='+st[:index].to_s+'/'+expected.to_s+' playable='+st[:playable].to_s+'/'+expected.to_s+
      ' species='+species.to_s+'/56 sandshrew_head_selected='+st[:head].to_s+
      ' ticks='+st[:ticks].to_s+' max_tick_ms='+st[:max_tick].to_s+' total_ms='+st[:total_ms].to_s+
      ' over_50ms='+st[:over].to_s+' bad=['+st[:bad].join(',')+']')
    # Compatibility line：保留 v1.05.37 的既有觀察格式，但 qa_ms 代表「最大單 tick」。
    log_event(:battle,'BATTLE_REPRESENTATIVE_TRANSITION_AUDIT_V10537 pass='+(pass ? '1':'0')+
      ' pages='+pages.to_s+'/14 views='+views.to_s+'/70 species='+species.to_s+'/56'+
      ' playable='+st[:playable].to_s+'/'+expected.to_s+' sandshrew_head_selected='+st[:head].to_s+
      ' qa_ms='+st[:max_tick].to_s+' threshold_ms='+PMD_AC::TRANSITION_AUDIT_THRESHOLD_MS_V10538.to_s+
      ' bad=['+st[:bad].join(',')+'] gameplay_change=0 incremental_v10538=1')
  rescue
  end

  #--------------------------------------------------------------------------
  # Important Species 160-slot audit
  #--------------------------------------------------------------------------
  def important_species_audit_prepare_v10538
    queue=[]
    PMD_AC::IMPORTANT_MANUAL_SPECIES_V10538.each do |sid|
      PMD_AC::IMPORTANT_MANUAL_FAMILIES_V10538.each{|fam|queue.push([sid,fam])}
    end
    @important_audit_state_v10538={:queue=>queue,:index=>0,:playable=>0,:fallback=>0,
      :native=>0,:generic_attack=>0,:bad=>[],:ticks=>0,:max_tick=>0,:total_ms=>0,
      :started=>false,:complete=>false,:over=>0,:cache=>{}}
  rescue
    @important_audit_state_v10538={:queue=>[],:index=>0,:playable=>0,:fallback=>0,
      :native=>0,:generic_attack=>0,:bad=>['prepare_exception'],:ticks=>0,:max_tick=>0,:total_ms=>0,
      :started=>false,:complete=>true,:over=>0,:cache=>{}}
  end

  def important_species_audit_tick_v10538
    st=@important_audit_state_v10538
    return if st==nil || st[:complete]
    tq=@rep_transition_audit_v10537
    return if tq==nil || !tq[:pass]
    begin
      return if @rep_transition_audit_finished_frame_v10538==Graphics.frame_count
    rescue
    end
    unless st[:started]
      st[:started]=true
      log_event(:battle,'BATTLE_IMPORTANT_SPECIES_AUDIT_V10538 START species=16 families=10 slots=160'+
        ' per_tick='+PMD_AC::IMPORTANT_AUDIT_PER_TICK_V10538.to_s+
        ' threshold_ms='+PMD_AC::IMPORTANT_AUDIT_THRESHOLD_MS_V10538.to_s+
        ' source=existing_56_representative_important_subset')
    end
    t0=Time.now
    PMD_AC::IMPORTANT_AUDIT_PER_TICK_V10538.times do
      break if st[:index]>=st[:queue].size
      row=st[:queue][st[:index]];sid=row[0];fam=row[1]
      q=PMD_AC.important_manual_action_info_v10538(sid,fam)
      st[:cache][sid+':'+fam.to_s]=q
      st[:playable]+=1 if q[:playable]
      st[:fallback]+=1 if q[:fallback]
      st[:native]+=1 if q[:native]
      st[:generic_attack]+=1 if q[:pose]==:attack
      if !q[:playable] && st[:bad].size<16
        st[:bad].push(sid+':'+fam.to_s+'=unplayable')
      end
      st[:index]+=1
    end
    ms=((Time.now-t0)*1000.0).round
    st[:ticks]+=1;st[:total_ms]+=ms
    st[:max_tick]=ms if ms>st[:max_tick]
    st[:over]+=1 if ms>PMD_AC::IMPORTANT_AUDIT_THRESHOLD_MS_V10538
    return if st[:index]<st[:queue].size
    st[:complete]=true
    pass=(st[:index]==160 && st[:playable]==160 && st[:bad].empty? && st[:over]==0 &&
      st[:max_tick]<=PMD_AC::IMPORTANT_AUDIT_THRESHOLD_MS_V10538)
    @important_audit_result_v10538={:pass=>pass,:slots=>st[:index],:playable=>st[:playable],
      :fallback=>st[:fallback],:native=>st[:native],:generic_attack=>st[:generic_attack],
      :bad=>st[:bad],:ticks=>st[:ticks],:max_tick=>st[:max_tick],:total_ms=>st[:total_ms],
      :over=>st[:over],:cache=>st[:cache]}
    log_event(:battle,'BATTLE_IMPORTANT_SPECIES_AUDIT_V10538 COMPLETE pass='+(pass ? '1':'0')+
      ' species=16/16 families=10/10 slots='+st[:index].to_s+'/160 playable='+st[:playable].to_s+'/160'+
      ' fallback='+st[:fallback].to_s+' selected_native='+st[:native].to_s+
      ' generic_attack='+st[:generic_attack].to_s+' ticks='+st[:ticks].to_s+
      ' max_tick_ms='+st[:max_tick].to_s+' total_ms='+st[:total_ms].to_s+
      ' over_50ms='+st[:over].to_s+' bad=['+st[:bad].join(',')+']')
  rescue
  end

  def important_species_active_v10538?
    @important_active_v10538==true
  end

  def important_species_ready_v10538?
    return false unless @phase==:battle
    return false unless respond_to?(:verification_mode) && verification_mode==:normal
    return false if important_species_active_v10538?
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
    q=@important_audit_result_v10538
    q!=nil && q[:pass]
  rescue
    false
  end

  def motion_perf_capture_active_v1023?
    return false if important_species_active_v10538?
    pmd_ac_v10538_motion_perf_capture_active_v1023
  rescue
    pmd_ac_v10538_motion_perf_capture_active_v1023
  end

  #--------------------------------------------------------------------------
  # Important Species Fixture UI
  #--------------------------------------------------------------------------
  def important_create_overlay_v10538
    return if @important_overlay_v10538!=nil
    @important_overlay_v10538=Sprite.new(@viewport)
    @important_overlay_v10538.bitmap=Bitmap.new(Graphics.width,Graphics.height)
    @important_overlay_v10538.z=16100
  end

  def important_current_stage_v10538
    f=@important_frame_v10538.to_i
    pre=PMD_AC::IMPORTANT_PRE_FRAMES_V10538
    aw=@important_action_window_v10538.to_i
    hold=PMD_AC::IMPORTANT_END_HOLD_V10538
    return :pre_neutral if f<pre
    return :action if f<pre+aw
    return :end_hold if f<pre+aw+hold
    :post_neutral
  rescue
    :pre_neutral
  end

  def important_draw_header_v10538
    important_create_overlay_v10538
    b=@important_overlay_v10538.bitmap;b.clear
    b.fill_rect(0,0,Graphics.width,Graphics.height,Color.new(3,6,10,248))
    font=PMD_AC.const_defined?(:UI_PANEL_FONT_V0741) ? PMD_AC::UI_PANEL_FONT_V0741 : ['Microsoft JhengHei']
    b.font.name=font;b.font.size=19;b.font.bold=true;b.font.color=Color.new(255,255,255)
    b.draw_text(8,3,Graphics.width-16,25,'Important Species Manual QA I  |  Representative Important 16',1)
    pages=PMD_AC.important_manual_pages_v10538
    pi=@important_page_v10538.to_i
    fam=PMD_AC::IMPORTANT_MANUAL_FAMILIES_V10538[@important_family_v10538.to_i] || :strike
    sids=(pages!=nil && pi>=0 && pi<pages.size) ? pages[pi] : []
    names=sids.collect{|sid|'#'+sid+' '+PMD_AC.important_manual_name_v10538(sid)}
    b.font.size=12;b.font.bold=false;b.font.color=Color.new(195,215,235)
    b.draw_text(6,28,Graphics.width-12,18,'Page '+(pi+1).to_s+'/4  '+fam.to_s.upcase+
      '  stage='+important_current_stage_v10538.to_s.upcase+'  '+names.join(' | '),1)
    marks=(@important_marks_v10538 || {}).size
    b.font.size=12;b.font.bold=true;b.font.color=Color.new(255,220,125)
    b.draw_text(8,Graphics.height-21,Graphics.width-16,18,
      'F8 標記/取消疑點 ['+marks.to_s+']   C 下一 Family   ←/→ 換頁   B/Esc 離開   SHIFT+F9 啟動',1)
  rescue
  end

  def important_dispose_panels_v10538
    (@important_panels_v10538 || []).each{|p|p.dispose if p!=nil}
    @important_panels_v10538=[]
  rescue
  end

  def important_dispose_all_v10538
    important_dispose_panels_v10538
    s=@important_overlay_v10538
    if s!=nil
      begin;s.bitmap.dispose if s.bitmap!=nil && !s.bitmap.disposed?;rescue;end
      begin;s.dispose unless s.disposed?;rescue;end
    end
    @important_overlay_v10538=nil
    @important_active_v10538=false
    @important_loading_v10538=false
  rescue
  end

  def important_start_v10538
    return false unless important_species_ready_v10538?
    @important_active_v10538=true
    @important_loading_v10538=true
    @important_assets_v10538=PMD_AC.important_manual_asset_rows_v10538
    @important_load_index_v10538=0
    @important_page_v10538=0
    @important_family_v10538=0
    @important_frame_v10538=0
    @important_action_window_v10538=PMD_AC::REPRESENTATIVE_TRANSITION_ACTION_MIN_V10537
    @important_panels_v10538=[]
    @important_marks_v10538={}
    @important_pages_seen_v10538={}
    @important_species_seen_v10538={}
    @important_sequences_seen_v10538={}
    @important_runs_v10538=@important_runs_v10538.to_i+1
    @important_request_v10538=false
    important_create_overlay_v10538
    log_event(:battle,'BATTLE_IMPORTANT_SPECIES_MANUAL_QA_V10538 START input=SHIFT+F9 species=16 pages=4 families=10'+
      ' sequence_views=40 two_diagonals=1 single_shot=1 stable_species_scale=1'+
      ' combat_step_paused=1 preview_sprite_isolated=1 performance_capture_paused=1 manual_visual_judgement_required=1')
    important_draw_header_v10538
    true
  rescue
    important_dispose_all_v10538
    false
  end

  def important_prewarm_v10538
    rows=@important_assets_v10538 || []
    n=PMD_AC::IMPORTANT_PREWARM_PER_FRAME_V10538;n=1 if n<=0
    n.times do
      break if @important_load_index_v10538.to_i>=rows.size
      row=rows[@important_load_index_v10538.to_i]
      PMD_AC.representative_visual_bitmap_v10534(row[0],row[1])
      @important_load_index_v10538=@important_load_index_v10538.to_i+1
    end
    if @important_load_index_v10538.to_i>=rows.size
      @important_loading_v10538=false
      log_event(:battle,'BATTLE_IMPORTANT_SPECIES_PREWARM_V10538 ready=1 assets='+rows.size.to_s+'/'+rows.size.to_s+
        ' per_frame='+n.to_s+' formal_perf_capture_paused=1')
      important_build_page_v10538
    else
      important_draw_header_v10538
    end
  rescue
    important_finish_v10538(false,'prewarm_exception')
  end

  def important_build_page_v10538
    important_dispose_panels_v10538
    pages=PMD_AC.important_manual_pages_v10538
    pi=@important_page_v10538.to_i
    return important_finish_v10538(true,'complete') if pi>=pages.size
    sids=pages[pi]
    top=50;bottom=25;gap=4;cols=2;rows=2
    pw=(Graphics.width-gap*(cols+1))/cols
    ph=(Graphics.height-top-bottom-gap*(rows+1))/rows
    sids.each_with_index do |sid,i|
      c=i%cols;r=i/cols;x=gap+c*(pw+gap);y=top+gap+r*(ph+gap)
      p=Sprite_PMDImportantSpeciesPanelV10538.new(@viewport,x,y,pw,ph,sid,pi*4+i+1,16)
      @important_panels_v10538.push(p)
      @important_species_seen_v10538[sid]=true
    end
    @important_pages_seen_v10538[pi]=true
    important_apply_family_v10538
  rescue
    important_finish_v10538(false,'page_exception')
  end

  def important_rows_v10538
    pages=PMD_AC.important_manual_pages_v10538
    pi=@important_page_v10538.to_i
    return [] if pi<0 || pi>=pages.size
    fam=PMD_AC::IMPORTANT_MANUAL_FAMILIES_V10538[@important_family_v10538.to_i] || :strike
    out=[]
    pages[pi].each do |sid|
      q=nil
      a=@important_audit_result_v10538
      if a!=nil && a[:cache]!=nil
        q=a[:cache][sid+':'+fam.to_s]
      end
      q=PMD_AC.important_manual_action_info_v10538(sid,fam) if q==nil
      out.push({:sid=>sid,:info=>q,:pose=>q[:pose],
        :duration=>PMD_AC.important_manual_action_duration_v10538(sid,q[:pose])})
    end
    out
  rescue
    []
  end

  def important_apply_family_v10538
    rows=important_rows_v10538
    maxdur=PMD_AC::REPRESENTATIVE_TRANSITION_ACTION_MIN_V10537
    rows.each{|q|maxdur=q[:duration].to_i if q[:duration].to_i>maxdur}
    maxdur=PMD_AC::REPRESENTATIVE_TRANSITION_ACTION_MAX_V10537 if maxdur>PMD_AC::REPRESENTATIVE_TRANSITION_ACTION_MAX_V10537
    @important_action_window_v10538=maxdur
    @important_frame_v10538=0
    (@important_panels_v10538 || []).each{|p|p.set_neutral_v10537 if p!=nil}
    pi=@important_page_v10538.to_i
    fam=PMD_AC::IMPORTANT_MANUAL_FAMILIES_V10538[@important_family_v10538.to_i] || :strike
    @important_sequences_seen_v10538[pi.to_s+':'+fam.to_s]=true
    poses=[]
    rows.each do |q|
      info=q[:info]
      poses.push(q[:sid]+':' +(q[:pose]==nil ? 'nil':q[:pose].to_s)+':'+q[:duration].to_i.to_s+'f'+
        ':fb'+(info[:fallback] ? '1':'0')+':nat'+(info[:native] ? '1':'0'))
    end
    log_event(:battle,'BATTLE_IMPORTANT_SPECIES_SEQUENCE_V10538 page='+(pi+1).to_s+'/4 family='+fam.to_s+
      ' species=['+rows.collect{|q|q[:sid]}.join(',')+'] action_window='+maxdur.to_s+
      ' poses=['+poses.join(',')+'] flow=neutral>single_shot>end_hold>neutral')
    important_draw_header_v10538
  rescue
    important_finish_v10538(false,'family_exception')
  end

  def important_begin_action_v10538
    rows=important_rows_v10538
    (@important_panels_v10538 || []).each_with_index do |p,i|
      p.set_action_v10537(rows[i][:info]) if p!=nil && rows[i]!=nil
    end
    important_draw_header_v10538
  rescue
  end

  def important_begin_post_v10538
    (@important_panels_v10538 || []).each{|p|p.set_neutral_v10537 if p!=nil}
    important_draw_header_v10538
  rescue
  end

  def important_next_family_v10538
    @important_family_v10538=@important_family_v10538.to_i+1
    if @important_family_v10538>=PMD_AC::IMPORTANT_MANUAL_FAMILIES_V10538.size
      @important_family_v10538=0
      @important_page_v10538=@important_page_v10538.to_i+1
      pages=PMD_AC.important_manual_pages_v10538
      if @important_page_v10538>=pages.size
        important_finish_v10538(true,'complete')
      else
        important_build_page_v10538
      end
    else
      important_apply_family_v10538
    end
  rescue
    important_finish_v10538(false,'next_family_exception')
  end

  def important_change_page_v10538(delta)
    pages=PMD_AC.important_manual_pages_v10538
    return if pages.empty?
    @important_page_v10538=(@important_page_v10538.to_i+delta.to_i)%pages.size
    @important_family_v10538=0
    important_build_page_v10538
  rescue
  end

  def important_current_finding_v10538
    rows=important_rows_v10538
    pi=@important_page_v10538.to_i
    fam=PMD_AC::IMPORTANT_MANUAL_FAMILIES_V10538[@important_family_v10538.to_i] || :strike
    poses=[]
    rows.each{|q|poses.push(q[:sid]+':' +(q[:pose]==nil ? 'nil':q[:pose].to_s)+':'+q[:duration].to_i.to_s+'f')}
    {:key=>pi.to_s+':'+fam.to_s,:page=>pi,:family=>fam,
      :species=>rows.collect{|q|q[:sid]},:poses=>poses}
  rescue
    nil
  end

  def important_toggle_mark_v10538
    row=important_current_finding_v10538;return if row==nil
    if @important_marks_v10538[row[:key]]
      @important_marks_v10538.delete(row[:key]);action='unmark'
      begin;Sound.play_cancel;rescue;end
    else
      @important_marks_v10538[row[:key]]=row;action='mark'
      begin;Sound.play_decision;rescue;end
    end
    log_event(:battle,'BATTLE_IMPORTANT_SPECIES_FINDING_V10538 action='+action+
      ' page='+(row[:page]+1).to_s+'/4 family='+row[:family].to_s+
      ' species=['+row[:species].join(',')+'] poses=['+row[:poses].join(',')+']'+
      ' marks_now='+@important_marks_v10538.size.to_s)
    important_draw_header_v10538
  rescue
  end

  def important_findings_text_v10538
    out=[]
    (@important_marks_v10538 || {}).values.sort_by{|r|[r[:page].to_i,r[:family].to_s]}.each do |r|
      out.push('p'+(r[:page].to_i+1).to_s+':'+r[:family].to_s+'=['+r[:species].join(',')+']')
    end
    out
  rescue
    []
  end

  def important_finish_v10538(ok,reason)
    return false unless important_species_active_v10538?
    marks=important_findings_text_v10538
    important_dispose_panels_v10538
    s=@important_overlay_v10538
    if s!=nil
      begin;s.bitmap.dispose if s.bitmap!=nil && !s.bitmap.disposed?;rescue;end
      begin;s.dispose unless s.disposed?;rescue;end
    end
    @important_overlay_v10538=nil
    @important_active_v10538=false
    @important_loading_v10538=false
    pages=(@important_pages_seen_v10538 || {}).size
    species=(@important_species_seen_v10538 || {}).size
    views=(@important_sequences_seen_v10538 || {}).size
    structural=(pages==4 && species==16 && views==40)
    fixture_pass=ok && structural
    visual_pass=fixture_pass && marks.empty?
    @important_completes_v10538=@important_completes_v10538.to_i+1 if fixture_pass
    begin
      @motion_perf_prev_update_time_v1023=Time.now.to_f
      @motion_perf_capture_last_time_v1023=Time.now if @motion_perf_capture_last_time_v1023!=nil
    rescue
    end
    log_event(:battle,'BATTLE_IMPORTANT_SPECIES_COMPLETE_V10538 fixture_pass='+(fixture_pass ? '1':'0')+
      ' visual_pass='+(visual_pass ? '1':'0')+' reason='+reason.to_s+
      ' pages_seen='+pages.to_s+'/4 species_seen='+species.to_s+'/16 sequence_views='+views.to_s+'/40'+
      ' marks='+marks.size.to_s+' findings=['+marks.join('|')+'] stable_species_scale=1 single_shot=1'+
      ' combat_step_resumed=1 performance_capture_resumed=1'+
      ' next_gate='+(visual_pass ? 'generated_runtime_asset_expansion_0027_0494':'focused_important_species_review')+
      ' gameplay_change=0')
    visual_pass
  rescue
    false
  end

  def important_update_v10538
    return unless important_species_active_v10538?
    if @important_loading_v10538
      important_prewarm_v10538;return
    end
    (@important_panels_v10538 || []).each{|p|p.update if p!=nil}
    @important_frame_v10538=@important_frame_v10538.to_i+1
    pre=PMD_AC::IMPORTANT_PRE_FRAMES_V10538
    aw=@important_action_window_v10538.to_i
    hold=PMD_AC::IMPORTANT_END_HOLD_V10538
    post=PMD_AC::IMPORTANT_POST_FRAMES_V10538
    f=@important_frame_v10538.to_i
    if f==pre
      important_begin_action_v10538
    elsif f==pre+aw
      important_draw_header_v10538
    elsif f==pre+aw+hold
      important_begin_post_v10538
    elsif f>=pre+aw+hold+post
      important_next_family_v10538
    end
  rescue
    important_finish_v10538(false,'update_exception')
  end

  def important_input_v10538
    if Input.trigger?(Input::B)
      begin;Sound.play_cancel;rescue;end
      important_finish_v10538(false,'manual_exit')
    elsif Input.trigger?(Input::F8)
      important_toggle_mark_v10538
    elsif Input.trigger?(Input::RIGHT)
      begin;Sound.play_cursor;rescue;end
      important_change_page_v10538(1)
    elsif Input.trigger?(Input::LEFT)
      begin;Sound.play_cursor;rescue;end
      important_change_page_v10538(-1)
    elsif Input.trigger?(Input::C)
      begin;Sound.play_decision;rescue;end
      important_next_family_v10538
    end
  rescue
  end

  def update_battle_input
    if important_species_active_v10538?
      important_input_v10538
      return
    end
    # P8 v1.06.67: historical SHIFT+F9 Important Species launcher retired.
    # important_start_v10538 remains callable for issue-driven diagnosis.
    pmd_ac_v10538_update_battle_input
  rescue
    pmd_ac_v10538_update_battle_input
  end

  def update_battle_step
    if important_species_active_v10538?
      important_update_v10538
      return
    end
    unless respond_to?(:production_external_battle_fast_v10613?) && production_external_battle_fast_v10613?
      representative_transition_audit_tick_v10538
      important_species_audit_tick_v10538
    end
    r=pmd_ac_v10538_update_battle_step
    if !@important_ready_logged_v10538 && important_species_ready_v10538?
      @important_ready_logged_v10538=true
      log_event(:battle,'BATTLE_IMPORTANT_SPECIES_MANUAL_QA_V10538 READY input=SHIFT+F9 species=16 pages=4 families=10'+
        ' sequence_views=40 stable_species_scale=1 single_shot=1 F8_mark=1'+
        ' transition_windows_passed=1 current_asset_scope=56_representatives')
    end
    if @important_request_v10538 && important_species_ready_v10538?
      important_start_v10538
    end
    r
  rescue
    pmd_ac_v10538_update_battle_step
  end

  def restart_to_deploy
    important_finish_v10538(false,'return_deploy') if important_species_active_v10538?
    important_dispose_all_v10538
    pmd_ac_v10538_restart_to_deploy
  end

  def terminate
    important_dispose_all_v10538
    pmd_ac_v10538_terminate
  end

  def focus_cast_log_summary_v1055
    r=pmd_ac_v10538_focus_summary
    return r if respond_to?(:production_external_battle_fast_v10613?) && production_external_battle_fast_v10613?
    begin
      tq=@rep_transition_audit_v10537 || {}
      iq=@important_audit_result_v10538 || {}
      marks=important_findings_text_v10538
      log_event(:battle,'BATTLE_TRANSITION_AUDIT_INCREMENTAL_SUMMARY_V10538 pass='+(tq[:pass] ? '1':'0')+
        ' playable='+tq[:playable].to_i.to_s+'/280 max_tick_ms='+tq[:ms].to_i.to_s+
        ' cold_start_sync_scan_retired=1 threshold_ms='+PMD_AC::TRANSITION_AUDIT_THRESHOLD_MS_V10538.to_s)
      log_event(:battle,'BATTLE_IMPORTANT_SPECIES_SUMMARY_V10538 audit_pass='+(iq[:pass] ? '1':'0')+
        ' runs='+@important_runs_v10538.to_i.to_s+' completes='+@important_completes_v10538.to_i.to_s+
        ' marks='+marks.size.to_s+' findings=['+marks.join('|')+'] input=SHIFT+F9'+
        ' next_gate='+((@important_completes_v10538.to_i>0 && marks.empty?) ?
          'generated_runtime_asset_expansion_0027_0494':'run_important_species_manual_qa')+
        ' representative_transition_windows_pass=1 gameplay_change=0')
    rescue
    end
    r
  end
end
