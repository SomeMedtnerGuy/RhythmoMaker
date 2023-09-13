extends PanelContainer


@onready var search: Button = $MarginContainer/VBoxContainer/MarginContainer/OptionsContainer/VBoxContainer/Search

@onready var project_path_line_edit: LineEdit = $MarginContainer/VBoxContainer/MarginContainer/OptionsContainer/VBoxContainer/ProjectPath/LineEdit

@onready var file_dialog: FileDialog = $FileDialog


func _on_search_pressed() -> void:
	file_dialog.visible = true


func _on_file_dialog_file_selected(path: String) -> void:
	project_path_line_edit.text = path


func _on_open_pressed() -> void:
	var path := project_path_line_edit.text
	if path == "":
		print("No file selected!")
	else:
		if not FileAccess.file_exists(path):
			print("This file cannot be open!")
			return 
		var save_file := FileAccess.open(path, FileAccess.READ)
		
		var saved_data := {
			"misc_vars": get_saved_data(save_file),
			"measures_figures": get_saved_data(save_file),
			"pages_markers": get_saved_data(save_file),
			"synchronizer_vars": get_saved_data(save_file)
		}
		EventBus.open_project_requested.emit(saved_data)


func get_saved_data(save_file: FileAccess) -> Variant:
	var json_string = save_file.get_line()
	var json = JSON.new()
	var parse_result = json.parse(json_string)
	if not parse_result == OK:
		print("JSON Parse Error: ", json.get_error_message(), " in ", json_string, " at line ", json.get_error_line())
		return {}
	return json.get_data()
