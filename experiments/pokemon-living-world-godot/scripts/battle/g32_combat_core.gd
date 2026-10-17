extends "res://scripts/battle/g31_combat_core.gd"
## G3.2 route planning on top of sealed G3.1 fixed-tick combat.
## Escape is chosen from deterministic, geometry-scored candidate directions.
## No new attack/damage authority and no change to accepted G3.1.
const ESCAPE_LOOKAHEAD_TICKS: int = 9
const ESCAPE_MARGIN: float = 45.0
const ESCAPE_LOCK_TICKS: int = 18
const ESCAPE_SPEED_FACTOR: float = 1.08
const ESCAPE_DIRS: Array[Vector2] = [
    Vector2.LEFT, Vector2.RIGHT, Vector2.UP, Vector2.DOWN,
    Vector2(-1.0, -1.0), Vector2(-1.0, 1.0),
    Vector2(1.0, -1.0), Vector2(1.0, 1.0)
]

func reset(new_seed: int = 20261017, new_order: String = "FREE") -> void:
    super.reset(new_seed, new_order)
    for idx in range(units.size()):
        var f: Dictionary = units[idx]
        f["escape_steps"] = 0
        f["escape_plans"] = 0
        f["escape_replans"] = 0
        f["wall_contacts"] = 0
        f["escape_lock_until"] = -1
        f["escape_heading"] = Vector2.ZERO
        f["min_wall_clearance"] = 10000.0
        units[idx] = f

func _wall_clearance(point: Vector2) -> float:
    return minf(minf(point.x - WEST, EAST - point.x), minf(point.y - NORTH, SOUTH - point.y))

func _retreat_wall_risk(i: int) -> bool:
    var me: Dictionary = units[i]
    var foe: Dictionary = units[1 - i]
    var p: Vector2 = me["position"]
    var delta: Vector2 = (foe["position"] as Vector2) - p
    if delta.length_squared() < 0.001:
        return false
    var away: Vector2 = -delta.normalized()
    var forward: Vector2 = p + away * float(me["speed"]) * DT * float(ESCAPE_LOOKAHEAD_TICKS)
    var clipped: Vector2 = _clamp(forward)
    return forward.distance_to(clipped) > 0.1 or _wall_clearance(clipped) < ESCAPE_MARGIN

func _decide(i: int) -> Dictionary:
    var result: Dictionary = super._decide(i)
    if i != 0 or order != "KEEP_DISTANCE":
        return result
    if str(result["action"]) == "RETREAT" and _retreat_wall_risk(i):
        result["action"] = "ESCAPE"
        result["reason"] = str(result["reason"]) + " escape=lookahead_wall_risk"
    return result

func _escape_score(i: int, heading: Vector2) -> float:
    var me: Dictionary = units[i]
    var foe: Dictionary = units[1 - i]
    var start: Vector2 = me["position"]
    var step_distance: float = float(me["speed"]) * DT * ESCAPE_SPEED_FACTOR
    var desired: Vector2 = start + heading * step_distance * float(ESCAPE_LOOKAHEAD_TICKS)
    var reachable: Vector2 = _clamp(desired)
    var traveled: float = start.distance_to(reachable)
    var clipped: float = desired.distance_to(reachable)
    var opponent: Vector2 = foe["position"]
    # The opponent chases the candidate destination but cannot exceed its speed budget.
    var pursuit: Vector2 = reachable - opponent
    var foe_budget: float = float(foe["speed"]) * DT * float(ESCAPE_LOOKAHEAD_TICKS)
    var predicted_foe: Vector2 = opponent + pursuit.limit_length(foe_budget)
    var future_gap: float = reachable.distance_to(predicted_foe)
    var safety: float = clampf(_wall_clearance(reachable), 0.0, ESCAPE_MARGIN * 2.0)
    var old_heading: Vector2 = me["escape_heading"]
    var continuity: float = 2.5 * maxf(0.0, heading.dot(old_heading))
    # Prefer reachable space and distance from pursuer, heavily penalize clipping.
    return future_gap * 1.6 + traveled * 0.22 + safety * 0.75 - clipped * 3.0 + continuity

func _plan_escape(i: int) -> Vector2:
    var best_score: float = -INF
    var chosen: Vector2 = Vector2.ZERO
    for candidate in ESCAPE_DIRS:
        var heading: Vector2 = candidate.normalized()
        var score: float = _escape_score(i, heading)
        if score > best_score:
            best_score = score
            chosen = heading
    return chosen

func _apply_intent(i: int, intent: Dictionary) -> void:
    if str(intent["action"]) != "ESCAPE":
        super._apply_intent(i, intent)
        return
    var me: Dictionary = units[i]
    var foe: Dictionary = units[1 - i]
    var pos: Vector2 = me["position"]
    var heading: Vector2 = me["escape_heading"]
    var steps: float = float(me["speed"]) * DT * ESCAPE_SPEED_FACTOR
    var next: Vector2 = _clamp(pos + heading * steps)
    var must_replan: bool = tick_number >= int(me["escape_lock_until"]) or heading.length_squared() < 0.01
    if not must_replan and next.distance_to(pos) < steps * 0.70:
        must_replan = true
        me["wall_contacts"] = int(me["wall_contacts"]) + 1
    if must_replan:
        heading = _plan_escape(i)
        next = _clamp(pos + heading * steps)
        if int(me["escape_plans"]) > 0:
            me["escape_replans"] = int(me["escape_replans"]) + 1
        me["escape_plans"] = int(me["escape_plans"]) + 1
        me["escape_heading"] = heading
        me["escape_lock_until"] = tick_number + ESCAPE_LOCK_TICKS
        _emit("ESCAPE_PLAN unit=%d dir=%s wall_clearance=%.1f score=%.1f" % [
            i, str(heading), _wall_clearance(pos), _escape_score(i, heading)])
    if next.distance_to(pos) < steps * 0.70:
        me["wall_contacts"] = int(me["wall_contacts"]) + 1
    me["position"] = next
    var delta: Vector2 = (foe["position"] as Vector2) - next
    me["facing"] = delta.normalized() if delta.length_squared() > 0.001 else Vector2.RIGHT
    me["action"] = "ESCAPE"
    me["reason"] = str(intent["reason"])
    me["last_utility"] = intent["scores"]
    me["escape_steps"] = int(me["escape_steps"]) + 1
    me["retreat_steps"] = int(me["retreat_steps"]) + 1
    me["min_wall_clearance"] = minf(float(me["min_wall_clearance"]), _wall_clearance(next))
    units[i] = me
