#version 430

uniform sampler2D gtexture;

in vec2 texCoord;

/* RENDERTARGETS: 9 */
layout(location = 0) out vec4 fragColor;

void main() {
    fragColor = texture(gtexture, texCoord);
}
