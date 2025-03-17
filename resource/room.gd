extends Resource
class_name Room

@export var type: Type = Type.Choice

enum Type {
	Battle,
	Rest,
	Treasure,
	Choice,
	Boss
}
