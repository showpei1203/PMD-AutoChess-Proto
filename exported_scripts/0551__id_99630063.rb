# encoding: UTF-8
#==============================================================================
# ■ PMD AutoChess - Focus Type Color Authority Fix v1.05.66
#------------------------------------------------------------------------------
# Windows evidence showed type=grass/status charge still using the old yellow
# fallback.  Bypass the fragile respond_to? chain and read the canonical
# v1.03.14 18-type palette directly for all Focus charge visuals.
#==============================================================================
$imported={} unless defined?($imported)
$imported['PMD_AutoChess_FocusTypeColorAuthorityFix_v10566']=true

module PMD_AC
  class << self
    def focus_type_rgb_v10566(type)
      t=type
      t=t.to_sym if t.respond_to?(:to_sym)
      if const_defined?(:TYPE_COLOR_V10314)
        rgb=TYPE_COLOR_V10314[t]
        rgb=TYPE_COLOR_V10314[:normal] if rgb==nil
        return rgb.dup if rgb!=nil
      end
      [168,168,120]
    rescue
      [168,168,120]
    end

    def focus_type_palette_audit_v10566
      keys=[:normal,:fire,:water,:electric,:grass,:ice,:fighting,:poison,:ground,
        :flying,:psychic,:bug,:rock,:ghost,:dragon,:dark,:steel,:fairy]
      bad=[]
      keys.each do |k|
        rgb=focus_type_rgb_v10566(k)
        bad.push(k.to_s) unless rgb!=nil && rgb.size==3
      end
      {:pass=>bad.empty?,:types=>keys.size,:bad=>bad}
    rescue
      {:pass=>false,:types=>0,:bad=>['audit_error']}
    end
  end
end

class Scene_PMD_AutoChess
  def focus_cast_color_v1055(type,alpha=255)
    rgb=PMD_AC.focus_type_rgb_v10566(type)
    Color.new(rgb[0].to_i,rgb[1].to_i,rgb[2].to_i,alpha)
  rescue
    Color.new(168,168,120,alpha)
  end
end
