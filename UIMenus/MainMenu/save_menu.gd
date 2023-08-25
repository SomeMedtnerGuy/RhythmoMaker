extends PanelContainer

@onready var project_name: LineEdit = $MarginContainer/VBoxContainer/MarginContainer/OptionsContainer/ProjectName/LineEdit


func _on_save_pressed() -> void:
	var project_name_snake: String = project_name.text.to_snake_case()
	var file_path := "user://%s.save" % project_name_snake
	var save_game = FileAccess.open(file_path, FileAccess.WRITE)
	
	var save_dict := {
		"new": false
	}
	for node in get_tree().get_nodes_in_group("saver"):
		save_dict.merge(node.save_data())
	
	var json_string = JSON.stringify(save_dict)
	save_game.store_line(json_string)
	
	MenuManager.return_to_first()
