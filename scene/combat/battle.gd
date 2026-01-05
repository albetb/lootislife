extends Node

@onready var combat_manager: CombatManager = $CombatManager
@onready var battleground: Battleground = $CombatManager/Battleground
@onready var hand_ui: Hand = $Hand
@onready var health_label: Label = $PlayerHud/HealthValue
@onready var mana_label: Label = $PlayerHud/Mana/ManaValue
@onready var enemy = $Enemy

func _ready() -> void:
	# --- Safety checks ---
	if combat_manager == null:
		push_error("Battle: CombatManager non trovato")
		return

	if hand_ui == null:
		push_error("Battle: Hand UI non trovata")
		return

	# --- Dependency injection ---
	combat_manager.bind_hand_ui(hand_ui)
	combat_manager.bind_mana_ui(mana_label)
	combat_manager.bind_health_ui(health_label)
	combat_manager.bind_enemy(enemy)
	hand_ui.battleground = battleground

	# --- Start combat ---
	var deck := Player.pending_combat_deck
	Player.pending_combat_deck = []

	if deck.is_empty():
		push_warning("Battle: deck vuoto all'avvio combattimento")

	combat_manager.start(deck)
