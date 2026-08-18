#==============================================================================
# 【PMD AutoChess 中文維護說明】
# 腳本：PMD AutoChess Proto v0.33
# 分類：核心戰鬥 Runtime
#
# 【用途／機制】
# 承接前序 Data／Config，實際執行戰鬥 Scene、Unit、AI、技能與呈現。
#
# 【怎麼調整】
# 一般平衡與資料調整不要直接改 Runtime；若要追加功能，建議在較後腳本 alias 原方法後擴充。
#
# 【本腳本主要設定常數／資料表】
# - SKILL_SPECIAL_RGS3_FOLDER_V033 / VERIFICATION_SKILL_SPECIAL_END_FRAME_V033 / SKILL_IMPACT_FIRST_WAIT_V033 / SKILL_IMPACT_LAST_HOLD_V033
# - VERIFICATION_MODES / VERIFICATION_LABELS
#
# 【Runtime 主要方法（查流程時可直接搜尋）】
# - skill_special_manifest_v033 / skill_special_visual_v033 / skill_special_rgs3_meta_v033 / skill_special_rgs3_bitmap_v033
# - skill_audio_spec_v032 / skill_special_scalar_v033 / skill_special_checksum32_v033 / validate_skill_special_v033
# - initialize / update / update_src_v033 / dispose
#
# 【維護規則】
# - RPG Maker VX / RGSS2 / Ruby 1.8 相容。
# - instance_uid 才是 Pokémon 個體身份；Actor ID 只是容器。
# - 新增行為優先沿用既有 helper／Data 表；避免破壞已 Freeze 的舊核心。
# - 本專案新腳本也必須保留同等級的中文說明與實際範例。
#==============================================================================
#==============================================================================
# ■ PMD AutoChess Proto v0.33
#    Skill Visual + Audio Specialization I
#------------------------------------------------------------------------------
#  Additive presentation layer on verified v0.32.
#  Uses the user's 192px-cell VX animation sheets (RGS3_ATK_###) directly.
#  Damage, targeting, accuracy, projectile collision and status semantics remain
#  untouched. Latest verification is first; S cycles only the latest 5 modes.
#==============================================================================
module PMD_AC
  SKILL_SPECIAL_RGS3_FOLDER_V033 = "Graphics/Animations/"
  VERIFICATION_SKILL_SPECIAL_END_FRAME_V033 = 590
  SKILL_IMPACT_FIRST_WAIT_V033 = 3
  SKILL_IMPACT_LAST_HOLD_V033 = 6

  class << self
    alias pmd_ac_v033_skill_audio_spec_v032 skill_audio_spec_v032 unless method_defined?(:pmd_ac_v033_skill_audio_spec_v032)

    def skill_special_manifest_v033; SKILL_SPECIAL_MANIFEST_V033; end
    def skill_special_visual_v033(move_key); SKILL_SPECIAL_VISUAL_V033[move_key]; end
    def skill_special_rgs3_meta_v033(name); SKILL_SPECIAL_RGS3_META_V033[name.to_s]; end
    def skill_special_rgs3_bitmap_v033(name); Cache.load_bitmap(SKILL_SPECIAL_RGS3_FOLDER_V033,name.to_s); end

    def skill_audio_spec_v032(move_key,stage,variant_index=0)
      ov=SKILL_SPECIAL_AUDIO_V033[move_key]
      if ov!=nil
        field=(stage.to_s+"_cat").to_sym
        if ov.has_key?(field)
          cat=ov[field]
          return nil if cat==nil
          pool=skill_audio_category_pool_v032(cat)
          return nil if pool==nil || pool.empty?
          idx=variant_index.to_i % pool.size
          name=pool[idx]
          style=ov[:audio_style] || :normal
          volume=SKILL_AUDIO_VOLUME_V032[stage] || 80
          pitch=SKILL_AUDIO_PITCH_V032[style] || 100
          return {:name=>name,:volume=>volume,:pitch=>pitch}
        end
      end
      pmd_ac_v033_skill_audio_spec_v032(move_key,stage,variant_index)
    end

    def skill_special_scalar_v033(v)
      return "" if v==nil
      return v ? "true" : "false" if v==true || v==false
      v.to_s
    end

    def skill_special_checksum32_v033
      h=0
      groups=[["V",SKILL_SPECIAL_VISUAL_V033],["G",SKILL_SPECIAL_RGS3_META_V033],["A",SKILL_SPECIAL_AUDIO_V033]]
      for pair in groups
        prefix=pair[0]; group=pair[1]
        for key in group.keys.sort{|a,b|a.to_s<=>b.to_s}
          r=group[key]
          fields=r.keys.sort{|a,b|a.to_s<=>b.to_s}.collect{|f|f.to_s+"="+skill_special_scalar_v033(r[f])}
          text=([prefix,key.to_s]+fields).join("|")
          text.each_byte{|by|h=((h*33)+by)&0x7fffffff}
        end
      end
      h
    end

    def validate_skill_special_v033
      e=[]; m=SKILL_SPECIAL_MANIFEST_V033
      e.push("visual_count") unless SKILL_SPECIAL_VISUAL_V033.size==9
      e.push("audio_count") unless SKILL_SPECIAL_AUDIO_V033.size==9
      e.push("asset_count") unless SKILL_SPECIAL_RGS3_META_V033.size==13
      e.push("rgs3_count") unless m[:rgs3_sheet_count].to_i==256
      e.push("sfx_alias") unless m[:sfx_alias_count].to_i==50 && m[:sfx_alias_missing].to_i==0
      e.push("magenta") unless m[:opaque_magenta_remaining].to_i==0
      e.push("thunder") unless SKILL_SPECIAL_VISUAL_V033[:thunder][:primary]=="RGS3_ATK_208"
      e.push("rock_slide") unless SKILL_SPECIAL_VISUAL_V033[:rock_slide][:kind]==:rock_fall
      e.push("dark_anchor") unless SKILL_SPECIAL_VISUAL_V033[:dark_pulse][:anchor]==:user
      e.push("checksum") unless skill_special_checksum32_v033==m[:runtime_checksum32].to_i
      e
    end
  end

  remove_const(:VERIFICATION_MODES) if const_defined?(:VERIFICATION_MODES)
  VERIFICATION_MODES=[:skill_special,:skill_audio,:skill_visual_expansion,:skill_visual,:weather_visual]
  remove_const(:VERIFICATION_LABELS) if const_defined?(:VERIFICATION_LABELS)
  VERIFICATION_LABELS={
    :skill_special=>"SKILL_SPECIAL",:skill_audio=>"SKILL_AUDIO",
    :skill_visual_expansion=>"SKILL_VISUAL_EXPANSION",:skill_visual=>"SKILL_VISUAL",
    :weather_visual=>"WEATHER_VISUAL"
  }
end

#==============================================================================
# ■ Short Impact Readability Pass
#==============================================================================
class Sprite_PMDSkillImpactV030
  alias pmd_ac_v033_initialize initialize unless method_defined?(:pmd_ac_v033_initialize)
  def initialize(viewport,x,y,style,delay=0)
    pmd_ac_v033_initialize(viewport,x,y,style,delay)
    @pmd_v033_hold=PMD_AC::SKILL_IMPACT_LAST_HOLD_V033
    unless @finished
      base=(@profile==nil ? PMD_AC::SKILL_IMPACT_FIRST_WAIT_V033 : (@profile[:frame_wait]||PMD_AC::SKILL_IMPACT_FIRST_WAIT_V033)).to_i
      @wait=[base,PMD_AC::SKILL_IMPACT_FIRST_WAIT_V033].max
    end
  end
  def update
    super
    return if @finished
    if @delay>0
      @delay-=1; self.visible=true if @delay<=0; return
    end
    @wait-=1; return if @wait>0
    last=[@profile[:frames].to_i-1,0].max
    if @frame>=last && @pmd_v033_hold.to_i>0
      @pmd_v033_hold-=1; @wait=1; return
    end
    @frame+=1; @wait=[(@profile[:frame_wait]||3).to_i,1].max
    if @frame>=@profile[:frames].to_i
      @finished=true; self.visible=false; return
    end
    update_src
  end
end

#==============================================================================
# ■ VX 192px-cell animation sprite
#==============================================================================
class Sprite_PMDSkillVXAnimV033 < Sprite
  attr_reader :finished
  def initialize(viewport,name,x,y,opts=nil)
    super(viewport); opts={} if opts==nil
    @meta=PMD_AC.skill_special_rgs3_meta_v033(name); @finished=false
    if @meta==nil; @finished=true; self.visible=false; return; end
    @cells=@meta[:cells_csv].to_s.split(',').collect{|s|s.to_i}; @cells=[0] if @cells.empty?
    @frame=0; @wait=[(opts[:frame_wait]||3).to_i,1].max; @frame_wait=@wait
    @delay=[(opts[:delay]||0).to_i,0].max; @hold=[(opts[:hold]||5).to_i,0].max
    @life=(opts[:life]||0).to_i; @age=0
    @dx=(opts[:dx]||0.0).to_f; @dy=(opts[:dy]||0.0).to_f
    @grow=(opts[:grow]||0.0).to_f; @spin=(opts[:spin]||0.0).to_f
    self.bitmap=PMD_AC.skill_special_rgs3_bitmap_v033(name); self.ox=96; self.oy=96
    self.x=x.to_i; self.y=y.to_i; self.z=(opts[:z]||9290).to_i
    self.zoom_x=(opts[:zoom]||1.0).to_f; self.zoom_y=self.zoom_x
    self.angle=(opts[:angle]||0.0).to_f; self.blend_type=(opts[:blend]||1).to_i
    self.opacity=(opts[:opacity]||255).to_i; self.visible=(@delay<=0); update_src_v033
  end
  def update_src_v033
    idx=@cells[@frame % @cells.size]; col=idx%5; row=idx/5
    self.src_rect.set(col*192,row*192,192,192)
  end
  def update
    super; return if @finished
    if @delay>0; @delay-=1; self.visible=true if @delay<=0; return; end
    @age+=1; self.x=(self.x+@dx).to_i; self.y=(self.y+@dy).to_i
    self.angle+=@spin; self.zoom_x+=@grow; self.zoom_y+=@grow
    @wait-=1
    if @wait<=0
      if @frame<@cells.size-1
        @frame+=1; update_src_v033; @wait=@frame_wait
      elsif @hold>0
        @hold-=1; @wait=1
      elsif @life<=0 || @age>=@life
        @finished=true; self.visible=false
      end
    end
    if @life>0 && @age>=@life && @frame>=@cells.size-1 && @hold<=0
      @finished=true; self.visible=false
    end
  end
end

class Sprite_PMDSkillVXFallingRockV033 < Sprite
  attr_reader :finished
  def initialize(viewport,scene,name,x,ground_y,delay,zoom,spin)
    super(viewport); @scene=scene; @name=name; @ground_y=ground_y.to_f; @delay=delay.to_i
    @vy=1.7; @gravity=0.45; @spin=spin.to_f; @finished=false
    meta=PMD_AC.skill_special_rgs3_meta_v033(name); cells=meta[:cells_csv].to_s.split(','); idx=(cells.empty? ? 0 : cells[0].to_i)
    self.bitmap=PMD_AC.skill_special_rgs3_bitmap_v033(name); self.src_rect.set((idx%5)*192,(idx/5)*192,192,192)
    self.ox=96; self.oy=96; self.x=x.to_i; self.y=(ground_y-95-delay*2).to_i
    self.zoom_x=zoom.to_f; self.zoom_y=zoom.to_f; self.z=9288; self.visible=(@delay<=0)
  end
  def update
    super; return if @finished
    if @delay>0; @delay-=1; self.visible=true if @delay<=0; return; end
    @vy+=@gravity; self.y=(self.y+@vy).to_i; self.angle+=@spin
    if self.y>=@ground_y
      self.y=@ground_y.to_i; @scene.add_vfx_impact_xy(self.x,self.y,:rock,0) if @scene!=nil
      @finished=true; self.visible=false
    end
  end
end

class Sprite_PMDSkillVXOrbitLeafV033 < Sprite
  attr_reader :finished
  def initialize(viewport,cx,cy,index)
    super(viewport); @cx=cx.to_f; @cy=cy.to_f; @index=index.to_i; @age=0; @life=34; @finished=false
    @meta=PMD_AC.skill_special_rgs3_meta_v033('RGS3_ATK_199'); @cells=@meta[:cells_csv].to_s.split(',').collect{|s|s.to_i}; @frame=0; @wait=2
    self.bitmap=PMD_AC.skill_special_rgs3_bitmap_v033('RGS3_ATK_199'); self.ox=96; self.oy=96; self.z=9291; self.blend_type=0; update_src_v033
  end
  def update_src_v033; idx=@cells[@frame%@cells.size]; self.src_rect.set((idx%5)*192,(idx/5)*192,192,192); end
  def update
    super; return if @finished; @age+=1
    a=(@index*0.95)+@age*0.34; r=44.0-@age*0.62
    self.x=(@cx+Math.cos(a)*r).to_i; self.y=(@cy+Math.sin(a)*r-@age*0.30).to_i; self.angle+=18
    @wait-=1; if @wait<=0; @frame=(@frame+1)%@cells.size; update_src_v033; @wait=2; end
    self.opacity=[255-@age*5,35].max
    if @age>=@life; @finished=true; self.visible=false; end
  end
end

class Sprite_PMDSkillDemoLabelV033 < Sprite
  attr_reader :finished
  def initialize(viewport,text,life=46)
    super(viewport); self.bitmap=Bitmap.new(240,28); self.bitmap.fill_rect(0,0,240,28,Color.new(0,0,0,145)); self.bitmap.font.size=18
    self.bitmap.draw_text(0,0,240,28,text.to_s,1); self.x=152; self.y=72; self.z=9400; @life=life.to_i; @finished=false
  end
  def update; super; return if @finished; @life-=1; self.opacity=[@life*18,255].min; if @life<=0; @finished=true; self.visible=false; end; end
  def dispose; self.bitmap.dispose if self.bitmap!=nil && !self.bitmap.disposed?; super; end
end

class Scene_PMD_AutoChess
  alias pmd_ac_v033_start start unless method_defined?(:pmd_ac_v033_start)
  alias pmd_ac_v033_apply_skill_effects apply_skill_effects unless method_defined?(:pmd_ac_v033_apply_skill_effects)
  alias pmd_ac_v033_prepare_verification_battle prepare_verification_battle unless method_defined?(:pmd_ac_v033_prepare_verification_battle)
  alias pmd_ac_v033_update_verification_script update_verification_script unless method_defined?(:pmd_ac_v033_update_verification_script)
  alias pmd_ac_v033_complete_verification_mode complete_verification_mode unless method_defined?(:pmd_ac_v033_complete_verification_mode)
  alias pmd_ac_v033_log_event log_event unless method_defined?(:pmd_ac_v033_log_event)

  def start
    pmd_ac_v033_start
    begin
      if FileTest.exist?(PMD_AC::BATTLE_LOG_FILE)
        text=File.open(PMD_AC::BATTLE_LOG_FILE,"rb"){|f|f.read}
        text.sub!(/PMD AutoChess Proto v0\.[0-9.]+ Battle Verification Log/,"PMD AutoChess Proto v0.33 Battle Verification Log")
        File.open(PMD_AC::BATTLE_LOG_FILE,"wb"){|f|f.write(text)}
      end
    rescue
    end
    m=PMD_AC.skill_special_manifest_v033
    @skill_special_last_v033={}
    log_event(:skill_special,"LOADED specials="+m[:special_visual_count].to_s+" rgs3="+m[:rgs3_sheet_count].to_s+" sfx_alias="+m[:sfx_alias_count].to_s+" magenta_remaining="+m[:opaque_magenta_remaining].to_s+" checksum32="+m[:runtime_checksum32].to_s)
  end

  def special_xy_v033(obj)
    return [obj[0].to_i,obj[1].to_i] if obj.is_a?(Array)
    return [272,200] if obj==nil
    [obj.visual_center_x.to_i,obj.visual_center_y.to_i]
  end
  def add_special_label_v033(text); @effect_sprites.push(Sprite_PMDSkillDemoLabelV033.new(@viewport,text,46)); end
  def add_vx_anim_v033(name,x,y,opts=nil); s=Sprite_PMDSkillVXAnimV033.new(@viewport,name,x,y,opts); @effect_sprites.push(s); s; end

  def play_skill_special_visual_v033(move_key,user,target,demo=false)
    sp=PMD_AC.skill_special_visual_v033(move_key); return false if sp==nil
    anchor=(sp[:anchor]==:user ? user : target); x,y=special_xy_v033(anchor)
    add_special_label_v033(sp[:label]) if demo
    case sp[:kind]
    when :thunder_strike
      add_vx_anim_v033('RGS3_ATK_208',x,y-34,{:frame_wait=>4,:hold=>8,:zoom=>1.55,:blend=>1})
      add_vx_anim_v033('RGS3_ATK_221',x,y,{:frame_wait=>4,:delay=>6,:hold=>8,:zoom=>1.25,:blend=>1})
    when :rock_fall
      names=['RGS3_ATK_149','RGS3_ATK_240','RGS3_ATK_149','RGS3_ATK_149','RGS3_ATK_240']; offs=[-48,-24,0,27,50]
      for i in 0...names.size
        zoom=(names[i]=='RGS3_ATK_240' ? 0.62 : 0.92)
        @effect_sprites.push(Sprite_PMDSkillVXFallingRockV033.new(@viewport,self,names[i],x+offs[i],y+12,i*3,zoom,((i%2)==0 ? 8 : -7)))
      end
    when :blizzard_sweep
      4.times{|i|add_vx_anim_v033('RGS3_ATK_147',x-90+i*30,y-58+i*9,{:frame_wait=>4,:delay=>i*3,:hold=>3,:zoom=>0.90,:blend=>1,:dx=>3.2,:dy=>2.1,:angle=>-18})}
      add_vx_anim_v033('RGS3_ATK_221',x,y,{:frame_wait=>4,:delay=>13,:hold=>8,:zoom=>1.35,:blend=>1})
    when :leaf_swirl
      7.times{|i|@effect_sprites.push(Sprite_PMDSkillVXOrbitLeafV033.new(@viewport,x,y,i))}
      add_vx_anim_v033('RGS3_ATK_063',x,y,{:delay=>21,:life=>17,:hold=>9,:zoom=>1.25,:blend=>1,:grow=>0.022})
    when :pulse_ring
      if move_key==:dark_pulse
        add_vx_anim_v033('RGS3_ATK_215',x,y,{:frame_wait=>4,:hold=>8,:zoom=>0.90,:blend=>1,:grow=>0.025})
      elsif move_key==:dragon_pulse
        add_vx_anim_v033('RGS3_ATK_177',x,y,{:frame_wait=>2,:hold=>6,:zoom=>1.10,:blend=>1,:grow=>0.010})
      else
        add_vx_anim_v033('RGS3_ATK_190',x,y,{:frame_wait=>4,:hold=>8,:zoom=>0.90,:blend=>1,:grow=>0.035})
      end
    when :recover_sparkle
      pts=[[-28,10],[24,12],[-14,-24],[30,-18]]
      pts.each_with_index{|p,i|add_vx_anim_v033('RGS3_ATK_195',x+p[0],y+p[1],{:frame_wait=>5,:delay=>i*4,:hold=>9,:zoom=>0.90,:blend=>1,:dy=>-0.45})}
    when :cross_slash
      add_vx_anim_v033('RGS3_ATK_238',x,y,{:hold=>14,:zoom=>1.05,:blend=>1,:angle=>42})
      add_vx_anim_v033('RGS3_ATK_238',x,y,{:hold=>14,:zoom=>1.05,:blend=>1,:angle=>-42,:delay=>3})
      add_vx_anim_v033('RGS3_ATK_239',x,y,{:delay=>7,:hold=>10,:zoom=>0.95,:blend=>1,:grow=>0.020})
    else
      return false
    end
    true
  end

  def should_play_skill_special_v033(user,move_key)
    @skill_special_last_v033={} if @skill_special_last_v033==nil
    key=[user.object_id,move_key]; now=Graphics.frame_count; old=@skill_special_last_v033[key]
    return false if old!=nil && now-old<=2
    @skill_special_last_v033[key]=now; true
  end

  def apply_skill_effects(user,target,data,multiplier=1.0)
    result=pmd_ac_v033_apply_skill_effects(user,target,data,multiplier)
    if data!=nil && data[:canonical_move_key]!=nil
      mk=data[:canonical_move_key]
      if PMD_AC.skill_special_visual_v033(mk)!=nil && should_play_skill_special_v033(user,mk)
        play_skill_special_visual_v033(mk,user,target,false)
        log_event(:skill_special,user.log_name+" SPECIAL move="+mk.to_s+" kind="+PMD_AC.skill_special_visual_v033(mk)[:kind].to_s)
      end
    end
    result
  end

  def prepare_verification_battle
    pmd_ac_v033_prepare_verification_battle
    if verification_mode==:skill_special
      @skill_special_failed_v033=false; @skill_special_demo_v033=0
      for u in @units; u.verification_combat_sandbox(true); end
    end
  end

  def log_event(category,message)
    if category.to_s=="verify" && verification_mode==:skill_special && message.to_s.index("SKILL_SPECIAL_")==0 && message.to_s.include?(" pass=0")
      @skill_special_failed_v033=true
    end
    pmd_ac_v033_log_event(category,message)
  end

  def verify_skill_special_manifest_v033
    return if @verification_done[:skill_special_manifest]
    e=PMD_AC.validate_skill_special_v033; m=PMD_AC.skill_special_manifest_v033; pass=e.empty?
    log_event(:verify,"SKILL_SPECIAL_MANIFEST pass="+(pass ? "1":"0")+" specials="+m[:special_visual_count].to_s+" rgs3="+m[:rgs3_sheet_count].to_s+" sfx_alias="+m[:sfx_alias_count].to_s+" magenta="+m[:opaque_magenta_remaining].to_s+" checksum="+PMD_AC.skill_special_checksum32_v033.to_s+" errors=["+e.join(",")+"]")
    @verification_done[:skill_special_manifest]=true
  end

  def verify_skill_special_readability_v033
    return if @verification_done[:skill_special_readability]
    s=Sprite_PMDSkillImpactV030.new(@viewport,272,180,:ice,0); first=s.instance_variable_get(:@wait); hold=s.instance_variable_get(:@pmd_v033_hold); s.dispose unless s.disposed?
    pass=first>=PMD_AC::SKILL_IMPACT_FIRST_WAIT_V033 && hold==PMD_AC::SKILL_IMPACT_LAST_HOLD_V033
    log_event(:verify,"SKILL_SPECIAL_IMPACT_READABILITY pass="+(pass ? "1":"0")+" first_wait="+first.to_s+" last_hold="+hold.to_s)
    @verification_done[:skill_special_readability]=true
  end

  def demo_skill_special_v033(move_key,label,x,y,audio_stage)
    play_skill_special_visual_v033(move_key,[x,y],[x,y],true)
    spec=PMD_AC.skill_audio_spec_v032(move_key,audio_stage,0); ok=spec!=nil && FileTest.exist?("Audio/SE/"+spec[:name].to_s+".wav")
    PMD_AC.play_se(spec) if ok; @skill_special_demo_v033+=1 if ok
    log_event(:skill_special,"DEMO "+label+" move="+move_key.to_s+" audio="+(spec==nil ? "nil":spec[:name].to_s)+" ok="+(ok ? "1":"0"))
  end

  def verify_skill_special_runtime_v033
    return if @verification_done[:skill_special_runtime]
    keys=[:thunder,:rock_slide,:blizzard,:leaf_storm,:dark_pulse,:dragon_pulse,:hyper_voice,:recover,:swords_dance]; ok=true
    for k in keys
      d=PMD_AC.skill_data(("mv_"+k.to_s).to_sym); ok=false if d==nil || PMD_AC.skill_special_visual_v033(k)==nil
    end
    log_event(:verify,"SKILL_SPECIAL_RUNTIME pass="+(ok ? "1":"0")+" mapped="+keys.size.to_s+" rgs3_cells=1 additive_to_222=1 combat_logic=unchanged")
    @verification_done[:skill_special_runtime]=true
  end

  def verify_skill_special_audio_v033
    return if @verification_done[:skill_special_audio]
    r=PMD_AC.skill_audio_spec_v032(:rock_slide,:hit,0); b=PMD_AC.skill_audio_spec_v032(:blizzard,:launch,0); l=PMD_AC.skill_audio_spec_v032(:leaf_storm,:hit,0); h=PMD_AC.skill_audio_spec_v032(:hyper_voice,:hit,0)
    pass=r!=nil && b!=nil && l!=nil && h!=nil && @skill_special_demo_v033.to_i==9
    log_event(:verify,"SKILL_SPECIAL_AUDIO pass="+(pass ? "1":"0")+" demos="+@skill_special_demo_v033.to_i.to_s+" aliases=50 rock="+(r==nil ? "nil":r[:name].to_s)+" blizzard="+(b==nil ? "nil":b[:name].to_s)+" leaf="+(l==nil ? "nil":l[:name].to_s)+" voice="+(h==nil ? "nil":h[:name].to_s))
    @verification_done[:skill_special_audio]=true
  end

  def verify_skill_special_recent_modes_v033
    return if @verification_done[:skill_special_recent]
    expected=[:skill_special,:skill_audio,:skill_visual_expansion,:skill_visual,:weather_visual]
    pass=PMD_AC::VERIFICATION_MODES==expected && verification_mode==:skill_special
    log_event(:verify,"SKILL_SPECIAL_RECENT_MODES pass="+(pass ? "1":"0")+" modes="+PMD_AC::VERIFICATION_MODES.size.to_s+" default="+PMD_AC::VERIFICATION_LABELS[PMD_AC::VERIFICATION_MODES[0]].to_s)
    @verification_done[:skill_special_recent]=true
  end

  def update_verification_script
    pmd_ac_v033_update_verification_script
    return unless verification_mode==:skill_special
    f=@verification_frame
    verify_skill_special_manifest_v033 if f==4
    verify_skill_special_readability_v033 if f==20
    demo_skill_special_v033(:thunder,"THUNDER",272,178,:hit) if f==45
    demo_skill_special_v033(:rock_slide,"ROCK SLIDE",272,195,:hit) if f==100
    demo_skill_special_v033(:blizzard,"BLIZZARD",272,195,:launch) if f==155
    demo_skill_special_v033(:leaf_storm,"LEAF STORM",272,195,:hit) if f==210
    demo_skill_special_v033(:dark_pulse,"DARK PULSE",272,195,:hit) if f==265
    demo_skill_special_v033(:dragon_pulse,"DRAGON PULSE",272,195,:hit) if f==320
    demo_skill_special_v033(:hyper_voice,"HYPER VOICE",272,195,:hit) if f==375
    demo_skill_special_v033(:recover,"RECOVER",272,195,:hit) if f==430
    demo_skill_special_v033(:swords_dance,"SWORDS DANCE",272,195,:hit) if f==485
    verify_skill_special_runtime_v033 if f==535
    verify_skill_special_audio_v033 if f==550
    verify_skill_special_recent_modes_v033 if f==565
    complete_verification_mode if f==PMD_AC::VERIFICATION_SKILL_SPECIAL_END_FRAME_V033
  end

  def complete_verification_mode
    if verification_mode==:skill_special && @skill_special_failed_v033
      for u in @units; u.verification_finish; end
      @verification_done[:complete]=true
      log_event(:verify,"FAILED mode=SKILL_SPECIAL auto_skill=on original_skills=restored"); return
    end
    pmd_ac_v033_complete_verification_mode
  end
end
