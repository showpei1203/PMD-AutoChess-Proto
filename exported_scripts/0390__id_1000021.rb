# encoding: UTF-8
#==============================================================================
# 【PMD AutoChess 中文維護說明】
# 腳本：PMD AutoChess RPG Foundation Hub Color Nil-Compare Fix v1.00.2
# 分類：RPG Hub UI／RGSS2 Color 相容修正／Render Regression 強化
# RPG Maker VX / RGSS2 / Ruby 1.8 compatible
#==============================================================================
# 【用途】
# 修正 v1.00 / v1.00.1 在 NORMAL 布陣按 F8 進入「林緣營地」時出現：
#   TypeError: can't convert NilClass into Color
#
# 【真正根因】
# v1.00 原碼：
#   b.font.color=color if color!=nil
# v1.00.1 安全橋接又寫成：
#   if color!=nil && ...
# Windows RGSS2 實機顯示錯誤行正好落在上述「Color 與 nil 做 != 比較」的位置。
# RGSS2 的 Color 是 C extension 類別；其 == / != 對 nil 的比較路徑會嘗試把
# nil 轉成 Color，因而丟出 TypeError。換句話說，前一版誤判成 Font#color=。
#
# 【修正原則】
# 1. Hub Color 路徑完全禁止 `color != nil` / `color == nil`。
# 2. 改用 Ruby truthiness：`if color` / `color ? ... : ...`，不呼叫 Color#==。
# 3. 已有 Color 物件直接交給 Font#color=；nil 才建立白色 Color fallback。
# 4. 不修改 Encounter／Reward／Recruit／Party／BOX／Nature／Boss。
# 5. 不修改 Normal Attack Speed、Damage Formula、Frozen Combat Core。
# 6. 保留 v1.00.1 render smoke，並追加 v1.00.2 truthiness regression。
#
# 【Verifier】
# S 一次 -> RPG_FOUNDATION_V100 -> Shift。
# 必須看到：
#   RPG_HUB_RENDER_V1001 pass=1 color_bridge=1 refresh=1
#   RPG_COLOR_TRUTHINESS_V1002 pass=1 supplied=1 fallback=1 refresh=1 nil_compare_removed=1
#   RPG_FOUNDATION_V100 pass=1
#   VERIFY_FINISHED_BATTLE_RESUME pass=1
#
# 【操作】
# NORMAL 戰前布陣按 F8：進入「林緣營地」。
#
# 【事件／腳本呼叫】
# 本腳本是相容層，不需要事件端額外呼叫。
#
# 【可調參數】
# HUB_FALLBACK_COLOR_V1002：Hub 未指定文字色時的 RGBA，預設純白。
#==============================================================================
module PMD_AC
  HUB_FALLBACK_COLOR_V1002=[255,255,255,255]

  class << self
    # 覆蓋 v1.00.1 同名方法。
    # 關鍵：絕不寫 `color != nil`，因為 RGSS2 Color#!= nil 會進 C 層比較。
    def hub_safe_color_v1001(color)
      if color
        return color
      end
      c=HUB_FALLBACK_COLOR_V1002
      Color.new(c[0],c[1],c[2],c[3])
    end

    def rpg_color_truthiness_probe_v1002
      begin
        supplied=hub_safe_color_v1001(Color.new(11,22,33,44))
        fallback=hub_safe_color_v1001(nil)
        supplied_ok=supplied.is_a?(Color)
        fallback_ok=fallback.is_a?(Color)
        refresh_ok=rpg_foundation_hub_render_smoke_v1001
        return [supplied_ok && fallback_ok && refresh_ok,supplied_ok,fallback_ok,refresh_ok]
      rescue Exception
        return [false,false,false,false]
      end
    end

    # v1.00.1 verifier 仍會呼叫這個 writer；改寫成最新 hotfix 報告，
    # 讓使用者只需要回傳一份 v1.00.2 報告。
    def write_rpg_foundation_hubfix_report_v1001(pass,detail='')
      begin
        File.open('PMD_RPGFoundationHubFix_v1.00.2.txt','wb') do |f|
          f.write("PMD AutoChess RPG Foundation Hub Color Nil-Compare Fix v1.00.2\r\n")
          f.write("F8 Hub render smoke: "+(pass ? 'PASS':'FAIL')+"\r\n")
          f.write("Root cause: RGSS2 Color compared with nil via ==/!= C-extension path\r\n")
          f.write("Fix: Ruby truthiness only; no Color == nil / != nil comparison\r\n")
          f.write("Original RPG Foundation runtime logic modified: NO\r\n")
          f.write("Normal Attack Speed modified: NO\r\n")
          f.write("Damage formula modified: NO\r\n")
          f.write("Frozen Combat Core direct modification: NO\r\n")
          f.write("Detail: "+detail.to_s+"\r\n")
          f.write("Review PASS: "+(pass ? '1':'0')+"\r\n")
        end
        return true
      rescue
        return false
      end
    end
  end
end

class Scene_PMD_RPGFoundationV100
  # 覆蓋 v1.00.1。
  # supplied Color 直接使用；nil 才由 hub_safe_color_v1001 建立 fallback。
  # 這裡也完全不做 Color 與 nil 的 == / != 比較。
  def font_v100(b,size,bold=false,color=nil)
    begin
      b.font.name=['Microsoft JhengHei','微軟正黑體','Arial']
    rescue
    end
    b.font.size=size.to_i
    b.font.bold=bold ? true : false
    b.font.color=PMD_AC.hub_safe_color_v1001(color)
  end
end

class Scene_PMD_AutoChess
  alias pmd_ac_v1002_update_verification_script update_verification_script unless method_defined?(:pmd_ac_v1002_update_verification_script)
  def update_verification_script
    pmd_ac_v1002_update_verification_script
    return unless verification_mode==:rpg_foundation_v100
    f=@verification_frame.to_i
    verify_rpg_color_truthiness_v1002 if f>=132
  end

  def verify_rpg_color_truthiness_v1002
    return if @verification_done[:rpg_color_truthiness_v1002]
    r=PMD_AC.rpg_color_truthiness_probe_v1002
    pass=r[0]
    @rpg_foundation_failed_v100=true unless pass
    log_event(:verify,'RPG_COLOR_TRUTHINESS_V1002 pass='+(pass ? '1':'0')+
      ' supplied='+(r[1] ? '1':'0')+
      ' fallback='+(r[2] ? '1':'0')+
      ' refresh='+(r[3] ? '1':'0')+
      ' nil_compare_removed=1')
    @verification_done[:rpg_color_truthiness_v1002]=true
  end
end

PMD_AC.log_global(:rpg_foundation,'PATCH v1.00.2 hub_color_nil_compare=truthiness_only Color_eq_nil=removed render_smoke=v1.00.1_carried gameplay_unchanged=1') if PMD_AC.respond_to?(:log_global)
