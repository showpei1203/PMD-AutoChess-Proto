#==============================================================================
# 【PMD AutoChess 中文維護說明】
# 腳本：PMD AutoChess Proto v0.52.1 RGSS2 Compatibility Fix
# 分類：核心戰鬥 Runtime
#
# 【用途／機制】
# 承接前序 Data／Config，實際執行戰鬥 Scene、Unit、AI、技能與呈現。
#
# 【怎麼調整】
# 一般平衡與資料調整不要直接改 Runtime；若要追加功能，建議在較後腳本 alias 原方法後擴充。
#
# 【Runtime 主要方法（查流程時可直接搜尋）】
# - clear_binding_v052 / evading_v052? / start / pursuit_bonus_v052?
#
# 【維護規則】
# - RPG Maker VX / RGSS2 / Ruby 1.8 相容。
# - instance_uid 才是 Pokémon 個體身份；Actor ID 只是容器。
# - 新增行為優先沿用既有 helper／Data 表；避免破壞已 Freeze 的舊核心。
# - 本專案新腳本也必須保留同等級的中文說明與實際範例。
#==============================================================================
#===============================================================================
# ■ PMD AutoChess Proto v0.52.1
#    RGSS2 Move Coverage IV Compatibility Fix
#-------------------------------------------------------------------------------
# Additive compatibility patch over v0.52.
#
# RPG Maker VX / RGSS2 Ruby used by this project does not expose
# Object#instance_variable_defined?. v0.52 accidentally reintroduced that
# Ruby API in three code paths:
#   1) Rapid Spin / binding cleanup checks for v0.51 Leech Seed state
#   2) Pursuit's active-evade detection
#   3) Pursuit's movement-away velocity test
#
# RGSS2 safely returns nil when an unset instance variable is read directly.
# Therefore this patch replaces all three checks with Ruby-1.8-safe nil reads.
# No move power, duration, targeting, presentation, coverage, or AI mechanics
# are changed.
#===============================================================================

class Game_PMDChessUnit
  # v0.52 compatibility override: no Object#instance_variable_defined?.
  def clear_binding_v052
    n=0
    if status?(:bound_v052)
      remove_status(:bound_v052)
      n+=1
    end
    if status?(:fire_trap_v051)
      remove_status(:fire_trap_v051)
      n+=1
    end
    if @leech_seed_frames_v051 != nil && @leech_seed_frames_v051.to_i > 0
      @leech_seed_frames_v051=0
      @leech_seed_tick_v051=0
      n+=1
    end
    @bound_style_v052=nil
    n
  end

  # v0.52 compatibility override: reading an unset ivar returns nil in RGSS2.
  def evading_v052?
    @evade_visual_frames != nil && @evade_visual_frames.to_i > 0
  end
end

class Scene_PMD_AutoChess
  alias pmd_ac_v0521_start start unless method_defined?(:pmd_ac_v0521_start)

  def start
    pmd_ac_v0521_start
    begin
      if FileTest.exist?(PMD_AC::BATTLE_LOG_FILE)
        text=File.open(PMD_AC::BATTLE_LOG_FILE,'rb'){|f|f.read}
        text.sub!(/PMD AutoChess Proto v0\.[0-9.]+ Battle Verification Log/,
                  'PMD AutoChess Proto v0.52.1 Battle Verification Log')
        File.open(PMD_AC::BATTLE_LOG_FILE,'wb'){|f|f.write(text)}
      end
    rescue
    end
    log_event(:move_coverage_iv,
      'PATCH v0.52.1 rgss2_instance_variable_defined_fix=3 '+
      'binding=direct_nil evade=direct_nil velocity=instance_variable_get '+
      'mechanics_unchanged=1')
  end

  # v0.52 compatibility override: instance_variable_get is supported by RGSS2.
  def pursuit_bonus_v052?(user,target)
    return false if user==nil || target==nil
    return true if target.respond_to?(:evading_v052?) && target.evading_v052?
    vx=target.instance_variable_get(:@velocity_x)
    vy=target.instance_variable_get(:@velocity_y)
    vx=0.0 if vx==nil
    vy=0.0 if vy==nil
    vx=vx.to_f
    vy=vy.to_f
    dx=target.pixel_x-user.pixel_x
    dy=target.pixel_y-user.pixel_y
    len=Math.sqrt(dx*dx+dy*dy)
    return false if len<0.001
    (vx*dx/len+vy*dy/len)>0.35
  end
end
