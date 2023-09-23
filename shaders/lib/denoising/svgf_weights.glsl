#ifndef SVGF_WEIGHTS_GLSL
#define SVGF_WEIGHTS_GLSL

const float NORMAL_PARAM = 128.0;
const float POSITION_PARAM = 10.0;
const float LUMINANCE_PARAM = 4.0;

float svgfNormalWeight(vec3 centerNormal, vec3 normal) {
    return pow(max(dot(centerNormal, normal), 0.0), NORMAL_PARAM);
}

float svgfPositionWeight(vec3 centerPos, vec3 pixelPos, vec3 normal) {
    // Modified to check for distance from the center plane 
    return exp(-POSITION_PARAM * abs(dot(pixelPos - centerPos, normal)));
}

#endif // SVGF_WEIGHTS_GLSL