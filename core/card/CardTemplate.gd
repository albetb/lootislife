extends Resource
class_name CardTemplate

enum CardType {
	ATTACK,
	SKILL,
	POWER
}

@export var id: String
@export var display_name: String
@export var description: String

@export var cost: int = 1
@export var type: CardType = CardType.ATTACK

@export var retain: bool = false
@export var exhaust: bool = false
@export var charges: int = -1

# quante copie genera questo template
@export var copies: int = 1

# lista di CardEffect
@export var effects: Array[CardEffect] = []
@export var upgrade_to: CardTemplate
@export var tags: PackedStringArray
