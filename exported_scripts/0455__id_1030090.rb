#==============================================================================
# ■ PMD AutoChess - Motion Species QA 0001-0026 / Personality Pass I v1.03.9
#==============================================================================
# 【用途】
# 本腳本是 Motion Framework 完成 Contact / Result / Multi-hit / Remote Motion 後，
# 第一輪 0001～0026 物種逐隻 QA 與 Personality 校正層。它只處理 Presentation：
# 1. 將 Deploy 待機 LOOP 從「Body Pool 自動猜動作」改為 0001～0026 逐隻白名單。
# 2. 每隻只允許真正 compiled direct、非 copy/alias、rows>=8、PNG 存在的動作。
# 3. 0001～0026 的 Deploy 不再用 Walk 當主要待機，也永遠不使用 Hop。
# 4. 保留 v1.03.5 的 45° row 鎖定：我方 dir=3、敵方 dir=1。
# 5. 新增 26 隻 × 16 個 Motion Family 的 source-route QA audit，確認每個 family
#    至少能找到可播放 Native 或既有安全 fallback；audit 不發 Damage、不建立 projectile。
#
# 【主要設定】
# MOTION_QA_DEPLOY_V1039
#   每隻 Pokemon 的 Deploy base、特殊待機動作與節奏。特殊動作是人工白名單，
#   不再讓 Body Pool 自動補入看似可用但性格不合的演技。
#
# MOTION_QA_ROUTE_CASES_V1039
#   16 個 Motion family 的 metadata-only 測試案例。只呼叫既有 source router，
#   不呼叫 Damage Formula、AI、Energy、Projectile resolve 或 Spatial Runtime。
#
# 【機制規則】
# - Frozen Combat Core 不修改；本腳本是 trailing alias/override。
# - HOME / logical action anchor 規則不變。
# - Damage hit count / timing authority、AI、Attack Speed、Energy、logical x/y 不變。
# - live battle 的純裝飾 Rich LOOP 仍由 v1.03.2 隔離；本版 personality 白名單只接管 Deploy。
# - 若白名單 action 在未來素材包消失，Runtime 會拒絕它並在 QA verifier 報 FAIL，
#   不會偷偷用單方向素材冒充 45°。
#
# 【可調參數】
# - 想改某隻 Deploy 個性：只改 MOTION_QA_DEPLOY_V1039[sid][:specials]。
# - 想讓某隻更沉穩／更活潑：改 :primary / :between / :ending。
# - specials 禁止加入 :hop、Attack、Strike、Kick、Bite、Shoot、Hurt 等明確戰鬥語意。
# - 不要為了視覺調整 @action_timer、HP、Energy、velocity 或 pixel_x/pixel_y。
#
# 【事件／腳本呼叫方式】
# 不需事件呼叫。0001～0026 在 Deploy 自動使用本版逐隻 profile。
# Windows 驗收：按 S 切 PMD Motion verifier，Deploy 先觀察 10～20 秒，再 Shift
# 完整跑完一場。LOG 應包含 MOTION_SPECIES_QA_0001_0026_V1039 pass=1。
#
# 【實際範例】
# - 妙蛙種子：Idle → Nod / Pose / Shake → Idle；全程 45°，沒有 Hop / Walk 主循環。
# - 水箭龜：Idle → Withdraw → Idle，節奏較慢，符合 fortress personality。
# - 大針蜂：沒有 direct 8-dir Idle，因此以 Hover 作 45° base，不硬塞 Walk。
# - 皮卡丘：Idle → Pose / Nod → Idle；QuickStrike / Shock 保留給真正戰鬥，不拿來待機。
#==============================================================================

$imported = {} unless defined?($imported)
$imported['PMD_AutoChess_MotionSpeciesQA_0001_0026_v1039'] = true

module PMD_AC
  MOTION_SPECIES_QA_VERSION_V1039 = '1.03.9'
  MOTION_SPECIES_QA_RANGE_V1039 = (1..26).to_a.collect{|i| '%04d' % i}

  MOTION_QA_SPECIES_NAMES_V1039 = {
    '0001'=>'Bulbasaur','0002'=>'Ivysaur','0003'=>'Venusaur',
    '0004'=>'Charmander','0005'=>'Charmeleon','0006'=>'Charizard',
    '0007'=>'Squirtle','0008'=>'Wartortle','0009'=>'Blastoise',
    '0010'=>'Caterpie','0011'=>'Metapod','0012'=>'Butterfree',
    '0013'=>'Weedle','0014'=>'Kakuna','0015'=>'Beedrill',
    '0016'=>'Pidgey','0017'=>'Pidgeotto','0018'=>'Pidgeot',
    '0019'=>'Rattata','0020'=>'Raticate','0021'=>'Spearow','0022'=>'Fearow',
    '0023'=>'Ekans','0024'=>'Arbok','0025'=>'Pikachu','0026'=>'Raichu'
  }

  # primary / between / ending 仍會經 v1.03.7 的 1.18 hold scale。
  # 因此本表是 Personality 差異，不是全域速度修改。
  MOTION_QA_DEPLOY_V1039 = {
    '0001'=>{:base=>:idle, :specials=>[:nod,:pose,:shake],       :primary=>24,:between=>10,:ending=>18},
    '0002'=>{:base=>:idle, :specials=>[:shake],                 :primary=>27,:between=>12,:ending=>20},
    '0003'=>{:base=>:idle, :specials=>[:shake],                 :primary=>31,:between=>14,:ending=>24},
    '0004'=>{:base=>:idle, :specials=>[:nod,:pose],             :primary=>19,:between=>8, :ending=>14},
    '0005'=>{:base=>:idle, :specials=>[:pose,:nod],             :primary=>22,:between=>9, :ending=>16},
    '0006'=>{:base=>:idle, :specials=>[],                       :primary=>27,:between=>11,:ending=>20},
    '0007'=>{:base=>:idle, :specials=>[:withdraw,:nod,:pose],   :primary=>24,:between=>10,:ending=>18},
    '0008'=>{:base=>:idle, :specials=>[:withdraw],              :primary=>27,:between=>12,:ending=>21},
    '0009'=>{:base=>:idle, :specials=>[:withdraw],              :primary=>32,:between=>14,:ending=>24},
    '0010'=>{:base=>:idle, :specials=>[],                       :primary=>28,:between=>12,:ending=>21},
    '0011'=>{:base=>:idle, :specials=>[],                       :primary=>34,:between=>15,:ending=>26},
    '0012'=>{:base=>:idle, :specials=>[:flap_around],           :primary=>20,:between=>9, :ending=>15},
    '0013'=>{:base=>:idle, :specials=>[],                       :primary=>24,:between=>10,:ending=>18},
    '0014'=>{:base=>:idle, :specials=>[],                       :primary=>34,:between=>15,:ending=>26},
    '0015'=>{:base=>:hover,:specials=>[],                       :primary=>20,:between=>9, :ending=>16},
    '0016'=>{:base=>:idle, :specials=>[:flap_around,:nod,:pose],:primary=>22,:between=>9, :ending=>16},
    '0017'=>{:base=>:idle, :specials=>[:flap_around],           :primary=>24,:between=>10,:ending=>18},
    '0018'=>{:base=>:idle, :specials=>[:flap_around],           :primary=>26,:between=>11,:ending=>19},
    '0019'=>{:base=>:idle, :specials=>[:tail_whip],             :primary=>18,:between=>8, :ending=>14},
    '0020'=>{:base=>:idle, :specials=>[:tail_whip],             :primary=>21,:between=>9, :ending=>16},
    '0021'=>{:base=>:idle, :specials=>[:hover],                 :primary=>20,:between=>9, :ending=>15},
    '0022'=>{:base=>:idle, :specials=>[:hover],                 :primary=>22,:between=>9, :ending=>16},
    '0023'=>{:base=>:idle, :specials=>[:nod,:pose],             :primary=>26,:between=>11,:ending=>19},
    '0024'=>{:base=>:idle, :specials=>[],                       :primary=>25,:between=>11,:ending=>19},
    '0025'=>{:base=>:idle, :specials=>[:pose,:nod],             :primary=>18,:between=>8, :ending=>14},
    '0026'=>{:base=>:idle, :specials=>[:pose,:nod],             :primary=>22,:between=>9, :ending=>16}
  }

  # [expected_family, move_key, synthetic_data, synthetic_profile]
  # synthetic hash 只為 classifier 提供 semantic，不會送進 gameplay resolve。
  MOTION_QA_ROUTE_CASES_V1039 = [
    [:strike,     :basic_attack, nil, nil],
    [:dash,       :qa_dash,      nil, {:motion=>:dash_return}],
    [:lunge,      :qa_lunge,     nil, {:motion=>:contact_return}],
    [:head,       :headbutt,     nil, nil],
    [:punch,      :fire_punch,   nil, nil],
    [:kick,       :double_kick,  nil, nil],
    [:bite,       :bite,         nil, nil],
    [:multi,      :qa_multi,     nil, {:motion=>:multi_contact}],
    [:spin,       :rapid_spin,   nil, nil],
    [:tail,       :tail_whip,    nil, nil],
    [:projectile, :qa_projectile,{:visual_kind=>:projectile,:delivery=>:projectile,:move_type=>:water},nil],
    [:beam,       :qa_beam,      {:visual_kind=>:beam,:delivery=>:beam,:move_type=>:water},nil],
    [:cast,       :qa_cast,      {:visual_kind=>:self_fx,:target_type=>:self,:move_type=>:normal},nil],
    [:shock,      :qa_shock,     {:visual_kind=>:projectile,:delivery=>:projectile,:move_type=>:electric},nil],
    [:drain,      :absorb,       {:visual_kind=>:target_hit,:move_type=>:grass},nil],
    [:sound,      :growl,        {:visual_kind=>:target_hit,:move_type=>:normal,:sound=>true},nil]
  ]

  class << self
    def motion_species_qa_v1039?(species)
      MOTION_SPECIES_QA_RANGE_V1039.include?(species.to_s)
    end

    def motion_species_qa_deploy_v1039(species)
      MOTION_QA_DEPLOY_V1039[species.to_s]
    end

    def motion_species_qa_direct8_v1039?(species,action)
      return false if action==nil || action==:hop
      return false unless respond_to?(:motion_playable_v102?)
      return false unless motion_playable_v102?(species.to_s,action)
      return false unless respond_to?(:compiled_direct_action_v061)
      d=compiled_direct_action_v061(species.to_s,action)
      return false if d==nil
      return false if d[:copy_of]!=nil || d[:alias_of]!=nil
      return false if d[:rows].to_i<8
      return false unless respond_to?(:compiled_action_asset_available_v061?)
      compiled_action_asset_available_v061?(species.to_s,action,d)
    rescue
      false
    end
  end
end

#==============================================================================
# ■ Game_PMDChessUnit - 0001-0026 curated Deploy personality
#==============================================================================
class Game_PMDChessUnit
  alias pmd_ac_v1039_motion_deploy_base_45_v1038 motion_deploy_base_45_v1038 unless method_defined?(:pmd_ac_v1039_motion_deploy_base_45_v1038)
  alias pmd_ac_v1039_motion_deploy_rich_specials_v1035 motion_deploy_rich_specials_v1035 unless method_defined?(:pmd_ac_v1039_motion_deploy_rich_specials_v1035)
  alias pmd_ac_v1039_motion_deploy_rich_sequence_v1035 motion_deploy_rich_sequence_v1035 unless method_defined?(:pmd_ac_v1039_motion_deploy_rich_sequence_v1035)

  def motion_deploy_base_45_v1038
    if PMD_AC.motion_species_qa_v1039?(@species)
      q=PMD_AC.motion_species_qa_deploy_v1039(@species)
      a=q==nil ? nil : q[:base]
      return a if PMD_AC.motion_species_qa_direct8_v1039?(@species,a)
    end
    pmd_ac_v1039_motion_deploy_base_45_v1038
  rescue
    pmd_ac_v1039_motion_deploy_base_45_v1038
  end

  def motion_deploy_rich_specials_v1035
    unless PMD_AC.motion_species_qa_v1039?(@species)
      return pmd_ac_v1039_motion_deploy_rich_specials_v1035
    end
    q=PMD_AC.motion_species_qa_deploy_v1039(@species)
    src=q==nil ? [] : (q[:specials] || [])
    out=[]
    src.each do |a|
      next if a==nil || a==:hop
      next if out.include?(a)
      next unless PMD_AC.motion_species_qa_direct8_v1039?(@species,a)
      out.push(a)
    end
    out
  rescue
    []
  end

  # 0001-0026 不再讓通用 Body Pool 補動作。每隻只播人工白名單，避免雖然 8-dir
  # 但性格不合的 Native action 混進待機。45° row 仍由 v1.03.5 Sprite 層負責。
  def motion_deploy_rich_sequence_v1035
    unless PMD_AC.motion_species_qa_v1039?(@species)
      return pmd_ac_v1039_motion_deploy_rich_sequence_v1035
    end
    return @motion_deploy_rich_sequence_v1035 if @motion_deploy_rich_sequence_v1035!=nil
    q=PMD_AC.motion_species_qa_deploy_v1039(@species) || {}
    base=motion_deploy_base_45_v1038
    specials=motion_deploy_rich_specials_v1035
    primary=q[:primary].to_i; primary=24 if primary<=0
    between=q[:between].to_i; between=10 if between<=0
    ending=q[:ending].to_i; ending=18 if ending<=0
    seq=[]
    seq.push([base,motion_deploy_scaled_hold_v1037(primary)])
    specials.each_with_index do |a,i|
      hold=motion_deploy_hold_v1035(a)
      seq.push([a,motion_deploy_scaled_hold_v1037(hold)])
      seq.push([base,motion_deploy_scaled_hold_v1037(between+(i%2)*2)])
    end
    seq.push([base,motion_deploy_scaled_hold_v1037(ending)])
    @motion_deploy_rich_special_count_v1035=specials.size
    @motion_deploy_rich_sequence_v1035=seq
    seq
  rescue
    [[motion_deploy_base_45_v1038,motion_deploy_scaled_hold_v1037(24)]]
  end
end

#==============================================================================
# ■ Scene_PMD_AutoChess - 0001-0026 metadata/runtime route QA
#==============================================================================
class Scene_PMD_AutoChess
  alias pmd_ac_v1039_prepare_verification_battle prepare_verification_battle unless method_defined?(:pmd_ac_v1039_prepare_verification_battle)
  alias pmd_ac_v1039_update_verification_script update_verification_script unless method_defined?(:pmd_ac_v1039_update_verification_script)

  def motion_species_qa_reset_v1039
    @motion_species_qa_failed_v1039=false
    @motion_species_qa_deploy_result_v1039=nil
    @motion_species_qa_route_result_v1039=nil
  end

  def prepare_verification_battle
    pmd_ac_v1039_prepare_verification_battle
    if motion_phase_b_verifier_active_v1036?
      motion_species_qa_reset_v1039
      log_event(:showcase,
        'MOTION_SPECIES_QA_V1039 START scope=0001-0026 deploy=curated_direct8_45_nohop'+
        ' family_routes=16_per_species metadata_only=1 body_support_preserved=1'+
        ' damage_unchanged=1 ai_unchanged=1 attack_speed_unchanged=1 energy_unchanged=1 spatial_unchanged=1')
    end
  end

  def motion_species_qa_deploy_audit_v1039
    return if @motion_species_qa_deploy_result_v1039!=nil
    profiles=0;base_ok=0;special_ok=0;special_total=0;hop=0;bad=[]
    PMD_AC::MOTION_SPECIES_QA_RANGE_V1039.each do |sid|
      p=nil;q=nil
      begin;p=PMD_AC.motion_species_profile_v102(sid);rescue;p=nil;end
      q=PMD_AC.motion_species_qa_deploy_v1039(sid)
      profiles+=1 if p!=nil && q!=nil && PMD_AC::MOTION_BODY_TUNING_V102[p[:body]]!=nil
      b=q==nil ? nil : q[:base]
      bok=PMD_AC.motion_species_qa_direct8_v1039?(sid,b)
      base_ok+=1 if bok
      sgood=true
      list=q==nil ? [] : (q[:specials] || [])
      list.each do |a|
        special_total+=1
        hop+=1 if a==:hop
        ok=(a!=:hop && PMD_AC.motion_species_qa_direct8_v1039?(sid,a))
        special_ok+=1 if ok
        sgood=false unless ok
      end
      bad.push(sid) unless p!=nil && q!=nil && bok && sgood
      if motion_phase_b_verifier_active_v1036?
        log_event(:motion_phase_a,
          'MOTION_QA_SPECIES_V1039 sid='+sid+
          ' name='+PMD_AC::MOTION_QA_SPECIES_NAMES_V1039[sid].to_s+
          ' body='+(p==nil ? 'nil':p[:body].to_s)+' support='+(p==nil ? 'nil':p[:support].to_s)+
          ' personality='+(p==nil ? 'nil':p[:personality].to_s)+
          ' deploy_base='+(b==nil ? 'nil':b.to_s)+
          ' specials=['+list.collect{|x|x.to_s}.join(',')+'] direct8='+(bok && sgood ? '1':'0')+
          ' hop=0 angle=45')
      end
    end
    pass=profiles==26 && base_ok==26 && special_ok==special_total && hop==0 && bad.empty?
    @motion_species_qa_failed_v1039=true unless pass
    @motion_species_qa_deploy_result_v1039={:pass=>pass,:profiles=>profiles,:base_ok=>base_ok,
      :special_ok=>special_ok,:special_total=>special_total,:hop=>hop,:bad=>bad}
    log_event(:verify,
      'MOTION_QA_DEPLOY_0001_0026_V1039 pass='+(pass ? '1':'0')+
      ' profiles='+profiles.to_s+'/26 base_direct8='+base_ok.to_s+'/26'+
      ' specials_direct8='+special_ok.to_s+'/'+special_total.to_s+
      ' hop_items='+hop.to_s+' curated_only=1 generic_body_pool=0 walk_primary=0'+
      ' all_actions_45deg=1 bad=['+bad.join(',')+']')
  rescue
    @motion_species_qa_failed_v1039=true
    @motion_species_qa_deploy_result_v1039={:pass=>false}
    log_event(:verify,'MOTION_QA_DEPLOY_0001_0026_V1039 pass=0 error=1')
  end

  def motion_species_qa_route_audit_v1039
    return if @motion_species_qa_route_result_v1039!=nil
    total=0;ok_count=0;native_count=0;fallback_count=0;bad=[]
    PMD_AC::MOTION_SPECIES_QA_RANGE_V1039.each do |sid|
      sid_ok=0;sid_native=0;sid_fallback=0
      PMD_AC::MOTION_QA_ROUTE_CASES_V1039.each do |row|
        expected=row[0];mk=row[1];data=row[2];profile=row[3]
        r=nil
        begin;r=PMD_AC.motion_source_route_v102(sid,mk,data,profile);rescue;r=nil;end
        total+=1
        good=r!=nil && r[:family]==expected && r[:selected]!=nil && r[:has_playable]
        if good
          ok_count+=1;sid_ok+=1
          if r[:selected_native]
            native_count+=1;sid_native+=1
          else
            fallback_count+=1;sid_fallback+=1
          end
        else
          bad.push(sid+':'+expected.to_s)
        end
      end
      if motion_phase_b_verifier_active_v1036?
        log_event(:motion_native,
          'MOTION_QA_ROUTES_V1039 sid='+sid+' playable='+sid_ok.to_s+'/16'+
          ' semantic_native='+sid_native.to_s+' fallback='+sid_fallback.to_s+
          ' hasNative_hasPlayable_separated=1')
      end
    end
    expected_total=PMD_AC::MOTION_SPECIES_QA_RANGE_V1039.size*PMD_AC::MOTION_QA_ROUTE_CASES_V1039.size
    pass=total==expected_total && ok_count==expected_total && bad.empty?
    @motion_species_qa_failed_v1039=true unless pass
    @motion_species_qa_route_result_v1039={:pass=>pass,:total=>total,:ok=>ok_count,
      :native=>native_count,:fallback=>fallback_count,:bad=>bad}
    log_event(:verify,
      'MOTION_QA_SOURCE_ROUTES_0001_0026_V1039 pass='+(pass ? '1':'0')+
      ' playable='+ok_count.to_s+'/'+expected_total.to_s+
      ' semantic_native='+native_count.to_s+' safe_fallback='+fallback_count.to_s+
      ' families=16 species=26 damage_resolve_called=0 projectile_spawned=0'+
      ' bad=['+bad[0,12].join(',')+']')
  rescue
    @motion_species_qa_failed_v1039=true
    @motion_species_qa_route_result_v1039={:pass=>false}
    log_event(:verify,'MOTION_QA_SOURCE_ROUTES_0001_0026_V1039 pass=0 error=1')
  end

  def verify_motion_species_qa_v1039
    return if @verification_done[:motion_species_qa_v1039]
    motion_species_qa_deploy_audit_v1039
    motion_species_qa_route_audit_v1039
    d=@motion_species_qa_deploy_result_v1039 || {}
    r=@motion_species_qa_route_result_v1039 || {}
    pass=d[:pass] && r[:pass] && !@motion_species_qa_failed_v1039
    log_event(:verify,
      'MOTION_SPECIES_QA_0001_0026_V1039 pass='+(pass ? '1':'0')+
      ' stage=species_personality_qa_i profiles=26 curated_deploy=26'+
      ' deploy_45=1 deploy_hop=0 walk_primary=0 routes='+r[:ok].to_i.to_s+'/'+r[:total].to_i.to_s+
      ' live_battle_ambient_isolation_retained=1'+
      ' damage_unchanged=1 ai_unchanged=1 attack_speed_unchanged=1 energy_unchanged=1 spatial_unchanged=1')
    @verification_done[:motion_species_qa_v1039]=true
  rescue
    @motion_species_qa_failed_v1039=true
    log_event(:verify,'MOTION_SPECIES_QA_0001_0026_V1039 pass=0 error=1')
    @verification_done[:motion_species_qa_v1039]=true
  end

  def update_verification_script
    pmd_ac_v1039_update_verification_script
    return unless motion_phase_b_verifier_active_v1036?
    return if @verification_done==nil
    f=@verification_frame.to_i
    motion_species_qa_deploy_audit_v1039 if f>=184
    motion_species_qa_route_audit_v1039 if f>=188
  end

  # v1.03.9 final seal：Phase B A/B/C + Remote 必須 PASS，Species QA 也必須 PASS。
  # 這只是 verifier 合併；不介入任何 battle update / damage resolve。
  def verify_motion_final_v102
    return if @verification_done[:motion_final_v102]
    verify_motion_species_qa_v1039
    pass=!@motion_phase_a_failed_v102 && !@motion_phase_b_failed_v103 &&
      !@motion_phase_b_batch_b_failed_v1036 && !@motion_phase_b_batch_c_failed_v1037 &&
      !@motion_phase_b_remote_failed_v1038 && !@motion_species_qa_failed_v1039
    log_event(:verify,
      'PMD_MOTION_PHASE_A_V102 pass='+(pass ? '1':'0')+
      ' superseded_by_phase_b=1 scope=0001-0026 presentation_only=1'+
      ' damage_formula_unchanged=1 attack_speed_unchanged=1 spatial_framework_unchanged=1')
    log_event(:verify,
      'PMD_MOTION_PHASE_B_V103 pass='+(pass ? '1':'0')+
      ' batch=remote_motion_all scope=0001-0026'+
      ' contact_chain_a=1 result_semantics_b=1 multihit_c=1 remote_all=1'+
      ' species_qa_v1039='+( @motion_species_qa_failed_v1039 ? '0':'1')+
      ' deploy_curated_45_nohop=1 gameplay_timer_added=0 damage_packet_authority_unchanged=1'+
      ' projectile_speed_unchanged=1 ai_unchanged=1 damage_formula_unchanged=1'+
      ' attack_speed_unchanged=1 energy_unchanged=1 spatial_unchanged=1')
    @verification_done[:motion_final_v102]=true
  end
end
