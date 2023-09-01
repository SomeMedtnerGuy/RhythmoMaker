class_name MeasuresPage
extends Node2D

@onready var MEASURE_POSITIONS := [
	$MeasurePos1.position,
	$MeasurePos2.position,
	$MeasurePos3.position,
	$MeasurePos4.position
]

var current_marker: Selectable = null

@onready var measures: Node2D = $Measures
@onready var markers: Node2D = $Markers


func place_measure(measure: Measure) -> void:
	measure.position = MEASURE_POSITIONS[measures.get_child_count()]
	measures.add_child(measure)
	if measures.get_child_count() == 4:
		measure.is_last_of_page = true


func get_measures() -> Array:
	return measures.get_children()


