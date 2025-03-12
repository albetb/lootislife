extends ColorRect

@onready var level_label: Label = $LevelLabel
@onready var coin_label: Label = $CoinLabel
@onready var health_label: Label = $HealthLabel
@onready var health_bar: ProgressBar = $HealthBar
@onready var exp_bar: ProgressBar = $ExpBar

func _ready() -> void:
	update_ui()
	
func update_ui():
	var level_label_text = "Lv: " + str(Player.data.level)
	if level_label.text != level_label_text:
		level_label.text = level_label_text
	var coin_label_text = str(Player.data.coins)
	if coin_label.text != coin_label_text:
		coin_label.text = coin_label_text
	var health_label_text = "Hp: %d/%d" % [Player.current_health(), Player.max_health()]
	if health_label.text != health_label_text:
		health_label.text = health_label_text
	
	health_bar.max_value = Player.max_health()
	health_bar.value = Player.current_health()
	health_bar.tooltip_text = "%d/%d" % [Player.current_health(), Player.max_health()]
	exp_bar.max_value = Player.exp_needed()
	exp_bar.value = Player.data.exp
	exp_bar.tooltip_text = "%d/%d" % [Player.data.exp, Player.exp_needed()]
