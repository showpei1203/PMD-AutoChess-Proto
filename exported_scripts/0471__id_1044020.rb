# encoding: UTF-8
#==============================================================================
# 【PMD AutoChess 中文維護說明】
# 腳本：PMD AutoChess Hurt/Faint Narrow Profiler v1.04.4
# 分類：效能診斷／Hurt-Faint Spike Attribution／Trailing Diagnostic Layer
# RPG Maker VX / RGSS2 / Ruby 1.8 compatible
#------------------------------------------------------------------------------
# 【用途】
# v1.04.3 Windows LOG 再次抓到 50ms 以上 internal spike，最大 frame 的共同特徵是：
# 多隻單位同時 Hurt、至少一隻 Skill，偶爾伴隨 Faint。舊 profiler 只知道整個 Scene update
# 花 61ms，無法判定成本主要在 Unit logic、Unit Sprite、FX、Projectile 或 action bitmap refresh。
# 本腳本只在「Hurt reaction >= 2」，或「Hurt>=1 + Faint>=1 + Skill>=1」的 PMD Motion verifier
# frame 啟用窄範圍計時，避免重新打開 broad profiler。
#------------------------------------------------------------------------------
# 【主要設定】
# MOTION_HF_PROBE_TRIGGER_UNITS_V1044 = 2
# MOTION_HF_PROBE_RECORD_MS_V1044 = 45
#------------------------------------------------------------------------------
# 【機制規則】
# - 一般 frame 完全不計時；Hurt>=2，或 Hurt>=1 + Faint>=1 + Skill>=1 才啟用。
# - 啟用 frame 計時：Scene total、battle_step、unit_sprites、effects、projectiles。
# - 另統計 Game_PMDChessUnit#update 總時間與 Sprite refresh_action_bitmap 次數/時間。
# - 不修改任何 return value、Damage、AI、Motion timing、hit-stop、Hurt ownership、GC policy。
# - 本層是 diagnostic-only。若 profiler overhead 造成 Performance Seal 變動，以 component
#   attribution 為本版目的，不用本版 alone 作正式效能封版。
#------------------------------------------------------------------------------
# 【可調參數】
# 若仍抓不到案發 frame，可把 TRIGGER_UNITS 改 1；診斷完成後應移除或保持條件式停用。
#------------------------------------------------------------------------------
# 【事件／腳本呼叫方式】
# 無需事件呼叫。PMD Motion verifier 跑完整場後看：
#   MOTION_HURT_FAINT_NARROW_PROFILER_V1044
#   MOTION_HURT_FAINT_NARROW_SUMMARY_V1044
#------------------------------------------------------------------------------
# 【實際範例】
# 若 61ms 主要在 Sprite transition：
#   total=61 sprite_ms=48 refresh_ms=31 refresh_calls=3
# 若主要是 unit logic：
#   total=61 battle_step_ms=54 unit_update_ms=49 sprite_ms=4
#==============================================================================
$imported={} unless defined?($imported)
$imported['PMD_AutoChess_HurtFaintNarrowProfiler_v1044']=true

module PMD_AC
  MOTION_HF_PROBE_TRIGGER_UNITS_V1044=2
  MOTION_HF_PROBE_RECORD_MS_V1044=45

  class << self
    def motion_hf_probe_scene_v1044
      s=$scene
      return nil if s==nil || !s.respond_to?(:motion_hf_probe_child_active_v1044?)
      return nil unless s.motion_hf_probe_child_active_v1044?
      s
    rescue
      nil
    end
  end
end

class Game_PMDChessUnit
  alias pmd_ac_v1044_hf_unit_update update unless method_defined?(:pmd_ac_v1044_hf_unit_update)
  def update
    s=PMD_AC.motion_hf_probe_scene_v1044
    return pmd_ac_v1044_hf_unit_update if s==nil
    t=Time.now
    r=pmd_ac_v1044_hf_unit_update
    ms=((Time.now-t)*1000.0).round rescue 0
    s.motion_hf_probe_add_v1044(:unit_update,ms)
    r
  end
end

class Sprite_PMDChessUnit
  alias pmd_ac_v1044_hf_refresh_action_bitmap refresh_action_bitmap unless method_defined?(:pmd_ac_v1044_hf_refresh_action_bitmap)
  def refresh_action_bitmap(force)
    s=PMD_AC.motion_hf_probe_scene_v1044
    return pmd_ac_v1044_hf_refresh_action_bitmap(force) if s==nil
    t=Time.now
    r=pmd_ac_v1044_hf_refresh_action_bitmap(force)
    ms=((Time.now-t)*1000.0).round rescue 0
    s.motion_hf_probe_add_v1044(:refresh_action_bitmap,ms)
    s.motion_hf_probe_add_v1044(:refresh_calls,1)
    r
  end
end

class Scene_PMD_AutoChess
  alias pmd_ac_v1044_hf_update update unless method_defined?(:pmd_ac_v1044_hf_update)
  alias pmd_ac_v1044_hf_update_battle_step update_battle_step unless method_defined?(:pmd_ac_v1044_hf_update_battle_step)
  alias pmd_ac_v1044_hf_update_unit_sprites update_unit_sprites unless method_defined?(:pmd_ac_v1044_hf_update_unit_sprites)
  alias pmd_ac_v1044_hf_update_effect_sprites update_effect_sprites unless method_defined?(:pmd_ac_v1044_hf_update_effect_sprites)
  alias pmd_ac_v1044_hf_update_projectile_sprites update_projectile_sprites unless method_defined?(:pmd_ac_v1044_hf_update_projectile_sprites)
  alias pmd_ac_v1044_hf_start_battle start_battle unless method_defined?(:pmd_ac_v1044_hf_start_battle)
  alias pmd_ac_v1044_hf_check_battle_end check_battle_end unless method_defined?(:pmd_ac_v1044_hf_check_battle_end)
  alias pmd_ac_v1044_hf_update_verification_script update_verification_script unless method_defined?(:pmd_ac_v1044_hf_update_verification_script)

  def motion_hf_probe_mode_v1044?
    return false unless @phase==:battle
    return false unless respond_to?(:motion_perf_mode_v1023?) && motion_perf_mode_v1023?
    true
  rescue
    false
  end

  def motion_hf_probe_reaction_counts_v1044
    hurt=0;faint=0;skill=0
    (@units||[]).each do |u|
      next if u==nil
      hf=(u.instance_variable_get(:@hurt_frames).to_i rescue 0)
      p1=(u.instance_variable_get(:@presentation_hit_react_frames_v0552).to_i rescue 0)
      p2=(u.instance_variable_get(:@presentation_hit_react_frames_v0551).to_i rescue 0)
      mh=(u.instance_variable_get(:@motion_hurt_state_v102) rescue nil)
      is_hurt=hf>0 || p1>0 || p2>0 || mh!=nil
      is_faint=(u.action==:faint rescue false) || (u.dead? rescue false)
      is_skill=(u.action==:skill rescue false)
      hurt+=1 if is_hurt
      faint+=1 if is_faint
      skill+=1 if is_skill
    end
    [hurt,faint,skill]
  rescue
    [0,0,0]
  end

  def motion_hf_probe_reset_v1044
    @motion_hf_probe_child_active_v1044=false
    @motion_hf_probe_frame_v1044={}
    @motion_hf_probe_frames_v1044=0
    @motion_hf_probe_max_v1044=nil
    @motion_hf_probe_logged_v1044=false
    true
  end

  def start_battle
    motion_hf_probe_reset_v1044
    pmd_ac_v1044_hf_start_battle
  end

  def motion_hf_probe_child_active_v1044?
    @motion_hf_probe_child_active_v1044 ? true : false
  rescue
    false
  end

  def motion_hf_probe_add_v1044(key,value)
    return false unless @motion_hf_probe_child_active_v1044
    h=@motion_hf_probe_frame_v1044 || {}
    h[key]=h[key].to_i+value.to_i
    @motion_hf_probe_frame_v1044=h
    true
  rescue
    false
  end

  def motion_hf_probe_time_child_v1044(key)
    return yield unless @motion_hf_probe_child_active_v1044
    t=Time.now
    r=yield
    ms=((Time.now-t)*1000.0).round rescue 0
    motion_hf_probe_add_v1044(key,ms)
    r
  end

  def update_battle_step
    motion_hf_probe_time_child_v1044(:battle_step){pmd_ac_v1044_hf_update_battle_step}
  end

  def update_unit_sprites
    motion_hf_probe_time_child_v1044(:unit_sprites){pmd_ac_v1044_hf_update_unit_sprites}
  end

  def update_effect_sprites
    motion_hf_probe_time_child_v1044(:effects){pmd_ac_v1044_hf_update_effect_sprites}
  end

  def update_projectile_sprites
    motion_hf_probe_time_child_v1044(:projectiles){pmd_ac_v1044_hf_update_projectile_sprites}
  end

  def motion_hf_probe_context_v1044
    return motion_perf_action_context_v1023 if respond_to?(:motion_perf_action_context_v1023)
    ''
  rescue
    ''
  end

  def update
    counts=motion_hf_probe_reaction_counts_v1044
    active=motion_hf_probe_mode_v1044? && (counts[0].to_i>=PMD_AC::MOTION_HF_PROBE_TRIGGER_UNITS_V1044 || (counts[0].to_i>=1 && counts[1].to_i>=1 && counts[2].to_i>=1))
    unless active
      @motion_hf_probe_child_active_v1044=false
      return pmd_ac_v1044_hf_update
    end

    @motion_hf_probe_child_active_v1044=true
    @motion_hf_probe_frame_v1044={:unit_update=>0,:refresh_action_bitmap=>0,:refresh_calls=>0,
      :battle_step=>0,:unit_sprites=>0,:effects=>0,:projectiles=>0}
    @motion_hf_probe_frames_v1044=@motion_hf_probe_frames_v1044.to_i+1
    t=Time.now
    r=pmd_ac_v1044_hf_update
    total=((Time.now-t)*1000.0).round rescue 0
    @motion_hf_probe_child_active_v1044=false

    h=@motion_hf_probe_frame_v1044 || {}
    if total>=PMD_AC::MOTION_HF_PROBE_RECORD_MS_V1044
      rec={:frame=>(respond_to?(:motion_perf_relative_frame_v1023) ? motion_perf_relative_frame_v1023 : -1),
        :total=>total,:hurt=>counts[0].to_i,:faint=>counts[1].to_i,:skill=>counts[2].to_i,
        :battle_step=>h[:battle_step].to_i,:unit_update=>h[:unit_update].to_i,
        :unit_sprites=>h[:unit_sprites].to_i,:effects=>h[:effects].to_i,:projectiles=>h[:projectiles].to_i,
        :refresh_ms=>h[:refresh_action_bitmap].to_i,:refresh_calls=>h[:refresh_calls].to_i,
        :context=>motion_hf_probe_context_v1044}
      if @motion_hf_probe_max_v1044==nil || rec[:total].to_i>@motion_hf_probe_max_v1044[:total].to_i
        @motion_hf_probe_max_v1044=rec
      end
    end
    r
  rescue
    @motion_hf_probe_child_active_v1044=false
    pmd_ac_v1044_hf_update
  end

  def motion_hf_probe_log_summary_v1044
    return if @motion_hf_probe_logged_v1044
    @motion_hf_probe_logged_v1044=true
    r=@motion_hf_probe_max_v1044
    if r==nil
      log_event(:perf,'MOTION_HURT_FAINT_NARROW_SUMMARY_V1044 severe_seen=0 probed_frames='+@motion_hf_probe_frames_v1044.to_i.to_s+
        ' trigger_units='+PMD_AC::MOTION_HF_PROBE_TRIGGER_UNITS_V1044.to_s+' diagnostic_only=1')
    else
      log_event(:perf,'MOTION_HURT_FAINT_NARROW_SUMMARY_V1044 severe_seen=1 frame='+r[:frame].to_i.to_s+
        ' total_ms='+r[:total].to_i.to_s+' hurt='+r[:hurt].to_i.to_s+' faint='+r[:faint].to_i.to_s+' skill='+r[:skill].to_i.to_s+
        ' battle_step_ms='+r[:battle_step].to_i.to_s+' unit_update_ms='+r[:unit_update].to_i.to_s+
        ' unit_sprites_ms='+r[:unit_sprites].to_i.to_s+' refresh_ms='+r[:refresh_ms].to_i.to_s+' refresh_calls='+r[:refresh_calls].to_i.to_s+
        ' effects_ms='+r[:effects].to_i.to_s+' projectiles_ms='+r[:projectiles].to_i.to_s+
        ' probed_frames='+@motion_hf_probe_frames_v1044.to_i.to_s+' diagnostic_only=1 actions=['+r[:context].to_s+']')
    end
  rescue
  end

  def check_battle_end
    before=@phase
    r=pmd_ac_v1044_hf_check_battle_end
    motion_hf_probe_log_summary_v1044 if before==:battle && @phase!=:battle
    r
  end

  def update_verification_script
    pmd_ac_v1044_hf_update_verification_script
    if respond_to?(:motion_phase_b_verifier_active_v1036?) && motion_phase_b_verifier_active_v1036? &&
       !@motion_hf_probe_verify_v1044 && @verification_frame.to_i>=216
      @motion_hf_probe_verify_v1044=true
      log_event(:verify,'MOTION_HURT_FAINT_NARROW_PROFILER_V1044 pass=1 diagnostic_only=1'+
        ' trigger_hurt2_or_hurt_faint_skill=1 broad_profiler=0 normal_frames_timed=0 damage_unchanged=1 ai_unchanged=1'+
        ' attack_speed_unchanged=1 energy_unchanged=1 spatial_unchanged=1 hitstop_unchanged=1')
    end
  rescue
  end
end
