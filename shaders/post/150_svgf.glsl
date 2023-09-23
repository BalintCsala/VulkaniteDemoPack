layout(local_size_x = 8, local_size_y = 8) in;
const vec2 workGroupsRender = vec2(0.5, 0.5);

#include "/lib/denoising/spherical_harmonics.glsl"
#include "/lib/denoising/svgf_weights.glsl"

#include "/lib/buffers/rt_output_iris.glsl"
#include "/lib/buffers/sh_swap.glsl"

// Normals
uniform sampler2D colortex4;
uniform sampler2D colortex5;

uniform int frameCounter;
uniform vec2 resolution;

const float WEIGHTS[] = float[](0.25, 0.5, 0.25);
const int RADIUS = 1;

void main() {
    ivec2 pixel = ivec2(gl_GlobalInvocationID.xy);
    vec3 centerNormal = texelFetch(colortex4, pixel * 2, 0).xyz;
    vec3 centerPos = texelFetch(colortex5, pixel * 2, 0).xyz;

    SHCoeffs result = SHCoeffs(mat3x4(0.0));
    float totalWeight = 0.0;
    for (int x = -RADIUS; x <= RADIUS; x++) {
        for (int y = -RADIUS; y <= RADIUS; y++) {
            ivec2 pos = pixel + ivec2(x, y) * STEP_SIZE;
            if (pos.x < 0 || pos.y < 0 || pos.x >= resolution.x / 2.0 - 1 || pos.y >= resolution.y / 2.0 - 1) 
                continue;
                
            vec3 normal = texelFetch(colortex4, pos * 2, 0).xyz;
            vec3 position = texelFetch(colortex5, pos * 2, 0).xyz;

            float normalWeight = svgfNormalWeight(centerNormal, normal);
            float positionWeight = svgfPositionWeight(centerPos, position, normal);
            float weight = WEIGHTS[x + RADIUS] * WEIGHTS[y + RADIUS] * normalWeight * positionWeight;

            #if SVGF_STEP == 1
                // For the second step we read from rt output
                SHCoeffs sh = rtOutput.data[getIndex(uvec2(pos), uint(frameCounter))].diffuse;
            #else
                // In the others we read from the previous swap output
                SHCoeffs sh = shSwap.data[getSwapIndex(uvec2(pos), (SVGF_STEP + 1) % 2)];
            #endif
            result.coeffs += sh.coeffs * weight;
            totalWeight += weight;
        }
    }
    if (totalWeight <= 0.0)
        return;
    result.coeffs /= totalWeight;
    #if SVGF_STEP == 0
        // For the first step we otput to rt output to make filtering easier
        rtOutput.data[getIndex(uvec2(pixel), uint(frameCounter))].diffuse = result;
    #else
        // In the rest of the steps we just go back and forth between sh swap
        shSwap.data[getSwapIndex(uvec2(pixel), SVGF_STEP % 2)] = result;
    #endif
}