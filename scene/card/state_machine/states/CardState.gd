class_name CardState
extends Node

signal transitioned

var card: Card

func _ready() -> void:
	card = get_owner() as Card
	if card == null:
		push_error("CardState: owner is not a Card")

func _enter() -> void:
	pass

func _exit() -> void:
	pass

func on_input(_event: InputEvent) -> void:
	pass

func on_gui_input(_event: InputEvent) -> void:
	pass

func on_mouse_entered() -> void:
	pass

func on_mouse_exited() -> void:
	pass
