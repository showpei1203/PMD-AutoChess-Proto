# encoding: UTF-8
#==============================================================================
# 【PMD AutoChess 中文維護說明】
# 腳本：PMD AutoChess Species Audit Disabled-Form Scope Hotfix v0.99.4.1
# 分類：#0001～#0494 最終 Species Production Audit 審查範圍修正
#
# 【用途】
# 修正 v0.99.4 逐隻審查器把 ruleset_enabled=false 的未啟用 Form Ability
# 誤判為目前 Production Core Error 的問題。這些 Form 仍保留在 702 Form 資料庫中，
# 供未來世代／Mega／Regional／Primal 等內容擴充，但不屬於目前啟用規則集。
#
# 【問題來源】
# v0.99.4 原審查會對 702 個 Form 全部要求 ability_data() 有 Runtime。
# 實機結果顯示 20 個 Species、21 個停用 Form 使用目前未啟用的 Form Ability，
# 因而造成 SPECIES_AUDIT_CORE / ABILITY / EVOLUTION_FORM 三組假失敗。
#
# 【正式規則】
# 1. 所有 Form（啟用與停用）仍必須有合法六維 base_stats 與 1～2 個 types。
# 2. ruleset_enabled=true 的 Form，若指定 Ability，必須具有可執行 Runtime。
# 3. ruleset_enabled=false 的 Form，Ability Runtime 缺口記為 Design Warning／Deferred，
#    不列入目前 Core Error。
# 4. Species 正式 Ability Slots 仍維持 1193/1193，完全由 v0.97 Frozen Runtime 驗證。
# 5. 本補丁不新增 Ability、不啟用任何停用 Form、不改戰鬥數值與 Form 切換規則。
#
# 【主要設定／可調參數】
# 無平衡參數。本補丁只修正 Audit Scope；不應透過此處啟用 Form。
# Form 是否正式啟用，仍以 FORMS_DB_V016[species][form][:ruleset_enabled] 為準。
#
# 【事件／腳本呼叫方式】
# 不需事件呼叫。沿用 v0.99.4 驗證：
#   NORMAL → S 一次 → SPECIES_PRODUCTION_AUDIT_V0994 → Shift
#
# 【預期額外 Marker】
# SPECIES_AUDIT_SCOPE_HOTFIX_V09941 pass=1
#   deferred_disabled_form_abilities=21
#   deferred_species=20
#   enabled_form_runtime_missing=0
#
# 【實際範例】
# 阿羅拉雷丘、Mega 袋獸、Mega 沙奈朵、原始蓋歐卡等目前 ruleset_enabled=false；
# 它們的未啟用 Form Ability 會保留資料，但不再讓 #0001～#0494 Core Audit 假失敗。
#
# 【維護注意】
# - RPG Maker VX / RGSS2 / Ruby 1.8 相容。
# - 不修改 v0.99.4 舊腳本；本檔以 additive alias 方式追加於 Main 前。
# - 不修改 v0.97 Ability Runtime、v0.77 Evolution、v0.60.2 Damage Packet。
# - 若未來把某 Form 的 ruleset_enabled 改為 true，其 Ability 仍會立即重新進入
#   Core Runtime 檢查，不會被本補丁永久忽略。
#==============================================================================
module PMD_AC
  SPECIES_AUDIT_SCOPE_HOTFIX_V09941 = true

  class << self
    alias pmd_ac_v09941_species_production_row_v0994 species_production_row_v0994 unless method_defined?(:pmd_ac_v09941_species_production_row_v0994)
    def species_production_row_v0994(species_key)
      row = pmd_ac_v09941_species_production_row_v0994(species_key)
      return row if row == nil
      forms = FORMS_DB_V016[species_key] || {}
      cleaned = []
      deferred = []
      (row[:errors] || []).each do |error_text|
        text = error_text.to_s
        if text.index('form:') == 0
          kept = []
          payload = text[5, text.size - 5].to_s
          payload.split(',').each do |token|
            parts = token.split(':', 2)
            form_key = parts[0].to_s.to_sym
            kind = parts[1].to_s
            form = forms[form_key]
            if kind == 'ability' && form != nil && !form[:ruleset_enabled]
              deferred.push([form_key, form[:ability]])
            else
              kept.push(token)
            end
          end
          cleaned.push('form:' + kept.join(',')) unless kept.empty?
        else
          cleaned.push(text)
        end
      end
      row[:errors] = cleaned
      row[:deferred_disabled_form_abilities_v09941] = deferred
      if !deferred.empty? && !(row[:warnings] || []).include?('disabled_form_future_ability')
        row[:warnings] ||= []
        row[:warnings].push('disabled_form_future_ability')
      end
      row
    end

    alias pmd_ac_v09941_species_production_audit_v0994 species_production_audit_v0994 unless method_defined?(:pmd_ac_v09941_species_production_audit_v0994)
    def species_production_audit_v0994
      report = pmd_ac_v09941_species_production_audit_v0994
      deferred_count = 0
      deferred_species = []
      enabled_missing = []
      (report[:rows] || []).each do |row|
        list = row[:deferred_disabled_form_abilities_v09941] || []
        unless list.empty?
          deferred_count += list.size
          deferred_species.push(row[:species_key])
        end
        forms = FORMS_DB_V016[row[:species_key]] || {}
        forms.each do |form_key, form|
          next unless form[:ruleset_enabled]
          ability = form[:ability]
          next if ability == nil
          data = ability_data(ability)
          if data == nil || (data.respond_to?(:empty?) && data.empty?)
            enabled_missing.push([row[:species_key], form_key, ability])
          end
        end
      end
      report[:deferred_disabled_form_ability_count_v09941] = deferred_count
      report[:deferred_disabled_form_species_v09941] = deferred_species.uniq
      report[:enabled_form_runtime_missing_v09941] = enabled_missing
      report
    end

    alias pmd_ac_v09941_species_production_audit_text_v0994 species_production_audit_text_v0994 unless method_defined?(:pmd_ac_v09941_species_production_audit_text_v0994)
    def species_production_audit_text_v0994(report = nil)
      r = report || species_production_audit_v0994
      text = pmd_ac_v09941_species_production_audit_text_v0994(r)
      extra = []
      extra << ''
      extra << 'V0.99.4.1 AUDIT SCOPE HOTFIX'
      extra << 'Disabled Form Ability Runtime deferred: ' + r[:deferred_disabled_form_ability_count_v09941].to_i.to_s
      extra << 'Affected disabled-form Species: ' + (r[:deferred_disabled_form_species_v09941] || []).size.to_s
      extra << 'Enabled Form Ability Runtime missing: ' + (r[:enabled_form_runtime_missing_v09941] || []).size.to_s
      extra << 'Policy: disabled forms retain data but do not fail current Production Core.'
      extra << 'Mechanics changed: NO'
      text + extra.join("\r\n") + "\r\n"
    end
  end
end

class Scene_PMD_AutoChess
  alias pmd_ac_v09941_start start unless method_defined?(:pmd_ac_v09941_start)
  alias pmd_ac_v09941_refresh_header refresh_header unless method_defined?(:pmd_ac_v09941_refresh_header)
  alias pmd_ac_v09941_update_verification_script update_verification_script unless method_defined?(:pmd_ac_v09941_update_verification_script)

  def start
    pmd_ac_v09941_start
    log_event(:species_audit,
      'PATCH v0.99.4.1 disabled_form_scope=deferred ruleset_enabled_only_runtime_gate=1 mechanics_unchanged=1')
    refresh_header
  end

  def refresh_header
    pmd_ac_v09941_refresh_header
    return if @header_sprite == nil || @header_sprite.bitmap == nil
    bmp = @header_sprite.bitmap
    bmp.fill_rect(0, 0, Graphics.width, 28, Color.new(0, 0, 0, 180))
    pmd_ac_v074_font(bmp)
    bmp.font.size = PMD_AC.const_defined?(:UI_HEADER_TITLE_FONT_V086) ? PMD_AC::UI_HEADER_TITLE_FONT_V086 : 20
    bmp.font.bold = true
    bmp.font.color = Color.new(255,255,255)
    bmp.draw_text(16, 1, Graphics.width - 32, 30, 'PMD 自走棋原型 v0.99.4.1', 1)
  end

  def update_verification_script
    pmd_ac_v09941_update_verification_script
    return unless species_production_audit_v0994?
    return if @verification_done == nil
    f = @verification_frame.to_i
    if f >= 12 && !@verification_done[:v09941_scope_hotfix]
      r = species_audit_report_v0994
      deferred = r[:deferred_disabled_form_ability_count_v09941].to_i
      species = (r[:deferred_disabled_form_species_v09941] || []).size
      enabled_missing = (r[:enabled_form_runtime_missing_v09941] || []).size
      pass = deferred == 21 && species == 20 && enabled_missing == 0
      log_species_verify_v0994('SPECIES_AUDIT_SCOPE_HOTFIX_V09941', pass,
        'deferred_disabled_form_abilities=' + deferred.to_s +
        ' deferred_species=' + species.to_s +
        ' enabled_form_runtime_missing=' + enabled_missing.to_s +
        ' disabled_forms=' + r[:disabled_forms].to_i.to_s +
        ' mechanics_unchanged=1')
      @verification_done[:v09941_scope_hotfix] = true
    end
  end
end
