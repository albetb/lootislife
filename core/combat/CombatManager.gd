extends Node
class_name CombatManager

@export var card_scene: PackedScene

var runtime: PlayerRuntimeState
var hand_ui: Field  # assegnato dalla scena

func start(deck: Array[CardInstance]) -> void:
	start_combat(deck)

# -------------------------------------------------
# INJECTION
# -------------------------------------------------

func bind_hand_ui(hand: Field) -> void:
	hand_ui = hand

# -------------------------------------------------
# COMBAT FLOW
# -------------------------------------------------

func start_combat(deck: Array[CardInstance]) -> void:
	runtime = PlayerRuntimeState.new()
	runtime.setup(Player, deck)
	start_turn()

func start_turn() -> void:
	runtime.start_turn(Player.base_draw())
	_refresh_hand_ui()

func end_turn() -> void:
	runtime.end_turn()
	start_turn()

# -------------------------------------------------
# UI
# -------------------------------------------------

func _refresh_hand_ui() -> void:
	if hand_ui == null:
		push_error("CombatManager: hand_ui non assegnata")
		return

	hand_ui.discard_all_cards()
	for card_instance in runtime.hand:
		var card_ui: Card = card_scene.instantiate()
		card_ui.bind(card_instance)
		hand_ui.add_card(card_ui)

# -------------------------------------------------
# CARD PLAY
# -------------------------------------------------

func request_play_card(card_ui: Card) -> void:
	var card_instance: CardInstance = card_ui.card_data

	if not can_play(card_instance):
		return

	CardResolver.play(card_instance, runtime, null)
	runtime.after_card_played(card_instance)

	_refresh_hand_ui()

func can_play(card_instance: CardInstance) -> bool:
	return card_instance.cost <= runtime.energy
