extends Panel

signal enabled_disabled(enabled)

signal start_pressed
signal stop_pressed


@onready var manual_highlight_button := $HBoxContainer/ManualHighlightButton
@onready var start_durations_recording := $HBoxContainer/StartDurationsRecording
@onready var confirmation_dialog: ConfirmationDialog = $HBoxContainer/StartDurationsRecording/ConfirmationDialog



## This toggle controls whether play button of manual highlight can be pressed or not.
func _on_manual_highlight_button_toggled(button_pressed):
	start_durations_recording.disabled = not button_pressed
	# Editor must be informed so it sets the mode (which synchronizer must know to know how to define the timing of each figure
	enabled_disabled.emit(button_pressed)


## Recording button behavior
func _on_start_manual_highlight_toggled(button_pressed):
	# If toggled on, user is asked for a confirmation, as the program will erase the previous durations to record the new ones
	if button_pressed:
		confirmation_dialog.visible = true
	else:
		stop_pressed.emit()


## If action confirmed, send signal to EditorWindow
func _on_confirmation_dialog_confirmed() -> void:
	start_pressed.emit()


## The button was pressed anyway, so it must be unpressed consequence-free if the user cancels the action
func _on_confirmation_dialog_canceled() -> void:
	start_durations_recording.set_pressed_no_signal(false)
