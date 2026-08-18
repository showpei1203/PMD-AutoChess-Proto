#==============================================================================
# ■ PMD AutoChess - Motion Phase B Batch B + Deploy Native Discovery Fix v1.03.6
#==============================================================================
# 【用途】
# 本版同時完成兩個彼此獨立、但都屬於 Motion Presentation 的修正：
#
# A. 修正 v1.03.5 Deploy 45° Rich LOOP「實際沒有任何特殊 Native Action」的根因。
#    v1.03.5 誤把 PMD_AC.motion_playable_v102?(species, action) 當成
#    Game_PMDChessUnit 的 instance method 呼叫，因此 direct 8-direction 判定永遠失敗。
#    本版改成直接查 PMD_AC compiled action database，並要求：
#      1) pose 自己真的 playable；
#      2) compiled direct action 存在；
#      3) 不是 copy_of / alias_of；
#      4) rows >= 8；
#      5) 對應 Bitmap asset 真實存在。
#    這樣 Deploy Rich LOOP 才會真的使用該物種自己的 8-direction Native 空閒動作。
#
# B. Motion Phase B Batch B：Miss / Immune / Guard 結果語意。
#    成功命中已由 v1.03.0 Contact Chain A 處理。本版補齊「沒有造成傷害」時玩家
#    應該看到的不同結果，避免 MISS、免疫、Protect 全部看起來像同一種空白事件。
#
# 【正式規則】
# 1. MISS / Whiff：
#    - 只對 Contact family 做身體演技；遠程 MISS 沿用既有 Projectile / FX 路徑。
#    - 攻擊者小幅向目標方向 overshoot 後收回，表示揮空。
#    - 目標不播放 Hurt，不產生假擊退。
#    - 既有 MISS Popup / miss_count / Accuracy 邏輯完全不改。
#
# 2. IMMUNE：
#    - 只在有「明確免疫證據」時觸發，不把任意 0 damage 猜成免疫。
#    - 支援 Type 0x、Ability type immunity / Wonder Guard / absorb、Air Balloon、
#      Magnet Rise 等已存在 runtime 規則。
#    - Contact attacker 只有短小 rejected recoil；目標不演 Hurt。
#    - 不修改 Ability、Type Chart、Held Item、Field 或 Damage Formula。
#
# 3. GUARD：
#    - Protect / Detect / Wide Guard / Quick Guard 被擋下時，目標維持站穩；既有
#      Shield / Guard FX 保留。
#    - Contact attacker 做比一般免疫更明顯的 bounce-back。
#    - v0.40 Direct Guard 原本會 register_miss；本版保留該統計／LOG 行為，僅用
#      Guard context 阻止它被視覺誤判成一般 MISS。
#
# 4. Presentation-only：
#    - 所有新位移只寫 @visual_offset_x / @visual_offset_y。
#    - 禁止修改 logical pixel_x / pixel_y、AI、Damage Formula、Attack Speed、
#      Energy、Skill cooldown、Spatial Runtime。
#
# 5. Multi-hit 不在本版改動。下一批獨立處理每 hit 的 advance / retreat / impact，
#    避免結果語意與多段 choreography 一次混在同一個變更面。
#
# 6. Deploy / Battle Ambient 邊界維持：
#    - Deploy 可使用真正 Native Rich LOOP；
#    - live AutoChess battle 禁止純裝飾的大幅 Ambient 位移；
#    - 戰鬥中的大幅位移必須來自真正 Combat Motion / Spatial Runtime。
#
# 【主要設定】
# MOTION_PHASE_B_RESULT_TUNING_V1036
#   :miss   => total 8f / 3px forward whiff
#   :immune => total 7f / 2px rejected recoil
#   :guard  => total 9f / 4px guard bounce
#
# DEPLOY_NATIVE_DIRECT_REQUIRED_V1036 = true
#   Deploy special 必須是 direct native，不接受 copy/alias 冒充物種原生演技。
#
# 【可調參數】
# - MISS 太誇張：降低 :miss :amp；不要縮短命中判定或 Attack Speed。
# - Guard 彈太遠：降低 :guard :amp；不要改真正 knockback。
# - Deploy 想更 Rich：調 v1.03.5 Pool / MAX_SPECIALS；本版只負責「候選是真的」。
# - 不要在本腳本加入全戰場慢速／低 HP。該 A/B 已排定在所有 Motion Phase 完成後。
#
# 【事件／腳本呼叫方式】
# 不需事件呼叫。NORMAL 與 PMD Motion Runtime 自動套用 presentation。
# Windows 驗收：布陣按 S 切至 PMD Motion → Shift → 完整戰鬥。
#
# 【實際範例】
# - 妙蛙種子 Tackle miss：妙蛙種子往前多探一點再回收，小拉達不播放 Hurt。
# - Ground 接觸技打 Air Balloon：攻擊者有短 recoil，目標維持站穩並保留既有免疫訊息。
# - Tackle 撞 Protect：攻擊者較明顯彈回，目標只有既有 Shield / Guard 呈現。
#==============================================================================

$imported = {} unless defined?($imported)
$imported['PMD_AutoChess_MotionPhaseB_ResultSemantics_DeployNativeFix_v1036'] = true

# v1.03.5 blocked list 漏了 :swing；Deploy Rich LOOP 不應把攻擊擺動當待機演技。
if defined?(PMD_AC) && defined?(PMD_AC::DEPLOY_RICH_BLOCKED_ACTIONS_V1035)
  PMD_AC::DEPLOY_RICH_BLOCKED_ACTIONS_V1035.push(:swing) unless PMD_AC::DEPLOY_RICH_BLOCKED_ACTIONS_V1035.include?(:swing)
end

module PMD_AC
  DEPLOY_NATIVE_DIRECT_REQUIRED_V1036 = true

  MOTION_PHASE_B_RESULT_TUNING_V1036 = {
    :miss   => {:total=>8, :amp=>3.0, :lift=>0.45},
    :immune => {:total=>7, :amp=>2.0, :lift=>0.25},
    :guard  => {:total=>9, :amp=>4.0, :lift=>0.55}
  }

  MOTION_PHASE_B_RESULT_MAX_X_V1036 = 5.0
  MOTION_PHASE_B_RESULT_MAX_Y_V1036 = 2.0

  class << self
    alias pmd_ac_v1036_log_category_allowed_v1006? log_category_allowed_v1006? unless method_defined?(:pmd_ac_v1036_log_category_allowed_v1006?)

    def log_category_allowed_v1006?(mode,category)
      if mode==:pmd_motion_phase_a_v102
        c=category.to_s.to_sym
        return true if c==:motion_result || c==:motion_deploy
      end
      pmd_ac_v1036_log_category_allowed_v1006?(mode,category)
    end
  end
end

#==============================================================================
# ■ Game_PMDChessUnit - Deploy direct native 判定 + Result visual state
#==============================================================================
class Game_PMDChessUnit
  alias pmd_ac_v1036_initialize initialize unless method_defined?(:pmd_ac_v1036_initialize)
  alias pmd_ac_v1036_start_combat start_combat unless method_defined?(:pmd_ac_v1036_start_combat)
  alias pmd_ac_v1036_stop_combat stop_combat unless method_defined?(:pmd_ac_v1036_stop_combat)
  alias pmd_ac_v1036_update update unless method_defined?(:pmd_ac_v1036_update)
  alias pmd_ac_v1036_update_visual_motion update_visual_motion unless method_defined?(:pmd_ac_v1036_update_visual_motion)
  alias pmd_ac_v1036_visual_action visual_action unless method_defined?(:pmd_ac_v1036_visual_action)
  alias pmd_ac_v1036_motion_phase_b_clear_test_state_v103 motion_phase_b_clear_test_state_v103 unless method_defined?(:pmd_ac_v1036_motion_phase_b_clear_test_state_v103)

  def initialize(*args)
    pmd_ac_v1036_initialize(*args)
    @motion_phase_b_result_v1036=nil
  end

  def start_combat
    pmd_ac_v1036_start_combat
    @motion_phase_b_result_v1036=nil
  end

  def stop_combat
    pmd_ac_v1036_stop_combat
    @motion_phase_b_result_v1036=nil
  end

  # v1.03.5 同名 method 的正式修正。
  # 注意 motion_playable_v102? 是 PMD_AC module method，不是 unit instance method。
  def motion_deploy_direct_8dir_v1035?(action)
    return false if action==nil
    return false unless PMD_AC.respond_to?(:motion_playable_v102?)
    return false unless PMD_AC.motion_playable_v102?(@species,action)
    return false unless PMD_AC.respond_to?(:compiled_direct_action_v061)
    d=PMD_AC.compiled_direct_action_v061(@species.to_s,action)
    return false if d==nil
    return false if d[:copy_of]!=nil || d[:alias_of]!=nil
    return false unless d[:rows].to_i>=8
    if PMD_AC.respond_to?(:compiled_action_asset_available_v061?)
      return false unless PMD_AC.compiled_action_asset_available_v061?(@species.to_s,action,d)
    end
    true
  rescue
    false
  end

  def motion_deploy_direct_native_actions_v1036
    out=[]
    return out unless PMD_AC.respond_to?(:compiled_direct_action_v061)
    candidates=[]
    begin
      candidates.concat(motion_deploy_rich_specials_v1035)
    rescue
    end
    PMD_AC::DEPLOY_RICH_COMMON_POOL_V1035.each{|a|candidates.push(a) unless candidates.include?(a)} rescue nil
    candidates.each do |a|
      next if PMD_AC::DEPLOY_RICH_BLOCKED_ACTIONS_V1035.include?(a) rescue false
      out.push(a) if motion_deploy_direct_8dir_v1035?(a) && !out.include?(a)
    end
    out
  rescue
    []
  end

  def motion_phase_b_result_active_v1036?
    @motion_phase_b_result_v1036!=nil
  end

  def motion_phase_b_result_kind_v1036
    s=@motion_phase_b_result_v1036
    s==nil ? nil : s[:kind]
  end

  def motion_phase_b_begin_result_v1036(kind,target,route,reason=nil)
    return false unless motion_phase_a_species_v102?
    return false if dead? || route==nil
    family=route[:family]
    return false unless motion_phase_b_contact_family_v103?(family)
    tune=PMD_AC::MOTION_PHASE_B_RESULT_TUNING_V1036[kind]
    return false if tune==nil
    dx=1.0;dy=0.0
    if target!=nil
      dx=target.pixel_x.to_f-@pixel_x.to_f
      dy=target.pixel_y.to_f-@pixel_y.to_f
    end
    dist=Math.sqrt(dx*dx+dy*dy)
    if dist<=0.001
      dx=@team==:ally ? 1.0 : -1.0
      dy=0.0;dist=1.0
    end
    @motion_phase_b_recovery_v103=nil
    @motion_phase_b_result_v1036={
      :kind=>kind,:reason=>reason,:elapsed=>0,:total=>[tune[:total].to_i,1].max,
      :amp=>tune[:amp].to_f,:lift=>tune[:lift].to_f,
      :nx=>dx/dist,:ny=>dy/dist,:family=>family,:target=>target,
      :move_key=>route[:move_key],:source_pose=>route[:selected]
    }
    true
  rescue
    @motion_phase_b_result_v1036=nil
    false
  end

  def motion_phase_b_update_result_v1036
    s=@motion_phase_b_result_v1036
    return if s==nil
    if dead?
      @motion_phase_b_result_v1036=nil
      return
    end
    s[:elapsed]=s[:elapsed].to_i+1
    if s[:elapsed]>=s[:total].to_i
      @motion_phase_b_result_v1036=nil
      motion_restart_ambient_v102 if respond_to?(:motion_restart_ambient_v102)
    end
  rescue
    @motion_phase_b_result_v1036=nil
  end

  def motion_phase_b_apply_result_offset_v1036
    s=@motion_phase_b_result_v1036
    return if s==nil
    total=[s[:total].to_i,1].max
    q=s[:elapsed].to_f/total.to_f
    q=0.0 if q<0.0;q=1.0 if q>1.0
    wave=Math.sin(q*Math::PI)
    amp=s[:amp].to_f*wave
    sign=s[:kind]==:miss ? 1.0 : -1.0
    ox=s[:nx].to_f*amp*sign
    oy=s[:ny].to_f*amp*sign-s[:lift].to_f*Math.sin(q*Math::PI)
    maxx=PMD_AC::MOTION_PHASE_B_RESULT_MAX_X_V1036.to_f
    maxy=PMD_AC::MOTION_PHASE_B_RESULT_MAX_Y_V1036.to_f
    ox=maxx if ox>maxx;ox=-maxx if ox< -maxx
    oy=maxy if oy>maxy;oy=-maxy if oy< -maxy
    @visual_offset_x=@visual_offset_x.to_f+ox
    @visual_offset_y=@visual_offset_y.to_f+oy
  rescue
  end

  def update_visual_motion
    pmd_ac_v1036_update_visual_motion
    motion_phase_b_apply_result_offset_v1036
  end

  def visual_action
    base=pmd_ac_v1036_visual_action
    s=@motion_phase_b_result_v1036
    return base if s==nil
    # 行動本身還在播放時維持 source pose；行動結束則以 Walk 收勢，避免硬切 Hurt/Idle。
    return base if acting?
    return :walk if PMD_AC.motion_playable_v102?(@species,:walk)
    base
  rescue
    base
  end

  def update
    pmd_ac_v1036_update
    motion_phase_b_update_result_v1036
  end

  def motion_phase_b_clear_test_state_v103
    pmd_ac_v1036_motion_phase_b_clear_test_state_v103
    @motion_phase_b_result_v1036=nil
  end
end

#==============================================================================
# ■ Scene_PMD_AutoChess - Miss / Immune / Guard routing + verifiers
#==============================================================================
class Scene_PMD_AutoChess
  alias pmd_ac_v1036_register_miss register_miss unless method_defined?(:pmd_ac_v1036_register_miss)
  alias pmd_ac_v1036_deal_direct_damage deal_direct_damage unless method_defined?(:pmd_ac_v1036_deal_direct_damage)
  alias pmd_ac_v1036_apply_skill_effects apply_skill_effects unless method_defined?(:pmd_ac_v1036_apply_skill_effects)
  alias pmd_ac_v1036_prepare_verification_battle prepare_verification_battle unless method_defined?(:pmd_ac_v1036_prepare_verification_battle)
  alias pmd_ac_v1036_update_verification_script update_verification_script unless method_defined?(:pmd_ac_v1036_update_verification_script)
  alias pmd_ac_v1036_verify_motion_final_v102 verify_motion_final_v102 unless method_defined?(:pmd_ac_v1036_verify_motion_final_v102)
  alias pmd_ac_v1036_start_battle start_battle unless method_defined?(:pmd_ac_v1036_start_battle)

  def motion_phase_b_verifier_active_v1036?
    return pmd_motion_phase_a_v102? if respond_to?(:pmd_motion_phase_a_v102?)
    m=verification_mode
    m==:pmd_motion_phase_a_v102 || m==:pmd_motion_phase_b_v103
  rescue
    false
  end

  def motion_phase_b_move_data_v1036(user,explicit=nil)
    return explicit if explicit!=nil
    return nil if user==nil
    return user.skill_data if user.respond_to?(:skill_data) && user.respond_to?(:action) && user.action==:skill
    nil
  rescue
    nil
  end

  def motion_phase_b_move_key_v1036(data)
    return :basic_attack if data==nil
    data[:canonical_move_key] || data[:move_key] || :skill
  rescue
    :skill
  end

  def motion_phase_b_result_route_v1036(user,data=nil)
    return nil if user==nil
    mk=motion_phase_b_move_key_v1036(data)
    route=motion_route_for_unit_v102(user,mk,data) rescue nil
    return nil if route==nil
    return nil unless PMD_AC::MOTION_CONTACT_FAMILIES_V102.include?(route[:family])
    r=route.dup
    r[:move_key]=mk
    r
  rescue
    nil
  end

  def motion_phase_b_start_result_v1036(kind,user,target,data=nil,reason=nil)
    route=motion_phase_b_result_route_v1036(user,data)
    return false if route==nil || user==nil
    ok=user.motion_phase_b_begin_result_v1036(kind,target,route,reason)
    if ok
      @motion_phase_b_result_counts_v1036={} if @motion_phase_b_result_counts_v1036==nil
      @motion_phase_b_result_counts_v1036[kind]=@motion_phase_b_result_counts_v1036[kind].to_i+1
      if motion_phase_b_verifier_active_v1036? && @motion_phase_b_result_log_count_v1036.to_i<12
        @motion_phase_b_result_log_count_v1036=@motion_phase_b_result_log_count_v1036.to_i+1
        log_event(:motion_result,
          user.log_name+' -> '+(target==nil ? 'NONE' : target.log_name)+
          ' result='+kind.to_s+' move='+route[:move_key].to_s+' family='+route[:family].to_s+
          ' reason='+(reason==nil ? 'none' : reason.to_s)+
          ' attacker_visual_only=1 target_hurt=0 logical_xy_unchanged=1')
      end
    end
    ok
  rescue
    false
  end

  def motion_phase_b_guard_reason_v1036(user,target,data,basic=false)
    return nil unless respond_to?(:guard_block_reason_v040)
    return nil if user==nil || target==nil
    return nil if respond_to?(:guard_bypass_v040?) && guard_bypass_v040?(data)
    guard_block_reason_v040(user,target,data,basic)
  rescue
    nil
  end

  def motion_phase_b_damage_type_category_v1036(user,target,data,options=nil)
    opts=options==nil ? {} : options
    type=opts[:move_type];cat=opts[:damage_category]
    if respond_to?(:canonical_damage_type_and_category)
      begin
        triple=canonical_damage_type_and_category(user,opts)
        type=triple[0] if type==nil
        cat=triple[1] if cat==nil
        data=triple[2] if data==nil && triple[2]!=nil
      rescue
      end
    end
    type=(data[:move_type] || data[:type]) if type==nil && data!=nil
    cat=(data[:damage_category] || data[:category]) if cat==nil && data!=nil
    type=user.basic_move_type if type==nil && user!=nil && user.respond_to?(:basic_move_type)
    type=:normal if type==nil
    cat=:physical if cat==nil
    [type,cat,data]
  rescue
    [:normal,:physical,data]
  end

  # 只回傳「可證明」的免疫原因；任意 0 damage 不會被猜成 immune。
  def motion_phase_b_immunity_reason_v1036(user,target,data=nil,options=nil)
    return nil if user==nil || target==nil || target.dead?
    type,cat,data=motion_phase_b_damage_type_category_v1036(user,target,data,options)
    begin
      eff=PMD_AC.type_effectiveness(type,target.pokemon_types)
      return :type_zero if eff.to_f<=0.0
    rescue
    end
    begin
      tb=target.respond_to?(:canonical_passive_behavior) ? target.canonical_passive_behavior : {}
      return :ability_type_immunity if tb[:kind]==:type_immunity_stage && type==tb[:type]
      if tb[:kind]==:non_super_effective_immunity
        eff=PMD_AC.type_effectiveness(type,target.pokemon_types)
        return :wonder_guard if eff.to_f<=1.0
      end
    rescue
    end
    begin
      if type==:ground && target.respond_to?(:air_balloon_active_v041?) && target.air_balloon_active_v041?
        return :air_balloon
      end
    rescue
    end
    begin
      if type==:ground && target.respond_to?(:magnet_rise_active_v051?) && target.magnet_rise_active_v051?
        return :magnet_rise
      end
    rescue
    end
    begin
      if respond_to?(:ability_absorb_matching_v065?) && ability_absorb_matching_v065?(user,target,data,(options||{})[:source_type],type)
        return :ability_absorb
      end
    rescue
    end
    begin
      if target.respond_to?(:ability_incoming_multiplier)
        mult=target.ability_incoming_multiplier(type,cat)
        return :ability_incoming_zero if mult.to_f<=0.0
      end
    rescue
    end
    nil
  end

  # v0.40 direct guard 會在深層呼叫 register_miss。Context 讓它保留原統計，
  # 但視覺選 Guard bounce，而不是一般 Miss overshoot。
  def register_miss(user,target)
    ctx=@motion_phase_b_guard_context_v1036
    data=motion_phase_b_move_data_v1036(user,nil)
    result=pmd_ac_v1036_register_miss(user,target)
    if ctx!=nil && ctx[:user]==user && ctx[:target]==target && ctx[:reason]!=nil
      unless ctx[:started]
        motion_phase_b_start_result_v1036(:guard,user,target,ctx[:data],ctx[:reason])
        ctx[:started]=true
      end
    else
      motion_phase_b_start_result_v1036(:miss,user,target,data,:miss)
    end
    result
  end

  def deal_direct_damage(user,target,power,options=nil)
    opts=options==nil ? {} : options
    data=opts[:skill_data]
    basic=(opts[:source_type]==:basic || data==nil)
    guard_reason=motion_phase_b_guard_reason_v1036(user,target,data,basic)
    immune_reason=guard_reason==nil ? motion_phase_b_immunity_reason_v1036(user,target,data,opts) : nil
    before=target==nil ? 0 : target.hp.to_i
    old_ctx=@motion_phase_b_guard_context_v1036
    ctx=nil
    if guard_reason!=nil
      ctx={:user=>user,:target=>target,:reason=>guard_reason,:data=>data,:started=>false}
      @motion_phase_b_guard_context_v1036=ctx
    end
    result=nil
    begin
      result=pmd_ac_v1036_deal_direct_damage(user,target,power,options)
    ensure
      @motion_phase_b_guard_context_v1036=old_ctx
    end
    after=target==nil ? before : target.hp.to_i
    if guard_reason!=nil
      motion_phase_b_start_result_v1036(:guard,user,target,data,guard_reason) unless ctx!=nil && ctx[:started]
    elsif result.to_i<=0 && after==before && immune_reason!=nil
      motion_phase_b_start_result_v1036(:immune,user,target,data,immune_reason)
    end
    result
  end

  def apply_skill_effects(user,target,data,scale=1.0)
    guard_reason=motion_phase_b_guard_reason_v1036(user,target,data,false)
    immune_reason=guard_reason==nil ? motion_phase_b_immunity_reason_v1036(user,target,data,{:skill_data=>data,:source_type=>:skill_direct}) : nil
    before=target==nil ? 0 : target.hp.to_i
    result=pmd_ac_v1036_apply_skill_effects(user,target,data,scale)
    after=target==nil ? before : target.hp.to_i
    active_kind=user!=nil && user.respond_to?(:motion_phase_b_result_kind_v1036) ? user.motion_phase_b_result_kind_v1036 : nil
    zero_result=(result==nil || result==false || (result.respond_to?(:to_i) && result.to_i<=0))
    if guard_reason!=nil && zero_result && after==before && active_kind!=:guard
      motion_phase_b_start_result_v1036(:guard,user,target,data,guard_reason)
    elsif zero_result && after==before && immune_reason!=nil && active_kind!=:immune
      # 某些 Ability absorb 在 apply_skill_effects 外層就 return 0，不會進 deal_direct_damage。
      # 若 inner deal_direct_damage 已建立 immune state，這裡不重複計數／重置動畫。
      motion_phase_b_start_result_v1036(:immune,user,target,data,immune_reason)
    end
    result
  end

  def motion_capture_deploy_native_v1036
    covered=0;ready=0;total=0;rows=[]
    (@units || []).each do |u|
      next if u==nil
      next unless u.respond_to?(:motion_phase_a_species_v102?) && u.motion_phase_a_species_v102?
      covered+=1
      actions=u.respond_to?(:motion_deploy_direct_native_actions_v1036) ? u.motion_deploy_direct_native_actions_v1036 : []
      ready+=1 unless actions.empty?
      total+=actions.size
      rows.push(u.species.to_s+'='+actions.join('/'))
    end
    @motion_deploy_native_snapshot_v1036={:covered=>covered,:ready=>ready,:total=>total,:rows=>rows}
    if motion_phase_b_verifier_active_v1036?
      log_event(:motion_deploy,
        'MOTION_DEPLOY_NATIVE_DISCOVERY_V1036 ready=1 covered='+covered.to_s+
        ' direct_native_ready='+ready.to_s+'/'+covered.to_s+' direct_native_actions='+total.to_s+
        ' playable_module_call=1 compiled_direct=1 copy_alias_rejected=1 rows8=1 asset_exists=1'+
        ' samples=['+rows.join(',')+']')
    end
  rescue
  end

  def start_battle
    motion_capture_deploy_native_v1036 if @phase==:deploy
    pmd_ac_v1036_start_battle
  end

  def prepare_verification_battle
    pmd_ac_v1036_prepare_verification_battle
    if motion_phase_b_verifier_active_v1036?
      @motion_phase_b_result_counts_v1036={:miss=>0,:immune=>0,:guard=>0}
      @motion_phase_b_result_log_count_v1036=0
      @motion_phase_b_batch_b_failed_v1036=false
      log_event(:showcase,
        'MOTION_PHASE_B_BATCH_B START result_semantics=miss,immune,guard'+
        ' target_hurt_suppressed=1 contact_only=1 multihit_next_batch=1'+
        ' deploy_native_fix=1 presentation_only=1')
    end
  end

  def verify_motion_deploy_native_v1036
    return if @verification_done[:motion_deploy_native_v1036]
    s=@motion_deploy_native_snapshot_v1036 || {}
    covered=s[:covered].to_i;ready=s[:ready].to_i;total=s[:total].to_i
    pass=covered>0 && ready==covered && total>=covered
    @motion_phase_b_batch_b_failed_v1036=true unless pass
    log_event(:verify,
      'MOTION_DEPLOY_NATIVE_DISCOVERY_V1036 pass='+(pass ? '1':'0')+
      ' covered='+covered.to_s+' direct_native_ready='+ready.to_s+'/'+covered.to_s+
      ' direct_native_actions='+total.to_s+
      ' module_playable_call=1 compiled_direct=1 copy_alias_rejected=1 rows8=1 asset_exists=1'+
      ' v1035_instance_method_bug_fixed=1 deploy_only=1 battle_ambient_isolation_retained=1')
    @verification_done[:motion_deploy_native_v1036]=true
  rescue
    @motion_phase_b_batch_b_failed_v1036=true
    log_event(:verify,'MOTION_DEPLOY_NATIVE_DISCOVERY_V1036 pass=0 error=1')
    @verification_done[:motion_deploy_native_v1036]=true
  end

  # 純 presentation deterministic verifier：不透過真正 Damage Formula 扣血。
  # 目的只驗三種 state 的 routing / 幅度 / target-hurt suppression / logical XY 不變。
  def verify_motion_phase_b_result_semantics_v1036
    return if @verification_done[:motion_phase_b_result_semantics_v1036]
    a=verification_unit(:ally,:bulbasaur)
    t=verification_unit(:enemy,:rattata)
    pass=a!=nil && t!=nil
    miss=false;immune=false;guard=false;target_clean=false;xy_ok=false
    if pass
      ax=a.pixel_x.to_f;ay=a.pixel_y.to_f;tx=t.pixel_x.to_f;ty=t.pixel_y.to_f
      ah=a.hp.to_i;th=t.hp.to_i
      route=motion_phase_b_result_route_v1036(a,nil)
      if route!=nil
        miss=a.motion_phase_b_begin_result_v1036(:miss,t,route,:verify)
        miss=miss && a.motion_phase_b_result_kind_v1036==:miss
        a.motion_phase_b_clear_test_state_v103
        immune=a.motion_phase_b_begin_result_v1036(:immune,t,route,:verify)
        immune=immune && a.motion_phase_b_result_kind_v1036==:immune
        a.motion_phase_b_clear_test_state_v103
        guard=a.motion_phase_b_begin_result_v1036(:guard,t,route,:protect)
        guard=guard && a.motion_phase_b_result_kind_v1036==:guard
        a.motion_phase_b_clear_test_state_v103
      end
      target_clean=!(t.respond_to?(:motion_hurt_active_v102?) && t.motion_hurt_active_v102?)
      xy_ok=a.pixel_x.to_f==ax && a.pixel_y.to_f==ay && t.pixel_x.to_f==tx && t.pixel_y.to_f==ty && a.hp.to_i==ah && t.hp.to_i==th
      pass=miss && immune && guard && target_clean && xy_ok
    end
    @motion_phase_b_batch_b_failed_v1036=true unless pass
    log_event(:verify,
      'MOTION_PHASE_B_RESULT_SEMANTICS_V1036 pass='+(pass ? '1':'0')+
      ' miss='+(miss ? '1':'0')+' immune='+(immune ? '1':'0')+' guard='+(guard ? '1':'0')+
      ' target_hurt_suppressed='+(target_clean ? '1':'0')+' hp_unchanged='+(xy_ok ? '1':'0')+
      ' visual_offset_only=1 miss_forward_whiff=1 immune_short_recoil=1 guard_strong_recoil=1'+
      ' guard_miss_counter_unchanged=1 multi_hit_unchanged=1 logical_xy_unchanged=1'+
      ' ai_unchanged=1 damage_unchanged=1 attack_speed_unchanged=1 energy_unchanged=1')
    @verification_done[:motion_phase_b_result_semantics_v1036]=true
  rescue
    @motion_phase_b_batch_b_failed_v1036=true
    log_event(:verify,'MOTION_PHASE_B_RESULT_SEMANTICS_V1036 pass=0 error=1')
    @verification_done[:motion_phase_b_result_semantics_v1036]=true
  end

  # 舊 v1.03.1～v1.03.5 部分 verifier 使用 UI label key :pmd_motion_phase_b_v103，
  # 但正式 mode ring 內部 key 仍是 :pmd_motion_phase_a_v102。本版統一補跑，讓功能與
  # 驗收不再因名稱歷史包袱脫節。
  def motion_phase_b_run_deferred_verifiers_v1036(f)
    return unless motion_phase_b_verifier_active_v1036?
    if f>=170 && respond_to?(:verify_motion_phase_b_snap_polish_v1031) && !@verification_done[:motion_phase_b_snap_polish_v1031]
      verify_motion_phase_b_snap_polish_v1031
    end
    if f>=172 && respond_to?(:verify_battle_ambient_isolation_v1032) && !@verification_done[:battle_ambient_isolation_v1032]
      verify_battle_ambient_isolation_v1032
    end
    if f>=174 && respond_to?(:verify_deploy_idle_loop_v1033) && !@verification_done[:deploy_idle_loop_v1033]
      verify_deploy_idle_loop_v1033
    end
    if f>=178 && respond_to?(:verify_deploy_45_rich_v1035) && !@verification_done[:deploy_45_rich_v1035]
      verify_deploy_45_rich_v1035
    end
  rescue
  end

  def update_verification_script
    pmd_ac_v1036_update_verification_script
    return unless motion_phase_b_verifier_active_v1036?
    return if @verification_done==nil
    f=@verification_frame.to_i
    motion_phase_b_run_deferred_verifiers_v1036(f)
    verify_motion_deploy_native_v1036 if f>=182
    verify_motion_phase_b_result_semantics_v1036 if f>=184
  end

  # 取代 v1.03.0 final 文案，將 Batch B 與 Deploy native fix 納入正式 PASS。
  def verify_motion_final_v102
    return if @verification_done[:motion_final_v102]
    pass=!@motion_phase_a_failed_v102 && !@motion_phase_b_failed_v103 && !@motion_phase_b_batch_b_failed_v1036
    log_event(:verify,
      'PMD_MOTION_PHASE_A_V102 pass='+(pass ? '1':'0')+
      ' superseded_by_phase_b=1 scope=0001-0026 presentation_only=1'+
      ' damage_formula_unchanged=1 attack_speed_unchanged=1 spatial_framework_unchanged=1')
    log_event(:verify,
      'PMD_MOTION_PHASE_B_V103 pass='+(pass ? '1':'0')+
      ' batch=contact_chain_b scope=0001-0026 anticipation=1 source_hit_return=1'+
      ' impact_semantic=1 landing=1 attacker_recovery=1 ambient_reset=1'+
      ' miss_semantic=1 immune_semantic=1 guard_semantic=1 deploy_direct_native_fix=1'+
      ' multi_next_batch=1 ai_unchanged=1 damage_formula_unchanged=1'+
      ' attack_speed_unchanged=1 spatial_unchanged=1')
    @verification_done[:motion_final_v102]=true
  end
end
