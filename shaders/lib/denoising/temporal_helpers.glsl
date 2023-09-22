#ifndef TEMPORAL_HELPERS_GLSL
#define TEMPORAL_HELPERS_GLSL

layout(rg32f) uniform image2D temporalData;

struct TemporalData {
    float depth;
    float weight;
};

TemporalData bilinearReadTemporalData(vec2 fragPos, int frameCounter, vec2 resolution) {
    ivec2 offs = ivec2((frameCounter % 2) * int(resolution.x / 2.0), 0);
    ivec2 coord = ivec2(fragPos);
    vec2 frac = fract(fragPos);
    vec2 data00 = imageLoad(temporalData, coord + ivec2(0, 0) + offs).xy;
    vec2 data10 = imageLoad(temporalData, coord + ivec2(1, 0) + offs).xy;
    vec2 data01 = imageLoad(temporalData, coord + ivec2(0, 1) + offs).xy;
    vec2 data11 = imageLoad(temporalData, coord + ivec2(1, 1) + offs).xy;
    vec2 res = mix(
        mix(
            data00,
            data10,
            frac.x
        ),
        mix(
            data01,
            data11,
            frac.x
        ),
        frac.y
    );
    return TemporalData(res.x, res.y);
}

void writeTemporalData(TemporalData data, ivec2 coord, int frameCounter, vec2 resolution) {
    ivec2 offs = ivec2(((frameCounter + 1) % 2) * int(resolution.x / 2.0), 0);
    imageStore(temporalData, coord + offs, vec4(data.depth, data.weight, 0.0, 0.0));
}

#endif // TEMPORAL_HELPERS_GLSL