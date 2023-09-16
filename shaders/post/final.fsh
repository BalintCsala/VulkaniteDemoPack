#version 430

//#ifndef VULKANITE
//#include "/lib/no_vulkanite.glsl"
//#elif

#include "/lib/tonemap.glsl"

in vec2 texCoord;

uniform sampler2D colortex0;
uniform sampler2D colortex1;

/* RENDERTARGETS: 0 */
layout(location = 0) out vec4 fragColor;

void main() {
    fragColor = texture(colortex0, texCoord);
    fragColor.rgb = ACESFilm(fragColor.rgb);
    fragColor.rgb = pow(fragColor.rgb, vec3(1.0 / 2.2));
}

//#endif