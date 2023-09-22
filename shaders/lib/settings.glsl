#ifndef SETTINGS_GLSL
#define SETTINGS_GLSL

#define RAY_BOUNCES 5 // Number of times the ray bounces before stopping. Larger values lead to better image quality but lower performance. [2 3 4 5 6 7]
#define ACCUMULATION_LENGTH 8 // Number of frames to accumulate before displaying the result, only applies when accumulation is set to "Reprojection". Larger values result in smoother images, but more ghosting with lights. [1 2 3 4 5 6 7 8 9 10]
#define ACCUMULATION_TYPE 1 // Type of the accumulation [0 1]

const float sunPathRotation = 30.0;

/*
// Normals
const int colortex3Format = RGBA32F;
// Geometry normals
const int colortex4Format = RGBA32F;

const int colortex0Format = RGBA32F;
const int colortex1Format = RGBA32F;
const int colortex2Format = RGBA32F;
const bool colortex1Clear = false;
const bool colortex2Clear = false;
*/

#endif // SETTINGS_GLSL