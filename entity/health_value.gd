extends Label

@onready var player_node: Node2D = $"../../../Player"


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	self.text = str(player_node.current_health)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	self.text = str(player_node.current_health)
