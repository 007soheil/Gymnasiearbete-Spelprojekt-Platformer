extends CharacterBody2D

class_name Enemy

const MAXIMUM_SPEED = 200
const ACC = 2000

enum {IDLE, FLYING, TURN, ATTACK, HURT, DEATH}

var state = FLYING
var direction: int = 1
var attack_player: bool = false
var turn_after_a_while: float = randf_range(4, 6)
var turn_timer: float = 0
var health: int = 50

@onready var enemy: Sprite2D = $Sprite2D
@onready var anim: AnimationPlayer = $AnimationPlayer

func _physics_process(delta: float) -> void:
	match state:
		IDLE:
			_idle_state(delta)
		FLYING:
			_flying_state(delta)
		ATTACK:
			_attack_state(delta)
		HURT:
			_hurt_state(delta)
		DEATH:
			_death_state(delta)

#### GENERAL HELP FUNCTIONS ####

func _update_enemy_direction(direction: int) -> void:
	if direction == -1:
		enemy.flip_h = false
		enemy.offset = Vector2(0, 0)
	if direction == 1:
		enemy.flip_h = true
		enemy.offset = Vector2(-17, 0)
		
func _reset_turn_timer():
	turn_after_a_while = randf_range(4, 6)
	turn_timer = turn_after_a_while
	
func _take_damage():
	pass
	if health <= 0:
		_enter_death_state()

#### STATE FUNCTIONS ####

func _idle_state(delta: float) -> void:
	pass

func _flying_state(delta: float) -> void:
	anim.play("flying")
	_update_enemy_direction(direction)
	velocity.x = direction*MAXIMUM_SPEED
	move_and_slide()
	
	turn_timer -= delta
	if turn_timer <= 0.0:
		direction *= -1
		_update_enemy_direction(direction)
		_reset_turn_timer()
	
	if is_on_wall():
		direction *= -1
		_update_enemy_direction(direction)
		_reset_turn_timer()	
	
	if attack_player:
		_enter_attack_state()
	

func _attack_state(delta: float) -> void:
	pass
	
func _hurt_state(delta: float) -> void:
	pass
	
func _death_state(delta: float) -> void:
	pass
	
#### ENTER STATE FUNCTION ####

func _enter_idle_state():
	state = IDLE
	anim.play("idle")

func _enter_flying_state():
	state = FLYING
	anim.play("flying")
	
func _enter_attack_state():
	state = ATTACK
	anim.play("attack")
	
func _enter_hurt_state():
	state = HURT
	anim.play("hurt")
	
func _enter_death_state():
	state = DEATH
	anim.play("death")


func _on_player_in_range_area_area_entered(body: Node2D) -> void:
	if body is Player:
		attack_player = true
