# encoding: UTF-8
#===============================================================================
# ■ PMD AutoChess - Additional Spawn Materialization v1.05.47
#===============================================================================
# 【目的】
# Phase D-II：關閉 v0.77 明確標示 deferred 的 additional_spawn evolution。
# v0.16.1 已能在 Nincada -> Ninjask evolution event 產生 [:shedinja] 描述，
# 但歷代 Runtime 沒有 consumer 將描述實體化為持久 PMD_PokemonInstance。
#
# 【正式政策】
# - additional spawn 一律建立全新 instance_uid；Actor ID 仍不是身份。
# - 優先放入第一個空 Party slot；Party 滿則放第一個有空位的 BOX。
# - Party + 全 BOX 都滿時保留 pending descriptor，不吞掉取得事件。
# - Spawn 繼承來源個體 IV / Nature / Known Move Library / Mastery / Active Slots / Pending Move。
# - 不複製 Held Item；Ability 由 target species 自己的 default slot 決定。
# - 現行唯一規則為 Nincada Lv20 -> Shedinja；實作保持 generic descriptor consumer。
#
# 【不改】
# EXP、進化門檻、Ninjask 主進化、branch choice、Move damage、Energy、AI、戰鬥節奏。
#===============================================================================
$imported={} unless defined?($imported)
$imported['PMD_AutoChess_AdditionalSpawnMaterialization_v10547']=true

module PMD_AC
  ADDITIONAL_SPAWN_POLICY_V10547={
    :version=>'1.05.47',
    :authority=>:additional_spawn_materialization,
    :identity=>:new_instance_uid,
    :party_first=>true,
    :storage_fallback=>true,
    :full_capacity=>:persistent_pending_descriptor,
    :inherit=>[:ivs,:nature,:known_moves,:move_mastery,:active_moves,:pending_moves],
    :held_item_copy=>false,
    :target_default_ability=>true,
    :current_rule=>[:nincada,:ninjask,:shedinja,20]
  }

  class << self
    def additional_spawn_destination_v10547
      p=pokemon_party_uids_v045
      p.each_index{|i|return [:party,i] if p[i]==nil}
      boxes=pokemon_storage_boxes_v045
      boxes.each_index do |bi|
        return [:storage,bi] if boxes[bi].size<STORAGE_BOX_CAPACITY_V045
      end
      nil
    rescue
      nil
    end

    def allocate_registry_unique_uid_v10547
      4096.times do
        uid=allocate_temporary_instance_uid.to_i
        return uid if uid>0 && pokemon_instance_for_uid_v045(uid)==nil
      end
      nil
    rescue
      nil
    end

    def place_additional_spawn_instance_v10547(instance,dest)
      return false if instance==nil || dest==nil
      if dest[0]==:party
        return party_assign_instance_v045(dest[1],instance,false)
      elsif dest[0]==:storage
        return store_instance_v045(instance,dest[1],false)
      end
      false
    rescue
      false
    end

    def flush_registry_additional_spawns_v10547
      result=[]
      begin
        pokemon_registry_v045.values.each do |inst|
          next unless inst.respond_to?(:flush_pending_additional_spawns_v10547)
          a=inst.flush_pending_additional_spawns_v10547
          result.concat(a) if a!=nil
        end
      rescue
      end
      result
    end
  end
end

class PMD_PokemonInstance
  def pending_additional_spawns_v10547
    @pending_additional_spawns_v10547=[] if @pending_additional_spawns_v10547==nil
    @pending_additional_spawns_v10547.collect{|x|x.dup}
  end

  def build_additional_spawn_v10547(desc)
    target=desc[:target]
    level=(desc[:level]||@level).to_i
    dest=PMD_AC.additional_spawn_destination_v10547
    return {:status=>:pending,:target=>target,:level=>level,:reason=>:capacity_full} if dest==nil
    uid=PMD_AC.allocate_registry_unique_uid_v10547
    return {:status=>:pending,:target=>target,:level=>level,:reason=>:uid_unavailable} if uid==nil

    opts={:instance_uid=>uid}
    begin opts[:ivs]=ivs; rescue; end
    begin opts[:nature]=nature_key; rescue; end
    begin opts[:ability_slot]=PMD_AC.default_ability_slot(target); rescue; end
    child=PMD_PokemonInstance.new(target,level,opts)

    # Split-origin continuity: preserve player-earned move knowledge/mastery/loadout.
    begin
      ensure_growth_data_v045
      child.ensure_growth_data_v045
      child.instance_variable_set(:@known_moves_v045,@known_moves_v045.dup)
      child.instance_variable_set(:@move_mastery_exp_v045,@move_mastery_exp_v045.dup)
      child.instance_variable_set(:@active_moves_v045,@active_moves_v045.dup)
      child.instance_variable_set(:@pending_move_choices_v045,@pending_move_choices_v045.dup)
    rescue
    end
    # Held Item is deliberately not cloned. PMD_PokemonInstance constructor defaults it to nil.

    unless PMD_AC.register_pokemon_instance_v045(child) && PMD_AC.place_additional_spawn_instance_v10547(child,dest)
      begin PMD_AC.pokemon_registry_v045.delete(uid); rescue; end
      return {:status=>:pending,:target=>target,:level=>level,:reason=>:placement_failed}
    end

    begin
      h=child.instance_variable_get(:@progression_history)
      if h!=nil
        h.push({:type=>:additional_spawn,:source_uid=>instance_uid,:source_species=>desc[:source_species],
          :source_evolution=>desc[:source_evolution],:species=>target,:level=>level})
      end
    rescue
    end
    {:status=>:created,:target=>target,:level=>level,:uid=>child.instance_uid,
      :location=>PMD_AC.pokemon_location_v045(child.instance_uid),
      :source_uid=>instance_uid,:source_species=>desc[:source_species],
      :source_evolution=>desc[:source_evolution]}
  rescue => e
    {:status=>:pending,:target=>(desc[:target] rescue nil),:level=>(desc[:level] rescue @level),
      :reason=>:exception,:error=>e.class.to_s}
  end

  def flush_pending_additional_spawns_v10547
    @pending_additional_spawns_v10547=[] if @pending_additional_spawns_v10547==nil
    return [] if @pending_additional_spawns_v10547.empty?
    done=[];remain=[]
    @pending_additional_spawns_v10547.each do |desc|
      row=build_additional_spawn_v10547(desc)
      if row[:status]==:created
        done.push(row)
      else
        remain.push(desc)
      end
    end
    @pending_additional_spawns_v10547=remain
    done
  rescue
    []
  end

  alias pmd_ac_v10547_gain_exp gain_exp unless method_defined?(:pmd_ac_v10547_gain_exp)
  def gain_exp(amount,allow_evolution=true)
    # Existing gameplay/progression chain delegates exactly once.
    result=pmd_ac_v10547_gain_exp(amount,allow_evolution)
    result[:additional_spawn_results_v10547]=[]

    # Retry any previously capacity-deferred spawn first.
    result[:additional_spawn_results_v10547].concat(flush_pending_additional_spawns_v10547)

    for evo in (result[:evolutions]||[])
      for target in (evo[:additional_spawns]||[])
        desc={:source_species=>evo[:from],:source_evolution=>evo[:to],
          :target=>target,:level=>evo[:level].to_i}
        row=build_additional_spawn_v10547(desc)
        result[:additional_spawn_results_v10547].push(row)
        if row[:status]!=:created
          @pending_additional_spawns_v10547=[] if @pending_additional_spawns_v10547==nil
          @pending_additional_spawns_v10547.push(desc) unless @pending_additional_spawns_v10547.any?{|x|
            x[:source_species]==desc[:source_species] && x[:source_evolution]==desc[:source_evolution] &&
            x[:target]==desc[:target] && x[:level].to_i==desc[:level].to_i}
        end
        evo[:additional_spawn_materialization_v10547]=row
      end
    end
    result[:pending_additional_spawns_v10547]=pending_additional_spawns_v10547
    result
  end
end

class Game_PMDChessUnit
  alias pmd_ac_v10547_gain_progression_exp gain_progression_exp unless method_defined?(:pmd_ac_v10547_gain_progression_exp)
  def gain_progression_exp(amount)
    result=pmd_ac_v10547_gain_progression_exp(amount)
    begin
      for row in (result[:additional_spawn_results_v10547]||[])
        next if @scene==nil
        if row[:status]==:created
          @scene.log_event(:evolution,log_name+' ADDITIONAL_SPAWN '+row[:target].to_s+
            ' uid='+row[:uid].to_s+' location='+row[:location].inspect+
            ' source_uid='+row[:source_uid].to_s)
        else
          @scene.log_event(:evolution,log_name+' ADDITIONAL_SPAWN_PENDING '+row[:target].to_s+
            ' reason='+row[:reason].to_s+' retained=1')
        end
      end
    rescue
    end
    result
  end
end

class Scene_PMD_AutoChess
  alias pmd_ac_v10547_start_battle start_battle unless method_defined?(:pmd_ac_v10547_start_battle)
  def start_battle
    begin
      rows=PMD_AC.flush_registry_additional_spawns_v10547
      for row in rows
        log_event(:progression,'ADDITIONAL_SPAWN_RETRY_V10547 '+row[:target].to_s+
          ' uid='+row[:uid].to_s+' location='+row[:location].inspect+' retained_then_created=1')
      end
    rescue
    end
    pmd_ac_v10547_start_battle
  end
end
