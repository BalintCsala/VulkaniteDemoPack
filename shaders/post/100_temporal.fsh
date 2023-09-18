#version 430

#include "/lib/settings.glsl"
#include "/lib/utils.glsl"
#include "/lib/smootherstep.glsl"

in vec2 texCoord;

uniform int frameCounter;

uniform sampler2D colortex0;
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

/*
const int colortex0Format = RGBA32F;
const int colortex1Format = RGBA32F;
const int colortex2Format = RGBA32F;
const bool colortex1Clear = false;
const bool colortex2Clear = false;
*/

/* RENDERTARGETS: 0,1,2 */
layout(location = 0) out vec4 fragColor;
layout(location = 1) out vec4 prevOutput;
layout(location = 2) out vec4 prevDepthOut;

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
    vec3 screenPos = vec3(texCoord, texture(depthtex0, texCoord).x);
    vec4 currColor = texture(colortex0, texCoord);
    vec4 newColor;
    #if ACCUMULATION_TYPE == 0
        vec4 prevColor = texture(colortex1, texCoord);
        newColor = mix(prevColor, currColor, 1.0 / float(frameCounter));
    #elif ACCUMULATION_TYPE == 1
        vec3 prevScreenPos = reproject(screenPos);
        float prevDepth = texture(colortex2, prevScreenPos.xy).x;
        if (abs(linearizeDepth(prevScreenPos.z, near, far) - linearizeDepth(prevDepth, near, far)) > 0.1) {
            newColor = currColor;
            newColor.a = 1.0;
        } else if (clamp(prevScreenPos.xy, 0.0, 1.0) != prevScreenPos.xy) {
            newColor = currColor;
            newColor.a = 1.0;
        } else {
            vec4 prevColor = texture(colortex1, prevScreenPos.xy);
            float weight = min(prevColor.a + 1.0, ACCUMULATION_LENGTH);
            newColor = mix(prevColor, currColor, 1.0 / weight);
            newColor.a = weight;
        }
    #endif

    prevOutput = newColor;
    prevDepthOut = vec4(screenPos.z);

    fragColor = newColor;
}