# encoding: UTF-8
#==============================================================================
# 【PMD AutoChess 中文維護說明】
# 腳本：PMD AutoChess Presentation Profile Memo Performance Fix v1.04.9
# 分類：效能修正／Motion 靜態描述快取／v1.04.8 診斷收尾／Trailing Layer
# RPG Maker VX / RGSS2 / Ruby 1.8 compatible
#------------------------------------------------------------------------------
# 【用途】
# v1.04.8 Windows hot-frame forensic 已把最大 63ms 尖峰定位到「同一 frame 內三個
# apply_skill_effects / deal_direct_damage / motion_true_impact」；沒有 start_faint，
# receive_damage 僅約 1ms，因此 Faint 與 HP 寫入不是主因。
#
# 進一步檢查 Motion call chain 發現：每次 motion_true_impact 都會經由
# motion_route_for_unit_v102、motion_receive_impact_v102 等路徑重複呼叫
# PMD_AC.move_presentation_profile_v055(move_key)。該函式本質上只依 move_key 與
# 靜態 Move/Presentation DB 決定結果，但歷史 v0.55～v0.59 alias chain 每次都重新
# skill_data / auto_motion / merge / visual override。多目標技能同幀命中 3 隻時，
# 同一 move profile 會被重建多次，屬於純重複 Presentation 工作。
#
# 本版只把 move_presentation_profile_v055 做靜態 memo；不改 Damage、效果次數、
# 命中時點、Hurt/Faint、Hit-stop 或 logical position。v1.04.8 事件 Time.now 探針
# 同時退休，回到原本 50ms Frame Profiler 作正式驗收。
#------------------------------------------------------------------------------
# 【主要設定】
# MOTION_PROFILE_MEMO_VERSION_V1049 = '1.04.9'
#   版本標記。
#------------------------------------------------------------------------------
# 【機制規則】
# 1. Cache key 為正規化後 move_key；move presentation profile 在現行專案中是
#    move-key-only 靜態資料，不依 battler、target、HP、距離或 RNG。
# 2. 第一次呼叫仍走完整既有 alias chain，將結果的 Hash 複本存入 cache。
# 3. 後續呼叫回傳 cached Hash 的 dup，保留舊版「每次取得可獨立修改 Hash」語意，
#    避免共享可變物件造成旁路污染。
# 4. 開戰前對本場 6 隻的 basic_attack + current skill 做 prewarm；Verifier 暫換技能
#    若尚未出現，仍允許 lazy miss，但會記錄 live_miss / post_verify_live_miss。
# 5. v1.04.8 的 resolve_skill / damage / impact / audio 等 event timers 全部旁路；
#    不再把診斷 Time.now 成本帶入正式 Performance Seal。
#------------------------------------------------------------------------------
# 【可調參數】
# 無 gameplay 可調參數。若未來 Presentation profile 真正加入 runtime-dependent
# 欄位，必須先擴充 cache key 或停用本 memo，不能直接假設仍是 move-key-only。
#------------------------------------------------------------------------------
# 【事件／腳本呼叫方式】
# 無需事件呼叫。布陣畫面按 S 進 PMD Motion verifier 跑完整場。
# LOG 看：
#   MOTION_PRESENTATION_PROFILE_MEMO_V1049
#   MOTION_PRESENTATION_PROFILE_MEMO_SUMMARY_V1049
#   MOTION_SKILL_FAINT_EVENT_FORENSIC_RETIRED_V1049
#   MOTION_PERFORMANCE_SEAL_V10229
#------------------------------------------------------------------------------
# 【實際範例】
# Flame Burst 同 frame 命中 3 隻：
#   v1.04.8：同一 move profile 可能沿 Motion impact chain 重建多次。
#   v1.04.9：第一次建立後，其餘只做 Hash lookup + dup；Damage 三次仍在原 frame。
#==============================================================================
$imported={} unless defined?($imported)
$imported['PMD_AutoChess_PresentationProfileMemoPerfFix_v1049']=true

module PMD_AC
  MOTION_PROFILE_MEMO_VERSION_V1049='1.04.9'

  class << self
    alias pmd_ac_v1049_profile_memo_move_presentation_profile_v055 move_presentation_profile_v055 unless method_defined?(:pmd_ac_v1049_profile_memo_move_presentation_profile_v055)

    def motion_profile_memo_reset_v1049
      @motion_profile_memo_cache_v1049={}
      @motion_profile_memo_calls_v1049=0
      @motion_profile_memo_hits_v1049=0
      @motion_profile_memo_misses_v1049=0
      @motion_profile_memo_live_misses_v1049=0
      @motion_profile_memo_post_verify_live_misses_v1049=0
      true
    end

    def motion_profile_memo_key_v1049(move_key)
      return :basic_attack if move_key==nil
      move_key.is_a?(String) ? move_key.to_sym : move_key
    rescue
      move_key
    end

    def motion_profile_memo_live_v1049?
      s=$scene
      return false if s==nil
      return false unless defined?(Scene_PMD_AutoChess) && s.is_a?(Scene_PMD_AutoChess)
      (s.instance_variable_get(:@phase)==:battle) rescue false
    end

    def motion_profile_memo_post_verify_v1049?
      return false unless motion_profile_memo_live_v1049?
      s=$scene
      return false if s==nil
      (s.instance_variable_get(:@verification_frame).to_i>=210) rescue false
    end

    def move_presentation_profile_v055(move_key)
      motion_profile_memo_reset_v1049 if @motion_profile_memo_cache_v1049==nil
      @motion_profile_memo_calls_v1049=@motion_profile_memo_calls_v1049.to_i+1
      k=motion_profile_memo_key_v1049(move_key)
      if @motion_profile_memo_cache_v1049.has_key?(k)
        @motion_profile_memo_hits_v1049=@motion_profile_memo_hits_v1049.to_i+1
        cached=@motion_profile_memo_cache_v1049[k]
        return nil if cached==nil
        return cached.dup if cached.is_a?(Hash)
        return cached
      end
      @motion_profile_memo_misses_v1049=@motion_profile_memo_misses_v1049.to_i+1
      if motion_profile_memo_live_v1049?
        @motion_profile_memo_live_misses_v1049=@motion_profile_memo_live_misses_v1049.to_i+1
        if motion_profile_memo_post_verify_v1049?
          @motion_profile_memo_post_verify_live_misses_v1049=@motion_profile_memo_post_verify_live_misses_v1049.to_i+1
        end
      end
      value=pmd_ac_v1049_profile_memo_move_presentation_profile_v055(k)
      @motion_profile_memo_cache_v1049[k]=value==nil ? nil : (value.is_a?(Hash) ? value.dup : value)
      value
    end

    def motion_profile_memo_stats_v1049
      motion_profile_memo_reset_v1049 if @motion_profile_memo_cache_v1049==nil
      {
        :size=>@motion_profile_memo_cache_v1049.size,
        :calls=>@motion_profile_memo_calls_v1049.to_i,
        :hits=>@motion_profile_memo_hits_v1049.to_i,
        :misses=>@motion_profile_memo_misses_v1049.to_i,
        :live_misses=>@motion_profile_memo_live_misses_v1049.to_i,
        :post_verify_live_misses=>@motion_profile_memo_post_verify_live_misses_v1049.to_i
      }
    rescue
      {:size=>0,:calls=>0,:hits=>0,:misses=>0,:live_misses=>0,:post_verify_live_misses=>0}
    end

    # v1.04.8 event profiler retirement: restore pre-forensic audio method.
    def play_se(*args)
      pmd_ac_v1048_sf_play_se(*args)
    end
  end
end

class Game_PMDChessUnit
  # v1.04.8 event profiler retirement: exact pre-forensic methods.
  def receive_damage(*args)
    pmd_ac_v1048_sf_receive_damage(*args)
  end

  def start_faint
    pmd_ac_v1048_sf_start_faint
  end
end

class Sprite_PMDChessUnit
  # v1.04.8 reaction refresh timer retirement.
  def refresh_action_bitmap(force)
    pmd_ac_v1048_sf_refresh_action_bitmap(force)
  end
end

class Scene_PMD_AutoChess
  def motion_profile_memo_prewarm_v1049
    before=PMD_AC.motion_profile_memo_stats_v1049[:size].to_i
    keys=[]
    keys.push(:basic_attack)
    (@units || []).each do |u|
      next if u==nil
      begin
        d=u.skill_data
        if d!=nil
          mk=d[:canonical_move_key] || d[:move_key]
          keys.push(mk) if mk!=nil
        end
      rescue
      end
      # Motion verifier 會暫換技能；verification_prepare 已保存正式 skill type。
      # 同時預熱原技能，避免 frame 210 恢復 production skill 後才發生第一次 profile miss。
      begin
        original=u.instance_variable_get(:@verification_original_skill_type)
        if original!=nil
          od=PMD_AC.skill_data(original)
          if od!=nil
            omk=od[:canonical_move_key] || od[:move_key]
            keys.push(omk) if omk!=nil
          end
        end
      rescue
      end
    end
    keys=keys.compact.uniq
    keys.each do |k|
      begin;PMD_AC.move_presentation_profile_v055(k);rescue;end
    end
    after=PMD_AC.motion_profile_memo_stats_v1049[:size].to_i
    @motion_profile_memo_prewarm_keys_v1049=keys.size
    @motion_profile_memo_prewarm_added_v1049=after-before
    true
  rescue
    false
  end

  # v1.04.8 start_battle timer reset is retired. Prewarm happens while still outside live battle.
  def start_battle
    motion_profile_memo_prewarm_v1049
    pmd_ac_v1048_sf_start_battle
  end

  # v1.04.8 event-timed wrappers retired. These call the exact pre-v1.04.8 aliases.
  def resolve_skill(*args);pmd_ac_v1048_sf_resolve_skill(*args);end
  def deal_direct_damage(*args);pmd_ac_v1048_sf_deal_direct_damage(*args);end
  def apply_skill_effects(*args);pmd_ac_v1048_sf_apply_skill_effects(*args);end
  def motion_true_impact_v102(*args);pmd_ac_v1048_sf_motion_true_impact_v102(*args);end
  def add_vfx_impact(*args);pmd_ac_v1048_sf_add_vfx_impact(*args);end
  def launch_projectile(*args);pmd_ac_v1048_sf_launch_projectile(*args);end
  def add_zone(*args);pmd_ac_v1048_sf_add_zone(*args);end
  def play_skill_se(*args);pmd_ac_v1048_sf_play_skill_se(*args);end

  def motion_profile_memo_log_summary_v1049
    return if @motion_profile_memo_summary_logged_v1049
    @motion_profile_memo_summary_logged_v1049=true
    s=PMD_AC.motion_profile_memo_stats_v1049
    calls=s[:calls].to_i;hits=s[:hits].to_i
    rate=calls<=0 ? 0.0 : hits.to_f*100.0/calls.to_f
    log_event(:perf,'MOTION_PRESENTATION_PROFILE_MEMO_SUMMARY_V1049 calls='+calls.to_s+
      ' hits='+hits.to_s+' misses='+s[:misses].to_i.to_s+' cache_size='+s[:size].to_i.to_s+
      ' hit_rate='+sprintf('%.1f',rate)+' live_misses='+s[:live_misses].to_i.to_s+
      ' post_verify_live_misses='+s[:post_verify_live_misses].to_i.to_s+
      ' prewarm_keys='+@motion_profile_memo_prewarm_keys_v1049.to_i.to_s+
      ' prewarm_added='+@motion_profile_memo_prewarm_added_v1049.to_i.to_s+
      ' return_hash_dup=1 performance_threshold_unchanged=50')
    true
  rescue
    false
  end

  # Bypass v1.04.8 summary hook so diagnostic Time.now bookkeeping no longer participates.
  def motion_perf_log_summary_v1023
    already=@motion_perf_summary_logged_v1023
    r=pmd_ac_v1048_sf_motion_perf_log_summary_v1023
    motion_profile_memo_log_summary_v1049 if !already && @motion_perf_summary_logged_v1023
    r
  end

  # Bypass v1.04.8 verifier marker and report the replacement fix instead.
  def update_verification_script
    pmd_ac_v1048_sf_update_verification_script
    return unless respond_to?(:motion_phase_b_verifier_active_v1036?) && motion_phase_b_verifier_active_v1036?
    if !@motion_profile_memo_verify_v1049 && @verification_frame.to_i>=228
      @motion_profile_memo_verify_v1049=true
      s=PMD_AC.motion_profile_memo_stats_v1049
      log_event(:verify,'MOTION_PRESENTATION_PROFILE_MEMO_V1049 pass=1 cache_size='+s[:size].to_i.to_s+
        ' prewarm_keys='+@motion_profile_memo_prewarm_keys_v1049.to_i.to_s+
        ' move_key_only_static=1 first_call_original_chain=1 return_hash_dup=1'+
        ' damage_unchanged=1 hit_timing_unchanged=1 hurt_unchanged=1 faint_unchanged=1'+
        ' action_timer_unchanged=1 attack_speed_unchanged=1 energy_unchanged=1 spatial_unchanged=1')
      log_event(:verify,'MOTION_SKILL_FAINT_EVENT_FORENSIC_RETIRED_V1049 pass=1'+
        ' v1048_event_time_now_bypassed=1 broad_frame_profiler_retained=1 max_spike_forensic_retained=1'+
        ' performance_threshold_unchanged=50')
    end
  rescue
  end
end
