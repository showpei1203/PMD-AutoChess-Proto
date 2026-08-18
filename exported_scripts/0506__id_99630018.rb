# encoding: UTF-8
#===============================================================================
# ■ PMD AutoChess - Focus Carryover + Basic Attack Spark + Important Library II v1.05.22
#===============================================================================
# 【用途】
# 1. 修正 v1.05.21 實機影片確認的「叫聲 Focus 開始時仍看到完整火球」問題。
#    影片逐格檢查後確認：火球在「叫聲」標題出現前就已存在，並在 Focus freeze 後
#    停在完全相同位置；它不是 Growl 新生成的 cast muzzle / orbit / attack pose，而是
#    前一個行動留下的 Sprite_PMDVFXBurst 視覺尾巴，被 v1.05.8 的 baseline freeze 凍住。
# 2. 建立正式 Focus Carryover Boundary：
#    - 純 Status Focus：開始前直接清除上一行動殘留的短命 PMD VFX Burst，確保狀態技能
#      從第一幀就是乾淨畫面，只保留暗場、技能名、target mark、結果文字與紅／藍光圈。
#    - 非 Status Focus：舊短命 Burst 不再被永久凍在 Focus 畫面中，而是在 intro 前段
#      繼續播放至結束，最多 12f 後強制清掉；不推進任何 gameplay / logical projectile。
# 3. 普通攻擊 Presentation 降噪：遠程 basic projectile 固定縮小，不跟進化型態放大；
#    命中不再使用大型 elemental impact，而改成 4 顆屬性色小光點由目標中心短促四散。
# 4. 同步推進 Important Skill Library II：把高辨識度大招從 16 招擴到 40 招，並在
#    v1.05.21 的 beam / rift / impact / burst 上新增 wave / column 兩種 release family。
#
# 【實機依據】
# - v1.05.21 LOG：Growl 已為 charge=none、cast_muzzle suppressed、Native Motion sealed，
#   但影片仍看到完整橘色火球。
# - 逐格影片可見該火球在 Growl title 出現前已存在，Growl Focus 後只是被 freeze 保留。
# - 因此本版修的是 Focus 與上一個 action 的 Presentation Ownership 邊界，不再繼續
#   對 Growl 本身追加無效特判。
#
# 【Focus Carryover 規則】
# - 僅處理 @effect_sprites 中 Sprite_PMDVFXBurst 這種純短命 Presentation Sprite。
# - 不清除 / 不推進 @projectile_sprites，避免 logical projectile 與 sprite 脫鉤。
# - 不修改 Damage、HP、AI、Energy、Attack Wait、Priority、hit timing、Spatial endpoint。
# - 純 Status：Focus begin 前直接 dispose 上一招的 VFXBurst。
# - Damage / Important / Boss：intro 期間只讓 pre-existing VFXBurst 自己走完動畫；
#   其他 baseline effect、所有 gameplay、所有 logical projectile 仍維持 freeze。
#
# 【Basic Attack Spark 規則】
# - 遠程 basic projectile：只縮 Presentation zoom，logical radius / speed / tracking / collision 不變。
# - basic 命中：4 顆固定大小 type-colored pixel spark，12f 左右向外四散並淡出。
# - melee / ranged basic 共用同一命中語言。
# - VFX 尺度與 species stage / sprite size 無關，因此 Charmander 與 Charizard 的 basic
#   命中辨識度一致；進化差異留給 Motion、Skill、Important/Boss Focus。
# - Damage skill 不進此規則，水槍／起風／大招仍保留各自技能 VFX。
#
# 【Important Library II】
# 原 v1.05.15 16 招全部保留，再新增 24 招：
# Thunder / Blizzard / Fire Blast / Hydro Pump / Earthquake / Stone Edge /
# Close Combat / Brave Bird / Flare Blitz / Wood Hammer / Leaf Storm / Overheat /
# Focus Blast / Aura Sphere / Dark Pulse / Dragon Pulse / Flash Cannon / Explosion /
# Extreme Speed / Sky Attack / Eruption / Water Spout / Future Sight / Meteor Mash。
#
# 新 release family：
# - wave：全場／範圍型大招，目標中心橫向擴散。
# - column：由上往下的高能量打擊，目標位置垂直收束。
# 舊 beam / rift / impact / burst 保留。
#
# 【主要設定】
# FOCUS_CARRYOVER_DRAIN_MAX_V10522 = 12
#   非 Status Focus 中，舊 VFXBurst 最多再跑 12f；正常情況會在此之前自行結束。
# IMPORTANT_FOCUS_SKILL_TYPES_V10522
#   Library II 新增技能 runtime key。
# FOCUS_SIGNATURE_FAMILY_V10522
#   Library II 技能的 release family。
#
# 【LOG】
# BATTLE_FOCUS_CARRYOVER_BOUNDARY_V10522 START ...
# BATTLE_FOCUS_CARRYOVER_CLEAN_V10522 skill=... mode=status_purge purged=... sheets=[...]
# BATTLE_FOCUS_CARRYOVER_DRAIN_V10522 finished=... forced=...
# BATTLE_IMPORTANT_LIBRARY_II_V10522 skill=... tier=important family=...
# BATTLE_FOCUS_CARRYOVER_IMPORTANT_LIBRARY_SUMMARY_V10522 ...
#
# 【實際範例】
# 1. 前一招火系攻擊剛爆炸，小火龍立刻用叫聲：舊火球在叫聲 Focus 第一幀前就被清掉。
# 2. 水槍 Focus 緊接上一招：舊短命 impact 可在暗場前段自然播完，不會被凍成背景擺設。
# 3. Thunder / Eruption 類 Important 技能：仍是 60f Important Focus，但 release 會改成
#    column / wave 語言，不再所有大招共用同一個 X 線條。
#===============================================================================
$imported={} unless defined?($imported)
$imported['PMD_AutoChess_FocusCarryoverBoundary_ImportantLibraryII_v10522']=true

module PMD_AC
  FOCUS_CARRYOVER_DRAIN_MAX_V10522 = 12

  BASIC_PROJECTILE_SCALE_V10522 = 0.28
  BASIC_HIT_PARTICLE_COUNT_V10522 = 4
  BASIC_HIT_PARTICLE_FRAMES_V10522 = 12
  BASIC_HIT_PARTICLE_SPREAD_V10522 = 16.0

  BASIC_HIT_TYPE_RGB_V10522 = {
    :normal=>[224,224,214], :fire=>[255,116,52], :water=>[74,188,255],
    :electric=>[255,226,58], :grass=>[105,218,100], :ice=>[135,232,255],
    :fighting=>[238,104,70], :poison=>[184,92,218], :ground=>[213,166,89],
    :flying=>[155,190,255], :psychic=>[255,108,180], :bug=>[174,211,65],
    :rock=>[196,169,93], :ghost=>[143,112,210], :dragon=>[123,105,255],
    :dark=>[126,111,106], :steel=>[178,195,213], :fairy=>[255,161,209],
    :seed=>[105,218,100], :web=>[174,211,65], :impact=>[224,224,214],
    :neutral=>[224,224,214]
  }

  @basic_hit_particle_bitmap_cache_v10522 = {}

  def self.basic_hit_rgb_v10522(style)
    BASIC_HIT_TYPE_RGB_V10522[style] || BASIC_HIT_TYPE_RGB_V10522[:normal]
  rescue
    [224,224,214]
  end

  def self.basic_hit_particle_bitmap_v10522(style)
    @basic_hit_particle_bitmap_cache_v10522={} if @basic_hit_particle_bitmap_cache_v10522==nil
    key=style || :normal
    bmp=@basic_hit_particle_bitmap_cache_v10522[key]
    return bmp if bmp!=nil && !bmp.disposed?
    rgb=basic_hit_rgb_v10522(key)
    bmp=Bitmap.new(7,7)
    bmp.clear
    bmp.fill_rect(1,1,5,5,Color.new(rgb[0],rgb[1],rgb[2],90))
    bmp.fill_rect(2,2,3,3,Color.new(rgb[0],rgb[1],rgb[2],235))
    bmp.set_pixel(3,3,Color.new(255,255,255,255))
    @basic_hit_particle_bitmap_cache_v10522[key]=bmp
    bmp
  rescue
    nil
  end

  IMPORTANT_FOCUS_SKILL_TYPES_V10522 = [
    :mv_thunder,:mv_blizzard,:mv_fire_blast,:mv_hydro_pump,
    :mv_earthquake,:mv_stone_edge,:mv_close_combat,:mv_brave_bird,
    :mv_flare_blitz,:mv_wood_hammer,:mv_leaf_storm,:mv_overheat,
    :mv_focus_blast,:mv_aura_sphere,:mv_dark_pulse,:mv_dragon_pulse,
    :mv_flash_cannon,:mv_explosion,:mv_extreme_speed,:mv_sky_attack,
    :mv_eruption,:mv_water_spout,:mv_future_sight,:mv_meteor_mash
  ]

  FOCUS_SIGNATURE_FAMILY_V10522 = {
    :mv_hydro_pump=>:beam,
    :mv_focus_blast=>:beam,
    :mv_aura_sphere=>:beam,
    :mv_dark_pulse=>:beam,
    :mv_dragon_pulse=>:beam,
    :mv_flash_cannon=>:beam,
    :mv_future_sight=>:rift,
    :mv_stone_edge=>:impact,
    :mv_close_combat=>:impact,
    :mv_brave_bird=>:impact,
    :mv_flare_blitz=>:impact,
    :mv_wood_hammer=>:impact,
    :mv_extreme_speed=>:impact,
    :mv_sky_attack=>:impact,
    :mv_meteor_mash=>:impact,
    :mv_fire_blast=>:burst,
    :mv_leaf_storm=>:burst,
    :mv_overheat=>:burst,
    :mv_explosion=>:burst,
    :mv_earthquake=>:wave,
    :mv_blizzard=>:wave,
    :mv_eruption=>:wave,
    :mv_water_spout=>:wave,
    :mv_thunder=>:column
  }
end

class Scene_PMD_AutoChess
  alias pmd_ac_v10522_focus_begin focus_cast_begin_v1055 unless method_defined?(:pmd_ac_v10522_focus_begin)
  alias pmd_ac_v10522_focus_complete focus_cast_complete_lock_v1055 unless method_defined?(:pmd_ac_v10522_focus_complete)
  alias pmd_ac_v10522_update_effect_sprites update_effect_sprites unless method_defined?(:pmd_ac_v10522_update_effect_sprites)
  alias pmd_ac_v10522_focus_tier focus_tier_v10515 unless method_defined?(:pmd_ac_v10522_focus_tier)
  alias pmd_ac_v10522_semantic_family focus_semantic_family_v10521 unless method_defined?(:pmd_ac_v10522_semantic_family)
  alias pmd_ac_v10522_semantic_update_one focus_semantic_update_one_v10521 unless method_defined?(:pmd_ac_v10522_semantic_update_one)
  alias pmd_ac_v10522_start_battle start_battle unless method_defined?(:pmd_ac_v10522_start_battle)
  alias pmd_ac_v10522_focus_summary focus_cast_log_summary_v1055 unless method_defined?(:pmd_ac_v10522_focus_summary)

  def focus_carryover_transient_v10522?(sp)
    return false if sp==nil
    sp.class.to_s=='Sprite_PMDVFXBurst'
  rescue
    false
  end

  def focus_carryover_sheet_v10522(sp)
    return 'NONE' if sp==nil
    s=sp.instance_variable_get(:@sheet_name)
    s==nil ? sp.class.to_s : s.to_s
  rescue
    'UNKNOWN'
  end

  def focus_carryover_collect_v10522
    rows=[]
    (@effect_sprites || []).each do |sp|
      next if sp==nil || sp.disposed?
      next unless focus_carryover_transient_v10522?(sp)
      rows.push(sp)
    end
    rows
  rescue
    []
  end

  def focus_carryover_remove_v10522(list)
    return 0 if list==nil || list.empty?
    ids={}
    list.each{|sp|ids[sp.object_id]=true if sp!=nil}
    kept=[]
    removed=0
    (@effect_sprites || []).each do |sp|
      if sp!=nil && ids[sp.object_id]
        begin;sp.dispose unless sp.disposed?;rescue;end
        removed+=1
      else
        kept.push(sp)
      end
    end
    @effect_sprites=kept
    removed
  rescue
    0
  end

  def focus_carryover_prepare_v10522(user)
    rows=focus_carryover_collect_v10522
    @focus_carryover_ids_v10522={}
    @focus_carryover_start_v10522=Graphics.frame_count.to_i
    status=(respond_to?(:focus_content_pure_status_v10520?) && focus_content_pure_status_v10520?(user))
    sheets=rows.collect{|sp|focus_carryover_sheet_v10522(sp)}
    if status
      n=focus_carryover_remove_v10522(rows)
      @focus_carryover_status_purge_v10522=@focus_carryover_status_purge_v10522.to_i+n
      # 若上一個 action 還有真正的 logical projectile 在飛，只隱藏 Sprite，
      # 不 dispose / 不 update；Focus 完成後再恢復可見，邏輯命中完全不變。
      @focus_carryover_hidden_projectiles_v10522=[]
      (@projectile_sprites || []).each do |p|
        next if p==nil || p.disposed?
        next unless p.visible
        done=false
        begin;done=p.finished ? true : false;rescue;done=false;end
        next if done
        p.visible=false
        @focus_carryover_hidden_projectiles_v10522.push(p)
      end
      hidden=@focus_carryover_hidden_projectiles_v10522.size
      @focus_carryover_projectiles_hidden_v10522=@focus_carryover_projectiles_hidden_v10522.to_i+hidden
      log_event(:battle,'BATTLE_FOCUS_CARRYOVER_CLEAN_V10522 skill='+
        (user==nil ? 'NONE' : user.instance_variable_get(:@skill_type).to_s)+
        ' mode=status_purge purged='+n.to_i.to_s+' projectile_visuals_hidden='+hidden.to_i.to_s+
        ' sheets=['+sheets.join(',')+']') if n>0 || hidden>0
      return true
    end
    rows.each{|sp|@focus_carryover_ids_v10522[sp.object_id]=true if sp!=nil}
    @focus_carryover_drain_started_v10522=@focus_carryover_drain_started_v10522.to_i+1 if rows.size>0
    true
  rescue
    false
  end

  def focus_cast_begin_v1055(user,target)
    focus_carryover_prepare_v10522(user)
    ok=pmd_ac_v10522_focus_begin(user,target)
    unless ok
      @focus_carryover_ids_v10522={}
    end
    if ok
      key=(user==nil ? nil : user.instance_variable_get(:@skill_type))
      tier=focus_tier_v10515(user)
      if tier==:important && PMD_AC::IMPORTANT_FOCUS_SKILL_TYPES_V10522.include?(key)
        fam=focus_semantic_family_v10521(key,tier)
        @important_library_ii_seen_v10522={} if @important_library_ii_seen_v10522==nil
        @important_library_ii_seen_v10522[key]=fam
        log_event(:battle,'BATTLE_IMPORTANT_LIBRARY_II_V10522 skill='+key.to_s+
          ' tier=important family='+fam.to_s)
      end
    end
    ok
  rescue
    pmd_ac_v10522_focus_begin(user,target)
  end


  def focus_carryover_restore_projectiles_v10522
    rows=@focus_carryover_hidden_projectiles_v10522 || []
    restored=0
    rows.each do |p|
      next if p==nil || p.disposed?
      done=false
      begin;done=p.finished ? true : false;rescue;done=false;end
      next if done
      p.visible=true
      restored+=1
    end
    @focus_carryover_hidden_projectiles_v10522=[]
    @focus_carryover_projectiles_restored_v10522=@focus_carryover_projectiles_restored_v10522.to_i+restored
    log_event(:battle,'BATTLE_FOCUS_CARRYOVER_PROJECTILE_RESTORE_V10522 restored='+restored.to_i.to_s) if restored>0
    restored
  rescue
    @focus_carryover_hidden_projectiles_v10522=[]
    0
  end

  def focus_cast_complete_lock_v1055(reason)
    was_active=(respond_to?(:focus_cast_action_lane_active_v1058?) && focus_cast_action_lane_active_v1058?)
    r=pmd_ac_v10522_focus_complete(reason)
    still_active=(respond_to?(:focus_cast_action_lane_active_v1058?) && focus_cast_action_lane_active_v1058?)
    focus_carryover_restore_projectiles_v10522 if was_active && !still_active
    r
  rescue
    focus_carryover_restore_projectiles_v10522
    pmd_ac_v10522_focus_complete(reason)
  end

  def focus_carryover_drain_intro_v10522
    ids=@focus_carryover_ids_v10522 || {}
    return false if ids.empty?
    age=Graphics.frame_count.to_i-@focus_carryover_start_v10522.to_i
    kept=[]
    finished=0
    forced=0
    (@effect_sprites || []).each do |sp|
      if sp!=nil && ids[sp.object_id] && focus_carryover_transient_v10522?(sp)
        begin
          sp.update unless sp.disposed?
        rescue
        end
        done=false
        begin;done=sp.finished ? true : false;rescue;done=false;end
        if done || age>=PMD_AC::FOCUS_CARRYOVER_DRAIN_MAX_V10522
          forced+=1 if !done
          finished+=1 if done
          begin;sp.dispose unless sp.disposed?;rescue;end
          ids.delete(sp.object_id)
        else
          kept.push(sp)
        end
      else
        kept.push(sp)
      end
    end
    @effect_sprites=kept
    if finished>0 || forced>0
      @focus_carryover_drain_finished_v10522=@focus_carryover_drain_finished_v10522.to_i+finished
      @focus_carryover_drain_forced_v10522=@focus_carryover_drain_forced_v10522.to_i+forced
      log_event(:battle,'BATTLE_FOCUS_CARRYOVER_DRAIN_V10522 finished='+finished.to_i.to_s+
        ' forced='+forced.to_i.to_s+' age='+age.to_i.to_s)
    end
    true
  rescue
    false
  end

  def update_effect_sprites
    if respond_to?(:focus_cast_action_lane_active_v1058?) && focus_cast_action_lane_active_v1058? &&
       @focus_cast_intro_active_v1055
      focus_carryover_drain_intro_v10522
    end
    pmd_ac_v10522_update_effect_sprites
  rescue
    nil
  end

  def focus_tier_v10515(user)
    tier=pmd_ac_v10522_focus_tier(user)
    return tier unless tier==:standard
    key=(user==nil ? nil : user.instance_variable_get(:@skill_type))
    return :important if PMD_AC::IMPORTANT_FOCUS_SKILL_TYPES_V10522.include?(key)
    :standard
  rescue
    pmd_ac_v10522_focus_tier(user)
  end

  def focus_semantic_family_v10521(key,tier)
    fam=PMD_AC::FOCUS_SIGNATURE_FAMILY_V10522[key]
    return fam if fam!=nil
    pmd_ac_v10522_semantic_family(key,tier)
  rescue
    pmd_ac_v10522_semantic_family(key,tier)
  end

  def focus_semantic_update_one_v10521(sp,fam,a,b,ratio,second=false)
    if fam==:wave
      x=b[0]
      y=b[1]+8+(second ? 4 : 0)
      opacity=(225*(1.0-ratio)).to_i
      z=0.45+1.35*ratio
      focus_semantic_place_line_v10521(sp,x,y,0.0,z,0.90,opacity,20030)
      return
    elsif fam==:column
      x=b[0]+(second ? 5 : -2)
      y=b[1]-18
      opacity=(235*(1.0-ratio)).to_i
      z=0.50+0.72*ratio
      focus_semantic_place_line_v10521(sp,x,y,90.0,z,0.82,opacity,20030)
      return
    end
    pmd_ac_v10522_semantic_update_one(sp,fam,a,b,ratio,second)
  rescue
    focus_semantic_hide_one_v10521(sp) if respond_to?(:focus_semantic_hide_one_v10521)
  end

  def focus_carryover_reset_v10522
    @focus_carryover_ids_v10522={}
    @focus_carryover_start_v10522=-1
    @focus_carryover_status_purge_v10522=0
    @focus_carryover_drain_started_v10522=0
    @focus_carryover_drain_finished_v10522=0
    @focus_carryover_drain_forced_v10522=0
    @focus_carryover_hidden_projectiles_v10522=[]
    @focus_carryover_projectiles_hidden_v10522=0
    @focus_carryover_projectiles_restored_v10522=0
    @important_library_ii_seen_v10522={}
  end

  def start_battle
    r=pmd_ac_v10522_start_battle
    focus_carryover_reset_v10522
    if respond_to?(:verification_mode) && verification_mode==:normal
      log_event(:battle,'BATTLE_FOCUS_CARRYOVER_BOUNDARY_V10522 START'+
        ' pure_status_preexisting_vfxburst=purge'+
        ' nonstatus_preexisting_vfxburst=drain'+
        ' drain_max='+PMD_AC::FOCUS_CARRYOVER_DRAIN_MAX_V10522.to_s+
        ' logical_projectile_unchanged=1 status_charge_none_retained=1'+
        ' damage_formula_unchanged=1 hp_unchanged=1 ai_unchanged=1 energy_unchanged=1'+
        ' attack_wait_unchanged=1 spatial_endpoint_unchanged=1 hit_timing_unchanged=1')
      log_event(:battle,'BATTLE_IMPORTANT_LIBRARY_II_V10522 START added='+
        PMD_AC::IMPORTANT_FOCUS_SKILL_TYPES_V10522.size.to_s+
        ' total_with_v10515='+(PMD_AC::IMPORTANT_FOCUS_SKILL_TYPES_V10515.size+
        PMD_AC::IMPORTANT_FOCUS_SKILL_TYPES_V10522.size).to_s+
        ' families=beam,rift,impact,burst,wave,column')
      log_event(:battle,'BATTLE_BASIC_ATTACK_SPARK_V10522 START'+
        ' projectile_scale='+PMD_AC::BASIC_PROJECTILE_SCALE_V10522.to_s+
        ' particles_per_hit='+PMD_AC::BASIC_HIT_PARTICLE_COUNT_V10522.to_s+
        ' particle_frames='+PMD_AC::BASIC_HIT_PARTICLE_FRAMES_V10522.to_s+
        ' fixed_scale=1 evolution_independent=1 large_basic_impact_retired=1'+
        ' damage_unchanged=1 hit_timing_unchanged=1 projectile_logic_unchanged=1')
    end
    r
  end

  def focus_carryover_summary_v10522
    seen=@important_library_ii_seen_v10522 || {}
    fams={}
    seen.each_pair{|k,v|fams[v]=fams[v].to_i+1}
    parts=[]
    [:beam,:rift,:impact,:burst,:wave,:column].each{|k|parts.push(k.to_s+'='+fams[k].to_i.to_s)}
    log_event(:battle,'BATTLE_FOCUS_CARRYOVER_IMPORTANT_LIBRARY_SUMMARY_V10522'+
      ' status_purged='+@focus_carryover_status_purge_v10522.to_i.to_s+
      ' projectile_visuals_hidden='+@focus_carryover_projectiles_hidden_v10522.to_i.to_s+
      ' projectile_visuals_restored='+@focus_carryover_projectiles_restored_v10522.to_i.to_s+
      ' drain_started='+@focus_carryover_drain_started_v10522.to_i.to_s+
      ' drain_finished='+@focus_carryover_drain_finished_v10522.to_i.to_s+
      ' drain_forced='+@focus_carryover_drain_forced_v10522.to_i.to_s+
      ' important_library_seen='+seen.size.to_i.to_s+
      ' families=['+parts.join(',')+']')
    true
  rescue
    false
  end

  def focus_cast_log_summary_v1055
    r=pmd_ac_v10522_focus_summary
    focus_carryover_summary_v10522
    r
  rescue
    false
  end
end

#==============================================================================
# ■ Sprite_PMDBasicHitParticleV10522
#------------------------------------------------------------------------------
# 普攻專用小型屬性光點。只做 Presentation，不持有 gameplay state。
#==============================================================================
class Sprite_PMDBasicHitParticleV10522 < Sprite
  attr_reader :finished

  def initialize(viewport,x,y,style,index)
    super(viewport)
    @origin_x=x.to_f
    @origin_y=y.to_f
    @age=0
    @finished=false
    @frames=PMD_AC::BASIC_HIT_PARTICLE_FRAMES_V10522
    angles=[-35.0,-145.0,145.0,35.0]
    deg=angles[index.to_i % angles.size]
    rad=deg*Math::PI/180.0
    speed=PMD_AC::BASIC_HIT_PARTICLE_SPREAD_V10522.to_f/[[@frames-1,1].max,1].max.to_f
    speed*=1.0+(index.to_i%2)*0.12
    @vx=Math.cos(rad)*speed
    @vy=Math.sin(rad)*speed
    self.bitmap=PMD_AC.basic_hit_particle_bitmap_v10522(style)
    self.ox=3
    self.oy=3
    self.x=@origin_x.to_i
    self.y=@origin_y.to_i
    self.z=9350
    self.blend_type=1
    self.opacity=245
  end

  def update
    super
    return if @finished
    @age+=1
    self.x=(@origin_x+@vx*@age).round
    # 輕微下墜，讓四散不像死板十字線。
    self.y=(@origin_y+@vy*@age+0.035*@age*@age).round
    t=@age.to_f/[[@frames,1].max,1].max.to_f
    self.opacity=PMD_AC.clamp((245*(1.0-t)).round,0,255)
    z=1.0-0.22*t
    self.zoom_x=z
    self.zoom_y=z
    if @age>=@frames
      @finished=true
      self.visible=false
    end
  rescue
    @finished=true
    self.visible=false
  end

  # bitmap 為 PMD_AC shared cache，不由 particle instance dispose。
  def dispose
    self.bitmap=nil
    super
  end
end

#==============================================================================
# ■ Basic ranged projectile：只縮 Presentation 尺度
#==============================================================================
class Sprite_PMDProjectile
  alias pmd_ac_v10522_basic_initialize initialize unless method_defined?(:pmd_ac_v10522_basic_initialize)
  alias pmd_ac_v10522_basic_hit hit unless method_defined?(:pmd_ac_v10522_basic_hit)

  def initialize(*args)
    pmd_ac_v10522_basic_initialize(*args)
    if @kind==:basic
      self.zoom_x=PMD_AC::BASIC_PROJECTILE_SCALE_V10522
      self.zoom_y=PMD_AC::BASIC_PROJECTILE_SCALE_V10522
      @scene.basic_attack_projectile_polish_note_v10522(self) if @scene!=nil &&
        @scene.respond_to?(:basic_attack_projectile_polish_note_v10522)
    end
  end

  def hit(x,y)
    if @kind==:basic && @scene!=nil && @scene.respond_to?(:basic_attack_visual_context_begin_v10522)
      @scene.basic_attack_visual_context_begin_v10522(@style,:ranged)
      begin
        return pmd_ac_v10522_basic_hit(x,y)
      ensure
        @scene.basic_attack_visual_context_end_v10522 if @scene.respond_to?(:basic_attack_visual_context_end_v10522)
      end
    end
    pmd_ac_v10522_basic_hit(x,y)
  end
end

#==============================================================================
# ■ Melee basic：沿用既有 Damage / Motion，只替換命中 Presentation
#==============================================================================
class Game_PMDChessUnit
  alias pmd_ac_v10522_basic_resolve resolve_basic_attack unless method_defined?(:pmd_ac_v10522_basic_resolve)

  def resolve_basic_attack
    scene=@scene
    packet=@basic_attack_packet_v09912
    style=nil
    if packet!=nil
      style=packet[:move_type]
    elsif respond_to?(:pokemon_types)
      arr=pokemon_types
      style=arr[0] if arr!=nil && !arr.empty?
    end
    if scene!=nil && scene.respond_to?(:basic_attack_visual_context_begin_v10522)
      scene.basic_attack_visual_context_begin_v10522(style || :normal,:basic_resolve)
      begin
        return pmd_ac_v10522_basic_resolve
      ensure
        scene.basic_attack_visual_context_end_v10522 if scene.respond_to?(:basic_attack_visual_context_end_v10522)
      end
    end
    pmd_ac_v10522_basic_resolve
  end
end

class Scene_PMD_AutoChess
  alias pmd_ac_v10522_basic_add_vfx_impact add_vfx_impact unless method_defined?(:pmd_ac_v10522_basic_add_vfx_impact)
  alias pmd_ac_v10522_basic_add_vfx_impact_xy add_vfx_impact_xy unless method_defined?(:pmd_ac_v10522_basic_add_vfx_impact_xy)

  def basic_attack_visual_context_begin_v10522(style,source=nil)
    @basic_attack_visual_context_v10522={:style=>(style || :normal),:source=>source}
    true
  rescue
    false
  end

  def basic_attack_visual_context_end_v10522
    @basic_attack_visual_context_v10522=nil
    true
  rescue
    false
  end

  def basic_attack_particle_style_v10522(style)
    key=style || :normal
    return :grass if key==:seed
    return :bug if key==:web
    return :normal if [:impact,:neutral].include?(key)
    key
  rescue
    :normal
  end

  def add_basic_hit_sparks_v10522(x,y,style)
    return false if @effect_sprites==nil
    key=basic_attack_particle_style_v10522(style)
    count=PMD_AC::BASIC_HIT_PARTICLE_COUNT_V10522
    i=0
    while i<count
      @effect_sprites.push(Sprite_PMDBasicHitParticleV10522.new(@viewport,x,y,key,i))
      i+=1
    end
    @basic_hit_spark_events_v10522=@basic_hit_spark_events_v10522.to_i+1
    @basic_hit_spark_particles_v10522=@basic_hit_spark_particles_v10522.to_i+count
    log_event(:battle,'BATTLE_BASIC_HIT_SPARK_V10522 style='+key.to_s+
      ' particles='+count.to_s+' fixed_scale=1 evolution_independent=1')
    true
  rescue
    false
  end

  def add_vfx_impact(obj,style,delay=0)
    ctx=@basic_attack_visual_context_v10522
    # melee basic 的舊命中固定是 :impact；只吃這一個 call，
    # 避免同步觸發的 reactive ability VFX 被 basic context 誤攔。
    if ctx!=nil && ctx[:source]==:basic_resolve && style==:impact && obj!=nil && delay.to_i<=0
      @basic_attack_visual_context_v10522=nil
      x,y=effect_anchor_xy(obj,false)
      add_basic_hit_sparks_v10522(x,y,ctx[:style] || :normal)
      return
    end
    pmd_ac_v10522_basic_add_vfx_impact(obj,style,delay)
  end

  def add_vfx_impact_xy(x,y,style,delay=0)
    ctx=@basic_attack_visual_context_v10522
    # ranged projectile 的 base hit 會先呼叫一次 add_vfx_impact_xy，再 resolve damage。
    # 在這一刻 consume context，後面的 reactive VFX 不受影響。
    if ctx!=nil && ctx[:source]==:ranged && delay.to_i<=0
      @basic_attack_visual_context_v10522=nil
      add_basic_hit_sparks_v10522(x,y,ctx[:style] || style)
      return
    end
    pmd_ac_v10522_basic_add_vfx_impact_xy(x,y,style,delay)
  end

  def basic_attack_projectile_polish_note_v10522(projectile)
    @basic_projectile_scaled_v10522=@basic_projectile_scaled_v10522.to_i+1
    if @basic_projectile_scaled_v10522<=4
      log_event(:battle,'BATTLE_BASIC_PROJECTILE_SCALE_V10522 style='+projectile.style.to_s+
        ' scale='+PMD_AC::BASIC_PROJECTILE_SCALE_V10522.to_s+
        ' logical_radius_unchanged=1 speed_unchanged=1 tracking_unchanged=1')
    end
    true
  rescue
    false
  end

  # v1.05.22 的新 basic spark 也是短命 carryover，Focus boundary 必須認得它。
  alias pmd_ac_v10522_basic_focus_transient focus_carryover_transient_v10522? unless method_defined?(:pmd_ac_v10522_basic_focus_transient)
  def focus_carryover_transient_v10522?(sp)
    return true if sp!=nil && sp.class.to_s=='Sprite_PMDBasicHitParticleV10522'
    return true if sp!=nil && sp.class.to_s=='Sprite_PMDSkillImpactV030'
    return true if sp!=nil && sp.class.to_s=='Sprite_PMDChessEffect'
    pmd_ac_v10522_basic_focus_transient(sp)
  rescue
    false
  end

  alias pmd_ac_v10522_basic_reset focus_carryover_reset_v10522 unless method_defined?(:pmd_ac_v10522_basic_reset)
  def focus_carryover_reset_v10522
    pmd_ac_v10522_basic_reset
    @basic_attack_visual_context_v10522=nil
    @basic_projectile_scaled_v10522=0
    @basic_hit_spark_events_v10522=0
    @basic_hit_spark_particles_v10522=0
  end

  alias pmd_ac_v10522_basic_summary focus_carryover_summary_v10522 unless method_defined?(:pmd_ac_v10522_basic_summary)
  def focus_carryover_summary_v10522
    r=pmd_ac_v10522_basic_summary
    log_event(:battle,'BATTLE_BASIC_ATTACK_SPARK_SUMMARY_V10522'+
      ' projectiles_scaled='+@basic_projectile_scaled_v10522.to_i.to_s+
      ' hit_events='+@basic_hit_spark_events_v10522.to_i.to_s+
      ' particles='+@basic_hit_spark_particles_v10522.to_i.to_s+
      ' projectile_scale='+PMD_AC::BASIC_PROJECTILE_SCALE_V10522.to_s+
      ' particles_per_hit='+PMD_AC::BASIC_HIT_PARTICLE_COUNT_V10522.to_s+
      ' evolution_independent=1 large_basic_impact_retired=1')
    r
  rescue
    false
  end
end
