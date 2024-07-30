extends Node

const MAX_COORD = pow(2,31)-1
const MIN_COORD = -MAX_COORD

# Scene manager defaults
var fade_out_speed: float = .350
var fade_in_speed: float = .35
var fade_out_pattern: String = "linear"
var fade_in_pattern: String = "linear"
var fade_out_smoothness = 0.2 # (float, 0, 1)
var fade_in_smoothness = 0.2 # (float, 0, 1)
var fade_out_inverted: bool = false
var fade_in_inverted: bool = true
var color: Color = Color.WHITE
var timeout: float = 0.0
var clickable: bool = false
var add_to_back: bool = true

@onready var fade_out_options = SceneManager.create_options(fade_out_speed, fade_out_pattern, fade_out_smoothness, fade_out_inverted)
@onready var fade_in_options = SceneManager.create_options(fade_in_speed, fade_in_pattern, fade_in_smoothness, fade_in_inverted)
@onready var general_options = SceneManager.create_general_options(color, timeout, clickable, add_to_back)
var current_scene
var _spawn_args: Dictionary

func minv(curvec,newvec): return Vector2(min(curvec.x,newvec.x),min(curvec.y,newvec.y))
func maxv(curvec,newvec): return Vector2(max(curvec.x,newvec.x),max(curvec.y,newvec.y))


func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS

	# Scene manager stuff
	SceneManager.load_finished.connect(_change_to_loaded_scene)
	current_scene = SceneManager._current_scene


### Calculates the bounding box of a polygon
#	polygon: The packed array of verticies making the polygon
#	Returns a Rect2 containing the polygon's boundaries
func calculate_bounding_box(polygon: PackedVector2Array, offset: Vector2=Vector2.ZERO) -> Rect2:
	var min_vec = Vector2(MAX_COORD, MAX_COORD)
	var max_vec = Vector2(MIN_COORD, MIN_COORD)
	for v in polygon:
		min_vec = Bhleg.minv(min_vec,v)
		max_vec = Bhleg.maxv(max_vec,v)
	return Rect2(min_vec-offset, max_vec-min_vec+offset)


### Call this when you want to change the scene midgame.
### Relies on the SceneManager addon
#	scene: Name of the scene you want to change to
#	args: A dictionary of arguments to pass down
func change_scene(scene: String, args: Dictionary = {}):
	SceneManager.set_recorded_scene(scene)
	SceneManager.change_scene("loading", fade_out_options, fade_in_options, general_options)
	await SceneManager.fade_in_finished
	_spawn_args = args
	await get_tree().create_timer(0.05).timeout
	current_scene = scene
	SceneManager.load_scene_interactive(SceneManager.get_recorded_scene())

func _change_to_loaded_scene():
	SceneManager.change_scene_to_loaded_scene(fade_out_options, fade_in_options, general_options)


### Reloads the current scene.
### Relies on the SceneManager addon.
#	args: A dictionary of arguments to pass down
func reload_scene(args: Dictionary = {}):
	current_scene = SceneManager._current_scene
	change_scene(current_scene, args)

### Converts a shape to a polygon
#	samples: For circles
#	offset: Value to offset each vertex
#   Returns a dictionary containing the PackedVector2Array 'polygon' and the bounding box 'extent'
func convert_shape_to_polygon(shape: Shape2D, samples: int = 20, offset: Vector2 = Vector2.ZERO) -> Dictionary:
	var verts: Array[Vector2] = []
	var extent: Rect2 = Rect2()
	if shape is CircleShape2D:
		# Convert the circle into a polygon
		var r: float = (shape as CircleShape2D).radius
		var rad: float = 0
		var step: float = 2 * PI / float(samples)
		
		for i in range(samples):
			verts.append(Vector2(cos(rad), sin(rad)) * r + offset)
			rad += step

		extent.position = offset - Vector2(r,r)
		extent.size = Vector2(r,r) * 2.0

	# Return the polygon
	return { "polygon": PackedVector2Array(verts), "extent": extent }
	

func _notification(what):
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		get_tree().quit() # default behavior
