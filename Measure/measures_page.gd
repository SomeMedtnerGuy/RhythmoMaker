## Holds a set of measures
class_name MeasuresPage
extends Node2D

const MAX_MEASURES_AMOUNT := 4

## Keeps the positions of the measures in an array in the right order
@onready var MEASURE_POSITIONS := [
	$MeasurePos1.position,
	$MeasurePos2.position,
	$MeasurePos3.position,
	$MeasurePos4.position
]

@onready var measures: Node2D = $Measures
@onready var markers: Node2D = $Markers


## Places the argument measure in the correct position, depending on how many measures this page already has
func place_measure(measure: Measure) -> void:
	measure.position = MEASURE_POSITIONS[measures.get_child_count()]
	measures.add_child(measure)
	# if the page became full by placin this measure, flag it as being the last of the page, so highlighter can know when to send the pageturn request signal
	if measures.get_child_count() == MAX_MEASURES_AMOUNT:
		measure.is_last_of_page = true


## Returns an array containing the measures in the page
func get_measures() -> Array:
	return measures.get_children()


