extends CharacterBody2D

class_name Enemy

#Konstanter för fiender
const MAXIMUM_SPEED = 200
const ACC = 2000
const DAMAGE = 25
const KNOCKBACK = 200
const GRAVITY = 550

#State machine för fienden
enum {IDLE, FLYING, TURN, ATTACK, HURT, DEATH}

#Fiendens variabler
var state = FLYING
var direction: int = 1
var attack_player: bool = false
var turn_after_a_while: float = randf_range(4, 6) #Slumpad tid tills fienden vänder
var turn_timer: float = 0
var health: int = 50
var can_take_damage: bool = true
var target_player: Player = null #Referens till spelaren om fienden upptäcker denne

#Referenser till noder
@onready var enemy: Sprite2D = $Sprite2D
@onready var anim: AnimationPlayer = $AnimationPlayer
@onready var damage_cooldown: Timer = $DamageCooldown
@onready var damage_player_collision: CollisionShape2D = $PlayerDetectArea/CollisionShape2D

func _physics_process(delta: float) -> void:
	match state: #Fiendens state machine, växling mellan olika tillstånd
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
	#Spegla fiendens sprite beroende på rörelseriktning
	if direction == -1:
		enemy.flip_h = false
		enemy.offset = Vector2(0, 0)
	if direction == 1:
		enemy.flip_h = true
		enemy.offset = Vector2(-17, 0)
		
func _reset_turn_timer():
	#Slumpa ny tid innan nästa vändning
	turn_after_a_while = randf_range(4, 6)
	turn_timer = turn_after_a_while

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
		#Om fienden träffar en vägg, vänd
		direction *= -1
		_reset_turn_timer()
		velocity.x = direction * MAXIMUM_SPEED
		_update_enemy_direction(direction)
	
	move_and_slide()
	
	#Om spelaren är i närheten, attackera
	if attack_player and target_player != null:
		var distance_to_player = global_position.distance_to(target_player.global_position)
		if distance_to_player < 30:
			_enter_attack_state()


func _attack_state(delta: float) -> void:
	#Väntar tills animationen är klar
	if anim.is_playing():
		return
	#Gå tillbaka till fly state efter attack
	_enter_flying_state()
	
func _hurt_state(delta: float) -> void:
	#Fienden påverkas av gravitation vid skada
	velocity.y += GRAVITY * delta
	move_and_slide()
	#När animationen är klar går den in i attack eller fly state
	if not anim.is_playing():
		if attack_player:
			_enter_attack_state()
		else:
			_enter_flying_state()
	
func _death_state(delta: float) -> void:
	#Stänga av kollision som skadar spelaren
	damage_player_collision.set_deferred("disabled", true)
	#Väntar på animationen
	if anim.is_playing():
		return
	#Ta bort fienden
	queue_free()
	
#### ENTER STATE FUNCTION ####
#Fienden går in i olika states och animationer börjar spelas
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
	
	if from_position != null: #Fienden får knockback beroende på var den skadas
		_apply_knockback(from_position)
	
	can_take_damage = false #Damage cooldown
	damage_cooldown.start()
	
func _enter_death_state():
	state = DEATH
	anim.play("death")

#### PLAYER INTERACTION FUNCTIONS ####
func _on_player_in_range_area_body_entered(body: Node2D) -> void:
	if body is Player: #Om spelaren är inom området för att bli jagad
		attack_player = true
		target_player = body
		enemy.modulate = Color(1, 0.5, 0.5) #Fienden blir röd om spelare upptäcks
		$ExclamationMark.visible = true

func _on_player_in_range_area_body_exited(body: Node2D) -> void:
	if body == target_player: #Om spelaren lämnar området för att bli jagad
		target_player = null
		attack_player = false
		enemy.modulate = Color(1, 1, 1) #Fiender återställs när spelare ej upptäcks
		$ExclamationMark.visible = false

#### DAMAGE AND KNOCKBACK ####
func apply_damage(amount: int, from_position):
	if not can_take_damage:
		return
	#Minska HP och gå in i hurt state
	if can_take_damage:
		health -= amount
		_enter_hurt_state(from_position)
		can_take_damage = false
		damage_cooldown.start()
	#Gå in i death state om HP är 0
	if health <= 0:
		_enter_death_state()


func _on_player_detect_area_body_entered(body: Node2D) -> void:
	#Skadar spelaren när fienden rör vid den
	if body is Player:
		body.apply_damage(DAMAGE, global_position)


func _on_damage_cooldown_timeout() -> void:
	can_take_damage = true #Kan ta skada igen när timern tar slut

func _take_damage(from_position):
	#Gå in i death state eller hurt beroende på HP
	if health <= 0:
		_enter_death_state()
	else:
		_enter_hurt_state(from_position)

func _apply_knockback(from_position: Vector2):
	#Skjuter fienden bort från attackkällan (spelaren)
	var knockback_direction = (global_position - from_position).normalized()
	velocity.x = knockback_direction.x * KNOCKBACK
	velocity.y = -200
