class_name HandInsertController
extends Node

var cards_root: Node2D
var layout: HandLayoutController
var drag: HandDragController

@export var vertical_tolerance := 200.0   # quanto lontano sopra/sotto accetti l’insert

func update_insert(mouse_global_pos: Vector2) -> void:
	if drag == null or layout == null or cards_root == null:
		return

	if drag.dragging_card == null:
		drag.insert_active = false
		drag.insert_index = -1
		return

	var cards := cards_root.get_children()
	if cards.is_empty():
		drag.insert_active = false
		drag.insert_index = 0
		return

	# posizione mouse nello spazio della mano
	var local := cards_root.to_local(mouse_global_pos)

	# controllo verticale semplice (evita insert da troppo lontano)
	if abs(local.y) > vertical_tolerance:
		drag.insert_active = false
		drag.insert_index = -1
		return

	# --- FAN GEOMETRICO ---
	var count := cards.size()
	var center := (count - 1) * 0.5
	var card_width := (cards[0] as Card).get_card_width()

	# stessi parametri del layout
	var arc_step := card_width * (1.0 - layout.overlap)
	var arc_length := arc_step * (count - 1)
	var arc_angle := arc_length / layout.fan_radius
	var half_arc := arc_angle * 0.5 * 2

	# angolo del mouse rispetto al centro del cerchio
	var angle := atan2(local.x, layout.fan_radius - local.y)

	# normalizza [ -half_arc … +half_arc ] → [0 … count]
	var t := inverse_lerp(-half_arc, half_arc, angle)
	var index := int(round(t * count))

	drag.insert_active = true
	drag.insert_index = clamp(index, 0, count)
