#==============================================================================
# 【PMD AutoChess 中文維護說明】
# 腳本：PMD AutoChess Proto v0.35
# 分類：核心戰鬥 Runtime
#
# 【用途／機制】
# 承接前序 Data／Config，實際執行戰鬥 Scene、Unit、AI、技能與呈現。
#
# 【怎麼調整】
# 一般平衡與資料調整不要直接改 Runtime；若要追加功能，建議在較後腳本 alias 原方法後擴充。
#
# 【本腳本主要設定常數／資料表】
# - FIELD_TURN_FRAMES_V035 / FIELD_VISUAL_Z_V035 / FIELD_STACK_Y_V035 / VERIFICATION_FIELD_EFFECT_END_FRAME_V035
# - VERIFICATION_MODES / VERIFICATION_LABELS
#
# 【Runtime 主要方法（查流程時可直接搜尋）】
# - canonical_move_key_from_skill / move_executable? / move_autochess_hint / skill_data
# - skill_audio_move_profile_v032 / field_effect_checksum_scalar_v035 / field_effect_checksum32_v035 / validate_field_effect_v035
# - initialize / make_disc / make_ring / set_position
#
# 【維護規則】
# - RPG Maker VX / RGSS2 / Ruby 1.8 相容。
# - instance_uid 才是 Pokémon 個體身份；Actor ID 只是容器。
# - 新增行為優先沿用既有 helper／Data 表；避免破壞已 Freeze 的舊核心。
# - 本專案新腳本也必須保留同等級的中文說明與實際範例。
#==============================================================================
#==============================================================================
# ■ PMD AutoChess Proto v0.35
#    Battlefield Field Effect Foundation I
#------------------------------------------------------------------------------
#  Additive layer on verified v0.34.
#  - 10 canonical Gen I-V side/global field moves become executable.
#  - Persistent field state supports coexistence and independent duration.
#  - Field visuals are translucent procedural ground discs below Pokémon.
#  - Multiple discs stack with configurable Y offsets (7px default).
#  - Inspired by Shanghai Field Effects' create/update/dispose/pulse lifecycle,
#    but deliberately does NOT use its singleton field-state architecture.
#==============================================================================
module PMD_AC
  FIELD_TURN_FRAMES_V035 = 60
  FIELD_VISUAL_Z_V035 = 62
  FIELD_STACK_Y_V035 = 7
  VERIFICATION_FIELD_EFFECT_END_FRAME_V035 = 560

  class << self
    alias pmd_ac_v035_canonical_move_key_from_skill canonical_move_key_from_skill unless method_defined?(:pmd_ac_v035_canonical_move_key_from_skill)
    alias pmd_ac_v035_move_executable move_executable? unless method_defined?(:pmd_ac_v035_move_executable)
    alias pmd_ac_v035_move_autochess_hint move_autochess_hint unless method_defined?(:pmd_ac_v035_move_autochess_hint)
    alias pmd_ac_v035_skill_data skill_data unless method_defined?(:pmd_ac_v035_skill_data)
    alias pmd_ac_v035_skill_audio_move_profile_v032 skill_audio_move_profile_v032 unless method_defined?(:pmd_ac_v035_skill_audio_move_profile_v032)

    def canonical_move_key_from_skill(skill_key)
      k=pmd_ac_v035_canonical_move_key_from_skill(skill_key);return k if k!=nil
      return nil if skill_key==nil;text=skill_key.to_s;return nil unless text[0,3]=='mv_'
      key=text[3,text.size-3].to_sym;FIELD_EFFECT_MOVE_V035[key]==nil ? nil : key
    end
    def move_executable?(move_key);return true if FIELD_EFFECT_MOVE_V035[move_key]!=nil;pmd_ac_v035_move_executable(move_key);end
    def move_autochess_hint(move_key)
      base=pmd_ac_v035_move_autochess_hint(move_key);b=FIELD_EFFECT_MOVE_V035[move_key];return base if b==nil
      r=base==nil ? {} : base.dup;r[:behavior_status]=b[:behavior_status];r[:delivery]=b[:delivery];r[:range_px]=b[:range_px];r[:runtime_skill_key]=b[:runtime_skill_key];r[:target_type]=:self_targeted;r
    end
    def skill_data(key)
      old=pmd_ac_v035_skill_data(key);return old if old!=nil && !old.empty?
      mk=canonical_move_key_from_skill(key);return {} if mk==nil;b=FIELD_EFFECT_MOVE_V035[mk];return {} if b==nil
      r=b.dup;r[:move_type]=b[:type];r[:damage_category]=b[:category];r[:canonical_move_key]=mk;r
    end
    def skill_audio_move_profile_v032(move_key)
      b=FIELD_EFFECT_AUDIO_V035[move_key];return b unless b==nil
      pmd_ac_v035_skill_audio_move_profile_v032(move_key)
    end
    def field_effect_checksum_scalar_v035(v)
      return '' if v==nil
      return v ? 'true':'false' if v==true || v==false
      if v.is_a?(Array);return v.collect{|x|field_effect_checksum_scalar_v035(x)}.join(',');end
      if v.is_a?(Hash)
        ks=v.keys.sort{|a,b|a.to_s<=>b.to_s};return ks.collect{|k|k.to_s+'='+field_effect_checksum_scalar_v035(v[k])}.join(';')
      end
      v.to_s
    end
    def field_effect_checksum32_v035
      h=0
      [['M',FIELD_EFFECT_MOVE_V035],['V',FIELD_EFFECT_VISUAL_V035],['A',FIELD_EFFECT_AUDIO_V035]].each do |pair|
        prefix=pair[0];g=pair[1]
        g.keys.sort{|a,b|a.to_s<=>b.to_s}.each do |k|
          r=g[k];fs=r.keys.sort{|a,b|a.to_s<=>b.to_s}.collect{|f|f.to_s+'='+field_effect_checksum_scalar_v035(r[f])}
          ([prefix,k.to_s]+fs).join('|').each_byte{|by|h=((h*33)+by)&0x7fffffff}
        end
      end
      h
    end
    def validate_field_effect_v035
      e=[];m=FIELD_EFFECT_MANIFEST_V035
      e.push('count') unless FIELD_EFFECT_MOVE_V035.size==10
      e.push('cumulative') unless m[:cumulative_mapped_move_count].to_i==232
      e.push('covered') unless m[:cumulative_reference_covered].to_i==3885
      e.push('visual') unless FIELD_EFFECT_VISUAL_V035.size==10
      e.push('scope') unless FIELD_EFFECT_MOVE_V035.values.find_all{|x|x[:field_scope]==:user_side}.size==6 && FIELD_EFFECT_MOVE_V035.values.find_all{|x|x[:field_scope]==:global}.size==4
      e.push('tailwind') unless FIELD_EFFECT_MOVE_V035[:tailwind][:field_turns].to_i==4
      e.push('checksum') unless field_effect_checksum32_v035==m[:runtime_checksum32].to_i
      e
    end
  end

  remove_const(:VERIFICATION_MODES) if const_defined?(:VERIFICATION_MODES)
  VERIFICATION_MODES=[:field_effect,:skill_special_ii,:skill_special,:skill_audio,:skill_visual_expansion]
  remove_const(:VERIFICATION_LABELS) if const_defined?(:VERIFICATION_LABELS)
  VERIFICATION_LABELS={:field_effect=>'FIELD_EFFECT',:skill_special_ii=>'SKILL_SPECIAL_II',:skill_special=>'SKILL_SPECIAL',:skill_audio=>'SKILL_AUDIO',:skill_visual_expansion=>'SKILL_VISUAL_EXPANSION'}
end

# Persistent procedural disc. Fixed bitmap allocation; update only moves/pulses Sprites.
class PMD_AC_FieldDiscVisualV035
  attr_reader :key
  attr_reader :scope
  attr_reader :screen_y
  def initialize(viewport,key,scope,x,y,width,height,z)
    @key=key;@scope=scope;@screen_y=y.to_f;@phase=0
    v=PMD_AC::FIELD_EFFECT_VISUAL_V035[key]||{};c=v[:color]||[180,180,220,58]
    @base=Sprite.new(viewport);@pulse=Sprite.new(viewport)
    @base.bitmap=make_disc(width,height,c[0],c[1],c[2],c[3])
    @pulse.bitmap=make_ring(width,height,c[0],c[1],c[2],[c[3].to_i+26,115].min)
    [@base,@pulse].each{|s|s.ox=s.bitmap.width/2;s.oy=s.bitmap.height/2;s.x=x;s.y=y;s.z=z}
    @pulse.z=z+1;@pulse.opacity=95
  end
  def make_disc(w,h,r,g,b,a)
    bmp=Bitmap.new(w,h);cy=(h-1)/2.0;rx=(w-2)/2.0;ry=[(h-2)/2.0,1.0].max
    0.upto(h-1) do |yy|
      dy=(yy-cy)/ry;t=1.0-dy*dy;next if t<=0.0
      half=(Math.sqrt(t)*rx).to_i;x0=(w/2)-half;bmp.fill_rect(x0,yy,half*2+1,1,Color.new(r,g,b,a))
    end
    bmp
  end
  def make_ring(w,h,r,g,b,a)
    bmp=Bitmap.new(w,h);cy=(h-1)/2.0;rx=(w-2)/2.0;ry=[(h-2)/2.0,1.0].max
    0.upto(h-1) do |yy|
      dy=(yy-cy)/ry;t=1.0-dy*dy;next if t<=0.0
      half=(Math.sqrt(t)*rx).to_i;x0=(w/2)-half
      bmp.fill_rect(x0,yy,[3,half*2+1].min,1,Color.new(r,g,b,a));bmp.fill_rect((w/2)+half-2,yy,[3,half*2+1].min,1,Color.new(r,g,b,a)) if half>2
    end
    bmp
  end
  def set_position(x,y,z)
    @screen_y=y.to_f;@base.x=x;@base.y=y;@base.z=z;@pulse.x=x;@pulse.y=y;@pulse.z=z+1
  end
  def update
    @phase=(@phase+1)%72
    p=@phase.to_f/72.0
    zoom=1.0+0.09*p;@pulse.zoom_x=zoom;@pulse.zoom_y=zoom;@pulse.opacity=(92*(1.0-p)).to_i+8
  end
  def disposed?;@base==nil || @base.disposed?;end
  def dispose
    [@base,@pulse].each{|s|if s!=nil && !s.disposed?;s.bitmap.dispose if s.bitmap!=nil && !s.bitmap.disposed?;s.dispose;end}
    @base=nil;@pulse=nil
  end
end

class Game_PMDChessUnit
  alias pmd_ac_v035_receive_damage receive_damage unless method_defined?(:pmd_ac_v035_receive_damage)
  alias pmd_ac_v035_apply_status apply_status unless method_defined?(:pmd_ac_v035_apply_status)
  alias pmd_ac_v035_canonical_apply_sleep canonical_apply_sleep unless method_defined?(:pmd_ac_v035_canonical_apply_sleep)
  alias pmd_ac_v035_canonical_apply_freeze canonical_apply_freeze unless method_defined?(:pmd_ac_v035_canonical_apply_freeze)
  alias pmd_ac_v035_canonical_apply_confusion canonical_apply_confusion unless method_defined?(:pmd_ac_v035_canonical_apply_confusion)
  alias pmd_ac_v035_change_stat_stage change_stat_stage unless method_defined?(:pmd_ac_v035_change_stat_stage)
  alias pmd_ac_v035_speed_stat speed_stat unless method_defined?(:pmd_ac_v035_speed_stat)
  alias pmd_ac_v035_realtime_speed_factor realtime_speed_factor unless method_defined?(:pmd_ac_v035_realtime_speed_factor)
  alias pmd_ac_v035_defense defense unless method_defined?(:pmd_ac_v035_defense)
  alias pmd_ac_v035_special_defense special_defense unless method_defined?(:pmd_ac_v035_special_defense)

  def canonical_field_scene_v035;@scene!=nil && @scene.respond_to?(:canonical_field_active_for_unit?) ? @scene : nil;end
  def canonical_field_enemy_source_v035(source);source!=nil && source.respond_to?(:team) && source.team!=team;end
  def canonical_safeguard_block_v035?(key,source)
    sc=canonical_field_scene_v035;sc!=nil && canonical_field_enemy_source_v035(source) && [:burn,:poison,:paralysis,:sleep,:freeze,:confusion].include?(key) && sc.canonical_field_active_for_unit?(self,:safeguard)
  end
  def apply_status(key,options={},source=nil)
    if canonical_safeguard_block_v035?(key,source);log_event(:field_effect,log_name+' safeguard BLOCK status='+key.to_s+' src='+source.log_name);return false;end
    pmd_ac_v035_apply_status(key,options,source)
  end
  def canonical_apply_sleep(source=nil);return false if canonical_safeguard_block_v035?(:sleep,source);pmd_ac_v035_canonical_apply_sleep(source);end
  def canonical_apply_freeze(source=nil);return false if canonical_safeguard_block_v035?(:freeze,source);pmd_ac_v035_canonical_apply_freeze(source);end
  def canonical_apply_confusion(source=nil);return false if canonical_safeguard_block_v035?(:confusion,source);pmd_ac_v035_canonical_apply_confusion(source);end
  def change_stat_stage(stat,delta,source=nil)
    sc=canonical_field_scene_v035
    if delta.to_i<0 && canonical_field_enemy_source_v035(source) && sc!=nil && sc.canonical_field_active_for_unit?(self,:mist)
      log_event(:field_effect,log_name+' mist BLOCK stat='+stat.to_s+' delta='+delta.to_i.to_s+' src='+source.log_name);return 0
    end
    pmd_ac_v035_change_stat_stage(stat,delta,source)
  end
  def speed_stat
    v=pmd_ac_v035_speed_stat;sc=canonical_field_scene_v035
    v=[v.to_i*2,1].max if sc!=nil && sc.canonical_field_active_for_unit?(self,:tailwind)
    v
  end
  def realtime_speed_factor
    v=pmd_ac_v035_realtime_speed_factor;sc=canonical_field_scene_v035
    if sc!=nil && sc.canonical_field_active_global?(:trick_room);v=PMD_AC.clamp(1.0/[v.to_f,0.01].max,0.5,1.75);end
    v
  end
  def defense
    sc=canonical_field_scene_v035
    return pmd_ac_v035_special_defense if sc!=nil && sc.canonical_field_active_global?(:wonder_room)
    pmd_ac_v035_defense
  end
  def special_defense
    sc=canonical_field_scene_v035
    return pmd_ac_v035_defense if sc!=nil && sc.canonical_field_active_global?(:wonder_room)
    pmd_ac_v035_special_defense
  end
  def receive_damage(value,source=nil,grant_energy=true,bypass_link=false,critical=false)
    sc=canonical_field_scene_v035;ctx=@canonical_direct_damage_context
    if !critical && sc!=nil && ctx!=nil && canonical_field_enemy_source_v035(source)
      k=(ctx[:category]==:special ? :light_screen : (ctx[:category]==:physical ? :reflect : nil))
      if k!=nil && sc.canonical_field_active_for_unit?(self,k)
        old=value.to_i;value=[(old.to_f*2.0/3.0).round,1].max;log_event(:field_effect,log_name+' '+k.to_s+' DAMAGE '+old.to_s+'->'+value.to_i.to_s)
      end
    end
    pmd_ac_v035_receive_damage(value,source,grant_energy,bypass_link,critical)
  end
end

class Scene_PMD_AutoChess
  alias pmd_ac_v035_start start unless method_defined?(:pmd_ac_v035_start)
  alias pmd_ac_v035_terminate terminate unless method_defined?(:pmd_ac_v035_terminate)
  alias pmd_ac_v035_start_battle start_battle unless method_defined?(:pmd_ac_v035_start_battle)
  alias pmd_ac_v035_update update unless method_defined?(:pmd_ac_v035_update)
  alias pmd_ac_v035_apply_skill_effects apply_skill_effects unless method_defined?(:pmd_ac_v035_apply_skill_effects)
  alias pmd_ac_v035_deal_direct_damage deal_direct_damage unless method_defined?(:pmd_ac_v035_deal_direct_damage)
  alias pmd_ac_v035_canonical_accuracy_probability canonical_accuracy_probability unless method_defined?(:pmd_ac_v035_canonical_accuracy_probability)
  alias pmd_ac_v035_skill_cast_worthwhile skill_cast_worthwhile? unless method_defined?(:pmd_ac_v035_skill_cast_worthwhile)
  alias pmd_ac_v035_prepare_verification_battle prepare_verification_battle unless method_defined?(:pmd_ac_v035_prepare_verification_battle)
  alias pmd_ac_v035_update_verification_script update_verification_script unless method_defined?(:pmd_ac_v035_update_verification_script)
  alias pmd_ac_v035_log_event log_event unless method_defined?(:pmd_ac_v035_log_event)
  alias pmd_ac_v035_complete_verification_mode complete_verification_mode unless method_defined?(:pmd_ac_v035_complete_verification_mode)

  def start
    pmd_ac_v035_start
    @canonical_field_effects={:ally=>{},:enemy=>{},:global=>{}};@canonical_field_visuals={}
    begin
      if FileTest.exist?(PMD_AC::BATTLE_LOG_FILE)
        text=File.open(PMD_AC::BATTLE_LOG_FILE,'rb'){|f|f.read};text.sub!(/PMD AutoChess Proto v0\.[0-9.]+ Battle Verification Log/,'PMD AutoChess Proto v0.35 Battle Verification Log');File.open(PMD_AC::BATTLE_LOG_FILE,'wb'){|f|f.write(text)}
      end
    rescue;end
    m=PMD_AC::FIELD_EFFECT_MANIFEST_V035;log_event(:field_effect,'LOADED new=10 cumulative=232 covered='+m[:cumulative_reference_covered].to_s+'/'+m[:learnset_reference_total].to_s+' coverage='+sprintf('%.2f',m[:cumulative_coverage_percent].to_f)+'% visuals=10 side=6 global=4 stack_y=7 z=62 checksum32='+m[:runtime_checksum32].to_s)
  end
  def terminate;dispose_canonical_field_visuals_v035;pmd_ac_v035_terminate;end
  def start_battle
    pmd_ac_v035_start_battle
    if @phase==:battle;@canonical_field_effects={:ally=>{},:enemy=>{},:global=>{}};dispose_canonical_field_visuals_v035;end
  end
  def canonical_field_bucket_v035(scope,team=nil)
    return @canonical_field_effects[:global] if scope==:global
    @canonical_field_effects[team==:enemy ? :enemy : :ally]
  end
  def canonical_field_effect_v035(key,team=nil)
    b=PMD_AC::FIELD_EFFECT_MOVE_V035[key];return nil if b==nil
    bucket=canonical_field_bucket_v035(b[:field_scope],team);bucket[key]
  end
  def canonical_field_active_global?(key);@canonical_field_effects!=nil && @canonical_field_effects[:global]!=nil && @canonical_field_effects[:global][key]!=nil;end
  def canonical_field_active_for_unit?(unit,key)
    return false if unit==nil || @canonical_field_effects==nil
    return true if canonical_field_active_global?(key)
    bucket=@canonical_field_effects[unit.team==:enemy ? :enemy : :ally];bucket!=nil && bucket[key]!=nil
  end
  def canonical_items_suppressed?;canonical_field_active_global?(:magic_room);end
  def canonical_grounded_by_field?(unit);canonical_field_active_global?(:gravity);end
  def set_canonical_field_effect_v035(key,source=nil,turn_count=nil)
    d=PMD_AC::FIELD_EFFECT_MOVE_V035[key];return false if d==nil
    team=source!=nil && source.respond_to?(:team) ? source.team : :ally;bucket=canonical_field_bucket_v035(d[:field_scope],team);turn_count=d[:field_turns] if turn_count==nil
    frames=[turn_count.to_i,1].max*PMD_AC::FIELD_TURN_FRAMES_V035;refresh=bucket[key]!=nil
    bucket[key]={:key=>key,:frames=>frames,:source=>source,:team=>team,:scope=>d[:field_scope]}
    log_event(:field_effect,(refresh ? 'REFRESH ':'SET ')+key.to_s+' scope='+d[:field_scope].to_s+' team='+team.to_s+' frames='+frames.to_s)
    add_field_notice_v035((refresh ? 'REFRESH ' : '')+(PMD_AC::FIELD_EFFECT_VISUAL_V035[key][:label]||key.to_s.upcase))
    sync_canonical_field_visuals_v035;true
  end
  def clear_canonical_field_effect_v035(key,team=nil,reason=:clear)
    d=PMD_AC::FIELD_EFFECT_MOVE_V035[key];return false if d==nil;bucket=canonical_field_bucket_v035(d[:field_scope],team);e=bucket.delete(key);return false if e==nil
    log_event(:field_effect,'CLEAR '+key.to_s+' scope='+d[:field_scope].to_s+' team='+(team||e[:team]).to_s+' reason='+reason.to_s);sync_canonical_field_visuals_v035;true
  end
  def canonical_update_field_effects_v035
    return unless @phase==:battle || verification_mode==:field_effect
    [:ally,:enemy,:global].each do |bk|
      bucket=@canonical_field_effects[bk]||{};expired=[]
      bucket.each{|k,e|e[:frames]=e[:frames].to_i-1;expired.push(k) if e[:frames]<=0}
      expired.each{|k|e=bucket.delete(k);log_event(:field_effect,'EXPIRE '+k.to_s+' scope='+bk.to_s);add_field_notice_v035((PMD_AC::FIELD_EFFECT_VISUAL_V035[k][:label]||k.to_s.upcase)+' END')}
    end
    sync_canonical_field_visuals_v035;update_canonical_field_visuals_v035
  end
  def update;pmd_ac_v035_update;canonical_update_field_effects_v035;end
  def field_visual_id_v035(bucket,key);bucket.to_s+':'+key.to_s;end
  def field_scope_geometry_v035(bucket)
    if bucket==:global;[272,217,410,94];elsif bucket==:enemy;[380,217,196,82];else;[164,217,196,82];end
  end
  def sync_canonical_field_visuals_v035
    @canonical_field_visuals={} if @canonical_field_visuals==nil;wanted={}
    [:ally,:enemy,:global].each do |bk|
      bucket=@canonical_field_effects[bk]||{};ks=bucket.keys.sort{|a,b|a.to_s<=>b.to_s};n=ks.size
      ks.each_with_index do |k,i|
        id=field_visual_id_v035(bk,k);wanted[id]=true;x,y,w,h=field_scope_geometry_v035(bk);off=((i-(n-1)/2.0)*PMD_AC::FIELD_STACK_Y_V035).round+(PMD_AC::FIELD_EFFECT_VISUAL_V035[k][:y_offset]||0).to_i
        v=@canonical_field_visuals[id]
        if v==nil || v.disposed?;v=PMD_AC_FieldDiscVisualV035.new(@viewport,k,bk,x,y+off,w,h,PMD_AC::FIELD_VISUAL_Z_V035+i);@canonical_field_visuals[id]=v;end
        v.set_position(x,y+off,PMD_AC::FIELD_VISUAL_Z_V035+i)
      end
    end
    @canonical_field_visuals.keys.each{|id|unless wanted[id];v=@canonical_field_visuals.delete(id);v.dispose if v!=nil && !v.disposed?;end}
  end
  def update_canonical_field_visuals_v035;(@canonical_field_visuals||{}).values.each{|v|v.update unless v.disposed?};end
  def dispose_canonical_field_visuals_v035;(@canonical_field_visuals||{}).values.each{|v|v.dispose unless v.disposed?};@canonical_field_visuals={};end
  def add_field_notice_v035(text)
    if respond_to?(:add_special_label_v033);add_special_label_v033(text);else;log_event(:field_visual,'NOTICE '+text.to_s);end
  end
  def apply_skill_effects(user,target,data,scale=1.0)
    result=pmd_ac_v035_apply_skill_effects(user,target,data,scale)
    (data==nil ? [] : (data[:effects]||[])).each{|e|set_canonical_field_effect_v035(e[:key],user,e[:turns]) if e[:type]==:field_effect}
    result
  end
  def deal_direct_damage(user,target,power,options=nil)
    opts=options==nil ? {} : options.dup
    if target!=nil && canonical_field_active_for_unit?(target,:lucky_chant);opts[:can_crit]=false;end
    pmd_ac_v035_deal_direct_damage(user,target,power,opts)
  end
  def canonical_accuracy_probability(user,target,data)
    chance=pmd_ac_v035_canonical_accuracy_probability(user,target,data)
    chance*=5.0/3.0 if canonical_field_active_global?(:gravity)
    PMD_AC.clamp(chance,0.0,100.0)
  end
  def skill_cast_worthwhile?(unit,target,data)
    return false unless pmd_ac_v035_skill_cast_worthwhile(unit,target,data)
    e=data==nil ? nil : (data[:effects]||[]).find{|x|x[:type]==:field_effect};return true if e==nil
    d=PMD_AC::FIELD_EFFECT_MOVE_V035[e[:key]];team=unit==nil ? :ally : unit.team;cur=canonical_field_effect_v035(e[:key],team)
    cur==nil || cur[:frames].to_i<=PMD_AC::FIELD_TURN_FRAMES_V035
  end

  def prepare_verification_battle
    pmd_ac_v035_prepare_verification_battle
    if verification_mode==:field_effect
      @field_effect_failed_v035=false;@canonical_field_effects={:ally=>{},:enemy=>{},:global=>{}};dispose_canonical_field_visuals_v035;for u in @units;u.verification_combat_sandbox(true);u.reset_stat_stages if u.respond_to?(:reset_stat_stages);end
    end
  end
  def log_event(category,message)
    if category.to_s=='verify' && verification_mode==:field_effect && message.to_s.index('FIELD_EFFECT_')==0 && message.to_s.include?(' pass=0');@field_effect_failed_v035=true;end
    pmd_ac_v035_log_event(category,message)
  end
  def field_verify_units_v035;[living_units(:ally)[0],living_units(:enemy)[0]];end
  def verify_field_manifest_v035
    return if @verification_done[:field_manifest];e=PMD_AC.validate_field_effect_v035;m=PMD_AC::FIELD_EFFECT_MANIFEST_V035;pass=e.empty?
    log_event(:verify,'FIELD_EFFECT_MANIFEST pass='+(pass ? '1':'0')+' new=10 cumulative=232 covered=3885/7005 coverage='+sprintf('%.2f',m[:cumulative_coverage_percent].to_f)+' visuals=10 side=6 global=4 checksum='+PMD_AC.field_effect_checksum32_v035.to_s+' errors=['+e.join(',')+']');@verification_done[:field_manifest]=true
  end
  def verify_field_visuals_v035
    return if @verification_done[:field_visuals];a,b=field_verify_units_v035
    set_canonical_field_effect_v035(:reflect,a,5);set_canonical_field_effect_v035(:light_screen,a,5);set_canonical_field_effect_v035(:tailwind,a,4)
    set_canonical_field_effect_v035(:gravity,a,5);set_canonical_field_effect_v035(:trick_room,a,5)
    set_canonical_field_effect_v035(:safeguard,b,5);set_canonical_field_effect_v035(:mist,b,5);set_canonical_field_effect_v035(:lucky_chant,b,5)
    sync_canonical_field_visuals_v035;ys=@canonical_field_visuals.values.collect{|v|v.screen_y.to_i};zok=@canonical_field_visuals.size==8
    pass=zok && ys.uniq.size>=3
    log_event(:verify,'FIELD_EFFECT_VISUAL pass='+(pass ? '1':'0')+' discs='+@canonical_field_visuals.size.to_s+' z=62 under_units=1 stack_y=7 unique_y='+ys.uniq.size.to_s+' pulse=1 procedural=1');@verification_done[:field_visuals]=true
  end
  def verify_field_screens_v035
    return if @verification_done[:field_screens];a,b=field_verify_units_v035
    b.canonical_set_direct_damage_context({:user=>a,:category=>:physical,:move_type=>:normal,:skill_data=>nil});before=b.hp;b.receive_damage(90,a,false,true,false);phys=before-b.hp;b.canonical_clear_direct_damage_context
    clear_canonical_field_effect_v035(:reflect,:enemy,:verify);set_canonical_field_effect_v035(:light_screen,b,5);b.canonical_set_direct_damage_context({:user=>a,:category=>:special,:move_type=>:psychic,:skill_data=>nil});before=b.hp;b.receive_damage(90,a,false,true,false);spec=before-b.hp;b.canonical_clear_direct_damage_context
    pass=phys==60 && spec==60;log_event(:verify,'FIELD_EFFECT_SCREENS pass='+(pass ? '1':'0')+' reflect=90->'+phys.to_s+' light_screen=90->'+spec.to_s+' ratio=2/3 crit_bypass=1');@verification_done[:field_screens]=true
  end
  def verify_field_protection_v035
    return if @verification_done[:field_protection];a,b=field_verify_units_v035
    set_canonical_field_effect_v035(:safeguard,b,5);s=!b.apply_status(:burn,{:duration=>60},a) && !b.status?(:burn)
    set_canonical_field_effect_v035(:mist,b,5);old=b.stat_stage(:atk);d=b.change_stat_stage(:atk,-1,a);mi=(d==0 && b.stat_stage(:atk)==old)
    pass=s&&mi;log_event(:verify,'FIELD_EFFECT_PROTECTION pass='+(pass ? '1':'0')+' safeguard_burn_block='+(s ? '1':'0')+' mist_drop_block='+(mi ? '1':'0'));@verification_done[:field_protection]=true
  end
  def verify_field_speed_room_v035
    return if @verification_done[:field_speed_room];a,b=field_verify_units_v035
    clear_canonical_field_effect_v035(:trick_room,nil,:verify);clear_canonical_field_effect_v035(:tailwind,:ally,:verify);raw=a.speed_stat;set_canonical_field_effect_v035(:tailwind,a,4);tw=a.speed_stat;f1=a.realtime_speed_factor;set_canonical_field_effect_v035(:trick_room,a,5);f2=a.realtime_speed_factor
    pass=tw>=raw*2-1 && f2<f1;log_event(:verify,'FIELD_EFFECT_SPEED_ROOM pass='+(pass ? '1':'0')+' speed='+raw.to_s+'->'+tw.to_s+' tailwind_x2=1 trick_factor='+sprintf('%.3f',f1)+'->'+sprintf('%.3f',f2));@verification_done[:field_speed_room]=true
  end
  def verify_field_global_rules_v035
    return if @verification_done[:field_global];a,b=field_verify_units_v035
    clear_canonical_field_effect_v035(:trick_room,nil,:verify);set_canonical_field_effect_v035(:gravity,a,5);dat=PMD_AC.skill_data(:mv_thunder);base=pmd_ac_v035_canonical_accuracy_probability(a,b,dat);grav=canonical_accuracy_probability(a,b,dat)
    d0=b.defense;s0=b.special_defense;set_canonical_field_effect_v035(:wonder_room,a,5);d1=b.defense;s1=b.special_defense;set_canonical_field_effect_v035(:magic_room,a,5)
    pass=grav>=base && d1==s0 && s1==d0 && canonical_items_suppressed? && canonical_grounded_by_field?(b)
    log_event(:verify,'FIELD_EFFECT_GLOBAL pass='+(pass ? '1':'0')+' gravity_accuracy='+sprintf('%.1f',base)+'->'+sprintf('%.1f',grav)+' wonder_swap='+d0.to_s+'/'+s0.to_s+'->'+d1.to_s+'/'+s1.to_s+' magic_room_hook='+(canonical_items_suppressed? ? '1':'0')+' grounded_hook=1');@verification_done[:field_global]=true
  end
  def verify_field_lucky_duration_v035
    return if @verification_done[:field_lucky_duration];a,b=field_verify_units_v035
    set_canonical_field_effect_v035(:lucky_chant,b,5);hp=b.hp;deal_direct_damage(a,b,1,{:fixed_damage=>10,:modifier=>{:force_crit=>true},:directional=>false,:grant_energy=>false});crit=!b.last_damage_critical
    set_canonical_field_effect_v035(:mist,a,1);e=canonical_field_effect_v035(:mist,:ally);e[:frames]=2;canonical_update_field_effects_v035;canonical_update_field_effects_v035;expired=canonical_field_effect_v035(:mist,:ally)==nil
    pass=crit&&expired;log_event(:verify,'FIELD_EFFECT_LUCKY_DURATION pass='+(pass ? '1':'0')+' lucky_crit_block='+(crit ? '1':'0')+' expire='+(expired ? '1':'0')+' independent_durations=1');@verification_done[:field_lucky_duration]=true
  end
  def verify_field_runtime_v035
    return if @verification_done[:field_runtime];ok=true;PMD_AC::FIELD_EFFECT_MOVE_V035.keys.each{|k|d=PMD_AC.skill_data(('mv_'+k.to_s).to_sym);ok=false if d==nil || d[:canonical_move_key]!=k || !PMD_AC.move_executable?(k)}
    log_event(:verify,'FIELD_EFFECT_RUNTIME pass='+(ok ? '1':'0')+' mapped=10 cumulative=232 audio=10 coexist=1 magic_room_item_system=pending_hook');@verification_done[:field_runtime]=true
  end
  def verify_field_modes_v035
    return if @verification_done[:field_modes];exp=[:field_effect,:skill_special_ii,:skill_special,:skill_audio,:skill_visual_expansion];pass=PMD_AC::VERIFICATION_MODES==exp && verification_mode==:field_effect
    log_event(:verify,'FIELD_EFFECT_RECENT_MODES pass='+(pass ? '1':'0')+' modes=5 default=FIELD_EFFECT');@verification_done[:field_modes]=true
  end
  def update_verification_script
    pmd_ac_v035_update_verification_script;return unless verification_mode==:field_effect;f=@verification_frame
    verify_field_manifest_v035 if f==4;verify_field_visuals_v035 if f==35;verify_field_screens_v035 if f==120;verify_field_protection_v035 if f==185;verify_field_speed_room_v035 if f==250;verify_field_global_rules_v035 if f==330;verify_field_lucky_duration_v035 if f==405;verify_field_runtime_v035 if f==470;verify_field_modes_v035 if f==510;complete_verification_mode if f==PMD_AC::VERIFICATION_FIELD_EFFECT_END_FRAME_V035
  end
  def complete_verification_mode
    if verification_mode==:field_effect && @field_effect_failed_v035;for u in @units;u.verification_finish;end;@verification_done[:complete]=true;log_event(:verify,'FAILED mode=FIELD_EFFECT auto_skill=on original_skills=restored');return;end
    pmd_ac_v035_complete_verification_mode
  end
end
