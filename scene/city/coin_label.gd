extends Label

func _ready() -> void:
	self.text = str(Player.data.coins)
