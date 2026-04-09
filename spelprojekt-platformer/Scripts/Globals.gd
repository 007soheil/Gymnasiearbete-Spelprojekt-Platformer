extends Node

#enum för spelets svårighetsgrader
enum Difficulty {EASY, NORMAL, HARD}

#Nuvarande svårighetsgrad
var difficulty := Difficulty.NORMAL
#Spelarens liv
var lives = 3
#Spelarens samlade mynt
var coins = 0
#Uppgraderingar/perks som spelaren kan låsa upp
var dash_unlocked := false
var double_jump_unlocked := false


func apply_difficulty_settings():
	#Justerar spelarens liv baserat på vald svårighetsgrad
	match difficulty:
		Difficulty.EASY:
			lives = 3
		Difficulty.NORMAL:
			lives = 2
		Difficulty.HARD:
			lives = 1
