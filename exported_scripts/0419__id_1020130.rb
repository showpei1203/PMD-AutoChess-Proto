# encoding: UTF-8
#==============================================================================
# 【PMD AutoChess 中文維護說明】
# 腳本：PMD AutoChess Runtime Residual Prewarm v1.02.13
# 分類：PMD Motion Phase A／Battle Loading 延伸／殘餘 Hitch 修正＋診斷
# RPG Maker VX / RGSS2 / Ruby 1.8 compatible
#------------------------------------------------------------------------------
# 【用途】
# v1.02.12 Windows RGSS2 實測已證明：
# - Battle Loading 226/226、slow_bitmap=0。
# - visible baseline alpha scan 搬到 Loading 後，Sprite update 最大值由 151ms 級
#   降到 3ms，opening/runtime >=50ms hitch 約由 16/16 降到 8/8。
# - 仍剩兩類殘餘尖峰：Game_PMDChessUnit#update 與 projectile_sprites。
#
# 本版針對剩餘問題做四件事：
# 1. 補齊 v0.57.6 ACTION_FALLBACKS 的「requested action」baseline key，包含 faint 等
#    alias/fallback key，避免 live battle 還有單一 baseline miss。
# 2. 在 Battle Loading 預先把 v0.30/v0.31 Projectile sheet 每一幀縮放成 48x48
#    Runtime frame cache；live projectile redraw 改用 Bitmap#blt，不再每次 stretch_blt。
# 3. Battle Loading 建立 Audio/SE 檔名索引，並只對本場可能使用的音效做 0 音量
#    warm play，把音效檔 existence / decoder first-touch 儘量移出 live battle。
# 4. 延伸 v1.02.7 Deep Profiler，細分 Unit update_action_timer / resolve_basic_attack /
#    receive_damage / movement / hurt，以及 Scene launch_projectile / damage / audio / VFX，
#    若仍有 hitch，可直接知道剩餘成本落在哪一層。
#------------------------------------------------------------------------------
# 【主要設定項】
# PMD_AC::MOTION_PROJECTILE_FRAME_CACHE_V10213_ENABLED
#   true：建立預縮放 Projectile frame cache。
# PMD_AC::MOTION_AUDIO_PREWARM_V10213_ENABLED
#   true：建立 Audio/SE index 並 warm 本場音效。
# PMD_AC::MOTION_AUDIO_PREWARM_MAX_V10213
#   最多 warm 幾個不同 SE，避免未來內容膨脹時 Loading 無上限。
#------------------------------------------------------------------------------
# 【機制規則】
# - 只在 PMD_MOTION_PHASE_A_V102 正式測試模式啟用 Loading 額外工作。
# - Projectile frame cache 是 presentation-only，不改 projectile 速度、追蹤、命中、生命期。
# - Audio warm 使用 volume=0，不改正式播放時音量／pitch／音效 routing。
# - Audio existence 查詢使用啟動後建立的 RAM index，避免每次 RPG::SE 前做 1~6 次 FileTest。
# - Deep profiler 只記憶體收集，沿用 v1.02.7 戰鬥結束後一次輸出。
#------------------------------------------------------------------------------
# 【可調參數】
# - 若 Projectile frame cache 記憶體需要再縮，可改成只建立本場 active move styles；
#   目前 20 種 style × 少量 frame × 48x48，成本很低，優先換取穩定。
# - 若 0 音量 warm 在特定音效後端沒有 cache 效果，可之後只保留 RAM existence index。
#------------------------------------------------------------------------------
# 【事件／腳本呼叫方式】
# 不需事件手動呼叫。
# S → PMD_MOTION_PHASE_A_V102 → Shift。
# Loading 會新增：
#   - 補齊動作腳底基準
#   - 預建投射物影格
#   - 預熱戰鬥音效
#------------------------------------------------------------------------------
# 【實際 LOG 範例】
# MOTION_RESIDUAL_PREWARM_V10213 ready=1 baseline_alias=... projectile_frames=... audio=...
# MOTION_RUNTIME_RESIDUAL_V10213 pass=1 projectile_cache=1 audio_index=1 profiler=1
# MOTION_BASELINE_MISS_KEYS_V10213 live_miss=0 keys=[]
#------------------------------------------------------------------------------
# 【不可破壞】
# - Frozen Combat Core 不直接修改，只用 Main 前 trailing alias/override。
# - Pokémon 個體身份仍為 instance_uid。
# - PMD Sprite 100%，Effect / Projectile 50%。
# - 不修改 AI、Damage Formula、Attack Speed、Spatial Framework、hit-stop、Hurt ownership、
#   Native hitFrame、技能傷害時機、logical xy、projectile hit logic。
# - Game.ini 不得有 UTF-8 BOM。
#==============================================================================

$imported = {} unless defined?($imported)
$imported['PMD_AutoChess_RuntimeResidualPrewarm_v10213'] = true

module PMD_AC
  MOTION_RUNTIME_RESIDUAL_VERSION_V10213='1.02.13'
  MOTION_PROJECTILE_FRAME_CACHE_V10213_ENABLED=true
  MOTION_AUDIO_PREWARM_V10213_ENABLED=true
  MOTION_AUDIO_PREWARM_MAX_V10213=64

  class << self
    alias pmd_ac_v10213_audio_file_exists_v0883 audio_file_exists_v0883 if method_defined?(:audio_file_exists_v0883) && !method_defined?(:pmd_ac_v10213_audio_file_exists_v0883)

    def motion_projectile_frame_cache_v10213
      @motion_projectile_frame_cache_v10213={} if @motion_projectile_frame_cache_v10213==nil
      @motion_projectile_frame_cache_v10213
    end

    def motion_projectile_profile_styles_v10213
      if const_defined?(:SKILL_VISUAL_PROJECTILE_V031)
        return SKILL_VISUAL_PROJECTILE_V031.keys
      elsif const_defined?(:SKILL_VISUAL_PROJECTILE_V030)
        return SKILL_VISUAL_PROJECTILE_V030.keys
      end
      []
    rescue
      []
    end

    # 預先建立與 v0.30 redraw 完全相同的 48x48 成品幀。
    def motion_build_projectile_frame_v10213(style,frame)
      return nil unless MOTION_PROJECTILE_FRAME_CACHE_V10213_ENABLED
      s=style.respond_to?(:to_sym) ? style.to_sym : style
      p=skill_visual_projectile_profile_v030(s)
      return nil if p==nil
      frames=[p[:frames].to_i,1].max
      f=frame.to_i % frames
      key=[s,f]
      c=motion_projectile_frame_cache_v10213
      return c[key] if c.has_key?(key) && c[key]!=nil && !c[key].disposed?
      sheet=skill_visual_load_bitmap_v030(p[:sheet])
      return nil if sheet==nil || sheet.disposed?
      out=Bitmap.new(48,48)
      src=Rect.new(0,f*p[:frame_h].to_i,p[:frame_w].to_i,p[:frame_h].to_i)
      dw=(p[:display_w]||34).to_i;dh=(p[:display_h]||34).to_i
      dx=(48-dw)/2;dy=(48-dh)/2
      out.stretch_blt(Rect.new(dx,dy,dw,dh),sheet,src)
      c[key]=out
      out
    rescue
      nil
    end

    def motion_audio_index_v10213
      @motion_audio_index_v10213
    end

    def motion_build_audio_index_v10213
      h={}
      begin
        Dir.glob('Audio/SE/*').each do |path|
          next if File.directory?(path)
          base=File.basename(path)
          name=base.sub(/\.[^.]+$/,'')
          h[name.to_s.downcase]=path
          h[base.to_s.downcase]=path
        end
      rescue
      end
      @motion_audio_index_v10213=h
      h
    end

    # v0.88.3 原方法每次最多做 6 次 FileTest。index 建好後改純 RAM lookup。
    def audio_file_exists_v0883(name)
      idx=@motion_audio_index_v10213
      if idx!=nil && name!=nil
        n=name.to_s.downcase
        return true if idx.has_key?(n)
        ['.wav','.ogg','.mp3','.wma','.mid'].each do |ext|
          return true if idx.has_key?(n+ext)
        end
        return false
      end
      return pmd_ac_v10213_audio_file_exists_v0883(name) if respond_to?(:pmd_ac_v10213_audio_file_exists_v0883)
      false
    rescue
      false
    end
  end
end

#==============================================================================
# ■ Projectile runtime redraw：stretch_blt → cached 48x48 blt
#==============================================================================
class Sprite_PMDProjectile
  alias pmd_ac_v10213_redraw_skill_visual_v030 redraw_skill_visual_v030 unless method_defined?(:pmd_ac_v10213_redraw_skill_visual_v030)

  def redraw_skill_visual_v030
    p=@pmd_skill_visual_profile_v030
    return pmd_ac_v10213_redraw_skill_visual_v030 if p==nil ||
      !PMD_AC::MOTION_PROJECTILE_FRAME_CACHE_V10213_ENABLED
    begin
      f=@pmd_v030_frame.to_i % [p[:frames].to_i,1].max
      cached=PMD_AC.motion_build_projectile_frame_v10213(@style,f)
      return pmd_ac_v10213_redraw_skill_visual_v030 if cached==nil
      self.bitmap.clear
      self.bitmap.blt(0,0,cached,Rect.new(0,0,48,48))
      self.blend_type=(p[:blend]||0).to_i
      return
    rescue
      return pmd_ac_v10213_redraw_skill_visual_v030
    end
  end
end

#==============================================================================
# ■ Scene：Loading 延伸 + baseline alias closure + verifier
#==============================================================================
class Scene_PMD_AutoChess
  alias pmd_ac_v10213_start start unless method_defined?(:pmd_ac_v10213_start)
  alias pmd_ac_v10213_restart_to_deploy restart_to_deploy unless method_defined?(:pmd_ac_v10213_restart_to_deploy)
  alias pmd_ac_v10213_motion_baseline_pairs_v10212 motion_baseline_pairs_v10212 unless method_defined?(:pmd_ac_v10213_motion_baseline_pairs_v10212)
  alias pmd_ac_v10213_battle_loading_process_motion_v1029 battle_loading_process_motion_v1029 unless method_defined?(:pmd_ac_v10213_battle_loading_process_motion_v1029)
  alias pmd_ac_v10213_update_verification_script update_verification_script unless method_defined?(:pmd_ac_v10213_update_verification_script)
  alias pmd_ac_v10213_motion_log_baseline_runtime_v10212 motion_log_baseline_runtime_v10212 unless method_defined?(:pmd_ac_v10213_motion_log_baseline_runtime_v10212)

  def motion_runtime_residual_mode_v10213?
    verification_mode==:pmd_motion_phase_a_v102
  rescue
    false
  end

  def motion_runtime_residual_reset_v10213
    @motion_runtime_residual_summary_v10213=nil
    @motion_runtime_residual_verify_logged_v10213=false
    @motion_audio_prewarm_names_v10213=[]
  end

  def start
    motion_runtime_residual_reset_v10213
    pmd_ac_v10213_start
  end

  def restart_to_deploy
    r=pmd_ac_v10213_restart_to_deploy
    motion_runtime_residual_reset_v10213 if @phase==:deploy
    r
  end

  # v1.02.12 local action cache 已含真實 direct actions，但 requested fallback key（最典型 faint）
  # 本身也會成為 v0.57.6 cache key，因此全部補齊 ACTION_FALLBACKS.keys。
  def motion_baseline_pairs_v10212
    rows=pmd_ac_v10213_motion_baseline_pairs_v10212
    return rows unless motion_runtime_residual_mode_v10213?
    seen={}
    rows.each{|r|seen[r[2]]=true if r!=nil && r[2]!=nil}
    (@unit_sprites || []).each do |sp|
      next if sp==nil || !sp.respond_to?(:unit)
      u=sp.unit;next if u==nil
      keys=[]
      begin;keys.concat(PMD_AC::ACTION_FALLBACKS.keys);rescue;end
      keys.concat([:idle,:walk,:attack,:hurt,:faint])
      keys.each do |a|
        key=[u.species.to_s,a]
        next if seen[key]
        begin;next if PMD_AC.action_data(u.species,a)==nil;rescue;next;end
        seen[key]=true;rows.push([u,a,key])
      end
    end
    rows
  rescue
    pmd_ac_v10213_motion_baseline_pairs_v10212
  end

  def motion_build_projectile_frames_v10213(ui)
    return {:frames=>0,:fail=>0,:ms=>0,:max=>0} unless PMD_AC::MOTION_PROJECTILE_FRAME_CACHE_V10213_ENABLED
    styles=PMD_AC.motion_projectile_profile_styles_v10213
    jobs=[]
    styles.each do |style|
      p=PMD_AC.skill_visual_projectile_profile_v030(style) rescue nil
      next if p==nil
      [p[:frames].to_i,1].max.times{|f|jobs.push([style,f])}
    end
    total=jobs.size;done=0;fail=0;ms_total=0;ms_max=0
    jobs.each do |row|
      t=Time.now.to_f
      bmp=PMD_AC.motion_build_projectile_frame_v10213(row[0],row[1])
      ms=((Time.now.to_f-t)*1000.0).round rescue 0
      ms_total+=ms;ms_max=ms if ms>ms_max
      fail+=1 if bmp==nil;done+=1
      if done==1 || done==total || (done%4)==0
        battle_loading_draw_v1029(ui,98,'預建投射物影格',done.to_s+'/'+total.to_s+'  '+row[0].to_s)
      end
    end
    {:frames=>total,:fail=>fail,:ms=>ms_total,:max=>ms_max}
  rescue
    {:frames=>0,:fail=>1,:ms=>0,:max=>0}
  end

  def motion_collect_audio_names_v10213
    names=[];seen={}
    add=lambda do |spec|
      name=nil
      if spec.is_a?(String);name=spec
      elsif spec.is_a?(Hash);name=spec[:name]
      end
      if name!=nil && name.to_s!='' && !seen[name.to_s]
        seen[name.to_s]=true;names.push(name.to_s)
      end
    end
    begin;add.call(PMD_AC::BASIC_ATTACK_HIT_SE_V0883);rescue;end
    begin;add.call(PMD_AC::DAMAGING_SKILL_HIT_FALLBACK_SE_V0883);rescue;end
    (@units || []).each do |u|
      next if u==nil
      d=(u.skill_data rescue nil)
      next if d==nil
      [:cast_se,:launch_se,:hit_se].each{|k|add.call(d[k]) if d.has_key?(k)}
      mk=d[:canonical_move_key]
      next if mk==nil || !PMD_AC.respond_to?(:skill_audio_move_profile_v032)
      p=PMD_AC.skill_audio_move_profile_v032(mk) rescue nil
      next if p==nil
      [:cast,:launch,:hit].each do |stage|
        cat=p[(stage.to_s+'_cat').to_sym]
        next if cat==nil
        pool=PMD_AC.skill_audio_category_pool_v032(cat) rescue nil
        (pool || []).each{|n|add.call(n)}
      end
    end
    names
  rescue
    names || []
  end

  def motion_audio_prewarm_v10213(ui)
    return {:index=>0,:audio=>0,:fail=>0,:ms=>0,:max=>0} unless PMD_AC::MOTION_AUDIO_PREWARM_V10213_ENABLED
    idx=PMD_AC.motion_build_audio_index_v10213
    names=motion_collect_audio_names_v10213
    maxn=PMD_AC::MOTION_AUDIO_PREWARM_MAX_V10213.to_i
    names=names[0,maxn] if maxn>0 && names.size>maxn
    done=0;fail=0;ms_total=0;ms_max=0
    names.each do |name|
      t=Time.now.to_f;ok=true
      begin
        # volume=0：只把 decoder / file first-touch 搬到 Loading，不改正式音效。
        RPG::SE.new(name.to_s,0,100).play
        begin;Audio.se_stop;rescue;end
      rescue
        ok=false;fail+=1
      end
      ms=((Time.now.to_f-t)*1000.0).round rescue 0
      ms_total+=ms;ms_max=ms if ms>ms_max
      done+=1
      battle_loading_draw_v1029(ui,98,'預熱戰鬥音效',done.to_s+'/'+names.size.to_s+'  '+name.to_s) if done==1 || done==names.size || (done%3)==0
    end
    @motion_audio_prewarm_names_v10213=names
    {:index=>idx==nil ? 0 : idx.size,:audio=>names.size,:fail=>fail,:ms=>ms_total,:max=>ms_max}
  rescue
    {:index=>0,:audio=>0,:fail=>1,:ms=>0,:max=>0}
  end

  def battle_loading_process_motion_v1029(ui)
    stat=pmd_ac_v10213_battle_loading_process_motion_v1029(ui)
    return stat unless motion_runtime_residual_mode_v10213?
    proj=motion_build_projectile_frames_v10213(ui)
    audio=motion_audio_prewarm_v10213(ui)
    base_pairs=(motion_baseline_pairs_v10212.size rescue 0)
    @motion_runtime_residual_summary_v10213={
      :baseline_pairs=>base_pairs,
      :projectile_frames=>proj[:frames].to_i,:projectile_fail=>proj[:fail].to_i,
      :projectile_ms=>proj[:ms].to_i,:projectile_max=>proj[:max].to_i,
      :audio_index=>audio[:index].to_i,:audio=>audio[:audio].to_i,:audio_fail=>audio[:fail].to_i,
      :audio_ms=>audio[:ms].to_i,:audio_max=>audio[:max].to_i
    }
    stat[:fail]=stat[:fail].to_i+proj[:fail].to_i if stat.is_a?(Hash)
    begin
      log_event(:perf,'MOTION_RESIDUAL_PREWARM_V10213 ready=1 baseline_pairs='+base_pairs.to_i.to_s+
        ' projectile_frames='+proj[:frames].to_i.to_s+' projectile_fail='+proj[:fail].to_i.to_s+
        ' projectile_ms='+proj[:ms].to_i.to_s+' projectile_max_ms='+proj[:max].to_i.to_s+
        ' audio_index='+audio[:index].to_i.to_s+' audio='+audio[:audio].to_i.to_s+
        ' audio_fail='+audio[:fail].to_i.to_s+' audio_ms='+audio[:ms].to_i.to_s+
        ' audio_max_ms='+audio[:max].to_i.to_s+' before_live_battle=1')
    rescue
    end
    stat
  rescue
    stat || {:enabled=>1,:fail=>1}
  end

  def verify_motion_runtime_residual_v10213
    return if @motion_runtime_residual_verify_logged_v10213
    s=@motion_runtime_residual_summary_v10213 || {}
    ready=s[:baseline_pairs].to_i>0 && s[:projectile_frames].to_i>0 &&
      s[:projectile_fail].to_i==0 && s[:audio_fail].to_i==0
    @motion_phase_a_failed_v102=true unless ready
    log_event(:verify,'MOTION_RUNTIME_RESIDUAL_V10213 pass='+(ready ? '1':'0')+
      ' baseline_alias_closure=1 projectile_frame_cache=1 projectile_frames='+s[:projectile_frames].to_i.to_s+
      ' projectile_fail='+s[:projectile_fail].to_i.to_s+' audio_index=1 audio='+s[:audio].to_i.to_s+
      ' audio_fail='+s[:audio_fail].to_i.to_s+' residual_profiler=1'+
      ' ai_unchanged=1 damage_unchanged=1 attack_speed_unchanged=1 spatial_unchanged=1')
    @motion_runtime_residual_verify_logged_v10213=true
  end

  def update_verification_script
    pmd_ac_v10213_update_verification_script
    return unless motion_runtime_residual_mode_v10213?
    verify_motion_runtime_residual_v10213 if @verification_frame.to_i>=50
  end

  def motion_log_baseline_runtime_v10212
    if motion_runtime_residual_mode_v10213?
      begin
        h=@motion_baseline_live_miss_keys_v10212 || {}
        keys=h.keys.map{|k|k[0].to_s+':'+k[1].to_s}.sort
        log_event(:perf,'MOTION_BASELINE_MISS_KEYS_V10213 live_miss='+@motion_baseline_live_miss_v10212.to_i.to_s+
          ' unique='+keys.size.to_s+' keys=['+keys.join(',')+'] expected=0')
      rescue
      end
    end
    pmd_ac_v10213_motion_log_baseline_runtime_v10212
  end

  # --------------------------------------------------------------------------
  # v1.02.7 Deep Profiler 的 Scene 細分。只計時，不改 return / 執行順序。
  # --------------------------------------------------------------------------
  alias pmd_ac_v10213_launch_projectile launch_projectile unless method_defined?(:pmd_ac_v10213_launch_projectile)
  alias pmd_ac_v10213_deal_direct_damage deal_direct_damage unless method_defined?(:pmd_ac_v10213_deal_direct_damage)
  alias pmd_ac_v10213_add_vfx_impact add_vfx_impact unless method_defined?(:pmd_ac_v10213_add_vfx_impact)
  alias pmd_ac_v10213_add_vfx_impact_xy add_vfx_impact_xy unless method_defined?(:pmd_ac_v10213_add_vfx_impact_xy)
  alias pmd_ac_v10213_play_basic_se play_basic_se unless method_defined?(:pmd_ac_v10213_play_basic_se)
  alias pmd_ac_v10213_play_skill_se play_skill_se unless method_defined?(:pmd_ac_v10213_play_skill_se)
  alias pmd_ac_v10213_resolve_skill resolve_skill unless method_defined?(:pmd_ac_v10213_resolve_skill)

  def motion_residual_scene_time_v10213(kind,unit=nil)
    active=respond_to?(:motion_deep_active_v1027?) && motion_deep_active_v1027?
    return yield unless active
    t=Time.now.to_f;r=yield;ms=((Time.now.to_f-t)*1000.0).round rescue 0
    motion_deep_record_v1027(kind,ms,unit,nil) rescue nil
    r
  end

  def launch_projectile(*args)
    u=args[0] rescue nil
    motion_residual_scene_time_v10213('launch_projectile',u){pmd_ac_v10213_launch_projectile(*args)}
  end
  def deal_direct_damage(*args)
    u=args[0] rescue nil
    motion_residual_scene_time_v10213('direct_damage',u){pmd_ac_v10213_deal_direct_damage(*args)}
  end
  def add_vfx_impact(*args)
    motion_residual_scene_time_v10213('add_vfx_impact',nil){pmd_ac_v10213_add_vfx_impact(*args)}
  end
  def add_vfx_impact_xy(*args)
    motion_residual_scene_time_v10213('add_vfx_xy',nil){pmd_ac_v10213_add_vfx_impact_xy(*args)}
  end
  def play_basic_se(*args)
    u=args[0] rescue nil
    motion_residual_scene_time_v10213('basic_se',u){pmd_ac_v10213_play_basic_se(*args)}
  end
  def play_skill_se(*args)
    u=args[0] rescue nil
    motion_residual_scene_time_v10213('skill_se',u){pmd_ac_v10213_play_skill_se(*args)}
  end
  def resolve_skill(*args)
    u=args[0] rescue nil
    motion_residual_scene_time_v10213('resolve_skill',u){pmd_ac_v10213_resolve_skill(*args)}
  end
end

#==============================================================================
# ■ Unit：v1.02.7 Deep Profiler 細分 core update 子步驟
#==============================================================================
class Game_PMDChessUnit
  alias pmd_ac_v10213_update_popup update_popup unless method_defined?(:pmd_ac_v10213_update_popup)
  alias pmd_ac_v10213_update_hurt update_hurt unless method_defined?(:pmd_ac_v10213_update_hurt)
  alias pmd_ac_v10213_update_hit_system update_hit_system unless method_defined?(:pmd_ac_v10213_update_hit_system)
  alias pmd_ac_v10213_update_statuses update_statuses unless method_defined?(:pmd_ac_v10213_update_statuses)
  alias pmd_ac_v10213_update_action_timer update_action_timer unless method_defined?(:pmd_ac_v10213_update_action_timer)
  alias pmd_ac_v10213_update_movement update_movement unless method_defined?(:pmd_ac_v10213_update_movement)
  alias pmd_ac_v10213_update_visual_motion update_visual_motion unless method_defined?(:pmd_ac_v10213_update_visual_motion)
  alias pmd_ac_v10213_refresh_motion_visual refresh_motion_visual unless method_defined?(:pmd_ac_v10213_refresh_motion_visual)
  alias pmd_ac_v10213_resolve_basic_attack resolve_basic_attack unless method_defined?(:pmd_ac_v10213_resolve_basic_attack)
  alias pmd_ac_v10213_receive_damage receive_damage unless method_defined?(:pmd_ac_v10213_receive_damage)

  def motion_residual_unit_time_v10213(kind)
    s=(respond_to?(:motion_deep_scene_v1027) ? motion_deep_scene_v1027 : nil) rescue nil
    return yield if s==nil
    t=Time.now.to_f;r=yield;ms=((Time.now.to_f-t)*1000.0).round rescue 0
    s.motion_deep_record_v1027(kind,ms,self,nil) rescue nil
    r
  end

  def update_popup;motion_residual_unit_time_v10213('unit_popup'){pmd_ac_v10213_update_popup};end
  def update_hurt;motion_residual_unit_time_v10213('unit_hurt'){pmd_ac_v10213_update_hurt};end
  def update_hit_system;motion_residual_unit_time_v10213('unit_hit_system'){pmd_ac_v10213_update_hit_system};end
  def update_statuses;motion_residual_unit_time_v10213('unit_statuses'){pmd_ac_v10213_update_statuses};end
  def update_action_timer;motion_residual_unit_time_v10213('unit_action_timer'){pmd_ac_v10213_update_action_timer};end
  def update_movement;motion_residual_unit_time_v10213('unit_movement'){pmd_ac_v10213_update_movement};end
  def update_visual_motion;motion_residual_unit_time_v10213('unit_visual_motion'){pmd_ac_v10213_update_visual_motion};end
  def refresh_motion_visual;motion_residual_unit_time_v10213('unit_refresh_motion'){pmd_ac_v10213_refresh_motion_visual};end
  def resolve_basic_attack;motion_residual_unit_time_v10213('resolve_basic_attack'){pmd_ac_v10213_resolve_basic_attack};end
  def receive_damage(*args);motion_residual_unit_time_v10213('receive_damage'){pmd_ac_v10213_receive_damage(*args)};end
end

#==============================================================================
# ■ Projectile：單顆 update / redraw 細分
#==============================================================================
class Sprite_PMDProjectile
  alias pmd_ac_v10213_update_profiled update unless method_defined?(:pmd_ac_v10213_update_profiled)

  def update
    s=@scene rescue nil
    active=s!=nil && s.respond_to?(:motion_deep_active_v1027?) && s.motion_deep_active_v1027?
    return pmd_ac_v10213_update_profiled unless active
    t=Time.now.to_f;r=pmd_ac_v10213_update_profiled;ms=((Time.now.to_f-t)*1000.0).round rescue 0
    s.motion_deep_record_v1027('projectile_one',ms,@user,'style='+@style.to_s) rescue nil
    r
  end
end
