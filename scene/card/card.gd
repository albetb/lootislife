class_name Card
extends Node2D

@onready var input_area: Area2D = $InputArea
@onready var input_shape: CollisionShape2D = $InputArea/CollisionShape2D
@onready var visual_root: Node2D = $VisualRoot

@onready var name_label: Label = $VisualRoot/NameLabel
@onready var cost_label: Label = $VisualRoot/CostLabel
@onready var effect_label: Label = $VisualRoot/EffectLabel

signal hovered(card)
signal unhovered(card)

var card_data
var hand: Hand
var _data_bound := false

# hover / drag visual
const HOVER_SCALE := 1.15
const SCALE_LERP := 12.0
var target_scale := Vector2.ONE

func _ready() -> void:
	assert(input_area != null)
	input_area.input_event.connect(_on_input_event)
	input_area.mouse_entered.connect(_on_mouse_entered)
	input_area.mouse_exited.connect(_on_mouse_exited)
	_center_visual_root()

	if _data_bound:
		_apply_visuals()

func bind(data) -> void:
	card_data = data
	_data_bound = true
	if is_node_ready():
		_apply_visuals()

func _apply_visuals() -> void:
	if card_data == null:
		return

	name_label.text = card_data.name
	cost_label.text = str(card_data.cost)
	effect_label.text = card_data.description

# -------------------------------------------------
# INPUT
# -------------------------------------------------

func _on_input_event(_viewport, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			hand.request_drag(self)
			target_scale = Vector2.ONE * HOVER_SCALE
		else:
			hand.release_drag(self)
			target_scale = Vector2.ONE
		
func _on_mouse_entered():
	if hand.dragging_card != null:
		return
	target_scale = Vector2.ONE * HOVER_SCALE 
	emit_signal("hovered", self)

func _on_mouse_exited():
	if hand.dragging_card != null:
		return
	target_scale = Vector2.ONE
	emit_signal("unhovered", self)

# -------------------------------------------------
# UPDATE
# -------------------------------------------------

func _process(delta: float) -> void:
	scale = scale.lerp(target_scale, min(1.0, SCALE_LERP * delta))

# -------------------------------------------------
# UTILS
# -------------------------------------------------

func get_card_width() -> float:
	var shape := input_shape.shape
	if shape is RectangleShape2D:
		return shape.size.x
	return 0.0

func _center_visual_root() -> void:
	var shape := input_shape.shape
	if shape is RectangleShape2D:
		visual_root.position = -shape.size * 0.5
