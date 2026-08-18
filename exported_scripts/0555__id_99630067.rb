# encoding: UTF-8
#===============================================================================
# ■ PMD AutoChess - Curated Visual Test Four-Move Loadouts v1.05.70
#-------------------------------------------------------------------------------
# 【用途】
# v1.05.59 素材測試 roster 原本直接使用預設 Lv15 自動學招，容易讓視覺測試與
# AI/學招順序混在一起。本版只對 imported visual fixture 明確配置 6 隻 × 4 招。
# 烈咬陸鯊不放天氣技，避免素材動畫測試被「維持沙暴」策略長時間壟斷。
# 正式 Party、Hunt、Challenge、Progression 完全不受影響。
#===============================================================================
$imported={} unless defined?($imported)
$imported['PMD_AutoChess_CuratedVisualTestLoadouts_v10570']=true

module PMD_AC
  VISUAL_TEST_LOADOUTS_V10570={
    :scyther=>[:wing_attack,:quick_attack,:x_scissor,:leer],
    :gardevoir=>[:psychic,:confusion,:magical_leaf,:growl],
    :lucario=>[:force_palm,:metal_claw,:quick_attack,:counter],
    :garchomp=>[:dragon_claw,:earthquake,:crunch,:fire_fang],
    :caterpie=>[:tackle,:string_shot,:bug_bite,:electroweb],
    :rotom=>[:thunder_shock,:confuse_ray,:shadow_ball,:thunder_wave]
  }

  class << self
    def visual_test_apply_loadout_v10570(unit)
      return false if unit==nil || unit.pokemon_instance==nil
      sp=unit.pokemon_instance.species_key
      moves=VISUAL_TEST_LOADOUTS_V10570[sp]
      return false if moves==nil || moves.empty?
      pi=unit.pokemon_instance
      pi.ensure_growth_data_v045 if pi.respond_to?(:ensure_growth_data_v045)
      usable=[]
      moves.each do |mv|
        next unless move_executable?(mv)
        unless pi.knows_move_v045?(mv)
          pi.learn_known_move_v045(mv,pi.level,sp,false)
        end
        usable.push(mv) if pi.knows_move_v045?(mv)
      end
      return false unless usable.size==4
      pi.set_active_moves_v045(usable)
    rescue
      false
    end

    def visual_test_loadout_audit_v10570
      bad=[]
      VISUAL_TEST_LOADOUTS_V10570.each do |sp,moves|
        bad.push(sp.to_s+':count') unless moves.size==4 && moves.uniq.size==4
        moves.each{|mv|bad.push(sp.to_s+':'+mv.to_s) unless move_executable?(mv)}
      end
      {:pass=>bad.empty?,:species=>VISUAL_TEST_LOADOUTS_V10570.size,:slots=>24,:bad=>bad}
    rescue
      {:pass=>false,:species=>0,:slots=>0,:bad=>['audit_error']}
    end
  end
end

class Scene_PMD_AutoChess
  alias pmd_ac_v10570_create_units create_units unless method_defined?(:pmd_ac_v10570_create_units)
  alias pmd_ac_v10570_start_battle start_battle unless method_defined?(:pmd_ac_v10570_start_battle)

  def create_units
    pmd_ac_v10570_create_units
    begin
      if @visual_test_roster_v10559
        (@units||[]).each{|u|PMD_AC.visual_test_apply_loadout_v10570(u)}
        @visual_test_curated_loadout_v10570=true
      end
    rescue
    end
  end

  def start_battle
    r=pmd_ac_v10570_start_battle
    begin
      if @visual_test_curated_loadout_v10570 && @phase==:battle
        rows=[]
        (@units||[]).each do |u|
          next if u==nil || u.pokemon_instance==nil
          moves=u.pokemon_instance.battle_moves_v046 rescue []
          rows.push(u.pokemon_instance.species_key.to_s+'=['+moves.collect{|x|x.to_s}.join(',')+']')
        end
        a=PMD_AC.visual_test_loadout_audit_v10570
        log_event(:battle,'BATTLE_VISUAL_TEST_LOADOUT_V10570 pass='+(a[:pass] ? '1':'0')+
          ' species='+a[:species].to_i.to_s+'/6 slots='+a[:slots].to_i.to_s+'/24 rows={'+rows.join('|')+'}')
      end
    rescue
    end
    r
  end
end
