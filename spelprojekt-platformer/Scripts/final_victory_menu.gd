extends CanvasLayer

#Signal som skickas när spelaren trycker på return knappen
signal return_pressed
#Refererar till ljudspelare för Victory-skärmen
@onready var VictoryMenuMusic: AudioStreamPlayer = $VictoryMenuMusic

func _ready():
	#Gör att scenen fortfarande processas även om spelet pausas
	process_mode = Node.PROCESS_MODE_ALWAYS
	#Gömmer final victory screen tills den ska visas
	hide()


func _on_return_button_pressed() -> void:
	#Skickar signal till leveln att return knappen har tryckts
	return_pressed.emit()
