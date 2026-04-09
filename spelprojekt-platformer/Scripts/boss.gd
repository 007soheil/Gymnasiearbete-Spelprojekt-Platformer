extends CharacterBody2D

class_name Boss

#Konstanter för rörelse och strid
const MAXIMUM_SPEED = 100
const ACC = 2000
const DAMAGE = 50
const KNOCKBACK = 100
const GRAVITY = 550

#Bossens state machine
enum {IDLE, WALK, ATTACK, HURT, DEATH}

#Olika variabler för bossen
var state = WALK
var direction: int = -1
var attack_player: bool = false
var health: int = 150
var can_take_damage: bool = true
var target_player: Player = null #Referens till spelaren om fienden upptäcker denne
var player_in_attack_range: bool = false

#Vägglogik för patrullering
var wall_turn_cooldown = 0.5
var wall_timer = 0.0

#Referenser till noder
@onready var boss: Sprite2D = $Sprite2D
@onready var anim: AnimationPlayer = $AnimationPlayer
@onready var damage_cooldown: Timer = $DamageCooldown
@onready var damage_player_collision: CollisionShape2D = $PlayerDetectArea/CollisionShape2D
@onready var attack_hitbox: CollisionShape2D = $AttackHitbox/CollisionShape2D
@onready var attack_delay: Timer = $AttackDelay
@onready var left_wall: RayCast2D = $LeftWall
@onready var right_wall: RayCast2D = $RightWall

#Signal som skickas när bossen är död
signal boss_dead

func _physics_process(delta: float) -> void:
	match state: #State machine som styr bossens beteende
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
	#print(state)

func _ready():
	#Börjar spelet med avstängd hitbox för attack
	attack_hitbox.set_deferred("disabled", true)

#### GENERAL HELP FUNCTIONS ####

func _update_boss_direction(direction: int) -> void:
	#Vänder sprite och flyttar attack-hitboxen beroende på riktning
	if direction == -1:
		boss.flip_h = false
		attack_hitbox.position = Vector2(-46.5, 14)
	if direction == 1:
		boss.flip_h = true
		attack_hitbox.position = Vector2(46.5, 14)


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
		#Byt riktning och det behövs
		if chase_dir != direction:
			direction = chase_dir
			_update_boss_direction(direction)
		
		#Stoppa vid en vägg
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
		#Patrullera runt
		velocity.x = direction * MAXIMUM_SPEED

		#Uppdatera väggtimer
		if wall_timer > 0:
			wall_timer -= delta

		#Byta riktning om boss når väggen
		if direction == -1 and left_wall.is_colliding() and wall_timer <= 0:
			direction = 1
			_update_boss_direction(direction)
			wall_timer = wall_turn_cooldown
		elif direction == 1 and right_wall.is_colliding() and wall_timer <= 0:
			direction = -1
			_update_boss_direction(direction)
			wall_timer = wall_turn_cooldown

	#Röra på bossen
	move_and_slide()

func _attack_state(delta: float) -> void:
	#Bossen står still när den attackerar
	velocity.x = 0
	move_and_slide()
	#Vänta tills animationen är klar
	if anim.is_playing():
		return
	#Stäng av hitbox efter attack
	attack_hitbox.set_deferred("disabled", true)
	
	
func _hurt_state(delta: float) -> void:
	#Stäng av hitbox under skada
	attack_hitbox.set_deferred("disabled", true)
	
	velocity.y += GRAVITY * delta
	move_and_slide()
	#Går vidare när animationen är klar
	if not anim.is_playing():
		if attack_player:
			_enter_attack_state()
		else:
			_enter_walk_state()
	
func _death_state(delta: float) -> void:
	#Stänger av all kollision när bossen dör
	attack_hitbox.set_deferred("disabled", true)
	damage_player_collision.set_deferred("disabled", true)
	#Vänta på animation
	if anim.is_playing():
		return
	#Ta bort bossen från scenen
	queue_free()
	
#### ENTER STATE FUNCTION ####
#Bossen går in i olika states och animationer börjar spelas
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
	attack_delay.start() #Dröjning/delay innan hitbox aktiveras

	
func _enter_hurt_state(from_position):
	state = HURT
	anim.play("hurt")
	#Stänger av attack hitboxen
	attack_hitbox.set_deferred("disabled", true)
	
	#Spela hurt-ljud/justeringar
	$Hurt.pitch_scale = 2.0
	$Hurt.volume_db = 8.0
	$Hurt.play()
	#Knockback från spelaren
	if from_position != null:
		_apply_knockback(from_position)
	#Tillfällig odödlighet
	can_take_damage = false
	damage_cooldown.start()
	
func _enter_death_state():
	state = DEATH
	anim.play("death")
	
	#Dödsljud/justeringar
	$Hurt.pitch_scale = 1.0
	$Hurt.volume_db = 10.0
	$Hurt.play()
	
	#Signal som skickar när bossen är död
	boss_dead.emit()
	
	#Stäng av all kollision och rörelse
	damage_player_collision.set_deferred("disabled", true)
	attack_hitbox.set_deferred("disabled", true)
	velocity = Vector2.ZERO

#### PLAYER INTERACTION FUNCTIONS ####
func _on_player_in_range_area_body_entered(body: Node2D) -> void:
	if body is Player:
		attack_player = true
		target_player = body
		boss.modulate = Color(0.5, 0.5, 1) #Bossen blir blå om spelare upptäcks

func _on_player_in_range_area_body_exited(body: Node2D) -> void:
	if body == target_player:
		target_player = null
		attack_player = false
		boss.modulate = Color(1, 1, 1) #Bossen återställs när spelare ej upptäcks


#### DAMAGE FUNCTIONS ####
func apply_damage(amount: int, from_position):
	#Inget händer om boss inte kan ta damage
	if not can_take_damage:
		return
	#Boss tar damage från spelarens attack
	health -= amount
	#Bossen går in i death state om den har 0 hp, annars går den in i hurt state och får knockback
	if health <= 0:
		_enter_death_state()
	else:
		_enter_hurt_state(from_position)
		
func _apply_knockback(from_position: Vector2):
	#Skjuter bossen bort från spelaren och räknar ut riktningen från attackens position
	var knockback_direction = (global_position - from_position).normalized()
	velocity.x = knockback_direction.x * KNOCKBACK
	velocity.y = -50

#### ATTACK FUNCTIONS ####
func _on_attack_hitbox_body_entered(body: Node2D) -> void:
	if body is Player: #Spelaren tar damage om den går in i attack hitbox
		body.apply_damage(DAMAGE, global_position)


func _on_damage_cooldown_timeout() -> void:
	#Bossen kan ta damage igen
	can_take_damage = true


func _take_damage(from_position): #Går in i olika states beroende på hp
	if health <= 0:
		_enter_death_state()
	else:
		_enter_hurt_state(from_position)


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
	#Aktivera attack hitbox efter dröjning/delay
	attack_hitbox.set_deferred("disabled", false)
