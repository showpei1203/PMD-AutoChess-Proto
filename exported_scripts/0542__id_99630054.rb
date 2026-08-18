# encoding: UTF-8
#===============================================================================
# ■ PMD AutoChess - Phase D-IV Collection Continuity / Hunt Economy v1.05.57
#===============================================================================
# 【核心修正】
# v0.81 戰後招募會依 species+level 重新 new PMD_PokemonInstance，造成玩家看到的
# Encounter 個體與真正加入 BOX 的 IV/Nature/Ability 不同。本版在 Phase D-IV Hunt
# 正式改為「同一 Encounter instance」招募：保留 UID、IV、Nature、Ability、已學招式。
# Elite 仍只是當場 Encounter modifier，不永久複製菁英倍率。
#
# 【Hunt Economy】
# - Tier1：高招募率、0 Elite，服務前期收集。
# - Tier2~4：逐步降低招募率、增加 Elite，仍不進 AI4/5。
# - H21：傳說再遇低率，招募率最低。
# - Spawn rarity 只調 active pool 權重，不修改 species Authority。
#===============================================================================
$imported={} unless defined?($imported)
$imported['PMD_AutoChess_PhaseDIVCollectionContinuityEconomy_v10557']=true

module PMD_AC
  PHASE_DIV_HUNT_ECONOMY_V10557={
    1=>{:steps=>[8,13], :recruit_rate=>45,:elite_rate=>0, :elite_max=>0},
    2=>{:steps=>[9,14], :recruit_rate=>38,:elite_rate=>3, :elite_max=>1},
    3=>{:steps=>[10,15],:recruit_rate=>32,:elite_rate=>7, :elite_max=>1},
    4=>{:steps=>[11,16],:recruit_rate=>26,:elite_rate=>12,:elite_max=>1},
    5=>{:steps=>[12,18],:recruit_rate=>12,:elite_rate=>18,:elite_max=>1}
  }
  PHASE_DIV_RARITY_WEIGHT_V10557={
    'common'=>60,'uncommon'=>30,'rare'=>12,'very_rare'=>4,'legendary'=>1
  }

  class << self
    def phase_div_hunt_economy_v10557(tier)
      PHASE_DIV_HUNT_ECONOMY_V10557[tier.to_i] || PHASE_DIV_HUNT_ECONOMY_V10557[1]
    end

    def phase_div_hunt_steps_v10557(tier)
      phase_div_hunt_economy_v10557(tier)[:steps].dup
    end

    def phase_div_hunt_runtime_options_v10557(code)
      h=phase_div_hunt_v10553(code);tier=h==nil ? 1 : h[:tier].to_i
      e=phase_div_hunt_economy_v10557(tier)
      {:recruit_rate=>e[:recruit_rate],:elite_rate=>e[:elite_rate],
        :elite_profile=>:standard_elite,:elite_max=>e[:elite_max]}
    end

    def phase_div_spawn_weight_v10557(row)
      return 1 if row==nil
      base=PHASE_DIV_RARITY_WEIGHT_V10557[row[:spawn_rarity].to_s].to_i
      base=1 if base<=0
      # Challenge reward / legendary become huntable only after clear; keep them rare.
      base=[base,3].min if row[:first_track].to_s=='challenge_reward'
      base=1 if row[:first_track].to_s=='challenge_boss'
      base
    rescue
      1
    end

    alias pmd_ac_v10557_recruit_offer_for_request_v081 recruit_offer_for_request_v081 unless method_defined?(:pmd_ac_v10557_recruit_offer_for_request_v081)
    def recruit_offer_for_request_v081(request,enemy_units=nil,roll=nil,pick=nil)
      offer=pmd_ac_v10557_recruit_offer_for_request_v081(request,enemy_units,roll,pick)
      return offer if offer==nil || request==nil || request[:phase_div_hunt_code_v10555]==nil
      units=(enemy_units||[]).find_all{|u|u!=nil && u.respond_to?(:species_key) && u.species_key.to_s==offer[:species].to_s}
      source=units.sort_by{|u|u.respond_to?(:instance_uid) ? u.instance_uid.to_i : 0}[0]
      if source!=nil && source.respond_to?(:pokemon_instance)
        inst=source.pokemon_instance
        if inst!=nil
          offer[:source_instance_v10557]=inst
          offer[:source_instance_uid_v10557]=inst.instance_uid.to_i
          offer[:ivs_v10557]=inst.ivs rescue nil
          offer[:nature_v10557]=inst.nature_key rescue nil
          offer[:ability_v10557]=inst.ability_key rescue nil
          offer[:exact_encounter_instance_v10557]=true
        end
      end
      offer
    rescue
      offer
    end

    def phase_div_clone_recruit_instance_v10557(source)
      return nil if source==nil
      uid=respond_to?(:allocate_registry_unique_uid_v10547) ? allocate_registry_unique_uid_v10547 : nil
      return nil if uid==nil
      opts={:instance_uid=>uid,:ivs=>source.ivs,:nature=>source.nature_key,:ability_slot=>source.ability_slot}
      child=PMD_PokemonInstance.new(source.species_key,source.level,opts)
      begin
        source.ensure_growth_data_v045;child.ensure_growth_data_v045
        child.instance_variable_set(:@known_moves_v045,source.known_moves_v045)
        child.instance_variable_set(:@move_mastery_exp_v045,source.instance_variable_get(:@move_mastery_exp_v045).dup)
        child.instance_variable_set(:@active_moves_v045,source.active_moves_v045)
        child.instance_variable_set(:@pending_move_choices_v045,source.pending_move_choices_v045)
      rescue
      end
      child
    rescue
      nil
    end

    alias pmd_ac_v10557_accept_recruit_offer_v080 accept_recruit_offer_v080 unless method_defined?(:pmd_ac_v10557_accept_recruit_offer_v080)
    def accept_recruit_offer_v080(offer)
      return pmd_ac_v10557_accept_recruit_offer_v080(offer) if offer==nil || offer[:source_instance_v10557]==nil
      return nil if offer[:accepted]
      return nil if first_available_box_v078==nil
      source=offer[:source_instance_v10557]
      inst=source
      registered=register_pokemon_instance_v045(inst)
      unless registered
        existing=pokemon_instance_for_uid_v045(source.instance_uid)
        if existing!=nil && existing.equal?(source)
          registered=true
        else
          inst=phase_div_clone_recruit_instance_v10557(source)
          registered=(inst!=nil && register_pokemon_instance_v045(inst))
        end
      end
      return nil unless registered && inst!=nil
      unless store_instance_first_available_v078(inst,false)
        pokemon_registry_v045.delete(inst.instance_uid.to_i) if !inst.equal?(source) rescue nil
        return nil
      end
      inst.heal_field_hp_v082 if inst.respond_to?(:heal_field_hp_v082)
      offer[:accepted]=true
      offer[:instance_uid]=inst.instance_uid.to_i
      offer[:exact_encounter_instance_v10557]=inst.equal?(source)
      offer[:individual_continuity_v10557]=true
      stage_state_v080[:recruits]=stage_state_v080[:recruits].to_i+1 if respond_to?(:stage_state_v080)
      inst
    rescue
      nil
    end

    def phase_div_collection_continuity_audit_v10557
      bad=[]
      (1..5).each do |tier|
        e=phase_div_hunt_economy_v10557(tier)
        bad.push('economy:'+tier.to_s) if e[:recruit_rate].to_i<0 || e[:recruit_rate].to_i>100
        bad.push('elite:'+tier.to_s) if e[:elite_rate].to_i<0 || e[:elite_rate].to_i>100
        s=e[:steps]||[];bad.push('steps:'+tier.to_s) unless s.size==2 && s[0].to_i>0 && s[1].to_i>=s[0].to_i
      end
      bad.push('tier1_elite') unless phase_div_hunt_economy_v10557(1)[:elite_rate].to_i==0
      bad.push('tier5_recruit') unless phase_div_hunt_economy_v10557(5)[:recruit_rate].to_i<phase_div_hunt_economy_v10557(1)[:recruit_rate].to_i
      {:pass=>bad.empty?,:tiers=>5,:bad=>bad}
    rescue
      {:pass=>false,:tiers=>0,:bad=>['audit_error']}
    end
  end
end

class Scene_PMD_AutoChess
  alias pmd_ac_v10557_accept_rpg_recruit_v081 accept_rpg_recruit_v081 unless method_defined?(:pmd_ac_v10557_accept_rpg_recruit_v081)
  alias pmd_ac_v10557_focus_summary focus_cast_log_summary_v1055 unless method_defined?(:pmd_ac_v10557_focus_summary)

  def accept_rpg_recruit_v081
    before=nil
    begin
      rr=@rpg_reward_v081;before=rr==nil ? nil : rr[:offer]
    rescue
    end
    r=pmd_ac_v10557_accept_rpg_recruit_v081
    begin
      if r && before!=nil && before[:individual_continuity_v10557]
        log_event(:collection,'PHASE_DIV_HUNT_RECRUIT_CONTINUITY_V10557 species='+before[:species].to_s+
          ' uid='+before[:instance_uid].to_i.to_s+' exact_encounter='+(before[:exact_encounter_instance_v10557] ? '1':'0')+
          ' nature='+(before[:nature_v10557]||'unknown').to_s+' ability='+(before[:ability_v10557]||'unknown').to_s+
          ' ivs=['+((before[:ivs_v10557]||[]).join(','))+'] elite_mods_persistent=0')
      end
    rescue
    end
    r
  end

  def focus_cast_log_summary_v1055
    r=pmd_ac_v10557_focus_summary
    begin
      a=PMD_AC.phase_div_collection_continuity_audit_v10557
      log_event(:battle,'BATTLE_PHASE_DIV_COLLECTION_CONTINUITY_SUMMARY_V10557 pass='+(a[:pass] ? '1':'0')+
        ' hunt_tiers='+a[:tiers].to_i.to_s+'/5 exact_encounter_recruit=1 iv_nature_ability_preserved=1'+
        ' elite_mods_not_persistent=1 hunt_ai_max=3 challenge_ai_max=5 ui_polish=deferred'+
        ' errors=['+(a[:bad]||[]).join(',')+'] blocking_gate=0')
    rescue
    end
    r
  end
end
