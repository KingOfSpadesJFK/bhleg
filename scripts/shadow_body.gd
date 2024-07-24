extends StaticBody2D
class_name ShadowBody


func add_polygon(verts: PackedVector2Array) -> void:
	# Set up the polygon queue
	var poly_queue: Array[PackedVector2Array] = []
	for c in get_children():
		if c is CollisionPolygon2D:
			# Add to the queue and dispose of each child (after this is done...)
			poly_queue.append(c.polygon)
			c.queue_free()

	# Loop through the poly queue
	while poly_queue.size() > 0:
		# Run a boolean operation on these polygons
		var col_poly = poly_queue.pop_front()
		var combined = Geometry2D.merge_polygons(col_poly, verts)

		# Attach each polygon to a new CollisionPolygon2D
		#  and parent them to you
		for arr: PackedVector2Array in combined:
			var c = CollisionPolygon2D.new()
			c.build_mode = CollisionPolygon2D.BuildMode.BUILD_SEGMENTS
			c.polygon = arr.duplicate()			# Since arr will go bye-bye after the thread
			add_child(c)
