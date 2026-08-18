#==============================================================================
# PMD AutoChess Encounter Config Data v0.84
# RPG 遇敵／敵方等級縮放／精英怪資料設定層
# RPG Maker VX / RGSS2 / Ruby 1.8 compatible
#==============================================================================
# 【這支腳本是做什麼的】
# 把 v0.80～v0.83 已經能運作的 Stage／Wild／Boss／Scripted Battle，整理成
# 「只改資料表就能追加內容」的設定層。一般新增地圖區域、調敵人等級、加入精英怪時，
# 請優先修改本腳本，不要直接去改 Scene_PMD_AutoChess。
#
# 【三層設定概念】
# 1. ENEMY_SCALING_PROFILES_V084：敵人等級怎麼算。
# 2. ELITE_PROFILES_V084：精英怪比普通怪強多少。
# 3. ENCOUNTER_PROFILES_V084：把「敵人池＋縮放＋精英率」綁成可直接使用的區域。
#
#------------------------------------------------------------------------------
# 【A. 敵人等級縮放 ENEMY_SCALING_PROFILES_V084】
# mode 可用：
#   :fixed          = 沿用原 Encounter／Stage 寫死的等級。
#   :party_average  = 以我方出戰三隻的平均 Lv 為基準。
#   :blend          = 原設定 Lv 與我方平均 Lv 取平均，適合不想完全動態化的區域。
#
# offset：算完後額外 + / - 幾級。
# variance：每隻敵人允許上下浮動幾級，例如 1 代表 -1～+1。
# min_level / max_level：最後硬限制，不會超出。
#
# 範例：希望野外敵人約等於我方平均 Lv -1，並在 ±1 內浮動：
#   :my_route=>{
#     :mode=>:party_average, :offset=>-1, :variance=>1,
#     :min_level=>5, :max_level=>30
#   }
#
#------------------------------------------------------------------------------
# 【B. 精英怪 ELITE_PROFILES_V084】
# stat_mult 可調：:hp / :atk / :def / :spatk / :spdef / :speed
# energy_start_bonus：額外增加開場 Energy，不會取代 Boss／原敵人的 energy_start。
# label：戰鬥畫面頭上會顯示的中文標記。
#
# 精英倍率只存在「這一場敵人 Runtime」，若該物種可招募，抓到 BOX 的仍是正常個體；
# 不會把 1.6× HP、1.15× ATK 永久帶回玩家隊伍。
#
# 範例：
#   :my_elite=>{
#     :label=>'菁英',
#     :stat_mult=>{:hp=>1.50,:atk=>1.15,:def=>1.10,
#                  :spatk=>1.15,:spdef=>1.10,:speed=>1.05},
#     :energy_start_bonus=>20
#   }
#
#------------------------------------------------------------------------------
# 【C. Encounter Profile ENCOUNTER_PROFILES_V084】
# source：引用 v0.81 RPG_ENCOUNTER_DB_V081 的 Encounter key。
# scaling：引用上面的 Scaling Profile。
# elite_rate：每個符合資格的敵人有幾 % 變精英。
# elite_profile：使用哪種精英模板。
# elite_max：同一場最多幾隻精英。
# level_floor / level_cap：這個區域額外覆蓋縮放上下限。
# enemy_stat_mult：整場所有敵人額外倍率，可用於困難區域；通常保持 1.0。
#
# 範例呼叫：
#   PMD_AC.start_profile_battle_v084(:forest_adaptive)
#
# 野外地圖啟用：
#   PMD_AC.wild_profile_on_v084(:forest_adaptive, 10, 18)
#   PMD_AC.wild_profile_on_v084(:forest_adaptive, 10, 18, [1,2])
#   PMD_AC.wild_off_v081
#
# 事件臨時覆蓋：
#   PMD_AC.start_profile_battle_v084(:forest_adaptive, {
#     :level_offset=>2,        # 這次額外 +2 Lv
#     :elite_rate=>30,         # 這次精英率改 30%
#     :elite_profile=>:veteran_elite,
#     :reward_table=>:my_reward
#   })
#
#------------------------------------------------------------------------------
# 【D. 舊 API 也能套 Profile】
# 原本 v0.81：
#   PMD_AC.start_battle_v081(:roadside_pikachu)
#
# 現在可直接：
#   PMD_AC.start_battle_v081(:roadside_pikachu, {
#     :encounter_profile=>:roadside_adaptive
#   })
#
# v0.82 自訂戰也可以：
#   PMD_AC.start_custom_battle_v082('山道伏擊', [
#     [:rattata, 12], [:pidgey, 12], [:pikachu, 13]
#   ], {:encounter_profile=>:forest_danger})
#
#------------------------------------------------------------------------------
# 【E. 單一敵人不要變精英／強制精英】
# enemy_setup 的 mods 裡可以寫：
#   {:elite_forbidden=>true}  # 永遠不是精英
#   {:force_elite=>true}      # 強制精英
#   {:elite_profile=>:veteran_elite} # 該敵人指定另一精英模板
#
# Boss（mods[:boss] == true 或 kind == :boss）永遠不會被 v0.84 精英化；
# Boss 請繼續使用 v0.81 的 :stat_mult / :phases / :mechanic。
#
#------------------------------------------------------------------------------
# 【維護原則】
# - instance_uid 才是 Pokémon 個體身份；Actor ID 只是容器。
# - v0.75 戰鬥平衡、v0.76 能力公式、v0.81 Boss Phase 不在本腳本重寫。
# - 新增區域時優先「新增資料」，不要為一片草叢再 alias 一次 Scene。
# - 往後新增 PMD AutoChess 腳本，開頭必須保留同等級的中文說明與範例。
#==============================================================================
module PMD_AC
  ENEMY_SCALING_PROFILES_V084 = {
    :fixed=>{
      :mode=>:fixed,:offset=>0,:variance=>0,:min_level=>1,:max_level=>100
    },
    :party_match=>{
      :mode=>:party_average,:offset=>0,:variance=>1,:min_level=>1,:max_level=>100
    },
    :party_easy=>{
      :mode=>:party_average,:offset=>-2,:variance=>1,:min_level=>1,:max_level=>100
    },
    :party_hard=>{
      :mode=>:party_average,:offset=>2,:variance=>1,:min_level=>1,:max_level=>100
    },
    :soft_scale=>{
      :mode=>:blend,:offset=>0,:variance=>1,:min_level=>1,:max_level=>100
    }
  }

  ELITE_PROFILES_V084 = {
    :standard_elite=>{
      :label=>'精英',
      :stat_mult=>{:hp=>1.50,:atk=>1.12,:def=>1.10,:spatk=>1.12,:spdef=>1.10,:speed=>1.04},
      :energy_start_bonus=>18
    },
    :veteran_elite=>{
      :label=>'強敵',
      :stat_mult=>{:hp=>1.75,:atk=>1.18,:def=>1.15,:spatk=>1.18,:spdef=>1.15,:speed=>1.06},
      :energy_start_bonus=>28
    },
    :swift_elite=>{
      :label=>'迅捷',
      :stat_mult=>{:hp=>1.35,:atk=>1.10,:def=>1.05,:spatk=>1.10,:spdef=>1.05,:speed=>1.14},
      :energy_start_bonus=>22
    }
  }

  ENCOUNTER_PROFILES_V084 = {
    :forest_fixed=>{
      :source=>:forest_wild,
      :scaling=>:fixed,
      :elite_rate=>0,
      :elite_profile=>:standard_elite,
      :elite_max=>0
    },
    :forest_adaptive=>{
      :source=>:forest_wild,
      :scaling=>:party_match,
      :level_floor=>8,
      :level_cap=>22,
      :elite_rate=>10,
      :elite_profile=>:standard_elite,
      :elite_max=>1
    },
    :forest_danger=>{
      :source=>:forest_wild,
      :scaling=>:party_hard,
      :level_floor=>10,
      :level_cap=>30,
      :elite_rate=>25,
      :elite_profile=>:veteran_elite,
      :elite_max=>2,
      :enemy_stat_mult=>{:hp=>1.08,:atk=>1.05,:def=>1.03,:spatk=>1.05,:spdef=>1.03,:speed=>1.00}
    },
    :roadside_adaptive=>{
      :source=>:roadside_pikachu,
      :scaling=>:soft_scale,
      :level_floor=>10,
      :level_cap=>28,
      :elite_rate=>0,
      :elite_profile=>:standard_elite,
      :elite_max=>0
    }
  }

  ENCOUNTER_CONFIG_VERIFY_END_V084 = 24
  ENCOUNTER_CONFIG_MANIFEST_V084 = {
    :schema_version=>'1.0',
    :content_version=>'0.84.0',
    :scaling_profiles=>ENEMY_SCALING_PROFILES_V084.size,
    :elite_profiles=>ELITE_PROFILES_V084.size,
    :encounter_profiles=>ENCOUNTER_PROFILES_V084.size,
    :boss_elite=>false,
    :recruit_keeps_elite_mods=>false,
    :base_encounter=>'v0.81',
    :field_runtime=>'v0.82',
    :reward_loot=>'v0.83',
    :runtime_checksum32=>1840842601
  }

  class << self
    def scaling_profile_v084(key)
      ENEMY_SCALING_PROFILES_V084[key] || ENEMY_SCALING_PROFILES_V084[:fixed]
    end

    def elite_profile_v084(key)
      ELITE_PROFILES_V084[key] || ELITE_PROFILES_V084[:standard_elite]
    end

    def encounter_profile_v084(key)
      ENCOUNTER_PROFILES_V084[key]
    end

    def party_average_level_v084
      list=[]
      if respond_to?(:party_instances_v078)
        for inst in party_instances_v078
          list.push(inst.level.to_i) if inst!=nil
        end
      else
        for i in 0...PARTY_CAPACITY_V045
          inst=party_instance_v045(i)
          list.push(inst.level.to_i) if inst!=nil
        end
      end
      return POKEMON_DEFAULT_LEVEL.to_i if list.empty?
      sum=0
      list.each{|lv|sum+=lv.to_i}
      [(sum.to_f/list.size.to_f).round,1].max
    end

    def clamp_level_v084(level,min_level,max_level)
      mn=[min_level.to_i,1].max
      mx=[max_level.to_i,mn].max
      lv=level.to_i
      lv=mn if lv<mn
      lv=mx if lv>mx
      lv
    end

    def scaled_enemy_level_v084(base_level,request,slot_index=0,variance_roll=nil)
      return [base_level.to_i,1].max if request==nil
      key=request[:scaling_profile_v084] || request[:scaling_profile] || :fixed
      p=scaling_profile_v084(key)
      mode=p[:mode] || :fixed
      avg=party_average_level_v084
      base=[base_level.to_i,1].max
      lv=base
      case mode
      when :party_average
        lv=avg
      when :blend
        lv=((base.to_f+avg.to_f)/2.0).round
      else
        lv=base
      end
      lv += (p[:offset]||0).to_i
      lv += (request[:level_offset_v084]||0).to_i
      variance=[(p[:variance]||0).to_i,0].max
      if variance>0
        if variance_roll==nil
          lv += rand(variance*2+1)-variance
        else
          lv += variance_roll.to_i%(variance*2+1)-variance
        end
      end
      mn=request[:level_floor_v084]
      mx=request[:level_cap_v084]
      mn=p[:min_level] if mn==nil
      mx=p[:max_level] if mx==nil
      clamp_level_v084(lv,mn||1,mx||100)
    end

    def merge_stat_mult_v084(base,extra)
      out={}
      keys=[:hp,:atk,:def,:spatk,:spdef,:speed]
      for k in keys
        a=base==nil ? 1.0 : (base[k]||1.0).to_f
        b=extra==nil ? 1.0 : (extra[k]||1.0).to_f
        out[k]=a*b
      end
      out
    end

    def dup_enemy_mods_v084(mods)
      src=mods.is_a?(Hash) ? mods : {}
      out=src.dup
      out[:stat_mult]=src[:stat_mult].dup if src[:stat_mult].is_a?(Hash)
      out[:active_moves]=src[:active_moves].dup if src[:active_moves].is_a?(Array)
      out[:phases]=src[:phases].collect{|x|x.is_a?(Hash) ? x.dup : x} if src[:phases].is_a?(Array)
      out
    end

    def elite_eligible_v084?(request,mods)
      return false if request==nil
      return false if request[:kind]==:boss || request[:boss]
      return false if mods!=nil && (mods[:boss] || mods[:elite_forbidden])
      true
    end

    def apply_elite_profile_v084(mods,profile_key)
      out=dup_enemy_mods_v084(mods)
      p=elite_profile_v084(profile_key)
      out[:elite_v084]=true
      out[:elite_profile_v084]=profile_key
      out[:elite_label_v084]=(p[:label]||'精英').to_s
      out[:stat_mult]=merge_stat_mult_v084(out[:stat_mult],p[:stat_mult])
      out[:energy_start]=(out[:energy_start]||0).to_i+(p[:energy_start_bonus]||0).to_i
      out
    end

    def encounter_profile_options_v084(profile_key,options=nil)
      p=encounter_profile_v084(profile_key)
      return nil if p==nil
      o=options==nil ? {} : options.dup
      {
        :profile_key=>profile_key,
        :source=>p[:source],
        :scaling=>(o[:scaling_profile]||p[:scaling]||:fixed),
        :level_floor=>(o.has_key?(:level_floor) ? o[:level_floor] : p[:level_floor]),
        :level_cap=>(o.has_key?(:level_cap) ? o[:level_cap] : p[:level_cap]),
        :level_offset=>(o[:level_offset]||0).to_i,
        :elite_rate=>(o.has_key?(:elite_rate) ? o[:elite_rate] : (p[:elite_rate]||0)).to_i,
        :elite_profile=>(o[:elite_profile]||p[:elite_profile]||:standard_elite),
        :elite_max=>(o.has_key?(:elite_max) ? o[:elite_max] : (p[:elite_max]||0)).to_i,
        :enemy_stat_mult=>(o[:enemy_stat_mult]||p[:enemy_stat_mult]),
        :options=>o
      }
    end

    def apply_profile_to_request_v084(request,profile_key,options=nil)
      return request if request==nil
      cfg=encounter_profile_options_v084(profile_key,options)
      return request if cfg==nil
      r=request.dup
      o=r[:options].is_a?(Hash) ? r[:options].dup : {}
      extra=cfg[:options] || {}
      extra.each{|k,v|o[k]=v}
      r[:options]=o
      r[:encounter_profile_v084]=profile_key
      r[:scaling_profile_v084]=cfg[:scaling]
      r[:level_floor_v084]=cfg[:level_floor]
      r[:level_cap_v084]=cfg[:level_cap]
      r[:level_offset_v084]=cfg[:level_offset]
      r[:elite_rate_v084]=cfg[:elite_rate]
      r[:elite_profile_v084]=cfg[:elite_profile]
      r[:elite_max_v084]=cfg[:elite_max]
      r[:enemy_stat_mult_v084]=cfg[:enemy_stat_mult]
      r[:recruit_rate]=extra[:recruit_rate].to_i if extra.has_key?(:recruit_rate)
      r[:recruitable]=extra[:recruitable] ? true : false if extra.has_key?(:recruitable)
      r[:can_escape]=extra[:can_escape] ? true : false if extra.has_key?(:can_escape)
      r[:deploy]=extra[:deploy] ? true : false if extra.has_key?(:deploy)
      r[:weather]=extra[:weather] if extra.has_key?(:weather)
      r
    end

    def start_profile_battle_v084(profile_key,options=nil)
      p=encounter_profile_v084(profile_key)
      return false if p==nil
      source=p[:source]
      return false if source==nil
      r=make_battle_request_v081(source,options)
      return false if r==nil
      r=apply_profile_to_request_v084(r,profile_key,options)
      return false if respond_to?(:once_switch_blocked_v082?) && once_switch_blocked_v082?(r)
      launch_battle_request_v081(r)
    end

    def wild_profile_config_v084(profile_key,min_steps=10,max_steps=18,terrain_tags=nil)
      p=encounter_profile_v084(profile_key)
      return nil if p==nil || p[:source]==nil
      mn=[min_steps.to_i,1].max
      mx=[max_steps.to_i,mn].max
      tags=terrain_tags==nil ? [] : terrain_tags.collect{|x|x.to_i}
      {:encounter=>p[:source],:profile=>profile_key,:min_steps=>mn,:max_steps=>mx,:terrain_tags=>tags}
    end

    def wild_profile_on_v084(profile_key,min_steps=10,max_steps=18,terrain_tags=nil,map_id=nil)
      cfg=wild_profile_config_v084(profile_key,min_steps,max_steps,terrain_tags)
      return false if cfg==nil
      mid=map_id==nil ? ($game_map==nil ? 0 : $game_map.map_id) : map_id.to_i
      return false if mid<=0
      wild_runtime_maps_v081[mid]=cfg
      if $game_player!=nil && $game_player.respond_to?(:make_pmd_encounter_count_v081)
        $game_player.make_pmd_encounter_count_v081(cfg[:min_steps],cfg[:max_steps])
      end
      true
    end

    def encounter_config_errors_v084
      e=[]
      ENEMY_SCALING_PROFILES_V084.each do |k,p|
        e.push('scaling_mode_'+k.to_s) unless [:fixed,:party_average,:blend].include?(p[:mode])
      end
      ELITE_PROFILES_V084.each do |k,p|
        e.push('elite_stat_'+k.to_s) unless p[:stat_mult].is_a?(Hash)
      end
      ENCOUNTER_PROFILES_V084.each do |k,p|
        e.push('profile_source_'+k.to_s) if p[:source]==nil || encounter_data_v081(p[:source])==nil
        e.push('profile_scaling_'+k.to_s) if ENEMY_SCALING_PROFILES_V084[p[:scaling]]==nil
        e.push('profile_elite_'+k.to_s) if ELITE_PROFILES_V084[p[:elite_profile]]==nil
      end
      e.uniq
    end
  end
end
