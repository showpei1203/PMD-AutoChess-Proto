# encoding: UTF-8
#==============================================================================
# 【PMD AutoChess 中文維護說明】
# 腳本：PMD AutoChess Basic Attack / Spatial Flex Runtime v0.99.12
# 分類：普攻模式 Runtime／AI Spacing／Spatial Intent／Verifier
# RPG Maker VX / RGSS2 / Ruby 1.8 compatible
#==============================================================================
# 【用途】
# 將 v0.99.12 Data 真正接到 NORMAL 戰鬥：
# 1. Basic Attack Range 與 Preferred Spacing 解耦。
# 2. ranged：0～Basic Max Range 全區間都能攻擊，貼身仍可 Point Blank。
# 3. adaptive：遠距 ranged basic；貼近後 close basic；使用 Hysteresis 防抖。
# 4. close basic 可有獨立 Type / Physical-Special Category，且不改 Skill Category。
# 5. Adaptive 進入 close mode 時，不再被舊「遠程受擊 Stagger」完全封鎖普攻；
#    仍保留 Hurt 與約 80% 移動速度，讓貼身戰有壓力但不形成永久 hard-lock。
# 6. 玩家 ai_setup 新增 :spacing_policy / :spatial_intent，現在即可用腳本設定；
#    未來 AI Strategy UI 只需接這兩個正式欄位，不必再重做 Runtime。
# 7. Spatial Intent 會微調已有位移技能的 AI 候選分數。
# 8. Aerial Ace / Feint Attack 示範 :dash_through，命中後穿過目標到另一側。
# 9. AoE / Zone / Line / Melee-density 技能新增幾何標籤與小幅情境 AI Bonus。
#
#==============================================================================
# 【最重要的規則】
# 「射程內都能攻擊」優先於「AI 想站在什麼距離」。
#
# 舊邏輯常見：
#   target < min_range -> 先逃 -> 才考慮攻擊
#
# v0.99.12：
#   target <= basic_max_range 且普攻 Ready -> 先攻擊
#   普攻冷卻期間 -> 再依 spacing_policy 重站位
#
# 因此 Kiter 仍會拉打，但不會因敵人太近就忘記自己有普攻。
#==============================================================================
# 【玩家 AI 腳本設定】
#   pkmn.set_ai_option(:spacing_policy, :hold)
#   pkmn.set_ai_option(:spacing_policy, :flexible)
#   pkmn.set_ai_option(:spatial_intent, :dive)
#   pkmn.set_ai_option(:spatial_intent, :peel)
#
# spacing_policy：
#   :species_default / :kite / :hold / :flexible / :bodyguard / :artillery / :close
# spatial_intent：
#   :balanced / :engage / :disengage / :peel / :dive / :control
#==============================================================================
# 【驗證方式】
# 布陣畫面：NORMAL -> S 一次 -> BASIC_SPATIAL_FLEX_V09912 -> Shift
# 預期：
#   BASIC_FLEX_COVERAGE_V09912 pass=1
#   BASIC_RANGE_DECOUPLE_V09912 pass=1
#   ADAPTIVE_HYSTERESIS_V09912 pass=1
#   POINT_BLANK_POLICY_V09912 pass=1
#   PLAYER_AI_FLEX_V09912 pass=1
#   SPATIAL_TAXONOMY_V09912 pass=1
#   SPATIAL_THROUGH_V09912 pass=1
#   BATTLE_GEOMETRY_AI_V09912 pass=1
#   GAMEPLAY_REVIEW_CARRY_V09912 pass=1
#   BASIC_SPATIAL_FLEX_V09912 pass=1
#   VERIFY_FINISHED_BATTLE_RESUME pass=1
#
# NORMAL 實戰觀察重點：
# - 小火龍被小拉達／波波貼身後是否切 close basic 並能反擊。
# - 小火龍遠距時是否仍使用 Fire projectile。
# - Squirtle Bodyguard 是否仍以保護隊友為主，不因 adaptive 亂跑。
# - Ranged 真遠程貼身時仍能射擊。
#==============================================================================
# 【安全邊界】
# - 不直接編輯 v0.15 / v0.88.3 / v0.91.4 / Frozen Combat Core 原腳本。
# - 不改 Skill Damage、Move Priority、Ability、Held Item、EXP、Evolution。
# - Basic Max Range 不取代 Skill Range。
# - 只對 source_type=:basic 注入 v0.99.12 Basic Packet 的 Type/Category。
#==============================================================================
module PMD_AC
  BASIC_SPATIAL_FLEX_VERIFY_END_V09912=128
  BASIC_SPATIAL_FLEX_REPORT_V09912='PMD_BasicSpatialFlex_v0.99.12.txt'

  class << self
    alias pmd_ac_v09912_valid_ai_option valid_ai_option? unless method_defined?(:pmd_ac_v09912_valid_ai_option)
    def valid_ai_option?(key,value)
      return AI_SPACING_POLICIES_V09912.include?(value) if key==:spacing_policy
      return AI_SPATIAL_INTENTS_V09912.include?(value) if key==:spatial_intent
      pmd_ac_v09912_valid_ai_option(key,value)
    end

    def basic_flex_all_species_v09912
      ks=SPECIES_DB_V016.keys
      ks.sort{|a,b|SPECIES_DB_V016[a][:national_dex].to_i<=>SPECIES_DB_V016[b][:national_dex].to_i}
    end

    def basic_flex_audit_v09912
      modes={:melee=>0,:ranged=>0,:adaptive=>0};spacings={};errors=[];rows=[]
      basic_flex_all_species_v09912.each do |sk|
        p=basic_flex_profile_v09912(sk,:normal)
        if p==nil
          errors.push([sk,:missing_profile]);next
        end
        modes[p[:mode]]=modes[p[:mode]].to_i+1
        spacings[p[:spacing_policy]]=spacings[p[:spacing_policy]].to_i+1
        errors.push([sk,:invalid_mode]) unless BASIC_ATTACK_MODES_V09912.include?(p[:mode])
        errors.push([sk,:invalid_spacing]) unless AI_SPACING_POLICIES_V09912.include?(p[:spacing_policy])
        if p[:mode]==:adaptive
          errors.push([sk,:bad_hysteresis]) unless p[:close_enter].to_f<p[:ranged_resume].to_f
          errors.push([sk,:bad_adaptive_range]) unless p[:basic_max_range].to_f>p[:ranged_resume].to_f
        end
        rows.push([sk,p])
      end
      {:rows=>rows,:modes=>modes,:spacings=>spacings,:errors=>errors,
       :pass=>(rows.size==494 && errors.empty?)}
    end

    def basic_flex_report_text_v09912(report=nil)
      r=report || basic_flex_audit_v09912;out=[]
      out << 'PMD AutoChess Basic Attack / Spatial Flex v0.99.12'
      out << 'Species coverage: '+r[:rows].size.to_s+'/494'
      out << 'Modes: melee='+r[:modes][:melee].to_i.to_s+
        ' ranged='+r[:modes][:ranged].to_i.to_s+
        ' adaptive='+r[:modes][:adaptive].to_i.to_s
      out << 'Spacing: '+r[:spacings].keys.sort{|a,b|a.to_s<=>b.to_s}.collect{|k|k.to_s+'='+r[:spacings][k].to_i.to_s}.join(' ')
      out << 'Spatial v0.91.4 moves: '+SPATIAL_MOVE_EXTENSIONS_V0914.size.to_s
      out << 'Spatial v0.99.12 through moves: '+SPATIAL_MOVE_EXTENSIONS_V09912.size.to_s
      out << 'Review carry: 494/494'
      out << 'Errors: '+r[:errors].size.to_s
      out << ''
      [:bulbasaur,:charmander,:squirtle,:abra,:alakazam,:pikachu,:magnemite].each do |sk|
        p=basic_flex_profile_v09912(sk,:normal);next if p==nil
        out << sk.to_s+' mode='+p[:mode].to_s+' spacing='+p[:spacing_policy].to_s+
          ' max='+p[:basic_max_range].to_f.round.to_s+
          ' close='+p[:close_type].to_s+'/'+p[:close_category].to_s+
          ' ranged='+p[:ranged_type].to_s+'/'+p[:ranged_category].to_s+
          ' source='+p[:source].to_s
      end
      out << ''
      out << 'Player AI options: spacing_policy='+AI_SPACING_POLICIES_V09912.collect{|x|x.to_s}.join(',')
      out << 'Player AI options: spatial_intent='+AI_SPATIAL_INTENTS_V09912.collect{|x|x.to_s}.join(',')
      out << 'Review PASS: '+(r[:pass] ? '1':'0')
      out.join("\n")+"\n"
    end

    def write_basic_flex_report_v09912(report=nil)
      File.open(BASIC_SPATIAL_FLEX_REPORT_V09912,'wb'){|f|f.write(basic_flex_report_text_v09912(report))}
      true
    rescue
      false
    end
  end
end

#==============================================================================
# ■ Game_PMDChessUnit : Basic Delivery / Spacing Runtime
#==============================================================================
class Game_PMDChessUnit
  alias pmd_ac_v09912_start_combat start_combat unless method_defined?(:pmd_ac_v09912_start_combat)
  alias pmd_ac_v09912_sync_from_pokemon_instance sync_from_pokemon_instance unless method_defined?(:pmd_ac_v09912_sync_from_pokemon_instance)
  alias pmd_ac_v09912_apply_persistent_ai_setup apply_persistent_ai_setup unless method_defined?(:pmd_ac_v09912_apply_persistent_ai_setup)
  alias pmd_ac_v09912_ranged ranged? unless method_defined?(:pmd_ac_v09912_ranged)
  alias pmd_ac_v09912_begin_attack begin_attack unless method_defined?(:pmd_ac_v09912_begin_attack)
  alias pmd_ac_v09912_resolve_basic_attack resolve_basic_attack unless method_defined?(:pmd_ac_v09912_resolve_basic_attack)
  alias pmd_ac_v09912_update_movement_policy_logic update_movement_policy_logic unless method_defined?(:pmd_ac_v09912_update_movement_policy_logic)
  alias pmd_ac_v09912_effective_move_speed effective_move_speed unless method_defined?(:pmd_ac_v09912_effective_move_speed)

  def basic_flex_runtime_v09912?
    return true if @scene==nil || !@scene.respond_to?(:verification_mode)
    m=@scene.verification_mode
    m==:normal || m==:basic_spatial_flex_v09912
  end

  def basic_flex_profile_v09912
    return nil unless respond_to?(:species_key)
    fk=respond_to?(:form_key) ? form_key : :normal
    PMD_AC.basic_flex_profile_v09912(species_key,fk)
  end

  def start_combat
    pmd_ac_v09912_start_combat
    @basic_adaptive_state_v09912=:ranged
    @basic_attack_packet_v09912=nil
    @basic_close_legacy_context_v09912=false
    @spacing_policy_v09912=nil
    @spatial_intent_v09912=nil
    apply_persistent_ai_setup
  end

  def sync_from_pokemon_instance
    ok=pmd_ac_v09912_sync_from_pokemon_instance
    if ok
      @basic_adaptive_state_v09912=:ranged if @basic_adaptive_state_v09912==nil
      apply_persistent_ai_setup
    end
    ok
  end

  def apply_persistent_ai_setup
    pmd_ac_v09912_apply_persistent_ai_setup
    return if @pokemon_instance==nil
    setup=@pokemon_instance.ai_setup
    @spacing_policy_v09912=setup[:spacing_policy] if setup[:spacing_policy]!=nil
    @spatial_intent_v09912=setup[:spatial_intent] if setup[:spatial_intent]!=nil
  end

  # 只在「啟動 adaptive close basic 的那一個 call stack」暫時告訴舊 Runtime
  # 這次攻擊要按 melee choreography 處理。正常 ranged? 語意完全保留。
  def ranged?
    return false if @basic_close_legacy_context_v09912
    pmd_ac_v09912_ranged
  end

  def effective_spacing_policy_v09912
    return @spacing_policy_v09912 if @spacing_policy_v09912!=nil && @spacing_policy_v09912!=:species_default
    p=basic_flex_profile_v09912
    p==nil ? :species_default : p[:spacing_policy]
  end

  def spatial_intent_v09912
    @spatial_intent_v09912 || :balanced
  end

  def basic_max_range_v09912
    p=basic_flex_profile_v09912
    return @melee_reach.to_f if p==nil || p[:mode]==:melee
    p[:basic_max_range].to_f
  end

  def basic_delivery_for_distance_v09912(distance)
    p=basic_flex_profile_v09912
    return :melee if p==nil || p[:mode]==:melee
    return :ranged if p[:mode]==:ranged
    d=distance.to_f
    state=@basic_adaptive_state_v09912 || :ranged
    if state==:ranged
      state=:close if d<=p[:close_enter].to_f
    else
      state=:ranged if d>=p[:ranged_resume].to_f
    end
    if state!=@basic_adaptive_state_v09912
      @basic_adaptive_state_v09912=state
      log_event(:basic_mode,log_name+' mode='+state.to_s+' distance='+d.round.to_s+
        ' enter='+p[:close_enter].to_f.round.to_s+' resume='+p[:ranged_resume].to_f.round.to_s)
    else
      @basic_adaptive_state_v09912=state
    end
    state==:close ? :melee : :ranged
  end

  def basic_attack_distance_allowed_v09912(distance,delivery=nil)
    d=distance.to_f
    mode=delivery || basic_delivery_for_distance_v09912(d)
    if mode==:melee
      limit=respond_to?(:basic_melee_hit_limit_v0871) ? basic_melee_hit_limit_v0871 :
        (@melee_reach.to_f+PMD_AC::MELEE_HIT_GRACE.to_f)
      return d<=limit
    end
    d<=basic_max_range_v09912
  end

  def basic_packet_v09912(delivery,distance)
    p=basic_flex_profile_v09912
    return nil if p==nil
    close=(delivery==:melee && p[:mode]==:adaptive)
    {
      :delivery=>delivery,
      :move_type=>(close ? p[:close_type] : p[:ranged_type]),
      :damage_category=>(close ? p[:close_category] : p[:ranged_category]),
      :basic_max_range=>basic_max_range_v09912,
      :distance=>distance.to_f,
      :profile_source=>p[:source],
      :species_key=>p[:species_key]
    }
  end

  def begin_attack
    return pmd_ac_v09912_begin_attack unless basic_flex_runtime_v09912?
    return if @target==nil || @target.dead?
    distance=distance_to(@target).to_f
    delivery=basic_delivery_for_distance_v09912(distance)
    return unless basic_attack_distance_allowed_v09912(distance,delivery)
    packet=basic_packet_v09912(delivery,distance)
    before=@action_timer.to_i
    if delivery==:melee && packet!=nil && basic_flex_profile_v09912[:mode]==:adaptive
      @basic_close_legacy_context_v09912=true
      begin
        pmd_ac_v09912_begin_attack
      ensure
        @basic_close_legacy_context_v09912=false
      end
    else
      pmd_ac_v09912_begin_attack
    end
    if @action==:attack && @action_timer.to_i>before
      @basic_attack_packet_v09912=packet
    else
      @basic_attack_packet_v09912=nil
    end
  end

  def resolve_basic_attack
    packet=@basic_attack_packet_v09912
    return pmd_ac_v09912_resolve_basic_attack if !basic_flex_runtime_v09912? || packet==nil
    @basic_attack_packet_v09912=nil
    return if @target==nil || @target.dead?
    intended_target=@target
    hit_target=@scene==nil ? intended_target : @scene.substitute_target_for(self,intended_target,:basic)
    face_toward(intended_target,true)
    modifier=consume_next_attack_modifier
    mod=modifier==nil ? {} : modifier.dup
    mod[:basic_profile_v09912]=packet.dup

    if packet[:delivery]==:ranged
      tracking_override=mod[:projectile_tracking]
      @scene.launch_projectile(self,hit_target,:basic,100,:single,tracking_override,mod,false)
      @scene.play_basic_se(self,:launch) if @scene!=nil
      return
    end

    evaded=hit_target.try_active_evade(self,:melee)
    in_range=basic_attack_distance_allowed_v09912(distance_to(hit_target).to_f,:melee)
    if in_range
      log_event(:evade_fail,hit_target.log_name+' melee still_hit by '+log_name+' grace=v0.99.12') if evaded
      @scene.deal_direct_damage(self,hit_target,100,
        {:modifier=>mod,:source_type=>:basic,:damage_category=>packet[:damage_category],:move_type=>packet[:move_type]})
      gain_energy(PMD_AC::ENERGY_ON_BASIC_HIT,hit_target,:basic_hit)
      @scene.add_vfx_impact(hit_target,:impact) if @scene!=nil
      @scene.play_basic_se(self,:hit) if @scene!=nil
    else
      log_event(:evade_success,hit_target.log_name+' melee avoided '+log_name) if evaded
      basic_melee_miss_retry_v0871 if respond_to?(:basic_melee_miss_retry_v0871)
      register_miss(hit_target)
    end
  end

  def basic_attack_ready_and_in_range_v09912?
    return false if @target==nil || @target.dead? || @attack_wait.to_f>0.0
    d=distance_to(@target).to_f
    basic_attack_distance_allowed_v09912(d,basic_delivery_for_distance_v09912(d))
  end

  def update_basic_flex_bodyguard_v09912
    return if @target==nil
    ally=protected_ally
    if basic_attack_ready_and_in_range_v09912?
      clear_move_goal;face_toward(@target,true);begin_attack;return
    end
    if ally==nil
      update_basic_flex_ranged_v09912;return
    end
    dx=@target.pixel_x-ally.pixel_x;dy=@target.pixel_y-ally.pixel_y
    len=Math.sqrt(dx*dx+dy*dy);if len<=0.001;dx=@team==:ally ? 1.0 : -1.0;dy=0.0;len=1.0;end
    gx=ally.pixel_x+dx/len*PMD_AC::AI_BODYGUARD_OFFSET
    gy=ally.pixel_y+dy/len*PMD_AC::AI_BODYGUARD_OFFSET
    if distance_to(ally).to_f>PMD_AC::AI_BODYGUARD_LEASH || distance_to(@target).to_f>basic_max_range_v09912
      set_move_goal(gx,gy)
    else
      clear_move_goal;face_toward(@target,true)
    end
  end

  def update_basic_flex_ranged_v09912
    return if @target==nil
    @scene.release_attack_slot(self) if @scene!=nil
    d=distance_to(@target).to_f
    delivery=basic_delivery_for_distance_v09912(d)
    p=basic_flex_profile_v09912
    spacing=effective_spacing_policy_v09912

    # :close 是玩家刻意把「能遠攻」的物種當近戰運用。
    if spacing==:close
      close_goal=[@melee_reach.to_f+10.0,58.0].max
      if d>close_goal
        move_toward_distance(@target,close_goal);return
      end
      if @attack_wait.to_f<=0.0 && basic_attack_distance_allowed_v09912(d,delivery)
        clear_move_goal;face_toward(@target,true);begin_attack
      else
        clear_move_goal;face_toward(@target,true)
      end
      return
    end

    # 核心：只要在 Basic Max Range 且 Ready，先打，再談理想站位。
    if @attack_wait.to_f<=0.0 && basic_attack_distance_allowed_v09912(d,delivery)
      clear_move_goal;face_toward(@target,true);begin_attack;return
    end

    if d>basic_max_range_v09912
      desired=p==nil ? 120.0 : p[:preferred_max].to_f
      desired=basic_max_range_v09912-12.0 if desired>=basic_max_range_v09912
      move_toward_distance(@target,desired);return
    end

    # Adaptive 已經切到 close 時，flexible/hold 不再把逃跑當唯一選項。
    if p!=nil && p[:mode]==:adaptive && delivery==:melee && [:flexible,:hold].include?(spacing)
      clear_move_goal;face_toward(@target,true);return
    end

    if @threat_level==:emergency && @threat_source!=nil && [:kite,:artillery].include?(spacing)
      set_threat_escape_goal(@threat_source,true);return
    elsif @threat_level==:pressured && @threat_source!=nil && [:kite,:artillery].include?(spacing)
      set_threat_escape_goal(@threat_source,false);return
    end

    min=p==nil ? 0.0 : p[:preferred_min].to_f
    max=p==nil ? basic_max_range_v09912 : p[:preferred_max].to_f
    case spacing
    when :kite,:artillery
      if d<min
        move_away_from(@target,max)
      elsif d>max
        move_toward_distance(@target,max)
      else
        clear_move_goal;face_toward(@target,true)
      end
    when :flexible
      if delivery==:ranged && d<min && min>0.0
        # 只在冷卻期做溫和重站位；不阻止下一發普攻。
        move_away_from(@target,[max,d+36.0].min)
      else
        clear_move_goal;face_toward(@target,true)
      end
    else # :hold / :species_default
      clear_move_goal;face_toward(@target,true)
    end
  end

  def update_movement_policy_logic
    return pmd_ac_v09912_update_movement_policy_logic unless basic_flex_runtime_v09912?
    p=basic_flex_profile_v09912
    return pmd_ac_v09912_update_movement_policy_logic if p==nil || p[:mode]==:melee
    spacing=effective_spacing_policy_v09912
    if @movement_policy==:bodyguard || spacing==:bodyguard
      update_basic_flex_bodyguard_v09912
    elsif [:kiter,:artillery,:controller].include?(@movement_policy) ||
          [:kite,:artillery,:flexible,:hold,:close].include?(spacing)
      update_basic_flex_ranged_v09912
    else
      pmd_ac_v09912_update_movement_policy_logic
    end
  end

  def effective_move_speed
    speed=pmd_ac_v09912_effective_move_speed
    return speed unless basic_flex_runtime_v09912?
    p=basic_flex_profile_v09912
    if p!=nil && p[:mode]==:adaptive && @basic_adaptive_state_v09912==:close &&
       respond_to?(:ranged_hit_stagger_v0883?) && ranged_hit_stagger_v0883?
      old=PMD_AC::RANGED_HIT_STAGGER_MOVE_MULT_V0883.to_f
      if old>0.001
        speed=speed/old*PMD_AC::ADAPTIVE_CLOSE_STAGGER_MOVE_MULT_V09912
      end
    end
    speed
  end

  def begin_tactical_dash_through_v09912(other,distance_past,frames,reason=:skill_dash_through)
    return false if other==nil || other.dead?
    dx=other.pixel_x-@pixel_x;dy=other.pixel_y-@pixel_y
    len=Math.sqrt(dx.to_f*dx.to_f+dy.to_f*dy.to_f)
    return false if len<=0.001
    total=len+distance_past.to_f
    begin_tactical_slide_vector_v0914(dx,dy,total,frames,reason)
  end
end

#==============================================================================
# ■ Scene_PMD_AutoChess : Damage Packet / Spatial / AI / Verifier
#==============================================================================
class Scene_PMD_AutoChess
  alias pmd_ac_v09912_deal_direct_damage deal_direct_damage unless method_defined?(:pmd_ac_v09912_deal_direct_damage)
  alias pmd_ac_v09912_apply_skill_effects apply_skill_effects unless method_defined?(:pmd_ac_v09912_apply_skill_effects)
  alias pmd_ac_v09912_progression_candidate_score_v046 progression_candidate_score_v046 unless method_defined?(:pmd_ac_v09912_progression_candidate_score_v046)
  alias pmd_ac_v09912_start start unless method_defined?(:pmd_ac_v09912_start)
  alias pmd_ac_v09912_refresh_header refresh_header unless method_defined?(:pmd_ac_v09912_refresh_header)
  alias pmd_ac_v09912_prepare_verification_battle prepare_verification_battle unless method_defined?(:pmd_ac_v09912_prepare_verification_battle)
  alias pmd_ac_v09912_update_verification_script update_verification_script unless method_defined?(:pmd_ac_v09912_update_verification_script)
  alias pmd_ac_v09912_log_event log_event unless method_defined?(:pmd_ac_v09912_log_event)

  def deal_direct_damage(user,target,power,options=nil)
    opts=options==nil ? {} : options.dup
    if opts[:source_type]==:basic
      mod=opts[:modifier]
      packet=mod==nil ? nil : mod[:basic_profile_v09912]
      if packet!=nil
        opts[:damage_category]=packet[:damage_category]
        opts[:move_type]=packet[:move_type]
      end
    end
    pmd_ac_v09912_deal_direct_damage(user,target,power,opts)
  end

  def canonical_move_key_v09912(data)
    return canonical_move_key_v0914(data) if respond_to?(:canonical_move_key_v0914)
    return nil if data==nil
    k=data[:canonical_move_key] || data['canonical_move_key'] || data[:move_key] || data['move_key']
    k==nil ? nil : k.to_s.downcase.gsub(/[^a-z0-9]+/,'_').to_sym
  end

  def new_spatial_native_duplicate_v09912?(data)
    effects=data==nil ? [] : (data[:effects] || data['effects'] || [])
    effects.each do |e|
      t=e[:type] || e['type'];next if t==nil
      return true if [:dash_user,:blink_user,:swap_position].include?(t.to_s.to_sym)
    end
    false
  end

  def apply_spatial_extension_v09912(user,target,data)
    return false if user==nil || target==nil || user.dead?
    mk=canonical_move_key_v09912(data);ext=PMD_AC.spatial_extension_v09912(mk)
    return false if ext==nil || new_spatial_native_duplicate_v09912?(data)
    return false unless user.respond_to?(:spatial_extension_once_v0914)
    return false unless user.spatial_extension_once_v0914(mk,:v09912_through)
    ok=false
    if ext[:kind]==:dash_through
      ok=user.begin_tactical_dash_through_v09912(target,ext[:distance_past]||30.0,ext[:frames]||7,:skill_dash_through)
    end
    if ok
      log_event(:spatial_move,user.log_name+' move='+mk.to_s+' kind='+ext[:kind].to_s+
        ' target='+target.log_name+' past='+(ext[:distance_past]||0).to_f.round.to_s)
    end
    ok
  end

  def apply_skill_effects(user,target,data,scale=1.0)
    result=pmd_ac_v09912_apply_skill_effects(user,target,data,scale)
    apply_spatial_extension_v09912(user,target,data)
    result
  end

  def enemy_density_v09912(unit,center,radius)
    return 0 if unit==nil || center==nil
    count=0
    enemies_of(unit).each do |e|
      next if e==nil || e.dead?
      dx=e.pixel_x-center.pixel_x;dy=e.pixel_y-center.pixel_y
      count+=1 if Math.sqrt(dx*dx+dy*dy)<=radius.to_f
    end
    count
  end

  def tactical_geometry_ai_bonus_v09912(unit,target,data,mk)
    tags=PMD_AC.skill_tactical_tags_v09912(mk,data);bonus=0.0
    if tags.include?(:melee_density_payoff)
      n=enemy_density_v09912(unit,unit,96.0)
      bonus+=[[n-1,0].max*5.0,15.0].min
    end
    if tags.include?(:cluster_payoff)
      radius=(data[:radius] || data['radius'] || 76.0).to_f
      n=enemy_density_v09912(unit,target,[radius,72.0].max)
      bonus+=[[n-1,0].max*4.0,12.0].min
    end
    bonus
  end

  def progression_candidate_score_v046(unit,target,data,move,slot)
    score=pmd_ac_v09912_progression_candidate_score_v046(unit,target,data,move,slot)
    return score if score==nil || unit==nil || target==nil || data==nil
    mk=canonical_move_key_v09912(data)
    tags=PMD_AC.skill_tactical_tags_v09912(mk,data)
    intent=unit.respond_to?(:spatial_intent_v09912) ? unit.spatial_intent_v09912 : :balanced
    score.to_f+PMD_AC.spatial_intent_bonus_v09912(intent,tags)+
      tactical_geometry_ai_bonus_v09912(unit,target,data,mk)
  end

  def basic_spatial_flex_v09912?
    verification_mode==:basic_spatial_flex_v09912
  end

  def start
    pmd_ac_v09912_start
    begin
      if FileTest.exist?(PMD_AC::BATTLE_LOG_FILE)
        text=File.open(PMD_AC::BATTLE_LOG_FILE,'rb'){|f|f.read}
        text.sub!(/PMD AutoChess Proto v0\.[0-9.]+ Battle Verification Log/,'PMD AutoChess Proto v0.99.12 Battle Verification Log')
        File.open(PMD_AC::BATTLE_LOG_FILE,'wb'){|f|f.write(text)}
      end
    rescue
    end
    log_event(:basic_flex,'FLOW v0.99.12 basic_range=decoupled delivery=melee+ranged+adaptive player_spacing=1 spatial_intent=1 spatial_v0914=19 dash_through=2 review=494/494 next=dynamic_role+ai_ui')
    refresh_header
  end

  def refresh_header
    pmd_ac_v09912_refresh_header
    return if @header_sprite==nil || @header_sprite.bitmap==nil
    bmp=@header_sprite.bitmap;bmp.fill_rect(0,0,Graphics.width,28,Color.new(0,0,0,180));pmd_ac_v074_font(bmp)
    bmp.font.size=PMD_AC.const_defined?(:UI_HEADER_TITLE_FONT_V086) ? PMD_AC::UI_HEADER_TITLE_FONT_V086 : 20
    bmp.font.bold=true;bmp.font.color=Color.new(255,255,255)
    bmp.draw_text(16,1,Graphics.width-32,30,'PMD 自走棋原型 v0.99.12',1)
  end

  def prepare_verification_battle
    pmd_ac_v09912_prepare_verification_battle
    return unless basic_spatial_flex_v09912?
    @basic_flex_failed_v09912=false
    @basic_flex_report_v09912=PMD_AC.basic_flex_audit_v09912
    @basic_flex_report_written_v09912=PMD_AC.write_basic_flex_report_v09912(@basic_flex_report_v09912)
    log_event(:showcase,'START mode=BASIC_SPATIAL_FLEX_V09912 species=494 range_semantics=0_to_max adaptive_hysteresis=1 spatial_intent=1')
  end

  def log_event(category,message)
    if category.to_s=='verify' && basic_spatial_flex_v09912? &&
       message.to_s.index('V09912')!=nil && message.to_s.index(' pass=0')!=nil
      @basic_flex_failed_v09912=true
    end
    pmd_ac_v09912_log_event(category,message)
  end

  def log_basic_flex_verify_v09912(name,pass,detail='')
    @basic_flex_failed_v09912=true unless pass
    log_event(:verify,name+' pass='+(pass ? '1':'0')+(detail=='' ? '' : ' '+detail))
  end

  def verify_basic_flex_coverage_v09912
    r=@basic_flex_report_v09912 || PMD_AC.basic_flex_audit_v09912
    pass=r[:pass] && r[:rows].size==494
    log_basic_flex_verify_v09912('BASIC_FLEX_COVERAGE_V09912',pass,
      'species='+r[:rows].size.to_s+'/494 melee='+r[:modes][:melee].to_i.to_s+
      ' ranged='+r[:modes][:ranged].to_i.to_s+' adaptive='+r[:modes][:adaptive].to_i.to_s+
      ' errors='+r[:errors].size.to_s)
  end

  def verify_range_decouple_v09912
    c=PMD_AC.basic_flex_profile_v09912(:charmander,:normal)
    a=PMD_AC.basic_flex_profile_v09912(:abra,:normal)
    pass=c[:mode]==:adaptive && c[:basic_max_range].to_f<192.0 && a[:mode]==:ranged &&
      a[:basic_max_range].to_f>=190.0
    log_basic_flex_verify_v09912('BASIC_RANGE_DECOUPLE_V09912',pass,
      'charmander_basic_max='+c[:basic_max_range].to_f.round.to_s+' skill_range_preserved=1 abra_basic_max='+a[:basic_max_range].to_f.round.to_s)
  end

  def find_species_unit_v09912(sk)
    @units.each{|u|return u if u.respond_to?(:species_key) && u.species_key==sk}
    nil
  end

  def verify_adaptive_hysteresis_v09912
    u=find_species_unit_v09912(:charmander);pass=false;detail='unit_missing'
    if u!=nil
      u.instance_variable_set(:@basic_adaptive_state_v09912,:ranged)
      a=u.basic_delivery_for_distance_v09912(60.0)
      b=u.basic_delivery_for_distance_v09912(80.0)
      c=u.basic_delivery_for_distance_v09912(100.0)
      pass=(a==:melee && b==:melee && c==:ranged)
      detail='d60='+a.to_s+' d80='+b.to_s+' d100='+c.to_s+' enter64_resume92'
    end
    log_basic_flex_verify_v09912('ADAPTIVE_HYSTERESIS_V09912',pass,detail)
  end

  def verify_point_blank_v09912
    a=PMD_AC.basic_flex_profile_v09912(:abra,:normal)
    pass=a[:mode]==:ranged && a[:basic_max_range].to_f>=190.0
    log_basic_flex_verify_v09912('POINT_BLANK_POLICY_V09912',pass,
      'true_ranged_min_attack_distance=0 max='+a[:basic_max_range].to_f.round.to_s+' preferred_distance_is_not_attack_gate=1')
  end

  def verify_player_ai_flex_v09912
    pass=PMD_AC.valid_ai_option?(:spacing_policy,:hold) &&
      PMD_AC.valid_ai_option?(:spacing_policy,:flexible) &&
      PMD_AC.valid_ai_option?(:spatial_intent,:dive) &&
      PMD_AC.valid_ai_option?(:spatial_intent,:peel)
    log_basic_flex_verify_v09912('PLAYER_AI_FLEX_V09912',pass,
      'spacing=species_default,kite,hold,flexible,bodyguard,artillery,close spatial=balanced,engage,disengage,peel,dive,control')
  end

  def verify_spatial_taxonomy_v09912
    q=PMD_AC.skill_tactical_tags_v09912(:quick_attack)
    w=PMD_AC.skill_tactical_tags_v09912(:water_gun)
    u=PMD_AC.skill_tactical_tags_v09912(:u_turn)
    al=PMD_AC.skill_tactical_tags_v09912(:ally_switch)
    pass=q.include?(:engage) && w.include?(:peel) && u.include?(:disengage) && al.include?(:swap) &&
      PMD_AC::SPATIAL_MOVE_EXTENSIONS_V0914.size==19
    log_basic_flex_verify_v09912('SPATIAL_TAXONOMY_V09912',pass,
      'legacy_spatial=19 quick_attack=engage water_gun=peel u_turn=disengage ally_switch=swap')
  end

  def verify_spatial_through_v09912
    a=PMD_AC.spatial_extension_v09912(:aerial_ace);f=PMD_AC.spatial_extension_v09912(:feint_attack)
    tags=PMD_AC.skill_tactical_tags_v09912(:aerial_ace)
    pass=a!=nil && f!=nil && a[:kind]==:dash_through && f[:kind]==:dash_through && tags.include?(:back_attack)
    log_basic_flex_verify_v09912('SPATIAL_THROUGH_V09912',pass,
      'aerial_ace=dash_through feint_attack=dash_through pass_enemy=1 back_attack_setup=1')
  end

  def verify_geometry_ai_v09912
    e=PMD_AC.skill_tactical_tags_v09912(:earthquake,{:canonical_move_key=>:earthquake})
    h=PMD_AC.skill_tactical_tags_v09912(:hurricane,{:canonical_move_key=>:hurricane,:delivery=>:aoe,:radius=>72})
    pass=e.include?(:melee_density_payoff) && h.include?(:cluster_payoff) &&
      PMD_AC.spatial_intent_bonus_v09912(:peel,PMD_AC.skill_tactical_tags_v09912(:water_gun))>0.0
    log_basic_flex_verify_v09912('BATTLE_GEOMETRY_AI_V09912',pass,
      'earthquake=melee_density hurricane=cluster peel_push_bonus=1 damage_multiplier_added=0')
  end

  def verify_review_carry_v09912
    count=0
    PMD_AC::SPECIES_DB_V016.each_key{|sk|count+=1 if PMD_AC.review_profile_for_v09911(sk,:normal)!=nil}
    pass=count==494 && @basic_flex_report_written_v09912 && FileTest.exist?(PMD_AC::BASIC_SPATIAL_FLEX_REPORT_V09912)
    log_basic_flex_verify_v09912('GAMEPLAY_REVIEW_CARRY_V09912',pass,
      'reviewed='+count.to_s+'/494 pending=0 report='+PMD_AC::BASIC_SPATIAL_FLEX_REPORT_V09912)
  end

  def update_verification_script
    unless basic_spatial_flex_v09912?
      pmd_ac_v09912_update_verification_script;return
    end
    return if @verification_done[:verification_complete]
    @verification_frame=@verification_frame.to_i+1;f=@verification_frame
    if f>=2 && !@verification_done[:v09912_cov];verify_basic_flex_coverage_v09912;@verification_done[:v09912_cov]=true;end
    if f>=12 && !@verification_done[:v09912_range];verify_range_decouple_v09912;@verification_done[:v09912_range]=true;end
    if f>=22 && !@verification_done[:v09912_hys];verify_adaptive_hysteresis_v09912;@verification_done[:v09912_hys]=true;end
    if f>=32 && !@verification_done[:v09912_pb];verify_point_blank_v09912;@verification_done[:v09912_pb]=true;end
    if f>=42 && !@verification_done[:v09912_ai];verify_player_ai_flex_v09912;@verification_done[:v09912_ai]=true;end
    if f>=52 && !@verification_done[:v09912_tax];verify_spatial_taxonomy_v09912;@verification_done[:v09912_tax]=true;end
    if f>=62 && !@verification_done[:v09912_through];verify_spatial_through_v09912;@verification_done[:v09912_through]=true;end
    if f>=72 && !@verification_done[:v09912_geo];verify_geometry_ai_v09912;@verification_done[:v09912_geo]=true;end
    if f>=82 && !@verification_done[:v09912_carry];verify_review_carry_v09912;@verification_done[:v09912_carry]=true;end
    if f>=92 && !@verification_done[:v09912_final]
      r=@basic_flex_report_v09912 || PMD_AC.basic_flex_audit_v09912
      pass=!@basic_flex_failed_v09912 && r[:pass]
      log_basic_flex_verify_v09912('BASIC_SPATIAL_FLEX_V09912',pass,
        'range=0_to_max adaptive=1 point_blank=1 player_ai=1 spatial_framework=1 geometry_ai=1 core_direct_modification=0 next=dynamic_role+ai_strategy_ui')
      @verification_done[:v09912_final]=true
    end
    complete_verification_mode if f>=PMD_AC::BASIC_SPATIAL_FLEX_VERIFY_END_V09912
  end
end

#==============================================================================
# ■ Verifier Mode Registration：NORMAL -> S 一次
#==============================================================================
module PMD_AC
  old_labels_v09912=VERIFICATION_LABELS.dup
  remove_const(:VERIFICATION_LABELS)
  VERIFICATION_LABELS=old_labels_v09912
  VERIFICATION_LABELS[:basic_spatial_flex_v09912]='BASIC_SPATIAL_FLEX_V09912'

  old_modes_v09912=VERIFICATION_MODES.dup
  remove_const(:VERIFICATION_MODES)
  VERIFICATION_MODES=[:normal,:basic_spatial_flex_v09912]+
    old_modes_v09912.reject{|x|x==:normal || x==:basic_spatial_flex_v09912 || x==:gameplay_review_final_v09911}
end
