#ifndef DATA_POINT_GLSL
#define DATA_POINT_GLSL

#include "/lib/denoising/spherical_harmonics.glsl"

struct DataPoint {
    SHCoeffs diffuse;
    vec4 specular;
    vec4 refraction;
}; // Total: 80 bytes

#endif // DATA_POINT_GLSL