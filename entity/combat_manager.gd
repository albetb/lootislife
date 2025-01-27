extends Node2D

@onready var player_node: Node2D = $"../Player"
@onready var enemy_node: Node2D = $"../Enemy"

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func cast_card(card: Card):
	var mana: int = player_node.current_mana
	var cost: int = card.card_cost
	var opponentHealth = enemy_node.current_health
	if mana - cost < 0 or opponentHealth <= 0:
		card.home_field.return_card_starting_position(card)
		return
	player_node.current_mana = mana - cost
	card.get_parent().remove_child(card)
	effect_parser(card)
	
func effect_parser(card: Card):
	if card.effect_label.text.split(" ")[0] == "Deal" and card.effect_label.text.split(" ")[2] == "damage":
		var damage: int = int(card.effect_label.text.split(" ")[1])
		var current_enemy_health: int = enemy_node.current_health
		enemy_node.current_health = str(max(0, current_enemy_health - damage))
