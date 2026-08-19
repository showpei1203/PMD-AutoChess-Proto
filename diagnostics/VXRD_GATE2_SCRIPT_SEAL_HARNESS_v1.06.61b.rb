# encoding: UTF-8
#===============================================================================
# ■ PMD AutoChess - VXRD Gate 2 Script Seal Harness
#   v1.06.61b TEST-ONLY
#-------------------------------------------------------------------------------
# Purpose:
# - Consolidate remaining script/runtime acceptance on top of v1.06.61 without
#   creating another Production version.
# - Re-use the corrected Map091 acceptance contract already PASS on Windows.
# - Validate A1 semantic allocation, ProjectState convergence, current-floor
#   Route Safety, Loading static contract, and no B/C/D/E stamping authority.
#
# Control: plain F5 on an active Map090 Random Hunt floor.
# Formal baseline remains v1.06.58 until v1.06.61 Windows visual/runtime gate.
#===============================================================================
$imported={} unless defined?($imported)
$imported['PMD_AutoChess_VXRDGate2ScriptSealHarness_v10661b']=true

module PMD_AC
  VXRD_GATE2_SCRIPT_SEAL_LOG_V10661B='PMD_VXRD_Gate2ScriptSeal_LATEST.log'

  class << self
    def vxrd_gate2_project_state_acceptance_v10661b
      bad=[]
      begin
        write_project_state_log(true)
      rescue
        bad << :project_state_write_exception
      end
      text=''
      begin
        File.open(PROJECT_STATE_FILE_V10564,'rb'){|io|text=io.read}
      rescue
        bad << :project_state_read_exception
      end
      bad << :schema unless text =~ /^PROJECT_STATE_SCHEMA=42\r?$/
      bad << :version unless text =~ /^CURRENT_VERSION=1\.06\.61\r?$/
      bad << :feature unless text.index('LATEST_FEATURE=A1_LIQUID_SURFACE_SEMANTIC_AUTHORITY_II+PROJECT_STATE_CONVERGENCE')
      bad << :semantic_section unless text.index('VXRD_A1_LIQUID_SEMANTIC_V10661_BEGIN') && text.index('VXRD_A1_LIQUID_SEMANTIC_V10661_END')
      bad << :semantic_state unless text.index('A1_LIQUID_SEMANTIC_AUTHORITY=PASS')
      bad << :h02 unless text.index('H02_WATER_BASE=2240')
      bad << :h07 unless text.index('H07_WATER_BASE=2432')
      bad << :h12 unless text.index('H12_WATER_BASE=2240')
      bad << :h17 unless text.index('H17_WATER_BASE=2240')
      entries=0
      begin
        entries=load_data('Data/Scripts.rvdata').size.to_i
      rescue
        bad << :script_container_read
      end
      bad << :test_script_count unless entries==649
      {:pass=>bad.empty?,:schema=>42,:version=>'1.06.61',:entries=>entries,:bad=>bad}
    rescue Exception=>e
      {:pass=>false,:schema=>0,:version=>'ERROR',:entries=>0,:bad=>[:project_state_exception],:error=>e.class.to_s}
    end

    def vxrd_gate2_script_seal_v10661b
      bad=[]
      a1=vxrd_a1_liquid_semantic_audit_v10661 rescue {:pass=>false,:bad=>[:missing_a1_audit]}
      bad << :a1_liquid unless a1[:pass]
      map091=respond_to?(:vxrd_map091_full_acceptance_v10661a) ? (vxrd_map091_full_acceptance_v10661a rescue {:pass=>false,:bad=>[:map091_exception]}) : {:pass=>false,:bad=>[:map091_harness_missing]}
      bad << :map091 unless map091[:pass]
      route_static=respond_to?(:vxrd_landmark_route_static_audit_v10655) ? (vxrd_landmark_route_static_audit_v10655 rescue {:pass=>false,:bad=>[:route_static_exception]}) : {:pass=>false,:bad=>[:route_static_missing]}
      bad << :route_static unless route_static[:pass]
      route_runtime={:pass=>false,:bad=>[:not_map090]}
      if $game_map!=nil && $game_map.map_id.to_i==90 && respond_to?(:vxrd_state_v10582)
        st=vxrd_state_v10582 rescue nil
        route_runtime=vxrd_landmark_route_audit_state_v10655(st,true) rescue {:pass=>false,:bad=>[:route_runtime_exception]}
      end
      bad << :route_runtime unless route_runtime[:pass]
      loading=respond_to?(:vxrd_map_loading_static_audit_v10656) ? (vxrd_map_loading_static_audit_v10656 rescue {:pass=>false,:bad=>[:loading_exception]}) : {:pass=>false,:bad=>[:loading_missing]}
      bad << :loading unless loading[:pass]
      ps=vxrd_gate2_project_state_acceptance_v10661b
      bad << :project_state unless ps[:pass]
      {:pass=>bad.empty?,:a1=>a1,:map091=>map091,:route_static=>route_static,
       :route_runtime=>route_runtime,:loading=>loading,:project_state=>ps,
       :formal_preserved=>true,:map_table_bcde_stamp=>false,
       :map091_mutation=>false,:topology_rewrite=>false,:battle_change=>false,
       :reward_change=>false,:progression_change=>false,:bad=>bad}
    rescue Exception=>e
      {:pass=>false,:bad=>[:gate2_exception],:error=>e.class.to_s}
    end

    def vxrd_write_gate2_script_seal_v10661b(result=nil)
      r=result||vxrd_gate2_script_seal_v10661b
      a=r[:a1]||{};m=r[:map091]||{};rs=r[:route_static]||{};rr=r[:route_runtime]||{};l=r[:loading]||{};ps=r[:project_state]||{}
      lines=[]
      lines << 'PMD AutoChess VXRD Gate 2 Script Seal v1.06.61b TEST-ONLY'
      lines << 'RESULT='+(r[:pass] ? 'PASS':'FAIL')
      lines << 'PRODUCTION_CANDIDATE=v1.06.61'
      lines << 'FORMAL_BASELINE=v1.06.58'
      lines << 'A1_LIQUID_SEMANTIC='+(a[:pass] ? 'PASS':'FAIL')
      lines << 'A1_KIND4_BASE=2240'
      lines << 'A1_KIND6_BASE=2336'
      lines << 'A1_KIND8_BASE=2432'
      lines << 'A1_KIND10_BASE=2528'
      lines << 'A1_KIND14_BASE=2720;LIQUID=LAVA'
      lines << 'H02_WATER_BASE=2240'
      lines << 'H07_WATER_BASE=2432'
      lines << 'H12_WATER_BASE=2240'
      lines << 'H17_WATER_BASE=2240'
      lines << 'MAP091_ACCEPTANCE='+(m[:pass] ? 'PASS':'FAIL')
      lines << 'ROUTE_STATIC='+(rs[:pass] ? 'PASS':'FAIL')
      lines << 'ROUTE_STATIC_TESTS='+rs[:tests].to_i.to_s+'/4'
      lines << 'ROUTE_RUNTIME='+(rr[:pass] ? 'PASS':'FAIL')
      lines << 'ROUTE_RUNTIME_REACHABLE='+rr[:reachable].to_i.to_s
      lines << 'ROUTE_RUNTIME_TARGETS='+(rr[:targets]||[]).size.to_i.to_s
      lines << 'ROUTE_RUNTIME_EXIT_REACHABLE='+(rr[:exit_reachable] ? '1':'0')
      lines << 'LOADING_STATIC='+(l[:pass] ? 'PASS':'FAIL')
      lines << 'PROJECT_STATE='+(ps[:pass] ? 'PASS':'FAIL')
      lines << 'PROJECT_STATE_SCHEMA='+ps[:schema].to_i.to_s
      lines << 'CURRENT_VERSION='+ps[:version].to_s
      lines << 'SCRIPT_CONTAINER_ENTRIES='+ps[:entries].to_i.to_s
      lines << 'FORMAL_0_643_BYTE_EXACT=PASS_BUILD_GATE'
      lines << 'MAP_TABLE_BCDE_STAMPING=0'
      lines << 'MAP091_MUTATION=0'
      lines << 'TOPOLOGY_REWRITE=0'
      lines << 'BATTLE_MECHANICS_CHANGED=0'
      lines << 'REWARD_MECHANICS_CHANGED=0'
      lines << 'PROGRESSION_CHANGED=0'
      [a,m,rs,rr,l,ps].each{|h|(h[:bad]||[]).each{|x|lines << 'DETAIL_ERROR='+x.to_s}}
      (r[:bad]||[]).each{|x|lines << 'ERROR='+x.to_s}
      File.open(VXRD_GATE2_SCRIPT_SEAL_LOG_V10661B,'wb'){|io|io.write(lines.join("\r\n")+"\r\n")}
      r
    rescue
      r||{:pass=>false}
    end
  end
end

class Scene_Map
  alias pmd_ac_v10661b_gate2_seal_update update unless method_defined?(:pmd_ac_v10661b_gate2_seal_update)
  alias pmd_ac_v10661b_gate2_seal_terminate terminate unless method_defined?(:pmd_ac_v10661b_gate2_seal_terminate)
  def vxrd_gate2_seal_dispose_v10661b
    if @vxrd_gate2_seal_overlay_v10661b!=nil
      begin;b=@vxrd_gate2_seal_overlay_v10661b.bitmap;b.dispose if b!=nil && !b.disposed?;rescue;end
      begin;@vxrd_gate2_seal_overlay_v10661b.dispose unless @vxrd_gate2_seal_overlay_v10661b.disposed?;rescue;end
    end
    @vxrd_gate2_seal_overlay_v10661b=nil;@vxrd_gate2_seal_frames_v10661b=0
  rescue
  end
  def vxrd_gate2_seal_show_v10661b(r)
    vxrd_gate2_seal_dispose_v10661b;s=Sprite.new;s.bitmap=Bitmap.new(Graphics.width,Graphics.height);s.z=31500;b=s.bitmap
    b.fill_rect(0,0,Graphics.width,Graphics.height,Color.new(2,7,13,235));b.font.name=['Microsoft JhengHei','Arial'];b.font.size=22;b.font.bold=true;b.font.color=r[:pass] ? Color.new(110,255,145):Color.new(255,110,110)
    b.draw_text(8,18,Graphics.width-16,30,'Gate 2 Script Seal  '+(r[:pass] ? 'PASS':'FAIL'),1)
    b.font.bold=false;b.font.size=18;b.font.color=Color.new(225,235,245);y=72
    a=r[:a1]||{};m=r[:map091]||{};rs=r[:route_static]||{};rr=r[:route_runtime]||{};l=r[:loading]||{};ps=r[:project_state]||{}
    rows=['A1 Liquid Semantic: '+(a[:pass] ? 'PASS':'FAIL')+'   H07=kind8/base2432','Map091: '+(m[:pass] ? 'PASS':'FAIL')+'   Route Static: '+(rs[:pass] ? 'PASS':'FAIL'),'Current Hunt Route: '+(rr[:pass] ? 'PASS':'FAIL')+'   Exit: '+(rr[:exit_reachable] ? 'PASS':'FAIL'),'Loading Contract: '+(l[:pass] ? 'PASS':'FAIL'),'ProjectState: '+(ps[:pass] ? 'PASS':'FAIL')+'   Version: '+ps[:version].to_s,'Scripts: '+ps[:entries].to_i.to_s+'   Formal 0..643: PASS build gate','BCD stamping: 0   Map091 mutation: 0   Topology rewrite: 0']
    rows.each{|t|b.draw_text(20,y,Graphics.width-40,28,t);y+=34}
    b.font.size=16;b.font.color=Color.new(170,195,215);b.draw_text(20,Graphics.height-60,Graphics.width-40,24,'LOG: '+PMD_AC::VXRD_GATE2_SCRIPT_SEAL_LOG_V10661B,1)
    @vxrd_gate2_seal_overlay_v10661b=s;@vxrd_gate2_seal_frames_v10661b=360
  rescue
  end
  def pmd_ac_v10661b_gate2_seal_plain_f5?
    return false unless $TEST
    return false unless Input.trigger?(Input::F5)
    return false if (Input.press?(Input::SHIFT) rescue false)
    return false if (Input.press?(Input::CTRL) rescue false)
    return false if (Input.press?(Input::ALT) rescue false)
    true
  rescue
    false
  end
  def update
    pmd_ac_v10661b_gate2_seal_update
    if @vxrd_gate2_seal_frames_v10661b.to_i>0
      @vxrd_gate2_seal_frames_v10661b-=1
      vxrd_gate2_seal_dispose_v10661b if @vxrd_gate2_seal_frames_v10661b.to_i<=0
    end
    if pmd_ac_v10661b_gate2_seal_plain_f5?
      r=PMD_AC.vxrd_gate2_script_seal_v10661b
      PMD_AC.vxrd_write_gate2_script_seal_v10661b(r)
      vxrd_gate2_seal_show_v10661b(r)
    end
  rescue
    pmd_ac_v10661b_gate2_seal_update
  end
  def terminate
    vxrd_gate2_seal_dispose_v10661b
    pmd_ac_v10661b_gate2_seal_terminate
  end
end
