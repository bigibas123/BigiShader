#ifndef BIGI_LIGHT_UTILS_H
#define BIGI_LIGHT_UTILS_H

#include <UnityCG.cginc>
#include <UnityStandardUtils.cginc>
#include <UnityLightingCommon.cginc>
#include <UnityPBSLighting.cginc>
#include <AutoLight.cginc>

#include "../Core/BigiShaderStructs.cginc"


#ifdef UNITY_PASS_FORWARDBASE
#include "../External/VRSL/VRSLGI-ParameterSettings.cginc"
#endif

#ifdef LTCGI_ENABLED
#include "../External/LTCGI/LTCGI-Functions.cginc"
#endif

namespace b_light
{
    world_info setup_world(in float3 worldPos, in fixed attenuation, in float3 normal, in float4 shadowmapUV)
    {
        world_info wi;

        #if defined(POINT)  || defined(POINT_COOKIE) || defined(SPOT)
		wi.worldLightDir = normalize(_WorldSpaceLightPos0.xyz - worldPos);
        #else
        wi.worldLightDir = _WorldSpaceLightPos0.xyz;
        #endif

        wi.worldLightColor = _LightColor0.rgba * attenuation;
        wi.viewDir = normalize(_WorldSpaceCameraPos - worldPos);
        wi.worldPos = worldPos;

        wi.normal = normal;
        wi.shadowmapUvs = shadowmapUV;
        return wi;
    }


    UnityLight CreateLight(const in world_info wi, const in half mainStrength)
    {
        UnityLight light;
        light.color = wi.worldLightColor * mainStrength;
        light.dir = wi.worldLightDir;
        light.ndotl = DotClamped(wi.normal, wi.worldLightDir) * mainStrength;
        return light;
    }

    float3 BoxProjection(
        float3 direction, float3 position,
        float4 cubemapPosition, float3 boxMin, float3 boxMax
    )
    {
        #if UNITY_SPECCUBE_BOX_PROJECTION
		UNITY_BRANCH
		if (cubemapPosition.w > 0) {
			float3 factors =
				((direction > 0 ? boxMax : boxMin) - position) / direction;
			float scalar = min(min(factors.x, factors.y), factors.z);
			direction = direction * scalar + (position - cubemapPosition);
		}
        #endif
        return direction;
    }

    UnityIndirect CreateIndirectLight(UnityIndirect indirectLight, in world_info wi, in float3 vertexLightColor,
                                      in half smoothness, in half vertexStrength, in half envStrength)
    {
        indirectLight.diffuse += (vertexLightColor * vertexStrength);

        #if defined(FORWARD_BASE_PASS)
		indirectLight.diffuse += (max(0, ShadeSH9(float4(wi.normal, 1))) * envStrength);

		float3 reflectionDir = reflect(-wi.viewDir, wi.normal);
		Unity_GlossyEnvironmentData envData;
		envData.roughness = 1 - smoothness;
		envData.reflUVW = BoxProjection(
			reflectionDir, wi.worldPos,
			unity_SpecCube0_ProbePosition,
			unity_SpecCube0_BoxMin, unity_SpecCube0_BoxMax
		);
		float3 probe0 = Unity_GlossyEnvironment(
			UNITY_PASS_TEXCUBE(unity_SpecCube0), unity_SpecCube0_HDR, envData
		);
		envData.reflUVW = BoxProjection(
			reflectionDir, wi.worldPos,
			unity_SpecCube1_ProbePosition,
			unity_SpecCube1_BoxMin, unity_SpecCube1_BoxMax
		);
        #if UNITY_SPECCUBE_BLENDING
		float interpolator = unity_SpecCube0_BoxMin.w;
		UNITY_BRANCH
		if (interpolator < 0.99999) {
			float3 probe1 = Unity_GlossyEnvironment(
				UNITY_PASS_TEXCUBE_SAMPLER(unity_SpecCube1, unity_SpecCube0),
				unity_SpecCube0_HDR, envData
			);
			indirectLight.specular += (lerp(probe1, probe0, interpolator) * envStrength);
		}
		else {
			indirectLight.specular += (probe0 * envStrength);
		}
        #else
		indirectLight.specular += (probe0 * envStrength);
        #endif
        #endif
        return indirectLight;
    }

    float4 _get_lighting(in float3 normal, in float3 worldPos, in float3 vertexLightColor, in half attenuation,
                         in half minAmbient, in half4 specularTint, in fixed ambientOcclusion,
                         float4 shadowmapUV, in half3 vertexEnvMainStrengths)
    {
        float3 albedo = float4(1.0, 1.0, 1.0, 1.0);
        albedo *= 1.0;

        normal = normalize(normal);
        const world_info wi = setup_world(worldPos, attenuation, normal, shadowmapUV);

        float oneMinusReflectivity;
        albedo = EnergyConservationBetweenDiffuseAndSpecular(
            albedo, specularTint.rgb, oneMinusReflectivity
        );
        UnityIndirect unityIndirect;
        unityIndirect.diffuse = 0;
        unityIndirect.specular = 0;
        float4 unity_pbs_output = UNITY_BRDF_PBS(
            albedo, specularTint.rgb,
            oneMinusReflectivity, specularTint.a,
            wi.normal, wi.viewDir,
            CreateLight(wi, vertexEnvMainStrengths.z),
            CreateIndirectLight(unityIndirect, wi, vertexLightColor, specularTint.a, vertexEnvMainStrengths.x,
                                vertexEnvMainStrengths.y)
        );
        float4 output = unity_pbs_output;

        #ifdef LTCGI_ENABLED
        UnityIndirect ltcgiIndirect;
        ltcgiIndirect.diffuse = 0;
        ltcgiIndirect.specular = 0;
        get_LTCGI(wi, ltcgiIndirect, specularTint.a);
        output.rgb += ltcgiIndirect.diffuse * albedo;
        output.rgb += ltcgiIndirect.specular;
        #endif

        #ifdef UNITY_PASS_FORWARDBASE
        b_vrslgi::setParams();
        output.rgb += VRSLGI(wi.worldPos, wi.normal, 1.0 - specularTint.a, wi.viewDir, albedo,
                             float2(oneMinusReflectivity, specularTint.a), wi.shadowmapUvs.xy, ambientOcclusion);
        #endif

        //output = max(minAmbient,output);
        return saturate(output);
    }

    float4 doStep(in const float4 inLight, in const half smoothness, in const uint steps)
    {
        const float4 offsetLight = ((inLight * steps) + (smoothness / 2.0)) - 0.5;
        const float4 smoothedPart = (float4)smoothstep(0.00, smoothness, frac(offsetLight)) / steps;
        const float4 steppedPart = floor(offsetLight) / steps;
        return smoothedPart + steppedPart;
    }

    float4 get_lighting(in float3 normal, in float3 worldPos, in float3 vertexLightColor, in fixed ambientOcclusion,
                        in half occlusionStrength, in half attenuation, in float4 shadowMapUv,
                        in half minAmbient, in half transmissivity, in half lightSmoothness,
                        in uint lightSteps, in half4 specSmooth, in half3 vertexEnvMainStrengths)
    {
        const half scaledAO = lerp(1, ambientOcclusion, occlusionStrength);
        attenuation = attenuation * scaledAO;

        float4 total = _get_lighting(normal, worldPos, vertexLightColor, attenuation, minAmbient, specSmooth,
                                     scaledAO, shadowMapUv, vertexEnvMainStrengths);
        if (transmissivity > Epsilon)
        {
            total += _get_lighting(normal * -1.0, worldPos, vertexLightColor, attenuation, 0, specSmooth,
                                   scaledAO, shadowMapUv, vertexEnvMainStrengths) * transmissivity;
        }
        total = doStep(total, lightSmoothness, lightSteps);
        total.rgba = float4(
            clamp(total.rgb, minAmbient, 5.0),
            clamp(total.a, 1.0, 1.0)
        );
        return total;
    }


    //Unity.cginc Shade4PointLights 
    float3 bigi_Shade4PointLights(
        float4 lightPosX, float4 lightPosY, float4 lightPosZ,
        float3 lightColor0, float3 lightColor1, float3 lightColor2, float3 lightColor3,
        float4 lightAttenSq,
        float3 pos, float3 normal
    )
    {
        // to light vectors
        float4 toLightX = lightPosX - pos.x;
        float4 toLightY = lightPosY - pos.y;
        float4 toLightZ = lightPosZ - pos.z;
        // squared lengths
        float4 lengthSq = 0;
        lengthSq += toLightX * toLightX;
        lengthSq += toLightY * toLightY;
        lengthSq += toLightZ * toLightZ;
        // don't produce NaNs if some vertex position overlaps with the light
        lengthSq = max(lengthSq, 0.000001);

        // NdotL
        float4 ndotl = 0;
        ndotl += toLightX * normal.x;
        ndotl += toLightY * normal.y;
        ndotl += toLightZ * normal.z;
        // correct NdotL
        float4 corr = rsqrt(lengthSq);
        ndotl = max(float4(0, 0, 0, 0), ndotl * corr);
        // attenuation
        float4 atten = 1.0 / (1.0 + lengthSq * lightAttenSq);
        float4 diff = ndotl * atten;
        // final color
        float3 col = 0;
        col += lightColor0 * diff.x;
        col += lightColor1 * diff.y;
        col += lightColor2 * diff.z;
        col += lightColor3 * diff.w;
        return col;
    }

    float3 ProcessVertexLights(
        float4 lightPosX, float4 lightPosY, float4 lightPosZ,
        float3 lightColor0, float3 lightColor1, float3 lightColor2, float3 lightColor3,
        float4 lightAttenSq,
        float3 pos, float3 normal
    )
    {
        float3 ret = 0;
        ret += bigi_Shade4PointLights(
            lightPosX, lightPosY, lightPosZ,
            lightColor0, lightColor1, lightColor2, lightColor3,
            lightAttenSq, pos, normal);
        return ret;
    }
}

#endif
