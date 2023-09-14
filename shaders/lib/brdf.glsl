#ifndef BRDF_GLSL
#define BRDF_GLSL

#include "/lib/constants.glsl"
#include "/lib/quaternions.glsl"
#include "/lib/rand.glsl"

const vec3 PREDETERMINED_F0[] = vec3[](
    vec3(0.53123, 0.51236, 0.49583), // Iron
    vec3(0.94423, 0.77610, 0.37340), // Gold
    vec3(0.91230, 0.91385, 0.91968), // Aluminium
    vec3(0.55560, 0.55454, 0.55478), // Chrome
    vec3(0.92595, 0.72090, 0.50415), // Copper
    vec3(0.63248, 0.62594, 0.64148), // Lead
    vec3(0.67885, 0.64240, 0.58841), // Platinum
    vec3(0.96200, 0.94947, 0.92212)  // Silver
);

struct Material {
    vec3 albedo;
    vec3 F0;
    float metallic;
    float roughness;
    vec3 emission;
    vec3 normal;
};

vec3 cosineWeighted(vec3 normal) {
    vec2 v = randVec2();
    float angle = 2.0 * PI * v.x;
    float u = 2.0 * v.y - 1.0;

    vec3 directionOffset = vec3(sqrt(1.0 - u * u) * vec2(cos(angle), sin(angle)), u);
    return normalize(normal + directionOffset);
}

vec3 fresnelSchlick(vec3 F0, float cosTheta) {
    return F0 + (1.0 - F0) * pow(1.0 - cosTheta, 5.0);
}

vec3 diffuseHammon(float LdotV, float NdotL, float NdotV, float NdotH, Material material) {
    float facing = 0.5 + 0.5 * LdotV;
    float rough = facing * (0.9 - 0.4 * facing) * (0.5 + NdotH) / NdotH;
    float smoot = 1.05 * (1.0 - pow(1.0 - NdotL, 5.0)) * (1.0 - pow(1.0 - NdotV, 5.0));
    float single = 1.0 / PI * mix(smoot, rough, material.roughness);
    float multi = 0.1159 * material.roughness;
    return material.albedo * (single + material.albedo * multi);
}

float ggxTrowbridgeReitz(float NdotH, Material material) {
    float denom = NdotH * NdotH * (material.roughness * material.roughness - 1.0) + 1.0;
    return material.roughness * material.roughness / (PI * denom * denom);
}

float ggxG1Schlick(float cosTheta, float k) {
    float denom = cosTheta * (1.0 - k) + k;
    return cosTheta / denom;
}

float geometrySmith(float NdotV, float NdotL, Material material) {
    float k = (material.roughness + 1.0) * (material.roughness + 1.0) / 8.0;
    return ggxG1Schlick(NdotV, k) * ggxG1Schlick(NdotL, k);
}

vec3 cookTorrance(float NdotH, float NdotV, float NdotL, Material material) {
    return ggxTrowbridgeReitz(NdotH, material) * 
            geometrySmith(NdotV, NdotL, material) * 
            fresnelSchlick(material.F0, NdotV) / (4.0 * NdotV * NdotL);
}

vec3 brdfDirect(vec3 view, vec3 light, Material material) {
    vec3 halfway = normalize(view + light);
    float NdotL = max(dot(material.normal, light), 0.0);
    float NdotV = max(dot(material.normal, view), 0.0);
    float NdotH = max(dot(material.normal, halfway), 0.0);
    float LdotV = dot(light, view);
    vec3 diffuse = diffuseHammon(LdotV, NdotL, NdotV, NdotH, material);
    vec3 specular = cookTorrance(NdotH, NdotV, NdotL, material);
    return (max(specular * mix(vec3(1.0), material.albedo, material.metallic), 0.0) + diffuse * (1.0 - material.metallic)) * NdotL;
}

float evaluateSpecularProbability(vec3 view, Material material) {
    vec3 reflected = reflect(-view, material.normal);
    vec3 halfway = normalize(view + reflected);
    float fresnel = clamp(luminance(fresnelSchlick(material.F0, max(dot(view, halfway), 0.0))), 0.0, 1.0);
    
    float diffuse = luminance(material.albedo) * (1.0 - material.metallic) * (1.0 - fresnel);
    float specular = fresnel;
    
    return specular / (specular + diffuse);
}

vec3 sampleGGXVNDF(vec3 Ve, vec2 alpha2D) {
    vec2 u = randVec2();

	vec3 Vh = normalize(vec3(alpha2D.x * Ve.x, alpha2D.y * Ve.y, Ve.z));

	float lensq = Vh.x * Vh.x + Vh.y * Vh.y;
	vec3 T1 = lensq > 0.0f ? vec3(-Vh.y, Vh.x, 0.0f) * inversesqrt(lensq) : vec3(1.0f, 0.0f, 0.0f);
	vec3 T2 = cross(Vh, T1);

	float r = sqrt(u.x);
	float phi = 2.0 * PI * u.y;
	float t1 = r * cos(phi);
	float t2 = r * sin(phi);
	float s = 0.5f * (1.0f + Vh.z);
	t2 = mix(sqrt(1.0f - t1 * t1), t2, s);

	vec3 Nh = t1 * T1 + t2 * T2 + sqrt(max(0.0f, 1.0f - t1 * t1 - t2 * t2)) * Vh;

	return normalize(vec3(alpha2D.x * Nh.x, alpha2D.y * Nh.y, max(0.0f, Nh.z)));
}

vec3 sampleSpecular(vec3 view, Material material, out vec3 rayDirection) {
    float alpha = material.roughness * material.roughness;
    vec3 microfacetNormal;
    if (material.roughness > EPSILON) {
        quat qRotation = getRotationToZAxis(material.normal);
        microfacetNormal = normalize(sampleGGXVNDF(quaternionRotate(view, qRotation), vec2(alpha)));
        microfacetNormal = quaternionRotate(microfacetNormal, vec4(qRotation.xyz, -qRotation.w));
    } else {
        microfacetNormal = material.normal;
    }
    rayDirection = reflect(-view, microfacetNormal);
    vec3 halfway = normalize(view + rayDirection);
    
    float HdotL = max(dot(halfway, rayDirection), 0.0);
    float NdotL = max(dot(microfacetNormal, rayDirection), 0.0);
    float NdotV = max(dot(microfacetNormal, view), 0.0);
    float k = (alpha + 1.0);
    k *= k / 8.0;

    vec3 F = fresnelSchlick(material.F0, NdotV);
    float G2 = ggxG1Schlick(NdotL, k);
    
    return F * G2;
}

vec3 sampleDiffuse(vec3 view, Material material, out vec3 rayDirection) {
    rayDirection = cosineWeighted(material.normal);
    vec3 halfway = normalize(view + rayDirection);

    float NdotL = max(dot(material.normal, rayDirection), 0.0);
    float NdotV = max(dot(material.normal, view), 0.0);
    float NdotH = max(dot(material.normal, halfway), 0.0);
    float LdotV = dot(rayDirection, view);

    return diffuseHammon(LdotV, NdotL, NdotV, NdotH, material) / NdotL * PI;
}

#endif // BRDF_GLSL