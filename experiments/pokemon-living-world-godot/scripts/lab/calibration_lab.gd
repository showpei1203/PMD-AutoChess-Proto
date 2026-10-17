extends Node2D
## G1.2 manual ground/scale/facing inspector. No 'approved' direction map.
## Own scene; accepted G1/G1.1 scenes are untouched.
const Source = preload("res://scripts/lab/pmd_sprite_source.gd")
const PRESET_IDS = [25, 94, 143]
const ACTIONS = ["Idle", "Walk", "Attack"]
const GROUND: Vector2 = Vector2(480.0, 350.0)
const MIN_SCALE: float = 0.5
const MAX_SCALE: float = 4.0

var species_id: int = 25
var direction_row: int = 0
var action_index: int = 0
var visual_scale: float = 2.0
var foot_shift: Vector2 = Vector2.ZERO
var show_shadow: bool = true
var source = Source.new()
var sprite: AnimatedSprite2D
var name_label: Label
var help_label: Label
var detail_label: Label
var status_label: Label
var loaded: bool = false
var frames_for_row: Dictionary = {}
var last_reported_frame: int = -1

func _ready() -> void:
    RenderingServer.set_default_clear_color(Color("#141b27"))
    sprite = AnimatedSprite2D.new()
    sprite.name = "CalibrationSprite"
    sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
    sprite.position = GROUND
    add_child(sprite)
    name_label = _label("", Vector2(24, 17), 20, Color("#eaf3ff"))
    _label("G1.2 腳點與體型校準 · 來源動畫八方向僅顯示原始列 · 模擬陰影非官方素材", Vector2(24, 48), 13, Color("#98afc1"))
    help_label = _label("Q/E 換寶可夢  1/2/3 基準  I/W/A 動作  ←/→ 原始方向  Z/X 縮放", Vector2(24, 424), 14, Color("#d1deef"))
    detail_label = _label("↑/↓ 調腳點高低  J/L 左右  B 陰影  R 重置  S 儲存本機校準數值", Vector2(24, 459), 14, Color("#d1deef"))
    status_label = _label("", Vector2(24, 491), 13, Color("#90e7bd"))
    _load(25)

func _snapshot_path() -> String:
    return "user://plw_g12_%04d.json" % species_id

func _load_saved() -> void:
    visual_scale = 2.0
    foot_shift = Vector2.ZERO
    var path: String = _snapshot_path()
    if not FileAccess.file_exists(path):
        return
    var file := FileAccess.open(path, FileAccess.READ)
    if file == null:
        return
    var data = JSON.parse_string(file.get_as_text())
    if not (data is Dictionary) or int(data.get("species_id", -1)) != species_id:
        return
    visual_scale = clampf(float(data.get("scale", 2.0)), MIN_SCALE, MAX_SCALE)
    foot_shift.x = clampf(float(data.get("shift_x", 0.0)), -100.0, 100.0)
    foot_shift.y = clampf(float(data.get("shift_y", 0.0)), -100.0, 100.0)
    direction_row = clampi(int(data.get("raw_direction_row", 0)), 0, 7)

func _save() -> void:
    var payload: Dictionary = {
        "schema": "plw-g12-calibration-1", "species_id": species_id,
        "scale": snappedf(visual_scale, 0.01),
        "shift_x": foot_shift.x, "shift_y": foot_shift.y,
        "raw_direction_row": direction_row,
        "direction_mapping_verified": false,
        "shadow_kind": "debug_ellipse_only",
        "accepted_as_physical_collisions": false
    }
    var file := FileAccess.open(_snapshot_path(), FileAccess.WRITE)
    if file == null:
        status_label.text = "儲存失敗：" + _snapshot_path()
        return
    file.store_string(JSON.stringify(payload, "  ") + "\n")
    file.close()
    print("[PLW-G12] local calibration saved: " + ProjectSettings.globalize_path(_snapshot_path()))
    status_label.text = "已儲存校準草稿（未驗收）: " + _snapshot_path()

func _load(id: int) -> void:
    species_id = clampi(id, 1, 151)
    source = Source.new()
    source.set_species_id(species_id)
    sprite.stop()
    sprite.sprite_frames = null
    frames_for_row.clear()
    direction_row = 0
    _load_saved()
    loaded = source.load_species(species_id)
    name_label.text = "Pokémon Living World | # %03d 物種腳點校準" % species_id
    if not loaded:
        status_label.text = "無法載入 #%03d：%s" % [species_id, str(source.errors)]
        print("[PLW-G12] source FAIL: " + str(source.errors))
    else:
        _set_row(direction_row)
    queue_redraw()

func _set_row(row: int) -> void:
    if not loaded:
        return
    direction_row = posmod(row, 8)
    if not frames_for_row.has(direction_row):
        source.errors.clear()
        frames_for_row[direction_row] = source.make_frames(direction_row, ACTIONS)
        if not source.errors.is_empty():
            print("[PLW-G12] #%03d raw_row=%d issues=%s" % [species_id, direction_row, str(source.errors)])
    sprite.sprite_frames = frames_for_row[direction_row]
    _play()

func _play() -> void:
    if sprite.sprite_frames == null:
        return
    var action: String = ACTIONS[action_index]
    if not sprite.sprite_frames.has_animation(action):
        action = "Idle" if sprite.sprite_frames.has_animation("Idle") else "Walk"
    if sprite.sprite_frames.has_animation(action):
        sprite.play(action)
    else:
        sprite.stop()
    _update_inspector()

func _process(_delta: float) -> void:
    _align_sprite()
    queue_redraw()

func _align_sprite() -> void:
    var frame_width: float = 0.0
    var frame_height: float = 0.0
    if sprite.sprite_frames != null and sprite.sprite_frames.has_animation(sprite.animation):
        var count: int = sprite.sprite_frames.get_frame_count(sprite.animation)
        if count > 0:
            var safe_frame: int = clampi(sprite.frame, 0, count - 1)
            var tex: Texture2D = sprite.sprite_frames.get_frame_texture(sprite.animation, safe_frame)
            if tex != null:
                frame_width = tex.get_size().x
                frame_height = tex.get_size().y
    sprite.scale = Vector2.ONE * visual_scale
    # Bottom of the *frame rectangle* lies on the ground reference line.
    # The actual nontransparent foot pixel may be elsewhere: tune shift.
    sprite.position = GROUND + foot_shift - Vector2(0.0, frame_height * visual_scale * 0.5)
    if last_reported_frame != int(frame_height):
        last_reported_frame = int(frame_height)
        _update_inspector()

func _update_inspector() -> void:
    if status_label == null or not loaded:
        return
    status_label.text = "#%03d  %s  row %d/7   scale %.2fx   腳點修正 (%d,%d)   陰影 %s" % [
        species_id, ACTIONS[action_index], direction_row, visual_scale,
        int(foot_shift.x), int(foot_shift.y), "ON" if show_shadow else "OFF"]

func _unhandled_key_input(event: InputEvent) -> void:
    if not event is InputEventKey or not event.pressed or event.echo:
        return
    match event.keycode:
        KEY_1: _load(PRESET_IDS[0])
        KEY_2: _load(PRESET_IDS[1])
        KEY_3: _load(PRESET_IDS[2])
        KEY_Q: _load(151 if species_id == 1 else species_id - 1)
        KEY_E: _load(1 if species_id == 151 else species_id + 1)
        KEY_I:
            action_index = 0
            _play()
        KEY_W:
            action_index = 1
            _play()
        KEY_A:
            action_index = 2
            _play()
        KEY_LEFT: _set_row(direction_row - 1)
        KEY_RIGHT: _set_row(direction_row + 1)
        KEY_Z: visual_scale = clampf(visual_scale - 0.1, MIN_SCALE, MAX_SCALE)
        KEY_X: visual_scale = clampf(visual_scale + 0.1, MIN_SCALE, MAX_SCALE)
        KEY_UP: foot_shift.y -= 1.0
        KEY_DOWN: foot_shift.y += 1.0
        KEY_J: foot_shift.x -= 1.0
        KEY_L: foot_shift.x += 1.0
        KEY_B: show_shadow = not show_shadow
        KEY_R:
            visual_scale = 2.0
            foot_shift = Vector2.ZERO
        KEY_S: _save()
        _: return
    _update_inspector()
    queue_redraw()
    get_viewport().set_input_as_handled()

func _label(txt: String, pos: Vector2, size: int, col: Color) -> Label:
    var item := Label.new()
    item.text = txt
    item.position = pos
    item.add_theme_font_size_override("font_size", size)
    item.add_theme_color_override("font_color", col)
    add_child(item)
    return item

func _draw() -> void:
    draw_rect(Rect2(0.0, 86.0, 960.0, 319.0), Color("#1d2a39"))
    for i in range(16):
        draw_line(Vector2(float(i) * 64.0, 88.0), Vector2(float(i) * 64.0, 404.0), Color("#293c4b"), 1.0)
    for j in range(5):
        draw_line(Vector2(0.0, 90.0 + float(j) * 64.0), Vector2(960.0, 90.0 + float(j) * 64.0), Color("#293c4b"), 1.0)
    # Debug shadow only; it does NOT use or claim PMDCollab Shadow offsets.
    if show_shadow:
        draw_set_transform(GROUND, 0.0, Vector2(1.0, 0.27))
        draw_circle(Vector2.ZERO, 48.0 * visual_scale / 2.0, Color(0.01, 0.02, 0.03, 0.35))
        draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
    var foot: Vector2 = GROUND + foot_shift
    draw_line(Vector2(96.0, foot.y), Vector2(864.0, foot.y), Color("#5c8797"), 1.0)
    draw_circle(foot, 4.0, Color("#fbcc64"))
    draw_line(foot + Vector2(-13.0, 0.0), foot + Vector2(13.0, 0.0), Color("#fbcc64"), 2.0)
    draw_line(foot + Vector2(0.0, -13.0), foot + Vector2(0.0, 13.0), Color("#fbcc64"), 2.0)
