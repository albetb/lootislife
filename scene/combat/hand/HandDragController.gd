class_name HandDragController
extends Node

signal play_requested(card: Card)
signal drag_finished(card: Card)
signal return_requested(card: Card)

var dragging_card: Card = null
var returning_card: Card = null

var drag_offset := Vector2.ZERO
var grab_offset_local := Vector2.ZERO

var last_mouse_pos := Vector2.ZERO
var drag_velocity := Vector2.ZERO
var insert_index := -1

var return_target := Vector2.ZERO
var return_rotation := 0.0

var drag_lerp_speed := 18.0
var drag_tilt_lerp := 10.0
var max_drag_tilt := 12.0
var min_drag_speed := 120.0

var return_lerp_speed := 12.0
var return_rotation_lerp_speed := 8.0

var insert_active := false
@export var insert_distance := 140.0
var original_index := -1

func start_drag(card: Card, mouse_pos: Vector2) -> void:
	if dragging_card != null:
		return

	dragging_card = card
	original_index = card.get_index()
	drag_offset = card.global_position - mouse_pos
	grab_offset_local = mouse_pos - card.global_position

	card.z_index = 1000

	last_mouse_pos = mouse_pos
	drag_velocity = Vector2.ZERO

func update(delta: float, mouse_pos: Vector2) -> void:
	_update_drag(delta, mouse_pos)
	_update_return(delta)

func release(mouse_pos: Vector2, battleground: Control) -> void:
	if dragging_card == null:
		return

	var card := dragging_card
	dragging_card = null
	drag_velocity = Vector2.ZERO

	if battleground and battleground.get_global_rect().has_point(mouse_pos):
		emit_signal("play_requested", card)
		return

	force_return(card)

func force_return(card: Card) -> void:
	returning_card = card
	insert_index = -1

func _update_drag(delta: float, mouse_pos: Vector2) -> void:
	if dragging_card == null:
		return

	# -----------------------------
	# POSIZIONE (come prima)
	# -----------------------------
	var target := mouse_pos + drag_offset
	dragging_card.global_position = dragging_card.global_position.lerp(
		target,
		min(1.0, drag_lerp_speed * delta)
	)

	# -----------------------------
	# VELOCITÀ
	# -----------------------------
	drag_velocity = (mouse_pos - last_mouse_pos) / max(delta, 0.0001)
	last_mouse_pos = mouse_pos

	var speed := drag_velocity.length()
	if speed < min_drag_speed:
		dragging_card.rotation_degrees = lerp(
			dragging_card.rotation_degrees,
			0.0,
			min(1.0, drag_tilt_lerp * delta)
		)
		return

	# -----------------------------
	# LEVA (quanto sei lontano dal centro)
	# grab_offset_local è già in locale alla carta
	# -----------------------------
	var half_size := Vector2(
		dragging_card.get_card_width() * 0.5,
		dragging_card.get_card_height() * 0.5
	)

	var lever_x = clamp(grab_offset_local.x / half_size.x, -1.0, 1.0)
	var lever_y = clamp(grab_offset_local.y / half_size.y, -1.0, 1.0)

	var lever_strength = max(abs(lever_x), abs(lever_y))
	if lever_strength < 0.15:
		dragging_card.rotation_degrees = lerp(
			dragging_card.rotation_degrees,
			0.0,
			min(1.0, drag_tilt_lerp * delta)
		)
		return

	# -----------------------------
	# DIREZIONE (torque fisico)
	# -----------------------------
	var movement := drag_velocity.normalized()

	# cross product 2D → scalare
	var torque = (movement.y * lever_x) - (movement.x * lever_y)

	# -----------------------------
	# INTENSITÀ
	# -----------------------------
	var speed_factor = clamp(
		(speed - min_drag_speed) / min_drag_speed,
		0.0,
		1.0
	)

	var target_tilt = clamp(
		torque * max_drag_tilt * lever_strength * speed_factor,
		-max_drag_tilt,
		max_drag_tilt
	)

	# -----------------------------
	# APPLICAZIONE
	# -----------------------------
	dragging_card.rotation_degrees = lerp(
		dragging_card.rotation_degrees,
		target_tilt,
		min(1.0, drag_tilt_lerp * delta)
	)

func _update_return(delta: float) -> void:
	if returning_card == null:
		return

	returning_card.global_position = returning_card.global_position.lerp(
		return_target,
		min(1.0, return_lerp_speed * delta)
	)

	returning_card.rotation_degrees = lerp(
		returning_card.rotation_degrees,
		return_rotation,
		min(1.0, return_rotation_lerp_speed * delta)
	)

	if returning_card.global_position.distance_to(return_target) < 1.0:
		returning_card.global_position = return_target
		returning_card.rotation_degrees = return_rotation

		var finished := returning_card
		returning_card = null
		emit_signal("drag_finished", finished)
