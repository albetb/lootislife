extends RefCounted
class_name GridState

var layout: Dictionary = {}
var WIDTH := 4
var HEIGHT := 4

func get_items() -> Array:
	return []

func is_cell_allowed(_cell: Vector2i) -> bool:
	return false

func get_required_visible_slots() -> int:
	return 0

func get_required_visible_rows() -> int:
	return 0

func item_is_out_of_bounds(_item) -> bool:
	return false

func get_max_slot() -> int:
	return WIDTH * HEIGHT
