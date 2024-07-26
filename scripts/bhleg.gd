extends Node

const MAX_COORD = pow(2,31)-1
const MIN_COORD = -MAX_COORD

func minv(curvec,newvec): return Vector2(min(curvec.x,newvec.x),min(curvec.y,newvec.y))
func maxv(curvec,newvec): return Vector2(max(curvec.x,newvec.x),max(curvec.y,newvec.y))


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
