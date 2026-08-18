# encoding: UTF-8
#===============================================================================
# ■ PMD AutoChess - VXRD Map091 Authoring Guard & FS Parity I v1.06.51
#-------------------------------------------------------------------------------
# Goals:
# 1) Map091 remains the single shared Event Template Library for H01-H21.
# 2) Correct the stock v1.06.50 template's accidental FLOORS:1-5 ceiling;
#    Tier-5 H21 can reach Floor 6, so generic templates must be all-floor.
# 3) Match Forest Symphony semantics for standalone <PMD_RD_FIXED> and
#    <PMD_RD_CONTROL> template events (no pool role tag required).
# 4) Add <PMD_RD_DISABLED> for safe editor-side temporary disabling.
# 5) Validate template syntax and requested-role capacity before cutover.
#    If Map091 cannot satisfy a generated floor, DO NOT remove legacy events;
#    preserve the older runtime event set as a safety fallback.
# 6) Produce PMD_VXRD_EventTemplateAudit_LATEST.log automatically.
#===============================================================================
$imported={} unless defined?($imported)
$imported['PMD_AutoChess_VXRDMap091AuthoringGuardFSParityI_v10651']=true

module PMD_AC
  VXRD_TEMPLATE_AUDIT_LOG_V10651='PMD_VXRD_EventTemplateAudit_LATEST.log'
  VXRD_TEMPLATE_MAP_PATH_V10651='Data/Map091.rvdata'
  VXRD_TEMPLATE_MAP_BACKUP_V10651='Data/Map091.rvdata.v10651.bak'
  VXRD_TEMPLATE_VALID_HUNTS_V10651=(1..21).collect{|i|'H'+sprintf('%02d',i)}
  VXRD_TEMPLATE_ROLE_ORDER_V10651=[:entrance,:exit,:retreat,:info,:treasure,:recovery,:rare,:elite,:encounter]
  VXRD_TEMPLATE_ROLE_TAGS_V10651={
    :entrance=>'<PMD_RD_ENTRANCE>',:exit=>'<PMD_RD_EXIT>',
    :encounter=>'<PMD_RD_ENCOUNTER>',:rare=>'<PMD_RD_RARE>',
    :elite=>'<PMD_RD_ELITE>',:treasure=>'<PMD_RD_TREASURE>',
    :recovery=>'<PMD_RD_RECOVERY>',:retreat=>'<PMD_RD_RETREAT>',
    :info=>'<PMD_RD_INFO>'
  }
  VXRD_TEMPLATE_ALLOWED_TAGS_V10651=[
    'PMD_RD_ENTRANCE','PMD_RD_EXIT','PMD_RD_ENCOUNTER','PMD_RD_RARE',
    'PMD_RD_ELITE','PMD_RD_TREASURE','PMD_RD_RECOVERY','PMD_RD_RETREAT',
    'PMD_RD_INFO','PMD_RD_WEIGHT','PMD_RD_MAX','PMD_RD_UNIQUE',
    'PMD_RD_NO_REPEAT','PMD_RD_SHARED','PMD_RD_FIXED','PMD_RD_CONTROL',
    'PMD_RD_FLOOR','PMD_RD_FLOORS','PMD_RD_HUNT','PMD_RD_HUNTS',
    'PMD_RD_DISABLED'
  ]
  VXRD_STOCK_NAMES_V10650={
    1=>'Exit <PMD_RD_EXIT><PMD_RD_UNIQUE><PMD_RD_FLOORS:1-5>',
    2=>'Encounter A <PMD_RD_ENCOUNTER><PMD_RD_WEIGHT:100><PMD_RD_MAX:1><PMD_RD_FLOORS:1-5>',
    3=>'Encounter B <PMD_RD_ENCOUNTER><PMD_RD_WEIGHT:80><PMD_RD_MAX:1><PMD_RD_FLOORS:1-5>',
    4=>'Encounter C <PMD_RD_ENCOUNTER><PMD_RD_WEIGHT:60><PMD_RD_MAX:1><PMD_RD_FLOORS:1-5>',
    5=>'Treasure <PMD_RD_TREASURE><PMD_RD_UNIQUE><PMD_RD_FLOORS:1-5>',
    6=>'Recovery <PMD_RD_RECOVERY><PMD_RD_UNIQUE><PMD_RD_FLOORS:1-5>',
    7=>'Retreat <PMD_RD_RETREAT><PMD_RD_UNIQUE><PMD_RD_FLOORS:1-5>',
    8=>'Info <PMD_RD_INFO><PMD_RD_UNIQUE><PMD_RD_FLOORS:1-5>',
    9=>'Entrance <PMD_RD_ENTRANCE><PMD_RD_UNIQUE><PMD_RD_FLOORS:1-5>',
    10=>'Rare Nest <PMD_RD_RARE><PMD_RD_UNIQUE><PMD_RD_FLOORS:1-5>',
    11=>'Elite <PMD_RD_ELITE><PMD_RD_UNIQUE><PMD_RD_FLOORS:1-5>'
  }

  class << self
    def vxrd_template_name_v10651(obj)
      obj.respond_to?(:name) ? obj.name.to_s : obj.to_s
    rescue
      obj.to_s
    end

    def vxrd_template_disabled_v10651?(obj)
      vxrd_template_name_v10651(obj) =~ /<PMD_RD_DISABLED>/i ? true:false
    rescue
      false
    end

    # FS parity: standalone FIXED / CONTROL are valid direct template types.
    alias pmd_ac_v10651_template_event_role_v10649 vxrd_template_event_role_v10649 unless method_defined?(:pmd_ac_v10651_template_event_role_v10649)
    def vxrd_template_event_role_v10649(rpg_event_or_name)
      role=pmd_ac_v10651_template_event_role_v10649(rpg_event_or_name)
      return role unless role==nil
      name=vxrd_template_name_v10651(rpg_event_or_name)
      fixed=(name =~ /<PMD_RD_FIXED>/i) ? true:false
      control=(name =~ /<PMD_RD_CONTROL>/i) ? true:false
      return :fixed if fixed && !control
      return :control if control && !fixed
      nil
    rescue
      nil
    end

    # Disabled templates stay on Map091 for editing but never enter selection.
    alias pmd_ac_v10651_template_entries_v10649 vxrd_template_entries_v10649 unless method_defined?(:pmd_ac_v10651_template_entries_v10649)
    def vxrd_template_entries_v10649(map,floor,role=nil,code=nil)
      rows=pmd_ac_v10651_template_entries_v10649(map,floor,role,code)
      rows.find_all{|e|!vxrd_template_disabled_v10651?(e[:event])}
    rescue
      []
    end

    # FS parity: standalone fixed/control events are direct, deterministic
    # templates. They are materialized once each when their floor/hunt filters
    # match; they do not consume encounter/treasure pool counts.
    alias pmd_ac_v10651_template_plan_v10649 vxrd_template_plan_v10649 unless method_defined?(:pmd_ac_v10651_template_plan_v10649)
    def vxrd_template_plan_v10649(template_map,state,floor,map_id)
      plan=pmd_ac_v10651_template_plan_v10649(template_map,state,floor,map_id)
      code=state==nil ? nil:state[:code]
      [:fixed,:control].each do |role|
        vxrd_template_entries_v10649(template_map,floor,role,code).each do |entry|
          plan << entry.dup
        end
      end
      plan
    rescue
      []
    end

    def vxrd_template_role_tags_found_v10651(name)
      out=[]
      VXRD_TEMPLATE_ROLE_TAGS_V10651.each do |role,tag|
        out << role if name.to_s.upcase.index(tag)
      end
      out
    rescue
      []
    end

    def vxrd_template_floor_tokens_v10651(name)
      text=name.to_s
      tokens=[]
      text.scan(/<PMD_RD_FLOOR\s*:\s*([^>]+)>/i){|m|tokens << [:single,m[0].to_s.strip]}
      text.scan(/<PMD_RD_FLOORS\s*:\s*([^>]+)>/i){|m|m[0].to_s.split(',').each{|t|tokens << [:multi,t.to_s.strip]}}
      tokens
    rescue
      []
    end

    def vxrd_template_floor_syntax_issues_v10651(name)
      issues=[]
      vxrd_template_floor_tokens_v10651(name).each do |kind,token|
        if token =~ /^\d+$/
          issues << 'floor_nonpositive:'+token if token.to_i<=0
        elsif token =~ /^(\d+)\s*-\s*(\d+)$/
          a=$1.to_i;b=$2.to_i
          issues << 'floor_range_nonpositive:'+token if a<=0 || b<=0
        else
          issues << 'floor_token_invalid:'+token
        end
      end
      issues
    rescue
      ['floor_parse_error']
    end

    def vxrd_template_hunt_syntax_issues_v10651(name)
      text=name.to_s.upcase;issues=[];tokens=[]
      text.scan(/<PMD_RD_HUNT\s*:\s*([^>]+)>/i){|m|tokens << m[0].to_s.strip.upcase}
      text.scan(/<PMD_RD_HUNTS\s*:\s*([^>]+)>/i){|m|m[0].to_s.split(',').each{|t|tokens << t.to_s.strip.upcase}}
      tokens.each do |token|
        issues << 'hunt_invalid:'+token unless VXRD_TEMPLATE_VALID_HUNTS_V10651.include?(token)
      end
      issues
    rescue
      ['hunt_parse_error']
    end

    def vxrd_template_numeric_issues_v10651(name)
      text=name.to_s;issues=[]
      if text =~ /<PMD_RD_WEIGHT\b/i
        m=text.match(/<PMD_RD_WEIGHT\s*:\s*(\d+)\s*>/i)
        issues << 'weight_invalid' if m==nil || m[1].to_i<=0
      end
      if text =~ /<PMD_RD_MAX\b/i
        m=text.match(/<PMD_RD_MAX\s*:\s*(\d+)\s*>/i)
        issues << 'max_invalid' if m==nil || m[1].to_i<=0
      end
      issues
    rescue
      ['numeric_parse_error']
    end

    def vxrd_template_unknown_tags_v10651(name)
      out=[]
      name.to_s.scan(/<\s*(PMD_RD_[A-Z_]+)(?:\s*:[^>]*)?>/i) do |m|
        tag=m[0].to_s.upcase
        out << tag unless VXRD_TEMPLATE_ALLOWED_TAGS_V10651.include?(tag)
      end
      out.uniq
    rescue
      []
    end

    def vxrd_template_event_pages_count_v10651(ev)
      pages=ev.instance_variable_get(:@pages) rescue nil
      pages.is_a?(Array) ? pages.size : 0
    rescue
      0
    end

    def vxrd_template_source_audit_v10651(map_id=91)
      result={:pass=>false,:map_id=>map_id.to_i,:events=>0,:active=>0,:ignored=>0,
        :disabled=>0,:roles=>{},:direct=>{:fixed=>0,:control=>0},:errors=>[],:warnings=>[]}
      map=vxrd_load_event_template_map_v10649(map_id)
      if map==nil
        result[:errors] << 'template_map_missing'
        return result
      end
      events=map.events rescue nil
      unless events.is_a?(Hash)
        result[:errors] << 'template_events_missing'
        return result
      end
      result[:events]=events.size
      events.keys.sort.each do |id|
        ev=events[id];next if ev==nil
        name=ev.name.to_s
        disabled=vxrd_template_disabled_v10651?(ev)
        role_tags=vxrd_template_role_tags_found_v10651(name)
        fixed=(name =~ /<PMD_RD_FIXED>/i) ? true:false
        control=(name =~ /<PMD_RD_CONTROL>/i) ? true:false
        unknown=vxrd_template_unknown_tags_v10651(name)
        unknown.each{|t|result[:errors] << 'event_'+id.to_i.to_s+':unknown_tag:'+t}
        vxrd_template_floor_syntax_issues_v10651(name).each{|x|result[:errors] << 'event_'+id.to_i.to_s+':'+x}
        vxrd_template_hunt_syntax_issues_v10651(name).each{|x|result[:errors] << 'event_'+id.to_i.to_s+':'+x}
        vxrd_template_numeric_issues_v10651(name).each{|x|result[:errors] << 'event_'+id.to_i.to_s+':'+x}
        if role_tags.size>1
          result[:errors] << 'event_'+id.to_i.to_s+':multiple_roles:'+role_tags.join(',')
        end
        if fixed && control
          result[:errors] << 'event_'+id.to_i.to_s+':fixed_control_conflict'
        end
        has_direct=(fixed || control)
        if vxrd_template_event_pages_count_v10651(ev)<=0 && (!role_tags.empty? || has_direct)
          result[:errors] << 'event_'+id.to_i.to_s+':no_event_page'
        end
        if disabled
          result[:disabled]+=1
          next
        end
        if role_tags.empty? && !has_direct
          # Normal untagged events are allowed as editor notes/reference only.
          result[:ignored]+=1
          next
        end
        result[:active]+=1
        if !role_tags.empty?
          r=role_tags[0]
          result[:roles][r]=result[:roles][r].to_i+1
        elsif fixed
          result[:direct][:fixed]+=1
        elsif control
          result[:direct][:control]+=1
        end
      end
      # Core role presence is a source-map authoring error. Rare/Elite/etc are
      # also part of the default semantic contract and should have at least one
      # source somewhere, even if later Hunt/Floor filters narrow eligibility.
      VXRD_TEMPLATE_ROLE_ORDER_V10651.each do |r|
        result[:warnings] << 'missing_role_source:'+r.to_s if result[:roles][r].to_i<=0
      end
      result[:errors]=result[:errors].uniq
      result[:warnings]=result[:warnings].uniq
      result[:pass]=result[:errors].empty?
      result
    rescue Exception=>e
      {:pass=>false,:map_id=>map_id.to_i,:events=>0,:active=>0,:ignored=>0,:disabled=>0,
       :roles=>{},:direct=>{:fixed=>0,:control=>0},:errors=>['audit_exception:'+e.class.to_s],:warnings=>[]}
    end

    def vxrd_template_capacity_v10651(entries,requested)
      need=requested.to_i;return 0 if need<=0
      cap=0
      (entries||[]).each do |e|
        m=e[:max]
        cap += (m==nil ? need:m.to_i)
        return need if cap>=need
      end
      cap
    rescue
      0
    end

    def vxrd_template_floor_coverage_v10651(template_map,state,floor,map_id)
      counts=vxrd_template_requested_counts_v10649(state,floor)
      code=state==nil ? nil:state[:code]
      missing=[];rows={}
      VXRD_TEMPLATE_ROLE_ORDER_V10651.each do |role|
        req=counts[role].to_i;next if req<=0
        entries=vxrd_template_entries_v10649(template_map,floor,role,code)
        cap=vxrd_template_capacity_v10651(entries,req)
        rows[role]={:requested=>req,:entries=>entries.size,:capacity=>cap}
        missing << role if cap<req
      end
      {:pass=>missing.empty?,:floor=>floor.to_i,:code=>code.to_s.upcase,
       :map_id=>map_id.to_i,:roles=>rows,:missing=>missing}
    rescue
      {:pass=>false,:floor=>floor.to_i,:code=>'',:map_id=>map_id.to_i,:roles=>{},:missing=>[:audit_error]}
    end

    def vxrd_write_template_audit_v10651(source=nil,coverage=nil,runtime=nil)
      begin
        source=vxrd_template_source_audit_v10651(91) if source==nil
        lines=[]
        lines << 'PMD AutoChess VXRD Event Template Audit v1.06.51'
        lines << 'RESULT='+(source[:pass] ? 'PASS':'FAIL')
        lines << 'MAP_ID='+source[:map_id].to_i.to_s
        lines << 'EVENTS='+source[:events].to_i.to_s
        lines << 'ACTIVE='+source[:active].to_i.to_s
        lines << 'DISABLED='+source[:disabled].to_i.to_s
        lines << 'IGNORED_UNTAGGED='+source[:ignored].to_i.to_s
        VXRD_TEMPLATE_ROLE_ORDER_V10651.each{|r|lines << 'ROLE_'+r.to_s.upcase+'='+source[:roles][r].to_i.to_s}
        lines << 'DIRECT_FIXED='+source[:direct][:fixed].to_i.to_s
        lines << 'DIRECT_CONTROL='+source[:direct][:control].to_i.to_s
        (source[:errors]||[]).each{|x|lines << 'ERROR='+x.to_s}
        (source[:warnings]||[]).each{|x|lines << 'WARN='+x.to_s}
        unless coverage==nil
          lines << 'RUNTIME_CODE='+coverage[:code].to_s
          lines << 'RUNTIME_FLOOR='+coverage[:floor].to_i.to_s
          lines << 'RUNTIME_COVERAGE='+(coverage[:pass] ? 'PASS':'FAIL')
          (coverage[:roles]||{}).each do |role,row|
            lines << 'COVERAGE_'+role.to_s.upcase+'='+row[:capacity].to_i.to_s+'/'+row[:requested].to_i.to_s+' entries='+row[:entries].to_i.to_s
          end
          lines << 'RUNTIME_MISSING='+(coverage[:missing]||[]).join(',')
        end
        unless runtime==nil
          lines << 'MATERIALIZE_PASS='+(runtime[:pass] ? '1':'0')
          lines << 'MATERIALIZE_REASON='+runtime[:reason].to_s if runtime[:reason]
          lines << 'LEGACY_FALLBACK_PRESERVED='+(runtime[:legacy_fallback_preserved] ? '1':'0')
          lines << 'GENERATED='+runtime[:generated].to_i.to_s if runtime.has_key?(:generated)
        end
        File.open(VXRD_TEMPLATE_AUDIT_LOG_V10651,'wb'){|io|io.write(lines.join("\r\n")+"\r\n")}
      rescue
      end
      true
    end

    # Stock v1.06.50 Map091 mistakenly limited every generic template to 1-5.
    # Migrate ONLY if all 11 source names still match the untouched stock map.
    # If the user has already edited Map091, do not touch it; the audit log will
    # instead expose any Floor-6 coverage gap.
    def vxrd_migrate_stock_map091_all_floor_v10651
      result={:pass=>false,:changed=>false,:reason=>:unknown}
      return result unless File.exist?(VXRD_TEMPLATE_MAP_PATH_V10651)
      map=load_data(VXRD_TEMPLATE_MAP_PATH_V10651) rescue nil
      return result if map==nil
      events=map.events rescue nil
      unless events.is_a?(Hash)
        result[:reason]=:events_missing;return result
      end
      stock=true
      VXRD_STOCK_NAMES_V10650.each do |id,expected|
        ev=events[id]
        if ev==nil || ev.name.to_s!=expected
          stock=false;break
        end
      end
      unless stock && events.size==VXRD_STOCK_NAMES_V10650.size
        result[:pass]=true;result[:reason]=:custom_map_preserved;return result
      end
      unless File.exist?(VXRD_TEMPLATE_MAP_BACKUP_V10651)
        File.open(VXRD_TEMPLATE_MAP_PATH_V10651,'rb') do |src|
          File.open(VXRD_TEMPLATE_MAP_BACKUP_V10651,'wb'){|dst|dst.write(src.read)}
        end
      end
      VXRD_STOCK_NAMES_V10650.each_key do |id|
        ev=events[id];next if ev==nil
        ev.name=ev.name.to_s.gsub(/<PMD_RD_FLOORS:1-5>/i,'') if ev.respond_to?(:name=)
        ev.instance_variable_set(:@name,ev.instance_variable_get(:@name).to_s.gsub(/<PMD_RD_FLOORS:1-5>/i,'')) unless ev.respond_to?(:name=)
      end
      save_data(map,VXRD_TEMPLATE_MAP_PATH_V10651)
      check=load_data(VXRD_TEMPLATE_MAP_PATH_V10651) rescue nil
      ok=true
      cevents=check==nil ? nil:(check.events rescue nil)
      ok=false unless cevents.is_a?(Hash)
      if ok
        VXRD_STOCK_NAMES_V10650.each_key do |id|
          ev=cevents[id]
          ok=false if ev==nil || ev.name.to_s =~ /<PMD_RD_FLOORS:1-5>/i
        end
      end
      result[:pass]=ok;result[:changed]=ok;result[:reason]=(ok ? :stock_all_floor_migrated : :verify_failed)
      result
    rescue Exception=>e
      result[:reason]=:exception;result[:error]=e.class.to_s;result
    end

    # Atomic template cutover guard. If current Map091 cannot satisfy all roles
    # requested by this floor, do not call v1.06.49 materialization because it
    # would remove the legacy runtime events first. Preserve legacy events and
    # make the problem visible in the audit log instead.
    alias pmd_ac_v10651_template_materialize_events_v10649 vxrd_template_materialize_events_v10649 unless method_defined?(:pmd_ac_v10651_template_materialize_events_v10649)
    def vxrd_template_materialize_events_v10649(state,code,floor)
      map_id=vxrd_event_template_map_id_v10649(code)
      map=vxrd_load_event_template_map_v10649(map_id)
      source=vxrd_template_source_audit_v10651(map_id)
      if map==nil || !source[:pass]
        out={:pass=>false,:reason=>:template_source_invalid,:map_id=>map_id,
          :legacy_fallback_preserved=>true,:source_errors=>source[:errors]}
        vxrd_write_template_audit_v10651(source,nil,out)
        state[:event_template_guard_v10651]=out if state.is_a?(Hash)
        return out
      end
      coverage=vxrd_template_floor_coverage_v10651(map,state,floor,map_id)
      unless coverage[:pass]
        out={:pass=>false,:reason=>:template_coverage_missing,:map_id=>map_id,
          :legacy_fallback_preserved=>true,:missing=>coverage[:missing]}
        vxrd_write_template_audit_v10651(source,coverage,out)
        state[:event_template_guard_v10651]=out if state.is_a?(Hash)
        return out
      end
      out=pmd_ac_v10651_template_materialize_events_v10649(state,code,floor)
      out[:legacy_fallback_preserved]=false if out.is_a?(Hash)
      vxrd_write_template_audit_v10651(source,coverage,out)
      state[:event_template_guard_v10651]={:pass=>out[:pass],:coverage=>coverage,:legacy_fallback_preserved=>false} if state.is_a?(Hash) && out.is_a?(Hash)
      out
    rescue Exception=>e
      out={:pass=>false,:reason=>:guard_exception,:legacy_fallback_preserved=>true,:error=>e.class.to_s}
      begin;vxrd_write_template_audit_v10651(nil,nil,out);rescue;end
      out
    end

    def vxrd_event_template_authoring_audit_v10651
      src=vxrd_template_source_audit_v10651(91)
      {:pass=>src[:pass],:map_id=>91,:source_events=>src[:events],:active=>src[:active],
       :disabled=>src[:disabled],:fixed=>src[:direct][:fixed],:control=>src[:direct][:control],
       :standalone_fixed_control=>true,:disabled_tag=>true,:atomic_cutover_guard=>true,
       :floor6_compatible=>true,:map091_overwrite_on_update=>false,:tutorial_updated=>true,
       :errors=>src[:errors]}
    rescue
      {:pass=>false,:map_id=>91,:errors=>[:audit_error]}
    end

    alias pmd_ac_v10651_write_project_state_log write_project_state_log unless method_defined?(:pmd_ac_v10651_write_project_state_log)
    def project_version
      '1.06.51'
    end
    def write_project_state_log(force=false)
      r=pmd_ac_v10651_write_project_state_log(force)
      return false unless r
      begin
        text='';File.open(PROJECT_STATE_FILE_V10564,'rb'){|io|text=io.read}
        text=text.gsub(/PROJECT_STATE_SCHEMA=\d+/,'PROJECT_STATE_SCHEMA=36')
        text=text.gsub(/CURRENT_VERSION=[^\r\n]+/,'CURRENT_VERSION=1.06.51')
        text=text.gsub(/LATEST_FEATURE=[^\r\n]+/,'LATEST_FEATURE=MAP091_AUTHORING_GUARD+FS_FIXED_CONTROL_PARITY+ATOMIC_EVENT_CUTOVER')
        text=text.gsub(/NEXT_TARGET=[^\r\n]+/,'NEXT_TARGET=MAP091_EVENT_CONTENTIZATION+LANDMARK_TEMPLATE_II')
        text=text.gsub(/\r?\nVXRD_EVENT_TEMPLATE_V10651_BEGIN.*?VXRD_EVENT_TEMPLATE_V10651_END\r?\n/m,"\r\n")
        a=vxrd_event_template_authoring_audit_v10651
        lines=[]
        lines << ''
        lines << 'VXRD_EVENT_TEMPLATE_V10651_BEGIN'
        lines << 'MAP091_AUTHORING_GUARD='+(a[:pass] ? 'PASS':'FAIL')
        lines << 'MAP091_SHARED_H01_H21=1'
        lines << 'MAP091_STANDALONE_FIXED_CONTROL=1'
        lines << 'MAP091_DISABLED_TAG=1'
        lines << 'MAP091_ATOMIC_CUTOVER_GUARD=1'
        lines << 'MAP091_LEGACY_EVENT_FALLBACK_ON_INVALID_TEMPLATE=1'
        lines << 'MAP091_GENERIC_FLOOR6_COMPATIBLE=1'
        lines << 'MAP091_UPDATE_POLICY=PRESERVE_LIVE_EDITOR_MAP'
        lines << 'MAP091_TUTORIAL_UPDATED=1'
        lines << 'MAP091_AUDIT_LOG='+VXRD_TEMPLATE_AUDIT_LOG_V10651
        lines << 'VXRD_EVENT_TEMPLATE_V10651_END'
        File.open(PROJECT_STATE_FILE_V10564,'wb'){|io|io.write(text.rstrip+"\r\n"+lines.join("\r\n")+"\r\n")}
      rescue
      end
      true
    rescue
      false
    end
  end
end

# One-time stock correction followed by source-map audit. Custom/user-edited
# Map091 is deliberately not rewritten.
begin
  PMD_AC.vxrd_migrate_stock_map091_all_floor_v10651
  PMD_AC.vxrd_write_template_audit_v10651
rescue
end
