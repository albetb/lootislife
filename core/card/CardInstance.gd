extends RefCounted
class_name CardInstance

# === STATIC DATA ===
var id: String
var name: String
var base_cost: int
var description: String

# === RUNTIME STATE ===
var cost: int
var retain: bool = false
var exhaust: bool = false
var charges: int = -1 # -1 = infinito

var effects: Array = []

func _init(
	_id: String = "",
	_name: String = "",
	_cost: int = 0,
	_desc: String = "",
	_effects: Array = []
):
	id = _id
	name = _name
	base_cost = _cost
	cost = _cost
	description = _desc
	effects = _effects

func can_play(runtime) -> bool:
	if cost > runtime.energy:
		return false
	if charges == 0:
		return false
	return true

func on_play(runtime, target) -> void:
	if charges > 0:
		charges -= 1
		
func should_exhaust() -> bool:
	if exhaust:
		return true
	if charges == 0:
		return true
	return false
