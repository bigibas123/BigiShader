#ifndef BIGI_LIGHT_UTILS_H
#define BIGI_LIGHT_UTILS_H

#include <UnityPBSLighting.cginc>
#include <UnityCG.cginc>
#include <UnityStandardUtils.cginc>
#include <UnityLightingCommon.cginc>
#include <AutoLight.cginc>

#include "../Epsilon.cginc"
#include "../Core/BigiShaderStructs.cginc"
#include "../Core/BigiGetColor.cginc"

#include "../External/VRCLV/VRCLightVolumes.cginc"
#include "../External/LTCGI/LTCGI-Functions.cginc"
//#include "../External/VRSL/BigiVRSL.cginc"

namespace b_light
{
    world_info setup_world(in float4 albedo, in float3 worldPos, in fixed attenuation, in float3 normal, in float4 shadowmapUV, float4 specularTint, float ambientOcclusion)
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

        wi.normal = normalize(normal);
        wi.shadowmapUvs = shadowmapUV;

    	//wi.albedo = albedo;
    	wi.smoothness = specularTint.a;
    	wi.albedo = float4(1.0,1.0,1.0,1.0);
    	wi.albedo = EnergyConservationBetweenDiffuseAndSpecular(
			wi.albedo, specularTint.rgb, wi.oneMinusReflectivity
		);
    	wi.specular = specularTint.rgb;
    	wi.ambientOcclusion = ambientOcclusion;
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

    UnityIndirect CreateIndirectLight(inout UnityIndirect indirectLight, const in world_info wi, const in float3 vertexLightColor,
    	const in half vertexStrength, const in half envStrength)
    {
        indirectLight.diffuse += (vertexLightColor * vertexStrength);

        #ifdef UNITY_PASS_FORWARDBASE
    	if ((!_UdonLightVolumeEnabled) || (_UdonLightVolumeCount <= 0))
    	{
    		// No VRC light volumes active
    		indirectLight.diffuse += (max(0, ShadeSH9(float4(wi.normal, 1))) * envStrength);
    	}else
    	{
    		// VRC Light volumes active
    		// Unsure if I should use this Since VRCLV only samples unity_SHA and not unity_SHB or unity_SHC
    		//indirectLight.diffuse += (max(0, ShadeSH3Order(float4(wi.normal, 1))) * envStrength);
    	}

		float3 reflectionDir = reflect(-wi.viewDir, wi.normal);
		Unity_GlossyEnvironmentData envData;
		envData.roughness = 1 - wi.smoothness;
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

    float4 _get_lighting(const in world_info wi, const in float3 vertexLightColor, const in half3 vertexEnvMainStrengths)
    {
        UnityIndirect unityIndirect;
        unityIndirect.diffuse = 0;
        unityIndirect.specular = 0;
    	
    	CreateIndirectLight(unityIndirect, wi, vertexLightColor, vertexEnvMainStrengths.x,vertexEnvMainStrengths.y);
    	
		GetLightVolumesLighting(wi, unityIndirect);
    	GetLTCGI(wi, unityIndirect);
    	// GetVRSLGI(wi, unityIndirect);
		
    	
        float4 unity_pbs_output = UNITY_BRDF_PBS(
            wi.albedo, wi.specular,
            wi.oneMinusReflectivity, wi.smoothness,
            wi.normal, wi.viewDir,
            CreateLight(wi, vertexEnvMainStrengths.z),unityIndirect
            
        );

    	return saturate(unity_pbs_output);
    }

    float4 doStep(in const float4 inLight, in const half smoothness, in const uint steps)
    {
        const float4 offsetLight = ((inLight * steps) + (smoothness / 2.0)) - 0.5;
        const float4 smoothedPart = (float4)smoothstep(0.00, smoothness, frac(offsetLight)) / steps;
        const float4 steppedPart = floor(offsetLight) / steps;
        return smoothedPart + steppedPart;
    }

    float4 get_lighting(in float4 albedo, in float3 normal, in float3 worldPos, in float3 vertexLightColor, in fixed ambientOcclusion,
                        in half occlusionStrength, in half attenuation, in float4 shadowMapUv,
                        in half minAmbient, in half transmissivity, in half lightSmoothness,
                        in uint lightSteps, in half4 specSmooth, in half3 vertexEnvMainStrengths, in float finalMultiply)
    {
        const half scaledAO = lerp(1, ambientOcclusion, occlusionStrength);
        attenuation = attenuation * scaledAO;

    	world_info wi = setup_world(albedo, worldPos, attenuation, normal, shadowMapUv, specSmooth, scaledAO);
    	
        float4 total = _get_lighting(wi,vertexLightColor, vertexEnvMainStrengths);
        if (transmissivity > Epsilon)
        {
        	wi.normal = wi.normal * -1.0;
            total += _get_lighting(wi,vertexLightColor, vertexEnvMainStrengths) * transmissivity;
        }
    	total.rgb = total.rgb * finalMultiply;
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
