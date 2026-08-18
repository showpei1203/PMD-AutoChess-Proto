# encoding: UTF-8
#==============================================================================
# ■ PMD AutoChess - Phase D-IV Challenge C07-C12 Runtime + Progression Gate v1.05.63
#------------------------------------------------------------------------------
# - C07-C12 become executable challenge battles.
# - Menu selector uses gentle sequential unlocks so high difficulty is not
#   exposed at the beginning of a normal playthrough.
# - Direct script calls remain available for development testing.
#==============================================================================
$imported={} unless defined?($imported)
$imported['PMD_AutoChess_PhaseDIVChallengeC07C12_v10563']=true

module PMD_AC
  # Align the executable challenge names with the v1.05.53 content authority.
  PHASE_DIV_EARLY_CHALLENGES_V10554['C03'][:name]='毒霧救援' if PHASE_DIV_EARLY_CHALLENGES_V10554['C03']!=nil
  PHASE_DIV_EARLY_CHALLENGES_V10554['C04'][:name]='岩隘突破' if PHASE_DIV_EARLY_CHALLENGES_V10554['C04']!=nil
  PHASE_DIV_EARLY_CHALLENGES_V10554['C05'][:name]='雷場控制' if PHASE_DIV_EARLY_CHALLENGES_V10554['C05']!=nil
  PHASE_DIV_EARLY_CHALLENGES_V10554['C06'][:name]='夜幕獵手' if PHASE_DIV_EARLY_CHALLENGES_V10554['C06']!=nil
  PHASE_DIV_EARLY_CHALLENGES_V10554['C07']={:name=>'鋼陣守線',:ai_tier=>3,:presentation=>'story_demo',:lesson=>'frontline_artillery_sync',
    :enemy_setup=>[['steelix',43],['magneton',44],['skarmory',45]],:reward=>'C07',:recruitable=>false}
  PHASE_DIV_EARLY_CHALLENGES_V10554['C08']={:name=>'龍谷前哨',:ai_tier=>3,:presentation=>'story_demo',:lesson=>'growth_pressure_endurance',
    :enemy_setup=>[['dragonair',49],['altaria',50],['flygon',51]],:reward=>'C08',:recruitable=>false}
  PHASE_DIV_EARLY_CHALLENGES_V10554['C09']={:name=>'沙暴圍城',:ai_tier=>3,:presentation=>'story_demo',:lesson=>'durability_focus_fire',
    :enemy_setup=>[['hippowdon',55],['cacturne',56],['sandslash',57]],:reward=>'C09',:recruitable=>false}
  PHASE_DIV_EARLY_CHALLENGES_V10554['C10']={:name=>'天空突襲',:ai_tier=>3,:presentation=>'story_demo',:lesson=>'mobility_space_pressure',
    :enemy_setup=>[['crobat',61],['staraptor',62],['gliscor',63]],:reward=>'C10',:recruitable=>false}
  PHASE_DIV_EARLY_CHALLENGES_V10554['C11']={:name=>'空間迷走',:ai_tier=>4,:presentation=>'story_demo',:lesson=>'displacement_stickiness',
    :enemy_setup=>[['gardevoir',67],['dusknoir',68],['magnezone',69]],:reward=>'C11',:recruitable=>false}
  PHASE_DIV_EARLY_CHALLENGES_V10554['C12']={:name=>'靈界封鎖',:ai_tier=>4,:presentation=>'story_demo',:lesson=>'control_attrition',
    :enemy_setup=>[['dusclops',73],['mismagius',74],['bronzong',75]],:reward=>'C12',:recruitable=>false}

  PHASE_DIV_CHALLENGE_RUNTIME_MAX_V10563=12

  class << self
    def phase_div_party_max_level_v10563
      max=1
      begin
        if respond_to?(:party_instance_uids_v045)
          (party_instance_uids_v045||[]).each do |uid|
            p=pokemon_instance_for_uid_v045(uid) rescue nil
            max=[max,p.level.to_i].max if p!=nil && p.respond_to?(:level)
          end
        end
      rescue
      end
      max
    end

    def phase_div_challenge_unlock_v10563(code)
      c=code.to_s.upcase
      n=c.sub('C','').to_i
      return false if n<1 || n>PHASE_DIV_CHALLENGE_RUNTIME_MAX_V10563
      ch=phase_div_challenge_v10553(c)||{}
      lv=phase_div_party_max_level_v10563
      return false if lv < [ch[:level_min].to_i-2,1].max
      return true if n==1
      prev='C'+sprintf('%02d',n-1)
      phase_div_challenge_cleared_v10556?(prev)
    rescue
      false
    end

    def phase_div_hunt_unlock_v10563(code)
      c=code.to_s.upcase
      n=c.sub('H','').to_i
      return false if n<1 || n>21
      return true if n==1
      h=phase_div_hunt_v10553(c)||{}
      phase_div_party_max_level_v10563 >= [h[:level_min].to_i-3,1].max
    rescue
      false
    end

    def phase_div_challenge_scene_enabled_v10560(code)
      phase_div_early_challenge_v10554(code)!=nil && phase_div_challenge_unlock_v10563(code)
    rescue
      false
    end

    def phase_div_hunt_scene_enabled_v10560(code)
      !(phase_div_hunt_catalog_v10555(code)||[]).empty? && phase_div_hunt_unlock_v10563(code)
    rescue
      false
    end

    def phase_div_challenge_runtime_audit_v10563
      bad=[]
      (1..12).each do |i|
        c='C'+sprintf('%02d',i)
        ch=phase_div_early_challenge_v10554(c)
        bad.push('missing:'+c) if ch==nil
        if ch!=nil
          rows=ch[:enemy_setup]||[]
          bad.push('size:'+c) unless rows.size==3
          rows.each do |row|
            k=row[0].to_sym
            bad.push('species:'+c+':'+k.to_s) if defined?(SPECIES_DB_V016) && SPECIES_DB_V016[k]==nil
          end
          bad.push('reward:'+c) if phase_div_fixed_reward_v10554(c)==nil
        end
      end
      {:pass=>bad.empty?,:runtime=>12,:authority=>16,:bad=>bad}
    rescue
      {:pass=>false,:runtime=>0,:authority=>16,:bad=>['audit_error']}
    end
  end
end
