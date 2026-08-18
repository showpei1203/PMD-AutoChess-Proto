# encoding: UTF-8
#==============================================================================
# ■ PMD AutoChess - Skill Focus Cue I v1.05.4
#==============================================================================
# 【用途】
# 1. 延續 v1.05.3「恢復原始戰鬥節奏」基底，不修改 HP、Damage、Attack Wait、
#    Energy、Action Timing、AI、Spatial 或技能真正的解算順序。
# 2. 只在 NORMAL 戰鬥加入極輕量、戰場內原生的技能焦點提示，協助玩家辨識：
#      施放者 → 主要目標 → 真正命中／效果發生的位置。
# 3. 不使用 v1.05.2 的上方事件列表、不畫 Source→Target 長連線、不增加文字編號，
#    避免把原始戰場重新變成額外 UI 儀表板。
#
# 【主要設定】
# SKILL_FOCUS_SOURCE_FRAMES_V1054 = 14
#   技能開始後，施放者頭頂的同屬性色小箭頭顯示時間。
# SKILL_FOCUS_TARGET_FRAMES_V1054 = 34
#   技能開始後，主要目標腳下的同屬性色焦點框顯示時間。
# SKILL_FOCUS_IMPACT_FRAMES_V1054 = 9
#   Damage／Effect 真正發生時，目標腳下的短促放大脈衝時間。
# SKILL_FOCUS_VISIBLE_CONTEXTS_V1054 = 2
#   同時最多顯示最近兩個技能意圖，避免六隻單位一起掛滿標記。
# SKILL_FOCUS_TRACK_CONTEXTS_V1054 = 8
#   背景最多保留八個最近技能 context，用於把晚到 Projectile／Effect 重新連回來源。
# SKILL_FOCUS_TRACK_FRAMES_V1054 = 120
#   技能開始後最多 120 frame 仍可把晚到命中辨識為該技能結果；只做視覺歸因。
# SKILL_FOCUS_IMPACT_POOL_V1054 = 4
#   同幀多目標技能最多同時顯示四個短促 Impact pulse。
#
# 【機制規則】
# - Frozen Combat Core 不直接修改；本腳本為 trailing alias/hook layer。
# - Game_PMDChessUnit#begin_skill 只在既有 begin_skill 完成後通知 Scene，
#   不提前、不延後、不取消原技能。
# - Scene#deal_direct_damage / #apply_skill_effects 只在 parent 完成後建立視覺 pulse。
# - 主要目標提示使用技能本身的 Type 顏色，與既有技能名稱 Banner 形成自然對應。
# - 多目標／晚到 Projectile 不額外畫長線，只在真正受影響的目標腳下出現短 pulse。
# - 同一 user/target/frame 的 Damage + Effect 會去重，避免同一命中閃兩次。
# - PMD Motion verifier 不啟用本層，避免污染既有回歸驗收。
# - 不新增 Gameplay delay / queue / stagger；所有 HP、狀態與命中仍在原 frame 解算。
#
# 【可調參數】
# - 若提示太搶眼：先降低 SOURCE/TARGET frame，不應先改戰鬥速度。
# - 若 Projectile 太晚才到：只提高 TRACK_FRAMES，不延長玩家看見的 Target cue。
# - 若大型 AoE 同時命中超過四個目標，可提高 IMPACT_POOL；3v3 正式戰場目前 4 足夠。
#
# 【事件／腳本呼叫方式】
# 無需事件呼叫。NORMAL → Shift 開戰後自動啟用。
# LOG 會輸出：
#   BATTLE_SKILL_FOCUS_CUE_V1054 START ...
#   BATTLE_SKILL_FOCUS_CUE_SUMMARY_V1054 ...
#
# 【實際範例】
# - 小火龍開始使用技能：小火龍頭上短暫出現 Type 色箭頭，主要目標腳下同步出現焦點框。
# - Projectile 真正打中目標：該目標腳下只脈衝 9 frame，Damage Popup 仍照原規則顯示。
# - 兩隻寶可夢近乎同時放技能：只保留最近兩組細小焦點提示；AI 與技能解算完全不排隊。
#==============================================================================
$imported={} unless defined?($imported)
$imported['PMD_AutoChess_SkillFocusCueI_v1054']=true

module PMD_AC
  SKILL_FOCUS_SOURCE_FRAMES_V1054 = 14
  SKILL_FOCUS_TARGET_FRAMES_V1054 = 34
  SKILL_FOCUS_IMPACT_FRAMES_V1054 = 9
  SKILL_FOCUS_VISIBLE_CONTEXTS_V1054 = 2
  SKILL_FOCUS_TRACK_CONTEXTS_V1054 = 8
  SKILL_FOCUS_TRACK_FRAMES_V1054 = 120
  SKILL_FOCUS_IMPACT_POOL_V1054 = 4
end

class Game_PMDChessUnit
  alias pmd_ac_v1054_skill_focus_begin_skill begin_skill unless method_defined?(:pmd_ac_v1054_skill_focus_begin_skill)

  def begin_skill(skill_target=nil)
    r=pmd_ac_v1054_skill_focus_begin_skill(skill_target)
    if @action==:skill && @scene!=nil && @scene.respond_to?(:skill_focus_begin_v1054)
      @scene.skill_focus_begin_v1054(self,@skill_target)
    end
    r
  end
end

class Scene_PMD_AutoChess
  alias pmd_ac_v1054_skill_focus_start start unless method_defined?(:pmd_ac_v1054_skill_focus_start)
  alias pmd_ac_v1054_skill_focus_terminate terminate unless method_defined?(:pmd_ac_v1054_skill_focus_terminate)
  alias pmd_ac_v1054_skill_focus_update update unless method_defined?(:pmd_ac_v1054_skill_focus_update)
  alias pmd_ac_v1054_skill_focus_start_battle start_battle unless method_defined?(:pmd_ac_v1054_skill_focus_start_battle)
  alias pmd_ac_v1054_skill_focus_deal_direct_damage deal_direct_damage unless method_defined?(:pmd_ac_v1054_skill_focus_deal_direct_damage)
  alias pmd_ac_v1054_skill_focus_apply_skill_effects apply_skill_effects unless method_defined?(:pmd_ac_v1054_skill_focus_apply_skill_effects)
  alias pmd_ac_v1054_skill_focus_check_battle_end check_battle_end unless method_defined?(:pmd_ac_v1054_skill_focus_check_battle_end)

  def skill_focus_normal_v1054?
    return false unless @phase==:battle
    if respond_to?(:motion_phase_b_verifier_active_v1036?)
      return false if motion_phase_b_verifier_active_v1036?
    end
    true
  rescue
    false
  end

  def skill_focus_color_v1054(type,alpha=255)
    if PMD_AC.respond_to?(:skill_type_banner_color_v10314)
      c=PMD_AC.skill_type_banner_color_v10314(type,alpha)
      return c if c!=nil
    end
    Color.new(255,230,120,alpha)
  rescue
    Color.new(255,230,120,alpha)
  end

  def skill_focus_type_v1054(unit)
    if PMD_AC.respond_to?(:skill_type_banner_type_v10314)
      return PMD_AC.skill_type_banner_type_v10314(unit)
    end
    :normal
  rescue
    :normal
  end

  def skill_focus_make_sprite_v1054(w,h)
    sp=Sprite.new(@viewport)
    sp.bitmap=Bitmap.new(w,h)
    sp.ox=w/2
    sp.oy=h/2
    sp.visible=false
    sp.opacity=0
    sp.z=9999
    sp
  rescue
    nil
  end

  def skill_focus_create_sprites_v1054
    @skill_focus_source_sprites_v1054=[]
    @skill_focus_target_sprites_v1054=[]
    PMD_AC::SKILL_FOCUS_VISIBLE_CONTEXTS_V1054.times do
      @skill_focus_source_sprites_v1054.push(skill_focus_make_sprite_v1054(24,14))
      @skill_focus_target_sprites_v1054.push(skill_focus_make_sprite_v1054(36,16))
    end
    @skill_focus_impact_sprites_v1054=[]
    PMD_AC::SKILL_FOCUS_IMPACT_POOL_V1054.times do
      @skill_focus_impact_sprites_v1054.push(skill_focus_make_sprite_v1054(42,20))
    end
    true
  rescue
    false
  end

  def skill_focus_dispose_sprite_v1054(sp)
    return if sp==nil
    if sp.bitmap!=nil && !sp.bitmap.disposed?
      sp.bitmap.dispose
    end
    sp.dispose unless sp.disposed?
  rescue
  end

  def skill_focus_dispose_v1054
    (@skill_focus_source_sprites_v1054 || []).each{|sp|skill_focus_dispose_sprite_v1054(sp)}
    (@skill_focus_target_sprites_v1054 || []).each{|sp|skill_focus_dispose_sprite_v1054(sp)}
    (@skill_focus_impact_sprites_v1054 || []).each{|sp|skill_focus_dispose_sprite_v1054(sp)}
    @skill_focus_source_sprites_v1054=[]
    @skill_focus_target_sprites_v1054=[]
    @skill_focus_impact_sprites_v1054=[]
    true
  rescue
    false
  end

  def skill_focus_draw_source_v1054(sp,type)
    return if sp==nil || sp.bitmap==nil
    b=sp.bitmap;b.clear
    c=skill_focus_color_v1054(type,235)
    d=Color.new(0,0,0,180)
    b.fill_rect(5,1,14,2,d)
    b.fill_rect(7,3,10,2,d)
    b.fill_rect(9,5,6,2,d)
    b.fill_rect(11,7,2,3,d)
    b.fill_rect(5,0,14,2,c)
    b.fill_rect(7,2,10,2,c)
    b.fill_rect(9,4,6,2,c)
    b.fill_rect(11,6,2,3,c)
  rescue
  end

  def skill_focus_draw_target_v1054(sp,type,impact=false)
    return if sp==nil || sp.bitmap==nil
    b=sp.bitmap;b.clear
    c=skill_focus_color_v1054(type,impact ? 255 : 210)
    d=Color.new(0,0,0,170)
    y=impact ? 3 : 5
    # 只畫四個短角，不形成大面積圓圈，避免遮住腳下 Position 資訊。
    b.fill_rect(2,y,9,2,d);b.fill_rect(2,y,2,5,d)
    b.fill_rect(25,y,9,2,d);b.fill_rect(32,y,2,5,d)
    b.fill_rect(2,y+7,9,2,d);b.fill_rect(2,y+4,2,5,d)
    b.fill_rect(25,y+7,9,2,d);b.fill_rect(32,y+4,2,5,d)
    b.fill_rect(3,y-1,8,2,c);b.fill_rect(3,y-1,2,5,c)
    b.fill_rect(25,y-1,8,2,c);b.fill_rect(31,y-1,2,5,c)
    b.fill_rect(3,y+6,8,2,c);b.fill_rect(3,y+3,2,5,c)
    b.fill_rect(25,y+6,8,2,c);b.fill_rect(31,y+3,2,5,c)
  rescue
  end

  def skill_focus_find_unit_sprite_v1054(unit)
    return nil if unit==nil
    (@unit_sprites || []).each do |sp|
      return sp if sp!=nil && sp.respond_to?(:unit) && sp.unit==unit
    end
    nil
  rescue
    nil
  end

  def skill_focus_anchor_v1054(unit,kind)
    sp=skill_focus_find_unit_sprite_v1054(unit)
    return nil if sp==nil || sp.disposed?
    top=(sp.y-sp.oy*sp.zoom_y).to_i
    if kind==:source
      return [sp.x.to_i,top-7,sp.z.to_i+42]
    end
    [sp.x.to_i,sp.y.to_i+4,sp.z.to_i+38]
  rescue
    nil
  end

  def skill_focus_reset_v1054
    @skill_focus_contexts_v1054=[]
    @skill_focus_impacts_v1054=[]
    @skill_focus_last_impact_frame_v1054={}
    @skill_focus_casts_v1054=0
    @skill_focus_pulses_v1054=0
    @skill_focus_overlap_casts_v1054=0
    @skill_focus_context_drops_v1054=0
    @skill_focus_summary_logged_v1054=false
    (@skill_focus_source_sprites_v1054 || []).each{|sp|sp.visible=false if sp!=nil}
    (@skill_focus_target_sprites_v1054 || []).each{|sp|sp.visible=false if sp!=nil}
    (@skill_focus_impact_sprites_v1054 || []).each{|sp|sp.visible=false if sp!=nil}
    true
  rescue
    false
  end

  def skill_focus_begin_v1054(user,target)
    return false unless skill_focus_normal_v1054?
    return false if user==nil
    now=Graphics.frame_count
    type=skill_focus_type_v1054(user)
    @skill_focus_contexts_v1054=[] if @skill_focus_contexts_v1054==nil
    recent=@skill_focus_contexts_v1054[-1]
    if recent!=nil && now-recent[:start].to_i<=18
      @skill_focus_overlap_casts_v1054=@skill_focus_overlap_casts_v1054.to_i+1
    end
    @skill_focus_contexts_v1054.delete_if{|c|c[:user]==user}
    @skill_focus_contexts_v1054.push({:user=>user,:target=>target,:type=>type,:start=>now,:impact_at=>nil})
    while @skill_focus_contexts_v1054.size>PMD_AC::SKILL_FOCUS_TRACK_CONTEXTS_V1054
      @skill_focus_contexts_v1054.shift
      @skill_focus_context_drops_v1054=@skill_focus_context_drops_v1054.to_i+1
    end
    @skill_focus_casts_v1054=@skill_focus_casts_v1054.to_i+1
    true
  rescue
    false
  end

  def skill_focus_context_for_v1054(user)
    return nil if user==nil
    now=Graphics.frame_count
    (@skill_focus_contexts_v1054 || []).reverse_each do |c|
      next unless c[:user]==user
      return c if now-c[:start].to_i<=PMD_AC::SKILL_FOCUS_TRACK_FRAMES_V1054
    end
    nil
  rescue
    nil
  end

  def skill_focus_spawn_impact_v1054(user,target)
    return false unless skill_focus_normal_v1054?
    return false if user==nil || target==nil
    ctx=skill_focus_context_for_v1054(user)
    return false if ctx==nil
    now=Graphics.frame_count
    @skill_focus_last_impact_frame_v1054={} if @skill_focus_last_impact_frame_v1054==nil
    key=user.object_id.to_s+':'+target.object_id.to_s
    return false if @skill_focus_last_impact_frame_v1054[key].to_i==now
    @skill_focus_last_impact_frame_v1054[key]=now
    ctx[:impact_at]=now
    @skill_focus_impacts_v1054=[] if @skill_focus_impacts_v1054==nil
    @skill_focus_impacts_v1054.push({:target=>target,:type=>ctx[:type],:start=>now})
    while @skill_focus_impacts_v1054.size>PMD_AC::SKILL_FOCUS_IMPACT_POOL_V1054
      @skill_focus_impacts_v1054.shift
    end
    @skill_focus_pulses_v1054=@skill_focus_pulses_v1054.to_i+1
    true
  rescue
    false
  end

  def skill_focus_hide_slots_v1054(list,from_index)
    return if list==nil
    i=from_index
    while i<list.size
      list[i].visible=false if list[i]!=nil
      i+=1
    end
  rescue
  end

  def skill_focus_update_context_sprites_v1054
    now=Graphics.frame_count
    active=(@skill_focus_contexts_v1054 || []).select do |c|
      age=now-c[:start].to_i
      age>=0 && age<PMD_AC::SKILL_FOCUS_TARGET_FRAMES_V1054 && c[:target]!=nil
    end
    max=PMD_AC::SKILL_FOCUS_VISIBLE_CONTEXTS_V1054
    active=active[-max,max] || active
    active.each_with_index do |c,i|
      source_sp=(@skill_focus_source_sprites_v1054 || [])[i]
      target_sp=(@skill_focus_target_sprites_v1054 || [])[i]
      age=now-c[:start].to_i
      alpha=(i==active.size-1 ? 235 : 145)
      sa=skill_focus_anchor_v1054(c[:user],:source)
      if source_sp!=nil && sa!=nil && age<PMD_AC::SKILL_FOCUS_SOURCE_FRAMES_V1054
        skill_focus_draw_source_v1054(source_sp,c[:type]) if source_sp.instance_variable_get(:@skill_focus_type_v1054)!=c[:type]
        source_sp.instance_variable_set(:@skill_focus_type_v1054,c[:type])
        source_sp.x=sa[0];source_sp.y=sa[1];source_sp.z=sa[2]
        source_sp.opacity=alpha
        source_sp.zoom_x=1.0;source_sp.zoom_y=1.0
        source_sp.visible=true
      elsif source_sp!=nil
        source_sp.visible=false
      end
      ta=skill_focus_anchor_v1054(c[:target],:target)
      if target_sp!=nil && ta!=nil
        skill_focus_draw_target_v1054(target_sp,c[:type],false) if target_sp.instance_variable_get(:@skill_focus_type_v1054)!=c[:type]
        target_sp.instance_variable_set(:@skill_focus_type_v1054,c[:type])
        target_sp.x=ta[0];target_sp.y=ta[1];target_sp.z=ta[2]
        target_sp.opacity=alpha
        target_sp.zoom_x=1.0;target_sp.zoom_y=1.0
        target_sp.visible=true
      elsif target_sp!=nil
        target_sp.visible=false
      end
    end
    skill_focus_hide_slots_v1054(@skill_focus_source_sprites_v1054,active.size)
    skill_focus_hide_slots_v1054(@skill_focus_target_sprites_v1054,active.size)
    @skill_focus_contexts_v1054.delete_if{|c|now-c[:start].to_i>PMD_AC::SKILL_FOCUS_TRACK_FRAMES_V1054}
  rescue
  end

  def skill_focus_update_impact_sprites_v1054
    now=Graphics.frame_count
    impacts=@skill_focus_impacts_v1054 || []
    impacts.delete_if{|e|now-e[:start].to_i>=PMD_AC::SKILL_FOCUS_IMPACT_FRAMES_V1054}
    impacts.each_with_index do |e,i|
      sp=(@skill_focus_impact_sprites_v1054 || [])[i]
      next if sp==nil
      a=skill_focus_anchor_v1054(e[:target],:target)
      if a==nil
        sp.visible=false
        next
      end
      skill_focus_draw_target_v1054(sp,e[:type],true) if sp.instance_variable_get(:@skill_focus_type_v1054)!=e[:type]
      sp.instance_variable_set(:@skill_focus_type_v1054,e[:type])
      age=now-e[:start].to_i
      life=PMD_AC::SKILL_FOCUS_IMPACT_FRAMES_V1054.to_f
      p=1.0-age.to_f/life
      sp.x=a[0];sp.y=a[1];sp.z=a[2]+2
      sp.opacity=PMD_AC.clamp((255*p).to_i,0,255)
      zoom=1.0+0.35*p
      sp.zoom_x=zoom;sp.zoom_y=zoom
      sp.visible=true
    end
    skill_focus_hide_slots_v1054(@skill_focus_impact_sprites_v1054,impacts.size)
  rescue
  end

  def skill_focus_update_v1054
    unless skill_focus_normal_v1054?
      skill_focus_hide_slots_v1054(@skill_focus_source_sprites_v1054,0)
      skill_focus_hide_slots_v1054(@skill_focus_target_sprites_v1054,0)
      skill_focus_hide_slots_v1054(@skill_focus_impact_sprites_v1054,0)
      return
    end
    skill_focus_update_context_sprites_v1054
    skill_focus_update_impact_sprites_v1054
  rescue
  end

  def start
    r=pmd_ac_v1054_skill_focus_start
    skill_focus_create_sprites_v1054
    skill_focus_reset_v1054
    r
  end

  def terminate
    skill_focus_dispose_v1054
    pmd_ac_v1054_skill_focus_terminate
  end

  def update
    r=pmd_ac_v1054_skill_focus_update
    skill_focus_update_v1054 if $scene==self
    r
  end

  def start_battle
    r=pmd_ac_v1054_skill_focus_start_battle
    if skill_focus_normal_v1054?
      skill_focus_reset_v1054
      log_event(:battle,'BATTLE_SKILL_FOCUS_CUE_V1054 START source_frames=14 target_frames=34 impact_frames=9'+
        ' visible_contexts=2 track_contexts=8 impact_pool=4 banner_54f_retained=1 event_feed=0 tether_line=0'+
        ' gameplay_delay=0 hp_unchanged=1 damage_unchanged=1 attack_wait_unchanged=1 energy_unchanged=1'+
        ' action_timing_unchanged=1 ai_unchanged=1 spatial_unchanged=1')
    end
    r
  end

  def deal_direct_damage(*args)
    user=(args[0] rescue nil)
    target=(args[1] rescue nil)
    r=pmd_ac_v1054_skill_focus_deal_direct_damage(*args)
    skill_focus_spawn_impact_v1054(user,target)
    r
  end

  def apply_skill_effects(*args)
    user=(args[0] rescue nil)
    target=(args[1] rescue nil)
    r=pmd_ac_v1054_skill_focus_apply_skill_effects(*args)
    skill_focus_spawn_impact_v1054(user,target)
    r
  end

  def skill_focus_log_summary_v1054
    return false if @skill_focus_summary_logged_v1054
    @skill_focus_summary_logged_v1054=true
    log_event(:battle,'BATTLE_SKILL_FOCUS_CUE_SUMMARY_V1054 casts='+@skill_focus_casts_v1054.to_i.to_s+
      ' impact_pulses='+@skill_focus_pulses_v1054.to_i.to_s+
      ' overlap_casts_18f='+@skill_focus_overlap_casts_v1054.to_i.to_s+
      ' context_drops='+@skill_focus_context_drops_v1054.to_i.to_s+
      ' max_visible_contexts=2 event_feed=0 tether_line=0 gameplay_delay=0 original_pace_retained=1')
    true
  rescue
    false
  end

  def check_battle_end
    before=@phase
    r=pmd_ac_v1054_skill_focus_check_battle_end
    skill_focus_log_summary_v1054 if before==:battle && @phase!=:battle
    r
  end
end
