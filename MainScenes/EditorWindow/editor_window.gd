class_name EditorWindow
extends Node

# Options for highlighting mode (explained below)
enum HIGHLIGHT_MODE {AUTOMATIC, MANUAL}

const HIGHLIGHTER_SCENE := preload("res://highlighter.gd")
# The path to the measure_page scene. There will be an arbitrary number of them, depending on how many measures the piece has
const MEASURES_PAGE_SCENE := preload("res://Measure/measures_page.tscn")
const MEASURES_PER_PAGE := 4
const NEUTRAL_COLOR := Color.WHITE
const HIGHLIGHT_COLOR := Color.LIGHT_YELLOW

# Automatic: Length of figures is calculated automatically from BPM value. Easy to use and extremely precise, but cannot take into account variations of tempo during the track. Ideal for computer-produced music and music performed at metronomic speed.
# Manual: Length of figures is manually set by user. Requires user to perform along the music once, so synchronizer can know how long exactly each figure is. Needs manual setting, but highly customizable. Ideal for music that slows down or speeds up during performance. 
@export var highlight_mode: HIGHLIGHT_MODE = HIGHLIGHT_MODE.AUTOMATIC :
	set(value):
		highlight_mode = value
		# if manual mode is set, figures should not have time durations until user sets them. This setter resets that variable, which could contain values from previous actions (like pressing play in automatic mode, which calculates these values automatically).
		if value == HIGHLIGHT_MODE.MANUAL:
			for figure in staff.get_figures():
				figure.duration_time = 0.0

## Value set by user in case music doesn't start right when audiofile does.
@export var initial_delay := 0.0
@export var number_of_measures := 4


## Number of pages present in staff. This number will depend on how many measures the user inputs. Used to avoid the page-turning to turn more pages than it should.
var number_of_pages: int
## An array containing the pages themselves
var pages_array: Array
## Holds the page currently displayed on screen. Setter handles the page-turning (aka what page is visible or not.
var current_page: MeasuresPage :
	set(page):
		# The previous current page should become invisible
		if current_page:
			current_page.visible = false
		current_page = page
		page.visible = true

## Holds the index of the current page, and the setter sends the correct page to the current_page variable 
var current_page_index: int :
	set(value):
		# Avoids the page index to leave the outer bounds of the number of pages
		current_page_index = clamp(value, 0, number_of_pages - 1)
		current_page = pages_array[current_page_index]
		# Updates the label that shows the page number
		page_number_label.text = "Página: %d" % (value + 1)


## Holds measure currently being highlighted
var highlighted_measure: Measure


@onready var inactive_indicator := $InactiveIndicator
@onready var staff := $Staff
@onready var page_number_label := $UiContainer/UI/PageNumberLabel
@onready var editor_tools := $UiContainer/UI/Tools
@onready var play_stop_manual_button := $UiContainer/UI/ManualHighlightUI/HBoxContainer/StartManualHighlight
@onready var playback_button := $UiContainer/UI/PlaybackButton
@onready var manual_highlight_ui := $UiContainer/UI/ManualHighlightUI
@onready var manual_highlight := $ManualHighlight
@onready var synchronizer := $Synchronizer



func _ready() -> void:
	EventBus.change_measures_submitted.connect(_on_change_measures_submitted)

## Sets all initial params for edition.
func setup(specs: Dictionary) -> void:
	# Creates and sets up the number of pages necessary until all measures are aaccounted for. It should fill the pages with max amount of measures until the last page, which should only include the number of measures left
	var measures_left = specs.measures_amount
	# While there are still measures to place...
	while measures_left != 0:
		# The function that create_measure_page() calls to add the measures, MeasurePage.add_measures() returns the number of measures remaining after the page is filled (4 less or 0, but it is flexible in case number of measures possible to fit in one page changes)
		measures_left = create_measure_page(measures_left)
	
	for measure in staff.get_measures():
		measure.beats_amount = specs.beats_per_measure
		measure.barline_type = Types.BARLINES.SINGLE
	
	# Sets the variables having to do with page handeling
	update_page_values()
	
	setup_players()


func create_measure_page(amount: int) -> int:
	var measure_page: MeasuresPage = MEASURES_PAGE_SCENE.instantiate()
	#Pages are invisible by default. Their visibility is controlled by current_page
	measure_page.visible = false
	staff.add_child(measure_page)
	
	amount = measure_page.add_measures(amount)
	
	for measure in measure_page.get_children():
		measure.selected_changed.connect(_on_measure_selected_changed)
	
	return amount


func update_page_values() -> void:
	pages_array = staff.get_pages()
	number_of_pages = len(pages_array)
	current_page_index = 0


func setup_players() -> void:
	var manual_highlight_highlighter := HIGHLIGHTER_SCENE.new()
	manual_highlight.setup(manual_highlight_highlighter)
	var synchronizer_highlighter := HIGHLIGHTER_SCENE.new()
	synchronizer.setup(synchronizer_highlighter)


## Does the necessary work before something can play (Synchronizer or Manual Highlight)
func setup_to_play_whatever(whatevers_ui: Node) -> void:
	# Deselect any measure that might be highlighted
	if highlighted_measure:
		highlighted_measure.highlighted = false
	# Makes the measures unable to be selected
	staff.toggle_measures_input(false)
	# Hide all UI except the relevant stop button
	whatevers_ui.remove_from_group("nodes_to_hide")
	get_tree().call_group("nodes_to_hide", "hide")
	# Since playback starts from the beginning of the piece turn page to the beginning of the staff
	current_page_index = 0


## Reverts the work done by setup_to_play_whatever, called whenever what is playing stops
func setup_to_stop_whatever(whatevers_ui: Node) -> void:
	# Allow for measures to be selected
	staff.toggle_measures_input(true)
	# Show again all UI. 
	get_tree().call_group("nodes_to_hide", "show")
	# Allow relevant UI to be hidden if another node needs to hide it
	whatevers_ui.add_to_group("nodes_to_hide")


## This function is responsible for collecting all the info input by the user so the Synchronizer can use it. It is called when the PlayStopButton is toggled on.
func start_playback() -> void:
	# Creates and fills in the array that the Synchronizer will be using to highlight the figures
	var figures_list = []
	
	figures_list = staff.get_figures()
	
	# Sets up the figures' duration_time depending on the highlight mode chosen by the user
	# In case of automatic, it just has to convert each figure's duration into duration_time
	if highlight_mode == HIGHLIGHT_MODE.AUTOMATIC:
		for figure in figures_list:
			figure.duration_time = figure.duration * synchronizer.beat_length
	# In case of manual, it checks if the manual setting was already done correctly (by checking if duration_time was set for every figure), and raises a warning otherwise
	else:
		for figure in figures_list:
			if not figure.duration_time:
				# Returns the button to neutral state, as playback hasn't started
				playback_button.set_pressed_no_signal(false)
				print("Not all figures are marked!")
				return
	
	#Prepares the playback (hide UI, turn to first page, etc)
	setup_to_play_whatever(playback_button)
	
	# Start Synchronizer
	synchronizer.start_playback(figures_list)


## This function is called either when the PlayStopButton is toggled off or when the playback reached its end
func stop_playback() -> void:
	synchronizer.stop_playback()
	setup_to_stop_whatever(playback_button)
	# Sets the play button to unpressed, in case the stop is caused by the end of playback and not by the untoggling of the button
	playback_button.set_pressed_no_signal(false)


## Starts ManualHighlight, allowing user to time the input so Synchronizer can reproduce it. Called when ManualHighlightUI's play button is pressed
func start_manual_highlight():
	setup_to_play_whatever(manual_highlight_ui)
	manual_highlight.start(staff.get_figures())


## Stops ManualHighlight. Called whenever the stop button is pressed, or when all figures's time durations are saved.
func stop_manual_highlight():
	manual_highlight.stop()
	setup_to_stop_whatever(manual_highlight_ui)
	# Sets the play button to unpressed, in case the stop is caused by the end of figures to process and not by the untoggling of the button
	play_stop_manual_button.set_pressed_no_signal(false)


## Toggles mode. Button itself controls activation of its respective play button.
func _on_manual_highlight_enabled_disabled(enabled):
	if enabled:
		highlight_mode = HIGHLIGHT_MODE.MANUAL
	else:
		highlight_mode = HIGHLIGHT_MODE.AUTOMATIC


## The next two functions allow page-turniing.
func _on_previous_page_button_pressed():
	# Do not turn back if current page is the first
	if current_page_index == 0:
		return
	current_page_index -= 1


func _on_next_page_button_pressed():
	# Do not turn forward if the current page is the last
	if current_page_index == number_of_pages - 1:
		return
	current_page_index += 1


## When a figure is chosen in the editor tool, the editor sends it to the measure currently highlighted for placement
func _on_figure_buttons_container_figure_chosen(duration: float, is_rest: bool) -> void:
	# Only place the figure if there is a measure selected
	if highlighted_measure:
		highlighted_measure.place_figure(duration, is_rest)


func _on_tools_menu_barline_chosen(barline) -> void:
	if highlighted_measure:
		highlighted_measure.barline_type = barline


func _on_erase_button_pressed():
	if highlighted_measure:
		# Currently, delete button deletes last figure of the selected measure.
		highlighted_measure.delete_last_figure()
	


## Each measure is connected to this function
func _on_measure_selected_changed(is_selected: bool, measure: Measure):
	# is_selected tells the function whether the measure became selected or not (it becomes deselected if it is clicked when it is already selected
	if is_selected:
		# If there is already a measure selected, deselect it first
		if highlighted_measure:
			highlighted_measure.highlighted = false
		highlighted_measure = measure
	# In case it became deselected, just update the variable. Everything else is taken care of by the measure itself
	else:
		highlighted_measure = null


## Turns page when requested by some player (via request of the highlighter, which is the one who checks if the note highlighted is the last of the page or not).
func _on_pageturn_requested():
	current_page_index += 1


## Callback of the signal emitted by the add/remove measures
func _on_change_measures_submitted(amount: int, add: bool) -> void:
	highlighted_measure = null
	# "Add" logic
	if add:
		# Adds remaining measures until last page fills,
		amount = staff.get_pages()[-1].add_measures(amount)
		# then continue adding measures, creating pages as needed
		while amount != 0:
			amount = create_measure_page(amount)
	# "Remove" logic
	else:
		var measures: Array = staff.get_measures()
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
		for page in staff.get_pages():
			if page.get_child_count() == 0:
				page.queue_free()
				# Needed to accurately update page values
				await page.tree_exited
	
	update_page_values()
	# Close the MainMenu after done
	MenuManager.return_to_first()


## Sets initial delay. Can either be done manually in the beginning (TO BE IMPLEMENTED) or set by ManualHighlight based on how long the user takes to start pressing.
func set_delay(delay):
	synchronizer.initial_delay = delay
