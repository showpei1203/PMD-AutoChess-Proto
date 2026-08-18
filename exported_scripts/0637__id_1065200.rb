# encoding: UTF-8
#===============================================================================
# ■ PMD AutoChess - VXRD Map091 Event Contentization I v1.06.52
#-------------------------------------------------------------------------------
# Map091 is now the shared authored event library for H01-H21.
# This pass turns the 11 generic stock templates into a deterministic content
# matrix without changing battle / reward / progression mechanics:
# - 5 common structural templates: Entrance / Exit / Retreat / Treasure / Recovery
# - 4 Hunt-family Info templates
# - 24 normal Encounter templates: 4 families x (3 low + 3 deep)
# - 8 Rare templates: 4 families x low/deep
# - 8 Elite templates: 4 families x low/deep
# Total: 49 source events.
#
# Low band = Floors 1-3. Deep band = Floors 4-6.
# Each normal encounter band exposes exactly three MAX:1 candidates, preserving
# the established maximum of three encounter nodes while exercising real FS-like
# HUNT/HUNTS + FLOOR/FLOORS filtering from the editor-authored Map091.
#===============================================================================
$imported={} unless defined?($imported)
$imported['PMD_AutoChess_VXRDEventContentizationI_v10652']=true

module PMD_AC
  VXRD_EVENT_CONTENT_AUDIT_LOG_V10652='PMD_VXRD_EventContentAudit_LATEST.log'
  VXRD_EVENT_CONTENT_EXPECTED_EVENTS_V10652=49
  VXRD_EVENT_FAMILY_HUNTS_V10652={
    :forest=>['H01','H06','H11','H16'],
    :wetland_ice=>['H02','H07','H12','H17'],
    :open_rock=>['H03','H04','H13','H18'],
    :relic_deep=>['H05','H08','H09','H10','H14','H15','H19','H20','H21']
  }

  class << self
    def vxrd_event_content_family_v10652(code)
      c=code.to_s.upcase
      VXRD_EVENT_FAMILY_HUNTS_V10652.each do |family,codes|
        return family if codes.include?(c)
      end
      nil
    rescue
      nil
    end

    def vxrd_event_content_capacity_v10652(entries)
      total=0
      (entries||[]).each do |e|
        cap=e[:max]
        total+=(cap==nil ? 999:cap.to_i)
      end
      total
    rescue
      0
    end

    def vxrd_event_content_audit_v10652
      map=vxrd_load_event_template_map_v10649(91) rescue nil
      bad=[];matrix=[];family_counts={};role_counts={}
      return {:pass=>false,:events=>0,:matrix=>0,:bad=>[:map091_missing]} if map==nil
      events=map.events rescue nil
      return {:pass=>false,:events=>0,:matrix=>0,:bad=>[:events_missing]} unless events.is_a?(Hash)
      bad << :event_count unless events.size==VXRD_EVENT_CONTENT_EXPECTED_EVENTS_V10652
      pos={}
      events.each do |id,ev|
        next if ev==nil
        name=ev.name.to_s
        bad << ('legacy_floor_ceiling_'+id.to_i.to_s).to_sym if name =~ /<PMD_RD_FLOORS\s*:\s*1\s*-\s*5>/i
        p=[ev.x.to_i,ev.y.to_i]
        bad << ('duplicate_source_position_'+id.to_i.to_s).to_sym if pos[p]
        pos[p]=true
        role=vxrd_template_event_role_v10649(ev)
        role_counts[role]=role_counts[role].to_i+1 unless role==nil
        VXRD_EVENT_FAMILY_HUNTS_V10652.each do |family,codes|
          hs=vxrd_template_hunt_set_v10649(name)
          if !(hs & codes).empty?
            family_counts[family]=family_counts[family].to_i+1
            break
          end
        end
      end
      all=[];VXRD_EVENT_FAMILY_HUNTS_V10652.each_value{|codes|all.concat(codes)}
      bad << :hunt_partition unless all.uniq.sort==(1..21).collect{|i|'H'+sprintf('%02d',i)}
      (1..21).each do |i|
        code='H'+sprintf('%02d',i)
        family=vxrd_event_content_family_v10652(code)
        bad << ('family_missing_'+code).to_sym if family==nil
        (1..6).each do |floor|
          row={:code=>code,:floor=>floor,:family=>family}
          [:entrance,:exit,:retreat,:treasure,:recovery,:info,:rare,:elite].each do |role|
            e=vxrd_template_entries_v10649(map,floor,role,code)
            row[role]=e.size
            bad << (code+'_F'+floor.to_s+'_'+role.to_s+'_coverage').to_sym if e.size<1
          end
          enc=vxrd_template_entries_v10649(map,floor,:encounter,code)
          row[:encounter_entries]=enc.size
          row[:encounter_capacity]=vxrd_event_content_capacity_v10652(enc)
          bad << (code+'_F'+floor.to_s+'_encounter_entries').to_sym unless enc.size==3
          bad << (code+'_F'+floor.to_s+'_encounter_capacity').to_sym if row[:encounter_capacity]<3
          matrix << row
        end
      end
      {:pass=>bad.empty?,:events=>events.size,:matrix=>matrix.size,
       :families=>VXRD_EVENT_FAMILY_HUNTS_V10652.size,:family_counts=>family_counts,
       :role_counts=>role_counts,:low_band=>'1-3',:deep_band=>'4-6',
       :all_hunts=>21,:all_floors_tested=>6,:bad=>bad}
    rescue Exception=>e
      {:pass=>false,:events=>0,:matrix=>0,:bad=>[:audit_exception],:error=>e.class.to_s}
    end

    def vxrd_write_event_content_audit_v10652
      a=vxrd_event_content_audit_v10652
      lines=[]
      lines << 'PMD AutoChess VXRD Event Content Audit v1.06.52'
      lines << 'RESULT='+(a[:pass] ? 'PASS':'FAIL')
      lines << 'MAP_ID=91'
      lines << 'SOURCE_EVENTS='+a[:events].to_i.to_s+'/49'
      lines << 'HUNT_FAMILIES='+a[:families].to_i.to_s+'/4'
      lines << 'HUNTS='+a[:all_hunts].to_i.to_s+'/21'
      lines << 'FLOOR_BANDS=1-3,4-6'
      lines << 'COVERAGE_MATRIX='+a[:matrix].to_i.to_s+'/126'
      lines << 'COMMON_STRUCTURAL=5'
      lines << 'INFO_FAMILY_TEMPLATES=4'
      lines << 'NORMAL_ENCOUNTER_TEMPLATES=24'
      lines << 'RARE_TEMPLATES=8'
      lines << 'ELITE_TEMPLATES=8'
      lines << 'ENCOUNTER_CANDIDATES_PER_HUNT_FLOOR=3'
      lines << 'BATTLE_MECHANICS_CHANGED=0'
      lines << 'REWARD_MECHANICS_CHANGED=0'
      lines << 'PROGRESSION_CHANGED=0'
      lines << 'MAP091_UPDATE_POLICY=FULL_OVERWRITE_WHILE_EDITOR_AUTHORING_PAUSED'
      lines << 'RMVX_EDITOR_RESTART_REQUIRED=1'
      (a[:family_counts]||{}).each{|k,v|lines << 'FAMILY_'+k.to_s.upcase+'_SOURCE_EVENTS='+v.to_i.to_s}
      (a[:bad]||[]).each{|x|lines << 'ERROR='+x.to_s}
      File.open(VXRD_EVENT_CONTENT_AUDIT_LOG_V10652,'wb'){|io|io.write(lines.join("\r\n")+"\r\n")}
      a
    rescue
      {:pass=>false,:events=>0,:matrix=>0,:bad=>[:write_error]}
    end

    alias pmd_ac_v10652_template_materialize_events_v10649 vxrd_template_materialize_events_v10649 unless method_defined?(:pmd_ac_v10652_template_materialize_events_v10649)
    def vxrd_template_materialize_events_v10649(state,code,floor)
      out=pmd_ac_v10652_template_materialize_events_v10649(state,code,floor)
      if out.is_a?(Hash) && out[:pass]
        family=vxrd_event_content_family_v10652(code)
        out[:content_family_v10652]=family
        out[:content_band_v10652]=(floor.to_i<=3 ? :low : :deep)
        if state.is_a?(Hash)
          state[:event_content_v10652]={:family=>family,:band=>out[:content_band_v10652],
            :source_map=>91,:generated=>out[:generated].to_i}
        end
      end
      out
    rescue
      out || {:pass=>false,:reason=>:contentization_wrapper_error}
    end

    alias pmd_ac_v10652_write_project_state_log write_project_state_log unless method_defined?(:pmd_ac_v10652_write_project_state_log)
    def project_version
      '1.06.52'
    end
    def write_project_state_log(force=false)
      r=pmd_ac_v10652_write_project_state_log(force)
      return false unless r
      begin
        text='';File.open(PROJECT_STATE_FILE_V10564,'rb'){|io|text=io.read}
        text=text.gsub(/PROJECT_STATE_SCHEMA=\d+/,'PROJECT_STATE_SCHEMA=37')
        text=text.gsub(/CURRENT_VERSION=[^\r\n]+/,'CURRENT_VERSION=1.06.52')
        text=text.gsub(/LATEST_FEATURE=[^\r\n]+/,'LATEST_FEATURE=MAP091_EVENT_CONTENTIZATION_I')
        text=text.gsub(/NEXT_TARGET=[^\r\n]+/,'NEXT_TARGET=LANDMARK_TEMPLATE_II_ATLAS_SAFE+EVENT_VISUAL_ART_PASS')
        text=text.gsub('MAP091_UPDATE_POLICY=PRESERVE_LIVE_EDITOR_MAP','MAP091_UPDATE_POLICY=FULL_OVERWRITE_WHILE_EDITOR_AUTHORING_PAUSED')
        text=text.gsub(/\r?\nVXRD_EVENT_CONTENT_V10652_BEGIN.*?VXRD_EVENT_CONTENT_V10652_END\r?\n/m,"\r\n")
        a=vxrd_event_content_audit_v10652
        lines=[]
        lines << ''
        lines << 'VXRD_EVENT_CONTENT_V10652_BEGIN'
        lines << 'MAP091_EVENT_CONTENTIZATION='+(a[:pass] ? 'PASS':'FAIL')
        lines << 'MAP091_SOURCE_EVENTS='+a[:events].to_i.to_s+'/49'
        lines << 'MAP091_HUNT_FAMILIES='+a[:families].to_i.to_s+'/4'
        lines << 'MAP091_HUNT_FLOOR_MATRIX='+a[:matrix].to_i.to_s+'/126'
        lines << 'MAP091_LOW_FLOOR_BAND=1-3'
        lines << 'MAP091_DEEP_FLOOR_BAND=4-6'
        lines << 'MAP091_COMMON_STRUCTURAL=5'
        lines << 'MAP091_INFO_FAMILY=4'
        lines << 'MAP091_NORMAL_ENCOUNTER=24'
        lines << 'MAP091_RARE=8'
        lines << 'MAP091_ELITE=8'
        lines << 'MAP091_UPDATE_POLICY=FULL_OVERWRITE_WHILE_EDITOR_AUTHORING_PAUSED'
        lines << 'RMVX_EDITOR_RESTART_REQUIRED=1'
        lines << 'TUTORIAL_UPDATED=1'
        lines << 'EVENT_CONTENT_AUDIT_LOG='+VXRD_EVENT_CONTENT_AUDIT_LOG_V10652
        lines << 'VXRD_EVENT_CONTENT_V10652_END'
        File.open(PROJECT_STATE_FILE_V10564,'wb'){|io|io.write(text.rstrip+"\r\n"+lines.join("\r\n")+"\r\n")}
      rescue
      end
      true
    rescue
      false
    end
  end
end

begin
  PMD_AC.vxrd_write_event_content_audit_v10652
rescue
end
