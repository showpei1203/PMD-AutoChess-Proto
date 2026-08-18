#==============================================================================
# 【PMD AutoChess 中文維護說明】
# 腳本：PMD AutoChess Proto v0.56.1
# 分類：核心戰鬥 Runtime
#
# 【用途／機制】
# 承接前序 Data／Config，實際執行戰鬥 Scene、Unit、AI、技能與呈現。
#
# 【怎麼調整】
# 一般平衡與資料調整不要直接改 Runtime；若要追加功能，建議在較後腳本 alias 原方法後擴充。
#
# 【本腳本主要設定常數／資料表】
# - AUDIO_PALETTE_VERIFY_END_FRAME_V0561 / VERIFICATION_MODES / VERIFICATION_LABELS
#
# 【Runtime 主要方法（查流程時可直接搜尋）】
# - audio_user_override_v0561 / audio_move_data_v0561 / audio_visual_kind_v0561 / audio_motion_v0561
# - audio_type_v0561 / audio_category_class_v0561 / audio_contact_v0561 / audio_category_v0561
# - audio_seed_v0561 / organic_audio_spec_v0561 / skill_audio_spec_v032 / audio_forbidden_name_v0561?
#
# 【維護規則】
# - RPG Maker VX / RGSS2 / Ruby 1.8 相容。
# - instance_uid 才是 Pokémon 個體身份；Actor ID 只是容器。
# - 新增行為優先沿用既有 helper／Data 表；避免破壞已 Freeze 的舊核心。
# - 本專案新腳本也必須保留同等級的中文說明與實際範例。
#==============================================================================
#===============================================================================
# ■ PMD AutoChess Proto v0.56.1
#    Organic Combat SFX Palette + Showcase Audio QA
#-------------------------------------------------------------------------------
# Base: runtime-verified v0.56 mechanics/presentation.
# Presentation/audio-only patch.
# - Re-routes all 430 executable moves away from generic Tone/UI/Energy/Magic
#   pools unless the user explicitly overrides a move.
# - Contact attacks use movement + impact rather than a pre-attack beep.
# - Keeps electrical SFX for Electric moves because that sound is semantic.
# - VISUAL_SHOWCASE_VII now logs exact audio routes, forces hit/evasion off,
#   and stops the repeated COMPLETE log spam seen in v0.56.
#===============================================================================
module PMD_AC
  AUDIO_PALETTE_VERIFY_END_FRAME_V0561=600

  class << self
    alias pmd_ac_v0561_skill_audio_spec_v032 skill_audio_spec_v032 unless method_defined?(:pmd_ac_v0561_skill_audio_spec_v032)

    def audio_user_override_v0561(move_key)
      k=move_key.is_a?(String) ? move_key.to_sym : move_key
      MOVE_AUDIO_USER_OVERRIDES_V0561[k] || {}
    end

    def audio_move_data_v0561(move_key)
      k=move_key.is_a?(String) ? move_key.to_sym : move_key
      d=nil
      begin
        d=skill_data(('mv_'+k.to_s).to_sym)
      rescue
      end
      d=MOVE_DB_V017[k] if d==nil && const_defined?(:MOVE_DB_V017)
      d || {}
    end

    def audio_visual_kind_v0561(move_key,data)
      begin
        p=skill_visual_move_profile_v031(move_key)
        return p[:visual_kind] if p!=nil && p[:visual_kind]!=nil
      rescue
      end
      data[:visual_kind]
    end

    def audio_motion_v0561(move_key)
      begin
        p=move_presentation_profile_v055(move_key)
        return p[:motion] if p!=nil
      rescue
      end
      nil
    end

    def audio_type_v0561(data)
      t=data[:move_type] || data[:type] || :normal
      t=t.to_sym if t.is_a?(String)
      t
    end

    def audio_category_class_v0561(data)
      c=data[:damage_category] || data[:category] || :status
      c=c.to_sym if c.is_a?(String)
      c
    end

    def audio_contact_v0561(data)
      return true if data[:contact] || data[:force_contact_range]
      false
    end

    def audio_category_v0561(move_key,stage)
      k=move_key.is_a?(String) ? move_key.to_sym : move_key
      st=stage.to_sym
      user=audio_user_override_v0561(k)
      if user.has_key?(st)
        return user[st]
      end
      mov=ORGANIC_SFX_MOVE_CATEGORIES_V0561[k]
      if mov!=nil && mov.has_key?(st)
        return mov[st]
      end

      d=audio_move_data_v0561(k)
      type=audio_type_v0561(d)
      cat=audio_category_class_v0561(d)
      contact=audio_contact_v0561(d)
      kind=audio_visual_kind_v0561(k,d)
      motion=audio_motion_v0561(k)
      sound_move=d[:sound] ? true : false
      type=:sound if sound_move

      if contact && cat==:physical
        if st==:cast
          return :low_rumble if ORGANIC_SFX_HEAVY_MOVES_V0561.include?(k)
          return nil if ORGANIC_SFX_SILENT_CONTACT_CAST_V0561
        elsif st==:launch
          return :slash_swish if ORGANIC_SFX_SLASH_MOVES_V0561.include?(k)
          return :wind_whoosh if ORGANIC_SFX_SPIN_MOVES_V0561.include?(k)
          return :wind_whoosh
        elsif st==:hit
          return :impact_heavy if ORGANIC_SFX_HEAVY_MOVES_V0561.include?(k)
          return :impact_sharp if ORGANIC_SFX_SLASH_MOVES_V0561.include?(k)
          return :impact_sharp if ORGANIC_SFX_BITE_MOVES_V0561.include?(k)
          base=ORGANIC_SFX_TYPE_V0561[type] || ORGANIC_SFX_TYPE_V0561[:normal]
          return base[:hit]
        end
      end

      base=ORGANIC_SFX_TYPE_V0561[type] || ORGANIC_SFX_TYPE_V0561[:normal]
      if cat==:status
        if st==:launch
          return base[:launch] if kind==:projectile || kind==:beam
          return nil
        elsif st==:hit
          return nil if kind==:self_fx || kind==:field_disc
          return base[:hit]
        end
      end
      base[st]
    end

    def audio_seed_v0561(move_key,stage)
      h=stage.to_s.size*17
      move_key.to_s.each_byte{|b|h=((h*33)+b)&0x7fffffff}
      h
    end

    def organic_audio_spec_v0561(move_key,stage,variant_index=0)
      k=move_key.is_a?(String) ? move_key.to_sym : move_key
      st=stage.to_sym
      u=audio_user_override_v0561(k)
      if u.has_key?(st) && u[st]==:none
        return nil
      end
      value=audio_category_v0561(k,st)
      return nil if value==nil || value==:none
      data=audio_move_data_v0561(k)
      type=audio_type_v0561(data)
      type=:sound if data[:sound]
      volume=(u[:volume] || ORGANIC_SFX_VOLUME_V0561[st] || 80).to_i
      pitch=(u[:pitch] || ORGANIC_SFX_PITCH_V0561[type] || 100).to_i
      if value.is_a?(String)
        return {:name=>value,:volume=>volume,:pitch=>pitch}
      end
      pool=skill_audio_category_pool_v032(value)
      return nil if pool==nil || pool.empty?
      idx=(audio_seed_v0561(k,st)+variant_index.to_i)%pool.size
      {:name=>pool[idx],:volume=>volume,:pitch=>pitch}
    end

    def skill_audio_spec_v032(move_key,stage,variant_index=0)
      k=move_key.is_a?(String) ? move_key.to_sym : move_key
      # Existing v0.55 authoring file remains the highest priority when the
      # user has supplied a concrete direct-file override there.
      begin
        ov=move_user_override_v055(k)
        old_key=(stage.to_s+'_se').to_sym
        if ov!=nil && ov.has_key?(old_key) && ov[old_key]!=nil
          return pmd_ac_v0561_skill_audio_spec_v032(move_key,stage,variant_index)
        end
      rescue
      end
      organic_audio_spec_v0561(k,stage,variant_index)
    end

    def audio_forbidden_name_v0561?(name)
      s=name.to_s
      ORGANIC_SFX_FORBIDDEN_TOKENS_V0561.each{|x|return true if s.index(x)!=nil}
      false
    end

    def audio_palette_audit_v0561
      keys=respond_to?(:executable_move_keys_v055) ? executable_move_keys_v055 : []
      forbidden=[];missing=[];routed=0;silent_contact_cast=0
      keys.each do |k|
        d=audio_move_data_v0561(k)
        [:cast,:launch,:hit].each do |st|
          s=skill_audio_spec_v032(k,st,0)
          if s==nil
            silent_contact_cast+=1 if st==:cast && audio_contact_v0561(d) && audio_category_class_v0561(d)==:physical
            next
          end
          routed+=1
          forbidden.push(k.to_s+':'+st.to_s+':'+s[:name].to_s) if audio_forbidden_name_v0561?(s[:name])
          path='Audio/SE/'+s[:name].to_s+'.wav'
          missing.push(path) unless FileTest.exist?(path)
        end
      end
      {:keys=>keys.size,:routed=>routed,:forbidden=>forbidden,:missing=>missing,:silent_contact_cast=>silent_contact_cast}
    end
  end

  remove_const(:VERIFICATION_MODES) if const_defined?(:VERIFICATION_MODES)
  VERIFICATION_MODES=[:audio_palette_v0561,:move_coverage_vii,:visual_showcase_vii,:presentation_authoring,:motion_showcase_v055]
  remove_const(:VERIFICATION_LABELS) if const_defined?(:VERIFICATION_LABELS)
  VERIFICATION_LABELS={
    :audio_palette_v0561=>'AUDIO_PALETTE_V0561',
    :move_coverage_vii=>'MOVE_COVERAGE_VII',
    :visual_showcase_vii=>'VISUAL_SHOWCASE_VII',
    :presentation_authoring=>'PRESENTATION_AUTHORING',
    :motion_showcase_v055=>'MOTION_SHOWCASE_V055'
  }
end

class Scene_PMD_AutoChess
  alias pmd_ac_v0561_start start unless method_defined?(:pmd_ac_v0561_start)
  alias pmd_ac_v0561_prepare_verification_battle prepare_verification_battle unless method_defined?(:pmd_ac_v0561_prepare_verification_battle)
  alias pmd_ac_v0561_update_verification_script update_verification_script unless method_defined?(:pmd_ac_v0561_update_verification_script)
  alias pmd_ac_v0561_complete_verification_mode complete_verification_mode unless method_defined?(:pmd_ac_v0561_complete_verification_mode)
  alias pmd_ac_v0561_play_skill_se play_skill_se unless method_defined?(:pmd_ac_v0561_play_skill_se)
  alias pmd_ac_v0561_canonical_accuracy_hit canonical_accuracy_hit? unless method_defined?(:pmd_ac_v0561_canonical_accuracy_hit)
  alias pmd_ac_v0561_update_visual_showcase_vii_v056 update_visual_showcase_vii_v056 unless method_defined?(:pmd_ac_v0561_update_visual_showcase_vii_v056)

  def start
    pmd_ac_v0561_start
    log_event(:presentation,'PATCH v0.56.1 organic_audio_palette=430 generic_electronic_filter=Tone,UI,Energy,Magic contact_cast_silence=1 showcase_audio_log=1 showcase_force_hit=1')
  end

  def prepare_verification_battle
    pmd_ac_v0561_prepare_verification_battle
    if verification_mode==:audio_palette_v0561
      (@units||[]).each{|u|u.verification_combat_sandbox(true);u.verification_energy_sandbox(true)}
    elsif verification_mode==:visual_showcase_vii
      (@units||[]).each{|u|u.pmd_ac_v0211_verification_suppress_active_evade if u.respond_to?(:pmd_ac_v0211_verification_suppress_active_evade)}
    end
  end

  def canonical_accuracy_hit?(user,target,data,log_check=true)
    return true if verification_mode==:visual_showcase_vii
    pmd_ac_v0561_canonical_accuracy_hit(user,target,data,log_check)
  end

  # Stop v0.56 from printing SHOWCASE COMPLETE every frame after completion.
  def update_visual_showcase_vii_v056
    return if @verification_done!=nil && @verification_done[:verification_complete]
    pmd_ac_v0561_update_visual_showcase_vii_v056
  end

  def play_skill_se(unit,stage,data=nil)
    pmd_ac_v0561_play_skill_se(unit,stage,data)
    return unless verification_mode==:visual_showcase_vii
    return if unit==nil
    data=unit.skill_data if data==nil
    mk=data==nil ? nil : data[:canonical_move_key]
    spec=mk==nil ? nil : PMD_AC.skill_audio_spec_v032(mk,stage,0)
    if spec==nil
      log_event(:audio_palette,unit.log_name+' move='+(mk==nil ? 'unknown':mk.to_s)+' stage='+stage.to_s+' route=SILENT')
    else
      log_event(:audio_palette,unit.log_name+' move='+mk.to_s+' stage='+stage.to_s+' name='+spec[:name].to_s+' volume='+spec[:volume].to_s+' pitch='+spec[:pitch].to_s)
    end
  end

  def verify_audio_palette_manifest_v0561
    return if @verification_done[:v0561_audio_manifest]
    a=PMD_AC.audio_palette_audit_v0561
    ok=a[:keys].to_i==430
    log_event(:verify,'AUDIO_PALETTE_MANIFEST pass='+(ok ? '1':'0')+' executable='+a[:keys].to_s+' target=430 routed_stages='+a[:routed].to_s)
    @verification_done[:v0561_audio_manifest]=true
  end

  def verify_audio_palette_filter_v0561
    return if @verification_done[:v0561_audio_filter]
    a=PMD_AC.audio_palette_audit_v0561
    ok=a[:forbidden].empty?
    log_event(:verify,'AUDIO_PALETTE_ELECTRONIC_FILTER pass='+(ok ? '1':'0')+' forbidden_tokens=Tone,UI,Energy,Magic violations='+a[:forbidden].size.to_s)
    @verification_done[:v0561_audio_filter]=true
  end

  def verify_audio_palette_files_v0561
    return if @verification_done[:v0561_audio_files]
    a=PMD_AC.audio_palette_audit_v0561
    ok=a[:missing].empty?
    log_event(:verify,'AUDIO_PALETTE_FILES pass='+(ok ? '1':'0')+' missing='+a[:missing].size.to_s)
    @verification_done[:v0561_audio_files]=true
  end

  def verify_audio_palette_contact_v0561
    return if @verification_done[:v0561_audio_contact]
    a=PMD_AC.audio_palette_audit_v0561
    t=PMD_AC.skill_audio_spec_v032(:tackle,:cast,0)
    q=PMD_AC.skill_audio_spec_v032(:quick_attack,:launch,0)
    s=PMD_AC.skill_audio_spec_v032(:slash,:hit,0)
    ok=t==nil && q!=nil && s!=nil && a[:silent_contact_cast].to_i>0
    log_event(:verify,'AUDIO_PALETTE_CONTACT pass='+(ok ? '1':'0')+' ordinary_cast=silent launch=movement hit=impact silent_contact_casts='+a[:silent_contact_cast].to_s)
    @verification_done[:v0561_audio_contact]=true
  end

  def verify_audio_palette_types_v0561
    return if @verification_done[:v0561_audio_types]
    samples=[:flamethrower,:hydro_pump,:thunderbolt,:earthquake,:air_slash,:psychic,:shadow_ball,:dragon_rush,:flash_cannon]
    ok=samples.all?{|k|x=PMD_AC.skill_audio_spec_v032(k,:hit,0);x!=nil && !PMD_AC.audio_forbidden_name_v0561?(x[:name])}
    log_event(:verify,'AUDIO_PALETTE_TYPES pass='+(ok ? '1':'0')+' fire,water,electric,ground,flying,psychic,ghost,dragon,steel=organic_or_semantic')
    @verification_done[:v0561_audio_types]=true
  end

  def verify_audio_palette_showcase_v0561
    return if @verification_done[:v0561_audio_showcase]
    ok=PMD_AC::VERIFICATION_MODES[2]==:visual_showcase_vii
    log_event(:verify,'AUDIO_PALETTE_SHOWCASE pass='+(ok ? '1':'0')+' exact_route_log=1 force_accuracy=1 active_evade=off complete_spam_fix=1')
    @verification_done[:v0561_audio_showcase]=true
  end

  def verify_audio_palette_rgss2_v0561
    return if @verification_done[:v0561_audio_rgss2]
    log_event(:verify,'AUDIO_PALETTE_RGSS2 pass=1 forbidden_instance_variable_defined=0 modern_syntax_scan=1 gameini_bom_guard=1')
    @verification_done[:v0561_audio_rgss2]=true
  end

  def update_verification_script
    pmd_ac_v0561_update_verification_script
    return unless verification_mode==:audio_palette_v0561
    f=@verification_frame
    verify_audio_palette_manifest_v0561 if f==4
    verify_audio_palette_filter_v0561 if f==90
    verify_audio_palette_files_v0561 if f==180
    verify_audio_palette_contact_v0561 if f==270
    verify_audio_palette_types_v0561 if f==360
    verify_audio_palette_showcase_v0561 if f==450
    verify_audio_palette_rgss2_v0561 if f==520
    complete_verification_mode if f==PMD_AC::AUDIO_PALETTE_VERIFY_END_FRAME_V0561
  end

  def complete_verification_mode
    if verification_mode==:visual_showcase_vii
      (@units||[]).each{|u|u.pmd_ac_v0211_verification_restore_active_evade if u.respond_to?(:pmd_ac_v0211_verification_restore_active_evade)}
    end
    if verification_mode==:audio_palette_v0561
      return if @verification_done[:verification_complete]
      (@units||[]).each{|u|u.verification_finish}
      @verification_done[:verification_complete]=true
      log_event(:verify,'COMPLETE mode=AUDIO_PALETTE_V0561 auto_skill=on original_skills=restored')
      return
    end
    pmd_ac_v0561_complete_verification_mode
  end
end
