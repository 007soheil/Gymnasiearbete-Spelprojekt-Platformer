extends Node

enum Difficulty {EASY, NORMAL, HARD}

var difficulty := Difficulty.NORMAL

var lives = 3
var coins = 0

var dash_unlocked := false
var double_jump_unlocked := false

func apply_difficulty_settings():
	match difficulty:
		Difficulty.EASY:
			lives = 3
		Difficulty.NORMAL:
			lives = 2
		Difficulty.HARD:
			lives = 1
