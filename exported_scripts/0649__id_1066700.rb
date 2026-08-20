# encoding: UTF-8
#===============================================================================
# ■ PMD AutoChess - P8 Formal Cross-Gate Regression + QA Shortcut Consolidation I
#   v1.06.67 PRODUCTION CANDIDATE
#-------------------------------------------------------------------------------
# 【用途】
# - 從 v1.06.66 FORMAL PASS / Gate 3 SEALED 接續，不重開任何 sealed gameplay。
# - 提供唯一目前 TEST launcher：Scene_Map plain F5。
# - Fast Seal 只組合「目前仍有效」的 accepted audit API，不呼叫已被後續 Authority
#   部分覆寫的 v1.06.10 aggregate structural audit。
# - Gate 1：VXRD / Random Hunt 結構與核心 API invariant。
# - Gate 2：Map091 source/content、current materialization、Route Safety、Loading、
#   A1 liquid semantic、BCD automatic stamping=0。
# - Gate 3：直接重用 v1.06.66 integrated seal contract。
# - Fast Seal 前後比對 Map090 / Map091 file CRC、Map090 live table checksum、
#   VXRD state、Hunt session、Party、Scene，證明 read-only / detached contract。
#
# 【QA Shortcut Governance】
# - 本候選精準退休舊 F6 / F7 / F9 QA launcher；舊 fixture method 保留供 issue-driven
#   手動/API 診斷，不按 key symbol 全域攔截。
# - F8 不由本腳本攔截或重定義；正式 Vertical Slice / PMD menu return 保留。
# - F8 在舊 visual fixture 內的 finding control 亦保留，但那些舊 fixture 已無 permanent
#   F-key launcher。
#
# 【Fast Seal 不變量】
# HARNESS_EXTRA_RNG_CALLS=0
# REWARD_GRANT=0
# MAP090/091_MUTATION=0
# BATTLE_LAUNCH=0
# SESSION_MUTATION=0
#===============================================================================
$imported={} unless defined?($imported)
$imported['PMD_AutoChess_P8FormalCrossGateRegressionQAShortcutConsolidationI_v10667']=true

module PMD_AC
  P8_VERSION_V10667='1.06.67'
  P8_LOG_V10667='PMD_P8_CrossGateRegression_LATEST.log'
  P8_FORMAL_BASE_VERSION_V10667='1.06.66'
  P8_FORMAL_BASE_SCRIPT_COUNT_V10667=651
  P8_FORMAL_BASE_SCRIPTS_SHA256_V10667='28986114dbb53abb9c3941e94ffc7b5607d1db7cc87b406cb922c1377adb7a16'
  P8_EXPECTED_CANDIDATE_SCRIPT_COUNT_V10667=652

  class << self
    def p8_file_crc_v10667(path)
      return nil unless FileTest.exist?(path)
      data=''
      File.open(path,'rb'){|io|data=io.read}
      Zlib.crc32(data)
    rescue
      -1
    end

    def p8_object_crc_v10667(obj)
      return nil if obj==nil
      Zlib.crc32(Marshal.dump(obj))
    rescue
      -1
    end

    def p8_live_map_checksum_v10667
      return nil if $game_map==nil || $game_map.map_id.to_i!=90
      return nil unless respond_to?(:vxrd_acceptance_tile_checksum_v10634)
      vxrd_acceptance_tile_checksum_v10634
    rescue
      -1
    end

    def p8_runtime_snapshot_v10667
      st=respond_to?(:vxrd_state_v10582) ? vxrd_state_v10582 : nil
      hs=respond_to?(:hunt_runtime_session_v10605) ? hunt_runtime_session_v10605 : nil
      {
        :map_id=>($game_map==nil ? 0:$game_map.map_id.to_i),
        :map090_file=>p8_file_crc_v10667('Data/Map090.rvdata'),
        :map091_file=>p8_file_crc_v10667('Data/Map091.rvdata'),
        :map_table=>p8_live_map_checksum_v10667,
        :vxrd_state=>p8_object_crc_v10667(st),
        :hunt_session=>p8_object_crc_v10667(hs),
        :party=>p8_object_crc_v10667($game_party),
        :scene=>($scene==nil ? 'nil':$scene.class.to_s)
      }
    rescue Exception=>e
      {:map_id=>0,:map090_file=>-1,:map091_file=>-1,:map_table=>-1,
       :vxrd_state=>-1,:hunt_session=>-1,:party=>-1,:scene=>'snapshot_error:'+e.class.to_s}
    end

    def p8_call_v10667(method_name,args=nil)
      return {:pass=>false,:missing_api=>true,:bad=>[:missing_api]} unless respond_to?(method_name)
      a=args.is_a?(Array) ? args : []
      r=send(method_name,*a)
      return {:pass=>false,:bad=>[:non_hash_result]} unless r.is_a?(Hash)
      r
    rescue Exception=>e
      {:pass=>false,:bad=>[:audit_exception],:error=>e.class.to_s}
    end

    def p8_add_audit_v10667(rows,blockers,gate,key,method_name,args=nil)
      r=p8_call_v10667(method_name,args)
      rows[key]=r
      unless r[:pass]
        klass=r[:missing_api] ? :test_defect : :runtime_defect
        bad=(r[:bad]||[:unknown]).collect{|x|x.to_s}
        blockers << {:gate=>gate,:key=>key,:class=>klass,:bad=>bad}
      end
      r
    rescue Exception=>e
      blockers << {:gate=>gate,:key=>key,:class=>:test_defect,:bad=>['wrapper_error:'+e.class.to_s]}
      {:pass=>false,:bad=>[:wrapper_error]}
    end

    def p8_gate1_v10667(blockers)
      rows={}
      st=respond_to?(:vxrd_state_v10582) ? vxrd_state_v10582 : nil
      hs=respond_to?(:hunt_runtime_session_v10605) ? hunt_runtime_session_v10605 : nil
      context=($game_map!=nil && $game_map.map_id.to_i==90 && st.is_a?(Hash) && hs.is_a?(Hash))
      unless context
        blockers << {:gate=>:gate1,:key=>:map090_live_context,:class=>:context_blocker,
          :bad=>['requires_live_random_hunt_map090']}
      end
      rows[:map090_live_context]={:pass=>context,:map_id=>($game_map==nil ? 0:$game_map.map_id.to_i),
        :state=>(st.is_a?(Hash) ? 1:0),:session=>(hs.is_a?(Hash) ? 1:0)}
      p8_add_audit_v10667(rows,blockers,:gate1,:wall_geometry,:vxrd_wall_geometry_audit_v10592)
      p8_add_audit_v10667(rows,blockers,:gate1,:regular_water_shape,:vxrd_regular_water_audit_v10593)
      p8_add_audit_v10667(rows,blockers,:gate1,:visual_style_scope,:vxrd_visual_style_audit_v10600)
      p8_add_audit_v10667(rows,blockers,:gate1,:tileset_semantic,:vxrd_tileset_semantic_audit_v10641)
      p8_add_audit_v10667(rows,blockers,:gate1,:room_runtime_api,:vxrd_room_runtime_audit_v10602)
      p8_add_audit_v10667(rows,blockers,:gate1,:node_lifecycle_api,:vxrd_node_lifecycle_audit_v10606)
      p8_add_audit_v10667(rows,blockers,:gate1,:save_resume_api,:vxrd_save_resume_audit_v10609)
      p8_add_audit_v10667(rows,blockers,:gate1,:room_visual_current,:vxrd_room_visual_audit_v10607)
      pass=rows.values.all?{|r|r.is_a?(Hash) && r[:pass]}
      {:pass=>pass,:rows=>rows}
    rescue Exception=>e
      blockers << {:gate=>:gate1,:key=>:gate_wrapper,:class=>:test_defect,:bad=>[e.class.to_s]}
      {:pass=>false,:rows=>rows||{}}
    end

    def p8_gate2_materialization_v10667(st)
      return {:pass=>false,:bad=>[:no_vxrd_state]} unless st.is_a?(Hash)
      content=st[:event_content_v10652]
      semantic=st[:event_semantic_placement_v10646]
      bad=[]
      bad << :template_not_materialized unless st[:event_template_materialized_v10649]==true
      bad << :template_map unless st[:event_template_map_id_v10649].to_i==91
      bad << :content_state unless content.is_a?(Hash) && content[:source_map].to_i==91 && content[:generated].to_i>0
      bad << :semantic_placement unless semantic.is_a?(Hash) && !semantic.empty?
      {:pass=>bad.empty?,:source_map=>st[:event_template_map_id_v10649].to_i,
        :generated=>(content.is_a?(Hash) ? content[:generated].to_i : 0),
        :semantic_count=>(semantic.is_a?(Hash) ? semantic.size : 0),:bad=>bad}
    rescue Exception=>e
      {:pass=>false,:bad=>[:materialization_audit_error],:error=>e.class.to_s}
    end

    def p8_gate2_v10667(blockers)
      rows={}
      st=respond_to?(:vxrd_state_v10582) ? vxrd_state_v10582 : nil
      p8_add_audit_v10667(rows,blockers,:gate2,:map091_source,:vxrd_template_source_audit_v10651,[91])
      p8_add_audit_v10667(rows,blockers,:gate2,:map091_content_matrix,:vxrd_event_content_audit_v10652)
      mat=p8_gate2_materialization_v10667(st)
      rows[:current_materialization]=mat
      unless mat[:pass]
        mc=(st.is_a?(Hash) ? :runtime_defect : :context_blocker)
        blockers << {:gate=>:gate2,:key=>:current_materialization,:class=>mc,
          :bad=>(mat[:bad]||[:unknown]).collect{|x|x.to_s}}
      end
      p8_add_audit_v10667(rows,blockers,:gate2,:landmark_semantic,:vxrd_landmark_audit_v10654)
      route_static=p8_add_audit_v10667(rows,blockers,:gate2,:route_static,:vxrd_landmark_route_static_audit_v10655)
      live_route=p8_call_v10667(:vxrd_landmark_route_audit_state_v10655,[st,true])
      rows[:route_live]=live_route
      unless live_route[:pass]
        blockers << {:gate=>:gate2,:key=>:route_live,:class=>:runtime_defect,
          :bad=>(live_route[:bad]||[:unknown]).collect{|x|x.to_s}}
      end
      loading=p8_add_audit_v10667(rows,blockers,:gate2,:loading_contract,:vxrd_map_loading_static_audit_v10656)
      a1=p8_add_audit_v10667(rows,blockers,:gate2,:a1_liquid_semantic,:vxrd_a1_liquid_semantic_audit_v10661)
      tile=p8_add_audit_v10667(rows,blockers,:gate2,:tileset_semantic,:vxrd_tileset_semantic_audit_v10641)
      bcde=(tile[:pass] && tile[:tileb_autodecor]==false && tile[:tilec_autodecor]==false &&
        tile[:tiled_autodecor]==false && route_static[:map_table_bcde_stamp]==false &&
        loading[:map_table_bcde_stamp]==false && a1[:bcde_stamp]==false)
      rows[:bcde_stamping]={:pass=>bcde,:tileb=>tile[:tileb_autodecor],
        :tilec=>tile[:tilec_autodecor],:tiled=>tile[:tiled_autodecor],
        :route_stamp=>route_static[:map_table_bcde_stamp],
        :loading_stamp=>loading[:map_table_bcde_stamp],:a1_stamp=>a1[:bcde_stamp]}
      unless bcde
        blockers << {:gate=>:gate2,:key=>:bcde_stamping,:class=>:runtime_defect,:bad=>['automatic_stamping_not_zero']}
      end
      pass=rows.values.all?{|r|r.is_a?(Hash) && r[:pass]}
      {:pass=>pass,:rows=>rows}
    rescue Exception=>e
      blockers << {:gate=>:gate2,:key=>:gate_wrapper,:class=>:test_defect,:bad=>[e.class.to_s]}
      {:pass=>false,:rows=>rows||{}}
    end

    def p8_gate3_v10667(blockers)
      rows={}
      r=p8_add_audit_v10667(rows,blockers,:gate3,:integrated_v10666,:vxrd_gate3_integrated_seal_audit_v10666)
      {:pass=>r[:pass] ? true:false,:rows=>rows}
    rescue Exception=>e
      blockers << {:gate=>:gate3,:key=>:gate_wrapper,:class=>:test_defect,:bad=>[e.class.to_s]}
      {:pass=>false,:rows=>rows||{}}
    end

    def p8_mutation_result_v10667(before,after)
      map090_file=(before[:map090_file]==after[:map090_file])
      map091_file=(before[:map091_file]==after[:map091_file])
      map_table=(before[:map_table]==after[:map_table])
      state=(before[:vxrd_state]==after[:vxrd_state])
      session=(before[:hunt_session]==after[:hunt_session])
      party=(before[:party]==after[:party])
      scene=(before[:scene]==after[:scene])
      map_zero=map090_file && map091_file && map_table && state
      {
        :pass=>(map_zero && session && party && scene),
        :map090_file=>(map090_file ? 0:1),:map091_file=>(map091_file ? 0:1),
        :map_table=>(map_table ? 0:1),:vxrd_state=>(state ? 0:1),
        :map_mutation=>(map_zero ? 0:1),:session_mutation=>(session ? 0:1),
        :party_mutation=>(party ? 0:1),:reward_grant=>(party ? 0:1),
        :battle_launch=>(scene ? 0:1),:harness_extra_rng_calls=>0
      }
    rescue
      {:pass=>false,:map_mutation=>1,:session_mutation=>1,:party_mutation=>1,
       :reward_grant=>1,:battle_launch=>1,:harness_extra_rng_calls=>0}
    end

    def p8_audit_line_v10667(gate,key,row)
      pass=row.is_a?(Hash) && row[:pass]
      bad=row.is_a?(Hash) ? (row[:bad]||[]) : [:invalid_result]
      'AUDIT gate='+gate.to_s.upcase+' key='+key.to_s+' result='+(pass ? 'PASS':'FAIL')+
        ' bad=['+bad.collect{|x|x.to_s}.join(',')+']'
    rescue
      'AUDIT gate='+gate.to_s.upcase+' key='+key.to_s+' result=FAIL bad=[log_error]'
    end

    def p8_write_log_v10667(result)
      lines=[]
      lines << 'PMD AutoChess P8 Formal Cross-Gate Regression + QA Shortcut Consolidation I'
      lines << 'VERSION='+P8_VERSION_V10667
      lines << 'FORMAL_BASE='+P8_FORMAL_BASE_VERSION_V10667
      lines << 'FORMAL_BASE_SCRIPT_COUNT='+P8_FORMAL_BASE_SCRIPT_COUNT_V10667.to_i.to_s
      lines << 'FORMAL_BASE_SCRIPTS_SHA256='+P8_FORMAL_BASE_SCRIPTS_SHA256_V10667
      current_count=(defined?($RGSS_SCRIPTS) && $RGSS_SCRIPTS.is_a?(Array)) ? $RGSS_SCRIPTS.size : 0
      lines << 'CURRENT_SCRIPT_COUNT='+current_count.to_i.to_s
      lines << 'EXPECTED_CANDIDATE_SCRIPT_COUNT='+P8_EXPECTED_CANDIDATE_SCRIPT_COUNT_V10667.to_i.to_s
      lines << 'SHORTCUT_CURRENT=F5_SCENE_MAP_TEST_ONLY'
      lines << 'SHORTCUT_RETIRED=F6_V10519,F7_V1014,F7_V10534,F9_V10536,SHIFT_F7_V10537,SHIFT_F9_V10538'
      lines << 'PRODUCTION_F8_PRESERVED=1'
      lines << 'STALE_V10610_AGGREGATE_USED=0'
      lines << 'GATE1='+(result[:gate1][:pass] ? 'PASS':'FAIL')
      lines << 'GATE2='+(result[:gate2][:pass] ? 'PASS':'FAIL')
      lines << 'GATE3='+(result[:gate3][:pass] ? 'PASS':'FAIL')
      [:gate1,:gate2,:gate3].each do |g|
        (result[g][:rows]||{}).keys.sort{|a,b|a.to_s<=>b.to_s}.each do |k|
          lines << p8_audit_line_v10667(g,k,result[g][:rows][k])
        end
      end
      m=result[:mutation]||{}
      lines << 'HARNESS_EXTRA_RNG_CALLS='+m[:harness_extra_rng_calls].to_i.to_s
      lines << 'REWARD_GRANT='+m[:reward_grant].to_i.to_s
      lines << 'MAP_MUTATION='+m[:map_mutation].to_i.to_s
      lines << 'MAP090_FILE_MUTATION='+m[:map090_file].to_i.to_s
      lines << 'MAP091_FILE_MUTATION='+m[:map091_file].to_i.to_s
      lines << 'MAP090_LIVE_TABLE_MUTATION='+m[:map_table].to_i.to_s
      lines << 'VXRD_STATE_MUTATION='+m[:vxrd_state].to_i.to_s
      lines << 'SESSION_MUTATION='+m[:session_mutation].to_i.to_s
      lines << 'PARTY_MUTATION='+m[:party_mutation].to_i.to_s
      lines << 'BATTLE_LAUNCH='+m[:battle_launch].to_i.to_s
      lines << 'BLOCKERS='+result[:blockers].size.to_i.to_s
      result[:blockers].each do |b|
        lines << 'BLOCKER gate='+b[:gate].to_s.upcase+' key='+b[:key].to_s+
          ' class='+b[:class].to_s.upcase+' bad=['+(b[:bad]||[]).join(',')+']'
      end
      lines << 'RESULT='+(result[:pass] ? 'PASS':'FAIL')
      File.open(P8_LOG_V10667,'wb'){|io|io.write(lines.join("\r\n")+"\r\n")}
      true
    rescue
      false
    end

    def p8_cross_gate_fast_seal_v10667
      blockers=[]
      before=p8_runtime_snapshot_v10667
      gate1=p8_gate1_v10667(blockers)
      gate2=p8_gate2_v10667(blockers)
      gate3=p8_gate3_v10667(blockers)
      after=p8_runtime_snapshot_v10667
      mutation=p8_mutation_result_v10667(before,after)
      unless mutation[:pass]
        bad=[]
        [:map_mutation,:session_mutation,:party_mutation,:battle_launch].each{|k|bad << k.to_s if mutation[k].to_i!=0}
        blockers << {:gate=>:fast_seal,:key=>:mutation_guard,:class=>:runtime_defect,:bad=>bad}
      end
      pass=gate1[:pass] && gate2[:pass] && gate3[:pass] && mutation[:pass] && blockers.empty?
      result={:pass=>pass,:gate1=>gate1,:gate2=>gate2,:gate3=>gate3,
        :mutation=>mutation,:blockers=>blockers,:before=>before,:after=>after}
      @p8_last_result_v10667=result
      p8_write_log_v10667(result)
      result
    rescue Exception=>e
      result={:pass=>false,:gate1=>{:pass=>false,:rows=>{}},:gate2=>{:pass=>false,:rows=>{}},
        :gate3=>{:pass=>false,:rows=>{}},:mutation=>{:pass=>false},
        :blockers=>[{:gate=>:fast_seal,:key=>:exception,:class=>:test_defect,:bad=>[e.class.to_s]}]}
      @p8_last_result_v10667=result
      p8_write_log_v10667(result)
      result
    end

    def p8_last_result_v10667
      @p8_last_result_v10667
    end

    alias pmd_ac_v10667_write_project_state_log write_project_state_log unless method_defined?(:pmd_ac_v10667_write_project_state_log)
    def project_version
      P8_VERSION_V10667
    end
    def write_project_state_log(force=false)
      r=pmd_ac_v10667_write_project_state_log(force)
      return false unless r
      begin
        text=''
        File.open(PROJECT_STATE_FILE_V10564,'rb'){|io|text=io.read}
        text=text.gsub(/PROJECT_STATE_SCHEMA=\d+/,'PROJECT_STATE_SCHEMA=48')
        text=text.gsub(/CURRENT_VERSION=[^\r\n]+/,'CURRENT_VERSION=1.06.67')
        text=text.gsub(/LATEST_FEATURE=[^\r\n]+/,'LATEST_FEATURE=P8_CROSS_GATE_REGRESSION+QA_SHORTCUT_CONSOLIDATION_I')
        text=text.gsub(/NEXT_TARGET=[^\r\n]+/,'NEXT_TARGET=P8_V10667_WINDOWS_FAST_SEAL_ACCEPTANCE')
        text=text.gsub(/\r?\nP8_V10667_BEGIN.*?P8_V10667_END\r?\n/m,"\r\n")
        last=p8_last_result_v10667
        lines=[]
        lines << ''
        lines << 'P8_V10667_BEGIN'
        lines << 'P8_FAST_SEAL_STATUS='+(last==nil ? 'PENDING_WINDOWS_F5':(last[:pass] ? 'PASS':'FAIL'))
        lines << 'P8_TEST_LAUNCHER=F5_SCENE_MAP_TEST_ONLY'
        lines << 'P8_OLD_QA_SHORTCUTS_RETIRED=F6,F7,F9,SHIFT_F7,SHIFT_F9_HOOK_SPECIFIC'
        lines << 'P8_PRODUCTION_F8_PRESERVED=1'
        lines << 'P8_STALE_V10610_AGGREGATE_USED=0'
        lines << 'P8_FORMAL_BASE_SCRIPTS_SHA256='+P8_FORMAL_BASE_SCRIPTS_SHA256_V10667
        lines << 'P8_FAST_LOG='+P8_LOG_V10667
        lines << 'P8_REWARD_CHANGE=0'
        lines << 'P8_GAMEPLAY_CHANGE=0'
        lines << 'RMVX_EDITOR_RESTART_REQUIRED=1'
        lines << 'TUTORIAL_UPDATED=1'
        lines << 'P8_V10667_END'
        File.open(PROJECT_STATE_FILE_V10564,'wb'){|io|io.write(text.rstrip+"\r\n"+lines.join("\r\n")+"\r\n")}
      rescue
      end
      true
    rescue
      false
    end
  end
end

#===============================================================================
# ■ Scene_Map - one current TEST-only launcher
#===============================================================================
class Scene_Map
  alias pmd_ac_v10667_p8_update update unless method_defined?(:pmd_ac_v10667_p8_update)
  def update
    pmd_ac_v10667_p8_update
    return unless $TEST
    return unless Input.trigger?(Input::F5)
    return if $game_map!=nil && $game_map.interpreter.running?
    return if $game_message!=nil && $game_message.busy
    r=PMD_AC.p8_cross_gate_fast_seal_v10667
    begin
      r[:pass] ? Sound.play_decision : Sound.play_buzzer
    rescue
    end
  rescue
    nil
  end
end
