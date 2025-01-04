shader_type particles;
uniform sampler2D pos_data;
uniform vec3 offset;

void start() {
	// Called when a particle is spawned.
}

void process() {
	vec4 data = texelFetch(pos_data,ivec2(int(INDEX),0),0);
	TRANSFORM[3].xyz = EMISSION_TRANSFORM[3].xyz+data.rgb-offset/2.0;
}
