extends CanvasLayer
## Independent G3.1 runtime logger, starts even when the battle core cannot tick.
const BUILD: String = "G3.1-v0.5.1"
const LOG_NAME: String = "PLW_G31_RUNTIME_LAST.log"
var log_file: FileAccess
var log_path: String = ""
var frames: int = 0
var physics_calls: int = 0
var last_heartbeat_ms: int = 0
var next_trace_index: int = 0
var indicator: Label

func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    _open_log()
    indicator = Label.new()
    indicator.text = "G3.1 LOGGER ACTIVE | reports/" + LOG_NAME
    indicator.position = Vector2(570, 65)
    indicator.add_theme_font_size_override("font_size", 11)
    indicator.add_theme_color_override("font_color", Color("#94edc9"))
    add_child(indicator)
    _log("LOGGER_READY build=%s scene=%s" % [BUILD,
        str(get_tree().current_scene.scene_file_path if get_tree().current_scene != null else "unknown")])

func _open_log() -> void:
    var folder: String = ProjectSettings.globalize_path("res://reports")
    var err: Error = DirAccess.make_dir_recursive_absolute(folder)
    if err == OK:
        log_path = folder.path_join(LOG_NAME)
        log_file = FileAccess.open(log_path, FileAccess.WRITE)
    if log_file == null:
        log_path = ProjectSettings.globalize_path("user://" + LOG_NAME)
        log_file = FileAccess.open(log_path, FileAccess.WRITE)
    if log_file != null:
        print("[PLW-G31-LOG] FILE " + log_path)
        _log("SESSION_START godot=" + str(Engine.get_version_info().get("string", "unknown")))
    else:
        push_error("[PLW-G31-LOG] Cannot open runtime log; error=" + str(FileAccess.get_open_error()))

func _log(s: String) -> void:
    var line: String = "[%dms] %s" % [Time.get_ticks_msec(), s]
    if log_file != null:
        log_file.store_line(line)
        log_file.flush()
    print("[PLW-G31-LOG] " + line)

func _exit_tree() -> void:
    _flush_trace()
    _log("SESSION_END render=%d physics=%d" % [frames, physics_calls])
    if log_file != null:
        log_file.close()
        log_file = null

func _physics_process(_delta: float) -> void:
    physics_calls += 1
    if physics_calls == 1:
        _log("PHYSICS_FIRST_CALL")

func _process(_delta: float) -> void:
    frames += 1
    _flush_trace()
    var now: int = Time.get_ticks_msec()
    if now - last_heartbeat_ms < 1000:
        return
    last_heartbeat_ms = now
    var parent: Node = get_parent()
    var c = parent.get("core")
    if c == null:
        _log("HEARTBEAT core=NULL render=%d physics=%d" % [frames, physics_calls])
        return
    indicator.text = "G3.1 | tick=%d | %s | reports/%s" % [
        int(c.get("tick_number")), "RESULT" if int(c.get("winner")) != -1 else "RUNNING", LOG_NAME]
    _log("HEARTBEAT tick=%d sim=%.1f render=%d physics=%d order=%s winner=%d paused=%s digest=%d" % [
        int(c.get("tick_number")), float(c.get("simulated_time")), frames, physics_calls,
        str(c.get("order")), int(c.get("winner")), str(parent.get("paused")), int(c.get("digest"))])
    for i in range(2):
        var f: Dictionary = c.units[i]
        _log("UNIT id=%d hp=%d/%d action=%s pos=%s cooldown=%d hit_at=%d reason=%s" % [
            int(f["id"]), int(f["hp"]), int(f["max_hp"]), str(f["action"]),
            str(f["position"]), int(f["cooldown"]), int(f["strike_at"]), str(f["reason"])])
        _log("SPACE unit=%d retreat=%d strafe=%d ranged=%d guard=%d guard_ready=%d style=%s" % [
            i, int(f["retreat_steps"]), int(f["strafe_steps"]), int(f["zone_strikes"]),
            int(f["guard_count"]), int(f["guard_ready_at"]), str(f["strike_mode"])])

func _flush_trace() -> void:
    var parent: Node = get_parent()
    var c = parent.get("core")
    if c == null:
        return
    var trace: Array[String] = c.trace
    # Reset and new-seed replays clear the trace buffer.
    if next_trace_index > trace.size():
        next_trace_index = 0
        _log("TRACE_RESTART seed=" + str(c.get("seed")))
    while next_trace_index < trace.size():
        _log("BATTLE " + trace[next_trace_index])
        next_trace_index += 1

func _input(event: InputEvent) -> void:
    if event is InputEventKey and event.pressed and not event.echo:
        if event.keycode in [KEY_1, KEY_2, KEY_3, KEY_4, KEY_5, KEY_SPACE, KEY_R, KEY_N, KEY_D]:
            _log("KEYBOARD code=%d" % event.keycode)
