# encoding: UTF-8
#===============================================================================
# ■ PMD AutoChess - Representative Runtime Route QA + Group Tuning Audit v1.05.28
#===============================================================================
# 【用途】
# 1. 承接 v1.05.27 已匯入的 56 隻 Representative Species，正式對 7 body × 8 species
#    × 16 motion family = 896 routes 執行「真實 Runtime Router」QA。
# 2. QA 直接呼叫現行 motion_source_route_v102，因此同時驗證 hasPlayable、family、
#    strict-45 geometry、selected pose、fallback，而不是只看 metadata 或檔名。
# 3. 為避免在戰鬥開始瞬間一次掃 896 routes，本版在 NORMAL battle 每 frame 最多掃
#    16 routes；記錄每 tick 耗時與 max_ms，50ms Performance threshold 不放寬。
# 4. 依 body × family 統計 fallback / generic Attack 熱點，並檢查「素材其實有更合適
#    Native pose」的 Group Tuning Candidate。v1.05.28 只 Audit，不改 candidate order；
#    等 Windows 實機證據後再做下一批正式 Group Tuning，避免憑空改 Motion。
# 5. 修正 v1.05.27 完整包的 packaging omission：v1.05.27 外部腳本存在，但舊
#    Scripts.rvdata 未嵌入。本版 build 會先正式嵌入 v1.05.27，再嵌入本腳本。
#
# 【主要設定】
# REPRESENTATIVE_ROUTE_QA_PER_TICK_V10528 = 16
#   每 frame 最多掃 16 routes；896 routes 約 56 frames 完成。
# REPRESENTATIVE_ROUTE_QA_THRESHOLD_MS_V10528 = 50
#   單 tick QA Performance threshold，沿用全專案 50ms 規格。
# REPRESENTATIVE_ROUTE_BAD_SAMPLE_V10528 = 16
#   LOG 最多列 16 條真正失敗 route。
# REPRESENTATIVE_TUNING_SAMPLE_V10528 = 16
#   LOG 最多列 16 條「generic Attack 但存在安全替代」candidate。
#
# 【機制規則】
# - Gate 0：PMD_AC.representative_runtime_matrix_v10527 必須 56/56 complete。
# - Gate 1 PASS：routes=896、playable=896、strict45=896、family_match=896。
# - fallback / selected=:attack 不直接算 FAIL；它是 Group Tuning 品質指標。
# - tuning candidate 必須同時：
#   A. pose 本身 playable；B. strict45；C. Anatomy Gate；D. Semantic Gate。
# - 只掃 Representative 56 隻；0001～0026 curated Motion 不修改。
# - 不改 Damage、HP、AI、Energy、Attack Wait、Priority、logical Spatial、hit timing。
# - 不改 Frozen Motion Core；本版 behavior_change=0。
#
# 【依賴／載入順序】
# - 必須載於 v1.05.27 後、Main 前。
# - 使用 v1.04.3 Representative groups / 16 family cases。
# - 使用 v1.05.26 Runtime Asset Admission Authority。
# - 使用 v1.05.27 Representative Runtime Admission Gate。
# - 若 v1.04.3 Anatomy Gate / v1.04.4 Semantic Gate 存在，tuning audit 必須通過兩者。
#
# 【事件／腳本呼叫方式】
# - NORMAL battle 自動開始分幀 QA，不需按鍵、不增加 S-menu verifier。
# - 腳本查詢目前狀態：PMD_AC.representative_route_qa_state_v10528
# - 強制重跑：PMD_AC.representative_route_qa_reset_v10528
#
# 【LOG】
# BATTLE_REPRESENTATIVE_ROUTE_QA_V10528 START/CACHED/PENDING ...
# BATTLE_REPRESENTATIVE_ROUTE_QA_SUMMARY_V10528 ...
# BATTLE_REPRESENTATIVE_ROUTE_GROUP_V10528 body=... routes=128 ...
# BATTLE_REPRESENTATIVE_ROUTE_HOTSPOT_V10528 ...
# BATTLE_REPRESENTATIVE_TUNING_CANDIDATE_V10528 ...
#
# 【實際範例】
# - 0095（serpentine）Punch family 若最後安全回到 Attack，route 仍可 PASS；若同時
#   Swing 可播、strict45 且通過 Anatomy/Semantic Gate，會列為下一版 tuning candidate，
#   但 v1.05.28 不會偷偷把它換成 Swing。
# - 代表素材完整時，NORMAL battle 約 56 frames 後應得到 896-route summary。
#===============================================================================
$imported={} unless defined?($imported)
$imported['PMD_AutoChess_RepresentativeRuntimeRouteQA_GroupTuningAudit_v10528']=true

module PMD_AC
  REPRESENTATIVE_ROUTE_QA_PER_TICK_V10528=16
  REPRESENTATIVE_ROUTE_QA_THRESHOLD_MS_V10528=50
  REPRESENTATIVE_ROUTE_BAD_SAMPLE_V10528=16
  REPRESENTATIVE_TUNING_SAMPLE_V10528=16

  REPRESENTATIVE_TUNING_PREFS_V10528={
    :small=>{
      :dash=>[:double,:swing],:lunge=>[:double,:swing],:multi=>[:double],:spin=>[:rotate],
      :projectile=>[:shoot,:charge],:beam=>[:shoot,:charge],:cast=>[:charge,:shoot],
      :shock=>[:shoot,:charge],:drain=>[:shoot,:charge],:sound=>[:rear_up,:rumble,:charge]
    },
    :medium=>{
      :dash=>[:double,:swing],:lunge=>[:double,:swing],:multi=>[:double],:spin=>[:rotate],
      :projectile=>[:shoot,:charge],:beam=>[:shoot,:charge],:cast=>[:charge,:shoot],
      :shock=>[:shoot,:charge],:drain=>[:shoot,:charge],:sound=>[:rear_up,:rumble,:charge]
    },
    :quadruped=>{
      :dash=>[:double,:swing],:lunge=>[:double,:swing],:multi=>[:double],:spin=>[:rotate],
      :projectile=>[:shoot,:charge],:beam=>[:shoot,:charge],:cast=>[:charge,:shoot],
      :shock=>[:shock,:shoot,:charge],:drain=>[:shoot,:charge],:sound=>[:rear_up,:rumble,:charge]
    },
    :heavy=>{
      :lunge=>[:swing,:double],:multi=>[:double],:spin=>[:rotate],
      :projectile=>[:shoot,:charge],:beam=>[:shoot,:charge],:cast=>[:charge,:shoot],
      :shock=>[:shoot,:charge],:drain=>[:charge,:shoot],:sound=>[:rumble,:rear_up,:charge]
    },
    :hover=>{
      :dash=>[:double,:swing],:lunge=>[:double,:swing],:multi=>[:double],:spin=>[:rotate],
      :projectile=>[:shoot,:charge],:beam=>[:shoot,:charge],:cast=>[:charge,:shoot],
      :shock=>[:shoot,:charge],:drain=>[:shoot,:charge],:sound=>[:rear_up,:charge]
    },
    :avian=>{
      :dash=>[:double,:swing],:lunge=>[:double,:swing],:multi=>[:double],:spin=>[:rotate],
      :projectile=>[:shoot,:charge],:beam=>[:shoot,:charge],:cast=>[:charge,:shoot],
      :shock=>[:shoot,:charge],:drain=>[:shoot,:charge],:sound=>[:rear_up,:charge]
    },
    :serpentine=>{
      :strike=>[:swing,:double],:dash=>[:swing,:double],:lunge=>[:swing,:double],
      :punch=>[:swing,:double],:kick=>[:swing,:double],:multi=>[:double,:swing],:spin=>[:rotate],
      :projectile=>[:shoot,:charge],:beam=>[:shoot,:charge],:cast=>[:charge,:shoot],
      :shock=>[:shoot,:charge],:drain=>[:shoot,:charge],:sound=>[:rear_up,:charge]
    }
  }

  class << self
    def representative_route_qa_state_v10528
      @representative_route_qa_v10528
    end

    def representative_route_qa_reset_v10528
      @representative_route_qa_v10528=nil
      true
    rescue
      false
    end

    def representative_route_qa_queue_v10528
      out=[]
      groups=representative_reps_by_body_v10527
      cases=const_defined?(:MOTION_REPRESENTATIVE_FAMILY_CASES_V1043) ? MOTION_REPRESENTATIVE_FAMILY_CASES_V1043 : []
      groups.each do |body,sids|
        sids.each do |sid|
          cases.each do |row|
            out.push([body,sid.to_s,row[0],row[1],row[2],row[3]])
          end
        end
      end
      out
    rescue
      []
    end

    def representative_route_group_row_v10528(state,body)
      state[:groups][body] ||= {:routes=>0,:playable=>0,:strict=>0,:family=>0,:fallback=>0,:attack=>0,:native=>0}
      state[:groups][body]
    end

    def representative_route_hotkey_v10528(body,family)
      body.to_s+':'+family.to_s
    end

    def representative_tuning_pose_safe_v10528(sid,pose,family)
      return false if pose==nil || pose==:attack
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

    def representative_tuning_candidate_v10528(sid,body,family)
      prefs=REPRESENTATIVE_TUNING_PREFS_V10528[body] || {}
      list=prefs[family] || []
      list.each do |pose|
        return pose if representative_tuning_pose_safe_v10528(sid,pose,family)
      end
      nil
    rescue
      nil
    end

    def representative_route_qa_prepare_v10528
      old=@representative_route_qa_v10528
      return old if old!=nil && old[:complete]
      matrix=representative_runtime_matrix_v10527
      unless matrix[:complete]
        @representative_route_qa_v10528={:ready=>false,:complete=>false,:pending=>true,
          :total=>0,:done=>0,:queue=>[],:groups=>{},:bad=>[],:tuning=>[],:hot=>{},
          :playable=>0,:strict=>0,:family=>0,:fallback=>0,:attack=>0,:native=>0,
          :tick_max_ms=>0,:ticks=>0,:over_threshold=>0,:pass=>false}
        return @representative_route_qa_v10528
      end
      q=representative_route_qa_queue_v10528
      @representative_route_qa_v10528={:ready=>true,:complete=>false,:pending=>false,
        :total=>q.size,:done=>0,:queue=>q,:groups=>{},:bad=>[],:tuning=>[],:hot=>{},
        :playable=>0,:strict=>0,:family=>0,:fallback=>0,:attack=>0,:native=>0,
        :tick_max_ms=>0,:ticks=>0,:over_threshold=>0,:pass=>false}
      @representative_route_qa_v10528
    rescue
      @representative_route_qa_v10528={:ready=>false,:complete=>false,:pending=>true,
        :total=>0,:done=>0,:queue=>[],:groups=>{},:bad=>['prepare_exception'],:tuning=>[],:hot=>{},
        :playable=>0,:strict=>0,:family=>0,:fallback=>0,:attack=>0,:native=>0,
        :tick_max_ms=>0,:ticks=>0,:over_threshold=>0,:pass=>false}
    end

    def representative_route_qa_tick_v10528
      s=@representative_route_qa_v10528 || representative_route_qa_prepare_v10528
      return s if s==nil || !s[:ready] || s[:complete]
      t0=Time.now
      count=0
      while count<REPRESENTATIVE_ROUTE_QA_PER_TICK_V10528 && s[:done]<s[:total]
        row=s[:queue][s[:done]]
        body=row[0];sid=row[1];expected=row[2]
        r=motion_source_route_v102(sid,row[3],row[4],row[5])
        selected=r==nil ? nil : r[:selected]
        playable=r!=nil && r[:has_playable]
        family_ok=r!=nil && r[:family]==expected
        strict_ok=false
        begin
          strict_ok=selected!=nil && motion_generated_diag_geometry_v1040?(sid,selected)
        rescue
          strict_ok=false
        end
        fallback=r!=nil && r[:fallback]
        native=r!=nil && r[:selected_native]
        attack=(selected==:attack)
        s[:playable]+=1 if playable
        s[:strict]+=1 if strict_ok
        s[:family]+=1 if family_ok
        s[:fallback]+=1 if fallback
        s[:native]+=1 if native
        s[:attack]+=1 if attack
        g=representative_route_group_row_v10528(s,body)
        g[:routes]+=1;g[:playable]+=1 if playable;g[:strict]+=1 if strict_ok;g[:family]+=1 if family_ok
        g[:fallback]+=1 if fallback;g[:native]+=1 if native;g[:attack]+=1 if attack
        if fallback
          hk=representative_route_hotkey_v10528(body,expected)
          s[:hot][hk]=s[:hot][hk].to_i+1
        end
        if (!playable || !family_ok || !strict_ok) && s[:bad].size<REPRESENTATIVE_ROUTE_BAD_SAMPLE_V10528
          s[:bad].push(sid+':'+expected.to_s+'='+(selected==nil ? 'nil' : selected.to_s)+
            ':p'+(playable ? '1':'0')+'s'+(strict_ok ? '1':'0')+'f'+(family_ok ? '1':'0'))
        end
        if attack && s[:tuning].size<REPRESENTATIVE_TUNING_SAMPLE_V10528
          alt=representative_tuning_candidate_v10528(sid,body,expected)
          if alt!=nil
            s[:tuning].push(sid+':'+body.to_s+':'+expected.to_s+'=attack>'+alt.to_s)
          end
        end
        s[:done]+=1;count+=1
      end
      ms=((Time.now-t0)*1000.0).round
      s[:ticks]+=1
      s[:tick_max_ms]=ms if ms>s[:tick_max_ms].to_i
      s[:over_threshold]+=1 if ms>REPRESENTATIVE_ROUTE_QA_THRESHOLD_MS_V10528
      if s[:done]>=s[:total]
        s[:complete]=true
        s[:pass]=(s[:total]==896 && s[:playable]==896 && s[:strict]==896 && s[:family]==896 && s[:over_threshold]==0)
      end
      s
    rescue
      s[:complete]=true if s!=nil
      s[:pass]=false if s!=nil
      s[:bad].push('tick_exception') if s!=nil && s[:bad].size<REPRESENTATIVE_ROUTE_BAD_SAMPLE_V10528
      s
    end

    def representative_route_hotspots_v10528(state=nil,limit=10)
      s=state || @representative_route_qa_v10528
      return [] if s==nil
      rows=s[:hot].to_a.sort{|a,b| b[1].to_i<=>a[1].to_i}
      rows[0,limit] || []
    rescue
      []
    end
  end
end

class Scene_PMD_AutoChess
  alias pmd_ac_v10528_start_battle start_battle unless method_defined?(:pmd_ac_v10528_start_battle)
  alias pmd_ac_v10528_update update unless method_defined?(:pmd_ac_v10528_update)
  alias pmd_ac_v10528_focus_summary focus_cast_log_summary_v1055 unless method_defined?(:pmd_ac_v10528_focus_summary)

  def start_battle
    r=pmd_ac_v10528_start_battle
    begin
      if respond_to?(:verification_mode) && verification_mode==:normal &&
         !(respond_to?(:production_external_battle_fast_v10613?) && production_external_battle_fast_v10613?)
        s=PMD_AC.representative_route_qa_prepare_v10528
        @representative_route_reported_v10528=false
        if !s[:ready]
          log_event(:battle,'BATTLE_REPRESENTATIVE_ROUTE_QA_V10528 PENDING gate0=0'+
            ' ready=0 behavior_change=0 next=representative_asset_admission')
        elsif s[:complete]
          log_event(:battle,'BATTLE_REPRESENTATIVE_ROUTE_QA_V10528 CACHED routes='+s[:total].to_s+
            ' pass='+(s[:pass] ? '1':'0')+' behavior_change=0')
          representative_route_qa_log_v10528(s)
        else
          log_event(:battle,'BATTLE_REPRESENTATIVE_ROUTE_QA_V10528 START gate0=1 reps=56 groups=7'+
            ' routes='+s[:total].to_s+' per_tick='+PMD_AC::REPRESENTATIVE_ROUTE_QA_PER_TICK_V10528.to_s+
            ' threshold_ms='+PMD_AC::REPRESENTATIVE_ROUTE_QA_THRESHOLD_MS_V10528.to_s+
            ' runtime_router=1 group_tuning=audit_only behavior_change=0')
        end
      end
    rescue
    end
    r
  end

  def update
    pmd_ac_v10528_update
    begin
      return unless respond_to?(:verification_mode) && verification_mode==:normal
      return if respond_to?(:production_external_battle_fast_v10613?) && production_external_battle_fast_v10613?
      s=PMD_AC.representative_route_qa_state_v10528
      return if s==nil || !s[:ready] || s[:complete] && @representative_route_reported_v10528
      was=s[:complete]
      s=PMD_AC.representative_route_qa_tick_v10528 unless s[:complete]
      if s!=nil && s[:complete] && !@representative_route_reported_v10528
        representative_route_qa_log_v10528(s)
      end
    rescue
    end
  end

  def representative_route_qa_log_v10528(s=nil)
    s ||= PMD_AC.representative_route_qa_state_v10528
    return false if s==nil || !s[:complete]
    log_event(:battle,'BATTLE_REPRESENTATIVE_ROUTE_QA_SUMMARY_V10528 pass='+(s[:pass] ? '1':'0')+
      ' routes='+s[:total].to_s+'/896 playable='+s[:playable].to_s+'/896'+
      ' strict45='+s[:strict].to_s+'/896 family_match='+s[:family].to_s+'/896'+
      ' selected_native='+s[:native].to_s+' fallback='+s[:fallback].to_s+
      ' generic_attack='+s[:attack].to_s+' ticks='+s[:ticks].to_s+
      ' max_tick_ms='+s[:tick_max_ms].to_s+' over_50ms='+s[:over_threshold].to_s+
      ' bad=['+(s[:bad]||[]).join(',')+'] behavior_change=0')
    [:small,:medium,:quadruped,:heavy,:hover,:avian,:serpentine].each do |body|
      g=s[:groups][body] || {}
      log_event(:battle,'BATTLE_REPRESENTATIVE_ROUTE_GROUP_V10528 body='+body.to_s+
        ' routes='+g[:routes].to_i.to_s+'/128 playable='+g[:playable].to_i.to_s+'/128'+
        ' strict45='+g[:strict].to_i.to_s+'/128 family='+g[:family].to_i.to_s+'/128'+
        ' selected_native='+g[:native].to_i.to_s+' fallback='+g[:fallback].to_i.to_s+
        ' generic_attack='+g[:attack].to_i.to_s)
    end
    hot=PMD_AC.representative_route_hotspots_v10528(s,10)
    log_event(:battle,'BATTLE_REPRESENTATIVE_ROUTE_HOTSPOT_V10528 rows=['+
      hot.collect{|row|row[0].to_s+'='+row[1].to_i.to_s}.join(',')+']')
    log_event(:battle,'BATTLE_REPRESENTATIVE_TUNING_CANDIDATE_V10528 count='+
      (s[:tuning]||[]).size.to_s+' samples=['+(s[:tuning]||[]).join(',')+']'+
      ' policy=audit_only apply_next_after_windows_evidence=1 motion_core_unchanged=1')
    @representative_route_reported_v10528=true
    true
  rescue
    false
  end

  def focus_cast_log_summary_v1055
    r=pmd_ac_v10528_focus_summary
    return r if respond_to?(:production_external_battle_fast_v10613?) && production_external_battle_fast_v10613?
    begin
      s=PMD_AC.representative_route_qa_state_v10528
      if s!=nil && s[:complete] && !@representative_route_reported_v10528
        representative_route_qa_log_v10528(s)
      elsif s!=nil && s[:ready] && !s[:complete]
        log_event(:battle,'BATTLE_REPRESENTATIVE_ROUTE_QA_SUMMARY_V10528 pass=0 incomplete=1'+
          ' done='+s[:done].to_i.to_s+'/'+s[:total].to_i.to_s+' blocking=0 retry_next_battle=1')
      end
    rescue
    end
    r
  end
end
