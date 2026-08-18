# encoding: UTF-8
#===============================================================================
# ■ PMD AutoChess - Representative Visual Scale Parity + Findings Capture v1.05.35
#===============================================================================
# 【用途】
# 1. 承接 v1.05.34 Windows 實機結果：Representative Visual Fixture 已完整跑完
#    14/14 pages、56/56 species、84/84 phase views，且 896-route QA 仍 PASS。
# 2. v1.05.34 Preview 會依「當前 action frame 尺寸」各自 fit panel；這有利於看動作內容，
#    但可能把不同 action sheet 之間的相對尺寸跳變縮放掉。v1.05.35 改成每隻物種固定
#    使用 neutral pose 計算出的同一 preview scale，讓 Attack / Hurt / route 換姿勢時的
#    相對尺寸差、腳底 anchor 跳動、裁切風險更容易被肉眼發現。
# 3. 新增 F8 Manual Finding Capture：看到目前「本頁 + 本 phase」有任何可疑視覺，
#    直接按 F8 標記；再按一次取消。LOG 會記錄 page/body/phase/species/selected pose，
#    使用者下一輪只需上傳 LOG，不必另外抄 56 隻名稱。
# 4. 本版仍是 QA / Presentation-only。沒有因為 v1.05.34 無自動錯誤就擅自宣告
#    人工視覺全部 PASS；真正物種 override 只在 F8 finding 或使用者明確視覺回報後處理。
#
# 【主要設定】
# REPRESENTATIVE_VISUAL_FINDING_INPUT_V10535 = Input::F8
#   Fixture active 時，F8 標記/取消目前 page + phase。
# REPRESENTATIVE_VISUAL_SCALE_MIN_V10535 = 0.12
#   只限制 Preview 最小顯示比例，沿用 v1.05.34 的 panel 可視下限。
# REPRESENTATIVE_VISUAL_SCALE_REFERENCE_V10535 = :neutral
#   同一物種全部 action 共用 neutral 參考 scale，不再每個 action 自行 fit。
#
# 【機制規則】
# - 仍沿用 v1.05.34：NORMAL battle 按 F7 啟動，若 896-route QA 尚未完成則 pending。
# - v1.05.35 不新增 S-menu verifier、不增加 top event feed。
# - F8 只在 Representative Fixture active 時由本腳本攔截；一般戰鬥/Deploy 原按鍵不改。
# - Finding 單位為 page + phase，因一頁同時顯示 4 species。LOG 同時寫出四隻與 pose；
#   下一階段可直接建立 focused 4-species review，不需要使用者記畫面角落是哪隻。
# - finding 是「人工疑點」，不是自動 FAIL。未標記也不等於腳本能證明畫面完美。
# - Preview stable scale 只影響 Fixture Sprite，不改正式戰場 Sprite zoom、bitmap、source rect。
# - 不修改 Damage Formula、HP、AI、Energy、Attack Wait、Priority、hit timing。
# - 不修改 logical Spatial x/y、速度、dash/lunge endpoint、push/pull/through。
# - Frozen Motion Combat Core 不直接修改；HOME 仍是本次 logical/action anchor。
# - 50ms 正式門檻不修改；Fixture 期間仍沿用 v1.05.34 暫停正式 Performance capture。
#
# 【操作方式】
# - NORMAL battle → F7：啟動 56-species Visual Fixture。
# - Fixture 中 F8：標記/取消目前 page + phase 的視覺疑點。
# - C：下一個 phase。
# - ← / →：上一頁 / 下一頁。
# - ↑ / ↓：上一個 / 下一個 body group。
# - B / Esc：提早離開。
#
# 【建議怎麼標記】
# - 任何一隻方向明顯錯、身體縮放突然變大/變小、腳底 anchor 瞬移、裁切、
#   四足/鳥/蛇用起來很怪、fallback 雖合法但肉眼很不自然，都按 F8。
# - 不需要判斷是哪一隻；只要當下那一頁有問題就標記。下一輪 LOG 會把四隻與 pose 列出。
#
# 【LOG】
# BATTLE_REPRESENTATIVE_VISUAL_SCALE_PARITY_V10535 START ...
# BATTLE_REPRESENTATIVE_VISUAL_FINDING_CAPTURE_V10535 START ...
# BATTLE_REPRESENTATIVE_VISUAL_FINDING_V10535 action=mark/unmark ...
# BATTLE_REPRESENTATIVE_VISUAL_FINDINGS_COMPLETE_V10535 ...
# BATTLE_REPRESENTATIVE_VISUAL_FINDINGS_SUMMARY_V10535 ...
#
# 【實際範例】
# - Page 13 serpentine / phase=lunge 時若看到大岩蛇或哈克龍 Swing 的身體尺寸突然跳變，
#   按 F8。LOG 會保存 page=13、body=serpentine、phase=lunge 對應的四隻 species 與 pose。
# - 如果完整 14 頁跑完且沒有任何肉眼疑點，不必按 F8；SUMMARY marks=0，後續可進
#   Transition Continuity Fixture，開始驗 HOME → action → recovery 的連續性。
#===============================================================================
$imported={} unless defined?($imported)
$imported['PMD_AutoChess_RepresentativeVisualScaleParityFindings_v10535']=true

module PMD_AC
  REPRESENTATIVE_VISUAL_SCALE_MIN_V10535=0.12
  REPRESENTATIVE_VISUAL_SCALE_REFERENCE_V10535=:neutral
end

#===============================================================================
# ■ Sprite_PMDRepresentativeVisualPanelV10534
#   trailing override：只改 Fixture Preview scale authority。
#===============================================================================
class Sprite_PMDRepresentativeVisualPanelV10534
  alias pmd_ac_v10535_visual_panel_initialize initialize unless method_defined?(:pmd_ac_v10535_visual_panel_initialize)

  def initialize(viewport,x,y,w,h,sid,body,index,total)
    @rep_visual_stable_scale_v10535=nil
    pmd_ac_v10535_visual_panel_initialize(viewport,x,y,w,h,sid,body,index,total)
  end

  def representative_visual_stable_scale_v10535
    return @rep_visual_stable_scale_v10535 if @rep_visual_stable_scale_v10535!=nil
    pose=PMD_AC.representative_visual_neutral_pose_v10534(@sid,@body)
    d=pose==nil ? nil : PMD_AC.action_data(@sid,pose)
    d=@data if d==nil
    if d==nil
      @rep_visual_stable_scale_v10535=1.0
      return @rep_visual_stable_scale_v10535
    end
    fw=d[:frame_w].to_i;fh=d[:frame_h].to_i
    fw=1 if fw<=0;fh=1 if fh<=0
    maxw=(@w/2-18).to_f;maxh=(@h-72).to_f
    scale=[maxw/fw.to_f,maxh/fh.to_f,1.0].min
    scale=PMD_AC::REPRESENTATIVE_VISUAL_SCALE_MIN_V10535 if scale<PMD_AC::REPRESENTATIVE_VISUAL_SCALE_MIN_V10535
    @rep_visual_stable_scale_v10535=scale
    scale
  rescue
    1.0
  end

  # v1.05.34 原本每個 action 依自己的 frame_w/frame_h 重新 fit。
  # v1.05.35 改成同物種固定 neutral-reference scale；ox/oy 仍用當前 frame bottom-center，
  # 以便直接看不同 action sheet 的實際相對尺寸差。
  def configure_geometry_v10534
    return if @data==nil
    fw=@data[:frame_w].to_i;fh=@data[:frame_h].to_i
    fw=1 if fw<=0;fh=1 if fh<=0
    scale=representative_visual_stable_scale_v10535
    @right.zoom_x=scale;@right.zoom_y=scale;@left.zoom_x=scale;@left.zoom_y=scale
    @right.ox=fw/2;@right.oy=fh;@left.ox=fw/2;@left.oy=fh
    @right.y=@y+@h-22;@left.y=@y+@h-22
  rescue
  end
end

#===============================================================================
# ■ Scene_PMD_AutoChess - Manual Finding Capture
#===============================================================================
class Scene_PMD_AutoChess
  alias pmd_ac_v10535_visual_start_battle start_battle unless method_defined?(:pmd_ac_v10535_visual_start_battle)
  alias pmd_ac_v10535_visual_fixture_start representative_visual_start_v10534 unless method_defined?(:pmd_ac_v10535_visual_fixture_start)
  alias pmd_ac_v10535_visual_fixture_input representative_visual_input_v10534 unless method_defined?(:pmd_ac_v10535_visual_fixture_input)
  alias pmd_ac_v10535_visual_fixture_finish representative_visual_finish_v10534 unless method_defined?(:pmd_ac_v10535_visual_fixture_finish)
  alias pmd_ac_v10535_visual_draw_header representative_visual_draw_header_v10534 unless method_defined?(:pmd_ac_v10535_visual_draw_header)
  alias pmd_ac_v10535_visual_focus_summary focus_cast_log_summary_v1055 unless method_defined?(:pmd_ac_v10535_visual_focus_summary)

  def start_battle
    @rep_visual_findings_v10535={}
    @rep_visual_findings_runs_v10535=0
    @rep_visual_findings_completed_v10535=0
    @rep_visual_header_sub_v10535=''
    pmd_ac_v10535_visual_start_battle
  end

  def representative_visual_start_v10534
    @rep_visual_findings_v10535={}
    @rep_visual_header_sub_v10535=''
    ok=pmd_ac_v10535_visual_fixture_start
    if ok
      @rep_visual_findings_runs_v10535=@rep_visual_findings_runs_v10535.to_i+1
      log_event(:battle,'BATTLE_REPRESENTATIVE_VISUAL_SCALE_PARITY_V10535 START reference=neutral'+
        ' stable_species_scale=1 per_action_fit_retired=1 preview_only=1 runtime_sprite_scale_unchanged=1'+
        ' anchor_authority=bottom_center_preview motion_core_unchanged=1 gameplay_change=0')
      log_event(:battle,'BATTLE_REPRESENTATIVE_VISUAL_FINDING_CAPTURE_V10535 START input=F8 unit=page_phase'+
        ' toggle=1 species_per_mark=4 manual_judgement=1 no_auto_fail=1 s_menu_added=0 top_event_feed_added=0')
    end
    ok
  rescue
    false
  end

  def representative_visual_draw_header_v10534(sub)
    @rep_visual_header_sub_v10535=sub.to_s
    representative_visual_create_overlay_v10534
    b=@rep_visual_overlay_v10534.bitmap;b.clear
    b.fill_rect(0,0,Graphics.width,Graphics.height,Color.new(3,6,10,248))
    font=PMD_AC.const_defined?(:UI_PANEL_FONT_V0741) ? PMD_AC::UI_PANEL_FONT_V0741 : ['Microsoft JhengHei']
    b.font.name=font;b.font.size=20;b.font.bold=true;b.font.color=Color.new(255,255,255)
    b.draw_text(8,3,Graphics.width-16,26,'Representative Visual QA II  |  Stable Scale + Findings',1)
    b.font.size=13;b.font.bold=false;b.font.color=Color.new(195,215,235)
    b.draw_text(8,28,Graphics.width-16,19,sub.to_s,1)
    marks=(@rep_visual_findings_v10535 || {}).size
    b.font.size=12;b.font.bold=true;b.font.color=Color.new(255,220,125)
    b.draw_text(8,Graphics.height-21,Graphics.width-16,18,
      'F8 標記/取消疑點 ['+marks.to_s+']   C 下一動作   ←/→ 換頁   ↑/↓ 換體型   B/Esc 離開',1)
  rescue
    pmd_ac_v10535_visual_draw_header(sub)
  end

  def representative_visual_current_finding_v10535
    pages=PMD_AC.representative_visual_pages_v10534
    pi=@rep_visual_page_v10534.to_i
    return nil if pages==nil || pi<0 || pi>=pages.size
    row=pages[pi];body=row[0];sids=row[1]
    phase=PMD_AC::REPRESENTATIVE_VISUAL_PHASES_V10534[@rep_visual_phase_index_v10534.to_i]
    phase=:neutral if phase==nil
    poses=[]
    sids.each do |sid|
      info=PMD_AC.representative_visual_phase_info_v10534(sid,body,phase)
      poses.push(sid.to_s+':' +(info[:pose]==nil ? 'nil' : info[:pose].to_s))
    end
    {:key=>pi.to_s+':'+phase.to_s,:page=>pi,:body=>body,:phase=>phase,:species=>sids,:poses=>poses}
  rescue
    nil
  end

  def representative_visual_toggle_finding_v10535
    row=representative_visual_current_finding_v10535
    return if row==nil
    @rep_visual_findings_v10535={} if @rep_visual_findings_v10535==nil
    key=row[:key]
    if @rep_visual_findings_v10535[key]
      @rep_visual_findings_v10535.delete(key)
      action='unmark'
      begin;Sound.play_cancel;rescue;end
    else
      @rep_visual_findings_v10535[key]=row
      action='mark'
      begin;Sound.play_decision;rescue;end
    end
    log_event(:battle,'BATTLE_REPRESENTATIVE_VISUAL_FINDING_V10535 action='+action+
      ' page='+(row[:page]+1).to_s+'/14 body='+row[:body].to_s+' phase='+row[:phase].to_s+
      ' species=['+row[:species].join(',')+'] poses=['+row[:poses].join(',')+']'+
      ' marks_now='+@rep_visual_findings_v10535.size.to_s)
    representative_visual_draw_header_v10534(@rep_visual_header_sub_v10535)
  rescue
  end

  def representative_visual_input_v10534
    if Input.trigger?(Input::F8)
      representative_visual_toggle_finding_v10535
      return
    end
    pmd_ac_v10535_visual_fixture_input
  rescue
    pmd_ac_v10535_visual_fixture_input
  end

  def representative_visual_findings_text_v10535
    rows=(@rep_visual_findings_v10535 || {}).values
    out=[]
    rows.sort_by{|r|[r[:page].to_i,r[:phase].to_s]}.each do |r|
      out.push('p'+(r[:page].to_i+1).to_s+':'+r[:body].to_s+':'+r[:phase].to_s+'=['+r[:species].join(',')+']')
    end
    out
  rescue
    []
  end

  def representative_visual_finish_v10534(ok,reason)
    findings_before=(@rep_visual_findings_v10535 || {}).size
    text_before=representative_visual_findings_text_v10535
    result=pmd_ac_v10535_visual_fixture_finish(ok,reason)
    @rep_visual_findings_completed_v10535=@rep_visual_findings_completed_v10535.to_i+1 if result
    next_gate=findings_before>0 ? 'focused_visual_review' : 'transition_continuity_fixture'
    log_event(:battle,'BATTLE_REPRESENTATIVE_VISUAL_FINDINGS_COMPLETE_V10535 fixture_pass='+(result ? '1':'0')+
      ' reason='+reason.to_s+' marks='+findings_before.to_s+' findings=['+text_before.join('|')+']'+
      ' stable_species_scale=1 next_gate='+next_gate+' gameplay_change=0')
    result
  rescue
    false
  end

  def focus_cast_log_summary_v1055
    r=pmd_ac_v10535_visual_focus_summary
    return r if respond_to?(:production_external_battle_fast_v10613?) && production_external_battle_fast_v10613?
    begin
      marks=(@rep_visual_findings_v10535 || {}).size
      text=representative_visual_findings_text_v10535
      next_gate=marks>0 ? 'focused_visual_review' : (@rep_visual_findings_completed_v10535.to_i>0 ? 'transition_continuity_fixture':'run_visual_fixture_with_F8')
      log_event(:battle,'BATTLE_REPRESENTATIVE_VISUAL_FINDINGS_SUMMARY_V10535 runs='+@rep_visual_findings_runs_v10535.to_i.to_s+
        ' completes='+@rep_visual_findings_completed_v10535.to_i.to_s+' marks='+marks.to_s+
        ' findings=['+text.join('|')+'] stable_species_scale=1 input=F8 next_gate='+next_gate+
        ' manual_judgement_required=1 gameplay_change=0')
    rescue
    end
    r
  end
end
