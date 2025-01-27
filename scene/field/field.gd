class_name Field
extends MarginContainer

@onready var card_drop_area_right: Area2D = $CardDropAreaRight
@onready var card_drop_area_left: Area2D = $CardDropAreaLeft
@onready var cards_holder: HBoxContainer = $CardsHolder
@onready var mana_value: Label = $"../ManaValue"
@onready var player_node: Node2D = $"../../Player"
@onready var combat_manager: Node2D = $"../../CombatManager"

@onready var card_scene: PackedScene = preload("res://scene/card/card.tscn")

func _ready():
	$CardDropAreaLeft/CollisionShape2D.shape.size.x = self.size.x / 2
	$CardDropAreaRight/CollisionShape2D.shape.size.x = self.size.x / 2
	
	new_hand()
	
	for child in cards_holder.get_children():
		var card := child as Card
		card.home_field = self
	
func new_hand():
	if self.name == "Hand":
		for child in cards_holder.get_children():
			cards_holder.remove_child(child)
		for a in range(player_node.hand_size):
			var card: Card = card_scene.instantiate()
			card._ready()
			var attacks = [["Power Attack", 2, "Deal 7 damage"], ["Attack", 1, "Deal 3 damage"]]
			var current_attack = attacks[randi() % attacks.size()]
			card.setValues(current_attack[0], current_attack[1], current_attack[2])
			card.home_field = self
			cards_holder.add_child(card)

func return_card_starting_position(card: Card):
	card.reparent(cards_holder)
	cards_holder.move_child(card, card.index)

func set_new_card(card: Card):
	if self.name == "Battleground":
		combat_manager.cast_card(card)
		return
	card_reposition(card)
	card.home_field = self

func card_reposition(card: Card):
	var field_areas = card.drop_point_detector.get_overlapping_areas()
	var cards_areas = card.card_detector.get_overlapping_areas()
	var index: int = 0
	
	if cards_areas.is_empty():
		print(field_areas.has(card_drop_area_left))
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
	
func add_card(card: Card):
	if cards_holder.get_children().size() < 10:
		self.cards_holder.add_child(card)

func _on_button_pressed() -> void:
	if self.name == "Hand":
		new_hand()
		player_node.current_mana = player_node.max_mana
