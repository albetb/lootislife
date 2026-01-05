class_name Card
extends Node2D

@onready var state_machine: CardStateMachine = $CardStateMachine
@onready var input_area: Area2D = $VisualRoot/InputArea
@onready var drop_point_detector: Area2D = $VisualRoot/DropPointDetector
@onready var card_detector: Area2D = $VisualRoot/CardsDetector

@onready var effect_label: Label = %EffectLabel
@onready var name_label: Label = %NameLabel
@onready var cost_label: Label = %CostLabel

@onready var visual_root: Node2D = $VisualRoot
@onready var input_shape: CollisionShape2D = $VisualRoot/InputArea/CollisionShape2D

var drag_layer: Node2D
var card_data: Object = null
var _pending_update := false

@export var home_field: Field
var index: int = 0

func _ready() -> void:
	input_area.input_event.connect(_on_input_event)
	input_area.mouse_entered.connect(_on_mouse_entered)
	input_area.mouse_exited.connect(_on_mouse_exited)
	
	_center_visual_root()

	if _pending_update:
		_apply_visuals()

func bind(data: Object) -> void:
	card_data = data
	_pending_update = true
	if is_node_ready():
		_apply_visuals()

func _apply_visuals() -> void:
	_pending_update = false
	if card_data == null:
		return

	name_label.text = card_data.name
	cost_label.text = str(card_data.cost)
	effect_label.text = card_data.description
	
func get_card_width() -> float:
	var shape = input_area.get_node("CollisionShape2D").shape
	if shape is RectangleShape2D:
		return shape.size.x * global_scale.x
	return 0.0
	
func _center_visual_root() -> void:
	if input_shape == null:
		return

	var shape := input_shape.shape
	if shape is RectangleShape2D:
		var size :Vector2 = shape.size
		visual_root.position = -size * 0.5

func reset_visual_state() -> void:
	scale = Vector2.ONE
	rotation = 0.0
	z_index = 0

# -------------------------
# INPUT ROUTING
# -------------------------

func _on_input_event(_viewport, event: InputEvent, _shape_idx: int) -> void:
	state_machine.on_input(event)
	#print("INPUT EVENT:", event)

func _on_mouse_entered() -> void:
	state_machine.on_mouse_entered()

func _on_mouse_exited() -> void:
	state_machine.on_mouse_exited()
