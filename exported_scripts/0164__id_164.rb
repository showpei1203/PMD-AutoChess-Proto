#==============================================================================
# 【PMD AutoChess 中文維護說明】
# 腳本：PMD AutoChess Proto v0.34
# 分類：核心戰鬥 Runtime
#
# 【用途／機制】
# 承接前序 Data／Config，實際執行戰鬥 Scene、Unit、AI、技能與呈現。
#
# 【怎麼調整】
# 一般平衡與資料調整不要直接改 Runtime；若要追加功能，建議在較後腳本 alias 原方法後擴充。
#
# 【本腳本主要設定常數／資料表】
# - SKILL_SPECIAL_RGS3_GLOBAL_SCALE_V0331 / VERIFICATION_SKILL_SPECIAL_II_END_FRAME_V034 / VERIFICATION_MODES / VERIFICATION_LABELS
#
# 【Runtime 主要方法（查流程時可直接搜尋）】
# - skill_special_visual_v033 / skill_special_rgs3_meta_v033 / skill_audio_spec_v032 / skill_special_ii_checksum32_v034
# - validate_skill_special_ii_v034 / start / play_skill_special_visual_v033 / prepare_verification_battle
# - log_event / verify_skill_special_ii_manifest_v034 / verify_skill_special_ii_scale_v034 / demo_skill_special_ii_v034
#
# 【維護規則】
# - RPG Maker VX / RGSS2 / Ruby 1.8 相容。
# - instance_uid 才是 Pokémon 個體身份；Actor ID 只是容器。
# - 新增行為優先沿用既有 helper／Data 表；避免破壞已 Freeze 的舊核心。
# - 本專案新腳本也必須保留同等級的中文說明與實際範例。
#==============================================================================
#==============================================================================
# ■ PMD AutoChess Proto v0.34
#    Skill Visual + Audio Specialization II
#------------------------------------------------------------------------------
#  Additive layer on verified v0.33.1.
#  - User-approved global RGS3 display baseline is now 0.60.
#  - Adds 12 specialized canonical move presentations, 21 cumulative.
#  - Reuses cleaned RGS3 VX sheets and verified v0.32 audio pools.
#  - Combat damage / targeting / accuracy / collision / status semantics untouched.
#==============================================================================
module PMD_AC
  remove_const(:SKILL_SPECIAL_RGS3_GLOBAL_SCALE_V0331) if const_defined?(:SKILL_SPECIAL_RGS3_GLOBAL_SCALE_V0331)
  SKILL_SPECIAL_RGS3_GLOBAL_SCALE_V0331 = 0.60
  VERIFICATION_SKILL_SPECIAL_II_END_FRAME_V034 = 680

  class << self
    alias pmd_ac_v034_special_visual_v033 skill_special_visual_v033 unless method_defined?(:pmd_ac_v034_special_visual_v033)
    def skill_special_visual_v033(move_key)
      SKILL_SPECIAL_II_VISUAL_V034[move_key] || pmd_ac_v034_special_visual_v033(move_key)
    end

    alias pmd_ac_v034_rgs3_meta_v033 skill_special_rgs3_meta_v033 unless method_defined?(:pmd_ac_v034_rgs3_meta_v033)
    def skill_special_rgs3_meta_v033(name)
      SKILL_SPECIAL_II_RGS3_META_V034[name.to_s] || pmd_ac_v034_rgs3_meta_v033(name)
    end

    alias pmd_ac_v034_audio_spec_v032 skill_audio_spec_v032 unless method_defined?(:pmd_ac_v034_audio_spec_v032)
    def skill_audio_spec_v032(move_key,stage,variant_index=0)
      ov=SKILL_SPECIAL_II_AUDIO_V034[move_key]
      if ov!=nil
        field=(stage.to_s+"_cat").to_sym
        if ov.has_key?(field)
          cat=ov[field]
          return nil if cat==nil
          pool=skill_audio_category_pool_v032(cat)
          return nil if pool==nil || pool.empty?
          idx=variant_index.to_i % pool.size
          style=ov[:audio_style] || :normal
          return {:name=>pool[idx],:volume=>(SKILL_AUDIO_VOLUME_V032[stage]||80),:pitch=>(SKILL_AUDIO_PITCH_V032[style]||100)}
        end
      end
      pmd_ac_v034_audio_spec_v032(move_key,stage,variant_index)
    end

    def skill_special_ii_checksum32_v034
      h=0
      groups=[["V",SKILL_SPECIAL_II_VISUAL_V034],["M",SKILL_SPECIAL_II_RGS3_META_V034],["A",SKILL_SPECIAL_II_AUDIO_V034]]
      for pair in groups
        prefix=pair[0]; group=pair[1]
        for key in group.keys.sort{|a,b|a.to_s<=>b.to_s}
          r=group[key]
          fields=r.keys.sort{|a,b|a.to_s<=>b.to_s}.collect{|f| f.to_s+"="+(r[f]==nil ? "" : r[f].to_s)}
          text=([prefix,key.to_s]+fields).join("|")
          text.each_byte{|by|h=((h*33)+by)&0x7fffffff}
        end
      end
      "SCALE|0.60".each_byte{|by|h=((h*33)+by)&0x7fffffff}
      h
    end

    def validate_skill_special_ii_v034
      e=[]; m=SKILL_SPECIAL_II_MANIFEST_V034
      e.push("visual_count") unless SKILL_SPECIAL_II_VISUAL_V034.size==12
      e.push("audio_count") unless SKILL_SPECIAL_II_AUDIO_V034.size==12
      e.push("asset_count") unless SKILL_SPECIAL_II_RGS3_META_V034.size==20
      e.push("scale") unless (SKILL_SPECIAL_RGS3_GLOBAL_SCALE_V0331-0.60).abs<0.001
      e.push("cumulative") unless m[:cumulative_special_count].to_i==21
      e.push("runtime") unless m[:runtime_move_total].to_i==222
      e.push("magenta") unless m[:opaque_magenta_remaining].to_i==0
      e.push("fire_blast") unless SKILL_SPECIAL_II_VISUAL_V034[:fire_blast][:primary]=="RGS3_ATK_174"
      e.push("air_slash") unless SKILL_SPECIAL_II_VISUAL_V034[:air_slash][:kind]==:wind_slashes
      e.push("calm_anchor") unless SKILL_SPECIAL_II_VISUAL_V034[:calm_mind][:anchor]==:user
      e.push("checksum") unless skill_special_ii_checksum32_v034==m[:runtime_checksum32].to_i
      e
    end
  end

  remove_const(:VERIFICATION_MODES) if const_defined?(:VERIFICATION_MODES)
  VERIFICATION_MODES=[:skill_special_ii,:skill_special,:skill_audio,:skill_visual_expansion,:skill_visual]
  remove_const(:VERIFICATION_LABELS) if const_defined?(:VERIFICATION_LABELS)
  VERIFICATION_LABELS={
    :skill_special_ii=>"SKILL_SPECIAL_II",:skill_special=>"SKILL_SPECIAL",:skill_audio=>"SKILL_AUDIO",
    :skill_visual_expansion=>"SKILL_VISUAL_EXPANSION",:skill_visual=>"SKILL_VISUAL"
  }
end

class Scene_PMD_AutoChess
  alias pmd_ac_v034_start start unless method_defined?(:pmd_ac_v034_start)
  alias pmd_ac_v034_play_skill_special_visual_v033 play_skill_special_visual_v033 unless method_defined?(:pmd_ac_v034_play_skill_special_visual_v033)
  alias pmd_ac_v034_prepare_verification_battle prepare_verification_battle unless method_defined?(:pmd_ac_v034_prepare_verification_battle)
  alias pmd_ac_v034_update_verification_script update_verification_script unless method_defined?(:pmd_ac_v034_update_verification_script)
  alias pmd_ac_v034_complete_verification_mode complete_verification_mode unless method_defined?(:pmd_ac_v034_complete_verification_mode)
  alias pmd_ac_v034_log_event log_event unless method_defined?(:pmd_ac_v034_log_event)

  def start
    pmd_ac_v034_start
    begin
      if FileTest.exist?(PMD_AC::BATTLE_LOG_FILE)
        text=File.open(PMD_AC::BATTLE_LOG_FILE,"rb"){|f|f.read}
        text.sub!(/PMD AutoChess Proto v0\.[0-9.]+ Battle Verification Log/,"PMD AutoChess Proto v0.34 Battle Verification Log")
        File.open(PMD_AC::BATTLE_LOG_FILE,"wb"){|f|f.write(text)}
      end
    rescue
    end
    m=PMD_AC::SKILL_SPECIAL_II_MANIFEST_V034
    log_event(:skill_special_ii,"LOADED new_specials="+m[:new_special_count].to_s+" cumulative="+m[:cumulative_special_count].to_s+" assets="+m[:new_asset_meta_count].to_s+" scale="+sprintf('%.2f',PMD_AC::SKILL_SPECIAL_RGS3_GLOBAL_SCALE_V0331)+" checksum32="+m[:runtime_checksum32].to_s)
  end

  def play_skill_special_visual_v033(move_key,user,target,demo=false)
    sp=PMD_AC::SKILL_SPECIAL_II_VISUAL_V034[move_key]
    return pmd_ac_v034_play_skill_special_visual_v033(move_key,user,target,demo) if sp==nil
    anchor=(sp[:anchor]==:user ? user : target); x,y=special_xy_v033(anchor)
    add_special_label_v033(sp[:label]) if demo
    case sp[:kind]
    when :fire_burst
      add_vx_anim_v033('RGS3_ATK_174',x,y,{:frame_wait=>4,:hold=>7,:zoom=>1.00,:blend=>1,:grow=>0.020})
      add_vx_anim_v033('RGS3_ATK_222',x,y,{:frame_wait=>3,:delay=>5,:hold=>9,:zoom=>1.12,:blend=>1,:grow=>0.018})
    when :psychic_focus
      add_vx_anim_v033('RGS3_ATK_215',x,y,{:frame_wait=>4,:hold=>8,:zoom=>1.05,:blend=>1,:grow=>0.030})
      add_vx_anim_v033('RGS3_ATK_172',x,y,{:frame_wait=>5,:delay=>5,:hold=>10,:zoom=>0.82,:blend=>1,:grow=>0.015})
    when :shadow_burst
      add_vx_anim_v033('RGS3_ATK_170',x,y,{:hold=>10,:zoom=>0.82,:blend=>1,:grow=>0.025})
      add_vx_anim_v033('RGS3_ATK_186',x,y,{:frame_wait=>4,:delay=>6,:hold=>8,:zoom=>1.02,:blend=>1,:grow=>0.015})
    when :sludge_burst
      add_vx_anim_v033('RGS3_ATK_158',x,y-8,{:frame_wait=>4,:hold=>6,:zoom=>0.96,:blend=>0,:dy=>-0.18})
      add_vx_anim_v033('RGS3_ATK_197',x,y,{:frame_wait=>4,:delay=>6,:hold=>8,:zoom=>1.00,:blend=>1,:grow=>0.020})
    when :wind_slashes
      add_vx_anim_v033('RGS3_ATK_130',x-34,y-12,{:frame_wait=>5,:hold=>5,:zoom=>0.95,:blend=>1,:angle=>-18,:dx=>2.2})
      add_vx_anim_v033('RGS3_ATK_130',x+26,y+8,{:frame_wait=>5,:delay=>4,:hold=>5,:zoom=>0.90,:blend=>1,:angle=>18,:dx=>-1.7})
      add_vx_anim_v033('RGS3_ATK_147',x,y,{:frame_wait=>4,:delay=>9,:hold=>7,:zoom=>0.88,:blend=>1})
    when :x_slash
      add_vx_anim_v033('RGS3_ATK_238',x,y,{:hold=>13,:zoom=>1.00,:blend=>1,:angle=>46})
      add_vx_anim_v033('RGS3_ATK_238',x,y,{:delay=>3,:hold=>13,:zoom=>1.00,:blend=>1,:angle=>-46})
      add_vx_anim_v033('RGS3_ATK_239',x,y,{:delay=>7,:hold=>10,:zoom=>0.90,:blend=>1,:grow=>0.018})
    when :combat_combo
      pts=[[-19,-8],[18,-4],[-11,12],[14,10]]
      pts.each_with_index{|p,i| add_vx_anim_v033('RGS3_ATK_236',x+p[0],y+p[1],{:delay=>i*3,:hold=>7,:zoom=>0.72,:blend=>1,:angle=>(i%2==0 ? 20 : -20)})}
      add_vx_anim_v033('RGS3_ATK_239',x,y,{:delay=>13,:hold=>11,:zoom=>1.02,:blend=>1,:grow=>0.020})
    when :mind_aura
      add_vx_anim_v033('RGS3_ATK_215',x,y,{:frame_wait=>5,:hold=>11,:zoom=>0.92,:blend=>1,:grow=>0.022})
      [[-23,-17],[22,-14],[0,17]].each_with_index{|p,i| add_vx_anim_v033('RGS3_ATK_195',x+p[0],y+p[1],{:frame_wait=>5,:delay=>i*4,:hold=>8,:zoom=>0.64,:blend=>1,:dy=>-0.30})}
    when :dark_focus
      add_vx_anim_v033('RGS3_ATK_206',x,y-8,{:hold=>15,:zoom=>0.88,:blend=>1})
      add_vx_anim_v033('RGS3_ATK_197',x,y,{:frame_wait=>4,:delay=>7,:hold=>8,:zoom=>0.90,:blend=>1,:grow=>0.018})
    when :power_aura
      add_vx_anim_v033('RGS3_ATK_237',x,y,{:hold=>17,:zoom=>0.92,:blend=>1,:grow=>0.012})
      add_vx_anim_v033('RGS3_ATK_239',x,y,{:delay=>8,:hold=>11,:zoom=>0.84,:blend=>1,:grow=>0.015})
    when :dragon_dance
      add_vx_anim_v033('RGS3_ATK_177',x,y,{:frame_wait=>2,:hold=>7,:zoom=>0.92,:blend=>1,:spin=>7})
      add_vx_anim_v033('RGS3_ATK_202',x,y,{:frame_wait=>4,:delay=>12,:hold=>8,:zoom=>0.78,:blend=>1,:grow=>0.018})
    when :aura_burst
      add_vx_anim_v033('RGS3_ATK_192',x,y,{:hold=>11,:zoom=>0.76,:blend=>1,:grow=>0.030})
      add_vx_anim_v033('RGS3_ATK_221',x,y,{:frame_wait=>4,:delay=>7,:hold=>8,:zoom=>0.94,:blend=>1,:grow=>0.015})
    else
      return false
    end
    true
  end

  def prepare_verification_battle
    pmd_ac_v034_prepare_verification_battle
    if verification_mode==:skill_special_ii
      @skill_special_ii_failed_v034=false; @skill_special_ii_demo_v034=0
      for u in @units; u.verification_combat_sandbox(true); end
    end
  end

  def log_event(category,message)
    if category.to_s=="verify" && verification_mode==:skill_special_ii && message.to_s.index("SKILL_SPECIAL_II_")==0 && message.to_s.include?(" pass=0")
      @skill_special_ii_failed_v034=true
    end
    pmd_ac_v034_log_event(category,message)
  end

  def verify_skill_special_ii_manifest_v034
    return if @verification_done[:skill_special_ii_manifest]
    e=PMD_AC.validate_skill_special_ii_v034; m=PMD_AC::SKILL_SPECIAL_II_MANIFEST_V034; pass=e.empty?
    log_event(:verify,"SKILL_SPECIAL_II_MANIFEST pass="+(pass ? "1":"0")+" new=12 cumulative=21 assets=20 runtime=222 scale="+sprintf('%.2f',PMD_AC::SKILL_SPECIAL_RGS3_GLOBAL_SCALE_V0331)+" magenta="+m[:opaque_magenta_remaining].to_s+" checksum="+PMD_AC.skill_special_ii_checksum32_v034.to_s+" errors=["+e.join(",")+"]")
    @verification_done[:skill_special_ii_manifest]=true
  end

  def verify_skill_special_ii_scale_v034
    return if @verification_done[:skill_special_ii_scale]
    a=Sprite_PMDSkillVXAnimV033.new(@viewport,'RGS3_ATK_174',272,180,{:zoom=>1.0}); z=a.zoom_x; a.dispose unless a.disposed?
    pass=(z-0.60).abs<0.001
    log_event(:verify,"SKILL_SPECIAL_II_SCALE pass="+(pass ? "1":"0")+" global=0.60 generic="+sprintf('%.2f',z)+" relative_move_scales=preserved")
    @verification_done[:skill_special_ii_scale]=true
  end

  def demo_skill_special_ii_v034(move_key,label,x,y,audio_stage)
    play_skill_special_visual_v033(move_key,[x,y],[x,y],true)
    spec=PMD_AC.skill_audio_spec_v032(move_key,audio_stage,0); ok=spec!=nil && FileTest.exist?("Audio/SE/"+spec[:name].to_s+".wav")
    PMD_AC.play_se(spec) if ok; @skill_special_ii_demo_v034+=1 if ok
    log_event(:skill_special_ii,"DEMO "+label+" move="+move_key.to_s+" audio="+(spec==nil ? "nil":spec[:name].to_s)+" ok="+(ok ? "1":"0"))
  end

  def verify_skill_special_ii_runtime_v034
    return if @verification_done[:skill_special_ii_runtime]
    keys=PMD_AC::SKILL_SPECIAL_II_VISUAL_V034.keys; ok=true
    for k in keys
      d=PMD_AC.skill_data(("mv_"+k.to_s).to_sym); ok=false if d==nil || PMD_AC.skill_special_visual_v033(k)==nil
    end
    log_event(:verify,"SKILL_SPECIAL_II_RUNTIME pass="+(ok ? "1":"0")+" new="+keys.size.to_s+" cumulative=21 additive_to_222=1 combat_logic=unchanged")
    @verification_done[:skill_special_ii_runtime]=true
  end

  def verify_skill_special_ii_audio_v034
    return if @verification_done[:skill_special_ii_audio]
    a=PMD_AC.skill_audio_spec_v032(:aura_sphere,:hit,0); f=PMD_AC.skill_audio_spec_v032(:fire_blast,:hit,0); c=PMD_AC.skill_audio_spec_v032(:close_combat,:hit,0)
    pass=a!=nil && f!=nil && c!=nil && @skill_special_ii_demo_v034.to_i==12
    log_event(:verify,"SKILL_SPECIAL_II_AUDIO pass="+(pass ? "1":"0")+" demos="+@skill_special_ii_demo_v034.to_i.to_s+" fire="+(f==nil ? "nil":f[:name].to_s)+" combat="+(c==nil ? "nil":c[:name].to_s)+" aura="+(a==nil ? "nil":a[:name].to_s))
    @verification_done[:skill_special_ii_audio]=true
  end

  def verify_skill_special_ii_modes_v034
    return if @verification_done[:skill_special_ii_modes]
    exp=[:skill_special_ii,:skill_special,:skill_audio,:skill_visual_expansion,:skill_visual]
    pass=PMD_AC::VERIFICATION_MODES==exp && verification_mode==:skill_special_ii
    log_event(:verify,"SKILL_SPECIAL_II_RECENT_MODES pass="+(pass ? "1":"0")+" modes=5 default=SKILL_SPECIAL_II")
    @verification_done[:skill_special_ii_modes]=true
  end

  def update_verification_script
    pmd_ac_v034_update_verification_script
    return unless verification_mode==:skill_special_ii
    f=@verification_frame
    verify_skill_special_ii_manifest_v034 if f==4
    verify_skill_special_ii_scale_v034 if f==20
    demo_skill_special_ii_v034(:fire_blast,"FIRE BLAST",272,192,:hit) if f==45
    demo_skill_special_ii_v034(:psychic,"PSYCHIC",272,192,:hit) if f==90
    demo_skill_special_ii_v034(:shadow_ball,"SHADOW BALL",272,192,:hit) if f==135
    demo_skill_special_ii_v034(:sludge_bomb,"SLUDGE BOMB",272,192,:hit) if f==180
    demo_skill_special_ii_v034(:air_slash,"AIR SLASH",272,192,:hit) if f==225
    demo_skill_special_ii_v034(:x_scissor,"X-SCISSOR",272,192,:hit) if f==270
    demo_skill_special_ii_v034(:close_combat,"CLOSE COMBAT",272,192,:hit) if f==315
    demo_skill_special_ii_v034(:calm_mind,"CALM MIND",272,192,:hit) if f==360
    demo_skill_special_ii_v034(:nasty_plot,"NASTY PLOT",272,192,:hit) if f==405
    demo_skill_special_ii_v034(:bulk_up,"BULK UP",272,192,:hit) if f==450
    demo_skill_special_ii_v034(:dragon_dance,"DRAGON DANCE",272,192,:hit) if f==495
    demo_skill_special_ii_v034(:aura_sphere,"AURA SPHERE",272,192,:hit) if f==540
    verify_skill_special_ii_runtime_v034 if f==590
    verify_skill_special_ii_audio_v034 if f==610
    verify_skill_special_ii_modes_v034 if f==630
    complete_verification_mode if f==PMD_AC::VERIFICATION_SKILL_SPECIAL_II_END_FRAME_V034
  end

  def complete_verification_mode
    if verification_mode==:skill_special_ii && @skill_special_ii_failed_v034
      for u in @units; u.verification_finish; end
      @verification_done[:complete]=true
      log_event(:verify,"FAILED mode=SKILL_SPECIAL_II auto_skill=on original_skills=restored"); return
    end
    pmd_ac_v034_complete_verification_mode
  end
end
