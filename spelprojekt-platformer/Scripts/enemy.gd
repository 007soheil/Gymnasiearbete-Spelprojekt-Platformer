extends CharacterBody2D

class_name Enemy

const MAXIMUM_SPEED = 200
const ACC = 2000
const DAMAGE = 25
const KNOCKBACK = 200
const GRAVITY = 550

enum {IDLE, FLYING, TURN, ATTACK, HURT, DEATH}

var state = FLYING
var direction: int = 1
var attack_player: bool = false
var turn_after_a_while: float = randf_range(4, 6)
var turn_timer: float = 0
var health: int = 50
var can_take_damage: bool = true
var target_player: Player = null

@onready var enemy: Sprite2D = $Sprite2D
@onready var anim: AnimationPlayer = $AnimationPlayer
@onready var damage_cooldown: Timer = $DamageCooldown
@onready var damage_player_collision: CollisionShape2D = $PlayerDetectArea/CollisionShape2D

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

"""
func _take_damage():
	if health <= 0:
		_enter_death_state()
	else:
		_enter_hurt_state(from_position)
"""
#### STATE FUNCTIONS ####

func _idle_state(delta: float) -> void:
	pass

func _flying_state(delta: float) -> void:
	anim.play("flying")
	
	if attack_player and target_player != null:
		#Riktningen mot spelaren
		direction = sign(target_player.global_position.x - global_position.x)
		_update_enemy_direction(direction)
		velocity.x = direction * MAXIMUM_SPEED
		velocity.y = 0 #Låsa y-led
	else:
		#Patrullera normalt
		velocity.x = direction * MAXIMUM_SPEED
		turn_timer -= delta
		if turn_timer <= 0.0:
			direction *= -1
			_update_enemy_direction(direction)
			_reset_turn_timer()
	
	if is_on_wall():
		direction *= -1
		_reset_turn_timer()
		velocity.x = direction * MAXIMUM_SPEED
		_update_enemy_direction(direction)
	
	move_and_slide()
	
	#Om spelaren är i närheten
	if attack_player and target_player != null:
		var distance_to_player = global_position.distance_to(target_player.global_position)
		if distance_to_player < 30:
			_enter_attack_state()


func _attack_state(delta: float) -> void:
	if anim.is_playing():
		return
	_enter_flying_state()
	
func _hurt_state(delta: float) -> void:
	velocity.y += GRAVITY * delta
	move_and_slide()
	
	if not anim.is_playing():
		if attack_player:
			_enter_attack_state()
		else:
			_enter_flying_state()
	
func _death_state(delta: float) -> void:
	damage_player_collision.set_deferred("disabled", true)
	
	if anim.is_playing():
		return
	
	queue_free()
	
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
	
func _enter_hurt_state(from_position):
	state = HURT
	anim.play("hurt")
	$Hurt.play()
	
	if from_position != null:
		_apply_knockback(from_position)
	can_take_damage = false
	damage_cooldown.start()
	
func _enter_death_state():
	state = DEATH
	anim.play("death")


func _on_player_in_range_area_body_entered(body: Node2D) -> void:
	if body is Player:
		attack_player = true
		target_player = body
		enemy.modulate = Color(1, 0.5, 0.5) #Fienden blir röd om spelare upptäcks
		$ExclamationMark.visible = true

func _on_player_in_range_area_body_exited(body: Node2D) -> void:
	if body == target_player:
		target_player = null
		attack_player = false
		enemy.modulate = Color(1, 1, 1) #Fiender återställs när spelare ej upptäcks
		$ExclamationMark.visible = false

func apply_damage(amount: int, from_position):
	if not can_take_damage:
		return
	if can_take_damage:
		health -= amount
		_enter_hurt_state(from_position)
		can_take_damage = false
		damage_cooldown.start()
	if health <= 0:
		_enter_death_state()


func _on_player_detect_area_body_entered(body: Node2D) -> void:
	if body is Player:
		body.apply_damage(DAMAGE, global_position)


func _on_damage_cooldown_timeout() -> void:
	can_take_damage = true


func _take_damage(from_position):
	if health <= 0:
		_enter_death_state()
	else:
		_enter_hurt_state(from_position)

func _apply_knockback(from_position: Vector2):
	var knockback_direction = (global_position - from_position).normalized()
	velocity.x = knockback_direction.x * KNOCKBACK
	velocity.y = -200
