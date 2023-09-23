#version 430

#ifndef VULKANITE
#include "/lib/no_vulkanite.glsl"
#else

#include "/lib/tonemap.glsl"
#include "/lib/buffers/sh_swap.glsl"

in vec2 texCoord;

uniform sampler2D depthtex0;
uniform sampler2D colortex3;
uniform sampler2D colortex4;

layout(rg32f) uniform image2D temporalData;

uniform int frameCounter;

/* RENDERTARGETS: 0 */
layout(location = 0) out vec4 fragColor;

void main() {
    float depth = texture(depthtex0, texCoord).x;
    if (depth == 1.0) {
        fragColor = vec4(0, 0, 0, 1);
        return;
    }
    vec3 normal = texture(colortex3, texCoord).xyz;
    SHCoeffs sh = shSwap.data[getSwapIndex(uvec2(gl_FragCoord.xy) / 2u, 0u)];

    fragColor.a = 1.0;
    fragColor.rgb = decodeSH(sh, normal) * 10.0;
    fragColor.rgb = ACESFilm(fragColor.rgb);
    fragColor.rgb = pow(fragColor.rgb, vec3(1.0 / 2.2));
}

#endif