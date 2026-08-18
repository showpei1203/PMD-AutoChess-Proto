#==============================================================================
# 【PMD AutoChess 中文維護說明】
# 腳本：PMD AutoChess RPG Field Data v0.82
# 分類：RPG 地圖持續狀態
#
# 【用途／機制】
# 處理跨戰 HP、治療、檢查點、戰敗政策、一次性事件與自訂戰鬥。
#
# 【怎麼調整】
# 事件範例：PMD_AC.heal_party_v082；自訂戰：PMD_AC.start_custom_battle_v082('伏
# 擊',[[:rattata,15]])。
#
# 【本腳本主要設定常數／資料表】
# - RPG_FIELD_DEFAULT_HP_POLICY_V082 / RPG_FIELD_DEFAULT_DEFEAT_POLICY_V082 / RPG_FIELD_VERIFY_END_V082 / RPG_FIELD_MANIFEST_V082
#
# 【Runtime 主要方法（查流程時可直接搜尋）】
# - owned_instances_v082 / party_instances_v082 / heal_party_v082 / heal_all_owned_v082
# - encounter_hp_policy_v082 / encounter_defeat_policy_v082 / encounter_heal_after_v082 / apply_field_hp_to_unit_v082
# - sync_field_hp_from_unit_v082 / set_checkpoint_v082 / checkpoint_v082 / clear_checkpoint_v082
#
# 【維護規則】
# - RPG Maker VX / RGSS2 / Ruby 1.8 相容。
# - instance_uid 才是 Pokémon 個體身份；Actor ID 只是容器。
# - 新增行為優先沿用既有 helper／Data 表；避免破壞已 Freeze 的舊核心。
# - 本專案新腳本也必須保留同等級的中文說明與實際範例。
#==============================================================================
#==============================================================================
# PMD AutoChess RPG Field Runtime Data v0.82
# RGSS2 / Ruby 1.8 compatible
#------------------------------------------------------------------------------
# Extends v0.81 RPG Encounter Bridge without replacing Stage / Wild / Boss /
# Scripted definitions.
#
# Core field-RPG calls:
#   PMD_AC.heal_party_v082
#   PMD_AC.heal_all_owned_v082
#   PMD_AC.set_checkpoint_v082
#
# Direct temporary battle (no DB entry required):
#   PMD_AC.start_custom_battle_v082('路邊伏擊', [
#     [:rattata, 14],
#     [:pidgey, 15],
#     [:pikachu, 16]
#   ])
#
# Custom Boss battle:
#   PMD_AC.start_boss_battle_v082('古樹守衛', [
#     [:beedrill,5,2,20,{
#       :boss=>true,
#       :stat_mult=>{:hp=>2.5,:atk=>1.2},
#       :energy_start=>50
#     }]
#   ], {:defeat_policy=>:checkpoint})
#
# Request options recognized by v0.82:
#   :hp_policy       => :carry / :full
#   :defeat_policy   => :return_heal / :return_map / :checkpoint / :gameover
#   :heal_after_win  => true / false
#   :heal_after_escape=>true / false
#   :once_switch     => switch id (battle will not launch again after a win)
#   :win_common_event / :lose_common_event / :escape_common_event => event id
#==============================================================================
module PMD_AC
  RPG_FIELD_DEFAULT_HP_POLICY_V082 = {
    :stage=>:full,
    :wild=>:carry,
    :boss=>:carry,
    :scripted=>:carry
  }

  RPG_FIELD_DEFAULT_DEFEAT_POLICY_V082 = {
    :stage=>:return_map,
    :wild=>:return_heal,
    :boss=>:return_heal,
    :scripted=>:return_heal
  }

  RPG_FIELD_VERIFY_END_V082 = 24

  RPG_FIELD_MANIFEST_V082 = {
    :schema_version=>'1.0',
    :content_version=>'0.82.0',
    :hp_persistence=>true,
    :hp_contexts=>[:wild,:boss,:scripted],
    :stage_default_hp=>:full,
    :heal_party_api=>true,
    :heal_all_owned_api=>true,
    :checkpoint=>true,
    :defeat_policies=>[:return_heal,:return_map,:checkpoint,:gameover],
    :result_common_event=>true,
    :once_switch=>true,
    :custom_battle_api=>true,
    :custom_boss_api=>true,
    :boss_recruitable=>false,
    :carry=>'v0.81 RPG Encounter Bridge',
    :runtime_checksum32=>180822904
  }

  class << self
    def owned_instances_v082
      uids=[]
      for uid in pokemon_party_uids_v045
        uids.push(uid.to_i) if uid!=nil && uid.to_i>0 && !uids.include?(uid.to_i)
      end
      for box in pokemon_storage_boxes_v045
        for uid in box
          uids.push(uid.to_i) if uid!=nil && uid.to_i>0 && !uids.include?(uid.to_i)
        end
      end
      out=[]
      for uid in uids
        inst=pokemon_instance_for_uid_v045(uid)
        out.push(inst) if inst!=nil
      end
      out
    end

    def party_instances_v082
      out=[]
      for i in 0...PARTY_CAPACITY_V045
        inst=party_instance_v045(i)
        out.push(inst) if inst!=nil
      end
      out
    end

    def heal_party_v082
      count=0
      for inst in party_instances_v082
        next unless inst.respond_to?(:heal_field_hp_v082)
        inst.heal_field_hp_v082
        count+=1
      end
      count
    end

    def heal_all_owned_v082
      count=0
      for inst in owned_instances_v082
        next unless inst.respond_to?(:heal_field_hp_v082)
        inst.heal_field_hp_v082
        count+=1
      end
      count
    end

    def encounter_hp_policy_v082(request)
      return :full if request==nil
      o=request[:options] || {}
      p=o[:hp_policy]
      p=request[:hp_policy] if p==nil
      p=RPG_FIELD_DEFAULT_HP_POLICY_V082[request[:kind]] if p==nil
      p=:full unless [:carry,:full].include?(p)
      p
    end

    def encounter_defeat_policy_v082(request)
      return :return_heal if request==nil
      o=request[:options] || {}
      p=o[:defeat_policy]
      p=request[:defeat_policy] if p==nil
      p=RPG_FIELD_DEFAULT_DEFEAT_POLICY_V082[request[:kind]] if p==nil
      valid=RPG_FIELD_MANIFEST_V082[:defeat_policies]
      p=:return_heal unless valid.include?(p)
      p
    end

    def encounter_heal_after_v082(request,result)
      return false if request==nil
      o=request[:options] || {}
      return o[:heal_after_win] ? true : false if result==:win
      return o[:heal_after_escape] ? true : false if result==:escape
      false
    end

    def apply_field_hp_to_unit_v082(unit,request)
      return false if unit==nil || unit.team!=:ally
      return false unless unit.respond_to?(:pokemon_instance)
      inst=unit.pokemon_instance
      return false if inst==nil || !inst.respond_to?(:field_hp_v082)
      policy=encounter_hp_policy_v082(request)
      hp=policy==:carry ? inst.field_hp_v082 : unit.maxhp
      unit.set_current_hp_v082(hp) if unit.respond_to?(:set_current_hp_v082)
      true
    end

    def sync_field_hp_from_unit_v082(unit,request)
      return false if unit==nil || unit.team!=:ally
      return false unless encounter_hp_policy_v082(request)==:carry
      return false unless unit.respond_to?(:pokemon_instance)
      inst=unit.pokemon_instance
      return false if inst==nil || !inst.respond_to?(:set_field_hp_v082)
      inst.set_field_hp_v082(unit.hp)
      true
    end

    def set_checkpoint_v082(map_id=nil,x=nil,y=nil,direction=nil)
      return false if $game_system==nil || $game_map==nil || $game_player==nil
      mid=map_id==nil ? $game_map.map_id.to_i : map_id.to_i
      px=x==nil ? $game_player.x.to_i : x.to_i
      py=y==nil ? $game_player.y.to_i : y.to_i
      dir=direction==nil ? $game_player.direction.to_i : direction.to_i
      return false if mid<=0
      $game_system.pmd_autochess_checkpoint_v082={
        :map_id=>mid,:x=>px,:y=>py,:direction=>dir
      }
      true
    end

    def checkpoint_v082
      return nil if $game_system==nil
      $game_system.pmd_autochess_checkpoint_v082
    end

    def clear_checkpoint_v082
      return false if $game_system==nil
      $game_system.pmd_autochess_checkpoint_v082=nil
      true
    end

    def once_switch_blocked_v082?(request)
      return false if request==nil || $game_switches==nil
      o=request[:options] || {}
      sid=o[:once_switch].to_i
      sid>0 && $game_switches[sid]
    end

    def mark_once_switch_v082(request,result)
      return false if request==nil || result!=:win || $game_switches==nil
      o=request[:options] || {}
      sid=o[:once_switch].to_i
      return false if sid<=0
      $game_switches[sid]=true
      true
    end

    def reserve_result_common_event_v082(request,result)
      return 0 if request==nil || $game_temp==nil
      o=request[:options] || {}
      key=result==:win ? :win_common_event : (result==:lose ? :lose_common_event : :escape_common_event)
      cid=o[key].to_i
      return 0 if cid<=0
      $game_temp.common_event_id=cid
      cid
    end

    def normalize_enemy_setup_v082(rows)
      rows=[] if rows==nil
      positions=[[4,1],[5,2],[5,3],[4,2],[5,1],[4,3]]
      out=[]
      rows.each_with_index do |row,i|
        if row.is_a?(Hash)
          sp=row[:species]
          lv=(row[:level]||POKEMON_DEFAULT_LEVEL).to_i
          cell=row[:cell] || positions[i%positions.size]
          mods=row[:mods] || {}
          out.push([sp,cell[0].to_i,cell[1].to_i,lv,mods]) if sp!=nil
        elsif row.is_a?(Array)
          if row.size==2
            cell=positions[i%positions.size]
            out.push([row[0],cell[0],cell[1],row[1].to_i,{}])
          elsif row.size==3 && row[2].is_a?(Hash)
            cell=positions[i%positions.size]
            out.push([row[0],cell[0],cell[1],row[1].to_i,row[2]])
          elsif row.size>=4
            mods=row[4].is_a?(Hash) ? row[4] : {}
            out.push([row[0],row[1].to_i,row[2].to_i,row[3].to_i,mods])
          end
        end
      end
      out
    end

    def custom_battle_request_v082(name,enemy_setup,options=nil)
      o=options==nil ? {} : options.dup
      kind=o[:kind] || :scripted
      kind=:scripted unless [:wild,:boss,:scripted].include?(kind)
      boss=(kind==:boss)
      recruitable=boss ? false : (o.has_key?(:recruitable) ? (o[:recruitable] ? true : false) : false)
      recruit_rate=recruitable ? (o[:recruit_rate]||0).to_i : 0
      can_escape=boss ? (o.has_key?(:can_escape) ? (o[:can_escape] ? true : false) : false) :
        (o.has_key?(:can_escape) ? (o[:can_escape] ? true : false) : true)
      {
        :key=>:custom_v082,
        :name=>name.to_s,
        :kind=>kind,
        :enemy_setup=>normalize_enemy_setup_v082(enemy_setup),
        :weather=>o[:weather],
        :recruitable=>recruitable,
        :recruit_rate=>recruit_rate,
        :can_escape=>can_escape,
        :deploy=>o.has_key?(:deploy) ? (o[:deploy] ? true : false) : true,
        :boss=>boss,
        :source=>:script,
        :hp_policy=>o[:hp_policy],
        :defeat_policy=>o[:defeat_policy],
        :options=>o
      }
    end

    def start_custom_battle_v082(name,enemy_setup,options=nil)
      r=custom_battle_request_v082(name,enemy_setup,options)
      return false if r[:enemy_setup].empty?
      return false if once_switch_blocked_v082?(r)
      launch_battle_request_v081(r)
    end

    def start_boss_battle_v082(name,enemy_setup,options=nil)
      o=options==nil ? {} : options.dup
      o[:kind]=:boss
      o[:recruitable]=false
      o[:recruit_rate]=0
      start_custom_battle_v082(name,enemy_setup,o)
    end

    def launch_rpg_request_guard_v082(request)
      return false if request==nil
      return false if once_switch_blocked_v082?(request)
      true
    end
  end
end

class Game_System
  attr_accessor :pmd_autochess_checkpoint_v082
end

class PMD_PokemonInstance
  def field_maxhp_v082
    s=combat_stats
    [(s[:hp]||1).to_i,1].max
  end

  def ensure_field_hp_v082
    max=field_maxhp_v082
    @field_hp_v082=max if @field_hp_v082==nil
    @field_hp_v082=[[@field_hp_v082.to_i,0].max,max].min
    @field_hp_v082
  end

  def field_hp_v082
    ensure_field_hp_v082
  end

  def field_hp_rate_v082
    field_hp_v082.to_f/field_maxhp_v082.to_f
  end

  def field_fainted_v082?
    field_hp_v082<=0
  end

  def set_field_hp_v082(value)
    max=field_maxhp_v082
    @field_hp_v082=[[value.to_i,0].max,max].min
    @field_hp_v082
  end

  def heal_field_hp_v082
    @field_hp_v082=field_maxhp_v082
  end
end
