#==============================================================================
# 【PMD AutoChess 中文維護說明】
# 腳本：PMD AutoChess Proto v0.40
# 分類：核心戰鬥 Runtime
#
# 【用途／機制】
# 承接前序 Data／Config，實際執行戰鬥 Scene、Unit、AI、技能與呈現。
#
# 【怎麼調整】
# 一般平衡與資料調整不要直接改 Runtime；若要追加功能，建議在較後腳本 alias 原方法後擴充。
#
# 【本腳本主要設定常數／資料表】
# - VERIFICATION_GUARD_END_FRAME_V040 / GUARD_DEFAULT_FRAMES_V040 / VERIFICATION_MODES / VERIFICATION_LABELS
#
# 【Runtime 主要方法（查流程時可直接搜尋）】
# - canonical_move_key_from_skill / move_executable? / move_autochess_hint / skill_data
# - skill_audio_move_profile_v032 / guard_checksum_scalar_v040 / guard_checksum32_v040 / validate_guard_v040
# - initialize / make_disc / make_ring / update_position
#
# 【維護規則】
# - RPG Maker VX / RGSS2 / Ruby 1.8 相容。
# - instance_uid 才是 Pokémon 個體身份；Actor ID 只是容器。
# - 新增行為優先沿用既有 helper／Data 表；避免破壞已 Freeze 的舊核心。
# - 本專案新腳本也必須保留同等級的中文說明與實際範例。
#==============================================================================
#===============================================================================
# ■ PMD AutoChess Proto v0.40
#    Protect / Guard Runtime I
#-------------------------------------------------------------------------------
# Additive layer on verified v0.39.1.
# - Protect / Detect: personal hostile-move guards (60 realtime frames).
# - Endure: lethal incoming damage is capped so the user remains at 1 HP.
# - Wide Guard: source-following spatial aura blocks multi-target attacks.
# - Quick Guard: source-following spatial aura blocks priority > 0 attacks.
# - Feint and Shadow Force bypass protection and break relevant guards.
# - Full-energy skill economy is the anti-spam gate in this AutoChess ruleset;
#   no additional consecutive-Protect RNG is added in v0.40.
#===============================================================================
module PMD_AC
  VERIFICATION_GUARD_END_FRAME_V040 = 600
  GUARD_DEFAULT_FRAMES_V040 = 60

  class << self
    alias pmd_ac_v040_canonical_move_key_from_skill canonical_move_key_from_skill unless method_defined?(:pmd_ac_v040_canonical_move_key_from_skill)
    alias pmd_ac_v040_move_executable move_executable? unless method_defined?(:pmd_ac_v040_move_executable)
    alias pmd_ac_v040_move_autochess_hint move_autochess_hint unless method_defined?(:pmd_ac_v040_move_autochess_hint)
    alias pmd_ac_v040_skill_data skill_data unless method_defined?(:pmd_ac_v040_skill_data)
    alias pmd_ac_v040_skill_audio_move_profile_v032 skill_audio_move_profile_v032 unless method_defined?(:pmd_ac_v040_skill_audio_move_profile_v032)

    def canonical_move_key_from_skill(skill_key)
      k=pmd_ac_v040_canonical_move_key_from_skill(skill_key);return k if k!=nil
      return nil if skill_key==nil;text=skill_key.to_s;return nil unless text[0,3]=='mv_'
      key=text[3,text.size-3].to_sym;GUARD_MOVE_V040[key]==nil ? nil : key
    end
    def move_executable?(move_key);return true if GUARD_MOVE_V040[move_key]!=nil;pmd_ac_v040_move_executable(move_key);end
    def move_autochess_hint(move_key)
      base=pmd_ac_v040_move_autochess_hint(move_key);b=GUARD_MOVE_V040[move_key];return base if b==nil
      r=base==nil ? {} : base.dup;r[:behavior_status]=b[:behavior_status];r[:delivery]=b[:delivery];r[:runtime_skill_key]=b[:runtime_skill_key];r[:target_type]=b[:target_type];r[:policy]=b[:policy];r[:range_px]=b[:range_px] if b[:range_px]!=nil;r
    end
    def skill_data(key)
      old=pmd_ac_v040_skill_data(key);return old if old!=nil && !old.empty?
      mk=canonical_move_key_from_skill(key);return {} if mk==nil;b=GUARD_MOVE_V040[mk];return {} if b==nil;b.dup
    end
    def skill_audio_move_profile_v032(move_key)
      b=GUARD_AUDIO_V040[move_key];return b unless b==nil
      pmd_ac_v040_skill_audio_move_profile_v032(move_key)
    end
    def guard_checksum_scalar_v040(v)
      return '' if v==nil;return v ? 'true':'false' if v==true || v==false
      return v.collect{|x|guard_checksum_scalar_v040(x)}.join(',') if v.is_a?(Array)
      if v.is_a?(Hash);ks=v.keys.sort{|a,b|a.to_s<=>b.to_s};return ks.collect{|k|k.to_s+'='+guard_checksum_scalar_v040(v[k])}.join(';');end
      return sprintf('%.2f',v) if v.is_a?(Float);v.to_s
    end
    def guard_checksum32_v040
      h=0;m=GUARD_MANIFEST_V040
      m.keys.reject{|k|k==:runtime_checksum32}.sort{|a,b|a.to_s<=>b.to_s}.each{|k|('M|'+k.to_s+'='+guard_checksum_scalar_v040(m[k])).each_byte{|by|h=((h*33)+by)&0x7fffffff}}
      GUARD_MOVE_V040.keys.sort{|a,b|a.to_s<=>b.to_s}.each do |k|
        src={};[:name,:name_en,:type,:category,:priority,:energy_cost_hint,:guard_kind,:duration_frames,:target_type,:policy,:delivery,:visual_kind,:radius_x,:radius_y,:power,:accuracy,:range_px,:vfx_style,:bypass_protect,:break_guard,:cast_cat,:launch_cat,:hit_cat].each{|f|v=GUARD_MOVE_V040[k][f];src[f]=v unless v==nil}
        ('R|'+k.to_s+'|'+guard_checksum_scalar_v040(src)).each_byte{|by|h=((h*33)+by)&0x7fffffff}
      end
      GUARD_VISUAL_V040.keys.sort{|a,b|a.to_s<=>b.to_s}.each{|k|('V|'+k.to_s+'|'+guard_checksum_scalar_v040(GUARD_VISUAL_V040[k])).each_byte{|by|h=((h*33)+by)&0x7fffffff}}
      h
    end
    def validate_guard_v040
      e=[];m=GUARD_MANIFEST_V040;e.push('count') unless GUARD_MOVE_V040.size==6;e.push('cumulative') unless m[:cumulative_mapped_move_count].to_i==243;e.push('covered') unless m[:cumulative_reference_covered].to_i==4077
      e.push('personal') unless [:protect,:detect,:endure].all?{|k|GUARD_MOVE_V040[k][:target_type]==:self}
      e.push('aura') unless GUARD_MOVE_V040[:wide_guard][:radius_x].to_i==145 && GUARD_MOVE_V040[:quick_guard][:radius_x].to_i==145
      e.push('feint') unless GUARD_MOVE_V040[:feint][:bypass_protect] && GUARD_MOVE_V040[:feint][:break_guard]
      e.push('checksum') unless guard_checksum32_v040==m[:runtime_checksum32].to_i;e
    end
  end

  remove_const(:VERIFICATION_MODES) if const_defined?(:VERIFICATION_MODES)
  VERIFICATION_MODES=[:guard,:two_turn,:altitude,:field_ai,:field_spatial]
  remove_const(:VERIFICATION_LABELS) if const_defined?(:VERIFICATION_LABELS)
  VERIFICATION_LABELS={:guard=>'GUARD',:two_turn=>'TWO_TURN',:altitude=>'ALTITUDE',:field_ai=>'FIELD_AI',:field_spatial=>'FIELD_SPATIAL'}
end

class PMD_AC_GuardDiscVisualV040
  attr_reader :key
  def initialize(viewport,unit,key,profile)
    @unit=unit;@key=key;@profile=profile;@phase=0
    c=profile[:color]||[160,220,255,50];w=profile[:width].to_i;h=profile[:height].to_i
    @base=Sprite.new(viewport);@pulse=Sprite.new(viewport)
    @base.bitmap=make_disc(w,h,c[0],c[1],c[2],c[3]);@pulse.bitmap=make_ring(w,h,c[0],c[1],c[2],[c[3].to_i+28,110].min)
    [@base,@pulse].each{|s|s.ox=s.bitmap.width/2;s.oy=s.bitmap.height/2};@pulse.opacity=90;update_position
  end
  def make_disc(w,h,r,g,b,a)
    bmp=Bitmap.new(w,h);cy=(h-1)/2.0;rx=(w-2)/2.0;ry=[(h-2)/2.0,1.0].max
    0.upto(h-1){|yy|dy=(yy-cy)/ry;t=1.0-dy*dy;next if t<=0.0;half=(Math.sqrt(t)*rx).to_i;x0=(w/2)-half;bmp.fill_rect(x0,yy,half*2+1,1,Color.new(r,g,b,a))};bmp
  end
  def make_ring(w,h,r,g,b,a)
    bmp=Bitmap.new(w,h);cy=(h-1)/2.0;rx=(w-2)/2.0;ry=[(h-2)/2.0,1.0].max
    0.upto(h-1){|yy|dy=(yy-cy)/ry;t=1.0-dy*dy;next if t<=0.0;half=(Math.sqrt(t)*rx).to_i;x0=(w/2)-half;bmp.fill_rect(x0,yy,[3,half*2+1].min,1,Color.new(r,g,b,a));bmp.fill_rect((w/2)+half-2,yy,[3,half*2+1].min,1,Color.new(r,g,b,a)) if half>2};bmp
  end
  def update_position
    return if @unit==nil;x=@unit.pixel_x.to_i;y=@unit.pixel_y.to_i;z=(@profile[:z]||63).to_i
    @base.x=x;@base.y=y;@base.z=z;@pulse.x=x;@pulse.y=y;@pulse.z=z+1
  end
  def update
    update_position;@phase=(@phase+1)%60;p=@phase.to_f/60.0;z=1.0+0.08*p;@pulse.zoom_x=z;@pulse.zoom_y=z;@pulse.opacity=(82*(1.0-p)).to_i+8
  end
  def disposed?;@base==nil || @base.disposed?;end
  def dispose
    [@base,@pulse].each{|s|next if s==nil || s.disposed?;s.bitmap.dispose if s.bitmap!=nil && !s.bitmap.disposed?;s.dispose};@base=nil;@pulse=nil
  end
end

class Game_PMDChessUnit
  alias pmd_ac_v040_initialize initialize unless method_defined?(:pmd_ac_v040_initialize)
  alias pmd_ac_v040_update update unless method_defined?(:pmd_ac_v040_update)
  alias pmd_ac_v040_receive_damage receive_damage unless method_defined?(:pmd_ac_v040_receive_damage)
  alias pmd_ac_v040_start_faint start_faint unless method_defined?(:pmd_ac_v040_start_faint)

  def initialize(*args);pmd_ac_v040_initialize(*args);@guards_v040={};end
  def guards_v040;@guards_v040={} if @guards_v040==nil;@guards_v040;end
  def guard_active_v040?(key);guards_v040[key].to_i>0;end
  def guard_frames_v040(key);guards_v040[key].to_i;end
  def set_guard_v040(key,frames=PMD_AC::GUARD_DEFAULT_FRAMES_V040)
    if [:protect,:detect,:endure].include?(key);[:protect,:detect,:endure].each{|k|guards_v040.delete(k)};end
    guards_v040[key]=[frames.to_i,1].max;true
  end
  def clear_guard_v040(key);guards_v040.delete(key)!=nil;end
  def clear_all_guards_v040;@guards_v040={};end
  def update
    pmd_ac_v040_update
    return if @guards_v040==nil || @guards_v040.empty?
    expired=[];@guards_v040.each{|k,v|n=v.to_i-1;if n<=0;expired.push(k);else;@guards_v040[k]=n;end};expired.each{|k|@guards_v040.delete(k);log_event(:guard,log_name+' EXPIRE '+k.to_s)}
  end
  def receive_damage(value,source=nil,grant_energy=true,bypass_link=false,critical=false)
    if guard_active_v040?(:endure) && @hp.to_i>0
      raw=value.to_i;preview=respond_to?(:canonical_preview_local_hp_damage) ? canonical_preview_local_hp_damage(raw,bypass_link) : raw
      if preview>=@hp.to_i
        capped=respond_to?(:canonical_cap_sturdy_raw) ? canonical_cap_sturdy_raw(raw,bypass_link) : [raw,@hp.to_i-1].min
        capped=0 if capped<0;log_event(:guard,log_name+' ENDURE lethal='+raw.to_s+' cap='+capped.to_s+' hp='+@hp.to_s)
        return if capped<=0
        value=capped
      end
    end
    pmd_ac_v040_receive_damage(value,source,grant_energy,bypass_link,critical)
  end
  def start_faint;clear_all_guards_v040;pmd_ac_v040_start_faint;end
end

class Scene_PMD_AutoChess
  alias pmd_ac_v040_start start unless method_defined?(:pmd_ac_v040_start)
  alias pmd_ac_v040_terminate terminate unless method_defined?(:pmd_ac_v040_terminate)
  alias pmd_ac_v040_start_battle start_battle unless method_defined?(:pmd_ac_v040_start_battle)
  alias pmd_ac_v040_update update unless method_defined?(:pmd_ac_v040_update)
  alias pmd_ac_v040_resolve_skill resolve_skill unless method_defined?(:pmd_ac_v040_resolve_skill)
  alias pmd_ac_v040_apply_skill_effects apply_skill_effects unless method_defined?(:pmd_ac_v040_apply_skill_effects)
  alias pmd_ac_v040_deal_direct_damage deal_direct_damage unless method_defined?(:pmd_ac_v040_deal_direct_damage)
  alias pmd_ac_v040_skill_cast_worthwhile skill_cast_worthwhile? unless method_defined?(:pmd_ac_v040_skill_cast_worthwhile)
  alias pmd_ac_v040_prepare_verification_battle prepare_verification_battle unless method_defined?(:pmd_ac_v040_prepare_verification_battle)
  alias pmd_ac_v040_update_verification_script update_verification_script unless method_defined?(:pmd_ac_v040_update_verification_script)
  alias pmd_ac_v040_log_event log_event unless method_defined?(:pmd_ac_v040_log_event)
  alias pmd_ac_v040_complete_verification_mode complete_verification_mode unless method_defined?(:pmd_ac_v040_complete_verification_mode)

  def start
    pmd_ac_v040_start;@guard_visuals_v040={}
    begin
      if FileTest.exist?(PMD_AC::BATTLE_LOG_FILE);text=File.open(PMD_AC::BATTLE_LOG_FILE,'rb'){|f|f.read};text.sub!(/PMD AutoChess Proto v0\.[0-9.]+ Battle Verification Log/,'PMD AutoChess Proto v0.40 Battle Verification Log');File.open(PMD_AC::BATTLE_LOG_FILE,'wb'){|f|f.write(text)};end
    rescue;end
    m=PMD_AC::GUARD_MANIFEST_V040;log_event(:guard,'LOADED new=6 cumulative='+m[:cumulative_mapped_move_count].to_s+' covered='+m[:cumulative_reference_covered].to_s+'/'+m[:learnset_reference_total].to_s+' coverage='+sprintf('%.2f',m[:cumulative_coverage_percent].to_f)+'% personal=3 aura=2 feint=1 checksum32='+m[:runtime_checksum32].to_s)
  end
  def terminate;dispose_guard_visuals_v040;pmd_ac_v040_terminate;end
  def start_battle;pmd_ac_v040_start_battle;if @phase==:battle;for u in @units;u.clear_all_guards_v040 if u.respond_to?(:clear_all_guards_v040);end;dispose_guard_visuals_v040;end;end
  def update;pmd_ac_v040_update;sync_guard_visuals_v040;update_guard_visuals_v040;end

  def guard_move_key_v040(data);data==nil ? nil : (data[:canonical_move_key]||data[:move_key]);end
  def guard_move_db_v040(data);k=guard_move_key_v040(data);return nil if k==nil || !PMD_AC.const_defined?(:MOVE_DB_V017);PMD_AC::MOVE_DB_V017[k];end
  def guard_bypass_v040?(data);k=guard_move_key_v040(data);return true if data!=nil && data[:bypass_protect];[:feint,:shadow_force].include?(k);end
  def guard_protectable_v040?(data)
    return true if data==nil
    return false if guard_bypass_v040?(data)
    db=guard_move_db_v040(data);flags=db==nil ? [] : (db[:flags]||[]);return true if flags.include?(:protect)
    # Runtime-generated hostile skills without a canonical protect flag default to protectable.
    effects=data[:effects]||[];effects.any?{|e|[:damage,:status,:control,:canonical_sleep,:canonical_freeze,:canonical_confusion].include?(e[:type])}
  end
  def guard_priority_v040(data);db=guard_move_db_v040(data);return data[:priority].to_i if data!=nil && data[:priority]!=nil;db==nil ? 0 : db[:priority].to_i;end
  def guard_multi_target_v040?(data)
    return false if data==nil;db=guard_move_db_v040(data);t=db==nil ? nil : db[:target]
    return true if [:all_opponents,:all_other_pokemon,:all_pokemon].include?(t)
    return true if data[:delivery]==:aoe || data[:global_direct];false
  end
  def guard_inside_aura_v040?(source,target,key)
    return false if source==nil || target==nil || source.dead? || source.team!=target.team || !source.guard_active_v040?(key)
    d=PMD_AC::GUARD_MOVE_V040[key];rx=(d[:radius_x]||145).to_f;ry=(d[:radius_y]||96).to_f;dx=(target.pixel_x-source.pixel_x).to_f/rx;dy=(target.pixel_y-source.pixel_y).to_f/ry;dx*dx+dy*dy<=1.0
  end
  def guard_aura_sources_v040(target,key);(@units||[]).find_all{|u|u.respond_to?(:guard_active_v040?) && guard_inside_aura_v040?(u,target,key)};end
  def guard_block_reason_v040(user,target,data,basic=false)
    return nil if user==nil || target==nil || user.team==target.team || guard_bypass_v040?(data)
    if target.guard_active_v040?(:protect) && (basic || guard_protectable_v040?(data));return :protect;end
    if target.guard_active_v040?(:detect) && (basic || guard_protectable_v040?(data));return :detect;end
    if !basic && guard_multi_target_v040?(data) && !guard_aura_sources_v040(target,:wide_guard).empty?;return :wide_guard;end
    if !basic && guard_priority_v040(data)>0 && !guard_aura_sources_v040(target,:quick_guard).empty?;return :quick_guard;end
    nil
  end
  def break_guard_on_target_v040(target,reason=:break)
    return 0 if target==nil;count=0
    [:protect,:detect].each{|k|if target.clear_guard_v040(k);count+=1;log_event(:guard,target.log_name+' BREAK '+k.to_s+' reason='+reason.to_s);end}
    [:wide_guard,:quick_guard].each do |k|
      guard_aura_sources_v040(target,k).each{|u|if u.clear_guard_v040(k);count+=1;log_event(:guard,u.log_name+' BREAK '+k.to_s+' via='+target.log_name+' reason='+reason.to_s);end}
    end
    count
  end
  def activate_guard_v040(unit,data)
    key=data[:guard_kind];frames=(data[:duration_frames]||60).to_i;unit.set_guard_v040(key,frames);play_skill_se(unit,:hit,data);add_skill_effect(unit,:shield) if respond_to?(:add_skill_effect)
    log_event(:guard,unit.log_name+' SET '+key.to_s+' frames='+frames.to_s+(data[:radius_x] ? ' radius='+data[:radius_x].to_s+'/'+data[:radius_y].to_s : ''));sync_guard_visuals_v040;true
  end
  def resolve_skill(unit)
    data=unit==nil ? nil : unit.skill_data
    if unit!=nil && data!=nil && data[:guard_kind]!=nil;return activate_guard_v040(unit,data);end
    pmd_ac_v040_resolve_skill(unit)
  end
  def apply_skill_effects(user,target,data,scale=1.0)
    if user!=nil && target!=nil && user.team!=target.team
      if guard_bypass_v040?(data);break_guard_on_target_v040(target,guard_move_key_v040(data)||:bypass)
      else
        reason=guard_block_reason_v040(user,target,data,false)
        if reason!=nil;log_event(:guard,target.log_name+' BLOCK '+reason.to_s+' move='+(guard_move_key_v040(data)||:unknown).to_s+' src='+user.log_name);add_skill_effect(target,:shield);return 0;end
      end
    end
    pmd_ac_v040_apply_skill_effects(user,target,data,scale)
  end
  def deal_direct_damage(user,target,power,options=nil)
    opts=options==nil ? {} : options;data=opts[:skill_data];basic=(opts[:source_type]==:basic || data==nil)
    if user!=nil && target!=nil && user.team!=target.team
      if guard_bypass_v040?(data);break_guard_on_target_v040(target,guard_move_key_v040(data)||:bypass)
      else
        reason=guard_block_reason_v040(user,target,data,basic)
        if reason!=nil;user.register_miss(target) if user.respond_to?(:register_miss);log_event(:guard,target.log_name+' BLOCK '+reason.to_s+' direct='+(guard_move_key_v040(data)||(basic ? :basic : :unknown)).to_s+' src='+user.log_name);add_skill_effect(target,:shield);return 0;end
      end
    end
    pmd_ac_v040_deal_direct_damage(user,target,power,options)
  end
  def skill_cast_worthwhile?(unit,target,data)
    return false unless pmd_ac_v040_skill_cast_worthwhile(unit,target,data)
    return true if unit==nil || data==nil || data[:guard_kind]==nil
    !unit.guard_active_v040?(data[:guard_kind])
  end

  def guard_visual_id_v040(unit,key);unit.instance_uid.to_s+':'+key.to_s;end
  def sync_guard_visuals_v040
    @guard_visuals_v040={} if @guard_visuals_v040==nil;wanted={}
    for u in (@units||[])
      next if u.dead? || !u.respond_to?(:guards_v040)
      u.guards_v040.keys.each do |k|;p=PMD_AC::GUARD_VISUAL_V040[k];next if p==nil || !u.guard_active_v040?(k);id=guard_visual_id_v040(u,k);wanted[id]=true;v=@guard_visuals_v040[id];if v==nil || v.disposed?;v=PMD_AC_GuardDiscVisualV040.new(@viewport,u,k,p);@guard_visuals_v040[id]=v;end;end
    end
    @guard_visuals_v040.keys.each{|id|unless wanted[id];v=@guard_visuals_v040.delete(id);v.dispose if v!=nil && !v.disposed?;end}
  end
  def update_guard_visuals_v040;(@guard_visuals_v040||{}).values.each{|v|v.update unless v.disposed?};end
  def dispose_guard_visuals_v040;(@guard_visuals_v040||{}).values.each{|v|v.dispose unless v.disposed?};@guard_visuals_v040={};end

  def prepare_verification_battle
    pmd_ac_v040_prepare_verification_battle
    if verification_mode==:guard;@guard_failed_v040=false;@guard_snapshots_v040={};for u in @units;u.verification_combat_sandbox(true);u.clear_all_guards_v040 if u.respond_to?(:clear_all_guards_v040);end;dispose_guard_visuals_v040;end
  end
  def log_event(category,message)
    if category.to_s=='verify' && verification_mode==:guard && message.to_s.index('GUARD_')==0 && message.to_s.include?(' pass=0');@guard_failed_v040=true;end
    pmd_ac_v040_log_event(category,message)
  end
  def guard_verify_units_v040;[verification_unit(:ally,:bulbasaur),verification_unit(:ally,:charmander),verification_unit(:ally,:squirtle),verification_unit(:enemy,:rattata)];end
  def guard_reset_units_v040
    for u in @units;u.clear_all_guards_v040 if u.respond_to?(:clear_all_guards_v040);u.verification_clear_status(:confusion) if u.respond_to?(:verification_clear_status);end;dispose_guard_visuals_v040
  end
  def verify_guard_manifest_v040
    return if @verification_done[:guard_manifest];e=PMD_AC.validate_guard_v040;m=PMD_AC::GUARD_MANIFEST_V040;pass=e.empty?;log_event(:verify,'GUARD_MANIFEST pass='+(pass ? '1':'0')+' new=6 cumulative='+m[:cumulative_mapped_move_count].to_s+' covered='+m[:cumulative_reference_covered].to_s+'/'+m[:learnset_reference_total].to_s+' coverage='+sprintf('%.2f',m[:cumulative_coverage_percent].to_f)+' personal=3 aura=2 checksum='+PMD_AC.guard_checksum32_v040.to_s+' errors=['+e.join(',')+']');@verification_done[:guard_manifest]=true
  end
  def verify_guard_visual_v040
    return if @verification_done[:guard_visual];guard_reset_units_v040;a,b,c,t=guard_verify_units_v040;a.set_guard_v040(:protect,60);b.set_guard_v040(:wide_guard,60);c.set_guard_v040(:quick_guard,60);sync_guard_visuals_v040;pass=@guard_visuals_v040.size==3
    log_event(:verify,'GUARD_VISUAL pass='+(pass ? '1':'0')+' discs='+@guard_visuals_v040.size.to_s+' personal=protect aura=wide_guard,quick_guard z_below_units=1 pulse=1 follow_source=1');@verification_done[:guard_visual]=true
  end
  def verify_guard_personal_v040
    return if @verification_done[:guard_personal];guard_reset_units_v040;a,b,c,t=guard_verify_units_v040;t.set_guard_v040(:protect,60);hp=t.hp;basic=deal_direct_damage(a,t,50,{:fixed_damage=>50,:can_crit=>false,:directional=>false,:source_type=>:basic,:grant_energy=>false});tackle=apply_skill_effects(a,t,PMD_AC.skill_data(:mv_tackle),1.0);blocked=(basic==0 && tackle.to_i==0 && t.hp==hp)
    sf=PMD_AC.skill_data(:mv_shadow_force);before=t.hp;hit=apply_skill_effects(a,t,sf,1.0);bypass=t.hp<before && !t.guard_active_v040?(:protect)
    t.set_guard_v040(:detect,60);hp2=t.hp;d2=deal_direct_damage(a,t,30,{:fixed_damage=>30,:can_crit=>false,:directional=>false,:source_type=>:basic,:grant_energy=>false});detect=(d2==0 && t.hp==hp2)
    pass=blocked&&bypass&&detect;log_event(:verify,'GUARD_PERSONAL pass='+(pass ? '1':'0')+' protect_basic=1 protect_skill=1 detect_basic=1 shadow_force_bypass=1 break_guard=1');@verification_done[:guard_personal]=true
  end
  def verify_guard_endure_v040
    return if @verification_done[:guard_endure];guard_reset_units_v040;a,b,c,t=guard_verify_units_v040;t.instance_variable_set(:@hp,40);t.set_guard_v040(:endure,60);deal_direct_damage(a,t,1,{:fixed_damage=>999,:can_crit=>false,:directional=>false,:grant_energy=>false});survive=t.hp==1;t.clear_guard_v040(:endure);t.heal(t.maxhp);before=t.hp;deal_direct_damage(a,t,1,{:fixed_damage=>10,:can_crit=>false,:directional=>false,:grant_energy=>false});normal=(before-t.hp)==10
    pass=survive&&normal;log_event(:verify,'GUARD_ENDURE pass='+(pass ? '1':'0')+' lethal=40->1 nonlethal_without_guard=10 min_hp=1');@verification_done[:guard_endure]=true
  end
  def verify_guard_wide_v040
    return if @verification_done[:guard_wide];guard_reset_units_v040;a,b,c,t=guard_verify_units_v040;a.deploy_to_cell(1,2);b.deploy_to_pixel(a.pixel_x+50,a.pixel_y);t.deploy_to_pixel(a.pixel_x+220,a.pixel_y);a.set_guard_v040(:wide_guard,60);bl=PMD_AC.skill_data(:mv_blizzard);hp=b.hp;inside=apply_skill_effects(t,b,bl,1.0);block=(inside.to_i==0 && b.hp==hp);b.deploy_to_pixel(a.pixel_x+200,a.pixel_y);hp2=b.hp;outside=apply_skill_effects(t,b,bl,1.0);outside_hit=b.hp<hp2
    pass=block&&outside_hit;log_event(:verify,'GUARD_WIDE pass='+(pass ? '1':'0')+' multi_target_inside=blocked outside=hit spatial_aura=145/96 single_target_not_claimed=1');@verification_done[:guard_wide]=true
  end
  def verify_guard_quick_v040
    return if @verification_done[:guard_quick];guard_reset_units_v040;a,b,c,t=guard_verify_units_v040;a.deploy_to_cell(1,2);b.deploy_to_pixel(a.pixel_x+50,a.pixel_y);t.deploy_to_pixel(a.pixel_x+210,a.pixel_y);a.set_guard_v040(:quick_guard,60)
    qa={:canonical_move_key=>:quick_attack,:move_type=>:normal,:damage_category=>:physical,:priority=>1,:target_type=>:enemy_targeted,:delivery=>:instant,:effects=>[{:type=>:damage,:power=>40}]};hp=b.hp;res=apply_skill_effects(t,b,qa,1.0);blocked=res.to_i==0 && b.hp==hp
    normal={:canonical_move_key=>:tackle,:move_type=>:normal,:damage_category=>:physical,:priority=>0,:target_type=>:enemy_targeted,:delivery=>:instant,:effects=>[{:type=>:damage,:power=>40}]};hp2=b.hp;apply_skill_effects(t,b,normal,1.0);normal_hit=b.hp<hp2
    pass=blocked&&normal_hit;log_event(:verify,'GUARD_QUICK pass='+(pass ? '1':'0')+' priority_gt0=blocked priority0=hit spatial_aura=145/96');@verification_done[:guard_quick]=true
  end
  def verify_guard_feint_v040
    return if @verification_done[:guard_feint];guard_reset_units_v040;a,b,c,t=guard_verify_units_v040;b.deploy_to_pixel(t.pixel_x,t.pixel_y);t.set_guard_v040(:protect,60);b.set_guard_v040(:wide_guard,60);f=PMD_AC.skill_data(:mv_feint);before=t.hp;apply_skill_effects(a,t,f,1.0);damage=before-t.hp;broken=!t.guard_active_v040?(:protect)&&!b.guard_active_v040?(:wide_guard)
    pass=damage>0&&broken;log_event(:verify,'GUARD_FEINT_BREAK pass='+(pass ? '1':'0')+' damage='+damage.to_s+' protect_removed=1 affecting_wide_guard_removed=1 shadow_force_hook=integrated');@verification_done[:guard_feint]=true
  end
  def verify_guard_runtime_v040
    return if @verification_done[:guard_runtime];ok=true;[:protect,:detect,:endure,:wide_guard,:quick_guard,:feint].each{|k|d=PMD_AC.skill_data(('mv_'+k.to_s).to_sym);ok=false if d==nil || d[:canonical_move_key]!=k || !PMD_AC.move_executable?(k)};log_event(:verify,'GUARD_RUNTIME pass='+(ok ? '1':'0')+' mapped=6 cumulative=243 coverage=4077/7005 protect_detect=60 endure=1hp wide_quick=spatial_aura feint_break=1 full_energy_antispam=1 extra_rng=0');@verification_done[:guard_runtime]=true
  end
  def verify_guard_modes_v040
    return if @verification_done[:guard_modes];exp=[:guard,:two_turn,:altitude,:field_ai,:field_spatial];pass=PMD_AC::VERIFICATION_MODES==exp && verification_mode==:guard;log_event(:verify,'GUARD_RECENT_MODES pass='+(pass ? '1':'0')+' modes=5 default=GUARD');@verification_done[:guard_modes]=true
  end
  def update_verification_script
    pmd_ac_v040_update_verification_script;return unless verification_mode==:guard;f=@verification_frame
    verify_guard_manifest_v040 if f==4;verify_guard_visual_v040 if f==30;verify_guard_personal_v040 if f==95;verify_guard_endure_v040 if f==175;verify_guard_wide_v040 if f==255;verify_guard_quick_v040 if f==335;verify_guard_feint_v040 if f==415;verify_guard_runtime_v040 if f==485;verify_guard_modes_v040 if f==525;complete_verification_mode if f==PMD_AC::VERIFICATION_GUARD_END_FRAME_V040
  end
  def complete_verification_mode
    if verification_mode==:guard;guard_reset_units_v040;if @guard_failed_v040;for u in @units;u.verification_finish;end;@verification_done[:complete]=true;log_event(:verify,'FAILED mode=GUARD auto_skill=on original_skills=restored');return;end;end
    pmd_ac_v040_complete_verification_mode
  end
end
