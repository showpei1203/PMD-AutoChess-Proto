#==============================================================================
# 【PMD AutoChess 中文維護說明】
# 腳本：PMD AutoChess Proto v0.23
# 分類：核心戰鬥 Runtime
#
# 【用途／機制】
# 承接前序 Data／Config，實際執行戰鬥 Scene、Unit、AI、技能與呈現。
#
# 【怎麼調整】
# 一般平衡與資料調整不要直接改 Runtime；若要追加功能，建議在較後腳本 alias 原方法後擴充。
#
# 【本腳本主要設定常數／資料表】
# - ACTION_STATUS_RUNTIME_FILE / USE_EXTERNAL_ACTION_STATUS_DB / VERIFICATION_ACTION_STATUS_END_FRAME / FREEZE_THAW_CHANCE
# - CONFUSION_SELF_HIT_CHANCE / CONFUSION_SELF_HIT_POWER / VERIFICATION_MODES / VERIFICATION_LABELS
#
# 【Runtime 主要方法（查流程時可直接搜尋）】
# - loaded? / using_runtime_file? / load_error / manifest
# - embedded_data / load! / behavior / keys
# - behavior_count / canonical_move_key_from_skill / move_executable? / move_autochess_hint
#
# 【維護規則】
# - RPG Maker VX / RGSS2 / Ruby 1.8 相容。
# - instance_uid 才是 Pokémon 個體身份；Actor ID 只是容器。
# - 新增行為優先沿用既有 helper／Data 表；避免破壞已 Freeze 的舊核心。
# - 本專案新腳本也必須保留同等級的中文說明與實際範例。
#==============================================================================
#==============================================================================
# ■ PMD AutoChess Proto v0.23
#    Canonical Sleep / Freeze / Confusion / Flinch Action Status Layer
#------------------------------------------------------------------------------
#  Base: verified v0.22.1 FullTestProject.
#  Existing combat Core and prior data layers remain untouched.
#==============================================================================
module PMD_AC
  ACTION_STATUS_RUNTIME_FILE="Data/PMD_AutoChess_ActionStatus_v023_000.rvdata"
  USE_EXTERNAL_ACTION_STATUS_DB=true unless const_defined?(:USE_EXTERNAL_ACTION_STATUS_DB)
  VERIFICATION_ACTION_STATUS_END_FRAME=420
  FREEZE_THAW_CHANCE=20
  CONFUSION_SELF_HIT_CHANCE=50
  CONFUSION_SELF_HIT_POWER=40
  STATUS_DEFS[:sleep]={:tags=>[:debuff,:control,:major_status,:sleep],:stack_mode=>:refresh} unless STATUS_DEFS.has_key?(:sleep)
  STATUS_DEFS[:freeze]={:tags=>[:debuff,:control,:major_status,:freeze],:stack_mode=>:refresh} unless STATUS_DEFS.has_key?(:freeze)
  STATUS_DEFS[:confusion]={:tags=>[:debuff,:control,:volatile,:confusion],:stack_mode=>:refresh} unless STATUS_DEFS.has_key?(:confusion)

  module ActionStatusDB
    @loaded=false;@using_runtime_file=false;@load_error=nil;@data=nil
    class << self
      def loaded?;@loaded ? true : false;end
      def using_runtime_file?;@using_runtime_file ? true : false;end
      def load_error;@load_error;end
      def manifest;@data==nil ? {} : (@data[:manifest]||{});end
      def embedded_data;{:manifest=>PMD_AC::ACTION_STATUS_MANIFEST_V023,:behaviors=>PMD_AC::ACTION_STATUS_MOVE_V023};end
      def load!
        return true if @loaded
        @load_error=nil;@using_runtime_file=false;data=nil
        if PMD_AC::USE_EXTERNAL_ACTION_STATUS_DB && FileTest.exist?(PMD_AC::ACTION_STATUS_RUNTIME_FILE)
          begin
            c=load_data(PMD_AC::ACTION_STATUS_RUNTIME_FILE)
            if c.is_a?(Hash) && c[:manifest] && c[:behaviors].is_a?(Hash) && c[:manifest][:schema_version]=="1.0" && c[:manifest][:new_mapped_move_count].to_i==47
              data=c;@using_runtime_file=true
            end
          rescue => e
            @load_error=e.class.to_s+":"+e.message.to_s
          end
        end
        data=embedded_data if data==nil;@data=data;@loaded=true
        if PMD_AC::USE_EXTERNAL_ACTION_STATUS_DB && !@using_runtime_file
          begin;save_data(@data,PMD_AC::ACTION_STATUS_RUNTIME_FILE);rescue => e;@load_error=e.class.to_s+":"+e.message.to_s;end
        end
        true
      end
      def behavior(key);load! unless loaded?;(@data[:behaviors]||{})[key];end
      def keys;load! unless loaded?;(@data[:behaviors]||{}).keys;end
      def behavior_count;keys.size;end
    end
  end

  class << self
    alias pmd_ac_v023_move_executable move_executable? unless method_defined?(:pmd_ac_v023_move_executable)
    alias pmd_ac_v023_move_autochess_hint move_autochess_hint unless method_defined?(:pmd_ac_v023_move_autochess_hint)
    alias pmd_ac_v023_skill_data skill_data unless method_defined?(:pmd_ac_v023_skill_data)
    alias pmd_ac_v023_canonical_move_key_from_skill canonical_move_key_from_skill unless method_defined?(:pmd_ac_v023_canonical_move_key_from_skill)
    def canonical_move_key_from_skill(skill_key)
      key=pmd_ac_v023_canonical_move_key_from_skill(skill_key);return key if key!=nil
      return nil if skill_key==nil;text=skill_key.to_s;return nil unless text[0,3]=="mv_"
      k=text[3,text.size-3].to_sym;ActionStatusDB.behavior(k)==nil ? nil : k
    end
    def move_executable?(move_key);return true if ActionStatusDB.behavior(move_key)!=nil;pmd_ac_v023_move_executable(move_key);end
    def move_autochess_hint(move_key)
      base=pmd_ac_v023_move_autochess_hint(move_key);b=ActionStatusDB.behavior(move_key);return base if b==nil
      r=base==nil ? {} : base.dup;r[:behavior_status]=b[:behavior_status];r[:delivery]=b[:delivery];r[:range_px]=b[:range_px];r[:runtime_skill_key]=b[:runtime_skill_key];r
    end
    def skill_data(key)
      old=pmd_ac_v023_skill_data(key);return old if old!=nil && !old.empty?
      mk=canonical_move_key_from_skill(key);return {} if mk==nil;d=ActionStatusDB.behavior(mk);return {} if d==nil
      r=d.dup;r[:move_type]=d[:type];r[:damage_category]=d[:category];r[:canonical_move_key]=mk;r
    end
    def action_status_checksum32
      h=0
      for key in ActionStatusDB.keys.sort{|a,b|a.to_s<=>b.to_s}
        r=ActionStatusDB.behavior(key);eff=[];sec=[]
        for e in (r[:effects]||[]);eff.push([e[:type],e[:power],e[:stat],e[:stages],e[:min_turns],e[:max_turns]].join(","));end
        for e in (r[:secondary_effects]||[]);sec.push([e[:group],e[:type],e[:status],e[:chance],e[:receiver],e[:min_turns],e[:max_turns]].join(","));end
        text=[key,r[:runtime_skill_key],r[:target],r[:delivery],r[:range_px],r[:global_direct],eff.join(";"),sec.join(";")].join("|")
        text.each_byte{|b|h=((h*33)+b)&0x7fffffff}
      end
      h
    end
    def validate_action_status_db
      e=[]
      for k in ActionStatusDB.keys
        r=ActionStatusDB.behavior(k);e.push("move:"+k.to_s) if move_data(k)==nil;e.push("skill:"+k.to_s) unless r[:runtime_skill_key]==canonical_runtime_skill_key(k);e.push("effects:"+k.to_s) if (r[:effects]||[]).empty?
      end
      e.push("count") unless ActionStatusDB.behavior_count==47
      for k in [:spore,:ice_beam,:confuse_ray,:bite,:ice_fang,:fire_fang,:thunder_fang];e.push("missing:"+k.to_s) if ActionStatusDB.behavior(k)==nil;end
      for k in [:fake_out,:snore,:chatter,:teeter_dance];e.push("deferred:"+k.to_s) if ActionStatusDB.behavior(k)!=nil;end
      e.push("checksum") unless action_status_checksum32==ActionStatusDB.manifest[:runtime_checksum32].to_i
      e
    end
  end
  ActionStatusDB.load!

  remove_const(:VERIFICATION_MODES) if const_defined?(:VERIFICATION_MODES)
  VERIFICATION_MODES=[:normal,:control,:beam,:zone,:hit,:energy,:direction,:object,:summon,:identity,:progression,:individual,:mega,:synergy,:species_db,:move_db,:move_runtime,:stat_stage,:sustain,:secondary,:speed_status,:action_status]
  remove_const(:VERIFICATION_LABELS) if const_defined?(:VERIFICATION_LABELS)
  VERIFICATION_LABELS={:normal=>"NORMAL",:control=>"CONTROL",:beam=>"BEAM",:zone=>"ZONE",:hit=>"HIT",:energy=>"ENERGY",:direction=>"DIRECTION",:object=>"OBJECT",:summon=>"SUMMON",:identity=>"IDENTITY",:progression=>"PROGRESSION",:individual=>"INDIVIDUAL",:mega=>"MEGA",:synergy=>"SYNERGY",:species_db=>"SPECIES_DB",:move_db=>"MOVE_DB",:move_runtime=>"MOVE_RUNTIME",:stat_stage=>"STAT_STAGE",:sustain=>"SUSTAIN",:secondary=>"SECONDARY",:speed_status=>"SPEED_STATUS",:action_status=>"ACTION_STATUS"}
end

class Game_PMDChessUnit
  alias pmd_ac_v023_update_logic update_logic unless method_defined?(:pmd_ac_v023_update_logic)
  alias pmd_ac_v023_begin_attack begin_attack unless method_defined?(:pmd_ac_v023_begin_attack)
  alias pmd_ac_v023_begin_skill begin_skill unless method_defined?(:pmd_ac_v023_begin_skill)
  alias pmd_ac_v023_status_debug_label status_debug_label unless method_defined?(:pmd_ac_v023_status_debug_label)
  alias pmd_ac_v023_verification_clear_status verification_clear_status unless method_defined?(:pmd_ac_v023_verification_clear_status)

  def sleeping?;status?(:sleep);end
  def frozen?;status?(:freeze);end
  def confused?;status?(:confusion);end
  def canonical_flinch_pending?;@canonical_flinch_pending ? true : false;end
  def canonical_major_status_active?;[:burn,:poison,:paralysis,:sleep,:freeze].any?{|k|status?(k)};end
  def canonical_action_status_roll(key,max)
    if @scene!=nil && @scene.respond_to?(:canonical_action_status_roll);return @scene.canonical_action_status_roll(key,max);end
    rand(max)
  end
  def canonical_cancel_unresolved_action(reason)
    return false unless acting? && !@action_hit_done
    @action_timer=0;@action_total_frames=0;@action_hit_frame=0;@action_hit_done=false;@action=:idle;@visual_action=:idle;@action_lunge=0.0;@channeling=false;@skill_target=nil
    clear_move_goal;@velocity_x*=PMD_AC::STOP_DAMPING;@velocity_y*=PMD_AC::STOP_DAMPING
    @scene.release_attack_slot(self) if @scene!=nil
    log_event(:action_status,log_name+" INTERRUPT reason="+reason.to_s)
    true
  end
  def canonical_apply_sleep(source=nil)
    return false if dead? || canonical_major_status_active?
    turns=2+canonical_action_status_roll(:sleep_turns,3)
    apply_status(:sleep,{:duration=>999999,:value=>0,:interval=>999999,:stack_mode=>:refresh},source)
    @canonical_sleep_turns=turns;@canonical_status_wait=effective_attack_wait.to_f
    canonical_cancel_unresolved_action(:sleep)
    log_event(:action_status,log_name+" SLEEP turns="+turns.to_s+" blocked="+(turns-1).to_s)
    true
  end
  def canonical_apply_freeze(source=nil)
    return false if dead? || canonical_major_status_active? || pokemon_types.include?(:ice)
    apply_status(:freeze,{:duration=>999999,:value=>0,:interval=>999999,:stack_mode=>:refresh},source)
    @canonical_status_wait=effective_attack_wait.to_f;canonical_cancel_unresolved_action(:freeze)
    log_event(:action_status,log_name+" FREEZE")
    true
  end
  def canonical_apply_confusion(source=nil)
    return false if dead? || confused?
    turns=2+canonical_action_status_roll(:confusion_turns,4)
    apply_status(:confusion,{:duration=>999999,:value=>0,:interval=>999999,:stack_mode=>:refresh},source)
    @canonical_confusion_turns=turns
    log_event(:action_status,log_name+" CONFUSION turns="+turns.to_s)
    true
  end
  def canonical_apply_flinch(source=nil)
    return false if dead? || sleeping? || frozen?
    if acting?
      return canonical_cancel_unresolved_action(:flinch) unless @action_hit_done
      return false
    end
    @canonical_flinch_pending=true
    log_event(:action_status,log_name+" FLINCH_PENDING")
    true
  end
  def canonical_clear_action_status(key,reason=:expire)
    @statuses.delete(key) if @statuses!=nil
    @canonical_sleep_turns=0 if key==:sleep
    @canonical_confusion_turns=0 if key==:confusion
    @canonical_status_wait=0.0 if key==:sleep || key==:freeze
    log_event(:action_status,log_name+" "+key.to_s.upcase+" CLEAR reason="+reason.to_s)
  end
  def verification_clear_status(key)
    pmd_ac_v023_verification_clear_status(key)
    @canonical_sleep_turns=0 if key==:sleep
    @canonical_confusion_turns=0 if key==:confusion
    @canonical_status_wait=0.0 if key==:sleep || key==:freeze
    @canonical_flinch_pending=false if key==:flinch
  end
  def verification_set_sleep_turns(v);@canonical_sleep_turns=v.to_i;@canonical_status_wait=0.0;end
  def verification_set_confusion_turns(v);@canonical_confusion_turns=v.to_i;end
  def verification_force_status_wait_ready;@canonical_status_wait=0.0;end
  def canonical_update_immobilized_status
    return false unless sleeping? || frozen?
    clear_move_goal;@velocity_x*=PMD_AC::STOP_DAMPING;@velocity_y*=PMD_AC::STOP_DAMPING
    @canonical_status_wait=effective_attack_wait.to_f if @canonical_status_wait==nil
    @canonical_status_wait-=PMD_AC::LOGIC_TICK*attack_speed_multiplier
    return true if @canonical_status_wait>0
    if sleeping?
      if @canonical_sleep_turns.to_i<=1
        canonical_clear_action_status(:sleep,:wake);@attack_wait=0;return false
      end
      @canonical_sleep_turns-=1;@canonical_status_wait=effective_attack_wait.to_f
      log_event(:action_status,log_name+" SLEEP_BLOCK remaining="+(@canonical_sleep_turns-1).to_s);return true
    end
    if frozen?
      roll=canonical_action_status_roll(:freeze_thaw,100)
      if roll<PMD_AC::FREEZE_THAW_CHANCE
        canonical_clear_action_status(:freeze,:thaw);@attack_wait=0;log_event(:action_status,log_name+" THAW roll="+roll.to_s);return false
      end
      @canonical_status_wait=effective_attack_wait.to_f;log_event(:action_status,log_name+" FREEZE_BLOCK roll="+roll.to_s);return true
    end
    false
  end
  def update_logic
    return if canonical_update_immobilized_status
    pmd_ac_v023_update_logic
  end
  def canonical_consume_flinch(kind)
    return false unless canonical_flinch_pending?
    @canonical_flinch_pending=false
    @attack_wait=@attack_wait_max.to_f if kind==:basic
    if kind==:skill;@energy=0;@skill_target=nil;end
    log_event(:action_status,log_name+" FLINCH_BLOCK kind="+kind.to_s)
    @scene.add_skill_effect(self,:stun) if @scene!=nil
    true
  end
  def canonical_confusion_self_damage
    defense_value=[defense.to_i,1].max;power=PMD_AC::CONFUSION_SELF_HIT_POWER
    lf=(2*level/5)+2;base=(((lf*power*atk)/defense_value)/50)+2;base=[(base*PMD_AC::POKEMON_DAMAGE_SCALE).round,1].max
    roll=PMD_AC::POKEMON_RANDOM_MIN+canonical_action_status_roll(:confusion_damage_roll,PMD_AC::POKEMON_RANDOM_MAX-PMD_AC::POKEMON_RANDOM_MIN+1)
    [(base.to_f*roll.to_f/100.0).floor,1].max
  end
  def canonical_confusion_action_block?(kind)
    return false unless confused?
    if @canonical_confusion_turns.to_i<=1
      canonical_clear_action_status(:confusion,:snap_out);return false
    end
    @canonical_confusion_turns-=1
    roll=canonical_action_status_roll(:confusion_self_hit,100)
    if roll<PMD_AC::CONFUSION_SELF_HIT_CHANCE
      dmg=canonical_confusion_self_damage;before=@hp;receive_damage(dmg,self,false,true,false)
      @attack_wait=@attack_wait_max.to_f if kind==:basic
      if kind==:skill;@energy=0;@skill_target=nil;end
      log_event(:confusion,log_name+" SELF_HIT roll="+roll.to_s+" damage="+(before-@hp).to_s+" remaining="+(@canonical_confusion_turns-1).to_s)
      @scene.add_skill_effect(self,:debuff) if @scene!=nil
      return true
    end
    log_event(:confusion,log_name+" ACT_OK roll="+roll.to_s+" remaining="+(@canonical_confusion_turns-1).to_s);false
  end
  def v023_call_old_begin(kind,target=nil)
    @v023_skip_internal_paralysis=true
    begin
      kind==:basic ? pmd_ac_v023_begin_attack : pmd_ac_v023_begin_skill(target)
    ensure
      @v023_skip_internal_paralysis=false
    end
  end
  def v023_skip_internal_paralysis?;@v023_skip_internal_paralysis ? true : false;end
  def begin_attack
    return if canonical_consume_flinch(:basic)
    if paralyzed? && @scene!=nil && @scene.canonical_full_paralysis?(self,:basic);@attack_wait=@attack_wait_max.to_f;return;end
    return if canonical_confusion_action_block?(:basic)
    v023_call_old_begin(:basic)
  end
  def begin_skill(skill_target=nil)
    return if canonical_consume_flinch(:skill)
    if paralyzed? && @scene!=nil && @scene.canonical_full_paralysis?(self,:skill);@energy=0;@skill_target=nil;return;end
    return if canonical_confusion_action_block?(:skill)
    v023_call_old_begin(:skill,skill_target)
  end
  def status_debug_label
    text=pmd_ac_v023_status_debug_label;parts=[];parts.push("Slp") if sleeping?;parts.push("Frz") if frozen?;parts.push("Cnf") if confused?;parts.push("Fl") if canonical_flinch_pending?
    return text if parts.empty?;text==nil || text.empty? ? parts.join(" ") : text+" "+parts.join(" ")
  end
end

class Scene_PMD_AutoChess
  alias pmd_ac_v023_start start unless method_defined?(:pmd_ac_v023_start)
  alias pmd_ac_v023_prepare_verification_battle prepare_verification_battle unless method_defined?(:pmd_ac_v023_prepare_verification_battle)
  alias pmd_ac_v023_apply_skill_effects apply_skill_effects unless method_defined?(:pmd_ac_v023_apply_skill_effects)
  alias pmd_ac_v023_apply_canonical_secondary_group apply_canonical_secondary_group unless method_defined?(:pmd_ac_v023_apply_canonical_secondary_group)
  alias pmd_ac_v023_canonical_secondary_roll canonical_secondary_roll unless method_defined?(:pmd_ac_v023_canonical_secondary_roll)
  alias pmd_ac_v023_canonical_secondary_status_immune canonical_secondary_status_immune? unless method_defined?(:pmd_ac_v023_canonical_secondary_status_immune)
  alias pmd_ac_v023_canonical_full_paralysis canonical_full_paralysis? unless method_defined?(:pmd_ac_v023_canonical_full_paralysis)
  alias pmd_ac_v023_skill_cast_worthwhile skill_cast_worthwhile? unless method_defined?(:pmd_ac_v023_skill_cast_worthwhile)
  alias pmd_ac_v023_projectile_tracking_for projectile_tracking_for unless method_defined?(:pmd_ac_v023_projectile_tracking_for)
  alias pmd_ac_v023_update_verification_script update_verification_script unless method_defined?(:pmd_ac_v023_update_verification_script)
  alias pmd_ac_v023_log_event log_event unless method_defined?(:pmd_ac_v023_log_event)
  alias pmd_ac_v023_complete_verification_mode complete_verification_mode unless method_defined?(:pmd_ac_v023_complete_verification_mode)

  def start
    pmd_ac_v023_start
    begin
      if FileTest.exist?(PMD_AC::BATTLE_LOG_FILE)
        text=File.open(PMD_AC::BATTLE_LOG_FILE,"rb"){|f|f.read};text.sub!("PMD AutoChess Proto v0.22.1 Battle Verification Log","PMD AutoChess Proto v0.23 Battle Verification Log");File.open(PMD_AC::BATTLE_LOG_FILE,"wb"){|f|f.write(text)}
      end
    rescue;end
    m=PMD_AC::ActionStatusDB.manifest;log_event(:action_status,"LOADED new="+PMD_AC::ActionStatusDB.behavior_count.to_s+" cumulative="+m[:cumulative_mapped_move_count].to_s+" covered="+m[:cumulative_reference_covered].to_s+"/"+m[:learnset_reference_total].to_s+" source="+(PMD_AC::ActionStatusDB.using_runtime_file? ? "rvdata":"embedded")+" checksum32="+m[:runtime_checksum32].to_s)
  end
  def prepare_verification_battle
    pmd_ac_v023_prepare_verification_battle
    if verification_mode==:action_status
      for u in @units;u.verification_combat_sandbox(true);for k in [:sleep,:freeze,:confusion,:flinch,:burn,:poison,:paralysis];u.verification_clear_status(k);end;end
      @action_status_rolls={};@action_status_snapshots={};@action_status_verification_failed=false;@v023_perfect_tracking_skill=nil;@secondary_verification_rolls=[]
    end
  end
  def set_action_status_rolls(key,values);@action_status_rolls={} if @action_status_rolls==nil;@action_status_rolls[key]=values.dup;end
  def canonical_action_status_roll(key,max)
    a=@action_status_rolls==nil ? nil : @action_status_rolls[key]
    return a.shift.to_i if verification_mode==:action_status && a!=nil && !a.empty?
    rand(max)
  end
  def canonical_full_paralysis?(unit,kind=:action)
    return false if unit!=nil && unit.respond_to?(:v023_skip_internal_paralysis?) && unit.v023_skip_internal_paralysis?
    pmd_ac_v023_canonical_full_paralysis(unit,kind)
  end
  def canonical_secondary_status_immune?(unit,status)
    if unit!=nil && [:burn,:poison,:paralysis].include?(status) && unit.canonical_major_status_active?;return true;end
    pmd_ac_v023_canonical_secondary_status_immune(unit,status)
  end
  def apply_canonical_secondary_group(user,target,data,effects,result)
    custom=(effects||[]).any?{|e|[:canonical_freeze,:canonical_confusion,:canonical_flinch].include?(e[:type])}
    return pmd_ac_v023_apply_canonical_secondary_group(user,target,data,effects,result) unless custom
    return if effects==nil || effects.empty? || result.to_i<=0
    chance=effects[0][:chance].to_i;proc_result,roll=canonical_secondary_roll(chance);move=(data[:canonical_move_key]||:unknown).to_s
    log_event(:secondary,user.log_name+" move="+move+" chance="+chance.to_s+" roll="+roll.to_s+" proc="+(proc_result ? "1":"0"));return unless proc_result
    for e in effects
      receiver=e[:receiver]==:user ? user : target;next if receiver==nil || receiver.dead?
      case e[:type]
      when :canonical_freeze
        if receiver.pokemon_types.include?(:ice) || receiver.canonical_major_status_active?;log_event(:action_status,receiver.log_name+" FREEZE_IMMUNE");else;receiver.canonical_apply_freeze(user);add_skill_effect(receiver,:stun);end
      when :canonical_confusion
        receiver.canonical_apply_confusion(user);add_skill_effect(receiver,:debuff)
      when :canonical_flinch
        receiver.canonical_apply_flinch(user);add_skill_effect(receiver,:stun)
      end
    end
  end
  def apply_skill_effects(user,target,data,scale=1.0)
    result=pmd_ac_v023_apply_skill_effects(user,target,data,scale)
    return result if user==nil || target==nil
    for e in (data[:effects]||[])
      case e[:type]
      when :canonical_sleep
        if target.canonical_apply_sleep(user);add_skill_effect(target,:stun);else;log_event(:action_status,target.log_name+" SLEEP_FAIL status_or_dead");end
      when :canonical_confusion
        if target.canonical_apply_confusion(user);add_skill_effect(target,:debuff);end
      end
    end
    if result.to_i>0 && target.frozen? && data[:move_type]==:fire
      target.canonical_clear_action_status(:freeze,:fire_hit);log_event(:action_status,target.log_name+" THAW_BY_FIRE from="+user.log_name)
    end
    result
  end
  def skill_cast_worthwhile?(unit,target,data)
    return false unless pmd_ac_v023_skill_cast_worthwhile(unit,target,data)
    pure_sleep=(data[:effects]||[]).any?{|e|e[:type]==:canonical_sleep}
    pure_conf=(data[:effects]||[]).any?{|e|e[:type]==:canonical_confusion}
    return false if pure_sleep && (target==nil || target.canonical_major_status_active?)
    return false if pure_conf && target!=nil && target.confused? && !(data[:effects]||[]).any?{|e|e[:type]==:stat_stage}
    true
  end
  def projectile_tracking_for(user,kind,effect_type)
    return :perfect if verification_mode==:action_status && @v023_perfect_tracking_skill!=nil && effect_type==@v023_perfect_tracking_skill
    pmd_ac_v023_projectile_tracking_for(user,kind,effect_type)
  end
  def canonical_secondary_roll(chance)
    if verification_mode==:action_status && @secondary_verification_rolls!=nil && !@secondary_verification_rolls.empty?
      c=PMD_AC.clamp(chance.to_i,0,100);return [true,0] if c>=100;roll=@secondary_verification_rolls.shift.to_i;return [roll<c,roll]
    end
    pmd_ac_v023_canonical_secondary_roll(chance)
  end
  def log_event(category,message)
    if category.to_s=="verify";t=message.to_s;@action_status_verification_failed=true if t.index("ACTION_STATUS_")==0 && t.include?(" pass=0");end
    pmd_ac_v023_log_event(category,message)
  end
  def verify_action_status_manifest(tag)
    return if @verification_done[tag];m=PMD_AC::ActionStatusDB.manifest;pass=PMD_AC::ActionStatusDB.behavior_count==47 && m[:previous_mapped_move_count].to_i==154 && m[:cumulative_mapped_move_count].to_i==201 && m[:new_reference_covered].to_i==816 && m[:cumulative_reference_covered].to_i==3432 && PMD_AC.action_status_checksum32==m[:runtime_checksum32].to_i
    log_event(:verify,tag.to_s.upcase+" pass="+(pass ? "1":"0")+" new=47 cumulative=201 covered=3432/7005 coverage="+m[:cumulative_coverage_percent].to_s+"%");@verification_done[tag]=true
  end
  def verify_action_status_bridge(tag)
    return if @verification_done[tag];e=PMD_AC.validate_action_status_db;pass=e.empty? && PMD_AC.move_executable?(:spore) && PMD_AC.move_executable?(:ice_beam) && PMD_AC.move_executable?(:confuse_ray) && PMD_AC.move_executable?(:bite) && !PMD_AC.move_executable?(:fake_out)
    log_event(:verify,tag.to_s.upcase+" pass="+(pass ? "1":"0")+" errors=["+e.join(",")+"] fake_out=deferred");@verification_done[tag]=true
  end
  def verify_action_status_sleep_cast(tag)
    return if @verification_done[tag];u=verification_unit(:ally,:bulbasaur);t=verification_unit(:enemy,:rattata);t.verification_clear_status(:sleep);t.pmd_ac_v0211_verification_suppress_active_evade;@v023_perfect_tracking_skill=:mv_spore;set_action_status_rolls(:sleep_turns,[0]);ok=u.verification_force_skill(:mv_spore,t)
    log_event(:verify,tag.to_s.upcase+" pass="+(ok ? "1":"0")+" forced_turn_roll=0 tracking=perfect");@verification_done[tag]=true
  end
  def verify_action_status_sleep_result(tag)
    return if @verification_done[tag];t=verification_unit(:enemy,:rattata);t.pmd_ac_v0211_verification_restore_active_evade;@v023_perfect_tracking_skill=nil;applied=t.sleeping?;t.verification_set_sleep_turns(2);a=t.canonical_update_immobilized_status;b=t.canonical_update_immobilized_status;pass=applied && a && !b && !t.sleeping?
    log_event(:verify,tag.to_s.upcase+" pass="+(pass ? "1":"0")+" applied="+(applied ? "1":"0")+" blocked_first="+(a ? "1":"0")+" wake_second="+(!b ? "1":"0"));@verification_done[tag]=true
  end
  def verify_action_status_freeze_cast(tag)
    return if @verification_done[tag];u=verification_unit(:ally,:squirtle);t=verification_unit(:enemy,:rattata);t.verification_clear_status(:freeze);t.pmd_ac_v0211_verification_suppress_active_evade;@v023_perfect_tracking_skill=:mv_ice_beam;set_secondary_verification_rolls([0]);ok=u.verification_force_skill(:mv_ice_beam,t)
    log_event(:verify,tag.to_s.upcase+" pass="+(ok ? "1":"0")+" forced_secondary_roll=0 tracking=perfect");@verification_done[tag]=true
  end
  def verify_action_status_freeze_result(tag)
    return if @verification_done[tag];t=verification_unit(:enemy,:rattata);t.pmd_ac_v0211_verification_restore_active_evade;@v023_perfect_tracking_skill=nil;pass=t.frozen?;log_event(:verify,tag.to_s.upcase+" pass="+(pass ? "1":"0")+" frozen="+(pass ? "1":"0"));t.verification_clear_status(:freeze);@verification_done[tag]=true
  end
  def verify_action_status_confusion_cast(tag)
    return if @verification_done[tag];u=verification_unit(:enemy,:pikachu);t=verification_unit(:ally,:squirtle);t.verification_clear_status(:confusion);t.pmd_ac_v0211_verification_suppress_active_evade;@v023_perfect_tracking_skill=:mv_confuse_ray;set_action_status_rolls(:confusion_turns,[0]);ok=u.verification_force_skill(:mv_confuse_ray,t)
    log_event(:verify,tag.to_s.upcase+" pass="+(ok ? "1":"0")+" forced_turn_roll=0 tracking=perfect");@verification_done[tag]=true
  end
  def verify_action_status_confusion_result(tag)
    return if @verification_done[tag];t=verification_unit(:ally,:squirtle);t.pmd_ac_v0211_verification_restore_active_evade;@v023_perfect_tracking_skill=nil;applied=t.confused?;t.verification_set_confusion_turns(3);set_action_status_rolls(:confusion_self_hit,[49,50]);set_action_status_rolls(:confusion_damage_roll,[15]);before=t.hp;a=t.canonical_confusion_action_block?(:basic);mid=t.hp;b=t.canonical_confusion_action_block?(:basic);pass=applied && a && mid<before && !b
    log_event(:verify,tag.to_s.upcase+" pass="+(pass ? "1":"0")+" applied="+(applied ? "1":"0")+" roll49_selfhit="+(a ? "1":"0")+" damage="+(before-mid).to_s+" roll50_allow="+(!b ? "1":"0"));t.verification_clear_status(:confusion);@verification_done[tag]=true
  end
  def verify_action_status_flinch_cast(tag)
    return if @verification_done[tag];u=verification_unit(:ally,:charmander);t=verification_unit(:enemy,:rattata);u.deploy_to_cell(1,1);t.deploy_to_cell(2,1);t.deploy_to_pixel(u.pixel_x+48.0,u.pixel_y);t.verification_clear_status(:flinch);set_secondary_verification_rolls([0]);ok=u.verification_force_skill(:mv_bite,t)
    log_event(:verify,tag.to_s.upcase+" pass="+(ok ? "1":"0")+" distance="+u.distance_to(t).round.to_s+" forced_secondary_roll=0");@verification_done[tag]=true
  end
  def verify_action_status_flinch_result(tag)
    return if @verification_done[tag];t=verification_unit(:enemy,:rattata);pending=t.canonical_flinch_pending?;a=t.canonical_consume_flinch(:basic);b=t.canonical_consume_flinch(:basic);pass=pending && a && !b
    log_event(:verify,tag.to_s.upcase+" pass="+(pass ? "1":"0")+" pending="+(pending ? "1":"0")+" first_block="+(a ? "1":"0")+" second_allow="+(!b ? "1":"0"));@verification_done[tag]=true
  end
  def verify_action_status_rules(tag)
    return if @verification_done[tag];t=verification_unit(:enemy,:rattata);ice=verification_unit(:ally,:squirtle);t.verification_clear_status(:freeze);t.canonical_apply_freeze(nil);t.verification_force_status_wait_ready;set_action_status_rolls(:freeze_thaw,[19]);thaw=!t.canonical_update_immobilized_status && !t.frozen?;t.canonical_apply_freeze(nil);t.verification_force_status_wait_ready;set_action_status_rolls(:freeze_thaw,[20]);block=t.canonical_update_immobilized_status && t.frozen?;t.verification_clear_status(:freeze);pass=thaw && block && !ice.pokemon_types.include?(:ice)
    log_event(:verify,tag.to_s.upcase+" pass="+(pass ? "1":"0")+" freeze_roll19=thaw freeze_roll20=block confusion50=gen5 sleep_block=1..3");@verification_done[tag]=true
  end
  def verify_action_status_fire_thaw(tag)
    return if @verification_done[tag];u=verification_unit(:ally,:charmander);t=verification_unit(:enemy,:rattata);t.verification_clear_status(:freeze);t.canonical_apply_freeze(nil);u.deploy_to_cell(1,1);t.deploy_to_cell(3,1);t.pmd_ac_v0211_verification_suppress_active_evade;@v023_perfect_tracking_skill=:mv_ember;@action_status_snapshots[:fire]=t.hp;ok=u.verification_force_skill(:mv_ember,t);log_event(:verify,tag.to_s.upcase+" pass="+(ok ? "1":"0")+" frozen_before=1 tracking=perfect");@verification_done[tag]=true
  end
  def verify_action_status_fire_thaw_result(tag)
    return if @verification_done[tag];t=verification_unit(:enemy,:rattata);t.pmd_ac_v0211_verification_restore_active_evade;@v023_perfect_tracking_skill=nil;b=@action_status_snapshots[:fire];pass=t.hp<b && !t.frozen?;log_event(:verify,tag.to_s.upcase+" pass="+(pass ? "1":"0")+" damage="+(b-t.hp).to_s+" thawed="+(!t.frozen? ? "1":"0"));@verification_done[tag]=true
  end
  def verify_action_status_runtime_file(tag)
    return if @verification_done[tag];p=FileTest.exist?(PMD_AC::ACTION_STATUS_RUNTIME_FILE);log_event(:verify,tag.to_s.upcase+" pass="+(p ? "1":"0")+" runtime_file="+(p ? "present":"missing")+" source="+(PMD_AC::ActionStatusDB.using_runtime_file? ? "rvdata":"embedded_first_boot"));@verification_done[tag]=true
  end
  def update_verification_script
    pmd_ac_v023_update_verification_script;return unless verification_mode==:action_status;f=@verification_frame
    verify_action_status_manifest(:action_status_manifest) if f==4;verify_action_status_bridge(:action_status_bridge) if f==30
    verify_action_status_sleep_cast(:action_status_sleep_cast) if f==55;verify_action_status_sleep_result(:action_status_sleep_result) if f==95
    verify_action_status_freeze_cast(:action_status_freeze_cast) if f==120;verify_action_status_freeze_result(:action_status_freeze_result) if f==175
    verify_action_status_confusion_cast(:action_status_confusion_cast) if f==195;verify_action_status_confusion_result(:action_status_confusion_result) if f==245
    verify_action_status_flinch_cast(:action_status_flinch_cast) if f==265;verify_action_status_flinch_result(:action_status_flinch_result) if f==300
    verify_action_status_rules(:action_status_rules) if f==325;verify_action_status_fire_thaw(:action_status_fire_thaw_cast) if f==340;verify_action_status_fire_thaw_result(:action_status_fire_thaw_result) if f==385
    verify_action_status_runtime_file(:action_status_runtime_file) if f==400;complete_verification_mode if f==PMD_AC::VERIFICATION_ACTION_STATUS_END_FRAME
  end
  def complete_verification_mode
    if verification_mode==:action_status
      @v023_perfect_tracking_skill=nil;@secondary_verification_rolls=[] if @secondary_verification_rolls!=nil
      for u in @units;begin;u.pmd_ac_v0211_verification_restore_active_evade;rescue;end;end
      if @action_status_verification_failed
        return if @verification_done[:verification_complete];for u in @units;u.verification_finish;end;@verification_done[:verification_complete]=true;log_event(:verify,"FAILED mode=ACTION_STATUS auto_skill=on original_skills=restored");return
      end
    end
    pmd_ac_v023_complete_verification_mode
  end
end
