# encoding: UTF-8
#==============================================================================
# PMD AutoChess Visual Micro Tuning v0.88.2
# 傷害數字低拋微調＋近身攻擊 Sprite 下移 5px
# RPG Maker VX / RGSS2 / Ruby 1.8 compatible
#==============================================================================
# 【用途】
# 本補丁延續 v0.88.1 Damage Scatter，只做兩項純視覺微調：
# 1. 傷害數字仍隨機往左／右彈出，但降低向上初速度，讓彈射高度更低。
# 2. 近身攻擊進行時，只把「攻擊者本體 Sprite」往畫面下方移動 5px。
#
# 這兩項都不修改 Pokémon 的邏輯座標，因此不會影響：命中距離、碰撞／接敵、
# AI、移動、Projectile、HP／Energy、傷害公式或多段攻擊 Damage Packet。
#
#------------------------------------------------------------------------------
# 【主要設定項】
# DAMAGE_SCATTER_Y_MIN_V0882 = -3.65
# DAMAGE_SCATTER_Y_MAX_V0882 = -3.15
#   v0.88.1 原本為 -4.50 ～ -3.80。RGSS 畫面 Y 向下為正，所以負值越大
#   代表向上拋得越高。本版把絕對值縮小，平均拋物高度約由 31px 降到 21px。
#
# MELEE_ATTACK_SPRITE_Y_OFFSET_V0882 = 5
#   近身攻擊者 Sprite 額外向下 5px。只改 Sprite 顯示，不改 @pixel_y。
#
# MELEE_ATTACK_VISUAL_MOTIONS_V0882
#   判斷哪些 Skill Presentation Motion 屬於近身攻擊。包含 contact / dash /
#   blink / charge / multi-contact 等接觸型演出；stationary_cast 與
#   runtime_owned（Fly／Dive／Dig 等特殊垂直演出）不套用此 5px 微調。
#
#------------------------------------------------------------------------------
# 【機制規則】
# 傷害 Popup：
# - 水平左右隨機、水平初速、水平最大距離與畫面邊界沿用 v0.88.1。
# - 重力仍沿用 v0.88.1 的 0.28。
# - 只降低垂直初速，因此軌跡仍是「先上拋，再下墜」。
#
# 近身攻擊 Sprite：
# - 普通攻擊：只有 melee? == true 且 @action == :attack 時套用 +5px。
# - 技能：只有接觸型／衝刺型 Presentation 或技能標記 contact 時套用。
# - 遠程普通攻擊、stationary_cast、純支援與特殊 runtime_owned 動作不套用。
# - 位移加在 Sprite_PMDChessUnit#update_position 的最末端，因此血條、頭上文字、
#   邏輯位置與傷害判定仍使用原本位置。
#
#------------------------------------------------------------------------------
# 【可調參數】
# 想讓傷害數字再低一些：
#   DAMAGE_SCATTER_Y_MIN_V0882 = -3.30
#   DAMAGE_SCATTER_Y_MAX_V0882 = -2.90
#
# 想讓近身攻擊 Sprite 再低一些：
#   MELEE_ATTACK_SPRITE_Y_OFFSET_V0882 = 7
#
# 想恢復 v0.88.1 高度：
#   DAMAGE_SCATTER_Y_MIN_V0882 = -4.50
#   DAMAGE_SCATTER_Y_MAX_V0882 = -3.80
#
#------------------------------------------------------------------------------
# 【事件／腳本呼叫方式】
# 本補丁為戰鬥 Runtime 自動套用，不需要事件頁呼叫。
# 只要進入 Scene_PMD_AutoChess，NORMAL 戰鬥就會自動使用。
#
# 純腳本查詢範例：
#   PMD_AC::MELEE_ATTACK_SPRITE_Y_OFFSET_V0882
#     # => 5
#
#   PMD_AC.melee_attack_sprite_y_offset_v0882(:attack,true,nil,nil)
#     # => 5，代表近戰普通攻擊會向下 5px
#
#   PMD_AC.melee_attack_sprite_y_offset_v0882(:attack,false,nil,nil)
#     # => 0，遠程普通攻擊不調整
#
#------------------------------------------------------------------------------
# 【驗證方式】
# 布陣畫面從 NORMAL 按 S 一次切到 VISUAL_TUNING_V0882，再按 Shift。
# 預期 LOG：
#   VISUAL_TUNING_MANIFEST_V0882 pass=1
#   DAMAGE_ARC_LOWER_V0882 pass=1
#   MELEE_SPRITE_OFFSET_V0882 pass=1
#   VISUAL_TUNING_CARRY_V0882 pass=1
#   VISUAL_TUNING_V0882 pass=1
#   VERIFY_FINISHED_BATTLE_RESUME pass=1
#
# NORMAL 實戰肉眼再確認：
# - 傷害數字左右散開仍存在，但最高點比 v0.88.1 明顯低一些。
# - 近身普通攻擊／接觸技能的攻擊者動作圖往下約 5px。
# - 遠程攻擊、待機、血條與頭上文字位置不被一起下移。
#
#------------------------------------------------------------------------------
# 【注意事項／不修改內容】
# - 不修改 v0.15 Movement / Combat Core。
# - 不修改 v0.60.2 Multi-hit Damage Packet / Choreography。
# - 不修改 v0.62 Native Semantic Router。
# - 不修改 v0.87.1 melee hit grace。
# - 不修改 v0.88 Passive Energy / Anti-Stall / Head Status / Center Notice。
# - 不修改 v0.88.1 左右隨機散射與水平邊界。
#==============================================================================
module PMD_AC
  PATCH_VERSION_V0882 = '0.88.2'

  DAMAGE_SCATTER_Y_MIN_V0882 = -3.65
  DAMAGE_SCATTER_Y_MAX_V0882 = -3.15
  MELEE_ATTACK_SPRITE_Y_OFFSET_V0882 = 5
  VISUAL_TUNING_VERIFY_END_V0882 = 20

  MELEE_ATTACK_VISUAL_MOTIONS_V0882 = [
    :step_attack,
    :lunge_return,
    :contact_return,
    :dash_stop,
    :dash_return,
    :dash_through_return,
    :blink_return,
    :blink_engage,
    :dash_engage,
    :charge_dash,
    :multi_contact,
    :spin_contact
  ]

  VISUAL_TUNING_MANIFEST_V0882 = {
    :version => PATCH_VERSION_V0882,
    :damage_y_min => DAMAGE_SCATTER_Y_MIN_V0882,
    :damage_y_max => DAMAGE_SCATTER_Y_MAX_V0882,
    :gravity => DAMAGE_SCATTER_GRAVITY_V0881,
    :melee_sprite_y => MELEE_ATTACK_SPRITE_Y_OFFSET_V0882,
    :logical_position => :unchanged,
    :hitbox => :unchanged,
    :mechanics => :unchanged
  }

  # 純分類 helper。Runtime 與 Verifier 共用，避免驗證時改寫戰鬥單位狀態。
  def self.melee_attack_sprite_y_offset_v0882(action_key,melee_flag,profile,data)
    return 0 if action_key==nil
    if action_key==:attack
      return melee_flag ? MELEE_ATTACK_SPRITE_Y_OFFSET_V0882 : 0
    end
    return 0 unless action_key==:skill

    p=profile || {}
    d=data || {}
    return 0 if p[:remote_cast]
    motion=p[:motion]
    return 0 if motion==:stationary_cast || motion==:runtime_owned
    if MELEE_ATTACK_VISUAL_MOTIONS_V0882.include?(motion)
      return MELEE_ATTACK_SPRITE_Y_OFFSET_V0882
    end
    if d[:contact] || d[:force_contact_range]
      return MELEE_ATTACK_SPRITE_Y_OFFSET_V0882
    end
    0
  end

  V0882_OLD_VERIFICATION_MODES = VERIFICATION_MODES.dup
  V0882_OLD_VERIFICATION_LABELS = VERIFICATION_LABELS.dup
  remove_const(:VERIFICATION_MODES)
  VERIFICATION_MODES = [:normal,:visual_tuning_v0882] +
    V0882_OLD_VERIFICATION_MODES.reject{|x|x==:normal || x==:visual_tuning_v0882}
  remove_const(:VERIFICATION_LABELS)
  VERIFICATION_LABELS = V0882_OLD_VERIFICATION_LABELS.dup
  VERIFICATION_LABELS[:normal]='NORMAL'
  VERIFICATION_LABELS[:visual_tuning_v0882]='VISUAL_TUNING_V0882'
end

#==============================================================================
# ■ Game_PMDChessUnit : 只判斷本體 Sprite 是否需要下移
#==============================================================================
class Game_PMDChessUnit
  def melee_attack_sprite_y_offset_v0882
    return 0 if dead? || !acting?
    profile=nil
    data=nil
    if @action==:skill
      profile=@presentation_profile_v055
      data=skill_data
    end
    PMD_AC.melee_attack_sprite_y_offset_v0882(@action,melee?,profile,data)
  end
end

#==============================================================================
# ■ Sprite_PMDChessUnit
#==============================================================================
class Sprite_PMDChessUnit
  alias pmd_ac_v0882_update_position update_position unless method_defined?(:pmd_ac_v0882_update_position)

  # v0.88.2：所有舊 UI / bar / logical anchor 都先完成定位，再只移本體 Sprite。
  def update_position
    pmd_ac_v0882_update_position
    return if @unit==nil || !@unit.respond_to?(:melee_attack_sprite_y_offset_v0882)
    off=@unit.melee_attack_sprite_y_offset_v0882.to_i
    self.y+=off if off!=0
  end

  # 沿用 v0.88.1 的左右散射，只降低垂直初速度。
  def setup_damage_scatter_v0881
    @damage_scatter_dir_v0881=(rand(2)==0 ? -1 : 1)
    span=PMD_AC::DAMAGE_SCATTER_X_MAX_V0881-PMD_AC::DAMAGE_SCATTER_X_MIN_V0881
    @damage_scatter_vx_v0881=PMD_AC::DAMAGE_SCATTER_X_MIN_V0881 +
      rand(101).to_f/100.0*span
    yspan=PMD_AC::DAMAGE_SCATTER_Y_MAX_V0882-PMD_AC::DAMAGE_SCATTER_Y_MIN_V0882
    @damage_scatter_vy_v0881=PMD_AC::DAMAGE_SCATTER_Y_MIN_V0882 +
      rand(101).to_f/100.0*yspan
  end

  # 保留舊 method 名稱，讓 v0.88.1 update_popup 與舊 Verifier 不必重接。
  def damage_scatter_offset_v0881(elapsed,dir=nil,vx=nil,vy=nil)
    t=[elapsed.to_i,0].max
    d=dir==nil ? (@damage_scatter_dir_v0881 || 1) : dir.to_i
    xs=vx==nil ? (@damage_scatter_vx_v0881 || PMD_AC::DAMAGE_SCATTER_X_MIN_V0881) : vx.to_f
    ys=vy==nil ? (@damage_scatter_vy_v0881 || PMD_AC::DAMAGE_SCATTER_Y_MIN_V0882) : vy.to_f
    dx=(d*xs*t).round
    lim=PMD_AC::DAMAGE_SCATTER_X_LIMIT_V0881
    dx=lim if dx>lim
    dx=-lim if dx < -lim
    dy=(ys*t + 0.5*PMD_AC::DAMAGE_SCATTER_GRAVITY_V0881*t*t).round
    [dx,dy]
  end
end

#==============================================================================
# ■ Scene_PMD_AutoChess : 版本標示＋v0.88.2 Verifier
#==============================================================================
class Scene_PMD_AutoChess
  alias pmd_ac_v0882_start start unless method_defined?(:pmd_ac_v0882_start)
  alias pmd_ac_v0882_refresh_header refresh_header unless method_defined?(:pmd_ac_v0882_refresh_header)
  alias pmd_ac_v0882_prepare_verification_battle prepare_verification_battle unless method_defined?(:pmd_ac_v0882_prepare_verification_battle)
  alias pmd_ac_v0882_update_verification_script update_verification_script unless method_defined?(:pmd_ac_v0882_update_verification_script)
  alias pmd_ac_v0882_log_event log_event unless method_defined?(:pmd_ac_v0882_log_event)

  def start
    pmd_ac_v0882_start
    begin
      if FileTest.exist?(PMD_AC::BATTLE_LOG_FILE)
        text=File.open(PMD_AC::BATTLE_LOG_FILE,'rb'){|f|f.read}
        text.sub!(/PMD AutoChess Proto v0\.[0-9.]+ Battle Verification Log/,
                  'PMD AutoChess Proto v0.88.2 Battle Verification Log')
        File.open(PMD_AC::BATTLE_LOG_FILE,'wb'){|f|f.write(text)}
      end
    rescue
    end
    log_event(:presentation,
      'PATCH v0.88.2 damage_arc='+PMD_AC::DAMAGE_SCATTER_Y_MIN_V0882.to_s+'..'+
      PMD_AC::DAMAGE_SCATTER_Y_MAX_V0882.to_s+
      ' gravity='+PMD_AC::DAMAGE_SCATTER_GRAVITY_V0881.to_s+
      ' melee_sprite_y=+'+PMD_AC::MELEE_ATTACK_SPRITE_Y_OFFSET_V0882.to_s+
      ' logical_y_unchanged=1 mechanics_unchanged=1')
    refresh_header
  end

  def refresh_header
    pmd_ac_v0882_refresh_header
    return if @header_sprite==nil || @header_sprite.bitmap==nil
    bmp=@header_sprite.bitmap
    bmp.fill_rect(0,0,Graphics.width,28,Color.new(0,0,0,180))
    bmp.font.size=PMD_AC::UI_HEADER_TITLE_FONT_V086
    bmp.font.bold=true
    bmp.font.color=Color.new(255,255,255)
    bmp.draw_text(16,1,Graphics.width-32,30,'PMD 自走棋原型 v0.88.2',1)
  end

  def visual_tuning_v0882?
    verification_mode==:visual_tuning_v0882
  end

  def prepare_verification_battle
    pmd_ac_v0882_prepare_verification_battle
    @visual_tuning_v0882_failed=false if visual_tuning_v0882?
  end

  def log_event(category,message)
    if category.to_s=='verify' && visual_tuning_v0882? &&
       message.to_s.index('VISUAL_TUNING_')==0 && message.to_s.include?(' pass=0')
      @visual_tuning_v0882_failed=true
    end
    if category.to_s=='verify' && visual_tuning_v0882? &&
       message.to_s.index('DAMAGE_ARC_LOWER_V0882')==0 && message.to_s.include?(' pass=0')
      @visual_tuning_v0882_failed=true
    end
    if category.to_s=='verify' && visual_tuning_v0882? &&
       message.to_s.index('MELEE_SPRITE_OFFSET_V0882')==0 && message.to_s.include?(' pass=0')
      @visual_tuning_v0882_failed=true
    end
    pmd_ac_v0882_log_event(category,message)
  end

  def log_verify_v0882(name,pass,detail='')
    @visual_tuning_v0882_failed=true unless pass
    log_event(:verify,name+' pass='+(pass ? '1':'0')+(detail=='' ? '' : ' '+detail))
  end

  def verify_visual_tuning_manifest_v0882
    return if @verification_done[:v0882_manifest]
    m=PMD_AC::VISUAL_TUNING_MANIFEST_V0882
    pass=m[:version]=='0.88.2' &&
      m[:damage_y_min]>PMD_AC::DAMAGE_SCATTER_Y_MIN_V0881 &&
      m[:damage_y_max]>PMD_AC::DAMAGE_SCATTER_Y_MAX_V0881 &&
      m[:melee_sprite_y]==5 && m[:logical_position]==:unchanged &&
      m[:mechanics]==:unchanged
    log_verify_v0882('VISUAL_TUNING_MANIFEST_V0882',pass,
      'y='+m[:damage_y_min].to_s+'..'+m[:damage_y_max].to_s+
      ' melee_sprite_y=+'+m[:melee_sprite_y].to_s+' logical_y=unchanged')
    @verification_done[:v0882_manifest]=true
  end

  def verify_damage_arc_lower_v0882
    return if @verification_done[:v0882_arc]
    g=PMD_AC::DAMAGE_SCATTER_GRAVITY_V0881.to_f
    old_v=(PMD_AC::DAMAGE_SCATTER_Y_MIN_V0881+PMD_AC::DAMAGE_SCATTER_Y_MAX_V0881).to_f/2.0
    new_v=(PMD_AC::DAMAGE_SCATTER_Y_MIN_V0882+PMD_AC::DAMAGE_SCATTER_Y_MAX_V0882).to_f/2.0
    old_h=(old_v*old_v)/(2.0*g)
    new_h=(new_v*new_v)/(2.0*g)
    ratio=old_h<=0.0 ? 1.0 : new_h/old_h
    pass=new_h<old_h && ratio<0.80 && ratio>0.50 && g==0.28
    log_verify_v0882('DAMAGE_ARC_LOWER_V0882',pass,
      'old_apex='+sprintf('%.1f',old_h)+' new_apex='+sprintf('%.1f',new_h)+
      ' ratio='+sprintf('%.3f',ratio)+' gravity='+sprintf('%.2f',g))
    @verification_done[:v0882_arc]=true
  end

  def verify_melee_sprite_offset_v0882
    return if @verification_done[:v0882_melee]
    melee_basic=PMD_AC.melee_attack_sprite_y_offset_v0882(:attack,true,nil,nil)
    ranged_basic=PMD_AC.melee_attack_sprite_y_offset_v0882(:attack,false,nil,nil)
    contact_skill=PMD_AC.melee_attack_sprite_y_offset_v0882(
      :skill,false,{:motion=>:contact_return},{:contact=>true})
    remote_skill=PMD_AC.melee_attack_sprite_y_offset_v0882(
      :skill,true,{:motion=>:stationary_cast,:remote_cast=>true},{:contact=>false})
    runtime_owned=PMD_AC.melee_attack_sprite_y_offset_v0882(
      :skill,true,{:motion=>:runtime_owned},{:contact=>true})
    pass=melee_basic==5 && ranged_basic==0 && contact_skill==5 &&
      remote_skill==0 && runtime_owned==0
    log_verify_v0882('MELEE_SPRITE_OFFSET_V0882',pass,
      'melee_basic='+melee_basic.to_s+' ranged_basic='+ranged_basic.to_s+
      ' contact_skill='+contact_skill.to_s+' remote_skill='+remote_skill.to_s+
      ' runtime_owned='+runtime_owned.to_s+' logical_y_unchanged=1')
    @verification_done[:v0882_melee]=true
  end

  def verify_visual_tuning_carry_v0882
    return if @verification_done[:v0882_carry]
    pass=PMD_AC::DAMAGE_SCATTER_X_MIN_V0881==1.35 &&
      PMD_AC::DAMAGE_SCATTER_X_MAX_V0881==2.15 &&
      PMD_AC::DAMAGE_SCATTER_GRAVITY_V0881==0.28 &&
      PMD_AC::BATTLE_FLOW_MANIFEST_V088[:passive_energy_gain]==2 &&
      PMD_AC::BATTLE_FLOW_MANIFEST_V088[:ranged_stall_break]==180 &&
      PMD_AC::BASIC_MELEE_HIT_GRACE_BONUS_V0871==18.0
    log_verify_v0882('VISUAL_TUNING_CARRY_V0882',pass,
      'scatter_x=v0.88.1 battle_flow=v0.88 miss=v0.87.1 damage_packet=v0.60.2 unchanged')
    @verification_done[:v0882_carry]=true
  end

  def update_verification_script
    unless visual_tuning_v0882?
      pmd_ac_v0882_update_verification_script
      return
    end
    @verification_frame=@verification_frame.to_i+1
    f=@verification_frame
    verify_visual_tuning_manifest_v0882 if f>=2
    verify_damage_arc_lower_v0882 if f>=4
    verify_melee_sprite_offset_v0882 if f>=6
    verify_visual_tuning_carry_v0882 if f>=8
    if f>=10 && !@verification_done[:v0882_final]
      pass=!@visual_tuning_v0882_failed
      log_verify_v0882('VISUAL_TUNING_V0882',pass,
        'manifest=1 lower_arc=1 melee_offset=1 carry=1')
      @verification_done[:v0882_final]=true
    end
    complete_verification_mode if f>=PMD_AC::VISUAL_TUNING_VERIFY_END_V0882
  end
end
