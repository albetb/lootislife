class_name HandDrawController
extends Node

var drawing := false
var draw_queue: Array[Card] = []
var draw_delay := 0.15

signal draw_card_requested(card: Card)
signal draw_finished

func request_draw(cards: Array[Card]) -> void:
	if cards.is_empty():
		return

	if drawing:
		draw_queue.append_array(cards)
		return

	drawing = true
	draw_queue = cards.duplicate()
	_draw_next_card()

func _draw_next_card() -> void:
	if draw_queue.is_empty():
		drawing = false
		draw_finished.emit()
		return

	var card = draw_queue.pop_front()
	draw_card_requested.emit(card)

func advance() -> void:
	_draw_next_card()

func is_drawing() -> bool:
	return drawing
