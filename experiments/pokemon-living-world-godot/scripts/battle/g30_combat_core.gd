extends RefCounted
## G3.0 deterministic, fixed-tick 1v1 authority. Visual animation is never hit authority.
## Prototype combat math is NOT official Pokémon type/stat/damage mechanics.
const DT: float = 0.1
const MAX_TICKS: int = 600
const WEST: float = 85.0
const EAST: float = 875.0
const NORTH: float = 145.0
const SOUTH: float = 373.0
const SEED_JUMP: int = 104729
const ORDER_NAMES = ["FREE", "AGGRESSIVE", "KEEP_DISTANCE", "DEFENSIVE"]
const ACTIONS = ["APPROACH", "ATTACK", "GUARD", "DODGE", "CIRCLE", "WINDUP", "DOWN"]
const BASE_UNIT_STATS = [
    {"id": 25, "label": "#025 皮卡丘", "hp": 85, "power": 12, "speed": 57.0,
     "range": 78.0, "cooldown_ticks": 11, "windup_ticks": 3},
    {"id": 94, "label": "#094 耿鬼", "hp": 94, "power": 11, "speed": 43.0,
     "range": 85.0, "cooldown_ticks": 13, "windup_ticks": 4}
]

var seed: int = 20261017
var random_state: int = 1
var tick_number: int = 0
var simulated_time: float = 0.0
var winner: int = -1  # -1 running, 0/1 winner, 2 tie
var result_reason: String = ""
var order: String = "FREE"
var units: Array[Dictionary] = []
var trace: Array[String] = []
var total_hits: int = 0
var total_misses: int = 0
var digest: int = 7

func _next_random() -> int:
    random_state = (random_state * 1103515245 + 12345) & 2147483647
    return random_state

func reset(new_seed: int = 20261017, new_order: String = "FREE") -> void:
    seed = new_seed
    random_state = (new_seed & 2147483647)
    if random_state == 0:
        random_state = 1
    tick_number = 0
    simulated_time = 0.0
    winner = -1
    result_reason = ""
    order = new_order if ORDER_NAMES.has(new_order) else "FREE"
    units.clear()
    trace.clear()
    total_hits = 0
    total_misses = 0
    digest = 7
    var v0: int = _next_random() % 59 - 29
    var v1: int = _next_random() % 59 - 29
    for i in range(2):
        var s: Dictionary = BASE_UNIT_STATS[i]
        var p: Vector2 = Vector2(250.0 if i == 0 else 710.0, 264.0 + float(v0 if i == 0 else v1))
        units.append({"id": int(s["id"]), "label": str(s["label"]),
            "hp": int(s["hp"]), "max_hp": int(s["hp"]), "power": int(s["power"]),
            "speed": float(s["speed"]), "range": float(s["range"]),
            "cooldown_ticks": int(s["cooldown_ticks"]), "windup_ticks": int(s["windup_ticks"]),
            "position": p, "facing": Vector2.RIGHT if i == 0 else Vector2.LEFT,
            "action": "APPROACH", "reason": "initial sighting", "cooldown": 0,
            "strike_at": -1, "dodge_ready_at": 0, "guard_until": 0,
            "damage_done": 0, "hits": 0, "misses": 0,
            "last_utility": {}, "intent_counter": 0})
    _emit("SESSION seed=%d order=%s start=%s/%s" % [seed, order, str(units[0]["position"]), str(units[1]["position"])])

func set_order(value: String) -> bool:
    if not ORDER_NAMES.has(value):
        _emit("ORDER_REJECTED %s (PROTECT_ALLY requires 2v2)" % value)
        return false
    order = value
    _emit("ORDER %s" % order)
    return true

func _emit(s: String) -> void:
    trace.append("tick=%d t=%.1f %s" % [tick_number, simulated_time, s])

func _utility(i: int) -> Dictionary:
    var me: Dictionary = units[i]
    var foe: Dictionary = units[1 - i]
    var dist: float = (me["position"] as Vector2).distance_to(foe["position"] as Vector2)
    var enemy_telegraph: bool = int(foe["strike_at"]) >= tick_number
    var can_attack: bool = int(me["cooldown"]) <= 0 and int(me["strike_at"]) < 0
    var scores: Dictionary = {"APPROACH": -100.0, "ATTACK": -100.0,
        "GUARD": -100.0, "DODGE": -100.0, "CIRCLE": 10.0}
    if dist > float(me["range"]) - 6.0:
        scores["APPROACH"] = 80.0 + minf(8.0, dist / 95.0)
    elif can_attack:
        scores["ATTACK"] = 110.0
    else:
        scores["CIRCLE"] = 30.0
    if enemy_telegraph and dist < float(foe["range"]) + 12.0:
        if tick_number >= int(me["dodge_ready_at"]) and int(me["hp"]) * 2 < int(me["max_hp"]):
            scores["DODGE"] = 115.0
        elif int(me["guard_until"]) < tick_number and (i == 1 or order == "DEFENSIVE"):
            scores["GUARD"] = 107.0 if i == 1 else 118.0
    if i == 0:
        match order:
            "AGGRESSIVE":
                scores["ATTACK"] = float(scores["ATTACK"]) + 15.0 if can_attack else -100.0
                scores["GUARD"] = -100.0
            "KEEP_DISTANCE":
                if enemy_telegraph and dist < float(foe["range"]) + 30.0:
                    scores["DODGE"] = 119.0 if tick_number >= int(me["dodge_ready_at"]) else -100.0
                if dist > float(me["range"]):
                    scores["APPROACH"] = maxf(float(scores["APPROACH"]), 92.0)
            "DEFENSIVE":
                scores["GUARD"] = float(scores["GUARD"]) + 5.0 if float(scores["GUARD"]) > 0.0 else -100.0
    return {"distance": dist, "enemy_telegraph": enemy_telegraph,
        "scores": scores, "can_attack": can_attack}

func _decide(i: int) -> Dictionary:
    var me: Dictionary = units[i]
    if int(me["hp"]) <= 0:
        return {"action": "DOWN", "reason": "hp=0", "scores": {}}
    if int(me["strike_at"]) >= 0:
        return {"action": "WINDUP", "reason": "attack telegraph; hit scheduled tick %d" % int(me["strike_at"]), "scores": {}}
    var u: Dictionary = _utility(i)
    var scores: Dictionary = u["scores"]
    var action: String = "CIRCLE"
    var best: float = -999.0
    # This action order is the deterministic score tie-breaker.
    for name in ["ATTACK", "GUARD", "DODGE", "APPROACH", "CIRCLE"]:
        if float(scores[name]) > best:
            best = float(scores[name])
            action = name
    var reason: String = "distance=%.1f range=%.1f cooldown=%d foe_telegraph=%s utility=%.1f order=%s" % [
        float(u["distance"]), float(me["range"]), int(me["cooldown"]),
        str(u["enemy_telegraph"]), best, order if i == 0 else "WILD"]
    return {"action": action, "reason": reason, "scores": scores}

func _clamp(p: Vector2) -> Vector2:
    return Vector2(clampf(p.x, WEST, EAST), clampf(p.y, NORTH, SOUTH))

func _apply_intent(i: int, intent: Dictionary) -> void:
    var me: Dictionary = units[i]
    var enemy: Dictionary = units[1 - i]
    var pos: Vector2 = me["position"]
    var aim: Vector2 = enemy["position"]
    var delta: Vector2 = aim - pos
    var direction: Vector2 = delta.normalized() if delta.length_squared() > 0.001 else Vector2.RIGHT
    var action: String = str(intent["action"])
    var prev_action: String = str(me["action"])
    me["action"] = action
    me["reason"] = str(intent["reason"])
    me["last_utility"] = intent["scores"]
    match action:
        "APPROACH":
            var next: Vector2 = _clamp(pos + direction * float(me["speed"]) * DT)
            me["facing"] = direction
            me["position"] = next
        "DODGE":
            var escape: Vector2 = -direction
            me["position"] = _clamp(pos + escape * float(me["speed"]) * DT * 2.1)
            me["facing"] = escape
            me["dodge_ready_at"] = tick_number + 22
            _emit("DODGE unit=%d cooldown_until=%d" % [i, int(me["dodge_ready_at"])])
        "GUARD":
            me["guard_until"] = tick_number + 4
        "CIRCLE":
            # Do not create a second chase; small deterministic sidestep when readying strike.
            var side: Vector2 = Vector2(-direction.y, direction.x)
            me["position"] = _clamp(pos + side * float(me["speed"]) * DT * 0.12)
            me["facing"] = direction
        "ATTACK":
            me["strike_at"] = tick_number + int(me["windup_ticks"])
            me["cooldown"] = maxi(5, int(me["cooldown_ticks"]) - 2) if i == 0 and order == "AGGRESSIVE" else int(me["cooldown_ticks"])
            me["intent_counter"] = int(me["intent_counter"]) + 1
            me["facing"] = direction
            _emit("WINDUP unit=%d target=%d resolve_tick=%d power=%d" % [i, 1-i, int(me["strike_at"]), int(me["power"])])
    if prev_action != action:
        _emit("DECISION unit=%d action=%s %s" % [i, action, str(me["reason"])])
    units[i] = me

func _resolve_hits() -> void:
    var planned: Array[Dictionary] = []
    for i in range(units.size()):
        var me: Dictionary = units[i]
        if int(me["strike_at"]) != tick_number:
            continue
        var foe: Dictionary = units[1 - i]
        var dist: float = (me["position"] as Vector2).distance_to(foe["position"] as Vector2)
        var in_range: bool = dist <= float(me["range"]) + 12.0
        var defended: bool = int(foe["guard_until"]) >= tick_number
        var damage: int = maxi(1, int(floor(float(me["power"]) * 0.5))) if defended else int(me["power"])
        planned.append({"attacker": i, "target": 1-i, "in_range": in_range,
            "guarded": defended, "damage": damage, "distance": dist})
        me["strike_at"] = -1
        units[i] = me
    # Snapshot-based resolution: if both hits land on the same tick, both count.
    for hit in planned:
        var attacker: int = int(hit["attacker"])
        var target: int = int(hit["target"])
        var source: Dictionary = units[attacker]
        var enemy: Dictionary = units[target]
        if bool(hit["in_range"]):
            enemy["hp"] = maxi(0, int(enemy["hp"]) - int(hit["damage"]))
            source["hits"] = int(source["hits"]) + 1
            source["damage_done"] = int(source["damage_done"]) + int(hit["damage"])
            total_hits += 1
            _emit("HIT actor=%d target=%d damage=%d guard=%s target_hp=%d dist=%.1f" % [
                attacker, target, int(hit["damage"]), str(hit["guarded"]),
                int(enemy["hp"]), float(hit["distance"])])
        else:
            source["misses"] = int(source["misses"]) + 1
            total_misses += 1
            _emit("MISS actor=%d target=%d reason=out_of_range distance=%.1f" % [
                attacker, target, float(hit["distance"])])
        units[attacker] = source
        units[target] = enemy

func _finish(reason: String) -> void:
    if winner != -1:
        return
    var a: int = int(units[0]["hp"])
    var b: int = int(units[1]["hp"])
    if a <= 0 and b <= 0:
        winner = 2
    elif a <= 0:
        winner = 1
    elif b <= 0:
        winner = 0
    else:
        var percent_a: float = float(a) / float(units[0]["max_hp"])
        var percent_b: float = float(b) / float(units[1]["max_hp"])
        if absf(percent_a-percent_b) < 0.0001:
            winner = 2
        else:
            winner = 0 if percent_a > percent_b else 1
    result_reason = reason
    _emit("RESULT winner=%d reason=%s hp=%d/%d hits=%d misses=%d digest=%d seed=%d" % [
        winner, reason, a, b, total_hits, total_misses, digest, seed])

func step() -> void:
    if winner != -1:
        return
    tick_number += 1
    simulated_time += DT
    for i in range(2):
        var f: Dictionary = units[i]
        f["cooldown"] = maxi(0, int(f["cooldown"]) - 1)
        units[i] = f
    # Snapshot decisions first, then movement: prevents first-agent decision bias.
    var intents: Array[Dictionary] = []
    for i in range(2):
        intents.append(_decide(i))
    for i in range(2):
        _apply_intent(i, intents[i])
        # Detailed explainability at 1Hz, plus all transitions and hit events.
        if tick_number % 10 == 0:
            _emit("WHY unit=%d action=%s %s scores=%s" % [
                i, str(intents[i]["action"]), str(intents[i]["reason"]), str(intents[i]["scores"])])
    _resolve_hits()
    var stamp: int = tick_number
    for f in units:
        var p: Vector2 = f["position"]
        stamp += int(f["hp"]) * 103 + int(p.x * 10.0) * 11 + int(p.y * 10.0) * 7
    digest = (digest * 31 + stamp) % 2147483647
    if int(units[0]["hp"]) <= 0 or int(units[1]["hp"]) <= 0:
        _finish("KO")
    elif tick_number >= MAX_TICKS:
        _finish("TIMEOUT_HP_RATIO")
