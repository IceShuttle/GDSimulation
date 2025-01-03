#[compute]
#version 450

#include "utils.glsl"

layout(local_size_x = 1024, local_size_y = 1, local_size_z = 1) in; // invocation

float density_to_pressure(float density) {
    float error = density - info.target_density;
    float pressure = error * info.pressure_multiplier;
    return pressure;
}

vec3 calc_pressure_force(uint i) {
    vec3 force = vec3(0, 0, 0);
    for (int j = 0; j < 1024; j++) {
        float r = compute_distance(pos.data[i], pos.data[j]);
        if (i == j || r < 0.1)
            continue;
        vec3 dir = (pos.data[i] - pos.data[j]) / r;
        float slope = derivative(r);
        float density = densities.data[i];
        if (density < 10)
            continue;
        force += dir * density_to_pressure(density) * slope * info.mass / density;
    }
    return force;
}

void apply_pressure_force(float delta) {
    vel.data[gl_GlobalInvocationID.x] += -(calc_pressure_force(gl_GlobalInvocationID.x) * delta) / 500;
}

void apply_gravity(float delta) {
    vel.data[gl_GlobalInvocationID.x].y -= info.gravity * delta;
}

void check_boundaries(float elasticity) {
    if (abs(0.5 - pos.data[gl_GlobalInvocationID.x].x) > .5) {
        vel.data[gl_GlobalInvocationID.x].x = -1 * vel.data[gl_GlobalInvocationID.x].x * elasticity;
    }
    if (abs(0.5 - pos.data[gl_GlobalInvocationID.x].y) > .5) {
        vel.data[gl_GlobalInvocationID.x].y = -1 * vel.data[gl_GlobalInvocationID.x].y * elasticity;
    }
    if (abs(0.5 - pos.data[gl_GlobalInvocationID.x].z) > .5) {
        vel.data[gl_GlobalInvocationID.x].z = -1 * vel.data[gl_GlobalInvocationID.x].z * elasticity;
    }
}

void move_particle(float delta) {
    pos.data[gl_GlobalInvocationID.x] += vel.data[gl_GlobalInvocationID.x] * delta;
}

void main() {
    apply_gravity(info.delta);
    apply_pressure_force(info.delta);
    check_boundaries(info.elasticity);
    move_particle(info.delta);
    imageStore(output_img, ivec2(gl_GlobalInvocationID.x, 0), vec4(pos.data[gl_GlobalInvocationID.x], 0));
}
