extends HBoxContainer
class_name CardsPreview

@export var card_scene: PackedScene
@export var card_scale := 1.0

func clear() -> void:
	for c in get_children():
		c.queue_free()

func show_cards(card_templates: Array[CardTemplate]) -> void:
	clear()

	for template in card_templates:
		if template == null:
			continue

		var copies = max(1, template.copies)
		var card: Card = card_scene.instantiate()

		card.bind_template(template)
		card.interaction_enabled = false
		add_child(card)
		card.set_visual_scale(card_scale)
		card.set_stack_copies(copies)
