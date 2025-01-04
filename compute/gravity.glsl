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
    for(int j = 0; j < 1024; j++) {
        float r = compute_distance(pos.data[i], pos.data[j]);
        if(i == j || r < 0.1)
            continue;
        vec3 dir = (pos.data[i] - pos.data[j]) / r;
        float slope = derivative(r);
        float density = densities.data[i];
        if(density < 10)
            continue;
        force += -dir * density_to_pressure(density) * slope * info.mass / density;
    }
    return force;
}

void apply_pressure_force(float delta) {
    vel.data[gl_GlobalInvocationID.x] += (calc_pressure_force(gl_GlobalInvocationID.x) * delta) / 500;
}

vec3 calc_viscosity_force(uint i) {
    vec3 local_velocity = vec3(0, 0, 0);
    for(int j = 0; j < 1024; j++) {
        float density = densities.data[j];
        float r = compute_distance(pos.data[i], pos.data[j]);
        if(i == j || r < 0.1 || density < 10)
            continue;
        local_velocity += info.mass / density * vel.data[j] * smoothing_func(r);
    }
    vec3 dir = normalize(normalize(local_velocity) - normalize(vel.data[i]));
    // return dir * info.viscosity;
    return dir * 1;
}
void apply_viscous_force(float delta) {
    vel.data[gl_GlobalInvocationID.x] += calc_viscosity_force(gl_GlobalInvocationID.x) * delta;
}

void apply_gravity(float delta) {
    vel.data[gl_GlobalInvocationID.x].y -= info.gravity * delta;
}

void check_boundaries(uint i, float elasticity, vec3 bounds) {
    vec3 half_bounds = bounds / 2;
    if(abs(pos.data[i].x) > half_bounds.x) {
        pos.data[i].x = half_bounds.x * sign(pos.data[i].x);
        vel.data[i].x *= -elasticity;
    }
    if(abs(pos.data[i].y) > half_bounds.y) {
        pos.data[i].y = half_bounds.y * sign(pos.data[i].y);
        vel.data[i].y *= -elasticity;
    }
    if(abs(pos.data[i].z) > half_bounds.z) {
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
    // apply_viscous_force(info.delta);
    check_boundaries(gl_GlobalInvocationID.x, info.elasticity, bounds);
    move_particle(info.delta);
    imageStore(output_img, ivec2(gl_GlobalInvocationID.x, 0), vec4(pos.data[gl_GlobalInvocationID.x] + bounds / 2, 0));
}
