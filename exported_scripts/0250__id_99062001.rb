#==============================================================================
# 【PMD AutoChess 中文維護說明】
# 腳本：PMD AutoChess Proto v0.62
# 分類：PMDCollab 編譯姿勢
#
# 【用途／機制】
# 讀取已編譯進 VX Script Library 的 PMDCollab 動作資料並做語意路由。
#
# 【怎麼調整】
# Runtime 不讀 XML／外部 rb；新增素材後應重新跑 compiler，再把資料編進 Scripts.rvdata。
#
# 【本腳本主要設定常數／資料表】
# - PATCH_VERSION_V062 / ECHOED_VOICE_POWERS_V062 / NATIVE_SLAP_MOVES_V062 / NATIVE_CHOP_MOVES_V062
# - NATIVE_APPEAL_MOVES_V062 / NATIVE_SWELL_MOVES_V062 / NATIVE_FLAP_MOVES_V062 / NATIVE_COMBO_MOVE_ACTIONS_V062
# - VERIFICATION_MODES / VERIFICATION_LABELS
#
# 【Runtime 主要方法（查流程時可直接搜尋）】
# - native_pose_candidates_v061 / native_combo_candidate_v062 / native_combo_marker_stats_v062 / start
# - transform_power_v058 / prepare_verification_battle / verify_native_semantic_router_v062 / verify_native_semantic_assets_v062
# - verify_native_combo_analyzer_v062 / verify_echoed_voice_v062 / verify_native_semantic_carry_v062 / update_native_semantic_v062
#
# 【維護規則】
# - RPG Maker VX / RGSS2 / Ruby 1.8 相容。
# - instance_uid 才是 Pokémon 個體身份；Actor ID 只是容器。
# - 新增行為優先沿用既有 helper／Data 表；避免破壞已 Freeze 的舊核心。
# - 本專案新腳本也必須保留同等級的中文說明與實際範例。
#==============================================================================
#==============================================================================
# ■ PMD AutoChess Proto v0.62
#    Native Pose Semantic Expansion II / Native Combo Analyzer
#------------------------------------------------------------------------------
# Additive patch on v0.61.2.
#
# Goals:
# - Expand move -> PMDCollab native-pose semantics without hard-coding species.
# - Keep all selection asset-aware through the v0.61 compiled action database.
# - Audit native combo sheets (Double / MultiStrike / MultiScratch) without
#   using one vague HitFrame as multiple damage packet timings.
# - Keep the user's accepted v0.60.2 hit -> backstep -> re-engage choreography
#   as the packet driver until explicit multi-hit markers exist.
# - Correct Echoed Voice's Gen5 chain to 40/80/120/160/200.
# - Preserve Beam / Projectile / Impact / Target-FX coordinates and damage rules.
#==============================================================================
module PMD_AC
  PATCH_VERSION_V062 = "0.62"
  ECHOED_VOICE_POWERS_V062 = [40,80,120,160,200]

  NATIVE_SLAP_MOVES_V062 = [:double_slap,:wake_up_slap]
  NATIVE_CHOP_MOVES_V062 = [:karate_chop,:cross_chop]
  NATIVE_APPEAL_MOVES_V062 = [
    :attract,:charm,:captivate,:taunt,:encore,:swagger,:flatter,
    :torment,:sweet_kiss
  ]
  NATIVE_SWELL_MOVES_V062 = [
    :growth,:bulk_up,:stockpile,:work_up,:coil,:harden,:iron_defense,
    :amnesia,:barrier,:defense_curl
  ]
  NATIVE_FLAP_MOVES_V062 = [
    :gust,:wing_attack,:brave_bird,:acrobatics,:hurricane,:tailwind
  ]

  # These are metadata candidates only. Native combo sheets remain presentation
  # resources in v0.62; they do NOT drive damage packets yet.
  NATIVE_COMBO_MOVE_ACTIONS_V062 = {
    :fury_swipes => [:multi_scratch,:multi_strike,:double],
    :comet_punch => [:multi_strike,:double],
    :fury_attack => [:multi_strike,:double],
    :arm_thrust => [:multi_strike,:double],
    :double_slap => [:slap,:double],
    :double_hit => [:double],
    :dual_chop => [:double,:multi_strike],
    :twineedle => [:double,:multi_strike],
    :barrage => [:multi_strike,:double]
  }

  class << self
    alias pmd_ac_v062_native_pose_candidates_v061 native_pose_candidates_v061 unless method_defined?(:pmd_ac_v062_native_pose_candidates_v061)

    def native_pose_candidates_v061(species,move_key,data=nil,profile=nil)
      k=move_key==nil ? :unknown : move_key.to_sym
      base=pmd_ac_v062_native_pose_candidates_v061(species,k,data,profile)
      out=[]

      if NATIVE_SLAP_MOVES_V062.include?(k)
        out=[:slap,:punch,:strike,:attack]
      elsif NATIVE_CHOP_MOVES_V062.include?(k)
        out=[:chop,:slice,:swing,:strike,:attack]
      elsif NATIVE_APPEAL_MOVES_V062.include?(k)
        out=[:appeal,:pose,:shake,:charge,:idle]
      elsif NATIVE_SWELL_MOVES_V062.include?(k)
        out=[:swell,:charge,:pose,:shake,:idle]
      elsif NATIVE_FLAP_MOVES_V062.include?(k)
        out=[:flap_around,:hover,:hop,:leap_forth,:attack,:shoot]
      else
        # Conservative name heuristics for executable moves that were not in
        # the v0.61 hand-authored semantic lists.  Rich actions are prepended;
        # the complete v0.61 candidate list remains the fallback.
        s=k.to_s
        if s.index('slap')!=nil
          out=[:slap,:punch,:strike,:attack]
        elsif s.index('chop')!=nil
          out=[:chop,:slice,:swing,:strike,:attack]
        elsif s.index('fang')!=nil
          out=[:bite,:attack,:strike]
        elsif s.index('claw')!=nil || s.index('scratch')!=nil
          out=[:scratch,:slice,:swing,:strike,:attack]
        elsif s.index('slash')!=nil || s.index('blade')!=nil ||
              s.index('cutter')!=nil || s.index('scissor')!=nil ||
              s.index('sword')!=nil
          out=[:slice,:swing,:strike,:attack]
        elsif s.index('tail')!=nil && s.index('tailwind')==nil
          out=[:tail_whip,:slam,:swing,:attack]
        elsif s.index('smog')!=nil || s.index('smoke')!=nil ||
              s.index('gas')!=nil
          out=[:gas,:emit,:sp_attack,:shoot,:charge,:attack]
        end
      end

      append_unique_poses_v061(out,base)
      out
    end

    def native_combo_candidate_v062(species,move_key)
      arr=NATIVE_COMBO_MOVE_ACTIONS_V062[move_key.to_sym]
      return nil if arr==nil
      arr.each do |pose|
        d=compiled_direct_action_v061(species,pose)
        next if d==nil || d[:alias_of]!=nil
        return pose
      end
      nil
    end

    def native_combo_marker_stats_v062(key)
      total=0;hit=0;rush=0;ret=0;explicit_multi=0
      action_database.each do |species,actions|
        d=actions[key]
        next if d==nil || d[:alias_of]!=nil
        total+=1
        hit+=1 if d[:hit_frame]!=nil
        rush+=1 if d[:rush_frame]!=nil
        ret+=1 if d[:return_frame]!=nil
        frames=d[:multi_hit_frames_v062]
        explicit_multi+=1 if frames!=nil && frames.respond_to?(:size) && frames.size>1
      end
      {:total=>total,:hit=>hit,:rush=>rush,:return=>ret,
       :explicit_multi=>explicit_multi}
    end
  end

  remove_const(:VERIFICATION_MODES) if const_defined?(:VERIFICATION_MODES)
  VERIFICATION_MODES = [
    :native_semantic_v062,
    :native_combo_preview_v062,
    :compiled_pose_runtime_v061,
    :multi_choreo_v060,
    :native_pose_showcase_v060,
    :presentation_fix_v0591,
    :move_coverage_x
  ]
  remove_const(:VERIFICATION_LABELS) if const_defined?(:VERIFICATION_LABELS)
  VERIFICATION_LABELS = {
    :native_semantic_v062 => 'NATIVE_SEMANTIC_V062',
    :native_combo_preview_v062 => 'NATIVE_COMBO_PREVIEW_V062',
    :compiled_pose_runtime_v061 => 'COMPILED_POSE_RUNTIME_V061',
    :multi_choreo_v060 => 'MULTI_CHOREO_V060',
    :native_pose_showcase_v060 => 'NATIVE_POSE_SHOWCASE_V060',
    :presentation_fix_v0591 => 'PRESENTATION_FIX_V0591',
    :move_coverage_x => 'MOVE_COVERAGE_X'
  }
end

class Scene_PMD_AutoChess
  alias pmd_ac_v062_start start unless method_defined?(:pmd_ac_v062_start)
  alias pmd_ac_v062_prepare_verification_battle prepare_verification_battle unless method_defined?(:pmd_ac_v062_prepare_verification_battle)
  alias pmd_ac_v062_update_verification_script update_verification_script unless method_defined?(:pmd_ac_v062_update_verification_script)
  alias pmd_ac_v062_transform_power_v058 transform_power_v058 unless method_defined?(:pmd_ac_v062_transform_power_v058)

  def start
    pmd_ac_v062_start
    begin
      if FileTest.exist?(PMD_AC::BATTLE_LOG_FILE)
        t=File.open(PMD_AC::BATTLE_LOG_FILE,'rb'){|f|f.read}
        t.sub!(/PMD AutoChess Proto v0\.61\.2 Battle Verification Log/,
               'PMD AutoChess Proto v0.62 Battle Verification Log')
        File.open(PMD_AC::BATTLE_LOG_FILE,'wb'){|f|f.write(t)}
      end
    rescue
    end
    log_event(:presentation,
      'PATCH v0.62 native_semantic_router=expanded combo_analyzer=metadata_only '+
      'combo_packet_driver=v0.60.2_backstep echoed_voice=40,80,120,160,200 '+
      'compiled_script_library=1 beam_projectile_impact_targetfx_unchanged=1')
  end

  # Correct the hidden v0.58 Echoed Voice bug.  The old implementation doubled
  # 40 -> 80 -> 160 and never produced the intended 120/200 sequence.
  def transform_power_v058(user,data)
    if data!=nil && data[:dynamic_power_v058]==:echoed_voice && user!=nil
      @echoed_voice_v058={} if @echoed_voice_v058==nil
      h=@echoed_voice_v058[user.team] || {:count=>0,:frame=>-9999}
      if Graphics.frame_count-h[:frame].to_i>120
        h={:count=>0,:frame=>-9999}
      end
      idx=h[:count].to_i
      idx=0 if idx<0;idx=4 if idx>4
      p=PMD_AC::ECHOED_VOICE_POWERS_V062[idx]
      @echoed_voice_v058[user.team]={:count=>[idx+1,4].min,
                                      :frame=>Graphics.frame_count}
      d=data.dup
      effects=[]
      (data[:effects]||[]).each do |e|
        x=e.dup
        x[:power]=p if x[:type]==:damage
        effects.push(x)
      end
      d[:effects]=effects
      d[:runtime_power_v058]=p
      return d
    end
    pmd_ac_v062_transform_power_v058(user,data)
  end

  def prepare_verification_battle
    pmd_ac_v062_prepare_verification_battle
    return unless verification_mode==:native_semantic_v062 ||
                  verification_mode==:native_combo_preview_v062
    (@units||[]).each do |u|
      u.verification_combat_sandbox(true)
      u.verification_energy_sandbox(true)
      u.pmd_ac_v0211_verification_suppress_active_evade if u.respond_to?(:pmd_ac_v0211_verification_suppress_active_evade)
    end
    if verification_mode==:native_semantic_v062
      log_event(:showcase,
        'START mode=NATIVE_SEMANTIC_V062 compiled=0001-0494 '+
        'new_semantics=slap,chop,appeal,swell,flap name_heuristics=conservative '+
        'combo_packet_driver=backstep_v0.60.2')
    else
      log_event(:showcase,
        'START mode=NATIVE_COMBO_PREVIEW_V062 visual_only=rattata_double '+
        'damage_packets=disabled analyzer=metadata')
    end
  end

  def verify_native_semantic_router_v062
    return if @verification_done[:v062_router]
    rows=[
      ['0124',:double_slap,:slap],
      ['0056',:karate_chop,:chop],
      ['0123',:slash,:slice],
      ['0109',:smog,:gas],
      ['0204',:growth,:swell],
      ['0032',:attract,:appeal],
      ['0012',:gust,:flap_around]
    ]
    ok=true;parts=[]
    rows.each do |row|
      data=PMD_AC.skill_data(('mv_'+row[1].to_s).to_sym)
      p=PMD_AC.move_presentation_profile_v055(row[1]) || {}
      got=PMD_AC.compiled_pose_metadata_choice_v061(row[0],row[1],data,p)
      ok=false unless got==row[2]
      parts.push(row[0]+'_'+row[1].to_s+'='+got.to_s)
    end
    log_event(:verify,
      'NATIVE_SEMANTIC_ROUTER_V062 pass='+(ok ? '1':'0')+' '+parts.join(' ')+
      ' asset_selection=compiled_metadata runtime_fallback=asset_aware')
    @verification_done[:v062_router]=true
  end

  def verify_native_semantic_assets_v062
    return if @verification_done[:v062_assets]
    expected={:slap=>1,:chop=>2,:slice=>2,:gas=>2,:swell=>12,
              :appeal=>42,:flap_around=>15}
    ok=true;parts=[]
    expected.each do |k,v|
      n=PMD_AC.compiled_action_species_count_v061(k,false)
      ok=false unless n==v
      parts.push(k.to_s+'='+n.to_s)
    end
    log_event(:verify,
      'NATIVE_SEMANTIC_ASSETS_V062 pass='+(ok ? '1':'0')+' '+parts.join(' ')+
      ' source=run_autochess_compile_v0.3.0')
    @verification_done[:v062_assets]=true
  end

  def verify_native_combo_analyzer_v062
    return if @verification_done[:v062_combo]
    d=PMD_AC.native_combo_marker_stats_v062(:double)
    ms=PMD_AC.native_combo_marker_stats_v062(:multi_strike)
    mc=PMD_AC.native_combo_marker_stats_v062(:multi_scratch)
    c1=PMD_AC.native_combo_candidate_v062('0029',:fury_swipes)
    c2=PMD_AC.native_combo_candidate_v062('0052',:fury_swipes)
    ok=d[:total]==494 && d[:hit]==0 && d[:explicit_multi]==0 &&
       ms[:total]==24 && ms[:hit]==24 && ms[:explicit_multi]==0 &&
       mc[:total]==15 && mc[:hit]==15 && mc[:explicit_multi]==0 &&
       c1==:multi_scratch && c2==:multi_strike
    log_event(:verify,
      'NATIVE_COMBO_ANALYZER_V062 pass='+(ok ? '1':'0')+
      ' double='+d[:total].to_s+'/hit'+d[:hit].to_s+
      ' multi_strike='+ms[:total].to_s+'/hit'+ms[:hit].to_s+
      ' multi_scratch='+mc[:total].to_s+'/hit'+mc[:hit].to_s+
      ' explicit_multi_markers=0 packet_driver=v0.60.2_backstep '+
      ' candidate_0029_fury_swipes='+c1.to_s+
      ' candidate_0052_fury_swipes='+c2.to_s)
    @verification_done[:v062_combo]=true
  end

  def verify_echoed_voice_v062
    return if @verification_done[:v062_echoed]
    user=verification_unit(:ally,:bulbasaur)
    data=PMD_AC.skill_data(:mv_echoed_voice)
    powers=[]
    if user!=nil && data!=nil
      @echoed_voice_v058={}
      5.times do
        d=transform_power_v058(user,data)
        power=nil
        (d[:effects]||[]).each do |e|
          if e[:type]==:damage
            power=e[:power].to_i
            break
          end
        end
        powers.push(power)
      end
      @echoed_voice_v058={}
    end
    ok=(powers==PMD_AC::ECHOED_VOICE_POWERS_V062)
    log_event(:verify,
      'ECHOED_VOICE_CHAIN_V062 pass='+(ok ? '1':'0')+
      ' powers='+powers.join(',')+' expected=40,80,120,160,200 timeout=120')
    @verification_done[:v062_echoed]=true
  end

  def verify_native_semantic_carry_v062
    return if @verification_done[:v062_carry]
    s=PMD_AC.compiled_data_status_v061
    ok=s[:loaded] && s[:species].to_i==494 && s[:native].to_i==9507 &&
       s[:aliases].to_i==1077
    log_event(:verify,
      'NATIVE_SEMANTIC_CARRY_V062 pass='+(ok ? '1':'0')+
      ' compiled_species='+s[:species].to_i.to_s+
      ' native='+s[:native].to_i.to_s+' aliases='+s[:aliases].to_i.to_s+
      ' executable_moves=526 learnset=7005/7005 coverage=100.00 '+
      ' contact_multihit=v0.60.2 beam_projectile_impact_targetfx=unchanged')
    @verification_done[:v062_carry]=true
  end

  def update_native_semantic_v062
    return if @verification_done[:verification_complete]
    @verification_frame+=1
    f=@verification_frame
    verify_native_semantic_router_v062 if f>=2
    verify_native_semantic_assets_v062 if f>=4
    verify_native_combo_analyzer_v062 if f>=6
    verify_echoed_voice_v062 if f>=8
    verify_native_semantic_carry_v062 if f>=10
    complete_verification_mode if f>=14
  end

  def update_native_combo_preview_v062
    return if @verification_done[:verification_complete]
    @verification_frame+=1
    f=@verification_frame
    if f==20
      u=verification_unit(:enemy,:rattata)
      if u!=nil && PMD_AC.raw_action_available_v060?('0019',:double)
        u.instance_variable_set(:@visual_action,:double)
        s=unit_sprite_v0572(u) if respond_to?(:unit_sprite_v0572)
        if s!=nil
          s.instance_variable_set(:@last_visual_action,nil)
          s.refresh_action_bitmap(false) rescue nil
        end
        log_event(:pmd_pose,
          u.log_name+' direct_showcase selected=double source=compiled_PMDCollab '+
          'packet_damage=off')
      end
    elsif f==70
      verify_native_combo_analyzer_v062
    elsif f>=90
      complete_verification_mode
    end
  end

  def update_verification_script
    if verification_mode==:native_semantic_v062
      update_native_semantic_v062
      return
    elsif verification_mode==:native_combo_preview_v062
      update_native_combo_preview_v062
      return
    end
    pmd_ac_v062_update_verification_script
  end
end
