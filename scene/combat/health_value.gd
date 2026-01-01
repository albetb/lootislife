extends Label

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	self.text = "Punti vita: %d/%d" % [Player.data.current_hp, Player.max_health()]
