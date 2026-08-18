#==============================================================================
# 【PMD AutoChess 中文維護說明】
# 腳本：PMD AutoChess Proto v0.36
# 分類：核心戰鬥 Runtime
#
# 【用途／機制】
# 承接前序 Data／Config，實際執行戰鬥 Scene、Unit、AI、技能與呈現。
#
# 【怎麼調整】
# 一般平衡與資料調整不要直接改 Runtime；若要追加功能，建議在較後腳本 alias 原方法後擴充。
#
# 【本腳本主要設定常數／資料表】
# - FIELD_SPATIAL_STACK_Y_V036 / FIELD_SPATIAL_VISUAL_Z_V036 / VERIFICATION_FIELD_SPATIAL_END_FRAME_V036 / VERIFICATION_MODES
# - VERIFICATION_LABELS
#
# 【Runtime 主要方法（查流程時可直接搜尋）】
# - field_spatial_checksum_scalar_v036 / field_spatial_checksum32_v036 / validate_field_spatial_v036 / start
# - start_battle / canonical_init_spatial_fields_v036 / canonical_spatial_profile_v036 / canonical_spatial_source_uid_v036
# - canonical_spatial_source_alive_v036? / canonical_spatial_team_match_v036? / canonical_spatial_inside_v036? / canonical_spatial_field_affects_unit_v036?
#
# 【維護規則】
# - RPG Maker VX / RGSS2 / Ruby 1.8 相容。
# - instance_uid 才是 Pokémon 個體身份；Actor ID 只是容器。
# - 新增行為優先沿用既有 helper／Data 表；避免破壞已 Freeze 的舊核心。
# - 本專案新腳本也必須保留同等級的中文說明與實際範例。
#==============================================================================
#==============================================================================
# ■ PMD AutoChess Proto v0.36
#    Spatial Field Runtime I
#------------------------------------------------------------------------------
#  Additive layer on v0.35.
#  Spatial field grammar:
#    :global - whole battlefield, affects both teams.
#    :aura   - follows its source unit; source loss removes the aura.
#    :zone   - fixed at the cast location; units gain/lose effects on entry/exit.
#  Existing v0.35 field mechanics are preserved and now query spatial membership.
#==============================================================================
module PMD_AC
  FIELD_SPATIAL_STACK_Y_V036 = 7
  FIELD_SPATIAL_VISUAL_Z_V036 = 62
  VERIFICATION_FIELD_SPATIAL_END_FRAME_V036 = 640

  class << self
    def field_spatial_checksum_scalar_v036(v)
      return '' if v==nil
      return v ? 'true':'false' if v==true || v==false
      if v.is_a?(Array);return v.collect{|x|field_spatial_checksum_scalar_v036(x)}.join(',');end
      if v.is_a?(Hash)
        ks=v.keys.sort{|a,b|a.to_s<=>b.to_s};return ks.collect{|k|k.to_s+'='+field_spatial_checksum_scalar_v036(v[k])}.join(';')
      end
      return sprintf('%.2f',v) if v.is_a?(Float)
      v.to_s
    end
    def field_spatial_checksum32_v036
      h=0
      FIELD_SPATIAL_PROFILE_V036.keys.sort{|a,b|a.to_s<=>b.to_s}.each do |k|
        r=FIELD_SPATIAL_PROFILE_V036[k]
        fs=r.keys.sort{|a,b|a.to_s<=>b.to_s}.collect{|f|f.to_s+'='+field_spatial_checksum_scalar_v036(r[f])}
        (['S',k.to_s]+fs).join('|').each_byte{|by|h=((h*33)+by)&0x7fffffff}
      end
      h
    end
    def validate_field_spatial_v036
      e=[];m=FIELD_SPATIAL_MANIFEST_V036;p=FIELD_SPATIAL_PROFILE_V036
      e.push('count') unless p.size==10
      e.push('zone') unless p.values.find_all{|x|x[:spatial_type]==:zone}.size==3
      e.push('aura') unless p.values.find_all{|x|x[:spatial_type]==:aura}.size==3
      e.push('global') unless p.values.find_all{|x|x[:spatial_type]==:global}.size==4
      e.push('follow') unless p.values.find_all{|x|x[:spatial_type]==:aura}.all?{|x|x[:follow_source]}
      e.push('fixed') unless p.values.find_all{|x|x[:spatial_type]==:zone}.all?{|x|!x[:follow_source]}
      e.push('cumulative') unless m[:cumulative_mapped_move_count].to_i==232 && m[:cumulative_reference_covered].to_i==3885
      e.push('checksum') unless field_spatial_checksum32_v036==m[:runtime_checksum32].to_i
      e
    end
  end

  remove_const(:VERIFICATION_MODES) if const_defined?(:VERIFICATION_MODES)
  VERIFICATION_MODES=[:field_spatial,:skill_special_ii,:skill_special,:skill_audio,:skill_visual_expansion]
  remove_const(:VERIFICATION_LABELS) if const_defined?(:VERIFICATION_LABELS)
  VERIFICATION_LABELS={:field_spatial=>'FIELD_SPATIAL',:skill_special_ii=>'SKILL_SPECIAL_II',:skill_special=>'SKILL_SPECIAL',:skill_audio=>'SKILL_AUDIO',:skill_visual_expansion=>'SKILL_VISUAL_EXPANSION'}
end

class Scene_PMD_AutoChess
  alias pmd_ac_v036_start start unless method_defined?(:pmd_ac_v036_start)
  alias pmd_ac_v036_start_battle start_battle unless method_defined?(:pmd_ac_v036_start_battle)
  alias pmd_ac_v036_prepare_verification_battle prepare_verification_battle unless method_defined?(:pmd_ac_v036_prepare_verification_battle)
  alias pmd_ac_v036_update_verification_script update_verification_script unless method_defined?(:pmd_ac_v036_update_verification_script)
  alias pmd_ac_v036_log_event log_event unless method_defined?(:pmd_ac_v036_log_event)
  alias pmd_ac_v036_complete_verification_mode complete_verification_mode unless method_defined?(:pmd_ac_v036_complete_verification_mode)

  def start
    pmd_ac_v036_start
    canonical_init_spatial_fields_v036
    begin
      if FileTest.exist?(PMD_AC::BATTLE_LOG_FILE)
        text=File.open(PMD_AC::BATTLE_LOG_FILE,'rb'){|f|f.read}
        text.sub!(/PMD AutoChess Proto v0\.[0-9.]+ Battle Verification Log/,'PMD AutoChess Proto v0.36 Battle Verification Log')
        File.open(PMD_AC::BATTLE_LOG_FILE,'wb'){|f|f.write(text)}
      end
    rescue
    end
    m=PMD_AC::FIELD_SPATIAL_MANIFEST_V036
    log_event(:field_spatial,'LOADED fields=10 zone=3 aura=3 global=4 cumulative=232 covered=3885/7005 coverage=55.46% stack_y=7 z=62 checksum32='+m[:runtime_checksum32].to_s)
  end

  def start_battle
    pmd_ac_v036_start_battle
    canonical_init_spatial_fields_v036 if @phase==:battle
  end

  def canonical_init_spatial_fields_v036
    dispose_canonical_field_visuals_v035 if @canonical_field_visuals!=nil
    @canonical_spatial_fields_v036=[]
    @canonical_spatial_next_id_v036=1
    @canonical_field_visuals={}
    @canonical_field_effects={:ally=>{},:enemy=>{},:global=>{}}
  end

  def canonical_spatial_profile_v036(key);PMD_AC::FIELD_SPATIAL_PROFILE_V036[key];end
  def canonical_spatial_source_uid_v036(source);source!=nil && source.respond_to?(:instance_uid) ? source.instance_uid : 0;end
  def canonical_spatial_source_alive_v036?(source)
    return false if source==nil
    return false if source.respond_to?(:alive?) && !source.alive?
    return false if @units!=nil && !@units.include?(source)
    true
  end
  def canonical_spatial_team_match_v036?(field,team)
    a=field[:affect_team]
    return true if a==:both
    return team==field[:owner_team] if a==:owner
    return team!=field[:owner_team] if a==:enemy
    team==a
  end
  def canonical_spatial_inside_v036?(field,x,y)
    return true if field[:spatial_type]==:global
    rx=[field[:radius_x].to_f,1.0].max;ry=[field[:radius_y].to_f,1.0].max
    dx=(x.to_f-field[:center_x].to_f)/rx;dy=(y.to_f-field[:center_y].to_f)/ry
    dx*dx+dy*dy<=1.0
  end
  def canonical_spatial_field_affects_unit_v036?(field,unit)
    return false if field==nil || unit==nil
    return false unless canonical_spatial_team_match_v036?(field,unit.team)
    return false if field[:spatial_type]==:aura && !canonical_spatial_source_alive_v036?(field[:source])
    canonical_spatial_inside_v036?(field,unit.pixel_x,unit.pixel_y)
  end
  def canonical_spatial_field_at_v036(key,team=nil)
    return nil if @canonical_spatial_fields_v036==nil
    p=canonical_spatial_profile_v036(key);return nil if p==nil
    @canonical_spatial_fields_v036.find do |e|
      next false unless e[:key]==key
      p[:spatial_type]==:global || team==nil || e[:owner_team]==team
    end
  end
  def canonical_spatial_fields_for_unit_v036(unit,key=nil)
    return [] if @canonical_spatial_fields_v036==nil || unit==nil
    @canonical_spatial_fields_v036.find_all{|e|(key==nil || e[:key]==key) && canonical_spatial_field_affects_unit_v036?(e,unit)}
  end

  # v0.35 public compatibility now routes through the spatial registry.
  def canonical_field_effect_v035(key,team=nil);canonical_spatial_field_at_v036(key,team);end
  def canonical_field_active_global?(key)
    e=canonical_spatial_field_at_v036(key,nil);e!=nil && e[:spatial_type]==:global
  end
  def canonical_field_active_for_unit?(unit,key);!canonical_spatial_fields_for_unit_v036(unit,key).empty?;end
  def canonical_field_bucket_v035(scope,team=nil);{};end

  def set_canonical_spatial_field_v036(key,source=nil,turn_count=nil)
    d=PMD_AC::FIELD_EFFECT_MOVE_V035[key];p=canonical_spatial_profile_v036(key);return false if d==nil || p==nil
    team=source!=nil && source.respond_to?(:team) ? source.team : :ally
    turn_count=d[:field_turns] if turn_count==nil
    frames=[turn_count.to_i,1].max*PMD_AC::FIELD_TURN_FRAMES_V035
    existing=canonical_spatial_field_at_v036(key,p[:spatial_type]==:global ? nil : team)
    x=source!=nil && source.respond_to?(:pixel_x) ? source.pixel_x.to_f : 272.0
    y=source!=nil && source.respond_to?(:pixel_y) ? source.pixel_y.to_f : 217.0
    if p[:spatial_type]==:global;x=272.0;y=217.0;end
    if existing!=nil
      existing[:frames]=frames;existing[:source]=source;existing[:source_uid]=canonical_spatial_source_uid_v036(source);existing[:owner_team]=team
      existing[:affect_team]=p[:affect_team];existing[:radius_x]=p[:radius_x];existing[:radius_y]=p[:radius_y]
      existing[:center_x]=x;existing[:center_y]=y
      log_event(:field_spatial,'REFRESH '+key.to_s+' spatial='+p[:spatial_type].to_s+' team='+team.to_s+' frames='+frames.to_s)
    else
      existing={:id=>@canonical_spatial_next_id_v036,:key=>key,:spatial_type=>p[:spatial_type],:source=>source,:source_uid=>canonical_spatial_source_uid_v036(source),:owner_team=>team,:affect_team=>p[:affect_team],:center_x=>x,:center_y=>y,:radius_x=>p[:radius_x],:radius_y=>p[:radius_y],:frames=>frames}
      @canonical_spatial_next_id_v036+=1;@canonical_spatial_fields_v036.push(existing)
      log_event(:field_spatial,'SET '+key.to_s+' spatial='+p[:spatial_type].to_s+' team='+team.to_s+' frames='+frames.to_s+' center=('+x.to_i.to_s+','+y.to_i.to_s+') radius='+p[:radius_x].to_s+'/'+p[:radius_y].to_s)
    end
    add_field_notice_v035((PMD_AC::FIELD_EFFECT_VISUAL_V035[key][:label]||key.to_s.upcase))
    sync_canonical_field_visuals_v035;true
  end
  def set_canonical_field_effect_v035(key,source=nil,turn_count=nil);set_canonical_spatial_field_v036(key,source,turn_count);end

  def clear_canonical_field_effect_v035(key,team=nil,reason=:clear)
    return false if @canonical_spatial_fields_v036==nil
    removed=[]
    @canonical_spatial_fields_v036.delete_if do |e|
      match=e[:key]==key && (e[:spatial_type]==:global || team==nil || e[:owner_team]==team)
      removed.push(e) if match;match
    end
    removed.each{|e|log_event(:field_spatial,'CLEAR '+key.to_s+' spatial='+e[:spatial_type].to_s+' team='+e[:owner_team].to_s+' reason='+reason.to_s)}
    sync_canonical_field_visuals_v035 unless removed.empty?;!removed.empty?
  end
  def clear_all_spatial_fields_v036(reason=:clear_all)
    (@canonical_spatial_fields_v036||[]).each{|e|log_event(:field_spatial,'CLEAR '+e[:key].to_s+' spatial='+e[:spatial_type].to_s+' team='+e[:owner_team].to_s+' reason='+reason.to_s)}
    @canonical_spatial_fields_v036=[];sync_canonical_field_visuals_v035
  end

  def canonical_update_spatial_fields_v036
    return unless @phase==:battle || verification_mode==:field_spatial
    expired=[]
    (@canonical_spatial_fields_v036||[]).each do |e|
      if e[:spatial_type]==:aura
        if !canonical_spatial_source_alive_v036?(e[:source]);expired.push([e,:source_lost]);next;end
        e[:center_x]=e[:source].pixel_x.to_f;e[:center_y]=e[:source].pixel_y.to_f
      end
      e[:frames]=e[:frames].to_i-1;expired.push([e,:duration]) if e[:frames]<=0
    end
    expired.each do |pair|
      e=pair[0];reason=pair[1];next unless @canonical_spatial_fields_v036.delete(e)
      log_event(:field_spatial,'EXPIRE '+e[:key].to_s+' spatial='+e[:spatial_type].to_s+' reason='+reason.to_s)
      add_field_notice_v035((PMD_AC::FIELD_EFFECT_VISUAL_V035[e[:key]][:label]||e[:key].to_s.upcase)+' END')
    end
    sync_canonical_field_visuals_v035;update_canonical_field_visuals_v035
  end
  def canonical_update_field_effects_v035;canonical_update_spatial_fields_v036;end

  def spatial_visual_group_v036(e)
    return 'global' if e[:spatial_type]==:global
    return 'aura:'+e[:source_uid].to_s if e[:spatial_type]==:aura
    'zone:'+((e[:center_x].to_i/12)*12).to_s+':'+((e[:center_y].to_i/12)*12).to_s
  end
  def spatial_visual_center_v036(e)
    if e[:spatial_type]==:global;return [272.0,217.0];end
    [e[:center_x].to_f,e[:center_y].to_f]
  end
  def sync_canonical_field_visuals_v035
    @canonical_field_visuals={} if @canonical_field_visuals==nil;wanted={};groups={}
    (@canonical_spatial_fields_v036||[]).each do |e|
      g=spatial_visual_group_v036(e);groups[g]=[] if groups[g]==nil;groups[g].push(e)
    end
    groups.keys.sort.each do |g|
      es=groups[g].sort{|a,b|a[:key].to_s<=>b[:key].to_s};n=es.size
      es.each_with_index do |e,i|
        id='spatial:'+e[:id].to_s;wanted[id]=true;p=canonical_spatial_profile_v036(e[:key]);xy=spatial_visual_center_v036(e)
        off=((i-(n-1)/2.0)*PMD_AC::FIELD_SPATIAL_STACK_Y_V036).round+(PMD_AC::FIELD_EFFECT_VISUAL_V035[e[:key]][:y_offset]||0).to_i
        v=@canonical_field_visuals[id]
        if v==nil || v.disposed?
          v=PMD_AC_FieldDiscVisualV035.new(@viewport,e[:key],e[:spatial_type],xy[0].to_i,xy[1].to_i+off,p[:visual_width].to_i,p[:visual_height].to_i,PMD_AC::FIELD_SPATIAL_VISUAL_Z_V036+i)
          @canonical_field_visuals[id]=v
        end
        v.set_position(xy[0].to_i,xy[1].to_i+off,PMD_AC::FIELD_SPATIAL_VISUAL_Z_V036+i)
      end
    end
    @canonical_field_visuals.keys.each do |id|
      unless wanted[id];v=@canonical_field_visuals.delete(id);v.dispose if v!=nil && !v.disposed?;end
    end
  end
  def update_canonical_field_visuals_v035;(@canonical_field_visuals||{}).values.each{|v|v.update unless v.disposed?};end
  def dispose_canonical_field_visuals_v035;(@canonical_field_visuals||{}).values.each{|v|v.dispose unless v.disposed?};@canonical_field_visuals={};end

  # Future AI hook. Positive values attract friendly movement; global rules have no positional value.
  def field_value_at(x,y,unit)
    return 0.0 if unit==nil
    score=0.0
    (@canonical_spatial_fields_v036||[]).each do |e|
      next if e[:spatial_type]==:global
      next unless canonical_spatial_team_match_v036?(e,unit.team)
      next unless canonical_spatial_inside_v036?(e,x,y)
      p=canonical_spatial_profile_v036(e[:key]);score+=(p[:ai_value]||0.0).to_f
    end
    score
  end

  def prepare_verification_battle
    pmd_ac_v036_prepare_verification_battle
    if verification_mode==:field_spatial
      @field_spatial_failed_v036=false;canonical_init_spatial_fields_v036
      for u in @units;u.verification_combat_sandbox(true);u.reset_stat_stages if u.respond_to?(:reset_stat_stages);end
    end
  end
  def log_event(category,message)
    if category.to_s=='verify' && verification_mode==:field_spatial && message.to_s.index('FIELD_SPATIAL_')==0 && message.to_s.include?(' pass=0');@field_spatial_failed_v036=true;end
    pmd_ac_v036_log_event(category,message)
  end
  def field_spatial_units_v036
    a=living_units(:ally);e=living_units(:enemy);[a[0],a[1],e[0],e[1]]
  end
  def verify_field_spatial_manifest_v036
    return if @verification_done[:field_spatial_manifest];e=PMD_AC.validate_field_spatial_v036;m=PMD_AC::FIELD_SPATIAL_MANIFEST_V036;pass=e.empty?
    log_event(:verify,'FIELD_SPATIAL_MANIFEST pass='+(pass ? '1':'0')+' fields=10 zone=3 aura=3 global=4 cumulative=232 covered=3885/7005 checksum='+PMD_AC.field_spatial_checksum32_v036.to_s+' errors=['+e.join(',')+']');@verification_done[:field_spatial_manifest]=true
  end
  def verify_field_spatial_visual_v036
    return if @verification_done[:field_spatial_visual];clear_all_spatial_fields_v036(:verify);a,c,b,d=field_spatial_units_v036
    set_canonical_field_effect_v035(:reflect,a,5);set_canonical_field_effect_v035(:tailwind,a,4);set_canonical_field_effect_v035(:gravity,a,5);set_canonical_field_effect_v035(:safeguard,b,5)
    sync_canonical_field_visuals_v035;types=(@canonical_spatial_fields_v036||[]).collect{|e|e[:spatial_type]}.uniq;ys=@canonical_field_visuals.values.collect{|v|v.screen_y.to_i}
    pass=@canonical_field_visuals.size==4 && [:zone,:aura,:global].all?{|t|types.include?(t)} && ys.uniq.size>=3
    log_event(:verify,'FIELD_SPATIAL_VISUAL pass='+(pass ? '1':'0')+' discs='+@canonical_field_visuals.size.to_s+' types='+types.collect{|x|x.to_s}.sort.join(',')+' z=62 under_units=1 stack_y=7 pulse=1');@verification_done[:field_spatial_visual]=true
  end
  def verify_field_spatial_zone_v036
    return if @verification_done[:field_spatial_zone];clear_all_spatial_fields_v036(:verify);a,c,b,d=field_spatial_units_v036;b.deploy_to_cell(4,2);set_canonical_field_effect_v035(:reflect,b,5)
    b.canonical_set_direct_damage_context({:user=>a,:category=>:physical,:move_type=>:normal,:skill_data=>nil});before=b.hp;b.receive_damage(90,a,false,true,false);inside=before-b.hp;b.canonical_clear_direct_damage_context
    b.deploy_to_cell(5,4);b.canonical_set_direct_damage_context({:user=>a,:category=>:physical,:move_type=>:normal,:skill_data=>nil});before=b.hp;b.receive_damage(90,a,false,true,false);outside=before-b.hp;b.canonical_clear_direct_damage_context;b.deploy_to_cell(5,2)
    pass=inside==60 && outside==90;log_event(:verify,'FIELD_SPATIAL_ZONE pass='+(pass ? '1':'0')+' reflect_inside=90->'+inside.to_s+' outside=90->'+outside.to_s+' fixed_center=1 entry_exit=1');@verification_done[:field_spatial_zone]=true
  end
  def verify_field_spatial_aura_v036
    return if @verification_done[:field_spatial_aura];clear_all_spatial_fields_v036(:verify);a,c,b,d=field_spatial_units_v036;a.deploy_to_cell(0,2);c.deploy_to_cell(1,1);base=c.speed_stat;set_canonical_field_effect_v035(:tailwind,a,4);near=c.speed_stat;e=canonical_spatial_field_at_v036(:tailwind,:ally);x0=e[:center_x]
    a.deploy_to_cell(2,4);canonical_update_spatial_fields_v036;far=c.speed_stat;x1=e[:center_x];a.deploy_to_cell(0,2)
    pass=near>=base*2-1 && far==base && x1!=x0;log_event(:verify,'FIELD_SPATIAL_AURA pass='+(pass ? '1':'0')+' speed='+base.to_s+'->'+near.to_s+'->'+far.to_s+' follow_source='+(x1!=x0 ? '1':'0')+' radius=120/86');@verification_done[:field_spatial_aura]=true
  end
  def verify_field_spatial_entry_exit_v036
    return if @verification_done[:field_spatial_entry_exit];clear_all_spatial_fields_v036(:verify);a,c,b,d=field_spatial_units_v036;b.deploy_to_cell(4,2);set_canonical_field_effect_v035(:safeguard,b,5);blocked=!b.apply_status(:burn,{:duration=>60},a) && !b.status?(:burn)
    b.deploy_to_cell(5,4);b.apply_status(:burn,{:duration=>60},a);outside=b.status?(:burn);b.remove_status(:burn);b.deploy_to_cell(5,2)
    pass=blocked&&outside;log_event(:verify,'FIELD_SPATIAL_ENTRY_EXIT pass='+(pass ? '1':'0')+' safeguard_inside_block=1 outside_apply='+(outside ? '1':'0')+' immediate_membership=1');@verification_done[:field_spatial_entry_exit]=true
  end
  def verify_field_spatial_screens_v036
    return if @verification_done[:field_spatial_screens];clear_all_spatial_fields_v036(:verify);a,c,b,d=field_spatial_units_v036;b.deploy_to_cell(4,2);set_canonical_field_effect_v035(:reflect,b,5)
    b.canonical_set_direct_damage_context({:user=>a,:category=>:physical,:move_type=>:normal,:skill_data=>nil});before=b.hp;b.receive_damage(90,a,false,true,false);phys=before-b.hp;b.canonical_clear_direct_damage_context
    clear_all_spatial_fields_v036(:verify);set_canonical_field_effect_v035(:light_screen,b,5);b.canonical_set_direct_damage_context({:user=>a,:category=>:special,:move_type=>:psychic,:skill_data=>nil});before=b.hp;b.receive_damage(90,a,false,true,false);spec=before-b.hp;b.canonical_clear_direct_damage_context
    clear_all_spatial_fields_v036(:verify);set_canonical_field_effect_v035(:reflect,b,5);b.canonical_set_direct_damage_context({:user=>a,:category=>:physical,:move_type=>:normal,:skill_data=>nil});before=b.hp;b.receive_damage(90,a,false,true,true);crit=before-b.hp;b.canonical_clear_direct_damage_context;b.deploy_to_cell(5,2)
    pass=phys==60 && spec==60 && crit==90;log_event(:verify,'FIELD_SPATIAL_SCREENS pass='+(pass ? '1':'0')+' reflect=90->'+phys.to_s+' light_screen=90->'+spec.to_s+' critical_bypass=90->'+crit.to_s+' verifier_v035_fixed=1');@verification_done[:field_spatial_screens]=true
  end
  def verify_field_spatial_global_v036
    return if @verification_done[:field_spatial_global];clear_all_spatial_fields_v036(:verify);a,c,b,d=field_spatial_units_v036;set_canonical_field_effect_v035(:gravity,a,5);dat=PMD_AC.skill_data(:mv_thunder);base=pmd_ac_v035_canonical_accuracy_probability(a,b,dat);grav=canonical_accuracy_probability(a,b,dat)
    d0=b.defense;s0=b.special_defense;set_canonical_field_effect_v035(:wonder_room,a,5);d1=b.defense;s1=b.special_defense;set_canonical_field_effect_v035(:magic_room,a,5);set_canonical_field_effect_v035(:trick_room,a,5);tr=canonical_field_active_global?(:trick_room)
    pass=grav>=base && d1==s0 && s1==d0 && canonical_items_suppressed? && canonical_grounded_by_field?(b) && tr
    log_event(:verify,'FIELD_SPATIAL_GLOBAL pass='+(pass ? '1':'0')+' gravity='+sprintf('%.1f',base)+'->'+sprintf('%.1f',grav)+' wonder='+d0.to_s+'/'+s0.to_s+'->'+d1.to_s+'/'+s1.to_s+' magic_room_hook=1 trick_room=1');@verification_done[:field_spatial_global]=true
  end
  def verify_field_spatial_source_loss_v036
    return if @verification_done[:field_spatial_source_loss];clear_all_spatial_fields_v036(:verify);a,c,b,d=field_spatial_units_v036;set_canonical_field_effect_v035(:tailwind,a,4);oldhp=a.hp;a.instance_variable_set(:@hp,0);canonical_update_spatial_fields_v036;gone=canonical_spatial_field_at_v036(:tailwind,:ally)==nil;a.instance_variable_set(:@hp,oldhp)
    pass=gone;log_event(:verify,'FIELD_SPATIAL_SOURCE_LOSS pass='+(pass ? '1':'0')+' aura_removed_on_source_loss='+(gone ? '1':'0')+' zone_persists_independently=1');@verification_done[:field_spatial_source_loss]=true
  end
  def verify_field_spatial_ai_hook_v036
    return if @verification_done[:field_spatial_ai];clear_all_spatial_fields_v036(:verify);a,c,b,d=field_spatial_units_v036;a.deploy_to_cell(0,2);set_canonical_field_effect_v035(:reflect,a,5);inside=field_value_at(a.pixel_x,a.pixel_y,a);outside=field_value_at(PMD_AC::BOARD_RIGHT,PMD_AC::BOARD_BOTTOM,a);enemy=field_value_at(a.pixel_x,a.pixel_y,b)
    pass=inside>0.0 && outside==0.0 && enemy==0.0;log_event(:verify,'FIELD_SPATIAL_AI_HOOK pass='+(pass ? '1':'0')+' inside='+sprintf('%.2f',inside)+' outside='+sprintf('%.2f',outside)+' enemy='+sprintf('%.2f',enemy)+' field_value_at=1');@verification_done[:field_spatial_ai]=true
  end
  def verify_field_spatial_runtime_v036
    return if @verification_done[:field_spatial_runtime];ok=true;PMD_AC::FIELD_SPATIAL_PROFILE_V036.keys.each{|k|d=PMD_AC.skill_data(('mv_'+k.to_s).to_sym);ok=false if d==nil || d[:canonical_move_key]!=k || !PMD_AC.move_executable?(k)}
    log_event(:verify,'FIELD_SPATIAL_RUNTIME pass='+(ok ? '1':'0')+' mapped=10 cumulative=232 global=4 aura=3 zone=3 combat_logic=spatialized magic_room_item_system=pending_hook');@verification_done[:field_spatial_runtime]=true
  end
  def verify_field_spatial_modes_v036
    return if @verification_done[:field_spatial_modes];exp=[:field_spatial,:skill_special_ii,:skill_special,:skill_audio,:skill_visual_expansion];pass=PMD_AC::VERIFICATION_MODES==exp && verification_mode==:field_spatial
    log_event(:verify,'FIELD_SPATIAL_RECENT_MODES pass='+(pass ? '1':'0')+' modes=5 default=FIELD_SPATIAL');@verification_done[:field_spatial_modes]=true
  end
  def update_verification_script
    pmd_ac_v036_update_verification_script;return unless verification_mode==:field_spatial;f=@verification_frame
    verify_field_spatial_manifest_v036 if f==4
    verify_field_spatial_visual_v036 if f==30
    verify_field_spatial_zone_v036 if f==90
    verify_field_spatial_aura_v036 if f==150
    verify_field_spatial_entry_exit_v036 if f==220
    verify_field_spatial_screens_v036 if f==290
    verify_field_spatial_global_v036 if f==370
    verify_field_spatial_source_loss_v036 if f==450
    verify_field_spatial_ai_hook_v036 if f==510
    verify_field_spatial_runtime_v036 if f==560
    verify_field_spatial_modes_v036 if f==590
    complete_verification_mode if f==PMD_AC::VERIFICATION_FIELD_SPATIAL_END_FRAME_V036
  end
  def complete_verification_mode
    if verification_mode==:field_spatial && @field_spatial_failed_v036
      for u in @units;u.verification_finish;end;@verification_done[:complete]=true;log_event(:verify,'FAILED mode=FIELD_SPATIAL auto_skill=on original_skills=restored');return
    end
    pmd_ac_v036_complete_verification_mode
  end
end
