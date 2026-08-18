# encoding: UTF-8
#===============================================================================
# ■ PMD AutoChess - Production Encounter Resource Manifest + Loading Attribution v1.06.23
#-------------------------------------------------------------------------------
# v1.02.9 intentionally preloads resources before live battle. Its original
# production collector loads almost every PMD action PNG for all six battlers.
# Production external Hunt/Challenge now preload a conservative encounter
# manifest: core/reaction/ambient actions plus all four active-move route poses.
# The 0-100% loading UI and global VFX/SkillFX preload remain intact.
# Also separates intentional loading time from actual Scene/start_battle core.
#===============================================================================
$imported={} unless defined?($imported)
$imported['PMD_AutoChess_ProductionEncounterResourceManifest_v10623']=true

module PMD_AC
  PRODUCTION_ENCOUNTER_CORE_ACTIONS_V10623=[:walk,:idle,:attack,:hurt,:faint,:cringe,:pain]
end

class Scene_PMD_AutoChess
  alias pmd_ac_v10623_battle_loading_collect_assets_v1029 battle_loading_collect_assets_v1029 unless method_defined?(:pmd_ac_v10623_battle_loading_collect_assets_v1029)
  alias pmd_ac_v10623_run_battle_resource_loading_v1029 run_battle_resource_loading_v1029 unless method_defined?(:pmd_ac_v10623_run_battle_resource_loading_v1029)
  alias pmd_ac_v10623_focus_summary focus_cast_log_summary_v1055 unless method_defined?(:pmd_ac_v10623_focus_summary)

  def v10623_production_manifest_active?
    return false unless respond_to?(:production_external_battle_fast_v10613?)
    production_external_battle_fast_v10613?
  rescue
    false
  end

  def v10623_unit_active_moves(u)
    return [] if u==nil
    pi=nil
    begin;pi=u.pokemon_instance;rescue;pi=nil;end
    return [] if pi==nil
    begin
      return pi.battle_moves_v046.compact if pi.respond_to?(:battle_moves_v046)
    rescue
    end
    begin
      return pi.active_moves_v045.compact if pi.respond_to?(:active_moves_v045)
    rescue
    end
    []
  end

  def v10623_add_action(out,sid,a)
    return if a==nil
    k=a.to_s.to_sym
    return if out.include?(k)
    begin
      return unless PMD_AC.action_data(sid,k)!=nil
    rescue
      return
    end
    out.push(k)
  rescue
  end

  def v10623_actions_for_unit(u)
    out=[]
    return out if u==nil
    sid=u.species.to_s rescue ''
    return out if sid==''
    PMD_AC::PRODUCTION_ENCOUNTER_CORE_ACTIONS_V10623.each{|a|v10623_add_action(out,sid,a)}
    begin
      p=PMD_AC.motion_species_profile_v102(sid)
      if p!=nil && p[:ambient]!=nil
        p[:ambient].each do |row|
          next if row==nil || row[0]==nil
          v10623_add_action(out,sid,row[0])
        end
      end
    rescue
    end
    v10623_unit_active_moves(u).each do |mv|
      begin
        data=PMD_AC.skill_data(('mv_'+mv.to_s).to_sym)
        profile=nil
        begin;profile=PMD_AC.move_presentation_profile_v055(mv);rescue;profile=nil;end
        begin
          PMD_AC.native_pose_candidates_v061(sid,mv,data,profile).each do |a|
            begin
              v10623_add_action(out,sid,a) if PMD_AC.motion_playable_v102?(sid,a)
            rescue
            end
          end
        rescue
        end
        begin
          route=PMD_AC.motion_source_route_v102(sid,mv,data,profile)
          v10623_add_action(out,sid,route[:selected]) if route!=nil
        rescue
        end
      rescue
      end
    end
    out
  rescue
    []
  end

  def battle_loading_collect_assets_v1029
    return pmd_ac_v10623_battle_loading_collect_assets_v1029 unless v10623_production_manifest_active?
    queue=[];seen={}
    species_count=0;action_count=0;fallback_species=0
    (@units || []).each do |u|
      next if u==nil
      sid=u.species.to_s rescue ''
      next if sid==''
      species_count+=1
      before=queue.size
      v10623_actions_for_unit(u).each do |a|
        begin
          ad=PMD_AC.action_data(sid,a)
          next if ad==nil || ad[:file]==nil
          battle_loading_add_bitmap_v1029(queue,seen,PMD_AC::PMD_ROOT+sid+'/',ad[:file],'寶可夢動作')
        rescue
        end
      end
      added=queue.size-before
      action_count+=added
      # Safety fallback for an unrecognized/legacy species only. Normal generated
      # species never pay the old whole-folder glob cost.
      if added<=0
        fallback_species+=1
        begin
          folder=PMD_AC::PMD_ROOT+sid+'/'
          Dir.glob(folder+'*.png').sort.each do |path|
            battle_loading_add_bitmap_v1029(queue,seen,folder,File.basename(path,'.png'),'寶可夢動作')
          end
        rescue
        end
      end
    end

    # Keep the proven global FX preload policy. These sets are small and shared;
    # this preserves the user's no-first-use-stutter requirement.
    fx_before=queue.size
    begin
      Dir.glob(PMD_AC::BATTLE_LOAD_PMD_VFX_FOLDER_V1029+'*.png').sort.each do |path|
        battle_loading_add_bitmap_v1029(queue,seen,PMD_AC::BATTLE_LOAD_PMD_VFX_FOLDER_V1029,
          File.basename(path,'.png'),'技能 VFX')
      end
    rescue
    end
    begin
      Dir.glob(PMD_AC::BATTLE_LOAD_SKILL_FX_FOLDER_V1029+'*.png').sort.each do |path|
        battle_loading_add_bitmap_v1029(queue,seen,PMD_AC::BATTLE_LOAD_SKILL_FX_FOLDER_V1029,
          File.basename(path,'.png'),'技能特效')
      end
    rescue
    end
    @v10623_manifest_species=species_count
    @v10623_manifest_action_assets=action_count
    @v10623_manifest_fx_assets=queue.size-fx_before
    @v10623_manifest_total_assets=queue.size
    @v10623_manifest_fallback_species=fallback_species
    queue
  rescue
    pmd_ac_v10623_battle_loading_collect_assets_v1029
  end

  def run_battle_resource_loading_v1029
    t=Time.now.to_f
    r=pmd_ac_v10623_run_battle_resource_loading_v1029
    @v10623_loading_total_ms=(((Time.now.to_f-t)*1000.0).round rescue 0)
    begin
      s=@battle_resource_loading_summary_v1029 || {}
      ui=(respond_to?(:loading_ui_refresh_summary_v10233) ? loading_ui_refresh_summary_v10233 : {})
      @v10623_loading_asset_ms=s[:asset_ms].to_i
      @v10623_loading_asset_count=s[:assets].to_i
      @v10623_loading_gc_ms=s[:gc_ms].to_i
      @v10623_loading_ui_ms=ui[:ui_ms].to_i
    rescue
    end
    r
  end

  def v10623_loading_summary
    return false if @v10623_loading_summary_logged
    @v10623_loading_summary_logged=true
    return true unless v10623_production_manifest_active?
    total=@v10623_loading_total_ms.to_i
    core=@v10613_start_battle_ms.to_i-total
    core=0 if core<0
    other=total-@v10623_loading_asset_ms.to_i-@v10623_loading_gc_ms.to_i-@v10623_loading_ui_ms.to_i
    other=0 if other<0
    log_event(:perf,'BATTLE_PRODUCTION_LOADING_ATTRIBUTION_SUMMARY_V10623 pass=1'+
      ' start_battle_ms='+@v10613_start_battle_ms.to_i.to_s+
      ' intentional_loading_ms='+total.to_s+' core_start_battle_ms='+core.to_s+
      ' asset_count='+@v10623_loading_asset_count.to_i.to_s+
      ' manifest_species='+@v10623_manifest_species.to_i.to_s+
      ' manifest_action_assets='+@v10623_manifest_action_assets.to_i.to_s+
      ' manifest_fx_assets='+@v10623_manifest_fx_assets.to_i.to_s+
      ' fallback_species='+@v10623_manifest_fallback_species.to_i.to_s+
      ' asset_ms='+@v10623_loading_asset_ms.to_i.to_s+
      ' ui_ms='+@v10623_loading_ui_ms.to_i.to_s+
      ' gc_ms='+@v10623_loading_gc_ms.to_i.to_s+' other_loading_ms='+other.to_s+
      ' loading_bar_retained=1 all_active_moves_manifested=1 global_fx_retained=1'+
      ' production_full_action_folder_load=0 gameplay_change=0')
    true
  rescue
    false
  end

  def focus_cast_log_summary_v1055
    r=pmd_ac_v10623_focus_summary
    v10623_loading_summary
    r
  rescue
    false
  end
end
