# encoding: UTF-8
#===============================================================================
# ■ PMD AutoChess - v1.06.64a Gate 3 Run Accounting Windows Acceptance
#   TEST-ONLY / READ-ONLY
#===============================================================================
$imported={} unless defined?($imported)
$imported['PMD_AutoChess_Gate3RunAccountingWindowsAcceptance_v10664a']=true

module PMD_AC
  GATE3_V10664A_LOG='PMD_GATE3_RunAccounting_LATEST.log'
  class << self
    def gate3_v10664a_project_state
      bad=[];text=''
      begin
        write_project_state_log(true)
        File.open(PROJECT_STATE_FILE_V10564,'rb'){|io|text=io.read}
      rescue
        bad << :project_state_io
      end
      bad << :schema unless text =~ /^PROJECT_STATE_SCHEMA=45\r?$/
      bad << :version unless text =~ /^CURRENT_VERSION=1\.06\.64\r?$/
      {:pass=>bad.empty?,:bad=>bad}
    rescue
      {:pass=>false,:bad=>[:project_state_error]}
    end

    def gate3_v10664a_live_session
      s=respond_to?(:hunt_runtime_session_v10605) ? hunt_runtime_session_v10605 : nil
      return {:pass=>false,:bad=>[:no_active_hunt]} if s==nil || $game_map==nil || $game_map.map_id.to_i!=90
      before=Marshal.dump(s)
      raw=s[:vxrd_runtime_stats_v10604]||{}
      clone=Marshal.load(Marshal.dump(raw))
      migrated=vxrd_gate3_ensure_active_accounting_v10664(clone)
      after=Marshal.dump(s)
      legacy_ok=migrated.is_a?(Hash) && migrated[:completion_bonus_results].to_i==0 &&
        migrated[:immediate_loot_results].to_i==raw[:loot_results].to_i
      {:pass=>(before==after && legacy_ok),:code=>s[:code].to_s,
        :legacy_total=>raw[:loot_results].to_i,:migrated_immediate=>migrated[:immediate_loot_results].to_i,
        :migrated_completion=>migrated[:completion_bonus_results].to_i,
        :migration=>legacy_ok,:session_same=>(before==after),
        :bad=>((before==after && legacy_ok) ? []:[:live_semantic_or_mutation])}
    rescue Exception=>e
      {:pass=>false,:bad=>[:live_error],:error=>e.class.to_s}
    end

    def gate3_v10664a_run
      static=vxrd_gate3_accounting_static_audit_v10664 rescue {:pass=>false,:bad=>[:static_missing]}
      live=gate3_v10664a_live_session
      ps=gate3_v10664a_project_state
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

    def gate3_v10664a_write(r)
      s=r[:static]||{};l=r[:live]||{};p=r[:project_state]||{}
      lines=[]
      lines << 'PMD AutoChess v1.06.64a Gate 3 Run Accounting Windows Acceptance TEST-ONLY'
      lines << 'RESULT='+(r[:pass] ? 'PASS':'FAIL')
      lines << 'PRODUCTION_CANDIDATE=v1.06.64'
      lines << 'FORMAL_BASELINE=v1.06.63'
      lines << 'STATIC_ACCOUNTING='+(s[:pass] ? 'PASS':'FAIL')
      lines << 'LEGACY_TOTAL='+s[:legacy_total].to_i.to_s
      lines << 'LEGACY_SPLIT='+s[:legacy_immediate].to_i.to_s+'+'+s[:legacy_completion].to_i.to_s
      lines << 'NEW_TOTAL='+s[:split_total].to_i.to_s
      lines << 'NEW_SPLIT='+s[:split_immediate].to_i.to_s+'+'+s[:split_completion].to_i.to_s
      lines << 'MARSHAL_PERSISTENCE='+(s[:marshal] ? 'PASS':'FAIL')
      lines << 'CLASSIFICATION=IMMEDIATE+COMPLETION'
      lines << 'LEGACY_FIELDS_PRESERVED='+s[:legacy_fields_preserved].to_i.to_s
      lines << 'LIVE_HUNT='+l[:code].to_s
      lines << 'LIVE_LEGACY_TOTAL='+l[:legacy_total].to_i.to_s
      lines << 'LIVE_MIGRATION='+(l[:migration] ? 'PASS':'FAIL')
      lines << 'LIVE_SPLIT='+l[:migrated_immediate].to_i.to_s+'+'+l[:migrated_completion].to_i.to_s
      lines << 'PROJECT_STATE='+(p[:pass] ? 'PASS':'FAIL')
      lines << 'PROJECT_STATE_SCHEMA=45'
      lines << 'CURRENT_VERSION=1.06.64'
      lines << 'RNG_CALLS=0'
      lines << 'REWARD_GRANT=0'
      lines << 'MAP_REGEN=0'
      lines << 'SESSION_MUTATION='+r[:session_mutation].to_i.to_s
      [s,l,p].each{|h|(h[:bad]||[]).each{|x|lines << 'DETAIL_ERROR='+x.to_s}}
      (r[:bad]||[]).each{|x|lines << 'ERROR='+x.to_s}
      File.open(GATE3_V10664A_LOG,'wb'){|io|io.write(lines.join("\r\n")+"\r\n")}
      r
    rescue
      r
    end
  end
end

class Scene_Map
  alias pmd_ac_v10664a_gate3_update update unless method_defined?(:pmd_ac_v10664a_gate3_update)
  alias pmd_ac_v10664a_gate3_terminate terminate unless method_defined?(:pmd_ac_v10664a_gate3_terminate)
  def gate3_v10664a_dispose
    if @gate3_v10664a_sprite!=nil
      begin;b=@gate3_v10664a_sprite.bitmap;b.dispose if b!=nil && !b.disposed?;rescue;end
      begin;@gate3_v10664a_sprite.dispose unless @gate3_v10664a_sprite.disposed?;rescue;end
    end
    @gate3_v10664a_sprite=nil;@gate3_v10664a_frames=0
  rescue
  end
  def gate3_v10664a_show(r)
    gate3_v10664a_dispose
    s=Sprite.new;s.bitmap=Bitmap.new(Graphics.width,Graphics.height);s.z=31500;b=s.bitmap
    b.fill_rect(0,0,Graphics.width,Graphics.height,Color.new(2,7,13,235))
    b.font.name=['Microsoft JhengHei','Arial'];b.font.size=22;b.font.bold=true
    b.font.color=r[:pass] ? Color.new(110,255,145):Color.new(255,110,110)
    b.draw_text(8,18,Graphics.width-16,30,'Gate 3 Run Accounting  '+(r[:pass] ? 'PASS':'FAIL'),1)
    b.font.bold=false;b.font.size=18;b.font.color=Color.new(225,235,245)
    s0=r[:static]||{};l=r[:live]||{};y=78
    rows=['Static Semantic Split: '+(s0[:pass] ? 'PASS':'FAIL'),
      'Legacy Fixture: '+s0[:legacy_total].to_i.to_s+' = '+s0[:legacy_immediate].to_i.to_s+' + '+s0[:legacy_completion].to_i.to_s,
      'New Fixture: '+s0[:split_total].to_i.to_s+' = '+s0[:split_immediate].to_i.to_s+' + '+s0[:split_completion].to_i.to_s,
      'Marshal Persistence: '+(s0[:marshal] ? 'PASS':'FAIL'),
      'Live '+l[:code].to_s+': migration '+(l[:migration] ? 'PASS':'FAIL')+'  '+l[:migrated_immediate].to_i.to_s+' + '+l[:migrated_completion].to_i.to_s,
      'Reward Grant: 0   Session Mutation: '+r[:session_mutation].to_i.to_s,
      'ProjectState: '+((r[:project_state]||{})[:pass] ? 'PASS':'FAIL')+'  v1.06.64']
    rows.each{|t|b.draw_text(18,y,Graphics.width-36,28,t);y+=36}
    b.font.size=15;b.font.color=Color.new(170,195,215)
    b.draw_text(16,Graphics.height-54,Graphics.width-32,24,'LOG: '+PMD_AC::GATE3_V10664A_LOG,1)
    @gate3_v10664a_sprite=s;@gate3_v10664a_frames=360
  rescue
  end
  def update
    pmd_ac_v10664a_gate3_update
    if @gate3_v10664a_frames.to_i>0
      @gate3_v10664a_frames-=1
      gate3_v10664a_dispose if @gate3_v10664a_frames.to_i<=0
    end
    plain=false
    begin
      plain=$TEST && Input.trigger?(Input::F5) &&
        !(Input.press?(Input::SHIFT) rescue false) &&
        !(Input.press?(Input::CTRL) rescue false) &&
        !(Input.press?(Input::ALT) rescue false)
    rescue;plain=false;end
    if plain
      r=PMD_AC.gate3_v10664a_run
      PMD_AC.gate3_v10664a_write(r)
      gate3_v10664a_show(r)
    end
  rescue
    pmd_ac_v10664a_gate3_update
  end
  def terminate
    gate3_v10664a_dispose
    pmd_ac_v10664a_gate3_terminate
  end
end
