extends CardEffect
class_name DamageEffect

@export var amount: int

func _init(damage: int = 0):
	amount = damage

func apply(runtime, source, target) -> void:
	if target == null:
		return
	target.take_damage(amount + source.get_damage_bonus())
