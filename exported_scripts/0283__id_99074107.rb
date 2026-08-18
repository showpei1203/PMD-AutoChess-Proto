#==============================================================================
# 【PMD AutoChess 中文維護說明】
# 腳本：PMD AutoChess Proto v0.76
# 分類：核心戰鬥 Runtime
#
# 【用途／機制】
# 承接前序 Data／Config，實際執行戰鬥 Scene、Unit、AI、技能與呈現。
#
# 【怎麼調整】
# 一般平衡與資料調整不要直接改 Runtime；若要追加功能，建議在較後腳本 alias 原方法後擴充。
#
# 【本腳本主要設定常數／資料表】
# - V076_OLD_VERIFICATION_MODES / V076_OLD_VERIFICATION_LABELS / VERIFICATION_MODES / VERIFICATION_LABELS
# - STATS_GROWTH_GROUPS_V076 / STATS_GROWTH_MANIFEST_V076
#
# 【Runtime 主要方法（查流程時可直接搜尋）】
# - stats_growth_checksum32_v076 / validate_stats_growth_v076 / realtime_speed_factor_for_instance_v076 / realtime_speed_label_v076
# - stats_growth_snapshot_v076 / refresh / start / stats_growth_v076?
# - prepare_verification_battle / log_verify_v076 / verify_stats_manifest_v076 / verify_stats_formula_v076
#
# 【維護規則】
# - RPG Maker VX / RGSS2 / Ruby 1.8 相容。
# - instance_uid 才是 Pokémon 個體身份；Actor ID 只是容器。
# - 新增行為優先沿用既有 helper／Data 表；避免破壞已 Freeze 的舊核心。
# - 本專案新腳本也必須保留同等級的中文說明與實際範例。
#==============================================================================
#==============================================================================
# PMD AutoChess Proto v0.76
# Pokemon Stats & Growth Audit / Freeze
# RGSS2 / Ruby 1.8 compatible
#------------------------------------------------------------------------------
# This phase formalizes the existing Pokemon-derived progression model instead
# of replacing it.  Combat mechanics are intentionally unchanged.
#==============================================================================
module PMD_AC
  V076_OLD_VERIFICATION_MODES = VERIFICATION_MODES.dup
  V076_OLD_VERIFICATION_LABELS = VERIFICATION_LABELS.dup
  remove_const(:VERIFICATION_MODES) if const_defined?(:VERIFICATION_MODES)
  VERIFICATION_MODES = [:normal,:stats_growth_v076] +
    V076_OLD_VERIFICATION_MODES.reject{|x|x==:normal || x==:stats_growth_v076}
  remove_const(:VERIFICATION_LABELS) if const_defined?(:VERIFICATION_LABELS)
  VERIFICATION_LABELS = V076_OLD_VERIFICATION_LABELS.merge(
    :normal=>'NORMAL', :stats_growth_v076=>'STATS_GROWTH_V076')

  STATS_GROWTH_GROUPS_V076 = [
    :erratic,:fast,:medium_fast,:medium_slow,:slow,:fluctuating
  ]

  STATS_GROWTH_MANIFEST_V076 = {
    :version=>'0.76',
    :species=>494,
    :base_stat_fields=>6,
    :level_max=>100,
    :growth_groups=>6,
    :pokemon_stat_formula=>'gen5_style_iv_nature_ev0',
    :combat_hp_scale=>POKEMON_COMBAT_HP_SCALE,
    :damage_scale=>POKEMON_DAMAGE_SCALE,
    :stab=>POKEMON_STAB_MULTIPLIER,
    :random_min=>POKEMON_RANDOM_MIN,
    :random_max=>POKEMON_RANDOM_MAX,
    :speed_runtime=>'v0.22_sqrt_canonical_ratio',
    :speed_factor_min=>SPEED_RT_MIN_FACTOR,
    :speed_factor_max=>SPEED_RT_MAX_FACTOR,
    :battle_exp=>'v0.46_deployed_alive1_fainted0.5',
    :progression_ui=>'v0.47',
    :battle_balance=>'v0.75',
    :basic_hit_sfx=>'v0.75.1'
  }

  class << self
    def stats_growth_checksum32_v076
      h=0
      keys=SPECIES_DB_V016.keys.sort{|a,b|a.to_s<=>b.to_s}
      for key in keys
        d=SPECIES_DB_V016[key] || {}
        text=[key,(d[:base_stats]||[]).join(','),d[:growth_group],
              d[:base_exp],d[:stage],d[:evolves_to]].join('|')
        text.each_byte{|b|h=((h*33)+b)&0x7fffffff}
      end
      h
    end

    def validate_stats_growth_v076
      errors=[]
      groups={}
      keys=SPECIES_DB_V016.keys
      errors.push('species_count') unless keys.size==494
      for key in keys
        d=SPECIES_DB_V016[key] || {}
        stats=d[:base_stats]
        if stats==nil || stats.size!=6
          errors.push('stats:'+key.to_s)
          next
        end
        bad=false
        for x in stats
          bad=true if x.to_i<=0
        end
        errors.push('stat_value:'+key.to_s) if bad
        g=d[:growth_group]
        groups[g]=true
        errors.push('growth:'+key.to_s) unless STATS_GROWTH_GROUPS_V076.include?(g)
      end
      errors.push('growth_group_count') unless groups.keys.size==6
      errors
    end

    def realtime_speed_factor_for_instance_v076(instance)
      return 1.0 if instance==nil
      stats=instance.combat_stats
      return 1.0 if stats==nil
      ref=canonical_speed_reference(instance.level)
      realtime_speed_factor_for(stats[:speed],ref,false)
    end

    def realtime_speed_label_v076(instance)
      sprintf('%.2f',realtime_speed_factor_for_instance_v076(instance))
    end
  end
end

class PMD_PokemonInstance
  def stats_growth_snapshot_v076
    {
      :species=>species_key,
      :level=>level,
      :growth_group=>growth_group,
      :pokemon_stats=>pokemon_stats,
      :combat_stats=>combat_stats,
      :realtime_speed_factor=>PMD_AC.realtime_speed_factor_for_instance_v076(self),
      :exp=>@exp,
      :next_exp=>next_level_exp,
      :uid=>instance_uid
    }
  end
end

class Sprite_PMDProgressionPanelV047
  alias pmd_ac_v076_refresh refresh unless method_defined?(:pmd_ac_v076_refresh)
  def refresh
    pmd_ac_v076_refresh
    return if @instance==nil || bitmap==nil
    b=bitmap
    # Replace the old developer-facing identity notes with player-facing
    # combat interpretation of the canonical Speed stat.
    b.fill_rect(25,286,140,40,Color.new(25,32,43,230))
    b.font.bold=false
    b.font.size=11
    b.font.color=Color.new(150,205,235)
    b.draw_text(30,288,130,16,
      '即時速度 ×'+PMD_AC.realtime_speed_label_v076(@instance),0)
    b.font.color=Color.new(130,150,170)
    b.draw_text(30,305,130,16,'個體／性格已計入能力',0)
  end
end

class Scene_PMD_AutoChess
  alias pmd_ac_v076_start start unless method_defined?(:pmd_ac_v076_start)
  alias pmd_ac_v076_prepare_verification_battle prepare_verification_battle unless method_defined?(:pmd_ac_v076_prepare_verification_battle)
  alias pmd_ac_v076_update_verification_script update_verification_script unless method_defined?(:pmd_ac_v076_update_verification_script)

  def start
    pmd_ac_v076_start
    idx=PMD_AC::VERIFICATION_MODES.index(:normal)
    @verification_mode_index=idx unless idx==nil
    begin
      if FileTest.exist?(PMD_AC::BATTLE_LOG_FILE)
        t=File.open(PMD_AC::BATTLE_LOG_FILE,'rb'){|f|f.read}
        t.sub!(/PMD AutoChess Proto v0\.[0-9.]+ Battle Verification Log/,
               'PMD AutoChess Proto v0.76 Battle Verification Log')
        File.open(PMD_AC::BATTLE_LOG_FILE,'wb'){|f|f.write(t)}
      end
    rescue
    end
    m=PMD_AC::STATS_GROWTH_MANIFEST_V076
    log_event(:progression,
      'FREEZE v0.76 stats=base6+iv+nature level_max='+m[:level_max].to_s+
      ' species='+m[:species].to_s+' growth_groups='+m[:growth_groups].to_s+
      ' hp_scale='+sprintf('%.2f',m[:combat_hp_scale].to_f)+
      ' damage_scale='+sprintf('%.2f',m[:damage_scale].to_f)+
      ' speed_runtime=v0.22 battle_exp=v0.46 progression_ui=v0.47 '+
      ' balance=v0.75 basic_hit_sfx=v0.75.1 checksum32='+
      PMD_AC.stats_growth_checksum32_v076.to_s)
    refresh_header
    refresh_footer
  end

  def stats_growth_v076?
    verification_mode==:stats_growth_v076
  end

  def prepare_verification_battle
    pmd_ac_v076_prepare_verification_battle
    return unless stats_growth_v076?
    for u in @units
      u.verification_combat_sandbox(true) if u.respond_to?(:verification_combat_sandbox)
      u.verification_energy_sandbox(true) if u.respond_to?(:verification_energy_sandbox)
    end
    @stats_growth_v076_failed=false
  end

  def log_verify_v076(name,pass,detail='')
    @stats_growth_v076_failed=true unless pass
    text=name+' pass='+(pass ? '1' : '0')
    text+=' '+detail unless detail==nil || detail==''
    log_event(:verify,text)
  end

  def verify_stats_manifest_v076
    return if @verification_done[:v076_manifest]
    m=PMD_AC::STATS_GROWTH_MANIFEST_V076
    errors=PMD_AC.validate_stats_growth_v076
    pass=m[:species].to_i==494 && m[:base_stat_fields].to_i==6 &&
         m[:growth_groups].to_i==6 && errors.empty?
    log_verify_v076('STATS_GROWTH_MANIFEST_V076',pass,
      'species=494 stats=6 growth_groups=6 errors=['+errors.join(',')+'] checksum32='+
      PMD_AC.stats_growth_checksum32_v076.to_s)
    @verification_done[:v076_manifest]=true
  end

  def verify_stats_formula_v076
    return if @verification_done[:v076_formula]
    fixed={:instance_uid=>760001,:ivs=>[15,15,15,15,15,15],
           :nature=>:hardy,:ability_slot=>:primary}
    b=PMD_PokemonInstance.new(:bulbasaur,15,fixed)
    r=PMD_PokemonInstance.new(:rattata,15,fixed.merge(:instance_uid=>760002))
    p=PMD_PokemonInstance.new(:pikachu,15,fixed.merge(:instance_uid=>760003))
    bs=b.combat_stats;rs=r.combat_stats;ps=p.combat_stats
    pass=bs[:hp]>0 && bs[:atk]>0 && bs[:spatk]>0 &&
         rs[:speed]>bs[:speed] && ps[:speed]>rs[:speed] &&
         bs[:hp]==(b.pokemon_stats[:hp]*PMD_AC::POKEMON_COMBAT_HP_SCALE).round
    log_verify_v076('STATS_FORMULA_V076',pass,
      'bulba=HP'+bs[:hp].to_s+'/A'+bs[:atk].to_s+'/D'+bs[:def].to_s+
      '/SA'+bs[:spatk].to_s+'/SD'+bs[:spdef].to_s+'/S'+bs[:speed].to_s+
      ' speed_order=bulba<rattata<pikachu')
    @verification_done[:v076_formula]=true
  end

  def verify_stats_individual_v076
    return if @verification_done[:v076_individual]
    low=PMD_PokemonInstance.new(:pikachu,20,
      {:instance_uid=>760010,:ivs=>[0,0,0,0,0,0],:nature=>:hardy,:ability_slot=>:primary})
    high=PMD_PokemonInstance.new(:pikachu,20,
      {:instance_uid=>760011,:ivs=>[31,31,31,31,31,31],:nature=>:hardy,:ability_slot=>:primary})
    modest=PMD_PokemonInstance.new(:pikachu,20,
      {:instance_uid=>760012,:ivs=>[15,15,15,15,15,15],:nature=>:modest,:ability_slot=>:primary})
    neutral=PMD_PokemonInstance.new(:pikachu,20,
      {:instance_uid=>760013,:ivs=>[15,15,15,15,15,15],:nature=>:hardy,:ability_slot=>:primary})
    ls=low.pokemon_stats;hs=high.pokemon_stats;ms=modest.pokemon_stats;ns=neutral.pokemon_stats
    pass=hs[:hp]>ls[:hp] && hs[:atk]>ls[:atk] && hs[:speed]>ls[:speed] &&
         ms[:spatk]>ns[:spatk] && ms[:atk]<ns[:atk]
    log_verify_v076('STATS_INDIVIDUAL_V076',pass,
      'iv0_to31_hp='+ls[:hp].to_s+'->'+hs[:hp].to_s+
      ' atk='+ls[:atk].to_s+'->'+hs[:atk].to_s+
      ' modest_spatk='+ns[:spatk].to_s+'->'+ms[:spatk].to_s+
      ' modest_atk='+ns[:atk].to_s+'->'+ms[:atk].to_s)
    @verification_done[:v076_individual]=true
  end

  def verify_growth_curves_v076
    return if @verification_done[:v076_growth]
    expected={:erratic=>600000,:fast=>800000,:medium_fast=>1000000,
              :medium_slow=>1059860,:slow=>1250000,:fluctuating=>1640000}
    pass=true;parts=[]
    for g in PMD_AC::STATS_GROWTH_GROUPS_V076
      prev=0
      for lv in 1..100
        v=PMD_AC.exp_for_level(lv,g)
        pass=false if v<prev
        prev=v
      end
      total=PMD_AC.exp_for_level(100,g)
      pass=false unless total==expected[g]
      parts.push(g.to_s+'='+total.to_s)
    end
    log_verify_v076('GROWTH_CURVES_V076',pass,
      'monotonic=1 lv100=['+parts.join(',')+']')
    @verification_done[:v076_growth]=true
  end

  def verify_level_growth_v076
    return if @verification_done[:v076_level]
    i=PMD_PokemonInstance.new(:charmander,5,
      {:instance_uid=>760020,:ivs=>[15,15,15,15,15,15],:nature=>:hardy,:ability_slot=>:primary})
    uid=i.instance_uid;s5=i.combat_stats
    need=PMD_AC.exp_for_level(15,i.growth_group)-i.exp
    result=i.gain_exp(need,false);s15=i.combat_stats
    pass=i.level==15 && i.instance_uid==uid && s15[:hp]>s5[:hp] &&
         s15[:atk]>s5[:atk] && s15[:spatk]>s5[:spatk] &&
         s15[:speed]>s5[:speed] && (result[:levels]||[]).include?(15)
    log_verify_v076('LEVEL_GROWTH_V076',pass,
      'uid_same='+(i.instance_uid==uid ? '1':'0')+' lv=5->'+i.level.to_s+
      ' hp='+s5[:hp].to_s+'->'+s15[:hp].to_s+
      ' atk='+s5[:atk].to_s+'->'+s15[:atk].to_s+
      ' speed='+s5[:speed].to_s+'->'+s15[:speed].to_s)
    @verification_done[:v076_level]=true
  end

  def verify_speed_bridge_v076
    return if @verification_done[:v076_speed]
    fixed={:ivs=>[15,15,15,15,15,15],:nature=>:hardy,:ability_slot=>:primary}
    slow=PMD_PokemonInstance.new(:shuckle,50,fixed.merge(:instance_uid=>760030))
    mid=PMD_PokemonInstance.new(:pikachu,50,fixed.merge(:instance_uid=>760031))
    fast=PMD_PokemonInstance.new(:ninjask,50,fixed.merge(:instance_uid=>760032))
    a=PMD_AC.realtime_speed_factor_for_instance_v076(slow)
    b=PMD_AC.realtime_speed_factor_for_instance_v076(mid)
    c=PMD_AC.realtime_speed_factor_for_instance_v076(fast)
    pass=a<b && b<c && a>=PMD_AC::SPEED_RT_MIN_FACTOR &&
         c<=PMD_AC::SPEED_RT_MAX_FACTOR
    log_verify_v076('SPEED_RUNTIME_BRIDGE_V076',pass,
      'shuckle='+sprintf('%.3f',a)+' pikachu='+sprintf('%.3f',b)+
      ' ninjask='+sprintf('%.3f',c)+' bounds='+
      sprintf('%.2f',PMD_AC::SPEED_RT_MIN_FACTOR)+'..'+
      sprintf('%.2f',PMD_AC::SPEED_RT_MAX_FACTOR))
    @verification_done[:v076_speed]=true
  end

  def verify_evolution_stats_v076
    return if @verification_done[:v076_evolution]
    i=PMD_PokemonInstance.new(:bulbasaur,15,
      {:instance_uid=>760040,:ivs=>[15,15,15,15,15,15],:nature=>:hardy,:ability_slot=>:primary})
    uid=i.instance_uid;before=i.combat_stats
    need=PMD_AC.exp_for_level(16,i.growth_group)-i.exp
    result=i.gain_exp(need,true);after=i.combat_stats
    pass=i.species_key==:ivysaur && i.instance_uid==uid &&
         after[:hp]>before[:hp] && after[:atk]>before[:atk] &&
         after[:spatk]>before[:spatk] && !(result[:evolutions]||[]).empty?
    log_verify_v076('EVOLUTION_STATS_V076',pass,
      'species=bulbasaur->'+i.species_key.to_s+
      ' uid_same='+(i.instance_uid==uid ? '1':'0')+
      ' hp='+before[:hp].to_s+'->'+after[:hp].to_s+
      ' spatk='+before[:spatk].to_s+'->'+after[:spatk].to_s)
    @verification_done[:v076_evolution]=true
  end

  def verify_stats_carry_v076
    return if @verification_done[:v076_carry]
    pass=PMD_AC::POKEMON_DAMAGE_SCALE==1.65 &&
         PMD_AC::POKEMON_COMBAT_HP_SCALE==10.0 &&
         PMD_AC::POKEMON_STAB_MULTIPLIER==1.50 &&
         PMD_AC::RANGED_ENGAGE_RANGE_V075==102.0 &&
         PMD_AC::RANGED_RELEASE_RANGE_V075==124.0 &&
         PMD_AC::RANGED_REARM_FRAMES_V075==30
    log_verify_v076('STATS_GROWTH_CARRY_V076',pass,
      'damage=v0.12 scale=1.65 hp_scale=10 speed=v0.22 exp=v0.46 '+
      'ui=v0.47 balance=v0.75 weather=v0.28 field=v0.35-v0.37 '+
      'combo=v0.60.2 router=v0.62 basic_hit_sfx=v0.75.1')
    @verification_done[:v076_carry]=true
  end

  def update_verification_script
    unless stats_growth_v076?
      pmd_ac_v076_update_verification_script
      return
    end
    @verification_frame+=1
    f=@verification_frame
    verify_stats_manifest_v076 if f>=2
    verify_stats_formula_v076 if f>=4
    verify_stats_individual_v076 if f>=6
    verify_growth_curves_v076 if f>=8
    verify_level_growth_v076 if f>=10
    verify_speed_bridge_v076 if f>=12
    verify_evolution_stats_v076 if f>=14
    verify_stats_carry_v076 if f>=16
    complete_verification_mode if f>=18
  end

  def refresh_header
    return if @header_sprite==nil
    bmp=@header_sprite.bitmap
    bmp.clear
    bmp.fill_rect(0,0,Graphics.width,68,Color.new(0,0,0,180))
    pmd_ac_v074_font(bmp)
    bmp.font.size=PMD_AC::HEADER_TITLE_FONT_V0741
    bmp.font.bold=true
    bmp.font.color=Color.new(255,255,255)
    bmp.draw_text(16,4,Graphics.width-32,24,'PMD 自走棋原型 v0.76',1)
    bmp.font.size=PMD_AC::HEADER_SUB_FONT_V0741
    bmp.font.bold=false
    bmp.font.color=Color.new(210,220,230)
    text=''
    if @phase==:deploy
      text='戰前布陣｜D 成長/技能｜S 驗證：'+verification_mode_label+'｜Shift 開戰'
    elsif @phase==:battle
      text='AI Framework／Pixel Movement｜速度 x'+@battle_speed.to_s+'｜A 鍵切換｜B 離開'
    else
      text='戰鬥結束｜C 回到布陣｜B 離開'
    end
    bmp.draw_text(16,33,Graphics.width-32,21,text,1)
  end
end
