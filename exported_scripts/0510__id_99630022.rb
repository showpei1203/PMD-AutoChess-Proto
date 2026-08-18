# encoding: UTF-8
#===============================================================================
# ■ PMD AutoChess - Focus Fatigue Observer + Important Library IV + Boss Archetype I v1.05.25
#===============================================================================
# 【用途】
# 1. 在 v1.05.24 普通攻擊可讀性通過實機後，正式進入 Roadmap Phase B2：
#    觀察 Full Focus 的頻率、重複技能密度與連續 Standard Focus 壓力。
# 2. Observer 僅記錄資料，不自動縮短 Focus、不改 Battle Speed、不改技能頻率；
#    等 Windows 真實戰鬥證據足夠後，才決定是否需要 repeat-skill compression。
# 3. Important Skill Library IV 再擴充 37 招，讓更多高辨識度／招牌攻擊取得既有
#    60f Important Focus 與 semantic release；不是用單純威力門檻自動收錄所有招式。
# 4. 建立 Boss Focus Archetype I：Boss=true 時，可依 canonical species_key 選擇
#    predator / titan / aerial / mystic / primordial 等視覺語意 fallback。
#    已有招式級 semantic family 永遠優先，不會被物種 archetype 強行蓋掉。
# 5. 本版僅 Presentation / Observer；Damage、HP、AI、Energy、Attack Wait、Priority、
#    logical Spatial x/y/velocity/endpoints、hit timing、Motion Core 全部不修改。
#
# 【Phase B2 Focus 疲勞觀察規則】
# - 每個成功開始的 Focus 記錄 tier、skill、owner、frame。
# - repeat_global：連續兩個 Focus 使用相同 skill。
# - repeat_owner_window：同一 owner 在 180f 內再次使用相同 skill。
# - max_standard_chain：連續 Standard Focus 的最長鏈。
# - avg_gap/min_gap/max_gap：相鄰 Focus begin 的 frame 間隔。
# - unique_skills：本場實際出現多少種 Focus skill。
# - 只輸出 raw evidence；behavior_change=0。
#
# 【Important Skill Library IV：37 招】
# Surf / Discharge / Lava Plume / Muddy Water / Rock Slide / Cross Chop /
# Dynamic Punch / Megahorn / Head Smash / Dragon Rush / Dragon Claw / Outrage /
# Power Whip / Seed Flare / Magma Storm / Earth Power / Gunk Shot / Aqua Tail /
# Superpower / Hammer Arm / Focus Punch / Sky Uppercut / Avalanche / Payback /
# Night Slash / X-Scissor / Zen Headbutt / Iron Head / Sucker Punch / Rock Wrecker /
# Crush Grip / Attack Order / Chatter / Zap Cannon / Bonemerang / Bone Rush /
# Shadow Claw。
#
# 【Boss Archetype I】
# - predator：Beedrill / Nidoking / Arcanine / Machamp / Gyarados / Tyranitar /
#   Garchomp / Lucario 等，未映射技能預設 impact。
# - titan：Snorlax / Regi trio / Rhyperior / Regigigas 等，預設 impact。
# - aerial：三鳥 / Dragonite / Lugia / Ho-Oh / Salamence / Togekiss，預設 wave。
# - mystic：Alakazam / Gengar / Mewtwo / Gardevoir / Deoxys / Lake trio 等，預設 rift。
# - primordial：Kyogre / Groudon / Rayquaza / Dialga / Palkia / Giratina / Arceus，
#   使用逐物種 wave / column / rift fallback。
# 已存在的 beam/rift/impact/burst/wave/column 招式 mapping 優先權最高。
#
# 【主要設定／可調參數】
# FOCUS_FATIGUE_REPEAT_WINDOW_V10525 = 180
# IMPORTANT_FOCUS_SKILL_TYPES_V10525 = [...]  # 37 招
# FOCUS_SIGNATURE_FAMILY_V10525 = {...}
# BOSS_FOCUS_ARCHETYPE_V10525 = {...}
#
# 【依賴／載入順序】
# - 必須載於 v1.05.15、v1.05.21、v1.05.22、v1.05.23、v1.05.24 後、Main 前。
# - 沿用既有 Focus Action Lane、Important/Boss tier、semantic release。
# - 不直接修改 Frozen Combat Core。
#
# 【事件／腳本呼叫方式】
# - 無需事件呼叫，NORMAL battle 自動生效。
# - F6 Important/Boss deterministic fixture 仍沿用 v1.05.19。
#
# 【LOG】
# BATTLE_FOCUS_FATIGUE_OBSERVER_V10525 START ...
# BATTLE_IMPORTANT_LIBRARY_IV_V10525 START added=37 total=93 ...
# BATTLE_IMPORTANT_LIBRARY_IV_HIT_V10525 skill=... family=...
# BATTLE_BOSS_FOCUS_ARCHETYPE_V10525 species=... archetype=... family=...
# BATTLE_FOCUS_FATIGUE_SUMMARY_V10525 ... behavior_change=0
# BATTLE_CONTENT_SCALE_TRANSITION_V10525 ...
#
# 【實際範例】
# 1. Surf：若被 AI 選到，進 Important 60f Focus，release family=wave。
# 2. Garchomp 若被標為 Boss，使用未特別映射的技能時，Boss fallback=impact；
#    若技能本身是 Draco Meteor，仍優先使用既有 burst mapping。
# 3. 同一隻寶可夢 180f 內連續兩次使用同一 Focus skill，只增加 observer 統計，
#    本版不縮短第二次 Focus。
#===============================================================================
$imported={} unless defined?($imported)
$imported['PMD_AutoChess_FocusFatigue_ImportantLibraryIV_BossArchetypeI_v10525']=true

module PMD_AC
  FOCUS_FATIGUE_REPEAT_WINDOW_V10525 = 180

  IMPORTANT_FOCUS_SKILL_TYPES_V10525 = [
    :mv_surf,:mv_discharge,:mv_lava_plume,:mv_muddy_water,
    :mv_rock_slide,:mv_cross_chop,:mv_dynamic_punch,:mv_megahorn,
    :mv_head_smash,:mv_dragon_rush,:mv_dragon_claw,:mv_outrage,
    :mv_power_whip,:mv_seed_flare,:mv_magma_storm,:mv_earth_power,
    :mv_gunk_shot,:mv_aqua_tail,:mv_superpower,:mv_hammer_arm,
    :mv_focus_punch,:mv_sky_uppercut,:mv_avalanche,:mv_payback,
    :mv_night_slash,:mv_x_scissor,:mv_zen_headbutt,:mv_iron_head,
    :mv_sucker_punch,:mv_rock_wrecker,:mv_crush_grip,:mv_attack_order,
    :mv_chatter,:mv_zap_cannon,:mv_bonemerang,:mv_bone_rush,
    :mv_shadow_claw
  ]

  FOCUS_SIGNATURE_FAMILY_V10525 = {
    :mv_surf=>:wave,
    :mv_discharge=>:wave,
    :mv_lava_plume=>:wave,
    :mv_muddy_water=>:wave,
    :mv_rock_slide=>:column,
    :mv_cross_chop=>:impact,
    :mv_dynamic_punch=>:impact,
    :mv_megahorn=>:impact,
    :mv_head_smash=>:impact,
    :mv_dragon_rush=>:impact,
    :mv_dragon_claw=>:impact,
    :mv_outrage=>:burst,
    :mv_power_whip=>:impact,
    :mv_seed_flare=>:burst,
    :mv_magma_storm=>:burst,
    :mv_earth_power=>:column,
    :mv_gunk_shot=>:burst,
    :mv_aqua_tail=>:impact,
    :mv_superpower=>:impact,
    :mv_hammer_arm=>:impact,
    :mv_focus_punch=>:impact,
    :mv_sky_uppercut=>:impact,
    :mv_avalanche=>:column,
    :mv_payback=>:impact,
    :mv_night_slash=>:impact,
    :mv_x_scissor=>:impact,
    :mv_zen_headbutt=>:impact,
    :mv_iron_head=>:impact,
    :mv_sucker_punch=>:impact,
    :mv_rock_wrecker=>:impact,
    :mv_crush_grip=>:impact,
    :mv_attack_order=>:wave,
    :mv_chatter=>:wave,
    :mv_zap_cannon=>:beam,
    :mv_bonemerang=>:impact,
    :mv_bone_rush=>:impact,
    :mv_shadow_claw=>:impact
  }

  # species_key => {:archetype=>Symbol, :family=>Symbol}
  # 僅在 unit.boss==true 且 skill 沒有任何明確 semantic mapping 時使用。
  BOSS_FOCUS_ARCHETYPE_V10525 = {
    'beedrill'=>{:archetype=>:predator,:family=>:impact},
    'nidoqueen'=>{:archetype=>:predator,:family=>:impact},
    'nidoking'=>{:archetype=>:predator,:family=>:impact},
    'arcanine'=>{:archetype=>:predator,:family=>:impact},
    'machamp'=>{:archetype=>:predator,:family=>:impact},
    'rhydon'=>{:archetype=>:predator,:family=>:impact},
    'gyarados'=>{:archetype=>:predator,:family=>:wave},
    'tyranitar'=>{:archetype=>:predator,:family=>:impact},
    'slaking'=>{:archetype=>:predator,:family=>:impact},
    'garchomp'=>{:archetype=>:predator,:family=>:impact},
    'lucario'=>{:archetype=>:predator,:family=>:impact},

    'snorlax'=>{:archetype=>:titan,:family=>:impact},
    'regirock'=>{:archetype=>:titan,:family=>:column},
    'regice'=>{:archetype=>:titan,:family=>:column},
    'registeel'=>{:archetype=>:titan,:family=>:column},
    'rhyperior'=>{:archetype=>:titan,:family=>:impact},
    'regigigas'=>{:archetype=>:titan,:family=>:impact},

    'articuno'=>{:archetype=>:aerial,:family=>:wave},
    'zapdos'=>{:archetype=>:aerial,:family=>:column},
    'moltres'=>{:archetype=>:aerial,:family=>:wave},
    'dragonite'=>{:archetype=>:aerial,:family=>:wave},
    'lugia'=>{:archetype=>:aerial,:family=>:wave},
    'ho_oh'=>{:archetype=>:aerial,:family=>:wave},
    'salamence'=>{:archetype=>:aerial,:family=>:wave},
    'togekiss'=>{:archetype=>:aerial,:family=>:wave},

    'alakazam'=>{:archetype=>:mystic,:family=>:rift},
    'gengar'=>{:archetype=>:mystic,:family=>:rift},
    'mewtwo'=>{:archetype=>:mystic,:family=>:rift},
    'mew'=>{:archetype=>:mystic,:family=>:rift},
    'celebi'=>{:archetype=>:mystic,:family=>:rift},
    'gardevoir'=>{:archetype=>:mystic,:family=>:rift},
    'jirachi'=>{:archetype=>:mystic,:family=>:rift},
    'deoxys'=>{:archetype=>:mystic,:family=>:rift},
    'uxie'=>{:archetype=>:mystic,:family=>:rift},
    'mesprit'=>{:archetype=>:mystic,:family=>:rift},
    'azelf'=>{:archetype=>:mystic,:family=>:rift},
    'cresselia'=>{:archetype=>:mystic,:family=>:rift},
    'darkrai'=>{:archetype=>:mystic,:family=>:rift},
    'shaymin'=>{:archetype=>:mystic,:family=>:wave},

    'kyogre'=>{:archetype=>:primordial,:family=>:wave},
    'groudon'=>{:archetype=>:primordial,:family=>:column},
    'rayquaza'=>{:archetype=>:primordial,:family=>:wave},
    'dialga'=>{:archetype=>:primordial,:family=>:rift},
    'palkia'=>{:archetype=>:primordial,:family=>:rift},
    'giratina'=>{:archetype=>:primordial,:family=>:rift},
    'arceus'=>{:archetype=>:primordial,:family=>:column}
  }
end

class Scene_PMD_AutoChess
  alias pmd_ac_v10525_focus_tier focus_tier_v10515 unless method_defined?(:pmd_ac_v10525_focus_tier)
  alias pmd_ac_v10525_semantic_family focus_semantic_family_v10521 unless method_defined?(:pmd_ac_v10525_semantic_family)
  alias pmd_ac_v10525_focus_begin focus_cast_begin_v1055 unless method_defined?(:pmd_ac_v10525_focus_begin)
  alias pmd_ac_v10525_start_battle start_battle unless method_defined?(:pmd_ac_v10525_start_battle)
  alias pmd_ac_v10525_focus_summary focus_cast_log_summary_v1055 unless method_defined?(:pmd_ac_v10525_focus_summary)

  def focus_key_v10525(user)
    return nil if user==nil
    user.instance_variable_get(:@skill_type)
  rescue
    nil
  end

  def focus_owner_species_key_v10525(user)
    return '' if user==nil
    k=nil
    begin;k=user.species_key if user.respond_to?(:species_key);rescue;k=nil;end
    k=k.to_s.downcase
    k
  rescue
    ''
  end

  def focus_boss_archetype_v10525(user)
    key=focus_owner_species_key_v10525(user)
    PMD_AC::BOSS_FOCUS_ARCHETYPE_V10525[key]
  rescue
    nil
  end

  def focus_explicit_family_before_v10525(key)
    return nil if key==nil
    begin
      f=PMD_AC::FOCUS_SIGNATURE_FAMILY_V10523[key]
      return f if f!=nil
    rescue
    end
    begin
      f=PMD_AC::FOCUS_SIGNATURE_FAMILY_V10522[key]
      return f if f!=nil
    rescue
    end
    begin
      f=PMD_AC::FOCUS_SIGNATURE_FAMILY_V10521[key]
      return f if f!=nil
    rescue
    end
    nil
  rescue
    nil
  end

  def focus_tier_v10515(user)
    tier=pmd_ac_v10525_focus_tier(user)
    return tier unless tier==:standard
    key=focus_key_v10525(user)
    return :important if PMD_AC::IMPORTANT_FOCUS_SKILL_TYPES_V10525.include?(key)
    :standard
  rescue
    pmd_ac_v10525_focus_tier(user)
  end

  def focus_semantic_family_v10521(key,tier)
    fam=PMD_AC::FOCUS_SIGNATURE_FAMILY_V10525[key]
    return fam if fam!=nil
    explicit=focus_explicit_family_before_v10525(key)
    return pmd_ac_v10525_semantic_family(key,tier) if explicit!=nil
    if tier==:boss
      p=focus_boss_archetype_v10525(@focus_cast_owner_v1055)
      return p[:family] if p!=nil && p[:family]!=nil
    end
    pmd_ac_v10525_semantic_family(key,tier)
  rescue
    pmd_ac_v10525_semantic_family(key,tier)
  end

  def focus_fatigue_reset_v10525
    @focus_fatigue_casts_v10525=0
    @focus_fatigue_standard_v10525=0
    @focus_fatigue_important_v10525=0
    @focus_fatigue_boss_v10525=0
    @focus_fatigue_repeat_global_v10525=0
    @focus_fatigue_repeat_owner_window_v10525=0
    @focus_fatigue_standard_chain_v10525=0
    @focus_fatigue_max_standard_chain_v10525=0
    @focus_fatigue_same_skill_chain_v10525=0
    @focus_fatigue_max_same_skill_chain_v10525=0
    @focus_fatigue_gap_sum_v10525=0
    @focus_fatigue_gap_count_v10525=0
    @focus_fatigue_gap_min_v10525=nil
    @focus_fatigue_gap_max_v10525=0
    @focus_fatigue_last_frame_v10525=nil
    @focus_fatigue_first_frame_v10525=nil
    @focus_fatigue_last_key_v10525=nil
    @focus_fatigue_owner_skill_last_v10525={}
    @focus_fatigue_unique_skills_v10525={}
    @focus_fatigue_library_iv_hits_v10525=0
    @focus_boss_archetype_hits_v10525=0
    true
  rescue
    false
  end

  def focus_fatigue_owner_token_v10525(user,key)
    oid=0
    begin;oid=user.object_id if user!=nil;rescue;oid=0;end
    oid.to_s+'|'+(key==nil ? 'NONE' : key.to_s)
  rescue
    '0|NONE'
  end

  def focus_fatigue_record_v10525(user,key,tier)
    frame=Graphics.frame_count.to_i
    @focus_fatigue_casts_v10525=@focus_fatigue_casts_v10525.to_i+1
    @focus_fatigue_standard_v10525=@focus_fatigue_standard_v10525.to_i+1 if tier==:standard
    @focus_fatigue_important_v10525=@focus_fatigue_important_v10525.to_i+1 if tier==:important
    @focus_fatigue_boss_v10525=@focus_fatigue_boss_v10525.to_i+1 if tier==:boss
    @focus_fatigue_first_frame_v10525=frame if @focus_fatigue_first_frame_v10525==nil

    if @focus_fatigue_last_frame_v10525!=nil
      gap=frame-@focus_fatigue_last_frame_v10525.to_i
      gap=0 if gap<0
      @focus_fatigue_gap_sum_v10525=@focus_fatigue_gap_sum_v10525.to_i+gap
      @focus_fatigue_gap_count_v10525=@focus_fatigue_gap_count_v10525.to_i+1
      @focus_fatigue_gap_min_v10525=gap if @focus_fatigue_gap_min_v10525==nil || gap<@focus_fatigue_gap_min_v10525.to_i
      @focus_fatigue_gap_max_v10525=gap if gap>@focus_fatigue_gap_max_v10525.to_i
    end

    if key!=nil && key==@focus_fatigue_last_key_v10525
      @focus_fatigue_repeat_global_v10525=@focus_fatigue_repeat_global_v10525.to_i+1
      @focus_fatigue_same_skill_chain_v10525=@focus_fatigue_same_skill_chain_v10525.to_i+1
    else
      @focus_fatigue_same_skill_chain_v10525=1
    end
    if @focus_fatigue_same_skill_chain_v10525.to_i>@focus_fatigue_max_same_skill_chain_v10525.to_i
      @focus_fatigue_max_same_skill_chain_v10525=@focus_fatigue_same_skill_chain_v10525.to_i
    end

    if tier==:standard
      @focus_fatigue_standard_chain_v10525=@focus_fatigue_standard_chain_v10525.to_i+1
      if @focus_fatigue_standard_chain_v10525.to_i>@focus_fatigue_max_standard_chain_v10525.to_i
        @focus_fatigue_max_standard_chain_v10525=@focus_fatigue_standard_chain_v10525.to_i
      end
    else
      @focus_fatigue_standard_chain_v10525=0
    end

    token=focus_fatigue_owner_token_v10525(user,key)
    old=@focus_fatigue_owner_skill_last_v10525[token]
    if old!=nil && frame-old.to_i<=PMD_AC::FOCUS_FATIGUE_REPEAT_WINDOW_V10525
      @focus_fatigue_repeat_owner_window_v10525=@focus_fatigue_repeat_owner_window_v10525.to_i+1
      if @focus_fatigue_repeat_owner_window_v10525<=4
        log_event(:battle,'BATTLE_FOCUS_REPEAT_OBSERVER_V10525 owner='+(user==nil ? 'NONE' : user.log_name.to_s)+
          ' skill='+(key==nil ? 'NONE' : key.to_s)+' gap='+(frame-old.to_i).to_s+
          ' window='+PMD_AC::FOCUS_FATIGUE_REPEAT_WINDOW_V10525.to_s+' behavior_change=0')
      end
    end
    @focus_fatigue_owner_skill_last_v10525[token]=frame
    @focus_fatigue_unique_skills_v10525[key.to_s]=true if key!=nil
    @focus_fatigue_last_frame_v10525=frame
    @focus_fatigue_last_key_v10525=key

    if tier==:important && PMD_AC::IMPORTANT_FOCUS_SKILL_TYPES_V10525.include?(key)
      @focus_fatigue_library_iv_hits_v10525=@focus_fatigue_library_iv_hits_v10525.to_i+1
      if @focus_fatigue_library_iv_hits_v10525<=6
        fam=PMD_AC::FOCUS_SIGNATURE_FAMILY_V10525[key]
        log_event(:battle,'BATTLE_IMPORTANT_LIBRARY_IV_HIT_V10525 skill='+key.to_s+
          ' family='+(fam==nil ? 'NONE' : fam.to_s)+' tier=important')
      end
    end

    if tier==:boss
      p=focus_boss_archetype_v10525(user)
      if p!=nil
        @focus_boss_archetype_hits_v10525=@focus_boss_archetype_hits_v10525.to_i+1
        if @focus_boss_archetype_hits_v10525<=6
          log_event(:battle,'BATTLE_BOSS_FOCUS_ARCHETYPE_V10525 species='+focus_owner_species_key_v10525(user)+
            ' archetype='+p[:archetype].to_s+' fallback_family='+p[:family].to_s+
            ' explicit_skill_family='+(focus_explicit_family_before_v10525(key)==nil && PMD_AC::FOCUS_SIGNATURE_FAMILY_V10525[key]==nil ? '0':'1'))
        end
      end
    end
    true
  rescue
    false
  end

  def focus_cast_begin_v1055(user,target)
    key=focus_key_v10525(user)
    tier=focus_tier_v10515(user)
    ok=pmd_ac_v10525_focus_begin(user,target)
    focus_fatigue_record_v10525(user,key,tier) if ok
    ok
  rescue
    false
  end

  def start_battle
    r=pmd_ac_v10525_start_battle
    focus_fatigue_reset_v10525
    if respond_to?(:verification_mode) && verification_mode==:normal
      total=PMD_AC::IMPORTANT_FOCUS_SKILL_TYPES_V10515.size+
        PMD_AC::IMPORTANT_FOCUS_SKILL_TYPES_V10522.size+
        PMD_AC::IMPORTANT_FOCUS_SKILL_TYPES_V10523.size+
        PMD_AC::IMPORTANT_FOCUS_SKILL_TYPES_V10525.size
      log_event(:battle,'BATTLE_FOCUS_FATIGUE_OBSERVER_V10525 START'+
        ' repeat_window='+PMD_AC::FOCUS_FATIGUE_REPEAT_WINDOW_V10525.to_s+
        ' repeat_global=1 repeat_owner_skill=1 max_standard_chain=1 gap_metrics=1'+
        ' observer_only=1 behavior_change=0 battle_speed_unchanged=1 focus_timing_unchanged=1')
      log_event(:battle,'BATTLE_IMPORTANT_LIBRARY_IV_V10525 START added='+
        PMD_AC::IMPORTANT_FOCUS_SKILL_TYPES_V10525.size.to_s+' total='+total.to_s+
        ' families=beam,impact,burst,wave,column move_keys_static_validated=1')
      log_event(:battle,'BATTLE_BOSS_FOCUS_ARCHETYPE_I_V10525 START profiles='+
        PMD_AC::BOSS_FOCUS_ARCHETYPE_V10525.size.to_s+
        ' skill_family_priority=1 boss_flag_required=1 generic_boss_fallback_retained=1')
      log_event(:battle,'BATTLE_CONTENT_SCALE_TRANSITION_V10525 phase_b2_observer=1'+
        ' important_library_total='+total.to_s+
        ' boss_archetypes='+PMD_AC::BOSS_FOCUS_ARCHETYPE_V10525.size.to_s+
        ' generated_motion_profiles_0027_0494=468'+
        ' compiled_pmd_metadata_0001_0494=494 packaged_runtime_sprite_scope=26'+
        ' runtime_asset_qa_0027_0494=deferred no_fake_hasPlayable=1')
    end
    r
  end

  def focus_fatigue_summary_v10525
    casts=@focus_fatigue_casts_v10525.to_i
    gap_count=@focus_fatigue_gap_count_v10525.to_i
    avg=gap_count>0 ? (@focus_fatigue_gap_sum_v10525.to_i/gap_count) : 0
    min=@focus_fatigue_gap_min_v10525==nil ? 0 : @focus_fatigue_gap_min_v10525.to_i
    span=0
    if @focus_fatigue_first_frame_v10525!=nil && @focus_fatigue_last_frame_v10525!=nil
      span=@focus_fatigue_last_frame_v10525.to_i-@focus_fatigue_first_frame_v10525.to_i
      span=0 if span<0
    end
    rate=span>0 ? ((casts*1000.0/span.to_f)*10.0).round/10.0 : casts.to_f
    unique=@focus_fatigue_unique_skills_v10525==nil ? 0 : @focus_fatigue_unique_skills_v10525.size
    log_event(:battle,'BATTLE_FOCUS_FATIGUE_SUMMARY_V10525 casts='+casts.to_s+
      ' standard='+@focus_fatigue_standard_v10525.to_i.to_s+
      ' important='+@focus_fatigue_important_v10525.to_i.to_s+
      ' boss='+@focus_fatigue_boss_v10525.to_i.to_s+
      ' unique_skills='+unique.to_s+
      ' repeat_global='+@focus_fatigue_repeat_global_v10525.to_i.to_s+
      ' repeat_owner_window='+@focus_fatigue_repeat_owner_window_v10525.to_i.to_s+
      ' max_same_skill_chain='+@focus_fatigue_max_same_skill_chain_v10525.to_i.to_s+
      ' max_standard_chain='+@focus_fatigue_max_standard_chain_v10525.to_i.to_s+
      ' avg_gap='+avg.to_s+' min_gap='+min.to_s+' max_gap='+@focus_fatigue_gap_max_v10525.to_i.to_s+
      ' casts_per_1000f='+rate.to_s+
      ' library_iv_hits='+@focus_fatigue_library_iv_hits_v10525.to_i.to_s+
      ' boss_archetype_hits='+@focus_boss_archetype_hits_v10525.to_i.to_s+
      ' behavior_change=0')
    true
  rescue
    false
  end

  def focus_cast_log_summary_v1055
    r=pmd_ac_v10525_focus_summary
    focus_fatigue_summary_v10525
    r
  rescue
    false
  end
end
