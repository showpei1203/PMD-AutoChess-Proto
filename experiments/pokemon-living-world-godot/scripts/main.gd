extends Control

# Planning/bootstrap only. Intentionally no battle implementation or Pokémon
# imagery: the G0 source-rights and binary-integrity gate has not yet passed.
@onready var status: Label = $Status

func _ready() -> void:
    if status == null:
        push_error("Bootstrap scene missing Status Label")
        return
    print("[PLW] bootstrap ready; G0 asset/source verification PENDING")
