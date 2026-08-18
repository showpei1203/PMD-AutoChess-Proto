# encoding: UTF-8
#==============================================================================
# 【PMD AutoChess 中文維護說明】
# 腳本：PMD AutoChess Content Validation Runtime v0.95
# 分類：量產內容驗證／Verifier／報告輸出
#
# 【用途】
# 把 Content Validation Data v0.95 接到既有 Battle Verification 系統。布陣畫面從
# NORMAL 按 S 一次會先到 CONTENT_VALIDATION_V095，再按 Shift 執行跨資料庫檢查。
# 驗證只讀資料，不修改 Pokémon、HP、Energy、AI、Reward 或存檔內容。
#
# 【主要設定項】
# - 驗證模式：:content_validation_v095
# - 完成幀：PMD_AC::CONTENT_VALIDATION_VERIFY_END_V095
# - 報告檔：PMD_ContentValidation_v0.95.log
#
# 【機制規則】
# - Verifier 開始時只建立一次 validation report，後續各 PASS line 共用同一份結果。
# - ERROR 數 > 0 才讓最終 CONTENT_VALIDATION_V095 pass=0。
# - WARN 代表 Roadmap Known Gap；會讓 production_ready=0，但 Core 仍可 pass=1。
# - complete_verification_mode 仍走既有共通流程，必須最後輸出
#   VERIFY_FINISHED_BATTLE_RESUME pass=1，確保 AI／Movement 恢復。
#
# 【事件／腳本呼叫方式】
# 正常驗證：布陣 NORMAL → S 一次 → CONTENT_VALIDATION_V095 → Shift。
#
# 不進戰鬥也可直接輸出報告：
#   PMD_AC.write_content_validation_report_v095
#
# 【實際範例】
# 正常通過時應看到：
#   CONTENT_SPECIES_V095 pass=1 species=494 learnset=7005
#   CONTENT_MOVE_BRIDGE_V095 pass=1 executable=526
#   CONTENT_VALIDATION_V095 pass=1 errors=0 warnings=2 core_ready=1 production_ready=0
#
# 【注意事項】
# - RPG Maker VX / RGSS2 / Ruby 1.8 相容。
# - 禁止使用舊式 instance-variable reflection probe。
# - v0.94 Walk/Hop、Loot Economy、v0.93 圖鑑、v0.92 Map、v0.91 AI/Boss 全保留。
#==============================================================================
module PMD_AC
  V095_OLD_VERIFICATION_MODES = VERIFICATION_MODES.dup
  V095_OLD_VERIFICATION_LABELS = VERIFICATION_LABELS.dup
  remove_const(:VERIFICATION_MODES)
  VERIFICATION_MODES = [:normal,:content_validation_v095] +
    V095_OLD_VERIFICATION_MODES.reject{|x|x==:normal || x==:content_validation_v095}
  remove_const(:VERIFICATION_LABELS)
  VERIFICATION_LABELS = V095_OLD_VERIFICATION_LABELS.dup
  VERIFICATION_LABELS[:normal]='NORMAL'
  VERIFICATION_LABELS[:content_validation_v095]='CONTENT_VALIDATION_V095'
end

class Scene_PMD_AutoChess
  alias pmd_ac_v095_start start unless method_defined?(:pmd_ac_v095_start)
  alias pmd_ac_v095_refresh_header refresh_header unless method_defined?(:pmd_ac_v095_refresh_header)
  alias pmd_ac_v095_prepare_verification_battle prepare_verification_battle unless method_defined?(:pmd_ac_v095_prepare_verification_battle)
  alias pmd_ac_v095_update_verification_script update_verification_script unless method_defined?(:pmd_ac_v095_update_verification_script)
  alias pmd_ac_v095_log_event log_event unless method_defined?(:pmd_ac_v095_log_event)

  def start
    pmd_ac_v095_start
    begin
      if FileTest.exist?(PMD_AC::BATTLE_LOG_FILE)
        text=File.open(PMD_AC::BATTLE_LOG_FILE,'rb'){|f|f.read}
        text.sub!(/PMD AutoChess Proto v0\.[0-9.]+ Battle Verification Log/,
          'PMD AutoChess Proto v0.95 Battle Verification Log')
        File.open(PMD_AC::BATTLE_LOG_FILE,'wb'){|f|f.write(text)}
      end
    rescue
    end
    log_event(:content_validation,
      'FLOW v0.95 species=494 move_db=559 executable=526 learnset=7005 ability_runtime=1028/1193 pmd_test=0001-0026 crossref=stage+region+boss+loot errors_fail=1 warnings_fail=0')
    refresh_header
  end

  def refresh_header
    pmd_ac_v095_refresh_header
    return if @header_sprite==nil || @header_sprite.bitmap==nil
    bmp=@header_sprite.bitmap
    bmp.fill_rect(0,0,Graphics.width,28,Color.new(0,0,0,180))
    pmd_ac_v074_font(bmp)
    bmp.font.size=PMD_AC.const_defined?(:UI_HEADER_TITLE_FONT_V086) ? PMD_AC::UI_HEADER_TITLE_FONT_V086 : 20
    bmp.font.bold=true
    bmp.font.color=Color.new(255,255,255)
    bmp.draw_text(16,1,Graphics.width-32,30,'PMD 自走棋原型 v0.95',1)
  end

  def content_validation_v095?
    verification_mode==:content_validation_v095
  end

  def prepare_verification_battle
    pmd_ac_v095_prepare_verification_battle
    return unless content_validation_v095?
    @content_validation_failed_v095=false
    @content_validation_report_v095=PMD_AC.content_validation_report_v095
    @content_validation_report_written_v095=PMD_AC.write_content_validation_report_v095(@content_validation_report_v095)
    log_event(:showcase,
      'START mode=CONTENT_VALIDATION_V095 crossref=full errors='+@content_validation_report_v095[:errors].size.to_s+
      ' warnings='+@content_validation_report_v095[:warnings].size.to_s)
  end

  def log_event(category,message)
    if category.to_s=='verify' && content_validation_v095? &&
       message.to_s.index('V095')!=nil && message.to_s.include?(' pass=0')
      @content_validation_failed_v095=true
    end
    pmd_ac_v095_log_event(category,message)
  end

  def log_verify_v095(name,pass,detail='')
    @content_validation_failed_v095=true unless pass
    log_event(:verify,name+' pass='+(pass ? '1':'0')+(detail=='' ? '' : ' '+detail))
  end

  def content_report_v095
    @content_validation_report_v095 ||= PMD_AC.content_validation_report_v095
  end

  def verify_content_species_v095
    return if @verification_done[:v095_species]
    s=content_report_v095[:sections][:species]||{}
    log_verify_v095('CONTENT_SPECIES_V095',s[:pass] ? true:false,
      'species='+s[:species].to_i.to_s+' dex='+s[:dex].to_i.to_s+
      ' lines='+s[:lines].to_i.to_s+' forms='+s[:forms].to_i.to_s+
      ' learnset='+s[:learnset_refs].to_i.to_s+
      ' evo_errors='+s[:bad_evolution].to_i.to_s+
      ' tactical_errors='+s[:bad_tactical].to_i.to_s+
      ' ability_slot_corrections='+s[:ability_slot_corrections].to_i.to_s+' expected=27')
    @verification_done[:v095_species]=true
  end

  def verify_content_move_bridge_v095
    return if @verification_done[:v095_moves]
    s=content_report_v095[:sections][:moves]||{}
    log_verify_v095('CONTENT_MOVE_BRIDGE_V095',s[:pass] ? true:false,
      'move_db='+s[:move_db].to_i.to_s+' executable='+s[:executable].to_i.to_s+
      ' skill='+s[:skill].to_i.to_s+' presentation='+s[:presentation].to_i.to_s+
      ' visual='+s[:visual].to_i.to_s+' audio='+s[:audio].to_i.to_s+
      ' learnset='+s[:learnset_covered].to_i.to_s+'/'+s[:learnset_total].to_i.to_s+
      ' missing='+s[:missing].to_i.to_s)
    @verification_done[:v095_moves]=true
  end

  def verify_content_ability_v095
    return if @verification_done[:v095_ability]
    s=content_report_v095[:sections][:abilities]||{}
    log_verify_v095('CONTENT_ABILITY_V095',s[:pass] ? true:false,
      'canonical_species='+s[:canonical_species].to_i.to_s+
      ' slots='+s[:runtime_slots].to_i.to_s+'/'+s[:total_slots].to_i.to_s+
      ' runtime_species='+s[:runtime_species].to_i.to_s+'/494 known_gap=1 freeze=v0.67.1')
    @verification_done[:v095_ability]=true
  end

  def verify_content_pmd_v095
    return if @verification_done[:v095_pmd]
    s=content_report_v095[:sections][:pmd]||{}
    log_verify_v095('CONTENT_PMD_ASSETS_V095',s[:pass] ? true:false,
      'compiled_species='+s[:compiled_species].to_i.to_s+
      ' compiled_entries='+s[:compiled_entries].to_i.to_s+
      ' test='+s[:installed].to_i.to_s+'/'+s[:expected_test].to_i.to_s+
      ' walk='+s[:walk].to_i.to_s+' idle='+s[:idle].to_i.to_s+
      ' hurt='+s[:hurt].to_i.to_s+' hop='+s[:hop].to_i.to_s+
      ' fulltest_subset=1')
    @verification_done[:v095_pmd]=true
  end

  def verify_content_encounters_v095
    return if @verification_done[:v095_encounters]
    s=content_report_v095[:sections][:encounters]||{}
    log_verify_v095('CONTENT_ENCOUNTER_CROSSREF_V095',s[:pass] ? true:false,
      'stages='+s[:stages].to_i.to_s+' encounters='+s[:encounters].to_i.to_s+
      ' formations='+s[:formations].to_i.to_s+' regions='+s[:regions].to_i.to_s+
      ' bosses='+s[:boss_profiles].to_i.to_s+' map_profiles='+s[:map_profiles].to_i.to_s+
      ' bad_refs='+s[:bad_refs].to_i.to_s)
    @verification_done[:v095_encounters]=true
  end

  def verify_content_loot_v095
    return if @verification_done[:v095_loot]
    s=content_report_v095[:sections][:loot]||{}
    log_verify_v095('CONTENT_LOOT_V095',s[:pass] ? true:false,
      'pools='+s[:pools].to_i.to_s+' production_bindings='+s[:production_bindings].to_i.to_s+
      ' bad='+s[:bad].to_i.to_s+' item_catalog_deferred='+(s[:item_catalog_deferred] ? '1':'0')+
      ' known_gap=1')
    @verification_done[:v095_loot]=true
  end

  def verify_content_report_file_v095
    return if @verification_done[:v095_report]
    r=content_report_v095
    pass=@content_validation_report_written_v095 && FileTest.exist?(PMD_AC::CONTENT_VALIDATION_REPORT_FILE_V095)
    log_verify_v095('CONTENT_REPORT_V095',pass,
      'errors='+r[:errors].size.to_s+' warnings='+r[:warnings].size.to_s+
      ' report='+PMD_AC::CONTENT_VALIDATION_REPORT_FILE_V095+
      ' core_ready='+(r[:core_pass] ? '1':'0')+' production_ready='+(r[:production_ready] ? '1':'0'))
    @verification_done[:v095_report]=true
  end

  def verify_content_carry_v095
    return if @verification_done[:v095_carry]
    pass=PMD_AC::BATTLE_REST_VISUAL_V094==:walk &&
      PMD_AC::LOOT_ECONOMY_MANIFEST_V094[:weighted_pick] &&
      PMD_AC::COLLECTION_MANIFEST_V093[:species]==494 &&
      PMD_AC::MAP_INTEGRATION_MANIFEST_V092[:profiles]==3 &&
      PMD_AC::BOSS_FRAMEWORK_MANIFEST_V091[:profiles]==1 &&
      PMD_AC::SPATIAL_MOVE_EXTENSIONS_V0914.size==19
    log_verify_v095('CONTENT_VALIDATION_CARRY_V095',pass,
      'motion=v0.94 loot=v0.94 collection=v0.93 map=v0.92 boss=v0.91 tactical=v0.91.4 battle_rules=unchanged')
    @verification_done[:v095_carry]=true
  end

  def update_verification_script
    unless content_validation_v095?
      pmd_ac_v095_update_verification_script
      return
    end
    return if @verification_done[:verification_complete]
    @verification_frame=@verification_frame.to_i+1
    f=@verification_frame
    verify_content_species_v095 if f>=2
    verify_content_move_bridge_v095 if f>=4
    verify_content_ability_v095 if f>=6
    verify_content_pmd_v095 if f>=8
    verify_content_encounters_v095 if f>=10
    verify_content_loot_v095 if f>=12
    verify_content_report_file_v095 if f>=14
    verify_content_carry_v095 if f>=16
    if f>=20 && !@verification_done[:v095_final]
      r=content_report_v095
      pass=!@content_validation_failed_v095 && r[:core_pass]
      log_verify_v095('CONTENT_VALIDATION_V095',pass,
        'errors='+r[:errors].size.to_s+' warnings='+r[:warnings].size.to_s+
        ' core_ready='+(r[:core_pass] ? '1':'0')+
        ' production_ready='+(r[:production_ready] ? '1':'0')+
        ' known_gaps=ability_runtime+loot_catalog')
      @verification_done[:v095_final]=true
    end
    complete_verification_mode if f>=PMD_AC::CONTENT_VALIDATION_VERIFY_END_V095
  end
end
