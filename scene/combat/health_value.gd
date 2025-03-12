extends Label

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	self.text = "Punti vita: %d/%d" % [Player.current_health(), Player.max_health()]
