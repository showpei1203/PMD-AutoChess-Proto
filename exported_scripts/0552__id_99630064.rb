# encoding: UTF-8
#==============================================================================
# ■ PMD AutoChess - Phase D-IV Legendary Challenge Circuits C13-C16 v1.05.67
#------------------------------------------------------------------------------
# Converts the four legendary Challenge authorities into executable multi-wave
# circuits.  Every species whose v1.05.53 first_location is C13-C16 appears in
# its circuit.  A Challenge clear is recorded only after the final wave, which
# then unlocks those legendary species for H21 low-rate hunting.
#==============================================================================
$imported={} unless defined?($imported)
$imported['PMD_AutoChess_LegendaryChallengeCircuits_v10567']=true

module PMD_AC
  class << self
    def phase_div_legend_species_v10567(code)
      c=code.to_s.upcase
      rows=[]
      PHASE_DIV_SPECIES_APPEARANCE_V10553.each do |k,d|
        if d[:first_track].to_s=='challenge_boss' && d[:first_location].to_s.upcase==c
          rows.push([d[:appearance_order].to_i,k])
        end
      end
      rows.sort{|a,b|a[0]<=>b[0]}.collect{|r|r[1]}
    rescue
      []
    end

    def phase_div_legend_waves_v10567(code)
      c=code.to_s.upcase
      sp=phase_div_legend_species_v10567(c)
      ch=phase_div_challenge_v10553(c)||{}
      return [] if sp.empty?
      waves=[];i=0
      while i<sp.size
        group=sp[i,3]||[]
        wave_index=waves.size
        total=(sp.size+2)/3
        mn=ch[:level_min].to_i;mx=ch[:level_max].to_i
        base=mn
        if total>1
          base=mn+((mx-mn)*wave_index/[total-1,1].max)
        end
        rows=[]
        group.each_with_index{|k,j|rows.push([k.to_s,[base+j,mx].min])}
        waves.push(rows)
        i+=3
      end
      waves
    rescue
      []
    end

    def phase_div_legend_request_v10567(code,stage=0)
      c=code.to_s.upcase
      return nil unless ['C13','C14','C15','C16'].include?(c)
      ch=phase_div_challenge_v10553(c);return nil if ch==nil
      waves=phase_div_legend_waves_v10567(c);idx=stage.to_i
      return nil if idx<0 || idx>=waves.size
      opts={:source=>:phase_div_legend_circuit,:deploy=>true,:recruitable=>false,
        :recruit_rate=>0,:can_escape=>false,:hp_policy=>:carry,:defeat_policy=>:return_heal}
      name=ch[:name].to_s+' '+(idx+1).to_s+'/'+waves.size.to_s
      r=event_custom_request_v092(name,phase_div_enemy_setup_v10554(waves[idx]),opts,false)
      return nil if r==nil
      r[:key]=('phase_div_'+c.downcase+'_wave_'+(idx+1).to_s).to_sym
      r[:source]=:phase_div_legend_circuit
      r[:phase_div_legend_circuit_code_v10567]=c
      r[:phase_div_legend_stage_v10567]=idx
      r[:phase_div_legend_stage_count_v10567]=waves.size
      r[:phase_div_ai_tier_v10555]=ch[:ai_tier].to_i
      r[:pmd_return_scene_v10560]=:challenge
      # Existing v1.05.56 clear/reward authority sees the Challenge only on the
      # final wave.  C13-C16 have no fixed Pokemon descriptor; their permanent
      # reward is H21 legendary unlock.
      r[:phase_div_challenge_code_v10556]=c if idx==waves.size-1
      r
    rescue
      nil
    end

    def phase_div_start_legend_circuit_v10567(code,stage=0)
      r=phase_div_legend_request_v10567(code,stage);return false if r==nil
      launch_battle_request_v081(r)
    rescue
      false
    end

    def phase_div_legend_circuit_audit_v10567
      expected={'C13'=>5,'C14'=>6,'C15'=>10,'C16'=>15}
      bad=[];waves=0;species=0
      expected.each do |c,n|
        sp=phase_div_legend_species_v10567(c);ws=phase_div_legend_waves_v10567(c)
        bad.push('species:'+c) unless sp.size==n
        bad.push('waves:'+c) if ws.empty?
        flat=[];ws.each{|w|w.each{|r|flat.push(r[0].to_sym)}}
        bad.push('coverage:'+c) unless flat==sp
        species+=sp.size;waves+=ws.size
      end
      {:pass=>bad.empty?,:circuits=>4,:species=>species,:waves=>waves,:bad=>bad}
    rescue
      {:pass=>false,:circuits=>0,:species=>0,:waves=>0,:bad=>['audit_error']}
    end

    # v1.05.63 progression gate now extends through C16.
    def phase_div_challenge_unlock_v10563(code)
      c=code.to_s.upcase;n=c.sub('C','').to_i
      return false if n<1 || n>16
      ch=phase_div_challenge_v10553(c)||{}
      lv=phase_div_party_max_level_v10563
      return false if lv < [ch[:level_min].to_i-2,1].max
      return true if n==1
      prev='C'+sprintf('%02d',n-1)
      phase_div_challenge_cleared_v10556?(prev)
    rescue
      false
    end

    def phase_div_challenge_scene_enabled_v10560(code)
      c=code.to_s.upcase
      available=(phase_div_early_challenge_v10554(c)!=nil)
      available=true if ['C13','C14','C15','C16'].include?(c) && !phase_div_legend_waves_v10567(c).empty?
      available && phase_div_challenge_unlock_v10563(c)
    rescue
      false
    end

    alias pmd_ac_v10567_start_challenge_scene phase_div_start_challenge_scene_battle_v10560 unless method_defined?(:pmd_ac_v10567_start_challenge_scene)
    def phase_div_start_challenge_scene_battle_v10560(code)
      c=code.to_s.upcase
      if ['C13','C14','C15','C16'].include?(c)
        return phase_div_start_legend_circuit_v10567(c,0)
      end
      pmd_ac_v10567_start_challenge_scene(c)
    end

    alias pmd_ac_v10567_test_battle phase_div_test_battle_v10554 unless method_defined?(:pmd_ac_v10567_test_battle)
    def phase_div_test_battle_v10554(code,variant=0)
      c=code.to_s.upcase
      if ['C13','C14','C15','C16'].include?(c)
        return phase_div_start_legend_circuit_v10567(c,variant.to_i)
      end
      pmd_ac_v10567_test_battle(code,variant)
    end

    alias pmd_ac_v10567_record_result record_battle_result_v081 unless method_defined?(:pmd_ac_v10567_record_result)
    def record_battle_result_v081(request,result)
      r=pmd_ac_v10567_record_result(request,result)
      begin
        c=request==nil ? nil : request[:phase_div_legend_circuit_code_v10567]
        if c!=nil && result==:win && $game_temp!=nil
          idx=request[:phase_div_legend_stage_v10567].to_i
          total=request[:phase_div_legend_stage_count_v10567].to_i
          if idx+1<total
            $game_temp.pmd_phase_div_legend_next_v10567=[c,idx+1]
          else
            $game_temp.pmd_phase_div_legend_next_v10567=nil
          end
        end
      rescue
      end
      r
    end
  end
end


class Scene_PMD_ChallengeSelectV10560 < Scene_Base
  # v1.05.67: distinguish "locked" from "runtime missing" now that C01-C16 all
  # have executable Runtime.  Keep functional UI only; polish remains deferred.
  def start
    super
    commands=[];@codes=[]
    (1..16).each do |i|
      c='C'+sprintf('%02d',i);ch=PMD_AC.phase_div_challenge_v10553(c)||{}
      runtime=(PMD_AC.phase_div_early_challenge_v10554(c)!=nil)
      runtime=true if ['C13','C14','C15','C16'].include?(c) && !PMD_AC.phase_div_legend_waves_v10567(c).empty?
      unlocked=runtime && PMD_AC.phase_div_challenge_unlock_v10563(c)
      clear=PMD_AC.respond_to?(:phase_div_challenge_clear_count_v10556) ? PMD_AC.phase_div_challenge_clear_count_v10556(c) : 0
      label=c+' '+ch[:name].to_s+'｜AI'+ch[:ai_tier].to_i.to_s
      label+=(clear.to_i>0 ? '［CLEAR］' : '')
      label+='［Runtime待接］' unless runtime
      label+='［未解鎖］' if runtime && !unlocked
      commands.push(label);@codes.push(c)
    end
    @window=Window_Command.new(Graphics.width,commands)
    @window.height=Graphics.height
    @window.create_contents
    @window.refresh
    @window.index=0
  end
end

class Game_Temp
  attr_accessor :pmd_phase_div_legend_next_v10567
end

class Scene_PMD_AutoChess
  alias pmd_ac_v10567_create_units create_units unless method_defined?(:pmd_ac_v10567_create_units)
  alias pmd_ac_v10567_return_to_map return_to_map_v081 unless method_defined?(:pmd_ac_v10567_return_to_map)
  alias pmd_ac_v10567_focus_summary focus_cast_log_summary_v1055 unless method_defined?(:pmd_ac_v10567_focus_summary)

  def create_units
    pmd_ac_v10567_create_units
    req=rpg_request_v081 rescue nil
    if req!=nil && req[:phase_div_legend_circuit_code_v10567]!=nil
      tier=req[:phase_div_ai_tier_v10555].to_i
      (@units||[]).each{|u|PMD_AC.phase_div_apply_enemy_ai_tier_v10555(u,tier) if u.team==:enemy}
    end
  end

  def return_to_map_v081
    req=rpg_request_v081 rescue nil
    next_wave=($game_temp==nil ? nil : $game_temp.pmd_phase_div_legend_next_v10567)
    if req!=nil && req[:phase_div_legend_circuit_code_v10567]!=nil && next_wave!=nil
      begin
        sync_field_hp_v082(req) if respond_to?(:sync_field_hp_v082)
      rescue
      end
      PMD_AC.clear_battle_request_v081
      $game_temp.pmd_phase_div_legend_next_v10567=nil if $game_temp!=nil
      PMD_AC.phase_div_start_legend_circuit_v10567(next_wave[0],next_wave[1])
      return
    end
    pmd_ac_v10567_return_to_map
  end

  def focus_cast_log_summary_v1055
    r=pmd_ac_v10567_focus_summary
    begin
      a=PMD_AC.phase_div_legend_circuit_audit_v10567
      log_event(:battle,'BATTLE_PHASE_DIV_LEGEND_CIRCUIT_SUMMARY_V10567 pass='+(a[:pass] ? '1':'0')+
        ' circuits='+a[:circuits].to_i.to_s+'/4 species='+a[:species].to_i.to_s+'/36 waves='+a[:waves].to_i.to_s+
        ' final_clear_only=1 h21_unlock=1 recruit_in_circuit=0 errors=['+(a[:bad]||[]).join(',')+'] blocking_gate=0')
    rescue
    end
    r
  end
end
