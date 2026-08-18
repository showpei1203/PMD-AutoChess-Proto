#==============================================================================
# 【PMD AutoChess 中文維護說明】
# 腳本：PMD AutoChess PMDCollab Native Pose Config v0.60
# 分類：動畫／Presentation
#
# 【用途／機制】
# 處理 PMDCollab Native Pose、接近／攻擊／受擊、Beam、Projectile、Impact、Target FX
#  與畫面節奏。
#
# 【怎麼調整】
# 外觀調整優先改 Config / Tuning；不要改傷害 packet。接觸多段仍由 v0.60.2 負責傷害節奏。
#
# 【本腳本主要設定常數／資料表】
# - NATIVE_POSE_VERSION_V060 / CONTACT_MULTI_CHOREO_V060 / RANGED_MULTI_CHOREO_V060 / KICK_MOVES_V060
# - HOP_MOVES_V060 / SPIN_MOVES_V060 / SLASH_MOVES_V060 / QUICK_MOVES_V060
# - NATIVE_PHASES_V060 / NATIVE_ADDED_ACTIONS_V060
#
# 【Runtime 主要方法（查流程時可直接搜尋）】
# - merge_native_pose_data_v060 / raw_action_available_v060? / native_pose_candidates_v060 / native_pose_for_move_v060
# - native_action_data_v060 / native_elapsed_to_frame_v060 / native_phase_timing_v060
#
# 【維護規則】
# - RPG Maker VX / RGSS2 / Ruby 1.8 相容。
# - instance_uid 才是 Pokémon 個體身份；Actor ID 只是容器。
# - 新增行為優先沿用既有 helper／Data 表；避免破壞已 Freeze 的舊核心。
# - 本專案新腳本也必須保留同等級的中文說明與實際範例。
#==============================================================================
#==============================================================================
# ■ PMD AutoChess PMDCollab Native Pose Config v0.60
#------------------------------------------------------------------------------
# Presentation-only native-pose integration layer.
# - Reads the same RushFrame / HitFrame / ReturnFrame concepts used by
#   PMDCollab AnimData.xml, precompiled here for RGSS2/Ruby 1.8 safety.
# - Move families can request a better native pose, but always fall back to the
#   already verified Attack / Shoot / Charge actions when an asset is absent.
# - Contact multi-hit choreography: hit -> short retreat -> re-engage -> hit.
# - Ranged multi-hit choreography: fresh Shoot pose + fresh projectile per hit.
#==============================================================================
module PMD_AC
  NATIVE_POSE_VERSION_V060 = "0.60"

  CONTACT_MULTI_CHOREO_V060 = {
    :enabled => true,
    :retreat_px => 12.0,
    :retreat_frames => 5,
    :reengage_min_frames => 7,
    :reengage_max_frames => 16,
    :between_hits_hold => 2,
    :final_return_frames => 9,
    :ease_reengage => true,
    :log => true
  }

  RANGED_MULTI_CHOREO_V060 = {
    :enabled => true,
    :pose_gap_frames => 4,
    :launch_min_frames => 5,
    :launch_max_frames => 14,
    :between_launches_frames => 3,
    :tracking_after_first_hit => :perfect,
    :log => true
  }

  KICK_MOVES_V060 = [
    :double_kick, :jump_kick, :high_jump_kick, :triple_kick,
    :low_kick, :blaze_kick
  ]
  HOP_MOVES_V060 = [
    :bounce, :sky_drop, :fly
  ]
  SPIN_MOVES_V060 = [
    :rapid_spin, :rollout, :gyro_ball, :ice_ball
  ]
  SLASH_MOVES_V060 = [
    :slash, :night_slash, :leaf_blade, :psycho_cut, :fury_cutter,
    :x_scissor, :false_swipe, :cut, :sacred_sword, :aerial_ace,
    :shadow_claw, :cross_poison, :air_cutter
  ]
  QUICK_MOVES_V060 = [
    :quick_attack, :extreme_speed, :sucker_punch, :pursuit,
    :mach_punch, :bullet_punch, :aqua_jet, :shadow_sneak
  ]

  # PMDCollab phase metadata for the six prototype species.  These values are
  # copied from their official AnimData.xml and supplement the old minimal data.
  NATIVE_PHASES_V060 = {
    "0001" => {
      :attack => {:rush_frame=>2,:hit_frame=>5,:return_frame=>7},
      :strike => {:copy_of=>:attack},
      :shoot  => {:hit_frame=>2,:return_frame=>4},
      :charge => {:hit_frame=>5,:return_frame=>9}
    },
    "0004" => {
      :attack => {:rush_frame=>2,:hit_frame=>6,:return_frame=>8},
      :kick   => {:rush_frame=>1,:hit_frame=>3,:return_frame=>5},
      :strike => {:rush_frame=>1,:hit_frame=>3,:return_frame=>4},
      :shoot  => {:copy_of=>:charge},
      :charge => {:hit_frame=>5,:return_frame=>9}
    },
    "0007" => {
      :attack => {:rush_frame=>1,:hit_frame=>3,:return_frame=>6},
      :strike => {:copy_of=>:attack},
      :shoot  => {:hit_frame=>4,:return_frame=>8},
      :charge => {:hit_frame=>5,:return_frame=>9}
    },
    "0010" => {
      :attack => {:rush_frame=>2,:hit_frame=>5,:return_frame=>7},
      :strike => {:copy_of=>:attack},
      :shoot  => {:hit_frame=>1,:return_frame=>5},
      :charge => {:hit_frame=>5,:return_frame=>9}
    },
    "0019" => {
      :attack => {:rush_frame=>1,:hit_frame=>3,:return_frame=>6},
      :strike => {:copy_of=>:attack}
    },
    "0025" => {
      :attack => {:rush_frame=>1,:hit_frame=>3,:return_frame=>6},
      :shoot  => {:hit_frame=>2,:return_frame=>4},
      :shock  => {:hit_frame=>6,:return_frame=>10},
      :charge => {:hit_frame=>5,:return_frame=>9}
    }
  }

  # Two official Charge sheets are added to this prototype so all three ally
  # starters have a distinct charge/cast pose.  Other native poses are used
  # automatically whenever the installed PMD asset folder already contains them.
  NATIVE_ADDED_ACTIONS_V060 = {
    "0001" => {
      :charge => {
        :file=>"Charge-Anim", :frame_w=>32, :frame_h=>40,
        :frames=>10, :rows=>8, :row=>0,
        :durations=>[2,2,2,2,2,2,2,2,2,2],
        :hit_frame=>5, :return_frame=>9, :loop=>false
      }
    },
    "0007" => {
      :charge => {
        :file=>"Charge-Anim", :frame_w=>32, :frame_h=>32,
        :frames=>10, :rows=>8, :row=>0,
        :durations=>[2,2,2,2,2,2,2,2,2,2],
        :hit_frame=>5, :return_frame=>9, :loop=>false
      }
    }
  }

  class << self
    def merge_native_pose_data_v060
      return unless defined?(PMD_AUTOCHESS_DATA)
      NATIVE_ADDED_ACTIONS_V060.each do |species, actions|
        sd=PMD_AUTOCHESS_DATA[species]
        next if sd==nil
        actions.each do |key,data|
          sd[key]=data.dup if sd[key]==nil
        end
      end

      # Official CopyOf aliases that need no extra bitmap.
      [["0001",:strike,:attack],["0007",:strike,:attack],
       ["0010",:strike,:attack],["0019",:strike,:attack],
       ["0004",:shoot,:charge]].each do |row|
        sd=PMD_AUTOCHESS_DATA[row[0]]
        next if sd==nil || sd[row[2]]==nil
        sd[row[1]]=sd[row[2]].dup if sd[row[1]]==nil
      end

      # Supplement existing action hashes with official phase markers.
      NATIVE_PHASES_V060.each do |species, actions|
        sd=PMD_AUTOCHESS_DATA[species]
        next if sd==nil
        actions.each do |key,phase|
          d=sd[key]
          next if d==nil
          if phase[:copy_of]!=nil
            src=sd[phase[:copy_of]]
            next if src==nil
            [:rush_frame,:hit_frame,:return_frame].each do |field|
              d[field]=src[field] if d[field]==nil && src[field]!=nil
            end
          else
            d[:rush_frame]=phase[:rush_frame] if phase[:rush_frame]!=nil
            d[:hit_frame]=phase[:hit_frame] if phase[:hit_frame]!=nil
            d[:return_frame]=phase[:return_frame] if phase[:return_frame]!=nil
          end
          d[:phase_source]=:pmdcollab_animdata
        end
      end

      ACTION_FALLBACKS[:kick]=[:kick,:strike,:attack,:hop,:idle]
      ACTION_FALLBACKS[:hop]=[:hop,:attack,:strike,:idle]
      ACTION_FALLBACKS[:rotate]=[:rotate,:double,:attack,:idle]
      ACTION_FALLBACKS[:quick_strike]=[:quick_strike,:strike,:attack,:idle]
    end

    def raw_action_available_v060?(species,action)
      sd=action_database[species.to_s]
      return false if sd==nil
      d=sd[action]
      return false if d==nil || d[:file]==nil
      begin
        return bitmap_exists?(PMD_ROOT+species.to_s+"/",d[:file])
      rescue
        return false
      end
    end

    def native_pose_candidates_v060(species,move_key,data=nil,profile=nil)
      k=move_key==nil ? :unknown : move_key.to_sym
      if KICK_MOVES_V060.include?(k)
        return [:kick,:strike,:attack]
      end
      if HOP_MOVES_V060.include?(k)
        return [:hop,:attack,:strike]
      end
      if SPIN_MOVES_V060.include?(k)
        return [:rotate,:attack,:strike]
      end
      if SLASH_MOVES_V060.include?(k)
        return [:strike,:swing,:attack]
      end
      if QUICK_MOVES_V060.include?(k)
        return [:quick_strike,:strike,:attack]
      end
      motion=profile==nil ? nil : profile[:motion]
      visual=data==nil ? nil : (data[:visual_kind] || data[:delivery])
      move_type=data==nil ? nil : (data[:move_type] || data[:type])
      if species.to_s=="0025" && move_type==:electric &&
         motion!=:contact_return && motion!=:multi_contact && motion!=:charge_dash
        return [:shock,:shoot,:charge,:attack]
      end
      if motion==:multi_contact
        return [:strike,:attack]
      end
      if [:contact_return,:lunge_return,:step_attack,:charge_dash,
          :dash_return,:dash_stop,:dash_engage,:blink_return,
          :blink_engage,:dash_through_return,:spin_contact].include?(motion)
        return [:strike,:attack]
      end
      if visual==:projectile || visual==:beam || visual==:target_hit ||
         visual==:area_hit || (data!=nil && [:projectile,:beam,:aoe].include?(data[:delivery]))
        return [:shoot,:charge,:attack]
      end
      if data!=nil && [:self,:ally].include?(data[:target_type])
        return [:charge,:shoot,:attack,:idle]
      end
      return [:charge,:shoot,:attack] if motion==:stationary_cast
      [:attack,:strike,:shoot,:charge]
    end

    def native_pose_for_move_v060(species,move_key,data=nil,profile=nil)
      c=native_pose_candidates_v060(species,move_key,data,profile)
      c.each do |pose|
        return pose if raw_action_available_v060?(species,pose)
      end
      :attack
    end

    def native_action_data_v060(species,pose)
      sd=action_database[species.to_s]
      return nil if sd==nil
      d=sd[pose]
      return nil if d==nil
      d
    end

    def native_elapsed_to_frame_v060(data,index)
      return 0 if data==nil
      ds=data[:durations]
      return 0 if ds==nil || ds.empty? || index==nil
      idx=clamp(index.to_i,0,ds.size-1)
      total=0
      i=0
      while i<=idx
        total+=[ds[i].to_i,1].max
        i+=1
      end
      total
    end

    def native_phase_timing_v060(species,pose)
      d=native_action_data_v060(species,pose)
      return {:rush=>0,:hit=>8,:return=>12,:total=>18,:pose=>pose} if d==nil
      ds=d[:durations] || []
      total=0
      ds.each{|v|total+=[v.to_i,1].max}
      total=18 if total<=0
      hit=d[:hit_frame]
      hit_elapsed=hit==nil ? [total*45/100,1].max : native_elapsed_to_frame_v060(d,hit)
      rush=d[:rush_frame]
      rush_elapsed=rush==nil ? 0 : native_elapsed_to_frame_v060(d,rush)
      ret=d[:return_frame]
      return_elapsed=ret==nil ? [hit_elapsed+3,total].min : native_elapsed_to_frame_v060(d,ret)
      {:rush=>rush_elapsed,:hit=>hit_elapsed,:return=>return_elapsed,
       :total=>total,:pose=>pose,:rush_frame=>rush,:hit_frame=>hit,
       :return_frame=>ret}
    end
  end

  merge_native_pose_data_v060
end
