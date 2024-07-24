extends CharacterBody2D
class_name Player


const SPEED = 200.0
const JUMP_VELOCITY = -400.0
const FLASH_RAY_LENGTH = 1000.0
const FLASH_SPREAD = 90.0			# How wide the area of flash should be (in degrees)
const FLASH_SAMPLES = 50

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

# The static body to draw over
@export var shadow_body: ShadowBody

var _do_flash: bool = false
var _flash_angle: float
var _flash_markers: Node
@onready var _camera: Camera2D = $Camera2D


func _physics_process(delta):
	# Add the gravity.
	if not is_on_floor():
		velocity.y += gravity * delta

	# Handle jump.
	if Input.is_action_just_pressed("player_jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var direction = Input.get_axis("player_left", "player_right")
	if direction:
		velocity.x = direction * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)

	move_and_slide()

	# Do flash routine 
	#  MUST BE DONE IN _physics_step()!!!
	if _do_flash:
		_flash_light()


func _flash_light():
	# Debugging markers
	if _flash_markers:
		_flash_markers.queue_free()
	_flash_markers = Node.new()
	add_child(_flash_markers)

	# Initialize the new polygon
	var verts: Array[Vector2] = []

	# Initialize the raycasting
	var space_state = get_world_2d().direct_space_state
	var step: float = deg_to_rad(FLASH_SPREAD / FLASH_SAMPLES)
	var angle: float = deg_to_rad(_flash_angle - FLASH_SPREAD / 2.0)

	# Initial starting ray cast
	var dir = Vector2(cos(angle), sin(angle))	# Convert the current angle to a normal vector
	var query = PhysicsRayQueryParameters2D.create(global_position, dir * FLASH_RAY_LENGTH)
	query.collision_mask = 4
	var shad_result = space_state.intersect_ray(query)
	if shad_result:
		verts.append(shad_result.position)
	else:
		verts.append(global_position)

	# Raycast the samples
	var prev_pos = verts[0]
	var prev_dir = Vector2(0,0)
	for i in range(FLASH_SAMPLES):
		# Raycast
		dir = Vector2(cos(angle), sin(angle))	# Convert the current angle to a normal vector
		query.to = dir * FLASH_RAY_LENGTH
		query.collision_mask = 1					# This first ray query will check for layer 1 (the environment)
		var env_result = space_state.intersect_ray(query)
		
		# Process the result
		if env_result:
			# Append to the polygon
			var d = (env_result.position - prev_pos).normalized()
			if !d.is_equal_approx(prev_dir):
				verts.append(env_result.position)

				# Create the debug marker
				var sp = Sprite2D.new()
				var t = PlaceholderTexture2D.new()
				t.size = Vector2(5,5)
				sp.texture = t
				sp.position = env_result.position
				_flash_markers.add_child(sp)
			
			prev_dir = d

		# Add the step
		angle += step

	# Final ray cast for starting ray
	query.collision_mask = 4
	shad_result = space_state.intersect_ray(query)
	if shad_result:
		verts.append(shad_result.position)
	else:
		verts.append(global_position)

	# Finalize new polygon
	shadow_body.add_polygon(PackedVector2Array(verts))
	
	# Create the polygon visual
	verts[0] = global_position
	verts[verts.size()-1] = global_position
	var flash_poly: Polygon2D = Polygon2D.new()
	# flash_poly.color = Color(1,0,0,1)
	flash_poly.polygon = PackedVector2Array(verts)
	add_sibling(flash_poly)
	_do_flash = false


func _input(event):
	if event is InputEventMouse:
		if event.is_action_pressed("player_flash"):
			var cpos = Vector2.ZERO					# Top-left camera position
			if _camera:
				cpos = _camera.global_position - get_viewport().get_visible_rect().size / 2
			var epos = cpos + event.position		# Event position relative to world space
			var n = (epos - global_position).normalized()
			if n.is_zero_approx():
				_flash_angle= 0.0
			else:
				_flash_angle = rad_to_deg(atan2(n.y, n.x))
			_do_flash = true
