extends Node2D
## Standalone G3.0 1v1 Utility AI vertical slice. Accepted ecology labs never modified.
const CombatCore = preload("res://scripts/battle/g30_combat_core.gd")
const Source = preload("res://scripts/lab/pmd_sprite_source.gd")
const Visual = preload("res://scripts/lab/pmd_visual_policy.gd")
const ART_ACTIONS = ["Walk", "Idle", "Attack"]
const FIGHTER_SCALE: float = 1.72
const MAX_FRAME_STEPS: int = 4

var core
var clock_accum: float = 0.0
var paused: bool = false
var show_debug: bool = true
var renderers: Array[Dictionary] = []
var title_label: Label
var info_label: Label
var instructions_label: Label
var debug_label: Label
var result_label: Label
var hint_label: Label

func _label(content: String, at: Vector2, size: int, color: Color) -> Label:
    var label := Label.new()
    label.text = content
    label.position = at
    label.add_theme_font_size_override("font_size", size)
    label.add_theme_color_override("font_color", color)
    add_child(label)
    return label

func _ready() -> void:
    RenderingServer.set_default_clear_color(Color("#111926"))
    title_label = _label("Pokémon Living World | G3.0 自主戰鬥核心實驗", Vector2(24, 12), 22, Color("#e5f4ff"))
    _label("固定 AI Tick／Utility 決策／攻擊前搖／傷害權威／同 Seed 重播", Vector2(24, 46), 13, Color("#9ebbd1"))
    info_label = _label("", Vector2(24, 80), 13, Color("#aadbe5"))
    debug_label = _label("", Vector2(24, 390), 12, Color("#d6e7f4"))
    result_label = _label("", Vector2(210, 232), 22, Color("#fff0b4"))
    instructions_label = _label("1自由  2積極  3保持距離  4防守  |  Space暫停  R相同種子重播  N換種子  D除錯", Vector2(20, 491), 13, Color("#e6ddba"))
    hint_label = _label("1v1 原型：保護隊友須等 2v2；尚無招式屬性、PP、障礙物與正式戰鬥平衡", Vector2(20, 518), 11, Color("#acc4d2"))
    core = CombatCore.new()
    _build_renderers()
    _reset_battle(20261017, "FREE")

func _build_renderers() -> void:
    for i in range(2):
        var actor := Node2D.new()
        actor.name = "BattleActor_%d" % i
        add_child(actor)
        var sprite := AnimatedSprite2D.new()
        sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
        actor.add_child(sprite)
        var source = Source.new()
        var id: int = int(CombatCore.BASE_UNIT_STATS[i]["id"])
        source.set_species_id(id)
        var ok: bool = source.load_species(id)
        renderers.append({"actor": actor, "sprite": sprite, "source": source,
            "id": id, "ready": ok, "cached_rows": {}, "row": -1,
            "animation": "", "align_key": "", "anchor": {}})
        if not ok:
            print("[PLW-G30] ART FALLBACK #%03d %s" % [id, str(source.errors)])

func _reset_battle(new_seed: int, order_name: String) -> void:
    core.reset(new_seed, order_name)
    paused = false
    clock_accum = 0.0
    for i in range(renderers.size()):
        var view: Dictionary = renderers[i]
        view["row"] = -1
        view["animation"] = ""
        view["align_key"] = ""
        # Shared SpriteFrames cache is safe across seeded resets for the same local art.
        renderers[i] = view
        _update_renderer(i)
    _update_hud()
    queue_redraw()
    print("[PLW-G30] BATTLE_RESET seed=%d order=%s" % [int(core.get("seed")), str(core.get("order"))])

func _sprites_for(i: int, row: int) -> SpriteFrames:
    var view: Dictionary = renderers[i]
    var cached: Dictionary = view["cached_rows"]
    if cached.has(row):
        return cached[row] as SpriteFrames
    var source = view["source"]
    source.errors.clear()
    var frames: SpriteFrames = source.make_frames(row, ART_ACTIONS)
    var true_row: int = row
    if not frames.has_animation("Walk"):
        source.errors.clear()
        frames = source.make_frames(0, ART_ACTIONS)
        true_row = 0
    if frames.has_animation("Attack"):
        frames.set_animation_loop("Attack", false)
    if frames.has_animation("Idle"):
        frames.set_animation_loop("Idle", false)
    cached[row] = frames
    var actual: Dictionary = view.get("true_rows", {})
    actual[row] = true_row
    view["true_rows"] = actual
    view["cached_rows"] = cached
    renderers[i] = view
    return frames

func _update_renderer(i: int) -> void:
    var u: Dictionary = core.units[i]
    var view: Dictionary = renderers[i]
    var actor: Node2D = view["actor"]
    var sprite: AnimatedSprite2D = view["sprite"]
    actor.position = u["position"]
    if not bool(view["ready"]):
        return
    var facing: Vector2 = u["facing"]
    var row: int = Visual.direction_row(facing)
    var face_changed: bool = int(view["row"]) != row
    if face_changed:
        sprite.sprite_frames = _sprites_for(i, row)
        view = renderers[i]
        view["row"] = row
        view["align_key"] = ""
    var action: String = str(u["action"])
    var animation: String = "Attack" if action in ["ATTACK", "WINDUP"] else "Walk"
    if sprite.sprite_frames == null or not sprite.sprite_frames.has_animation(animation):
        animation = "Walk" if sprite.sprite_frames != null and sprite.sprite_frames.has_animation("Walk") else ""
    if animation.is_empty():
        renderers[i] = view
        return
    if face_changed or str(view["animation"]) != animation:
        sprite.play(animation)
        view["animation"] = animation
        view["align_key"] = ""
    # Important: Walk animation may stay the same across MOVE/STANCE transitions.
    # Refresh speed independently of animation name, without restarting frames.
    var wanted_speed: float = 0.95 if animation == "Attack" else (Visual.playback_speed(int(view["id"]), "MOVE") if action in ["APPROACH", "DODGE"] else 0.24)
    if absf(sprite.speed_scale - wanted_speed) > 0.001:
        sprite.speed_scale = wanted_speed
    if int(u["hp"]) <= 0:
        sprite.modulate = Color(0.45, 0.47, 0.52, 0.90)
        sprite.pause()
    else:
        sprite.modulate = Color.WHITE
    var anchor_row: int = int((view.get("true_rows", {}) as Dictionary).get(row, row))
    var key: String = "%s:%d:%d" % [animation, anchor_row, sprite.frame]
    if str(view["align_key"]) != key:
        view["anchor"] = view["source"].get_frame_alignment(animation, anchor_row, sprite.frame)
        view["align_key"] = key
    var anchor: Dictionary = view["anchor"]
    var size: Vector2 = anchor.get("frame_size", Vector2.ZERO)
    if size != Vector2.ZERO:
        var foot: Vector2 = anchor.get("ground_point", Vector2(size.x * 0.5, size.y))
        sprite.scale = Vector2.ONE * FIGHTER_SCALE
        sprite.position = (size * 0.5 - foot) * FIGHTER_SCALE
    renderers[i] = view

func _physics_process(delta: float) -> void:
    if core == null:
        return
    if not paused and int(core.get("winner")) == -1:
        clock_accum += delta
        var loops: int = 0
        while clock_accum >= CombatCore.DT and loops < MAX_FRAME_STEPS:
            core.step()
            clock_accum -= CombatCore.DT
            loops += 1
        if loops == MAX_FRAME_STEPS and clock_accum >= CombatCore.DT:
            clock_accum = 0.0
    for i in range(renderers.size()):
        _update_renderer(i)
    _update_hud()
    queue_redraw()

func _update_hud() -> void:
    var status: String = "RUNNING" if int(core.get("winner")) == -1 else "RESULT"
    if paused:
        status = "PAUSED"
    info_label.text = "Seed %d  |  tick %d  |  %.1fs  |  %s  |  訓練家指令：%s  |  命中 %d／落空 %d" % [
        int(core.get("seed")), int(core.get("tick_number")), float(core.get("simulated_time")),
        status, str(core.get("order")), int(core.get("total_hits")), int(core.get("total_misses"))]
    var labels: Array[String] = []
    for i in range(2):
        var f: Dictionary = core.units[i]
        labels.append("%s | HP %d/%d | %s | %.0fpx" % [
            str(f["label"]), int(f["hp"]), int(f["max_hp"]), str(f["action"]),
            (f["position"] as Vector2).distance_to(core.units[1-i]["position"] as Vector2)])
    debug_label.visible = show_debug
    debug_label.text = "\n".join(labels)
    result_label.visible = int(core.get("winner")) != -1
    if result_label.visible:
        var w: int = int(core.get("winner"))
        var winner_text: String = "平手" if w == 2 else str(core.units[w]["label"]) + " 獲勝"
        result_label.text = "%s | %s | TICK %d\n按 R 同 Seed 重播，N 換種子" % [
            winner_text, str(core.get("result_reason")), int(core.get("tick_number"))]

func _input(event: InputEvent) -> void:
    if not (event is InputEventKey) or not event.pressed or event.echo:
        return
    match event.keycode:
        KEY_SPACE: paused = not paused
        KEY_R: _reset_battle(int(core.get("seed")), str(core.get("order")))
        KEY_N: _reset_battle(int(core.get("seed")) + CombatCore.SEED_JUMP, str(core.get("order")))
        KEY_1: core.set_order("FREE")
        KEY_2: core.set_order("AGGRESSIVE")
        KEY_3: core.set_order("KEEP_DISTANCE")
        KEY_4: core.set_order("DEFENSIVE")
        KEY_5: core.set_order("PROTECT_ALLY") # explicit unavailable 1v1, logged rejection
        KEY_D: show_debug = not show_debug
        _: return
    _update_hud()
    queue_redraw()
    get_viewport().set_input_as_handled()

func _draw() -> void:
    draw_rect(Rect2(0.0, 112.0, 960.0, 270.0), Color("#202f40"))
    for x in range(0, 16):
        draw_line(Vector2(float(x) * 64.0, 112.0), Vector2(float(x) * 64.0, 382.0), Color("#2c4050"), 1.0)
    for y in range(0, 6):
        draw_line(Vector2(0.0, 116.0 + float(y) * 52.0), Vector2(960.0, 116.0 + float(y) * 52.0), Color("#2c4050"), 1.0)
    draw_rect(Rect2(70.0, 140.0, 820.0, 237.0), Color("#7c9fbd"), false, 1.5)
    if core == null:
        return
    for i in range(2):
        var f: Dictionary = core.units[i]
        var pos: Vector2 = f["position"]
        draw_set_transform(pos, 0.0, Vector2(1.0, 0.25))
        draw_circle(Vector2.ZERO, 23.0, Color(0.0, 0.0, 0.0, 0.28))
        draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
        var hp_fraction: float = float(f["hp"]) / float(f["max_hp"])
        var bar_y: float = 153.0 if i == 0 else 177.0
        var bar_x: float = 67.0 if i == 0 else 652.0
        draw_rect(Rect2(bar_x, bar_y, 245.0, 11.0), Color("#0b1420"))
        draw_rect(Rect2(bar_x, bar_y, 245.0 * hp_fraction, 11.0), Color("#45d993") if i == 0 else Color("#ca7bf1"))
        if show_debug:
            draw_arc(pos, float(f["range"]), 0.0, TAU, 48, Color("#63b1ee") if i == 0 else Color("#a986ee"), 1.1)
            if str(f["action"]) in ["ATTACK", "WINDUP"]:
                draw_arc(pos, float(f["range"]), 0.0, TAU, 48, Color("#ffba55"), 3.0)
            var pointer: Vector2 = f["facing"]
            draw_line(pos, pos + pointer * 24.0, Color("#fff2b6"), 2.2)
