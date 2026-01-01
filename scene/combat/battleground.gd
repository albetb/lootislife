class_name Battleground
extends MarginContainer

@onready var combat_manager = $".."

func _ready():
	pass

func set_new_card(card: Card):
	combat_manager.request_play_card(card)
