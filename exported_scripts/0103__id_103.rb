#==============================================================================
# ■ module n01
#------------------------------------------------------------------------------
# 　ターゲット選択時のヘルプ表示セッティング Ver1.1
#==============================================================================
module N01
  
 # Display the state of the battler.
  WORD_STATE_DISPLAY = true
  
 # Name to display when there is no abnormal state.
  WORD_NORMAL_STATE = "Normal"
  
 # Displays the HP gauge.
  HP_DISPLAY = true
  
 # Displays the HP gauge for actors.
  ACTOR_DISPLAY = true
  
 # Do not display the HP gauge and states for the following enemies. ex.[1,2,3]
  ENEMY_NON_DISPLAY = []
  
 # Do not display the following states as abnormal. ex.[1,2,3]
  STATE_NON_DISPLAY = []
  
  
end 
#-------------------------------設定ここまで-----------------------------------

#==============================================================================
# ■ Window_Help
#------------------------------------------------------------------------------
# 　スキルやアイテムの説明、アクターのステータスなどを表示するウィンドウです。
#==============================================================================

class Window_Help < Window_Base
  #--------------------------------------------------------------------------
  # ● テキスト設定
  #--------------------------------------------------------------------------
  def set_text_n01add(member)
    self.contents.clear
    self.contents.font.color = normal_color
    if !member.actor? && N01::ENEMY_NON_DISPLAY.include?(member.enemy_id)
      return self.contents.draw_text(4, 0, self.width - 40, WLH, member.name, 1)
    elsif member.actor? && !N01::ACTOR_DISPLAY
      return self.contents.draw_text(4, 0, self.width - 40, WLH, member.name, 1)
    end
    if N01::WORD_STATE_DISPLAY && N01::HP_DISPLAY
      self.contents.draw_text(0, 0, 180, WLH, member.name, 1)
      draw_actor_hp(member, 182, 0, 120)
      text = "["
      for state in member.states
        next if N01::STATE_NON_DISPLAY.include?(state.id)
        text += " " if text != "["
        text += state.name
      end
      text += N01::WORD_NORMAL_STATE if text == "["
      text += "]"
      text = "" if text == "[]"
      self.contents.draw_text(315, 0, 195, WLH, text, 0)
    elsif N01::WORD_STATE_DISPLAY
      text = member.name + "  ["
      for state in member.states
        next if N01::STATE_NON_DISPLAY.include?(state.id)
        text += " " if text != member.name + "  ["
        text += state.name
      end
      text += N01::WORD_NORMAL_STATE if text == member.name + "  ["
      text += "]"
      text = "" if text == "[]"
      self.contents.draw_text(4, 0, self.width - 40, WLH, text, 1)
    elsif N01::HP_DISPLAY
      self.contents.draw_text(4, 0, 240, WLH, member.name, 1)
      draw_actor_hp(member, 262, 0, 120)
    end 
  end
end

#==============================================================================
# ■ Scene_Battle
#------------------------------------------------------------------------------
# 　バトル画面の処理を行うクラスです。
#==============================================================================
class Scene_Battle < Scene_Base
  #--------------------------------------------------------------------------
  # ● ターゲット選択の開始
  #--------------------------------------------------------------------------
  def start_target_selection(actor = false)
    members = $game_party.members if actor
    members = $game_troop.members unless actor
    # カーソルスプライトの作成
    @cursor = Sprite.new
    @cursor.bitmap = Cache.character("cursor")
    @cursor.src_rect.set(0, 0, 32, 32)
    @cursor_flame = 0
    @cursor.x = -200
    @cursor.y = -200
    @cursor.ox = @cursor.width
    @cursor.oy = @cursor.height
    # ターゲット名を表示するヘルプウインドウを作成
    @help_window.visible = false if @help_window != nil
    @help_window2 = Window_Help.new if @help_window2 == nil
    # 不要なウインドウを消す
    @actor_command_window.active = false
    @skill_window.visible = false if @skill_window != nil
    @item_window.visible = false if @item_window != nil
    # 存在しているターゲットで最も番号の低い対象を最初に指すように
    @index = 0
    @max_index = members.size - 1
    # アクターは戦闘不能者でもターゲットできるようにエネミーと区別
    unless actor
      members.size.times do
        break if members[@index].exist?
        @index += 1
      end
    end  
    @help_window2.set_text_n01add(members[@index])
    select_member(actor)
  end
  #--------------------------------------------------------------------------
  # ● カーソルを前に移動
  #--------------------------------------------------------------------------
  def cursor_up(members, actor)
    Sound.play_cursor
    members.size.times do
      @index += members.size - 1
      @index %= members.size
      break if actor
      break if members[@index].exist?
    end
    @help_window2.set_text_n01add(members[@index])
  end
  #--------------------------------------------------------------------------
  # ● カーソルを次に移動
  #--------------------------------------------------------------------------
  def cursor_down(members, actor)
    Sound.play_cursor
    members.size.times do
      @index += 1
      @index %= members.size
      break if actor
      break if members[@index].exist? && !actor
    end
    @help_window2.set_text_n01add(members[@index])
  end
end  
