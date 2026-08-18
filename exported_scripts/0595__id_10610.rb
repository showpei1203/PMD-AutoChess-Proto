# encoding: UTF-8
#===============================================================================
# ■ PMD AutoChess - VXRD Random Hunt Content / Structure Seal v1.06.10
#-------------------------------------------------------------------------------
# 【完成規則】
# - 21 Hunt 全部由同一 VX-native Random Dungeon Runtime 承接。
# - 牆／地板／裝飾沿用已驗證 Authority；水域只出現在 H02/H07/H12/H17。
# - 水域採 FS 參考腳本中 moss A1 animated-water family 對應的 VX base 2096，
#   搭配同 floor family 的乾岸；矩形 only、單一水種、無河流、無橋。
# - Room Type：入口／出口／一般／寶藏／稀有巢穴／菁英／休息共 7 類。
# - Battle Loot 即時取得；Treasure Room 額外一次既有 Loot Pool；
#   只有完整通關再給一次 Completion Bonus，撤退／敗北不給。
#===============================================================================
$imported={} unless defined?($imported)
$imported['PMD_AutoChess_VXRDRandomHuntStructureSeal_v10610']=true

module PMD_AC
  VXRD_FINAL_WATER_BASE_V10610=2096
  VXRD_FINAL_WATER_CODES_V10610=['H02','H07','H12','H17']
  VXRD_FINAL_ROOM_TYPES_V10610=[:entrance,:exit,:normal,:treasure,:rare_nest,:elite,:recovery]

  # Reference-derived correction: FS hikimoki_moss uses the second VX A1 animated-water family.
  VXRD_FINAL_WATER_CODES_V10610.each do |c|
    if defined?(VXRD_HUNT_STYLE_V10600) && VXRD_HUNT_STYLE_V10600[c].is_a?(Hash)
      VXRD_HUNT_STYLE_V10600[c][:water]=true
      VXRD_HUNT_STYLE_V10600[c][:water_base]=VXRD_FINAL_WATER_BASE_V10610
      VXRD_HUNT_STYLE_V10600[c][:water_rects]=(c=='H02' || c=='H07') ? 1 : 2
    end
  end

  if defined?(VXRD_ROOM_TYPE_LABEL_V10601)
    VXRD_ROOM_TYPE_LABEL_V10601[:recovery]='休息房'
  end

  class VXRD_Layout_V10582
    # Final deterministic rectangle water placement. Unlike v1.05.93's
    # random-try approach, enumerate valid placements so a Water Hunt cannot
    # randomly become a completely dry floor when a valid room exists.
    def vxrd_place_regular_water_v10593
      @water_rects_v10593=[]
      prof=pmd_vxrd_water_profile_v10593
      return 0 if prof[:rects].to_i<=0 || prof[:chance].to_i<=0
      return 0 if @rng.rand(100)>=prof[:chance].to_i
      candidates=@rooms.find_all{|r|r[:w].to_i>=6 && r[:h].to_i>=6}
      candidates=candidates.find_all do |r|
        inside_e=@entrance && @entrance[0]>=r[:x] && @entrance[0]<r[:x]+r[:w] && @entrance[1]>=r[:y] && @entrance[1]<r[:y]+r[:h]
        inside_x=@exit_pos && @exit_pos[0]>=r[:x] && @exit_pos[0]<r[:x]+r[:w] && @exit_pos[1]>=r[:y] && @exit_pos[1]<r[:y]+r[:h]
        !inside_e && !inside_x
      end
      wanted=[prof[:rects].to_i,candidates.size].min
      used={}
      wanted.times do |slot|
        placements=[]
        candidates.each do |r|
          next if used[r[:id].to_i]
          [[4,3],[3,3],[3,2],[2,2]].each do |sz|
            ww=[sz[0],r[:w].to_i-2].min;hh=[sz[1],r[:h].to_i-2].min
            next if ww<2 || hh<2
            xmin=r[:x].to_i+1;xmax=r[:x].to_i+r[:w].to_i-ww-1
            ymin=r[:y].to_i+1;ymax=r[:y].to_i+r[:h].to_i-hh-1
            next if xmax<xmin || ymax<ymin
            for ty in ymin..ymax
              for tx in xmin..xmax
                spans_cx=(tx<=r[:cx].to_i && tx+ww-1>=r[:cx].to_i)
                spans_cy=(ty<=r[:cy].to_i && ty+hh-1>=r[:cy].to_i)
                next if spans_cx || spans_cy
                fixed_hit=false
                (@options[:fixed_positions]||[]).each do |fp|
                  next unless fp.is_a?(Array) && fp.size>=2
                  fx=fp[0].to_i;fy=fp[1].to_i
                  if fx>=tx && fx<tx+ww && fy>=ty && fy<ty+hh
                    fixed_hit=true;break
                  end
                end
                next if fixed_hit
                placements << [r,tx,ty,ww,hh]
              end
            end
            break unless placements.empty?
          end
        end
        break if placements.empty?
        pick=placements[@rng.rand(placements.size)]
        r,wx,wy,ww,hh=pick
        for yy in wy...(wy+hh)
          for xx in wx...(wx+ww)
            @grid[yy][xx]=2 if @grid[yy][xx]==1
          end
        end
        @water_rects_v10593 << {:x=>wx,:y=>wy,:w=>ww,:h=>hh,:room_id=>r[:id].to_i}
        used[r[:id].to_i]=true
      end
      @water_rects_v10593.size
    rescue
      0
    end
  end

  class << self
    alias pmd_ac_v10610_vxrd_options_v10582 vxrd_options_v10582 unless method_defined?(:pmd_ac_v10610_vxrd_options_v10582)
    def vxrd_options_v10582(code,options=nil)
      o=pmd_ac_v10610_vxrd_options_v10582(code,options)
      if VXRD_FINAL_WATER_CODES_V10610.include?(code.to_s.upcase)
        o[:min_room]=[o[:min_room].to_i,6].max
      end
      o
    rescue
      options.is_a?(Hash) ? options.dup : {}
    end

    alias pmd_ac_v10610_hunt_runtime_advance_floor_v10605 hunt_runtime_advance_floor_v10605 unless method_defined?(:pmd_ac_v10610_hunt_runtime_advance_floor_v10605)
    def hunt_runtime_advance_floor_v10605
      s=hunt_runtime_session_v10605
      return false if s==nil
      floor=s[:vxrd_floor_count_v10584].to_i
      st=s[:vxrd_runtime_stats_v10604]||={}
      wins=(st[:floor_wins]||{})[floor].to_i
      if wins<=0
        hunt_runtime_message_v10604(['出口尚未穩定','本層至少完成 1 場戰鬥後才能前往下一層。','探索 Encounter / Rare Nest / Elite Room 皆可。'])
        return false
      end
      pmd_ac_v10610_hunt_runtime_advance_floor_v10605
    rescue
      false
    end

    def hunt_runtime_floor_gate_v10610
      s=hunt_runtime_session_v10605;return {:pass=>false,:reason=>:no_run} if s==nil
      f=s[:vxrd_floor_count_v10584].to_i;st=s[:vxrd_runtime_stats_v10604]||={}
      w=(st[:floor_wins]||{})[f].to_i
      {:pass=>w>0,:floor=>f,:wins=>w,:required=>1}
    rescue
      {:pass=>false,:reason=>:error}
    end

    alias pmd_ac_v10610_vxrd_runtime_info_event_v10605 vxrd_runtime_info_event_v10605 unless method_defined?(:pmd_ac_v10610_vxrd_runtime_info_event_v10605)
    def vxrd_runtime_info_event_v10605(interpreter=nil)
      if respond_to?(:vxrd_autotest_active_v10586?) && vxrd_autotest_active_v10586?
        return pmd_ac_v10610_vxrd_runtime_info_event_v10605(interpreter)
      end
      i=hunt_runtime_info_v10605;return false if i==nil
      gate=hunt_runtime_floor_gate_v10610
      gate_text=gate[:pass] ? '出口已穩定：可前往下一層' : '出口未穩定：本層需至少 1 勝'
      hunt_runtime_message_v10604([
        i[:code].to_s+'｜Floor '+i[:floor].to_i.to_s+'/'+i[:max_floor].to_i.to_s,
        '探索 '+i[:explored].to_i.to_s+'%｜遭遇 '+i[:encounters].to_i.to_s+'｜Room '+i[:room].to_s,
        gate_text,
        '入口附近可撤退；已取得招募與掉落會保留。'
      ])
      true
    rescue
      false
    end

    def vxrd_final_water_policy_v10610(code=nil)
      c=code==nil ? nil : code.to_s.upcase
      style=c==nil ? nil : (defined?(VXRD_HUNT_STYLE_V10600) ? VXRD_HUNT_STYLE_V10600[c] : nil)
      {:code=>c,:enabled=>(style!=nil && style[:water] ? true:false),
        :water_base=>(style==nil ? 0:style[:water_base].to_i),
        :rectangle_only=>true,:one_type_per_style=>true,:river=>false,:bridge=>false,
        :bank=>true,:source=>:fs_hikimoki_moss_a1_family}
    rescue
      {:code=>c,:enabled=>false,:water_base=>0,:rectangle_only=>true,:river=>false,:bridge=>false}
    end

    def vxrd_final_room_policy_v10610
      {:types=>VXRD_FINAL_ROOM_TYPES_V10610.dup,:treasure_guaranteed=>true,
        :recovery_guaranteed=>true,:rare_requires_active_pool=>true,:elite_min_tier=>2,
        :special_rooms_dry=>true,:no_free_revive=>true}
    end

    def vxrd_final_reward_policy_v10610
      {:battle_loot=>:existing_hunt_pool,:treasure=>:existing_hunt_pool,
        :completion_bonus=>:one_existing_pool_draw,:retreat_bonus=>false,:defeat_bonus=>false,
        :recruit_exact_encounter=>true,:floor_exit_requires_win=>1}
    end

    def vxrd_random_hunt_system_audit_v10610
      bad=[]
      hunts=defined?(PHASE_DIV_HUNT_ORDER_V10553) ? PHASE_DIV_HUNT_ORDER_V10553 : []
      bad << :hunt_count unless hunts.size==21
      wet=hunts.find_all{|c|VXRD_HUNT_STYLE_V10600[c] && VXRD_HUNT_STYLE_V10600[c][:water]}
      bad << :water_scope unless wet.sort==VXRD_FINAL_WATER_CODES_V10610.sort
      wet.each do |c|
        s=VXRD_HUNT_STYLE_V10600[c]
        bad << ('water_base_'+c).to_sym unless s[:water_base].to_i==VXRD_FINAL_WATER_BASE_V10610
      end
      wa=respond_to?(:vxrd_wall_geometry_audit_v10592) ? vxrd_wall_geometry_audit_v10592 : {:pass=>true}
      bad << :wall unless wa[:pass]
      va=respond_to?(:vxrd_visual_style_audit_v10600) ? vxrd_visual_style_audit_v10600 : {:pass=>false}
      bad << :visual_style unless va[:pass]
      ra=respond_to?(:vxrd_room_runtime_audit_v10602) ? vxrd_room_runtime_audit_v10602 : {:pass=>false}
      bad << :room_runtime unless ra[:pass]
      na=respond_to?(:vxrd_node_lifecycle_audit_v10606) ? vxrd_node_lifecycle_audit_v10606 : {:pass=>false}
      bad << :node_lifecycle unless na[:pass]
      aa=respond_to?(:hunt_run_accounting_audit_v10608) ? hunt_run_accounting_audit_v10608 : {:pass=>false}
      bad << :accounting unless aa[:pass]
      sa=respond_to?(:vxrd_save_resume_audit_v10609) ? vxrd_save_resume_audit_v10609 : {:pass=>false}
      bad << :save_resume unless sa[:pass]
      map_ok=FileTest.exist?('Data/Map090.rvdata') rescue false
      bad << :map090 unless map_ok
      tags=defined?(VXRD_EVENT_TAGS_V10584) ? VXRD_EVENT_TAGS_V10584 : {}
      [:entrance,:exit,:encounter,:treasure,:recovery,:retreat,:info].each{|k|bad << ('tag_'+k.to_s).to_sym if tags[k]==nil}
      {:pass=>bad.empty?,:hunts=>hunts.size,:water_codes=>wet,:water_base=>VXRD_FINAL_WATER_BASE_V10610,
        :room_types=>VXRD_FINAL_ROOM_TYPES_V10610.size,:floor_curve=>VXRD_HUNT_FLOORS_BY_TIER_V10604.values,
        :rtp_tiles_only=>true,:external_png=>false,:parallax=>false,:second_map_runtime=>false,
        :river=>false,:bridge=>false,:water_irregular=>false,:map090=>map_ok,:bad=>bad}
    rescue
      {:pass=>false,:hunts=>0,:room_types=>0,:bad=>[:audit_error]}
    end
  end
end
