extends Node2D

const SAVE_PATH = "user://adventureplatformer_savefile.data"
const PLAYER_SCENE = preload("res://Scenes/Player.tscn")


@onready var player: Player = $Player
@onready var camera: Camera2D = $Camera2D
@onready var time_label: Label = $HUD/TimeLabel
@onready var hearts_container: HBoxContainer = $HUD/HeartsContainer
@onready var highscore_label: Label = $HUD/HighscoreLabel
@onready var coincounter_label: Label = $HUD/CoinCounter
@onready var coin: Area2D = $Coin
@onready var blue_gem: Area2D = $BlueGem
@onready var coin_cointainer: Node2D = $Coins
@onready var yellow_gem: Area2D = $YellowGem
@onready var gray_gem: Area2D = $GrayGem
@onready var green_gem: Area2D = $GreenGem
@onready var red_gem: Area2D = $RedGem


var time: float = 0.0
var level_completed: bool = false
var high_scores: Dictionary = {}

@export var level = 1

func _ready() -> void:
	$MainMenu.MainMenuMusic.stop()
	$BackgroundMusic.play()
	_save_highscore(name)
	player.get_node("RemoteTransform2D").remote_path = camera.get_path()
	player.connect("dead", _on_player_dead)
	for child in coin_cointainer.get_children():
		child.connect("pickup", _on_coin_pickup)
	blue_gem.connect("pickup", _on_gem_pickup)
	yellow_gem.connect("pickup", _on_gem_pickup)
	gray_gem.connect("pickup", _on_gem_pickup)
	green_gem.connect("pickup", _on_gem_pickup)
	red_gem.connect("pickup", _on_gem_pickup)
	$VictoryMenu.advance_pressed.connect(_on_victory_advance)
	
	_update_heart_amount()
	if name in high_scores:
		var time_string = _from_seconds_to_time(high_scores[name])
		highscore_label.text = "Best time: " + time_string
	else:
		highscore_label.text = ""
	
	print(high_scores)
	

func _process(delta: float) -> void:
	if not level_completed:
		time += delta
		
		var time_string = _from_seconds_to_time(time)
		time_label.text = "Time: " + time_string
		
		coincounter_label.text = str(Globals.coins)

func _on_player_dead() -> void:
	Globals.lives -= 1
	_update_heart_amount()
	if Globals.lives > 0:
		player = PLAYER_SCENE.instantiate()
		player.global_position = $PlayerSpawnPosition.global_position
		add_child(player)
		player.get_node("RemoteTransform2D").remote_path = camera.get_path()
		player.connect("dead", _on_player_dead)
	else:
		$GameOverMenu.visible = true
		$GameOverMenu.GameOverMenuMusic.play()
		$BackgroundMusic.stop()


func _on_coin_pickup():
	Globals.coins += 1
	
func _on_gem_pickup() -> void:
	level_completed = true
	
	coincounter_label.visible = false
	
	#LevelManager.change_to_victory_menu()
	
	$VictoryMenu.visible = true
	$VictoryMenu.VictoryMenuMusic.play()
	$BackgroundMusic.stop()
	get_tree().paused = true
	
	#LevelManager.change_to_next_level(level)
	
	if name in high_scores:
		#Det finns ett befintligt highscore
		if time < high_scores[name]:
			_save_highscore(name)
	else:
		#Om det inte finns ett innebär det att leveln klaras för första gången
		_save_highscore(name)

func _get_highscores() -> void:
	if FileAccess.file_exists(SAVE_PATH):
		var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
		high_scores = file.get_var() #Sparade variabeln räknas
		file.close()

func _save_highscore(level_name: String) -> void:
	high_scores[level_name] = time #Värdet ändras om det finns, annars läggs det till
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE) #Finns inte filen skapas den
	#high_scores = {}
	file.store_var(high_scores)
	file.close()

func _update_heart_amount() -> void:
	var lives_lost = 3 -Globals.lives
	var deactivated_hearts = 0
	for child in hearts_container.get_children():
		if deactivated_hearts < lives_lost:
			child.hide()
			deactivated_hearts += 1


func _from_seconds_to_time(seconds: float) -> String:
	var min = int(seconds / 60)
	var sec = int(seconds - min*60)
	return "%02d:%02d" % [min, sec]


func _on_victory_advance():
	get_tree().paused = false
	LevelManager.change_to_next_level(level)
	$VictoryMenu.VictoryMenuMusic.stop()
