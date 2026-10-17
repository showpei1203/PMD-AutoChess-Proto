extends Node2D
## G1 animation lab: preview actual locally downloaded PMDCollab artwork.
## Not battle AI, and not a formally accepted animation/offset calibration.
const Source = preload("res://scripts/lab/pmd_sprite_source.gd")
const IDS = [25, 94, 143]
const NAMES = ["#025 皮卡丘", "#094 耿鬼", "#143 卡比獸"]
const ACTIONS = ["Idle", "Walk", "Attack"]
const X_POS = [184.0, 480.0, 776.0]
const GROUND_Y: float = 326.0
var agents: Array[Dictionary] = []
var selected: int = 0
var facing_row: int = 0
var action_index: int = 0
var auto_demo: bool = true
var auto_timer: float = 0.0
var status: Label
var instructions: Label
var details: Label

func _ready() -> void:
    RenderingServer.set_default_clear_color(Color("#141b27"))
    _add_label("Pokémon Living World  |  G1 PMD 動畫實驗場", Vector2(24, 14), 21, Color("#eaf3ff"))
    _add_label("本機素材預覽 · 無戰鬥 AI · 素材不會上傳 GitHub", Vector2(26, 47), 14, Color("#97aabd"))
    instructions = _add_label("1 / 2 / 3：選取寶可夢    I：待機   W：行走   A：攻擊   ← / →：切換原始方向列   Space：自動輪播", Vector2(24, 464), 14, Color("#d1deef"))
    details = _add_label("", Vector2(24, 492), 13, Color("#91e7bd"))
    status = _add_label("", Vector2(24, 428), 14, Color("#ffcd8a"))
    for i in range(IDS.size()):
        _create_agent(i)
    _refresh_detail()
    queue_redraw()

func _create_agent(index: int) -> void:
    var agent := Node2D.new()
    agent.name = "Species_%04d" % IDS[index]
    agent.position = Vector2(X_POS[index], GROUND_Y - 56.0)
    add_child(agent)
    var sprite := AnimatedSprite2D.new()
    sprite.name = "PMDAnimatedSprite"
    sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
    sprite.scale = Vector2(1.6, 1.6)
    agent.add_child(sprite)
    var label := _add_label(NAMES[index], Vector2(X_POS[index] - 53.0, 374.0), 17, Color("#f4f6fc"))
    var src = Source.new()
    src.set_species_id(IDS[index])
    var ok: bool = src.load_species(IDS[index])
    agents.append({"root": agent, "sprite": sprite, "source": src, "ok": ok,
        "frames_by_direction": {}, "label": label})
    if ok:
        _set_sprite_direction(index, 0)
    else:
        var err_msg: String = str(src.errors[0]) if not src.errors.is_empty() else "unknown error"
        _add_label("Missing local art", Vector2(X_POS[index] - 76.0, 302.0), 15, Color("#ffaf94"))
        print("[PLW-G1] %s failed: %s" % [NAMES[index], err_msg])

func _set_sprite_direction(index: int, raw_row: int) -> void:
    var agent: Dictionary = agents[index]
    if not bool(agent["ok"]):
        return
    var frames_cache: Dictionary = agent["frames_by_direction"]
    if not frames_cache.has(raw_row):
        var source = agent["source"]
        frames_cache[raw_row] = source.make_frames(raw_row, ACTIONS)
        for warning in source.errors:
            print("[PLW-G1] %s %s" % [NAMES[index], warning])
        source.errors.clear()
    var sprite: AnimatedSprite2D = agent["sprite"]
    sprite.sprite_frames = frames_cache[raw_row]
    _play(index)

func _play(index: int) -> void:
    var sprite: AnimatedSprite2D = agents[index]["sprite"]
    if sprite.sprite_frames == null:
        return
    var action: String = ACTIONS[action_index]
    if not sprite.sprite_frames.has_animation(action):
        if sprite.sprite_frames.has_animation("Idle"):
            action = "Idle"
        elif sprite.sprite_frames.has_animation("Walk"):
            action = "Walk"
        else:
            return
    sprite.play(action)

func _process(delta: float) -> void:
    if auto_demo:
        auto_timer += delta
        if auto_timer > 2.3:
            auto_timer = 0.0
            action_index = (action_index + 1) % ACTIONS.size()
            for i in range(agents.size()):
                _play(i)
            _refresh_detail()
    for i in range(agents.size()):
        var node: Node2D = agents[i]["root"]
        node.position.x = X_POS[i]
        node.position.y = GROUND_Y - 56.0
        if bool(agents[i]["ok"]) and ACTIONS[action_index] == "Walk":
            node.position.x += sin(Time.get_ticks_msec() * 0.0018 + i) * 21.0
    queue_redraw()

func _unhandled_key_input(event: InputEvent) -> void:
    if not event is InputEventKey or not event.pressed or event.echo:
        return
    match event.keycode:
        KEY_1: selected = 0
        KEY_2: selected = 1
        KEY_3: selected = 2
        KEY_I: _select_action(0)
        KEY_W: _select_action(1)
        KEY_A: _select_action(2)
        KEY_SPACE: auto_demo = not auto_demo
        KEY_LEFT:
            facing_row = posmod(facing_row - 1, 8)
            for i in range(agents.size()):
                _set_sprite_direction(i, facing_row)
        KEY_RIGHT:
            facing_row = posmod(facing_row + 1, 8)
            for i in range(agents.size()):
                _set_sprite_direction(i, facing_row)
        _: return
    _refresh_detail()
    queue_redraw()
    get_viewport().set_input_as_handled()

func _select_action(index: int) -> void:
    action_index = index
    auto_demo = false
    for i in range(agents.size()):
        _play(i)

func _refresh_detail() -> void:
    var loaded: int = 0
    for agent in agents:
        if bool(agent["ok"]):
            loaded += 1
    status.text = "已找到本機來源：%d / 3 種   |   未找到請確認 data/raw/pmdcollab/0025、0094、0143" % loaded
    details.text = "選擇：%s   動作：%s   方向原始列：%d / 7（方位定義未驗收）   自動輪播：%s" % [NAMES[selected], ACTIONS[action_index], facing_row, "ON" if auto_demo else "OFF"]
    print("[PLW-G1] ready=%d/3 action=%s raw_direction_row=%d" % [loaded, ACTIONS[action_index], facing_row])

func _add_label(value: String, p: Vector2, font_size: int, color: Color) -> Label:
    var label := Label.new()
    label.text = value
    label.position = p
    label.add_theme_font_size_override("font_size", font_size)
    label.add_theme_color_override("font_color", color)
    add_child(label)
    return label

func _draw() -> void:
    draw_rect(Rect2(0, 85, 960, 315), Color("#1d2a39"))
    for n in range(17):
        draw_line(Vector2(n * 64, 89), Vector2(n * 64, 402), Color("#293c4b"), 1.0)
    for n in range(6):
        draw_line(Vector2(0, 90 + n * 64), Vector2(960, 90 + n * 64), Color("#293c4b"), 1.0)
    for i in range(3):
        draw_circle(Vector2(X_POS[i], GROUND_Y + 8.0), 72.0, Color("#273a49"))
        draw_arc(Vector2(X_POS[i], GROUND_Y + 8.0), 73.0, 0.0, TAU, 40, Color("#718caa") if i == selected else Color("#385367"), 2.0)
