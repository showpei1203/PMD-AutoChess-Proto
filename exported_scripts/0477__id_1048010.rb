# encoding: UTF-8
#==============================================================================
# 【PMD AutoChess 中文維護說明】
# 腳本：PMD AutoChess Skill/Faint Event Forensic v1.04.8
# 分類：效能診斷／Skill Resolve + Lethal/Faint Transition／Trailing Diagnostic
# RPG Maker VX / RGSS2 / Ruby 1.8 compatible
#------------------------------------------------------------------------------
# 【用途】
# v1.04.7 Windows 已證明 Zone procedural Bitmap 成本成功移出 live battle：
# live_builds=0、per_zone_draw=0，但 Performance Seal 仍有 57ms internal spike。
# 最大尖峰 frame 的共同狀態為多隻 Skill/Hurt 並伴隨兩隻 Faint，因此本版停止再猜
# Bitmap／Zone，改以「事件式、低頻」計時直接拆解技能結算與致死轉場。
#------------------------------------------------------------------------------
# 【主要設定】
# MOTION_SF_EVENT_RECORD_MS_V1048 = 1
#   單一事件 >=1ms 才算 slow event；所有 event 仍累積 calls/total/max。
# MOTION_SF_MAX_FRAMES_V1048 = 256
#   最多保留 256 個有事件的 frame，不對正常無事件 frame 建資料。
#------------------------------------------------------------------------------
# 【機制規則】
# - 不新增每 frame timer；只在本來就低頻發生的事件方法前後讀 Time.now。
# - 量測：resolve_skill、deal_direct_damage、apply_skill_effects、motion_true_impact、
#   add_vfx_impact、launch_projectile、add_zone、play_skill_se、receive_damage、start_faint，
#   以及 Hurt/Faint action 切換時的 refresh_action_bitmap。
# - 事件時間是 inclusive timing，父子呼叫可能重疊；用途是定位哪一層包含成本，
#   不是把所有欄位相加當作 Scene update 總時間。
# - 戰鬥結束時直接讀既有 v1.03.15 Max Spike Forensic 的 frame，輸出該 frame 的事件明細。
# - 若 Max Spike frame 沒有事件紀錄，另輸出事件總時間最高的 frame，證明要往別層追。
# - 本版 diagnostic-only，不改 Damage、AI、Attack Speed、Energy、Spatial、Action timing、
#   Hurt/Faint ownership、Zone、Projectile、VFX 外觀或 GC policy。
#------------------------------------------------------------------------------
# 【可調參數】
# - RECORD_MS 只影響 slow counter，不影響是否累積事件統計。
# - 診斷完成後應由下一個 root-cause fix 取代／退休，不長期常駐。
#------------------------------------------------------------------------------
# 【事件／腳本呼叫方式】
# 無需事件呼叫。布陣畫面按 S 切到 PMD Motion verifier，完整跑完一場。
# LOG 主要看：
#   MOTION_SKILL_FAINT_EVENT_FORENSIC_V1048
#   MOTION_SKILL_FAINT_EVENT_SUMMARY_V1048
#   MOTION_SKILL_FAINT_EVENT_HOTFRAME_V1048
#------------------------------------------------------------------------------
# 【實際範例】
# 若 Max Spike 57ms 主要包含技能結算：
#   resolve_skill=max45 ... receive_damage=max30 start_faint=max18
# 若 Max Spike 沒有任何事件成本：
#   traced=0
# 則下一版應轉追一般 Unit/Sprite update，而不是繼續改技能／Faint。
#==============================================================================
$imported={} unless defined?($imported)
$imported['PMD_AutoChess_SkillFaintEventForensic_v1048']=true

module PMD_AC
  MOTION_SF_EVENT_RECORD_MS_V1048=1
  MOTION_SF_MAX_FRAMES_V1048=256

  class << self
    def motion_sf_scene_v1048
      s=$scene
      return nil if s==nil || !s.respond_to?(:motion_sf_trace_active_v1048?)
      return nil unless s.motion_sf_trace_active_v1048?
      s
    rescue
      nil
    end

    alias pmd_ac_v1048_sf_play_se play_se unless method_defined?(:pmd_ac_v1048_sf_play_se)
    def play_se(*args)
      s=motion_sf_scene_v1048
      return pmd_ac_v1048_sf_play_se(*args) if s==nil
      t=Time.now.to_f
      r=pmd_ac_v1048_sf_play_se(*args)
      ms=((Time.now.to_f-t)*1000.0).round rescue 0
      s.motion_sf_trace_add_v1048(:audio,ms,nil,(args[0].to_s rescue ''))
      r
    end
  end
end

class Game_PMDChessUnit
  alias pmd_ac_v1048_sf_receive_damage receive_damage unless method_defined?(:pmd_ac_v1048_sf_receive_damage)
  alias pmd_ac_v1048_sf_start_faint start_faint unless method_defined?(:pmd_ac_v1048_sf_start_faint)

  def receive_damage(*args)
    s=@scene
    return pmd_ac_v1048_sf_receive_damage(*args) if s==nil || !s.respond_to?(:motion_sf_trace_active_v1048?) || !s.motion_sf_trace_active_v1048?
    before=(@hp.to_i rescue 0)
    t=Time.now.to_f
    r=pmd_ac_v1048_sf_receive_damage(*args)
    ms=((Time.now.to_f-t)*1000.0).round rescue 0
    after=(@hp.to_i rescue 0)
    lethal=(before>0 && after<=0) ? 1 : 0
    src=(args[1] rescue nil)
    extra='hp='+before.to_s+'>'+after.to_s+' lethal='+lethal.to_s+' src='+(src==nil ? '-' : (src.log_name.to_s rescue '?'))
    s.motion_sf_trace_add_v1048(:receive_damage,ms,self,extra)
    r
  end

  def start_faint
    s=@scene
    return pmd_ac_v1048_sf_start_faint if s==nil || !s.respond_to?(:motion_sf_trace_active_v1048?) || !s.motion_sf_trace_active_v1048?
    first=(instance_variable_get(:@dead_started) ? 0 : 1) rescue 1
    t=Time.now.to_f
    r=pmd_ac_v1048_sf_start_faint
    ms=((Time.now.to_f-t)*1000.0).round rescue 0
    s.motion_sf_trace_add_v1048(:start_faint,ms,self,'first='+first.to_s)
    r
  end
end

class Sprite_PMDChessUnit
  alias pmd_ac_v1048_sf_refresh_action_bitmap refresh_action_bitmap unless method_defined?(:pmd_ac_v1048_sf_refresh_action_bitmap)
  def refresh_action_bitmap(force)
    s=(@unit==nil ? nil : (@unit.scene rescue nil))
    visual=(@unit==nil ? nil : (@unit.visual_action rescue nil))
    trace=(s!=nil && s.respond_to?(:motion_sf_trace_active_v1048?) && s.motion_sf_trace_active_v1048? && [:hurt,:faint].include?(visual))
    return pmd_ac_v1048_sf_refresh_action_bitmap(force) unless trace
    t=Time.now.to_f
    r=pmd_ac_v1048_sf_refresh_action_bitmap(force)
    ms=((Time.now.to_f-t)*1000.0).round rescue 0
    s.motion_sf_trace_add_v1048(:sprite_refresh_reaction,ms,@unit,'visual='+visual.to_s+' force='+(force ? '1':'0'))
    r
  end
end

class Scene_PMD_AutoChess
  alias pmd_ac_v1048_sf_start_battle start_battle unless method_defined?(:pmd_ac_v1048_sf_start_battle)
  alias pmd_ac_v1048_sf_update_verification_script update_verification_script unless method_defined?(:pmd_ac_v1048_sf_update_verification_script)
  alias pmd_ac_v1048_sf_motion_perf_log_summary_v1023 motion_perf_log_summary_v1023 unless method_defined?(:pmd_ac_v1048_sf_motion_perf_log_summary_v1023)
  alias pmd_ac_v1048_sf_resolve_skill resolve_skill unless method_defined?(:pmd_ac_v1048_sf_resolve_skill)
  alias pmd_ac_v1048_sf_deal_direct_damage deal_direct_damage unless method_defined?(:pmd_ac_v1048_sf_deal_direct_damage)
  alias pmd_ac_v1048_sf_apply_skill_effects apply_skill_effects unless method_defined?(:pmd_ac_v1048_sf_apply_skill_effects)
  alias pmd_ac_v1048_sf_motion_true_impact_v102 motion_true_impact_v102 unless method_defined?(:pmd_ac_v1048_sf_motion_true_impact_v102)
  alias pmd_ac_v1048_sf_add_vfx_impact add_vfx_impact unless method_defined?(:pmd_ac_v1048_sf_add_vfx_impact)
  alias pmd_ac_v1048_sf_launch_projectile launch_projectile unless method_defined?(:pmd_ac_v1048_sf_launch_projectile)
  alias pmd_ac_v1048_sf_add_zone add_zone unless method_defined?(:pmd_ac_v1048_sf_add_zone)
  alias pmd_ac_v1048_sf_play_skill_se play_skill_se unless method_defined?(:pmd_ac_v1048_sf_play_skill_se)

  def motion_sf_trace_active_v1048?
    return false unless @phase==:battle
    return false unless respond_to?(:motion_perf_mode_v1023?) && motion_perf_mode_v1023?
    true
  rescue
    false
  end

  def motion_sf_trace_reset_v1048
    @motion_sf_frames_v1048={}
    @motion_sf_order_v1048=[]
    @motion_sf_slow_events_v1048=0
    @motion_sf_summary_logged_v1048=false
    true
  end

  def start_battle
    motion_sf_trace_reset_v1048
    pmd_ac_v1048_sf_start_battle
  end

  def motion_sf_trace_frame_v1048
    return motion_perf_relative_frame_v1023 if respond_to?(:motion_perf_relative_frame_v1023)
    0
  rescue
    0
  end

  def motion_sf_trace_add_v1048(kind,ms,unit=nil,extra=nil)
    return false unless motion_sf_trace_active_v1048?
    @motion_sf_frames_v1048={} if @motion_sf_frames_v1048==nil
    @motion_sf_order_v1048=[] if @motion_sf_order_v1048==nil
    f=motion_sf_trace_frame_v1048.to_i
    h=@motion_sf_frames_v1048[f]
    if h==nil
      if @motion_sf_order_v1048.size>=PMD_AC::MOTION_SF_MAX_FRAMES_V1048
        old=@motion_sf_order_v1048.shift
        @motion_sf_frames_v1048.delete(old)
      end
      h={:events=>{},:units=>[], :extras=>[]}
      @motion_sf_frames_v1048[f]=h
      @motion_sf_order_v1048.push(f)
    end
    k=kind.to_sym
    e=h[:events][k]
    e={:calls=>0,:total=>0,:max=>0,:slow=>0} if e==nil
    n=ms.to_i
    e[:calls]+=1;e[:total]+=n;e[:max]=n if n>e[:max]
    if n>=PMD_AC::MOTION_SF_EVENT_RECORD_MS_V1048
      e[:slow]+=1
      @motion_sf_slow_events_v1048=@motion_sf_slow_events_v1048.to_i+1
    end
    h[:events][k]=e
    if unit!=nil
      name=(unit.log_name.to_s rescue '?')
      h[:units].push(name) unless h[:units].include?(name)
    end
    if extra!=nil && !extra.to_s.empty? && h[:extras].size<8
      h[:extras].push(k.to_s+':'+extra.to_s)
    end
    true
  rescue
    false
  end

  def motion_sf_trace_timed_v1048(kind,unit=nil,extra=nil)
    return yield unless motion_sf_trace_active_v1048?
    t=Time.now.to_f
    r=yield
    ms=((Time.now.to_f-t)*1000.0).round rescue 0
    motion_sf_trace_add_v1048(kind,ms,unit,extra)
    r
  end

  def resolve_skill(*args)
    u=(args[0] rescue nil)
    mk=nil
    begin;d=u==nil ? nil : u.skill_data;mk=d==nil ? nil : (d[:canonical_move_key]||d[:move_key]);rescue;mk=nil;end
    motion_sf_trace_timed_v1048(:resolve_skill,u,'move='+(mk||:unknown).to_s){pmd_ac_v1048_sf_resolve_skill(*args)}
  end

  def deal_direct_damage(*args)
    u=(args[0] rescue nil);targ=(args[1] rescue nil)
    extra='target='+(targ==nil ? '-' : (targ.log_name.to_s rescue '?'))
    motion_sf_trace_timed_v1048(:deal_direct_damage,u,extra){pmd_ac_v1048_sf_deal_direct_damage(*args)}
  end

  def apply_skill_effects(*args)
    u=(args[0] rescue nil);targ=(args[1] rescue nil)
    extra='target='+(targ==nil ? '-' : (targ.log_name.to_s rescue '?'))
    motion_sf_trace_timed_v1048(:apply_skill_effects,u,extra){pmd_ac_v1048_sf_apply_skill_effects(*args)}
  end

  def motion_true_impact_v102(*args)
    u=(args[0] rescue nil);targ=(args[1] rescue nil)
    extra='target='+(targ==nil ? '-' : (targ.log_name.to_s rescue '?'))
    motion_sf_trace_timed_v1048(:motion_true_impact,u,extra){pmd_ac_v1048_sf_motion_true_impact_v102(*args)}
  end

  def add_vfx_impact(*args)
    u=(args[0] rescue nil);style=(args[1] rescue nil)
    motion_sf_trace_timed_v1048(:add_vfx_impact,u,'style='+style.to_s){pmd_ac_v1048_sf_add_vfx_impact(*args)}
  end

  def launch_projectile(*args)
    u=(args[0] rescue nil)
    motion_sf_trace_timed_v1048(:launch_projectile,u,nil){pmd_ac_v1048_sf_launch_projectile(*args)}
  end

  def add_zone(*args)
    u=(args[0] rescue nil)
    motion_sf_trace_timed_v1048(:add_zone,u,nil){pmd_ac_v1048_sf_add_zone(*args)}
  end

  def play_skill_se(*args)
    u=(args[0] rescue nil);stage=(args[1] rescue nil)
    motion_sf_trace_timed_v1048(:play_skill_se,u,'stage='+stage.to_s){pmd_ac_v1048_sf_play_skill_se(*args)}
  end

  def motion_sf_event_text_v1048(h)
    return 'none' if h==nil
    parts=[]
    keys=[:resolve_skill,:deal_direct_damage,:apply_skill_effects,:receive_damage,:start_faint,
      :motion_true_impact,:add_vfx_impact,:launch_projectile,:add_zone,:play_skill_se,:audio,:sprite_refresh_reaction]
    keys.each do |k|
      e=h[:events][k]
      next if e==nil
      parts.push(k.to_s+'=c'+e[:calls].to_i.to_s+'/t'+e[:total].to_i.to_s+'/m'+e[:max].to_i.to_s)
    end
    parts.empty? ? 'none' : parts.join(',')
  rescue
    'error'
  end

  def motion_sf_event_total_v1048(h)
    return 0 if h==nil
    n=0
    h[:events].each_value{|e|n+=e[:total].to_i}
    n
  rescue
    0
  end

  def motion_sf_log_summary_v1048
    return if @motion_sf_summary_logged_v1048
    @motion_sf_summary_logged_v1048=true
    frames=@motion_sf_frames_v1048 || {}
    spike=@motion_max_spike_forensic_v10315 rescue nil
    sf=spike==nil ? -1 : spike[:frame].to_i
    sh=frames[sf]
    traced=sh==nil ? 0 : 1
    log_event(:perf,'MOTION_SKILL_FAINT_EVENT_SUMMARY_V1048 spike_frame='+sf.to_s+
      ' spike_update_ms='+(spike==nil ? '0' : spike[:update].to_i.to_s)+
      ' traced='+traced.to_s+' event_frames='+frames.size.to_s+
      ' slow_events='+@motion_sf_slow_events_v1048.to_i.to_s+
      ' inclusive_timings=1 normal_frame_timer=0 events=['+motion_sf_event_text_v1048(sh)+']'+
      (sh==nil ? '' : ' units=['+(sh[:units]||[]).join(',')+'] extras=['+(sh[:extras]||[]).join('|')+']'))
    hot=nil;hot_score=-1
    frames.each do |f,h|
      score=motion_sf_event_total_v1048(h)
      if score>hot_score;hot_score=score;hot=[f,h];end
    end
    if hot!=nil
      h=hot[1]
      log_event(:perf,'MOTION_SKILL_FAINT_EVENT_HOTFRAME_V1048 frame='+hot[0].to_i.to_s+
        ' inclusive_event_total_ms='+hot_score.to_i.to_s+' events=['+motion_sf_event_text_v1048(h)+']'+
        ' units=['+(h[:units]||[]).join(',')+'] extras=['+(h[:extras]||[]).join('|')+']')
    end
    true
  rescue
    false
  end

  def motion_perf_log_summary_v1023
    already=@motion_perf_summary_logged_v1023
    r=pmd_ac_v1048_sf_motion_perf_log_summary_v1023
    motion_sf_log_summary_v1048 if !already && @motion_perf_summary_logged_v1023
    r
  end

  def update_verification_script
    pmd_ac_v1048_sf_update_verification_script
    if respond_to?(:motion_phase_b_verifier_active_v1036?) && motion_phase_b_verifier_active_v1036? &&
       !@motion_sf_verify_v1048 && @verification_frame.to_i>=226
      @motion_sf_verify_v1048=true
      log_event(:verify,'MOTION_SKILL_FAINT_EVENT_FORENSIC_V1048 pass=1 diagnostic_only=1 event_timing_only=1 normal_frame_timer=0'+
        ' methods=resolve_skill,deal_direct_damage,apply_skill_effects,receive_damage,start_faint,motion_true_impact,vfx,projectile,zone,se,reaction_refresh'+
        ' performance_threshold_unchanged=50 damage_unchanged=1 ai_unchanged=1 attack_speed_unchanged=1 energy_unchanged=1 spatial_unchanged=1')
    end
  rescue
  end
end
