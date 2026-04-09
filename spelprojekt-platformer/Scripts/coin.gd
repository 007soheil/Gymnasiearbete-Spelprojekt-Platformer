extends Area2D

class_name Coin
#Signal som skickar när myntet plockas upp
signal pickup
#Variabel som anger om myntet har plockats upp
var is_collected: bool = false

func _ready() -> void:
	#Sätter igång animationen när spelet startas
	$AnimationPlayer.play("coin_animation")

func _on_body_entered(body: Node2D) -> void:
	#Inget händer om myntet har plockats upp
	if is_collected:
		return
	if body is Player: #Om spelaren plockar upp myntet
		#Ljud spelas upp
		$CoinPickup.play()
		#Kollisionen stängs av
		$CollisionShape2D.set_deferred("disabled", true)
		#Signal skickas att den har plockats upp
		emit_signal("pickup")
		#Pickup animation spelas
		$AnimationPlayer.play("pickup")
		#Väntar på animation
		await $AnimationPlayer.animation_finished
		#Tar bort mynt från scenen
		queue_free()
