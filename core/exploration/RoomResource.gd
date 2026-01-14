extends Resource
class_name RoomResource

@export var type: Type = Type.Selection

enum Type {
	Battle,
	Rest,
	Treasure,
	Selection,
	Boss
}
