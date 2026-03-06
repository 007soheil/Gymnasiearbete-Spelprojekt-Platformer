extends CharacterBody2D

class_name Skeleton

const MAXIMUM_SPEED = 175
const ACC = 2000
const DAMAGE = 50
const KNOCKBACK = 100
const GRAVITY = 550

enum {IDLE, WALK, ATTACK, HURT, DEATH}

var state = WALK
var direction: int = 1
var attack_player: bool = false
var health: int = 50
var can_take_damage: bool = true
var target_player: Player = null
var wall_turn_cooldown = 0.5
var wall_timer = 0.0
var player_in_attack_range: bool = false

@onready var skeleton: Sprite2D = $Sprite2D
@onready var anim: AnimationPlayer = $AnimationPlayer
@onready var damage_cooldown: Timer = $DamageCooldown
@onready var damage_player_collision: CollisionShape2D = $PlayerDetectArea/CollisionShape2D
@onready var attack_hitbox: CollisionShape2D = $AttackHitbox/CollisionShape2D
@onready var attack_delay: Timer = $AttackDelay
@onready var left_wall: RayCast2D = $LeftWall
@onready var right_wall: RayCast2D = $RightWall

func _physics_process(delta: float) -> void:
	if direction == -1:
		skeleton.flip_h = true
	else:
		skeleton.flip_h = false
	
	match state:
		IDLE:
			_idle_state(delta)
		WALK:
			_walk_state(delta)
		ATTACK:
			_attack_state(delta)
		HURT:
			_hurt_state(delta)
		DEATH:
			_death_state(delta)

func _ready():
	attack_hitbox.set_deferred("disabled", true)

#### GENERAL HELP FUNCTIONS ####

func _update_enemy_direction(direction: int) -> void:
	if direction == -1:
		attack_hitbox.position = Vector2(-38, -9)
	if direction == 1:
		attack_hitbox.position = Vector2(38, -9)


#### STATE FUNCTIONS ####

func _idle_state(delta: float) -> void:
	pass

func _walk_state(delta: float) -> void:
	#Sätta igång walk animation ifall den inte är igång
	if anim.current_animation != "walk":
		anim.play("walk")
		
	#Gravitation
	velocity.y += GRAVITY * delta

	if attack_player and target_player != null:
		#Jaga spelare
		var chase_dir = sign(target_player.global_position.x - global_position.x)
		if chase_dir == 0:
			chase_dir = direction #Undvika 0
		if direction != chase_dir:
			direction = chase_dir
			_update_enemy_direction(direction)
		
		#Stannar lite om skeletten är vid väggen
		if (direction == -1 and left_wall.is_colliding()) or (direction == 1 and right_wall.is_colliding()):
			velocity.x = 0
		else:
			velocity.x = direction * MAXIMUM_SPEED

		#Attackera om spelare och boss är i samma område
		if $PlayerDetectArea.get_overlapping_bodies().has(target_player):
			_enter_attack_state()
			velocity.x = 0
			return

	else:
		#Patrullera
		velocity.x = direction * MAXIMUM_SPEED

		#Uppdatera väggtimer
		if wall_timer > 0:
			wall_timer -= delta

		#Vänd riktning om skeletten träffar väggen eller en annan skelett
		if wall_timer <= 0 and ((direction == -1 and (left_wall.is_colliding() or is_on_wall())) or (direction == 1 and (right_wall.is_colliding() or is_on_wall()))):
			direction *= -1
			_update_enemy_direction(direction)
			wall_timer = wall_turn_cooldown

	#Röra på skeletten
	move_and_slide()

func _attack_state(delta: float) -> void:
	velocity.x = 0
	move_and_slide()
	if anim.is_playing():
		return
	attack_hitbox.set_deferred("disabled", true)
	
	
func _hurt_state(delta: float) -> void:
	velocity.y += GRAVITY * delta
	move_and_slide()
	
	if not anim.is_playing():
		if attack_player:
			_enter_attack_state()
		else:
			_enter_walk_state()
	
func _death_state(delta: float) -> void:
	damage_player_collision.set_deferred("disabled", true)
	
	if anim.is_playing():
		return
	
	queue_free()
	
#### ENTER STATE FUNCTION ####

func _enter_idle_state():
	state = IDLE
	anim.play("idle")

func _enter_walk_state():
	state = WALK
	anim.play("walk")
	
func _enter_attack_state():
	state = ATTACK
	velocity = Vector2.ZERO
	anim.play("attack")
	attack_delay.start()

	
func _enter_hurt_state(from_position):
	state = HURT
	anim.play("hurt")
	#$Hurt.play() Inget hurt ljud än
	
	if from_position != null:
		_apply_knockback(from_position)
	can_take_damage = false
	damage_cooldown.start()
	
func _enter_death_state():
	state = DEATH
	anim.play("death")
	damage_player_collision.set_deferred("disabled", true)
	attack_hitbox.set_deferred("disabled", true)
	velocity = Vector2.ZERO


func _on_player_in_range_area_body_entered(body: Node2D) -> void:
	if body is Player:
		attack_player = true
		target_player = body
		skeleton.modulate = Color(1, 0.5, 0.5) #Skeletten blir blå om spelare upptäcks
		$ExclamationMark.visible = true

func _on_player_in_range_area_body_exited(body: Node2D) -> void:
	if body == target_player:
		target_player = null
		attack_player = false
		skeleton.modulate = Color(1, 1, 1) #Skeletten återställs när spelare ej upptäcks
		$ExclamationMark.visible = false

func apply_damage(amount: int, from_position):
	if not can_take_damage:
		return
		
	health -= amount
	
	if health <= 0:
		_enter_death_state()
	else:
		_enter_hurt_state(from_position)


func _on_attack_hitbox_body_entered(body: Node2D) -> void:
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
	velocity.y = -50


func _on_animation_player_animation_finished(anim_name: StringName) -> void:
	if anim_name == "attack":
		attack_hitbox.set_deferred("disabled", true)
		if health <= 0:
			_enter_death_state()
		else:
			_enter_walk_state()
	elif anim_name == "hurt":
		if health <= 0:
			_enter_death_state()
		elif attack_player:
			_enter_attack_state()
		else:
			_enter_walk_state()
	elif anim_name == "death":
		queue_free()

func _on_attack_delay_timeout() -> void:
	attack_hitbox.set_deferred("disabled", false)
