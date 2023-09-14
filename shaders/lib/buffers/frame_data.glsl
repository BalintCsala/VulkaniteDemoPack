#ifndef FRAME_DATA_GLSL
#define FRAME_DATA_GLSL

layout(std430, binding = 0) buffer frameData {
    float avgExposure;
};

#endif // FRAME_DATA_GLSL