# encoding: UTF-8
#===============================================================================
# ■ PMD AutoChess - Status Native Motion Seal + Focus Content III v1.05.21
#===============================================================================
# 【用途】
# 1. 修正 v1.05.20 Windows 實機仍可看到「叫聲瞬間播放普通攻擊身體動作」的問題。
#    v1.05.20 LOG 已證明 Growl 的 Focus charge_style=:none、elemental muzzle / impact / burst
#    皆已被封鎖，因此剩餘來源不是 VFX，而是 PMD Native Pose Router 在找不到 sound/status
#    專屬動作時回退到 :attack / :strike 的身體動作。
# 2. 對所有 pure status 技能建立最後一層 Presentation Ownership：技能執行期間不准使用
#    Attack / Strike / Lunge 類 fallback；優先維持施放前的低干擾 body loop，否則使用
#    Idle / Walk / Hover。只改 visual_action，不改 action timer、hit frame、effect、AI 或 Spatial。
# 3. 同步推進 Important / Boss Focus Content III：在 v1.05.20 封環與 release echo 之上，
#    增加 beam / rift / impact / burst 四種「釋放語言」，讓高價值技能不再只靠時間與光環區分。
#
# 【Windows 實機依據】
# - v1.05.20 Growl：BATTLE_FOCUS_CONTENT_PROFILE_V10520 明確為 status_minimal=1 charge=none，
#   但使用者仍看到普通攻擊動畫，因此可排除 Focus orbit。
# - 同場 v1.05.17 仍記錄 cast_muzzle / vfx_event / focus_impact suppression，證明舊 elemental
#   VFX 已被封住。剩餘可見來源鎖定 Native Pose fallback。
# - v1.05.19 / v1.05.20 F6 fixture 已實機 PASS Important=60/242、Boss=72/248，本版不重開
#   tier timing Authority，只擴張 Presentation content。
#
# 【Status Native Motion Seal 規則】
# - 判定沿用 PMD_AC.status_semantic_pure_v10516?，不特判 Growl。
# - begin_skill 前先記錄目前 visual_action；parent 完整跑完後，若是 pure status：
#     1) 優先恢復施放前的 :idle / :walk / :hover；
#     2) 若前一動作不是安全 loop，依序找 :idle / :walk / :hover；
#     3) 清除 Motion Phase B contact / remote presentation state；
#     4) visual_action 在該 skill action 存續期間持續回傳安全 pose。
# - 不改 @action / @action_timer / @action_hit_frame / @action_hit_done。
# - 不改 sound effect、Focus、target mark、Result text、v1.05.14 紅藍多光圈、KO、Result Hold。
#
# 【Focus Content III 四種釋放語言】
# - beam：從施放者朝目標方向拉出狹長 type-tinted 能量軌跡。
# - rift：目標附近出現交叉裂隙斬線；Spacial Rend / Roar of Time / Shadow Force 使用。
# - impact：目標附近短促交叉收束；Giga Impact / Volt Tackle 類使用。
# - burst：目標附近較寬的 X 型爆發線；Blast Burn / Draco Meteor / Sacred Fire 等使用。
# - Important 使用單段；Boss 會追加第二條延遲反向／偏角軌跡，形成更重的雙段語言。
# - 全部與 v1.05.20 owner seal + release echo 疊加，但不新增全螢幕字卡。
#
# 【可調參數】
# STATUS_SAFE_POSES_V10521 = [:idle,:walk,:hover]
# FOCUS_SEMANTIC_RELEASE_FRAMES_V10521 = 14
# FOCUS_SEMANTIC_BOSS_DELAY_V10521 = 2
#
# 【依賴／載入順序】
# - 置於 v1.05.20 之後、Main 之前。
# - 依賴 v1.05.16 pure-status classifier、v1.05.20 Focus Content II。
# - 使用 trailing alias/hook，不直接修改 Frozen Combat Core / Motion Core。
#
# 【事件／腳本呼叫方式】
# 無需事件呼叫，NORMAL battle 自動生效。
# F6 fixture 沿用 v1.05.19：Important 亞空裂斬會展示 rift；Boss 撞擊展示 impact。
#
# 【實際範例】
# - 小火龍 Growl：Focus 暗場／技能名 → 身體維持低干擾 loop → -攻擊 + 藍色下降光圈。
#   不再出現 Attack / Strike 身體動作，也不再有球狀 VFX。
# - Water Gun：damage move，不受 Status Motion Seal 影響。
# - F6 Spacial Rend：Important 封環 + rift crossed release。
# - F6 Boss Tackle：Boss 雙封環 + impact 雙段 release。
#
# 【LOG】
# BATTLE_STATUS_NATIVE_MOTION_SEAL_V10521 skill=... previous=... safe=... sealed=1
# BATTLE_FOCUS_SEMANTIC_RELEASE_V10521 tier=... family=... skill=...
# BATTLE_STATUS_NATIVE_MOTION_FOCUS_CONTENT_SUMMARY_V10521 ...
#===============================================================================
$imported={} unless defined?($imported)
$imported['PMD_AutoChess_StatusNativeMotionSeal_FocusContentIII_v10521']=true

module PMD_AC
  STATUS_SAFE_POSES_V10521 = [:idle,:walk,:hover]
  FOCUS_SEMANTIC_RELEASE_FRAMES_V10521 = 14
  FOCUS_SEMANTIC_BOSS_DELAY_V10521 = 2

  FOCUS_SIGNATURE_FAMILY_V10521 = {
    :mv_hyper_beam=>:beam,
    :mv_solar_beam=>:beam,
    :mv_hydro_cannon=>:beam,
    :mv_psycho_boost=>:beam,
    :mv_doom_desire=>:beam,
    :mv_spacial_rend=>:rift,
    :mv_roar_of_time=>:rift,
    :mv_shadow_force=>:rift,
    :mv_giga_impact=>:impact,
    :mv_volt_tackle=>:impact,
    :mv_frenzy_plant=>:burst,
    :mv_blast_burn=>:burst,
    :mv_draco_meteor=>:burst,
    :mv_judgment=>:burst,
    :mv_aeroblast=>:burst,
    :mv_sacred_fire=>:burst
  }
end

#==============================================================================
# ■ Game_PMDChessUnit - pure status 禁止攻擊型 Native fallback
#==============================================================================
class Game_PMDChessUnit
  alias pmd_ac_v10521_status_motion_begin_skill begin_skill unless method_defined?(:pmd_ac_v10521_status_motion_begin_skill)
  alias pmd_ac_v10521_status_motion_visual_action visual_action unless method_defined?(:pmd_ac_v10521_status_motion_visual_action)
  alias pmd_ac_v10521_status_motion_update update unless method_defined?(:pmd_ac_v10521_status_motion_update)
  alias pmd_ac_v10521_status_motion_start_combat start_combat unless method_defined?(:pmd_ac_v10521_status_motion_start_combat)
  alias pmd_ac_v10521_status_motion_stop_combat stop_combat unless method_defined?(:pmd_ac_v10521_status_motion_stop_combat)

  def status_motion_reset_v10521
    @status_motion_seal_active_v10521=false
    @status_motion_safe_pose_v10521=nil
    @status_motion_skill_v10521=nil
  end

  def start_combat
    r=pmd_ac_v10521_status_motion_start_combat
    status_motion_reset_v10521
    r
  end

  def stop_combat
    status_motion_reset_v10521
    pmd_ac_v10521_status_motion_stop_combat
  end

  def status_motion_pure_v10521?
    d=nil
    begin;d=skill_data;rescue;d=nil;end
    return PMD_AC.status_semantic_pure_v10516?(d) if PMD_AC.respond_to?(:status_semantic_pure_v10516?)
    false
  rescue
    false
  end

  def status_motion_pose_playable_v10521?(pose)
    return false if pose==nil
    begin
      return true if PMD_AC.respond_to?(:motion_playable_v102?) && PMD_AC.motion_playable_v102?(@species,pose)
    rescue
    end
    begin
      return true if PMD_AC.respond_to?(:raw_action_available_v060?) && PMD_AC.raw_action_available_v060?(@species,pose)
    rescue
    end
    false
  end

  def status_motion_safe_pose_v10521(previous)
    if PMD_AC::STATUS_SAFE_POSES_V10521.include?(previous) && status_motion_pose_playable_v10521?(previous)
      return previous
    end
    PMD_AC::STATUS_SAFE_POSES_V10521.each do |pose|
      return pose if status_motion_pose_playable_v10521?(pose)
    end
    :idle
  rescue
    :idle
  end

  def status_motion_clear_attack_presentation_v10521
    @motion_phase_b_action_v103=nil
    @motion_phase_b_recovery_v103=nil
    @motion_remote_state_v1038=nil
    @motion_remote_recovery_snap_v1038=false
    true
  rescue
    false
  end

  def status_motion_log_v10521(previous,safe)
    s=@scene
    return false if s==nil || !s.respond_to?(:log_event)
    key=@skill_type
    s.log_event(:battle,'BATTLE_STATUS_NATIVE_MOTION_SEAL_V10521 skill='+(key==nil ? 'NONE' : key.to_s)+
      ' previous='+(previous==nil ? 'NONE' : previous.to_s)+' safe='+(safe==nil ? 'NONE' : safe.to_s)+
      ' contact_state_cleared=1 remote_state_cleared=1 sealed=1')
    if s.respond_to?(:status_native_motion_note_v10521)
      s.status_native_motion_note_v10521(key,previous,safe)
    end
    true
  rescue
    false
  end

  def begin_skill(skill_target=nil)
    previous=@visual_action
    r=pmd_ac_v10521_status_motion_begin_skill(skill_target)
    if @action==:skill && status_motion_pure_v10521?
      safe=status_motion_safe_pose_v10521(previous)
      @status_motion_seal_active_v10521=true
      @status_motion_safe_pose_v10521=safe
      @status_motion_skill_v10521=@skill_type
      status_motion_clear_attack_presentation_v10521
      @visual_action=safe
      status_motion_log_v10521(previous,safe)
    else
      @status_motion_seal_active_v10521=false
      @status_motion_safe_pose_v10521=nil
      @status_motion_skill_v10521=nil
    end
    r
  rescue
    r
  end

  def visual_action
    if @status_motion_seal_active_v10521 && @action==:skill
      p=@status_motion_safe_pose_v10521
      return p if p!=nil
    end
    pmd_ac_v10521_status_motion_visual_action
  rescue
    pmd_ac_v10521_status_motion_visual_action
  end

  def update
    r=pmd_ac_v10521_status_motion_update
    if @status_motion_seal_active_v10521
      if @action!=:skill || (@status_motion_skill_v10521!=nil && @skill_type!=@status_motion_skill_v10521)
        @status_motion_seal_active_v10521=false
        @status_motion_safe_pose_v10521=nil
        @status_motion_skill_v10521=nil
      end
    end
    r
  end
end

#==============================================================================
# ■ Scene_PMD_AutoChess - Important/Boss semantic release content
#==============================================================================
class Scene_PMD_AutoChess
  alias pmd_ac_v10521_focus_release focus_cast_release_intro_v1055 unless method_defined?(:pmd_ac_v10521_focus_release)
  alias pmd_ac_v10521_focus_update focus_cast_update_v1055 unless method_defined?(:pmd_ac_v10521_focus_update)
  alias pmd_ac_v10521_start start unless method_defined?(:pmd_ac_v10521_start)
  alias pmd_ac_v10521_terminate terminate unless method_defined?(:pmd_ac_v10521_terminate)
  alias pmd_ac_v10521_start_battle start_battle unless method_defined?(:pmd_ac_v10521_start_battle)
  alias pmd_ac_v10521_focus_summary focus_cast_log_summary_v1055 unless method_defined?(:pmd_ac_v10521_focus_summary)

  def status_native_motion_note_v10521(key,previous,safe)
    @status_native_motion_count_v10521=@status_native_motion_count_v10521.to_i+1
    @status_native_motion_skills_v10521={} if @status_native_motion_skills_v10521==nil
    @status_native_motion_skills_v10521[key]=true if key!=nil
    true
  rescue
    false
  end

  def focus_semantic_family_v10521(key,tier)
    fam=PMD_AC::FOCUS_SIGNATURE_FAMILY_V10521[key]
    return fam if fam!=nil
    return :impact if tier==:boss
    :burst
  rescue
    :burst
  end

  def focus_semantic_make_line_v10521
    sp=Sprite.new(@viewport)
    sp.bitmap=Bitmap.new(96,8)
    sp.ox=48
    sp.oy=4
    sp.z=20029
    sp.visible=false
    sp.opacity=0
    sp.blend_type=1
    b=sp.bitmap
    for yy in 0...8
      for xx in 0...96
        dx=(xx-47.5).abs/47.5
        dy=(yy-3.5).abs/3.5
        a=(255*(1.0-dx)*(1.0-dy*0.55)).to_i
        next if a<=0
        b.set_pixel(xx,yy,Color.new(255,255,255,a))
      end
    end
    sp
  rescue
    nil
  end

  def focus_semantic_create_v10521
    @focus_semantic_line_a_v10521=focus_semantic_make_line_v10521
    @focus_semantic_line_b_v10521=focus_semantic_make_line_v10521
    focus_semantic_hide_v10521
    true
  rescue
    false
  end

  def focus_semantic_dispose_one_v10521(sp)
    return if sp==nil
    begin
      b=sp.bitmap
      b.dispose if b!=nil && !b.disposed?
    rescue
    end
    begin;sp.dispose unless sp.disposed?;rescue;end
  end

  def focus_semantic_dispose_v10521
    focus_semantic_dispose_one_v10521(@focus_semantic_line_a_v10521)
    focus_semantic_dispose_one_v10521(@focus_semantic_line_b_v10521)
    @focus_semantic_line_a_v10521=nil
    @focus_semantic_line_b_v10521=nil
    true
  rescue
    false
  end

  def focus_semantic_hide_one_v10521(sp)
    return if sp==nil || sp.disposed?
    sp.visible=false
    sp.opacity=0
    sp.angle=0
  rescue
  end

  def focus_semantic_hide_v10521
    focus_semantic_hide_one_v10521(@focus_semantic_line_a_v10521)
    focus_semantic_hide_one_v10521(@focus_semantic_line_b_v10521)
  end

  def focus_semantic_color_v10521(sp,type)
    return if sp==nil || sp.disposed?
    c=focus_cast_color_v1055(type,255)
    sp.color=Color.new(c.red,c.green,c.blue,255)
  rescue
  end

  def focus_semantic_anchor_pair_v10521(owner,target)
    a=focus_cast_anchor_v1055(owner)
    b=focus_cast_anchor_v1055(target)
    [a,b]
  rescue
    [[Graphics.width/2-40,Graphics.height/2,100],[Graphics.width/2+40,Graphics.height/2,100]]
  end

  def focus_semantic_angle_v10521(a,b)
    Math.atan2((b[1]-a[1]).to_f,(b[0]-a[0]).to_f)*180.0/Math::PI
  rescue
    0.0
  end

  def focus_semantic_start_release_v10521(tier,key,owner,target,type)
    return false unless tier==:important || tier==:boss
    @focus_semantic_active_v10521=true
    @focus_semantic_tier_v10521=tier
    @focus_semantic_key_v10521=key
    @focus_semantic_family_v10521=focus_semantic_family_v10521(key,tier)
    @focus_semantic_owner_v10521=owner
    @focus_semantic_target_v10521=target
    @focus_semantic_type_v10521=type
    @focus_semantic_start_v10521=Graphics.frame_count.to_i
    @focus_semantic_release_count_v10521=@focus_semantic_release_count_v10521.to_i+1
    fam=@focus_semantic_family_v10521
    @focus_semantic_family_counts_v10521={} if @focus_semantic_family_counts_v10521==nil
    @focus_semantic_family_counts_v10521[fam]=@focus_semantic_family_counts_v10521[fam].to_i+1
    log_event(:battle,'BATTLE_FOCUS_SEMANTIC_RELEASE_V10521 tier='+tier.to_s+
      ' family='+fam.to_s+' skill='+(key==nil ? 'NONE' : key.to_s)+
      ' frames='+PMD_AC::FOCUS_SEMANTIC_RELEASE_FRAMES_V10521.to_s+
      ' boss_second='+(tier==:boss ? '1':'0'))
    true
  rescue
    false
  end

  def focus_semantic_place_line_v10521(sp,x,y,angle,zoom_x,zoom_y,opacity,z)
    return if sp==nil || sp.disposed?
    sp.x=x.to_i
    sp.y=y.to_i
    sp.angle=angle
    sp.zoom_x=zoom_x
    sp.zoom_y=zoom_y
    sp.opacity=PMD_AC.clamp(opacity.to_i,0,255)
    sp.z=z
    sp.visible=sp.opacity>0
  rescue
  end

  def focus_semantic_update_one_v10521(sp,fam,a,b,ratio,second=false)
    return if sp==nil || sp.disposed?
    angle=focus_semantic_angle_v10521(a,b)
    mx=(a[0]+b[0])/2.0
    my=(a[1]+b[1])/2.0
    dist=Math.sqrt((b[0]-a[0]).to_f**2+(b[1]-a[1]).to_f**2)
    opacity=(235*(1.0-ratio)).to_i
    if fam==:beam
      z=[dist/96.0,0.45].max
      ang=angle+(second ? 4.0 : 0.0)
      yoff=second ? 5.0 : -2.0
      focus_semantic_place_line_v10521(sp,mx,my+yoff,ang,z*(0.72+0.28*ratio),0.75,opacity,20029)
    elsif fam==:rift
      x=b[0];y=b[1]-4
      ang=angle+(second ? -34.0 : 34.0)
      focus_semantic_place_line_v10521(sp,x,y,ang,0.55+0.90*ratio,0.95,opacity,20030)
    elsif fam==:impact
      x=b[0];y=b[1]-3
      ang=angle+(second ? 90.0 : 0.0)
      focus_semantic_place_line_v10521(sp,x,y,ang,0.34+0.58*ratio,0.82,opacity,20030)
    else
      x=b[0];y=b[1]-4
      ang=(second ? -48.0 : 48.0)+(ratio*26.0*(second ? -1.0 : 1.0))
      focus_semantic_place_line_v10521(sp,x,y,ang,0.50+0.95*ratio,1.05,opacity,20030)
    end
  rescue
    focus_semantic_hide_one_v10521(sp)
  end

  def focus_semantic_update_v10521
    return false unless @focus_semantic_active_v10521
    frames=PMD_AC::FOCUS_SEMANTIC_RELEASE_FRAMES_V10521
    age=Graphics.frame_count.to_i-@focus_semantic_start_v10521.to_i
    if age<0 || age>=frames
      @focus_semantic_active_v10521=false
      focus_semantic_hide_v10521
      return false
    end
    owner=@focus_semantic_owner_v10521
    target=@focus_semantic_target_v10521
    pair=focus_semantic_anchor_pair_v10521(owner,target)
    a=pair[0];b=pair[1]
    type=@focus_semantic_type_v10521 || :normal
    fam=@focus_semantic_family_v10521 || :burst
    ratio=age.to_f/[frames-1,1].max.to_f
    s1=@focus_semantic_line_a_v10521
    focus_semantic_color_v10521(s1,type)
    focus_semantic_update_one_v10521(s1,fam,a,b,ratio,false)
    s2=@focus_semantic_line_b_v10521
    if @focus_semantic_tier_v10521==:boss
      delay=PMD_AC::FOCUS_SEMANTIC_BOSS_DELAY_V10521
      if age>=delay
        r2=(age-delay).to_f/[frames-delay-1,1].max.to_f
        focus_semantic_color_v10521(s2,type)
        focus_semantic_update_one_v10521(s2,fam,a,b,r2,true)
      else
        focus_semantic_hide_one_v10521(s2)
      end
    else
      focus_semantic_hide_one_v10521(s2)
    end
    true
  rescue
    false
  end

  def focus_cast_release_intro_v1055
    tier=@focus_tier_current_v10515 || :standard
    owner=@focus_cast_owner_v1055
    target=@focus_cast_target_v1055
    key=(respond_to?(:focus_skill_type_v10515) ? focus_skill_type_v10515(owner) : nil)
    type=@focus_cast_type_v1055 || :normal
    r=pmd_ac_v10521_focus_release
    focus_semantic_start_release_v10521(tier,key,owner,target,type) if r && (tier==:important || tier==:boss)
    r
  rescue
    r
  end

  def focus_cast_update_v1055
    r=pmd_ac_v10521_focus_update
    focus_semantic_update_v10521
    r
  rescue
    r
  end

  def focus_content_reset_v10521
    @status_native_motion_count_v10521=0
    @status_native_motion_skills_v10521={}
    @focus_semantic_active_v10521=false
    @focus_semantic_release_count_v10521=0
    @focus_semantic_family_counts_v10521={}
    @focus_semantic_summary_logged_v10521=false
    focus_semantic_hide_v10521
  rescue
  end

  def start
    r=pmd_ac_v10521_start
    focus_semantic_create_v10521
    r
  end

  def terminate
    focus_semantic_dispose_v10521
    pmd_ac_v10521_terminate
  end

  def start_battle
    r=pmd_ac_v10521_start_battle
    if respond_to?(:verification_mode) && verification_mode==:normal
      focus_content_reset_v10521
      log_event(:battle,'BATTLE_STATUS_NATIVE_MOTION_FOCUS_CONTENT_V10521 START'+
        ' pure_status_attack_pose_fallback=suppressed safe_poses=idle,walk,hover'+
        ' semantic_release=beam,rift,impact,burst boss_second_delay='+PMD_AC::FOCUS_SEMANTIC_BOSS_DELAY_V10521.to_s+
        ' damage_formula_unchanged=1 hp_unchanged=1 ai_unchanged=1 energy_unchanged=1'+
        ' attack_wait_unchanged=1 spatial_endpoint_unchanged=1 hit_timing_unchanged=1'+
        ' motion_core_unchanged=1 performance_threshold_ms=50')
    end
    r
  end

  def status_native_motion_focus_summary_v10521
    return false if @focus_semantic_summary_logged_v10521
    @focus_semantic_summary_logged_v10521=true
    skills=[]
    (@status_native_motion_skills_v10521 || {}).keys.each{|k|skills << k.to_s}
    fam=[]
    [:beam,:rift,:impact,:burst].each do |k|
      n=(@focus_semantic_family_counts_v10521 || {})[k].to_i
      fam << k.to_s+'='+n.to_s
    end
    log_event(:battle,'BATTLE_STATUS_NATIVE_MOTION_FOCUS_CONTENT_SUMMARY_V10521'+
      ' status_motion_sealed='+@status_native_motion_count_v10521.to_i.to_s+
      ' status_skills=['+skills.sort.join(',')+']'+
      ' semantic_releases='+@focus_semantic_release_count_v10521.to_i.to_s+
      ' families=['+fam.join(',')+']'+
      ' important_boss_content_v10520_retained=1')
    true
  rescue
    false
  end

  def focus_cast_log_summary_v1055
    r=pmd_ac_v10521_focus_summary
    status_native_motion_focus_summary_v10521
    r
  rescue
    false
  end
end
