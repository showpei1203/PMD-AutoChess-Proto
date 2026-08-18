#==============================================================================
# 【PMD AutoChess 中文維護說明】
# 腳本：PMD AutoChess Proto v0.31
# 分類：核心戰鬥 Runtime
#
# 【用途／機制】
# 承接前序 Data／Config，實際執行戰鬥 Scene、Unit、AI、技能與呈現。
#
# 【怎麼調整】
# 一般平衡與資料調整不要直接改 Runtime；若要追加功能，建議在較後腳本 alias 原方法後擴充。
#
# 【本腳本主要設定常數／資料表】
# - VERIFICATION_SKILL_VISUAL_EXPANSION_END_FRAME / VERIFICATION_MODES / VERIFICATION_LABELS
#
# 【Runtime 主要方法（查流程時可直接搜尋）】
# - skill_visual_manifest_v031 / skill_visual_move_profile_v031 / skill_visual_beam_profile_v030 / skill_visual_projectile_profile_v030
# - skill_visual_impact_profile_v030 / skill_visual_move_profile_v030 / skill_visual_scalar_v031 / skill_visual_checksum32_v031
# - validate_skill_visual_v031 / update_geometry / bitmap_for / start
#
# 【維護規則】
# - RPG Maker VX / RGSS2 / Ruby 1.8 相容。
# - instance_uid 才是 Pokémon 個體身份；Actor ID 只是容器。
# - 新增行為優先沿用既有 helper／Data 表；避免破壞已 Freeze 的舊核心。
# - 本專案新腳本也必須保留同等級的中文說明與實際範例。
#==============================================================================
#==============================================================================
# ■ PMD AutoChess Proto v0.31
#    Skill Visual Expansion I - 18 Type Grammar + 222 Runtime Move Coverage
#------------------------------------------------------------------------------
#  Additive visual-only layer on verified v0.30. Existing combat calculations,
#  collision, tracking, Active Evade and move behavior data are not replaced.
#==============================================================================
module PMD_AC
  VERIFICATION_SKILL_VISUAL_EXPANSION_END_FRAME = 460

  class << self
    alias pmd_ac_v031_beam_profile skill_visual_beam_profile_v030 unless method_defined?(:pmd_ac_v031_beam_profile)
    alias pmd_ac_v031_projectile_profile skill_visual_projectile_profile_v030 unless method_defined?(:pmd_ac_v031_projectile_profile)
    alias pmd_ac_v031_impact_profile skill_visual_impact_profile_v030 unless method_defined?(:pmd_ac_v031_impact_profile)
    alias pmd_ac_v031_move_profile skill_visual_move_profile_v030 unless method_defined?(:pmd_ac_v031_move_profile)

    def skill_visual_manifest_v031; SKILL_VISUAL_MANIFEST_V031; end
    def skill_visual_move_profile_v031(move_key); SKILL_VISUAL_MOVE_V031[move_key]; end

    def skill_visual_beam_profile_v030(style)
      p=SKILL_VISUAL_BEAM_V031[style];return p if p!=nil;pmd_ac_v031_beam_profile(style)
    end
    def skill_visual_projectile_profile_v030(style)
      p=SKILL_VISUAL_PROJECTILE_V031[style];return p if p!=nil;pmd_ac_v031_projectile_profile(style)
    end
    def skill_visual_impact_profile_v030(style)
      p=SKILL_VISUAL_IMPACT_V031[style];return p if p!=nil;pmd_ac_v031_impact_profile(style)
    end
    def skill_visual_move_profile_v030(move_key)
      p=SKILL_VISUAL_MOVE_V031[move_key];return p if p!=nil;pmd_ac_v031_move_profile(move_key)
    end

    def skill_visual_scalar_v031(v)
      return "" if v==nil
      return v ? "true" : "false" if v==true || v==false
      if v.is_a?(Float)
        s=sprintf("%.8g",v);s += ".0" unless s.include?(".") || s.include?("e") || s.include?("E");return s
      end
      v.to_s
    end
    def skill_visual_checksum32_v031
      h=0
      groups=[["B",SKILL_VISUAL_BEAM_V031],["P",SKILL_VISUAL_PROJECTILE_V031],["I",SKILL_VISUAL_IMPACT_V031],["M",SKILL_VISUAL_MOVE_V031]]
      for pair in groups
        prefix=pair[0];group=pair[1]
        for key in group.keys.sort{|a,b|a.to_s<=>b.to_s}
          r=group[key]
          fields=r.keys.sort{|a,b|a.to_s<=>b.to_s}.collect{|f|f.to_s+"="+skill_visual_scalar_v031(r[f])}
          text=([prefix,key.to_s]+fields).join("|")
          text.each_byte{|by|h=((h*33)+by)&0x7fffffff}
        end
      end
      h
    end
    def validate_skill_visual_v031
      e=[];m=SKILL_VISUAL_MANIFEST_V031
      e.push("beam_count") unless SKILL_VISUAL_BEAM_V031.size==8
      e.push("projectile_count") unless SKILL_VISUAL_PROJECTILE_V031.size==20
      e.push("impact_count") unless SKILL_VISUAL_IMPACT_V031.size==23
      e.push("move_count") unless SKILL_VISUAL_MOVE_V031.size==222
      e.push("type_styles") unless SKILL_VISUAL_TYPE_STYLES_V031.size==18
      e.push("water_head") unless SKILL_VISUAL_BEAM_V031[:water][:head]=="Ranger_109"
      e.push("electric_jitter") unless SKILL_VISUAL_BEAM_V031[:electric][:motion]==:jitter
      e.push("signal_wave") unless SKILL_VISUAL_BEAM_V031[:signal][:motion]==:oscillate
      e.push("thunder_target") unless SKILL_VISUAL_MOVE_V031[:thunder][:visual_kind]==:target_hit && SKILL_VISUAL_MOVE_V031[:thunder][:hide_logical_projectile]
      e.push("tackle_contact") unless SKILL_VISUAL_MOVE_V031[:tackle][:visual_kind]==:contact_hit
      e.push("hyper_voice_area") unless SKILL_VISUAL_MOVE_V031[:hyper_voice][:visual_kind]==:area_hit && SKILL_VISUAL_MOVE_V031[:hyper_voice][:style]==:sound
      e.push("swords_dance_self") unless SKILL_VISUAL_MOVE_V031[:swords_dance][:visual_kind]==:self_fx
      e.push("checksum") unless skill_visual_checksum32_v031==m[:runtime_checksum32].to_i
      e
    end
  end

  remove_const(:VERIFICATION_MODES) if const_defined?(:VERIFICATION_MODES)
  VERIFICATION_MODES=[:normal,:control,:beam,:zone,:hit,:energy,:direction,:object,:summon,:identity,
    :progression,:individual,:mega,:synergy,:species_db,:move_db,:move_runtime,:stat_stage,:sustain,
    :secondary,:speed_status,:action_status,:ability,:ability_trigger,:ability_passive,:accuracy_evasion,
    :weather,:weather_visual,:skill_visual,:skill_visual_expansion]
  remove_const(:VERIFICATION_LABELS) if const_defined?(:VERIFICATION_LABELS)
  VERIFICATION_LABELS={:normal=>"NORMAL",:control=>"CONTROL",:beam=>"BEAM",:zone=>"ZONE",:hit=>"HIT",
    :energy=>"ENERGY",:direction=>"DIRECTION",:object=>"OBJECT",:summon=>"SUMMON",:identity=>"IDENTITY",
    :progression=>"PROGRESSION",:individual=>"INDIVIDUAL",:mega=>"MEGA",:synergy=>"SYNERGY",
    :species_db=>"SPECIES_DB",:move_db=>"MOVE_DB",:move_runtime=>"MOVE_RUNTIME",:stat_stage=>"STAT_STAGE",
    :sustain=>"SUSTAIN",:secondary=>"SECONDARY",:speed_status=>"SPEED_STATUS",:action_status=>"ACTION_STATUS",
    :ability=>"ABILITY",:ability_trigger=>"ABILITY_TRIGGER",:ability_passive=>"ABILITY_PASSIVE",
    :accuracy_evasion=>"ACCURACY_EVASION",:weather=>"WEATHER",:weather_visual=>"WEATHER_VISUAL",
    :skill_visual=>"SKILL_VISUAL",:skill_visual_expansion=>"SKILL_VISUAL_EXPANSION"}
end

# Additional beam motion without replacing the v0.30 geometry engine.
class PMD_AC_SkillBeamVisualV030
  alias pmd_ac_v031_update_geometry update_geometry unless method_defined?(:pmd_ac_v031_update_geometry)
  def update_geometry
    pmd_ac_v031_update_geometry
    return if @profile==nil || @body==nil
    base=(@profile[:thickness]||0.55).to_f
    case @profile[:motion]
    when :pulse
      seq=[0.90,1.00,1.10,1.00];@body.zoom_y=base*seq[Graphics.frame_count % 4]
    when :oscillate
      seq=[0.88,1.02,1.12,1.02];@body.zoom_y=base*seq[Graphics.frame_count % 4]
      @body.opacity=[220,240,255,240][Graphics.frame_count % 4]
    when :rigid
      @body.zoom_y=base
    end
  end
end

# Extend projectile trail palette to all 18 types plus sound.
class Sprite_PMDSkillTrailV030
  class << self
    alias pmd_ac_v031_bitmap_for bitmap_for unless method_defined?(:pmd_ac_v031_bitmap_for)
    def bitmap_for(style)
      return pmd_ac_v031_bitmap_for(style) if [:fire,:water,:electric,:seed].include?(style)
      old=class_variable_get(:@@bitmaps)
      return old[style] if old[style]!=nil && !old[style].disposed?
      rgb=case style
      when :normal;[225,220,190]
      when :grass;[95,210,95]
      when :ice,:aurora;[125,225,255]
      when :fighting;[235,150,95]
      when :poison;[180,85,220]
      when :ground,:rock;[190,145,75]
      when :flying;[170,225,255]
      when :psychic,:psychic_beam;[245,100,220]
      when :bug,:signal;[165,215,80]
      when :ghost;[135,95,200]
      when :dragon;[110,130,255]
      when :dark;[105,90,125]
      when :steel,:steel_beam;[195,210,220]
      when :fairy;[255,155,220]
      when :sound;[210,120,255]
      else;[220,235,255]
      end
      b=Bitmap.new(12,12);c=Color.new(rgb[0],rgb[1],rgb[2],185)
      b.fill_rect(3,3,6,6,Color.new(c.red,c.green,c.blue,65));b.fill_rect(4,4,4,4,c);old[style]=b;b
    end
  end
end

class Scene_PMD_AutoChess
  alias pmd_ac_v031_start start unless method_defined?(:pmd_ac_v031_start)
  alias pmd_ac_v031_projectile_style projectile_style unless method_defined?(:pmd_ac_v031_projectile_style)
  alias pmd_ac_v031_launch_projectile launch_projectile unless method_defined?(:pmd_ac_v031_launch_projectile)
  alias pmd_ac_v031_apply_skill_effects apply_skill_effects unless method_defined?(:pmd_ac_v031_apply_skill_effects)
  alias pmd_ac_v031_prepare_verification_battle prepare_verification_battle unless method_defined?(:pmd_ac_v031_prepare_verification_battle)
  alias pmd_ac_v031_update_verification_script update_verification_script unless method_defined?(:pmd_ac_v031_update_verification_script)
  alias pmd_ac_v031_complete_verification_mode complete_verification_mode unless method_defined?(:pmd_ac_v031_complete_verification_mode)
  alias pmd_ac_v031_log_event log_event unless method_defined?(:pmd_ac_v031_log_event)

  def start
    pmd_ac_v031_start
    begin
      if FileTest.exist?(PMD_AC::BATTLE_LOG_FILE)
        text=File.open(PMD_AC::BATTLE_LOG_FILE,"rb"){|f|f.read}
        text.sub!(/PMD AutoChess Proto v0\.[0-9.]+ Battle Verification Log/,"PMD AutoChess Proto v0.31 Battle Verification Log")
        File.open(PMD_AC::BATTLE_LOG_FILE,"wb"){|f|f.write(text)}
      end
    rescue
    end
    m=PMD_AC.skill_visual_manifest_v031
    log_event(:skill_visual_expansion,"LOADED runtime_moves="+m[:mapped_move_visual_count].to_s+"/"+m[:runtime_move_total].to_s+" coverage="+sprintf("%.2f",m[:runtime_visual_coverage_percent].to_f)+"% beams="+m[:beam_profile_count].to_s+" projectiles="+m[:projectile_profile_count].to_s+" impacts="+m[:impact_profile_count].to_s+" types="+m[:type_style_count].to_s+" assets="+m[:asset_count].to_s+" checksum32="+m[:runtime_checksum32].to_s)
  end

  # Weather Ball must look like its effective weather type, not permanent Normal.
  def projectile_style(user,kind,effect_type)
    if effect_type!=nil
      data=PMD_AC.skill_data(effect_type)
      if data!=nil && data[:canonical_move_key]==:weather_ball && respond_to?(:canonical_weather_adjust_skill_data)
        d=canonical_weather_adjust_skill_data(data);return d[:move_type] if d!=nil && d[:move_type]!=nil
      end
    end
    pmd_ac_v031_projectile_style(user,kind,effect_type)
  end

  # Some canonical moves use projectile collision internally for range/accuracy,
  # but visually belong entirely on the target (Thunder, Hypnosis, etc.).
  def launch_projectile(user,target,kind,power,effect_type,tracking_override=nil,attack_modifier=nil,allow_substitute=true)
    data=effect_type==nil ? nil : PMD_AC.skill_data(effect_type);visual=nil
    visual=PMD_AC.skill_visual_move_profile_v031(data[:canonical_move_key]) if data!=nil && data[:canonical_move_key]!=nil
    before=@projectile_sprites.size
    pmd_ac_v031_launch_projectile(user,target,kind,power,effect_type,tracking_override,attack_modifier,allow_substitute)
    if visual!=nil && visual[:hide_logical_projectile] && @projectile_sprites.size>before
      p=@projectile_sprites[-1];p.visible=false;p.instance_variable_set(:@pmd_skill_visual_hidden_v031,true)
      log_event(:skill_visual_expansion,user.log_name+" TARGET_ONLY move="+data[:canonical_move_key].to_s+" logical_projectile=hidden")
    end
  end

  def apply_skill_effects(user,target,data,multiplier=1.0)
    if data!=nil && data[:canonical_move_key]!=nil
      visual=PMD_AC.skill_visual_move_profile_v031(data[:canonical_move_key])
      if visual!=nil && [:contact_hit,:area_hit,:self_fx].include?(visual[:visual_kind])
        obj=(visual[:visual_kind]==:self_fx ? user : target)
        if obj!=nil
          add_vfx_impact(obj,visual[:style])
          log_event(:skill_visual_expansion,user.log_name+" "+visual[:visual_kind].to_s.upcase+" move="+data[:canonical_move_key].to_s+" style="+visual[:style].to_s+" target="+(obj.respond_to?(:log_name) ? obj.log_name : "POINT"))
        end
      end
    end
    pmd_ac_v031_apply_skill_effects(user,target,data,multiplier)
  end

  def prepare_verification_battle
    pmd_ac_v031_prepare_verification_battle
    if verification_mode==:skill_visual_expansion
      @skill_visual_expansion_failed_v031=false
      for u in @units;u.verification_combat_sandbox(true);end
    end
  end
  def log_event(category,message)
    if category.to_s=="verify" && verification_mode==:skill_visual_expansion && message.to_s.index("SKILL_VISUAL_EXPANSION_")==0 && message.to_s.include?(" pass=0")
      @skill_visual_expansion_failed_v031=true
    end
    pmd_ac_v031_log_event(category,message)
  end

  def skill_visual_expansion_manifest_v031
    return if @verification_done[:skill_visual_expansion_manifest]
    e=PMD_AC.validate_skill_visual_v031;m=PMD_AC.skill_visual_manifest_v031;pass=e.empty?
    log_event(:verify,"SKILL_VISUAL_EXPANSION_MANIFEST pass="+(pass ? "1":"0")+" moves="+m[:mapped_move_visual_count].to_s+"/"+m[:runtime_move_total].to_s+" coverage="+sprintf("%.2f",m[:runtime_visual_coverage_percent].to_f)+"% types="+m[:type_style_count].to_s+" beams="+m[:beam_profile_count].to_s+" projectiles="+m[:projectile_profile_count].to_s+" impacts="+m[:impact_profile_count].to_s+" assets="+m[:asset_count].to_s+" checksum="+PMD_AC.skill_visual_checksum32_v031.to_s+" errors=["+e.join(",")+"]")
    @verification_done[:skill_visual_expansion_manifest]=true
  end
  def skill_visual_expansion_beams_v031
    return if @verification_done[:skill_visual_expansion_beams]
    styles=[:aurora,:psychic_beam,:signal,:steel_beam];ok=true
    styles.each_with_index{|s,i|p=PMD_AC.skill_visual_beam_profile_v030(s);ok=false if p==nil;add_skill_visual_beam_v030([88,118+i*54],[452,118+i*54],s,36,nil) if p!=nil}
    log_event(:verify,"SKILL_VISUAL_EXPANSION_BEAMS pass="+(ok ? "1":"0")+" styles=aurora,psychic_beam,signal,steel_beam motions=pulse,pulse,oscillate,rigid")
    @verification_done[:skill_visual_expansion_beams]=true
  end
  def skill_visual_expansion_projectiles_v031
    return if @verification_done[:skill_visual_expansion_projectiles]
    styles=[:grass,:psychic,:ghost,:rock,:flying,:dragon];ok=true
    styles.each_with_index{|s,i|p=PMD_AC.skill_visual_projectile_profile_v030(s);ok=false if p==nil;@effect_sprites.push(Sprite_PMDSkillDemoProjectileV030.new(@viewport,self,88,100+i*42,456,100+i*42,s)) if p!=nil}
    log_event(:verify,"SKILL_VISUAL_EXPANSION_PROJECTILES pass="+(ok ? "1":"0")+" styles=grass,psychic,ghost,rock,flying,dragon trail_palette=18_type")
    @verification_done[:skill_visual_expansion_projectiles]=true
  end
  def skill_visual_expansion_impacts_v031
    return if @verification_done[:skill_visual_expansion_impacts]
    styles=[:normal,:fighting,:poison,:ground,:bug,:dark,:steel,:fairy];ok=true
    styles.each_with_index{|s,i|p=PMD_AC.skill_visual_impact_profile_v030(s);ok=false if p==nil;add_vfx_impact_xy(72+(i%4)*132,150+(i/4)*100,s,0) if p!=nil}
    log_event(:verify,"SKILL_VISUAL_EXPANSION_IMPACTS pass="+(ok ? "1":"0")+" styles=normal,fighting,poison,ground,bug,dark,steel,fairy")
    @verification_done[:skill_visual_expansion_impacts]=true
  end
  def skill_visual_expansion_mapping_v031
    return if @verification_done[:skill_visual_expansion_mapping]
    m=PMD_AC::SKILL_VISUAL_MOVE_V031;counts=Hash.new(0);m.each_value{|v|counts[v[:visual_kind]]+=1}
    pass=m.size==222 && counts[:projectile]==75 && counts[:contact_hit]==73 && counts[:self_fx]==36 && counts[:area_hit]==21 && counts[:beam]==11 && counts[:target_hit]==6
    log_event(:verify,"SKILL_VISUAL_EXPANSION_MAPPING pass="+(pass ? "1":"0")+" total="+m.size.to_s+" beam="+counts[:beam].to_s+" projectile="+counts[:projectile].to_s+" contact="+counts[:contact_hit].to_s+" area="+counts[:area_hit].to_s+" self="+counts[:self_fx].to_s+" target="+counts[:target_hit].to_s)
    @verification_done[:skill_visual_expansion_mapping]=true
  end
  def skill_visual_expansion_semantics_v031
    return if @verification_done[:skill_visual_expansion_semantics]
    t=PMD_AC.skill_data(:mv_tackle);h=PMD_AC.skill_data(:mv_hyper_voice);s=PMD_AC.skill_data(:mv_swords_dance);r=PMD_AC.skill_data(:mv_rock_throw);p=PMD_AC.skill_data(:mv_psybeam);th=PMD_AC.skill_data(:mv_thunder)
    pass=t[:visual_kind]==:contact_hit && h[:visual_kind]==:area_hit && h[:visual_style]==:sound && s[:visual_kind]==:self_fx && r[:visual_kind]==:projectile && r[:visual_style]==:rock && p[:visual_kind]==:beam && p[:visual_style]==:psychic_beam && th[:visual_kind]==:target_hit
    log_event(:verify,"SKILL_VISUAL_EXPANSION_SEMANTICS pass="+(pass ? "1":"0")+" tackle=contact hyper_voice=area_sound swords_dance=self rock_throw=projectile psybeam=beam thunder=target_only")
    @verification_done[:skill_visual_expansion_semantics]=true
  end
  def skill_visual_expansion_weather_ball_v031
    return if @verification_done[:skill_visual_expansion_weather_ball]
    data=PMD_AC.skill_data(:mv_weather_ball);clear_canonical_weather(:verify_visual) if respond_to?(:clear_canonical_weather);a=projectile_style(nil,nil,:mv_weather_ball)
    set_canonical_weather(:sun,nil,5,false) if respond_to?(:set_canonical_weather);b=projectile_style(nil,nil,:mv_weather_ball)
    set_canonical_weather(:rain,nil,5,false) if respond_to?(:set_canonical_weather);c=projectile_style(nil,nil,:mv_weather_ball)
    clear_canonical_weather(:verify_visual) if respond_to?(:clear_canonical_weather)
    pass=a==:normal && b==:fire && c==:water
    log_event(:verify,"SKILL_VISUAL_EXPANSION_WEATHER_BALL pass="+(pass ? "1":"0")+" clear="+a.to_s+" sun="+b.to_s+" rain="+c.to_s)
    @verification_done[:skill_visual_expansion_weather_ball]=true
  end
  def skill_visual_expansion_regression_v031
    return if @verification_done[:skill_visual_expansion_regression]
    w=PMD_AC.skill_visual_beam_profile_v030(:water);e=PMD_AC.skill_visual_beam_profile_v030(:electric);f=PMD_AC.skill_visual_projectile_profile_v030(:fire);i=PMD_AC.skill_visual_impact_profile_v030(:ice)
    pass=w[:body]=="Ranger_105" && w[:head]=="Ranger_109" && e[:body]=="Ranger_098" && e[:motion]==:jitter && f[:sheet]=="Ranger_174" && i[:sheet]=="Ranger_221"
    log_event(:verify,"SKILL_VISUAL_EXPANSION_REGRESSION pass="+(pass ? "1":"0")+" v030_water=105/109 electric=098 fire_projectile=174 ice_impact=221")
    @verification_done[:skill_visual_expansion_regression]=true
  end
  def update_verification_script
    pmd_ac_v031_update_verification_script
    return unless verification_mode==:skill_visual_expansion
    f=@verification_frame
    skill_visual_expansion_manifest_v031 if f==4
    skill_visual_expansion_beams_v031 if f==40
    skill_visual_expansion_projectiles_v031 if f==110
    skill_visual_expansion_impacts_v031 if f==190
    skill_visual_expansion_mapping_v031 if f==270
    skill_visual_expansion_semantics_v031 if f==320
    skill_visual_expansion_weather_ball_v031 if f==365
    skill_visual_expansion_regression_v031 if f==410
    complete_verification_mode if f==PMD_AC::VERIFICATION_SKILL_VISUAL_EXPANSION_END_FRAME
  end
  def complete_verification_mode
    if verification_mode==:skill_visual_expansion && @skill_visual_expansion_failed_v031
      for u in @units;u.verification_finish;end
      @verification_done[:complete]=true
      log_event(:verify,"FAILED mode=SKILL_VISUAL_EXPANSION auto_skill=on original_skills=restored");return
    end
    pmd_ac_v031_complete_verification_mode
  end
end
