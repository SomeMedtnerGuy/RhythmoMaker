## Menu used for amount of measures change. 
## When more of these kinds of menus are needed (submition of values), it mmight become a base class for them, holding the mutual code.
extends PanelContainer

## In case the value received by the imput is this, it means the LineEdit is empty
const EMPTY := -1

@onready var measures_amount_input := $MarginContainer/VBoxContainer/MarginContainer/OptionsContainer/MeasuresAmount


func _on_save_pressed() -> void:
	# First, get the value present in LineEdit. This value is already filtered by LineEdit so only a valid value (including the EMPTY constant) is returned
	var amount: int = measures_amount_input.value
	
	if amount != EMPTY:
		# Param2 is true if measures should be added, false otherwise. For that, only thing needed to do is checking which Menu is using the script.
		EventBus.change_measures_submitted.emit(
			amount,
			true if self.name == "AddMeasures" else false
			)
