extends Node
class_name CombatManager

@export var card_scene: PackedScene

var runtime: PlayerRuntimeState
var hand_ui: Field  # assegnato dalla scena
var mana_label: Label  # assegnato dalla scena
var health_label: Label  # assegnato dalla scena
var enemy_node: Node = null
var drag_layer: Node2D


func start(deck: Array[CardInstance]) -> void:
	start_combat(deck)

# -------------------------------------------------
# INJECTION
# -------------------------------------------------

func bind_hand_ui(hand: Field) -> void:
	hand_ui = hand
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
		card_ui.drag_layer = hand_ui.get_node("DragLayer")
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
		return

	CardResolver.play(card_instance, runtime, enemy_node)
	runtime.after_card_played(card_instance)
	# rimuove la carta ui giocata
	card_ui.queue_free()

	_refresh_hand_ui()
	_refresh_mana_ui()
	_refresh_health_ui()

func can_play(card_instance: CardInstance) -> bool:
	return card_instance.cost <= runtime.energy

func _on_pass_button_pressed() -> void:
	# 1. Fine turno giocatore
	runtime.end_turn()

	# 2. (FUTURO) turno del nemico
	# enemy_take_turn()

	# 3. Controllo vittoria
	if enemy_node != null and enemy_node.current_health <= 0:
		_end_combat_victory()
		return

	# 4. Nuovo turno giocatore
	start_turn()
	_refresh_mana_ui()
	_refresh_health_ui()
	
func _end_combat_victory() -> void:
	# Ricompense (temporanee, come prima)
	Player.data.coins += Player.apply_loot_multiplier(randi_range(20, 100))
	Player.gain_exp(Player.apply_loot_multiplier(randi_range(10, 20)))
	Player.save()

	# Torna all'esplorazione
	SceneManager.switch("res://scene/explore/explore.tscn")
