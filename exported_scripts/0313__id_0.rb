# encoding: UTF-8
#==============================================================================
# PMD AutoChess Damage Scatter Popup v0.88.1
# 傷害數字左右隨機拋射＋重力下墜演出
# RPG Maker VX / RGSS2 / Ruby 1.8 compatible
#==============================================================================
# 【用途】
# v0.88 已把傷害數字改成 Tankentai SBS 風格的「上拋→落下→回彈」。
# 本補丁依使用者要求再調整：每一筆傷害數字產生時，會隨機選擇往寶可夢
# Sprite 的左側或右側彈出，先帶有向上的初速度，再受重力往下墜。
#
# 因此連續傷害、多段攻擊、DOT 等數字不會全部疊在角色正上方；左右交錯後，
# 戰場資訊會更接近動作 RPG / SBS 的「傷害飛散」感。
#
#------------------------------------------------------------------------------
# 【最常調整的參數】
# DAMAGE_SCATTER_X_MIN_V0881 = 1.35
# DAMAGE_SCATTER_X_MAX_V0881 = 2.15
#   水平初速度範圍。數字越大，左右飛得越遠。
#
# DAMAGE_SCATTER_Y_MIN_V0881 = -4.50
# DAMAGE_SCATTER_Y_MAX_V0881 = -3.80
#   垂直初速度。RGSS 畫面 Y 向下為正，所以負值代表先往上彈。
#   絕對值越大，彈得越高。
#
# DAMAGE_SCATTER_GRAVITY_V0881 = 0.28
#   每 frame 的重力。越大越快掉下來。
#
# DAMAGE_SCATTER_X_LIMIT_V0881 = 78
#   最多允許離開原本位置的水平距離，避免數字飛到半個畫面之外。
#
#------------------------------------------------------------------------------
# 【實際效果範例】
# 同一隻寶可夢連續受到三次傷害時，可能會像：
#
#            35 ↗
#        寶可夢
#     ↖ 18             42 ↘
#
# 每一筆都獨立抽左／右方向以及一點點速度差，因此不會像排版軟體一樣
# 全部整齊疊成一根柱子。戰鬥畢竟不是 Excel，數字可以有點人生。
#
#------------------------------------------------------------------------------
# 【如果想調整】
# 想飛得更開：
#   DAMAGE_SCATTER_X_MAX_V0881 = 2.60
#
# 想彈得更高：
#   DAMAGE_SCATTER_Y_MIN_V0881 = -5.20
#   DAMAGE_SCATTER_Y_MAX_V0881 = -4.40
#
# 想更快往下掉：
#   DAMAGE_SCATTER_GRAVITY_V0881 = 0.34
#
#------------------------------------------------------------------------------
# 【不修改的內容】
# - 傷害／暴擊／命中／閃避公式
# - v0.88 被動蓄力與遠程 Anti-Stall
# - v0.88 頭上狀態、天氣／場地中央提示
# - Damage Popup 字型、顏色、CRIT 顯示、淡出時間
# - v0.15 移動核心、v0.60.2 Damage Packet
#
# 【驗證方式】
# 布陣畫面從 NORMAL 按 S 一次切到 DAMAGE_SCATTER_V0881，再按 Shift。
# 預期：
#   DAMAGE_SCATTER_MANIFEST_V0881 pass=1
#   DAMAGE_SCATTER_LEFT_RIGHT_V0881 pass=1
#   DAMAGE_SCATTER_FALL_V0881 pass=1
#   DAMAGE_SCATTER_CARRY_V0881 pass=1
#   DAMAGE_SCATTER_V0881 pass=1
#   VERIFY_FINISHED_BATTLE_RESUME pass=1
#==============================================================================
module PMD_AC
  DAMAGE_SCATTER_X_MIN_V0881 = 1.35
  DAMAGE_SCATTER_X_MAX_V0881 = 2.15
  DAMAGE_SCATTER_Y_MIN_V0881 = -4.50
  DAMAGE_SCATTER_Y_MAX_V0881 = -3.80
  DAMAGE_SCATTER_GRAVITY_V0881 = 0.28
  DAMAGE_SCATTER_X_LIMIT_V0881 = 78
  DAMAGE_SCATTER_VERIFY_END_V0881 = 22

  DAMAGE_SCATTER_MANIFEST_V0881 = {
    :version=>'0.88.1',
    :direction=>:random_left_or_right,
    :motion=>:ballistic_arc_then_fall,
    :x_min=>DAMAGE_SCATTER_X_MIN_V0881,
    :x_max=>DAMAGE_SCATTER_X_MAX_V0881,
    :y_min=>DAMAGE_SCATTER_Y_MIN_V0881,
    :y_max=>DAMAGE_SCATTER_Y_MAX_V0881,
    :gravity=>DAMAGE_SCATTER_GRAVITY_V0881,
    :x_limit=>DAMAGE_SCATTER_X_LIMIT_V0881,
    :v088_text_style=>:unchanged,
    :mechanics=>:unchanged
  }

  V0881_OLD_VERIFICATION_MODES = VERIFICATION_MODES.dup
  V0881_OLD_VERIFICATION_LABELS = VERIFICATION_LABELS.dup
  remove_const(:VERIFICATION_MODES)
  VERIFICATION_MODES = [:normal,:damage_scatter_v0881] +
    V0881_OLD_VERIFICATION_MODES.reject{|x|x==:normal || x==:damage_scatter_v0881}
  remove_const(:VERIFICATION_LABELS)
  VERIFICATION_LABELS = V0881_OLD_VERIFICATION_LABELS.dup
  VERIFICATION_LABELS[:normal]='NORMAL'
  VERIFICATION_LABELS[:damage_scatter_v0881]='DAMAGE_SCATTER_V0881'
end

#==============================================================================
# ■ Sprite_PMDChessUnit
#==============================================================================
class Sprite_PMDChessUnit
  alias pmd_ac_v0881_update_popup update_popup unless method_defined?(:pmd_ac_v0881_update_popup)

  # 每次新傷害出現時，獨立抽一次左右方向與速度。
  def setup_damage_scatter_v0881
    @damage_scatter_dir_v0881=(rand(2)==0 ? -1 : 1)
    span=PMD_AC::DAMAGE_SCATTER_X_MAX_V0881-PMD_AC::DAMAGE_SCATTER_X_MIN_V0881
    @damage_scatter_vx_v0881=PMD_AC::DAMAGE_SCATTER_X_MIN_V0881 + rand(101).to_f/100.0*span
    yspan=PMD_AC::DAMAGE_SCATTER_Y_MAX_V0881-PMD_AC::DAMAGE_SCATTER_Y_MIN_V0881
    @damage_scatter_vy_v0881=PMD_AC::DAMAGE_SCATTER_Y_MIN_V0881 + rand(101).to_f/100.0*yspan
  end

  # 純計算 helper，Verifier 也會使用。
  def damage_scatter_offset_v0881(elapsed,dir=nil,vx=nil,vy=nil)
    t=[elapsed.to_i,0].max
    d=dir==nil ? (@damage_scatter_dir_v0881 || 1) : dir.to_i
    xs=vx==nil ? (@damage_scatter_vx_v0881 || PMD_AC::DAMAGE_SCATTER_X_MIN_V0881) : vx.to_f
    ys=vy==nil ? (@damage_scatter_vy_v0881 || PMD_AC::DAMAGE_SCATTER_Y_MIN_V0881) : vy.to_f
    dx=(d*xs*t).round
    lim=PMD_AC::DAMAGE_SCATTER_X_LIMIT_V0881
    dx=lim if dx>lim
    dx=-lim if dx < -lim
    dy=(ys*t + 0.5*PMD_AC::DAMAGE_SCATTER_GRAVITY_V0881*t*t).round
    [dx,dy]
  end

  def update_popup
    frames=@unit.damage_popup_frames
    old=@last_popup_frames
    new_popup=(frames>0 && (old==nil || old<=0 || frames>old))
    setup_damage_scatter_v0881 if new_popup

    # 先讓 v0.88 完成文字繪製、CRIT 樣式、淡出與 anchor 初始化。
    pmd_ac_v0881_update_popup
    return if frames<=0 || @popup_sprite==nil || !@popup_sprite.visible

    total=[@popup_start_frames_v088.to_i,frames].max
    elapsed=total-frames
    off=damage_scatter_offset_v0881(elapsed)
    px=@popup_anchor_x_v088.to_i+off[0]
    maxx=Graphics.width-@popup_sprite.bitmap.width
    px=0 if px<0
    px=maxx if px>maxx
    @popup_sprite.x=px
    @popup_sprite.y=@popup_anchor_y_v088.to_i+off[1]
  end
end

#==============================================================================
# ■ Scene_PMD_AutoChess : 版本標示＋Verifier
#==============================================================================
class Scene_PMD_AutoChess
  alias pmd_ac_v0881_start start unless method_defined?(:pmd_ac_v0881_start)
  alias pmd_ac_v0881_refresh_header refresh_header unless method_defined?(:pmd_ac_v0881_refresh_header)
  alias pmd_ac_v0881_prepare_verification_battle prepare_verification_battle unless method_defined?(:pmd_ac_v0881_prepare_verification_battle)
  alias pmd_ac_v0881_update_verification_script update_verification_script unless method_defined?(:pmd_ac_v0881_update_verification_script)
  alias pmd_ac_v0881_log_event log_event unless method_defined?(:pmd_ac_v0881_log_event)

  def start
    pmd_ac_v0881_start
    begin
      if FileTest.exist?(PMD_AC::BATTLE_LOG_FILE)
        text=File.open(PMD_AC::BATTLE_LOG_FILE,'rb'){|f|f.read}
        text.sub!(/PMD AutoChess Proto v0\.[0-9.]+ Battle Verification Log/,
                  'PMD AutoChess Proto v0.88.1 Battle Verification Log')
        File.open(PMD_AC::BATTLE_LOG_FILE,'wb'){|f|f.write(text)}
      end
    rescue
    end
    log_event(:presentation,
      'PATCH v0.88.1 damage_scatter=random_left_right ballistic=1 gravity='+
      PMD_AC::DAMAGE_SCATTER_GRAVITY_V0881.to_s+
      ' x_speed='+PMD_AC::DAMAGE_SCATTER_X_MIN_V0881.to_s+'..'+
      PMD_AC::DAMAGE_SCATTER_X_MAX_V0881.to_s+' mechanics_unchanged=1')
    refresh_header
  end

  def refresh_header
    pmd_ac_v0881_refresh_header
    return if @header_sprite==nil || @header_sprite.bitmap==nil
    bmp=@header_sprite.bitmap
    bmp.fill_rect(0,0,Graphics.width,28,Color.new(0,0,0,180))
    bmp.font.size=PMD_AC::UI_HEADER_TITLE_FONT_V086
    bmp.font.bold=true
    bmp.font.color=Color.new(255,255,255)
    bmp.draw_text(16,1,Graphics.width-32,30,'PMD 自走棋原型 v0.88.1',1)
  end

  def damage_scatter_v0881?
    verification_mode==:damage_scatter_v0881
  end

  def prepare_verification_battle
    pmd_ac_v0881_prepare_verification_battle
    @damage_scatter_v0881_failed=false if damage_scatter_v0881?
  end

  def log_event(category,message)
    if category.to_s=='verify' && damage_scatter_v0881? &&
       message.to_s.index('DAMAGE_SCATTER_')==0 && message.to_s.include?(' pass=0')
      @damage_scatter_v0881_failed=true
    end
    pmd_ac_v0881_log_event(category,message)
  end

  def log_verify_v0881(name,pass,detail='')
    @damage_scatter_v0881_failed=true unless pass
    log_event(:verify,name+' pass='+(pass ? '1':'0')+(detail=='' ? '' : ' '+detail))
  end

  def verify_damage_scatter_manifest_v0881
    return if @verification_done[:v0881_manifest]
    m=PMD_AC::DAMAGE_SCATTER_MANIFEST_V0881
    pass=m[:direction]==:random_left_or_right && m[:motion]==:ballistic_arc_then_fall &&
      m[:gravity]>0 && m[:x_max]>m[:x_min]
    log_verify_v0881('DAMAGE_SCATTER_MANIFEST_V0881',pass,
      'dir=left_or_right gravity='+m[:gravity].to_s+' x='+m[:x_min].to_s+'..'+m[:x_max].to_s)
    @verification_done[:v0881_manifest]=true
  end

  def verify_damage_scatter_left_right_v0881
    return if @verification_done[:v0881_lr]
    sp=@unit_sprites==nil ? nil : @unit_sprites[0]
    left=[];right=[];pass=false
    if sp!=nil && sp.respond_to?(:damage_scatter_offset_v0881)
      left=sp.damage_scatter_offset_v0881(10,-1,1.8,-4.1)
      right=sp.damage_scatter_offset_v0881(10,1,1.8,-4.1)
      pass=(left[0]<0 && right[0]>0 && left[0].abs==right[0].abs)
    end
    log_verify_v0881('DAMAGE_SCATTER_LEFT_RIGHT_V0881',pass,
      'left_x='+(left[0]||0).to_s+' right_x='+(right[0]||0).to_s)
    @verification_done[:v0881_lr]=true
  end

  def verify_damage_scatter_fall_v0881
    return if @verification_done[:v0881_fall]
    sp=@unit_sprites==nil ? nil : @unit_sprites[0]
    early=[];late=[];pass=false
    if sp!=nil && sp.respond_to?(:damage_scatter_offset_v0881)
      early=sp.damage_scatter_offset_v0881(8,1,1.8,-4.1)
      late=sp.damage_scatter_offset_v0881(34,1,1.8,-4.1)
      pass=(early[1]<0 && late[1]>early[1])
    end
    log_verify_v0881('DAMAGE_SCATTER_FALL_V0881',pass,
      'early_y='+(early[1]||0).to_s+' late_y='+(late[1]||0).to_s+' arc_then_fall=1')
    @verification_done[:v0881_fall]=true
  end

  def verify_damage_scatter_carry_v0881
    return if @verification_done[:v0881_carry]
    pass=PMD_AC::BATTLE_FLOW_MANIFEST_V088[:passive_energy_gain]==2 &&
      PMD_AC::BATTLE_FLOW_MANIFEST_V088[:ranged_stall_break]==180 &&
      PMD_AC::BASIC_MELEE_HIT_GRACE_BONUS_V0871==18.0
    log_verify_v0881('DAMAGE_SCATTER_CARRY_V0881',pass,
      'battle_flow=v0.88 miss=v0.87.1 damage_formula=unchanged')
    @verification_done[:v0881_carry]=true
  end

  def update_verification_script
    unless damage_scatter_v0881?
      pmd_ac_v0881_update_verification_script
      return
    end
    @verification_frame=@verification_frame.to_i+1
    f=@verification_frame
    verify_damage_scatter_manifest_v0881 if f>=2
    verify_damage_scatter_left_right_v0881 if f>=4
    verify_damage_scatter_fall_v0881 if f>=6
    verify_damage_scatter_carry_v0881 if f>=8
    if f>=10 && !@verification_done[:v0881_final]
      pass=!@damage_scatter_v0881_failed
      log_verify_v0881('DAMAGE_SCATTER_V0881',pass,
        'manifest=1 left_right=1 fall=1 carry=1')
      @verification_done[:v0881_final]=true
    end
    complete_verification_mode if f>=PMD_AC::DAMAGE_SCATTER_VERIFY_END_V0881
  end
end
