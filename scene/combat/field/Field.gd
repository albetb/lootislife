class_name Field
extends Node2D

@onready var hand_area: Control = $HandArea
@onready var card_drop_area_right: Area2D = $CardDropAreaRight
@onready var card_drop_area_left: Area2D = $CardDropAreaLeft
@onready var cards_root: Node2D = $Cards

var combat_manager: CombatManager = null

func _ready() -> void:
	# aspetta che il layout UI sia stabile
	await get_tree().process_frame
	_update_hand_center()

	# reagisci a futuri resize
	hand_area.resized.connect(_update_hand_center)

	var half_width := hand_area.size.x * 0.5
	$CardDropAreaLeft/CollisionShape2D.shape.size.x = half_width
	$CardDropAreaRight/CollisionShape2D.shape.size.x = half_width

func _update_hand_center() -> void:
	if hand_area.size == Vector2.ZERO:
		return

	var center_global := hand_area.global_position + hand_area.size * 0.5
	cards_root.global_position = center_global

# -------------------------
# INJECTION
# -------------------------

func bind_combat_manager(manager: CombatManager) -> void:
	combat_manager = manager

# -------------------------
# CARD MANAGEMENT
# -------------------------

func request_reposition() -> void:
	if not is_inside_tree():
		return
	call_deferred("_reposition_cards")

#func add_card(card: Card) -> bool:
#	if cards_root.get_child_count() >= Player.data.max_hand_size:
#		return false

#	card.home_field = self
#	cards_root.add_child(card)
#	request_reposition()
#	return true

func add_card(card: Card) -> void:
	card.home_field = self
	cards_root.add_child(card)
	_reposition_cards()
	
func discard_all_cards() -> void:
	for child in cards_root.get_children():
		child.queue_free()
	request_reposition()

# -------------------------
# LAYOUT (UNICA AUTORITÀ)
# -------------------------

func _reposition_cards() -> void:
	var count := cards_root.get_child_count()
	if count == 0:
		return

	var gap := 10.0
	var fan_height := 18.0
	var max_rotation := 8.0

	var first := cards_root.get_child(0) as Card
	var card_width := first.get_card_width()
	var step := card_width + gap

	var center_index := (count - 1) * 0.5

	for i in range(count):
		var card := cards_root.get_child(i) as Card
		var offset := i - center_index
		var t :float = offset / max(center_index, 1.0)

		var curve := (1.0 - cos(abs(t) * PI)) * 0.5

		card.position = Vector2(
			offset * step,
			curve * fan_height
		)

		card.rotation_degrees = t * max_rotation
		card.z_index = 100 + i
		card.index = i

# -------------------------
# DROP HANDLING
# -------------------------

func return_card_starting_position(card: Card) -> void:
	card.reparent(cards_root)
	request_reposition()

func set_new_card(card: Card) -> void:
	if combat_manager:
		combat_manager.request_play_card(card)

func remove_card(card: Card) -> void:
	if card.get_parent() == cards_root:
		cards_root.remove_child(card)
		request_reposition()
