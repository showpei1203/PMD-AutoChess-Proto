extends CanvasLayer
## Standalone G2 diagnostic observer. Works even if the AI physics tick stalls.
## Does not change the accepted G1 scenes or the G2 simulation state machine.
const LOG_NAME: String = "PLW_G22_RUNTIME_LAST.log"
const BUILD: String = "G2.2-v0.4.1.1"
const SEED_JUMP: int = 104729
var log_file: FileAccess
var log_path: String = ""
var visual_frames: int = 0
var physics_callbacks: int = 0
var last_heartbeat_ms: int = 0
var last_states: Dictionary = {}
var first_key_seen: bool = false
var indicator: Label

func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    _open_log()
    _log("LOGGER_READY build=" + BUILD + " scene=" + str(get_tree().current_scene.scene_file_path if get_tree().current_scene != null else "unknown"))
    indicator = Label.new()
    indicator.text = "G2.2 LOGGER ACTIVE | log: reports/" + LOG_NAME
    indicator.position = Vector2(550.0, 64.0)
    indicator.add_theme_font_size_override("font_size", 11)
    indicator.add_theme_color_override("font_color", Color("#9decc1"))
    add_child(indicator)
    _button("M 移動", Vector2(535, 414), _force_movement)
    _button("D 除錯", Vector2(670, 414), _debug_toggle)
    _button("N 換種子", Vector2(805, 414), _change_seed)
    set_process(true)
    set_physics_process(true)
    set_process_input(true)

func _open_log() -> void:
    var report_dir: String = ProjectSettings.globalize_path("res://reports")
    var create_error: Error = DirAccess.make_dir_recursive_absolute(report_dir)
    if create_error == OK:
        log_path = report_dir.path_join(LOG_NAME)
        log_file = FileAccess.open(log_path, FileAccess.WRITE)
    if log_file == null:
        log_path = ProjectSettings.globalize_path("user://" + LOG_NAME)
        log_file = FileAccess.open(log_path, FileAccess.WRITE)
    if log_file == null:
        push_error("[PLW-G2-LOG] Unable to create diagnostics log (res/user), err=" + str(FileAccess.get_open_error()))
    else:
        print("[PLW-G2-LOG] FILE " + log_path)
        _log("SESSION_START godot=" + str(Engine.get_version_info().get("string", "unknown")))

func _log(message: String) -> void:
    var row: String = "[%dms] %s" % [Time.get_ticks_msec(), message]
    print("[PLW-G2-LOG] " + row)
    if log_file != null:
        log_file.store_line(row)
        log_file.flush()

func _exit_tree() -> void:
    _log("SESSION_END visual=%d physics=%d" % [visual_frames, physics_callbacks])
    if log_file != null:
        log_file.close()
        log_file = null

func _button(text_value: String, where: Vector2, action: Callable) -> void:
    var button := Button.new()
    button.text = text_value
    button.position = where
    button.size = Vector2(126.0, 32.0)
    button.pressed.connect(action)
    add_child(button)

func _physics_process(delta: float) -> void:
    physics_callbacks += 1
    if physics_callbacks == 1:
        _log("PHYSICS_FIRST_CALL delta=" + str(delta))

func _process(_delta: float) -> void:
    visual_frames += 1
    var now: int = Time.get_ticks_msec()
    if now - last_heartbeat_ms < 1000:
        return
    last_heartbeat_ms = now
    var root: Node = get_parent()
    var tick_value: String = str(root.get("step_number"))
    var seed_value: String = str(root.get("seed"))
    var paused_flag: String = str(root.get("paused"))
    var info: String = "HEARTBEAT tick=" + tick_value + " seed=" + seed_value + " ui=" + str(visual_frames) + " physics=" + str(physics_callbacks) + " paused=" + paused_flag + " tree_paused=" + str(get_tree().paused) + " root_process=" + str(root.is_processing()) + " root_physics=" + str(root.is_physics_processing()) + " engine_frames=" + str(Engine.get_frames_drawn())
    _log(info)
    indicator.text = "G2.2.1 | tick=" + tick_value + " ui=" + str(visual_frames) + " physics=" + str(physics_callbacks) + " | reports/" + LOG_NAME
    var entities = root.get("agents")
    if not (entities is Array):
        _log("ERROR no agents Array on G2 root")
        return
    for agent in entities:
        if not (agent is Dictionary):
            continue
        var id: int = int(agent.get("id", 0))
        var state: String = str(agent.get("state", "UNKNOWN"))
        var target: String = str(agent.get("target", "?"))
        var position: String = str(agent.get("position", "?"))
        var moved: String = str(agent.get("distance_moved", "?"))
        var roams: String = str(agent.get("roam_count", "?"))
        var since_roam: String = str(agent.get("time_since_roam", "?"))
        var facing: String = str(agent.get("raw_facing_row", "?"))
        var pose: String = str(agent.get("visual_mode", "?"))
        var events: String = str(agent.get("pose_count", "?"))
        var key: String = state + ":" + target + ":" + facing + ":" + pose + ":" + events + ":" + roams
        if last_states.get(id, "") != key:
            _log("AGENT #%03d state=%s pos=%s target=%s moved=%s roams=%s since_roam=%s facing=%s pose=%s events=%s" % [id, state, position, target, moved, roams, since_roam, facing, pose, events])
            last_states[id] = key

func _input(event: InputEvent) -> void:
    if not (event is InputEventKey) or not event.pressed or event.echo:
        return
    if event.keycode in [KEY_M, KEY_D, KEY_N, KEY_R, KEY_SPACE, KEY_1, KEY_2, KEY_3]:
        _log("KEYBOARD keycode=" + str(event.keycode) + " scene=" + str(get_parent().name))
        first_key_seen = true

func _force_movement() -> void:
    var root: Node = get_parent()
    _log("BUTTON M press; has_begin_roam=" + str(root.has_method("_begin_roam")))
    if root.has_method("_begin_roam"):
        root.call("_begin_roam", int(root.get("focus")), "BUTTON DIAGNOSTIC force target")
        root.set("show_debug", true)
        root.call("_refresh_ui")
        root.call("queue_redraw")

func _debug_toggle() -> void:
    var root: Node = get_parent()
    var next_value: bool = not bool(root.get("show_debug"))
    _log("BUTTON D next_debug=" + str(next_value))
    root.set("show_debug", next_value)
    root.call("_refresh_ui")
    root.call("queue_redraw")

func _change_seed() -> void:
    var root: Node = get_parent()
    var current: int = int(root.get("seed"))
    _log("BUTTON N seed=" + str(current) + " -> " + str(current + SEED_JUMP))
    last_states.clear()
    root.call("_reset_simulation", current + SEED_JUMP)
