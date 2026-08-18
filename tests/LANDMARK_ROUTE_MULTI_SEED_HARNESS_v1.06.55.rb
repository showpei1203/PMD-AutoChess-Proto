# encoding: UTF-8
# Offline deterministic route-safety regression for PMD AutoChess v1.06.55.
# Does not touch RPG Maker VX Data files or runtime maps.

class Game_System; end unless defined?(Game_System)
module PMD_AC; end unless defined?(PMD_AC)
load '/mnt/data/pmd_v10654_src/0567__id_99630079.rb'
module PMD_AC
  class << self
    def hunt_generate_vx_floor_v10584(*args); nil; end unless method_defined?(:hunt_generate_vx_floor_v10584)
    def write_project_state_log(*args); true; end unless method_defined?(:write_project_state_log)
  end
end
load '/mnt/data/0640__id_1065500.rb'

HUNTS=['H01','H04','H09','H14','H19']
SEEDS=[10655,21011,31469,41927,52391,62851,73309,83777]

def room_contains?(r,p)
  p[0]>=r[:x] && p[0]<r[:x]+r[:w] && p[1]>=r[:y] && p[1]<r[:y]+r[:h]
end

def inner_candidates(layout, room, entrance, exit_pos)
  x0=room[:x]+1; y0=room[:y]+1
  x1=room[:x]+room[:w]-2; y1=room[:y]+room[:h]-2
  pts=[]
  return pts if x1<x0 || y1<y0
  (x0..x1).each{|x|pts << [x,y0] << [x,y1]}
  (y0..y1).each{|y|pts << [x0,y] << [x1,y]}
  seen={}
  pts.find_all do |p|
    next false if seen[p]; seen[p]=true
    next false unless layout.floor?(p[0],p[1])
    next false if (p[0]-room[:cx]).abs<=1 || (p[1]-room[:cy]).abs<=1
    next false if (p[0]-entrance[0]).abs+(p[1]-entrance[1]).abs<=2
    next false if (p[0]-exit_pos[0]).abs+(p[1]-exit_pos[1]).abs<=2
    true
  end
end

rows=[]; failures=[]
HUNTS.each_with_index do |code,hi|
  SEEDS.each_with_index do |seed,si|
    opts={:room_count=>6+((hi+si)%5),:min_room=>((hi+si)%2==0 ? 5:4),
      :corridor_width=>((hi+si)%3==0 ? 2:1),:extra_connection_rate=>20+((hi+si)%2)*6,:margin=>2}
    layout=PMD_AC::VXRD_Layout_V10582.new(60,45,seed ^ (hi*7919),opts)
    unless layout.generate
      failures << [code,seed,'layout_generate'];next
    end
    state={:code=>code,:seed=>seed,:width=>layout.width,:height=>layout.height,
      :entrance=>layout.entrance,:exit=>layout.exit_pos,:rooms=>layout.rooms,
      :edges=>layout.edges,:walkable=>layout.walkable,
      :landmark_reserved_v10654=>{},:landmark_blocked_v10654=>{},
      :landmarks_v10654=>{:placements=>[]}}
    entry_room=layout.rooms.find{|r|room_contains?(r,layout.entrance)}
    exit_room=layout.rooms.find{|r|room_contains?(r,layout.exit_pos)}
    candidate_rooms=layout.rooms.reject{|r|r.equal?(entry_room) || r.equal?(exit_room)}
    placements=[]
    candidate_rooms.each do |room|
      pts=inner_candidates(layout,room,layout.entrance,layout.exit_pos)
      next if pts.empty?
      p=pts[(seed+room[:id]*17+hi*31)%pts.size]
      next if placements.any?{|q|[(q[:anchor][0]-p[0]).abs,(q[:anchor][1]-p[1]).abs].max<5}
      placements << {:template=>:offline_hard,:anchor=>p,:w=>1,:h=>1,:blocking=>true}
      break if placements.size>=2
    end
    state[:landmarks_v10654][:placements]=placements
    PMD_AC.vxrd_landmark_route_rebuild_masks_v10655(state)
    sem={};eid=1
    layout.rooms.each do |room|
      next if room.equal?(entry_room)
      sem[eid]={:tag=>(room.equal?(exit_room) ? :exit : :encounter),:x=>room[:cx],:y=>room[:cy],:room_type=>:normal}
      eid+=1
    end
    state[:event_semantic_placement_v10646]=sem
    before=PMD_AC.vxrd_landmark_route_audit_state_v10655(state,true)
    repair=PMD_AC.vxrd_landmark_route_repair_v10655(state,true)
    after=repair[:after]||{}
    ok=layout.validate && repair[:pass] && after[:exit_reachable] && (after[:bad]||[]).empty?
    failures << [code,seed,'route_repair'] unless ok
    rows << [code,seed,placements.size,before[:pass] ? 1:0,repair[:removed_count].to_i,ok ? 'PASS':'FAIL']
  end
end
puts 'PMD AutoChess v1.06.55 Landmark Route Multi-Seed Offline Regression'
rows.each{|r|puts "HUNT=#{r[0]} SEED=#{r[1]} HARD=#{r[2]} BEFORE=#{r[3]} REMOVED=#{r[4]} RESULT=#{r[5]}"}
puts "SUMMARY cases=#{rows.size} pass=#{rows.count{|r|r[5]=='PASS'}} fail=#{failures.size} hunts=#{HUNTS.size} seeds_per_hunt=#{SEEDS.size}"
failures.each{|f|puts "FAIL #{f.join(' ')}"}
puts 'RESULT='+(failures.empty? ? 'PASS':'FAIL')
exit(failures.empty? ? 0:1)
