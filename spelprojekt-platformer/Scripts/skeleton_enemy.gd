extends CharacterBody2D

class_name Skeleton

#Konstanter för skeletten
const MAXIMUM_SPEED = 175
const ACC = 2000
const DAMAGE = 50
const KNOCKBACK = 100
const GRAVITY = 550

#States/tillstånd för skeletten
enum {IDLE, WALK, ATTACK, HURT, DEATH}

#Variabler för skeletten
var state = WALK
var direction: int = 1
var attack_player: bool = false #Om spelare har upptäckts
var health: int = 50
var can_take_damage: bool = true
var target_player: Player = null #Referens till spelaren om fienden upptäcker denne
var wall_turn_cooldown = 0.5
var wall_timer = 0.0
var player_in_attack_range: bool = false
var can_turn: bool = true

#Referenser till noder/timers/raycasts
@onready var skeleton: Sprite2D = $Sprite2D
@onready var anim: AnimationPlayer = $AnimationPlayer
@onready var damage_cooldown: Timer = $DamageCooldown
@onready var damage_player_collision: CollisionShape2D = $PlayerDetectArea/CollisionShape2D
@onready var attack_hitbox: CollisionShape2D = $AttackHitbox/CollisionShape2D
@onready var attack_delay: Timer = $AttackDelay
@onready var left_wall: RayCast2D = $LeftWall
@onready var right_wall: RayCast2D = $RightWall
@onready var left_edge: RayCast2D = $LeftEdge
@onready var right_edge: RayCast2D = $RightEdge
@onready var edge_timer: Timer = $EdgeTimer

func _physics_process(delta: float) -> void:
	#Speglar skeletten/dess attack hitbox beroende på riktning
	if direction == -1:
		skeleton.flip_h = true
		attack_hitbox.position = Vector2(-38, -9)
	else:
		skeleton.flip_h = false
		attack_hitbox.position = Vector2(38, -9)
	
	match state:
		#State machine
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
	#Börjar med att stänga av attack hitboxen
	attack_hitbox.set_deferred("disabled", true)

#### GENERAL HELP FUNCTIONS ####

func _update_enemy_direction(direction: int) -> void:
	#Uppdaterar attack hitbox riktning beroende på riktning
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
	
	#Upptäckt av kanter (så att skeletten inte faller från plattform)
	if is_on_floor() and can_turn:
		if direction == -1 and not left_edge.is_colliding():
			_turn_around()
		elif direction == 1 and not right_edge.is_colliding():
			_turn_around()
	#Påbörja jakt av spelare
	if attack_player and target_player != null:
		#Jaga spelare beroende på spelarens position
		var chase_dir = sign(target_player.global_position.x - global_position.x)
		
		if chase_dir == 0:
			chase_dir = direction #Undvika 0/att stå still
			
		#Uppdatera riktning mot spelaren
		if direction != chase_dir:
			direction = chase_dir
			_update_enemy_direction(direction)
		
		#Stannar lite om skeletten är vid väggen
		if (direction == -1 and left_wall.is_colliding()) or (direction == 1 and right_wall.is_colliding()):
			velocity.x = 0
		else:
			velocity.x = direction * MAXIMUM_SPEED
			
		
		#Attackera om spelare och skeletten är i samma område
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
	#Stå stilla vid attack
	velocity.x = 0
	#Gravitation
	velocity.y += GRAVITY * delta
	move_and_slide()
	#Vänta på animation
	if anim.is_playing():
		return
	#Stäng av attack hitbox efter attack
	attack_hitbox.set_deferred("disabled", true)
	
	
func _hurt_state(delta: float) -> void:
	#Gravitation
	velocity.y += GRAVITY * delta
	move_and_slide()
	
	#Byt till attack eller walk state efter hurt animation
	if not anim.is_playing():
		if attack_player:
			_enter_attack_state()
		else:
			_enter_walk_state()
	
func _death_state(delta: float) -> void:
	#Stäng av kollisioner som skadar spelare vid död
	damage_player_collision.set_deferred("disabled", true)
	attack_hitbox.set_deferred("disabled", true)
	#Vänta på animation
	if anim.is_playing():
		return
	#Ta bort fiende
	queue_free()
	
#### ENTER STATE FUNCTION ####
#Skeletten går in i olika states och animationer börjar spelas
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
	attack_delay.start() #Lite fördröjning innan attacken börjar

	
func _enter_hurt_state(from_position):
	state = HURT
	anim.play("hurt")
	attack_hitbox.set_deferred("disabled", true)
	$Hurt.play()
	
	if from_position != null: #Skeletten får knockback beroende på var den skadas
		_apply_knockback(from_position)
	
	can_take_damage = false #Damage cooldown
	damage_cooldown.start()
	
func _enter_death_state():
	state = DEATH
	anim.play("death")
	$Hurt.play()
	#Kollisioner stängs av för att skada spelaren och rörelse avslutas
	damage_player_collision.set_deferred("disabled", true)
	attack_hitbox.set_deferred("disabled", true)
	velocity = Vector2.ZERO

#### OTHER FUNCTIONS/SIGNALS ####
#Spelaren går in i jakt range
func _on_player_in_range_area_body_entered(body: Node2D) -> void:
	#Spelare upptäckt
	if body is Player:
		attack_player = true
		target_player = body
		skeleton.modulate = Color(1, 0.5, 0.5) #Skeletten blir blå om spelare upptäcks
		$ExclamationMark.visible = true
#Spelaren lämnar jakt range
func _on_player_in_range_area_body_exited(body: Node2D) -> void:
	#Spelare tappas bort
	if body == target_player:
		target_player = null
		attack_player = false
		skeleton.modulate = Color(1, 1, 1) #Skeletten återställs när spelare ej upptäcks
		$ExclamationMark.visible = false

func apply_damage(amount: int, from_position):
	if not can_take_damage:
		return
	#Ta skada
	health -= amount
	#Byta till death eller hurt state beroende på HP
	if health <= 0:
		_enter_death_state()
	else:
		_enter_hurt_state(from_position)


func _on_attack_hitbox_body_entered(body: Node2D) -> void:
	#Skadar spelaren
	if body is Player:
		body.apply_damage(DAMAGE, global_position)


func _on_damage_cooldown_timeout() -> void:
	#Damage cooldown tar slut
	can_take_damage = true


func _take_damage(from_position):
	#Byter till death eller hurt state beroende på HP
	if health <= 0:
		_enter_death_state()
	else:
		_enter_hurt_state(from_position)

func _apply_knockback(from_position: Vector2):
	#Skjuter fienden bort från attackkällan (spelaren)
	var knockback_direction = (global_position - from_position).normalized()
	velocity.x = knockback_direction.x * KNOCKBACK
	velocity.y = -50


func _on_animation_player_animation_finished(anim_name: StringName) -> void:
	#Funktionen körs varje gång en animation slutar spelas automatiskt och gör olika saker beroende på animationen, t.ex. byta state
	if anim_name == "attack":
		attack_hitbox.set_deferred("disabled", true)
		if health <= 0:
			attack_hitbox.set_deferred("disabled", true)
			_enter_death_state()
		else:
			attack_hitbox.set_deferred("disabled", true)
			_enter_walk_state()
	elif anim_name == "hurt":
		if health <= 0:
			attack_hitbox.set_deferred("disabled", true)
			_enter_death_state()
		elif attack_player:
			attack_hitbox.set_deferred("disabled", true)
			_enter_attack_state()
		else:
			attack_hitbox.set_deferred("disabled", true)
			_enter_walk_state()
	elif anim_name == "death":
		attack_hitbox.set_deferred("disabled", true)
		queue_free()

func _on_attack_delay_timeout() -> void:
	#Sätter på attack hitbox efter fördröjning
	attack_hitbox.set_deferred("disabled", false)

func _on_edge_timer_timeout() -> void:
	#Edge cooldown för att undvika att fastna vid kanter
	can_turn = true

func _turn_around():
	#Vänder och uppdaterar riktning
	direction *= -1
	_update_enemy_direction(direction)
	#Cooldown för att vända
	can_turn = false
	edge_timer.start()
