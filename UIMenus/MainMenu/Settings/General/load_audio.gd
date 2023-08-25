extends PanelContainer


@onready var search: Button = $MarginContainer/VBoxContainer/MarginContainer/OptionsContainer/VBoxContainer/Search

@onready var audio_path_line_edit: LineEdit = $MarginContainer/VBoxContainer/MarginContainer/OptionsContainer/VBoxContainer/AudioPath/LineEdit

@onready var file_dialog: FileDialog = $FileDialog


func _on_search_pressed() -> void:
	file_dialog.visible = true


func _on_file_dialog_file_selected(path: String) -> void:
	audio_path_line_edit.text = path


func _on_import_pressed() -> void:
	var path := audio_path_line_edit.text
	if path == "":
		print("No file selected!")
	else:
		var audio: AudioStreamMP3 = load_mp3(path)
		EventBus.audio_chosen.emit(audio)


func load_mp3(path: String) -> AudioStreamMP3:
	var file = FileAccess.open(path, FileAccess.READ)
	var audio := AudioStreamMP3.new()
	audio.data = file.get_buffer(file.get_length())
	return audio
