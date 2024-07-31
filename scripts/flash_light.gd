extends Node2D
class_name FlashLight

const FLASH_RAY_LENGTH = 1000.0
const FLASH_SPREAD = 90.0			# How wide the area of flash should be (in degrees)
const FLASH_SAMPLES = 200

@export var exclusions: Array = []


func add_exclusion(exclude: Node2D):
	exclusions.append(exclude)


# Where the flash of light polygon is made
func flash_light(red_light: bool):
	## Debugging markers
	#if _flash_markers:
		#_flash_markers.queue_free()
	#_flash_markers = Node.new()
	#add_child(_flash_markers)

	# Initialize the new polygon
	var verts: Array[Vector2] = []

	# Initialize the raycasting
	var space_state = get_world_2d().direct_space_state
	var step: float = deg_to_rad(FLASH_SPREAD) / FLASH_SAMPLES
	var angle: float = global_rotation + deg_to_rad(FLASH_SPREAD / 2.0)
	
	# Initial starting ray cast
	var mid_pos: Vector2 = Vector2.ZERO
	var start_pos: Vector2 = global_position
	var full_length: Vector2 = Vector2(cos(angle), sin(angle)) * FLASH_RAY_LENGTH
	var query = PhysicsRayQueryParameters2D.create(start_pos, global_position + full_length)
	query.exclude = exclusions
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
		query.to = global_position + dir * FLASH_RAY_LENGTH
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
	var extent = Bhleg.calculate_bounding_box(PackedVector2Array(verts))
	if Geometry2D.is_polygon_clockwise(PackedVector2Array(verts)):
		get_tree().call_group("ShadowBodies", "add_polygon", PackedVector2Array(verts), extent)
		if !red_light:
			get_tree().call_group("RedLightBodies", "subtract_polygon", PackedVector2Array(verts), extent)
		else:
			get_tree().call_group("RedLightBodies", "add_polygon", PackedVector2Array(verts), extent)
