class_name HandLayoutController
extends Node

var gap := 10.0
var fan_height := 18.0
var max_rotation := 8.0
var hover_push := 60.0
var use_fan_layout := true
var layout_lerp_speed := 12.0

var layout_initialized := false
var layout_targets := {}
var hovered_card: Card = null
var has_animated_entry := false

func compute_layout(
		cards_root: Node2D,
		dragging_card: Card,
		returning_card: Card,
		insert_index: int
	) -> Dictionary:
	layout_targets.clear()

	var real_cards := cards_root.get_children()
	if real_cards.is_empty():
		return layout_targets

	var layout_cards := []

	for c in real_cards:
		if c != dragging_card and c != returning_card:
			layout_cards.append(c)

	if dragging_card != null and insert_index != -1:
		layout_cards.insert(
			clamp(insert_index, 0, layout_cards.size()),
			null
		)

	var count := layout_cards.size()
	var card_width := (real_cards[0] as Card).get_card_width()
	var step := card_width * 0.75 + gap
	var center_index := (count - 1) * 0.5

	var hover_index := -1
	if hovered_card != null:
		hover_index = layout_cards.find(hovered_card)

	for i in range(count):
		var card = layout_cards[i]
		if card == null:
			continue

		var push := 0.0
		if hover_index != -1:
			var d := i - hover_index
			push = sign(d) * hover_push * exp(-abs(d))

		var offset := i - center_index

		if use_fan_layout:
			var t = offset / max(center_index, 1.0)
			var curve := (1.0 - cos(abs(t) * PI)) * 0.5
			layout_targets[card] = Vector2(offset * step + push, curve * fan_height)
			card.rotation_degrees = t * max_rotation
		else:
			layout_targets[card] = Vector2(offset * step + push, 0.0)
			card.rotation_degrees = 0.0

		card.z_index = i
		if card == hovered_card:
			card.z_index = 2000

	return layout_targets

func apply_initial_layout():
	layout_initialized = true

func reset():
	layout_initialized = false
	layout_targets.clear()
	has_animated_entry = false
	hovered_card = null

func compute_insert_index(cards_root: Node2D, mouse_x_global: float) -> int:
	var cards := cards_root.get_children()
	if cards.is_empty():
		return 0

	var card := cards[0] as Card
	var card_width := card.get_card_width()
	var step = card_width * 0.75 + gap
	var center_index := (cards.size() - 1) * 0.5

	var local_x := cards_root.to_local(Vector2(mouse_x_global, 0)).x

	for i in range(cards.size()):
		var slot_x = (i - center_index) * step
		if local_x < slot_x:
			return i

	return cards.size()

func compute_return_transform(card: Card, cards_root: Node2D) -> Dictionary:
	var cards := cards_root.get_children()
	if cards.is_empty():
		return {
			"position": card.global_position,
			"rotation": card.rotation_degrees
		}

	var index := cards.find(card)
	if index == -1:
		return {
			"position": card.global_position,
			"rotation": card.rotation_degrees
		}

	var count := cards.size()
	var card_width := (cards[0] as Card).get_card_width()
	var step := card_width * 0.75 + gap
	var center_index := (count - 1) * 0.5
	var offset := index - center_index

	var local_pos: Vector2
	var rotation: float

	if use_fan_layout:
		var t = offset / max(center_index, 1.0)
		var curve := (1.0 - cos(abs(t) * PI)) * 0.5
		local_pos = Vector2(
			offset * step,
			curve * fan_height
		)
		rotation = t * max_rotation
	else:
		local_pos = Vector2(offset * step, 0.0)
		rotation = 0.0

	return {
		"position": cards_root.to_global(local_pos),
		"rotation": rotation
	}
