extends Node2D

signal update_ui

var save_file_path = "user://save/"
var save_file_name = "PlayerSave.Tres"
var last_save_time: float = 0.0
@export var data = PlayerData.new()

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	DirAccess.make_dir_absolute(save_file_path)
	load_data()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	last_save_time += delta
	if last_save_time >= 1.0:
		last_save_time = 0.0
		save()

func load_data():
	var data = ResourceLoader.load(save_file_path + save_file_name)
	if data == null:
		data = PlayerData.new()
		print("loading error")
	else:
		data = data.duplicate(true)
		print("loaded")
	
func save():
	ResourceSaver.save(data, save_file_path + save_file_name)
	print("save")

func add_points():
	data.change_points(1)
	#emit_signal("update_ui", data.points)
