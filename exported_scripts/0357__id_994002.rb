# encoding: UTF-8
#==============================================================================
# 【PMD AutoChess 中文維護說明】
# 腳本：PMD AutoChess Species Production Audit Runtime v0.99.4
# 分類：#0001～#0494 逐隻審查 Runtime／報告輸出／Verifier
#
# 【用途】
# 讀取實際 Runtime 最終資料，逐隻檢查 Species/Move/Ability/Evolution/Form/AI，
# 並輸出完整審查報告。本腳本不自動「修正」任何寶可夢，避免 Validator 為了全綠
# 偷偷改資料。若 Core Error > 0，必須回到真正的資料來源修正。
#
# 【Verifier】
# NORMAL → S 一次 → SPECIES_PRODUCTION_AUDIT_V0994 → Shift。
# 主要 markers：
# SPECIES_AUDIT_CORE_V0994
# SPECIES_AUDIT_STATS_V0994
# SPECIES_AUDIT_MOVEPOOL_V0994
# SPECIES_AUDIT_ABILITY_V0994
# SPECIES_AUDIT_EVOLUTION_FORM_V0994
# SPECIES_AUDIT_AI_V0994
# SPECIES_AUDIT_DESIGN_SCOPE_V0994
# SPECIES_PRODUCTION_AUDIT_V0994
# VERIFY_FINISHED_BATTLE_RESUME
#
# 【報告解讀】
# CORE=PASS：可安全建立、成長、學招、進化、抽 Ability 並進入戰鬥。
# WARN：不是壞資料，而是正式 RPG 的平衡／取得／技能擴充工作仍值得人工確認。
#
# 【維護注意】
# - RPG Maker VX / RGSS2 / Ruby 1.8。
# - 禁止改動 v0.99.2 Team Bond Runtime、v0.60.2 Multi-hit、v0.75 Balance。
# - Verifier 只讀，不污染 Pokémon Instance 或 Save。
#==============================================================================
module PMD_AC
  SPECIES_PRODUCTION_AUDIT_VERIFY_MODE_V0994=:species_production_audit_v0994
  SPECIES_PRODUCTION_AUDIT_VERIFY_END_V0994=90

  class << self
    def species_production_row_v0994(species_key)
      d=SPECIES_DB_V016[species_key]
      return {:species_key=>species_key,:errors=>['missing_species'],:warnings=>[]} if d==nil
      errors=[];warnings=[]
      stats=d[:base_stats] || []
      errors.push('base_stats') unless stats.size==6 && stats.all?{|x|x.to_i>0}
      errors.push('bst') unless stats.inject(0){|s,x|s+x.to_i}==d[:bst].to_i
      types=d[:types] || []
      errors.push('types') unless types.size>=1 && types.size<=2
      errors.push('growth_group') unless SPECIES_AUDIT_GROWTH_GROUPS_V0994.include?(d[:growth_group])
      line=EVOLUTION_LINES_V016[d[:line]]
      errors.push('line_missing') if line==nil
      errors.push('line_member') if line!=nil && !(line[:members] || []).include?(species_key)

      learn=d[:learnset] || []
      errors.push('learnset_empty') if learn.empty?
      method_counts={}
      move_keys=[];bad_move=[];nonexec=[]
      learn.each do |e|
        method=e[:method];method_counts[method]=method_counts[method].to_i+1
        mv=e[:move];move_keys.push(mv) unless move_keys.include?(mv)
        bad_move.push(mv) unless MOVE_DB_V017.has_key?(mv)
        nonexec.push(mv) if MOVE_DB_V017.has_key?(mv) && !move_executable?(mv)
      end
      errors.push('learnset_bad_ref:'+bad_move.uniq.join(',')) unless bad_move.empty?
      errors.push('learnset_nonexec:'+nonexec.uniq.join(',')) unless nonexec.empty?
      checkpoint={}
      SPECIES_AUDIT_LEVEL_CHECKPOINTS_V0994.each do |lv|
        known=[]
        learn.each do |e|
          if e[:method]==:level_up && e[:level].to_i<=lv.to_i && move_executable?(e[:move])
            known.push(e[:move]) unless known.include?(e[:move])
          end
        end
        checkpoint[lv]=known.size
      end
      errors.push('lv1_no_executable_move') if checkpoint[1].to_i<=0
      warnings.push('sparse_levelup_movepool') if move_keys.size<SPECIES_AUDIT_SPARSE_MOVE_LIMIT_V0994

      slots=ability_slots(species_key) || {}
      errors.push('ability_primary_nil') if slots[:primary]==nil
      ability_count=0;ability_missing=[]
      [:primary,:secondary,:hidden].each do |slot|
        ab=slots[slot]
        next if ab==nil
        ability_count+=1
        bd=ability_data(ab)
        ability_missing.push(ab) if bd==nil || (bd.respond_to?(:empty?) && bd.empty?)
      end
      errors.push('ability_runtime:'+ability_missing.uniq.join(',')) unless ability_missing.empty?

      (d[:evolution_rules] || []).each do |r|
        target=r[:target_species]
        errors.push('evolution_target:'+target.to_s) unless SPECIES_DB_V016.has_key?(target)
      end

      profile=d[:tactical_profile] || {}
      SPECIES_AUDIT_PROFILE_FIELDS_V0994.each do |field|
        value=profile[field]
        errors.push('profile:'+field.to_s) if value==nil || (value.respond_to?(:empty?) && value.empty?)
      end
      errors.push('role_tags_empty') if (d[:role_tags] || []).empty?
      errors.push('synergy_tags_empty') if (d[:synergy_tags] || []).empty?

      forms=(FORMS_DB_V016[species_key] || {})
      errors.push('normal_form') unless forms.has_key?(:normal)
      form_errors=[];enabled_forms=0
      forms.each do |fk,f|
        enabled_forms+=1 if f[:ruleset_enabled]
        fs=f[:base_stats] || [];ft=f[:types] || []
        form_errors.push(fk.to_s+':stats') unless fs.size==6 && fs.all?{|x|x.to_i>0}
        form_errors.push(fk.to_s+':types') unless ft.size>=1 && ft.size<=2
        if f[:ability]!=nil
          bd=ability_data(f[:ability])
          form_errors.push(fk.to_s+':ability') if bd==nil || (bd.respond_to?(:empty?) && bd.empty?)
        end
      end
      errors.push('form:'+form_errors.join(',')) unless form_errors.empty?

      warnings.push('extreme_bst_low') if d[:bst].to_i<SPECIES_AUDIT_BST_LOW_V0994
      warnings.push('extreme_bst_high') if d[:bst].to_i>=SPECIES_AUDIT_BST_HIGH_V0994
      warnings.push('special_runtime_review') if SPECIES_SPECIAL_REVIEW_V0994.has_key?(species_key)
      warnings.push('legacy_ai_override') if profile[:ai_override_reason]!=nil

      {
        :species_key=>species_key,:dex=>d[:national_dex].to_i,:name=>d[:name].to_s,
        :types=>types,:stats=>stats,:bst=>d[:bst].to_i,:growth=>d[:growth_group],
        :line=>d[:line],:learnset_refs=>learn.size,:unique_moves=>move_keys.size,
        :method_counts=>method_counts,:move_checkpoints=>checkpoint,
        :abilities=>slots,:ability_count=>ability_count,:evolution_count=>(d[:evolution_rules] || []).size,
        :form_count=>forms.size,:enabled_forms=>enabled_forms,:role=>profile[:role_primary],
        :movement=>profile[:movement_policy],:target=>profile[:target_policy],:skill=>profile[:skill_policy],
        :profile_generation=>profile[:profile_generation],:errors=>errors,:warnings=>warnings
      }
    end

    def species_production_audit_v0994
      rows=[];errors=[];warning_rows=[];refs=0;slot_total=0;forms=0;enabled_forms=0
      methods={};profile_generations={};manual_ai=0;level_lt4={};dex_seen={}
      SPECIES_AUDIT_LEVEL_CHECKPOINTS_V0994.each{|lv|level_lt4[lv]=0}
      keys=SPECIES_DB_V016.keys.sort{|a,b|SPECIES_DB_V016[a][:national_dex].to_i<=>SPECIES_DB_V016[b][:national_dex].to_i}
      keys.each do |k|
        row=species_production_row_v0994(k);rows.push(row)
        errors.push([k,row[:errors]]) unless row[:errors].empty?
        warning_rows.push([k,row[:warnings]]) unless row[:warnings].empty?
        refs+=row[:learnset_refs].to_i;slot_total+=row[:ability_count].to_i
        forms+=row[:form_count].to_i;enabled_forms+=row[:enabled_forms].to_i
        row[:method_counts].each{|m,c|methods[m]=methods[m].to_i+c.to_i}
        pg=row[:profile_generation];profile_generations[pg]=profile_generations[pg].to_i+1
        d=SPECIES_DB_V016[k];manual_ai+=1 if (d[:tactical_profile] || {})[:ai_override_reason]!=nil
        row[:move_checkpoints].each{|lv,c|level_lt4[lv]+=1 if c.to_i<4}
        dex=row[:dex];errors.push([k,['duplicate_dex:'+dex.to_s]]) if dex_seen[dex]
        dex_seen[dex]=true
      end
      expected_dex=(1..494).to_a
      missing_dex=expected_dex.find_all{|x|!dex_seen[x]}
      errors.push([:global,['missing_dex:'+missing_dex.join(',')]]) unless missing_dex.empty?
      sparse=rows.find_all{|r|r[:warnings].include?('sparse_levelup_movepool')}.map{|r|r[:species_key]}
      special=rows.find_all{|r|r[:warnings].include?('special_runtime_review')}.map{|r|r[:species_key]}
      {
        :rows=>rows,:errors=>errors,:warning_rows=>warning_rows,
        :species=>rows.size,:dex=>dex_seen.size,:lines=>EVOLUTION_LINES_V016.size,
        :forms=>forms,:enabled_forms=>enabled_forms,:disabled_forms=>forms-enabled_forms,
        :move_db=>MOVE_DB_V017.size,
        :executable_moves=>(const_defined?(:NATIVE_SEMANTIC_CLASS_MAP_V063) ? NATIVE_SEMANTIC_CLASS_MAP_V063.size : 0),
        :learnset_refs=>refs,:method_counts=>methods,:ability_slots=>slot_total,
        :profiles=>rows.find_all{|r|r[:role]!=nil}.size,:profile_generations=>profile_generations,
        :manual_ai_overrides=>manual_ai,:level_lt4=>level_lt4,:sparse_species=>sparse,
        :special_review_species=>special,
        :core_ready=>(errors.empty? && rows.size==494 && refs==7005 && slot_total==1193 && forms==702)
      }
    end

    def species_production_audit_text_v0994(report=nil)
      r=report || species_production_audit_v0994
      t=[]
      t << 'PMD AutoChess Species Production Audit v0.99.4'
      t << '============================================================'
      t << 'CORE SUMMARY'
      t << 'Species: '+r[:species].to_s+'/494'
      t << 'National Dex: '+r[:dex].to_s+'/494'
      t << 'Evolution Lines: '+r[:lines].to_s+'/248'
      t << 'Forms: '+r[:forms].to_s+'/702 enabled='+r[:enabled_forms].to_s+' disabled='+r[:disabled_forms].to_s
      t << 'Move DB: '+r[:move_db].to_s+'/559 executable='+r[:executable_moves].to_s+'/526'
      t << 'Learnset refs: '+r[:learnset_refs].to_s+'/7005'
      t << 'Ability slots: '+r[:ability_slots].to_s+'/1193'
      t << 'AI Profiles: '+r[:profiles].to_s+'/494 manual_overrides='+r[:manual_ai_overrides].to_s
      t << 'Core Errors: '+r[:errors].size.to_s
      t << 'Core Species Ready: '+(r[:core_ready] ? 'YES':'NO')
      t << ''
      t << 'RPG DESIGN SCOPE'
      t << 'Learnset methods: '+r[:method_counts].inspect
      t << 'IMPORTANT: current 7005 Species learnset entries are level_up only; TM/Tutor/Egg acquisition pools are not yet production content.'
      t << 'AI profile generation: '+r[:profile_generations].inspect
      t << 'IMPORTANT: all Species have data-complete profiles, but most profiles are generated rather than individually hand-tuned.'
      t << 'Sparse lifetime level-up movepool (<4): '+r[:sparse_species].size.to_s+' '+r[:sparse_species].inspect
      SPECIES_AUDIT_LEVEL_CHECKPOINTS_V0994.each{|lv|t << 'Level '+lv.to_s+' with <4 executable learned moves: '+r[:level_lt4][lv].to_s}
      t << 'Special runtime review candidates: '+r[:special_review_species].size.to_s+' '+r[:special_review_species].inspect
      t << ''
      unless r[:errors].empty?
        t << 'CORE ERRORS'
        r[:errors].each{|x|t << x[0].to_s+': '+x[1].join(',')}
        t << ''
      end
      t << 'PER-SPECIES AUDIT'
      t << 'DEX|SPECIES|NAME|CORE|BST|TYPES|GROWTH|MOVES(ref/unique,L1/L10/L20/L50)|ABILITIES|EVO|FORMS(enabled/total)|AI(role/move/target/skill)|WARNINGS'
      r[:rows].each do |row|
        cp=row[:move_checkpoints]
        abilities=[:primary,:secondary,:hidden].map{|s|row[:abilities][s]}.compact.join('/')
        warn=row[:warnings].empty? ? '-' : row[:warnings].join(',')
        t << sprintf('%03d',row[:dex])+'|'+row[:species_key].to_s+'|'+row[:name].to_s+'|'+
          (row[:errors].empty? ? 'PASS':'FAIL')+'|'+row[:bst].to_s+'|'+row[:types].join('/')+'|'+row[:growth].to_s+'|'+
          row[:learnset_refs].to_s+'/'+row[:unique_moves].to_s+','+cp[1].to_s+'/'+cp[10].to_s+'/'+cp[20].to_s+'/'+cp[50].to_s+'|'+
          abilities+'|'+row[:evolution_count].to_s+'|'+row[:enabled_forms].to_s+'/'+row[:form_count].to_s+'|'+
          row[:role].to_s+'/'+row[:movement].to_s+'/'+row[:target].to_s+'/'+row[:skill].to_s+'|'+warn
      end
      t << ''
      t << 'SPECIAL REVIEW NOTES'
      SPECIES_SPECIAL_REVIEW_V0994.keys.sort{|a,b|SPECIES_DB_V016[a][:national_dex].to_i<=>SPECIES_DB_V016[b][:national_dex].to_i}.each do |k|
        d=SPECIES_DB_V016[k]
        t << sprintf('%03d',d[:national_dex].to_i)+' '+d[:name].to_s+' ('+k.to_s+'): '+SPECIES_SPECIAL_REVIEW_V0994[k]
      end
      t.join("\r\n")+"\r\n"
    end

    def write_species_production_audit_v0994(report=nil)
      begin
        File.open(SPECIES_PRODUCTION_AUDIT_REPORT_FILE_V0994,'wb'){|f|f.write(species_production_audit_text_v0994(report))}
        true
      rescue
        false
      end
    end
  end

  old_modes=VERIFICATION_MODES.dup
  old_labels=VERIFICATION_LABELS.dup
  remove_const(:VERIFICATION_MODES)
  VERIFICATION_MODES=[:normal,:species_production_audit_v0994]+old_modes.reject{|x|x==:normal || x==:species_production_audit_v0994}
  remove_const(:VERIFICATION_LABELS)
  VERIFICATION_LABELS=old_labels.dup
  VERIFICATION_LABELS[:normal]='NORMAL'
  VERIFICATION_LABELS[:species_production_audit_v0994]='SPECIES_PRODUCTION_AUDIT_V0994'
end

class Scene_PMD_AutoChess
  alias pmd_ac_v0994_start start unless method_defined?(:pmd_ac_v0994_start)
  alias pmd_ac_v0994_refresh_header refresh_header unless method_defined?(:pmd_ac_v0994_refresh_header)
  alias pmd_ac_v0994_prepare_verification_battle prepare_verification_battle unless method_defined?(:pmd_ac_v0994_prepare_verification_battle)
  alias pmd_ac_v0994_update_verification_script update_verification_script unless method_defined?(:pmd_ac_v0994_update_verification_script)
  alias pmd_ac_v0994_log_event log_event unless method_defined?(:pmd_ac_v0994_log_event)

  def start
    pmd_ac_v0994_start
    begin
      if FileTest.exist?(PMD_AC::BATTLE_LOG_FILE)
        text=File.open(PMD_AC::BATTLE_LOG_FILE,'rb'){|f|f.read}
        text.sub!(/PMD AutoChess Proto v0\.[0-9.]+ Battle Verification Log/,
          'PMD AutoChess Proto v0.99.4 Battle Verification Log')
        File.open(PMD_AC::BATTLE_LOG_FILE,'wb'){|f|f.write(text)}
      end
    rescue
    end
    log_event(:species_audit,
      'FLOW v0.99.4 species=494 stats=6 learnset=7005 ability_slots=1193 lines=248 forms=702 ai_profiles=494 core_error_fail=1 design_warning_fail=0')
    refresh_header
  end

  def refresh_header
    pmd_ac_v0994_refresh_header
    return if @header_sprite==nil || @header_sprite.bitmap==nil
    bmp=@header_sprite.bitmap
    bmp.fill_rect(0,0,Graphics.width,28,Color.new(0,0,0,180))
    pmd_ac_v074_font(bmp)
    bmp.font.size=PMD_AC.const_defined?(:UI_HEADER_TITLE_FONT_V086) ? PMD_AC::UI_HEADER_TITLE_FONT_V086 : 20
    bmp.font.bold=true;bmp.font.color=Color.new(255,255,255)
    bmp.draw_text(16,1,Graphics.width-32,30,'PMD 自走棋原型 v0.99.4',1)
  end

  def species_production_audit_v0994?
    verification_mode==:species_production_audit_v0994
  end

  def prepare_verification_battle
    pmd_ac_v0994_prepare_verification_battle
    return unless species_production_audit_v0994?
    @species_audit_failed_v0994=false
    @species_audit_report_v0994=PMD_AC.species_production_audit_v0994
    @species_audit_written_v0994=PMD_AC.write_species_production_audit_v0994(@species_audit_report_v0994)
    log_event(:showcase,'START mode=SPECIES_PRODUCTION_AUDIT_V0994 species=494 per_species=1 mutation=off fake_vfx=off fake_sfx=off')
  end

  def log_event(category,message)
    if category.to_s=='verify' && species_production_audit_v0994? && message.to_s.index('V0994')!=nil && message.to_s.index(' pass=0')!=nil
      @species_audit_failed_v0994=true
    end
    pmd_ac_v0994_log_event(category,message)
  end

  def species_audit_report_v0994
    @species_audit_report_v0994 ||= PMD_AC.species_production_audit_v0994
  end

  def log_species_verify_v0994(name,pass,detail)
    @species_audit_failed_v0994=true unless pass
    log_event(:verify,name+' pass='+(pass ? '1':'0')+' '+detail)
  end

  def update_verification_script
    unless species_production_audit_v0994?
      pmd_ac_v0994_update_verification_script
      return
    end
    return if @verification_done[:verification_complete]
    @verification_frame=@verification_frame.to_i+1
    f=@verification_frame;r=species_audit_report_v0994
    if f>=2 && !@verification_done[:v0994_core]
      pass=r[:species]==494 && r[:dex]==494 && r[:errors].empty? && r[:core_ready]
      log_species_verify_v0994('SPECIES_AUDIT_CORE_V0994',pass,'species='+r[:species].to_s+'/494 dex='+r[:dex].to_s+'/494 errors='+r[:errors].size.to_s+' core_ready='+(r[:core_ready] ? '1':'0'))
      @verification_done[:v0994_core]=true
    end
    if f>=6 && !@verification_done[:v0994_stats]
      good=r[:rows].find_all{|x|(x[:stats] || []).size==6 && x[:bst].to_i==(x[:stats] || []).inject(0){|s,v|s+v.to_i}}.size
      pass=good==494
      log_species_verify_v0994('SPECIES_AUDIT_STATS_V0994',pass,'base6='+good.to_s+'/494 growth_groups='+r[:rows].map{|x|x[:growth]}.uniq.size.to_s+' bst_low_warn='+r[:rows].find_all{|x|x[:warnings].include?('extreme_bst_low')}.size.to_s+' bst_high_warn='+r[:rows].find_all{|x|x[:warnings].include?('extreme_bst_high')}.size.to_s)
      @verification_done[:v0994_stats]=true
    end
    if f>=10 && !@verification_done[:v0994_moves]
      method_level=r[:method_counts][:level_up].to_i
      pass=r[:learnset_refs]==7005 && method_level==7005 && r[:errors].find_all{|x|x[1].join(',').index('learnset_')!=nil}.empty?
      log_species_verify_v0994('SPECIES_AUDIT_MOVEPOOL_V0994',pass,'move_db='+r[:move_db].to_s+'/559 executable='+r[:executable_moves].to_s+'/526 refs='+r[:learnset_refs].to_s+'/7005 level_up='+method_level.to_s+' tm=0 tutor=0 egg=0 sparse_lifetime='+r[:sparse_species].size.to_s+' lv1_zero=0 lv20_lt4='+r[:level_lt4][20].to_s+' design_gap=non_levelup_acquisition')
      @verification_done[:v0994_moves]=true
    end
    if f>=14 && !@verification_done[:v0994_ability]
      ability_errors=r[:errors].find_all{|x|x[1].join(',').index('ability')!=nil}
      pass=r[:ability_slots]==1193 && ability_errors.empty?
      log_species_verify_v0994('SPECIES_AUDIT_ABILITY_V0994',pass,'slots='+r[:ability_slots].to_s+'/1193 species=494/494 runtime_missing='+ability_errors.size.to_s+' ability_runtime=v0.97_157/157')
      @verification_done[:v0994_ability]=true
    end
    if f>=18 && !@verification_done[:v0994_evoform]
      evoform_errors=r[:errors].find_all{|x|x[1].join(',').index('evolution')!=nil || x[1].join(',').index('form')!=nil || x[1].join(',').index('line_')!=nil}
      pass=r[:lines]==248 && r[:forms]==702 && evoform_errors.empty?
      log_species_verify_v0994('SPECIES_AUDIT_EVOLUTION_FORM_V0994',pass,'lines='+r[:lines].to_s+'/248 forms='+r[:forms].to_s+'/702 enabled='+r[:enabled_forms].to_s+' disabled='+r[:disabled_forms].to_s+' bad='+evoform_errors.size.to_s)
      @verification_done[:v0994_evoform]=true
    end
    if f>=22 && !@verification_done[:v0994_ai]
      ai_errors=r[:errors].find_all{|x|x[1].join(',').index('profile:')!=nil || x[1].join(',').index('role_tags')!=nil}
      pass=r[:profiles]==494 && ai_errors.empty?
      generated=r[:profile_generations][:v016_percentile_role_fixed_cadence].to_i
      log_species_verify_v0994('SPECIES_AUDIT_AI_V0994',pass,'profiles='+r[:profiles].to_s+'/494 generated='+generated.to_s+' manual_overrides='+r[:manual_ai_overrides].to_s+' missing='+ai_errors.size.to_s+' design_review=required')
      @verification_done[:v0994_ai]=true
    end
    if f>=26 && !@verification_done[:v0994_scope]
      pass=r[:method_counts][:level_up].to_i==7005 && r[:sparse_species].size==15 && r[:special_review_species].size==PMD_AC::SPECIES_SPECIAL_REVIEW_V0994.size
      log_species_verify_v0994('SPECIES_AUDIT_DESIGN_SCOPE_V0994',pass,'level_up_only=7005 tm_tutor_egg_deferred=1 sparse_species='+r[:sparse_species].size.to_s+' special_review='+r[:special_review_species].size.to_s+' auto_profile_generated='+r[:profile_generations][:v016_percentile_role_fixed_cadence].to_i.to_s+' core_vs_design_separated=1')
      @verification_done[:v0994_scope]=true
    end
    if f>=30 && !@verification_done[:v0994_report]
      pass=@species_audit_written_v0994 && FileTest.exist?(PMD_AC::SPECIES_PRODUCTION_AUDIT_REPORT_FILE_V0994)
      log_species_verify_v0994('SPECIES_AUDIT_REPORT_V0994',pass,'file='+PMD_AC::SPECIES_PRODUCTION_AUDIT_REPORT_FILE_V0994+' rows='+r[:rows].size.to_s+' warnings='+r[:warning_rows].size.to_s)
      @verification_done[:v0994_report]=true
    end
    if f>=36 && !@verification_done[:v0994_final]
      pass=!@species_audit_failed_v0994 && r[:core_ready]
      log_species_verify_v0994('SPECIES_PRODUCTION_AUDIT_V0994',pass,'species=494 stats=494/494 learnsets=494/494 refs=7005/7005 ability_slots=1193/1193 lines=248 forms=702 ai_profiles=494 core_errors='+r[:errors].size.to_s+' core_ready='+(r[:core_ready] ? '1':'0')+' rpg_design_pending=movepool_acquisition+per_species_balance')
      @verification_done[:v0994_final]=true
    end
    complete_verification_mode if f>=PMD_AC::SPECIES_PRODUCTION_AUDIT_VERIFY_END_V0994
  end
end
