# ItemInstance.gd
extends RefCounted
class_name ItemInstance

var id: String
var size := Vector2i(1, 1) # 1x1 o 1x2
var position := Vector2i(-1, -1)

var display_name: String
var item_type: String
var description: String
