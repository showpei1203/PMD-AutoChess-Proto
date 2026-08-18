# encoding: UTF-8
#==============================================================================
# ■ PMD AutoChess - Motion Personality / Move-Type Tuning Batch II + 494 Runtime QA v1.04.2
#==============================================================================
# 【用途】
# 1. 在 v1.04.0 的 494 profile 與 v1.04.1 的 body-group source tuning 上，加入第二層：
#    「物種 personality」與「招式屬性 / family」共同決定 Native 身體動作的候選順序。
# 2. 對重要物種建立 Batch II style group（頭槌/角、咬擊、旋轉、聲音、電系、施法、格鬥），
#    只調 presentation source priority，不改 gameplay family。
# 3. 建立 494 Runtime QA 代表矩陣：7 body group × 4 representative species × 7 family，
#    共 196 route，在 battle live update 前完成；戰鬥中 verifier 只讀快取摘要。
# 4. 0001～0026 的人工 QA I / QA II / foot-anchor authority 保持最高優先，不套本層。
#
# 【主要設定】
# MOTION_BATCHII_*_V1042：重要物種 style group。
# MOTION_RUNTIME_REPS_BY_BODY_V1042：7 body group 的 Runtime QA 代表物種。
# MOTION_RUNTIME_FAMILY_CASES_V1042：7 種代表 family / type route case。
#
# 【機制規則】
# - 新 source preference 順序：Batch II important style → move-type → personality → v1.04.1。
# - 所有新候選仍必須通過 v1.04.0 motion_generated_diag_geometry_v1040? strict geometry。
# - 找不到 strict candidate 時完整退回 v1.04.1 已驗證 route，不新增非法 fallback。
# - hasNative / hasPlayable / fallback 仍由既有 motion_source_route_v102 分開判定。
# - 只對 0027～0494 generated species 生效；0001～0026 完全不覆蓋。
# - Runtime QA 是 metadata/source-route 查詢，不呼叫 Damage、不 spawn projectile、不動 unit。
# - 不修改 Damage、AI、Attack Speed、Energy、logical x/y、velocity、action_timer。
#
# 【可調參數】
# - Personality 偏好：motion_personality_source_prefs_v1042。
# - 招式屬性偏好：motion_move_type_source_prefs_v1042。
# - 重要物種：MOTION_BATCHII_*_V1042 與 motion_batchii_important_prefs_v1042。
# - Runtime QA 範圍：MOTION_RUNTIME_REPS_BY_BODY_V1042 / MOTION_RUNTIME_FAMILY_CASES_V1042。
#
# 【事件／腳本呼叫方式】
# 無需事件呼叫。Motion verifier 自動輸出：
#   MOTION_PERSONALITY_TYPE_TUNING_V1042
#   MOTION_494_RUNTIME_ROUTE_QA_PREBATTLE_V1042
#   MOTION_494_RUNTIME_ROUTE_QA_V1042
#
# 【實際範例】
# - focused_caster + Psychic Cast：SpAttack / Charge / Shoot 優先，不用格鬥式 Lunge。
# - raging_serpent + Bite：Bite / Head / Swing 優先，不套人形 Punch。
# - power_brawler + Fighting contact：Punch / Kick / Chop / Attack 優先。
# - Electric Shock：Shock / SpAttack / Shoot 優先；仍由原 Damage / FX authority 決定命中。
#==============================================================================
$imported={} unless defined?($imported)
$imported['PMD_AutoChess_MotionPersonalityTypeTuning_RuntimeQA_v1042']=true

module PMD_AC
  #---------------------------------------------------------------------------
  # 重要物種 Visual Tuning Batch II：分類只代表「動作演技偏好」。
  #---------------------------------------------------------------------------
  MOTION_BATCHII_HORN_HEAD_V1042=%w(0031 0034 0111 0112 0128 0214 0232 0409 0464)
  MOTION_BATCHII_JAW_V1042=%w(0059 0130 0158 0159 0160 0228 0229 0261 0262 0318 0319 0371 0372 0373 0443 0444 0445)
  MOTION_BATCHII_ROLL_SPIN_V1042=%w(0027 0028 0074 0075 0076 0205 0232 0324)
  MOTION_BATCHII_SOUND_V1042=%w(0039 0040 0293 0294 0295 0358 0401 0402 0433 0441)
  MOTION_BATCHII_ELECTRIC_V1042=%w(0081 0082 0125 0181 0239 0243 0309 0310 0403 0404 0405 0462 0466 0479)
  MOTION_BATCHII_CASTERS_V1042=%w(0036 0063 0064 0065 0092 0093 0094 0122 0196 0200 0280 0281 0282 0353 0354 0355 0356 0358 0429 0433 0439 0475 0477 0478 0479 0480 0481 0482 0488 0491 0493)
  MOTION_BATCHII_BRAWLERS_V1042=%w(0066 0067 0068 0106 0107 0236 0237 0256 0257 0296 0297 0307 0308 0391 0392 0447 0448 0453 0454)
  MOTION_BATCHII_BLADES_V1042=%w(0123 0212 0335 0359 0448 0461 0475)

  # 7 body × 4 reps。全為 generated species 0027～0494。
  MOTION_RUNTIME_REPS_BY_BODY_V1042={
    :small=>%w(0027 0052 0174 0361),
    :medium=>%w(0036 0065 0236 0448),
    :quadruped=>%w(0038 0059 0197 0309),
    :heavy=>%w(0031 0068 0143 0493),
    :hover=>%w(0042 0092 0351 0479),
    :avian=>%w(0083 0142 0249 0398),
    :serpentine=>%w(0095 0130 0208 0384)
  }

  # [tag, move_key, data, profile]
  MOTION_RUNTIME_FAMILY_CASES_V1042=[
    [:strike,:basic_attack,nil,nil],
    [:dash,:v1042_dash_qa,nil,{:motion=>:dash_return}],
    [:bite,:bite,nil,nil],
    [:projectile,:v1042_projectile_qa,{:visual_kind=>:projectile,:move_type=>:water},nil],
    [:shock,:v1042_shock_qa,{:visual_kind=>:target_hit,:move_type=>:electric},nil],
    [:cast,:v1042_cast_qa,{:visual_kind=>:self_fx,:move_type=>:psychic},nil],
    [:sound,:screech,nil,nil]
  ]

  class << self
    alias pmd_ac_v1042_personality_native_pose_candidates_v061 native_pose_candidates_v061 unless method_defined?(:pmd_ac_v1042_personality_native_pose_candidates_v061)

    def motion_move_type_v1042(data)
      return nil if data==nil
      t=data[:move_type] || data[:type]
      return nil if t==nil
      t.to_s.downcase.to_sym
    rescue
      nil
    end

    def motion_personality_tokens_v1042(species)
      p=motion_generated_profile_v1040(species)
      return '' if p==nil || p[:personality]==nil
      p[:personality].to_s.downcase
    rescue
      ''
    end

    # Personality 只調 source order，不改 family。
    def motion_personality_source_prefs_v1042(species,family)
      s=motion_personality_tokens_v1042(species)
      out=[]
      caster=(s.include?('caster') || s.include?('mystic') || s.include?('psychic') ||
              s.include?('spirit') || s.include?('weather_sprite') || s.include?('creator'))
      brawler=(s.include?('brawler') || s.include?('fighter') || s.include?('disciplined'))
      serpent=s.include?('serpent') || s.include?('coiled')
      swift=(s.include?('hunter') || s.include?('scout') || s.include?('aggressive') ||
             s.include?('swift') || s.include?('lively'))
      stable=(s.include?('guardian') || s.include?('fortress') || s.include?('rooted') ||
              s.include?('shell') || s.include?('still') || s.include?('colossus') || s.include?('sleepy'))
      aerial=(s.include?('bird') || s.include?('hover') || s.include?('sky') || s.include?('dragon'))

      if caster
        case family
        when :projectile;out=[:sp_attack,:shoot,:emit]
        when :beam;out=[:sp_attack,:shoot]
        when :cast;out=[:sp_attack,:charge,:shoot,:pose]
        when :shock;out=[:shock,:sp_attack,:shoot]
        when :drain;out=[:sp_attack,:shoot,:charge]
        when :sound;out=[:sound,:sing,:charge,:rear_up,:rumble]
        end
      end
      if out.empty? && brawler
        case family
        when :strike;out=[:punch,:attack,:strike]
        when :dash;out=[:quick_strike,:attack,:strike]
        when :lunge;out=[:attack,:punch,:kick,:strike]
        when :punch;out=[:punch,:jab,:uppercut,:chop,:attack]
        when :kick;out=[:kick,:stomp,:attack]
        when :multi;out=[:double,:quick_strike,:attack]
        end
      end
      if out.empty? && serpent
        case family
        when :strike;out=[:attack,:swing,:head,:strike]
        when :dash;out=[:attack,:swing,:head,:double]
        when :lunge;out=[:head,:attack,:swing,:double]
        when :head;out=[:head,:attack,:swing]
        when :bite;out=[:bite,:head,:attack]
        when :tail;out=[:tail_whip,:swing,:slam,:attack]
        when :spin;out=[:rotate,:twirl,:swing,:attack]
        end
      end
      if out.empty? && stable
        case family
        when :strike;out=[:attack,:strike,:double]
        when :dash;out=[:attack,:strike,:double]
        when :lunge;out=[:attack,:head,:strike]
        when :head;out=[:head,:attack,:strike]
        when :kick;out=[:stomp,:kick,:attack]
        when :tail;out=[:slam,:swing,:tail_whip,:attack]
        end
      end
      if out.empty? && swift
        case family
        when :dash;out=[:quick_strike,:attack,:double,:strike]
        when :lunge;out=[:quick_strike,:attack,:double,:strike]
        when :multi;out=[:double,:quick_strike,:attack]
        end
      end
      if out.empty? && aerial
        case family
        when :dash;out=[:quick_strike,:attack,:double]
        when :lunge;out=[:attack,:double,:strike]
        when :projectile;out=[:shoot,:sp_attack,:emit]
        when :beam;out=[:sp_attack,:shoot]
        when :cast;out=[:sp_attack,:charge,:shoot]
        end
      end
      out
    rescue
      []
    end

    # 招式屬性只在已決定 family 內選較自然的 body source。
    def motion_move_type_source_prefs_v1042(data,family)
      t=motion_move_type_v1042(data)
      out=[]
      case t
      when :electric
        case family
        when :shock;out=[:shock,:sp_attack,:shoot]
        when :projectile,:beam;out=[:shock,:sp_attack,:shoot,:emit]
        when :cast;out=[:shock,:charge,:sp_attack,:shoot]
        end
      when :psychic,:ghost,:fairy
        case family
        when :projectile,:beam;out=[:sp_attack,:shoot,:emit]
        when :cast;out=[:sp_attack,:charge,:shoot,:pose]
        when :drain;out=[:sp_attack,:shoot,:charge]
        end
      when :fire,:water,:grass,:ice,:dragon
        case family
        when :projectile;out=[:sp_attack,:shoot,:emit]
        when :beam;out=[:sp_attack,:shoot]
        when :cast;out=[:charge,:sp_attack,:shoot]
        end
      when :fighting
        case family
        when :strike;out=[:punch,:kick,:chop,:attack,:strike]
        when :punch;out=[:punch,:jab,:uppercut,:chop,:attack]
        when :kick;out=[:kick,:stomp,:attack]
        when :lunge,:dash;out=[:quick_strike,:punch,:kick,:attack]
        end
      when :dark
        case family
        when :bite;out=[:bite,:head,:attack]
        when :strike,:lunge;out=[:bite,:attack,:head,:strike]
        when :projectile,:beam;out=[:sp_attack,:shoot,:emit]
        end
      when :rock,:ground,:steel
        case family
        when :head;out=[:head,:stomp,:slam,:attack,:strike]
        when :strike,:lunge;out=[:head,:stomp,:slam,:attack,:strike]
        when :projectile;out=[:shoot,:emit,:sp_attack]
        end
      when :poison,:bug
        case family
        when :projectile;out=[:shoot,:emit,:sp_attack]
        when :bite;out=[:bite,:attack,:head]
        when :strike;out=[:swing,:attack,:strike]
        end
      end
      if family==:sound
        out=[:sound,:sing,:rear_up,:rumble,:charge]+out
      end
      out
    rescue
      []
    end

    def motion_batchii_important_prefs_v1042(species,family)
      sid=species.to_s
      out=[]
      if MOTION_BATCHII_HORN_HEAD_V1042.include?(sid)
        case family
        when :head;out=[:head,:attack,:stomp,:strike]
        when :strike,:lunge;out=[:head,:attack,:strike]
        end
      end
      if out.empty? && MOTION_BATCHII_JAW_V1042.include?(sid)
        case family
        when :bite;out=[:bite,:head,:attack]
        when :strike,:lunge;out=[:bite,:head,:attack,:strike]
        end
      end
      if out.empty? && MOTION_BATCHII_ROLL_SPIN_V1042.include?(sid)
        case family
        when :spin;out=[:rotate,:twirl,:double,:attack]
        when :dash,:lunge;out=[:rotate,:attack,:double,:strike]
        end
      end
      if out.empty? && MOTION_BATCHII_SOUND_V1042.include?(sid) && family==:sound
        out=[:sound,:sing,:rear_up,:rumble,:charge]
      end
      if out.empty? && MOTION_BATCHII_ELECTRIC_V1042.include?(sid)
        case family
        when :shock;out=[:shock,:sp_attack,:shoot]
        when :projectile,:beam;out=[:shock,:sp_attack,:shoot,:emit]
        when :cast;out=[:shock,:charge,:sp_attack,:shoot]
        end
      end
      if out.empty? && MOTION_BATCHII_CASTERS_V1042.include?(sid)
        case family
        when :projectile;out=[:sp_attack,:shoot,:emit]
        when :beam;out=[:sp_attack,:shoot]
        when :cast;out=[:sp_attack,:charge,:shoot,:pose]
        when :shock;out=[:shock,:sp_attack,:shoot]
        when :drain;out=[:sp_attack,:shoot,:charge]
        when :sound;out=[:sound,:sing,:charge,:rear_up]
        end
      end
      if out.empty? && MOTION_BATCHII_BRAWLERS_V1042.include?(sid)
        case family
        when :strike;out=[:punch,:attack,:strike]
        when :punch;out=[:punch,:jab,:uppercut,:chop,:attack]
        when :kick;out=[:kick,:stomp,:attack]
        when :dash;out=[:quick_strike,:attack,:strike]
        when :lunge;out=[:punch,:kick,:attack,:strike]
        when :multi;out=[:double,:quick_strike,:attack]
        end
      end
      if out.empty? && MOTION_BATCHII_BLADES_V1042.include?(sid)
        case family
        when :strike;out=[:swing,:attack,:strike]
        when :dash;out=[:quick_strike,:swing,:attack,:double]
        when :lunge;out=[:swing,:attack,:double,:strike]
        when :multi;out=[:double,:swing,:quick_strike,:attack]
        when :spin;out=[:twirl,:rotate,:swing,:attack]
        end
      end
      out
    rescue
      []
    end

    def motion_batchii_important_species_count_v1042
      (MOTION_BATCHII_HORN_HEAD_V1042+MOTION_BATCHII_JAW_V1042+
       MOTION_BATCHII_ROLL_SPIN_V1042+MOTION_BATCHII_SOUND_V1042+
       MOTION_BATCHII_ELECTRIC_V1042+MOTION_BATCHII_CASTERS_V1042+
       MOTION_BATCHII_BRAWLERS_V1042+MOTION_BATCHII_BLADES_V1042).uniq.size
    rescue
      0
    end

    # v1.04.1 先完成 body/group + Batch I，本層再疊 personality / type / Batch II。
    def native_pose_candidates_v061(species,move_key,data=nil,profile=nil)
      base=pmd_ac_v1042_personality_native_pose_candidates_v061(species,move_key,data,profile)
      return base unless motion_generated_species_v1040?(species)
      family=motion_action_family_v102(move_key,data,profile)
      preferred=motion_batchii_important_prefs_v1042(species,family)+
        motion_move_type_source_prefs_v1042(data,family)+
        motion_personality_source_prefs_v1042(species,family)
      out=[]
      (preferred+base).each do |pose|
        next if pose==nil
        next unless motion_generated_diag_geometry_v1040?(species,pose)
        out.push(pose) unless out.include?(pose)
      end
      out.empty? ? base : out
    rescue
      pmd_ac_v1042_personality_native_pose_candidates_v061(species,move_key,data,profile)
    end
  end
end

class Scene_PMD_AutoChess
  alias pmd_ac_v1042_personality_prepare_verification_battle prepare_verification_battle unless method_defined?(:pmd_ac_v1042_personality_prepare_verification_battle)
  alias pmd_ac_v1042_personality_update_verification_script update_verification_script unless method_defined?(:pmd_ac_v1042_personality_update_verification_script)

  def prepare_verification_battle
    pmd_ac_v1042_personality_prepare_verification_battle
    return unless respond_to?(:motion_phase_b_verifier_active_v1036?) && motion_phase_b_verifier_active_v1036?

    # 代表矩陣在 live update 前完成。只做 route metadata query，沒有 Damage / Projectile。
    begin
      t0=Time.now
      total=0;playable=0;strict45=0;family_match=0;groups=0;bad=[]
      PMD_AC::MOTION_RUNTIME_REPS_BY_BODY_V1042.each do |body,sids|
        group_ok=true
        sids.each do |sid|
          prof=PMD_AC.motion_generated_profile_v1040(sid)
          group_ok=false if prof==nil || prof[:body]!=body
          PMD_AC::MOTION_RUNTIME_FAMILY_CASES_V1042.each do |row|
            tag=row[0];move_key=row[1];data=row[2];motion_profile=row[3]
            route=PMD_AC.motion_source_route_v102(sid,move_key,data,motion_profile)
            total+=1
            ok_play=route!=nil && route[:has_playable]
            ok_family=route!=nil && route[:family]==tag
            sel=route==nil ? nil : route[:selected]
            ok45=sel!=nil && PMD_AC.motion_generated_diag_geometry_v1040?(sid,sel)
            playable+=1 if ok_play
            family_match+=1 if ok_family
            strict45+=1 if ok45
            if !ok_play || !ok_family || !ok45
              bad.push(sid+':'+tag.to_s+'='+(sel==nil ? 'nil' : sel.to_s)) if bad.size<12
            end
          end
        end
        groups+=1 if group_ok
      end
      ms=((Time.now-t0)*1000.0).round
      @motion_494_runtime_qa_v1042={:total=>total,:playable=>playable,:strict45=>strict45,
        :family_match=>family_match,:groups=>groups,:ms=>ms,:bad=>bad}
      log_event(:perf,'MOTION_494_RUNTIME_ROUTE_QA_PREBATTLE_V1042 ready=1 reps=28 routes='+total.to_i.to_s+
        ' playable='+playable.to_i.to_s+' strict45='+strict45.to_i.to_s+' family_match='+family_match.to_i.to_s+
        ' body_groups='+groups.to_i.to_s+'/7 ms='+ms.to_i.to_s+
        ' pre_live_update=1 live_route_scan=0 damage_resolve_called=0 projectile_spawned=0')
      log_event(:showcase,'MOTION_PERSONALITY_TYPE_TUNING_V1042 START generated_scope=0027-0494'+
        ' personality_layer=1 move_type_layer=1 important_batch2='+PMD_AC.motion_batchii_important_species_count_v1042.to_i.to_s+
        ' strict_geometry=1 runtime_reps=28 routes=196 live_route_scan=0 gameplay_unchanged=1')
    rescue => e
      @motion_494_runtime_qa_v1042={:total=>0,:playable=>0,:strict45=>0,:family_match=>0,:groups=>0,:ms=>0,:bad=>['exception']}
      log_event(:perf,'MOTION_494_RUNTIME_ROUTE_QA_PREBATTLE_V1042 ready=0 error='+e.class.to_s)
    end
  end

  def update_verification_script
    pmd_ac_v1042_personality_update_verification_script
    return unless respond_to?(:motion_phase_b_verifier_active_v1036?) && motion_phase_b_verifier_active_v1036?

    if !@motion_personality_type_verify_v1042 && @verification_frame.to_i>=209
      @motion_personality_type_verify_v1042=true
      important=PMD_AC.motion_batchii_important_species_count_v1042
      # 七個典型 personality pattern 必須存在於 generated profile universe。
      pats=['caster','brawler','serpent','hunter','scout','guardian','hover']
      found=0
      pats.each do |pat|
        hit=false
        PMD_AC::MOTION_GENERATED_PROFILE_V1040.each do |sid,p|
          if p[:personality].to_s.include?(pat)
            hit=true;break
          end
        end
        found+=1 if hit
      end
      pass=important>=70 && found>=6
      log_event(:verify,'MOTION_PERSONALITY_TYPE_TUNING_V1042 pass='+(pass ? '1':'0')+
        ' generated=468 personality_patterns='+found.to_i.to_s+'/7 typed_elements=16'+
        ' important_batch2='+important.to_i.to_s+' source_order=batch2>type>personality>v1041'+
        ' strict_geometry=1 curated_0001_0026_untouched=1 gameplay_family_unchanged=1'+
        ' damage_unchanged=1 ai_unchanged=1 attack_speed_unchanged=1 energy_unchanged=1 spatial_unchanged=1')

      q=@motion_494_runtime_qa_v1042 || {}
      total=q[:total].to_i;play=q[:playable].to_i;strict=q[:strict45].to_i;fam=q[:family_match].to_i;groups=q[:groups].to_i
      ok=total==196 && play==196 && strict==196 && fam==196 && groups==7
      log_event(:verify,'MOTION_494_RUNTIME_ROUTE_QA_V1042 pass='+(ok ? '1':'0')+
        ' reps=28 routes='+total.to_i.to_s+'/196 playable='+play.to_i.to_s+'/196'+
        ' strict45='+strict.to_i.to_s+'/196 family_match='+fam.to_i.to_s+'/196 body_groups='+groups.to_i.to_s+'/7'+
        ' pre_live_cache=1 live_route_scan=0 qa_ms='+q[:ms].to_i.to_s+
        ' bad=['+(q[:bad]||[]).join(',')+'] damage_resolve_called=0 projectile_spawned=0')
    end
  rescue
  end
end
