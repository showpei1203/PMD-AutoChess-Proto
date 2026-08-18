# encoding: UTF-8
#===============================================================================
# ■ PMD AutoChess - VX Native Random Dungeon Core v1.05.82
#-------------------------------------------------------------------------------
# 【用途】
# 直接在目前 RPG Maker VX Map 的 Table 上生成 BSP 房間／通路。
# 使用 VX 原生 RTP tile ID / autotile variant，不建立 PNG、Parallax 或第二套 Game_Map。
# 結構概念吸收使用者提供的 FS_RandomDungeon 與 dungeon.rvdata，但 Runtime Authority
# 仍維持現有 Scene_Map / Game_Map。
#===============================================================================
$imported={} unless defined?($imported)
$imported['PMD_AutoChess_VXNativeRandomDungeon_v10582']=true

class Game_System
  attr_accessor :pmd_vxrd_state_v10582
end

module PMD_AC
  # 使用者提供 dungeon.rvdata 的 VX RTP autotile pattern 概念重新整理。
  # [floor_autotile_base, wall_autotile_base, decor_a, decor_b]
  VXRD_RTP_PALETTES_V10582=[
    [1552,5888,77,82],[1553,5936,77,82],[1554,5984,77,82],[1555,6032,77,82],
    [1556,6080,77,82],[1557,6128,77,82],[1558,6176,77,82],[1559,6224,77,82],
    [1568,6656,77,82],[1569,6704,77,82],[1570,6752,77,82],[1571,6800,77,82],
    [1572,6848,77,82],[1573,6896,77,82],[1574,6944,77,82],[1575,6992,77,82],
    [1584,7424,536,528],[1585,7472,537,529],[1586,7520,538,530],[1587,7568,539,531],
    [1588,7616,540,532],[1589,7664,541,533],[1590,7712,542,534],[1591,7760,543,535]
  ]

  VXRD_BIOME_PALETTE_V10582={
    'forest'=>0,'water'=>8,'sky'=>4,'mountain'=>16,'mystic'=>20,'legend'=>23
  }

  class VXRD_RNG_V10582
    def initialize(seed)
      @state=seed.to_i & 0x7fffffff
      @state=10582 if @state==0
    end
    def rand(max=nil)
      @state=((@state*1103515245)+12345) & 0x7fffffff
      return @state if max==nil
      m=max.to_i
      return 0 if m<=1
      @state % m
    end
    def range(min,max)
      a=min.to_i;b=max.to_i
      a,b=b,a if a>b
      a+rand(b-a+1)
    end
  end

  class VXRD_Layout_V10582
    attr_reader :width,:height,:rooms,:edges,:entrance,:exit_pos,:walkable,:room_cells
    def initialize(width,height,seed,options)
      @width=width.to_i;@height=height.to_i;@seed=seed.to_i
      @rng=VXRD_RNG_V10582.new(@seed)
      @options=options || {}
      @grid=Array.new(@height){Array.new(@width,0)}
      @rooms=[];@edges=[];@walkable=[];@room_cells=[]
      @entrance=nil;@exit_pos=nil
    end
    def cell(x,y)
      return 0 if x<0 || y<0 || x>=@width || y>=@height
      @grid[y][x]
    end
    def floor?(x,y)
      cell(x,y)==1
    end
    def carve(x,y,room=false)
      return if x<1 || y<1 || x>=@width-1 || y>=@height-1
      @grid[y][x]=1
      @room_cells << [x,y] if room
    end
    def generate
      margin=[@options[:margin].to_i,2].max
      min_room=[@options[:min_room].to_i,4].max
      target=[@options[:room_count].to_i,3].max
      usable=[@width-margin*2,@height-margin*2]
      return false if usable[0] < min_room+4 || usable[1] < min_room+4
      rects=[[margin,margin,usable[0],usable[1]]]
      split_guard=0
      while rects.size<target && split_guard<target*30
        split_guard+=1
        idx=largest_splittable_rect(rects,min_room)
        break if idx==nil
        rect=rects.delete_at(idx)
        pair=split_rect(rect,min_room)
        if pair==nil
          rects << rect
          break
        end
        rects.concat(pair)
      end
      rects.each{|r|create_room(r,min_room)}
      return false if @rooms.size<2
      connect_rooms_tree
      add_extra_connections
      connect_fixed_positions
      choose_entrance_exit
      rebuild_walkable
      validate
    end
    def largest_splittable_rect(rects,min_room)
      need=min_room+4
      best=nil;area=-1
      rects.each_with_index do |r,i|
        next unless r[2]>=need*2 || r[3]>=need*2
        a=r[2]*r[3]
        if a>area;area=a;best=i;end
      end
      best
    end
    def split_rect(rect,min_room)
      x,y,w,h=rect
      need=min_room+4
      split_vertical = w>h ? true : (h>w ? false : @rng.rand(2)==0)
      if split_vertical && w>=need*2
        cut=@rng.range(need,w-need)
        return [[x,y,cut,h],[x+cut,y,w-cut,h]]
      elsif h>=need*2
        cut=@rng.range(need,h-need)
        return [[x,y,w,cut],[x,y+cut,w,h-cut]]
      elsif w>=need*2
        cut=@rng.range(need,w-need)
        return [[x,y,cut,h],[x+cut,y,w-cut,h]]
      end
      nil
    end
    def create_room(rect,min_room)
      x,y,w,h=rect
      pad=2
      maxw=[w-pad*2,min_room].max
      maxh=[h-pad*2,min_room].max
      rw=@rng.range(min_room,maxw)
      rh=@rng.range(min_room,maxh)
      rx=x+pad+@rng.rand([maxw-rw+1,1].max)
      ry=y+pad+@rng.rand([maxh-rh+1,1].max)
      room={:x=>rx,:y=>ry,:w=>rw,:h=>rh,:cx=>rx+rw/2,:cy=>ry+rh/2,:id=>@rooms.size}
      @rooms << room
      for yy in ry...(ry+rh)
        for xx in rx...(rx+rw)
          carve(xx,yy,true)
        end
      end
    end
    def room_distance(a,b)
      (a[:cx]-b[:cx]).abs+(a[:cy]-b[:cy]).abs
    end
    def edge_exists?(a,b)
      @edges.any?{|e|(e[0]==a && e[1]==b)||(e[0]==b && e[1]==a)}
    end
    def connect_rooms_tree
      connected=[0];remaining=(1...@rooms.size).to_a
      while !remaining.empty?
        best=nil;bestd=999999
        connected.each do |a|
          remaining.each do |b|
            d=room_distance(@rooms[a],@rooms[b])
            if d<bestd;bestd=d;best=[a,b];end
          end
        end
        break if best==nil
        connect_room_pair(best[0],best[1])
        connected << best[1]
        remaining.delete(best[1])
      end
    end
    def add_extra_connections
      pct=@options[:extra_connection_rate].to_i
      pct=20 if pct<=0
      @rooms.each_with_index do |room,i|
        nearest=[]
        @rooms.each_with_index{|r,j|nearest << [room_distance(room,r),j] if i!=j && !edge_exists?(i,j)}
        nearest.sort!{|a,b|a[0]<=>b[0]}
        nearest[0,2].to_a.each do |row|
          connect_room_pair(i,row[1]) if @rng.rand(100)<pct
        end
      end
    end
    def connect_room_pair(ai,bi)
      return if edge_exists?(ai,bi)
      a=@rooms[ai];b=@rooms[bi]
      width=[@options[:corridor_width].to_i,1].max
      if @rng.rand(2)==0
        carve_h(a[:cx],b[:cx],a[:cy],width)
        carve_v(a[:cy],b[:cy],b[:cx],width)
      else
        carve_v(a[:cy],b[:cy],a[:cx],width)
        carve_h(a[:cx],b[:cx],b[:cy],width)
      end
      @edges << [ai,bi]
    end
    def carve_h(x1,x2,y,width)
      a=x1<x2 ? x1 : x2;b=x1>x2 ? x1 : x2
      for x in a..b
        for o in 0...width;carve(x,y+o,false);end
      end
    end
    def carve_v(y1,y2,x,width)
      a=y1<y2 ? y1 : y2;b=y1>y2 ? y1 : y2
      for y in a..b
        for o in 0...width;carve(x+o,y,false);end
      end
    end
    def graph_distances(start)
      d={start=>0};q=[start]
      while !q.empty?
        cur=q.shift
        @edges.each do |e|
          n=e[0]==cur ? e[1] : (e[1]==cur ? e[0] : nil)
          next if n==nil || d.has_key?(n)
          d[n]=d[cur]+1;q << n
        end
      end
      d
    end
    def connect_fixed_positions
      list=@options[:fixed_positions]
      return if !list.is_a?(Array) || list.empty?
      list.each do |p|
        next unless p.is_a?(Array) && p.size>=2
        x=p[0].to_i;y=p[1].to_i
        next if x<2 || y<2 || x>=@width-2 || y>=@height-2
        for yy in (y-1)..(y+1)
          for xx in (x-1)..(x+1);carve(xx,yy,false);end
        end
        best=nil;bestd=999999
        @rooms.each_with_index do |r,i|
          d=(r[:cx]-x).abs+(r[:cy]-y).abs
          if d<bestd;bestd=d;best=i;end
        end
        next if best==nil
        r=@rooms[best]
        if @rng.rand(2)==0
          carve_h(x,r[:cx],y,1);carve_v(y,r[:cy],r[:cx],1)
        else
          carve_v(y,r[:cy],x,1);carve_h(x,r[:cx],r[:cy],1)
        end
      end
    end
    def choose_entrance_exit
      d0=graph_distances(0)
      a=d0.keys.sort{|x,y|d0[y]<=>d0[x]}[0] || 0
      da=graph_distances(a)
      b=da.keys.sort{|x,y|da[y]<=>da[x]}[0] || (@rooms.size-1)
      @entrance=[@rooms[a][:cx],@rooms[a][:cy]]
      @exit_pos=[@rooms[b][:cx],@rooms[b][:cy]]
    end
    def rebuild_walkable
      @walkable=[]
      for y in 0...@height
        for x in 0...@width
          @walkable << [x,y] if floor?(x,y)
        end
      end
    end
    def validate
      return false if @entrance==nil || @exit_pos==nil || @walkable.empty?
      seen={};q=[@entrance];seen[@entrance[1]*@width+@entrance[0]]=true
      dirs=[[1,0],[-1,0],[0,1],[0,-1]]
      while !q.empty?
        p=q.shift
        dirs.each do |d|
          nx=p[0]+d[0];ny=p[1]+d[1];idx=ny*@width+nx
          next unless floor?(nx,ny);next if seen[idx]
          seen[idx]=true;q << [nx,ny]
        end
      end
      return false unless seen[@exit_pos[1]*@width+@exit_pos[0]]
      @rooms.each{|r|return false unless seen[r[:cy]*@width+r[:cx]]}
      true
    end
  end

  class << self
    def vxrd_palette_index_v10582(code=nil,options=nil)
      o=options.is_a?(Hash) ? options : {}
      return o[:palette_index].to_i if o.has_key?(:palette_index)
      h=(code!=nil && respond_to?(:phase_div_hunt_v10553)) ? phase_div_hunt_v10553(code.to_s.upcase) : nil
      biome=h==nil ? 'forest' : h[:biome].to_s
      (VXRD_BIOME_PALETTE_V10582[biome] || 0).to_i
    rescue
      0
    end
    def vxrd_palette_v10582(code=nil,options=nil)
      idx=vxrd_palette_index_v10582(code,options)
      idx=0 if idx<0 || idx>=VXRD_RTP_PALETTES_V10582.size
      p=VXRD_RTP_PALETTES_V10582[idx]
      {:index=>idx,:floor=>p[0],:wall=>p[1],:decor_a=>p[2],:decor_b=>p[3]}
    end
    def vxrd_wall_neighbor_v10582(layout,x,y)
      return true if x<0 || y<0 || x>=layout.width || y>=layout.height
      !layout.floor?(x,y)
    end
    # dungeon.rvdata 的 VX autotile 連接概念重新實作：0..46 為 wall base variant。
    def vxrd_wall_variant_v10582(layout,x,y)
      l=!vxrd_wall_neighbor_v10582(layout,x-1,y)
      r=!vxrd_wall_neighbor_v10582(layout,x+1,y)
      u=!vxrd_wall_neighbor_v10582(layout,x,y-1)
      d=!vxrd_wall_neighbor_v10582(layout,x,y+1)
      missing=(l ? 1:0)+(r ? 1:0)+(u ? 1:0)+(d ? 1:0)
      if missing==0
        n=0
        n+=1 unless vxrd_wall_neighbor_v10582(layout,x-1,y-1)
        n+=2 unless vxrd_wall_neighbor_v10582(layout,x+1,y-1)
        n+=4 unless vxrd_wall_neighbor_v10582(layout,x+1,y+1)
        n+=8 unless vxrd_wall_neighbor_v10582(layout,x-1,y+1)
        return n
      elsif missing==1
        if l
          n=16;n+=1 unless vxrd_wall_neighbor_v10582(layout,x+1,y-1);n+=2 unless vxrd_wall_neighbor_v10582(layout,x+1,y+1);return n
        elsif u
          n=20;n+=1 unless vxrd_wall_neighbor_v10582(layout,x+1,y+1);n+=2 unless vxrd_wall_neighbor_v10582(layout,x-1,y+1);return n
        elsif r
          n=24;n+=1 unless vxrd_wall_neighbor_v10582(layout,x-1,y+1);n+=2 unless vxrd_wall_neighbor_v10582(layout,x-1,y-1);return n
        else
          n=28;n+=1 unless vxrd_wall_neighbor_v10582(layout,x-1,y-1);n+=2 unless vxrd_wall_neighbor_v10582(layout,x+1,y-1);return n
        end
      elsif missing==2
        if l
          return r ? 32 : (!u ? 40 : 34)
        else
          return !r ? 33 : (!u ? 38 : 36)
        end
      elsif missing==3
        return !d ? 42 : (!r ? 43 : (!u ? 44 : 45))
      end
      46
    rescue
      46
    end
    def vxrd_apply_layout_v10582(layout,palette)
      return false if $game_map==nil
      map=$game_map.instance_variable_get(:@map)
      return false if map==nil || map.data==nil
      data=map.data
      for y in 0...layout.height
        for x in 0...layout.width
          data[x,y,1]=0;data[x,y,2]=0
          if layout.floor?(x,y)
            data[x,y,0]=palette[:floor]
          else
            data[x,y,0]=palette[:wall]+vxrd_wall_variant_v10582(layout,x,y)
          end
        end
      end
      $game_map.need_refresh=true if $game_map.respond_to?(:need_refresh=)
      true
    rescue
      false
    end
    def vxrd_options_v10582(code,options=nil)
      o=options.is_a?(Hash) ? options.dup : {}
      h=respond_to?(:phase_div_hunt_v10553) ? phase_div_hunt_v10553(code.to_s.upcase) : nil
      tier=h==nil ? 1 : h[:tier].to_i
      o[:room_count]=[5+tier,10].min unless o.has_key?(:room_count)
      o[:min_room]=tier<=2 ? 5 : 4 unless o.has_key?(:min_room)
      o[:corridor_width]=tier<=2 ? 2 : 1 unless o.has_key?(:corridor_width)
      o[:extra_connection_rate]=tier<=2 ? 26 : 20 unless o.has_key?(:extra_connection_rate)
      o[:margin]=2 unless o.has_key?(:margin)
      o
    end
    def vxrd_generate_current_map_v10582(code=nil,seed=nil,options=nil)
      return nil if $game_map==nil || $game_system==nil
      c=code==nil ? (respond_to?(:hunt_info) && hunt_info!=nil ? hunt_info[:code].to_s : 'H01') : code.to_s.upcase
      o=vxrd_options_v10582(c,options)
      w=$game_map.width.to_i;h=$game_map.height.to_i
      return nil if w<20 || h<15
      base=seed==nil ? ((Graphics.frame_count.to_i+($game_map.map_id.to_i*7919)+10582)&0x7fffffff) : seed.to_i
      layout=nil;actual=base;attempt=0
      8.times do |i|
        actual=(base ^ ((i+1)*1103515245) ^ (i*12345)) & 0x7fffffff
        cand=VXRD_Layout_V10582.new(w,h,actual,o)
        if cand.generate;layout=cand;attempt=i+1;break;end
      end
      return nil if layout==nil
      pal=vxrd_palette_v10582(c,o)
      return nil unless vxrd_apply_layout_v10582(layout,pal)
      state={:active=>true,:code=>c,:map_id=>$game_map.map_id.to_i,:seed=>actual,:base_seed=>base,
        :attempt=>attempt,:width=>w,:height=>h,:palette=>pal,:options=>o,
        :entrance=>layout.entrance,:exit=>layout.exit_pos,:rooms=>layout.rooms,
        :edges=>layout.edges,:walkable=>layout.walkable,:room_cells=>layout.room_cells,
        :explored=>{},:generated_frame=>Graphics.frame_count.to_i}
      $game_system.pmd_vxrd_state_v10582=state
      if o[:move_player]!=false && $game_player!=nil && state[:entrance]!=nil
        $game_player.moveto(state[:entrance][0],state[:entrance][1])
        $game_player.center(state[:entrance][0],state[:entrance][1]) if $game_player.respond_to?(:center)
      end
      state
    rescue
      nil
    end
    def vxrd_state_v10582
      return nil if $game_system==nil
      $game_system.pmd_vxrd_state_v10582
    rescue
      nil
    end
    def vxrd_core_audit_v10582
      pal=VXRD_RTP_PALETTES_V10582
      {:pass=>pal.size==24 && VXRD_BIOME_PALETTE_V10582.size==6,
       :palettes=>pal.size,:biomes=>VXRD_BIOME_PALETTE_V10582.size,
       :png_generation=>false,:parallax_generation=>false,:second_game_map=>false}
    rescue
      {:pass=>false,:palettes=>0,:biomes=>0}
    end
  end
end
