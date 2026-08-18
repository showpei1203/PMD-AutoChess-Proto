#==============================================================================
# 【PMD AutoChess 中文維護說明】
# 腳本：PMD AutoChess Proto v0.63
# 分類：核心戰鬥 Runtime
#
# 【用途／機制】
# 承接前序 Data／Config，實際執行戰鬥 Scene、Unit、AI、技能與呈現。
#
# 【怎麼調整】
# 一般平衡與資料調整不要直接改 Runtime；若要追加功能，建議在較後腳本 alias 原方法後擴充。
#
# 【本腳本主要設定常數／資料表】
# - PATCH_VERSION_V063 / VERIFICATION_MODES / VERIFICATION_LABELS
#
# 【Runtime 主要方法（查流程時可直接搜尋）】
# - semantic_audit_class_v063 / semantic_audit_specialized_poses_v063 / semantic_audit_resolution_tier_v063 / semantic_audit_summary_v063
# - semantic_audit_class_stats_match_v063? / start / prepare_verification_battle / verify_native_semantic_map_v063
# - verify_native_semantic_resolution_v063 / verify_native_semantic_classes_v063 / verify_native_semantic_carry_v063 / update_native_semantic_audit_v063
#
# 【維護規則】
# - RPG Maker VX / RGSS2 / Ruby 1.8 相容。
# - instance_uid 才是 Pokémon 個體身份；Actor ID 只是容器。
# - 新增行為優先沿用既有 helper／Data 表；避免破壞已 Freeze 的舊核心。
# - 本專案新腳本也必須保留同等級的中文說明與實際範例。
#==============================================================================
#==============================================================================
# PMD AutoChess Proto v0.63
# Native Pose Semantic Audit - 526 executable moves / 7005 learnset references
#------------------------------------------------------------------------------
# Additive diagnostic patch on v0.62.
#
# This release DOES NOT change the accepted v0.62 pose router, v0.60.2
# multi-hit packet choreography, Beam/Projectile/Impact/Target-FX anchors, or
# Organic Combat SFX palette. It classifies every executable move and measures
# how often the compiled PMDCollab database can satisfy a specialized native
# semantic pose, a compiler alias, or only the generic fallback backbone.
#==============================================================================
module PMD_AC
  PATCH_VERSION_V063 = "0.63"

  class << self
    def semantic_audit_class_v063(move_key)
      k = move_key
      k = k.to_sym if k != nil && k.respond_to?(:to_sym)
      NATIVE_SEMANTIC_CLASS_MAP_V063[k]
    end

    def semantic_audit_specialized_poses_v063(move_key)
      c = semantic_audit_class_v063(move_key)
      return [] if c == nil
      NATIVE_SEMANTIC_CLASS_POSES_V063[c] || []
    end

    def semantic_audit_resolution_tier_v063(species, move_key)
      poses = semantic_audit_specialized_poses_v063(move_key)
      return :fallback if poses == nil || poses.empty?
      alias_found = false
      poses.each do |pose|
        d = compiled_direct_action_v061(species, pose)
        next if d == nil
        if d[:alias_of] == nil
          return :native
        else
          alias_found = true
        end
      end
      alias_found ? :alias : :fallback
    end

    def semantic_audit_summary_v063(force=false)
      if !force && @semantic_audit_summary_v063 != nil
        return @semantic_audit_summary_v063
      end
      out = {
        :moves=>NATIVE_SEMANTIC_CLASS_MAP_V063.size,
        :classes=>0,:refs=>0,:native=>0,:alias=>0,:fallback=>0,
        :unknown_move_db=>0,:unclassified_refs=>0,:class_stats=>{}
      }
      classes = {}
      NATIVE_SEMANTIC_CLASS_MAP_V063.each do |k,c|
        classes[c] = true
        if defined?(MOVE_DB_V017) && MOVE_DB_V017[k] == nil
          out[:unknown_move_db] += 1
        end
        out[:class_stats][c] = {:moves=>0,:refs=>0,:native=>0,:alias=>0,:fallback=>0} if out[:class_stats][c] == nil
        out[:class_stats][c][:moves] += 1
      end
      out[:classes] = classes.size

      if defined?(SPECIES_DB_V016)
        SPECIES_DB_V016.each do |species_key,sp|
          species = sp[:pmd_species]
          (sp[:learnset] || []).each do |entry|
            k = entry[:move]
            c = NATIVE_SEMANTIC_CLASS_MAP_V063[k]
            if c == nil
              out[:unclassified_refs] += 1
              next
            end
            out[:refs] += 1
            tier = semantic_audit_resolution_tier_v063(species, k)
            out[tier] += 1
            cs = out[:class_stats][c]
            cs[:refs] += 1
            cs[tier] += 1
          end
        end
      end
      @semantic_audit_summary_v063 = out
      out
    end

    def semantic_audit_class_stats_match_v063?(actual)
      expected = NATIVE_SEMANTIC_CLASS_STATS_V063
      return false unless actual != nil && actual.size == expected.size
      expected.each do |c,e|
        a = actual[c]
        return false if a == nil
        [:moves,:refs,:native,:alias,:fallback].each do |k|
          return false unless a[k].to_i == e[k].to_i
        end
      end
      true
    end
  end

  remove_const(:VERIFICATION_MODES) if const_defined?(:VERIFICATION_MODES)
  VERIFICATION_MODES = [
    :native_semantic_audit_v063,
    :native_semantic_v062,
    :native_combo_preview_v062,
    :compiled_pose_runtime_v061,
    :multi_choreo_v060,
    :native_pose_showcase_v060,
    :presentation_fix_v0591,
    :move_coverage_x
  ]
  remove_const(:VERIFICATION_LABELS) if const_defined?(:VERIFICATION_LABELS)
  VERIFICATION_LABELS = {
    :native_semantic_audit_v063 => 'NATIVE_SEMANTIC_AUDIT_V063',
    :native_semantic_v062 => 'NATIVE_SEMANTIC_V062',
    :native_combo_preview_v062 => 'NATIVE_COMBO_PREVIEW_V062',
    :compiled_pose_runtime_v061 => 'COMPILED_POSE_RUNTIME_V061',
    :multi_choreo_v060 => 'MULTI_CHOREO_V060',
    :native_pose_showcase_v060 => 'NATIVE_POSE_SHOWCASE_V060',
    :presentation_fix_v0591 => 'PRESENTATION_FIX_V0591',
    :move_coverage_x => 'MOVE_COVERAGE_X'
  }
end

class Scene_PMD_AutoChess
  alias pmd_ac_v063_start start unless method_defined?(:pmd_ac_v063_start)
  alias pmd_ac_v063_prepare_verification_battle prepare_verification_battle unless method_defined?(:pmd_ac_v063_prepare_verification_battle)
  alias pmd_ac_v063_update_verification_script update_verification_script unless method_defined?(:pmd_ac_v063_update_verification_script)

  def start
    pmd_ac_v063_start
    begin
      if FileTest.exist?(PMD_AC::BATTLE_LOG_FILE)
        t = File.open(PMD_AC::BATTLE_LOG_FILE, 'rb') { |f| f.read }
        t.sub!(/PMD AutoChess Proto v0\.62 Battle Verification Log/,
               'PMD AutoChess Proto v0.63 Battle Verification Log')
        File.open(PMD_AC::BATTLE_LOG_FILE, 'wb') { |f| f.write(t) }
      end
    rescue
    end
    log_event(:presentation,
      'PATCH v0.63 semantic_audit=526_moves learnset_refs=7005 '+
      'runtime_router=v0.62_unchanged audit_only=1 '+
      'combo_packet_driver=v0.60.2_backstep presentation_anchors=unchanged '+
      'organic_sfx=v0.56.1')
  end

  def prepare_verification_battle
    pmd_ac_v063_prepare_verification_battle
    return unless verification_mode == :native_semantic_audit_v063
    (@units || []).each do |u|
      u.verification_combat_sandbox(true)
      u.verification_energy_sandbox(true)
      if u.respond_to?(:pmd_ac_v0211_verification_suppress_active_evade)
        u.pmd_ac_v0211_verification_suppress_active_evade
      end
    end
    PMD_AC.semantic_audit_summary_v063(true)
    log_event(:showcase,
      'START mode=NATIVE_SEMANTIC_AUDIT_V063 executable_moves=526 '+
      'learnset_refs=7005 diagnostic_only=1 runtime_router=v0.62_unchanged '+
      'pokemon_resume_after_final_assert=1')
  end

  def verify_native_semantic_map_v063
    return if @verification_done[:v063_map]
    s = PMD_AC.semantic_audit_summary_v063
    exp = PMD_AC::NATIVE_SEMANTIC_AUDIT_SCOPE_V063
    ok = s[:moves].to_i == exp[:executable_moves].to_i &&
         s[:classes].to_i == PMD_AC::NATIVE_SEMANTIC_AUDIT_EXPECTED_V063[:classes].to_i &&
         s[:refs].to_i == exp[:learnset_refs].to_i &&
         s[:unknown_move_db].to_i == 0 && s[:unclassified_refs].to_i == 0
    log_event(:verify,
      'NATIVE_SEMANTIC_AUDIT_V063 pass='+(ok ? '1':'0')+
      ' executable_moves='+s[:moves].to_i.to_s+
      ' classified='+PMD_AC::NATIVE_SEMANTIC_CLASS_MAP_V063.size.to_s+
      ' classes='+s[:classes].to_i.to_s+
      ' learnset_refs='+s[:refs].to_i.to_s+
      ' unknown_move_db='+s[:unknown_move_db].to_i.to_s+
      ' unclassified_refs='+s[:unclassified_refs].to_i.to_s)
    @verification_done[:v063_map] = true
  end

  def verify_native_semantic_resolution_v063
    return if @verification_done[:v063_resolution]
    s = PMD_AC.semantic_audit_summary_v063
    e = PMD_AC::NATIVE_SEMANTIC_AUDIT_EXPECTED_V063
    ok = s[:native].to_i == e[:native].to_i &&
         s[:alias].to_i == e[:alias].to_i &&
         s[:fallback].to_i == e[:fallback].to_i &&
         s[:native].to_i+s[:alias].to_i+s[:fallback].to_i == s[:refs].to_i
    denom = [s[:refs].to_i,1].max.to_f
    np = s[:native].to_f*100.0/denom
    ap = s[:alias].to_f*100.0/denom
    fp = s[:fallback].to_f*100.0/denom
    log_event(:verify,
      'NATIVE_SEMANTIC_RESOLUTION_V063 pass='+(ok ? '1':'0')+
      ' native='+s[:native].to_i.to_s+'/'+sprintf('%.2f',np)+'%'+
      ' alias='+s[:alias].to_i.to_s+'/'+sprintf('%.2f',ap)+'%'+
      ' fallback='+s[:fallback].to_i.to_s+'/'+sprintf('%.2f',fp)+'%'+
      ' denominator='+s[:refs].to_i.to_s+' basis=species_learnset_reference')
    @verification_done[:v063_resolution] = true
  end

  def verify_native_semantic_classes_v063
    return if @verification_done[:v063_classes]
    s = PMD_AC.semantic_audit_summary_v063
    ok = PMD_AC.semantic_audit_class_stats_match_v063?(s[:class_stats])
    top = [:ranged,:target_support,:generic_contact,:self_support,:sound]
    parts = []
    top.each do |c|
      a = s[:class_stats][c] || {}
      parts.push(c.to_s+'='+a[:refs].to_i.to_s+
                 '/n'+a[:native].to_i.to_s+
                 '/a'+a[:alias].to_i.to_s+
                 '/f'+a[:fallback].to_i.to_s)
    end
    log_event(:verify,
      'NATIVE_SEMANTIC_CLASS_STATS_V063 pass='+(ok ? '1':'0')+
      ' classes='+s[:classes].to_i.to_s+' '+parts.join(' ')+
      ' full_table=PMD_NATIVE_SEMANTIC_AUDIT_v0.63.txt')
    @verification_done[:v063_classes] = true
  end

  def verify_native_semantic_carry_v063
    return if @verification_done[:v063_carry]
    c = PMD_AC.compiled_data_status_v061
    ok = c[:loaded] && c[:species].to_i == 494 && c[:native].to_i == 9507 &&
         c[:aliases].to_i == 1077
    log_event(:verify,
      'NATIVE_SEMANTIC_CARRY_V063 pass='+(ok ? '1':'0')+
      ' compiled_species='+c[:species].to_i.to_s+
      ' native_actions='+c[:native].to_i.to_s+
      ' compatibility_aliases='+c[:aliases].to_i.to_s+
      ' executable_moves=526 learnset=7005/7005 '+
      ' router=v0.62_unchanged combo_packet_driver=v0.60.2_backstep '+
      ' beam_projectile_impact_targetfx=unchanged')
    @verification_done[:v063_carry] = true
  end

  def update_native_semantic_audit_v063
    return if @verification_done[:verification_complete]
    @verification_frame += 1
    f = @verification_frame
    verify_native_semantic_map_v063 if f >= 2
    verify_native_semantic_resolution_v063 if f >= 4
    verify_native_semantic_classes_v063 if f >= 6
    verify_native_semantic_router_v062 if f >= 8
    verify_native_semantic_assets_v062 if f >= 10
    verify_native_combo_analyzer_v062 if f >= 12
    verify_echoed_voice_v062 if f >= 14
    verify_native_semantic_carry_v062 if f >= 16
    verify_native_semantic_carry_v063 if f >= 18
    complete_verification_mode if f >= 20
  end

  def update_verification_script
    if verification_mode == :native_semantic_audit_v063
      update_native_semantic_audit_v063
      return
    end
    pmd_ac_v063_update_verification_script
  end
end
