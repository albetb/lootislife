extends ColorRect

@onready var level_label: Label = $LevelLabel
@onready var health_label: Label = $HealthLabel
@onready var health_bar: ProgressBar = $HealthBar
@onready var exp_bar: ProgressBar = $ExpBar

func _ready() -> void:
	Events.update_ui.connect(update_ui)
	update_ui()

func update_ui() -> void:
	if Player.data == null:
		return

	# --- LEVEL ---
	level_label.text = "Lv: %d" % Player.data.level

	# --- HEALTH ---
	var current_hp := Player.data.current_hp
	var max_hp := Player.max_health()

	health_label.text = "HP: %d / %d" % [current_hp, max_hp]
	health_bar.max_value = max_hp
	health_bar.value = current_hp
	health_bar.tooltip_text = "%d / %d" % [current_hp, max_hp]

	# --- EXPERIENCE ---
	exp_bar.max_value = Player.exp_needed()
	exp_bar.value = Player.data.experience
	exp_bar.tooltip_text = "%d / %d" % [Player.data.experience, Player.exp_needed()]
