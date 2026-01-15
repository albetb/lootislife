extends ColorRect

@onready var health_bar: ProgressBar = $VBoxContainer/VBoxContainer/HealthBar
@onready var health_label: Label = $VBoxContainer/VBoxContainer/HealthBar/HealthLabel
@onready var exp_bar: ProgressBar = $VBoxContainer/VBoxContainer/ExpBar
@onready var exp_label: Label = $VBoxContainer/VBoxContainer/ExpBar/ExpLabel

func _ready() -> void:
	Events.update_ui.connect(update_ui)
	update_ui()

func update_ui() -> void:
	if Player.data == null:
		return

	# --- HEALTH ---
	var current_hp := Player.data.current_hp
	var max_hp := Player.max_health()
	health_label.text = "%d / %d" % [current_hp, max_hp]
	health_bar.max_value = max_hp
	health_bar.value = current_hp

	# --- EXPERIENCE ---
	var current_exp := Player.data.experience
	var exp_needed := Player.exp_needed()
	exp_label.text = "%d / %d" % [current_exp, exp_needed]
	exp_bar.max_value = exp_needed
	exp_bar.value = current_exp

func _on_back_button_pressed() -> void:
	Player.save()
	SceneManager.switch("res://scene/start/start_menu.tscn")
