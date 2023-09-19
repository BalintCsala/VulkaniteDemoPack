#ifndef PAYLOAD_GLSL
#define PAYLOAD_GLSL

#include "/lib/pbr/material.glsl"

struct Payload {
    vec4 hitData;
    vec3 geometryNormal;
    Material material;
};

#endif // PAYLOAD_GLSL