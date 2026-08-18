# encoding: UTF-8
#===============================================================================
# ■ PMD AutoChess - VX Random Dungeon Placement + Exploration v1.05.83
#-------------------------------------------------------------------------------
# 【用途】
# 吸收使用者提供 dungeon.rvdata 的 random_pos / complete_map / 房間探索概念，
# 但仍使用現行 Game_Map。提供事件安全取點與探索資料 Authority；Fog / Minimap 外觀延後。
#===============================================================================
$imported={} unless defined?($imported)
$imported['PMD_AutoChess_VXRandomDungeonPlacementExploration_v10583']=true

module PMD_AC
  class << self
    def vxrd_position_far_enough_v10583(x,y,occupied,min_distance)
      d=[min_distance.to_i,1].max
      (occupied||[]).each do |p|
        next unless p.is_a?(Array) && p.size>=2
        return false if (x-p[0].to_i).abs<d && (y-p[1].to_i).abs<d
      end
      true
    end
    def vxrd_random_walkable_position_v10583(kind=:room,salt=0,occupied=nil,min_distance=2)
      s=vxrd_state_v10582
      return nil if s==nil || !s[:active]
      source=(kind.to_sym==:any ? s[:walkable] : s[:room_cells]) || []
      source=s[:walkable]||[] if source.empty?
      return nil if source.empty?
      rng=VXRD_RNG_V10582.new((s[:seed].to_i ^ ((salt.to_i+1)*2654435761)) & 0x7fffffff)
      tries=[source.size*2,40].max
      tries.times do
        p=source[rng.rand(source.size)]
        next if p==nil
        next if s[:entrance]!=nil && (p[0]-s[:entrance][0]).abs<3 && (p[1]-s[:entrance][1]).abs<3
        next if s[:exit]!=nil && (p[0]-s[:exit][0]).abs<2 && (p[1]-s[:exit][1]).abs<2
        next unless vxrd_position_far_enough_v10583(p[0],p[1],occupied,min_distance)
        return [p[0],p[1]]
      end
      nil
    rescue
      nil
    end
    def vxrd_room_at_v10583(x,y)
      s=vxrd_state_v10582;return nil if s==nil
      (s[:rooms]||[]).each do |r|
        return r if x.to_i>=r[:x].to_i && x.to_i<r[:x].to_i+r[:w].to_i &&
                    y.to_i>=r[:y].to_i && y.to_i<r[:y].to_i+r[:h].to_i
      end
      nil
    rescue
      nil
    end
    def vxrd_explore_index_v10583(s,x,y)
      y.to_i*s[:width].to_i+x.to_i
    end
    def vxrd_mark_explored_v10583(x,y)
      s=vxrd_state_v10582;return false if s==nil
      return false if x.to_i<0 || y.to_i<0 || x.to_i>=s[:width].to_i || y.to_i>=s[:height].to_i
      s[:explored]||={}
      idx=vxrd_explore_index_v10583(s,x,y)
      before=s[:explored][idx]==true
      s[:explored][idx]=true
      !before
    rescue
      false
    end
    def vxrd_reveal_at_v10583(x=nil,y=nil)
      s=vxrd_state_v10582;return false if s==nil
      px=x==nil ? ($game_player==nil ? 0:$game_player.x.to_i) : x.to_i
      py=y==nil ? ($game_player==nil ? 0:$game_player.y.to_i) : y.to_i
      changed=false
      room=vxrd_room_at_v10583(px,py)
      if room!=nil
        for yy in (room[:y].to_i-1)..(room[:y].to_i+room[:h].to_i)
          for xx in (room[:x].to_i-1)..(room[:x].to_i+room[:w].to_i)
            changed=true if vxrd_mark_explored_v10583(xx,yy)
          end
        end
      else
        radius=2
        for yy in (py-radius)..(py+radius)
          for xx in (px-radius)..(px+radius)
            changed=true if vxrd_mark_explored_v10583(xx,yy)
          end
        end
      end
      changed
    rescue
      false
    end
    def vxrd_explored_v10583?(x,y)
      s=vxrd_state_v10582;return false if s==nil || s[:explored]==nil
      s[:explored][vxrd_explore_index_v10583(s,x,y)]==true
    rescue
      false
    end
    def vxrd_exploration_percent_v10583
      s=vxrd_state_v10582;return 0 if s==nil
      total=(s[:walkable]||[]).size;return 0 if total<=0
      found=0
      (s[:walkable]||[]).each{|p|found+=1 if vxrd_explored_v10583?(p[0],p[1])}
      ((found*100.0/total).round).to_i
    rescue
      0
    end
    def vxrd_complete_exploration_v10583
      s=vxrd_state_v10582;return false if s==nil
      (s[:walkable]||[]).each{|p|vxrd_mark_explored_v10583(p[0],p[1])}
      true
    rescue
      false
    end
    def vxrd_placement_exploration_audit_v10583
      req=[:vxrd_random_walkable_position_v10583,:vxrd_reveal_at_v10583,
        :vxrd_explored_v10583?,:vxrd_exploration_percent_v10583,:vxrd_complete_exploration_v10583]
      bad=req.find_all{|m|!respond_to?(m)}
      {:pass=>bad.empty?,:api=>req.size,:bad=>bad,:visual_fog=>:deferred,:visual_minimap=>:deferred}
    rescue
      {:pass=>false,:api=>0,:bad=>[:audit_error]}
    end
  end
end

class Scene_Map
  alias pmd_ac_v10583_update_exploration update unless method_defined?(:pmd_ac_v10583_update_exploration)
  def update
    pmd_ac_v10583_update_exploration
    begin
      s=PMD_AC.vxrd_state_v10582
      if s!=nil && s[:active] && s[:map_id].to_i==$game_map.map_id.to_i
        sig=[$game_player.x.to_i,$game_player.y.to_i]
        if @pmd_vxrd_last_reveal_v10583!=sig
          @pmd_vxrd_last_reveal_v10583=sig
          PMD_AC.vxrd_reveal_at_v10583(sig[0],sig[1])
        end
      end
    rescue
    end
  end
end
