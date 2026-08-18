# encoding: UTF-8
#===============================================================================
# ■ PMD AutoChess - Hunt / Challenge UI Data Contract v1.05.80
#-------------------------------------------------------------------------------
# 只固定 UI 需要的資料欄位、排序與狀態語意，不決定框體 / 顏色 / 圖示 / 動畫。
# 後續正式 UI 直接消費這層，避免 Window 自己重新推導 gameplay Authority。
#===============================================================================
$imported={} unless defined?($imported)
$imported['PMD_AutoChess_HuntChallengeUIDataContract_v10580']=true

module PMD_AC
  HUNT_UI_LIST_FIELDS_V10580=[:code,:name,:tier,:biome,:level_min,:level_max,:ai_tier,
    :unlocked,:seen,:owned,:total,:active,:rarity,:economy,:badges]
  HUNT_UI_SPECIES_FIELDS_V10580=[:species,:dex,:name,:seen,:owned,:unlocked,:rarity,:role,:active]
  CHALLENGE_UI_LIST_FIELDS_V10580=[:code,:name,:level_min,:level_max,:ai_tier,:unlocked,:cleared,
    :legend_circuit,:reward_name,:reward_species,:reward_quality,:badges]

  class << self
    def hunt_ui_badges_v10580(code,info=nil)
      h=phase_div_hunt_v10553(code);return [] if h==nil
      a=[]
      a.push('T'+h[:tier].to_i.to_s)
      a.push('AI'+h[:ai_tier].to_i.to_s)
      a.push(h[:biome].to_s.upcase)
      a.push('ACTIVE') if info!=nil && !(info[:active_pool]||[]).empty?
      a
    rescue
      []
    end

    def hunt_ui_rows_v10580
      out=[]
      PHASE_DIV_HUNT_ORDER_V10553.each do |c|
        h=phase_div_hunt_v10553(c);info=hunt_collection_info(c)
        next if h==nil || info==nil
        unlocked=respond_to?(:phase_div_hunt_unlock_v10563) ? phase_div_hunt_unlock_v10563(c) : true
        out.push({:code=>c,:name=>h[:name].to_s,:tier=>h[:tier].to_i,:biome=>h[:biome].to_s,
          :level_min=>h[:level_min].to_i,:level_max=>h[:level_max].to_i,:ai_tier=>h[:ai_tier].to_i,
          :unlocked=>(unlocked ? true:false),:seen=>info[:seen].to_i,:owned=>info[:owned].to_i,
          :total=>info[:total].to_i,:active=>info[:active_pool]||[],:rarity=>info[:rarity]||{},
          :economy=>(respond_to?(:hunt_economy_info) ? hunt_economy_info(c) : nil),
          :badges=>hunt_ui_badges_v10580(c,info)})
      end
      out
    rescue
      []
    end

    def hunt_ui_species_rows_v10580(code)
      info=hunt_collection_info(code);return [] if info==nil
      active=info[:active_pool]||[]
      hunt_collection_rows(code).collect do |r|
        {:species=>r[:species],:dex=>r[:dex].to_i,:name=>r[:name].to_s,
         :seen=>(r[:seen] ? true:false),:owned=>(r[:owned] ? true:false),
         :unlocked=>(r[:unlocked] ? true:false),:rarity=>r[:rarity].to_s,
         :role=>r[:role].to_s,:active=>active.include?(r[:species])}
      end
    rescue
      []
    end

    def hunt_ui_detail_v10580(code)
      c=code.to_s.upcase;info=hunt_collection_info(c);return nil if info==nil
      h=phase_div_hunt_v10553(c);return nil if h==nil
      {:summary=>info,:species=>hunt_ui_species_rows_v10580(c),
       :economy=>(respond_to?(:hunt_economy_info) ? hunt_economy_info(c) : nil),
       :map_theme=>h[:rtp_theme].to_s,:unlock_text=>h[:unlock].to_s,
       :ui_visual_seal=>:deferred}
    rescue
      nil
    end

    def challenge_ui_badges_v10580(code,info)
      a=[]
      a.push('AI'+info[:ai_tier].to_i.to_s)
      a.push(info[:legend_circuit] ? 'LEGEND' : 'TACTICAL')
      a.push('CLEAR') if info[:cleared]
      a.push('LOCKED') unless info[:unlocked]
      a
    rescue
      []
    end

    def challenge_ui_rows_v10580
      out=[]
      PHASE_DIV_CHALLENGE_ORDER_V10553.each do |c|
        info=challenge_collection_info(c);next if info==nil
        rw=info[:fixed_reward]
        out.push({:code=>c,:name=>info[:name].to_s,:level_min=>info[:level_min].to_i,
          :level_max=>info[:level_max].to_i,:ai_tier=>info[:ai_tier].to_i,
          :unlocked=>(info[:unlocked] ? true:false),:cleared=>(info[:cleared] ? true:false),
          :legend_circuit=>(info[:legend_circuit] ? true:false),
          :reward_name=>(rw==nil ? '' : rw[:name].to_s),
          :reward_species=>(rw==nil ? nil : rw[:species].to_s),
          :reward_quality=>(rw==nil ? '' : rw[:quality].to_s),
          :badges=>challenge_ui_badges_v10580(c,info)})
      end
      out
    rescue
      []
    end

    def challenge_ui_detail_v10580(code)
      c=code.to_s.upcase;info=challenge_collection_info(c);return nil if info==nil
      row=challenge_ui_rows_v10580.find{|x|x[:code]==c}
      {:summary=>info,:list_row=>row,:reward=>info[:fixed_reward],
       :legend_circuit=>(info[:legend_circuit] ? true:false),:ui_visual_seal=>:deferred}
    rescue
      nil
    end

    def ui_data_contract_audit_v10580
      h=hunt_ui_rows_v10580;c=challenge_ui_rows_v10580;bad=[]
      bad.push('hunt_count') unless h.size==21
      bad.push('challenge_count') unless c.size==16
      bad.push('hunt_order') unless h.collect{|x|x[:code]}==PHASE_DIV_HUNT_ORDER_V10553
      bad.push('challenge_order') unless c.collect{|x|x[:code]}==PHASE_DIV_CHALLENGE_ORDER_V10553
      h.each do |r|
        HUNT_UI_LIST_FIELDS_V10580.each{|k|bad.push(r[:code].to_s+':'+k.to_s) unless r.has_key?(k)}
      end
      c.each do |r|
        CHALLENGE_UI_LIST_FIELDS_V10580.each{|k|bad.push(r[:code].to_s+':'+k.to_s) unless r.has_key?(k)}
      end
      {:pass=>bad.empty?,:hunts=>h.size,:challenges=>c.size,
       :hunt_fields=>HUNT_UI_LIST_FIELDS_V10580.size,:challenge_fields=>CHALLENGE_UI_LIST_FIELDS_V10580.size,:bad=>bad.uniq}
    rescue
      {:pass=>false,:hunts=>0,:challenges=>0,:hunt_fields=>0,:challenge_fields=>0,:bad=>['audit_error']}
    end
  end
end

class Scene_PMD_AutoChess
  alias pmd_ac_v10580_focus_summary focus_cast_log_summary_v1055 unless method_defined?(:pmd_ac_v10580_focus_summary)
  def focus_cast_log_summary_v1055
    r=pmd_ac_v10580_focus_summary
    begin
      a=PMD_AC.ui_data_contract_audit_v10580
      log_event(:battle,'BATTLE_PHASE_DIV_UI_DATA_CONTRACT_SUMMARY_V10580 pass='+(a[:pass] ? '1':'0')+
        ' hunts='+a[:hunts].to_i.to_s+'/21 challenges='+a[:challenges].to_i.to_s+'/16'+
        ' hunt_fields='+a[:hunt_fields].to_i.to_s+' challenge_fields='+a[:challenge_fields].to_i.to_s+
        ' stable_order=1 visual_style_deferred=1 errors=['+(a[:bad]||[]).join(',')+']')
    rescue
    end
    r
  end
end
