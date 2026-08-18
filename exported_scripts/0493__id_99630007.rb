#==============================================================================
# ■ PMD AutoChess Focus Cast Z-Order Authority v1.05.9
#------------------------------------------------------------------------------
# 【用途】
#   修正 v1.05.8 Focus Cast Action Lane 中，傷害數字可能覆蓋在施放者頭頂
#   技能名稱 Banner 上方的視覺層級問題。
#
# 【主要機制】
#   1. 只有目前 Full Focus / Action Lane 的施放者取得技能 Banner 高層級。
#   2. Focus owner 的舊式 108x24 技能 Banner 固定為 Z=19990。
#   3. Focus Overlay 維持 Z=20000，因此 Banner 仍受遮罩透明洞的鏡頭語言約束。
#   4. 傷害 Popup、狀態 UI、一般單位 UI 全部維持既有 Z 計算。
#   5. Focus 完成後移除優先旗標，下一次 update_position 自動回復舊排序。
#
# 【可調參數】
#   FOCUS_CAST_SKILL_BANNER_Z_V1059 = 19990
#     - Focus owner 技能文字的固定 Z。
#   FOCUS_CAST_OVERLAY_Z_REFERENCE_V1059 = 20000
#     - 僅作維護／驗證參考，不修改 v1.05.5 Overlay 本身。
#
# 【依賴與載入順序】
#   - 必須放在 v1.05.8「Focus Cast Action Lane」之後。
#   - 依賴既有 Sprite_PMDChessUnit#update_position。
#   - 依賴 Scene_PMD_AutoChess#focus_cast_begin_v1055 / complete_lock_v1055。
#   - 不修改 Combat Core、Damage、HP、Energy、AI、Attack Wait、Spatial。
#
# 【事件／腳本呼叫】
#   不需事件呼叫。NORMAL 戰鬥進入 Full Focus 時自動生效。
#
# 【範例】
#   水槍 Focus：
#     技能名稱 Banner Z=19990
#     Focus Overlay Z=20000
#     傷害數字沿用既有 self.z+30
#   因此 Damage Popup 不會再蓋住目前技能名稱。
#
# 【版本】v1.05.9 / 2026-08-15
#==============================================================================

module PMD_AC
  FOCUS_CAST_SKILL_BANNER_Z_V1059 = 19990
  FOCUS_CAST_OVERLAY_Z_REFERENCE_V1059 = 20000
end

class Sprite_PMDChessUnit
  alias pmd_ac_v1059_focus_z_update_position update_position unless method_defined?(:pmd_ac_v1059_focus_z_update_position)
  def update_position
    pmd_ac_v1059_focus_z_update_position
    return if @unit==nil || @skill_sprite==nil
    priority=@unit.instance_variable_get(:@focus_cast_banner_priority_v1059)
    if priority
      @skill_sprite.z=PMD_AC::FOCUS_CAST_SKILL_BANNER_Z_V1059
    end
  rescue
  end
end

class Scene_PMD_AutoChess
  alias pmd_ac_v1059_focus_z_begin focus_cast_begin_v1055 unless method_defined?(:pmd_ac_v1059_focus_z_begin)
  alias pmd_ac_v1059_focus_z_complete focus_cast_complete_lock_v1055 unless method_defined?(:pmd_ac_v1059_focus_z_complete)
  alias pmd_ac_v1059_focus_z_start_battle start_battle unless method_defined?(:pmd_ac_v1059_focus_z_start_battle)

  def focus_cast_begin_v1055(user,target)
    r=pmd_ac_v1059_focus_z_begin(user,target)
    if r && user!=nil
      user.instance_variable_set(:@focus_cast_banner_priority_v1059,true)
    end
    r
  rescue
    false
  end

  def focus_cast_complete_lock_v1055(reason)
    u=@focus_cast_owner_v1055
    r=pmd_ac_v1059_focus_z_complete(reason)
    if u!=nil
      u.instance_variable_set(:@focus_cast_banner_priority_v1059,false)
    end
    r
  rescue
    false
  end

  def start_battle
    r=pmd_ac_v1059_focus_z_start_battle
    begin
      if respond_to?(:focus_cast_action_lane_normal_v1058?) && focus_cast_action_lane_normal_v1058?
        log_event(:battle,
          'BATTLE_FOCUS_CAST_ZORDER_V1059 START skill_banner_z='+
          PMD_AC::FOCUS_CAST_SKILL_BANNER_Z_V1059.to_s+
          ' overlay_z='+PMD_AC::FOCUS_CAST_OVERLAY_Z_REFERENCE_V1059.to_s+
          ' damage_popup_below_focus_skill=1 focus_only=1 normal_ui_unchanged=1')
      end
    rescue
    end
    r
  end
end
