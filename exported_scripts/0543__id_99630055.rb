# encoding: UTF-8
#==============================================================================
# ■ PMD AutoChess - Type-Colored Status Focus Charge v1.05.58
#------------------------------------------------------------------------------
# Pure-status moves were intentionally set to charge_style=:none in v1.05.20
# to remove the old generic "fireball-like" orbit.  That solved ownership,
# but it also made moves such as String Shot feel as if they had no charge.
# This layer restores a restrained pulse charge for pure status moves while
# keeping v1.05.17 muzzle/projectile/impact suppression intact.
#
# Color authority remains the canonical type palette from v1.03.14:
# Fire=orange/red, Water=blue, Bug=olive green, Psychic=pink, etc.
# No damage / hit timing / Energy / AI / Spatial changes.
#==============================================================================
$imported={} unless defined?($imported)
$imported['PMD_AutoChess_TypeColoredStatusFocusCharge_v10558']=true

module PMD_AC
  STATUS_FOCUS_CHARGE_STYLE_V10558=:pulse
end

class Scene_PMD_AutoChess
  alias pmd_ac_v10558_focus_profile focus_cast_profile_v1055 unless method_defined?(:pmd_ac_v10558_focus_profile)
  alias pmd_ac_v10558_focus_begin focus_cast_begin_v1055 unless method_defined?(:pmd_ac_v10558_focus_begin)

  def focus_cast_profile_v1055(user)
    p=pmd_ac_v10558_focus_profile(user)
    if respond_to?(:focus_content_pure_status_v10520?) && focus_content_pure_status_v10520?(user)
      p[:charge_style]=PMD_AC::STATUS_FOCUS_CHARGE_STYLE_V10558
      p[:status_type_charge_v10558]=true
    end
    p
  rescue
    pmd_ac_v10558_focus_profile(user)
  end

  def focus_cast_begin_v1055(user,target)
    r=pmd_ac_v10558_focus_begin(user,target)
    begin
      if r && @focus_cast_profile_v1055!=nil && @focus_cast_profile_v1055[:status_type_charge_v10558]
        t=@focus_cast_type_v1055 || :normal
        c=focus_cast_color_v1055(t,255)
        log_event(:battle,'BATTLE_STATUS_TYPE_CHARGE_V10558 skill='+(user==nil ? 'NONE':user.skill_name.to_s)+
          ' type='+t.to_s+' style='+@focus_cast_profile_v1055[:charge_style].to_s+
          ' rgb='+c.red.to_i.to_s+','+c.green.to_i.to_s+','+c.blue.to_i.to_s+
          ' generic_muzzle_retained=0 gameplay_change=0')
      end
    rescue
    end
    r
  end
end
