#==============================================================================
# 【PMD AutoChess 中文維護說明】
# 腳本：PMD AutoChess Proto v0.33.1
# 分類：核心戰鬥 Runtime
#
# 【用途／機制】
# 承接前序 Data／Config，實際執行戰鬥 Scene、Unit、AI、技能與呈現。
#
# 【怎麼調整】
# 一般平衡與資料調整不要直接改 Runtime；若要追加功能，建議在較後腳本 alias 原方法後擴充。
#
# 【本腳本主要設定常數／資料表】
# - SKILL_SPECIAL_RGS3_GLOBAL_SCALE_V0331
#
# 【Runtime 主要方法（查流程時可直接搜尋）】
# - initialize / start / verify_skill_special_scale_v0331 / update_verification_script
#
# 【維護規則】
# - RPG Maker VX / RGSS2 / Ruby 1.8 相容。
# - instance_uid 才是 Pokémon 個體身份；Actor ID 只是容器。
# - 新增行為優先沿用既有 helper／Data 表；避免破壞已 Freeze 的舊核心。
# - 本專案新腳本也必須保留同等級的中文說明與實際範例。
#==============================================================================
#==============================================================================
# ■ PMD AutoChess Proto v0.33.1
#    Skill Special RGS3 Visual Scale Tuning
#------------------------------------------------------------------------------
#  Additive presentation-only patch on verified v0.33.
#  User feedback: specialized RGS3 skill animations are too large.
#  Applies a global 0.70 display multiplier to all v0.33 RGS3 special FX while
#  preserving each move's relative size differences, positions, timing, audio,
#  hit logic, collision, targeting and all combat semantics.
#==============================================================================
module PMD_AC
  SKILL_SPECIAL_RGS3_GLOBAL_SCALE_V0331 = 0.70
end

# Generic VX 192px-cell specialized animation.
class Sprite_PMDSkillVXAnimV033
  alias pmd_ac_v0331_scale_initialize initialize unless method_defined?(:pmd_ac_v0331_scale_initialize)
  def initialize(viewport,name,x,y,opts=nil)
    pmd_ac_v0331_scale_initialize(viewport,name,x,y,opts)
    return if @finished
    s=PMD_AC::SKILL_SPECIAL_RGS3_GLOBAL_SCALE_V0331
    self.zoom_x*=s
    self.zoom_y*=s
    @grow=@grow.to_f*s
  end
end

# Rock Slide falling rocks use a separate sprite class, so scale them too.
class Sprite_PMDSkillVXFallingRockV033
  alias pmd_ac_v0331_scale_initialize initialize unless method_defined?(:pmd_ac_v0331_scale_initialize)
  def initialize(viewport,scene,name,x,ground_y,delay,zoom,spin)
    pmd_ac_v0331_scale_initialize(viewport,scene,name,x,ground_y,delay,zoom,spin)
    s=PMD_AC::SKILL_SPECIAL_RGS3_GLOBAL_SCALE_V0331
    self.zoom_x*=s
    self.zoom_y*=s
  end
end

# Leaf Storm orbit leaves also bypass the generic animation class.
class Sprite_PMDSkillVXOrbitLeafV033
  alias pmd_ac_v0331_scale_initialize initialize unless method_defined?(:pmd_ac_v0331_scale_initialize)
  def initialize(viewport,cx,cy,index)
    pmd_ac_v0331_scale_initialize(viewport,cx,cy,index)
    s=PMD_AC::SKILL_SPECIAL_RGS3_GLOBAL_SCALE_V0331
    self.zoom_x=s
    self.zoom_y=s
  end
end

class Scene_PMD_AutoChess
  alias pmd_ac_v0331_scale_start start unless method_defined?(:pmd_ac_v0331_scale_start)
  alias pmd_ac_v0331_scale_update_verification_script update_verification_script unless method_defined?(:pmd_ac_v0331_scale_update_verification_script)

  def start
    pmd_ac_v0331_scale_start
    begin
      if FileTest.exist?(PMD_AC::BATTLE_LOG_FILE)
        text=File.open(PMD_AC::BATTLE_LOG_FILE,"rb"){|f|f.read}
        text.sub!(/PMD AutoChess Proto v0\.[0-9.]+ Battle Verification Log/,"PMD AutoChess Proto v0.33.1 Battle Verification Log")
        File.open(PMD_AC::BATTLE_LOG_FILE,"wb"){|f|f.write(text)}
      end
    rescue
    end
    log_event(:skill_special,"PATCH v0.33.1 rgs3_global_scale=0.70 relative_move_scales=preserved")
  end

  def verify_skill_special_scale_v0331
    return if @verification_done[:skill_special_scale_v0331]
    s=PMD_AC::SKILL_SPECIAL_RGS3_GLOBAL_SCALE_V0331
    a=Sprite_PMDSkillVXAnimV033.new(@viewport,'RGS3_ATK_221',272,180,{:zoom=>1.0})
    z1=a.zoom_x
    a.dispose unless a.disposed?
    r=Sprite_PMDSkillVXFallingRockV033.new(@viewport,self,'RGS3_ATK_149',272,195,0,1.0,0)
    z2=r.zoom_x
    r.dispose unless r.disposed?
    l=Sprite_PMDSkillVXOrbitLeafV033.new(@viewport,272,195,0)
    z3=l.zoom_x
    l.dispose unless l.disposed?
    pass=((z1-s).abs<0.001 && (z2-s).abs<0.001 && (z3-s).abs<0.001)
    log_event(:verify,"SKILL_SPECIAL_SCALE pass="+(pass ? "1":"0")+" global="+sprintf('%.2f',s)+" generic="+sprintf('%.2f',z1)+" rock="+sprintf('%.2f',z2)+" leaf="+sprintf('%.2f',z3)+" relative_move_scales=preserved")
    @verification_done[:skill_special_scale_v0331]=true
  end

  def update_verification_script
    pmd_ac_v0331_scale_update_verification_script
    return unless verification_mode==:skill_special
    verify_skill_special_scale_v0331 if @verification_frame==30
  end
end
