class_name MeasuresPage
extends Node2D

const MEASURE_POSITIONS := [
	Vector2(30, 90),
	Vector2(665, 90),
	Vector2(30, 332),
	Vector2(665, 332)
]

const MEASURE_SCENE := preload("res://Measure/measure.tscn")


var beats_per_measure := 4


## Simply places measures in the page (at specific positiions, for a maximum of four). Returns number of measures left after page is filled
func add_measures(amount: int) -> int:
	# Stop if there are no measures left or page is filled
	while amount != 0 and get_child_count() < 4:
		var measure := MEASURE_SCENE.instantiate()
		measure.position = MEASURE_POSITIONS[get_child_count()]
		add_child(measure)
		amount -= 1
	
	return amount
