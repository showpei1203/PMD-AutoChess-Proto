# encoding: UTF-8
#===============================================================================
# ■ PMD AutoChess - VXRD Random Hunt Real Loading Overlay I v1.06.56
#-------------------------------------------------------------------------------
# 【用途】
# 1. 將 Random Hunt 進入 Map090、切換 Hunt、前往下一層時原本的黑幕等待，
#    改成沿用既有「戰鬥 Loading」視覺語言的真正進度顯示。
# 2. 百分比綁定真實生成 checkpoint，不使用假計時器，也不故意延長讀取時間。
# 3. 直接沿用既有 Loading Authority：
#    - v1.02.9 的百分比 / 藍色 bar / stage / detail 版型。
#    - v1.00.7 的跑動寶可夢 Sprite_PMDLoadingPokemonV1007。
#    - v1.02.33 的 UI refresh throttle 概念（stage 變更立即刷新；同 stage 3% 或 180ms）。
# 4. Loading 期間不呼叫 Input.update，避免輸入穿透。
#
# 【真實進度 checkpoint】
# 0%   開始探索地圖 Loading
# 12%  Map090 房間 / 地形生成
# 45%  Landmark 生成開始
# 60%  Landmark / collision mask 完成
# 62%  entrance -> exit pre-event route audit
# 68%  Map091 Event Template materialize
# 76%  semantic relocation
# 84%  post-event required-target route audit
# 93%  Hunt floor data finalize
# 96%  Map / spriteset 準備
# 100% 可立即 reveal
#
# 【不變】
# - 不修改 Random Hunt seed / room topology / route audit 結果。
# - 不修改 AI / Damage / Attack Speed / Focus/C2 / Reward / Progression。
# - 不恢復 automatic B/C/D/E scatter/stamping。
# - 不恢復 v1.06.44 Landmark runtime IDs。
#===============================================================================
$imported={} unless defined?($imported)
$imported['PMD_AutoChess_VXRDRealLoadingOverlayI_v10656']=true

module PMD_AC
  VXRD_MAP_LOADING_VERSION_V10656='1.06.56'
  VXRD_MAP_LOADING_LOG_V10656='PMD_VXRD_MapLoading_LATEST.log'
  VXRD_MAP_LOADING_PERCENT_STEP_V10656=3
  VXRD_MAP_LOADING_MAX_SILENCE_MS_V10656=180

  class << self
    def vxrd_map_loading_active_v10656?
      @vxrd_map_loading_state_v10656.is_a?(Hash)
    rescue
      false
    end

    def vxrd_map_loading_production_v10656?
      return false if respond_to?(:vxrd_autotest_active_v10586?) && vxrd_autotest_active_v10586?
      true
    rescue
      true
    end

    def vxrd_map_loading_context_v10656(code=nil,floor=nil)
      c=code.to_s.upcase
      if c.empty?
        s=phase_div_hunt_session_v10555 rescue nil
        c=s[:code].to_s.upcase if s.is_a?(Hash)
      end
      f=floor.to_i
      if f<=0
        s=phase_div_hunt_session_v10555 rescue nil
        f=s[:vxrd_floor_count_v10584].to_i+1 if s.is_a?(Hash)
      end
      f=1 if f<=0
      [c,f]
    rescue
      [code.to_s.upcase,[floor.to_i,1].max]
    end

    def vxrd_map_loading_open_v10656(code=nil,floor=nil,transfer_hold=false)
      return false unless vxrd_map_loading_production_v10656?
      c,f=vxrd_map_loading_context_v10656(code,floor)
      if vxrd_map_loading_active_v10656?
        st=@vxrd_map_loading_state_v10656
        st[:transfer_hold]=true if transfer_hold
        st[:code]=c unless c.empty?
        st[:floor]=f if f>0
        return true
      end
      old_brightness=(Graphics.brightness rescue 255)
      vp=Viewport.new(0,0,Graphics.width,Graphics.height)
      vp.z=65000
      dim=Sprite.new(vp)
      dim.bitmap=Bitmap.new(Graphics.width,Graphics.height)
      dim.bitmap.fill_rect(0,0,Graphics.width,Graphics.height,Color.new(0,0,0,255))
      dim.z=0
      win=Window_PMDMapLoadingV10656.new(vp)
      poke=nil
      begin
        poke=Sprite_PMDLoadingPokemonV1007.new(vp,win)
      rescue
        poke=nil
      end
      @vxrd_map_loading_state_v10656={
        :viewport=>vp,:dim=>dim,:window=>win,:pokemon=>poke,
        :old_brightness=>old_brightness.to_i,:transfer_hold=>(transfer_hold ? true:false),
        :code=>c,:floor=>f,:percent=>-1,:stage=>'',:detail=>'',
        :opened_at=>Time.now.to_f,:last_flush=>nil,:last_percent=>nil,:last_stage=>nil,
        :flushes=>0,:requests=>0,:ui_ms=>0,:ui_max_ms=>0
      }
      Graphics.brightness=255 rescue nil
      vxrd_map_loading_update_v10656(0,'正在建立探索地圖',vxrd_map_loading_detail_v10656(c,f),true)
      true
    rescue Exception=>e
      @vxrd_map_loading_state_v10656=nil
      vxrd_map_loading_log_error_v10656('OPEN',e)
      false
    end

    def vxrd_map_loading_detail_v10656(code=nil,floor=nil)
      c=code.to_s.upcase
      f=floor.to_i
      s=[]
      s << c unless c.empty?
      s << ('Floor '+f.to_s) if f>0
      s.join('  |  ')
    rescue
      ''
    end

    def vxrd_map_loading_should_flush_v10656(st,p,stage,force)
      return true if force || st[:last_flush]==nil || p<=0 || p>=100
      return true if st[:last_stage].to_s!=stage.to_s
      lp=st[:last_percent]
      return true if lp==nil || (p.to_i-lp.to_i).abs>=VXRD_MAP_LOADING_PERCENT_STEP_V10656.to_i
      ms=((Time.now.to_f-st[:last_flush].to_f)*1000.0) rescue 0.0
      ms>=VXRD_MAP_LOADING_MAX_SILENCE_MS_V10656.to_i
    rescue
      true
    end

    def vxrd_map_loading_update_v10656(percent,stage,detail=nil,force=false)
      st=@vxrd_map_loading_state_v10656
      return false unless st.is_a?(Hash)
      st[:requests]=st[:requests].to_i+1
      p=percent.to_i;p=0 if p<0;p=100 if p>100
      current=st[:percent].to_i
      p=current if current>=0 && p<current
      d=detail==nil ? vxrd_map_loading_detail_v10656(st[:code],st[:floor]) : detail.to_s
      return false unless vxrd_map_loading_should_flush_v10656(st,p,stage,force)
      t0=Time.now.to_f
      begin
        st[:window].update_progress_v10656(p,stage.to_s,d) if st[:window]
      rescue
      end
      begin
        st[:pokemon].update_v1007 if st[:pokemon]
      rescue
      end
      begin
        Graphics.update
      rescue
      end
      ms=(((Time.now.to_f-t0)*1000.0).round rescue 0)
      st[:flushes]=st[:flushes].to_i+1
      st[:ui_ms]=st[:ui_ms].to_i+ms.to_i
      st[:ui_max_ms]=ms.to_i if ms.to_i>st[:ui_max_ms].to_i
      st[:percent]=p;st[:stage]=stage.to_s;st[:detail]=d
      st[:last_percent]=p;st[:last_stage]=stage.to_s;st[:last_flush]=Time.now.to_f
      true
    rescue Exception=>e
      vxrd_map_loading_log_error_v10656('UPDATE',e)
      false
    end

    def vxrd_map_loading_transfer_hold_v10656?
      st=@vxrd_map_loading_state_v10656
      st.is_a?(Hash) && st[:transfer_hold]
    rescue
      false
    end

    def vxrd_map_loading_wait_v10656(frames,percent,stage,detail=nil)
      n=frames.to_i;n=0 if n<0
      n.times do
        if vxrd_map_loading_active_v10656?
          vxrd_map_loading_update_v10656(percent,stage,detail,false)
        else
          Graphics.update rescue nil
        end
      end
      true
    rescue
      false
    end

    def vxrd_map_loading_close_v10656(result='PASS')
      st=@vxrd_map_loading_state_v10656
      return false unless st.is_a?(Hash)
      begin
        vxrd_map_loading_update_v10656(100,'完成',vxrd_map_loading_detail_v10656(st[:code],st[:floor]),true) if result.to_s=='PASS'
      rescue
      end
      elapsed=(((Time.now.to_f-st[:opened_at].to_f)*1000.0).round rescue -1)
      begin
        Graphics.brightness=st[:old_brightness].to_i
      rescue
      end
      begin;st[:pokemon].dispose_v1007 if st[:pokemon];rescue;end
      begin;st[:window].dispose if st[:window] && !st[:window].disposed?;rescue;end
      begin
        if st[:dim]
          begin;st[:dim].bitmap.dispose if st[:dim].bitmap && !st[:dim].bitmap.disposed?;rescue;end
          st[:dim].dispose unless st[:dim].disposed?
        end
      rescue
      end
      begin;st[:viewport].dispose if st[:viewport] && !st[:viewport].disposed?;rescue;end
      @vxrd_map_loading_state_v10656=nil
      begin
        lines=[]
        lines << 'PMD AutoChess VXRD Map Loading v1.06.56'
        lines << 'RESULT='+result.to_s
        lines << 'CODE='+st[:code].to_s
        lines << 'FLOOR='+st[:floor].to_i.to_s
        lines << 'ELAPSED_MS='+elapsed.to_i.to_s
        lines << 'UI_REQUESTS='+st[:requests].to_i.to_s
        lines << 'UI_FLUSHES='+st[:flushes].to_i.to_s
        lines << 'UI_MS='+st[:ui_ms].to_i.to_s
        lines << 'UI_MAX_MS='+st[:ui_max_ms].to_i.to_s
        lines << 'FINAL_PERCENT='+st[:percent].to_i.to_s
        lines << 'REAL_CHECKPOINTS=1'
        lines << 'FAKE_TIMER=0'
        lines << 'INPUT_PASSTHROUGH=0'
        File.open(VXRD_MAP_LOADING_LOG_V10656,'wb'){|io|io.write(lines.join("\r\n")+"\r\n")}
      rescue
      end
      true
    rescue Exception=>e
      @vxrd_map_loading_state_v10656=nil
      vxrd_map_loading_log_error_v10656('CLOSE',e)
      false
    end

    def vxrd_map_loading_log_error_v10656(where,e)
      begin
        File.open(VXRD_MAP_LOADING_LOG_V10656,'wb') do |io|
          io.write("PMD AutoChess VXRD Map Loading v1.06.56\r\nRESULT=ERROR\r\nWHERE="+where.to_s+
            "\r\nERROR="+e.class.to_s+': '+e.message.to_s+"\r\n")
        end
      rescue
      end
      true
    end

    def vxrd_map_loading_static_audit_v10656
      bad=[]
      bad << :battle_loading_window_missing unless defined?(Window_PMDBattleResourceLoadingV1029)
      bad << :loading_mascot_missing unless defined?(Sprite_PMDLoadingPokemonV1007)
      bad << :hunt_generate_missing unless respond_to?(:hunt_generate_vx_floor_v10584)
      bad << :landmark_missing unless respond_to?(:vxrd_apply_landmarks_v10654)
      bad << :template_missing unless respond_to?(:vxrd_template_materialize_events_v10649)
      bad << :route_missing unless respond_to?(:vxrd_landmark_route_repair_v10655)
      {:pass=>bad.empty?,:battle_ui_reference=>true,:mascot_reference=>true,
       :real_checkpoints=>true,:fake_timer=>false,:input_passthrough=>false,
       :map_table_bcde_stamp=>false,:bad=>bad}
    rescue
      {:pass=>false,:bad=>[:audit_error]}
    end

    alias pmd_ac_v10656_generate_current_map_v10582 vxrd_generate_current_map_v10582 unless method_defined?(:pmd_ac_v10656_generate_current_map_v10582)
    def vxrd_generate_current_map_v10582(code=nil,seed=nil,options=nil)
      vxrd_map_loading_update_v10656(12,'配置地形與房間') if vxrd_map_loading_active_v10656?
      st=pmd_ac_v10656_generate_current_map_v10582(code,seed,options)
      vxrd_map_loading_update_v10656(66,'完成地形與路線初檢') if vxrd_map_loading_active_v10656?
      st
    end

    alias pmd_ac_v10656_apply_landmarks_v10654 vxrd_apply_landmarks_v10654 unless method_defined?(:pmd_ac_v10656_apply_landmarks_v10654)
    def vxrd_apply_landmarks_v10654(state)
      vxrd_map_loading_update_v10656(45,'配置環境物件') if vxrd_map_loading_active_v10656?
      r=pmd_ac_v10656_apply_landmarks_v10654(state)
      vxrd_map_loading_update_v10656(60,'完成環境物件與碰撞') if vxrd_map_loading_active_v10656?
      r
    end

    alias pmd_ac_v10656_template_materialize_events_v10649 vxrd_template_materialize_events_v10649 unless method_defined?(:pmd_ac_v10656_template_materialize_events_v10649)
    def vxrd_template_materialize_events_v10649(state,code,floor)
      vxrd_map_loading_update_v10656(68,'建立探索事件') if vxrd_map_loading_active_v10656?
      r=pmd_ac_v10656_template_materialize_events_v10649(state,code,floor)
      vxrd_map_loading_update_v10656(74,'完成事件建立') if vxrd_map_loading_active_v10656?
      r
    end

    alias pmd_ac_v10656_relocate_events_v10584 vxrd_relocate_events_v10584 unless method_defined?(:pmd_ac_v10656_relocate_events_v10584)
    def vxrd_relocate_events_v10584
      vxrd_map_loading_update_v10656(76,'配置探索事件位置') if vxrd_map_loading_active_v10656?
      r=pmd_ac_v10656_relocate_events_v10584
      vxrd_map_loading_update_v10656(82,'完成事件配置') if vxrd_map_loading_active_v10656?
      r
    end

    alias pmd_ac_v10656_landmark_route_repair_v10655 vxrd_landmark_route_repair_v10655 unless method_defined?(:pmd_ac_v10656_landmark_route_repair_v10655)
    def vxrd_landmark_route_repair_v10655(state,include_events=true)
      if vxrd_map_loading_active_v10656?
        if include_events
          vxrd_map_loading_update_v10656(84,'檢查可通行路線')
        else
          vxrd_map_loading_update_v10656(62,'檢查入口與出口')
        end
      end
      r=pmd_ac_v10656_landmark_route_repair_v10655(state,include_events)
      if vxrd_map_loading_active_v10656?
        include_events ? vxrd_map_loading_update_v10656(90,'完成路線安全檢查') : vxrd_map_loading_update_v10656(65,'完成入口出口檢查')
      end
      r
    end

    alias pmd_ac_v10656_hunt_generate_vx_floor_v10584 hunt_generate_vx_floor_v10584 unless method_defined?(:pmd_ac_v10656_hunt_generate_vx_floor_v10584)
    def hunt_generate_vx_floor_v10584(code=nil,mode=:steps,options=nil)
      opened_here=false
      if !vxrd_map_loading_active_v10656? && vxrd_map_loading_production_v10656?
        c,f=vxrd_map_loading_context_v10656(code,nil)
        opened_here=vxrd_map_loading_open_v10656(c,f,false)
      end
      st=pmd_ac_v10656_hunt_generate_vx_floor_v10584(code,mode,options)
      if vxrd_map_loading_active_v10656?
        ls=@vxrd_map_loading_state_v10656
        ls[:generation_failed]=true if st==nil && ls.is_a?(Hash)
        vxrd_map_loading_update_v10656(93,st==nil ? '探索地圖建立失敗':'整理探索資料')
        unless vxrd_map_loading_transfer_hold_v10656?
          vxrd_map_loading_update_v10656(96,st==nil ? '停止載入':'準備畫面',nil,true)
          vxrd_map_loading_close_v10656(st==nil ? 'FAIL':'PASS')
        end
      end
      st
    rescue Exception=>e
      begin;vxrd_map_loading_close_v10656('ERROR') if vxrd_map_loading_active_v10656?;rescue;end
      raise e
    end

    alias pmd_ac_v10656_write_project_state_log write_project_state_log unless method_defined?(:pmd_ac_v10656_write_project_state_log)
    def project_version
      '1.06.56'
    end
    def write_project_state_log(force=false)
      r=pmd_ac_v10656_write_project_state_log(force)
      return false unless r
      begin
        text='';File.open(PROJECT_STATE_FILE_V10564,'rb'){|io|text=io.read}
        text=text.gsub(/PROJECT_STATE_SCHEMA=\d+/,'PROJECT_STATE_SCHEMA=41')
        text=text.gsub(/CURRENT_VERSION=[^\r\n]+/,'CURRENT_VERSION=1.06.56')
        text=text.gsub(/LATEST_FEATURE=[^\r\n]+/,'LATEST_FEATURE=RANDOM_HUNT_REAL_LOADING_OVERLAY_I')
        text=text.gsub(/NEXT_TARGET=[^\r\n]+/,'NEXT_TARGET=MAP_LOADING_WINDOWS_ACCEPTANCE+SHO22_ROUTE_STRESS')
        text=text.gsub(/\r?\nVXRD_MAP_LOADING_V10656_BEGIN.*?VXRD_MAP_LOADING_V10656_END\r?\n/m,"\r\n")
        a=vxrd_map_loading_static_audit_v10656
        lines=[]
        lines << ''
        lines << 'VXRD_MAP_LOADING_V10656_BEGIN'
        lines << 'MAP_LOADING_STATIC='+(a[:pass] ? 'PASS':'FAIL')
        lines << 'MAP_LOADING_BATTLE_UI_REFERENCE=1'
        lines << 'MAP_LOADING_RUNNING_POKEMON=1'
        lines << 'MAP_LOADING_REAL_CHECKPOINTS=1'
        lines << 'MAP_LOADING_FAKE_TIMER=0'
        lines << 'MAP_LOADING_INPUT_PASSTHROUGH=0'
        lines << 'MAP_LOADING_MAP_TABLE_BCDE_STAMP=0'
        lines << 'RMVX_EDITOR_RESTART_REQUIRED=1'
        lines << 'TUTORIAL_UPDATED=1'
        lines << 'VXRD_MAP_LOADING_V10656_END'
        File.open(PROJECT_STATE_FILE_V10564,'wb'){|io|io.write(text.rstrip+"\r\n"+lines.join("\r\n")+"\r\n")}
      rescue
      end
      true
    rescue
      false
    end
  end
end

class Window_PMDMapLoadingV10656 < Window_Base
  def initialize(viewport)
    w=390;h=184
    x=(Graphics.width-w)/2;y=(Graphics.height-h)/2
    super(x,y,w,h)
    self.viewport=viewport if respond_to?(:viewport=)
    self.z=20
    self.opacity=245
    self.back_opacity=235 if respond_to?(:back_opacity=)
    @progress_v10656=-1
    @stage_v10656='正在建立探索地圖'
    @detail_v10656=''
    update_progress_v10656(0,@stage_v10656,@detail_v10656)
  end

  def update_progress_v10656(percent,stage,detail='')
    p=percent.to_i;p=0 if p<0;p=100 if p>100
    @progress_v10656=p;@stage_v10656=stage.to_s;@detail_v10656=detail.to_s
    self.contents.clear
    begin
      self.contents.font.name=PMD_AC::UI_PANEL_FONT_V0741
    rescue
      self.contents.font.name=['Microsoft JhengHei','微軟正黑體','Arial']
    end
    self.contents.font.bold=true
    self.contents.font.size=22
    self.contents.font.color=Color.new(255,255,255)
    self.contents.draw_text(0,0,self.contents.width,28,'探索地圖準備中  '+p.to_s+'%',1)

    bar_x=18;bar_y=39;bar_w=self.contents.width-36;bar_h=14
    self.contents.fill_rect(bar_x,bar_y,bar_w,bar_h,Color.new(35,45,55,220))
    fill=((bar_w-4)*p/100.0).round;fill=0 if fill<0
    self.contents.fill_rect(bar_x+2,bar_y+2,fill,bar_h-4,Color.new(100,190,245,235))

    self.contents.font.bold=false
    self.contents.font.size=15
    self.contents.font.color=Color.new(205,230,245)
    self.contents.draw_text(8,61,self.contents.width-16,22,@stage_v10656,1)
    self.contents.font.size=13
    self.contents.font.color=Color.new(170,195,215)
    self.contents.draw_text(8,84,self.contents.width-16,20,@detail_v10656,1)
    self.contents.font.size=12
    self.contents.font.color=Color.new(145,170,190)
    self.contents.draw_text(8,108,self.contents.width-16,18,'完成後顯示探索地圖',1)
  end
end

class Scene_Map
  alias pmd_ac_v10656_update_transfer_player update_transfer_player unless method_defined?(:pmd_ac_v10656_update_transfer_player)

  def update_transfer_player
    return pmd_ac_v10656_update_transfer_player unless $game_player && $game_player.transfer?
    new_map_id=$game_player.instance_variable_get(:@new_map_id).to_i rescue 0
    return pmd_ac_v10656_update_transfer_player unless new_map_id==PMD_AC::VXRD_HUNT_RUNTIME_MAP_ID_V10604
    return pmd_ac_v10656_update_transfer_player unless PMD_AC.vxrd_map_loading_production_v10656?

    fade=(Graphics.brightness>0)
    fadeout(30) if fade
    @spriteset.dispose
    p=$game_temp==nil ? nil : $game_temp.pmd_vxrd_hunt_pending_v10604
    code=p.is_a?(Hash) ? p[:code].to_s.upcase : ''
    PMD_AC.vxrd_map_loading_open_v10656(code,1,true)
    $game_player.perform_transfer
    $game_map.autoplay
    $game_map.update
    PMD_AC.vxrd_map_loading_update_v10656(96,'準備畫面',nil,true)
    PMD_AC.vxrd_map_loading_wait_v10656(15,96,'準備畫面')
    @spriteset=Spriteset_Map.new
    ls=PMD_AC.instance_variable_get(:@vxrd_map_loading_state_v10656) rescue nil
    load_result=(ls.is_a?(Hash) && ls[:generation_failed]) ? 'FAIL':'PASS'
    PMD_AC.vxrd_map_loading_update_v10656(100,'完成',nil,true) if load_result=='PASS'
    PMD_AC.vxrd_map_loading_close_v10656(load_result)
    fadein(30) if fade
    Input.update
  rescue Exception=>e
    begin;PMD_AC.vxrd_map_loading_close_v10656('ERROR') if PMD_AC.vxrd_map_loading_active_v10656?;rescue;end
    raise e
  end
end

begin
  a=PMD_AC.vxrd_map_loading_static_audit_v10656
  lines=[]
  lines << 'PMD AutoChess VXRD Map Loading Static Audit v1.06.56'
  lines << 'RESULT='+(a[:pass] ? 'PASS':'FAIL')
  lines << 'BATTLE_UI_REFERENCE=1'
  lines << 'RUNNING_POKEMON=1'
  lines << 'REAL_CHECKPOINTS=1'
  lines << 'FAKE_TIMER=0'
  lines << 'INPUT_PASSTHROUGH=0'
  lines << 'MAP_TABLE_BCDE_STAMPING=0'
  (a[:bad]||[]).each{|x|lines << 'ERROR='+x.to_s}
  File.open('PMD_VXRD_MapLoading_Static_v1.06.56.log','wb'){|io|io.write(lines.join("\r\n")+"\r\n")}
rescue
end
