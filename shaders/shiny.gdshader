shader_type canvas_item;

float hard_step(float f) {
	f = round(f*16.0) / 16.0;
	return f;
}

void fragment() {
	vec2 uv = SCREEN_UV;
	float off = 0.875;
	float factor = 0.25;
	vec2 pp = SCREEN_UV / SCREEN_PIXEL_SIZE / 8.0f;
	float t = TIME + (pp.x + round(pp.y*2.0)/2.0) * 1.0;
	COLOR *= vec4(hard_step((sin(t)*factor)+off), hard_step((sin(t+PI/3.0)*factor)+off), hard_step((sin(t+2.0*PI/3.0)*factor)+off), COLOR.a);
}