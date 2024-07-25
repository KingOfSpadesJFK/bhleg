extends StaticBody2D
class_name ShadowBody

const META_BOUNDING_BOX = "bounding_box"


func add_polygon(verts: PackedVector2Array, extent: Rect2) -> void:
	var minv = func (curvec,newvec):
		return Vector2(min(curvec.x,newvec.x),min(curvec.y,newvec.y))
	var maxv = func (curvec,newvec):
		return Vector2(max(curvec.x,newvec.x),max(curvec.y,newvec.y))

	# Set up the polygon queue
	var poly_stack: Array[PackedVector2Array] = []
	for c in get_children():
		if c is CollisionPolygon2D:
			# Add to the queue and 
			if c.has_meta(META_BOUNDING_BOX):
				var box: Rect2 = c.get_meta(META_BOUNDING_BOX) as Rect2
				if extent.intersects(box):
					poly_stack.append(c.polygon)
					c.queue_free()
			else:
				poly_stack.append(c.polygon)
				c.queue_free()

			# Dispose of each child after this is done...

	# Loop through the poly queue
	while poly_stack.size() > 0:
		# Run a boolean operation on these polygons
		var col_poly = poly_stack.pop_back()
		var combined = Geometry2D.merge_polygons(col_poly, verts)

		# Attach each polygon to a new CollisionPolygon2D
		#  and parent them to you
		for arr: PackedVector2Array in combined:
			var c = CollisionPolygon2D.new()
			c.build_mode = CollisionPolygon2D.BuildMode.BUILD_SEGMENTS
			c.polygon = arr.duplicate()			# Since arr will go bye-bye after the thread
			add_child(c)
			
			# Get the bounding box of the current polygon
			var min_vec = Vector2(pow(2,31)-1,pow(2,31)-1)
			var max_vec = Vector2(-pow(2,31)-1,-pow(2,31)-1)
			for v in arr:
				min_vec = minv.call(min_vec,v)
				max_vec = maxv.call(max_vec,v)
			c.set_meta(META_BOUNDING_BOX, Rect2(min_vec, max_vec-min_vec))
			

			# DEBUG PURPOSES
			# var flash_poly: Polygon2D = Polygon2D.new()
			# randomize()
			# flash_poly.color = Color(_rand(), _rand(), _rand(), 1)
			# flash_poly.polygon = arr.duplicate()
			# add_child(flash_poly)


func _rand():
	return 0.75 + randf() * 0.25
