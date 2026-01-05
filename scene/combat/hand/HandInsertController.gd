class_name HandInsertController
extends Node

var cards_root: Node2D
var layout: HandLayoutController
var drag: HandDragController

@export var min_hand_width := 300.0
@export var card_spacing := 120.0
@export var base_hand_height := 160.0

# moltiplicatori di tolleranza
@export var horizontal_factor := 0.75
@export var vertical_factor := 0.5

func update_insert(mouse_x_global: float) -> void:
	if drag == null or cards_root == null or layout == null:
		return

	if drag.dragging_card == null:
		drag.insert_active = false
		drag.insert_index = -1
		return

	var card_pos := drag.dragging_card.global_position
	var hand_origin := cards_root.get_global_transform_with_canvas().origin

	var card_count := cards_root.get_child_count()
	var hand_width = max(min_hand_width, card_count * card_spacing)

	var dx = abs(card_pos.x - hand_origin.x)
	var dy = abs(card_pos.y - hand_origin.y)

	var horizontal_range = hand_width * horizontal_factor
	var vertical_range := base_hand_height * vertical_factor

	if dx < horizontal_range and dy < vertical_range:
		drag.insert_active = true
		drag.insert_index = layout.compute_insert_index(
			cards_root,
			mouse_x_global
		)
	else:
		drag.insert_active = false
		drag.insert_index = -1
