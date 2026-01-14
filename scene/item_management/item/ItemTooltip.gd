extends Panel
class_name ItemTooltip

@export var card_scene: PackedScene
@export var card_scale := 1.0

@onready var background: ColorRect = $MarginContainer/ColorRect
@onready var margin: MarginContainer = $MarginContainer
@onready var cards_container: HBoxContainer = $MarginContainer/HBoxContainer/CardsPreview
@onready var name_label: Label = $MarginContainer/HBoxContainer/VBoxContainer/NameLabel
@onready var type_label: Label = $MarginContainer/HBoxContainer/VBoxContainer/TypeLabel
@onready var desc_label: Label = $MarginContainer/HBoxContainer/VBoxContainer/Description

const MIN_TOOLTIP_SIZE := Vector2(4, 2)

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_PASS
	visible = false
	desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	desc_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL

func bind(item: EquipmentData) -> void:
	visible = false

	name_label.text = item.display_name
	type_label.text = EquipmentData.SlotType.keys()[item.slot_type].to_lower().capitalize()
	desc_label.text = item.description

	_show_cards(item.card_templates)

	await get_tree().process_frame
	await get_tree().process_frame

	var content_size := margin.get_combined_minimum_size()
	custom_minimum_size = Vector2(
		max(content_size.x, MIN_TOOLTIP_SIZE.x),
		max(content_size.y, MIN_TOOLTIP_SIZE.y)
	) * 1.2

	background.custom_minimum_size = custom_minimum_size
	visible = true

func _show_cards(card_templates: Array[CardTemplate]) -> void:
	for c in cards_container.get_children():
		c.queue_free()

	for template in card_templates:
		if template == null:
			continue

		var copies = max(1, template.copies)
		var card: Card = card_scene.instantiate()

		card.bind_template(template)
		card.interaction_enabled = false
		cards_container.add_child(card)
		card.set_visual_scale(card_scale)
		card.set_stack_copies(copies)
