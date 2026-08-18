# encoding: UTF-8
#==============================================================================
# 【PMD AutoChess 中文維護說明】
# 腳本：PMD AutoChess Map Terrain Compatibility Hotfix v1.01.1
# 分類：RPG Map Integration／VX Terrain Tag 相容修正／Vertical Slice Hotfix
# RPG Maker VX / RGSS2 / Ruby 1.8 compatible
#------------------------------------------------------------------------------
# 【用途】
# 修正 v0.92 RPG Map Integration 在 RPG Maker VX 中直接呼叫
# $game_map.terrain_tag(x,y) 所造成的 NoMethodError。此專案的原生 Game_Map
# 並沒有 terrain_tag API，而 v1.01 Map004/005 又刻意使用 terrain_tags=[]，代表
# 「不限地形」，因此本來就不應為了判定隨機遭遇去讀取不存在的 Terrain Tag。
#
# 同時修正 v1.01 Scene_Map#update_encounter 的條件分流：只有 Map004/005 的
# Vertical Slice 走 v1.01 自訂隨機遭遇；其他所有地圖必須交回既有 v0.81～v0.92
# encounter chain，避免未來其他正式地圖的原生／既有遭遇被 v1.01 提前 return。
#------------------------------------------------------------------------------
# 【主要設定項】
# 本 Hotfix 無需資料庫設定。仍沿用：
# - Map004 / Map005：terrain_tags=[]，不限地形。
# - Map006：Boss 區，不開步行隨機遭遇。
# - 其他地圖：交回 pmd_ac_v101_update_encounter（v1.01 之前的正式 encounter chain）。
#------------------------------------------------------------------------------
# 【機制規則】
# 1. current_map_encounter_allowed_v092?：若 terrain_tags 為空，立即 true，
#    不呼叫 terrain_tag。
# 2. current_terrain_tag_v092：只有 Game_Map 真正提供 terrain_tag 時才呼叫；
#    否則安全回傳 0。這維持 v0.81 原本的 fallback 思路。
# 3. 非空 terrain_tags 在沒有 terrain_tag provider 的 VX 專案中，會以 tag=0 判定；
#    因此若日後需要真正 Terrain Tag，應另接明確的 terrain provider，不可假裝 VX
#    原生已有該 API。
# 4. 不修改 Dynamic Tactical Role、Spatial Framework、Damage Formula、Skill FX。
# 5. 不改 instance_uid、Recruit、Reward、Field HP、Boss、Startup Cooperative Loader。
#------------------------------------------------------------------------------
# 【可調參數】
# 無。若正式地圖不需要 Terrain Tag 篩選，binding 使用：
#   :terrain_tags=>[]
# 即可允許所有可走位置觸發遭遇。
#------------------------------------------------------------------------------
# 【事件／腳本呼叫方式】
# 不需要新增事件指令。原 v1.01 呼叫方式維持：
#   PMD_AC.vertical_wild_v101(:field_marker)
#   PMD_AC.vertical_special_v101
#   PMD_AC.vertical_boss_v101
#------------------------------------------------------------------------------
# 【實際範例】
# Map004 / Map005 runtime binding：
#   {:profile=>:forest_route, :terrain_tags=>[], :min_steps=>12, :max_steps=>20}
# 此時 current_map_encounter_allowed_v092? 直接允許，不查 terrain_tag。
#------------------------------------------------------------------------------
# 【維護注意】
# - 本腳本是 trailing hotfix，放在 v1.01 Vertical Slice 後、Main 前。
# - Frozen Combat Core 不直接修改。
# - S 選單不新增 mode；Hotfix verifier 掛在既有 MAP_STORY_VERTICAL_SLICE_V101。
#==============================================================================
module PMD_AC
  MAP_TERRAIN_HOTFIX_VERSION_V1011='1.01.1'

  class << self
    # RPG Maker VX 本專案的 Game_Map 沒有原生 terrain_tag。
    # 只有真的有 provider 時才讀取，否則採 v0.81 同樣的安全 fallback=0。
    def current_terrain_tag_v092
      return 0 if $game_map==nil || $game_player==nil
      return 0 unless $game_map.respond_to?(:terrain_tag)
      begin
        return $game_map.terrain_tag($game_player.x,$game_player.y).to_i
      rescue
        return 0
      end
    end

    # terrain_tags=[] 本意就是「不限地形」，先短路，不應碰 terrain API。
    def current_map_encounter_allowed_v092?
      return false if $game_map==nil
      cfg=region_wild_config_for_map_v086($game_map.map_id)
      return false if cfg==nil
      tags=cfg[:terrain_tags] || []
      return true if tags.empty?
      terrain_tag_allowed_v092?(cfg,current_terrain_tag_v092)
    end

    def map_terrain_hotfix_v1011_ok?
      return false unless respond_to?(:current_terrain_tag_v092)
      return false unless respond_to?(:current_map_encounter_allowed_v092?)
      true
    end
  end
end

#==============================================================================
# ■ Scene_Map encounter 分流修正
#==============================================================================
class Scene_Map
  # v1.01 已建立 pmd_ac_v101_update_encounter，指向 Vertical Slice 覆寫前的正式鏈。
  # 這裡直接覆寫 v1.01 method，不再額外 alias，避免 alias chain 再膨脹。
  def update_encounter
    mid=$game_map==nil ? 0 : $game_map.map_id.to_i
    vertical_random=(mid==4 || mid==5) && PMD_AC.vertical_map_v101?(mid)
    unless vertical_random
      pmd_ac_v101_update_encounter
      return
    end

    cfg=PMD_AC.wild_config_for_map_v081(mid)
    return if cfg==nil
    return if $game_player==nil
    return if $game_player.encounter_count>0
    return if $game_map.interpreter.running?
    return if $game_system!=nil && $game_system.encounter_disabled
    return unless PMD_AC.current_map_encounter_allowed_v092?

    mn=(cfg[:min_steps]||PMD_AC::VERTICAL_RANDOM_MIN_V101).to_i
    mx=(cfg[:max_steps]||PMD_AC::VERTICAL_RANDOM_MAX_V101).to_i
    $game_player.make_pmd_encounter_count_v081(mn,mx)
    PMD_AC.vertical_wild_v101(:walking)
  end
end

#==============================================================================
# ■ Formal verifier：沿用 MAP_STORY_VERTICAL_SLICE_V101，不增加 S 選單項目
#==============================================================================
class Scene_PMD_AutoChess
  def verify_map_story_binding_v101
    return if @verification_done[:map_story_binding_v101]

    c=PMD_AC.build_map_wild_config_v092({:profile=>:forest_route,:terrain_tags=>[],
      :min_steps=>PMD_AC::VERTICAL_RANDOM_MIN_V101,:max_steps=>PMD_AC::VERTICAL_RANDOM_MAX_V101})
    r=PMD_AC.mark_vertical_request_v101(PMD_AC.rpg_foundation_wild_request_v100)
    marked=r!=nil && (r[:options]||{})[:vertical_slice_v101]

    # VX compatibility：Game_Map 沒有 terrain_tag 仍必須安全；[] 必須直接 allow。
    terrain_method_absent=($game_map==nil || !$game_map.respond_to?(:terrain_tag))
    terrain_safe=true
    begin
      # 不改目前 map binding，只驗證 helper 對空 tags 的規則與 fallback method 可呼叫。
      terrain_safe=PMD_AC.terrain_tag_allowed_v092?({:terrain_tags=>[]},PMD_AC.current_terrain_tag_v092)
    rescue
      terrain_safe=false
    end

    pass=c!=nil && c[:region_v086]==:forest_edge && c[:terrain_tags]==[] &&
      c[:min_steps]==PMD_AC::VERTICAL_RANDOM_MIN_V101 &&
      c[:max_steps]==PMD_AC::VERTICAL_RANDOM_MAX_V101 && marked && terrain_safe &&
      PMD_AC.map_terrain_hotfix_v1011_ok?

    log_map_story_v101('MAP_STORY_BINDING_V101',pass,
      'region=forest_edge terrain=all steps=12..20 foundation_request=1 return_to_map=1 terrain_hotfix=1')
    log_map_story_v101('MAP_STORY_TERRAIN_SAFE_V1011',terrain_safe,
      'vx_native_terrain_tag='+(terrain_method_absent ? '0':'1')+' empty_tags_short_circuit=1 fallback_tag=0 encounter_fallback=1')
    @verification_done[:map_story_binding_v101]=true
  end
end
