class_name Battleground
extends MarginContainer

@onready var combat_manager = $".."

func _ready():
	pass

func set_new_card(card: Card):
	combat_manager.cast_card(card)
