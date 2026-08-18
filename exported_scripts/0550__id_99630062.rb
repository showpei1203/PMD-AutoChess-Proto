# encoding: UTF-8
#==============================================================================
# ■ PMD AutoChess - Supply / Viewport Lifecycle Compatibility Seal v1.05.65
#------------------------------------------------------------------------------
# Fixes RGSS2 Viewport cleanup on Supply Scene ESC and seals the same legacy
# cleanup pattern in native weather.  VX Viewport in the user's runtime does not
# implement disposed?, so Viewport is disposed directly once and nulled.
#==============================================================================
$imported={} unless defined?($imported)
$imported['PMD_AutoChess_SupplyViewportLifecycleSeal_v10565']=true

module PMD_AC
  SUPPLY_VIEWPORT_LIFECYCLE_VERSION_V10565='1.05.65'
  class << self
    def supply_viewport_lifecycle_seal_v10565?
      true
    end
  end
end

class Scene_PMDSupplyInventoryV099 < Scene_Base
  # Full trailing override: do not call the v0.99 terminate body because it uses
  # Viewport#disposed?, which does not exist in this RGSS2 runtime.
  def terminate
    panel=@panel
    @panel=nil
    if panel!=nil
      begin
        panel.dispose unless panel.disposed?
      rescue
        begin;panel.dispose;rescue;end
      end
    end
    vp=@viewport
    @viewport=nil
    if vp!=nil
      begin
        vp.dispose
      rescue
      end
    end
    super
  end
end

class Scene_PMD_AutoChess
  # Legacy v0.74.3 weather cleanup swallowed the missing Viewport#disposed?
  # exception, leaking the viewport.  Keep behavior identical, only seal cleanup.
  def dispose_native_weather_core_v0743
    core=@native_weather_core_v0743
    @native_weather_core_v0743=nil
    if core!=nil
      begin;core.dispose;rescue;end
    end
    vp=@native_weather_viewport_v0743
    @native_weather_viewport_v0743=nil
    if vp!=nil
      begin;vp.dispose;rescue;end
    end
  end
end
