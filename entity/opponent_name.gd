extends Label

@onready var enemy_node: Node2D = $"../../Enemy"

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	self.text = enemy_node.enemy_name


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	self.text = enemy_node.enemy_name
