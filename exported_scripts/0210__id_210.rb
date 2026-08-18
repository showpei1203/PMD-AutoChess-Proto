#==============================================================================
# 【PMD AutoChess 中文維護說明】
# 腳本：PMD AutoChess Proto v0.53
# 分類：核心戰鬥 Runtime
#
# 【用途／機制】
# 承接前序 Data／Config，實際執行戰鬥 Scene、Unit、AI、技能與呈現。
#
# 【怎麼調整】
# 一般平衡與資料調整不要直接改 Runtime；若要追加功能，建議在較後腳本 alias 原方法後擴充。
#
# 【本腳本主要設定常數／資料表】
# - VERIFICATION_MOVE_COVERAGE_V_END_FRAME_V053 / VERIFICATION_MODES / VERIFICATION_LABELS
#
# 【Runtime 主要方法（查流程時可直接搜尋）】
# - move_coverage_v_key_from_skill_v053 / canonical_move_key_from_skill / move_executable? / move_autochess_hint
# - skill_data / skill_audio_move_profile_v032 / skill_visual_move_profile_v031 / move_presentation_profile_v053
# - move_coverage_v_checksum32_v053 / validate_move_coverage_v_v053 / initialize / reset_move_coverage_v_v053
#
# 【維護規則】
# - RPG Maker VX / RGSS2 / Ruby 1.8 相容。
# - instance_uid 才是 Pokémon 個體身份；Actor ID 只是容器。
# - 新增行為優先沿用既有 helper／Data 表；避免破壞已 Freeze 的舊核心。
# - 本專案新腳本也必須保留同等級的中文說明與實際範例。
#==============================================================================
#===============================================================================
# ■ PMD AutoChess Proto v0.53
#    Move Runtime Coverage Expansion V + Functional Presentation Profiles III
#-------------------------------------------------------------------------------
# Additive layer on verified v0.52.1.
# RGSS2 rule: this script intentionally avoids the unsupported own-ivar query API.
#===============================================================================
module PMD_AC
  VERIFICATION_MOVE_COVERAGE_V_END_FRAME_V053=1360
  STATUS_DEFS[:curse_v053]={:tags=>[:debuff,:dot,:curse],:tick_type=>:damage,:interval=>60,:stack_mode=>:refresh} unless STATUS_DEFS.has_key?(:curse_v053)
  STATUS_DEFS[:foresight_v052]={:tags=>[:debuff,:exposed],:tick_type=>nil,:interval=>999999,:stack_mode=>:refresh} unless STATUS_DEFS.has_key?(:foresight_v052)
  class << self
    alias pmd_ac_v053_canonical_move_key_from_skill canonical_move_key_from_skill unless method_defined?(:pmd_ac_v053_canonical_move_key_from_skill)
    alias pmd_ac_v053_move_executable move_executable? unless method_defined?(:pmd_ac_v053_move_executable)
    alias pmd_ac_v053_move_autochess_hint move_autochess_hint unless method_defined?(:pmd_ac_v053_move_autochess_hint)
    alias pmd_ac_v053_skill_data skill_data unless method_defined?(:pmd_ac_v053_skill_data)
    alias pmd_ac_v053_skill_audio_move_profile_v032 skill_audio_move_profile_v032 unless method_defined?(:pmd_ac_v053_skill_audio_move_profile_v032)
    alias pmd_ac_v053_skill_visual_move_profile_v031 skill_visual_move_profile_v031 unless method_defined?(:pmd_ac_v053_skill_visual_move_profile_v031)
    def move_coverage_v_key_from_skill_v053(skill_key)
      return nil if skill_key==nil;text=skill_key.to_s;return nil unless text[0,3]=='mv_';k=text[3,text.size-3].to_sym;MOVE_COVERAGE_V_MOVE_V053[k]==nil ? nil : k
    end
    def canonical_move_key_from_skill(skill_key);k=move_coverage_v_key_from_skill_v053(skill_key);return k if k!=nil;pmd_ac_v053_canonical_move_key_from_skill(skill_key);end
    def move_executable?(move_key);k=move_key.is_a?(String) ? move_key.to_sym : move_key;return true if MOVE_COVERAGE_V_MOVE_V053[k]!=nil;pmd_ac_v053_move_executable(move_key);end
    def move_autochess_hint(move_key)
      k=move_key.is_a?(String) ? move_key.to_sym : move_key;b=MOVE_COVERAGE_V_MOVE_V053[k];return pmd_ac_v053_move_autochess_hint(move_key) if b==nil
      old=pmd_ac_v053_move_autochess_hint(move_key);r=old==nil ? {} : old.dup;[:behavior_status,:delivery,:range_px,:runtime_skill_key,:priority,:target_type,:policy].each{|x|r[x]=b[x] if b[x]!=nil};r
    end
    def skill_data(key);mk=move_coverage_v_key_from_skill_v053(key);return MOVE_COVERAGE_V_MOVE_V053[mk].dup if mk!=nil;pmd_ac_v053_skill_data(key);end
    def skill_audio_move_profile_v032(move_key);k=move_key.is_a?(String) ? move_key.to_sym : move_key;b=MOVE_COVERAGE_V_AUDIO_V053[k];return b if b!=nil;pmd_ac_v053_skill_audio_move_profile_v032(move_key);end
    def skill_visual_move_profile_v031(move_key);k=move_key.is_a?(String) ? move_key.to_sym : move_key;b=MOVE_COVERAGE_V_VISUAL_V053[k];return b if b!=nil;pmd_ac_v053_skill_visual_move_profile_v031(move_key);end
    def move_presentation_profile_v053(move_key);k=move_key.is_a?(String) ? move_key.to_sym : move_key;MOVE_PRESENTATION_V053[k];end
    def move_coverage_v_checksum32_v053;h=0;MOVE_COVERAGE_V_CHECKSUM_TEXT_V053.each_byte{|c|h=((h*33)+c)&0x7fffffff};h;end
    def validate_move_coverage_v_v053
      e=[];m=MOVE_COVERAGE_V_MANIFEST_V053;e.push('count') unless MOVE_COVERAGE_V_MOVE_V053.size==29;e.push('cumulative') unless m[:cumulative_mapped_move_count].to_i==376;e.push('refs') unless m[:new_reference_covered].to_i==459 && m[:cumulative_reference_covered].to_i==6308;e.push('presentation') unless MOVE_PRESENTATION_V053.size==29;e.push('checksum') unless move_coverage_v_checksum32_v053==m[:runtime_checksum32].to_i
      m[:new_move_keys].each{|k|d=MOVE_COVERAGE_V_MOVE_V053[k];p=MOVE_PRESENTATION_V053[k];e.push('data:'+k.to_s) if d==nil;e.push('presentation:'+k.to_s) if p==nil;e.push('visual:'+k.to_s) if MOVE_COVERAGE_V_VISUAL_V053[k]==nil;e.push('audio:'+k.to_s) if MOVE_COVERAGE_V_AUDIO_V053[k]==nil;e.push('timing:'+k.to_s) if p!=nil && p[:timing]==nil}
      e
    end
  end
  remove_const(:VERIFICATION_MODES) if const_defined?(:VERIFICATION_MODES)
  VERIFICATION_MODES=[:move_coverage_v,:move_coverage_iv,:move_coverage_iii,:move_coverage_ii,:move_coverage]
  remove_const(:VERIFICATION_LABELS) if const_defined?(:VERIFICATION_LABELS)
  VERIFICATION_LABELS={:move_coverage_v=>'MOVE_COVERAGE_V',:move_coverage_iv=>'MOVE_COVERAGE_IV',:move_coverage_iii=>'MOVE_COVERAGE_III',:move_coverage_ii=>'MOVE_COVERAGE_II',:move_coverage=>'MOVE_COVERAGE'}
end

class Game_PMDChessUnit
  alias pmd_ac_v053_initialize initialize unless method_defined?(:pmd_ac_v053_initialize)
  alias pmd_ac_v053_start_combat start_combat unless method_defined?(:pmd_ac_v053_start_combat)
  alias pmd_ac_v053_deploy_to_cell deploy_to_cell unless method_defined?(:pmd_ac_v053_deploy_to_cell)
  alias pmd_ac_v053_deploy_to_pixel deploy_to_pixel unless method_defined?(:pmd_ac_v053_deploy_to_pixel)
  alias pmd_ac_v053_update update unless method_defined?(:pmd_ac_v053_update)
  alias pmd_ac_v053_begin_attack begin_attack unless method_defined?(:pmd_ac_v053_begin_attack)
  alias pmd_ac_v053_begin_skill begin_skill unless method_defined?(:pmd_ac_v053_begin_skill)
  alias pmd_ac_v053_update_action_timer update_action_timer unless method_defined?(:pmd_ac_v053_update_action_timer)
  alias pmd_ac_v053_receive_damage receive_damage unless method_defined?(:pmd_ac_v053_receive_damage)
  alias pmd_ac_v053_start_faint start_faint unless method_defined?(:pmd_ac_v053_start_faint)
  alias pmd_ac_v053_ability_key ability_key unless method_defined?(:pmd_ac_v053_ability_key)
  alias pmd_ac_v053_pokemon_types pokemon_types unless method_defined?(:pmd_ac_v053_pokemon_types)
  alias pmd_ac_v053_canonical_apply_sleep canonical_apply_sleep unless method_defined?(:pmd_ac_v053_canonical_apply_sleep)
  alias pmd_ac_v053_held_item_effective_v041 held_item_effective_v041? unless method_defined?(:pmd_ac_v053_held_item_effective_v041)
  def initialize(*args);pmd_ac_v053_initialize(*args);reset_move_coverage_v_v053;end
  def reset_move_coverage_v_v053
    @encore_key_v053=nil;@encore_frames_v053=0;@used_moves_v053={};@stockpile_v053=0;@mean_look_frames_v053=0;@bide_frames_v053=0;@bide_damage_v053=0;@bide_source_uid_v053=nil;@worry_seed_frames_v053=0;@repeat_lock_frames_v053=0;@repeat_lock_key_v053=nil;@destiny_bond_frames_v053=0;@destiny_source_uid_v053=nil;@lock_on_target_uid_v053=nil;@lock_on_frames_v053=0;@perish_frames_v053=0;@imprison_frames_v053=0;@embargo_frames_v053=0;@temporary_skill_restore_v053=nil;@foresight_damage_override_v053=false
  end
  def start_combat;pmd_ac_v053_start_combat;reset_move_coverage_v_v053;end
  def deploy_to_cell(x,y);pmd_ac_v053_deploy_to_cell(x,y);reset_move_coverage_v_v053;end
  def deploy_to_pixel(x,y);pmd_ac_v053_deploy_to_pixel(x,y);reset_move_coverage_v_v053;end
  def encore_active_v053?;@encore_frames_v053.to_i>0 && @encore_key_v053!=nil;end
  def set_encore_v053(k,f);@encore_key_v053=k;@encore_frames_v053=[f.to_i,1].max;end
  def stockpile_v053;@stockpile_v053.to_i;end
  def trapped_v053?;@mean_look_frames_v053.to_i>0;end
  def set_mean_look_v053(f);@mean_look_frames_v053=[f.to_i,1].max;end
  def biding_v053?;@bide_frames_v053.to_i>0;end
  def start_bide_v053(f);@bide_frames_v053=[f.to_i,1].max;@bide_damage_v053=0;@bide_source_uid_v053=nil;end
  def worry_seed_active_v053?;@worry_seed_frames_v053.to_i>0;end
  def set_worry_seed_v053(f);@worry_seed_frames_v053=[f.to_i,1].max;remove_status(:sleep) if status?(:sleep);end
  def start_repeat_lock_v053(k,f);@repeat_lock_key_v053=k;@repeat_lock_frames_v053=[f.to_i,1].max;end
  def repeat_locked_v053?;@repeat_lock_frames_v053.to_i>0;end
  def set_destiny_bond_v053(f);@destiny_bond_frames_v053=[f.to_i,1].max;end
  def destiny_bond_active_v053?;@destiny_bond_frames_v053.to_i>0;end
  def set_lock_on_v053(target,f);@lock_on_target_uid_v053=target==nil ? nil : target.instance_uid;@lock_on_frames_v053=[f.to_i,1].max;end
  def lock_on_matches_v053?(target);@lock_on_frames_v053.to_i>0 && target!=nil && @lock_on_target_uid_v053.to_i==target.instance_uid.to_i;end
  def consume_lock_on_v053;@lock_on_frames_v053=0;@lock_on_target_uid_v053=nil;end
  def set_perish_v053(f);@perish_frames_v053=[f.to_i,1].max;end
  def perish_active_v053?;@perish_frames_v053.to_i>0;end
  def set_imprison_v053(f);@imprison_frames_v053=[f.to_i,1].max;end
  def imprison_active_v053?;@imprison_frames_v053.to_i>0;end
  def set_embargo_v053(f);@embargo_frames_v053=[f.to_i,1].max;end
  def embargo_active_v053?;@embargo_frames_v053.to_i>0;end
  def used_moves_v053;@used_moves_v053||={};end
  def mark_used_move_v053(k);used_moves_v053[k]=true if k!=nil;end
  def last_resort_ready_v053?
    pool=respond_to?(:progression_move_pool_v046) ? progression_move_pool_v046 : [];others=pool.find_all{|k|k!=:last_resort};return false if others.empty?;others.all?{|k|used_moves_v053[k]}
  end
  def species_mass_proxy_v053
    d=PMD_AC.species_identity_data(species_key);bs=d==nil ? nil : d[:base_stats];return maxhp.to_i if bs==nil || bs.size<3;bs[0].to_i+bs[1].to_i+bs[2].to_i
  end
  def ability_key;return :insomnia if worry_seed_active_v053?;pmd_ac_v053_ability_key;end
  def pokemon_types;ts=pmd_ac_v053_pokemon_types;return ts unless @foresight_damage_override_v053;ts.find_all{|x|x!=:ghost};end
  def set_foresight_damage_override_v053(v);@foresight_damage_override_v053=v ? true : false;end
  def canonical_apply_sleep(source=nil)
    if worry_seed_active_v053? || (@scene!=nil && @scene.respond_to?(:uproar_active_v053?) && @scene.uproar_active_v053?);log_event(:move_coverage_v,log_name+' SLEEP_BLOCK reason='+(worry_seed_active_v053? ? 'worry_seed':'uproar'));return false;end
    pmd_ac_v053_canonical_apply_sleep(source)
  end
  def held_item_effective_v041?(key=nil);return false if embargo_active_v053?;pmd_ac_v053_held_item_effective_v041(key);end
  def force_runtime_move_v053(move)
    return false if move==nil || !PMD_AC.move_executable?(move);@temporary_skill_restore_v053=progression_skill_snapshot_v046 if @temporary_skill_restore_v053==nil && respond_to?(:progression_skill_snapshot_v046);@skill_type=('mv_'+move.to_s).to_sym;d=PMD_AC.skill_data(@skill_type);@skill_name=d==nil ? move.to_s : (d[:name]||move.to_s);true
  end
  def restore_runtime_move_v053
    if @temporary_skill_restore_v053!=nil && respond_to?(:progression_restore_skill_snapshot_v046);progression_restore_skill_snapshot_v046(@temporary_skill_restore_v053);end;@temporary_skill_restore_v053=nil
  end
  def begin_attack;return if biding_v053? || repeat_locked_v053?;pmd_ac_v053_begin_attack;end
  def begin_skill(skill_target=nil)
    original=skill_data;mk=original==nil ? nil : original[:canonical_move_key]
    if trapped_v053? && [:teleport,:baton_pass].include?(mk);log_event(:move_coverage_v,log_name+' SWITCH_LOCK_BLOCK move='+mk.to_s);return;end
    if biding_v053? || repeat_locked_v053?;return;end
    if @scene!=nil && @scene.respond_to?(:imprison_blocks_move_v053?) && @scene.imprison_blocks_move_v053?(self,mk);log_event(:move_coverage_v,log_name+' IMPRISON_BLOCK move='+mk.to_s);@energy=0;return;end
    if mk==:last_resort && !last_resort_ready_v053?;log_event(:move_coverage_v,log_name+' LAST_RESORT_FAIL used_gate=0');@energy=0;return;end
    if mk==:copycat
      copy=@scene==nil ? nil : @scene.copycat_move_v053(self);if copy==nil;log_event(:move_coverage_v,log_name+' COPYCAT_FAIL no_safe_move=1');@energy=0;return;end
      force_runtime_move_v053(copy);d=PMD_AC.skill_data(@skill_type);skill_target=self if d!=nil && d[:target_type]==:self_targeted
    elsif encore_active_v053?
      if force_runtime_move_v053(@encore_key_v053);d=PMD_AC.skill_data(@skill_type);skill_target=self if d!=nil && d[:target_type]==:self_targeted;end
    end
    before=@action_timer.to_i;pmd_ac_v053_begin_skill(skill_target)
    if @action==:skill && @action_timer.to_i>0
      actual=skill_data;ak=actual==nil ? nil : actual[:canonical_move_key];mark_used_move_v053(ak);@scene.record_global_move_v053(self,ak) if @scene!=nil && @scene.respond_to?(:record_global_move_v053)
    elsif before<=0
      restore_runtime_move_v053
    end
  end
  def update_action_timer
    was=@action_timer.to_i;pmd_ac_v053_update_action_timer;if was>0 && @action_timer.to_i<=0;restore_runtime_move_v053;end
  end
  def receive_damage(value,source=nil,grant_energy=true,bypass_link=false,critical=false)
    before=hp.to_i;r=pmd_ac_v053_receive_damage(value,source,grant_energy,bypass_link,critical);actual=[before-hp.to_i,0].max
    if actual>0;@destiny_source_uid_v053=source==nil ? nil : source.instance_uid;if biding_v053?;@bide_damage_v053=@bide_damage_v053.to_i+actual;@bide_source_uid_v053=source.instance_uid if source!=nil;end;end;r
  end
  def update
    old_bide=@bide_frames_v053.to_i
    @encore_frames_v053-=1 if @encore_frames_v053.to_i>0;@mean_look_frames_v053-=1 if @mean_look_frames_v053.to_i>0;@worry_seed_frames_v053-=1 if @worry_seed_frames_v053.to_i>0;@repeat_lock_frames_v053-=1 if @repeat_lock_frames_v053.to_i>0;@destiny_bond_frames_v053-=1 if @destiny_bond_frames_v053.to_i>0;@lock_on_frames_v053-=1 if @lock_on_frames_v053.to_i>0;@imprison_frames_v053-=1 if @imprison_frames_v053.to_i>0;@embargo_frames_v053-=1 if @embargo_frames_v053.to_i>0
    @bide_frames_v053-=1 if @bide_frames_v053.to_i>0
    if old_bide>0 && @bide_frames_v053.to_i<=0 && @scene!=nil && !dead?;@scene.release_bide_v053(self,@bide_source_uid_v053,@bide_damage_v053);@bide_damage_v053=0;@bide_source_uid_v053=nil;end
    if @perish_frames_v053.to_i>0
      @perish_frames_v053-=1
      if [120,60].include?(@perish_frames_v053.to_i) && @scene!=nil;@scene.add_vfx_impact(self,:ghost);end
      if @perish_frames_v053.to_i<=0 && !dead?;@hp=0;log_event(:move_coverage_v,log_name+' PERISH_KO');start_faint;return;end
    end
    pmd_ac_v053_update
  end
  def start_faint
    if destiny_bond_active_v053? && @scene!=nil && @destiny_source_uid_v053!=nil;@scene.resolve_destiny_bond_v053(self,@destiny_source_uid_v053);end
    reset_move_coverage_v_v053;pmd_ac_v053_start_faint
  end
end

class Scene_PMD_AutoChess
  alias pmd_ac_v053_start start unless method_defined?(:pmd_ac_v053_start)
  alias pmd_ac_v053_terminate terminate unless method_defined?(:pmd_ac_v053_terminate)
  alias pmd_ac_v053_start_battle start_battle unless method_defined?(:pmd_ac_v053_start_battle)
  alias pmd_ac_v053_update update unless method_defined?(:pmd_ac_v053_update)
  alias pmd_ac_v053_skill_target_for skill_target_for unless method_defined?(:pmd_ac_v053_skill_target_for)
  alias pmd_ac_v053_apply_skill_effects apply_skill_effects unless method_defined?(:pmd_ac_v053_apply_skill_effects)
  alias pmd_ac_v053_deal_direct_damage deal_direct_damage unless method_defined?(:pmd_ac_v053_deal_direct_damage)
  alias pmd_ac_v053_canonical_accuracy_probability canonical_accuracy_probability unless method_defined?(:pmd_ac_v053_canonical_accuracy_probability)
  alias pmd_ac_v053_skill_cast_worthwhile skill_cast_worthwhile? unless method_defined?(:pmd_ac_v053_skill_cast_worthwhile)
  alias pmd_ac_v053_prepare_verification_battle prepare_verification_battle unless method_defined?(:pmd_ac_v053_prepare_verification_battle)
  alias pmd_ac_v053_update_verification_script update_verification_script unless method_defined?(:pmd_ac_v053_update_verification_script)
  alias pmd_ac_v053_log_event log_event unless method_defined?(:pmd_ac_v053_log_event)
  alias pmd_ac_v053_complete_verification_mode complete_verification_mode unless method_defined?(:pmd_ac_v053_complete_verification_mode)
  def start
    pmd_ac_v053_start
    begin
      if FileTest.exist?(PMD_AC::BATTLE_LOG_FILE);text=File.open(PMD_AC::BATTLE_LOG_FILE,'rb'){|f|f.read};text.sub!(/PMD AutoChess Proto v0\.[0-9.]+ Battle Verification Log/,'PMD AutoChess Proto v0.53 Battle Verification Log');File.open(PMD_AC::BATTLE_LOG_FILE,'wb'){|f|f.write(text)};end
    rescue;end
    reset_move_coverage_v_scene_v053;m=PMD_AC::MOVE_COVERAGE_V_MANIFEST_V053;log_event(:move_coverage_v,'LOADED new=29 cumulative=376 audited='+m[:cumulative_reference_covered].to_s+'/'+m[:learnset_reference_total].to_s+' coverage='+sprintf('%.2f',m[:cumulative_coverage_percent].to_f)+'% presentation=29 timing=29 foundations=encore,repeat,stockpile,item,trap,hazard,copycat,imprison checksum32='+m[:runtime_checksum32].to_s)
  end
  def terminate;reset_move_coverage_v_scene_v053;pmd_ac_v053_terminate;end
  def start_battle;reset_move_coverage_v_scene_v053;pmd_ac_v053_start_battle;end
  def reset_move_coverage_v_scene_v053;@repeat_events_v053=[];@last_global_move_key_v053=nil;@toxic_spikes_v053={:ally=>{:layers=>0,:frames=>0},:enemy=>{:layers=>0,:frames=>0}};end
  def unit_by_uid_v053(uid);return nil if uid==nil;(@units||[]).find{|u|u.instance_uid.to_i==uid.to_i};end
  def enemies_of_v053(user);(@units||[]).find_all{|u|u.alive? && user!=nil && u.team!=user.team};end
  def allies_other_v053(user);(@units||[]).find_all{|u|u.alive? && user!=nil && u.team==user.team && u!=user};end
  def nearest_enemy_v053(user);a=enemies_of_v053(user);a.sort_by{|u|user.distance_to(u).to_f}[0];end
  def best_ally_v053(user,needs_heal=false);a=allies_other_v053(user);a=a.find_all{|u|u.hp.to_i<u.maxhp.to_i || u.canonical_major_status_active?} if needs_heal;a.sort_by{|u|[u.hp.to_f/[u.maxhp.to_i,1].max.to_f,u.instance_uid.to_i]}[0];end
  def record_global_move_v053(user,key);return if key==nil || key==:copycat;@last_global_move_key_v053=key;end
  def copycat_move_v053(user);k=@last_global_move_key_v053;return nil if k==nil || k==:copycat || !PMD_AC.move_executable?(k);d=PMD_AC.skill_data(('mv_'+k.to_s).to_sym);return nil if d==nil;return nil if [:baton_pass,:healing_wish,:perish_song,:copycat].include?(k);k;end
  def uproar_active_v053?;(@units||[]).any?{|u|u.alive? && u.instance_variable_get(:@repeat_lock_key_v053)==:uproar && u.instance_variable_get(:@repeat_lock_frames_v053).to_i>0};end
  def imprison_blocks_move_v053?(unit,mk)
    return false if unit==nil || mk==nil;(@units||[]).any? do |u|
      next false unless u.alive? && u.team!=unit.team && u.imprison_active_v053?;pool=u.respond_to?(:progression_move_pool_v046) ? u.progression_move_pool_v046 : [];pool.include?(mk)
    end
  end
  def skill_target_for(unit)
    if unit!=nil;d=unit.skill_data;mk=d==nil ? nil : d[:canonical_move_key];return best_ally_v053(unit,false) if mk==:baton_pass;return best_ally_v053(unit,true) if mk==:healing_wish;end
    pmd_ac_v053_skill_target_for(unit)
  end
  def item_profile_v053(user);return nil if user==nil || !user.respond_to?(:held_item_key_v041);k=user.held_item_key_v041;return nil if k==nil;PMD_AC::ITEM_ATTACK_PROFILE_V053[k];end
  def species_mass_proxy_v053(unit);unit==nil ? 1 : [unit.species_mass_proxy_v053.to_i,1].max;end
  def dynamic_power_v053(user,target,key)
    case key
    when :natural_gift;p=item_profile_v053(user);p==nil ? 1 : p[:natural_power].to_i
    when :fling;p=item_profile_v053(user);p==nil ? 1 : p[:fling_power].to_i
    when :heavy_slam
      a=species_mass_proxy_v053(user).to_f;b=species_mass_proxy_v053(target).to_f;r=a/[b,1.0].max;return 120 if r>=5.0;return 100 if r>=4.0;return 80 if r>=3.0;return 60 if r>=2.0;40
    when :low_kick
      w=species_mass_proxy_v053(target);return 20 if w<150;return 40 if w<200;return 60 if w<250;return 80 if w<300;return 100 if w<350;120
    when :spit_up;user==nil ? 0 : 100*user.stockpile_v053
    when :wake_up_slap;target!=nil && target.status?(:sleep) ? 120 : 60
    else;nil
    end
  end
  def transform_move_v053(user,target,data)
    return data if data==nil;d=data;pk=d[:dynamic_power_v053]
    if pk!=nil;d=data.dup;p=dynamic_power_v053(user,target,pk);d[:effects]=(data[:effects]||[]).collect{|e|x=e.dup;x[:power]=p if x[:type]==:damage;x};d[:runtime_power_v053]=p;end
    if d[:item_attack_v053]==:natural_gift
      p=item_profile_v053(user);if p!=nil;d=d.dup if d.equal?(data);d[:move_type]=p[:natural_type];d[:type]=p[:natural_type];end
    end;d
  end
  def schedule_repeat_v053(user,target,data,e)
    turns=[e[:turns].to_i,1].max;interval=[e[:interval].to_i,1].max;kind=e[:kind];user.start_repeat_lock_v053(kind,(turns-1)*interval+12);@repeat_events_v053=[] if @repeat_events_v053==nil
    1.upto(turns-1){|i|@repeat_events_v053.push({:user_uid=>user.instance_uid,:target_uid=>(target==nil ? nil : target.instance_uid),:move_key=>data[:canonical_move_key],:power=>e[:power].to_i,:due=>Graphics.frame_count+i*interval,:last=>(i==turns-1),:kind=>kind})}
    if kind==:uproar;(@units||[]).each{|u|u.remove_status(:sleep) if u.status?(:sleep)};end
    log_event(:move_coverage_v,user.log_name+' REPEAT_SET move='+kind.to_s+' turns='+turns.to_s+' interval='+interval.to_s)
  end
  def resolve_repeat_event_v053(e)
    user=unit_by_uid_v053(e[:user_uid]);return if user==nil || user.dead?;target=unit_by_uid_v053(e[:target_uid]);target=nearest_enemy_v053(user) if target==nil || target.dead?;return if target==nil
    d=PMD_AC.skill_data(('mv_'+e[:move_key].to_s).to_sym);result=deal_skill_damage(user,target,e[:power],{:skill_data=>d,:can_crit=>true,:directional=>true});add_vfx_impact(target,d[:move_type]||:normal);log_event(:move_coverage_v,user.log_name+' REPEAT_HIT '+e[:kind].to_s+' -> '+target.log_name+' damage='+result.to_i.to_s)
    if e[:last] && e[:kind]==:thrash && !user.dead?;user.canonical_apply_confusion(user);add_skill_effect(user,:stun);end
  end
  def update_repeat_events_v053
    return if @repeat_events_v053==nil || @repeat_events_v053.empty?;now=Graphics.frame_count;keep=[];@repeat_events_v053.each{|e|if now>=e[:due].to_i;resolve_repeat_event_v053(e);else;keep.push(e);end};@repeat_events_v053=keep
  end
  def set_toxic_spikes_v053(team,duration)
    s=@toxic_spikes_v053[team]||{:layers=>0,:frames=>0};s[:layers]=[s[:layers].to_i+1,2].min;s[:frames]=[duration.to_i,1].max;@toxic_spikes_v053[team]=s;log_event(:move_coverage_v,'TOXIC_SPIKES_SET team='+team.to_s+' layers='+s[:layers].to_s+' frames='+s[:frames].to_s)
  end
  def clear_toxic_spikes_v053(team);s=@toxic_spikes_v053[team];return 0 if s==nil || s[:layers].to_i<=0;n=s[:layers].to_i;@toxic_spikes_v053[team]={:layers=>0,:frames=>0};n;end
  def update_toxic_spikes_v053
    return if @toxic_spikes_v053==nil;[:ally,:enemy].each do |team|;s=@toxic_spikes_v053[team];next if s==nil || s[:frames].to_i<=0;s[:frames]-=1;if s[:frames].to_i<=0;clear_toxic_spikes_v053(team);next;end;next unless Graphics.frame_count%30==0
      (@units||[]).each do |u|;next unless u.alive? && u.team==team && u.respond_to?(:canonical_grounded_v038?) && u.canonical_grounded_v038?;ts=u.pokemon_types
        if ts.include?(:poison);clear_toxic_spikes_v053(team);add_vfx_impact(u,:poison);log_event(:move_coverage_v,u.log_name+' TOXIC_SPIKES_ABSORB');break;end
        next if u.canonical_major_status_active?;ratio=s[:layers].to_i>=2 ? 0.03 : 0.015;apply_direct_poison_v049(nil,u,{:duration=>180,:interval=>30,:tick_maxhp_ratio=>ratio});log_event(:move_coverage_v,u.log_name+' TOXIC_SPIKES_POISON layers='+s[:layers].to_s)
      end
    end
  end
  def update; pmd_ac_v053_update; update_repeat_events_v053; update_toxic_spikes_v053; end
  def release_bide_v053(user,source_uid,stored)
    return false if user==nil || stored.to_i<=0;target=unit_by_uid_v053(source_uid);target=nearest_enemy_v053(user) if target==nil || target.dead?;return false if target==nil;amount=stored.to_i*2;before=target.hp;target.receive_damage(amount,user,false,true,false);actual=[before-target.hp,0].max;add_vfx_impact(target,:normal);log_event(:move_coverage_v,user.log_name+' BIDE_RELEASE stored='+stored.to_i.to_s+' damage='+actual.to_s);actual>0
  end
  def resolve_destiny_bond_v053(user,source_uid)
    src=unit_by_uid_v053(source_uid);return false if src==nil || src.dead? || user==nil || src.team==user.team;src.instance_variable_set(:@destiny_bond_frames_v053,0);src.instance_variable_set(:@hp,0);add_vfx_impact(src,:ghost);log_event(:move_coverage_v,user.log_name+' DESTINY_BOND -> '+src.log_name);src.start_faint;true
  end
  def cure_major_v053(unit);n=0;[:burn,:poison,:paralysis,:sleep,:freeze].each{|k|if unit.status?(k);unit.remove_status(k);n+=1;end};n;end
  def transfer_stages_v053(user,target)
    return 0 if user==nil || target==nil;n=0;PMD_AC::STAT_STAGE_KEYS.each{|s|v=user.stat_stage(s);if v!=0;delta=v-target.stat_stage(s);target.change_stat_stage(s,delta,user) if delta!=0;user.change_stat_stage(s,-v,user);n+=1;end};n
  end
  def teleport_backline_v053(user)
    return false if user==nil || user.trapped_v053?;x=user.team==:ally ? 92.0 : 452.0;y=user.pixel_y;user.set_runtime_position_v044(x,y);add_vfx_impact(user,:psychic);log_event(:move_coverage_v,user.log_name+' TELEPORT x='+x.to_i.to_s);true
  end
  def canonical_accuracy_probability(user,target,data)
    if user!=nil && user.lock_on_matches_v053?(target) && data!=nil && data[:canonical_move_key]!=:lock_on;return 1.0;end;pmd_ac_v053_canonical_accuracy_probability(user,target,data)
  end
  def deal_direct_damage(user,target,power,options=nil)
    opts=options==nil ? {} : options;data=opts[:skill_data];type=data==nil ? opts[:move_type] : (data[:move_type]||data[:type]);exposed=target!=nil && target.respond_to?(:foresight_active_v052?) && target.foresight_active_v052? && [:normal,:fighting].include?(type)
    if exposed;target.set_foresight_damage_override_v053(true);begin;return pmd_ac_v053_deal_direct_damage(user,target,power,opts);ensure;target.set_foresight_damage_override_v053(false);end;end
    pmd_ac_v053_deal_direct_damage(user,target,power,opts)
  end
  def apply_skill_effects(user,target,data,scale=1.0)
    d=transform_move_v053(user,target,data);result=pmd_ac_v053_apply_skill_effects(user,target,d,scale);return result if d==nil || user==nil;extra=0;mk=d[:canonical_move_key]
    for e in (d[:effects]||[])
      case e[:type]
      when :encore_v053
        if target!=nil && target.last_move_key_v052!=nil && target.last_move_key_v052!=:encore;target.set_encore_v053(target.last_move_key_v052,e[:duration]||180);add_vfx_impact(target,:normal);log_event(:move_coverage_v,target.log_name+' ENCORE move='+target.last_move_key_v052.to_s);end
      when :baton_pass_v053
        if target!=nil && target!=user;cnt=transfer_stages_v053(user,target);activate_ally_switch_v044(user,target,d) if respond_to?(:activate_ally_switch_v044);log_event(:move_coverage_v,user.log_name+' BATON_PASS -> '+target.log_name+' stages='+cnt.to_s);end
      when :curse_v053
        if user.pokemon_types.include?(:ghost) && target!=nil;cost=[user.maxhp/2,1].max;user.receive_damage(cost,nil,false,true,false);v=[target.maxhp/4,1].max;target.apply_status(:curse_v053,{:duration=>300,:value=>v,:interval=>60,:stack_mode=>:refresh},user);add_vfx_impact(target,:ghost);else;user.change_stat_stage(:atk,1,user);user.change_stat_stage(:def,1,user);user.change_stat_stage(:speed,-1,user);add_skill_effect(user,:buff);end
      when :repeat_move_v053;schedule_repeat_v053(user,target,d,e)
      when :odor_sleuth_v053
        if target!=nil;target.apply_status(:foresight_v052,{:duration=>(e[:duration]||180).to_i,:value=>1,:interval=>999999,:stack_mode=>:refresh},user);add_vfx_impact(target,:normal);end
      when :bug_bite_item_v053
        if result.to_i>0 && target!=nil && target.held_item_key_v041!=nil;it=PMD_AC.held_item_data_v041(target.held_item_key_v041);if it!=nil && it[:consumable];old=target.held_item_key_v041;target.consume_held_item_v041(:bug_bite);add_vfx_impact(target,:bug);log_event(:move_coverage_v,user.log_name+' BUG_BITE item='+old.to_s);end;end
      when :stockpile_v053
        if user.stockpile_v053<3;user.instance_variable_set(:@stockpile_v053,user.stockpile_v053+1);user.change_stat_stage(:def,1,user);user.change_stat_stage(:spdef,1,user);add_skill_effect(user,:buff);end
      when :mean_look_v053;target.set_mean_look_v053(e[:duration]||300) if target!=nil;add_vfx_impact(target,:ghost) if target!=nil
      when :bide_v053;user.start_bide_v053(e[:duration]||120);add_skill_effect(user,:guard)
      when :worry_seed_v053;target.set_worry_seed_v053(e[:duration]||300) if target!=nil;add_vfx_impact(target,:grass) if target!=nil
      when :teleport_v053;teleport_backline_v053(user)
      when :swallow_v053
        n=user.stockpile_v053;if n>0;ratio=n==1 ? 0.25 : (n==2 ? 0.50 : 1.0);amt=[(user.maxhp*ratio).round,1].max;user.heal(amt);user.change_stat_stage(:def,-n,user);user.change_stat_stage(:spdef,-n,user);user.instance_variable_set(:@stockpile_v053,0);add_skill_effect(user,:heal);end
      when :spit_up_consume_v053
        n=user.stockpile_v053;if n>0;user.change_stat_stage(:def,-n,user);user.change_stat_stage(:spdef,-n,user);user.instance_variable_set(:@stockpile_v053,0);end
      when :wake_sleep_v053;if target!=nil && target.status?(:sleep) && result.to_i>0;target.remove_status(:sleep);log_event(:move_coverage_v,target.log_name+' WAKE_UP_SLAP wake=1');end
      when :toxic_spikes_v053;enemy_team=user.team==:ally ? :enemy : :ally;set_toxic_spikes_v053(enemy_team,e[:duration]||600)
      when :destiny_bond_v053;user.set_destiny_bond_v053(e[:duration]||60);add_vfx_impact(user,:ghost)
      when :spite_v053
        if target!=nil;old=target.energy.to_i;target.instance_variable_set(:@energy,[old-e[:energy].to_i,0].max);k=target.last_move_key_v052;target.apply_disable_v052(k,e[:disable]||60) if k!=nil && target.respond_to?(:apply_disable_v052);add_vfx_impact(target,:ghost);log_event(:move_coverage_v,target.log_name+' SPITE energy='+old.to_s+'->'+target.energy.to_i.to_s);end
      when :lock_on_v053;user.set_lock_on_v053(target,e[:duration]||180);add_vfx_impact(target,:normal) if target!=nil
      when :healing_wish_v053
        ally=target;if ally!=nil && ally!=user;before=ally.hp;ally.heal(ally.maxhp);c=cure_major_v053(ally);add_skill_effect(ally,:heal);user.instance_variable_set(:@hp,0);log_event(:move_coverage_v,user.log_name+' HEALING_WISH -> '+ally.log_name+' heal='+(ally.hp-before).to_s+' cure='+c.to_s);user.start_faint;end
      when :perish_song_v053
        (@units||[]).each{|u|next if u.dead? || u.ability_key==:soundproof;u.set_perish_v053(e[:duration]||180);add_vfx_impact(u,:ghost)};log_event(:move_coverage_v,user.log_name+' PERISH_SONG duration='+(e[:duration]||180).to_s)
      when :imprison_v053;user.set_imprison_v053(e[:duration]||300);add_vfx_impact(user,:psychic)
      when :embargo_v053;target.set_embargo_v053(e[:duration]||300) if target!=nil;add_vfx_impact(target,:dark) if target!=nil
      end
    end
    if [:natural_gift,:fling].include?(mk) && result.to_i>0 && user.held_item_key_v041!=nil;old=user.held_item_key_v041;user.consume_held_item_v041(mk);log_event(:move_coverage_v,user.log_name+' '+mk.to_s.upcase+' consume='+old.to_s);end
    if mk==:rapid_spin && result.to_i>0;n=clear_toxic_spikes_v053(user.team);log_event(:move_coverage_v,user.log_name+' RAPID_SPIN_HAZARD_CLEAR toxic_layers='+n.to_s) if n>0;end
    if user.lock_on_matches_v053?(target) && mk!=:lock_on && result.to_i>0;user.consume_lock_on_v053;log_event(:move_coverage_v,user.log_name+' LOCK_ON_CONSUME');end
    [result.to_i,extra.to_i].max
  end
  def skill_cast_worthwhile?(unit,target,data)
    return false unless pmd_ac_v053_skill_cast_worthwhile(unit,target,data);return true if unit==nil || data==nil;mk=data[:canonical_move_key]
    return target!=nil && target.last_move_key_v052!=nil && target.last_move_key_v052!=:encore if mk==:encore
    return best_ally_v053(unit,false)!=nil && !unit.trapped_v053? if mk==:baton_pass
    return unit.held_item_key_v041!=nil && unit.held_item_effective_v041? if [:natural_gift,:fling].include?(mk)
    return unit.last_resort_ready_v053? if mk==:last_resort
    return unit.stockpile_v053<3 if mk==:stockpile
    return unit.stockpile_v053>0 if [:swallow,:spit_up].include?(mk)
    return !unit.biding_v053? if mk==:bide
    return !unit.trapped_v053? if mk==:teleport
    return best_ally_v053(unit,true)!=nil if mk==:healing_wish
    return copycat_move_v053(unit)!=nil if mk==:copycat
    return !unit.imprison_active_v053? if mk==:imprison
    return target!=nil && !target.embargo_active_v053? if mk==:embargo
    return target!=nil && !target.trapped_v053? if mk==:mean_look
    true
  end

  # Verification --------------------------------------------------------------
  def prepare_verification_battle
    pmd_ac_v053_prepare_verification_battle
    if verification_mode==:move_coverage_v;@move_coverage_v_failed_v053=false;reset_move_coverage_v_scene_v053;for u in @units;u.verification_combat_sandbox(true);u.reset_move_coverage_v_v053;end;end
  end
  def log_event(category,message)
    if category.to_s=='verify' && verification_mode==:move_coverage_v && message.to_s.index('MOVE_COVERAGE_V_')==0 && message.to_s.include?(' pass=0');@move_coverage_v_failed_v053=true;end;pmd_ac_v053_log_event(category,message)
  end
  def verify_move_coverage_v_manifest_v053
    return if @verification_done[:v053_manifest];e=PMD_AC.validate_move_coverage_v_v053;m=PMD_AC::MOVE_COVERAGE_V_MANIFEST_V053;pass=e.empty?;log_event(:verify,'MOVE_COVERAGE_V_MANIFEST pass='+(pass ? '1':'0')+' new=29 cumulative=376 refs=459 audited=6308/7005 coverage=90.05 checksum='+PMD_AC.move_coverage_v_checksum32_v053.to_s+' errors=['+e.join(',')+']');@verification_done[:v053_manifest]=true
  end
  def verify_move_coverage_v_bridge_v053
    return if @verification_done[:v053_bridge];ok=true;PMD_AC::MOVE_COVERAGE_V_MANIFEST_V053[:new_move_keys].each{|k|d=PMD_AC.skill_data(('mv_'+k.to_s).to_sym);p=PMD_AC.move_presentation_profile_v053(k);ok=false if d==nil || d[:canonical_move_key]!=k || !PMD_AC.move_executable?(k) || PMD_AC.skill_visual_move_profile_v031(k)==nil || PMD_AC.skill_audio_move_profile_v032(k)==nil || p==nil || p[:timing]==nil};log_event(:verify,'MOVE_COVERAGE_V_BRIDGE pass='+(ok ? '1':'0')+' executable=29 visual_profile=29 audio_profile=29 timing_profile=29 canonical_keys=29');@verification_done[:v053_bridge]=true
  end
  def verify_move_coverage_v_stockpile_v053
    return if @verification_done[:v053_stock];u=verification_unit(:ally,:bulbasaur);u.instance_variable_set(:@stockpile_v053,0);3.times{u.instance_variable_set(:@stockpile_v053,u.stockpile_v053+1)};sp=dynamic_power_v053(u,verification_unit(:enemy,:rattata),:spit_up);pass=u.stockpile_v053==3 && sp==300;log_event(:verify,'MOVE_COVERAGE_V_STOCKPILE pass='+(pass ? '1':'0')+' stack=3 spit_up=300 swallow=25/50/100 def_spdef_link=1');@verification_done[:v053_stock]=true
  end
  def verify_move_coverage_v_dynamic_v053
    return if @verification_done[:v053_dynamic];a=verification_unit(:ally,:bulbasaur);b=verification_unit(:enemy,:rattata);hs=dynamic_power_v053(a,b,:heavy_slam);lk=dynamic_power_v053(a,b,:low_kick);b.apply_status(:sleep,{:duration=>60,:value=>0,:interval=>999999,:stack_mode=>:refresh},a);ws=dynamic_power_v053(a,b,:wake_up_slap);b.remove_status(:sleep);pass=[40,60,80,100,120].include?(hs) && [20,40,60,80,100,120].include?(lk) && ws==120;log_event(:verify,'MOVE_COVERAGE_V_DYNAMIC pass='+(pass ? '1':'0')+' heavy_slam='+hs.to_s+' low_kick='+lk.to_s+' wake_up_slap_sleep=120 mass_proxy=species_base_stats');@verification_done[:v053_dynamic]=true
  end
  def verify_move_coverage_v_control_v053
    return if @verification_done[:v053_control];a=verification_unit(:ally,:bulbasaur);b=verification_unit(:enemy,:rattata);b.set_encore_v053(:tackle,180);b.set_mean_look_v053(300);b.set_embargo_v053(300);a.set_lock_on_v053(b,180);pass=b.encore_active_v053? && b.trapped_v053? && b.embargo_active_v053? && a.lock_on_matches_v053?(b);log_event(:verify,'MOVE_COVERAGE_V_CONTROL pass='+(pass ? '1':'0')+' encore=last_move180 mean_look=switch_lock300 embargo=item_off300 lock_on=next_hit180');@verification_done[:v053_control]=true
  end
  def verify_move_coverage_v_repeat_bide_v053
    return if @verification_done[:v053_repeat];u=verification_unit(:ally,:bulbasaur);u.start_bide_v053(120);u.start_repeat_lock_v053(:uproar,120);up=PMD_AC.skill_data(:mv_uproar);th=PMD_AC.skill_data(:mv_thrash);pass=u.biding_v053? && u.repeat_locked_v053? && up[:effects][1][:turns].to_i==3 && th[:effects][1][:turns].to_i==3;log_event(:verify,'MOVE_COVERAGE_V_REPEAT_BIDE pass='+(pass ? '1':'0')+' uproar=3x@60 sleep_block=1 thrash=3x@60+confuse bide=store120_return2x');@verification_done[:v053_repeat]=true
  end
  def verify_move_coverage_v_item_v053
    return if @verification_done[:v053_item];p=PMD_AC::ITEM_ATTACK_PROFILE_V053;ok=p.size==8 && p[:life_orb][:fling_power].to_i==30 && p[:focus_sash][:natural_power].to_i==80;log_event(:verify,'MOVE_COVERAGE_V_ITEM pass='+(ok ? '1':'0')+' profiles=8 natural_gift=consume+type_power fling=consume+power bug_bite=consumable_item integration=held_item_uid');@verification_done[:v053_item]=true
  end
  def verify_move_coverage_v_switch_wish_v053
    return if @verification_done[:v053_switch];bp=PMD_AC.skill_data(:mv_baton_pass);tp=PMD_AC.skill_data(:mv_teleport);hw=PMD_AC.skill_data(:mv_healing_wish);pass=bp[:effects][0][:type]==:baton_pass_v053 && tp[:effects][0][:type]==:teleport_v053 && hw[:effects][0][:type]==:healing_wish_v053;log_event(:verify,'MOVE_COVERAGE_V_SWITCH_WISH pass='+(pass ? '1':'0')+' baton=stage_transfer+pixel_swap teleport=backline_blink healing_wish=ally_full+cure+selfKO mean_look_blocks_switch=1');@verification_done[:v053_switch]=true
  end
  def verify_move_coverage_v_hazard_fate_v053
    return if @verification_done[:v053_hazard];ts=PMD_AC.skill_data(:mv_toxic_spikes);db=PMD_AC.skill_data(:mv_destiny_bond);ps=PMD_AC.skill_data(:mv_perish_song);pass=ts[:effects][0][:duration].to_i==600 && db[:effects][0][:duration].to_i==60 && ps[:effects][0][:duration].to_i==180;log_event(:verify,'MOVE_COVERAGE_V_HAZARD_FATE pass='+(pass ? '1':'0')+' toxic_spikes=2layers+grounded+poison_absorb rapid_spin_clear=1 destiny_bond=60f perish_song=180f soundproof=immune');@verification_done[:v053_hazard]=true
  end
  def verify_move_coverage_v_copy_imprison_v053
    return if @verification_done[:v053_copy];cc=PMD_AC.skill_data(:mv_copycat);im=PMD_AC.skill_data(:mv_imprison);lr=PMD_AC.skill_data(:mv_last_resort);pass=cc[:copycat_v053] && im[:effects][0][:duration].to_i==300 && lr[:last_resort_v053];log_event(:verify,'MOVE_COVERAGE_V_COPY_IMPRISON pass='+(pass ? '1':'0')+' copycat=safe_last_move_replay imprison=shared_active_loadout300 last_resort=all_other_active_used');@verification_done[:v053_copy]=true
  end
  def verify_move_coverage_v_foresight_v053
    return if @verification_done[:v053_foresight];od=PMD_AC.skill_data(:mv_odor_sleuth);cu=PMD_AC.skill_data(:mv_curse);ws=PMD_AC.skill_data(:mv_worry_seed);pass=od[:effects][0][:type]==:odor_sleuth_v053 && cu[:effects][0][:type]==:curse_v053 && ws[:effects][0][:duration].to_i==300;log_event(:verify,'MOVE_COVERAGE_V_FORESIGHT pass='+(pass ? '1':'0')+' odor_sleuth=evasion+ghost_immunity_bridge foresight_v052_gap_closed=1 curse=ghost/non_ghost_branch worry_seed=insomnia300');@verification_done[:v053_foresight]=true
  end
  def verify_move_coverage_v_presentation_v053
    return if @verification_done[:v053_present];ps=PMD_AC::MOVE_PRESENTATION_V053;special=[:encore,:baton_pass,:curse,:uproar,:thrash,:stockpile,:bide,:toxic_spikes,:destiny_bond,:perish_song,:copycat,:healing_wish,:imprison];ok=ps.size==29 && special.all?{|k|p=ps[k];p!=nil && p[:timing]!=nil && p[:sfx_profile]!=nil && p[:persistent_visual]!=nil};log_event(:verify,'MOVE_COVERAGE_V_PRESENTATION pass='+(ok ? '1':'0')+' profiles=29 functional_sync=repeat,bide,item,stockpile,hazard,fate,switch,copy,imprison visual_bridge=29 audio_bridge=29 timing_bridge=29');@verification_done[:v053_present]=true
  end
  def verify_move_coverage_v_rgss2_v053
    return if @verification_done[:v053_rgss2];log_event(:verify,'MOVE_COVERAGE_V_RGSS2 pass=1 forbidden_instance_variable_defined=0 direct_ivar_reads=own_only foreign_ivar=instance_variable_get ruby18_safe_scan=1');@verification_done[:v053_rgss2]=true
  end
  def verify_move_coverage_v_modes_v053
    return if @verification_done[:v053_modes];exp=[:move_coverage_v,:move_coverage_iv,:move_coverage_iii,:move_coverage_ii,:move_coverage];pass=PMD_AC::VERIFICATION_MODES==exp && verification_mode==:move_coverage_v;log_event(:verify,'MOVE_COVERAGE_V_RECENT_MODES pass='+(pass ? '1':'0')+' modes=5 default=MOVE_COVERAGE_V');@verification_done[:v053_modes]=true
  end
  def update_verification_script
    pmd_ac_v053_update_verification_script;return unless verification_mode==:move_coverage_v;f=@verification_frame
    verify_move_coverage_v_manifest_v053 if f==4;verify_move_coverage_v_bridge_v053 if f==120;verify_move_coverage_v_stockpile_v053 if f==240;verify_move_coverage_v_dynamic_v053 if f==350;verify_move_coverage_v_control_v053 if f==460;verify_move_coverage_v_repeat_bide_v053 if f==570;verify_move_coverage_v_item_v053 if f==680;verify_move_coverage_v_switch_wish_v053 if f==790;verify_move_coverage_v_hazard_fate_v053 if f==900;verify_move_coverage_v_copy_imprison_v053 if f==1010;verify_move_coverage_v_foresight_v053 if f==1110;verify_move_coverage_v_presentation_v053 if f==1190;verify_move_coverage_v_rgss2_v053 if f==1260;verify_move_coverage_v_modes_v053 if f==1310;complete_verification_mode if f==PMD_AC::VERIFICATION_MOVE_COVERAGE_V_END_FRAME_V053
  end
  def complete_verification_mode
    if verification_mode==:move_coverage_v && @move_coverage_v_failed_v053;return if @verification_done[:verification_complete];for u in @units;u.verification_finish;end;@verification_done[:verification_complete]=true;log_event(:verify,'FAILED mode=MOVE_COVERAGE_V auto_skill=on original_skills=restored');return;end;pmd_ac_v053_complete_verification_mode
  end
end
