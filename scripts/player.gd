extends CharacterBody2D
class_name Player


const SPEED = 200.0
const JUMP_VELOCITY = -400.0
const FLASH_RAY_LENGTH = 1000.0
const FLASH_SPREAD = 45.0			# How wide the area of flash should be (in degrees)
const FLASH_SAMPLES = 100

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

var _do_flash: bool = false
var _flash_direction: Vector2
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

	# Raycast
	var space_state = get_world_2d().direct_space_state
	var flash_angle: float = atan2(_flash_direction.y, _flash_direction.x)
	var step: float = deg_to_rad(FLASH_SPREAD / FLASH_SAMPLES)
	var angle: float = flash_angle - deg_to_rad(FLASH_SPREAD / 2.0)
	for i in range(FLASH_SAMPLES):
		var dir = Vector2(cos(angle), sin(angle))
		var query = PhysicsRayQueryParameters2D.create(global_position, dir * FLASH_RAY_LENGTH)
		var result = space_state.intersect_ray(query)
		angle += step
		if result:
			var sp = Sprite2D.new()
			var t = PlaceholderTexture2D.new()
			t.size = Vector2(5,5)
			sp.texture = t
			sp.position = result.position
			_flash_markers.add_child(sp)

	_do_flash = false


func _input(event):
	if event is InputEventMouseButton:
		if event.is_action_pressed("player_flash"):
			var cpos = Vector2.ZERO					# Top-left camera position
			if _camera:
				cpos = _camera.global_position - get_viewport().get_visible_rect().size / 2
			var epos = cpos + event.position		# Event position relative to world space
			_flash_direction = (epos - global_position).normalized()
			_do_flash = true
