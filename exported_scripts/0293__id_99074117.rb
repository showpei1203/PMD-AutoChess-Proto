#==============================================================================
# 【PMD AutoChess 中文維護說明】
# 腳本：PMD AutoChess RPG Encounter Data v0.81
# 分類：RPG 遇敵橋接
#
# 【用途／機制】
# 把自走棋戰鬥接到地圖野怪、Boss、事件戰與指定 Stage。
#
# 【怎麼調整】
# 事件範例：PMD_AC.start_battle_v081(:boss_beedrill)；野外範例：PMD_AC.wild_on_
# v081(:forest_wild,10,18)。
#
# 【本腳本主要設定常數／資料表】
# - RPG_ENCOUNTER_DB_V081 / MAP_WILD_DEFAULTS_V081 / RPG_ENCOUNTER_VERIFY_END_V081 / RPG_ENCOUNTER_MANIFEST_V081
#
# 【Runtime 主要方法（查流程時可直接搜尋）】
# - encounter_data_v081 / battle_request_v081 / clear_battle_request_v081 / stage_request_v081
# - make_battle_request_v081 / start_stage_battle_v081 / start_battle_v081 / launch_battle_request_v081
# - battle_result_state_v081 / last_battle_result_v081 / battle_won_v081? / battle_lost_v081?
#
# 【維護規則】
# - RPG Maker VX / RGSS2 / Ruby 1.8 相容。
# - instance_uid 才是 Pokémon 個體身份；Actor ID 只是容器。
# - 新增行為優先沿用既有 helper／Data 表；避免破壞已 Freeze 的舊核心。
# - 本專案新腳本也必須保留同等級的中文說明與實際範例。
#==============================================================================
#==============================================================================
# PMD AutoChess RPG Encounter Data v0.81
# RGSS2 / Ruby 1.8 compatible
#------------------------------------------------------------------------------
# v0.80 Stage remains intact. This database adds RPG-facing battle definitions.
#
# Event script calls:
#   PMD_AC.start_battle_v081(:roadside_pikachu)
#   PMD_AC.start_battle_v081(:boss_beedrill)
#   PMD_AC.start_stage_battle_v081(2)
#
# Result checks after returning to the map:
#   PMD_AC.battle_won_v081?
#   PMD_AC.battle_lost_v081?
#   PMD_AC.battle_escaped_v081?
#   PMD_AC.last_battle_result_v081
#
# Enable random wild encounters on the current map:
#   PMD_AC.wild_on_v081(:forest_wild, 10, 18)
#   PMD_AC.wild_on_v081(:forest_wild, 10, 18, [1,2])  # terrain tags only
#   PMD_AC.wild_off_v081
#
# Optional result hooks:
#   PMD_AC.start_battle_v081(:boss_beedrill,
#     {:win_switch=>21, :lose_switch=>22, :result_variable=>30})
# result_variable: 1=win, 2=lose, 3=escape.
#==============================================================================
module PMD_AC
  RPG_ENCOUNTER_DB_V081 = {
    :forest_wild=>{
      :id=>:forest_wild,
      :name=>'林地野生群',
      :kind=>:wild,
      :team_size=>3,
      :enemy_pool=>[
        {:species=>:caterpie,:min_level=>10,:max_level=>13,:weight=>35},
        {:species=>:rattata,:min_level=>10,:max_level=>14,:weight=>30},
        {:species=>:pidgey,:min_level=>11,:max_level=>14,:weight=>25},
        {:species=>:pikachu,:min_level=>12,:max_level=>15,:weight=>10}
      ],
      :recruitable=>true,
      :recruit_rate=>30,
      :can_escape=>true,
      :deploy=>false,
      :weather=>nil
    },
    :roadside_pikachu=>{
      :id=>:roadside_pikachu,
      :name=>'受驚的皮卡丘',
      :kind=>:scripted,
      :enemy_setup=>[
        [:pikachu,5,2,16,{}]
      ],
      :recruitable=>true,
      :recruit_rate=>100,
      :can_escape=>true,
      :deploy=>false,
      :weather=>nil
    },
    :boss_beedrill=>{
      :id=>:boss_beedrill,
      :name=>'蜂巢霸主・大針蜂',
      :kind=>:boss,
      :enemy_setup=>[
        [:weedle,4,1,15,{}],
        [:beedrill,5,2,18,{
          :boss=>true,
          :stat_mult=>{:hp=>2.60,:atk=>1.25,:def=>1.15,:spatk=>1.10,:spdef=>1.20,:speed=>1.05},
          :energy_start=>55,
          :active_moves=>[:fury_attack,:focus_energy],
          :phases=>[
            {:key=>:queen_rage,:hp_below=>0.50,:text=>'霸主狂暴',
             :effects=>[[:shield_rate,0.25],[:stat_mult,:atk,1.20],[:stat_mult,:speed,1.12],[:energy,35]]},
            {:key=>:last_sting,:hp_below=>0.25,:text=>'最後一搏',
             :effects=>[[:stat_mult,:atk,1.15],[:stat_mult,:spatk,1.15],[:energy,50]]}
          ]
        }],
        [:kakuna,5,3,15,{}]
      ],
      :recruitable=>false,
      :recruit_rate=>0,
      :can_escape=>false,
      :deploy=>true,
      :weather=>nil,
      :boss=>true
    }
  }

  # Optional map defaults. Keep empty in the test project so random encounters
  # never interrupt ordinary validation. Production projects may add entries:
  #   12=>{:encounter=>:forest_wild,:min_steps=>10,:max_steps=>18,:terrain_tags=>[1]}
  MAP_WILD_DEFAULTS_V081 = {}

  RPG_ENCOUNTER_VERIFY_END_V081 = 24
  RPG_ENCOUNTER_MANIFEST_V081 = {
    :schema_version=>'1.0',
    :content_version=>'0.81.0',
    :contexts=>[:stage,:wild,:boss,:scripted],
    :stage_bridge=>'v0.80',
    :wild_map_runtime=>true,
    :wild_terrain_filter=>true,
    :boss_custom_stats=>true,
    :boss_phase_rules=>true,
    :boss_recruitable=>false,
    :script_call=>true,
    :result_bridge=>'win,lose,escape',
    :identity=>'instance_uid',
    :runtime_checksum32=>130810081
  }

  class << self
    def encounter_data_v081(key)
      RPG_ENCOUNTER_DB_V081[key]
    end

    def battle_request_v081
      return nil if $game_temp==nil
      $game_temp.pmd_autochess_request_v081
    end

    def clear_battle_request_v081
      $game_temp.pmd_autochess_request_v081=nil if $game_temp!=nil
    end

    def stage_request_v081(stage_id,options=nil)
      d=stage_data_v080(stage_id)
      return nil if d==nil
      o=options==nil ? {} : options.dup
      {:key=>('stage_'+stage_id.to_i.to_s).to_sym,:name=>d[:name],:kind=>:stage,
       :stage_id=>stage_id.to_i,:enemy_setup=>d[:enemy_setup],:weather=>d[:weather],
       :recruitable=>true,:can_escape=>true,:deploy=>true,:options=>o,:source=>:script}
    end

    def make_battle_request_v081(key,options=nil)
      d=encounter_data_v081(key)
      return nil if d==nil
      o=options==nil ? {} : options.dup
      r=d.dup
      r[:options]=o
      r[:source]=(o[:source] || :script)
      r[:deploy]=o[:deploy] unless o[:deploy]==nil
      r[:can_escape]=o[:can_escape] unless o[:can_escape]==nil
      r
    end

    def start_stage_battle_v081(stage_id,options=nil)
      r=stage_request_v081(stage_id,options)
      return false if r==nil
      launch_battle_request_v081(r)
    end

    def start_battle_v081(key,options=nil)
      r=make_battle_request_v081(key,options)
      return false if r==nil
      launch_battle_request_v081(r)
    end

    def launch_battle_request_v081(request)
      return false if request==nil || $game_temp==nil
      $game_temp.pmd_autochess_request_v081=request
      # Use next_scene while on Scene_Map so Game_Interpreter pauses exactly like
      # native battle processing. This keeps following event commands from running
      # before the AutoChess battle has returned to the map.
      if $scene!=nil && $scene.is_a?(Scene_Map)
        $game_temp.next_scene='pmd_autochess'
      else
        $scene=Scene_PMD_AutoChess.new
      end
      true
    end

    def battle_result_state_v081
      return nil if $game_system==nil
      $game_system.pmd_autochess_last_result_v081
    end

    def last_battle_result_v081
      s=battle_result_state_v081
      s==nil ? nil : s[:result]
    end

    def battle_won_v081?; last_battle_result_v081==:win; end
    def battle_lost_v081?; last_battle_result_v081==:lose; end
    def battle_escaped_v081?; last_battle_result_v081==:escape; end

    def record_battle_result_v081(request,result)
      return if $game_system==nil
      data={:result=>result,:kind=>(request==nil ? nil : request[:kind]),
        :encounter=>(request==nil ? nil : request[:key]),
        :stage_id=>(request==nil ? nil : request[:stage_id])}
      $game_system.pmd_autochess_last_result_v081=data
      apply_battle_result_hooks_v081(request,result)
      data
    end

    def apply_battle_result_hooks_v081(request,result)
      return if request==nil
      o=request[:options] || {}
      sw=nil
      sw=o[:win_switch] if result==:win
      sw=o[:lose_switch] if result==:lose
      sw=o[:escape_switch] if result==:escape
      if sw!=nil && sw.to_i>0 && $game_switches!=nil
        $game_switches[sw.to_i]=true
      end
      if o[:result_variable]!=nil && o[:result_variable].to_i>0 && $game_variables!=nil
        val=result==:win ? 1 : (result==:lose ? 2 : 3)
        $game_variables[o[:result_variable].to_i]=val
      end
    end

    def wild_runtime_maps_v081
      return {} if $game_system==nil
      h=$game_system.pmd_autochess_wild_maps_v081
      if h==nil
        h={}
        $game_system.pmd_autochess_wild_maps_v081=h
      end
      h
    end

    def wild_config_for_map_v081(map_id)
      mid=map_id.to_i
      h=wild_runtime_maps_v081
      return h[mid] if h.has_key?(mid)
      MAP_WILD_DEFAULTS_V081[mid]
    end

    def wild_on_v081(encounter_key,min_steps=10,max_steps=18,terrain_tags=nil,map_id=nil)
      return false if encounter_data_v081(encounter_key)==nil
      mid=map_id==nil ? ($game_map==nil ? 0 : $game_map.map_id) : map_id.to_i
      return false if mid<=0
      mn=[min_steps.to_i,1].max
      mx=[max_steps.to_i,mn].max
      tags=terrain_tags==nil ? [] : terrain_tags.collect{|x|x.to_i}
      wild_runtime_maps_v081[mid]={:encounter=>encounter_key,:min_steps=>mn,:max_steps=>mx,:terrain_tags=>tags}
      $game_player.make_pmd_encounter_count_v081(mn,mx) if $game_player!=nil && $game_player.respond_to?(:make_pmd_encounter_count_v081)
      true
    end

    def wild_off_v081(map_id=nil)
      mid=map_id==nil ? ($game_map==nil ? 0 : $game_map.map_id) : map_id.to_i
      return false if mid<=0
      wild_runtime_maps_v081.delete(mid)
      true
    end

    def wild_terrain_valid_v081(config)
      return true if config==nil
      tags=config[:terrain_tags] || []
      return true if tags.empty?
      return false if $game_map==nil || $game_player==nil
      tag=0
      begin
        tag=$game_map.terrain_tag($game_player.x,$game_player.y).to_i
      rescue
        tag=0
      end
      tags.include?(tag)
    end

    def weighted_pool_pick_v081(pool,roll=nil)
      pool=pool || []
      return nil if pool.empty?
      total=0
      pool.each{|e|total += [(e[:weight]||1).to_i,1].max}
      r=roll==nil ? rand(total) : roll.to_i%total
      acc=0
      pool.each do |e|
        acc += [(e[:weight]||1).to_i,1].max
        return e if r<acc
      end
      pool[-1]
    end

    def build_enemy_setup_v081(request,seed_rolls=nil)
      return [] if request==nil
      fixed=request[:enemy_setup]
      return fixed.collect{|r|r.dup} if fixed!=nil
      pool=request[:enemy_pool] || []
      count=[(request[:team_size]||3).to_i,1].max
      pos=[[4,1],[5,2],[5,3],[4,2],[5,1],[4,3]]
      out=[]
      for i in 0...count
        rr=seed_rolls==nil ? nil : seed_rolls[i]
        p=weighted_pool_pick_v081(pool,rr)
        next if p==nil
        mn=(p[:min_level]||1).to_i
        mx=[(p[:max_level]||mn).to_i,mn].max
        lv=mn+(mx>mn ? rand(mx-mn+1) : 0)
        xy=pos[i%pos.size]
        out.push([p[:species],xy[0],xy[1],lv,(p[:mods]||{})])
      end
      out
    end

    def recruit_offer_for_request_v081(request,enemy_units=nil,roll=nil,pick=nil)
      return nil if request==nil || !request[:recruitable]
      return nil if request[:kind]==:boss
      chance=(request[:recruit_rate]||0).to_i
      r=roll==nil ? rand(100) : roll.to_i
      return nil if r>=chance
      species=[]
      if enemy_units!=nil
        enemy_units.each{|u|species.push(u.species_key) if u!=nil && !species.include?(u.species_key)}
      end
      if species.empty?
        setup=build_enemy_setup_v081(request,[0,1,2])
        setup.each{|row|species.push(row[0]) unless species.include?(row[0])}
      end
      return nil if species.empty?
      idx=pick==nil ? rand(species.size) : pick.to_i%species.size
      lv=1
      if enemy_units!=nil
        u=enemy_units.find{|x|x.species_key==species[idx]}
        lv=u.level if u!=nil
      end
      {:species=>species[idx],:level=>lv,:chance=>chance,:accepted=>false,
       :encounter=>request[:key],:kind=>request[:kind]}
    end

    def rpg_encounter_manifest_errors_v081
      e=[]
      [:forest_wild,:roadside_pikachu,:boss_beedrill].each do |k|
        d=encounter_data_v081(k)
        e.push('missing_'+k.to_s) if d==nil
      end
      b=encounter_data_v081(:boss_beedrill)
      e.push('boss_recruitable') if b!=nil && b[:recruitable]
      e.push('boss_escape') if b!=nil && b[:can_escape]
      e.uniq
    end
  end
end

class Game_System
  attr_accessor :pmd_autochess_last_result_v081
  attr_accessor :pmd_autochess_wild_maps_v081
end

class Game_Temp
  attr_accessor :pmd_autochess_request_v081
end
