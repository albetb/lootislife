extends CardEffect
class_name DrawEffect

var amount: int

func _init(value: int):
	amount = value

func apply(source, _target) -> void:
	source.draw_cards(amount)
