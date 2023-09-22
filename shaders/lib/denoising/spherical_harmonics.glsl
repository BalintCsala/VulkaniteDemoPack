#ifndef SPHERICAL_HARMONICS_GLSL
#define SPHERICAL_HARMONICS_GLSL

#include "/lib/constants.glsl"

struct SHCoeffs {
    mat3x4 coeffs;
}; // 3 * 4 * 4 = 48 bytes

const float SQRT_1_PI = sqrt(1.0 / PI);
const float SQRT_3_PI = sqrt(3.0 / PI);
const float SQRT_5_PI = sqrt(5.0 / PI);
const float SQRT_15_PI = sqrt(15.0 / PI);

const float SH_0_COEFF = 0.5 * SQRT_1_PI;

const float SH_1_COEFF = 0.5 * SQRT_3_PI;
const float SH_2_COEFF = 0.5 * SQRT_3_PI;
const float SH_3_COEFF = 0.5 * SQRT_3_PI;

SHCoeffs encodeSH(vec3 direction, vec3 color) {
    return SHCoeffs(transpose(mat4x3(
        color * SH_0_COEFF,
        color * (SH_1_COEFF * direction.y),
        color * (SH_2_COEFF * direction.z),
        color * (SH_3_COEFF * direction.x)
    )));
}

vec3 decodeSH(SHCoeffs sh, vec3 direction) {
    mat4x3 coeffs = transpose(sh.coeffs);
    return (
        coeffs[0] * SH_0_COEFF +
        coeffs[1] * (SH_1_COEFF * direction.y) +
        coeffs[2] * (SH_2_COEFF * direction.z) +
        coeffs[3] * (SH_3_COEFF * direction.x)
    ) * PI;
}

SHCoeffs blendSH(SHCoeffs sh1, SHCoeffs sh2, float blendFactor) {
    return SHCoeffs(
        sh1.coeffs * (1.0 - blendFactor) + sh2.coeffs * blendFactor
    );
}

#endif // SPHERICAL_HARMONICS_GLSL