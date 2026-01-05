extends CardState

const SCALE := 1.15
var original_scale: Vector2
var original_z: int

func _enter() -> void:
	original_scale = card.scale
	original_z = card.z_index

	card.scale = original_scale * SCALE
	card.z_index = 1000   # sempre sopra le altre

func on_input(event: InputEvent) -> void:
	if event.is_action_pressed("mouse_left"):
		transitioned.emit("click")

func on_mouse_exited() -> void:
	card.scale = original_scale
	card.z_index = original_z
	transitioned.emit("idle")
