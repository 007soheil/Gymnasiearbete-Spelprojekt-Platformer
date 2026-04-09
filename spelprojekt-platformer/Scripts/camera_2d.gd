extends Camera2D

#Hur stark skakningen är just nu
var shake_amount: float = 0.0
#Hur snabbt skakningen avtar
var shake_decay: float = 20.0
#Kamerans ursprungliga offset för återställning
var original_offset: Vector2 = Vector2.ZERO

func _ready():
	#Spara start-offset så man kan återgå efter skakning
	original_offset = offset

func shake(intensity: float):
	#Starta en skakning med given styrka
	shake_amount = intensity

func _process(delta):
	if shake_amount > 0:
		#Flytta kameran slumpmässigt inom ett intervall för att skapa skakning
		offset = original_offset + Vector2(randf_range(-shake_amount, shake_amount), randf_range(-shake_amount, shake_amount))
		shake_amount = max(shake_amount - shake_decay * delta, 0) #Minska skakningen över tid
	else:
		#Återställ kameran när skakning är klar
		offset = original_offset
