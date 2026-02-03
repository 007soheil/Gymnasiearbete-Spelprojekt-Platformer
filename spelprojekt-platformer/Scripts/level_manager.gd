extends Node2D

const LAST_LEVEL = 1
const LEVEL_PATH = "res://Scenes/level_"

func change_to_next_level(current_level: int) -> void:
	$AnimationPlayer.play("fade_in")
	await $AnimationPlayer.animation_finished
	if current_level < LAST_LEVEL:
		get_tree().change_scene_to_file(LEVEL_PATH + str(current_level + 1) + ".tscn")
	else:
		get_tree().change_scene_to_file("res://Scenes/level_1.tscn")
	$AnimationPlayer.play("fade_out")

func change_to_victory_menu() -> void:
	pass

	
func restart_from_level_1() -> void:
	Globals.lives = 3
	$AnimationPlayer.play("fade_in")
	await $AnimationPlayer.animation_finished
	get_tree().change_scene_to_file(LEVEL_PATH + str(1) + ".tscn")
	$AnimationPlayer.play("fade_out")
	
