#version 430 compatibility

in vec4 at_tangent;

out vec2 texCoord;
out vec3 normal;
out vec3 tangent;
out vec3 bitangent;
out vec3 position;

uniform mat4 gbufferModelViewInverse;

void main() {
    vec4 viewPos = gl_ModelViewMatrix * gl_Vertex;
    gl_Position = gl_ProjectionMatrix * viewPos;

    position = (gbufferModelViewInverse * viewPos).xyz;
    texCoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
    normal = mat3(gbufferModelViewInverse) * gl_NormalMatrix * gl_Normal;
    tangent = mat3(gbufferModelViewInverse) * gl_NormalMatrix * at_tangent.xyz;
    bitangent = mat3(gbufferModelViewInverse) * gl_NormalMatrix * (cross(tangent, normal) * at_tangent.w);
}
