extends Node

var save_file_path: String = "user://save/"
var save_file_name: String = "PlayerSave.Tres"
@export var data: PlayerData = PlayerData.new()

func _ready() -> void:
	DirAccess.make_dir_absolute(save_file_path)
	load_data()

func load_data():
	data = ResourceLoader.load(save_file_path + save_file_name, "PlayerData") as PlayerData
	if data == null:
		data = PlayerData.new()
		save()
	else:
		data = data.duplicate(true)
	
func save():
	ResourceSaver.save(data, save_file_path + save_file_name)
	print("save")
