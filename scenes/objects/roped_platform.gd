extends Node2D

var _segment = SegmentShape2D.new()
@onready var _spring_joint: DampedSpringJoint2D = $DampedSpringJoint2D
@onready var _line: Line2D = $Rope
@onready var _line_outline: Line2D = $RopeOutline

@export var length: float = 50.0 : 
	get:
		return length
	set(val):
		if _spring_joint:
			_spring_joint.length = val
		length = val

@export var rest_length: float = 0.0 :
	get:
		return rest_length
	set(val):
		if _spring_joint:
			_spring_joint.rest_length = val
		rest_length = val

@export var stiffness: float = 0.0 :
	get:
		return stiffness
	set(val):
		if _spring_joint:
			_spring_joint.stiffness = val
		stiffness = val
@export var damping: float = 0.0

@export var physics_object: PhysicsBody2D


func _enter_tree():
	var col_shape: CollisionShape2D = CollisionShape2D.new()
	col_shape.shape = _segment
	$HitBox.add_child(col_shape)
	length = length


# Called when the node enters the scene tree for the first time.
func _ready():
	_spring_joint.node_b = physics_object.get_path()
	_spring_joint.length = length

	if _line && _line_outline:
		var verts: Array[Vector2] = [$Anchor.position, to_local(physics_object.global_position)]
		_line.points = PackedVector2Array(verts)
		_line_outline.points = PackedVector2Array(verts)


func _process(_delta):
	if _line && _line_outline:
		var verts: Array[Vector2] = [$Anchor.position, to_local(physics_object.global_position)]
		_line.points = PackedVector2Array(verts)
		_line_outline.points = PackedVector2Array(verts)
		


func _phyisics_process(_delta):
	if _spring_joint:
		_segment.a = $Anchor.position
		_segment.b = to_local(physics_object.global_position)


# Cut the work
func _on_hit_box_hit():
	if _spring_joint:
		_spring_joint.queue_free()
		_spring_joint = null
		_line.queue_free()
		_line = null
		_line_outline.queue_free()
		_line_outline = null
		$HitBox.queue_free()
