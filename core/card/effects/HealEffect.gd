extends CardEffect
class_name HealEffect

@export var amount: int

func _init(value: int = 0):
	amount = value

func apply(source, _target) -> void:
	source.heal(amount)
