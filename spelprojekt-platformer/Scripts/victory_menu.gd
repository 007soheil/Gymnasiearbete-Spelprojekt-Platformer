extends CanvasLayer

signal advance_pressed

@onready var coinamount_label: Label = $CoinAmount

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	hide()
	
func coin():
	coinamount_label.text = str(Globals.coins)



func _on_advance_button_pressed() -> void:
	advance_pressed.emit()


func _on_perk_upgrade_button_pressed() -> void:
	if Globals.coins >= 10:
		Globals.coins - 10
	pass


func _on_perk_upgrade_button_2_pressed() -> void:
	if Globals.coins >= 15:
		Globals.coins - 15
	pass
