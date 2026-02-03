extends Camera2D

var shake_amount: float = 0.0
var shake_decay: float = 20.0
var original_offset: Vector2 = Vector2.ZERO

func _ready():
	original_offset = offset

func shake(intensity: float):
	shake_amount = intensity

func _process(delta):
	if shake_amount > 0:
		offset = original_offset + Vector2(randf_range(-shake_amount, shake_amount), randf_range(-shake_amount, shake_amount))
		shake_amount = max(shake_amount - shake_decay * delta, 0)
	else:
		offset = original_offset
