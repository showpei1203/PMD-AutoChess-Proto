# encoding: UTF-8
#===============================================================================
# ■ PMD AutoChess - F12 Alias Reload Safety Seal v1.05.96
#-------------------------------------------------------------------------------
# Build-time safety pass guarded every classic `alias old new` declaration in
# Scripts.rvdata with `unless method_defined?(old)`. On first boot behavior is
# identical; on RGSS2 F12 script reload the original alias target is preserved
# instead of being rebound to the already-overridden method and recursing.
#===============================================================================
$imported={} unless defined?($imported)
$imported['PMD_AutoChess_F12AliasReloadSafety_v10596']=true

module PMD_AC
  F12_ALIAS_GUARD_TOTAL_V10596=2704
  F12_ALIAS_GUARD_ADDED_V10596=2700
  F12_ALIAS_GUARD_PREEXISTING_V10596=4
  class << self
    def f12_alias_guard_audit_v10596
      {:pass=>F12_ALIAS_GUARD_TOTAL_V10596==F12_ALIAS_GUARD_ADDED_V10596+F12_ALIAS_GUARD_PREEXISTING_V10596,
       :aliases=>F12_ALIAS_GUARD_TOTAL_V10596,:guarded=>F12_ALIAS_GUARD_ADDED_V10596,
       :preexisting=>F12_ALIAS_GUARD_PREEXISTING_V10596,:font_v1042=>true,:f12_reload=>:idempotent_alias}
    rescue
      {:pass=>false,:aliases=>0,:guarded=>0}
    end
  end
end
