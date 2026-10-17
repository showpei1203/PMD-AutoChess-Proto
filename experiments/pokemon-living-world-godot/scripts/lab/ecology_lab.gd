extends Node2D
## G2.0 independent ecology prototype: movement / intent without battle.
## Three specimen profiles share ONE reproducible utility/state policy.
## Accepted G1/G1.1/G1.2 scenes and the F5 main scene stay unchanged.
const Source = preload("res://scripts/lab/pmd_sprite_source.gd")
const IDS = [25, 94, 143]
const LABELS = ["#025 皮卡丘", "#094 耿鬼", "#143 卡比獸"]
const HOMES = [Vector2(185.0, 290.0), Vector2(480.0, 290.0), Vector2(775.0, 290.0)]
const ARENA = Rect2(62.0, 122.0, 836.0, 250.0)
const FIXED_AI_DELTA: float = 0.10
const MAX_STEPS_PER_TICK: int = 4
const START_SEED: int = 20261017
const ANIMATIONS = ["Idle", "Walk"]
const STATES = ["IDLE", "ROAM", "OBSERVE", "RETURN", "REST"]
const SPECIES = {
    25: {"role": "CURIOUS", "speed": 50.0, "radius": 112.0, "scale": 1.6, "roam": 0.72, "observe": 0.22, "rest": 0.06},
    94: {"role": "PROWL", "speed": 35.0, "radius": 145.0, "scale": 1.6, "roam": 0.55, "observe": 0.35, "rest": 0.10},
    143: {"role": "ANCHOR", "speed": 16.0, "radius": 49.0, "scale": 1.7, "roam": 0.13, "observe": 0.18, "rest": 0.69}
}

var agents: Array[Dictionary] = []
var clock_accum: float = 0.0
var simulated_time: float = 0.0
var step_number: int = 0
var seed: int = START_SEED
var paused: bool = false
var show_debug: bool = true
var focus: int = 0
var header: Label
var state_info: Label
var instructions: Label

func _ready() -> void:
    RenderingServer.set_default_clear_color(Color("#141b27"))
    header = _label("Pokémon Living World | G2.0 自主生態測試場", Vector2(24, 13), 22, Color("#e9f4ff"))
    _label("自主 Idle / Roam / Observe / Return / Rest，無攻擊 AI，物理與方向映射仍待驗收", Vector2(24, 46), 13, Color("#9eb5c9"))
    instructions = _label("Space：暫停   R：相同種子重新開始   N：換種子   1/2/3：選取   D：觀察資訊", Vector2(24, 455), 14, Color("#d4e4f2"))
    state_info = _label("", Vector2(24, 489), 13, Color("#90e7bd"))
    _reset_simulation(START_SEED)

func _reset_simulation(new_seed: int) -> void:
    for old in agents:
        if is_instance_valid(old["actor"]):
            (old["actor"] as Node2D).queue_free()
        if is_instance_valid(old["label"]):
            (old["label"] as Label).queue_free()
    agents.clear()
    seed = new_seed
    paused = false
    clock_accum = 0.0
    simulated_time = 0.0
    step_number = 0
    focus = 0
    for i in range(IDS.size()):
        _spawn(i)
    _refresh_ui()
    queue_redraw()

func _spawn(index: int) -> void:
    var id: int = IDS[index]
    var profile: Dictionary = SPECIES[id]
    var rng := RandomNumberGenerator.new()
    rng.seed = seed + id * 1009
    var actor := Node2D.new()
    actor.name = "Ecology_%04d" % id
    actor.position = HOMES[index]
    add_child(actor)
    var sprite := AnimatedSprite2D.new()
    sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
    actor.add_child(sprite)
    var source = Source.new()
    source.set_species_id(id)
    var ready: bool = source.load_species(id)
    if ready:
        sprite.sprite_frames = source.make_frames(0, ANIMATIONS)
    var label := _label("", Vector2(HOMES[index].x - 72.0, 402.0), 12, Color("#f5f6f8"))
    var entry: Dictionary = {"id": id, "role": str(profile["role"]),
        "profile": profile, "actor": actor, "sprite": sprite, "label": label,
        "source": source, "ready": ready, "rng": rng, "position": HOMES[index],
        "home": HOMES[index], "target": HOMES[index], "state": "IDLE", "age": 0.0,
        "duration": rng.randf_range(1.0, 2.2), "decision": "spawn", "observation": "",
        "motion": "", "anchor_key": "", "alignment": {}, "raw_facing_row": 0}
    agents.append(entry)
    _set_animation(index, "Idle")
    if not ready:
        print("[PLW-G2] #%03d failed loading: %s" % [id, str(source.errors)])
    else:
        print("[PLW-G2] #%03d loaded role=%s" % [id, profile["role"]])

func _set_animation(index: int, motion: String) -> void:
    var entry: Dictionary = agents[index]
    var sprite: AnimatedSprite2D = entry["sprite"]
    if sprite.sprite_frames == null:
        return
    var actual: String = motion
    if not sprite.sprite_frames.has_animation(actual):
        actual = "Idle" if sprite.sprite_frames.has_animation("Idle") else "Walk"
    if not sprite.sprite_frames.has_animation(actual):
        return
    if str(entry["motion"]) != actual or not sprite.is_playing():
        sprite.play(actual)
        entry["motion"] = actual
        entry["anchor_key"] = ""
        agents[index] = entry

func _set_state(index: int, state: String, reason: String) -> void:
    var entry: Dictionary = agents[index]
    var rng: RandomNumberGenerator = entry["rng"]
    entry["state"] = state
    entry["age"] = 0.0
    entry["decision"] = reason
    match state:
        "IDLE": entry["duration"] = rng.randf_range(0.8, 1.8)
        "OBSERVE": entry["duration"] = rng.randf_range(0.75, 1.5)
        "REST": entry["duration"] = rng.randf_range(2.1, 3.4)
        "ROAM", "RETURN": entry["duration"] = 8.0 # finite fail-safe, not a timer that teleports
        _: entry["duration"] = 1.0
    agents[index] = entry
    _set_animation(index, "Walk" if state in ["ROAM", "RETURN"] else "Idle")

func _choose_post_idle(index: int) -> void:
    var entry: Dictionary = agents[index]
    var profile: Dictionary = entry["profile"]
    var rng: RandomNumberGenerator = entry["rng"]
    var roll: float = rng.randf()
    if roll < float(profile["roam"]):
        var angle: float = rng.randf_range(0.0, TAU)
        var distance: float = rng.randf_range(30.0, float(profile["radius"]))
        var target: Vector2 = (entry["home"] as Vector2) + Vector2(cos(angle), sin(angle)) * distance
        entry["target"] = Vector2(clampf(target.x, ARENA.position.x, ARENA.end.x),
                                  clampf(target.y, ARENA.position.y, ARENA.end.y))
        agents[index] = entry
        _set_state(index, "ROAM", "curiosity/territory: new local target")
    elif roll < float(profile["roam"]) + float(profile["observe"]):
        _set_state(index, "OBSERVE", "listen / watch neighbours")
    else:
        _set_state(index, "REST", "energy conservation")

func _physics_process(delta: float) -> void:
    if paused:
        return
    clock_accum += delta
    var iterations: int = 0
    while clock_accum >= FIXED_AI_DELTA and iterations < MAX_STEPS_PER_TICK:
        _step_ecology(FIXED_AI_DELTA)
        clock_accum -= FIXED_AI_DELTA
        iterations += 1
    if iterations == MAX_STEPS_PER_TICK and clock_accum >= FIXED_AI_DELTA:
        clock_accum = 0.0 # bounded catch-up on slower Surface devices
    for i in range(agents.size()):
        _align_visual(i)
    _refresh_ui()
    queue_redraw()

func _step_ecology(dt: float) -> void:
    simulated_time += dt
    step_number += 1
    # Snapshot prevents first-updated agent bias in neighbour observation.
    var snapshots: Array[Vector2] = []
    for entry in agents:
        snapshots.append(entry["position"] as Vector2)
    for i in range(agents.size()):
        var entry: Dictionary = agents[i]
        var state: String = str(entry["state"])
        var pos: Vector2 = entry["position"]
        entry["age"] = float(entry["age"]) + dt
        agents[i] = entry
        if state == "IDLE":
            if float(entry["age"]) >= float(entry["duration"]):
                _choose_post_idle(i)
        elif state == "OBSERVE":
            var nearest: int = -1
            var nearest_dist: float = 150.0
            for j in range(snapshots.size()):
                if j == i:
                    continue
                var distance: float = snapshots[i].distance_to(snapshots[j])
                if distance < nearest_dist:
                    nearest_dist = distance
                    nearest = j
            entry["observation"] = "#%03d" % IDS[nearest] if nearest >= 0 else "no nearby target"
            agents[i] = entry
            if float(entry["age"]) >= float(entry["duration"]):
                _set_state(i, "IDLE", "finished observing")
        elif state == "REST":
            if float(entry["age"]) >= float(entry["duration"]):
                _set_state(i, "IDLE", "rest complete")
        elif state in ["ROAM", "RETURN"]:
            var target: Vector2 = entry["target"] if state == "ROAM" else entry["home"]
            var step: float = float(entry["profile"]["speed"]) * dt
            entry["position"] = pos.move_toward(target, step)
            agents[i] = entry
            if (entry["position"] as Vector2).distance_to(target) < 1.5:
                if state == "ROAM" and (entry["position"] as Vector2).distance_to(entry["home"] as Vector2) > 35.0:
                    _set_state(i, "OBSERVE", "target reached")
                else:
                    _set_state(i, "IDLE", "home / roam destination reached")
            elif float(entry["age"]) >= float(entry["duration"]):
                if state == "ROAM":
                    _set_state(i, "RETURN", "roam timeout: home")
                else:
                    _set_state(i, "IDLE", "return timeout: safe idle")
        # Safety: prevent drift outside arena when future AI adds new moves.
        entry = agents[i]
        var constrained: Vector2 = entry["position"]
        entry["position"] = Vector2(clampf(constrained.x, ARENA.position.x, ARENA.end.x),
                                   clampf(constrained.y, ARENA.position.y, ARENA.end.y))
        agents[i] = entry

func _align_visual(index: int) -> void:
    var entry: Dictionary = agents[index]
    var actor: Node2D = entry["actor"]
    var sprite: AnimatedSprite2D = entry["sprite"]
    actor.position = entry["position"]
    if not bool(entry["ready"]) or sprite.sprite_frames == null:
        return
    var motion: String = str(sprite.animation)
    var frame_key: String = "%s:%d" % [motion, sprite.frame]
    if frame_key != str(entry["anchor_key"]):
        entry["alignment"] = entry["source"].get_frame_alignment(motion, 0, sprite.frame)
        entry["anchor_key"] = frame_key
        agents[index] = entry
    var align: Dictionary = entry["alignment"]
    var frame_size: Vector2 = align.get("frame_size", Vector2.ZERO)
    if frame_size == Vector2.ZERO:
        return
    var anchor: Vector2 = align.get("ground_point", Vector2(frame_size.x * 0.5, frame_size.y))
    var scale: float = float(entry["profile"]["scale"])
    sprite.scale = Vector2.ONE * scale
    sprite.position = (frame_size * 0.5 - anchor) * scale

func _unhandled_key_input(event: InputEvent) -> void:
    if not event is InputEventKey or not event.pressed or event.echo:
        return
    match event.keycode:
        KEY_SPACE: paused = not paused
        KEY_R: _reset_simulation(seed)
        KEY_N: _reset_simulation(seed + 1)
        KEY_1: focus = 0
        KEY_2: focus = 1
        KEY_3: focus = 2
        KEY_D: show_debug = not show_debug
        _: return
    _refresh_ui()
    queue_redraw()
    get_viewport().set_input_as_handled()

func _refresh_ui() -> void:
    if state_info == null:
        return
    var active: Dictionary = agents[focus]
    state_info.text = "Seed %d  ·  tick %d  ·  %s  ·  焦點 %s：%s / %s" % [
        seed, step_number, "PAUSED" if paused else "RUNNING", LABELS[focus], active["state"], active["decision"]]
    for i in range(agents.size()):
        var entry: Dictionary = agents[i]
        var label: Label = entry["label"]
        label.text = "%s  %s\n%s" % [LABELS[i], entry["role"], entry["state"]]

func _label(text: String, position: Vector2, size: int, color: Color) -> Label:
    var label := Label.new()
    label.text = text
    label.position = position
    label.add_theme_font_size_override("font_size", size)
    label.add_theme_color_override("font_color", color)
    add_child(label)
    return label

func _draw() -> void:
    draw_rect(Rect2(0.0, 86.0, 960.0, 326.0), Color("#1d2a39"))
    for col in range(16):
        draw_line(Vector2(float(col) * 64.0, 86.0), Vector2(float(col) * 64.0, 412.0), Color("#273a49"), 1.0)
    for row in range(6):
        draw_line(Vector2(0.0, 88.0 + float(row) * 64.0), Vector2(960.0, 88.0 + float(row) * 64.0), Color("#273a49"), 1.0)
    for i in range(agents.size()):
        var entry: Dictionary = agents[i]
        var center: Vector2 = entry["position"]
        draw_set_transform(center, 0.0, Vector2(1.0, 0.25))
        draw_circle(Vector2.ZERO, 29.0 if IDS[i] == 143 else 19.0, Color(0.0, 0.0, 0.0, 0.27))
        draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
        if show_debug:
            var home: Vector2 = entry["home"]
            var target: Vector2 = entry["target"]
            draw_arc(home, float(entry["profile"]["radius"]), 0.0, TAU, 48,
                Color("#728ba4", 0.32), 1.0)
            if str(entry["state"]) == "ROAM":
                draw_line(center, target, Color("#eed78a", 0.64), 1.0)
                draw_circle(target, 3.0, Color("#eed78a"))
            draw_circle(center, 2.0, Color("#68e6d3") if i == focus else Color("#a9bfd1"))
