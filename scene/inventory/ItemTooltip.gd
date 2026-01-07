extends Panel
class_name ItemTooltip

@onready var name_label: Label = $VBoxContainer/NameLabel
@onready var type_label: Label = $VBoxContainer/TypeLabel
@onready var desc_label: Label = $VBoxContainer/Description

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func bind(item: ItemInstance) -> void:
	name_label.text = item.display_name
	type_label.text = item.item_type
	desc_label.text = item.description
