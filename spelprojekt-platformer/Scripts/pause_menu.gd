extends CanvasLayer

#Referens till musik
@onready var PauseMenuMusic: AudioStreamPlayer = $PauseMenuMusic

func _ready():
	#Gör att scenen fortfarande processas även om spelet pausas
	process_mode = Node.PROCESS_MODE_ALWAYS

func _on_resume_button_pressed() -> void:
	#Återupptar spelet när resume trycks
	_resume_game()
	
func _resume_game():
	#Stoppar pausmusik
	$PauseMenuMusic.stop()
	#Informerar föräldern (level-manager) att toggla paus (unpausa)
	get_parent().toggle_pause()
	#Återuppta spel/avsluta paus
	get_tree().paused = false

func _on_main_menu_button_pressed() -> void:
	$PauseMenuMusic.stop() #Stoppar musik
	get_tree().paused = false #Säkersställ att spelet inte är pausat
	get_parent().toggle_pause() #Togglar paus i level_manager
	LevelManager.change_to_main_menu() #Går tillbaka till main meny
