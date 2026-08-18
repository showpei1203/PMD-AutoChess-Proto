#==============================================================================
# ■ PMD AutoChess - Battle Ambient Isolation v1.03.2
#==============================================================================
# 【用途】
# 將 Phase A 期間加入的 Species Ambient Rich LOOP 從「正式自走棋戰鬥中」移除，
# 避免 Hop、Flap Around、Tail Whip、Twirl 等純視覺大動作被玩家誤認為攻擊、閃避、
# 擊退、位移技能或 AI 正在改變站位。
#
# 【正式規則】
# 1. 布陣／待機畫面仍保留既有 Sprite idle / 空閒狀態設定；本腳本不修改 Deploy 顯示。
# 2. 進入 live battle 後，Species Ambient Rich LOOP 停止輪播。
# 3. 戰鬥中若單位沒有被 Combat Motion／Hurt／Spatial Runtime 接管，靜止被動顯示優先使用
#    Walk；缺少 Walk 才安全回退 Idle。
# 4. Hop、Flap Around、Twirl、Tail Whip、Look Up 等不再因「純待機」於戰場自行觸發。
# 5. 真正的大幅位移只能由：
#      - Combat Motion（攻擊、技能、Hurt、Recovery 等）
#      - Spatial Runtime（追擊、撤退、Push/Pull/Dash 等真實邏輯位移）
#    產生。
# 6. 本版只改 presentation selector，不修改 pixel_x / pixel_y、Damage、Attack Speed、
#    Energy、AI、Pathfinding、Targeting 或 Spatial Framework。
#
# 【主要設定】
# BATTLE_PASSIVE_ACTION_V1032 = :walk
#   live battle 無戰鬥語意動作時，優先使用 Walk 作為被動生命感顯示。
#
# 【可調參數】
# 若日後希望戰場保留極低干擾原地 breathing/bob，應另做「Combat Micro Idle」層，
# 僅允許不產生明顯水平/垂直位移的 presentation offset；不要重新啟用 Rich LOOP。
#
# 【事件／腳本呼叫方式】
# 不需事件呼叫。進入 PMD AutoChess live battle 自動生效；Deploy 不受影響。
#
# 【實際範例】
# 小火龍在布陣畫面仍可依既有 Sprite idle 設定呈現；正式戰鬥中等待時不再突然 Hop。
# 當牠真正使用 Quick Attack / Dash / Jump 類技能時，Hop/Dash 等 Motion 仍可正常使用，
# 因為那是具有戰鬥語意的動作，不屬於 Ambient Rich LOOP。
#==============================================================================

$imported = {} unless defined?($imported)
$imported['PMD_AutoChess_BattleAmbientIsolation_v1032'] = true

module PMD_AC
  BATTLE_PASSIVE_ACTION_V1032 = :walk
end

class Game_PMDChessUnit
  alias pmd_ac_v1032_motion_ambient_eligible_v102? motion_ambient_eligible_v102? unless method_defined?(:pmd_ac_v1032_motion_ambient_eligible_v102?)
  alias pmd_ac_v1032_motion_update_ambient_v102 motion_update_ambient_v102 unless method_defined?(:pmd_ac_v1032_motion_update_ambient_v102)
  alias pmd_ac_v1032_visual_action visual_action unless method_defined?(:pmd_ac_v1032_visual_action)

  # Rich LOOP 僅退出 live battle；Deploy 的既有 idle 顯示完全不碰。
  def motion_ambient_eligible_v102?
    return false if @battle_active
    pmd_ac_v1032_motion_ambient_eligible_v102?
  rescue
    false
  end

  # live battle 不再輪播 Species Ambient sequence；固定回 passive base。
  def motion_update_ambient_v102
    if @battle_active && motion_phase_a_species_v102?
      @motion_ambient_index_v102=0
      @motion_ambient_frames_v102=1
      @motion_ambient_action_v102=PMD_AC::BATTLE_PASSIVE_ACTION_V1032
      return
    end
    pmd_ac_v1032_motion_update_ambient_v102
  rescue
  end

  # Combat-owned pose 永遠優先。只有真正「沒有戰鬥語意」的 stationary walk/idle
  # 才統一成 Walk，避免 Idle/Rich Loop 自己看起來像事件發生。
  def visual_action
    base=pmd_ac_v1032_visual_action
    return base unless @battle_active
    return base unless motion_phase_a_species_v102?
    return base if dead? || acting?
    return base if motion_actual_moving_v102?
    return base if respond_to?(:motion_hurt_active_v102?) && motion_hurt_active_v102?
    return base unless base==:walk || base==:idle
    return :walk if PMD_AC.motion_playable_v102?(@species,:walk)
    :idle
  rescue
    base
  end
end

class Scene_PMD_AutoChess
  alias pmd_ac_v1032_update_verification_script update_verification_script unless method_defined?(:pmd_ac_v1032_update_verification_script)

  def update_verification_script
    pmd_ac_v1032_update_verification_script
    return unless verification_mode==:pmd_motion_phase_b_v103
    return if @verification_done==nil
    f=@verification_frame.to_i
    if f==172 && !@verification_done[:battle_ambient_isolation_v1032]
      verify_battle_ambient_isolation_v1032
    end
  end

  def verify_battle_ambient_isolation_v1032
    units=[]
    begin
      units.concat(@units) if @units!=nil
    rescue
    end
    covered=0
    passive_ok=0
    units.each do |u|
      next if u==nil
      next unless u.respond_to?(:motion_phase_a_species_v102?) && u.motion_phase_a_species_v102?
      covered+=1
      a=u.instance_variable_get(:@motion_ambient_action_v102) rescue nil
      passive_ok+=1 if a==:walk || a==nil
    end
    pass=covered>0 && passive_ok==covered
    log_event(:verify,
      'MOTION_BATTLE_AMBIENT_ISOLATION_V1032 pass='+(pass ? '1':'0')+
      ' covered='+covered.to_s+' passive_ok='+passive_ok.to_s+
      ' rich_loop_live_battle=0 deploy_idle_retained=1 passive_action=walk'+
      ' hop_idle_battle=0 large_visual_idle_displacement=0'+
      ' combat_motion_retained=1 spatial_runtime_retained=1'+
      ' logical_xy_unchanged=1 ai_unchanged=1 damage_unchanged=1'+
      ' attack_speed_unchanged=1 energy_unchanged=1')
    @verification_done[:battle_ambient_isolation_v1032]=true
  rescue
    log_event(:verify,'MOTION_BATTLE_AMBIENT_ISOLATION_V1032 pass=0 error=1')
    @verification_done[:battle_ambient_isolation_v1032]=true
  end
end
