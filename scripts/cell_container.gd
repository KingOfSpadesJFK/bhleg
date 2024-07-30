@tool
extends Control
class_name CellContainer

@export var red_cells: int = 1
@export var cyan_cells: int = 1
var _red_texture: ColorRect
var _blue_texture: ColorRect
var _container: BoxContainer 

func _enter_tree():
	for c in get_children():
		c.queue_free()
	
	# Initialize the box container itself
	_container = BoxContainer.new()
	_container.alignment = BoxContainer.ALIGNMENT_CENTER
	add_child(_container)

	# Create the red cells
	_red_texture = ColorRect.new()
	_red_texture.color = Color.html("#e04500")
	_red_texture.custom_minimum_size = Vector2(3, 5)
	_red_texture.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_red_texture.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	for i in range(red_cells):
		_container.add_child(_red_texture)
		_red_texture = _red_texture.duplicate()
	
	# Create the border
	var b: ColorRect = ColorRect.new()
	b.color = Color.html("#283255")
	b.custom_minimum_size = Vector2(1, 7)
	b.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	b.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_container.add_child(b)
	
	# Create the cyan cells
	_blue_texture = _red_texture.duplicate()
	_blue_texture.color = Color.html("#00c9ff")
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
