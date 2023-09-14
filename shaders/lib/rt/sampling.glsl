#ifndef SAMPLING_GLSL
#define SAMPLING_GLSL

#include "/lib/rand.glsl"
#include "/lib/constants.glsl"

vec3 cosineWeightedHemisphereSample(vec3 normal) {
    vec2 v = randVec2();
    float angle = 2.0 * PI * v.x;
    float u = 2.0 * v.y - 1.0;

    vec3 directionOffset = vec3(sqrt(1.0 - u * u) * vec2(cos(angle), sin(angle)), u);
    return normalize(normal + directionOffset);
}

#endif // SAMPLING_GLSL