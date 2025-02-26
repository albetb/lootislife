extends CanvasLayer

func _ready() -> void:
	if Player.data.current_path.size() > 0:
		SceneManager.switch("res://scene/explore/explore.tscn")
