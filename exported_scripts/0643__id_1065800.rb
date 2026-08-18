# encoding: UTF-8
#===============================================================================
# ■ PMD AutoChess - VXRD Water-Bottom Autotile Pair Authority I
#   v1.06.58
#-------------------------------------------------------------------------------
# 【用途】
# 修正 Random Hunt 水域使用的 VX A1 原生 AUTOTILE。
# v1.06.42 起四張水域 Hunt 一律使用 A1 base 2096（深海家族），實機視覺
# 雖有動畫，但水底完全不透明，與目前地圖希望呈現的淺水／可見底風格不符。
#
# 【正式規則】
# 1. A1 base 2048：冰山／浮冰裝飾左側的可見底水家族。
#    - 用於草地、自然土底、濕地等柔性地表。
#    - 目前 H02「苔溪濕地」使用。
# 2. A1 base 2240：冰山／浮冰裝飾右側的可見底水家族。
#    - 用於石路、岩盤、硬質／冰雪底等地表。
#    - 目前 H07 / H12 / H17 使用。
# 3. A1 base 2096（深海家族）自 Random Hunt 正式水域配置撤銷。
#
# 【為什麼 base 是 2048 / 2240】
# VX A1 從 tile ID 2048 起算，每個 AUTOTILE kind 佔 48 個 shape ID。
# - kind 0 => 2048：A1 左側第一組動畫水。
# - kind 1 => 2096：深海／不透明水（舊設定）。
# - kind 4 => 2240：A1 右側第一組動畫水，位於浮冰裝飾右側。
# 本版只切換 AUTOTILE kind，不改 PNG，因此仍保留 VX 原生動畫與拼接。
#
# 【Hunt 對應】
# H02 => 2048 / :grass_bottom_clear
# H07 => 2240 / :stone_bottom_clear
# H12 => 2240 / :stone_bottom_clear
# H17 => 2240 / :stone_bottom_clear
#
# 【不變規則】
# - 水域仍只存在 H02 / H07 / H12 / H17。
# - 保持 rectangle-only，無 river、無 bridge。
# - 水仍屬不可步行的 A1 water region。
# - A2 ground 對 A1 water 的 shoreline border 規則維持 v1.06.42 Authority。
# - 不恢復任何 B/C/D/E automatic scatter / stamping。
# - 不更動 Gate 1 topology、Map090/Map091 Authority、Landmark、Route Safety。
# - 不更動 Battle AI / Damage / Attack Speed / Focus-C2 / Reward / Progression。
#
# 【可調參數】
# 若日後新增水域 Hunt，請在 VXRD_WATER_BOTTOM_PAIR_V10658 新增 code 與 base。
# base 必須是合法 A1 autotile kind base（2048 + kind*48），且正式內容應先做
# RMVX 實機 visual acceptance 再封版。
#
# 【事件／腳本呼叫】
# 正常遊戲不需事件呼叫；腳本載入時會覆寫既有 Hunt style 的 water_base。
# 稽核可呼叫：
#   PMD_AC.vxrd_water_bottom_pair_audit_v10658
# 寫出 LOG：
#   PMD_AC.vxrd_write_water_bottom_pair_audit_v10658
# 產生：PMD_VXRD_WaterBottom_Audit_LATEST.log
#
# 【實例】
# H02 Floor 1 生成水池時，Runtime 會從原本 base 2096 改用 2048，
# 因此仍是原生動畫 AUTOTILE，但視覺改成可看見自然底色的淺水。
# H07 / H12 / H17 則使用 2240 的硬質底版本。
#===============================================================================
$imported={} unless defined?($imported)
$imported['PMD_AutoChess_VXRDWaterBottomAutotilePairAuthorityI_v10658']=true

module PMD_AC
  VXRD_WATER_BOTTOM_VERSION_V10658='1.06.58'
  VXRD_WATER_BOTTOM_LOG_V10658='PMD_VXRD_WaterBottom_Audit_LATEST.log'
  VXRD_A1_GRASS_BOTTOM_WATER_BASE_V10658=2048
  VXRD_A1_STONE_BOTTOM_WATER_BASE_V10658=2240
  VXRD_A1_REVOKED_DEEP_WATER_BASE_V10658=2096

  VXRD_WATER_BOTTOM_PAIR_V10658={
    'H02'=>{:base=>VXRD_A1_GRASS_BOTTOM_WATER_BASE_V10658,
      :style=>:grass_bottom_clear,:ground=>:natural},
    'H07'=>{:base=>VXRD_A1_STONE_BOTTOM_WATER_BASE_V10658,
      :style=>:stone_bottom_clear,:ground=>:hard},
    'H12'=>{:base=>VXRD_A1_STONE_BOTTOM_WATER_BASE_V10658,
      :style=>:stone_bottom_clear,:ground=>:hard_ice},
    'H17'=>{:base=>VXRD_A1_STONE_BOTTOM_WATER_BASE_V10658,
      :style=>:stone_bottom_clear,:ground=>:hard_ice}
  }

  if const_defined?(:VXRD_HUNT_STYLE_V10600)
    VXRD_WATER_BOTTOM_PAIR_V10658.each do |code,pair|
      row=VXRD_HUNT_STYLE_V10600[code]
      if row.is_a?(Hash)
        row[:water]=true
        row[:water_base]=pair[:base].to_i
        row[:water_bottom_style_v10658]=pair[:style]
      end
    end
  end

  class << self
    def vxrd_water_bottom_pair_v10658(code=nil)
      c=(code || (respond_to?(:hunt_current_code) ? hunt_current_code : nil)).to_s.upcase
      VXRD_WATER_BOTTOM_PAIR_V10658[c]
    rescue
      nil
    end

    def vxrd_water_bottom_pair_audit_v10658
      bad=[]
      expected=%w[H02 H07 H12 H17]
      pairs=VXRD_WATER_BOTTOM_PAIR_V10658
      bad << 'pair_scope' unless pairs.keys.sort==expected.sort
      bad << 'grass_base' unless VXRD_A1_GRASS_BOTTOM_WATER_BASE_V10658==2048
      bad << 'stone_base' unless VXRD_A1_STONE_BOTTOM_WATER_BASE_V10658==2240
      bad << 'revoked_base' unless VXRD_A1_REVOKED_DEEP_WATER_BASE_V10658==2096
      expected.each do |code|
        p=pairs[code]
        bad << code+':missing_pair' unless p.is_a?(Hash)
        next unless p.is_a?(Hash)
        base=p[:base].to_i
        bad << code+':invalid_a1_base' unless [2048,2240].include?(base)
        bad << code+':deep_water_still_used' if base==2096
        if const_defined?(:VXRD_HUNT_STYLE_V10600)
          row=VXRD_HUNT_STYLE_V10600[code]
          bad << code+':missing_style' unless row.is_a?(Hash)
          if row.is_a?(Hash)
            bad << code+':water_disabled' unless row[:water]
            bad << code+':runtime_base' unless row[:water_base].to_i==base
          end
        end
      end
      bad << 'H02_not_grass_bottom' unless pairs['H02'][:base].to_i==2048
      %w[H07 H12 H17].each do |code|
        bad << code+':not_stone_bottom' unless pairs[code][:base].to_i==2240
      end
      if const_defined?(:VXRD_NATIVE_AUTOTILE_PROFILE_V10642)
        wet=VXRD_NATIVE_AUTOTILE_PROFILE_V10642.keys.find_all do |c|
          VXRD_NATIVE_AUTOTILE_PROFILE_V10642[c][:water]
        end
        bad << 'native_water_scope' unless wet.sort==expected.sort
      end
      {:pass=>bad.empty?,:pairs=>pairs,:water_codes=>expected,
       :grass_base=>2048,:stone_base=>2240,:revoked_base=>2096,
       :deep_water_used=>pairs.values.any?{|p|p[:base].to_i==2096},
       :native_a1=>true,:animated=>true,:topology_rewrite=>false,
       :map_table_bcde_stamp=>false,:bad=>bad}
    rescue Exception=>e
      {:pass=>false,:bad=>[:audit_error],:error=>e.class.to_s}
    end

    def vxrd_write_water_bottom_pair_audit_v10658
      r=vxrd_water_bottom_pair_audit_v10658
      lines=[]
      lines << 'PMD AutoChess VXRD Water-Bottom Autotile Pair Audit v1.06.58'
      lines << 'RESULT='+(r[:pass] ? 'PASS':'FAIL')
      lines << 'WATER_CODES='+(r[:water_codes]||[]).join(',')
      lines << 'H02_BASE=2048'
      lines << 'H07_BASE=2240'
      lines << 'H12_BASE=2240'
      lines << 'H17_BASE=2240'
      lines << 'GRASS_BOTTOM_BASE=2048'
      lines << 'STONE_BOTTOM_BASE=2240'
      lines << 'REVOKED_DEEP_WATER_BASE=2096'
      lines << 'DEEP_WATER_USED=0'
      lines << 'NATIVE_A1_AUTOTILE=1'
      lines << 'ANIMATED=1'
      lines << 'TOPOLOGY_REWRITE=0'
      lines << 'MAP_TABLE_BCDE_STAMPING=0'
      (r[:bad]||[]).each{|x|lines << 'ERROR='+x.to_s}
      File.open(VXRD_WATER_BOTTOM_LOG_V10658,'wb') do |io|
        io.write(lines.join("\r\n")+"\r\n")
      end
      r
    rescue
      {:pass=>false}
    end

    alias pmd_ac_v10658_write_project_state_log write_project_state_log unless method_defined?(:pmd_ac_v10658_write_project_state_log)
    def project_version
      '1.06.58'
    end
    def write_project_state_log(force=false)
      r=pmd_ac_v10658_write_project_state_log(force)
      vxrd_write_water_bottom_pair_audit_v10658
      r
    rescue
      r
    end
  end
end
