#==============================================================================
# 【PMD AutoChess 中文維護說明】
# 腳本：PMD AutoChess Proto v0.60.1
# 分類：PMDCollab 編譯姿勢
#
# 【用途／機制】
# 讀取已編譯進 VX Script Library 的 PMDCollab 動作資料並做語意路由。
#
# 【怎麼調整】
# Runtime 不讀 XML／外部 rb；新增素材後應重新跑 compiler，再把資料編進 Scripts.rvdata。
#
# 【本腳本主要設定常數／資料表】
# - PRESENTATION_PATCH_VERSION_V0601
#
# 【Runtime 主要方法（查流程時可直接搜尋）】
# - presentation_showcase_v0553? / start / contact_multi_showcase_skill_v0601? / place_contact_multi_showcase_pair_v0601
# - force_v060_skill / verify_multi_choreo_v060
#
# 【維護規則】
# - RPG Maker VX / RGSS2 / Ruby 1.8 相容。
# - instance_uid 才是 Pokémon 個體身份；Actor ID 只是容器。
# - 新增行為優先沿用既有 helper／Data 表；避免破壞已 Freeze 的舊核心。
# - 本專案新腳本也必須保留同等級的中文說明與實際範例。
#==============================================================================
#==============================================================================
# ■ PMD AutoChess Proto v0.60.1
#    Contact Multi-Hit Showcase Range / Staging Fix
#------------------------------------------------------------------------------
# Additive patch on v0.60.
# - The v0.60 contact choreography itself did not execute in its verification
#   showcase because Triple Kick / Double Kick were still rejected by the old
#   logical melee range gate before the first damage packet.
# - Extend the existing v0.55.3 showcase-only range bypass to MULTI_CHOREO_V060.
# - Stage contact showcase pairs 60px apart on one ground-Y line so the visual
#   contact offset can actually reach the configured contact gap, making the
#   backstep -> re-engage -> hit choreography visible instead of testing it
#   across the whole board.
# - Normal battle range, AI, logical positions and all damage rules are unchanged.
#==============================================================================
module PMD_AC
  PRESENTATION_PATCH_VERSION_V0601 = "0.60.1"
end

class Game_PMDChessUnit
  alias pmd_ac_v0601_presentation_showcase_v0553 presentation_showcase_v0553? unless method_defined?(:pmd_ac_v0601_presentation_showcase_v0553)

  def presentation_showcase_v0553?
    if @scene!=nil && @scene.respond_to?(:verification_mode)
      return true if @scene.verification_mode==:multi_choreo_v060
    end
    pmd_ac_v0601_presentation_showcase_v0553
  end
end

class Scene_PMD_AutoChess
  alias pmd_ac_v0601_start start unless method_defined?(:pmd_ac_v0601_start)
  alias pmd_ac_v0601_force_v060_skill force_v060_skill unless method_defined?(:pmd_ac_v0601_force_v060_skill)
  alias pmd_ac_v0601_verify_multi_choreo_v060 verify_multi_choreo_v060 unless method_defined?(:pmd_ac_v0601_verify_multi_choreo_v060)

  def start
    pmd_ac_v0601_start
    begin
      if FileTest.exist?(PMD_AC::BATTLE_LOG_FILE)
        t=File.open(PMD_AC::BATTLE_LOG_FILE,'rb'){|f|f.read}
        t.sub!(/PMD AutoChess Proto v0\.60 Battle Verification Log/,
               'PMD AutoChess Proto v0.60.1 Battle Verification Log')
        File.open(PMD_AC::BATTLE_LOG_FILE,'wb'){|f|f.write(t)}
      end
    rescue
    end
    log_event(:presentation,
      'PATCH v0.60.1 multi_choreo_showcase_range_bypass=1 contact_demo_distance=60 '+
      'contact_demo_same_ground_y=1 normal_combat_unchanged=1')
  end

  def contact_multi_showcase_skill_v0601?(skill_key)
    d=PMD_AC.skill_data(skill_key)
    return false if d==nil
    return false unless d[:multi_hit_v049] || d[:triple_kick_v059]
    mk=d[:canonical_move_key] || d[:move_key]
    return false if mk==nil
    contact_multi_kind_v060?(d,mk)
  end

  def place_contact_multi_showcase_pair_v0601(user,target)
    return if user==nil || target==nil
    y=220.0
    user.instance_variable_set(:@pixel_x,240.0)
    user.instance_variable_set(:@pixel_y,y)
    user.instance_variable_set(:@velocity_x,0.0)
    user.instance_variable_set(:@velocity_y,0.0)
    target.instance_variable_set(:@pixel_x,300.0)
    target.instance_variable_set(:@pixel_y,y)
    target.instance_variable_set(:@velocity_x,0.0)
    target.instance_variable_set(:@velocity_y,0.0)
    target.instance_variable_set(:@hp,target.maxhp)
    target.instance_variable_set(:@dead_started,false)
    user.instance_variable_set(:@multi_contact_choreo_v060,nil)
    user.clear_presentation_motion_v055 if user.respond_to?(:clear_presentation_motion_v055)
    log_event(:multi_choreo,
      'SHOWCASE_PAIR '+user.log_name+' -> '+target.log_name+
      ' logical_distance=60.0 same_ground_y=220.0 contact_visual_reachable=1')
  end

  def force_v060_skill(skill_key,user,target,label)
    if verification_mode==:multi_choreo_v060 &&
       contact_multi_showcase_skill_v0601?(skill_key)
      place_contact_multi_showcase_pair_v0601(user,target)
    end
    pmd_ac_v0601_force_v060_skill(skill_key,user,target,label)
  end

  def verify_multi_choreo_v060
    pmd_ac_v0601_verify_multi_choreo_v060
    return if @verification_done[:v0601_gate]
    s=@multi_choreo_stats_v060 || {}
    gate_ok=s[:contact_hits].to_i>=5 && s[:retreats].to_i>=3 &&
            s[:reengages].to_i>=3
    log_event(:verify,
      'CONTACT_MULTI_SHOWCASE_GATE_V0601 pass='+(gate_ok ? '1':'0')+
      ' range_bypass=1 staged_distance=60 same_ground_y=1 hits='+
      s[:contact_hits].to_i.to_s+' retreats='+s[:retreats].to_i.to_s+
      ' reengages='+s[:reengages].to_i.to_s+
      ' normal_combat_unchanged=1')
    @verification_done[:v0601_gate]=true
  end
end
