shader_type canvas_item;
uniform sampler2D pos;

void vertex() {
}

void fragment() {
	//COLOR = vec4(UV, 0.5, 1.0);
	vec4 col = texture(pos,UV);
	COLOR.rgba = col;
	COLOR.a = 1.0;
}

//void light() {
	// Called for every pixel for every light affecting the CanvasItem.
	// Uncomment to replace the default light processing function with this one.
//}
