class_name MeasuresPage
extends Node2D

const MEASURE_POSITIONS := [
	Vector2(30, 90),
	Vector2(665, 90),
	Vector2(30, 332),
	Vector2(665, 332)
]


func place_measure(measure: Measure) -> void:
	measure.position = MEASURE_POSITIONS[get_child_count()]
	add_child(measure)
	
