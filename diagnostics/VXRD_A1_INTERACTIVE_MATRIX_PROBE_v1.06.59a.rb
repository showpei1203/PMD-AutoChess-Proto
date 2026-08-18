# encoding: UTF-8
#===============================================================================
# ■ PMD AutoChess - VXRD A1 Interactive Water Matrix Probe
#   v1.06.59a TEST-ONLY DIAGNOSTIC
#-------------------------------------------------------------------------------
# Purpose:
# - Identify the exact native VX A1 visible-bottom / gravel-bottom water tile.
# - Render real RGSS2 Tilemap samples side-by-side without modifying Map090 data.
# - Formal baseline remains v1.06.58; no production Hunt water mapping changes.
#
# Controls (RMVX Test Play, H07 / Map090 only):
# - F5: open probe / advance page / close after last page.
# - The underlying H07 map remains the accepted v1.06.58 mapping (2240).
#
# Safety:
# - No map generation, no event relocation, no route rewrite, no Landmark change.
# - No B/C/D/E stamping.
# - Diagnostic source only; never promote this script directly to Formal Source.
#===============================================================================
$imported={} unless defined?($imported)
$imported['PMD_AutoChess_VXRDA1InteractiveWaterMatrixProbe_v10659a']=true

module PMD_AC
  VXRD_A1_MATRIX_PROBE_VERSION_V10659A='1.06.59a-PROBE'
  VXRD_A1_MATRIX_PROBE_LOG_V10659A='PMD_VXRD_A1MatrixProbe_LATEST.log'
  VXRD_A1_MATRIX_PROBE_CURRENT_BASE_V10659A=2240
  VXRD_A1_MATRIX_PROBE_PAGES_V10659A=[
    [2240,2288,2336,2384],
    [2048,2096,2144,2192],
    [2432,2480,2528,2576],
    [2624,2672,2720,2768]
  ]

  class << self
    def vxrd_a1_probe_h07_active_v10659a?
      return false unless $TEST
      return false if $game_map==nil || $game_map.map_id.to_i!=90
      s=phase_div_hunt_session_v10555 rescue nil
      s.is_a?(Hash) && s[:active] && s[:code].to_s.upcase=='H07'
    rescue
      false
    end

    def vxrd_a1_probe_tile_data_v10659a(base)
      w=4;h=4
      data=Table.new(w,h,3)
      mask=Array.new(w*h,true)
      for y in 0...h
        for x in 0...w
          v=vxrd_floor_variant_from_mask_v10589(mask,w,h,x,y)
          data[x,y,0]=base.to_i+v.to_i
          data[x,y,1]=0
          data[x,y,2]=0
        end
      end
      data
    rescue
      nil
    end

    def vxrd_a1_probe_static_audit_v10659a
      pages=VXRD_A1_MATRIX_PROBE_PAGES_V10659A
      flat=[];pages.each{|p|p.each{|x|flat << x.to_i}}
      bad=[]
      bad << :test_guard unless defined?($TEST)
      bad << :variant_helper unless respond_to?(:vxrd_floor_variant_from_mask_v10589)
      bad << :page_count unless pages.size==4
      bad << :candidate_count unless flat.size==16 && flat.uniq.size==16
      bad << :current_missing unless flat.include?(VXRD_A1_MATRIX_PROBE_CURRENT_BASE_V10659A)
      flat.each{|b|bad << ('invalid_base_'+b.to_s).to_sym unless b>=2048 && ((b-2048)%48)==0}
      {:pass=>bad.empty?,:pages=>pages.size,:candidates=>flat.size,
       :current=>VXRD_A1_MATRIX_PROBE_CURRENT_BASE_V10659A,
       :map_mutation=>false,:hunt_mapping_mutation=>false,:bcde_stamp=>false,:bad=>bad}
    rescue
      {:pass=>false,:pages=>0,:candidates=>0,:bad=>[:audit_error]}
    end

    def vxrd_a1_probe_write_log_v10659a(action,page=nil)
      a=vxrd_a1_probe_static_audit_v10659a
      pidx=page==nil ? -1:page.to_i
      bases=(pidx>=0 && pidx<VXRD_A1_MATRIX_PROBE_PAGES_V10659A.size) ? VXRD_A1_MATRIX_PROBE_PAGES_V10659A[pidx] : []
      lines=[]
      lines << 'PMD AutoChess VXRD A1 Interactive Matrix Probe v1.06.59a'
      lines << 'RESULT='+(a[:pass] ? 'PASS':'FAIL')
      lines << 'ACTION='+action.to_s
      lines << 'FRAME='+(Graphics.frame_count.to_i rescue 0).to_s
      lines << 'TEST_MODE='+($TEST ? '1':'0')
      lines << 'MAP_ID='+(($game_map==nil ? 0:$game_map.map_id).to_i).to_s
      lines << 'HUNT=H07'
      lines << 'FORMAL_BASELINE=v1.06.58'
      lines << 'FORMAL_H07_BASE=2240'
      lines << 'MAP_MUTATION=0'
      lines << 'HUNT_MAPPING_MUTATION=0'
      lines << 'BCDE_STAMP=0'
      lines << 'PAGE='+(pidx<0 ? 'NONE':(pidx+1).to_s+'/'+VXRD_A1_MATRIX_PROBE_PAGES_V10659A.size.to_s)
      lines << 'BASES='+bases.collect{|x|x.to_i.to_s}.join(',')
      lines << 'USER_ACTION=Press F5 to advance; report the base whose panel shows the desired gravel/pebble clear bottom.'
      (a[:bad]||[]).each{|x|lines << 'ERROR='+x.to_s}
      File.open(VXRD_A1_MATRIX_PROBE_LOG_V10659A,'ab'){|io|io.write(lines.join("\r\n")+"\r\nEND\r\n")}
      a
    rescue
      {:pass=>false}
    end
  end
end

class Scene_Map
  alias pmd_ac_v10659a_a1probe_update update unless method_defined?(:pmd_ac_v10659a_a1probe_update)
  alias pmd_ac_v10659a_a1probe_terminate terminate unless method_defined?(:pmd_ac_v10659a_a1probe_terminate)

  def vxrd_a1_probe_active_v10659a?
    @vxrd_a1_probe_active_v10659a==true
  end

  def vxrd_a1_probe_dispose_v10659a
    (@vxrd_a1_probe_tilemaps_v10659a||[]).each do |tm|
      begin;tm.dispose if tm!=nil;rescue;end
    end
    (@vxrd_a1_probe_viewports_v10659a||[]).each do |vp|
      begin;vp.dispose if vp!=nil && !vp.disposed?;rescue;end
    end
    if @vxrd_a1_probe_overlay_v10659a!=nil
      begin
        b=@vxrd_a1_probe_overlay_v10659a.bitmap
        b.dispose if b!=nil && !b.disposed?
      rescue
      end
      begin;@vxrd_a1_probe_overlay_v10659a.dispose unless @vxrd_a1_probe_overlay_v10659a.disposed?;rescue;end
    end
    @vxrd_a1_probe_tilemaps_v10659a=[]
    @vxrd_a1_probe_viewports_v10659a=[]
    @vxrd_a1_probe_overlay_v10659a=nil
    @vxrd_a1_probe_active_v10659a=false
  rescue
    @vxrd_a1_probe_active_v10659a=false
  end

  def vxrd_a1_probe_draw_overlay_v10659a
    @vxrd_a1_probe_overlay_v10659a=Sprite.new if @vxrd_a1_probe_overlay_v10659a==nil
    s=@vxrd_a1_probe_overlay_v10659a
    if s.bitmap==nil || s.bitmap.disposed?
      s.bitmap=Bitmap.new(Graphics.width,Graphics.height)
    end
    s.z=29990
    b=s.bitmap;b.clear
    b.fill_rect(0,0,Graphics.width,Graphics.height,Color.new(2,7,14,235))
    b.font.name=['Microsoft JhengHei','Arial']
    b.font.size=19;b.font.bold=true;b.font.color=Color.new(255,255,255)
    b.draw_text(8,5,Graphics.width-16,26,'VX A1 Water Matrix Probe  |  H07  |  TEST ONLY',1)
    b.font.size=12;b.font.bold=false;b.font.color=Color.new(185,205,225)
    b.draw_text(8,31,Graphics.width-16,18,'Formal H07 remains base 2240.  Panels below use the real RGSS2 Tilemap renderer.',1)
    page=@vxrd_a1_probe_page_v10659a.to_i
    bases=PMD_AC::VXRD_A1_MATRIX_PROBE_PAGES_V10659A[page] || []
    xs=[8,142,276,410]
    bases.each_with_index do |base,i|
      current=(base.to_i==PMD_AC::VXRD_A1_MATRIX_PROBE_CURRENT_BASE_V10659A)
      b.font.size=14;b.font.bold=true
      b.font.color=current ? Color.new(120,255,150) : Color.new(255,220,120)
      label='base '+base.to_i.to_s+' / kind '+((base.to_i-2048)/48).to_i.to_s
      label+='  CURRENT' if current
      b.draw_text(xs[i],55,126,20,label,1)
      b.fill_rect(xs[i]-1,78,130,130,current ? Color.new(80,210,110,170) : Color.new(80,120,160,150))
      b.fill_rect(xs[i]+1,80,126,126,Color.new(18,23,30,255))
    end
    b.font.size=12;b.font.bold=true;b.font.color=Color.new(255,255,255)
    b.draw_text(8,215,Graphics.width-16,20,'Page '+(page+1).to_s+'/'+PMD_AC::VXRD_A1_MATRIX_PROBE_PAGES_V10659A.size.to_s+'   F5 = next page / close after last page',1)
    b.font.size=11;b.font.bold=false;b.font.color=Color.new(190,210,230)
    b.draw_text(8,239,Graphics.width-16,18,'Find the panel with visible gravel/pebbles under clear water, then report its base number.',1)
    b.draw_text(8,259,Graphics.width-16,18,'No map regeneration, no event relocation, no route/landmark change, no production mapping mutation.',1)
  rescue
  end

  def vxrd_a1_probe_create_page_v10659a(page)
    vxrd_a1_probe_dispose_v10659a
    @vxrd_a1_probe_active_v10659a=true
    @vxrd_a1_probe_page_v10659a=page.to_i
    @vxrd_a1_probe_tilemaps_v10659a=[]
    @vxrd_a1_probe_viewports_v10659a=[]
    vxrd_a1_probe_draw_overlay_v10659a
    bases=PMD_AC::VXRD_A1_MATRIX_PROBE_PAGES_V10659A[@vxrd_a1_probe_page_v10659a] || []
    xs=[9,143,277,411]
    bases.each_with_index do |base,i|
      vp=Viewport.new(xs[i],81,126,126)
      vp.z=30000
      tm=Tilemap.new(vp)
      tm.bitmaps[0]=Cache.system('TileA1')
      tm.bitmaps[1]=Cache.system('TileA2')
      tm.bitmaps[2]=Cache.system('TileA3')
      tm.bitmaps[3]=Cache.system('TileA4')
      tm.bitmaps[4]=Cache.system('TileA5')
      tm.bitmaps[5]=Cache.system('TileB')
      tm.bitmaps[6]=Cache.system('TileC')
      tm.bitmaps[7]=Cache.system('TileD')
      tm.bitmaps[8]=Cache.system('TileE')
      tm.map_data=PMD_AC.vxrd_a1_probe_tile_data_v10659a(base)
      tm.passages=$game_map.passages
      tm.ox=1;tm.oy=1
      @vxrd_a1_probe_viewports_v10659a << vp
      @vxrd_a1_probe_tilemaps_v10659a << tm
    end
    PMD_AC.vxrd_a1_probe_write_log_v10659a('OPEN_PAGE',@vxrd_a1_probe_page_v10659a)
    begin;Sound.play_decision;rescue;end
  rescue
    vxrd_a1_probe_dispose_v10659a
  end

  def vxrd_a1_probe_handle_v10659a
    return false unless PMD_AC.vxrd_a1_probe_h07_active_v10659a?
    if Input.trigger?(Input::F5)
      if !vxrd_a1_probe_active_v10659a?
        vxrd_a1_probe_create_page_v10659a(0)
      else
        n=@vxrd_a1_probe_page_v10659a.to_i+1
        if n>=PMD_AC::VXRD_A1_MATRIX_PROBE_PAGES_V10659A.size
          PMD_AC.vxrd_a1_probe_write_log_v10659a('CLOSE_AFTER_LAST',@vxrd_a1_probe_page_v10659a)
          vxrd_a1_probe_dispose_v10659a
          begin;Sound.play_cancel;rescue;end
        else
          vxrd_a1_probe_create_page_v10659a(n)
        end
      end
      return true
    end
    false
  rescue
    false
  end

  def update
    pmd_ac_v10659a_a1probe_update
    if vxrd_a1_probe_active_v10659a? && !PMD_AC.vxrd_a1_probe_h07_active_v10659a?
      PMD_AC.vxrd_a1_probe_write_log_v10659a('AUTO_CLOSE_CONTEXT_EXIT',@vxrd_a1_probe_page_v10659a)
      vxrd_a1_probe_dispose_v10659a
      return
    end
    (@vxrd_a1_probe_tilemaps_v10659a||[]).each{|tm|begin;tm.update if tm!=nil;rescue;end}
    vxrd_a1_probe_handle_v10659a
  rescue
    pmd_ac_v10659a_a1probe_update
  end

  def terminate
    vxrd_a1_probe_dispose_v10659a
    pmd_ac_v10659a_a1probe_terminate
  end
end
