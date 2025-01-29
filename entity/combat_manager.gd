extends Node2D

@onready var player_node: Node2D = $"../../Player"
@onready var enemy_node: Node2D = $"../Enemy"
@onready var hand: Field = $"../Hand"
@onready var cards_holder: HBoxContainer = $"../Hand/CardsHolder"
@onready var card_scene: PackedScene = preload("res://scene/card/card.tscn")

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	new_hand()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func new_hand():
	hand.discard_all_cards()
	for a in range(player_node.hand_size):
		var card: Card = card_scene.instantiate()
		card._ready()
		card.home_field = hand
		var attacks = [["Power Attack", 2, "Deal 7 damage"], ["Attack", 1, "Deal 3 damage"]]
		var current_attack = attacks[randi() % attacks.size()]
		card.setValues(current_attack[0], current_attack[1], current_attack[2])
		hand.add_card(card)
	
func can_be_casted(card: Card) -> bool:
	var haveMana: bool = player_node.current_mana - card.card_cost >= 0
	var enemyAlive: bool = enemy_node.current_health > 0
	return haveMana and enemyAlive

func cast_card(card: Card):
	if !can_be_casted(card):
		card.home_field.return_card_starting_position(card)
		return
	player_node.current_mana = player_node.current_mana - card.card_cost
	card.get_parent().remove_child(card)
	effect_parser(card)

func effect_parser(card: Card):
	if card.effect_label.text.split(" ")[0] == "Deal" and card.effect_label.text.split(" ")[2] == "damage":
		var damage: int = int(card.effect_label.text.split(" ")[1])
		var current_enemy_health: int = enemy_node.current_health
		enemy_node.current_health = str(max(0, current_enemy_health - damage))

func _on_pass_button_pressed() -> void:
	new_hand()
