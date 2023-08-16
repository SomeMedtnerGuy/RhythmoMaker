extends MenuTree


func _ready() -> void:
	setup_buttons()
	MenuManager.change_to_menu($Start)

