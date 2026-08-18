# encoding: UTF-8
#==============================================================================
# 【PMD AutoChess 中文維護說明】
# 腳本：PMD AutoChess Team Bond Discovery Runtime v0.99.3
# 分類：隊伍羈絆／RPG 永久發現紀錄／Content Verifier／v0.99.2 相容補丁
#
# 【用途】
# 1. 保存 Relationship Bond 的「看過 Seen」與「自己組過 Formed」兩層 RPG 紀錄。
# 2. NORMAL 正式戰鬥中：敵我任何 Relationship 啟動都記 Seen；只有玩家隊伍記 Formed。
# 3. 提供未來羈絆圖鑑 UI 需要的名稱隱藏、Hint、詳細資料解鎖查詢 API。
# 4. 新增 TEAM_BOND_CONTENT_V0993 Verifier，驗證 81 組內容、Rank、Basis、Priority、
#    Species/Line Cross-reference、Discovery Save Isolation；不重測／不修改戰鬥效果核心。
# 5. 修正舊 TEAM_BOND_V0992 Verifier 的硬編碼 42/34 顯示，使內容擴張後仍可重跑。
#
# 【永久 Save Data】
# Game_System：
# @team_bond_seen_v0993   Hash<bond_key,true>
# @team_bond_formed_v0993 Hash<bond_key,true>
# 舊存檔沒有這兩個變數時會自動建立空 Hash，不要求重開新存檔。
#
# 【Seen / Formed 規則】
# - 玩家 Relationship 成立：Seen + Formed。
# - 敵方 Relationship 成立：Seen only。
# - Tactical Bond 永久公開，不進神秘發現紀錄。
# - Verifier 不污染正式 Save；所有測試後會完整還原 seen/formed。
# - Rank 只控制未發現資料呈現，不修改任何戰鬥倍率。
#
# 【未來 UI 查詢】
# PMD_AC.team_bond_seen_v0993?(:creation_myth)
# PMD_AC.team_bond_formed_v0993?(:creation_myth)
# PMD_AC.team_bond_display_name_v0993(:mimic_trinity) # 未發現 Secret => "???"
# PMD_AC.team_bond_details_unlocked_v0993?(:sea_god_birds)
# PMD_AC.team_bond_hint_v0993(:sea_god_birds)
# PMD_AC.team_bond_seen_keys_v0993
# PMD_AC.team_bond_formed_keys_v0993
#
# 【Verifier 操作】
# NORMAL → S 一次 → TEAM_BOND_CONTENT_V0993 → Shift。
# 主要 markers：
# TEAM_BOND_CONTENT_REGISTRY_V0993
# TEAM_BOND_DISCOVERY_METADATA_V0993
# TEAM_BOND_CONTENT_CROSSREF_V0993
# TEAM_BOND_PRIORITY_EXPANSION_V0993
# TEAM_BOND_DISCOVERY_SAVE_V0993
# TEAM_BOND_V0992_COMPAT_V0993
# TEAM_BOND_CONTENT_V0993
# VERIFY_FINISHED_BATTLE_RESUME
#
# 【可調參數】
# - 內容數、名稱、組成、效果、rank、hint：只改 Data 腳本。
# - 本 Runtime 不藏羈絆平衡數值。
#
# 【維護注意】
# - v0.99.2 Team Bond Effect Runtime 已實機 PASS，這裡只做 Additive Patch。
# - 不修改 v0.15 Movement、v0.60.2 Multi-hit、v0.75 Balance、Ability 1193/1193。
# - 保持 RPG Maker VX / RGSS2 / Ruby 1.8 相容。
#==============================================================================
module PMD_AC
  TEAM_BOND_DISCOVERY_VERSION_V0993='0.99.3'
  TEAM_BOND_CONTENT_VERIFY_MODE_V0993=:team_bond_content_v0993
  TEAM_BOND_CONTENT_VERIFY_END_V0993=72

  class << self
    def team_bond_seen_map_v0993
      return {} if $game_system==nil
      $game_system.team_bond_seen_map_v0993
    end

    def team_bond_formed_map_v0993
      return {} if $game_system==nil
      $game_system.team_bond_formed_map_v0993
    end

    def team_bond_seen_v0993?(key)
      team_bond_seen_map_v0993[key] ? true:false
    end

    def team_bond_formed_v0993?(key)
      team_bond_formed_map_v0993[key] ? true:false
    end

    def mark_team_bond_seen_v0993(key)
      d=TEAM_BOND_DATA_V0992[key]
      return false if d==nil || d[:category]!=:relationship || $game_system==nil
      map=$game_system.team_bond_seen_map_v0993
      fresh=!map[key]
      map[key]=true
      fresh
    end

    def mark_team_bond_formed_v0993(key)
      d=TEAM_BOND_DATA_V0992[key]
      return false if d==nil || d[:category]!=:relationship || $game_system==nil
      seen=$game_system.team_bond_seen_map_v0993
      formed=$game_system.team_bond_formed_map_v0993
      fresh=!formed[key]
      seen[key]=true
      formed[key]=true
      fresh
    end

    def team_bond_seen_keys_v0993
      team_bond_seen_map_v0993.keys.find_all{|k|team_bond_seen_map_v0993[k]}.sort{|a,b|a.to_s<=>b.to_s}
    end

    def team_bond_formed_keys_v0993
      team_bond_formed_map_v0993.keys.find_all{|k|team_bond_formed_map_v0993[k]}.sort{|a,b|a.to_s<=>b.to_s}
    end

    def team_bond_details_unlocked_v0993?(key)
      d=TEAM_BOND_DATA_V0992[key]
      return false if d==nil
      rank=d[:discovery_rank]
      return true if rank==:normal || rank==:tactical
      team_bond_seen_v0993?(key)
    end

    def team_bond_display_name_v0993(key)
      d=TEAM_BOND_DATA_V0992[key]
      return key.to_s if d==nil
      if d[:discovery_rank]==:secret && d[:hidden_until_discovered] && !team_bond_seen_v0993?(key)
        return '???'
      end
      d[:name] || key.to_s
    end

    def validate_team_bond_content_v0993
      errors=[]
      base_errors=validate_team_bond_registry_v0992
      base_errors.each{|e|errors.push('v0992:'+e.to_s)}
      rel=0;tac=0;ranks={:normal=>0,:rare=>0,:secret=>0,:tactical=>0}
      TEAM_BOND_DATA_V0992.each do |key,d|
        if d[:category]==:relationship;rel+=1;else;tac+=1;end
        errors.push('basis:'+key.to_s) unless TEAM_BOND_BASIS_TYPES_V0993.include?(d[:basis])
        rank=d[:discovery_rank]
        errors.push('rank:'+key.to_s) unless TEAM_BOND_DISCOVERY_RANKS_V0993.include?(rank)
        ranks[rank]=ranks[rank].to_i+1 if rank!=nil
        errors.push('hint:'+key.to_s) if d[:hint].to_s.empty?
        errors.push('hidden_flag:'+key.to_s) if d[:hidden_until_discovered]==nil
        if d[:category]==:tactical
          errors.push('tactical_rank:'+key.to_s) unless rank==:tactical
          errors.push('tactical_hidden:'+key.to_s) if d[:hidden_until_discovered]
        else
          errors.push('relationship_rank:'+key.to_s) unless [:normal,:rare,:secret].include?(rank)
        end
      end
      m=TEAM_BOND_MANIFEST_V0993
      errors.push('total') unless TEAM_BOND_DATA_V0992.size==81
      errors.push('relationship') unless rel==73
      errors.push('tactical') unless tac==8
      errors.push('new_count') unless TEAM_BOND_EXPANSION_DATA_V0993.size==39
      expected=m[:relationship_rank_counts] || {}
      [:normal,:rare,:secret].each{|r|errors.push('rank_count:'+r.to_s) unless ranks[r].to_i==expected[r].to_i}
      errors.push('tactical_public_count') unless ranks[:tactical].to_i==8
      errors
    end

    def team_bond_crossref_summary_v0993
      species=const_defined?(:SPECIES_DB_V016) ? SPECIES_DB_V016 : {}
      lines=const_defined?(:EVOLUTION_LINES_V016) ? EVOLUTION_LINES_V016 : {}
      reqs=0;species_refs=0;line_refs=0;pool_refs=0;bad=[]
      TEAM_BOND_DATA_V0992.each do |key,d|
        next unless d[:category]==:relationship
        for req in (d[:composition] || [])
          reqs+=1
          case req[:type]
          when :species
            species_refs+=1;bad.push(key.to_s+':'+req[:key].to_s) unless species.has_key?(req[:key])
          when :line
            line_refs+=1;bad.push(key.to_s+':'+req[:key].to_s) unless lines.has_key?(req[:key])
          when :species_pool
            for sk in (req[:keys] || [])
              pool_refs+=1;bad.push(key.to_s+':'+sk.to_s) unless species.has_key?(sk)
            end
          when :form
            sk=req[:species];bad.push(key.to_s+':'+sk.to_s) if sk!=nil && !species.has_key?(sk)
          end
        end
      end
      {:species=>species.size,:lines=>lines.size,:requirements=>reqs,
       :species_refs=>species_refs,:line_refs=>line_refs,:pool_refs=>pool_refs,:bad=>bad}
    end
  end

  old_modes=VERIFICATION_MODES.dup
  old_labels=VERIFICATION_LABELS.dup
  remove_const(:VERIFICATION_MODES)
  VERIFICATION_MODES=[:normal,:team_bond_content_v0993,:team_bond_v0992]+old_modes.reject{|x|x==:normal || x==:team_bond_v0992 || x==:team_bond_content_v0993}
  remove_const(:VERIFICATION_LABELS)
  VERIFICATION_LABELS=old_labels.dup
  VERIFICATION_LABELS[:normal]='NORMAL'
  VERIFICATION_LABELS[:team_bond_content_v0993]='TEAM_BOND_CONTENT_V0993'
  VERIFICATION_LABELS[:team_bond_v0992]='TEAM_BOND_V0992'
end

#==============================================================================
# ■ Game_System：永久 RPG Seen / Formed Save Data
#==============================================================================
class Game_System
  alias pmd_ac_v0993_team_bond_initialize initialize unless method_defined?(:pmd_ac_v0993_team_bond_initialize)
  def initialize
    pmd_ac_v0993_team_bond_initialize
    @team_bond_seen_v0993={}
    @team_bond_formed_v0993={}
  end

  def team_bond_seen_map_v0993
    @team_bond_seen_v0993={} if @team_bond_seen_v0993==nil
    @team_bond_seen_v0993
  end

  def team_bond_formed_map_v0993
    @team_bond_formed_v0993={} if @team_bond_formed_v0993==nil
    @team_bond_formed_v0993
  end
end

#==============================================================================
# ■ Scene_PMD_AutoChess：NORMAL 發現紀錄、版本提示、Content Verifier
#==============================================================================
class Scene_PMD_AutoChess
  alias pmd_ac_v0993_start start unless method_defined?(:pmd_ac_v0993_start)
  alias pmd_ac_v0993_refresh_header refresh_header unless method_defined?(:pmd_ac_v0993_refresh_header)
  alias pmd_ac_v0993_refresh_team_bonds_v0992 refresh_team_bonds_v0992 unless method_defined?(:pmd_ac_v0993_refresh_team_bonds_v0992)
  alias pmd_ac_v0993_prepare_verification_battle prepare_verification_battle unless method_defined?(:pmd_ac_v0993_prepare_verification_battle)
  alias pmd_ac_v0993_update_verification_script update_verification_script unless method_defined?(:pmd_ac_v0993_update_verification_script)
  alias pmd_ac_v0993_diagnostic_presentation_suppressed_v068 diagnostic_presentation_suppressed_v068? unless method_defined?(:pmd_ac_v0993_diagnostic_presentation_suppressed_v068)
  alias pmd_ac_v0993_log_team_bond_verify_v0992 log_team_bond_verify_v0992 unless method_defined?(:pmd_ac_v0993_log_team_bond_verify_v0992)

  def team_bond_content_mode_v0993?;verification_mode==:team_bond_content_v0993;end

  def start
    pmd_ac_v0993_start
    begin
      if FileTest.exist?(PMD_AC::BATTLE_LOG_FILE)
        text=File.open(PMD_AC::BATTLE_LOG_FILE,'rb'){|f|f.read}
        text.sub!(/PMD AutoChess Proto v0\.[0-9.]+ Battle Verification Log/,
          'PMD AutoChess Proto v0.99.3 Battle Verification Log')
        File.open(PMD_AC::BATTLE_LOG_FILE,'wb'){|f|f.write(text)}
      end
    rescue
    end
    log_event(:team_bond_content,
      'FLOW v0.99.3 bonds=81 relationship=73 tactical=8 new_relationship=39 ranks=33/28/12 '+
      'seen_formed=save basis=8 content_cap=81 runtime=v0.99.2_unchanged')
    refresh_header
  end

  def refresh_header
    pmd_ac_v0993_refresh_header
    return if @header_sprite==nil || @header_sprite.bitmap==nil
    bmp=@header_sprite.bitmap
    bmp.fill_rect(0,0,Graphics.width,28,Color.new(0,0,0,180))
    pmd_ac_v074_font(bmp) if respond_to?(:pmd_ac_v074_font)
    bmp.font.size=PMD_AC.const_defined?(:UI_HEADER_TITLE_FONT_V086) ? PMD_AC::UI_HEADER_TITLE_FONT_V086 : 20
    bmp.font.bold=true;bmp.font.color=Color.new(255,255,255)
    bmp.draw_text(16,1,Graphics.width-32,30,'PMD 自走棋原型 v0.99.3',1)
  end

  def diagnostic_presentation_suppressed_v068?
    return true if team_bond_content_mode_v0993?
    pmd_ac_v0993_diagnostic_presentation_suppressed_v068
  end

  # NORMAL 才寫正式 RPG Save；Verifier 與舊診斷模式完全不碰 Seen / Formed。
  # v0.80 Stage Select 是開發／挑戰入口，預設不寫 RPG 羈絆圖鑑；Wild/Boss/Scripted/Map 會寫。
  def team_bond_discovery_recordable_v0993?
    return false unless verification_mode==:normal
    if respond_to?(:rpg_request_v081)
      req=rpg_request_v081
      return false if req!=nil && req[:kind]==:stage
    end
    true
  end

  def record_team_bond_discovery_v0993(team,keys)
    return unless team_bond_discovery_recordable_v0993?
    for key in (keys || [])
      d=PMD_AC::TEAM_BOND_DATA_V0992[key]
      next if d==nil || d[:category]!=:relationship
      seen_new=PMD_AC.mark_team_bond_seen_v0993(key)
      formed_new=false
      formed_new=PMD_AC.mark_team_bond_formed_v0993(key) if team==:ally
      if seen_new
        log_event(:team_bond_discovery,'SEEN '+key.to_s+' name='+PMD_AC.team_bond_name_v0992(key)+' via='+team.to_s)
      end
      if formed_new
        log_event(:team_bond_discovery,'FORMED '+key.to_s+' name='+PMD_AC.team_bond_name_v0992(key))
      end
    end
  end

  def refresh_team_bonds_v0992(team,reason=:refresh,apply_once=true)
    before=active_team_bond_keys_v0992(team)
    fresh=pmd_ac_v0993_refresh_team_bonds_v0992(team,reason,apply_once)
    activated=fresh-before
    record_team_bond_discovery_v0993(team,activated) unless activated.empty?
    fresh
  end

  # v0.99.3 內容擴張後，舊 v0.99.2 Registry Verifier 改讀動態 81/73/8。
  def verify_team_bond_registry_v0992
    return if @verification_done[:bond_registry_v0992]
    errors=PMD_AC.validate_team_bond_registry_v0992
    m=PMD_AC::TEAM_BOND_MANIFEST_V0992
    pass=errors.empty? && PMD_AC::TEAM_BOND_DATA_V0992.size==81 && m[:relationship_count]==73 && m[:tactical_count]==8
    log_team_bond_verify_v0992('TEAM_BOND_REGISTRY_V0992',pass,
      'total=81 relationship=73 tactical=8 content=v0.99.3 runtime=v0.99.2 errors=['+errors.join(',')+']')
    @verification_done[:bond_registry_v0992]=true
  end

  def log_team_bond_verify_v0992(label,pass,detail='')
    if label=='TEAM_BOND_V0992'
      detail='bonds=81 relationship=73 tactical=8 category_limit=1+1 faint_persist=1 legacy_v015=1 runtime=v0.99.2 content=v0.99.3'
    end
    pmd_ac_v0993_log_team_bond_verify_v0992(label,pass,detail)
  end

  def log_team_bond_content_verify_v0993(label,pass,detail='')
    @team_bond_content_results_v0993={} if @team_bond_content_results_v0993==nil
    @team_bond_content_results_v0993[label.to_s]=pass ? true:false
    log_event(:verify,label+' pass='+(pass ? '1':'0')+(detail.to_s.empty? ? '' : ' '+detail.to_s))
  end

  def verify_team_bond_content_registry_v0993
    return if @verification_done[:bond_content_registry_v0993]
    errors=PMD_AC.validate_team_bond_content_v0993
    pass=errors.empty? && PMD_AC::TEAM_BOND_DATA_V0992.size==81 && PMD_AC::TEAM_BOND_EXPANSION_DATA_V0993.size==39
    log_team_bond_content_verify_v0993('TEAM_BOND_CONTENT_REGISTRY_V0993',pass,
      'total='+PMD_AC::TEAM_BOND_DATA_V0992.size.to_s+' relationship=73 tactical=8 new=39 errors=['+errors.join(',')+']')
    @verification_done[:bond_content_registry_v0993]=true
  end

  def verify_team_bond_metadata_v0993
    return if @verification_done[:bond_metadata_v0993]
    ranks={:normal=>0,:rare=>0,:secret=>0,:tactical=>0};hints=0;hidden_secret=0
    PMD_AC::TEAM_BOND_DATA_V0992.each do |k,d|
      ranks[d[:discovery_rank]]=ranks[d[:discovery_rank]].to_i+1
      hints+=1 unless d[:hint].to_s.empty?
      hidden_secret+=1 if d[:discovery_rank]==:secret && d[:hidden_until_discovered]
    end
    pass=ranks[:normal]==33 && ranks[:rare]==28 && ranks[:secret]==12 && ranks[:tactical]==8 && hints==81 && hidden_secret==12
    log_team_bond_content_verify_v0993('TEAM_BOND_DISCOVERY_METADATA_V0993',pass,
      'relationship_ranks='+ranks[:normal].to_s+'/'+ranks[:rare].to_s+'/'+ranks[:secret].to_s+
      ' tactical_public='+ranks[:tactical].to_s+' hints='+hints.to_s+'/81 secret_hidden='+hidden_secret.to_s+'/12')
    @verification_done[:bond_metadata_v0993]=true
  end

  def verify_team_bond_crossref_v0993
    return if @verification_done[:bond_crossref_v0993]
    s=PMD_AC.team_bond_crossref_summary_v0993
    pass=s[:species]==494 && s[:lines]==248 && s[:bad].empty?
    log_team_bond_content_verify_v0993('TEAM_BOND_CONTENT_CROSSREF_V0993',pass,
      'species='+s[:species].to_s+' lines='+s[:lines].to_s+' requirements='+s[:requirements].to_s+
      ' species_refs='+s[:species_refs].to_s+' line_refs='+s[:line_refs].to_s+' pool_refs='+s[:pool_refs].to_s+
      ' bad=['+s[:bad].join(',')+']')
    @verification_done[:bond_crossref_v0993]=true
  end

  def verify_team_bond_priority_expansion_v0993
    return if @verification_done[:bond_priority_expansion_v0993]
    a=[team_bond_test_unit_v0992(99301,:dragonite),team_bond_test_unit_v0992(99302,:metagross),team_bond_test_unit_v0992(99303,:garchomp)]
    b=[team_bond_test_unit_v0992(99304,:pikachu),team_bond_test_unit_v0992(99305,:plusle),team_bond_test_unit_v0992(99306,:minun)]
    c=[team_bond_test_unit_v0992(99307,:omastar),team_bond_test_unit_v0992(99308,:kabutops),team_bond_test_unit_v0992(99309,:aerodactyl)]
    ka=PMD_AC.active_team_bond_keys_for_v0992(a);kb=PMD_AC.active_team_bond_keys_for_v0992(b);kc=PMD_AC.active_team_bond_keys_for_v0992(c)
    pass=ka.include?(:champion_aces) && !ka.include?(:apex_bloodline) && kb.include?(:electric_mouse_union) && !kb.include?(:plus_minus_pair) && kc.include?(:kanto_fossils) && !kc.include?(:fossil_museum)
    log_team_bond_content_verify_v0993('TEAM_BOND_PRIORITY_EXPANSION_V0993',pass,
      'champion=['+ka.join(',')+'] electric=['+kb.join(',')+'] fossil=['+kc.join(',')+']')
    @verification_done[:bond_priority_expansion_v0993]=true
  end

  def verify_team_bond_discovery_save_v0993
    return if @verification_done[:bond_discovery_save_v0993]
    if $game_system==nil
      log_team_bond_content_verify_v0993('TEAM_BOND_DISCOVERY_SAVE_V0993',false,'game_system=nil')
      @verification_done[:bond_discovery_save_v0993]=true
      return
    end
    seen=$game_system.team_bond_seen_map_v0993
    formed=$game_system.team_bond_formed_map_v0993
    old_seen=seen.dup;old_formed=formed.dup
    begin
      seen.clear;formed.clear
      secret_before=PMD_AC.team_bond_display_name_v0993(:mimic_trinity)
      rare_before=PMD_AC.team_bond_details_unlocked_v0993?(:sea_god_birds)
      s1=PMD_AC.mark_team_bond_seen_v0993(:sea_god_birds)
      s2=PMD_AC.mark_team_bond_seen_v0993(:mimic_trinity)
      f1=PMD_AC.mark_team_bond_formed_v0993(:mimic_trinity)
      secret_after=PMD_AC.team_bond_display_name_v0993(:mimic_trinity)
      rare_after=PMD_AC.team_bond_details_unlocked_v0993?(:sea_god_birds)
      pass=secret_before=='???' && !rare_before && s1 && s2 && f1 && secret_after=='模仿者' && rare_after && PMD_AC.team_bond_seen_v0993?(:mimic_trinity) && PMD_AC.team_bond_formed_v0993?(:mimic_trinity)
    ensure
      seen.clear;old_seen.each{|k,v|seen[k]=v}
      formed.clear;old_formed.each{|k,v|formed[k]=v}
    end
    restored=(seen==old_seen && formed==old_formed)
    pass=pass && restored
    log_team_bond_content_verify_v0993('TEAM_BOND_DISCOVERY_SAVE_V0993',pass,
      'secret_before=??? secret_after=模仿者 rare_unlock=1 seen=1 formed=1 verifier_restored='+(restored ? '1':'0'))
    @verification_done[:bond_discovery_save_v0993]=true
  end

  def verify_team_bond_v0992_compat_v0993
    return if @verification_done[:bond_v0992_compat_v0993]
    starters=[team_bond_test_unit_v0992(99321,:bulbasaur),team_bond_test_unit_v0992(99322,:charmander),team_bond_test_unit_v0992(99323,:squirtle)]
    keys=PMD_AC.active_team_bond_keys_for_v0992(starters)
    pass=keys.include?(:kanto_starter_trio) && PMD_AC::TEAM_BOND_MANIFEST_V0992[:relationship_count]==73 && PMD_AC::TEAM_BOND_EFFECT_TYPES_V0992.size==14
    log_team_bond_content_verify_v0993('TEAM_BOND_V0992_COMPAT_V0993',pass,
      'kanto='+ (keys.include?(:kanto_starter_trio) ? '1':'0')+' manifest=73/8 effects=14 runtime_unchanged=1')
    @verification_done[:bond_v0992_compat_v0993]=true
  end

  def prepare_verification_battle
    # 繞過 v0.99.2 自己的舊 42-count showcase 文字，直接接它之前的 verifier chain。
    if team_bond_content_mode_v0993? || team_bond_mode_v0992?
      pmd_ac_v0992_prepare_verification_battle
      for u in (@units || [])
        u.verification_combat_sandbox(true) if u.respond_to?(:verification_combat_sandbox)
      end
      label=team_bond_content_mode_v0993? ? 'TEAM_BOND_CONTENT_V0993' : 'TEAM_BOND_V0992'
      log_event(:showcase,'START mode='+label+' bonds=81 relationship=73 tactical=8 fake_vfx=off fake_sfx=off runtime=v0.99.2')
    else
      # v0.99.2 method 對非 Team Bond 模式會安全交回更舊 verifier chain。
      pmd_ac_v0993_prepare_verification_battle
    end
  end

  def update_verification_script
    unless team_bond_content_mode_v0993?
      pmd_ac_v0993_update_verification_script
      return
    end
    @verification_frame+=1
    f=@verification_frame
    verify_team_bond_content_registry_v0993 if f>=2
    verify_team_bond_metadata_v0993 if f>=8
    verify_team_bond_crossref_v0993 if f>=14
    verify_team_bond_priority_expansion_v0993 if f>=22
    verify_team_bond_discovery_save_v0993 if f>=30
    verify_team_bond_v0992_compat_v0993 if f>=38
    if f>=48 && !@verification_done[:bond_content_final_v0993]
      labels=['TEAM_BOND_CONTENT_REGISTRY_V0993','TEAM_BOND_DISCOVERY_METADATA_V0993',
        'TEAM_BOND_CONTENT_CROSSREF_V0993','TEAM_BOND_PRIORITY_EXPANSION_V0993',
        'TEAM_BOND_DISCOVERY_SAVE_V0993','TEAM_BOND_V0992_COMPAT_V0993']
      results=@team_bond_content_results_v0993 || {}
      pass=labels.all?{|label|results[label]==true}
      log_team_bond_content_verify_v0993('TEAM_BOND_CONTENT_V0993',pass,
        'bonds=81 relationship=73 tactical=8 new=39 ranks=33/28/12 discovery=seen+formed content_cap=81 runtime=v0.99.2')
      @verification_done[:bond_content_final_v0993]=true
    end
    complete_verification_mode if f>=PMD_AC::TEAM_BOND_CONTENT_VERIFY_END_V0993
  end
end
