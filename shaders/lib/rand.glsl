#ifndef RAND_GLSL
#define RAND_GLSL

uint state;

uint rand() {
	state = (state << 13U) ^ state;
    state = state * (state * state * 15731U + 789221U) + 1376312589U;
    return state;
}

float randFloat() {
    return float(rand() & uvec3(0x7fffffffU)) / float(0x7fffffff);
}

vec2 randVec2() {
    return vec2(randFloat(), randFloat());
}

void initRNG(uvec2 pixel, uint frame) {
    state = frame;
    state = (pixel.x + pixel.y * 14352113u) ^ rand();
    rand();
}

#endif // RAND_GLSL