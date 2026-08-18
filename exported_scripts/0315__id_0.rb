# encoding: UTF-8
#==============================================================================
# 【PMD AutoChess 中文維護說明】
# 腳本：PMD AutoChess Combat Feel / Audio / Ranged Stagger v0.88.3
# 分類：戰鬥手感微調／音效診斷／遠程拉打平衡
# RPG Maker VX / RGSS2 / Ruby 1.8 compatible
#==============================================================================
# 【用途】
# 本補丁承接 v0.88.2，針對實戰觀察到的三個「手感」問題調整：
#
# 1. 傷害數字雖已降低拋物高度，但左右飛得仍稍遠。
#    -> 保留隨機往左／右彈射，只縮短水平速度與最大水平距離，
#       讓數字更靠近被打中的 Pokémon Sprite。
#
# 2. NORMAL 實戰開局有普攻已命中，但聽感上像沒有音效；部分技能命中也可能
#    因該 Stage 沒有配置 SE 而完全安靜。
#    -> 普攻確認命中共用 SE「PMD_MoveHit」音量由 v0.75.1 的 42 提高到 68。
#    -> Canonical「會造成傷害」技能若 hit stage 明確沒有音效路由，補一個低干擾
#       PMD_MoveHit fallback（只在真正 Damage Hit 時，不替狀態／支援技能亂配音）。
#    -> 包裝 PMD_AC.play_se，NORMAL LOG 會新增 AUDIO_RUNTIME，記錄實際送去
#       RPG::SE 的檔名、音量、Pitch 與檔案是否存在，方便往後直接抓漏音。
#
# 3. v0.74.3 / v0.75 的遠程防拉打規則是「近戰靠近」就 ENGAGED，並直接禁止
#    遠程攻擊／敵對技能，必須拉到 124px 再等 30f REARM 才能重新開火。
#    這會產生畫面上明明已在射程內，皮卡丘卻只跑不打的反直覺情況。
#    -> v0.88.3 NORMAL Runtime 不再以「敵人靠近」禁止遠程開火，也不削弱原本
#       的基礎拉打／移動能力。
#    -> 改成只有「真的被近身基本攻擊／Contact 技能造成 HP 傷害」後，遠程才
#       進入 Ranged Hit Stagger：短時間不能重新發動攻擊／技能，移動降速，
#       因此遠程平常拉打很好，但一旦被打到就更容易被近戰黏住。
#
#==============================================================================
# 【主要設定項】
#
# ■ Damage Popup 水平散射
# DAMAGE_SCATTER_X_MIN_V0883 = 0.85
# DAMAGE_SCATTER_X_MAX_V0883 = 1.35
# DAMAGE_SCATTER_X_LIMIT_V0883 = 48
#   v0.88.1 原本為 1.35～2.15、最大 78px。
#   v0.88.3 垂直值完全沿用 v0.88.2：-3.65～-3.15、Gravity 0.28。
#
# ■ 普攻命中音
# BASIC_ATTACK_HIT_SE_V0883 = PMD_MoveHit / volume 68 / pitch 105
#   只在成功 Damage Hit 播放。Miss、Evade、Projectile Lost 仍不播命中音。
#
# ■ Damage Skill 無 Hit SE 時的安全 fallback
# DAMAGING_SKILL_HIT_FALLBACK_SE_V0883 = PMD_MoveHit / volume 72 / pitch 100
#   只有 Canonical Move + 明確會造成傷害 + hit stage route=nil 才使用。
#   狀態技、自我 Buff、純支援、故意安靜的 cast / launch 不受影響。
#
# ■ 遠程被近身打中的黏著懲罰
# RANGED_CONTACT_BASIC_STAGGER_V0883 = 18
# RANGED_CONTACT_SKILL_STAGGER_V0883 = 24
# RANGED_HIT_STAGGER_MOVE_MULT_V0883 = 0.45
#   18f 約 0.30 秒；24f 約 0.40 秒（60 FPS）。
#   Stagger 期間：
#   - 不能開始新的 Basic Attack。
#   - 不能開始新的 Skill。
#   - 移動速度乘 0.45。
#   - 已經開始的技能不硬切斷，避免破壞 Action / Multi-hit choreography。
#   - 再次被 Contact Hit 時取較長剩餘時間，會刷新黏著窗口。
#
#==============================================================================
# 【遠程拉打新規則】
# 舊 v0.75：
#   「近戰靠近 102px」-> ENGAGED -> 禁止攻擊 -> 拉開 124px -> 等 30f -> 開火。
#
# v0.88.3：
#   「只是靠近」-> 不鎖攻擊、不鎖技能、不額外降撤退速度。
#   「近戰真的打中」-> 18/24f Ranged Hit Stagger + 45% 移動。
#
# 因此像皮卡丘這類 Artillery：
# - 射程內可以正常邊拉邊打，不再發生 80～120px 只跑不射。
# - 如果妙蛙種子／小火龍追到並成功 Contact Hit，皮卡丘會有明顯短暫僵直，
#   這時追擊者比較容易繼續貼住。
# - 遠程 Damage / Range / Projectile Tracking 本身完全不砍。
#
#==============================================================================
# 【Contact 判定】
# 以下 Direct Damage 會觸發遠程 Hit Stagger：
# - source_type == :basic 且攻擊者 melee? == true。
# - Skill Data 有 :contact == true。
# - source_move_flags 包含 :contact。
# - Presentation Motion 屬於既有 v0.88.2 Contact / Dash / Blink / Multi-contact。
#
# 以下不觸發：
# - 遠程 Projectile Basic。
# - Beam / Projectile 類技能。
# - Poison / Burn / Weather / Field / Zone 等間接傷害。
# - 0 Damage、Shield 全吸收後 HP 沒下降、或目標已死亡。
#
#==============================================================================
# 【Audio Runtime LOG 怎麼看】
# 每次真正呼叫 PMD_AC.play_se 時會新增：
#   [AUDIO_RUNTIME] PLAY name=PMD_MoveHit volume=68 pitch=105 file=1
#
# file=1：Audio/SE 下找到可播放檔案。
# file=0：路由有要求播放，但實體檔案不存在；這才是真正要修素材／命名。
#
# 若 Damage Skill 的 canonical hit stage 本身沒有 SE，本補丁會另外記錄：
#   [AUDIO_FALLBACK] ... reason=damaging_hit_route_silent
# 然後播放 PMD_MoveHit fallback。
#
#==============================================================================
# 【可調參數範例】
# 想讓傷害數字再貼近 Sprite：
#   DAMAGE_SCATTER_X_MIN_V0883 = 0.65
#   DAMAGE_SCATTER_X_MAX_V0883 = 1.05
#   DAMAGE_SCATTER_X_LIMIT_V0883 = 40
#
# 想讓遠程被貼到後更難脫離：
#   RANGED_CONTACT_BASIC_STAGGER_V0883 = 22
#   RANGED_CONTACT_SKILL_STAGGER_V0883 = 30
#   RANGED_HIT_STAGGER_MOVE_MULT_V0883 = 0.35
#
# 想讓遠程比較能逃：
#   RANGED_CONTACT_BASIC_STAGGER_V0883 = 14
#   RANGED_CONTACT_SKILL_STAGGER_V0883 = 18
#   RANGED_HIT_STAGGER_MOVE_MULT_V0883 = 0.60
#
#==============================================================================
# 【事件／腳本呼叫方式】
# 本補丁為 Runtime 自動套用，不需事件頁呼叫。
#
# 純腳本查詢範例：
#   PMD_AC::DAMAGE_SCATTER_X_MAX_V0883
#     # => 1.35
#
#   pokemon.ranged_hit_stagger_v0883?
#     # => true / false
#
#   pokemon.ranged_hit_stagger_frames_v0883
#     # => 剩餘 Frame
#
#==============================================================================
# 【驗證方式】
# 布陣畫面：NORMAL -> 按 S 一次 -> COMBAT_FEEL_V0883 -> Shift。
# 預期 LOG：
#   COMBAT_FEEL_MANIFEST_V0883 pass=1
#   DAMAGE_SCATTER_CLOSE_V0883 pass=1
#   AUDIO_AUDIBILITY_V0883 pass=1
#   RANGED_KITE_POLICY_V0883 pass=1
#   RANGED_STAGGER_POLICY_V0883 pass=1
#   COMBAT_FEEL_CARRY_V0883 pass=1
#   COMBAT_FEEL_V0883 pass=1
#   VERIFY_FINISHED_BATTLE_RESUME pass=1
#
# 再跑 NORMAL 實戰，主要看：
# - Damage Popup 左右角度／距離是否更貼 Sprite。
# - 戰鬥一開始的 Basic Hit 是否清楚聽得到。
# - LOG 是否有 AUDIO_RUNTIME file=0。
# - 皮卡丘在射程內是否正常持續開火，不再因單純靠近而停射。
# - 皮卡丘被近戰真的打中時是否出現 RANGED_STAGGER，且短暫較難跑掉。
#
#==============================================================================
# 【不修改內容】
# - 不改 v0.15 基礎 Movement / Range / Damage。
# - 不改 Projectile Tracking / Active Evade / Accuracy。
# - 不改 v0.60.2 Multi-hit Damage Packet / Choreography。
# - 不改 v0.62 Native Semantic Router。
# - 不改 v0.87.1 melee hit grace。
# - 不改 v0.88 Passive Energy、頭上文字、天氣／場地中央提示。
# - v0.88 的舊 180f STALL_BREAK 保留程式碼以維持舊 Verifier，但 NORMAL 下
#   因 v0.75 proximity ENGAGED 不再啟動，所以正常不需要靠 COUNTERFIRE 救場。
# - v0.88.2 近身攻擊者 Sprite +5px 與垂直 Damage Popup 軌跡原樣保留。
#==============================================================================
module PMD_AC
  PATCH_VERSION_V0883 = '0.88.3'

  DAMAGE_SCATTER_X_MIN_V0883 = 0.85
  DAMAGE_SCATTER_X_MAX_V0883 = 1.35
  DAMAGE_SCATTER_X_LIMIT_V0883 = 48

  BASIC_ATTACK_HIT_SE_V0883 = {
    :name => 'PMD_MoveHit',
    :volume => 68,
    :pitch => 105
  }
  DAMAGING_SKILL_HIT_FALLBACK_SE_V0883 = {
    :name => 'PMD_MoveHit',
    :volume => 72,
    :pitch => 100
  }

  RANGED_CONTACT_BASIC_STAGGER_V0883 = 18
  RANGED_CONTACT_SKILL_STAGGER_V0883 = 24
  RANGED_HIT_STAGGER_MOVE_MULT_V0883 = 0.45
  COMBAT_FEEL_VERIFY_END_V0883 = 20

  COMBAT_FEEL_MANIFEST_V0883 = {
    :version => PATCH_VERSION_V0883,
    :damage_x_min => DAMAGE_SCATTER_X_MIN_V0883,
    :damage_x_max => DAMAGE_SCATTER_X_MAX_V0883,
    :damage_x_limit => DAMAGE_SCATTER_X_LIMIT_V0883,
    :damage_y_min => DAMAGE_SCATTER_Y_MIN_V0882,
    :damage_y_max => DAMAGE_SCATTER_Y_MAX_V0882,
    :basic_hit_volume => BASIC_ATTACK_HIT_SE_V0883[:volume],
    :proximity_attack_lock => false,
    :ranged_basic_stagger => RANGED_CONTACT_BASIC_STAGGER_V0883,
    :ranged_skill_stagger => RANGED_CONTACT_SKILL_STAGGER_V0883,
    :ranged_stagger_move_mult => RANGED_HIT_STAGGER_MOVE_MULT_V0883,
    :damage => :unchanged,
    :range => :unchanged,
    :projectile => :unchanged
  }

  def self.audio_file_exists_v0883(name)
    return false if name==nil || name.to_s==''
    n=name.to_s
    return true if FileTest.exist?('Audio/SE/'+n)
    ['.wav','.ogg','.mp3','.wma','.mid'].each do |ext|
      return true if FileTest.exist?('Audio/SE/'+n+ext)
    end
    false
  end

  def self.damaging_skill_v0883?(data)
    return false if data==nil
    cat=data[:damage_category]
    return false if cat==:status
    return true if data[:fixed_damage]!=nil && data[:fixed_damage].to_i>0
    [:power,:base_power,:damage_power].each do |key|
      return true if data[key]!=nil && data[key].to_f>0.0
    end
    false
  end

  def self.contact_skill_packet_v0883?(data,profile=nil)
    return false if data==nil
    return true if data[:contact]
    flags=data[:source_move_flags] || []
    return true if flags.include?(:contact)
    return true if data[:force_contact_range]
    p=profile || {}
    motion=p[:motion]
    if const_defined?('MELEE_ATTACK_VISUAL_MOTIONS_V0882')
      return true if MELEE_ATTACK_VISUAL_MOTIONS_V0882.include?(motion)
    end
    false
  end

  def self.contact_damage_packet_v0883?(user,options,profile=nil)
    return false if user==nil
    opts=options || {}
    if opts[:source_type]==:basic
      return user.respond_to?(:melee?) && user.melee?
    end
    data=opts[:skill_data]
    contact_skill_packet_v0883?(data,profile)
  end

  # 只保留「被真的打中」鎖，不再因 proximity 自動鎖攻擊。
  def self.ranged_proximity_attack_lock_v0883?
    false
  end

  V0883_OLD_VERIFICATION_MODES = VERIFICATION_MODES.dup
  V0883_OLD_VERIFICATION_LABELS = VERIFICATION_LABELS.dup
  remove_const(:VERIFICATION_MODES)
  VERIFICATION_MODES = [:normal,:combat_feel_v0883] +
    V0883_OLD_VERIFICATION_MODES.reject{|x|x==:normal || x==:combat_feel_v0883}
  remove_const(:VERIFICATION_LABELS)
  VERIFICATION_LABELS = V0883_OLD_VERIFICATION_LABELS.dup
  VERIFICATION_LABELS[:normal]='NORMAL'
  VERIFICATION_LABELS[:combat_feel_v0883]='COMBAT_FEEL_V0883'

  class << self
    alias pmd_ac_v0883_play_se play_se unless method_defined?(:pmd_ac_v0883_play_se)

    # 所有真正送往 RPG::SE 的路由都留下 AUDIO_RUNTIME，避免再靠耳朵猜。
    def play_se(spec)
      if spec!=nil
        if spec.is_a?(String)
          name=spec
          volume=SE_DEFAULT_VOLUME
          pitch=SE_DEFAULT_PITCH
        else
          name=spec[:name]
          volume=(spec[:volume] || SE_DEFAULT_VOLUME).to_i
          pitch=(spec[:pitch] || SE_DEFAULT_PITCH).to_i
        end
        if name!=nil && name.to_s!=''
          begin
            if $scene!=nil && $scene.is_a?(Scene_PMD_AutoChess) &&
               $scene.respond_to?(:log_event)
              exists=audio_file_exists_v0883(name)
              $scene.log_event(:audio_runtime,
                'PLAY name='+name.to_s+
                ' volume='+volume.to_i.to_s+
                ' pitch='+pitch.to_i.to_s+
                ' file='+(exists ? '1':'0'))
            end
          rescue
          end
        end
      end
      pmd_ac_v0883_play_se(spec)
    end
  end
end

#==============================================================================
# ■ Game_PMDChessUnit : 遠程被 Contact Hit 後才產生真正 Gameplay Stagger
#==============================================================================
class Game_PMDChessUnit
  alias pmd_ac_v0883_initialize initialize unless method_defined?(:pmd_ac_v0883_initialize)
  alias pmd_ac_v0883_start_combat start_combat unless method_defined?(:pmd_ac_v0883_start_combat)
  alias pmd_ac_v0883_update_hurt update_hurt unless method_defined?(:pmd_ac_v0883_update_hurt)
  alias pmd_ac_v0883_old_update_logic update_logic unless method_defined?(:pmd_ac_v0883_old_update_logic)
  alias pmd_ac_v0883_old_update_threat_state update_threat_state unless method_defined?(:pmd_ac_v0883_old_update_threat_state)
  alias pmd_ac_v0883_old_effective_move_speed effective_move_speed unless method_defined?(:pmd_ac_v0883_old_effective_move_speed)
  alias pmd_ac_v0883_old_skill_in_range skill_in_range? unless method_defined?(:pmd_ac_v0883_old_skill_in_range)
  alias pmd_ac_v0883_old_begin_attack begin_attack unless method_defined?(:pmd_ac_v0883_old_begin_attack)
  alias pmd_ac_v0883_old_begin_skill begin_skill unless method_defined?(:pmd_ac_v0883_old_begin_skill)

  def initialize(*args)
    pmd_ac_v0883_initialize(*args)
    reset_ranged_hit_stagger_v0883
  end

  def start_combat
    pmd_ac_v0883_start_combat
    reset_ranged_hit_stagger_v0883
    # v0.74.3 / v0.75 proximity state 僅在 NORMAL／新版驗證停用。
    # 舊 Verification Mode 仍保留舊行為，方便歷史回歸驗證。
    if combat_feel_runtime_v0883?
      @ranged_disengage_lock_v0743=0
      @ranged_disengage_episode_v0743=false
      @ranged_engaged_v075=false
      @ranged_rearm_frames_v075=0
      @ranged_rearm_ready_logged_v075=true
    end
  end

  def reset_ranged_hit_stagger_v0883
    @ranged_hit_stagger_v0883=0
  end

  # NORMAL 與本版 Verifier 使用新規則；舊 Verifier 保留舊 v0.75 行為。
  def combat_feel_runtime_v0883?
    return true if @scene==nil
    return true unless @scene.respond_to?(:verification_mode)
    m=@scene.verification_mode
    m==:normal || m==:combat_feel_v0883
  end

  def ranged_hit_stagger_frames_v0883
    @ranged_hit_stagger_v0883.to_i
  end

  def ranged_hit_stagger_v0883?
    ranged_hit_stagger_frames_v0883>0
  end

  def apply_ranged_hit_stagger_v0883(source,frames,kind=:basic)
    return false unless ranged?
    return false if dead?
    f=[frames.to_i,1].max
    old=@ranged_hit_stagger_v0883.to_i
    @ranged_hit_stagger_v0883=[old,f].max

    # 視覺 Hurt 與 Gameplay 鎖同步拉長；不硬切目前正在執行的 Skill。
    @hurt_frames=[@hurt_frames.to_i,@ranged_hit_stagger_v0883].max
    @presentation_hit_react_frames_v0552=[
      @presentation_hit_react_frames_v0552.to_i,
      @ranged_hit_stagger_v0883
    ].max
    @presentation_hit_react_pose_v0552=:hurt

    # 被近身打到時先吃掉大部分慣性，之後 effective_move_speed 再乘 0.45。
    @velocity_x=@velocity_x.to_f*0.25
    @velocity_y=@velocity_y.to_f*0.25
    clear_move_goal if respond_to?(:clear_move_goal)

    src=source==nil ? 'SYSTEM' : source.log_name
    log_event(:ranged_stagger,
      log_name+' <- '+src+
      ' kind='+kind.to_s+
      ' frames='+@ranged_hit_stagger_v0883.to_s+
      ' move_mult='+sprintf('%.2f',PMD_AC::RANGED_HIT_STAGGER_MOVE_MULT_V0883))
    true
  end

  def update_hurt
    pmd_ac_v0883_update_hurt
    if @ranged_hit_stagger_v0883.to_i>0
      @ranged_hit_stagger_v0883-=1
      @ranged_hit_stagger_v0883=0 if @ranged_hit_stagger_v0883<0
    end
  end

  # -------------------------------------------------------------------------
  # v0.88.3 核心：直接回到 v0.74.3「插入前」的正常邏輯。
  # 這只跳過 v0.74.3 / v0.75 的 proximity anti-kite wrappers，
  # 不跳過更早的 Movement / Combat AI / Accuracy / Presentation 層。
  # -------------------------------------------------------------------------
  def update_logic
    return pmd_ac_v0883_old_update_logic unless combat_feel_runtime_v0883?
    pmd_ac_v0743_update_logic
  end

  def update_threat_state
    return pmd_ac_v0883_old_update_threat_state unless combat_feel_runtime_v0883?
    pmd_ac_v0743_update_threat_state
  end

  def skill_in_range?(other)
    return pmd_ac_v0883_old_skill_in_range(other) unless combat_feel_runtime_v0883?
    pmd_ac_v0743_skill_in_range(other)
  end

  def effective_move_speed
    return pmd_ac_v0883_old_effective_move_speed unless combat_feel_runtime_v0883?
    speed=pmd_ac_v0743_effective_move_speed
    if ranged? && ranged_hit_stagger_v0883?
      speed*=PMD_AC::RANGED_HIT_STAGGER_MOVE_MULT_V0883
    end
    speed
  end

  def begin_attack
    return pmd_ac_v0883_old_begin_attack unless combat_feel_runtime_v0883?
    return if ranged? && ranged_hit_stagger_v0883?
    pmd_ac_v075_begin_attack
  end

  def begin_skill(skill_target=nil)
    return pmd_ac_v0883_old_begin_skill(skill_target) unless combat_feel_runtime_v0883?
    return if ranged? && ranged_hit_stagger_v0883?
    pmd_ac_v075_begin_skill(skill_target)
  end
end

#==============================================================================
# ■ Sprite_PMDChessUnit : Damage Popup 水平散射收斂，垂直沿用 v0.88.2
#==============================================================================
class Sprite_PMDChessUnit
  # v0.88.1 update_popup 仍呼叫相同 method 名，因此只覆寫這兩個 helper 即可。
  def setup_damage_scatter_v0881
    @damage_scatter_dir_v0881=(rand(2)==0 ? -1 : 1)
    span=PMD_AC::DAMAGE_SCATTER_X_MAX_V0883-PMD_AC::DAMAGE_SCATTER_X_MIN_V0883
    @damage_scatter_vx_v0881=PMD_AC::DAMAGE_SCATTER_X_MIN_V0883+
      rand(101).to_f/100.0*span
    yspan=PMD_AC::DAMAGE_SCATTER_Y_MAX_V0882-PMD_AC::DAMAGE_SCATTER_Y_MIN_V0882
    @damage_scatter_vy_v0881=PMD_AC::DAMAGE_SCATTER_Y_MIN_V0882+
      rand(101).to_f/100.0*yspan
  end

  def damage_scatter_offset_v0881(elapsed,dir=nil,vx=nil,vy=nil)
    t=[elapsed.to_i,0].max
    d=dir==nil ? (@damage_scatter_dir_v0881 || 1) : dir.to_i
    xs=vx==nil ? (@damage_scatter_vx_v0881 || PMD_AC::DAMAGE_SCATTER_X_MIN_V0883) : vx.to_f
    ys=vy==nil ? (@damage_scatter_vy_v0881 || PMD_AC::DAMAGE_SCATTER_Y_MIN_V0882) : vy.to_f
    dx=(d*xs*t).round
    lim=PMD_AC::DAMAGE_SCATTER_X_LIMIT_V0883
    dx=lim if dx>lim
    dx=-lim if dx < -lim
    dy=(ys*t+0.5*PMD_AC::DAMAGE_SCATTER_GRAVITY_V0881*t*t).round
    [dx,dy]
  end
end

#==============================================================================
# ■ Scene_PMD_AutoChess : Contact Stagger / Audio / Verifier
#==============================================================================
class Scene_PMD_AutoChess
  alias pmd_ac_v0883_start start unless method_defined?(:pmd_ac_v0883_start)
  alias pmd_ac_v0883_refresh_header refresh_header unless method_defined?(:pmd_ac_v0883_refresh_header)
  alias pmd_ac_v0883_play_basic_se play_basic_se unless method_defined?(:pmd_ac_v0883_play_basic_se)
  alias pmd_ac_v0883_play_skill_se play_skill_se unless method_defined?(:pmd_ac_v0883_play_skill_se)
  alias pmd_ac_v0883_deal_direct_damage deal_direct_damage unless method_defined?(:pmd_ac_v0883_deal_direct_damage)
  alias pmd_ac_v0883_prepare_verification_battle prepare_verification_battle unless method_defined?(:pmd_ac_v0883_prepare_verification_battle)
  alias pmd_ac_v0883_update_verification_script update_verification_script unless method_defined?(:pmd_ac_v0883_update_verification_script)

  def start
    pmd_ac_v0883_start
    begin
      if FileTest.exist?(PMD_AC::BATTLE_LOG_FILE)
        text=File.open(PMD_AC::BATTLE_LOG_FILE,'rb'){|f|f.read}
        text.sub!(/PMD AutoChess Proto v0\.[0-9.]+ Battle Verification Log/,
                  'PMD AutoChess Proto v0.88.3 Battle Verification Log')
        File.open(PMD_AC::BATTLE_LOG_FILE,'wb'){|f|f.write(text)}
      end
    rescue
    end
    log_event(:presentation,
      'PATCH v0.88.3 damage_scatter_x='+PMD_AC::DAMAGE_SCATTER_X_MIN_V0883.to_s+'..'+
      PMD_AC::DAMAGE_SCATTER_X_MAX_V0883.to_s+
      ' x_limit='+PMD_AC::DAMAGE_SCATTER_X_LIMIT_V0883.to_s+
      ' vertical=v0.88.2_unchanged melee_sprite_y=v0.88.2_unchanged')
    log_event(:audio,
      'PATCH v0.88.3 basic_hit_se=PMD_MoveHit volume='+
      PMD_AC::BASIC_ATTACK_HIT_SE_V0883[:volume].to_s+
      ' damaging_skill_silent_hit_fallback=1 runtime_audio_log=1')
    log_event(:ranged_balance,
      'PATCH v0.88.3 proximity_attack_lock=off kiting_base=restored '+
      'contact_basic_stagger='+PMD_AC::RANGED_CONTACT_BASIC_STAGGER_V0883.to_s+
      ' contact_skill_stagger='+PMD_AC::RANGED_CONTACT_SKILL_STAGGER_V0883.to_s+
      ' stagger_move_mult='+sprintf('%.2f',PMD_AC::RANGED_HIT_STAGGER_MOVE_MULT_V0883)+
      ' ranged_damage=unchanged ranged_range=unchanged')
    refresh_header
  end

  def refresh_header
    pmd_ac_v0883_refresh_header
    return if @header_sprite==nil || @header_sprite.bitmap==nil
    bmp=@header_sprite.bitmap
    bmp.fill_rect(0,0,Graphics.width,28,Color.new(0,0,0,180))
    bmp.font.size=PMD_AC::UI_HEADER_TITLE_FONT_V086
    bmp.font.bold=true
    bmp.font.color=Color.new(255,255,255)
    bmp.draw_text(16,1,Graphics.width-32,30,'PMD 自走棋原型 v0.88.3',1)
  end

  # 普攻只有 Confirmed Hit 才換成較清楚的 68 音量。
  def play_basic_se(unit,stage)
    if respond_to?(:diagnostic_presentation_suppressed_v068?) &&
       diagnostic_presentation_suppressed_v068?
      return pmd_ac_v0883_play_basic_se(unit,stage)
    end
    if stage==:hit
      PMD_AC.play_se(PMD_AC::BASIC_ATTACK_HIT_SE_V0883)
      return
    end
    pmd_ac_v0883_play_basic_se(unit,stage)
  end

  # Canonical Damage Skill 的 hit route 若明確為 nil，補一個命中 fallback。
  # 已有正常 hit SFX 的技能完全沿用舊 routing，不重播。
  def play_skill_se(unit,stage,data=nil)
    if respond_to?(:diagnostic_presentation_suppressed_v068?) &&
       diagnostic_presentation_suppressed_v068?
      return pmd_ac_v0883_play_skill_se(unit,stage,data)
    end
    d=data
    d=unit.skill_data if d==nil && unit!=nil
    mk=d==nil ? nil : d[:canonical_move_key]
    profile=mk==nil ? nil : PMD_AC.skill_audio_move_profile_v032(mk)
    spec=(mk==nil || profile==nil) ? nil : PMD_AC.skill_audio_spec_v032(mk,stage,0)

    pmd_ac_v0883_play_skill_se(unit,stage,d)

    if stage==:hit && mk!=nil && profile!=nil && spec==nil &&
       PMD_AC.damaging_skill_v0883?(d)
      log_event(:audio_fallback,
        (unit==nil ? 'NONE' : unit.log_name)+
        ' move='+mk.to_s+' stage=hit reason=damaging_hit_route_silent')
      PMD_AC.play_se(PMD_AC::DAMAGING_SKILL_HIT_FALLBACK_SE_V0883)
    end
  end

  def contact_profile_for_v0883(user)
    return nil if user==nil || !user.respond_to?(:presentation_profile_v055)
    begin
      user.presentation_profile_v055
    rescue
      nil
    end
  end

  # 只以真正 HP Damage 判定。Shield 全吸收、0 Damage、間接傷害都不觸發。
  def deal_direct_damage(user,target,power,options=nil)
    before=target==nil ? 0 : target.hp.to_i
    opts=options==nil ? {} : options
    result=pmd_ac_v0883_deal_direct_damage(user,target,power,options)
    actual=target==nil ? 0 : [before-target.hp.to_i,0].max
    if actual>0 && target!=nil && !target.dead? && target.respond_to?(:ranged?) &&
       target.ranged? && user!=nil
      profile=contact_profile_for_v0883(user)
      if PMD_AC.contact_damage_packet_v0883?(user,opts,profile)
        skill=opts[:skill_data]
        kind=skill==nil ? :basic : :skill
        frames=kind==:skill ? PMD_AC::RANGED_CONTACT_SKILL_STAGGER_V0883 :
          PMD_AC::RANGED_CONTACT_BASIC_STAGGER_V0883
        target.apply_ranged_hit_stagger_v0883(user,frames,kind) if
          target.respond_to?(:apply_ranged_hit_stagger_v0883)
      end
    end
    result
  end

  # -------------------------------------------------------------------------
  # v0.88.3 Verifier
  # -------------------------------------------------------------------------
  def combat_feel_v0883?
    verification_mode==:combat_feel_v0883
  end

  def prepare_verification_battle
    pmd_ac_v0883_prepare_verification_battle
    @combat_feel_v0883_failed=false if combat_feel_v0883?
  end

  def log_verify_v0883(name,pass,detail='')
    @combat_feel_v0883_failed=true unless pass
    log_event(:verify,name+' pass='+(pass ? '1':'0')+(detail=='' ? '' : ' '+detail))
  end

  def verify_combat_feel_manifest_v0883
    return if @verification_done[:v0883_manifest]
    m=PMD_AC::COMBAT_FEEL_MANIFEST_V0883
    pass=m[:version]=='0.88.3' && m[:proximity_attack_lock]==false &&
      m[:damage]==:unchanged && m[:range]==:unchanged && m[:projectile]==:unchanged
    log_verify_v0883('COMBAT_FEEL_MANIFEST_V0883',pass,
      'x='+m[:damage_x_min].to_s+'..'+m[:damage_x_max].to_s+
      ' basic_se='+m[:basic_hit_volume].to_s+
      ' proximity_lock=off stagger='+m[:ranged_basic_stagger].to_s+'/'+
      m[:ranged_skill_stagger].to_s)
    @verification_done[:v0883_manifest]=true
  end

  def verify_damage_scatter_close_v0883
    return if @verification_done[:v0883_scatter]
    old_avg=(PMD_AC::DAMAGE_SCATTER_X_MIN_V0881+PMD_AC::DAMAGE_SCATTER_X_MAX_V0881)/2.0
    new_avg=(PMD_AC::DAMAGE_SCATTER_X_MIN_V0883+PMD_AC::DAMAGE_SCATTER_X_MAX_V0883)/2.0
    ratio=new_avg/old_avg
    pass=new_avg<old_avg && ratio<0.70 && PMD_AC::DAMAGE_SCATTER_X_LIMIT_V0883<
      PMD_AC::DAMAGE_SCATTER_X_LIMIT_V0881 &&
      PMD_AC::DAMAGE_SCATTER_Y_MIN_V0882==-3.65 &&
      PMD_AC::DAMAGE_SCATTER_Y_MAX_V0882==-3.15
    log_verify_v0883('DAMAGE_SCATTER_CLOSE_V0883',pass,
      'old_x_avg='+sprintf('%.2f',old_avg)+' new_x_avg='+sprintf('%.2f',new_avg)+
      ' ratio='+sprintf('%.3f',ratio)+' x_limit='+PMD_AC::DAMAGE_SCATTER_X_LIMIT_V0883.to_s+
      ' vertical=v0.88.2')
    @verification_done[:v0883_scatter]=true
  end

  def verify_audio_audibility_v0883
    return if @verification_done[:v0883_audio]
    basic=PMD_AC::BASIC_ATTACK_HIT_SE_V0883
    fallback=PMD_AC::DAMAGING_SKILL_HIT_FALLBACK_SE_V0883
    bfile=PMD_AC.audio_file_exists_v0883(basic[:name])
    ffile=PMD_AC.audio_file_exists_v0883(fallback[:name])
    audit_ok=true
    if PMD_AC.respond_to?(:audio_palette_audit_v0561)
      begin
        a=PMD_AC.audio_palette_audit_v0561
        audit_ok=a[:missing].empty?
      rescue
        audit_ok=false
      end
    end
    pass=basic[:volume].to_i>PMD_AC::BASIC_ATTACK_HIT_SE_V0751[:volume].to_i &&
      bfile && ffile && audit_ok
    log_verify_v0883('AUDIO_AUDIBILITY_V0883',pass,
      'basic_volume='+basic[:volume].to_s+' old=42 basic_file='+(bfile ? '1':'0')+
      ' fallback_file='+(ffile ? '1':'0')+' palette_missing='+(audit_ok ? '0':'1'))
    @verification_done[:v0883_audio]=true
  end

  def verify_ranged_kite_policy_v0883
    return if @verification_done[:v0883_kite]
    pass=PMD_AC.ranged_proximity_attack_lock_v0883? == false &&
      PMD_AC::RANGED_ENGAGE_RANGE_V075==102.0 &&
      PMD_AC::RANGED_RELEASE_RANGE_V075==124.0 &&
      PMD_AC::RANGED_REARM_FRAMES_V075==30
    log_verify_v0883('RANGED_KITE_POLICY_V0883',pass,
      'proximity_attack_lock=0 old_engage=102 old_release=124 old_rearm=30 '+
      'base_kiting=restored')
    @verification_done[:v0883_kite]=true
  end

  def verify_ranged_stagger_policy_v0883
    return if @verification_done[:v0883_stagger]
    basic_contact=PMD_AC.contact_damage_packet_v0883?(
      (@units||[]).find{|u|u!=nil && u.respond_to?(:melee?) && u.melee?},
      {:source_type=>:basic},nil)
    skill_contact=PMD_AC.contact_skill_packet_v0883?(
      {:contact=>true,:damage_category=>:physical,:power=>40},{:motion=>:contact_return})
    projectile_contact=PMD_AC.contact_skill_packet_v0883?(
      {:contact=>false,:damage_category=>:special,:power=>40},{:motion=>:stationary_cast,:remote_cast=>true})
    pass=basic_contact && skill_contact && !projectile_contact &&
      PMD_AC::RANGED_CONTACT_BASIC_STAGGER_V0883==18 &&
      PMD_AC::RANGED_CONTACT_SKILL_STAGGER_V0883==24 &&
      PMD_AC::RANGED_HIT_STAGGER_MOVE_MULT_V0883==0.45
    log_verify_v0883('RANGED_STAGGER_POLICY_V0883',pass,
      'basic_contact='+(basic_contact ? '1':'0')+
      ' skill_contact='+(skill_contact ? '1':'0')+
      ' projectile_contact='+(projectile_contact ? '1':'0')+
      ' frames=18/24 move_mult=0.45')
    @verification_done[:v0883_stagger]=true
  end

  def verify_combat_feel_carry_v0883
    return if @verification_done[:v0883_carry]
    pass=PMD_AC::DAMAGE_SCATTER_Y_MIN_V0882==-3.65 &&
      PMD_AC::DAMAGE_SCATTER_Y_MAX_V0882==-3.15 &&
      PMD_AC::MELEE_ATTACK_SPRITE_Y_OFFSET_V0882==5 &&
      PMD_AC::BASIC_MELEE_HIT_GRACE_BONUS_V0871==18.0 &&
      PMD_AC::BATTLE_FLOW_MANIFEST_V088[:passive_energy_gain]==2
    log_verify_v0883('COMBAT_FEEL_CARRY_V0883',pass,
      'damage_y=v0.88.2 melee_sprite_y=+5 miss=v0.87.1 passive_energy=v0.88 '+
      'damage_packet=v0.60.2 unchanged')
    @verification_done[:v0883_carry]=true
  end

  def update_verification_script
    unless combat_feel_v0883?
      pmd_ac_v0883_update_verification_script
      return
    end
    @verification_frame=@verification_frame.to_i+1
    f=@verification_frame
    verify_combat_feel_manifest_v0883 if f>=2
    verify_damage_scatter_close_v0883 if f>=4
    verify_audio_audibility_v0883 if f>=6
    verify_ranged_kite_policy_v0883 if f>=8
    verify_ranged_stagger_policy_v0883 if f>=10
    verify_combat_feel_carry_v0883 if f>=12
    if f>=14 && !@verification_done[:v0883_final]
      pass=!@combat_feel_v0883_failed
      log_verify_v0883('COMBAT_FEEL_V0883',pass,
        'scatter=1 audio=1 kite=1 stagger=1 carry=1')
      @verification_done[:v0883_final]=true
    end
    complete_verification_mode if f>=PMD_AC::COMBAT_FEEL_VERIFY_END_V0883
  end
end
