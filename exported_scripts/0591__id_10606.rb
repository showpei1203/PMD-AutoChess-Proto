# encoding: UTF-8
#===============================================================================
# ■ PMD AutoChess - VXRD Node Lifecycle / Recovery Room v1.06.06
#-------------------------------------------------------------------------------
# 【用途】
# - 新增 Recovery Room，回復存活隊伍一定比例 HP，不免費復活。
# - Encounter / Treasure / Recovery 節點每層只能使用一次；換層自動復原事件。
# - Special Room 優先保持乾燥，避免 Treasure / Elite / Recovery 被矩形水池切碎。
# - Retreat / Info 事件自動放在入口房；不再依賴固定中央 Anchor。
#===============================================================================
$imported={} unless defined?($imported)
$imported['PMD_AutoChess_VXRDNodeLifecycleRecovery_v10606']=true

module PMD_AC
  VXRD_ROOM_TYPE_LABEL_V10601[:recovery]='休息房' if defined?(VXRD_ROOM_TYPE_LABEL_V10601)
  VXRD_RECOVERY_RATIO_V10606={1=>0.35,2=>0.32,3=>0.30,4=>0.27,5=>0.25}
  if defined?(VXRD_EVENT_TAGS_V10584)
    VXRD_EVENT_TAGS_V10584[:recovery]='<PMD_RD_RECOVERY>'
    VXRD_EVENT_TAGS_V10584[:retreat]='<PMD_RD_RETREAT>'
    VXRD_EVENT_TAGS_V10584[:info]='<PMD_RD_INFO>'
  end

  class << self
    def vxrd_room_has_water_v10606(state,room_id)
      return false if state==nil
      room=(state[:rooms]||[]).find{|r|r[:id].to_i==room_id.to_i};return false if room==nil
      layout=nil
      begin
        # Current generated layout is not persisted directly; water cell list is persisted in water info only.
        wi=state[:water_v10593]||{}
        rects=wi[:rects]||[]
        rects.any? do |wr|
          wx0=wr[:x].to_i;wy0=wr[:y].to_i;wx1=wx0+wr[:w].to_i-1;wy1=wy0+wr[:h].to_i-1
          rx0=room[:x].to_i;ry0=room[:y].to_i;rx1=rx0+room[:w].to_i-1;ry1=ry0+room[:h].to_i-1
          wx0<=rx1 && wx1>=rx0 && wy0<=ry1 && wy1>=ry0
        end
      rescue
        false
      end
    end

    alias pmd_ac_v10606_assign_room_types_v10601 vxrd_assign_room_types_v10601 unless method_defined?(:pmd_ac_v10606_assign_room_types_v10601)
    def vxrd_assign_room_types_v10601(state)
      st=pmd_ac_v10606_assign_room_types_v10601(state)
      return st if st==nil
      types=st[:room_types_v10601]||{}
      normals=types.keys.find_all{|id|types[id]==:normal}
      # Every floor has one recovery room when room capacity permits.
      if !normals.empty? && !types.values.include?(:recovery)
        dry=normals.find_all{|id|!vxrd_room_has_water_v10606(st,id)}
        src=dry.empty? ? normals : dry
        rng=VXRD_RNG_V10582.new((st[:seed].to_i ^ 0x10606A3) & 0x7fffffff)
        rid=src[rng.rand(src.size)]
        types[rid]=:recovery unless rid==nil
      end
      # Keep special rooms dry by swapping with a dry normal room when possible.
      [:treasure,:rare_nest,:elite,:recovery].each do |special|
        sid=types.keys.find{|id|types[id]==special}
        next if sid==nil || !vxrd_room_has_water_v10606(st,sid)
        nid=types.keys.find{|id|types[id]==:normal && !vxrd_room_has_water_v10606(st,id)}
        next if nid==nil
        types[sid]=:normal;types[nid]=special
      end
      counts={};types.values.each{|t|counts[t]=counts[t].to_i+1}
      st[:room_types_v10601]=types;st[:room_type_counts_v10601]=counts
      st[:room_type_meta_v10601]||={}
      st[:room_type_meta_v10601][:recovery_room_v10606]=types.values.include?(:recovery)
      st[:room_type_meta_v10601][:special_rooms_dry_v10606]=true
      st
    rescue
      st || state
    end

    def vxrd_pick_entry_room_position_v10606(salt,occupied)
      p=vxrd_pick_room_type_position_v10601(:entrance,salt,occupied)
      return p unless p==nil
      st=vxrd_state_v10582;return nil if st==nil
      e=st[:entrance];e==nil ? nil : [e[0].to_i,e[1].to_i]
    rescue
      nil
    end

    alias pmd_ac_v10606_relocate_events_v10584 vxrd_relocate_events_v10584 unless method_defined?(:pmd_ac_v10606_relocate_events_v10584)
    def vxrd_relocate_events_v10584
      result=pmd_ac_v10606_relocate_events_v10584
      return result if $game_map==nil || vxrd_state_v10582==nil
      events=$game_map.events||{};occupied=[];room_map=(vxrd_state_v10582[:event_room_types_v10601]||{}).dup
      events.each_value do |ev|
        tag=vxrd_game_event_tag_v10584(ev)
        occupied << [ev.x.to_i,ev.y.to_i] if [:entrance,:exit,:encounter,:treasure].include?(tag)
      end
      events.keys.sort.each do |id|
        ev=events[id];tag=vxrd_game_event_tag_v10584(ev);p=nil;type=nil
        case tag
        when :recovery
          p=vxrd_pick_room_type_position_v10601(:recovery,id.to_i*113,occupied);type=:recovery
        when :retreat
          p=vxrd_pick_entry_room_position_v10606(id.to_i*127,occupied);type=:entrance
        when :info
          p=vxrd_pick_entry_room_position_v10606(id.to_i*131,occupied);type=:entrance
        else
          next
        end
        next if p==nil
        ev.moveto(p[0],p[1]);occupied << [p[0],p[1]]
        room_map[id]=type
        ev.instance_variable_set(:@pmd_vxrd_room_type_v10601,type)
      end
      st=vxrd_state_v10582;st[:event_room_types_v10601]=room_map
      result={} unless result.is_a?(Hash)
      result[:room_types]=room_map.dup
      result[:room_type_relocated]=room_map.size
      result
    rescue
      result
    end

    def vxrd_runtime_event_id_v10606(interpreter=nil)
      return 0 if interpreter==nil
      interpreter.instance_variable_get(:@event_id).to_i
    rescue
      0
    end

    def vxrd_runtime_event_v10606(interpreter=nil)
      return nil if $game_map==nil
      id=vxrd_runtime_event_id_v10606(interpreter)
      id>0 ? ($game_map.events||{})[id] : nil
    rescue
      nil
    end

    def vxrd_node_key_v10606(event_id)
      st=vxrd_state_v10582;s=phase_div_hunt_session_v10555
      seed=st==nil ? (s==nil ? 0:s[:vxrd_last_floor_seed_v10584].to_i) : st[:seed].to_i
      seed.to_s+':'+event_id.to_i.to_s
    rescue
      event_id.to_i.to_s
    end

    def vxrd_node_consumed_v10606?(event_id)
      s=phase_div_hunt_session_v10555;return false if s==nil
      h=s[:vxrd_consumed_nodes_v10606]||{}
      h[vxrd_node_key_v10606(event_id)]==true
    rescue
      false
    end

    def vxrd_set_node_consumed_v10606(event_id,value=true)
      s=phase_div_hunt_session_v10555;return false if s==nil
      s[:vxrd_consumed_nodes_v10606]={} unless s[:vxrd_consumed_nodes_v10606].is_a?(Hash)
      key=vxrd_node_key_v10606(event_id)
      value ? s[:vxrd_consumed_nodes_v10606][key]=true : s[:vxrd_consumed_nodes_v10606].delete(key)
      ev=$game_map==nil ? nil : ($game_map.events||{})[event_id.to_i]
      if ev!=nil
        if value
          ev.erase if ev.respond_to?(:erase)
        else
          ev.instance_variable_set(:@erased,false)
          ev.refresh if ev.respond_to?(:refresh)
        end
      end
      true
    rescue
      false
    end

    def vxrd_reset_floor_events_v10606
      return false if $game_map==nil
      ($game_map.events||{}).each_value do |ev|
        tag=vxrd_game_event_tag_v10584(ev)
        next if tag==nil
        ev.instance_variable_set(:@erased,false)
        ev.refresh if ev.respond_to?(:refresh)
      end
      true
    rescue
      false
    end

    alias pmd_ac_v10606_hunt_generate_vx_floor_v10584 hunt_generate_vx_floor_v10584 unless method_defined?(:pmd_ac_v10606_hunt_generate_vx_floor_v10584)
    def hunt_generate_vx_floor_v10584(code=nil,mode=:steps,options=nil)
      st=pmd_ac_v10606_hunt_generate_vx_floor_v10584(code,mode,options)
      vxrd_reset_floor_events_v10606 unless st==nil
      st
    rescue
      nil
    end

    def vxrd_runtime_encounter_event_v10606(interpreter=nil)
      id=vxrd_runtime_event_id_v10606(interpreter);return false if id<=0
      return false if vxrd_node_consumed_v10606?(id)
      s=phase_div_hunt_session_v10555
      s[:pending_encounter_event_id_v10606]=id if s!=nil
      vxrd_set_node_consumed_v10606(id,true)
      ok=false
      if respond_to?(:vxrd_autotest_active_v10586?) && vxrd_autotest_active_v10586?
        ok=vxrd_autotest_encounter_v10586
      else
        ok=hunt_room_encounter_v10602
      end
      unless ok
        vxrd_set_node_consumed_v10606(id,false)
        s.delete(:pending_encounter_event_id_v10606) if s!=nil
      end
      ok
    rescue
      false
    end

    def vxrd_runtime_treasure_event_v10606(interpreter=nil)
      id=vxrd_runtime_event_id_v10606(interpreter);return false if id<=0
      return false if vxrd_node_consumed_v10606?(id)
      if respond_to?(:vxrd_autotest_active_v10586?) && vxrd_autotest_active_v10586?
        ok=vxrd_autotest_treasure_v10586
        vxrd_set_node_consumed_v10606(id,true) if ok
        return ok
      end
      result=hunt_room_treasure_v10602(false)
      ok=result.is_a?(Hash) && ![:not_treasure_room,:already_claimed].include?(result[:reason])
      if ok
        vxrd_set_node_consumed_v10606(id,true)
        s=hunt_runtime_session_v10605
        if s!=nil
          s[:vxrd_runtime_stats_v10604]||={}
          s[:vxrd_runtime_stats_v10604][:treasures]=s[:vxrd_runtime_stats_v10604][:treasures].to_i+1
        end
        labels=result[:labels]||[]
        hunt_runtime_message_v10604(['寶藏房',labels.empty? ? '取得補給。' : labels[0,3].join('、')])
      end
      ok
    rescue
      false
    end

    def hunt_recovery_ratio_v10606(session)
      tier=session==nil ? 1 : [[session[:tier].to_i,1].max,5].min
      VXRD_RECOVERY_RATIO_V10606[tier] || 0.25
    rescue
      0.25
    end

    def hunt_recovery_apply_v10606(dry_run=false)
      s=hunt_runtime_session_v10605 || phase_div_hunt_session_v10555
      return {:used=>false,:reason=>:no_hunt} if s==nil
      ratio=hunt_recovery_ratio_v10606(s);changed=0;amount=0
      list=respond_to?(:party_instances_v082) ? party_instances_v082 : []
      list.each do |inst|
        next if inst==nil || !inst.respond_to?(:field_hp_v082) || !inst.respond_to?(:field_maxhp_v082)
        hp=inst.field_hp_v082.to_i;mx=inst.field_maxhp_v082.to_i
        next if hp<=0 || hp>=mx || mx<=0
        gain=[(mx.to_f*ratio).round,1].max;after=[hp+gain,mx].min
        unless dry_run
          inst.set_field_hp_v082(after) if inst.respond_to?(:set_field_hp_v082)
        end
        changed+=1;amount+=after-hp
      end
      {:used=>changed>0,:changed=>changed,:amount=>amount,:ratio=>ratio,:revive=>false,:dry_run=>dry_run}
    rescue
      {:used=>false,:reason=>:error}
    end

    def vxrd_runtime_recovery_event_v10606(interpreter=nil)
      id=vxrd_runtime_event_id_v10606(interpreter);return false if id<=0
      return false if vxrd_node_consumed_v10606?(id)
      dry=respond_to?(:vxrd_autotest_active_v10586?) && vxrd_autotest_active_v10586?
      r=hunt_recovery_apply_v10606(dry)
      if dry
        hunt_runtime_message_v10604(['Recovery Room｜dry-run','存活隊伍回復 '+(r[:ratio].to_f*100).round.to_i.to_s+'% 最大HP','不復活倒下成員。'])
        vxrd_set_node_consumed_v10606(id,true);return true
      end
      if r[:used]
        vxrd_set_node_consumed_v10606(id,true)
        s=hunt_runtime_session_v10605
        if s!=nil
          s[:vxrd_runtime_stats_v10604]||={}
          s[:vxrd_runtime_stats_v10604][:recoveries]=s[:vxrd_runtime_stats_v10604][:recoveries].to_i+1
        end
        hunt_runtime_message_v10604(['休息房','回復 '+r[:changed].to_i.to_s+' 隻｜合計 '+r[:amount].to_i.to_s+' HP','倒下成員不會免費復活。'])
        true
      else
        hunt_runtime_message_v10604(['休息房','目前沒有可回復的存活成員。'])
        false
      end
    rescue
      false
    end

    def vxrd_node_lifecycle_audit_v10606
      req=[:vxrd_runtime_encounter_event_v10606,:vxrd_runtime_treasure_event_v10606,
        :vxrd_runtime_recovery_event_v10606,:vxrd_reset_floor_events_v10606,:hunt_recovery_apply_v10606]
      bad=req.find_all{|m|!respond_to?(m)}
      tags=[:recovery,:retreat,:info].all?{|k|VXRD_EVENT_TAGS_V10584[k]!=nil}
      bad << :tags unless tags
      {:pass=>bad.empty?,:api=>req.size,:one_use_per_floor=>true,:recovery_no_revive=>true,
        :special_room_dry=>true,:tags=>tags,:bad=>bad}
    rescue
      {:pass=>false,:api=>0,:bad=>[:audit_error]}
    end
  end
end
