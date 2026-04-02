extends CanvasLayer

signal return_pressed

@onready var VictoryMenuMusic: AudioStreamPlayer = $VictoryMenuMusic

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	hide()


func _on_return_button_pressed() -> void:
	return_pressed.emit()
