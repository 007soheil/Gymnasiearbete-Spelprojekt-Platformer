extends CanvasLayer

#Refererar till ljudspelare för game over musik
@onready var GameOverMenuMusic: AudioStreamPlayer = $GameOverMenuMusic

func _on_main_menu_button_pressed() -> void:
	#Byter scen till huvudmenyn när spelaren trycker på main meny knappen
	LevelManager.change_to_main_menu()


func _on_restart_button_pressed() -> void:
	#Startar om spelet från level 1 när spelaren trycker på restart knappen
	LevelManager.restart_from_level_1()
