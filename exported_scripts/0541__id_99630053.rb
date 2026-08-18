# encoding: UTF-8
#===============================================================================
# ■ PMD AutoChess - Phase D-IV Challenge First-Clear Reward v1.05.56
#===============================================================================
# 【用途】
# 正式接上 Challenge persistent clear state 與 C01~C12 固定高品質個體獎勵。
# - 每個 Challenge clear count 持久保存在 Game_System。
# - 固定 Pokemon 只在第一次勝利建立一次；重打不 duplicate。
# - BOX 有空位時直接送 BOX；容量滿時保留 pending descriptor，之後可再 flush。
# - 固定 IV / Nature / Ability 使用 v1.05.54 descriptor；不改野外完美個體上限。
# - UI 外觀仍 deferred，本版只提供 Runtime + log/data API。
#===============================================================================
$imported={} unless defined?($imported)
$imported['PMD_AutoChess_PhaseDIVChallengeFirstClearReward_v10556']=true

module PMD_AC
  PHASE_DIV_CHALLENGE_REWARD_POLICY_V10556={
    :version=>'1.05.56',:first_clear_exactly_once=>true,:repeat_reward=>false,
    :destination=>:storage_first,:capacity_full=>:persistent_pending,
    :identity=>:new_instance_uid,:ui_polish=>:deferred
  }

  class << self
    def phase_div_challenge_clears_v10556
      return {} if $game_system==nil
      h=$game_system.pmd_phase_div_challenge_clears_v10556
      if h==nil;h={};$game_system.pmd_phase_div_challenge_clears_v10556=h;end
      h
    end

    def phase_div_challenge_claims_v10556
      return {} if $game_system==nil
      h=$game_system.pmd_phase_div_challenge_claims_v10556
      if h==nil;h={};$game_system.pmd_phase_div_challenge_claims_v10556=h;end
      h
    end

    def phase_div_pending_rewards_v10556
      return [] if $game_system==nil
      a=$game_system.pmd_phase_div_pending_rewards_v10556
      if a==nil;a=[];$game_system.pmd_phase_div_pending_rewards_v10556=a;end
      a
    end

    def phase_div_challenge_clear_count_v10556(code)
      phase_div_challenge_clears_v10556[code.to_s.upcase].to_i
    end

    def phase_div_challenge_cleared_v10556?(code)
      phase_div_challenge_clear_count_v10556(code)>0
    end

    def phase_div_mark_challenge_clear_v10556(code)
      c=code.to_s.upcase
      return nil if phase_div_challenge_v10553(c)==nil
      h=phase_div_challenge_clears_v10556
      old=h[c].to_i;h[c]=old+1
      {:code=>c,:first_clear=>(old==0),:clear_count=>h[c]}
    rescue
      nil
    end

    def phase_div_reward_ability_slot_v10556(species,ability_key)
      target=ability_key.to_s.downcase.to_sym
      slots=ability_slots(species.to_sym)||{}
      slots.each{|slot,key|return slot if key.to_s.downcase.to_sym==target}
      default_ability_slot(species.to_sym)
    rescue
      :primary
    end

    def phase_div_build_fixed_reward_instance_v10556(code)
      c=code.to_s.upcase;r=phase_div_fixed_reward_v10554(c)
      return nil if r==nil
      uid=respond_to?(:allocate_registry_unique_uid_v10547) ? allocate_registry_unique_uid_v10547 : nil
      return nil if uid==nil
      sp=r[:species].to_s.downcase.to_sym
      opts={:instance_uid=>uid,:ivs=>(r[:ivs]||[]).dup,:nature=>r[:nature].to_s.downcase.to_sym,
        :ability_slot=>phase_div_reward_ability_slot_v10556(sp,r[:ability])}
      PMD_PokemonInstance.new(sp,r[:level].to_i,opts)
    rescue
      nil
    end

    def phase_div_materialize_fixed_reward_v10556(code)
      c=code.to_s.upcase
      return {:status=>:already_claimed,:code=>c} if phase_div_challenge_claims_v10556[c]
      r=phase_div_fixed_reward_v10554(c)
      return {:status=>:no_fixed_reward,:code=>c} if r==nil
      bi=first_available_box_v078
      if bi==nil
        phase_div_pending_rewards_v10556.push(c) unless phase_div_pending_rewards_v10556.include?(c)
        return {:status=>:pending,:code=>c,:reason=>:storage_full,:species=>r[:species]}
      end
      inst=phase_div_build_fixed_reward_instance_v10556(c)
      return {:status=>:pending,:code=>c,:reason=>:build_failed,:species=>r[:species]} if inst==nil
      unless register_pokemon_instance_v045(inst) && store_instance_v045(inst,bi,false)
        pokemon_registry_v045.delete(inst.instance_uid.to_i) rescue nil
        phase_div_pending_rewards_v10556.push(c) unless phase_div_pending_rewards_v10556.include?(c)
        return {:status=>:pending,:code=>c,:reason=>:store_failed,:species=>r[:species]}
      end
      phase_div_challenge_claims_v10556[c]=inst.instance_uid.to_i
      phase_div_pending_rewards_v10556.delete(c)
      {:status=>:created,:code=>c,:species=>inst.species_key,:level=>inst.level,
        :uid=>inst.instance_uid,:location=>pokemon_location_v045(inst.instance_uid),
        :nature=>inst.nature_key,:ability=>inst.ability_key,:ivs=>inst.ivs}
    rescue => e
      {:status=>:pending,:code=>c,:reason=>:exception,:error=>e.class.to_s}
    end

    def phase_div_flush_pending_rewards_v10556
      out=[]
      phase_div_pending_rewards_v10556.dup.each do |code|
        row=phase_div_materialize_fixed_reward_v10556(code)
        out.push(row)
      end
      out
    rescue
      []
    end

    def phase_div_challenge_request_v10556(code)
      c=code.to_s.upcase;ch=phase_div_early_challenge_v10554(c)
      return nil if ch==nil
      opts={:source=>:phase_div_challenge,:deploy=>true,:recruitable=>false,:recruit_rate=>0,
        :can_escape=>true,:hp_policy=>:carry,:defeat_policy=>:return_heal}
      r=event_custom_request_v092(ch[:name],phase_div_enemy_setup_v10554(ch[:enemy_setup]),opts,false)
      return nil if r==nil
      r[:key]=('phase_div_'+c.downcase).to_sym
      r[:source]=:phase_div_challenge
      r[:phase_div_challenge_code_v10556]=c
      r[:phase_div_ai_tier_v10555]=ch[:ai_tier].to_i
      r
    rescue
      nil
    end

    def phase_div_start_challenge_v10556(code)
      r=phase_div_challenge_request_v10556(code);return false if r==nil
      launch_battle_request_v081(r)
    rescue
      false
    end

    alias pmd_ac_v10556_record_battle_result_v081 record_battle_result_v081 unless method_defined?(:pmd_ac_v10556_record_battle_result_v081)
    def record_battle_result_v081(request,result)
      data=pmd_ac_v10556_record_battle_result_v081(request,result)
      begin
        c=request==nil ? nil : request[:phase_div_challenge_code_v10556]
        if c!=nil && result==:win
          clear=phase_div_mark_challenge_clear_v10556(c)
          reward=nil
          reward=phase_div_materialize_fixed_reward_v10556(c) if clear!=nil && clear[:first_clear]
          $game_system.pmd_phase_div_last_challenge_reward_v10556={:clear=>clear,:reward=>reward} if $game_system!=nil
        end
      rescue
      end
      data
    end

    alias pmd_ac_v10556_phase_div_test_battle_v10554 phase_div_test_battle_v10554 unless method_defined?(:pmd_ac_v10556_phase_div_test_battle_v10554)
    def phase_div_test_battle_v10554(code,variant=0)
      c=code.to_s.upcase
      if c=='C01' || c=='C02'
        return phase_div_start_challenge_v10556(c)
      end
      pmd_ac_v10556_phase_div_test_battle_v10554(code,variant)
    end

    def phase_div_challenge_reward_audit_v10556
      bad=[]
      (1..12).each do |i|
        c='C'+sprintf('%02d',i)
        r=phase_div_fixed_reward_v10554(c)
        bad.push('reward:'+c) if r==nil
        if r!=nil
          bad.push('ivs:'+c) unless (r[:ivs]||[]).size==6
          bad.push('species:'+c) if phase_div_species_v10553(r[:species])==nil
          bad.push('ability:'+c) if ability_slots(r[:species].to_sym)[phase_div_reward_ability_slot_v10556(r[:species],r[:ability])]==nil
        end
      end
      {:pass=>bad.empty?,:fixed=>12,:bad=>bad}
    rescue
      {:pass=>false,:fixed=>0,:bad=>['audit_error']}
    end
  end
end

class Game_System
  attr_accessor :pmd_phase_div_challenge_clears_v10556
  attr_accessor :pmd_phase_div_challenge_claims_v10556
  attr_accessor :pmd_phase_div_pending_rewards_v10556
  attr_accessor :pmd_phase_div_last_challenge_reward_v10556
end

class Scene_Map
  alias pmd_ac_v10556_start start unless method_defined?(:pmd_ac_v10556_start)
  def start
    pmd_ac_v10556_start
    PMD_AC.phase_div_flush_pending_rewards_v10556 rescue nil
  end
end

class Scene_PMD_AutoChess
  alias pmd_ac_v10556_create_units create_units unless method_defined?(:pmd_ac_v10556_create_units)
  alias pmd_ac_v10556_process_stage_result_v080 process_stage_result_v080 unless method_defined?(:pmd_ac_v10556_process_stage_result_v080)
  alias pmd_ac_v10556_focus_summary focus_cast_log_summary_v1055 unless method_defined?(:pmd_ac_v10556_focus_summary)

  def create_units
    pmd_ac_v10556_create_units
    req=rpg_request_v081 rescue nil
    if req!=nil && req[:phase_div_challenge_code_v10556]!=nil
      tier=req[:phase_div_ai_tier_v10555].to_i
      (@units||[]).each{|u|PMD_AC.phase_div_apply_enemy_ai_tier_v10555(u,tier) if u.team==:enemy}
    end
  end

  def process_stage_result_v080(winner_team)
    r=pmd_ac_v10556_process_stage_result_v080(winner_team)
    begin
      req=rpg_request_v081
      if req!=nil && req[:phase_div_challenge_code_v10556]!=nil && winner_team==:ally
        x=$game_system==nil ? nil : $game_system.pmd_phase_div_last_challenge_reward_v10556
        if x!=nil
          c=x[:clear];w=x[:reward]
          log_event(:collection,'PHASE_DIV_CHALLENGE_CLEAR_V10556 code='+req[:phase_div_challenge_code_v10556].to_s+
            ' first='+(c!=nil && c[:first_clear] ? '1':'0')+' count='+(c==nil ? '0':c[:clear_count].to_i.to_s)+
            ' reward='+(w==nil ? 'repeat_none':w[:status].to_s)+
            ' species='+(w==nil || w[:species]==nil ? 'none':w[:species].to_s)+' exactly_once=1')
        end
      end
    rescue
    end
    r
  end

  def focus_cast_log_summary_v1055
    r=pmd_ac_v10556_focus_summary
    begin
      a=PMD_AC.phase_div_challenge_reward_audit_v10556
      log_event(:battle,'BATTLE_PHASE_DIV_CHALLENGE_REWARD_SUMMARY_V10556 pass='+(a[:pass] ? '1':'0')+
        ' fixed_descriptors='+a[:fixed].to_i.to_s+'/12 persistent_clear=1 exactly_once=1'+
        ' storage_full_pending=1 ui_polish=deferred errors=['+(a[:bad]||[]).join(',')+'] blocking_gate=0')
    rescue
    end
    r
  end
end
