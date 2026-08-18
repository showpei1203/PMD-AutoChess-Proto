#==============================================================================
# PMD AutoChess Proto v0.83.1
# Reward / Loot 驗證計時修正
#==============================================================================
# 【用途】
# 修正 v0.83「REWARD_LOOT_V083」驗證模式啟動後，驗證 frame 不會增加的問題。
# v0.83 的 Reward / Loot 遊戲機制本身不在本腳本修改範圍內；本腳本只修驗證器。
#
# 【問題原因】
# v0.83 重寫 Scene_PMD_AutoChess#update_verification_script 時，在
# :reward_loot_v083 模式下沒有呼叫舊 verifier chain，也沒有自行執行：
#   @verification_frame += 1
# 因此畫面雖然顯示驗證模式已開始，frame 永遠停在 0，所有 frame 2/4/6...
# 的斷言都不會執行。
#
# 【本版修正】
# - 只有 :reward_loot_v083 模式改由本腳本自行推進 verification frame。
# - 直接重用 v0.83 已存在的六組驗證方法，不複製 Reward/Loot Runtime。
# - 其他 25 種舊驗證模式仍走原 alias chain，完全不改。
# - 完成後仍必須出現：
#     VERIFY_FINISHED_BATTLE_RESUME pass=1
#   才代表 AI／移動已恢復。
#
# 【玩家／開發者測試方式】
# 1. 布陣畫面按 S 切到：REWARD_LOOT_V083
# 2. 按 Shift 開戰。
# 3. LOG 應依序出現：
#    REWARD_LOOT_MANIFEST_V083 pass=1
#    REWARD_LOOT_STAGE_V083 pass=1
#    REWARD_LOOT_CONTEXT_V083 pass=1
#    REWARD_LOOT_SCHEMA_V083 pass=1
#    REWARD_LOOT_INLINE_V083 pass=1
#    REWARD_LOOT_CARRY_V083 pass=1
#    REWARD_LOOT_V083 pass=1
#    VERIFY_FINISHED_BATTLE_RESUME pass=1
#
# 【可調設定】
# 驗證結束 frame 仍使用 v0.83：
#   PMD_AC::REWARD_VERIFY_END_V083
# 一般不需要修改。
#
# 【注意】
# - RGSS2 / Ruby 1.8 相容。
# - 不使用 instance_variable_defined?。
# - 不修改 Reward table、掉落率、Gold、Item、Stage、Wild、Boss 等遊戲數值。
#==============================================================================
module PMD_AC
  REWARD_VERIFIER_PATCH_V0831 = true
end

class Scene_PMD_AutoChess
  alias pmd_ac_v0831_update_verification_script update_verification_script unless method_defined?(:pmd_ac_v0831_update_verification_script)

  def update_verification_script
    unless reward_loot_v083?
      pmd_ac_v0831_update_verification_script
      return
    end

    @verification_frame = @verification_frame.to_i + 1
    f = @verification_frame
    verify_reward_loot_manifest_v083 if f >= 2
    verify_reward_loot_stage_v083 if f >= 4
    verify_reward_loot_context_v083 if f >= 6
    verify_reward_loot_schema_v083 if f >= 8
    verify_reward_loot_inline_v083 if f >= 10
    verify_reward_loot_carry_v083 if f >= 12
    if f >= 16 && !@verification_done[:v083_final]
      pass = !@reward_loot_v083_failed
      log_verify_v083('REWARD_LOOT_V083', pass,
        'manifest=1 stage=1 context=1 schema=1 inline=1 carry=1 verifier_patch=v0.83.1')
      @verification_done[:v083_final] = true
    end
    complete_verification_mode if f >= PMD_AC::REWARD_VERIFY_END_V083
  end

  alias pmd_ac_v0831_start start unless method_defined?(:pmd_ac_v0831_start)
  def start
    pmd_ac_v0831_start
    log_event(:reward_loot,
      'PATCH v0.83.1 verifier_frame_tick=restored reward_runtime=v0.83_unchanged')
  end
end

class Scene_PMD_AutoChess
  alias pmd_ac_v0831_refresh_header refresh_header unless method_defined?(:pmd_ac_v0831_refresh_header)
  def refresh_header
    pmd_ac_v0831_refresh_header
    return if @header_sprite==nil || @header_sprite.bitmap==nil
    bmp=@header_sprite.bitmap
    bmp.fill_rect(0,0,Graphics.width,28,Color.new(0,0,0,180))
    pmd_ac_v074_font(bmp)
    bmp.font.size=PMD_AC::HEADER_TITLE_FONT_V0741
    bmp.font.bold=true
    bmp.font.color=Color.new(255,255,255)
    bmp.draw_text(16,4,Graphics.width-32,24,'PMD 自走棋原型 v0.83.1',1)
  end
end
