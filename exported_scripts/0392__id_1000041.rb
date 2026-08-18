# encoding: UTF-8
#==============================================================================
# 【PMD AutoChess 中文維護說明】
# 腳本：PMD AutoChess RPG Foundation Standalone Tool Scenes v1.00.4
# 分類：RPG 管理介面／Scene 隔離／效能修正／Party BOX／AI Strategy
# RPG Maker VX / RGSS2 / Ruby 1.8 compatible
#==============================================================================
# 【用途】
# 修正 v1.00~v1.00.3 的 RPG Hub「隊伍／BOX」「AI 編成」不是獨立 Scene，
# 而是先建立完整 Scene_PMD_AutoChess，再把管理面板覆蓋在戰場上所造成的：
# 1. 進入管理頁面明顯卡頓；
# 2. 背景仍是關卡預覽／戰場；
# 3. AI 編成時 Shift 仍可啟動底下的戰鬥；
# 4. 每次進工具頁都重新建立戰鬥單位、戰場 Sprite 與大量 Runtime UI。
#
# 【核心修正】
# - Scene_PMD_RPGPartyV1004：真正獨立的 Party/BOX Scene。
# - Scene_PMD_RPGAIStrategyV1004：真正獨立的 AI Strategy Scene。
# - F8 Hub 的 :party / :ai 直接切換到上述 Scene，不再建立 AutoChess Scene。
# - Party 交換直接呼叫既有 instance_uid storage API，不建立戰鬥 Unit。
# - AI 設定直接編輯 PMD_PokemonInstance#ai_setup，Dynamic Role 直接由個體資料計算。
#
# 【AI Strategy 規則】
# 玩家可調 9 項：
# role_bias / movement / target / threat / skill / spacing / spatial_intent /
# condition_focus / target_commitment。
# 未手動設定時，畫面顯示 Gameplay Review + Basic Flex + Nature Temperament 的
# 實際預設值；修改仍使用既有 set_ai_option / clear_ai_option，所以戰鬥 Runtime
# 不需要任何新格式。
#
# 【操作】
# F8 -> 林緣營地：
# - 隊伍／BOX：←→ 區域、↑↓ 選擇、C 標記/交換、Q/W 換 BOX、B 返回營地。
# - AI 編成：↑↓ 欄位、←→ 調整、C 恢復預設、Q/W 切換隊伍寶可夢、B 返回。
# - Shift 在兩個管理 Scene 中沒有任何戰鬥用途，也不會啟動戰鬥。
#
# 【效能 LOG】
# 實際 Scene 開啟／關閉時間寫入：
#   PMD_RPGToolScenePerf_v1.00.4.log
# 用於判斷仍有哪些 RPG 管理頁面需要做獨立 Scene／快取。
#
# 【Verifier】
# S 一次 -> RPG_FOUNDATION_V100 -> Shift。
# 新增：
#   RPG_TOOL_SCENE_ISOLATION_V1004
#   RPG_TOOL_SCENE_RENDER_V1004
# 驗證 Party/AI 都是 Scene_Base 子類、不是 AutoChess、沒有 start_battle 路徑，
# 並真的建立與銷毀兩個管理 Scene。
#
# 【維護限制】
# - 不直接修改 Frozen Combat Core。
# - 不修改傷害公式、Attack Speed、Basic Flex、Nature、Dynamic Role 計算。
# - Pokémon identity 一律使用 instance_uid，不以 Actor ID 當個體。
#==============================================================================
module PMD_AC
  RPG_TOOL_PERF_LOG_V1004='PMD_RPGToolScenePerf_v1.00.4.log'

  class << self
    def rpg_tool_time_ms_v1004(t0)
      begin
        return ((Time.now.to_f-t0.to_f)*1000.0).round
      rescue
        return -1
      end
    end

    def rpg_tool_perf_log_v1004(text)
      begin
        File.open(RPG_TOOL_PERF_LOG_V1004,'ab') do |f|
          stamp=Time.now.strftime('%Y-%m-%d %H:%M:%S') rescue 'time'
          f.write('['+stamp+'] '+text.to_s+"\r\n")
        end
        true
      rescue
        false
      end
    end

    def rpg_tool_party_swap_v1004(slot,storage_uid)
      before=party_instance_v045(slot)
      incoming=pokemon_instance_for_uid_v045(storage_uid)
      return false if before==nil || incoming==nil
      old_uid=before.instance_uid.to_i
      ok=swap_party_with_storage_v045(slot,storage_uid)
      if ok
        rpg_tool_perf_log_v1004('PARTY_SWAP slot='+(slot.to_i+1).to_s+
          ' in='+storage_uid.to_i.to_s+' out='+old_uid.to_s+' identity=instance_uid')
      end
      ok
    end

    def rpg_ai_review_profile_v1004(inst)
      return {} if inst==nil
      fk=inst.respond_to?(:form_key) ? inst.form_key : :normal
      p=respond_to?(:review_profile_for_v09911) ? review_profile_for_v09911(inst.species_key,fk) : nil
      p || {}
    end

    def rpg_ai_effective_value_v1004(inst,key)
      return nil if inst==nil
      setup=inst.ai_setup || {}
      review=rpg_ai_review_profile_v1004(inst)
      case key
      when :role_bias
        return setup[:role_bias] || :auto
      when :movement_policy
        return setup[:movement_policy] || review[:movement_policy] || :frontline
      when :target_policy
        return setup[:target_policy] || review[:target_policy] || :nearest
      when :threat_policy
        return setup[:threat_policy] || review[:threat_policy] || :normal
      when :skill_policy
        return setup[:skill_policy] || review[:skill_policy] || :current_target
      when :spacing_policy
        return setup[:spacing_policy] || :species_default
      when :spatial_intent
        return setup[:spatial_intent] || :balanced
      when :condition_focus
        v=setup[:condition_focus]
        return respond_to?(:normalize_condition_focus_v09915) ? normalize_condition_focus_v09915(v) : (v || :auto)
      when :target_commitment
        return clamp(setup[:target_commitment].to_i,0,100) if setup[:target_commitment]!=nil
        base=(review[:target_commitment] || 60).to_i
        off=respond_to?(:temperament_commitment_offset_v09916) ? temperament_commitment_offset_v09916(inst.nature_key).to_i : 0
        return clamp(base+off,0,100)
      end
      nil
    end

    def rpg_ai_rows_v1004
      if const_defined?(:AI_STRATEGY_ROWS_V09915)
        return AI_STRATEGY_ROWS_V09915
      end
      AI_STRATEGY_ROWS_V09913
    end

    def rpg_ai_row_label_v1004(key)
      if const_defined?(:AI_STRATEGY_ROW_LABELS_V09915)
        return AI_STRATEGY_ROW_LABELS_V09915[key] || key.to_s
      end
      AI_STRATEGY_ROW_LABELS_V09913[key] || key.to_s
    end

    def rpg_ai_instance_name_v1004(inst)
      return '---' if inst==nil
      begin
        return species_display_name_v047(inst.species_key)
      rescue
        return inst.species_key.to_s
      end
    end

    def rpg_ai_move_name_v1004(mv)
      begin
        return move_display_name_v047(mv)
      rescue
        return mv.to_s
      end
    end

    # [total, party_render, ai_render, lifecycle, detail]
    def rpg_tool_scene_smoke_v1004
      party=nil
      ai=nil
      party_ok=false
      ai_ok=false
      life_ok=false
      err=''
      begin
        party=Scene_PMD_RPGPartyV1004.new
        party.start
        ps=party.instance_variable_get(:@panel)
        party_ok=ps!=nil && ps.bitmap!=nil
        party.terminate
        party=nil

        ai=Scene_PMD_RPGAIStrategyV1004.new
        ai.start
        sp=ai.instance_variable_get(:@sprite)
        ai_ok=sp!=nil && sp.bitmap!=nil
        ai.terminate
        ai=nil
        life_ok=true
      rescue Exception => e
        err=e.class.to_s+': '+e.message.to_s
      ensure
        begin; party.terminate if party; rescue; end
        begin; ai.terminate if ai; rescue; end
      end
      [party_ok && ai_ok && life_ok,party_ok,ai_ok,life_ok,err]
    end
  end
end

#==============================================================================
# ■ Scene_PMD_RPGPartyV1004
# 真正獨立的隊伍／BOX Scene。完全不建立 Scene_PMD_AutoChess。
#==============================================================================
class Scene_PMD_RPGPartyV1004 < Scene_Base
  def start
    super
    t=Time.now.to_f
    PMD_AC.rpg_tool_perf_log_v1004('OPEN_BEGIN tool=party standalone=1 autochess=0')
    swapper=Proc.new{|slot,uid|PMD_AC.rpg_tool_party_swap_v1004(slot,uid)}
    @panel=Sprite_PMDPartyStoragePanelV078.new(nil,swapper)
    ms=PMD_AC.rpg_tool_time_ms_v1004(t)
    PMD_AC.rpg_tool_perf_log_v1004('OPEN_END tool=party ms='+ms.to_s+' standalone=1 battle_scene=0 units_created=0 preview_created=0')
  end

  def update
    super
    return if @panel==nil
    @panel.update
    if @panel.close_requested
      PMD_AC.rpg_tool_perf_log_v1004('CLOSE_REQUEST tool=party return=hub')
      $scene=Scene_PMD_RPGFoundationV100.new
    end
  end

  def terminate
    t=Time.now.to_f
    super
    p=@panel
    if p
      begin
        bmp=p.bitmap
        bmp.dispose if bmp && !bmp.disposed?
      rescue
      end
      begin
        p.dispose unless p.disposed?
      rescue
        begin;p.dispose;rescue;end
      end
    end
    @panel=nil
    PMD_AC.rpg_tool_perf_log_v1004('TERMINATE tool=party ms='+PMD_AC.rpg_tool_time_ms_v1004(t).to_s)
  end
end

#==============================================================================
# ■ Scene_PMD_RPGAIStrategyV1004
# 直接編輯 PMD_PokemonInstance，不建立任何戰鬥 Unit／敵人／Preview。
#==============================================================================
class Scene_PMD_RPGAIStrategyV1004 < Scene_Base
  def start
    super
    t=Time.now.to_f
    PMD_AC.rpg_tool_perf_log_v1004('OPEN_BEGIN tool=ai standalone=1 autochess=0')
    @party_index=0
    @row=0
    @sprite=Sprite.new
    @sprite.bitmap=Bitmap.new(Graphics.width,Graphics.height)
    @sprite.z=16000
    normalize_party_index_v1004
    refresh_v1004
    PMD_AC.rpg_tool_perf_log_v1004('OPEN_END tool=ai ms='+PMD_AC.rpg_tool_time_ms_v1004(t).to_s+
      ' standalone=1 battle_scene=0 units_created=0 preview_created=0')
  end

  def terminate
    t=Time.now.to_f
    super
    s=@sprite
    if s
      begin
        bmp=s.bitmap
        bmp.dispose if bmp && !bmp.disposed?
      rescue
      end
      begin
        s.dispose unless s.disposed?
      rescue
        begin;s.dispose;rescue;end
      end
    end
    @sprite=nil
    PMD_AC.rpg_tool_perf_log_v1004('TERMINATE tool=ai ms='+PMD_AC.rpg_tool_time_ms_v1004(t).to_s)
  end

  def party_v1004
    PMD_AC.party_instances_v078
  end

  def normalize_party_index_v1004
    p=party_v1004
    return @party_index=0 if p.empty?
    @party_index=0 if @party_index<0 || @party_index>=p.size
    if p[@party_index]==nil
      found=nil
      p.each_with_index{|inst,i|found=i if found==nil && inst!=nil}
      @party_index=found || 0
    end
  end

  def instance_v1004
    p=party_v1004
    return nil if p.empty?
    p[@party_index]
  end

  def change_party_v1004(dir)
    p=party_v1004
    return if p.empty?
    start=@party_index
    loop do
      @party_index=(@party_index+dir)%p.size
      break if p[@party_index]!=nil || @party_index==start
    end
    @row=0
    Sound.play_cursor
    refresh_v1004
  end

  def change_value_v1004(dir)
    inst=instance_v1004
    return if inst==nil
    rows=PMD_AC.rpg_ai_rows_v1004
    key=rows[@row]
    current=PMD_AC.rpg_ai_effective_value_v1004(inst,key)
    if key==:target_commitment
      value=PMD_AC.clamp(current.to_i+dir.to_i*5,0,100)
      inst.set_ai_option(key,value)
    else
      vals=PMD_AC.strategy_values_v09913(key)
      return if vals==nil || vals.empty?
      idx=vals.index(current)
      idx=0 if idx==nil
      idx=(idx+dir.to_i)%vals.size
      inst.set_ai_option(key,vals[idx])
    end
    PMD_AC.rpg_tool_perf_log_v1004('AI_CHANGE uid='+inst.instance_uid.to_i.to_s+' key='+key.to_s+
      ' value='+PMD_AC.rpg_ai_effective_value_v1004(inst,key).to_s)
    refresh_v1004
  end

  def reset_value_v1004
    inst=instance_v1004
    return if inst==nil
    key=PMD_AC.rpg_ai_rows_v1004[@row]
    default=PMD_AC.strategy_default_value_v09913(key)
    if default==nil
      inst.clear_ai_option(key)
    else
      inst.set_ai_option(key,default)
    end
    PMD_AC.rpg_tool_perf_log_v1004('AI_RESET uid='+inst.instance_uid.to_i.to_s+' key='+key.to_s)
    refresh_v1004
  end

  def update
    super
    if Input.trigger?(Input::B)
      Sound.play_cancel
      PMD_AC.rpg_tool_perf_log_v1004('CLOSE_REQUEST tool=ai return=hub')
      $scene=Scene_PMD_RPGFoundationV100.new
      return
    end
    if Input.trigger?(Input::L)
      change_party_v1004(-1);return
    elsif Input.trigger?(Input::R)
      change_party_v1004(1);return
    end
    rows=PMD_AC.rpg_ai_rows_v1004
    if Input.repeat?(Input::UP)
      @row-=1;@row=rows.size-1 if @row<0
      Sound.play_cursor;refresh_v1004
    elsif Input.repeat?(Input::DOWN)
      @row+=1;@row=0 if @row>=rows.size
      Sound.play_cursor;refresh_v1004
    elsif Input.repeat?(Input::LEFT)
      Sound.play_cursor;change_value_v1004(-1)
    elsif Input.repeat?(Input::RIGHT)
      Sound.play_cursor;change_value_v1004(1)
    elsif Input.trigger?(Input::C)
      Sound.play_cancel;reset_value_v1004
    end
    # Shift 故意不處理。此 Scene 沒有 battle/deploy phase，也沒有 start_battle。
  end

  def setup_font_v1004(b)
    begin
      b.font.name=PMD_AC::UI_PANEL_FONT_V0741
    rescue
      begin;b.font.name=['Microsoft JhengHei','微軟正黑體','Arial'];rescue;end
    end
  end

  def refresh_v1004
    return if @sprite==nil || @sprite.bitmap==nil
    b=@sprite.bitmap;b.clear;setup_font_v1004(b)
    w=Graphics.width;h=Graphics.height
    b.fill_rect(0,0,w,h,Color.new(7,12,19))
    b.fill_rect(10,10,w-20,h-20,Color.new(17,27,39))
    inst=instance_v1004
    if inst==nil
      b.font.size=22;b.font.bold=true;b.font.color=Color.new(255,255,255)
      b.draw_text(20,20,w-40,30,'AI Strategy｜隊伍沒有可編成的寶可夢',0)
      b.font.size=14;b.font.bold=false;b.font.color=Color.new(180,210,230)
      b.draw_text(20,h-42,w-40,24,'B 返回林緣營地',1)
      return
    end

    name=PMD_AC.rpg_ai_instance_name_v1004(inst)
    nature=PMD_AC.respond_to?(:nature_label_v09916) ? PMD_AC.nature_label_v09916(inst.nature_key) : inst.nature_key.to_s
    b.font.bold=true;b.font.size=22;b.font.color=Color.new(255,255,255)
    b.draw_text(20,14,w-40,28,'AI Strategy｜'+name+'  Lv'+inst.level.to_i.to_s,0)
    b.font.bold=false;b.font.size=13;b.font.color=Color.new(170,220,255)
    b.draw_text(20,42,w-40,20,'Q/W 切換隊伍｜Nature '+nature+'｜uid '+inst.instance_uid.to_i.to_s,0)

    scores=PMD_AC.dynamic_role_scores_v09913(inst)
    top=PMD_AC.sorted_role_scores_v09913(scores)[0,3]
    role_text=top.collect{|r|PMD_AC.role_label_v09913(r)+' '+scores[r].to_i.to_s}.join(' / ')
    b.font.size=14;b.font.color=Color.new(255,225,165)
    b.draw_text(20,64,w-40,20,'目前定位：'+role_text,0)

    if PMD_AC.respond_to?(:temperament_axes_v09916)
      ax=PMD_AC.temperament_axes_v09916(inst.nature_key)
      text='個性傾向  攻'+ax[:aggression].to_i.to_s+'  謹'+ax[:caution].to_i.to_s+
        '  機'+ax[:mobility].to_i.to_s+'  援'+ax[:support].to_i.to_s+'  執'+ax[:commitment].to_i.to_s
      b.font.size=12;b.font.color=Color.new(190,210,220)
      b.draw_text(20,84,w-40,18,text,0)
    end

    moves=inst.respond_to?(:active_moves_v045) ? inst.active_moves_v045 : []
    names=moves.collect{|mv|PMD_AC.rpg_ai_move_name_v1004(mv)}
    b.font.size=12;b.font.color=Color.new(200,210,220)
    b.draw_text(20,102,w-40,18,'4招：'+(names.empty? ? '（尚無 Active Move）' : names.join(' / ')),0)

    rows=PMD_AC.rpg_ai_rows_v1004
    y=126;row_h=25
    rows.each_with_index do |key,i|
      sel=i==@row
      b.fill_rect(18,y-1,w-36,row_h-1,Color.new(53,86,116)) if sel
      b.font.size=15;b.font.bold=sel
      b.font.color=sel ? Color.new(255,245,175) : Color.new(235,240,245)
      label=PMD_AC.rpg_ai_row_label_v1004(key)
      value=PMD_AC.rpg_ai_effective_value_v1004(inst,key)
      value_label=PMD_AC.strategy_value_label_v09913(key,value)
      b.draw_text(28,y,190,22,label,0)
      b.draw_text(225,y,w-250,22,value_label,0)
      y+=row_h
    end
    b.font.bold=false;b.font.size=12;b.font.color=Color.new(170,220,255)
    b.draw_text(12,h-32,w-24,20,'↑↓ 欄位｜←→ 調整｜C 恢復預設｜Q/W 換寶可夢｜B 返回營地｜Shift 無戰鬥功能',1)
  end
end

#==============================================================================
# ■ RPG Hub route：Party / AI 不再借用 AutoChess Scene
#==============================================================================
class Scene_PMD_RPGFoundationV100
  alias pmd_ac_v1004_execute_v100 execute_v100 unless method_defined?(:pmd_ac_v1004_execute_v100)
  def execute_v100
    key=PMD_AC::RPG_FOUNDATION_MENU_V100[@index]
    if key==:party
      Sound.play_decision
      PMD_AC.rpg_tool_perf_log_v1004('ROUTE hub->party standalone=1')
      $scene=Scene_PMD_RPGPartyV1004.new
      return
    elsif key==:ai
      Sound.play_decision
      PMD_AC.rpg_tool_perf_log_v1004('ROUTE hub->ai standalone=1')
      $scene=Scene_PMD_RPGAIStrategyV1004.new
      return
    end
    pmd_ac_v1004_execute_v100
  end
end

#==============================================================================
# ■ Hub / Collection timing probe
# 只量測既有 Scene 的 start/terminate，不改它們的內容。
#==============================================================================
class Scene_PMD_RPGFoundationV100
  alias pmd_ac_v1004_perf_start start unless method_defined?(:pmd_ac_v1004_perf_start)
  def start
    t=Time.now.to_f
    PMD_AC.rpg_tool_perf_log_v1004('OPEN_BEGIN tool=hub standalone=1')
    pmd_ac_v1004_perf_start
    PMD_AC.rpg_tool_perf_log_v1004('OPEN_END tool=hub ms='+PMD_AC.rpg_tool_time_ms_v1004(t).to_s+' standalone=1')
  end
end

class Scene_PMDCollectionV093
  alias pmd_ac_v1004_perf_start start unless method_defined?(:pmd_ac_v1004_perf_start)
  alias pmd_ac_v1004_perf_terminate terminate unless method_defined?(:pmd_ac_v1004_perf_terminate)
  def start
    t=Time.now.to_f
    PMD_AC.rpg_tool_perf_log_v1004('OPEN_BEGIN tool=collection standalone=1')
    pmd_ac_v1004_perf_start
    PMD_AC.rpg_tool_perf_log_v1004('OPEN_END tool=collection ms='+PMD_AC.rpg_tool_time_ms_v1004(t).to_s+' standalone=1 battle_scene=0')
  end
  def terminate
    t=Time.now.to_f
    pmd_ac_v1004_perf_terminate
    PMD_AC.rpg_tool_perf_log_v1004('TERMINATE tool=collection ms='+PMD_AC.rpg_tool_time_ms_v1004(t).to_s)
  end
end

#==============================================================================
# ■ AutoChess compatibility：舊 temporary bridge 不再開 Overlay
#==============================================================================
class Scene_PMD_AutoChess
  alias pmd_ac_v1004_setup_rpg_foundation_tool_v100 setup_rpg_foundation_tool_v100 unless method_defined?(:pmd_ac_v1004_setup_rpg_foundation_tool_v100)
  alias pmd_ac_v1004_update_verification_script update_verification_script unless method_defined?(:pmd_ac_v1004_update_verification_script)

  def setup_rpg_foundation_tool_v100
    if $game_temp && $game_temp.pmd_rpg_foundation_tool_v100
      # v1.00.4 之後 Hub 不會再使用這條路。若舊存檔/舊 Scene 留有 flag，
      # 清掉即可，避免再次把管理 Overlay 疊在戰場上。
      old=$game_temp.pmd_rpg_foundation_tool_v100
      $game_temp.pmd_rpg_foundation_tool_v100=nil
      PMD_AC.rpg_tool_perf_log_v1004('LEGACY_TOOL_FLAG_CLEARED tool='+old.to_s+' overlay_blocked=1')
      return
    end
    pmd_ac_v1004_setup_rpg_foundation_tool_v100
  end

  def verify_rpg_tool_scene_isolation_v1004
    return if @verification_done[:rpg_tool_scene_isolation_v1004]
    party_base=(Scene_PMD_RPGPartyV1004.superclass==Scene_Base)
    ai_base=(Scene_PMD_RPGAIStrategyV1004.superclass==Scene_Base)
    party_no_battle=!Scene_PMD_RPGPartyV1004.new.respond_to?(:start_battle)
    ai_no_battle=!Scene_PMD_RPGAIStrategyV1004.new.respond_to?(:start_battle)
    pass=party_base && ai_base && party_no_battle && ai_no_battle
    @rpg_foundation_failed_v100=true unless pass
    log_event(:verify,'RPG_TOOL_SCENE_ISOLATION_V1004 pass='+(pass ? '1':'0')+
      ' party_scene='+(party_base ? '1':'0')+' ai_scene='+(ai_base ? '1':'0')+
      ' autochess_boot=0 shift_battle_path='+(party_no_battle && ai_no_battle ? '0':'1'))
    @verification_done[:rpg_tool_scene_isolation_v1004]=true
  end

  def verify_rpg_tool_scene_render_v1004
    return if @verification_done[:rpg_tool_scene_render_v1004]
    r=PMD_AC.rpg_tool_scene_smoke_v1004
    pass=r[0]
    @rpg_foundation_failed_v100=true unless pass
    detail='party='+(r[1] ? '1':'0')+' ai='+(r[2] ? '1':'0')+' lifecycle='+(r[3] ? '1':'0')
    detail+=' error='+r[4].to_s unless r[4].to_s.empty?
    log_event(:verify,'RPG_TOOL_SCENE_RENDER_V1004 pass='+(pass ? '1':'0')+' '+detail)
    @verification_done[:rpg_tool_scene_render_v1004]=true
  end

  def update_verification_script
    pmd_ac_v1004_update_verification_script
    return unless verification_mode==:rpg_foundation_v100
    f=@verification_frame.to_i
    verify_rpg_tool_scene_isolation_v1004 if f>=144
    verify_rpg_tool_scene_render_v1004 if f>=148
  end
end

PMD_AC.rpg_tool_perf_log_v1004('PATCH v1.00.4 standalone_party=1 standalone_ai=1 autochess_overlay_bridge=disabled')
PMD_AC.log_global(:rpg_foundation,'PATCH v1.00.4 standalone_tool_scenes party_box=1 ai_strategy=1 autochess_boot=0 shift_battle_path=0 performance_log=1') if PMD_AC.respond_to?(:log_global)
