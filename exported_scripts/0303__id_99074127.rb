#==============================================================================
# PMD AutoChess Battle Presentation Data v0.85
# 戰鬥背景／BGM／地圖・關卡・Boss・事件戰演出設定層
# RPG Maker VX / RGSS2 / Ruby 1.8 compatible
#==============================================================================
# 【這支腳本是做什麼的】
# 集中管理 PMD AutoChess 每一場戰鬥所使用的「戰鬥背景」與「BGM」。
# v0.81 已把戰鬥入口分成 Stage／Wild／Boss／Scripted；v0.85 在其上增加演出層，
# 讓不同地圖、不同關卡、不同 Boss、不同指定事件戰可以各用自己的背景與音樂。
#
# 【素材放哪裡】
# 戰鬥背景：Graphics/Battlebacks/
# BGM：     Audio/BGM/
#
# 背景建議尺寸：544 x 416（VX 原生畫面尺寸）。
# 其他尺寸也能用，Runtime 會 stretch 到 544 x 416。
# battleback 請寫完整檔名，例如：'forest_day.jpg'、'boss_ruins.png'。
# bgm 請寫 RPG Maker 使用的檔名「不含副檔名」，例如：'Battle'、'BossTheme'。
#
#------------------------------------------------------------------------------
# 【A. Battle Presentation Profile】
# 最常修改的是 BATTLE_PRESENTATION_PROFILES_V085。
#
# 可用欄位：
#   :battleback  => 'bg_001.jpg'   # Graphics/Battlebacks/ 裡的圖片
#   :bgm         => 'Battle'       # Audio/BGM/Battle.ogg 等，副檔名不用寫
#   :bgm_volume  => 90             # 0～100
#   :bgm_pitch   => 100            # 通常 50～150
#
# bgm 特殊值：
#   nil   = 使用 $game_system.battle_bgm（VX 系統設定的戰鬥 BGM）
#   false = 本場完全不播放 BGM
#   :map  = 戰鬥時繼續／恢復進戰鬥前的地圖 BGM
#
# battleback = nil：維持 PMD AutoChess 原本的深色藍紅背景。
#
# 範例：
#   :forest_day=>{
#     :battleback=>'forest_day.jpg',
#     :bgm=>'ForestBattle', :bgm_volume=>85, :bgm_pitch=>100
#   }
#
#------------------------------------------------------------------------------
# 【B. 不同地圖使用不同戰鬥背景／BGM】
# 修改 MAP_BATTLE_PRESENTATION_V085：
#
#   MAP_BATTLE_PRESENTATION_V085 = {
#     12=>:forest_day,   # Map ID 12
#     18=>:cave,
#     25=>:snowfield
#   }
#
# 地圖設定是「預設值」。如果 Boss／指定戰鬥另外指定，會蓋過地圖設定。
# Wild、Scripted、Boss 都能吃目前 Map ID 的預設演出。
#
#------------------------------------------------------------------------------
# 【C. 不同 Stage／關卡】
# 在 PMD AutoChess Stage Data v0.80 的該關卡 Hash 加：
#
#   :presentation=>:forest_day
#
# 例如：
#   1=>{
#     :name=>'林緣演習',
#     ...,
#     :presentation=>:forest_day
#   }
#
# Stage 選單 Q/W 切換關卡時，背景與 BGM 會跟著刷新。
#
#------------------------------------------------------------------------------
# 【D. 不同 Boss／固定 Encounter】
# 在 PMD AutoChess RPG Encounter Data v0.81 的 Encounter Hash 加：
#
#   :presentation=>:boss_demo
#
# 例如：
#   :boss_beedrill=>{
#     :name=>'蜂巢霸主・大針蜂',
#     :kind=>:boss,
#     ...,
#     :presentation=>:boss_demo
#   }
#
# Boss 的 presentation 優先於地圖預設。
#
#------------------------------------------------------------------------------
# 【E. v0.84 Encounter Profile 也能指定】
# 在 ENCOUNTER_PROFILES_V084 裡加：
#
#   :presentation=>:forest_day
#
# 適合「森林普通區／森林危險區」共用同一套背景與 BGM。
#
#------------------------------------------------------------------------------
# 【F. 指定某一場事件戰】
# 最高優先權。直接在呼叫時指定 Profile：
#
#   PMD_AC.start_battle_v081(:roadside_pikachu, {
#     :presentation=>:boss_demo
#   })
#
# 或完全不建 Profile，這一場直接覆蓋：
#
#   PMD_AC.start_battle_v081(:roadside_pikachu, {
#     :battleback=>'bg_002.jpg',
#     :bgm=>'lotr',
#     :bgm_volume=>90,
#     :bgm_pitch=>100
#   })
#
# v0.82 Custom Battle 同樣可用：
#   PMD_AC.start_custom_battle_v082('劇情伏擊', [
#     [:rattata,15], [:pidgey,15]
#   ], {
#     :presentation=>:forest_demo
#   })
#
# Boss Custom Battle：
#   PMD_AC.start_boss_battle_v082('古樹守衛', [...], {
#     :presentation=>:boss_demo
#   })
#
#------------------------------------------------------------------------------
# 【G. 優先順序】
# 從低到高：
#   全域預設
#     < 地圖 MAP_BATTLE_PRESENTATION_V085
#     < v0.84 Encounter Profile
#     < Stage／Encounter／Boss 本身的 :presentation
#     < 呼叫時 options[:presentation]
#     < 呼叫時直接 :battleback / :bgm / :bgm_volume / :bgm_pitch
#
# 因此同一張森林地圖：
# - 普通野怪可用 forest_demo
# - 森林 Boss 可用 boss_demo
# - 某一場劇情戰又能臨時換另一張背景／另一首歌
#
#------------------------------------------------------------------------------
# 【H. 回到地圖後】
# 外部 RPG 戰鬥結束後，仍沿用 v0.81 的 map_bgm / map_bgs 還原流程。
# 所以 Boss BGM 不會打完後一路追著玩家回村莊，這點對村民的心理健康很重要。
#
#------------------------------------------------------------------------------
# 【維護規則】
# - 一般只改本 Data 腳本，不要為了換一張背景去改 Scene_PMD_AutoChess。
# - battleback 檔案不存在時，自動退回原 PMD AutoChess 背景，不讓遊戲因此 Crash。
# - BGM 若填錯檔名，RGSS2 可能無法播放；請確認 Audio/BGM 內確實有素材。
# - 往後新增 PMD AutoChess 腳本，開頭仍須附完整中文說明與實際範例。
#==============================================================================
module PMD_AC
  BATTLE_PRESENTATION_PROFILES_V085 = {
    :default=>{
      :battleback=>nil,
      :bgm=>nil,
      :bgm_volume=>100,
      :bgm_pitch=>100
    },
    # 測試專案現有素材範例。正式製作時可直接複製／改名／追加。
    :forest_demo=>{
      :battleback=>'bg_001.jpg',
      :bgm=>'Battle',
      :bgm_volume=>85,
      :bgm_pitch=>100
    },
    :boss_demo=>{
      :battleback=>'bg_002.jpg',
      :bgm=>'lotr-ttt',
      :bgm_volume=>90,
      :bgm_pitch=>100
    },
    :story_demo=>{
      :battleback=>'bg_001.jpg',
      :bgm=>'lotr',
      :bgm_volume=>85,
      :bgm_pitch=>100
    }
  }

  # Map ID => Presentation Profile。
  # 正式專案請直接在這裡追加，例如：
  #   12=>:forest_demo,
  #   18=>:boss_demo
  # 測試專案預設保持空白，避免莫名改掉既有測試地圖的聲畫。
  MAP_BATTLE_PRESENTATION_V085 = {
  }

  DEFAULT_BATTLE_PRESENTATION_V085 = :default
  BATTLE_PRESENTATION_VERIFY_END_V085 = 24
  BATTLE_PRESENTATION_MANIFEST_V085 = {
    :schema_version=>'1.0',
    :content_version=>'0.85.0',
    :profiles=>BATTLE_PRESENTATION_PROFILES_V085.size,
    :map_defaults=>MAP_BATTLE_PRESENTATION_V085.size,
    :supports=>[:map,:stage,:wild,:boss,:scripted,:custom],
    :background_folder=>'Graphics/Battlebacks/',
    :bgm_folder=>'Audio/BGM/',
    :map_restore=>'v0.81',
    :runtime_checksum32=>850850125
  }

  class << self
    def battle_presentation_profile_v085(key)
      p=BATTLE_PRESENTATION_PROFILES_V085[key]
      p==nil ? nil : p
    end

    def copy_presentation_hash_v085(src)
      out={}
      return out unless src.is_a?(Hash)
      src.each{|k,v|out[k]=v}
      out
    end

    def merge_presentation_hash_v085(base,overlay)
      out=copy_presentation_hash_v085(base)
      return out unless overlay.is_a?(Hash)
      overlay.each{|k,v|out[k]=v}
      out
    end

    def presentation_value_hash_v085(value)
      return {} if value==nil
      return copy_presentation_hash_v085(value) if value.is_a?(Hash)
      p=battle_presentation_profile_v085(value)
      p==nil ? {} : copy_presentation_hash_v085(p)
    end

    def current_map_id_v085
      return nil if $game_map==nil
      $game_map.map_id
    end

    def map_presentation_value_v085(map_id=nil)
      id=map_id==nil ? current_map_id_v085 : map_id
      return nil if id==nil
      MAP_BATTLE_PRESENTATION_V085[id.to_i]
    end

    def request_source_presentation_values_v085(request)
      values=[]
      return values if request==nil
      # v0.84 Encounter Profile（區域級）。
      ep=request[:encounter_profile_v084]
      if ep!=nil && defined?(ENCOUNTER_PROFILES_V084)
        pd=ENCOUNTER_PROFILES_V084[ep]
        values.push(pd[:presentation]) if pd!=nil && pd.has_key?(:presentation)
      end
      # Stage／Encounter 自己的設定（比區域級更具體）。
      if request[:kind]==:stage && request[:stage_id]!=nil && respond_to?(:stage_data_v080)
        sd=stage_data_v080(request[:stage_id])
        values.push(sd[:presentation]) if sd!=nil && sd.has_key?(:presentation)
      elsif request[:key]!=nil && respond_to?(:encounter_data_v081)
        ed=encounter_data_v081(request[:key])
        values.push(ed[:presentation]) if ed!=nil && ed.has_key?(:presentation)
      end
      values.push(request[:presentation]) if request.has_key?(:presentation)
      values
    end

    def resolve_battle_presentation_v085(request=nil,map_id=nil)
      result=presentation_value_hash_v085(DEFAULT_BATTLE_PRESENTATION_V085)
      # 1. 地圖預設。
      result=merge_presentation_hash_v085(result,
        presentation_value_hash_v085(map_presentation_value_v085(map_id)))
      # 2. Encounter Profile／Stage／Boss／Encounter 本身。
      request_source_presentation_values_v085(request).each do |value|
        result=merge_presentation_hash_v085(result,presentation_value_hash_v085(value))
      end
      # 3. 單場 options，最高優先。
      options=request!=nil && request[:options].is_a?(Hash) ? request[:options] : {}
      if options.has_key?(:presentation)
        result=merge_presentation_hash_v085(result,
          presentation_value_hash_v085(options[:presentation]))
      end
      [:battleback,:bgm,:bgm_volume,:bgm_pitch].each do |key|
        result[key]=options[key] if options.has_key?(key)
      end
      result[:bgm_volume]=100 if result[:bgm_volume]==nil
      result[:bgm_pitch]=100 if result[:bgm_pitch]==nil
      result
    end

    def battleback_file_v085(name)
      return nil if name==nil || name==false
      s=name.to_s
      return nil if s==''
      list=[s]
      unless s.index('.')
        list += [s+'.png',s+'.jpg',s+'.jpeg']
      end
      list.each do |f|
        return f if FileTest.exist?('Graphics/Battlebacks/'+f)
      end
      nil
    end

    def bgm_file_exists_v085(name)
      return true if name==nil || name==false || name==:map
      s=name.to_s
      return false if s==''
      ['.ogg','.mp3','.wma','.mid','.wav'].each do |ext|
        return true if FileTest.exist?('Audio/BGM/'+s+ext)
      end
      false
    end

    def battle_presentation_errors_v085
      e=[]
      BATTLE_PRESENTATION_PROFILES_V085.each do |key,p|
        unless p.is_a?(Hash)
          e.push(key.to_s+':not_hash')
          next
        end
        if p[:battleback]!=nil && p[:battleback]!=false && battleback_file_v085(p[:battleback])==nil
          e.push(key.to_s+':battleback_missing')
        end
        if p[:bgm]!=nil && p[:bgm]!=false && p[:bgm]!=:map && !bgm_file_exists_v085(p[:bgm])
          e.push(key.to_s+':bgm_missing')
        end
      end
      e
    end
  end
end
