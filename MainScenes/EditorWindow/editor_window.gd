class_name EditorWindow
extends Node

## These constants hold the color values of the inactive_indicator, which should make the window fade whenever settings menu is open
const MODULATE_COLOR_ACTIVE := Color(1,1,1,1)
const MODULATE_COLOR_INACTIVE := Color(1,1,1,0.34)
## Color of the measure selection
const NEUTRAL_COLOR := Color.WHITE
const HIGHLIGHT_COLOR := Color.LIGHT_YELLOW

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
		page_number_label.text = "Página: %d" % (value + 1)


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



func _ready() -> void:
	# Connects signals from the event bus
	EventBus.change_measures_submitted.connect(_on_change_measures_submitted)
	EventBus.audio_chosen.connect(_on_audio_chosen)
	
	# These signals make the marker_traker know whether is the right time to delete markers (by hovering them over trash).
	erase_button.mouse_entered.connect(marker_tracker._on_hover_over_trash.bind(true))
	erase_button.mouse_exited.connect(marker_tracker._on_hover_over_trash.bind(false))


## Sets all initial params for edition.
func setup(specs: Dictionary) -> void:
	
	staff.setup(specs.measures_amount, specs.beats_per_measure)
	# Sets the variables having to do with page handeling
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
	setup_to_stop_whatever(playback_button)
	# Sets the play button to unpressed, in case the stop is caused by the end of playback and not by the untoggling of the button
	if synchronizer.mode == Synchronizer.MODE.PLAYBACK:
		playback_button.set_pressed_no_signal(false)
	else:
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
		staff.highlighted_measure.place_figure(figure_specs, current_page_index)


## Same thing happens to barlines.
func _on_tools_menu_barline_chosen(barline: Types.BARLINES) -> void:
	if staff.highlighted_measure:
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
		staff.add_measures(amount)
	else:
		# "await" is needed here beause "update_page_values()" must be called only after all measure and page deletion is properly handled
		await staff.remove_measures(amount)
	
	update_page_values()
	# Close the MainMenu after done
	MenuManager.return_to_first()


## Callback from the load audio menu
func _on_audio_chosen(audio: AudioStreamMP3) -> void:
	synchronizer.set_audio(audio)
	MenuManager.return_to_first()


## Callback from the forwarded signal from one of the marker menus. The type is sent to the MarkerTracker for its creation and placement
func _on_editors_menu_marker_chosen(marker: Selectable) -> void:
	marker_tracker.add_marker(marker)
