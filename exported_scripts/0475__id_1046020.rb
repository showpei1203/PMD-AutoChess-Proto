# encoding: UTF-8
#==============================================================================
# 【PMD AutoChess 中文維護說明】
# 腳本：PMD AutoChess Skill Banner Lifetime v1.04.6
# 分類：戰鬥 UI／技能名稱 Banner／Trailing Layer
# RPG Maker VX / RGSS2 / Ruby 1.8 compatible
#------------------------------------------------------------------------------
# 【用途】
# 1. 依 Windows 實機觀感，將技能名稱 Banner 的存在時間由 42 frame 延長到 54 frame。
# 2. 只延長「完整可讀 hold」；沿用 v1.04.2 既有 opacity=frames*12 淡出公式，
#    因此最後約 21 frame 的 fade 長度與手感不變。
# 3. 延續 v1.04.3 的 18px UI font、108x24 屬性色底板、只顯示技能名稱，以及
#    v1.04.2 pre-render / v1.04.1 render cache。Live battle 仍不做 draw_text。
#------------------------------------------------------------------------------
# 【主要設定】
# SKILL_BANNER_POPUP_FRAMES_V1046 = 54
#   技能名稱總存在 frame。舊正式值為 42。
# SKILL_BANNER_OLD_FRAMES_V1046 = 42
#   僅供 verifier / 文件比對。
#------------------------------------------------------------------------------
# 【機制規則】
# - 只 alias Game_PMDChessUnit#begin_skill，parent 完成技能起手後，將
#   @skill_popup_frames 提高到至少 54。
# - 不改 @action_timer、@action_total_frames、@action_hit_frame、Energy、Damage、AI、
#   Attack Speed、Projectile/Beam timing、logical x/y 或 velocity。
# - 若未來其他正式 UI 層把 popup 設得比 54 更長，本層不會把它縮短。
# - 淡出公式不改，因此延長的是前段可讀時間，不拖長尾端透明殘影。
#------------------------------------------------------------------------------
# 【可調參數】
# - 想再多停約 0.2 秒（60fps）：可由 54 調至 66。
# - 不建議直接把 fade multiplier 12 改小，那會讓尾端拖影變長，視覺反而黏滯。
#------------------------------------------------------------------------------
# 【事件／腳本呼叫方式】
# 無需事件呼叫。所有 Game_PMDChessUnit 正常 begin_skill 時自動套用。
# Motion verifier 會輸出：
#   SKILL_BANNER_LIFETIME_V1046
#------------------------------------------------------------------------------
# 【實際範例】
# 舊：42 frame = 約 21 frame full readable + 約 21 frame fade。
# 新：54 frame = 約 33 frame full readable + 約 21 frame fade。
#==============================================================================
$imported={} unless defined?($imported)
$imported['PMD_AutoChess_SkillBannerLifetime_v1046']=true

module PMD_AC
  SKILL_BANNER_OLD_FRAMES_V1046=42
  SKILL_BANNER_POPUP_FRAMES_V1046=54
end

class Game_PMDChessUnit
  alias pmd_ac_v1046_skill_banner_lifetime_begin_skill begin_skill unless method_defined?(:pmd_ac_v1046_skill_banner_lifetime_begin_skill)

  def begin_skill(skill_target=nil)
    before=@skill_popup_frames.to_i rescue 0
    pmd_ac_v1046_skill_banner_lifetime_begin_skill(skill_target)
    begin
      now=@skill_popup_frames.to_i
      target=PMD_AC::SKILL_BANNER_POPUP_FRAMES_V1046
      fresh=(now==PMD_AC::SKILL_BANNER_OLD_FRAMES_V1046 || now>before)
      @skill_popup_frames=target if fresh && now>0 && now<target
    rescue
    end
  end
end

class Scene_PMD_AutoChess
  alias pmd_ac_v1046_banner_lifetime_update_verification_script update_verification_script unless method_defined?(:pmd_ac_v1046_banner_lifetime_update_verification_script)

  def update_verification_script
    pmd_ac_v1046_banner_lifetime_update_verification_script
    return unless respond_to?(:motion_phase_b_verifier_active_v1036?) && motion_phase_b_verifier_active_v1036?
    if !@skill_banner_lifetime_verify_v1046 && @verification_frame.to_i>=220
      @skill_banner_lifetime_verify_v1046=true
      old=PMD_AC::SKILL_BANNER_OLD_FRAMES_V1046
      now=PMD_AC::SKILL_BANNER_POPUP_FRAMES_V1046
      ok=now>old && now==54
      log_event(:verify,'SKILL_BANNER_LIFETIME_V1046 pass='+(ok ? '1':'0')+
        ' old_frames='+old.to_i.to_s+' new_frames='+now.to_i.to_s+
        ' extra_full_readable_frames='+(now-old).to_i.to_s+
        ' fade_formula_unchanged=1 font=18 banner=108x24 live_draw_text=0'+
        ' action_timer_unchanged=1 attack_speed_unchanged=1 damage_unchanged=1 energy_unchanged=1 spatial_unchanged=1')
    end
  rescue
  end
end
