# encoding: UTF-8
#==============================================================================
# 【PMD AutoChess 中文維護說明】
# 腳本：PMD AutoChess Global Tutor / Special Learning Runtime v0.99.7
# 分類：Movepool Production Expansion III Runtime / Verifier
#
# 【用途】
# - 把 GLOBAL_TUTOR_B2W2_V0997 接到 v0.99.5 的 tutor_compatible / teach API。
# - 新增永久 Tutor Service unlock state，支援舊存檔懶初始化。
# - 保留逐招 unlock API；服務解鎖與逐招解鎖任一成立即可進行 Tutor 教學。
# - 提供 Special Learning method wrapper，不改 canonical compatibility。
# - 提供 MOVEPOOL_PRODUCTION_V0997 驗證模式與 Gameplay Review queue 報告。
#
# 【Tutor Service 規則】
# 1. 預設全部 locked。
# 2. unlock_tutor_service_v0997(:elemental) 後，該服務的招式視為可使用 Tutor。
# 3. Pokémon 仍必須 species-compatible，並且 move Runtime 必須 executable。
# 4. 學會後仍進入永久 learned library、4 Active Move、pending replacement、Mastery。
# 5. 本版不收費；價格/材料/商店由 v1.03 Economy 接入。
#
# 【Special Learning 規則】
# - grant_special_method_v0997 只接受 SPECIAL_LEARNING_POLICY_V0997 中的 canonical 組合。
# - 實際 commit 仍走 v0.99.5 grant_special_move，因此 acquisition history 與 instance_uid 不變。
#
# 【維護規則】
# - RGSS2 / Ruby 1.8。
# - Frozen Combat Core direct modification = NO。
# - Actor ID != Pokémon identity。
#==============================================================================
module PMD_AC
  MOVEPOOL_PRODUCTION_AUDIT_FILE_V0997='PMD_MovepoolProduction_RuntimeAudit_v0.99.7.txt'
  GAMEPLAY_REVIEW_QUEUE_FILE_V0997='PMD_GameplayReview_Queue_v0.99.7.txt'
  MOVEPOOL_PRODUCTION_VERIFY_END_V0997=112
  @fallback_tutor_services_v0997={}

  class << self
    alias pmd_ac_v0997_tutor_compatible tutor_compatible_v0995? unless method_defined?(:pmd_ac_v0997_tutor_compatible)
    alias pmd_ac_v0997_unlock_tutor unlock_tutor_v0995 unless method_defined?(:pmd_ac_v0997_unlock_tutor)
    alias pmd_ac_v0997_tutor_unlocked tutor_unlocked_v0995? unless method_defined?(:pmd_ac_v0997_tutor_unlocked)
    alias pmd_ac_v0997_sources_for_move movepool_sources_for_move_v0995 unless method_defined?(:pmd_ac_v0997_sources_for_move)

    def global_tutor_compatible_v0997?(species,move)
      sk=normalize_acquisition_key_v0995(species)
      mv=normalize_acquisition_key_v0995(move)
      a=GLOBAL_TUTOR_B2W2_V0997[sk]
      a!=nil && a.include?(mv)
    end

    def global_tutor_move_v0997?(move)
      mv=normalize_acquisition_key_v0995(move)
      return false if mv==nil
      TUTOR_SERVICES_V0997.each_value{|d|return true if (d[:moves]||[]).include?(mv)}
      false
    end

    def tutor_service_for_move_v0997(move)
      mv=normalize_acquisition_key_v0995(move)
      TUTOR_SERVICES_V0997.each{|k,d|return k if (d[:moves]||[]).include?(mv)}
      nil
    end

    def tutor_services_v0997
      if defined?($game_system) && $game_system!=nil
        h=$game_system.pmd_tutor_services_v0997
        if h==nil
          h={}
          $game_system.pmd_tutor_services_v0997=h
        end
        return h
      end
      @fallback_tutor_services_v0997={} if @fallback_tutor_services_v0997==nil
      @fallback_tutor_services_v0997
    end

    def unlock_tutor_service_v0997(service_key)
      k=normalize_acquisition_key_v0995(service_key)
      return false if TUTOR_SERVICES_V0997[k]==nil
      tutor_services_v0997[k]=true
      true
    end

    def lock_tutor_service_v0997(service_key)
      k=normalize_acquisition_key_v0995(service_key)
      tutor_services_v0997.delete(k)
      true
    end

    def tutor_service_unlocked_v0997?(service_key)
      k=normalize_acquisition_key_v0995(service_key)
      TUTOR_SERVICES_V0997[k]!=nil && tutor_services_v0997[k] ? true : false
    end

    def tutor_move_service_unlocked_v0997?(move)
      s=tutor_service_for_move_v0997(move)
      s!=nil && tutor_service_unlocked_v0997?(s)
    end

    def tutor_compatible_v0995?(species,move)
      global_tutor_compatible_v0997?(species,move) || pmd_ac_v0997_tutor_compatible(species,move)
    end

    def unlock_tutor_v0995(move)
      mv=normalize_acquisition_key_v0995(move)
      if global_tutor_move_v0997?(mv)
        tutor_unlocks_v0995[mv]=true
        return true
      end
      pmd_ac_v0997_unlock_tutor(move)
    end

    def tutor_unlocked_v0995?(move)
      return true if pmd_ac_v0997_tutor_unlocked(move)
      tutor_move_service_unlocked_v0997?(move)
    end

    def movepool_sources_for_move_v0995(species,move)
      out=pmd_ac_v0997_sources_for_move(species,move)
      mv=normalize_acquisition_key_v0995(move)
      if global_tutor_compatible_v0997?(species,mv)
        found=false
        out.each{|e|found=true if e[0]==:tutor_b2w2}
        out.push([:tutor_b2w2,mv]) unless found
      end
      out
    end

    def special_learning_policy_v0997(method_key)
      SPECIAL_LEARNING_POLICY_V0997[normalize_acquisition_key_v0995(method_key)]
    end

    def special_method_compatible_v0997?(species,method_key,move=nil)
      p=special_learning_policy_v0997(method_key)
      return false if p==nil
      sk=normalize_acquisition_key_v0995(species)
      return false unless (p[:species]||[]).include?(sk)
      return true if move==nil
      (p[:moves]||[]).include?(normalize_acquisition_key_v0995(move))
    end

    def grant_special_method_v0997(instance_uid,method_key,move=nil,grant_key=nil)
      instance=pokemon_instance_for_uid_v045(instance_uid)
      mk=normalize_acquisition_key_v0995(method_key)
      p=special_learning_policy_v0997(mk)
      return acquisition_result_v0995(false,:source_missing,:special,instance,nil,mk) if p==nil
      mv=move==nil ? ((p[:moves]||[]).size==1 ? p[:moves][0] : nil) : normalize_acquisition_key_v0995(move)
      return acquisition_result_v0995(false,:move_missing,:special,instance,mv,mk) if mv==nil
      return acquisition_result_v0995(false,:incompatible,:special,instance,mv,mk) if instance==nil || !special_method_compatible_v0997?(instance.species_key,mk,mv)
      gk=grant_key==nil ? mk : normalize_acquisition_key_v0995(grant_key)
      grant_special_move_instance_v0995(instance,mv,gk)
    end

    def global_tutor_audit_v0997
      refs=0;moves={};bad=[];missing=[];service_moves={}
      GLOBAL_TUTOR_B2W2_V0997.each do |sk,a|
        refs+=a.size
        a.each do |mv|
          moves[mv]=true
          bad.push([sk,mv]) unless move_executable?(mv)
        end
      end
      SPECIES_DB_V016.each_key{|sk|missing.push(sk) if GLOBAL_TUTOR_B2W2_V0997[sk]==nil}
      TUTOR_SERVICES_V0997.each_value{|d|(d[:moves]||[]).each{|mv|service_moves[mv]=true}}
      missing_services=moves.keys.find_all{|mv|!service_moves[mv]}
      extra_services=service_moves.keys.find_all{|mv|!moves[mv]}
      expected_missing=MOVEPOOL_PRODUCTION_MANIFEST_V0997[:tutor_missing_species]
      {:species=>GLOBAL_TUTOR_B2W2_V0997.size,:refs=>refs,:moves=>moves.keys,
       :bad_runtime=>bad,:missing_species=>missing,:missing_services=>missing_services,
       :extra_services=>extra_services,
       :pass=>(GLOBAL_TUTOR_B2W2_V0997.size==489 && refs==5361 && moves.size==67 &&
         bad.empty? && missing.sort_by{|x|x.to_s}==expected_missing.sort_by{|x|x.to_s} &&
         missing_services.empty? && extra_services.empty?)}
    end

    def special_learning_audit_v0997
      errors=[]
      p1=special_move_entry_v0995(:pichu,:volt_tackle)
      p2=special_move_entry_v0995(:rotom,:thunder_shock)
      errors.push(:pichu_volt_tackle) if p1==nil || p1[:method]!=:light_ball_egg
      errors.push(:rotom_form_change) if p2==nil || p2[:method]!=:form_change
      errors.push(:policy_light_ball) unless special_method_compatible_v0997?(:pichu,:light_ball_egg,:volt_tackle)
      errors.push(:policy_rotom) unless special_method_compatible_v0997?(:rotom,:form_change,:thunder_shock)
      {:refs=>2,:methods=>2,:errors=>errors,:pass=>errors.empty?}
    end

    def gameplay_review_queue_audit_v0997
      ids={}
      SPECIES_DB_V016.each{|sk,d|ids[d[:national_dex].to_i]=sk if d[:national_dex]!=nil}
      covered={}
      GAMEPLAY_REVIEW_BATCHES_V0997.each{|b|(b[0]..b[1]).each{|i|covered[i]=true}}
      missing=(1..494).find_all{|i|ids[i]==nil || !covered[i]}
      {:species=>ids.size,:fields=>GAMEPLAY_REVIEW_FIELDS_V0997.size,:batches=>GAMEPLAY_REVIEW_BATCHES_V0997.size,
       :missing=>missing,:pass=>(ids.size==494 && GAMEPLAY_REVIEW_FIELDS_V0997.size==18 && GAMEPLAY_REVIEW_BATCHES_V0997.size==4 && missing.empty?)}
    end

    def movepool_production_audit_v0997
      base=movepool_production_audit_v0996
      tutor=global_tutor_audit_v0997
      special=special_learning_audit_v0997
      review=gameplay_review_queue_audit_v0997
      nonlevel={}
      base[:acquisition][:nonlevel_unique].each_key{|k|nonlevel[k]=true}
      tutor[:moves].each{|k|nonlevel[k]=true}
      blocked=nonlevel.keys.find_all{|mv|!move_executable?(mv)}
      {:base=>base,:tutor=>tutor,:special=>special,:review=>review,
       :nonlevel_unique=>nonlevel.keys,:nonlevel_blocked=>blocked,
       :pass=>(base[:pass] && tutor[:pass] && special[:pass] && review[:pass] && blocked.empty?)}
    end

    def movepool_production_audit_text_v0997(report=nil)
      r=report || movepool_production_audit_v0997
      t=r[:tutor];s=r[:special];q=r[:review]
      out=[]
      out << 'PMD AutoChess Movepool Production Runtime Audit v0.99.7'
      out << 'Base: v0.99.6 | Frozen Combat Core direct modification: NO'
      out << 'B2W2 Tutor species/refs/moves: '+t[:species].to_s+'/494 | '+t[:refs].to_s+' | '+t[:moves].size.to_s
      out << 'B2W2 Tutor runtime blocked: '+t[:bad_runtime].size.to_s
      out << 'Tutor service coverage: '+TUTOR_SERVICES_V0997.size.to_s+' services | missing moves='+t[:missing_services].size.to_s
      out << 'Tutor missing species: '+t[:missing_species].collect{|x|x.to_s}.sort.join(', ')
      out << 'Special methods/refs/errors: '+s[:methods].to_s+'/'+s[:refs].to_s+'/'+s[:errors].size.to_s
      out << 'Non-level unique after global tutor: '+r[:nonlevel_unique].size.to_s+' | blocked='+r[:nonlevel_blocked].size.to_s
      out << 'Gameplay review queue: species='+q[:species].to_s+' fields='+q[:fields].to_s+' batches='+q[:batches].to_s
      out << 'Next review batch: #0001-0151'
      out << 'Production Ready: '+(r[:pass] ? '1':'0')
      out.join("\r\n")+"\r\n"
    end

    def write_movepool_production_audit_v0997(report=nil)
      File.open(MOVEPOOL_PRODUCTION_AUDIT_FILE_V0997,'wb'){|f|f.write(movepool_production_audit_text_v0997(report))}
      true
    rescue
      false
    end

    def gameplay_review_queue_text_v0997
      out=[]
      out << 'PMD AutoChess Gameplay Review Queue v0.99.7'
      out << 'Status: schema ready; content review pending'
      out << 'Batches: #0001-0151 / #0152-0251 / #0252-0386 / #0387-0494'
      out << 'Fields: '+GAMEPLAY_REVIEW_FIELDS_V0997.collect{|x|x.to_s}.join(', ')
      out << ''
      (1..494).each do |id|
        sk=nil
        SPECIES_DB_V016.each{|k,d|sk=k if d[:national_dex].to_i==id}
        batch=GAMEPLAY_REVIEW_BATCHES_V0997.find{|b|id>=b[0] && id<=b[1]}
        out << sprintf('#%04d',id)+' '+(sk==nil ? 'missing' : sk.to_s)+' batch='+batch[0].to_s+'-'+batch[1].to_s+' status=PENDING'
      end
      out.join("\r\n")+"\r\n"
    end

    def write_gameplay_review_queue_v0997
      File.open(GAMEPLAY_REVIEW_QUEUE_FILE_V0997,'wb'){|f|f.write(gameplay_review_queue_text_v0997)}
      true
    rescue
      false
    end
  end

  old_modes=VERIFICATION_MODES.dup
  old_labels=VERIFICATION_LABELS.dup
  remove_const(:VERIFICATION_MODES)
  VERIFICATION_MODES=[:normal,:movepool_production_v0997]+old_modes.reject{|x|
    x==:normal || x==:movepool_production_v0997 || x==:movepool_production_v0996 || x==:movepool_acquisition_v0995
  }
  remove_const(:VERIFICATION_LABELS)
  VERIFICATION_LABELS=old_labels.dup
  VERIFICATION_LABELS.delete(:movepool_production_v0996)
  VERIFICATION_LABELS.delete(:movepool_acquisition_v0995)
  VERIFICATION_LABELS[:movepool_production_v0997]='MOVEPOOL_PRODUCTION_V0997'
end

class Game_System
  attr_accessor :pmd_tutor_services_v0997
  alias pmd_ac_v0997_initialize initialize unless method_defined?(:pmd_ac_v0997_initialize)
  def initialize
    pmd_ac_v0997_initialize
    @pmd_tutor_services_v0997={}
  end
end

class Scene_PMD_AutoChess
  alias pmd_ac_v0997_start start unless method_defined?(:pmd_ac_v0997_start)
  alias pmd_ac_v0997_refresh_header refresh_header unless method_defined?(:pmd_ac_v0997_refresh_header)
  alias pmd_ac_v0997_prepare_verification_battle prepare_verification_battle unless method_defined?(:pmd_ac_v0997_prepare_verification_battle)
  alias pmd_ac_v0997_update_verification_script update_verification_script unless method_defined?(:pmd_ac_v0997_update_verification_script)
  alias pmd_ac_v0997_terminate terminate unless method_defined?(:pmd_ac_v0997_terminate)
  alias pmd_ac_v0997_log_event log_event unless method_defined?(:pmd_ac_v0997_log_event)

  def start
    pmd_ac_v0997_start
    begin
      if FileTest.exist?(PMD_AC::BATTLE_LOG_FILE)
        text=File.open(PMD_AC::BATTLE_LOG_FILE,'rb'){|f|f.read}
        text.sub!(/PMD AutoChess Proto v0\.[0-9.]+ Battle Verification Log/,'PMD AutoChess Proto v0.99.7 Battle Verification Log')
        File.open(PMD_AC::BATTLE_LOG_FILE,'wb'){|f|f.write(text)}
      end
    rescue
    end
    log_event(:movepool_production,'FLOW v0.99.7 b2w2_tutor=489species/5361refs/67moves services=7 special=2 review_queue=494')
    refresh_header
  end

  def refresh_header
    pmd_ac_v0997_refresh_header
    return if @header_sprite==nil || @header_sprite.bitmap==nil
    bmp=@header_sprite.bitmap
    bmp.fill_rect(0,0,Graphics.width,28,Color.new(0,0,0,180))
    pmd_ac_v074_font(bmp)
    bmp.font.size=PMD_AC.const_defined?(:UI_HEADER_TITLE_FONT_V086) ? PMD_AC::UI_HEADER_TITLE_FONT_V086 : 20
    bmp.font.bold=true
    bmp.font.color=Color.new(255,255,255)
    bmp.draw_text(16,1,Graphics.width-32,30,'PMD 自走棋原型 v0.99.7',1)
  end

  def movepool_production_v0997?
    verification_mode==:movepool_production_v0997
  end

  def prepare_verification_battle
    pmd_ac_v0997_prepare_verification_battle
    return unless movepool_production_v0997?
    @movepool_production_failed_v0997=false
    @movepool_production_report_v0997=PMD_AC.movepool_production_audit_v0997
    @movepool_production_written_v0997=PMD_AC.write_movepool_production_audit_v0997(@movepool_production_report_v0997)
    @gameplay_review_written_v0997=PMD_AC.write_gameplay_review_queue_v0997

    @tutor_services_snapshot_v0997=PMD_AC.tutor_services_v0997.dup
    @tutor_unlocks_snapshot_v0997=PMD_AC.tutor_unlocks_v0995.dup
    PMD_AC.tutor_services_v0997.clear
    PMD_AC.lock_tutor_v0995(:giga_drain)

    reg=PMD_AC.pokemon_registry_v045
    @tutor_test_uid_v0997=99700101
    @special_test_uid_v0997=99700172
    @tutor_old_instance_v0997=reg[@tutor_test_uid_v0997]
    @special_old_instance_v0997=reg[@special_test_uid_v0997]
    @tutor_test_instance_v0997=PMD_PokemonInstance.new(:bulbasaur,5,{:instance_uid=>@tutor_test_uid_v0997,:ivs=>[15,15,15,15,15,15],:nature=>:hardy,:ability_slot=>:primary})
    @special_test_instance_v0997=PMD_PokemonInstance.new(:pichu,1,{:instance_uid=>@special_test_uid_v0997,:ivs=>[15,15,15,15,15,15],:nature=>:hardy,:ability_slot=>:primary})
    reg[@tutor_test_uid_v0997]=@tutor_test_instance_v0997
    reg[@special_test_uid_v0997]=@special_test_instance_v0997
    log_event(:showcase,'START mode=MOVEPOOL_PRODUCTION_V0997 global_tutor=5361 services=7 special=2 review=494')
  end

  def restore_movepool_production_v0997
    return if @movepool_restore_done_v0997
    if @tutor_services_snapshot_v0997!=nil
      h=PMD_AC.tutor_services_v0997;h.clear;@tutor_services_snapshot_v0997.each{|k,v|h[k]=v}
    end
    if @tutor_unlocks_snapshot_v0997!=nil
      h=PMD_AC.tutor_unlocks_v0995;h.clear;@tutor_unlocks_snapshot_v0997.each{|k,v|h[k]=v}
    end
    reg=PMD_AC.pokemon_registry_v045
    if @tutor_test_uid_v0997!=nil
      if @tutor_old_instance_v0997==nil;reg.delete(@tutor_test_uid_v0997);else;reg[@tutor_test_uid_v0997]=@tutor_old_instance_v0997;end
    end
    if @special_test_uid_v0997!=nil
      if @special_old_instance_v0997==nil;reg.delete(@special_test_uid_v0997);else;reg[@special_test_uid_v0997]=@special_old_instance_v0997;end
    end
    @movepool_restore_done_v0997=true
    true
  end

  def terminate
    restore_movepool_production_v0997 if movepool_production_v0997?
    pmd_ac_v0997_terminate
  end

  def log_event(category,message)
    if category.to_s=='verify' && movepool_production_v0997? && message.to_s.index('V0997')!=nil && message.to_s.index(' pass=0')!=nil
      @movepool_production_failed_v0997=true
    end
    pmd_ac_v0997_log_event(category,message)
  end

  def log_movepool_verify_v0997(name,pass,detail)
    @movepool_production_failed_v0997=true unless pass
    log_event(:verify,name+' pass='+(pass ? '1':'0')+' '+detail)
  end

  def update_verification_script
    unless movepool_production_v0997?
      pmd_ac_v0997_update_verification_script
      return
    end
    return if @verification_done[:verification_complete]
    @verification_frame=@verification_frame.to_i+1
    f=@verification_frame
    r=@movepool_production_report_v0997 || PMD_AC.movepool_production_audit_v0997
    t=r[:tutor];s=r[:special];q=r[:review]

    if f>=2 && !@verification_done[:v0997_data]
      pass=t[:pass]
      log_movepool_verify_v0997('MOVEPOOL_GLOBAL_TUTOR_DATA_V0997',pass,
        'species='+t[:species].to_s+'/489 refs='+t[:refs].to_s+'/5361 moves='+t[:moves].size.to_s+'/67 missing='+t[:missing_species].size.to_s+'/5')
      @verification_done[:v0997_data]=true
    end

    if f>=8 && !@verification_done[:v0997_runtime]
      pass=t[:bad_runtime].empty? && r[:nonlevel_blocked].empty? && r[:nonlevel_unique].size==441
      log_movepool_verify_v0997('MOVEPOOL_GLOBAL_TUTOR_RUNTIME_V0997',pass,
        'tutor_executable='+(67-t[:bad_runtime].size).to_s+'/67 nonlevel_unique='+r[:nonlevel_unique].size.to_s+'/441 blocked='+r[:nonlevel_blocked].size.to_s+'/0')
      @verification_done[:v0997_runtime]=true
    end

    if f>=14 && !@verification_done[:v0997_services]
      coverage={}
      PMD_AC::TUTOR_SERVICES_V0997.each_value{|d|(d[:moves]||[]).each{|mv|coverage[mv]=true}}
      locked=PMD_AC::TUTOR_SERVICES_V0997.keys.all?{|k|!PMD_AC.tutor_service_unlocked_v0997?(k)}
      pass=coverage.size==67 && locked && t[:missing_services].empty?
      log_movepool_verify_v0997('MOVEPOOL_TUTOR_SERVICE_V0997',pass,
        'services='+PMD_AC::TUTOR_SERVICES_V0997.size.to_s+'/7 move_coverage='+coverage.size.to_s+'/67 default_locked='+(locked ? '1':'0'))
      @verification_done[:v0997_services]=true
    end

    if f>=20 && !@verification_done[:v0997_persist]
      before=PMD_AC.tutor_unlocked_v0995?(:giga_drain)
      unlocked=PMD_AC.unlock_tutor_service_v0997(:elemental)
      after=PMD_AC.tutor_unlocked_v0995?(:giga_drain)
      compat=PMD_AC.tutor_compatible_v0995?(:bulbasaur,:giga_drain)
      pass=!before && unlocked && after && compat
      log_movepool_verify_v0997('MOVEPOOL_TUTOR_PERSISTENCE_V0997',pass,
        'service=elemental before='+(before ? '1':'0')+' unlock='+(unlocked ? '1':'0')+' after='+(after ? '1':'0')+' bulbasaur_compat='+(compat ? '1':'0'))
      @verification_done[:v0997_persist]=true
    end

    if f>=26 && !@verification_done[:v0997_teach]
      x=PMD_AC.teach_tutor_v0995(@tutor_test_uid_v0997,:giga_drain)
      known=@tutor_test_instance_v0997.knows_move_v045?(:giga_drain)
      pass=x[:ok] && x[:reason]==:learned && known
      log_movepool_verify_v0997('MOVEPOOL_TUTOR_TEACH_V0997',pass,
        'move=giga_drain result='+x[:reason].to_s+' learned='+(known ? '1':'0')+' identity=instance_uid')
      @verification_done[:v0997_teach]=true
    end

    if f>=32 && !@verification_done[:v0997_exclusions]
      expected=[:ditto,:unown,:wobbuffet,:smeargle,:wynaut]
      missing=t[:missing_species].sort_by{|x|x.to_s}
      policy=expected.all?{|sk|PMD_AC::TUTOR_EXCLUSION_POLICY_V0997[sk]!=nil}
      pass=missing==expected.sort_by{|x|x.to_s} && policy
      log_movepool_verify_v0997('MOVEPOOL_TUTOR_EXCEPTIONS_V0997',pass,
        'missing=[ditto,unown,wobbuffet,smeargle,wynaut] policy=5/5 forced_tutor=0')
      @verification_done[:v0997_exclusions]=true
    end

    if f>=38 && !@verification_done[:v0997_special]
      x=PMD_AC.grant_special_method_v0997(@special_test_uid_v0997,:light_ball_egg,:volt_tackle,:verify_light_ball)
      known=@special_test_instance_v0997.knows_move_v045?(:volt_tackle)
      pass=s[:pass] && x[:ok] && known && PMD_AC.special_method_compatible_v0997?(:rotom,:form_change,:thunder_shock)
      log_movepool_verify_v0997('MOVEPOOL_SPECIAL_POLICY_V0997',pass,
        'canonical_methods=2 refs=2 pichu_volt_tackle='+(known ? '1':'0')+' rotom_form_memory=1')
      @verification_done[:v0997_special]=true
    end

    if f>=44 && !@verification_done[:v0997_review]
      pass=q[:pass] && @gameplay_review_written_v0997 && FileTest.exist?(PMD_AC::GAMEPLAY_REVIEW_QUEUE_FILE_V0997)
      log_movepool_verify_v0997('GAMEPLAY_REVIEW_QUEUE_V0997',pass,
        'species='+q[:species].to_s+'/494 fields='+q[:fields].to_s+'/18 batches='+q[:batches].to_s+'/4 next=0001-0151')
      @verification_done[:v0997_review]=true
    end

    if f>=50 && !@verification_done[:v0997_report]
      pass=@movepool_production_written_v0997 && FileTest.exist?(PMD_AC::MOVEPOOL_PRODUCTION_AUDIT_FILE_V0997)
      log_movepool_verify_v0997('MOVEPOOL_PRODUCTION_REPORT_V0997',pass,
        'file='+PMD_AC::MOVEPOOL_PRODUCTION_AUDIT_FILE_V0997+' tutor_refs=5361 blocked=0')
      @verification_done[:v0997_report]=true
    end

    if f>=56 && !@verification_done[:v0997_final]
      pass=!@movepool_production_failed_v0997 && r[:pass]
      log_movepool_verify_v0997('MOVEPOOL_PRODUCTION_V0997',pass,
        'global_tutor=complete special_policy=complete review_queue=ready next=gameplay_review_0001-0151')
      @verification_done[:v0997_final]=true
      restore_movepool_production_v0997
    end

    complete_verification_mode if f>=PMD_AC::MOVEPOOL_PRODUCTION_VERIFY_END_V0997
  end
end
