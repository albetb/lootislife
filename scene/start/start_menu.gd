extends CanvasLayer

func _ready() -> void:
	if Player.data.coins <= 0:
		$ContinueButton.disabled = true
		$NewGameButton.text = "New game"
		$NewGameLabel.text = ""
		$Panel.visible = false
		$Panel/LevelLabel.text = ""
		$Panel/CoinLabel.text = ""
	else:
		$ContinueButton.disabled = false
		$NewGameButton.text = "* New game"
		$NewGameLabel.text = "* This will overwrite any saved game"
		$Panel.visible = true
		$Panel/LevelLabel.text = "Level: " + str(Player.data.level)
		$Panel/CoinLabel.text = "Coin: " + str(Player.data.coins)


func _new_game() -> void:
	Player.reset()
	SceneManager.switch("res://scene/explore/explore.tscn")

func _continue() -> void:
	SceneManager.switch("res://scene/explore/explore.tscn")
