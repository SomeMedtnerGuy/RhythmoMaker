extends PanelContainer

@onready var project_name: LineEdit = $MarginContainer/VBoxContainer/MarginContainer/OptionsContainer/ProjectName/LineEdit


func _on_save_pressed() -> void:
	EventBus.save_project_requested.emit(project_name.text)
	MenuManager.return_to_first()
