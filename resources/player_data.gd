extends Resource
class_name PlayerData

@export var points = 0
@export var max_points = 0
@export var effects = []

@export var level: int = 1
@export var current_health: int = 20
@export var max_health: int = 20
@export var max_mana: int = 3
@export var hand_size: int = 5
@export var max_hand_size: int = 10
@export var coins: int = 0

func change_points(value: int):
	points += value
	max_points = max(points, max_points)

func add_effect(effect: String):
	effects.append(effect)

func reset_attributes():
	points = 0
	max_points = 0
	effects = []
	
	level = 1
	current_health = 20
	max_health = 20
	max_mana = 3
	hand_size = 5
	max_hand_size = 10
	coins = 0
