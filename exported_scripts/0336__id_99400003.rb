# encoding: UTF-8
#==============================================================================
# 【PMD AutoChess 中文維護說明】
# 腳本：PMD AutoChess Loot / Item Economy Runtime v0.94
# 分類：RPG 獎勵／掉落池／戰鬥結算／Verifier
#
# 【用途】
# 執行 v0.94 Weighted Loot Pool，並把結果追加到既有 v0.83 Reward/Loot 結算。
# 同時負責 v0.94 的整合 Verifier，包含本版新增的 PMD Walk/Hop Motion 規則。
#
# 【主要流程】
# 1. 戰鬥勝利 -> 舊 v0.83 固定 Reward 結算。
# 2. Region 戰 -> 舊 v0.86 Rare / Elite Bonus 照常追加。
# 3. 如果 request / Binding 有 :loot_pool -> v0.94 Weighted Pool 再追加。
# 4. 結果仍放進 @loot_reward_v083，因此舊 Result UI 不需要第二套戰利品畫面。
#
# 【Context 額外 Roll】
# - Rare / Very Rare、Elite、Boss 可依 Data 常數增加 Roll。
# - 首通／重複不自動增加 Roll，但 Entry 可用 first_clear_only / repeat_only 篩選。
#
# 【掉落紀錄】
# Game_System 會保存：
# - last_loot_pool_result_v094：上一個真正套用的 v0.94 Pool 結果。
# - loot_ledger_v094：依 type/id 累計取得數量，供未來商店／製作／統計使用。
# 只有 dry_run=false 才寫入，Verifier 不污染存檔。
#
# 【事件／腳本呼叫方式】
#   PMD_AC.last_loot_pool_result_v094
#   PMD_AC.loot_ledger_v094
#   PMD_AC.resolve_loot_pool_v094(:my_pool, context, true, [0,20])
#
# 【實際範例】
#   request[:options][:loot_pool] = :forest_materials
#   -> 勝利後先拿 v0.83 固定獎勵，再抽 forest_materials。
#
# 【Verifier】
# NORMAL 按 S 一次 -> LOOT_ECONOMY_V094 -> Shift。
# 預期包含：
#   PMD_MOTION_IDLE_WALK_V094 pass=1
#   PMD_MOTION_CONTACT_ROUTER_V094 pass=1
#   LOOT_ECONOMY_MANIFEST_V094 pass=1
#   LOOT_POOL_WEIGHTED_V094 pass=1
#   LOOT_CONTEXT_ROLLS_V094 pass=1
#   LOOT_BINDING_POLICY_V094 pass=1
#   LOOT_ECONOMY_CARRY_V094 pass=1
#   LOOT_ECONOMY_V094 pass=1
#   VERIFY_FINISHED_BATTLE_RESUME pass=1
#
# 【注意事項】
# - v0.94 production bindings 預設為 0，所以現有 Stage/Region 實際獎勵不變。
# - 本版不新增 Data/Items.rvdata 內容；Item Catalog 等用途確定後只補 Data 表。
# - 不修改傷害、AI、招募、進化、v0.60.2 Multi-hit 或 v0.91.4 位移數值。
# - RPG Maker VX / RGSS2 / Ruby 1.8 相容；禁止舊式 instance-variable reflection probe。
#==============================================================================

#==============================================================================
# ■ Game_System : Loot Ledger
#==============================================================================
class Game_System
  def pmd_ac_loot_ledger_v094
    @pmd_ac_loot_ledger_v094={} if @pmd_ac_loot_ledger_v094==nil
    @pmd_ac_loot_ledger_v094
  end

  def pmd_ac_last_loot_pool_result_v094
    @pmd_ac_last_loot_pool_result_v094
  end

  def pmd_ac_set_last_loot_pool_result_v094(value)
    @pmd_ac_last_loot_pool_result_v094=value
  end
end

module PMD_AC
  class << self
    def loot_result_identity_v094(result)
      return nil if result==nil
      t=result[:type]
      case t
      when :item,:weapon,:armor,:variable,:switch,:common_event
        return t.to_s+':'+result[:id].to_i.to_s
      when :gold
        return 'gold'
      end
      t.to_s
    end

    def record_loot_pool_result_v094(result)
      return if result==nil || $game_system==nil
      ledger=$game_system.pmd_ac_loot_ledger_v094
      (result[:results]||[]).each do |r|
        key=loot_result_identity_v094(r)
        next if key==nil
        amount=r[:amount]
        amount=1 if amount==nil
        ledger[key]=ledger[key].to_i+amount.to_i
      end
      $game_system.pmd_ac_set_last_loot_pool_result_v094(result)
    end

    def loot_ledger_v094
      return {} if $game_system==nil
      $game_system.pmd_ac_loot_ledger_v094
    end

    def last_loot_pool_result_v094
      return nil if $game_system==nil
      $game_system.pmd_ac_last_loot_pool_result_v094
    end

    # rolls：Weighted Pick 的 deterministic roll。
    # chance_rolls：抽中 Entry 後交給 v0.83 chance 判定。
    # amount_rolls：Gold min/max 等數量 roll。
    def resolve_loot_pool_v094(pool_key,context=nil,dry_run=false,rolls=nil,chance_rolls=nil,amount_rolls=nil)
      pool=loot_pool_v094(pool_key)
      return {:pool=>pool_key,:results=>[],:labels=>[],:rolls=>0,:dry_run=>dry_run ? true:false,
              :reason=>:missing_pool} if pool==nil
      ctx=context || {}
      candidates=[]
      (pool[:entries]||[]).each do |row|
        candidates.push(row.dup) if loot_entry_allowed_v094(row,ctx)
      end
      wanted=loot_roll_count_v094(pool,ctx)
      results=[]
      used=[]
      i=0
      while i<wanted && !candidates.empty?
        pick_roll=rolls==nil ? nil : rolls[i]
        row=loot_weighted_pick_v094(candidates,pick_roll)
        break if row==nil
        chance_roll=chance_rolls==nil ? nil : chance_rolls[i]
        amount_roll=amount_rolls==nil ? i : amount_rolls[i]
        r=apply_reward_row_v083(row,dry_run,chance_roll,amount_roll)
        if r[:granted]
          r[:loot_pool_v094]=pool_key
          r[:loot_entry_v094]=row[:key]
          r[:label]='掉落 '+r[:label].to_s
          results.push(r)
        end
        used.push(row[:key])
        candidates.delete(row) unless row[:repeatable]
        i+=1
      end
      out={:pool=>pool_key,:results=>results,:labels=>results.collect{|x|x[:label].to_s},
           :rolls=>wanted,:used=>used,:context=>ctx,:dry_run=>dry_run ? true:false}
      record_loot_pool_result_v094(out) unless dry_run
      out
    end
  end

  V094_OLD_VERIFICATION_MODES = VERIFICATION_MODES.dup
  V094_OLD_VERIFICATION_LABELS = VERIFICATION_LABELS.dup
  remove_const(:VERIFICATION_MODES)
  VERIFICATION_MODES = [:normal,:loot_economy_v094] +
    V094_OLD_VERIFICATION_MODES.reject{|x|x==:normal || x==:loot_economy_v094}
  remove_const(:VERIFICATION_LABELS)
  VERIFICATION_LABELS = V094_OLD_VERIFICATION_LABELS.dup
  VERIFICATION_LABELS[:normal]='NORMAL'
  VERIFICATION_LABELS[:loot_economy_v094]='LOOT_ECONOMY_V094'
end

#==============================================================================
# ■ Scene_PMD_AutoChess
#==============================================================================
class Scene_PMD_AutoChess
  alias pmd_ac_v094_start start unless method_defined?(:pmd_ac_v094_start)
  alias pmd_ac_v094_refresh_header refresh_header unless method_defined?(:pmd_ac_v094_refresh_header)
  alias pmd_ac_v094_process_loot_reward_v083 process_loot_reward_v083 unless method_defined?(:pmd_ac_v094_process_loot_reward_v083)
  alias pmd_ac_v094_prepare_verification_battle prepare_verification_battle unless method_defined?(:pmd_ac_v094_prepare_verification_battle)
  alias pmd_ac_v094_update_verification_script update_verification_script unless method_defined?(:pmd_ac_v094_update_verification_script)
  alias pmd_ac_v094_log_event log_event unless method_defined?(:pmd_ac_v094_log_event)

  def start
    pmd_ac_v094_start
    begin
      if FileTest.exist?(PMD_AC::BATTLE_LOG_FILE)
        text=File.open(PMD_AC::BATTLE_LOG_FILE,'rb'){|f|f.read}
        text.sub!(/PMD AutoChess Proto v0\.[0-9.]+ Battle Verification Log/,
          'PMD AutoChess Proto v0.94 Battle Verification Log')
        File.open(PMD_AC::BATTLE_LOG_FILE,'wb'){|f|f.write(text)}
      end
    rescue
    end
    m=PMD_AC::LOOT_ECONOMY_MANIFEST_V094
    log_event(:presentation,
      'PATCH v0.94 battle_rest_visual=walk semantic_contact=hop_asset_aware heavy_rush=leap_forth head_rush=head native_router=v0.62_preserved damage_unchanged=1')
    log_event(:loot_economy,
      'FLOW v0.94 weighted_pool=1 pools='+m[:pools].to_s+
      ' production_bindings='+m[:production_bindings].to_s+
      ' reward_backend=v0.83 region_bonus=v0.86 item_catalog=deferred balance_changed=0')
    refresh_header
  end

  def refresh_header
    pmd_ac_v094_refresh_header
    return if @header_sprite==nil || @header_sprite.bitmap==nil
    bmp=@header_sprite.bitmap
    bmp.fill_rect(0,0,Graphics.width,28,Color.new(0,0,0,180))
    pmd_ac_v074_font(bmp)
    bmp.font.size=PMD_AC.const_defined?(:UI_HEADER_TITLE_FONT_V086) ? PMD_AC::UI_HEADER_TITLE_FONT_V086 : 20
    bmp.font.bold=true
    bmp.font.color=Color.new(255,255,255)
    bmp.draw_text(16,1,Graphics.width-32,30,'PMD 自走棋原型 v0.94',1)
  end

  def elite_enemy_count_v094
    n=0
    (@units||[]).each do |u|
      next if u==nil || u.team!=:enemy
      n+=1 if u.respond_to?(:elite_v084) && u.elite_v084
    end
    n
  end

  def process_loot_reward_v083(winner_team)
    loot=pmd_ac_v094_process_loot_reward_v083(winner_team)
    return loot unless verification_mode==:normal && winner_team==:ally
    req=respond_to?(:rpg_request_v081) ? rpg_request_v081 : nil
    sid=nil
    first=false
    if req!=nil && req[:kind]==:stage
      sid=req[:stage_id]
      first=@stage_reward_v080!=nil && @stage_reward_v080[:first_clear] ? true:false
    elsif req==nil
      sid=@active_stage_id_v080 || PMD_AC.current_stage_id_v080
      first=@stage_reward_v080!=nil && @stage_reward_v080[:first_clear] ? true:false
    end
    pool_key=PMD_AC.loot_pool_key_for_v094(req,sid)
    return loot if pool_key==nil
    ctx=PMD_AC.loot_context_v094(req,sid,first,elite_enemy_count_v094)
    extra=PMD_AC.resolve_loot_pool_v094(pool_key,ctx,false,nil,nil,nil)
    return loot if extra[:results].empty?
    loot={:table=>nil,:results=>[],:labels=>[],:winner=>winner_team} if loot==nil
    loot[:results]||=[]
    loot[:labels]||=[]
    extra[:results].each{|r|loot[:results].push(r)}
    extra[:labels].each{|s|loot[:labels].push(s)}
    @loot_reward_v083=loot
    log_event(:loot_economy,
      'GRANT pool='+pool_key.to_s+' rolls='+extra[:rolls].to_i.to_s+
      ' rarity='+ctx[:rarity].to_s+' elite='+ctx[:elite_count].to_i.to_s+
      ' boss='+(ctx[:boss] ? '1':'0')+' rewards='+extra[:labels].join('|'))
    loot
  end

  def loot_economy_v094?
    verification_mode==:loot_economy_v094
  end

  def prepare_verification_battle
    pmd_ac_v094_prepare_verification_battle
    return unless loot_economy_v094?
    @loot_economy_failed_v094=false
    log_event(:showcase,
      'START mode=LOOT_ECONOMY_V094 motion=walk_idle+hop_contact economy=weighted_pool production_bindings=0')
  end

  def log_event(category,message)
    if category.to_s=='verify' && loot_economy_v094? &&
       message.to_s.index('V094')!=nil && message.to_s.include?(' pass=0')
      @loot_economy_failed_v094=true
    end
    pmd_ac_v094_log_event(category,message)
  end

  def log_verify_v094(name,pass,detail='')
    @loot_economy_failed_v094=true unless pass
    log_event(:verify,name+' pass='+(pass ? '1':'0')+(detail=='' ? '' : ' '+detail))
  end

  def verify_pmd_motion_idle_walk_v094
    return if @verification_done[:v094_motion_idle]
    u=verification_unit(:ally,:bulbasaur)
    pass=false
    if u!=nil
      u.instance_variable_set(:@action,:idle)
      u.instance_variable_set(:@visual_action,:idle)
      u.instance_variable_set(:@stun_frames,0)
      u.instance_variable_set(:@hurt_frames,0)
      u.instance_variable_set(:@evade_visual_frames,0)
      u.refresh_motion_visual
      pass=u.action==:idle && u.visual_action==:walk &&
        PMD_AC.action_data(u.species,:walk)!=nil
    end
    log_verify_v094('PMD_MOTION_IDLE_WALK_V094',pass,
      'logic_idle=1 visual=walk fallback=walk_to_idle_if_missing')
    @verification_done[:v094_motion_idle]=true
  end

  def verify_pmd_motion_contact_router_v094
    return if @verification_done[:v094_motion_router]
    tackle=PMD_AC.skill_data(:mv_tackle)
    pt=PMD_AC.move_presentation_profile_v055(:tackle) || {:motion=>:contact_return}
    dk=PMD_AC.skill_data(:mv_double_kick)
    pdk=PMD_AC.move_presentation_profile_v055(:double_kick) || {}
    hb=PMD_AC.skill_data(:mv_headbutt)
    phb=PMD_AC.move_presentation_profile_v055(:headbutt) || {:motion=>:contact_return}
    tb=PMD_AC.skill_data(:mv_thunderbolt)
    ptb=PMD_AC.move_presentation_profile_v055(:thunderbolt) || {}
    a=PMD_AC.native_pose_for_move_v060('0001',:tackle,tackle,pt)
    b=PMD_AC.native_pose_for_move_v060('0004',:double_kick,dk,pdk)
    c=PMD_AC.native_pose_for_move_v060('0001',:headbutt,hb,phb)
    d=PMD_AC.native_pose_for_move_v060('0025',:thunderbolt,tb,ptb)
    pass=(a==:leap_forth || a==:hop) && b==:kick && c==:head && d==:shock
    log_verify_v094('PMD_MOTION_CONTACT_ROUTER_V094',pass,
      'tackle='+a.to_s+' double_kick='+b.to_s+' headbutt='+c.to_s+
      ' thunderbolt='+d.to_s+' specialized_pose_preserved=1 asset_aware=1')
    @verification_done[:v094_motion_router]=true
  end

  def verify_loot_economy_manifest_v094
    return if @verification_done[:v094_manifest]
    e=PMD_AC.loot_economy_errors_v094
    m=PMD_AC::LOOT_ECONOMY_MANIFEST_V094
    pass=e.empty? && m[:weighted_pick] && m[:reward_backend]==:v083 &&
      m[:production_bindings]==0 && m[:balance_changed]==false
    log_verify_v094('LOOT_ECONOMY_MANIFEST_V094',pass,
      'pools='+m[:pools].to_s+' production_bindings='+m[:production_bindings].to_s+
      ' backend=v0.83 errors=['+e.join(',')+'] balance_changed=0')
    @verification_done[:v094_manifest]=true
  end

  def verify_loot_pool_weighted_v094
    return if @verification_done[:v094_weighted]
    ctx={:rarity=>:normal,:elite=>false,:boss=>false,:first_clear=>false,:repeat=>true}
    r=PMD_AC.resolve_loot_pool_v094(:verifier_sample_v094,ctx,true,[0,61],[0,0],[0,0])
    keys=r[:results].collect{|x|x[:loot_entry_v094]}
    pass=r[:rolls]==2 && r[:results].size==2 && keys.include?(:coin_small) && keys.include?(:item_sample)
    log_verify_v094('LOOT_POOL_WEIGHTED_V094',pass,
      'rolls='+r[:rolls].to_s+' picks='+keys.join(',')+' dry_run=1 ledger_unchanged=1')
    @verification_done[:v094_weighted]=true
  end

  def verify_loot_context_rolls_v094
    return if @verification_done[:v094_context]
    pool=PMD_AC.loot_pool_v094(:verifier_sample_v094)
    n0=PMD_AC.loot_roll_count_v094(pool,{:rarity=>:normal,:elite=>false,:boss=>false})
    nr=PMD_AC.loot_roll_count_v094(pool,{:rarity=>:rare,:elite=>false,:boss=>false})
    ne=PMD_AC.loot_roll_count_v094(pool,{:rarity=>:rare,:elite=>true,:boss=>false})
    nb=PMD_AC.loot_roll_count_v094(pool,{:rarity=>:rare,:elite=>true,:boss=>true})
    elite_row=pool[:entries].find{|x|x[:key]==:elite_coin}
    rare_row=pool[:entries].find{|x|x[:key]==:rare_coin}
    allow_normal=!PMD_AC.loot_entry_allowed_v094(elite_row,{:rarity=>:normal,:elite=>false}) &&
      !PMD_AC.loot_entry_allowed_v094(rare_row,{:rarity=>:normal,:elite=>false})
    allow_bonus=PMD_AC.loot_entry_allowed_v094(elite_row,{:rarity=>:rare,:elite=>true}) &&
      PMD_AC.loot_entry_allowed_v094(rare_row,{:rarity=>:rare,:elite=>true})
    pass=n0==2 && nr==3 && ne==4 && nb==5 && allow_normal && allow_bonus
    log_verify_v094('LOOT_CONTEXT_ROLLS_V094',pass,
      'normal='+n0.to_s+' rare='+nr.to_s+' rare_elite='+ne.to_s+' rare_elite_boss='+nb.to_s+
      ' context_filter=1 max=5')
    @verification_done[:v094_context]=true
  end

  def verify_loot_binding_policy_v094
    return if @verification_done[:v094_binding]
    a=PMD_AC.loot_pool_key_for_v094({:kind=>:scripted,:key=>:x,:options=>{:loot_pool=>:verifier_sample_v094}},nil)
    b=PMD_AC.loot_pool_key_for_v094({:kind=>:scripted,:key=>:x,:options=>{:loot_pool=>false}},nil)
    c=PMD_AC.loot_pool_key_for_v094({:kind=>:stage,:stage_id=>1,:key=>:stage_1,:options=>{}},1)
    pass=a==:verifier_sample_v094 && b==nil && c==nil && PMD_AC::LOOT_POOL_BINDINGS_V094.empty?
    log_verify_v094('LOOT_BINDING_POLICY_V094',pass,
      'direct='+a.to_s+' disable='+(b==nil ? 'nil':b.to_s)+' production_default='+(c==nil ? 'none':c.to_s)+
      ' priority=options>formation>encounter>region>stage')
    @verification_done[:v094_binding]=true
  end

  def verify_loot_economy_carry_v094
    return if @verification_done[:v094_carry]
    pass=PMD_AC::REWARD_LOOT_MANIFEST_V083[:types].size==7 &&
      PMD_AC::REGION_ECOLOGY_MANIFEST_V086[:formations]>=8 &&
      PMD_AC::COLLECTION_MANIFEST_V093[:species]==494 &&
      PMD_AC::BATTLE_REST_VISUAL_V094==:walk &&
      PMD_AC::SPATIAL_MOVE_EXTENSIONS_V0914.size==19
    log_verify_v094('LOOT_ECONOMY_CARRY_V094',pass,
      'reward=v0.83 region=v0.86 collection=v0.93 map=v0.92 tactical=v0.91.4 motion=v0.94 battle_rules=unchanged')
    @verification_done[:v094_carry]=true
  end

  def update_verification_script
    unless loot_economy_v094?
      pmd_ac_v094_update_verification_script
      return
    end
    return if @verification_done[:verification_complete]
    @verification_frame=@verification_frame.to_i+1
    f=@verification_frame
    verify_pmd_motion_idle_walk_v094 if f>=2
    verify_pmd_motion_contact_router_v094 if f>=4
    verify_loot_economy_manifest_v094 if f>=6
    verify_loot_pool_weighted_v094 if f>=8
    verify_loot_context_rolls_v094 if f>=10
    verify_loot_binding_policy_v094 if f>=12
    verify_loot_economy_carry_v094 if f>=14
    if f>=18 && !@verification_done[:v094_final]
      pass=!@loot_economy_failed_v094
      log_verify_v094('LOOT_ECONOMY_V094',pass,
        'motion_idle=walk motion_contact=hop_or_leap weighted=1 context=1 binding=1 carry=1 production_balance_unchanged=1')
      @verification_done[:v094_final]=true
    end
    complete_verification_mode if f>=PMD_AC::LOOT_ECONOMY_VERIFY_END_V094
  end
end
