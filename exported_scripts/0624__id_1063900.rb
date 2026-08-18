# encoding: UTF-8
#===============================================================================
# ■ PMD AutoChess - Hunt Style Preview QA v1.06.39
#-------------------------------------------------------------------------------
# Temporary visual-QA access for H01-H21.
# - Hunt selector becomes a style preview selector for this QA build only.
# - All 21 Hunt maps may be entered regardless of progression unlocks.
# - Preview uses deterministic seeds and Floor 1 only.
# - Combat / treasure / recovery / floor progression are suppressed.
# - H21 borrows a temporary H20 active pool only to satisfy map-session setup;
#   no encounter may launch and no Legendary Circuit / Hunt clear state changes.
# - Retreat returns directly to the pre-preview origin without settlement rewards.
# Production progression authority is otherwise untouched and this patch is
# intended to be removed after visual acceptance.
#===============================================================================
$imported={} unless defined?($imported)
$imported['PMD_AutoChess_HuntStylePreviewQA_v10639']=true

class Game_Temp
  attr_accessor :pmd_hunt_style_preview_pending_v10639
end

module PMD_AC
  HUNT_STYLE_PREVIEW_CODES_V10639=(1..21).collect{|i|'H'+sprintf('%02d',i)}
  HUNT_STYLE_PREVIEW_PRIORITY_V10639=['H01','H02','H03','H04','H05','H09','H12','H14','H15','H17','H18','H19','H20','H21']

  class << self
    def hunt_style_preview_pending_v10639
      return nil if $game_temp==nil
      p=$game_temp.pmd_hunt_style_preview_pending_v10639
      p.is_a?(Hash) ? p : nil
    rescue
      nil
    end

    def hunt_style_preview_active_v10639?
      s=hunt_runtime_session_v10605 rescue nil
      s!=nil && s[:style_preview_v10639] && $game_map!=nil &&
        $game_map.map_id.to_i==VXRD_HUNT_RUNTIME_MAP_ID_V10604
    rescue
      false
    end

    def hunt_style_preview_seed_v10639(code)
      n=code.to_s.upcase.sub('H','').to_i
      1063900+n*101
    rescue
      1063901
    end

    def phase_div_start_hunt_style_preview_v10639(code)
      return false if $game_temp==nil
      c=code.to_s.upcase
      return false unless HUNT_STYLE_PREVIEW_CODES_V10639.include?(c)
      seed=hunt_style_preview_seed_v10639(c)
      $game_temp.pmd_hunt_style_preview_pending_v10639={:code=>c,:seed=>seed}
      ok=start_hunt_dungeon_v10604(c,:event,seed)
      $game_temp.pmd_hunt_style_preview_pending_v10639=nil unless ok
      ok
    rescue
      $game_temp.pmd_hunt_style_preview_pending_v10639=nil if $game_temp!=nil
      false
    end

    # H21 has no production spawn catalog before Legendary Circuit clears.
    # In style preview only, bypass that launch gate so the map shell can exist.
    alias pmd_ac_v10639_hunt_runtime_launch_gate_v10626 hunt_runtime_launch_gate_v10626 unless method_defined?(:pmd_ac_v10639_hunt_runtime_launch_gate_v10626)
    def hunt_runtime_launch_gate_v10626(code)
      c=code.to_s.upcase
      p=hunt_style_preview_pending_v10639
      if p!=nil && p[:code].to_s.upcase==c && HUNT_STYLE_PREVIEW_CODES_V10639.include?(c)
        return {:pass=>true,:code=>c,:reason=>:style_preview_v10639,:catalog=>0}
      end
      pmd_ac_v10639_hunt_runtime_launch_gate_v10626(code)
    rescue
      {:pass=>false,:code=>code.to_s.upcase,:reason=>:gate_error,:catalog=>0}
    end

    # H21 needs a non-empty session active pool because the legacy Hunt session
    # constructor rejects empty pools. Borrow H20 only as inert fixture data.
    alias pmd_ac_v10639_phase_div_build_active_pool_v10555 phase_div_build_active_pool_v10555 unless method_defined?(:pmd_ac_v10639_phase_div_build_active_pool_v10555)
    def phase_div_build_active_pool_v10555(code,seed)
      c=code.to_s.upcase
      p=hunt_style_preview_pending_v10639
      if c=='H21' && p!=nil && p[:code].to_s.upcase=='H21'
        return pmd_ac_v10639_phase_div_build_active_pool_v10555('H20',seed)
      end
      pmd_ac_v10639_phase_div_build_active_pool_v10555(code,seed)
    rescue
      []
    end

    # Mark the session before the generated floor is populated so every later
    # event handler can recognize that this is a side-effect-free visual run.
    alias pmd_ac_v10639_hunt_enter hunt_enter unless method_defined?(:pmd_ac_v10639_hunt_enter)
    def hunt_enter(code,seed=nil)
      s=pmd_ac_v10639_hunt_enter(code,seed)
      p=hunt_style_preview_pending_v10639
      if s!=nil && p!=nil && p[:code].to_s.upcase==code.to_s.upcase
        s[:style_preview_v10639]=true
        s[:style_preview_seed_v10639]=p[:seed].to_i
        s[:style_preview_original_code_v10639]=code.to_s.upcase
      end
      s
    rescue
      nil
    end

    alias pmd_ac_v10639_hunt_runtime_generate_after_transfer_v10604 hunt_runtime_generate_after_transfer_v10604 unless method_defined?(:pmd_ac_v10639_hunt_runtime_generate_after_transfer_v10604)
    def hunt_runtime_generate_after_transfer_v10604
      p=hunt_style_preview_pending_v10639
      ok=pmd_ac_v10639_hunt_runtime_generate_after_transfer_v10604
      if ok && p!=nil
        s=hunt_runtime_session_v10605 rescue nil
        if s!=nil && s[:style_preview_v10639]
          s[:vxrd_max_floors_v10604]=1
          hunt_runtime_message_v10604([
            'Hunt Style Preview｜'+s[:code].to_s,
            ((phase_div_hunt_v10553(s[:code])||{})[:name]||'').to_s+'｜Floor 1 視覺 QA',
            '戰鬥／寶藏／Recovery／下一層皆停用，不影響正式進度。',
            '看完請回入口使用「撤退」返回原地。'
          ]) rescue nil
        end
      end
      $game_temp.pmd_hunt_style_preview_pending_v10639=nil if $game_temp!=nil
      ok
    rescue
      $game_temp.pmd_hunt_style_preview_pending_v10639=nil if $game_temp!=nil
      false
    end

    # Combat paths: consume nothing and launch nothing.
    alias pmd_ac_v10639_hunt_room_encounter_v10602 hunt_room_encounter_v10602 unless method_defined?(:pmd_ac_v10639_hunt_room_encounter_v10602)
    def hunt_room_encounter_v10602(room_type=nil)
      if hunt_style_preview_active_v10639?
        hunt_runtime_message_v10604(['風格 QA｜Encounter 停用','此版本只用來檢查地圖素材與配置。']) rescue nil
        return true
      end
      pmd_ac_v10639_hunt_room_encounter_v10602(room_type)
    rescue
      false
    end

    alias pmd_ac_v10639_phase_div_launch_hunt_encounter_v10555 phase_div_launch_hunt_encounter_v10555 unless method_defined?(:pmd_ac_v10639_phase_div_launch_hunt_encounter_v10555)
    def phase_div_launch_hunt_encounter_v10555
      return true if hunt_style_preview_active_v10639?
      pmd_ac_v10639_phase_div_launch_hunt_encounter_v10555
    rescue
      false
    end

    # Node interactions are deliberately side-effect-free during visual QA.
    alias pmd_ac_v10639_vxrd_runtime_treasure_event_v10606 vxrd_runtime_treasure_event_v10606 unless method_defined?(:pmd_ac_v10639_vxrd_runtime_treasure_event_v10606)
    def vxrd_runtime_treasure_event_v10606(interpreter=nil)
      if hunt_style_preview_active_v10639?
        hunt_runtime_message_v10604(['風格 QA｜Treasure 停用','不取得任何道具，也不消耗正式節點紀錄。']) rescue nil
        return true
      end
      pmd_ac_v10639_vxrd_runtime_treasure_event_v10606(interpreter)
    rescue
      false
    end

    alias pmd_ac_v10639_vxrd_runtime_recovery_event_v10606 vxrd_runtime_recovery_event_v10606 unless method_defined?(:pmd_ac_v10639_vxrd_runtime_recovery_event_v10606)
    def vxrd_runtime_recovery_event_v10606(interpreter=nil)
      if hunt_style_preview_active_v10639?
        hunt_runtime_message_v10604(['風格 QA｜Recovery 停用','隊伍 HP 不會改變。']) rescue nil
        return true
      end
      pmd_ac_v10639_vxrd_runtime_recovery_event_v10606(interpreter)
    rescue
      false
    end

    # One floor is enough to verify a Hunt material profile. Do not allow a QA
    # preview to progress or accidentally reach normal completion settlement.
    alias pmd_ac_v10639_vxrd_runtime_exit_event_v10605 vxrd_runtime_exit_event_v10605 unless method_defined?(:pmd_ac_v10639_vxrd_runtime_exit_event_v10605)
    def vxrd_runtime_exit_event_v10605(interpreter=nil)
      if hunt_style_preview_active_v10639?
        hunt_runtime_message_v10604(['風格 QA｜Floor 1 Only','此區材質 Profile 已完整套用於第一層。','請回入口使用「撤退」查看下一個區域。']) rescue nil
        return true
      end
      pmd_ac_v10639_vxrd_runtime_exit_event_v10605(interpreter)
    rescue
      false
    end

    def hunt_style_preview_return_v10639
      s=hunt_runtime_session_v10605 rescue nil
      return false if s==nil || !s[:style_preview_v10639]
      origin=(s[:vxrd_origin_v10604]||{}).dup
      s[:active]=false
      begin
        st=vxrd_state_v10582
        st[:active]=false if st!=nil
      rescue
      end
      begin
        $game_system.pmd_phase_div_hunt_session_v10555=s if $game_system!=nil
      rescue
      end
      if $game_player!=nil
        mid=origin[:map_id].to_i
        mid=2 if mid<=0 || mid==VXRD_HUNT_RUNTIME_MAP_ID_V10604
        x=origin[:x].to_i;y=origin[:y].to_i;d=origin[:direction].to_i;d=2 if d<=0
        $game_player.reserve_transfer(mid,x,y,d)
        $scene=Scene_Map.new unless $scene.is_a?(Scene_Map)
      end
      true
    rescue
      false
    end

    alias pmd_ac_v10639_vxrd_runtime_retreat_event_v10605 vxrd_runtime_retreat_event_v10605 unless method_defined?(:pmd_ac_v10639_vxrd_runtime_retreat_event_v10605)
    def vxrd_runtime_retreat_event_v10605(interpreter=nil)
      return hunt_style_preview_return_v10639 if hunt_style_preview_active_v10639?
      pmd_ac_v10639_vxrd_runtime_retreat_event_v10605(interpreter)
    rescue
      false
    end

    alias pmd_ac_v10639_vxrd_runtime_info_event_v10605 vxrd_runtime_info_event_v10605 unless method_defined?(:pmd_ac_v10639_vxrd_runtime_info_event_v10605)
    def vxrd_runtime_info_event_v10605(interpreter=nil)
      if hunt_style_preview_active_v10639?
        s=hunt_runtime_session_v10605
        hunt_runtime_message_v10604([
          s[:code].to_s+' '+((phase_div_hunt_v10553(s[:code])||{})[:name]||'').to_s,
          'Style Preview｜Floor 1｜Seed '+s[:style_preview_seed_v10639].to_i.to_s,
          '所有 Gameplay Node 停用；正式 Unlock / Clear 不變。',
          '入口「撤退」返回。'
        ]) rescue nil
        return true
      end
      pmd_ac_v10639_vxrd_runtime_info_event_v10605(interpreter)
    rescue
      false
    end

    def hunt_style_preview_audit_v10639
      bad=[]
      bad << :codes unless HUNT_STYLE_PREVIEW_CODES_V10639.size==21
      bad << :priority unless HUNT_STYLE_PREVIEW_PRIORITY_V10639.size==14
      req=[:phase_div_start_hunt_style_preview_v10639,:hunt_style_preview_active_v10639?,
        :hunt_style_preview_return_v10639,:hunt_style_preview_seed_v10639]
      req.each{|m|bad << m unless respond_to?(m)}
      {:pass=>bad.empty?,:codes=>HUNT_STYLE_PREVIEW_CODES_V10639.size,
       :priority=>HUNT_STYLE_PREVIEW_PRIORITY_V10639.size,:floor_limit=>1,
       :combat=>false,:loot=>false,:recovery=>false,:progression_change=>false,:bad=>bad}
    rescue
      {:pass=>false,:codes=>0,:priority=>0,:bad=>[:audit_error]}
    end
  end
end

# This QA build intentionally turns the Hunt selector into a pure visual-preview
# launcher. It does not modify the underlying progression unlock authority.
class Scene_PMD_HuntSelectV10560 < Scene_Base
  def initialize(return_scene=nil)
    @return_scene=return_scene
  end

  def start
    super
    commands=[];@codes=[]
    PMD_AC::HUNT_STYLE_PREVIEW_CODES_V10639.each do |c|
      h=PMD_AC.phase_div_hunt_v10553(c)||{}
      tag=PMD_AC::HUNT_STYLE_PREVIEW_PRIORITY_V10639.include?(c) ? '｜優先檢查' : ''
      commands.push(c+' '+h[:name].to_s+'｜風格QA'+tag)
      @codes.push(c)
    end
    @window=Window_Command.new(Graphics.width,commands)
    @window.height=Graphics.height
    @window.create_contents
    @window.refresh if @window.respond_to?(:refresh)
    @window.index=0
  end

  def update
    super;@window.update
    if Input.trigger?(Input::B)
      Sound.play_cancel
      $game_temp.pmd_phase_div_selector_return_scene_v10560=nil if $game_temp!=nil
      $scene=@return_scene || Scene_Map.new
      return
    elsif Input.trigger?(Input::C)
      c=@codes[@window.index]
      Sound.play_decision
      $game_temp.pmd_phase_div_selector_return_scene_v10560=@return_scene if $game_temp!=nil
      ok=PMD_AC.phase_div_start_hunt_style_preview_v10639(c)
      Sound.play_buzzer unless ok
    end
  end

  def terminate
    @window.dispose if @window!=nil && !@window.disposed?
    super
  end
end

module PMD_AC
  class << self
    alias pmd_ac_v10639_write_project_state_log write_project_state_log unless method_defined?(:pmd_ac_v10639_write_project_state_log)
    def project_version
      '1.06.39'
    end
    def write_project_state_log(force=false)
      r=pmd_ac_v10639_write_project_state_log(force)
      return false unless r
      begin
        text='';File.open(PROJECT_STATE_FILE_V10564,'rb'){|io|text=io.read}
        text=text.gsub(/CURRENT_VERSION=[^\r\n]+/,'CURRENT_VERSION=1.06.39')
        text=text.gsub(/LATEST_FEATURE=[^\r\n]+/,'LATEST_FEATURE=HUNT_STYLE_PREVIEW_QA+RTP_MATERIAL_AUTHORITY_II')
        text=text.gsub(/\r?\nHUNT_STYLE_PREVIEW_V10639_BEGIN.*?HUNT_STYLE_PREVIEW_V10639_END\r?\n/m,"\r\n")
        a=hunt_style_preview_audit_v10639
        lines=[]
        lines << ''
        lines << 'HUNT_STYLE_PREVIEW_V10639_BEGIN'
        lines << 'HUNT_STYLE_PREVIEW_QA='+(a[:pass] ? 'PASS':'FAIL')
        lines << 'HUNT_STYLE_PREVIEW_CODES='+a[:codes].to_i.to_s+'/21'
        lines << 'HUNT_STYLE_PREVIEW_PRIORITY='+HUNT_STYLE_PREVIEW_PRIORITY_V10639.join(',')
        lines << 'HUNT_STYLE_PREVIEW_FLOOR_LIMIT=1'
        lines << 'HUNT_STYLE_PREVIEW_COMBAT=DISABLED'
        lines << 'HUNT_STYLE_PREVIEW_LOOT=DISABLED'
        lines << 'HUNT_STYLE_PREVIEW_RECOVERY=DISABLED'
        lines << 'HUNT_STYLE_PREVIEW_PROGRESSION_CHANGE=0'
        lines << 'HUNT_STYLE_PREVIEW_TEMPORARY=1'
        lines << 'HUNT_STYLE_PREVIEW_V10639_END'
        File.open(PROJECT_STATE_FILE_V10564,'wb'){|io|io.write(text.rstrip+"\r\n"+lines.join("\r\n")+"\r\n")}
      rescue
      end
      true
    rescue
      false
    end
  end
end
