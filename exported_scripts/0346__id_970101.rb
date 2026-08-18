#===============================================================================
# PMD AutoChess Ability Trap Verifier Slot Hotfix v0.97.1
#===============================================================================
#【用途】
# 修正 v0.97「最後 12 種 Ability」驗證模式中，Arena Trap（沙穴）測試單位
# 錯誤使用 Diglett 的 primary Ability Slot，導致實際拿 Sand Veil（沙隱）測試
# Arena Trap，造成 ABILITY_TRAP_RUNTIME_V097 假性 pass=0。
#
#【主要設定項】
# 本補丁沒有新的遊戲平衡參數。唯一修正是：
#   Diglett 驗證單位：primary -> secondary
# 因 Species DB 的正式資料為：
#   primary   = sand_veil
#   secondary = arena_trap
#   hidden    = sand_force
#
#【機制規則】
# 1. 只在 verification_mode == :ability_runtime_v097 時攔截 v097_unit。
# 2. 只有 species=:diglett 且 verifier 傳入 slot=:primary 時，改用 :secondary。
# 3. NORMAL 正式戰鬥、Species DB、Ability Slot、Arena Trap Runtime 完全不修改。
# 4. 原 v0.97 的 Magnet Pull／Shadow Tag／Suction Cups 等正式行為全部沿用。
# 5. frame=4 完成 Trap 驗證後，另外寫出實際 Diglett secondary Ability key，
#    讓 LOG 可以直接反查 Verifier 是否使用正確 Slot。
#
#【可調參數】
# 無。此腳本是驗證器修正，不應拿來調整 Arena Trap 半徑或其他戰鬥數值。
# Arena Trap／Magnet Pull／Shadow Tag 的正式半徑仍由 v0.97 Data Script 管理。
#
#【事件／腳本呼叫方式】
# 一般事件不需要呼叫本腳本。
# 測試方式：Scene_PMD_AutoChess 的 NORMAL 模式按 S 切到
# ABILITY_RUNTIME_V097，再按 Shift 執行 Verifier。
#
#【實際範例】
# 預期 LOG：
#   ABILITY_TRAP_RUNTIME_V097 pass=1 arena=1 magnet_steel=1 shadow=1
#   ABILITY_TRAP_VERIFIER_SLOT_V0971 pass=1 diglett_slot=secondary
#     actual=arena_trap runtime_unchanged=1
#   ABILITY_RUNTIME_V097 pass=1 ... slots=1193/1193 ... remaining=0
#   VERIFY_FINISHED_BATTLE_RESUME pass=1
#
#【注意事項】
# - 不要把 Diglett 的正式 primary Ability 改成 Arena Trap；那會破壞 Canonical Data。
# - 本補丁只修 verifier fixture，不能用來改實際寶可夢的 Ability Slot。
# - 若未來 Species DB Slot 定義改動，應修改 Verifier fixture，而不是改 Runtime 規則。
#===============================================================================

module PMD_AC
  ABILITY_TRAP_VERIFIER_SLOT_HOTFIX_V0971 = true
end

class Scene_PMD_AutoChess
  alias pmd_ac_v0971_v097_unit v097_unit unless method_defined?(:pmd_ac_v0971_v097_unit)
  alias pmd_ac_v0971_update_verification_script update_verification_script unless method_defined?(:pmd_ac_v0971_update_verification_script)
  alias pmd_ac_v0971_start start unless method_defined?(:pmd_ac_v0971_start)
  alias pmd_ac_v0971_refresh_header refresh_header unless method_defined?(:pmd_ac_v0971_refresh_header)

  def v097_unit(species, slot, team, id)
    if ability_runtime_v097? && species == :diglett && slot == :primary
      slot = :secondary
    end
    pmd_ac_v0971_v097_unit(species, slot, team, id)
  end

  def update_verification_script
    pmd_ac_v0971_update_verification_script
    if ability_runtime_v097? && @verification_frame.to_i == 4 && !@v0971_trap_slot_logged
      data = PMD_AC.species_identity_data(:diglett)
      slots = data == nil ? nil : data[:ability_slots]
      actual = slots == nil ? nil : slots[:secondary]
      ok = actual == :arena_trap
      log_verify_v097('ABILITY_TRAP_VERIFIER_SLOT_V0971', ok,
        'diglett_slot=secondary actual=' + actual.to_s + ' runtime_unchanged=1')
      @v0971_trap_slot_logged = true
    end
  end

  def refresh_header
    pmd_ac_v0971_refresh_header
    return if @header_sprite == nil || @header_sprite.bitmap == nil
    b = @header_sprite.bitmap
    b.fill_rect(0, 0, Graphics.width, 28, Color.new(0, 0, 0, 180))
    pmd_ac_v074_font(b)
    b.font.size = 20
    b.font.bold = true
    b.font.color = Color.new(255, 255, 255)
    b.draw_text(16, 1, Graphics.width - 32, 30, 'PMD 自走棋原型 v0.97.1', 1)
  end

  def start
    pmd_ac_v0971_start
    begin
      if FileTest.exist?(PMD_AC::BATTLE_LOG_FILE)
        text = File.open(PMD_AC::BATTLE_LOG_FILE, 'rb') { |f| f.read }
        text.sub!(/PMD AutoChess Proto v0\.[0-9.]+ Battle Verification Log/,
          'PMD AutoChess Proto v0.97.1 Battle Verification Log')
        File.open(PMD_AC::BATTLE_LOG_FILE, 'wb') { |f| f.write(text) }
      end
    rescue
    end
    log_event(:ability_runtime_v097,
      'PATCH v0.97.1 verifier_diglett_slot=secondary actual=arena_trap runtime_unchanged=1')
    refresh_header
  end
end
