#==============================================================================
# PMD AutoChess Proto v0.83
# RPG Reward / Loot Framework
#==============================================================================
# 【中文使用說明】
# 本腳本是 v0.83 的「執行層」，讀取前一支 Reward / Loot Data v0.83 的設定。
# 一般調整獎勵內容時，請優先改 Data 腳本的 REWARD_TABLES_V083，
# 不需要改這支 Runtime。
#
# 【處理流程】
#   戰鬥勝利
#     ↓
#   v0.79 EXP／技能熟練
#     ↓
#   v0.80/v0.81 關卡解鎖／招募判定
#     ↓
#   v0.83 Loot Table 判定
#     ↓
#   Gold／Item／Weapon／Armor／Variable／Switch／Common Event
#     ↓
#   結果畫面顯示「戰利品」
#
# 【注意】
# 1. 戰敗不發 v0.83 Loot。
# 2. Boss 仍不可招募，但可以有 Loot。
# 3. Stage 的 first_clear / repeat 由 v0.80 通關資料判斷。
# 4. Wild / Boss / Scripted 使用 :win，除非事件傳入 :rewards 做臨時覆蓋。
# 5. 這支腳本只追加 Reward 層，不改 v0.75 戰鬥平衡、v0.76 成長、v0.82 HP 延續。
#
# 【常用範例】
# 事件戰指定 Reward Table：
#   PMD_AC.start_battle_v081(:roadside_pikachu, {:reward_table=>:my_battle})
#
# 臨時戰鬥直接指定 Rewards：
#   PMD_AC.start_custom_battle_v082('伏擊', [[:rattata,15]], {
#     :rewards=>[{:type=>:gold,:amount=>80}]
#   })
#==============================================================================
module PMD_AC
  V083_OLD_VERIFICATION_MODES = VERIFICATION_MODES.dup
  V083_OLD_VERIFICATION_LABELS = VERIFICATION_LABELS.dup
  remove_const(:VERIFICATION_MODES)
  VERIFICATION_MODES = [:normal,:reward_loot_v083] +
    V083_OLD_VERIFICATION_MODES.reject{|x|x==:normal || x==:reward_loot_v083}
  remove_const(:VERIFICATION_LABELS)
  VERIFICATION_LABELS = V083_OLD_VERIFICATION_LABELS.dup
  VERIFICATION_LABELS[:normal]='NORMAL'
  VERIFICATION_LABELS[:reward_loot_v083]='REWARD_LOOT_V083'

  def self.draw_loot_summary_v083(bitmap,loot,winner_team)
    return false if bitmap==nil
    y=REWARD_LOOT_Y_V083
    bitmap.fill_rect(16,y,bitmap.width-32,REWARD_LOOT_H_V083,Color.new(27,42,28,232))
    begin
      bitmap.font.name=UI_PANEL_FONT_V0741
    rescue
      bitmap.font.name=['Microsoft JhengHei','微軟正黑體','Arial']
    end
    bitmap.font.size=15
    bitmap.font.bold=true
    bitmap.font.color=Color.new(205,240,190)
    labels=loot==nil ? [] : (loot[:labels]||[])
    if winner_team!=:ally
      text='戰利品：戰敗不發放'
    elsif labels.empty?
      text='戰利品：無'
    else
      text='戰利品：'+labels.join('｜')
    end
    bitmap.draw_text(24,y+3,bitmap.width-48,22,text,0)
    true
  end
end

class Scene_PMD_AutoChess
  alias pmd_ac_v083_start start unless method_defined?(:pmd_ac_v083_start)
  alias pmd_ac_v083_create_units create_units unless method_defined?(:pmd_ac_v083_create_units)
  alias pmd_ac_v083_process_stage_result_v080 process_stage_result_v080 unless method_defined?(:pmd_ac_v083_process_stage_result_v080)
  alias pmd_ac_v083_show_result show_result unless method_defined?(:pmd_ac_v083_show_result)
  alias pmd_ac_v083_refresh_header refresh_header unless method_defined?(:pmd_ac_v083_refresh_header)
  alias pmd_ac_v083_prepare_verification_battle prepare_verification_battle unless method_defined?(:pmd_ac_v083_prepare_verification_battle)
  alias pmd_ac_v083_update_verification_script update_verification_script unless method_defined?(:pmd_ac_v083_update_verification_script)
  alias pmd_ac_v083_log_event log_event unless method_defined?(:pmd_ac_v083_log_event)

  def start
    pmd_ac_v083_start
    begin
      if FileTest.exist?(PMD_AC::BATTLE_LOG_FILE)
        text=File.open(PMD_AC::BATTLE_LOG_FILE,'rb'){|f|f.read}
        text.sub!(/PMD AutoChess Proto v0\.[0-9.]+ Battle Verification Log/,
                  'PMD AutoChess Proto v0.83 Battle Verification Log')
        File.open(PMD_AC::BATTLE_LOG_FILE,'wb'){|f|f.write(text)}
      end
    rescue
    end
    m=PMD_AC::REWARD_LOOT_MANIFEST_V083
    log_event(:reward_loot,
      'FLOW v0.83 types='+m[:types].join(',')+
      ' stage_tables='+m[:stage_tables].to_s+
      ' encounter_tables='+m[:encounter_tables].to_s+
      ' inline=1 boss_reward=1 boss_recruit=off')
    refresh_header
  end

  def create_units
    @loot_reward_v083=nil
    pmd_ac_v083_create_units
  end

  def process_loot_reward_v083(winner_team)
    return nil unless verification_mode==:normal
    if winner_team!=:ally
      @loot_reward_v083={:table=>nil,:results=>[],:labels=>[],:winner=>winner_team}
      return @loot_reward_v083
    end
    req=rpg_request_v081
    sid=nil
    first=false
    if req!=nil && req[:kind]==:stage
      sid=req[:stage_id]
      first=@stage_reward_v080!=nil && @stage_reward_v080[:first_clear] ? true:false
    elsif req==nil
      sid=@active_stage_id_v080 || PMD_AC.current_stage_id_v080
      first=@stage_reward_v080!=nil && @stage_reward_v080[:first_clear] ? true:false
    end
    loot=PMD_AC.resolve_rewards_v083(req,sid,first,false,nil)
    loot[:winner]=winner_team
    @loot_reward_v083=loot
    detail=loot[:labels].empty? ? 'none' : loot[:labels].join('|')
    log_event(:reward_loot,'GRANT table='+(loot[:table]==nil ? 'inline_or_none' : loot[:table].to_s)+
      ' first='+(first ? '1':'0')+' rewards='+detail)
    loot
  end

  def process_stage_result_v080(winner_team)
    pmd_ac_v083_process_stage_result_v080(winner_team)
    process_loot_reward_v083(winner_team)
  end

  def redraw_result_with_loot_v083
    return false if verification_mode!=:normal
    return false if @result_sprite==nil
    req=rpg_request_v081
    old=@result_sprite.bitmap
    old.dispose if old!=nil && !old.disposed?
    @result_sprite.bitmap=Bitmap.new(510,PMD_AC::REWARD_RESULT_H_V083)
    @result_sprite.x=(Graphics.width-510)/2
    @result_sprite.y=(Graphics.height-PMD_AC::REWARD_RESULT_H_V083)/2-2
    @result_sprite.z=9999
    record=@battle_record_after_v079 || PMD_AC.battle_loop_state_v079
    attention=progression_attention_total_v077
    winner=nil
    if req!=nil && req[:kind]!=:stage
      rr=@rpg_reward_v081 || {:request=>req,:winner=>nil,:offer=>nil}
      winner=rr[:winner]
      PMD_AC.draw_rpg_result_v081(@result_sprite.bitmap,@result_text,
        @battle_reward_rows_v079||[],record,attention,rr)
    else
      sid=req!=nil ? req[:stage_id] : (@active_stage_id_v080||PMD_AC.current_stage_id_v080)
      sr=@stage_reward_v080 || {:stage_id=>sid,:winner=>nil,:offer=>nil,
        :clear_count=>PMD_AC.stage_clear_count_v080(sid)}
      winner=sr[:winner]
      PMD_AC.draw_stage_result_v080(@result_sprite.bitmap,@result_text,
        @battle_reward_rows_v079||[],record,attention,sr)
    end
    PMD_AC.draw_loot_summary_v083(@result_sprite.bitmap,@loot_reward_v083,winner)
    true
  end

  def show_result
    pmd_ac_v083_show_result
    redraw_result_with_loot_v083
  end

  def refresh_header
    pmd_ac_v083_refresh_header
    return if @header_sprite==nil || @header_sprite.bitmap==nil
    bmp=@header_sprite.bitmap
    bmp.fill_rect(0,0,Graphics.width,28,Color.new(0,0,0,180))
    pmd_ac_v074_font(bmp)
    bmp.font.size=PMD_AC::HEADER_TITLE_FONT_V0741
    bmp.font.bold=true
    bmp.font.color=Color.new(255,255,255)
    bmp.draw_text(16,4,Graphics.width-32,24,'PMD 自走棋原型 v0.83',1)
  end

  def reward_loot_v083?
    verification_mode==:reward_loot_v083
  end

  def prepare_verification_battle
    pmd_ac_v083_prepare_verification_battle
    @reward_loot_v083_failed=false if reward_loot_v083?
  end

  def log_event(category,message)
    if category.to_s=='verify' && reward_loot_v083? &&
       message.to_s.index('REWARD_LOOT_')==0 && message.to_s.include?(' pass=0')
      @reward_loot_v083_failed=true
    end
    pmd_ac_v083_log_event(category,message)
  end

  def log_verify_v083(name,pass,detail='')
    @reward_loot_v083_failed=true unless pass
    log_event(:verify,name+' pass='+(pass ? '1':'0')+(detail=='' ? '' : ' '+detail))
  end

  def verify_reward_loot_manifest_v083
    return if @verification_done[:v083_manifest]
    e=PMD_AC.reward_loot_errors_v083
    m=PMD_AC::REWARD_LOOT_MANIFEST_V083
    pass=e.empty? && m[:types].size==7 && m[:boss_recruitable]==false
    log_verify_v083('REWARD_LOOT_MANIFEST_V083',pass,
      'types=7 stage_tables='+m[:stage_tables].to_s+' encounter_tables='+m[:encounter_tables].to_s+
      ' errors=['+e.join(',')+']')
    @verification_done[:v083_manifest]=true
  end

  def verify_reward_loot_stage_v083
    return if @verification_done[:v083_stage]
    req={:kind=>:stage,:stage_id=>1,:key=>:stage_1,:options=>{}}
    a=PMD_AC.resolve_rewards_v083(req,1,true,true,[0])
    b=PMD_AC.resolve_rewards_v083(req,1,false,true,[0])
    pass=a[:table]==:stage_1 && b[:table]==:stage_1 &&
      a[:results][0]!=nil && a[:results][0][:amount]==100 &&
      b[:results][0]!=nil && b[:results][0][:amount]==35
    log_verify_v083('REWARD_LOOT_STAGE_V083',pass,
      'first='+(a[:labels][0]||'none')+' repeat='+(b[:labels][0]||'none'))
    @verification_done[:v083_stage]=true
  end

  def verify_reward_loot_context_v083
    return if @verification_done[:v083_context]
    w={:kind=>:wild,:key=>:forest_wild,:options=>{}}
    b={:kind=>:boss,:key=>:boss_beedrill,:options=>{}}
    s={:kind=>:scripted,:key=>:roadside_pikachu,:options=>{}}
    wr=PMD_AC.resolve_rewards_v083(w,nil,false,true,[0])
    br=PMD_AC.resolve_rewards_v083(b,nil,false,true,[0])
    sr=PMD_AC.resolve_rewards_v083(s,nil,false,true,[0])
    pass=wr[:table]==:forest_wild && br[:table]==:boss_beedrill && sr[:table]==:roadside_pikachu &&
      br[:results][0]!=nil && br[:results][0][:amount]==300
    log_verify_v083('REWARD_LOOT_CONTEXT_V083',pass,
      'wild='+wr[:labels].join('|')+' boss='+br[:labels].join('|')+' scripted='+sr[:labels].join('|'))
    @verification_done[:v083_context]=true
  end

  def verify_reward_loot_schema_v083
    return if @verification_done[:v083_schema]
    rows=[
      {:type=>:item,:id=>5,:qty=>2},
      {:type=>:weapon,:id=>3,:qty=>1},
      {:type=>:armor,:id=>8,:qty=>1},
      {:type=>:variable,:id=>21,:amount=>3},
      {:type=>:switch,:id=>40,:value=>true},
      {:type=>:common_event,:id=>12}
    ]
    types=[];ok=true
    for r in rows
      x=PMD_AC.apply_reward_row_v083(r,true,0,0)
      ok=false unless x[:granted]
      types.push(x[:type]) if x[:granted]
    end
    pass=ok && types==[:item,:weapon,:armor,:variable,:switch,:common_event]
    log_verify_v083('REWARD_LOOT_SCHEMA_V083',pass,'types='+types.join(','))
    @verification_done[:v083_schema]=true
  end

  def verify_reward_loot_inline_v083
    return if @verification_done[:v083_inline]
    req={:kind=>:scripted,:key=>:custom,:options=>{
      :reward_table=>false,
      :rewards=>[{:type=>:gold,:amount=>77},{:type=>:variable,:id=>9,:amount=>2}]
    }}
    r=PMD_AC.resolve_rewards_v083(req,nil,false,true,[0,0])
    pass=r[:table]==nil && r[:results].size==2 && r[:results][0][:amount]==77 && r[:results][1][:id]==9
    log_verify_v083('REWARD_LOOT_INLINE_V083',pass,'rewards='+r[:labels].join('|'))
    @verification_done[:v083_inline]=true
  end

  def verify_reward_loot_carry_v083
    return if @verification_done[:v083_carry]
    pass=PMD_AC::RPG_FIELD_MANIFEST_V082[:boss_recruitable]==false &&
      PMD_AC::RPG_ENCOUNTER_MANIFEST_V081[:contexts].size==4 &&
      PMD_AC::STAGE_DB_V080.size==3 && PMD_AC::PARTY_CAPACITY_V045==3
    log_verify_v083('REWARD_LOOT_CARRY_V083',pass,
      'field=v0.82 encounter=v0.81 stage=v0.80 reward=v0.79 party=v0.78 progression=v0.77.1 balance=v0.75')
    @verification_done[:v083_carry]=true
  end

  def update_verification_script
    unless reward_loot_v083?
      pmd_ac_v083_update_verification_script
      return
    end
    f=@verification_frame.to_i
    verify_reward_loot_manifest_v083 if f>=2
    verify_reward_loot_stage_v083 if f>=4
    verify_reward_loot_context_v083 if f>=6
    verify_reward_loot_schema_v083 if f>=8
    verify_reward_loot_inline_v083 if f>=10
    verify_reward_loot_carry_v083 if f>=12
    if f>=16 && !@verification_done[:v083_final]
      pass=!@reward_loot_v083_failed
      log_verify_v083('REWARD_LOOT_V083',pass,'manifest=1 stage=1 context=1 schema=1 inline=1 carry=1')
      @verification_done[:v083_final]=true
    end
    complete_verification_mode if f>=PMD_AC::REWARD_VERIFY_END_V083
  end
end
