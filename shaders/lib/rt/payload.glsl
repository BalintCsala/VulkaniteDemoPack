#ifndef PAYLOAD_GLSL
#define PAYLOAD_GLSL

struct Payload {
    vec4 color;
    vec4 hitData;
    vec3 geometryNormal;
    vec3 normal;
    float emission;
};

#endif // PAYLOAD_GLSL