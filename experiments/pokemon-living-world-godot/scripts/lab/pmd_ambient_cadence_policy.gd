extends RefCounted
## G2.3 species-specific visual cadence. Pure data; never drives AI or movement.
## Tune these independently from SpriteCollab frame durations.
const MovePolicy = preload("res://scripts/lab/pmd_visual_policy.gd")
const CADENCE = {
    25: {"stance": 0.26, "idle": 0.95, "float": 0.70, "pose": 0.78,
         "nod": 0.75, "wait_min": 5.0, "wait_max": 8.5,
         "actions": ["Idle", "Idle", "Pose"]},
    94: {"stance": 0.17, "idle": 0.70, "float": 0.40, "pose": 0.62,
         "nod": 0.60, "wait_min": 8.0, "wait_max": 13.5,
         "actions": ["Float", "Float", "Idle", "Pose"]},
    143: {"stance": 0.09, "idle": 0.35, "float": 0.28, "pose": 0.38,
          "nod": 0.45, "wait_min": 18.0, "wait_max": 28.0,
          "actions": ["Nod", "Nod", "Idle", "NONE"]},
}

static func profile(species_id: int) -> Dictionary:
    if CADENCE.has(species_id):
        return CADENCE[species_id]
    return {"stance": 0.18, "idle": 0.65, "float": 0.48,
            "pose": 0.65, "nod": 0.65, "wait_min": 8.0,
            "wait_max": 14.0, "actions": ["Idle"]}

static func speed(species_id: int, mode: String) -> float:
    if mode == "MOVE":
        return MovePolicy.playback_speed(species_id, "MOVE")
    var data: Dictionary = profile(species_id)
    if mode == "STANCE":
        return float(data["stance"])
    if mode.begins_with("MICRO_"):
        return float(data.get(mode.trim_prefix("MICRO_").to_lower(), data["idle"]))
    return float(data["stance"])

static func next_delay(species_id: int, rng: RandomNumberGenerator) -> float:
    var data: Dictionary = profile(species_id)
    return rng.randf_range(float(data["wait_min"]), float(data["wait_max"]))

static func next_action(species_id: int, rng: RandomNumberGenerator) -> String:
    var data: Dictionary = profile(species_id)
    var actions: Array = data["actions"]
    return str(actions[rng.randi_range(0, actions.size() - 1)])
