# encoding: UTF-8
#==============================================================================
# 【PMD AutoChess 中文維護說明】
# 腳本：PMD AutoChess Protection / Peel Layer v0.91.3
# 分類：AutoChess Team AI／Ally Distress／Bodyguard Peel／Soft Provoke／Verifier
#
# 【用途】
# 讓隊伍開始具有「互相保護」的自走棋行為。後排／遠程／施法型隊友被攻擊時，
# 會發出 ALLY_DISTRESS；具 Bodyguard / Protective / Tank 傾向的隊友中只選一名
# 最合適者回防。護衛會暫時改保受襲隊友、鎖定攻擊者，並沿用既有 Bodyguard
# 站位邏輯移到「隊友與威脅之間」。
#
# 【主要設定項】
# - PEEL_DURATION_V0913：一次護衛任務維持時間。
# - PEEL_RESPONSE_RANGE_V0913：護衛願意回防的最大距離。
# - PEEL_LOG_COOLDOWN_V0913：同一受害者/攻擊者的 Distress LOG 節流。
# - SOFT_PROVOKE_*：護衛／Tank 對普通敵人的軟性吸引力。
#
# 【機制規則】
# 1. 後排定義：ranged 或 role_tags 含 caster/controller/artillery/support。
# 2. 每次真正 HP Damage 後，若受害者屬後排且來源是敵方 Pokémon Unit，
#    Scene 產生 ALLY_DISTRESS。
# 3. 只有具護衛資格的隊友競爭接手；Bodyguard/Protective 最強，Tank 次之。
# 4. 同一個 Distress 只由一名 Protector 接手，避免全隊一起往後跑。
# 5. Protector 若正在出招，不會中途篡改 Damage Packet；等 Action 結束後再轉火。
# 6. Peel 期間 protected_ally() 暫時改成真正受襲隊友，因此既有 bodyguard movement
#    會站到 Ally 與 Attacker 中間。
# 7. Soft Provoke：Bodyguard/Tank 本身在 Target Utility 有小幅吸引力；
#    正在 Peel 某攻擊者時吸引力更高。
# 8. Assassin / ignore_minor 對 Soft Provoke 只有極低敏感度，仍以切後排為主。
# 9. Hard Provoke 完全沿用既有 apply_taunt / forced_target，優先度高於本系統。
#
# 【可調參數】
# 若護衛太常回頭：降低 PEEL_RESPONSE_RANGE_V0913 或提高 Protector 限制。
# 若坦克太容易搶仇恨：降低 SOFT_PROVOKE_BASE_V0913 / SOFT_PROVOKE_PEEL_V0913。
# 若刺客太容易被坦克拉走：降低 soft_provoke_susceptibility_v0913 的 Assassin 值。
#
# 【事件／腳本呼叫方式】
# Runtime 自動運作。
# 也可由事件／Boss Mechanic 主動發出：
#   scene.emit_ally_distress_v0913(victim, attacker, damage, false, :front)
#
# 【實際範例】
# 敵小拉達切入後排皮卡丘：
#   [ALLY_DISTRESS] ALLY:皮卡丘 attacked_by=ENEMY:小拉達 ...
#   [PEEL] ALLY:傑尼龜 protect=ALLY:皮卡丘 target=ENEMY:小拉達 ...
# 傑尼龜接著會靠近皮卡丘與小拉達之間；一般敵人較可能改打傑尼龜。
# Assassin 仍可能無視 Soft Provoke 繼續追後排。
#
# 【驗證】
# NORMAL 按 S 一次 -> AUTOCHESS_AGGRO_V0913 -> Shift。
# BOSS_FRAMEWORK_V091 會排在下一個模式，可再按一次 S 測 v0.91.1 Hotfix。
#
# 【注意事項】
# - 本系統不改傷害、命中、射程、Projectile、Ranged Stagger、v0.60.2 Multi-hit。
# - 不會把所有寶可夢都變成護衛；反應由 AI Role / Threat Policy 決定。
# - RGSS2 / Ruby 1.8 相容，不使用專案禁用的舊式 instance-variable probe。
#==============================================================================
module PMD_AC
  PATCH_VERSION_V0913='0.91.3'
  PEEL_DURATION_V0913=120
  PEEL_RESPONSE_RANGE_V0913=205.0
  PEEL_LOG_COOLDOWN_V0913=45
  PEEL_CONTACT_RANGE_V0913=84.0
  SOFT_PROVOKE_BASE_V0913=900.0
  SOFT_PROVOKE_TANK_V0913=560.0
  SOFT_PROVOKE_PEEL_V0913=2800.0
  AUTOCHESS_AGGRO_VERIFY_END_V0913=24

  V0913_OLD_VERIFICATION_MODES=VERIFICATION_MODES.dup
  V0913_OLD_VERIFICATION_LABELS=VERIFICATION_LABELS.dup
  remove_const(:VERIFICATION_MODES)
  VERIFICATION_MODES=[:normal,:autochess_aggro_v0913,:boss_framework_v091]+
    V0913_OLD_VERIFICATION_MODES.reject{|x|[:normal,:autochess_aggro_v0913,:boss_framework_v091].include?(x)}
  remove_const(:VERIFICATION_LABELS)
  VERIFICATION_LABELS=V0913_OLD_VERIFICATION_LABELS.dup
  VERIFICATION_LABELS[:normal]='NORMAL'
  VERIFICATION_LABELS[:autochess_aggro_v0913]='AUTOCHESS_AGGRO_V0913'
  VERIFICATION_LABELS[:boss_framework_v091]='BOSS_FRAMEWORK_V091'
end

class Game_PMDChessUnit
  attr_reader :distress_ally_v0913
  attr_reader :distress_attacker_v0913
  attr_reader :distress_frames_v0913

  alias pmd_ac_v0913_initialize initialize unless method_defined?(:pmd_ac_v0913_initialize)
  def initialize(id,key,team,cell_x,cell_y,pokemon_instance=nil)
    pmd_ac_v0913_initialize(id,key,team,cell_x,cell_y,pokemon_instance)
    @distress_ally_v0913=nil
    @distress_attacker_v0913=nil
    @distress_frames_v0913=0
  end

  def backline_priority_v0913?
    return true if ranged?
    tags=role_tags || []
    [:caster,:controller,:artillery,:support].any?{|x|tags.include?(x)}
  end

  def protection_strength_v0913
    return 1.00 if @movement_policy==:bodyguard
    return 0.96 if @threat_policy==:protective
    tags=role_tags || []
    return 0.72 if @role==:tank
    return 0.58 if tags.include?(:tank) && @movement_policy!=:assassin
    return 0.42 if tags.include?(:support) && !ranged? && @movement_policy!=:assassin
    0.0
  end

  def soft_provoke_base_v0913
    return PMD_AC::SOFT_PROVOKE_BASE_V0913 if @movement_policy==:bodyguard || @threat_policy==:protective
    tags=role_tags || []
    return PMD_AC::SOFT_PROVOKE_TANK_V0913 if @role==:tank || (tags.include?(:tank) && @movement_policy!=:assassin)
    0.0
  end

  def soft_provoke_susceptibility_v0913
    return 0.10 if @movement_policy==:assassin
    return 0.15 if @threat_policy==:ignore_minor
    return 0.72 if @threat_policy==:hold_ground
    return 1.08 if @threat_policy==:responsive
    1.0
  end

  def distress_guard_active_v0913?
    return false if @distress_frames_v0913.to_i<=0
    return false if @distress_ally_v0913==nil || @distress_attacker_v0913==nil
    return false if @distress_ally_v0913.dead? || @distress_attacker_v0913.dead?
    return false if @distress_ally_v0913.team!=@team || @distress_attacker_v0913.team==@team
    true
  end

  def protecting_ally_from_v0913?(attacker)
    distress_guard_active_v0913? && @distress_attacker_v0913==attacker
  end

  def accept_distress_guard_v0913(ally,attacker,frames=PMD_AC::PEEL_DURATION_V0913)
    return false if ally==nil || attacker==nil || ally.dead? || attacker.dead?
    return false if ally.team!=@team || attacker.team==@team
    return false if protection_strength_v0913<=0.0
    changed=(@distress_ally_v0913!=ally || @distress_attacker_v0913!=attacker || @distress_frames_v0913.to_i<=0)
    @distress_ally_v0913=ally
    @distress_attacker_v0913=attacker
    @distress_frames_v0913=[frames.to_i,1].max
    if !acting? && !taunted? && @target!=attacker
      old=@target
      if @scene!=nil
        @scene.log_event(:peel,log_name+' protect='+ally.log_name+' target='+attacker.log_name+
          ' old='+(old==nil ? 'NONE' : old.log_name)+' strength='+sprintf('%.2f',protection_strength_v0913)) if changed
      end
      set_target(attacker)
    elsif changed && @scene!=nil
      @scene.log_event(:peel,log_name+' QUEUE protect='+ally.log_name+' target='+attacker.log_name+
        ' acting='+(acting? ? '1':'0')+' strength='+sprintf('%.2f',protection_strength_v0913))
    end
    true
  end

  def clear_distress_guard_v0913(reason=:expire)
    return if @distress_ally_v0913==nil && @distress_attacker_v0913==nil
    old_attacker=@distress_attacker_v0913
    if @scene!=nil
      @scene.log_event(:peel,log_name+' END reason='+reason.to_s+
        ' target='+(old_attacker==nil ? 'NONE' : old_attacker.log_name))
    end
    @distress_ally_v0913=nil
    @distress_attacker_v0913=nil
    @distress_frames_v0913=0
    if @target==old_attacker && !taunted? && !acting?
      set_target(nil)
    end
  end

  alias pmd_ac_v0913_update_threat_timers update_threat_timers unless method_defined?(:pmd_ac_v0913_update_threat_timers)
  def update_threat_timers
    pmd_ac_v0913_update_threat_timers
    if @distress_frames_v0913.to_i>0
      @distress_frames_v0913-=1
      if !distress_guard_active_v0913?
        clear_distress_guard_v0913(:expire)
      end
    end
  end

  alias pmd_ac_v0913_protected_ally protected_ally unless method_defined?(:pmd_ac_v0913_protected_ally)
  def protected_ally
    return @distress_ally_v0913 if distress_guard_active_v0913?
    pmd_ac_v0913_protected_ally
  end

  alias pmd_ac_v0913_update_target_selection update_target_selection unless method_defined?(:pmd_ac_v0913_update_target_selection)
  def update_target_selection
    if distress_guard_active_v0913? && !taunted?
      set_target(@distress_attacker_v0913) if @target!=@distress_attacker_v0913
      return
    end
    pmd_ac_v0913_update_target_selection
  end

  alias pmd_ac_v0913_target_utility target_utility unless method_defined?(:pmd_ac_v0913_target_utility)
  def target_utility(enemy)
    base=pmd_ac_v0913_target_utility(enemy)
    return base if enemy==nil || enemy.dead?
    return base if enemy.respond_to?(:battle_object?) && enemy.battle_object?
    return base unless enemy.is_a?(Game_PMDChessUnit)
    susceptibility=soft_provoke_susceptibility_v0913
    bonus=enemy.soft_provoke_base_v0913.to_f*susceptibility
    if enemy.protecting_ally_from_v0913?(self)
      bonus+=PMD_AC::SOFT_PROVOKE_PEEL_V0913*susceptibility
    end
    base.to_f+bonus
  end

  alias pmd_ac_v0913_receive_damage receive_damage unless method_defined?(:pmd_ac_v0913_receive_damage)
  def receive_damage(value,source=nil,grant_energy=true,bypass_link=false,critical=false)
    before=@hp.to_i
    arc=nil
    if source!=nil && source.is_a?(Game_PMDChessUnit) && source.team!=@team
      begin;arc=incoming_arc_from(source);rescue;arc=nil;end
    end
    result=pmd_ac_v0913_receive_damage(value,source,grant_energy,bypass_link,critical)
    actual=[before-@hp.to_i,0].max
    if actual>0 && grant_energy && @scene!=nil && source!=nil && source.is_a?(Game_PMDChessUnit) && source.team!=@team
      @scene.emit_ally_distress_v0913(self,source,actual,critical,arc)
    end
    result
  end
end

class Scene_PMD_AutoChess
  alias pmd_ac_v0913_start start unless method_defined?(:pmd_ac_v0913_start)
  alias pmd_ac_v0913_prepare_verification_battle prepare_verification_battle unless method_defined?(:pmd_ac_v0913_prepare_verification_battle)
  alias pmd_ac_v0913_update_verification_script update_verification_script unless method_defined?(:pmd_ac_v0913_update_verification_script)
  alias pmd_ac_v0913_log_event log_event unless method_defined?(:pmd_ac_v0913_log_event)
  alias pmd_ac_v0913_refresh_header refresh_header unless method_defined?(:pmd_ac_v0913_refresh_header)

  def start
    pmd_ac_v0913_start
    begin
      if FileTest.exist?(PMD_AC::BATTLE_LOG_FILE)
        text=File.open(PMD_AC::BATTLE_LOG_FILE,'rb'){|f|f.read}
        text.sub!(/PMD AutoChess Proto v0\.[0-9.]+ Battle Verification Log/,
          'PMD AutoChess Proto v0.91.3 Battle Verification Log')
        File.open(PMD_AC::BATTLE_LOG_FILE,'wb'){|f|f.write(text)}
      end
    rescue
    end
    @distress_log_frames_v0913={}
    log_event(:autochess_ai,
      'FLOW v0.91.3 aggro=v0.91.2 ally_distress=1 single_protector=1 bodyguard_peel=1 soft_provoke=1 hard_provoke=v0.15 assassin_resist=1 boss_verifier=v0.91.1')
  end

  def refresh_header
    pmd_ac_v0913_refresh_header
    return if @header_sprite==nil || @header_sprite.bitmap==nil
    bmp=@header_sprite.bitmap
    bmp.fill_rect(0,0,Graphics.width,28,Color.new(0,0,0,180))
    pmd_ac_v074_font(bmp)
    bmp.font.size=PMD_AC::HEADER_TITLE_FONT_V0741
    bmp.font.bold=true
    bmp.font.color=Color.new(255,255,255)
    bmp.draw_text(16,4,Graphics.width-32,24,'PMD 自走棋原型 v0.91.3',1)
  end

  def distress_log_key_v0913(victim,attacker)
    victim.id.to_s+':'+attacker.id.to_s
  end

  def distress_contact_v0913?(victim,attacker)
    return false if victim==nil || attacker==nil
    return true if attacker.respond_to?(:melee?) && attacker.melee?
    attacker.distance_to(victim).to_f<=PMD_AC::PEEL_CONTACT_RANGE_V0913
  end

  def best_protector_v0913(victim,attacker)
    candidates=allies_of(victim).find_all{|u|
      u!=victim && u.alive? && u.protection_strength_v0913>0.0 &&
      u.distance_to(victim).to_f<=PMD_AC::PEEL_RESPONSE_RANGE_V0913
    }
    best=nil;best_score=nil
    candidates.each do |u|
      score=u.protection_strength_v0913*1200.0
      score-=u.distance_to(victim).to_f*2.5
      score-=u.distance_to(attacker).to_f*0.8
      score+=240.0 if u.movement_policy==:bodyguard
      score+=120.0 if u.threat_policy==:protective
      if best==nil || score>best_score
        best=u;best_score=score
      end
    end
    [best,best_score||0.0]
  end

  def emit_ally_distress_v0913(victim,attacker,damage,critical=false,arc=nil)
    return false if victim==nil || attacker==nil || victim.dead? || attacker.dead?
    return false if victim.team==attacker.team || !victim.backline_priority_v0913?
    protector,score=best_protector_v0913(victim,attacker)
    return false if protector==nil
    contact=distress_contact_v0913?(victim,attacker)
    key=distress_log_key_v0913(victim,attacker)
    @distress_log_frames_v0913={} if @distress_log_frames_v0913==nil
    now=Graphics.frame_count
    last=@distress_log_frames_v0913[key]
    if last==nil || now-last.to_i>=PMD_AC::PEEL_LOG_COOLDOWN_V0913
      hp_rate=damage.to_f/[victim.maxhp.to_i,1].max.to_f
      log_event(:ally_distress,victim.log_name+' attacked_by='+attacker.log_name+
        ' damage='+damage.to_i.to_s+' hp_rate='+sprintf('%.3f',hp_rate)+
        ' contact='+(contact ? '1':'0')+' arc='+(arc||:unknown).to_s+
        ' protector='+protector.log_name)
      @distress_log_frames_v0913[key]=now
    end
    protector.accept_distress_guard_v0913(victim,attacker,PMD_AC::PEEL_DURATION_V0913)
  end

  def autochess_aggro_v0913?
    verification_mode==:autochess_aggro_v0913
  end

  def prepare_verification_battle
    pmd_ac_v0913_prepare_verification_battle
    if autochess_aggro_v0913?
      @autochess_aggro_v0913_failed=false
    end
  end

  def log_event(category,message)
    if category.to_s=='verify' && autochess_aggro_v0913? &&
       (message.to_s.index('AGGRO_')==0 || message.to_s.index('PEEL_')==0 || message.to_s.index('AUTOCHESS_')==0) &&
       message.to_s.include?(' pass=0')
      @autochess_aggro_v0913_failed=true
    end
    pmd_ac_v0913_log_event(category,message)
  end

  def log_verify_v0913(name,pass,detail='')
    @autochess_aggro_v0913_failed=true unless pass
    log_event(:verify,name+' pass='+(pass ? '1':'0')+(detail=='' ? '' : ' '+detail))
  end

  def make_ai_test_instance_v0913(species,setup)
    inst=PMD_PokemonInstance.new(species,15)
    inst.apply_ai_setup_hash(setup) if setup!=nil
    inst
  end

  def make_ai_test_unit_v0913(id,species,team,cx,cy,setup=nil)
    u=Game_PMDChessUnit.new(id,species,team,cx,cy,make_ai_test_instance_v0913(species,setup))
    u.scene=self
    u
  end

  def verify_aggro_manifest_v0913
    return if @verification_done[:v0913_manifest]
    pass=PMD_AC::AGGRO_MAX_V0912==100.0 && PMD_AC::PEEL_DURATION_V0913==120 &&
      PMD_AC::PEEL_RESPONSE_RANGE_V0913>=180.0 && PMD_AC::AGGRO_HARMFUL_STATUS_V0912.include?(:fear)
    log_verify_v0913('AUTOCHESS_AGGRO_MANIFEST_V0913',pass,
      'aggro_cap=100 decay='+PMD_AC::AGGRO_DECAY_PER_FRAME_V0912.to_s+
      ' peel=120f response='+PMD_AC::PEEL_RESPONSE_RANGE_V0913.to_i.to_s+'px hard_provoke=legacy')
    @verification_done[:v0913_manifest]=true
  end

  def verify_aggro_accumulation_v0913
    return if @verification_done[:v0913_accum]
    u=make_ai_test_unit_v0913(99301,:charmander,:ally,1,1,
      {:target_policy=>:execute,:movement_policy=>:bruiser,:threat_policy=>:normal,:target_commitment=>60})
    e=make_ai_test_unit_v0913(99302,:pidgey,:enemy,5,1,nil)
    a=u.add_aggro_v0912(e,18,:damage)
    b=u.add_aggro_v0912(e,26,:back_attack)
    before=u.aggro_value_v0912(e)
    10.times{u.update_threat_timers}
    after=u.aggro_value_v0912(e)
    pass=a>=17.9 && b>=43.9 && after<before && after>40.0
    log_verify_v0913('AGGRO_ACCUMULATION_V0912',pass,
      'stack='+sprintf('%.1f',before)+' decay10='+sprintf('%.1f',after)+' cap=100')
    @verification_done[:v0913_accum]=true
  end

  def verify_aggro_role_response_v0913
    return if @verification_done[:v0913_roles]
    bruiser=make_ai_test_unit_v0913(99311,:charmander,:ally,1,1,
      {:movement_policy=>:bruiser,:threat_policy=>:normal})
    assassin=make_ai_test_unit_v0913(99312,:rattata,:ally,1,2,
      {:movement_policy=>:assassin,:threat_policy=>:ignore_minor})
    pass=bruiser.aggro_response_v0912>assassin.aggro_response_v0912 &&
      bruiser.aggro_retarget_threshold_v0912<100.0 && assassin.aggro_retarget_threshold_v0912>=999.0
    log_verify_v0913('AGGRO_ROLE_RESPONSE_V0912',pass,
      'bruiser='+sprintf('%.2f',bruiser.aggro_response_v0912)+
      ' assassin='+sprintf('%.2f',assassin.aggro_response_v0912)+
      ' assassin_threshold='+assassin.aggro_retarget_threshold_v0912.to_i.to_s)
    @verification_done[:v0913_roles]=true
  end

  def verify_aggro_retarget_v0913
    return if @verification_done[:v0913_retarget]
    u=make_ai_test_unit_v0913(99321,:charmander,:ally,1,1,
      {:target_policy=>:execute,:movement_policy=>:bruiser,:threat_policy=>:normal,:target_commitment=>60})
    old=make_ai_test_unit_v0913(99322,:caterpie,:enemy,4,1,nil)
    bully=make_ai_test_unit_v0913(99323,:pidgey,:enemy,4,2,nil)
    u.set_target(old)
    u.add_aggro_v0912(bully,78,:verification)
    combat_ai_with_units_v068([u,old,bully]){u.reevaluate_target}
    pass=u.target==bully
    log_verify_v0913('AGGRO_RETARGET_V0912',pass,
      'execute_target=caterpie bully=pidgey aggro=78 switched='+(pass ? '1':'0'))
    @verification_done[:v0913_retarget]=true
  end

  def verify_peel_selection_v0913
    return if @verification_done[:v0913_peel]
    victim=make_ai_test_unit_v0913(99331,:pikachu,:ally,0,2,
      {:movement_policy=>:controller,:threat_policy=>:responsive})
    guard=make_ai_test_unit_v0913(99332,:squirtle,:ally,1,2,
      {:target_policy=>:protect_ally,:movement_policy=>:bodyguard,:threat_policy=>:protective})
    attacker=make_ai_test_unit_v0913(99333,:rattata,:enemy,2,2,
      {:movement_policy=>:assassin,:threat_policy=>:ignore_minor})
    ok=false
    combat_ai_with_units_v068([victim,guard,attacker]) do
      ok=emit_ally_distress_v0913(victim,attacker,30,false,:back)
      guard.update_target_selection
    end
    pass=ok && guard.distress_guard_active_v0913? && guard.distress_ally_v0913==victim && guard.target==attacker
    log_verify_v0913('PEEL_SELECTION_V0913',pass,
      'victim=pikachu protector=squirtle attacker=rattata single_protector=1 target_lock='+(guard.target==attacker ? '1':'0'))
    @verification_done[:v0913_peel]=true
  end

  def verify_soft_provoke_v0913
    return if @verification_done[:v0913_provoke]
    normal=make_ai_test_unit_v0913(99341,:charmander,:enemy,4,1,
      {:movement_policy=>:bruiser,:threat_policy=>:normal})
    assassin=make_ai_test_unit_v0913(99342,:rattata,:enemy,4,2,
      {:movement_policy=>:assassin,:threat_policy=>:ignore_minor})
    guard=make_ai_test_unit_v0913(99343,:squirtle,:ally,1,1,
      {:movement_policy=>:bodyguard,:threat_policy=>:protective})
    n=guard.soft_provoke_base_v0913*normal.soft_provoke_susceptibility_v0913
    a=guard.soft_provoke_base_v0913*assassin.soft_provoke_susceptibility_v0913
    pass=n>=800.0 && a<n*0.25 && guard.soft_provoke_base_v0913>0.0
    log_verify_v0913('PEEL_SOFT_PROVOKE_V0913',pass,
      'normal_bonus='+n.to_i.to_s+' assassin_bonus='+a.to_i.to_s+' hard_taunt=unchanged')
    @verification_done[:v0913_provoke]=true
  end

  def verify_aggro_carry_v0913
    return if @verification_done[:v0913_carry]
    pass=PMD_AC::RANGED_CONTACT_BASIC_STAGGER_V0883==18 &&
      PMD_AC::STALL_WATCH_FRAMES_V089==540 && PMD_AC::BOSS_FRAMEWORK_MANIFEST_V091[:profiles]>=1
    log_verify_v0913('AUTOCHESS_AGGRO_CARRY_V0913',pass,
      'target_policy=preserved threat=preserved ranged_stagger=v0.88.3 stalemate=v0.89 boss=v0.91 damage_packet=v0.60.2 unchanged')
    @verification_done[:v0913_carry]=true
  end

  def update_verification_script
    unless autochess_aggro_v0913?
      pmd_ac_v0913_update_verification_script
      return
    end
    @verification_frame=@verification_frame.to_i+1
    f=@verification_frame
    verify_aggro_manifest_v0913 if f>=2
    verify_aggro_accumulation_v0913 if f>=4
    verify_aggro_role_response_v0913 if f>=6
    verify_aggro_retarget_v0913 if f>=8
    verify_peel_selection_v0913 if f>=10
    verify_soft_provoke_v0913 if f>=12
    verify_aggro_carry_v0913 if f>=14
    if f>=18 && !@verification_done[:v0913_final]
      pass=!@autochess_aggro_v0913_failed
      log_verify_v0913('AUTOCHESS_AGGRO_V0913',pass,
        'aggro=1 decay=1 role_response=1 retarget=1 distress=1 peel=1 soft_provoke=1 carry=1')
      @verification_done[:v0913_final]=true
    end
    complete_verification_mode if f>=PMD_AC::AUTOCHESS_AGGRO_VERIFY_END_V0913
  end
end
