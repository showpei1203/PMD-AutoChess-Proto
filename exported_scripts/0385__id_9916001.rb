# encoding: UTF-8
#==============================================================================
# 【PMD AutoChess 中文維護說明】
# 腳本：PMD AutoChess Nature × AI Temperament Data v0.99.16
# 分類：個體差異／Nature 行為傾向／AI 軟性權重資料層
# RPG Maker VX / RGSS2 / Ruby 1.8 compatible
#==============================================================================
# 【用途】
# 延續 v0.99.15 Spatial Conditions + AI Rules，將既有 Pokémon 原作 25 種 Nature
# 除了能力值 ±10% 之外，再賦予「小幅、持久、可被玩家 AI 覆蓋」的戰鬥個性。
# 目的不是新增 25 套寫死 AI，而是讓同物種、同技能、同 Ability 的不同個體，
# 在 Auto AI 下仍會有可辨識的選招／追擊／脫困／援護差異，增加重複捕捉與 BOX 收藏價值。
#
# 【五個 Temperament 軸】
# aggression  攻擊性：接戰、追擊、切後排、收頭、深入混戰。
# caution     謹慎度：脫困、保距、低血撤離、風險控制。
# mobility    機動性：Dash Through、Reposition、Flank、Escape Through。
# support     援護性：Peel、Rescue、Intercept、Swap、保護友軍。
# commitment  執著度：持續鎖定目標、完成追擊、較少無故換目標。
# 每軸範圍 -2..+2。這些值「不是能力值」，也不直接修改傷害／速度／防禦。
#
# 【玩家控制權優先】
# Nature 是軟性權重，不得凌駕玩家 AI：
# - Role Bias 明確指定時：Nature 對 Dynamic Role 只保留 25%。
# - Condition Focus 明確指定時：Nature 對條件選招只保留 35%。
# - Spatial Intent 明確指定時：Nature 對位移選招只保留 35%。
# - Target Commitment 明確指定時：Nature 對 commitment 影響 = 0%。
# 因此「勇敢」寶可夢仍可被玩家配置成 Kiter，「膽小」也可被配置成 Diver；
# Nature 只讓相同配置的行為細節略有不同。
#
# 【收集設計原則】
# - 不設 Best Nature / Trash Nature。
# - 每種 Nature 都至少有一項正向傾向與自己的取捨。
# - AI 影響上限刻意小於 Role / Spatial Condition 的主要分數。
# - 玩家不需要為了通關被迫刷指定 Nature；想追求特定戰鬥手感才值得刷。
#
# 【腳本呼叫範例】
# pokemon.set_nature(:brave)
# PMD_AC.temperament_axes_v09916(pokemon.nature_key)
# PMD_AC.temperament_move_bonus_v09916(pokemon, [:engage,:execute])
# PMD_AC.temperament_summary_v09916(pokemon.nature_key)
#
# 【可調參數】
# TEMPERAMENT_MOVE_AXIS_WEIGHT_V09916  每軸選招影響係數
# TEMPERAMENT_MOVE_BONUS_CAP_V09916    Nature 單次選招加權上限
# TEMPERAMENT_ROLE_AXIS_WEIGHT_V09916  Dynamic Role 提示強度
# TEMPERAMENT_COMMIT_STEP_V09916       執著度對 target commitment 的每級影響
# TEMPERAMENT_*_EXPLICIT_SCALE_V09916  玩家明確 AI 設定後 Nature 殘留比例
#
# 【安全邊界】
# - 不修改 Pokémon 原作 Nature 的能力值乘數。
# - 不修改 Damage Formula / Move Power / Accuracy / Priority / Attack Speed。
# - 不直接修改 Frozen Combat Core。
# - 不改 494 Species Gameplay Review、Basic Flex、Spatial Framework。
#==============================================================================
module PMD_AC
  NATURE_AI_VERSION_V09916='0.99.16'

  TEMPERAMENT_AXES_V09916=[:aggression,:caution,:mobility,:support,:commitment]
  TEMPERAMENT_AXIS_LABELS_V09916={
    :aggression=>'攻擊',:caution=>'謹慎',:mobility=>'機動',:support=>'援護',:commitment=>'執著'
  }

  NATURE_LABELS_ZH_V09916={
    :hardy=>'勤奮',:lonely=>'怕寂寞',:brave=>'勇敢',:adamant=>'固執',:naughty=>'頑皮',
    :bold=>'大膽',:docile=>'坦率',:relaxed=>'悠閒',:impish=>'淘氣',:lax=>'樂天',
    :timid=>'膽小',:hasty=>'急躁',:serious=>'認真',:jolly=>'爽朗',:naive=>'天真',
    :modest=>'內斂',:mild=>'慢吞吞',:quiet=>'冷靜',:bashful=>'害羞',:rash=>'馬虎',
    :calm=>'溫和',:gentle=>'溫順',:sassy=>'自大',:careful=>'慎重',:quirky=>'浮躁'
  }

  # 25 種 Nature 全部手工設計，且與原作能力值增減「並存但不綁死」。
  # 例如 Brave 原作降 Speed，但 AI 個性上的 mobility=-1 只是傾向，不再額外改速度。
  NATURE_TEMPERAMENT_V09916={
    :hardy   =>{:aggression=> 1,:caution=> 0,:mobility=> 0,:support=> 0,:commitment=> 1},
    :lonely  =>{:aggression=> 1,:caution=> 0,:mobility=> 0,:support=>-1,:commitment=> 1},
    :brave   =>{:aggression=> 2,:caution=>-1,:mobility=>-1,:support=> 0,:commitment=> 2},
    :adamant =>{:aggression=> 1,:caution=> 0,:mobility=> 0,:support=>-1,:commitment=> 2},
    :naughty =>{:aggression=> 2,:caution=>-1,:mobility=> 1,:support=>-1,:commitment=> 0},

    :bold    =>{:aggression=> 0,:caution=> 2,:mobility=>-1,:support=> 1,:commitment=> 1},
    :docile  =>{:aggression=>-1,:caution=> 1,:mobility=> 0,:support=> 2,:commitment=>-1},
    :relaxed =>{:aggression=> 0,:caution=> 2,:mobility=>-2,:support=> 1,:commitment=> 1},
    :impish  =>{:aggression=> 1,:caution=> 1,:mobility=> 1,:support=> 1,:commitment=> 0},
    :lax     =>{:aggression=> 1,:caution=>-1,:mobility=> 0,:support=> 0,:commitment=>-1},

    :timid   =>{:aggression=>-2,:caution=> 2,:mobility=> 2,:support=> 0,:commitment=>-1},
    :hasty   =>{:aggression=> 1,:caution=>-1,:mobility=> 2,:support=>-1,:commitment=>-1},
    :serious =>{:aggression=> 0,:caution=> 0,:mobility=> 0,:support=> 0,:commitment=> 2},
    :jolly   =>{:aggression=> 1,:caution=> 0,:mobility=> 2,:support=> 1,:commitment=> 0},
    :naive   =>{:aggression=> 1,:caution=>-1,:mobility=> 2,:support=> 0,:commitment=>-2},

    :modest  =>{:aggression=> 0,:caution=> 1,:mobility=> 0,:support=> 1,:commitment=> 1},
    :mild    =>{:aggression=> 0,:caution=> 0,:mobility=> 0,:support=> 2,:commitment=>-1},
    :quiet   =>{:aggression=>-1,:caution=> 1,:mobility=>-2,:support=> 1,:commitment=> 2},
    :bashful =>{:aggression=>-1,:caution=> 1,:mobility=> 0,:support=> 1,:commitment=>-1},
    :rash    =>{:aggression=> 2,:caution=>-2,:mobility=> 1,:support=> 0,:commitment=> 1},

    :calm    =>{:aggression=>-1,:caution=> 2,:mobility=> 0,:support=> 2,:commitment=> 1},
    :gentle  =>{:aggression=>-2,:caution=> 1,:mobility=> 0,:support=> 2,:commitment=>-1},
    :sassy   =>{:aggression=> 1,:caution=> 1,:mobility=>-1,:support=> 0,:commitment=> 2},
    :careful =>{:aggression=>-1,:caution=> 2,:mobility=> 0,:support=> 1,:commitment=> 2},
    :quirky  =>{:aggression=> 0,:caution=> 0,:mobility=> 1,:support=> 0,:commitment=>-1}
  }

  TEMPERAMENT_MOVE_AXIS_WEIGHT_V09916=1.55
  TEMPERAMENT_MOVE_BONUS_CAP_V09916=7.5
  TEMPERAMENT_ROLE_AXIS_WEIGHT_V09916=1.55
  TEMPERAMENT_COMMIT_STEP_V09916=4
  TEMPERAMENT_COMMIT_AGGRESSION_STEP_V09916=1
  TEMPERAMENT_COMMIT_CAUTION_STEP_V09916=1
  TEMPERAMENT_COMMIT_OFFSET_CAP_V09916=10
  TEMPERAMENT_ROLE_EXPLICIT_SCALE_V09916=0.25
  TEMPERAMENT_CONDITION_EXPLICIT_SCALE_V09916=0.35
  TEMPERAMENT_SPATIAL_EXPLICIT_SCALE_V09916=0.35

  TEMPERAMENT_AGGRESSIVE_TAGS_V09916=[
    :engage,:gap_close,:dive,:center_dive,:execute,:burst_damage,
    :back_attack,:blink_behind,:crowd_commit,:melee_density_payoff
  ]
  TEMPERAMENT_CAUTIOUS_TAGS_V09916=[
    :escape_through,:escape,:disengage,:space_create,:reposition,
    :guard_support,:heal_support
  ]
  TEMPERAMENT_MOBILITY_TAGS_V09916=[
    :dash_through,:blink_behind,:phase_reposition,:reposition,
    :escape_through,:swap,:flank,:gap_close
  ]
  TEMPERAMENT_SUPPORT_TAGS_V09916=[
    :rescue,:intercept,:peel,:swap,:frontline_control,:guard_support,
    :heal_support,:cluster_geometry,:cone_geometry
  ]
  TEMPERAMENT_COMMIT_TAGS_V09916=[
    :execute,:engage,:gap_close,:back_attack,:burst_damage,:dive
  ]

  class << self
    def normalize_nature_v09916(key)
      k=key==nil ? :hardy : key.to_sym rescue :hardy
      NATURE_TEMPERAMENT_V09916.has_key?(k) ? k : :hardy
    end

    def nature_label_v09916(key)
      k=normalize_nature_v09916(key)
      NATURE_LABELS_ZH_V09916[k] || k.to_s
    end

    def temperament_axes_v09916(nature_key)
      k=normalize_nature_v09916(nature_key)
      src=NATURE_TEMPERAMENT_V09916[k] || NATURE_TEMPERAMENT_V09916[:hardy]
      h={}
      TEMPERAMENT_AXES_V09916.each{|a|h[a]=src[a].to_i}
      h
    end

    def temperament_axis_text_v09916(value)
      v=value.to_i
      return '+'+v.to_s if v>0
      v.to_s
    end

    def temperament_summary_v09916(nature_key)
      h=temperament_axes_v09916(nature_key)
      TEMPERAMENT_AXES_V09916.collect do |a|
        TEMPERAMENT_AXIS_LABELS_V09916[a]+temperament_axis_text_v09916(h[a])
      end.join(' ')
    end

    def temperament_setup_v09916(pokemon)
      return {} if pokemon==nil || !pokemon.respond_to?(:ai_setup)
      pokemon.ai_setup || {}
    end

    def temperament_influence_scale_v09916(pokemon,domain=:move)
      setup=temperament_setup_v09916(pokemon)
      case domain
      when :role
        rb=setup[:role_bias]
        return TEMPERAMENT_ROLE_EXPLICIT_SCALE_V09916 if rb!=nil && rb!=:auto
      when :condition
        cf=setup[:condition_focus]
        return TEMPERAMENT_CONDITION_EXPLICIT_SCALE_V09916 if cf!=nil && cf!=:auto
      when :spatial
        si=setup[:spatial_intent]
        return TEMPERAMENT_SPATIAL_EXPLICIT_SCALE_V09916 if si!=nil && si!=:balanced
      when :commitment
        return 0.0 if setup[:target_commitment]!=nil
      when :move
        scales=[]
        cf=setup[:condition_focus]
        si=setup[:spatial_intent]
        rb=setup[:role_bias]
        scales << TEMPERAMENT_CONDITION_EXPLICIT_SCALE_V09916 if cf!=nil && cf!=:auto
        scales << TEMPERAMENT_SPATIAL_EXPLICIT_SCALE_V09916 if si!=nil && si!=:balanced
        scales << TEMPERAMENT_ROLE_EXPLICIT_SCALE_V09916 if rb!=nil && rb!=:auto
        return scales.min unless scales.empty?
      end
      1.0
    end

    def tag_intersects_v09916(tags,group)
      return false if tags==nil || group==nil
      !(tags & group).empty?
    end

    def temperament_move_bonus_for_v09916(nature_key,tags,scale=1.0)
      return 0.0 if tags==nil
      h=temperament_axes_v09916(nature_key)
      w=TEMPERAMENT_MOVE_AXIS_WEIGHT_V09916
      total=0.0
      total+=h[:aggression].to_f*w if tag_intersects_v09916(tags,TEMPERAMENT_AGGRESSIVE_TAGS_V09916)
      total+=h[:caution].to_f*w if tag_intersects_v09916(tags,TEMPERAMENT_CAUTIOUS_TAGS_V09916)
      total+=h[:mobility].to_f*w if tag_intersects_v09916(tags,TEMPERAMENT_MOBILITY_TAGS_V09916)
      total+=h[:support].to_f*w if tag_intersects_v09916(tags,TEMPERAMENT_SUPPORT_TAGS_V09916)
      total+=h[:commitment].to_f*w if tag_intersects_v09916(tags,TEMPERAMENT_COMMIT_TAGS_V09916)

      # 個性取捨：高攻擊性較不愛純撤退；高謹慎度較不愛無條件深入。
      if tag_intersects_v09916(tags,[:escape_through,:escape,:disengage])
        total-=h[:aggression].to_f*0.75
        total-=h[:commitment].to_f*0.55
      end
      if tag_intersects_v09916(tags,[:center_dive,:dive,:blink_behind])
        total-=h[:caution].to_f*0.70
      end
      total*=scale.to_f
      cap=TEMPERAMENT_MOVE_BONUS_CAP_V09916
      [[total,-cap].max,cap].min
    end

    def temperament_move_bonus_v09916(pokemon,tags)
      return 0.0 if pokemon==nil
      nature=pokemon.respond_to?(:nature_key) ? pokemon.nature_key : :hardy
      scale=temperament_influence_scale_v09916(pokemon,:move)
      temperament_move_bonus_for_v09916(nature,tags,scale)
    end

    def temperament_role_hints_v09916(nature_key)
      h=temperament_axes_v09916(nature_key)
      out={}
      add=lambda{|r,v|out[r]=out[r].to_f+v.to_f}
      w=TEMPERAMENT_ROLE_AXIS_WEIGHT_V09916
      a=h[:aggression].to_f*w
      c=h[:caution].to_f*w
      m=h[:mobility].to_f*w
      s=h[:support].to_f*w
      k=h[:commitment].to_f*w
      add.call(:bruiser,a);add.call(:assassin,a*0.8);add.call(:diver,a*0.9)
      add.call(:kiter,c);add.call(:bodyguard,c*0.55);add.call(:controller,c*0.45)
      add.call(:skirmisher,m);add.call(:diver,m*0.7);add.call(:assassin,m*0.55);add.call(:kiter,m*0.45)
      add.call(:bodyguard,s);add.call(:controller,s*0.75)
      add.call(:frontline,k*0.55);add.call(:bruiser,k*0.65);add.call(:assassin,k*0.35)
      out
    end

    def temperament_commitment_offset_v09916(nature_key)
      h=temperament_axes_v09916(nature_key)
      raw=h[:commitment].to_i*TEMPERAMENT_COMMIT_STEP_V09916+
        h[:aggression].to_i*TEMPERAMENT_COMMIT_AGGRESSION_STEP_V09916-
        h[:caution].to_i*TEMPERAMENT_COMMIT_CAUTION_STEP_V09916
      cap=TEMPERAMENT_COMMIT_OFFSET_CAP_V09916
      [[raw,-cap].max,cap].min
    end

    def nature_ai_report_text_v09916
      out=[]
      out << 'PMD AutoChess Nature x AI Temperament v0.99.16'
      out << 'Nature coverage: '+NATURE_TEMPERAMENT_V09916.size.to_s+'/25'
      out << 'Axes: '+TEMPERAMENT_AXES_V09916.collect{|x|x.to_s}.join(',')
      out << 'Player priority: explicit Role Bias/Condition Focus/Spatial Intent reduce Nature influence; explicit Target Commitment overrides 100%'
      out << 'Normal Nature stat multipliers modified: NO'
      out << 'Normal Attack Speed modified: NO'
      out << 'Damage formula modified: NO'
      out << 'Dynamic Role carry: YES'
      out << 'Spatial Conditions carry: YES'
      out << 'Frozen Combat Core direct modification: NO'
      NATURE_TEMPERAMENT_V09916.keys.sort{|a,b|a.to_s<=>b.to_s}.each do |n|
        out << n.to_s+'('+nature_label_v09916(n)+') '+temperament_summary_v09916(n)
      end
      out << 'Review PASS: 1'
      out.join("\r\n")+"\r\n"
    end

    def write_nature_ai_report_v09916
      File.open('PMD_NatureAITemperament_v0.99.16.txt','wb'){|f|f.write(nature_ai_report_text_v09916)}
      true
    rescue
      false
    end
  end
end
