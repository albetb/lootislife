extends CanvasLayer

func _ready() -> void:
	if !Player.is_game_started():
		$ContinueButton.disabled = true
		$NewGameButton.text = "Nuova partita"
		$NewGameLabel.text = ""
		$Panel.visible = false
		$Panel/LevelLabel.text = ""
		$Panel/CoinLabel.text = ""
		$Panel/Coin.visible = false
	else:
		$ContinueButton.disabled = false
		$NewGameButton.text = "* Nuova partita"
		$NewGameLabel.text = "* Sovrascriverà i dati di gioco"
		$Panel.visible = true
		$Panel/LevelLabel.text = "Lv " + str(Player.data.level)
		$Panel/CoinLabel.text = str(Player.data.coins)
		$Panel/Coin.visible = true


func _new_game() -> void:
	Player.reset()
	SceneManager.switch("res://scene/exploration/explore.tscn")

func _continue() -> void:
	SceneManager.switch("res://scene/exploration/explore.tscn")
