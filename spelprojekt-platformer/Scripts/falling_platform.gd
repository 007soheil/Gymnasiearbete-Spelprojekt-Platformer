extends Node2D

@onready var platform: Sprite2D = $StaticBody2D/Sprite2D
@onready var collision: CollisionShape2D = $StaticBody2D/CollisionShape2D
@onready var fall_timer: Timer = $StaticBody2D/FallTimer

var shaking: bool = false

func _on_area_2d_body_entered(body: Node2D) -> void:
	if body is Player and not shaking:
		shaking = true
		fall_timer.start()
		start_shake()

func start_shake():
	var tween = create_tween()
	tween.set_loops(10)
	tween.tween_property(platform, "position:x", platform.position.x + 2, 0.05)
	tween.tween_property(platform, "position:x", platform.position.x - 2, 0.05)

func _on_fall_timer_timeout() -> void:
	var tween = create_tween()
	tween.tween_property(self, "position:y", position.y + 2000, 5)
	collision.disabled = true
