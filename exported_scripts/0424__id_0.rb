# encoding: UTF-8
#==============================================================================
# 【PMD AutoChess 中文維護說明】
# 腳本：PMD AutoChess Direct Damage / Projectile Hit Micro Profiler v1.02.18
# 分類：PMD Motion Phase A／Windows RGSS2 實機效能定位／Trailing Diagnostic
# RPG Maker VX / RGSS2 / Ruby 1.8 compatible
#------------------------------------------------------------------------------
# 【用途】
# v1.02.16 已將 Target Anchor opaque-bounds alpha scan 搬到 Battle Loading，
# Windows RGSS2 實機證明 effect_anchor 231ms -> 1ms、launch_projectile
# 236ms -> 5ms。v1.02.17 進一步證明 status_total 與所有 Status 子區塊
# max 都只有 0~1ms，因此前一場 unit_statuses 129ms 並非狀態邏輯根因。
#
# 最新實機 Deep Profiler 重新指出：
#   projectile_sprites max 約 129ms
#   projectile_one    max 約 128ms
#   direct_damage     max 約 128ms
# 且 launch_projectile 維持約 5ms。
#
# 本腳本只做「Projectile 命中瞬間 + Direct Damage alias chain」微型 profiler，
# 不改傷害公式、Projectile 命中判定、Ability、AI、Attack Speed、Spatial Runtime、
# logical x/y、Motion presentation 或任何戰鬥結果。
#------------------------------------------------------------------------------
# 【主要設定】
# MOTION_DAMAGE_MICRO_THRESHOLD_MS_V10218 = 4
#   單一區塊 >=4ms 才寫入 hot record；全部呼叫仍做統計。
# MOTION_DAMAGE_MICRO_RECORD_LIMIT_V10218 = 128
#   獨立 buffer，不受 v1.02.7 Deep Profiler 160 筆上限影響。
# MOTION_DAMAGE_MICRO_REPORT_LIMIT_V10218 = 32
#   戰鬥結束輸出最慢 32 筆。
#------------------------------------------------------------------------------
# 【量測區塊】
# Projectile 命中外層：
# 1. projectile_hit_total       Sprite_PMDProjectile#hit 全部。
# 2. projectile_resolve_total   Scene#resolve_projectile 全部。
# 3. projectile_impact_vfx      命中時 add_vfx_impact_xy。
# 4. projectile_refresh_footer  resolve_projectile 尾端 refresh_footer。
# 5. projectile_gain_energy     Basic Hit 後 gain_energy。
# 6. projectile_basic_se        Basic Hit SE。
#
# Direct Damage：
# 7. damage_total               現行 Scene#deal_direct_damage 全部。
# 8. damage_pre_motion          v1.02 Motion true-impact 之前的既有 damage chain。
# 9. damage_below_v09912        v0.99.12 之前的累積 chain。
# 10. damage_below_v097         v0.97 之前的累積 chain。
# 11. damage_below_v0914        v0.91.4 之前的累積 chain。
# 12. damage_below_v0883        v0.88.3 之前的累積 chain。
# 13. damage_below_v066         v0.66 之前的累積 chain。
# 14. damage_below_v057         v0.57 之前的累積 chain。
# 15. damage_calculate          Game_PMDChessUnit#calculate_damage。
# 16. damage_incoming_arc       incoming_arc_from。
# 17. damage_direction_mult     directional_damage_multiplier。
# 18. damage_receive            target.receive_damage。
# 19. motion_true_impact        v1.02 Motion impact wrapper。
# 20. motion_receive_impact     target Motion Hurt ownership。
# 21. motion_route              source-aware route lookup。
# 22. motion_snap               source hitFrame snap。
# 23. damage_log_event          damage context 內 LOG。
#------------------------------------------------------------------------------
# 【判讀】
# - damage_total 高、damage_pre_motion 低：慢點在 v1.02 motion_true_impact 後段。
# - damage_pre_motion 高，某個 below checkpoint 開始明顯下降：根因位於兩個
#   checkpoint 之間的歷史 alias layer，下一版只拆該區段。
# - damage_receive 高：只追 receive_damage chain。
# - damage_calculate 高：只追 damage formula / type / ability resolver。
# - 所有 child 都低，但某個 total 約 120ms：較像 alias wrapper 間配置、
#   runtime pause / GC 邊界或未覆蓋的小區塊；再做更窄 A/B，不直接猜。
#------------------------------------------------------------------------------
# 【機制規則】
# - 只在 PMD_MOTION_PHASE_A_V102 + live battle 計時。
# - 所有 hook 都為 trailing alias；Frozen Combat Core 不直接修改。
# - 不改 method 參數、return value、執行順序、命中條件與例外流程。
# - 只在 Projectile Hit 或 Direct Damage context 中量 child，避免全戰鬥污染。
#------------------------------------------------------------------------------
# 【事件／腳本呼叫方式】
# 正式事件不需呼叫。
# 測試：S -> PMD_MOTION_PHASE_A_V102 -> Shift -> Loading 100% -> 完整跑完一場。
#------------------------------------------------------------------------------
# 【LOG／驗證】
# 開戰：
#   MOTION_DAMAGE_MICRO_PROFILER_V10218 pass=1
# 戰鬥結束：
#   MOTION_DAMAGE_MICRO_SUMMARY_V10218 stats=[...]
#   MOTION_DAMAGE_MICRO_HOT_V10218 frame=... kind=... ms=... unit=...
#------------------------------------------------------------------------------
# 【不可破壞】
# - 不修改 Damage Formula / Attack Speed / AI / Spatial / logical x/y。
# - 不修改 Projectile speed / tracking / collision / impact timing。
# - 不修改 Motion hit-stop / Hurt ownership / source hitFrame / Skill FX。
# - v1.00.8 / v1.01.3 / v1.01.6 / v1.01.8 與 v1.02.12~17 原樣保留。
# - Game.ini 不得有 UTF-8 BOM，第 0 byte 必須為 [。
#==============================================================================
module PMD_AC
  MOTION_DAMAGE_MICRO_VERSION_V10218='1.02.18'
  MOTION_DAMAGE_MICRO_THRESHOLD_MS_V10218=4
  MOTION_DAMAGE_MICRO_RECORD_LIMIT_V10218=128
  MOTION_DAMAGE_MICRO_REPORT_LIMIT_V10218=32
end

$PMD_AC_DAMAGE_CONTEXT_V10218=nil
$PMD_AC_PROJECTILE_HIT_CONTEXT_V10218=nil

class Scene_PMD_AutoChess
  alias pmd_ac_v10218_start start unless method_defined?(:pmd_ac_v10218_start)
  alias pmd_ac_v10218_start_battle start_battle unless method_defined?(:pmd_ac_v10218_start_battle)
  alias pmd_ac_v10218_update_verification_script update_verification_script unless method_defined?(:pmd_ac_v10218_update_verification_script)
  alias pmd_ac_v10218_motion_perf_log_summary_v1023 motion_perf_log_summary_v1023 unless method_defined?(:pmd_ac_v10218_motion_perf_log_summary_v1023)

  alias pmd_ac_v10218_resolve_projectile resolve_projectile unless method_defined?(:pmd_ac_v10218_resolve_projectile)
  alias pmd_ac_v10218_deal_direct_damage deal_direct_damage unless method_defined?(:pmd_ac_v10218_deal_direct_damage)
  alias pmd_ac_v10218_add_vfx_impact_xy add_vfx_impact_xy unless method_defined?(:pmd_ac_v10218_add_vfx_impact_xy)
  alias pmd_ac_v10218_refresh_footer refresh_footer unless method_defined?(:pmd_ac_v10218_refresh_footer)
  alias pmd_ac_v10218_play_basic_se play_basic_se unless method_defined?(:pmd_ac_v10218_play_basic_se)
  alias pmd_ac_v10218_log_event log_event unless method_defined?(:pmd_ac_v10218_log_event)

  # Damage alias-chain checkpoints. These names are historical aliases already
  # present in the production chain; wrapping them changes timing observation only.
  alias pmd_ac_v10218_cp_motion pmd_ac_v102_deal_direct_damage unless method_defined?(:pmd_ac_v10218_cp_motion)
  alias pmd_ac_v10218_cp_09912 pmd_ac_v09912_deal_direct_damage unless method_defined?(:pmd_ac_v10218_cp_09912)
  alias pmd_ac_v10218_cp_097 pmd_ac_v097_deal_direct_damage unless method_defined?(:pmd_ac_v10218_cp_097)
  alias pmd_ac_v10218_cp_0914 pmd_ac_v0914_deal_direct_damage unless method_defined?(:pmd_ac_v10218_cp_0914)
  alias pmd_ac_v10218_cp_0883 pmd_ac_v0883_deal_direct_damage unless method_defined?(:pmd_ac_v10218_cp_0883)
  alias pmd_ac_v10218_cp_066 pmd_ac_v066_deal_direct_damage unless method_defined?(:pmd_ac_v10218_cp_066)
  alias pmd_ac_v10218_cp_057 pmd_ac_v057_deal_direct_damage unless method_defined?(:pmd_ac_v10218_cp_057)

  alias pmd_ac_v10218_motion_true_impact_v102 motion_true_impact_v102 unless method_defined?(:pmd_ac_v10218_motion_true_impact_v102)
  alias pmd_ac_v10218_motion_route_for_unit_v102 motion_route_for_unit_v102 unless method_defined?(:pmd_ac_v10218_motion_route_for_unit_v102)
  alias pmd_ac_v10218_motion_snap_unit_v102 motion_snap_unit_v102 unless method_defined?(:pmd_ac_v10218_motion_snap_unit_v102)

  def motion_damage_micro_reset_v10218
    @motion_damage_micro_stats_v10218={}
    @motion_damage_micro_records_v10218=[]
    @motion_damage_micro_summary_logged_v10218=false
  end

  def start
    motion_damage_micro_reset_v10218
    pmd_ac_v10218_start
  end

  def start_battle
    motion_damage_micro_reset_v10218 if verification_mode==:pmd_motion_phase_a_v102
    pmd_ac_v10218_start_battle
  end

  def motion_damage_micro_active_v10218?
    return false unless verification_mode==:pmd_motion_phase_a_v102
    return false unless @phase==:battle
    true
  rescue
    false
  end

  def motion_damage_micro_frame_v10218
    return 0 if @battle_started_frame==nil
    Graphics.frame_count-@battle_started_frame
  rescue
    0
  end

  def motion_damage_micro_context_v10218?
    $PMD_AC_DAMAGE_CONTEXT_V10218!=nil || $PMD_AC_PROJECTILE_HIT_CONTEXT_V10218!=nil
  rescue
    false
  end

  def motion_damage_micro_record_v10218(kind,ms,unit=nil,extra=nil)
    return unless motion_damage_micro_active_v10218?
    @motion_damage_micro_stats_v10218={} if @motion_damage_micro_stats_v10218==nil
    @motion_damage_micro_records_v10218=[] if @motion_damage_micro_records_v10218==nil
    key=kind.to_s;n=ms.to_i
    st=@motion_damage_micro_stats_v10218[key]
    if st==nil
      st={:calls=>0,:total=>0,:max=>0,:slow=>0}
      @motion_damage_micro_stats_v10218[key]=st
    end
    st[:calls]+=1;st[:total]+=n;st[:max]=n if n>st[:max]
    return if n<PMD_AC::MOTION_DAMAGE_MICRO_THRESHOLD_MS_V10218
    st[:slow]+=1
    return if @motion_damage_micro_records_v10218.size>=PMD_AC::MOTION_DAMAGE_MICRO_RECORD_LIMIT_V10218
    uname='-'
    begin;uname=unit.log_name.to_s if unit!=nil;rescue;end
    @motion_damage_micro_records_v10218.push({
      :frame=>motion_damage_micro_frame_v10218,:kind=>key,:ms=>n,
      :unit=>uname,:extra=>extra.to_s
    })
  rescue
  end

  def motion_damage_micro_time_v10218(kind,unit=nil,extra=nil)
    return yield unless motion_damage_micro_active_v10218?
    t=Time.now.to_f
    result=yield
    ms=((Time.now.to_f-t)*1000.0).round rescue 0
    motion_damage_micro_record_v10218(kind,ms,unit,extra)
    result
  end

  def motion_damage_micro_child_time_v10218(kind,unit=nil,extra=nil)
    return yield unless motion_damage_micro_active_v10218? && motion_damage_micro_context_v10218?
    motion_damage_micro_time_v10218(kind,unit,extra){yield}
  end

  def verify_motion_damage_micro_v10218
    return if @verification_done!=nil && @verification_done[:motion_damage_micro_v10218]
    pass=verification_mode==:pmd_motion_phase_a_v102 &&
      @motion_damage_micro_stats_v10218!=nil && @motion_damage_micro_records_v10218!=nil
    @motion_phase_a_failed_v102=true unless pass
    log_event(:verify,'MOTION_DAMAGE_MICRO_PROFILER_V10218 pass='+(pass ? '1':'0')+
      ' projectile_hit=1 direct_damage_chain=1 independent_buffer=1 threshold_ms='+
      PMD_AC::MOTION_DAMAGE_MICRO_THRESHOLD_MS_V10218.to_s+
      ' behavior_unchanged=1 ai_unchanged=1 damage_unchanged=1 attack_speed_unchanged=1 spatial_unchanged=1')
    @verification_done[:motion_damage_micro_v10218]=true if @verification_done!=nil
  rescue
  end

  def update_verification_script
    result=pmd_ac_v10218_update_verification_script
    if verification_mode==:pmd_motion_phase_a_v102 && @verification_frame.to_i>=59
      verify_motion_damage_micro_v10218
    end
    result
  end

  def motion_damage_micro_log_summary_v10218
    return if @motion_damage_micro_summary_logged_v10218
    return unless verification_mode==:pmd_motion_phase_a_v102
    @motion_damage_micro_summary_logged_v10218=true
    stats=[]
    (@motion_damage_micro_stats_v10218 || {}).each{|k,v|stats.push([v[:max].to_i,k,v])}
    stats.sort!{|a,b|b[0]<=>a[0]}
    text=stats.map do |row|
      v=row[2];avg=v[:calls].to_i<=0 ? 0 : (v[:total].to_i/v[:calls].to_i)
      row[1]+':max'+v[:max].to_s+'/avg'+avg.to_s+'/slow'+v[:slow].to_s+'/calls'+v[:calls].to_s
    end.join(',')
    records=(@motion_damage_micro_records_v10218 || []).dup
    records.sort!{|a,b|b[:ms].to_i<=>a[:ms].to_i}
    hot=records[0,PMD_AC::MOTION_DAMAGE_MICRO_REPORT_LIMIT_V10218] || []
    log_event(:perf,'MOTION_DAMAGE_MICRO_SUMMARY_V10218 records='+records.size.to_s+
      ' report='+hot.size.to_s+' stats=['+text+']')
    hot.each do |r|
      log_event(:perf,'MOTION_DAMAGE_MICRO_HOT_V10218 frame='+r[:frame].to_i.to_s+
        ' kind='+r[:kind].to_s+' ms='+r[:ms].to_i.to_s+' unit='+r[:unit].to_s+
        (r[:extra].to_s=='' ? '' : ' extra='+r[:extra].to_s))
    end
  rescue
  end

  def motion_perf_log_summary_v1023
    already=@motion_perf_summary_logged_v1023
    result=pmd_ac_v10218_motion_perf_log_summary_v1023
    if !already && @motion_perf_summary_logged_v1023
      motion_damage_micro_log_summary_v10218
    end
    result
  end

  def resolve_projectile(projectile)
    u=projectile==nil ? nil : projectile.user
    extra=projectile==nil ? '' : 'kind='+projectile.kind.to_s+' style='+projectile.style.to_s
    motion_damage_micro_child_time_v10218('projectile_resolve_total',u,extra){
      pmd_ac_v10218_resolve_projectile(projectile)
    }
  end

  def deal_direct_damage(user,target,power,options=nil)
    old=$PMD_AC_DAMAGE_CONTEXT_V10218
    $PMD_AC_DAMAGE_CONTEXT_V10218={:user=>user,:target=>target,:options=>options}
    extra='source='+(options==nil ? 'nil' : options[:source_type].to_s)
    begin
      motion_damage_micro_time_v10218('damage_total',user,extra){
        pmd_ac_v10218_deal_direct_damage(user,target,power,options)
      }
    ensure
      $PMD_AC_DAMAGE_CONTEXT_V10218=old
    end
  end

  def pmd_ac_v102_deal_direct_damage(*args)
    u=args[0] rescue nil
    motion_damage_micro_child_time_v10218('damage_pre_motion',u,nil){pmd_ac_v10218_cp_motion(*args)}
  end
  def pmd_ac_v09912_deal_direct_damage(*args)
    u=args[0] rescue nil
    motion_damage_micro_child_time_v10218('damage_below_v09912',u,nil){pmd_ac_v10218_cp_09912(*args)}
  end
  def pmd_ac_v097_deal_direct_damage(*args)
    u=args[0] rescue nil
    motion_damage_micro_child_time_v10218('damage_below_v097',u,nil){pmd_ac_v10218_cp_097(*args)}
  end
  def pmd_ac_v0914_deal_direct_damage(*args)
    u=args[0] rescue nil
    motion_damage_micro_child_time_v10218('damage_below_v0914',u,nil){pmd_ac_v10218_cp_0914(*args)}
  end
  def pmd_ac_v0883_deal_direct_damage(*args)
    u=args[0] rescue nil
    motion_damage_micro_child_time_v10218('damage_below_v0883',u,nil){pmd_ac_v10218_cp_0883(*args)}
  end
  def pmd_ac_v066_deal_direct_damage(*args)
    u=args[0] rescue nil
    motion_damage_micro_child_time_v10218('damage_below_v066',u,nil){pmd_ac_v10218_cp_066(*args)}
  end
  def pmd_ac_v057_deal_direct_damage(*args)
    u=args[0] rescue nil
    motion_damage_micro_child_time_v10218('damage_below_v057',u,nil){pmd_ac_v10218_cp_057(*args)}
  end

  def motion_true_impact_v102(*args)
    u=args[0] rescue nil
    motion_damage_micro_child_time_v10218('motion_true_impact',u,nil){pmd_ac_v10218_motion_true_impact_v102(*args)}
  end
  def motion_route_for_unit_v102(*args)
    u=args[0] rescue nil
    motion_damage_micro_child_time_v10218('motion_route',u,nil){pmd_ac_v10218_motion_route_for_unit_v102(*args)}
  end
  def motion_snap_unit_v102(*args)
    u=args[0] rescue nil
    motion_damage_micro_child_time_v10218('motion_snap',u,nil){pmd_ac_v10218_motion_snap_unit_v102(*args)}
  end

  def add_vfx_impact_xy(*args)
    if $PMD_AC_PROJECTILE_HIT_CONTEXT_V10218!=nil
      return motion_damage_micro_child_time_v10218('projectile_impact_vfx',nil,nil){pmd_ac_v10218_add_vfx_impact_xy(*args)}
    end
    pmd_ac_v10218_add_vfx_impact_xy(*args)
  end

  def refresh_footer(*args)
    if $PMD_AC_PROJECTILE_HIT_CONTEXT_V10218!=nil
      return motion_damage_micro_child_time_v10218('projectile_refresh_footer',nil,nil){pmd_ac_v10218_refresh_footer(*args)}
    end
    pmd_ac_v10218_refresh_footer(*args)
  end

  def play_basic_se(*args)
    if $PMD_AC_PROJECTILE_HIT_CONTEXT_V10218!=nil
      u=args[0] rescue nil
      return motion_damage_micro_child_time_v10218('projectile_basic_se',u,nil){pmd_ac_v10218_play_basic_se(*args)}
    end
    pmd_ac_v10218_play_basic_se(*args)
  end

  def log_event(*args)
    if $PMD_AC_DAMAGE_CONTEXT_V10218!=nil
      u=$PMD_AC_DAMAGE_CONTEXT_V10218[:user] rescue nil
      return motion_damage_micro_child_time_v10218('damage_log_event',u,'cat='+(args[0].to_s rescue '?')){
        pmd_ac_v10218_log_event(*args)
      }
    end
    pmd_ac_v10218_log_event(*args)
  end
end

class Game_PMDChessUnit
  alias pmd_ac_v10218_calculate_damage calculate_damage unless method_defined?(:pmd_ac_v10218_calculate_damage)
  alias pmd_ac_v10218_incoming_arc_from incoming_arc_from unless method_defined?(:pmd_ac_v10218_incoming_arc_from)
  alias pmd_ac_v10218_directional_damage_multiplier directional_damage_multiplier unless method_defined?(:pmd_ac_v10218_directional_damage_multiplier)
  alias pmd_ac_v10218_receive_damage receive_damage unless method_defined?(:pmd_ac_v10218_receive_damage)
  alias pmd_ac_v10218_gain_energy gain_energy unless method_defined?(:pmd_ac_v10218_gain_energy)
  alias pmd_ac_v10218_motion_receive_impact_v102 motion_receive_impact_v102 unless method_defined?(:pmd_ac_v10218_motion_receive_impact_v102)

  def motion_damage_micro_scene_v10218
    s=@scene
    return nil if s==nil || !s.respond_to?(:motion_damage_micro_active_v10218?)
    return nil unless s.motion_damage_micro_active_v10218?
    s
  rescue
    nil
  end

  def motion_damage_micro_unit_child_v10218(kind,extra=nil)
    s=motion_damage_micro_scene_v10218
    return yield if s==nil || !s.motion_damage_micro_context_v10218?
    t=Time.now.to_f;result=yield;ms=((Time.now.to_f-t)*1000.0).round rescue 0
    s.motion_damage_micro_record_v10218(kind,ms,self,extra)
    result
  end

  def calculate_damage(*args)
    motion_damage_micro_unit_child_v10218('damage_calculate'){pmd_ac_v10218_calculate_damage(*args)}
  end
  def incoming_arc_from(*args)
    motion_damage_micro_unit_child_v10218('damage_incoming_arc'){pmd_ac_v10218_incoming_arc_from(*args)}
  end
  def directional_damage_multiplier(*args)
    motion_damage_micro_unit_child_v10218('damage_direction_mult'){pmd_ac_v10218_directional_damage_multiplier(*args)}
  end
  def receive_damage(*args)
    motion_damage_micro_unit_child_v10218('damage_receive'){pmd_ac_v10218_receive_damage(*args)}
  end
  def gain_energy(*args)
    if $PMD_AC_PROJECTILE_HIT_CONTEXT_V10218!=nil
      return motion_damage_micro_unit_child_v10218('projectile_gain_energy'){pmd_ac_v10218_gain_energy(*args)}
    end
    pmd_ac_v10218_gain_energy(*args)
  end
  def motion_receive_impact_v102(*args)
    motion_damage_micro_unit_child_v10218('motion_receive_impact'){pmd_ac_v10218_motion_receive_impact_v102(*args)}
  end
end

class Sprite_PMDProjectile
  alias pmd_ac_v10218_hit hit unless method_defined?(:pmd_ac_v10218_hit)

  def hit(*args)
    s=@scene rescue nil
    active=s!=nil && s.respond_to?(:motion_damage_micro_active_v10218?) && s.motion_damage_micro_active_v10218?
    return pmd_ac_v10218_hit(*args) unless active
    old=$PMD_AC_PROJECTILE_HIT_CONTEXT_V10218
    $PMD_AC_PROJECTILE_HIT_CONTEXT_V10218=self
    t=Time.now.to_f
    begin
      result=pmd_ac_v10218_hit(*args)
    ensure
      ms=((Time.now.to_f-t)*1000.0).round rescue 0
      extra='kind='+@kind.to_s+' style='+@style.to_s
      s.motion_damage_micro_record_v10218('projectile_hit_total',ms,@user,extra) rescue nil
      $PMD_AC_PROJECTILE_HIT_CONTEXT_V10218=old
    end
    result
  end
end
