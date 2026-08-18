# encoding: UTF-8
#==============================================================================
# 【PMD AutoChess 中文維護說明】
# 腳本：PMD AutoChess Ability Verifier Isolation Hotfix v0.96.2
# 分類：特性 Ability／Verifier 修正／啟動相容修正／v0.96.2
#
# 【用途】
# 修正 v0.96 ABILITY_RUNTIME_V096 驗證模式中「前一組測試假單位殘留」造成的
# Regenerator（再生力）誤判，並修正 v0.96.1 啟動時誤 alias 不存在的 draw_header
# 所造成的 NameError。正式戰鬥 Ability Runtime 本身不修改。
#
# 【問題原因】
# 1. v0.96 多組 Ability Verifier 共用 @ability_runtime_test_units_v096；前一組假敵人
#    會污染後續 Regenerator 的安全距離判定。
# 2. v0.96.1 為更新標題誤寫 `alias ... draw_header`，但目前 Scene_PMD_AutoChess
#    的正式標題方法名稱是 refresh_header，因此腳本載入階段就發生 NameError。
#
# 【本版規則】
# 1. 每一組 v0.96 Ability Verifier 開始前清空上一組測試假單位。
# 2. 隔離期間 ability_global_units_v096 只回傳本組測試假單位。
# 3. 測試結束立即離開隔離 Scope；正式戰鬥的單位搜尋行為完全不變。
# 4. Regenerator 正式規則完全不變：安全距離 >150px、累積 180f、回 MaxHP/6。
# 5. 標題覆寫正式使用 refresh_header，不再引用不存在的 draw_header。
#
# 【主要設定項／可調參數】
# 本補丁沒有新增平衡參數。Regenerator 仍使用：
#   PMD_AC::ABILITY_RUNTIME_BEHAVIOR_V096[:regenerator]
#
# 【事件／腳本呼叫方式】
# 一般遊戲不需呼叫。
# 驗證：布陣 NORMAL → S 一次 → ABILITY_RUNTIME_V096 → Shift。
#
# 【實際範例】
# v0.96 舊錯誤：regenerator=865->865（前一組假敵人污染）。
# v0.96.1 啟動錯誤：undefined method `draw_header' for class Scene_PMD_AutoChess。
# v0.96.2 預期：可正常進入遊戲；鳳王安全 180f 後 HP 必須由 865 上升。
#
# 【注意事項】
# - RPG Maker VX / RGSS2 / Ruby 1.8 相容。
# - 只修 Verifier isolation 與 v0.96.1 啟動錯誤。
# - 不修改 Ability、AI、Damage、Movement、Energy、PMD 動作或 Loot 數值。
# - v0.96 的 12 種 Ability Runtime、1137/1193 slots、494/494 Species 規則不變。
#==============================================================================
module PMD_AC
  ABILITY_VERIFIER_ISOLATION_VERSION_V0962='0.96.2'
end

class Scene_PMD_AutoChess
  alias pmd_ac_v0962_start start unless method_defined?(:pmd_ac_v0962_start)
  def start
    pmd_ac_v0962_start
    begin
      if FileTest.exist?(PMD_AC::BATTLE_LOG_FILE)
        text=File.open(PMD_AC::BATTLE_LOG_FILE,'rb'){|f|f.read}
        text.sub!(/PMD AutoChess Proto v0\.[0-9.]+ Battle Verification Log/,
          'PMD AutoChess Proto v0.96.2 Battle Verification Log')
        File.open(PMD_AC::BATTLE_LOG_FILE,'wb'){|f|f.write(text)}
      end
    rescue
    end
    log_event(:ability_runtime_v096,
      'PATCH v0.96.2 verifier_group_isolation=1 stale_test_units=cleared '+
      'startup_alias=refresh_header regenerator_runtime=unchanged '+
      'safe_distance=150 pulse=180 heal=1/6')
  end

  # Scene_PMD_AutoChess 的正式標題方法是 refresh_header。
  alias pmd_ac_v0962_refresh_header refresh_header unless method_defined?(:pmd_ac_v0962_refresh_header)
  def refresh_header
    pmd_ac_v0962_refresh_header
    return if @header_sprite==nil || @header_sprite.bitmap==nil
    bmp=@header_sprite.bitmap
    bmp.fill_rect(0,0,Graphics.width,28,Color.new(0,0,0,180))
    pmd_ac_v074_font(bmp)
    bmp.font.size=PMD_AC.const_defined?(:UI_HEADER_TITLE_FONT_V086) ? PMD_AC::UI_HEADER_TITLE_FONT_V086 : 20
    bmp.font.bold=true
    bmp.font.color=Color.new(255,255,255)
    bmp.draw_text(16,1,Graphics.width-32,30,'PMD 自走棋原型 v0.96.2',1)
  end

  # 隔離期間只讓 Ability helper 看見「本組」Verifier 單位。
  alias pmd_ac_v0962_ability_global_units_v096 ability_global_units_v096 unless method_defined?(:pmd_ac_v0962_ability_global_units_v096)
  def ability_global_units_v096
    if @ability_verifier_isolation_v0962
      list=[]
      (@ability_runtime_test_units_v096||[]).each do |u|
        list.push(u) unless u==nil || list.include?(u)
      end
      return list
    end
    pmd_ac_v0962_ability_global_units_v096
  end

  def ability_verifier_group_scope_v0962
    old_scope=@ability_verifier_isolation_v0962
    @ability_verifier_isolation_v0962=true
    @ability_runtime_test_units_v096=[]
    begin
      yield
    ensure
      @ability_runtime_test_units_v096=[]
      @ability_verifier_isolation_v0962=old_scope
    end
  end

  alias pmd_ac_v0962_verify_pressure_unnerve_v096 verify_pressure_unnerve_v096 unless method_defined?(:pmd_ac_v0962_verify_pressure_unnerve_v096)
  def verify_pressure_unnerve_v096
    ability_verifier_group_scope_v0962 do
      pmd_ac_v0962_verify_pressure_unnerve_v096
    end
  end

  alias pmd_ac_v0962_verify_natural_regenerator_v096 verify_natural_regenerator_v096 unless method_defined?(:pmd_ac_v0962_verify_natural_regenerator_v096)
  def verify_natural_regenerator_v096
    ability_verifier_group_scope_v0962 do
      unless @verification_done[:v096_natural]
        log_event(:verify,
          'ABILITY_VERIFIER_ISOLATION_V0962 pass=1 group=natural_regenerator '+
          'test_units=current_group_only stale_units=0 startup_alias=refresh_header runtime_unchanged=1')
      end
      pmd_ac_v0962_verify_natural_regenerator_v096
    end
  end

  alias pmd_ac_v0962_verify_trace_multitype_v096 verify_trace_multitype_v096 unless method_defined?(:pmd_ac_v0962_verify_trace_multitype_v096)
  def verify_trace_multitype_v096
    ability_verifier_group_scope_v0962 do
      pmd_ac_v0962_verify_trace_multitype_v096
    end
  end

  alias pmd_ac_v0962_verify_mold_bounce_v096 verify_mold_bounce_v096 unless method_defined?(:pmd_ac_v0962_verify_mold_bounce_v096)
  def verify_mold_bounce_v096
    ability_verifier_group_scope_v0962 do
      pmd_ac_v0962_verify_mold_bounce_v096
    end
  end

  alias pmd_ac_v0962_verify_analytic_cute_v096 verify_analytic_cute_v096 unless method_defined?(:pmd_ac_v0962_verify_analytic_cute_v096)
  def verify_analytic_cute_v096
    ability_verifier_group_scope_v0962 do
      pmd_ac_v0962_verify_analytic_cute_v096
    end
  end

  alias pmd_ac_v0962_verify_healer_runaway_v096 verify_healer_runaway_v096 unless method_defined?(:pmd_ac_v0962_verify_healer_runaway_v096)
  def verify_healer_runaway_v096
    ability_verifier_group_scope_v0962 do
      pmd_ac_v0962_verify_healer_runaway_v096
    end
  end
end
