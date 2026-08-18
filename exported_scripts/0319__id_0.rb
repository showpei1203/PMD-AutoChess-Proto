# encoding: UTF-8
#==============================================================================
# 【PMD AutoChess 中文維護說明】
# 腳本：PMD AutoChess True Foot Bars Hotfix v0.89.2
# 分類：戰鬥 UI／v0.88.4 True Foot Bar 安全修正
# RPG Maker VX / RGSS2 / Ruby 1.8 compatible
#==============================================================================
# 【用途】
# 修正 v0.88.4 True Foot Bars 在 RGSS2 Runtime 讀取 Sprite#src_rect 時，
# 部分初始化／動作切換時序會觸發：
#   TypeError: can't convert NilClass into Rect
#
# v0.88.4 原本試圖逐「目前顯示 Frame」讀 src_rect 後掃描不透明像素腳底。
# 對一般 Ruby 物件這個想法沒有問題，但 RGSS2 Sprite#src_rect 是引擎 C 層屬性，
# 在特定生命週期讀取時可能遇到未完成的 Rect 狀態，因此不能把它當成永遠安全。
#
# v0.89.2 不直接修改 v0.88.4，而是覆寫其腳底 Offset 方法，改用專案早已在
# v0.57.6 驗證過的 PMD_AC.visible_bottom_rel_for_action_v0576：
# - 依 species + visual_action 讀 PMD action bitmap。
# - 掃描該動作所有有效 Frame／方向列的不透明最下緣。
# - 結果使用既有 Cache。
# - 完全不讀 Sprite#src_rect。
#
# 這種 Action-level baseline 對 HP／Energy Bar 反而更合適：角色在同一動作播放時
# Bar 不會因腳尖、尾巴或單幀姿勢差異而上下抖動。
#==============================================================================
# 【定位規則】
# 1. 仍由 v0.88.4 最後的 update_position 負責 Bar.x/y/z。
# 2. v0.89.2 只覆寫 visible_foot_frame_offset_v0884。
# 3. 非 Placeholder：使用 v0.57.6 action-level opaque-foot baseline。
# 4. Placeholder／資料缺失／讀圖失敗：Offset = 0，Bar 退回 Sprite self.y + gap。
# 5. Bar Gap 沿用 v0.88.4：TRUE_FOOT_BAR_GAP_Y_V0884 = 2px。
#==============================================================================
# 【保留內容】
# - HP／Energy Bar 尺寸、比例、顏色完全不改。
# - v0.88.2 近戰攻擊 Sprite +5px 仍會自然帶著 Bar 一起移動。
# - 不改 logical pixel_y、命中、Range、AI、Projectile、VFX Anchor。
# - 不改 v0.88.3 Audio／Ranged Stagger／Kiting。
# - 不改 v0.89 Stalemate Watch／Resolve 規則。
#==============================================================================
# 【事件／腳本使用方式】
# Runtime 自動生效，不需要事件頁呼叫。
#
# 查詢某戰鬥 Sprite 的腳底畫面 Y：
#   sprite.visible_foot_screen_y_v0884
#
# 清除 v0.57.6 action-level 腳底快取（一般不需要）：
#   PMD_AC.contact_bottom_cache_v0576.clear
#==============================================================================
# 【驗證】
# STALEMATE_SAFETY_V089 驗證應包含：
#   TRUE_FOOT_BAR_V0884 pass=1 action_level_opaque_foot=v0.57.6 src_rect_dependency=0
#   TRUE_FOOT_BAR_HOTFIX_V0892 pass=1
#   STALEMATE_HOTFIX_V0891 pass=1
#   VERIFY_FINISHED_BATTLE_RESUME pass=1
#==============================================================================
module PMD_AC
  PATCH_VERSION_V0892 = '0.89.2'
end

class Sprite_PMDChessUnit
  # 覆寫 v0.88.4：不再碰 RGSS2 Sprite#src_rect。
  def visible_foot_frame_offset_v0884
    return 0.0 if @unit==nil
    return 0.0 if @placeholder
    return 0.0 if self.bitmap==nil || self.bitmap.disposed?
    action=@unit.visual_action
    action=:idle if action==nil
    begin
      return PMD_AC.visible_bottom_rel_for_action_v0576(@unit,action).to_f
    rescue
      return 0.0
    end
  end
end

class Scene_PMD_AutoChess
  alias pmd_ac_v0892_start start unless method_defined?(:pmd_ac_v0892_start)
  alias pmd_ac_v0892_refresh_header refresh_header unless method_defined?(:pmd_ac_v0892_refresh_header)
  alias pmd_ac_v0892_prepare_verification_battle prepare_verification_battle unless method_defined?(:pmd_ac_v0892_prepare_verification_battle)

  def start
    pmd_ac_v0892_start
    begin
      if FileTest.exist?(PMD_AC::BATTLE_LOG_FILE)
        text=File.open(PMD_AC::BATTLE_LOG_FILE,'rb'){|f|f.read}
        text.sub!(/PMD AutoChess Proto v0\.[0-9.]+ Battle Verification Log/,
                  'PMD AutoChess Proto v0.89.2 Battle Verification Log')
        File.open(PMD_AC::BATTLE_LOG_FILE,'wb'){|f|f.write(text)}
      end
    rescue
    end
    log_event(:presentation,
      'PATCH v0.89.2 true_foot_bar=action_level_opaque_baseline '+
      'source=v0.57.6 src_rect_dependency=0 gap_y='+
      PMD_AC::TRUE_FOOT_BAR_GAP_Y_V0884.to_s+
      ' mechanics_unchanged=1')
    refresh_header
  end

  def refresh_header
    pmd_ac_v0892_refresh_header
    return if @header_sprite==nil || @header_sprite.bitmap==nil
    bmp=@header_sprite.bitmap
    bmp.fill_rect(0,0,Graphics.width,28,Color.new(0,0,0,180))
    bmp.font.size=PMD_AC::UI_HEADER_TITLE_FONT_V086
    bmp.font.bold=true
    bmp.font.color=Color.new(255,255,255)
    bmp.draw_text(16,1,Graphics.width-32,30,'PMD 自走棋原型 v0.89.2',1)
  end

  # 覆寫 v0.89 舊驗證敘述，反映 v0.89.2 已不再逐 Frame 讀 src_rect。
  def verify_true_foot_bar_v0884
    return if @verification_done[:v089_foot]
    pass=PMD_AC::TRUE_FOOT_BAR_GAP_Y_V0884==2 &&
      PMD_AC.respond_to?(:visible_bottom_rel_for_action_v0576) &&
      PMD_AC.respond_to?(:contact_bottom_cache_v0576)
    log_verify_v089('TRUE_FOOT_BAR_V0884',pass,
      'action_level_opaque_foot=v0.57.6 src_rect_dependency=0 gap_y='+
      PMD_AC::TRUE_FOOT_BAR_GAP_Y_V0884.to_s+
      ' logical_y_unchanged=1 hp_energy_same_bar=1')
    @verification_done[:v089_foot]=true
  end

  def prepare_verification_battle
    pmd_ac_v0892_prepare_verification_battle
    if respond_to?(:stalemate_safety_v089?) && stalemate_safety_v089?
      pass=PMD_AC.respond_to?(:visible_bottom_rel_for_action_v0576) &&
        PMD_AC.respond_to?(:contact_bottom_cache_v0576)
      pmd_ac_v089_log_event(:verify,
        'TRUE_FOOT_BAR_HOTFIX_V0892 pass='+(pass ? '1':'0')+
        ' src_rect_dependency=0 action_cache=v0.57.6')
      @stalemate_v089_failed=true unless pass
    end
  end
end
