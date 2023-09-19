#ifndef FRAGMENT_INFO_GLSL
#define FRAGMENT_INFO_GLSL

#include "/lib/rt/data.glsl"

struct FragmentInfo {
    vec2 uv;
    vec3 tangent;
    vec3 bitangent;
    vec3 normal;
};

vec2 getFragmentUV(Quad quad, vec3 baryCoords, bool isSideA) {
    vec2 t0 = (quad.vertices[0].block_texture) / 65536.0;
    vec2 t1 = (isSideA ? quad.vertices[1].block_texture : quad.vertices[2].block_texture) / 65536.0;
    vec2 t2 = (isSideA ? quad.vertices[2].block_texture : quad.vertices[3].block_texture) / 65536.0;
    return t0 * baryCoords.x + t1 * baryCoords.y + t2 * baryCoords.z;
}

vec2 getFragmentUV(Quad quad, vec2 baryCoords) {
    bool isSideA = (gl_PrimitiveID & 1) == 0;
    vec3 barys = vec3(1.0 - baryCoords.x - baryCoords.y, baryCoords.x, baryCoords.y);
    return getFragmentUV(quad, barys, isSideA);
}

FragmentInfo getFragmentInfo(Quad quad, vec2 baryCoords) {
    bool isSideA = (gl_PrimitiveID & 1) == 0;

    vec3 n0 = quad.vertices[0].normal / 128.0;
    vec3 n1 = (isSideA ? quad.vertices[1].normal : quad.vertices[2].normal) / 128.0;
    vec3 n2 = (isSideA ? quad.vertices[2].normal : quad.vertices[3].normal) / 128.0;

    vec3 t0 = quad.vertices[0].tangent.xyz / 128.0;
    vec3 t1 = (isSideA ? quad.vertices[1].tangent.xyz : quad.vertices[2].tangent.xyz) / 128.0;
    vec3 t2 = (isSideA ? quad.vertices[2].tangent.xyz : quad.vertices[3].tangent.xyz) / 128.0;

    vec3 barys = vec3(1.0 - baryCoords.x - baryCoords.y, baryCoords.x, baryCoords.y);
    vec2 uv = getFragmentUV(quad, barys, isSideA);
    vec3 normal = normalize(n0 * barys.x + n1 * barys.y + n2 * barys.z);
    vec3 tangent = normalize(t0 * barys.x + t1 * barys.y + t2 * barys.z);
    //vec3 normal = quad.vertices[0].normal / 128.0;
    //vec3 tangent = quad.vertices[0].tangent.xyz / 128.0;
    vec3 bitangent = cross(tangent, normal) * (quad.vertices[0].tangent.w / 128.0);
    return FragmentInfo(uv, tangent, bitangent, normal);
}

#endif // FRAGMENT_INFO_GLSL