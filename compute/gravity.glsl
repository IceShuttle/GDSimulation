#[compute]
#version 450

#include "utils.glsl"

layout(local_size_x = 1024, local_size_y = 1, local_size_z = 1) in; // invocation

float calc_pressure(float density) {
    return density * info.pressure_multiplier / info.mass;
}

vec3 calc_pressure_force(uint i) {
    vec3 pressure_grad = vec3(0, 0, 0);
    for (int j = 0; j < 1024; j++) {
        float density = densities.data[j];
        vec3 diff = pos.data[i] - pos.data[j];
        float r = length(diff);

        if (i == j)
            continue;
        if (r < 0.01)
            r = 0.01;
        if (density < 10)
            density = 10;
        vec3 dir = diff / r;

        float mass = info.mass;
        pressure_grad += dir * mass * calc_pressure(density) * derivative(r) / density;
    }
    return pressure_grad;
}

void apply_pressure_force(float delta) {
    vel.data[gl_GlobalInvocationID.x] -= calc_pressure_force(gl_GlobalInvocationID.x) * delta;
}

vec3 calc_viscosity_force(uint i) {
    vec3 local_velocity = vec3(0, 0, 0);
    for (int j = 0; j < 1024; j++) {
        float density = densities.data[j];
        vec3 diff = pos.data[i] - pos.data[j];
        float r = length(diff);

        if (i == j)
            continue;
        if (r < 0.01)
            r = 0.01;
        if (density < 10)
            density = 10;
        vec3 dir = diff / r;
        float mass = info.mass;
        local_velocity += dir * mass * vel.data[j] * second_derivative(r) / density;
    }
    return local_velocity * info.viscosity;
}
void apply_viscous_force(float delta) {
    vel.data[gl_GlobalInvocationID.x] += calc_viscosity_force(gl_GlobalInvocationID.x) * delta;
}

void apply_gravity(float delta) {
    vel.data[gl_GlobalInvocationID.x].y -= info.gravity * delta;
}

void check_boundaries(uint i, float elasticity, vec3 bounds) {
    vec3 half_bounds = bounds / 2;
    if (abs(pos.data[i].x) > half_bounds.x) {
        pos.data[i].x = half_bounds.x * sign(pos.data[i].x);
        vel.data[i].x *= -elasticity;
    }
    if (abs(pos.data[i].y) > half_bounds.y) {
        pos.data[i].y = half_bounds.y * sign(pos.data[i].y);
        vel.data[i].y *= -elasticity;
    }
    if (abs(pos.data[i].z) > half_bounds.z) {
        pos.data[i].z = half_bounds.z * sign(pos.data[i].z);
        vel.data[i].z *= -elasticity;
    }
}

void move_particle(float delta) {
    pos.data[gl_GlobalInvocationID.x] += vel.data[gl_GlobalInvocationID.x] * delta;
}

void main() {
    vec3 bounds = vec3(info.xbound, info.ybound, info.zbound);
    apply_gravity(info.delta);
    apply_pressure_force(info.delta);
    apply_viscous_force(info.delta);
    check_boundaries(gl_GlobalInvocationID.x, info.elasticity, bounds);
    move_particle(info.delta);
    imageStore(output_img, ivec2(gl_GlobalInvocationID.x, 0), vec4(pos.data[gl_GlobalInvocationID.x] + bounds / 2, 0));
}
