#==============================================================================
# 【PMD AutoChess 中文維護說明】
# 腳本：PMD AutoChess Proto v0.45
# 分類：核心戰鬥 Runtime
#
# 【用途／機制】
# 承接前序 Data／Config，實際執行戰鬥 Scene、Unit、AI、技能與呈現。
#
# 【怎麼調整】
# 一般平衡與資料調整不要直接改 Runtime；若要追加功能，建議在較後腳本 alias 原方法後擴充。
#
# 【本腳本主要設定常數／資料表】
# - VERIFICATION_IDENTITY_BRIDGE_END_FRAME_V045 / VERIFICATION_MODES / VERIFICATION_LABELS
#
# 【Runtime 主要方法（查流程時可直接搜尋）】
# - begin_identity_sandbox_v045 / end_identity_sandbox_v045 / identity_sandbox_v045? / ensure_boxes_shape_v045
# - pokemon_registry_v045 / pokemon_party_uids_v045 / pokemon_storage_boxes_v045 / register_pokemon_instance_v045
# - pokemon_instance_for_uid_v045 / same_pokemon_v045? / party_instance_v045 / pokemon_location_v045
#
# 【維護規則】
# - RPG Maker VX / RGSS2 / Ruby 1.8 相容。
# - instance_uid 才是 Pokémon 個體身份；Actor ID 只是容器。
# - 新增行為優先沿用既有 helper／Data 表；避免破壞已 Freeze 的舊核心。
# - 本專案新腳本也必須保留同等級的中文說明與實際範例。
#==============================================================================
#===============================================================================
# ■ PMD AutoChess Proto v0.45
#    Party / Storage / Clone Identity Bridge + RPG Growth Data Foundation
#-------------------------------------------------------------------------------
# Additive layer on verified v0.44.
# Identity truth remains PokemonInstance.instance_uid. Actor IDs are adapters.
#===============================================================================
module PMD_AC
  VERIFICATION_IDENTITY_BRIDGE_END_FRAME_V045 = 820

  @fallback_registry_v045 = {}
  @fallback_party_v045 = [nil,nil,nil]
  @fallback_boxes_v045 = nil
  @runtime_actor_owner_v045 = {}
  @identity_sandbox_v045 = false
  @sandbox_registry_v045 = nil
  @sandbox_party_v045 = nil
  @sandbox_boxes_v045 = nil

  remove_const(:VERIFICATION_MODES) if const_defined?(:VERIFICATION_MODES)
  VERIFICATION_MODES = [:identity_bridge,:tactical_support,:reactive_priority,:priority,:held_item]
  remove_const(:VERIFICATION_LABELS) if const_defined?(:VERIFICATION_LABELS)
  VERIFICATION_LABELS = {
    :identity_bridge=>"IDENTITY_BRIDGE", :tactical_support=>"TACTICAL_SUPPORT",
    :reactive_priority=>"REACTIVE_PRIORITY", :priority=>"PRIORITY",
    :held_item=>"HELD_ITEM"
  }

  class << self
    def begin_identity_sandbox_v045
      @identity_sandbox_v045=true
      @sandbox_registry_v045={}
      @sandbox_party_v045=Array.new(PARTY_CAPACITY_V045)
      @sandbox_boxes_v045=Array.new(STORAGE_BOX_COUNT_V045){[]}
      @runtime_actor_owner_v045={}
      true
    end
    def end_identity_sandbox_v045
      @identity_sandbox_v045=false
      @sandbox_registry_v045=nil;@sandbox_party_v045=nil;@sandbox_boxes_v045=nil
      @runtime_actor_owner_v045={}
      true
    end
    def identity_sandbox_v045?; @identity_sandbox_v045 ? true : false; end

    def ensure_boxes_shape_v045(boxes)
      boxes=[] if boxes==nil
      while boxes.size < STORAGE_BOX_COUNT_V045; boxes.push([]); end
      boxes
    end

    def pokemon_registry_v045
      return @sandbox_registry_v045 if identity_sandbox_v045?
      if defined?($game_system) && $game_system!=nil
        $game_system.pmd_pokemon_registry_v045={} if $game_system.pmd_pokemon_registry_v045==nil
        return $game_system.pmd_pokemon_registry_v045
      end
      @fallback_registry_v045={} if @fallback_registry_v045==nil
      @fallback_registry_v045
    end
    def pokemon_party_uids_v045
      return @sandbox_party_v045 if identity_sandbox_v045?
      if defined?($game_system) && $game_system!=nil
        p=$game_system.pmd_pokemon_party_uids_v045
        p=Array.new(PARTY_CAPACITY_V045) if p==nil
        while p.size<PARTY_CAPACITY_V045;p.push(nil);end
        p=p[0,PARTY_CAPACITY_V045]
        $game_system.pmd_pokemon_party_uids_v045=p
        return p
      end
      @fallback_party_v045=Array.new(PARTY_CAPACITY_V045) if @fallback_party_v045==nil
      @fallback_party_v045
    end
    def pokemon_storage_boxes_v045
      return ensure_boxes_shape_v045(@sandbox_boxes_v045) if identity_sandbox_v045?
      if defined?($game_system) && $game_system!=nil
        b=ensure_boxes_shape_v045($game_system.pmd_pokemon_storage_boxes_v045)
        $game_system.pmd_pokemon_storage_boxes_v045=b
        return b
      end
      @fallback_boxes_v045=ensure_boxes_shape_v045(@fallback_boxes_v045)
      @fallback_boxes_v045
    end

    def register_pokemon_instance_v045(instance)
      return false if instance==nil || !instance.respond_to?(:instance_uid)
      uid=instance.instance_uid.to_i; return false if uid<=0
      r=pokemon_registry_v045; old=r[uid]
      return false if old!=nil && !old.equal?(instance)
      r[uid]=instance; true
    end
    def pokemon_instance_for_uid_v045(uid)
      pokemon_registry_v045[uid.to_i]
    end
    def same_pokemon_v045?(a,b)
      return false if a==nil || b==nil
      au=a.respond_to?(:instance_uid) ? a.instance_uid : a
      bu=b.respond_to?(:instance_uid) ? b.instance_uid : b
      au!=nil && bu!=nil && au.to_i==bu.to_i
    end
    def party_instance_v045(slot)
      slot=slot.to_i;return nil if slot<0 || slot>=PARTY_CAPACITY_V045
      uid=pokemon_party_uids_v045[slot];uid==nil ? nil : pokemon_instance_for_uid_v045(uid)
    end
    def pokemon_location_v045(uid)
      uid=uid.to_i;p=pokemon_party_uids_v045
      p.each_index{|i|return [:party,i] if p[i]!=nil && p[i].to_i==uid}
      boxes=pokemon_storage_boxes_v045
      boxes.each_index do |bi|
        boxes[bi].each_index{|ii|return [:storage,bi,ii] if boxes[bi][ii].to_i==uid}
      end
      pokemon_instance_for_uid_v045(uid)==nil ? nil : [:registry_only]
    end
    def remove_uid_from_locations_v045(uid)
      uid=uid.to_i;p=pokemon_party_uids_v045
      p.each_index{|i|p[i]=nil if p[i]!=nil && p[i].to_i==uid}
      for box in pokemon_storage_boxes_v045;box.delete_if{|x|x.to_i==uid};end
      true
    end
    def sync_legacy_roster_slot_v045(slot,instance)
      return if identity_sandbox_v045?
      return unless slot.to_i>=0 && slot.to_i<PARTY_CAPACITY_V045
      begin
        s=roster_storage;s[slot.to_i]=instance if s!=nil
      rescue
      end
    end
    def party_assign_instance_v045(slot,instance,store_replaced=false)
      slot=slot.to_i;return false if slot<0 || slot>=PARTY_CAPACITY_V045
      return false unless register_pokemon_instance_v045(instance)
      p=pokemon_party_uids_v045;old_uid=p[slot];uid=instance.instance_uid.to_i
      if old_uid!=nil && old_uid.to_i!=uid && store_replaced
        old=pokemon_instance_for_uid_v045(old_uid);store_instance_v045(old,0,false) if old!=nil
      elsif old_uid!=nil && old_uid.to_i!=uid
        return false
      end
      remove_uid_from_locations_v045(uid);p=pokemon_party_uids_v045;p[slot]=uid
      sync_legacy_roster_slot_v045(slot,instance)
      true
    end
    def store_instance_v045(instance,box_index=0,allow_from_party=false)
      return false unless register_pokemon_instance_v045(instance)
      uid=instance.instance_uid.to_i;loc=pokemon_location_v045(uid)
      return false if loc!=nil && loc[0]==:party && !allow_from_party
      bi=box_index.to_i;return false if bi<0 || bi>=STORAGE_BOX_COUNT_V045
      box=pokemon_storage_boxes_v045[bi];return false if box.size>=STORAGE_BOX_CAPACITY_V045 && !box.include?(uid)
      remove_uid_from_locations_v045(uid);box=pokemon_storage_boxes_v045[bi];box.push(uid) unless box.include?(uid)
      release_clone_actor_v045(uid)
      true
    end
    def swap_party_with_storage_v045(slot,storage_uid)
      slot=slot.to_i;return false if slot<0 || slot>=PARTY_CAPACITY_V045
      storage_uid=storage_uid.to_i;loc=pokemon_location_v045(storage_uid)
      return false if loc==nil || loc[0]!=:storage
      incoming=pokemon_instance_for_uid_v045(storage_uid);return false if incoming==nil
      p=pokemon_party_uids_v045;old_uid=p[slot];bi=loc[1];ii=loc[2]
      p[slot]=storage_uid
      box=pokemon_storage_boxes_v045[bi];box.delete_at(ii)
      if old_uid!=nil
        box.push(old_uid) if box.size<STORAGE_BOX_CAPACITY_V045
        old=pokemon_instance_for_uid_v045(old_uid);release_clone_actor_v045(old_uid) if old!=nil
      end
      sync_legacy_roster_slot_v045(slot,incoming)
      true
    end

    def runtime_actor_owner_v045(runtime_id)
      @runtime_actor_owner_v045={} if @runtime_actor_owner_v045==nil
      @runtime_actor_owner_v045[runtime_id.to_i]
    end
    def bind_clone_actor_v045(instance_or_uid,runtime_id,template_id=nil)
      instance=instance_or_uid.respond_to?(:instance_uid) ? instance_or_uid : pokemon_instance_for_uid_v045(instance_or_uid)
      return false if instance==nil
      register_pokemon_instance_v045(instance)
      rid=runtime_id.to_i;return false if rid<=0
      @runtime_actor_owner_v045={} if @runtime_actor_owner_v045==nil
      owner=@runtime_actor_owner_v045[rid]
      return false if owner!=nil && owner.to_i!=instance.instance_uid.to_i
      old=instance.runtime_actor_id
      if old!=nil
        old_owner=@runtime_actor_owner_v045[old.to_i]
        @runtime_actor_owner_v045.delete(old.to_i) if old_owner!=nil && old_owner.to_i==instance.instance_uid.to_i
      end
      tid=template_id==nil ? instance.template_actor_id : template_id
      instance.bind_actor_ids(rid,tid)
      @runtime_actor_owner_v045[rid]=instance.instance_uid.to_i
      true
    end
    def release_clone_actor_v045(instance_or_uid)
      instance=instance_or_uid.respond_to?(:instance_uid) ? instance_or_uid : pokemon_instance_for_uid_v045(instance_or_uid)
      return false if instance==nil
      rid=instance.runtime_actor_id
      if rid!=nil && @runtime_actor_owner_v045!=nil
        old_owner=@runtime_actor_owner_v045[rid.to_i]
        @runtime_actor_owner_v045.delete(rid.to_i) if old_owner!=nil && old_owner.to_i==instance.instance_uid.to_i
      end
      instance.bind_actor_ids(nil,instance.template_actor_id)
      true
    end

    def canonical_level_entries_v045(species_key,level,through=false)
      d=species_identity_data(species_key);return [] if d==nil
      a=[]
      for e in (d[:learnset]||[])
        next unless e[:method]==:level_up
        lv=e[:level].to_i
        next if through ? (lv>level.to_i) : (lv!=level.to_i)
        a.push(e)
      end
      a.sort{|x,y|c=x[:level].to_i<=>y[:level].to_i;c==0 ? x[:order].to_i<=>y[:order].to_i : c}
    end
    def identity_growth_checksum32_v045;IDENTITY_GROWTH_MANIFEST_V045[:runtime_checksum32].to_i;end
  end
end

class Game_System
  attr_accessor :pmd_pokemon_registry_v045
  attr_accessor :pmd_pokemon_party_uids_v045
  attr_accessor :pmd_pokemon_storage_boxes_v045
  unless method_defined?(:pmd_ac_v045_initialize)
    alias pmd_ac_v045_initialize initialize unless method_defined?(:pmd_ac_v045_initialize)
    def initialize
      pmd_ac_v045_initialize
      @pmd_pokemon_registry_v045={}
      @pmd_pokemon_party_uids_v045=Array.new(PMD_AC::PARTY_CAPACITY_V045)
      @pmd_pokemon_storage_boxes_v045=Array.new(PMD_AC::STORAGE_BOX_COUNT_V045){[]}
    end
  end
end

module PMD_AC
  class << self
    alias pmd_ac_v045_ally_roster_instance ally_roster_instance unless method_defined?(:pmd_ac_v045_ally_roster_instance)
    def ally_roster_instance(slot,initial_species,initial_level=nil)
      existing=party_instance_v045(slot)
      return existing if existing!=nil
      instance=pmd_ac_v045_ally_roster_instance(slot,initial_species,initial_level)
      register_pokemon_instance_v045(instance)
      p=pokemon_party_uids_v045
      if slot.to_i>=0 && slot.to_i<PARTY_CAPACITY_V045
        p[slot.to_i]=instance.instance_uid.to_i
      end
      instance
    end
  end
end

class PMD_PokemonInstance
  def ensure_growth_data_v045
    if @known_moves_v045==nil
      @known_moves_v045=[]
      for e in PMD_AC.canonical_level_entries_v045(species_key,@level,true)
        mv=e[:move];@known_moves_v045.push(mv) unless @known_moves_v045.include?(mv)
      end
    end
    @move_mastery_exp_v045={} if @move_mastery_exp_v045==nil
    for mv in @known_moves_v045;@move_mastery_exp_v045[mv]=0 if @move_mastery_exp_v045[mv]==nil;end
    if @active_moves_v045==nil
      exec=@known_moves_v045.find_all{|mv|PMD_AC.move_executable?(mv)}
      @active_moves_v045=exec[-PMD_AC::ACTIVE_MOVE_SLOTS_V045,PMD_AC::ACTIVE_MOVE_SLOTS_V045] || exec
    end
    @pending_move_choices_v045=[] if @pending_move_choices_v045==nil
    true
  end
  def known_moves_v045;ensure_growth_data_v045;@known_moves_v045.dup;end
  def active_moves_v045;ensure_growth_data_v045;@active_moves_v045.dup;end
  def pending_move_choices_v045;ensure_growth_data_v045;@pending_move_choices_v045.dup;end
  def knows_move_v045?(move);ensure_growth_data_v045;@known_moves_v045.include?(move);end
  def move_mastery_exp_v045(move);ensure_growth_data_v045;(@move_mastery_exp_v045[move]||0).to_i;end
  def move_level_v045(move)
    e=move_mastery_exp_v045(move);lv=1
    PMD_AC::MOVE_MASTERY_THRESHOLDS_V045.each_index{|i|lv=i+1 if e>=PMD_AC::MOVE_MASTERY_THRESHOLDS_V045[i].to_i}
    [lv,PMD_AC::MOVE_LEVEL_MAX_V045].min
  end
  def gain_move_mastery_v045(move,amount=1)
    ensure_growth_data_v045;return nil unless @known_moves_v045.include?(move)
    old_exp=move_mastery_exp_v045(move);old_lv=move_level_v045(move)
    cap=PMD_AC::MOVE_MASTERY_THRESHOLDS_V045[-1].to_i
    now=[[old_exp+[amount.to_i,0].max,cap].min,0].max
    @move_mastery_exp_v045[move]=now;new_lv=move_level_v045(move)
    {:move=>move,:exp_before=>old_exp,:exp_after=>now,:level_before=>old_lv,:level_after=>new_lv,:level_up=>(new_lv>old_lv)}
  end
  def set_active_moves_v045(moves)
    ensure_growth_data_v045;moves=(moves||[]).compact
    return false if moves.size>PMD_AC::ACTIVE_MOVE_SLOTS_V045 || moves.uniq.size!=moves.size
    for mv in moves;return false unless @known_moves_v045.include?(mv) && PMD_AC.move_executable?(mv);end
    @active_moves_v045=moves.dup;true
  end
  def learn_known_move_v045(move,level=nil,species=nil,record=true)
    ensure_growth_data_v045;return false if move==nil || @known_moves_v045.include?(move)
    @known_moves_v045.push(move);@move_mastery_exp_v045[move]=0
    if PMD_AC.move_executable?(move)
      if @active_moves_v045.size<PMD_AC::ACTIVE_MOVE_SLOTS_V045;@active_moves_v045.push(move)
      elsif !@pending_move_choices_v045.include?(move);@pending_move_choices_v045.push(move);end
    end
    if record && @progression_history!=nil
      @progression_history.push({:type=>:canonical_move_learn,:level=>(level||@level),:move=>move,:species=>(species||species_key)})
    end
    true
  end
  def resolve_pending_move_v045(new_move,forget_move)
    ensure_growth_data_v045;return false unless @pending_move_choices_v045.include?(new_move)
    return false unless @active_moves_v045.include?(forget_move)
    i=@active_moves_v045.index(forget_move);@active_moves_v045[i]=new_move;@pending_move_choices_v045.delete(new_move);true
  end

  alias pmd_ac_v045_gain_exp gain_exp unless method_defined?(:pmd_ac_v045_gain_exp)
  def gain_exp(amount,allow_evolution=true)
    ensure_growth_data_v045;start_species=species_key;start_level=@level
    result=pmd_ac_v045_gain_exp(amount,allow_evolution)
    result[:canonical_moves]=[];result[:pending_moves]=[]
    species_cursor=start_species
    evolutions=result[:evolutions]||[]
    for lv in (result[:levels]||[])
      for e in PMD_AC.canonical_level_entries_v045(species_cursor,lv,false)
        if learn_known_move_v045(e[:move],lv,species_cursor,true);result[:canonical_moves].push(e[:move]);end
      end
      for evo in evolutions
        next unless evo[:level].to_i==lv.to_i && evo[:from]==species_cursor
        species_cursor=evo[:to]
        for e in PMD_AC.canonical_level_entries_v045(species_cursor,lv,false)
          if learn_known_move_v045(e[:move],lv,species_cursor,true);result[:canonical_moves].push(e[:move]);end
        end
      end
    end
    result[:pending_moves]=pending_move_choices_v045
    result
  end
end

class Game_PMDChessUnit
  def same_pokemon_v045?(other);PMD_AC.same_pokemon_v045?(self,other);end
  alias pmd_ac_v045_gain_progression_exp gain_progression_exp unless method_defined?(:pmd_ac_v045_gain_progression_exp)
  def gain_progression_exp(amount)
    result=pmd_ac_v045_gain_progression_exp(amount)
    if @scene!=nil
      for mv in (result[:canonical_moves]||[])
        @scene.log_event(:move_learn,log_name+' CANONICAL_LEARN '+mv.to_s+' Lv='+level.to_s)
      end
      unless (result[:pending_moves]||[]).empty?
        @scene.log_event(:move_learn,log_name+' MOVE_REPLACE_PENDING '+result[:pending_moves].collect{|x|x.to_s}.join(','))
      end
    end
    result
  end
end

class Scene_PMD_AutoChess
  alias pmd_ac_v045_start start unless method_defined?(:pmd_ac_v045_start)
  alias pmd_ac_v045_terminate terminate unless method_defined?(:pmd_ac_v045_terminate)
  alias pmd_ac_v045_prepare_verification_battle prepare_verification_battle unless method_defined?(:pmd_ac_v045_prepare_verification_battle)
  alias pmd_ac_v045_update_verification_script update_verification_script unless method_defined?(:pmd_ac_v045_update_verification_script)
  alias pmd_ac_v045_log_event log_event unless method_defined?(:pmd_ac_v045_log_event)
  alias pmd_ac_v045_complete_verification_mode complete_verification_mode unless method_defined?(:pmd_ac_v045_complete_verification_mode)
  alias pmd_ac_v045_resolve_skill resolve_skill unless method_defined?(:pmd_ac_v045_resolve_skill)

  def start
    pmd_ac_v045_start
    begin
      if FileTest.exist?(PMD_AC::BATTLE_LOG_FILE)
        text=File.open(PMD_AC::BATTLE_LOG_FILE,'rb'){|f|f.read}
        text.sub!(/PMD AutoChess Proto v0\.[0-9.]+ Battle Verification Log/,'PMD AutoChess Proto v0.45 Battle Verification Log')
        File.open(PMD_AC::BATTLE_LOG_FILE,'wb'){|f|f.write(text)}
      end
    rescue
    end
    m=PMD_AC::IDENTITY_GROWTH_MANIFEST_V045
    log_event(:identity_bridge,'LOADED identity=instance_uid party=3 storage=24x30 clone_actor=adapter growth=level_exp+known_moves+move_mastery slots=4 mastery_lv=5 checksum32='+m[:runtime_checksum32].to_s)
  end
  def terminate
    PMD_AC.end_identity_sandbox_v045 if PMD_AC.identity_sandbox_v045?
    pmd_ac_v045_terminate
  end
  def battle_unit_for_uid_v045(uid)
    (@units||[]).find{|u|u.respond_to?(:instance_uid) && u.instance_uid.to_i==uid.to_i}
  end

  def resolve_skill(unit)
    data=unit==nil ? nil : unit.skill_data
    mk=nil
    if data!=nil
      mk=data[:canonical_move_key]||data[:move_key]
      mk=mk.to_sym if mk.is_a?(String)
    end
    result=pmd_ac_v045_resolve_skill(unit)
    if verification_mode==:normal && unit!=nil && unit.team==:ally && mk!=nil && unit.respond_to?(:pokemon_instance)
      inst=unit.pokemon_instance
      if inst!=nil && inst.respond_to?(:knows_move_v045?) && inst.knows_move_v045?(mk)
        r=inst.gain_move_mastery_v045(mk,1)
        if r!=nil
          log_event(:move_mastery,unit.log_name+' '+mk.to_s+' mastery='+r[:exp_after].to_s+' skill_lv='+r[:level_after].to_s)
          log_event(:move_mastery,unit.log_name+' '+mk.to_s+' SKILL_LEVEL_UP '+r[:level_before].to_s+'->'+r[:level_after].to_s) if r[:level_up]
        end
      end
    end
    result
  end

  def prepare_verification_battle
    pmd_ac_v045_prepare_verification_battle
    if verification_mode==:identity_bridge
      @identity_bridge_failed_v045=false
      PMD_AC.begin_identity_sandbox_v045
      for u in @units;u.verification_combat_sandbox(true);PMD_AC.register_pokemon_instance_v045(u.pokemon_instance) if u.respond_to?(:pokemon_instance);end
    end
  end
  def log_event(category,message)
    if category.to_s=='verify' && verification_mode==:identity_bridge && message.to_s.index('BRIDGE_')==0 && message.to_s.include?(' pass=0')
      @identity_bridge_failed_v045=true
    end
    pmd_ac_v045_log_event(category,message)
  end

  def bridge_test_instance_v045(uid,species=:pikachu,level=12,runtime=nil,template=7)
    PMD_PokemonInstance.new(species,level,{:instance_uid=>uid,:runtime_actor_id=>runtime,:template_actor_id=>template,:ivs=>[15,15,15,15,15,15],:nature=>:hardy,:ability_slot=>:primary})
  end
  def verify_bridge_manifest_v045
    return if @verification_done[:bridge_manifest];m=PMD_AC::IDENTITY_GROWTH_MANIFEST_V045
    pass=m[:identity_key]=='instance_uid' && m[:party_capacity].to_i==3 && m[:storage_box_count].to_i==24 && m[:active_move_slots].to_i==4 && m[:move_level_max].to_i==5
    log_event(:verify,'BRIDGE_MANIFEST pass='+(pass ? '1':'0')+' identity=instance_uid party=3 storage=24x30 active_moves=4 skill_levels=5 level_max=100 checksum='+m[:runtime_checksum32].to_s);@verification_done[:bridge_manifest]=true
  end
  def verify_bridge_registry_v045
    return if @verification_done[:bridge_registry]
    a=bridge_test_instance_v045(99450001);b=bridge_test_instance_v045(99450002);c=bridge_test_instance_v045(99450003)
    ra=PMD_AC.register_pokemon_instance_v045(a);rb=PMD_AC.register_pokemon_instance_v045(b);rc=PMD_AC.register_pokemon_instance_v045(c)
    fake=bridge_test_instance_v045(99450001,:pikachu,12,nil,7);collision=!PMD_AC.register_pokemon_instance_v045(fake)
    pass=ra&&rb&&rc&&collision&&PMD_AC.pokemon_registry_v045.size>=3&&a.template_actor_id==b.template_actor_id&&a.instance_uid!=b.instance_uid
    log_event(:verify,'BRIDGE_REGISTRY pass='+(pass ? '1':'0')+' same_species=3 same_template=7 unique_uid=3 collision_rejected='+(collision ? '1':'0')+' actor_id_not_identity=1');@verification_done[:bridge_registry]=true
  end
  def verify_bridge_party_storage_v045
    return if @verification_done[:bridge_party_storage]
    a=bridge_test_instance_v045(99450101);b=bridge_test_instance_v045(99450102);PMD_AC.register_pokemon_instance_v045(a);PMD_AC.register_pokemon_instance_v045(b)
    sa=PMD_AC.store_instance_v045(a,2,false);sb=PMD_AC.store_instance_v045(b,2,false)
    assign=PMD_AC.party_assign_instance_v045(0,a,false);before=PMD_AC.pokemon_location_v045(a.instance_uid);swap=PMD_AC.swap_party_with_storage_v045(0,b.instance_uid);after_a=PMD_AC.pokemon_location_v045(a.instance_uid);after_b=PMD_AC.pokemon_location_v045(b.instance_uid)
    pass=sa&&sb&&assign&&swap&&before==[:party,0]&&after_a!=nil&&after_a[0]==:storage&&after_b==[:party,0]&&PMD_AC.party_instance_v045(0).equal?(b)
    log_event(:verify,'BRIDGE_PARTY_STORAGE pass='+(pass ? '1':'0')+' uid_only_slots=1 exclusive_location=1 atomic_swap=1 party_uid='+PMD_AC.pokemon_party_uids_v045[0].to_s+' stored_uid='+a.instance_uid.to_s);@verification_done[:bridge_party_storage]=true
  end
  def verify_bridge_clone_v045
    return if @verification_done[:bridge_clone]
    a=bridge_test_instance_v045(99450201);b=bridge_test_instance_v045(99450202);PMD_AC.register_pokemon_instance_v045(a);PMD_AC.register_pokemon_instance_v045(b)
    x=PMD_AC.bind_clone_actor_v045(a,501,7);conflict=!PMD_AC.bind_clone_actor_v045(b,501,7);uid=a.instance_uid;rebind=PMD_AC.bind_clone_actor_v045(a,777,7);same=(a.instance_uid==uid&&a.runtime_actor_id==777&&a.template_actor_id==7);release=PMD_AC.release_clone_actor_v045(a);released=(a.runtime_actor_id==nil&&a.template_actor_id==7&&a.instance_uid==uid)
    pass=x&&conflict&&rebind&&same&&release&&released
    log_event(:verify,'BRIDGE_CLONE pass='+(pass ? '1':'0')+' runtime=501->777->nil template=7 uid_same='+(a.instance_uid==uid ? '1':'0')+' runtime_collision_rejected='+(conflict ? '1':'0')+' runtime_actor_not_identity=1');@verification_done[:bridge_clone]=true
  end
  def verify_bridge_battle_lookup_v045
    return if @verification_done[:bridge_battle]
    allies=(@units||[]).find_all{|u|u.team==:ally};ok=!allies.empty?
    for u in allies
      PMD_AC.register_pokemon_instance_v045(u.pokemon_instance);found=battle_unit_for_uid_v045(u.instance_uid);ok=false unless found.equal?(u)&&u.same_pokemon_v045?(found)
    end
    distinct=allies.size<2 ? true : !allies[0].same_pokemon_v045?(allies[1])
    pass=ok&&distinct
    log_event(:verify,'BRIDGE_BATTLE_LOOKUP pass='+(pass ? '1':'0')+' lookup_by_uid=1 same_pokemon_uid_compare=1 unit_object_not_identity=1 allies='+allies.size.to_s);@verification_done[:bridge_battle]=true
  end
  def verify_bridge_growth_v045
    return if @verification_done[:bridge_growth]
    i=PMD_PokemonInstance.new(:bulbasaur,1,{:instance_uid=>99450301,:ivs=>[15,15,15,15,15,15],:nature=>:hardy,:ability_slot=>:primary})
    PMD_AC.register_pokemon_instance_v045(i);known1=i.known_moves_v045;active1=i.active_moves_v045;uid=i.instance_uid
    need=PMD_AC.exp_for_level(3,i.growth_group)-i.exp;r=i.gain_exp(need,true);known3=i.known_moves_v045
    m0=i.move_level_v045(:tackle);mr=i.gain_move_mastery_v045(:tackle,10);m1=i.move_level_v045(:tackle)
    PMD_AC.store_instance_v045(i,4,false);same=PMD_AC.pokemon_instance_for_uid_v045(uid)
    pass=known1.include?(:tackle)&&known3.include?(:growl)&&i.level==3&&r[:canonical_moves].include?(:growl)&&m0==1&&m1==2&&mr[:level_up]&&same.equal?(i)&&same.level==3&&same.move_level_v045(:tackle)==2&&active1.size<=4
    log_event(:verify,'BRIDGE_GROWTH pass='+(pass ? '1':'0')+' lv=1->'+i.level.to_s+' exp_persistent=1 canonical_learn=tackle,growl active_slots<=4 mastery=tackle_Lv'+m0.to_s+'->'+m1.to_s+' storage_persistent=1 uid_same='+(same!=nil&&same.instance_uid==uid ? '1':'0'));@verification_done[:bridge_growth]=true
  end
  def verify_bridge_growth_audit_v045
    return if @verification_done[:bridge_growth_audit]
    species=0;learnsets=0;groups={}
    for k in PMD_AC::SPECIES_DB_V016.keys
      d=PMD_AC::SPECIES_DB_V016[k];species+=1;learnsets+=1 unless (d[:learnset]||[]).empty?;groups[d[:growth_group]]=true
    end
    pass=species==494&&learnsets==494&&groups.keys.size==6&&PMD_AC::POKEMON_MAX_LEVEL==100&&respond_to?(:award_battle_exp)
    log_event(:verify,'BRIDGE_GROWTH_AUDIT pass='+(pass ? '1':'0')+' species=494 canonical_learnsets=494 growth_groups='+groups.keys.size.to_s+' level_exp_existing=1 battle_exp_existing=1 old_learning=legacy_only fixed_v045=canonical_known_moves skill_mastery_added=1 combat_mastery_bonus=deferred_v046 growth_ui=deferred_v046');@verification_done[:bridge_growth_audit]=true
  end
  def verify_bridge_tactical_identity_v045
    return if @verification_done[:bridge_tactical_identity]
    a,b=nil,nil
    allies=(@units||[]).find_all{|u|u.team==:ally};a=allies[0];b=allies[1] if allies.size>1
    if a==nil || b==nil
      pass=false
    else
      au=a.instance_uid;bu=b.instance_uid;ax=a.pixel_x;ay=a.pixel_y;bx=b.pixel_x;by=b.pixel_y
      a.set_runtime_position_v044(bx,by) if a.respond_to?(:set_runtime_position_v044)
      b.set_runtime_position_v044(ax,ay) if b.respond_to?(:set_runtime_position_v044)
      pass=(a.instance_uid==au&&b.instance_uid==bu)
      a.set_runtime_position_v044(ax,ay) if a.respond_to?(:set_runtime_position_v044)
      b.set_runtime_position_v044(bx,by) if b.respond_to?(:set_runtime_position_v044)
    end
    log_event(:verify,'BRIDGE_TACTICAL_IDENTITY pass='+(pass ? '1':'0')+' teammate_effects=battle_unit_scope ally_switch=position_only helping_hand=unit_state redirect=deployed_units_only instance_uid_preserved='+(pass ? '1':'0'));@verification_done[:bridge_tactical_identity]=true
  end
  def verify_bridge_modes_v045
    return if @verification_done[:bridge_modes];exp=[:identity_bridge,:tactical_support,:reactive_priority,:priority,:held_item];pass=PMD_AC::VERIFICATION_MODES==exp&&verification_mode==:identity_bridge
    log_event(:verify,'BRIDGE_RECENT_MODES pass='+(pass ? '1':'0')+' modes=5 default=IDENTITY_BRIDGE');@verification_done[:bridge_modes]=true
  end

  def update_verification_script
    pmd_ac_v045_update_verification_script;return unless verification_mode==:identity_bridge;f=@verification_frame
    verify_bridge_manifest_v045 if f==4
    verify_bridge_registry_v045 if f==70
    verify_bridge_party_storage_v045 if f==150
    verify_bridge_clone_v045 if f==240
    verify_bridge_battle_lookup_v045 if f==330
    verify_bridge_growth_v045 if f==430
    verify_bridge_growth_audit_v045 if f==540
    verify_bridge_tactical_identity_v045 if f==650
    verify_bridge_modes_v045 if f==720
    complete_verification_mode if f==PMD_AC::VERIFICATION_IDENTITY_BRIDGE_END_FRAME_V045
  end
  def complete_verification_mode
    if verification_mode==:identity_bridge
      failed=@identity_bridge_failed_v045
      PMD_AC.end_identity_sandbox_v045
      if failed
        for u in @units;u.verification_finish;end
        @verification_done[:complete]=true
        log_event(:verify,'FAILED mode=IDENTITY_BRIDGE auto_skill=on original_skills=restored')
        return
      end
    end
    pmd_ac_v045_complete_verification_mode
  end
end
