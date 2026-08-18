# encoding: UTF-8
#===============================================================================
# ■ PMD AutoChess - Project State Schema 18 / Hunt Unlock + Retreat v1.06.30
#===============================================================================
$imported={} unless defined?($imported)
$imported['PMD_AutoChess_ProjectStateSchema18_HuntUnlockRetreat_v10630']=true

module PMD_AC
  class << self
    alias pmd_ac_v10630_write_project_state_log write_project_state_log unless method_defined?(:pmd_ac_v10630_write_project_state_log)

    def project_version
      '1.06.30'
    end

    def write_project_state_log(force=false)
      r=pmd_ac_v10630_write_project_state_log(force)
      return false unless r
      audit=hunt_sequential_unlock_audit_v10629 rescue {:pass=>false,:api=>0}
      clears=hunt_clear_counts_v10629 rescue {}
      unlocked=[]
      (1..21).each do |i|
        c='H'+sprintf('%02d',i)
        st=hunt_unlock_state_v10629(c) rescue {:unlocked=>false}
        unlocked << c if st[:unlocked]
      end
      next_code=nil
      (1..20).each do |i|
        c='H'+sprintf('%02d',i)
        n='H'+sprintf('%02d',i+1)
        if hunt_clear_count_v10629(c)>0 && hunt_clear_count_v10629(n)<=0
          next_code=n
          break
        end
      end
      text='';File.open(PROJECT_STATE_FILE_V10564,'rb'){|io|text=io.read}
      text=text.gsub(/PROJECT_STATE_SCHEMA=\d+/,'PROJECT_STATE_SCHEMA=18')
      text=text.gsub(/CURRENT_VERSION=[^\r\n]+/,'CURRENT_VERSION=1.06.30')
      text=text.gsub(/LATEST_FEATURE=[^\r\n]+/,'LATEST_FEATURE=HUNT_SEQUENTIAL_UNLOCK+RETREAT_UX+VXRD_WINDOWS_ACCEPTANCE')
      text=text.gsub(/NEXT_TARGET=[^\r\n]+/,'NEXT_TARGET=VXRD_WINDOWS_INTEGRATED_ACCEPTANCE')
      text=text.gsub(/\r?\nHUNT_UNLOCK_RETREAT_V10630_BEGIN.*?HUNT_UNLOCK_RETREAT_V10630_END\r?\n/m,"\r\n")
      clear_rows=clears.keys.sort.find_all{|c|clears[c].to_i>0}.collect{|c|c+':'+clears[c].to_i.to_s}
      lines=[]
      lines << ''
      lines << 'HUNT_UNLOCK_RETREAT_V10630_BEGIN'
      lines << 'HUNT_SEQUENTIAL_UNLOCK='+(audit[:pass] ? 'PASS':'FAIL')
      lines << 'HUNT_UNLOCK_POLICY=PREVIOUS_HUNT_FULL_CLEAR'
      lines << 'HUNT_CLEAR_COUNTS='+(clear_rows.empty? ? 'NONE':clear_rows.join(','))
      lines << 'HUNT_UNLOCKED_NOW='+unlocked.size.to_i.to_s+'/21'
      lines << 'HUNT_UNLOCKED_CODES='+unlocked.join(',')
      lines << 'HUNT_NEXT_UNLOCK='+(next_code==nil ? 'NONE':next_code)
      lines << 'H21_EXTRA_GATE=LEGENDARY_CIRCUIT_CLEAR'
      lines << 'HUNT_RETREAT_NODE=ENTRANCE_ROOM_NPC'
      lines << 'HUNT_RETREAT_API=PMD_AC.hunt_runtime_retreat_v10605'
      lines << 'HUNT_RETREAT_KEEPS_IMMEDIATE_REWARDS=1'
      lines << 'HUNT_RETREAT_COMPLETION_BONUS=0'
      lines << 'HUNT_UNLOCK_RETREAT_V10630_END'
      File.open(PROJECT_STATE_FILE_V10564,'wb'){|io|io.write(text.rstrip+"\r\n"+lines.join("\r\n")+"\r\n")}
      true
    rescue
      false
    end
  end
end
