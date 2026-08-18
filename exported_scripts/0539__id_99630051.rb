# encoding: UTF-8
#===============================================================================
# ■ PMD AutoChess - Phase D-IV Early 2+2 Prototype Data v1.05.54
#===============================================================================
# 【用途】
# 將 Phase D-IV 前兩張 Hunt 與前兩張 Challenge 做成可查詢／可呼叫的 Prototype。
# 正式 Random Map / RTP Map Scene 尚未綁定，因此目前只使用既有 Battle Presentation。
#
# 【測試呼叫】
# PMD_AC.phase_div_test_battle_v10554('H01',0)
# PMD_AC.phase_div_test_battle_v10554('H02',3)
# PMD_AC.phase_div_test_battle_v10554('C01',0)
# PMD_AC.phase_div_test_battle_v10554('C02',0)
#
# Challenge fixed reward 本版只建立 descriptor，不自動發放。
# Persistent first-clear flag + materialization 留給 D-IV.4，避免半套 reward duplication。
#===============================================================================
$imported={} unless defined?($imported)
$imported['PMD_AutoChess_PhaseDIVEarly2Plus2Prototype_v10554']=true

module PMD_AC
  PHASE_DIV_EARLY_HUNTS_V10554={'H01'=>{:name=>'林緣採集地',:ai_tier=>0,:recruitable=>true,:recruit_rate=>38,:presentation=>'forest_demo',:formations=>[[['caterpie',5],['rattata',5],['oddish',5]],[['weedle',5],['sentret',6],['bidoof',6]],[['nidoran_f',6],['meowth',6],['paras',6]],[['teddiursa',7],['aipom',7],['pineco',7]]],:active_pool_target=>[8,10],:map_theme=>'RTP forest/grass'},'H02'=>{:name=>'苔溪濕地',:ai_tier=>0,:recruitable=>true,:recruit_rate=>36,:presentation=>'forest_demo',:formations=>[[['psyduck',8],['poliwag',8],['wooper',8]],[['lotad',9],['surskit',9],['buizel',9]],[['tentacool',9],['chinchou',9],['shellos',9]],[['feebas',10],['horsea',10],['staryu',10]]],:active_pool_target=>[8,10],:map_theme=>'RTP creek/wetland'}}
  PHASE_DIV_EARLY_CHALLENGES_V10554={'C01'=>{:name=>'林道護衛演習',:ai_tier=>1,:presentation=>'forest_demo',:lesson=>'bodyguard_backline',:enemy_setup=>[['geodude',10],['rattata',11],['oddish',10]],:reward=>'C01',:recruitable=>false},'C02'=>{:name=>'風脊狙擊演習',:ai_tier=>1,:presentation=>'story_demo',:lesson=>'artillery_target_priority',:enemy_setup=>[['magnemite',14],['pidgey',14],['ekans',15]],:reward=>'C02',:recruitable=>false}}
  PHASE_DIV_FIXED_REWARDS_V10554={'C01'=>{:species=>'eevee',:name=>'伊布',:level=>10,:nature=>'jolly',:ability=>'adaptability',:ivs=>[24,31,22,18,22,31],:quality=>'2×31',:note=>'前期萬用配隊核心'},'C02'=>{:species=>'ralts',:name=>'拉魯拉絲',:level=>14,:nature=>'timid',:ability=>'synchronize',:ivs=>[22,10,21,31,24,31],:quality=>'2×31',:note=>'控制／遠程入門'},'C03'=>{:species=>'togepi',:name=>'波克比',:level=>20,:nature=>'calm',:ability=>'serene_grace',:ivs=>[31,8,23,24,31,20],:quality=>'2×31',:note=>'支援／狀態協同'},'C04'=>{:species=>'riolu',:name=>'利歐路',:level=>25,:nature=>'jolly',:ability=>'inner_focus',:ivs=>[22,31,20,18,20,31],:quality=>'2×31',:note=>'切入／鬥士'},'C05'=>{:species=>'rotom',:name=>'洛托姆',:level=>31,:nature=>'timid',:ability=>'levitate',:ivs=>[24,12,24,31,26,31],:quality=>'2×31',:note=>'控制／機動核心'},'C06'=>{:species=>'absol',:name=>'阿勃梭魯',:level=>37,:nature=>'jolly',:ability=>'super_luck',:ivs=>[24,31,20,18,20,31],:quality=>'2×31',:note=>'刺客／收頭'},'C07'=>{:species=>'beldum',:name=>'鐵啞鈴',:level=>43,:nature=>'adamant',:ability=>'clear_body',:ivs=>[31,31,28,16,24,18],:quality=>'2×31',:note=>'鋼系成長核心'},'C08'=>{:species=>'dratini',:name=>'迷你龍',:level=>49,:nature=>'adamant',:ability=>'shed_skin',:ivs=>[28,31,24,18,24,31],:quality=>'2×31',:note=>'龍系長線成長'},'C09'=>{:species=>'larvitar',:name=>'幼基拉斯',:level=>55,:nature=>'adamant',:ability=>'guts',:ivs=>[31,31,28,12,24,20],:quality=>'2×31',:note=>'耐久／壓力核心'},'C10'=>{:species=>'bagon',:name=>'寶貝龍',:level=>61,:nature=>'jolly',:ability=>'rock_head',:ivs=>[26,31,24,16,22,31],:quality=>'2×31',:note=>'高速物攻成長'},'C11'=>{:species=>'gible',:name=>'圓陸鯊',:level=>67,:nature=>'jolly',:ability=>'sand_veil',:ivs=>[28,31,26,16,22,31],:quality=>'2×31',:note=>'空間切入核心'},'C12'=>{:species=>'spiritomb',:name=>'花岩怪',:level=>73,:nature=>'careful',:ability=>'pressure',:ivs=>[31,24,31,20,31,12],:quality=>'3×31',:note=>'控制／耐久終盤拼圖'}}

  class << self
    def phase_div_early_hunt_v10554(code)
      PHASE_DIV_EARLY_HUNTS_V10554[code.to_s.upcase]
    end

    def phase_div_early_challenge_v10554(code)
      PHASE_DIV_EARLY_CHALLENGES_V10554[code.to_s.upcase]
    end

    def phase_div_fixed_reward_v10554(code)
      PHASE_DIV_FIXED_REWARDS_V10554[code.to_s.upcase]
    end

    def phase_div_enemy_setup_v10554(rows)
      out=[]
      (rows || []).each do |row|
        out.push([row[0].to_sym,row[1].to_i])
      end
      out
    end

    # Development-only battle launcher.  Does not alter Map bindings.
    def phase_div_test_battle_v10554(code,variant=0)
      c=code.to_s.upcase
      h=phase_div_early_hunt_v10554(c)
      if h!=nil
        fs=h[:formations] || []
        return false if fs.empty? || !respond_to?(:event_custom_v092)
        row=fs[variant.to_i % fs.size]
        return event_custom_v092(h[:name],phase_div_enemy_setup_v10554(row),
          {:deploy=>true,:source=>:script,:recruitable=>true,
           :recruit_rate=>h[:recruit_rate].to_i,:presentation=>h[:presentation]})
      end
      ch=phase_div_early_challenge_v10554(c)
      if ch!=nil
        return false unless respond_to?(:event_custom_v092)
        return event_custom_v092(ch[:name],phase_div_enemy_setup_v10554(ch[:enemy_setup]),
          {:deploy=>true,:source=>:script,:recruitable=>false,:recruit_rate=>0,
           :presentation=>ch[:presentation],:can_escape=>true})
      end
      false
    rescue
      false
    end

    def phase_div_early_audit_v10554
      bad=[]
      PHASE_DIV_EARLY_HUNTS_V10554.each do |code,h|
        bad.push('hunt_authority:'+code) if phase_div_hunt_v10553(code)==nil
        fs=h[:formations] || []
        bad.push('hunt_formations:'+code) if fs.empty?
        fs.each do |f|
          bad.push('hunt_size:'+code) unless f.size==3
          f.each do |row|
            k=row[0].to_sym
            bad.push('species:'+code+':'+k.to_s) if defined?(SPECIES_DB_V016) && SPECIES_DB_V016[k]==nil
          end
        end
      end
      PHASE_DIV_EARLY_CHALLENGES_V10554.each do |code,h|
        bad.push('challenge_authority:'+code) if phase_div_challenge_v10553(code)==nil
        rows=h[:enemy_setup] || []
        bad.push('challenge_size:'+code) unless rows.size==3
      end
      ['C01','C02'].each do |code|
        r=phase_div_fixed_reward_v10554(code)
        bad.push('reward:'+code) if r==nil
        if r!=nil
          k=r[:species].to_sym
          bad.push('reward_species:'+code) if defined?(SPECIES_DB_V016) && SPECIES_DB_V016[k]==nil
          bad.push('reward_ivs:'+code) unless (r[:ivs] || []).size==6
        end
      end
      {:pass=>bad.empty?,:hunts=>PHASE_DIV_EARLY_HUNTS_V10554.size,
       :challenges=>PHASE_DIV_EARLY_CHALLENGES_V10554.size,
       :fixed_rewards=>PHASE_DIV_FIXED_REWARDS_V10554.size,:bad=>bad}
    rescue
      {:pass=>false,:hunts=>0,:challenges=>0,:fixed_rewards=>0,:bad=>['audit_error']}
    end
  end
end

class Scene_PMD_AutoChess
  alias pmd_ac_v10554_start_battle start_battle unless method_defined?(:pmd_ac_v10554_start_battle)
  alias pmd_ac_v10554_focus_summary focus_cast_log_summary_v1055 unless method_defined?(:pmd_ac_v10554_focus_summary)

  def start_battle
    r=pmd_ac_v10554_start_battle
    begin
      @v10554_summary_logged=false
      if @phase==:battle && respond_to?(:verification_mode) && verification_mode==:normal &&
         !(respond_to?(:production_external_battle_fast_v10613?) && production_external_battle_fast_v10613?)
        a=PMD_AC.phase_div_early_audit_v10554
        log_event(:battle,'BATTLE_PHASE_DIV_EARLY_2PLUS2_V10554 START pass='+(a[:pass] ? '1':'0')+
          ' hunts='+a[:hunts].to_i.to_s+'/2 challenges='+a[:challenges].to_i.to_s+'/2'+
          ' fixed_reward_descriptors='+a[:fixed_rewards].to_i.to_s+
          ' random_map_bridge=deferred reward_materialization=deferred ui_polish=deferred'+
          ' gameplay_change=0 errors=['+(a[:bad]||[]).join(',')+']')
      end
    rescue
    end
    r
  end

  def phase_div_early_summary_v10554
    return false if @v10554_summary_logged
    @v10554_summary_logged=true
    a=PMD_AC.phase_div_early_audit_v10554
    log_event(:battle,'BATTLE_PHASE_DIV_EARLY_2PLUS2_SUMMARY_V10554 pass='+(a[:pass] ? '1':'0')+
      ' H01=ready H02=ready C01=ready C02=ready'+
      ' fixed_reward_materialization=next random_map_rtp_bridge=next ui_visual_seal=deferred blocking_gate=0')
    a[:pass]
  rescue
    false
  end

  def focus_cast_log_summary_v1055
    r=pmd_ac_v10554_focus_summary
    return r if respond_to?(:production_external_battle_fast_v10613?) && production_external_battle_fast_v10613?
    begin
      phase_div_early_summary_v10554
    rescue
    end
    r
  end
end
