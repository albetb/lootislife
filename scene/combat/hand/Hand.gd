class_name Hand
extends Node2D

@onready var cards_root: Node2D = $Cards
@export var battleground: Control

signal card_play_requested(card: Card)
signal card_play_failed(card: Card)

# --------------------
# Layout params
# --------------------
@export var gap := 10.0
@export var fan_height := 18.0
@export var max_rotation := 8.0
@export var use_fan_layout := true
@export var layout_lerp_speed := 12.0
var layout_initialized := false
var _layout_dirty := false
var drawing := false
var draw_queue: Array[Card] = []

var layout_targets: Dictionary = {}

# --------------------
# Drag / Return
# --------------------
var dragging_card: Card = null
var drag_offset := Vector2.ZERO
@export var drag_lerp_speed := 18.0

var returning_card: Card = null
@export var return_lerp_speed := 14.0
@export var return_rotation_lerp_speed := 8.0
var return_target := Vector2.ZERO
var return_rotation := 0.0

var drag_insert_index := -1
@export var drag_rotation_lerp_speed := 8.0
var has_animated_entry := false

# --------------------
# Hover
# --------------------
var hovered_card: Card = null
@export var hover_push := 60.0

# =========================================================
# PROCESS
# =========================================================

func _process(delta: float) -> void:
	_update_drag(delta)
	_update_return(delta)
	_update_layout_motion(delta)

	if dragging_card:
		reposition_cards()
	elif _layout_dirty and returning_card == null:
		reposition_cards()
		_layout_dirty = false

# --------------------

func _update_drag(delta: float) -> void:
	if dragging_card == null:
		return

	drag_insert_index = _compute_insert_index(get_global_mouse_position().x)

	var target := get_global_mouse_position() + drag_offset
	dragging_card.global_position = dragging_card.global_position.lerp(
		target,
		min(1.0, drag_lerp_speed * delta)
	)

	dragging_card.rotation_degrees = lerp(
		dragging_card.rotation_degrees,
		0.0,
		min(1.0, drag_rotation_lerp_speed * delta)
	)

# --------------------

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

		_layout_dirty = true

# --------------------

func _update_layout_motion(delta: float) -> void:
	if not layout_initialized:
		return
	if _layout_dirty:
		return
	for card in layout_targets:
		if card == dragging_card or card == returning_card:
			continue

		card.position = card.position.lerp(
			layout_targets[card],
			min(1.0, layout_lerp_speed * delta)
		)

# =========================================================
# CARD MANAGEMENT
# =========================================================

func add_card(card: Card) -> void:
	card.hand = self
	cards_root.add_child(card)
	card.hovered.connect(_on_card_hovered)
	card.unhovered.connect(_on_card_unhovered)

func remove_card(card: Card) -> void:
	if dragging_card == card:
		dragging_card = null
	cards_root.remove_child(card)
	reposition_cards()
	if cards_root.get_child_count() == 0:
		layout_initialized = false
		layout_targets.clear()
		
func draw_cards(cards: Array[Card]) -> void:
	if drawing:
		draw_queue.append_array(cards)
		return

	drawing = true
	draw_queue = cards.duplicate()
	_draw_next_card()

func _draw_next_card() -> void:
	if draw_queue.is_empty():
		drawing = false
		layout_initialized = false
		_layout_dirty = true
		return

	var card :Card = draw_queue.pop_front()
	_add_card_with_animation(card)

	await get_tree().create_timer(0.15).timeout
	_draw_next_card()
	
	if draw_queue.is_empty():
		drawing = false
		_layout_dirty = true
	
func _add_card_with_animation(card: Card) -> void:
	has_animated_entry = true
	card.hand = self
	cards_root.add_child(card)

	# posizione di partenza (simula mazzo a destra)
	var start_pos := Vector2(
		get_viewport_rect().size.x * 0.5 + 200,
		0
	)
	card.position = start_pos
	card.rotation_degrees = 0

	card.hovered.connect(_on_card_hovered)
	card.unhovered.connect(_on_card_unhovered)

	# ricalcola layout FINALE
	reposition_cards()
	
func clear_hand() -> void:
	for card in cards_root.get_children():
		card.queue_free()

	layout_initialized = false
	layout_targets.clear()
	has_animated_entry = false 
	hovered_card = null
	dragging_card = null
	returning_card = null
	
func mark_layout_dirty() -> void:
	_layout_dirty = true

# =========================================================
# HOVER
# =========================================================

func _on_card_hovered(card: Card) -> void:
	if dragging_card or returning_card:
		return
	hovered_card = card
	card.z_index = 2000
	reposition_cards()

func _on_card_unhovered(card: Card) -> void:
	if hovered_card == card:
		hovered_card = null
		reposition_cards()

# =========================================================
# LAYOUT
# =========================================================

func reposition_cards() -> void:
	if dragging_card == null:
		drag_insert_index = -1
	layout_targets.clear()

	var real_cards := cards_root.get_children()
	if real_cards.is_empty():
		return

	# build logical layout
	var layout_cards: Array = []
	for c in real_cards:
		if c != dragging_card and c != returning_card:
			layout_cards.append(c)

	if dragging_card and drag_insert_index != -1:
		layout_cards.insert(
			clamp(drag_insert_index, 0, layout_cards.size()),
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
			var t :float = offset / max(center_index, 1.0)
			var curve := (1.0 - cos(abs(t) * PI)) * 0.5

			layout_targets[card] = Vector2(
				offset * step + push,
				curve * fan_height
			)
			card.rotation_degrees = t * max_rotation
		else:
			layout_targets[card] = Vector2(offset * step + push, 0.0)
			card.rotation_degrees = 0.0

		card.z_index = i
		if card == hovered_card:
			card.z_index = 2000
			
	for card in layout_targets:
		if not layout_initialized and not has_animated_entry:
			card.position = layout_targets[card]
	layout_initialized = true
	_layout_dirty = false

# =========================================================
# DRAG CONTROL
# =========================================================

func request_drag(card: Card) -> void:
	if dragging_card != null:
		return

	dragging_card = card
	drag_offset = card.global_position - get_global_mouse_position()
	card.z_index = 1000

# --------------------

func release_drag(card: Card) -> void:
	if dragging_card != card:
		return

	var insert_index := drag_insert_index
	drag_insert_index = -1
	
	dragging_card = null

	if _is_over_battleground(card):
		emit_signal("card_play_requested", card)
		return

	layout_targets.erase(card)

	if insert_index != -1:
		cards_root.move_child(card, insert_index)

	_compute_return_target(card)
	returning_card = card

# =========================================================
# UTILS
# =========================================================

func _compute_return_target(card: Card) -> void:
	var cards := cards_root.get_children()
	var index := cards.find(card)
	var count := cards.size()

	var card_width := card.get_card_width()
	var step := card_width * 0.75 + gap
	var center_index := (count - 1) * 0.5
	var offset := index - center_index

	if use_fan_layout:
		var t :float = offset / max(center_index, 1.0)
		var curve := (1.0 - cos(abs(t) * PI)) * 0.5

		return_target = cards_root.to_global(Vector2(
			offset * step,
			curve * fan_height
		))
		return_rotation = t * max_rotation
	else:
		return_target = cards_root.to_global(Vector2(offset * step, 0.0))
		return_rotation = 0.0

# --------------------

func _is_over_battleground(card: Card) -> bool:
	return battleground \
		and battleground.get_global_rect().has_point(get_global_mouse_position())

# --------------------

func _compute_insert_index(mouse_x_global: float) -> int:
	var local_x := cards_root.to_local(Vector2(mouse_x_global, 0)).x
	var cards := cards_root.get_children()
	if cards.is_empty():
		return 0

	var card_width := (cards[0] as Card).get_card_width()
	var step := card_width * 0.75 + gap
	var center_index := (cards.size() - 1) * 0.5

	for i in range(cards.size()):
		var slot_x := (i - center_index) * step
		if local_x < slot_x:
			return i

	return cards.size()

func on_card_play_failed(card: Card) -> void:
	# la carta DEVE tornare in mano
	layout_targets.erase(card)
	_compute_return_target(card)
	returning_card = card
