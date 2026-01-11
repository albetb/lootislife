extends Panel
class_name ItemTooltip

@onready var name_label: Label = $VBoxContainer/NameLabel
@onready var type_label: Label = $VBoxContainer/TypeLabel
@onready var desc_label: Label = $VBoxContainer/Description
@onready var background: ColorRect = $ColorRect
const MAX_WIDTH := 250
const PADDING := Vector2(12, 10)

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	visible = false

	name_label.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	type_label.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	desc_label.size_flags_horizontal = Control.SIZE_FILL

	desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD

func bind(item: EquipmentData) -> void:
	name_label.text = item.display_name
	
	var slot_key = EquipmentData.SlotType.keys()[item.slot_type]
	type_label.text = slot_key.to_lower().capitalize()

	desc_label.text = item.description

	# larghezza target per il wrap
	custom_minimum_size.x = MAX_WIDTH
	size.x = MAX_WIDTH

	# lascia risolvere il layout
	await get_tree().process_frame
	await get_tree().process_frame

	var content_size = $VBoxContainer.get_combined_minimum_size()
	var final_size := Vector2(
		MAX_WIDTH,
		content_size.y
	) + PADDING * 2

	custom_minimum_size = final_size
	size = final_size

	background.position = Vector2.ZERO
	background.size = size
	visible = true
