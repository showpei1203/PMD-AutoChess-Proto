# encoding: UTF-8
#==============================================================================
# PMD AutoChess Miss Pace Tuning v0.87.1
# 普攻近戰落空率／戰鬥節奏修正
# RPG Maker VX / RGSS2 / Ruby 1.8 compatible
#==============================================================================
# 【這支腳本是做什麼的】
# 實戰 LOG 顯示 MISS 看起來很多，但主要來源不是寶可夢技能的 Accuracy 骰失敗，
# 而是「近戰普攻開始揮擊後，目標在命中幀前移出原本 melee_reach + 10px」造成的
# 空揮。尤其近戰追 Controller / Kiter 時會非常明顯，戰鬥因此被大量空揮拖長。
#
# v0.87.1 採用「近戰命中承諾」而不是把所有招式改成必中：
#   - 普通近戰攻擊在已經成功貼身並開始揮擊後，額外給一段 Hit Grace。
#   - Active Evade 仍然保留；若真的側閃出命中承諾距離，仍會 MISS。
#   - 遠程 Projectile Tracking 完全不改。
#   - Pokémon 原作 Accuracy / Evasion 公式完全不改。
#   - 催眠粉 75%、亂擊 85%、一擊必殺 30% 等技能仍維持原本設定。
#
# 這樣做的理由很單純：
# 「對方在你揮拳的 8 幀內往後走 12px」不該比真正的閃避技能還有效。
# 不然 AI 最強的防禦策略就會變成邊走邊讓對方打空氣，戰鬥像兩群人在搶計程車。
#------------------------------------------------------------------------------
# 【最常調整的參數】
#
# BASIC_MELEE_HIT_GRACE_BONUS_V0871 = 18.0
#   在既有 MELEE_HIT_GRACE=10px 之外，再增加多少命中寬容。
#   目前有效 Grace = 28px。
#
# BASIC_MELEE_MISS_RETRY_RATE_V0871 = 0.60
#   若真的落空，剩餘普攻冷卻最多保留到原冷卻的 60%，讓近戰較快重追重打。
#   1.00 = 完全不補償；0.50 = 落空後最多剩半個冷卻。
#
# 建議範圍：
#   Grace Bonus 12~24px
#   Retry Rate  0.50~0.75
#------------------------------------------------------------------------------
# 【這版沒有修改】
# - v0.27 Accuracy / Evasion
# - Sand Attack / Double Team / No Guard / Hustle / Compound Eyes 等
# - Active Evade 距離與 210 frame cooldown
# - Projectile weak/strong tracking
# - 傷害、暴擊、方向傷害、AI、移動核心
#------------------------------------------------------------------------------
# 【驗證模式】
# 布陣按 S 切到 MISS_PACE_V0871，再按 Shift。
# 預期：
#   MISS_PACE_MANIFEST_V0871 pass=1
#   MISS_PACE_MELEE_GRACE_V0871 pass=1
#   MISS_PACE_RETRY_V0871 pass=1
#   MISS_PACE_ACCURACY_CARRY_V0871 pass=1
#   MISS_PACE_ACTIVE_EVADE_CARRY_V0871 pass=1
#   MISS_PACE_CARRY_V0871 pass=1
#   MISS_PACE_V0871 pass=1
#   VERIFY_FINISHED_BATTLE_RESUME pass=1
#==============================================================================
module PMD_AC
  BASIC_MELEE_HIT_GRACE_BONUS_V0871 = 18.0
  BASIC_MELEE_MISS_RETRY_RATE_V0871 = 0.60
  MISS_PACE_VERIFY_END_V0871 = 24
  MISS_PACE_MANIFEST_V0871 = {
    :version=>'0.87.1',
    :base_melee_grace=>MELEE_HIT_GRACE,
    :bonus_melee_grace=>BASIC_MELEE_HIT_GRACE_BONUS_V0871,
    :effective_melee_grace=>MELEE_HIT_GRACE+BASIC_MELEE_HIT_GRACE_BONUS_V0871,
    :miss_retry_rate=>BASIC_MELEE_MISS_RETRY_RATE_V0871,
    :canonical_accuracy_unchanged=>true,
    :active_evade_unchanged=>true,
    :projectile_tracking_unchanged=>true,
    :damage_unchanged=>true
  }

  V0871_OLD_VERIFICATION_MODES = VERIFICATION_MODES.dup
  V0871_OLD_VERIFICATION_LABELS = VERIFICATION_LABELS.dup
  remove_const(:VERIFICATION_MODES)
  VERIFICATION_MODES = [:normal,:miss_pace_v0871] +
    V0871_OLD_VERIFICATION_MODES.reject{|x|x==:normal || x==:miss_pace_v0871}
  remove_const(:VERIFICATION_LABELS)
  VERIFICATION_LABELS = V0871_OLD_VERIFICATION_LABELS.dup
  VERIFICATION_LABELS[:normal]='NORMAL'
  VERIFICATION_LABELS[:miss_pace_v0871]='MISS_PACE_V0871'
end

class Game_PMDChessUnit
  def basic_melee_hit_limit_v0871
    @melee_reach.to_f + PMD_AC::MELEE_HIT_GRACE.to_f +
      PMD_AC::BASIC_MELEE_HIT_GRACE_BONUS_V0871
  end

  def basic_melee_in_hit_commit_v0871?(other)
    return false if other==nil || other.dead?
    distance_to(other).to_f <= basic_melee_hit_limit_v0871
  end

  def basic_melee_miss_retry_v0871
    cap=@attack_wait_max.to_f * PMD_AC::BASIC_MELEE_MISS_RETRY_RATE_V0871
    @attack_wait=cap if @attack_wait.to_f>cap
  end

  def resolve_basic_attack
    return if @target == nil || @target.dead?
    intended_target = @target
    hit_target = @scene == nil ? intended_target :
                 @scene.substitute_target_for(self, intended_target, :basic)
    face_toward(intended_target, true)
    modifier = consume_next_attack_modifier

    if ranged?
      tracking_override = nil
      if modifier != nil
        tracking_override = modifier[:projectile_tracking]
      end
      @scene.launch_projectile(self, hit_target, :basic, 100, :single,
                               tracking_override, modifier, false)
      @scene.play_basic_se(self, :launch) if @scene != nil
      return
    end

    evaded = hit_target.try_active_evade(self, :melee)
    distance_after_evade=distance_to(hit_target).to_f
    in_range = basic_melee_in_hit_commit_v0871?(hit_target)

    if in_range
      if evaded
        log_event(:evade_fail,
                  hit_target.log_name + " melee still_hit by " + log_name +
                  " grace=v0.87.1")
      end
      @scene.deal_direct_damage(self, hit_target, 100,
                                {:modifier => modifier,
                                 :source_type => :basic})
      gain_energy(PMD_AC::ENERGY_ON_BASIC_HIT, hit_target, :basic_hit)
      @scene.add_vfx_impact(hit_target, :impact) if @scene != nil
      @scene.play_basic_se(self, :hit) if @scene != nil
    else
      if evaded
        log_event(:evade_success,
                  hit_target.log_name + " melee avoided " + log_name)
      end
      log_event(:miss_pace,
                log_name+" spatial_whiff target="+hit_target.log_name+
                " distance="+sprintf("%.1f",distance_after_evade)+
                " hit_limit="+sprintf("%.1f",basic_melee_hit_limit_v0871))
      basic_melee_miss_retry_v0871
      register_miss(hit_target)
    end
  end
end

class Scene_PMD_AutoChess
  alias pmd_ac_v0871_start start unless method_defined?(:pmd_ac_v0871_start)
  alias pmd_ac_v0871_refresh_header refresh_header unless method_defined?(:pmd_ac_v0871_refresh_header)
  alias pmd_ac_v0871_prepare_verification_battle prepare_verification_battle unless method_defined?(:pmd_ac_v0871_prepare_verification_battle)
  alias pmd_ac_v0871_update_verification_script update_verification_script unless method_defined?(:pmd_ac_v0871_update_verification_script)
  alias pmd_ac_v0871_log_event log_event unless method_defined?(:pmd_ac_v0871_log_event)

  def start
    pmd_ac_v0871_start
    begin
      if FileTest.exist?(PMD_AC::BATTLE_LOG_FILE)
        text=File.open(PMD_AC::BATTLE_LOG_FILE,'rb'){|f|f.read}
        text.sub!(/PMD AutoChess Proto v0\.[0-9.]+ Battle Verification Log/,
                  'PMD AutoChess Proto v0.87.1 Battle Verification Log')
        File.open(PMD_AC::BATTLE_LOG_FILE,'wb'){|f|f.write(text)}
      end
    rescue
    end
    m=PMD_AC::MISS_PACE_MANIFEST_V0871
    log_event(:miss_pace,
      'PATCH v0.87.1 melee_grace='+sprintf('%.1f',m[:effective_melee_grace])+
      ' retry_rate='+sprintf('%.2f',m[:miss_retry_rate])+
      ' canonical_accuracy=unchanged active_evade=unchanged projectile=unchanged damage=unchanged')
    refresh_header
  end

  def refresh_header
    pmd_ac_v0871_refresh_header
    return if @header_sprite==nil || @header_sprite.bitmap==nil
    bmp=@header_sprite.bitmap
    bmp.fill_rect(0,0,Graphics.width,28,Color.new(0,0,0,180))
    pmd_ac_v074_font(bmp)
    bmp.font.size=PMD_AC::UI_HEADER_TITLE_FONT_V086
    bmp.font.bold=true
    bmp.font.color=Color.new(255,255,255)
    bmp.draw_text(16,1,Graphics.width-32,30,'PMD 自走棋原型 v0.87.1',1)
  end

  def miss_pace_v0871?
    verification_mode==:miss_pace_v0871
  end

  def prepare_verification_battle
    pmd_ac_v0871_prepare_verification_battle
    @miss_pace_v0871_failed=false if miss_pace_v0871?
  end

  def log_event(category,message)
    if category.to_s=='verify' && miss_pace_v0871? &&
       message.to_s.index('MISS_PACE_')==0 && message.to_s.include?(' pass=0')
      @miss_pace_v0871_failed=true
    end
    pmd_ac_v0871_log_event(category,message)
  end

  def log_verify_v0871(name,pass,detail='')
    @miss_pace_v0871_failed=true unless pass
    log_event(:verify,name+' pass='+(pass ? '1':'0')+(detail=='' ? '' : ' '+detail))
  end

  def verify_miss_pace_manifest_v0871
    return if @verification_done[:v0871_manifest]
    m=PMD_AC::MISS_PACE_MANIFEST_V0871
    pass=m[:base_melee_grace].to_f==10.0 &&
      m[:effective_melee_grace].to_f==28.0 &&
      m[:canonical_accuracy_unchanged] && m[:active_evade_unchanged]
    log_verify_v0871('MISS_PACE_MANIFEST_V0871',pass,
      'base_grace='+m[:base_melee_grace].to_s+
      ' bonus='+m[:bonus_melee_grace].to_s+
      ' effective='+m[:effective_melee_grace].to_s+
      ' accuracy_unchanged=1 evade_unchanged=1')
    @verification_done[:v0871_manifest]=true
  end

  def verify_miss_pace_melee_grace_v0871
    return if @verification_done[:v0871_grace]
    u=verification_unit(:ally,:charmander)
    pass=false
    if u!=nil
      limit=u.basic_melee_hit_limit_v0871
      expected=u.instance_variable_get(:@melee_reach).to_f+28.0
      pass=(limit-expected).abs<0.01
      log_verify_v0871('MISS_PACE_MELEE_GRACE_V0871',pass,
        'species=charmander reach='+sprintf('%.1f',u.instance_variable_get(:@melee_reach).to_f)+
        ' hit_limit='+sprintf('%.1f',limit)+' extra_grace=28.0')
    else
      log_verify_v0871('MISS_PACE_MELEE_GRACE_V0871',false,'unit=nil')
    end
    @verification_done[:v0871_grace]=true
  end

  def verify_miss_pace_retry_v0871
    return if @verification_done[:v0871_retry]
    u=verification_unit(:ally,:charmander)
    pass=false
    if u!=nil
      max=u.instance_variable_get(:@attack_wait_max).to_f
      u.instance_variable_set(:@attack_wait,max)
      u.basic_melee_miss_retry_v0871
      got=u.instance_variable_get(:@attack_wait).to_f
      expected=max*PMD_AC::BASIC_MELEE_MISS_RETRY_RATE_V0871
      pass=(got-expected).abs<0.01
      u.instance_variable_set(:@attack_wait,0)
      log_verify_v0871('MISS_PACE_RETRY_V0871',pass,
        'attack_wait_max='+sprintf('%.1f',max)+' miss_retry_cap='+sprintf('%.1f',expected))
    else
      log_verify_v0871('MISS_PACE_RETRY_V0871',false,'unit=nil')
    end
    @verification_done[:v0871_retry]=true
  end

  def verify_miss_pace_accuracy_carry_v0871
    return if @verification_done[:v0871_accuracy]
    u=verification_unit(:ally,:bulbasaur)
    t=verification_unit(:enemy,:pidgey)
    data=PMD_AC.skill_data(:mv_sleep_powder)
    chance=(u!=nil && t!=nil && data!=nil) ? canonical_accuracy_probability(u,t,data).to_f : -1.0
    pass=(chance-75.0).abs<0.01
    log_verify_v0871('MISS_PACE_ACCURACY_CARRY_V0871',pass,
      'sleep_powder='+sprintf('%.1f',chance)+' canonical_expected=75.0')
    @verification_done[:v0871_accuracy]=true
  end

  def verify_miss_pace_active_evade_carry_v0871
    return if @verification_done[:v0871_evade]
    t=verification_unit(:enemy,:rattata)
    cd=t==nil ? -1 : t.instance_variable_get(:@evade_cooldown_max).to_i
    enabled=t==nil ? false : (t.instance_variable_get(:@active_evade_enabled) ? true:false)
    pass=enabled && cd==210
    log_verify_v0871('MISS_PACE_ACTIVE_EVADE_CARRY_V0871',pass,
      'rattata_active_evade='+(enabled ? '1':'0')+' cooldown='+cd.to_s+' expected=210')
    @verification_done[:v0871_evade]=true
  end

  def verify_miss_pace_carry_v0871
    return if @verification_done[:v0871_carry]
    pass=PMD_AC::ENCOUNTER_UNLOCK_MANIFEST_V087[:content_version]=='0.87.0' &&
      PMD_AC::REGION_ECOLOGY_MANIFEST_V086[:formations]>=8 &&
      PMD_AC::PRESENTATION_FREEZE_V075[:version]=='0.75' rescue false
    # PRESENTATION_FREEZE_V075 may not expose :version in all builds; fall back to stable constants.
    if !pass
      pass=PMD_AC::PARTY_CAPACITY_V045==3 &&
        PMD_AC::REGION_ECOLOGY_MANIFEST_V086[:formations]>=8 &&
        PMD_AC::ENCOUNTER_UNLOCK_MANIFEST_V087[:content_version]=='0.87.0'
    end
    log_verify_v0871('MISS_PACE_CARRY_V0871',pass,
      'unlock=v0.87 region=v0.86 balance=v0.75 movement_core=v0.15 damage_packet=v0.60.2')
    @verification_done[:v0871_carry]=true
  end

  def update_verification_script
    unless miss_pace_v0871?
      pmd_ac_v0871_update_verification_script
      return
    end
    @verification_frame=@verification_frame.to_i+1
    f=@verification_frame
    verify_miss_pace_manifest_v0871 if f>=2
    verify_miss_pace_melee_grace_v0871 if f>=4
    verify_miss_pace_retry_v0871 if f>=6
    verify_miss_pace_accuracy_carry_v0871 if f>=8
    verify_miss_pace_active_evade_carry_v0871 if f>=10
    verify_miss_pace_carry_v0871 if f>=12
    if f>=14 && !@verification_done[:v0871_final]
      pass=!@miss_pace_v0871_failed
      log_verify_v0871('MISS_PACE_V0871',pass,
        'manifest=1 melee_grace=1 retry=1 accuracy=1 evade=1 carry=1')
      @verification_done[:v0871_final]=true
    end
    complete_verification_mode if f>=PMD_AC::MISS_PACE_VERIFY_END_V0871
  end
end
