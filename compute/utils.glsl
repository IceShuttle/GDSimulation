layout(set = 0, binding = 0, std430) restrict buffer readonly Info {
    float waste;
    float mass;
    float xbound;
    float ybound;
    float zbound;
    float elasticity;
    float gravity;
    float target_density;
    float pressure_multiplier;
    float viscosity;
    float delta;
} info;

layout(set = 0, binding = 1, std430) restrict buffer PosBuffer {
    vec3 data[];
}
pos;

layout(set = 0, binding = 2, std430) restrict buffer VelBuffer {
    vec3 data[];
}
vel;

layout(set = 0, binding = 3, std430) restrict buffer Density {
    float data[];
}
densities;

layout(rgba16f, binding = 4) uniform image2D output_img;
float compute_distance(vec3 p1, vec3 p2) {
    vec3 diff = p2 - p1;
    return sqrt(dot(diff, diff));
}

float smoothing_func(float r) {
    if (r < 1) {
        return 1 - pow(r, 2);
    } else {
        return 0;
    }
}

float derivative(float r) {
    if (r < 1) {
        return -(3 * r) / 2;
    } else {
        return 0;
    }
}
