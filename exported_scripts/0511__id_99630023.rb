# encoding: UTF-8
#===============================================================================
# ■ PMD AutoChess - Runtime Asset Admission I + Focus Policy Seal v1.05.26
#===============================================================================
# 【用途】
# 1. 承接 v1.05.25 Focus Fatigue Observer 的 Windows 實機證據，正式記錄 Phase B2
#    目前政策：保留既有 Full Focus timing，不啟用 repeat-skill compression。
# 2. 建立 0001～0494 PMD Runtime Asset Admission Authority。Generated profile / compiled
#    metadata 只代表資料已準備，不再被誤當成 runtime playable；只有實際打包進
#    Graphics/PMD/#### 且具備最低必要動作的物種才算 admitted。
# 3. 讓 0027～0494 日後只要把 PMDCollab runtime 圖片放進專案，就能自動進入既有
#    motion router / generated profile，不需要再為每隻物種新增一層硬編碼開關。
# 4. 對 v1.04.3 的 56 隻 Representative QA 另外輸出 runtime readiness，讓後續真正
#    匯入素材後可以立刻知道代表物種覆蓋率，而不是靠 marker 自我宣告。
# 5. 本版只做 Resource Admission / Observer / Tooling；Damage、HP、AI、Energy、
#    Attack Wait、Priority、logical Spatial x/y/velocity/endpoints、hit timing、Motion
#    Core、Focus timing 全部不修改。
#
# 【Runtime Asset Admission 規則】
# - folder_present：Graphics/PMD/#### 實際存在。
# - neutral_ready：至少有 Idle-Anim.png / Walk-Anim.png / Float-Anim.png 其中一個。
# - attack_ready：Attack-Anim.png 存在。
# - hurt_ready：Hurt-Anim.png 存在。
# - admitted = folder_present && neutral_ready && attack_ready && hurt_ready。
# - Faint-Anim.png 為 optional 指標，因既有 Runtime 允許死亡 presentation fallback；
#   缺 Faint 不會把整隻物種判成不可用。
# - 0001～0026 curated runtime 與 0027～0494 generated runtime 使用同一 admission 定義，
#   但 generated profile 的 Motion source priority 仍由 v1.04.x 系列擁有。
#
# 【Focus Phase B2 決策】
# v1.05.25 Windows 兩場 evidence：
# - casts_per_1000f = 9.5 / 9.5
# - repeat_global = 0 / 0
# - repeat_owner_window = 0 / 0
# - max_same_skill_chain = 1 / 1
# 因此目前不啟用 repeat compression。Observer 繼續保留，等更高階／Boss 戰資料出現
# 再判斷是否需要處理「整體 Standard Focus 密度」，而不是先砍不存在的重複招問題。
#
# 【主要設定／可調參數】
# RUNTIME_ASSET_RANGE_V10526 = 1..494
# RUNTIME_GENERATED_RANGE_V10526 = 27..494
# RUNTIME_REQUIRED_NEUTRAL_V10526 = [Idle, Walk, Float]
# RUNTIME_REQUIRED_CORE_V10526 = [Attack, Hurt]
# RUNTIME_ASSET_SCAN_CACHE_V10526：每個遊戲 session 只掃一次，避免反覆 File I/O。
#
# 【依賴／載入順序】
# - 必須載於 v1.05.25 後、Main 前。
# - 可使用 v1.05.22a 的 executable_root；若不存在則回退 Dir.pwd。
# - Representative 清單優先沿用 v1.04.3 MOTION_REPRESENTATIVE_REPS_BY_BODY_V1043。
# - 不直接修改 Frozen Combat Core。
#
# 【事件／腳本呼叫方式】
# - NORMAL battle 自動輸出 Admission summary，無需事件呼叫。
# - 腳本查詢：PMD_AC.runtime_asset_admitted_v10526?('0027')
# - 強制重掃：PMD_AC.runtime_asset_scan_v10526(true)
#
# 【LOG】
# BATTLE_FOCUS_POLICY_V10526 ...
# BATTLE_RUNTIME_ASSET_ADMISSION_V10526 packaged=... admitted=... generated=... reps=...
# BATTLE_RUNTIME_ASSET_ADMISSION_SAMPLE_V10526 ...
# BATTLE_RUNTIME_ASSET_ADMISSION_SUMMARY_V10526 ...
#
# 【實際範例】
# 1. 專案尚只有 0001～0026：generated_admitted=0/468，deferred=1，這是正確狀態。
# 2. 把 0027 的 Idle/Attack/Hurt 等 runtime 圖片放進 Graphics/PMD/0027 後，下一次
#    啟動遊戲會自動得到 generated_admitted>=1，不需要修改 Scripts.rvdata。
# 3. 若只放資料表而沒有 PNG，0027 仍只有 metadata_ready，不會偽裝成 playable。
#===============================================================================
$imported={} unless defined?($imported)
$imported['PMD_AutoChess_RuntimeAssetAdmission_FocusPolicy_v10526']=true

module PMD_AC
  RUNTIME_ASSET_RANGE_V10526=(1..494).to_a.collect{|i|'%04d'%i}
  RUNTIME_GENERATED_RANGE_V10526=(27..494).to_a.collect{|i|'%04d'%i}
  RUNTIME_REQUIRED_NEUTRAL_V10526=['Idle-Anim.png','Walk-Anim.png','Float-Anim.png']
  RUNTIME_REQUIRED_CORE_V10526=['Attack-Anim.png','Hurt-Anim.png']

  class << self
    alias pmd_ac_v10526_motion_source_route motion_source_route_v102 unless method_defined?(:pmd_ac_v10526_motion_source_route)

    def motion_source_route_v102(species,move_key,data=nil,profile=nil)
      r=pmd_ac_v10526_motion_source_route(species,move_key,data,profile)
      sid=species.to_s
      if RUNTIME_GENERATED_RANGE_V10526.include?(sid) && !runtime_asset_admitted_v10526?(sid)
        out=r==nil ? {} : r.dup
        out[:has_playable]=false
        out[:selected]=nil
        out[:fallback]=true
        return out
      end
      r
    rescue
      {:family=>:strike,:selected=>nil,:has_native=>false,:has_playable=>false,:fallback=>true}
    end

    def runtime_project_root_v10526
      begin
        if defined?(PMDACCharacterResourceGuardV10522A)
          return PMDACCharacterResourceGuardV10522A.executable_root
        end
      rescue
      end
      Dir.pwd
    rescue
      '.'
    end

    def runtime_pmd_root_v10526
      File.join(runtime_project_root_v10526,'Graphics','PMD')
    rescue
      File.join('Graphics','PMD')
    end

    def runtime_asset_file_v10526(sid,name)
      File.join(runtime_pmd_root_v10526,sid.to_s,name.to_s)
    rescue
      ''
    end

    def runtime_asset_row_v10526(sid)
      sid=sid.to_s
      folder=File.join(runtime_pmd_root_v10526,sid)
      present=FileTest.directory?(folder) rescue false
      neutral=false
      if present
        RUNTIME_REQUIRED_NEUTRAL_V10526.each do |name|
          exists=false
          begin;exists=FileTest.exist?(File.join(folder,name));rescue;exists=false;end
          if exists
            neutral=true
            break
          end
        end
      end
      attack=present && (FileTest.exist?(File.join(folder,'Attack-Anim.png')) rescue false)
      hurt=present && (FileTest.exist?(File.join(folder,'Hurt-Anim.png')) rescue false)
      faint=present && (FileTest.exist?(File.join(folder,'Faint-Anim.png')) rescue false)
      admitted=present && neutral && attack && hurt
      {:sid=>sid,:present=>present,:neutral=>neutral,:attack=>attack,:hurt=>hurt,
       :faint=>faint,:admitted=>admitted}
    rescue
      {:sid=>sid.to_s,:present=>false,:neutral=>false,:attack=>false,:hurt=>false,
       :faint=>false,:admitted=>false}
    end

    def runtime_representative_ids_v10526
      begin
        if const_defined?(:MOTION_REPRESENTATIVE_REPS_BY_BODY_V1043)
          out=[]
          MOTION_REPRESENTATIVE_REPS_BY_BODY_V1043.each_value{|a|a.each{|sid|out.push(sid.to_s)}}
          return out.uniq
        end
      rescue
      end
      []
    end

    def runtime_asset_scan_v10526(force=false)
      return @runtime_asset_scan_v10526 if !force && @runtime_asset_scan_v10526!=nil
      ids=[]
      begin
        Dir.glob(File.join(runtime_pmd_root_v10526,'[0-9][0-9][0-9][0-9]')).each do |path|
          sid=File.basename(path).to_s
          ids.push(sid) if RUNTIME_ASSET_RANGE_V10526.include?(sid)
        end
      rescue
      end
      ids=ids.uniq.sort
      admitted=[];partial=[];faint=[]
      ids.each do |sid|
        row=runtime_asset_row_v10526(sid)
        if row[:admitted]
          admitted.push(sid)
          faint.push(sid) if row[:faint]
        else
          partial.push(sid)
        end
      end
      generated=admitted.select{|sid|RUNTIME_GENERATED_RANGE_V10526.include?(sid)}
      reps=runtime_representative_ids_v10526
      reps_ready=reps.select{|sid|admitted.include?(sid)}
      generated_partial=partial.select{|sid|RUNTIME_GENERATED_RANGE_V10526.include?(sid)}
      @runtime_asset_scan_v10526={
        :packaged=>ids,:admitted=>admitted,:partial=>partial,:faint=>faint,
        :generated=>generated,:generated_partial=>generated_partial,
        :reps=>reps,:reps_ready=>reps_ready,
        :generated_complete=>(generated.size==RUNTIME_GENERATED_RANGE_V10526.size),
        :representative_complete=>(reps.size>0 && reps_ready.size==reps.size)
      }
      @runtime_asset_scan_v10526
    rescue
      @runtime_asset_scan_v10526={:packaged=>[],:admitted=>[],:partial=>[],:faint=>[],
        :generated=>[],:generated_partial=>[],:reps=>[],:reps_ready=>[],
        :generated_complete=>false,:representative_complete=>false}
    end

    def runtime_asset_admitted_v10526?(sid)
      q=runtime_asset_scan_v10526(false)
      q[:admitted].include?(sid.to_s)
    rescue
      false
    end
  end
end

class Scene_PMD_AutoChess
  alias pmd_ac_v10526_start_battle start_battle unless method_defined?(:pmd_ac_v10526_start_battle)
  alias pmd_ac_v10526_focus_summary focus_cast_log_summary_v1055 unless method_defined?(:pmd_ac_v10526_focus_summary)

  def start_battle
    r=pmd_ac_v10526_start_battle
    begin
      if respond_to?(:verification_mode) && verification_mode==:normal
        q=PMD_AC.runtime_asset_scan_v10526(false)
        reps=q[:reps].size
        rep_ready=q[:reps_ready].size
        gen=q[:generated].size
        gen_total=PMD_AC::RUNTIME_GENERATED_RANGE_V10526.size
        log_event(:battle,'BATTLE_FOCUS_POLICY_V10526 current_policy=preserve_full_focus'+
          ' repeat_compression=0 observer_v10525_retained=1 standard_precharge=48'+
          ' evidence_repeat_global=0 evidence_repeat_owner_window=0'+
          ' overall_density_watch=1 behavior_change=0')
        log_event(:battle,'BATTLE_RUNTIME_ASSET_ADMISSION_V10526 packaged='+q[:packaged].size.to_s+
          ' admitted='+q[:admitted].size.to_s+' partial='+q[:partial].size.to_s+
          ' generated_admitted='+gen.to_s+'/'+gen_total.to_s+
          ' representatives='+rep_ready.to_s+'/'+reps.to_s+
          ' faint_native='+q[:faint].size.to_s+'/'+q[:admitted].size.to_s+
          ' generated_complete='+(q[:generated_complete] ? '1':'0')+
          ' representative_complete='+(q[:representative_complete] ? '1':'0')+
          ' deferred='+(q[:generated_complete] ? '0':'1')+
          ' false_playable_claim=0')
        if gen>0 || q[:generated_partial].size>0
          sample=(q[:generated][0,8]||[]).join(',')
          bad=(q[:generated_partial][0,8]||[]).join(',')
          log_event(:battle,'BATTLE_RUNTIME_ASSET_ADMISSION_SAMPLE_V10526 admitted=['+sample+'] partial=['+bad+']')
        end
      end
    rescue
    end
    r
  end

  def runtime_asset_admission_summary_v10526
    q=PMD_AC.runtime_asset_scan_v10526(false)
    log_event(:battle,'BATTLE_RUNTIME_ASSET_ADMISSION_SUMMARY_V10526 packaged='+q[:packaged].size.to_s+
      ' admitted='+q[:admitted].size.to_s+' generated='+q[:generated].size.to_s+'/'+
      PMD_AC::RUNTIME_GENERATED_RANGE_V10526.size.to_s+
      ' reps='+q[:reps_ready].size.to_s+'/'+q[:reps].size.to_s+
      ' generated_partial='+q[:generated_partial].size.to_s+
      ' importer=Tools/IMPORT_PMD_RUNTIME_ASSETS_v10526.py'+
      ' gameplay_change=0')
    true
  rescue
    false
  end

  def focus_cast_log_summary_v1055
    r=pmd_ac_v10526_focus_summary
    runtime_asset_admission_summary_v10526
    r
  rescue
    false
  end
end
