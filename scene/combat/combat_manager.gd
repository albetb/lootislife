extends Node

@onready var enemy_node: Node2D = $"../Enemy"
@onready var hand: Field = $"../Hand"
@onready var card_scene: PackedScene = preload("res://scene/card/card.tscn")
@onready var player_mana: int = Player.data.max_mana

signal update_mana

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	new_hand()
	emit_signal("update_mana", player_mana)

func new_hand():
	hand.discard_all_cards()
	for i in range(Player.data.hand_size):
		draw_card()
		
func draw_card():
	var card: Card = card_scene.instantiate()
	var card_effect = get_random_card()
	card.setValues(card_effect[0], card_effect[1], card_effect[2])
	hand.add_card(card)
	
func get_random_card():
	var attacks = [["Power Attack", 2, "Deal 7 damage"], ["Attack", 1, "Deal 3 damage"]]
	return attacks[randi() % attacks.size()]
	
func can_be_casted(card: Card) -> bool:
	var have_mana: bool = player_mana - card.card_cost >= 0
	var enemy_alive: bool = enemy_node.current_health > 0
	return have_mana and enemy_alive

func cast_card(card: Card):
	if !can_be_casted(card):
		card.home_field.return_card_starting_position(card)
		return
	player_mana = player_mana - card.card_cost
	card.get_parent().remove_child(card)
	effect_parser(card)
	emit_signal("update_mana", player_mana)
	
	var enemy_alive: bool = enemy_node.current_health > 0
	if !enemy_alive:
		var pass_button: Button = $"../PassButton"
		pass_button.text = "Back"

func effect_parser(card: Card):
	if card.effect_label.text.split(" ")[0] == "Deal" and card.effect_label.text.split(" ")[2] == "damage":
		var damage: int = int(card.effect_label.text.split(" ")[1])
		var current_enemy_health: int = enemy_node.current_health
		enemy_node.current_health = str(max(0, current_enemy_health - damage))

func _on_pass_button_pressed() -> void:
	new_hand()
	player_mana = Player.data.max_mana
	emit_signal("update_mana", player_mana)
	
	if enemy_node.current_health <= 0:
		Player.data.coins += randi_range(20, 100)
		Player.gain_exp(randi_range(10, 40))
		Player.save()
		SceneManager.switch("res://scene/explore/explore.tscn")
