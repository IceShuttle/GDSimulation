shader_type canvas_item;
uniform vec3 highlight :source_color;
uniform vec3 background :source_color;

void vertex() {
	//float radius = sin(TIME)*100.;
	//VERTEX.x += cos(TIME)*radius;
	//VERTEX.y += sin(TIME)*100.;
}

void fragment() {
	vec2 uv = (UV-.5)*2.;
	float dist = sqrt(pow(uv.x,2)+pow(uv.y,2));
	float phase = dist*20.-TIME*7.;
	float thickness = sin(phase);

	if (sin(phase)>0.){
		COLOR.xyz = smoothstep(highlight,background,vec3(thickness,thickness,thickness));
		}
	else{
		COLOR.xyz=background;
	}
	COLOR.a = sin(phase)+.8;
	if (dist>1.){
		COLOR = vec4(0.,0.,0.,0.);
	}
}

//void light() {
	 //Called for every pixel for every light affecting the CanvasItem.
	 //Uncomment to replace the default light processing function with this one.
//}
