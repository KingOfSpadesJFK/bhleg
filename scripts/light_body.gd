extends CollisionObject2D
class_name LightBody

const META_SHADOW_EXTENT = "extent"
const META_SHADOW_HOLE = "is_hole"
const META_SHADOW_VISUAL = "visual"

@export var texture: Texture2D
var _visual_group: CanvasGroup

class PolyStackEntry:
	var polygon: PackedVector2Array
	var extent: Rect2
	var is_hole: bool
	var visual: Node


func _enter_tree():
	_visual_group = CanvasGroup.new()

	# Initialize each child polygon with a bounding box and hole
	for c in get_children():
		if c is CollisionPolygon2D:
			c.set_meta(META_SHADOW_EXTENT, Bhleg.calculate_bounding_box(c.polygon))
			c.set_meta(META_SHADOW_HOLE, false)

			# Create the visual for the poly
			var p = _add_visual_polygon(c.polygon)
			c.set_meta(META_SHADOW_VISUAL, p)
		
		elif c is CollisionShape2D:
			if c.shape is CircleShape2D:
				c.queue_free()

				# Convert the circle into a polygon
				var shape_poly: Dictionary = Bhleg.convert_shape_to_polygon(c.shape, 20,  c.global_position)

				# Create the new polygon
				var col: CollisionPolygon2D = CollisionPolygon2D.new()
				col.build_mode = CollisionPolygon2D.BUILD_SEGMENTS
				col.polygon = shape_poly.polygon
				add_child(col)

				var extent = shape_poly.extent
				col.set_meta(META_SHADOW_EXTENT, extent)
				col.set_meta(META_SHADOW_HOLE, false)

				var p = _add_visual_polygon(shape_poly.polygon)
				col.set_meta(META_SHADOW_VISUAL, p)

	add_child(_visual_group)


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
	# Generate the polygon queue
	var poly_queue = _generate_poly_queue(verts, extent)

	# Loop through the poly queue
	var i: int = 0
	var main_hole: CollisionPolygon2D = null
	while i < poly_queue.size():
		# Run a boolean operation on these polygons
		var col_poly: PolyStackEntry = poly_queue[i]
		i += 1
		var combined: Array[PackedVector2Array]

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

				if (is_hole):
					main_hole = c
	
	# Reorder the children
	_reorder_children(self)
	_reorder_children(_visual_group)


### Adds a polygon to the light body
#	verts: The array of vertices for the polygon
#	extent: The bounding box of the passed in polygon
func add_polygon(verts: PackedVector2Array, extent: Rect2) -> void:
	# Generate the polygon queue
	var poly_queue = _generate_poly_queue(verts, extent)

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

				if !(is_hole):
					main_body = c
	
	# Reorder the children
	_reorder_children(self)
	_reorder_children(_visual_group)


func _generate_poly_queue(_verts: PackedVector2Array, _extent: Rect2):
	# Set up the polygon queue
	var poly_queue: Array[PolyStackEntry] = []
	for c in get_children():
		if c is CollisionPolygon2D:
			var entry: PolyStackEntry = PolyStackEntry.new()
			entry.polygon = c.polygon

			# Add to the queue and dispose of each child after this is done...
			if c.has_meta(META_SHADOW_EXTENT) && c.has_meta(META_SHADOW_HOLE):
				# If there is a bounding box, check if input extent intersects the new polygon
				var box: Rect2 = c.get_meta(META_SHADOW_EXTENT) as Rect2
				if box.intersects(_extent):
					entry.extent = box
					entry.is_hole = c.get_meta(META_SHADOW_HOLE)
					poly_queue.append(entry)
					c.get_meta(META_SHADOW_VISUAL).queue_free()
					c.queue_free()
	
	return poly_queue


func _generate_collision_polygon(polygon: PackedVector2Array, is_hole: bool) -> CollisionPolygon2D:
	var c = CollisionPolygon2D.new()
	c.build_mode = CollisionPolygon2D.BuildMode.BUILD_SEGMENTS
	c.polygon = polygon
	add_child(c)
	
	# Get the bounding box of the current polygon
	c.set_meta(META_SHADOW_EXTENT, Bhleg.calculate_bounding_box(polygon))

	# Determine whether this polygon is a hole
	c.set_meta(META_SHADOW_HOLE, is_hole)

	# Generate the visual for the polygon
	#  and associate the visual to the collision
	var v = _add_visual_polygon(polygon, is_hole)
	c.set_meta(META_SHADOW_VISUAL, v)

	return c


func _reorder_children(n: Node):
	for c in n.get_children():
		if c.has_meta(META_SHADOW_HOLE) && c.get_meta(META_SHADOW_HOLE):
			c.move_to_front()
	pass
