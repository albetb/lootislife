extends Node2D

@export var enemy_name: String
@export var level: int
@export var current_health: int
@export var max_health: int

@onready var health_label: Label = $OpponentHealthValue
@onready var name_label: Label = $OpponentName

func _ready() -> void:
	enemy_name = "CATTIVONE"
	level = 1
	current_health = 5
	max_health = 5
	name_label.text = enemy_name
	health_label.text = "%s/%s" % [str(current_health), str(max_health)]

func take_damage(amount) -> void:
	current_health = max(current_health - amount, 0)
	health_label.text = "%s/%s" % [str(current_health), str(max_health)]
	if current_health <= 0:
		name_label.text = "Moooorto!"
