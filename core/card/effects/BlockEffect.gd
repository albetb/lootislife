extends CardEffect
class_name BlockEffect

var amount: int

func _init(value: int):
	amount = value

func apply(source, _target) -> void:
	source.add_block(amount)
