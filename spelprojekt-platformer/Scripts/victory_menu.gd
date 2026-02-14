extends CanvasLayer

signal advance_pressed

@onready var coinamount_label: Label = $CoinAmount
@onready var VictoryMenuMusic: AudioStreamPlayer = $VictoryMenuMusic

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	hide()
	
	if Globals.dash_unlocked:
		$PerkUpgradeButton.disabled = true
		$PerkUpgradeButton.text = "Unlocked!"
	if Globals.double_jump_unlocked:
		$PerkUpgradeButton2.disabled = true
		$PerkUpgradeButton2.text = "Unlocked!"

func _physics_process(delta: float) -> void:
	coinamount_label.text = str(Globals.coins)


func _on_advance_button_pressed() -> void:
	advance_pressed.emit()


func _on_perk_upgrade_button_pressed() -> void:
	if Globals.dash_unlocked:
		return
	
	if Globals.coins < 10:
		return
	
	$UpgradeSound.play()
	Globals.coins -= 10
	Globals.dash_unlocked = true

	$PerkUpgradeButton.disabled = true
	$PerkUpgradeButton.text = "Unlocked!"

func _on_perk_upgrade_button_2_pressed() -> void:
	if Globals.double_jump_unlocked:
		return
	
	if Globals.coins < 15:
		return
	
	$UpgradeSound.play()
	Globals.coins -= 15
	Globals.double_jump_unlocked = true
	
	$PerkUpgradeButton2.disabled = true
	$PerkUpgradeButton2.text = "Unlocked!"
