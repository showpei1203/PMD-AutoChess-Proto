extends SceneTree
## G3.2 native Godot 4.7.2 parser/replay/spatial-probe gate. Must run on Surface.
const Core = preload("res://scripts/battle/g32_combat_core.gd")
const SEEDS = [20261017, 20365746, 31415926, 42, 777, 2025, 99991, 8008135]
const ORDERS = ["FREE", "AGGRESSIVE", "KEEP_DISTANCE", "DEFENSIVE"]
const CORNERS: Array[Vector2] = [
    Vector2(92, 152), Vector2(868, 152), Vector2(92, 366), Vector2(868, 366)]

func _initialize() -> void:
    var failures: int = 0
    var samples: int = 0
    var total_escape: int = 0
    var corner_success: int = 0
    for seed in SEEDS:
        for order in ORDERS:
            var a: Dictionary = _simulate(int(seed), str(order), -1)
            var b: Dictionary = _simulate(int(seed), str(order), -1)
            samples += 1
            if not bool(a["ok"]) or a["signature"] != b["signature"]:
                push_error("G32_GATE FAILED replay seed=%d order=%s" % [int(seed), str(order)])
                failures += 1
            if order == "KEEP_DISTANCE":
                total_escape += int(a["escape"])
            print("G32_GATE seed=%d order=%s signature=%s" % [int(seed), str(order), str(a["signature"])])
    for corner in range(CORNERS.size()):
        var a: Dictionary = _simulate(20261017, "KEEP_DISTANCE", corner)
        var b: Dictionary = _simulate(20261017, "KEEP_DISTANCE", corner)
        samples += 1
        if not bool(a["ok"]) or a["signature"] != b["signature"] or int(a["escape"]) == 0:
            push_error("G32_GATE FAILED corner=%d" % corner)
            failures += 1
        else:
            corner_success += 1
        print("G32_GATE CORNER=%d signature=%s escape=%d" % [corner, str(a["signature"]), int(a["escape"])])
    if total_escape == 0 or corner_success != CORNERS.size():
        failures += 1
        push_error("G32_GATE ESCAPE_NOT_EXERCISED total=%d corners=%d" % [total_escape, corner_success])
    print("G32_GATE ESCAPE_SUMMARY normal=%d corners=%d" % [total_escape, corner_success])
    print("G32_GATE RESULT samples=%d failures=%d" % [samples, failures])
    quit(0 if failures == 0 else 2)

func _simulate(seed: int, posture: String, corner: int) -> Dictionary:
    var c = Core.new()
    c.reset(seed, posture)
    if corner >= 0:
        var me: Dictionary = c.units[0]
        var foe: Dictionary = c.units[1]
        var p: Vector2 = CORNERS[corner]
        me["position"] = p
        var inward: Vector2 = Vector2(1, 1)
        if p.x > 480.0:
            inward.x = -1.0
        if p.y > 260.0:
            inward.y = -1.0
        foe["position"] = p + inward * 80.0
        c.units[0] = me
        c.units[1] = foe
    var bounds_ok: bool = true
    while int(c.get("winner")) == -1 and int(c.get("tick_number")) < Core.MAX_TICKS:
        c.step()
        for unit in c.units:
            var at: Vector2 = unit["position"]
            if at.x < Core.WEST - 0.1 or at.x > Core.EAST + 0.1 or at.y < Core.NORTH - 0.1 or at.y > Core.SOUTH + 0.1:
                bounds_ok = false
    var me: Dictionary = c.units[0]
    var signature: String = "%d:%d:%d:%d:%d:%d:%d:%d:%d" % [
        int(c.get("winner")), int(c.get("tick_number")),
        int(c.units[0]["hp"]), int(c.units[1]["hp"]), int(c.get("digest")),
        int(me["escape_steps"]), int(me["escape_plans"]),
        int(me["wall_contacts"]), int(me["zone_strikes"])]
    return {"ok": bounds_ok and int(c.get("winner")) != -1 and int(c.get("total_hits")) > 0,
        "signature": signature, "escape": int(me["escape_steps"])}
