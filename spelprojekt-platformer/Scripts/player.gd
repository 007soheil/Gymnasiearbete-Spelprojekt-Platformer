extends CharacterBody2D

class_name Player

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
var attacking: bool = false
var attacking2: bool = false
var is_falling: bool = false
var can_special_attack: bool = true
var can_jump: bool = true
var health: int = 100

@onready var player: Sprite2D = $Sprite2D
@onready var anim: AnimationPlayer = $AnimationPlayer
@onready var specialattackcooldown: Timer = $Special_Attack_Cooldown

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
	
	if velocity.y > 0:
		_enter_air_state(false)

	if Input.is_action_just_pressed("attack"):
		_enter_attack1_state(true)
	
	if Input.is_action_just_pressed("specialattack") and can_special_attack:
		_enter_attack2_state(true)
	
	if velocity.length() > 0 and state != JUMP and is_on_floor():
		_enter_walk_state()

	
func _walk_state(delta: float) -> void:
	var input_x = Input.get_axis("left", "right")
	_movement(delta, input_x)
	_update_player_direction(input_x)
		
	if velocity.y > 0 and state != JUMP and not is_on_floor():
		_enter_air_state(false)
		
	elif Input.is_action_just_pressed("jump"):
		_enter_jump_state(true)
		
	elif Input.is_action_just_pressed("attack"):
		_enter_attack1_state(true)
		
	elif Input.is_action_just_pressed("specialattack") and can_special_attack:
		_enter_attack2_state(true)
		
	elif velocity.length() == 0:
		_enter_idle_state()
	elif not is_on_floor():
		_enter_jump_state(false)

	
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


	if Input.is_action_just_pressed("attack"):
		_enter_attack1_state(true)
	if Input.is_action_just_pressed("specialattack") and can_special_attack:
		_enter_attack2_state(true)
	elif not is_on_floor() and not pressed_jump and velocity.y > 0:
		_enter_air_state(true)
	elif is_on_floor() and pressed_jump:
		_enter_jump_state(true)
	elif is_on_floor() and velocity.length() == 0:
		_enter_idle_state()
	elif is_on_floor():
		_enter_walk_state()
	#elif Input.is_action_just_pressed("attack"):
		#_enter_attack1_state(true)
	
func _air_state(delta: float) -> void:
	var input_x = Input.get_axis("left", "right")
	_movement(delta, input_x)
	_update_player_direction(input_x)
	
	if not is_on_floor() and can_jump:
		coyote_timer += delta
		if coyote_timer > 1.0:
			can_jump = false
			coyote_timer = 0.0
	
	if Input.is_action_just_pressed("jump") and can_jump:
		_enter_jump_state(true)
	elif velocity.length() == 0:
		_enter_idle_state()
	elif velocity.length() != 0 and is_on_floor():
		_enter_walk_state()
	elif Input.is_action_just_pressed("attack"):
		_enter_attack1_state(true)
	elif Input.is_action_just_pressed("specialattack") and can_special_attack:
		_enter_attack2_state(true)
	
func _death_state(delta: float) -> void:
	pass
	
func _attack1_state(delta: float) -> void:
	var input_x = Input.get_axis("left", "right")
	_movement(delta, input_x)
	_update_player_direction(input_x)
	
	#före jump om man ska vänta tills attacken är klar
	#if anim.is_playing(): #attackanimationen
		#return
	
	if Input.is_action_just_pressed("jump") and is_on_floor():
		_enter_jump_state(true)
	
	if anim.is_playing(): #väntar på attackanimationen
		return
		
	if velocity.length() == 0:
		_enter_idle_state()
	if velocity.length() != 0 and not anim.is_playing():
		_enter_walk_state()
	
func _attack2_state(delta: float) -> void:
	var input_x = Input.get_axis("left", "right")
	_movement(delta, input_x)
	_update_player_direction(input_x)
	
	if Input.is_action_just_pressed("jump") and is_on_floor():
		_enter_jump_state(true)
		
	if anim.is_playing():
		return
	
	if velocity.length() == 0:
		_enter_idle_state()
	if velocity.length() != 0 and not anim.is_playing():
		_enter_walk_state()

##### ENTER STATE FUNCTION #####
func _enter_idle_state():
	state = IDLE
	anim.play("idle")
	velocity.x = 0
	
func _enter_walk_state(): #nya _run_state
	state = WALK
	anim.play("run")
	
	
func _enter_jump_state(jumping: bool):
	state = JUMP
	anim.play("jump")
	pressed_jump = false
	
	if jumping:
		velocity += JUMP_VELOCITY*up_direction

func _enter_air_state(jump):
	state = AIR
	anim.play("fall")
	is_falling = true
	if not jump:
		can_jump = true
	
func _enter_death_state():
	state = DEATH
	anim.play("death")

func _enter_attack1_state(attacking: bool):
	state = ATTACK1
	anim.play("attack2")
	attacking = true
	
func _enter_attack2_state(attacking2: bool):
	if can_special_attack:
		can_special_attack = false
		state = ATTACK2
		anim.play("attack3")
		attacking2 = true
		specialattackcooldown.start()


func _on_special_attack_cooldown_timeout() -> void:
	can_special_attack = true


func _on_hitbox_area_entered(area: Area2D) -> void:
	pass
