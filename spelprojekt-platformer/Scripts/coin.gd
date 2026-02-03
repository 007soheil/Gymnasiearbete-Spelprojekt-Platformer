extends Area2D

class_name Coin

signal pickup

var is_collected: bool = false

func _ready() -> void:
	$AnimationPlayer.play("coin_animation")

func _on_body_entered(body: Node2D) -> void:
	if is_collected:
		return
	if body is Player:
		emit_signal("pickup")
		$AnimationPlayer.play("pickup")
		await $AnimationPlayer.animation_finished
		queue_free()
