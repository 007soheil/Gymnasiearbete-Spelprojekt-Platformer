extends Node2D

#Konstanter för hantering av nivå
const LAST_LEVEL = 5
const LEVEL_PATH = "res://Scenes/level_"
const MAIN_MENU = "res://Scenes/main_menu.tscn"
const VICTORY_MENU = "res://Scenes/victory_menu.tscn"

#Preload för level 1
var level_1 = preload("res://Scenes/level.tscn")

#Håller reda på om spelet är pausat
var is_paused: bool = false

#### LEVEL / SCENE MANAGEMENT ####

func change_to_next_level(current_level: int) -> void:
	#Fade in animation före nivåbyte
	$AnimationPlayer.play("fade_in")
	await $AnimationPlayer.animation_finished
	
	#Byt till nästa nivå om det finns, annars starta om från level 1
	if current_level < LAST_LEVEL:
		get_tree().change_scene_to_file(LEVEL_PATH + str(current_level + 1) + ".tscn")
	else:
		get_tree().change_scene_to_file("res://Scenes/level_1.tscn")
	
	#Fade out efter nivåbyte
	$AnimationPlayer.play("fade_out")

func change_to_victory_menu() -> void: #Har för tillfället detta i level-script
	#Fade in animation
	$AnimationPlayer.play("fade_in")
	await $AnimationPlayer.animation_finished
	
	#Byt till victory meny
	get_tree().change_scene_to_file(VICTORY_MENU)
	
	#Fade out animation
	$AnimationPlayer.play("fade_out")
	
	#Spela victory musik
	$VictoryMenu.VictoryMenuMusic.play()

func restart_from_level_1() -> void:
	#Nollställa perks
	Globals.dash_unlocked = false
	Globals.double_jump_unlocked = false
	
	#Nollställa svårighetsgradsinställningar
	Globals.apply_difficulty_settings()
	
	#Nollställa mynt
	Globals.coins = 0
	
	#Fade in animation vid växling till första leveln
	$AnimationPlayer.play("fade_in")
	await $AnimationPlayer.animation_finished
	
	#Byt till level 1
	get_tree().change_scene_to_file(LEVEL_PATH + str(1) + ".tscn")
	
	#Fade out animation
	$AnimationPlayer.play("fade_out")

func start_new_game():
	#Nollställa perks
	Globals.dash_unlocked = false
	Globals.double_jump_unlocked = false

	#Återställ svårighetsgrad och mynt
	Globals.apply_difficulty_settings()
	Globals.coins = 0
	
	#Fade in animation och nivåbyte
	$AnimationPlayer.play("fade_in")
	await $AnimationPlayer.animation_finished
	get_tree().change_scene_to_file(LEVEL_PATH + str(1) + ".tscn")
	
	#get_tree().change_scene_to_packed(level_1)
	
	#Fade out animation
	$AnimationPlayer.play("fade_out")

func change_to_main_menu():
	#Nollställa perks
	Globals.dash_unlocked = false
	Globals.double_jump_unlocked = false
	#Återställ liv och mynt
	Globals.lives = 3
	Globals.coins = 0
	#Fade in animation och byt till huvudmenyn
	$AnimationPlayer.play("fade_in")
	await $AnimationPlayer.animation_finished
	get_tree().change_scene_to_file(MAIN_MENU)
	$AnimationPlayer.play("fade_out")
	
#### PAUSE HANDLING ####

func _unhandled_input(event):
	#Om paus knapp trycks, toggla paus
	if event.is_action_pressed("pause"):
		toggle_pause()

func toggle_pause():
	#Växla pausläge
	is_paused = !is_paused
	get_tree().paused = is_paused
	$PauseMenu.visible = is_paused
	#Spela pausmusik om spelet är pausat
	if is_paused:
		$PauseMenu.PauseMenuMusic.play()
