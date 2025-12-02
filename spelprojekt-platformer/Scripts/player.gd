extends CharacterBody2D

const MAXIMUM_SPEED = 300
const ACC = 2500
const JUMP_VELOCITY = 600
const GRAVITY = 1250
const KNOCKBACK = 700

enum {IDLE, WALK, JUMP, AIR, DEATH, ATTACK1, ATTACK2}

var state = IDLE
var jump_buffer = 0.0
var coyote_timer = 0.0
var pressed_jump: bool = false
var has_jumped: bool = false

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

func _movement(delta: float, input_x: float) -> void:
	if input_x != 0:
		velocity.x = move_toward(velocity.x, input_x*MAXIMUM_SPEED, ACC*delta)
	else:
		velocity.x = move_toward(velocity.x, 0, ACC*delta)
			
	velocity.y += GRAVITY * delta
	apply_floor_snap()
	move_and_slide()

func _update_player_direction(input_x: float) -> void:
	if input_x > 0:
		player.flip_h = false
	if input_x < 0:
		player.flip_h = true

##### STATE FUNCTIONS #####

func _idle_state(delta: float) -> void:
	if Input.is_action_just_pressed("jump"):
		_enter_jump_state(true)
	
	var input_x = Input.get_axis("left", "right")
	_update_player_direction(input_x)
	
	_movement(delta, input_x)

	
	if velocity.length() > 0 and state != JUMP:
		_enter_walk_state()
	
func _walk_state(delta: float) -> void:
	var input_x = Input.get_axis("left", "right")
	_movement(delta, input_x)
	_update_player_direction(input_x)
	
	if Input.is_action_just_pressed("jump"):
		_enter_jump_state(true)
		
	if velocity.length() == 0:
		_enter_idle_state()
	
func _jump_state(delta: float) -> void:

	if Input.is_action_just_pressed("jump"):
		pressed_jump = true
	var input_x = Input.get_axis("left", "right")
	_update_player_direction(input_x)

	_movement(delta, input_x)
	if pressed_jump:
		jump_buffer += delta
		if jump_buffer > 0.1:
			pressed_jump = false
			jump_buffer = 0.0

	if is_on_floor() and pressed_jump:
		_enter_jump_state(true)
	elif is_on_floor() and velocity.length() == 0:
		_enter_idle_state()
	elif is_on_floor():
		_enter_walk_state()

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
	anim.play("idle")
	velocity.x = 0
	
func _enter_walk_state():
	state = WALK
	anim.play("walk")
	
	
func _enter_jump_state(jumping: bool):
	state = JUMP
	anim.play("jump")
	pressed_jump = false
	
	if jumping:
		velocity += JUMP_VELOCITY*up_direction

func _enter_air_state(jumping: bool):
	state = AIR
	
func _enter_death_state():
	state = DEATH
	anim.play("death")

func _enter_attack1_state():
	state = ATTACK1
	anim.play("attack2")
	
func _enter_attack2_state():
	state = ATTACK2
	anim.play("attack3")
