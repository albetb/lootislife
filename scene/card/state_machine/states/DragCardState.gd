extends CardState

var drag_offset := Vector2.ZERO
var dragging := false
var original_rotation := 0.0
var original_z := 0

func _enter() -> void:
	if not Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		transitioned.emit("idle")
		return

	dragging = true
	original_rotation = card.rotation
	original_z = card.z_index
	
	card.reset_visual_state()

	card.rotation = 0.0
	card.z_index = 1000

	var global_pos := card.global_position
	drag_offset = global_pos - card.get_global_mouse_position()

	card.home_field.remove_card(card)
	card.reparent(card.drag_layer)
	card.global_position = global_pos

func _process(delta: float) -> void:
	if not dragging:
		return

	var target := card.get_global_mouse_position() + drag_offset
	card.global_position = card.global_position.lerp(
	target,
	min(1.0, 18.0 * delta)
)

func on_input(event: InputEvent) -> void:
	if event.is_action_released("mouse_left"):
		dragging = false
		card.rotation = original_rotation
		card.z_index = original_z
		transitioned.emit("release")
		
func _exit() -> void:
	dragging = false
