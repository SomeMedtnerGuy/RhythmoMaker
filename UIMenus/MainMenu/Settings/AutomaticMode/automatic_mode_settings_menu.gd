extends PanelContainer

@onready var set_tempo: SettingsEditField = $MarginContainer/VBoxContainer/MarginContainer/OptionsContainer/SetTempo
@onready var set_delay: SettingsEditField = $MarginContainer/VBoxContainer/MarginContainer/OptionsContainer/SetDelay


func _on_save_pressed() -> void:
	var chosen_tempo: String = set_tempo.line_edit.text
	var chosen_delay: String = set_delay.line_edit.text
	if not (
		chosen_tempo.is_valid_int()
		and chosen_delay.is_valid_float()
	):
		print("All fields must be filled with valid input!")
		return
	# First, get the value present in LineEdit. This value is already filtered by LineEdit so only a valid value (including the EMPTY constant) is returned
	var tempo := int(chosen_tempo)
	var delay := float(chosen_delay)
	
	EventBus.tempo_submitted.emit(tempo)
	EventBus.delay_submitted.emit(delay)
	
	MenuManager.return_to_first()
