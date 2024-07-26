@tool
extends Control
class_name CellContainer

@export var red_cells: int = 1
@export var cyan_cells: int = 1
var _red_texture: TextureRect
var _blue_texture: TextureRect
var _container: BoxContainer 


func _enter_tree():
	for c in get_children():
		c.queue_free()
	
	# Initialize the box container itself
	_container = BoxContainer.new()
	_container.alignment = BoxContainer.ALIGNMENT_CENTER
	add_child(_container)

	# Initialize a placeholder texture
	var t: PlaceholderTexture2D = PlaceholderTexture2D.new()
	t.size = Vector2(3,5)

	# Create the red cells
	_red_texture = TextureRect.new()
	_red_texture.texture = t
	_red_texture.expand_mode = TextureRect.EXPAND_KEEP_SIZE
	_red_texture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	for i in range(red_cells):
		_container.add_child(_red_texture)
		_red_texture = _red_texture.duplicate()
	
	# Create the border
	var tb: PlaceholderTexture2D = PlaceholderTexture2D.new()
	tb.size = Vector2(1,7)
	var b: TextureRect = TextureRect.new()
	b.texture = tb
	_container.add_child(b)
	
	# Create the cyan cells
	_blue_texture = _red_texture.duplicate()
	for i in range(cyan_cells):
		_container.add_child(_blue_texture)
		_blue_texture = _blue_texture.duplicate()


func _ready():
	_container.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	_container.add_theme_constant_override("separation", 1)


# Decreases red and cyan cells from cell container
func _on_player_flash(red: int, cyan: int):
	# If there are enough children
	#  ...excluding the border
	if _container.get_child_count() > 1:
		# Free the children
		for r in range(red):
			var ch = _container.get_child(0)
			_container.remove_child(ch)
			ch.queue_free()
			if red_cells <= 0:
				break
		
		for c in range(cyan):
			var ch = _container.get_child(_container.get_child_count()-1)
			_container.remove_child(ch)
			ch.queue_free()
			if cyan_cells <= 0:
				break
