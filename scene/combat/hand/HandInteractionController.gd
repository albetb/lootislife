class_name HandInteractionController
extends Node

var cards_root: Node2D
var drag: HandDragController
var layout: HandLayoutController

func update_interactions() -> void:
	if cards_root == null or drag == null:
		return

	var dragging := drag.dragging_card != null or drag.returning_card != null

	for card in cards_root.get_children():
		if card == drag.dragging_card:
			card.interaction_enabled = true
		else:
			card.interaction_enabled = not dragging

func can_hover() -> bool:
	if drag == null:
		return true
	return drag.dragging_card == null and drag.returning_card == null

func clear_hover_state() -> void:
	if layout != null:
		layout.hovered_card = null
