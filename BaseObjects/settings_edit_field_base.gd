## Base Scene for a LineEdit with a label telling what that LineEdit holds. 
class_name SettingsEditField
extends HBoxContainer

const INT_DEFAULT := 4

var value: Variant

@onready var line_edit := $LineEdit


#func _ready() -> void:
#	_on_line_edit_text_changed(line_edit.text)


## All checking for invalid inputs is done here in one place, so values that are of the same type can be checked with the same code.
## Each checking is done in three parts: What happens if LineEdit is empty, what happens if it is not the type we want and finally what should happen if the input is valid
#func _on_line_edit_text_changed(new_text: String) -> void:
#	match get_name():
#		"MeasuresAmount", "BeatsPerMeasure":
#			# -1 is the empty constant for ints
#			if new_text == "":
#				value = -1
#			elif not new_text.is_valid_int():
#				# Show a warning saying the input should be a valid integer.
#				print("Invalid Input!")
#				# Write back the default value for integer fields in LineEdit and value
#				line_edit.text = str(INT_DEFAULT)
#				value = INT_DEFAULT
#			else:
#				# If input is valid, place it in value, not allowing it to be less than 1
#				value = max(1, int(new_text))
#				# Write the value in the text (means that if the user types "0" it will show up "1"
#				line_edit.text = str(value)
