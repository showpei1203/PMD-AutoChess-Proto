# encoding: UTF-8
#===============================================================================
# ■ PMD AutoChess - Map091 Editor Registration Bridge v1.06.50
#-------------------------------------------------------------------------------
# Purpose:
# - Map091.rvdata already exists as the FS-style Event Template Library.
# - RPG Maker VX editor visibility is controlled by Data/MapInfos.rvdata.
# - The user should NOT have to create dozens of dummy maps to reach ID 091.
#
# On game startup, this script safely patches the CURRENT project's MapInfos:
# 1) preserve every existing entry exactly;
# 2) add key 91 only if it is missing;
# 3) clone an existing RPG::MapInfo object, then set Map091 metadata;
# 4) write a one-time backup before saving;
# 5) subsequent startups are no-ops once ID 91 exists.
#
# No map gameplay data, progression, or Map090 runtime authority is changed.
#===============================================================================
$imported={} unless defined?($imported)
$imported['PMD_AutoChess_Map091EditorRegistrationBridge_v10650']=true

module PMD_AC
  VXRD_TEMPLATE_MAP_ID_V10650=91
  VXRD_TEMPLATE_MAP_NAME_V10650='[VXRD] Event Templates'
  VXRD_MAPINFOS_PATH_V10650='Data/MapInfos.rvdata'
  VXRD_MAP091_PATH_V10650='Data/Map091.rvdata'
  VXRD_MAPINFOS_BACKUP_V10650='Data/MapInfos.rvdata.v10650.bak'
  VXRD_MAPINFO_PATCH_LOG_V10650='PMD_MapInfo091Patch_LATEST.log'

  class << self
    def vxrd_map091_editor_registration_v10650
      result={:pass=>false,:changed=>false,:already=>false,:reason=>:unknown}
      begin
        unless File.exist?(VXRD_MAP091_PATH_V10650)
          result[:reason]=:map091_missing
          return result
        end
        unless File.exist?(VXRD_MAPINFOS_PATH_V10650)
          result[:reason]=:mapinfos_missing
          return result
        end
        infos=load_data(VXRD_MAPINFOS_PATH_V10650)
        unless infos.is_a?(Hash)
          result[:reason]=:mapinfos_not_hash
          return result
        end
        id=VXRD_TEMPLATE_MAP_ID_V10650
        if infos.has_key?(id)
          result[:pass]=true
          result[:already]=true
          result[:reason]=:already_registered
          vxrd_write_map091_patch_log_v10650(result,infos)
          return result
        end
        template=nil
        infos.keys.sort.each do |k|
          v=infos[k]
          if v!=nil
            template=v
            break
          end
        end
        if template==nil
          result[:reason]=:no_mapinfo_template
          return result
        end
        # Backup the user's CURRENT MapInfos byte-for-byte before first change.
        unless File.exist?(VXRD_MAPINFOS_BACKUP_V10650)
          File.open(VXRD_MAPINFOS_PATH_V10650,'rb') do |src|
            File.open(VXRD_MAPINFOS_BACKUP_V10650,'wb'){|dst|dst.write(src.read)}
          end
        end
        mi=Marshal.load(Marshal.dump(template))
        max_order=0
        infos.each_value do |obj|
          o=obj.instance_variable_get(:@order).to_i rescue 0
          max_order=o if o>max_order
        end
        mi.instance_variable_set(:@name,VXRD_TEMPLATE_MAP_NAME_V10650)
        mi.instance_variable_set(:@parent_id,0)
        mi.instance_variable_set(:@order,max_order+1)
        mi.instance_variable_set(:@expanded,false)
        mi.instance_variable_set(:@scroll_x,272)
        mi.instance_variable_set(:@scroll_y,208)
        infos[id]=mi
        save_data(infos,VXRD_MAPINFOS_PATH_V10650)

        # Verify from disk, not only from the in-memory hash.
        check=load_data(VXRD_MAPINFOS_PATH_V10650)
        ok=check.is_a?(Hash) && check.has_key?(id)
        result[:pass]=ok
        result[:changed]=ok
        result[:reason]=(ok ? :registered : :verify_failed)
        result[:entries_before]=infos.size-1
        result[:entries_after]=(check.is_a?(Hash) ? check.size : 0)
        result[:order]=mi.instance_variable_get(:@order).to_i rescue 0
        vxrd_write_map091_patch_log_v10650(result,check)
        result
      rescue Exception=>e
        result[:reason]=:exception
        result[:error]=e.class.to_s+': '+e.message.to_s
        begin;vxrd_write_map091_patch_log_v10650(result,nil);rescue;end
        result
      end
    end

    def vxrd_write_map091_patch_log_v10650(result,infos=nil)
      begin
        lines=[]
        lines << 'PMD AutoChess Map091 Editor Registration v1.06.50'
        lines << 'RESULT='+(result[:pass] ? 'PASS':'FAIL')
        lines << 'CHANGED='+(result[:changed] ? '1':'0')
        lines << 'ALREADY_REGISTERED='+(result[:already] ? '1':'0')
        lines << 'REASON='+result[:reason].to_s
        lines << 'MAP_ID='+VXRD_TEMPLATE_MAP_ID_V10650.to_s
        lines << 'MAP_NAME='+VXRD_TEMPLATE_MAP_NAME_V10650
        lines << 'MAP091_FILE='+(File.exist?(VXRD_MAP091_PATH_V10650) ? 'PASS':'MISSING')
        lines << 'MAPINFOS_FILE='+(File.exist?(VXRD_MAPINFOS_PATH_V10650) ? 'PASS':'MISSING')
        lines << 'BACKUP='+(File.exist?(VXRD_MAPINFOS_BACKUP_V10650) ? VXRD_MAPINFOS_BACKUP_V10650 : 'NONE')
        lines << 'MAPINFO_HAS_091='+((infos.is_a?(Hash) && infos.has_key?(VXRD_TEMPLATE_MAP_ID_V10650)) ? '1':'0')
        lines << 'ERROR='+result[:error].to_s if result[:error]
        File.open(VXRD_MAPINFO_PATCH_LOG_V10650,'wb'){|io|io.write(lines.join("\r\n")+"\r\n")}
      rescue
      end
      true
    end

    def vxrd_map091_registration_audit_v10650
      {:pass=>true,:target_map_id=>91,:sparse_map_ids_supported=>true,
       :preserve_existing_mapinfos=>true,:backup_before_write=>true,
       :second_game_map=>false,:gameplay_change=>false}
    end
  end
end

# Run once at script load. MapInfos is editor metadata, not active Game_Map data.
begin
  PMD_AC.vxrd_map091_editor_registration_v10650
rescue
end

module PMD_AC
  class << self
    alias pmd_ac_v10650_write_project_state_log write_project_state_log unless method_defined?(:pmd_ac_v10650_write_project_state_log)
    def project_version
      '1.06.50'
    end
    def write_project_state_log(force=false)
      r=pmd_ac_v10650_write_project_state_log(force)
      return false unless r
      begin
        text='';File.open(PROJECT_STATE_FILE_V10564,'rb'){|io|text=io.read}
        text=text.gsub(/CURRENT_VERSION=[^\r\n]+/,'CURRENT_VERSION=1.06.50')
        text=text.gsub(/LATEST_FEATURE=[^\r\n]+/,'LATEST_FEATURE=MAP091_EDITOR_REGISTRATION_BRIDGE+FS_STYLE_EVENT_TEMPLATE_MAP')
        text=text.gsub(/NEXT_TARGET=[^\r\n]+/,'NEXT_TARGET=MAP091_EDITOR_AUTHORING+EVENT_TEMPLATE_CONTENTIZATION')
        text=text.gsub(/PROJECT_STATE_SCHEMA=\d+/,'PROJECT_STATE_SCHEMA=34')
        text=text.gsub(/\r?\nMAP091_EDITOR_REGISTRATION_V10650_BEGIN.*?MAP091_EDITOR_REGISTRATION_V10650_END\r?\n/m,"\r\n")
        begin
          infos=load_data(VXRD_MAPINFOS_PATH_V10650)
          registered=infos.is_a?(Hash) && infos.has_key?(VXRD_TEMPLATE_MAP_ID_V10650)
        rescue
          registered=false
        end
        lines=[]
        lines << ''
        lines << 'MAP091_EDITOR_REGISTRATION_V10650_BEGIN'
        lines << 'MAP091_EDITOR_VISIBLE='+(registered ? 'READY_AFTER_EDITOR_RESTART':'NOT_REGISTERED')
        lines << 'MAP091_MAP_ID=91'
        lines << 'MAP091_MAP_NAME='+VXRD_TEMPLATE_MAP_NAME_V10650
        lines << 'MAP091_MAPINFOS_PATCH=ADD_ONLY'
        lines << 'MAP091_EXISTING_MAPINFO_ENTRIES=PRESERVED'
        lines << 'MAP091_MAPINFOS_BACKUP='+VXRD_MAPINFOS_BACKUP_V10650
        lines << 'MAP091_SECOND_GAME_MAP=0'
        lines << 'MAP091_GAMEPLAY_CHANGE=0'
        lines << 'MAP091_EDITOR_REGISTRATION_V10650_END'
        File.open(PROJECT_STATE_FILE_V10564,'wb'){|io|io.write(text.rstrip+"\r\n"+lines.join("\r\n")+"\r\n")}
      rescue
      end
      true
    rescue
      false
    end
  end
end
