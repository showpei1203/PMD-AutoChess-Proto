# encoding: UTF-8
#===============================================================================
# ■ PMD AutoChess - Hunt Rare / Elite Feedback v1.05.71
#-------------------------------------------------------------------------------
# 【用途】
# 狩獵戰鬥在不改正式 UI 外觀的前提下，利用既有 v0.88 center notice 提醒稀有／
# 超稀有／傳說與 Elite 遭遇。正式 HUD 美化仍留待後續 UI Phase。
#===============================================================================
$imported={} unless defined?($imported)
$imported['PMD_AutoChess_HuntRareEliteFeedback_v10571']=true

module PMD_AC
  HUNT_RARITY_RANK_V10571={'common'=>0,'uncommon'=>1,'rare'=>2,'very_rare'=>3,'legendary'=>4}
  HUNT_RARITY_LABEL_V10571={'rare'=>'稀有遭遇','very_rare'=>'超稀有遭遇','legendary'=>'傳說遭遇'}

  class << self
    def hunt_unit_species_v10571(unit)
      return unit.pokemon_instance.species_key if unit!=nil && unit.respond_to?(:pokemon_instance) && unit.pokemon_instance!=nil
      return unit.key if unit!=nil && unit.respond_to?(:key)
      nil
    rescue
      nil
    end

    def hunt_feedback_scan_v10571(units)
      elites=[];rare=[];max_rank=0;max_key='common'
      (units||[]).each do |u|
        next if u==nil || u.team!=:enemy
        sp=hunt_unit_species_v10571(u);row=phase_div_species_v10553(sp) rescue nil
        rk=row==nil ? 'common' : row[:spawn_rarity].to_s
        rank=HUNT_RARITY_RANK_V10571[rk].to_i
        if rank>max_rank;max_rank=rank;max_key=rk;end
        rare.push(u.name.to_s) if rank>=2
        elites.push(u.name.to_s) if u.respond_to?(:elite_v084) && u.elite_v084
      end
      {:rarity=>max_key,:rank=>max_rank,:rare_names=>rare.uniq,:elite_names=>elites.uniq,
       :elite_count=>elites.size}
    rescue
      {:rarity=>'common',:rank=>0,:rare_names=>[],:elite_names=>[],:elite_count=>0}
    end
  end
end

class Scene_PMD_AutoChess
  alias pmd_ac_v10571_start_battle start_battle unless method_defined?(:pmd_ac_v10571_start_battle)
  alias pmd_ac_v10571_update update unless method_defined?(:pmd_ac_v10571_update)
  alias pmd_ac_v10571_focus_summary focus_cast_log_summary_v1055 unless method_defined?(:pmd_ac_v10571_focus_summary)

  def start_battle
    r=pmd_ac_v10571_start_battle
    begin
      req=rpg_request_v081
      if req!=nil && req[:phase_div_hunt_code_v10555]!=nil
        f=PMD_AC.hunt_feedback_scan_v10571(@units)
        q=[]
        if f[:elite_count].to_i>0
          q.push('菁英出現｜'+f[:elite_names].join('、'))
        end
        label=PMD_AC::HUNT_RARITY_LABEL_V10571[f[:rarity].to_s]
        if label!=nil && !f[:rare_names].empty?
          q.push(label+'｜'+f[:rare_names].join('、'))
        end
        @hunt_feedback_queue_v10571=q
        @hunt_feedback_wait_v10571=20
        log_event(:collection,'PHASE_DIV_HUNT_FEEDBACK_V10571 code='+req[:phase_div_hunt_code_v10555].to_s+
          ' rarity='+f[:rarity].to_s+' elite_count='+f[:elite_count].to_i.to_s+
          ' notices='+q.size.to_s+' ui=existing_center_notice')
      end
    rescue
    end
    r
  end

  def update
    pmd_ac_v10571_update
    begin
      return if @hunt_feedback_queue_v10571==nil || @hunt_feedback_queue_v10571.empty?
      @hunt_feedback_wait_v10571=@hunt_feedback_wait_v10571.to_i-1
      return if @hunt_feedback_wait_v10571>0
      text=@hunt_feedback_queue_v10571.shift
      add_center_notice_v088(text) if respond_to?(:add_center_notice_v088)
      @hunt_feedback_wait_v10571=76
    rescue
    end
  end

  def focus_cast_log_summary_v1055
    r=pmd_ac_v10571_focus_summary
    begin
      log_event(:battle,'BATTLE_PHASE_DIV_HUNT_RARE_ELITE_FEEDBACK_SUMMARY_V10571 ready=1'+
        ' rarity=rare,very_rare,legendary elite=1 center_notice=v088 ui_polish=deferred gameplay_change=0')
    rescue
    end
    r
  end
end
