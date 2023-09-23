#ifndef SH_SWAP_GLSL
#define SH_SWAP_GLSL

#include "/lib/denoising/spherical_harmonics.glsl"

layout(std430, binding = 2) buffer SHSwap {
    SHCoeffs data[];
} shSwap; // Total: 1920 * 1080 * 48 * 2 = 199,065,600 bytes

uint getSwapIndex(uvec2 coord, uint swapId) {
    return (coord.y * 1920u + coord.x) * 2u + swapId;
}

#endif // SH_SWAP_GLSL