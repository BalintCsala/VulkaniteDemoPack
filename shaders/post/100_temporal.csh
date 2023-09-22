#version 430

layout(local_size_x = 8, local_size_y = 8) in;
const vec2 workGroupsRender = vec2(0.5, 0.5);

#include "/lib/settings.glsl"
#include "/lib/utils.glsl"
#include "/lib/denoising/spherical_harmonics.glsl"
#include "/lib/denoising/temporal_helpers.glsl"

#include "/lib/buffers/rt_output_iris.glsl"

uniform sampler2D colortex1;
uniform sampler2D colortex2;
uniform sampler2D depthtex0;

uniform mat4 gbufferProjectionInverse;
uniform mat4 gbufferModelViewInverse;
uniform vec3 cameraPosition;

uniform mat4 gbufferPreviousProjection;
uniform mat4 gbufferPreviousModelView;
uniform vec3 previousCameraPosition;

uniform float near;
uniform float far;
uniform vec2 resolution;
uniform int frameCounter;

vec3 reproject(vec3 screenPos) {
    vec4 tmp = gbufferProjectionInverse * vec4(screenPos * 2.0 - 1.0, 1.0);
    vec3 viewPos = tmp.xyz / tmp.w;
    vec3 playerPos = (gbufferModelViewInverse * vec4(viewPos, 1.0)).xyz;
    vec3 worldPos = playerPos + cameraPosition;
    vec3 prevPlayerPos = worldPos - previousCameraPosition;
    vec3 prevViewPos = (gbufferPreviousModelView * vec4(prevPlayerPos, 1.0)).xyz;
    vec4 prevClipPos = gbufferPreviousProjection * vec4(prevViewPos, 1.0);
    return prevClipPos.xyz / prevClipPos.w * 0.5 + 0.5;
}

void main() {
    ivec2 coord = ivec2(gl_GlobalInvocationID.xy);

    vec2 halfRes = resolution / 2.0;

    vec2 texCoord = vec2(coord) / halfRes;
    float depth = texture(depthtex0, texCoord).x;

    if (frameCounter < 2 || depth == 1.0) {
        return;
    }
    vec3 screenPos = vec3(texCoord, depth);

    uint index = getIndex(coord, uint(frameCounter));
    SHCoeffs diffuseCoeffs = rtOutput.data[index].diffuse;

    vec3 prevScreenPos = reproject(screenPos);
    TemporalData temporal = bilinearReadTemporalData(prevScreenPos.xy * halfRes, frameCounter, resolution);
    float prevDepth = temporal.depth;
    float currDepthLinear = linearizeDepth(prevScreenPos.z, near, far);
    float prevDepthLinear = linearizeDepth(prevDepth, near, far);

    float weight;
    if (clamp(prevScreenPos.xy, 0.0, 1.0) == prevScreenPos.xy &&
            abs(currDepthLinear - prevDepthLinear) < 0.05 * currDepthLinear) {

        float totalWeight = min(temporal.weight + 1.0, ACCUMULATION_LENGTH);
        SHCoeffs prevDiffuseCoeffs = sampleCoeffs(prevScreenPos.xy * halfRes, uint(frameCounter - 1));

        diffuseCoeffs = blendSH(prevDiffuseCoeffs, diffuseCoeffs, 1.0 / totalWeight);
        rtOutput.data[index].diffuse = diffuseCoeffs;
        weight = totalWeight;
    } else {
        weight = 1.0;
    }
    writeTemporalData(TemporalData(depth, weight), coord, frameCounter, resolution);
}