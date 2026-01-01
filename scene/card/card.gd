class_name Card
extends Control

## === UI REFERENCES ===
@onready var effect_label: Label = %EffectLabel
@onready var name_label: Label = %NameLabel
@onready var cost_label: Label = %CostLabel
@onready var state_machine: CardStateMachine = $CardStateMachine
@onready var drop_point_detector: Area2D = $DropPointDetector
@onready var card_detector: Area2D = $CardsDetector

## === DATA BINDING ===
var card_data: Object
@export var home_field: Field
var index: int = 0

func _ready():
	pass

## === INPUT DELEGATION ===
func _input(event):
	state_machine.on_input(event)

func _on_gui_input(event):
	state_machine.on_gui_input(event)

func _on_mouse_entered():
	state_machine.on_mouse_entered()

func _on_mouse_exited():
	state_machine.on_mouse_exited()

## === BINDING ===
func bind(data: Object) -> void:
	card_data = data
	call_deferred("_update_visuals")

func _update_visuals() -> void:
	if card_data == null:
		return

	name_label.text = card_data.name
	cost_label.text = str(card_data.cost)
	effect_label.text = card_data.description

## === TEMPORARY COMPATIBILITY (optional) ===
func setValues(name_value: String, cost: int, effect: String):
	name_label.text = name_value
	cost_label.text = str(cost)
	effect_label.text = effect
