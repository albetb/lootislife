extends Label

@onready var enemy_node: Node2D = $".."

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	self.text = str(enemy_node.current_health)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	self.text = str(enemy_node.current_health)
