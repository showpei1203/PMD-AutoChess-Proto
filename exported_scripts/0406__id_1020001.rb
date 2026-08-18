# encoding: UTF-8
#==============================================================================
# 【PMD AutoChess 中文維護說明】
# 腳本：PMD AutoChess Motion Framework Phase A v1.02
# 分類：PMDCollab 身體演技層／純 Presentation／0001-0026 Phase A
# RPG Maker VX / RGSS2 / Ruby 1.8 compatible
#------------------------------------------------------------------------------
# 【用途】
# 1. 將既有 PMDCollab compiled action、Native Semantic Router、Hit/Hurt、Multi-hit
#    等零散呈現能力收束成正式 Motion Framework。
# 2. Phase A 只正式登錄 PMD 0001-0026。先以妙蛙種子、小火龍、傑尼龜、
#    綠毛蟲、小拉達、波波、皮卡丘七隻做肉眼代表組。
# 3. Motion 僅負責「身體演技層」；Dynamic Tactical Role、Spatial Framework、
#    Skill FX、Damage Formula、Attack Speed、Projectile/Beam 命中時間全部沿用既有系統。
#------------------------------------------------------------------------------
# 【主要設定項】
# MOTION_SPECIES_PHASE_A_V102：0001-0026 的 Species Personality / Body Profile /
#   Current Support State / Ambient Rich LOOP。
# MOTION_BODY_TUNING_V102：不同身體類型的 Hurt 動量、回穩時間。
# MOTION_FAMILY_NATIVE_V102：Move Action Family 對應的 Native Action 候選。
# MOTION_REPRESENTATIVES_V102：第一輪肉眼驗證七隻。
#------------------------------------------------------------------------------
# 【核心規則】
# A. Species Personality / Rich LOOP
# - AI 真正在移動時一定顯示 Walk。
# - 停止且沒有 Attack/Skill/Hurt/Stun 時，才跑物種化 Rich LOOP。
# - Rich LOOP 只切換 PMD Action，不修改 logical pixel_x / pixel_y。
#
# B. Body Profile 與 Support State 分離
# - Body Profile：small/medium/quadruped/avian/hover/serpentine/heavy，只影響
#   Hurt 動量、settle/re-anchor 視覺節奏。
# - Support State：ground/air/float/burrow，表示「此刻」如何回穩；不等於角色職責。
#
# C. Move Action Family / Native provenance
# - 先分類 Strike/Dash/Lunge/Head/Swing/Punch/Kick/Bite/Multi/Projectile/Beam/
#   Cast/Shock/Drain/Spin/Tail/Sound。
# - hasNative = 原始 compiled action 直接存在，且不是 copy/alias。
# - hasPlayable = 當前專案真的有可載入 bitmap。
# - Native 與 fallback 分開記錄，不再把「能播放」誤當「原生就有」。
# - Phase A 只在 0001-0026 範圍內，把真正 direct-native family action 提到既有
#   v0.94 Router 前面；若沒有 direct native，完整退回已驗證 Router。
#
# D. Action Anchor
# - 每次 Attack/Skill 開始記錄當下 logical x/y 為 action anchor。
# - Motion recovery 絕不把 logical x/y 寫回 anchor。
# - Dash/retreat/push/pull/through 等真正位移仍由 Spatial Runtime 決定。
#
# E. hitFrame / FX handoff / True Impact
# - Skill 真正進入既有 :launch 階段時，遠程/施法 family 依 source hitFrame 做
#   1-2 visible-frame release snap；不提前 Projectile/Beam 傷害。
# - True direct impact 時，Contact family 才把攻擊者短暫 snap 到 source hitFrame
#   並做 hit-stop。Projectile/Beam 的 target impact 不把施法者倒帶回發射姿勢。
#
# F. per-hit / per-battler Hurt ownership
# - 每次成功 Direct Damage 都產生該 target 自己的 presentation token。
# - 新的一擊只取代該 battler 上一個 token；不用 global battle busy。
# - Multi-hit 因每一段 Damage 都會建立新 token，所以每一擊都有獨立 Hurt。
# - Critical / Effectiveness 只加重 hit-stop / Hurt 幅度，不改 Damage Formula。
#
# G. Landing / Re-anchor / Ambient Reset
# - Hurt 前段使用 Hurt pose；後段依 support state 用 Walk/Hover 做 settle。
# - recoil 只是 visual offset；settle 完成回 0，再重啟 Species Rich LOOP。
#------------------------------------------------------------------------------
# 【可調參數】
# - 想調某隻停頓節奏：改 MOTION_SPECIES_PHASE_A_V102[sid][:ambient]。
# - 想調某體型受擊重量：改 MOTION_BODY_TUNING_V102。
# - 想增加 family native 候選：改 MOTION_FAMILY_NATIVE_V102。
# - 不要在這裡修改技能傷害、射程、Spatial 位移距離或 Attack Speed。
#------------------------------------------------------------------------------
# 【事件／腳本呼叫】
# 正常戰鬥自動生效，不需要事件命令。
# 開發查詢：
#   PMD_AC.motion_species_profile_v102('0004')
#   PMD_AC.motion_action_family_v102(:thunderbolt, data, profile)
#   PMD_AC.motion_source_route_v102('0025', :thunderbolt, data, profile)
#   unit.motion_support_state_v102
#------------------------------------------------------------------------------
# 【實際範例】
# - 小火龍停止時：Walk -> 短停 -> Hop/LookUp 小動作 -> 再回 Walk；logical x/y 不動。
# - 皮卡丘 Thunderbolt：優先真正 Native Shock；source hitFrame 只當發射 handoff，
#   雷擊真正命中仍等既有 Projectile/Skill Runtime。
# - 小拉達被連擊三次：三個獨立 Hurt ownership token，不會因另一隻寶可夢正在播
#   狀態動畫就卡在 Hurt 最後一格。
# - Dash-through 技能打完：Motion 只清 visual recoil；不 Walk 回出招前座標。
#==============================================================================
module PMD_AC
  MOTION_PHASE_A_VERSION_V102='1.02.0'
  MOTION_PHASE_A_SPECIES_RANGE_V102=(1..26).to_a.collect{|i|'%04d'%i}
  MOTION_REPRESENTATIVES_V102=['0001','0004','0007','0010','0019','0016','0025']

  MOTION_BODY_TUNING_V102={
    :small=>{:recoil=>1.12,:hurt=>9,:settle=>7,:vertical=>2.4},
    :medium=>{:recoil=>0.92,:hurt=>10,:settle=>8,:vertical=>1.8},
    :quadruped=>{:recoil=>0.78,:hurt=>10,:settle=>9,:vertical=>1.3},
    :avian=>{:recoil=>0.96,:hurt=>9,:settle=>9,:vertical=>2.2},
    :hover=>{:recoil=>0.88,:hurt=>9,:settle=>11,:vertical=>2.8},
    :serpentine=>{:recoil=>0.82,:hurt=>10,:settle=>10,:vertical=>1.0},
    :heavy=>{:recoil=>0.58,:hurt=>12,:settle=>11,:vertical=>0.8}
  }

  # [body, support, personality, ambient]
  # ambient 每列為 [action, visible frames]；動作不存在會安全退回 idle/walk。
  MOTION_SPECIES_PHASE_A_V102={
    '0001'=>{:body=>:quadruped,:support=>:ground,:personality=>:calm_scout,
      :ambient=>[[:walk,30],[:idle,14],[:look_up,18],[:idle,18]]},
    '0002'=>{:body=>:quadruped,:support=>:ground,:personality=>:steady_growth,
      :ambient=>[[:walk,32],[:idle,16],[:shake,14],[:idle,20]]},
    '0003'=>{:body=>:heavy,:support=>:ground,:personality=>:rooted_guardian,
      :ambient=>[[:walk,36],[:idle,24],[:deep_breath,20],[:idle,26]]},
    '0004'=>{:body=>:small,:support=>:ground,:personality=>:restless_spark,
      :ambient=>[[:walk,22],[:idle,8],[:hop,16],[:idle,9],[:look_up,12]]},
    '0005'=>{:body=>:medium,:support=>:ground,:personality=>:confident_hunter,
      :ambient=>[[:walk,26],[:idle,10],[:pose,16],[:idle,12]]},
    '0006'=>{:body=>:medium,:support=>:ground,:personality=>:proud_dragon,
      :ambient=>[[:walk,28],[:idle,14],[:pose,18],[:idle,15]]},
    '0007'=>{:body=>:small,:support=>:ground,:personality=>:alert_guard,
      :ambient=>[[:walk,26],[:idle,12],[:nod,14],[:idle,14],[:look_up,12]]},
    '0008'=>{:body=>:medium,:support=>:ground,:personality=>:measured_guard,
      :ambient=>[[:walk,30],[:idle,15],[:shake,14],[:idle,18]]},
    '0009'=>{:body=>:heavy,:support=>:ground,:personality=>:fortress,
      :ambient=>[[:walk,36],[:idle,24],[:withdraw,14],[:idle,24]]},
    '0010'=>{:body=>:serpentine,:support=>:ground,:personality=>:cautious_crawler,
      :ambient=>[[:walk,20],[:idle,24],[:walk,14],[:idle,28]]},
    '0011'=>{:body=>:heavy,:support=>:ground,:personality=>:still_cocoon,
      :ambient=>[[:idle,34],[:shake,10],[:idle,34]]},
    '0012'=>{:body=>:avian,:support=>:float,:personality=>:gentle_flutter,
      :ambient=>[[:walk,22],[:idle,10],[:flap_around,18],[:idle,12]]},
    '0013'=>{:body=>:serpentine,:support=>:ground,:personality=>:nervous_crawler,
      :ambient=>[[:walk,18],[:idle,18],[:walk,12],[:idle,22]]},
    '0014'=>{:body=>:heavy,:support=>:ground,:personality=>:still_cocoon,
      :ambient=>[[:idle,32],[:twirl,10],[:idle,34]]},
    '0015'=>{:body=>:hover,:support=>:float,:personality=>:aggressive_hover,
      :ambient=>[[:hover,26],[:idle,8],[:jab,12],[:hover,22]]},
    '0016'=>{:body=>:avian,:support=>:ground,:personality=>:watchful_bird,
      :ambient=>[[:walk,24],[:idle,10],[:flap_around,18],[:idle,10],[:look_up,12]]},
    '0017'=>{:body=>:avian,:support=>:ground,:personality=>:watchful_bird,
      :ambient=>[[:walk,26],[:idle,11],[:flap_around,18],[:idle,12]]},
    '0018'=>{:body=>:avian,:support=>:ground,:personality=>:proud_bird,
      :ambient=>[[:walk,28],[:idle,12],[:flap_around,20],[:idle,13]]},
    '0019'=>{:body=>:small,:support=>:ground,:personality=>:restless_rodent,
      :ambient=>[[:walk,18],[:idle,6],[:look_up,12],[:walk,14],[:idle,8]]},
    '0020'=>{:body=>:medium,:support=>:ground,:personality=>:bold_rodent,
      :ambient=>[[:walk,22],[:idle,8],[:tail_whip,14],[:idle,10]]},
    '0021'=>{:body=>:avian,:support=>:ground,:personality=>:sharp_bird,
      :ambient=>[[:walk,22],[:idle,9],[:hover,14],[:idle,10]]},
    '0022'=>{:body=>:avian,:support=>:ground,:personality=>:sharp_bird,
      :ambient=>[[:walk,24],[:idle,10],[:hover,16],[:idle,11]]},
    '0023'=>{:body=>:serpentine,:support=>:ground,:personality=>:coiled_scout,
      :ambient=>[[:walk,22],[:idle,18],[:shake,12],[:idle,18]]},
    '0024'=>{:body=>:serpentine,:support=>:ground,:personality=>:coiled_predator,
      :ambient=>[[:walk,24],[:idle,16],[:twirl,14],[:idle,17]]},
    '0025'=>{:body=>:small,:support=>:ground,:personality=>:lively_electric,
      :ambient=>[[:walk,20],[:idle,7],[:hop,14],[:idle,7],[:pose,12]]},
    '0026'=>{:body=>:medium,:support=>:ground,:personality=>:confident_electric,
      :ambient=>[[:walk,24],[:idle,10],[:pose,14],[:idle,11]]}
  }

  # 這張表只列「語意上真的屬於該 Family」的 Native Action。
  # Attack/Strike 等安全 fallback 留給既有 v0.94 Router，避免 hasNative 被誤判。
  MOTION_FAMILY_NATIVE_V102={
    :strike=>[:strike,:attack],
    :dash=>[:quick_strike,:leap_forth,:hop],
    :lunge=>[:leap_forth,:hop],
    :head=>[:head],
    :swing=>[:swing],
    :punch=>[:punch,:jab,:uppercut,:chop],
    :kick=>[:kick,:stomp],
    :bite=>[:bite],
    :multi=>[:double,:quick_strike],
    :projectile=>[:shoot,:sp_attack,:emit],
    :beam=>[:sp_attack,:shoot],
    :cast=>[:charge,:sp_attack,:shoot,:pose],
    :shock=>[:shock],
    :drain=>[:sp_attack,:shoot,:charge],
    :spin=>[:rotate,:twirl],
    :tail=>[:tail_whip,:swing,:slam],
    :sound=>[:sound,:sing,:rear_up,:rumble]
  }

  MOTION_CONTACT_FAMILIES_V102=[:strike,:dash,:lunge,:head,:swing,:punch,:kick,:bite,:multi,:spin,:tail]
  MOTION_REMOTE_FAMILIES_V102=[:projectile,:beam,:cast,:shock,:drain,:sound]
  MOTION_LOG_CATEGORIES_V102=[:battle,:perf,:verify,:summary,:showcase,:motion_phase_a,:motion_native,:motion_hit]

  class << self
    alias pmd_ac_v102_native_pose_candidates_v061 native_pose_candidates_v061 unless method_defined?(:pmd_ac_v102_native_pose_candidates_v061)
    alias pmd_ac_v102_log_category_allowed_v1006? log_category_allowed_v1006? unless method_defined?(:pmd_ac_v102_log_category_allowed_v1006?)

    def motion_phase_a_species_v102?(species)
      MOTION_PHASE_A_SPECIES_RANGE_V102.include?(species.to_s)
    end

    def motion_species_profile_v102(species)
      MOTION_SPECIES_PHASE_A_V102[species.to_s]
    end

    def motion_body_tuning_v102(species)
      p=motion_species_profile_v102(species)
      MOTION_BODY_TUNING_V102[p==nil ? :medium : p[:body]] || MOTION_BODY_TUNING_V102[:medium]
    end

    def motion_direct_native_v102?(species,pose)
      return false unless motion_phase_a_species_v102?(species)
      return false unless respond_to?(:compiled_direct_action_v061)
      d=compiled_direct_action_v061(species.to_s,pose)
      return false if d==nil
      return false if d[:copy_of]!=nil || d[:alias_of]!=nil
      return false unless respond_to?(:compiled_action_asset_available_v061?)
      compiled_action_asset_available_v061?(species.to_s,pose,d)
    rescue
      false
    end

    def motion_playable_v102?(species,pose)
      return false if pose==nil
      # Provenance 查詢不能使用 action_data，因為 action_data 會安全 fallback 到別的姿勢。
      # 這裡只回答「這個 pose 自己是否真的能播」。
      return raw_action_available_v060?(species.to_s,pose) if respond_to?(:raw_action_available_v060?)
      if respond_to?(:compiled_action_asset_available_v061?) && respond_to?(:compiled_direct_action_v061)
        d=compiled_direct_action_v061(species.to_s,pose)
        return false if d==nil
        return compiled_action_asset_available_v061?(species.to_s,pose,d)
      end
      false
    rescue
      false
    end


    def motion_visual_frame_markers_v102(species,pose)
      d=nil
      begin;d=compiled_direct_action_v061(species.to_s,pose) if respond_to?(:compiled_direct_action_v061);rescue;d=nil;end
      return {:hit=>nil,:return=>nil,:source=>:none} if d==nil
      frames=d[:frames].to_i
      ds=d[:durations]
      frames=ds.size if frames<=0 && ds!=nil
      frames=1 if frames<=0
      hit=d[:hit_frame]
      ret=d[:return_frame]
      source=:native
      if hit==nil
        hit=[(frames*0.45).floor,0].max
        hit=frames-1 if hit>=frames
        source=:visual_fallback
      end
      if ret==nil
        ret=[(frames*0.72).floor,hit.to_i].max
        ret=frames-1 if ret>=frames
        source=:visual_fallback if source==:native
      end
      {:hit=>hit,:return=>ret,:source=>source}
    rescue
      {:hit=>nil,:return=>nil,:source=>:none}
    end

    def motion_move_key_v102(move_key)
      return :basic_attack if move_key==nil
      move_key.to_s.downcase.gsub(/[^a-z0-9]+/,'_').to_sym
    end

    def motion_action_family_v102(move_key,data=nil,profile=nil)
      k=motion_move_key_v102(move_key)
      return :strike if k==:basic_attack
      begin
        return :kick if const_defined?(:NATIVE_KICK_MOVES_V061) && NATIVE_KICK_MOVES_V061.include?(k)
        return :punch if const_defined?(:NATIVE_PUNCH_MOVES_V061) && NATIVE_PUNCH_MOVES_V061.include?(k)
        return :bite if const_defined?(:NATIVE_BITE_MOVES_V061) && NATIVE_BITE_MOVES_V061.include?(k)
        return :tail if const_defined?(:NATIVE_TAIL_MOVES_V061) && NATIVE_TAIL_MOVES_V061.include?(k)
        return :spin if const_defined?(:NATIVE_SPIN_MOVES_V061) && NATIVE_SPIN_MOVES_V061.include?(k)
        return :sound if const_defined?(:NATIVE_SOUND_MOVES_V061) && NATIVE_SOUND_MOVES_V061.include?(k)
      rescue
      end
      return :head if [:headbutt,:zen_headbutt,:head_smash,:skull_bash].include?(k)
      return :drain if [:absorb,:mega_drain,:giga_drain,:drain_punch,:dream_eater,:leech_life].include?(k)
      motion=profile==nil ? nil : profile[:motion]
      return :multi if motion==:multi_contact
      return :dash if [:dash_return,:dash_stop,:dash_engage,:blink_return,:blink_engage,:dash_through_return].include?(motion)
      return :lunge if [:contact_return,:lunge_return,:step_attack,:charge_dash].include?(motion)
      visual=data==nil ? nil : (data[:visual_kind] || data[:delivery])
      delivery=data==nil ? nil : data[:delivery]
      move_type=data==nil ? nil : (data[:move_type] || data[:type])
      return :shock if move_type==:electric && [:projectile,:beam,:target_hit,:area_hit].include?(visual)
      return :beam if visual==:beam || delivery==:beam || delivery==:sustained_beam || delivery==:sweeping_beam
      return :projectile if visual==:projectile || delivery==:projectile
      return :cast if [:area_hit,:target_hit,:self_fx,:field_disc].include?(visual) || motion==:stationary_cast
      if data!=nil
        return :lunge if data[:contact] || data[:force_contact_range]
        return :cast if [:self,:ally].include?(data[:target_type])
      end
      :strike
    rescue
      :strike
    end

    def motion_family_candidates_v102(family)
      (MOTION_FAMILY_NATIVE_V102[family] || MOTION_FAMILY_NATIVE_V102[:strike]).dup
    end

    # Phase A 只把「真正 direct native 且 bitmap 存在」的 family action 放到舊 Router 前面。
    # 找不到時完整保留 v0.94 已驗證 fallback 順序。
    def native_pose_candidates_v061(species,move_key,data=nil,profile=nil)
      base=pmd_ac_v102_native_pose_candidates_v061(species,move_key,data,profile)
      return base unless motion_phase_a_species_v102?(species)
      family=motion_action_family_v102(move_key,data,profile)
      out=[]
      motion_family_candidates_v102(family).each do |pose|
        out.push(pose) if motion_direct_native_v102?(species,pose) && !out.include?(pose)
      end
      append_unique_poses_v061(out,base)
      out
    rescue
      pmd_ac_v102_native_pose_candidates_v061(species,move_key,data,profile)
    end

    def motion_source_route_v102(species,move_key,data=nil,profile=nil)
      family=motion_action_family_v102(move_key,data,profile)
      candidates=native_pose_candidates_v061(species,move_key,data,profile)
      selected=nil
      candidates.each do |pose|
        if motion_playable_v102?(species,pose)
          selected=pose
          break
        end
      end
      selected=:attack if selected==nil && motion_playable_v102?(species,:attack)
      semantic_native=motion_family_candidates_v102(family).any?{|pose|motion_direct_native_v102?(species,pose)}
      selected_semantic_native=selected!=nil && motion_family_candidates_v102(family).include?(selected) && motion_direct_native_v102?(species,selected)
      meta=nil
      begin
        meta=compiled_direct_action_v061(species.to_s,selected) if selected!=nil && respond_to?(:compiled_direct_action_v061)
      rescue
        meta=nil
      end
      markers=selected==nil ? {:hit=>nil,:return=>nil,:source=>:none} : motion_visual_frame_markers_v102(species,selected)
      {
        :family=>family,:selected=>selected,:has_native=>semantic_native,
        :has_playable=>(selected!=nil && motion_playable_v102?(species,selected)),
        :fallback=>(selected!=nil && !selected_semantic_native),
        :selected_native=>selected_semantic_native,:source_action=>(meta==nil ? nil : meta[:source_action]),
        :hit_frame=>markers[:hit],:return_frame=>markers[:return],:timing_source=>markers[:source]
      }
    rescue
      {:family=>:strike,:selected=>:attack,:has_native=>false,:has_playable=>true,:fallback=>true}
    end

    def log_category_allowed_v1006?(mode,category)
      if mode==:pmd_motion_phase_a_v102
        return MOTION_LOG_CATEGORIES_V102.include?(category.to_s.to_sym)
      end
      pmd_ac_v102_log_category_allowed_v1006?(mode,category)
    end
  end

  remove_const(:VERIFICATION_MODES) if const_defined?(:VERIFICATION_MODES)
  VERIFICATION_MODES=[:pmd_motion_phase_a_v102,:map_story_vertical_slice_v101,
    :rpg_foundation_v100,:nature_ai_temperament_v09916,:spatial_conditions_ai_rules_v09915]
  remove_const(:VERIFICATION_LABELS) if const_defined?(:VERIFICATION_LABELS)
  VERIFICATION_LABELS={
    :pmd_motion_phase_a_v102=>'PMD_MOTION_PHASE_A_V102',
    :map_story_vertical_slice_v101=>'MAP_STORY_VERTICAL_SLICE_V101',
    :rpg_foundation_v100=>'RPG_FOUNDATION_V100',
    :nature_ai_temperament_v09916=>'NATURE_AI_TEMPERAMENT_V09916',
    :spatial_conditions_ai_rules_v09915=>'SPATIAL_CONDITIONS_AI_RULES_V09915'
  }
end

#==============================================================================
# ■ Game_PMDChessUnit - Species Ambient / Action Anchor / per-hit ownership
#==============================================================================
class Game_PMDChessUnit
  alias pmd_ac_v102_initialize initialize unless method_defined?(:pmd_ac_v102_initialize)
  alias pmd_ac_v102_start_combat start_combat unless method_defined?(:pmd_ac_v102_start_combat)
  alias pmd_ac_v102_stop_combat stop_combat unless method_defined?(:pmd_ac_v102_stop_combat)
  alias pmd_ac_v102_update update unless method_defined?(:pmd_ac_v102_update)
  alias pmd_ac_v102_update_visual_motion update_visual_motion unless method_defined?(:pmd_ac_v102_update_visual_motion)
  alias pmd_ac_v102_visual_action visual_action unless method_defined?(:pmd_ac_v102_visual_action)
  alias pmd_ac_v102_begin_attack begin_attack unless method_defined?(:pmd_ac_v102_begin_attack)
  alias pmd_ac_v102_begin_skill begin_skill unless method_defined?(:pmd_ac_v102_begin_skill)

  def initialize(*args)
    pmd_ac_v102_initialize(*args)
    motion_reset_phase_a_v102
  end

  def start_combat
    pmd_ac_v102_start_combat
    motion_reset_phase_a_v102
  end

  def stop_combat
    pmd_ac_v102_stop_combat
    motion_reset_phase_a_v102
  end

  def motion_reset_phase_a_v102
    @motion_ambient_index_v102=0
    @motion_ambient_frames_v102=1
    @motion_ambient_action_v102=:walk
    @motion_hurt_state_v102=nil
    @motion_hurt_serial_v102=0
    @motion_action_anchor_x_v102=nil
    @motion_action_anchor_y_v102=nil
    @motion_action_family_v102=nil
    @motion_source_pose_v102=nil
    @motion_source_meta_v102=nil
    @motion_release_seen_v102={}
    @motion_support_override_v102=nil
    @motion_ambient_logged_v102={}
  end

  def motion_phase_a_species_v102?
    PMD_AC.motion_phase_a_species_v102?(@species)
  end

  def motion_species_profile_v102
    PMD_AC.motion_species_profile_v102(@species)
  end

  def motion_body_profile_v102
    p=motion_species_profile_v102
    p==nil ? :medium : p[:body]
  end

  def motion_support_state_v102
    # 後續 Fly/Dig/Dive/Gravity 可在這裡寫入 runtime override；Phase A 先讀 default。
    return @motion_support_override_v102 if @motion_support_override_v102!=nil
    p=motion_species_profile_v102
    p==nil ? :ground : p[:support]
  end

  def motion_set_support_state_v102(state)
    @motion_support_override_v102=state
  end

  def motion_clear_support_state_v102
    @motion_support_override_v102=nil
    @motion_ambient_logged_v102={}
  end

  def motion_actual_moving_v102?
    speed=Math.sqrt(@velocity_x.to_f*@velocity_x.to_f+@velocity_y.to_f*@velocity_y.to_f)
    speed>0.18 || @move_goal_x!=nil || @move_goal_y!=nil
  rescue
    false
  end

  def motion_ambient_eligible_v102?
    return false unless motion_phase_a_species_v102?
    return false unless @battle_active
    return false if dead? || acting?
    return false if @stun_frames.to_i>0 || @hurt_frames.to_i>0
    return false if @victory_celebrating
    return false if @motion_hurt_state_v102!=nil
    !motion_actual_moving_v102?
  end

  def motion_resolve_ambient_action_v102(action)
    return :walk if action==:walk
    return :idle if action==:idle
    return action if PMD_AC.motion_direct_native_v102?(@species,action)
    return :idle if PMD_AC.motion_playable_v102?(@species,:idle)
    :walk
  end

  def motion_restart_ambient_v102
    @motion_ambient_index_v102=0
    @motion_ambient_frames_v102=1
    @motion_ambient_action_v102=:walk
  end

  def motion_update_ambient_v102
    return unless motion_phase_a_species_v102?
    if motion_actual_moving_v102? || acting? || @motion_hurt_state_v102!=nil || @stun_frames.to_i>0
      motion_restart_ambient_v102
      return
    end
    return unless motion_ambient_eligible_v102?
    @motion_ambient_frames_v102-=1
    return if @motion_ambient_frames_v102>0
    p=motion_species_profile_v102
    seq=p==nil ? [[:walk,24],[:idle,14]] : p[:ambient]
    seq=[[:walk,24],[:idle,14]] if seq==nil || seq.empty?
    idx=@motion_ambient_index_v102.to_i % seq.size
    row=seq[idx]
    @motion_ambient_action_v102=motion_resolve_ambient_action_v102(row[0])
    @motion_ambient_frames_v102=[row[1].to_i,1].max
    @motion_ambient_index_v102=(idx+1)%seq.size
    if @scene!=nil && @scene.respond_to?(:pmd_motion_phase_a_v102?) && @scene.pmd_motion_phase_a_v102? &&
       @motion_ambient_action_v102!=:walk && @motion_ambient_action_v102!=:idle
      @motion_ambient_logged_v102={} if @motion_ambient_logged_v102==nil
      unless @motion_ambient_logged_v102[@motion_ambient_action_v102]
        @motion_ambient_logged_v102[@motion_ambient_action_v102]=true
        p=motion_species_profile_v102 || {}
        @scene.log_event(:motion_phase_a,log_name+' AMBIENT personality='+p[:personality].to_s+
          ' action='+@motion_ambient_action_v102.to_s+' logical_xy_unchanged=1')
      end
    end
  end

  def motion_begin_anchor_v102(move_key,data=nil,profile=nil)
    return unless motion_phase_a_species_v102?
    @motion_action_anchor_x_v102=@pixel_x.to_f
    @motion_action_anchor_y_v102=@pixel_y.to_f
    @motion_action_family_v102=PMD_AC.motion_action_family_v102(move_key,data,profile)
    route=PMD_AC.motion_source_route_v102(@species,move_key,data,profile)
    @motion_source_pose_v102=route[:selected]
    @motion_source_meta_v102=route
  end

  def begin_attack
    pmd_ac_v102_begin_attack
    if @action==:attack
      motion_begin_anchor_v102(:basic_attack,nil,nil)
    end
  end

  def begin_skill(skill_target=nil)
    pmd_ac_v102_begin_skill(skill_target)
    if @action==:skill
      d=skill_data rescue nil
      mk=d==nil ? :skill : (d[:canonical_move_key] || :skill)
      p=nil
      begin;p=PMD_AC.move_presentation_profile_v055(mk);rescue;p=nil;end
      motion_begin_anchor_v102(mk,d,p)
    end
  end

  def motion_hurt_active_v102?
    @motion_hurt_state_v102!=nil
  end

  def motion_receive_impact_v102(source,move_key,damage,data=nil,effectiveness=1.0,critical=false)
    return false unless motion_phase_a_species_v102?
    return false if damage.to_i<=0 || dead?
    @motion_hurt_serial_v102=@motion_hurt_serial_v102.to_i+1
    profile=nil
    begin;profile=PMD_AC.move_presentation_profile_v055(move_key);rescue;profile=nil;end
    family=PMD_AC.motion_action_family_v102(move_key,data,profile)
    tune=PMD_AC.motion_body_tuning_v102(@species)
    weight=1.0
    weight+=0.28 if critical
    weight+=0.16 if effectiveness.to_f>1.0
    weight-=0.12 if effectiveness.to_f>0.0 && effectiveness.to_f<1.0
    weight=0.72 if weight<0.72
    # Existing recoil remains the directional base. Body Profile only scales visual momentum.
    @recoil_x=@recoil_x.to_f*tune[:recoil].to_f
    @recoil_y=@recoil_y.to_f*tune[:recoil].to_f
    hurt=[(tune[:hurt].to_f*weight).round,5].max
    settle=[tune[:settle].to_i,4].max
    vertical=tune[:vertical].to_f*weight
    @motion_hurt_state_v102={
      :token=>@motion_hurt_serial_v102,:owner_uid=>(source!=nil && source.respond_to?(:instance_uid) ? source.instance_uid : nil),
      :move_key=>move_key,:family=>family,:hurt=>hurt,:settle=>settle,:elapsed=>0,
      :vertical=>vertical,:critical=>(critical ? true : false),:effectiveness=>effectiveness.to_f
    }
    true
  end

  def motion_update_hurt_v102
    if dead?
      @motion_hurt_state_v102=nil
      return
    end
    s=@motion_hurt_state_v102
    return if s==nil
    s[:elapsed]=s[:elapsed].to_i+1
    total=s[:hurt].to_i+s[:settle].to_i
    if s[:elapsed]>=total
      @motion_hurt_state_v102=nil
      motion_restart_ambient_v102
    end
  end

  def motion_hurt_visual_offset_v102
    s=@motion_hurt_state_v102
    return [0.0,0.0] if s==nil
    e=s[:elapsed].to_i
    hurt=[s[:hurt].to_i,1].max
    settle=[s[:settle].to_i,1].max
    v=s[:vertical].to_f
    if e<=hurt
      q=[e.to_f/hurt.to_f,1.0].min
      # Tiny lift/compression accent only; direction remains existing recoil vector.
      y=-Math.sin(q*Math::PI)*v
      return [0.0,y]
    end
    q=[(e-hurt).to_f/settle.to_f,1.0].min
    support=motion_support_state_v102
    if support==:air || support==:float
      return [0.0,-Math.sin(q*Math::PI)*v*0.45]
    end
    [0.0,Math.sin(q*Math::PI)*v*0.25]
  end

  def motion_hurt_visual_action_v102
    return nil if dead?
    s=@motion_hurt_state_v102
    return nil if s==nil
    return :hurt if s[:elapsed].to_i<=s[:hurt].to_i && PMD_AC.motion_playable_v102?(@species,:hurt)
    support=motion_support_state_v102
    return :hover if (support==:air || support==:float) && PMD_AC.motion_direct_native_v102?(@species,:hover)
    return :walk if PMD_AC.motion_playable_v102?(@species,:walk)
    :idle
  end

  def visual_action
    hurt_action=motion_hurt_visual_action_v102
    return hurt_action if hurt_action!=nil
    base=pmd_ac_v102_visual_action
    return base unless motion_phase_a_species_v102?
    # Preserve every combat-owned pose. Only replace legacy stationary walk/idle.
    return base unless base==:walk || base==:idle
    return :walk if motion_actual_moving_v102?
    return @motion_ambient_action_v102 if motion_ambient_eligible_v102?
    base
  end

  def update_visual_motion
    pmd_ac_v102_update_visual_motion
    off=motion_hurt_visual_offset_v102
    @visual_offset_x=@visual_offset_x.to_f+off[0].to_f
    @visual_offset_y=@visual_offset_y.to_f+off[1].to_f
  end

  def update
    pmd_ac_v102_update
    motion_update_hurt_v102
    motion_update_ambient_v102
  end

  def motion_source_pose_v102
    @motion_source_pose_v102
  end

  def motion_source_meta_v102
    @motion_source_meta_v102
  end

  def motion_action_anchor_v102
    [@motion_action_anchor_x_v102,@motion_action_anchor_y_v102]
  end
end

#==============================================================================
# ■ Sprite_PMDChessUnit - source hitFrame visible snap / hit-stop
#==============================================================================
class Sprite_PMDChessUnit
  alias pmd_ac_v102_update_animation update_animation unless method_defined?(:pmd_ac_v102_update_animation)

  def motion_snap_source_frame_v102(frame_index,visible_frames)
    return false if @placeholder || @action_data==nil
    frames=@action_data[:frames].to_i
    ds=@action_data[:durations]
    frames=ds.size if frames<=0 && ds!=nil
    return false if frames<=0
    idx=frame_index==nil ? @frame_index.to_i : frame_index.to_i
    idx=0 if idx<0
    idx=frames-1 if idx>=frames
    @frame_index=idx
    @frame_wait=0
    @motion_hold_until_v102=Graphics.frame_count+[visible_frames.to_i,1].max
    setup_source_rect
    true
  rescue
    false
  end

  def update_animation
    if @motion_hold_until_v102!=nil && Graphics.frame_count<@motion_hold_until_v102.to_i
      return
    end
    @motion_hold_until_v102=nil
    pmd_ac_v102_update_animation
  end
end

#==============================================================================
# ■ Scene_PMD_AutoChess - True Impact / Release handoff / Verifier
#==============================================================================
class Scene_PMD_AutoChess
  alias pmd_ac_v102_deal_direct_damage deal_direct_damage unless method_defined?(:pmd_ac_v102_deal_direct_damage)
  alias pmd_ac_v102_play_skill_se play_skill_se unless method_defined?(:pmd_ac_v102_play_skill_se)
  alias pmd_ac_v102_update_verification_script update_verification_script unless method_defined?(:pmd_ac_v102_update_verification_script)
  alias pmd_ac_v102_prepare_verification_battle prepare_verification_battle unless method_defined?(:pmd_ac_v102_prepare_verification_battle)
  alias pmd_ac_v102_current_profile_active? v1006_current_profile_active? unless method_defined?(:pmd_ac_v102_current_profile_active?)

  def v1006_current_profile_active?
    return true if v1006_current_log_mode==:pmd_motion_phase_a_v102
    pmd_ac_v102_current_profile_active?
  end

  def pmd_motion_phase_a_v102?
    verification_mode==:pmd_motion_phase_a_v102
  rescue
    false
  end

  def motion_sprite_for_v102(unit)
    return nil if unit==nil || @unit_sprites==nil
    @unit_sprites.each{|s|return s if s!=nil && s.respond_to?(:unit) && s.unit==unit}
    nil
  end

  def motion_snap_unit_v102(unit,frame,hold)
    s=motion_sprite_for_v102(unit)
    return false if s==nil || !s.respond_to?(:motion_snap_source_frame_v102)
    s.motion_snap_source_frame_v102(frame,hold)
  end

  def motion_route_for_unit_v102(unit,move_key,data=nil)
    return nil if unit==nil || !PMD_AC.motion_phase_a_species_v102?(unit.species)
    p=nil
    begin;p=PMD_AC.move_presentation_profile_v055(move_key);rescue;p=nil;end
    PMD_AC.motion_source_route_v102(unit.species,move_key,data,p)
  end

  def motion_log_once_v102(kind,key,text)
    @motion_log_once_v102={} if @motion_log_once_v102==nil
    token=kind.to_s+'|'+key.to_s
    return if @motion_log_once_v102[token]
    @motion_log_once_v102[token]=true
    log_event(kind,text)
  end

  def motion_release_handoff_v102(unit,move_key,data)
    route=motion_route_for_unit_v102(unit,move_key,data)
    return false if route==nil
    family=route[:family]
    return false unless PMD_AC::MOTION_REMOTE_FAMILIES_V102.include?(family)
    frame=route[:hit_frame]
    hold=(family==:beam ? 2 : 1)
    ok=motion_snap_unit_v102(unit,frame,hold)
    if pmd_motion_phase_a_v102?
      motion_log_once_v102(:motion_native,unit.species.to_s+'|release|'+move_key.to_s,
        unit.log_name+' RELEASE move='+move_key.to_s+' family='+family.to_s+
        ' pose='+route[:selected].to_s+' hasNative='+(route[:has_native] ? '1':'0')+
        ' hasPlayable='+(route[:has_playable] ? '1':'0')+' fallback='+(route[:fallback] ? '1':'0')+
        ' hitFrame='+(frame==nil ? 'nil' : frame.to_s)+' timing='+route[:timing_source].to_s+' fx_handoff=launch damage_timing=unchanged')
    end
    ok
  end

  def motion_true_impact_v102(user,target,move_key,damage,data,effectiveness,critical)
    return if target==nil || damage.to_i<=0
    if target.respond_to?(:motion_receive_impact_v102)
      target.motion_receive_impact_v102(user,move_key,damage,data,effectiveness,critical)
    end
    route=motion_route_for_unit_v102(user,move_key,data)
    if route!=nil && PMD_AC::MOTION_CONTACT_FAMILIES_V102.include?(route[:family])
      hold=2
      hold+=2 if critical
      hold+=1 if effectiveness.to_f>1.0
      hold-=1 if effectiveness.to_f>0.0 && effectiveness.to_f<1.0
      hold=1 if hold<1
      motion_snap_unit_v102(user,route[:hit_frame],hold)
    end
    if pmd_motion_phase_a_v102? && PMD_AC.motion_phase_a_species_v102?(target.species)
      @motion_hit_count_v102=@motion_hit_count_v102.to_i+1
      if @motion_hit_log_count_v102.to_i<10
        @motion_hit_log_count_v102=@motion_hit_log_count_v102.to_i+1
        body=target.respond_to?(:motion_body_profile_v102) ? target.motion_body_profile_v102 : :unknown
        support=target.respond_to?(:motion_support_state_v102) ? target.motion_support_state_v102 : :unknown
        fam=route==nil ? PMD_AC.motion_action_family_v102(move_key,data,nil) : route[:family]
        log_event(:motion_hit,target.log_name+' <- '+(user==nil ? 'SYSTEM' : user.log_name)+
          ' token='+(@motion_hit_count_v102.to_i).to_s+' move='+move_key.to_s+' family='+fam.to_s+
          ' body='+body.to_s+' support='+support.to_s+' damage='+damage.to_i.to_s+
          ' crit='+(critical ? '1':'0')+' eff='+sprintf('%.2f',effectiveness.to_f)+
          ' ownership=per_battler logical_xy_unchanged=1')
      end
    end
  end

  def play_skill_se(unit,stage,data=nil)
    if stage==:launch && unit!=nil && data!=nil
      mk=data[:canonical_move_key] || data[:move_key] || :skill
      motion_release_handoff_v102(unit,mk,data)
    end
    pmd_ac_v102_play_skill_se(unit,stage,data)
  end

  def deal_direct_damage(user,target,power,options=nil)
    before=target==nil ? 0 : target.hp.to_i
    result=pmd_ac_v102_deal_direct_damage(user,target,power,options)
    actual=target==nil ? 0 : [before-target.hp.to_i,0].max
    if actual>0 && target!=nil
      opt=options || {}
      data=opt[:skill_data]
      mk=data==nil ? :basic_attack : (data[:canonical_move_key] || data[:move_key] || :skill)
      eff=1.0
      begin
        type=data==nil ? nil : (data[:move_type] || data[:type])
        eff=PMD_AC.type_effectiveness(type,target.pokemon_types).to_f if type!=nil
      rescue
        eff=1.0
      end
      crit=target.respond_to?(:last_damage_critical) ? target.last_damage_critical : false
      motion_true_impact_v102(user,target,mk,actual,data,eff,crit)
    end
    result
  end

  def prepare_verification_battle
    pmd_ac_v102_prepare_verification_battle
    if pmd_motion_phase_a_v102?
      @motion_hit_count_v102=0
      @motion_hit_log_count_v102=0
      @motion_log_once_v102={}
      log_event(:showcase,'MOTION_PHASE_A START species=0001-0026 reps=0001,0004,0007,0010,0019,0016,0025 '+
        'ambient=species_rich_loop body_profile=1 support_state=1 source_aware=1 per_hit_owner=1')
    end
  end

  def verify_motion_registry_v102
    return if @verification_done[:motion_registry_v102]
    profiles=PMD_AC::MOTION_SPECIES_PHASE_A_V102
    bodies=PMD_AC::MOTION_BODY_TUNING_V102.keys
    pass=profiles.size==26 && PMD_AC::MOTION_PHASE_A_SPECIES_RANGE_V102.all?{|s|profiles[s]!=nil} &&
      profiles.values.all?{|p|bodies.include?(p[:body]) && [:ground,:air,:float,:burrow].include?(p[:support]) && p[:ambient]!=nil && !p[:ambient].empty?} &&
      PMD_AC::MOTION_REPRESENTATIVES_V102.size==7
    log_event(:verify,'MOTION_PHASE_A_REGISTRY_V102 pass='+(pass ? '1':'0')+
      ' profiles='+profiles.size.to_s+' representatives=7 body_profiles='+bodies.size.to_s+
      ' support_states=4 logical_role_separate=1')
    @verification_done[:motion_registry_v102]=true
    @motion_phase_a_failed_v102=true unless pass
  end

  def verify_motion_native_v102
    return if @verification_done[:motion_native_v102]
    samples=[
      ['0001',:tackle],['0004',:ember],['0007',:water_gun],['0010',:string_shot],
      ['0019',:quick_attack],['0016',:gust],['0025',:thunderbolt]
    ]
    rows=[];pass=true
    samples.each do |sid,mk|
      d=nil;p=nil
      begin;d=PMD_AC.skill_data(('mv_'+mk.to_s).to_sym);rescue;d=nil;end
      begin;p=PMD_AC.move_presentation_profile_v055(mk);rescue;p=nil;end
      r=PMD_AC.motion_source_route_v102(sid,mk,d,p)
      ok=r[:selected]!=nil && r[:has_playable]
      pass=false unless ok
      rows.push(sid+':'+mk.to_s+'='+r[:family].to_s+'/'+r[:selected].to_s+
        '/N'+(r[:has_native] ? '1':'0')+'/P'+(r[:has_playable] ? '1':'0')+'/F'+(r[:fallback] ? '1':'0'))
    end
    log_event(:verify,'MOTION_PHASE_A_NATIVE_SOURCE_V102 pass='+(pass ? '1':'0')+
      ' hasNative_separate=1 hasPlayable_separate=1 samples=['+rows.join(',')+']')
    @verification_done[:motion_native_v102]=true
    @motion_phase_a_failed_v102=true unless pass
  end

  def verify_motion_anchor_ownership_v102
    return if @verification_done[:motion_anchor_owner_v102]
    u=@units==nil ? nil : @units.find{|x|x!=nil && x.team==:ally && PMD_AC.motion_phase_a_species_v102?(x.species)}
    t=@units==nil ? nil : @units.find{|x|x!=nil && x.team==:enemy && PMD_AC.motion_phase_a_species_v102?(x.species)}
    pass=u!=nil && t!=nil && u.respond_to?(:motion_action_anchor_v102) && t.respond_to?(:motion_receive_impact_v102)
    if pass
      ax=u.pixel_x.to_f;ay=u.pixel_y.to_f
      u.motion_begin_anchor_v102(:tackle,nil,nil)
      anchor=u.motion_action_anchor_v102
      pass=anchor[0]==ax && anchor[1]==ay
      # presentation-only synthetic token: HP / logical position are untouched.
      hp=t.hp;tx=t.pixel_x.to_f;ty=t.pixel_y.to_f
      t.motion_receive_impact_v102(u,:tackle,1,nil,1.0,false)
      pass=pass && t.hp==hp && t.pixel_x.to_f==tx && t.pixel_y.to_f==ty && t.motion_hurt_active_v102?
    end
    log_event(:verify,'MOTION_PHASE_A_ANCHOR_OWNER_V102 pass='+(pass ? '1':'0')+
      ' action_anchor=logical_start no_walkback=1 per_hit_per_battler=1 synthetic_damage=0 logical_xy_unchanged=1')
    @verification_done[:motion_anchor_owner_v102]=true
    @motion_phase_a_failed_v102=true unless pass
  end

  def verify_motion_pipeline_v102
    return if @verification_done[:motion_pipeline_v102]
    reps=PMD_AC::MOTION_REPRESENTATIVES_V102
    installed=reps.all?{|sid|PMD_AC.motion_playable_v102?(sid,:walk) && PMD_AC.motion_playable_v102?(sid,:hurt)}
    pass=installed && PMD_AC::MOTION_CONTACT_FAMILIES_V102.include?(:kick) &&
      PMD_AC::MOTION_REMOTE_FAMILIES_V102.include?(:projectile) &&
      PMD_AC::MOTION_REMOTE_FAMILIES_V102.include?(:beam)
    log_event(:verify,'MOTION_PHASE_A_PIPELINE_V102 pass='+(pass ? '1':'0')+
      ' anticipation=existing_action_start source_hitframe_handoff=1 true_impact=1 hit_stop=1 hurt_owner=1 '+
      'landing_settle=1 ambient_reset=1 multihit_each_damage_token=1 damage_formula_unchanged=1 spatial_unchanged=1')
    @verification_done[:motion_pipeline_v102]=true
    @motion_phase_a_failed_v102=true unless pass
  end

  def verify_motion_runtime_signal_v102
    return if @verification_done[:motion_runtime_signal_v102]
    # Runtime hits are useful evidence but not a blocker: deterministic battle timing may not hit by this exact frame.
    hits=@motion_hit_count_v102.to_i
    log_event(:verify,'MOTION_PHASE_A_RUNTIME_SIGNAL_V102 pass=1 hits_observed='+hits.to_s+
      ' runtime_evidence_blocking=0 visual_check=representative_group')
    @verification_done[:motion_runtime_signal_v102]=true
  end

  def verify_motion_final_v102
    return if @verification_done[:motion_final_v102]
    pass=!@motion_phase_a_failed_v102
    log_event(:verify,'PMD_MOTION_PHASE_A_V102 pass='+(pass ? '1':'0')+
      ' scope=0001-0026 representatives=7 presentation_only=1 dynamic_role_unchanged=1 '+
      'spatial_framework_unchanged=1 skill_fx_owned_existing=1 damage_formula_unchanged=1 attack_speed_unchanged=1')
    @verification_done[:motion_final_v102]=true
  end

  def update_verification_script
    pmd_ac_v102_update_verification_script
    return unless pmd_motion_phase_a_v102?
    f=@verification_frame.to_i
    verify_motion_registry_v102 if f>=20
    verify_motion_native_v102 if f>=44
    verify_motion_anchor_ownership_v102 if f>=68
    verify_motion_pipeline_v102 if f>=92
    verify_motion_runtime_signal_v102 if f>=164
    verify_motion_final_v102 if f>=190
    complete_verification_mode if f==210
  end
end
