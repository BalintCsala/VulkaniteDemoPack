#version 430

#include "/lib/settings.glsl"

uniform sampler2D gtexture;
uniform sampler2D normals;

in vec2 texCoord;
in vec3 normal;
in vec3 tangent;
in vec3 bitangent;

/* RENDERTARGETS: 3,4 */
layout(location = 0) out vec4 outNormal;
layout(location = 1) out vec4 outGeometryNormal;

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

    outNormal = vec4(tbn * mappedNormal, 1.0);
    outGeometryNormal = vec4(nNormal, 1.0);
}
