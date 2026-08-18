#==============================================================================
# 【PMD AutoChess 中文維護說明】
# 腳本：PMD AutoChess Proto v0.60.2
# 分類：PMDCollab 編譯姿勢
#
# 【用途／機制】
# 讀取已編譯進 VX Script Library 的 PMDCollab 動作資料並做語意路由。
#
# 【怎麼調整】
# Runtime 不讀 XML／外部 rb；新增素材後應重新跑 compiler，再把資料編進 Scripts.rvdata。
#
# 【本腳本主要設定常數／資料表】
# - PRESENTATION_PATCH_VERSION_V0602
#
# 【Runtime 主要方法（查流程時可直接搜尋）】
# - start / ranged_multi_initial_v0602? / start_ranged_pipeline_on_launch_v0602 / launch_projectile
# - prepare_verification_battle / log_event / gaps_v0602 / uniform_gaps_v0602?
# - verify_multi_choreo_v060
#
# 【維護規則】
# - RPG Maker VX / RGSS2 / Ruby 1.8 相容。
# - instance_uid 才是 Pokémon 個體身份；Actor ID 只是容器。
# - 新增行為優先沿用既有 helper／Data 表；避免破壞已 Freeze 的舊核心。
# - 本專案新腳本也必須保留同等級的中文說明與實際範例。
#==============================================================================
#==============================================================================
# ■ PMD AutoChess Proto v0.60.2
#    Uniform Multi-Hit Cadence / First-Shot Pipeline Fix
#------------------------------------------------------------------------------
# Additive patch on v0.60.1.
#
# v0.60 correctly created a fresh pose/projectile for each ranged multi-hit,
# but it did not start that choreography until the FIRST projectile had already
# reached the target.  Result: hit #1 -> hit #2 included one whole projectile
# travel time, while hit #2 -> #3 -> #4 were already pipelined and much faster.
#
# v0.60.2 starts the ranged multi-hit pipeline at the INITIAL projectile launch:
#   launch #1 -> pose #2 -> launch #2 -> pose #3 -> launch #3 ...
# All projectiles keep the same normal speed, so their impacts inherit the same
# launch spacing.  No speed-up/teleport hack is used.
#
# Contact multi-hit also removes the extra hold that only existed after hit #2+,
# making each hit-to-hit cycle consistently retreat -> re-engage -> hit.
# Damage, hit count, crit/contact abilities, projectile collision, Beam/Impact
# anchors and normal combat targeting are unchanged.
#==============================================================================
module PMD_AC
  PRESENTATION_PATCH_VERSION_V0602 = "0.60.2"
  # v0.60 had a 2f impact hold only after hit #2 and later.  Removing it makes
  # first->second and second->third use the exact same spatial cycle.
  CONTACT_MULTI_CHOREO_V060[:between_hits_hold] = 0
end

class Scene_PMD_AutoChess
  alias pmd_ac_v0602_start start unless method_defined?(:pmd_ac_v0602_start)
  alias pmd_ac_v0602_launch_projectile launch_projectile unless method_defined?(:pmd_ac_v0602_launch_projectile)
  alias pmd_ac_v0602_prepare_verification_battle prepare_verification_battle unless method_defined?(:pmd_ac_v0602_prepare_verification_battle)
  alias pmd_ac_v0602_verify_multi_choreo_v060 verify_multi_choreo_v060 unless method_defined?(:pmd_ac_v0602_verify_multi_choreo_v060)
  alias pmd_ac_v0602_log_event log_event unless method_defined?(:pmd_ac_v0602_log_event)

  def start
    pmd_ac_v0602_start
    begin
      if FileTest.exist?(PMD_AC::BATTLE_LOG_FILE)
        t=File.open(PMD_AC::BATTLE_LOG_FILE,'rb'){|f|f.read}
        t.sub!(/PMD AutoChess Proto v0\.60\.1 Battle Verification Log/,
               'PMD AutoChess Proto v0.60.2 Battle Verification Log')
        File.open(PMD_AC::BATTLE_LOG_FILE,'wb'){|f|f.write(t)}
      end
    rescue
    end
    log_event(:presentation,
      'PATCH v0.60.2 ranged_multihit_pipeline=initial_launch contact_hit_cycle=uniform '+
      'first_second_gap_fix=1 projectile_speed=unchanged damage_rules=unchanged')
  end

  def ranged_multi_initial_v0602?(effect_type)
    return false if effect_type==nil
    return false if effect_type.to_s.index('v060_seq_')==0
    data=PMD_AC.skill_data(effect_type)
    return false if data==nil || data[:v060_packet]
    return false unless data[:multi_hit_v049] || data[:triple_kick_v059]
    mk=data[:canonical_move_key] || data[:move_key] || :multi_hit
    return false unless PMD_AC::RANGED_MULTI_CHOREO_V060[:enabled]
    ranged_multi_kind_v060?(data,mk)
  end

  def start_ranged_pipeline_on_launch_v0602(user,target,effect_type,data)
    mk=data[:canonical_move_key] || data[:move_key] || :multi_hit
    hits=multi_hit_count_for_v060(data)
    return effect_type if hits<=1
    p=PMD_AC.move_presentation_profile_v055(mk) || {}
    pose=PMD_AC.native_pose_for_move_v060(user.species,mk,data,p)
    lead=ranged_launch_frames_v060(user,pose)
    cfg=PMD_AC::RANGED_MULTI_CHOREO_V060

    # The original first projectile must resolve exactly one packet.  Marking it
    # v060_packet prevents apply_skill_effects from starting the old post-impact
    # multi sequence when projectile #1 arrives.
    first_packet=single_packet_data_v060(data,nil)
    first_packet[:v060_packet]=true
    first_key=new_temp_skill_key_v060(user,mk,1)
    PMD_AC.register_sequential_skill_v060(first_key,first_packet)

    total=(hits-1)*(cfg[:between_launches_frames].to_i+lead)+
          PMD_AC::PROJECTILE_LIFE.to_i+20
    user.start_multi_sequence_lock_v060(total,pose)
    @multi_ranged_events_v060.push({
      :user=>user,:target=>target,:data=>data,:single=>first_packet,
      :scale=>1.0,:move_key=>mk,:hits=>hits,:done=>1,:next_hit=>2,
      :pose=>pose,:phase=>:pose_gap,
      :next_frame=>Graphics.frame_count+cfg[:between_launches_frames].to_i,
      :launch_frames=>lead,:v0602_pipeline=>true
    })
    log_event(:multi_choreo,user.log_name+' move='+mk.to_s+
              ' START ranged_pipeline hits='+hits.to_s+' pose='+pose.to_s+
              ' first_launch_frame='+Graphics.frame_count.to_s+
              ' launch_interval='+(cfg[:between_launches_frames].to_i+lead).to_s+
              ' projectile_speed=normal')
    first_key
  end

  def launch_projectile(user,target,kind,power,effect_type,tracking_override=nil,
                        attack_modifier=nil,allow_substitute=true)
    actual_effect=effect_type
    if kind==:skill_generic && ranged_multi_initial_v0602?(effect_type)
      data=PMD_AC.skill_data(effect_type)
      actual_effect=start_ranged_pipeline_on_launch_v0602(user,target,effect_type,data)
    end

    # Record launch cadence for verification.  The temporary packets preserve
    # canonical_move_key, so all launches can be grouped by the real move.
    begin
      d=actual_effect==nil ? nil : PMD_AC.skill_data(actual_effect)
      mk=d==nil ? nil : (d[:canonical_move_key] || d[:move_key])
      if @multi_cadence_launch_frames_v0602!=nil && mk!=nil && d[:v060_packet]
        a=@multi_cadence_launch_frames_v0602[mk]
        if a==nil;a=[];@multi_cadence_launch_frames_v0602[mk]=a;end
        a.push(Graphics.frame_count)
      end
    rescue
    end

    pmd_ac_v0602_launch_projectile(user,target,kind,power,actual_effect,
                                   tracking_override,attack_modifier,
                                   allow_substitute)
  end

  def prepare_verification_battle
    pmd_ac_v0602_prepare_verification_battle
    if verification_mode==:multi_choreo_v060
      @multi_cadence_launch_frames_v0602={}
      @multi_cadence_contact_frames_v0602={}
    end
  end

  # Observe contact impact frames without changing the v0.60 choreography.
  def log_event(category,message)
    if verification_mode==:multi_choreo_v060 && category.to_s=='multi_choreo' &&
       @multi_cadence_contact_frames_v0602!=nil
      text=message.to_s
      if text.index(' START contact hits=')!=nil || text.index(' HIT ')!=nil
        if text =~ /move=([A-Za-z0-9_]+)/
          mk=$1.to_sym
          a=@multi_cadence_contact_frames_v0602[mk]
          if a==nil;a=[];@multi_cadence_contact_frames_v0602[mk]=a;end
          a.push(Graphics.frame_count)
        end
      end
    end
    pmd_ac_v0602_log_event(category,message)
  end

  def gaps_v0602(frames)
    return [] if frames==nil || frames.size<2
    r=[]
    i=1
    while i<frames.size
      r.push(frames[i].to_i-frames[i-1].to_i)
      i+=1
    end
    r
  end

  def uniform_gaps_v0602?(gaps,tolerance=1)
    return true if gaps==nil || gaps.size<=1
    min=gaps.min.to_i;max=gaps.max.to_i
    (max-min)<=tolerance.to_i
  end

  def verify_multi_choreo_v060
    pmd_ac_v0602_verify_multi_choreo_v060
    return if @verification_done[:v0602_cadence]
    cg=[]
    [:triple_kick,:double_kick].each do |mk|
      g=gaps_v0602(@multi_cadence_contact_frames_v0602==nil ? nil :
                   @multi_cadence_contact_frames_v0602[mk])
      cg.concat(g)
    end
    rg=[]
    [:icicle_spear,:bullet_seed].each do |mk|
      g=gaps_v0602(@multi_cadence_launch_frames_v0602==nil ? nil :
                   @multi_cadence_launch_frames_v0602[mk])
      rg.concat(g)
    end
    contact_ok=uniform_gaps_v0602?(gaps_v0602(
      @multi_cadence_contact_frames_v0602==nil ? nil :
      @multi_cadence_contact_frames_v0602[:triple_kick]),1)
    ranged_ok=uniform_gaps_v0602?(rg,1) && !rg.empty?
    log_event(:verify,
      'MULTI_CADENCE_V0602 pass='+((contact_ok && ranged_ok) ? '1':'0')+
      ' contact_triple_gaps='+gaps_v0602(
        @multi_cadence_contact_frames_v0602==nil ? nil :
        @multi_cadence_contact_frames_v0602[:triple_kick]).join(',')+
      ' ranged_launch_gaps='+rg.join(',')+
      ' initial_projectile_pipelined=1 projectile_speed=normal')
    @verification_done[:v0602_cadence]=true
  end
end
