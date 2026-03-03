extends CanvasLayer

@onready var PauseMenuMusic: AudioStreamPlayer = $PauseMenuMusic

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS

func _on_resume_button_pressed() -> void:
	_resume_game()
	
func _resume_game():
	$PauseMenuMusic.stop()
	get_parent().toggle_pause()
	get_tree().paused = false

func _on_main_menu_button_pressed() -> void:
	$PauseMenuMusic.stop()
	get_tree().paused = false
	get_parent().toggle_pause()
	LevelManager.change_to_main_menu()
