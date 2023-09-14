#version 430

#include "/lib/buffers/frame_data.glsl"

in vec2 texCoord;

uniform sampler2D colortex0;

/* RENDERTARGETS: 0 */
layout(location = 0) out vec4 fragColor;

void main() {
    fragColor = texture(colortex0, texCoord);
    fragColor.rgb *= avgExposure;
}
