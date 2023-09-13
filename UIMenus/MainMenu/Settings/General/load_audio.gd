class_name LoadAudio
extends PanelContainer


@onready var search: Button = $MarginContainer/VBoxContainer/MarginContainer/OptionsContainer/VBoxContainer/Search

@onready var audio_path_line_edit: LineEdit = $MarginContainer/VBoxContainer/MarginContainer/OptionsContainer/VBoxContainer/AudioPath/LineEdit

@onready var file_dialog: FileDialog = $FileDialog


func _on_search_pressed() -> void:
	file_dialog.visible = true


## Once the file is chosen, its filepath should appear in the respective field of the window
func _on_file_dialog_file_selected(path: String) -> void:
	audio_path_line_edit.text = path


## This function should fetch the audio_path and send it to synchronizer, which loads it (using the static function below)
func _on_import_pressed() -> void:
	var path := audio_path_line_edit.text
	if path == "":
		print("No file selected!")
	else:
		EventBus.audio_chosen.emit(path)
		MenuManager.return_to_first()


## Static function that takes a file path and returns the mp3 audiofile. Returns null if the file cannot open correctly
static func load_mp3(path: String) -> AudioStreamMP3:
	var file = FileAccess.open(path, FileAccess.READ)
	if FileAccess.get_open_error() != 0:
		return null
	var audio := AudioStreamMP3.new()
	audio.data = file.get_buffer(file.get_length())
	return audio
