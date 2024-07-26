extends Node2D

var _opened: bool = false
@export var next_scene: String


func _on_area_2d_body_entered(body: Node2D):
	if body is Player and _opened:
		# Change scene
		Bhleg.change_scene(next_scene)
		pass


func _unlock_keyhole():
	_opened = true
	if $AnimatedSprite2D:
		$AnimatedSprite2D.animation = "open"
