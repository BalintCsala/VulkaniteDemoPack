#ifndef RT_OUTPUT_HELPERS_GLSL
#define RT_OUTPUT_HELPERS_GLSL

uint getIndex(uvec2 coord, uint frameId) {
    return (coord.y * 1920u + coord.x) * 2u + frameId % 2u;
}

void writeDiffuse(SHCoeffs coeffs, uvec2 coord, uint frameId) {
    uint index = getIndex(coord / 2, frameId);
    rtOutput.data[index].diffuse = coeffs;
}

void writeSpecular(vec3 radiance, float secondaryDist, uvec2 coord, uint frameId) {
    uint index = getIndex(coord / 2, frameId);
    rtOutput.data[index].specular = vec4(radiance, secondaryDist);
}

SHCoeffs sampleCoeffs(vec2 fragPos, uint frameId) {
    uvec2 pixel = uvec2(fragPos);
    vec2 frac = fract(fragPos);
    SHCoeffs sh00 = rtOutput.data[getIndex(pixel + uvec2(0, 0), frameId)].diffuse;
    SHCoeffs sh10 = rtOutput.data[getIndex(pixel + uvec2(1, 0), frameId)].diffuse;
    SHCoeffs sh01 = rtOutput.data[getIndex(pixel + uvec2(0, 1), frameId)].diffuse;
    SHCoeffs sh11 = rtOutput.data[getIndex(pixel + uvec2(1, 1), frameId)].diffuse;

    return blendSH(
        blendSH(sh00, sh10, frac.x),
        blendSH(sh01, sh11, frac.x),
        frac.y
    );
}

#endif // RT_OUTPUT_HELPERS_GLSL