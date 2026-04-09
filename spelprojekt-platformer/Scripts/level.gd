extends Node2D

#Konstanter för sparfil och spelarscen
const SAVE_PATH = "user://adventureplatformer_savefile.data"
const PLAYER_SCENE = preload("res://Scenes/Player.tscn")

#Referenser till noder
@onready var player: Player = $Player
@onready var camera: Camera2D = $Camera2D
@onready var time_label: Label = $HUD/TimeLabel
@onready var hearts_container: HBoxContainer = $HUD/HeartsContainer
@onready var highscore_label: Label = $HUD/HighscoreLabel
@onready var coincounter_label: Label = $HUD/CoinCounter

#Referenser till collectibles
@onready var coin: Area2D = $Coin
@onready var blue_gem: Area2D = $BlueGem
@onready var coin_cointainer: Node2D = $Coins
@onready var yellow_gem: Area2D = $YellowGem
@onready var gray_gem: Area2D = $GrayGem
@onready var green_gem: Area2D = $GreenGem
@onready var red_gem: Area2D = $RedGem

#Variabler för leveln
var time: float = 0.0
var level_completed: bool = false
var high_scores: Dictionary = {}
var boss_dead: bool = false

@export var level = 1


func _ready() -> void:
	#reset_highscores() #Nollställa Highscores
	
	_get_highscores()
	
	#Musik
	$MainMenu.MainMenuMusic.stop()
	$BackgroundMusic.play()
	
	#Koppla kamera till spelaren
	player.get_node("RemoteTransform2D").remote_path = camera.get_path()
	
	#Koppla dödssignal till funktion
	player.connect("dead", _on_player_dead)
	
	#Koppla alla mynt till funktion
	for child in coin_cointainer.get_children():
		child.connect("pickup", _on_coin_pickup)
	
	#Koppla alla ädelstenar till funktion
	blue_gem.connect("pickup", _on_gem_pickup)
	yellow_gem.connect("pickup", _on_gem_pickup)
	gray_gem.connect("pickup", _on_gem_pickup)
	green_gem.connect("pickup", _on_gem_pickup)
	red_gem.connect("pickup", _on_gem_pickup)
	
	#Boss level, leder till att ädelstenen visas vid boss död
	if has_node("Boss"):
		for node in get_children():
			if "Gem" in node.name:
				$Boss.boss_dead.connect(node._boss_dead)
	
	#Knappsignaler
	$VictoryMenu.advance_pressed.connect(_on_victory_advance)
	$FinalVictoryMenu.return_pressed.connect(_on_victory_return)
	
	#Ädelstenen till sista leveln
	$RedGem.monitoring = false
	$RedGem.hide()
	
	#Om det är sista leveln så byts musiken till en speciell
	if level == 5:
		$BackgroundMusic.stop()
		$BossBattleMusic.play()
	
	_update_heart_amount()
	
	#Svårighet och level för highscores och visa dem
	var diff_key = _difficulty_to_string(Globals.difficulty)
	var level_name = "Level" + str(level)
	#Kollar om highscore finns på olika levels och svårighetsgrader, annars ingen best time
	if high_scores.has(level_name):
		if high_scores.has(level_name) and high_scores[level_name].has(diff_key):
			var best_time = high_scores[level_name][diff_key]
			if best_time != INF: #INF gör så att det "inte finns" ett rekord
				var time_string = _from_seconds_to_time(best_time)
				highscore_label.text = "Best time (" + diff_key.capitalize() + "): " + time_string
		else:
			highscore_label.text = ""
	else:
		highscore_label.text = ""

	#print(high_scores)

func _process(delta: float) -> void:
	#Timer fortsätter om leveln inte avklarats
	if not level_completed:
		time += delta
		
		var time_string = _from_seconds_to_time(time) #Omvandlar tid till rätt format
		time_label.text = "Time: " + time_string #Aktuella tiden
		#Antal mynt samlade
		coincounter_label.text = str(Globals.coins)

func _on_player_dead() -> void: #Spelaren dör
	if get_tree().paused:
		return #Ignorerar död ifall man har pausat eller startar om spelet
	
	#Tappar ett liv och uppdaterar hjärtan
	Globals.lives -= 1
	_update_heart_amount()
	
	#Respawnar om man har liv kvar
	if Globals.lives > 0:
		player = PLAYER_SCENE.instantiate()
		player.global_position = $PlayerSpawnPosition.global_position
		add_child(player)
		#Koppla nya spelaren till kamera och dödssignal
		player.get_node("RemoteTransform2D").remote_path = camera.get_path()
		player.connect("dead", _on_player_dead)
	else: #Game over annars
		$GameOverMenu.visible = true
		$GameOverMenu.GameOverMenuMusic.play()
		$BackgroundMusic.stop()

#### PICKUP FUNCTIONS ####
func _on_coin_pickup(): #Räknar mynt vid samling
	Globals.coins += 1
	
func _on_gem_pickup() -> void: #Avklarad nivå vid uppplockning av ädelsten
	level_completed = true
	
	coincounter_label.visible = false
	
	#LevelManager.change_to_victory_menu()
	#Victory skräm vid vinst
	if level < 5:
		$VictoryMenu.visible = true
		$VictoryMenu.VictoryMenuMusic.play()
		$BackgroundMusic.stop()
		get_tree().paused = true
	#Speciell victory skärm vid vinst av sista nivån
	if level == 5:
		$FinalVictoryMenu.visible = true
		$VictoryMenu.VictoryMenuMusic.play()
		$BackgroundMusic.stop()
		get_tree().paused = true
	
	#LevelManager.change_to_next_level(level)
	
	#Spara highscore
	var level_name = "Level" + str(level)
	_save_highscore(level_name)

func _get_highscores() -> void: #Hämtar highscores
	if FileAccess.file_exists(SAVE_PATH):
		var file = FileAccess.open(SAVE_PATH, FileAccess.READ) #Öppnar fil för läsning
		high_scores = file.get_var() #Laddar dictionary med highscores från filen
		file.close()
	
	#Se till att varje level har alla difficulty keys, saknar difficulty, sätts till INF (ingen highscore)
	for level_name in high_scores.keys():
		for diff in ["easy", "normal", "hard"]:
			if not high_scores[level_name].has(diff):
				high_scores[level_name][diff] = INF #INF = oändlig (ingen highscore)
				
	#Se till att alla levels 1-5 finns i dictionaryn
	for i in range(1, 6):
		var level_name = "Level" + str(i)
		if not high_scores.has(level_name):
			high_scores[level_name] = {
				"easy": INF,
				"normal": INF,
				"hard": INF
			}

func _save_highscore(level_name: String) -> void: #Spara highscore till filen
	#Om level inte finns ännu, skapa en ny tom/förifylld dictionary så att värden kan sparas i den
	if not high_scores.has(level_name):
		high_scores[level_name] = {
			"easy": INF,
			"normal": INF,
			"hard": INF
		}
	
	var diff_key = _difficulty_to_string(Globals.difficulty)
	
	#Ersätt bara om den nya tiden är bättre
	if time < high_scores[level_name][diff_key]:
		high_scores[level_name][diff_key] = time
	
	#Skriv tillbaka hela dictionaryn till fil
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	file.store_var(high_scores)
	file.close()

func _update_heart_amount() -> void:
	var lives_lost = 3 -Globals.lives #Max liv är 3
	var deactivated_hearts = 0
	for child in hearts_container.get_children():
		if deactivated_hearts < lives_lost:
			child.hide() #Dölj förlorade hjärtan
			deactivated_hearts += 1

func _from_seconds_to_time(seconds: float) -> String: #Omvandlar sekunder till mm:ss
	var min = int(seconds / 60)
	var sec = int(seconds - min*60)
	return "%02d:%02d" % [min, sec]

func _on_victory_advance():
	#Byt till nästa level vid fortsättning till nästa nivå
	get_tree().paused = false #Återupptar spel från paus
	LevelManager.change_to_next_level(level) #Växlar nivå
	$VictoryMenu.VictoryMenuMusic.stop() #Stoppar musik
	
func _on_victory_return(): #Från vinst vid level 5 till main meny
	get_tree().paused = false #Återupptar spelet
	$VictoryMenu.VictoryMenuMusic.stop() #Stoppar musik
	LevelManager.change_to_main_menu() #Byter till main meny
	level = 1 #Startar om från level 1

func _difficulty_to_string(diff: Globals.Difficulty) -> String: #Omvandlar global difficulty till string
	match diff:
		Globals.Difficulty.EASY: return "easy"
		Globals.Difficulty.NORMAL: return "normal"
		Globals.Difficulty.HARD: return "hard"
	return "easy" #Ifall något går fel

func reset_highscores(): #Nollställer highscore
	var file = FileAccess.open("user://adventureplatformer_savefile.data", FileAccess.WRITE)
	file.store_var({}) #ersätta filen med ett tomt dictionary
	file.close()
	
	high_scores.clear() #Rensar i minnet också
