#==============================================================================
# 【PMD AutoChess 中文維護說明】
# 腳本：PMD AutoChess RPG Map Integration Data v0.92
# 分類：RPG 地圖事件整合／標準模板資料
#
# 【用途】
# 把 v0.81～v0.91 已完成的 Encounter、Region Ecology、Unlock、Field HP、
# Checkpoint、Reward、Boss Framework 等功能，整理成 RPG Maker VX 地圖事件可直接
# 使用的統一入口。這支腳本只放「地圖模板資料與純資料 helper」，實際 Scene／事件
# 呼叫 Runtime 在下一支 v0.92 Runtime 腳本。
#
# 【主要設定項】
# 1. MAP_PROFILES_V092：地圖野生遭遇模板。
#    - :region       對應 v0.86 Region key。
#    - :min_steps    最少步數。
#    - :max_steps    最多步數。
#    - :terrain_tags 允許觸發野生戰的 Terrain Tag；[] 表示不限。
#    - :condition    可使用 v0.87 Condition Spec；nil 表示無額外限制。
# 2. MAP_BINDINGS_V092：正式地圖 ID → Profile 的靜態綁定表。
#    預設刻意保持空白，避免測試專案 Map001 自動開始野生遭遇。
#
# 【機制規則】
# - Region Formation／Rare／Elite／Unlock 全部沿用 v0.84～v0.87，不在此重算。
# - Terrain Tag 只決定「這一步能不能觸發遭遇」，不改編成內容。
# - 靜態 MAP_BINDINGS 與 Runtime bind_map_v092 可並存；Runtime 綁定優先。
# - 本層不修改 v0.15 Movement、v0.60.2 Damage Packet、v0.91.4 Tactical Passive。
#
# 【可調參數】
# 可直接新增 MAP_PROFILES_V092。例如：
#   :my_forest=>{
#     :name=>'我的森林', :region=>:forest_edge,
#     :min_steps=>8, :max_steps=>14, :terrain_tags=>[1,2], :condition=>nil
#   }
# 再把正式地圖綁定：
#   MAP_BINDINGS_V092 = { 12=>{:profile=>:my_forest} }
#
# 【事件／腳本呼叫方式】
# Runtime 腳本提供：
#   PMD_AC.bind_map_v092(:forest_route)          # 目前地圖啟用林緣野生遭遇
#   PMD_AC.unbind_map_v092                       # 目前地圖取消 v0.92 綁定
#   PMD_AC.checkpoint_here_v092                  # 把目前位置設為檢查點
#   PMD_AC.heal_party_here_v092                  # 回復目前 3 隻隊伍
#   PMD_AC.event_battle_v092(:roadside_pikachu) # 固定事件戰
#   PMD_AC.event_region_v092(:forest_edge)       # 依 Region 抽 Formation
#   PMD_AC.event_boss_v092(:boss_beedrill)       # Boss Framework II
#
# 【實際事件範例】
# 事件頁「腳本」：
#   PMD_AC.event_boss_v092(:boss_beedrill,
#     {:once_switch=>81, :defeat_policy=>:checkpoint,
#      :result_variable=>21, :win_common_event=>12})
# 回到地圖後變數 21：1=勝、2=敗、3=逃；Boss 本身仍不可逃跑，所以通常只有 1/2。
#
# 【注意事項】
# - RPG Maker VX / RGSS2 / Ruby 1.8 相容。
# - instance_uid 才是 Pokémon 個體身份；Actor ID 只是容器。
# - Game.ini 禁止 UTF-8 BOM。
# - 不要在此新增另一套傷害／招募／Rare／Elite 規則，必須沿用既有 Runtime。
#==============================================================================
module PMD_AC
  MAP_INTEGRATION_VERSION_V092 = '0.92'

  MAP_PROFILES_V092 = {
    :forest_route=>{
      :name=>'林緣道路',
      :region=>:forest_edge,
      :min_steps=>10,
      :max_steps=>18,
      :terrain_tags=>[1,2],
      :condition=>nil
    },
    :poison_route=>{
      :name=>'毒針林道路',
      :region=>:poison_grove,
      :min_steps=>8,
      :max_steps=>14,
      :terrain_tags=>[1,2],
      :condition=>nil
    },
    :thunder_route=>{
      :name=>'雷羽坡道路',
      :region=>:thunder_slope,
      :min_steps=>8,
      :max_steps=>14,
      :terrain_tags=>[1,2,3],
      :condition=>nil
    }
  }

  # 正式專案在這裡填 Map ID。測試專案預設空白，避免 Map001 自動遇敵。
  # 例：12=>{:profile=>:forest_route}
  MAP_BINDINGS_V092 = {
  }

  MAP_INTEGRATION_VERIFY_END_V092 = 30

  MAP_INTEGRATION_MANIFEST_V092 = {
    :schema_version=>'1.0',
    :content_version=>'0.92.0',
    :profiles=>MAP_PROFILES_V092.size,
    :static_bindings=>MAP_BINDINGS_V092.size,
    :region_runtime=>'v0.86-v0.87',
    :terrain_runtime=>'v0.81',
    :field_hp=>'v0.82',
    :reward=>'v0.83',
    :boss=>'v0.91',
    :tactical=>'v0.91.4',
    :event_api=>true,
    :runtime_binding=>true,
    :result_bridge=>true,
    :checkpoint=>true,
    :heal=>true,
    :runtime_checksum32=>920920314
  }

  class << self
    def map_profile_v092(key)
      MAP_PROFILES_V092[key]
    end

    def static_map_binding_v092(map_id)
      MAP_BINDINGS_V092[map_id.to_i]
    end

    def map_profile_options_v092(profile_key,options=nil)
      p=map_profile_v092(profile_key)
      return nil if p==nil
      o=options==nil ? {} : options.dup
      out=p.dup
      o.each_pair{|k,v| out[k]=v }
      out[:profile]=profile_key
      out
    end

    def terrain_tag_allowed_v092?(config,tag)
      return false if config==nil
      tags=config[:terrain_tags] || []
      return true if tags.empty?
      tags.collect{|x|x.to_i}.include?(tag.to_i)
    end

    def map_profile_errors_v092
      errors=[]
      MAP_PROFILES_V092.each_pair do |key,row|
        if row==nil || !row.is_a?(Hash)
          errors.push('profile_'+key.to_s)
          next
        end
        region=row[:region]
        errors.push('region_'+key.to_s) if region==nil || region_data_v086(region)==nil
        mn=(row[:min_steps]||0).to_i
        mx=(row[:max_steps]||0).to_i
        errors.push('steps_'+key.to_s) if mn<=0 || mx<mn
        errors.push('terrain_'+key.to_s) unless (row[:terrain_tags]||[]).is_a?(Array)
      end
      MAP_BINDINGS_V092.each_pair do |mid,row|
        errors.push('mapid_'+mid.to_s) if mid.to_i<=0
        key=row.is_a?(Hash) ? row[:profile] : row
        errors.push('binding_'+mid.to_s) if map_profile_v092(key)==nil
      end
      errors
    end

    def map_result_code_v092(result=nil)
      r=result
      r=last_battle_result_v081 if r==nil && respond_to?(:last_battle_result_v081)
      return 1 if r==:win
      return 2 if r==:lose
      return 3 if r==:escape
      0
    end
  end
end
