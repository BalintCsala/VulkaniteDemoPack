#version 430

in vec4 color;

/* RENDERTARGETS: 9 */
layout(location = 0) out vec4 fragColor;

void main() {
    fragColor = color;
}
