class_name HandLayoutController
extends Node

var overlap := 0.5        # 0 = carte affiancate, 0.4–0.5 = overlap piacevole
var fan_radius := 1000.0    # raggio reale del cerchio
var max_rotation := 10.0
var hover_push := 60.0
var use_fan_layout := true
var layout_lerp_speed := 12.0

var layout_initialized := false
var layout_targets := {}
var hovered_card: Card = null
var has_animated_entry := false


# -------------------------------------------------
# FAN GEOMETRICO PURO (CERCHIO VERO)
# -------------------------------------------------

func _fan_transform(index: int, count: int, card_width: float) -> Dictionary:
	if count <= 1:
		return { "pos": Vector2.ZERO, "rot": 0.0 }

	var center := (count - 1) * 0.5
	var offset := index - center

	# ampiezza angolare basata su overlap
	var arc_step := card_width * (1.0 - overlap)
	var arc_length := arc_step * (count - 1)
	var arc_angle := arc_length / fan_radius

	var angle := offset * (arc_angle / center)

	var x := sin(angle) * fan_radius
	var y := fan_radius - cos(angle) * fan_radius

	return {
		"pos": Vector2(x, y),
		"rot": rad_to_deg(angle)
	}


# -------------------------------------------------
# LAYOUT LIVE
# -------------------------------------------------

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
		layout_cards.insert(clamp(insert_index, 0, layout_cards.size()), null)

	var count := layout_cards.size()
	var card_width := (real_cards[0] as Card).get_card_width()

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

		if use_fan_layout:
			var data := _fan_transform(i, count, card_width)
			layout_targets[card] = Vector2(
				data.pos.x + push,
				data.pos.y
			)
			card.rotation_degrees = data.rot
		else:
			layout_targets[card] = Vector2(
				(i - (count - 1) * 0.5) * card_width,
				0.0
			)
			card.rotation_degrees = 0.0

		card.z_index = i
		if card == hovered_card:
			card.z_index = 2000

	return layout_targets


# -------------------------------------------------
# RETURN TARGET (IDENTICO AL FAN)
# -------------------------------------------------

func compute_return_transform(card: Card, cards_root: Node2D) -> Dictionary:
	var cards := cards_root.get_children()
	var index := cards.find(card)
	if index == -1 or cards.is_empty():
		return {
			"position": card.global_position,
			"rotation": card.rotation_degrees
		}

	var count := cards.size()
	var card_width := (cards[0] as Card).get_card_width()

	var local_pos := Vector2.ZERO
	var rotation := 0.0

	if use_fan_layout:
		var data := _fan_transform(index, count, card_width)
		local_pos = data.pos
		rotation = data.rot
	else:
		local_pos = Vector2(
			(index - (count - 1) * 0.5) * card_width,
			0.0
		)

	return {
		"position": cards_root.to_global(local_pos),
		"rotation": rotation
	}


# -------------------------------------------------
# INSERT
# -------------------------------------------------

func compute_insert_index(cards_root: Node2D, mouse_x_global: float) -> int:
	var cards := cards_root.get_children()
	if cards.is_empty():
		return 0

	var card_width := (cards[0] as Card).get_card_width()
	var step := card_width * (1.0 - overlap)
	var center := (cards.size() - 1) * 0.5

	var local_x := cards_root.to_local(Vector2(mouse_x_global, 0)).x

	for i in range(cards.size()):
		var slot_x := (i - center) * step
		if local_x < slot_x:
			return i

	return cards.size()


# -------------------------------------------------
# STATE
# -------------------------------------------------

func apply_initial_layout():
	layout_initialized = true

func reset():
	layout_initialized = false
	layout_targets.clear()
	has_animated_entry = false
	hovered_card = null
