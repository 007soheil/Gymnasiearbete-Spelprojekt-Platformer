extends CharacterBody2D

const SPEED = 300
const ACC = 2500
const JUMP_VELOCITY = 600
const GRAVITY = 1250
const KNOCKBACK = 700

enum {IDLE, WALK, JUMP, AIR, DEATH, ATTACK1, ATTACK2}

var state = IDLE
var jump_buffer = 0.0
var coyote_timer = 0.0
var want_to_jump: bool = false

@onready var player: Sprite2D = $Sprite2D
@onready var anim: AnimationPlayer = $AnimationPlayer


func _physics_process(delta: float) -> void:
	match state:
		IDLE:
			_idle_state(delta)
		WALK:
			_walk_state(delta)
		JUMP:
			_jump_state(delta)
		AIR:
			_air_state(delta)
		DEATH:
			_death_state(delta)
		ATTACK1:
			_attack1_state(delta)
		ATTACK2:
			_attack2_state(delta)


##### GENERAL FUNCTIONS #####

func _update_player_direction():
	pass

##### STATE FUNCTIONS #####

func _idle_state(delta: float) -> void:
	pass
	#1
	#2
	#3
func _walk_state(delta: float) -> void:
	pass
func _jump_state(delta: float) -> void:
	pass
func _air_state(delta: float) -> void:
	pass
func _death_state(delta: float) -> void:
	pass
func _attack1_state(delta: float) -> void:
	pass
func _attack2_state(delta: float) -> void:
	pass

##### ENTER STATE FUNCTION #####
func _enter_idle_state():
	state = IDLE
	
func _enter_jump_state():
	state = JUMP

func _enter_air_state(jumping: bool):
	state = AIR
	
func _enter_death_state():
	state = DEATH

func _enter_attack1_state():
	state = ATTACK1
	
func _enter_attack2_state():
	state = ATTACK2
