# encoding: UTF-8
#===============================================================================
# ■ PMD AutoChess - Status Minimal Focus + Important/Boss Content II v1.05.20
#===============================================================================
# 【用途】
# 1. 依 Windows 實機觀察，徹底移除純 Status 技能 Focus precharge 中仍像「小火球」的
#    generic orbit charge。v1.05.17 已封 elemental cast muzzle / burst / impact；本版再把
#    Focus 自己的 charge_style 收斂為 :none，完成純狀態技能的 Presentation Ownership。
# 2. 同步推進 Phase B1 內容擴張：Important / Boss 不再只有 precharge / mask 數字差異，
#    新增 target-local / owner-local 的「封環收束 + release echo」視覺語言。
# 3. 所有新增內容均為 Presentation-only，不改 Damage、HP、AI、Energy、Attack Wait、
#    Priority、hit timing、logical Spatial x/y/velocity/endpoints。
#
# 【Windows 實機依據】
# - v1.05.19 已確認 Growl 的 elemental cast muzzle 被 v1.05.17 suppress，但肉眼仍可能看到
#   一顆像火球的光點；LOG 顯示 Growl tier=standard charge=orbit，因此剩餘來源就是
#   Focus generic orbit，而不是技能本身 projectile。
# - v1.05.19 F6 fixture 已實機 PASS：Important=60/242/signature、Boss=72/248/boss。
# - v1.05.18 Status Completion 已實機 PASS：waits=3 commits=3 timeouts=0，Result Hold 在
#   effect commit 後才開始。本版不重開此 Authority。
#
# 【純 Status 規則】
# - canonical category=:status → Focus profile charge_style=:none。
# - 保留：暗場 overlay、技能名稱 banner、target shadow mark、技能音效、Result text、
#   v1.05.14 紅／藍多光圈、KO、v1.05.13 Result Hold 18f。
# - 不顯示：generic Focus orbit、elemental cast muzzle、generic projectile visual、
#   generic target impact / old VFX burst（後三項仍由 v1.05.16～17 Authority 封鎖）。
# - Damage+status 技能不是 pure status，仍保留正常攻擊 Presentation。
#
# 【Important Content II】
# - 沿用 60f / mask 242 / signature particle convergence。
# - precharge 後半加入一個 type-tinted「收束封環」，環會緩慢旋轉並縮向施放者。
# - release 時產生一段 12f outward echo ring，讓「蓄力完成 → 招式釋放」有清楚斷點。
#
# 【Boss Content II】
# - 沿用 72f / mask 248 / boss dual-direction particles。
# - precharge 使用兩個不同半徑、反向旋轉的封環，強度高於 Important，但不新增全螢幕字卡。
# - release 使用雙段 echo：第一環立即外擴，第二環延遲 3f 外擴，建立 Boss 層級重量感。
#
# 【效能與安全】
# - 只新增 2 個小型 Sprite（96x30 / 124x38），bitmap 在 Scene start 一次建立。
# - live battle 每 frame 只改座標 / zoom / opacity / angle，不逐 frame 重建 bitmap。
# - performance threshold 仍為 50ms，不放寬。
#
# 【設定／可調參數】
# FOCUS_CONTENT_IMPORTANT_RELEASE_FRAMES_V10520 = 12
# FOCUS_CONTENT_BOSS_RELEASE_FRAMES_V10520      = 16
# FOCUS_CONTENT_BOSS_SECOND_DELAY_V10520       = 3
#
# 【依賴／載入順序】
# - 置於 v1.05.19 之後、Main 之前。
# - 依賴 v1.05.15 Focus tier、v1.05.17 pure-status classifier、v1.05.18 completion Authority。
# - 使用 trailing alias/hook，不修改 Frozen Combat Core。
#
# 【事件／腳本呼叫方式】
# 無需事件呼叫，NORMAL battle 自動生效。
# F6 fixture 仍沿用 v1.05.19：會自然帶出本版 Important/Boss Content II。
#
# 【實際範例】
# - Growl：暗場 +「叫聲」+ target mark → -攻擊 + 藍色多光圈 → 18f Result Hold；
#   precharge 不再有 orbit 小光球。
# - Water Gun：damage move，仍維持 standard orbit + 原攻擊 VFX。
# - F6 Important 亞空裂斬：signature convergence + 單層封環 + release echo。
# - F6 Boss 撞擊：boss particles + 雙層反向封環 + 雙段 release echo。
#
# 【LOG】
# BATTLE_STATUS_MINIMAL_FOCUS_IMPORTANT_BOSS_CONTENT_V10520 START ...
# BATTLE_FOCUS_CONTENT_PROFILE_V10520 user=... skill=... tier=... status_minimal=... charge=...
# BATTLE_FOCUS_CONTENT_RELEASE_V10520 tier=important/boss frames=...
# BATTLE_STATUS_MINIMAL_FOCUS_IMPORTANT_BOSS_CONTENT_SUMMARY_V10520 ...
#===============================================================================
$imported={} unless defined?($imported)
$imported['PMD_AutoChess_StatusMinimalFocus_ImportantBossContentII_v10520']=true

module PMD_AC
  FOCUS_CONTENT_IMPORTANT_RELEASE_FRAMES_V10520 = 12
  FOCUS_CONTENT_BOSS_RELEASE_FRAMES_V10520 = 16
  FOCUS_CONTENT_BOSS_SECOND_DELAY_V10520 = 3
end

class Scene_PMD_AutoChess
  alias pmd_ac_v10520_focus_profile focus_cast_profile_v1055 unless method_defined?(:pmd_ac_v10520_focus_profile)
  alias pmd_ac_v10520_focus_begin focus_cast_begin_v1055 unless method_defined?(:pmd_ac_v10520_focus_begin)
  alias pmd_ac_v10520_focus_release focus_cast_release_intro_v1055 unless method_defined?(:pmd_ac_v10520_focus_release)
  alias pmd_ac_v10520_focus_update focus_cast_update_v1055 unless method_defined?(:pmd_ac_v10520_focus_update)
  alias pmd_ac_v10520_start start unless method_defined?(:pmd_ac_v10520_start)
  alias pmd_ac_v10520_terminate terminate unless method_defined?(:pmd_ac_v10520_terminate)
  alias pmd_ac_v10520_start_battle start_battle unless method_defined?(:pmd_ac_v10520_start_battle)
  alias pmd_ac_v10520_focus_summary focus_cast_log_summary_v1055 unless method_defined?(:pmd_ac_v10520_focus_summary)

  def focus_content_pure_status_v10520?(user)
    return false if user==nil
    key=user.instance_variable_get(:@skill_type)
    if respond_to?(:status_vfx_seal_pure_v10517?)
      return status_vfx_seal_pure_v10517?(key)
    end
    false
  rescue
    false
  end

  def focus_cast_profile_v1055(user)
    p=pmd_ac_v10520_focus_profile(user)
    p={} if p==nil
    if focus_content_pure_status_v10520?(user)
      p[:charge_style]=:none
      p[:status_minimal_v10520]=true
    end
    p
  rescue
    pmd_ac_v10520_focus_profile(user)
  end

  def focus_content_make_ring_sprite_v10520(w,h,z)
    sp=Sprite.new(@viewport)
    sp.bitmap=Bitmap.new(w,h)
    sp.ox=w/2
    sp.oy=h/2
    sp.z=z
    sp.visible=false
    sp.opacity=0
    sp.blend_type=1
    focus_content_draw_ring_v10520(sp.bitmap)
    sp
  rescue
    nil
  end

  def focus_content_draw_ring_v10520(bmp)
    return if bmp==nil || bmp.disposed?
    bmp.clear
    w=bmp.width.to_i
    h=bmp.height.to_i
    cx=(w-1).to_f/2.0
    cy=(h-1).to_f/2.0
    rx=[cx-2.0,1.0].max
    ry=[cy-2.0,1.0].max
    for yy in 0...h
      for xx in 0...w
        dx=(xx.to_f-cx)/rx
        dy=(yy.to_f-cy)/ry
        q=dx*dx+dy*dy
        next if q>1.0 || q<0.70
        a=(q>0.90 ? 235 : (q>0.80 ? 150 : 70))
        bmp.set_pixel(xx,yy,Color.new(255,255,255,a))
      end
    end
  rescue
  end

  def focus_content_create_v10520
    @focus_content_ring_a_v10520=focus_content_make_ring_sprite_v10520(96,30,20024)
    @focus_content_ring_b_v10520=focus_content_make_ring_sprite_v10520(124,38,20023)
    focus_content_hide_v10520
    true
  rescue
    false
  end

  def focus_content_dispose_one_v10520(sp)
    return if sp==nil
    begin
      b=sp.bitmap
      b.dispose if b!=nil && !b.disposed?
    rescue
    end
    begin
      sp.dispose unless sp.disposed?
    rescue
    end
  end

  def focus_content_dispose_v10520
    focus_content_dispose_one_v10520(@focus_content_ring_a_v10520)
    focus_content_dispose_one_v10520(@focus_content_ring_b_v10520)
    @focus_content_ring_a_v10520=nil
    @focus_content_ring_b_v10520=nil
    true
  rescue
    false
  end

  def focus_content_hide_one_v10520(sp)
    return if sp==nil || sp.disposed?
    sp.visible=false
    sp.opacity=0
    sp.angle=0
  rescue
  end

  def focus_content_hide_v10520
    focus_content_hide_one_v10520(@focus_content_ring_a_v10520)
    focus_content_hide_one_v10520(@focus_content_ring_b_v10520)
  end

  def focus_content_apply_type_color_v10520(sp,type,alpha=255)
    return if sp==nil || sp.disposed?
    c=focus_cast_color_v1055(type,alpha)
    sp.color=Color.new(c.red,c.green,c.blue,255)
  rescue
  end

  def focus_content_anchor_v10520(user)
    focus_cast_anchor_v1055(user)
  rescue
    [Graphics.width/2,Graphics.height/2,100]
  end

  def focus_content_update_intro_v10520
    return false unless @focus_cast_intro_active_v1055
    tier=@focus_tier_current_v10515 || :standard
    return false unless tier==:important || tier==:boss
    owner=@focus_cast_owner_v1055
    return false if owner==nil
    p=@focus_cast_profile_v1055 || {}
    intro=[p[:intro_frames].to_i,1].max
    age=@focus_cast_intro_age_v1055.to_i
    ratio=age.to_f/intro.to_f
    ratio=0.0 if ratio<0.0;ratio=1.0 if ratio>1.0
    a=focus_content_anchor_v10520(owner)
    type=@focus_cast_type_v1055 || :normal

    if tier==:important
      sp=@focus_content_ring_a_v10520
      if sp!=nil && !sp.disposed?
        focus_content_apply_type_color_v10520(sp,type)
        sp.x=a[0];sp.y=a[1]-5;sp.z=20024
        sp.zoom_x=1.45-0.50*ratio
        sp.zoom_y=sp.zoom_x
        sp.angle=(age*2)%360
        pulse=110+(Math.sin(age.to_f*0.32)*55).to_i
        pulse=70 if pulse<70;pulse=190 if pulse>190
        sp.opacity=pulse
        sp.visible=(ratio>0.35)
      end
      focus_content_hide_one_v10520(@focus_content_ring_b_v10520)
    else
      s1=@focus_content_ring_a_v10520
      s2=@focus_content_ring_b_v10520
      if s1!=nil && !s1.disposed?
        focus_content_apply_type_color_v10520(s1,type)
        s1.x=a[0];s1.y=a[1]-5;s1.z=20024
        s1.zoom_x=1.55-0.55*ratio;s1.zoom_y=s1.zoom_x
        s1.angle=(age*4)%360
        s1.opacity=170+(Math.sin(age.to_f*0.36)*55).to_i
        s1.visible=true
      end
      if s2!=nil && !s2.disposed?
        focus_content_apply_type_color_v10520(s2,type)
        s2.x=a[0];s2.y=a[1]-5;s2.z=20023
        s2.zoom_x=1.30-0.35*ratio;s2.zoom_y=s2.zoom_x
        s2.angle=(-age*3)%360
        s2.opacity=120+(Math.sin(age.to_f*0.29+1.3)*45).to_i
        s2.visible=true
      end
    end
    true
  rescue
    false
  end

  def focus_content_begin_release_v10520(tier,owner,type)
    return false unless tier==:important || tier==:boss
    @focus_content_release_active_v10520=true
    @focus_content_release_tier_v10520=tier
    @focus_content_release_owner_v10520=owner
    @focus_content_release_type_v10520=type
    @focus_content_release_start_v10520=Graphics.frame_count.to_i
    @focus_content_release_count_v10520=@focus_content_release_count_v10520.to_i+1
    frames=(tier==:boss ? PMD_AC::FOCUS_CONTENT_BOSS_RELEASE_FRAMES_V10520 : PMD_AC::FOCUS_CONTENT_IMPORTANT_RELEASE_FRAMES_V10520)
    log_event(:battle,'BATTLE_FOCUS_CONTENT_RELEASE_V10520 tier='+tier.to_s+
      ' frames='+frames.to_s+' owner='+(owner==nil ? 'NONE' : owner.log_name.to_s))
    true
  rescue
    false
  end

  def focus_content_update_release_v10520
    return false unless @focus_content_release_active_v10520
    tier=@focus_content_release_tier_v10520
    frames=(tier==:boss ? PMD_AC::FOCUS_CONTENT_BOSS_RELEASE_FRAMES_V10520 : PMD_AC::FOCUS_CONTENT_IMPORTANT_RELEASE_FRAMES_V10520)
    age=Graphics.frame_count.to_i-@focus_content_release_start_v10520.to_i
    if age<0 || age>=frames
      @focus_content_release_active_v10520=false
      focus_content_hide_v10520 unless @focus_cast_intro_active_v1055
      return false
    end
    owner=@focus_content_release_owner_v10520
    a=focus_content_anchor_v10520(owner)
    type=@focus_content_release_type_v10520 || :normal
    ratio=age.to_f/[frames-1,1].max.to_f
    s1=@focus_content_ring_a_v10520
    if s1!=nil && !s1.disposed?
      focus_content_apply_type_color_v10520(s1,type)
      s1.x=a[0];s1.y=a[1]-5;s1.z=20024
      s1.zoom_x=0.78+1.05*ratio;s1.zoom_y=s1.zoom_x
      s1.angle=(age*5)%360
      s1.opacity=PMD_AC.clamp((225*(1.0-ratio)).to_i,0,255)
      s1.visible=true
    end
    s2=@focus_content_ring_b_v10520
    if tier==:boss && s2!=nil && !s2.disposed?
      delay=PMD_AC::FOCUS_CONTENT_BOSS_SECOND_DELAY_V10520
      a2=age-delay
      if a2>=0
        ratio2=a2.to_f/[frames-delay-1,1].max.to_f
        focus_content_apply_type_color_v10520(s2,type)
        s2.x=a[0];s2.y=a[1]-5;s2.z=20023
        s2.zoom_x=0.72+1.25*ratio2;s2.zoom_y=s2.zoom_x
        s2.angle=(-a2*4)%360
        s2.opacity=PMD_AC.clamp((185*(1.0-ratio2)).to_i,0,255)
        s2.visible=true
      else
        s2.visible=false
      end
    elsif s2!=nil && !s2.disposed?
      s2.visible=false
    end
    true
  rescue
    false
  end

  def focus_cast_begin_v1055(user,target)
    ok=pmd_ac_v10520_focus_begin(user,target)
    if ok
      tier=@focus_tier_current_v10515 || (respond_to?(:focus_tier_v10515) ? focus_tier_v10515(user) : :standard)
      p=@focus_cast_profile_v1055 || {}
      status_minimal=focus_content_pure_status_v10520?(user)
      @focus_content_status_minimal_count_v10520=@focus_content_status_minimal_count_v10520.to_i+1 if status_minimal
      @focus_content_important_count_v10520=@focus_content_important_count_v10520.to_i+1 if tier==:important
      @focus_content_boss_count_v10520=@focus_content_boss_count_v10520.to_i+1 if tier==:boss
      log_event(:battle,'BATTLE_FOCUS_CONTENT_PROFILE_V10520 user='+(user==nil ? 'NONE' : user.log_name.to_s)+
        ' skill='+(user==nil ? 'NONE' : user.skill_name.to_s)+
        ' tier='+tier.to_s+' status_minimal='+(status_minimal ? '1':'0')+
        ' charge='+(p[:charge_style]||:orbit).to_s+
        ' owner_seal='+(tier==:important ? 'single' : (tier==:boss ? 'dual':'none')))
    end
    ok
  rescue
    false
  end

  def focus_cast_release_intro_v1055
    tier=@focus_tier_current_v10515 || :standard
    owner=@focus_cast_owner_v1055
    type=@focus_cast_type_v1055 || :normal
    r=pmd_ac_v10520_focus_release
    focus_content_begin_release_v10520(tier,owner,type) if r && (tier==:important || tier==:boss)
    r
  rescue
    pmd_ac_v10520_focus_release
  end

  def focus_cast_update_v1055
    r=pmd_ac_v10520_focus_update
    if @focus_cast_intro_active_v1055
      focus_content_update_intro_v10520
    else
      focus_content_update_release_v10520
    end
    r
  rescue
    r
  end

  def focus_content_reset_v10520
    @focus_content_status_minimal_count_v10520=0
    @focus_content_important_count_v10520=0
    @focus_content_boss_count_v10520=0
    @focus_content_release_count_v10520=0
    @focus_content_release_active_v10520=false
    @focus_content_release_tier_v10520=nil
    @focus_content_release_owner_v10520=nil
    @focus_content_release_type_v10520=nil
    @focus_content_release_start_v10520=-1
    @focus_content_summary_logged_v10520=false
    focus_content_hide_v10520
  rescue
  end

  def start
    r=pmd_ac_v10520_start
    focus_content_create_v10520
    r
  end

  def terminate
    focus_content_dispose_v10520
    pmd_ac_v10520_terminate
  end

  def start_battle
    r=pmd_ac_v10520_start_battle
    if respond_to?(:verification_mode) && verification_mode==:normal
      focus_content_reset_v10520
      log_event(:battle,'BATTLE_STATUS_MINIMAL_FOCUS_IMPORTANT_BOSS_CONTENT_V10520 START'+
        ' pure_status_charge=none target_mark_retained=1 result_ring_retained=1'+
        ' important_content=convergence_seal+release_echo'+
        ' boss_content=dual_counter_seal+double_release_echo'+
        ' important_release_frames='+PMD_AC::FOCUS_CONTENT_IMPORTANT_RELEASE_FRAMES_V10520.to_s+
        ' boss_release_frames='+PMD_AC::FOCUS_CONTENT_BOSS_RELEASE_FRAMES_V10520.to_s+
        ' damage_formula_unchanged=1 hp_unchanged=1 ai_unchanged=1 energy_unchanged=1'+
        ' attack_wait_unchanged=1 spatial_endpoint_unchanged=1 hit_timing_unchanged=1'+
        ' performance_threshold_ms=50')
    end
    r
  end

  def focus_content_summary_v10520
    return false if @focus_content_summary_logged_v10520
    @focus_content_summary_logged_v10520=true
    log_event(:battle,'BATTLE_STATUS_MINIMAL_FOCUS_IMPORTANT_BOSS_CONTENT_SUMMARY_V10520'+
      ' status_minimal='+@focus_content_status_minimal_count_v10520.to_i.to_s+
      ' important_content='+@focus_content_important_count_v10520.to_i.to_s+
      ' boss_content='+@focus_content_boss_count_v10520.to_i.to_s+
      ' release_echoes='+@focus_content_release_count_v10520.to_i.to_s+
      ' status_charge_none=1 important_seal=1 boss_dual_seal=1')
    true
  rescue
    false
  end

  def focus_cast_log_summary_v1055
    r=pmd_ac_v10520_focus_summary
    focus_content_summary_v10520
    r
  rescue
    false
  end
end
