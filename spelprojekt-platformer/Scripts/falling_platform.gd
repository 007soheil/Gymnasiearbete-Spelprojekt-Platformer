extends Node2D

#Referenser till plattformens sprite, kollision och timer för fall
@onready var platform: Sprite2D = $StaticBody2D/Sprite2D
@onready var collision: CollisionShape2D = $StaticBody2D/CollisionShape2D
@onready var fall_timer: Timer = $StaticBody2D/FallTimer

#Kontrollerar ifall den redan skakar
var shaking: bool = false

func _on_area_2d_body_entered(body: Node2D) -> void:
	#När spelaren går på plattformen och den redan inte skakar
	if body is Player and not shaking:
		shaking = true #Markera att plattformen skakar
		fall_timer.start() #Starta timer för fall
		start_shake() #Starta skak animation

func start_shake():
	#Skapa en tween för att skaka plattformen fram och tillbaka
	var tween = create_tween()
	tween.set_loops(10) #Antal gånger plattformen skakar
	tween.tween_property(platform, "position:x", platform.position.x + 2, 0.05)
	tween.tween_property(platform, "position:x", platform.position.x - 2, 0.05)

func _on_fall_timer_timeout() -> void:
	#Tid löper ut, plattform faller
	var tween = create_tween()
	tween.tween_property(self, "position:y", position.y + 2000, 5) #Fallanimation
	collision.disabled = true #Kollision stängs av så att spelaren faller igenom
