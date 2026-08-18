# encoding: UTF-8
#===============================================================================
# ■ PMD AutoChess - QA Preview Z-Order Visibility Seal v1.05.39
#===============================================================================
# 【用途】
# 1. 修正 v1.05.38 Important Species Manual QA I 的「整片近乎全黑」問題。
#    Windows 截圖顯示：標題與底部操作列正常，但 2×2 Pokémon panel 與 sprite 僅剩
#    極暗殘影；同場 LOG 卻已確認 assets=110/110、160/160 route playable，故不是素材
#    缺失，而是 QA 顯示層級（Z-order）錯誤。
# 2. 追溯後確認 v1.05.37 Transition Continuity Fixture 也有同類層級錯誤：
#    - 原 Visual panel 背景 z=15002、Pokémon sprite z=15003。
#    - v1.05.37 全畫面黑色 overlay 卻設為 z=16000。
#    - v1.05.38 Important overlay 更設為 z=16100。
#    overlay 使用 alpha=248，因此 panel/sprite 被壓在幾乎不透明黑幕後方，只剩約 3%
#    亮度的殘影。
# 3. 本版把 v1.05.37 / v1.05.38 QA overlay 統一封回 z=15000，並再次鎖定 panel=15002、
#    Pokémon sprite=15003，恢復原 v1.05.34 Visual Fixture 已驗證的正確層級結構。
# 4. 新增 runtime Z-order self-check。若 overlay 不在 panel / Pokémon sprite 下方，
#    Transition 或 Important fixture 即使完整播完，也不得產生有效人工 visual PASS。
# 5. v1.05.38 incremental audit 與 Important 160-slot structural audit 已由 Windows PASS，
#    全部保留；本版不重寫 routing，只要求人工視覺驗收重新跑一次。
#
# 【主要設定】
# QA_PREVIEW_OVERLAY_Z_V10539 = 15000
#   QA 全畫面暗底，必須在 panel 與 Pokémon sprite 下方。
# QA_PREVIEW_PANEL_Z_V10539 = 15002
#   每格資訊 panel。
# QA_PREVIEW_SPRITE_Z_V10539 = 15003
#   左右 45° Pokémon preview sprite。
#
# 【機制規則】
# - Frozen Motion Combat Core 不直接修改。
# - 不修改 Damage Formula、HP、AI、Energy、Attack Wait、Priority、hit timing。
# - 不修改 logical Spatial x/y、velocity、dash/lunge endpoint、push/pull/through。
# - v1.05.36 Sandshrew Head component guard 完整保留。
# - v1.05.28～33 Group Tuning I～V 完整保留。
# - v1.05.38 incremental Transition audit 與 Important 160-slot audit 完整保留。
# - 本版只有 QA Preview presentation Z-order 修正，不影響正式戰場 Sprite z-order。
# - QA fixture active 時既有 combat-step pause / performance-capture pause 規則不變。
# - 正式 Performance threshold 仍為 50ms，完全不放寬。
#
# 【人工驗收規則】
# 由於 v1.05.37 與 v1.05.38 舊畫面被 overlay 遮住，先前「marks=0」只代表沒有按 F8，
# 不能再當作可靠肉眼 PASS。本版需重新執行：
#   SHIFT + F7：Representative Transition Continuity Fixture（56 species / 70 views）
#   SHIFT + F9：Important Species Manual QA I（16 species / 40 views）
# 兩者畫面都應清楚顯示 Pokémon sprite 與 panel 文字。
# 任何動作若有 component-only、尺寸跳變、anchor 跳動、翻面或不自然 recovery，按 F8。
#
# 【LOG】
# BATTLE_QA_PREVIEW_ZORDER_SEAL_V10539 START ...
# BATTLE_QA_PREVIEW_ZORDER_CHECK_V10539 fixture=transition ...
# BATTLE_QA_PREVIEW_ZORDER_CHECK_V10539 fixture=important ...
# BATTLE_QA_PREVIEW_ZORDER_SUMMARY_V10539 ...
#
# 【事件／腳本呼叫方式】
# 不需事件腳本呼叫；只在 NORMAL battle QA fixture 內作用。
#
# 【實際範例】
# SHIFT+F9 啟動後，黑色背景應位於最底層；#0151 夢幻、#0244 炎帝、#0330 沙漠蜻蜓、
# #0350 美納斯的左右 45° sprite 應保持正常亮度，不再只剩深黑剪影。
#===============================================================================
$imported={} unless defined?($imported)
$imported['PMD_AutoChess_QAPreviewZOrderVisibilitySeal_v10539']=true

module PMD_AC
  QA_PREVIEW_OVERLAY_Z_V10539=15000
  QA_PREVIEW_PANEL_Z_V10539=15002
  QA_PREVIEW_SPRITE_Z_V10539=15003
end

#===============================================================================
# ■ Base Representative Preview Panel
#   封住 panel / preview sprite 的正式 QA z-order。
#===============================================================================
class Sprite_PMDRepresentativeVisualPanelV10534
  alias pmd_ac_v10539_qa_zorder_initialize initialize unless method_defined?(:pmd_ac_v10539_qa_zorder_initialize)
  def initialize(viewport,x,y,w,h,sid,body,index,total)
    pmd_ac_v10539_qa_zorder_initialize(viewport,x,y,w,h,sid,body,index,total)
    @panel.z=PMD_AC::QA_PREVIEW_PANEL_Z_V10539 if @panel!=nil
    @right.z=PMD_AC::QA_PREVIEW_SPRITE_Z_V10539 if @right!=nil
    @left.z=PMD_AC::QA_PREVIEW_SPRITE_Z_V10539 if @left!=nil
  rescue
  end
end

class Scene_PMD_AutoChess
  alias pmd_ac_v10539_qa_zorder_start_battle start_battle unless method_defined?(:pmd_ac_v10539_qa_zorder_start_battle)
  alias pmd_ac_v10539_transition_create_overlay_v10537 representative_transition_create_overlay_v10537 unless method_defined?(:pmd_ac_v10539_transition_create_overlay_v10537)
  alias pmd_ac_v10539_transition_build_page_v10537 representative_transition_build_page_v10537 unless method_defined?(:pmd_ac_v10539_transition_build_page_v10537)
  alias pmd_ac_v10539_transition_finish_v10537 representative_transition_finish_v10537 unless method_defined?(:pmd_ac_v10539_transition_finish_v10537)
  alias pmd_ac_v10539_important_create_overlay_v10538 important_create_overlay_v10538 unless method_defined?(:pmd_ac_v10539_important_create_overlay_v10538)
  alias pmd_ac_v10539_important_build_page_v10538 important_build_page_v10538 unless method_defined?(:pmd_ac_v10539_important_build_page_v10538)
  alias pmd_ac_v10539_important_finish_v10538 important_finish_v10538 unless method_defined?(:pmd_ac_v10539_important_finish_v10538)
  alias pmd_ac_v10539_focus_summary focus_cast_log_summary_v1055 unless method_defined?(:pmd_ac_v10539_focus_summary)

  def start_battle
    @qa_zorder_transition_logged_v10539=false
    @qa_zorder_important_logged_v10539=false
    @qa_zorder_transition_pass_v10539=false
    @qa_zorder_important_pass_v10539=false
    r=pmd_ac_v10539_qa_zorder_start_battle
    begin
      if respond_to?(:verification_mode) && verification_mode==:normal &&
         !(respond_to?(:production_external_battle_fast_v10613?) && production_external_battle_fast_v10613?)
        log_event(:battle,'BATTLE_QA_PREVIEW_ZORDER_SEAL_V10539 START overlay_z='+
          PMD_AC::QA_PREVIEW_OVERLAY_Z_V10539.to_s+' panel_z='+PMD_AC::QA_PREVIEW_PANEL_Z_V10539.to_s+
          ' sprite_z='+PMD_AC::QA_PREVIEW_SPRITE_Z_V10539.to_s+
          ' v10537_old_overlay_z=16000 v10538_old_overlay_z=16100'+
          ' previous_transition_visual_acceptance_invalidated=1 previous_important_visual_acceptance_invalidated=1'+
          ' structural_audits_retained=1 motion_core_unchanged=1 gameplay_change=0')
      end
    rescue
    end
    r
  end

  #--------------------------------------------------------------------------
  # v1.05.37 Transition overlay：放回 preview panel 下方。
  #--------------------------------------------------------------------------
  def representative_transition_create_overlay_v10537
    r=pmd_ac_v10539_transition_create_overlay_v10537
    begin
      @rep_transition_overlay_v10537.z=PMD_AC::QA_PREVIEW_OVERLAY_Z_V10539 if @rep_transition_overlay_v10537!=nil
    rescue
    end
    r
  end

  #--------------------------------------------------------------------------
  # v1.05.38 Important overlay：放回 preview panel 下方。
  #--------------------------------------------------------------------------
  def important_create_overlay_v10538
    r=pmd_ac_v10539_important_create_overlay_v10538
    begin
      @important_overlay_v10538.z=PMD_AC::QA_PREVIEW_OVERLAY_Z_V10539 if @important_overlay_v10538!=nil
    rescue
    end
    r
  end

  def qa_preview_zorder_state_v10539(kind)
    panels=[];overlay=nil
    if kind==:transition
      panels=@rep_transition_panels_v10537 || []
      overlay=@rep_transition_overlay_v10537
    else
      panels=@important_panels_v10538 || []
      overlay=@important_overlay_v10538
    end
    p=panels[0]
    return {:pass=>false,:overlay=>-1,:panel=>-1,:sprite=>-1} if p==nil || overlay==nil
    pn=p.instance_variable_get(:@panel)
    rr=p.instance_variable_get(:@right)
    ll=p.instance_variable_get(:@left)
    oz=overlay.z.to_i
    pz=pn==nil ? -1 : pn.z.to_i
    rz=rr==nil ? -1 : rr.z.to_i
    lz=ll==nil ? -1 : ll.z.to_i
    sz=rz<lz ? rz : lz
    pass=(oz<pz && pz<rz && pz<lz &&
      oz==PMD_AC::QA_PREVIEW_OVERLAY_Z_V10539 &&
      pz==PMD_AC::QA_PREVIEW_PANEL_Z_V10539 &&
      rz==PMD_AC::QA_PREVIEW_SPRITE_Z_V10539 &&
      lz==PMD_AC::QA_PREVIEW_SPRITE_Z_V10539)
    {:pass=>pass,:overlay=>oz,:panel=>pz,:sprite=>sz,:right=>rz,:left=>lz}
  rescue
    {:pass=>false,:overlay=>-1,:panel=>-1,:sprite=>-1,:right=>-1,:left=>-1}
  end

  def qa_preview_zorder_log_v10539(kind)
    q=qa_preview_zorder_state_v10539(kind)
    if kind==:transition
      @qa_zorder_transition_pass_v10539=q[:pass]
      return q if @qa_zorder_transition_logged_v10539
      @qa_zorder_transition_logged_v10539=true
    else
      @qa_zorder_important_pass_v10539=q[:pass]
      return q if @qa_zorder_important_logged_v10539
      @qa_zorder_important_logged_v10539=true
    end
    log_event(:battle,'BATTLE_QA_PREVIEW_ZORDER_CHECK_V10539 fixture='+kind.to_s+
      ' pass='+(q[:pass] ? '1':'0')+' overlay_z='+q[:overlay].to_i.to_s+
      ' panel_z='+q[:panel].to_i.to_s+' sprite_z='+q[:sprite].to_i.to_s+
      ' required_order=overlay<panel<sprite old_blackout_retired=1')
    q
  rescue
    {:pass=>false}
  end

  def representative_transition_build_page_v10537
    r=pmd_ac_v10539_transition_build_page_v10537
    qa_preview_zorder_log_v10539(:transition)
    r
  rescue
    r
  end

  def important_build_page_v10538
    r=pmd_ac_v10539_important_build_page_v10538
    qa_preview_zorder_log_v10539(:important)
    r
  rescue
    r
  end

  # 若層級驗證失敗，禁止黑畫面再次被 marks=0 誤判為人工 PASS。
  def representative_transition_finish_v10537(ok,reason)
    if ok && !@qa_zorder_transition_pass_v10539
      ok=false;reason='zorder_visibility_invalid'
    end
    pmd_ac_v10539_transition_finish_v10537(ok,reason)
  rescue
    pmd_ac_v10539_transition_finish_v10537(false,'zorder_visibility_exception')
  end

  def important_finish_v10538(ok,reason)
    if ok && !@qa_zorder_important_pass_v10539
      ok=false;reason='zorder_visibility_invalid'
    end
    pmd_ac_v10539_important_finish_v10538(ok,reason)
  rescue
    pmd_ac_v10539_important_finish_v10538(false,'zorder_visibility_exception')
  end

  def focus_cast_log_summary_v1055
    r=pmd_ac_v10539_focus_summary
    return r if respond_to?(:production_external_battle_fast_v10613?) && production_external_battle_fast_v10613?
    begin
      log_event(:battle,'BATTLE_QA_PREVIEW_ZORDER_SUMMARY_V10539 transition_checked='+
        (@qa_zorder_transition_logged_v10539 ? '1':'0')+' transition_pass='+
        (@qa_zorder_transition_pass_v10539 ? '1':'0')+' important_checked='+
        (@qa_zorder_important_logged_v10539 ? '1':'0')+' important_pass='+
        (@qa_zorder_important_pass_v10539 ? '1':'0')+
        ' old_visual_acceptance_invalidated=1 structural_audits_retained=1 gameplay_change=0')
    rescue
    end
    r
  end
end
