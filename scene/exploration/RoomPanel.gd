extends Panel

func _ready() -> void:
	Events.update_ui.connect(self.update_ui)
	update_ui()

func update_ui():
	$RoomLabel.text = "Stanza: " + str(Player.current_room())
	var loot_mult = int(round((Player.loot_multiplier() - 1) * 100))
	$LootLabel.text = "Loot +" + str(loot_mult) + "%"
