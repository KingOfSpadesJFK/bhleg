extends CharacterBody2D
class_name Player


const SPEED = 200.0
const JUMP_VELOCITY = -400.0
const FLASH_RAY_LENGTH = 1000.0
const FLASH_SPREAD = 90.0			# How wide the area of flash should be (in degrees)
const FLASH_SAMPLES = 200

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

# The static body to draw over
@export var shadow_body: ShadowBody
@export var red_cells: int = 10
@export var cyan_cells: int = 10

var flash_type: FlashType = FlashType.WHITE

@onready var _flash_point: Node2D = $FlashAnchor/FlashHead
var _mouse_position: Vector2 = Vector2.ZERO
var _do_flash: FlashType = FlashType.NONE
var _flash_angle: float :
	set(value):
		_flash_angle = value
		$FlashAnchor.rotation = deg_to_rad(value)
		pass

var _flash_markers: Node
var _beam_charge: float
@onready var _camera: Camera2D = $Camera2D

signal flash(red_count: int, cyan_count: int)

enum FlashType {
	NONE,
	WHITE,
	RED,
	CYAN,
}


func _process(_delta):
	if flash_type == FlashType.RED:
		if _beam_charge > 3.0 && _beam_charge <= red_cells:
			_beam_charge += _delta
			
	_flash_angle = _calculate_flash_direction(_mouse_position)
	pass


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
	if !(_do_flash == FlashType.NONE || _do_flash == FlashType.RED):
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
	var step: float = deg_to_rad(FLASH_SPREAD) / FLASH_SAMPLES
	var angle: float = deg_to_rad(_flash_angle + (FLASH_SPREAD / 2.0))
	
	# Initial starting ray cast
	var mid_pos: Vector2 = Vector2.ZERO
	var start_pos: Vector2 = _flash_point.global_position
	var full_length: Vector2 = Vector2(cos(angle), sin(angle)) * FLASH_RAY_LENGTH
	var query = PhysicsRayQueryParameters2D.create(start_pos, _flash_point.global_position + full_length)
	query.collision_mask = 1
	var env_result = space_state.intersect_ray(query)
	if env_result:
		mid_pos = env_result.position

	# Record previous entries
	var prev_pos = start_pos
	var v = (mid_pos - prev_pos).normalized()
	var prev_dir = atan2(v.y, v.x)
	
	# Raycast the samples
	angle -= step
	for i in range(FLASH_SAMPLES-1):
		# Raycast
		var dir = Vector2(cos(angle), sin(angle))	# Convert the current angle to a normal vector
		query.to = _flash_point.global_position + dir * FLASH_RAY_LENGTH
		query.collision_mask = 1					# This first ray query will check for layer 1 (the environment)
		env_result = space_state.intersect_ray(query)
		
		# Process the result
		if env_result:
			# Check if the points are lined in the same direction
			var _v = (env_result.position - mid_pos).normalized()
			var next_dir = atan2(_v.y, _v.x)
			if next_dir - prev_dir >= PI / 120.0 || next_dir - prev_dir <= -PI / 120.0:
				# Append to the polygon
				verts.append(mid_pos)
			
			prev_pos = mid_pos
			mid_pos = env_result.position
			prev_dir = next_dir

		# Add the step
		angle -= step

	# Finalize new polygon
	verts.append(mid_pos)
	verts.append(start_pos)
	var extent = Bhleg.calculate_bounding_box(PackedVector2Array(verts), Vector2(64,64))
	if Geometry2D.is_polygon_clockwise(PackedVector2Array(verts)):
		shadow_body.add_polygon(PackedVector2Array(verts), extent)

	# Create the debug markers
	#for _v in verts:
	#	# Create the debug marker
	#	var sp = Sprite2D.new()
	#	var t = PlaceholderTexture2D.new()
	#	t.size = Vector2(5,5)
	#	sp.texture = t
	#	sp.position = _v
	#	_flash_markers.add_child(sp)
	
	_do_flash = FlashType.NONE
	

func _has_enough_for_white() -> bool: return red_cells >= 1 && cyan_cells >= 1
func _has_enough_for_red() -> bool: return red_cells >= 1
func _has_enough_for_cyan() -> bool: return cyan_cells >= 5


# Should cyan and red switch?
#  Red should be the floaty stuff?
#  Cyan should be the laser beam?
func _input(event):
	# Since there's probs only gonna be one place we'll need this, put it here
	#  A check to see if we should do the flash or not
	var _flash_check: Callable = func() -> bool:		
		if event.is_action_pressed("player_flash"):
			match flash_type:
				FlashType.WHITE:
					if _has_enough_for_white():
						red_cells -= 1
						cyan_cells -= 1
						flash.emit(1, 1)
						return FlashType.WHITE
				FlashType.RED:
					if _has_enough_for_red():
						return FlashType.RED	# Do something else for red
				FlashType.CYAN:
					if _has_enough_for_cyan():
						cyan_cells -= 5
						return FlashType.CYAN
				_:
					return FlashType.NONE	
		
		return FlashType.NONE

	if event is InputEventMouseButton:
		_mouse_position = event.position

		# Do the red thing instead
		if event.is_action_released("player_flash") && _do_flash == FlashType.RED:
			if red_cells >= roundi(_beam_charge):
				red_cells -= roundi(_beam_charge)

			_do_flash = FlashType.NONE
		else:
			# Activate... the flash!
			_do_flash = _flash_check.call()
			if _do_flash:
				_flash_angle = _calculate_flash_direction(_mouse_position)
	
	if event is InputEventMouse:
		_mouse_position = event.position


func _calculate_flash_direction(mouse_pos: Vector2):
	var result: float = 0
	var cpos = Vector2.ZERO					# Top-left camera position
	if _camera:
		cpos = _camera.global_position - get_viewport().get_visible_rect().size / 2
	var epos = cpos + mouse_pos		# Event position relative to world space
	var n = (epos - global_position).normalized()
	if n.is_zero_approx():
		result = 0.0
	else:
		result = rad_to_deg(atan2(n.y, n.x))
		var q: float = snapped(result, 45.0)
		result = q
		
	return result

