# encoding: UTF-8
#==============================================================================
# 【PMD AutoChess 中文維護說明】
# 腳本：PMD AutoChess Motion Deep Frame Profiler v1.02.7
# 分類：PMD Motion Phase A／實機效能定位／Trailing Diagnostic
# RPG Maker VX / RGSS2 / Ruby 1.8 compatible
#------------------------------------------------------------------------------
# 【用途】
# v1.02.6 實機結果已證明 VERIFY LOG fast path 本身不是 100~240ms hitch 根因：
# MOTION_VERIFY_FASTPATH_V1026 的 total_write_ms / max_write_ms 都為 0，但 opening/runtime
# 仍有大量 >=50ms hitch。v1.02.5 也已把 slow bitmap 壓到接近 0，因此本版停止猜測，
# 對 live battle 的主要更新區塊做分段計時，直接找出耗時落在 Unit、AI Logic、Sprite、
# Effect、Projectile、Verifier、Attack/Skill start、Zone 或其他哪一層。
#------------------------------------------------------------------------------
# 【主要設定】
# MOTION_DEEP_COMPONENT_THRESHOLD_MS_V1027 = 6
#   單一區塊 >= 6ms 才記錄，避免大量正常微小呼叫污染資料。
# MOTION_DEEP_RECORD_LIMIT_V1027 = 160
#   記憶體內最多保留 160 筆慢區塊；戰鬥中不寫磁碟。
# MOTION_DEEP_REPORT_LIMIT_V1027 = 32
#   戰鬥結束只輸出最慢 32 筆，保持 current-test LOG 精簡。
#------------------------------------------------------------------------------
# 【機制規則】
# 1. 所有計時記錄都只在 PMD_MOTION_PHASE_A_V102 模式生效。
# 2. 戰鬥中只把慢區塊存入 Array / Hash，不立即 File.write，避免 profiler 自己製造卡頓。
# 3. 監測層級：
#    - Scene update_verification_script
#    - Scene update_unit_sprites / effect_sprites / projectile_sprites
#    - Scene update_battle_objects / object_sprites / zones / check_battle_end
#    - Game_PMDChessUnit update / update_logic / begin_attack / begin_skill
#    - Sprite_PMDChessUnit update / refresh_action_bitmap
# 4. 同一筆會記 frame、耗時、單位、action / visual_action，方便與 v1.02.3 的
#    MOTION_FRAME_SPIKE_V1023 對照。
# 5. 不修改任何 method 的 return value 與執行順序；只在前後讀 Time.now。
#------------------------------------------------------------------------------
# 【可調參數】
# - 若實機 profiler 本身造成可感負擔，可把 COMPONENT_THRESHOLD 從 6 提高到 10。
# - REPORT_LIMIT 建議維持 32；只需要找最慢層級，不需要把 2000 frame 全倒進 LOG。
#------------------------------------------------------------------------------
# 【事件／腳本呼叫方式】
# 正式事件不需呼叫。
# 測試：AutoChess 布陣 → S 切 PMD_MOTION_PHASE_A_V102 → Shift → 完整看完一場。
#------------------------------------------------------------------------------
# 【LOG／驗證】
# verifier：
#   MOTION_DEEP_PROFILER_V1027 pass=1 buffered=1 behavior_unchanged=1
# 戰鬥結束：
#   MOTION_DEEP_SUMMARY_V1027 ...
#   MOTION_DEEP_HOT_V1027 frame=... kind=unit_update ms=... unit=...
#------------------------------------------------------------------------------
# 【實際判讀範例】
# - 若 hot 幾乎都是 verify_update：把 verifier 全移出 live battle。
# - 若 hot 是 unit_logic / begin_attack：追 AI / Attack alias chain。
# - 若 hot 是 sprite_update / sprite_refresh：追 PMD sprite refresh / Bitmap / Popup。
# - 若所有 component 都很低但 Scene update 仍 100ms：再往 Scene super / Graphics 邊界查。
#------------------------------------------------------------------------------
# 【不可破壞】
# - Frozen Combat Core 不直接修改，只以 trailing alias 量測。
# - Pokémon 個體身份仍使用 instance_uid。
# - PMD Sprite 100%，Effect / Projectile 50%。
# - 不修改 AI、Target、Dynamic Tactical Role、Spatial Framework、Damage、Attack Speed。
# - 不修改 Motion hit-stop、Hurt ownership、source hitFrame、Skill FX 或 logical position。
# - Game.ini 不得有 UTF-8 BOM。
#==============================================================================
module PMD_AC
  MOTION_DEEP_PROFILER_VERSION_V1027='1.02.7'
  MOTION_DEEP_COMPONENT_THRESHOLD_MS_V1027=6
  MOTION_DEEP_RECORD_LIMIT_V1027=160
  MOTION_DEEP_REPORT_LIMIT_V1027=32
end

class Scene_PMD_AutoChess
  alias pmd_ac_v1027_start start unless method_defined?(:pmd_ac_v1027_start)
  alias pmd_ac_v1027_start_battle start_battle unless method_defined?(:pmd_ac_v1027_start_battle)
  alias pmd_ac_v1027_prepare_verification_battle prepare_verification_battle unless method_defined?(:pmd_ac_v1027_prepare_verification_battle)
  alias pmd_ac_v1027_refresh_selected_sprites refresh_selected_sprites unless method_defined?(:pmd_ac_v1027_refresh_selected_sprites)
  alias pmd_ac_v1027_refresh_header refresh_header unless method_defined?(:pmd_ac_v1027_refresh_header)
  alias pmd_ac_v1027_refresh_footer refresh_footer unless method_defined?(:pmd_ac_v1027_refresh_footer)
  alias pmd_ac_v1027_restart_to_deploy restart_to_deploy unless method_defined?(:pmd_ac_v1027_restart_to_deploy)
  alias pmd_ac_v1027_update_verification_script update_verification_script unless method_defined?(:pmd_ac_v1027_update_verification_script)
  alias pmd_ac_v1027_update_unit_sprites update_unit_sprites unless method_defined?(:pmd_ac_v1027_update_unit_sprites)
  alias pmd_ac_v1027_update_effect_sprites update_effect_sprites unless method_defined?(:pmd_ac_v1027_update_effect_sprites)
  alias pmd_ac_v1027_update_projectile_sprites update_projectile_sprites unless method_defined?(:pmd_ac_v1027_update_projectile_sprites)
  alias pmd_ac_v1027_update_battle_objects update_battle_objects unless method_defined?(:pmd_ac_v1027_update_battle_objects)
  alias pmd_ac_v1027_update_battle_object_sprites update_battle_object_sprites unless method_defined?(:pmd_ac_v1027_update_battle_object_sprites)
  alias pmd_ac_v1027_update_zones update_zones unless method_defined?(:pmd_ac_v1027_update_zones)
  alias pmd_ac_v1027_check_battle_end check_battle_end unless method_defined?(:pmd_ac_v1027_check_battle_end)
  alias pmd_ac_v1027_motion_perf_log_summary_v1023 motion_perf_log_summary_v1023 unless method_defined?(:pmd_ac_v1027_motion_perf_log_summary_v1023)

  def motion_deep_mode_v1027?
    verification_mode==:pmd_motion_phase_a_v102
  rescue
    false
  end

  def motion_deep_reset_v1027
    @motion_deep_records_v1027=[]
    @motion_deep_stats_v1027={}
    @motion_deep_summary_logged_v1027=false
    @motion_deep_enabled_v1027=false
  end

  def start
    motion_deep_reset_v1027
    result=pmd_ac_v1027_start
    @motion_deep_enabled_v1027=motion_deep_mode_v1027?
    result
  end

  def start_battle
    unless motion_deep_mode_v1027?
      return pmd_ac_v1027_start_battle
    end
    t=Time.now.to_f
    result=pmd_ac_v1027_start_battle
    ms=((Time.now.to_f-t)*1000.0).round rescue 0
    motion_deep_record_v1027('start_battle_total',ms,nil,nil) if @phase==:battle
    result
  end

  def prepare_verification_battle
    return pmd_ac_v1027_prepare_verification_battle unless motion_deep_active_v1027?
    motion_deep_timed_v1027('prepare_verify'){pmd_ac_v1027_prepare_verification_battle}
  end

  def refresh_selected_sprites
    return pmd_ac_v1027_refresh_selected_sprites unless motion_deep_active_v1027?
    motion_deep_timed_v1027('refresh_selected'){pmd_ac_v1027_refresh_selected_sprites}
  end

  def refresh_header
    return pmd_ac_v1027_refresh_header unless motion_deep_active_v1027?
    motion_deep_timed_v1027('refresh_header'){pmd_ac_v1027_refresh_header}
  end

  def refresh_footer
    return pmd_ac_v1027_refresh_footer unless motion_deep_active_v1027?
    motion_deep_timed_v1027('refresh_footer'){pmd_ac_v1027_refresh_footer}
  end

  def restart_to_deploy
    result=pmd_ac_v1027_restart_to_deploy
    motion_deep_reset_v1027
    @motion_deep_enabled_v1027=motion_deep_mode_v1027? if @phase==:deploy
    result
  end

  def motion_deep_active_v1027?
    @motion_deep_enabled_v1027 && @phase==:battle && motion_deep_mode_v1027?
  rescue
    false
  end

  def motion_deep_frame_v1027
    return 0 if @battle_started_frame==nil
    Graphics.frame_count-@battle_started_frame
  rescue
    0
  end

  def motion_deep_record_v1027(kind,ms,unit=nil,extra=nil)
    return unless motion_deep_active_v1027?
    n=ms.to_i
    key=kind.to_s
    st=@motion_deep_stats_v1027[key]
    if st==nil
      st={:calls=>0,:total=>0,:max=>0,:slow=>0}
      @motion_deep_stats_v1027[key]=st
    end
    st[:calls]+=1
    st[:total]+=n
    st[:max]=n if n>st[:max]
    return if n<PMD_AC::MOTION_DEEP_COMPONENT_THRESHOLD_MS_V1027
    st[:slow]+=1
    return if @motion_deep_records_v1027.size>=PMD_AC::MOTION_DEEP_RECORD_LIMIT_V1027
    uname='-'
    action='-'
    visual='-'
    begin
      if unit!=nil
        uname=unit.log_name.to_s
        action=unit.action.to_s
        visual=unit.visual_action.to_s
      end
    rescue
    end
    @motion_deep_records_v1027.push({
      :frame=>motion_deep_frame_v1027,:kind=>key,:ms=>n,
      :unit=>uname,:action=>action,:visual=>visual,:extra=>extra.to_s
    })
  rescue
  end

  def motion_deep_timed_v1027(kind)
    t=Time.now.to_f
    result=yield
    ms=((Time.now.to_f-t)*1000.0).round rescue 0
    motion_deep_record_v1027(kind,ms,nil,nil)
    result
  end

  def update_unit_sprites
    return pmd_ac_v1027_update_unit_sprites unless motion_deep_active_v1027?
    motion_deep_timed_v1027('unit_sprites_total'){pmd_ac_v1027_update_unit_sprites}
  end

  def update_effect_sprites
    return pmd_ac_v1027_update_effect_sprites unless motion_deep_active_v1027?
    motion_deep_timed_v1027('effect_sprites'){pmd_ac_v1027_update_effect_sprites}
  end

  def update_projectile_sprites
    return pmd_ac_v1027_update_projectile_sprites unless motion_deep_active_v1027?
    motion_deep_timed_v1027('projectile_sprites'){pmd_ac_v1027_update_projectile_sprites}
  end

  def update_battle_objects
    return pmd_ac_v1027_update_battle_objects unless motion_deep_active_v1027?
    motion_deep_timed_v1027('battle_objects'){pmd_ac_v1027_update_battle_objects}
  end

  def update_battle_object_sprites
    return pmd_ac_v1027_update_battle_object_sprites unless motion_deep_active_v1027?
    motion_deep_timed_v1027('battle_object_sprites'){pmd_ac_v1027_update_battle_object_sprites}
  end

  def update_zones
    return pmd_ac_v1027_update_zones unless motion_deep_active_v1027?
    motion_deep_timed_v1027('zones'){pmd_ac_v1027_update_zones}
  end

  def check_battle_end
    return pmd_ac_v1027_check_battle_end unless motion_deep_active_v1027?
    motion_deep_timed_v1027('check_end'){pmd_ac_v1027_check_battle_end}
  end

  def verify_motion_deep_profiler_v1027
    return if @verification_done[:motion_deep_profiler_v1027]
    pass=motion_deep_mode_v1027? && @motion_deep_records_v1027!=nil && @motion_deep_stats_v1027!=nil
    @motion_phase_a_failed_v102=true unless pass
    log_event(:verify,'MOTION_DEEP_PROFILER_V1027 pass='+(pass ? '1':'0')+
      ' buffered=1 component_threshold_ms='+PMD_AC::MOTION_DEEP_COMPONENT_THRESHOLD_MS_V1027.to_s+
      ' behavior_unchanged=1 ai_unchanged=1 damage_unchanged=1 attack_speed_unchanged=1 spatial_unchanged=1')
    @verification_done[:motion_deep_profiler_v1027]=true
  end

  def update_verification_script
    unless motion_deep_active_v1027?
      result=pmd_ac_v1027_update_verification_script
      verify_motion_deep_profiler_v1027 if motion_deep_mode_v1027? && @verification_frame.to_i>=42
      return result
    end
    t=Time.now.to_f
    result=pmd_ac_v1027_update_verification_script
    ms=((Time.now.to_f-t)*1000.0).round rescue 0
    motion_deep_record_v1027('verify_update',ms,nil,'vf='+@verification_frame.to_i.to_s)
    verify_motion_deep_profiler_v1027 if @verification_frame.to_i>=42
    result
  end

  def motion_deep_log_summary_v1027
    return if @motion_deep_summary_logged_v1027
    return unless motion_deep_mode_v1027?
    @motion_deep_summary_logged_v1027=true
    stats=[]
    @motion_deep_stats_v1027.each do |k,v|
      stats.push([v[:max].to_i,k,v])
    end
    stats.sort!{|a,b|b[0]<=>a[0]}
    top_stats=stats[0,12] || []
    stat_text=top_stats.map{|row|v=row[2];row[1]+':max'+v[:max].to_s+'/slow'+v[:slow].to_s+'/calls'+v[:calls].to_s}.join(',')
    records=@motion_deep_records_v1027.dup
    records.sort!{|a,b|b[:ms].to_i<=>a[:ms].to_i}
    hot=records[0,PMD_AC::MOTION_DEEP_REPORT_LIMIT_V1027] || []
    log_event(:perf,'MOTION_DEEP_SUMMARY_V1027 records='+records.size.to_s+
      ' report='+hot.size.to_s+' threshold_ms='+PMD_AC::MOTION_DEEP_COMPONENT_THRESHOLD_MS_V1027.to_s+
      ' stats=['+stat_text+']')
    hot.each do |r|
      log_event(:perf,'MOTION_DEEP_HOT_V1027 frame='+r[:frame].to_i.to_s+
        ' kind='+r[:kind].to_s+' ms='+r[:ms].to_i.to_s+
        ' unit='+r[:unit].to_s+' action='+r[:action].to_s+'/'+r[:visual].to_s+
        (r[:extra].to_s.empty? ? '' : ' extra='+r[:extra].to_s))
    end
  rescue
  end

  def motion_perf_log_summary_v1023
    already=@motion_perf_summary_logged_v1023
    result=pmd_ac_v1027_motion_perf_log_summary_v1023
    if !already && @motion_perf_summary_logged_v1023
      motion_deep_log_summary_v1027
    end
    result
  end
end

class Game_PMDChessUnit
  alias pmd_ac_v1027_update update unless method_defined?(:pmd_ac_v1027_update)
  alias pmd_ac_v1027_start_combat start_combat unless method_defined?(:pmd_ac_v1027_start_combat)
  alias pmd_ac_v1027_update_logic update_logic unless method_defined?(:pmd_ac_v1027_update_logic)
  alias pmd_ac_v1027_begin_attack begin_attack unless method_defined?(:pmd_ac_v1027_begin_attack)
  alias pmd_ac_v1027_begin_skill begin_skill unless method_defined?(:pmd_ac_v1027_begin_skill)

  def motion_deep_scene_v1027
    s=@scene
    return nil if s==nil || !s.respond_to?(:motion_deep_active_v1027?) || !s.motion_deep_active_v1027?
    s
  rescue
    nil
  end

  def motion_deep_unit_time_v1027(kind)
    s=motion_deep_scene_v1027
    return yield if s==nil
    t=Time.now.to_f
    result=yield
    ms=((Time.now.to_f-t)*1000.0).round rescue 0
    s.motion_deep_record_v1027(kind,ms,self,nil)
    result
  end

  def start_combat
    motion_deep_unit_time_v1027('start_combat'){pmd_ac_v1027_start_combat}
  end

  def update
    motion_deep_unit_time_v1027('unit_update'){pmd_ac_v1027_update}
  end

  def update_logic
    motion_deep_unit_time_v1027('unit_logic'){pmd_ac_v1027_update_logic}
  end

  def begin_attack
    motion_deep_unit_time_v1027('begin_attack'){pmd_ac_v1027_begin_attack}
  end

  def begin_skill(skill_target=nil)
    motion_deep_unit_time_v1027('begin_skill'){pmd_ac_v1027_begin_skill(skill_target)}
  end
end

class Sprite_PMDChessUnit
  alias pmd_ac_v1027_update update unless method_defined?(:pmd_ac_v1027_update)
  alias pmd_ac_v1027_refresh_action_bitmap refresh_action_bitmap unless method_defined?(:pmd_ac_v1027_refresh_action_bitmap)

  def motion_deep_sprite_scene_v1027
    return nil if @unit==nil
    s=@unit.scene rescue nil
    return nil if s==nil || !s.respond_to?(:motion_deep_active_v1027?) || !s.motion_deep_active_v1027?
    s
  rescue
    nil
  end

  def update
    s=motion_deep_sprite_scene_v1027
    return pmd_ac_v1027_update if s==nil
    t=Time.now.to_f
    result=pmd_ac_v1027_update
    ms=((Time.now.to_f-t)*1000.0).round rescue 0
    s.motion_deep_record_v1027('sprite_update',ms,@unit,nil)
    result
  end

  def refresh_action_bitmap(force)
    s=motion_deep_sprite_scene_v1027
    return pmd_ac_v1027_refresh_action_bitmap(force) if s==nil
    t=Time.now.to_f
    result=pmd_ac_v1027_refresh_action_bitmap(force)
    ms=((Time.now.to_f-t)*1000.0).round rescue 0
    s.motion_deep_record_v1027('sprite_refresh',ms,@unit,'force='+(force ? '1':'0'))
    result
  end
end
