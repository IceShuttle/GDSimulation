#[compute]
#version 450

//layout(local_size_x = 32, local_size_y = 32, local_size_z = 1) in;// invocation
//
layout(set = 0, binding = 0, std430) restrict buffer readonly Info {
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

layout(rgba16f, binding = 3) uniform image2D output_img;

void apply_gravity(float delta) {
    vel.data[gl_GlobalInvocationID.x].y -= 9.8 * delta;
}

void check_boundaries(float elastisity) {
    if (abs(0.5 - pos.data[gl_GlobalInvocationID.x].x) > .5) {
        vel.data[gl_GlobalInvocationID.x].x = -1 * vel.data[gl_GlobalInvocationID.x].x * elastisity;
    }
    if (abs(0.5 - pos.data[gl_GlobalInvocationID.x].y) > .5) {
        vel.data[gl_GlobalInvocationID.x].y = -1 * vel.data[gl_GlobalInvocationID.x].y * elastisity;
    }
    if (abs(0.5 - pos.data[gl_GlobalInvocationID.x].z) > .5) {
        vel.data[gl_GlobalInvocationID.x].z = -1 * vel.data[gl_GlobalInvocationID.x].z * elastisity;
    }
}

void move_particle(float delta) {
    pos.data[gl_GlobalInvocationID.x] += vel.data[gl_GlobalInvocationID.x] * delta;
}

void main() {
    apply_gravity(info.delta);
    check_boundaries(0.9);
    move_particle(info.delta);
    imageStore(output_img, ivec2(gl_GlobalInvocationID.x, 0), vec4(pos.data[gl_GlobalInvocationID.x], 0));
}
