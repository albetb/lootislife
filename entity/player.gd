extends Node2D

@export var player_name: String
@export var level: int
@export var current_health: int
@export var max_health: int
@export var current_mana: int
@export var max_mana: int
@export var hand_size: int
@export var max_hand_size: int

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	player_name = ""
	level = 1
	current_health = 20
	max_health = 20
	current_mana = 3
	max_mana = 3
	hand_size = 5
	max_hand_size = 10

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _on_pass_button_pressed() -> void:
	current_mana = max_mana
