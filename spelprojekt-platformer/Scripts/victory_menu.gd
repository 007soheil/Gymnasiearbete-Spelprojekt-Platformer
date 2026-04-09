extends CanvasLayer

#Signal som skickas när spelaren vill gå vidare till nästa nivå
signal advance_pressed

#Refererar till UI-element
@onready var coinamount_label: Label = $CoinAmount
@onready var VictoryMenuMusic: AudioStreamPlayer = $VictoryMenuMusic

func _ready():
	#Gör att scenen fortfarande processas även om spelet pausas
	process_mode = Node.PROCESS_MODE_ALWAYS
	#Gömmer victory screen tills den ska visas
	hide()
	#Uppdatera knapparnas status beroende på redan upplåsta/köpta perks
	if Globals.dash_unlocked:
		$PerkUpgradeButton.disabled = true
		$PerkUpgradeButton.text = "Unlocked!"
	
	if Globals.double_jump_unlocked:
		$PerkUpgradeButton2.disabled = true
		$PerkUpgradeButton2.text = "Unlocked!"

func _physics_process(delta: float) -> void: 
	#Uppdaterar mängden coins hela tiden
	coinamount_label.text = str(Globals.coins)


func _on_advance_button_pressed() -> void: 
	#Skickar signal till level att advance har tryckts
	advance_pressed.emit()


func _on_perk_upgrade_button_pressed() -> void:
	#Inget händer ifall spelaren redan har perk
	if Globals.dash_unlocked:
		return
	#Inget händer ifall spelaren inte har råd med perk
	if Globals.coins < 10:
		return
	#Låser upp dash perk
	$UpgradeSound.play()
	Globals.coins -= 10
	Globals.dash_unlocked = true
	#Uppdaterar knappens utseende
	$PerkUpgradeButton.disabled = true
	$PerkUpgradeButton.text = "Unlocked!"

func _on_perk_upgrade_button_2_pressed() -> void:
	#Inget händer ifall spelaren redan har perk
	if Globals.double_jump_unlocked:
		return
	#Inget händer ifall spelaren inte har råd med perk
	if Globals.coins < 15:
		return
	#Låser upp double jump perk
	$UpgradeSound.play()
	Globals.coins -= 15
	Globals.double_jump_unlocked = true
	#Uppdaterar knappens utseende
	$PerkUpgradeButton2.disabled = true
	$PerkUpgradeButton2.text = "Unlocked!"
