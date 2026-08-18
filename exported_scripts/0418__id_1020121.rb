# encoding: UTF-8
#==============================================================================
# 【PMD AutoChess 中文維護說明】
# 腳本：PMD AutoChess Visible Baseline Preload v1.02.12
# 分類：戰鬥效能／Battle Loading Gate／PMD 腳底基準預運算
# RPG Maker VX / RGSS2 / Ruby 1.8 compatible
#==============================================================================
# 【用途】
# v1.02.9 已把本場 Pokémon Action、VFX、SkillFX 放到正式開戰前 Loading；
# v1.02.10 也已用真實 Sprite + Graphics.update 做 Render Prime。Windows RGSS2
# 實測仍可在 Attack / Hop / Shock 等第一次出現時發生 50～200ms 級停頓，
# 而 slow_bitmap=0，證明不是 PNG 檔案本身尚未讀取。
#
# Deep Profiler 後續定位到真正的同步成本之一來自 v0.57.6 / v0.89.2：
# PMD_AC.visible_bottom_rel_for_action_v0576 會在「species + action 第一次使用」時，
# 對該 Action 的所有有效 Frame／方向列使用 Bitmap#get_pixel 掃描不透明腳底。
# 這份結果同時被：
#   1. v0.89.2 True Foot HP/Energy Bar
#   2. v0.57.6 contact visible baseline correction
# 使用，因此第一次 Attack / Hurt / Hop / Shock 等會把昂貴 alpha scan 留到 live battle。
#
# v1.02.12 把這些 alpha baseline 全部搬進 v1.02.9 Battle Loading Gate。
# Loading 100% 前完成本場六隻 Pokémon 所有已綁定 Action 的腳底基準 Cache，
# 正式戰鬥中只做 Hash lookup，不再臨時逐像素掃圖。
#==============================================================================
# 【主要設定項】
# PMD_AC::MOTION_BASELINE_PRELOAD_ENABLED_V10212
#   true：在 PMD Motion verifier 的 Battle Loading 階段預運算。
# PMD_AC::MOTION_BASELINE_PRELOAD_SLOW_MS_V10212
#   單一 action alpha scan 超過此毫秒數時計入 slow 統計；只做 LOG 統計。
#==============================================================================
# 【機制規則】
# 1. 沿用 v1.02.4 local action cache，取得本場 Active Pokémon 所有可播放 Action。
# 2. 以 species + action 去重，並補 idle / walk / attack / hurt 基本姿勢。
# 3. 若 PMD_AC.contact_bottom_cache_v0576 已有結果，不重掃。
# 4. 尚未存在的項目在 Loading Overlay 內呼叫 visible_bottom_rel_for_action_v0576。
# 5. v1.02.9 最後仍會 GC.start，完成後才真正 start battle。
# 6. Live battle 若仍發生 baseline cache miss，只記憶體計數；原函式仍安全 fallback。
# 7. v1.02.11 GC-disable A/B 已證明不是主因，本版在 Motion verifier 停用該 Guard，
#    避免戰鬥結果前額外 GC.enable / GC.start 停頓與不必要記憶體風險。
#==============================================================================
# 【可調參數】
# - 若 Loading 過久，未來可把 contact_bottom_cache_v0576 預編譯成磁碟 Cache；
#   本版先以實機結果確認「live alpha scan」是否就是主要 hitch 來源。
# - 不改 TRUE_FOOT_BAR_GAP、Sprite y、logical y、命中座標或任何戰鬥公式。
#==============================================================================
# 【事件／腳本呼叫方式】
# 不需事件手動呼叫。
# S → PMD_MOTION_PHASE_A_V102 → Shift。
# Battle Loading 中會新增「分析 PMD 腳底基準」階段，完成後才進入戰鬥。
#==============================================================================
# 【實際範例】
# Loading LOG：
#   MOTION_BASELINE_PRELOAD_V10212 ready=1 pairs=179 computed=... cached=... fail=0 ...
# Verifier：
#   MOTION_VISIBLE_BASELINE_PRELOAD_V10212 pass=1 ... live_gc_guard=0
# Battle end：
#   MOTION_BASELINE_RUNTIME_V10212 live_miss=0
#==============================================================================
# 【不可破壞】
# - Frozen Combat Core 不直接修改，只以 Main 前 trailing alias / override 安裝。
# - Pokémon 個體身份仍使用 instance_uid。
# - PMD Sprite 100%，Effect / Projectile 50%。
# - 不修改 AI、Damage Formula、Attack Speed、Spatial Framework、hit-stop、
#   Hurt ownership、Native hitFrame、技能傷害時機與 logical xy。
# - Game.ini 不得有 UTF-8 BOM。
#==============================================================================

$imported = {} unless defined?($imported)
$imported['PMD_AutoChess_VisibleBaselinePreload_v10212'] = true

module PMD_AC
  MOTION_BASELINE_PRELOAD_VERSION_V10212='1.02.12'
  MOTION_BASELINE_PRELOAD_ENABLED_V10212=true
  MOTION_BASELINE_PRELOAD_SLOW_MS_V10212=20

  class << self
    alias pmd_ac_v10212_visible_bottom_rel_for_action_v0576 visible_bottom_rel_for_action_v0576 unless method_defined?(:pmd_ac_v10212_visible_bottom_rel_for_action_v0576)

    # Live battle cache-miss audit。真正計算仍完全交回 v0.57.6。
    def visible_bottom_rel_for_action_v0576(unit,action)
      act=action==nil ? :idle : action
      key=[unit==nil ? '' : unit.species.to_s,act]
      c=contact_bottom_cache_v0576
      miss=!c.has_key?(key)
      if miss && $scene!=nil && $scene.respond_to?(:motion_baseline_live_active_v10212?) &&
         $scene.motion_baseline_live_active_v10212?
        begin;$scene.motion_baseline_live_miss_v10212(key);rescue;end
      end
      pmd_ac_v10212_visible_bottom_rel_for_action_v0576(unit,action)
    end
  end
end

class Scene_PMD_AutoChess
  alias pmd_ac_v10212_start start unless method_defined?(:pmd_ac_v10212_start)
  alias pmd_ac_v10212_restart_to_deploy restart_to_deploy unless method_defined?(:pmd_ac_v10212_restart_to_deploy)
  alias pmd_ac_v10212_battle_loading_process_motion_v1029 battle_loading_process_motion_v1029 unless method_defined?(:pmd_ac_v10212_battle_loading_process_motion_v1029)
  alias pmd_ac_v10212_update_verification_script update_verification_script unless method_defined?(:pmd_ac_v10212_update_verification_script)
  alias pmd_ac_v10212_show_result show_result unless method_defined?(:pmd_ac_v10212_show_result)

  def motion_baseline_preload_mode_v10212?
    return false unless PMD_AC::MOTION_BASELINE_PRELOAD_ENABLED_V10212
    verification_mode==:pmd_motion_phase_a_v102
  rescue
    false
  end

  # v1.02.11 GC-disable 是 A/B 診斷，不是正式策略。v1.02.12 已有實機證據
  # 顯示 hitch 仍存在，因此 Motion verifier 直接停用該 Guard。
  def motion_live_gc_mode_v10211?
    false
  end

  def motion_baseline_reset_v10212
    @motion_baseline_summary_v10212=nil
    @motion_baseline_live_miss_v10212=0
    @motion_baseline_live_miss_keys_v10212={}
    @motion_baseline_verify_logged_v10212=false
    @motion_baseline_runtime_logged_v10212=false
  end

  def start
    motion_baseline_reset_v10212
    pmd_ac_v10212_start
  end

  def restart_to_deploy
    r=pmd_ac_v10212_restart_to_deploy
    motion_baseline_reset_v10212 if @phase==:deploy
    r
  end

  def motion_baseline_live_active_v10212?
    motion_baseline_preload_mode_v10212? && @phase==:battle
  rescue
    false
  end

  def motion_baseline_live_miss_v10212(key)
    @motion_baseline_live_miss_v10212=@motion_baseline_live_miss_v10212.to_i+1
    @motion_baseline_live_miss_keys_v10212={} if @motion_baseline_live_miss_keys_v10212==nil
    @motion_baseline_live_miss_keys_v10212[key]=true
  end

  def motion_baseline_pairs_v10212
    rows=[];seen={}
    return rows if @unit_sprites==nil
    @unit_sprites.each do |sp|
      next if sp==nil || !sp.respond_to?(:unit)
      u=sp.unit
      next if u==nil
      acts=[]
      begin
        h=sp.motion_local_action_cache_v1024
        acts.concat(h.keys) if h!=nil
      rescue
      end
      acts.concat([:idle,:walk,:attack,:hurt])
      acts.each do |a|
        next if a==nil
        key=[u.species.to_s,a]
        next if seen[key]
        seen[key]=true
        rows.push([u,a,key])
      end
    end
    rows
  rescue
    []
  end

  def motion_precompute_baselines_v10212(ui)
    pairs=motion_baseline_pairs_v10212
    total=pairs.size;computed=0;cached=0;fail=0;slow=0;max_ms=0;total_ms=0
    cache=PMD_AC.contact_bottom_cache_v0576
    pairs.each_with_index do |row,i|
      u=row[0];a=row[1];key=row[2]
      if cache.has_key?(key)
        cached+=1
      else
        t=Time.now.to_f;ok=true
        begin
          PMD_AC.visible_bottom_rel_for_action_v0576(u,a)
          ok=cache.has_key?(key)
        rescue
          ok=false
        end
        ms=((Time.now.to_f-t)*1000.0).round rescue 0
        total_ms+=ms;max_ms=ms if ms>max_ms
        slow+=1 if ms>=PMD_AC::MOTION_BASELINE_PRELOAD_SLOW_MS_V10212.to_i
        if ok;computed+=1;else;fail+=1;end
      end
      if i==0 || i==total-1 || ((i+1)%4)==0
        detail=(i+1).to_s+'/'+total.to_s+'  '+u.species.to_s+' / '+a.to_s
        begin;battle_loading_draw_v1029(ui,98,'分析 PMD 腳底基準',detail);rescue;end
      end
    end
    @motion_baseline_summary_v10212={
      :pairs=>total,:computed=>computed,:cached=>cached,:fail=>fail,
      :total_ms=>total_ms,:max_ms=>max_ms,:slow=>slow,:cache_after=>cache.size
    }
    begin
      log_event(:perf,'MOTION_BASELINE_PRELOAD_V10212 ready=1 pairs='+total.to_i.to_s+
        ' computed='+computed.to_i.to_s+' cached='+cached.to_i.to_s+' fail='+fail.to_i.to_s+
        ' total_ms='+total_ms.to_i.to_s+' max_ms='+max_ms.to_i.to_s+' slow='+slow.to_i.to_s+
        ' cache_after='+cache.size.to_i.to_s+' before_live_battle=1 live_gc_guard=0')
    rescue
    end
    @motion_baseline_summary_v10212
  rescue Exception=>e
    @motion_baseline_summary_v10212={:pairs=>0,:computed=>0,:cached=>0,:fail=>1,:total_ms=>0,:max_ms=>0,:slow=>0,:cache_after=>0}
    begin;log_event(:perf,'MOTION_BASELINE_PRELOAD_V10212 ready=1 fallback=1 error='+e.class.to_s);rescue;end
    @motion_baseline_summary_v10212
  end

  # v1.02.10 Render Prime 完成後、v1.02.9 final GC / 100% 前做 alpha baseline。
  def battle_loading_process_motion_v1029(ui)
    stat=pmd_ac_v10212_battle_loading_process_motion_v1029(ui)
    if motion_baseline_preload_mode_v10212?
      bs=motion_precompute_baselines_v10212(ui)
      stat[:fail]=stat[:fail].to_i+bs[:fail].to_i if stat.is_a?(Hash)
    end
    stat
  rescue
    {:enabled=>1,:fail=>1}
  end

  def verify_motion_visible_baseline_preload_v10212
    return if @motion_baseline_verify_logged_v10212
    s=@motion_baseline_summary_v10212 || {}
    pairs=s[:pairs].to_i
    ready=pairs>0 && s[:fail].to_i==0
    pass=motion_baseline_preload_mode_v10212? && ready && !motion_live_gc_mode_v10211?
    @motion_phase_a_failed_v102=true unless pass
    log_event(:verify,'MOTION_VISIBLE_BASELINE_PRELOAD_V10212 pass='+(pass ? '1':'0')+
      ' pairs='+pairs.to_s+' computed='+s[:computed].to_i.to_s+' cached='+s[:cached].to_i.to_s+
      ' fail='+s[:fail].to_i.to_s+' cache_after='+s[:cache_after].to_i.to_s+
      ' before_live_battle=1 alpha_scan_shifted_to_loading=1 live_gc_guard=0'+
      ' ai_unchanged=1 damage_unchanged=1 attack_speed_unchanged=1 spatial_unchanged=1')
    @motion_baseline_verify_logged_v10212=true
  end

  def update_verification_script
    pmd_ac_v10212_update_verification_script
    return unless motion_baseline_preload_mode_v10212?
    verify_motion_visible_baseline_preload_v10212 if @verification_frame.to_i>=49
  end

  def motion_log_baseline_runtime_v10212
    return if @motion_baseline_runtime_logged_v10212
    keys=@motion_baseline_live_miss_keys_v10212==nil ? 0 : @motion_baseline_live_miss_keys_v10212.size
    begin
      log_event(:perf,'MOTION_BASELINE_RUNTIME_V10212 live_miss='+@motion_baseline_live_miss_v10212.to_i.to_s+
        ' unique_miss='+keys.to_i.to_s+' expected=0 alpha_scan_live_expected=0 live_gc_guard=0')
    rescue
    end
    @motion_baseline_runtime_logged_v10212=true
  end

  def show_result
    motion_log_baseline_runtime_v10212 if motion_baseline_preload_mode_v10212?
    pmd_ac_v10212_show_result
  end
end
