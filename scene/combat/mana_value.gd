extends Label

func _on_combat_manager_update_mana(value) -> void:
	self.text = str(value)
