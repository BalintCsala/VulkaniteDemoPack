#version 430

#include "/lib/settings.glsl"

in vec2 texCoord;

uniform int frameCounter;

uniform sampler2D colortex0;
uniform sampler2D colortex1;
uniform sampler2D colortex2;
uniform sampler2D depthtex1;

uniform mat4 gbufferProjectionInverse;
uniform mat4 gbufferModelViewInverse;
uniform vec3 cameraPosition;

uniform mat4 gbufferPreviousProjection;
uniform mat4 gbufferPreviousModelView;
uniform vec3 previousCameraPosition;

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

void main() {
    vec3 screenPos = vec3(texCoord, texture(depthtex1, texCoord).x);
    vec4 currColor = texture(colortex0, texCoord);
    vec4 newColor;
    #if ACCUMULATION_TYPE == 0
        vec4 prevColor = texture(colortex1, texCoord);
        newColor = mix(prevColor, currColor, 1.0 / float(frameCounter + 1));
    #elif ACCUMULATION_TYPE == 1
        vec4 tmp = gbufferProjectionInverse * vec4(screenPos * 2.0 - 1.0, 1.0);
        vec3 viewPos = tmp.xyz / tmp.w;
        vec3 playerPos = (gbufferModelViewInverse * vec4(viewPos, 1.0)).xyz;
        vec3 worldPos = playerPos + cameraPosition;
        vec3 prevPlayerPos = worldPos - previousCameraPosition;
        vec3 prevViewPos = (gbufferPreviousModelView * vec4(prevPlayerPos, 1.0)).xyz;
        vec4 prevClipPos = gbufferPreviousProjection * vec4(prevViewPos, 1.0);
        vec3 prevScreenPos = prevClipPos.xyz / prevClipPos.w * 0.5 + 0.5;
        float prevDepth = texture(colortex2, prevScreenPos.xy).x;
        if (abs(1.0 / (1.005 - prevScreenPos.z) - 1.0 / (1.005 - prevDepth)) > 0.1) {
            newColor = currColor;
        } else if (clamp(prevScreenPos.xy, 0.0, 1.0) != prevScreenPos.xy) {
            newColor = currColor;
        } else {
            vec4 prevColor = texture(colortex1, prevScreenPos.xy);
            newColor = mix(prevColor, currColor, max(1.0 / float(frameCounter + 1), 1.0 / ACCUMULATION_LENGTH));
        }
    #endif

    prevOutput = newColor;
    prevDepthOut = vec4(screenPos.z);

    fragColor = newColor;
}