extends CardState


func _enter():
	var field_areas = card.drop_point_detector.get_overlapping_areas()

	if field_areas.is_empty():
		card.home_field.return_card_starting_position(card)
	elif field_areas[0].get_parent() == card.home_field:
		card.home_field.card_reposition(card)
	else:
		var new_field = field_areas[0].get_parent()
		new_field.set_new_card(card)

	transitioned.emit("idle")
