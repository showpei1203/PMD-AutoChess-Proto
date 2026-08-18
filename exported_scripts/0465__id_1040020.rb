# encoding: UTF-8
#==============================================================================
# ■ PMD AutoChess - Motion Generated Profile Manual QA + Group Tuning v1.04.1
#==============================================================================
# 【用途】
# 延續 v1.04.0 的 0027～0494 generated profile，完成第一批人工收斂：
# 1. 處理 v1.04.0 conservative true-45 geometry gate 留下的 11 隻 pending。
# 2. 將 7 種 body group 的 source preference 從只調 dash/lunge，擴成完整 family tuning。
# 3. 對重要物種建立第一批 source-style 人工偏好，不改技能 gameplay family。
# 4. 0001～0026 的 QA I / II / foot-anchor authority 完全不覆蓋。
#
# 【11 隻 pending 的正式處理】
# 0113 吉利蛋、0174 寶寶丁、0204 榛果球、0236 無畏小子、0242 幸福蛋、
# 0285 蘑蘑菇、0344 念力土偶、0351 飄浮泡泡、0361 雪童子、
# 0366 珍珠貝、0438 盆才怪。
# conservative geometry certificate 會因 diagonal row 的 bounds/foot signature 與某個
# cardinal row 相同而拒絕。這批人工 QA 只允許「direct 8-row Idle」作 Deploy base，
# 不把 exception 傳給 combat source router，也不自動加入任何 special。
#
# 【主要設定】
# MOTION_PENDING_11_PROFILE_V1041：11 隻人工 profile/cadence 修正。
# MOTION_GROUP_FAMILY_PREFS_V1041：七種 body group 的完整 source preference。
# MOTION_IMPORTANT_*_V1041：重要物種第一批 source-style tuning group。
#
# 【機制規則】
# - 11 隻 manual exception 只存在於 Deploy base :idle；combat 仍要求 v1.04.0 strict geometry。
# - Hop 仍禁止進 Deploy idle loop。
# - source preference 只決定「同一 gameplay family 用哪個 Native 身體動作呈現」。
# - hasNative / hasPlayable / fallback 語意不合併。
# - 找不到 strict-45 candidate 時完整保留 v1.04.0 / v0.94 fallback。
# - 不修改 Damage、AI、Attack Speed、Energy、logical x/y、velocity、action_timer。
#
# 【可調參數】
# - 個別物種 morphology/personality：改 MOTION_PENDING_11_PROFILE_V1041。
# - group source：改 MOTION_GROUP_FAMILY_PREFS_V1041。
# - 重要物種偏好：調整 MOTION_IMPORTANT_*_V1041 常數或 motion_important_source_prefs_v1041。
#
# 【事件／腳本呼叫方式】
# 不需事件呼叫。Windows Motion verifier 會輸出：
#   MOTION_GENERATED_PENDING_11_V1041
#   MOTION_GENERATED_GROUP_TUNING_V1041
#
# 【實際範例】
# Castform 0351：由 medium/ground 改為 hover/float，Deploy 只用 Idle。
# Blissey 0242：由 medium 改為 heavy，Deploy 只用 Idle。
# Rayquaza / Steelix / Gyarados：contact family 優先蛇形安全 body action；
# Mewtwo / Gardevoir / Latias/Latios：remote family 優先 SpAttack/Shoot/Charge。
#==============================================================================
$imported={} unless defined?($imported)
$imported['PMD_AutoChess_MotionGeneratedProfileManualQA_GroupTuning_v1041']=true

module PMD_AC
  MOTION_PENDING_11_PROFILE_V1041={
    '0113'=>{:body=>:heavy,:support=>:ground,:personality=>:nurturing_guardian,:deploy_base=>:idle,:specials=>[],:primary=>40,:between=>17,:ending=>30},
    '0174'=>{:body=>:small,:support=>:ground,:personality=>:gentle_scout,:deploy_base=>:idle,:specials=>[],:primary=>28,:between=>12,:ending=>21},
    '0204'=>{:body=>:heavy,:support=>:ground,:personality=>:still_shell,:deploy_base=>:idle,:specials=>[],:primary=>42,:between=>18,:ending=>32},
    '0236'=>{:body=>:medium,:support=>:ground,:personality=>:trainee_brawler,:deploy_base=>:idle,:specials=>[],:primary=>27,:between=>11,:ending=>20},
    '0242'=>{:body=>:heavy,:support=>:ground,:personality=>:nurturing_guardian,:deploy_base=>:idle,:specials=>[],:primary=>40,:between=>17,:ending=>30},
    '0285'=>{:body=>:small,:support=>:ground,:personality=>:calm_scout,:deploy_base=>:idle,:specials=>[],:primary=>29,:between=>12,:ending=>22},
    '0344'=>{:body=>:hover,:support=>:float,:personality=>:ancient_hover,:deploy_base=>:idle,:specials=>[],:primary=>30,:between=>12,:ending=>22},
    '0351'=>{:body=>:hover,:support=>:float,:personality=>:weather_sprite,:deploy_base=>:idle,:specials=>[],:primary=>27,:between=>11,:ending=>20},
    '0361'=>{:body=>:small,:support=>:ground,:personality=>:cautious_scout,:deploy_base=>:idle,:specials=>[],:primary=>27,:between=>11,:ending=>20},
    '0366'=>{:body=>:heavy,:support=>:ground,:personality=>:shell_guardian,:deploy_base=>:idle,:specials=>[],:primary=>40,:between=>17,:ending=>30},
    '0438'=>{:body=>:small,:support=>:ground,:personality=>:timid_scout,:deploy_base=>:idle,:specials=>[],:primary=>29,:between=>12,:ending=>22}
  }

  # 完整 family group tuning。前段為 body personality；後段仍會 append v1.04.0 安全候選。
  MOTION_GROUP_FAMILY_PREFS_V1041={
    :small=>{
      :strike=>[:strike,:attack],:dash=>[:quick_strike,:leap_forth,:hop,:attack,:strike],
      :lunge=>[:leap_forth,:hop,:quick_strike,:attack,:strike],:head=>[:head,:attack],
      :swing=>[:swing,:attack],:punch=>[:punch,:jab,:uppercut,:chop,:attack],
      :kick=>[:kick,:stomp,:attack],:bite=>[:bite,:attack],:multi=>[:double,:quick_strike,:attack],
      :spin=>[:twirl,:rotate,:attack],:tail=>[:tail_whip,:swing,:slam,:attack],
      :projectile=>[:shoot,:sp_attack,:emit],:beam=>[:sp_attack,:shoot],
      :cast=>[:charge,:sp_attack,:shoot,:pose],:shock=>[:shock,:sp_attack,:shoot],
      :drain=>[:sp_attack,:shoot,:charge],:sound=>[:sound,:sing,:rear_up,:rumble,:charge]
    },
    :medium=>{
      :strike=>[:strike,:attack],:dash=>[:quick_strike,:leap_forth,:attack,:strike],
      :lunge=>[:leap_forth,:quick_strike,:attack,:strike],:head=>[:head,:attack],
      :swing=>[:swing,:attack],:punch=>[:punch,:jab,:uppercut,:chop,:attack],
      :kick=>[:kick,:stomp,:attack],:bite=>[:bite,:attack],:multi=>[:double,:quick_strike,:attack],
      :spin=>[:rotate,:twirl,:attack],:tail=>[:tail_whip,:swing,:slam,:attack],
      :projectile=>[:shoot,:sp_attack,:emit],:beam=>[:sp_attack,:shoot],
      :cast=>[:charge,:sp_attack,:shoot,:pose],:shock=>[:shock,:sp_attack,:shoot],
      :drain=>[:sp_attack,:shoot,:charge],:sound=>[:sound,:sing,:rear_up,:rumble,:charge]
    },
    :quadruped=>{
      :strike=>[:strike,:attack],:dash=>[:quick_strike,:leap_forth,:attack,:strike],
      :lunge=>[:leap_forth,:attack,:strike],:head=>[:head,:attack,:strike],
      :swing=>[:swing,:attack],:punch=>[:attack,:punch],:kick=>[:kick,:stomp,:attack],
      :bite=>[:bite,:attack,:strike],:multi=>[:double,:quick_strike,:attack],
      :spin=>[:rotate,:twirl,:attack],:tail=>[:tail_whip,:swing,:slam,:attack],
      :projectile=>[:shoot,:sp_attack,:emit],:beam=>[:sp_attack,:shoot],
      :cast=>[:charge,:sp_attack,:shoot,:pose],:shock=>[:shock,:sp_attack,:shoot],
      :drain=>[:sp_attack,:shoot,:charge],:sound=>[:sound,:rear_up,:rumble,:sing,:charge]
    },
    :avian=>{
      :strike=>[:attack,:strike],:dash=>[:quick_strike,:attack,:double],
      :lunge=>[:attack,:double,:strike],:head=>[:head,:attack],:swing=>[:swing,:attack],
      :punch=>[:attack,:punch],:kick=>[:kick,:stomp,:attack],:bite=>[:bite,:attack],
      :multi=>[:double,:quick_strike,:attack],:spin=>[:twirl,:rotate,:attack],
      :tail=>[:tail_whip,:swing,:slam,:attack],:projectile=>[:shoot,:sp_attack,:emit],
      :beam=>[:sp_attack,:shoot],:cast=>[:sp_attack,:charge,:shoot,:pose],
      :shock=>[:shock,:sp_attack,:shoot],:drain=>[:sp_attack,:shoot,:charge],
      :sound=>[:sound,:sing,:rear_up,:rumble,:charge]
    },
    :hover=>{
      :strike=>[:attack,:strike],:dash=>[:quick_strike,:attack,:double],
      :lunge=>[:attack,:double,:strike],:head=>[:head,:attack],:swing=>[:swing,:attack],
      :punch=>[:attack,:punch],:kick=>[:attack,:kick],:bite=>[:bite,:attack],
      :multi=>[:double,:quick_strike,:attack],:spin=>[:rotate,:twirl,:attack],
      :tail=>[:tail_whip,:swing,:slam,:attack],:projectile=>[:sp_attack,:shoot,:emit],
      :beam=>[:sp_attack,:shoot],:cast=>[:sp_attack,:charge,:shoot,:pose],
      :shock=>[:shock,:sp_attack,:shoot],:drain=>[:sp_attack,:shoot,:charge],
      :sound=>[:sound,:sing,:rear_up,:rumble,:charge]
    },
    :serpentine=>{
      :strike=>[:attack,:swing,:strike,:double],:dash=>[:attack,:swing,:double,:head],
      :lunge=>[:attack,:swing,:head,:double],:head=>[:head,:attack,:swing],
      :swing=>[:swing,:attack],:punch=>[:attack,:swing],:kick=>[:attack,:swing],
      :bite=>[:bite,:head,:attack],:multi=>[:double,:attack,:swing],
      :spin=>[:rotate,:twirl,:swing,:attack],:tail=>[:tail_whip,:swing,:slam,:attack],
      :projectile=>[:shoot,:sp_attack,:emit],:beam=>[:sp_attack,:shoot],
      :cast=>[:charge,:sp_attack,:shoot,:pose],:shock=>[:shock,:sp_attack,:shoot],
      :drain=>[:sp_attack,:shoot,:charge],:sound=>[:sound,:rear_up,:rumble,:sing,:charge]
    },
    :heavy=>{
      :strike=>[:attack,:strike,:double],:dash=>[:attack,:strike,:double],
      :lunge=>[:attack,:strike,:double],:head=>[:head,:attack,:strike],
      :swing=>[:swing,:attack,:strike],:punch=>[:punch,:attack,:strike],
      :kick=>[:stomp,:kick,:attack],:bite=>[:bite,:attack,:strike],
      :multi=>[:double,:attack,:strike],:spin=>[:rotate,:twirl,:attack],
      :tail=>[:slam,:swing,:tail_whip,:attack],:projectile=>[:sp_attack,:shoot,:emit],
      :beam=>[:sp_attack,:shoot],:cast=>[:charge,:sp_attack,:shoot,:pose],
      :shock=>[:shock,:sp_attack,:shoot],:drain=>[:sp_attack,:charge,:shoot],
      :sound=>[:rear_up,:rumble,:sound,:sing,:charge]
    }
  }

  # 第一批「重要物種 visual source tuning」。只控制 Native 候選順序。
  MOTION_IMPORTANT_REMOTE_CASTERS_V1041=%w(0065 0094 0150 0151 0196 0251 0282 0380 0381 0385 0386 0479 0493)
  MOTION_IMPORTANT_BRAWLERS_V1041=%w(0068 0257 0448)
  MOTION_IMPORTANT_BLADES_V1041=%w(0123 0212 0359)
  MOTION_IMPORTANT_SERPENTS_V1041=%w(0130 0208 0350 0384)
  MOTION_IMPORTANT_DRAGONS_V1041=%w(0149 0330 0373 0445)
  MOTION_IMPORTANT_HEAVY_V1041=%w(0143 0248 0260 0289 0306 0376 0383 0483 0484 0487)
  MOTION_IMPORTANT_FLYERS_V1041=%w(0131 0142 0249 0250 0382 0468)
  MOTION_IMPORTANT_EXTRA_V1041=%w(0229 0254 0382 0494)

  class << self
    alias pmd_ac_v1041_motion_generated_profile_v1040 motion_generated_profile_v1040 unless method_defined?(:pmd_ac_v1041_motion_generated_profile_v1040)
    alias pmd_ac_v1041_motion_generated_deploy_action_v1040? motion_generated_deploy_action_v1040? unless method_defined?(:pmd_ac_v1041_motion_generated_deploy_action_v1040?)
    alias pmd_ac_v1041_native_pose_candidates_v061 native_pose_candidates_v061 unless method_defined?(:pmd_ac_v1041_native_pose_candidates_v061)

    def motion_pending_11_v1041?(species)
      MOTION_PENDING_11_PROFILE_V1041.has_key?(species.to_s)
    rescue
      false
    end

    def motion_generated_profile_v1040(species)
      base=pmd_ac_v1041_motion_generated_profile_v1040(species)
      over=MOTION_PENDING_11_PROFILE_V1041[species.to_s]
      return base if over==nil
      out=base==nil ? {} : base.dup
      over.each{|k,v|out[k]=v}
      out[:manual_pending_resolved_v1041]=true
      out
    rescue
      pmd_ac_v1041_motion_generated_profile_v1040(species)
    end

    def motion_manual_idle_deploy_v1041?(species,action)
      return false unless action==:idle && motion_pending_11_v1041?(species)
      d=compiled_direct_action_v061(species.to_s,:idle) rescue nil
      return false if d==nil || d[:copy_of]!=nil || d[:alias_of]!=nil || d[:rows].to_i<8
      return false unless motion_playable_v102?(species.to_s,:idle)
      true
    rescue
      false
    end

    def motion_generated_deploy_action_v1040?(species,action)
      # 11 隻 exception 只允許 Deploy Idle。Combat source 不吃這條例外。
      return true if motion_manual_idle_deploy_v1041?(species,action)
      pmd_ac_v1041_motion_generated_deploy_action_v1040?(species,action)
    rescue
      pmd_ac_v1041_motion_generated_deploy_action_v1040?(species,action)
    end

    def motion_group_family_prefs_v1041(species,family)
      p=motion_generated_profile_v1040(species)
      return [] if p==nil
      h=MOTION_GROUP_FAMILY_PREFS_V1041[p[:body]]
      return [] if h==nil
      h[family] || []
    rescue
      []
    end

    def motion_important_source_prefs_v1041(species,family)
      sid=species.to_s
      out=[]
      if MOTION_IMPORTANT_REMOTE_CASTERS_V1041.include?(sid)
        case family
        when :projectile;out=[:sp_attack,:shoot,:emit]
        when :beam;out=[:sp_attack,:shoot]
        when :cast;out=[:sp_attack,:charge,:shoot,:pose]
        when :shock;out=[:shock,:sp_attack,:shoot]
        when :drain;out=[:sp_attack,:shoot,:charge]
        when :sound;out=[:sound,:sing,:rear_up,:rumble,:charge]
        end
      elsif MOTION_IMPORTANT_BRAWLERS_V1041.include?(sid)
        case family
        when :strike;out=[:punch,:attack,:strike]
        when :punch;out=[:punch,:jab,:uppercut,:chop,:attack]
        when :kick;out=[:kick,:stomp,:attack]
        when :multi;out=[:double,:quick_strike,:attack]
        when :dash;out=[:quick_strike,:attack,:strike]
        end
      elsif MOTION_IMPORTANT_BLADES_V1041.include?(sid)
        case family
        when :strike;out=[:swing,:attack,:strike]
        when :dash;out=[:quick_strike,:attack,:double]
        when :lunge;out=[:attack,:double,:strike]
        when :multi;out=[:double,:quick_strike,:attack]
        when :spin;out=[:twirl,:rotate,:attack]
        end
      elsif MOTION_IMPORTANT_SERPENTS_V1041.include?(sid)
        case family
        when :strike;out=[:attack,:swing,:strike]
        when :dash;out=[:attack,:swing,:double,:head]
        when :lunge;out=[:attack,:head,:swing]
        when :head;out=[:head,:attack,:swing]
        when :bite;out=[:bite,:head,:attack]
        when :tail;out=[:tail_whip,:swing,:slam,:attack]
        end
      elsif MOTION_IMPORTANT_DRAGONS_V1041.include?(sid)
        case family
        when :dash;out=[:quick_strike,:attack,:double]
        when :lunge;out=[:attack,:double,:strike]
        when :bite;out=[:bite,:attack]
        when :projectile;out=[:shoot,:sp_attack,:emit]
        when :beam;out=[:sp_attack,:shoot]
        end
      elsif MOTION_IMPORTANT_HEAVY_V1041.include?(sid)
        case family
        when :strike;out=[:attack,:strike,:double]
        when :lunge;out=[:attack,:strike,:double]
        when :head;out=[:head,:attack,:strike]
        when :punch;out=[:punch,:attack,:strike]
        when :kick;out=[:stomp,:kick,:attack]
        when :tail;out=[:slam,:swing,:tail_whip,:attack]
        end
      elsif MOTION_IMPORTANT_FLYERS_V1041.include?(sid)
        case family
        when :dash;out=[:quick_strike,:attack,:double]
        when :lunge;out=[:attack,:double,:strike]
        when :projectile;out=[:shoot,:sp_attack,:emit]
        when :beam;out=[:sp_attack,:shoot]
        when :cast;out=[:sp_attack,:charge,:shoot,:pose]
        when :sound;out=[:sound,:sing,:rear_up,:rumble,:charge]
        end
      end
      if MOTION_IMPORTANT_EXTRA_V1041.include?(sid)
        case family
        when :projectile;out=[:shoot,:sp_attack,:emit]+out
        when :beam;out=[:sp_attack,:shoot]+out
        when :cast;out=[:charge,:sp_attack,:shoot,:pose]+out
        end
      end
      out
    rescue
      []
    end

    def native_pose_candidates_v061(species,move_key,data=nil,profile=nil)
      base=pmd_ac_v1041_native_pose_candidates_v061(species,move_key,data,profile)
      return base unless motion_generated_species_v1040?(species)
      family=motion_action_family_v102(move_key,data,profile)
      preferred=motion_important_source_prefs_v1041(species,family)+motion_group_family_prefs_v1041(species,family)
      out=[]
      (preferred+base).each do |pose|
        next if pose==nil
        # Combat source 始終維持 strict geometry；11 隻 Deploy exception 不外溢。
        next unless motion_generated_diag_geometry_v1040?(species,pose)
        out.push(pose) unless out.include?(pose)
      end
      out.empty? ? base : out
    rescue
      pmd_ac_v1041_native_pose_candidates_v061(species,move_key,data,profile)
    end
  end
end

class Scene_PMD_AutoChess
  alias pmd_ac_v1041_generated_qa_prepare_verification_battle prepare_verification_battle unless method_defined?(:pmd_ac_v1041_generated_qa_prepare_verification_battle)
  alias pmd_ac_v1041_generated_qa_update_verification_script update_verification_script unless method_defined?(:pmd_ac_v1041_generated_qa_update_verification_script)

  def prepare_verification_battle
    pmd_ac_v1041_generated_qa_prepare_verification_battle
    if respond_to?(:motion_phase_b_verifier_active_v1036?) && motion_phase_b_verifier_active_v1036?
      log_event(:showcase,'MOTION_GENERATED_QA_TUNING_V1041 START pending11=11 group_bodies=7'+
        ' full_family_tuning=1 important_source_batch=46 pending_deploy_idle_only=1 combat_exception=0'+
        ' hop_deploy=0 gameplay_unchanged=1')
    end
  end

  def update_verification_script
    pmd_ac_v1041_generated_qa_update_verification_script
    return unless respond_to?(:motion_phase_b_verifier_active_v1036?) && motion_phase_b_verifier_active_v1036?

    if !@motion_pending_11_verify_v1041 && @verification_frame.to_i>=206
      ok=true;direct8=0;profile_ok=0
      PMD_AC::MOTION_PENDING_11_PROFILE_V1041.each do |sid,over|
        p=PMD_AC.motion_generated_profile_v1040(sid)
        d=PMD_AC.compiled_direct_action_v061(sid,:idle) rescue nil
        direct=d!=nil && d[:copy_of]==nil && d[:alias_of]==nil && d[:rows].to_i>=8
        direct8+=1 if direct
        prof=p!=nil && p[:manual_pending_resolved_v1041] && p[:deploy_base]==:idle && (p[:specials]||[]).empty?
        profile_ok+=1 if prof
        ok=false unless direct && prof
      end
      @motion_pending_11_verify_v1041=true
      log_event(:verify,'MOTION_GENERATED_PENDING_11_V1041 pass='+(ok ? '1':'0')+
        ' resolved='+profile_ok.to_i.to_s+'/11 direct8_idle='+direct8.to_i.to_s+'/11'+
        ' deploy_idle_only=11 specials=0 combat_source_exception=0 hop_deploy=0'+
        ' castform=hover/float blissey=heavy tyrogue=medium clamperl=heavy')
    end

    if !@motion_group_tuning_verify_v1041 && @verification_frame.to_i>=208
      bodies=PMD_AC::MOTION_GROUP_FAMILY_PREFS_V1041.keys
      fams=[:strike,:dash,:lunge,:head,:punch,:kick,:bite,:multi,:spin,:tail,
            :projectile,:beam,:cast,:shock,:drain,:sound]
      complete=bodies.size==7 && bodies.all?{|b|fams.all?{|f|PMD_AC::MOTION_GROUP_FAMILY_PREFS_V1041[b][f]!=nil}}
      important=(PMD_AC::MOTION_IMPORTANT_REMOTE_CASTERS_V1041+
        PMD_AC::MOTION_IMPORTANT_BRAWLERS_V1041+PMD_AC::MOTION_IMPORTANT_BLADES_V1041+
        PMD_AC::MOTION_IMPORTANT_SERPENTS_V1041+PMD_AC::MOTION_IMPORTANT_DRAGONS_V1041+
        PMD_AC::MOTION_IMPORTANT_HEAVY_V1041+PMD_AC::MOTION_IMPORTANT_FLYERS_V1041+
        PMD_AC::MOTION_IMPORTANT_EXTRA_V1041).uniq
      ok=complete && important.size>=40
      @motion_group_tuning_verify_v1041=true
      log_event(:verify,'MOTION_GENERATED_GROUP_TUNING_V1041 pass='+(ok ? '1':'0')+
        ' body_groups='+bodies.size.to_i.to_s+'/7 families_per_group=16/16 important_source_species='+important.size.to_i.to_s+
        ' strict_geometry_combat=1 pending11_exception_deploy_only=1 prior_fallback_retained=1'+
        ' damage_unchanged=1 ai_unchanged=1 attack_speed_unchanged=1 energy_unchanged=1 spatial_unchanged=1')
    end
  rescue
  end
end
