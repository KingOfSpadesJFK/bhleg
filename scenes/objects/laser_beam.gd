extends Node2D

var speed: float = 3000.0


func _physics_process(delta):
	position += Vector2(cos(rotation), sin(rotation)) * speed * delta
