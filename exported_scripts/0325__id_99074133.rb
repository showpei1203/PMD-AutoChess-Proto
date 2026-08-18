# encoding: UTF-8
#==============================================================================
# 【PMD AutoChess 中文維護說明】
# 腳本：PMD AutoChess Hidden Aggro & Reactive Targeting v0.91.2
# 分類：AutoChess AI／Hidden Aggro／Reactive Targeting
#
# 【用途】
# 在既有 Target Policy 與 THREAT 之外加入「隱藏仇恨 AGGRO」。
# Target Policy 決定角色原本想打誰；THREAT 負責空間危急；AGGRO 則記錄
# 「最近哪些敵人真的一直傷害／背刺／爆擊／控制我」。AGGRO 足夠高時，
# 可以打破一般 Target Commitment，避免角色被人在背後連打仍死追舊目標。
#
# 【主要設定項】
# - AGGRO_MAX_V0912：每個敵人的最大隱藏仇恨。
# - AGGRO_DECAY_PER_FRAME_V0912：每 frame 自然衰減。
# - AGGRO_DAMAGE_BASE_V0912 / AGGRO_DAMAGE_HP_SCALE_V0912：受傷產生仇恨。
# - AGGRO_BACK_BONUS_V0912：背擊額外仇恨。
# - AGGRO_CRIT_BONUS_V0912：爆擊額外仇恨。
# - AGGRO_REPEAT_BONUS_V0912：同一敵人短時間連續攻擊額外仇恨。
# - AGGRO_UTILITY_SCALE_V0912：AGGRO 轉為 Target Utility 的倍率。
#
# 【機制規則】
# 1. 每隻寶可夢各自保存「自己 → 每個敵人」的 AGGRO，不是全隊共用。
# 2. 真正造成 HP Damage 才產生主要 AGGRO；Invulnerability 擋掉的傷害不算。
# 3. 背擊、爆擊、短時間同一來源連打會額外增加。
# 4. DOT／Redirect 等 grant_energy=false 的間接傷害仍會產生較低 AGGRO。
# 5. Sleep / Fear / Root / Stun / Taunt 等有害狀態會再增加控制仇恨。
# 6. AGGRO 會隨時間自然衰減，敵人死亡後清除。
# 7. 一般 Target Utility 仍保留原 v0.15 + v0.68~v0.72 的全部邏輯，
#    本補丁只在最後追加 AGGRO Bonus。
# 8. 當候選敵人的 AGGRO 超過角色門檻時，可用較低切換門檻觸發
#    AGGRO_RETARGET；但 Execute 目標已低於 12% HP 時會提高轉火門檻，
#    避免「差一刀收掉卻突然回頭」。
# 9. Assassin / ignore_minor 對 AGGRO 反應非常低，Frontline 較穩，
#    Bruiser / Normal 中等，Responsive / Kiter 較容易自保。
#
# 【可調參數】
# 主要常數集中在 PMD_AC 模組最上方。若想讓角色更容易回頭：
# - 提高 AGGRO_UTILITY_SCALE_V0912，或降低 aggro_retarget_threshold_v0912。
# 若想讓角色更專注原目標：反向調整即可。
#
# 【事件／腳本呼叫方式】
# Runtime 自動運作，不需要事件設定。
# 開發／Boss 腳本可手動：
#   unit.add_aggro_v0912(enemy, 30, :script)
#   unit.aggro_value_v0912(enemy)
#   unit.clear_aggro_v0912(enemy)
#
# 【實際範例】
# 小火龍追低血綠毛蟲，波波從背後打 1 次：通常仍追綠毛蟲。
# 波波連續背擊 2~3 次：AGGRO 累積後可能：
#   [AGGRO_RETARGET] ALLY:小火龍 ENEMY:綠毛蟲 -> ENEMY:波波 ...
# 刺客型小拉達即使被坦克拍打，仍大多繼續執行 backline_low_def。
#
# 【注意事項】
# - AGGRO 是隱藏戰鬥資料，不新增玩家 HUD 數字。
# - Hard Taunt / forced_target 永遠優先，不會被 AGGRO 覆蓋。
# - 不改 Damage、Accuracy、Range、Projectile、Movement Core。
# - RGSS2 / Ruby 1.8 相容，不使用專案禁用的舊式 instance-variable probe。
#==============================================================================
module PMD_AC
  PATCH_VERSION_V0912 = '0.91.2'
  AGGRO_MAX_V0912 = 100.0
  AGGRO_DECAY_PER_FRAME_V0912 = 0.060
  AGGRO_DAMAGE_BASE_V0912 = 7.0
  AGGRO_DAMAGE_HP_SCALE_V0912 = 135.0
  AGGRO_BACK_BONUS_V0912 = 8.0
  AGGRO_CRIT_BONUS_V0912 = 8.0
  AGGRO_MELEE_BONUS_V0912 = 3.0
  AGGRO_REPEAT_BONUS_V0912 = 4.0
  AGGRO_REPEAT_MEMORY_V0912 = 150
  AGGRO_INDIRECT_MULT_V0912 = 0.35
  AGGRO_UTILITY_SCALE_V0912 = 72.0
  AGGRO_RETARGET_COOLDOWN_V0912 = 36
  AGGRO_EXECUTE_PROTECT_HP_V0912 = 0.12
  AGGRO_EXECUTE_EXTRA_THRESHOLD_V0912 = 26.0
  AGGRO_MIN_DELTA_V0912 = 12.0
  AGGRO_CONTROL_AMOUNT_V0912 = 14.0
  AGGRO_DEBUFF_AMOUNT_V0912 = 7.0
  AGGRO_HARMFUL_STATUS_V0912 = [
    :poison,:bad_poison,:burn,:sleep,:paralysis,:freeze,
    :confusion,:fear,:root,:stun,:taunt,:disable,:encore,
    :bind,:trap,:leech_seed
  ]
  AGGRO_CONTROL_STATUS_V0912 = [
    :sleep,:paralysis,:freeze,:confusion,:fear,:root,:stun,:taunt,
    :disable,:encore,:bind,:trap
  ]
end

class Game_PMDChessUnit
  attr_reader :aggro_last_source_v0912
  attr_reader :aggro_retarget_cooldown_v0912

  alias pmd_ac_v0912_initialize initialize unless method_defined?(:pmd_ac_v0912_initialize)
  def initialize(id,key,team,cell_x,cell_y,pokemon_instance=nil)
    pmd_ac_v0912_initialize(id,key,team,cell_x,cell_y,pokemon_instance)
    @aggro_v0912={}
    @aggro_last_source_v0912=nil
    @aggro_last_source_frames_v0912=0
    @aggro_retarget_cooldown_v0912=0
  end

  def aggro_hash_v0912
    @aggro_v0912={} if @aggro_v0912==nil
    @aggro_v0912
  end

  def aggro_value_v0912(enemy)
    return 0.0 if enemy==nil || enemy.dead? || enemy.team==@team
    aggro_hash_v0912[enemy].to_f
  end

  def clear_aggro_v0912(enemy=nil)
    if enemy==nil
      @aggro_v0912={}
    else
      aggro_hash_v0912.delete(enemy)
    end
  end

  def aggro_response_v0912
    v=case @threat_policy
    when :ignore_minor then 0.16
    when :hold_ground then 0.56
    when :protective then 0.74
    when :responsive then 1.00
    else 0.88
    end
    case @movement_policy
    when :assassin then v*=0.35
    when :bodyguard then v*=0.88
    when :bruiser then v*=1.08
    when :kiter,:controller then v*=1.05
    when :artillery then v*=0.94
    end
    PMD_AC.clamp(v,0.05,1.25)
  end

  def aggro_retarget_threshold_v0912
    return 999.0 if @movement_policy==:assassin || @threat_policy==:ignore_minor
    base=case @threat_policy
    when :responsive then 44.0
    when :protective then 64.0
    when :hold_ground then 76.0
    else 52.0
    end
    base-=4.0 if @movement_policy==:bruiser
    base-=3.0 if [:kiter,:controller].include?(@movement_policy)
    base+=6.0 if @movement_policy==:bodyguard
    PMD_AC.clamp(base,36.0,95.0)
  end

  def add_aggro_v0912(enemy,amount,reason=:generic,options=nil)
    return 0.0 if enemy==nil || enemy==self || enemy.dead?
    return 0.0 if enemy.team==@team
    amount=amount.to_f
    return aggro_value_v0912(enemy) if amount<=0.0
    old=aggro_value_v0912(enemy)
    now=PMD_AC.clamp(old+amount,0.0,PMD_AC::AGGRO_MAX_V0912)
    aggro_hash_v0912[enemy]=now
    @aggro_last_source_v0912=enemy
    @aggro_last_source_frames_v0912=PMD_AC::AGGRO_REPEAT_MEMORY_V0912
    if @scene!=nil
      @scene.log_event(:aggro,log_name+' <- '+enemy.log_name+
        ' +'+sprintf('%.1f',amount)+' reason='+reason.to_s+
        ' total='+sprintf('%.1f',now))
    end
    now
  end

  def add_damage_aggro_v0912(source,damage,critical=false,direct=true,arc=nil)
    return 0.0 if dead?
    return 0.0 if source==nil || !source.is_a?(Game_PMDChessUnit)
    return 0.0 if source.team==@team || source.dead? || damage.to_i<=0
    hp_rate=damage.to_f/[[@maxhp.to_i,1].max,1].max.to_f
    amount=PMD_AC::AGGRO_DAMAGE_BASE_V0912+
      [hp_rate*PMD_AC::AGGRO_DAMAGE_HP_SCALE_V0912,28.0].min
    amount+=PMD_AC::AGGRO_CRIT_BONUS_V0912 if critical
    amount+=PMD_AC::AGGRO_BACK_BONUS_V0912 if arc==:back
    if source.respond_to?(:melee?) && source.melee?
      amount+=PMD_AC::AGGRO_MELEE_BONUS_V0912
    end
    if @aggro_last_source_v0912==source && @aggro_last_source_frames_v0912.to_i>0
      amount+=PMD_AC::AGGRO_REPEAT_BONUS_V0912
    end
    amount*=PMD_AC::AGGRO_INDIRECT_MULT_V0912 unless direct
    reason=direct ? :damage : :indirect_damage
    reason=:back_attack if direct && arc==:back
    reason=:critical if direct && critical && arc!=:back
    add_aggro_v0912(source,amount,reason)
  end

  def harmful_status_v0912?(key)
    PMD_AC::AGGRO_HARMFUL_STATUS_V0912.include?(key)
  end

  def control_status_v0912?(key)
    PMD_AC::AGGRO_CONTROL_STATUS_V0912.include?(key)
  end

  alias pmd_ac_v0912_update_threat_timers update_threat_timers unless method_defined?(:pmd_ac_v0912_update_threat_timers)
  def update_threat_timers
    pmd_ac_v0912_update_threat_timers
    h=aggro_hash_v0912
    dead_keys=[]
    h.keys.each do |enemy|
      if enemy==nil || enemy.dead? || enemy.team==@team
        dead_keys.push(enemy);next
      end
      v=h[enemy].to_f-PMD_AC::AGGRO_DECAY_PER_FRAME_V0912
      if v<=0.20
        dead_keys.push(enemy)
      else
        h[enemy]=v
      end
    end
    dead_keys.each{|k|h.delete(k)}
    if @aggro_last_source_frames_v0912.to_i>0
      @aggro_last_source_frames_v0912-=1
      if @aggro_last_source_frames_v0912<=0
        @aggro_last_source_frames_v0912=0
        @aggro_last_source_v0912=nil
      end
    end
    if @aggro_retarget_cooldown_v0912.to_i>0
      @aggro_retarget_cooldown_v0912-=1
    end
  end

  alias pmd_ac_v0912_receive_damage receive_damage unless method_defined?(:pmd_ac_v0912_receive_damage)
  def receive_damage(value,source=nil,grant_energy=true,bypass_link=false,critical=false)
    before=@hp.to_i
    arc=nil
    if source!=nil && source.is_a?(Game_PMDChessUnit) && source.team!=@team
      begin;arc=incoming_arc_from(source);rescue;arc=nil;end
    end
    result=pmd_ac_v0912_receive_damage(value,source,grant_energy,bypass_link,critical)
    actual=[before-@hp.to_i,0].max
    add_damage_aggro_v0912(source,actual,critical,grant_energy ? true:false,arc) if actual>0
    result
  end

  alias pmd_ac_v0912_apply_status apply_status unless method_defined?(:pmd_ac_v0912_apply_status)
  def apply_status(key,options={},source=nil)
    before=status?(key)
    result=pmd_ac_v0912_apply_status(key,options,source)
    if !before && status?(key) && harmful_status_v0912?(key) &&
       source!=nil && source.is_a?(Game_PMDChessUnit) && source.team!=@team
      amount=control_status_v0912?(key) ? PMD_AC::AGGRO_CONTROL_AMOUNT_V0912 :
                                         PMD_AC::AGGRO_DEBUFF_AMOUNT_V0912
      add_aggro_v0912(source,amount,:control)
    end
    result
  end

  alias pmd_ac_v0912_target_utility target_utility unless method_defined?(:pmd_ac_v0912_target_utility)
  def target_utility(enemy)
    base=pmd_ac_v0912_target_utility(enemy)
    return base if enemy==nil || enemy.dead?
    return base if enemy.respond_to?(:battle_object?) && enemy.battle_object?
    bonus=aggro_value_v0912(enemy)*PMD_AC::AGGRO_UTILITY_SCALE_V0912*aggro_response_v0912
    base.to_f+bonus
  end

  def aggro_execute_lock_v0912?
    return false if @target==nil || @target.dead? || @target_policy!=:execute
    hp_rate=@target.hp.to_f/[[@target.maxhp.to_i,1].max,1].max.to_f
    hp_rate<=PMD_AC::AGGRO_EXECUTE_PROTECT_HP_V0912
  end

  def aggro_retarget_ready_v0912?(candidate)
    return false if candidate==nil || candidate.dead? || candidate==@target
    return false if taunted? || @aggro_retarget_cooldown_v0912.to_i>0
    value=aggro_value_v0912(candidate)
    threshold=aggro_retarget_threshold_v0912
    threshold+=PMD_AC::AGGRO_EXECUTE_EXTRA_THRESHOLD_V0912 if aggro_execute_lock_v0912?
    return false if value<threshold
    current=aggro_value_v0912(@target)
    return false if value<current+PMD_AC::AGGRO_MIN_DELTA_V0912
    true
  end

  alias pmd_ac_v0912_reevaluate_target reevaluate_target unless method_defined?(:pmd_ac_v0912_reevaluate_target)
  def reevaluate_target
    candidate,candidate_score=best_target_candidate
    if candidate!=nil && @target!=nil && aggro_retarget_ready_v0912?(candidate)
      old=@target
      current_score=target_utility(old).to_f
      # 高仇恨只放寬「切換慣性」，仍要求候選 Utility 不至於荒謬地低於舊目標。
      if candidate_score.to_f>=current_score*0.92
        value=aggro_value_v0912(candidate)
        cur=aggro_value_v0912(old)
        if @scene!=nil
          @scene.log_event(:aggro_retarget,log_name+' '+old.log_name+' -> '+candidate.log_name+
            ' reason=self_defense aggro='+sprintf('%.1f',value)+
            ' current_aggro='+sprintf('%.1f',cur)+
            ' policy='+@target_policy.to_s)
        end
        set_target(candidate)
        @aggro_retarget_cooldown_v0912=PMD_AC::AGGRO_RETARGET_COOLDOWN_V0912
        return
      end
    end
    pmd_ac_v0912_reevaluate_target
  end
end
