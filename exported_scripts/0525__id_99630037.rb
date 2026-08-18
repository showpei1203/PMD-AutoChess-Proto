# encoding: UTF-8
#===============================================================================
# ■ PMD AutoChess - Generated Runtime Asset Expansion I
#   + Visual Acceptance Persistence Gate v1.05.40
#===============================================================================
# 【用途】
# 1. 正式開始 0027～0494 Generated Runtime Asset Expansion。
# 2. 把 468 隻 generated species 切成 6 個固定下載批次，每批 78 隻，讓素材擴張可分段、
#    可重跑、可驗證，不需要一次把整個 PMDCollab repository 全塞進開發流程。
# 3. 沿用 v1.05.26 Runtime Asset Admission：一隻物種必須至少具有
#      Idle / Walk / Float 其中一種 + Attack + Hurt
#    才算正式 admitted。Faint 仍為 optional。
# 4. 新增 Generated Expansion Runtime Observer，在 NORMAL battle 直接回報：
#      - generated admitted / 468
#      - 各 Batch A～F readiness
#      - partial / missing 數量
#      - 下一個建議下載 batch
# 5. 把 v1.05.39 已由 Windows 實機確認的 Important Species Manual QA PASS 記錄為
#    acceptance marker；Representative Transition 則仍要求在修正 Z-order 後重新跑一次
#    SHIFT+F7，通過後本版自動建立持久化 marker。
# 6. Visual Acceptance Gate 與素材擴張可並行：即使 Transition marker 尚未完成，下載工具
#    仍可擴張素材；但 generated_full_acceptance 不會提前宣告 PASS。
#
# 【主要設定】
# GENERATED_EXPANSION_BATCHES_V10540
#   A = 0027～0104
#   B = 0105～0182
#   C = 0183～0260
#   D = 0261～0338
#   E = 0339～0416
#   F = 0417～0494
#   每批固定 78 species，6 批合計 468。
#
# GENERATED_EXPANSION_THRESHOLD_MS_V10540 = 50
#   正式 QA 效能門檻保持 50ms，完全不放寬。
#
# 【機制規則】
# - Frozen Motion Combat Core 不直接修改。
# - 不修改 Damage Formula、HP、AI、Energy、Attack Wait、Priority、hit timing。
# - 不修改 logical Spatial x/y、velocity、dash/lunge endpoint、push/pull/through。
# - 不改 v1.05.28～33 已 PASS 的 Group Tuning。
# - 不改 v1.05.36 Sandshrew Head component guard。
# - 不改 v1.05.38 incremental Transition audit / Important 160-slot structural audit。
# - 不改 v1.05.39 QA Z-order Visibility Seal。
# - 本版本只新增素材擴張工具、readiness observer 與人工驗收 marker。
#
# 【Visual Acceptance Persistence】
# - Important Species：v1.05.39 Windows LOG 已確認 Z-order pass + 40/40 views + marks=0，
#   本完整專案附帶 Graphics/PMD/_IMPORTANT_VISUAL_V10539_PASS.txt。
# - Representative Transition：必須在 v1.05.39+ 正確 Z-order 下重新執行 SHIFT+F7。
#   若 14/14 pages、56/56 species、70/70 views、marks=0 且 Z-order self-check pass，
#   本版會建立 Graphics/PMD/_TRANSITION_VISUAL_V10540_PASS.txt。
# - marker 只記錄人工 QA 已完成，不改任何正式戰鬥行為。
#
# 【下載／匯入方式】
# 專案附帶：
#   Tools/DOWNLOAD_PMD_GENERATED_RUNTIME_EXPANSION_v10540.py
#   Tools/DOWNLOAD_PMD_GENERATED_RUNTIME_EXPANSION_v10540.bat
#   Tools/PMD_GENERATED_RUNTIME_READINESS_v10540.py
#   Tools/PMD_GENERATED_RUNTIME_READINESS_v10540.bat
#
# 建議順序：
#   1. NORMAL battle → SHIFT+F7，完成有效 Transition visual PASS。
#   2. 關閉遊戲。
#   3. 執行 DOWNLOAD...bat，預設下載 Batch A。
#   4. 重新開遊戲打一場 NORMAL，LOG 會自動更新 batch readiness。
#   5. 依序下載 B～F；也可命令列使用 --batch all。
#
# 【事件／腳本呼叫方式】
# 不需事件腳本呼叫。若要由 Debug Console 強制重掃素材：
#   PMD_AC.runtime_asset_scan_v10526(true)
#
# 【LOG】
# BATTLE_GENERATED_RUNTIME_EXPANSION_V10540 START ...
# BATTLE_GENERATED_RUNTIME_BATCH_V10540 batch=A ...
# BATTLE_GENERATED_RUNTIME_VISUAL_GATE_V10540 ...
# BATTLE_GENERATED_RUNTIME_EXPANSION_SUMMARY_V10540 ...
# BATTLE_GENERATED_RUNTIME_VISUAL_ACCEPT_V10540 kind=transition ...
# BATTLE_GENERATED_RUNTIME_VISUAL_ACCEPT_V10540 kind=important ...
#
# 【實際範例】
# 目前專案若仍只有 56 隻 generated representative，可看到：
#   generated=56/468 complete=0
# 下載 Batch A 並重新啟動後，generated 數字應增加；已存在的 representative folders
# 會被 downloader 自動跳過，不會重複下載。
#===============================================================================
$imported={} unless defined?($imported)
$imported['PMD_AutoChess_GeneratedRuntimeExpansionI_VisualAcceptancePersistence_v10540']=true

module PMD_AC
  GENERATED_EXPANSION_THRESHOLD_MS_V10540=50
  GENERATED_EXPANSION_BATCHES_V10540={
    'A'=>[27,104],
    'B'=>[105,182],
    'C'=>[183,260],
    'D'=>[261,338],
    'E'=>[339,416],
    'F'=>[417,494]
  }
  IMPORTANT_VISUAL_MARKER_V10540=File.join('Graphics','PMD','_IMPORTANT_VISUAL_V10539_PASS.txt')
  TRANSITION_VISUAL_MARKER_V10540=File.join('Graphics','PMD','_TRANSITION_VISUAL_V10540_PASS.txt')
  GENERATED_COMPLETE_MARKER_V10540=File.join('Graphics','PMD','_GENERATED_RUNTIME_V10540_COMPLETE.txt')

  class << self
    def generated_expansion_sid_v10540(n)
      sprintf('%04d',n.to_i)
    rescue
      n.to_s
    end

    def generated_expansion_batch_ids_v10540(batch)
      row=GENERATED_EXPANSION_BATCHES_V10540[batch.to_s.upcase]
      return [] if row==nil
      out=[]
      i=row[0].to_i
      while i<=row[1].to_i
        out.push(generated_expansion_sid_v10540(i))
        i+=1
      end
      out
    rescue
      []
    end

    def generated_expansion_marker_v10540?(kind)
      path=(kind==:important ? IMPORTANT_VISUAL_MARKER_V10540 : TRANSITION_VISUAL_MARKER_V10540)
      FileTest.exist?(path) rescue false
    end

    def generated_expansion_write_marker_v10540(kind,detail)
      path=(kind==:important ? IMPORTANT_VISUAL_MARKER_V10540 : TRANSITION_VISUAL_MARKER_V10540)
      text='PMD AutoChess Visual Acceptance\r\n'+
        'version=v1.05.40\r\nkind='+kind.to_s+'\r\n'+
        'detail='+detail.to_s+'\r\n'+
        'zorder_required=overlay<panel<sprite\r\n'+
        'manual_marks=0\r\n'
      File.open(path,'wb'){|f|f.write(text)}
      true
    rescue
      false
    end

    def generated_expansion_status_v10540(force=false)
      q=runtime_asset_scan_v10526(force)
      admitted=q[:admitted] || []
      generated=q[:generated] || []
      partial=q[:generated_partial] || []
      batches={}
      next_batch='complete'
      GENERATED_EXPANSION_BATCHES_V10540.keys.sort.each do |b|
        ids=generated_expansion_batch_ids_v10540(b)
        ready=ids.select{|sid|admitted.include?(sid)}
        part=ids.select{|sid|partial.include?(sid)}
        missing=ids.size-ready.size-part.size
        batches[b]={:ready=>ready.size,:total=>ids.size,:partial=>part.size,:missing=>missing}
        next_batch=b if next_batch=='complete' && ready.size<ids.size
      end
      important=generated_expansion_marker_v10540?(:important)
      transition=generated_expansion_marker_v10540?(:transition)
      visual=important && transition
      complete=(generated.size==RUNTIME_GENERATED_RANGE_V10526.size)
      {
        :scan=>q,:generated=>generated.size,:total=>RUNTIME_GENERATED_RANGE_V10526.size,
        :partial=>partial.size,:batches=>batches,:next_batch=>next_batch,
        :important_visual=>important,:transition_visual=>transition,:visual_gate=>visual,
        :generated_complete=>complete,:formal_complete=>(complete && visual)
      }
    rescue
      {:scan=>{},:generated=>0,:total=>468,:partial=>0,:batches=>{},:next_batch=>'A',
       :important_visual=>false,:transition_visual=>false,:visual_gate=>false,
       :generated_complete=>false,:formal_complete=>false}
    end

    def generated_expansion_write_complete_marker_v10540(status)
      return false if status==nil || !status[:generated_complete]
      exists=false
      begin;exists=FileTest.exist?(GENERATED_COMPLETE_MARKER_V10540);rescue;exists=false;end
      return true if exists
      File.open(GENERATED_COMPLETE_MARKER_V10540,'wb') do |f|
        f.write('PMD AutoChess Generated Runtime Asset Expansion v1.05.40\r\n')
        f.write('generated=468/468\r\n')
        f.write('admission=neutral+Attack+Hurt\r\n')
      end
      true
    rescue
      false
    end
  end
end

class Scene_PMD_AutoChess
  alias pmd_ac_v10540_generated_start_battle start_battle unless method_defined?(:pmd_ac_v10540_generated_start_battle)
  alias pmd_ac_v10540_transition_finish_v10537 representative_transition_finish_v10537 unless method_defined?(:pmd_ac_v10540_transition_finish_v10537)
  alias pmd_ac_v10540_important_finish_v10538 important_finish_v10538 unless method_defined?(:pmd_ac_v10540_important_finish_v10538)
  alias pmd_ac_v10540_generated_focus_summary focus_cast_log_summary_v1055 unless method_defined?(:pmd_ac_v10540_generated_focus_summary)

  def start_battle
    r=pmd_ac_v10540_generated_start_battle
    begin
      if respond_to?(:verification_mode) && verification_mode==:normal &&
         !(respond_to?(:production_external_battle_fast_v10613?) && production_external_battle_fast_v10613?)
        st=PMD_AC.generated_expansion_status_v10540(false)
        PMD_AC.generated_expansion_write_complete_marker_v10540(st)
        log_event(:battle,'BATTLE_GENERATED_RUNTIME_EXPANSION_V10540 START generated='+
          st[:generated].to_i.to_s+'/'+st[:total].to_i.to_s+
          ' partial='+st[:partial].to_i.to_s+
          ' complete='+(st[:generated_complete] ? '1':'0')+
          ' batches=6 batch_size=78 next_batch='+st[:next_batch].to_s+
          ' downloader=Tools/DOWNLOAD_PMD_GENERATED_RUNTIME_EXPANSION_v10540.py'+
          ' admission=neutral+Attack+Hurt motion_core_unchanged=1 gameplay_change=0')
        PMD_AC::GENERATED_EXPANSION_BATCHES_V10540.keys.sort.each do |b|
          q=st[:batches][b] || {:ready=>0,:total=>78,:partial=>0,:missing=>78}
          log_event(:battle,'BATTLE_GENERATED_RUNTIME_BATCH_V10540 batch='+b+
            ' ready='+q[:ready].to_i.to_s+'/'+q[:total].to_i.to_s+
            ' partial='+q[:partial].to_i.to_s+' missing='+q[:missing].to_i.to_s)
        end
        log_event(:battle,'BATTLE_GENERATED_RUNTIME_VISUAL_GATE_V10540 important='+
          (st[:important_visual] ? '1':'0')+' transition='+(st[:transition_visual] ? '1':'0')+
          ' visual_gate='+(st[:visual_gate] ? '1':'0')+
          ' formal_complete='+(st[:formal_complete] ? '1':'0')+
          ' next_gate='+(st[:transition_visual] ?
            (st[:generated_complete] ? 'generated_full_runtime_qa':'download_batch_'+st[:next_batch].to_s) :
            'rerun_transition_visibility_SHIFT_F7'))
      end
    rescue
    end
    r
  end

  # v1.05.39 已先驗證 Z-order；只有上一層真正回傳 visual PASS 時才寫 marker。
  def representative_transition_finish_v10537(ok,reason)
    pass=pmd_ac_v10540_transition_finish_v10537(ok,reason)
    if pass
      wrote=PMD_AC.generated_expansion_write_marker_v10540(:transition,
        'SHIFT+F7 14/14 pages 56/56 species 70/70 views marks=0 zorder=v10539')
      log_event(:battle,'BATTLE_GENERATED_RUNTIME_VISUAL_ACCEPT_V10540 kind=transition pass=1 marker='+
        (wrote ? '1':'0')+' source=v10539_visibility_seal')
    end
    pass
  rescue
    false
  end

  def important_finish_v10538(ok,reason)
    pass=pmd_ac_v10540_important_finish_v10538(ok,reason)
    if pass
      wrote=PMD_AC.generated_expansion_write_marker_v10540(:important,
        'SHIFT+F9 4/4 pages 16/16 species 40/40 views marks=0 zorder=v10539')
      log_event(:battle,'BATTLE_GENERATED_RUNTIME_VISUAL_ACCEPT_V10540 kind=important pass=1 marker='+
        (wrote ? '1':'0')+' source=v10539_visibility_seal')
    end
    pass
  rescue
    false
  end

  def focus_cast_log_summary_v1055
    r=pmd_ac_v10540_generated_focus_summary
    return r if respond_to?(:production_external_battle_fast_v10613?) && production_external_battle_fast_v10613?
    begin
      st=PMD_AC.generated_expansion_status_v10540(false)
      log_event(:battle,'BATTLE_GENERATED_RUNTIME_EXPANSION_SUMMARY_V10540 generated='+
        st[:generated].to_i.to_s+'/'+st[:total].to_i.to_s+
        ' partial='+st[:partial].to_i.to_s+
        ' next_batch='+st[:next_batch].to_s+
        ' important_visual='+(st[:important_visual] ? '1':'0')+
        ' transition_visual='+(st[:transition_visual] ? '1':'0')+
        ' visual_gate='+(st[:visual_gate] ? '1':'0')+
        ' generated_complete='+(st[:generated_complete] ? '1':'0')+
        ' formal_complete='+(st[:formal_complete] ? '1':'0')+
        ' threshold_ms='+PMD_AC::GENERATED_EXPANSION_THRESHOLD_MS_V10540.to_s+
        ' gameplay_change=0')
    rescue
    end
    r
  end
end
