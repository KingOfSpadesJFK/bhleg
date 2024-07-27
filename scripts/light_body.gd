extends CollisionObject2D
class_name LightBody

const META_SHADOW_EXTENT = "extent"
const META_SHADOW_HOLE = "is_hole"
const META_SHADOW_VISUAL = "visual"

var _visual_poly: Node2D

class PolyStackEntry:
	var polygon: PackedVector2Array
	var extent: Rect2
	var is_hole: bool
	var visual: Node


func _enter_tree():
	_visual_poly = Node2D.new()

	# Initialize each child polygon with a bounding box and hole
	for c in get_children():
		if c is CollisionPolygon2D:
			c.set_meta(META_SHADOW_EXTENT, Bhleg.calculate_bounding_box(c.polygon))
			c.set_meta(META_SHADOW_HOLE, false)

			# Create the visual for the poly
			add_visual_polygon(c.polygon)
		
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

				add_visual_polygon(shape_poly.polygon)

	add_child(_visual_poly)


func add_visual_polygon(polygon: PackedVector2Array):
	var poly: Polygon2D = Polygon2D.new()
	poly.polygon = polygon
	_visual_poly.add_child(poly)


### Adds a polygon to the shadow body
#	verts: The array of vertices for the polygon
#	extent: The bounding box of the passed in polygon
func add_polygon(verts: PackedVector2Array, extent: Rect2) -> void:
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
				if box.intersects(extent):
					entry.extent = box
					entry.is_hole = c.get_meta(META_SHADOW_HOLE)
					poly_queue.append(entry)
					c.queue_free()
					#c.get_meta(META_SHADOW_VISUAL).queue_free()

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
				var c = CollisionPolygon2D.new()
				c.build_mode = CollisionPolygon2D.BuildMode.BUILD_SEGMENTS
				c.polygon = arr
				add_child(c)
				if !(col_poly.is_hole || Geometry2D.is_polygon_clockwise(arr)):
					main_body = c
				
				# Get the bounding box of the current polygon
				c.set_meta(META_SHADOW_EXTENT, Bhleg.calculate_bounding_box(arr))

				# Determine whether this polygon is a hole
				c.set_meta(META_SHADOW_HOLE, col_poly.is_hole || Geometry2D.is_polygon_clockwise(arr))
		
		# Create the visual for the polygon
		add_visual_polygon(verts)
