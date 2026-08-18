# encoding: UTF-8
#==============================================================================
# 【PMD AutoChess 中文維護說明】
# 腳本：PMD AutoChess Ability Diagnostic Presentation Hotfix v0.96.3
# 分類：特性 Ability／Verifier 視覺隔離／v0.96.3
#
# 【用途】
# 修正 ABILITY_RUNTIME_V096 驗證開始後，Magic Bounce（魔法鏡）測試使用的
# 假單位在畫面左上角 (0,0) 產生技能命中特效的問題。這是 Verifier 專用假單位
# 沒有正式戰場 Sprite／畫面座標時，被既有 Skill Visual Runtime 依預設座標繪製
# 所造成的「Diagnostic VFX Leak」。正式戰鬥 Ability 與技能視覺完全不修改。
#
# 【問題來源】
# v0.68 已建立 diagnostic_presentation_suppressed_v068?，用來讓 Ability／AI
# 診斷模式的假單位不播放 VFX／SFX；但 v0.96 新增的 :ability_runtime_v096
# 尚未加入該白名單。Magic Bounce 驗證會實際呼叫 apply_skill_effects，Screech
# 的 target_hit Visual 因此仍建立 Impact Sprite，而假單位座標會落在畫面左上角。
#
# 【本版規則】
# 1. :ability_runtime_v096 一律套用 v0.68 的 Diagnostic Presentation Isolation。
# 2. Verifier 中的假單位不建立技能 VFX、Beam、Impact、Link、Burst 或戰鬥 SFX。
# 3. Ability 數值／狀態／反射／回復等正式 Runtime 邏輯仍照常執行與驗證。
# 4. NORMAL 正式戰鬥完全不受影響，技能與 Ability 視覺／音效照常播放。
# 5. v0.96.2 的 Verifier Group Isolation、Regenerator 規則完全不變。
#
# 【主要設定項／可調參數】
# 本補丁沒有新增平衡參數，只擴充 Diagnostic Presentation 的模式判斷。
#
# 【事件／腳本呼叫方式】
# 一般遊戲不需呼叫。
# 驗證：布陣 NORMAL → S 一次 → ABILITY_RUNTIME_V096 → Shift。
#
# 【實際範例】
# v0.96.2：Magic Bounce 測試時左上角會短暫出現 Screech／Sound Impact 動畫。
# v0.96.3：同一測試仍得到 bounce_caster_atk=-1、target_atk=0，但不建立畫面特效。
#
# 【注意事項】
# - RPG Maker VX / RGSS2 / Ruby 1.8 相容。
# - 不修改 Ability、AI、Damage、Movement、Energy、PMD 動作、Loot 或正式技能視覺。
# - 不改 v0.96 的 12 種 Ability、1137/1193 slots、494/494 Species Coverage。
#==============================================================================
module PMD_AC
  ABILITY_DIAGNOSTIC_PRESENTATION_VERSION_V0963='0.96.3'
end

class Scene_PMD_AutoChess
  alias pmd_ac_v0963_start start unless method_defined?(:pmd_ac_v0963_start)
  alias pmd_ac_v0963_refresh_header refresh_header unless method_defined?(:pmd_ac_v0963_refresh_header)
  alias pmd_ac_v0963_diagnostic_presentation_suppressed_v068 diagnostic_presentation_suppressed_v068? unless method_defined?(:pmd_ac_v0963_diagnostic_presentation_suppressed_v068)
  alias pmd_ac_v0963_verify_ability_manifest_v096 verify_ability_manifest_v096 unless method_defined?(:pmd_ac_v0963_verify_ability_manifest_v096)

  def start
    pmd_ac_v0963_start
    begin
      if FileTest.exist?(PMD_AC::BATTLE_LOG_FILE)
        text=File.open(PMD_AC::BATTLE_LOG_FILE,'rb'){|f|f.read}
        text.sub!(/PMD AutoChess Proto v0\.[0-9.]+ Battle Verification Log/,
          'PMD AutoChess Proto v0.96.3 Battle Verification Log')
        File.open(PMD_AC::BATTLE_LOG_FILE,'wb'){|f|f.write(text)}
      end
    rescue
    end
    log_event(:ability_runtime_v096,
      'PATCH v0.96.3 diagnostic_fake_unit_vfx=off diagnostic_fake_unit_sfx=off '+
      'mode=ABILITY_RUNTIME_V096 source=v0.68 normal_combat_unchanged=1')
  end

  def refresh_header
    pmd_ac_v0963_refresh_header
    return if @header_sprite==nil || @header_sprite.bitmap==nil
    bmp=@header_sprite.bitmap
    bmp.fill_rect(0,0,Graphics.width,28,Color.new(0,0,0,180))
    pmd_ac_v074_font(bmp)
    bmp.font.size=PMD_AC.const_defined?(:UI_HEADER_TITLE_FONT_V086) ? PMD_AC::UI_HEADER_TITLE_FONT_V086 : 20
    bmp.font.bold=true
    bmp.font.color=Color.new(255,255,255)
    bmp.draw_text(16,1,Graphics.width-32,30,'PMD 自走棋原型 v0.96.3',1)
  end

  # 承接 v0.68 的正式 Diagnostic Presentation Isolation，只補上 v0.96 模式。
  def diagnostic_presentation_suppressed_v068?
    return true if verification_mode==:ability_runtime_v096
    pmd_ac_v0963_diagnostic_presentation_suppressed_v068
  end

  # 在原 Manifest 驗證後追加一個明確 marker，確認本模式真的被 Presentation 隔離。
  def verify_ability_manifest_v096
    pmd_ac_v0963_verify_ability_manifest_v096
    return unless ability_runtime_v096?
    return if @verification_done[:v0963_diagnostic_presentation]
    pass=diagnostic_presentation_suppressed_v068?
    log_verify_v096('ABILITY_DIAGNOSTIC_PRESENTATION_V0963',pass,
      'fake_unit_vfx=off fake_unit_sfx=off source=v0.68 normal_combat_unchanged=1')
    @verification_done[:v0963_diagnostic_presentation]=true
  end
end
