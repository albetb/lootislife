extends CardEffect
class_name DrawEffect

@export var amount: int

func _init(value: int = 0):
	amount = value

func apply(runtime, source, target) -> void:
	source.request_draw(amount)
