## Object that holds the score. Offers methods to provide info about it, or change its state
class_name Staff
extends Node2D


## Returns a list of page objects
func get_pages() -> Array:
	return get_children()


## Returns a list of all measures
func get_measures() -> Array:
	var output := []
	
	for page in get_children():
		for measure in page.get_children():
			output.push_back(measure)
	return output


## Returns a list of all figures
func get_figures() -> Array:
	var output := []
	
	for measure in get_measures():
		for figure in measure.figures.get_children():
			output.push_back(figure)
	
	return output


## Toggles the availability of measures to be selected
func toggle_measures_input(enable: bool) -> void:
	for measure in get_measures():
		measure.input_pickable = enable
