# encoding: UTF-8
#===============================================================================
# ■ PMD AutoChess - Status Impact Allowlist + Basic Attack Target Spark + Important Library III v1.05.23
#===============================================================================
# 【用途】
# 1. 修正 v1.05.22a 實機影片中 Growl（叫聲）結果套用時，目標身上仍短暫播放
#    完整橘色火球動畫的問題。
# 2. 影片逐格與專案資產交叉比對後，該動畫外觀可對應 PMD Skill Impact 的
#    fire sheet「Ranger_222」。它不是 v1.05.20 的 Focus orbit，也不是 v1.05.17
#    已封鎖的 cast muzzle，更不是單純上一招 freeze carryover。
# 3. 建立 Pure Status Impact Allowlist：純狀態技能 Focus 存續期間，任何舊式
#    SkillImpact / PMD VFX Burst 都不得進入可見 Presentation；僅保留技能名稱、
#    Focus 暗場、target mark、結果文字、紅／藍能力光圈與必要狀態提示。
# 4. 延續使用者指定的普通攻擊視覺方向：遠程 basic 的 logical projectile 仍完整
#    運算，但 projectile Sprite 改為完全隱藏；命中只在目標位置顯示小型屬性光點四散。
#    同時縮小光點本體，避免初始型寶可夢的普攻看起來像必殺技。
# 5. Important Skill Library III 再擴充 16 招，沿用已 Windows PASS 的 Important 60f、
#    Boss 72f Authority 與既有 beam / rift / impact / burst / wave / column family。
#
# 【根因與機制】
# - v1.05.21 已證明 Growl：charge=none、cast muzzle suppressed、Native Motion sealed。
# - v1.05.22a 影片中火球是在「-攻擊」與藍色 stat ring 出現的同一時間生成，
#   外觀與 Graphics/Pictures/PMD_SkillFX/Ranger_222.png 一致。
# - 因此本版不再只依賴 v1.05.16 的 apply context flag，而是使用「整個 pure-status
#   Focus 生命週期」作為 Presentation Authority。只要 owner 仍是 pure status，
#   add_vfx_impact / add_vfx_impact_xy 直接拒絕，update_effect_sprites 另有第二層 purge，
#   防止舊腳本繞過 helper 直接塞入 Sprite_PMDSkillImpactV030。
#
# 【Pure Status Allowlist】
# 保留：
# - Focus 暗場／技能名稱／target shadow mark
# - Result Feedback 文字（-攻擊、-速度、+睡眠…）
# - v1.05.14 紅／藍多光圈
# - KO / Result Hold / Skill SE
# 禁止：
# - Sprite_PMDSkillImpactV030（含 Ranger_222 fire impact）
# - Sprite_PMDVFXBurst 舊式 burst
# - Sprite_PMDBasicHitParticleV10522 若它是前一個 basic 的殘留
# - pure-status Focus 期間任何 add_vfx_impact / add_vfx_impact_xy
#
# 【普通攻擊視覺】
# - ranged basic logical projectile：保留速度、追蹤、collision、hit timing，但 Sprite.visible=false。
# - melee / ranged basic 命中：沿用 v1.05.22 4 顆 type-colored particle。
# - particle bitmap 維持 7x7 邊界以相容既有 ox/oy，但實際可見像素縮為 3x3 halo + 1px core。
# - 不依 species stage / evolution / Sprite 尺寸放大。
#
# 【Important Library III 新增 16 招】
# Flamethrower / Thunderbolt / Ice Beam / Psychic / Shadow Ball / Energy Ball /
# Sludge Bomb / Power Gem / Air Slash / Bug Buzz / Iron Tail / Leaf Blade /
# Waterfall / Heat Wave / Hurricane / Crunch。
# 僅新增 Presentation tier/family，不改招式威力、AI、Energy、命中、Priority、Spatial。
#
# 【可調參數】
# STATUS_IMPACT_ALLOWLIST_V10523
#   true：啟用 pure-status 全生命週期 impact/burst 封鎖。
# BASIC_PROJECTILE_TARGET_ONLY_V10523
#   true：basic ranged projectile 只保留 logical object，不顯示飛行 Sprite。
# BASIC_HIT_PARTICLE_HALO_ALPHA_V10523
#   普攻命中小光點外圈透明度。
#
# 【依賴／載入順序】
# - 必須載於 v1.05.22 / v1.05.22a 後、Main 前。
# - 依賴 v1.05.16 status_semantic_pure_v10516?、v1.05.17 status_vfx_seal_pure_v10517?、
#   v1.05.20 pure-status Focus、v1.05.22 basic spark。
# - 不直接修改 Frozen Motion Core。
#
# 【事件／腳本呼叫方式】
# - 無需事件呼叫。NORMAL 戰鬥自動生效。
# - F6 Important/Boss fixture 仍沿用 v1.05.19，不新增測試模式。
#
# 【實際範例】
# 1. 小火龍使用叫聲：不出現 Ranger_222 火球，只顯示 -攻擊與藍色下降多光圈。
# 2. 傑尼龜 ranged basic：看不到大型水球飛行；命中時目標身上出現 4 顆小型水色光點四散。
# 3. 噴火龍 ranged basic：與小火龍相同固定尺度，不因進化把 basic VFX 放大。
# 4. Flamethrower 進 Important tier 時沿用 beam family；戰鬥邏輯完全不變。
#===============================================================================
$imported={} unless defined?($imported)
$imported['PMD_AutoChess_StatusImpactAllowlist_BasicAttackTargetSpark_ImportantLibraryIII_v10523']=true

module PMD_AC
  STATUS_IMPACT_ALLOWLIST_V10523 = true
  BASIC_PROJECTILE_TARGET_ONLY_V10523 = true
  BASIC_HIT_PARTICLE_HALO_ALPHA_V10523 = 66

  IMPORTANT_FOCUS_SKILL_TYPES_V10523 = [
    :mv_flamethrower,:mv_thunderbolt,:mv_ice_beam,:mv_psychic,
    :mv_shadow_ball,:mv_energy_ball,:mv_sludge_bomb,:mv_power_gem,
    :mv_air_slash,:mv_bug_buzz,:mv_iron_tail,:mv_leaf_blade,
    :mv_waterfall,:mv_heat_wave,:mv_hurricane,:mv_crunch
  ]

  FOCUS_SIGNATURE_FAMILY_V10523 = {
    :mv_flamethrower=>:beam,
    :mv_thunderbolt=>:beam,
    :mv_ice_beam=>:beam,
    :mv_psychic=>:rift,
    :mv_shadow_ball=>:burst,
    :mv_energy_ball=>:burst,
    :mv_sludge_bomb=>:burst,
    :mv_power_gem=>:burst,
    :mv_air_slash=>:wave,
    :mv_bug_buzz=>:wave,
    :mv_iron_tail=>:impact,
    :mv_leaf_blade=>:impact,
    :mv_waterfall=>:impact,
    :mv_heat_wave=>:wave,
    :mv_hurricane=>:wave,
    :mv_crunch=>:impact
  }

  class << self
    alias pmd_ac_v10523_basic_particle_bitmap basic_hit_particle_bitmap_v10522 unless method_defined?(:pmd_ac_v10523_basic_particle_bitmap)

    # 仍回傳 7x7，避免改動 Sprite_PMDBasicHitParticleV10522 的 ox/oy；
    # 只縮小實際畫出的可見像素。
    def basic_hit_particle_bitmap_v10522(style)
      @basic_hit_particle_bitmap_cache_v10522={} if @basic_hit_particle_bitmap_cache_v10522==nil
      key=style || :normal
      bmp=@basic_hit_particle_bitmap_cache_v10522[key]
      if bmp!=nil && !bmp.disposed?
        # v1.05.22 舊 cache 可能已建立 5x5 halo；重畫一次成 v1.05.23 小型版本。
        mark=bmp.instance_variable_get(:@pmd_v10523_small)
        return bmp if mark
      end
      rgb=basic_hit_rgb_v10522(key)
      bmp=Bitmap.new(7,7) if bmp==nil || bmp.disposed?
      bmp.clear
      a=BASIC_HIT_PARTICLE_HALO_ALPHA_V10523
      bmp.fill_rect(2,2,3,3,Color.new(rgb[0],rgb[1],rgb[2],a))
      bmp.set_pixel(3,3,Color.new(255,255,255,245))
      bmp.instance_variable_set(:@pmd_v10523_small,true)
      @basic_hit_particle_bitmap_cache_v10522[key]=bmp
      bmp
    rescue
      pmd_ac_v10523_basic_particle_bitmap(style)
    end
  end
end

#==============================================================================
# ■ Basic ranged projectile visual
#------------------------------------------------------------------------------
# logical projectile 照常存在並更新，只隱藏 Sprite。
#==============================================================================
class Sprite_PMDProjectile
  alias pmd_ac_v10523_basic_initialize initialize unless method_defined?(:pmd_ac_v10523_basic_initialize)

  def initialize(*args)
    pmd_ac_v10523_basic_initialize(*args)
    begin
      if PMD_AC::BASIC_PROJECTILE_TARGET_ONLY_V10523 && @kind==:basic
        self.visible=false
        @pmd_basic_target_only_v10523=true
        if @scene!=nil && @scene.respond_to?(:basic_projectile_target_only_note_v10523)
          @scene.basic_projectile_target_only_note_v10523(self)
        end
      end
    rescue
    end
  end
end

class Scene_PMD_AutoChess
  alias pmd_ac_v10523_add_vfx_impact add_vfx_impact unless method_defined?(:pmd_ac_v10523_add_vfx_impact)
  alias pmd_ac_v10523_add_vfx_impact_xy add_vfx_impact_xy unless method_defined?(:pmd_ac_v10523_add_vfx_impact_xy)
  alias pmd_ac_v10523_update_effect_sprites update_effect_sprites unless method_defined?(:pmd_ac_v10523_update_effect_sprites)
  alias pmd_ac_v10523_focus_tier focus_tier_v10515 unless method_defined?(:pmd_ac_v10523_focus_tier)
  alias pmd_ac_v10523_semantic_family focus_semantic_family_v10521 unless method_defined?(:pmd_ac_v10523_semantic_family)
  alias pmd_ac_v10523_start_battle start_battle unless method_defined?(:pmd_ac_v10523_start_battle)
  alias pmd_ac_v10523_focus_summary focus_cast_log_summary_v1055 unless method_defined?(:pmd_ac_v10523_focus_summary)

  def status_impact_owner_key_v10523
    u=@focus_cast_owner_v1055
    return nil if u==nil
    u.instance_variable_get(:@skill_type)
  rescue
    nil
  end

  def pure_status_focus_active_v10523?
    return false unless PMD_AC::STATUS_IMPACT_ALLOWLIST_V10523
    active=false
    if respond_to?(:focus_cast_action_lane_active_v1058?)
      active=focus_cast_action_lane_active_v1058? ? true : false
    else
      active=@focus_cast_owner_v1055!=nil
    end
    return false unless active
    key=status_impact_owner_key_v10523
    return false if key==nil
    if respond_to?(:status_vfx_seal_pure_v10517?)
      return status_vfx_seal_pure_v10517?(key) ? true : false
    end
    if respond_to?(:status_semantic_pure_v10516?)
      return status_semantic_pure_v10516?(key) ? true : false
    end
    false
  rescue
    false
  end

  def status_impact_block_note_v10523(kind,style=nil)
    @status_impact_blocked_v10523=@status_impact_blocked_v10523.to_i+1
    key=status_impact_owner_key_v10523
    if @status_impact_blocked_v10523<=12
      log_event(:battle,'BATTLE_STATUS_IMPACT_ALLOWLIST_V10523 skill='+(key==nil ? 'NONE' : key.to_s)+
        ' blocked='+kind.to_s+' style='+(style==nil ? 'NONE' : style.to_s))
    end
    true
  rescue
    false
  end

  # 第一層：阻止所有 helper-based impact。
  def add_vfx_impact(obj,style,delay=0)
    if pure_status_focus_active_v10523?
      status_impact_block_note_v10523(:impact,style)
      return nil
    end
    pmd_ac_v10523_add_vfx_impact(obj,style,delay)
  end

  def add_vfx_impact_xy(x,y,style,delay=0)
    if pure_status_focus_active_v10523?
      status_impact_block_note_v10523(:impact_xy,style)
      return nil
    end
    pmd_ac_v10523_add_vfx_impact_xy(x,y,style,delay)
  end

  def status_forbidden_effect_sprite_v10523?(sp)
    return false if sp==nil
    n=sp.class.to_s
    return true if n=='Sprite_PMDSkillImpactV030'
    return true if n=='Sprite_PMDVFXBurst'
    return true if n=='Sprite_PMDBasicHitParticleV10522'
    false
  rescue
    false
  end

  # 第二層：防舊腳本直接 new Sprite_PMDSkillImpactV030 後塞入 @effect_sprites。
  def purge_pure_status_forbidden_effects_v10523
    return 0 unless pure_status_focus_active_v10523?
    list=@effect_sprites || []
    kept=[]
    removed=0
    sheets=[]
    list.each do |sp|
      if sp!=nil && !sp.disposed? && status_forbidden_effect_sprite_v10523?(sp)
        name=sp.class.to_s
        begin
          s=sp.instance_variable_get(:@style)
          name += ':'+s.to_s if s!=nil
        rescue
        end
        sheets.push(name) if sheets.size<6
        begin;sp.dispose unless sp.disposed?;rescue;end
        removed+=1
      else
        kept.push(sp)
      end
    end
    if removed>0
      @effect_sprites=kept
      @status_impact_purged_v10523=@status_impact_purged_v10523.to_i+removed
      key=status_impact_owner_key_v10523
      log_event(:battle,'BATTLE_STATUS_IMPACT_PURGE_V10523 skill='+(key==nil ? 'NONE' : key.to_s)+
        ' removed='+removed.to_s+' classes=['+sheets.join(',')+']')
    end
    removed
  rescue
    0
  end

  def update_effect_sprites
    # parent 前後各 purge 一次：前者清 carryover，後者抓 parent 本幀新生成的漏網 Sprite。
    purge_pure_status_forbidden_effects_v10523
    r=pmd_ac_v10523_update_effect_sprites
    purge_pure_status_forbidden_effects_v10523
    r
  end

  def basic_projectile_target_only_note_v10523(projectile)
    @basic_projectile_hidden_v10523=@basic_projectile_hidden_v10523.to_i+1
    if @basic_projectile_hidden_v10523<=4
      style=nil
      begin;style=projectile.style;rescue;style=nil;end
      log_event(:battle,'BATTLE_BASIC_PROJECTILE_TARGET_ONLY_V10523 style='+(style==nil ? 'NONE' : style.to_s)+
        ' sprite_hidden=1 logical_projectile_retained=1')
    end
    true
  rescue
    false
  end

  def focus_tier_v10515(user)
    tier=pmd_ac_v10523_focus_tier(user)
    return tier unless tier==:standard
    key=(user==nil ? nil : user.instance_variable_get(:@skill_type))
    return :important if PMD_AC::IMPORTANT_FOCUS_SKILL_TYPES_V10523.include?(key)
    :standard
  rescue
    pmd_ac_v10523_focus_tier(user)
  end

  def focus_semantic_family_v10521(key,tier)
    fam=PMD_AC::FOCUS_SIGNATURE_FAMILY_V10523[key]
    return fam if fam!=nil
    pmd_ac_v10523_semantic_family(key,tier)
  rescue
    pmd_ac_v10523_semantic_family(key,tier)
  end

  def status_impact_reset_v10523
    @status_impact_blocked_v10523=0
    @status_impact_purged_v10523=0
    @basic_projectile_hidden_v10523=0
  end

  def start_battle
    r=pmd_ac_v10523_start_battle
    status_impact_reset_v10523
    if respond_to?(:verification_mode) && verification_mode==:normal
      log_event(:battle,'BATTLE_STATUS_IMPACT_ALLOWLIST_V10523 START'+
        ' pure_status_impact=blocked pure_status_impact_xy=blocked'+
        ' forbidden_sprites=SkillImpactV030,VFXBurst,BasicHitParticle'+
        ' result_text_retained=1 stat_ring_retained=1 target_mark_retained=1'+
        ' ranger_222_guard=1 damage_formula_unchanged=1 hp_unchanged=1 ai_unchanged=1'+
        ' energy_unchanged=1 attack_wait_unchanged=1 spatial_endpoint_unchanged=1 hit_timing_unchanged=1')
      log_event(:battle,'BATTLE_BASIC_ATTACK_TARGET_SPARK_V10523 START'+
        ' ranged_projectile_sprite=hidden logical_projectile_retained=1'+
        ' hit_particles=4 particle_visible_core=small evolution_independent=1'+
        ' damage_unchanged=1 collision_unchanged=1 speed_unchanged=1 tracking_unchanged=1')
      total=PMD_AC::IMPORTANT_FOCUS_SKILL_TYPES_V10515.size+
        PMD_AC::IMPORTANT_FOCUS_SKILL_TYPES_V10522.size+
        PMD_AC::IMPORTANT_FOCUS_SKILL_TYPES_V10523.size
      log_event(:battle,'BATTLE_IMPORTANT_LIBRARY_III_V10523 START added='+
        PMD_AC::IMPORTANT_FOCUS_SKILL_TYPES_V10523.size.to_s+' total='+total.to_s+
        ' families=beam,rift,impact,burst,wave')
    end
    r
  end

  def focus_cast_log_summary_v1055
    r=pmd_ac_v10523_focus_summary
    log_event(:battle,'BATTLE_STATUS_IMPACT_ALLOWLIST_SUMMARY_V10523'+
      ' blocked='+@status_impact_blocked_v10523.to_i.to_s+
      ' purged='+@status_impact_purged_v10523.to_i.to_s+
      ' basic_projectile_sprites_hidden='+@basic_projectile_hidden_v10523.to_i.to_s+
      ' ranger_222_guard=1 target_only_basic=1 important_library_iii=16')
    r
  rescue
    false
  end
end
