extends Node2D
class_name RedLightBody

const META_SHADOW_EXTENT = "extent"
const META_SHADOW_HOLE = "is_hole"
const META_SHADOW_VISUAL = "visual"

@export var texture: Texture2D
@export var solid: bool = false
@export_category("Physics")
@export var gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity")
@export var linear_damp: float = 0.0
@export_flags_2d_physics var collision_layer: int = 1
@export_flags_2d_physics var collision_mask: int = 1

var _visual_group: CanvasGroup = CanvasGroup.new()
var _body_area: Area2D = Area2D.new()
var _hole_area: Area2D = Area2D.new()

class PolyStackEntry:
	var polygon: PackedVector2Array
	var extent: Rect2
	var is_hole: bool
	var visual: Node

signal body_entered_body(b: Node2D)
signal body_entered_hole(b: Node2D)
signal body_exited_body(b: Node2D)
signal body_exited_hole(b: Node2D)


# The same function as in light_body, but with a few _body_area.'s lying around
func _enter_tree():
	# Initialize the areas
	_body_area.linear_damp = linear_damp
	_body_area.gravity = gravity
	_hole_area.linear_damp = linear_damp
	_hole_area.gravity = gravity
	_body_area.collision_layer = collision_layer
	_body_area.collision_mask  = collision_mask
	_hole_area.collision_layer = collision_layer
	_hole_area.collision_mask  = collision_mask

	# Initialize each child polygon with a bounding box and hole
	for c in get_children():
		if c is CollisionPolygon2D:
			c.reparent(_body_area)
			c.set_meta(META_SHADOW_EXTENT, Bhleg.calculate_bounding_box(c.polygon))
			c.set_meta(META_SHADOW_HOLE, false)

			# Create the visual for the poly
			var p = _add_visual_polygon(c.polygon)
			c.set_meta(META_SHADOW_VISUAL, p)
		
		elif c is CollisionShape2D:
			c.queue_free()

			# Convert the shape into a polygon
			var shape_poly: Dictionary = Bhleg.convert_shape_to_polygon(c.shape, 20,  c.global_position)

			# Create the new polygon
			var col: CollisionPolygon2D = CollisionPolygon2D.new()
			col.build_mode = CollisionPolygon2D.BUILD_SEGMENTS
			col.polygon = shape_poly.polygon
			_body_area.add_child(col)

			var extent = shape_poly.extent
			col.set_meta(META_SHADOW_EXTENT, extent)
			col.set_meta(META_SHADOW_HOLE, false)

			var p = _add_visual_polygon(shape_poly.polygon)
			col.set_meta(META_SHADOW_VISUAL, p)
	
	# Add each children to the scene tree
	add_child(_visual_group)
	add_child(_body_area)
	add_child(_hole_area)


func _apply_gravity_and_damp(b: Node2D):
	if b is Player:
		b.gravity = gravity
		b.damp = linear_damp
	pass


func _restore_gravity_and_damp(b: Node2D):
	if b is Player:
		b.gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
		b.damp = 0.0
	pass


func _on_body_area_body_entered(b: Node2D): 
	body_entered_body.emit(b) 
	_apply_gravity_and_damp(b)


func _on_hole_area_body_entered(b: Node2D): 
	body_entered_hole.emit(b)
	_restore_gravity_and_damp(b)


func _on_body_area_body_exited(b: Node2D):  
	body_exited_body.emit(b) 
	_restore_gravity_and_damp(b)


func _on_hole_area_body_exited(b: Node2D):  
	body_exited_hole.emit(b) 
	_apply_gravity_and_damp(b)




func _ready():
	_body_area.body_entered.connect(_on_body_area_body_entered)
	_hole_area.body_entered.connect(_on_hole_area_body_entered)
	_body_area.body_exited.connect(_on_body_area_body_exited)
	_hole_area.body_exited.connect(_on_hole_area_body_exited)
	pass


func _add_visual_polygon(polygon: PackedVector2Array, hole: bool = false) -> Polygon2D:
	var poly: Polygon2D = Polygon2D.new()
	poly.polygon = polygon
	poly.set_meta(META_SHADOW_HOLE, hole)

	# For holes in the light
	if hole:
		var m = CanvasItemMaterial.new()
		m.blend_mode = CanvasItemMaterial.BLEND_MODE_SUB
		poly.material = m

	_visual_group.add_child(poly)
	return poly


### Subtracts a polygon from the light body
#	verts: The array of vertices for the polygon
#	extent: The bounding box of the passed in polygon
func subtract_polygon(verts: PackedVector2Array, extent: Rect2) -> void:
	# Get a polygon queue containing all the polygons the flash is overlapping
	var poly_queue = _generate_poly_queue(verts, extent)

	# Loop through the poly queue			# Who woulda knew sorting by what's 
	var i: int = poly_queue.size() - 1		#  a hole and not would come in handy
	var main_hole: CollisionPolygon2D = null
	while i >= 0:
		# Run a boolean operation on these polygons
		var combined: Array[PackedVector2Array]
		var col_poly: PolyStackEntry = poly_queue[i]
		i -= 1

		# If the poly is a hole...
		#  merge the flash into the hole
		if !col_poly.is_hole:
			combined = Geometry2D.clip_polygons(col_poly.polygon, verts)	

		# If the main body is already dealt with... 
		#  merge the main poly with the current poly
		elif main_hole:
			combined = Geometry2D.merge_polygons(col_poly.polygon, main_hole.polygon)	# Merge the main body with the col_poly
			main_hole.free()
			main_hole = null
			pass
		
		# Just clip the flash from the current poly
		else:
			combined = Geometry2D.merge_polygons(col_poly.polygon, verts)	

		# Attach each polygon to a new CollisionPolygon2D
		#  and add them to the tree
		for arr: PackedVector2Array in combined:
			if !arr.is_empty():
				var is_hole = col_poly.is_hole || Geometry2D.is_polygon_clockwise(arr)
				var c = _generate_collision_polygon(arr, is_hole)

				# Generate the visual for the polygon
				#  and associate the visual to the collision
				var v = _add_visual_polygon(arr, is_hole)
				c.set_meta(META_SHADOW_VISUAL, v)

				# It's a surprise tool to help us when merging wiht the main body
				if (is_hole):
					main_hole = c
	
	# Reorder the children
	_reorder_children(_visual_group)
	_reorder_children(_hole_area)


### Adds a polygon to the light body
#	verts: The array of vertices for the polygon
#	extent: The bounding box of the passed in polygon
func add_polygon(verts: PackedVector2Array, extent: Rect2) -> void:
	# Get a polygon queue containing all the polygons the flash is overlapping
	var poly_queue = _generate_poly_queue(verts, extent)

	# If this flash overlaps nothing at all...
	#  just add the collision poly
	if poly_queue.is_empty():
		var c = _generate_collision_polygon(verts, false)
		var v = _add_visual_polygon(verts, false)
		c.set_meta(META_SHADOW_VISUAL, v)
	
	# If this flash is overlapping something...
	else:
		# Loop through the poly queue
		var i: int = 0
		var main_body: CollisionPolygon2D = null
		while i < poly_queue.size():
			# Run a boolean operation on these polygons
			var col_poly: PolyStackEntry = poly_queue[i]
			i += 1
			var combined: Array[PackedVector2Array]

			# If the poly is a hole...
			#  cut the flash from the hole
			if col_poly.is_hole:
				combined = Geometry2D.clip_polygons(col_poly.polygon, verts)

			# If the main body is already dealt with... 
			#  merge the main poly with the current poly
			elif main_body:		
				combined = Geometry2D.merge_polygons(col_poly.polygon, main_body.polygon)	# Merge the main body with the col_poly
				main_body.free()
				main_body = null
			
			# Just merge the flash with the current poly
			else:
				combined = Geometry2D.merge_polygons(col_poly.polygon, verts)	

			# Attach each polygon to a new CollisionPolygon2D
			#  and add them to the tree
			for arr: PackedVector2Array in combined:
				if !arr.is_empty():
					var is_hole = col_poly.is_hole || Geometry2D.is_polygon_clockwise(arr)
					var c = _generate_collision_polygon(arr, is_hole)

					# Generate the visual for the polygon
					#  and associate the visual to the collision
					var v = _add_visual_polygon(arr, is_hole)
					c.set_meta(META_SHADOW_VISUAL, v)

					if !(is_hole):
						main_body = c
	
	# Reorder the children
	_reorder_children(_visual_group)
	_reorder_children(_hole_area)


func _generate_poly_queue(_verts: PackedVector2Array, _extent: Rect2):
	# Set up the polygon queue and the necessary function for this
	var poly_queue: Array[PolyStackEntry] = []
	var _add_to_poly_q: Callable = func (c: CollisionPolygon2D, is_hole: bool):
		var entry: PolyStackEntry = PolyStackEntry.new()
		entry.polygon = c.polygon
		# If there is a bounding box, check if input extent intersects the new polygon
		var box: Rect2 = c.get_meta(META_SHADOW_EXTENT) as Rect2
		if box.intersects(_extent):
			entry.extent = box
			entry.is_hole = c.get_meta(META_SHADOW_HOLE)
			poly_queue.append(entry)
			c.get_meta(META_SHADOW_VISUAL).queue_free()
			c.queue_free()
	
	# Add overlapping bodies to the poly queue
	for c in _body_area.get_children():
		if c is CollisionPolygon2D:
			# Add to the queue and dispose of each child after this is done...
			if c.has_meta(META_SHADOW_EXTENT):
				# If there is a bounding box, check if input extent intersects the new polygon
				_add_to_poly_q.call(c, false)
	
	# Add overlapping holes to the poly queue
	for c in _hole_area.get_children():
		if c is CollisionPolygon2D:
			# Add to the queue and dispose of each child after this is done...
			if c.has_meta(META_SHADOW_EXTENT):
				# If there is a bounding box, check if input extent intersects the new polygon
				_add_to_poly_q.call(c, true)
	
	return poly_queue


func _generate_collision_polygon(polygon: PackedVector2Array, is_hole: bool) -> CollisionPolygon2D:
	var c = CollisionPolygon2D.new()
	c.build_mode = CollisionPolygon2D.BUILD_SOLIDS if solid else CollisionPolygon2D.BuildMode.BUILD_SEGMENTS
	c.polygon = polygon
	if is_hole:
		_hole_area.add_child(c)
	else:
		_body_area.add_child(c)
	
	# Get the bounding box of the current polygon
	c.set_meta(META_SHADOW_EXTENT, Bhleg.calculate_bounding_box(polygon))

	# Determine whether this polygon is a hole
	c.set_meta(META_SHADOW_HOLE, is_hole)

	return c


# Reorders children so holes are done first
func _reorder_children(n: Node):
	for c in n.get_children():
		# If it has the meta, GET the meta
		#                     ^^^ for your dyslexic ass
		if c.has_meta(META_SHADOW_HOLE) && c.get_meta(META_SHADOW_HOLE):
			c.move_to_front()
	pass
