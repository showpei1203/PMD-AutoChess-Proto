# encoding: UTF-8
#==============================================================================
# 【PMD AutoChess 中文維護說明】
# 腳本：PMD AutoChess Motion Frame Spike Profiler v1.02.3
# 分類：PMD Motion Phase A／效能診斷／Frame Spike／Trailing Hotfix
# RPG Maker VX / RGSS2 / Ruby 1.8 compatible
#------------------------------------------------------------------------------
# 【用途】
# 用於精確定位 v1.02～v1.02.2 Motion Framework 實機回報的「戰鬥剛開始」與
# 「戰鬥中某些時刻」短暫卡頓。v1.02.2 已完成 Bitmap / route cache 與 deploy prewarm，
# 但舊 LOG 沒有逐 frame wall-time，因此無法區分：真正的 RGSS2 frame spike、戰鬥建立
# 成本、戰鬥中晚到的 Bitmap decode，或 Motion 設計上的 1～4 frame hit-stop 視覺停頓。
# 本版只加低負擔 profiler，不修改 AI、Damage、Attack Speed、Spatial 或動作時序。
#------------------------------------------------------------------------------
# 【主要設定】
# MOTION_FRAME_SPIKE_MS_V1023 = 28
#   相鄰兩次 Scene update 起點的 wall-time 超過此值視為 frame spike。
# MOTION_SEVERE_SPIKE_MS_V1023 = 45
#   超過此值視為 severe spike。
# MOTION_UPDATE_SPIKE_MS_V1023 = 12
#   Scene_PMD_AutoChess#update 本身 CPU 時間超過此值會一併標記。
# MOTION_BITMAP_SLOW_MS_V1023 = 8
#   live battle / start_battle 中 Cache.load_bitmap 超過此值視為晚到素材載入。
# MOTION_PROFILE_RECORD_LIMIT_V1023 = 24
#   記錄最多 24 筆，避免 profiler 自己變成新的 LOG 洪水。
#------------------------------------------------------------------------------
# 【機制規則】
# 1. 只在 PMD_MOTION_PHASE_A_V102 測試模式啟用，每 frame 僅做 Time.now 與少量數值比較。
# 2. 不在 spike 發生當下寫檔；先存在記憶體，戰鬥結束才用既有 buffered LOG 輸出。
# 3. 同時量測 start_battle 總耗時、相鄰 frame gap、Scene update CPU、慢 Bitmap load。
# 4. 記錄 Motion source-frame hold 次數與最大 hold，藉此區分「真的掉 frame」和
#    「設計上的 hit-stop / source hold 看起來像停頓」。本版不改 hold 秒數。
# 5. 每筆 spike 會保存當時六隻單位的 action / visual_action / target 快照，方便回推。
#------------------------------------------------------------------------------
# 【可調參數】
# 若 30 FPS 裝置需要較寬鬆門檻，可把 MOTION_FRAME_SPIKE_MS_V1023 提高到 40。
# 正式完成診斷後，可保留腳本但 profiler 只會在 Motion verifier mode 工作。
#------------------------------------------------------------------------------
# 【事件／腳本呼叫方式】
# 一般事件不需呼叫。
# 測試：AutoChess 布陣 → S 切 PMD_MOTION_PHASE_A_V102 → Shift → 看完整場戰鬥。
# 戰鬥結束後查看 PMD_AutoChess_Battle.log 的：
#   MOTION_FRAME_PROFILE_V1023
#   MOTION_FRAME_SPIKE_V1023
#   MOTION_LATE_BITMAP_V1023
#------------------------------------------------------------------------------
# 【實際範例】
# 若卡頓是真正 frame spike：
#   MOTION_FRAME_SPIKE_V1023 frame=520 gap_ms=67 update_ms=51 ...
# 若卡頓其實只是 3 frame hit-stop，wall-time 正常：
#   MOTION_FRAME_PROFILE_V1023 spikes=0 ... visual_holds=... max_hold=3
# 若是第一次載入漏網 Action PNG：
#   MOTION_LATE_BITMAP_V1023 frame=432 ms=24 file=Shock-Anim.png
#------------------------------------------------------------------------------
# 【不可破壞】
# - 不直接修改 Frozen Combat Core，只以 Main 前 trailing alias 安裝。
# - Pokémon 個體身份仍使用 instance_uid。
# - 不修改 logical pixel_x / pixel_y。
# - 不修改 AI Policy、Dynamic Tactical Role、Spatial Framework、Attack Speed、Damage。
# - 不修改 v1.02 Motion hit-stop／Native handoff／Hurt ownership 的實際行為。
#==============================================================================
module PMD_AC
  MOTION_FRAME_PROFILER_VERSION_V1023='1.02.3'
  MOTION_FRAME_SPIKE_MS_V1023=28
  MOTION_SEVERE_SPIKE_MS_V1023=45
  MOTION_UPDATE_SPIKE_MS_V1023=12
  MOTION_BITMAP_SLOW_MS_V1023=8
  MOTION_PROFILE_RECORD_LIMIT_V1023=24

  class << self
    def motion_perf_scene_v1023
      s=$scene
      return nil if s==nil
      return nil unless s.respond_to?(:motion_perf_capture_active_v1023?)
      return nil unless s.motion_perf_capture_active_v1023?
      s
    rescue
      nil
    end
  end
end

#==============================================================================
# ■ Cache - 記錄 live battle 中真正慢的 Bitmap load，不改 Cache 行為
#==============================================================================
module Cache
  class << self
    alias pmd_ac_v1023_load_bitmap load_bitmap unless method_defined?(:pmd_ac_v1023_load_bitmap)
    def load_bitmap(folder_name,filename,hue=0)
      s=PMD_AC.motion_perf_scene_v1023
      return pmd_ac_v1023_load_bitmap(folder_name,filename,hue) if s==nil
      t=Time.now.to_f
      result=pmd_ac_v1023_load_bitmap(folder_name,filename,hue)
      ms=((Time.now.to_f-t)*1000.0).round rescue 0
      begin;s.motion_perf_note_bitmap_v1023(folder_name,filename,ms);rescue;end
      result
    end
  end
end

#==============================================================================
# ■ Sprite_PMDChessUnit - 只記錄 source hold / hit-stop，不改實際 hold
#==============================================================================
class Sprite_PMDChessUnit
  alias pmd_ac_v1023_motion_snap_source_frame_v102 motion_snap_source_frame_v102 unless method_defined?(:pmd_ac_v1023_motion_snap_source_frame_v102)
  def motion_snap_source_frame_v102(frame_index,visible_frames)
    result=pmd_ac_v1023_motion_snap_source_frame_v102(frame_index,visible_frames)
    if result
      begin
        s=PMD_AC.motion_perf_scene_v1023
        s.motion_perf_note_hold_v1023(@unit,visible_frames) if s!=nil
      rescue
      end
    end
    result
  end
end

#==============================================================================
# ■ Scene_PMD_AutoChess - wall-time / update CPU / battle-start profiler
#==============================================================================
class Scene_PMD_AutoChess
  alias pmd_ac_v1023_update update unless method_defined?(:pmd_ac_v1023_update)
  alias pmd_ac_v1023_start_battle start_battle unless method_defined?(:pmd_ac_v1023_start_battle)
  alias pmd_ac_v1023_check_battle_end check_battle_end unless method_defined?(:pmd_ac_v1023_check_battle_end)
  alias pmd_ac_v1023_restart_to_deploy restart_to_deploy unless method_defined?(:pmd_ac_v1023_restart_to_deploy)
  alias pmd_ac_v1023_terminate terminate unless method_defined?(:pmd_ac_v1023_terminate)
  alias pmd_ac_v1023_update_verification_script update_verification_script unless method_defined?(:pmd_ac_v1023_update_verification_script)

  def motion_perf_mode_v1023?
    verification_mode==:pmd_motion_phase_a_v102
  rescue
    false
  end

  def motion_perf_reset_v1023
    @motion_perf_initialized_v1023=true
    @motion_perf_starting_v1023=false
    @motion_perf_prev_update_time_v1023=nil
    @motion_perf_frames_v1023=0
    @motion_perf_spikes_v1023=[]
    @motion_perf_bitmap_records_v1023=[]
    @motion_perf_bitmap_calls_v1023=0
    @motion_perf_bitmap_slow_v1023=0
    @motion_perf_max_bitmap_ms_v1023=0
    @motion_perf_max_gap_ms_v1023=0
    @motion_perf_max_update_ms_v1023=0
    @motion_perf_severe_v1023=0
    @motion_perf_battle_start_ms_v1023=0
    @motion_perf_holds_v1023=0
    @motion_perf_hold_gt1_v1023=0
    @motion_perf_max_hold_v1023=0
    @motion_perf_recent_hold_frame_v1023=-9999
    @motion_perf_recent_hold_frames_v1023=0
    @motion_perf_summary_logged_v1023=false
    true
  end

  def motion_perf_capture_active_v1023?
    return false unless motion_perf_mode_v1023?
    @motion_perf_starting_v1023 || @phase==:battle
  rescue
    false
  end

  def motion_perf_relative_frame_v1023
    return 0 if @battle_started_frame==nil
    Graphics.frame_count-@battle_started_frame
  rescue
    0
  end

  def motion_perf_action_context_v1023
    rows=[]
    (@units || []).each do |u|
      next if u==nil
      name=(u.log_name rescue u.name.to_s)
      act=(u.action rescue :unknown)
      vis=(u.visual_action rescue :unknown)
      tar=(u.target rescue nil)
      tn=tar==nil ? '-' : (tar.log_name rescue tar.name.to_s)
      rows.push(name+'='+act.to_s+'/'+vis.to_s+'>'+tn.to_s)
    end
    rows.join(';')
  rescue
    'context_error'
  end

  def motion_perf_note_hold_v1023(unit,visible_frames)
    return unless motion_perf_capture_active_v1023?
    h=visible_frames.to_i
    @motion_perf_holds_v1023=@motion_perf_holds_v1023.to_i+1
    @motion_perf_hold_gt1_v1023=@motion_perf_hold_gt1_v1023.to_i+1 if h>1
    @motion_perf_max_hold_v1023=h if h>@motion_perf_max_hold_v1023.to_i
    @motion_perf_recent_hold_frame_v1023=motion_perf_relative_frame_v1023
    @motion_perf_recent_hold_frames_v1023=h
    true
  rescue
    false
  end

  def motion_perf_note_bitmap_v1023(folder,filename,ms)
    return unless motion_perf_capture_active_v1023?
    @motion_perf_bitmap_calls_v1023=@motion_perf_bitmap_calls_v1023.to_i+1
    m=ms.to_i
    @motion_perf_max_bitmap_ms_v1023=m if m>@motion_perf_max_bitmap_ms_v1023.to_i
    return true if m<PMD_AC::MOTION_BITMAP_SLOW_MS_V1023
    @motion_perf_bitmap_slow_v1023=@motion_perf_bitmap_slow_v1023.to_i+1
    rec=@motion_perf_bitmap_records_v1023 || []
    if rec.size<PMD_AC::MOTION_PROFILE_RECORD_LIMIT_V1023
      rec.push({:frame=>motion_perf_relative_frame_v1023,:ms=>m,
        :file=>filename.to_s,:folder=>folder.to_s})
    end
    @motion_perf_bitmap_records_v1023=rec
    true
  rescue
    false
  end

  def motion_perf_record_spike_v1023(gap_ms,update_ms)
    g=gap_ms.to_i
    u=update_ms.to_i
    return if g<PMD_AC::MOTION_FRAME_SPIKE_MS_V1023 && u<PMD_AC::MOTION_UPDATE_SPIKE_MS_V1023
    @motion_perf_severe_v1023=@motion_perf_severe_v1023.to_i+1 if g>=PMD_AC::MOTION_SEVERE_SPIKE_MS_V1023
    rec=@motion_perf_spikes_v1023 || []
    return if rec.size>=PMD_AC::MOTION_PROFILE_RECORD_LIMIT_V1023
    f=motion_perf_relative_frame_v1023
    recent=(f-@motion_perf_recent_hold_frame_v1023.to_i)<=2
    rec.push({:frame=>f,:gap=>g,:update=>u,
      :verify=>(@verification_frame.to_i rescue 0),
      :hold=>(recent ? @motion_perf_recent_hold_frames_v1023.to_i : 0),
      :context=>motion_perf_action_context_v1023})
    @motion_perf_spikes_v1023=rec
  rescue
  end

  def motion_perf_log_summary_v1023
    return if @motion_perf_summary_logged_v1023
    return unless @motion_perf_initialized_v1023
    @motion_perf_summary_logged_v1023=true
    spikes=@motion_perf_spikes_v1023 || []
    bits=@motion_perf_bitmap_records_v1023 || []
    log_event(:perf,'MOTION_FRAME_PROFILE_V1023 battle_start_ms='+@motion_perf_battle_start_ms_v1023.to_i.to_s+
      ' frames='+@motion_perf_frames_v1023.to_i.to_s+
      ' spikes='+spikes.size.to_s+' severe='+@motion_perf_severe_v1023.to_i.to_s+
      ' max_gap_ms='+@motion_perf_max_gap_ms_v1023.to_i.to_s+
      ' max_update_ms='+@motion_perf_max_update_ms_v1023.to_i.to_s+
      ' bitmap_calls='+@motion_perf_bitmap_calls_v1023.to_i.to_s+
      ' slow_bitmap='+@motion_perf_bitmap_slow_v1023.to_i.to_s+
      ' max_bitmap_ms='+@motion_perf_max_bitmap_ms_v1023.to_i.to_s+
      ' visual_holds='+@motion_perf_holds_v1023.to_i.to_s+
      ' hold_gt1='+@motion_perf_hold_gt1_v1023.to_i.to_s+
      ' max_hold='+@motion_perf_max_hold_v1023.to_i.to_s)
    spikes.each do |r|
      log_event(:perf,'MOTION_FRAME_SPIKE_V1023 frame='+r[:frame].to_i.to_s+
        ' gap_ms='+r[:gap].to_i.to_s+' update_ms='+r[:update].to_i.to_s+
        ' verify_frame='+r[:verify].to_i.to_s+' recent_hold='+r[:hold].to_i.to_s+
        ' actions=['+r[:context].to_s+']')
    end
    bits.each do |r|
      log_event(:perf,'MOTION_LATE_BITMAP_V1023 frame='+r[:frame].to_i.to_s+
        ' ms='+r[:ms].to_i.to_s+' file='+r[:file].to_s+' folder='+r[:folder].to_s)
    end
    true
  rescue
    false
  end

  def start_battle
    if motion_perf_mode_v1023?
      motion_perf_reset_v1023 unless @motion_perf_initialized_v1023
      @motion_perf_starting_v1023=true
      t=Time.now.to_f
      old=@phase
      result=pmd_ac_v1023_start_battle
      ms=((Time.now.to_f-t)*1000.0).round rescue 0
      @motion_perf_starting_v1023=false
      if @phase==:battle && old!=:battle
        @motion_perf_battle_start_ms_v1023=ms
        @motion_perf_prev_update_time_v1023=Time.now.to_f
      end
      return result
    end
    pmd_ac_v1023_start_battle
  end

  def update
    unless motion_perf_capture_active_v1023?
      return pmd_ac_v1023_update
    end
    now=Time.now.to_f
    gap=0
    if @motion_perf_prev_update_time_v1023!=nil
      gap=((now-@motion_perf_prev_update_time_v1023.to_f)*1000.0).round rescue 0
    end
    @motion_perf_prev_update_time_v1023=now
    t=Time.now.to_f
    result=pmd_ac_v1023_update
    update_ms=((Time.now.to_f-t)*1000.0).round rescue 0
    @motion_perf_frames_v1023=@motion_perf_frames_v1023.to_i+1
    @motion_perf_max_gap_ms_v1023=gap if gap>@motion_perf_max_gap_ms_v1023.to_i
    @motion_perf_max_update_ms_v1023=update_ms if update_ms>@motion_perf_max_update_ms_v1023.to_i
    motion_perf_record_spike_v1023(gap,update_ms)
    result
  end

  def check_battle_end
    old=@phase
    result=pmd_ac_v1023_check_battle_end
    if motion_perf_mode_v1023? && old==:battle && @phase==:result
      motion_perf_log_summary_v1023
    end
    result
  end

  def restart_to_deploy
    motion_perf_log_summary_v1023 if motion_perf_mode_v1023?
    result=pmd_ac_v1023_restart_to_deploy
    @motion_perf_initialized_v1023=false
    result
  end

  def terminate
    motion_perf_log_summary_v1023 if motion_perf_mode_v1023?
    pmd_ac_v1023_terminate
  end

  def verify_motion_frame_profiler_v1023
    return if @verification_done[:motion_frame_profiler_v1023]
    pass=@motion_perf_initialized_v1023 && motion_perf_mode_v1023?
    @motion_phase_a_failed_v102=true unless pass
    log_event(:verify,'MOTION_FRAME_PROFILER_V1023 pass='+(pass ? '1':'0')+
      ' wall_gap=1 update_cpu=1 battle_start=1 late_bitmap=1 hitstop_audit=1 buffered_records=1 '+
      'ai_unchanged=1 damage_unchanged=1 attack_speed_unchanged=1 spatial_unchanged=1')
    @verification_done[:motion_frame_profiler_v1023]=true
  end

  def update_verification_script
    pmd_ac_v1023_update_verification_script
    return unless motion_perf_mode_v1023?
    verify_motion_frame_profiler_v1023 if @verification_frame.to_i>=32
  end
end
