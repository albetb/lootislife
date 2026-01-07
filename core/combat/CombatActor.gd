# CombatActor.gd
extends RefCounted
class_name CombatActor

var runtime: PlayerRuntimeState
var base_data # Player o EnemyData
signal draw_requested(amount: int)

func _init(_runtime, _base_data):
	runtime = _runtime
	base_data = _base_data

func get_damage_bonus() -> int:
	return runtime.get_damage_bonus()

func add_block(amount: int):
	runtime.add_block(amount)

func take_damage(amount: int):
	runtime.current_hp -= amount

func request_draw(amount: int) -> void:
	draw_requested.emit(amount)
