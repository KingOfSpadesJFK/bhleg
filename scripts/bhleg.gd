extends Node


func minv(curvec,newvec): return Vector2(min(curvec.x,newvec.x),min(curvec.y,newvec.y))
func maxv(curvec,newvec): return Vector2(max(curvec.x,newvec.x),max(curvec.y,newvec.y))


func calculate_bounding_box(polygon: PackedVector2Array) -> Rect2:
	var min_vec = Vector2(pow(2,31)-1,pow(2,31)-1)
	var max_vec = Vector2(-pow(2,31),-pow(2,31))
	for v in polygon:
		min_vec = Bhleg.minv(min_vec,v)
		max_vec = Bhleg.maxv(max_vec,v)
	return Rect2(min_vec, max_vec-min_vec)
