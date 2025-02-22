extends Node

func _on_start_pressed() -> void:
	SceneManager.switch("res://scene/city/city.tscn")


func _on_battle_pressed() -> void:
	SceneManager.switch("res://scene/combat/battle.tscn")


func _on_adventure_pressed() -> void:
	SceneManager.switch("res://scene/explore/explore.tscn")
