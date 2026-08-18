#==============================================================================
# 【PMD AutoChess 中文維護說明】
# 腳本：PMD AutoChess Party Storage Data v0.78
# 分類：隊伍／BOX
#
# 【用途／機制】
# 管理 3 隻出戰隊伍、24×30 BOX、instance_uid 原子交換與編成 UI。
#
# 【怎麼調整】
# 擴充取得 Pokémon 時可使用 store_instance_first_available_v078；不要用 Actor ID
#  當個體身份。
#
# 【本腳本主要設定常數／資料表】
# - PARTY_STORAGE_MANIFEST_V078 / PARTY_STORAGE_VERIFY_END_V078 / PARTY_STORAGE_VISIBLE_ROWS_V078
#
# 【Runtime 主要方法（查流程時可直接搜尋）】
# - party_instances_v078 / box_instances_v078 / storage_count_v078 / party_ready_v078?
# - first_available_box_v078 / store_instance_first_available_v078 / party_storage_integrity_errors_v078 / ensure_demo_reserves_v078
# - party_storage_checksum32_v078
#
# 【維護規則】
# - RPG Maker VX / RGSS2 / Ruby 1.8 相容。
# - instance_uid 才是 Pokémon 個體身份；Actor ID 只是容器。
# - 新增行為優先沿用既有 helper／Data 表；避免破壞已 Freeze 的舊核心。
# - 本專案新腳本也必須保留同等級的中文說明與實際範例。
#==============================================================================
#==============================================================================
# PMD AutoChess Party / Storage Manager Data v0.78
# RGSS2 / Ruby 1.8 compatible
#==============================================================================
module PMD_AC
  PARTY_STORAGE_MANIFEST_V078 = {
    :schema_version=>"1.0",
    :content_version=>"0.78.0",
    :base_identity=>"v0.45",
    :party_capacity=>3,
    :storage_boxes=>24,
    :box_capacity=>30,
    :identity_key=>"instance_uid",
    :manager_input=>"Input::X",
    :swap_policy=>"atomic_party_storage_swap",
    :empty_party_policy=>"fixed_three_swap_only",
    :future_store_api=>"first_available_box",
    :test_project_demo_reserves=>3,
    :progression=>"v0.76+v0.77.1",
    :battle_balance=>"v0.75",
    :runtime_checksum32=>2687215894
  }

  PARTY_STORAGE_VERIFY_END_V078 = 18
  PARTY_STORAGE_VISIBLE_ROWS_V078 = 9

  class << self
    def party_instances_v078
      a=[]
      for i in 0...PARTY_CAPACITY_V045
        a.push(party_instance_v045(i))
      end
      a
    end

    def box_instances_v078(box_index)
      bi=box_index.to_i
      return [] if bi<0 || bi>=STORAGE_BOX_COUNT_V045
      result=[]
      box=pokemon_storage_boxes_v045[bi] || []
      for uid in box
        i=pokemon_instance_for_uid_v045(uid)
        result.push(i) if i!=nil
      end
      result
    end

    def storage_count_v078
      total=0
      for box in pokemon_storage_boxes_v045
        total += box==nil ? 0 : box.size
      end
      total
    end

    def party_ready_v078?
      p=pokemon_party_uids_v045
      return false if p==nil || p.size<PARTY_CAPACITY_V045
      seen={}
      for i in 0...PARTY_CAPACITY_V045
        uid=p[i]
        return false if uid==nil || uid.to_i<=0
        return false if seen[uid.to_i]
        seen[uid.to_i]=true
        return false if pokemon_instance_for_uid_v045(uid)==nil
      end
      true
    end

    def first_available_box_v078
      boxes=pokemon_storage_boxes_v045
      for bi in 0...STORAGE_BOX_COUNT_V045
        box=boxes[bi] || []
        return bi if box.size<STORAGE_BOX_CAPACITY_V045
      end
      nil
    end

    def store_instance_first_available_v078(instance,allow_from_party=false)
      return false if instance==nil
      bi=first_available_box_v078
      return false if bi==nil
      store_instance_v045(instance,bi,allow_from_party)
    end

    def party_storage_integrity_errors_v078
      errors=[]
      party=pokemon_party_uids_v045 || []
      boxes=pokemon_storage_boxes_v045 || []
      seen={}
      for si in 0...party.size
        uid=party[si]
        next if uid==nil
        k=uid.to_i
        errors.push("party_invalid_uid_"+si.to_s) if k<=0
        errors.push("duplicate_uid_"+k.to_s) if seen[k]
        seen[k]=true
        errors.push("party_missing_registry_"+k.to_s) if pokemon_instance_for_uid_v045(k)==nil
      end
      for bi in 0...boxes.size
        box=boxes[bi] || []
        errors.push("box_overflow_"+bi.to_s) if box.size>STORAGE_BOX_CAPACITY_V045
        for uid in box
          k=uid.to_i
          errors.push("box_invalid_uid_"+bi.to_s) if k<=0
          errors.push("duplicate_uid_"+k.to_s) if seen[k]
          seen[k]=true
          errors.push("box_missing_registry_"+k.to_s) if pokemon_instance_for_uid_v045(k)==nil
        end
      end
      errors.uniq
    end


    def ensure_demo_reserves_v078
      return 0 if identity_sandbox_v045?
      return 0 unless storage_count_v078==0
      specs=[:rattata,:caterpie,:pikachu]
      added=0
      for sp in specs
        inst=PMD_PokemonInstance.new(sp,15,
          {:ivs=>[15,15,15,15,15,15],:nature=>:hardy,:ability_slot=>:primary})
        if register_pokemon_instance_v045(inst) &&
           store_instance_first_available_v078(inst,false)
          added+=1
        end
      end
      added
    end

    def party_storage_checksum32_v078
      PARTY_STORAGE_MANIFEST_V078[:runtime_checksum32].to_i
    end
  end
end
