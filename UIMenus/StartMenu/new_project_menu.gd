extends PanelContainer

## The specs that can be set by the user. They are linked to their default values
var specs := {
	new = true,
	measures_amount = 4,
	beats_per_measure = 4
}

@onready var measures_amount_input := $MarginContainer/VBoxContainer/MarginContainer/OptionsContainer/MeasuresAmount
@onready var beats_per_measure_input := $MarginContainer/VBoxContainer/MarginContainer/OptionsContainer/BeatsPerMeasure



func _on_create_button_pressed() -> void:
	## Makes sure all fields have something written on them
	var measures_amount: String = measures_amount_input.line_edit.text
	var beats_per_measure: String = beats_per_measure_input.line_edit.text
	if not (
		measures_amount.is_valid_int()
		and beats_per_measure.is_valid_int()
	):
		print("All fields must be filled with valid input!")
		return
	
	# "value" is the variable that holds what is written in the edit_field already cast to the right type
	specs.measures_amount = int(measures_amount)
	specs.beats_per_measure = int(beats_per_measure)
	EventBus.project_specs_defined.emit(specs)
