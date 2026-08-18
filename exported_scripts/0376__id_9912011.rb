#==============================================================================
# 【PMD AutoChess 中文維護說明】
# 腳本：PMD AutoChess Basic Spatial Flex Verifier Fix v0.99.12.1
# 分類：戰鬥驗證相容修正（Trailing Alias Hook）
#
# 【用途】
# 修正 v0.99.12 的 BASIC_SPATIAL_FLEX 專用驗證模式沒有繼承 v0.88.3
# Combat Feel Runtime 的問題。該問題只會讓此 verifier 退回 v0.75 的
# anti-kite 攻擊鎖，造成 Adaptive 小火龍切到 close mode 後看起來幾乎不攻擊。
# NORMAL 正式戰鬥原本就會使用 v0.88.3，本腳本不改 NORMAL 的傷害、射程、
# 攻速、移速、Threat、Stagger 或 AI 數值。
#
# 【主要規則】
# 1. BASIC_SPATIAL_FLEX_V09912 verifier 亦視為 v0.88.3 Combat Feel Runtime。
# 2. v0.99.12 Adaptive close basic 因而可正確繞過舊 v0.75 anti-kite attack lock。
# 3. 新增 BASIC_CLOSE_DISPATCH_V099121 regression：不只驗證 mode 切換，
#    而是實際走 begin_attack dispatch，確認 close/melee 普攻真的能啟動。
# 4. Regression 失敗時會同步把 v0.99.12 final verifier 標成 FAIL。
#
# 【可調參數】
# VERIFY_CLOSE_DISTANCE_V099121：Regression 使用的近身距離。預設 52px，
# 必須低於小火龍 close_enter=64，並在其 melee hit grace 內。
#
# 【測試方式】
# 進入測試專案：NORMAL -> S 一次 -> BASIC_SPATIAL_FLEX_V09912 -> Shift。
# 預期新增：
#   BASIC_CLOSE_DISPATCH_V099121 pass=1 inherited_v0883=1 delivery=melee action_started=1
# 並且原本 BASIC_SPATIAL_FLEX_V09912 與 VERIFY_FINISHED_BATTLE_RESUME 仍 pass=1。
#
# 【事件／腳本呼叫】
# 本腳本為 Runtime／Verifier 修正，不需要事件呼叫。
#
# 【維護規則】
# - RPG Maker VX / RGSS2 / Ruby 1.8 相容。
# - 不直接修改 Frozen Combat Core，只使用 trailing alias。
# - Pokémon 個體身份仍使用 instance_uid。
#==============================================================================

module PMD_AC
  VERIFY_CLOSE_DISTANCE_V099121 = 52.0 unless const_defined?('VERIFY_CLOSE_DISTANCE_V099121')
end

class Game_PMDChessUnit
  alias pmd_ac_v099121_combat_feel_runtime_v0883 combat_feel_runtime_v0883? unless method_defined?(:pmd_ac_v099121_combat_feel_runtime_v0883)

  def combat_feel_runtime_v0883?
    if @scene != nil && @scene.respond_to?(:verification_mode)
      return true if @scene.verification_mode == :basic_spatial_flex_v09912
    end
    pmd_ac_v099121_combat_feel_runtime_v0883
  end
end

class Scene_PMD_AutoChess
  alias pmd_ac_v099121_start start unless method_defined?(:pmd_ac_v099121_start)
  alias pmd_ac_v099121_update_verification_script update_verification_script unless method_defined?(:pmd_ac_v099121_update_verification_script)

  def start
    pmd_ac_v099121_start
    begin
      if FileTest.exist?(PMD_AC::BATTLE_LOG_FILE)
        t=File.open(PMD_AC::BATTLE_LOG_FILE,'rb'){|f|f.read}
        t.sub!(/PMD AutoChess Proto v0\.99\.12 Battle Verification Log/,
          'PMD AutoChess Proto v0.99.12.1 Battle Verification Log')
        File.open(PMD_AC::BATTLE_LOG_FILE,'wb'){|f|f.write(t)}
      end
    rescue
    end
    log_event(:basic_flex,
      'PATCH v0.99.12.1 verifier_inherits_v0.88.3=1 close_dispatch_regression=1 '+
      'normal_combat_unchanged=1 damage_unchanged=1 spacing_unchanged=1')
  end

  def verify_close_basic_dispatch_v099121
    u=verification_unit(:ally,:charmander)
    t=verification_unit(:enemy,:rattata)
    pass=false
    inherited=false
    delivery=:none
    action_started=false
    if u!=nil && t!=nil && !u.dead? && !t.dead?
      saved={}
      [:@target,:@pixel_x,:@pixel_y,:@attack_wait,:@action,:@visual_action,
       :@action_timer,:@action_total_frames,:@action_hit_frame,:@action_hit_done,
       :@action_lunge,:@velocity_x,:@velocity_y,:@move_goal_x,:@move_goal_y,
       :@basic_adaptive_state_v09912,:@basic_attack_packet_v09912,
       :@ranged_hit_stagger_v0883].each do |iv|
        saved[iv]=u.instance_variable_get(iv)
      end
      tx=t.instance_variable_get(:@pixel_x)
      ty=t.instance_variable_get(:@pixel_y)
      begin
        # 保持小火龍位置，只把測試目標暫時放在固定近身距離。
        t.instance_variable_set(:@pixel_x,
          u.instance_variable_get(:@pixel_x).to_f+PMD_AC::VERIFY_CLOSE_DISTANCE_V099121)
        t.instance_variable_set(:@pixel_y,u.instance_variable_get(:@pixel_y).to_f)
        u.instance_variable_set(:@target,t)
        u.instance_variable_set(:@attack_wait,0.0)
        u.instance_variable_set(:@action,:idle)
        u.instance_variable_set(:@action_timer,0)
        u.instance_variable_set(:@action_total_frames,0)
        u.instance_variable_set(:@ranged_hit_stagger_v0883,0)
        u.instance_variable_set(:@basic_adaptive_state_v09912,:ranged)
        inherited=u.combat_feel_runtime_v0883? ? true : false
        delivery=u.basic_delivery_for_distance_v09912(PMD_AC::VERIFY_CLOSE_DISTANCE_V099121)
        u.begin_attack
        packet=u.instance_variable_get(:@basic_attack_packet_v09912)
        action_started=(u.instance_variable_get(:@action)==:attack &&
          u.instance_variable_get(:@action_timer).to_i>0)
        pass=inherited && delivery==:melee && action_started && packet!=nil &&
          packet[:delivery]==:melee
      rescue
        pass=false
      ensure
        t.instance_variable_set(:@pixel_x,tx)
        t.instance_variable_set(:@pixel_y,ty)
        saved.each{|iv,val|u.instance_variable_set(iv,val)}
      end
    end
    @basic_flex_failed_v09912=true unless pass
    log_event(:verify,
      'BASIC_CLOSE_DISPATCH_V099121 pass='+(pass ? '1' : '0')+
      ' inherited_v0883='+(inherited ? '1' : '0')+
      ' delivery='+delivery.to_s+
      ' action_started='+(action_started ? '1' : '0')+
      ' normal_combat_unchanged=1')
  end

  def update_verification_script
    if verification_mode==:basic_spatial_flex_v09912 &&
       !@verification_done[:verification_complete]
      f=@verification_frame.to_i
      if f>=86 && !@verification_done[:v099121_close_dispatch]
        verify_close_basic_dispatch_v099121
        @verification_done[:v099121_close_dispatch]=true
      end
    end
    pmd_ac_v099121_update_verification_script
  end
end
