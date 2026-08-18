# encoding: UTF-8
#==============================================================================
# ■ PMD AutoChess - Focus Cast Cue I v1.05.5
#==============================================================================
# 【用途】
# 1. 延續 v1.05.3／v1.05.4 的原始 Combat Core 節奏，不修改 HP、Damage、
#    Attack Wait、Energy、AI、Spatial、技能 hitFrame 或真正效果順序。
# 2. 技能開始時加入「短硬停 → 遮罩聚焦施放者 → 通用集氣 → 技能宣告 →
#    戰鬥恢復、遮罩漸退 → 追蹤到真正 Impact／Effect」的視覺文法。
# 3. 使用 Forest Symphony 提供的 Overlay1 遮罩做正式焦點素材；原圖 1088x832，
#    正好是 VX 544x416 的 2 倍，因此不縮放，而以裁切方式把透明洞移到施放者位置。
# 4. 保留 v1.05.4 輕量 Target / Impact Cue。完整 Focus 被占用或冷卻中時，技能
#    仍照原規則施放，只降級為 v1.05.4 Cue，不排隊、不取消技能。
#
# 【主要設定】
# FOCUS_CAST_INTRO_FRAMES_V1055 = 16
#   硬 Freeze 的總長度。全場邏輯、單位動畫、Projectile、Effect、Zone 都暫停。
# FOCUS_CAST_FADE_IN_FRAMES_V1055 = 5
#   Overlay opacity 由 0 漸入到設定上限。
# FOCUS_CAST_TITLE_FRAME_V1055 = 8
#   通用集氣開始後，第幾 frame 顯示技能名稱。
# FOCUS_CAST_FADE_OUT_FRAMES_V1055 = 10
#   硬 Freeze 結束、原戰鬥恢復後，Overlay 邊打邊漸退的時間。
# FOCUS_CAST_MASK_OPACITY_V1055 = 232
#   遮罩最高 Sprite opacity。原圖本身仍保留 alpha 漸層與透明中心。
# FOCUS_CAST_GLOBAL_COOLDOWN_V1055 = 18
#   一次完整 Focus 結束後，短時間內的新技能只走 v1.05.4 輕量 Cue，避免停停走走。
# FOCUS_CAST_TRACK_TIMEOUT_V1055 = 150
#   Focus ownership 最長追蹤時間；晚到 Projectile／Effect 超過此值才安全釋放。
#
# 【Freeze 規則：重要】
# - v1.05.5 預設只在「技能宣告 Intro」做真正全場 Freeze。
# - Intro 完成後，原 Combat Core 立刻恢復；Overlay 於技能動作進行中漸退。
# - Focus ownership 仍追蹤到 Damage / Effect / Zone / 位移等語意落地，讓玩家
#   能把後續結果歸因到剛才的技能。
# - 不預設 Freeze 到 Projectile 命中，因為那會讓長飛行技能把其他五隻單位的
#   Gameplay clock 一起延後，實質改變技能／傷害相對時序。若未來 Boss／必殺技
#   要採這種規則，應以獨立「Cinematic Priority」規格明確加入，而非暗改核心。
#
# 【通用集氣與專屬 Override】
# - 預設使用 :orbit：8 顆 Type 色像素粒子向施放者收束。
# - SPECIES_OVERRIDES / SKILL_OVERRIDES / BOSS_OVERRIDE 都是維護入口。
# - 可調：:intro_frames、:fade_in_frames、:title_frame、:fade_out_frames、
#   :mask_opacity、:charge_style。
# - 範例（目前只示範格式，沒有正式覆寫任何寶可夢）：
#     FOCUS_CAST_SPECIES_OVERRIDES_V1055['pikachu'] = {
#       :charge_style=>:orbit, :intro_frames=>18
#     }
#     FOCUS_CAST_SKILL_OVERRIDES_V1055['某招式'] = {
#       :intro_frames=>20, :mask_opacity=>245
#     }
# - Boss 預設可由 FOCUS_CAST_BOSS_OVERRIDE_V1055 統一提高強度；目前只保留入口，
#   不改既有 Boss 數值或技能資料。
#
# 【機制規則】
# - Frozen Combat Core 不直接修改；本腳本是 Scripts.rvdata 尾端 alias/hook layer。
# - Game_PMDChessUnit#begin_skill：parent 完成後才建立 Focus，不改技能決策。
# - Scene#update_battle_step：只有 Intro active 時 return，形成全世界同步 Pause。
# - Intro 期間 unit/effect/projectile sprite updater 同步停止，視覺與邏輯一致凍結。
# - Focus Overlay、Charge、Title 使用獨立高 Z Sprite，不寫 unit logical x/y。
# - Intro 結束後 battle step 立即恢復；遮罩只剩 opacity fade，不再攔 Gameplay。
# - deal_direct_damage / apply_skill_effects / resolve_skill 只記錄 Focus 語意完成，
#   不更動回傳值、不二次施加效果。
# - PMD Motion verifier 不啟用本層。
#
# 【事件／腳本呼叫方式】
# 無需事件呼叫。NORMAL → Shift 後技能自動觸發。
# LOG：
#   BATTLE_FOCUS_CAST_V1055 START ...
#   BATTLE_FOCUS_CAST_BEGIN_V1055 ...
#   BATTLE_FOCUS_CAST_RELEASE_V1055 ...
#   BATTLE_FOCUS_CAST_EFFECT_V1055 ...
#   BATTLE_FOCUS_CAST_SUMMARY_V1055 ...
#
# 【實際範例】
# 1. 小火龍 Energy 滿並開始技能。
# 2. 全場約 16f 停住；Overlay 5f 漸入並把透明洞裁在小火龍身上。
# 3. Type 色粒子向小火龍收束，第 8f 出現技能名稱。
# 4. 第 16f 原戰鬥恢復，小火龍 Native skill action / Projectile 正常執行；
#    Overlay 同時 10f 漸退。
# 5. Projectile 真正命中時記錄 Effect ownership，v1.05.4 Impact Cue 接手結果提示。
#==============================================================================
$imported={} unless defined?($imported)
$imported['PMD_AutoChess_FocusCastCueI_v1055']=true

module PMD_AC
  FOCUS_CAST_INTRO_FRAMES_V1055 = 16
  FOCUS_CAST_FADE_IN_FRAMES_V1055 = 5
  FOCUS_CAST_TITLE_FRAME_V1055 = 8
  FOCUS_CAST_FADE_OUT_FRAMES_V1055 = 10
  FOCUS_CAST_MASK_OPACITY_V1055 = 232
  FOCUS_CAST_GLOBAL_COOLDOWN_V1055 = 18
  FOCUS_CAST_TRACK_TIMEOUT_V1055 = 150
  FOCUS_CAST_OVERLAY_NAME_V1055 = 'PMD_FocusOverlay_v1055'
  FOCUS_CAST_PARTICLE_COUNT_V1055 = 8

  FOCUS_CAST_SPECIES_OVERRIDES_V1055 = {}
  FOCUS_CAST_SKILL_OVERRIDES_V1055 = {}
  FOCUS_CAST_BOSS_OVERRIDE_V1055 = {
    :intro_frames=>18,
    :fade_in_frames=>5,
    :title_frame=>9,
    :fade_out_frames=>12,
    :mask_opacity=>242,
    :charge_style=>:orbit
  }
end

class Game_PMDChessUnit
  alias pmd_ac_v1055_focus_cast_begin_skill begin_skill unless method_defined?(:pmd_ac_v1055_focus_cast_begin_skill)

  def begin_skill(skill_target=nil)
    r=pmd_ac_v1055_focus_cast_begin_skill(skill_target)
    if @action==:skill && @scene!=nil && @scene.respond_to?(:focus_cast_begin_v1055)
      @scene.focus_cast_begin_v1055(self,@skill_target)
    end
    r
  end
end

class Scene_PMD_AutoChess
  alias pmd_ac_v1055_focus_cast_start start unless method_defined?(:pmd_ac_v1055_focus_cast_start)
  alias pmd_ac_v1055_focus_cast_terminate terminate unless method_defined?(:pmd_ac_v1055_focus_cast_terminate)
  alias pmd_ac_v1055_focus_cast_update update unless method_defined?(:pmd_ac_v1055_focus_cast_update)
  alias pmd_ac_v1055_focus_cast_start_battle start_battle unless method_defined?(:pmd_ac_v1055_focus_cast_start_battle)
  alias pmd_ac_v1055_focus_cast_update_battle_step update_battle_step unless method_defined?(:pmd_ac_v1055_focus_cast_update_battle_step)
  alias pmd_ac_v1055_focus_cast_update_unit_sprites update_unit_sprites unless method_defined?(:pmd_ac_v1055_focus_cast_update_unit_sprites)
  alias pmd_ac_v1055_focus_cast_update_effect_sprites update_effect_sprites unless method_defined?(:pmd_ac_v1055_focus_cast_update_effect_sprites)
  alias pmd_ac_v1055_focus_cast_update_projectile_sprites update_projectile_sprites unless method_defined?(:pmd_ac_v1055_focus_cast_update_projectile_sprites)
  alias pmd_ac_v1055_focus_cast_update_camera_shake update_camera_shake unless method_defined?(:pmd_ac_v1055_focus_cast_update_camera_shake)
  alias pmd_ac_v1055_focus_cast_deal_direct_damage deal_direct_damage unless method_defined?(:pmd_ac_v1055_focus_cast_deal_direct_damage)
  alias pmd_ac_v1055_focus_cast_apply_skill_effects apply_skill_effects unless method_defined?(:pmd_ac_v1055_focus_cast_apply_skill_effects)
  alias pmd_ac_v1055_focus_cast_resolve_skill resolve_skill unless method_defined?(:pmd_ac_v1055_focus_cast_resolve_skill)
  alias pmd_ac_v1055_focus_cast_check_battle_end check_battle_end unless method_defined?(:pmd_ac_v1055_focus_cast_check_battle_end)

  def focus_cast_normal_v1055?
    return false unless @phase==:battle
    if respond_to?(:motion_phase_b_verifier_active_v1036?)
      return false if motion_phase_b_verifier_active_v1036?
    end
    true
  rescue
    false
  end

  def focus_cast_profile_v1055(user)
    p={
      :intro_frames=>PMD_AC::FOCUS_CAST_INTRO_FRAMES_V1055,
      :fade_in_frames=>PMD_AC::FOCUS_CAST_FADE_IN_FRAMES_V1055,
      :title_frame=>PMD_AC::FOCUS_CAST_TITLE_FRAME_V1055,
      :fade_out_frames=>PMD_AC::FOCUS_CAST_FADE_OUT_FRAMES_V1055,
      :mask_opacity=>PMD_AC::FOCUS_CAST_MASK_OPACITY_V1055,
      :charge_style=>:orbit
    }
    if user!=nil && user.respond_to?(:boss) && user.boss
      PMD_AC::FOCUS_CAST_BOSS_OVERRIDE_V1055.each{|k,v|p[k]=v}
    end
    if user!=nil && user.respond_to?(:species)
      key=user.species.to_s
      o=PMD_AC::FOCUS_CAST_SPECIES_OVERRIDES_V1055[key]
      o.each{|k,v|p[k]=v} if o!=nil
    end
    if user!=nil && user.respond_to?(:skill_name)
      key=user.skill_name.to_s
      o=PMD_AC::FOCUS_CAST_SKILL_OVERRIDES_V1055[key]
      o.each{|k,v|p[k]=v} if o!=nil
    end
    p
  rescue
    {
      :intro_frames=>16,:fade_in_frames=>5,:title_frame=>8,
      :fade_out_frames=>10,:mask_opacity=>232,:charge_style=>:orbit
    }
  end

  def focus_cast_type_v1055(user)
    if respond_to?(:skill_focus_type_v1054)
      return skill_focus_type_v1054(user)
    end
    :normal
  rescue
    :normal
  end

  def focus_cast_color_v1055(type,alpha=255)
    if respond_to?(:skill_focus_color_v1054)
      return skill_focus_color_v1054(type,alpha)
    end
    Color.new(255,230,120,alpha)
  rescue
    Color.new(255,230,120,alpha)
  end

  def focus_cast_find_unit_sprite_v1055(unit)
    if respond_to?(:skill_focus_find_unit_sprite_v1054)
      return skill_focus_find_unit_sprite_v1054(unit)
    end
    (@unit_sprites || []).each do |sp|
      return sp if sp!=nil && sp.respond_to?(:unit) && sp.unit==unit
    end
    nil
  rescue
    nil
  end

  def focus_cast_anchor_v1055(user)
    sp=focus_cast_find_unit_sprite_v1055(user)
    return [Graphics.width/2,Graphics.height/2,100] if sp==nil || sp.disposed?
    [sp.x.to_i,sp.y.to_i,sp.z.to_i]
  rescue
    [Graphics.width/2,Graphics.height/2,100]
  end

  def focus_cast_make_sprite_v1055(w,h,z)
    sp=Sprite.new(@viewport)
    sp.bitmap=Bitmap.new(w,h)
    sp.ox=w/2
    sp.oy=h/2
    sp.z=z
    sp.visible=false
    sp.opacity=0
    sp
  rescue
    nil
  end

  def focus_cast_create_v1055
    @focus_cast_overlay_v1055=Sprite.new(@viewport)
    @focus_cast_overlay_v1055.bitmap=Bitmap.new(Graphics.width,Graphics.height)
    @focus_cast_overlay_v1055.x=0
    @focus_cast_overlay_v1055.y=0
    @focus_cast_overlay_v1055.z=20000
    @focus_cast_overlay_v1055.opacity=0
    @focus_cast_overlay_v1055.visible=false

    @focus_cast_title_v1055=focus_cast_make_sprite_v1055(220,32,20030)
    @focus_cast_particles_v1055=[]
    PMD_AC::FOCUS_CAST_PARTICLE_COUNT_V1055.times do
      @focus_cast_particles_v1055.push(focus_cast_make_sprite_v1055(8,8,20025))
    end
    focus_cast_reset_v1055
    true
  rescue
    false
  end

  def focus_cast_dispose_sprite_v1055(sp)
    return if sp==nil
    if sp.bitmap!=nil && !sp.bitmap.disposed?
      sp.bitmap.dispose
    end
    sp.dispose unless sp.disposed?
  rescue
  end

  def focus_cast_dispose_v1055
    focus_cast_dispose_sprite_v1055(@focus_cast_overlay_v1055)
    focus_cast_dispose_sprite_v1055(@focus_cast_title_v1055)
    (@focus_cast_particles_v1055 || []).each{|sp|focus_cast_dispose_sprite_v1055(sp)}
    @focus_cast_overlay_v1055=nil
    @focus_cast_title_v1055=nil
    @focus_cast_particles_v1055=[]
    true
  rescue
    false
  end

  def focus_cast_reset_v1055
    @focus_cast_owner_v1055=nil
    @focus_cast_target_v1055=nil
    @focus_cast_profile_v1055=nil
    @focus_cast_type_v1055=:normal
    @focus_cast_intro_active_v1055=false
    @focus_cast_intro_age_v1055=0
    @focus_cast_fade_age_v1055=-1
    @focus_cast_lock_active_v1055=false
    @focus_cast_effect_seen_v1055=false
    @focus_cast_start_frame_v1055=0
    @focus_cast_last_complete_frame_v1055=-9999
    @focus_cast_full_count_v1055=0
    @focus_cast_downgrade_count_v1055=0
    @focus_cast_effect_count_v1055=0
    @focus_cast_freeze_frames_v1055=0
    @focus_cast_timeout_count_v1055=0
    @focus_cast_overlay_builds_v1055=0
    @focus_cast_summary_logged_v1055=false
    if @focus_cast_overlay_v1055!=nil
      @focus_cast_overlay_v1055.visible=false
      @focus_cast_overlay_v1055.opacity=0
    end
    if @focus_cast_title_v1055!=nil
      @focus_cast_title_v1055.visible=false
      @focus_cast_title_v1055.opacity=0
    end
    (@focus_cast_particles_v1055 || []).each do |sp|
      next if sp==nil
      sp.visible=false
      sp.opacity=0
    end
    true
  rescue
    false
  end

  def focus_cast_overlay_source_v1055
    return @focus_cast_overlay_source_v1055 if @focus_cast_overlay_source_v1055!=nil
    @focus_cast_overlay_source_v1055=Cache.system(PMD_AC::FOCUS_CAST_OVERLAY_NAME_V1055)
    @focus_cast_overlay_source_v1055
  rescue
    nil
  end

  def focus_cast_build_overlay_v1055(user)
    return false if @focus_cast_overlay_v1055==nil || @focus_cast_overlay_v1055.bitmap==nil
    src=focus_cast_overlay_source_v1055
    return false if src==nil
    a=focus_cast_anchor_v1055(user)
    x=a[0].to_i;y=a[1].to_i
    x=0 if x<0;x=Graphics.width if x>Graphics.width
    y=0 if y<0;y=Graphics.height if y>Graphics.height
    sx=src.width/2-x
    sy=src.height/2-y
    max_x=[src.width-Graphics.width,0].max
    max_y=[src.height-Graphics.height,0].max
    sx=0 if sx<0;sx=max_x if sx>max_x
    sy=0 if sy<0;sy=max_y if sy>max_y
    b=@focus_cast_overlay_v1055.bitmap
    b.clear
    b.blt(0,0,src,Rect.new(sx,sy,Graphics.width,Graphics.height))
    @focus_cast_overlay_builds_v1055=@focus_cast_overlay_builds_v1055.to_i+1
    true
  rescue
    false
  end

  def focus_cast_draw_particle_v1055(sp,type)
    return if sp==nil || sp.bitmap==nil
    b=sp.bitmap;b.clear
    c=focus_cast_color_v1055(type,235)
    c2=focus_cast_color_v1055(type,110)
    b.fill_rect(1,1,6,6,c2)
    b.fill_rect(2,2,4,4,c)
    b.fill_rect(3,3,2,2,Color.new(255,255,255,245))
  rescue
  end

  def focus_cast_draw_title_v1055(user,type)
    sp=@focus_cast_title_v1055
    return false if sp==nil || sp.bitmap==nil
    b=sp.bitmap;b.clear
    name=(user!=nil && user.respond_to?(:skill_name)) ? user.skill_name.to_s : 'SKILL'
    bg=focus_cast_color_v1055(type,205)
    edge=Color.new(0,0,0,205)
    b.fill_rect(6,4,208,24,edge)
    b.fill_rect(8,6,204,20,bg)
    begin
      names=defined?(PMD_AC::UI_PANEL_FONT_V0741) ? PMD_AC::UI_PANEL_FONT_V0741 : ['Microsoft JhengHei','微軟正黑體','Arial']
      b.font.name=names
    rescue
    end
    b.font.size=20
    b.font.bold=true
    b.font.color=Color.new(255,255,255,255)
    b.draw_text(10,4,200,24,name,1)
    true
  rescue
    false
  end

  def focus_cast_show_title_v1055
    return if @focus_cast_title_v1055==nil || @focus_cast_owner_v1055==nil
    focus_cast_draw_title_v1055(@focus_cast_owner_v1055,@focus_cast_type_v1055)
    a=focus_cast_anchor_v1055(@focus_cast_owner_v1055)
    x=a[0].to_i
    y=a[1].to_i+48
    x=110 if x<110;x=Graphics.width-110 if x>Graphics.width-110
    y=28 if y<28;y=Graphics.height-34 if y>Graphics.height-34
    @focus_cast_title_v1055.x=x
    @focus_cast_title_v1055.y=y
    @focus_cast_title_v1055.opacity=255
    @focus_cast_title_v1055.visible=true
  rescue
  end

  def focus_cast_hide_v1054_cues_during_intro_v1055
    return unless @focus_cast_intro_active_v1055
    if respond_to?(:skill_focus_hide_slots_v1054)
      skill_focus_hide_slots_v1054(@skill_focus_source_sprites_v1054,0)
      skill_focus_hide_slots_v1054(@skill_focus_target_sprites_v1054,0)
      skill_focus_hide_slots_v1054(@skill_focus_impact_sprites_v1054,0)
    end
  rescue
  end

  def focus_cast_can_full_v1055(user)
    return false unless focus_cast_normal_v1055?
    return false if user==nil
    return false if @focus_cast_intro_active_v1055
    return false if @focus_cast_lock_active_v1055
    now=Graphics.frame_count
    return false if now-@focus_cast_last_complete_frame_v1055.to_i<PMD_AC::FOCUS_CAST_GLOBAL_COOLDOWN_V1055
    true
  rescue
    false
  end

  def focus_cast_begin_v1055(user,target)
    return false unless focus_cast_normal_v1055?
    return false if user==nil
    unless focus_cast_can_full_v1055(user)
      @focus_cast_downgrade_count_v1055=@focus_cast_downgrade_count_v1055.to_i+1
      return false
    end
    @focus_cast_owner_v1055=user
    @focus_cast_target_v1055=target
    @focus_cast_profile_v1055=focus_cast_profile_v1055(user)
    @focus_cast_type_v1055=focus_cast_type_v1055(user)
    @focus_cast_intro_active_v1055=true
    @focus_cast_intro_age_v1055=0
    @focus_cast_fade_age_v1055=-1
    @focus_cast_lock_active_v1055=true
    @focus_cast_effect_seen_v1055=false
    @focus_cast_start_frame_v1055=Graphics.frame_count
    @focus_cast_full_count_v1055=@focus_cast_full_count_v1055.to_i+1
    focus_cast_build_overlay_v1055(user)
    if @focus_cast_overlay_v1055!=nil
      @focus_cast_overlay_v1055.opacity=0
      @focus_cast_overlay_v1055.visible=true
    end
    (@focus_cast_particles_v1055 || []).each do |sp|
      focus_cast_draw_particle_v1055(sp,@focus_cast_type_v1055)
      sp.visible=true if sp!=nil
    end
    log_event(:battle,'BATTLE_FOCUS_CAST_BEGIN_V1055 user='+user.log_name.to_s+
      ' skill='+user.skill_name.to_s+' target='+(target==nil ? 'NONE' : target.log_name.to_s)+
      ' intro_frames='+@focus_cast_profile_v1055[:intro_frames].to_i.to_s+
      ' fade_in='+@focus_cast_profile_v1055[:fade_in_frames].to_i.to_s+
      ' fade_out='+@focus_cast_profile_v1055[:fade_out_frames].to_i.to_s+
      ' mask_opacity='+@focus_cast_profile_v1055[:mask_opacity].to_i.to_s+
      ' world_freeze=intro_only focus_lock_until_effect=1')
    true
  rescue
    false
  end

  def focus_cast_hard_freeze_v1055?
    focus_cast_normal_v1055? && @focus_cast_intro_active_v1055
  rescue
    false
  end

  def focus_cast_charge_none_v1055(age,intro)
    (@focus_cast_particles_v1055 || []).each{|sp|sp.visible=false if sp!=nil}
  rescue
  end

  def focus_cast_charge_pulse_v1055(age,intro)
    return if @focus_cast_owner_v1055==nil
    a=focus_cast_anchor_v1055(@focus_cast_owner_v1055)
    count=PMD_AC::FOCUS_CAST_PARTICLE_COUNT_V1055
    (@focus_cast_particles_v1055 || []).each_with_index do |sp,i|
      next if sp==nil
      ring=(i<4 ? 20.0 : 30.0)
      ang=(Math::PI*2.0*i.to_f/count.to_f)
      pulse=0.78+0.22*Math.sin(age.to_f*0.7)
      sp.x=(a[0]+Math.cos(ang)*ring*pulse).to_i
      sp.y=(a[1]-6+Math.sin(ang)*ring*0.50*pulse).to_i
      sp.z=20025
      sp.opacity=210
      sp.zoom_x=1.0
      sp.zoom_y=1.0
      sp.visible=true
    end
  rescue
  end

  def focus_cast_charge_orbit_v1055(age,intro)
    return if @focus_cast_owner_v1055==nil
    a=focus_cast_anchor_v1055(@focus_cast_owner_v1055)
    ratio=intro<=1 ? 1.0 : age.to_f/intro.to_f
    ratio=0.0 if ratio<0.0;ratio=1.0 if ratio>1.0
    radius=36.0-(25.0*ratio)
    count=PMD_AC::FOCUS_CAST_PARTICLE_COUNT_V1055
    (@focus_cast_particles_v1055 || []).each_with_index do |sp,i|
      next if sp==nil
      ang=(Math::PI*2.0*i.to_f/count.to_f)+(age.to_f*0.18)
      sp.x=(a[0]+Math.cos(ang)*radius).to_i
      sp.y=(a[1]-6+Math.sin(ang)*radius*0.55).to_i
      sp.z=20025
      pulse=150+(Math.sin(age.to_f*0.55+i)*70).to_i
      pulse=80 if pulse<80;pulse=255 if pulse>255
      sp.opacity=pulse
      sp.zoom_x=0.8+ratio*0.45
      sp.zoom_y=sp.zoom_x
      sp.visible=true
    end
  rescue
  end

  def focus_cast_release_intro_v1055
    return false unless @focus_cast_intro_active_v1055
    @focus_cast_intro_active_v1055=false
    @focus_cast_fade_age_v1055=0
    (@focus_cast_particles_v1055 || []).each{|sp|sp.visible=false if sp!=nil}
    if @focus_cast_title_v1055!=nil
      @focus_cast_title_v1055.visible=false
      @focus_cast_title_v1055.opacity=0
    end
    log_event(:battle,'BATTLE_FOCUS_CAST_RELEASE_V1055 user='+
      (@focus_cast_owner_v1055==nil ? 'NONE' : @focus_cast_owner_v1055.log_name.to_s)+
      ' skill='+(@focus_cast_owner_v1055==nil ? 'NONE' : @focus_cast_owner_v1055.skill_name.to_s)+
      ' gameplay_resume=1 mask_fade_during_action=1 logic_order_preserved=1')
    true
  rescue
    false
  end

  def focus_cast_mark_effect_v1055(user,target,kind)
    return false unless @focus_cast_lock_active_v1055
    return false if user==nil || user!=@focus_cast_owner_v1055
    unless @focus_cast_effect_seen_v1055
      @focus_cast_effect_seen_v1055=true
      @focus_cast_effect_count_v1055=@focus_cast_effect_count_v1055.to_i+1
      log_event(:battle,'BATTLE_FOCUS_CAST_EFFECT_V1055 user='+user.log_name.to_s+
        ' skill='+user.skill_name.to_s+' target='+(target==nil ? 'NONE' : target.log_name.to_s)+
        ' kind='+kind.to_s+' age='+(Graphics.frame_count-@focus_cast_start_frame_v1055.to_i).to_s)
    end
    true
  rescue
    false
  end

  def focus_cast_delivery_delayed_v1055(user)
    return false if user==nil || !user.respond_to?(:skill_data)
    d=user.skill_data || {}
    delivery=d[:delivery] || :instant
    return true if delivery==:projectile
    return true if delivery==:aoe && user.respond_to?(:ranged?) && user.ranged?
    false
  rescue
    false
  end

  def focus_cast_complete_lock_v1055(reason)
    return false unless @focus_cast_lock_active_v1055
    @focus_cast_lock_active_v1055=false
    @focus_cast_last_complete_frame_v1055=Graphics.frame_count
    log_event(:battle,'BATTLE_FOCUS_CAST_COMPLETE_V1055 reason='+reason.to_s+
      ' effect_seen='+(@focus_cast_effect_seen_v1055 ? '1' : '0')+
      ' age='+(Graphics.frame_count-@focus_cast_start_frame_v1055.to_i).to_s)
    @focus_cast_owner_v1055=nil
    @focus_cast_target_v1055=nil
    true
  rescue
    false
  end

  def focus_cast_update_lock_v1055
    return unless @focus_cast_lock_active_v1055
    u=@focus_cast_owner_v1055
    if u==nil || u.dead?
      focus_cast_complete_lock_v1055(:owner_gone)
      return
    end
    age=Graphics.frame_count-@focus_cast_start_frame_v1055.to_i
    if age>PMD_AC::FOCUS_CAST_TRACK_TIMEOUT_V1055
      @focus_cast_timeout_count_v1055=@focus_cast_timeout_count_v1055.to_i+1
      focus_cast_complete_lock_v1055(:timeout)
      return
    end
    delayed=focus_cast_delivery_delayed_v1055(u)
    if @focus_cast_effect_seen_v1055
      focus_cast_complete_lock_v1055(:effect) if !@focus_cast_intro_active_v1055 && u.action!=:skill
    elsif !delayed && !@focus_cast_intro_active_v1055 && u.action!=:skill
      focus_cast_complete_lock_v1055(:action_complete)
    end
  rescue
  end

  def focus_cast_update_v1055
    return unless focus_cast_normal_v1055?
    if @focus_cast_intro_active_v1055
      p=@focus_cast_profile_v1055 || focus_cast_profile_v1055(@focus_cast_owner_v1055)
      intro=[p[:intro_frames].to_i,1].max
      fade=[p[:fade_in_frames].to_i,1].max
      title_at=p[:title_frame].to_i
      age=@focus_cast_intro_age_v1055.to_i
      max_op=p[:mask_opacity].to_i
      op=(max_op*[age+1,fade].min/fade.to_f).to_i
      if @focus_cast_overlay_v1055!=nil
        @focus_cast_overlay_v1055.opacity=op
        @focus_cast_overlay_v1055.visible=true
      end
      style=(p[:charge_style] || :orbit).to_sym
      method_name=('focus_cast_charge_'+style.to_s+'_v1055').to_sym
      if respond_to?(method_name)
        send(method_name,age,intro)
      else
        focus_cast_charge_orbit_v1055(age,intro)
      end
      focus_cast_show_title_v1055 if age>=title_at
      focus_cast_hide_v1054_cues_during_intro_v1055
      @focus_cast_intro_age_v1055=age+1
      @focus_cast_freeze_frames_v1055=@focus_cast_freeze_frames_v1055.to_i+1
      focus_cast_release_intro_v1055 if @focus_cast_intro_age_v1055.to_i>=intro
    elsif @focus_cast_fade_age_v1055.to_i>=0
      p=@focus_cast_profile_v1055 || {:fade_out_frames=>10,:mask_opacity=>232}
      frames=[p[:fade_out_frames].to_i,1].max
      age=@focus_cast_fade_age_v1055.to_i
      remain=1.0-age.to_f/frames.to_f
      remain=0.0 if remain<0.0
      if @focus_cast_overlay_v1055!=nil
        @focus_cast_overlay_v1055.opacity=(p[:mask_opacity].to_i*remain).to_i
        @focus_cast_overlay_v1055.visible=remain>0.0
      end
      @focus_cast_fade_age_v1055=age+1
      if @focus_cast_fade_age_v1055.to_i>frames
        @focus_cast_fade_age_v1055=-1
        @focus_cast_overlay_v1055.visible=false if @focus_cast_overlay_v1055!=nil
      end
    end
    focus_cast_update_lock_v1055
  rescue
  end

  def start
    r=pmd_ac_v1055_focus_cast_start
    focus_cast_create_v1055
    focus_cast_overlay_source_v1055
    r
  end

  def terminate
    focus_cast_dispose_v1055
    pmd_ac_v1055_focus_cast_terminate
  end

  def update
    r=pmd_ac_v1055_focus_cast_update
    focus_cast_update_v1055 if $scene==self
    r
  end

  def start_battle
    r=pmd_ac_v1055_focus_cast_start_battle
    if focus_cast_normal_v1055?
      focus_cast_reset_v1055
      focus_cast_overlay_source_v1055
      log_event(:battle,'BATTLE_FOCUS_CAST_V1055 START intro_frames=16 fade_in=5 title_frame=8 fade_out=10'+
        ' mask_opacity=232 overlay=FS_Overlay1 crop_tracking=1 generic_charge=orbit'+
        ' hard_freeze_scope=intro_only focus_lock_until_effect=1 global_cooldown=18'+
        ' v1054_light_cue_retained=1 hp_unchanged=1 damage_unchanged=1 attack_wait_unchanged=1'+
        ' energy_unchanged=1 action_hitframe_unchanged=1 ai_unchanged=1 spatial_unchanged=1')
    end
    r
  end

  def update_battle_step
    return if focus_cast_hard_freeze_v1055?
    pmd_ac_v1055_focus_cast_update_battle_step
  end

  def update_unit_sprites
    return if focus_cast_hard_freeze_v1055?
    pmd_ac_v1055_focus_cast_update_unit_sprites
  end

  def update_effect_sprites
    return if focus_cast_hard_freeze_v1055?
    pmd_ac_v1055_focus_cast_update_effect_sprites
  end

  def update_projectile_sprites
    return if focus_cast_hard_freeze_v1055?
    pmd_ac_v1055_focus_cast_update_projectile_sprites
  end

  def update_camera_shake
    return if focus_cast_hard_freeze_v1055?
    pmd_ac_v1055_focus_cast_update_camera_shake
  end

  def deal_direct_damage(*args)
    user=(args[0] rescue nil)
    target=(args[1] rescue nil)
    r=pmd_ac_v1055_focus_cast_deal_direct_damage(*args)
    focus_cast_mark_effect_v1055(user,target,:damage)
    r
  end

  def apply_skill_effects(*args)
    user=(args[0] rescue nil)
    target=(args[1] rescue nil)
    r=pmd_ac_v1055_focus_cast_apply_skill_effects(*args)
    focus_cast_mark_effect_v1055(user,target,:effect)
    r
  end

  def resolve_skill(unit)
    data=(unit==nil ? nil : unit.skill_data)
    r=pmd_ac_v1055_focus_cast_resolve_skill(unit)
    if unit!=nil && unit==@focus_cast_owner_v1055 && data!=nil
      delivery=data[:delivery] || :instant
      if !focus_cast_delivery_delayed_v1055(unit) && !@focus_cast_effect_seen_v1055
        if data[:pre_move]!=nil || data[:zone]!=nil || delivery==:beam || delivery==:chain ||
           delivery==:bounce || delivery==:pierce || delivery==:sustained_beam || delivery==:sweeping_beam
          focus_cast_mark_effect_v1055(unit,unit.skill_target,:resolve_commit)
        end
      end
    end
    r
  end

  def focus_cast_log_summary_v1055
    return false if @focus_cast_summary_logged_v1055
    @focus_cast_summary_logged_v1055=true
    log_event(:battle,'BATTLE_FOCUS_CAST_SUMMARY_V1055 full_focus='+@focus_cast_full_count_v1055.to_i.to_s+
      ' downgraded='+@focus_cast_downgrade_count_v1055.to_i.to_s+
      ' effects_linked='+@focus_cast_effect_count_v1055.to_i.to_s+
      ' hard_freeze_frames='+@focus_cast_freeze_frames_v1055.to_i.to_s+
      ' overlay_builds='+@focus_cast_overlay_builds_v1055.to_i.to_s+
      ' timeouts='+@focus_cast_timeout_count_v1055.to_i.to_s+
      ' hard_freeze_scope=intro_only mask_fade_during_action=1 focus_lock_until_effect=1'+
      ' gameplay_order_after_intro=unchanged v1054_light_cue_retained=1')
    true
  rescue
    false
  end

  def check_battle_end
    before=@phase
    r=pmd_ac_v1055_focus_cast_check_battle_end
    if before==:battle && @phase!=:battle
      focus_cast_log_summary_v1055
      @focus_cast_intro_active_v1055=false
      @focus_cast_lock_active_v1055=false
      @focus_cast_overlay_v1055.visible=false if @focus_cast_overlay_v1055!=nil
      @focus_cast_title_v1055.visible=false if @focus_cast_title_v1055!=nil
      (@focus_cast_particles_v1055 || []).each{|sp|sp.visible=false if sp!=nil}
    end
    r
  end
end
