extends Node2D

var speed: float = 1500.0


func _physics_process(delta):
	position += Vector2(cos(rotation), sin(rotation)) * speed * delta


func _on_hurtbox_destroyed():
	$Line2D.queue_free()
	$CPUParticles2D.emitting = false
	await $CPUParticles2D.finished
	queue_free()


func _on_lifetime_timeout():
	_on_hurtbox_destroyed()
