extends HBoxContainer

## Sends out the duration and is_rest flag of the button that was pressed
signal figure_chosen(duration, is_rest)

## Variable and setter that control the is_rest flag of all buttons.
var _is_rest := false :
	set(value):
		_is_rest = value
		for button in notes_container.get_children():
			button.is_rest = value

## Variable that keeps track of whether the dotted button is on. Used to calcculate duration being sent out
var _is_dotted := false


@onready var notes_container := $NotesContainer


func _ready():
	# Connects the pressed signal of all the figure buttons, binding their respective duration
	for button in notes_container.get_children():
		button.pressed.connect(_on_figure_pressed.bind(button.duration))


func _on_rest_toggle_button_toggled(button_pressed: bool) -> void:
	_is_rest = button_pressed


func _on_dotted_toggle_button_toggled(button_pressed):
	_is_dotted = button_pressed


func _on_figure_pressed(duration: float):
	# A dot adds half the value of the figure to it, so a new duration is calculated depending on the _is_dotted flag
	if _is_dotted:
		duration += duration / 2
	
	var figure_specs := {
		duration = duration,
		is_rest = _is_rest
	}
	figure_chosen.emit(figure_specs)
