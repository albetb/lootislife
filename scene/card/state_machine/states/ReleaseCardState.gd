extends CardState

func _enter() -> void:
	if card.home_field == null:
		transitioned.emit("idle")
		return

	var global_pos := card.global_position

	# rientro SEMPRE sotto cards_root
	card.reparent(card.home_field.cards_root)
	card.global_position = global_pos

	var field_areas := card.drop_point_detector.get_overlapping_areas()

	for area in field_areas:
		var parent := area.get_parent()

		# Drop sulla mano
		if parent is Field:
			if parent == card.home_field:
				card.home_field.request_reposition()
			else:
				parent.set_new_card(card)

			transitioned.emit("idle")
			return

		# Drop sul nemico
		if parent.is_in_group("enemy"):
			var cm := card.home_field.combat_manager
			if cm and cm.can_play(card.card_data):
				cm.request_play_card(card)
			else:
				card.home_field.request_reposition()

			transitioned.emit("idle")
			return

	# Nessun target valido → torna in mano
	card.home_field.request_reposition()
	transitioned.emit("idle")
