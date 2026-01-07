extends RefCounted
class_name CardInstance

# -------------------------
# TEMPLATE (STATIC)
# -------------------------
var template: CardTemplate

# -------------------------
# RUNTIME STATE
# -------------------------
var name: String = ""
var description: String = ""
var cost: int
var retain: bool = false
var exhaust: bool = false
var charges: int = -1 # -1 = infinito

var effects: Array[CardEffect] = []

var template_id: String
var type: CardTemplate.CardType

# -------------------------
# SETUP
# -------------------------
func setup(from_template: CardTemplate) -> void:
	template = from_template
	name = from_template.display_name
	description = from_template.description
	cost = from_template.cost
	retain = from_template.retain
	exhaust = from_template.exhaust
	charges = from_template.charges
	effects = from_template.effects.duplicate(true)
	template_id = from_template.id
	type = from_template.type

# -------------------------
# GAMEPLAY
# -------------------------
func can_play(runtime) -> bool:
	if cost > runtime.energy:
		return false
	if charges == 0:
		return false
	return true

func on_play(runtime) -> void:
	if charges > 0:
		charges -= 1

func should_exhaust() -> bool:
	return exhaust or charges == 0

func has_variable(variable) -> bool:
	return false
	
func upgrade():
	if template.upgrade_to:
		setup(template.upgrade_to)

func play(runtime, source, target) -> void:
	if not can_play(runtime):
		return

	runtime.energy -= cost

	for effect in effects:
		effect.apply(runtime, source, target)

	on_play(runtime)
