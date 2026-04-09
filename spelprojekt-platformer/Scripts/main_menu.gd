extends CanvasLayer

#Refererar till musik
@onready var MainMenuMusic: AudioStreamPlayer = $MainMenuMusic

func _ready():
	$MainMenuMusic.play() #Starta musik när menyn visas
	get_tree().paused = false #Säkerställ att spelet inte är pausat när man återgår till huvudmenyn

func _on_easy_button_pressed() -> void:
	#Sätter svårighetsgrad till lätt och startar nytt spel
	Globals.difficulty = Globals.Difficulty.EASY
	LevelManager.start_new_game()

func _on_normal_button_pressed() -> void:
	#Sätter svårighetsgrad till medel och startar nytt spel
	Globals.difficulty = Globals.Difficulty.NORMAL
	LevelManager.start_new_game()

func _on_hard_button_pressed() -> void:
	#Sätter svårighetsgrad till svår och startar nytt spel
	Globals.difficulty = Globals.Difficulty.HARD
	LevelManager.start_new_game()

func _on_quit_button_pressed() -> void:
	get_tree().quit() #Stänger spelet
