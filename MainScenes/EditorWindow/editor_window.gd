class_name EditorWindow
extends Node

## These constants hold the color values of the inactive_indicator, which should make the window fade whenever settings menu is open
const MODULATE_COLOR_ACTIVE := Color(1,1,1,1)
const MODULATE_COLOR_INACTIVE := Color(1,1,1,0.34)
## Color of the measure selection
const NEUTRAL_COLOR := Color.WHITE
const HIGHLIGHT_COLOR := Color.LIGHT_YELLOW

const DEFAULT_TEMPO := 120
const DEFAULT_DELAY := 0.0

## Holds whether EditorWindow should be active or not. Setter changes its indicator and process_mode accordingly. Input detection of buttons and measures should be disabled during inactivity, and because children inherit process_mode of parents, by disabling EditorWindow, this propagates down the chain and has the desired effect.
var active := true:
	set(value):
		active = value
		if active:
			inactive_indicator.color = MODULATE_COLOR_ACTIVE
			process_mode = Node.PROCESS_MODE_INHERIT
		else:
			inactive_indicator.color = MODULATE_COLOR_INACTIVE
			process_mode = Node.PROCESS_MODE_DISABLED


## Number of pages present in staff. This number will depend on how many measures the user inputs. Used to avoid the page-turning system to turn more pages than it should.
var number_of_pages: int
## An array containing the pages themselves
var pages_array: Array
## Holds the index of the current page, and the setter sends the correct page to the current_page variable 
var current_page_index: int :
	set(value):
		# Avoids the page index to leave the outer bounds of the number of pages
		current_page_index = clamp(value, 0, number_of_pages - 1)
		# Setter of staff.current_page handles visibility of pages, so all EditorWindow must do is set that variable
		staff.current_page = pages_array[current_page_index]
		# Updates the label that shows the page number
		page_number_label.text = "Página: %d/%d" % [(current_page_index + 1), number_of_pages]


@onready var inactive_indicator: CanvasModulate = $InactiveIndicator
@onready var staff: Staff = $Staff
@onready var marker_tracker: MarkerTracker = $Staff/MarkerTracker
@onready var pages: Node2D = $Staff/Pages
@onready var page_number_label: Label = $UiContainer/UI/PageNumberLabel
@onready var editor_tools: Control = $UiContainer/UI/Tools
@onready var editors_menu: EditorsMenu = $UiContainer/UI/Tools/EditorsMenu
@onready var erase_button: TextureButton = $UiContainer/UI/Tools/EraseButton
@onready var play_stop_recording_button: TextureButton = $UiContainer/UI/ManualDurationSettingUI/HBoxContainer/StartDurationsRecording
@onready var playback_button: TextureButton = $UiContainer/UI/PlaybackButton
@onready var manual_duration_setting_ui: Panel = $UiContainer/UI/ManualDurationSettingUI
@onready var synchronizer: Synchronizer = $Synchronizer
@onready var save_confirmed: AcceptDialog = $SaveConfirmed



func _ready() -> void:
	# Connects signals from the event bus
	EventBus.change_measures_submitted.connect(_on_change_measures_submitted)
	EventBus.audio_chosen.connect(_on_audio_chosen)
	EventBus.tempo_submitted.connect(_on_tempo_submitted)
	EventBus.delay_submitted.connect(_on_delay_submitted)
	# Set synchronizer with the default values. Done here to run setters
	EventBus.tempo_submitted.emit(DEFAULT_TEMPO)
	EventBus.delay_submitted.emit(DEFAULT_DELAY)
	
	EventBus.save_project_requested.connect(_on_save_project_requested)
	
	# These signals make the marker_traker know whether is the right time to delete markers (by hovering them over trash).
	erase_button.mouse_entered.connect(marker_tracker._on_hover_over_trash.bind(true))
	erase_button.mouse_exited.connect(marker_tracker._on_hover_over_trash.bind(false))


## Sets all initial params for edition.
func setup(specs: Dictionary) -> void:
	
	staff.setup(specs.measures_amount, specs.beats_per_measure)
	# Sets the variables having to do with page handeling
	update_page_values()


func load_project(save_dict: Dictionary) -> void:
	# Use misc vars
	var misc_vars: Dictionary = save_dict.misc_vars
	staff.update_beats_per_measure(misc_vars.beats_per_measure)
	
	# Place measures and figures
	var measures_figures: Array = save_dict.measures_figures
	for measure_specs in measures_figures:
		var measure: Measure = staff.add_measure()
		measure.barline_type = measure_specs.barline_type
		measure.is_start_repeat = measure_specs.is_start_repeat
		for figure_specs in measure_specs.figures:
			measure.place_figure(figure_specs)
	
	# Place markers
	var pages_markers = save_dict.pages_markers
	var pages_list: Array = staff.get_pages()
	for i in range(pages_markers.size()):
		var current_page: MeasuresPage = pages_list[i]
		for marker_specs in pages_markers[i]:
			marker_tracker.place_saved_marker(marker_specs, current_page)
	
	# Set Synchronizer up
	var synchronizer_vars: Dictionary = save_dict.synchronizer_vars
	synchronizer.load_saved_vars(synchronizer_vars)
	
	
	update_page_values()


## Sets the variables having to do with page handeling
func update_page_values() -> void:
	pages_array = staff.get_pages()
	number_of_pages = len(pages_array)
	current_page_index = 0


## Does the necessary work before something can play (Synchronizer or ManualDurationSetting)
func setup_to_play_whatever(whatevers_ui: Node) -> void:
	# Deselect any measure that might be highlighted
	if staff.highlighted_measure:
		staff.highlighted_measure.highlighted = false
	# Makes the measures unable to be selected
	staff.toggle_measures_input(false)
	# Hide all UI except the relevant stop button
	whatevers_ui.remove_from_group("nodes_to_hide")
	get_tree().call_group("nodes_to_hide", "hide")
	# Since playback starts from the beginning of the piece turn page to the beginning of the staff
	current_page_index = 0
	# Set the staff to playing scale
	staff.scale = Staff.PLAYING_SCALE


## Reverts the work done by setup_to_play_whatever, called whenever what is playing stops
func setup_to_stop_whatever(whatevers_ui: Node) -> void:
	# Allow for measures to be selected
	staff.toggle_measures_input(true)
	# Show again all UI. 
	get_tree().call_group("nodes_to_hide", "show")
	# Allow relevant UI to be hidden if another node needs to hide it
	whatevers_ui.add_to_group("nodes_to_hide")
	# Reverts scale of staff to default
	staff.scale = Staff.DEFAULT_SCALE


## Starts Syncronizer in Playback Mode, the whole point of this software. Just plays the audio with the highlight in sync with it, based either in automatic calculation or manual setting of durations of each figure.
func start_playback() -> void:
	#Prepares the playback (hide UI, turn to first page, etc)
	setup_to_play_whatever(playback_button)
	# Start Synchronizer
	synchronizer.start_playback(staff)


## Starts Synchronizer in Manual Duration Setting Mode, allowing user to time the input so it can reproduce it. Called when ManualDurationSettingUI's play button is pressed
func start_duration_recording():
	setup_to_play_whatever(manual_duration_setting_ui)
	synchronizer.start_recording(staff)


## This function is called either when the PlayStopButton is toggled off or when the playback or manual duration setting reached its end
func stop_synchronizer() -> void:
	# Lets Synchronizer handle its stopping behaviour
	synchronizer.stop()
	# Sets the play button to unpressed, in case the stop is caused by the end of playback and not by the untoggling of the button
	if synchronizer.mode == Synchronizer.MODE.PLAYBACK:
		setup_to_stop_whatever(playback_button)
		playback_button.set_pressed_no_signal(false)
	else:
		setup_to_stop_whatever(manual_duration_setting_ui)
		play_stop_recording_button.set_pressed_no_signal(false)


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


## When a figure is chosen in the editor tool, the editor sends its specs to the measure currently highlighted for creation and placement
func _on_figure_buttons_container_figure_chosen(figure_specs: Dictionary) -> void:
	# Only place the figure if there is a measure selected
	if staff.highlighted_measure:
		staff.highlighted_measure.place_figure(figure_specs)


## Same thing happens to barlines.
func _on_tools_menu_barline_chosen(barline: Types.BARLINES) -> void:
	if staff.highlighted_measure:
		if barline == Types.BARLINES.STARTREP:
			staff.highlighted_measure.is_start_repeat = not staff.highlighted_measure.is_start_repeat
		else:
			staff.highlighted_measure.barline_type = barline


func _on_erase_button_pressed() -> void:
	if staff.highlighted_measure:
		# Currently, delete button deletes last figure of the selected measure.
		staff.highlighted_measure.delete_last_figure()


## Turns page when requested by some player (via request of the Highlighter, which is the one who checks if the note highlighted is the last of the page or not).
func _on_page_changed(page_i: int) -> void:
	current_page_index = page_i


## Callback of the signal emitted by the add/remove measures menu. This function handles both, so the "add" parameter is a bool that'll simply define which Staff function to call
func _on_change_measures_submitted(amount: int, add: bool) -> void:
	staff.highlighted_measure = null
	if add:
		for _i in amount:
			staff.add_measure()
	else:
		# "await" is needed here beause "update_page_values()" must be called only after all measure and page deletion is properly handled
		await staff.remove_measures(amount)
	
	update_page_values()
	# Close the MainMenu after done
	MenuManager.return_to_first()


## Sets the audio_path of the Synchronizer. Its setter takes care of loading the actual audio to the audio_stream_player
func _on_audio_chosen(audio_path: String) -> void:
	synchronizer.audio_path = audio_path


func _on_tempo_submitted(tempo: int) -> void:
	synchronizer.track_bpm = tempo


func _on_delay_submitted(delay: float) -> void:
	synchronizer.first_highlight_delay = delay


## Callback from the forwarded signal from one of the marker menus. The type is sent to the MarkerTracker for its creation and placement
func _on_editors_menu_marker_chosen(marker: Selectable) -> void:
	marker_tracker.add_marker(marker)


## Callback that executes when the save button is pressed
func _on_save_project_requested(project_name: String) -> void:
	# In order to keep the projects easily accessible (and to allow the software to access saved projects from any computer), a folder "projects" is created on the folder where the executable is stored. The project is saved in that folder.
	# First, we get the folder of the executable  
	var program_folder := OS.get_executable_path().get_base_dir()
	# Then we createa path to a savefile (with the name chosen by the user) inside "projects", inside that folder
	var file_name :=  program_folder + "/projects/%s.save" % project_name
	# And then we open said file (or create one, if it does not exist yet) to write our info there
	var save_project = FileAccess.open(file_name, FileAccess.WRITE)
	
	# Next we store the different info in several vars:
	
	# Save misc vars
	var misc_vars := {
		"beats_per_measure": staff._beats_per_measure,
	}
	
	# Save measures and figures. The way this array is organized is as follows:
		# each dict inside the measures_figures represents a measure
		# that measure has a barline_type, is_start_repeat, and figures, the latter linked to an array
		# that array contains dicts, each one representing a figure inside the respective measure
		# each of those dicts contain a duration and an is_rest
	# This way we have the entire hierarchy of measures and figures in a single array
	var measures_figures := []
	for measure in staff.get_measures():
		var measure_dict := {}
		measure_dict["barline_type"] = measure.barline_type
		measure_dict["is_start_repeat"] = measure.is_start_repeat
		var figures := []
		for figure in measure.get_figures():
			var figure_dict := {}
			figure_dict["duration"] = figure.duration
			figure_dict["is_rest"] = figure.is_rest
			figures.append(figure_dict)
		measure_dict["figures"] = figures
		measures_figures.append(measure_dict)
	
	# Save Markers. Similar to measures_figures. This time however, each page is simply an array of markers (and not a dict), because we only have markers to save. Each Marker is a dict with a position and a texture_path
	var pages_markers := []
	for page in staff.get_pages():
		var markers := []
		for marker in page.markers.get_children():
			var marker_dict := {
				"pos_x": marker.position.x,
				"pos_y": marker.position.y,
				"texture_path": marker.texture_path,
			}
			markers.append(marker_dict)
		pages_markers.append(markers)
	
	# Save Synchronizer vars. get_saved_vars() already creates the dictionary in the proper format
	var synchronizer_vars := synchronizer.get_saved_vars()
	
	# Finally, we take each of those variables containing the saved data, put them in an array, and loop through them to store them one per line in a JSON file
	var complete_data := [misc_vars, measures_figures, pages_markers, synchronizer_vars]
	for data in complete_data:
		var json_string := JSON.stringify(data)
		save_project.store_line(json_string)
	
	# Open the window saying the project was successfully saved
	save_confirmed.show()
