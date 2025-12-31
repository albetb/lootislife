extends CardEffect
class_name DamageEffect

var amount: int

func _init(damage: int):
	amount = damage

func apply(source, target) -> void:
	if target == null:
		return
	target.take_damage(amount + source.get_damage_bonus())
