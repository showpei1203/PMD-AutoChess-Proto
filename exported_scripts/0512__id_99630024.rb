# encoding: UTF-8
#===============================================================================
# ■ PMD AutoChess - Representative Runtime QA Admission Gate I v1.05.27
#===============================================================================
# 【用途】
# 1. 承接 v1.05.26 Runtime Asset Admission Authority，把 56 隻 Representative Species
#    從單一「0/56 或 56/56」數字拆成 7 個 Body Group 的可執行 readiness matrix。
# 2. NORMAL battle 直接輸出各 body group ready / partial / missing，並列出最多 12 隻
#    尚缺 neutral / Attack / Hurt 的代表物種，讓後續素材匯入與 Windows QA 有明確批次。
# 3. 建立 Representative QA Admission Gate：只有 runtime admitted 的代表物種才允許進入
#    後續 hasPlayable QA；metadata-ready 仍不可冒充 runtime-ready。
# 4. 配合 Tools/DOWNLOAD_PMD_REPRESENTATIVE_FROM_GITHUB_v10527.py，代表素材進包後不需
#    修改 Scripts.rvdata，下一次啟動即可自動更新 readiness。
# 5. 本版只新增 Resource QA / Tooling / LOG，不修改 Damage、HP、AI、Energy、Attack Wait、
#    Priority、logical Spatial x/y/velocity/endpoints、hit timing、Motion Core、Focus timing。
#
# 【主要設定／可調參數】
# REPRESENTATIVE_REPS_BY_BODY_V10527：沿用 v1.04.3 的 7 body × 8 species。
# REPRESENTATIVE_SAMPLE_LIMIT_V10527 = 12：LOG 最多列 12 隻缺件樣本。
# REPRESENTATIVE_GATE_REQUIRED_V10527 = [:neutral, :attack, :hurt]。
#
# 【機制規則】
# - ready：v1.05.26 runtime_asset_admitted_v10526? = true。
# - partial：Graphics/PMD/#### 已存在，但缺 neutral / Attack / Hurt 其中至少一項。
# - missing：資料夾不存在。
# - group_ready：該 body group 8/8 admitted。
# - representative_complete：56/56 admitted；未達成時是 pending，不宣告 FAIL。
# - 0001～0026 curated runtime 不在本層 Representative Gate 範圍內。
#
# 【依賴／載入順序】
# - 必須載於 v1.05.26 後、Main 前。
# - 使用 PMD_AC.runtime_asset_row_v10526 / runtime_asset_scan_v10526。
# - Representative group 優先讀 v1.04.3 MOTION_REPRESENTATIVE_REPS_BY_BODY_V1043。
# - 不直接修改 Frozen Combat Core。
#
# 【事件／腳本呼叫方式】
# - NORMAL battle 自動輸出 readiness，無需事件呼叫。
# - 腳本查詢：PMD_AC.representative_runtime_matrix_v10527
# - 單隻查詢：PMD_AC.representative_runtime_detail_v10527('0027')
#
# 【LOG】
# BATTLE_REPRESENTATIVE_RUNTIME_QA_V10527 ...
# BATTLE_REPRESENTATIVE_RUNTIME_GROUP_V10527 body=small ready=.../8 ...
# BATTLE_REPRESENTATIVE_RUNTIME_PENDING_V10527 samples=[...]
# BATTLE_REPRESENTATIVE_RUNTIME_QA_SUMMARY_V10527 ...
#
# 【實際範例】
# - 目前只打包 0001～0026 時：ready=0/56 missing=56 gate=open_pending，不是假 FAIL。
# - 下載器先匯入 small group 8 隻後：small=8/8，其餘 group 仍 pending。
# - 56/56 admitted 後：gate=ready，下一階段即可跑真正 896 route Representative QA。
#===============================================================================
$imported={} unless defined?($imported)
$imported['PMD_AutoChess_RepresentativeRuntimeQA_AdmissionGate_v10527']=true

module PMD_AC
  REPRESENTATIVE_SAMPLE_LIMIT_V10527=12
  REPRESENTATIVE_GATE_REQUIRED_V10527=[:neutral,:attack,:hurt]

  class << self
    def representative_reps_by_body_v10527
      begin
        if const_defined?(:MOTION_REPRESENTATIVE_REPS_BY_BODY_V1043)
          out={}
          MOTION_REPRESENTATIVE_REPS_BY_BODY_V1043.each do |body,sids|
            out[body]=sids.collect{|sid|sid.to_s}
          end
          return out
        end
      rescue
      end
      {}
    end

    def representative_runtime_detail_v10527(sid)
      row=runtime_asset_row_v10526(sid.to_s)
      missing=[]
      missing.push(:neutral) unless row[:neutral]
      missing.push(:attack) unless row[:attack]
      missing.push(:hurt) unless row[:hurt]
      state=row[:admitted] ? :ready : (row[:present] ? :partial : :missing)
      {:sid=>sid.to_s,:state=>state,:missing=>missing,:faint=>row[:faint],
       :present=>row[:present],:admitted=>row[:admitted]}
    rescue
      {:sid=>sid.to_s,:state=>:missing,:missing=>REPRESENTATIVE_GATE_REQUIRED_V10527.dup,
       :faint=>false,:present=>false,:admitted=>false}
    end

    def representative_runtime_matrix_v10527
      groups=representative_reps_by_body_v10527
      rows={};ready=0;partial=0;missing=0;pending=[];group_ready=0
      groups.each do |body,sids|
        gr=0;gp=0;gm=0;details=[]
        sids.each do |sid|
          d=representative_runtime_detail_v10527(sid)
          details.push(d)
          case d[:state]
          when :ready;gr+=1;ready+=1
          when :partial;gp+=1;partial+=1;pending.push(d)
          else;gm+=1;missing+=1;pending.push(d)
          end
        end
        group_ready+=1 if gr==sids.size && sids.size>0
        rows[body]={:total=>sids.size,:ready=>gr,:partial=>gp,:missing=>gm,:details=>details}
      end
      total=ready+partial+missing
      {:groups=>rows,:total=>total,:ready=>ready,:partial=>partial,:missing=>missing,
       :pending=>pending,:group_ready=>group_ready,:group_total=>groups.size,
       :complete=>(total>0 && ready==total)}
    rescue
      {:groups=>{},:total=>0,:ready=>0,:partial=>0,:missing=>0,:pending=>[],
       :group_ready=>0,:group_total=>0,:complete=>false}
    end

    def representative_pending_sample_v10527(matrix=nil)
      m=matrix || representative_runtime_matrix_v10527
      out=[]
      m[:pending][0,REPRESENTATIVE_SAMPLE_LIMIT_V10527].each do |d|
        miss=d[:missing].collect{|x|x.to_s}.join('+')
        out.push(d[:sid]+':'+d[:state].to_s+':'+miss)
      end
      out
    rescue
      []
    end
  end
end

class Scene_PMD_AutoChess
  alias pmd_ac_v10527_start_battle start_battle unless method_defined?(:pmd_ac_v10527_start_battle)
  alias pmd_ac_v10527_focus_summary focus_cast_log_summary_v1055 unless method_defined?(:pmd_ac_v10527_focus_summary)

  def start_battle
    r=pmd_ac_v10527_start_battle
    begin
      if respond_to?(:verification_mode) && verification_mode==:normal &&
         !(respond_to?(:production_external_battle_fast_v10613?) && production_external_battle_fast_v10613?)
        m=PMD_AC.representative_runtime_matrix_v10527
        gate=m[:complete] ? 'ready' : 'open_pending'
        log_event(:battle,'BATTLE_REPRESENTATIVE_RUNTIME_QA_V10527 ready='+m[:ready].to_s+'/'+m[:total].to_s+
          ' partial='+m[:partial].to_s+' missing='+m[:missing].to_s+
          ' body_groups='+m[:group_ready].to_s+'/'+m[:group_total].to_s+
          ' gate='+gate+' false_playable_claim=0 gameplay_change=0')
        m[:groups].each do |body,g|
          log_event(:battle,'BATTLE_REPRESENTATIVE_RUNTIME_GROUP_V10527 body='+body.to_s+
            ' ready='+g[:ready].to_s+'/'+g[:total].to_s+' partial='+g[:partial].to_s+
            ' missing='+g[:missing].to_s)
        end
        sample=PMD_AC.representative_pending_sample_v10527(m)
        if sample.size>0
          log_event(:battle,'BATTLE_REPRESENTATIVE_RUNTIME_PENDING_V10527 samples=['+sample.join(',')+']'+
            ' downloader=Tools/DOWNLOAD_PMD_REPRESENTATIVE_FROM_GITHUB_v10527.py')
        end
      end
    rescue
    end
    r
  end

  def representative_runtime_summary_v10527
    m=PMD_AC.representative_runtime_matrix_v10527
    log_event(:battle,'BATTLE_REPRESENTATIVE_RUNTIME_QA_SUMMARY_V10527 ready='+m[:ready].to_s+'/'+m[:total].to_s+
      ' partial='+m[:partial].to_s+' missing='+m[:missing].to_s+
      ' groups='+m[:group_ready].to_s+'/'+m[:group_total].to_s+
      ' representative_complete='+(m[:complete] ? '1':'0')+
      ' next_gate='+(m[:complete] ? 'runtime_route_qa_896':'asset_import')+
      ' importer_local=Tools/IMPORT_PMD_RUNTIME_ASSETS_v10526.py'+
      ' downloader_github=Tools/DOWNLOAD_PMD_REPRESENTATIVE_FROM_GITHUB_v10527.py'+
      ' gameplay_change=0')
    true
  rescue
    false
  end

  def focus_cast_log_summary_v1055
    r=pmd_ac_v10527_focus_summary
    return r if respond_to?(:production_external_battle_fast_v10613?) && production_external_battle_fast_v10613?
    representative_runtime_summary_v10527
    r
  end
end
