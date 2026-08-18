# encoding: UTF-8
#===============================================================================
# ■ PMD AutoChess - Hunt Runtime / Availability Semantics Seal v1.06.26
#-------------------------------------------------------------------------------
# H21 is structurally/runtime-ready but intentionally has no spawnable catalog
# before Legendary Circuit clears. Separate runtime readiness from current
# spawn availability and add a production direct-API gate for empty catalogs.
#===============================================================================
$imported={} unless defined?($imported)
$imported['PMD_AutoChess_HuntRuntimeAvailabilitySemantics_v10626']=true

module PMD_AC
  class << self
    def hunt_runtime_ready_codes_v10626
      return [] unless respond_to?(:start_hunt_dungeon_v10604) &&
        respond_to?(:hunt_generate_vx_floor_v10584) && respond_to?(:hunt_map_enter)
      out=[]
      PHASE_DIV_HUNT_ORDER_V10553.each do |c|
        out.push(c) if phase_div_hunt_v10553(c)!=nil
      end
      out
    rescue
      []
    end

    def hunt_spawnable_now_codes_v10626
      out=[]
      PHASE_DIV_HUNT_ORDER_V10553.each do |c|
        out.push(c) unless (phase_div_hunt_catalog_v10555(c)||[]).empty?
      end
      out
    rescue
      []
    end

    def hunt_gated_codes_v10626
      hunt_runtime_ready_codes_v10626-hunt_spawnable_now_codes_v10626
    rescue
      []
    end

    def h21_total_legend_species_v10626
      n=0
      PHASE_DIV_SPECIES_APPEARANCE_V10553.each do |k,row|
        n+=1 if row!=nil && row[:natural_hunt].to_s.upcase=='H21'
      end
      n
    rescue
      0
    end

    def h21_unlocked_legend_species_v10626
      (phase_div_hunt_catalog_v10555('H21')||[]).size
    rescue
      0
    end

    def hunt_runtime_launch_gate_v10626(code)
      c=code.to_s.upcase
      return {:pass=>false,:code=>c,:reason=>:unknown_hunt} if phase_div_hunt_v10553(c)==nil
      catalog=phase_div_hunt_catalog_v10555(c)||[]
      return {:pass=>true,:code=>c,:reason=>:ready,:catalog=>catalog.size} unless catalog.empty?
      reason=(c=='H21' ? :legend_circuit_locked : :empty_catalog)
      {:pass=>false,:code=>c,:reason=>reason,:catalog=>0}
    rescue
      {:pass=>false,:code=>code.to_s.upcase,:reason=>:gate_error,:catalog=>0}
    end

    alias pmd_ac_v10626_start_hunt_dungeon_v10604 start_hunt_dungeon_v10604 unless method_defined?(:pmd_ac_v10626_start_hunt_dungeon_v10604)
    def start_hunt_dungeon_v10604(code,mode=VXRD_HUNT_DEFAULT_MODE_V10604,seed=nil)
      g=hunt_runtime_launch_gate_v10626(code)
      unless g[:pass]
        if g[:reason]==:legend_circuit_locked
          hunt_runtime_message_v10604(['H21 裂隙聖域尚未解鎖','先完成 Legendary Circuit 挑戰。','每個已通關 Circuit 會把對應傳說種加入 H21。']) rescue nil
        else
          hunt_runtime_message_v10604(['狩獵區目前沒有可用 Encounter Pool',g[:code].to_s+' / '+g[:reason].to_s]) rescue nil
        end
        return false
      end
      pmd_ac_v10626_start_hunt_dungeon_v10604(code,mode,seed)
    rescue
      false
    end

    def hunt_runtime_semantics_audit_v10626
      ready=hunt_runtime_ready_codes_v10626
      spawn=hunt_spawnable_now_codes_v10626
      gated=hunt_gated_codes_v10626
      total=h21_total_legend_species_v10626
      unlocked=h21_unlocked_legend_species_v10626
      expected_gate=(unlocked<=0 ? gated==['H21'] : true)
      {:pass=>ready.size==21 && total==36 && expected_gate,
        :runtime_ready=>ready.size,:spawnable_now=>spawn.size,:gated=>gated,
        :h21_unlocked=>unlocked,:h21_total=>total}
    rescue
      {:pass=>false,:runtime_ready=>0,:spawnable_now=>0,:gated=>[],:h21_unlocked=>0,:h21_total=>0}
    end
  end
end
