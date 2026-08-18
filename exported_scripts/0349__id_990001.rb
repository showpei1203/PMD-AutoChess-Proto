# encoding: UTF-8
#==============================================================================
# 【PMD AutoChess 中文維護說明】
# 腳本：PMD AutoChess Supply / Inventory UI Data v0.99
# 分類：玩家介面／補給背包／v0.98 Item Runtime 前端
#
# 【用途】
# 把 v0.98 已完成的 8 種正式補給品與 use_supply_v098 API 接成玩家可直接操作的
# 背包介面。這支只放 UI 文案、模式與測試設定，不改任何補給品數值。
#
# 【主要設定項】
# SUPPLY_UI_OPEN_INPUT_V099：布陣階段開啟鍵，正式採 Input::ALT。
# SUPPLY_UI_VISIBLE_ITEM_ROWS_V099：左側一次顯示的道具列數。
# SUPPLY_UI_VISIBLE_MOVE_ROWS_V099：招式熟練道具一次顯示的招式列數。
# SUPPLY_UI_DEMO_SEED_V099：FullTestProject 是否一次性補到每種 2 個，方便直接測 UI。
# SUPPLY_UI_DESCRIPTIONS_V099：8 種道具的玩家說明文字。
#
# 【機制規則】
# :items   選道具。
# :targets 選目前 Party 的 Pokémon；身份一律使用 instance_uid。
# :moves   只有招式心得／招式秘典會進入，選擇該個體已學招式。
# 群體型道具（團隊口糧／蜂王蜜）在道具頁直接使用。
#
# 【事件／腳本呼叫】
# 地圖事件可直接：PMD_AC.open_supply_inventory_v099
# 戰前布陣：按 Alt 開啟。
# 關閉：Alt 或 B；確認：C/Enter；返回上一層：B。
#
# 【實際範例】
# 1. Alt → 林緣傷藥 → Enter → 選妙蛙種子 → Enter。
# 2. Alt → 招式心得 → Enter → 選小火龍 → Enter → 選 Ember → Enter。
# 3. Alt → 團隊口糧 → Enter，直接治療目前三隻隊員中受傷且存活者。
#
# 【可調參數】
# 本版只調 UI 行數、測試種子與說明文字。HP%、EXP、Mastery 數值仍只改 v0.98
# SUPPLY_CATALOG_V098，避免兩份設定互相打架。
#
# 【注意】
# - SUPPLY_UI_DEMO_SEED_V099=true 只為 FullTestProject 直接測試；正式整合進 RPG 時
#   可設 false，所有道具仍應由 v0.98 Loot／事件取得。
# - 不修改 Loot 權重、Ability 1193/1193、AI、Damage、Energy、PMD Motion、Multi-hit。
# - RPG Maker VX / RGSS2 / Ruby 1.8 相容。
#==============================================================================
module PMD_AC
  PATCH_VERSION_SUPPLY_UI_V099='0.99'
  SUPPLY_UI_OPEN_INPUT_V099='Input::ALT'
  SUPPLY_UI_VISIBLE_ITEM_ROWS_V099=8
  SUPPLY_UI_VISIBLE_MOVE_ROWS_V099=7
  SUPPLY_UI_DEMO_SEED_V099=true

  SUPPLY_UI_DESCRIPTIONS_V099={
    6=>'回復一隻存活寶可夢 35% 最大 HP。HP 已滿或倒下時不能使用。',
    7=>'讓一隻倒下的寶可夢復活，HP 回到最大值的 40%。',
    8=>'讓一隻寶可夢獲得 300 EXP；Lv100 時不能使用。',
    9=>'讓一隻寶可夢獲得 900 EXP；Lv100 時不能使用。',
    10=>'指定一隻寶可夢的已學招式，增加 10 點招式熟練度。',
    11=>'指定一隻寶可夢的已學招式，增加 30 點招式熟練度。',
    12=>'目前三隻隊員中，所有存活且受傷者各回復 25% 最大 HP。',
    13=>'存活隊員回復 50% 最大 HP；倒下隊員以 25% 最大 HP 復活。'
  }

  SUPPLY_UI_KIND_LABELS_V099={
    :heal_one=>'單體回復',:revive_one=>'單體復活',:exp_one=>'經驗成長',
    :mastery_one=>'招式熟練',:heal_party=>'全隊回復',:honey_party=>'全隊急救'
  }

  SUPPLY_UI_REASON_LABELS_V099={
    :unknown_item=>'這個道具目前沒有 PMD 補給效果。',
    :no_inventory=>'目前沒有持有這個道具。',
    :no_target=>'沒有可使用的寶可夢目標。',
    :fainted=>'目標已倒下，這個道具不能使用。',
    :full_hp=>'目標 HP 已滿。',
    :not_fainted=>'目標尚未倒下，不需要復活。',
    :level_max=>'目標已達 Lv100。',
    :no_move=>'請選擇一個已學招式。',
    :mastery_max=>'這個招式的熟練度已達上限。',
    :no_injured_party=>'目前隊伍沒有需要回復的成員。',
    :unsupported_kind=>'這個補給效果尚未支援。'
  }

  SUPPLY_UI_VERIFY_END_V099=34
  SUPPLY_UI_MANIFEST_V099={
    :version=>'0.99',:catalog_items=>8,:party_capacity=>3,
    :open_phase=>:deploy,:open_input=>SUPPLY_UI_OPEN_INPUT_V099,
    :modes=>[:items,:targets,:moves],:targeted_items=>6,:party_items=>2,
    :mastery_items=>2,:uses_runtime=>'v0.98',:identity=>'instance_uid',
    :field_hp_bridge=>'field_hp_v082',:map_scene_api=>true,
    :demo_seed=>SUPPLY_UI_DEMO_SEED_V099,:combat_rules_unchanged=>true
  }

  class << self
    def supply_ui_description_v099(item_id)
      SUPPLY_UI_DESCRIPTIONS_V099[item_id.to_i] || ''
    end
    def supply_ui_kind_label_v099(kind)
      SUPPLY_UI_KIND_LABELS_V099[kind] || kind.to_s
    end
    def supply_ui_reason_label_v099(reason)
      SUPPLY_UI_REASON_LABELS_V099[reason] || (reason==nil ? '' : reason.to_s)
    end
    def supply_ui_targeted_kind_v099?(kind)
      ![:heal_party,:honey_party].include?(kind)
    end
    def supply_ui_mastery_kind_v099?(kind)
      kind==:mastery_one
    end
  end
end
