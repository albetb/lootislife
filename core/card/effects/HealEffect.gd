extends CardEffect
class_name HealEffect

var amount: int

func _init(value: int):
	amount = value

func apply(source, _target) -> void:
	source.heal(amount)
