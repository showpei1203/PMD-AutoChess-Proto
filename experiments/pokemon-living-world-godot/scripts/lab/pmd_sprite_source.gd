extends RefCounted
## PMDCollab sheet reader (G1 lab only). No sprite bytes are stored in GitHub.
## One sheet is arranged in horizontal frames and vertical facing rows.
## The row-to-compass mapping remains unverified; controls expose raw row IDs.
const ROOT: String = "res://data/raw/pmdcollab/"
const TICK_RATE: float = 60.0
var textures: Dictionary = {}
var definitions: Dictionary = {}
var errors: Array[String] = []
# Cached CPU-side PNG images and per-frame anchor analysis, only for currently viewed species.
var anchor_images: Dictionary = {}
var anchor_cache: Dictionary = {}

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
    # PMDCollab AnimData.xml can contain CRLF, legacy formatting and CopyOf.
    # XMLParser is a streaming token reader, not a strict DOM validator. Keep
    # state for the actual Anim records instead of maintaining an extra stack
    # that can reject otherwise usable upstream documents.
    var parsed: Dictionary = {}
    var current: Dictionary = {}
    var active_field: String = ""
    var saw_root: bool = false
    while true:
        var state: Error = parser.read()
        if state == ERR_FILE_EOF:
            break
        if state != OK:
            errors.append("Invalid XML: " + str(state))
            return false
        var kind: int = parser.get_node_type()
        if kind == XMLParser.NODE_ELEMENT:
            var element: String = parser.get_node_name().strip_edges()
            if element == "AnimData":
                saw_root = true
            elif element == "Anim":
                current = {"name": "", "copy_of": "", "width": 0, "height": 0, "durations": []}
                active_field = ""
            elif not current.is_empty():
                match element:
                    "Name", "CopyOf", "FrameWidth", "FrameHeight", "Duration":
                        active_field = element
                    _:
                        active_field = ""
            if parser.is_empty() and element == active_field:
                active_field = ""
        elif kind == XMLParser.NODE_TEXT:
            if current.is_empty() or active_field.is_empty():
                continue
            var data: String = parser.get_node_data().strip_edges()
            if data.is_empty():
                continue
            match active_field:
                "Name": current["name"] = data
                "CopyOf": current["copy_of"] = data
                "FrameWidth": current["width"] = data.to_int()
                "FrameHeight": current["height"] = data.to_int()
                "Duration": (current["durations"] as Array).append(maxi(1, data.to_int()))
        elif kind == XMLParser.NODE_ELEMENT_END:
            var close: String = parser.get_node_name().strip_edges()
            if close == "Anim" and not current.is_empty():
                var action: String = str(current.get("name", "")).strip_edges()
                if not action.is_empty():
                    if parsed.has(action):
                        errors.append("Duplicate animation: " + action)
                        return false
                    parsed[action] = current.duplicate(true)
                current = {}
                active_field = ""
            elif close == active_field:
                active_field = ""
    if not saw_root:
        errors.append("Missing AnimData XML root: " + xml_path)
        return false
    if parsed.is_empty():
        errors.append("No animations in " + xml_path)
        return false
    definitions = parsed
    textures.clear()
    anchor_images.clear()
    anchor_cache.clear()
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
        # PNGs inside res:// must use the Godot-imported Texture2D resource.
        # Image.load() works in the editor but warns and may fail on export.
        var imported_texture: Resource = ResourceLoader.load(sheet_path, "Texture2D")
        if not (imported_texture is Texture2D):
            errors.append("Failed to import Texture2D: " + sheet_path)
            return {}
        textures[source_action] = imported_texture as Texture2D
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

# G1.2.1: Find the *actual* anchor per PMDCollab frame. The format specifies:
# - <Action>-Shadow.png: white pixel marks original ground/shadow center.
# - <Action>-Offsets.png: green body center / red-blue hands / black head.
# Offsets.png is NOT a ground/foot reference. Prefer native shadow markers.
# If shadow marker is absent, use the nontransparent sprite bottom as a *visual*
# fallback only. This may flatten intentional jump or flight displacement.
func _anchor_image(path: String) -> Image:
    if anchor_images.has(path):
        return anchor_images[path] as Image
    # A few community animations omit a native Shadow sheet. Missing optional
    # sheets should trigger alpha fallback, NOT an engine error in Output.
    if not ResourceLoader.exists(path, "Texture2D"):
        return null
    var res: Resource = ResourceLoader.load(path, "Texture2D")
    if not (res is Texture2D):
        return null
    var img: Image = (res as Texture2D).get_image()
    if img == null or img.is_empty():
        return null
    anchor_images[path] = img
    return img

func _alpha_bounds(image: Image, area: Rect2i) -> Rect2i:
    var left: int = area.position.x + area.size.x
    var top: int = area.position.y + area.size.y
    var right: int = area.position.x - 1
    var bottom: int = area.position.y - 1
    for y in range(area.position.y, area.end.y):
        for x in range(area.position.x, area.end.x):
            if image.get_pixel(x, y).a > 0.10:
                left = mini(left, x)
                top = mini(top, y)
                right = maxi(right, x)
                bottom = maxi(bottom, y)
    if right < left:
        return Rect2i()
    return Rect2i(left - area.position.x, top - area.position.y, right - left + 1, bottom - top + 1)

func _native_shadow_center(image: Image, area: Rect2i) -> Dictionary:
    # PMD Shadow.png white pixel is the official shadow center. Other colored
    # shadow markers encode shadow SIZE and must not be mistaken for feet.
    var total: Vector2 = Vector2.ZERO
    var count: int = 0
    for y in range(area.position.y, area.end.y):
        for x in range(area.position.x, area.end.x):
            var p: Color = image.get_pixel(x, y)
            if p.a > 0.5 and p.r > 0.94 and p.g > 0.94 and p.b > 0.94:
                total += Vector2(float(x - area.position.x) + 0.5, float(y - area.position.y) + 0.5)
                count += 1
    if count < 1 or count > 16:
        return {}
    return {"point": total / float(count), "white_pixel_count": count}

func get_frame_alignment(action: String, direction_row: int, frame_index: int) -> Dictionary:
    # The frame/grid is taken from AnimData.xml, *not* an arbitrary SpriteFrames
    # max dimensions. CopyOf correctly resolves to a single real source sheet.
    var resolved: Dictionary = resolve_action(action)
    if resolved.is_empty():
        return {}
    var sheet: String = str(resolved.get("name", ""))
    var width: int = int(resolved.get("width", 0))
    var height: int = int(resolved.get("height", 0))
    var durations: Array = resolved.get("durations", [])
    if width <= 0 or height <= 0 or frame_index < 0 or frame_index >= durations.size() or direction_row < 0:
        return {}
    var key: String = "%s:%d:%d" % [sheet, direction_row, frame_index]
    if anchor_cache.has(key):
        return anchor_cache[key]
    var directory: String = ROOT + species_key() + "/"
    var anim: Image = _anchor_image(directory + sheet + "-Anim.png")
    if anim == null:
        return {}
    var cell: Rect2i = Rect2i(frame_index * width, direction_row * height, width, height)
    if cell.end.x > anim.get_width() or cell.end.y > anim.get_height():
        return {}
    var alpha: Rect2i = _alpha_bounds(anim, cell)
    var center_x: float = float(width) / 2.0
    var alpha_point: Vector2 = Vector2(center_x, float(height))
    if alpha.has_area():
        # Exclusive lower edge, avoids frame-height bias when PNG has empty rows.
        alpha_point.y = float(alpha.position.y + alpha.size.y)
    var result: Dictionary = {
        "frame_size": Vector2(float(width), float(height)),
        "ink_bounds": Rect2(Vector2(alpha.position), Vector2(alpha.size)),
        "frame_point": Vector2(center_x, float(height)),
        "ink_point": alpha_point,
        "ground_point": alpha_point,
        "reason": "ALPHA_BOTTOM_FALLBACK" if alpha.has_area() else "EMPTY_FRAME_FALLBACK",
        "native_found": false,
        "native_white_pixels": 0
    }
    var shadow: Image = _anchor_image(directory + sheet + "-Shadow.png")
    if shadow != null and shadow.get_width() >= cell.end.x and shadow.get_height() >= cell.end.y:
        var native: Dictionary = _native_shadow_center(shadow, cell)
        if not native.is_empty():
            result["ground_point"] = native["point"]
            result["reason"] = "PMD_SHADOW_CENTER"
            result["native_found"] = true
            result["native_white_pixels"] = native["white_pixel_count"]
    anchor_cache[key] = result
    return result
