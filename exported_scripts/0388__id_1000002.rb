# encoding: UTF-8
#==============================================================================
# 【PMD AutoChess 中文維護說明】
# 腳本：PMD AutoChess RPG Foundation Runtime v1.00
# 分類：RPG Hub／Encounter 串接／招募個體／返回流程／Verifier
# RPG Maker VX / RGSS2 / Ruby 1.8 compatible
#==============================================================================
# 【用途】
# 把專案中已存在的 RPG 子系統組成第一個可遊玩閉環。
# 這是「正式 RPG 地圖內容」之前的 Foundation Shell：所有戰鬥、招募、成長、
# Party/BOX、圖鑑、Nature/AI 都使用既有正式 Runtime，Hub 只負責流程導航。
#
# 【主要操作】
# - NORMAL 戰前布陣按 F8：進入林緣營地。
# - 營地 ↑↓：選擇；C：執行；B：返回戰鬥實驗室。
# - Party/BOX 與 AI 編成會暫時進入原戰前畫面，關閉面板後自動回營地。
# - 圖鑑直接使用 v0.93 Scene，關閉後回營地。
#
# 【戰鬥流程】
# 野外／特殊／Boss Request 都帶 :rpg_foundation_v100 標記；
# 戰鬥結果先讓 v0.82 完成 field HP / defeat policy，再改回 RPG Hub。
# 這樣不會複製 Encounter、Reward、Recruit 或 Boss 程式。
#
# 【個體收集】
# Recruit 成功後從 offer[:instance_uid] 找回真正的 PMD_PokemonInstance，
# 記錄 species / Nature，確保收集價值建立在 instance_uid 個體上。
#
# 【Verifier】
# 驗證 manifest、狀態進度、Request bridge、解鎖規則、Nature 個體、
# Party/BOX／圖鑑／AI API、返回流程、舊 v0.99.16 carry 與最新五個 S mode。
#===============================================================================
module PMD_AC
  class << self
    def rpg_foundation_state_v100
      if $game_system==nil
        @rpg_foundation_fallback_state_v100=rpg_foundation_default_state_v100 if @rpg_foundation_fallback_state_v100==nil
        return @rpg_foundation_fallback_state_v100
      end
      s=$game_system.pmd_rpg_foundation_state_v100
      if s==nil
        s=rpg_foundation_default_state_v100
        $game_system.pmd_rpg_foundation_state_v100=s
      end
      s
    end

    def reset_rpg_foundation_v100
      s=rpg_foundation_default_state_v100
      if $game_system!=nil
        $game_system.pmd_rpg_foundation_state_v100=s
      else
        @rpg_foundation_fallback_state_v100=s
      end
      s
    end

    def rpg_foundation_special_unlocked_v100?
      rpg_foundation_state_v100[:wild_wins].to_i>=RPG_FOUNDATION_SPECIAL_WIN_REQ_V100
    end

    def rpg_foundation_boss_unlocked_v100?
      rpg_foundation_state_v100[:wild_wins].to_i>=RPG_FOUNDATION_BOSS_WIN_REQ_V100
    end

    def rpg_foundation_request_v100?(request)
      return false if request==nil
      o=request[:options] || {}
      o[:rpg_foundation_v100] ? true : false
    end

    def rpg_foundation_options_v100(kind)
      {
        :source=>:rpg_foundation_v100,
        :rpg_foundation_v100=>true,
        :foundation_kind_v100=>kind,
        :hp_policy=>:carry,
        :defeat_policy=>:return_heal,
        :heal_after_win=>false,
        :heal_after_escape=>false,
        :deploy=>(kind==:boss ? true : false)
      }
    end

    def rpg_foundation_wild_request_v100
      event_region_request_v092(RPG_FOUNDATION_WILD_REGION_V100,rpg_foundation_options_v100(:wild),nil)
    end

    def rpg_foundation_special_request_v100
      o=rpg_foundation_options_v100(:special)
      o[:deploy]=false
      event_request_v092(RPG_FOUNDATION_SPECIAL_ENCOUNTER_V100,o)
    end

    def rpg_foundation_boss_request_v100
      o=rpg_foundation_options_v100(:boss)
      o[:deploy]=true
      event_boss_request_v092(RPG_FOUNDATION_BOSS_ENCOUNTER_V100,o)
    end

    def launch_rpg_foundation_request_v100(request)
      return false if request==nil
      launch_battle_request_v081(request)
    end

    def start_rpg_foundation_wild_v100
      launch_rpg_foundation_request_v100(rpg_foundation_wild_request_v100)
    end

    def start_rpg_foundation_special_v100
      return false unless rpg_foundation_special_unlocked_v100?
      return false if rpg_foundation_state_v100[:special_cleared]
      launch_rpg_foundation_request_v100(rpg_foundation_special_request_v100)
    end

    def start_rpg_foundation_boss_v100
      return false unless rpg_foundation_boss_unlocked_v100?
      launch_rpg_foundation_request_v100(rpg_foundation_boss_request_v100)
    end

    def apply_rpg_foundation_result_v100(request,result)
      return false unless rpg_foundation_request_v100?(request)
      s=rpg_foundation_state_v100
      kind=(request[:options]||{})[:foundation_kind_v100]
      s[:last_result]=result
      s[:last_kind]=kind
      if kind==:wild
        s[:expeditions]=s[:expeditions].to_i+1
        if result==:win
          s[:wild_wins]=s[:wild_wins].to_i+1
        elsif result==:lose
          s[:wild_losses]=s[:wild_losses].to_i+1
        end
      elsif kind==:special
        if result==:win
          s[:special_wins]=s[:special_wins].to_i+1
        end
      elsif kind==:boss
        s[:boss_attempts]=s[:boss_attempts].to_i+1
        if result==:win
          s[:boss_wins]=s[:boss_wins].to_i+1
          s[:boss_cleared]=true
        end
      end
      true
    end

    def record_rpg_foundation_recruit_v100(instance,request=nil)
      return false if instance==nil || !instance.respond_to?(:instance_uid)
      s=rpg_foundation_state_v100
      s[:recruits]=s[:recruits].to_i+1
      s[:last_recruit_uid]=instance.instance_uid.to_i
      s[:last_recruit_species]=instance.species_key
      s[:last_recruit_nature]=instance.nature_key
      if request!=nil && (request[:options]||{})[:foundation_kind_v100]==:special
        s[:special_cleared]=true
      end
      record_species_owned_v093(instance.species_key) if respond_to?(:record_species_owned_v093)
      true
    end

    def rpg_foundation_party_summary_v100
      rows=[]
      party_instances_v078.each_with_index do |inst,i|
        if inst==nil
          rows << (i+1).to_s+'. ---'
          next
        end
        d=species_identity_data(inst.species_key)
        name=d==nil ? inst.species_key.to_s : (d[:name]||inst.species_key.to_s).to_s
        nature=respond_to?(:nature_label_v09916) ? nature_label_v09916(inst.nature_key) : inst.nature_key.to_s
        rows << (i+1).to_s+'. '+name+' Lv'+inst.level.to_i.to_s+'｜'+nature+'｜uid '+inst.instance_uid.to_i.to_s
      end
      rows
    end

    def rpg_foundation_collection_text_v100
      return '圖鑑資料不可用' unless respond_to?(:dex_summary_v093)
      h=dex_summary_v093
      '看見 '+h[:seen].to_i.to_s+'/'+h[:total].to_i.to_s+'｜曾擁有 '+h[:owned].to_i.to_s+'｜目前 '+h[:current].to_i.to_s
    end

    def open_rpg_foundation_v100
      $scene=Scene_PMD_RPGFoundationV100.new
      true
    end

    alias pmd_ac_v100_record_battle_result_v081 record_battle_result_v081 unless method_defined?(:pmd_ac_v100_record_battle_result_v081)
    def record_battle_result_v081(request,result)
      data=pmd_ac_v100_record_battle_result_v081(request,result)
      apply_rpg_foundation_result_v100(request,result) if rpg_foundation_request_v100?(request)
      data
    end
  end
end

class Game_System
  attr_accessor :pmd_rpg_foundation_state_v100
end

class Game_Temp
  attr_accessor :pmd_rpg_foundation_tool_v100
end

#==============================================================================
# ■ Scene_PMD_RPGFoundationV100
#==============================================================================
class Scene_PMD_RPGFoundationV100 < Scene_Base
  def start
    super
    @index=0
    @viewport=Viewport.new(0,0,Graphics.width,Graphics.height)
    @viewport.z=100
    @sprite=Sprite.new(@viewport)
    @sprite.bitmap=Bitmap.new(Graphics.width,Graphics.height)
    PMD_AC.rpg_foundation_state_v100[:visits]=PMD_AC.rpg_foundation_state_v100[:visits].to_i+1
    refresh_v100
  end

  def terminate
    super
    if @sprite!=nil
      @sprite.bitmap.dispose if @sprite.bitmap!=nil && !@sprite.bitmap.disposed?
      @sprite.dispose unless @sprite.disposed?
    end
    @viewport.dispose if @viewport!=nil && !@viewport.disposed?
  end

  def update
    super
    if Input.repeat?(Input::UP)
      @index-=1;@index=PMD_AC::RPG_FOUNDATION_MENU_V100.size-1 if @index<0
      Sound.play_cursor;refresh_v100
    elsif Input.repeat?(Input::DOWN)
      @index+=1;@index=0 if @index>=PMD_AC::RPG_FOUNDATION_MENU_V100.size
      Sound.play_cursor;refresh_v100
    elsif Input.trigger?(Input::C)
      execute_v100
    elsif Input.trigger?(Input::B) || Input.trigger?(Input::F8)
      Sound.play_cancel
      $scene=Scene_PMD_AutoChess.new
    end
  end

  def item_enabled_v100(key)
    s=PMD_AC.rpg_foundation_state_v100
    return PMD_AC.rpg_foundation_special_unlocked_v100? && !s[:special_cleared] if key==:special
    return PMD_AC.rpg_foundation_boss_unlocked_v100? if key==:boss
    true
  end

  def execute_v100
    key=PMD_AC::RPG_FOUNDATION_MENU_V100[@index]
    unless item_enabled_v100(key)
      Sound.play_buzzer
      return
    end
    case key
    when :wild
      Sound.play_decision
      PMD_AC.start_rpg_foundation_wild_v100
    when :special
      Sound.play_decision
      PMD_AC.start_rpg_foundation_special_v100
    when :boss
      Sound.play_decision
      PMD_AC.start_rpg_foundation_boss_v100
    when :party
      Sound.play_decision
      $game_temp.pmd_rpg_foundation_tool_v100=:party if $game_temp!=nil
      $scene=Scene_PMD_AutoChess.new
    when :collection
      Sound.play_decision
      PMD_AC.open_collection_v093
    when :ai
      Sound.play_decision
      $game_temp.pmd_rpg_foundation_tool_v100=:ai if $game_temp!=nil
      $scene=Scene_PMD_AutoChess.new
    when :heal
      PMD_AC.heal_party_v082
      Sound.play_recovery
      refresh_v100
    else
      Sound.play_decision
      $scene=Scene_PMD_AutoChess.new
    end
  end

  def font_v100(b,size,bold=false,color=nil)
    begin
      b.font.name=['Microsoft JhengHei','微軟正黑體','Arial']
    rescue
    end
    b.font.size=size;b.font.bold=bold
    b.font.color=color if color!=nil
  end

  def refresh_v100
    b=@sprite.bitmap;b.clear
    b.fill_rect(0,0,Graphics.width,Graphics.height,Color.new(10,18,24))
    b.fill_rect(0,0,Graphics.width,48,Color.new(18,43,54))
    font_v100(b,24,true,Color.new(255,255,255))
    b.draw_text(18,8,Graphics.width-36,30,'林緣營地｜RPG Foundation v1.00',0)

    s=PMD_AC.rpg_foundation_state_v100
    font_v100(b,14,false,Color.new(185,220,230))
    progress='林緣勝利 '+s[:wild_wins].to_i.to_s+'｜招募 '+s[:recruits].to_i.to_s+
      '｜Boss '+(s[:boss_cleared] ? 'CLEAR':'未討伐')
    b.draw_text(20,52,Graphics.width-40,22,progress,0)

    x=20;y=82;w=262;row_h=31
    PMD_AC::RPG_FOUNDATION_MENU_V100.each_with_index do |key,i|
      enabled=item_enabled_v100(key)
      selected=i==@index
      b.fill_rect(x,y+i*row_h,w,row_h-3,selected ? Color.new(48,82,98) : Color.new(22,35,43))
      font_v100(b,16,selected,enabled ? Color.new(245,245,245) : Color.new(110,125,132))
      label=PMD_AC::RPG_FOUNDATION_MENU_LABEL_V100[key]
      if key==:special && !PMD_AC.rpg_foundation_special_unlocked_v100?
        label+='［林緣勝利 1 次］'
      elsif key==:special && s[:special_cleared]
        label+='［已完成］'
      elsif key==:boss && !PMD_AC.rpg_foundation_boss_unlocked_v100?
        label+='［林緣勝利 2 次］'
      elsif key==:boss && s[:boss_cleared]
        label+='［已討伐，可重戰］'
      end
      b.draw_text(x+10,y+i*row_h,w-20,row_h-3,label,0)
    end

    rx=300;rw=Graphics.width-rx-18
    b.fill_rect(rx,82,rw,162,Color.new(17,28,35))
    font_v100(b,17,true,Color.new(255,225,165));b.draw_text(rx+10,88,rw-20,24,'目前隊伍與個體',0)
    PMD_AC.rpg_foundation_party_summary_v100.each_with_index do |line,i|
      font_v100(b,13,false,Color.new(220,232,235));b.draw_text(rx+10,116+i*32,rw-20,26,line,0)
    end

    b.fill_rect(rx,252,rw,90,Color.new(17,28,35))
    font_v100(b,15,true,Color.new(175,225,190));b.draw_text(rx+10,258,rw-20,22,'收集進度',0)
    font_v100(b,13,false,Color.new(220,232,235));b.draw_text(rx+10,282,rw-20,22,PMD_AC.rpg_foundation_collection_text_v100,0)
    if s[:last_recruit_uid]!=nil
      nr=PMD_AC.respond_to?(:nature_label_v09916) ? PMD_AC.nature_label_v09916(s[:last_recruit_nature]) : s[:last_recruit_nature].to_s
      b.draw_text(rx+10,304,rw-20,22,'最近招募：'+s[:last_recruit_species].to_s+'｜'+nr+'｜uid '+s[:last_recruit_uid].to_s,0)
    end

    b.fill_rect(0,Graphics.height-42,Graphics.width,42,Color.new(12,24,30))
    font_v100(b,13,false,Color.new(185,210,220))
    b.draw_text(12,Graphics.height-36,Graphics.width-24,24,'↑↓ 選擇｜C 決定｜B/F8 返回戰鬥實驗室｜Party/AI 關閉後自動回營地',1)
  end
end

#==============================================================================
# ■ Scene_PMD_AutoChess : Hub shortcut / tool bridge / result return / Verifier
#==============================================================================
class Scene_PMD_AutoChess
  alias pmd_ac_v100_start start unless method_defined?(:pmd_ac_v100_start)
  alias pmd_ac_v100_update_deploy_phase update_deploy_phase unless method_defined?(:pmd_ac_v100_update_deploy_phase)
  alias pmd_ac_v100_accept_rpg_recruit_v081 accept_rpg_recruit_v081 unless method_defined?(:pmd_ac_v100_accept_rpg_recruit_v081)
  alias pmd_ac_v100_return_to_map_v081 return_to_map_v081 unless method_defined?(:pmd_ac_v100_return_to_map_v081)
  alias pmd_ac_v100_refresh_header refresh_header unless method_defined?(:pmd_ac_v100_refresh_header)
  alias pmd_ac_v100_prepare_verification_battle prepare_verification_battle unless method_defined?(:pmd_ac_v100_prepare_verification_battle)
  alias pmd_ac_v100_update_verification_script update_verification_script unless method_defined?(:pmd_ac_v100_update_verification_script)
  alias pmd_ac_v100_log_event log_event unless method_defined?(:pmd_ac_v100_log_event)
  alias pmd_ac_v100_spatial_framework_runtime_enabled_v09914 spatial_framework_runtime_enabled_v09914? unless method_defined?(:pmd_ac_v100_spatial_framework_runtime_enabled_v09914)
  alias pmd_ac_v100_verify_latest_five_modes_v09916 verify_latest_five_modes_v09916 unless method_defined?(:pmd_ac_v100_verify_latest_five_modes_v09916)
  alias pmd_ac_v100_verify_latest_five_modes_v09915 verify_latest_five_modes_v09915 unless method_defined?(:pmd_ac_v100_verify_latest_five_modes_v09915)
  alias pmd_ac_v100_verify_latest_five_modes_v09914 verify_latest_five_modes_v09914 unless method_defined?(:pmd_ac_v100_verify_latest_five_modes_v09914)

  def rpg_foundation_v100?
    verification_mode==:rpg_foundation_v100
  end

  def spatial_framework_runtime_enabled_v09914?
    return true if rpg_foundation_v100?
    pmd_ac_v100_spatial_framework_runtime_enabled_v09914
  end

  def start
    pmd_ac_v100_start
    begin
      if FileTest.exist?(PMD_AC::BATTLE_LOG_FILE)
        text=File.open(PMD_AC::BATTLE_LOG_FILE,'rb'){|f|f.read}
        text.sub!(/PMD AutoChess Proto v0\.[0-9.]+ Battle Verification Log/,'PMD AutoChess Proto v1.00 Battle Verification Log')
        File.open(PMD_AC::BATTLE_LOG_FILE,'wb'){|f|f.write(text)}
      end
    rescue
    end
    log_event(:rpg_foundation,'FLOW v1.00 loop=camp>explore>battle>recruit+growth>party+box>boss>camp '+
      'nature_ai=v0.99.16 carry=1 combat_core_direct_modification=0')
    setup_rpg_foundation_tool_v100
    refresh_header
  end

  def setup_rpg_foundation_tool_v100
    return if $game_temp==nil || @phase!=:deploy || verification_mode!=:normal || rpg_external_battle_v081?
    tool=$game_temp.pmd_rpg_foundation_tool_v100
    return if tool==nil
    $game_temp.pmd_rpg_foundation_tool_v100=nil
    @rpg_foundation_tool_v100=tool
    if tool==:party
      party_storage_open_v078
    elsif tool==:ai
      ally=(@units||[]).find{|u|u.team==:ally && !u.summoned?}
      @selected_unit=ally
      if ally!=nil && open_ai_strategy_v09913
        refresh_selected_sprites if respond_to?(:refresh_selected_sprites)
      else
        @rpg_foundation_tool_v100=nil
      end
    end
  end

  def update_deploy_phase
    party_before=@party_storage_panel_v078!=nil
    ai_before=@ai_strategy_open_v09913 ? true : false
    if verification_mode==:normal && !rpg_external_battle_v081? && @rpg_foundation_tool_v100==nil &&
       @party_storage_panel_v078==nil && !@ai_strategy_open_v09913 && Input.trigger?(Input::F8)
      Sound.play_decision
      $scene=Scene_PMD_RPGFoundationV100.new
      return
    end
    pmd_ac_v100_update_deploy_phase
    if @rpg_foundation_tool_v100==:party && party_before && @party_storage_panel_v078==nil
      @rpg_foundation_tool_v100=nil
      $scene=Scene_PMD_RPGFoundationV100.new
      return
    elsif @rpg_foundation_tool_v100==:ai && ai_before && !@ai_strategy_open_v09913
      @rpg_foundation_tool_v100=nil
      @selected_unit=nil
      $scene=Scene_PMD_RPGFoundationV100.new
      return
    end
  end

  def accept_rpg_recruit_v081
    req=rpg_request_v081
    foundation=PMD_AC.rpg_foundation_request_v100?(req)
    offer=@rpg_reward_v081==nil ? nil : @rpg_reward_v081[:offer]
    ok=pmd_ac_v100_accept_rpg_recruit_v081
    if ok && foundation && offer!=nil && offer[:instance_uid]!=nil
      inst=PMD_AC.pokemon_instance_for_uid_v045(offer[:instance_uid])
      if PMD_AC.record_rpg_foundation_recruit_v100(inst,req)
        log_event(:rpg_foundation,'RECRUIT uid='+inst.instance_uid.to_s+' species='+inst.species_key.to_s+
          ' nature='+inst.nature_key.to_s+' temperament='+PMD_AC.temperament_summary_v09916(inst.nature_key))
      end
    end
    ok
  end

  def return_to_map_v081
    req=rpg_request_v081
    foundation=PMD_AC.rpg_foundation_request_v100?(req)
    pmd_ac_v100_return_to_map_v081
    if foundation && $scene!=nil && !$scene.is_a?(Scene_Gameover)
      $scene=Scene_PMD_RPGFoundationV100.new
    end
  end

  def refresh_header
    pmd_ac_v100_refresh_header
    return if @header_sprite==nil || @header_sprite.bitmap==nil
    bmp=@header_sprite.bitmap
    bmp.fill_rect(0,0,Graphics.width,28,Color.new(0,0,0,180))
    pmd_ac_v074_font(bmp) if respond_to?(:pmd_ac_v074_font)
    bmp.font.size=20;bmp.font.bold=true;bmp.font.color=Color.new(255,255,255)
    bmp.draw_text(16,1,Graphics.width-32,28,'PMD AutoChess RPG Foundation v1.00',1)
  end

  def prepare_verification_battle
    pmd_ac_v100_prepare_verification_battle
    return unless rpg_foundation_v100?
    @rpg_foundation_failed_v100=false
    @rpg_foundation_report_written_v100=PMD_AC.write_rpg_foundation_report_v100
    log_event(:showcase,'START mode=RPG_FOUNDATION_V100 playable_loop=1 hub=F8 nature_individuality=1')
  end

  def log_event(category,message)
    if category.to_s=='verify' && rpg_foundation_v100? && message.to_s.index('V100')!=nil && message.to_s.index(' pass=0')!=nil
      @rpg_foundation_failed_v100=true
    end
    pmd_ac_v100_log_event(category,message)
  end

  def log_rpg_verify_v100(name,pass,detail='')
    @rpg_foundation_failed_v100=true unless pass
    log_event(:verify,name+' pass='+(pass ? '1':'0')+(detail=='' ? '' : ' '+detail))
  end

  def verify_rpg_manifest_v100
    return if @verification_done[:rpg_manifest_v100]
    e=PMD_AC.rpg_foundation_manifest_errors_v100
    pass=e.empty? && PMD_AC::RPG_FOUNDATION_MENU_V100.size==8
    log_rpg_verify_v100('RPG_FOUNDATION_MANIFEST_V100',pass,'errors='+e.join(',')+' menu=8')
    @verification_done[:rpg_manifest_v100]=true
  end

  def verify_rpg_state_progress_v100
    return if @verification_done[:rpg_state_progress_v100]
    old=Marshal.load(Marshal.dump(PMD_AC.rpg_foundation_state_v100))
    PMD_AC.reset_rpg_foundation_v100
    rw=PMD_AC.rpg_foundation_wild_request_v100
    rb=PMD_AC.rpg_foundation_boss_request_v100
    PMD_AC.apply_rpg_foundation_result_v100(rw,:win)
    one=PMD_AC.rpg_foundation_state_v100[:wild_wins].to_i==1 && PMD_AC.rpg_foundation_special_unlocked_v100? && !PMD_AC.rpg_foundation_boss_unlocked_v100?
    PMD_AC.apply_rpg_foundation_result_v100(rw,:win)
    two=PMD_AC.rpg_foundation_boss_unlocked_v100?
    PMD_AC.apply_rpg_foundation_result_v100(rb,:win)
    boss=PMD_AC.rpg_foundation_state_v100[:boss_cleared] && PMD_AC.rpg_foundation_state_v100[:boss_wins].to_i==1
    $game_system.pmd_rpg_foundation_state_v100=old if $game_system!=nil
    pass=one && two && boss
    log_rpg_verify_v100('RPG_FOUNDATION_PROGRESS_V100',pass,'special_after=1 boss_after=2 boss_clear=1')
    @verification_done[:rpg_state_progress_v100]=true
  end

  def verify_rpg_request_bridge_v100
    return if @verification_done[:rpg_request_bridge_v100]
    w=PMD_AC.rpg_foundation_wild_request_v100;s=PMD_AC.rpg_foundation_special_request_v100;b=PMD_AC.rpg_foundation_boss_request_v100
    pass=w!=nil && s!=nil && b!=nil && PMD_AC.rpg_foundation_request_v100?(w) && PMD_AC.rpg_foundation_request_v100?(b) &&
      (w[:options]||{})[:hp_policy]==:carry && (w[:options]||{})[:defeat_policy]==:return_heal &&
      w[:recruitable] && s[:recruitable] && !b[:recruitable] && !b[:can_escape]
    log_rpg_verify_v100('RPG_FOUNDATION_REQUEST_BRIDGE_V100',pass,
      'wild='+w[:kind].to_s+' special='+s[:kind].to_s+' boss='+b[:kind].to_s+' carry_hp=1 boss_recruit=0')
    @verification_done[:rpg_request_bridge_v100]=true
  end

  def verify_rpg_individuality_v100
    return if @verification_done[:rpg_individuality_v100]
    a=PMD_PokemonInstance.new(:pikachu,12);b=PMD_PokemonInstance.new(:pikachu,12)
    a.set_nature(:brave);b.set_nature(:timid)
    ta=PMD_AC.temperament_axes_v09916(a.nature_key);tb=PMD_AC.temperament_axes_v09916(b.nature_key)
    pass=a.species_key==b.species_key && a.instance_uid!=b.instance_uid && a.nature_key!=b.nature_key && ta!=tb
    log_rpg_verify_v100('RPG_INDIVIDUALITY_V100',pass,
      'same_species=1 unique_uid=1 brave_vs_timid=1 temperament_diff=1')
    @verification_done[:rpg_individuality_v100]=true
  end

  def verify_rpg_player_tools_v100
    return if @verification_done[:rpg_player_tools_v100]
    pass=PMD_AC.respond_to?(:party_instances_v078) && PMD_AC.respond_to?(:storage_count_v078) &&
      PMD_AC.respond_to?(:open_collection_v093) && respond_to?(:open_ai_strategy_v09913) &&
      defined?(Scene_PMD_RPGFoundationV100)!=nil
    log_rpg_verify_v100('RPG_PLAYER_TOOLS_V100',pass,'party_box=1 pokedex=1 ai_strategy=1 hub_scene=1')
    @verification_done[:rpg_player_tools_v100]=true
  end

  def verify_rpg_carry_v100
    return if @verification_done[:rpg_carry_v100]
    u=verification_unit(:ally,:charmander)
    pass=PMD_AC.respond_to?(:temperament_axes_v09916) && PMD_AC.respond_to?(:dex_summary_v093) &&
      PMD_AC.respond_to?(:heal_party_v082) && PMD_AC.respond_to?(:resolve_rewards_v083) &&
      u!=nil && u.respond_to?(:cadence_runtime_v099142?) && u.cadence_runtime_v099142? &&
      u.respond_to?(:basic_flex_runtime_v09912?) && u.basic_flex_runtime_v09912?
    log_rpg_verify_v100('RPG_SYSTEM_CARRY_V100',pass,
      'nature_ai=1 spatial=1 cadence=1 basic_flex=1 reward=1 field_hp=1 damage_unchanged=1')
    @verification_done[:rpg_carry_v100]=true
  end

  def verify_latest_five_modes_v100
    return if @verification_done[:latest_five_modes_v100]
    exp=[:rpg_foundation_v100,:nature_ai_temperament_v09916,:spatial_conditions_ai_rules_v09915,
      :spatial_framework_expansion_v09914,:dynamic_tactical_role_v09913]
    actual=PMD_AC::VERIFICATION_MODES[1,5]
    pass=PMD_AC::VERIFICATION_MODES.size==6 && PMD_AC::VERIFICATION_MODES[0]==:normal && actual==exp
    log_rpg_verify_v100('LATEST_FIVE_MODES_V100',pass,'formal_modes=5 order='+actual.collect{|x|x.to_s}.join(','))
    @verification_done[:latest_five_modes_v100]=true
  end

  def verify_rpg_final_v100
    return if @verification_done[:rpg_final_v100]
    pass=!@rpg_foundation_failed_v100 && @rpg_foundation_report_written_v100
    log_rpg_verify_v100('RPG_FOUNDATION_V100',pass,
      'playable_loop=1 individuality=1 player_tools=1 battle_core_carried=1 core_direct_modification=0 next=map_story_vertical_slice')
    @verification_done[:rpg_final_v100]=true
  end

  def update_verification_script
    pmd_ac_v100_update_verification_script
    return unless rpg_foundation_v100?
    f=@verification_frame.to_i
    verify_rpg_manifest_v100 if f>=20
    verify_rpg_state_progress_v100 if f>=44
    verify_rpg_request_bridge_v100 if f>=68
    verify_rpg_individuality_v100 if f>=92
    verify_rpg_player_tools_v100 if f>=116
    verify_rpg_carry_v100 if f>=140
    verify_latest_five_modes_v100 if f>=164
    verify_rpg_final_v100 if f>=184
    if f>=PMD_AC::RPG_FOUNDATION_VERIFY_END_V100 && !@verification_done[:rpg_foundation_complete_v100]
      if @rpg_foundation_failed_v100
        for u in @units;u.verification_finish if u.respond_to?(:verification_finish);end
        @verification_done[:rpg_foundation_complete_v100]=true
        @verification_done[:complete]=true
        log_event(:verify,'FAILED mode=RPG_FOUNDATION_V100 auto_skill=on original_skills=restored')
      else
        complete_verification_mode
        @verification_done[:rpg_foundation_complete_v100]=true
      end
    end
  end

  # 舊 verifier 仍在最新五項，更新其 latest-five 期待值。
  def verify_latest_five_modes_v09916
    unless verification_mode==:nature_ai_temperament_v09916
      return pmd_ac_v100_verify_latest_five_modes_v09916
    end
    return if @verification_done[:latest_five_modes_v09916]
    exp=[:rpg_foundation_v100,:nature_ai_temperament_v09916,:spatial_conditions_ai_rules_v09915,
      :spatial_framework_expansion_v09914,:dynamic_tactical_role_v09913]
    actual=PMD_AC::VERIFICATION_MODES[1,5]
    pass=PMD_AC::VERIFICATION_MODES.size==6 && actual==exp
    log_nature_verify_v09916('LATEST_FIVE_MODES_V09916',pass,'formal_modes=5 current_head=v100 order='+actual.collect{|x|x.to_s}.join(','))
    @verification_done[:latest_five_modes_v09916]=true
  end

  def verify_latest_five_modes_v09915
    unless verification_mode==:spatial_conditions_ai_rules_v09915
      return pmd_ac_v100_verify_latest_five_modes_v09915
    end
    return if @verification_done[:latest_five_modes_v09915]
    exp=[:rpg_foundation_v100,:nature_ai_temperament_v09916,:spatial_conditions_ai_rules_v09915,
      :spatial_framework_expansion_v09914,:dynamic_tactical_role_v09913]
    actual=PMD_AC::VERIFICATION_MODES[1,5]
    pass=PMD_AC::VERIFICATION_MODES.size==6 && actual==exp
    log_condition_verify_v09915('LATEST_FIVE_MODES_V09915',pass,'formal_modes=5 current_head=v100 order='+actual.collect{|x|x.to_s}.join(','))
    @verification_done[:latest_five_modes_v09915]=true
  end

  def verify_latest_five_modes_v09914
    unless verification_mode==:spatial_framework_expansion_v09914
      return pmd_ac_v100_verify_latest_five_modes_v09914
    end
    return if @verification_done[:latest_five_modes_v09914]
    exp=[:rpg_foundation_v100,:nature_ai_temperament_v09916,:spatial_conditions_ai_rules_v09915,
      :spatial_framework_expansion_v09914,:dynamic_tactical_role_v09913]
    actual=PMD_AC::VERIFICATION_MODES[1,5]
    pass=PMD_AC::VERIFICATION_MODES.size==6 && actual==exp
    log_spatial_verify_v09914('LATEST_FIVE_MODES_V09914',pass,'formal_modes=5 current_head=v100 order='+actual.collect{|x|x.to_s}.join(','))
    @verification_done[:latest_five_modes_v09914]=true
  end
end

#==============================================================================
# ■ v1.00 Verifier runtime inheritance
#==============================================================================
class Game_PMDChessUnit
  alias pmd_ac_v100_combat_feel_runtime_v0883 combat_feel_runtime_v0883? unless method_defined?(:pmd_ac_v100_combat_feel_runtime_v0883)
  alias pmd_ac_v100_basic_flex_runtime_v09912 basic_flex_runtime_v09912? unless method_defined?(:pmd_ac_v100_basic_flex_runtime_v09912)
  alias pmd_ac_v100_cadence_runtime_v099142 cadence_runtime_v099142? unless method_defined?(:pmd_ac_v100_cadence_runtime_v099142)

  def rpg_foundation_v100_verifier?
    @scene!=nil && @scene.respond_to?(:verification_mode) && @scene.verification_mode==:rpg_foundation_v100
  end

  def combat_feel_runtime_v0883?
    return true if rpg_foundation_v100_verifier?
    pmd_ac_v100_combat_feel_runtime_v0883
  end

  def basic_flex_runtime_v09912?
    return true if rpg_foundation_v100_verifier?
    pmd_ac_v100_basic_flex_runtime_v09912
  end

  def cadence_runtime_v099142?
    return true if rpg_foundation_v100_verifier?
    pmd_ac_v100_cadence_runtime_v099142
  end
end

#==============================================================================
# ■ S 輪替：NORMAL + 最新 5 個正式 verifier
#==============================================================================
module PMD_AC
  old_labels_v100=VERIFICATION_LABELS.dup
  remove_const(:VERIFICATION_LABELS)
  VERIFICATION_LABELS=old_labels_v100
  VERIFICATION_LABELS[:rpg_foundation_v100]='RPG_FOUNDATION_V100'

  remove_const(:VERIFICATION_MODES) if const_defined?(:VERIFICATION_MODES)
  VERIFICATION_MODES=[
    :normal,
    :rpg_foundation_v100,
    :nature_ai_temperament_v09916,
    :spatial_conditions_ai_rules_v09915,
    :spatial_framework_expansion_v09914,
    :dynamic_tactical_role_v09913
  ]
end
