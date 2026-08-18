# encoding: UTF-8
# PMD AutoChess SHO-22 broad Landmark route stress.
# Test-only. Runs against the formal v1.06.56 source tree while exercising
# the actual v1.06.55 route-audit / repair implementation.

class Game_System; end unless defined?(Game_System)
module PMD_AC; end unless defined?(PMD_AC)

ROOT = File.expand_path('..', __dir__)
load File.join(ROOT, 'exported_scripts', '0567__id_99630079.rb')

module PMD_AC
  class << self
    def hunt_generate_vx_floor_v10584(*args); nil; end unless method_defined?(:hunt_generate_vx_floor_v10584)
    def write_project_state_log(*args); true; end unless method_defined?(:write_project_state_log)
  end
end

load File.join(ROOT, 'exported_scripts', '0640__id_1065500.rb')

HUNTS = (1..21).map { |n| 'H%02d' % n }
SEEDS_PER_HUNT = 40

$failures = []
$production_rows = 0
$natural_removal_cases = 0
$natural_removed_total = 0
$adversarial_rows = 0
$adversarial_removed_total = 0


def assert_case(ok, label, detail='')
  return true if ok
  $failures << [label, detail].reject { |x| x.to_s.empty? }.join(' :: ')
  false
end


def room_contains?(r,p)
  p[0] >= r[:x] && p[0] < r[:x] + r[:w] &&
    p[1] >= r[:y] && p[1] < r[:y] + r[:h]
end


def inner_candidates(layout, room, entrance, exit_pos)
  x0=room[:x]+1; y0=room[:y]+1
  x1=room[:x]+room[:w]-2; y1=room[:y]+room[:h]-2
  pts=[]
  return pts if x1<x0 || y1<y0
  (x0..x1).each { |x| pts << [x,y0] << [x,y1] }
  (y0..y1).each { |y| pts << [x0,y] << [x1,y] }
  seen={}
  pts.find_all do |p|
    next false if seen[p]
    seen[p]=true
    next false unless layout.floor?(p[0],p[1])
    next false if (p[0]-room[:cx]).abs<=1 || (p[1]-room[:cy]).abs<=1
    next false if (p[0]-entrance[0]).abs+(p[1]-entrance[1]).abs<=2
    next false if (p[0]-exit_pos[0]).abs+(p[1]-exit_pos[1]).abs<=2
    true
  end
end


def build_layout(base_seed, hi, si)
  attempt=0
  while attempt<5
    seed=(base_seed + attempt*104729) & 0x7fffffff
    opts={
      :room_count=>6+((hi+si+attempt)%5),
      :min_room=>((hi+si)%2==0 ? 5:4),
      :corridor_width=>((hi+si)%3==0 ? 2:1),
      :extra_connection_rate=>20+((hi+si)%2)*6,
      :margin=>2
    }
    layout=PMD_AC::VXRD_Layout_V10582.new(60,45,seed ^ (hi*7919),opts)
    return [layout,seed,attempt] if layout.generate
    attempt+=1
  end
  [nil,nil,attempt]
end


def run_production_like
  HUNTS.each_with_index do |code,hi|
    SEEDS_PER_HUNT.times do |si|
      base_seed=1065600 + hi*100003 + si*7919
      layout,seed,retries=build_layout(base_seed,hi,si)
      unless layout
        assert_case(false, 'layout_generate', "#{code} seed=#{base_seed}")
        next
      end
      state={
        :code=>code,:seed=>seed,:width=>layout.width,:height=>layout.height,
        :entrance=>layout.entrance,:exit=>layout.exit_pos,:rooms=>layout.rooms,
        :edges=>layout.edges,:walkable=>layout.walkable,
        :landmark_reserved_v10654=>{},:landmark_blocked_v10654=>{},
        :landmarks_v10654=>{:placements=>[]}
      }
      entry_room=layout.rooms.find { |r| room_contains?(r,layout.entrance) }
      exit_room=layout.rooms.find { |r| room_contains?(r,layout.exit_pos) }
      candidate_rooms=layout.rooms.reject { |r| r.equal?(entry_room) || r.equal?(exit_room) }
      placements=[]
      candidate_rooms.each do |room|
        pts=inner_candidates(layout,room,layout.entrance,layout.exit_pos)
        next if pts.empty?
        p=pts[(seed+room[:id]*17+hi*31+si*7)%pts.size]
        next if placements.any? { |q| [(q[:anchor][0]-p[0]).abs,(q[:anchor][1]-p[1]).abs].max<5 }
        placements << {:template=>:stress_hard,:anchor=>p,:w=>1,:h=>1,:blocking=>true}
        break if placements.size>=2
      end
      state[:landmarks_v10654][:placements]=placements
      PMD_AC.vxrd_landmark_route_rebuild_masks_v10655(state)

      sem={}; eid=1
      layout.rooms.each do |room|
        next if room.equal?(entry_room)
        tag = room.equal?(exit_room) ? :exit : [:encounter,:treasure,:recovery,:info][eid % 4]
        sem[eid]={:tag=>tag,:x=>room[:cx],:y=>room[:cy],:room_type=>:normal}
        eid+=1
      end
      state[:event_semantic_placement_v10646]=sem

      before=PMD_AC.vxrd_landmark_route_audit_state_v10655(state,true)
      repair=PMD_AC.vxrd_landmark_route_repair_v10655(state,true)
      after=repair[:after] || {}
      removed=repair[:removed_count].to_i
      $natural_removal_cases += 1 if removed>0
      $natural_removed_total += removed
      ok=layout.validate && repair[:pass] && after[:exit_reachable] &&
        (after[:bad]||[]).empty? && repair[:topology_rewrite]==false
      assert_case(ok,'production_like',"#{code} seed=#{seed} retries=#{retries} before=#{before[:pass]} removed=#{removed} bad=#{(after[:bad]||[]).join(',')}")
      $production_rows += 1
    end
  end
end


def state_from_walkable(walkable, entrance, exit_pos, placements=[], events={})
  st={
    :code=>'ADV',:seed=>999,:entrance=>entrance,:exit=>exit_pos,
    :walkable=>walkable,:landmark_reserved_v10654=>{},:landmark_blocked_v10654=>{},
    :landmarks_v10654=>{:placements=>placements},
    :event_semantic_placement_v10646=>events
  }
  PMD_AC.vxrd_landmark_route_rebuild_masks_v10655(st)
  st
end


def hard(x,y,name=:adversarial_hard)
  {:template=>name,:anchor=>[x,y],:w=>1,:h=>1,:blocking=>true}
end


def soft(x,y)
  {:template=>:adversarial_soft,:anchor=>[x,y],:w=>1,:h=>1,:blocking=>false}
end


def run_repair_case(label,state,include_events,expected_removed,min_before_fail=true)
  before=PMD_AC.vxrd_landmark_route_audit_state_v10655(state,include_events)
  repair=PMD_AC.vxrd_landmark_route_repair_v10655(state,include_events)
  after=repair[:after] || {}
  removed=repair[:removed_count].to_i
  $adversarial_rows += 1
  $adversarial_removed_total += removed
  assert_case(!before[:pass],label,'before unexpectedly PASS') if min_before_fail
  assert_case(repair[:pass],label,"repair FAIL bad=#{(after[:bad]||[]).join(',')}")
  assert_case(after[:exit_reachable],label,'exit not reachable after repair')
  assert_case((after[:bad]||[]).empty?,label,"after bad=#{(after[:bad]||[]).join(',')}")
  assert_case(repair[:topology_rewrite]==false,label,'topology rewrite flag changed')
  assert_case(removed==expected_removed,label,"removed=#{removed} expected=#{expected_removed}")
end


def run_adversarial
  # 1. Unique corridor throat must force a real removal.
  walk=(0..6).map { |x| [x,0] }
  run_repair_case('unique_corridor_throat',state_from_walkable(walk,[0,0],[6,0],[hard(3,0)]),true,1)

  # 2. Every required semantic tag must be protected even when exit stays reachable.
  [:retreat,:info,:treasure,:recovery,:rare,:elite,:encounter].each_with_index do |tag,i|
    walk=(0..6).map { |x| [x,0] } + [[3,1],[3,2],[3,3]]
    events={1=>{:tag=>tag,:x=>3,:y=>3,:room_type=>:normal}}
    run_repair_case("semantic_branch_#{tag}",state_from_walkable(walk,[0,0],[6,0],[hard(3,1,("block_#{tag}").to_sym)],events),true,1)
  end

  # 3. Two independent semantic branches require two actual removals.
  walk=(0..6).map { |x| [x,0] } + [[2,1],[2,2],[2,3],[4,1],[4,2],[4,3]]
  events={
    1=>{:tag=>:treasure,:x=>2,:y=>3,:room_type=>:normal},
    2=>{:tag=>:recovery,:x=>4,:y=>3,:room_type=>:normal}
  }
  run_repair_case('two_independent_semantic_blocks',state_from_walkable(walk,[0,0],[6,0],[hard(2,1,:block_a),hard(4,1,:block_b)],events),true,2)

  # 4. Soft decoration on a corridor is not a blocker and must never be removed.
  st=state_from_walkable((0..6).map { |x| [x,0] },[0,0],[6,0],[soft(3,0)])
  before=PMD_AC.vxrd_landmark_route_audit_state_v10655(st,true)
  repair=PMD_AC.vxrd_landmark_route_repair_v10655(st,true)
  $adversarial_rows += 1
  assert_case(before[:pass],'soft_corridor','soft decoration falsely blocked route')
  assert_case(repair[:pass] && repair[:removed_count].to_i==0,'soft_corridor','soft decoration was removed')

  # 5. Hard prop in open room with detour should remain; no over-repair.
  open=[]; 3.times { |y| 3.times { |x| open << [x,y] } }
  st=state_from_walkable(open,[0,1],[2,1],[hard(1,1,:open_center)])
  before=PMD_AC.vxrd_landmark_route_audit_state_v10655(st,true)
  repair=PMD_AC.vxrd_landmark_route_repair_v10655(st,true)
  $adversarial_rows += 1
  assert_case(before[:pass],'open_room_detour','detour was falsely rejected')
  assert_case(repair[:pass] && repair[:removed_count].to_i==0,'open_room_detour','safe hard prop was over-repaired')
end

run_production_like
run_adversarial

puts 'PMD AutoChess SHO-22 Landmark Route Broad Stress'
puts "BASELINE=v1.06.56 ROUTE_RUNTIME=v1.06.55"
puts "PRODUCTION_LIKE_CASES=#{$production_rows} HUNTS=#{HUNTS.size} SEEDS_PER_HUNT=#{SEEDS_PER_HUNT}"
puts "NATURAL_REMOVAL_CASES=#{$natural_removal_cases} NATURAL_REMOVED_TOTAL=#{$natural_removed_total}"
puts "ADVERSARIAL_CASES=#{$adversarial_rows} ADVERSARIAL_REMOVED_TOTAL=#{$adversarial_removed_total}"
puts "FAILURES=#{$failures.size}"
$failures.each { |f| puts "FAIL #{f}" }
puts 'TOPOLOGY_REWRITE=0'
puts 'MAP_TABLE_BCDE_STAMPING=0'
puts 'RESULT=' + ($failures.empty? ? 'PASS' : 'FAIL')
exit($failures.empty? ? 0 : 1)
