#ifndef RT_OUTPUT_GLSL
#define RT_OUTPUT_GLSL

#include "/lib/rt/data_point.glsl"

layout(std430, set = 0, binding = 7) buffer RTOutputBuffer {
    DataPoint data[];
} rtOutput; // Total: 1920 * 1080 * 2 * 80 = 331,776,000 bytes

#include "/lib/buffers/rt_output_helpers.glsl"

#endif // RT_OUTPUT_GLSL