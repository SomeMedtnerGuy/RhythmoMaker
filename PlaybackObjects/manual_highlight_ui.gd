extends Panel

signal enabled_disabled(enabled)

signal start_pressed
signal stop_pressed


@onready var manual_highlight_button := $HBoxContainer/ManualHighlightButton
@onready var start_manual_highlight := $HBoxContainer/StartManualHighlight


## This toggle controls whether play button of manual highlight can be pressed or not.
func _on_manual_highlight_button_toggled(button_pressed):
	start_manual_highlight.disabled = not button_pressed
	# Editor must be informed so it sets the mode (which synchronizer must know to know how to define the timing of each figure
	enabled_disabled.emit(button_pressed)


## Simply divides this callback's signal in two, so they can be connected directly to the functions in Editor that trigger the necessary behavior
func _on_start_manual_highlight_toggled(button_pressed):
	if button_pressed:
		start_pressed.emit()
	else:
		stop_pressed.emit()
