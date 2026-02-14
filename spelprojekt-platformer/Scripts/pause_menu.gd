extends CanvasLayer

@onready var PauseMenuMusic: AudioStreamPlayer = $PauseMenuMusic

func _ready():
	#$PauseMenuMusic.play()
	process_mode = Node.PROCESS_MODE_ALWAYS
	

func _on_resume_button_pressed() -> void:
	$PauseMenuMusic.stop()
	get_parent().toggle_pause()
	

func _on_main_menu_button_pressed() -> void:
	$PauseMenuMusic.stop()
	get_tree().paused = false
	get_parent().toggle_pause()
	LevelManager.change_to_main_menu()
