extends Node2D

const LAST_LEVEL = 4
const LEVEL_PATH = "res://Scenes/level_"
const MAIN_MENU = "res://Scenes/main_menu.tscn"
const VICTORY_MENU = "res://Scenes/victory_menu.tscn"

var level_1 = preload("res://Scenes/level.tscn")
var is_paused: bool = false



func change_to_next_level(current_level: int) -> void:
	$AnimationPlayer.play("fade_in")
	await $AnimationPlayer.animation_finished
	if current_level < LAST_LEVEL:
		get_tree().change_scene_to_file(LEVEL_PATH + str(current_level + 1) + ".tscn")
	else:
		get_tree().change_scene_to_file("res://Scenes/level_1.tscn")
	$AnimationPlayer.play("fade_out")

	
func change_to_victory_menu() -> void: #Har för tillfället detta i level-script
	$AnimationPlayer.play("fade_in")
	await $AnimationPlayer.animation_finished
	get_tree().change_scene_to_file(VICTORY_MENU)
	$AnimationPlayer.play("fade_out")
	$VictoryMenu.VictoryMenuMusic.play()


func restart_from_level_1() -> void:
	#Nollställa perks
	var dash_unlocked := false
	var double_jump_unlocked := false
	
	Globals.apply_difficulty_settings()
	Globals.coins = 0
	$AnimationPlayer.play("fade_in")
	await $AnimationPlayer.animation_finished
	get_tree().change_scene_to_file(LEVEL_PATH + str(1) + ".tscn")
	$AnimationPlayer.play("fade_out")


func start_new_game():
	#Nollställa perks
	var dash_unlocked := false
	var double_jump_unlocked := false

	Globals.apply_difficulty_settings()
	Globals.coins = 0
	$AnimationPlayer.play("fade_in")
	await $AnimationPlayer.animation_finished
	get_tree().change_scene_to_file(LEVEL_PATH + str(1) + ".tscn")
	#get_tree().change_scene_to_packed(level_1)
	$AnimationPlayer.play("fade_out")

func change_to_main_menu():
	Globals.lives = 3
	Globals.coins = 0
	$AnimationPlayer.play("fade_in")
	await $AnimationPlayer.animation_finished
	get_tree().change_scene_to_file(MAIN_MENU)
	$AnimationPlayer.play("fade_out")
	

func _unhandled_input(event):
	if event.is_action_pressed("pause"):
		toggle_pause()

func toggle_pause():
	is_paused = !is_paused
	get_tree().paused = is_paused
	$PauseMenu.visible = is_paused
	if is_paused:
		$PauseMenu.PauseMenuMusic.play()
