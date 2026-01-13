extends Panel
class_name ItemTooltip

@onready var background: ColorRect = $MarginContainer/ColorRect
@onready var margin: MarginContainer = $MarginContainer
@onready var cards_preview: CardsPreview = $MarginContainer/HBoxContainer/CardsPreview
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

	var slot_key = EquipmentData.SlotType.keys()[item.slot_type]
	type_label.text = slot_key.to_lower().capitalize()

	desc_label.text = item.description
	cards_preview.show_cards(item.card_templates)

	# Attendi che TUTTO il layout si stabilizzi
	await get_tree().process_frame
	await get_tree().process_frame

	# Size reale del contenuto
	var content_size := margin.get_combined_minimum_size()
	var ent_size := desc_label.get_combined_minimum_size()
	var cards_size := cards_preview.get_combined_minimum_size()

	# Applica solo i vincoli minimi
	custom_minimum_size = Vector2(
		max(content_size.x, MIN_TOOLTIP_SIZE.x),
		max(content_size.y, MIN_TOOLTIP_SIZE.y)
	) * 1.2
	background.custom_minimum_size = custom_minimum_size

	visible = true
