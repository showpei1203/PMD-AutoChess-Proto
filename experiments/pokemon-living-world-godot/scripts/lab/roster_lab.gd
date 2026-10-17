extends Node2D
## G1.1 independent Kanto gallery: 3 species loaded on demand, NOT 151 at once.
## The previously accepted scenes/animation_lab.tscn remains unmodified.
## Local PMDCollab artwork is kept under gitignored data/raw/pmdcollab/.
const Source = preload("res://scripts/lab/pmd_sprite_source.gd")
const SHOWCASE_IDS = [25, 94, 143]
const ACTIONS = ["Idle", "Walk", "Attack"]
const X_POS = [184.0, 480.0, 776.0]
const GROUND_Y: float = 326.0
const TOTAL_SPECIES: int = 151
const PAGE_SIZE: int = 3
const PAGE_COUNT: int = 51
const SPECIAL_NAMES = {25: "皮卡丘", 94: "耿鬼", 143: "卡比獸"}

var slots: Array[Dictionary] = []
var page_index: int = -1 # -1 = preserved #025/#094/#143 benchmark
var facing_row: int = 0
var action_index: int = 0
var selected_slot: int = 0
var auto_demo: bool = false
var auto_timer: float = 0.0
var title_label: Label
var status_label: Label
var help_label: Label
var detail_label: Label

func _ready() -> void:
    RenderingServer.set_default_clear_color(Color("#141b27"))
    title_label = _add_label("Pokémon Living World | G1.1 151 隻動畫巡覽場", Vector2(24, 14), 21, Color("#eaf3ff"))
    _add_label("只載入目前顯示的 3 隻 · 原 3 隻實驗場保持不變 · 沒有自主 AI", Vector2(24, 48), 13, Color("#97aabd"))
    status_label = _add_label("", Vector2(24, 423), 14, Color("#ffcd8a"))
    help_label = _add_label("Q / E 或 PageUp / PageDown：圖鑑翻頁  T：三隻基準  I / W / A：動畫  ← / →：方向列", Vector2(24, 457), 13, Color("#d1deef"))
    detail_label = _add_label("", Vector2(24, 491), 13, Color("#91e7bd"))
    for i in range(PAGE_SIZE):
        _create_slot(i)
    _show_benchmark()
    queue_redraw()

func _create_slot(index: int) -> void:
    var actor := Node2D.new()
    actor.name = "GallerySlot_%d" % (index + 1)
    actor.position = Vector2(X_POS[index], GROUND_Y - 56.0)
    add_child(actor)
    var sprite := AnimatedSprite2D.new()
    sprite.name = "PMDAnimatedSprite"
    sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
    sprite.scale = Vector2(1.6, 1.6)
    actor.add_child(sprite)
    var species_label := _add_label("", Vector2(X_POS[index] - 75.0, 374.0), 17, Color("#f4f6fc"))
    var error_label := _add_label("", Vector2(X_POS[index] - 105.0, 304.0), 12, Color("#ffaf94"))
    var source = Source.new()
    slots.append({"root": actor, "sprite": sprite, "source": source, "species_id": -1,
        "ready": false, "cache": {}, "name_label": species_label, "error_label": error_label})

func _load_slot(index: int, species_id: int) -> void:
    var slot: Dictionary = slots[index]
    var actor: Node2D = slot["root"]
    var name_label: Label = slot["name_label"]
    var error_label: Label = slot["error_label"]
    var sprite: AnimatedSprite2D = slot["sprite"]
    sprite.stop()
    sprite.sprite_frames = null
    slot["cache"] = {}
    slot["ready"] = false
    slot["species_id"] = species_id
    if species_id < 1 or species_id > TOTAL_SPECIES:
        actor.visible = false
        name_label.visible = false
        error_label.visible = false
        slots[index] = slot
        return
    actor.visible = true
    name_label.visible = true
    error_label.visible = true
    name_label.text = "#%03d %s" % [species_id, str(SPECIAL_NAMES.get(species_id, ""))]
    error_label.text = ""
    var source = slot["source"]
    source.set_species_id(species_id)
    var ok: bool = source.load_species(species_id)
    slot["ready"] = ok
    slots[index] = slot
    if not ok:
        var issue: String = str(source.errors[0]) if not source.errors.is_empty() else "unknown source error"
        error_label.text = "XML / source error"
        print("[PLW-G11] #%03d load FAIL: %s" % [species_id, issue])
        return
    _set_slot_row(index, facing_row)

func _set_slot_row(index: int, row: int) -> void:
    var slot: Dictionary = slots[index]
    if not bool(slot["ready"]):
        return
    var cached: Dictionary = slot["cache"]
    var source = slot["source"]
    var species_id: int = int(slot["species_id"])
    if not cached.has(row):
        source.errors.clear()
        var frames: SpriteFrames = source.make_frames(row, ACTIONS)
        cached[row] = frames
        slot["cache"] = cached
        slots[index] = slot
        for issue in source.errors:
            print("[PLW-G11] #%03d row=%d: %s" % [species_id, row, str(issue)])
        source.errors.clear()
    var sprite: AnimatedSprite2D = slot["sprite"]
    sprite.sprite_frames = cached[row]
    if sprite.sprite_frames == null or sprite.sprite_frames.get_animation_names().is_empty():
        var error_label: Label = slot["error_label"]
        error_label.text = "NO PLAYABLE ANIMATION"
        return
    _play_slot(index)

func _play_slot(index: int) -> void:
    var slot: Dictionary = slots[index]
    if not bool(slot["ready"]):
        return
    var sprite: AnimatedSprite2D = slot["sprite"]
    if sprite.sprite_frames == null:
        return
    var desired: String = ACTIONS[action_index]
    var actual: String = desired
    if not sprite.sprite_frames.has_animation(actual):
        if sprite.sprite_frames.has_animation("Idle"):
            actual = "Idle"
        elif sprite.sprite_frames.has_animation("Walk"):
            actual = "Walk"
        else:
            return
    sprite.play(actual)

func _show_benchmark() -> void:
    page_index = -1
    selected_slot = 0
    for i in range(PAGE_SIZE):
        _load_slot(i, SHOWCASE_IDS[i])
    _refresh_labels()

func _turn_page(delta: int) -> void:
    selected_slot = 0
    if page_index == -1:
        page_index = 0 if delta > 0 else PAGE_COUNT - 1
    else:
        page_index = posmod(page_index + delta, PAGE_COUNT)
    for i in range(PAGE_SIZE):
        _load_slot(i, page_index * PAGE_SIZE + i + 1)
    _refresh_labels()

func _change_action(value: int) -> void:
    action_index = value
    auto_demo = false
    for i in range(PAGE_SIZE):
        _play_slot(i)
    _refresh_labels()

func _process(delta: float) -> void:
    if auto_demo:
        auto_timer += delta
        if auto_timer >= 2.3:
            auto_timer = 0.0
            action_index = (action_index + 1) % ACTIONS.size()
            for i in range(PAGE_SIZE):
                _play_slot(i)
            _refresh_labels()
    for i in range(PAGE_SIZE):
        var slot: Dictionary = slots[i]
        var actor: Node2D = slot["root"]
        actor.position = Vector2(X_POS[i], GROUND_Y - 56.0)
        if bool(slot["ready"]) and ACTIONS[action_index] == "Walk":
            actor.position.x += sin(Time.get_ticks_msec() * 0.0018 + i) * 21.0
    queue_redraw()

func _unhandled_key_input(event: InputEvent) -> void:
    if not event is InputEventKey or not event.pressed or event.echo:
        return
    match event.keycode:
        KEY_E, KEY_PAGEDOWN: _turn_page(1)
        KEY_Q, KEY_PAGEUP: _turn_page(-1)
        KEY_T: _show_benchmark()
        KEY_1: selected_slot = 0
        KEY_2: selected_slot = 1
        KEY_3: selected_slot = 2
        KEY_I: _change_action(0)
        KEY_W: _change_action(1)
        KEY_A: _change_action(2)
        KEY_LEFT:
            facing_row = posmod(facing_row - 1, 8)
            for i in range(PAGE_SIZE):
                _set_slot_row(i, facing_row)
        KEY_RIGHT:
            facing_row = posmod(facing_row + 1, 8)
            for i in range(PAGE_SIZE):
                _set_slot_row(i, facing_row)
        KEY_SPACE: auto_demo = not auto_demo
        _: return
    _refresh_labels()
    queue_redraw()
    get_viewport().set_input_as_handled()

func _refresh_labels() -> void:
    var ready_count: int = 0
    var visible_count: int = 0
    for slot in slots:
        var actor: Node2D = slot["root"]
        if actor.visible:
            visible_count += 1
            if bool(slot["ready"]):
                ready_count += 1
    var page_title: String = "三隻基準展示" if page_index == -1 else "圖鑑第 %d / %d 頁" % [page_index + 1, PAGE_COUNT]
    status_label.text = "%s  ·  已解析 %d/%d 隻  ·  顯示錯誤請查看 Godot 輸出 [PLW-G11]" % [page_title, ready_count, visible_count]
    var current_id: int = int(slots[selected_slot]["species_id"])
    detail_label.text = "選取 #%03d   動作 %s   原始方向列 %d/7   自動輪播 %s   Space 切換" % [current_id, ACTIONS[action_index], facing_row, "ON" if auto_demo else "OFF"]
    print("[PLW-G11] %s ready=%d/%d action=%s row=%d" % [page_title, ready_count, visible_count, ACTIONS[action_index], facing_row])

func _add_label(content: String, pos: Vector2, font_size: int, color: Color) -> Label:
    var label := Label.new()
    label.text = content
    label.position = pos
    label.add_theme_font_size_override("font_size", font_size)
    label.add_theme_color_override("font_color", color)
    add_child(label)
    return label

func _draw() -> void:
    draw_rect(Rect2(0, 85, 960, 315), Color("#1d2a39"))
    for col in range(17):
        draw_line(Vector2(col * 64, 89), Vector2(col * 64, 402), Color("#293c4b"), 1.0)
    for row in range(6):
        draw_line(Vector2(0, 90 + row * 64), Vector2(960, 90 + row * 64), Color("#293c4b"), 1.0)
    for i in range(PAGE_SIZE):
        var center := Vector2(X_POS[i], GROUND_Y + 8.0)
        draw_circle(center, 72.0, Color("#273a49"))
        draw_arc(center, 73.0, 0.0, TAU, 40, Color("#718caa") if i == selected_slot else Color("#385367"), 2.0)
