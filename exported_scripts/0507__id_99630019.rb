#==============================================================================
# PMD AutoChess - Character Resource Guard v1.05.22a
#------------------------------------------------------------------------------
# 【用途】
# 修正 Windows / RGSS2 在少數啟動情境下，明明 Graphics/Characters 內存在
# 角色 PNG，Cache.character 仍以相對路徑回報「Unable to find file」的問題。
# 本腳本只負責角色圖讀取的 presentation / resource safety，不修改戰鬥邏輯。
#
# 【主要設定】
# 1. CHARACTER_EXTENSIONS：絕對路徑重試時依序嘗試的副檔名。
# 2. SAFE_FALLBACK_CHARACTER：若指定角色圖真的不存在，最後的安全替代角色圖。
#
# 【機制規則】
# - 先呼叫既有 Cache.character，正常情況完全不改行為。
# - 僅在既有讀取拋出「找不到 Graphics/Characters」相關錯誤時介入。
# - 使用 Win32API GetModuleFileNameA 取得 Game.exe 所在資料夾，改以絕對路徑載入。
# - 絕對路徑仍失敗時，才嘗試 SAFE_FALLBACK_CHARACTER，避免遊戲直接中止。
# - 不修改 Actor 資料、角色座標、Motion、AI、Damage、HP、Energy、Attack Wait、
#   Priority、Spatial 或任何戰鬥 Authority。
#
# 【可調參數】
# CHARACTER_EXTENSIONS = [".png", ".jpg", ".bmp"]
# SAFE_FALLBACK_CHARACTER = "$Actor1_1"
#
# 【依賴 / 載入順序】
# - 必須放在 Main 之前。
# - 以 trailing alias 方式包住 Cache.character，不直接改寫既有 Cache Core。
# - 需要 RGSS2 內建 Win32API。
#
# 【事件 / 腳本呼叫方式】
# 不需事件呼叫，自動生效。
#
# 【實際範例】
# Cache.character("$Actor7_3")
# 若原相對路徑成功，直接回傳原結果；若失敗，會自動嘗試：
# <Game.exe所在資料夾>/Graphics/Characters/$Actor7_3.png
#==============================================================================

module PMDACCharacterResourceGuardV10522A
  CHARACTER_EXTENSIONS = [".png", ".jpg", ".bmp"]
  SAFE_FALLBACK_CHARACTER = "$Actor1_1"

  @absolute_cache = {}

  def self.executable_root
    return @executable_root if @executable_root
    begin
      api = Win32API.new('kernel32', 'GetModuleFileNameA', 'LPL', 'L')
      buffer = "\0" * 1024
      length = api.call(0, buffer, 1024)
      if length && length > 0
        exe_path = buffer[0, length]
        @executable_root = File.dirname(exe_path)
      else
        @executable_root = Dir.pwd
      end
    rescue Exception
      @executable_root = Dir.pwd
    end
    @executable_root
  end

  def self.missing_character_error?(error)
    text = error.to_s
    return true if text.include?("Unable to find file Graphics/Characters/")
    return true if text.include?("No such file or directory") && text.include?("Graphics/Characters")
    false
  end

  def self.absolute_character_path(filename)
    base = File.join(executable_root, "Graphics", "Characters", filename.to_s)
    CHARACTER_EXTENSIONS.each do |ext|
      path = base + ext
      return path if FileTest.exist?(path)
    end
    nil
  end

  def self.load_absolute_character(filename)
    path = absolute_character_path(filename)
    return nil if path.nil?
    cached = @absolute_cache[path]
    if cached.nil? || cached.disposed?
      cached = Bitmap.new(path)
      @absolute_cache[path] = cached
    end
    cached
  end

  def self.write_guard_log(requested, mode, detail = nil)
    begin
      path = File.join(executable_root, "PMD_CharacterResourceGuard_v10522a.log")
      File.open(path, "ab") do |file|
        line = "requested=#{requested} mode=#{mode}"
        line += " detail=#{detail}" if detail
        file.write(line + "\r\n")
      end
    rescue Exception
    end
  end
end

module Cache
  class << self
    alias pmd_ac_v10522a_character character unless method_defined?(:pmd_ac_v10522a_character)

    def character(filename)
      begin
        return pmd_ac_v10522a_character(filename)
      rescue Exception => original_error
        raise original_error unless PMDACCharacterResourceGuardV10522A.missing_character_error?(original_error)

        absolute_bitmap = PMDACCharacterResourceGuardV10522A.load_absolute_character(filename)
        if absolute_bitmap
          PMDACCharacterResourceGuardV10522A.write_guard_log(filename, "absolute_recovery")
          return absolute_bitmap
        end

        fallback = PMDACCharacterResourceGuardV10522A::SAFE_FALLBACK_CHARACTER
        if filename.to_s != fallback
          begin
            fallback_bitmap = PMDACCharacterResourceGuardV10522A.load_absolute_character(fallback)
            if fallback_bitmap
              PMDACCharacterResourceGuardV10522A.write_guard_log(filename, "fallback", fallback)
              return fallback_bitmap
            end
          rescue Exception
          end
        end

        PMDACCharacterResourceGuardV10522A.write_guard_log(filename, "failed", original_error.to_s)
        raise original_error
      end
    end
  end
end
