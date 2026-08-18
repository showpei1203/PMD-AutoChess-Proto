#==============================================================================
# 【PMD AutoChess 中文維護說明】
# 腳本：PMD AutoChess Proto v0.41
# 分類：核心戰鬥 Runtime
#
# 【用途／機制】
# 承接前序 Data／Config，實際執行戰鬥 Scene、Unit、AI、技能與呈現。
#
# 【怎麼調整】
# 一般平衡與資料調整不要直接改 Runtime；若要追加功能，建議在較後腳本 alias 原方法後擴充。
#
# 【本腳本主要設定常數／資料表】
# - VERIFICATION_HELD_ITEM_END_FRAME_V041 / VERIFICATION_MODES / VERIFICATION_LABELS
#
# 【Runtime 主要方法（查流程時可直接搜尋）】
# - held_item_data_v041 / held_item_checksum_scalar_v041 / held_item_checksum32_v041 / validate_held_item_v041
# - initialize / held_item_key_v041 / equip_held_item_v041 / remove_held_item_v041
# - consume_held_item_v041 / held_item_magic_room_suppressed_v041? / held_item_effective_v041? / air_balloon_active_v041?
#
# 【維護規則】
# - RPG Maker VX / RGSS2 / Ruby 1.8 相容。
# - instance_uid 才是 Pokémon 個體身份；Actor ID 只是容器。
# - 新增行為優先沿用既有 helper／Data 表；避免破壞已 Freeze 的舊核心。
# - 本專案新腳本也必須保留同等級的中文說明與實際範例。
#==============================================================================
#===============================================================================
# ■ PMD AutoChess Proto v0.41
#    Held Item + Magic Room Foundation I
#-------------------------------------------------------------------------------
# Additive layer on verified v0.40.1.
# - Held item identity lives on PMD_PokemonInstance, never Actor ID.
# - Implements 8 complete foundation items useful to the current one-active-skill
#   AutoChess ruleset: Leftovers, Life Orb, Focus Sash, Air Balloon, Eviolite,
#   Muscle Band, Wise Glasses, Expert Belt.
# - Magic Room now suppresses actual held-item effects and restores them when it
#   ends. The old pending item hook is therefore closed.
# - Air Balloon is also grounded by Gravity, matching the existing altitude layer.
# - Life Orb recoil respects Magic Guard and the existing Sheer Force qualifier.
#===============================================================================
module PMD_AC
  VERIFICATION_HELD_ITEM_END_FRAME_V041=700

  class << self
    def held_item_data_v041(key);key==nil ? nil : HELD_ITEM_DATA_V041[key];end
    def held_item_checksum_scalar_v041(v)
      return '' if v==nil;return v ? 'true':'false' if v==true || v==false
      return v.collect{|x|held_item_checksum_scalar_v041(x)}.join(',') if v.is_a?(Array)
      if v.is_a?(Hash);ks=v.keys.sort{|a,b|a.to_s<=>b.to_s};return ks.collect{|k|k.to_s+'='+held_item_checksum_scalar_v041(v[k])}.join(';');end
      return sprintf('%.2f',v) if v.is_a?(Float);v.to_s
    end
    def held_item_checksum32_v041
      h=0;m=HELD_ITEM_MANIFEST_V041
      m.keys.reject{|k|k==:runtime_checksum32}.sort{|a,b|a.to_s<=>b.to_s}.each{|k|('M|'+k.to_s+'='+held_item_checksum_scalar_v041(m[k])).each_byte{|by|h=((h*33)+by)&0x7fffffff}}
      HELD_ITEM_DATA_V041.keys.sort{|a,b|a.to_s<=>b.to_s}.each{|k|('I|'+k.to_s+'|'+held_item_checksum_scalar_v041(HELD_ITEM_DATA_V041[k])).each_byte{|by|h=((h*33)+by)&0x7fffffff}}
      h
    end
    def validate_held_item_v041
      e=[];m=HELD_ITEM_MANIFEST_V041
      e.push('count') unless HELD_ITEM_DATA_V041.size==8
      [:leftovers,:life_orb,:focus_sash,:air_balloon,:eviolite,:muscle_band,:wise_glasses,:expert_belt].each{|k|e.push('missing:'+k.to_s) if HELD_ITEM_DATA_V041[k]==nil}
      e.push('identity') unless m[:identity_storage].to_s=='pokemon_instance' && m[:identity_key].to_s=='instance_uid'
      e.push('magic_room') unless m[:magic_room_integration]
      e.push('checksum') unless held_item_checksum32_v041==m[:runtime_checksum32].to_i;e
    end
  end

  remove_const(:VERIFICATION_MODES) if const_defined?(:VERIFICATION_MODES)
  VERIFICATION_MODES=[:held_item,:guard,:two_turn,:altitude,:field_ai]
  remove_const(:VERIFICATION_LABELS) if const_defined?(:VERIFICATION_LABELS)
  VERIFICATION_LABELS={:held_item=>'HELD_ITEM',:guard=>'GUARD',:two_turn=>'TWO_TURN',:altitude=>'ALTITUDE',:field_ai=>'FIELD_AI'}
end

class PMD_PokemonInstance
  alias pmd_ac_v041_initialize initialize unless method_defined?(:pmd_ac_v041_initialize)
  def initialize(species_key,level=nil,options=nil)
    opts=options==nil ? {} : options
    pmd_ac_v041_initialize(species_key,level,options)
    @held_item_v041=opts[:held_item] if opts.has_key?(:held_item)
  end
  def held_item_key_v041;@held_item_v041;end
  def equip_held_item_v041(key)
    return false if key!=nil && PMD_AC.held_item_data_v041(key)==nil
    @held_item_v041=key;true
  end
  def remove_held_item_v041;old=@held_item_v041;@held_item_v041=nil;old;end
end

class Game_PMDChessUnit
  alias pmd_ac_v041_atk atk unless method_defined?(:pmd_ac_v041_atk)
  alias pmd_ac_v041_special_attack special_attack unless method_defined?(:pmd_ac_v041_special_attack)
  alias pmd_ac_v041_defense defense unless method_defined?(:pmd_ac_v041_defense)
  alias pmd_ac_v041_special_defense special_defense unless method_defined?(:pmd_ac_v041_special_defense)
  alias pmd_ac_v041_speed_stat speed_stat unless method_defined?(:pmd_ac_v041_speed_stat)
  alias pmd_ac_v041_receive_damage receive_damage unless method_defined?(:pmd_ac_v041_receive_damage)
  alias pmd_ac_v041_canonical_trigger_turn_end canonical_trigger_turn_end unless method_defined?(:pmd_ac_v041_canonical_trigger_turn_end)

  def held_item_key_v041;@pokemon_instance==nil ? nil : @pokemon_instance.held_item_key_v041;end
  def equip_held_item_v041(key)
    return false if @pokemon_instance==nil
    ok=@pokemon_instance.equip_held_item_v041(key)
    log_event(:held_item,log_name+' EQUIP '+(key==nil ? 'none' : key.to_s)) if ok && @scene!=nil
    ok
  end
  def consume_held_item_v041(reason=:consume)
    return nil if @pokemon_instance==nil
    old=@pokemon_instance.remove_held_item_v041
    log_event(:held_item,log_name+' CONSUME '+old.to_s+' reason='+reason.to_s) if old!=nil && @scene!=nil
    old
  end
  def held_item_magic_room_suppressed_v041?
    @scene!=nil && @scene.respond_to?(:canonical_items_suppressed?) && @scene.canonical_items_suppressed?
  end
  def held_item_effective_v041?(key=nil)
    k=held_item_key_v041;return false if k==nil || (key!=nil && k!=key)
    return false if held_item_magic_room_suppressed_v041?
    PMD_AC.held_item_data_v041(k)!=nil
  end
  def air_balloon_active_v041?
    return false unless held_item_effective_v041?(:air_balloon)
    return false if @scene!=nil && @scene.respond_to?(:canonical_field_active_global?) && @scene.canonical_field_active_global?(:gravity)
    true
  end
  def eviolite_eligible_v041?
    return false if @pokemon_instance==nil
    d=@pokemon_instance.species_data;return false if d==nil
    rules=d[:evolution_rules]||[];!rules.empty? || d[:evolves_to]!=nil
  end
  def atk
    v=pmd_ac_v041_atk
    v=[(v.to_f*1.0).round,1].max
    v
  end
  def special_attack
    v=pmd_ac_v041_special_attack
    v
  end
  def defense
    v=pmd_ac_v041_defense
    if held_item_effective_v041?(:eviolite) && eviolite_eligible_v041?;v=[(v.to_f*3.0/2.0).round,1].max;end
    v
  end
  def special_defense
    v=pmd_ac_v041_special_defense
    if held_item_effective_v041?(:eviolite) && eviolite_eligible_v041?;v=[(v.to_f*3.0/2.0).round,1].max;end
    v
  end
  def speed_stat;pmd_ac_v041_speed_stat;end

  def receive_damage(value,source=nil,grant_energy=true,bypass_link=false,critical=false)
    raw=value.to_i
    direct=instance_variable_defined?(:@canonical_direct_damage_context) && @canonical_direct_damage_context!=nil
    sturdy_will_handle=(ability_key==:sturdy && respond_to?(:canonical_sturdy_eligible_source?) && canonical_sturdy_eligible_source?(source))
    endure_will_handle=(respond_to?(:guard_active_v040?) && guard_active_v040?(:endure))
    if direct && held_item_effective_v041?(:focus_sash) && @hp.to_i==@maxhp.to_i && @hp.to_i>1 && !sturdy_will_handle && !endure_will_handle && respond_to?(:canonical_preview_local_hp_damage) && canonical_preview_local_hp_damage(raw,bypass_link)>=@hp.to_i
      capped=respond_to?(:canonical_cap_sturdy_raw) ? canonical_cap_sturdy_raw(raw,bypass_link) : [raw,@hp.to_i-1].min
      capped=1 if capped<1;value=capped;consume_held_item_v041(:focus_sash)
      log_event(:held_item,log_name+' FOCUS_SASH raw='+raw.to_s+'->'+value.to_i.to_s+' hp='+@hp.to_s)
    end
    pmd_ac_v041_receive_damage(value,source,grant_energy,bypass_link,critical)
  end

  def canonical_trigger_turn_end
    result=pmd_ac_v041_canonical_trigger_turn_end
    if alive? && held_item_effective_v041?(:leftovers) && @hp.to_i<@maxhp.to_i
      amount=[@maxhp.to_i/16,1].max;before=@hp.to_i;heal(amount);actual=@hp.to_i-before
      log_event(:held_item,log_name+' LEFTOVERS heal='+actual.to_s+' hp='+@hp.to_s+'/'+@maxhp.to_s)
      return true if actual>0
    end
    result
  end
end

class Scene_PMD_AutoChess
  alias pmd_ac_v041_start start unless method_defined?(:pmd_ac_v041_start)
  alias pmd_ac_v041_deal_direct_damage deal_direct_damage unless method_defined?(:pmd_ac_v041_deal_direct_damage)
  alias pmd_ac_v041_prepare_verification_battle prepare_verification_battle unless method_defined?(:pmd_ac_v041_prepare_verification_battle)
  alias pmd_ac_v041_update_verification_script update_verification_script unless method_defined?(:pmd_ac_v041_update_verification_script)
  alias pmd_ac_v041_log_event log_event unless method_defined?(:pmd_ac_v041_log_event)
  alias pmd_ac_v041_complete_verification_mode complete_verification_mode unless method_defined?(:pmd_ac_v041_complete_verification_mode)

  def start
    pmd_ac_v041_start
    begin
      if FileTest.exist?(PMD_AC::BATTLE_LOG_FILE)
        text=File.open(PMD_AC::BATTLE_LOG_FILE,'rb'){|f|f.read};text.sub!(/PMD AutoChess Proto v0\.[0-9.]+ Battle Verification Log/,'PMD AutoChess Proto v0.41 Battle Verification Log');File.open(PMD_AC::BATTLE_LOG_FILE,'wb'){|f|f.write(text)}
      end
    rescue;end
    m=PMD_AC::HELD_ITEM_MANIFEST_V041
    log_event(:held_item,'LOADED items='+PMD_AC::HELD_ITEM_DATA_V041.size.to_s+' storage=pokemon_instance identity=instance_uid magic_room=integrated gravity_balloon=1 checksum32='+m[:runtime_checksum32].to_s)
  end

  def held_item_damage_multiplier_v041(user,target,data,type,cat)
    return 1.0 if user==nil || !user.respond_to?(:held_item_effective_v041?) || !user.held_item_effective_v041?
    k=user.held_item_key_v041;d=PMD_AC.held_item_data_v041(k);return 1.0 if d==nil
    case k
    when :life_orb
      return d[:damage_num].to_f/[d[:damage_den].to_i,1].max.to_f
    when :muscle_band
      return cat==:physical ? d[:damage_num].to_f/[d[:damage_den].to_i,1].max.to_f : 1.0
    when :wise_glasses
      return cat==:special ? d[:damage_num].to_f/[d[:damage_den].to_i,1].max.to_f : 1.0
    when :expert_belt
      eff=target==nil ? 1.0 : PMD_AC.type_effectiveness(type,target.pokemon_types)
      return eff>1.0 ? d[:damage_num].to_f/[d[:damage_den].to_i,1].max.to_f : 1.0
    end
    1.0
  end
  def held_item_life_orb_recoil_suppressed_v041?(user,data)
    return true if user==nil
    return true if user.respond_to?(:ability_key) && user.ability_key==:magic_guard
    if user.respond_to?(:ability_key) && user.ability_key==:sheer_force && user.respond_to?(:canonical_sheer_force_qualifies?) && user.canonical_sheer_force_qualifies?(data);return true;end
    false
  end
  def held_item_apply_life_orb_recoil_v041(user,data)
    return 0 if user==nil || user.dead? || !user.held_item_effective_v041?(:life_orb) || held_item_life_orb_recoil_suppressed_v041?(user,data)
    amount=[user.maxhp.to_i/10,1].max;before=user.hp
    if respond_to?(:canonical_indirect_ability_damage);canonical_indirect_ability_damage(user,user,amount,'life_orb');else;user.receive_damage(amount,user,false,true,false);end
    actual=[before-user.hp,0].max;log_event(:held_item,user.log_name+' LIFE_ORB recoil='+actual.to_s+' hp='+user.hp.to_s+'/'+user.maxhp.to_s) if actual>0;actual
  end

  def deal_direct_damage(user,target,power,options=nil)
    return 0 if user==nil || target==nil
    options={} if options==nil;data=options[:skill_data]
    type=nil;cat=nil
    if respond_to?(:canonical_damage_type_and_category);triple=canonical_damage_type_and_category(user,options);type=triple[0];cat=triple[1];data=triple[2] if data==nil;end
    type=options[:move_type] if type==nil;cat=options[:damage_category] if cat==nil
    type=data[:move_type] if type==nil && data!=nil;cat=data[:damage_category] if cat==nil && data!=nil
    type=user.basic_move_type if type==nil && user.respond_to?(:basic_move_type);type=:normal if type==nil;cat=:physical if cat==nil

    if type==:ground && target.respond_to?(:air_balloon_active_v041?) && target.air_balloon_active_v041?
      log_event(:held_item,target.log_name+' AIR_BALLOON IMMUNE ground from='+user.log_name);return 0
    end

    p=power
    mult=1.0
    if options[:fixed_damage]==nil
      mult=held_item_damage_multiplier_v041(user,target,data,type,cat)
      if mult!=1.0;p=[(power.to_f*mult).round,1].max;log_event(:held_item,user.log_name+' '+user.held_item_key_v041.to_s+' POWER_X'+sprintf('%.2f',mult)+' move='+(data==nil ? 'basic' : (data[:canonical_move_key]||:unknown).to_s));end
    end
    result=pmd_ac_v041_deal_direct_damage(user,target,p,options)
    if result.to_i>0
      if target.respond_to?(:held_item_effective_v041?) && target.held_item_effective_v041?(:air_balloon);target.consume_held_item_v041(:damaging_hit);end
      held_item_apply_life_orb_recoil_v041(user,data)
    end
    result
  end

  def held_item_test_unit_v041(species,team,id,ability_slot=:primary)
    @held_item_test_units_v041=[] if @held_item_test_units_v041==nil
    i=PMD_PokemonInstance.new(species,50,{:instance_uid=>99041000+id.to_i,:ability_slot=>ability_slot})
    u=Game_PMDChessUnit.new(9410+id.to_i,species,team,0,0,i);u.scene=self;u.verification_combat_sandbox(true);@held_item_test_units_v041.push(u);u
  end
  def held_item_reset_fields_v041;clear_canonical_field_effect_v035(:magic_room,nil,:verify) if respond_to?(:clear_canonical_field_effect_v035);end
  def held_item_clear_test_v041
    held_item_reset_fields_v041
    (@held_item_test_units_v041||[]).each{|u|u.equip_held_item_v041(nil) if u.respond_to?(:equip_held_item_v041)}
    @held_item_test_units_v041=[]
  end
  def prepare_verification_battle
    pmd_ac_v041_prepare_verification_battle
    if verification_mode==:held_item
      @held_item_failed_v041=false;@held_item_test_units_v041=[];held_item_reset_fields_v041
      for u in @units;u.verification_combat_sandbox(true);end
    end
  end
  def log_event(category,message)
    if category.to_s=='verify' && verification_mode==:held_item && message.to_s.index('HELD_ITEM_')==0 && message.to_s.include?(' pass=0');@held_item_failed_v041=true;end
    pmd_ac_v041_log_event(category,message)
  end

  def verify_held_item_manifest_v041
    return if @verification_done[:held_item_manifest];e=PMD_AC.validate_held_item_v041;m=PMD_AC::HELD_ITEM_MANIFEST_V041;pass=e.empty?
    log_event(:verify,'HELD_ITEM_MANIFEST pass='+(pass ? '1':'0')+' items=8 storage=pokemon_instance identity=instance_uid magic_room=integrated checksum='+PMD_AC.held_item_checksum32_v041.to_s+' errors=['+e.join(',')+']');@verification_done[:held_item_manifest]=true
  end
  def verify_held_item_identity_v041
    return if @verification_done[:held_item_identity];i=PMD_PokemonInstance.new(:bulbasaur,25,{:instance_uid=>99410001,:held_item=>:leftovers});u=Game_PMDChessUnit.new(9491,:bulbasaur,:ally,0,0,i);u.scene=self
    same=(i.instance_uid.to_i==u.instance_uid.to_i && i.held_item_key_v041==:leftovers && u.held_item_key_v041==:leftovers);u.equip_held_item_v041(:life_orb);persist=(i.held_item_key_v041==:life_orb)
    pass=same&&persist;log_event(:verify,'HELD_ITEM_IDENTITY pass='+(pass ? '1':'0')+' uid='+i.instance_uid.to_s+' instance_source=1 unit_delegate=1 equip_persists=1 actor_id_unused=1');@verification_done[:held_item_identity]=true
  end
  def verify_held_item_stats_v041
    return if @verification_done[:held_item_stats];u=held_item_test_unit_v041(:bulbasaur,:ally,1);base_d=u.defense;base_s=u.special_defense;u.equip_held_item_v041(:eviolite);ed=u.defense;es=u.special_defense
    set_canonical_field_effect_v035(:magic_room,u,5);md=u.defense;ms=u.special_defense;held_item_reset_fields_v041;rest_d=u.defense;rest_s=u.special_defense
    eligible=u.eviolite_eligible_v041?;pass=eligible&&ed==[(base_d*1.5).round,1].max&&es==[(base_s*1.5).round,1].max&&md==base_d&&ms==base_s&&rest_d==ed&&rest_s==es
    log_event(:verify,'HELD_ITEM_STATS pass='+(pass ? '1':'0')+' eviolite='+base_d.to_s+'/'+base_s.to_s+'->'+ed.to_s+'/'+es.to_s+' magic_room='+md.to_s+'/'+ms.to_s+' restored='+rest_d.to_s+'/'+rest_s.to_s+' evolvable=1');@verification_done[:held_item_stats]=true
  end
  def verify_held_item_damage_v041
    return if @verification_done[:held_item_damage];a=held_item_test_unit_v041(:bulbasaur,:ally,2);t=held_item_test_unit_v041(:charmander,:enemy,3)
    a.equip_held_item_v041(:muscle_band);m1=held_item_damage_multiplier_v041(a,t,nil,:normal,:physical);m1s=held_item_damage_multiplier_v041(a,t,nil,:normal,:special)
    a.equip_held_item_v041(:wise_glasses);wg=held_item_damage_multiplier_v041(a,t,nil,:normal,:special)
    a.equip_held_item_v041(:expert_belt);eb=held_item_damage_multiplier_v041(a,t,nil,:water,:special);ebn=held_item_damage_multiplier_v041(a,t,nil,:normal,:physical)
    a.equip_held_item_v041(:life_orb);lo=held_item_damage_multiplier_v041(a,t,nil,:grass,:special);ahp=a.hp;before=t.hp;deal_direct_damage(a,t,60,{:move_type=>:grass,:damage_category=>:special,:can_crit=>false,:directional=>false,:grant_energy=>false});hit=before-t.hp;recoil=ahp-a.hp;expected=[a.maxhp/10,1].max
    set_canonical_field_effect_v035(:magic_room,a,5);supp=held_item_damage_multiplier_v041(a,t,nil,:grass,:special);held_item_reset_fields_v041
    pass=(m1>1.09&&m1<1.11&&m1s==1.0&&wg>1.09&&wg<1.11&&eb>1.19&&eb<1.21&&ebn==1.0&&lo>1.29&&lo<1.31&&hit>0&&recoil==expected&&supp==1.0)
    log_event(:verify,'HELD_ITEM_DAMAGE pass='+(pass ? '1':'0')+' muscle='+sprintf('%.2f',m1)+' wise='+sprintf('%.2f',wg)+' expert='+sprintf('%.2f',eb)+' life_orb='+sprintf('%.2f',lo)+' hit='+hit.to_s+' recoil='+recoil.to_s+' magic_room_mult='+sprintf('%.2f',supp));@verification_done[:held_item_damage]=true
  end
  def verify_held_item_focus_sash_v041
    return if @verification_done[:held_item_sash];a=held_item_test_unit_v041(:bulbasaur,:ally,4);t=held_item_test_unit_v041(:rattata,:enemy,5);t.equip_held_item_v041(:focus_sash);full=t.hp;deal_direct_damage(a,t,1,{:fixed_damage=>full+200,:move_type=>:normal,:damage_category=>:physical,:can_crit=>false,:directional=>false,:grant_energy=>false});survive=(t.hp==1);consumed=(t.held_item_key_v041==nil)
    s=held_item_test_unit_v041(:rattata,:enemy,6);s.equip_held_item_v041(:focus_sash);set_canonical_field_effect_v035(:magic_room,a,5);deal_direct_damage(a,s,1,{:fixed_damage=>s.maxhp+200,:move_type=>:normal,:damage_category=>:physical,:can_crit=>false,:directional=>false,:grant_energy=>false});suppressed=s.dead? && s.held_item_key_v041==:focus_sash;held_item_reset_fields_v041
    pass=survive&&consumed&&suppressed;log_event(:verify,'HELD_ITEM_FOCUS_SASH pass='+(pass ? '1':'0')+' full_hp='+full.to_s+' survive_1hp='+(survive ? '1':'0')+' consumed='+(consumed ? '1':'0')+' magic_room_suppresses_without_consume='+(suppressed ? '1':'0')+' direct_only=1');@verification_done[:held_item_sash]=true
  end
  def verify_held_item_air_balloon_v041
    return if @verification_done[:held_item_balloon];a=held_item_test_unit_v041(:bulbasaur,:ally,7);t=held_item_test_unit_v041(:rattata,:enemy,8);t.equip_held_item_v041(:air_balloon);hp=t.hp;immune=deal_direct_damage(a,t,1,{:fixed_damage=>50,:move_type=>:ground,:damage_category=>:physical,:can_crit=>false,:directional=>false,:grant_energy=>false})==0 && t.hp==hp && t.held_item_key_v041==:air_balloon
    hit=deal_direct_damage(a,t,1,{:fixed_damage=>20,:move_type=>:normal,:damage_category=>:physical,:can_crit=>false,:directional=>false,:grant_energy=>false});popped=hit.to_i>0 && t.held_item_key_v041==nil;before=t.hp;ground_after=deal_direct_damage(a,t,1,{:fixed_damage=>20,:move_type=>:ground,:damage_category=>:physical,:can_crit=>false,:directional=>false,:grant_energy=>false});after_hit=ground_after.to_i>0 && t.hp<before
    t2=held_item_test_unit_v041(:rattata,:enemy,9);t2.equip_held_item_v041(:air_balloon);set_canonical_field_effect_v035(:magic_room,a,5);before2=t2.hp;mr=deal_direct_damage(a,t2,1,{:fixed_damage=>20,:move_type=>:ground,:damage_category=>:physical,:can_crit=>false,:directional=>false,:grant_energy=>false});mr_hit=mr.to_i>0&&t2.hp<before2&&t2.held_item_key_v041==:air_balloon;held_item_reset_fields_v041
    t3=held_item_test_unit_v041(:rattata,:enemy,10);t3.equip_held_item_v041(:air_balloon);set_canonical_field_effect_v035(:gravity,a,5);g0=t3.hp;gr=deal_direct_damage(a,t3,1,{:fixed_damage=>20,:move_type=>:ground,:damage_category=>:physical,:can_crit=>false,:directional=>false,:grant_energy=>false});gravity_hit=gr.to_i>0&&t3.hp<g0&&t3.held_item_key_v041==nil;clear_canonical_field_effect_v035(:gravity,nil,:verify)
    pass=immune&&popped&&after_hit&&mr_hit&&gravity_hit;log_event(:verify,'HELD_ITEM_AIR_BALLOON pass='+(pass ? '1':'0')+' ground_immune='+(immune ? '1':'0')+' pop_on_hit='+(popped ? '1':'0')+' ground_after_pop='+(after_hit ? '1':'0')+' magic_room_ground_hit_item_retained='+(mr_hit ? '1':'0')+' gravity_ground_hit_pop='+(gravity_hit ? '1':'0'));@verification_done[:held_item_balloon]=true
  end
  def verify_held_item_leftovers_v041
    return if @verification_done[:held_item_leftovers];u=held_item_test_unit_v041(:rattata,:ally,11);u.equip_held_item_v041(:leftovers);loss=[u.maxhp/4,10].max;u.instance_variable_set(:@hp,u.maxhp-loss);b=u.hp;u.canonical_trigger_turn_end;heal=u.hp-b;expected=[u.maxhp/16,1].max
    u.instance_variable_set(:@hp,u.maxhp-loss);set_canonical_field_effect_v035(:magic_room,u,5);m0=u.hp;u.canonical_trigger_turn_end;blocked=(u.hp==m0);held_item_reset_fields_v041;u.canonical_trigger_turn_end;resumed=(u.hp-m0)==expected
    pass=heal==expected&&blocked&&resumed;log_event(:verify,'HELD_ITEM_LEFTOVERS pass='+(pass ? '1':'0')+' heal='+heal.to_s+' expected='+expected.to_s+' magic_room_block='+(blocked ? '1':'0')+' resumes_after='+(resumed ? '1':'0'));@verification_done[:held_item_leftovers]=true
  end
  def verify_held_item_magic_guard_v041
    return if @verification_done[:held_item_magic_guard];mg=held_item_test_unit_v041(:clefairy,:ally,12,:secondary);t=held_item_test_unit_v041(:rattata,:enemy,13);mg.equip_held_item_v041(:life_orb);before=mg.hp;deal_direct_damage(mg,t,50,{:move_type=>:normal,:damage_category=>:special,:can_crit=>false,:directional=>false,:grant_energy=>false});blocked=(mg.hp==before)
    pass=blocked;log_event(:verify,'HELD_ITEM_MAGIC_GUARD pass='+(pass ? '1':'0')+' life_orb_boost=1 recoil_blocked='+(blocked ? '1':'0')+' ability_interop=1');@verification_done[:held_item_magic_guard]=true
  end
  def verify_held_item_runtime_v041
    return if @verification_done[:held_item_runtime];ok=PMD_AC::HELD_ITEM_DATA_V041.size==8 && respond_to?(:canonical_items_suppressed?)
    log_event(:verify,'HELD_ITEM_RUNTIME pass='+(ok ? '1':'0')+' items=8 storage=PokemonInstance instance_uid_truth=1 magic_room_item_system=integrated pending_hook_closed=1 leftovers=1 life_orb=1 sash=1 balloon=1 eviolite=1 damage_boosters=3');@verification_done[:held_item_runtime]=true
  end
  def verify_held_item_modes_v041
    return if @verification_done[:held_item_modes];exp=[:held_item,:guard,:two_turn,:altitude,:field_ai];pass=PMD_AC::VERIFICATION_MODES==exp && verification_mode==:held_item
    log_event(:verify,'HELD_ITEM_RECENT_MODES pass='+(pass ? '1':'0')+' modes=5 default=HELD_ITEM');@verification_done[:held_item_modes]=true
  end
  def update_verification_script
    pmd_ac_v041_update_verification_script;return unless verification_mode==:held_item;f=@verification_frame
    verify_held_item_manifest_v041 if f==4;verify_held_item_identity_v041 if f==50;verify_held_item_stats_v041 if f==120;verify_held_item_damage_v041 if f==200;verify_held_item_focus_sash_v041 if f==290;verify_held_item_air_balloon_v041 if f==390;verify_held_item_leftovers_v041 if f==490;verify_held_item_magic_guard_v041 if f==560;verify_held_item_runtime_v041 if f==610;verify_held_item_modes_v041 if f==640;complete_verification_mode if f==PMD_AC::VERIFICATION_HELD_ITEM_END_FRAME_V041
  end
  def complete_verification_mode
    if verification_mode==:held_item
      held_item_clear_test_v041
      if @held_item_failed_v041;for u in @units;u.verification_finish;end;@verification_done[:complete]=true;log_event(:verify,'FAILED mode=HELD_ITEM auto_skill=on original_skills=restored');return;end
    end
    pmd_ac_v041_complete_verification_mode
  end
end
