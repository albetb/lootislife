class_name Field
extends MarginContainer

@onready var card_drop_area_right: Area2D = $CardDropAreaRight
@onready var card_drop_area_left: Area2D = $CardDropAreaLeft
@onready var cards_holder: HBoxContainer = $CardsHolder
@onready var player_node: Node2D = $"../../Player"
@onready var combat_manager = $".."

func _ready():
	$CardDropAreaLeft/CollisionShape2D.shape.size.x = self.size.x / 2
	$CardDropAreaRight/CollisionShape2D.shape.size.x = self.size.x / 2

func add_card(card: Card) -> bool:
	if cards_holder.get_children().size() < player_node.max_hand_size:
		self.cards_holder.add_child(card)
		return true
	return false

func discard_all_cards() -> void:
	for child in cards_holder.get_children():
		cards_holder.remove_child(child)

# card positioning
func return_card_starting_position(card: Card):
	card.reparent(cards_holder)
	cards_holder.move_child(card, card.index)

func set_new_card(card: Card):
	card_reposition(card)
	card.home_field = self

func card_reposition(card: Card):
	var field_areas = card.drop_point_detector.get_overlapping_areas()
	var cards_areas = card.card_detector.get_overlapping_areas()
	var index: int = 0

	if cards_areas.is_empty():
		if field_areas.has(card_drop_area_right):
			index = cards_holder.get_children().size()
	elif cards_areas.size() == 1:
		if field_areas.has(card_drop_area_left):
			index = cards_areas[0].get_parent().get_index()
		else:
			index = cards_areas[0].get_parent().get_index() + 1
	else:
		index = cards_areas[0].get_parent().get_index()
		if index > cards_areas[1].get_parent().get_index():
			index = cards_areas[1].get_parent().get_index()

		index += 1

	card.reparent(cards_holder)
	cards_holder.move_child(card, index)
