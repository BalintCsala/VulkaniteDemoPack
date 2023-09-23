#version 430

#include "/lib/settings.glsl"

uniform sampler2D gtexture;
uniform sampler2D normals;

in vec2 texCoord;
in vec3 normal;
in vec3 tangent;
in vec3 bitangent;
in vec3 position;

/* RENDERTARGETS: 3,4,5 */
layout(location = 0) out vec4 outNormal;
layout(location = 1) out vec4 outGeometryNormal;
layout(location = 2) out vec4 outFragPos;

void main() {
    vec4 color = texture(gtexture, texCoord);
    if (color.a < 0.1) {
        discard;
    }

    vec3 nNormal = normalize(normal);
    mat3 tbn = mat3(
        normalize(tangent),
        normalize(bitangent),
        nNormal
    );
    vec3 mappedNormal = texture(normals, texCoord).xyz;
    mappedNormal.z = sqrt(max(1.0 - dot(mappedNormal.xy, mappedNormal.xy), 0.0));

    outNormal = vec4(tbn * mappedNormal, 0.0);
    outGeometryNormal = vec4(nNormal, 0.0);
    outFragPos = vec4(position, 0.0);
}
