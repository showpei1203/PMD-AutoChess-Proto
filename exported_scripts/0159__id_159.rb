#==============================================================================
# 【PMD AutoChess 中文維護說明】
# 腳本：PMD AutoChess Proto v0.32
# 分類：核心戰鬥 Runtime
#
# 【用途／機制】
# 承接前序 Data／Config，實際執行戰鬥 Scene、Unit、AI、技能與呈現。
#
# 【怎麼調整】
# 一般平衡與資料調整不要直接改 Runtime；若要追加功能，建議在較後腳本 alias 原方法後擴充。
#
# 【本腳本主要設定常數／資料表】
# - VERIFICATION_SKILL_AUDIO_END_FRAME_V032 / SKILL_AUDIO_VOLUME_V032 / SKILL_AUDIO_PITCH_V032 / VERIFICATION_MODES
# - VERIFICATION_LABELS
#
# 【Runtime 主要方法（查流程時可直接搜尋）】
# - skill_audio_manifest_v032 / skill_audio_move_profile_v032 / skill_audio_category_pool_v032 / skill_audio_spec_v032
# - skill_audio_scalar_v032 / skill_audio_checksum32_v032 / validate_skill_audio_v032 / start
# - play_skill_se / prepare_verification_battle / log_event / verify_skill_audio_manifest_v032
#
# 【維護規則】
# - RPG Maker VX / RGSS2 / Ruby 1.8 相容。
# - instance_uid 才是 Pokémon 個體身份；Actor ID 只是容器。
# - 新增行為優先沿用既有 helper／Data 表；避免破壞已 Freeze 的舊核心。
# - 本專案新腳本也必須保留同等級的中文說明與實際範例。
#==============================================================================
#==============================================================================
# ■ PMD AutoChess Proto v0.32
#    Skill Audio Foundation + PMD_SkillFX Magenta Guide Cleanup
#------------------------------------------------------------------------------
#  Additive presentation-only layer on verified v0.31.1.
#  - 222/222 runtime canonical moves have audio routing profiles.
#  - Full user-supplied unique DS SFX library is packaged under Audio/SE.
#  - Existing Ranger SkillFX #FF00FF registration guides are cleaned offline.
#  - Recent-5 verification selector keeps the newest mode first.
#==============================================================================
module PMD_AC
  VERIFICATION_SKILL_AUDIO_END_FRAME_V032 = 440

  SKILL_AUDIO_VOLUME_V032 = {:cast=>70,:launch=>77,:hit=>84}
  SKILL_AUDIO_PITCH_V032 = {
    :normal=>100,:fire=>96,:water=>100,:electric=>106,:grass=>102,:ice=>108,
    :fighting=>94,:poison=>96,:ground=>88,:flying=>106,:psychic=>108,
    :bug=>104,:rock=>90,:ghost=>92,:dragon=>94,:dark=>90,:steel=>100,
    :fairy=>112,:sound=>105
  }

  class << self
    def skill_audio_manifest_v032
      SKILL_AUDIO_MANIFEST_V032
    end

    def skill_audio_move_profile_v032(move_key)
      SKILL_AUDIO_MOVE_V032[move_key]
    end

    def skill_audio_category_pool_v032(category)
      return nil if category == nil
      SKILL_AUDIO_CATEGORY_POOLS_V032[category.to_sym]
    end

    def skill_audio_spec_v032(move_key,stage,variant_index=0)
      p=skill_audio_move_profile_v032(move_key)
      return nil if p==nil
      field=(stage.to_s+"_cat").to_sym
      cat=p[field]
      return nil if cat==nil
      pool=skill_audio_category_pool_v032(cat)
      return nil if pool==nil || pool.empty?
      idx=variant_index.to_i % pool.size
      name=pool[idx]
      style=p[:audio_style] || p[:type] || :normal
      volume=SKILL_AUDIO_VOLUME_V032[stage] || 80
      pitch=SKILL_AUDIO_PITCH_V032[style] || 100
      {:name=>name,:volume=>volume,:pitch=>pitch}
    end

    def skill_audio_scalar_v032(v)
      return "" if v==nil
      return v ? "true" : "false" if v==true || v==false
      if v.is_a?(Float)
        s=sprintf("%.8g",v)
        s += ".0" unless s.include?(".") || s.include?("e") || s.include?("E")
        return s
      end
      v.to_s
    end

    def skill_audio_checksum32_v032
      h=0
      groups=[["C",SKILL_AUDIO_CATEGORY_POOLS_V032],["T",SKILL_AUDIO_TYPE_V032],["M",SKILL_AUDIO_MOVE_V032]]
      for pair in groups
        prefix=pair[0];group=pair[1]
        for key in group.keys.sort{|a,b|a.to_s<=>b.to_s}
          r=group[key]
          fields=[]
          if r.is_a?(Array)
            fields.push("files="+r.collect{|x|x.to_s}.join(","))
          else
            for f in r.keys.sort{|a,b|a.to_s<=>b.to_s}
              fields.push(f.to_s+"="+skill_audio_scalar_v032(r[f]))
            end
          end
          text=([prefix,key.to_s]+fields).join("|")
          text.each_byte{|by|h=((h*33)+by)&0x7fffffff}
        end
      end
      h
    end

    def validate_skill_audio_v032
      e=[];m=SKILL_AUDIO_MANIFEST_V032
      e.push("library_count") unless m[:library_wav_count].to_i==489
      e.push("skill_sfx_count") unless m[:skill_sfx_wav_count].to_i==261
      e.push("cry_count") unless m[:creature_cry_wav_count].to_i==228
      e.push("type_profiles") unless SKILL_AUDIO_TYPE_V032.size==19
      e.push("move_count") unless SKILL_AUDIO_MOVE_V032.size==222
      e.push("move_coverage") unless m[:mapped_move_audio_count].to_i==222
      e.push("special_count") unless SKILL_AUDIO_SPECIALS_V032.size==10
      e.push("fx_clean") unless m[:fx_cleaned_count].to_i==44 && m[:fx_remaining_opaque_magenta].to_i==0
      e.push("thunderbolt") unless SKILL_AUDIO_MOVE_V032[:thunderbolt][:launch_cat]==:energy_beam && SKILL_AUDIO_MOVE_V032[:thunderbolt][:hit_cat]==:electric_zap
      e.push("flamethrower") unless SKILL_AUDIO_MOVE_V032[:flamethrower][:launch_cat]==:long_burst
      e.push("hydro_pump") unless SKILL_AUDIO_MOVE_V032[:hydro_pump][:hit_cat]==:water_splash
      e.push("screech") unless SKILL_AUDIO_MOVE_V032[:screech][:launch_cat]==nil && SKILL_AUDIO_MOVE_V032[:screech][:hit_cat]==:tone_high_sustain
      e.push("checksum") unless skill_audio_checksum32_v032==m[:runtime_checksum32].to_i
      e
    end
  end

  # Latest test first; keep only the recent five in everyday S cycling.
  remove_const(:VERIFICATION_MODES) if const_defined?(:VERIFICATION_MODES)
  VERIFICATION_MODES = [
    :skill_audio,
    :skill_visual_expansion,
    :skill_visual,
    :weather_visual,
    :weather
  ]

  remove_const(:VERIFICATION_LABELS) if const_defined?(:VERIFICATION_LABELS)
  VERIFICATION_LABELS = {
    :skill_audio            => "SKILL_AUDIO",
    :skill_visual_expansion => "SKILL_VISUAL_EXPANSION",
    :skill_visual           => "SKILL_VISUAL",
    :weather_visual         => "WEATHER_VISUAL",
    :weather                => "WEATHER"
  }
end

class Scene_PMD_AutoChess
  alias pmd_ac_v032_start start unless method_defined?(:pmd_ac_v032_start)
  alias pmd_ac_v032_play_skill_se play_skill_se unless method_defined?(:pmd_ac_v032_play_skill_se)
  alias pmd_ac_v032_prepare_verification_battle prepare_verification_battle unless method_defined?(:pmd_ac_v032_prepare_verification_battle)
  alias pmd_ac_v032_update_verification_script update_verification_script unless method_defined?(:pmd_ac_v032_update_verification_script)
  alias pmd_ac_v032_complete_verification_mode complete_verification_mode unless method_defined?(:pmd_ac_v032_complete_verification_mode)
  alias pmd_ac_v032_log_event log_event unless method_defined?(:pmd_ac_v032_log_event)

  def start
    pmd_ac_v032_start
    begin
      if FileTest.exist?(PMD_AC::BATTLE_LOG_FILE)
        text=File.open(PMD_AC::BATTLE_LOG_FILE,"rb"){|f|f.read}
        text.sub!(/PMD AutoChess Proto v0\.[0-9.]+ Battle Verification Log/,
                  "PMD AutoChess Proto v0.32 Battle Verification Log")
        File.open(PMD_AC::BATTLE_LOG_FILE,"wb"){|f|f.write(text)}
      end
    rescue
    end
    m=PMD_AC.skill_audio_manifest_v032
    log_event(:skill_audio,
      "LOADED library="+m[:library_wav_count].to_s+
      " skill_sfx="+m[:skill_sfx_wav_count].to_s+
      " cries="+m[:creature_cry_wav_count].to_s+
      " mapped_moves="+m[:mapped_move_audio_count].to_s+"/"+m[:runtime_move_total].to_s+
      " coverage="+sprintf("%.2f",m[:runtime_audio_coverage_percent].to_f)+"%"+
      " fx_cleaned="+m[:fx_cleaned_count].to_s+
      " magenta_remaining="+m[:fx_remaining_opaque_magenta].to_s+
      " checksum32="+m[:runtime_checksum32].to_s)
  end

  # Canonical runtime moves use v0.32 audio profiles. Legacy custom skills keep
  # the old cast_se / launch_se / hit_se routing exactly as before.
  def play_skill_se(unit,stage,data=nil)
    return if unit==nil
    data=unit.skill_data if data==nil
    mk=(data==nil ? nil : data[:canonical_move_key])
    profile=(mk==nil ? nil : PMD_AC.skill_audio_move_profile_v032(mk))
    return pmd_ac_v032_play_skill_se(unit,stage,data) if profile==nil

    @skill_audio_variant_v032={} if @skill_audio_variant_v032==nil
    vk=[mk,stage]
    idx=@skill_audio_variant_v032[vk] || 0
    @skill_audio_variant_v032[vk]=idx+1
    spec=PMD_AC.skill_audio_spec_v032(mk,stage,idx)
    # Explicit nil means this move/stage intentionally has no SE.
    return if spec==nil

    # Preserve v0.15 same-frame Chain/Pierce/AOE hit dedup semantics.
    if stage==:hit
      @skill_hit_se_frames={} if @skill_hit_se_frames==nil
      hit_key=[unit.id,unit.skill_type]
      now=Graphics.frame_count
      last=@skill_hit_se_frames[hit_key] || -9999
      return if now-last < PMD_AC::SKILL_HIT_SE_DEDUP_FRAMES
      @skill_hit_se_frames[hit_key]=now
    end
    PMD_AC.play_se(spec)
  end

  def prepare_verification_battle
    pmd_ac_v032_prepare_verification_battle
    if verification_mode==:skill_audio
      @skill_audio_failed_v032=false
      @skill_audio_demo_count_v032=0
      for u in @units;u.verification_combat_sandbox(true);end
    end
  end

  def log_event(category,message)
    if category.to_s=="verify" && verification_mode==:skill_audio &&
       message.to_s.index("SKILL_AUDIO_")==0 && message.to_s.include?(" pass=0")
      @skill_audio_failed_v032=true
    end
    pmd_ac_v032_log_event(category,message)
  end

  def verify_skill_audio_manifest_v032
    return if @verification_done[:skill_audio_manifest]
    e=PMD_AC.validate_skill_audio_v032;m=PMD_AC.skill_audio_manifest_v032
    pass=e.empty?
    log_event(:verify,
      "SKILL_AUDIO_MANIFEST pass="+(pass ? "1":"0")+
      " library="+m[:library_wav_count].to_s+
      " skill_sfx="+m[:skill_sfx_wav_count].to_s+
      " cries="+m[:creature_cry_wav_count].to_s+
      " moves="+m[:mapped_move_audio_count].to_s+"/"+m[:runtime_move_total].to_s+
      " types="+m[:type_audio_profile_count].to_s+
      " pools="+m[:used_category_pool_count].to_s+
      " specials="+m[:special_move_profile_count].to_s+
      " checksum="+PMD_AC.skill_audio_checksum32_v032.to_s+
      " errors=["+e.join(",")+"]")
    @verification_done[:skill_audio_manifest]=true
  end

  def opaque_magenta_count_v032(name)
    b=Cache.load_bitmap("Graphics/Pictures/PMD_SkillFX/",name)
    count=0
    y=0
    while y<b.height
      x=0
      while x<b.width
        c=b.get_pixel(x,y)
        count+=1 if c.alpha>0 && c.red==255 && c.green==0 && c.blue==255
        x+=1
      end
      y+=1
    end
    count
  rescue
    -1
  end

  def verify_skill_fx_clean_v032
    return if @verification_done[:skill_fx_clean]
    a=opaque_magenta_count_v032("Ranger_149")
    b=opaque_magenta_count_v032("Ranger_169")
    c=opaque_magenta_count_v032("Ranger_156")
    m=PMD_AC.skill_audio_manifest_v032
    tool=FileTest.exist?("Tools/clean_import_skillfx_v032.py") && FileTest.exist?("DevAssets/Source/Pokemon_Ranger3_AttackEffects.zip")
    pass=a==0 && b==0 && c==0 && m[:fx_remaining_opaque_magenta].to_i==0 && tool
    log_event(:verify,
      "SKILL_AUDIO_FX_CLEAN pass="+(pass ? "1":"0")+
      " cleaned="+m[:fx_cleaned_count].to_s+
      " removed="+m[:fx_removed_magenta_pixels].to_s+
      " remaining="+m[:fx_remaining_opaque_magenta].to_s+
      " ranger149="+a.to_s+" ranger169="+b.to_s+" ranger156="+c.to_s+
      " future_import_tool="+(tool ? "1":"0"))
    @verification_done[:skill_fx_clean]=true
  end

  def verify_skill_audio_files_v032
    return if @verification_done[:skill_audio_files]
    checked=0;missing=[]
    for cat in PMD_AC::SKILL_AUDIO_CATEGORY_POOLS_V032.keys
      pool=PMD_AC::SKILL_AUDIO_CATEGORY_POOLS_V032[cat]
      for name in pool
        checked+=1
        missing.push(name) unless FileTest.exist?("Audio/SE/"+name+".wav")
      end
    end
    pass=missing.empty?
    log_event(:verify,
      "SKILL_AUDIO_FILES pass="+(pass ? "1":"0")+
      " checked="+checked.to_s+" missing="+missing.size.to_s+
      (missing.empty? ? "" : " first_missing="+missing[0].to_s))
    @verification_done[:skill_audio_files]=true
  end

  def verify_skill_audio_profiles_v032
    return if @verification_done[:skill_audio_profiles]
    e=PMD_AC.skill_audio_spec_v032(:thunderbolt,:launch,0)
    f=PMD_AC.skill_audio_spec_v032(:flamethrower,:launch,0)
    w=PMD_AC.skill_audio_spec_v032(:hydro_pump,:hit,0)
    r=PMD_AC.skill_audio_spec_v032(:rock_throw,:hit,0)
    s=PMD_AC.skill_audio_spec_v032(:screech,:hit,0)
    pass=e!=nil && f!=nil && w!=nil && r!=nil && s!=nil
    log_event(:verify,
      "SKILL_AUDIO_PROFILES pass="+(pass ? "1":"0")+
      " electric="+(e==nil ? "nil":e[:name].to_s)+
      " fire="+(f==nil ? "nil":f[:name].to_s)+
      " water="+(w==nil ? "nil":w[:name].to_s)+
      " rock="+(r==nil ? "nil":r[:name].to_s)+
      " sound="+(s==nil ? "nil":s[:name].to_s))
    @verification_done[:skill_audio_profiles]=true
  end

  def verify_skill_audio_specials_v032
    return if @verification_done[:skill_audio_specials]
    t=PMD_AC::SKILL_AUDIO_MOVE_V032[:thunder]
    tb=PMD_AC::SKILL_AUDIO_MOVE_V032[:thunderbolt]
    fl=PMD_AC::SKILL_AUDIO_MOVE_V032[:flamethrower]
    hp=PMD_AC::SKILL_AUDIO_MOVE_V032[:hydro_pump]
    sc=PMD_AC::SKILL_AUDIO_MOVE_V032[:screech]
    rec=PMD_AC::SKILL_AUDIO_MOVE_V032[:recover]
    pass=t[:launch_cat]==nil && tb[:launch_cat]==:energy_beam &&
      fl[:launch_cat]==:long_burst && hp[:launch_cat]==:ambient_stream &&
      sc[:launch_cat]==nil && rec[:launch_cat]==nil
    log_event(:verify,
      "SKILL_AUDIO_SPECIALS pass="+(pass ? "1":"0")+
      " thunder=target_hit thunderbolt=beam flamethrower=beam hydro_pump=stream"+
      " screech=target_only recover=self")
    @verification_done[:skill_audio_specials]=true
  end

  def play_skill_audio_demo_v032(move_key,stage,label)
    spec=PMD_AC.skill_audio_spec_v032(move_key,stage,0)
    ok=spec!=nil && FileTest.exist?("Audio/SE/"+spec[:name].to_s+".wav")
    PMD_AC.play_se(spec) if ok
    @skill_audio_demo_count_v032+=1 if ok
    log_event(:skill_audio,
      "DEMO "+label+" move="+move_key.to_s+" stage="+stage.to_s+
      " file="+(spec==nil ? "nil":spec[:name].to_s)+" ok="+(ok ? "1":"0"))
  end

  def verify_skill_audio_playback_v032
    return if @verification_done[:skill_audio_playback]
    pass=@skill_audio_demo_count_v032.to_i==8
    log_event(:verify,
      "SKILL_AUDIO_PLAYBACK pass="+(pass ? "1":"0")+
      " demos="+@skill_audio_demo_count_v032.to_i.to_s+
      " sequence=thunderbolt,flamethrower,hydro_pump,screech,recover")
    @verification_done[:skill_audio_playback]=true
  end

  def verify_skill_audio_recent_modes_v032
    return if @verification_done[:skill_audio_recent_modes]
    expected=[:skill_audio,:skill_visual_expansion,:skill_visual,:weather_visual,:weather]
    pass=PMD_AC::VERIFICATION_MODES==expected && verification_mode==:skill_audio
    log_event(:verify,
      "SKILL_AUDIO_RECENT_MODES pass="+(pass ? "1":"0")+
      " modes="+PMD_AC::VERIFICATION_MODES.size.to_s+
      " default="+PMD_AC::VERIFICATION_LABELS[PMD_AC::VERIFICATION_MODES[0]].to_s)
    @verification_done[:skill_audio_recent_modes]=true
  end

  def update_verification_script
    pmd_ac_v032_update_verification_script
    return unless verification_mode==:skill_audio
    f=@verification_frame
    verify_skill_audio_manifest_v032 if f==4
    verify_skill_fx_clean_v032 if f==20
    verify_skill_audio_files_v032 if f==40
    verify_skill_audio_profiles_v032 if f==70
    verify_skill_audio_specials_v032 if f==100
    play_skill_audio_demo_v032(:thunderbolt,:launch,"THUNDERBOLT_LAUNCH") if f==130
    play_skill_audio_demo_v032(:thunderbolt,:hit,"THUNDERBOLT_HIT") if f==165
    play_skill_audio_demo_v032(:flamethrower,:launch,"FLAMETHROWER_FLOW") if f==200
    play_skill_audio_demo_v032(:flamethrower,:hit,"FLAMETHROWER_HIT") if f==235
    play_skill_audio_demo_v032(:hydro_pump,:launch,"HYDRO_PUMP_FLOW") if f==270
    play_skill_audio_demo_v032(:hydro_pump,:hit,"HYDRO_PUMP_HIT") if f==305
    play_skill_audio_demo_v032(:screech,:hit,"SCREECH_TARGET") if f==340
    play_skill_audio_demo_v032(:recover,:hit,"RECOVER_SELF") if f==375
    verify_skill_audio_playback_v032 if f==400
    verify_skill_audio_recent_modes_v032 if f==420
    complete_verification_mode if f==PMD_AC::VERIFICATION_SKILL_AUDIO_END_FRAME_V032
  end

  def complete_verification_mode
    if verification_mode==:skill_audio && @skill_audio_failed_v032
      for u in @units;u.verification_finish;end
      @verification_done[:complete]=true
      log_event(:verify,"FAILED mode=SKILL_AUDIO auto_skill=on original_skills=restored")
      return
    end
    pmd_ac_v032_complete_verification_mode
  end
end
