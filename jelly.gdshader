shader_type canvas_item;

uniform vec2 x_pos;
uniform vec4 color;

void vertex() {
	if (VERTEX.y<0.0){
		VERTEX.xy+=x_pos;
	}else{
		VERTEX.xy+=x_pos;
	}
	VERTEX *= exp(sin(TIME));
}

void fragment() {
	if (COLOR.a>0.0){
	COLOR = color;
	COLOR.a = sin(TIME);
	}
}
