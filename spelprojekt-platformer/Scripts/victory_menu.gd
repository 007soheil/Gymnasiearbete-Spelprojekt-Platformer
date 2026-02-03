extends CanvasLayer

signal advance_pressed

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	hide()



func _on_advance_button_pressed() -> void:
	advance_pressed.emit()


func _on_perk_upgrade_button_pressed() -> void:
	pass # Replace with function body.


func _on_perk_upgrade_button_2_pressed() -> void:
	pass # Replace with function body.
