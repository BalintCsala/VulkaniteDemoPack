#ifndef BRDF_GLSL
#define BRDF_GLSL

#include "/lib/constants.glsl"
#include "/lib/rand.glsl"
#include "/lib/quaternions.glsl"

vec3 schlickFresnel(vec3 F0, float cosTheta) {
    return F0 + (1.0 - F0) * pow(1.0 - cosTheta, 5.0);
}

vec3 cosineWeighted(vec3 normal) {
    vec2 v = randVec2();
    float angle = 2.0 * PI * v.x;
    float u = 2.0 * v.y - 1.0;

    vec3 directionOffset = vec3(sqrt(1.0 - u * u) * vec2(cos(angle), sin(angle)), u);
    return normalize(normal + directionOffset);
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

vec3 cookTorrance(float NdotH, float NdotV, float NdotL, float HdotL, Material material) {
    return ggxTrowbridgeReitz(NdotH, material) * 
            geometrySmith(NdotV, NdotL, material) * 
            schlickFresnel(material.F0, HdotL) / (4.0 * NdotV * NdotL);
}

vec3 brdfDirect(vec3 view, vec3 light, Material material) {
    vec3 halfway = normalize(view + light);
    float NdotL = max(dot(material.normal, light), 0.0);
    float NdotV = max(dot(material.normal, view), 0.0);
    float NdotH = max(dot(material.normal, halfway), 0.0);
    float HdotL = max(dot(halfway, light), 0.0);

    vec3 fresnelInternal = schlickFresnel(material.F0, NdotV);
    vec3 fresnelTransmission = schlickFresnel(material.F0, NdotL);

    vec3 diffuse = material.albedo / PI * (1.0 - material.metallic) * (1.0 - fresnelInternal) * (1.0 - fresnelTransmission);
    vec3 specular = cookTorrance(NdotH, NdotV, NdotL, HdotL, material) * mix(vec3(1.0), material.albedo, material.metallic);
    return (specular + diffuse) * NdotL;
}

float evaluateSpecularProbability(vec3 view, Material material) {
    vec3 reflected = reflect(-view, material.normal);
    vec3 halfway = normalize(view + reflected);
    float fresnel = clamp(luminance(schlickFresnel(material.F0, max(dot(view, halfway), 0.0))), 0.0, 1.0);
    
    float diffuse = luminance(material.albedo) * (1.0 - material.metallic) * (1.0 - fresnel);
    float specular = fresnel;
    
    return specular / (specular + diffuse);
}

vec3 sampleGGXVNDF(vec3 Ve, vec2 alpha2D) {
    vec2 u = randVec2();

	vec3 Vh = normalize(vec3(alpha2D.x * Ve.x, alpha2D.y * Ve.y, Ve.z));

	float lensq = Vh.x * Vh.x + Vh.y * Vh.y;
	vec3 T1 = lensq > 0.0 ? vec3(-Vh.y, Vh.x, 0.0) * inversesqrt(lensq) : vec3(1.0, 0.0, 0.0);
	vec3 T2 = cross(Vh, T1);

	float r = sqrt(u.x);
	float phi = 2.0 * PI * u.y;
	float t1 = r * cos(phi);
	float t2 = r * sin(phi);
	float s = 0.5 * (1.0 + Vh.z);
	t2 = mix(sqrt(1.0 - t1 * t1), t2, s);

	vec3 Nh = t1 * T1 + t2 * T2 + sqrt(max(0.0f, 1.0f - t1 * t1 - t2 * t2)) * Vh;

	return normalize(vec3(alpha2D.x * Nh.x, alpha2D.y * Nh.y, max(0.0, Nh.z)));
}

struct BRDFSample {
    vec3 direction;
    vec3 throughput;
};

BRDFSample sampleSpecular(vec3 view, Material material) {
    float alpha = material.roughness * material.roughness;
    vec3 microfacetNormal;
    if (material.roughness > EPSILON) {
        vec4 qRotation = getRotationToZAxis(material.normal);
        microfacetNormal = normalize(sampleGGXVNDF(quatRotate(view, qRotation), vec2(alpha)));
        microfacetNormal = quatRotate(microfacetNormal, vec4(qRotation.xyz, -qRotation.w));
    } else {
        microfacetNormal = material.normal;
    }
    vec3 rayDirection = reflect(-view, microfacetNormal);
    vec3 halfway = normalize(view + rayDirection);
    
    float HdotL = max(dot(halfway, rayDirection), 0.0);
    float NdotL = max(dot(microfacetNormal, rayDirection), 0.0);
    float NdotV = max(dot(microfacetNormal, view), 0.0);
    float k = (alpha + 1.0);
    k *= k / 8.0;

    vec3 F = schlickFresnel(material.F0, NdotV);
    float G2 = ggxG1Schlick(NdotL, k);
    
    return BRDFSample(
        rayDirection, 
        F * G2
    );
}

BRDFSample sampleDiffuse(vec3 view, Material material) {
    return BRDFSample(
        cosineWeighted(material.normal),
        material.albedo
    );
}

BRDFSample sampleMaterial(vec3 view, Material material) {
    float specularProbability = evaluateSpecularProbability(view, material);
    if (randFloat() < specularProbability) {
        BRDFSample brdfSample = sampleSpecular(view, material);
        brdfSample.throughput /= specularProbability;
        if (material.metallic > 0.5) {
            brdfSample.throughput *= material.albedo;
        }
        return brdfSample;
    } else {
        BRDFSample brdfSample = sampleDiffuse(view, material);
        brdfSample.throughput /= 1.0 - specularProbability;
        return brdfSample;
    }
}

#endif // BRDF_GLSL