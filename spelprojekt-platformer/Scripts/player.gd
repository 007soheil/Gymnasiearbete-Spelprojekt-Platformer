extends CharacterBody2D

class_name Player

#Konstanter för spelaren
const MAXIMUM_SPEED = 300
const ACC = 2500
const JUMP_VELOCITY = 600
const GRAVITY = 1250
const KNOCKBACK = 300
const DAMAGE = 25
const EXTRA_JUMPS_LOCKED = 0
const EXTRA_JUMPS_UNLOCKED = 1
const DASH_SPEED = 700
const DASH_TIME = 0.15

#Väggslide konstanter
const WALL_SLIDE_GRAVITY = 750
const WALL_SLIDE_PUSH = 200

const WALL_SLIDE_SPEED = 120
const WALL_JUMP_FORCE_X = 420
const WALL_JUMP_FORCE_Y = 650

#Spelarens state machine
enum {IDLE, WALK, JUMP, AIR, DEATH, ATTACK1, ATTACK2, HURT, WALL, DASH}

#Spelarens variabler
var state = IDLE
var jump_buffer = 0.0 #Buffert för hopp input
var coyote_timer = 0.0 #Kort tid efter kant
var pressed_jump: bool = false #Om spelaren har tryckt på hoppa
var attacking: bool = false
var attacking2: bool = false
var is_falling: bool = false
var can_special_attack: bool = true
var can_jump: bool = true
var health: int = 100
var can_take_damage: bool = true
var is_dead: bool = false
var wall_direction := 0 #-1 = vänster vägg och 1 = höger vägg
var double_jump_unlocked: bool = false
var jumps_left: int = 0
var dash_unlocked: bool = false
var dash_timer: float = 0.0
var dash_direction := 0
var can_dash = true

#Signalerar att spelaren är död
signal dead

#Referenser till spelarens noder, sprite, kollisioner, raycasts, timer
@onready var player: Sprite2D = $Sprite2D
@onready var anim: AnimationPlayer = $AnimationPlayer
@onready var specialattackcooldown: Timer = $Special_Attack_Cooldown
@onready var sword: CollisionShape2D = $Hitbox/SwordCollision
@onready var sword_up: CollisionShape2D = $Hitbox/SwordCollision2
@onready var sword_up_sides: CollisionShape2D = $Hitbox/SwordCollision3
@onready var hurt_timer: Timer = $HurtTimer
@onready var left_wall_lower_ray: RayCast2D = $LeftWallLower
@onready var right_wall_lower_ray: RayCast2D = $RightWallLower
@onready var left_wall_upper_ray: RayCast2D = $LeftWallUpper
@onready var right_wall_upper_ray: RayCast2D = $RightWallUpper
@onready var dash_cooldown: Timer = $DashCooldown
@onready var health_bar: ProgressBar = get_tree().get_current_scene().get_node("CanvasLayer/Control/HealthBar")
@onready var blink_timer: Timer = $BlinkTimer


func _physics_process(delta: float) -> void:
	#State machine, kallar olika states baserat på nuvarande tillstånd
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
		HURT:
			_hurt_state(delta)
		WALL:
			_wall_state(delta)
		DASH:
			_dash_state(delta)
	#print(state)

#Kontrollerar i början för att se om man har låst upp någon perk
func _ready():
	dash_unlocked = Globals.dash_unlocked
	double_jump_unlocked = Globals.double_jump_unlocked
	health = 100
	health_bar.value = health

##### GENERAL FUNCTIONS #####

func _movement(delta: float, input_x: float) -> void:
	#Horisontell rörelse med acceleration
	if input_x != 0:
		velocity.x = move_toward(velocity.x, input_x*MAXIMUM_SPEED, ACC*delta)
	else:
		velocity.x = move_toward(velocity.x, 0, ACC*delta)
	#Gravitation
	velocity.y += GRAVITY * delta
	#Snap till golv för smidighet
	if is_on_floor():
		apply_floor_snap()
	
	move_and_slide()
	
	#Nollställa hoppstatus om spelaren är på golvet
	if is_on_floor():
		jumps_left = EXTRA_JUMPS_UNLOCKED if double_jump_unlocked else EXTRA_JUMPS_LOCKED
		can_jump = true
		coyote_timer = 0.0

func _update_player_direction(input_x: float) -> void:
	#Speglar spelaren beroende på rörelseriktning
	if input_x > 0:
		player.flip_h = false
		sword.position = Vector2(35, 0)
		sword_up_sides.position = Vector2(35, -36)
	if input_x < 0:
		player.flip_h = true
		sword.position = Vector2(-35, 0)
		sword_up_sides.position = Vector2(-35, -36)

func _get_dash_direction(input_x: float) -> int:
	#Bestämmer dash riktning
	if input_x != 0:
		_update_player_direction(input_x)
		return sign(input_x)
	
	#Ifall man inte går så dashar man åt det håll man tittar
	return -1 if player.flip_h else 1

##### STATE FUNCTIONS #####

func _idle_state(delta: float) -> void:
	#Hanterar input och rörelse när spelaren står stilla
	if Input.is_action_just_pressed("jump"):
		_enter_jump_state(true)
	
	var input_x = Input.get_axis("left", "right")
	_update_player_direction(input_x)
	
	_movement(delta, input_x)
	
	#Om spelaren faller, byt till air state
	if velocity.y > 0:
		_enter_air_state(false)

	#Attack input
	if Input.is_action_just_pressed("attack"):
		_enter_attack1_state(true)
	
	if Input.is_action_just_pressed("specialattack") and can_special_attack:
		_enter_attack2_state(true)
	
	#Om spelaren börjar röra på sig, byt till walk state
	if velocity.length() > 0 and state != JUMP and is_on_floor():
		_enter_walk_state()
	#Dash input
	if Input.is_action_just_pressed("dash") and can_dash:
		dash_direction = _get_dash_direction(input_x)
		_enter_dash_state()
	
func _walk_state(delta: float) -> void:
	#Hanterar input och rörelse när spelaren går
	var input_x = Input.get_axis("left", "right")
	_movement(delta, input_x)
	_update_player_direction(input_x)
		
	#Övergång till andra states
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
		
	#Dash input
	if Input.is_action_just_pressed("dash") and can_dash:
		dash_direction = _get_dash_direction(input_x)
		_enter_dash_state()
	
func _jump_state(delta: float) -> void:
	#Jump state, hanterar jump buffer
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
	
	#Dash under hopp
	if Input.is_action_just_pressed("dash") and can_dash:
		dash_direction = _get_dash_direction(input_x)
		_enter_dash_state()
		return
	#Attack input
	if Input.is_action_just_pressed("attack"):
		_enter_attack1_state(true)
	if Input.is_action_just_pressed("specialattack") and can_special_attack:
		_enter_attack2_state(true)
	#Övergång till andra states
	elif not is_on_floor() and not pressed_jump and velocity.y > 0:
		_enter_air_state(true)
	elif is_on_floor() and pressed_jump:
		_enter_jump_state(true)
	elif is_on_floor() and velocity.length() == 0:
		_enter_idle_state()
	elif is_on_floor():
		_enter_walk_state()
	
func _air_state(delta: float) -> void:
	#Hanterar air state
	if state != AIR:
		coyote_timer = 0.0
	var input_x = Input.get_axis("left", "right")
	_movement(delta, input_x)
	_update_player_direction(input_x)
	
	#Om spelaren nuddar vägg, byt till wall state
	if is_on_wall() and not is_on_floor() and (Input.is_action_pressed("left") or Input.is_action_pressed("right")):
		_enter_wall_state()
		return
	
	#Coyote timer
	if not is_on_floor() and can_jump:
		coyote_timer += delta
		if coyote_timer > 0.2:
			can_jump = false
			coyote_timer = 0.0
	
	#Hopp input
	if Input.is_action_just_pressed("jump"):
		#För coyote jump
		if can_jump:
			_enter_jump_state(true)
			return
		#För dubbelhopp
		elif jumps_left > 0:
			_enter_jump_state(true)
			return
	#Om spelaren landar
	elif velocity.length() == 0:
		$JumpLandingSound.play()
		_enter_idle_state()
	elif velocity.length() != 0 and is_on_floor():
		$JumpLandingSound.play()
		_enter_walk_state()
	#Attack input
	elif Input.is_action_just_pressed("attack"):
		_enter_attack1_state(true)
	elif Input.is_action_just_pressed("specialattack") and can_special_attack:
		_enter_attack2_state(true)
	#Dash input
	if Input.is_action_just_pressed("dash") and can_dash:
		dash_direction = _get_dash_direction(input_x)
		_enter_dash_state()
	
func _death_state(delta: float) -> void:
	#Death state, ingen input, rör sig bara med gravitation
	_movement(delta, 0)
	
func _attack1_state(delta: float) -> void:
	var input_x = Input.get_axis("left", "right")
	_movement(delta, input_x)
	_update_player_direction(input_x)
	sword.set_deferred("disabled", false)
	
	#Hoppa under attack
	if Input.is_action_just_pressed("jump") and is_on_floor():
		sword.set_deferred("disabled", true)
		_enter_jump_state(true)
	
	if anim.is_playing(): #väntar på attackanimationen
		return
	
	sword.set_deferred("disabled", true)
	
	#Gå tillbaka till idle eller walk
	if velocity.length() == 0:
		_enter_idle_state()
	if velocity.length() != 0 and not anim.is_playing():
		_enter_walk_state()
	
func _attack2_state(delta: float) -> void: #Specialattack
	var input_x = Input.get_axis("left", "right")
	_movement(delta, input_x)
	_update_player_direction(input_x)
	#Aktivera alla olika attack hitbox (uppåt)
	sword.set_deferred("disabled", false)
	sword_up.set_deferred("disabled", false)
	sword_up_sides.set_deferred("disabled", false)
	#Hoppa under specialattack
	if Input.is_action_just_pressed("jump") and is_on_floor():
		sword.set_deferred("disabled", true)
		sword_up.set_deferred("disabled", true)
		sword_up_sides.set_deferred("disabled", true)
		_enter_jump_state(true)
		
	if anim.is_playing():
		return
	#Stäng av alla attack hitboxes när attacken är klar
	sword.set_deferred("disabled", true)
	sword_up.set_deferred("disabled", true)
	sword_up_sides.set_deferred("disabled", true)
	#Gå tillbaka till idle eller walk
	if velocity.length() == 0:
		_enter_idle_state()
	if velocity.length() != 0 and not anim.is_playing():
		_enter_walk_state()

func _hurt_state(delta: float) -> void:
	#Hanterar spelaren när den tar skada
	velocity.y += GRAVITY * delta #Gravitation när man tar skada
	move_and_slide()
	
	if not anim.is_playing(): #Hurt animationen är klar
		if is_on_floor():
			if velocity.x == 0:
				_enter_idle_state()
			else:
				_enter_walk_state()
		else:
			_enter_air_state(false)

func _wall_state(delta: float) -> void:
	#Hanterar vägg slide
	var input_x = Input.get_axis("left", "right")
	_update_player_direction(-wall_direction) #Rikta bort från väggen
	
	#Lämna väggen om den inte nuddas eller trycks mot den
	if not is_on_wall() and not left_wall_lower_ray.is_colliding() and not left_wall_upper_ray.is_colliding() and input_x != wall_direction or not is_on_wall() and not right_wall_lower_ray.is_colliding() and not right_wall_upper_ray.is_colliding() and input_x != wall_direction or not left_wall_lower_ray.is_colliding() and not left_wall_upper_ray.is_colliding() and not right_wall_lower_ray.is_colliding() and not right_wall_upper_ray.is_colliding():
		_enter_air_state(false)
		return

	#Kontrollerar wall slide hastighet
	velocity.y = min(velocity.y + WALL_SLIDE_GRAVITY * delta, WALL_SLIDE_SPEED)
	
	#Wall jump
	if Input.is_action_just_pressed("jump"):
		velocity.y = -WALL_JUMP_FORCE_Y
		velocity.x = -wall_direction * WALL_JUMP_FORCE_X
		$JumpSound.play()
		can_jump = false
		coyote_timer = 0.0
		
		jumps_left = EXTRA_JUMPS_UNLOCKED if double_jump_unlocked else EXTRA_JUMPS_LOCKED
		
		_enter_air_state(true)
		return
	
	#Om man landar på golv
	if is_on_floor():
		if abs(velocity.x) > 0:
			_enter_walk_state()
		else:
			_enter_idle_state()
		return
	
	move_and_slide()

func _dash_state(delta: float) -> void:
	#Hanterar dash
	dash_timer -= delta
	
	velocity.y = 0
	velocity.x = DASH_SPEED * dash_direction
	move_and_slide()
	
	#När dash är klar, gå till air eller idle state
	if dash_timer <= 0:
		if is_on_floor():
			_enter_idle_state()
		else:
			_enter_air_state(false)

##### ENTER STATE FUNCTION #####
#Spelaren går in i olika states och animationer börjar spelas
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
	$JumpSound.play()
	
	#Använder extrahoppet endast om man inte använder coyote
	if not can_jump:
		if jumps_left <= 0:
			return
		jumps_left -= 1
	
	can_jump = false
	coyote_timer = 0.0
	
	if jumping:
		velocity.y = -JUMP_VELOCITY

func _enter_air_state(jump):
	state = AIR
	anim.play("fall")
	is_falling = true

func _enter_death_state():
	state = DEATH
	anim.play("death")
	$DeathSound.play()
	
	#Avsluta blinkningen
	can_take_damage = true
	blink_timer.stop()
	player.visible = true
	
	if not is_dead:
		is_dead = true
		anim.play("fall")
		$PlayerCollision.set_deferred("disabled", true)
		$RemoteTransform2D.remote_path = ""
		
		#Rotation animation för död
		var tween = get_tree().create_tween()
		tween.tween_property(self, "rotation", rotation + PI, 0.67)

func _enter_attack1_state(attacking: bool):
	state = ATTACK1
	anim.play("attack2")
	attacking = true
	$SwordSound.play()
	
func _enter_attack2_state(attacking2: bool):
	if can_special_attack:
		can_special_attack = false
		state = ATTACK2
		anim.play("attack3")
		$SpecialAttackSound.play()
		attacking2 = true
		specialattackcooldown.start()
		
func _enter_hurt_state(from_position):
	state = HURT
	anim.play("hurt")
	$HurtSound.play()
	
	#Stäng av alla hitboxes
	sword.set_deferred("disabled", true)
	sword_up.set_deferred("disabled", true)
	sword_up_sides.set_deferred("disabled", true)
	
	if from_position != null:
		apply_knockback(from_position)
	
	can_take_damage = false
	hurt_timer.start()
	blink_timer.start()

func _enter_wall_state():
	if state == WALL:
		return
	
	state = WALL
	anim.play("wall_slide")
	wall_direction = -get_wall_normal().x
	velocity.x = 0
	
	jumps_left = EXTRA_JUMPS_UNLOCKED if double_jump_unlocked else EXTRA_JUMPS_LOCKED

func _enter_dash_state():
	if not dash_unlocked:
		return
	
	state = DASH
	anim.play("dash")
	dash_timer = DASH_TIME
	can_dash = false
	dash_cooldown.start()
	
	velocity.y = 0
	velocity.x = dash_direction * DASH_SPEED
	
#### DAMAGE AND KNOCKBACK FUNCTIONS ####
func apply_damage(amount: int, from_position):
	if not can_take_damage:
		return
	
	#Minska hp och uppdatera health bar
	if can_take_damage:
		health -= amount
		health = clamp(health, 0, 100)
		health_bar.value = health #Uppdaterar health bar
		_enter_hurt_state(from_position)
		#Skakning av kameran
		var camera = get_tree().get_current_scene().get_node("Camera2D")
		if camera:
			camera.shake(10)

	if health <= 0:
		_enter_death_state()

func apply_knockback(from_position: Vector2):
	#Knuffar spelaren bort från skadekälla
	var knockback_direction = (global_position - from_position).normalized()
	velocity.x = knockback_direction.x * KNOCKBACK
	velocity.y = -200

#### SIGNALS ####
func _on_special_attack_cooldown_timeout() -> void:
	can_special_attack = true
	
func _on_hitbox_body_entered(body: Node2D) -> void:
	#När hitbox träffar en fiende
	if body is Enemy or body is Boss or body is Skeleton:
		body.apply_damage(DAMAGE, global_position)

func _on_hurt_timer_timeout() -> void:
	can_take_damage = true
	player.visible = true
	blink_timer.stop()

func _on_visible_on_screen_notifier_2d_screen_exited() -> void:
	#Om spelaren lämnar skärmen, då dör man
	emit_signal("dead")
	queue_free()

func _on_dash_cooldown_timeout() -> void:
	can_dash = true

func _on_blink_timer_timeout() -> void:
	#Blink effekt när spelaren tar skada
	player.visible = !player.visible
