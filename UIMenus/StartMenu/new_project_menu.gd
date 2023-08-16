extends PanelContainer

## The specs that can be set by the user. They are linked to their default values
var specs := {
	measures_amount = 4,
	beats_per_measure = 4
}


@onready var measures_amount := $MarginContainer/VBoxContainer/MarginContainer/OptionsContainer/MeasuresAmount
@onready var beats_per_measure := $MarginContainer/VBoxContainer/MarginContainer/OptionsContainer/BeatsPerMeasure



func _on_create_button_pressed() -> void:
	## Makes sure all fields have something written on them
	for input in [measures_amount, beats_per_measure]:
		if input.value is String:
			print("All fields must be filled!")
			return
	
	# "value" is the variable that holds what is written in the edit_field already cast to the right type
	specs.measures_amount = measures_amount.value
	specs.beats_per_measure = beats_per_measure.value
	EventBus.new_project_setup_complete.emit(specs)
