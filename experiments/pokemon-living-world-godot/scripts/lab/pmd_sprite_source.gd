extends RefCounted
## PMDCollab sheet reader (G1 lab only). No sprite bytes are stored in GitHub.
## One sheet is arranged in horizontal frames and vertical facing rows.
## The row-to-compass mapping remains unverified; controls expose raw row IDs.
const ROOT: String = "res://data/raw/pmdcollab/"
const TICK_RATE: float = 60.0
var textures: Dictionary = {}
var definitions: Dictionary = {}
var errors: Array[String] = []

func load_species(species_id: int) -> bool:
    errors.clear()
    var key: String = "%04d" % species_id
    var xml_path: String = ROOT + key + "/AnimData.xml"
    if not FileAccess.file_exists(xml_path):
        errors.append("Missing AnimData.xml: " + xml_path)
        return false
    var parser := XMLParser.new()
    var err: Error = parser.open(xml_path)
    if err != OK:
        errors.append("Failed to open XML: " + str(err))
        return false
    var parsed: Dictionary = {}
    var tags: Array[String] = []
    var current: Dictionary = {}
    while true:
        var state: Error = parser.read()
        if state == ERR_FILE_EOF:
            break
        if state != OK:
            errors.append("Invalid XML: " + str(state))
            return false
        var kind: int = parser.get_node_type()
        if kind == XMLParser.NODE_ELEMENT:
            var element: String = parser.get_node_name()
            tags.append(element)
            if element == "Anim":
                current = {"name": "", "copy_of": "", "width": 0, "height": 0, "durations": []}
            if parser.is_empty():
                tags.pop_back()
        elif kind == XMLParser.NODE_TEXT:
            if tags.is_empty() or current.is_empty():
                continue
            var data: String = parser.get_node_data().strip_edges()
            if data.is_empty():
                continue
            var tag: String = tags.back()
            match tag:
                "Name": current["name"] = data
                "CopyOf": current["copy_of"] = data
                "FrameWidth": current["width"] = data.to_int()
                "FrameHeight": current["height"] = data.to_int()
                "Duration": (current["durations"] as Array).append(maxi(1, data.to_int()))
        elif kind == XMLParser.NODE_ELEMENT_END:
            var close: String = parser.get_node_name()
            if close == "Anim" and not current.is_empty():
                var action: String = str(current.get("name", ""))
                if not action.is_empty():
                    parsed[action] = current.duplicate(true)
                current = {}
            if tags.is_empty() or tags.back() != close:
                errors.append("XML tag mismatch: " + close)
                return false
            tags.pop_back()
    if parsed.is_empty():
        errors.append("No animations in " + xml_path)
        return false
    definitions = parsed
    textures.clear()
    return true

func resolve_action(action: String) -> Dictionary:
    var seen: Dictionary = {}
    var original: String = action
    var requested: String = action
    # A finite condition plus the final explicit return is required so Godot's
    # typed-function analyzer sees a return value on EVERY possible path.
    while not requested.is_empty():
        if seen.has(requested):
            errors.append("CopyOf loop: " + original)
            return {}
        seen[requested] = true
        if not definitions.has(requested):
            errors.append("Action unavailable: " + requested)
            return {}
        var data: Dictionary = definitions[requested]
        var parent_action: String = str(data.get("copy_of", "")).strip_edges()
        if parent_action.is_empty():
            return data
        requested = parent_action
    # Also protects empty initial action names. Keep all failure paths typed.
    errors.append("Empty animation action: " + original)
    return {}

func get_animation(action: String, direction_row: int) -> Dictionary:
    var resolved: Dictionary = resolve_action(action)
    if resolved.is_empty():
        return {}
    var source_action: String = str(resolved["name"])
    var filename: String = source_action + "-Anim.png"
    var sheet_path: String = ROOT + str(species_key()) + "/" + filename
    if not FileAccess.file_exists(sheet_path):
        errors.append("Missing sheet " + sheet_path)
        return {}
    if not textures.has(source_action):
        var image := Image.new()
        if image.load(sheet_path) != OK:
            errors.append("Failed to read image " + sheet_path)
            return {}
        textures[source_action] = ImageTexture.create_from_image(image)
    var texture: Texture2D = textures[source_action]
    var frame_width: int = int(resolved.get("width", 0))
    var frame_height: int = int(resolved.get("height", 0))
    if frame_width <= 0 or frame_height <= 0:
        errors.append("Invalid dimensions: " + source_action)
        return {}
    if texture.get_width() % frame_width != 0 or texture.get_height() % frame_height != 0:
        errors.append("Sheet dimensions incompatible: " + sheet_path)
        return {}
    var cols: int = int(float(texture.get_width()) / float(frame_width))
    var rows: int = int(float(texture.get_height()) / float(frame_height))
    if direction_row < 0 or direction_row >= rows:
        errors.append("Direction row out of range: " + source_action)
        return {}
    var durations: Array = resolved.get("durations", [])
    if durations.is_empty() or durations.size() > cols:
        errors.append("Frame count incompatible: " + source_action)
        return {}
    var result: Array[Texture2D] = []
    for i in range(durations.size()):
        var crop := AtlasTexture.new()
        crop.atlas = texture
        crop.region = Rect2(i * frame_width, direction_row * frame_height, frame_width, frame_height)
        crop.filter_clip = true
        result.append(crop)
    return {"textures": result, "durations": durations, "rows": rows,
        "sheet": source_action, "width": frame_width, "height": frame_height}

var _id: int = -1
func set_species_id(value: int) -> void:
    _id = value
func species_key() -> String:
    return "%04d" % _id

func make_frames(direction_row: int, actions: Array) -> SpriteFrames:
    var frames := SpriteFrames.new()
    if frames.has_animation("default"):
        frames.remove_animation("default")
    for action in actions:
        if not definitions.has(action):
            continue
        var entry: Dictionary = get_animation(action, direction_row)
        if entry.is_empty():
            continue
        frames.add_animation(action)
        frames.set_animation_speed(action, TICK_RATE)
        frames.set_animation_loop(action, action != "Attack")
        var images: Array = entry["textures"]
        var delays: Array = entry["durations"]
        for i in range(images.size()):
            frames.add_frame(action, images[i] as Texture2D, float(delays[i]))
    return frames
