#[compute]
#version 450

#include "utils.glsl"

float calc_density_comp(uint i, uint j) {
    float r = compute_distance(pos.data[i], pos.data[j]);
    return smoothing_func(r);
}

void set_density(uint i) {
    float density = 0;

    for (int j = 0; j < 1024; j++) {
        if (i == j)
            continue;
        density += calc_density_comp(i, j);
    }

    densities.data[i] = density * 3 / 4;
}

void main() {
    set_density(gl_GlobalInvocationID.x);
}
