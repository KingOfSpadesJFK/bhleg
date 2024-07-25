extends StaticBody2D
class_name ShadowBody

const META_SHADOW_EXTENT = "extent"
const META_SHADOW_HOLE = "is_hole"

class PolyStackEntry:
	var polygon: PackedVector2Array
	var extent: Rect2
	var is_hole: bool
	var owner: Node


func _ready():
	# Initialize each child polygon with a bounding box and hole
	for c in get_children():
		if c is CollisionPolygon2D:
			c.set_meta(META_SHADOW_EXTENT, Bhleg.calculate_bounding_box(c.polygon))
			c.set_meta(META_SHADOW_HOLE, false)


func add_polygon(verts: PackedVector2Array, extent: Rect2) -> void:
	# Set up the polygon queue
	var poly_stack: Array[PolyStackEntry] = []
	for c in get_children():
		if c is CollisionPolygon2D:
			var entry: PolyStackEntry = PolyStackEntry.new()
			entry.polygon = c.polygon
			# Add to the queue and dispose of each child after this is done...
			if c.has_meta(META_SHADOW_EXTENT) && c.has_meta(META_SHADOW_HOLE):
				# If there is a bounding box, check if input extent intersects the new polygon
				var box: Rect2 = c.get_meta(META_SHADOW_EXTENT) as Rect2
				if extent.intersects(box):
					entry.extent = box
					entry.is_hole = c.get_meta(META_SHADOW_HOLE)
					poly_stack.append(entry)
					c.queue_free()

	# Loop through the poly queue
	while poly_stack.size() > 0:
		# Run a boolean operation on these polygons
		var col_poly: PolyStackEntry = poly_stack.pop_back()
		var combined: Array[PackedVector2Array]
		if col_poly.is_hole:
			combined = Geometry2D.clip_polygons(col_poly.polygon, verts)
		else:
			combined = Geometry2D.merge_polygons(col_poly.polygon, verts)

		# Attach each polygon to a new CollisionPolygon2D
		#  and parent them to you
		for arr: PackedVector2Array in combined:
			if !arr.is_empty():
				var c = CollisionPolygon2D.new()
				c.build_mode = CollisionPolygon2D.BuildMode.BUILD_SEGMENTS
				c.polygon = arr.duplicate()			# Since arr will go bye-bye after the thread
				add_child(c)
				
				# Get the bounding box of the current polygon
				c.set_meta(META_SHADOW_EXTENT, Bhleg.calculate_bounding_box(arr))

				# Determine whether this polygon is a hole
				c.set_meta(META_SHADOW_HOLE, col_poly.is_hole || Geometry2D.is_polygon_clockwise(arr))
				

				# DEBUG PURPOSES
				#var flash_poly: Polygon2D = Polygon2D.new()
				#randomize()
				#flash_poly.color = Color(_rand(), _rand(), _rand(), 1)
				#flash_poly.polygon = arr.duplicate()
				#add_child(flash_poly)


func _rand():
	return 0.75 + randf() * 0.25
