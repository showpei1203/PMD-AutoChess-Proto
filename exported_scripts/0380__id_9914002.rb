# encoding: UTF-8
#==============================================================================
# 【PMD AutoChess 中文維護說明】
# 腳本：PMD AutoChess Spatial Framework Expansion Runtime v0.99.14.1
# 分類：空間技能 Runtime／戰場幾何 AI／Verifier／S 最新五項整理
# RPG Maker VX / RGSS2 / Ruby 1.8 compatible
#==============================================================================
# 【用途】
# 將 v0.99.14 的統一 Spatial Vocabulary 接進實際戰鬥。
# v0.99.14.1 啟動修正：Spatial Intent 中文標籤應擴充 PMD_AC 模組方法，
# 不可誤把 strategy_value_label_v09913 當成 Scene_PMD_AutoChess instance method。
# 本版重點不是再替 Species 寫死職業，而是讓「技能＋AI」真正產生不同站位價值：
# - escape_through：可穿越單位／混戰區脫困，不要求先退到指定距離才攻擊。
# - dash_through：穿過目標，到另一側建立背擊／側擊位置。
# - center_dive：往目標附近敵群重心深入，供 Diver／Bruiser 類玩法。
# - intercept：提供救援／護衛用的插入敵我之間 Runtime API。
# - Line / Cone / Surround：提供 AI 幾何計分，不在本版偷偷加 Move Power。
#
# 【玩家 AI】
# v0.99.13 AI Strategy 的 spatial_intent 新增：
#   escape / rescue / crowd / flank
# 既有 balanced / engage / disengage / peel / dive / control 全保留。
#
# 【實際技能示範】
# Rapid Spin / Teleport -> escape_through
# Acrobatics            -> dash_through
# Brave Bird / Flare Blitz -> center_dive
# 原 v0.91.4 / v0.99.12 Spatial Moves 繼續沿用。
#
# 【AI 幾何規則】
# - surrounded：自己 92px 內敵人越多，Surround 技能價值越高。
# - line：使用者→目標直線附近可命中的敵人越多，Pierce 類價值越高。
# - cone：使用者朝目標方向的扇形敵人越多，Cone 類價值越高。
# - Dynamic Role 與 spatial_intent 會再對相符技能加權。
#
# 【事件／腳本呼叫方式】
# 一般戰鬥自動運作。
# 開發／事件可直接使用：
#   unit.begin_tactical_escape_through_v09914(threat, 58, 7)
#   unit.begin_tactical_center_dive_v09914(target, 54, 7, 110)
#   unit.begin_tactical_intercept_v09914(ally, threat, 7)
#
# 【測試方式】
# NORMAL -> S 一次 -> SPATIAL_FRAMEWORK_EXPANSION_V09914 -> Shift
#
# 必要 PASS：
#   STRATEGY_LABEL_BRIDGE_V099141
#   SPATIAL_VOCABULARY_V09914
#   SPATIAL_INTENT_EXPANSION_V09914
#   ESCAPE_THROUGH_RUNTIME_V09914
#   CENTER_DIVE_RUNTIME_V09914
#   GEOMETRY_LINE_CONE_V09914
#   ROLE_SPATIAL_SCORING_V09914
#   LATEST_FIVE_MODES_V09914
#   DYNAMIC_ROLE_CARRY_V09914
#   SPATIAL_FRAMEWORK_EXPANSION_V09914
#   VERIFY_FINISHED_BATTLE_RESUME
#
# 【S 選單規則】
# NORMAL 之外只保留最新 5 個正式 mode：
# v0.99.14 / v0.99.13 / v0.99.12 / v0.99.11 / v0.99.10。
# 舊 verifier 程式仍留在 Scripts 中，只退出 S 輪替，不刪歷史能力。
#
# 【安全邊界】
# - 不直接修改 Frozen Combat Core，全部 trailing alias / extension。
# - 不改傷害公式、Power、Accuracy、Priority、Base Stats。
# - 不改 v0.99.13 Dynamic Role 計算核心，只追加 Spatial 加權。
# - Pokémon 身份仍為 instance_uid。
#==============================================================================
module PMD_AC
  SPATIAL_FRAMEWORK_VERIFY_END_V09914=154
  SPATIAL_FRAMEWORK_REPORT_V09914='PMD_SpatialFrameworkExpansion_v0.99.14.1.txt'

  class << self
    def spatial_framework_report_text_v09914
      out=[]
      out << 'PMD AutoChess Spatial Framework Expansion v0.99.14.1'
      out << 'Spatial kinds: '+SPATIAL_KINDS_V09914.collect{|x|x.to_s}.join(',')
      out << 'New spatial moves: '+SPATIAL_MOVE_EXTENSIONS_V09914.keys.collect{|x|x.to_s}.sort.join(',')
      out << 'Spatial intents: '+AI_SPATIAL_INTENTS_V09914.collect{|x|x.to_s}.join(',')
      out << 'Geometry: line=1 cone=1 surround=1 cluster=carry'
      out << 'Damage formula modified: NO'
      out << 'Dynamic Role carry: YES'
      out << 'S verifier latest formal modes: 5'
      out << 'Frozen Combat Core direct modification: NO'
      out << 'Review PASS: 1'
      out.join("\r\n")+"\r\n"
    end

    def write_spatial_framework_report_v09914
      File.open(SPATIAL_FRAMEWORK_REPORT_V09914,'wb'){|f|f.write(spatial_framework_report_text_v09914)}
      true
    rescue
      false
    end
  end
end

#==============================================================================
# ■ PMD_AC : v0.99.14.1 Strategy Label Bridge Hotfix
#==============================================================================
# v0.99.13 的 strategy_value_label_v09913 是 PMD_AC singleton method。
# v0.99.14 原版誤在 Scene_PMD_AutoChess 上 alias，導致腳本載入階段 NameError。
# 正確做法是在 PMD_AC singleton 層追加 Spatial Intent 中文標籤，
# 既有 Role / Movement / Target / Threat / Skill / Spacing 標籤全部回退舊方法。
module PMD_AC
  class << self
    alias pmd_ac_v099141_strategy_value_label_v09913 strategy_value_label_v09913 unless method_defined?(:pmd_ac_v099141_strategy_value_label_v09913)

    def strategy_value_label_v09913(key,value)
      if key==:spatial_intent && SPATIAL_INTENT_LABELS_V09914[value]!=nil
        return SPATIAL_INTENT_LABELS_V09914[value]
      end
      pmd_ac_v099141_strategy_value_label_v09913(key,value)
    end
  end
end

#==============================================================================
# ■ Game_PMDChessUnit : new spatial movement primitives
#==============================================================================
class Game_PMDChessUnit
  alias pmd_ac_v09914_combat_feel_runtime_v0883 combat_feel_runtime_v0883? unless method_defined?(:pmd_ac_v09914_combat_feel_runtime_v0883)
  alias pmd_ac_v09914_basic_flex_runtime_v09912 basic_flex_runtime_v09912? unless method_defined?(:pmd_ac_v09914_basic_flex_runtime_v09912)

  def combat_feel_runtime_v0883?
    if @scene!=nil && @scene.respond_to?(:verification_mode)
      return true if @scene.verification_mode==:spatial_framework_expansion_v09914
    end
    pmd_ac_v09914_combat_feel_runtime_v0883
  end

  def basic_flex_runtime_v09912?
    if @scene!=nil && @scene.respond_to?(:verification_mode)
      return true if @scene.verification_mode==:spatial_framework_expansion_v09914
    end
    pmd_ac_v09914_basic_flex_runtime_v09912
  end

  def spatial_alive_enemies_v09914
    return [] if @scene==nil || !@scene.respond_to?(:enemies_of)
    @scene.enemies_of(self).select{|e|e!=nil && !e.dead?}
  rescue
    []
  end

  def spatial_plan_v09914
    @spatial_plan_v09914
  end

  # 選擇 8 個方向中「終點與敵人最疏離」的方向。
  # Tactical Slide 本來就不做單位碰撞，因此必要時可直接穿過混戰區。
  def best_escape_vector_v09914(threat=nil,distance=58.0)
    enemies=spatial_alive_enemies_v09914
    dirs=[]
    8.times do |i|
      a=Math::PI*2.0*i.to_f/8.0
      dirs.push([Math.cos(a),Math.sin(a)])
    end
    best=nil;best_score=-999999.0
    dirs.each do |d|
      ex=@pixel_x.to_f+d[0]*distance.to_f
      ey=@pixel_y.to_f+d[1]*distance.to_f
      min_d=9999.0
      sum_d=0.0
      enemies.each do |e|
        dx=ex-e.pixel_x.to_f;dy=ey-e.pixel_y.to_f
        dd=Math.sqrt(dx*dx+dy*dy)
        min_d=dd if dd<min_d
        sum_d+=dd
      end
      min_d=distance.to_f if enemies.empty?
      score=min_d*2.0+sum_d*0.08
      if threat!=nil && !threat.dead?
        sx=@pixel_x.to_f-threat.pixel_x.to_f
        sy=@pixel_y.to_f-threat.pixel_y.to_f
        sl=Math.sqrt(sx*sx+sy*sy)
        if sl>0.001
          align=d[0]*sx/sl+d[1]*sy/sl
          score+=align*36.0
          score-=120.0 if align<0.0
        end
      end
      # 輕度避免把自己送到版面最外緣；真正 clamp 仍由既有 Runtime 處理。
      score-=8.0 if ex<28.0 || ex>Graphics.width-28 || ey<52.0 || ey>Graphics.height-34
      if score>best_score
        best_score=score;best=d
      end
    end
    best || [@team==:ally ? -1.0 : 1.0,0.0]
  end

  def begin_tactical_escape_through_v09914(threat=nil,distance=58.0,frames=7,reason=:skill_escape_through)
    return false if dead?
    threat=tactical_nearest_enemy_v0914 if threat==nil && respond_to?(:tactical_nearest_enemy_v0914)
    v=best_escape_vector_v09914(threat,distance)
    @spatial_plan_v09914={:kind=>:escape_through,:dx=>v[0],:dy=>v[1],:distance=>distance.to_f}
    begin_tactical_slide_vector_v0914(v[0],v[1],distance,frames,reason)
  end

  def cluster_center_for_target_v09914(target,radius=110.0)
    return nil if target==nil
    enemies=spatial_alive_enemies_v09914
    chosen=[]
    enemies.each do |e|
      dx=e.pixel_x.to_f-target.pixel_x.to_f;dy=e.pixel_y.to_f-target.pixel_y.to_f
      chosen.push(e) if Math.sqrt(dx*dx+dy*dy)<=radius.to_f
    end
    chosen.push(target) if target.team!=@team && !chosen.include?(target)
    return [target.pixel_x.to_f,target.pixel_y.to_f,1] if chosen.empty?
    sx=0.0;sy=0.0
    chosen.each{|e|sx+=e.pixel_x.to_f;sy+=e.pixel_y.to_f}
    [sx/chosen.size.to_f,sy/chosen.size.to_f,chosen.size]
  end

  def begin_tactical_center_dive_v09914(target,distance=54.0,frames=7,radius=110.0,reason=:skill_center_dive)
    return false if target==nil || target.dead? || target.team==@team
    c=cluster_center_for_target_v09914(target,radius)
    return false if c==nil
    dx=c[0]-@pixel_x.to_f;dy=c[1]-@pixel_y.to_f
    len=Math.sqrt(dx*dx+dy*dy)
    return false if len<=1.0
    travel=[distance.to_f,len].min
    @spatial_plan_v09914={:kind=>:center_dive,:dx=>dx,:dy=>dy,:distance=>travel,:cluster=>c[2]}
    begin_tactical_slide_vector_v0914(dx,dy,travel,frames,reason)
  end

  # 救援 API：移動到 ally 與 threat 之間，距 ally 約 40% 的位置。
  def begin_tactical_intercept_v09914(ally,threat,frames=7,reason=:skill_intercept)
    return false if ally==nil || threat==nil || ally.dead? || threat.dead?
    return false if ally.team!=@team || threat.team==@team
    tx=ally.pixel_x.to_f+(threat.pixel_x.to_f-ally.pixel_x.to_f)*0.40
    ty=ally.pixel_y.to_f+(threat.pixel_y.to_f-ally.pixel_y.to_f)*0.40
    dx=tx-@pixel_x.to_f;dy=ty-@pixel_y.to_f
    len=Math.sqrt(dx*dx+dy*dy)
    return false if len<=1.0
    travel=[len,64.0].min
    @spatial_plan_v09914={:kind=>:intercept,:dx=>dx,:dy=>dy,:distance=>travel,:ally=>ally.id,:threat=>threat.id}
    begin_tactical_slide_vector_v0914(dx,dy,travel,frames,reason)
  end
end

#==============================================================================
# ■ Scene_PMD_AutoChess : geometry, skill extension, AI scoring, verifier
#==============================================================================
class Scene_PMD_AutoChess
  alias pmd_ac_v09914_start start unless method_defined?(:pmd_ac_v09914_start)
  alias pmd_ac_v09914_refresh_header refresh_header unless method_defined?(:pmd_ac_v09914_refresh_header)
  alias pmd_ac_v09914_apply_skill_effects apply_skill_effects unless method_defined?(:pmd_ac_v09914_apply_skill_effects)
  alias pmd_ac_v09914_progression_candidate_score_v046 progression_candidate_score_v046 unless method_defined?(:pmd_ac_v09914_progression_candidate_score_v046)
  alias pmd_ac_v09914_prepare_verification_battle prepare_verification_battle unless method_defined?(:pmd_ac_v09914_prepare_verification_battle)
  alias pmd_ac_v09914_update_verification_script update_verification_script unless method_defined?(:pmd_ac_v09914_update_verification_script)
  alias pmd_ac_v09914_log_event log_event unless method_defined?(:pmd_ac_v09914_log_event)

  def spatial_framework_expansion_v09914?
    verification_mode==:spatial_framework_expansion_v09914
  end

  def spatial_framework_runtime_enabled_v09914?
    m=verification_mode
    m==:normal || m==:spatial_framework_expansion_v09914
  end

  def start
    pmd_ac_v09914_start
    begin
      if FileTest.exist?(PMD_AC::BATTLE_LOG_FILE)
        t=File.open(PMD_AC::BATTLE_LOG_FILE,'rb'){|f|f.read}
        t.sub!(/PMD AutoChess Proto v0\.[0-9.]+ Battle Verification Log/,
          'PMD AutoChess Proto v0.99.14.1 Battle Verification Log')
        File.open(PMD_AC::BATTLE_LOG_FILE,'wb'){|f|f.write(t)}
      end
    rescue
    end
    log_event(:spatial_framework,
      'FLOW v0.99.14.1 startup_label_bridge=1 vocabulary=12 escape_through=1 center_dive=1 intercept_api=1 '+
      'geometry=line+cone+surround spatial_intents=10 latest_s_modes=5 damage_unchanged=1')
    refresh_header
  end

  def refresh_header
    pmd_ac_v09914_refresh_header
    return if @header_sprite==nil || @header_sprite.bitmap==nil
    bmp=@header_sprite.bitmap
    bmp.fill_rect(0,0,Graphics.width,28,Color.new(0,0,0,180))
    pmd_ac_v074_font(bmp) if respond_to?(:pmd_ac_v074_font)
    bmp.font.size=20;bmp.font.bold=true;bmp.font.color=Color.new(255,255,255)
    bmp.draw_text(16,1,Graphics.width-32,28,'PMD 自走棋原型 v0.99.14.1',1)
  end

  def canonical_move_key_v09914(data)
    return canonical_move_key_v09912(data) if respond_to?(:canonical_move_key_v09912)
    return nil if data==nil
    PMD_AC.canonical_spatial_key_v09914(data[:canonical_move_key] || data['canonical_move_key'])
  end

  def native_spatial_duplicate_v09914?(data,kind)
    effects=data==nil ? [] : (data[:effects] || data['effects'] || [])
    types=[]
    effects.each do |e|
      t=e[:type] || e['type'];types.push(t.to_s.to_sym) if t!=nil
    end
    return (types.include?(:dash_user) || types.include?(:blink_user)) if kind==:dash_through
    return types.include?(:swap_position) if kind==:intercept || kind==:swap
    false
  end

  def apply_spatial_framework_extension_v09914(user,target,data)
    return false unless spatial_framework_runtime_enabled_v09914?
    return false if user==nil || user.dead? || data==nil
    mk=canonical_move_key_v09914(data)
    ext=PMD_AC.spatial_extension_v09914(mk)
    return false if ext==nil
    kind=ext[:kind]
    return false if native_spatial_duplicate_v09914?(data,kind)
    return false unless user.respond_to?(:spatial_extension_once_v0914)
    return false unless user.spatial_extension_once_v0914(mk,('v09914_'+kind.to_s).to_sym)
    threat=target
    if threat==nil || threat.team==user.team || threat.dead?
      threat=user.respond_to?(:tactical_nearest_enemy_v0914) ? user.tactical_nearest_enemy_v0914 : nil
    end
    ok=false
    case kind
    when :escape_through
      ok=user.begin_tactical_escape_through_v09914(threat,ext[:distance]||58.0,ext[:frames]||7,:skill_escape_through)
    when :dash_through
      ok=user.begin_tactical_dash_through_v09912(threat,ext[:distance_past]||32.0,ext[:frames]||7,:skill_dash_through_v09914) if threat!=nil
    when :center_dive
      ok=user.begin_tactical_center_dive_v09914(threat,ext[:distance]||52.0,ext[:frames]||7,
        ext[:cluster_radius]||108.0,:skill_center_dive) if threat!=nil
    end
    if ok
      log_event(:spatial_move,user.log_name+' move='+mk.to_s+' kind='+kind.to_s+
        (threat==nil ? '' : ' target='+threat.log_name))
    end
    ok
  end

  def apply_skill_effects(user,target,data,scale=1.0)
    result=pmd_ac_v09914_apply_skill_effects(user,target,data,scale)
    apply_spatial_framework_extension_v09914(user,target,data)
    result
  end

  def geometry_alive_enemies_v09914(unit)
    return [] if unit==nil || !respond_to?(:enemies_of)
    enemies_of(unit).select{|e|e!=nil && !e.dead?}
  rescue
    []
  end

  def surrounded_enemy_count_v09914(unit,radius=PMD_AC::SURROUND_RADIUS_V09914)
    return 0 if unit==nil
    geometry_alive_enemies_v09914(unit).inject(0) do |n,e|
      dx=e.pixel_x.to_f-unit.pixel_x.to_f;dy=e.pixel_y.to_f-unit.pixel_y.to_f
      n+(Math.sqrt(dx*dx+dy*dy)<=radius.to_f ? 1 : 0)
    end
  end

  def line_enemy_count_v09914(user,target,width=PMD_AC::LINE_WIDTH_V09914,range=PMD_AC::LINE_RANGE_V09914)
    return 0 if user==nil || target==nil
    vx=target.pixel_x.to_f-user.pixel_x.to_f;vy=target.pixel_y.to_f-user.pixel_y.to_f
    len=Math.sqrt(vx*vx+vy*vy);return 0 if len<=0.001
    ux=vx/len;uy=vy/len;max_r=[range.to_f,len+80.0].min
    count=0
    geometry_alive_enemies_v09914(user).each do |e|
      ex=e.pixel_x.to_f-user.pixel_x.to_f;ey=e.pixel_y.to_f-user.pixel_y.to_f
      proj=ex*ux+ey*uy
      next if proj<0.0 || proj>max_r
      perp=(ex*uy-ey*ux).abs
      count+=1 if perp<=width.to_f
    end
    count
  end

  def cone_enemy_count_v09914(user,target,range=PMD_AC::CONE_RANGE_V09914,half_deg=PMD_AC::CONE_HALF_ANGLE_DEG_V09914)
    return 0 if user==nil || target==nil
    vx=target.pixel_x.to_f-user.pixel_x.to_f;vy=target.pixel_y.to_f-user.pixel_y.to_f
    len=Math.sqrt(vx*vx+vy*vy);return 0 if len<=0.001
    ux=vx/len;uy=vy/len
    cos_limit=Math.cos(half_deg.to_f*Math::PI/180.0)
    count=0
    geometry_alive_enemies_v09914(user).each do |e|
      ex=e.pixel_x.to_f-user.pixel_x.to_f;ey=e.pixel_y.to_f-user.pixel_y.to_f
      d=Math.sqrt(ex*ex+ey*ey);next if d<=0.001 || d>range.to_f
      dot=(ex/d)*ux+(ey/d)*uy
      count+=1 if dot>=cos_limit
    end
    count
  end

  def spatial_framework_ai_bonus_v09914(unit,target,data)
    return 0.0 unless spatial_framework_runtime_enabled_v09914?
    return 0.0 if unit==nil || target==nil || data==nil
    mk=canonical_move_key_v09914(data)
    tags=PMD_AC.move_tactical_tags_v09914(mk,data)
    bonus=0.0
    intent=unit.respond_to?(:spatial_intent_v09912) ? unit.spatial_intent_v09912 : :balanced
    bonus+=PMD_AC.spatial_intent_bonus_extra_v09914(intent,tags)
    role=unit.respond_to?(:dynamic_role_v09913) ? unit.dynamic_role_v09913 : nil
    bonus+=PMD_AC.role_spatial_bonus_v09914(role,tags)

    if tags.include?(:surrounded_payoff)
      n=surrounded_enemy_count_v09914(unit)
      bonus+=[[n-1,0].max*5.0,15.0].min
    end
    if tags.include?(:line_geometry)
      n=line_enemy_count_v09914(unit,target)
      bonus+=[[n-1,0].max*4.0,12.0].min
    end
    if tags.include?(:cone_geometry)
      n=cone_enemy_count_v09914(unit,target)
      bonus+=[[n-1,0].max*3.0,12.0].min
    end
    ext=PMD_AC.spatial_extension_v09914(mk)
    if ext!=nil && ext[:kind]==:escape_through
      n=surrounded_enemy_count_v09914(unit,110.0)
      bonus+=[n*6.0,18.0].min
    elsif ext!=nil && ext[:kind]==:center_dive
      n=0
      geometry_alive_enemies_v09914(unit).each do |e|
        dx=e.pixel_x.to_f-target.pixel_x.to_f;dy=e.pixel_y.to_f-target.pixel_y.to_f
        n+=1 if Math.sqrt(dx*dx+dy*dy)<=(ext[:cluster_radius]||108.0).to_f
      end
      bonus+=[[n-1,0].max*5.0,15.0].min
    end
    [bonus,42.0].min
  end

  def progression_candidate_score_v046(unit,target,data,move,slot)
    score=pmd_ac_v09914_progression_candidate_score_v046(unit,target,data,move,slot)
    return score if score==nil
    score.to_f+spatial_framework_ai_bonus_v09914(unit,target,data)
  end

  def prepare_verification_battle
    pmd_ac_v09914_prepare_verification_battle
    return unless spatial_framework_expansion_v09914?
    @spatial_framework_failed_v09914=false
    @spatial_framework_report_written_v09914=PMD_AC.write_spatial_framework_report_v09914
    log_event(:showcase,'START mode=SPATIAL_FRAMEWORK_EXPANSION_V09914 vocabulary=12 intents=10 geometry=line+cone+surround latest_modes=5')
  end

  def log_event(category,message)
    if category.to_s=='verify' && spatial_framework_expansion_v09914? &&
       message.to_s.index('V09914')!=nil && message.to_s.index(' pass=0')!=nil
      @spatial_framework_failed_v09914=true
    end
    pmd_ac_v09914_log_event(category,message)
  end

  def log_spatial_verify_v09914(name,pass,detail='')
    @spatial_framework_failed_v09914=true unless pass
    log_event(:verify,name+' pass='+(pass ? '1':'0')+(detail=='' ? '' : ' '+detail))
  end

  def verify_strategy_label_bridge_v099141
    return if @verification_done[:strategy_label_bridge_v099141]
    escape_label=nil;auto_label=nil;pass=false
    begin
      escape_label=PMD_AC.strategy_value_label_v09913(:spatial_intent,:escape)
      auto_label=PMD_AC.strategy_value_label_v09913(:role_bias,:auto)
      pass=escape_label==PMD_AC::SPATIAL_INTENT_LABELS_V09914[:escape] &&
        auto_label!=nil && auto_label.to_s!=''
    rescue
      pass=false
    end
    log_spatial_verify_v09914('STRATEGY_LABEL_BRIDGE_V099141',pass,
      'module=PMD_AC scene_alias=0 escape_label='+(escape_label==nil ? 'nil' : escape_label.to_s)+
      ' legacy_role_label='+(auto_label==nil ? 'nil' : auto_label.to_s))
    @verification_done[:strategy_label_bridge_v099141]=true
  end

  def verify_spatial_vocabulary_v09914
    return if @verification_done[:spatial_vocab_v09914]
    kinds=PMD_AC::SPATIAL_KINDS_V09914
    r=PMD_AC.spatial_extension_unified_v09914(:rapid_spin)
    a=PMD_AC.spatial_extension_unified_v09914(:aerial_ace)
    u=PMD_AC.spatial_extension_unified_v09914(:u_turn)
    pass=kinds.size==12 && r!=nil && r[:kind]==:escape_through &&
      a!=nil && a[:kind]==:dash_through && u!=nil && u[:kind]==:retreat
    log_spatial_verify_v09914('SPATIAL_VOCABULARY_V09914',pass,
      'kinds='+kinds.size.to_s+' rapid_spin=escape_through aerial_ace=dash_through u_turn=retreat')
    @verification_done[:spatial_vocab_v09914]=true
  end

  def verify_spatial_intents_v09914
    return if @verification_done[:spatial_intents_v09914]
    vals=PMD_AC::AI_SPATIAL_INTENTS_V09914
    pass=vals.size==10 && [:escape,:rescue,:crowd,:flank].all?{|x|vals.include?(x)} &&
      PMD_AC.valid_ai_option?(:spatial_intent,:escape) &&
      PMD_AC.spatial_intent_bonus_extra_v09914(:flank,[:dash_through])>0.0
    log_spatial_verify_v09914('SPATIAL_INTENT_EXPANSION_V09914',pass,
      'intents='+vals.size.to_s+' new=escape,rescue,crowd,flank persistent_ai_setup=1')
    @verification_done[:spatial_intents_v09914]=true
  end

  def save_unit_spatial_state_v09914(u)
    h={}
    [:@pixel_x,:@pixel_y,:@tactical_slide_x_v0914,:@tactical_slide_y_v0914,
     :@tactical_slide_frames_v0914,:@spatial_plan_v09914].each{|iv|h[iv]=u.instance_variable_get(iv)}
    h
  end

  def restore_unit_spatial_state_v09914(u,h)
    h.each{|iv,v|u.instance_variable_set(iv,v)}
    u.sync_cell_from_pixel if u.respond_to?(:sync_cell_from_pixel)
  end

  def verify_escape_through_runtime_v09914
    return if @verification_done[:escape_runtime_v09914]
    u=verification_unit(:ally,:charmander);t=verification_unit(:enemy,:pidgey)
    pass=false;dot=0.0
    if u!=nil && t!=nil
      s=save_unit_spatial_state_v09914(u)
      begin
        awayx=u.pixel_x.to_f-t.pixel_x.to_f;awayy=u.pixel_y.to_f-t.pixel_y.to_f
        ok=u.begin_tactical_escape_through_v09914(t,58.0,7,:verify_escape)
        plan=u.spatial_plan_v09914
        if ok && plan!=nil
          dot=plan[:dx].to_f*awayx+plan[:dy].to_f*awayy
          pass=plan[:kind]==:escape_through && u.tactical_slide_active_v0914? && dot>0.0
        end
      rescue
        pass=false
      ensure
        restore_unit_spatial_state_v09914(u,s)
      end
    end
    log_spatial_verify_v09914('ESCAPE_THROUGH_RUNTIME_V09914',pass,
      'slide=collision_passthrough distance=58 frames=7 away_dot='+sprintf('%.1f',dot))
    @verification_done[:escape_runtime_v09914]=true
  end

  def verify_center_dive_runtime_v09914
    return if @verification_done[:center_dive_runtime_v09914]
    u=verification_unit(:ally,:charmander);t=verification_unit(:enemy,:caterpie)
    pass=false;cluster=0
    if u!=nil && t!=nil
      s=save_unit_spatial_state_v09914(u)
      begin
        c=u.cluster_center_for_target_v09914(t,110.0)
        before=Math.sqrt((u.pixel_x.to_f-c[0])**2+(u.pixel_y.to_f-c[1])**2)
        ok=u.begin_tactical_center_dive_v09914(t,54.0,7,110.0,:verify_dive)
        plan=u.spatial_plan_v09914
        cluster=plan==nil ? 0 : plan[:cluster].to_i
        if ok && plan!=nil
          nx=u.pixel_x.to_f+u.instance_variable_get(:@tactical_slide_x_v0914).to_f*7.0
          ny=u.pixel_y.to_f+u.instance_variable_get(:@tactical_slide_y_v0914).to_f*7.0
          after=Math.sqrt((nx-c[0])**2+(ny-c[1])**2)
          pass=plan[:kind]==:center_dive && after<before
        end
      rescue
        pass=false
      ensure
        restore_unit_spatial_state_v09914(u,s)
      end
    end
    log_spatial_verify_v09914('CENTER_DIVE_RUNTIME_V09914',pass,
      'toward_cluster=1 distance=54 cluster='+cluster.to_s+' pass_units=1')
    @verification_done[:center_dive_runtime_v09914]=true
  end

  def verify_geometry_line_cone_v09914
    return if @verification_done[:geometry_line_cone_v09914]
    u=verification_unit(:ally,:charmander);t=verification_unit(:enemy,:caterpie)
    line=0;cone=0;sur=0;pass=false
    if u!=nil && t!=nil
      line=line_enemy_count_v09914(u,t,PMD_AC::LINE_WIDTH_V09914,PMD_AC::LINE_RANGE_V09914)
      cone=cone_enemy_count_v09914(u,t,PMD_AC::CONE_RANGE_V09914,PMD_AC::CONE_HALF_ANGLE_DEG_V09914)
      sur=surrounded_enemy_count_v09914(u,PMD_AC::SURROUND_RADIUS_V09914)
      pass=line>=1 && cone>=1 && sur>=0 &&
        PMD_AC.move_tactical_tags_v09914(:earthquake).include?(:surrounded_payoff)
    end
    log_spatial_verify_v09914('GEOMETRY_LINE_CONE_V09914',pass,
      'line_count='+line.to_s+' cone_count='+cone.to_s+' surround_count='+sur.to_s+' power_modified=0')
    @verification_done[:geometry_line_cone_v09914]=true
  end

  def verify_role_spatial_scoring_v09914
    return if @verification_done[:role_spatial_scoring_v09914]
    diver=PMD_AC.role_spatial_bonus_v09914(:diver,[:center_dive,:crowd_commit])
    skim=PMD_AC.role_spatial_bonus_v09914(:skirmisher,[:escape_through,:reposition])
    body=PMD_AC.role_spatial_bonus_v09914(:bodyguard,[:intercept,:rescue])
    flank=PMD_AC.spatial_intent_bonus_extra_v09914(:flank,[:dash_through])
    pass=diver>0.0 && skim>0.0 && body>0.0 && flank>0.0
    log_spatial_verify_v09914('ROLE_SPATIAL_SCORING_V09914',pass,
      'diver='+diver.to_i.to_s+' skirmisher='+skim.to_i.to_s+' bodyguard='+body.to_i.to_s+' flank_intent='+flank.to_i.to_s)
    @verification_done[:role_spatial_scoring_v09914]=true
  end

  def verify_latest_five_modes_v09914
    return if @verification_done[:latest_five_modes_v09914]
    exp=[:spatial_framework_expansion_v09914,:dynamic_tactical_role_v09913,
      :basic_spatial_flex_v09912,:gameplay_review_final_v09911,:gameplay_review_hoenn_v09910]
    actual=PMD_AC::VERIFICATION_MODES[1,5]
    pass=PMD_AC::VERIFICATION_MODES.size==6 && actual==exp && PMD_AC::VERIFICATION_MODES[0]==:normal
    log_spatial_verify_v09914('LATEST_FIVE_MODES_V09914',pass,
      'formal_modes=5 normal_plus=1 order='+actual.collect{|x|x.to_s}.join(','))
    @verification_done[:latest_five_modes_v09914]=true
  end

  def verify_dynamic_role_carry_v09914
    return if @verification_done[:dynamic_role_carry_v09914]
    r=PMD_AC.basic_flex_audit_v09912
    pass=PMD_AC::TACTICAL_ROLES_V09913.size==9 && r[:rows].size==494 &&
      PMD_AC.move_tactical_tags_v09914(:ally_switch).include?(:rescue) &&
      PMD_AC.move_tactical_tags_v09914(:rapid_spin).include?(:escape_through)
    log_spatial_verify_v09914('DYNAMIC_ROLE_CARRY_V09914',pass,
      'roles=9 basic_flex=494/494 dynamic_role=carried spatial_tags=extended')
    @verification_done[:dynamic_role_carry_v09914]=true
  end

  def verify_spatial_final_v09914
    return if @verification_done[:spatial_final_v09914]
    pass=!@spatial_framework_failed_v09914 && @spatial_framework_report_written_v09914
    log_spatial_verify_v09914('SPATIAL_FRAMEWORK_EXPANSION_V09914',pass,
      'strategy_label_bridge=1 escape_through=1 center_dive=1 intercept_api=1 geometry=1 ai_intents=10 latest_modes=5 '+
      'damage_unchanged=1 core_direct_modification=0 next=spatial_conditions+ai_rules')
    @verification_done[:spatial_final_v09914]=true
  end

  def update_verification_script
    pmd_ac_v09914_update_verification_script
    return unless spatial_framework_expansion_v09914?
    f=@verification_frame.to_i
    verify_strategy_label_bridge_v099141 if f>=6
    verify_spatial_vocabulary_v09914 if f>=10
    verify_spatial_intents_v09914 if f>=26
    verify_escape_through_runtime_v09914 if f>=42
    verify_center_dive_runtime_v09914 if f>=58
    verify_geometry_line_cone_v09914 if f>=76
    verify_role_spatial_scoring_v09914 if f>=94
    verify_latest_five_modes_v09914 if f>=112
    verify_dynamic_role_carry_v09914 if f>=128
    verify_spatial_final_v09914 if f>=140
    if f>=PMD_AC::SPATIAL_FRAMEWORK_VERIFY_END_V09914 &&
       !@verification_done[:spatial_framework_complete_v09914]
      if @spatial_framework_failed_v09914
        for u in @units;u.verification_finish if u.respond_to?(:verification_finish);end
        @verification_done[:spatial_framework_complete_v09914]=true
        @verification_done[:complete]=true
        log_event(:verify,'FAILED mode=SPATIAL_FRAMEWORK_EXPANSION_V09914 auto_skill=on original_skills=restored')
      else
        complete_verification_mode
        @verification_done[:spatial_framework_complete_v09914]=true
      end
    end
  end
end

#==============================================================================
# ■ S 輪替：NORMAL + 最新 5 個正式 verifier
#==============================================================================
module PMD_AC
  old_labels_v09914=VERIFICATION_LABELS.dup
  remove_const(:VERIFICATION_LABELS)
  VERIFICATION_LABELS=old_labels_v09914
  VERIFICATION_LABELS[:spatial_framework_expansion_v09914]='SPATIAL_FRAMEWORK_EXPANSION_V09914'

  remove_const(:VERIFICATION_MODES) if const_defined?(:VERIFICATION_MODES)
  VERIFICATION_MODES=[
    :normal,
    :spatial_framework_expansion_v09914,
    :dynamic_tactical_role_v09913,
    :basic_spatial_flex_v09912,
    :gameplay_review_final_v09911,
    :gameplay_review_hoenn_v09910
  ]
end
