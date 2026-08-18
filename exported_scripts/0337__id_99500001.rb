# encoding: UTF-8
#==============================================================================
# 【PMD AutoChess 中文維護說明】
# 腳本：PMD AutoChess Content Validation Data v0.95
# 分類：量產內容驗證／跨資料庫完整性／開發工具
#
# 【用途】
# 專案進入 494 種 Pokémon、526 個可執行招式、7005 筆 Learnset、Region、Boss、
# 圖鑑、掉落等大量內容後，單靠逐場人工測試已無法可靠找出「資料有寫但彼此沒接上」
# 的問題。本腳本建立統一 Content Validation 規則，專門檢查跨系統引用與已知缺口。
#
# 【核心原則：ERROR 與 KNOWN GAP 分開】
# - ERROR：本來應該有效的資料斷線，例如進化目標不存在、Learnset Move 沒 Runtime、
#   Region 指到不存在 Formation、Boss Summon 指到不存在 Species。ERROR 會使
#   CONTENT_VALIDATION_V095 最終 pass=0。
# - WARN / KNOWN GAP：目前 Roadmap 明確知道尚未 100% 的內容，例如 Ability Runtime
#   目前 1028/1193 slots、483/494 species，以及 v0.94 Production Loot Binding 為 0。
#   這些會寫入報告，但不會把 Core Validation 判定失敗。
#
# 【主要設定項】
# - CONTENT_VALIDATION_EXPECTED_V095：目前 Freeze 後應維持的正式資料數量。
# - CONTENT_VALIDATION_TEST_PMD_MIN/MAX_V095：FullTestProject 實際攜帶的 PMD 範圍。
# - CONTENT_VALIDATION_REPORT_FILE_V095：Runtime 可輸出的完整驗證報告檔名。
# - CONTENT_VALIDATION_REQUIRED_TACTICAL_KEYS_V095：Species AI Profile 必備欄位。
#
# 【驗證內容】
# 1. Species / Dex / Evolution / Ability Slots / Tactical Profile。
# 2. 7005 Learnset refs 是否全部指向 MoveDB 且有 executable Runtime。
# 3. 526 executable moves 是否都有 Skill / Presentation / Visual / Audio bridge。
# 4. Ability canonical slots 與 SpeciesDB 是否一致；Runtime 覆蓋率只列 Known Gap。
# 5. PMDCollab compiled metadata 494 種；FullTestProject 0001-0026 必須有 Walk/Idle。
# 6. Stage / Encounter / Formation / Region / Unlock / Map Profile / Boss Cross-reference。
# 7. Loot Pool / Binding / Reward Row 基本合法性。
#
# 【可調參數】
# 若 FullTestProject 未來改成 0001-0151，可把 CONTENT_VALIDATION_TEST_PMD_MAX_V095
# 改成 151；正式完整版若放齊 0001-0494，再改成 494 即可。
#
# 【事件／腳本呼叫方式】
# 取得 Hash：
#   r = PMD_AC.content_validation_report_v095
#   p r[:errors]
#
# 輸出文字檔：
#   PMD_AC.write_content_validation_report_v095
#
# 查目前是否 Core Pass：
#   PMD_AC.content_validation_core_pass_v095?
#
# 【實際範例】
# 若新增 Region：
#   :my_area=>{:formations=>[{:formation=>:my_pack,:weight=>50}]}
# 但忘了建立 :my_pack，Validator 會回報：
#   ERROR region_formation:my_area->my_pack
#
# 若 Ability 尚未做到 100%，則只會回報：
#   WARN ability_runtime_gap slots=1028/1193 species=483/494
# 這是 Roadmap 缺口，不是資料損壞。
#
# 【注意事項】
# - RPG Maker VX / RGSS2 / Ruby 1.8 相容。
# - 禁止使用舊式 instance-variable reflection probe。
# - 本腳本只讀資料，不修改戰鬥數值、AI、掉落、圖鑑或存檔。
# - TestProject 只攜帶 0001-0026 PMD 是刻意設計，不要求實體素材 494/494。
#==============================================================================
module PMD_AC
  CONTENT_VALIDATION_VERSION_V095 = '0.95'
  CONTENT_VALIDATION_REPORT_FILE_V095 = 'PMD_ContentValidation_v0.95.log'
  CONTENT_VALIDATION_VERIFY_END_V095 = 40
  CONTENT_VALIDATION_TEST_PMD_MIN_V095 = 1
  CONTENT_VALIDATION_TEST_PMD_MAX_V095 = 26

  CONTENT_VALIDATION_EXPECTED_V095 = {
    :species=>494,
    :dex_min=>1,
    :dex_max=>494,
    :evolution_lines=>248,
    :forms=>702,
    :move_db=>559,
    :executable_moves=>526,
    :learnset_refs=>7005,
    :ability_slots=>1193,
    :ability_runtime_slots=>1028,
    :ability_runtime_species=>483,
    :stage_count=>3,
    :encounter_count=>3,
    :formation_count=>8,
    :region_count=>4,
    :boss_profile_count=>1,
    :map_profile_count=>3
  }

  CONTENT_VALIDATION_REQUIRED_TACTICAL_KEYS_V095 = [
    :role_primary,:target_policy,:movement_policy,:threat_policy,:skill_policy,
    :target_commitment,:range,:preferred_range,:collision_radius,:melee_reach,
    :move_speed,:attack_wait
  ]

  CONTENT_VALIDATION_REWARD_TYPES_V095 = [
    :gold,:item,:weapon,:armor,:variable,:switch,:common_event
  ]

  class << self
    def content_validation_new_report_v095
      {
        :version=>CONTENT_VALIDATION_VERSION_V095,
        :errors=>[], :warnings=>[], :info=>[], :sections=>{},
        :core_pass=>false, :production_ready=>false
      }
    end

    def content_validation_push_v095(report,severity,code,detail='')
      row={:code=>code.to_s,:detail=>detail.to_s}
      case severity
      when :error
        report[:errors].push(row)
      when :warning
        report[:warnings].push(row)
      else
        report[:info].push(row)
      end
      row
    end

    def content_validation_safe_v095(report,section)
      begin
        value=yield
        report[:sections][section]=value
        value
      rescue Exception => e
        content_validation_push_v095(report,:error,
          'validator_exception:'+section.to_s,e.class.to_s+':'+e.message.to_s)
        report[:sections][section]={:pass=>false,:exception=>e.class.to_s}
        report[:sections][section]
      end
    end

    def content_validation_species_v095(report)
      content_validation_safe_v095(report,:species) do
        exp=CONTENT_VALIDATION_EXPECTED_V095
        db=defined?(SPECIES_DB_V016) ? SPECIES_DB_V016 : {}
        lines=defined?(EVOLUTION_LINES_V016) ? EVOLUTION_LINES_V016 : {}
        forms=defined?(FORMS_DB_V016) ? FORMS_DB_V016 : {}
        dex_seen={}
        learnset_refs=0
        missing_moves=0
        nonexec_moves=0
        bad_lines=0
        bad_evo=0
        bad_tactical=0
        ability_slot_corrections=0
        bad_stats=0

        if db.size!=exp[:species]
          content_validation_push_v095(report,:error,'species_count',db.size.to_s+'/'+exp[:species].to_s)
        end
        if lines.size!=exp[:evolution_lines]
          content_validation_push_v095(report,:error,'evolution_line_count',lines.size.to_s+'/'+exp[:evolution_lines].to_s)
        end
        form_count=0
        forms.each_value{|h| form_count += h.is_a?(Hash) ? h.size : 0}
        if form_count!=exp[:forms]
          content_validation_push_v095(report,:error,'form_count',form_count.to_s+'/'+exp[:forms].to_s)
        end

        db.each_pair do |key,d|
          if d==nil || d[:species_key]!=key
            content_validation_push_v095(report,:error,'species_key:'+key.to_s,'hash_key_mismatch')
          end
          n=d==nil ? 0 : d[:national_dex].to_i
          if n<exp[:dex_min] || n>exp[:dex_max] || dex_seen[n]
            content_validation_push_v095(report,:error,'national_dex:'+key.to_s,n.to_s)
          else
            dex_seen[n]=key
          end
          stats=d==nil ? nil : d[:base_stats]
          unless stats.is_a?(Array) && stats.size==6 && stats.all?{|x|x.to_i>0}
            bad_stats+=1
          end

          line_key=d==nil ? nil : d[:line]
          line=line_key==nil ? nil : lines[line_key]
          unless line!=nil && (line[:members]||[]).include?(key)
            bad_lines+=1
          end

          ((d||{})[:evolution_rules]||[]).each do |rule|
            target=rule[:target_species]
            if target==nil || db[target]==nil
              bad_evo+=1
            elsif db[target][:line]!=line_key
              bad_evo+=1
            end
          end

          tp=(d||{})[:tactical_profile]
          if !tp.is_a?(Hash) || CONTENT_VALIDATION_REQUIRED_TACTICAL_KEYS_V095.any?{|x|tp[x]==nil}
            bad_tactical+=1
          end

          if defined?(ABILITY_SPECIES_SLOTS_V024)
            canon=ABILITY_SPECIES_SLOTS_V024[key]||{}
            src=(d||{})[:ability_slots]||{}
            [:primary,:secondary,:hidden].each do |slot|
              ability_slot_corrections+=1 if canon[slot]!=src[slot]
            end
          end

          ((d||{})[:learnset]||[]).each do |row|
            learnset_refs+=1
            mk=row[:move]
            if !defined?(MOVE_DB_V017) || MOVE_DB_V017[mk]==nil
              missing_moves+=1
            elsif !move_executable?(mk)
              nonexec_moves+=1
            end
          end
        end

        if dex_seen.size!=exp[:species] || dex_seen.keys.min!=exp[:dex_min] || dex_seen.keys.max!=exp[:dex_max]
          content_validation_push_v095(report,:error,'national_dex_continuity',dex_seen.size.to_s)
        end
        content_validation_push_v095(report,:error,'species_base_stats',bad_stats.to_s) if bad_stats>0
        content_validation_push_v095(report,:error,'species_line_refs',bad_lines.to_s) if bad_lines>0
        content_validation_push_v095(report,:error,'evolution_target_refs',bad_evo.to_s) if bad_evo>0
        content_validation_push_v095(report,:error,'tactical_profiles',bad_tactical.to_s) if bad_tactical>0
        expected_corrections=defined?(ABILITY_MANIFEST_V024) ? ABILITY_MANIFEST_V024[:corrected_slot_count].to_i : 0
        if ability_slot_corrections!=expected_corrections
          content_validation_push_v095(report,:error,'ability_slot_corrections',
            ability_slot_corrections.to_s+'/'+expected_corrections.to_s)
        elsif ability_slot_corrections>0
          content_validation_push_v095(report,:info,'ability_slot_corrections',
            ability_slot_corrections.to_s+' gen5_corrections=v0.24 expected=1')
        end
        if learnset_refs!=exp[:learnset_refs]
          content_validation_push_v095(report,:error,'learnset_ref_count',learnset_refs.to_s+'/'+exp[:learnset_refs].to_s)
        end
        content_validation_push_v095(report,:error,'learnset_missing_move',missing_moves.to_s) if missing_moves>0
        content_validation_push_v095(report,:error,'learnset_nonexec_move',nonexec_moves.to_s) if nonexec_moves>0

        {:pass=>bad_stats==0 && bad_lines==0 && bad_evo==0 && bad_tactical==0 &&
          ability_slot_corrections==expected_corrections && missing_moves==0 && nonexec_moves==0 &&
          db.size==exp[:species] && learnset_refs==exp[:learnset_refs],
         :species=>db.size,:dex=>dex_seen.size,:lines=>lines.size,:forms=>form_count,
         :learnset_refs=>learnset_refs,:missing_moves=>missing_moves,:nonexec_moves=>nonexec_moves,
         :bad_evolution=>bad_evo,:bad_tactical=>bad_tactical,:ability_slot_corrections=>ability_slot_corrections}
      end
    end

    def content_validation_moves_v095(report)
      content_validation_safe_v095(report,:moves) do
        exp=CONTENT_VALIDATION_EXPECTED_V095
        move_db=defined?(MOVE_DB_V017) ? MOVE_DB_V017 : {}
        keys=defined?(NATIVE_SEMANTIC_CLASS_MAP_V063) ? NATIVE_SEMANTIC_CLASS_MAP_V063.keys : []
        exec=0;skill=0;presentation=0;visual=0;audio=0
        missing=[]
        keys.each do |k|
          exec+=1 if move_executable?(k)
          sd=skill_data(('mv_'+k.to_s).to_sym)
          skill+=1 if sd!=nil && !sd.empty?
          p=move_presentation_profile_v055(k)
          presentation+=1 if p!=nil && !p.empty?
          v=skill_visual_move_profile_v031(k)
          visual+=1 if v!=nil && !v.empty?
          a=skill_audio_move_profile_v032(k)
          audio+=1 if a!=nil && !a.empty?
          if !move_executable?(k) || sd==nil || sd.empty? || p==nil || p.empty? ||
             v==nil || v.empty? || a==nil || a.empty?
            missing.push(k)
          end
        end
        man=defined?(MOVE_COVERAGE_X_MANIFEST_V059) ? MOVE_COVERAGE_X_MANIFEST_V059 : {}
        if move_db.size!=exp[:move_db]
          content_validation_push_v095(report,:error,'move_db_count',move_db.size.to_s+'/'+exp[:move_db].to_s)
        end
        if keys.size!=exp[:executable_moves]
          content_validation_push_v095(report,:error,'semantic_move_count',keys.size.to_s+'/'+exp[:executable_moves].to_s)
        end
        if man[:cumulative_mapped_move_count].to_i!=exp[:executable_moves] ||
           man[:cumulative_reference_covered].to_i!=exp[:learnset_refs] ||
           man[:remaining_reference_count].to_i!=0
          content_validation_push_v095(report,:error,'move_coverage_manifest',man.inspect)
        end
        unless missing.empty?
          content_validation_push_v095(report,:error,'move_bridge_missing',missing[0,20].join(','))
        end
        {:pass=>move_db.size==exp[:move_db] && keys.size==exp[:executable_moves] && missing.empty? &&
          exec==exp[:executable_moves] && skill==exp[:executable_moves] &&
          presentation==exp[:executable_moves] && visual==exp[:executable_moves] && audio==exp[:executable_moves],
         :move_db=>move_db.size,:executable=>exec,:skill=>skill,:presentation=>presentation,
         :visual=>visual,:audio=>audio,:learnset_covered=>man[:cumulative_reference_covered].to_i,
         :learnset_total=>man[:learnset_reference_total].to_i,:missing=>missing.size}
      end
    end

    def content_validation_abilities_v095(report)
      content_validation_safe_v095(report,:abilities) do
        exp=CONTENT_VALIDATION_EXPECTED_V095
        canon=defined?(ABILITY_SPECIES_SLOTS_V024) ? ABILITY_SPECIES_SLOTS_V024 : {}
        m=defined?(ABILITY_RUNTIME_MANIFEST_V067) ? ABILITY_RUNTIME_MANIFEST_V067 : {}
        if canon.size!=exp[:species]
          content_validation_push_v095(report,:error,'ability_species_slots',canon.size.to_s+'/'+exp[:species].to_s)
        end
        if defined?(ABILITY_MANIFEST_V024) && ABILITY_MANIFEST_V024[:total_slot_count].to_i!=exp[:ability_slots]
          content_validation_push_v095(report,:error,'ability_canonical_slot_count',ABILITY_MANIFEST_V024[:total_slot_count].to_s)
        end
        if m[:implemented_slot_count].to_i<exp[:ability_slots] || m[:species_with_any_implemented_ability].to_i<exp[:species]
          content_validation_push_v095(report,:warning,'ability_runtime_gap',
            'slots='+m[:implemented_slot_count].to_i.to_s+'/'+exp[:ability_slots].to_s+
            ' species='+m[:species_with_any_implemented_ability].to_i.to_s+'/'+exp[:species].to_s+
            ' known_freeze=v0.67.1')
        end
        {:pass=>canon.size==exp[:species] && m[:implemented_slot_count].to_i==exp[:ability_runtime_slots] &&
          m[:species_with_any_implemented_ability].to_i==exp[:ability_runtime_species],
         :canonical_species=>canon.size,:total_slots=>exp[:ability_slots],
         :runtime_slots=>m[:implemented_slot_count].to_i,
         :runtime_species=>m[:species_with_any_implemented_ability].to_i,:known_gap=>true}
      end
    end

    def content_validation_pmd_v095(report)
      content_validation_safe_v095(report,:pmd) do
        st=compiled_data_status_v061
        exp=CONTENT_VALIDATION_EXPECTED_V095
        installed=0;walk=0;idle=0;hurt=0;hop=0
        n=CONTENT_VALIDATION_TEST_PMD_MIN_V095
        while n<=CONTENT_VALIDATION_TEST_PMD_MAX_V095
          sid=sprintf('%04d',n)
          path='Graphics/PMD/'+sid
          if FileTest.exist?(path)
            installed+=1
            walk+=1 if compiled_action_asset_available_v061?(sid,:walk)
            idle+=1 if compiled_action_asset_available_v061?(sid,:idle)
            hurt+=1 if compiled_action_asset_available_v061?(sid,:hurt)
            hop+=1 if compiled_action_asset_available_v061?(sid,:hop)
          end
          n+=1
        end
        expected_test=CONTENT_VALIDATION_TEST_PMD_MAX_V095-CONTENT_VALIDATION_TEST_PMD_MIN_V095+1
        if !st[:loaded] || st[:species].to_i!=exp[:species]
          content_validation_push_v095(report,:error,'pmd_compiled_metadata',st.inspect)
        end
        if installed!=expected_test
          content_validation_push_v095(report,:error,'pmd_test_folders',installed.to_s+'/'+expected_test.to_s)
        end
        if walk!=expected_test
          content_validation_push_v095(report,:error,'pmd_walk_assets',walk.to_s+'/'+expected_test.to_s)
        end
        if idle!=expected_test
          content_validation_push_v095(report,:error,'pmd_idle_assets',idle.to_s+'/'+expected_test.to_s)
        end
        content_validation_push_v095(report,:info,'pmd_test_scope',
          'installed='+installed.to_s+'/494 intentional_fulltest_subset=1 hop='+hop.to_s+'/'+expected_test.to_s)
        {:pass=>st[:loaded] && st[:species].to_i==exp[:species] && installed==expected_test &&
          walk==expected_test && idle==expected_test,
         :compiled_species=>st[:species].to_i,:compiled_entries=>st[:entries].to_i,
         :installed=>installed,:expected_test=>expected_test,:walk=>walk,:idle=>idle,:hurt=>hurt,:hop=>hop}
      end
    end

    def content_validation_species_ref_v095(report,code,key)
      return true if defined?(SPECIES_DB_V016) && SPECIES_DB_V016[key]!=nil
      content_validation_push_v095(report,:error,code,key.to_s)
      false
    end

    def content_validation_encounters_v095(report)
      content_validation_safe_v095(report,:encounters) do
        exp=CONTENT_VALIDATION_EXPECTED_V095
        bad=0
        stages=defined?(STAGE_DB_V080) ? STAGE_DB_V080 : {}
        encounters=defined?(RPG_ENCOUNTER_DB_V081) ? RPG_ENCOUNTER_DB_V081 : {}
        formations=defined?(ENCOUNTER_FORMATIONS_V086) ? ENCOUNTER_FORMATIONS_V086 : {}
        regions=defined?(REGION_ECOLOGY_PROFILES_V086) ? REGION_ECOLOGY_PROFILES_V086 : {}
        boss_profiles=defined?(BOSS_PROFILES_V091) ? BOSS_PROFILES_V091 : {}
        map_profiles=defined?(MAP_PROFILES_V092) ? MAP_PROFILES_V092 : {}

        stages.each_pair do |sid,d|
          (d[:enemy_setup]||[]).each do |row|
            bad+=1 unless content_validation_species_ref_v095(report,'stage_species:'+sid.to_s,row[0])
          end
          (d[:recruit_pool]||[]).each do |sp|
            bad+=1 unless content_validation_species_ref_v095(report,'stage_recruit:'+sid.to_s,sp)
          end
        end
        if defined?(STAGE_ORDER_V080)
          STAGE_ORDER_V080.each{|sid| if stages[sid]==nil; bad+=1; content_validation_push_v095(report,:error,'stage_order',sid.to_s);end}
        end

        encounters.each_pair do |key,d|
          (d[:enemy_setup]||[]).each do |row|
            bad+=1 unless content_validation_species_ref_v095(report,'encounter_species:'+key.to_s,row[0])
          end
          (d[:enemy_pool]||[]).each do |row|
            bad+=1 unless content_validation_species_ref_v095(report,'encounter_pool:'+key.to_s,row[:species])
          end
        end

        formations.each_pair do |key,d|
          (d[:members]||[]).each do |row|
            bad+=1 unless content_validation_species_ref_v095(report,'formation_species:'+key.to_s,row[:species])
          end
        end

        regions.each_pair do |key,d|
          base=d[:base_profile]
          if defined?(ENCOUNTER_PROFILES_V084) && ENCOUNTER_PROFILES_V084[base]==nil
            bad+=1;content_validation_push_v095(report,:error,'region_base_profile:'+key.to_s,base.to_s)
          end
          (d[:formations]||[]).each do |row|
            fk=row[:formation]
            if formations[fk]==nil
              bad+=1;content_validation_push_v095(report,:error,'region_formation:'+key.to_s,fk.to_s)
            end
          end
          pk=d[:presentation]
          if pk!=nil && defined?(BATTLE_PRESENTATION_PROFILES_V085) && BATTLE_PRESENTATION_PROFILES_V085[pk]==nil
            bad+=1;content_validation_push_v095(report,:error,'region_presentation:'+key.to_s,pk.to_s)
          end
        end

        if defined?(STAGE_REGION_MAP_V090)
          STAGE_REGION_MAP_V090.each_pair do |sid,rk|
            if stages[sid]==nil || regions[rk]==nil
              bad+=1;content_validation_push_v095(report,:error,'stage_region:'+sid.to_s,rk.to_s)
            end
          end
        end

        map_profiles.each_pair do |key,d|
          rk=d[:region]
          if rk!=nil && regions[rk]==nil
            bad+=1;content_validation_push_v095(report,:error,'map_profile_region:'+key.to_s,rk.to_s)
          end
        end
        if defined?(MAP_BINDINGS_V092)
          MAP_BINDINGS_V092.each_pair do |mid,d|
            pk=d.is_a?(Hash) ? d[:profile] : d
            if map_profiles[pk]==nil
              bad+=1;content_validation_push_v095(report,:error,'map_binding:'+mid.to_s,pk.to_s)
            end
          end
        end

        if defined?(BOSS_ENCOUNTER_PROFILE_V091)
          BOSS_ENCOUNTER_PROFILE_V091.each_pair do |enc,pk|
            if encounters[enc]==nil || boss_profiles[pk]==nil
              bad+=1;content_validation_push_v095(report,:error,'boss_link:'+enc.to_s,pk.to_s)
            elsif encounters[enc][:kind]!=:boss
              bad+=1;content_validation_push_v095(report,:error,'boss_link_kind:'+enc.to_s,encounters[enc][:kind].to_s)
            end
          end
        end
        boss_profiles.each_pair do |pk,p|
          enc=p[:encounter]
          if enc!=nil && encounters[enc]==nil
            bad+=1;content_validation_push_v095(report,:error,'boss_encounter:'+pk.to_s,enc.to_s)
          end
          (p[:phases]||[]).each do |phase|
            (phase[:effects]||[]).each do |effect|
              kind=effect[0]
              if defined?(BOSS_EFFECT_TYPES_V091) && !BOSS_EFFECT_TYPES_V091.include?(kind)
                bad+=1;content_validation_push_v095(report,:error,'boss_effect:'+pk.to_s,kind.to_s)
              end
              if kind==:summon
                bad+=1 unless content_validation_species_ref_v095(report,'boss_summon:'+pk.to_s,effect[1])
              end
            end
          end
        end

        if defined?(REGION_UNLOCK_RULES_V087)
          REGION_UNLOCK_RULES_V087.each_key do |rk|
            if regions[rk]==nil
              bad+=1;content_validation_push_v095(report,:error,'unlock_region',rk.to_s)
            end
          end
        end
        if defined?(FORMATION_UNLOCK_RULES_V087)
          FORMATION_UNLOCK_RULES_V087.each_key do |fk|
            if formations[fk]==nil
              bad+=1;content_validation_push_v095(report,:error,'unlock_formation',fk.to_s)
            end
          end
        end

        [[:stage,stages.size,exp[:stage_count]],[:encounter,encounters.size,exp[:encounter_count]],
         [:formation,formations.size,exp[:formation_count]],[:region,regions.size,exp[:region_count]],
         [:boss,boss_profiles.size,exp[:boss_profile_count]],[:map_profile,map_profiles.size,exp[:map_profile_count]]].each do |row|
          if row[1]!=row[2]
            bad+=1;content_validation_push_v095(report,:error,row[0].to_s+'_count',row[1].to_s+'/'+row[2].to_s)
          end
        end

        {:pass=>bad==0,:bad_refs=>bad,:stages=>stages.size,:encounters=>encounters.size,
         :formations=>formations.size,:regions=>regions.size,:boss_profiles=>boss_profiles.size,
         :map_profiles=>map_profiles.size}
      end
    end

    def content_validation_reward_row_valid_v095(report,code,row)
      t=row[:type]
      unless CONTENT_VALIDATION_REWARD_TYPES_V095.include?(t)
        content_validation_push_v095(report,:error,code+':type',t.to_s)
        return false
      end
      id=row[:id].to_i
      case t
      when :item
        if id<=0 || $data_items==nil || $data_items[id]==nil
          content_validation_push_v095(report,:error,code+':item',id.to_s);return false
        end
      when :weapon
        if id<=0 || $data_weapons==nil || $data_weapons[id]==nil
          content_validation_push_v095(report,:error,code+':weapon',id.to_s);return false
        end
      when :armor
        if id<=0 || $data_armors==nil || $data_armors[id]==nil
          content_validation_push_v095(report,:error,code+':armor',id.to_s);return false
        end
      when :variable,:switch,:common_event
        if id<=0
          content_validation_push_v095(report,:error,code+':id',id.to_s);return false
        end
      end
      true
    end

    def content_validation_loot_v095(report)
      content_validation_safe_v095(report,:loot) do
        pools=defined?(LOOT_POOLS_V094) ? LOOT_POOLS_V094 : {}
        bindings=defined?(LOOT_POOL_BINDINGS_V094) ? LOOT_POOL_BINDINGS_V094 : {}
        bad=0
        pools.each_pair do |key,pool|
          entries=pool[:entries]||[]
          if pool[:base_rolls].to_i<=0 || pool[:max_rolls].to_i<pool[:base_rolls].to_i || entries.empty?
            bad+=1;content_validation_push_v095(report,:error,'loot_pool:'+key.to_s,'invalid_rolls_or_empty')
          end
          entries.each do |row|
            if row[:weight].to_i<=0
              bad+=1;content_validation_push_v095(report,:error,'loot_weight:'+key.to_s,row[:key].to_s)
            end
            bad+=1 unless content_validation_reward_row_valid_v095(report,'loot_reward:'+key.to_s,row)
          end
        end
        bindings.each_pair do |source,pool_key|
          if pools[pool_key]==nil
            bad+=1;content_validation_push_v095(report,:error,'loot_binding_pool',source.inspect+'->'+pool_key.to_s)
          end
          if source.is_a?(Array) && source.size>=2
            kind=source[0];key=source[1]
            valid=true
            case kind
            when :stage
              valid=defined?(STAGE_DB_V080) && STAGE_DB_V080[key.to_i]!=nil
            when :region
              valid=defined?(REGION_ECOLOGY_PROFILES_V086) && REGION_ECOLOGY_PROFILES_V086[key]!=nil
            when :formation
              valid=defined?(ENCOUNTER_FORMATIONS_V086) && ENCOUNTER_FORMATIONS_V086[key]!=nil
            when :encounter
              valid=defined?(RPG_ENCOUNTER_DB_V081) && RPG_ENCOUNTER_DB_V081[key]!=nil
            end
            unless valid
              bad+=1;content_validation_push_v095(report,:error,'loot_binding_source',source.inspect)
            end
          end
        end
        if bindings.empty?
          content_validation_push_v095(report,:warning,'loot_production_bindings',
            '0 item_catalog=deferred v0.94_policy=preserved')
        end
        {:pass=>bad==0,:pools=>pools.size,:production_bindings=>bindings.size,
         :bad=>bad,:item_catalog_deferred=>bindings.empty?}
      end
    end

    def content_validation_report_v095
      report=content_validation_new_report_v095
      content_validation_species_v095(report)
      content_validation_moves_v095(report)
      content_validation_abilities_v095(report)
      content_validation_pmd_v095(report)
      content_validation_encounters_v095(report)
      content_validation_loot_v095(report)
      report[:core_pass]=report[:errors].empty?
      report[:production_ready]=report[:core_pass] && report[:warnings].empty?
      report
    end

    def content_validation_core_pass_v095?
      content_validation_report_v095[:core_pass]
    end

    def content_validation_text_v095(report=nil)
      r=report || content_validation_report_v095
      s=[]
      s.push('PMD AutoChess Content Validation v0.95')
      s.push('Core: '+(r[:core_pass] ? 'PASS':'FAIL')+
        ' | Production Ready: '+(r[:production_ready] ? 'YES':'NO')+
        ' | Errors='+r[:errors].size.to_s+' Warnings='+r[:warnings].size.to_s)
      s.push('-'*72)
      r[:sections].each_pair do |key,v|
        line='['+(v[:pass] ? 'PASS':'FAIL')+'] '+key.to_s
        v.each_pair do |k,val|
          next if k==:pass || val.is_a?(Array) || val.is_a?(Hash)
          line+=' '+k.to_s+'='+val.to_s
        end
        s.push(line)
      end
      unless r[:errors].empty?
        s.push('-'*72);s.push('ERRORS')
        r[:errors].each{|x|s.push('ERROR '+x[:code].to_s+' '+x[:detail].to_s)}
      end
      unless r[:warnings].empty?
        s.push('-'*72);s.push('KNOWN GAPS / WARNINGS')
        r[:warnings].each{|x|s.push('WARN '+x[:code].to_s+' '+x[:detail].to_s)}
      end
      unless r[:info].empty?
        s.push('-'*72);s.push('INFO')
        r[:info].each{|x|s.push('INFO '+x[:code].to_s+' '+x[:detail].to_s)}
      end
      s.push('-'*72)
      s.join("\r\n")+"\r\n"
    end

    def write_content_validation_report_v095(report=nil)
      r=report || content_validation_report_v095
      begin
        File.open(CONTENT_VALIDATION_REPORT_FILE_V095,'wb'){|f|f.write(content_validation_text_v095(r))}
        true
      rescue
        false
      end
    end
  end
end
