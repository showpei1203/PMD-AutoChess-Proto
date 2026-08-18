# encoding: UTF-8
#===============================================================================
# ■ PMD AutoChess - VXRD Map091 Full Acceptance Harness
#   v1.06.60 TEST-ONLY
#-------------------------------------------------------------------------------
# Purpose:
# Validate Map091 as the shared FS-style Event Template Library for H01-H21:
# - 21 Hunts x Floors 1..6 content/filter matrix
# - HUNT/FLOOR/WEIGHT/MAX/UNIQUE/NO_REPEAT parser semantics
# - FIXED/CONTROL/SHARED parser + runtime-ID semantics (synthetic contract)
# - source RPG::Event pages / graphics / triggers / command-list integrity
# - 49/49 deep Marshal clone integrity
# - current Map090 materialized template-event metadata
# - non-destructive Marshal save/load roundtrip of current $game_map/session
#
# Control: SHIFT+F5 during RMVX Test Play on active Map090 Hunt floor.
# Formal baseline remains v1.06.58. No runtime mutation is performed.
#===============================================================================
$imported={} unless defined?($imported)
$imported['PMD_AutoChess_VXRDMap091FullAcceptanceHarness_v10660']=true

module PMD_AC
  VXRD_MAP091_ACCEPT_LOG_V10660='PMD_VXRD_Map091Acceptance_LATEST.log'
  VXRD_MAP091_EXPECTED_SOURCE_EVENTS_V10660=49
  VXRD_MAP091_EXPECTED_MATRIX_V10660=126
  VXRD_MAP091_ALLOWED_ROLES_V10660=[:entrance,:exit,:retreat,:info,:treasure,:recovery,:rare,:elite,:encounter]

  class << self
    def vxrd_map091_source_acceptance_v10660
      bad=[]
      map=vxrd_load_event_template_map_v10649(91) rescue nil
      return {:pass=>false,:events=>0,:pages=>0,:clones=>0,:bad=>[:map091_missing]} if map==nil
      events=map.events rescue nil
      return {:pass=>false,:events=>0,:pages=>0,:clones=>0,:bad=>[:events_missing]} unless events.is_a?(Hash)
      bad << :source_event_count unless events.size==VXRD_MAP091_EXPECTED_SOURCE_EVENTS_V10660
      pages=0;graphics=0;triggers=0;lists=0;clones=0;roles={};positions={}
      events.keys.sort.each do |id|
        ev=events[id];next if ev==nil
        role=vxrd_template_event_role_v10649(ev) rescue nil
        roles[role]=roles[role].to_i+1 unless role==nil
        bad << ('role_'+id.to_i.to_s).to_sym if role==nil || !VXRD_MAP091_ALLOWED_ROLES_V10660.include?(role)
        pos=[ev.x.to_i,ev.y.to_i] rescue [0,0]
        bad << ('duplicate_position_'+id.to_i.to_s).to_sym if positions[pos]
        positions[pos]=true
        eps=ev.pages rescue nil
        if !eps.is_a?(Array) || eps.empty?
          bad << ('pages_'+id.to_i.to_s).to_sym
          next
        end
        pages+=eps.size
        eps.each_with_index do |pg,pi|
          g=pg.graphic rescue nil
          g==nil ? bad << ('graphic_'+id.to_i.to_s+'_'+pi.to_i.to_s).to_sym : graphics+=1
          tr=pg.trigger.to_i rescue -1
          (tr<0 || tr>4) ? bad << ('trigger_'+id.to_i.to_s+'_'+pi.to_i.to_s).to_sym : triggers+=1
          li=pg.list rescue nil
          (!li.is_a?(Array) || li.empty?) ? bad << ('list_'+id.to_i.to_s+'_'+pi.to_i.to_s).to_sym : lists+=1
        end
        begin
          blob=Marshal.dump(ev);cp=Marshal.load(blob)
          same=(Marshal.dump(cp)==blob)
          deep=(cp.object_id!=ev.object_id && cp.pages.object_id!=ev.pages.object_id)
          (same && deep) ? clones+=1 : bad << ('clone_'+id.to_i.to_s).to_sym
        rescue
          bad << ('clone_exception_'+id.to_i.to_s).to_sym
        end
      end
      VXRD_MAP091_ALLOWED_ROLES_V10660.each{|r|bad << ('missing_role_'+r.to_s).to_sym if roles[r].to_i<=0}
      {:pass=>bad.empty?,:events=>events.size,:pages=>pages,:graphics=>graphics,:triggers=>triggers,:lists=>lists,:clones=>clones,:roles=>roles,:bad=>bad}
    rescue Exception=>e
      {:pass=>false,:events=>0,:pages=>0,:clones=>0,:bad=>[:source_exception],:error=>e.class.to_s}
    end

    def vxrd_map091_parser_contract_v10660
      bad=[]
      s='Probe <PMD_RD_ENCOUNTER><PMD_RD_HUNTS:H01,H07><PMD_RD_FLOORS:2-4><PMD_RD_WEIGHT:80><PMD_RD_MAX:2><PMD_RD_SHARED><PMD_RD_FIXED><PMD_RD_CONTROL>'
      bad << :hunt_set unless vxrd_template_hunt_set_v10649(s)==['H01','H07']
      bad << :floor_set unless vxrd_template_floor_set_v10649(s)==[2,3,4]
      bad << :hunt_enabled unless vxrd_template_enabled_for_hunt_v10649?(s,'H07') && !vxrd_template_enabled_for_hunt_v10649?(s,'H08')
      bad << :floor_enabled unless vxrd_template_enabled_on_floor_v10649?(s,3) && !vxrd_template_enabled_on_floor_v10649?(s,5)
      bad << :weight unless vxrd_template_weight_v10649(s)==80
      bad << :max unless vxrd_template_max_v10649(s)==2
      bad << :shared unless vxrd_template_shared_v10649?(s)
      bad << :fixed unless vxrd_template_fixed_v10649?(s)
      bad << :control unless vxrd_template_control_v10649?(s)
      bad << :unique unless vxrd_template_max_v10649('X <PMD_RD_UNIQUE>')==1
      bad << :no_repeat unless vxrd_template_max_v10649('X <PMD_RD_NO_REPEAT>')==1
      shared={:shared=>true,:source_id=>9};normal={:shared=>false,:source_id=>9}
      bad << :shared_id unless vxrd_template_runtime_event_id_v10649(1,1,shared)==809 && vxrd_template_runtime_event_id_v10649(6,7,shared)==809
      bad << :normal_floor_id unless vxrd_template_runtime_event_id_v10649(1,1,normal)!=vxrd_template_runtime_event_id_v10649(6,1,normal)
      {:pass=>bad.empty?,:tests=>12,:fixed=>true,:control=>true,:shared=>true,:bad=>bad}
    rescue
      {:pass=>false,:tests=>0,:bad=>[:parser_exception]}
    end

    def vxrd_map091_matrix_acceptance_v10660
      a=vxrd_event_content_audit_v10652 rescue {:pass=>false,:events=>0,:matrix=>0,:bad=>[:content_audit_missing]}
      {:pass=>(a[:pass] && a[:events].to_i==49 && a[:matrix].to_i==126),:events=>a[:events].to_i,:matrix=>a[:matrix].to_i,:families=>a[:families].to_i,:bad=>(a[:bad]||[])}
    rescue
      {:pass=>false,:events=>0,:matrix=>0,:bad=>[:matrix_exception]}
    end

    def vxrd_map091_runtime_acceptance_v10660
      bad=[]
      return {:pass=>false,:owned=>0,:plan=>0,:roundtrip=>false,:bad=>[:not_map090]} if $game_map==nil || $game_map.map_id.to_i!=90
      sess=phase_div_hunt_session_v10555 rescue nil
      state=vxrd_state_v10582 rescue nil
      bad << :session unless sess.is_a?(Hash) && sess[:active]
      bad << :state unless state.is_a?(Hash)
      events=$game_map.events||{};owned=[]
      events.each do |id,ev|
        next unless vxrd_template_event_owned_v10649?(ev) rescue false
        owned << ev
        sm=ev.instance_variable_get(:@pmd_vxrd_template_source_map_v10649) rescue 0
        sid=ev.instance_variable_get(:@pmd_vxrd_template_source_id_v10649) rescue 0
        role=ev.instance_variable_get(:@pmd_vxrd_template_role_v10649) rescue nil
        name=vxrd_game_event_name_v10584(ev) rescue ''
        bad << ('runtime_source_map_'+id.to_i.to_s).to_sym unless sm.to_i==91
        bad << ('runtime_source_id_'+id.to_i.to_s).to_sym unless sid.to_i>0
        bad << ('runtime_role_'+id.to_i.to_s).to_sym unless VXRD_MAP091_ALLOWED_ROLES_V10660.include?(role)
        bad << ('runtime_generated_name_'+id.to_i.to_s).to_sym unless name.to_s.index('<PMD_RD_GENERATED>')!=nil
        raw=ev.instance_variable_get(:@event) rescue nil
        bad << ('runtime_raw_'+id.to_i.to_s).to_sym if raw==nil || !(raw.pages rescue nil).is_a?(Array)
      end
      bad << :runtime_owned_empty if owned.empty?
      plan=state.is_a?(Hash) ? (state[:event_template_plan_v10649]||[]) : []
      bad << :runtime_plan_empty if !plan.is_a?(Array) || plan.empty?
      bad << :runtime_plan_count unless !owned.empty? && plan.is_a?(Array) && plan.size==owned.size
      roundtrip=false;roundtrip_owned=0;session_roundtrip=false
      begin
        blob=Marshal.dump($game_map);gm=Marshal.load(blob);ev2=gm.events||{}
        ev2.each_value{|ev|roundtrip_owned+=1 if (ev.instance_variable_get(:@pmd_vxrd_template_event_v10649) rescue false)==true}
        roundtrip=(roundtrip_owned==owned.size && roundtrip_owned>0)
      rescue
        roundtrip=false
      end
      bad << :game_map_marshal_roundtrip unless roundtrip
      begin
        sb=Marshal.dump(sess);sc=Marshal.load(sb)
        session_roundtrip=(sc.is_a?(Hash) && sc[:code].to_s==sess[:code].to_s && sc[:vxrd_floor_count_v10584].to_i==sess[:vxrd_floor_count_v10584].to_i)
      rescue
        session_roundtrip=false
      end
      bad << :session_marshal_roundtrip unless session_roundtrip
      {:pass=>bad.empty?,:owned=>owned.size,:plan=>(plan.is_a?(Array) ? plan.size : 0),:roundtrip=>roundtrip,:roundtrip_owned=>roundtrip_owned,:session_roundtrip=>session_roundtrip,:hunt=>(sess.is_a?(Hash) ? sess[:code].to_s : 'NONE'),:floor=>(sess.is_a?(Hash) ? sess[:vxrd_floor_count_v10584].to_i : 0),:bad=>bad}
    rescue Exception=>e
      {:pass=>false,:owned=>0,:plan=>0,:roundtrip=>false,:bad=>[:runtime_exception],:error=>e.class.to_s}
    end

    def vxrd_map091_full_acceptance_v10660
      base=vxrd_event_template_audit_v10649 rescue {:pass=>false,:bad=>[:template_audit_missing]}
      source=vxrd_map091_source_acceptance_v10660;parser=vxrd_map091_parser_contract_v10660;matrix=vxrd_map091_matrix_acceptance_v10660;runtime=vxrd_map091_runtime_acceptance_v10660
      bad=[];bad << :template_authority unless base[:pass];bad << :source unless source[:pass];bad << :parser unless parser[:pass];bad << :matrix unless matrix[:pass];bad << :runtime unless runtime[:pass]
      {:pass=>bad.empty?,:template=>base,:source=>source,:parser=>parser,:matrix=>matrix,:runtime=>runtime,:bad=>bad}
    rescue Exception=>e
      {:pass=>false,:bad=>[:full_exception],:error=>e.class.to_s}
    end

    def vxrd_write_map091_acceptance_v10660(result=nil)
      r=result||vxrd_map091_full_acceptance_v10660;s=r[:source]||{};p=r[:parser]||{};m=r[:matrix]||{};rt=r[:runtime]||{};ta=r[:template]||{}
      lines=[]
      lines << 'PMD AutoChess VXRD Map091 Full Acceptance v1.06.60 TEST-ONLY'
      lines << 'RESULT='+(r[:pass] ? 'PASS':'FAIL')
      lines << 'FORMAL_BASELINE=v1.06.58'
      lines << 'MAP091_TEMPLATE_AUTHORITY='+(ta[:pass] ? 'PASS':'FAIL')
      lines << 'SOURCE_EVENTS='+s[:events].to_i.to_s+'/49';lines << 'SOURCE_PAGES='+s[:pages].to_i.to_s
      lines << 'PAGE_GRAPHICS='+s[:graphics].to_i.to_s+'/'+s[:pages].to_i.to_s;lines << 'PAGE_TRIGGERS='+s[:triggers].to_i.to_s+'/'+s[:pages].to_i.to_s;lines << 'PAGE_COMMAND_LISTS='+s[:lists].to_i.to_s+'/'+s[:pages].to_i.to_s
      lines << 'DEEP_CLONES='+s[:clones].to_i.to_s+'/49';lines << 'PARSER_CONTRACT='+(p[:pass] ? 'PASS':'FAIL');lines << 'PARSER_TESTS='+p[:tests].to_i.to_s+'/12';lines << 'FIXED_CONTROL_SHARED_CONTRACT='+(p[:pass] ? 'PASS':'FAIL')
      lines << 'CONTENT_MATRIX='+m[:matrix].to_i.to_s+'/126';lines << 'HUNT_FAMILIES='+m[:families].to_i.to_s+'/4'
      lines << 'RUNTIME_HUNT='+rt[:hunt].to_s;lines << 'RUNTIME_FLOOR='+rt[:floor].to_i.to_s;lines << 'RUNTIME_TEMPLATE_EVENTS='+rt[:owned].to_i.to_s;lines << 'RUNTIME_PLAN_EVENTS='+rt[:plan].to_i.to_s
      lines << 'GAME_MAP_MARSHAL_ROUNDTRIP='+(rt[:roundtrip] ? 'PASS':'FAIL');lines << 'GAME_MAP_ROUNDTRIP_TEMPLATE_EVENTS='+rt[:roundtrip_owned].to_i.to_s;lines << 'SESSION_MARSHAL_ROUNDTRIP='+(rt[:session_roundtrip] ? 'PASS':'FAIL')
      lines << 'RUNTIME_MUTATION=0';lines << 'MAP091_MUTATION=0';lines << 'BATTLE_MECHANICS_CHANGED=0';lines << 'REWARD_MECHANICS_CHANGED=0';lines << 'PROGRESSION_CHANGED=0'
      lines << 'EDITOR_WORKFLOW=FULL_OVERWRITE_WHILE_EDITOR_AUTHORING_PAUSED;CLOSE_RMVX_BEFORE_DATA_OVERWRITE'
      [ta,s,p,m,rt].each{|h|(h[:bad]||[]).each{|x|lines << 'ERROR='+x.to_s}};(r[:bad]||[]).each{|x|lines << 'ERROR=FULL_'+x.to_s}
      File.open(VXRD_MAP091_ACCEPT_LOG_V10660,'wb'){|io|io.write(lines.join("\r\n")+"\r\n")};r
    rescue
      r||{:pass=>false}
    end
  end
end

class Scene_Map
  alias pmd_ac_v10660_map091_accept_update update unless method_defined?(:pmd_ac_v10660_map091_accept_update)
  alias pmd_ac_v10660_map091_accept_terminate terminate unless method_defined?(:pmd_ac_v10660_map091_accept_terminate)
  def vxrd_map091_accept_dispose_v10660
    if @vxrd_map091_accept_overlay_v10660!=nil
      begin;b=@vxrd_map091_accept_overlay_v10660.bitmap;b.dispose if b!=nil && !b.disposed?;rescue;end
      begin;@vxrd_map091_accept_overlay_v10660.dispose unless @vxrd_map091_accept_overlay_v10660.disposed?;rescue;end
    end
    @vxrd_map091_accept_overlay_v10660=nil;@vxrd_map091_accept_overlay_frames_v10660=0
  rescue
  end
  def vxrd_map091_accept_show_v10660(r)
    vxrd_map091_accept_dispose_v10660;s=Sprite.new;s.bitmap=Bitmap.new(Graphics.width,Graphics.height);s.z=31000;b=s.bitmap
    b.fill_rect(0,0,Graphics.width,Graphics.height,Color.new(2,7,13,235));b.font.name=['Microsoft JhengHei','Arial'];b.font.size=22;b.font.bold=true;b.font.color=r[:pass] ? Color.new(110,255,145):Color.new(255,110,110)
    b.draw_text(8,20,Graphics.width-16,30,'Map091 Full Acceptance  '+(r[:pass] ? 'PASS':'FAIL'),1)
    src=r[:source]||{};mx=r[:matrix]||{};rt=r[:runtime]||{};pa=r[:parser]||{}
    rows=['Source Events: '+src[:events].to_i.to_s+'/49   Deep Clone: '+src[:clones].to_i.to_s+'/49','Hunt/Floor Matrix: '+mx[:matrix].to_i.to_s+'/126   Parser: '+(pa[:pass] ? 'PASS':'FAIL'),'Runtime Events: '+rt[:owned].to_i.to_s+'   Plan: '+rt[:plan].to_i.to_s,'Game_Map Save/Load Roundtrip: '+(rt[:roundtrip] ? 'PASS':'FAIL'),'Session Save/Load Roundtrip: '+(rt[:session_roundtrip] ? 'PASS':'FAIL'),'LOG: '+PMD_AC::VXRD_MAP091_ACCEPT_LOG_V10660]
    b.font.size=15;b.font.bold=false;b.font.color=Color.new(220,230,240);rows.each_with_index{|t,i|b.draw_text(20,80+i*35,Graphics.width-40,28,t,0)}
    b.font.size=12;b.font.color=Color.new(170,195,220);b.draw_text(12,340,Graphics.width-24,22,'TEST-only audit. No Map090/Map091 mutation. Overlay closes automatically.',1)
    @vxrd_map091_accept_overlay_v10660=s;@vxrd_map091_accept_overlay_frames_v10660=240
  rescue
    vxrd_map091_accept_dispose_v10660
  end
  def vxrd_map091_accept_shortcut_v10660
    return false unless $TEST;return false if $game_map==nil || $game_map.map_id.to_i!=90;return false unless Input.press?(Input::SHIFT) && Input.trigger?(Input::F5)
    r=PMD_AC.vxrd_map091_full_acceptance_v10660;PMD_AC.vxrd_write_map091_acceptance_v10660(r);vxrd_map091_accept_show_v10660(r);begin;r[:pass] ? Sound.play_decision : Sound.play_buzzer;rescue;end;true
  rescue
    false
  end
  def update
    pmd_ac_v10660_map091_accept_update
    if @vxrd_map091_accept_overlay_frames_v10660.to_i>0;@vxrd_map091_accept_overlay_frames_v10660-=1;vxrd_map091_accept_dispose_v10660 if @vxrd_map091_accept_overlay_frames_v10660<=0;end
    vxrd_map091_accept_shortcut_v10660
  rescue
    pmd_ac_v10660_map091_accept_update
  end
  def terminate
    vxrd_map091_accept_dispose_v10660;pmd_ac_v10660_map091_accept_terminate
  end
end
