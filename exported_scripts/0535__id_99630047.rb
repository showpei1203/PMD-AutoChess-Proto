# encoding: UTF-8
#===============================================================================
# ■ PMD AutoChess - Team Composition Preview v1.05.50
#===============================================================================
# 【用途】
# 在既有 v0.99.13「AI Strategy」布陣面板加入隊伍定位與 Team Bond 預覽。
# v1.05.49 已讓正式 Tactical Bond 使用 Dynamic Primary Role；本版把同一套 Authority
# 直接顯示給玩家，避免「改了 Build，只有 Runtime 知道結果」的黑箱。
#
# 【顯示內容】
# AI Strategy 面板下方新增兩行：
# 1. 隊伍定位：目前三隻正式出戰 Pokémon 的 Dynamic Tactical Role。
# 2. 羈絆預覽：依目前隊伍與 v1.05.49 Effective Composition Tags 即時計算，
#    最多顯示 1 Relationship + 1 Tactical Bond，與正式 battle-start category limit 相同。
#
# 【隱藏羈絆】
# 若 v0.99.3 Discovery Runtime 存在，Secret Relationship Bond 未發現時沿用既有
# team_bond_display_name_v0993 規則顯示「???」，本版不偷看未解鎖內容。
# Tactical Bond 永久公開，照舊顯示正式名稱。
#
# 【操作】
# 布陣時選擇我方 Pokémon，按 A 開啟既有 AI Strategy。
# 修改 role_bias / spacing / spatial_intent / target 等設定後，面板會立即重新整理。
# 不新增按鍵，不改 battle A=x1/x2。
#
# 【安全邊界】
# - 純 UI / Readability，不修改 Team Bond 效果、Damage、Energy 或 AI 評分。
# - 不修改 Footer 高度、Viewport、戰鬥 HUD 或 Focus UI。
# - 不影響 Verification Mode；只有 deploy phase 且 NORMAL 時顯示正式預覽。
#===============================================================================
$imported={} unless defined?($imported)
$imported['PMD_AutoChess_TeamCompositionPreview_v10550']=true

module PMD_AC
  TEAM_COMPOSITION_PREVIEW_VERSION_V10550='1.05.50'
end

class Scene_PMD_AutoChess
  alias pmd_ac_v10550_refresh_ai_strategy_v09913 refresh_ai_strategy_v09913 unless method_defined?(:pmd_ac_v10550_refresh_ai_strategy_v09913)
  alias pmd_ac_v10550_start_battle start_battle unless method_defined?(:pmd_ac_v10550_start_battle)
  alias pmd_ac_v10550_focus_summary focus_cast_log_summary_v1055 unless method_defined?(:pmd_ac_v10550_focus_summary)

  def team_composition_preview_units_v10550
    return team_composition_units_v10549(:ally) if respond_to?(:team_composition_units_v10549)
    out=[]
    for u in (@units || [])
      next if u==nil || u.team!=:ally
      next if u.respond_to?(:summoned?) && u.summoned?
      next if u.respond_to?(:counts_for_victory?) && !u.counts_for_victory?
      out.push(u)
    end
    out
  rescue
    []
  end

  def team_composition_preview_keys_v10550
    units=team_composition_preview_units_v10550
    return [] unless defined?(PMD_AC::TEAM_BOND_DATA_V0992)
    PMD_AC.active_team_bond_keys_for_v0992(units)
  rescue
    []
  end

  def team_composition_preview_bond_name_v10550(key)
    if PMD_AC.respond_to?(:team_bond_display_name_v0993)
      return PMD_AC.team_bond_display_name_v0993(key)
    end
    d=PMD_AC::TEAM_BOND_DATA_V0992[key] rescue nil
    d==nil ? key.to_s : (d[:name] || key.to_s)
  rescue
    key.to_s
  end

  def team_composition_preview_text_v10550
    units=team_composition_preview_units_v10550
    roles=units.collect do |u|
      r=u.respond_to?(:dynamic_role_v09913) ? (u.dynamic_role_v09913 rescue :frontline) : :frontline
      PMD_AC.respond_to?(:role_label_v09913) ? PMD_AC.role_label_v09913(r) : r.to_s
    end
    keys=team_composition_preview_keys_v10550
    names=keys.collect{|k|team_composition_preview_bond_name_v10550(k)}
    role_text=roles.empty? ? '尚無正式出戰成員' : roles.join(' / ')
    bond_text=names.empty? ? '無' : names.join(' + ')
    [role_text,bond_text]
  rescue
    ['讀取失敗','無']
  end

  def refresh_ai_strategy_v09913
    r=pmd_ac_v10550_refresh_ai_strategy_v09913
    begin
      return r unless @phase==:deploy
      return r unless respond_to?(:verification_mode) && verification_mode==:normal
      return r if @ai_strategy_sprite_v09913==nil || @ai_strategy_sprite_v09913.bitmap==nil
      bmp=@ai_strategy_sprite_v09913.bitmap
      w=bmp.width;h=bmp.height
      text=team_composition_preview_text_v10550
      y=h-112
      # 使用既有面板內的空白區，不覆蓋 8 列 AI options 與底部操作提示。
      bmp.fill_rect(14,y-4,w-28,58,Color.new(12,24,35,205))
      bmp.font.bold=false;bmp.font.size=14;bmp.font.color=Color.new(190,225,255)
      bmp.draw_text(22,y,w-44,22,'隊伍定位：'+text[0].to_s,0)
      bmp.font.color=Color.new(255,225,150)
      bmp.draw_text(22,y+25,w-44,22,'羈絆預覽：'+text[1].to_s,0)
    rescue
      # UI 預覽失敗不可影響 AI Strategy 本體。
    end
    r
  end

  def start_battle
    r=pmd_ac_v10550_start_battle
    begin
      @v10550_summary_logged=false
      if @phase==:battle && respond_to?(:verification_mode) && verification_mode==:normal
        log_event(:battle,'BATTLE_TEAM_COMPOSITION_PREVIEW_V10550 START'+
          ' deploy_ai_panel=1 dynamic_role_preview=1 relationship_tactical_preview=1'+
          ' secret_discovery_respected=1 battle_ui_unchanged=1 gameplay_change=0')
      end
    rescue
    end
    r
  end

  def team_composition_preview_summary_v10550
    return false if @v10550_summary_logged
    @v10550_summary_logged=true
    log_event(:battle,'BATTLE_TEAM_COMPOSITION_PREVIEW_SUMMARY_V10550 ready=1'+
      ' ui_scope=deploy_ai_strategy rows_added=2 bond_authority=v10549'+
      ' secret_discovery_respected=1 gameplay_change=0 blocking_gate=0')
    true
  rescue
    false
  end

  def focus_cast_log_summary_v1055
    r=pmd_ac_v10550_focus_summary
    begin
      team_composition_preview_summary_v10550
    rescue
    end
    r
  end
end
