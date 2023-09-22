layout(local_size_x = 8, local_size_y = 8) in;
const vec2 workGroupsRender = vec2(0.5, 0.5);

#include "/lib/denoising/spherical_harmonics.glsl"

#include "/lib/buffers/rt_output_iris.glsl"
#include "/lib/buffers/sh_swap.glsl"

// Normals
uniform sampler2D colortex4;

uniform int frameCounter;
uniform vec2 resolution;

const float WEIGHTS[] = float[](0.25, 0.5, 0.25);
const int RADIUS = 1;

void main() {
    ivec2 pixel = ivec2(gl_GlobalInvocationID.xy);
    uint frameId = uint(frameCounter);
    vec3 centerNormal = texelFetch(colortex4, pixel * 2, 0).xyz;

    SHCoeffs result = SHCoeffs(mat3x4(0.0));
    float totalWeight = 0.0;
    for (int x = -RADIUS; x <= RADIUS; x++) {
        for (int y = -RADIUS; y <= RADIUS; y++) {
            ivec2 pos = pixel + ivec2(x, y) * STEP_SIZE;
            if (pos.x < 0 || pos.y < 0 || pos.x > resolution.x / 2.0 || pos.y > resolution.y / 2.0) 
                continue;
                
            vec3 normal = texelFetch(colortex4, pos * 2, 0).xyz;
            float weight = WEIGHTS[x + RADIUS] * WEIGHTS[y + RADIUS] * max(dot(centerNormal, normal), 0.0);

            #ifdef SWAP
                SHCoeffs sh = shSwap.data[getSwapIndex(uvec2(pos))];
            #else
                SHCoeffs sh = rtOutput.data[getIndex(uvec2(pos), frameId)].diffuse;
            #endif
            result.coeffs += sh.coeffs * weight;
            totalWeight += weight;
        }
    }
    if (totalWeight <= 0.0)
        return;
    result.coeffs /= totalWeight;
    #ifdef SWAP
        rtOutput.data[getIndex(uvec2(pixel), frameId)].diffuse = result;
    #else
        shSwap.data[getSwapIndex(uvec2(pixel))] = result;
    #endif
}