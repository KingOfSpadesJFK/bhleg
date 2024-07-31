extends Node2D

var _laser_beam: PackedScene = preload("res://scenes/objects/laser_beam.tscn")
var hit: bool = false
@export_enum("White", "Red", "Cyan") var type: int = 0


func _ready():
	match type:
		0:
			$Overlay.modulate = Color.WHITE
		1:
			$Overlay.modulate = Color.html("#e04500")
		2:
			$Overlay.modulate = Color.html("#00c9ff")


func _physics_process(_delta):
	if hit:
		$FlashLight.flash_light(type == 1)
		hit = false


func _on_hit_box_hit():
	if type == 2:
		var b = _laser_beam.instantiate()
		b.position = $BeamPoint.global_position
		b.rotation = global_rotation
		add_sibling(b)
	else:
		hit = true
