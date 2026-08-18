# encoding: UTF-8
#===============================================================================
# ■ PMD AutoChess - Hunt / Challenge Collection Info Data Authority v1.05.76
#-------------------------------------------------------------------------------
# 【用途】
# 為後續正式 UI 提供純資料 API：區域總物種、已解鎖、Seen、Owned、稀有度、
# 當次 active pool 與 Challenge clear/reward。此版不封 UI 外觀。
#===============================================================================
$imported={} unless defined?($imported)
$imported['PMD_AutoChess_CollectionInfoData_v10576']=true

module PMD_AC
  class << self
    def hunt_raw_catalog_v10576(code)
      c=code.to_s.upcase;out=[]
      PHASE_DIV_SPECIES_APPEARANCE_V10553.each do |k,row|
        out.push(k) if row[:natural_hunt].to_s.upcase==c
      end
      out.sort{|a,b|PHASE_DIV_SPECIES_APPEARANCE_V10553[a][:appearance_order].to_i <=> PHASE_DIV_SPECIES_APPEARANCE_V10553[b][:appearance_order].to_i}
    rescue
      []
    end

    def hunt_collection_rows(code)
      unlocked=phase_div_hunt_catalog_v10555(code)||[]
      hunt_raw_catalog_v10576(code).collect do |sp|
        row=phase_div_species_v10553(sp)||{}
        seen=respond_to?(:dex_seen_v093?) && dex_seen_v093?(sp)
        owned=respond_to?(:dex_ever_owned_v093?) && dex_ever_owned_v093?(sp)
        {:species=>sp,:dex=>row[:dex].to_i,:name=>(seen || owned ? row[:name].to_s : '????'),
         :seen=>(seen ? true:false),:owned=>(owned ? true:false),
         :unlocked=>unlocked.include?(sp),:rarity=>row[:spawn_rarity].to_s,
         :role=>row[:role].to_s,:first_track=>row[:first_track].to_s,
         :first_location=>row[:first_location].to_s}
      end
    rescue
      []
    end

    def hunt_collection_info(code)
      c=code.to_s.upcase;h=phase_div_hunt_v10553(c)
      return nil if h==nil
      rows=hunt_collection_rows(c);unlocked=rows.find_all{|r|r[:unlocked]}
      active=[];s=phase_div_hunt_session_v10555
      active=(s[:active_pool]||[]).dup if s!=nil && s[:active] && s[:code].to_s==c
      rc={}
      rows.each{|r|rc[r[:rarity]]=(rc[r[:rarity]]||0)+1}
      seen_n=0;owned_n=0;unseen_n=0;locked_n=0;active_seen=0;active_owned=0
      rows.each do |r|
        seen_n+=1 if r[:seen];owned_n+=1 if r[:owned]
        unseen_n+=1 unless r[:seen];locked_n+=1 unless r[:unlocked]
      end
      active.each do |sp|
        active_seen+=1 if respond_to?(:dex_seen_v093?) && dex_seen_v093?(sp)
        active_owned+=1 if respond_to?(:dex_ever_owned_v093?) && dex_ever_owned_v093?(sp)
      end
      {:code=>c,:name=>h[:name].to_s,:tier=>h[:tier].to_i,:ai_tier=>h[:ai_tier].to_i,
       :level_min=>h[:level_min].to_i,:level_max=>h[:level_max].to_i,
       :total=>rows.size,:unlocked=>unlocked.size,:seen=>seen_n,:owned=>owned_n,
       :unseen=>unseen_n,:locked=>locked_n,:rarity=>rc,:active_pool=>active,
       :active_seen=>active_seen,:active_owned=>active_owned}
    rescue
      nil
    end

    def challenge_collection_info(code)
      c=code.to_s.upcase;row=phase_div_challenge_v10553(c)
      return nil if row==nil
      clear=respond_to?(:phase_div_challenge_cleared_v10556?) && phase_div_challenge_cleared_v10556?(c)
      unlocked=respond_to?(:phase_div_challenge_unlock_v10563) ? phase_div_challenge_unlock_v10563(c) : true
      reward=respond_to?(:phase_div_fixed_reward_v10554) ? phase_div_fixed_reward_v10554(c) : nil
      {:code=>c,:name=>row[:name].to_s,:ai_tier=>row[:ai_tier].to_i,
       :level_min=>row[:level_min].to_i,:level_max=>row[:level_max].to_i,
       :unlocked=>(unlocked ? true:false),:cleared=>(clear ? true:false),
       :fixed_reward=>reward,:legend_circuit=>(['C13','C14','C15','C16'].include?(c) ? true:false)}
    rescue
      nil
    end

    def collection_info_audit_v10576
      hb=0;cb=0
      (PHASE_DIV_HUNT_ORDER_V10553||[]).each{|c|hb+=1 if hunt_collection_info(c)!=nil}
      (PHASE_DIV_CHALLENGE_ORDER_V10553||[]).each{|c|cb+=1 if challenge_collection_info(c)!=nil}
      {:pass=>(hb==21 && cb==16),:hunts=>hb,:challenges=>cb}
    rescue
      {:pass=>false,:hunts=>0,:challenges=>0}
    end
  end
end

class Scene_PMD_AutoChess
  alias pmd_ac_v10576_focus_summary focus_cast_log_summary_v1055 unless method_defined?(:pmd_ac_v10576_focus_summary)
  def focus_cast_log_summary_v1055
    r=pmd_ac_v10576_focus_summary
    begin
      a=PMD_AC.collection_info_audit_v10576
      log_event(:battle,'BATTLE_PHASE_DIV_COLLECTION_INFO_DATA_SUMMARY_V10576 pass='+(a[:pass] ? '1':'0')+
        ' hunts='+a[:hunts].to_i.to_s+'/21 challenges='+a[:challenges].to_i.to_s+'/16'+
        ' seen_owned_rarity=1 active_pool=1 ui_visual_seal=deferred gameplay_change=0')
    rescue
    end
    r
  end
end
