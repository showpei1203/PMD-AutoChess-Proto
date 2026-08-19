# encoding: UTF-8
#===============================================================================
# ■ PMD AutoChess - v1.06.62b Gate 3 Floor-Depth Risk Windows Acceptance
#   TEST-ONLY
#-------------------------------------------------------------------------------
# Plain F5 on active Map090 Hunt. Read-only acceptance.
#===============================================================================
$imported={} unless defined?($imported)
$imported['PMD_AutoChess_Gate3FloorDepthRiskWindowsAcceptance_v10662b']=true

module PMD_AC
  GATE3_V10662B_LOG='PMD_GATE3_FloorDepthRisk_LATEST.log'
  class << self
    def gate3_v10662b_project_state
      bad=[];text=''
      begin
        write_project_state_log(true)
        File.open(PROJECT_STATE_FILE_V10564,'rb'){|io|text=io.read}
      rescue
        bad << :project_state_io
      end
      bad << :schema unless text =~ /^PROJECT_STATE_SCHEMA=43\r?$/
      bad << :version unless text =~ /^CURRENT_VERSION=1\.06\.62\r?$/
      {:pass=>bad.empty?,:bad=>bad}
    rescue
      {:pass=>false,:bad=>[:project_state_error]}
    end

    def gate3_v10662b_current_floor
      s=respond_to?(:hunt_runtime_session_v10605) ? hunt_runtime_session_v10605 : nil
      st=respond_to?(:vxrd_state_v10582) ? (vxrd_state_v10582 rescue nil) : nil
      return {:pass=>false,:bad=>[:no_active_map090]} if s==nil || st==nil || $game_map==nil || $game_map.map_id.to_i!=90
      meta=st[:room_type_meta_v10601]||{}
      tier=[[s[:tier].to_i,1].max,5].min
      floor=s[:vxrd_floor_count_v10584].to_i
      session_max=s[:vxrd_max_floors_v10604].to_i
      preview=(s[:style_preview_v10639] ? true:false)
      canonical_max=(respond_to?(:hunt_runtime_floor_limit_v10604) ?
        (hunt_runtime_floor_limit_v10604(s[:code]) rescue session_max) : session_max)
      canonical_max=session_max if canonical_max.to_i<=0
      max=preview ? canonical_max.to_i : session_max.to_i
      max=1 if max<=0
      br=VXRD_RARE_NEST_RATE_V10601[tier].to_i
      be=VXRD_ELITE_ROOM_RATE_V10601[tier].to_i
      er=vxrd_gate3_effective_rate_v10662(br,floor,max,:rare)
      ee=(tier>=2 ? vxrd_gate3_effective_rate_v10662(be,floor,max,:elite) : 0)
      bad=[]
      bad << :meta_floor unless meta[:floor_v10662].to_i==floor
      bad << :meta_max unless meta[:max_floor_v10662].to_i==max
      bad << :rare_rate unless meta[:rare_rate].to_i==er
      bad << :elite_rate unless meta[:elite_rate].to_i==ee
      bad << :extra_rng unless meta[:extra_rng_calls_v10662].to_i==0
      bad << :preview_session_max unless !preview || session_max.to_i==1
      {:pass=>bad.empty?,:code=>s[:code].to_s,:tier=>tier,:floor=>floor,:max_floor=>max,
       :session_max=>session_max.to_i,:canonical_max=>canonical_max.to_i,:style_preview=>(preview ? 1:0),
       :rare_base=>br,:rare_effective=>er,:elite_base=>be,:elite_effective=>ee,
       :rare_promoted=>(meta[:rare_promoted_v10662] ? 1:0),
       :elite_promoted=>(meta[:elite_promoted_v10662] ? 1:0),:bad=>bad}
    rescue Exception=>e
      {:pass=>false,:bad=>[:current_floor_error],:error=>e.class.to_s}
    end

    def gate3_v10662b_run
      before=nil;after=nil
      begin;s=hunt_runtime_session_v10605;before=Marshal.dump(s) unless s==nil;rescue;end
      static=vxrd_gate3_static_audit_v10662 rescue {:pass=>false,:bad=>[:static_missing]}
      current=gate3_v10662b_current_floor
      ps=gate3_v10662b_project_state
      begin;s=hunt_runtime_session_v10605;after=Marshal.dump(s) unless s==nil;rescue;end
      session_same=(before==after)
      bad=[]
      bad << :static unless static[:pass]
      bad << :current unless current[:pass]
      bad << :project_state unless ps[:pass]
      bad << :session_mutation unless session_same
      {:pass=>bad.empty?,:static=>static,:current=>current,:project_state=>ps,
       :session_same=>session_same,:rng_calls=>0,:map_regen=>0,:reward_grant=>0,:bad=>bad}
    rescue Exception=>e
      {:pass=>false,:bad=>[:harness_error],:error=>e.class.to_s}
    end

    def gate3_v10662b_write(r)
      c=r[:current]||{};s=r[:static]||{};p=r[:project_state]||{}
      lines=[]
      lines << 'PMD AutoChess v1.06.62b Gate 3 Floor-Depth Risk Windows Acceptance TEST-ONLY'
      lines << 'RESULT='+(r[:pass] ? 'PASS':'FAIL')
      lines << 'PRODUCTION_CANDIDATE=v1.06.62'
      lines << 'FORMAL_BASELINE=v1.06.61'
      lines << 'STATIC_CURVE='+(s[:pass] ? 'PASS':'FAIL')
      lines << 'CURRENT_FLOOR='+(c[:pass] ? 'PASS':'FAIL')
      lines << 'LIVE_HUNT='+c[:code].to_s
      lines << 'LIVE_TIER='+c[:tier].to_i.to_s
      lines << 'LIVE_FLOOR='+c[:floor].to_i.to_s+'/'+c[:max_floor].to_i.to_s
      lines << 'STYLE_PREVIEW='+c[:style_preview].to_i.to_s
      lines << 'SESSION_MAX_FLOOR='+c[:session_max].to_i.to_s
      lines << 'CANONICAL_MAX_FLOOR='+c[:canonical_max].to_i.to_s
      lines << 'PREVIEW_MAX_OVERRIDE_EXPECTED='+(c[:style_preview].to_i==1 ? '1':'0')
      lines << 'LIVE_RARE='+c[:rare_base].to_i.to_s+'->'+c[:rare_effective].to_i.to_s
      lines << 'LIVE_ELITE='+c[:elite_base].to_i.to_s+'->'+c[:elite_effective].to_i.to_s
      lines << 'LIVE_RARE_PROMOTED='+c[:rare_promoted].to_i.to_s
      lines << 'LIVE_ELITE_PROMOTED='+c[:elite_promoted].to_i.to_s
      lines << 'PROJECT_STATE='+(p[:pass] ? 'PASS':'FAIL')
      lines << 'PROJECT_STATE_SCHEMA=43'
      lines << 'CURRENT_VERSION=1.06.62'
      lines << 'RARE_FINAL_DEPTH_BONUS=12'
      lines << 'ELITE_FINAL_DEPTH_BONUS=15'
      lines << 'SPECIAL_RATE_CAP=85'
      lines << 'EXTRA_RNG_CALLS=0'
      lines << 'MAP_REGEN=0'
      lines << 'REWARD_GRANT=0'
      lines << 'SESSION_MUTATION='+(r[:session_same] ? '0':'1')
      lines << 'COMPLETION_BONUS_POLICY=UNCHANGED_2_2_3_4_4'
      lines << 'SETTLEMENT_VISIBILITY=EXPANDED_EXISTING_FIELDS_ONLY'
      (s[:curve]||{}).keys.sort.each do |tier|
        rows=(s[:curve][tier]||[]).collect{|x|'F'+x[0].to_i.to_s+':R'+x[1].to_i.to_s+'/E'+x[2].to_i.to_s}
        lines << 'TIER'+tier.to_i.to_s+'_CURVE='+rows.join(',')
      end
      [s,c,p].each{|h|(h[:bad]||[]).each{|x|lines << 'DETAIL_ERROR='+x.to_s}}
      (r[:bad]||[]).each{|x|lines << 'ERROR='+x.to_s}
      File.open(GATE3_V10662B_LOG,'wb'){|io|io.write(lines.join("\r\n")+"\r\n")}
      r
    rescue
      r
    end
  end
end

class Scene_Map
  alias pmd_ac_v10662b_gate3_update update unless method_defined?(:pmd_ac_v10662b_gate3_update)
  alias pmd_ac_v10662b_gate3_terminate terminate unless method_defined?(:pmd_ac_v10662b_gate3_terminate)
  def gate3_v10662b_dispose
    if @gate3_v10662b_sprite!=nil
      begin;b=@gate3_v10662b_sprite.bitmap;b.dispose if b!=nil && !b.disposed?;rescue;end
      begin;@gate3_v10662b_sprite.dispose unless @gate3_v10662b_sprite.disposed?;rescue;end
    end
    @gate3_v10662b_sprite=nil;@gate3_v10662b_frames=0
  rescue
  end
  def gate3_v10662b_show(r)
    gate3_v10662b_dispose
    s=Sprite.new;s.bitmap=Bitmap.new(Graphics.width,Graphics.height);s.z=31500;b=s.bitmap
    b.fill_rect(0,0,Graphics.width,Graphics.height,Color.new(2,7,13,235))
    b.font.name=['Microsoft JhengHei','Arial'];b.font.size=22;b.font.bold=true
    b.font.color=r[:pass] ? Color.new(110,255,145):Color.new(255,110,110)
    b.draw_text(8,18,Graphics.width-16,30,'Gate 3 Floor-Depth Risk  '+(r[:pass] ? 'PASS':'FAIL'),1)
    b.font.bold=false;b.font.size=18;b.font.color=Color.new(225,235,245)
    c=r[:current]||{};y=80
    rows=['Static Curve: '+((r[:static]||{})[:pass] ? 'PASS':'FAIL'),
      'Live: '+c[:code].to_s+'  Tier '+c[:tier].to_i.to_s+'  Floor '+c[:floor].to_i.to_s+'/'+c[:max_floor].to_i.to_s,
      'Rare: '+c[:rare_base].to_i.to_s+'% -> '+c[:rare_effective].to_i.to_s+'%',
      'Elite: '+c[:elite_base].to_i.to_s+'% -> '+c[:elite_effective].to_i.to_s+'%',
      'Extra RNG: 0   Session Mutation: '+(r[:session_same] ? '0':'1'),
      'Completion Bonus: unchanged   Settlement: expanded',
      'ProjectState: '+((r[:project_state]||{})[:pass] ? 'PASS':'FAIL')+'  v1.06.62']
    rows.each{|t|b.draw_text(20,y,Graphics.width-40,28,t);y+=36}
    b.font.size=15;b.font.color=Color.new(170,195,215)
    b.draw_text(16,Graphics.height-58,Graphics.width-32,24,'LOG: '+PMD_AC::GATE3_V10662B_LOG,1)
    @gate3_v10662b_sprite=s;@gate3_v10662b_frames=360
  rescue
  end
  def update
    pmd_ac_v10662b_gate3_update
    if @gate3_v10662b_frames.to_i>0
      @gate3_v10662b_frames-=1
      gate3_v10662b_dispose if @gate3_v10662b_frames.to_i<=0
    end
    plain=false
    begin
      plain=$TEST && Input.trigger?(Input::F5) &&
        !(Input.press?(Input::SHIFT) rescue false) &&
        !(Input.press?(Input::CTRL) rescue false) &&
        !(Input.press?(Input::ALT) rescue false)
    rescue;plain=false;end
    if plain
      r=PMD_AC.gate3_v10662b_run
      PMD_AC.gate3_v10662b_write(r)
      gate3_v10662b_show(r)
    end
  rescue
    pmd_ac_v10662b_gate3_update
  end
  def terminate
    gate3_v10662b_dispose
    pmd_ac_v10662b_gate3_terminate
  end
end
