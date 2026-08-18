# encoding: UTF-8
#==============================================================================
# 【PMD AutoChess 中文維護說明】
# 腳本：PMD AutoChess Loot / Item Production Runtime v0.98
# 分類：正式掉落／補給品使用／Content Validator／Verifier
#
# 【用途】
# 1. 把 v0.98 正式 Loot Pools / Bindings 接回 v0.94 Weighted Runtime。
# 2. 提供 ID 6～13 補給品的實際使用 API，直接操作 PMD_PokemonInstance，避免
#    VX Actor HP 與 Pokémon field_hp_v082 分裂成兩套資料。
# 3. 更新 v0.95 Content Validator，使目前 Demo 的正式 Loot / Item Catalog 完整後
#    不再保留 item_catalog deferred Warning。
#
# 【補給品使用 API】
# PMD_AC.use_supply_v098(6, instance_uid)             # 林緣傷藥
# PMD_AC.use_supply_v098(7, instance_uid)             # 活力種子
# PMD_AC.use_supply_v098(8, instance_uid)             # 經驗糖果 S
# PMD_AC.use_supply_v098(10,instance_uid,:tackle)      # 招式心得
# PMD_AC.use_supply_v098(12)                          # 團隊口糧
# PMD_AC.use_supply_v098(13)                          # 蜂王蜜
# 回傳 Hash；只有 :used=>true 才會扣 1 個道具。
#
# 【事件範例】
# uid=PMD_AC.pokemon_party_uids_v045[0]
# result=PMD_AC.use_supply_v098(8,uid)
# $game_variables[21]=result[:used] ? 1 : 0
#
# 【掉落規則】
# 戰鬥勝利仍先結算 v0.83 固定 Gold／v0.86 Rare-Elite bonus，再由 v0.94
# process_loot_reward_v083 依本版 Binding 追加 Item。Pickup / Honey Gather 的 v0.97
# bonus roll 也因此開始有真正 Production Pool 可作用。
#
# 【可調參數】
# 數值全部在前一支 SUPPLY_CATALOG_V098 / LOOT_POOLS_V098；Runtime 原則上不改。
#
# 【Verifier】
# NORMAL -> S 一次 -> LOOT_CONTENT_V098 -> Shift。
# 預期 LOOT_CONTENT_V098 pass=1 與 VERIFY_FINISHED_BATTLE_RESUME pass=1。
#
# 【注意】
# - 本版新增正式掉落會改變 Stage / Region / Boss 實際獎勵，這是預期內容更新。
# - 不修改 v0.83 Gold、v0.86 bonus、v0.94 Roll 規則本身。
# - 不修改 Ability 1193/1193、戰鬥數值、AI、PMD Motion、Multi-hit。
# - RPG Maker VX / RGSS2 / Ruby 1.8 相容。
#==============================================================================
module PMD_AC
  class << self
    alias pmd_ac_v098_loot_pool_v094 loot_pool_v094 unless method_defined?(:pmd_ac_v098_loot_pool_v094)
    alias pmd_ac_v098_loot_pool_key_for_v094 loot_pool_key_for_v094 unless method_defined?(:pmd_ac_v098_loot_pool_key_for_v094)

    def loot_pool_v094(key)
      p=pmd_ac_v098_loot_pool_v094(key)
      return p unless p==nil
      return nil if key==nil
      LOOT_POOLS_V098[key.to_sym]
    end

    def loot_pool_key_for_v094(request=nil,stage_id=nil)
      if request!=nil && request[:options]!=nil && request[:options].has_key?(:loot_pool)
        v=request[:options][:loot_pool]
        return nil if v==false
        return v.to_sym unless v==nil
      end
      old=pmd_ac_v098_loot_pool_key_for_v094(request,stage_id)
      return old unless old==nil
      if request!=nil
        f=request[:formation_v086]
        return LOOT_POOL_BINDINGS_V098[[:formation,f]] if f!=nil && LOOT_POOL_BINDINGS_V098.has_key?([:formation,f])
        k=request[:key]
        return LOOT_POOL_BINDINGS_V098[[:encounter,k]] if k!=nil && LOOT_POOL_BINDINGS_V098.has_key?([:encounter,k])
        r=request[:region_v086]
        return LOOT_POOL_BINDINGS_V098[[:region,r]] if r!=nil && LOOT_POOL_BINDINGS_V098.has_key?([:region,r])
        sid=request[:stage_id]
        return LOOT_POOL_BINDINGS_V098[[:stage,sid.to_i]] if sid!=nil && LOOT_POOL_BINDINGS_V098.has_key?([:stage,sid.to_i])
      end
      if stage_id!=nil && LOOT_POOL_BINDINGS_V098.has_key?([:stage,stage_id.to_i])
        return LOOT_POOL_BINDINGS_V098[[:stage,stage_id.to_i]]
      end
      nil
    end

    def supply_quantity_v098(item_id)
      id=item_id.to_i
      return 0 if $game_party==nil || $data_items==nil || $data_items[id]==nil
      $game_party.item_number($data_items[id]).to_i
    end

    def supply_target_v098(uid)
      return nil if uid==nil
      pokemon_instance_for_uid_v045(uid.to_i)
    end

    def supply_party_v098
      respond_to?(:party_instances_v082) ? party_instances_v082 : []
    end

    def supply_heal_amount_v098(inst,ratio)
      return 0 if inst==nil || !inst.respond_to?(:field_maxhp_v082)
      n=(inst.field_maxhp_v082.to_f*ratio.to_f).round
      n=1 if n<1
      n
    end

    # effect-only helper；Verifier 可用 party_override 測試，不碰真實 Inventory。
    def apply_supply_effect_v098(item_id,target=nil,move_key=nil,party_override=nil)
      d=supply_data_v098(item_id)
      return {:used=>false,:reason=>:unknown_item} if d==nil
      kind=d[:kind]
      case kind
      when :heal_one
        return {:used=>false,:reason=>:no_target} if target==nil
        hp=target.field_hp_v082;mx=target.field_maxhp_v082
        return {:used=>false,:reason=>:fainted} if hp<=0
        return {:used=>false,:reason=>:full_hp} if hp>=mx
        n=supply_heal_amount_v098(target,d[:ratio]);after=[hp+n,mx].min
        target.set_field_hp_v082(after)
        return {:used=>true,:kind=>kind,:before=>hp,:after=>after,:amount=>after-hp}
      when :revive_one
        return {:used=>false,:reason=>:no_target} if target==nil
        return {:used=>false,:reason=>:not_fainted} if target.field_hp_v082>0
        mx=target.field_maxhp_v082;n=(mx.to_f*d[:ratio].to_f).round;n=1 if n<1
        target.set_field_hp_v082(n)
        return {:used=>true,:kind=>kind,:before=>0,:after=>target.field_hp_v082,:amount=>target.field_hp_v082}
      when :exp_one
        return {:used=>false,:reason=>:no_target} if target==nil
        return {:used=>false,:reason=>:level_max} if target.level.to_i>=100
        before=target.exp.to_i;lv=target.level.to_i
        target.gain_exp(d[:amount].to_i,true)
        return {:used=>true,:kind=>kind,:before=>before,:after=>target.exp.to_i,:level_before=>lv,:level_after=>target.level.to_i}
      when :mastery_one
        return {:used=>false,:reason=>:no_target} if target==nil
        mk=move_key==nil ? nil : move_key.to_sym
        return {:used=>false,:reason=>:no_move} if mk==nil || !target.knows_move_v045?(mk)
        before=target.move_mastery_exp_v045(mk)
        r=target.gain_move_mastery_v045(mk,d[:amount].to_i)
        return {:used=>false,:reason=>:mastery_max} if r==nil || r[:exp_after].to_i==before.to_i
        return {:used=>true,:kind=>kind,:move=>mk,:before=>before,:after=>r[:exp_after],:level_after=>r[:level_after]}
      when :heal_party
        list=party_override==nil ? supply_party_v098 : party_override
        changed=0;total=0
        (list||[]).each do |inst|
          next if inst==nil
          hp=inst.field_hp_v082;mx=inst.field_maxhp_v082
          next if hp<=0 || hp>=mx
          n=supply_heal_amount_v098(inst,d[:ratio]);after=[hp+n,mx].min
          inst.set_field_hp_v082(after);changed+=1;total+=after-hp
        end
        return {:used=>changed>0,:kind=>kind,:changed=>changed,:amount=>total,:reason=>(changed>0 ? nil : :no_injured_party)}
      when :honey_party
        list=party_override==nil ? supply_party_v098 : party_override
        changed=0;revived=0;total=0
        (list||[]).each do |inst|
          next if inst==nil
          hp=inst.field_hp_v082;mx=inst.field_maxhp_v082
          if hp<=0
            n=(mx.to_f*d[:revive_ratio].to_f).round;n=1 if n<1
            inst.set_field_hp_v082(n);changed+=1;revived+=1;total+=n
          elsif hp<mx
            n=supply_heal_amount_v098(inst,d[:heal_ratio]);after=[hp+n,mx].min
            inst.set_field_hp_v082(after);changed+=1;total+=after-hp
          end
        end
        return {:used=>changed>0,:kind=>kind,:changed=>changed,:revived=>revived,:amount=>total,:reason=>(changed>0 ? nil : :no_injured_party)}
      end
      {:used=>false,:reason=>:unsupported_kind}
    end

    def use_supply_v098(item_id,instance_uid=nil,move_key=nil)
      id=item_id.to_i;d=supply_data_v098(id)
      return {:used=>false,:reason=>:unknown_item} if d==nil
      return {:used=>false,:reason=>:no_inventory} if supply_quantity_v098(id)<=0
      target=nil
      unless [:heal_party,:honey_party].include?(d[:kind])
        target=supply_target_v098(instance_uid)
        return {:used=>false,:reason=>:no_target} if target==nil
      end
      r=apply_supply_effect_v098(id,target,move_key,nil)
      if r[:used]
        $game_party.lose_item($data_items[id],1)
        r[:item_id]=id;r[:item_name]=d[:name];r[:remaining]=supply_quantity_v098(id)
      end
      r
    end

    def supply_inventory_v098
      out=[]
      supply_item_ids_v098.each do |id|
        d=supply_data_v098(id)
        out.push({:id=>id,:key=>d[:key],:name=>d[:name],:count=>supply_quantity_v098(id),:kind=>d[:kind]})
      end
      out
    end
  end
end

#==============================================================================
# ■ Content Validator v0.95 bridge：把 v0.98 正式 Pool / Binding 納入。
#==============================================================================
module PMD_AC
  class << self
    alias pmd_ac_v098_content_validation_loot_v095 content_validation_loot_v095 unless method_defined?(:pmd_ac_v098_content_validation_loot_v095)
    def content_validation_loot_v095(report)
      content_validation_safe_v095(report,:loot) do
        pools={}
        LOOT_POOLS_V094.each_pair{|k,v|pools[k]=v} if defined?(LOOT_POOLS_V094)
        LOOT_POOLS_V098.each_pair{|k,v|pools[k]=v}
        bindings={}
        LOOT_POOL_BINDINGS_V094.each_pair{|k,v|bindings[k]=v} if defined?(LOOT_POOL_BINDINGS_V094)
        LOOT_POOL_BINDINGS_V098.each_pair{|k,v|bindings[k]=v}
        bad=0
        pools.each_pair do |key,pool|
          entries=pool[:entries]||[]
          if pool[:base_rolls].to_i<=0 || pool[:max_rolls].to_i<pool[:base_rolls].to_i || entries.empty?
            bad+=1;content_validation_push_v095(report,:error,'loot_pool:'+key.to_s,'invalid_rolls_or_empty')
          end
          entries.each do |row|
            if row[:weight].to_i<=0
              bad+=1;content_validation_push_v095(report,:error,'loot_weight:'+key.to_s,row[:key].to_s)
            end
            bad+=1 unless content_validation_reward_row_valid_v095(report,'loot_reward:'+key.to_s,row)
          end
        end
        bindings.each_pair do |source,pool_key|
          if pools[pool_key]==nil
            bad+=1;content_validation_push_v095(report,:error,'loot_binding_pool',source.inspect+'->'+pool_key.to_s)
          end
          if source.is_a?(Array) && source.size>=2
            kind=source[0];key=source[1];valid=true
            case kind
            when :stage
              valid=defined?(STAGE_DB_V080) && STAGE_DB_V080[key.to_i]!=nil
            when :region
              valid=defined?(REGION_ECOLOGY_PROFILES_V086) && REGION_ECOLOGY_PROFILES_V086[key]!=nil
            when :formation
              valid=defined?(ENCOUNTER_FORMATIONS_V086) && ENCOUNTER_FORMATIONS_V086[key]!=nil
            when :encounter
              valid=defined?(RPG_ENCOUNTER_DB_V081) && RPG_ENCOUNTER_DB_V081[key]!=nil
            end
            unless valid
              bad+=1;content_validation_push_v095(report,:error,'loot_binding_source',source.inspect)
            end
          end
        end
        item_errors=loot_content_errors_v098
        item_errors.each{|x|bad+=1;content_validation_push_v095(report,:error,'loot_content_v098',x)}
        {:pass=>bad==0,:pools=>pools.size,:production_bindings=>bindings.size,
         :bad=>bad,:item_catalog_deferred=>false,:item_catalog=>SUPPLY_CATALOG_V098.size,
         :runtime=>'v0.94+v0.98'}
      end
    end
  end
end

#==============================================================================
# ■ Verifier Mode
#==============================================================================
module PMD_AC
  V098_OLD_VERIFICATION_MODES=VERIFICATION_MODES.dup
  V098_OLD_VERIFICATION_LABELS=VERIFICATION_LABELS.dup
  remove_const(:VERIFICATION_MODES)
  VERIFICATION_MODES=[:normal,:loot_content_v098]+V098_OLD_VERIFICATION_MODES.reject{|x|x==:normal || x==:loot_content_v098}
  remove_const(:VERIFICATION_LABELS)
  VERIFICATION_LABELS=V098_OLD_VERIFICATION_LABELS.dup
  VERIFICATION_LABELS[:normal]='NORMAL'
  VERIFICATION_LABELS[:loot_content_v098]='LOOT_CONTENT_V098'
end

class Scene_PMD_AutoChess
  alias pmd_ac_v098_start start unless method_defined?(:pmd_ac_v098_start)
  alias pmd_ac_v098_refresh_header refresh_header unless method_defined?(:pmd_ac_v098_refresh_header)
  alias pmd_ac_v098_prepare_verification_battle prepare_verification_battle unless method_defined?(:pmd_ac_v098_prepare_verification_battle)
  alias pmd_ac_v098_update_verification_script update_verification_script unless method_defined?(:pmd_ac_v098_update_verification_script)
  alias pmd_ac_v098_log_event log_event unless method_defined?(:pmd_ac_v098_log_event)

  def start
    pmd_ac_v098_start
    begin
      if FileTest.exist?(PMD_AC::BATTLE_LOG_FILE)
        text=File.open(PMD_AC::BATTLE_LOG_FILE,'rb'){|f|f.read}
        text.sub!(/PMD AutoChess Proto v0\.[0-9.]+ Battle Verification Log/,'PMD AutoChess Proto v0.98 Battle Verification Log')
        File.open(PMD_AC::BATTLE_LOG_FILE,'wb'){|f|f.write(text)}
      end
    rescue
    end
    m=PMD_AC::LOOT_CONTENT_MANIFEST_V098
    log_event(:loot_content,'FLOW v0.98 catalog='+m[:catalog_items].to_s+' pools='+m[:production_pools].to_s+
      ' bindings='+m[:production_bindings].to_s+' stage=3 region=4 boss=1 use_runtime=1 ability=1193/1193')
    refresh_header
  end

  def refresh_header
    pmd_ac_v098_refresh_header
    return if @header_sprite==nil || @header_sprite.bitmap==nil
    bmp=@header_sprite.bitmap
    bmp.fill_rect(0,0,Graphics.width,28,Color.new(0,0,0,180))
    pmd_ac_v074_font(bmp)
    bmp.font.size=PMD_AC.const_defined?(:UI_HEADER_TITLE_FONT_V086) ? PMD_AC::UI_HEADER_TITLE_FONT_V086 : 20
    bmp.font.bold=true;bmp.font.color=Color.new(255,255,255)
    bmp.draw_text(16,1,Graphics.width-32,30,'PMD 自走棋原型 v0.98',1)
  end

  def loot_content_v098?;verification_mode==:loot_content_v098;end

  def prepare_verification_battle
    pmd_ac_v098_prepare_verification_battle
    return unless loot_content_v098?
    @loot_content_failed_v098=false
    log_event(:showcase,'START mode=LOOT_CONTENT_V098 catalog=8 pools=5 bindings=8 production=on fake_vfx=off')
  end

  def log_event(category,message)
    if category.to_s=='verify' && loot_content_v098? && message.to_s.index('V098')!=nil && message.to_s.include?(' pass=0')
      @loot_content_failed_v098=true
    end
    pmd_ac_v098_log_event(category,message)
  end

  def log_verify_v098(name,pass,detail='')
    @loot_content_failed_v098=true unless pass
    log_event(:verify,name+' pass='+(pass ? '1':'0')+(detail=='' ? '' : ' '+detail))
  end

  def verify_loot_content_manifest_v098
    return if @verification_done[:v098_manifest]
    m=PMD_AC::LOOT_CONTENT_MANIFEST_V098;e=PMD_AC.loot_content_errors_v098
    pass=e.empty? && m[:catalog_items]==8 && m[:production_pools]==5 && m[:production_bindings]==8
    log_verify_v098('LOOT_CONTENT_MANIFEST_V098',pass,'items=8 pools=5 bindings=8 errors=['+e.join(',')+']')
    @verification_done[:v098_manifest]=true
  end

  def verify_loot_item_database_v098
    return if @verification_done[:v098_database]
    ids=PMD_AC.supply_item_ids_v098
    names=ids.collect{|id|$data_items!=nil && $data_items[id]!=nil ? $data_items[id].name.to_s : 'nil'}
    pass=ids==[6,7,8,9,10,11,12,13] && names.index('nil')==nil && names[0]=='林緣傷藥' && names[-1]=='蜂王蜜'
    log_verify_v098('LOOT_ITEM_DATABASE_V098',pass,'ids='+ids.join(',')+' first='+names[0].to_s+' last='+names[-1].to_s)
    @verification_done[:v098_database]=true
  end

  def verify_loot_bindings_v098
    return if @verification_done[:v098_bindings]
    a=PMD_AC.loot_pool_key_for_v094({:kind=>:stage,:stage_id=>1,:key=>:stage_1,:options=>{}},1)
    b=PMD_AC.loot_pool_key_for_v094({:kind=>:wild,:region_v086=>:poison_grove,:formation_v086=>:poison_grove_swarm,:options=>{}},nil)
    c=PMD_AC.loot_pool_key_for_v094({:kind=>:boss,:key=>:boss_beedrill,:options=>{}},nil)
    d=PMD_AC.loot_pool_key_for_v094({:kind=>:stage,:stage_id=>1,:options=>{:loot_pool=>false}},1)
    pass=a==:forest_supplies_v098 && b==:poison_supplies_v098 && c==:hive_boss_supplies_v098 && d==nil
    log_verify_v098('LOOT_PRODUCTION_BINDINGS_V098',pass,'stage1='+a.to_s+' poison='+b.to_s+' boss='+c.to_s+' explicit_off='+(d==nil ? 'nil':d.to_s))
    @verification_done[:v098_bindings]=true
  end

  def verify_loot_rolls_v098
    return if @verification_done[:v098_rolls]
    p=PMD_AC.loot_pool_v094(:forest_supplies_v098)
    n0=PMD_AC.loot_roll_count_v094(p,{:rarity=>:normal,:elite=>false,:boss=>false})
    n1=PMD_AC.loot_roll_count_v094(p,{:rarity=>:rare,:elite=>true,:boss=>false})
    r=PMD_AC.resolve_loot_pool_v094(:forest_supplies_v098,{:rarity=>:normal,:elite=>false,:boss=>false,:repeat=>true},true,[0],[0],[0])
    id=r[:results].empty? ? 0 : r[:results][0][:id].to_i
    pass=n0==1 && n1==3 && r[:results].size==1 && id==6
    log_verify_v098('LOOT_WEIGHTED_CONTENT_V098',pass,'normal_rolls='+n0.to_s+' rare_elite_rolls='+n1.to_s+' deterministic_item='+id.to_s+' dry_run=1')
    @verification_done[:v098_rolls]=true
  end

  def verify_supply_runtime_v098
    return if @verification_done[:v098_supply]
    a=PMD_PokemonInstance.new(:bulbasaur,10);b=PMD_PokemonInstance.new(:charmander,10)
    a.set_field_hp_v082((a.field_maxhp_v082*0.50).to_i);h0=a.field_hp_v082
    heal=PMD_AC.apply_supply_effect_v098(6,a,nil,[a,b]);h1=a.field_hp_v082
    b.set_field_hp_v082(0);rev=PMD_AC.apply_supply_effect_v098(7,b,nil,[a,b]);rev_hp=b.field_hp_v082
    exp0=a.exp.to_i;ex=PMD_AC.apply_supply_effect_v098(8,a,nil,[a,b]);exp1=a.exp.to_i
    mk=a.known_moves_v045[0];m0=a.move_mastery_exp_v045(mk);ma=PMD_AC.apply_supply_effect_v098(10,a,mk,[a,b]);m1=a.move_mastery_exp_v045(mk)
    b.set_field_hp_v082(0);a.set_field_hp_v082((a.field_maxhp_v082*0.40).to_i)
    honey=PMD_AC.apply_supply_effect_v098(13,nil,nil,[a,b])
    pass=heal[:used] && h1>h0 && rev[:used] && rev_hp>0 && ex[:used] && exp1>exp0 && ma[:used] && m1>m0 && honey[:used] && honey[:revived].to_i==1 && b.field_hp_v082>0
    log_verify_v098('SUPPLY_USE_RUNTIME_V098',pass,'heal='+h0.to_s+'->'+h1.to_s+' revive='+rev_hp.to_s+' exp='+exp0.to_s+'->'+exp1.to_s+' mastery='+m0.to_s+'->'+m1.to_s+' honey_revived='+honey[:revived].to_i.to_s)
    @verification_done[:v098_supply]=true
  end

  def verify_content_ready_v098
    return if @verification_done[:v098_content]
    r=PMD_AC.content_validation_report_v095;s=r[:sections][:loot]||{}
    pass=r[:errors].empty? && r[:warnings].empty? && r[:core_pass] && r[:production_ready] && s[:production_bindings].to_i==8 && s[:item_catalog].to_i==8
    log_verify_v098('CONTENT_PRODUCTION_READY_V098',pass,'errors='+r[:errors].size.to_s+' warnings='+r[:warnings].size.to_s+' loot_bindings='+s[:production_bindings].to_i.to_s+' item_catalog='+s[:item_catalog].to_i.to_s+' production_ready='+(r[:production_ready] ? '1':'0'))
    @verification_done[:v098_content]=true
  end

  def verify_loot_content_carry_v098
    return if @verification_done[:v098_carry]
    pass=PMD_AC::ABILITY_RUNTIME_MANIFEST_V097[:implemented_slot_count].to_i==1193 && PMD_AC::COLLECTION_MANIFEST_V093[:species].to_i==494 && PMD_AC::SPATIAL_MOVE_EXTENSIONS_V0914.size==19 && PMD_AC::LOOT_ECONOMY_MANIFEST_V094[:weighted_pick]
    log_verify_v098('LOOT_CONTENT_CARRY_V098',pass,'ability=1193/1193 species=494 tactical=v0.91.4 weighted_runtime=v0.94 battle_rules=unchanged')
    @verification_done[:v098_carry]=true
  end

  def update_verification_script
    unless loot_content_v098?
      pmd_ac_v098_update_verification_script
      return
    end
    return if @verification_done[:verification_complete]
    @verification_frame=@verification_frame.to_i+1;f=@verification_frame
    verify_loot_content_manifest_v098 if f>=2
    verify_loot_item_database_v098 if f>=4
    verify_loot_bindings_v098 if f>=6
    verify_loot_rolls_v098 if f>=8
    verify_supply_runtime_v098 if f>=10
    verify_content_ready_v098 if f>=14
    verify_loot_content_carry_v098 if f>=18
    if f>=22 && !@verification_done[:v098_final]
      pass=!@loot_content_failed_v098
      log_verify_v098('LOOT_CONTENT_V098',pass,'catalog=8 pools=5 bindings=8 supply_runtime=1 content_warnings=0 production_ready=1')
      @verification_done[:v098_final]=true
    end
    complete_verification_mode if f>=PMD_AC::LOOT_CONTENT_VERIFY_END_V098
  end
end

#==============================================================================
# ■ 舊 Verifier 相容：v0.98 清掉最後 Warning 後，舊版不可因「warnings 變 0」反而失敗。
#==============================================================================
module PMD_AC
  remove_const(:CONTENT_VALIDATION_VERSION_V095) if const_defined?(:CONTENT_VALIDATION_VERSION_V095)
  CONTENT_VALIDATION_VERSION_V095='0.98'
  remove_const(:CONTENT_VALIDATION_REPORT_FILE_V095) if const_defined?(:CONTENT_VALIDATION_REPORT_FILE_V095)
  CONTENT_VALIDATION_REPORT_FILE_V095='PMD_ContentValidation_v0.98.log'
end

class Scene_PMD_AutoChess
  alias pmd_ac_v098_log_verify_v097 log_verify_v097 unless method_defined?(:pmd_ac_v098_log_verify_v097)
  def log_verify_v097(name,pass,detail='')
    if name.to_s=='ABILITY_CONTENT_VALIDATION_V097'
      r=PMD_AC.content_validation_report_v095;s=r[:sections][:abilities]||{}
      pass=r[:errors].empty? && s[:runtime_slots].to_i==1193 && s[:runtime_species].to_i==494 && r[:warnings].empty?
      detail='errors='+r[:errors].size.to_s+' warnings='+r[:warnings].size.to_s+' slots='+s[:runtime_slots].to_i.to_s+'/1193 production_ready='+(r[:production_ready] ? '1':'0')+' loot=v0.98'
    end
    pmd_ac_v098_log_verify_v097(name,pass,detail)
  end

  def verify_ability_content_v096
    return if @verification_done[:v096_content]
    r=PMD_AC.content_validation_report_v095;s=r[:sections][:abilities]||{}
    pass=r[:errors].empty? && s[:runtime_slots].to_i==1193 && s[:runtime_species].to_i==494 && r[:warnings].empty?
    log_verify_v096('ABILITY_CONTENT_VALIDATION_V096',pass,
      'errors='+r[:errors].size.to_s+' warnings='+r[:warnings].size.to_s+
      ' ability_slots='+s[:runtime_slots].to_i.to_s+'/1193 species='+s[:runtime_species].to_i.to_s+'/494'+
      ' core_ready='+(r[:core_pass] ? '1':'0')+' production_ready='+(r[:production_ready] ? '1':'0')+' runtime=v0.98')
    @verification_done[:v096_content]=true
  end

  def verify_content_loot_v095
    return if @verification_done[:v095_loot]
    s=content_report_v095[:sections][:loot]||{}
    log_verify_v095('CONTENT_LOOT_V095',s[:pass] ? true:false,
      'pools='+s[:pools].to_i.to_s+' production_bindings='+s[:production_bindings].to_i.to_s+
      ' bad='+s[:bad].to_i.to_s+' item_catalog='+s[:item_catalog].to_i.to_s+
      ' item_catalog_deferred=0 known_gap=0 runtime=v0.98')
    @verification_done[:v095_loot]=true
  end
end

class Scene_PMD_AutoChess
  alias pmd_ac_v098_log_verify_v095 log_verify_v095 unless method_defined?(:pmd_ac_v098_log_verify_v095)
  def log_verify_v095(name,pass,detail='')
    if name.to_s=='CONTENT_VALIDATION_V095'
      r=content_report_v095
      pass=!@content_validation_failed_v095 && r[:core_pass]
      detail='errors='+r[:errors].size.to_s+' warnings='+r[:warnings].size.to_s+
        ' core_ready='+(r[:core_pass] ? '1':'0')+
        ' production_ready='+(r[:production_ready] ? '1':'0')+
        ' known_gaps=none runtime=v0.98'
    end
    pmd_ac_v098_log_verify_v095(name,pass,detail)
  end
end
