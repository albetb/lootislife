extends RefCounted
class_name CardResolver

static func play(card: CardInstance, source, target) -> void:
	if card == null:
		return
	if not card.can_play(source):
		return

	source.energy -= card.cost

	for effect in card.effects:
		effect.apply(source, target)

	card.on_play()
