extends SceneTree
## REAL GODOT GDSCRIPT gate, executed on Surface before opening G3.1 scene.
## 8 seeds x 4 orders, each replayed twice. Godot runtime result is authoritative.
const Core = preload("res://scripts/battle/g31_combat_core.gd")
const SEEDS = [20261017, 20365746, 31415926, 42, 777, 2025, 99991, 8008135]
const ORDERS = ["FREE", "AGGRESSIVE", "KEEP_DISTANCE", "DEFENSIVE"]

func _initialize() -> void:
    var failures: int = 0
    var samples: int = 0
    var keep_retreat: int = 0
    var keep_strafe: int = 0
    var keep_projectile: int = 0
    for seed in SEEDS:
        for order in ORDERS:
            var a: Dictionary = _simulate(int(seed), str(order))
            var b: Dictionary = _simulate(int(seed), str(order))
            samples += 1
            if not bool(a["ok"]) or not bool(b["ok"]):
                push_error("G31_GATE RUN_FAIL seed=%d order=%s" % [int(seed), str(order)])
                failures += 1
                continue
            if a["signature"] != b["signature"]:
                push_error("G31_GATE NONDETERMINISTIC seed=%d order=%s" % [int(seed), str(order)])
                failures += 1
            print("G31_GATE seed=%d order=%s signature=%s" % [int(seed), str(order), str(a["signature"])])
            if order == "KEEP_DISTANCE":
                keep_retreat += int(a["retreat"])
                keep_strafe += int(a["strafe"])
                keep_projectile += int(a["ranged"])
    if keep_retreat <= 0 or keep_strafe <= 0 or keep_projectile <= 0:
        push_error("G31_GATE ZONING_MISSING retreat=%d strafe=%d ranged=%d" % [keep_retreat, keep_strafe, keep_projectile])
        failures += 1
    var unsupported = Core.new()
    unsupported.reset(20261017, "FREE")
    if unsupported.set_order("PROTECT_ALLY"):
        push_error("G31_GATE PROTECT_ALLY illegally active for 1v1")
        failures += 1
    print("G31_GATE ZONE_SUMMARY retreat=%d strafe=%d ranged=%d" % [keep_retreat, keep_strafe, keep_projectile])
    print("G31_GATE RESULT samples=%d failures=%d" % [samples, failures])
    quit(0 if failures == 0 else 2)

func _simulate(seed: int, posture: String) -> Dictionary:
    var c = Core.new()
    c.reset(seed, posture)
    while int(c.get("winner")) == -1 and int(c.get("tick_number")) <= Core.MAX_TICKS:
        c.step()
    var ok: bool = int(c.get("winner")) != -1 and int(c.get("total_hits")) > 0
    var u: Dictionary = c.units[0]
    var signature: String = "%d:%d:%d:%d:%d:%d:%d:%d:%d:%d" % [
        int(c.get("winner")), int(c.get("tick_number")),
        int(c.units[0]["hp"]), int(c.units[1]["hp"]),
        int(c.get("total_hits")), int(c.get("digest")),
        int(u["retreat_steps"]), int(u["strafe_steps"]),
        int(u["zone_strikes"]), int(u["guard_count"])]
    return {"ok": ok, "signature": signature,
        "retreat": int(u["retreat_steps"]), "strafe": int(u["strafe_steps"]),
        "ranged": int(u["zone_strikes"])}
