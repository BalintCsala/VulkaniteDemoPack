#version 460
#extension GL_EXT_ray_tracing : require
#extension GL_EXT_shader_explicit_arithmetic_types_int64 : require
#extension GL_EXT_buffer_reference : require
#extension GL_EXT_shader_16bit_storage : require
#extension GL_EXT_shader_8bit_storage : require
#extension GL_EXT_shader_explicit_arithmetic_types : require

#include "/lib/rt/data.glsl"
#include "/lib/rt/payload.glsl"
#include "/lib/rt/fragment_info.glsl"
#include "/lib/pbr/material.glsl"

layout(location = 6) rayPayloadInEXT Payload payload;

layout(buffer_reference) buffer Quads {
    Quad quads[]; 
};

layout(buffer_reference) buffer BawBuffer {
    uint8_t data[]; 
};
hitAttributeEXT vec2 baryCoord;

layout(std140, binding = 0) uniform CameraInfo {
    vec3 corners[4];
    mat4 viewInverse;
    vec3 sunAngle;
} cam;

layout(binding = 2) buffer BlasDataAddresses { uint64_t address[]; } geometryReference;

layout(binding = 4) uniform  sampler2D blockTex;
layout(binding = 5) uniform  sampler2D blockTexNormal;
layout(binding = 6) uniform  sampler2D blockTexSpecular;

Quad getRayQuad() {
    return Quads(geometryReference.address[gl_InstanceCustomIndexEXT + gl_GeometryIndexEXT]).quads[gl_PrimitiveID>>1];
}


void main() {
    vec3 worldPos = gl_WorldRayOriginEXT + gl_HitTEXT * gl_WorldRayDirectionEXT;
    Quad quad = getRayQuad();

    FragmentInfo fragInfo = getFragmentInfo(quad, baryCoord);
    vec4 shadeColor = quad.vertices[0].color / 255.0;

    vec4 specular = texture(blockTexSpecular, fragInfo.uv);
    vec4 normal = texture(blockTexNormal, fragInfo.uv);
    vec4 albedo = texture(blockTex, fragInfo.uv);
    albedo.rgb = pow(albedo.rgb * shadeColor.rgb, vec3(2.2));

    mat3 tbn = mat3(
        fragInfo.tangent,
        fragInfo.bitangent,
        fragInfo.normal
    );

    payload.hitData = vec4(worldPos, gl_HitTEXT);
    payload.geometryNormal = fragInfo.normal;
    payload.material = getMaterial(albedo, normal, specular, tbn);
}