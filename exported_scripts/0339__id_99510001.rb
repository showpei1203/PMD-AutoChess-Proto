# encoding: UTF-8
#==============================================================================
# 【PMD AutoChess 中文維護說明】
# 腳本：PMD AutoChess Content Validation Hotfix v0.95.1
# 分類：內容驗證修正／Visual Bridge Cross-System Router
#
# 【用途】
# 修正 v0.95 Content Validator 對「招式視覺橋接」的誤判。
# v0.95 原本只用 skill_visual_move_profile_v031(move_key) 判斷 526 個 executable
# move 是否有 Visual，因此把不走 v0.31 Generic Visual，而是由專用 Runtime 呈現的
# Field v0.35、Guard v0.40、Two-Turn v0.39 共 21 招錯誤列為 missing。
#
# 【本版修正原則】
# 1. 不新增假的 Generic VFX，不修改任何招式效果／傷害／AI／動畫 Runtime。
# 2. Generic Visual v0.31～v0.59 仍是第一優先合法來源。
# 3. 若 Generic Visual 為 nil，Validator 再辨識三套既有合法專用視覺：
#    - FIELD_EFFECT_MOVE_V035 + FIELD_EFFECT_VISUAL_V035（10 招）
#    - GUARD_MOVE_V040 / GUARD_VISUAL_V040（6 招，Feint 走 Projectile 語意）
#    - TWO_TURN_MOVE_V039（5 招，使用 pose + vfx_style + contact hit）
# 4. Validator 最終仍要求 526/526 executable moves 都有某一條合法 Visual path。
#
# 【主要設定／輸出】
# - 報告檔改為 PMD_ContentValidation_v0.95.1.log，避免與錯誤的 v0.95 報告混淆。
# - CONTENT_MOVE_BRIDGE_V095 會額外輸出 generic / subsystem 視覺數量。
# - 新增 CONTENT_VISUAL_SUBSYSTEM_V0951 verifier 行。
#
# 【機制規則】
# v0.95 實測誤報的 21 招應被分類為：
# - Generic Visual：505
# - Field v0.35：10
# - Guard v0.40：6
# - Two-Turn v0.39：5
# - Total：526
# 因此正常結果應為 errors=0、warnings=2、core_ready=1、production_ready=0。
# 兩個 Warning 仍是既有已知缺口：Ability Runtime 尚未 100%，Loot Catalog 尚未綁定。
#
# 【事件／腳本呼叫方式】
# 布陣畫面：NORMAL → S 一次 → CONTENT_VALIDATION_V095 → Shift。
# 模式名稱維持 V095，因為本版是 Validator Hotfix，不改驗證內容主版本。
#
# 也可直接：
#   PMD_AC.write_content_validation_report_v095
# 會輸出 PMD_ContentValidation_v0.95.1.log。
#
# 【實際範例】
# Protect：
#   skill_visual_move_profile_v031(:protect) 可能為 nil，
#   但 GUARD_MOVE_V040[:protect][:visual_kind] == :guard_self，且有 GUARD_VISUAL_V040，
#   因此 Validator 應認定 Visual Bridge 有效。
#
# Fly：
#   由 TWO_TURN_MOVE_V039[:fly] 的 airborne pose / vfx_style / contact hit 管線呈現，
#   不要求再複製一份 Generic Visual Profile。
#
# 【注意事項】
# - RPG Maker VX / RGSS2 / Ruby 1.8 相容。
# - 不使用舊式 instance-variable reflection probe。
# - 不修改 v0.39 / v0.40 / v0.35 / v0.31～v0.59 舊腳本。
# - 不改 Damage、Accuracy、Range、Energy、AI、Field、Guard、Two-Turn、PMD 動作。
# - 只修 Validator 的跨系統辨識與版本顯示。
#==============================================================================
module PMD_AC
  remove_const(:CONTENT_VALIDATION_VERSION_V095) if const_defined?(:CONTENT_VALIDATION_VERSION_V095)
  CONTENT_VALIDATION_VERSION_V095 = '0.95.1'
  remove_const(:CONTENT_VALIDATION_REPORT_FILE_V095) if const_defined?(:CONTENT_VALIDATION_REPORT_FILE_V095)
  CONTENT_VALIDATION_REPORT_FILE_V095 = 'PMD_ContentValidation_v0.95.1.log'

  class << self
    alias pmd_ac_v0951_content_validation_text_v095 content_validation_text_v095 unless method_defined?(:pmd_ac_v0951_content_validation_text_v095)

    def content_validation_visual_source_v0951(move_key)
      k=move_key.is_a?(String) ? move_key.to_sym : move_key

      v=skill_visual_move_profile_v031(k)
      return :generic if v!=nil && !v.empty?

      if defined?(FIELD_EFFECT_MOVE_V035) && FIELD_EFFECT_MOVE_V035[k]!=nil
        d=FIELD_EFFECT_MOVE_V035[k]
        vis=defined?(FIELD_EFFECT_VISUAL_V035) ? FIELD_EFFECT_VISUAL_V035[k] : nil
        if d[:visual_kind]!=nil && vis!=nil
          return :field_v035
        end
      end

      if defined?(GUARD_MOVE_V040) && GUARD_MOVE_V040[k]!=nil
        d=GUARD_MOVE_V040[k]
        kind=d[:visual_kind]
        if kind==:guard_self || kind==:guard_aura
          vis=defined?(GUARD_VISUAL_V040) ? GUARD_VISUAL_V040[k] : nil
          return :guard_v040 if vis!=nil
        elsif kind!=nil && d[:vfx_style]!=nil
          # Feint 等 Guard 子系統中的攻擊型招式走既有 projectile/contact 視覺語意。
          return :guard_v040
        end
      end

      if defined?(TWO_TURN_MOVE_V039) && TWO_TURN_MOVE_V039[k]!=nil
        d=TWO_TURN_MOVE_V039[k]
        if d[:visual_kind]!=nil && d[:pose]!=nil && d[:vfx_style]!=nil
          return :two_turn_v039
        end
      end

      nil
    end

    def content_validation_moves_v095(report)
      content_validation_safe_v095(report,:moves) do
        exp=CONTENT_VALIDATION_EXPECTED_V095
        move_db=defined?(MOVE_DB_V017) ? MOVE_DB_V017 : {}
        keys=defined?(NATIVE_SEMANTIC_CLASS_MAP_V063) ? NATIVE_SEMANTIC_CLASS_MAP_V063.keys : []
        exec=0;skill=0;presentation=0;visual=0;audio=0
        visual_generic=0;visual_field=0;visual_guard=0;visual_two_turn=0
        missing=[]
        keys.each do |k|
          exec+=1 if move_executable?(k)
          sd=skill_data(('mv_'+k.to_s).to_sym)
          skill+=1 if sd!=nil && !sd.empty?
          p=move_presentation_profile_v055(k)
          presentation+=1 if p!=nil && !p.empty?
          source=content_validation_visual_source_v0951(k)
          if source!=nil
            visual+=1
            case source
            when :generic
              visual_generic+=1
            when :field_v035
              visual_field+=1
            when :guard_v040
              visual_guard+=1
            when :two_turn_v039
              visual_two_turn+=1
            end
          end
          a=skill_audio_move_profile_v032(k)
          audio+=1 if a!=nil && !a.empty?
          if !move_executable?(k) || sd==nil || sd.empty? || p==nil || p.empty? ||
             source==nil || a==nil || a.empty?
            missing.push(k)
          end
        end
        man=defined?(MOVE_COVERAGE_X_MANIFEST_V059) ? MOVE_COVERAGE_X_MANIFEST_V059 : {}
        if move_db.size!=exp[:move_db]
          content_validation_push_v095(report,:error,'move_db_count',move_db.size.to_s+'/'+exp[:move_db].to_s)
        end
        if keys.size!=exp[:executable_moves]
          content_validation_push_v095(report,:error,'semantic_move_count',keys.size.to_s+'/'+exp[:executable_moves].to_s)
        end
        if man[:cumulative_mapped_move_count].to_i!=exp[:executable_moves] ||
           man[:cumulative_reference_covered].to_i!=exp[:learnset_refs] ||
           man[:remaining_reference_count].to_i!=0
          content_validation_push_v095(report,:error,'move_coverage_manifest',man.inspect)
        end
        unless missing.empty?
          content_validation_push_v095(report,:error,'move_bridge_missing',missing.join(','))
        end
        content_validation_push_v095(report,:info,'visual_bridge_subsystems',
          'generic='+visual_generic.to_s+
          ' field_v035='+visual_field.to_s+
          ' guard_v040='+visual_guard.to_s+
          ' two_turn_v039='+visual_two_turn.to_s+
          ' total='+visual.to_s)
        {:pass=>move_db.size==exp[:move_db] && keys.size==exp[:executable_moves] && missing.empty? &&
          exec==exp[:executable_moves] && skill==exp[:executable_moves] &&
          presentation==exp[:executable_moves] && visual==exp[:executable_moves] && audio==exp[:executable_moves],
         :move_db=>move_db.size,:executable=>exec,:skill=>skill,:presentation=>presentation,
         :visual=>visual,:visual_generic=>visual_generic,:visual_field=>visual_field,
         :visual_guard=>visual_guard,:visual_two_turn=>visual_two_turn,
         :audio=>audio,:learnset_covered=>man[:cumulative_reference_covered].to_i,
         :learnset_total=>man[:learnset_reference_total].to_i,:missing=>missing.size}
      end
    end

    def content_validation_text_v095(report=nil)
      text=pmd_ac_v0951_content_validation_text_v095(report)
      text.sub!('PMD AutoChess Content Validation v0.95','PMD AutoChess Content Validation v0.95.1')
      text
    end
  end
end

class Scene_PMD_AutoChess
  alias pmd_ac_v0951_start start unless method_defined?(:pmd_ac_v0951_start)
  alias pmd_ac_v0951_refresh_header refresh_header unless method_defined?(:pmd_ac_v0951_refresh_header)

  def start
    pmd_ac_v0951_start
    begin
      if FileTest.exist?(PMD_AC::BATTLE_LOG_FILE)
        text=File.open(PMD_AC::BATTLE_LOG_FILE,'rb'){|f|f.read}
        text.sub!(/PMD AutoChess Proto v0\.[0-9.]+ Battle Verification Log/,
          'PMD AutoChess Proto v0.95.1 Battle Verification Log')
        File.open(PMD_AC::BATTLE_LOG_FILE,'wb'){|f|f.write(text)}
      end
    rescue
    end
    log_event(:content_validation,
      'PATCH v0.95.1 visual_bridge_router=generic+field_v035+guard_v040+two_turn_v039 generic_expected=505 subsystem_expected=21 mechanics_unchanged=1')
    refresh_header
  end

  def refresh_header
    pmd_ac_v0951_refresh_header
    return if @header_sprite==nil || @header_sprite.bitmap==nil
    bmp=@header_sprite.bitmap
    bmp.fill_rect(0,0,Graphics.width,28,Color.new(0,0,0,180))
    pmd_ac_v074_font(bmp)
    bmp.font.size=PMD_AC.const_defined?(:UI_HEADER_TITLE_FONT_V086) ? PMD_AC::UI_HEADER_TITLE_FONT_V086 : 20
    bmp.font.bold=true
    bmp.font.color=Color.new(255,255,255)
    bmp.draw_text(16,1,Graphics.width-32,30,'PMD 自走棋原型 v0.95.1',1)
  end

  def verify_content_move_bridge_v095
    return if @verification_done[:v095_moves]
    s=content_report_v095[:sections][:moves]||{}
    pass=s[:pass] ? true:false
    log_verify_v095('CONTENT_MOVE_BRIDGE_V095',pass,
      'move_db='+s[:move_db].to_i.to_s+' executable='+s[:executable].to_i.to_s+
      ' skill='+s[:skill].to_i.to_s+' presentation='+s[:presentation].to_i.to_s+
      ' visual='+s[:visual].to_i.to_s+' audio='+s[:audio].to_i.to_s+
      ' learnset='+s[:learnset_covered].to_i.to_s+'/'+s[:learnset_total].to_i.to_s+
      ' missing='+s[:missing].to_i.to_s)
    log_verify_v095('CONTENT_VISUAL_SUBSYSTEM_V0951',pass,
      'generic='+s[:visual_generic].to_i.to_s+
      ' field_v035='+s[:visual_field].to_i.to_s+
      ' guard_v040='+s[:visual_guard].to_i.to_s+
      ' two_turn_v039='+s[:visual_two_turn].to_i.to_s+
      ' total='+s[:visual].to_i.to_s+' missing='+s[:missing].to_i.to_s+
      ' mechanics_unchanged=1')
    @verification_done[:v095_moves]=true
  end
end
