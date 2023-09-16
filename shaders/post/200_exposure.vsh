#version 430 compatibility

#include "/lib/buffers/frame_data.glsl"
#include "/lib/colors.glsl"
#include "/lib/settings.glsl"

uniform sampler2D colortex0;
uniform int frameCounter;

out vec2 texCoord;

struct Sample {
    vec2 position;
    float weight;
};

const Sample[] samples = Sample[](
    Sample(vec2(0.5, 0.5), 0.2),
    Sample(vec2(0.35, 0.5), 0.1),
    Sample(vec2(0.65, 0.5), 0.1),
    Sample(vec2(0.5, 0.35), 0.1),
    Sample(vec2(0.5, 0.65), 0.1),
    Sample(vec2(0.25, 0.5), 0.07),
    Sample(vec2(0.75, 0.5), 0.07),
    Sample(vec2(0.5, 0.25), 0.07),
    Sample(vec2(0.5, 0.75), 0.07),
    Sample(vec2(0.25, 0.25), 0.03),
    Sample(vec2(0.75, 0.25), 0.03),
    Sample(vec2(0.25, 0.75), 0.03),
    Sample(vec2(0.75, 0.75), 0.03)
);

void main() {
    if (gl_VertexID == 0) {
        float luminanceSum = 0.0;    
        for (int i = 0; i < samples.length(); i++) {
            luminanceSum += luminance(texture(colortex0, samples[i].position).rgb) * samples[i].weight;
        }
        float exposure = clamp(calculateExposure(luminanceSum), 1.0, 500000.0);
        if (frameCounter <= 1) {
            avgExposure = exposure;
        } else {
            avgExposure = exp(mix(
                log(avgExposure), 
                log(exposure), 
                max(1.0 / float(frameCounter + 1), 0.005)
            ));
        }
    }

    gl_Position = gl_ModelViewProjectionMatrix * gl_Vertex;
    texCoord = gl_MultiTexCoord0.xy;
}