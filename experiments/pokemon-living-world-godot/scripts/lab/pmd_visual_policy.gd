extends RefCounted
## G2.2 isolated visual policy, not AI state authority and not physics.
## PMD sprite source direction rows: S0, SE1, E2, NE3, N4, NW5, W6, SW7.
## Godot +Y points DOWN. For 0 degrees (east), select row 2.
const FACING_NAMES: Array[String] = ["S", "SE", "E", "NE", "N", "NW", "W", "SW"]

static func direction_row(travel: Vector2) -> int:
    if travel.length_squared() < 0.0001:
        return 0  # Caller must preserve the previous facing when stopped.
    var sector: int = roundi(rad_to_deg(travel.angle()) / 45.0)
    return posmod(2 - sector, 8)

static func facing_name(row: int) -> String:
    return FACING_NAMES[posmod(row, 8)]

static func playback_speed(species_id: int, mode: String) -> float:
    match species_id:
        25:
            return 1.32 if mode == "MOVE" else 0.90
        94:
            return 1.00 if mode == "MOVE" else 0.85
        143:
            return 0.58 if mode == "MOVE" else 0.72
    return 1.0

static func next_pose_delay(species_id: int, rng: RandomNumberGenerator) -> float:
    match species_id:
        25:
            return rng.randf_range(3.5, 6.0)
        94:
            return rng.randf_range(7.0, 12.0)
        143:
            return rng.randf_range(12.0, 19.0)
    return rng.randf_range(7.0, 14.0)
