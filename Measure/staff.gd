## Object that holds the score. Offers methods to provide info about it, or change its state
class_name Staff
extends Marker2D


# The path to the measure_page scene. There will be an arbitrary number of them, depending on how many measures the piece has
const MEASURE_SCENE := preload("res://Measure/measure.tscn")
const MEASURES_PAGE_SCENE := preload("res://Measure/measures_page.tscn")
## The default and playing scales of the staff. Allows the staff to cover the empty space left by the UI during playing mode. Used by the EditorWindow, which sets it.
const DEFAULT_SCALE := Vector2(1.0, 1.0)
const PLAYING_SCALE := Vector2(1.2, 1.2)


## Holds the page currently displayed on screen. Setter handles the page-turning (aka what page is visible or not.
var current_page: MeasuresPage :
	set(page):
		# The previous current page should become invisible
		if current_page:
			current_page.visible = false
		current_page = page
		# Updates the marker_tracker counterpart, so it can know where to place markers
		marker_tracker.current_page = current_page
		page.visible = true


## Holds measure currently being highlighted
var highlighted_measure: Measure:
	set(value):
		# The previous measure should be unselected
		if highlighted_measure:
			highlighted_measure.highlighted = false
		# In case the measure clicked on is the one already selected, it means the user wants to unselect it, so delete the reference and return immediately
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


## All the setup function does is add "measures_amount" measures with "beats_per_measure" beats to the staff
func setup(measures_amount: int, beats_per_measure: int) -> void:
	update_beats_per_measure(beats_per_measure)
	for measure_no in measures_amount:
		add_measure()


func update_beats_per_measure(beats_per_measure: int) -> void:
	_beats_per_measure = beats_per_measure


## Places measures in the correct pages
func add_measure() -> Measure:
	# Creates a new page in case it is the first page or the previous one is full
	if not get_pages() or len(get_measures()) % MeasuresPage.MAX_MEASURES_AMOUNT == 0:
		create_measure_page()
	var last_page = get_pages()[-1]
	var measure := MEASURE_SCENE.instantiate()
	last_page.place_measure(measure)
	measure.beats_amount = _beats_per_measure
	measure.barline_type = Types.BARLINES.SINGLE
	measure.selected_changed.connect(_on_measure_selected_changed)
	measure.filled.connect(_on_measure_filled)
	return measure


## Removes the last "amount" measures from the staff
func remove_measures(amount: int) -> void:
	var measures: Array = get_measures()
	# Variable which holds the measure being deleted at a given point in the following while loop
	var last_deleted_measure: Measure
	while amount != 0:
		# Get the last measure of the list and delete it
		last_deleted_measure = measures[-1]
		last_deleted_measure.queue_free()
		# Remove it from the list (soon to be a null value)
		measures.pop_back()
		# One less measure to worry about!
		amount -= 1
	# If the last measure hasn't been deleted yet, wait until it is, because we need to accurately get the number of measures of any given page
	if last_deleted_measure:
		await last_deleted_measure.tree_exited
	
	# Handles page deletion in case no measures are present in it after removal process
	for page in get_pages():
		if len(page.get_measures()) == 0:
			page.queue_free()
			# Needed to accurately update page values
			await page.tree_exited


func create_measure_page() -> void:
	var measure_page: MeasuresPage = MEASURES_PAGE_SCENE.instantiate()
	# Pages are invisible by default. Their visibility is controlled by current_page
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


## Toggles the possibility of measures to be selected
func toggle_measures_input(enable: bool) -> void:
	for measure in get_measures():
		measure.input_pickable = enable


## Each measure input detection is connected to this function. highlighted_measure's setter handles logic
func _on_measure_selected_changed(measure: Measure):
	highlighted_measure = measure


## Selects the next measure if there are any
func _on_measure_filled() -> void:
	var measures = get_measures()
	var measure_i = measures.find(highlighted_measure)
	if measure_i + 1 < len(measures):
		highlighted_measure = measures[measure_i + 1]
