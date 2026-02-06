extends CanvasLayer

func _ready():
	get_tree().paused = false


func _on_easy_button_pressed() -> void:
	print("start game")
	Globals.difficulty = Globals.Difficulty.EASY
	LevelManager.start_new_game()


func _on_normal_button_pressed() -> void:
	Globals.difficulty = Globals.Difficulty.NORMAL
	LevelManager.start_new_game()

func _on_hard_button_pressed() -> void:
	Globals.difficulty = Globals.Difficulty.HARD
	LevelManager.start_new_game()

func _on_quit_button_pressed() -> void:
	get_tree().quit()
