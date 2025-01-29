extends Node2D

@export var enemy_name: String
@export var level: int
@export var current_health: int
@export var max_health: int

@onready var health_label: Label = $OpponentHealthValue
@onready var name_label: Label = $OpponentName

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	enemy_name = "CATTIVONE"
	level = 1
	current_health = 20
	max_health = 20

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if current_health <= 0:
		enemy_name = "Moooorto!"
