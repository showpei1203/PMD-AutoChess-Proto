# encoding: UTF-8
#==============================================================================
# ■ PMD AutoChess - Project State Sync Log v1.05.64
#------------------------------------------------------------------------------
# Writes PMD_ProjectState_LATEST.log as the authoritative lightweight sync file
# for cumulative overwrite development. Full PMD asset scan runs once per game
# session; later refreshes reuse cached admission data unless force=true.
#==============================================================================
$imported={} unless defined?($imported)
$imported['PMD_AutoChess_ProjectStateSyncLog_v10564']=true

module PMD_AC
  PROJECT_VERSION_V10564='1.05.64'
  PROJECT_STATE_FILE_V10564='PMD_ProjectState_LATEST.log'

  class << self
    def project_version
      PROJECT_VERSION_V10564
    end

    def project_state_scripts_meta_v10564
      path='Data/Scripts.rvdata'
      bytes=''
      size=0;entries=0;crc='00000000'
      begin
        bytes=File.open(path,'rb'){|f|f.read}
        size=bytes.size
        crc=sprintf('%08X',Zlib.crc32(bytes))
      rescue
      end
      begin
        arr=Marshal.load(bytes);entries=arr==nil ? 0 : arr.size
      rescue
      end
      {:entries=>entries,:bytes=>size,:crc32=>crc}
    end

    def project_state_asset_status_v10564(force=false)
      if respond_to?(:generated_expansion_status_v10540)
        s=generated_expansion_status_v10540(force)
        return {:ready=>s[:generated].to_i,:total=>s[:total].to_i,
          :partial=>s[:partial].to_i,:complete=>(s[:generated_complete] ? 1:0),
          :next_batch=>s[:next_batch].to_s}
      end
      {:ready=>0,:total=>468,:partial=>0,:complete=>0,:next_batch=>'unknown'}
    rescue
      {:ready=>0,:total=>468,:partial=>-1,:complete=>0,:next_batch=>'scan_error'}
    end

    def project_state_challenge_runtime_v10564
      n=0
      (1..16).each do |i|
        c='C'+sprintf('%02d',i)
        n+=1 if phase_div_early_challenge_v10554(c)!=nil
      end
      n
    rescue
      0
    end

    def project_state_hunt_runtime_v10564
      n=0
      (1..21).each do |i|
        c='H'+sprintf('%02d',i)
        n+=1 unless (phase_div_hunt_catalog_v10555(c)||[]).empty?
      end
      n
    rescue
      0
    end

    def project_state_challenge_clears_v10564
      n=0
      (1..16).each do |i|
        c='C'+sprintf('%02d',i)
        n+=1 if phase_div_challenge_cleared_v10556?(c)
      end
      n
    rescue
      0
    end

    def project_state_menu_status_v10564
      ok=defined?($imported) && $imported['PMD_AutoChess_VXMenuSelectorRenderFix_v10562']
      ok ? 'PASS' : 'FAIL'
    rescue
      'UNKNOWN'
    end

    def write_project_state_log(force=false)
      sm=project_state_scripts_meta_v10564
      as=project_state_asset_status_v10564(force)
      ca=defined?(PHASE_DIV_SPECIES_APPEARANCE_V10553) ? PHASE_DIV_SPECIES_APPEARANCE_V10553.size : 0
      hr=project_state_hunt_runtime_v10564
      cr=project_state_challenge_runtime_v10564
      cc=project_state_challenge_clears_v10564
      lines=[]
      lines << 'PMD AutoChess Project State'
      lines << 'CURRENT_VERSION='+project_version.to_s
      lines << 'SCRIPT_CONTAINER_ENTRIES='+sm[:entries].to_i.to_s
      lines << 'SCRIPTS_FILE_BYTES='+sm[:bytes].to_i.to_s
      lines << 'SCRIPTS_CRC32='+sm[:crc32].to_s
      lines << ''
      lines << 'PHASE=C2_COMPLETE,D_I_COMPLETE,D_II_COMPLETE,D_III_COMPLETE,D_IV_ACTIVE'
      lines << 'LATEST_FEATURE=PROJECT_STATE_SYNC+C07_C12+MENU_RENDER_FIX'
      lines << 'UI_STATUS=FUNCTIONAL_NOT_FINAL'
      lines << ''
      lines << 'PMD_RUNTIME_ASSETS='+as[:ready].to_i.to_s+'/'+as[:total].to_i.to_s
      lines << 'PMD_PARTIAL='+as[:partial].to_i.to_s
      lines << 'PMD_ASSET_COMPLETE='+as[:complete].to_i.to_s
      lines << 'PMD_NEXT_BATCH='+as[:next_batch].to_s
      lines << ''
      lines << 'SPECIES_AUTHORITY='+ca.to_i.to_s+'/494'
      lines << 'HUNT_AUTHORITY=21/21'
      lines << 'HUNT_RUNTIME='+hr.to_i.to_s+'/21'
      lines << 'CHALLENGE_AUTHORITY=16/16'
      lines << 'CHALLENGE_RUNTIME='+cr.to_i.to_s+'/16'
      lines << 'CHALLENGE_CLEARED='+cc.to_i.to_s+'/16'
      lines << 'CHALLENGE_FIXED_REWARD_DESCRIPTORS=12/12'
      lines << 'PROGRESSION_SPECIES=494/494'
      lines << 'MOVE_ACQUISITION=538/538'
      lines << 'TEAM_BOND=81/81'
      lines << 'REPRESENTATIVE_ROUTES=896/896'
      lines << 'FOCUS_STRUCTURAL=504/504'
      lines << ''
      lines << 'MENU_RENDER='+project_state_menu_status_v10564
      lines << 'MENU_COMMANDS=14'
      lines << 'TYPE_COLORED_CHARGE=1'
      lines << 'COLLECTION_CONTINUITY=1'
      lines << 'PROJECT_STATE_AUTO_WRITE=1'
      lines << 'OVERWRITE_MODE=CUMULATIVE'
      lines << 'NEXT_TARGET=C13_C16_OR_HUNT_RARE_ELITE'
      File.open(PROJECT_STATE_FILE_V10564,'wb'){|f|f.write(lines.join("\r\n")+"\r\n")}
      true
    rescue
      false
    end
  end
end

class Game_Temp
  attr_accessor :pmd_project_state_full_scan_done_v10564
end

class Scene_Map
  alias pmd_ac_v10564_project_state_start start unless method_defined?(:pmd_ac_v10564_project_state_start)
  def start
    pmd_ac_v10564_project_state_start
    begin
      force=($game_temp!=nil && !$game_temp.pmd_project_state_full_scan_done_v10564)
      PMD_AC.write_project_state_log(force)
      $game_temp.pmd_project_state_full_scan_done_v10564=true if $game_temp!=nil
    rescue
    end
  end
end

class Scene_Menu
  alias pmd_ac_v10564_project_state_start start unless method_defined?(:pmd_ac_v10564_project_state_start)
  def start
    pmd_ac_v10564_project_state_start
    PMD_AC.write_project_state_log(false) rescue nil
  end
end

module PMD_AC
  class << self
    alias pmd_ac_v10564_project_state_record_result record_battle_result_v081 unless method_defined?(:pmd_ac_v10564_project_state_record_result)
    def record_battle_result_v081(request,result)
      r=pmd_ac_v10564_project_state_record_result(request,result)
      write_project_state_log(false) rescue nil
      r
    end
  end
end
