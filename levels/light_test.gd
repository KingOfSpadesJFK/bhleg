extends Node2D

@export var _polygon2D: Polygon2D
@export var _shadow_bodies: LightBody
@export var _red_light: RedLightBody
var _polygon: PackedVector2Array


# Called when the node enters the scene tree for the first time.
func _ready():
	_polygon = _polygon2D.polygon.duplicate()
	pass # Replace with function body.


func _input(event):
	if event is InputEventMouse:
		var p = _offset(_polygon, event.position)
		if event.is_action_pressed("player_flash"):
			_shadow_bodies.add_polygon(p, Bhleg.calculate_bounding_box(p))
			_red_light.subtract_polygon(p, Bhleg.calculate_bounding_box(p))
		if event.is_action_pressed("debug_red_flash"):
			_shadow_bodies.add_polygon(p, Bhleg.calculate_bounding_box(p))
			_red_light.add_polygon(p, Bhleg.calculate_bounding_box(p))
		pass
	pass
	

func _offset(poly: PackedVector2Array, offset: Vector2) -> PackedVector2Array:
	var new_p: Array[Vector2] = []
	for v: Vector2 in poly:
		new_p.append(v+offset)
		
	return PackedVector2Array(new_p)
