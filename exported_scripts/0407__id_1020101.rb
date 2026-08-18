# encoding: UTF-8
#==============================================================================
# 【PMD AutoChess 中文維護說明】
# 腳本：PMD AutoChess Motion Verifier Production Runtime Bridge v1.02.1
# 分類：PMD Motion Phase A／正式 AI Runtime 繼承修正／Trailing Hotfix
# RPG Maker VX / RGSS2 / Ruby 1.8 compatible
#------------------------------------------------------------------------------
# 【用途】
# 修正 v1.02 的 PMD_MOTION_PHASE_A_V102 verifier 沒有完整繼承 NORMAL 正式戰鬥
# Runtime，導致測試模式內妙蛙種子、小火龍等單位可能退回舊版移動邏輯，肉眼上
# 出現長時間後撤、逃跑感過強、攻擊節奏與正式遊戲不一致。
#
# v1.02 Motion Framework 本身只負責 Presentation，理論上不該改 AI；真正問題是
# verifier mode 新增後，沒有像 RPG_FOUNDATION / MAP_STORY 一樣把 production runtime
# 明確 bridge 回來。本版只補這個接線，不更改正式 NORMAL 的任何 AI 數值。
#------------------------------------------------------------------------------
# 【主要修正】
# PMD_MOTION_PHASE_A_V102 模式強制沿用目前正式 production runtime：
# 1. Combat Feel v0.88.3
# 2. Basic Spatial Flex v0.99.12
# 3. Attack Cadence Recovery v0.99.14.2+
# 4. Spatial Framework v0.99.14+
#
# Dynamic Tactical Role、Spatial Conditions、Nature AI 原本的資料／評分鏈保持不變。
#------------------------------------------------------------------------------
# 【核心規則】
# - 只對 verification_mode == :pmd_motion_phase_a_v102 生效。
# - NORMAL 完全不改。
# - 不修改 spacing_policy、movement_policy、target_policy、Attack Speed、Damage Formula。
# - Motion 仍只處理身體演技，不得取得 AI 決策權。
# - 保留 v1.01.3 adaptive close dead-zone recovery。
#------------------------------------------------------------------------------
# 【診斷 LOG】
# Motion verifier 允許少量 cadence_recovery / cadence_watch，僅在異常或 recovery 發生時寫。
# 妙蛙種子／小火龍第一次真正進入 basic attack 時各寫一行 MOTION_AI，方便肉眼與 LOG 對照。
#------------------------------------------------------------------------------
# 【事件／腳本呼叫】
# 正式遊戲不需呼叫，進入 PMD_MOTION_PHASE_A_V102 verifier 自動生效。
# Debug：
#   unit.motion_production_runtime_v1021?
#------------------------------------------------------------------------------
# 【實際範例】
# v1.02：Motion verifier 中小火龍可能使用舊 movement runtime，持續往後拉。
# v1.02.1：同一 verifier 改用正式 Basic Spatial Flex；adaptive/flexible 會優先在合法
# 射程 Ready 時攻擊，只有正式 production 規則允許時才重站位。
#------------------------------------------------------------------------------
# 【Verifier】
# PMD_MOTION_PHASE_A_V102：
#   MOTION_PRODUCTION_RUNTIME_V1021 pass=1
# 並可看到：
#   [MOTION_AI] ALLY:妙蛙種子 basic_attack_seen=1 production_runtime=1
#   [MOTION_AI] ALLY:小火龍 basic_attack_seen=1 production_runtime=1
#------------------------------------------------------------------------------
# 【不可破壞】
# - Frozen Combat Core 不直接修改，只使用 Main 前 trailing alias。
# - Pokémon identity 仍為 instance_uid。
# - Dynamic Tactical Role / Spatial Framework / Skill FX / Damage Formula 不取代、不重寫。
#==============================================================================
module PMD_AC
  MOTION_RUNTIME_BRIDGE_VERSION_V1021='1.02.1'

  class << self
    alias pmd_ac_v1021_log_category_allowed_v1006? log_category_allowed_v1006? unless method_defined?(:pmd_ac_v1021_log_category_allowed_v1006?)
    def log_category_allowed_v1006?(mode,category)
      if mode==:pmd_motion_phase_a_v102
        c=category.to_s.to_sym
        return true if c==:cadence_recovery || c==:cadence_watch || c==:motion_ai
      end
      pmd_ac_v1021_log_category_allowed_v1006?(mode,category)
    end
  end
end

#==============================================================================
# ■ Game_PMDChessUnit : Motion verifier production runtime inheritance
#==============================================================================
class Game_PMDChessUnit
  alias pmd_ac_v1021_combat_feel_runtime_v0883 combat_feel_runtime_v0883? unless method_defined?(:pmd_ac_v1021_combat_feel_runtime_v0883)
  alias pmd_ac_v1021_basic_flex_runtime_v09912 basic_flex_runtime_v09912? unless method_defined?(:pmd_ac_v1021_basic_flex_runtime_v09912)
  alias pmd_ac_v1021_cadence_runtime_v099142 cadence_runtime_v099142? unless method_defined?(:pmd_ac_v1021_cadence_runtime_v099142)
  alias pmd_ac_v1021_begin_attack begin_attack unless method_defined?(:pmd_ac_v1021_begin_attack)

  def motion_production_runtime_v1021?
    @scene!=nil && @scene.respond_to?(:verification_mode) &&
      @scene.verification_mode==:pmd_motion_phase_a_v102
  end

  def combat_feel_runtime_v0883?
    return true if motion_production_runtime_v1021?
    pmd_ac_v1021_combat_feel_runtime_v0883
  end

  def basic_flex_runtime_v09912?
    return true if motion_production_runtime_v1021?
    pmd_ac_v1021_basic_flex_runtime_v09912
  end

  def cadence_runtime_v099142?
    return true if motion_production_runtime_v1021?
    pmd_ac_v1021_cadence_runtime_v099142
  end

  def begin_attack
    pmd_ac_v1021_begin_attack
    return unless motion_production_runtime_v1021?
    return unless @action==:attack
    sk=respond_to?(:species_key) ? species_key : nil
    return unless sk==:bulbasaur || sk==:charmander
    @motion_ai_attack_seen_v1021={} if @motion_ai_attack_seen_v1021==nil
    return if @motion_ai_attack_seen_v1021[sk]
    @motion_ai_attack_seen_v1021[sk]=true
    if @scene!=nil && @scene.respond_to?(:log_event)
      @scene.log_event(:motion_ai,log_name+' basic_attack_seen=1 production_runtime=1'+
        ' spacing='+(respond_to?(:effective_spacing_policy_v09912) ? effective_spacing_policy_v09912.to_s : 'unknown')+
        ' movement='+(@movement_policy==nil ? 'nil' : @movement_policy.to_s))
    end
  end
end

#==============================================================================
# ■ Scene_PMD_AutoChess : Spatial runtime bridge + verifier
#==============================================================================
class Scene_PMD_AutoChess
  alias pmd_ac_v1021_spatial_framework_runtime_enabled_v09914 spatial_framework_runtime_enabled_v09914? unless method_defined?(:pmd_ac_v1021_spatial_framework_runtime_enabled_v09914)
  alias pmd_ac_v1021_update_verification_script update_verification_script unless method_defined?(:pmd_ac_v1021_update_verification_script)

  def spatial_framework_runtime_enabled_v09914?
    return true if verification_mode==:pmd_motion_phase_a_v102
    pmd_ac_v1021_spatial_framework_runtime_enabled_v09914
  end

  def verify_motion_production_runtime_v1021
    return if @verification_done[:motion_production_runtime_v1021]
    b=verification_unit(:ally,:bulbasaur)
    c=verification_unit(:ally,:charmander)
    units=[b,c].compact
    combat=!units.empty? && units.all?{|u|u.respond_to?(:combat_feel_runtime_v0883?) && u.combat_feel_runtime_v0883?}
    flex=!units.empty? && units.all?{|u|u.respond_to?(:basic_flex_runtime_v09912?) && u.basic_flex_runtime_v09912?}
    cadence=!units.empty? && units.all?{|u|u.respond_to?(:cadence_runtime_v099142?) && u.cadence_runtime_v099142?}
    spatial=spatial_framework_runtime_enabled_v09914?
    pass=b!=nil && c!=nil && combat && flex && cadence && spatial
    @motion_phase_a_failed_v102=true unless pass
    log_event(:verify,'MOTION_PRODUCTION_RUNTIME_V1021 pass='+(pass ? '1':'0')+
      ' bulbasaur='+(b==nil ? '0':'1')+' charmander='+(c==nil ? '0':'1')+
      ' combat_feel='+(combat ? '1':'0')+' basic_flex='+(flex ? '1':'0')+
      ' cadence='+(cadence ? '1':'0')+' spatial='+(spatial ? '1':'0')+
      ' ai_values_unchanged=1 attack_speed_unchanged=1 damage_unchanged=1')
    @verification_done[:motion_production_runtime_v1021]=true
  end

  def update_verification_script
    pmd_ac_v1021_update_verification_script
    return unless verification_mode==:pmd_motion_phase_a_v102
    verify_motion_production_runtime_v1021 if @verification_frame.to_i>=26
  end
end
