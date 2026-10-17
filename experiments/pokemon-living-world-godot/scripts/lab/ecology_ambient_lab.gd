extends "res://scripts/lab/ecology_animation_lab.gd"
## G2.3 isolated species cadence layer. G2.2 stays byte-exact and accepted.
## Motion/facing/ground alignment remain owned by G2.2. Ambient does not move agents.
const Cadence = preload("res://scripts/lab/pmd_ambient_cadence_policy.gd")
const EXTRA_ACTIONS: Array[String] = ["Float", "Nod", "Pose"]
const MAX_SAFE_ANCHOR_DELTA: float = 5.0

func _ready() -> void:
    super._ready()
    header.text = "Pokémon Living World | G2.3 物種節奏與靜止動作導演"
    for child in get_children():
        if child is Label and str((child as Label).text).begins_with("平時Walk首格站姿"):
            (child as Label).text = "靜止時慢速Walk循環／物種專屬偶發動作／移動八方向維持優先權"
    instructions.text = "G2.3 正式測試 | Space 暫停 | R 重播 | N 換種子 | 1/2/3 焦點 | D 顯示 | M 強制探索"
    print("[PLW-G23] READY | Slow Walk stance + weighted species micro-actions")

func _spawn(index: int) -> void:
    super._spawn(index)
    var entry: Dictionary = agents[index]
    var rng: RandomNumberGenerator = entry["rng"]
    entry["pose_wait"] = Cadence.next_delay(int(entry["id"]), rng)
    entry["micro_action"] = ""
    agents[index] = entry

# Base G2.2 resolves animation direction and caches it. Extend only the
# additional low-priority, one-shot animations for this facing row.
func _row_frames(index: int, row: int) -> SpriteFrames:
    var frames: SpriteFrames = super._row_frames(index, row)
    var entry: Dictionary = agents[index]
    var real_row: int = int(entry.get("render_row", row))
    var source = entry["source"]
    for action in EXTRA_ACTIONS:
        if frames.has_animation(action) or not source.definitions.has(action):
            continue
        # No fake actions, no frame cropping with the wrong row.
        var data: Dictionary = source.get_animation(action, real_row)
        if data.is_empty():
            continue
        var images: Array = data["textures"]
        var durations: Array = data["durations"]
        if images.size() < 2 or images.size() != durations.size() or int(data.get("rows", 0)) < 8:
            continue
        frames.add_animation(action)
        frames.set_animation_speed(action, 60.0)
        frames.set_animation_loop(action, false)
        for k in range(images.size()):
            frames.add_frame(action, images[k] as Texture2D, float(durations[k]))
    return frames

func _safe_micro_action(index: int, wanted: String) -> String:
    if wanted == "NONE":
        return "NONE"
    var entry: Dictionary = agents[index]
    var sprite: AnimatedSprite2D = entry["sprite"]
    if sprite.sprite_frames == null:
        return "NONE"
    if wanted == "Idle":
        return "Idle" if sprite.sprite_frames.has_animation("Idle") else "NONE"
    if not sprite.sprite_frames.has_animation(wanted):
        return "Idle" if sprite.sprite_frames.has_animation("Idle") else "NONE"
    # Gen1 Recomp's non-disruptive ambient rule: require trusted native shadow
    # centers close to the usual posture. A large lift may be a real jump/flight
    # and must not be forcibly corrected to the floor.
    var row: int = int(entry.get("render_row", entry["raw_facing_row"]))
    var base: Dictionary = entry["source"].get_frame_alignment("Walk", row, 0)
    var candidate: Dictionary = entry["source"].get_frame_alignment(wanted, row, 0)
    if str(base.get("reason", "")) == "PMD_SHADOW_CENTER" and str(candidate.get("reason", "")) == "PMD_SHADOW_CENTER":
        var p0: Vector2 = base.get("ground_point", Vector2.ZERO)
        var p1: Vector2 = candidate.get("ground_point", Vector2.ZERO)
        if p0.distance_to(p1) <= MAX_SAFE_ANCHOR_DELTA:
            return wanted
    return "Idle" if sprite.sprite_frames.has_animation("Idle") else "NONE"

func _apply_visual_mode(index: int, mode: String, force_refresh: bool = false) -> void:
    var entry: Dictionary = agents[index]
    if not bool(entry["ready"]):
        return
    var sprite: AnimatedSprite2D = entry["sprite"]
    var facing: int = int(entry["raw_facing_row"])
    var cache: Dictionary = entry["cached_rows"]
    var changed_row: bool = not cache.has(facing) or sprite.sprite_frames != cache.get(facing)
    if changed_row:
        sprite.sprite_frames = _row_frames(index, facing)
        entry = agents[index]
    var old_mode: String = str(entry["visual_mode"])
    if not force_refresh and not changed_row and old_mode == mode and (mode != "STANCE" or sprite.is_playing()):
        return
    var action: String = "Walk"
    if mode.begins_with("MICRO_"):
        action = mode.trim_prefix("MICRO_").capitalize()
    if sprite.sprite_frames == null or not sprite.sprite_frames.has_animation(action):
        return
    sprite.speed_scale = Cadence.speed(int(entry["id"]), mode)
    # Unlike G2.2's frozen frame-0 stance, very-slow Walk genuinely animates.
    # No restart each tick: the elapsed frame time stays continuous.
    sprite.play(action)
    entry["visual_mode"] = mode
    entry["anchor_key"] = "" # change in action or facing invalidates feet
    entry["visual_speed"] = sprite.speed_scale
    entry["micro_action"] = action if mode.begins_with("MICRO_") else ""
    agents[index] = entry
    print("[PLW-G23] PRESENTATION #%03d mode=%s action=%s row=%d speed=%.2f" % [
        int(entry["id"]), mode, action, int(entry.get("render_row", facing)), sprite.speed_scale])

func _update_visual_director(index: int, dt: float) -> void:
    var entry: Dictionary = agents[index]
    if not bool(entry["ready"]):
        return
    var id: int = int(entry["id"])
    var state: String = str(entry["state"])
    # Actual movement has priority over all expressive micro-actions.
    if state in ["ROAM", "RETURN"]:
        if str(entry["visual_mode"]) != "MOVE":
            entry["pose_wait"] = Cadence.next_delay(id, entry["rng"])
        entry["pose_remaining"] = 0.0
        entry["micro_action"] = ""
        agents[index] = entry
        _apply_visual_mode(index, "MOVE")
        return
    if float(entry["pose_remaining"]) > 0.0:
        entry["pose_remaining"] = maxf(0.0, float(entry["pose_remaining"]) - dt)
        agents[index] = entry
        if float(entry["pose_remaining"]) > 0.0:
            var action: String = str(entry.get("micro_action", "Idle"))
            _apply_visual_mode(index, "MICRO_" + action.to_upper())
            return
        _apply_visual_mode(index, "STANCE")
        return
    var remaining: float = float(entry["pose_wait"]) - dt
    if remaining > 0.0:
        entry["pose_wait"] = remaining
        agents[index] = entry
        _apply_visual_mode(index, "STANCE")
        return
    var rng: RandomNumberGenerator = entry["rng"]
    entry["pose_wait"] = Cadence.next_delay(id, rng)
    agents[index] = entry
    # Guarantee facing-specific SpriteFrames exist before checking actions.
    _apply_visual_mode(index, "STANCE")
    var desired: String = Cadence.next_action(id, rng)
    var chosen: String = _safe_micro_action(index, desired)
    if chosen == "NONE":
        return
    if desired != chosen:
        print("[PLW-G23] AMBIENT FALLBACK #%03d wanted=%s using=%s" % [id, desired, chosen])
    _apply_visual_mode(index, "MICRO_" + chosen.to_upper(), true)
    entry = agents[index]
    var sprite: AnimatedSprite2D = entry["sprite"]
    var total: float = 0.0
    if sprite.sprite_frames != null and sprite.sprite_frames.has_animation(chosen):
        var sheet: SpriteFrames = sprite.sprite_frames
        for k in range(sheet.get_frame_count(chosen)):
            total += sheet.get_frame_duration(chosen, k)
        total /= maxf(0.01, sheet.get_animation_speed(chosen) * sprite.speed_scale)
    if total <= 0.0:
        _apply_visual_mode(index, "STANCE")
        return
    entry["pose_remaining"] = total
    entry["pose_count"] = int(entry["pose_count"]) + 1
    agents[index] = entry
