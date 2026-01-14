extends ColorRect

func _ready() -> void:
	Events.update_ui.connect(update_ui)
	update_ui()
	#print_tree_pretty()

func update_ui() -> void:
	pass

func _on_back_button_pressed() -> void:
	Player.save()
	SceneManager.switch("res://scene/start/start_menu.tscn")
