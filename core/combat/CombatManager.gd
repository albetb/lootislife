extends Node
class_name CombatManager

@onready var hand_ui: Field = $"../Hand"
@onready var card_scene: PackedScene = preload("res://scene/card/card.tscn")

var runtime: PlayerRuntimeState

func start_combat(deck: Array) -> void:
	# deck = Array[CardInstance]
	runtime = PlayerRuntimeState.new()
	runtime.setup(Player, deck)
	start_turn()

func start_turn() -> void:
	runtime.start_turn(Player.base_draw())
	_refresh_hand_ui()

func end_turn() -> void:
	runtime.end_turn()
	# enemy_turn()
	start_turn()
	
func _refresh_hand_ui():
	hand_ui.clear()
	for card_instance in runtime.hand:
		var card_ui: Card = card_scene.instantiate()
		card_ui.bind(card_instance)
		hand_ui.add_card(card_ui)

func request_play_card(card_ui: Card) -> void:
	var card_instance = card_ui.card_data
	if not can_play(card_instance):
		return

	# TODO: delegare a CardResolver
	# CardResolver.play(card_instance, runtime, enemy_runtime)

	runtime.play_card(card_instance)
	_refresh_hand_ui()
	
func can_play(card_instance) -> bool:
	if card_instance.cost > runtime.energy:
		return false
	if card_instance.is_exhausted:
		return false
	return true
