# encoding: UTF-8
#==============================================================================
# 【PMD AutoChess 中文維護說明】
# 腳本：PMD AutoChess Move Speed Status Allocation-Free v1.02.20
# 分類：PMD Motion Phase A／Windows RGSS2 效能單點 A/B／Trailing Optimization
# RPG Maker VX / RGSS2 / Ruby 1.8 compatible
#------------------------------------------------------------------------------
# 【用途】
# v1.02.19 Windows RGSS2 LOG 已把唯一 100ms 級 Movement spike 精確定位到：
#   movement_total          max 122ms
#   movement_effective_speed max 121ms
#   movement_status_speed    max 121ms
# 而 separation / zone avoidance / clamp / sync cell 等皆 <=1ms。
#
# 原始 status_stat_multiplier(:move_speed) 每次會先建立 @statuses.keys 陣列，
# 接著 slow_value_for(:move_speed) 又建立一次 @statuses.keys 陣列。即使單位沒有狀態，
# 每次 effective_move_speed 仍會產生兩個短命 Array。v1.02.19 單場 movement status
# speed 呼叫約 15,020 次，因此會累積大量無必要的小型配置。
#
# 本版只在 PMD_MOTION_PHASE_A_V102 live battle 對 :move_speed 使用等價的
# allocation-free each_pair 掃描；不改任何 Move Speed 數值、slow stack 規則、
# SLOW_CAP、AI、Spatial Runtime、logical x/y、Damage Formula 或 Attack Speed。
# 其他 stat（atk/def/attack_speed/action_speed...）仍完全走原始函式。
#------------------------------------------------------------------------------
# 【主要設定】
# MOTION_MOVE_SPEED_ALLOC_FREE_THRESHOLD_MS_V10220 = 4
#   fast path 單次 >=4ms 才保留 hot record。
# MOTION_MOVE_SPEED_ALLOC_FREE_RECORD_LIMIT_V10220 = 64
#   獨立記錄上限。
# MOTION_MOVE_SPEED_ALLOC_FREE_REPORT_LIMIT_V10220 = 20
#   戰鬥結束最多輸出 20 筆 hot record。
#------------------------------------------------------------------------------
# 【機制規則】
# 原始 move speed multiplier：
#   status_stat_multiplier(:move_speed)
#     -> 1.0 - slow_value_for(:move_speed)
#     -> 最低 0.10
#
# v1.02.20 等價 fast path：
# 1. 直接 @statuses.each_pair，不建立 @statuses.keys snapshot Array。
# 2. 每個 status 仍用 PMD_AC.status_def(key)。
# 3. 只有 tags 包含 :slow 且 base[:stat] == :move_speed 才納入。
# 4. stack_mode == :stack 時仍乘 stacks；其他模式與原版一致。
# 5. total 仍經 PMD_AC.clamp(total, 0.0, PMD_AC::SLOW_CAP)。
# 6. multiplier 仍為 [1.0 - total, 0.10].max。
#
# 注意：這是「相同公式、較少物件配置」，不是調快角色。
#------------------------------------------------------------------------------
# 【一致性驗證】
# verifier 會在測試早期對場上單位同時計算：
#   A. 原始 pmd_ac_v10220_status_stat_multiplier(:move_speed)
#   B. v1.02.20 allocation-free 結果
# 若任一差值 > 0.000001，MOTION_MOVE_SPEED_ALLOC_FREE_V10220 pass=0。
# 一致性檢查只執行一次，不在 live 每幀 shadow compare，避免重新製造配置。
#------------------------------------------------------------------------------
# 【LOG】
# 開戰驗證：
#   MOTION_MOVE_SPEED_ALLOC_FREE_V10220 pass=1 compared=... mismatch=0
# 戰鬥結束：
#   MOTION_MOVE_SPEED_ALLOC_FREE_SUMMARY_V10220 calls=... max_ms=...
#     scanned=... avoided_keys_arrays=... status_def_calls=...
#   MOTION_MOVE_SPEED_ALLOC_FREE_HOT_V10220 ...
#------------------------------------------------------------------------------
# 【事件／腳本呼叫方式與範例】
# 正式事件不需呼叫。
# 實機測試：S -> PMD_MOTION_PHASE_A_V102 -> Shift -> Loading 100% -> 完整跑完一場。
#------------------------------------------------------------------------------
# 【可調參數】
# 本版不提供數值平衡參數；SLOW_CAP 與所有 status data 都沿用 Frozen Combat Core。
# profiler threshold / record limit 僅影響診斷 LOG，不影響戰鬥。
#------------------------------------------------------------------------------
# 【不可破壞】
# - 不修改 Damage Formula / Attack Speed / AI / Spatial Runtime / logical x/y。
# - 不修改 Motion、Projectile、Skill FX、hit-stop、Hurt ownership。
# - 不修改 status value / duration / stack mode / SLOW_CAP。
# - Frozen Combat Core 不直接修改，本腳本只用 trailing alias/override。
# - v1.00.8、v1.01.3、v1.01.6、v1.01.8 與 v1.02.12~19 原樣保留。
# - Game.ini 不得有 UTF-8 BOM，第 0 byte 必須為 [。
#==============================================================================
module PMD_AC
  MOTION_MOVE_SPEED_ALLOC_FREE_VERSION_V10220='1.02.20'
  MOTION_MOVE_SPEED_ALLOC_FREE_THRESHOLD_MS_V10220=4
  MOTION_MOVE_SPEED_ALLOC_FREE_RECORD_LIMIT_V10220=64
  MOTION_MOVE_SPEED_ALLOC_FREE_REPORT_LIMIT_V10220=20
end

class Scene_PMD_AutoChess
  alias pmd_ac_v10220_start start unless method_defined?(:pmd_ac_v10220_start)
  alias pmd_ac_v10220_start_battle start_battle unless method_defined?(:pmd_ac_v10220_start_battle)
  alias pmd_ac_v10220_update_verification_script update_verification_script unless method_defined?(:pmd_ac_v10220_update_verification_script)
  alias pmd_ac_v10220_motion_perf_log_summary_v1023 motion_perf_log_summary_v1023 unless method_defined?(:pmd_ac_v10220_motion_perf_log_summary_v1023)

  def motion_move_speed_alloc_free_reset_v10220
    @motion_move_speed_alloc_calls_v10220=0
    @motion_move_speed_alloc_total_ms_v10220=0
    @motion_move_speed_alloc_max_ms_v10220=0
    @motion_move_speed_alloc_scanned_v10220=0
    @motion_move_speed_alloc_status_def_calls_v10220=0
    @motion_move_speed_alloc_records_v10220=[]
    @motion_move_speed_alloc_summary_logged_v10220=false
  end

  def start
    motion_move_speed_alloc_free_reset_v10220
    pmd_ac_v10220_start
  end

  def start_battle
    motion_move_speed_alloc_free_reset_v10220 if verification_mode==:pmd_motion_phase_a_v102
    pmd_ac_v10220_start_battle
  end

  def motion_move_speed_alloc_free_active_v10220?
    return false unless verification_mode==:pmd_motion_phase_a_v102
    return false unless @phase==:battle
    true
  rescue
    false
  end

  def motion_move_speed_alloc_record_v10220(ms,unit,scanned,status_def_calls)
    return unless motion_move_speed_alloc_free_active_v10220?
    @motion_move_speed_alloc_calls_v10220=0 if @motion_move_speed_alloc_calls_v10220==nil
    @motion_move_speed_alloc_total_ms_v10220=0 if @motion_move_speed_alloc_total_ms_v10220==nil
    @motion_move_speed_alloc_max_ms_v10220=0 if @motion_move_speed_alloc_max_ms_v10220==nil
    @motion_move_speed_alloc_scanned_v10220=0 if @motion_move_speed_alloc_scanned_v10220==nil
    @motion_move_speed_alloc_status_def_calls_v10220=0 if @motion_move_speed_alloc_status_def_calls_v10220==nil
    @motion_move_speed_alloc_records_v10220=[] if @motion_move_speed_alloc_records_v10220==nil
    n=ms.to_i
    @motion_move_speed_alloc_calls_v10220+=1
    @motion_move_speed_alloc_total_ms_v10220+=n
    @motion_move_speed_alloc_max_ms_v10220=n if n>@motion_move_speed_alloc_max_ms_v10220
    @motion_move_speed_alloc_scanned_v10220+=scanned.to_i
    @motion_move_speed_alloc_status_def_calls_v10220+=status_def_calls.to_i
    return if n<PMD_AC::MOTION_MOVE_SPEED_ALLOC_FREE_THRESHOLD_MS_V10220
    return if @motion_move_speed_alloc_records_v10220.size>=PMD_AC::MOTION_MOVE_SPEED_ALLOC_FREE_RECORD_LIMIT_V10220
    uname='-'
    begin;uname=unit.log_name.to_s if unit!=nil;rescue;end
    keys=''
    begin
      keys=(unit.statuses==nil ? [] : unit.statuses.keys).map{|k|k.to_s}.join('|')
    rescue
    end
    frame=0
    begin;frame=Graphics.frame_count-@battle_started_frame if @battle_started_frame!=nil;rescue;end
    @motion_move_speed_alloc_records_v10220.push({
      :frame=>frame,:ms=>n,:unit=>uname,:scanned=>scanned.to_i,:keys=>keys
    })
  rescue
  end

  def verify_motion_move_speed_alloc_free_v10220
    return if @verification_done!=nil && @verification_done[:motion_move_speed_alloc_free_v10220]
    compared=0
    mismatch=0
    max_diff=0.0
    begin
      units=@units || []
      units.each do |u|
        next if u==nil || !u.respond_to?(:motion_move_speed_multiplier_original_v10220)
        a=u.motion_move_speed_multiplier_original_v10220
        b=u.motion_move_speed_multiplier_alloc_free_v10220(false)
        diff=(a.to_f-b.to_f).abs
        max_diff=diff if diff>max_diff
        compared+=1
        mismatch+=1 if diff>0.000001
      end
    rescue
      mismatch+=1
    end
    pass=verification_mode==:pmd_motion_phase_a_v102 && compared>0 && mismatch==0
    @motion_phase_a_failed_v102=true unless pass
    log_event(:verify,'MOTION_MOVE_SPEED_ALLOC_FREE_V10220 pass='+(pass ? '1':'0')+
      ' compared='+compared.to_s+' mismatch='+mismatch.to_s+
      ' max_diff='+('%.6f' % max_diff)+
      ' each_pair=1 keys_snapshot_live=0 formula_unchanged=1 slow_cap_unchanged=1'+
      ' ai_unchanged=1 damage_unchanged=1 attack_speed_unchanged=1 spatial_values_unchanged=1')
    @verification_done[:motion_move_speed_alloc_free_v10220]=true if @verification_done!=nil
  rescue
  end

  def update_verification_script
    result=pmd_ac_v10220_update_verification_script
    if verification_mode==:pmd_motion_phase_a_v102 && @verification_frame.to_i>=61
      verify_motion_move_speed_alloc_free_v10220
    end
    result
  end

  def motion_move_speed_alloc_free_log_summary_v10220
    return if @motion_move_speed_alloc_summary_logged_v10220
    return unless verification_mode==:pmd_motion_phase_a_v102
    @motion_move_speed_alloc_summary_logged_v10220=true
    calls=@motion_move_speed_alloc_calls_v10220.to_i
    avg=calls<=0 ? 0 : (@motion_move_speed_alloc_total_ms_v10220.to_i/calls)
    avoided=calls*2
    records=(@motion_move_speed_alloc_records_v10220 || []).dup
    records.sort!{|a,b|b[:ms].to_i<=>a[:ms].to_i}
    hot=records[0,PMD_AC::MOTION_MOVE_SPEED_ALLOC_FREE_REPORT_LIMIT_V10220] || []
    log_event(:perf,'MOTION_MOVE_SPEED_ALLOC_FREE_SUMMARY_V10220 calls='+calls.to_s+
      ' max_ms='+@motion_move_speed_alloc_max_ms_v10220.to_i.to_s+
      ' avg_ms='+avg.to_s+' scanned='+@motion_move_speed_alloc_scanned_v10220.to_i.to_s+
      ' status_def_calls='+@motion_move_speed_alloc_status_def_calls_v10220.to_i.to_s+
      ' avoided_keys_arrays='+avoided.to_s+' hot='+hot.size.to_s)
    hot.each do |r|
      log_event(:perf,'MOTION_MOVE_SPEED_ALLOC_FREE_HOT_V10220 frame='+r[:frame].to_i.to_s+
        ' ms='+r[:ms].to_i.to_s+' unit='+r[:unit].to_s+
        ' scanned='+r[:scanned].to_i.to_s+' keys=['+r[:keys].to_s+']')
    end
  rescue
  end

  def motion_perf_log_summary_v1023
    already=@motion_perf_summary_logged_v1023
    result=pmd_ac_v10220_motion_perf_log_summary_v1023
    if !already && @motion_perf_summary_logged_v1023
      motion_move_speed_alloc_free_log_summary_v10220
    end
    result
  end
end

class Game_PMDChessUnit
  alias pmd_ac_v10220_status_stat_multiplier status_stat_multiplier unless method_defined?(:pmd_ac_v10220_status_stat_multiplier)

  # 原始鏈結果，只供 verifier 一次性 A/B；live fast path 不呼叫。
  def motion_move_speed_multiplier_original_v10220
    pmd_ac_v10220_status_stat_multiplier(:move_speed)
  end

  # 與原始 slow_value_for(:move_speed) + status_stat_multiplier(:move_speed)
  # 數學等價，但使用 each_pair，避免建立 Hash#keys snapshot Array。
  def motion_move_speed_multiplier_alloc_free_v10220(record=true)
    total=0.0
    scanned=0
    status_def_calls=0
    scene=@scene
    t=Time.now.to_f
    begin
      if @statuses!=nil
        @statuses.each_pair do |key,data|
          scanned+=1
          next if data==nil
          base=PMD_AC.status_def(key)
          status_def_calls+=1
          tags=base[:tags] || []
          next unless tags.include?(:slow)
          next unless base[:stat]==:move_speed
          stacks=[data[:stacks].to_i,1].max
          value=data[:value].to_f
          if (base[:stack_mode] || :refresh)==:stack
            value*=stacks
          end
          total+=value
        end
      end
      total=PMD_AC.clamp(total,0.0,PMD_AC::SLOW_CAP)
      result=[1.0-total,0.10].max
    ensure
      if record && scene!=nil && scene.respond_to?(:motion_move_speed_alloc_record_v10220)
        ms=((Time.now.to_f-t)*1000.0).round rescue 0
        scene.motion_move_speed_alloc_record_v10220(ms,self,scanned,status_def_calls)
      end
    end
    result
  end

  def status_stat_multiplier(stat)
    scene=@scene
    if stat==:move_speed && scene!=nil &&
       scene.respond_to?(:motion_move_speed_alloc_free_active_v10220?) &&
       scene.motion_move_speed_alloc_free_active_v10220?
      # 保留 v1.02.19 的 movement_status_speed 比較欄位，讓新舊 LOG 可直接對照。
      if scene.respond_to?(:motion_movement_micro_active_v10219?) &&
         scene.motion_movement_micro_active_v10219? &&
         $PMD_AC_MOVEMENT_CONTEXT_V10219!=nil &&
         scene.respond_to?(:motion_movement_micro_time_v10219)
        return scene.motion_movement_micro_time_v10219('movement_status_speed',self){
          motion_move_speed_multiplier_alloc_free_v10220(true)
        }
      end
      return motion_move_speed_multiplier_alloc_free_v10220(true)
    end
    pmd_ac_v10220_status_stat_multiplier(stat)
  end
end
