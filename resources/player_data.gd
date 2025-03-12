extends Resource
class_name PlayerData

@export var level: int = 1
@export var exp: int = 0

@export var coins: int = 0
@export var damage: int = 0

@export var max_mana: int = 3
@export var hand_size: int = 5
@export var max_hand_size: int = 10

@export var path: Array[Room] = []
@export var current_path: Array[Room] = []
@export var past_path: Array[Room] = []

@export var ability = {}
@export var updating_ability = {}
@export var ability_points: int = 28
@export var updating_ability_points: int = 0

func _ready() -> void:
	if ability == {}:
		ability = {
			Ability.Str: 1,
			Ability.Des: 1,
			Ability.Cos: 1,
			Ability.Int: 1,
			Ability.Sag: 1,
			Ability.Car: 1,
		}
		updating_ability = {
			Ability.Str: 0,
			Ability.Des: 0,
			Ability.Cos: 0,
			Ability.Int: 0,
			Ability.Sag: 0,
			Ability.Car: 0,
		}

enum Ability {
	Str,
	Des,
	Cos,
	Int,
	Sag,
	Car
}
