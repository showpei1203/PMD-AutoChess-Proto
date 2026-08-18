#==============================================================================
# 【PMD AutoChess 中文維護說明】
# 腳本：PMD AutoChess Proto v0.75.1
# 分類：近遠程平衡
#
# 【用途／機制】
# 處理 ENGAGED／SEPARATE／REARM、撤退速度與近戰短期追擊黏性。
#
# 【怎麼調整】
# 範例：想讓遠程更難脫離，可提高 release distance 或 rearm frames；不要直接砍所有遠程傷害。
#
# 【本腳本主要設定常數／資料表】
# - BASIC_ATTACK_HIT_SE_V0751
#
# 【Runtime 主要方法（查流程時可直接搜尋）】
# - start / play_basic_se / refresh_header
#
# 【維護規則】
# - RPG Maker VX / RGSS2 / Ruby 1.8 相容。
# - instance_uid 才是 Pokémon 個體身份；Actor ID 只是容器。
# - 新增行為優先沿用既有 helper／Data 表；避免破壞已 Freeze 的舊核心。
# - 本專案新腳本也必須保留同等級的中文說明與實際範例。
#==============================================================================
#==============================================================================
# PMD AutoChess Proto v0.75.1
# Basic Attack Hit SFX Polish
# RGSS2 / Ruby 1.8 compatible
#------------------------------------------------------------------------------
# Presentation only:
# - All successful basic attacks use one compact shared hit SE.
# - Melee and ranged basics both play it only on confirmed damage resolution.
# - Launch/cast remain silent.
# - Miss / evade / lost projectile do not play this hit SE.
# - Skill audio, damage, range, movement and AI are unchanged.
#==============================================================================
module PMD_AC
  BASIC_ATTACK_HIT_SE_V0751 = {
    :name => "PMD_MoveHit",
    :volume => 42,
    :pitch => 105
  }
end

class Scene_PMD_AutoChess
  alias pmd_ac_v0751_start start unless method_defined?(:pmd_ac_v0751_start)
  alias pmd_ac_v0751_play_basic_se play_basic_se unless method_defined?(:pmd_ac_v0751_play_basic_se)

  def start
    pmd_ac_v0751_start
    begin
      if FileTest.exist?(PMD_AC::BATTLE_LOG_FILE)
        t = File.open(PMD_AC::BATTLE_LOG_FILE,'rb'){|f| f.read}
        t.sub!(/PMD AutoChess Proto v0\.[0-9.]+ Battle Verification Log/,
               'PMD AutoChess Proto v0.75.1 Battle Verification Log')
        File.open(PMD_AC::BATTLE_LOG_FILE,'wb'){|f| f.write(t)}
      end
    rescue
    end
    log_event(:presentation,
      "PATCH v0.75.1 basic_attack_hit_se=PMD_MoveHit volume=42 pitch=105 " +
      "melee+ranged=1 launch_silent=1 miss_silent=1 projectile_lost_silent=1 mechanics_unchanged=1")
  end

  def play_basic_se(unit, stage)
    if respond_to?(:diagnostic_presentation_suppressed_v068?) && diagnostic_presentation_suppressed_v068?
      return
    end
    if stage == :hit
      PMD_AC.play_se(PMD_AC::BASIC_ATTACK_HIT_SE_V0751)
      return
    end
    pmd_ac_v0751_play_basic_se(unit, stage)
  end
  def refresh_header
    return if @header_sprite == nil
    bmp = @header_sprite.bitmap
    bmp.clear
    bmp.fill_rect(0,0,Graphics.width,68,Color.new(0,0,0,180))
    pmd_ac_v074_font(bmp)
    bmp.font.size = PMD_AC::HEADER_TITLE_FONT_V0741
    bmp.font.bold = true
    bmp.font.color = Color.new(255,255,255)
    bmp.draw_text(16,4,Graphics.width-32,24,"PMD 自走棋原型 v0.75.1",1)
    bmp.font.size = PMD_AC::HEADER_SUB_FONT_V0741
    bmp.font.bold = false
    bmp.font.color = Color.new(210,220,230)
    text = ""
    if @phase == :deploy
      text = "戰前布陣｜D 成長/技能｜S 驗證：" + verification_mode_label + "｜Shift 開戰"
    elsif @phase == :battle
      text = "AI Framework／Pixel Movement｜速度 x" + @battle_speed.to_s + "｜A 鍵切換｜B 離開"
    else
      text = "戰鬥結束｜C 回到布陣｜B 離開"
    end
    bmp.draw_text(16,33,Graphics.width-32,21,text,1)
  end

end
