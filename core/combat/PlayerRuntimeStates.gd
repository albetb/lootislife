extends RefCounted
class_name PlayerRuntimeState

# --- Riferimenti ---
var player_data: PlayerData
signal draw_requested(amount: int)

# --- Vita ---
var current_hp: int
var max_hp: int

# --- Risorse ---
var energy: int
var max_energy: int
var block: int = 0

# --- Carte ---
var deck: Array[CardInstance] = []
var hand: Array[CardInstance] = []
var discard: Array[CardInstance] = []
var exhaust: Array[CardInstance] = []

# --- Stati temporanei ---
var statuses: Dictionary = {}

# -------------------------
# SETUP
# -------------------------

func setup(player: Player, current_deck: Array[CardInstance]) -> void:
	player_data = player.data

	max_hp = player.max_health()
	current_hp = max_hp

	max_energy = 3
	energy = max_energy

	deck = current_deck.duplicate()
	deck.shuffle()

# -------------------------
# TURN FLOW
# -------------------------

func start_turn() -> Array[CardInstance]:
	energy = max_energy

	var max_hand_size := player_data.max_hand_size
	var space_left := max_hand_size - hand.size()

	if space_left <= 0:
		return []

	var draw_amount := Player.base_draw()
	var to_draw :int = min(draw_amount, space_left)
	return draw_cards(to_draw)

func end_turn() -> void:
	var retained: Array[CardInstance] = []

	for card in hand:
		if card.retain:
			retained.append(card)
		else:
			discard.append(card)

	hand = retained
	block = 0

# -------------------------
# DRAW / DISCARD
# -------------------------

func draw_cards(amount: int) -> Array[CardInstance]:
	var drawn: Array[CardInstance] = []
	var max_hand_size := player_data.max_hand_size

	for i in range(amount):
		if hand.size() >= max_hand_size:
			break

		reshuffle_if_needed()
		if deck.is_empty():
			break

		var card = deck.pop_front()
		hand.append(card)
		drawn.append(card)

	return drawn
	
func request_draw(amount: int) -> void:
	draw_requested.emit(amount)

func _discard_non_retain() -> void:
	for card in hand:
		if not card.retain:
			discard.append(card)
	hand = hand.filter(func(c): return c.retain)

func after_card_played(card: CardInstance) -> void:
	# 1. Rimuovi dalla mano
	hand.erase(card)

	# 2. Decidi il destino della carta
	if card.should_exhaust():
		exhaust.append(card)
	else:
		discard.append(card)

func reshuffle_if_needed():
	if deck.is_empty():
		deck = discard.duplicate()
		discard.clear()
		deck.shuffle()

# TODO!!
func get_damage_bonus():
	return 0
	
func add_block(amount: int) -> void:
	block += amount
	
