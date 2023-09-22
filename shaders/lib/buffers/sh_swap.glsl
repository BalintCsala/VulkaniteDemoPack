#ifndef SH_SWAP_GLSL
#define SH_SWAP_GLSL

#include "/lib/denoising/spherical_harmonics.glsl"

layout(std430, binding = 2) buffer SHSwap {
    SHCoeffs data[];
} shSwap; // Total: 1920 * 1080 * 48 = 99,532,800 bytes

uint getSwapIndex(uvec2 coord) {
    return coord.y * 1920u + coord.x;
}

#endif // SH_SWAP_GLSL