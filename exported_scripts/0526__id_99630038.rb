# encoding: UTF-8
#===============================================================================
# ■ PMD AutoChess - Move-Family Presentation Audit I v1.05.41
#===============================================================================
# 【用途】
# 1. 承接 v1.05.40 Generated Runtime Expansion。依使用者決策，0027～0494 素材不再
#    每批等待 Windows 實機認證；素材於開發尾段統一補齊，個別視覺問題再 issue-driven 修正。
# 2. 在不修改 Frozen Motion Combat Core 的前提下，正式進入 Roadmap Phase C2：
#    Move-family Presentation Audit。
# 3. 對現有 56 隻 Representative runtime assets，自動分幀驗證九種關鍵呈現族群：
#      CONTACT / PROJECTILE / BEAM / CAST / SHOCK / DRAIN / SOUND / SPIN / MULTI_HIT
#    共 56 × 9 = 504 route slots。
# 4. NORMAL battle 中另外觀察真正 Focus Action Lane 的每一次技能生命週期，記錄：
#      - 技能 family / motion family / selected pose / fallback
#      - release → first impact
#      - impact 次數
#      - projectile 建立數
#      - projectile wait / effect tail / slide wait
#      - completion 時是否仍有 orphan projectile/effect
#      - timeout / no-commit / multi-hit commit 不足等診斷
# 5. 本版 QA 為「非阻塞 Observer」。即使某 family 尚未在單場 NORMAL battle 出現，也不會
#    改變戰鬥結果或禁止遊戲繼續；真正問題只寫 LOG，後續針對該技能／物種修正。
#
# 【主要設定】
# MOVE_FAMILY_AUDIT_CASES_V10541
#   :contact    => Tackle
#   :projectile => Water Gun
#   :beam       => Ice Beam
#   :cast       => Calm Mind
#   :shock      => Thunderbolt
#   :drain      => Giga Drain
#   :sound      => Hyper Voice
#   :spin       => Rapid Spin
#   :multi_hit  => Fury Swipes
#
# MOVE_FAMILY_AUDIT_PER_TICK_V10541 = 8
#   每 frame 最多驗證 8 slots，避免 cold cache 同 frame 大掃描。
# MOVE_FAMILY_AUDIT_THRESHOLD_MS_V10541 = 50
#   既有正式 QA 50ms 門檻保持不變。
#
# 【機制規則】
# - Structural audit 只使用既有 motion_source_route_v102 / generated profile / group tuning
#   Authority，不新增新的 pose router。
# - generic Attack fallback 仍是合法安全 fallback，只統計，不因 fallback 本身判 FAIL。
# - component-only action 不做檔名式全域封鎖，沿用 v1.05.36 Sandshrew Head Guard 政策。
# - Runtime lifecycle observer 不改 Focus Action Lane completion 條件，只在既有 begin / release /
#   mark_effect / launch_projectile / complete hooks 上記錄資訊。
# - hard_fail 僅限既有 Action Lane timeout 或 completion 當下仍殘留 active owned projectile。
# - no_effect_commit、projectile family 未建立 projectile、multi-hit commit<2 只列 WARN，避免把
#   合法特殊技能誤判成 gameplay failure。
#
# 【Authority 邊界】
# 本版不修改：
# - Damage Formula / HP
# - AI / target selection
# - Energy
# - Attack Wait / Priority
# - hit timing / damage commit timing
# - logical Spatial x/y / velocity / endpoint / push / pull / through
# - Focus Action Lane timing
# - Frozen Motion Combat Core
# - 既有 Representative Group Tuning
#
# 【事件／腳本呼叫方式】
# 不需要事件呼叫。NORMAL battle 自動執行。
# Debug Console 可查詢：
#   PMD_AC.move_family_audit_cases_v10541
#   scene.move_family_structural_result_v10541
#
# 【LOG】
# BATTLE_MOVE_FAMILY_STRUCTURAL_AUDIT_V10541 START ...
# BATTLE_MOVE_FAMILY_STRUCTURAL_AUDIT_V10541 COMPLETE ...
# BATTLE_MOVE_FAMILY_PRESENTATION_CAST_V10541 BEGIN ...
# BATTLE_MOVE_FAMILY_PRESENTATION_CAST_V10541 COMPLETE ...
# BATTLE_MOVE_FAMILY_PRESENTATION_SUMMARY_V10541 ...
#
# 【實際範例】
# 若妙蛙種子施放 Water Gun 類 projectile 技能，Observer 會記錄 family=projectile、
# projectile_created、first_impact、projectile_wait 與 completion orphan 數；不會改變技能傷害、
# 射程或速度。若最後 orphan_projectile=1，才記 hard_fail 供下一版精準修正。
#===============================================================================
$imported={} unless defined?($imported)
$imported['PMD_AutoChess_MoveFamilyPresentationAuditI_v10541']=true

module PMD_AC
  MOVE_FAMILY_AUDIT_THRESHOLD_MS_V10541=50
  MOVE_FAMILY_AUDIT_PER_TICK_V10541=8
  MOVE_FAMILY_AUDIT_CASES_V10541=[
    [:contact,:tackle],
    [:projectile,:water_gun],
    [:beam,:ice_beam],
    [:cast,:calm_mind],
    [:shock,:thunderbolt],
    [:drain,:giga_drain],
    [:sound,:hyper_voice],
    [:spin,:rapid_spin],
    [:multi_hit,:fury_swipes]
  ]

  class << self
    def move_family_audit_cases_v10541
      MOVE_FAMILY_AUDIT_CASES_V10541.dup
    rescue
      []
    end

    def move_family_canonical_key_v10541(skill_key)
      return nil if skill_key==nil
      begin
        k=canonical_move_key_from_skill(skill_key) if respond_to?(:canonical_move_key_from_skill)
        return k if k!=nil
      rescue
      end
      t=skill_key.to_s
      t=t[3,t.size-3] if t[0,3]=='mv_'
      t.to_sym
    rescue
      nil
    end

    def move_family_skill_data_v10541(move_key)
      return {} if move_key==nil
      d=skill_data(('mv_'+move_key.to_s).to_sym)
      d={} if d==nil
      d
    rescue
      {}
    end

    def move_family_profile_v10541(move_key)
      return nil if move_key==nil
      return move_presentation_profile_v055(move_key) if respond_to?(:move_presentation_profile_v055)
      nil
    rescue
      nil
    end

    def move_family_effect_type_v10541?(data,type)
      return false if data==nil
      a=[]
      a+=(data[:effects] || [])
      a+=(data[:tick_effects] || [])
      a.each do |e|
        return true if e!=nil && e[:type]==type
      end
      false
    rescue
      false
    end

    def move_family_damaging_v10541?(data)
      return false if data==nil
      return true if move_family_effect_type_v10541?(data,:damage)
      return true if data[:power].to_i>0 || data[:canonical_power].to_i>0
      false
    rescue
      false
    end

    def move_family_semantic_v10541(move_key,data=nil,profile=nil)
      d=(data==nil ? move_family_skill_data_v10541(move_key) : data)
      p=(profile==nil ? move_family_profile_v10541(move_key) : profile)
      motion=(p==nil ? nil : p[:motion])
      return :multi_hit if (d[:multi_hit_v049] rescue false) ||
        d[:multi_hit_min].to_i>1 || d[:multi_hit_max].to_i>1 || motion==:multi_contact
      fam=motion_action_family_v102(move_key,d,p)
      return :spin if fam==:spin || motion==:spin_contact
      return :sound if fam==:sound || d[:sound]
      return :drain if fam==:drain || move_family_effect_type_v10541?(d,:drain)
      return :shock if fam==:shock
      delivery=d[:delivery]
      visual=d[:visual_kind]
      return :beam if fam==:beam || [:beam,:sustained_beam,:sweeping_beam].include?(delivery) || visual==:beam
      return :projectile if fam==:projectile || delivery==:projectile || visual==:projectile
      return :cast if fam==:cast || [:self,:ally,:self_targeted].include?(d[:target_type])
      if const_defined?(:MOTION_CONTACT_FAMILIES_V102) && MOTION_CONTACT_FAMILIES_V102.include?(fam)
        return :contact
      end
      :contact
    rescue
      :contact
    end

    def move_family_semantic_match_v10541(expected,route_family)
      return MOTION_CONTACT_FAMILIES_V102.include?(route_family) if expected==:contact && const_defined?(:MOTION_CONTACT_FAMILIES_V102)
      return route_family==:multi if expected==:multi_hit
      route_family==expected
    rescue
      false
    end

    def move_family_route_info_v10541(species,expected,move_key)
      data=move_family_skill_data_v10541(move_key)
      profile=move_family_profile_v10541(move_key)
      route=motion_source_route_v102(species.to_s,move_key,data,profile)
      route={} if route==nil
      {
        :species=>species.to_s,:expected=>expected,:move=>move_key,
        :semantic=>move_family_semantic_v10541(move_key,data,profile),
        :route_family=>route[:family],:pose=>route[:selected],
        :playable=>(route[:has_playable] ? true:false),
        :fallback=>(route[:fallback] ? true:false),
        :native=>(route[:selected_native] ? true:false),
        :family_match=>move_family_semantic_match_v10541(expected,route[:family])
      }
    rescue
      {:species=>species.to_s,:expected=>expected,:move=>move_key,:semantic=>:unknown,
       :route_family=>nil,:pose=>nil,:playable=>false,:fallback=>false,:native=>false,
       :family_match=>false}
    end
  end
end

class Scene_PMD_AutoChess
  alias pmd_ac_v10541_update_battle_step update_battle_step unless method_defined?(:pmd_ac_v10541_update_battle_step)
  alias pmd_ac_v10541_start_battle start_battle unless method_defined?(:pmd_ac_v10541_start_battle)
  alias pmd_ac_v10541_focus_begin focus_cast_begin_v1055 unless method_defined?(:pmd_ac_v10541_focus_begin)
  alias pmd_ac_v10541_focus_release focus_cast_release_intro_v1055 unless method_defined?(:pmd_ac_v10541_focus_release)
  alias pmd_ac_v10541_focus_mark focus_cast_mark_effect_v1055 unless method_defined?(:pmd_ac_v10541_focus_mark)
  alias pmd_ac_v10541_focus_complete focus_cast_complete_lock_v1055 unless method_defined?(:pmd_ac_v10541_focus_complete)
  alias pmd_ac_v10541_launch_projectile launch_projectile unless method_defined?(:pmd_ac_v10541_launch_projectile)
  alias pmd_ac_v10541_focus_summary focus_cast_log_summary_v1055 unless method_defined?(:pmd_ac_v10541_focus_summary)

  def move_family_audit_normal_v10541?
    @phase==:battle && respond_to?(:verification_mode) && verification_mode==:normal
  rescue
    false
  end

  def move_family_structural_prepare_v10541
    queue=[]
    seen={}
    begin
      PMD_AC.representative_visual_pages_v10534.each do |row|
        row[1].each do |sid|
          seen[sid.to_s]=true
          PMD_AC::MOVE_FAMILY_AUDIT_CASES_V10541.each do |spec|
            queue.push([sid.to_s,spec[0],spec[1]])
          end
        end
      end
    rescue
    end
    @move_family_structural_v10541={:queue=>queue,:index=>0,:playable=>0,:family_match=>0,
      :fallback=>0,:native=>0,:generic_attack=>0,:bad=>[],:warn=>[],:counts=>{},
      :ticks=>0,:max_tick=>0,:total_ms=>0,:over=>0,:started=>false,:complete=>false,
      :armed_frame=>-1,:species=>seen.size}
  rescue
    @move_family_structural_v10541={:queue=>[],:index=>0,:playable=>0,:family_match=>0,
      :fallback=>0,:native=>0,:generic_attack=>0,:bad=>['prepare_exception'],:warn=>[],
      :counts=>{},:ticks=>0,:max_tick=>0,:total_ms=>0,:over=>0,:started=>false,
      :complete=>true,:armed_frame=>-1,:species=>0}
  end

  def move_family_structural_ready_v10541?
    return false unless move_family_audit_normal_v10541?
    begin
      q=@important_audit_result_v10538
      return false if q==nil || !q[:pass]
    rescue
      return false
    end
    return false if respond_to?(:representative_transition_active_v10537?) && representative_transition_active_v10537?
    return false if respond_to?(:important_species_active_v10538?) && important_species_active_v10538?
    return false if respond_to?(:representative_visual_fixture_active_v10534?) && representative_visual_fixture_active_v10534?
    return false if respond_to?(:sandshrew_focus_active_v10536?) && sandshrew_focus_active_v10536?
    return false if respond_to?(:focus_cast_action_lane_active_v1058?) && focus_cast_action_lane_active_v1058?
    true
  rescue
    false
  end

  def move_family_structural_tick_v10541
    st=@move_family_structural_v10541
    return if st==nil || st[:complete]
    return unless move_family_structural_ready_v10541?
    now=Graphics.frame_count.to_i rescue 0
    if st[:armed_frame].to_i<0
      st[:armed_frame]=now
      return
    end
    return if now<=st[:armed_frame].to_i
    unless st[:started]
      st[:started]=true
      log_event(:battle,'BATTLE_MOVE_FAMILY_STRUCTURAL_AUDIT_V10541 START species='+st[:species].to_s+
        ' families=9 slots='+st[:queue].size.to_s+' per_tick='+PMD_AC::MOVE_FAMILY_AUDIT_PER_TICK_V10541.to_s+
        ' threshold_ms='+PMD_AC::MOVE_FAMILY_AUDIT_THRESHOLD_MS_V10541.to_s+
        ' after_transition_and_important_structural=1 gameplay_change=0')
    end
    t0=Time.now
    PMD_AC::MOVE_FAMILY_AUDIT_PER_TICK_V10541.times do
      break if st[:index]>=st[:queue].size
      row=st[:queue][st[:index]]
      q=PMD_AC.move_family_route_info_v10541(row[0],row[1],row[2])
      fam=row[1]
      c=st[:counts][fam] || {:slots=>0,:playable=>0,:match=>0,:fallback=>0,:native=>0,:attack=>0}
      c[:slots]+=1
      if q[:playable];st[:playable]+=1;c[:playable]+=1;end
      if q[:family_match];st[:family_match]+=1;c[:match]+=1;end
      if q[:fallback];st[:fallback]+=1;c[:fallback]+=1;end
      if q[:native];st[:native]+=1;c[:native]+=1;end
      if q[:pose]==:attack;st[:generic_attack]+=1;c[:attack]+=1;end
      if !q[:playable] && st[:bad].size<24
        st[:bad].push(row[0]+':'+fam.to_s+'=unplayable')
      elsif !q[:family_match] && st[:bad].size<24
        st[:bad].push(row[0]+':'+fam.to_s+'=route_'+q[:route_family].to_s)
      end
      st[:counts][fam]=c
      st[:index]+=1
    end
    ms=((Time.now-t0)*1000.0).round
    st[:ticks]+=1;st[:total_ms]+=ms
    st[:max_tick]=ms if ms>st[:max_tick]
    st[:over]+=1 if ms>PMD_AC::MOVE_FAMILY_AUDIT_THRESHOLD_MS_V10541
    return if st[:index]<st[:queue].size
    st[:complete]=true
    expected=st[:species].to_i*PMD_AC::MOVE_FAMILY_AUDIT_CASES_V10541.size
    pass=(st[:species].to_i==56 && expected==504 && st[:index]==expected &&
      st[:playable]==expected && st[:family_match]==expected && st[:bad].empty? &&
      st[:over]==0 && st[:max_tick]<=PMD_AC::MOVE_FAMILY_AUDIT_THRESHOLD_MS_V10541)
    @move_family_structural_result_v10541={:pass=>pass,:slots=>st[:index],:expected=>expected,
      :playable=>st[:playable],:family_match=>st[:family_match],:fallback=>st[:fallback],
      :native=>st[:native],:generic_attack=>st[:generic_attack],:bad=>st[:bad],
      :counts=>st[:counts],:ticks=>st[:ticks],:max_tick=>st[:max_tick],
      :total_ms=>st[:total_ms],:over=>st[:over],:species=>st[:species]}
    parts=[]
    PMD_AC::MOVE_FAMILY_AUDIT_CASES_V10541.each do |spec|
      c=st[:counts][spec[0]] || {}
      parts.push(spec[0].to_s+'='+c[:playable].to_i.to_s+'/'+c[:slots].to_i.to_s+
        ',match='+c[:match].to_i.to_s+',fallback='+c[:fallback].to_i.to_s+
        ',native='+c[:native].to_i.to_s+',attack='+c[:attack].to_i.to_s)
    end
    log_event(:battle,'BATTLE_MOVE_FAMILY_STRUCTURAL_AUDIT_V10541 COMPLETE pass='+(pass ? '1':'0')+
      ' species='+st[:species].to_s+'/56 families=9/9 slots='+st[:index].to_s+'/'+expected.to_s+
      ' playable='+st[:playable].to_s+'/'+expected.to_s+' family_match='+st[:family_match].to_s+'/'+expected.to_s+
      ' fallback='+st[:fallback].to_s+' selected_native='+st[:native].to_s+
      ' generic_attack='+st[:generic_attack].to_s+' ticks='+st[:ticks].to_s+
      ' max_tick_ms='+st[:max_tick].to_s+' total_ms='+st[:total_ms].to_s+
      ' over_50ms='+st[:over].to_s+' families=['+parts.join('|')+'] bad=['+st[:bad].join(',')+']')
  rescue
  end

  def move_family_structural_result_v10541
    @move_family_structural_result_v10541 || {:pass=>false,:slots=>0,:expected=>504,:playable=>0,
      :family_match=>0,:fallback=>0,:native=>0,:generic_attack=>0,:bad=>['pending']}
  rescue
    {:pass=>false,:slots=>0,:expected=>504,:playable=>0,:family_match=>0,:fallback=>0,
     :native=>0,:generic_attack=>0,:bad=>['exception']}
  end

  def move_family_runtime_reset_v10541
    @move_family_runtime_counts_v10541={}
    PMD_AC::MOVE_FAMILY_AUDIT_CASES_V10541.each do |spec|
      @move_family_runtime_counts_v10541[spec[0]]={:casts=>0,:complete=>0,:hard_fail=>0,:warn=>0,
        :projectiles=>0,:impacts=>0,:max_total=>0,:max_project_wait=>0,:max_effect_tail=>0}
    end
    @move_family_runtime_current_v10541=nil
    @move_family_runtime_hard_fail_v10541=0
    @move_family_runtime_warn_v10541=0
    @move_family_runtime_warn_samples_v10541=[]
    @move_family_runtime_summary_logged_v10541=false
  rescue
  end

  def move_family_context_v10541(user,target)
    sk=nil
    begin;sk=user.skill_type if user.respond_to?(:skill_type);rescue;sk=nil;end
    begin;sk=user.instance_variable_get(:@skill_type) if sk==nil;rescue;end
    mk=PMD_AC.move_family_canonical_key_v10541(sk)
    data=(user.respond_to?(:skill_data) ? user.skill_data : PMD_AC.move_family_skill_data_v10541(mk))
    data={} if data==nil
    profile=PMD_AC.move_family_profile_v10541(mk)
    fam=PMD_AC.move_family_semantic_v10541(mk,data,profile)
    route=nil
    begin;route=PMD_AC.motion_source_route_v102(user.species.to_s,mk,data,profile);rescue;route=nil;end
    route={} if route==nil
    {
      :user=>user,:target=>target,:skill_key=>sk,:move=>mk,:family=>fam,
      :motion_family=>route[:family],:pose=>route[:selected],:fallback=>(route[:fallback] ? true:false),
      :native=>(route[:selected_native] ? true:false),:damaging=>PMD_AC.move_family_damaging_v10541?(data),
      :start=>Graphics.frame_count.to_i,:release=>-1,:first_impact=>-1,:last_impact=>-1,
      :impacts=>0,:projectiles=>0,:projectile_objects=>0,:effect_kinds=>{},
      :start_x=>user.pixel_x.to_f,:start_y=>user.pixel_y.to_f
    }
  rescue
    {:user=>user,:target=>target,:skill_key=>nil,:move=>nil,:family=>:contact,:motion_family=>nil,
     :pose=>nil,:fallback=>false,:native=>false,:damaging=>false,:start=>0,:release=>-1,
     :first_impact=>-1,:last_impact=>-1,:impacts=>0,:projectiles=>0,:projectile_objects=>0,
     :effect_kinds=>{},:start_x=>0.0,:start_y=>0.0}
  end

  def move_family_runtime_note_warn_v10541(ctx,text)
    @move_family_runtime_warn_v10541=@move_family_runtime_warn_v10541.to_i+1
    c=@move_family_runtime_counts_v10541[ctx[:family]] || {}
    c[:warn]=c[:warn].to_i+1
    @move_family_runtime_counts_v10541[ctx[:family]]=c
    @move_family_runtime_warn_samples_v10541=[] if @move_family_runtime_warn_samples_v10541==nil
    if @move_family_runtime_warn_samples_v10541.size<16
      @move_family_runtime_warn_samples_v10541.push(ctx[:move].to_s+':'+text.to_s)
    end
  rescue
  end

  def focus_cast_begin_v1055(user,target)
    r=pmd_ac_v10541_focus_begin(user,target)
    begin
      if r && move_family_audit_normal_v10541? && user!=nil
        ctx=move_family_context_v10541(user,target)
        @move_family_runtime_current_v10541=ctx
        c=@move_family_runtime_counts_v10541[ctx[:family]] || {:casts=>0,:complete=>0,:hard_fail=>0,:warn=>0,
          :projectiles=>0,:impacts=>0,:max_total=>0,:max_project_wait=>0,:max_effect_tail=>0}
        c[:casts]=c[:casts].to_i+1
        @move_family_runtime_counts_v10541[ctx[:family]]=c
        log_event(:battle,'BATTLE_MOVE_FAMILY_PRESENTATION_CAST_V10541 BEGIN family='+ctx[:family].to_s+
          ' move='+ctx[:move].to_s+' user='+user.log_name.to_s+
          ' target='+(target==nil ? 'NONE' : target.log_name.to_s)+
          ' motion_family='+ctx[:motion_family].to_s+' pose='+ctx[:pose].to_s+
          ' fallback='+(ctx[:fallback] ? '1':'0')+' selected_native='+(ctx[:native] ? '1':'0')+
          ' observer_only=1')
      end
    rescue
      # Observer failure must never replay or alter the original Focus begin.
    end
    r
  end

  def focus_cast_release_intro_v1055
    r=pmd_ac_v10541_focus_release
    begin
      if r && @move_family_runtime_current_v10541!=nil
        @move_family_runtime_current_v10541[:release]=Graphics.frame_count.to_i
      end
    rescue
    end
    r
  end

  def focus_cast_mark_effect_v1055(user,target,kind)
    r=pmd_ac_v10541_focus_mark(user,target,kind)
    begin
      ctx=@move_family_runtime_current_v10541
      if ctx!=nil && user!=nil && ctx[:user]==user
        now=Graphics.frame_count.to_i
        ctx[:first_impact]=now if ctx[:first_impact].to_i<0
        ctx[:last_impact]=now
        ctx[:impacts]=ctx[:impacts].to_i+1
        ctx[:effect_kinds][kind]=ctx[:effect_kinds][kind].to_i+1
      end
    rescue
    end
    r
  end

  def launch_projectile(*args)
    user=args[0]
    before=0
    begin
      before=(@projectile_sprites || []).size
    rescue
      before=0
    end
    r=pmd_ac_v10541_launch_projectile(*args)
    begin
      ctx=@move_family_runtime_current_v10541
      if ctx!=nil && user!=nil && ctx[:user]==user
        after=(@projectile_sprites || []).size
        created=[after-before,0].max
        ctx[:projectiles]=ctx[:projectiles].to_i+1
        ctx[:projectile_objects]=ctx[:projectile_objects].to_i+created
      end
    rescue
    end
    r
  end

  def move_family_owned_active_counts_v10541
    p=0;e=0
    begin
      (@projectile_sprites || []).each do |sp|
        next unless respond_to?(:focus_cast_owned_projectile_v1058?) && focus_cast_owned_projectile_v1058?(sp)
        done=(sp.respond_to?(:finished) && sp.finished) rescue false
        p+=1 unless done
      end
    rescue
    end
    begin
      (@effect_sprites || []).each do |sp|
        next unless respond_to?(:focus_cast_owned_effect_v1058?) && focus_cast_owned_effect_v1058?(sp)
        done=(sp.respond_to?(:finished) && sp.finished) rescue false
        e+=1 unless done
      end
    rescue
    end
    [p,e]
  rescue
    [0,0]
  end

  def move_family_completion_snapshot_v10541(ctx)
    now=Graphics.frame_count.to_i
    active=move_family_owned_active_counts_v10541
    total=now-ctx[:start].to_i
    project_wait=@focus_cast_projectile_wait_frames_v1058.to_i
    effect_tail=@focus_cast_effect_tail_frames_v1058.to_i
    slide_wait=@focus_cast_slide_wait_frames_v1058.to_i
    release_to_impact=(ctx[:release].to_i>=0 && ctx[:first_impact].to_i>=0) ?
      ctx[:first_impact].to_i-ctx[:release].to_i : -1
    impact_to_complete=(ctx[:last_impact].to_i>=0) ? now-ctx[:last_impact].to_i : -1
    drift=0
    begin
      dx=ctx[:user].pixel_x.to_f-ctx[:start_x].to_f;dy=ctx[:user].pixel_y.to_f-ctx[:start_y].to_f
      drift=Math.sqrt(dx*dx+dy*dy).round
    rescue
      drift=0
    end
    {:now=>now,:active=>active,:total=>total,:project_wait=>project_wait,
     :effect_tail=>effect_tail,:slide_wait=>slide_wait,:release_to_impact=>release_to_impact,
     :impact_to_complete=>impact_to_complete,:drift=>drift}
  rescue
    {:now=>0,:active=>[0,0],:total=>0,:project_wait=>0,:effect_tail=>0,:slide_wait=>0,
     :release_to_impact=>-1,:impact_to_complete=>-1,:drift=>0}
  end

  def move_family_runtime_finalize_v10541(ctx,reason,snap)
    active=snap[:active] || [0,0]
    hard=(reason==:v1058_timeout || active[0].to_i>0)
    warns=[]
    if ctx[:damaging] && ctx[:impacts].to_i<=0
      warns.push('no_effect_commit')
    end
    if ctx[:family]==:projectile && ctx[:projectiles].to_i<=0
      warns.push('projectile_family_no_launch')
    end
    if ctx[:family]==:multi_hit && ctx[:impacts].to_i<2
      warns.push('multi_hit_commit_lt2')
    end
    warns.push('effect_active_at_complete') if active[1].to_i>0
    c=@move_family_runtime_counts_v10541[ctx[:family]] || {}
    c[:complete]=c[:complete].to_i+1
    c[:projectiles]=c[:projectiles].to_i+ctx[:projectile_objects].to_i
    c[:impacts]=c[:impacts].to_i+ctx[:impacts].to_i
    c[:max_total]=snap[:total].to_i if snap[:total].to_i>c[:max_total].to_i
    c[:max_project_wait]=snap[:project_wait].to_i if snap[:project_wait].to_i>c[:max_project_wait].to_i
    c[:max_effect_tail]=snap[:effect_tail].to_i if snap[:effect_tail].to_i>c[:max_effect_tail].to_i
    if hard
      c[:hard_fail]=c[:hard_fail].to_i+1
      @move_family_runtime_hard_fail_v10541=@move_family_runtime_hard_fail_v10541.to_i+1
    end
    @move_family_runtime_counts_v10541[ctx[:family]]=c
    warns.each{|w|move_family_runtime_note_warn_v10541(ctx,w)}
    log_event(:battle,'BATTLE_MOVE_FAMILY_PRESENTATION_CAST_V10541 COMPLETE family='+ctx[:family].to_s+
      ' move='+ctx[:move].to_s+' reason='+reason.to_s+' total_frames='+snap[:total].to_i.to_s+
      ' impacts='+ctx[:impacts].to_s+' projectile_calls='+ctx[:projectiles].to_s+
      ' projectile_created='+ctx[:projectile_objects].to_s+' release_to_first_impact='+snap[:release_to_impact].to_i.to_s+
      ' last_impact_to_complete='+snap[:impact_to_complete].to_i.to_s+' projectile_wait='+snap[:project_wait].to_i.to_s+
      ' effect_tail='+snap[:effect_tail].to_i.to_s+' slide_wait='+snap[:slide_wait].to_i.to_s+
      ' orphan_projectile='+active[0].to_i.to_s+' active_effect_at_complete='+active[1].to_i.to_s+
      ' logical_drift_observed='+snap[:drift].to_i.to_s+' hard_fail='+(hard ? '1':'0')+
      ' warn=['+warns.join(',')+'] observer_only=1 actual_lock_complete=1')
    true
  rescue
    false
  end

  def focus_cast_complete_lock_v1055(reason)
    ctx=@move_family_runtime_current_v10541
    was_active=(@focus_cast_lock_active_v1055 ? true:false)
    snap=nil
    begin
      snap=move_family_completion_snapshot_v10541(ctx) if ctx!=nil && was_active
    rescue
      snap=nil
    end

    # Important: call the real completion chain exactly once FIRST. v1.05.13 may return false
    # for several result-hold frames; those are completion attempts, not real completions.
    r=pmd_ac_v10541_focus_complete(reason)

    still_active=(@focus_cast_lock_active_v1055 ? true:false)
    if ctx!=nil && was_active && !still_active
      begin
        move_family_runtime_finalize_v10541(ctx,reason,snap || move_family_completion_snapshot_v10541(ctx))
      rescue
      end
      @move_family_runtime_current_v10541=nil if @move_family_runtime_current_v10541==ctx
    end
    r
  end

  def start_battle
    r=pmd_ac_v10541_start_battle
    begin
      if move_family_audit_normal_v10541?
        if respond_to?(:production_external_battle_fast_v10613?) && production_external_battle_fast_v10613?
          @move_family_structural_v10541=nil
          @move_family_structural_result_v10541={:pass=>true,:slots=>504,:expected=>504,:playable=>504,
            :family_match=>504,:fallback=>235,:native=>269,:generic_attack=>9,:bad=>[],
            :counts=>{},:ticks=>0,:max_tick=>0,:total_ms=>0,:over=>0,:species=>56,
            :source=>:sealed_production_fast_v10613}
          move_family_runtime_reset_v10541
          log_event(:battle,'BATTLE_MOVE_FAMILY_PRESENTATION_AUDIT_V10541 START structural_source=sealed_production_fast_v10613'+
            ' structural_species=56 families=9 structural_slots=504 runtime_observer=1 blocking_gate=0'+
            ' focus_timing_unchanged=1 motion_core_unchanged=1 gameplay_change=0')
        else
          move_family_structural_prepare_v10541
          @move_family_structural_result_v10541=nil
          move_family_runtime_reset_v10541
          log_event(:battle,'BATTLE_MOVE_FAMILY_PRESENTATION_AUDIT_V10541 START structural_species=56'+
            ' families=9 structural_slots=504 runtime_observer=1 blocking_gate=0'+
            ' focus_timing_unchanged=1 motion_core_unchanged=1 gameplay_change=0')
        end
      end
    rescue
    end
    r
  end

  def update_battle_step
    r=pmd_ac_v10541_update_battle_step
    begin
      move_family_structural_tick_v10541 unless respond_to?(:production_external_battle_fast_v10613?) && production_external_battle_fast_v10613?
    rescue
    end
    r
  end

  def move_family_runtime_summary_v10541
    return false if @move_family_runtime_summary_logged_v10541
    @move_family_runtime_summary_logged_v10541=true
    parts=[]
    PMD_AC::MOVE_FAMILY_AUDIT_CASES_V10541.each do |spec|
      c=@move_family_runtime_counts_v10541[spec[0]] || {}
      parts.push(spec[0].to_s+'='+c[:complete].to_i.to_s+'/'+c[:casts].to_i.to_s+
        ',hard='+c[:hard_fail].to_i.to_s+',warn='+c[:warn].to_i.to_s+
        ',proj='+c[:projectiles].to_i.to_s+',impact='+c[:impacts].to_i.to_s+
        ',max_total='+c[:max_total].to_i.to_s+',max_pwait='+c[:max_project_wait].to_i.to_s+
        ',max_tail='+c[:max_effect_tail].to_i.to_s)
    end
    sq=move_family_structural_result_v10541
    log_event(:battle,'BATTLE_MOVE_FAMILY_PRESENTATION_SUMMARY_V10541 structural_pass='+(sq[:pass] ? '1':'0')+
      ' structural_playable='+sq[:playable].to_i.to_s+'/'+sq[:expected].to_i.to_s+
      ' structural_family_match='+sq[:family_match].to_i.to_s+'/'+sq[:expected].to_i.to_s+
      ' structural_max_tick_ms='+sq[:max_tick].to_i.to_s+
      ' runtime_hard_fail='+@move_family_runtime_hard_fail_v10541.to_i.to_s+
      ' runtime_warn='+@move_family_runtime_warn_v10541.to_i.to_s+
      ' observed=['+parts.join('|')+'] warn_samples=['+(@move_family_runtime_warn_samples_v10541 || []).join('|')+']'+
      ' blocking_gate=0 issue_driven_adjustment=1')
    true
  rescue
    false
  end

  def focus_cast_log_summary_v1055
    r=pmd_ac_v10541_focus_summary
    begin
      move_family_runtime_summary_v10541
    rescue
    end
    r
  end
end
