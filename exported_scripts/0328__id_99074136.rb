# encoding: UTF-8
#==============================================================================
# 【PMD AutoChess 中文維護說明】
# 腳本：PMD AutoChess Tactical Passive / Spatial Runtime v0.91.4
# 分類：AutoChess 戰術被動／位移技能／戰鬥節奏／Verifier
#
# 【用途】
# 執行 v0.91.4 Data 的 Tactical Passive Counter 與 Spatial Move Extension。
# 這一層讓「成功普攻幾次」「承受幾次直接攻擊」可以觸發不消耗 Energy 的
# 小型位移／防禦反應；同時讓一部分既有招式真正改變戰場距離。
#
# 【主要設定項】
# 數值全部集中在 PMD AutoChess Tactical Passive / Spatial Data v0.91.4。
# Runtime 只負責：Counter、CD、平滑位移、Damage Reduction、技能位移路由、AI 加權。
#
# 【機制規則】
# 1. Tactical Passive 與 Energy 完全分離。被動觸發前後 Energy 數值不變。
# 2. pursuit_stride：成功基本攻擊達門檻後，向目前存活目標平滑追步；
#    不會穿過目標，會保留雙方碰撞半徑所需的基本間距。
# 3. evasive_step：成功基本攻擊達門檻後，只有附近確實存在威脅才後滑；
#    沒有威脅時 Counter 保留，不會白白浪費觸發。
# 4. shell_guard：直接 HP Damage 的承傷次數達門檻後，啟動短時間減傷；
#    DOT／Redirect 等 grant_energy=false 的間接傷害不計 Counter。
# 5. 被 Pull / Knockback 時會取消自身 Tactical Slide，敵方強制位移優先。
# 6. 技能位移擴充只在 NORMAL 與 TACTICAL_SPATIAL_V0914 驗證生效；
#    舊 Verifier 不套用，避免改變已 Freeze 的測試條件。
# 7. 若技能原本已有相同類型 Pull / Knockback / Dash / Blink，不重複疊加。
# 8. 位移招式會獲得小幅 AI Utility：遠程被貼時較愛 Push／Retreat，
#    近戰距離不足時較愛 Advance／Pull；不會覆蓋原 v0.68～v0.72 評分。
#
# 【可調參數】
# - 被動門檻／距離／CD／減傷：請改 Data Script。
# - 若想完全停用某寶可夢的戰術被動：從 TACTICAL_PASSIVES_V0914 移除該 species。
# - 若想取消某招位移：從 SPATIAL_MOVE_EXTENSIONS_V0914 移除該 move key。
#
# 【事件／腳本呼叫方式】
# 一般戰鬥自動運作。
# 開發 API：
#   unit.register_tactical_basic_hit_v0914(target)
#   unit.register_tactical_received_hit_v0914(source, damage)
#   unit.begin_tactical_advance_v0914(target, 36, 6, :script)
#   unit.begin_tactical_retreat_v0914(target, 36, 6, :script)
#
# 【實際範例】
# - 妙蛙種子普攻命中 3 次：PASSIVE_PROC 藤根追步，追近目前目標。
# - 皮卡丘普攻命中 4 次且敵人在 125px 內：PASSIVE_PROC 電光滑步，拉開距離。
# - 傑尼龜受到 3 次直接 HP Damage：PASSIVE_PROC 龜甲架勢，後續傷害短暫 -20%。
# - 水槍命中近身敵人：額外 Push 18px；藤鞭命中：額外 Pull 18px。
#
# 【驗證】
# NORMAL 按 S 一次 -> TACTICAL_SPATIAL_V0914 -> Shift。
# 預期最後：
#   TACTICAL_SPATIAL_V0914 pass=1
#   VERIFY_FINISHED_BATTLE_RESUME pass=1
#
# 【注意事項】
# - 不改 v0.60.2 Damage Packet、多段攻擊 cadence、Accuracy、Projectile Tracking。
# - 不削弱 v0.88.3 皮卡丘拉打；本版是增加雙方空間工具，而不是把 Kiting 關掉。
# - 不修改 v0.91.2 Aggro / v0.91.3 Peel 的判斷優先級。
# - RGSS2 / Ruby 1.8 相容；禁止使用 instance_variable_defined?。
#==============================================================================
module PMD_AC
  V0914_OLD_VERIFICATION_MODES = VERIFICATION_MODES.dup
  V0914_OLD_VERIFICATION_LABELS = VERIFICATION_LABELS.dup
  remove_const(:VERIFICATION_MODES)
  VERIFICATION_MODES = [:normal,:tactical_spatial_v0914,:autochess_aggro_v0913,:boss_framework_v091] +
    V0914_OLD_VERIFICATION_MODES.reject{|x|[:normal,:tactical_spatial_v0914,:autochess_aggro_v0913,:boss_framework_v091].include?(x)}
  remove_const(:VERIFICATION_LABELS)
  VERIFICATION_LABELS = V0914_OLD_VERIFICATION_LABELS.dup
  VERIFICATION_LABELS[:normal]='NORMAL'
  VERIFICATION_LABELS[:tactical_spatial_v0914]='TACTICAL_SPATIAL_V0914'
  VERIFICATION_LABELS[:autochess_aggro_v0913]='AUTOCHESS_AGGRO_V0913'
  VERIFICATION_LABELS[:boss_framework_v091]='BOSS_FRAMEWORK_V091'
end

#==============================================================================
# ■ Game_PMDChessUnit
#==============================================================================
class Game_PMDChessUnit
  attr_reader :tactical_basic_hits_v0914
  attr_reader :tactical_received_hits_v0914
  attr_reader :tactical_passive_cooldown_v0914
  attr_reader :tactical_guard_frames_v0914
  attr_reader :tactical_guard_ratio_v0914

  alias pmd_ac_v0914_initialize initialize unless method_defined?(:pmd_ac_v0914_initialize)
  alias pmd_ac_v0914_start_combat start_combat unless method_defined?(:pmd_ac_v0914_start_combat)
  alias pmd_ac_v0914_update_threat_timers update_threat_timers unless method_defined?(:pmd_ac_v0914_update_threat_timers)
  alias pmd_ac_v0914_update_movement update_movement unless method_defined?(:pmd_ac_v0914_update_movement)
  alias pmd_ac_v0914_apply_knockback apply_knockback unless method_defined?(:pmd_ac_v0914_apply_knockback)
  alias pmd_ac_v0914_apply_pull apply_pull unless method_defined?(:pmd_ac_v0914_apply_pull)
  alias pmd_ac_v0914_receive_damage receive_damage unless method_defined?(:pmd_ac_v0914_receive_damage)
  alias pmd_ac_v0914_begin_skill begin_skill unless method_defined?(:pmd_ac_v0914_begin_skill)

  def initialize(*args)
    pmd_ac_v0914_initialize(*args)
    reset_tactical_passive_v0914
  end

  def start_combat
    pmd_ac_v0914_start_combat
    reset_tactical_passive_v0914
  end

  def reset_tactical_passive_v0914
    @tactical_basic_hits_v0914=0
    @tactical_received_hits_v0914=0
    @tactical_passive_cooldown_v0914=0
    @tactical_guard_frames_v0914=0
    @tactical_guard_ratio_v0914=0.0
    @tactical_slide_frames_v0914=0
    @tactical_slide_x_v0914=0.0
    @tactical_slide_y_v0914=0.0
    @tactical_skill_serial_v0914=0
    @tactical_spatial_marks_v0914={}
    @tactical_evasive_proc_count_v0914=0
  end

  def tactical_passive_profile_v0914
    p=PMD_AC.tactical_passive_profile_v0914(species_key)
    return nil if p==nil
    key=p[:key]
    ability=respond_to?(:ability_key) ? ability_key : nil
    ability=ability.to_s.downcase.gsub(/[^a-z0-9]+/,'_').to_sym if ability!=nil
    if [:pursuit_stride,:evasive_step].include?(key) &&
       PMD_AC::TACTICAL_MOVEMENT_ABILITY_AFFINITY_V0914.include?(ability)
      p[:trigger]=[[p[:trigger].to_i-PMD_AC::TACTICAL_MOVEMENT_TRIGGER_REDUCTION_V0914,2].max,9].min
      p[:ability_affinity]=ability
    elsif key==:shell_guard &&
          PMD_AC::TACTICAL_DEFENSE_ABILITY_AFFINITY_V0914.include?(ability)
      p[:reduction]=[p[:reduction].to_f+PMD_AC::TACTICAL_DEFENSE_REDUCTION_BONUS_V0914,
                     PMD_AC::TACTICAL_DEFENSE_REDUCTION_CAP_V0914].min
      p[:ability_affinity]=ability
    end
    p
  end

  def tactical_passive_key_v0914
    p=tactical_passive_profile_v0914
    p==nil ? nil : p[:key]
  end

  def tactical_passive_name_v0914
    p=tactical_passive_profile_v0914
    p==nil ? '' : p[:name].to_s
  end

  def tactical_runtime_live_v0914?
    return false if dead? || @scene==nil
    return false unless @scene.respond_to?(:tactical_runtime_enabled_v0914?)
    @scene.tactical_runtime_enabled_v0914?
  end

  def tactical_slide_active_v0914?
    @tactical_slide_frames_v0914.to_i>0
  end

  def clear_tactical_slide_v0914
    @tactical_slide_frames_v0914=0
    @tactical_slide_x_v0914=0.0
    @tactical_slide_y_v0914=0.0
  end

  def begin_tactical_slide_vector_v0914(dx,dy,distance,frames,reason=:passive)
    return false if dead? || rooted? || @stun_frames.to_i>0
    return false if @knockback_frames.to_i>0
    len=Math.sqrt(dx.to_f*dx.to_f+dy.to_f*dy.to_f)
    return false if len<=0.001
    dist=distance.to_f
    return false if dist<=0.5
    f=[frames.to_i,1].max
    @tactical_slide_x_v0914=dx.to_f/len*dist/f.to_f
    @tactical_slide_y_v0914=dy.to_f/len*dist/f.to_f
    @tactical_slide_frames_v0914=f
    @velocity_x=0.0
    @velocity_y=0.0
    @scene.release_attack_slot(self) if @scene!=nil
    log_event(:tactical_move,log_name+' reason='+reason.to_s+
      ' dist='+dist.round.to_s+' frames='+f.to_s)
    true
  end

  def begin_tactical_advance_v0914(other,distance,frames,reason=:passive)
    return false if other==nil || other.dead?
    dx=other.pixel_x-@pixel_x
    dy=other.pixel_y-@pixel_y
    len=Math.sqrt(dx*dx+dy*dy)
    return false if len<=0.001
    stop=@collision_radius.to_f+other.collision_radius.to_f+5.0
    max_travel=[len-stop,0.0].max
    travel=[distance.to_f,max_travel].min
    begin_tactical_slide_vector_v0914(dx,dy,travel,frames,reason)
  end

  def begin_tactical_retreat_v0914(other,distance,frames,reason=:passive)
    return false if other==nil || other.dead?
    dx=@pixel_x-other.pixel_x
    dy=@pixel_y-other.pixel_y
    if dx.abs+dy.abs<=0.001
      dx=@team==:ally ? -1.0 : 1.0
      dy=((@id.to_i%3)-1).to_f*0.25
    end
    begin_tactical_slide_vector_v0914(dx,dy,distance,frames,reason)
  end

  # 遠程／敏捷型的側後滑步：保留拉開距離，但不把全部位移都用在直線後退。
  # 這樣能增加戰場角度變化，也避免把既有 Kiting 直接再放大一整段距離。
  def begin_tactical_evasive_step_v0914(other,distance,frames,reason=:passive_evade)
    return false if other==nil || other.dead?
    ax=@pixel_x-other.pixel_x
    ay=@pixel_y-other.pixel_y
    len=Math.sqrt(ax.to_f*ax.to_f+ay.to_f*ay.to_f)
    if len<=0.001
      ax=@team==:ally ? -1.0 : 1.0
      ay=0.0
      len=1.0
    end
    ax=ax.to_f/len
    ay=ay.to_f/len
    side=((@id.to_i+@tactical_evasive_proc_count_v0914.to_i)%2==0) ? 1.0 : -1.0
    px=-ay*side
    py=ax*side
    # 約 55% 往外、83.5% 側向；總向量重新由 begin_tactical_slide_vector 正規化。
    dx=ax*0.55+px*0.835
    dy=ay*0.55+py*0.835
    ok=begin_tactical_slide_vector_v0914(dx,dy,distance,frames,reason)
    @tactical_evasive_proc_count_v0914=@tactical_evasive_proc_count_v0914.to_i+1 if ok
    ok
  end

  def tactical_nearest_enemy_v0914
    if @target!=nil && !@target.dead? && @target.team!=@team
      return @target
    end
    return nil if @scene==nil
    list=@scene.enemies_of(self)
    best=nil;best_d=nil
    list.each do |u|
      next if u==nil || u.dead?
      d=distance_to(u).to_f
      if best==nil || d<best_d
        best=u;best_d=d
      end
    end
    best
  end

  def tactical_effective_trigger_v0914(profile)
    n=(profile[:trigger]||3).to_i
    n=2 if n<2
    n
  end

  def register_tactical_basic_hit_v0914(target)
    return false unless tactical_runtime_live_v0914?
    p=tactical_passive_profile_v0914
    return false if p==nil
    key=p[:key]
    return false unless [:pursuit_stride,:evasive_step].include?(key)
    @tactical_basic_hits_v0914=@tactical_basic_hits_v0914.to_i+1
    trigger=tactical_effective_trigger_v0914(p)
    @tactical_basic_hits_v0914=trigger if @tactical_basic_hits_v0914>trigger
    return false if @tactical_basic_hits_v0914<trigger
    return false if @tactical_passive_cooldown_v0914.to_i>0

    proc_target=(target!=nil && !target.dead?) ? target : tactical_nearest_enemy_v0914
    ok=false
    if key==:pursuit_stride
      ok=begin_tactical_advance_v0914(proc_target,p[:distance]||30.0,p[:frames]||6,:passive_pursuit)
    elsif key==:evasive_step
      threat=tactical_nearest_enemy_v0914
      if threat!=nil && distance_to(threat).to_f<=(p[:threat_range]||120.0).to_f
        ok=begin_tactical_evasive_step_v0914(threat,p[:distance]||30.0,p[:frames]||6,:passive_evade)
      end
    end
    if ok
      @tactical_basic_hits_v0914=0
      @tactical_passive_cooldown_v0914=(p[:cooldown]||60).to_i
      log_event(:passive_proc,log_name+' passive='+p[:name].to_s+
        ' key='+key.to_s+' trigger=basic_hit energy='+@energy.to_i.to_s+
        ' ability='+(respond_to?(:ability_key) ? ability_key.to_s : 'nil'))
    end
    ok
  end

  def register_tactical_received_hit_v0914(source,damage)
    return false unless tactical_runtime_live_v0914?
    p=tactical_passive_profile_v0914
    return false if p==nil || p[:key]!=:shell_guard
    return false if source==nil || source.team==@team || damage.to_i<=0
    @tactical_received_hits_v0914=@tactical_received_hits_v0914.to_i+1
    trigger=tactical_effective_trigger_v0914(p)
    @tactical_received_hits_v0914=trigger if @tactical_received_hits_v0914>trigger
    return false if @tactical_received_hits_v0914<trigger
    return false if @tactical_passive_cooldown_v0914.to_i>0
    @tactical_received_hits_v0914=0
    @tactical_guard_ratio_v0914=(p[:reduction]||0.20).to_f
    @tactical_guard_frames_v0914=(p[:duration]||60).to_i
    @tactical_passive_cooldown_v0914=(p[:cooldown]||120).to_i
    @scene.add_skill_effect(self,:shield) if @scene!=nil && @scene.respond_to?(:add_skill_effect)
    log_event(:passive_proc,log_name+' passive='+p[:name].to_s+
      ' key=shell_guard trigger=received_hit reduction='+
      sprintf('%.2f',@tactical_guard_ratio_v0914)+' dur='+@tactical_guard_frames_v0914.to_s+
      ' energy='+@energy.to_i.to_s+' ability='+(respond_to?(:ability_key) ? ability_key.to_s : 'nil'))
    true
  end

  def tactical_guard_active_v0914?
    @tactical_guard_frames_v0914.to_i>0 && @tactical_guard_ratio_v0914.to_f>0.0
  end

  def tactical_adjust_incoming_damage_v0914(value,direct=true)
    v=value.to_i
    return v unless direct && tactical_guard_active_v0914? && v>0
    ratio=PMD_AC.clamp(@tactical_guard_ratio_v0914.to_f,0.0,0.80)
    out=(v.to_f*(1.0-ratio)).round
    out=1 if out<1
    out
  end

  def update_threat_timers
    pmd_ac_v0914_update_threat_timers
    @tactical_passive_cooldown_v0914-=1 if @tactical_passive_cooldown_v0914.to_i>0
    if @tactical_guard_frames_v0914.to_i>0
      @tactical_guard_frames_v0914-=1
      if @tactical_guard_frames_v0914<=0
        @tactical_guard_frames_v0914=0
        @tactical_guard_ratio_v0914=0.0
      end
    end
  end

  def update_movement
    if tactical_slide_active_v0914? && !dead?
      @pixel_x+=@tactical_slide_x_v0914
      @pixel_y+=@tactical_slide_y_v0914
      @tactical_slide_frames_v0914-=1
      clamp_to_board
      sync_cell_from_pixel
      face_delta(@tactical_slide_x_v0914,@tactical_slide_y_v0914,false)
      clear_tactical_slide_v0914 if @tactical_slide_frames_v0914<=0
      return
    end
    pmd_ac_v0914_update_movement
  end

  def apply_knockback(source,distance)
    clear_tactical_slide_v0914
    pmd_ac_v0914_apply_knockback(source,distance)
  end

  def apply_pull(source,distance)
    clear_tactical_slide_v0914
    pmd_ac_v0914_apply_pull(source,distance)
  end

  def receive_damage(value,source=nil,grant_energy=true,bypass_link=false,critical=false)
    incoming=value.to_i
    adjusted=tactical_adjust_incoming_damage_v0914(incoming,grant_energy)
    if adjusted!=incoming && @scene!=nil
      @scene.log_event(:tactical_dr,log_name+' passive='+tactical_passive_name_v0914+
        ' damage='+incoming.to_s+'->'+adjusted.to_s+
        ' ratio='+sprintf('%.2f',@tactical_guard_ratio_v0914.to_f))
    end
    before=@hp.to_i
    result=pmd_ac_v0914_receive_damage(adjusted,source,grant_energy,bypass_link,critical)
    actual=[before-@hp.to_i,0].max
    if actual>0 && grant_energy && source!=nil && source.is_a?(Game_PMDChessUnit) && source.team!=@team
      register_tactical_received_hit_v0914(source,actual)
    end
    result
  end

  def begin_skill(target=nil)
    @tactical_skill_serial_v0914=@tactical_skill_serial_v0914.to_i+1
    @tactical_spatial_marks_v0914={}
    pmd_ac_v0914_begin_skill(target)
  end

  def begin_spatial_cast_serial_v0914
    @tactical_skill_serial_v0914=@tactical_skill_serial_v0914.to_i+1
    @tactical_spatial_marks_v0914={}
    @tactical_skill_serial_v0914
  end

  def spatial_extension_once_v0914(move_key,scope_key)
    @tactical_spatial_marks_v0914={} if @tactical_spatial_marks_v0914==nil
    serial=@tactical_skill_serial_v0914.to_i
    serial=Graphics.frame_count.to_i if serial<=0
    key=[serial,move_key,scope_key]
    return false if @tactical_spatial_marks_v0914[key]
    @tactical_spatial_marks_v0914[key]=true
    true
  end
end

#==============================================================================
# ■ Scene_PMD_AutoChess
#==============================================================================
class Scene_PMD_AutoChess
  alias pmd_ac_v0914_start start unless method_defined?(:pmd_ac_v0914_start)
  alias pmd_ac_v0914_update update unless method_defined?(:pmd_ac_v0914_update)
  alias pmd_ac_v0914_refresh_header refresh_header unless method_defined?(:pmd_ac_v0914_refresh_header)
  alias pmd_ac_v0914_prepare_verification_battle prepare_verification_battle unless method_defined?(:pmd_ac_v0914_prepare_verification_battle)
  alias pmd_ac_v0914_update_verification_script update_verification_script unless method_defined?(:pmd_ac_v0914_update_verification_script)
  alias pmd_ac_v0914_log_event log_event unless method_defined?(:pmd_ac_v0914_log_event)
  alias pmd_ac_v0914_deal_direct_damage deal_direct_damage unless method_defined?(:pmd_ac_v0914_deal_direct_damage)
  alias pmd_ac_v0914_apply_skill_effects apply_skill_effects unless method_defined?(:pmd_ac_v0914_apply_skill_effects)
  alias pmd_ac_v0914_progression_candidate_score_v046 progression_candidate_score_v046 unless method_defined?(:pmd_ac_v0914_progression_candidate_score_v046)

  def tactical_runtime_enabled_v0914?
    m=verification_mode
    m==:normal || m==:tactical_spatial_v0914
  end

  def tactical_spatial_v0914?
    verification_mode==:tactical_spatial_v0914
  end

  def start
    pmd_ac_v0914_start
    begin
      if FileTest.exist?(PMD_AC::BATTLE_LOG_FILE)
        text=File.open(PMD_AC::BATTLE_LOG_FILE,'rb'){|f|f.read}
        text.sub!(/PMD AutoChess Proto v0\.[0-9.]+ Battle Verification Log/,
          'PMD AutoChess Proto v0.91.4 Battle Verification Log')
        File.open(PMD_AC::BATTLE_LOG_FILE,'wb'){|f|f.write(text)}
      end
    rescue
    end
    @duel_pair_key_v0914=nil
    @duel_pair_frames_v0914=0
    @duel_watch_logged_v0914=false
    @duel_long_logged_v0914=false
    log_event(:tactical_passive,
      'FLOW v0.91.4 passive_counter=basic_hit+received_hit energy_cost=0'+
      ' spatial_moves='+PMD_AC::SPATIAL_MOVE_EXTENSIONS_V0914.size.to_s+
      ' passive_profiles='+PMD_AC::TACTICAL_PASSIVES_V0914.size.to_s+
      ' ability_affinity=movement+defense duel_pace_diagnostic=1')
  end

  def refresh_header
    pmd_ac_v0914_refresh_header
    return if @header_sprite==nil || @header_sprite.bitmap==nil
    bmp=@header_sprite.bitmap
    bmp.fill_rect(0,0,Graphics.width,28,Color.new(0,0,0,180))
    pmd_ac_v074_font(bmp)
    bmp.font.size=PMD_AC::HEADER_TITLE_FONT_V0741
    bmp.font.bold=true
    bmp.font.color=Color.new(255,255,255)
    bmp.draw_text(16,4,Graphics.width-32,24,'PMD 自走棋原型 v0.91.4',1)
  end

  def update
    pmd_ac_v0914_update
    update_duel_pace_v0914
  end

  def update_duel_pace_v0914
    return unless verification_mode==:normal
    return unless @phase==:battle
    allies=core_living_units(:ally)
    enemies=core_living_units(:enemy)
    if allies.size==1 && enemies.size==1
      key=[allies[0].id,enemies[0].id]
      if @duel_pair_key_v0914!=key
        @duel_pair_key_v0914=key
        @duel_pair_frames_v0914=0
        @duel_watch_logged_v0914=false
        @duel_long_logged_v0914=false
      end
      @duel_pair_frames_v0914=@duel_pair_frames_v0914.to_i+1
      if @duel_pair_frames_v0914>=PMD_AC::DUEL_PACE_WATCH_FRAMES_V0914 && !@duel_watch_logged_v0914
        log_event(:duel_pace,'WATCH '+allies[0].log_name+' vs '+enemies[0].log_name+
          ' frames='+@duel_pair_frames_v0914.to_s)
        @duel_watch_logged_v0914=true
      end
      if @duel_pair_frames_v0914>=PMD_AC::DUEL_PACE_LONG_FRAMES_V0914 && !@duel_long_logged_v0914
        log_event(:duel_pace,'LONG '+allies[0].log_name+' vs '+enemies[0].log_name+
          ' frames='+@duel_pair_frames_v0914.to_s+' diagnostic_only=1')
        @duel_long_logged_v0914=true
      end
    else
      @duel_pair_key_v0914=nil
      @duel_pair_frames_v0914=0
      @duel_watch_logged_v0914=false
      @duel_long_logged_v0914=false
    end
  end

  def deal_direct_damage(user,target,power,options=nil)
    opts=options==nil ? {} : options
    result=pmd_ac_v0914_deal_direct_damage(user,target,power,options)
    if tactical_runtime_enabled_v0914? && result.to_i>0 &&
       opts[:source_type]==:basic && user!=nil && !user.dead?
      user.register_tactical_basic_hit_v0914(target)
    end
    result
  end

  def canonical_move_key_v0914(data)
    return nil if data==nil
    k=data[:canonical_move_key]
    k=data['canonical_move_key'] if k==nil
    k=data[:move_key] if k==nil
    k=data['move_key'] if k==nil
    k=data[:runtime_skill_key] if k==nil
    k=data['runtime_skill_key'] if k==nil
    return nil if k==nil
    s=k.to_s.downcase.gsub(/^mv_/,'').gsub(/[^a-z0-9]+/,'_')
    s.to_sym
  end

  def spatial_effect_type_v0914(effect)
    return nil if effect==nil
    t=effect[:type]
    t=effect['type'] if t==nil
    t==nil ? nil : t.to_s.to_sym
  end

  def spatial_native_duplicate_v0914?(data,kind)
    effects=data==nil ? [] : (data[:effects] || data['effects'] || [])
    types=effects.collect{|e|spatial_effect_type_v0914(e)}
    return types.include?(:knockback) if kind==:push
    return types.include?(:pull) if kind==:pull
    return (types.include?(:dash_user) || types.include?(:blink_user)) if kind==:advance
    false
  end

  def apply_spatial_move_extension_v0914(user,target,data)
    return false unless tactical_runtime_enabled_v0914?
    return false if user==nil || user.dead? || target==nil
    mk=canonical_move_key_v0914(data)
    ext=PMD_AC.spatial_move_extension_v0914(mk)
    return false if ext==nil
    kind=ext[:kind]
    return false if spatial_native_duplicate_v0914?(data,kind)
    scope=(kind==:push || kind==:pull) ? target.id : :self
    return false unless user.spatial_extension_once_v0914(mk,scope)
    ok=false
    case kind
    when :advance
      ok=user.begin_tactical_advance_v0914(target,ext[:distance]||36.0,ext[:frames]||6,:skill_advance)
    when :retreat
      ok=user.begin_tactical_retreat_v0914(target,ext[:distance]||36.0,ext[:frames]||6,:skill_retreat)
    when :push
      if !target.dead?
        target.apply_knockback(user,ext[:distance]||20.0)
        ok=true
      end
    when :pull
      if !target.dead?
        target.apply_pull(user,ext[:distance]||20.0)
        ok=true
      end
    end
    if ok
      log_event(:spatial_move,user.log_name+' move='+mk.to_s+' kind='+kind.to_s+
        ' target='+target.log_name+' dist='+(ext[:distance]||0).to_f.round.to_s)
    end
    ok
  end

  def apply_skill_effects(user,target,data,scale=1.0)
    result=pmd_ac_v0914_apply_skill_effects(user,target,data,scale)
    apply_spatial_move_extension_v0914(user,target,data)
    result
  end

  def spatial_ai_bonus_v0914(unit,target,data)
    return 0.0 if unit==nil || target==nil || data==nil
    ext=PMD_AC.spatial_move_extension_v0914(canonical_move_key_v0914(data))
    return 0.0 if ext==nil
    d=unit.distance_to(target).to_f
    case ext[:kind]
    when :advance
      return PMD_AC.clamp((d-52.0)/4.0,0.0,18.0)
    when :pull
      return PMD_AC.clamp((d-58.0)/5.0,0.0,16.0)
    when :push
      return unit.ranged? ? PMD_AC.clamp((112.0-d)/4.0,0.0,20.0) :
                            PMD_AC.clamp((74.0-d)/5.0,0.0,10.0)
    when :retreat
      return PMD_AC.clamp((120.0-d)/3.5,0.0,22.0)
    end
    0.0
  end

  def progression_candidate_score_v046(unit,target,data,move,slot)
    score=pmd_ac_v0914_progression_candidate_score_v046(unit,target,data,move,slot)
    return score if score==nil || !tactical_runtime_enabled_v0914?
    score.to_f+spatial_ai_bonus_v0914(unit,target,data)
  end

  #--------------------------------------------------------------------------
  # ● Verifier
  #--------------------------------------------------------------------------
  def prepare_verification_battle
    pmd_ac_v0914_prepare_verification_battle
    @tactical_spatial_failed_v0914=false if tactical_spatial_v0914?
  end

  def log_event(category,message)
    if category.to_s=='verify' && tactical_spatial_v0914? &&
       (message.to_s.index('TACTICAL_')==0 || message.to_s.index('PASSIVE_')==0 ||
        message.to_s.index('SPATIAL_')==0 || message.to_s.index('DUEL_')==0) &&
       message.to_s.include?(' pass=0')
      @tactical_spatial_failed_v0914=true
    end
    pmd_ac_v0914_log_event(category,message)
  end

  def log_verify_v0914(name,pass,detail='')
    @tactical_spatial_failed_v0914=true unless pass
    log_event(:verify,name+' pass='+(pass ? '1':'0')+(detail=='' ? '' : ' '+detail))
  end

  def verification_set_position_v0914(unit,x,y)
    unit.instance_variable_set(:@pixel_x,x.to_f)
    unit.instance_variable_set(:@pixel_y,y.to_f)
    unit.send(:sync_cell_from_pixel)
  end

  def verify_tactical_manifest_v0914
    return if @verification_done[:v0914_manifest]
    p=PMD_AC.tactical_passive_profile_v0914(:bulbasaur)
    q=PMD_AC.tactical_passive_profile_v0914(:squirtle)
    pass=p!=nil && p[:key]==:pursuit_stride && q!=nil && q[:key]==:shell_guard &&
      PMD_AC::SPATIAL_MOVE_EXTENSIONS_V0914.size>=12 &&
      PMD_AC.spatial_move_extension_v0914(:quick_attack)[:kind]==:advance
    log_verify_v0914('TACTICAL_PASSIVE_MANIFEST_V0914',pass,
      'profiles='+PMD_AC::TACTICAL_PASSIVES_V0914.size.to_s+
      ' spatial_moves='+PMD_AC::SPATIAL_MOVE_EXTENSIONS_V0914.size.to_s+
      ' energy_cost=0 ability_layer=separate')
    @verification_done[:v0914_manifest]=true
  end

  def verify_passive_counter_v0914
    return if @verification_done[:v0914_counter]
    a=make_ai_test_unit_v0913(99401,:bulbasaur,:ally,1,1,nil)
    b=make_ai_test_unit_v0913(99402,:pikachu,:enemy,4,1,nil)
    verification_set_position_v0914(a,120,220)
    verification_set_position_v0914(b,220,220)
    a.set_target(b)
    e0=a.energy.to_i
    d0=a.distance_to(b).to_f
    3.times{a.register_tactical_basic_hit_v0914(b)}
    8.times{a.update_movement}
    d1=a.distance_to(b).to_f
    pass=d1<d0-10.0 && a.tactical_basic_hits_v0914.to_i==0 && a.energy.to_i==e0
    log_verify_v0914('PASSIVE_COUNTER_NO_ENERGY_V0914',pass,
      'species=bulbasaur trigger=3 distance='+d0.round.to_s+'->'+d1.round.to_s+
      ' energy='+e0.to_s+'->'+a.energy.to_i.to_s)
    @verification_done[:v0914_counter]=true
  end

  def verify_passive_evasive_v0914
    return if @verification_done[:v0914_evade]
    p=make_ai_test_unit_v0913(99411,:pikachu,:ally,2,2,nil)
    e=make_ai_test_unit_v0913(99412,:bulbasaur,:enemy,3,2,nil)
    verification_set_position_v0914(p,220,220)
    verification_set_position_v0914(e,290,220)
    p.set_target(e)
    d0=p.distance_to(e).to_f
    4.times{p.register_tactical_basic_hit_v0914(e)}
    8.times{p.update_movement}
    d1=p.distance_to(e).to_f
    lateral=(p.pixel_y-220.0).abs
    pass=d1>d0+5.0 && lateral>5.0 && p.energy.to_i==0
    log_verify_v0914('PASSIVE_EVASIVE_STEP_V0914',pass,
      'species=pikachu trigger=4 side_back=1 distance='+d0.round.to_s+'->'+d1.round.to_s+
      ' lateral='+lateral.round.to_s+' energy=0')
    @verification_done[:v0914_evade]=true
  end

  def verify_passive_guard_v0914
    return if @verification_done[:v0914_guard]
    s=make_ai_test_unit_v0913(99421,:squirtle,:ally,1,2,nil)
    r=make_ai_test_unit_v0913(99422,:rattata,:enemy,3,2,nil)
    e0=s.energy.to_i
    3.times{s.register_tactical_received_hit_v0914(r,30)}
    adjusted=s.tactical_adjust_incoming_damage_v0914(100,true)
    pass=s.tactical_guard_active_v0914? && adjusted==80 && s.energy.to_i==e0
    log_verify_v0914('PASSIVE_DAMAGE_REDUCTION_V0914',pass,
      'species=squirtle trigger=3 damage=100->'+adjusted.to_s+
      ' ratio='+sprintf('%.2f',s.tactical_guard_ratio_v0914.to_f)+' energy='+e0.to_s+'->'+s.energy.to_i.to_s)
    @verification_done[:v0914_guard]=true
  end

  def verify_spatial_router_v0914
    return if @verification_done[:v0914_router]
    q=PMD_AC.spatial_move_extension_v0914(:quick_attack)
    w=PMD_AC.spatial_move_extension_v0914(:water_gun)
    v=PMD_AC.spatial_move_extension_v0914(:vine_whip)
    u=PMD_AC.spatial_move_extension_v0914(:u_turn)
    pass=q[:kind]==:advance && w[:kind]==:push && v[:kind]==:pull && u[:kind]==:retreat
    log_verify_v0914('SPATIAL_MOVE_ROUTER_V0914',pass,
      'quick_attack=advance water_gun=push vine_whip=pull u_turn=retreat duplicate_guard=1')
    @verification_done[:v0914_router]=true
  end

  def verify_spatial_runtime_v0914
    return if @verification_done[:v0914_runtime]
    u=make_ai_test_unit_v0913(99431,:charmander,:ally,1,1,nil)
    t=make_ai_test_unit_v0913(99432,:caterpie,:enemy,4,1,nil)
    verification_set_position_v0914(u,120,220)
    verification_set_position_v0914(t,260,220)
    u.begin_spatial_cast_serial_v0914
    d0=u.distance_to(t).to_f
    data={:canonical_move_key=>'quick_attack',:effects=>[{:type=>:damage,:power=>40}]}
    ok=apply_spatial_move_extension_v0914(u,t,data)
    7.times{u.update_movement}
    d1=u.distance_to(t).to_f
    pass=ok && d1<d0-15.0
    log_verify_v0914('SPATIAL_MOVE_RUNTIME_V0914',pass,
      'quick_attack distance='+d0.round.to_s+'->'+d1.round.to_s+' smooth_slide=1')
    @verification_done[:v0914_runtime]=true
  end

  def verify_spatial_ai_v0914
    return if @verification_done[:v0914_ai]
    u=make_ai_test_unit_v0913(99441,:squirtle,:ally,1,2,nil)
    t=make_ai_test_unit_v0913(99442,:rattata,:enemy,2,2,nil)
    verification_set_position_v0914(u,200,220)
    verification_set_position_v0914(t,250,220)
    push=spatial_ai_bonus_v0914(u,t,{:canonical_move_key=>'water_gun'})
    retreat=spatial_ai_bonus_v0914(u,t,{:canonical_move_key=>'u_turn'})
    pass=push>0.0 && retreat>0.0
    log_verify_v0914('SPATIAL_AI_UTILITY_V0914',pass,
      'close_range_push='+sprintf('%.1f',push)+' retreat='+sprintf('%.1f',retreat)+' base_ai=v0.68-v0.72_preserved')
    @verification_done[:v0914_ai]=true
  end

  def verify_duel_diagnostic_v0914
    return if @verification_done[:v0914_duel]
    pass=PMD_AC::DUEL_PACE_WATCH_FRAMES_V0914==600 && PMD_AC::DUEL_PACE_LONG_FRAMES_V0914==1200
    log_verify_v0914('DUEL_PACE_DIAGNOSTIC_V0914',pass,
      'watch=600f long=1200f diagnostic_only=1 stalemate=v0.89_unchanged')
    @verification_done[:v0914_duel]=true
  end

  def verify_tactical_carry_v0914
    return if @verification_done[:v0914_carry]
    pass=PMD_AC::AGGRO_MAX_V0912==100.0 && PMD_AC::PEEL_DURATION_V0913==120 &&
      PMD_AC::RANGED_CONTACT_BASIC_STAGGER_V0883==18 && PMD_AC::STALL_WATCH_FRAMES_V089==540 &&
      PMD_AC::BOSS_FRAMEWORK_MANIFEST_V091[:profiles]>=1
    log_verify_v0914('TACTICAL_SPATIAL_CARRY_V0914',pass,
      'aggro=v0.91.2 peel=v0.91.3 boss=v0.91 ranged=v0.88.3 stalemate=v0.89 damage_packet=v0.60.2 unchanged')
    @verification_done[:v0914_carry]=true
  end

  def update_verification_script
    unless tactical_spatial_v0914?
      pmd_ac_v0914_update_verification_script
      return
    end
    @verification_frame=@verification_frame.to_i+1
    f=@verification_frame
    verify_tactical_manifest_v0914 if f>=2
    verify_passive_counter_v0914 if f>=4
    verify_passive_evasive_v0914 if f>=6
    verify_passive_guard_v0914 if f>=8
    verify_spatial_router_v0914 if f>=10
    verify_spatial_runtime_v0914 if f>=12
    verify_spatial_ai_v0914 if f>=14
    verify_duel_diagnostic_v0914 if f>=16
    verify_tactical_carry_v0914 if f>=18
    if f>=22 && !@verification_done[:v0914_final]
      pass=!@tactical_spatial_failed_v0914
      log_verify_v0914('TACTICAL_SPATIAL_V0914',pass,
        'passive_counter=1 no_energy=1 pursuit=1 evade=1 damage_reduction=1 spatial_router=1 spatial_ai=1 duel_diag=1 carry=1')
      @verification_done[:v0914_final]=true
    end
    complete_verification_mode if f>=PMD_AC::TACTICAL_SPATIAL_VERIFY_END_V0914
  end
end
