# encoding: UTF-8
#==============================================================================
# 【PMD AutoChess 中文維護說明】
# 腳本：PMD AutoChess Movement Micro Profiler v1.02.19
# 分類：PMD Motion Phase A／Windows RGSS2 實機效能定位／Trailing Diagnostic
# RPG Maker VX / RGSS2 / Ruby 1.8 compatible
#------------------------------------------------------------------------------
# 【用途】
# v1.02.18 Windows RGSS2 LOG 已證明 Projectile Hit / Direct Damage 本身皆正常：
#   projectile_hit_total max 約 13ms
#   damage_total          max 約 12ms
#   launch_projectile     max 約 6ms
# 同場唯一明確的 100ms 級 Unit 子區塊改為：
#   unit_movement max 約 124ms（slow=1）
# 因此本版停止追 Status / Direct Damage，改為只拆 Game_PMDChessUnit#update_movement
# 內部實際呼叫的 Movement 子區塊，確認 124ms 是落在目標速度、單位分離、
# 危險區閃避、速度修正、棋盤 clamp、cell 同步或朝向更新中的哪一段。
#
# 本腳本為純 profiler，不修改移動規則、AI、Spatial Runtime、logical x/y、
# Damage Formula、Attack Speed、Projectile、Motion presentation 或任何戰鬥結果。
#------------------------------------------------------------------------------
# 【主要設定】
# MOTION_MOVEMENT_MICRO_THRESHOLD_MS_V10219 = 4
#   單一量測區塊 >=4ms 才保留 hot record；所有呼叫仍累積 calls/avg/max。
# MOTION_MOVEMENT_MICRO_RECORD_LIMIT_V10219 = 128
#   獨立 buffer，不受 v1.02.7 Deep Profiler 160 筆上限影響。
# MOTION_MOVEMENT_MICRO_REPORT_LIMIT_V10219 = 32
#   戰鬥結束輸出最慢 32 筆。
#------------------------------------------------------------------------------
# 【量測區塊】
# 1. movement_total            現行 update_movement 全部。
# 2. movement_desired_velocity desired_velocity。
# 3. movement_separation       Scene#separation_vector。
# 4. movement_zone_avoid       Scene#zone_avoidance_vector。
# 5. movement_effective_speed  effective_move_speed。
# 6. movement_status_speed     movement context 內 status_stat_multiplier(:move_speed)。
# 7. movement_clamp            clamp_to_board。
# 8. movement_sync_cell        sync_cell_from_pixel。
# 9. movement_face_delta       face_delta。
# 10. movement_moving_check    moving?。
#
# movement_total hot record 額外記錄：
#   movement policy / action / visual action / goal 是否存在 / target / zones 數量。
#------------------------------------------------------------------------------
# 【判讀】
# - movement_total 與某 child 同步出現 100ms：下一版只修該 child。
# - movement_separation 高：只追單位碰撞／separation loop。
# - movement_zone_avoid 高：只追 harmful zone avoidance / zone LOG first-touch。
# - movement_effective_speed 或 movement_status_speed 高：只追 Move Speed 狀態鏈。
# - movement_clamp / sync_cell / face_delta 高：只追對應 Spatial helper。
# - movement_total 高但所有 child 都低：代表停頓落在 update_movement 本體未包覆的
#   算術區段，或 runtime pause/GC 剛好落在這個 stack；再做 segment A/B，不直接改 AI。
#------------------------------------------------------------------------------
# 【機制規則】
# - 只在 PMD_MOTION_PHASE_A_V102 且 @phase == :battle 時計時。
# - 所有 hook 都為 trailing alias；Frozen Combat Core 不直接修改。
# - method 參數、return value、執行順序與條件完全不變。
# - child profiler 只在 movement_total context 內啟用，避免全戰鬥污染。
#------------------------------------------------------------------------------
# 【事件／腳本呼叫方式與範例】
# 正式事件不需呼叫。
# 實機測試：S -> PMD_MOTION_PHASE_A_V102 -> Shift -> Loading 100% -> 完整跑完一場。
#------------------------------------------------------------------------------
# 【LOG／驗證】
# 開戰：
#   MOTION_MOVEMENT_MICRO_PROFILER_V10219 pass=1
# 戰鬥結束：
#   MOTION_MOVEMENT_MICRO_SUMMARY_V10219 stats=[...]
#   MOTION_MOVEMENT_MICRO_HOT_V10219 frame=... kind=... ms=... unit=... extra=...
#------------------------------------------------------------------------------
# 【不可破壞】
# - 不修改 Damage Formula / Attack Speed / AI / Spatial Runtime / logical x/y。
# - 不修改 Motion / Projectile / Status / Skill FX / hit-stop / Hurt ownership。
# - v1.00.8、v1.01.3、v1.01.6、v1.01.8 與 v1.02.12~18 原樣保留。
# - Game.ini 不得有 UTF-8 BOM，第 0 byte 必須為 [。
#==============================================================================
module PMD_AC
  MOTION_MOVEMENT_MICRO_VERSION_V10219='1.02.19'
  MOTION_MOVEMENT_MICRO_THRESHOLD_MS_V10219=4
  MOTION_MOVEMENT_MICRO_RECORD_LIMIT_V10219=128
  MOTION_MOVEMENT_MICRO_REPORT_LIMIT_V10219=32
end

$PMD_AC_MOVEMENT_CONTEXT_V10219=nil

class Scene_PMD_AutoChess
  alias pmd_ac_v10219_start start unless method_defined?(:pmd_ac_v10219_start)
  alias pmd_ac_v10219_start_battle start_battle unless method_defined?(:pmd_ac_v10219_start_battle)
  alias pmd_ac_v10219_update_verification_script update_verification_script unless method_defined?(:pmd_ac_v10219_update_verification_script)
  alias pmd_ac_v10219_motion_perf_log_summary_v1023 motion_perf_log_summary_v1023 unless method_defined?(:pmd_ac_v10219_motion_perf_log_summary_v1023)
  alias pmd_ac_v10219_separation_vector separation_vector unless method_defined?(:pmd_ac_v10219_separation_vector)
  alias pmd_ac_v10219_zone_avoidance_vector zone_avoidance_vector unless method_defined?(:pmd_ac_v10219_zone_avoidance_vector)

  def motion_movement_micro_reset_v10219
    @motion_movement_micro_stats_v10219={}
    @motion_movement_micro_records_v10219=[]
    @motion_movement_micro_summary_logged_v10219=false
  end

  def start
    motion_movement_micro_reset_v10219
    pmd_ac_v10219_start
  end

  def start_battle
    motion_movement_micro_reset_v10219 if verification_mode==:pmd_motion_phase_a_v102
    pmd_ac_v10219_start_battle
  end

  def motion_movement_micro_active_v10219?
    return false unless verification_mode==:pmd_motion_phase_a_v102
    return false unless @phase==:battle
    true
  rescue
    false
  end

  def motion_movement_micro_context_v10219?
    $PMD_AC_MOVEMENT_CONTEXT_V10219!=nil
  rescue
    false
  end

  def motion_movement_micro_frame_v10219
    return 0 if @battle_started_frame==nil
    Graphics.frame_count-@battle_started_frame
  rescue
    0
  end

  def motion_movement_micro_record_v10219(kind,ms,unit=nil,extra=nil)
    return unless motion_movement_micro_active_v10219?
    @motion_movement_micro_stats_v10219={} if @motion_movement_micro_stats_v10219==nil
    @motion_movement_micro_records_v10219=[] if @motion_movement_micro_records_v10219==nil
    key=kind.to_s
    n=ms.to_i
    st=@motion_movement_micro_stats_v10219[key]
    if st==nil
      st={:calls=>0,:total=>0,:max=>0,:slow=>0}
      @motion_movement_micro_stats_v10219[key]=st
    end
    st[:calls]+=1
    st[:total]+=n
    st[:max]=n if n>st[:max]
    return if n<PMD_AC::MOTION_MOVEMENT_MICRO_THRESHOLD_MS_V10219
    st[:slow]+=1
    return if @motion_movement_micro_records_v10219.size>=PMD_AC::MOTION_MOVEMENT_MICRO_RECORD_LIMIT_V10219
    uname='-'
    begin;uname=unit.log_name.to_s if unit!=nil;rescue;end
    @motion_movement_micro_records_v10219.push({
      :frame=>motion_movement_micro_frame_v10219,
      :kind=>key,:ms=>n,:unit=>uname,:extra=>extra.to_s
    })
  rescue
  end

  def motion_movement_micro_time_v10219(kind,unit=nil,extra=nil)
    return yield unless motion_movement_micro_active_v10219?
    t=Time.now.to_f
    result=yield
    ms=((Time.now.to_f-t)*1000.0).round rescue 0
    motion_movement_micro_record_v10219(kind,ms,unit,extra)
    result
  end

  def motion_movement_micro_child_time_v10219(kind,unit=nil,extra=nil)
    return yield unless motion_movement_micro_active_v10219? && motion_movement_micro_context_v10219?
    motion_movement_micro_time_v10219(kind,unit,extra){yield}
  end

  def separation_vector(unit)
    motion_movement_micro_child_time_v10219('movement_separation',unit){
      pmd_ac_v10219_separation_vector(unit)
    }
  end

  def zone_avoidance_vector(unit)
    extra='zones=' + ((@zones==nil) ? 0 : @zones.size).to_s
    motion_movement_micro_child_time_v10219('movement_zone_avoid',unit,extra){
      pmd_ac_v10219_zone_avoidance_vector(unit)
    }
  end

  def verify_motion_movement_micro_v10219
    return if @verification_done!=nil && @verification_done[:motion_movement_micro_v10219]
    pass=verification_mode==:pmd_motion_phase_a_v102 &&
      @motion_movement_micro_stats_v10219!=nil && @motion_movement_micro_records_v10219!=nil
    @motion_phase_a_failed_v102=true unless pass
    log_event(:verify,'MOTION_MOVEMENT_MICRO_PROFILER_V10219 pass='+(pass ? '1':'0')+
      ' child_context=1 independent_buffer=1 threshold_ms='+
      PMD_AC::MOTION_MOVEMENT_MICRO_THRESHOLD_MS_V10219.to_s+
      ' behavior_unchanged=1 ai_unchanged=1 damage_unchanged=1 attack_speed_unchanged=1 spatial_unchanged=1')
    @verification_done[:motion_movement_micro_v10219]=true if @verification_done!=nil
  rescue
  end

  def update_verification_script
    result=pmd_ac_v10219_update_verification_script
    if verification_mode==:pmd_motion_phase_a_v102 && @verification_frame.to_i>=60
      verify_motion_movement_micro_v10219
    end
    result
  end

  def motion_movement_micro_log_summary_v10219
    return if @motion_movement_micro_summary_logged_v10219
    return unless verification_mode==:pmd_motion_phase_a_v102
    @motion_movement_micro_summary_logged_v10219=true
    stats=[]
    (@motion_movement_micro_stats_v10219 || {}).each do |k,v|
      avg=v[:calls].to_i<=0 ? 0 : (v[:total].to_i/v[:calls].to_i)
      stats.push([v[:max].to_i,k,v,avg])
    end
    stats.sort!{|a,b|b[0]<=>a[0]}
    stat_text=stats.map{|row|
      v=row[2]
      row[1]+':max'+v[:max].to_s+'/avg'+row[3].to_s+'/slow'+v[:slow].to_s+'/calls'+v[:calls].to_s
    }.join(',')
    records=(@motion_movement_micro_records_v10219 || []).dup
    records.sort!{|a,b|b[:ms].to_i<=>a[:ms].to_i}
    hot=records[0,PMD_AC::MOTION_MOVEMENT_MICRO_REPORT_LIMIT_V10219] || []
    log_event(:perf,'MOTION_MOVEMENT_MICRO_SUMMARY_V10219 records='+records.size.to_s+
      ' report='+hot.size.to_s+' stats=['+stat_text+']')
    hot.each do |r|
      log_event(:perf,'MOTION_MOVEMENT_MICRO_HOT_V10219 frame='+r[:frame].to_i.to_s+
        ' kind='+r[:kind].to_s+' ms='+r[:ms].to_i.to_s+
        ' unit='+r[:unit].to_s+
        (r[:extra].to_s.empty? ? '' : ' extra='+r[:extra].to_s))
    end
  rescue
  end

  def motion_perf_log_summary_v1023
    already=@motion_perf_summary_logged_v1023
    result=pmd_ac_v10219_motion_perf_log_summary_v1023
    if !already && @motion_perf_summary_logged_v1023
      motion_movement_micro_log_summary_v10219
    end
    result
  end
end

class Game_PMDChessUnit
  alias pmd_ac_v10219_update_movement update_movement unless method_defined?(:pmd_ac_v10219_update_movement)
  alias pmd_ac_v10219_desired_velocity desired_velocity unless method_defined?(:pmd_ac_v10219_desired_velocity)
  alias pmd_ac_v10219_effective_move_speed effective_move_speed unless method_defined?(:pmd_ac_v10219_effective_move_speed)
  alias pmd_ac_v10219_status_stat_multiplier status_stat_multiplier unless method_defined?(:pmd_ac_v10219_status_stat_multiplier)
  alias pmd_ac_v10219_clamp_to_board clamp_to_board unless method_defined?(:pmd_ac_v10219_clamp_to_board)
  alias pmd_ac_v10219_sync_cell_from_pixel sync_cell_from_pixel unless method_defined?(:pmd_ac_v10219_sync_cell_from_pixel)
  alias pmd_ac_v10219_face_delta face_delta unless method_defined?(:pmd_ac_v10219_face_delta)
  alias pmd_ac_v10219_moving_q moving? unless method_defined?(:pmd_ac_v10219_moving_q)

  def motion_movement_scene_v10219
    s=@scene
    return nil if s==nil || !s.respond_to?(:motion_movement_micro_active_v10219?)
    return nil unless s.motion_movement_micro_active_v10219?
    s
  rescue
    nil
  end

  def motion_movement_extra_v10219
    policy=@movement_policy.to_s
    act=@action.to_s+'/'+@visual_action.to_s
    goal=(@move_goal_x==nil || @move_goal_y==nil) ? '0' : '1'
    target='-'
    begin;target=@target.log_name.to_s if @target!=nil;rescue;end
    zones=0
    begin
      raw=@scene.instance_eval{@zones}
      zones=raw.size if raw!=nil
    rescue
    end
    'policy='+policy+' action='+act+' goal='+goal+' target='+target+' zones='+zones.to_s
  rescue
    ''
  end

  def update_movement
    s=motion_movement_scene_v10219
    return pmd_ac_v10219_update_movement if s==nil
    old=$PMD_AC_MOVEMENT_CONTEXT_V10219
    $PMD_AC_MOVEMENT_CONTEXT_V10219=self
    t=Time.now.to_f
    result=pmd_ac_v10219_update_movement
    ms=((Time.now.to_f-t)*1000.0).round rescue 0
    s.motion_movement_micro_record_v10219('movement_total',ms,self,motion_movement_extra_v10219)
    result
  ensure
    $PMD_AC_MOVEMENT_CONTEXT_V10219=old
  end

  def desired_velocity
    s=motion_movement_scene_v10219
    return pmd_ac_v10219_desired_velocity if s==nil || $PMD_AC_MOVEMENT_CONTEXT_V10219==nil
    s.motion_movement_micro_time_v10219('movement_desired_velocity',self){pmd_ac_v10219_desired_velocity}
  end

  def effective_move_speed
    s=motion_movement_scene_v10219
    return pmd_ac_v10219_effective_move_speed if s==nil || $PMD_AC_MOVEMENT_CONTEXT_V10219==nil
    s.motion_movement_micro_time_v10219('movement_effective_speed',self){pmd_ac_v10219_effective_move_speed}
  end

  def status_stat_multiplier(stat)
    s=motion_movement_scene_v10219
    if s==nil || $PMD_AC_MOVEMENT_CONTEXT_V10219==nil || stat!=:move_speed
      return pmd_ac_v10219_status_stat_multiplier(stat)
    end
    s.motion_movement_micro_time_v10219('movement_status_speed',self){pmd_ac_v10219_status_stat_multiplier(stat)}
  end

  def clamp_to_board
    s=motion_movement_scene_v10219
    return pmd_ac_v10219_clamp_to_board if s==nil || $PMD_AC_MOVEMENT_CONTEXT_V10219==nil
    s.motion_movement_micro_time_v10219('movement_clamp',self){pmd_ac_v10219_clamp_to_board}
  end

  def sync_cell_from_pixel
    s=motion_movement_scene_v10219
    return pmd_ac_v10219_sync_cell_from_pixel if s==nil || $PMD_AC_MOVEMENT_CONTEXT_V10219==nil
    s.motion_movement_micro_time_v10219('movement_sync_cell',self){pmd_ac_v10219_sync_cell_from_pixel}
  end

  def face_delta(dx,dy,immediate=false)
    s=motion_movement_scene_v10219
    return pmd_ac_v10219_face_delta(dx,dy,immediate) if s==nil || $PMD_AC_MOVEMENT_CONTEXT_V10219==nil
    s.motion_movement_micro_time_v10219('movement_face_delta',self){pmd_ac_v10219_face_delta(dx,dy,immediate)}
  end

  def moving?
    s=motion_movement_scene_v10219
    return pmd_ac_v10219_moving_q if s==nil || $PMD_AC_MOVEMENT_CONTEXT_V10219==nil
    s.motion_movement_micro_time_v10219('movement_moving_check',self){pmd_ac_v10219_moving_q}
  end
end
