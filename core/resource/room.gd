extends Resource
class_name Room

@export var type: Type = Type.Selection

enum Type {
	Battle,
	Rest,
	Treasure,
	Selection,
	Boss
}
