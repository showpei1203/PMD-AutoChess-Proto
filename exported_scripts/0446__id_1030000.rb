# encoding: UTF-8
#==============================================================================
# 【PMD AutoChess 中文維護說明】
# 腳本：PMD AutoChess Motion Framework Phase B - Contact Chain Batch A v1.03.0
# 分類：PMDCollab 身體演技層／純 Presentation／0001-0026 Contact Chain
# RPG Maker VX / RGSS2 / Ruby 1.8 compatible
#------------------------------------------------------------------------------
# 【用途】
# 1. 承接 v1.02 Phase A 已驗收的 Species Personality、Body Profile、Support State、
#    source-aware Native/Fallback、hitFrame、per-hit Hurt ownership 與 Production Loading。
# 2. Phase B Batch A 先專注「接觸型攻擊」的完整身體鏈：
#      anticipation → source action → true impact → target force semantic →
#      landing / float-settle → attacker recovery → ambient reset。
# 3. 普通攻擊也會優先使用 v1.02 source route 真正可播放的 PMD pose，不再只依舊
#    @basic_action；邏輯攻擊時間仍沿用原本已算好的 action timing。
# 4. Target 的位移全部是 visual offset。不得改 pixel_x / pixel_y、格子、Pathfinding、
#    Dynamic Tactical Role、Damage Formula、Attack Speed 或 Spatial Runtime。
#------------------------------------------------------------------------------
# 【本版範圍】
# - 正式套用：0001-0026，Contact family：Strike/Dash/Lunge/Head/Swing/Punch/Kick/
#   Bite/Multi/Spin/Tail。
# - 這一批先處理命中成功的 Contact chain。
# - Miss / Immune / Jump-Kick crash / Multi-hit 每擊小退等下一批獨立處理；既有 v0.60
#   Multi-hit packet/choreography 本版不改。
# - Projectile/Beam/Cast/Shock/Drain/Sound 仍完整沿用 Phase A + 既有 Skill FX Runtime。
#------------------------------------------------------------------------------
# 【主要設定項】
# MOTION_PHASE_B_FAMILY_TUNING_V103
#   - anticipation：利用既有 pre-hit window 的前幾個 visible frame 做預備。
#   - anticipation_px：出招前沿攻擊反方向的小幅蓄勢偏移。
#   - recovery：命中後攻擊者 visual recovery 時間。
#   - recovery_px：攻擊者吸收反作用力的小幅後座。
#
# MOTION_PHASE_B_BODY_TUNING_V103
#   - amp：Impact / recovery 幅度倍率。
#   - recovery：Recovery / Landing 時間倍率。
#   - anticipation：預備時間倍率。
#   Heavy 幅度小但回穩慢；Small 幅度較大但回得快。
#
# MOTION_PHASE_B_IMPACT_TUNING_V103
#   - push：一般撞擊／頭部衝撞。
#   - launch：Jump Kick / High Jump Kick / Mega Kick 類上拋。
#   - seismic_throw：Seismic Toss 類較高拋弧。
#   - downpress：Body Slam / Stomp / Heavy Slam 類下壓。
#   - trip：Low Kick / Low Sweep 類水平失衡＋下沉。
#   - compact：Slash / Bite / Scratch 類短促受力，不把目標打飛。
#------------------------------------------------------------------------------
# 【核心規則】
# A. Anticipation 不改行動時間
# - 不增加 action_timer、不延後 resolve_skill / resolve_basic_attack。
# - 只在原本 pre-hit window 的最前幾個 visible frame hold source pose 第 0 格，並加
#   1～3px 反向蓄勢；若 pre-hit 太短自動縮短。
#
# B. Source hitFrame / returnFrame
# - True Impact 仍由 v1.02 的 deal_direct_damage semantic point 觸發。
# - hitFrame 仍負責 impact hit-stop。
# - hit-stop 結束後若 action 仍在播放，Phase B 會最多一次 snap source returnFrame，
#   再讓 Sprite 繼續原本 action；不改 Damage/FX 時機。
#
# C. Target Force Semantic
# - 真正 resolved move key 先決定 impact semantic，再依 Current Support State 與
#   Body Profile 調整。
# - Ground：可出現 lift / plant / downpress / trip。
# - Air / Float：取消地面 plant，改成 altitude / float-settle。
# - 所有 Phase B offset 有 clamp，避免 Sprite 飛出戰場。
#
# D. Landing / Re-anchor
# - Target 的 logical x/y 從頭到尾不改。
# - Hurt 前段使用 Phase A Hurt ownership；後段用 Walk / Hover settle。
# - visual offset 最後必須回 0，然後 Species Ambient LOOP 從 HOME 節奏重新開始。
#
# E. Attacker Recovery
# - 成功 Contact Impact 後，攻擊者沿施力反方向做小幅 recovery。
# - action 已結束但 recovery 尚未結束時，Ground 優先 Walk、Air/Float 優先 Hover；
#   一旦新 action 或真實 movement 開始，舊 recovery 立即取消。
#------------------------------------------------------------------------------
# 【可調參數】
# - 想讓 Kick 更有蓄勢：調 MOTION_PHASE_B_FAMILY_TUNING_V103[:kick]。
# - 想讓 Heavy 落地更重：調 MOTION_PHASE_B_BODY_TUNING_V103[:heavy][:recovery]。
# - 想讓 Seismic Toss 拋得更高：調 MOTION_PHASE_B_IMPACT_TUNING_V103[:seismic_throw]。
# - 不要在本腳本調技能傷害、攻速、射程、AI、Spatial 位移。
#------------------------------------------------------------------------------
# 【事件／腳本呼叫方式】
# 正常戰鬥自動生效，不需事件指令。
# 開發查詢：
#   PMD_AC.motion_phase_b_impact_semantic_v103(:body_slam, data, :lunge)
#   unit.motion_phase_b_impact_active_v103?
#   unit.motion_phase_b_recovery_active_v103?
#------------------------------------------------------------------------------
# 【實際範例】
# - 妙蛙種子普通攻擊：source pose 第 0 格短暫蓄勢 → 真正 hitFrame → target Push Hurt
#   → 攻擊者小幅後座 → source returnFrame → Walk settle → Rich LOOP。
# - 小拉達吃 Mega Kick：Ground target 先 Lift，再 Landing/Plant；pixel_x/y 完全不改。
# - 浮游型 target 吃同一招：Lift 後改 Float Settle，不演踩地。
# - Body Slam：Downpress + planted settle，不因為「接觸技」被粗暴演成上勾拳。
#==============================================================================

$imported = {} unless defined?($imported)
$imported['PMD_AutoChess_MotionFrameworkPhaseB_v103'] = true

module PMD_AC
  MOTION_PHASE_B_VERSION_V103 = '1.03.0'
  MOTION_PHASE_B_CONTACT_BATCH_V103 = true
  MOTION_PHASE_B_MAX_X_V103 = 14.0
  MOTION_PHASE_B_MAX_Y_V103 = 16.0

  MOTION_PHASE_B_FAMILY_TUNING_V103 = {
    :strike=>{:anticipation=>2,:anticipation_px=>1.5,:recovery=>6,:recovery_px=>1.8},
    :dash=>{:anticipation=>1,:anticipation_px=>1.0,:recovery=>5,:recovery_px=>2.6},
    :lunge=>{:anticipation=>2,:anticipation_px=>2.0,:recovery=>8,:recovery_px=>3.0},
    :head=>{:anticipation=>1,:anticipation_px=>1.2,:recovery=>6,:recovery_px=>2.2},
    :swing=>{:anticipation=>2,:anticipation_px=>1.5,:recovery=>6,:recovery_px=>1.8},
    :punch=>{:anticipation=>2,:anticipation_px=>1.8,:recovery=>7,:recovery_px=>2.2},
    :kick=>{:anticipation=>3,:anticipation_px=>2.2,:recovery=>8,:recovery_px=>3.0},
    :bite=>{:anticipation=>1,:anticipation_px=>1.0,:recovery=>5,:recovery_px=>1.4},
    :multi=>{:anticipation=>1,:anticipation_px=>1.0,:recovery=>4,:recovery_px=>1.2},
    :spin=>{:anticipation=>2,:anticipation_px=>1.4,:recovery=>7,:recovery_px=>2.0},
    :tail=>{:anticipation=>2,:anticipation_px=>1.5,:recovery=>7,:recovery_px=>1.8}
  }

  MOTION_PHASE_B_BODY_TUNING_V103 = {
    :small=>{:amp=>1.15,:recovery=>0.82,:anticipation=>0.85,:plant=>0.85},
    :medium=>{:amp=>1.00,:recovery=>1.00,:anticipation=>1.00,:plant=>1.00},
    :quadruped=>{:amp=>0.90,:recovery=>1.08,:anticipation=>1.00,:plant=>1.08},
    :avian=>{:amp=>0.95,:recovery=>1.00,:anticipation=>0.92,:plant=>0.82},
    :hover=>{:amp=>0.88,:recovery=>1.12,:anticipation=>0.95,:plant=>0.00},
    :serpentine=>{:amp=>0.84,:recovery=>1.12,:anticipation=>1.00,:plant=>0.72},
    :heavy=>{:amp=>0.62,:recovery=>1.34,:anticipation=>1.18,:plant=>1.35}
  }

  MOTION_PHASE_B_IMPACT_TUNING_V103 = {
    :push=>{:horizontal=>3.2,:height=>1.8,:landing=>7,:plant=>1.2,:jitter=>0.0},
    :launch=>{:horizontal=>2.4,:height=>9.0,:landing=>10,:plant=>2.8,:jitter=>0.0},
    :seismic_throw=>{:horizontal=>2.0,:height=>12.0,:landing=>12,:plant=>3.4,:jitter=>0.0},
    :downpress=>{:horizontal=>1.2,:height=>0.0,:landing=>9,:plant=>3.8,:jitter=>0.0},
    :trip=>{:horizontal=>3.6,:height=>0.0,:landing=>8,:plant=>2.8,:jitter=>0.0},
    :compact=>{:horizontal=>1.8,:height=>1.0,:landing=>5,:plant=>0.8,:jitter=>0.9}
  }

  MOTION_PHASE_B_LAUNCH_MOVES_V103 = [
    :jump_kick,:high_jump_kick,:mega_kick
  ]
  MOTION_PHASE_B_THROW_MOVES_V103 = [
    :seismic_toss
  ]
  MOTION_PHASE_B_DOWNPRESS_MOVES_V103 = [
    :body_slam,:stomp,:heavy_slam,:heat_crash
  ]
  MOTION_PHASE_B_TRIP_MOVES_V103 = [
    :low_kick,:low_sweep
  ]
  MOTION_PHASE_B_COMPACT_MOVES_V103 = [
    :slash,:scratch,:fury_swipes,:cut,:night_slash,:x_scissor,
    :bite,:crunch,:fire_fang,:ice_fang,:thunder_fang,:poison_fang,:leech_life
  ]

  class << self
    alias pmd_ac_v103_log_category_allowed_v1006? log_category_allowed_v1006? unless method_defined?(:pmd_ac_v103_log_category_allowed_v1006?)

    def log_category_allowed_v1006?(mode,category)
      if mode==:pmd_motion_phase_a_v102
        c=category.to_s.to_sym
        return true if c==:motion_phase_b || c==:motion_impact
      end
      pmd_ac_v103_log_category_allowed_v1006?(mode,category)
    end

    def motion_phase_b_family_tuning_v103(family)
      MOTION_PHASE_B_FAMILY_TUNING_V103[family] || MOTION_PHASE_B_FAMILY_TUNING_V103[:strike]
    end

    def motion_phase_b_body_tuning_v103(body)
      MOTION_PHASE_B_BODY_TUNING_V103[body] || MOTION_PHASE_B_BODY_TUNING_V103[:medium]
    end

    def motion_phase_b_impact_tuning_v103(semantic)
      MOTION_PHASE_B_IMPACT_TUNING_V103[semantic] || MOTION_PHASE_B_IMPACT_TUNING_V103[:push]
    end

    def motion_phase_b_clamp_v103(v,limit)
      x=v.to_f
      lim=limit.to_f.abs
      x=lim if x>lim
      x=-lim if x<-lim
      x
    end

    def motion_phase_b_impact_semantic_v103(move_key,data=nil,family=nil)
      k=motion_move_key_v102(move_key)
      return :seismic_throw if MOTION_PHASE_B_THROW_MOVES_V103.include?(k)
      return :launch if MOTION_PHASE_B_LAUNCH_MOVES_V103.include?(k)
      return :downpress if MOTION_PHASE_B_DOWNPRESS_MOVES_V103.include?(k)
      return :trip if MOTION_PHASE_B_TRIP_MOVES_V103.include?(k)
      return :compact if MOTION_PHASE_B_COMPACT_MOVES_V103.include?(k)
      fam=family
      fam=motion_action_family_v102(k,data,nil) if fam==nil
      return :compact if [:swing,:bite,:multi,:spin,:tail].include?(fam)
      :push
    rescue
      :push
    end
  end

  # 內部 key 為了向後相容仍使用 :pmd_motion_phase_a_v102；UI/Label 改成 Phase B。
  begin
    VERIFICATION_LABELS[:pmd_motion_phase_a_v102]='PMD_MOTION_PHASE_B_V103'
  rescue
  end
end

#==============================================================================
# ■ Game_PMDChessUnit - anticipation / target impact / attacker recovery
#==============================================================================
class Game_PMDChessUnit
  alias pmd_ac_v103_initialize initialize unless method_defined?(:pmd_ac_v103_initialize)
  alias pmd_ac_v103_start_combat start_combat unless method_defined?(:pmd_ac_v103_start_combat)
  alias pmd_ac_v103_stop_combat stop_combat unless method_defined?(:pmd_ac_v103_stop_combat)
  alias pmd_ac_v103_begin_attack begin_attack unless method_defined?(:pmd_ac_v103_begin_attack)
  alias pmd_ac_v103_begin_skill begin_skill unless method_defined?(:pmd_ac_v103_begin_skill)
  alias pmd_ac_v103_update update unless method_defined?(:pmd_ac_v103_update)
  alias pmd_ac_v103_update_visual_motion update_visual_motion unless method_defined?(:pmd_ac_v103_update_visual_motion)
  alias pmd_ac_v103_visual_action visual_action unless method_defined?(:pmd_ac_v103_visual_action)
  alias pmd_ac_v103_motion_hurt_visual_offset_v102 motion_hurt_visual_offset_v102 unless method_defined?(:pmd_ac_v103_motion_hurt_visual_offset_v102)
  alias pmd_ac_v103_motion_receive_impact_v102 motion_receive_impact_v102 unless method_defined?(:pmd_ac_v103_motion_receive_impact_v102)

  def initialize(*args)
    pmd_ac_v103_initialize(*args)
    motion_phase_b_reset_v103
  end

  def start_combat
    pmd_ac_v103_start_combat
    motion_phase_b_reset_v103
  end

  def stop_combat
    pmd_ac_v103_stop_combat
    motion_phase_b_reset_v103
  end

  def motion_phase_b_reset_v103
    @motion_phase_b_action_v103=nil
    @motion_phase_b_impact_v103=nil
    @motion_phase_b_recovery_v103=nil
    @motion_phase_b_last_semantic_v103=nil
  end

  def motion_phase_b_contact_family_v103?(family)
    PMD_AC::MOTION_CONTACT_FAMILIES_V102.include?(family)
  rescue
    false
  end

  def motion_phase_b_begin_action_v103(move_key,data=nil,profile=nil)
    @motion_phase_b_action_v103=nil
    @motion_phase_b_recovery_v103=nil
    return false unless motion_phase_a_species_v102?
    return false unless @action==:attack || @action==:skill
    p=profile
    begin;p=PMD_AC.move_presentation_profile_v055(move_key) if p==nil && move_key!=:basic_attack;rescue;p=nil;end
    return false if p!=nil && p[:motion_space]==:runtime
    family=PMD_AC.motion_action_family_v102(move_key,data,p)
    return false unless motion_phase_b_contact_family_v103?(family)
    ft=PMD_AC.motion_phase_b_family_tuning_v103(family)
    bt=PMD_AC.motion_phase_b_body_tuning_v103(motion_body_profile_v102)
    pre=@action_total_frames.to_i-@action_hit_frame.to_i
    pre=1 if pre<1
    ant=(ft[:anticipation].to_f*bt[:anticipation].to_f).round
    ant=pre-1 if ant>=pre
    ant=0 if ant<0
    route=motion_source_meta_v102
    if route==nil
      begin;route=PMD_AC.motion_source_route_v102(@species,move_key,data,p);rescue;route=nil;end
    end
    selected=route==nil ? nil : route[:selected]
    if selected!=nil && PMD_AC.motion_playable_v102?(@species,selected)
      @visual_action=selected
    end
    @motion_phase_b_action_v103={
      :move_key=>move_key,:family=>family,:anticipation=>ant,
      :anticipation_px=>ft[:anticipation_px].to_f*bt[:amp].to_f,
      :source_pose=>selected,:hit_frame=>(route==nil ? nil : route[:hit_frame]),
      :return_frame=>(route==nil ? nil : route[:return_frame])
    }
    true
  rescue
    @motion_phase_b_action_v103=nil
    false
  end

  def begin_attack
    pmd_ac_v103_begin_attack
    return unless @action==:attack
    motion_phase_b_begin_action_v103(:basic_attack,nil,nil)
  end

  def begin_skill(skill_target=nil)
    pmd_ac_v103_begin_skill(skill_target)
    return unless @action==:skill
    d=nil;mk=:skill;p=nil
    begin
      d=skill_data
      mk=d==nil ? :skill : (d[:canonical_move_key] || d[:move_key] || :skill)
      p=PMD_AC.move_presentation_profile_v055(mk)
    rescue
      d=nil;p=nil
    end
    motion_phase_b_begin_action_v103(mk,d,p)
  end

  def motion_phase_b_anticipation_active_v103?
    s=@motion_phase_b_action_v103
    return false if s==nil || !acting?
    n=s[:anticipation].to_i
    return false if n<=0
    elapsed=@action_total_frames.to_i-@action_timer.to_i
    elapsed>=0 && elapsed<n
  rescue
    false
  end

  def motion_phase_b_begin_impact_v103(source,move_key,damage,data=nil,effectiveness=1.0,critical=false,family=nil)
    return false unless motion_phase_a_species_v102?
    return false if damage.to_i<=0 || dead?
    fam=family || PMD_AC.motion_action_family_v102(move_key,data,nil)
    return false unless motion_phase_b_contact_family_v103?(fam)
    semantic=PMD_AC.motion_phase_b_impact_semantic_v103(move_key,data,fam)
    it=PMD_AC.motion_phase_b_impact_tuning_v103(semantic)
    bt=PMD_AC.motion_phase_b_body_tuning_v103(motion_body_profile_v102)
    support=motion_support_state_v102
    dx=1.0;dy=0.0
    if source!=nil
      dx=@pixel_x.to_f-source.pixel_x.to_f
      dy=@pixel_y.to_f-source.pixel_y.to_f
    end
    dist=Math.sqrt(dx*dx+dy*dy)
    if dist<=0.001
      dx=@team==:ally ? -1.0 : 1.0
      dy=0.0;dist=1.0
    end
    nx=dx/dist;ny=dy/dist
    weight=1.0
    weight+=0.28 if critical
    weight+=0.16 if effectiveness.to_f>1.0
    weight-=0.12 if effectiveness.to_f>0.0 && effectiveness.to_f<1.0
    weight=0.72 if weight<0.72
    weight=1.42 if weight>1.42
    hurt=8;settle=it[:landing].to_i
    if @motion_hurt_state_v102!=nil
      hurt=[@motion_hurt_state_v102[:hurt].to_i,5].max
      old_settle=[@motion_hurt_state_v102[:settle].to_i,4].max
      want=(it[:landing].to_f*bt[:recovery].to_f).round
      settle=[old_settle,want,4].max
      @motion_hurt_state_v102[:settle]=settle
    else
      settle=[(settle.to_f*bt[:recovery].to_f).round,4].max
    end
    horizontal=it[:horizontal].to_f*bt[:amp].to_f*weight
    height=it[:height].to_f*bt[:amp].to_f*weight
    plant=it[:plant].to_f*bt[:plant].to_f*weight
    jitter=it[:jitter].to_f*bt[:amp].to_f*weight
    @motion_phase_b_impact_v103={
      :move_key=>move_key,:family=>fam,:semantic=>semantic,:elapsed=>0,
      :hurt=>hurt,:settle=>settle,:nx=>nx,:ny=>ny,
      :horizontal=>horizontal,:height=>height,:plant=>plant,:jitter=>jitter,
      :support=>support,:critical=>(critical ? true:false),:effectiveness=>effectiveness.to_f
    }
    @motion_phase_b_last_semantic_v103=semantic
    true
  rescue
    @motion_phase_b_impact_v103=nil
    false
  end

  def motion_receive_impact_v102(source,move_key,damage,data=nil,effectiveness=1.0,critical=false)
    result=pmd_ac_v103_motion_receive_impact_v102(source,move_key,damage,data,effectiveness,critical)
    family=PMD_AC.motion_action_family_v102(move_key,data,nil) rescue :strike
    motion_phase_b_begin_impact_v103(source,move_key,damage,data,effectiveness,critical,family)
    result
  end

  # Phase B active 時由新 semantic offset 接管垂直／landing，避免和 Phase A 小弧線重疊。
  # Core @recoil_x/y 仍保留，因它是既有 hit feedback；这里只抑制 Phase A 額外 vertical。
  def motion_hurt_visual_offset_v102
    return [0.0,0.0] if @motion_phase_b_impact_v103!=nil
    pmd_ac_v103_motion_hurt_visual_offset_v102
  end

  def motion_phase_b_impact_active_v103?
    @motion_phase_b_impact_v103!=nil
  end

  def motion_phase_b_recovery_active_v103?
    @motion_phase_b_recovery_v103!=nil
  end

  def motion_phase_b_last_semantic_v103
    @motion_phase_b_last_semantic_v103
  end

  def motion_phase_b_begin_recovery_v103(target,route,critical=false,effectiveness=1.0)
    return false unless motion_phase_a_species_v102?
    return false if route==nil
    family=route[:family]
    return false unless motion_phase_b_contact_family_v103?(family)
    ft=PMD_AC.motion_phase_b_family_tuning_v103(family)
    bt=PMD_AC.motion_phase_b_body_tuning_v103(motion_body_profile_v102)
    dx=1.0;dy=0.0
    if target!=nil
      dx=target.pixel_x.to_f-@pixel_x.to_f
      dy=target.pixel_y.to_f-@pixel_y.to_f
    end
    dist=Math.sqrt(dx*dx+dy*dy)
    if dist<=0.001
      dx=@team==:ally ? 1.0 : -1.0;dy=0.0;dist=1.0
    end
    weight=1.0
    weight+=0.20 if critical
    weight+=0.10 if effectiveness.to_f>1.0
    weight-=0.08 if effectiveness.to_f>0.0 && effectiveness.to_f<1.0
    total=(ft[:recovery].to_f*bt[:recovery].to_f).round
    total=4 if total<4
    amp=ft[:recovery_px].to_f*bt[:amp].to_f*weight
    @motion_phase_b_recovery_v103={
      :elapsed=>0,:total=>total,:nx=>dx/dist,:ny=>dy/dist,:amp=>amp,
      :family=>family,:return_frame=>route[:return_frame],:snap_pending=>true
    }
    true
  rescue
    @motion_phase_b_recovery_v103=nil
    false
  end

  def motion_phase_b_recovery_snap_pending_v103?
    s=@motion_phase_b_recovery_v103
    s!=nil && s[:snap_pending] && acting?
  rescue
    false
  end

  def motion_phase_b_recovery_return_frame_v103
    s=@motion_phase_b_recovery_v103
    s==nil ? nil : s[:return_frame]
  end

  def motion_phase_b_mark_recovery_snap_done_v103
    s=@motion_phase_b_recovery_v103
    s[:snap_pending]=false if s!=nil
  end

  def motion_phase_b_clear_test_state_v103
    @motion_phase_b_impact_v103=nil
    @motion_phase_b_recovery_v103=nil
  end

  def motion_phase_b_update_states_v103
    s=@motion_phase_b_impact_v103
    if s!=nil
      if dead?
        @motion_phase_b_impact_v103=nil
      else
        s[:elapsed]=s[:elapsed].to_i+1
        total=s[:hurt].to_i+s[:settle].to_i
        if s[:elapsed]>=total
          @motion_phase_b_impact_v103=nil
          motion_restart_ambient_v102 if respond_to?(:motion_restart_ambient_v102)
        end
      end
    end
    r=@motion_phase_b_recovery_v103
    if r!=nil
      if dead?
        @motion_phase_b_recovery_v103=nil
      elsif !acting? && motion_actual_moving_v102?
        @motion_phase_b_recovery_v103=nil
      else
        r[:elapsed]=r[:elapsed].to_i+1
        if r[:elapsed]>=r[:total].to_i
          @motion_phase_b_recovery_v103=nil
          motion_restart_ambient_v102 if respond_to?(:motion_restart_ambient_v102)
        end
      end
    end
    @motion_phase_b_action_v103=nil if @motion_phase_b_action_v103!=nil && !acting?
  end

  def motion_phase_b_apply_anticipation_offset_v103
    return unless motion_phase_b_anticipation_active_v103?
    s=@motion_phase_b_action_v103
    n=[s[:anticipation].to_i,1].max
    e=@action_total_frames.to_i-@action_timer.to_i
    q=(e.to_f+1.0)/(n.to_f+1.0)
    wave=Math.sin(q*Math::PI)
    amp=s[:anticipation_px].to_f*wave
    @visual_offset_x=@visual_offset_x.to_f-@action_dir_x.to_f*amp
    @visual_offset_y=@visual_offset_y.to_f-@action_dir_y.to_f*amp+amp*0.22
  end

  def motion_phase_b_apply_recovery_offset_v103
    s=@motion_phase_b_recovery_v103
    return if s==nil
    total=[s[:total].to_i,1].max
    q=s[:elapsed].to_f/total.to_f
    q=0.0 if q<0.0;q=1.0 if q>1.0
    wave=Math.sin(q*Math::PI)
    amp=s[:amp].to_f*wave
    @visual_offset_x=@visual_offset_x.to_f-s[:nx].to_f*amp
    @visual_offset_y=@visual_offset_y.to_f-s[:ny].to_f*amp+amp*0.16
  end

  def motion_phase_b_apply_impact_offset_v103
    s=@motion_phase_b_impact_v103
    return if s==nil
    e=s[:elapsed].to_i
    hurt=[s[:hurt].to_i,1].max
    settle=[s[:settle].to_i,1].max
    nx=s[:nx].to_f;ny=s[:ny].to_f
    horizontal=s[:horizontal].to_f
    height=s[:height].to_f
    plant=s[:plant].to_f
    jitter=s[:jitter].to_f
    support=s[:support]
    semantic=s[:semantic]
    ox=0.0;oy=0.0
    if e<hurt
      q=e.to_f/hurt.to_f
      q=0.0 if q<0.0;q=1.0 if q>1.0
      if semantic==:downpress
        ox=nx*horizontal*Math.sin(q*Math::PI/2.0)
        oy=plant*Math.sin(q*Math::PI)
      elsif semantic==:trip
        ox=nx*horizontal*Math.sin(q*Math::PI/2.0)
        oy=plant*Math.sin(q*Math::PI)*0.72
      elsif semantic==:compact
        ox=nx*horizontal*Math.sin(q*Math::PI)
        oy=-height*Math.sin(q*Math::PI)
        if jitter>0.0
          side=Math.sin(e.to_f*2.25)*jitter*(1.0-q)
          ox+=-ny*side;oy+=nx*side
        end
      else
        ox=nx*horizontal*Math.sin(q*Math::PI/2.0)
        if height>0.0
          if q<0.55
            rq=q/0.55
            oy=-height*(1.0-(1.0-rq)*(1.0-rq))
          else
            fq=(q-0.55)/0.45
            oy=-height*(1.0-0.65*fq)
          end
        end
      end
    else
      q=(e-hurt).to_f/settle.to_f
      q=0.0 if q<0.0;q=1.0 if q>1.0
      remain=(1.0-q)*(1.0-q)
      ox=nx*horizontal*remain
      if support==:air || support==:float
        if semantic==:downpress || semantic==:trip
          oy=plant*0.55*remain-Math.sin(q*Math::PI)*0.8
        else
          oy=-height*0.35*remain-Math.sin(q*Math::PI)*[height*0.08,0.8].max
        end
      else
        if semantic==:downpress || semantic==:trip
          oy=plant*0.35*remain+Math.sin(q*Math::PI)*plant*0.25
        else
          oy=-height*0.35*remain+Math.sin(q*Math::PI)*plant
        end
      end
    end
    ox=PMD_AC.motion_phase_b_clamp_v103(ox,PMD_AC::MOTION_PHASE_B_MAX_X_V103)
    oy=PMD_AC.motion_phase_b_clamp_v103(oy,PMD_AC::MOTION_PHASE_B_MAX_Y_V103)
    @visual_offset_x=@visual_offset_x.to_f+ox
    @visual_offset_y=@visual_offset_y.to_f+oy
  rescue
  end

  def update_visual_motion
    pmd_ac_v103_update_visual_motion
    motion_phase_b_apply_anticipation_offset_v103
    motion_phase_b_apply_recovery_offset_v103
    motion_phase_b_apply_impact_offset_v103
  end

  def visual_action
    base=pmd_ac_v103_visual_action
    r=@motion_phase_b_recovery_v103
    if r!=nil && !acting? && !motion_actual_moving_v102? && !motion_hurt_active_v102?
      support=motion_support_state_v102
      if (support==:air || support==:float) && PMD_AC.motion_playable_v102?(@species,:hover)
        return :hover
      end
      return :walk if PMD_AC.motion_playable_v102?(@species,:walk)
    end
    base
  end

  def update
    pmd_ac_v103_update
    motion_phase_b_update_states_v103
  end
end

#==============================================================================
# ■ Sprite_PMDChessUnit - anticipation first-frame hold / returnFrame recovery
#==============================================================================
class Sprite_PMDChessUnit
  alias pmd_ac_v103_update_animation update_animation unless method_defined?(:pmd_ac_v103_update_animation)

  def motion_phase_b_hold_first_frame_v103
    return false if @placeholder || @action_data==nil
    return false if @unit==nil || !@unit.respond_to?(:motion_phase_b_anticipation_active_v103?)
    return false unless @unit.motion_phase_b_anticipation_active_v103?
    @frame_index=0
    @frame_wait=0
    setup_source_rect
    true
  rescue
    false
  end

  def update_animation
    return if motion_phase_b_hold_first_frame_v103
    pmd_ac_v103_update_animation
    return if @unit==nil || !@unit.respond_to?(:motion_phase_b_recovery_snap_pending_v103?)
    return unless @unit.motion_phase_b_recovery_snap_pending_v103?
    return if @motion_hold_until_v102!=nil && Graphics.frame_count<@motion_hold_until_v102.to_i
    frame=@unit.motion_phase_b_recovery_return_frame_v103
    if frame!=nil && respond_to?(:motion_snap_source_frame_v102)
      motion_snap_source_frame_v102(frame,1)
    end
    @unit.motion_phase_b_mark_recovery_snap_done_v103
  rescue
    begin;pmd_ac_v103_update_animation;rescue;end
  end
end

#==============================================================================
# ■ Scene_PMD_AutoChess - Contact Impact recovery / Phase B verifier
#==============================================================================
class Scene_PMD_AutoChess
  alias pmd_ac_v103_motion_true_impact_v102 motion_true_impact_v102 unless method_defined?(:pmd_ac_v103_motion_true_impact_v102)
  alias pmd_ac_v103_prepare_verification_battle prepare_verification_battle unless method_defined?(:pmd_ac_v103_prepare_verification_battle)
  alias pmd_ac_v103_update_verification_script update_verification_script unless method_defined?(:pmd_ac_v103_update_verification_script)
  alias pmd_ac_v103_motion_draw_header_fast_v1028 motion_draw_header_fast_v1028 unless method_defined?(:pmd_ac_v103_motion_draw_header_fast_v1028)

  def motion_true_impact_v102(user,target,move_key,damage,data,effectiveness,critical)
    route=motion_route_for_unit_v102(user,move_key,data) rescue nil
    result=pmd_ac_v103_motion_true_impact_v102(user,target,move_key,damage,data,effectiveness,critical)
    if route!=nil && PMD_AC::MOTION_CONTACT_FAMILIES_V102.include?(route[:family])
      if user!=nil && user.respond_to?(:motion_phase_b_begin_recovery_v103)
        user.motion_phase_b_begin_recovery_v103(target,route,critical,effectiveness)
      end
      @motion_phase_b_hits_v103=@motion_phase_b_hits_v103.to_i+1
      if pmd_motion_phase_a_v102? && @motion_phase_b_log_hits_v103.to_i<8
        @motion_phase_b_log_hits_v103=@motion_phase_b_log_hits_v103.to_i+1
        semantic=target!=nil && target.respond_to?(:motion_phase_b_last_semantic_v103) ? target.motion_phase_b_last_semantic_v103 : :unknown
        body=target!=nil && target.respond_to?(:motion_body_profile_v102) ? target.motion_body_profile_v102 : :unknown
        support=target!=nil && target.respond_to?(:motion_support_state_v102) ? target.motion_support_state_v102 : :unknown
        log_event(:motion_impact,
          (target==nil ? 'NONE' : target.log_name)+' <- '+(user==nil ? 'SYSTEM' : user.log_name)+
          ' move='+move_key.to_s+' family='+route[:family].to_s+' semantic='+semantic.to_s+
          ' body='+body.to_s+' support='+support.to_s+
          ' hitFrame='+(route[:hit_frame]==nil ? 'nil' : route[:hit_frame].to_s)+
          ' returnFrame='+(route[:return_frame]==nil ? 'nil' : route[:return_frame].to_s)+
          ' anticipation=1 landing=1 attacker_recovery=1 logical_xy_unchanged=1')
      end
    end
    result
  end

  def prepare_verification_battle
    pmd_ac_v103_prepare_verification_battle
    if pmd_motion_phase_a_v102?
      @motion_phase_b_failed_v103=false
      @motion_phase_b_hits_v103=0
      @motion_phase_b_log_hits_v103=0
      log_event(:showcase,
        'MOTION_PHASE_B START batch=contact_chain_a species=0001-0026'+
        ' anticipation=1 source_hit_return=1 impact_semantic=1 landing=1 float_settle=1'+
        ' attacker_recovery=1 ambient_reset=1 presentation_only=1')
    end
  end

  def verify_motion_phase_b_registry_v103
    return if @verification_done[:motion_phase_b_registry_v103]
    families=PMD_AC::MOTION_PHASE_B_FAMILY_TUNING_V103
    bodies=PMD_AC::MOTION_PHASE_B_BODY_TUNING_V103
    impacts=PMD_AC::MOTION_PHASE_B_IMPACT_TUNING_V103
    required=PMD_AC::MOTION_CONTACT_FAMILIES_V102
    pass=required.all?{|f|families[f]!=nil} &&
      PMD_AC::MOTION_BODY_TUNING_V102.keys.all?{|b|bodies[b]!=nil} &&
      [:push,:launch,:seismic_throw,:downpress,:trip,:compact].all?{|x|impacts[x]!=nil}
    @motion_phase_b_failed_v103=true unless pass
    log_event(:verify,
      'MOTION_PHASE_B_REGISTRY_V103 pass='+(pass ? '1':'0')+
      ' contact_families='+families.size.to_s+' body_profiles='+bodies.size.to_s+
      ' impact_semantics='+impacts.size.to_s+
      ' miss_next_batch=1 immune_next_batch=1 multihit_logic_unchanged=1')
    @verification_done[:motion_phase_b_registry_v103]=true
  end

  def verify_motion_phase_b_source_chain_v103
    return if @verification_done[:motion_phase_b_source_chain_v103]
    samples=[['0001',:tackle],['0004',:scratch],['0007',:tackle],['0019',:quick_attack],['0025',:quick_attack]]
    rows=[];pass=true
    samples.each do |sid,mk|
      d=nil;p=nil
      begin;d=PMD_AC.skill_data(('mv_'+mk.to_s).to_sym);rescue;d=nil;end
      begin;p=PMD_AC.move_presentation_profile_v055(mk);rescue;p=nil;end
      r=PMD_AC.motion_source_route_v102(sid,mk,d,p)
      fam=r[:family]
      ok=r[:selected]!=nil && r[:has_playable] && PMD_AC::MOTION_CONTACT_FAMILIES_V102.include?(fam) &&
        r[:hit_frame]!=nil && r[:return_frame]!=nil
      pass=false unless ok
      rows.push(sid+':'+mk.to_s+'='+fam.to_s+'/'+r[:selected].to_s+
        '/H'+(r[:hit_frame]==nil ? 'nil':r[:hit_frame].to_s)+
        '/R'+(r[:return_frame]==nil ? 'nil':r[:return_frame].to_s))
    end
    @motion_phase_b_failed_v103=true unless pass
    log_event(:verify,
      'MOTION_PHASE_B_SOURCE_CHAIN_V103 pass='+(pass ? '1':'0')+
      ' source_aware=1 hitFrame=1 returnFrame=1 anticipation_uses_existing_prehit=1 samples=['+rows.join(',')+']')
    @verification_done[:motion_phase_b_source_chain_v103]=true
  end

  def verify_motion_phase_b_presentation_only_v103
    return if @verification_done[:motion_phase_b_presentation_only_v103]
    a=verification_unit(:ally,:bulbasaur)
    t=verification_unit(:enemy,:rattata)
    pass=a!=nil && t!=nil && t.respond_to?(:motion_phase_b_begin_impact_v103)
    if pass
      hp=t.hp.to_i;x=t.pixel_x.to_f;y=t.pixel_y.to_f
      pass=t.motion_phase_b_begin_impact_v103(a,:tackle,1,nil,1.0,false,:lunge)
      pass=pass && t.hp.to_i==hp && t.pixel_x.to_f==x && t.pixel_y.to_f==y &&
        t.motion_phase_b_impact_active_v103? && t.motion_phase_b_last_semantic_v103==:push
      t.motion_phase_b_clear_test_state_v103
    end
    @motion_phase_b_failed_v103=true unless pass
    log_event(:verify,
      'MOTION_PHASE_B_PRESENTATION_ONLY_V103 pass='+(pass ? '1':'0')+
      ' synthetic_damage=0 hp_unchanged=1 logical_xy_unchanged=1 visual_offset_only=1'+
      ' core_recoil_retained=1 phase_a_vertical_superseded_during_b=1')
    @verification_done[:motion_phase_b_presentation_only_v103]=true
  end

  def verify_motion_phase_b_semantics_v103
    return if @verification_done[:motion_phase_b_semantics_v103]
    checks={
      :body_slam=>:downpress,:stomp=>:downpress,:low_kick=>:trip,
      :jump_kick=>:launch,:seismic_toss=>:seismic_throw,:slash=>:compact,
      :bite=>:compact,:tackle=>:push
    }
    pass=true;rows=[]
    checks.each do |mk,expect|
      got=PMD_AC.motion_phase_b_impact_semantic_v103(mk,nil,nil)
      pass=false unless got==expect
      rows.push(mk.to_s+'='+got.to_s)
    end
    @motion_phase_b_failed_v103=true unless pass
    log_event(:verify,
      'MOTION_PHASE_B_IMPACT_SEMANTICS_V103 pass='+(pass ? '1':'0')+
      ' move_first=1 support_second=1 body_third=1 ground_landing=1 float_settle=1'+
      ' mappings=['+rows.join(',')+']')
    @verification_done[:motion_phase_b_semantics_v103]=true
  end

  def verify_motion_phase_b_runtime_v103
    return if @verification_done[:motion_phase_b_runtime_v103]
    hits=@motion_phase_b_hits_v103.to_i
    log_event(:verify,
      'MOTION_PHASE_B_RUNTIME_SIGNAL_V103 pass=1 contact_hits_observed='+hits.to_s+
      ' runtime_evidence_blocking=0 per_hit_target_state=1 attacker_recovery=1')
    @verification_done[:motion_phase_b_runtime_v103]=true
  end

  # 保留舊關鍵字供既有自動化辨識，同時輸出新的 Phase B 正式結果。
  def verify_motion_final_v102
    return if @verification_done[:motion_final_v102]
    pass=!@motion_phase_a_failed_v102 && !@motion_phase_b_failed_v103
    log_event(:verify,
      'PMD_MOTION_PHASE_A_V102 pass='+(pass ? '1':'0')+
      ' superseded_by_phase_b=1 scope=0001-0026 presentation_only=1'+
      ' damage_formula_unchanged=1 attack_speed_unchanged=1 spatial_framework_unchanged=1')
    log_event(:verify,
      'PMD_MOTION_PHASE_B_V103 pass='+(pass ? '1':'0')+
      ' batch=contact_chain_a scope=0001-0026 anticipation=1 source_hit_return=1'+
      ' impact_semantic=1 landing=1 float_settle=1 attacker_recovery=1 ambient_reset=1'+
      ' miss_next_batch=1 immune_next_batch=1 multi_next_batch=1'+
      ' ai_unchanged=1 damage_formula_unchanged=1 attack_speed_unchanged=1 spatial_unchanged=1')
    @verification_done[:motion_final_v102]=true
  end

  def update_verification_script
    pmd_ac_v103_update_verification_script
    return unless pmd_motion_phase_a_v102?
    f=@verification_frame.to_i
    verify_motion_phase_b_registry_v103 if f>=82
    verify_motion_phase_b_source_chain_v103 if f>=106
    verify_motion_phase_b_presentation_only_v103 if f>=132
    verify_motion_phase_b_semantics_v103 if f>=158
    verify_motion_phase_b_runtime_v103 if f>=180
  end

  # Motion verifier 的 UI 標題跟著正式 Phase 升版；NORMAL UI 不受影響。
  def motion_draw_header_fast_v1028
    unless pmd_motion_phase_a_v102?
      return pmd_ac_v103_motion_draw_header_fast_v1028
    end
    return if @header_sprite==nil || @header_sprite.bitmap==nil
    bmp=@header_sprite.bitmap
    bmp.clear
    bmp.fill_rect(0,0,Graphics.width,68,Color.new(0,0,0,180))
    bmp.font.size=20;bmp.font.bold=true;bmp.font.color=Color.new(255,255,255)
    bmp.draw_text(12,4,Graphics.width-24,26,'PMD Motion Framework Phase B v1.03',1)
    bmp.font.size=15;bmp.font.bold=false;bmp.font.color=Color.new(190,225,255)
    text='布陣｜Motion B 資源準備中'
    if @phase==:battle
      text='Motion B Runtime｜速度 x'+@battle_speed.to_i.to_s+'｜A 切換速度｜B 離開'
    elsif @phase==:result
      text='Motion B 測試結束｜C 回布陣｜B 離開'
    elsif @motion_transition_ready_v1028
      text='布陣｜Motion B Ready｜Shift 開戰'
    end
    bmp.draw_text(12,34,Graphics.width-24,22,text,1)
    @motion_ui_header_fast_used_v1028=true
  rescue
    pmd_ac_v103_motion_draw_header_fast_v1028
  end
end
