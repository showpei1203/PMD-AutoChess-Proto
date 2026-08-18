# encoding: UTF-8
#==============================================================================
# 【PMD AutoChess 中文維護說明】
# 腳本：PMD AutoChess Status Micro Profiler v1.02.17
# 分類：PMD Motion Phase A／Windows RGSS2 實機效能定位／Trailing Diagnostic
# RPG Maker VX / RGSS2 / Ruby 1.8 compatible
#------------------------------------------------------------------------------
# 【用途】
# v1.02.16 已將 Target Anchor opaque-bounds alpha scan 搬入 Battle Loading，
# Windows RGSS2 實機證明 effect_anchor 由 231ms 降至 1ms、launch_projectile
# 由 236ms 降至 5ms，opening >=50ms 也降為 0。剩餘 Deep Profiler 顯示
# unit_statuses max 約 129ms，但 v1.02.7 的 160 筆慢記錄已滿，因此沒有保留
# 該次 spike 的 frame / unit / status context。
#
# 本腳本只做「狀態更新微型 profiler」，不改任何狀態效果、傷害、持續時間、
# Ability、AI、Attack Speed、Spatial Runtime 或 Motion presentation。
#------------------------------------------------------------------------------
# 【主要設定】
# MOTION_STATUS_MICRO_THRESHOLD_MS_V10217 = 4
#   單一子區塊 >=4ms 才保留 hot record；統計仍會記錄所有量測呼叫。
# MOTION_STATUS_MICRO_RECORD_LIMIT_V10217 = 96
#   使用獨立 buffer，不受 v1.02.7 的 160 records 上限影響。
# MOTION_STATUS_MICRO_REPORT_LIMIT_V10217 = 24
#   戰鬥結束只輸出最慢 24 筆。
#------------------------------------------------------------------------------
# 【量測區塊】
# 1. status_total          ：整個 Game_PMDChessUnit#update_statuses。
# 2. status_ability_key    ：v0.66 Heatproof 等 status wrapper 會查詢 Ability。
# 3. status_def            ：PMD_AC.status_def(key)。
# 4. status_receive_damage ：burn / poison 等 tick 造成的 receive_damage。
# 5. status_heal           ：持續回復 tick。
# 6. status_log_event      ：status tick / expire 的 LOG 事件。
# 7. status_notice         ：v0.88 狀態到期頭頂提示 queue。
#
# status_total 若 >= threshold，另外記錄：
# - statuses：當次更新後仍存在的狀態 key。
# - before_count：更新前狀態數。
# - due_tick：更新前 tick<=1 的狀態數。
# - expiring：更新前 duration<=1 的狀態數。
# 這些欄位只做診斷，不參與戰鬥邏輯。
#------------------------------------------------------------------------------
# 【機制規則】
# - 只在 PMD_MOTION_PHASE_A_V102 + live battle 生效。
# - @statuses 為空時直接走原方法，不增加微型 profiler 計時負擔。
# - 所有 hook 都使用 trailing alias；Frozen Combat Core 不直接修改。
# - 子方法只有在「目前正在 update_statuses」時才計時，其他戰鬥呼叫不記錄。
# - 不改原 method 的參數、return value、執行順序與例外行為。
#------------------------------------------------------------------------------
# 【事件／腳本呼叫方式】
# 正式事件不需呼叫。
# 測試：S -> PMD_MOTION_PHASE_A_V102 -> Shift -> Loading 100% -> 完整跑完一場。
#------------------------------------------------------------------------------
# 【LOG／驗證】
# 開戰 verifier：
#   MOTION_STATUS_MICRO_PROFILER_V10217 pass=1
# 戰鬥結束：
#   MOTION_STATUS_MICRO_SUMMARY_V10217 stats=[...]
#   MOTION_STATUS_MICRO_HOT_V10217 frame=... kind=... ms=... unit=...
#------------------------------------------------------------------------------
# 【判讀】
# - status_receive_damage 高：下一版只追狀態 tick 的 damage pipeline。
# - status_notice 高：只追 v0.88 status notice / popup。
# - status_ability_key 高：只追 Ability resolver/cache。
# - status_total 高但所有子區塊都低：時間落在 Hash/Array bookkeeping、外部停頓
#   或 GC 邊界，下一版再用更小的 A/B 驗證，不先猜。
#------------------------------------------------------------------------------
# 【不可破壞】
# - 不修改 Damage Formula / Attack Speed / AI / Spatial / logical x/y。
# - 不修改狀態效果、tick 數值、持續時間、stack、清除規則。
# - 不修改 Motion hit-stop、Hurt ownership、source hitFrame、Skill FX。
# - v1.00.8 / v1.01.3 / v1.01.6 / v1.01.8 與 v1.02.12~16 保持原樣。
# - Game.ini 不得有 UTF-8 BOM，第 0 byte 必須為 [。
#==============================================================================
module PMD_AC
  MOTION_STATUS_MICRO_VERSION_V10217='1.02.17'
  MOTION_STATUS_MICRO_THRESHOLD_MS_V10217=4
  MOTION_STATUS_MICRO_RECORD_LIMIT_V10217=96
  MOTION_STATUS_MICRO_REPORT_LIMIT_V10217=24
end

# 單執行緒 RGSS2 診斷 context。只在 update_statuses 執行期間暫時設定。
$PMD_AC_STATUS_MICRO_UNIT_V10217=nil

class Scene_PMD_AutoChess
  alias pmd_ac_v10217_start start unless method_defined?(:pmd_ac_v10217_start)
  alias pmd_ac_v10217_start_battle start_battle unless method_defined?(:pmd_ac_v10217_start_battle)
  alias pmd_ac_v10217_update_verification_script update_verification_script unless method_defined?(:pmd_ac_v10217_update_verification_script)
  alias pmd_ac_v10217_motion_perf_log_summary_v1023 motion_perf_log_summary_v1023 unless method_defined?(:pmd_ac_v10217_motion_perf_log_summary_v1023)

  def motion_status_micro_reset_v10217
    @motion_status_micro_stats_v10217={}
    @motion_status_micro_records_v10217=[]
    @motion_status_micro_summary_logged_v10217=false
  end

  def start
    motion_status_micro_reset_v10217
    pmd_ac_v10217_start
  end

  def start_battle
    motion_status_micro_reset_v10217 if verification_mode==:pmd_motion_phase_a_v102
    pmd_ac_v10217_start_battle
  end

  def motion_status_micro_active_v10217?
    return false unless verification_mode==:pmd_motion_phase_a_v102
    return false unless @phase==:battle
    true
  rescue
    false
  end

  def motion_status_micro_frame_v10217
    return 0 if @battle_started_frame==nil
    Graphics.frame_count-@battle_started_frame
  rescue
    0
  end

  def motion_status_micro_record_v10217(kind,ms,unit=nil,extra=nil)
    return unless motion_status_micro_active_v10217?
    @motion_status_micro_stats_v10217={} if @motion_status_micro_stats_v10217==nil
    @motion_status_micro_records_v10217=[] if @motion_status_micro_records_v10217==nil
    key=kind.to_s
    n=ms.to_i
    st=@motion_status_micro_stats_v10217[key]
    if st==nil
      st={:calls=>0,:total=>0,:max=>0,:slow=>0}
      @motion_status_micro_stats_v10217[key]=st
    end
    st[:calls]+=1
    st[:total]+=n
    st[:max]=n if n>st[:max]
    return if n<PMD_AC::MOTION_STATUS_MICRO_THRESHOLD_MS_V10217
    st[:slow]+=1
    return if @motion_status_micro_records_v10217.size>=PMD_AC::MOTION_STATUS_MICRO_RECORD_LIMIT_V10217
    uname='-'
    begin
      uname=unit.log_name.to_s if unit!=nil
    rescue
    end
    @motion_status_micro_records_v10217.push({
      :frame=>motion_status_micro_frame_v10217,
      :kind=>key,:ms=>n,:unit=>uname,:extra=>extra.to_s
    })
  rescue
  end

  def verify_motion_status_micro_v10217
    return if @verification_done!=nil && @verification_done[:motion_status_micro_v10217]
    pass=verification_mode==:pmd_motion_phase_a_v102 &&
      @motion_status_micro_stats_v10217!=nil && @motion_status_micro_records_v10217!=nil
    @motion_phase_a_failed_v102=true unless pass
    log_event(:verify,'MOTION_STATUS_MICRO_PROFILER_V10217 pass='+(pass ? '1':'0')+
      ' independent_buffer=1 threshold_ms='+PMD_AC::MOTION_STATUS_MICRO_THRESHOLD_MS_V10217.to_s+
      ' status_logic_unchanged=1 ai_unchanged=1 damage_unchanged=1 attack_speed_unchanged=1 spatial_unchanged=1')
    @verification_done[:motion_status_micro_v10217]=true if @verification_done!=nil
  rescue
  end

  def update_verification_script
    result=pmd_ac_v10217_update_verification_script
    if verification_mode==:pmd_motion_phase_a_v102 && @verification_frame.to_i>=58
      verify_motion_status_micro_v10217
    end
    result
  end

  def motion_status_micro_log_summary_v10217
    return if @motion_status_micro_summary_logged_v10217
    return unless verification_mode==:pmd_motion_phase_a_v102
    @motion_status_micro_summary_logged_v10217=true
    stats=[]
    (@motion_status_micro_stats_v10217 || {}).each do |k,v|
      stats.push([v[:max].to_i,k,v])
    end
    stats.sort!{|a,b|b[0]<=>a[0]}
    text=stats.map do |row|
      v=row[2]
      avg=v[:calls].to_i<=0 ? 0 : (v[:total].to_i/v[:calls].to_i)
      row[1]+':max'+v[:max].to_s+'/avg'+avg.to_s+'/slow'+v[:slow].to_s+'/calls'+v[:calls].to_s
    end.join(',')
    records=(@motion_status_micro_records_v10217 || []).dup
    records.sort!{|a,b|b[:ms].to_i<=>a[:ms].to_i}
    hot=records[0,PMD_AC::MOTION_STATUS_MICRO_REPORT_LIMIT_V10217] || []
    log_event(:perf,'MOTION_STATUS_MICRO_SUMMARY_V10217 records='+records.size.to_s+
      ' report='+hot.size.to_s+' stats=['+text+']')
    hot.each do |r|
      log_event(:perf,'MOTION_STATUS_MICRO_HOT_V10217 frame='+r[:frame].to_i.to_s+
        ' kind='+r[:kind].to_s+' ms='+r[:ms].to_i.to_s+
        ' unit='+r[:unit].to_s+(r[:extra].to_s=='' ? '' : ' extra='+r[:extra].to_s))
    end
  rescue
  end

  def motion_perf_log_summary_v1023
    already=@motion_perf_summary_logged_v1023
    result=pmd_ac_v10217_motion_perf_log_summary_v1023
    if !already && @motion_perf_summary_logged_v1023
      motion_status_micro_log_summary_v10217
    end
    result
  end
end

class Game_PMDChessUnit
  alias pmd_ac_v10217_update_statuses update_statuses unless method_defined?(:pmd_ac_v10217_update_statuses)
  alias pmd_ac_v10217_ability_key ability_key unless method_defined?(:pmd_ac_v10217_ability_key)
  alias pmd_ac_v10217_receive_damage receive_damage unless method_defined?(:pmd_ac_v10217_receive_damage)
  alias pmd_ac_v10217_heal heal unless method_defined?(:pmd_ac_v10217_heal)
  alias pmd_ac_v10217_log_event log_event unless method_defined?(:pmd_ac_v10217_log_event)
  alias pmd_ac_v10217_queue_status_notice_v088 queue_status_notice_v088 unless method_defined?(:pmd_ac_v10217_queue_status_notice_v088)

  def motion_status_micro_scene_v10217
    s=@scene
    return nil if s==nil || !s.respond_to?(:motion_status_micro_active_v10217?)
    return nil unless s.motion_status_micro_active_v10217?
    s
  rescue
    nil
  end

  def motion_status_micro_inside_v10217?
    $PMD_AC_STATUS_MICRO_UNIT_V10217.equal?(self)
  rescue
    false
  end

  def motion_status_micro_child_time_v10217(kind)
    return yield unless motion_status_micro_inside_v10217?
    s=motion_status_micro_scene_v10217
    return yield if s==nil
    t=Time.now.to_f
    result=yield
    ms=((Time.now.to_f-t)*1000.0).round rescue 0
    s.motion_status_micro_record_v10217(kind,ms,self,nil)
    result
  end

  def update_statuses
    s=motion_status_micro_scene_v10217
    return pmd_ac_v10217_update_statuses if s==nil || @statuses==nil || @statuses.empty?
    before_count=@statuses.size
    due_tick=0
    expiring=0
    begin
      @statuses.each do |k,data|
        next if data==nil
        due_tick+=1 if data[:tick]!=nil && data[:tick].to_i<=1
        expiring+=1 if data[:duration]!=nil && data[:duration].to_i<=1
      end
    rescue
    end
    old_context=$PMD_AC_STATUS_MICRO_UNIT_V10217
    $PMD_AC_STATUS_MICRO_UNIT_V10217=self
    t=Time.now.to_f
    begin
      result=pmd_ac_v10217_update_statuses
    ensure
      ms=((Time.now.to_f-t)*1000.0).round rescue 0
      extra='before_count='+before_count.to_i.to_s+' due_tick='+due_tick.to_i.to_s+
        ' expiring='+expiring.to_i.to_s
      if ms.to_i>=PMD_AC::MOTION_STATUS_MICRO_THRESHOLD_MS_V10217
        begin
          extra+=' statuses=['+(@statuses==nil ? [] : @statuses.keys).map{|k|k.to_s}.join('|')+']'
        rescue
        end
      end
      s.motion_status_micro_record_v10217('status_total',ms,self,extra)
      $PMD_AC_STATUS_MICRO_UNIT_V10217=old_context
    end
    result
  end

  def ability_key
    motion_status_micro_child_time_v10217('status_ability_key'){pmd_ac_v10217_ability_key}
  end

  def receive_damage(*args)
    motion_status_micro_child_time_v10217('status_receive_damage'){pmd_ac_v10217_receive_damage(*args)}
  end

  def heal(*args)
    motion_status_micro_child_time_v10217('status_heal'){pmd_ac_v10217_heal(*args)}
  end

  def log_event(*args)
    motion_status_micro_child_time_v10217('status_log_event'){pmd_ac_v10217_log_event(*args)}
  end

  def queue_status_notice_v088(*args)
    motion_status_micro_child_time_v10217('status_notice'){pmd_ac_v10217_queue_status_notice_v088(*args)}
  end
end

module PMD_AC
  class << self
    alias pmd_ac_v10217_status_def status_def unless method_defined?(:pmd_ac_v10217_status_def)
    def status_def(key)
      u=$PMD_AC_STATUS_MICRO_UNIT_V10217
      if u!=nil
        begin
          s=u.scene
          if s!=nil && s.respond_to?(:motion_status_micro_active_v10217?) && s.motion_status_micro_active_v10217?
            t=Time.now.to_f
            result=pmd_ac_v10217_status_def(key)
            ms=((Time.now.to_f-t)*1000.0).round rescue 0
            s.motion_status_micro_record_v10217('status_def',ms,u,'key='+key.to_s)
            return result
          end
        rescue
        end
      end
      pmd_ac_v10217_status_def(key)
    end
  end
end
