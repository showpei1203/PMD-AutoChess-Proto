extends "res://scripts/battle/g31_combat_lab.gd"
## G3.2 standalone spatial escape visualization. G3.1 scene/core byte-exact.
const G32Core = preload("res://scripts/battle/g32_combat_core.gd")

func _ready() -> void:
    super._ready()
    core = G32Core.new()
    _reset_battle(20261017, "FREE")
    title_label.text = "Pokémon Living World | G3.2 戰場預判／角落脫困"
    hint_label.text = "G3.2 測試：多方向預判逃脫／角落回旋；仍非寶可夢正式招式與地形導航"
    print("[PLW-G32] READY | deterministic escape planner enabled")

# Render all displacement actions as moving Walk without changing any attack timing.
func _physics_process(delta: float) -> void:
    super._physics_process(delta)
    if core == null:
        return
    for i in range(renderers.size()):
        var view: Dictionary = renderers[i]
        if not bool(view["ready"]):
            continue
        var action: String = str(core.units[i]["action"])
        if action in ["RETREAT", "STRAFE", "ESCAPE"]:
            var sprite: AnimatedSprite2D = view["sprite"]
            sprite.speed_scale = Visual.playback_speed(int(view["id"]), "MOVE")
