extends Node

# Emitted by the new_project_menu's "Create" button after the settings are defined
signal project_specs_defined(specs)
signal save_project_requested
signal open_project_requested(save_data: Dictionary)

## The "add" parameter should be true if the measures should be added and false if they should be removed. Signal connected in EditorWindow and emitted by change_measures_menu
signal change_measures_submitted(measures_amount, add)

## Emitted by settings when user chooses audio from disk
signal audio_chosen(audio: AudioStreamMP3)

## Emitted by AutomaticModeSettingsMenu upon save pressed
signal tempo_submitted(tempo: int)
signal delay_submitted(delay: float)
