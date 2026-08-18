#==============================================================================
# 【PMD AutoChess 中文維護說明】
# 腳本：PMD AutoChess Compiled Native Pose Config v0.61.1
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
# - COMPILED_POSE_VERSION_V061 / COMPILED_DATA_PATH_V061 / COMPILED_DATA_EXPECTED_SPECIES_V061 / COMPILED_DATA_EXPECTED_NATIVE_ACTIONS_V061
# - COMPILED_DATA_EXPECTED_ALIASES_V061 / COMPILED_DATA_EXPECTED_ACTION_ENTRIES_V061 / NATIVE_KICK_MOVES_V061 / NATIVE_PUNCH_MOVES_V061
# - NATIVE_BITE_MOVES_V061 / NATIVE_SCRATCH_MOVES_V061 / NATIVE_SLASH_MOVES_V061 / NATIVE_TAIL_MOVES_V061
# - NATIVE_STOMP_SLAM_MOVES_V061 / NATIVE_LICK_MOVES_V061 / NATIVE_QUICK_MOVES_V061 / NATIVE_SPIN_MOVES_V061
# - NATIVE_JUMP_MOVES_V061 / NATIVE_SOUND_MOVES_V061 / NATIVE_DANCE_MOVES_V061 / NATIVE_GAS_EMIT_MOVES_V061
# - NATIVE_WITHDRAW_MOVES_V061 / RESERVED_NATIVE_COMBO_ACTIONS_V061
#
# 【Runtime 主要方法（查流程時可直接搜尋）】
# - load_compiled_data_v061 / compiled_data_status_v061 / compiled_data_active_v061? / compiled_direct_action_v061
# - compiled_action_asset_available_v061? / action_data / compiled_action_species_count_v061 / move_flag_v061?
# - append_unique_poses_v061 / native_pose_candidates_v061 / compiled_pose_metadata_choice_v061 / select_available_native_pose_v061
#
# 【維護規則】
# - RPG Maker VX / RGSS2 / Ruby 1.8 相容。
# - instance_uid 才是 Pokémon 個體身份；Actor ID 只是容器。
# - 新增行為優先沿用既有 helper／Data 表；避免破壞已 Freeze 的舊核心。
# - 本專案新腳本也必須保留同等級的中文說明與實際範例。
#==============================================================================
#==============================================================================
# ■ PMD AutoChess Compiled Native Pose Config v0.61.1
#------------------------------------------------------------------------------
# Runtime bridge for run_autochess_compile v0.3.0 output.
# - Reads the generated PMD_AUTOCHESS_DATA_V030 constant from VX Scripts.rvdata.
# - The generated .rb file is an IMPORT SOURCE, not a runtime sidecar.
# - Replaces the old prototype PMD_AUTOCHESS_DATA with the 0001-0494 compiled DB.
# - Uses compiler-provided Rush/Hit/Return elapsed times directly.
# - Selects richer PMDCollab actions by move semantics while remaining
#   asset-aware. Missing test assets fall back safely instead of showing a box.
# - Exposes precompiled foot/center/lower-body anchors, but v0.61 does NOT change
#   the already-approved Beam / Projectile / Impact / Target-FX coordinates.
#
# IMPORTANT:
# Formal asset pipeline remains:
# PMDCollab raw AnimData.xml + *-Anim.png -> run_autochess_compile ->
# Graphics/PMD + generated PMD_AutoChess_Data_v0_3.rb -> VX Script Library
# -> Scripts.rvdata -> runtime.
#==============================================================================
module PMD_AC
  COMPILED_POSE_VERSION_V061 = "0.61.1"
  COMPILED_DATA_PATH_V061 = "Scripts.rvdata::PMD AutoChess Data v0.3"
  COMPILED_DATA_EXPECTED_SPECIES_V061 = 494
  COMPILED_DATA_EXPECTED_NATIVE_ACTIONS_V061 = 9507
  COMPILED_DATA_EXPECTED_ALIASES_V061 = 1077
  COMPILED_DATA_EXPECTED_ACTION_ENTRIES_V061 = 10584

  # Semantic families. These describe the MOVE, not the Pokemon. The actual
  # action still comes from that Pokemon's compiled PMDCollab action table.
  NATIVE_KICK_MOVES_V061 = [
    :double_kick,:triple_kick,:jump_kick,:high_jump_kick,:low_kick,
    :rolling_kick,:mega_kick,:blaze_kick,:low_sweep
  ]
  NATIVE_PUNCH_MOVES_V061 = [
    :comet_punch,:mega_punch,:fire_punch,:ice_punch,:thunder_punch,
    :mach_punch,:bullet_punch,:drain_punch,:focus_punch,:dynamic_punch,
    :shadow_punch,:dizzy_punch,:sky_uppercut,:hammer_arm,:arm_thrust
  ]
  NATIVE_BITE_MOVES_V061 = [
    :bite,:crunch,:fire_fang,:ice_fang,:thunder_fang,:poison_fang,
    :hyper_fang,:super_fang
  ]
  NATIVE_SCRATCH_MOVES_V061 = [
    :scratch,:fury_swipes,:metal_claw,:crush_claw,:dragon_claw
  ]
  NATIVE_SLASH_MOVES_V061 = [
    :slash,:night_slash,:leaf_blade,:psycho_cut,:fury_cutter,:x_scissor,
    :false_swipe,:cut,:sacred_sword,:aerial_ace,:shadow_claw,
    :cross_poison,:air_cutter,:razor_shell
  ]
  NATIVE_TAIL_MOVES_V061 = [
    :tail_whip,:iron_tail,:aqua_tail,:dragon_tail
  ]
  NATIVE_STOMP_SLAM_MOVES_V061 = [
    :stomp,:slam,:body_slam,:heavy_slam
  ]
  NATIVE_LICK_MOVES_V061 = [:lick]
  NATIVE_QUICK_MOVES_V061 = [
    :quick_attack,:extreme_speed,:sucker_punch,:pursuit,:mach_punch,
    :bullet_punch,:aqua_jet,:shadow_sneak,:fake_out,:feint
  ]
  NATIVE_SPIN_MOVES_V061 = [
    :rapid_spin,:rollout,:gyro_ball,:ice_ball,:flame_wheel
  ]
  NATIVE_JUMP_MOVES_V061 = [
    :bounce,:fly,:sky_drop
  ]
  NATIVE_SOUND_MOVES_V061 = [
    :growl,:roar,:sing,:supersonic,:screech,:snore,:uproar,:hyper_voice,
    :metal_sound,:grass_whistle,:bug_buzz,:chatter,:echoed_voice,:round,
    :heal_bell,:relic_song
  ]
  NATIVE_DANCE_MOVES_V061 = [
    :swords_dance,:dragon_dance,:quiver_dance,:teeter_dance,
    :petal_dance,:feather_dance,:rain_dance
  ]
  NATIVE_GAS_EMIT_MOVES_V061 = [
    :smog,:smokescreen,:poison_gas,:clear_smog,:acid_spray
  ]
  NATIVE_WITHDRAW_MOVES_V061 = [:withdraw]

  # Native combo sheets are intentionally NOT used as packet timing in v0.61.
  # They have no multi-hit frame markers in the compiler output. Keep the user's
  # verified hit -> backstep -> re-engage choreography until a later combo
  # timing analyser can identify individual impact frames safely.
  RESERVED_NATIVE_COMBO_ACTIONS_V061 = [:double,:multi_strike,:multi_scratch]

  class << self
    def load_compiled_data_v061
      @compiled_data_status_v061 = {
        :loaded=>false,:path=>COMPILED_DATA_PATH_V061,:version=>nil,
        :species=>0,:entries=>0,:native=>0,:aliases=>0,:error=>nil,
        :source=>:script_library
      }
      begin
        # RPG Maker VX executes code stored in Scripts.rvdata. The compiler's
        # generated .rb is therefore imported into the Script Editor during
        # project assembly; runtime must never depend on Ruby Kernel#load.
        unless Object.const_defined?("PMD_AUTOCHESS_DATA_V030")
          @compiled_data_status_v061[:error] = :script_library_data_missing
          return false
        end
        data = Object.const_get("PMD_AUTOCHESS_DATA_V030")
        if Object.const_defined?("PMD_AUTOCHESS_DATA")
          Object.send(:remove_const,:PMD_AUTOCHESS_DATA)
        end
        Object.const_set(:PMD_AUTOCHESS_DATA,data)
        @action_file_cache_v061 = {}

        entries=0;native=0;aliases=0
        data.each do |species,actions|
          entries += actions.size
          actions.each do |key,d|
            if d!=nil && d[:alias_of]!=nil
              aliases += 1
            else
              native += 1
            end
          end
        end
        ver = Object.const_defined?("PMD_AUTOCHESS_DATA_VERSION_V030") ?
              Object.const_get("PMD_AUTOCHESS_DATA_VERSION_V030") : "unknown"
        @compiled_data_status_v061 = {
          :loaded=>true,:path=>COMPILED_DATA_PATH_V061,:version=>ver.to_s,
          :species=>data.size,:entries=>entries,:native=>native,
          :aliases=>aliases,:error=>nil,:source=>:script_library
        }
        true
      rescue Exception => e
        @compiled_data_status_v061[:error] = e.class.to_s+":"+e.message.to_s
        false
      end
    end

    def compiled_data_status_v061
      @compiled_data_status_v061 || {:loaded=>false}
    end

    def compiled_data_active_v061?
      s=compiled_data_status_v061
      s[:loaded] ? true : false
    end
  end

  # Bind embedded compiler data before the v0.61 method overrides use action_database.
  load_compiled_data_v061

  class << self
    alias pmd_ac_v061_action_data action_data unless method_defined?(:pmd_ac_v061_action_data)
    alias pmd_ac_v061_native_pose_candidates_v060 native_pose_candidates_v060 unless method_defined?(:pmd_ac_v061_native_pose_candidates_v060)
    alias pmd_ac_v061_native_pose_for_move_v060 native_pose_for_move_v060 unless method_defined?(:pmd_ac_v061_native_pose_for_move_v060)
    alias pmd_ac_v061_native_phase_timing_v060 native_phase_timing_v060 unless method_defined?(:pmd_ac_v061_native_phase_timing_v060)

    def compiled_direct_action_v061(species,key)
      sd=action_database[species.to_s]
      return nil if sd==nil
      sd[key]
    end

    def compiled_action_asset_available_v061?(species,key,data=nil)
      d=data || compiled_direct_action_v061(species,key)
      return false if d==nil || d[:file]==nil
      @action_file_cache_v061={} if @action_file_cache_v061==nil
      cache_key=species.to_s+'|'+key.to_s+'|'+d[:file].to_s
      return @action_file_cache_v061[cache_key] if @action_file_cache_v061.has_key?(cache_key)
      ok=false
      begin
        ok=bitmap_exists?(PMD_ROOT+species.to_s+'/',d[:file])
      rescue
        ok=false
      end
      @action_file_cache_v061[cache_key]=ok
      ok
    end

    # Asset-aware action lookup. This matters for the FullTestProject because it
    # intentionally carries only the six prototype Pokemon folders, while the
    # embedded compiler data describes all 494 species/actions.
    def action_data(species,requested_action)
      return pmd_ac_v061_action_data(species,requested_action) unless compiled_data_active_v061?
      sd=action_database[species.to_s]
      return nil if sd==nil
      key=requested_action
      key=key.to_sym if key.respond_to?(:to_sym)
      fallbacks=ACTION_FALLBACKS[key]
      fallbacks=[key] if fallbacks==nil
      fallbacks.each do |candidate|
        d=sd[candidate]
        next if d==nil
        return d if compiled_action_asset_available_v061?(species,candidate,d)
      end
      # Last-resort visual safety. Never select a metadata entry whose bitmap is
      # absent if a basic installed sheet is available.
      [:idle,:walk,:attack,:hurt,:sleep].each do |candidate|
        d=sd[candidate]
        next if d==nil
        return d if compiled_action_asset_available_v061?(species,candidate,d)
      end
      nil
    end

    def compiled_action_species_count_v061(key,include_alias=true)
      n=0
      action_database.each do |species,actions|
        d=actions[key]
        next if d==nil
        next if !include_alias && d[:alias_of]!=nil
        n+=1
      end
      n
    end

    def move_flag_v061?(data,flag)
      return false if data==nil
      return true if data[flag]==true
      flags=data[:source_move_flags]
      return false if flags==nil
      flags.each do |f|
        return true if f.to_s==flag.to_s
      end
      false
    end

    def append_unique_poses_v061(dst,src)
      src.each do |v|
        dst.push(v) unless dst.include?(v)
      end
      dst
    end

    # Ordered semantic candidates from the move itself. Availability is checked
    # later against the Pokemon's compiled action table and installed bitmap.
    def native_pose_candidates_v061(species,move_key,data=nil,profile=nil)
      k=move_key==nil ? :unknown : move_key.to_sym
      out=[]
      if NATIVE_KICK_MOVES_V061.include?(k)
        out=[:kick,:stomp,:strike,:attack]
      elsif NATIVE_PUNCH_MOVES_V061.include?(k)
        out=[:uppercut,:punch,:jab,:chop,:strike,:attack]
      elsif NATIVE_BITE_MOVES_V061.include?(k)
        out=[:bite,:attack,:strike]
      elsif NATIVE_SCRATCH_MOVES_V061.include?(k)
        out=[:scratch,:strike,:attack]
      elsif NATIVE_SLASH_MOVES_V061.include?(k)
        out=[:slice,:swing,:strike,:attack]
      elsif NATIVE_TAIL_MOVES_V061.include?(k)
        out=[:tail_whip,:slam,:swing,:attack]
      elsif NATIVE_STOMP_SLAM_MOVES_V061.include?(k)
        out=[:stomp,:slam,:attack,:strike]
      elsif NATIVE_LICK_MOVES_V061.include?(k)
        out=[:lick,:attack,:strike]
      elsif NATIVE_QUICK_MOVES_V061.include?(k)
        out=[:quick_strike,:strike,:attack]
      elsif NATIVE_SPIN_MOVES_V061.include?(k)
        out=[:rotate,:twirl,:strike,:attack]
      elsif NATIVE_JUMP_MOVES_V061.include?(k)
        out=[:hop,:leap_forth,:attack,:strike]
      elsif NATIVE_SOUND_MOVES_V061.include?(k) || move_flag_v061?(data,:sound)
        if k==:sing || k==:grass_whistle
          out=[:sing,:sound,:rear_up,:rumble,:charge,:shoot,:attack]
        else
          out=[:sound,:rear_up,:rumble,:sing,:charge,:shoot,:attack]
        end
      elsif NATIVE_DANCE_MOVES_V061.include?(k)
        out=[:dance,:shake,:pose,:charge,:idle]
      elsif NATIVE_GAS_EMIT_MOVES_V061.include?(k)
        out=[:gas,:emit,:sp_attack,:shoot,:charge,:attack]
      elsif NATIVE_WITHDRAW_MOVES_V061.include?(k)
        out=[:withdraw,:swell,:charge,:idle]
      end

      # Electric ranged/cast actions can use species-specific Shock if present.
      move_type=data==nil ? nil : (data[:move_type] || data[:type])
      motion=profile==nil ? nil : profile[:motion]
      contact=(data!=nil && (data[:contact] || move_flag_v061?(data,:contact)))
      if out.empty? && move_type==:electric && !contact &&
         motion!=:contact_return && motion!=:multi_contact && motion!=:charge_dash
        out=[:shock,:sp_attack,:emit,:shoot,:charge,:attack]
      end

      # Generic special/projectile/status fallback is still driven by current
      # presentation data, but can use SpAttack/Emit before generic Shoot.
      if out.empty?
        visual=data==nil ? nil : (data[:visual_kind] || data[:delivery])
        if visual==:projectile || visual==:beam || visual==:target_hit ||
           visual==:area_hit || (data!=nil && [:projectile,:beam,:aoe].include?(data[:delivery]))
          out=[:sp_attack,:emit,:shoot,:charge,:attack]
        elsif data!=nil && [:self,:ally].include?(data[:target_type])
          out=[:charge,:swell,:shake,:pose,:shoot,:attack,:idle]
        end
      end

      # Preserve every older v0.60 candidate as a final compatibility layer.
      base=pmd_ac_v061_native_pose_candidates_v060(species,k,data,profile)
      append_unique_poses_v061(out,base)
      out
    end

    def compiled_pose_metadata_choice_v061(species,move_key,data=nil,profile=nil)
      c=native_pose_candidates_v061(species,move_key,data,profile)
      c.each do |pose|
        return pose if compiled_direct_action_v061(species,pose)!=nil
      end
      nil
    end

    def select_available_native_pose_v061(species,candidates)
      # Prefer true compiled actions over compatibility aliases.
      candidates.each do |pose|
        d=compiled_direct_action_v061(species,pose)
        next if d==nil || d[:alias_of]!=nil
        return pose if compiled_action_asset_available_v061?(species,pose,d)
      end
      # Then allow compiler-generated compatibility aliases.
      candidates.each do |pose|
        d=compiled_direct_action_v061(species,pose)
        next if d==nil
        return pose if compiled_action_asset_available_v061?(species,pose,d)
      end
      nil
    end

    # v0.60 call sites continue to call this method, so redefining it here
    # upgrades every existing skill without rewriting those scripts.
    def native_pose_for_move_v060(species,move_key,data=nil,profile=nil)
      return pmd_ac_v061_native_pose_for_move_v060(species,move_key,data,profile) unless compiled_data_active_v061?
      pose=select_available_native_pose_v061(species,native_pose_candidates_v061(species,move_key,data,profile))
      return pose unless pose==nil
      pmd_ac_v061_native_pose_for_move_v060(species,move_key,data,profile)
    end

    # Use compiler-precalculated elapsed phase timing instead of re-summing the
    # XML durations every time a pose is selected.
    def native_phase_timing_v060(species,pose)
      d=compiled_direct_action_v061(species,pose)
      if compiled_data_active_v061? && d!=nil
        total=d[:total_duration].to_i
        if total<=0
          total=0
          (d[:durations]||[]).each{|v|total+=[v.to_i,1].max}
        end
        total=18 if total<=0
        hit=d[:hit_time]
        rush=d[:rush_time]
        ret=d[:return_time]
        hit_elapsed=hit==nil ? [total*45/100,1].max : hit.to_i
        rush_elapsed=rush==nil ? 0 : rush.to_i
        return_elapsed=ret==nil ? [hit_elapsed+3,total].min : ret.to_i
        return {
          :rush=>rush_elapsed,:hit=>hit_elapsed,:return=>return_elapsed,
          :total=>total,:pose=>pose,:rush_frame=>d[:rush_frame],
          :hit_frame=>d[:hit_frame],:return_frame=>d[:return_frame],
          :phase_source=>:compiled_v030
        }
      end
      pmd_ac_v061_native_phase_timing_v060(species,pose)
    end

    def compiled_anchor_v061(species,pose,direction,kind=:foot)
      d=compiled_direct_action_v061(species,pose)
      return nil if d==nil
      row=direction_row(d,direction)
      arr=nil
      arr=d[:row_foot_y] if kind==:foot
      arr=d[:row_center_y] if kind==:center
      arr=d[:row_lower_body_y] if kind==:lower_body
      return nil if arr==nil || arr.empty?
      row=0 if row<0 || row>=arr.size
      arr[row]
    end
  end

  # Expanded direct fallbacks for compiled PMDCollab actions.
  ACTION_FALLBACKS[:kick]=[:kick,:stomp,:strike,:attack,:hop,:idle]
  ACTION_FALLBACKS[:punch]=[:punch,:jab,:uppercut,:chop,:strike,:attack,:idle]
  ACTION_FALLBACKS[:bite]=[:bite,:attack,:strike,:idle]
  ACTION_FALLBACKS[:scratch]=[:scratch,:strike,:attack,:idle]
  ACTION_FALLBACKS[:slice]=[:slice,:swing,:strike,:attack,:idle]
  ACTION_FALLBACKS[:tail_whip]=[:tail_whip,:slam,:swing,:attack,:idle]
  ACTION_FALLBACKS[:stomp]=[:stomp,:slam,:attack,:strike,:idle]
  ACTION_FALLBACKS[:lick]=[:lick,:attack,:strike,:idle]
  ACTION_FALLBACKS[:sound]=[:sound,:rear_up,:rumble,:sing,:charge,:shoot,:attack,:idle]
  ACTION_FALLBACKS[:dance]=[:dance,:shake,:pose,:charge,:idle]
  ACTION_FALLBACKS[:emit]=[:emit,:sp_attack,:shoot,:charge,:attack,:idle]
  ACTION_FALLBACKS[:sp_attack]=[:sp_attack,:emit,:shoot,:charge,:attack,:idle]
  ACTION_FALLBACKS[:withdraw]=[:withdraw,:swell,:charge,:idle]
  ACTION_FALLBACKS[:quick_strike]=[:quick_strike,:strike,:attack,:idle]
  ACTION_FALLBACKS[:rotate]=[:rotate,:twirl,:attack,:strike,:idle]
  ACTION_FALLBACKS[:hop]=[:hop,:leap_forth,:attack,:strike,:idle]
end
