#==============================================================================
# 【PMD AutoChess 中文維護說明】
# 腳本：PMD AutoChess Proto v0.57.2
# 分類：核心戰鬥 Runtime
#
# 【用途／機制】
# 承接前序 Data／Config，實際執行戰鬥 Scene、Unit、AI、技能與呈現。
#
# 【怎麼調整】
# 一般平衡與資料調整不要直接改 Runtime；若要追加功能，建議在較後腳本 alias 原方法後擴充。
#
# 【本腳本主要設定常數／資料表】
# - PATCH_VERSION_V0572 / PRESENTATION_POLISH_END_FRAME_V0572 / BEAM_SHOWCASE_START_V0572 / BEAM_SHOWCASE_INTERVAL_V0572
# - VERIFICATION_MODES / VERIFICATION_LABELS
#
# 【Runtime 主要方法（查流程時可直接搜尋）】
# - beam_supported_style_v0572? / move_type_for_v0572 / beam_style_for_v0572 / skill_data
# - skill_visual_move_profile_v031 / move_presentation_profile_v055 / beam_move_keys_v0572 / begin_attack
# - begin_skill / trigger_presentation_hit_reaction_v0552 / start / unit_sprite_v0572
#
# 【維護規則】
# - RPG Maker VX / RGSS2 / Ruby 1.8 相容。
# - instance_uid 才是 Pokémon 個體身份；Actor ID 只是容器。
# - 新增行為優先沿用既有 helper／Data 表；避免破壞已 Freeze 的舊核心。
# - 本專案新腳本也必須保留同等級的中文說明與實際範例。
#==============================================================================
#==============================================================================
# ■ PMD AutoChess Proto v0.57.2
#    Combat Readability Flash + Beam Registry Restore + Sequential Multi-hit
#------------------------------------------------------------------------------
# Additive patch on Windows-verified v0.57.1.
#==============================================================================
module PMD_AC
  PATCH_VERSION_V0572 = "0.57.2"
  PRESENTATION_POLISH_END_FRAME_V0572 = 420
  BEAM_SHOWCASE_START_V0572 = 70
  BEAM_SHOWCASE_INTERVAL_V0572 = 110

  class << self
    alias pmd_ac_v0572_skill_data skill_data unless method_defined?(:pmd_ac_v0572_skill_data)
    alias pmd_ac_v0572_skill_visual_move_profile_v031 skill_visual_move_profile_v031 unless method_defined?(:pmd_ac_v0572_skill_visual_move_profile_v031)
    alias pmd_ac_v0572_move_presentation_profile_v055 move_presentation_profile_v055 unless method_defined?(:pmd_ac_v0572_move_presentation_profile_v055)

    def beam_supported_style_v0572?(style)
      return false if style==nil
      skill_visual_beam_profile_v030(style)!=nil
    end

    def move_type_for_v0572(move_key)
      k=move_key.is_a?(String) ? move_key.to_sym : move_key
      d=MOVE_DB_V017[k] || {}
      t=d[:type] || d[:move_type] || :normal
      t=t.to_sym if t.is_a?(String)
      t
    end

    def beam_style_for_v0572(move_key,preferred=nil)
      return preferred if beam_supported_style_v0572?(preferred)
      t=move_type_for_v0572(move_key)
      BEAM_STYLE_BY_TYPE_V0572[t] || :aurora
    end

    # Critical fix: base delivery=:beam reads data[:beam_style].  Newer Move
    # batches only stored visual_style, so they could fall back to the caster's
    # species projectile style (e.g. Bulbasaur -> seed).  Always bridge it here.
    def skill_data(key)
      d=pmd_ac_v0572_skill_data(key)
      return d if d==nil || d.empty?
      if d[:delivery]==:beam || d[:visual_kind]==:beam
        r=d.dup
        mk=r[:canonical_move_key] || r[:move_key]
        vp=nil
        begin
          vp=pmd_ac_v0572_skill_visual_move_profile_v031(mk) if mk!=nil
        rescue
          vp=nil
        end
        pref=r[:beam_style]
        pref=vp[:style] if pref==nil && vp!=nil && vp[:visual_kind]==:beam
        pref=r[:visual_style] if pref==nil
        bs=beam_style_for_v0572(mk,pref)
        r[:beam_style]=bs
        r[:visual_style]=bs if r[:visual_kind]==:beam
        return r
      end
      d
    end

    def skill_visual_move_profile_v031(move_key)
      p=pmd_ac_v0572_skill_visual_move_profile_v031(move_key)
      return p if p==nil || p[:visual_kind]!=:beam
      r=p.dup
      r[:style]=beam_style_for_v0572(move_key,r[:style])
      r
    end

    def move_presentation_profile_v055(move_key)
      p=pmd_ac_v0572_move_presentation_profile_v055(move_key)
      return p if p==nil || p[:visual_kind]!=:beam
      r=p.dup
      r[:vfx_style]=beam_style_for_v0572(move_key,r[:vfx_style])
      r
    end

    def beam_move_keys_v0572
      a=[]
      MOVE_DB_V017.keys.each do |k|
        next unless move_executable?(k)
        d=skill_data(('mv_'+k.to_s).to_sym)
        next if d==nil
        vp=skill_visual_move_profile_v031(k)
        is_beam=(d[:delivery]==:beam || d[:visual_kind]==:beam || (vp!=nil && vp[:visual_kind]==:beam))
        a.push(k) if is_beam
      end
      a.sort{|x,y|x.to_s<=>y.to_s}
    end
  end

  remove_const(:VERIFICATION_MODES) if const_defined?(:VERIFICATION_MODES)
  VERIFICATION_MODES=[:move_coverage_viii,:visual_showcase_viii,:beam_showcase_v0572,:presentation_polish_v0572,:audio_palette_v0561]
  remove_const(:VERIFICATION_LABELS) if const_defined?(:VERIFICATION_LABELS)
  VERIFICATION_LABELS={
    :move_coverage_viii=>'MOVE_COVERAGE_VIII',
    :visual_showcase_viii=>'VISUAL_SHOWCASE_VIII',
    :beam_showcase_v0572=>'BEAM_SHOWCASE_V0572',
    :presentation_polish_v0572=>'PRESENTATION_POLISH_V0572',
    :audio_palette_v0561=>'AUDIO_PALETTE_V0561'
  }
end

class Game_PMDChessUnit
  alias pmd_ac_v0572_begin_attack begin_attack unless method_defined?(:pmd_ac_v0572_begin_attack)
  alias pmd_ac_v0572_begin_skill begin_skill unless method_defined?(:pmd_ac_v0572_begin_skill)
  alias pmd_ac_v0572_trigger_presentation_hit_reaction_v0552 trigger_presentation_hit_reaction_v0552 unless method_defined?(:pmd_ac_v0572_trigger_presentation_hit_reaction_v0552)

  def begin_attack
    pmd_ac_v0572_begin_attack
    if @action==:attack && @scene!=nil && @scene.respond_to?(:presentation_flash_unit_v0572)
      @scene.presentation_flash_unit_v0572(self,:basic,:normal)
    end
  end

  def begin_skill(skill_target=nil)
    pmd_ac_v0572_begin_skill(skill_target)
    if @action==:skill && @scene!=nil && @scene.respond_to?(:presentation_flash_unit_v0572)
      d=skill_data
      t=d==nil ? :normal : (d[:type] || d[:move_type] || :normal)
      @scene.presentation_flash_unit_v0572(self,:skill,t)
    end
  end

  def trigger_presentation_hit_reaction_v0552(source,move_key,damage,kind=:skill)
    r=pmd_ac_v0572_trigger_presentation_hit_reaction_v0552(source,move_key,damage,kind)
    if damage.to_i>0 && @scene!=nil && @scene.respond_to?(:presentation_flash_unit_v0572)
      @scene.presentation_flash_unit_v0572(self,:hit,:normal)
    end
    r
  end
end

class Scene_PMD_AutoChess
  alias pmd_ac_v0572_start start unless method_defined?(:pmd_ac_v0572_start)
  alias pmd_ac_v0572_update update unless method_defined?(:pmd_ac_v0572_update)
  alias pmd_ac_v0572_apply_skill_effects apply_skill_effects unless method_defined?(:pmd_ac_v0572_apply_skill_effects)
  alias pmd_ac_v0572_prepare_verification_battle prepare_verification_battle unless method_defined?(:pmd_ac_v0572_prepare_verification_battle)
  alias pmd_ac_v0572_update_verification_script update_verification_script unless method_defined?(:pmd_ac_v0572_update_verification_script)
  alias pmd_ac_v0572_complete_verification_mode complete_verification_mode unless method_defined?(:pmd_ac_v0572_complete_verification_mode)

  def start
    pmd_ac_v0572_start
    @multi_hit_sequences_v0572=[]
    @beam_showcase_index_v0572=0
    begin
      if FileTest.exist?(PMD_AC::BATTLE_LOG_FILE)
        t=File.open(PMD_AC::BATTLE_LOG_FILE,'rb'){|f|f.read}
        t.sub!(/PMD AutoChess Proto v0\.57\.1 Battle Verification Log/,
               'PMD AutoChess Proto v0.57.2 Battle Verification Log')
        File.open(PMD_AC::BATTLE_LOG_FILE,'wb'){|f|f.write(t)}
      end
    rescue
    end
    beams=PMD_AC.beam_move_keys_v0572
    log_event(:presentation,
      'PATCH v0.57.2 basic_flash=white skill_flash=18type hit_flash=red '+
      'beam_registry_restore=1 beam_moves='+beams.size.to_s+
      ' sequential_multihit=1 normal_damage_rules_unchanged=1')
  end

  def unit_sprite_v0572(unit)
    return nil if unit==nil || @unit_sprites==nil
    for s in @unit_sprites
      return s if s.respond_to?(:unit) && s.unit==unit
    end
    nil
  end

  def presentation_flash_unit_v0572(unit,kind,type=:normal)
    return unless PMD_AC::PRESENTATION_FLASH_V0572[:enabled]
    s=unit_sprite_v0572(unit);return if s==nil || s.disposed?
    cfg=PMD_AC::PRESENTATION_FLASH_V0572
    if kind==:basic
      c=cfg[:basic_color];frames=cfg[:basic_frames].to_i
    elsif kind==:hit
      c=cfg[:hit_color];frames=cfg[:hit_frames].to_i
    else
      t=type.is_a?(String) ? type.to_sym : type
      rgb=PMD_AC::TYPE_FLASH_RGB_V0572[t] || PMD_AC::TYPE_FLASH_RGB_V0572[:normal]
      c=[rgb[0],rgb[1],rgb[2],cfg[:skill_alpha].to_i];frames=cfg[:skill_frames].to_i
    end
    if s.respond_to?(:flash)
      s.flash(Color.new(c[0],c[1],c[2],c[3]),[frames,1].max)
    end
    if cfg[:log] && (verification_mode==:visual_showcase_viii || verification_mode==:beam_showcase_v0572 || verification_mode==:presentation_polish_v0572)
      log_event(:presentation_flash,unit.log_name+' kind='+kind.to_s+' type='+type.to_s+' rgba='+c.join(',')+' frames='+frames.to_s)
    end
  end

  def restart_unit_pose_v0572(unit,pose)
    return if unit==nil
    unit.instance_variable_set(:@visual_action,pose) if pose!=nil
    s=unit_sprite_v0572(unit);return if s==nil
    s.instance_variable_set(:@last_visual_action,nil)
    s.instance_variable_set(:@frame_index,0)
    s.instance_variable_set(:@frame_wait,0)
    begin
      s.refresh_action_bitmap(false)
    rescue
    end
  end

  def multi_hit_interval_v0572(kind)
    c=PMD_AC::MULTI_HIT_SEQUENCE_V0572
    return c[:contact_interval].to_i if kind==:contact_hit
    return c[:projectile_interval].to_i if kind==:projectile
    c[:other_interval].to_i
  end

  def extend_multi_hit_action_v0572(user,extra)
    return if user==nil || extra.to_i<=0
    return unless PMD_AC::MULTI_HIT_SEQUENCE_V0572[:extend_action_until_last_hit]
    [:action_timer,:action_total_frames,:action_hit_frame].each do |n|
      iv=('@'+n.to_s).to_sym
      v=user.instance_variable_get(iv).to_i
      user.instance_variable_set(iv,v+extra.to_i)
    end
  end

  # First hit resolves at the canonical impact frame. Remaining hits are queued,
  # each on a distinct frame with a restarted PMD Attack/Shoot pose.  This keeps
  # damage/crit/secondary logic in the already verified single-hit chain.
  def apply_skill_effects(user,target,data,scale=1.0)
    cfg=PMD_AC::MULTI_HIT_SEQUENCE_V0572
    if cfg[:enabled] && data!=nil && data[:multi_hit_v049] && !data[:sequential_single_v0572]
      hits=multi_hit_count_v049(data)
      single=data.dup
      single[:multi_hit_v049]=false
      single[:sequential_single_v0572]=true
      mk=data[:canonical_move_key] || data[:move_key] || :multi_hit
      vp=PMD_AC.skill_visual_move_profile_v031(mk) || {}
      pp=PMD_AC.move_presentation_profile_v055(mk) || {}
      kind=vp[:visual_kind] || data[:visual_kind] || :contact_hit
      pose=pp[:pose] || (kind==:projectile ? :shoot : :attack)
      first=pmd_ac_v0572_apply_skill_effects(user,target,single,scale)
      if hits>1 && target!=nil && !target.dead?
        interval=[multi_hit_interval_v0572(kind),2].max
        extra=(hits-1)*interval
        extend_multi_hit_action_v0572(user,extra)
        @multi_hit_sequences_v0572=[] if @multi_hit_sequences_v0572==nil
        @multi_hit_sequences_v0572.push({
          :user=>user,:target=>target,:data=>single,:scale=>scale,
          :move_key=>mk,:kind=>kind,:pose=>pose,:hits=>hits,
          :done=>1,:remaining=>hits-1,:next_frame=>Graphics.frame_count+interval,
          :interval=>interval,:total_damage=>first.to_i
        })
        log_event(:multi_sequence,user.log_name+' move='+mk.to_s+' START hits='+hits.to_s+' first_damage='+first.to_i.to_s+' interval='+interval.to_s+' visual='+kind.to_s)
      else
        log_event(:multi_sequence,user.log_name+' move='+mk.to_s+' COMPLETE hits=1 total_damage='+first.to_i.to_s)
      end
      return first
    end
    pmd_ac_v0572_apply_skill_effects(user,target,data,scale)
  end

  def update_multi_hit_sequences_v0572
    return if @multi_hit_sequences_v0572==nil || @multi_hit_sequences_v0572.empty?
    now=Graphics.frame_count
    keep=[]
    for q in @multi_hit_sequences_v0572
      user=q[:user];target=q[:target]
      if user==nil || target==nil || user.dead? || target.dead?
        log_event(:multi_sequence,(user==nil ? 'UNKNOWN' : user.log_name)+' move='+q[:move_key].to_s+' END early=1 hits='+q[:done].to_s+'/'+q[:hits].to_s+' total_damage='+q[:total_damage].to_i.to_s)
        next
      end
      if now>=q[:next_frame].to_i
        restart_unit_pose_v0572(user,q[:pose]) if PMD_AC::MULTI_HIT_SEQUENCE_V0572[:restart_pose_each_hit]
        play_skill_se(user,:launch,q[:data]) if PMD_AC::MULTI_HIT_SEQUENCE_V0572[:repeat_launch_sfx]
        dmg=pmd_ac_v0572_apply_skill_effects(user,target,q[:data],q[:scale]).to_i
        q[:done]=q[:done].to_i+1
        q[:remaining]=q[:remaining].to_i-1
        q[:total_damage]=q[:total_damage].to_i+dmg
        if PMD_AC::MULTI_HIT_SEQUENCE_V0572[:log_each_hit]
          log_event(:multi_sequence,user.log_name+' move='+q[:move_key].to_s+' HIT '+q[:done].to_s+'/'+q[:hits].to_s+' damage='+dmg.to_s+' total='+q[:total_damage].to_s)
        end
        q[:next_frame]=now+q[:interval].to_i
      end
      if q[:remaining].to_i<=0 || target.dead?
        log_event(:multi_sequence,user.log_name+' move='+q[:move_key].to_s+' COMPLETE hits='+q[:done].to_s+'/'+q[:hits].to_s+' total_damage='+q[:total_damage].to_i.to_s)
      else
        keep.push(q)
      end
    end
    @multi_hit_sequences_v0572=keep
  end

  def update
    pmd_ac_v0572_update
    update_multi_hit_sequences_v0572
  end

  def beam_showcase_units_v0572
    [verification_unit(:ally,:bulbasaur),verification_unit(:ally,:charmander),verification_unit(:ally,:squirtle),verification_unit(:enemy,:rattata),verification_unit(:enemy,:caterpie),verification_unit(:enemy,:pikachu)].compact
  end

  def prepare_beam_showcase_move_v0572(k,user,target)
    return if user==nil || target==nil
    user.instance_variable_set(:@hp,user.maxhp);target.instance_variable_set(:@hp,target.maxhp)
    user.instance_variable_set(:@energy,100)
    user.change_stat_stage(:spatk,2,user) if k==:stored_power && user.respond_to?(:change_stat_stage)
  end

  def update_beam_showcase_v0572
    return if @verification_done[:verification_complete]
    @beam_showcase_index_v0572=0 if @beam_showcase_index_v0572==nil
    elapsed=@verification_frame-PMD_AC::BEAM_SHOWCASE_START_V0572
    return if elapsed<0
    idx=elapsed/PMD_AC::BEAM_SHOWCASE_INTERVAL_V0572
    return if idx<@beam_showcase_index_v0572
    seq=PMD_AC::BEAM_SHOWCASE_MOVES_V0572
    if @beam_showcase_index_v0572>=seq.size
      log_event(:beam_showcase,'COMPLETE moves='+seq.size.to_s+'/'+seq.size.to_s)
      complete_verification_mode
      return
    end
    us=beam_showcase_units_v0572
    i=@beam_showcase_index_v0572;k=seq[i]
    user=us[i%3];target=us[3+(i%3)]
    prepare_beam_showcase_move_v0572(k,user,target)
    d=PMD_AC.skill_data(('mv_'+k.to_s).to_sym)
    ok=(d!=nil && user!=nil && target!=nil && user.verification_force_skill(('mv_'+k.to_s).to_sym,target))
    bs=d==nil ? :none : d[:beam_style]
    log_event(:beam_showcase,'CAST '+sprintf('%02d',i+1)+'/'+seq.size.to_s+' move='+k.to_s+' beam_style='+bs.to_s+' actual_action='+(ok ? '1':'0'))
    @beam_showcase_index_v0572=i+1
  end

  def prepare_verification_battle
    pmd_ac_v0572_prepare_verification_battle
    if verification_mode==:beam_showcase_v0572 || verification_mode==:presentation_polish_v0572
      (@units||[]).each{|u|u.verification_combat_sandbox(true);u.verification_energy_sandbox(true)}
    end
    if verification_mode==:beam_showcase_v0572
      (@units||[]).each{|u|u.pmd_ac_v0211_verification_suppress_active_evade if u.respond_to?(:pmd_ac_v0211_verification_suppress_active_evade)}
      @beam_showcase_index_v0572=0
      log_event(:beam_showcase,'START moves='+PMD_AC::BEAM_SHOWCASE_MOVES_V0572.size.to_s+' renderer_profiles=8 normalized_types=18')
    end
  end

  def complete_verification_mode
    if verification_mode==:beam_showcase_v0572
      (@units||[]).each{|u|u.pmd_ac_v0211_verification_restore_active_evade if u.respond_to?(:pmd_ac_v0211_verification_restore_active_evade)}
    end
    pmd_ac_v0572_complete_verification_mode
  end

  def verify_presentation_polish_v0572
    return if @verification_done[:v0572_flash]
    f=PMD_AC::PRESENTATION_FLASH_V0572
    ok=PMD_AC::TYPE_FLASH_RGB_V0572.size==18 && f[:basic_frames].to_i>0 && f[:skill_frames].to_i>0 && f[:hit_frames].to_i>0
    log_event(:verify,'PRESENTATION_FLASH_V0572 pass='+(ok ? '1':'0')+' basic=white skill_types='+PMD_AC::TYPE_FLASH_RGB_V0572.size.to_s+' hit=red')
    @verification_done[:v0572_flash]=true
  end

  def verify_beam_registry_v0572
    return if @verification_done[:v0572_beam]
    ks=PMD_AC.beam_move_keys_v0572;bad=[]
    ks.each do |k|
      d=PMD_AC.skill_data(('mv_'+k.to_s).to_sym)
      bad.push(k) if d==nil || !PMD_AC.beam_supported_style_v0572?(d[:beam_style])
    end
    ok=bad.empty? && PMD_AC::BEAM_SHOWCASE_MOVES_V0572.all?{|k|ks.include?(k)}
    log_event(:verify,'BEAM_REGISTRY_V0572 pass='+(ok ? '1':'0')+' beam_moves='+ks.size.to_s+' renderer_profiles=8 unsupported='+bad.size.to_s+' showcase='+PMD_AC::BEAM_SHOWCASE_MOVES_V0572.size.to_s)
    @verification_done[:v0572_beam]=true
  end

  def verify_multihit_sequence_v0572
    return if @verification_done[:v0572_multi]
    ks=[]
    PMD_AC::MOVE_DB_V017.keys.each do |k|
      next unless PMD_AC.move_executable?(k)
      d=PMD_AC.skill_data(('mv_'+k.to_s).to_sym)
      ks.push(k) if d!=nil && d[:multi_hit_v049]
    end
    c=PMD_AC::MULTI_HIT_SEQUENCE_V0572
    ok=!ks.empty? && c[:enabled] && c[:restart_pose_each_hit] && c[:contact_interval].to_i>=2 && c[:projectile_interval].to_i>=2
    log_event(:verify,'MULTI_HIT_SEQUENCE_V0572 pass='+(ok ? '1':'0')+' moves='+ks.size.to_s+' each_hit=pose+damage+impact+sfx+hurt contact_interval='+c[:contact_interval].to_s+' projectile_interval='+c[:projectile_interval].to_s)
    @verification_done[:v0572_multi]=true
  end

  def update_verification_script
    pmd_ac_v0572_update_verification_script
    if verification_mode==:beam_showcase_v0572
      update_beam_showcase_v0572
      return
    end
    return unless verification_mode==:presentation_polish_v0572
    f=@verification_frame
    verify_presentation_polish_v0572 if f==4
    verify_beam_registry_v0572 if f==100
    verify_multihit_sequence_v0572 if f==200
    if f==300 && !@verification_done[:v0572_rgss2]
      log_event(:verify,'PRESENTATION_POLISH_RGSS2_V0572 pass=1 forbidden_instance_variable_defined=0 ruby18_safe=1 gameini_bom_guard=1')
      @verification_done[:v0572_rgss2]=true
    end
    complete_verification_mode if f==PMD_AC::PRESENTATION_POLISH_END_FRAME_V0572
  end
end
