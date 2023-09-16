#ifndef LIGHT_COLOR_GLSL
#define LIGHT_COLOR_GLSL

const vec3 TOP_COLOR = vec3(0.017, 0.011, 0.773);
const vec3 BOTTOM_COLOR = pow(vec3(0.5, 0.52, 0.87), vec3(2.2));
const vec3 FOG_COLOR = pow(vec3(0.69, 0.7, 0.86), vec3(2.2));
const vec3 GROUND_COLOR = pow(vec3(0.33, 0.31, 0.29), vec3(2.2));
const vec3 SUNSET_COLOR = pow(vec3(1.2, 0.18, 0), vec3(2.2));
const vec3 SUNSET_PURPLE = pow(vec3(0.77, 0.02, 0.3), vec3(2.2));
const vec3 SUNSET_TOP = pow(vec3(0.23, 0, 0.56), vec3(2.2));

vec3 getSkyColor(vec3 direction, vec3 sunDir) {
    vec3 noonColor;
    {
        vec3 skyColor = mix(BOTTOM_COLOR, TOP_COLOR, direction.y);
        skyColor = mix(FOG_COLOR, skyColor, smoothstep(0.0, 0.1, direction.y) * 0.5 + 0.5);
        noonColor = mix(GROUND_COLOR, skyColor, smoothstep(-0.05, 0.0, direction.y));
    }
    vec3 sunsetColor;
    {
        vec3 skyColor = mix(BOTTOM_COLOR, SUNSET_TOP, direction.y);
        vec3 fogColor = mix(SUNSET_PURPLE, SUNSET_COLOR, smoothstep(0.3, 0.95, dot(sunDir, direction) * 0.5 + 0.5));
        fogColor = mix(FOG_COLOR, fogColor, smoothstep(0.2, 0.6 + direction.y, dot(sunDir, direction)) * 0.5 + 0.5);
        skyColor = mix(fogColor, skyColor, smoothstep(0.0, 0.6, direction.y) * 0.5 + 0.5);
        sunsetColor = mix(GROUND_COLOR, skyColor, smoothstep(-0.05, 0.0, direction.y));
    }
    vec3 nightColor = vec3(0, 0, 0.0000001);

    float time = sunDir.y / 0.9;
    vec3 color = noonColor;
    color = mix(sunsetColor, color, smoothstep(0.0, 0.1, time));
    color = mix(nightColor, color, pow(smoothstep(-0.8, 0.0, time), 20.0));

    return color;
}

const vec3 NORMAL_LIGHT_COLOR = pow(vec3(1, 0.95, 0.9), vec3(2.2));
const vec3 SUNSET_LIGHT_COLOR = pow(vec3(1, 0.51, 0.15), vec3(2.2));
const vec3 NIGHT_LIGHT_COLOR = pow(vec3(0.1, 0.1, 0.1), vec3(2.2));

vec3 getSunColor(vec3 sunDir) {
    float time = sunDir.y;
    vec3 color = NORMAL_LIGHT_COLOR;
    color = mix(SUNSET_LIGHT_COLOR, color, smoothstep(0.0, 0.2, time));
    color = mix(NIGHT_LIGHT_COLOR, color, smoothstep(-0.2, 0.0, time));

    return color;
}

#endif // LIGHT_COLOR_GLSL