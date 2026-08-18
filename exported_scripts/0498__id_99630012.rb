# encoding: UTF-8
#===============================================================================
# ■ PMD AutoChess - Orbit Stat FX + Focus Override Hooks v1.05.14
#===============================================================================
# 【用途】
# 1. 承接 v1.05.13 的能力升降／KO／Result Hold，可讀性邏輯維持不變，
#    但把原本單一紅／藍光圈改為「多個光圈逐步繞著寶可夢上升／下降後消失」。
# 2. 使用者明確指定：能力上升 / 下降要是多個光圈，分相位、繞身、邊移動邊淡出。
# 3. 同步啟動下一階段的 Focus Override Hooks：先把 Important Skill / Boss Focus
#    的判定掛點整理進場景層，暫不大幅改動演出，只建立安全腳手架與 LOG。
#
# 【本版不改】
# - Damage / HP / AI / Energy / Attack Wait / Spatial endpoint / hit timing
# - v1.05.13 的 KO Authority（start_faint 後顯示 KO）
# - v1.05.13 的 Result Hold 18f
#
# 【多光圈視覺規則】
# - 上升：紅色 4 個光圈，從腳邊附近依序生成，繞著單位做小幅旋轉，逐步往上，
#   同時淡出與微縮放。
# - 下降：藍色 4 個光圈，從較高處依序生成，繞著單位反向旋轉，逐步往下，
#   同時淡出。
# - 每個光圈固定相位差與時間錯開；不改單位 logical x/y，只是 presentation sprite。
#
# 【下一階段腳手架】
# - 提供 result_focus_override_target_v10514? / result_focus_override_note_v10514 等方法。
# - 目前只做 hooks 與 summary，不強行改 precharge / hold / banner。等這版 ring 視覺 PASS
#   後，再把真正的 Important Skill / Boss Focus 演出差異放進來，避免一次混兩個 root cause。
#
# 【主要參數】
# RESULT_STAT_RING_COUNT_V10514 = 4
# RESULT_STAT_RING_STAGGER_V10514 = 5
# RESULT_STAT_FX_FRAMES_V10514 = 28
#
# 【LOG】
# BATTLE_ORBIT_STAT_FX_V10514 START ...
# BATTLE_STAT_STAGE_FX_V10514 target=... dir=up/down stat=... delta=... rings=4
# BATTLE_FOCUS_OVERRIDE_HOOKS_V10514 START active=0 important_skill_hooks=1 boss_hooks=1
# BATTLE_ORBIT_STAT_FX_SUMMARY_V10514 ...
#===============================================================================
$imported={} unless defined?($imported)
$imported['PMD_AutoChess_OrbitStatFX_FocusOverrideHooks_v10514']=true

module PMD_AC
  RESULT_STAT_RING_COUNT_V10514 = 4
  RESULT_STAT_RING_STAGGER_V10514 = 5
  RESULT_STAT_FX_FRAMES_V10514 = 28
  RESULT_STAT_RING_RADIUS_X_V10514 = 14.0
  RESULT_STAT_RING_RADIUS_Y_V10514 = 5.0
  RESULT_STAT_RING_RISE_Y_V10514 = 44.0
  RESULT_STAT_RING_FALL_Y_V10514 = 42.0

  IMPORTANT_SKILL_FOCUS_OVERRIDE_KEYS_V10514 = []
  BOSS_FOCUS_OVERRIDE_ENCOUNTERS_V10514 = []

  def self.clamp_v10514(v, lo, hi)
    return lo if v < lo
    return hi if v > hi
    v
  end
end

class Game_PMDChessUnit
  alias pmd_ac_v10514_change_stat_stage change_stat_stage unless method_defined?(:pmd_ac_v10514_change_stat_stage)

  def change_stat_stage(stat,delta,source=nil)
    before=respond_to?(:stat_stage) ? stat_stage(stat).to_i : 0
    r=pmd_ac_v10514_change_stat_stage(stat,delta,source)
    after=respond_to?(:stat_stage) ? stat_stage(stat).to_i : before
    actual=after-before
    return r if actual==0
    scene=@scene
    if scene!=nil && scene.respond_to?(:result_feedback_stat_fx_note_v10514)
      direction=(actual>0 ? :up : :down)
      scene.result_feedback_stat_fx_note_v10514(self,direction,stat,actual)
    end
    r
  rescue
    pmd_ac_v10514_change_stat_stage(stat,delta,source)
  end
end

class Sprite_PMDChessUnit
  alias pmd_ac_v10514_initialize initialize unless method_defined?(:pmd_ac_v10514_initialize)
  alias pmd_ac_v10514_update update unless method_defined?(:pmd_ac_v10514_update)
  alias pmd_ac_v10514_dispose dispose unless method_defined?(:pmd_ac_v10514_dispose)

  def initialize(*args)
    pmd_ac_v10514_initialize(*args)
    orbit_stat_fx_build_v10514
  end

  def orbit_stat_fx_draw_ring_bitmap_v10514(bmp,r,g,b)
    return if bmp==nil || bmp.disposed?
    bmp.clear
    w=bmp.width.to_i
    h=bmp.height.to_i
    cx=(w-1).to_f/2.0
    cy=(h-1).to_f/2.0
    rx=[cx-2.0,1.0].max
    ry=[cy-2.0,1.0].max
    for yy in 0...h
      for xx in 0...w
        dx=(xx.to_f-cx)/rx
        dy=(yy.to_f-cy)/ry
        q=dx*dx+dy*dy
        next if q>1.0 || q<0.48
        alpha=(q>0.86 ? 235 : (q>0.68 ? 160 : 78))
        bmp.set_pixel(xx,yy,Color.new(r,g,b,alpha))
      end
    end
  rescue
  end

  def orbit_stat_fx_make_ring_v10514(r,g,b)
    sp=Sprite.new(self.viewport)
    sp.bitmap=Bitmap.new(PMD_AC::RESULT_STAT_RING_W_V10513,PMD_AC::RESULT_STAT_RING_H_V10513)
    orbit_stat_fx_draw_ring_bitmap_v10514(sp.bitmap,r,g,b)
    sp.ox=sp.bitmap.width/2
    sp.oy=sp.bitmap.height/2
    sp.visible=false
    sp.opacity=0
    sp.blend_type=1
    sp
  rescue
    nil
  end

  def orbit_stat_fx_build_array_v10514(r,g,b)
    arr=[]
    PMD_AC::RESULT_STAT_RING_COUNT_V10514.times do
      arr << orbit_stat_fx_make_ring_v10514(r,g,b)
    end
    arr
  rescue
    []
  end

  def orbit_stat_fx_build_v10514
    @orbit_stat_up_sprites_v10514=orbit_stat_fx_build_array_v10514(255,70,55)
    @orbit_stat_down_sprites_v10514=orbit_stat_fx_build_array_v10514(60,135,255)
  rescue
    @orbit_stat_up_sprites_v10514=[]
    @orbit_stat_down_sprites_v10514=[]
  end

  def orbit_stat_fx_active_v10514?(direction)
    return false if @unit==nil
    age=@unit.respond_to?(:result_feedback_stat_fx_age_v10513) ? @unit.result_feedback_stat_fx_age_v10513(direction) : 999999
    age >= 0 && age < (PMD_AC::RESULT_STAT_FX_FRAMES_V10514 + PMD_AC::RESULT_STAT_RING_STAGGER_V10514 * PMD_AC::RESULT_STAT_RING_COUNT_V10514)
  rescue
    false
  end

  def orbit_stat_fx_update_one_v10514(sp,direction,index)
    return if sp==nil || sp.disposed? || @unit==nil
    base_age=@unit.respond_to?(:result_feedback_stat_fx_age_v10513) ? @unit.result_feedback_stat_fx_age_v10513(direction) : 999999
    age=base_age - index.to_i * PMD_AC::RESULT_STAT_RING_STAGGER_V10514
    frames=PMD_AC::RESULT_STAT_FX_FRAMES_V10514
    if age < 0 || age >= frames || @unit.dead?
      sp.visible=false
      return
    end
    t=age.to_f / [frames-1,1].max.to_f
    phase=(index.to_f / [PMD_AC::RESULT_STAT_RING_COUNT_V10514,1].max.to_f) * Math::PI * 2.0
    angle=(direction==:up ? 1.0 : -1.0) * (Math::PI * 2.0 * (0.45 + t * 0.90)) + phase
    rx=PMD_AC::RESULT_STAT_RING_RADIUS_X_V10514 * (1.00 - 0.18 * t)
    ry=PMD_AC::RESULT_STAT_RING_RADIUS_Y_V10514 * (1.00 - 0.10 * t)
    xoff=Math.cos(angle) * rx
    wobble=Math.sin(angle) * ry
    if direction==:up
      ybase=12.0 - PMD_AC::RESULT_STAT_RING_RISE_Y_V10514 * t
    else
      ybase=-28.0 + PMD_AC::RESULT_STAT_RING_FALL_Y_V10514 * t
    end
    sp.x=self.x + xoff.round
    sp.y=self.y + (ybase + wobble).round
    sp.z=self.z + 28 + index.to_i
    zoom=0.78 + 0.18 * t
    sp.zoom_x=zoom
    sp.zoom_y=zoom
    fade=(1.0-t)
    fade*=0.92 if age < 3
    sp.opacity=PMD_AC.clamp_v10514((70 + 165 * fade).round,0,255)
    sp.visible=true
  rescue
    sp.visible=false if sp!=nil && !sp.disposed?
  end

  def orbit_stat_fx_update_array_v10514(arr,direction)
    return if arr==nil
    i=0
    while i < arr.size
      orbit_stat_fx_update_one_v10514(arr[i],direction,i)
      i+=1
    end
  rescue
  end

  def update
    orbit_stat_fx_update_array_v10514(@orbit_stat_up_sprites_v10514,:up)
    orbit_stat_fx_update_array_v10514(@orbit_stat_down_sprites_v10514,:down)
    pmd_ac_v10514_update
  end

  def orbit_stat_fx_dispose_array_v10514(arr)
    return if arr==nil
    arr.each do |sp|
      next if sp==nil
      begin
        bmp=sp.bitmap
        bmp.dispose if bmp!=nil && !bmp.disposed?
      rescue
      end
      begin
        sp.dispose unless sp.disposed?
      rescue
      end
    end
  rescue
  end

  def dispose
    orbit_stat_fx_dispose_array_v10514(@orbit_stat_up_sprites_v10514)
    orbit_stat_fx_dispose_array_v10514(@orbit_stat_down_sprites_v10514)
    @orbit_stat_up_sprites_v10514=nil
    @orbit_stat_down_sprites_v10514=nil
    pmd_ac_v10514_dispose
  end
end

class Scene_PMD_AutoChess
  alias pmd_ac_v10514_start_battle start_battle unless method_defined?(:pmd_ac_v10514_start_battle)
  alias pmd_ac_v10514_focus_summary focus_cast_log_summary_v1055 unless method_defined?(:pmd_ac_v10514_focus_summary)

  def result_feedback_stat_fx_note_v10514(unit,direction,stat,actual)
    log_event(:battle,'BATTLE_STAT_STAGE_FX_V10514 target='+(unit==nil ? 'NONE' : unit.log_name.to_s)+
      ' dir='+direction.to_s+' stat='+stat.to_s+' delta='+actual.to_i.to_s+
      ' rings='+PMD_AC::RESULT_STAT_RING_COUNT_V10514.to_i.to_s)
    true
  rescue
    false
  end

  def result_focus_override_target_v10514?(owner=nil,skill_key=nil)
    encounter=(respond_to?(:battle_id) ? battle_id : nil)
    important=(skill_key!=nil && PMD_AC::IMPORTANT_SKILL_FOCUS_OVERRIDE_KEYS_V10514.include?(skill_key))
    boss=(encounter!=nil && PMD_AC::BOSS_FOCUS_OVERRIDE_ENCOUNTERS_V10514.include?(encounter))
    important || boss
  rescue
    false
  end

  def result_focus_override_note_v10514(owner=nil,skill_key=nil)
    return false unless result_focus_override_target_v10514?(owner,skill_key)
    log_event(:battle,'BATTLE_FOCUS_OVERRIDE_HOOK_APPLY_V10514 owner='+(owner==nil ? 'NONE' : owner.log_name.to_s)+
      ' skill='+(skill_key==nil ? 'NONE' : skill_key.to_s))
    true
  rescue
    false
  end

  def start_battle
    r=pmd_ac_v10514_start_battle
    if respond_to?(:verification_mode) && verification_mode==:normal
      log_event(:battle,'BATTLE_ORBIT_STAT_FX_V10514 START'+
        ' ring_count='+PMD_AC::RESULT_STAT_RING_COUNT_V10514.to_s+
        ' stagger='+PMD_AC::RESULT_STAT_RING_STAGGER_V10514.to_s+
        ' stat_fx_frames='+PMD_AC::RESULT_STAT_FX_FRAMES_V10514.to_s+
        ' stat_up=multi_red_orbit_rise stat_down=multi_blue_orbit_fall'+
        ' ko_v10513_retained=1 result_hold_v10513_retained=1')
      log_event(:battle,'BATTLE_FOCUS_OVERRIDE_HOOKS_V10514 START active=0 important_skill_hooks=1 boss_hooks=1'+
        ' next_phase_scaffold=1 no_timing_change_yet=1')
    end
    r
  end

  def orbit_stat_fx_summary_v10514
    up=@result_stat_up_count_v10513.to_i
    down=@result_stat_down_count_v10513.to_i
    ko=@result_ko_count_v10513.to_i
    log_event(:battle,'BATTLE_ORBIT_STAT_FX_SUMMARY_V10514'+
      ' stat_up='+up.to_s+' stat_down='+down.to_s+' ko='+ko.to_s+
      ' ring_count='+PMD_AC::RESULT_STAT_RING_COUNT_V10514.to_s+
      ' result_hold_retained=1 focus_override_hooks_active=0')
    true
  rescue
    false
  end

  def focus_cast_log_summary_v1055
    r=pmd_ac_v10514_focus_summary
    orbit_stat_fx_summary_v10514
    r
  rescue
    false
  end
end
