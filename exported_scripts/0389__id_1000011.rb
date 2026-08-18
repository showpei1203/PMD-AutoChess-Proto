# encoding: UTF-8
#==============================================================================
# 【PMD AutoChess 中文維護說明】
# 腳本：PMD AutoChess RPG Foundation Hub Render Fix v1.00.1
# 分類：RPG Hub UI 相容修正／RGSS2 Color Bridge／實際 Render Regression
# RPG Maker VX / RGSS2 / Ruby 1.8 compatible
#==============================================================================
# 【用途】
# 修正 v1.00 在 NORMAL 布陣按 F8 進入「林緣營地」時，
# Scene_PMD_RPGFoundationV100#font_v100 將可選 Color 參數直接轉交給
# RGSS2 Font#color=，於部分實機路徑收到 nil 後產生：
#   TypeError: can't convert NilClass into Color
#
# 【修正原則】
# 1. 不修改 v1.00 Encounter／Reward／Recruit／Party／BOX／Nature／Boss 邏輯。
# 2. 不修改 Frozen Combat Core、傷害公式、Attack Speed。
# 3. 僅以 trailing override 修正 Hub 的字型顏色橋接。
# 4. Font#color= 永遠只接收「新建的 Color 實例」，不再把可選參數原樣交給 C 層。
# 5. color 為 nil 時使用白色，避免 RGSS2 C extension 收到 NilClass。
#
# 【Verifier】
# v1.00 原 verifier 只確認 Hub Scene/API 存在，沒有真的繪製畫面。
# v1.00.1 新增實際 render smoke：建立隱藏 Viewport／Sprite／Bitmap，
# 呼叫 refresh_v100 完整畫一次 Hub，再立即 dispose。
# 正式 marker：
#   RPG_HUB_RENDER_V1001 pass=1 color_bridge=1 refresh=1
# 若 render 發生例外，會讓原 RPG_FOUNDATION_V100 最終驗證一併 FAIL。
#
# 【操作】
# - NORMAL 戰前布陣按 F8：進入林緣營地。
# - S 一次切到 RPG_FOUNDATION_V100，Shift 執行 verifier。
#
# 【可調參數】
# HUB_FALLBACK_COLOR_V1001：Hub 字型沒有指定有效 Color 時的預設 RGBA。
# 一般不需要修改。
#==============================================================================
module PMD_AC
  HUB_FALLBACK_COLOR_V1001=[255,255,255,255]

  class << self
    def hub_safe_color_v1001(color)
      if color!=nil && color.respond_to?(:red) && color.respond_to?(:green) && color.respond_to?(:blue)
        a=color.respond_to?(:alpha) ? color.alpha.to_i : 255
        return Color.new(color.red.to_i,color.green.to_i,color.blue.to_i,a)
      end
      c=HUB_FALLBACK_COLOR_V1001
      Color.new(c[0],c[1],c[2],c[3])
    end

    def rpg_foundation_hub_render_smoke_v1001
      vp=nil
      sp=nil
      bmp=nil
      scene=nil
      err=''
      ok=false
      begin
        vp=Viewport.new(0,0,Graphics.width,Graphics.height)
        vp.z=1
        sp=Sprite.new(vp)
        sp.visible=false
        bmp=Bitmap.new(Graphics.width,Graphics.height)
        sp.bitmap=bmp
        scene=Scene_PMD_RPGFoundationV100.new
        scene.instance_variable_set(:@index,0)
        scene.instance_variable_set(:@viewport,vp)
        scene.instance_variable_set(:@sprite,sp)
        scene.refresh_v100
        ok=true
      rescue Exception => e
        err=e.class.to_s+': '+e.message.to_s
        ok=false
      ensure
        begin
          if sp!=nil && sp.bitmap!=nil && !sp.bitmap.disposed?
            sp.bitmap.dispose
          end
        rescue
        end
        begin
          sp.dispose if sp!=nil && !sp.disposed?
        rescue
        end
        begin
          vp.dispose if vp!=nil && !vp.disposed?
        rescue
        end
      end
      @rpg_foundation_hub_render_error_v1001=err
      ok
    end

    def rpg_foundation_hub_render_error_v1001
      @rpg_foundation_hub_render_error_v1001.to_s
    end

    def write_rpg_foundation_hubfix_report_v1001(pass,detail='')
      begin
        File.open('PMD_RPGFoundationHubFix_v1.00.1.txt','wb') do |f|
          f.write("PMD AutoChess RPG Foundation Hub Render Fix v1.00.1\r\n")
          f.write("F8 Hub render smoke: "+(pass ? 'PASS':'FAIL')+"\r\n")
          f.write("RGSS2 Font color bridge: safe Color instance only\r\n")
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
  # v1.00.1：不要把可選參數直接傳入 RGSS2 Font#color=。
  # 先重建成真正的 Color 物件；nil 則回退白色。
  def font_v100(b,size,bold=false,color=nil)
    begin
      b.font.name=['Microsoft JhengHei','微軟正黑體','Arial']
    rescue
    end
    b.font.size=size.to_i
    b.font.bold=bold ? true : false
    safe=PMD_AC.hub_safe_color_v1001(color)
    b.font.color=safe
  end
end

class Scene_PMD_AutoChess
  alias pmd_ac_v1001_update_verification_script update_verification_script unless method_defined?(:pmd_ac_v1001_update_verification_script)
  def update_verification_script
    pmd_ac_v1001_update_verification_script
    return unless verification_mode==:rpg_foundation_v100
    f=@verification_frame.to_i
    verify_rpg_hub_render_v1001 if f>=128
  end

  def verify_rpg_hub_render_v1001
    return if @verification_done[:rpg_hub_render_v1001]
    pass=PMD_AC.rpg_foundation_hub_render_smoke_v1001
    err=PMD_AC.rpg_foundation_hub_render_error_v1001
    @rpg_foundation_failed_v100=true unless pass
    detail=pass ? 'color_bridge=1 refresh=1' : 'color_bridge=0 refresh=0 error='+err
    log_event(:verify,'RPG_HUB_RENDER_V1001 pass='+(pass ? '1':'0')+' '+detail)
    PMD_AC.write_rpg_foundation_hubfix_report_v1001(pass,detail)
    @verification_done[:rpg_hub_render_v1001]=true
  end
end
