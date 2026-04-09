extends Area2D

signal pickup #Signal som skickas när spelaren plockar upp ädelstenen

var is_collected: bool = false #Variabel som kontrollerar om ädelstenen plockas upp

func _ready() -> void: #Sätter igång animationen för ädelstenen när spelet startas
	$AnimationPlayer.play("gem_animation")

func _on_body_entered(body: Node2D) -> void: #Funktion för när spelaren nuddar ädelstenen
	if is_collected: #Inget händer om den redan har plockats upp
		return
	if body is Player: #Kontrollerar att det är spelaren som kolliderar
		emit_signal("pickup") #Skickar signal när den har plockats upp
		$AnimationPlayer.play("pickup") #Spelar animation
		await $AnimationPlayer.animation_finished #Vänta på animation
		queue_free() #Ta bort ädelstenen från scenen

func _boss_dead(): #Om bossen är död så visas den sista ädelstenen och arean sätts på
	show()
	monitoring = true
