# encoding: UTF-8
#===============================================================================
# ■ PMD AutoChess - Project State Sync Schema 11 / VXRD Room Content v1.06.03
#===============================================================================
$imported={} unless defined?($imported)
$imported['PMD_AutoChess_ProjectStateSyncSchema11_v10603']=true

module PMD_AC
  class << self
    alias pmd_ac_v10603_write_vxrd_autotest_log_v10586 write_vxrd_autotest_log_v10586 unless method_defined?(:pmd_ac_v10603_write_vxrd_autotest_log_v10586)
    def write_vxrd_autotest_log_v10586(action,extra=nil)
      ok=pmd_ac_v10603_write_vxrd_autotest_log_v10586(action,extra)
      return false unless ok
      st=vxrd_state_v10582 rescue nil
      vs=st==nil ? nil : st[:visual_style_v10600]
      rt=vxrd_room_type_info_v10601 rescue nil
      rr=hunt_room_runtime_info_v10602 rescue nil
      lines=[]
      if vs!=nil
        lines << 'VISUAL_STYLE_POLICY='+vs[:policy].to_s
        lines << 'VISUAL_STYLE_PALETTE='+vs[:palette].to_i.to_s
        lines << 'VISUAL_STYLE_WATER_EXPECTED='+(vs[:water_expected] ? '1':'0')
        bank=vs[:bank]
        if bank!=nil
          lines << 'WATER_BANK_TILE='+bank[:bank_tile].to_i.to_s
          lines << 'WATER_BANK_CELLS='+bank[:bank_cells].to_i.to_s
          lines << 'WATER_BANK_ONE_TILE_RIM=1'
        end
      end
      if rt!=nil
        c=rt[:counts]||{}
        lines << 'ROOM_TYPES_TOTAL='+(rt[:types]||{}).size.to_i.to_s
        lines << 'ROOM_TYPE_NORMAL='+c[:normal].to_i.to_s
        lines << 'ROOM_TYPE_TREASURE='+c[:treasure].to_i.to_s
        lines << 'ROOM_TYPE_RARE_NEST='+c[:rare_nest].to_i.to_s
        lines << 'ROOM_TYPE_ELITE='+c[:elite].to_i.to_s
        lines << 'ROOM_TYPE_ENTRANCE='+c[:entrance].to_i.to_s
        lines << 'ROOM_TYPE_EXIT='+c[:exit].to_i.to_s
        lines << 'ROOM_EVENT_TYPED='+(rt[:events]||{}).size.to_i.to_s
      end
      if rr!=nil
        lines << 'PLAYER_ROOM_TYPE='+rr[:room_type].to_s
        lines << 'PLAYER_ROOM_ID='+(rr[:room_id]==nil ? 'nil':rr[:room_id].to_i.to_s)
        lines << 'TREASURE_CLAIMS='+rr[:treasure_claims].to_i.to_s
      end
      File.open(VXRD_AUTOTEST_LOG_V10586,'ab'){|io|io.write(lines.join("\r\n")+"\r\n")}
      true
    rescue
      false
    end

    alias pmd_ac_v10603_write_project_state_log write_project_state_log unless method_defined?(:pmd_ac_v10603_write_project_state_log)
    def project_version
      '1.06.03'
    end

    def write_project_state_log(force=false)
      r=pmd_ac_v10603_write_project_state_log(force)
      return false unless r
      v=vxrd_visual_style_audit_v10600 rescue {:pass=>false,:hunts=>0,:water_hunts=>0}
      t=vxrd_room_type_audit_v10601 rescue {:pass=>false,:rooms=>0,:typed=>0}
      x=vxrd_room_runtime_audit_v10602 rescue {:pass=>false,:api=>0}
      text='';File.open(PROJECT_STATE_FILE_V10564,'rb'){|io|text=io.read}
      text=text.gsub('PROJECT_STATE_SCHEMA=10','PROJECT_STATE_SCHEMA=11')
      text=text.gsub('LATEST_FEATURE=F12_ALIAS_GUARD+VXRD_PALETTE_WATER_PAIR+GROUND_DECOR','LATEST_FEATURE=VXRD_HUNT_STYLE_WATER_BANK+ROOM_TYPES+ROOM_RUNTIME')
      text=text.gsub('NEXT_TARGET=VXRD_ROOM_TYPES+TREASURE_ROOM+RARE_NEST+ELITE_ROOM','NEXT_TARGET=VXRD_ROOM_CONTENT_QA+HUNT_RUN_REWARD_CURVE+REGION_CONTENT')
      lines=[]
      lines << ''
      lines << 'VXRD_HUNT_VISUAL_STYLE='+(v[:pass] ? 'PASS':'FAIL')
      lines << 'VXRD_HUNT_STYLE_HUNTS='+v[:hunts].to_i.to_s+'/21'
      lines << 'VXRD_WATER_HUNTS='+v[:water_hunts].to_i.to_s+'/4'
      lines << 'VXRD_WATER_SCOPE=water_biome_only'
      lines << 'VXRD_WATER_BANK=1'
      lines << 'VXRD_WATER_RIVER=0'
      lines << 'VXRD_WATER_BRIDGE=0'
      lines << 'VXRD_ROOM_TYPE_AUTHORITY='+(t[:pass] ? 'PASS':'FAIL')
      lines << 'VXRD_ROOM_RUNTIME='+(x[:pass] ? 'PASS':'FAIL')
      lines << 'VXRD_ROOM_RUNTIME_API='+x[:api].to_i.to_s+'/3'
      lines << 'VXRD_TREASURE_EXISTING_LOOT=1'
      lines << 'VXRD_RARE_NEST_ACTIVE_POOL_PRESERVED=1'
      lines << 'VXRD_ELITE_ROOM_FORCE_ONE=1'
      File.open(PROJECT_STATE_FILE_V10564,'wb'){|io|io.write(text.rstrip+"\r\n"+lines.join("\r\n")+"\r\n")}
      true
    rescue
      false
    end

    def vxrd_autotest_presets_v10586
      [
        {:label=>'H01 林緣｜牆體＋裝飾',:code=>'H01',:mode=>:event,:seed=>1060301},
        {:label=>'H02 苔溪｜專用水域＋乾岸',:code=>'H02',:mode=>:event,:seed=>1060302},
        {:label=>'H05 月影｜無水秘境＋裝飾',:code=>'H05',:mode=>:event,:seed=>1060305},
        {:label=>'H09 回聲洞窟｜Room Type',:code=>'H09',:mode=>:event,:seed=>1060309},
        {:label=>'H12 霜湖｜中期水域＋Room',:code=>'H12',:mode=>:event,:seed=>1060312},
        {:label=>'H15 幽光神殿｜秘境 Room',:code=>'H15',:mode=>:event,:seed=>1060315},
        {:label=>'H21 裂隙聖域｜終盤 Room',:code=>'H21',:mode=>:event,:seed=>1060321},
        {:label=>'H01 林緣｜步數遭遇',:code=>'H01',:mode=>:steps,:seed=>1060311}
      ]
    end

    def vxrd_content_audit_v10603
      v=vxrd_visual_style_audit_v10600;t=vxrd_room_type_audit_v10601;x=vxrd_room_runtime_audit_v10602
      {:pass=>v[:pass] && t[:pass] && x[:pass],:visual=>v,:room_types=>t,:runtime=>x}
    rescue
      {:pass=>false}
    end
  end
end
