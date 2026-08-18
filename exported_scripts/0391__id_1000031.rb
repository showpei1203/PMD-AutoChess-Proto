# encoding: UTF-8
#==============================================================================
# 【PMD AutoChess 中文維護說明】
# 腳本：PMD AutoChess RPG Foundation Hub Lifecycle Fix v1.00.3
# 分類：RPG Hub UI／Scene Lifecycle／RGSS2 Viewport 相容修正／Verifier 強化
# RPG Maker VX / RGSS2 / Ruby 1.8 compatible
#==============================================================================
# 【用途】
# 修正 v1.00.2 在 NORMAL 布陣按 F8 進入「林緣營地」後，選擇「林緣探索」
# 切換場景時發生：
#   NoMethodError: undefined method `disposed?' for #<Viewport:...>
# 原因是 v1.00 Scene_PMD_RPGFoundationV100#terminate 使用：
#   @viewport.dispose if @viewport!=nil && !@viewport.disposed?
# 但 RPG Maker VX / RGSS2 的 Viewport 在此實機環境沒有 disposed? API。
#
# 【修正原則】
# 1. 不修改 Encounter／Reward／Recruit／Party／BOX／Nature／Boss 邏輯。
# 2. 不修改 Normal Attack Speed、Damage Formula、Frozen Combat Core。
# 3. 只覆蓋 Hub terminate：Bitmap / Sprite 依既有 disposed? API 安全清除；
#    Viewport 只呼叫 dispose，不再呼叫不存在的 disposed?。
# 4. dispose 後將 @sprite / @viewport 設為 nil，避免重複 terminate 再次清除。
# 5. 同步覆蓋 v1.00.1 render smoke 的 Viewport cleanup，避免 verifier 自己漏資源。
#
# 【Verifier】
# S 一次 -> RPG_FOUNDATION_V100 -> Shift。
# 除既有 v1.00 / v1.00.1 / v1.00.2 marker 外，必須看到：
#   RPG_HUB_LIFECYCLE_V1003 pass=1 start=1 terminate=1 viewport_dispose=1
# 此測試會真的執行一次 Hub start -> refresh -> terminate，專門防止
# 「畫得出來但離開時崩潰」再次漏過。
#
# 【操作】
# NORMAL 戰前布陣按 F8 -> 林緣營地 -> 選「林緣探索」。
# 正常結果：Hub 關閉並進入 Encounter / 戰鬥流程，不再於 terminate 崩潰。
#
# 【事件／腳本呼叫】
# 不需額外呼叫；本腳本是 trailing compatibility layer。
#
# 【可調參數】
# 無。此修正只處理 RGSS2 Scene lifecycle API 相容性。
#==============================================================================
module PMD_AC
  class << self
    #------------------------------------------------------------------------
    # v1.00.1 render smoke cleanup 修正版。
    # Viewport 不使用 disposed?，直接 dispose；其餘資源維持安全清理。
    #------------------------------------------------------------------------
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
          if sp
            sbmp=sp.bitmap
            sbmp.dispose if sbmp && !sbmp.disposed?
          elsif bmp
            bmp.dispose unless bmp.disposed?
          end
        rescue
        end
        begin
          sp.dispose if sp && !sp.disposed?
        rescue
        end
        begin
          vp.dispose if vp
        rescue
        end
      end
      @rpg_foundation_hub_render_error_v1001=err
      ok
    end

    #------------------------------------------------------------------------
    # Hub lifecycle smoke：真正跑 start -> render -> terminate。
    # 回傳 [總結果, start, terminate, viewport_dispose, detail]
    #------------------------------------------------------------------------
    def rpg_foundation_hub_lifecycle_smoke_v1003
      scene=nil
      start_ok=false
      terminate_ok=false
      viewport_dispose_ok=false
      err=''
      state=nil
      visits_before=nil
      begin
        state=rpg_foundation_state_v100
        visits_before=state[:visits].to_i if state
        scene=Scene_PMD_RPGFoundationV100.new
        scene.start
        start_ok=true
        begin
          sp=scene.instance_variable_get(:@sprite)
          sp.visible=false if sp
        rescue
        end
        scene.terminate
        terminate_ok=true
        vp_after=scene.instance_variable_get(:@viewport)
        sp_after=scene.instance_variable_get(:@sprite)
        viewport_dispose_ok=(!vp_after && !sp_after)
      rescue Exception => e
        err=e.class.to_s+': '+e.message.to_s
      ensure
        begin
          if state && visits_before
            state[:visits]=visits_before
          end
        rescue
        end
        # 若 start/terminate 中途失敗，做不依賴 Viewport#disposed? 的緊急清理。
        begin
          if scene
            sp=scene.instance_variable_get(:@sprite)
            if sp
              begin
                bmp=sp.bitmap
                bmp.dispose if bmp && !bmp.disposed?
              rescue
              end
              begin
                sp.dispose unless sp.disposed?
              rescue
              end
              scene.instance_variable_set(:@sprite,nil)
            end
            vp=scene.instance_variable_get(:@viewport)
            if vp
              begin
                vp.dispose
              rescue
              end
              scene.instance_variable_set(:@viewport,nil)
            end
          end
        rescue
        end
      end
      ok=start_ok && terminate_ok && viewport_dispose_ok
      @rpg_foundation_hub_lifecycle_error_v1003=err
      [ok,start_ok,terminate_ok,viewport_dispose_ok,err]
    end

    def rpg_foundation_hub_lifecycle_error_v1003
      @rpg_foundation_hub_lifecycle_error_v1003.to_s
    end

    # v1.00.1 verifier 會先呼叫此 writer。先只記錄 render 結果，
    # v1.00.3 lifecycle 測完後再產生最新且完整的單一報告。
    def write_rpg_foundation_hubfix_report_v1001(pass,detail='')
      @rpg_hub_render_pass_v1003=pass ? true : false
      @rpg_hub_render_detail_v1003=detail.to_s
      true
    end

    def write_rpg_foundation_hubfix_report_v1003(lifecycle_result)
      begin
        render_pass=@rpg_hub_render_pass_v1003 ? true : false
        render_detail=@rpg_hub_render_detail_v1003.to_s
        life_pass=lifecycle_result[0] ? true : false
        truth_pass=false
        if respond_to?(:rpg_color_truthiness_probe_v1002)
          tr=rpg_color_truthiness_probe_v1002
          truth_pass=tr[0] ? true : false
        end
        total=render_pass && truth_pass && life_pass
        File.open('PMD_RPGFoundationHubFix_v1.00.3.txt','wb') do |f|
          f.write("PMD AutoChess RPG Foundation Hub Lifecycle Fix v1.00.3\r\n")
          f.write("Hub render smoke: "+(render_pass ? 'PASS':'FAIL')+"\r\n")
          f.write("Color truthiness bridge: "+(truth_pass ? 'PASS':'FAIL')+"\r\n")
          f.write("Hub lifecycle start: "+(lifecycle_result[1] ? 'PASS':'FAIL')+"\r\n")
          f.write("Hub lifecycle terminate: "+(lifecycle_result[2] ? 'PASS':'FAIL')+"\r\n")
          f.write("Viewport dispose without disposed?: "+(lifecycle_result[3] ? 'PASS':'FAIL')+"\r\n")
          f.write("Root cause: RGSS2 Viewport has no disposed? method on this runtime\r\n")
          f.write("Original RPG Foundation gameplay logic modified: NO\r\n")
          f.write("Normal Attack Speed modified: NO\r\n")
          f.write("Damage formula modified: NO\r\n")
          f.write("Frozen Combat Core direct modification: NO\r\n")
          f.write("Render detail: "+render_detail+"\r\n")
          f.write("Lifecycle detail: "+lifecycle_result[4].to_s+"\r\n")
          f.write("Review PASS: "+(total ? '1':'0')+"\r\n")
        end
        total
      rescue
        false
      end
    end
  end
end

#==============================================================================
# ■ Scene_PMD_RPGFoundationV100 : lifecycle compatibility override
#==============================================================================
class Scene_PMD_RPGFoundationV100
  def terminate
    super
    sp=@sprite
    if sp
      begin
        bmp=sp.bitmap
        bmp.dispose if bmp && !bmp.disposed?
      rescue
      end
      begin
        sp.dispose unless sp.disposed?
      rescue
        begin
          sp.dispose
        rescue
        end
      end
    end
    @sprite=nil

    # RGSS2 Viewport：本實機沒有 disposed?；只呼叫 dispose。
    vp=@viewport
    if vp
      begin
        vp.dispose
      rescue
      end
    end
    @viewport=nil
  end
end

#==============================================================================
# ■ Scene_PMD_AutoChess : lifecycle verifier
#==============================================================================
class Scene_PMD_AutoChess
  alias pmd_ac_v1003_update_verification_script update_verification_script unless method_defined?(:pmd_ac_v1003_update_verification_script)
  def update_verification_script
    pmd_ac_v1003_update_verification_script
    return unless verification_mode==:rpg_foundation_v100
    f=@verification_frame.to_i
    verify_rpg_hub_lifecycle_v1003 if f>=136
  end

  def verify_rpg_hub_lifecycle_v1003
    return if @verification_done[:rpg_hub_lifecycle_v1003]
    r=PMD_AC.rpg_foundation_hub_lifecycle_smoke_v1003
    pass=r[0]
    @rpg_foundation_failed_v100=true unless pass
    detail='start='+(r[1] ? '1':'0')+
      ' terminate='+(r[2] ? '1':'0')+
      ' viewport_dispose='+(r[3] ? '1':'0')
    detail+=' error='+r[4].to_s unless r[4].to_s.empty?
    log_event(:verify,'RPG_HUB_LIFECYCLE_V1003 pass='+(pass ? '1':'0')+' '+detail)
    PMD_AC.write_rpg_foundation_hubfix_report_v1003(r)
    @verification_done[:rpg_hub_lifecycle_v1003]=true
  end
end

PMD_AC.log_global(:rpg_foundation,'PATCH v1.00.3 hub_lifecycle=1 viewport_disposed_query=removed lifecycle_smoke=start+render+terminate gameplay_unchanged=1') if PMD_AC.respond_to?(:log_global)
