class_name Hand
extends Node2D

@onready var cards_root: Node2D = $Cards
@export var battleground: Control

signal card_play_requested(card: Card)
signal card_play_failed(card: Card)

@export var gap := 10.0
@export var fan_height := 18.0
@export var max_rotation := 8.0
@export var hover_push := 60.0
@export var layout_lerp_speed := 12.0
@export var use_fan_layout := true

var _layout_dirty := false
var suppress_hover := false

var drag: HandDragController = HandDragController.new()
var layout: HandLayoutController = HandLayoutController.new()
var draw_controller: HandDrawController = HandDrawController.new()

func _ready() -> void:
	layout.gap = gap
	layout.fan_height = fan_height
	layout.max_rotation = max_rotation
	layout.hover_push = hover_push
	layout.layout_lerp_speed = layout_lerp_speed
	layout.use_fan_layout = use_fan_layout

	drag.play_requested.connect(func(card):
		card_play_requested.emit(card)
	)

	drag.drag_finished.connect(func(_card):
		layout.hovered_card = null
		_layout_dirty = true
	)

	draw_controller.draw_card_requested.connect(_on_draw_card_requested)
	drag.return_requested.connect(_on_return_requested)

	draw_controller.draw_finished.connect(func():
		layout.layout_initialized = false
		_layout_dirty = true
	)

func _process(delta: float) -> void:
	var dragging := drag.dragging_card != null or drag.returning_card != null

	for c in cards_root.get_children():
		if c == drag.dragging_card:
			c.interaction_enabled = true
		else:
			c.interaction_enabled = not dragging
	
	suppress_hover = drag.dragging_card != null or drag.returning_card != null

	drag.update(delta, get_global_mouse_position())
	_update_layout_motion(delta)

	if drag.dragging_card:
		var card_pos := drag.dragging_card.global_position
		var hand_rect := cards_root.get_global_transform_with_canvas().origin

		# dimensioni approssimate della mano
		var hand_width = max(300.0, cards_root.get_child_count() * 120.0)
		var hand_height := 160.0

		# range esteso orizzontalmente
		var horizontal_range = hand_width * 0.75
		var vertical_range := hand_height * 0.5

		var dx = abs(card_pos.x - hand_rect.x)
		var dy = abs(card_pos.y - hand_rect.y)

		if dx < horizontal_range and dy < vertical_range:
			drag.insert_active = true
			drag.insert_index = layout.compute_insert_index(
				cards_root,
				get_global_mouse_position().x
			)
		else:
			drag.insert_active = false

		reposition_cards()
	elif drag.returning_card:
		# layout già valido → continua a muoverlo
		pass
	elif _layout_dirty:
		reposition_cards()
		_layout_dirty = false

func _update_layout_motion(delta: float) -> void:
	if not layout.layout_initialized:
		return

	for card in layout.layout_targets:
		if card == drag.dragging_card or card == drag.returning_card:
			continue

		card.position = card.position.lerp(
			layout.layout_targets[card],
			min(1.0, layout.layout_lerp_speed * delta)
		)

# -------------------- CARD API --------------------

func add_card(card: Card) -> void:
	cards_root.add_child(card)

	card.hovered.connect(_on_card_hovered)
	card.unhovered.connect(_on_card_unhovered)
	card.drag_started.connect(request_drag)
	card.drag_released.connect(release_drag)

	reposition_cards()

func draw_cards(cards: Array[Card]) -> void:
	draw_controller.request_draw(cards)

func _on_draw_card_requested(card: Card) -> void:
	layout.has_animated_entry = true
	cards_root.add_child(card)

	card.position = Vector2(
		get_viewport_rect().size.x * 0.5 + 200,
		0
	)
	card.rotation_degrees = 0

	card.hovered.connect(_on_card_hovered)
	card.unhovered.connect(_on_card_unhovered)
	card.drag_started.connect(request_drag)
	card.drag_released.connect(release_drag)

	reposition_cards()

	await get_tree().create_timer(draw_controller.draw_delay).timeout
	draw_controller.advance()
	
func _on_return_requested(card: Card) -> void:
	layout.hovered_card = null
	var data = layout.compute_return_transform(card, cards_root)
	drag.return_target = data.position
	drag.return_rotation = data.rotation

func clear_hand() -> void:
	for c in cards_root.get_children():
		c.queue_free()

	layout.reset()
	_layout_dirty = false

# -------------------- HOVER --------------------

func _on_card_hovered(card: Card) -> void:
	if suppress_hover:
		return

	layout.hovered_card = card
	card.z_index = 2000
	reposition_cards()

func _on_card_unhovered(card: Card) -> void:
	if suppress_hover:
		return
		
	if layout.hovered_card == card:
		layout.hovered_card = null
		reposition_cards()

# -------------------- LAYOUT --------------------

func reposition_cards() -> void:
	var index := drag.insert_index
	if not drag.insert_active:
		index = -1

	layout.layout_targets = layout.compute_layout(
		cards_root,
		drag.dragging_card,
		drag.returning_card,
		index
	)

	for card in layout.layout_targets:
		if card == drag.dragging_card or card == drag.returning_card:
			continue

		if not layout.layout_initialized and not layout.has_animated_entry:
			card.position = layout.layout_targets[card]

	layout.apply_initial_layout()
	_layout_dirty = false

# -------------------- DRAG API --------------------

func request_drag(card: Card) -> void:
	drag.start_drag(card, get_global_mouse_position())

func release_drag(card: Card) -> void:
	if drag.dragging_card != card:
		return

	# caso campo di battaglia
	if battleground and battleground.get_global_rect().has_point(get_global_mouse_position()):
		card_play_requested.emit(card)
		return
		
	var final_index := drag.original_index
	if drag.insert_active and drag.insert_index != -1:
		final_index = drag.insert_index

	# smetti di trascinare
	drag.dragging_card = null
	drag.drag_velocity = Vector2.ZERO

	# applica SUBITO il nuovo ordine logico
	if card.get_parent() == cards_root:
		cards_root.move_child(card, final_index)

	# disattiva immediatamente lo slot
	drag.insert_active = false
	drag.insert_index = -1

	# ricalcola SUBITO il layout finale
	layout.hovered_card = null
	layout.layout_initialized = false
	reposition_cards()

	var data = layout.compute_return_transform(card, cards_root)
	drag.return_target = data.position
	drag.return_rotation = data.rotation
	drag.returning_card = card

func on_card_play_failed(card: Card) -> void:
	# 1. termina subito il drag
	drag.dragging_card = null
	drag.insert_active = false
	drag.insert_index = -1

	# 2. rimuovi hover e reset layout
	layout.hovered_card = null
	layout.layout_initialized = false

	# 3. calcola SUBITO il layout finale (senza la carta)
	reposition_cards()

	# 4. ora fai tornare la carta verso il suo slot
	var data = layout.compute_return_transform(card, cards_root)
	drag.return_target = data.position
	drag.return_rotation = data.rotation
	drag.returning_card = card

func on_card_played(card: Card) -> void:
	drag.dragging_card = null
	drag.returning_card = null
	drag.insert_index = -1

	layout.hovered_card = null
	layout.layout_initialized = false

	if card.get_parent() == cards_root:
		cards_root.remove_child(card)
		card.queue_free()

	_layout_dirty = true
	reposition_cards()
	
func is_dragging() -> bool:
	return drag.dragging_card != null
