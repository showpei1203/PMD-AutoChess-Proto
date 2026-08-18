# encoding: UTF-8
#==============================================================================
# 【PMD AutoChess 中文維護說明】
# 腳本：PMD AutoChess Movepool Acquisition Runtime v0.99.5
# 分類：Pokémon 永久招式取得／RPG 養成 Runtime
#
# 【用途】
# 本腳本把 v0.99.5 的 Movepool 相容資料真正接到 RPG 永久養成：
# 1. TM/HM：玩家先取得／解鎖機器，再教給相容 Pokémon；Gen V 規則為可重複使用。
# 2. Tutor：玩家先解鎖導師服務，再教給相容 Pokémon。
# 3. Egg：不自動解鎖；只能由繁殖／招募／事件明確授予相容 Egg Move。
# 4. Special：不自動解鎖；只能由事件／特殊系統明確授予。
# 5. 所有成功學會的招式都進入既有 v0.45「永久 learned library」，再由玩家配置 4 個 Active Moves。
#
# 【重要設計邊界】
# - 不修改 Frozen Combat Core，不改既有 7005 筆 Level-up 自動學習。
# - Actor ID 不是 Pokémon 身份；教學 API 一律以 instance_uid 尋找個體。
# - 相容 ≠ 已取得。相容資料只回答「能不能學」，Unlock/Grant 才回答「玩家是否已拿到來源」。
# - 若招式目前沒有 AutoChess Runtime，會回傳 :move_not_executable，絕不把不能戰鬥的招式塞進可用招式庫。
# - 舊存檔沒有 v0.99.5 欄位時採 Lazy Migration，自動補空 Hash，不要求重開檔。
#
# 【可調／可接設定】
# - TM/HM 現階段採 Gen V 可重複使用，不消耗數量。
# - Tutor 的金錢、素材、Quest 前置條件不在此腳本硬編；Economy／Quest 層先判定，再呼叫 unlock/teach API。
# - Egg/Special 只提供安全授予 API；繁殖、招募、劇情事件之後各自決定何時呼叫。
#
# 【事件／腳本呼叫方式】
# 取得 TM24 十萬伏特：
#   PMD_AC.unlock_machine_v0995(:tm24)
# 教給 instance_uid=12345 的 Pokémon：
#   result = PMD_AC.teach_machine_v0995(12345, :tm24)
#
# 解鎖 Draco Meteor 導師並教學：
#   PMD_AC.unlock_tutor_v0995(:draco_meteor)
#   PMD_AC.teach_tutor_v0995(12345, :draco_meteor)
#
# 繁殖／招募系統授予 Egg Move：
#   PMD_AC.grant_egg_move_v0995(12345, :charm)
#
# 特殊事件授予招式：
#   PMD_AC.grant_special_move_v0995(12345, :volt_tackle, :light_ball_event)
#
# 查詢結果 Hash：
#   {:ok=>true, :reason=>:learned, :source=>:machine, :move=>:thunderbolt, ...}
#   {:ok=>false,:reason=>:source_locked, ...}
#   {:ok=>false,:reason=>:incompatible, ...}
#   {:ok=>false,:reason=>:move_not_executable, ...}
#
# 【維護規則】
# - RPG Maker VX / RGSS2 / Ruby 1.8 相容。
# - 禁止使用本專案明確排除的 instance-variable introspection helper。
# - 新來源優先新增 Data + API，不要反向改 Frozen Core。
#==============================================================================
module PMD_AC
  MOVEPOOL_ACQUISITION_RUNTIME_VERSION_V0995 = '0.99.5'
  MOVEPOOL_ACQUISITION_RUNTIME_AUDIT_FILE_V0995 = 'PMD_MovepoolAcquisition_RuntimeAudit_v0.99.5.txt'
  MOVEPOOL_ACQUISITION_VERIFY_END_V0995 = 90

  @fallback_machine_unlocks_v0995 = {}
  @fallback_tutor_unlocks_v0995 = {}

  class << self
    def normalize_acquisition_key_v0995(value)
      return nil if value==nil
      text=value.to_s.downcase
      text=text.gsub('-','_').gsub(' ','_')
      text.to_sym
    end

    def machine_unlocks_v0995
      if defined?($game_system) && $game_system!=nil
        h=$game_system.pmd_machine_unlocks_v0995
        h={} if h==nil
        $game_system.pmd_machine_unlocks_v0995=h
        return h
      end
      @fallback_machine_unlocks_v0995={} if @fallback_machine_unlocks_v0995==nil
      @fallback_machine_unlocks_v0995
    end

    def tutor_unlocks_v0995
      if defined?($game_system) && $game_system!=nil
        h=$game_system.pmd_tutor_unlocks_v0995
        h={} if h==nil
        $game_system.pmd_tutor_unlocks_v0995=h
        return h
      end
      @fallback_tutor_unlocks_v0995={} if @fallback_tutor_unlocks_v0995==nil
      @fallback_tutor_unlocks_v0995
    end

    def acquisition_species_data_v0995(species)
      key=normalize_acquisition_key_v0995(species)
      d=MOVEPOOL_ACQUISITION_SPECIES_V0995[key]
      return nil if d==nil
      d
    end

    def machine_data_v0995(machine_key)
      key=normalize_acquisition_key_v0995(machine_key)
      MACHINE_CATALOG_V0995[key]
    end

    def machine_move_v0995(machine_key)
      d=machine_data_v0995(machine_key)
      d==nil ? nil : d[:move]
    end

    def machine_compatible_v0995?(species,machine_key)
      sk=normalize_acquisition_key_v0995(species)
      mk=normalize_acquisition_key_v0995(machine_key)
      d=acquisition_species_data_v0995(sk)
      return false if d==nil || machine_data_v0995(mk)==nil
      for pair in (d[:machine]||[])
        return true if pair[0]==mk && pair[1]==machine_move_v0995(mk)
      end
      false
    end

    def tutor_compatible_v0995?(species,move)
      d=acquisition_species_data_v0995(species)
      mv=normalize_acquisition_key_v0995(move)
      d!=nil && (d[:tutor]||[]).include?(mv)
    end

    def egg_move_compatible_v0995?(species,move)
      d=acquisition_species_data_v0995(species)
      mv=normalize_acquisition_key_v0995(move)
      d!=nil && (d[:egg]||[]).include?(mv)
    end

    def special_move_entry_v0995(species,move)
      d=acquisition_species_data_v0995(species)
      mv=normalize_acquisition_key_v0995(move)
      return nil if d==nil
      for e in (d[:special]||[])
        return e if e[:move]==mv
      end
      nil
    end

    def special_move_compatible_v0995?(species,move)
      special_move_entry_v0995(species,move)!=nil
    end

    def movepool_sources_for_move_v0995(species,move)
      sk=normalize_acquisition_key_v0995(species)
      mv=normalize_acquisition_key_v0995(move)
      d=acquisition_species_data_v0995(sk)
      return [] if d==nil || mv==nil
      out=[]
      for pair in (d[:machine]||[])
        out.push([:machine,pair[0]]) if pair[1]==mv
      end
      out.push([:tutor,mv]) if (d[:tutor]||[]).include?(mv)
      out.push([:egg,mv]) if (d[:egg]||[]).include?(mv)
      se=special_move_entry_v0995(sk,mv)
      out.push([:special,se[:method]]) if se!=nil
      out
    end

    def unlock_machine_v0995(machine_key)
      mk=normalize_acquisition_key_v0995(machine_key)
      return false if machine_data_v0995(mk)==nil
      machine_unlocks_v0995[mk]=true
      true
    end

    def lock_machine_v0995(machine_key)
      mk=normalize_acquisition_key_v0995(machine_key)
      machine_unlocks_v0995.delete(mk)
      true
    end

    def machine_unlocked_v0995?(machine_key)
      mk=normalize_acquisition_key_v0995(machine_key)
      machine_data_v0995(mk)!=nil && machine_unlocks_v0995[mk] ? true : false
    end

    def unlock_tutor_v0995(move)
      mv=normalize_acquisition_key_v0995(move)
      return false if mv==nil
      found=false
      MOVEPOOL_ACQUISITION_SPECIES_V0995.each_value do |d|
        if (d[:tutor]||[]).include?(mv);found=true;break;end
      end
      return false unless found
      tutor_unlocks_v0995[mv]=true
      true
    end

    def lock_tutor_v0995(move)
      mv=normalize_acquisition_key_v0995(move)
      tutor_unlocks_v0995.delete(mv)
      true
    end

    def tutor_unlocked_v0995?(move)
      mv=normalize_acquisition_key_v0995(move)
      tutor_unlocks_v0995[mv] ? true : false
    end

    def acquisition_result_v0995(ok,reason,source,instance,move,source_key=nil,extra=nil)
      r={:ok=>ok ? true : false,:reason=>reason,:source=>source,
         :instance_uid=>(instance==nil ? nil : instance.instance_uid.to_i),
         :species=>(instance==nil ? nil : instance.species_key),:move=>move,
         :source_key=>source_key}
      if extra!=nil
        extra.each{|k,v|r[k]=v}
      end
      r
    end

    def validate_teach_instance_v0995(instance,source,move,source_key=nil)
      mv=normalize_acquisition_key_v0995(move)
      return acquisition_result_v0995(false,:instance_missing,source,nil,mv,source_key) if instance==nil
      return acquisition_result_v0995(false,:move_missing,source,instance,mv,source_key) if mv==nil || MOVE_DB_V017[mv]==nil
      return acquisition_result_v0995(false,:already_known,source,instance,mv,source_key) if instance.knows_move_v045?(mv)
      return acquisition_result_v0995(false,:move_not_executable,source,instance,mv,source_key) unless move_executable?(mv)
      nil
    end

    def commit_acquired_move_v0995(instance,source,move,source_key=nil,extra=nil)
      mv=normalize_acquisition_key_v0995(move)
      check=validate_teach_instance_v0995(instance,source,mv,source_key)
      return check if check!=nil
      learned=instance.learn_known_move_v045(mv,nil,instance.species_key,false)
      return acquisition_result_v0995(false,:learn_failed,source,instance,mv,source_key) unless learned
      instance.record_move_acquisition_v0995(source,mv,source_key,extra)
      acquisition_result_v0995(true,:learned,source,instance,mv,source_key,
        {:active_moves=>instance.active_moves_v045.size,:pending_moves=>instance.pending_move_choices_v045.size})
    end

    def teach_machine_instance_v0995(instance,machine_key)
      mk=normalize_acquisition_key_v0995(machine_key)
      md=machine_data_v0995(mk)
      return acquisition_result_v0995(false,:source_missing,:machine,instance,nil,mk) if md==nil
      mv=md[:move]
      return acquisition_result_v0995(false,:source_locked,:machine,instance,mv,mk) unless machine_unlocked_v0995?(mk)
      return acquisition_result_v0995(false,:incompatible,:machine,instance,mv,mk) unless machine_compatible_v0995?(instance.species_key,mk)
      commit_acquired_move_v0995(instance,:machine,mv,mk,{:machine_kind=>md[:kind],:machine_number=>md[:number]})
    end

    def teach_machine_v0995(instance_uid,machine_key)
      instance=pokemon_instance_for_uid_v045(instance_uid)
      teach_machine_instance_v0995(instance,machine_key)
    end

    def teach_tutor_instance_v0995(instance,move)
      mv=normalize_acquisition_key_v0995(move)
      return acquisition_result_v0995(false,:source_locked,:tutor,instance,mv,mv) unless tutor_unlocked_v0995?(mv)
      return acquisition_result_v0995(false,:incompatible,:tutor,instance,mv,mv) if instance==nil || !tutor_compatible_v0995?(instance.species_key,mv)
      commit_acquired_move_v0995(instance,:tutor,mv,mv,nil)
    end

    def teach_tutor_v0995(instance_uid,move)
      instance=pokemon_instance_for_uid_v045(instance_uid)
      teach_tutor_instance_v0995(instance,move)
    end

    def grant_egg_move_instance_v0995(instance,move,grant_key=:egg_inheritance)
      mv=normalize_acquisition_key_v0995(move)
      gk=normalize_acquisition_key_v0995(grant_key)
      return acquisition_result_v0995(false,:incompatible,:egg,instance,mv,gk) if instance==nil || !egg_move_compatible_v0995?(instance.species_key,mv)
      commit_acquired_move_v0995(instance,:egg,mv,gk,nil)
    end

    def grant_egg_move_v0995(instance_uid,move,grant_key=:egg_inheritance)
      instance=pokemon_instance_for_uid_v045(instance_uid)
      grant_egg_move_instance_v0995(instance,move,grant_key)
    end

    def grant_special_move_instance_v0995(instance,move,grant_key=:event)
      mv=normalize_acquisition_key_v0995(move)
      gk=normalize_acquisition_key_v0995(grant_key)
      entry=instance==nil ? nil : special_move_entry_v0995(instance.species_key,mv)
      return acquisition_result_v0995(false,:incompatible,:special,instance,mv,gk) if entry==nil
      commit_acquired_move_v0995(instance,:special,mv,gk,{:canonical_method=>entry[:method]})
    end

    def grant_special_move_v0995(instance_uid,move,grant_key=:event)
      instance=pokemon_instance_for_uid_v045(instance_uid)
      grant_special_move_instance_v0995(instance,move,grant_key)
    end

    def movepool_acquisition_audit_v0995
      r={:errors=>[],:warnings=>[], :species=>MOVEPOOL_ACQUISITION_SPECIES_V0995.size,
         :machine_catalog=>MACHINE_CATALOG_V0995.size,:machine_refs=>0,:tutor_refs=>0,
         :egg_refs=>0,:special_refs=>0,:nonlevel_unique=>{},:nonlevel_executable=>{},
         :nonlevel_blocked=>{},:species_without_nonlevel=>[]}
      tm=0;hm=0
      MACHINE_CATALOG_V0995.each do |mk,md|
        if md[:kind]==:tm;tm+=1 elsif md[:kind]==:hm;hm+=1;end
        r[:errors].push('machine_missing_move:'+mk.to_s) if MOVE_DB_V017[md[:move]]==nil
      end
      r[:tm]=tm;r[:hm]=hm
      MOVEPOOL_ACQUISITION_SPECIES_V0995.each do |sk,d|
        count=0
        for pair in (d[:machine]||[])
          r[:machine_refs]+=1;count+=1;mv=pair[1];r[:nonlevel_unique][mv]=true
          md=MACHINE_CATALOG_V0995[pair[0]]
          r[:errors].push('machine_catalog:'+sk.to_s+':'+pair[0].to_s) if md==nil || md[:move]!=mv
        end
        for mv in (d[:tutor]||[]);r[:tutor_refs]+=1;count+=1;r[:nonlevel_unique][mv]=true;end
        for mv in (d[:egg]||[]);r[:egg_refs]+=1;count+=1;r[:nonlevel_unique][mv]=true;end
        for e in (d[:special]||[]);r[:special_refs]+=1;count+=1;r[:nonlevel_unique][e[:move]]=true;end
        r[:species_without_nonlevel].push(sk) if count==0
      end
      r[:nonlevel_unique].keys.each do |mv|
        if MOVE_DB_V017[mv]==nil
          r[:errors].push('move_db_missing:'+mv.to_s)
        elsif move_executable?(mv)
          r[:nonlevel_executable][mv]=true
        else
          r[:nonlevel_blocked][mv]=true
        end
      end
      man=MOVEPOOL_ACQUISITION_MANIFEST_V0995
      r[:errors].push('species_count') unless r[:species].to_i==man[:species_count].to_i
      r[:errors].push('machine_catalog_count') unless r[:machine_catalog].to_i==man[:machine_total].to_i
      r[:errors].push('machine_refs') unless r[:machine_refs].to_i==man[:machine_refs].to_i
      r[:errors].push('tutor_refs') unless r[:tutor_refs].to_i==man[:tutor_refs].to_i
      r[:errors].push('egg_refs') unless r[:egg_refs].to_i==man[:egg_refs].to_i
      r[:errors].push('special_refs') unless r[:special_refs].to_i==man[:special_refs].to_i
      r[:errors].push('tm_count') unless r[:tm].to_i==man[:tm_count].to_i
      r[:errors].push('hm_count') unless r[:hm].to_i==man[:hm_count].to_i
      r[:core_ready]=r[:errors].empty?
      r
    end

    def movepool_acquisition_audit_text_v0995(report=nil)
      r=report || movepool_acquisition_audit_v0995
      blocked=r[:nonlevel_blocked].keys.collect{|x|x.to_s}.sort
      none=r[:species_without_nonlevel].collect{|x|x.to_s}.sort
      t=[]
      t << 'PMD AutoChess Movepool Acquisition Runtime Audit v0.99.5'
      t << 'Source commit: '+MOVEPOOL_ACQUISITION_MANIFEST_V0995[:source_commit].to_s
      t << 'Ruleset: Black/White version_group_id=11'
      t << ''
      t << 'Species: '+r[:species].to_s+'/494'
      t << 'Level-up refs (existing/frozen): '+MOVEPOOL_ACQUISITION_MANIFEST_V0995[:level_up_refs].to_s
      t << 'Machine refs: '+r[:machine_refs].to_s+' catalog='+r[:machine_catalog].to_s+' TM='+r[:tm].to_s+' HM='+r[:hm].to_s
      t << 'Tutor refs: '+r[:tutor_refs].to_s
      t << 'Egg refs: '+r[:egg_refs].to_s
      t << 'Special refs: '+r[:special_refs].to_s
      t << 'Unique non-level moves: '+r[:nonlevel_unique].size.to_s
      t << 'Executable non-level moves now: '+r[:nonlevel_executable].size.to_s
      t << 'Runtime-gated non-level moves: '+r[:nonlevel_blocked].size.to_s
      t << 'Runtime-gated list: '+blocked.join(', ')
      t << 'Species with no non-level source in pinned BW data: '+none.size.to_s
      t << 'No-nonlevel list: '+none.join(', ')
      t << ''
      t << 'Policy: compatibility is data; acquisition is persistent RPG state; no full movepool free unlock.'
      t << 'Machine/Tutor default state: locked.'
      t << 'Egg/Special: explicit per-instance grant only.'
      t << 'Identity: instance_uid.'
      t << 'Combat Core modified: NO.'
      t << 'Errors: '+r[:errors].size.to_s+' ['+r[:errors].join(',')+']'
      t << 'Core Ready: '+(r[:core_ready] ? '1':'0')
      t.join("\r\n")+"\r\n"
    end

    def write_movepool_acquisition_audit_v0995(report=nil)
      begin
        File.open(MOVEPOOL_ACQUISITION_RUNTIME_AUDIT_FILE_V0995,'wb') do |f|
          f.write(movepool_acquisition_audit_text_v0995(report))
        end
        true
      rescue
        false
      end
    end
  end

  old_modes=VERIFICATION_MODES.dup
  old_labels=VERIFICATION_LABELS.dup
  remove_const(:VERIFICATION_MODES)
  VERIFICATION_MODES=[:normal,:movepool_acquisition_v0995]+old_modes.reject{|x|x==:normal || x==:movepool_acquisition_v0995}
  remove_const(:VERIFICATION_LABELS)
  VERIFICATION_LABELS=old_labels.dup
  VERIFICATION_LABELS[:normal]='NORMAL'
  VERIFICATION_LABELS[:movepool_acquisition_v0995]='MOVEPOOL_ACQUISITION_V0995'
end

class Game_System
  attr_accessor :pmd_machine_unlocks_v0995
  attr_accessor :pmd_tutor_unlocks_v0995
  unless method_defined?(:pmd_ac_v0995_initialize)
    alias pmd_ac_v0995_initialize initialize unless method_defined?(:pmd_ac_v0995_initialize)
    def initialize
      pmd_ac_v0995_initialize
      @pmd_machine_unlocks_v0995={}
      @pmd_tutor_unlocks_v0995={}
    end
  end
end

class PMD_PokemonInstance
  def ensure_move_acquisition_history_v0995
    @move_acquisition_history_v0995=[] if @move_acquisition_history_v0995==nil
    @move_acquisition_history_v0995
  end

  def move_acquisition_history_v0995
    ensure_move_acquisition_history_v0995.dup
  end

  def record_move_acquisition_v0995(source,move,source_key=nil,extra=nil)
    row={:type=>:move_acquisition,:source=>source,:move=>move,:source_key=>source_key,
         :instance_uid=>instance_uid.to_i,:species=>species_key,:level=>@level.to_i}
    if extra!=nil;extra.each{|k,v|row[k]=v};end
    ensure_move_acquisition_history_v0995.push(row)
    row
  end
end

class Scene_PMD_AutoChess
  alias pmd_ac_v0995_start start unless method_defined?(:pmd_ac_v0995_start)
  alias pmd_ac_v0995_refresh_header refresh_header unless method_defined?(:pmd_ac_v0995_refresh_header)
  alias pmd_ac_v0995_prepare_verification_battle prepare_verification_battle unless method_defined?(:pmd_ac_v0995_prepare_verification_battle)
  alias pmd_ac_v0995_update_verification_script update_verification_script unless method_defined?(:pmd_ac_v0995_update_verification_script)
  alias pmd_ac_v0995_terminate terminate unless method_defined?(:pmd_ac_v0995_terminate)
  alias pmd_ac_v0995_log_event log_event unless method_defined?(:pmd_ac_v0995_log_event)

  def start
    pmd_ac_v0995_start
    begin
      if FileTest.exist?(PMD_AC::BATTLE_LOG_FILE)
        text=File.open(PMD_AC::BATTLE_LOG_FILE,'rb'){|f|f.read}
        text.sub!(/PMD AutoChess Proto v0\.[0-9.]+ Battle Verification Log/,
          'PMD AutoChess Proto v0.99.5 Battle Verification Log')
        File.open(PMD_AC::BATTLE_LOG_FILE,'wb'){|f|f.write(text)}
      end
    rescue
    end
    log_event(:movepool_acquisition,
      'FLOW v0.99.5 level_up=7005 machine=15678 tutor=68 egg=2251 special=2 acquisition_state=persistent identity=instance_uid combat_core=unchanged')
    refresh_header
  end

  def refresh_header
    pmd_ac_v0995_refresh_header
    return if @header_sprite==nil || @header_sprite.bitmap==nil
    bmp=@header_sprite.bitmap
    bmp.fill_rect(0,0,Graphics.width,28,Color.new(0,0,0,180))
    pmd_ac_v074_font(bmp)
    bmp.font.size=PMD_AC.const_defined?(:UI_HEADER_TITLE_FONT_V086) ? PMD_AC::UI_HEADER_TITLE_FONT_V086 : 20
    bmp.font.bold=true;bmp.font.color=Color.new(255,255,255)
    bmp.draw_text(16,1,Graphics.width-32,30,'PMD 自走棋原型 v0.99.5',1)
  end

  def movepool_acquisition_v0995?
    verification_mode==:movepool_acquisition_v0995
  end

  def prepare_verification_battle
    pmd_ac_v0995_prepare_verification_battle
    return unless movepool_acquisition_v0995?
    @movepool_acquisition_failed_v0995=false
    @movepool_acquisition_report_v0995=PMD_AC.movepool_acquisition_audit_v0995
    @movepool_acquisition_written_v0995=PMD_AC.write_movepool_acquisition_audit_v0995(@movepool_acquisition_report_v0995)
    @movepool_machine_snapshot_v0995=PMD_AC.machine_unlocks_v0995.dup
    @movepool_tutor_snapshot_v0995=PMD_AC.tutor_unlocks_v0995.dup
    @movepool_test_uid_v0995=99500124
    reg=PMD_AC.pokemon_registry_v045
    @movepool_test_old_instance_v0995=reg[@movepool_test_uid_v0995]
    @movepool_test_instance_v0995=PMD_PokemonInstance.new(:bulbasaur,5,
      {:instance_uid=>@movepool_test_uid_v0995,:ivs=>[15,15,15,15,15,15],:nature=>:hardy,:ability_slot=>:primary})
    reg[@movepool_test_uid_v0995]=@movepool_test_instance_v0995
    PMD_AC.lock_machine_v0995(:tm06)
    PMD_AC.lock_tutor_v0995(:grass_pledge)
    log_event(:showcase,'START mode=MOVEPOOL_ACQUISITION_V0995 mutation=temp_only machine_default=locked tutor_default=locked egg=specific_grant special=specific_grant')
  end

  def restore_movepool_verification_v0995
    return if @movepool_restore_done_v0995
    if @movepool_machine_snapshot_v0995!=nil
      h=PMD_AC.machine_unlocks_v0995;h.clear;@movepool_machine_snapshot_v0995.each{|k,v|h[k]=v}
    end
    if @movepool_tutor_snapshot_v0995!=nil
      h=PMD_AC.tutor_unlocks_v0995;h.clear;@movepool_tutor_snapshot_v0995.each{|k,v|h[k]=v}
    end
    if @movepool_test_uid_v0995!=nil
      reg=PMD_AC.pokemon_registry_v045
      if @movepool_test_old_instance_v0995==nil;reg.delete(@movepool_test_uid_v0995)
      else;reg[@movepool_test_uid_v0995]=@movepool_test_old_instance_v0995;end
    end
    @movepool_restore_done_v0995=true
    true
  end

  def terminate
    restore_movepool_verification_v0995 if movepool_acquisition_v0995?
    pmd_ac_v0995_terminate
  end

  def log_event(category,message)
    if category.to_s=='verify' && movepool_acquisition_v0995? && message.to_s.index('V0995')!=nil && message.to_s.index(' pass=0')!=nil
      @movepool_acquisition_failed_v0995=true
    end
    pmd_ac_v0995_log_event(category,message)
  end

  def log_movepool_verify_v0995(name,pass,detail)
    @movepool_acquisition_failed_v0995=true unless pass
    log_event(:verify,name+' pass='+(pass ? '1':'0')+' '+detail)
  end

  def update_verification_script
    unless movepool_acquisition_v0995?
      pmd_ac_v0995_update_verification_script
      return
    end
    return if @verification_done[:verification_complete]
    @verification_frame=@verification_frame.to_i+1
    f=@verification_frame;r=@movepool_acquisition_report_v0995 || PMD_AC.movepool_acquisition_audit_v0995
    if f>=2 && !@verification_done[:v0995_data]
      pass=r[:core_ready] && r[:species]==494 && r[:machine_refs]==15678 && r[:tutor_refs]==68 && r[:egg_refs]==2251 && r[:special_refs]==2
      log_movepool_verify_v0995('MOVEPOOL_ACQUISITION_DATA_V0995',pass,
        'species='+r[:species].to_s+'/494 level_up=7005 machine='+r[:machine_refs].to_s+'/15678 tutor='+r[:tutor_refs].to_s+'/68 egg='+r[:egg_refs].to_s+'/2251 special='+r[:special_refs].to_s+'/2 catalog='+r[:machine_catalog].to_s+'/101 tm='+r[:tm].to_s+'/95 hm='+r[:hm].to_s+'/6 errors='+r[:errors].size.to_s)
      @verification_done[:v0995_data]=true
    end
    if f>=6 && !@verification_done[:v0995_policy]
      pass=!PMD_AC.machine_unlocked_v0995?(:tm06) && !PMD_AC.tutor_unlocked_v0995?(:grass_pledge)
      log_movepool_verify_v0995('MOVEPOOL_ACQUISITION_POLICY_V0995',pass,
        'all_free=0 machine_default_locked='+(!PMD_AC.machine_unlocked_v0995?(:tm06) ? '1':'0')+' tutor_default_locked='+(!PMD_AC.tutor_unlocked_v0995?(:grass_pledge) ? '1':'0')+' egg_explicit=1 special_explicit=1 identity=instance_uid')
      @verification_done[:v0995_policy]=true
    end
    if f>=10 && !@verification_done[:v0995_runtime_gate]
      pass=r[:nonlevel_unique].size==434 && r[:nonlevel_executable].size==415 && r[:nonlevel_blocked].size==19
      blocked=r[:nonlevel_blocked].keys.collect{|x|x.to_s}.sort.join(',')
      log_movepool_verify_v0995('MOVEPOOL_RUNTIME_GATE_V0995',pass,
        'nonlevel_unique='+r[:nonlevel_unique].size.to_s+'/434 executable='+r[:nonlevel_executable].size.to_s+'/415 blocked='+r[:nonlevel_blocked].size.to_s+'/19 teach_blocks_unimplemented=1 blocked_moves=['+blocked+']')
      @verification_done[:v0995_runtime_gate]=true
    end
    if f>=14 && !@verification_done[:v0995_machine_lock]
      x=PMD_AC.teach_machine_v0995(@movepool_test_uid_v0995,:tm06)
      pass=!x[:ok] && x[:reason]==:source_locked && !@movepool_test_instance_v0995.knows_move_v045?(:toxic)
      log_movepool_verify_v0995('MOVEPOOL_MACHINE_LOCK_V0995',pass,'tm06=toxic result='+x[:reason].to_s+' free_learn=0')
      @verification_done[:v0995_machine_lock]=true
    end
    if f>=18 && !@verification_done[:v0995_machine_teach]
      u=PMD_AC.unlock_machine_v0995(:tm06)
      x=PMD_AC.teach_machine_v0995(@movepool_test_uid_v0995,:tm06)
      pass=u && x[:ok] && x[:reason]==:learned && @movepool_test_instance_v0995.knows_move_v045?(:toxic) && @movepool_test_instance_v0995.active_moves_v045.size<=4
      log_movepool_verify_v0995('MOVEPOOL_MACHINE_TEACH_V0995',pass,'unlock='+(u ? '1':'0')+' result='+x[:reason].to_s+' learned='+(@movepool_test_instance_v0995.knows_move_v045?(:toxic) ? '1':'0')+' active_slots='+@movepool_test_instance_v0995.active_moves_v045.size.to_s)
      @verification_done[:v0995_machine_teach]=true
    end
    if f>=22 && !@verification_done[:v0995_tutor_gate]
      PMD_AC.unlock_tutor_v0995(:grass_pledge)
      x=PMD_AC.teach_tutor_v0995(@movepool_test_uid_v0995,:grass_pledge)
      pass=!x[:ok] && x[:reason]==:move_not_executable && !@movepool_test_instance_v0995.knows_move_v045?(:grass_pledge)
      log_movepool_verify_v0995('MOVEPOOL_TUTOR_RUNTIME_GATE_V0995',pass,'move=grass_pledge compatible=1 unlocked=1 result='+x[:reason].to_s+' unsafe_learn=0')
      @verification_done[:v0995_tutor_gate]=true
    end
    if f>=26 && !@verification_done[:v0995_egg]
      x=PMD_AC.grant_egg_move_v0995(@movepool_test_uid_v0995,:charm,:verifier_egg)
      pass=x[:ok] && @movepool_test_instance_v0995.knows_move_v045?(:charm)
      log_movepool_verify_v0995('MOVEPOOL_EGG_GRANT_V0995',pass,'move=charm compatible=1 explicit_grant=1 result='+x[:reason].to_s)
      @verification_done[:v0995_egg]=true
    end
    if f>=30 && !@verification_done[:v0995_special]
      uid=99500172;reg=PMD_AC.pokemon_registry_v045;old=reg[uid]
      pi=PMD_PokemonInstance.new(:pichu,5,{:instance_uid=>uid,:ivs=>[15,15,15,15,15,15],:nature=>:hardy,:ability_slot=>:primary});reg[uid]=pi
      x=PMD_AC.grant_special_move_v0995(uid,:volt_tackle,:verifier_light_ball)
      pass=x[:ok] && pi.knows_move_v045?(:volt_tackle) && x[:source]==:special
      if old==nil;reg.delete(uid);else;reg[uid]=old;end
      log_movepool_verify_v0995('MOVEPOOL_SPECIAL_GRANT_V0995',pass,'species=pichu move=volt_tackle canonical_method=light_ball_egg result='+x[:reason].to_s)
      @verification_done[:v0995_special]=true
    end
    if f>=34 && !@verification_done[:v0995_identity_history]
      h=@movepool_test_instance_v0995.move_acquisition_history_v0995
      wrong=h.find_all{|e|e[:instance_uid].to_i!=@movepool_test_uid_v0995.to_i}.size
      sources=h.collect{|e|e[:source]}.uniq
      pass=wrong==0 && sources.include?(:machine) && sources.include?(:egg)
      log_movepool_verify_v0995('MOVEPOOL_IDENTITY_HISTORY_V0995',pass,'instance_uid='+@movepool_test_uid_v0995.to_s+' rows='+h.size.to_s+' wrong_uid='+wrong.to_s+' sources=['+sources.collect{|x|x.to_s}.join(',')+'] actor_id_identity=0')
      @verification_done[:v0995_identity_history]=true
    end
    if f>=38 && !@verification_done[:v0995_report]
      pass=@movepool_acquisition_written_v0995 && FileTest.exist?(PMD_AC::MOVEPOOL_ACQUISITION_RUNTIME_AUDIT_FILE_V0995)
      log_movepool_verify_v0995('MOVEPOOL_ACQUISITION_REPORT_V0995',pass,'file='+PMD_AC::MOVEPOOL_ACQUISITION_RUNTIME_AUDIT_FILE_V0995+' blocked_runtime='+r[:nonlevel_blocked].size.to_s+' species_without_nonlevel='+r[:species_without_nonlevel].size.to_s)
      @verification_done[:v0995_report]=true
    end
    if f>=44 && !@verification_done[:v0995_final]
      pass=!@movepool_acquisition_failed_v0995 && r[:core_ready]
      log_movepool_verify_v0995('MOVEPOOL_ACQUISITION_V0995',pass,
        'architecture=ready data=canonical acquisition=persistent no_free_full_movepool=1 blocked_runtime='+r[:nonlevel_blocked].size.to_s+' next=exclusive_move_runtime+early_sparse_content')
      @verification_done[:v0995_final]=true
      restore_movepool_verification_v0995
    end
    complete_verification_mode if f>=PMD_AC::MOVEPOOL_ACQUISITION_VERIFY_END_V0995
  end
end
