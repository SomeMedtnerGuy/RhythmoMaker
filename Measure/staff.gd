## Object that holds the score. Offers methods to provide info about it, or change its state
class_name Staff
extends Marker2D


# The path to the measure_page scene. There will be an arbitrary number of them, depending on how many measures the piece has
const MEASURE_SCENE := preload("res://Measure/measure.tscn")
const MEASURES_PAGE_SCENE := preload("res://Measure/measures_page.tscn")
const MEASURES_PER_PAGE := 4


## Holds the page currently displayed on screen. Setter handles the page-turning (aka what page is visible or not.
var current_page: MeasuresPage :
	set(page):
		# The previous current page should become invisible
		if current_page:
			current_page.visible = false
		current_page = page
		marker_tracker.current_page = current_page
		page.visible = true


## Holds measure currently being highlighted
var highlighted_measure: Measure:
	set(value):
		# The previous measure should be unselected
		if highlighted_measure:
			highlighted_measure.highlighted = false
		if highlighted_measure == value:
			highlighted_measure = null
			return
		# Update selected measure
		highlighted_measure = value
		# Update variable of selected measure
		if highlighted_measure:
			highlighted_measure.highlighted = true

var _beats_per_measure: float = 0.0

@onready var pages: Node2D = $Pages
@onready var marker_tracker: Node2D = $MarkerTracker


func save_data() -> Dictionary:
	var data := {
		"measures_amount": len(get_measures()),
		"beats_per_measure": _beats_per_measure,
		"measures": []
	}
	for measure in get_measures():
		data.measures.append(measure.save_data())
	
	return data



func setup(measures_amount: int, beats_per_measure: int) -> void:
	_beats_per_measure = beats_per_measure
	add_measures(measures_amount)


func add_measures(amount: int, barline_type: Types.BARLINES = Types.BARLINES.SINGLE) -> void:
	for measure_no in amount:
		var measure := MEASURE_SCENE.instantiate()
		measure.beats_amount = _beats_per_measure
		if not get_pages() or len(get_measures()) % 4 == 0:
			create_measure_page()
		var last_page = get_pages()[-1]
		last_page.place_measure(measure)
		measure.barline_type = barline_type
		measure.selected_changed.connect(_on_measure_selected_changed)



func create_measure_page() -> void:
	var measure_page: MeasuresPage = MEASURES_PAGE_SCENE.instantiate()
	#Pages are invisible by default. Their visibility is controlled by current_page
	measure_page.visible = false
	pages.add_child(measure_page)


## Returns a list of page objects
func get_pages() -> Array:
	return pages.get_children()


## Returns a list of all measures
func get_measures() -> Array:
	var output := []
	
	for page in get_pages():
		for measure in page.measures.get_children():
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


## Each measure input detection is connected to this function
func _on_measure_selected_changed(measure: Measure):
	highlighted_measure = measure
