# encoding: UTF-8
#==============================================================================
# 【PMD AutoChess 中文維護說明】
# 腳本：PMD AutoChess Map / Story Runtime Acceptance + Minimal LOG v1.01.2
# 分類：RPG 垂直切片實機驗證／Battle LOG 精簡／Scene_Map runtime coverage
# RPG Maker VX / RGSS2 / Ruby 1.8 compatible
#------------------------------------------------------------------------------
# 【用途】
# v1.01.1 已修正 RPG Maker VX 沒有 Game_Map#terrain_tag 時的遭遇錯誤。本版不改
# 地圖玩法或 Combat Logic，而是補上兩個工程缺口：
# 1. MAP_STORY_VERTICAL_SLICE_V101 正式納入 current-test minimal Battle LOG，避免
#    DAMAGE / TARGET / AUDIO / THREAT 等與本次地圖驗證無關的歷史流水帳重新爆量。
# 2. 建立「真正玩過」的 runtime coverage。Static verifier 只能證明 Map005 / Map006
#    與事件存在；本版會記錄玩家是否真的走過三張地圖、NPC、Checkpoint、可見野戰、
#    步行遭遇、特殊皮卡丘、Boss、戰鬥後回原地圖與最後回營地。
#------------------------------------------------------------------------------
# 【主要設定項】
# LOG_MAP_STORY_VERIFY_CATEGORIES_V1012：本模式 Battle LOG 允許的最小 category。
# RUNTIME_REQUIRED_MAPS_V1012：實機必訪 Map004 / Map005 / Map006。
# RUNTIME_REQUIRED_NPCS_V1012：實機需對話 entrance / deep / hive 三種 NPC。
#------------------------------------------------------------------------------
# 【機制規則】
# 1. 本腳本只做 trailing alias / verifier hook，不直接修改 Frozen Combat Core。
# 2. Battle LOG 在 MAP_STORY 模式只保留 battle / perf / verify / summary / showcase。
#    舊 logger 的 gameplay side-effect 仍由 v1.00.6 fast path 維持，不因省略文字而失效。
# 3. runtime coverage 只存在當次 Game.exe 記憶體；不寫入存檔、不改 Pokémon 資料。
# 4. 特殊皮卡丘只要求「至少勝利一次並正常回 Map005」，不要求 RNG 招募成功；避免
#    驗證結果被捕捉機率綁架。Boss 則要求實際勝利並 boss_cleared=true。
# 5. Wild 至少需要兩勝以打開 Boss；另要求實際觸發過一次 visible marker 與一次
#    walking random encounter。walking 那場輸贏皆可，只驗證路徑與回圖安全。
# 6. Pokémon identity 永遠 instance_uid；Dynamic Tactical Role、Spatial Framework、
#    Skill FX、Damage Formula、Startup Cooperative Loader 均不修改。
#------------------------------------------------------------------------------
# 【可調參數】
# 若後續切片新增地圖，可擴充 RUNTIME_REQUIRED_MAPS_V1012。
# 若 NPC 不再要求三區皆互動，可調整 RUNTIME_REQUIRED_NPCS_V1012。
# Battle LOG 若某次專門查 Damage，可暫時把 :damage 加入 category；驗完下一版應移除。
#------------------------------------------------------------------------------
# 【玩家測試／事件呼叫方式】
# 一般事件不需新增呼叫；既有 v1.01 API 全部沿用：
#   PMD_AC.enter_vertical_slice_v101(4)
#   PMD_AC.vertical_wild_v101(:field_marker)
#   PMD_AC.vertical_special_v101
#   PMD_AC.vertical_boss_v101
#------------------------------------------------------------------------------
# 【正式實機驗證範例】
# 1. Map004：入口 NPC -> Checkpoint -> 可見野戰至少一勝 -> 步行遭遇一次。
# 2. Map005：深處 NPC -> 皮卡丘特殊遭遇至少一勝 -> 補足林緣 Wild 第 2 勝。
# 3. Map006：蜂巢 NPC -> Boss 勝利 -> 返回地圖 -> F8 回營地。
# 4. 回 AutoChess 布陣，S 切 MAP_STORY_VERTICAL_SLICE_V101，Shift。
# 預期：MAP_STORY_RUNTIME_ACCEPTANCE_V1012 pass=1，最後仍需
# VERIFY_FINISHED_BATTLE_RESUME pass=1。
#==============================================================================
module PMD_AC
  LOG_MAP_STORY_VERIFY_CATEGORIES_V1012=[:battle,:perf,:verify,:summary,:showcase]
  RUNTIME_REQUIRED_MAPS_V1012=[4,5,6]
  RUNTIME_REQUIRED_NPCS_V1012=[:entrance,:deep,:hive]

  class << self
    alias pmd_ac_v1012_log_category_allowed_v1006? log_category_allowed_v1006? unless method_defined?(:pmd_ac_v1012_log_category_allowed_v1006?)
    alias pmd_ac_v1012_vertical_log_v101 vertical_log_v101 unless method_defined?(:pmd_ac_v1012_vertical_log_v101)

    def log_category_allowed_v1006?(mode,category)
      if mode==:map_story_vertical_slice_v101
        return LOG_MAP_STORY_VERIFY_CATEGORIES_V1012.include?(category.to_s.to_sym)
      end
      pmd_ac_v1012_log_category_allowed_v1006?(mode,category)
    end

    def runtime_coverage_v1012
      if @runtime_coverage_v1012==nil
        @runtime_coverage_v1012={
          :maps=>{},:npcs=>{},:checkpoint=>false,:visible_wild=>false,:walking_wild=>false,
          :special_launch=>false,:special_return=>false,:boss_launch=>false,:boss_return=>false,
          :return_maps=>{},:returned_camp=>false,:last_battle_kind=>nil
        }
      end
      @runtime_coverage_v1012
    end

    def mark_runtime_log_v1012(text)
      t=text.to_s
      c=runtime_coverage_v1012
      if t =~ /MAP_ENTER id=(\d+)/
        c[:maps][$1.to_i]=true
      elsif t =~ /NPC zone=([^ ]+)/
        begin;c[:npcs][$1.to_s.to_sym]=true;rescue;end
      elsif t.index('CHECKPOINT ') == 0
        c[:checkpoint]=true
      elsif t.index('BATTLE_LAUNCH kind=wild') == 0
        c[:last_battle_kind]=:wild
        c[:walking_wild]=true if t.index('source=walking')!=nil
        c[:visible_wild]=true if t.index('source=marker_')!=nil
      elsif t.index('BATTLE_LAUNCH kind=special') == 0
        c[:last_battle_kind]=:special
        c[:special_launch]=true
      elsif t.index('BATTLE_LAUNCH kind=boss') == 0
        c[:last_battle_kind]=:boss
        c[:boss_launch]=true
      elsif t =~ /BATTLE_RETURN map=(\d+) result=([^ ]+)/
        mid=$1.to_i
        c[:return_maps][mid]=true
        if c[:last_battle_kind]==:special && mid==5
          c[:special_return]=true
        elsif c[:last_battle_kind]==:boss && mid==6
          c[:boss_return]=true
        end
        c[:last_battle_kind]=nil
      elsif t.index('RETURN_CAMP ') == 0
        c[:returned_camp]=true
      end
      c
    rescue
      runtime_coverage_v1012
    end

    def runtime_summary_v1012
      c=runtime_coverage_v1012
      maps=RUNTIME_REQUIRED_MAPS_V1012.collect{|m|c[:maps][m] ? m.to_s : '-'}.join(',')
      npcs=RUNTIME_REQUIRED_NPCS_V1012.collect{|n|c[:npcs][n] ? n.to_s : '-'}.join(',')
      returns=RUNTIME_REQUIRED_MAPS_V1012.collect{|m|c[:return_maps][m] ? m.to_s : '-'}.join(',')
      s=rpg_foundation_state_v100
      'RUNTIME_COVERAGE_V1012 maps='+maps+' npcs='+npcs+
        ' checkpoint='+(c[:checkpoint] ? '1':'0')+
        ' visible='+(c[:visible_wild] ? '1':'0')+
        ' walking='+(c[:walking_wild] ? '1':'0')+
        ' special='+(c[:special_launch] && c[:special_return] ? '1':'0')+
        ' boss='+(c[:boss_launch] && c[:boss_return] ? '1':'0')+
        ' returns='+returns+' camp='+(c[:returned_camp] ? '1':'0')+
        ' wild_wins='+s[:wild_wins].to_i.to_s+' special_wins='+s[:special_wins].to_i.to_s+
        ' boss_clear='+(s[:boss_cleared] ? '1':'0')
    rescue
      'RUNTIME_COVERAGE_V1012 error=1'
    end

    def runtime_acceptance_v1012?
      c=runtime_coverage_v1012
      s=rpg_foundation_state_v100
      maps=RUNTIME_REQUIRED_MAPS_V1012.all?{|m|c[:maps][m]}
      npcs=RUNTIME_REQUIRED_NPCS_V1012.all?{|n|c[:npcs][n]}
      returns=RUNTIME_REQUIRED_MAPS_V1012.all?{|m|c[:return_maps][m]}
      maps && npcs && returns && c[:checkpoint] && c[:visible_wild] && c[:walking_wild] &&
        c[:special_launch] && c[:special_return] && c[:boss_launch] && c[:boss_return] &&
        c[:returned_camp] && s[:wild_wins].to_i>=2 && s[:special_wins].to_i>=1 && s[:boss_cleared]
    rescue
      false
    end

    def vertical_log_v101(text)
      t=text.to_s
      mark_runtime_log_v1012(t)
      ok=pmd_ac_v1012_vertical_log_v101(t)
      if t.index('RETURN_CAMP ') == 0
        pmd_ac_v1012_vertical_log_v101(runtime_summary_v1012)
      end
      ok
    end
  end
end

class Scene_PMD_AutoChess
  alias pmd_ac_v1012_current_profile_active? v1006_current_profile_active? unless method_defined?(:pmd_ac_v1012_current_profile_active?)
  alias pmd_ac_v1012_update_verification_script update_verification_script unless method_defined?(:pmd_ac_v1012_update_verification_script)

  def v1006_current_profile_active?
    return true if v1006_current_log_mode==:map_story_vertical_slice_v101
    pmd_ac_v1012_current_profile_active?
  end

  def verify_map_story_runtime_acceptance_v1012
    return if @verification_done[:map_story_runtime_acceptance_v1012]
    pass=PMD_AC.runtime_acceptance_v1012?
    @map_story_failed_v101=true unless pass
    log_event(:verify,'MAP_STORY_RUNTIME_ACCEPTANCE_V1012 pass='+(pass ? '1':'0')+' '+PMD_AC.runtime_summary_v1012)
    @verification_done[:map_story_runtime_acceptance_v1012]=true
  end

  def verify_map_story_log_profile_v1012
    return if @verification_done[:map_story_log_profile_v1012]
    cats=PMD_AC::LOG_MAP_STORY_VERIFY_CATEGORIES_V1012
    pass=cats.include?(:verify) && cats.include?(:battle) && !cats.include?(:damage) &&
      !cats.include?(:target) && !cats.include?(:audio_runtime) && !cats.include?(:threat)
    @map_story_failed_v101=true unless pass
    log_event(:verify,'MAP_STORY_LOG_PROFILE_V1012 pass='+(pass ? '1':'0')+
      ' minimal=1 verify=1 damage_flood=0 target_flood=0 audio_flood=0 threat_flood=0 categories='+cats.size.to_s)
    @verification_done[:map_story_log_profile_v1012]=true
  end

  def update_verification_script
    pmd_ac_v1012_update_verification_script
    return unless map_story_vertical_slice_v101?
    f=@verification_frame.to_i
    verify_map_story_log_profile_v1012 if f>=186
    verify_map_story_runtime_acceptance_v1012 if f>=188
  end
end
