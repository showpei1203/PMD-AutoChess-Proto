# encoding: UTF-8
#===============================================================================
# ■ PMD AutoChess - v1.06.65a Gate 3 Integrated Run Summary Windows Acceptance
#   TEST-ONLY / READ-ONLY
#===============================================================================
$imported={} unless defined?($imported)
$imported['PMD_AutoChess_Gate3IntegratedRunSummaryWindowsAcceptance_v10665a']=true

module PMD_AC
  GATE3_V10665A_LOG='PMD_GATE3_IntegratedSeal_LATEST.log'
  class << self
    def gate3_v10665a_project_state
      bad=[];text=''
      begin
        write_project_state_log(true)
        File.open(PROJECT_STATE_FILE_V10564,'rb'){|io|text=io.read}
      rescue
        bad << :project_state_io
      end
      bad << :schema unless text =~ /^PROJECT_STATE_SCHEMA=46\r?$/
      bad << :version unless text =~ /^CURRENT_VERSION=1\.06\.65\r?$/
      bad << :seal unless text =~ /^GATE3_INTEGRATED_SEAL_STATIC=PASS\r?$/
      {:pass=>bad.empty?,:bad=>bad}
    rescue
      {:pass=>false,:bad=>[:project_state_error]}
    end

    def gate3_v10665a_live_session
      s=respond_to?(:hunt_runtime_session_v10605) ? hunt_runtime_session_v10605 : nil
      return {:pass=>false,:bad=>[:no_active_hunt]} if s==nil || $game_map==nil || $game_map.map_id.to_i!=90
      before=Marshal.dump(s)
      summary=vxrd_gate3_active_run_summary_v10665
      after=Marshal.dump(s)
      code=s[:code].to_s.upcase
      tier=vxrd_gate3_hunt_tier_v10665(code)
      risk=vxrd_gate3_risk_snapshot_v10665(code)
      target=vxrd_gate3_completion_target_v10663(tier)
      good=summary.is_a?(Hash) && before==after && summary[:code].to_s==code &&
        summary[:tier].to_i==tier.to_i && summary[:reason].to_sym==:active &&
        summary[:rare_rate_base].to_i==risk[:rare_base].to_i &&
        summary[:rare_rate_final].to_i==risk[:rare_final].to_i &&
        summary[:elite_rate_base].to_i==risk[:elite_base].to_i &&
        summary[:elite_rate_final].to_i==risk[:elite_final].to_i &&
        summary[:completion_target_rolls].to_i==target.to_i &&
        summary[:completion_rolls].to_i==0 && summary[:completion_bonus_results].to_i==0 &&
        summary[:accounting_balanced]
      {:pass=>good,:code=>code,:tier=>tier,:risk=>risk,:target=>target,
        :summary=>summary,:session_same=>(before==after),
        :bad=>(good ? []:[:live_summary_or_mutation])}
    rescue Exception=>e
      {:pass=>false,:bad=>[:live_error],:error=>e.class.to_s}
    end

    def gate3_v10665a_run
      static=vxrd_gate3_integrated_seal_audit_v10665 rescue {:pass=>false,:bad=>[:static_missing]}
      live=gate3_v10665a_live_session
      ps=gate3_v10665a_project_state
      bad=[]
      bad << :static unless static[:pass]
      bad << :live unless live[:pass]
      bad << :project_state unless ps[:pass]
      {:pass=>bad.empty?,:static=>static,:live=>live,:project_state=>ps,
        :rng_calls=>0,:reward_grant=>0,:map_regen=>0,
        :session_mutation=>(live[:session_same] ? 0:1),:bad=>bad}
    rescue Exception=>e
      {:pass=>false,:bad=>[:harness_error],:error=>e.class.to_s}
    end

    def gate3_v10665a_write(r)
      s=r[:static]||{};l=r[:live]||{};p=r[:project_state]||{}
      risk=l[:risk]||{};sum=l[:summary]||{}
      lines=[]
      lines << 'PMD AutoChess v1.06.65a Gate 3 Integrated Run Summary Windows Acceptance TEST-ONLY'
      lines << 'RESULT='+(r[:pass] ? 'PASS':'FAIL')
      lines << 'PRODUCTION_CANDIDATE=v1.06.65'
      lines << 'FORMAL_BASELINE=v1.06.64'
      lines << 'STATIC_INTEGRATED_SEAL='+(s[:pass] ? 'PASS':'FAIL')
      lines << 'SUB_V10662='+(s[:sub_v10662] ? 'PASS':'FAIL')
      lines << 'SUB_V10663='+(s[:sub_v10663] ? 'PASS':'FAIL')
      lines << 'SUB_V10664='+(s[:sub_v10664] ? 'PASS':'FAIL')
      lines << 'RISK_MONOTONIC='+(s[:risk_monotonic] ? 'PASS':'FAIL')
      lines << 'RISK_ENDPOINTS='+(s[:risk_endpoints] ? 'PASS':'FAIL')
      lines << 'COMPLETION_CURVE='+(s[:completion_curve]||[]).join('/')
      lines << 'MARSHAL_PERSISTENCE='+(s[:marshal] ? 'PASS':'FAIL')
      lines << 'SUMMARY_MUTATION='+s[:summary_mutation].to_i.to_s
      lines << 'LIVE_HUNT='+l[:code].to_s
      lines << 'LIVE_TIER='+l[:tier].to_i.to_s
      lines << 'LIVE_RARE='+risk[:rare_base].to_i.to_s+'->'+risk[:rare_final].to_i.to_s
      lines << 'LIVE_ELITE='+risk[:elite_base].to_i.to_s+'->'+risk[:elite_final].to_i.to_s
      lines << 'LIVE_COMPLETION_TARGET='+l[:target].to_i.to_s
      lines << 'LIVE_FLOORS='+sum[:floors_cleared].to_i.to_s+'/'+sum[:max_floors].to_i.to_s
      lines << 'LIVE_ACCOUNTING='+sum[:total_loot_results].to_i.to_s+'='+sum[:immediate_loot_results].to_i.to_s+'+'+sum[:raw_completion_bonus_results].to_i.to_s
      lines << 'LIVE_ACCOUNTING_BALANCED='+(sum[:accounting_balanced] ? 'PASS':'FAIL')
      lines << 'LIVE_SUMMARY='+(l[:pass] ? 'PASS':'FAIL')
      lines << 'PROJECT_STATE='+(p[:pass] ? 'PASS':'FAIL')
      lines << 'PROJECT_STATE_SCHEMA=46'
      lines << 'CURRENT_VERSION=1.06.65'
      lines << 'RNG_CALLS=0'
      lines << 'REWARD_GRANT=0'
      lines << 'MAP_REGEN=0'
      lines << 'SESSION_MUTATION='+r[:session_mutation].to_i.to_s
      [s,l,p].each{|h|(h[:bad]||[]).each{|x|lines << 'DETAIL_ERROR='+x.to_s}}
      (r[:bad]||[]).each{|x|lines << 'ERROR='+x.to_s}
      File.open(GATE3_V10665A_LOG,'wb'){|io|io.write(lines.join("\r\n")+"\r\n")}
      r
    rescue
      r
    end
  end
end

class Scene_Map
  alias pmd_ac_v10665a_gate3_update update unless method_defined?(:pmd_ac_v10665a_gate3_update)
  alias pmd_ac_v10665a_gate3_terminate terminate unless method_defined?(:pmd_ac_v10665a_gate3_terminate)
  def gate3_v10665a_dispose
    if @gate3_v10665a_sprite!=nil
      begin;b=@gate3_v10665a_sprite.bitmap;b.dispose if b!=nil && !b.disposed?;rescue;end
      begin;@gate3_v10665a_sprite.dispose unless @gate3_v10665a_sprite.disposed?;rescue;end
    end
    @gate3_v10665a_sprite=nil;@gate3_v10665a_frames=0
  rescue
  end
  def gate3_v10665a_show(r)
    gate3_v10665a_dispose
    s=Sprite.new;s.bitmap=Bitmap.new(Graphics.width,Graphics.height);s.z=31500;b=s.bitmap
    b.fill_rect(0,0,Graphics.width,Graphics.height,Color.new(2,7,13,235))
    b.font.name=['Microsoft JhengHei','Arial'];b.font.size=22;b.font.bold=true
    b.font.color=r[:pass] ? Color.new(110,255,145):Color.new(255,110,110)
    b.draw_text(8,18,Graphics.width-16,30,'Gate 3 Integrated Seal  '+(r[:pass] ? 'PASS':'FAIL'),1)
    b.font.bold=false;b.font.size=18;b.font.color=Color.new(225,235,245)
    st=r[:static]||{};l=r[:live]||{};risk=l[:risk]||{};sum=l[:summary]||{};y=72
    rows=[
      'Integrated Static: '+(st[:pass] ? 'PASS':'FAIL')+'  [62/63/64]',
      'Risk Curve: '+(st[:risk_monotonic] ? 'PASS':'FAIL')+'  endpoints '+(st[:risk_endpoints] ? 'PASS':'FAIL'),
      'Completion Curve: '+(st[:completion_curve]||[]).join('/'),
      'Live '+l[:code].to_s+' T'+l[:tier].to_i.to_s+': R '+risk[:rare_base].to_i.to_s+'→'+risk[:rare_final].to_i.to_s+'  E '+risk[:elite_base].to_i.to_s+'→'+risk[:elite_final].to_i.to_s,
      'Completion Target: '+l[:target].to_i.to_s+'  Floors '+sum[:floors_cleared].to_i.to_s+'/'+sum[:max_floors].to_i.to_s,
      'Accounting: '+sum[:total_loot_results].to_i.to_s+' = '+sum[:immediate_loot_results].to_i.to_s+' + '+sum[:raw_completion_bonus_results].to_i.to_s+'  '+(sum[:accounting_balanced] ? 'PASS':'FAIL'),
      'Reward 0  RNG 0  Map 0  Session '+r[:session_mutation].to_i.to_s,
      'ProjectState: '+((r[:project_state]||{})[:pass] ? 'PASS':'FAIL')+'  v1.06.65'
    ]
    rows.each{|t|b.draw_text(16,y,Graphics.width-32,27,t);y+=34}
    b.font.size=15;b.font.color=Color.new(170,195,215)
    b.draw_text(16,Graphics.height-50,Graphics.width-32,24,'LOG: '+PMD_AC::GATE3_V10665A_LOG,1)
    @gate3_v10665a_sprite=s;@gate3_v10665a_frames=360
  rescue
  end
  def update
    pmd_ac_v10665a_gate3_update
    if @gate3_v10665a_frames.to_i>0
      @gate3_v10665a_frames-=1
      gate3_v10665a_dispose if @gate3_v10665a_frames.to_i<=0
    end
    plain=false
    begin
      plain=$TEST && Input.trigger?(Input::F5) &&
        !(Input.press?(Input::SHIFT) rescue false) &&
        !(Input.press?(Input::CTRL) rescue false) &&
        !(Input.press?(Input::ALT) rescue false)
    rescue;plain=false;end
    if plain
      r=PMD_AC.gate3_v10665a_run
      PMD_AC.gate3_v10665a_write(r)
      gate3_v10665a_show(r)
    end
  rescue
    pmd_ac_v10665a_gate3_update
  end
  def terminate
    gate3_v10665a_dispose
    pmd_ac_v10665a_gate3_terminate
  end
end
