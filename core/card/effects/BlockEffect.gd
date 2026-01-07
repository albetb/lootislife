extends CardEffect
class_name BlockEffect

@export var amount: int

func _init(value: int = 0):
	amount = value

func apply(runtime, source, target) -> void:
	source.add_block(amount)
