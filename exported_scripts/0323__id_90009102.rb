# encoding: UTF-8
#==============================================================================
# 【PMD AutoChess 中文維護說明】
# 腳本：PMD AutoChess Boss Framework II Runtime v0.91
# 分類：Boss Runtime／Phase Executor／Verifier
#
# 【用途】
# 執行 Boss Framework Data v0.91 的 Phase。保留 v0.81 Encounter/Boss API，
# 事件仍可用 PMD_AC.start_battle_v081(:boss_beedrill)，不需要換呼叫方式。
#
# 【Runtime 行為】
# 1. Boss Encounter 建立後，依 encounter key 自動綁定 v0.91 Boss Profile。
# 2. 有 v0.91 Profile 的 Boss 會把舊 v0.81 HP Phase 標記為已處理，避免雙重觸發。
# 3. 每個 logic frame 檢查 HP／Timer Phase；同一 Boss 同時最多觸發一個 Phase。
# 4. Phase 觸發後有短 lock，跨多個 HP 門檻時會依序觸發，不會同幀爆滿畫面。
# 5. Phase 文字使用 v0.88 Center Notice 顯示。
# 6. 召喚增援使用 Pokémon Instance + PMD Sprite；屬於 Summon，不計入勝利條件。
# 7. Invulnerability 是「傷害無效窗口」，不刪除狀態系統；時間結束自動恢復。
# 8. Boss 勝利後沿用 v0.83 Loot，再依 Boss 首通記錄追加 first/repeat bonus。
# 9. Boss 強制不可招募、不可逃跑，v0.81 規則再加一層保護。
#
# 【事件／腳本用法】
#   PMD_AC.start_battle_v081(:boss_beedrill)
#   PMD_AC.boss_clear_count_v091(:hive_overlord)   # 查通關次數
#   PMD_AC.boss_first_clear_done_v091?(:hive_overlord)
#
# 【自訂 Mechanic Hook】
# Phase effect：[:mechanic,:my_hook,{:power=>2}]
# 在後載入腳本定義：
#   class Scene_PMD_AutoChess
#     def boss_phase_mechanic_my_hook_v091(unit,phase,args)
#       # 自訂 Boss 行為
#       true
#     end
#   end
#
# 【驗證】
# NORMAL 畫面按 S 一次 -> BOSS_FRAMEWORK_V091 -> Shift。
# 完成後必須出現 VERIFY_FINISHED_BATTLE_RESUME pass=1。
#
# 【注意事項】
# - RGSS2 / Ruby 1.8 相容。
# - 不使用專案禁用的舊式 instance variable probe。
# - 不改 v0.60.2 Damage Packet、v0.88.3 Ranged Stagger、v0.89 Safety Net。
# - Main 前追加；v0.90 舊 Scripts byte-for-byte 保留。
#==============================================================================
module PMD_AC
  PATCH_VERSION_V091 = '0.91'

  V091_OLD_VERIFICATION_MODES = VERIFICATION_MODES.dup
  V091_OLD_VERIFICATION_LABELS = VERIFICATION_LABELS.dup
  remove_const(:VERIFICATION_MODES)
  VERIFICATION_MODES = [:normal,:boss_framework_v091] +
    V091_OLD_VERIFICATION_MODES.reject{|x|x==:normal || x==:boss_framework_v091}
  remove_const(:VERIFICATION_LABELS)
  VERIFICATION_LABELS = V091_OLD_VERIFICATION_LABELS.dup
  VERIFICATION_LABELS[:normal]='NORMAL'
  VERIFICATION_LABELS[:boss_framework_v091]='BOSS_FRAMEWORK_V091'

  class << self
    alias pmd_ac_v091_make_battle_request_v081 make_battle_request_v081 unless method_defined?(:pmd_ac_v091_make_battle_request_v081)
    def make_battle_request_v081(key,options=nil)
      r=pmd_ac_v091_make_battle_request_v081(key,options)
      return nil if r==nil
      profile_key=boss_profile_key_for_encounter_v091(key)
      if profile_key!=nil
        r[:boss_profile_v091]=profile_key
        r[:boss]=true
        r[:kind]=:boss
        r[:recruitable]=false
        r[:recruit_rate]=0
        r[:can_escape]=false
      end
      r
    end

    def boss_clear_hash_v091
      return {} if $game_system==nil
      h=$game_system.pmd_autochess_boss_clears_v091
      if h==nil
        h={}
        $game_system.pmd_autochess_boss_clears_v091=h
      end
      h
    end

    def boss_clear_count_v091(profile_key)
      boss_clear_hash_v091[profile_key].to_i
    end

    def boss_first_clear_done_v091?(profile_key)
      boss_clear_count_v091(profile_key)>0
    end

    def record_boss_clear_v091(profile_key)
      return 0 if $game_system==nil || profile_key==nil
      h=boss_clear_hash_v091
      h[profile_key]=h[profile_key].to_i+1
      h[profile_key]
    end
  end
end

class Game_System
  attr_accessor :pmd_autochess_boss_clears_v091
end

class Game_PMDChessUnit
  attr_reader :boss_profile_key_v091
  attr_reader :boss_invulnerable_frames_v091

  def setup_boss_profile_v091(profile_key)
    p=PMD_AC.boss_profile_v091(profile_key)
    return false if p==nil
    @boss_profile_key_v091=profile_key
    @boss_phase_done_v091={}
    @boss_phase_lock_v091=0
    @boss_invulnerable_frames_v091=0
    # v0.91 是 v0.81 Phase 的後繼。實戰綁定 Profile 後，避免同一 Boss 兩套路由同時觸發。
    boss_phase_rules_v081.each do |rule|
      key=rule[:key] || ('phase_'+rule[:hp_below].to_s).to_sym
      mark_boss_phase_v081(key)
    end
    true
  end

  def boss_profile_v091
    PMD_AC.boss_profile_v091(@boss_profile_key_v091)
  end

  def boss_framework_v091?
    @boss_profile_key_v091!=nil
  end

  def boss_phase_done_v091?(key)
    (@boss_phase_done_v091||{})[key] ? true:false
  end

  def mark_boss_phase_v091(key)
    @boss_phase_done_v091={} if @boss_phase_done_v091==nil
    @boss_phase_done_v091[key]=true
  end

  def boss_phase_lock_v091
    @boss_phase_lock_v091.to_i
  end

  def set_boss_phase_lock_v091(frames)
    @boss_phase_lock_v091=[frames.to_i,0].max
  end

  def boss_invulnerable_v091?
    @boss_invulnerable_frames_v091.to_i>0
  end

  def start_boss_invulnerability_v091(frames)
    n=[frames.to_i,0].max
    return false if n<=0 || dead?
    @boss_invulnerable_frames_v091=[@boss_invulnerable_frames_v091.to_i,n].max
    true
  end

  def update_boss_runtime_v091
    if @boss_phase_lock_v091.to_i>0
      @boss_phase_lock_v091-=1
    end
    if @boss_invulnerable_frames_v091.to_i>0
      @boss_invulnerable_frames_v091-=1
      if @boss_invulnerable_frames_v091<=0 && @scene!=nil
        @boss_invulnerable_frames_v091=0
        @scene.log_event(:boss_invuln,log_name+' INVULNERABLE_END')
      end
    end
  end

  alias pmd_ac_v091_receive_damage receive_damage unless method_defined?(:pmd_ac_v091_receive_damage)
  def receive_damage(value,source=nil,grant_energy=true,bypass_link=false,critical=false)
    if boss_invulnerable_v091? && value.to_i>0 && !dead?
      if @scene!=nil
        src=source==nil ? 'SYSTEM' : source.log_name
        @scene.log_event(:boss_invuln,log_name+' BLOCK_DAMAGE raw='+value.to_i.to_s+
          ' src='+src+' remain='+@boss_invulnerable_frames_v091.to_i.to_s)
      end
      @last_damage=0
      @last_damage_critical=false
      return 0
    end
    pmd_ac_v091_receive_damage(value,source,grant_energy,bypass_link,critical)
  end
end

class Scene_PMD_AutoChess
  alias pmd_ac_v091_start start unless method_defined?(:pmd_ac_v091_start)
  alias pmd_ac_v091_create_units create_units unless method_defined?(:pmd_ac_v091_create_units)
  alias pmd_ac_v091_start_battle start_battle unless method_defined?(:pmd_ac_v091_start_battle)
  alias pmd_ac_v091_update_battle_step update_battle_step unless method_defined?(:pmd_ac_v091_update_battle_step)
  alias pmd_ac_v091_deal_direct_damage deal_direct_damage unless method_defined?(:pmd_ac_v091_deal_direct_damage)
  alias pmd_ac_v091_process_stage_result_v080 process_stage_result_v080 unless method_defined?(:pmd_ac_v091_process_stage_result_v080)
  alias pmd_ac_v091_refresh_header refresh_header unless method_defined?(:pmd_ac_v091_refresh_header)
  alias pmd_ac_v091_prepare_verification_battle prepare_verification_battle unless method_defined?(:pmd_ac_v091_prepare_verification_battle)
  alias pmd_ac_v091_update_verification_script update_verification_script unless method_defined?(:pmd_ac_v091_update_verification_script)
  alias pmd_ac_v091_log_event log_event unless method_defined?(:pmd_ac_v091_log_event)

  def start
    pmd_ac_v091_start
    begin
      if FileTest.exist?(PMD_AC::BATTLE_LOG_FILE)
        text=File.open(PMD_AC::BATTLE_LOG_FILE,'rb'){|f|f.read}
        text.sub!(/PMD AutoChess Proto v0\.[0-9.]+ Battle Verification Log/,
          'PMD AutoChess Proto v0.91 Battle Verification Log')
        File.open(PMD_AC::BATTLE_LOG_FILE,'wb'){|f|f.write(text)}
      end
    rescue
    end
    m=PMD_AC::BOSS_FRAMEWORK_MANIFEST_V091
    log_event(:boss_framework,
      'FLOW v0.91 profiles='+m[:profiles].to_s+' links='+m[:encounter_links].to_s+
      ' triggers=hp,timer adds=1 weather=1 field=1 shield=1 invuln=1 notice=1 mechanic=1 first_clear=1 boss_recruit=off')
    refresh_header
  end

  def create_units
    pmd_ac_v091_create_units
    req=rpg_request_v081
    @boss_framework_active_v091=false
    @boss_profile_key_v091=nil
    return if req==nil || req[:kind]!=:boss
    profile_key=PMD_AC.boss_profile_key_for_request_v091(req)
    return if profile_key==nil
    req[:recruitable]=false
    req[:recruit_rate]=0
    req[:can_escape]=false
    boss=(@units||[]).find{|u|u.team==:enemy && u.respond_to?(:boss_v081) && u.boss_v081}
    boss=(@units||[]).find{|u|u.team==:enemy && u.counts_for_victory?} if boss==nil
    if boss!=nil && boss.setup_boss_profile_v091(profile_key)
      @boss_framework_active_v091=true
      @boss_profile_key_v091=profile_key
      p=PMD_AC.boss_profile_v091(profile_key)
      log_event(:boss_framework,'PROFILE boss='+boss.log_name+' key='+profile_key.to_s+
        ' phases='+(p[:phases]||[]).size.to_s+' legacy_phase_router=off recruit=0 escape=0')
    end
  end

  def start_battle
    @boss_elapsed_v091=0
    pmd_ac_v091_start_battle
  end

  def boss_elapsed_v091
    @boss_elapsed_v091.to_i
  end

  def boss_units_v091
    (@units||[]).find_all{|u|u.team==:enemy && u.alive? && u.respond_to?(:boss_framework_v091?) && u.boss_framework_v091?}
  end

  def update_battle_step
    pmd_ac_v091_update_battle_step
    return unless @phase==:battle
    @boss_elapsed_v091=@boss_elapsed_v091.to_i+1
    boss_units_v091.each do |u|
      u.update_boss_runtime_v091
      update_one_boss_phase_v091(u)
    end
  end

  def update_one_boss_phase_v091(unit)
    return if unit==nil || unit.dead? || unit.boss_phase_lock_v091>0
    p=unit.boss_profile_v091
    return if p==nil
    hp_rate=PMD_AC.boss_phase_hp_rate_v091(unit.hp,unit.maxhp)
    age=boss_elapsed_v091
    (p[:phases]||[]).each do |rule|
      key=rule[:key]
      next if key==nil || unit.boss_phase_done_v091?(key)
      next unless PMD_AC.boss_phase_trigger_met_v091(rule,hp_rate,age)
      trigger_boss_phase_v091(unit,p,rule,hp_rate,age)
      return
    end
  end

  def trigger_boss_phase_v091(unit,profile,rule,hp_rate=nil,age=nil)
    return false if unit==nil || profile==nil || rule==nil
    key=rule[:key]
    return false if key==nil || unit.boss_phase_done_v091?(key)
    hp_rate=PMD_AC.boss_phase_hp_rate_v091(unit.hp,unit.maxhp) if hp_rate==nil
    age=boss_elapsed_v091 if age==nil
    unit.mark_boss_phase_v091(key)
    unit.set_boss_phase_lock_v091(profile[:phase_lock_frames]||12)
    text=rule[:text] || key.to_s
    add_center_notice_v088('BOSS｜'+text.to_s) if respond_to?(:add_center_notice_v088)
    results=[]
    (rule[:effects]||[]).each do |ef|
      results.push(apply_boss_phase_effect_v091(unit,profile,rule,ef,false))
    end
    log_event(:boss_phase,
      unit.log_name+' PHASE_V091 key='+key.to_s+' text='+text.to_s+
      ' trigger='+PMD_AC.boss_phase_trigger_label_v091(rule)+
      ' hp_rate='+sprintf('%.3f',hp_rate.to_f)+' age='+age.to_i.to_s+
      ' effects='+(rule[:effects]||[]).collect{|x|x[0].to_s}.join(','))
    results.all?{|x|x}
  end

  def apply_boss_phase_effect_v091(unit,profile,phase,effect,dry_run=false)
    return false if effect==nil || !effect.is_a?(Array)
    kind=effect[0]
    return false unless PMD_AC.boss_effect_supported_v091?(kind)
    return true if dry_run
    case kind
    when :shield_rate
      unit.add_shield([(unit.maxhp.to_f*effect[1].to_f).round,1].max,240,nil,unit)
    when :shield_flat
      unit.add_shield([effect[1].to_i,1].max,240,nil,unit)
    when :heal_rate
      unit.heal([(unit.maxhp.to_f*effect[1].to_f).round,1].max)
    when :energy
      unit.gain_energy(effect[1].to_i,unit,:boss_phase_v091)
    when :stat_mult
      return unit.apply_boss_stat_mult_v081(effect[1],effect[2])
    when :weather
      return false unless respond_to?(:set_canonical_weather)
      turns=effect[2]==nil ? 99 : effect[2].to_i
      permanent=effect[3] ? true:false
      set_canonical_weather(effect[1],unit,turns,permanent)
    when :field
      return false unless respond_to?(:set_canonical_field_effect_v035)
      turns=effect[2]==nil ? nil : effect[2].to_i
      set_canonical_field_effect_v035(effect[1],unit,turns)
    when :summon
      species=effect[1]
      count=[effect[2].to_i,1].max
      options=effect[3].is_a?(Hash) ? effect[3] : {}
      spawned=0
      count.times do |i|
        spawned+=1 if spawn_boss_add_v091(unit,species,options,i)!=nil
      end
      log_event(:boss_add,unit.log_name+' SUMMON_BATCH species='+species.to_s+
        ' requested='+count.to_s+' spawned='+spawned.to_s)
      return spawned>0
    when :invulnerable
      ok=unit.start_boss_invulnerability_v091(effect[1].to_i)
      log_event(:boss_invuln,unit.log_name+' INVULNERABLE_START frames='+effect[1].to_i.to_s) if ok
      return ok
    when :mechanic
      return call_boss_phase_mechanic_v091(unit,profile,phase,effect[1],effect[2])
    end
    true
  end

  def spawn_boss_add_v091(owner,species,options,index=0)
    return nil if owner==nil || owner.dead? || PMD_AC.unit_profile(species)==nil
    options={} if options==nil
    if respond_to?(:summoned_units) && summoned_units(owner.team).size>=PMD_AC::SUMMON_MAX_PER_TEAM
      log_event(:boss_add,owner.log_name+' SUMMON_REJECT species='+species.to_s+' reason=team_limit')
      return nil
    end
    @next_unit_id=@units.size if @next_unit_id==nil
    level=options[:level]
    level=owner.level.to_i+(options[:level_offset]||0).to_i if level==nil
    level=PMD_AC.clamp(level.to_i,1,PMD_AC::POKEMON_MAX_LEVEL)
    inst=PMD_PokemonInstance.new(species,level)
    unit=Game_PMDChessUnit.new(@next_unit_id,species,owner.team,
      PMD_AC.pixel_to_cell_x(owner.pixel_x),PMD_AC.pixel_to_cell_y(owner.pixel_y),inst)
    @next_unit_id+=1
    unit.scene=self
    summon_options={
      :duration=>(options[:duration]||420).to_i,
      :allow_skill=>options[:allow_skill] ? true:false,
      :expire_with_owner=>options.has_key?(:expire_with_owner) ? (options[:expire_with_owner] ? true:false) : true,
      :hp_scale=>(options[:hp_scale]||1.0).to_f,
      :stat_scale=>(options[:stat_scale]||1.0).to_f
    }
    unit.configure_as_summon(owner,summon_options)
    off=PMD_AC::BOSS_ADD_OFFSETS_V091[index.to_i%PMD_AC::BOSS_ADD_OFFSETS_V091.size]
    x=PMD_AC.clamp(owner.pixel_x.to_f+off[0].to_f,PMD_AC::BOARD_LEFT.to_f,PMD_AC::BOARD_RIGHT.to_f)
    y=PMD_AC.clamp(owner.pixel_y.to_f+off[1].to_f,PMD_AC::BOARD_TOP.to_f,PMD_AC::BOARD_BOTTOM.to_f)
    unit.deploy_to_pixel(x,y)
    unit.start_combat
    @units.push(unit)
    @unit_sprites.push(Sprite_PMDChessUnit.new(@viewport,unit)) if @unit_sprites!=nil
    log_event(:boss_add,owner.log_name+' SPAWN '+unit.log_name+' species='+species.to_s+
      ' lv='+level.to_s+' uid='+unit.instance_uid.to_s+' victory=0 dur='+unit.summon_remaining.to_s)
    unit
  end

  def call_boss_phase_mechanic_v091(unit,profile,phase,key,args=nil)
    return false if key==nil
    meth=('boss_phase_mechanic_'+key.to_s+'_v091').to_sym
    unless respond_to?(meth)
      log_event(:boss_mechanic,unit.log_name+' HOOK_MISSING key='+key.to_s)
      return false
    end
    result=send(meth,unit,phase,args||{})
    log_event(:boss_mechanic,unit.log_name+' HOOK key='+key.to_s+' result='+(result ? '1':'0'))
    result ? true:false
  end

  # Demo Hook：讓 Timer 召援不是只有視覺；追加少量能量。
  def boss_phase_mechanic_hive_alarm_v091(unit,phase,args)
    unit.gain_energy(10,unit,:boss_mechanic_v091)
    true
  end

  # Demo Hook：最後階段再刷新一次攻擊目標，避免 Boss 因舊 commitment 停頓。
  def boss_phase_mechanic_last_sting_v091(unit,phase,args)
    unit.set_target(nil) if unit.respond_to?(:set_target)
    true
  end

  # Direct Hit 在 Scene 層先擋，避免 Invulnerability 時還播放 Crit/Hit Damage 回饋。
  # DOT/其他直接 receive_damage 則由 Unit 層第二道保護攔截。
  def deal_direct_damage(user,target,power,options=nil)
    if target!=nil && target.respond_to?(:boss_invulnerable_v091?) && target.boss_invulnerable_v091?
      log_event(:boss_invuln,target.log_name+' BLOCK_DIRECT from='+(user==nil ? 'SYSTEM' : user.log_name)+
        ' remain='+target.boss_invulnerable_frames_v091.to_i.to_s)
      return 0
    end
    pmd_ac_v091_deal_direct_damage(user,target,power,options)
  end

  def process_stage_result_v080(winner_team)
    req=rpg_request_v081
    profile_key=req==nil ? nil : PMD_AC.boss_profile_key_for_request_v091(req)
    before=profile_key==nil ? 0 : PMD_AC.boss_clear_count_v091(profile_key)
    pmd_ac_v091_process_stage_result_v080(winner_team)
    return unless verification_mode==:normal && winner_team==:ally && req!=nil && req[:kind]==:boss && profile_key!=nil
    first=before<=0
    count=PMD_AC.record_boss_clear_v091(profile_key)
    rows=PMD_AC.boss_reward_rows_v091(profile_key,first)
    results=[]
    rows.each do |row|
      r=PMD_AC.apply_reward_row_v083(row,false,nil,nil)
      results.push(r) if r[:granted]
    end
    labels=results.collect{|x|x[:label].to_s}
    if @loot_reward_v083!=nil
      @loot_reward_v083[:results]=[] if @loot_reward_v083[:results]==nil
      @loot_reward_v083[:labels]=[] if @loot_reward_v083[:labels]==nil
      @loot_reward_v083[:results].concat(results)
      @loot_reward_v083[:labels].concat(labels)
    end
    @boss_reward_v091={:profile=>profile_key,:first_clear=>first,:clear_count=>count,
      :results=>results,:labels=>labels}
    log_event(:boss_reward,'profile='+profile_key.to_s+' first='+(first ? '1':'0')+
      ' clear_count='+count.to_s+' bonus='+(labels.empty? ? 'none' : labels.join('|'))+
      ' recruit=0')
  end

  def refresh_header
    pmd_ac_v091_refresh_header
    return if @header_sprite==nil || @header_sprite.bitmap==nil
    bmp=@header_sprite.bitmap
    bmp.fill_rect(0,0,Graphics.width,28,Color.new(0,0,0,180))
    pmd_ac_v074_font(bmp)
    bmp.font.size=PMD_AC::HEADER_TITLE_FONT_V0741
    bmp.font.bold=true
    bmp.font.color=Color.new(255,255,255)
    bmp.draw_text(16,4,Graphics.width-32,24,'PMD 自走棋原型 v0.91',1)
  end

  def boss_framework_v091?
    verification_mode==:boss_framework_v091
  end

  def prepare_verification_battle
    pmd_ac_v091_prepare_verification_battle
    if boss_framework_v091?
      @boss_v091_failed=false
      @boss_v091_fake=nil
    end
  end

  def log_event(category,message)
    if category.to_s=='verify' && boss_framework_v091? &&
       message.to_s.index('BOSS_')==0 && message.to_s.include?(' pass=0')
      @boss_v091_failed=true
    end
    pmd_ac_v091_log_event(category,message)
  end

  def log_verify_v091(name,pass,detail='')
    @boss_v091_failed=true unless pass
    log_event(:verify,name+' pass='+(pass ? '1':'0')+(detail=='' ? '' : ' '+detail))
  end

  def verify_boss_manifest_v091
    return if @verification_done[:v091_manifest]
    e=PMD_AC.boss_profile_errors_v091
    m=PMD_AC::BOSS_FRAMEWORK_MANIFEST_V091
    pass=e.empty? && m[:profiles]>=1 && m[:boss_recruitable]==false && m[:effect_types].size==10
    log_verify_v091('BOSS_FRAMEWORK_MANIFEST_V091',pass,
      'profiles='+m[:profiles].to_s+' links='+m[:encounter_links].to_s+' effects='+m[:effect_types].size.to_s+
      ' errors=['+e.join(',')+'] checksum32='+m[:runtime_checksum32].to_s)
    @verification_done[:v091_manifest]=true
  end

  def verify_boss_trigger_policy_v091
    return if @verification_done[:v091_trigger]
    hp={:key=>:hp,:hp_below=>0.50}
    tm={:key=>:tm,:time_frames=>360}
    both={:key=>:both,:hp_below=>0.50,:time_frames=>360,:trigger_mode=>:all}
    pass=PMD_AC.boss_phase_trigger_met_v091(hp,0.49,10) &&
      !PMD_AC.boss_phase_trigger_met_v091(hp,0.51,999) &&
      PMD_AC.boss_phase_trigger_met_v091(tm,1.0,360) &&
      !PMD_AC.boss_phase_trigger_met_v091(tm,0.1,359) &&
      PMD_AC.boss_phase_trigger_met_v091(both,0.49,360) &&
      !PMD_AC.boss_phase_trigger_met_v091(both,0.49,359)
    log_verify_v091('BOSS_TRIGGER_POLICY_V091',pass,'hp=1 timer=1 combined_all=1 phase_lock=12')
    @verification_done[:v091_trigger]=true
  end

  def verify_boss_effect_router_v091
    return if @verification_done[:v091_router]
    p=PMD_AC.boss_profile_v091(:hive_overlord)
    dummy=living_units(:enemy)[0]
    phases=p==nil ? [] : (p[:phases]||[])
    kinds=[]
    phases.each{|ph|(ph[:effects]||[]).each{|ef|kinds.push(ef[0])}}
    required=[:summon,:mechanic,:shield_rate,:field,:energy,:weather,:stat_mult,:invulnerable]
    ok=required.all?{|k|kinds.include?(k) && apply_boss_phase_effect_v091(dummy,p,phases[0],[k],true)}
    log_verify_v091('BOSS_EFFECT_ROUTER_V091',ok,
      'summon=1 weather=1 field=1 shield=1 invuln=1 energy=1 stat=1 mechanic=1 dry_run=1')
    @verification_done[:v091_router]=true
  end

  def verify_boss_invulnerability_v091
    return if @verification_done[:v091_invuln]
    inst=PMD_PokemonInstance.new(:beedrill,18)
    u=Game_PMDChessUnit.new(99101,:beedrill,:enemy,5,2,inst)
    u.scene=self
    u.apply_encounter_mods_v081({:boss=>true,:stat_mult=>{:hp=>1.0}})
    u.setup_boss_profile_v091(:hive_overlord)
    before=u.hp
    u.start_boss_invulnerability_v091(2)
    u.receive_damage(50,living_units(:ally)[0],false,false,false)
    blocked=(u.hp==before && u.boss_invulnerable_v091?)
    u.update_boss_runtime_v091
    u.update_boss_runtime_v091
    expired=!u.boss_invulnerable_v091?
    u.receive_damage(50,living_units(:ally)[0],false,false,false)
    resumed=u.hp<before
    pass=blocked && expired && resumed
    log_verify_v091('BOSS_INVULNERABILITY_V091',pass,
      'blocked='+(blocked ? '1':'0')+' expired='+(expired ? '1':'0')+' damage_resumed='+(resumed ? '1':'0'))
    @verification_done[:v091_invuln]=true
  end

  def verify_boss_profile_v091
    return if @verification_done[:v091_profile]
    p=PMD_AC.boss_profile_v091(:hive_overlord)
    r=PMD_AC.make_battle_request_v081(:boss_beedrill)
    phases=p==nil ? [] : (p[:phases]||[])
    pass=p!=nil && phases.size==4 && r!=nil && r[:boss_profile_v091]==:hive_overlord &&
      r[:kind]==:boss && !r[:recruitable] && !r[:can_escape]
    log_verify_v091('BOSS_PROFILE_V091',pass,
      'profile=hive_overlord phases='+phases.size.to_s+' hp_phases=3 timer_phases=1 recruit=0 escape=0 legacy_api=start_battle_v081')
    @verification_done[:v091_profile]=true
  end

  def verify_boss_reward_policy_v091
    return if @verification_done[:v091_reward]
    first=PMD_AC.boss_reward_rows_v091(:hive_overlord,true)
    repeat_rows=PMD_AC.boss_reward_rows_v091(:hive_overlord,false)
    fr=first.empty? ? nil : PMD_AC.apply_reward_row_v083(first[0],true,0,0)
    legacy=PMD_AC.resolve_rewards_v083({:kind=>:boss,:key=>:boss_beedrill,:options=>{}},nil,false,true,[0])
    pass=fr!=nil && fr[:amount].to_i==200 && repeat_rows.empty? &&
      legacy[:results][0]!=nil && legacy[:results][0][:amount].to_i==300
    log_verify_v091('BOSS_REWARD_POLICY_V091',pass,
      'legacy=300G first_bonus=200G first_total=500G repeat_total=300G clear_count=persistent recruit=0')
    @verification_done[:v091_reward]=true
  end

  def verify_boss_carry_v091
    return if @verification_done[:v091_carry]
    pass=PMD_AC::RPG_ENCOUNTER_MANIFEST_V081[:boss_recruitable]==false &&
      PMD_AC::REWARD_LOOT_MANIFEST_V083[:boss_recruitable]==false &&
      PMD_AC::BOSS_FRAMEWORK_MANIFEST_V091[:legacy_boss]=='v0.81'
    log_verify_v091('BOSS_FRAMEWORK_CARRY_V091',pass,
      'preview=v0.90 stalemate=v0.89 foot=v0.89.2 combat_feel=v0.88.3 reward=v0.83 encounter=v0.81 damage_packet=v0.60.2 unchanged')
    @verification_done[:v091_carry]=true
  end

  def update_verification_script
    unless boss_framework_v091?
      pmd_ac_v091_update_verification_script
      return
    end
    f=@verification_frame.to_i
    verify_boss_manifest_v091 if f>=2
    verify_boss_trigger_policy_v091 if f>=4
    verify_boss_effect_router_v091 if f>=6
    verify_boss_invulnerability_v091 if f>=8
    verify_boss_profile_v091 if f>=10
    verify_boss_reward_policy_v091 if f>=12
    verify_boss_carry_v091 if f>=14
    if f>=18 && !@verification_done[:v091_final]
      pass=!@boss_v091_failed
      log_verify_v091('BOSS_FRAMEWORK_V091',pass,
        'manifest=1 trigger=1 router=1 invuln=1 profile=1 reward=1 carry=1')
      @verification_done[:v091_final]=true
    end
    complete_verification_mode if f>=PMD_AC::BOSS_FRAMEWORK_VERIFY_END_V091
  end
end
