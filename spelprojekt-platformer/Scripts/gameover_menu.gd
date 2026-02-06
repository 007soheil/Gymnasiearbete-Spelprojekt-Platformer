extends CanvasLayer


func _on_main_menu_button_pressed() -> void:
	LevelManager.change_to_main_menu()


func _on_restart_button_pressed() -> void:
	LevelManager.restart_from_level_1()
	
