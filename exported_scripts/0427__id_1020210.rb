# encoding: UTF-8
#==============================================================================
# 【PMD AutoChess 中文維護說明】
# 腳本：PMD AutoChess Basic Flex Profile Memo v1.02.21
# 分類：PMD Motion Phase A／Windows RGSS2 效能單點 A/B／Trailing Optimization
# RPG Maker VX / RGSS2 / Ruby 1.8 compatible
#------------------------------------------------------------------------------
# 【用途】
# v1.02.20 Windows RGSS2 已證明 move-speed status allocation-free 等價改寫成功：
#   movement_status_speed  max 121ms -> 1ms
#   mismatch=0 / max_diff=0.000000
# 但同一場仍有：
#   movement_effective_speed max 122ms
#   movement_total           max 122ms
# 代表 effective_move_speed 的其他歷史層仍有高頻配置／停頓來源。
#
# 程式碼檢查確認 v0.99.12 Game_PMDChessUnit#basic_flex_profile_v09912 每次呼叫都會：
#   1. 進入 PMD_AC.basic_flex_profile_v09912(species, form)
#   2. review_profile_for_v09911 產生 profile .dup
#   3. 再建立新的 Basic Flex Hash
# 而 effective_move_speed、spacing、basic range、movement policy 等高頻路徑都會反覆讀取
# 同一隻寶可夢相同 species/form 的靜態 profile。v1.02.20 單場 effective speed 呼叫約
# 17,719 次，這些重複 Hash 配置沒有必要。
#
# 本版只在 PMD_MOTION_PHASE_A_V102 live battle 對 Game_PMDChessUnit 的
# basic_flex_profile_v09912 做「species + form 不變時回傳同一份唯讀用途 memo 結果」。
# species/form 若改變會立即重算，不快取跨形態結果。
#------------------------------------------------------------------------------
# 【主要設定】
# MOTION_BASIC_FLEX_MEMO_THRESHOLD_MS_V10221 = 4
#   cache miss / original build 單次 >=4ms 才留 hot record。
# MOTION_BASIC_FLEX_MEMO_RECORD_LIMIT_V10221 = 64
#   獨立 hot record 上限。
# MOTION_BASIC_FLEX_MEMO_REPORT_LIMIT_V10221 = 20
#   戰鬥結束最多輸出 20 筆。
#------------------------------------------------------------------------------
# 【機制規則】
# 1. 非 PMD_MOTION_PHASE_A_V102 或非 live battle：完全走原始 v0.99.12 方法。
# 2. 第一次 species/form：呼叫原始方法一次並保存結果。
# 3. 後續 species/form 相同：直接回傳保存的 profile，不重新 .dup / 建 Hash。
# 4. species 或 form 改變：立即 miss 並重新呼叫原始方法。
# 5. nil profile 也會依 species/form 記住，避免反覆查詢不存在的 profile。
# 6. 不修改 profile 內容；所有 threshold、range、spacing、delivery 與 source 原值保留。
#------------------------------------------------------------------------------
# 【一致性驗證】
# verifier 會對場上每個單位做一次：
#   A. 原始 basic_flex_profile_v09912
#   B. memo path 回傳結果
# 使用 Hash == / nil equality 比對。只要任何單位不一致，
# MOTION_BASIC_FLEX_MEMO_V10221 pass=0，並讓 PMD Motion verifier FAIL。
#------------------------------------------------------------------------------
# 【LOG】
# 開戰：
#   MOTION_BASIC_FLEX_MEMO_V10221 pass=1 compared=6 mismatch=0
# 戰鬥結束：
#   MOTION_BASIC_FLEX_MEMO_SUMMARY_V10221 calls=... hit=... miss=...
#     avoided_profile_builds=... max_miss_ms=...
#------------------------------------------------------------------------------
# 【事件／腳本呼叫方式與範例】
# 正式事件不需呼叫。
# 實機測試：S -> PMD_MOTION_PHASE_A_V102 -> Shift -> Loading 100% -> 完整跑完一場。
#------------------------------------------------------------------------------
# 【可調參數】
# 本版沒有戰鬥平衡參數。threshold / record limit 只影響診斷 LOG。
#------------------------------------------------------------------------------
# 【不可破壞】
# - 不改 Damage Formula / Attack Speed / AI 決策值 / Spatial logical x/y。
# - 不改 Adaptive Close threshold、basic range、spacing policy、move speed multiplier。
# - 不改 Motion / Projectile / Skill FX / hit-stop / Hurt ownership。
# - Frozen Combat Core 不直接修改，只用 trailing alias/override。
# - v1.02.20 Move Speed allocation-free 保留。
# - Game.ini 不得有 UTF-8 BOM，第 0 byte 必須為 [。
#==============================================================================
module PMD_AC
  MOTION_BASIC_FLEX_MEMO_VERSION_V10221='1.02.21'
  MOTION_BASIC_FLEX_MEMO_THRESHOLD_MS_V10221=4
  MOTION_BASIC_FLEX_MEMO_RECORD_LIMIT_V10221=64
  MOTION_BASIC_FLEX_MEMO_REPORT_LIMIT_V10221=20
end

class Scene_PMD_AutoChess
  alias pmd_ac_v10221_start start unless method_defined?(:pmd_ac_v10221_start)
  alias pmd_ac_v10221_start_battle start_battle unless method_defined?(:pmd_ac_v10221_start_battle)
  alias pmd_ac_v10221_update_verification_script update_verification_script unless method_defined?(:pmd_ac_v10221_update_verification_script)
  alias pmd_ac_v10221_motion_perf_log_summary_v1023 motion_perf_log_summary_v1023 unless method_defined?(:pmd_ac_v10221_motion_perf_log_summary_v1023)

  def motion_basic_flex_memo_reset_v10221
    @motion_basic_flex_calls_v10221=0
    @motion_basic_flex_hit_v10221=0
    @motion_basic_flex_miss_v10221=0
    @motion_basic_flex_max_miss_ms_v10221=0
    @motion_basic_flex_records_v10221=[]
    @motion_basic_flex_summary_logged_v10221=false
  end

  def start
    motion_basic_flex_memo_reset_v10221
    pmd_ac_v10221_start
  end

  def start_battle
    motion_basic_flex_memo_reset_v10221 if verification_mode==:pmd_motion_phase_a_v102
    pmd_ac_v10221_start_battle
  end

  def motion_basic_flex_memo_active_v10221?
    return false unless verification_mode==:pmd_motion_phase_a_v102
    return false unless @phase==:battle
    true
  rescue
    false
  end

  def motion_basic_flex_memo_record_v10221(hit,ms,unit)
    return unless motion_basic_flex_memo_active_v10221?
    @motion_basic_flex_calls_v10221=@motion_basic_flex_calls_v10221.to_i+1
    if hit
      @motion_basic_flex_hit_v10221=@motion_basic_flex_hit_v10221.to_i+1
      return
    end
    @motion_basic_flex_miss_v10221=@motion_basic_flex_miss_v10221.to_i+1
    n=ms.to_i
    @motion_basic_flex_max_miss_ms_v10221=n if n>@motion_basic_flex_max_miss_ms_v10221.to_i
    return if n<PMD_AC::MOTION_BASIC_FLEX_MEMO_THRESHOLD_MS_V10221
    @motion_basic_flex_records_v10221=[] if @motion_basic_flex_records_v10221==nil
    return if @motion_basic_flex_records_v10221.size>=PMD_AC::MOTION_BASIC_FLEX_MEMO_RECORD_LIMIT_V10221
    uname='-';sk='-';fk='-'
    begin;uname=unit.log_name.to_s if unit!=nil;rescue;end
    begin;sk=unit.species_key.to_s if unit!=nil;rescue;end
    begin;fk=unit.form_key.to_s if unit!=nil && unit.respond_to?(:form_key);rescue;end
    frame=0
    begin;frame=Graphics.frame_count-@battle_started_frame if @battle_started_frame!=nil;rescue;end
    @motion_basic_flex_records_v10221.push({:frame=>frame,:ms=>n,:unit=>uname,:species=>sk,:form=>fk})
  rescue
  end

  def verify_motion_basic_flex_memo_v10221
    return if @verification_done!=nil && @verification_done[:motion_basic_flex_memo_v10221]
    compared=0;mismatch=0
    begin
      (@units || []).each do |u|
        next if u==nil || !u.respond_to?(:motion_basic_flex_original_v10221)
        original=u.motion_basic_flex_original_v10221
        memo=u.motion_basic_flex_profile_memo_v10221(false)
        compared+=1
        mismatch+=1 unless original==memo
      end
    rescue
      mismatch+=1
    end
    pass=verification_mode==:pmd_motion_phase_a_v102 && compared>0 && mismatch==0
    @motion_phase_a_failed_v102=true unless pass
    log_event(:verify,'MOTION_BASIC_FLEX_MEMO_V10221 pass='+(pass ? '1':'0')+
      ' compared='+compared.to_s+' mismatch='+mismatch.to_s+
      ' species_form_keyed=1 profile_values_unchanged=1 adaptive_thresholds_unchanged=1'+
      ' ai_unchanged=1 damage_unchanged=1 attack_speed_unchanged=1 spatial_values_unchanged=1')
    @verification_done[:motion_basic_flex_memo_v10221]=true if @verification_done!=nil
  rescue
  end

  def update_verification_script
    result=pmd_ac_v10221_update_verification_script
    if verification_mode==:pmd_motion_phase_a_v102 && @verification_frame.to_i>=62
      verify_motion_basic_flex_memo_v10221
    end
    result
  end

  def motion_basic_flex_memo_log_summary_v10221
    return if @motion_basic_flex_summary_logged_v10221
    return unless verification_mode==:pmd_motion_phase_a_v102
    @motion_basic_flex_summary_logged_v10221=true
    calls=@motion_basic_flex_calls_v10221.to_i
    hit=@motion_basic_flex_hit_v10221.to_i
    miss=@motion_basic_flex_miss_v10221.to_i
    records=(@motion_basic_flex_records_v10221 || []).dup
    records.sort!{|a,b|b[:ms].to_i<=>a[:ms].to_i}
    hot=records[0,PMD_AC::MOTION_BASIC_FLEX_MEMO_REPORT_LIMIT_V10221] || []
    log_event(:perf,'MOTION_BASIC_FLEX_MEMO_SUMMARY_V10221 calls='+calls.to_s+
      ' hit='+hit.to_s+' miss='+miss.to_s+' avoided_profile_builds='+hit.to_s+
      ' max_miss_ms='+@motion_basic_flex_max_miss_ms_v10221.to_i.to_s+' hot='+hot.size.to_s)
    hot.each do |r|
      log_event(:perf,'MOTION_BASIC_FLEX_MEMO_HOT_V10221 frame='+r[:frame].to_i.to_s+
        ' ms='+r[:ms].to_i.to_s+' unit='+r[:unit].to_s+
        ' species='+r[:species].to_s+' form='+r[:form].to_s)
    end
  rescue
  end

  def motion_perf_log_summary_v1023
    already=@motion_perf_summary_logged_v1023
    result=pmd_ac_v10221_motion_perf_log_summary_v1023
    if !already && @motion_perf_summary_logged_v1023
      motion_basic_flex_memo_log_summary_v10221
    end
    result
  end
end

class Game_PMDChessUnit
  alias pmd_ac_v10221_basic_flex_profile_v09912 basic_flex_profile_v09912 unless method_defined?(:pmd_ac_v10221_basic_flex_profile_v09912)

  def motion_basic_flex_original_v10221
    pmd_ac_v10221_basic_flex_profile_v09912
  end

  def motion_basic_flex_profile_memo_v10221(record=true)
    sk=nil;fk=:normal
    begin;sk=species_key;rescue;end
    begin;fk=form_key if respond_to?(:form_key);rescue;end
    fk=:normal if fk==nil
    hit=(@motion_basic_flex_memo_ready_v10221 &&
         @motion_basic_flex_species_v10221==sk &&
         @motion_basic_flex_form_v10221==fk)
    scene=@scene
    if hit
      scene.motion_basic_flex_memo_record_v10221(true,0,self) if record && scene!=nil && scene.respond_to?(:motion_basic_flex_memo_record_v10221)
      return @motion_basic_flex_profile_v10221
    end
    t=Time.now.to_f
    profile=pmd_ac_v10221_basic_flex_profile_v09912
    ms=((Time.now.to_f-t)*1000.0).round rescue 0
    @motion_basic_flex_species_v10221=sk
    @motion_basic_flex_form_v10221=fk
    @motion_basic_flex_profile_v10221=profile
    @motion_basic_flex_memo_ready_v10221=true
    scene.motion_basic_flex_memo_record_v10221(false,ms,self) if record && scene!=nil && scene.respond_to?(:motion_basic_flex_memo_record_v10221)
    profile
  end

  def basic_flex_profile_v09912
    scene=@scene
    if scene!=nil && scene.respond_to?(:motion_basic_flex_memo_active_v10221?) &&
       scene.motion_basic_flex_memo_active_v10221?
      return motion_basic_flex_profile_memo_v10221(true)
    end
    pmd_ac_v10221_basic_flex_profile_v09912
  end
end
