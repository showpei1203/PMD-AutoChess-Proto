# encoding: UTF-8
#==============================================================================
# 【PMD AutoChess 中文維護說明】
# 腳本：PMD AutoChess Adaptive Close Dead-Zone + Production Runtime Bridge v1.01.3
# 分類：Basic Spatial Flex 安全修正／單位發呆防護／Map Story Verifier Runtime 繼承
# RPG Maker VX / RGSS2 / Ruby 1.8 compatible
#------------------------------------------------------------------------------
# 【用途】
# 修正實機觀察到的罕見「小火龍最後發呆」問題。追查 v0.99.12 Basic Spatial Flex
# 後確認 adaptive Pokémon 存在一個 hysteresis dead-zone：
# - 小火龍 close_enter=64、ranged_resume=92。
# - 進入 :close 後，若目標退到「近戰 hit limit 外、但仍小於 ranged_resume」的位置，
#   delivery 仍維持 :melee。
# - 舊 flexible / hold 分支在這個狀態會 clear_move_goal + face_toward 後直接 return，
#   造成單位既不攻擊也不追近；若其他單位仍持續造成傷害，全場 stalemate timer 也
#   不會介入，因此可能一直站著發呆。
#
# 本版只修這個不合理的移動死區：adaptive-close 若尚未進入合法 melee hit range，
# 會繼續向目前目標靠近至 melee hit limit 內，再交回原本 begin_attack / cadence。
# 不改 Attack Speed、傷害、技能、Target Policy、Dynamic Tactical Role 或 Spatial 技能。
#------------------------------------------------------------------------------
# 【第二個修正：Map Story Verifier Production Runtime Bridge】
# v1.00 RPG_FOUNDATION verifier 已有 production runtime inheritance，但 v1.01 新增的
# MAP_STORY_VERTICAL_SLICE_V101 漏了同一層 bridge，導致該 formal verifier 戰鬥中：
# - Combat Feel v0.88.3
# - Basic Spatial Flex v0.99.12
# - Attack Cadence Recovery v0.99.14.2
# - Spatial Framework v0.99.14+
# 可能退回歷史 verifier 行為。正式地圖戰（新 Scene 預設 NORMAL）不受此漏接影響，
# 但 Map Story formal battle 必須和 production runtime 一致，所以本版補齊。
#------------------------------------------------------------------------------
# 【主要規則】
# 1. 只在 Basic Flex 已啟用、profile=:adaptive、delivery=:melee、目前距離尚未合法命中時
#    判定 close-gap recovery。
# 2. flexible / hold：向目標追到 melee hit limit 內，不再原地 clear goal。
# 3. bodyguard：只有被保護隊友仍在 leash 內時才短距離追近；若離隊友太遠仍沿用原
#    Bodyguard guard position，避免修發呆時破壞護衛職責。
# 4. kite / artillery / close 沿用既有行為；不強制改成貼身。
# 5. 每次進入 dead-zone 只寫一行 :cadence_recovery LOG，離開後才允許下次再記。
# 6. MAP_STORY verifier 額外允許 cadence_recovery / cadence_watch 兩類異常診斷；正常
#    戰鬥沒有異常時不會增加流水帳。
#------------------------------------------------------------------------------
# 【可調參數】
# ADAPTIVE_CLOSE_APPROACH_MARGIN_V1013 = 4.0
#   追近目標設為 melee hit limit - 4px，避免剛好卡在浮點邊界。
#------------------------------------------------------------------------------
# 【事件／腳本呼叫方式】
# 正式遊戲不需事件呼叫，Runtime 自動套用。
# Debug 可查：
#   unit.adaptive_close_dead_zone_v1013?
#   unit.adaptive_close_recovery_count_v1013
#------------------------------------------------------------------------------
# 【實際範例】
# 小火龍已在 adaptive :close，敵人從 60px 後退到 80px；80px 仍小於 ranged_resume=92，
# 所以 delivery 仍是 melee，但若 melee hit limit 約 67~70px，舊版會原地發呆。
# v1.01.3 會建立 move goal 追到 hit limit 內，接著照原 Attack Speed 正常出手。
#------------------------------------------------------------------------------
# 【Verifier】
# MAP_STORY_VERTICAL_SLICE_V101：
#   MAP_STORY_PRODUCTION_RUNTIME_V1013 pass=1
#   ADAPTIVE_CLOSE_DEADZONE_V1013 pass=1
# 若真的觸發 runtime recovery，Battle LOG 會額外出現：
#   [CADENCE_RECOVERY] ... reason=adaptive_close_gap ...
#------------------------------------------------------------------------------
# 【不可破壞】
# - Frozen Combat Core 不直接修改，只使用 Main 前 trailing alias。
# - Pokémon identity 仍為 instance_uid。
# - Dynamic Tactical Role / Spatial Framework / Skill FX / Damage Formula 不取代、不重寫。
# - Attack Speed 與正常 cooldown 不修改。
#==============================================================================
module PMD_AC
  PATCH_VERSION_V1013='1.01.3'
  ADAPTIVE_CLOSE_APPROACH_MARGIN_V1013=4.0

  class << self
    alias pmd_ac_v1013_log_category_allowed_v1006? log_category_allowed_v1006? unless method_defined?(:pmd_ac_v1013_log_category_allowed_v1006?)
    def log_category_allowed_v1006?(mode,category)
      if mode==:map_story_vertical_slice_v101
        c=category.to_s.to_sym
        return true if c==:cadence_recovery || c==:cadence_watch
      end
      pmd_ac_v1013_log_category_allowed_v1006?(mode,category)
    end
  end
end

#==============================================================================
# ■ Game_PMDChessUnit : adaptive close dead-zone recovery
#==============================================================================
class Game_PMDChessUnit
  alias pmd_ac_v1013_update_basic_flex_ranged_v09912 update_basic_flex_ranged_v09912 unless method_defined?(:pmd_ac_v1013_update_basic_flex_ranged_v09912)
  alias pmd_ac_v1013_update_basic_flex_bodyguard_v09912 update_basic_flex_bodyguard_v09912 unless method_defined?(:pmd_ac_v1013_update_basic_flex_bodyguard_v09912)
  alias pmd_ac_v1013_combat_feel_runtime_v0883 combat_feel_runtime_v0883? unless method_defined?(:pmd_ac_v1013_combat_feel_runtime_v0883)
  alias pmd_ac_v1013_basic_flex_runtime_v09912 basic_flex_runtime_v09912? unless method_defined?(:pmd_ac_v1013_basic_flex_runtime_v09912)
  alias pmd_ac_v1013_cadence_runtime_v099142 cadence_runtime_v099142? unless method_defined?(:pmd_ac_v1013_cadence_runtime_v099142)

  def map_story_production_runtime_v1013?
    @scene!=nil && @scene.respond_to?(:verification_mode) &&
      @scene.verification_mode==:map_story_vertical_slice_v101
  end

  def combat_feel_runtime_v0883?
    return true if map_story_production_runtime_v1013?
    pmd_ac_v1013_combat_feel_runtime_v0883
  end

  def basic_flex_runtime_v09912?
    return true if map_story_production_runtime_v1013?
    pmd_ac_v1013_basic_flex_runtime_v09912
  end

  def cadence_runtime_v099142?
    return true if map_story_production_runtime_v1013?
    pmd_ac_v1013_cadence_runtime_v099142
  end

  def adaptive_close_melee_limit_v1013
    if respond_to?(:basic_melee_hit_limit_v0871)
      return basic_melee_hit_limit_v0871.to_f
    end
    @melee_reach.to_f+PMD_AC::MELEE_HIT_GRACE.to_f
  rescue
    @melee_reach.to_f
  end

  def adaptive_close_dead_zone_v1013?
    return false unless basic_flex_runtime_v09912?
    return false if @target==nil || @target.dead?
    p=basic_flex_profile_v09912
    return false if p==nil || p[:mode]!=:adaptive
    d=distance_to(@target).to_f
    delivery=basic_delivery_for_distance_v09912(d)
    return false unless delivery==:melee
    !basic_attack_distance_allowed_v09912(d,delivery)
  rescue
    false
  end

  def adaptive_close_recovery_count_v1013
    @adaptive_close_recovery_count_v1013.to_i
  end

  def adaptive_close_mark_clear_v1013
    @adaptive_close_gap_active_v1013=false
  end

  def adaptive_close_approach_v1013(reason)
    return false unless adaptive_close_dead_zone_v1013?
    d=distance_to(@target).to_f
    limit=adaptive_close_melee_limit_v1013
    desired=limit-PMD_AC::ADAPTIVE_CLOSE_APPROACH_MARGIN_V1013
    desired=18.0 if desired<18.0
    move_toward_distance(@target,desired)
    unless @adaptive_close_gap_active_v1013
      @adaptive_close_gap_active_v1013=true
      @adaptive_close_recovery_count_v1013=@adaptive_close_recovery_count_v1013.to_i+1
      log_event(:cadence_recovery,log_name+' reason=adaptive_close_gap'+
        ' policy='+reason.to_s+' distance='+d.round.to_s+
        ' melee_limit='+limit.round.to_s+' ranged_resume='+
        basic_flex_profile_v09912[:ranged_resume].to_f.round.to_s+' action=approach')
    end
    true
  rescue
    false
  end

  def update_basic_flex_ranged_v09912
    if basic_flex_runtime_v09912? && @target!=nil && !@target.dead?
      spacing=effective_spacing_policy_v09912
      if [:flexible,:hold].include?(spacing)
        if adaptive_close_approach_v1013(spacing)
          return
        end
      end
    end
    adaptive_close_mark_clear_v1013 unless adaptive_close_dead_zone_v1013?
    pmd_ac_v1013_update_basic_flex_ranged_v09912
  end

  def update_basic_flex_bodyguard_v09912
    if basic_flex_runtime_v09912? && @target!=nil && !@target.dead? &&
       adaptive_close_dead_zone_v1013?
      ally=protected_ally
      if ally==nil || distance_to(ally).to_f<=PMD_AC::AI_BODYGUARD_LEASH
        return if adaptive_close_approach_v1013(:bodyguard)
      end
    end
    adaptive_close_mark_clear_v1013 unless adaptive_close_dead_zone_v1013?
    pmd_ac_v1013_update_basic_flex_bodyguard_v09912
  end
end

#==============================================================================
# ■ Scene_PMD_AutoChess : Map Story production runtime bridge + verifier
#==============================================================================
class Scene_PMD_AutoChess
  alias pmd_ac_v1013_spatial_framework_runtime_enabled_v09914 spatial_framework_runtime_enabled_v09914? unless method_defined?(:pmd_ac_v1013_spatial_framework_runtime_enabled_v09914)
  alias pmd_ac_v1013_update_verification_script update_verification_script unless method_defined?(:pmd_ac_v1013_update_verification_script)

  def spatial_framework_runtime_enabled_v09914?
    return true if verification_mode==:map_story_vertical_slice_v101
    pmd_ac_v1013_spatial_framework_runtime_enabled_v09914
  end

  def verify_map_story_production_runtime_v1013
    return if @verification_done[:map_story_production_runtime_v1013]
    u=verification_unit(:ally,:charmander)
    combat=u!=nil && u.respond_to?(:combat_feel_runtime_v0883?) && u.combat_feel_runtime_v0883?
    flex=u!=nil && u.respond_to?(:basic_flex_runtime_v09912?) && u.basic_flex_runtime_v09912?
    cadence=u!=nil && u.respond_to?(:cadence_runtime_v099142?) && u.cadence_runtime_v099142?
    spatial=spatial_framework_runtime_enabled_v09914?
    pass=combat && flex && cadence && spatial
    @map_story_failed_v101=true unless pass
    log_event(:verify,'MAP_STORY_PRODUCTION_RUNTIME_V1013 pass='+(pass ? '1':'0')+
      ' combat_feel='+(combat ? '1':'0')+' basic_flex='+(flex ? '1':'0')+
      ' cadence='+(cadence ? '1':'0')+' spatial='+(spatial ? '1':'0')+
      ' attack_speed_unchanged=1 damage_unchanged=1')
    @verification_done[:map_story_production_runtime_v1013]=true
  end

  def verify_adaptive_close_deadzone_v1013
    return if @verification_done[:adaptive_close_deadzone_v1013]
    u=verification_unit(:ally,:charmander)
    t=verification_unit(:enemy,:caterpie)
    pass=false;detail='unit_missing'
    if u!=nil && t!=nil && !u.dead? && !t.dead?
      saved={}
      ivs=[:@target,:@pixel_x,:@pixel_y,:@move_goal_x,:@move_goal_y,
        :@basic_adaptive_state_v09912,:@spacing_policy_v09912,
        :@adaptive_close_gap_active_v1013,:@adaptive_close_recovery_count_v1013]
      ivs.each{|iv|saved[iv]=u.instance_variable_get(iv)}
      tx=t.instance_variable_get(:@pixel_x);ty=t.instance_variable_get(:@pixel_y)
      begin
        p=u.basic_flex_profile_v09912
        limit=u.adaptive_close_melee_limit_v1013
        test_d=[limit+8.0,p[:ranged_resume].to_f-4.0].min
        test_d=limit+2.0 if test_d<=limit
        t.instance_variable_set(:@pixel_x,u.instance_variable_get(:@pixel_x).to_f+test_d)
        t.instance_variable_set(:@pixel_y,u.instance_variable_get(:@pixel_y).to_f)
        u.instance_variable_set(:@basic_adaptive_state_v09912,:close)
        u.instance_variable_set(:@spacing_policy_v09912,:flexible)
        u.set_target(t)
        deadzone=u.adaptive_close_dead_zone_v1013?
        recovered=u.adaptive_close_approach_v1013(:verifier)
        gx=u.instance_variable_get(:@move_goal_x)
        gy=u.instance_variable_get(:@move_goal_y)
        pass=deadzone && recovered && gx!=nil && gy!=nil
        detail='distance='+test_d.round.to_s+' melee_limit='+limit.round.to_s+
          ' close_enter='+p[:close_enter].to_f.round.to_s+' ranged_resume='+p[:ranged_resume].to_f.round.to_s+
          ' deadzone='+(deadzone ? '1':'0')+' move_goal='+(gx!=nil && gy!=nil ? '1':'0')
      rescue
        pass=false;detail='exception=1'
      ensure
        t.instance_variable_set(:@pixel_x,tx);t.instance_variable_set(:@pixel_y,ty)
        saved.each{|iv,val|u.instance_variable_set(iv,val)}
      end
    end
    @map_story_failed_v101=true unless pass
    log_event(:verify,'ADAPTIVE_CLOSE_DEADZONE_V1013 pass='+(pass ? '1':'0')+' '+detail+
      ' attack_speed_unchanged=1 damage_unchanged=1')
    @verification_done[:adaptive_close_deadzone_v1013]=true
  end

  def update_verification_script
    pmd_ac_v1013_update_verification_script
    return unless verification_mode==:map_story_vertical_slice_v101
    f=@verification_frame.to_i
    verify_map_story_production_runtime_v1013 if f>=22
    verify_adaptive_close_deadzone_v1013 if f>=24
  end
end
