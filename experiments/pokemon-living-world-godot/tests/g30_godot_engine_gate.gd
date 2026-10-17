extends SceneTree
## REAL GODOT PARSER/RUNTIME GATE. Called --headless before showing 1v1 scene.
const Core = preload("res://scripts/battle/g30_combat_core.gd")
const SEEDS = [20261017, 20365746, 31415926]
const ORDERS = ["FREE", "AGGRESSIVE", "KEEP_DISTANCE", "DEFENSIVE"]

func _initialize() -> void:
    var failures: int = 0
    var samples: int = 0
    for seed in SEEDS:
        for order in ORDERS:
            var first = _simulate(int(seed), str(order))
            var repeat = _simulate(int(seed), str(order))
            samples += 1
            if not bool(first["ok"]) or not bool(repeat["ok"]):
                push_error("G30_GATE FAILED run failed seed=%d order=%s" % [int(seed),str(order)])
                failures += 1
                continue
            if first["signature"] != repeat["signature"]:
                push_error("G30_GATE FAILED nondeterministic replay seed=%d order=%s" % [int(seed),str(order)])
                failures += 1
            print("G30_GATE seed=%d order=%s signature=%s" % [int(seed),str(order),str(first["signature"])])
    var missing_team = Core.new()
    missing_team.reset(20261017, "FREE")
    if missing_team.set_order("PROTECT_ALLY"):
        push_error("G30_GATE FAILED PROTECT_ALLY illegally active in 1v1")
        failures += 1
    print("G30_GATE RESULT samples=%d failures=%d" % [samples, failures])
    quit(0 if failures == 0 else 2)

func _simulate(seed: int, order_name: String) -> Dictionary:
    var battle = Core.new()
    battle.reset(seed, order_name)
    while int(battle.get("winner")) == -1 and int(battle.get("tick_number")) < Core.MAX_TICKS + 1:
        battle.step()
    var result_ok: bool = int(battle.get("winner")) != -1 and int(battle.get("total_hits")) > 0
    var signature: String = "%d:%d:%d:%d:%d:%d" % [
        int(battle.get("winner")), int(battle.get("tick_number")),
        int(battle.units[0]["hp"]), int(battle.units[1]["hp"]),
        int(battle.get("total_hits")), int(battle.get("digest"))]
    if not result_ok:
        push_error("G30_GATE FAILED no terminal hits seed=%d order=%s" % [seed,order_name])
    return {"ok": result_ok, "signature": signature}
