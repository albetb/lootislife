class_name Card
extends Control

@export var card_name: String = "Card Name"
@export var card_description: String = "Card Description"
@export var card_cost: int = 1
@export var card_image: Node2D

@onready var effect_label: Label = %EffectLabel
@onready var name_label: Label = %NameLabel
@onready var cost_label: Label = %CostLabel
@onready var state_machine: CardStateMachine = $CardStateMachine
@onready var drop_point_detector: Area2D = $DropPointDetector
@onready var card_detector: Area2D = $CardsDetector
@onready var home_field: Field

var index: int = 0

func _ready():
	pass

func _input(event):
	state_machine.on_input(event)

func _on_gui_input(event):
	state_machine.on_gui_input(event)

func _on_mouse_entered():
	state_machine.on_mouse_entered()

func _on_mouse_exited():
	state_machine.on_mouse_exited()

func setValues(name_value: String, cost: int, effect: String):
	card_name = name_value
	card_cost = cost
	card_description = effect

func _process(delta: float) -> void:
	if cost_label != null and cost_label.text != str(card_cost):
		cost_label.set_text(str(card_cost))
	if name_label != null and name_label.text != card_name:
		name_label.set_text(card_name)
	if effect_label != null and effect_label.text != card_description:
		effect_label.set_text(card_description)
