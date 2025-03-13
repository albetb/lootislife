extends Panel

func _ready() -> void:
	update_ui()

func update_ui():
	$RoomLabel.text = "Stanza: " + str(Player.current_room())
	var loot_mult = int(round((Player.loot_mult() - 1) * 100))
	$LootLabel.text = "Loot +" + str(loot_mult) + "%"
