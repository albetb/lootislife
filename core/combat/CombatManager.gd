extends Node
class_name CombatManager

@export var card_scene: PackedScene

var runtime: PlayerRuntimeState
var hand_ui: Hand  # assegnato dalla scena
var mana_label: Label  # assegnato dalla scena
var health_label: Label  # assegnato dalla scena
var enemy_node: Node = null
var drag_layer: Node2D

func start(deck: Array[CardInstance]) -> void:
	start_combat(deck)

# -------------------------------------------------
# INJECTION
# -------------------------------------------------

func bind_hand_ui(hand: Hand) -> void:
	hand_ui = hand
	hand_ui.card_play_requested.connect(request_play_card)
	hand_ui.card_play_failed.connect(hand_ui.on_card_play_failed)

func bind_mana_ui(label: Label) -> void:
	mana_label = label
	
func bind_health_ui(label: Label) -> void:
	health_label = label
	
func bind_enemy(enemy: Node) -> void:
	enemy_node = enemy

# -------------------------------------------------
# COMBAT FLOW
# -------------------------------------------------

func start_combat(deck: Array[CardInstance]) -> void:
	runtime = PlayerRuntimeState.new()
	runtime.setup(Player, deck)

	runtime.draw_requested.connect(_on_runtime_draw_requested)
	start_turn()

func start_turn() -> void:
	var drawn := runtime.start_turn(Player.base_draw())

	hand_ui.draw_cards(
		_create_card_uis(drawn)
	)
	_refresh_health_ui()
	_refresh_mana_ui()

func _create_card_uis(cards: Array[CardInstance]) -> Array[Card]:
	var result: Array[Card] = []
	for c in cards:
		var card_ui: Card = card_scene.instantiate()
		card_ui.bind(c)
		result.append(card_ui)
	return result

func end_turn() -> void:
	runtime.end_turn()
	hand_ui.clear_hand()

# -------------------------------------------------
# UI
# -------------------------------------------------

func _refresh_hand_ui() -> void:
	if hand_ui == null:
		push_error("CombatManager: hand_ui non assegnata")
		return
		
	for child in hand_ui.cards_root.get_children():
		child.queue_free()

	for card_instance in runtime.hand:
		var card_ui: Card = card_scene.instantiate()
		hand_ui.add_card(card_ui)
		card_ui.bind(card_instance)

func _refresh_mana_ui() -> void:
	if mana_label == null:
		push_error("CombatManager: mana_label non assegnata")
		return
	
	mana_label.text = str(runtime.energy)

func _refresh_health_ui() -> void:
	if health_label == null:
		push_error("CombatManager: health_label non assegnata")
		return
	
	health_label.text = "%s/%s" % [str(runtime.current_hp), str(runtime.max_hp)]

# -------------------------------------------------
# CARD PLAY
# -------------------------------------------------

func request_play_card(card_ui: Card) -> void:
	var card_instance: CardInstance = card_ui.card_data

	if not can_play(card_instance):
		hand_ui.on_card_play_failed(card_ui)
		return

	CardResolver.play(card_instance, runtime, enemy_node)
	runtime.after_card_played(card_instance)

	hand_ui.on_card_played(card_ui)

	_refresh_mana_ui()
	_refresh_health_ui()

func can_play(card_instance: CardInstance) -> bool:
	return card_instance.cost <= runtime.energy
	
func _on_runtime_draw_requested(amount: int) -> void:
	var drawn := runtime.draw_cards(amount)
	hand_ui.draw_cards(_create_card_uis(drawn))

func _on_pass_button_pressed() -> void:
	end_turn()

	if enemy_node != null and enemy_node.current_health <= 0:
		_end_combat_victory()
		return

	start_turn()
	_refresh_mana_ui()
	_refresh_health_ui()
	
func _end_combat_victory() -> void:
	Player.data.coins += Player.apply_loot_multiplier(randi_range(20, 100))
	Player.gain_exp(Player.apply_loot_multiplier(randi_range(10, 20)))
	Player.save()

	# Torna all'esplorazione
	SceneManager.switch("res://scene/explore/explore.tscn")
